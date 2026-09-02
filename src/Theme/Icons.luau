--!strict

local NEBULA_URL = "https://raw.githubusercontent.com/Nebula-Softworks/Nebula-Icon-Library/refs/heads/master/Loader.luau"
local FALLBACK_ID = "rbxassetid://0"

local _cache: { [string]: string } = {}
local _lib: any = nil
local _loaded = false

local function tryLoad(): boolean
	if _loaded then return _lib ~= nil end
	_loaded = true

	local httpOk, httpResult = pcall(function()
		return game:GetService("HttpService")
	end)
	if not httpOk then return false end

	local fetchOk, source = pcall(function()
		return game:HttpGet(NEBULA_URL)
	end)
	if not fetchOk or type(source) ~= "string" then
		warn("[Delirium Icons] HTTP fetch failed — falling back to placeholder icons.")
		return false
	end

	local loadOk, result = pcall(function()
		return loadstring(source)()
	end)
	if not loadOk or type(result) ~= "table" then
		warn("[Delirium Icons] Nebula loadstring failed — falling back to placeholder icons.")
		return false
	end

	_lib = result
	return true
end

local Icons = {}
Icons.IsLoaded = false

function Icons.Init()
	Icons.IsLoaded = tryLoad()
end

function Icons.Get(name: string): string
	if _cache[name] then return _cache[name] end

	if not _lib then
		_cache[name] = FALLBACK_ID
		return FALLBACK_ID
	end

	local ok, id = pcall(function()
		return _lib[name] or _lib.get and _lib:get(name) or FALLBACK_ID
	end)

	local result = (ok and type(id) == "string") and id or FALLBACK_ID
	_cache[name] = result
	return result
end

function Icons.ClearCache()
	table.clear(_cache)
end

return Icons
