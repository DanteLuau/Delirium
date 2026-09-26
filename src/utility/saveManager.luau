--!strict

-- Delirium UI Library
-- saveManager.luau — Flag persistence layer.
--
-- Wraps flags.luau (runtime) + filesystem.luau (disk) into a clean save/load system.
-- Components register set-callbacks via Register() so Load() can push values back
-- into the UI without firing the component's user callback (avoids re-triggering
-- autosave mid-load).
--
-- ── Quick usage ──────────────────────────────────────────────────────────────
--
--   -- 1. (optional) change folder before first load
--   SaveManager:SetFolder("MyScript")
--
--   -- 2. create your window + elements, then register each stateful element
--   local toggle = Tab:CreateToggle({ name = "God Mode", flag = "GodMode", ... })
--   SaveManager:Register("GodMode", function(v) toggle:Set(v, true) end)
--
--   -- 3. load saved flags (applies via registered setters; no-op if no file yet)
--   SaveManager:Load()
--
--   -- 4. (optional) auto-build config tab
--   SaveManager:BuildConfigTab(Window)
--
--   -- 5. call in your unload / cleanup
--   SaveManager:StopAutoSave()
--
-- ── Full API ─────────────────────────────────────────────────────────────────
--
--   SaveManager:SetFolder(name)
--       Change root folder (default "Delirium"). Must be called before Load/Save.
--
--   SaveManager:SetAutoSaveInterval(seconds)
--       Override autosave cadence (default 30 s). Call before enabling autosave.
--
--   SaveManager:Register(flag, setter)
--       Register a setter for one flag. setter(v) must apply the value WITHOUT
--       firing the component's user callback (pass `true` as skipCallback to :Set).
--       If Load() already ran and stored a value for this flag, setter is called
--       immediately with the stored value.
--
--   SaveManager:RegisterMany({ flag = setter, ... })
--       Convenience wrapper — calls Register for every entry in the table.
--
--   SaveManager:Save(profileName?) → boolean
--       Serialize all (non-internal) flags to JSON and write atomically.
--       profileName defaults to "flags". Returns true on success.
--
--   SaveManager:Load(profileName?) → number
--       Read from disk, restore flags + call registered setters.
--       Returns count of flags restored (0 = file missing or empty).
--
--   SaveManager:Refresh()
--       Re-push every registered flag's current value through its setter.
--       Useful after an external flags:Set() call or a manual profile swap.
--
--   SaveManager:List() → { string }
--       Sorted list of saved profile names in the current folder.
--
--   SaveManager:Delete(profileName) → boolean
--       Remove one profile file. Returns true if file existed and was removed.
--
--   SaveManager:StartAutoSave()
--       Start the autosave loop manually (useful without BuildConfigTab's toggle).
--
--   SaveManager:StopAutoSave()
--       Stop the autosave loop. Call in your script's cleanup / unload handler.
--
--   SaveManager:GetActiveProfile() → string
--       Currently active profile name (defaults to "flags").
--
--   SaveManager:SetActiveProfile(name)
--       Change the active profile without saving/loading — affects what
--       Save()/Load()/ScheduleAutoSave() target when called with no name.
--
--   SaveManager:BuildConfigTab(window)
--       Builds a "Config" tab on window with profile input, dropdown, Save/Load/
--       Delete buttons, and an autosave toggle. All internal flags are excluded
--       from serialization automatically.
--
--   SaveManager:ScheduleAutoSave()
--       Debounced 0.5 s autosave — call from inside a flag callback to persist
--       after each user interaction without hammering the disk.
--
--   SaveManager.deriveFlagFromName(label) → string
--       "My Toggle" → "my_toggle". Deterministic ASCII slug; FNV-1a hash fallback
--       for non-ASCII or empty-after-sanitize labels.
--
-- ── Atomic write guarantee ───────────────────────────────────────────────────
--   Write to <file>.saving → verify read-back → promote to real path → delete temp.
--   A crash mid-write leaves only the .saving copy; Load() and List() ignore it.

local filesystem  = require(script.Parent.filesystem)
local flags       = require(script.Parent.flags)
local services    = require(script.Parent.services)

local HttpService = services.getService("HttpService") :: HttpService
local MarketplaceService = services.getService("MarketplaceService") :: MarketplaceService

-- ── Types ─────────────────────────────────────────────────────────────────────

type Setter      = (value: any, skipCallback: boolean?) -> ()
type FlagEntry   = { element: any?, set: Setter }

export type SaveManager = {
	-- config
	SetFolder:           (self: SaveManager, name: string) -> (),
	SetSubFolder:        (self: SaveManager, name: string?) -> (),
	SetSubfolder:        (self: SaveManager, name: string?) -> (),
	SetAutoSaveInterval: (self: SaveManager, seconds: number) -> (),
	-- registration
	Register:            (self: SaveManager, flag: string, target: any) -> (),
	RegisterMany:        (self: SaveManager, map: { [string]: any }) -> (),
	Ignore:              (self: SaveManager, flag: string) -> (),
	IgnoreMany:          (self: SaveManager, mapOrList: any) -> (),
	GetRegistry:         (self: SaveManager) -> { [string]: FlagEntry },
	-- persistence
	Save:                (self: SaveManager, profileName: string?) -> boolean,
	Load:                (self: SaveManager, profileName: string?, skipCallbacks: boolean?) -> number,
	Refresh:             (self: SaveManager, skipCallbacks: boolean?) -> (),
	-- profile management
	List:                (self: SaveManager) -> { string },
	Delete:              (self: SaveManager, profileName: string) -> boolean,
	-- autosave
	StopAutoSave:        (self: SaveManager) -> (),
	StartAutoSave:       (self: SaveManager) -> (),
	ScheduleAutoSave:    (self: SaveManager) -> (),
	-- profile getters/setters (for building a custom config UI without BuildConfigTab)
	GetActiveProfile:    (self: SaveManager) -> string,
	SetActiveProfile:    (self: SaveManager, name: string) -> (),
	-- ui
	BuildConfigTab:      (self: SaveManager, window: any) -> (),
	-- static
	deriveFlagFromName:  (label: string) -> string,
}

-- ── Module state ──────────────────────────────────────────────────────────────

local SaveManager   = {} :: any
SaveManager.__index = SaveManager

-- flag key → entry
local _registry  : { [string]: FlagEntry } = {}
-- flags read from disk but not yet consumed by Register()
-- cleared at the start of every Load() so stale values never bleed across loads
local _pendingLoad : { [string]: any } = {}
-- flags that should never be serialized (internal UI state)
local _ignored   : { [string]: boolean } = {}
-- root folder on disk (e.g. "Delirium" or "SCRIPTHUB")
local _folder    : string  = "Delirium"
-- optional game or sub-directory under <root>/configs/
local _subFolder : string? = nil
-- cached detected game name
local _detectedGameName : string? = nil
-- true while Load() is running; suppresses ScheduleAutoSave during restore
local _loading   : boolean = false
-- debounce gate for ScheduleAutoSave
local _savePending : boolean = false

-- autosave
local _autoEnabled  : boolean = false
local _autoInterval : number  = 30
local _autoThread   : thread? = nil
-- current active profile name — single source of truth (not read from element internals)
local _activeProfile : string = "flags"
-- unsubscribe function returned by flags:Subscribe — nil until installed
local _autoSaveHook : (() -> ())? = nil

-- ── Helpers ───────────────────────────────────────────────────────────────────

-- Sanitize string for valid filesystem path (strip illegal chars: \ / : * ? " < > |)
local function sanitizeName(name: string): string
	local cleaned = name:gsub('[\\/:*?"<>|]', ""):match("^%s*(.-)%s*$") or ""
	return cleaned
end

-- Resolve current game name via MarketplaceService with fallback to PlaceId
local function getGameName(): string
	if _detectedGameName then
		return _detectedGameName
	end

	local resolvedName: string? = nil
	local placeId = game.PlaceId

	pcall(function()
		local productInfo = MarketplaceService:GetProductInfo(placeId)
		if productInfo and type(productInfo.Name) == "string" and #productInfo.Name > 0 then
			resolvedName = sanitizeName(productInfo.Name)
		end
	end)

	if not resolvedName or #resolvedName == 0 then
		resolvedName = tostring(placeId)
	end

	_detectedGameName = resolvedName
	return resolvedName :: string
end

-- FNV-1a 32-bit hash for non-ASCII label fallback.
local function fnv1a(s: string): number
	local h: number = 2166136261
	for i = 1, #s do
		h = bit32.bxor(h, string.byte(s, i))
		h = bit32.band(h * 16777619, 0xFFFFFFFF)
	end
	return h
end

-- Resolve and trim a profile name, falling back to "flags".
local function resolveProfile(name: string?): string
	if not name then return _activeProfile end
	local trimmed = (name :: string):match("^%s*(.-)%s*$") or ""
	return if #trimmed > 0 then trimmed else "flags"
end

-- Resolve the active config directory:
--   If _subFolder is string: "<_folder>/configs/<_subFolder>"
--   If _subFolder is nil:    "<_folder>/configs/<auto_detected_game_name>"
--   If _subFolder is "":     "<_folder>/configs" (root configs folder without subfolder)
local function getFolder(): string
	local sub: string? = nil
	if _subFolder ~= nil then
		if #_subFolder > 0 then
			sub = _subFolder
		end
	else
		-- Automatically use the game name by default
		sub = getGameName()
	end

	if sub and #sub > 0 then
		return _folder .. "/configs/" .. sub
	end
	return _folder .. "/configs"
end

local function profilePath(name: string?): string
	return getFolder() .. "/" .. resolveProfile(name) .. ".json"
end

-- Serialize special Roblox types that don't survive JSON round-trips.
local function serializeValue(v: any): any
	local t = typeof(v)
	if t == "EnumItem" then
		return { __type = "EnumItem", enumType = tostring(v.EnumType), name = v.Name }
	elseif t == "Color3" then
		return { __type = "Color3", r = v.R, g = v.G, b = v.B }
	end
	return v
end

local function deserializeValue(v: any): any
	if type(v) ~= "table" or not v.__type then return v end
	if v.__type == "EnumItem" then
		local ok, result = pcall(function()
			return (Enum :: any)[v.enumType][v.name]
		end)
		return if ok and result then result else nil
	elseif v.__type == "Color3" then
		return Color3.new(v.r or 0, v.g or 0, v.b or 0)
	end
	return v
end

-- Atomic write: stage → verify → promote → remove temp.
-- Returns true if the final file was written successfully.
local function atomicWrite(path: string, content: string): boolean
	local tempPath = path .. ".saving"
	local targetDir = getFolder()

	filesystem.ensureDir(targetDir)

	if not pcall(filesystem.writefile, tempPath, content) then return false end

	-- Verify read-back before promoting to guard against partial/corrupt writes.
	local rOk, readBack = pcall(filesystem.readfile, tempPath)
	if not rOk or readBack ~= content then
		pcall(filesystem.delfile, tempPath)
		return false
	end

	local promOk = pcall(filesystem.writefile, path, content)
	-- Always remove the temp regardless of whether promotion succeeded.
	pcall(filesystem.delfile, tempPath)
	return promOk
end

-- ── Autosave internals ────────────────────────────────────────────────────────

local function stopAutoSave()
	if _autoThread then
		task.cancel(_autoThread)
		_autoThread = nil
	end
	_autoEnabled = false
end

local function startAutoSave()
	stopAutoSave()
	_autoEnabled = true
	_autoThread  = task.spawn(function()
		while _autoEnabled do
			task.wait(_autoInterval)
			if _autoEnabled then
				SaveManager:Save(_activeProfile)
			end
		end
		_autoThread = nil
	end)
end

-- ── Static helpers ────────────────────────────────────────────────────────────

-- Derives a deterministic flag key from a human-readable label.
-- ASCII path: lowercase, spaces→underscore, strip non-alphanumeric, cap 48 chars.
-- Fallback: FNV-1a hash → "Flag%08x" for non-ASCII or empty-after-sanitize inputs.
function SaveManager.deriveFlagFromName(label: string): string
	if #label == 0 then return "" end
	local sanitized = label
		:lower()
		:gsub("%s+", "_")
		:gsub("[^%w_]", "")
		:sub(1, 48)
	return if #sanitized > 0 then sanitized else string.format("Flag%08x", fnv1a(label))
end

-- ── Configuration ─────────────────────────────────────────────────────────────

-- Change the root folder (e.g. "Delirium", "SCRIPTHUB"). Must be called before Load/Save.
function SaveManager:SetFolder(name: string)
	assert(type(name) == "string" and #name > 0, "SaveManager:SetFolder — name must be a non-empty string")
	_folder = name
end

-- Set the game / subfolder name under <_folder>/configs/<name>.
-- Defaults automatically to the current game name (via MarketplaceService / PlaceId).
--   SaveManager:SetSubFolder("Custom Game") -> uses "Custom Game"
--   SaveManager:SetSubFolder()              -> resets to auto-detect game name
--   SaveManager:SetSubFolder("")            -> saves directly in <_folder>/configs/ without a subfolder
function SaveManager:SetSubFolder(name: string?)
	if name == nil then
		_subFolder = nil -- Revert to auto-detecting current game name
	elseif #name > 0 then
		_subFolder = sanitizeName(name)
	else
		_subFolder = "" -- Explicit empty string disables subfolder
	end
end

SaveManager.SetSubfolder = SaveManager.SetSubFolder

-- Override autosave cadence in seconds (default: 30).
function SaveManager:SetAutoSaveInterval(seconds: number)
	assert(type(seconds) == "number" and seconds > 0, "SaveManager:SetAutoSaveInterval — must be > 0")
	_autoInterval = seconds
end

-- ── Registration ──────────────────────────────────────────────────────────────

-- ── Registration ──────────────────────────────────────────────────────────────

-- Register an element or a setter for a single flag.
-- target can be:
--   1. A component element table with a :Set(value, skipCallback) method (e.g. Toggle, Slider, Dropdown)
--   2. A legacy setter function: (value: any, skipCallback: boolean?) -> ()
-- If Load() already stored a value for this flag, it is applied immediately (with callbacks enabled by default).
function SaveManager:Register(flag: string, target: any)
	assert(type(flag) == "string" and #flag > 0, "SaveManager:Register — flag must be a non-empty string")

	-- DX FIX: registering the same flag twice (usually a copy-paste mistake between
	-- two components) silently drops the first element's setter — it stops receiving
	-- Load()/Refresh() updates with no indication why. Warn so it's caught early.
	if _registry[flag] then
		warn(string.format(
			'[Delirium] SaveManager:Register — flag "%s" is already registered; overwriting. '
				.. "Two components likely share the same flag name.",
			flag
		))
	end

	local entry: FlagEntry
	if type(target) == "function" then
		entry = { set = target }
	elseif type(target) == "table" and target.Set then
		local el = target
		entry = {
			element = el,
			set = function(value: any, skipCallback: boolean?)
				el:Set(value, skipCallback)
			end,
		}
	else
		error("SaveManager:Register — target must be a function or a component with a :Set method", 2)
	end

	_registry[flag] = entry

	-- If Load() already ran and stored a value for this flag, apply it now.
	local pending = _pendingLoad[flag]
	if pending ~= nil then
		_pendingLoad[flag] = nil
		flags:Set(flag, pending)
		-- Call setter with skipCallback = false so that the component's callback executes
		-- and the script's runtime variables / automations actually start.
		pcall(entry.set, pending, false)
	end
end

-- Convenience: register many flags or elements in one call.
-- map = { flagKey = elementOrSetter, ... }
function SaveManager:RegisterMany(map: { [string]: any })
	for flag, target in map do
		self:Register(flag, target)
	end
end

-- Exclude a flag from being saved to disk.
function SaveManager:Ignore(flag: string)
	_ignored[flag] = true
end

-- Exclude multiple flags from being saved to disk.
function SaveManager:IgnoreMany(mapOrList: any)
	if type(mapOrList) ~= "table" then return end
	for k, v in mapOrList do
		if type(k) == "number" and type(v) == "string" then
			_ignored[v] = true
		elseif type(k) == "string" and v == true then
			_ignored[k] = true
		end
	end
end

-- Return the internal registry table.
function SaveManager:GetRegistry(): { [string]: FlagEntry }
	return _registry
end

-- ── Persistence ───────────────────────────────────────────────────────────────

-- Serialize all non-internal flags to JSON and write atomically.
-- Returns true on success, false on any failure.
function SaveManager:Save(profileName: string?): boolean
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
	if not ok or type(encoded) ~= "string" then return false end

	return atomicWrite(profilePath(profileName), encoded)
end

-- Read from disk and push values into flags + registered setters / elements.
-- Pending values for not-yet-registered flags are held in _pendingLoad and applied
-- the moment their component registers.
-- skipCallbacks: optional boolean, defaults to false (callbacks DO execute so runtime state updates).
-- Returns the number of flags successfully restored.
function SaveManager:Load(profileName: string?, skipCallbacks: boolean?): number
	-- Install the auto-save hook once per module lifetime.
	-- Any flag change that happens outside of Load() will automatically
	-- schedule a debounced save — user scripts no longer need to call
	-- SaveManager:ScheduleAutoSave() manually inside every callback.
	if not _autoSaveHook then
		_autoSaveHook = flags:Subscribe(function(key: string, _value: any)
			if _loading then return end
			if _ignored[key] then return end
			SaveManager:ScheduleAutoSave()
		end)
	end

	local path = profilePath(profileName)

	local raw: string? = nil
	pcall(function()
		if filesystem.isfile(path) then
			raw = filesystem.readfile(path)
		end
	end)
	if not raw or raw == "" then return 0 end

	local ok, data = pcall(HttpService.JSONDecode, HttpService, raw :: string)
	if not ok or type(data) ~= "table" then return 0 end

	-- Clear pending so stale values from a previous Load() don't bleed through.
	table.clear(_pendingLoad)

	_loading = true
	local count = 0
	local skip = (skipCallbacks == true)

	for flag, rawValue in data do
		if _ignored[flag] then continue end

		local value = deserializeValue(rawValue)
		if value == nil then continue end

		_pendingLoad[flag] = value
		flags:Set(flag, value)

		local entry = _registry[flag]
		if entry then
			if pcall(entry.set, value, skip) then
				count += 1
			end
			_pendingLoad[flag] = nil
		else
			count += 1
		end
	end

	_loading = false
	return count
end

-- Re-push every registered flag's current value through its setter.
-- Call after an external flags:Set() call, a manual profile swap, or any time
-- the runtime state and UI have drifted out of sync.
function SaveManager:Refresh(skipCallbacks: boolean?)
	local skip = (skipCallbacks == true)
	for flag, entry in _registry do
		local value = flags:Get(flag)
		if value ~= nil then
			pcall(entry.set, value, skip)
		end
	end
end

-- ── Profile management ────────────────────────────────────────────────────────

-- Sorted list of saved profile names in the current folder.
-- Never includes .saving temp files.
function SaveManager:List(): { string }
	local names: { string } = {}
	local targetDir = getFolder()
	pcall(function()
		filesystem.ensureDir(targetDir)
		for _, path in filesystem.listfiles(targetDir) do
			local normalized = path:gsub("\\", "/")
			local filename   = normalized:match("([^/]+)$") or ""
			if filename:match("%.saving$") then continue end
			local name = filename:match("^(.-)%.json$")
			if name and #name > 0 then
				table.insert(names, name)
			end
		end
	end)
	table.sort(names)
	return names
end

-- Remove a profile file. Returns true if the file existed and was deleted.
function SaveManager:Delete(profileName: string): boolean
	local trimmed = resolveProfile(profileName)
	if trimmed == "flags" and (not profileName or profileName == "") then
		-- don't silently delete the default profile on empty input
		return false
	end
	local path = profilePath(trimmed)
	local existed = pcall(function()
		if not filesystem.isfile(path) then error("not found") end
		filesystem.delfile(path)
	end)
	return existed
end

-- ── Autosave ──────────────────────────────────────────────────────────────────

-- Start the autosave loop (uses the interval set via SetAutoSaveInterval, default 30s).
-- Safe to call repeatedly — restarts the loop rather than stacking threads.
function SaveManager:StartAutoSave()
	startAutoSave()
end

-- Stop the autosave loop and remove the flags change hook.
-- Call in your script's cleanup / Window:Unload handler.
function SaveManager:StopAutoSave()
	stopAutoSave()
	if _autoSaveHook then
		_autoSaveHook()
		_autoSaveHook = nil
	end
end

-- Get the currently active profile name (defaults to "flags").
-- Useful when building a custom config UI instead of BuildConfigTab.
function SaveManager:GetActiveProfile(): string
	return _activeProfile
end

-- Set the active profile name directly (does not load or save — just changes
-- which profile Save()/Load()/ScheduleAutoSave() target when called with no name).
function SaveManager:SetActiveProfile(name: string)
	_activeProfile = resolveProfile(name)
end

-- Debounced 0.5 s autosave — call from inside a flag callback to persist the
-- user's change without hammering disk on every keystroke/slider tick.
-- No-op while Load() is running to prevent save-during-restore loops.
function SaveManager:ScheduleAutoSave()
	if _loading or _savePending then return end
	_savePending = true
	task.delay(0.5, function()
		_savePending = false
		if not _loading then
			self:Save(_activeProfile)
		end
	end)
end

SaveManager._scheduleAutoSave = SaveManager.ScheduleAutoSave

-- ── BuildConfigTab ────────────────────────────────────────────────────────────
-- Creates a "Config" tab on window with:
--   • Profile name input  (drives _activeProfile — NOT read from element internals)
--   • Saved profiles dropdown (refreshes after every Save/Delete)
--   • Save / Load / Delete buttons with success + error feedback
--   • Auto-save toggle
--
-- Internal flags (__SM_*) are added to _ignored so they're never written to disk.
--
-- Usage:
--   SaveManager:BuildConfigTab(Window)    -- call after CreateWindow
function SaveManager:BuildConfigTab(window: any)
	-- Mark internal flags as ignored — idempotent, safe to call multiple times.
	_ignored["__SM_input_profile"] = true
	_ignored["__SM_dd_profiles"]   = true
	_ignored["__SM_toggle_auto"]   = true

	local tab = window:CreateTab({
		name    = "Config",
		icon    = "lucide:save",
		columns = 1,
	})

	local col = tab.Left

	-- ── Profile name ──────────────────────────────────────────────────────────
	col:CreateSection({ name = "Profile" })

	-- The callback drives _activeProfile directly — no reading element internals.
	local profileInput = col:CreateInput({
		name         = "Profile Name",
		placeholder  = "flags  (default)",
		flag         = "__SM_input_profile",
		value        = _activeProfile,
		clearOnFocus = false,
		callback     = function(v: string)
			local trimmed = v:match("^%s*(.-)%s*$") or ""
			_activeProfile = if #trimmed > 0 then trimmed else "flags"
		end,
	})

	local ddHandle: any = nil

	local function refreshDropdown()
		if not ddHandle then return end
		local list = self:List()
		ddHandle:SetOptions(if #list > 0 then list else { "(no profiles)" })
	end

	-- Dropdown picks autofill _activeProfile.
	ddHandle = col:CreateDropdown({
		name        = "Saved Profiles",
		options     = (function()
			local list = self:List()
			return if #list > 0 then list else { "(no profiles)" }
		end)(),
		placeholder = "select to autofill name...",
		flag        = "__SM_dd_profiles",
		callback    = function(value: string | { string })
			local pick = if type(value) == "string"
				then value :: string
				else (value :: { string })[1] or ""
			-- Ignore the placeholder entry
			if pick == "(no profiles)" then return end
			_activeProfile = pick
			-- Sync the input field visual text and flag value
			profileInput:Set(pick, true)
		end,
	})

	-- ── Actions ───────────────────────────────────────────────────────────────
	col:CreateSection({ name = "Actions" })

	col:CreateButton({
		name        = "Save",
		description = "Write all flags to the active profile.",
		callback    = function()
			local name = _activeProfile
			local ok   = self:Save(name)
			refreshDropdown()
			if ok then
				ddHandle:Set(name, true)
				window:Notify({
					title   = "Saved",
					content = "Profile '" .. name .. "' written to disk.",
					type    = "success",
					duration = 3,
				})
			else
				window:Notify({
					title   = "Save Failed",
					content = "Could not write '" .. name .. "'. Check executor filesystem.",
					type    = "error",
					duration = 4,
				})
			end
		end,
	})

	col:CreateButton({
		name        = "Load",
		description = "Restore flags from the active profile.",
		callback    = function()
			local name  = _activeProfile
			local count = self:Load(name)
			if count > 0 then
				window:Notify({
					title   = "Loaded",
					content = "Profile '" .. name .. "' — " .. tostring(count) .. " flags restored.",
					type    = "success",
					duration = 3,
				})
			else
				window:Notify({
					title   = "Load",
					content = "Profile '" .. name .. "' not found or empty.",
					type    = "warning",
					duration = 3,
				})
			end
		end,
	})

	col:CreateButton({
		name        = "Delete",
		description = "Permanently remove the active profile from disk.",
		callback    = function()
			local name = _activeProfile
			local ok   = self:Delete(name)
			refreshDropdown()
			if ok then
				_activeProfile = "flags"
				profileInput:Set("flags", true)
				ddHandle:Set("flags", true)
				window:Notify({
					title   = "Deleted",
					content = "Profile '" .. name .. "' removed.",
					type    = "info",
					duration = 3,
				})
			else
				window:Notify({
					title   = "Delete Failed",
					content = "Profile '" .. name .. "' not found.",
					type    = "error",
					duration = 3,
				})
			end
		end,
	})

	-- ── Auto-save ─────────────────────────────────────────────────────────────
	col:CreateSection({ name = "Auto Save" })

	col:CreateToggle({
		name        = "Auto Save",
		description = "Save every " .. tostring(_autoInterval) .. " s to the active profile.",
		flag        = "__SM_toggle_auto",
		value       = false,
		callback    = function(enabled: boolean)
			if enabled then
				self:StartAutoSave()
				window:Notify({
					title   = "Auto Save On",
					content = "Saving every " .. tostring(_autoInterval) .. " s to '" .. _activeProfile .. "'.",
					type    = "info",
					duration = 3,
				})
			else
				self:StopAutoSave()
				window:Notify({
					title   = "Auto Save Off",
					content = "Stopped.",
					type    = "info",
					duration = 2,
				})
			end
		end,
	})
end

return SaveManager
