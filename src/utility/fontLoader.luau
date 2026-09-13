--!strict

-- Delirium UI Library
-- fontLoader.luau — External font loading via executor disk cache.
-- How it works:
--   1. Caller supplies a numeric asset id (the manifest JSON asset on Roblox).
--   2. We download the manifest JSON once, write it to disk, then iterate each face.
--   3. Each face (.ttf) is downloaded, PNG-style signature-checked, and written to disk.
--   4. getcustomasset() converts each disk path to a local URI.
--   5. We rewrite face assetIds in the manifest to those local URIs, write a second
--      manifest.json, getcustomasset() that too, and hand it to Font.new().
--   6. All variants (weight × style) are created from the same local manifest.
--   7. Everything is cached in memory so repeat calls for the same id are instant.
--
-- Falls back to `fallbackFont` on any failure — never throws to the caller.

local filesystem  = require(script.Parent.filesystem)
local AssetFetcher = require(script.Parent.assetFetcher)
local services    = require(script.Parent.services)

local httpService = services.getService("HttpService")
local runService  = services.getService("RunService")

-- ── Types ─────────────────────────────────────────────────────────────────────

export type FontFace = {
	name:    string,
	weight:  number,
	style:   string,
	assetId: string,
}

export type FontManifest = {
	name:  string,
	faces: { FontFace },
}

export type CachedFont = {
	customId:      string,           -- getcustomasset URI of the local manifest.json
	manifest:      FontManifest,
	variants:      { [string]: Font },
}

export type LoadOptions = {
	weight:      Enum.FontWeight?,
	style:       Enum.FontStyle?,
	saveToDisk:  boolean?,
	skipCache:   boolean?,
	fallback:    Font?,
}

export type FontLoader = {
	load:    (self: FontLoader, id: number | string, opts: LoadOptions?) -> Font?,
	resolve: (self: FontLoader, id: number | string) -> Font?,
	bind:    (self: FontLoader, instance: Instance, property: string, id: number | string, opts: LoadOptions?) -> (),
}

-- ── Constants ─────────────────────────────────────────────────────────────────

local FONTS_ROOT    = "Delirium/Fonts"
local DEFAULT_FONT  = Font.fromEnum(Enum.Font.SourceSans)
local IS_STUDIO     = runService:IsStudio()

-- TrueType / OpenType / WOFF magic bytes for body validation.
local FONT_SIGNATURES = { "\0\1\0\0", "OTTO", "true", "ttcf", "wOFF", "wOF2" }

-- ── Helpers ───────────────────────────────────────────────────────────────────

local function isFontBody(body: string): boolean
	for _, sig in FONT_SIGNATURES do
		if string.sub(body, 1, #sig) == sig then return true end
	end
	return false
end

-- Strip characters that are unsafe in a file path, keeping alphanumerics,
-- spaces, dashes, underscores, and dots.
local function sanitizeName(name: string): string
	return string.gsub(name, "[^%w%s%-_%.]+", "")
end

local function variantKey(weight: Enum.FontWeight, style: Enum.FontStyle): string
	return tostring(weight.Value) .. "|" .. tostring(style.Value)
end

local function jsonDecode(s: string): unknown?
	local ok, result = pcall(function()
		return httpService:JSONDecode(s)
	end)
	return if ok then result else nil
end

local function jsonEncode(data: unknown): string?
	local ok, result = pcall(function()
		return httpService:JSONEncode(data)
	end)
	return if ok and type(result) == "string" then result else nil
end

-- Parses and validates the font manifest table coming off the network.
-- sanitizes face names in-place so they're safe to use as filenames.
local function validateManifest(raw: unknown): FontManifest?
	if type(raw) ~= "table" then return nil end
	local m = raw :: any
	if type(m.name) ~= "string" or type(m.faces) ~= "table" then return nil end
	m.name = sanitizeName(m.name)
	if #m.name == 0 or #m.faces == 0 then return nil end
	for _, face in m.faces do
		if type(face) ~= "table" then return nil end
		if type(face.name) ~= "string" or type(face.assetId) ~= "string" then return nil end
		face.name = sanitizeName(face.name)
		if #face.name == 0 then return nil end
	end
	return m :: FontManifest
end

-- ── FontLoader ────────────────────────────────────────────────────────────────

local FontLoader = {}
FontLoader.__index = FontLoader

function FontLoader.new(): FontLoader
	local self = setmetatable({
		_cache    = {} :: { [number]: CachedFont },
		_fetcher  = AssetFetcher.new(),
		-- _bindings[id][instance][property] = LoadOptions?
		-- Weak keys on inner tables so GC'd UI doesn't pin the registry.
		_bindings = {} :: { [number]: any },
		_loading  = {} :: { [number]: boolean },
	}, FontLoader) :: any
	pcall(filesystem.ensureDir, FONTS_ROOT)
	return self
end

local function resolveId(value: unknown): number?
	if type(value) == "number" then return value end
	if type(value) == "string" then
		return tonumber(string.match(value :: string, "^rbxassetid://(%d+)$"))
			or tonumber(value)
	end
	return nil
end

-- Returns the cached Font for id (any weight/style), nil if not yet loaded.
function FontLoader.resolve(self: FontLoader, id: number | string): Font?
	local numId = resolveId(id)
	if not numId then return nil end
	local cached = (self :: any)._cache[numId]
	if not cached then return nil end
	for _, font in pairs(cached.variants) do return font end
	return nil
end

-- Core load entry-point.
-- opts.weight / opts.style select the variant (default Regular/Normal).
-- opts.saveToDisk = false degrades to the fallback — without disk there's no
--   way to hand a local URI to Font.new(), and loading from the raw rbxassetid
--   is detectable by anti-cheats.
-- opts.skipCache = true forces a fresh network round-trip even if memory-cached.
-- opts.fallback overrides the module-level fallback for this call.
function FontLoader.load(
	self:    FontLoader,
	id:      number | string,
	opts:    LoadOptions?
): Font?
	local cache:   { [number]: CachedFont } = (self :: any)._cache
	local fetcher: AssetFetcher            = (self :: any)._fetcher

	local weight     = (opts and opts.weight)     or Enum.FontWeight.Regular
	local style      = (opts and opts.style)      or Enum.FontStyle.Normal
	local saveToDisk = if opts and opts.saveToDisk ~= nil then opts.saveToDisk else true
	local skipCache  = if opts and opts.skipCache  ~= nil then opts.skipCache  else false
	local fallback   = (opts and opts.fallback) or DEFAULT_FONT
	local key        = variantKey(weight, style)

	local numId = resolveId(id)
	if not numId then
		warn("[Delirium:fontLoader] Invalid font id: " .. tostring(id))
		return fallback
	end

	-- 1. Memory cache hit
	if not skipCache then
		local cached = cache[numId]
		if cached then
			local hit = cached.variants[key]
			if hit then return hit end
			-- Manifest is loaded but this variant isn't; build it from the local URI.
			local ok, built = pcall(Font.new, cached.customId, weight, style)
			if ok and built then
				cached.variants[key] = built
				return built
			end
			-- Local manifest went stale; evict and re-download
			cache[numId] = nil
		end
	end

	-- 2. Disk-only path is mandatory for live use (see note above)
	if not saveToDisk then return fallback end

	-- 3. No getcustomasset → can't localise URIs → fall back
	local env = getfenv()
	if type(env.getcustomasset) ~= "function" or typeof(filesystem.isfile) ~= "function" then
		return fallback
	end

	pcall(filesystem.ensureDir, FONTS_ROOT)

	-- 4. Load / download the font manifest JSON
	local manifestPath = FONTS_ROOT .. "/" .. tostring(numId) .. ".json"
	local rawManifest: string? = nil
	local needsWrite = false

	if IS_STUDIO then
		-- Studio: inject a well-known manifest for developer preview
		rawManifest = '{"name":"Inter","faces":[' ..
			'{"name":"Regular","weight":400,"style":"normal","assetId":"rbxassetid://12187266066"},' ..
			'{"name":"Bold","weight":700,"style":"normal","assetId":"rbxassetid://12187275575"}' ..
		']}'
	elseif filesystem.isfile(manifestPath) then
		local ok, contents = pcall(filesystem.readfile, manifestPath)
		rawManifest = if ok then contents else nil
	else
		rawManifest = fetcher:getContentFromId(numId, false)
		needsWrite  = rawManifest ~= nil
	end

	if not rawManifest then return fallback end

	local manifest = validateManifest(jsonDecode(rawManifest))
	if not manifest then
		-- Corrupt or unrecognised body; evict the disk copy so next run retries
		pcall(filesystem.delfile, manifestPath)
		return fallback
	end
	if needsWrite then
		pcall(filesystem.writefile, manifestPath, rawManifest)
	end

	-- 5. Download each face and rewrite assetId → local URI
	local fontDir    = FONTS_ROOT .. "/" .. manifest.name
	local allLocal   = true

	pcall(filesystem.ensureDir, fontDir)

	for i, face in ipairs(manifest.faces) do
		local faceName = string.gsub(face.name, " ", "-")
		local facePath = fontDir .. "/" .. faceName .. ".ttf"

		if not filesystem.isfile(facePath) then
			local faceId = resolveId(face.assetId)
			local body: string? = if faceId
				then fetcher:getContentFromId(faceId, false)
				else nil

			if not body or not isFontBody(body) then
				allLocal = false
				warn(
					"[Delirium:fontLoader] Face download failed for id "
						.. tostring(numId) .. ", face: " .. face.name
				)
				continue
			end
			pcall(filesystem.writefile, facePath, body)
		end

		local ok, uri = pcall(env.getcustomasset, facePath)
		if ok and type(uri) == "string" then
			manifest.faces[i].assetId = uri
		else
			allLocal = false
			warn(
				"[Delirium:fontLoader] getcustomasset failed for face: "
					.. face.name
			)
		end
	end

	if not allLocal then return fallback end

	-- 6. Write the rewritten manifest and get a custom asset URI for it
	local rewrittenJson = jsonEncode(manifest)
	if not rewrittenJson then return fallback end

	local localManifestPath = fontDir .. "/manifest.json"
	if not pcall(filesystem.writefile, localManifestPath, rewrittenJson) then
		return fallback
	end

	local mOk, manifestUri = pcall(env.getcustomasset, localManifestPath)
	if not mOk or not manifestUri then return fallback end

	-- 7. Build the Font and cache it
	local fOk, font = pcall(Font.new, manifestUri, weight, style)
	if not fOk or not font then return fallback end

	local entry = cache[numId]
	if not entry then
		entry = { customId = manifestUri, manifest = manifest, variants = {} }
		cache[numId] = entry
	end
	entry.variants[key] = font
	return font
end

-- Assigns `value` to instance[property], queuing an auto-rebind if the font
-- isn't loaded yet. Kicks off a background load the first time an id is seen.
-- Once the font lands it's applied to every registered instance automatically.
function FontLoader.bind(
	self:     FontLoader,
	instance: Instance,
	property: string,
	id:       number | string,
	opts:     LoadOptions?
)
	local cache:    { [number]: CachedFont }  = (self :: any)._cache
	local bindings: { [number]: any }         = (self :: any)._bindings
	local loading:  { [number]: boolean }     = (self :: any)._loading

	local numId = resolveId(id)
	if not numId then
		warn("[Delirium:fontLoader] bind() — invalid id: " .. tostring(id))
		return
	end

	local weight = (opts and opts.weight) or Enum.FontWeight.Regular
	local style  = (opts and opts.style)  or Enum.FontStyle.Normal
	local key    = variantKey(weight, style)

	-- Already in memory → apply immediately, no need to register.
	local cached = cache[numId]
	if cached and cached.variants[key] then
		(instance :: any)[property] = cached.variants[key]
		return
	end

	-- Register this instance so it gets updated when the font lands.
	local slot = bindings[numId]
	if not slot then
		slot = setmetatable({}, { __mode = "k" }) :: any
		bindings[numId] = slot
	end
	local props = (slot :: any)[instance]
	if not props then
		props = {}
		(slot :: any)[instance] = props
	end
	(props :: any)[property] = opts

	-- Kick off the background load once per id (not once per binding).
	if loading[numId] then return end
	loading[numId] = true

	task.spawn(function()
		-- load() is synchronous-blocking; runs in spawned thread so UI doesn't stall.
		self:load(numId, opts)
		loading[numId] = nil

		-- Apply to every registered instance that's still in the DataModel.
		local bound = bindings[numId]
		if not bound then return end
		local c = cache[numId]
		if not c then return end

		for inst, instanceProps in (bound :: any) do
			if (inst :: Instance).Parent then
				local t = inst :: any
				for prop, bindOpts in (instanceProps :: any) do
					local bOpts   = bindOpts :: LoadOptions?
					local bWeight = (bOpts and bOpts.weight) or Enum.FontWeight.Regular
					local bStyle  = (bOpts and bOpts.style)  or Enum.FontStyle.Normal
					local bKey    = variantKey(bWeight, bStyle)
					local variant = c.variants[bKey]
					if variant then t[prop] = variant end
				end
			end
		end
	end)
end

return FontLoader
