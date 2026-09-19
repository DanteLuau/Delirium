--!strict

-- Delirium UI Library
-- utility/icons.luau — Nebula Icon Library loader and icon resolver.
-- Ports Loader.luau with multi-tier caching (in-memory, getgenv) and built-in fallbacks.

-- B5 FIX: was raw game:GetService — use cloneref-safe wrapper.
local services        = require(script.Parent.services)
local filesystem      = require(script.Parent.filesystem)
local ContentProvider = services.getService("ContentProvider") :: ContentProvider

export type IconPackName =
	"Lucide"
	| "Material"
	| "Phosphor"
	| "Phosphor-Filled"
	| "SF"
	| "Symbols"
	| "Symbols-Filled"
	| "Lab"
	| "Fluency"

local PACK_URLS: { [string]: string } = {
	["Lucide"]          = "https://raw.githubusercontent.com/Nebula-Softworks/Nebula-Icon-Library/master/LucideIcons.luau",
	["Material"]        = "https://raw.githubusercontent.com/Nebula-Softworks/Nebula-Icon-Library/master/MaterialIcons.luau",
	["Phosphor"]        = "https://raw.githubusercontent.com/Nebula-Softworks/Nebula-Icon-Library/refs/heads/master/Phosphor.luau",
	["Phosphor-Filled"] = "https://raw.githubusercontent.com/Nebula-Softworks/Nebula-Icon-Library/refs/heads/master/Phosphor%20Filled.luau",
	["SF"]              = "https://raw.githubusercontent.com/Nebula-Softworks/Nebula-Icon-Library/refs/heads/master/SFSymbols.luau",
	["Symbols"]         = "https://raw.githubusercontent.com/Nebula-Softworks/Nebula-Icon-Library/refs/heads/master/Symbols.luau",
	["Symbols-Filled"]  = "https://raw.githubusercontent.com/Nebula-Softworks/Nebula-Icon-Library/refs/heads/master/Symbols-Filled.luau",
	["Lab"]             = "https://raw.githubusercontent.com/Nebula-Softworks/Nebula-Icon-Library/refs/heads/master/LucideLab.luau",
	["Fluency"]         = "https://raw.githubusercontent.com/Nebula-Softworks/Nebula-Icon-Library/refs/heads/master/Fluency.luau",
}

local PREFIX_TO_PACK: { [string]: string } = {
	["lucide"]          = "Lucide",
	["material"]        = "Material",
	["phosphor"]        = "Phosphor",
	["phosphor-filled"] = "Phosphor-Filled",
	["sf"]              = "SF",
	["symbol"]          = "Symbols",
	["symbols"]         = "Symbols",
	["symbol-filled"]   = "Symbols-Filled",
	["symbols-filled"]  = "Symbols-Filled",
	["lab"]             = "Lab",
	["fluency"]         = "Fluency",
	["nebula"]          = "nebulaIcons",
}

-- Built-in instant fallback IDs for core icons (guaranteed available even offline / prior to HttpGet)
local BUILTIN_ICONS: { [string]: number } = {
	-- Window chrome & navigation
	["settings"]      = 10734950309,
	["settings-2"]    = 75339943202126,
	["minus"]         = 120931250449806,
	["minimize"]      = 120931250449806,
	["minimize-2"]    = 115725194133672,
	["maximize-2"]    = 108777312690515,
	["x"]             = 136096054247483,
	["close"]         = 136096054247483,
	["check"]         = 83827110621355,
	["plus"]          = 118563428285930,
	["chevron-down"]  = 95086910949405,
	["chevron-right"] = 126507964682213,
	["chevron-left"]  = 83856486110301,
	["chevron-up"]    = 124630674114245,
	["search"]        = 125618569555993,
	["lock"]          = 71897067930472,
	["user"]          = 81899856845503,
	["globe"]         = 111578783307093,
	-- Semantic notification icons
	["info"]          = 10723415903,
	["success"]       = 10709790387,
	["warning"]       = 10709752935,
	["error"]         = 10747384394,
	-- Popular general icons
	["sword"]         = 10723407389,
	["swords"]        = 10723407389,
	["eye"]           = 10734975692,
	["home"]          = 111043355839507,
}

local module: any = {}

-- Native Nebula built-in icons
module.nebulaIcons = {
	stripes       = 8834748103,
	circles       = 73048796459024,
	nebula        = 76656741080367,
	home          = 111043355839507,
	keycache      = 13587387127,
	apps          = 13300918120,
	view_in_ar    = 113380429914565,
	home_material = 9080449299,
	location      = 6034996695,
	sparkle       = 4483362748,
}

-- ── Caching Helpers ──────────────────────────────────────────────────────────

local CACHE_KEY_PREFIX = "__DeliriumNebula_"

local function getGenvTable(packName: string): { [string]: number }?
	if type(getgenv) == "function" then
		local ok, env = pcall(getgenv)
		if ok and type(env) == "table" then
			local t = env[CACHE_KEY_PREFIX .. packName]
			if type(t) == "table" then
				return t
			end
		end
	end
	return nil
end

local function setGenvTable(packName: string, data: { [string]: number })
	if type(getgenv) == "function" then
		local ok, env = pcall(getgenv)
		if ok and type(env) == "table" then
			pcall(function() env[CACHE_KEY_PREFIX .. packName] = data end)
		end
	end
end

-- ── Lazy Pack Loader (L1: memory, L2: getgenv, L3: disk, L4: network) ───────
local ICONS_DIR = "Delirium/assets/icons"

local function loadPack(packName: string): { [string]: number }?
	if module[packName] and type(module[packName]) == "table" then
		return module[packName]
	end

	-- L1: getgenv cache
	local genvData = getGenvTable(packName)
	if genvData then
		module[packName] = genvData
		return genvData
	end

	-- L2: disk cache (Delirium/assets/icons/<packName>.lua)
	local diskPath = ICONS_DIR .. "/" .. packName .. ".lua"
	local diskOk, diskSrc = pcall(function()
		if filesystem.isfile(diskPath) then
			return filesystem.readfile(diskPath)
		end
		return nil
	end)

	if diskOk and diskSrc and #diskSrc > 10 then
		local diskFn = loadstring(diskSrc)
		if diskFn then
			local okRun, diskTable = pcall(diskFn)
			if okRun and type(diskTable) == "table" then
				module[packName] = diskTable
				setGenvTable(packName, diskTable)
				return diskTable
			end
		end
	end

	-- L3: HTTP fetch from GitHub raw
	local url = PACK_URLS[packName]
	if not url then return nil end

	local ok, loaded = pcall(function()
		local httpGet = (game :: any).HttpGetAsync or (game :: any).HttpGet
		if not httpGet then return nil end
		local src = httpGet(game, url)
		if not src or #src < 10 then return nil end

		-- Save to disk asynchronously so next launch is instant
		pcall(function()
			filesystem.ensureDir(ICONS_DIR)
			filesystem.writefile(diskPath, src)
		end)

		local fn = loadstring(src)
		if not fn then return nil end
		return fn()
	end)

	if ok and type(loaded) == "table" then
		module[packName] = loaded
		setGenvTable(packName, loaded)
		return loaded
	end

	return nil
end

-- ── Public API ───────────────────────────────────────────────────────────────

-- GetIcon: matches Nebula Loader:GetIcon(name, source)
-- Returns number ID. source defaults to "Lucide".
function module:GetIcon(name: string, source: string?): number?
	local packName = source or "Lucide"

	-- 1. Check nebulaIcons table directly
	if packName == "nebulaIcons" or packName == "nebula" then
		local id = module.nebulaIcons[name]
		if id then return id end
	end

	-- 2. Check loaded or cached pack
	local pack = module[packName] or loadPack(packName)
	if pack and pack[name] then
		local id = pack[name]
		if type(id) == "number" then
			pcall(function()
				ContentProvider:PreloadAsync({ "rbxassetid://" .. tostring(id) })
			end)
			return id
		end
	end

	-- 3. Check built-in fallback table
	if BUILTIN_ICONS[name] then
		return BUILTIN_ICONS[name]
	end

	return nil
end

-- GetAssetUri: returns full "rbxassetid://<id>" or nil
function module.GetAssetUri(name: string, source: string?): string?
	local id = module:GetIcon(name, source)
	if id then
		return "rbxassetid://" .. tostring(id)
	end
	return nil
end

-- Resolve: universal icon resolver for Delirium components
-- Supports:
--   - 123456789 -> "rbxassetid://123456789"
--   - "123456789" -> "rbxassetid://123456789"
--   - "rbxassetid://..." or "roblox://..." -> as-is
--   - "lucide:settings" -> resolves from Lucide pack
--   - "symbol:search" -> resolves from Symbols pack
--   - "settings" -> checks built-in fallback, then Lucide, then Symbols
function module.Resolve(icon: (string | number)?, defaultSource: string?): string?
	if not icon or icon == "" then return nil end

	-- Numeric asset ID
	if type(icon) == "number" or tonumber(icon) ~= nil then
		return "rbxassetid://" .. tostring(icon)
	end

	local str = tostring(icon)

	-- Direct URI
	if string.sub(str, 1, 13) == "rbxassetid://" or string.sub(str, 1, 9) == "roblox://" or string.sub(str, 1, 4) == "http" then
		return str
	end

	-- Prefix format: "prefix:icon-name"
	local prefix, iconName = string.match(str, "^([%w%-_]+):([%w%-_]+)$")
	if prefix and iconName then
		local packName = PREFIX_TO_PACK[string.lower(prefix)] or prefix
		local id = module:GetIcon(iconName, packName)
		if id then
			return "rbxassetid://" .. tostring(id)
		end
	end

	-- Direct name lookup
	local fallbackPack = defaultSource or "Lucide"
	local directId = module:GetIcon(str, fallbackPack)
		or module:GetIcon(str, "Symbols")
		or BUILTIN_ICONS[str]

	if directId then
		return "rbxassetid://" .. tostring(directId)
	end

	return str
end

-- Preload a pack asynchronously without blocking the UI
function module.PreloadPack(packName: string)
	task.spawn(function()
		loadPack(packName)
	end)
end

return module
