--!strict

-- SaveManager — singleton flag registry + persistence layer.
-- Components register their own get/set callbacks via Register().
-- Save/Load use executor writefile/readfile (pcall-guarded, silent on failure).
-- AutoSave fires on every component Changed event (debounced 0.5s).
-- _loading guard prevents autosave loops during Load().
-- _pendingLoad carries forward flags loaded before a component registered.

local HttpService = game:GetService("HttpService")

-- ── Types ─────────────────────────────────────────────────────────────────────

type FlagEntry = {
	get : () -> any,
	set : (value: any) -> (),
}

-- ── Module state ──────────────────────────────────────────────────────────────

local SaveManager = {}
SaveManager.__index = SaveManager

-- Live flag values exposed to the outside world.
-- Read-only by convention — components update via their own SetValue, not here.
local Flags: { [string]: any } = {}

local _registry    : { [string]: FlagEntry } = {}
local _pendingLoad : { [string]: any }        = {}  -- deserialized values for late-registered flags
local _folder      : string  = "Delirium"
local _loading     : boolean = false
local _loaded      : boolean = false

-- ── Helpers ───────────────────────────────────────────────────────────────────

local function filePath(): string
	return _folder .. "/flags.json"
end

-- Serializes a KeyCode to its name string so it survives JSON round-trips.
local function serializeValue(v: any): any
	if typeof(v) == "EnumItem" then
		return { __enumType = "KeyCode", __name = (v :: Enum.KeyCode).Name }
	end
	return v
end

-- Inverse of serializeValue.
local function deserializeValue(v: any): any
	if type(v) == "table" and v.__enumType == "KeyCode" then
		local ok, result = pcall(function()
			return (Enum.KeyCode :: any)[v.__name]
		end)
		if ok and result then
			return result
		end
	end
	return v
end

-- ── Public API ────────────────────────────────────────────────────────────────

-- Derives a deterministic flag name from a human-readable label.
-- Lowercase, spaces → underscore, non-alphanumeric stripped, capped at 48 chars.
-- Returns "" if the result is empty (caller should skip registration).
function SaveManager.deriveFlagFromName(label: string): string
	local sanitized = label
		:lower()
		:gsub("%s+", "_")
		:gsub("[^%w_]", "")
		:sub(1, 48)
	return sanitized
end

-- Register a flag. Called by components in their constructor.
-- get() must return the current value.
-- set(value) must apply the value WITHOUT firing Changed (to avoid autoSave loops).
-- If Load() already ran and this flag had a stored value, it is applied immediately.
function SaveManager.Register(flag: string, get: () -> any, set: (value: any) -> ())
	-- Silent overwrite: Studio's module cache keeps the singleton alive between re-runs,
	-- so duplicate registration is expected noise, not a real collision.
	-- Components that genuinely share a flag name will still silently clobber each other
	-- (which is the correct behavior — last writer wins, first load wins via _pendingLoad).
	_registry[flag] = { get = get, set = set }
	Flags[flag]     = get()

	-- Apply any value that was loaded before this component registered.
	local pending = _pendingLoad[flag]
	if pending ~= nil then
		pcall(set, pending)
		Flags[flag] = pending
		-- Do NOT clear from _pendingLoad — a second Register (duplicate) may need it.
	end
end

-- Change the folder name. Call before Load/Save.
function SaveManager.SetFolder(name: string)
	_folder = name
end

-- Serialize all flags to JSON and write to disk.
-- Silent no-op if writefile is not available (non-executor context).
function SaveManager.Save()
	local data: { [string]: any } = {}
	for flag, entry in pairs(_registry) do
		local v = entry.get()
		Flags[flag] = v
		data[flag] = serializeValue(v)
	end

	local ok, encoded = pcall(HttpService.JSONEncode, HttpService, data)
	if not ok then return end

	-- writefile is an executor global — not available in Studio/live Roblox.
	local wfOk = pcall(function()
		local writefile = (getfenv and getfenv(0).writefile) or rawget(_G, "writefile")
		if type(writefile) == "function" then
			-- makefolder if available — ignore errors
			local makefolder = (getfenv and getfenv(0).makefolder) or rawget(_G, "makefolder")
			if type(makefolder) == "function" then
				pcall(makefolder, _folder)
			end
			writefile(filePath(), encoded)
		end
	end)
	_ = wfOk
end

-- Read from disk and apply to all registered flags.
-- Flags that have no registered entry yet are stored in _pendingLoad
-- and applied the moment their component calls Register().
function SaveManager.Load()
	local raw: string? = nil

	pcall(function()
		local readfile = (getfenv and getfenv(0).readfile) or rawget(_G, "readfile")
		if type(readfile) ~= "function" then return end

		local isfile = (getfenv and getfenv(0).isfile) or rawget(_G, "isfile")
		if type(isfile) == "function" and not isfile(filePath()) then return end

		raw = readfile(filePath())
	end)

	if not raw or raw == "" then return end

	local ok, data = pcall(HttpService.JSONDecode, HttpService, raw)
	if not ok or type(data) ~= "table" then return end

	-- Guard: suppress _scheduleAutoSave for the duration of Load.
	_loading = true

	for flag, rawValue in pairs(data) do
		local value = deserializeValue(rawValue)
		-- Store for any component that registers after this Load() call.
		_pendingLoad[flag] = value

		local entry = _registry[flag]
		if entry then
			pcall(entry.set, value)
			Flags[flag] = value
		end
	end

	_loading = false
	_loaded  = true
end

-- Called by components after Changed fires to persist the updated value.
-- Debounced at the module level to avoid hammering disk on rapid changes.
local _savePending = false
function SaveManager._scheduleAutoSave()
	if _loading then return end
	if _savePending then return end
	_savePending = true
	task.delay(0.5, function()
		_savePending = false
		SaveManager.Save()
	end)
end

-- Expose live Flags table (read-only by convention).
SaveManager.Flags = Flags

return SaveManager
