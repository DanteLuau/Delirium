--!strict

-- Delirium UI Library
-- saveManager.luau — Flag persistence layer.
--
-- Wraps flags.luau (runtime) + filesystem.luau (disk) into a save/load system.
-- Components register set-callbacks via Register() so Load() can push values back
-- into the UI. Save() snapshots flags:GetAll() so no component coordination is
-- needed on the write side — flags are the source of truth.
--
-- Profile API:
--   SaveManager:SetFolder(name)              -- change root folder (call before Load/Save)
--   SaveManager:Register(flag, set)          -- called by components; set(v) applies without firing callback
--   SaveManager:Save(profileName?)           -- serialize all flags → disk (atomic)
--   SaveManager:Load(profileName?)           -- deserialize disk → flags + registered setters
--   SaveManager:List()                       -- { string } of saved profile names
--   SaveManager:Delete(profileName)          -- remove one profile from disk
--   SaveManager:BuildConfigTab(window)       -- auto-builds a "Config" tab with full UI
--   SaveManager:SetAutoSaveInterval(secs)    -- override auto-save interval (default 30s)
--   SaveManager.deriveFlagFromName(s)        -- "My Toggle" → "my_toggle"
--   SaveManager._scheduleAutoSave()          -- debounced 0.5s auto-save; call after flag changes
--
-- Atomic write:
--   Write to <file>.saving → verify read-back → promote to real path → delete temp.
--   A crash mid-write leaves the .saving copy; Load() and List() both ignore it.

local filesystem  = require(script.Parent.filesystem)
local flags       = require(script.Parent.flags)
local services    = require(script.Parent.services)

local HttpService = services.getService("HttpService") :: HttpService

-- ── Types ─────────────────────────────────────────────────────────────────────

type SetCallback  = (value: any) -> ()
type FlagEntry    = { set: SetCallback }

export type SaveManager = {
	SetFolder:             (self: SaveManager, name: string) -> (),
	Register:              (self: SaveManager, flag: string, set: SetCallback) -> (),
	Save:                  (self: SaveManager, profileName: string?) -> (),
	Load:                  (self: SaveManager, profileName: string?) -> (),
	List:                  (self: SaveManager) -> { string },
	Delete:                (self: SaveManager, profileName: string) -> (),
	BuildConfigTab:        (self: SaveManager, window: any) -> (),
	SetAutoSaveInterval:   (self: SaveManager, seconds: number) -> (),
	_scheduleAutoSave:     (self: SaveManager) -> (),
	deriveFlagFromName:    (label: string) -> string,
}

-- ── Module state ──────────────────────────────────────────────────────────────

local SaveManager   = {} :: any
SaveManager.__index = SaveManager

local _registry    : { [string]: FlagEntry } = {}
local _pendingLoad : { [string]: any }        = {}
local _ignored     : { [string]: boolean }    = {}
local _folder      : string  = "Delirium"
local _loading     : boolean = false
local _savePending : boolean = false

-- auto-save state
local _autoEnabled  : boolean = false
local _autoInterval : number  = 30
local _autoThread   : thread? = nil
local _getAutoProfile : (() -> string)? = nil

-- ── Helpers ───────────────────────────────────────────────────────────────────

-- FNV-1a 32-bit hash — stable fallback for non-ASCII labels.
local function fnv1a(s: string): number
	local h: number = 2166136261
	for i = 1, #s do
		h = bit32.bxor(h, string.byte(s, i))
		h = bit32.band(h * 16777619, 0xFFFFFFFF)
	end
	return h
end

local function profilePath(name: string?): string
	local n = if name and #name > 0 then name else "flags"
	return _folder .. "/" .. n .. ".json"
end

-- Serialize EnumItems (KeyCode etc.) to survive JSON round-trips.
local function serializeValue(v: any): any
	if typeof(v) == "EnumItem" then
		return { __enumType = tostring(v.EnumType), __name = v.Name }
	end
	if typeof(v) == "Color3" then
		return { __type = "Color3", r = v.R, g = v.G, b = v.B }
	end
	return v
end

local function deserializeValue(v: any): any
	if type(v) ~= "table" then return v end
	if v.__enumType and v.__name then
		local ok, result = pcall(function()
			return (Enum :: any)[v.__enumType][v.__name]
		end)
		if ok and result then return result end
	end
	if v.__type == "Color3" then
		return Color3.new(v.r or 0, v.g or 0, v.b or 0)
	end
	return v
end

-- Atomic write: stage → verify → promote → delete temp.
-- FIX: was leaving name.json.saving on disk alongside name.json.
local function atomicWrite(path: string, content: string): boolean
	local tempPath = path .. ".saving"

	filesystem.ensureDir(_folder)

	local wOk = pcall(filesystem.writefile, tempPath, content)
	if not wOk then return false end

	-- Verify read-back before promoting (guards against partial writes).
	local rOk, readBack = pcall(filesystem.readfile, tempPath)
	if not rOk or readBack ~= content then
		pcall(filesystem.delfile, tempPath)
		return false
	end

	local promOk = pcall(filesystem.writefile, path, content)

	-- Always remove the temp — whether promote succeeded or not.
	-- This is the line that was missing, causing the double-file bug.
	pcall(filesystem.delfile, tempPath)

	return promOk
end

-- ── Auto-save internals ───────────────────────────────────────────────────────

-- A4 FIX: exposed so callers (user script's OnUnload, etc.) can stop the
-- infinite task.spawn loop that otherwise keeps writing flags.json forever
-- even after the window has been torn down.
local function stopAutoSave()
	if _autoThread then
		task.cancel(_autoThread)
		_autoThread = nil
	end
	_autoEnabled = false
end

local function startAutoSave(getProfile: () -> string)
	stopAutoSave()
	_autoEnabled     = true
	_getAutoProfile  = getProfile
	_autoThread = task.spawn(function()
		while _autoEnabled do
			task.wait(_autoInterval)
			if not _autoEnabled then break end
			local name = if _getAutoProfile then _getAutoProfile() else "flags"
			SaveManager:Save(name)
		end
		_autoThread = nil
	end)
end

-- ── Public API ────────────────────────────────────────────────────────────────

-- Derives a deterministic flag key from a human-readable label.
-- ASCII: lowercase, spaces → underscore, strip non-alphanumeric, cap at 48 chars.
-- Non-ASCII / empty-after-sanitize: FNV-1a hash → "Flag%08x".
function SaveManager.deriveFlagFromName(label: string): string
	if #label == 0 then return "" end
	local sanitized = label
		:lower()
		:gsub("%s+", "_")
		:gsub("[^%w_]", "")
		:sub(1, 48)
	if #sanitized > 0 then return sanitized end
	return string.format("Flag%08x", fnv1a(label))
end

-- Change the root folder. Must be called before Load/Save.
function SaveManager:SetFolder(name: string)
	_folder = name
end

-- Override the auto-save interval in seconds (default: 30).
-- Call before BuildConfigTab or before the user enables the toggle.
function SaveManager:SetAutoSaveInterval(seconds: number)
	_autoInterval = seconds
end

-- Register a component's setter for a flag.
-- set(value) must apply the value without firing the component's Changed callback
-- (to avoid triggering an autoSave loop while loading).
-- If Load() already ran and this flag had a stored value, it is applied immediately.
function SaveManager:Register(flag: string, set: SetCallback)
	_registry[flag] = { set = set }

	local pending = _pendingLoad[flag]
	if pending ~= nil then
		pcall(set, pending)
		flags:Set(flag, pending)
	end
end

-- Serialize all current flags to JSON and write atomically.
-- profileName defaults to "flags" → Delirium/flags.json.
-- Flags in _ignored (including internal Config-tab flags) are skipped.
function SaveManager:Save(profileName: string?)
	local snapshot = flags:GetAll()
	local data: { [string]: any } = {}
	for k, v in snapshot do
		if not _ignored[k] then
			data[k] = serializeValue(v)
		end
	end

	local ok, encoded = pcall(function()
		return HttpService:JSONEncode(data)
	end)
	if not ok then return end

	atomicWrite(profilePath(profileName), encoded)
end

-- Read from disk and push values into flags + registered setters.
-- Flags with no registered setter are held in _pendingLoad and applied
-- the moment their component calls Register().
function SaveManager:Load(profileName: string?)
	local path = profilePath(profileName)

	local raw: string? = nil
	pcall(function()
		if not filesystem.isfile(path) then return end
		raw = filesystem.readfile(path)
	end)
	if not raw or raw == "" then return end

	local ok, data = pcall(function()
		return HttpService:JSONDecode(raw :: string)
	end)
	if not ok or type(data) ~= "table" then return end

	_loading = true

	for flag, rawValue in data do
		if _ignored[flag] then continue end
		local value = deserializeValue(rawValue)
		_pendingLoad[flag] = value
		flags:Set(flag, value)

		local entry = _registry[flag]
		if entry then
			pcall(entry.set, value)
		end
	end

	_loading = false
end

-- Returns a list of all profile names in the folder.
-- Filters out .saving temps and non-.json files.
function SaveManager:List(): { string }
	local names: { string } = {}
	pcall(function()
		filesystem.ensureDir(_folder)
		local files = filesystem.listfiles(_folder)
		for _, path in files do
			local normalized = path:gsub("\\", "/")
			local filename   = normalized:match("([^/]+)$") or ""
			-- skip any .saving leftover — should be none after the atomicWrite fix,
			-- but guard anyway so List() is always clean.
			if filename:match("%.saving$") then continue end
			local name = filename:match("^(.+)%.json$")
			if name then
				table.insert(names, name)
			end
		end
	end)
	table.sort(names)
	return names
end

-- Delete a named profile. Silent if the file doesn't exist.
function SaveManager:Delete(profileName: string)
	if not profileName or #profileName == 0 then return end
	pcall(function()
		local path = profilePath(profileName)
		if not filesystem.isfile(path) then return end
		filesystem.delfile(path)
	end)
end

-- Debounced auto-save — call after any flag change to persist 0.5s later.
-- Skipped when Load() is running to avoid looping saves during restore.
function SaveManager:_scheduleAutoSave()
	if _loading then return end
	if _savePending then return end
	_savePending = true
	task.delay(0.5, function()
		_savePending = false
		self:Save()
	end)
end

-- ── BuildConfigTab ────────────────────────────────────────────────────────────
-- Creates a "Config" tab on the given Window with a full config management UI:
--   • Profile name input
--   • Saved profiles dropdown
--   • Save / Load / Delete buttons
--   • Auto-save toggle (on/off, uses _autoInterval)
--
-- Internal flags (__SM_*) are added to _ignored so they're never written to disk.
--
-- Usage (in your script, after CreateWindow):
--   SaveManager:BuildConfigTab(Window)
function SaveManager:BuildConfigTab(window: any)
	-- Mark internal flags as ignored so they're never serialized
	_ignored["__SM_ProfileName"] = true
	_ignored["__SM_ProfileList"] = true
	_ignored["__SM_AutoSave"]    = true

	local tab = window:CreateTab({
		name    = "Config",
		icon    = "lucide:save",
		columns = 1,
	})

	local col = tab.Left

	col:CreateSection({ name = "Configuration" })

	-- ── Profile name input ────────────────────────────────────────────────────
	local nameInput = col:CreateInput({
		name         = "Profile Name",
		placeholder  = "flags  (default)",
		flag         = "__SM_ProfileName",
		clearOnFocus = false,
		callback     = function(_: string) end,
	})

	local function currentProfile(): string
		local v = (nameInput :: any).value
		return if v and #(v :: string) > 0 then v :: string else "flags"
	end

	-- ── Saved profiles dropdown ───────────────────────────────────────────────
	local profilesDD = col:CreateDropdown({
		name        = "Saved Profiles",
		options     = self:List(),
		placeholder = "select a profile...",
		flag        = "__SM_ProfileList",
		callback    = function(value: string | { string })
			local pick = if type(value) == "string" then value else (value :: { string })[1]
			local ni = nameInput :: any
			ni:Set(pick, true)
		end,
	})

	local function refreshList()
		local dd = profilesDD :: any
		dd:SetOptions(self:List())
	end

	-- ── Save ──────────────────────────────────────────────────────────────────
	col:CreateButton({
		name        = "Save",
		description = "Write all flags to the named profile on disk.",
		callback    = function()
			local name = currentProfile()
			self:Save(name)
			refreshList()
			window:Notify({ title = "Saved", content = "Profile '" .. name .. "' written to disk." })
		end,
	})

	-- ── Load ──────────────────────────────────────────────────────────────────
	col:CreateButton({
		name        = "Load",
		description = "Restore flags from the selected profile and sync UI.",
		callback    = function()
			local name = currentProfile()
			self:Load(name)
			window:Notify({ title = "Loaded", content = "Profile '" .. name .. "' applied." })
		end,
	})

	-- ── Delete ────────────────────────────────────────────────────────────────
	col:CreateButton({
		name        = "Delete",
		description = "Permanently remove the named profile from disk.",
		callback    = function()
			local name = currentProfile()
			self:Delete(name)
			refreshList()
			window:Notify({ title = "Deleted", content = "Profile '" .. name .. "' removed." })
		end,
	})

	-- ── Auto-save toggle ──────────────────────────────────────────────────────
	col:CreateToggle({
		name        = "Auto Save",
		description = "Automatically saves every " .. tostring(_autoInterval) .. " seconds.",
		flag        = "__SM_AutoSave",
		value       = false,
		callback    = function(enabled: boolean)
			if enabled then
				startAutoSave(currentProfile)
				window:Notify({
					title   = "Auto Save On",
					content = "Saving every " .. tostring(_autoInterval) .. "s to '" .. currentProfile() .. "'.",
				})
			else
				stopAutoSave()
				window:Notify({ title = "Auto Save Off", content = "Stopped." })
			end
		end,
	})
end

-- A4 FIX: Public wrapper so callers outside this module can stop the auto-save
-- loop. Call SaveManager:StopAutoSave() in your script's cleanup / OnUnload.
-- (Window:Unload does not know about SaveManager, so it can't call this itself.)
function SaveManager:StopAutoSave()
	stopAutoSave()
end

return SaveManager
