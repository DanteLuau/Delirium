--!strict

-- Delirium UI Library
-- imageCache.luau — Disk-backed PNG cache + avatar headshots.
-- Responsibility: take an image manifest ({ [id]: url }), write each PNG to
-- disk once, then expose getcustomasset URIs so Roblox accepts them without
-- going through the CDN firewall. The disk file is the persistence layer;
-- the LRU in assetFetcher is only the per-session fast path.

local filesystem = require(script.Parent.filesystem)
local AssetFetcher = require(script.Parent.assetFetcher)
local services    = require(script.Parent.services)

local IS_STUDIO = services.getService("RunService"):IsStudio()

-- ── Types ─────────────────────────────────────────────────────────────────────

export type RewriteMap  = { [number]: string }
export type OnSettled   = (failed: number) -> ()
export type OnCached    = (id: number) -> ()
export type AvatarReady = (uri: string) -> ()

-- ── Module state ──────────────────────────────────────────────────────────────

local CACHE_ROOT    = "Delirium"
local CACHE_ASSETS  = "Delirium/Assets"

-- Thumbnail endpoint; 48 px matches Rayfield's headshotPx default.
local THUMB_ENDPOINT =
	"https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds=%d&size=48x48&format=Png&isCircular=false"

local PNG_MAGIC = "\137PNG\r\n\26\n"

-- Fetcher singleton shared by the whole module
local fetcher = AssetFetcher.new()

local imageCache = {}

-- rewrites[id] → "rbxtemp://..." URI string, once the file is on disk.
-- image.luau reads this table directly.
imageCache.rewrites = {} :: RewriteMap

-- Set by image.luau after require() so it can rebind blank UI properties when
-- a background download lands.
imageCache.onCached = nil :: OnCached?

-- ── Internal helpers ──────────────────────────────────────────────────────────

local env = getfenv()

-- Writes `body` to disk at `filePath` and converts it to a custom asset URI.
-- Returns nil when:
--   • the executor has no getcustomasset / file API
--   • the body fails the PNG magic check (error page, HTML redirect)
--   • any disk write or getcustomasset call errors
local function cacheFile(filePath: string, url: string, cacheKey: number | string): string?
	if type(env.getcustomasset) ~= "function" or typeof(filesystem.isfile) ~= "function" then
		return nil
	end

	if not filesystem.isfile(filePath) then
		pcall(filesystem.ensureFolder, CACHE_ROOT)
		pcall(filesystem.ensureFolder, CACHE_ASSETS)

		local body = fetcher:getContentFromUrl(url, cacheKey, false)
		-- never write a non-PNG body — an error page cached to disk would shadow
		-- the real asset on every subsequent session
		if not body or string.sub(body, 1, 8) ~= PNG_MAGIC then
			return nil
		end
		if not pcall(filesystem.writefile, filePath, body) then
			return nil
		end
	end

	local ok, uri = pcall(env.getcustomasset, filePath)
	return if ok and type(uri) == "string" then uri else nil
end

local function avatarFilePath(userId: number): string
	return CACHE_ASSETS .. "/avatar_" .. tostring(userId) .. ".png"
end

-- Parses the Roblox thumbnail API response, which is an unreliable mess, and
-- returns the CDN image URL or nil.
local function decodeThumbnailUrl(body: string): string?
	local services = require(script.Parent.services)
	local httpService = services.getService("HttpService")
	local ok, parsed = pcall(function()
		return httpService:JSONDecode(body)
	end)
	if not ok or type(parsed) ~= "table" then return nil end
	local data = (parsed :: any).data
	if type(data) ~= "table" then return nil end
	local entry = (data :: any)[1]
	if type(entry) ~= "table" then return nil end
	if entry.state == "Completed" and type(entry.imageUrl) == "string" then
		return entry.imageUrl
	end
	return nil
end

-- Polls the thumbnail API with up to 4 retries (state can be "Pending" on first hit)
-- then pipes the CDN URL through cacheFile.
local function fetchAndCacheAvatar(userId: number): string?
	local cdnUrl: string? = nil
	for attempt = 1, 4 do
		local url = string.format(THUMB_ENDPOINT, userId)
		local cacheKey = "thumb:" .. tostring(userId)
		local body = fetcher:getContentFromUrl(url, cacheKey, attempt > 1)
		if body then
			local imageUrl = decodeThumbnailUrl(body)
			if imageUrl then
				cdnUrl = imageUrl
				break
			end
		end
		task.wait(0.3)
	end
	if not cdnUrl then return nil end
	return cacheFile(avatarFilePath(userId), cdnUrl, "avatar_" .. tostring(userId))
end

-- ── Public API ────────────────────────────────────────────────────────────────

-- Preloads a manifest of images, writing each to disk in background tasks,
-- then fires onSettled(failed) once all downloads have resolved (failed = count
-- that never cached, so callers can log without per-icon noise).
--
-- manifest: { [id: number]: url: string }
-- Returns (allAlreadyCached: boolean, missCount: number).
function imageCache.preload(manifest: { [number]: string }, onSettled: OnSettled?): (boolean, number)
	local manifestSize = 0
	for _ in manifest do manifestSize += 1 end

	if IS_STUDIO then
		-- No getcustomasset in Studio, but numeric ids resolve fine via
		-- rbxassetid:// passthrough in image.resolve() — not a real failure.
		if onSettled then task.defer(onSettled, 0) end
		return true, 0
	end

	if type(env.getcustomasset) ~= "function" or typeof(filesystem.isfile) ~= "function" then
		if onSettled then task.defer(onSettled, manifestSize) end
		return false, manifestSize
	end

	local rewrites = imageCache.rewrites
	table.clear(rewrites)

	local function settle()
		if not onSettled then return end
		local failed = 0
		for id in manifest do
			if not rewrites[id] then failed += 1 end
		end
		onSettled(failed)
	end

	local pending  = 0
	local missing  = 0
	local spawning = true -- guard: stop a synchronous-finishing download from settling mid-loop

	for id, url in manifest do
		local filePath = CACHE_ASSETS .. "/" .. tostring(id) .. ".png"

		local uri: string? = nil
		if filesystem.isfile(filePath) then
			local ok, res = pcall(env.getcustomasset, filePath)
			uri = if ok and type(res) == "string" then res else nil
		end

		if uri then
			rewrites[id] = uri
		else
			missing += 1
			pending += 1
			task.spawn(function()
				local cached = cacheFile(filePath, url, id)
				if cached then
					rewrites[id] = cached
					if imageCache.onCached then
						pcall(imageCache.onCached, id)
					end
				end
				pending -= 1
				if pending == 0 and not spawning then
					settle()
				end
			end)
		end
	end

	spawning = false
	if pending == 0 then settle() end

	return missing == 0, missing
end

-- Returns a custom asset URI for a user's avatar headshot.
-- If onReady is provided the download runs in the background and the callback
-- fires with the URI once it lands; the return value is "" in the meantime.
function imageCache.avatar(userId: number, onReady: AvatarReady?): string
	-- Studio: no executor request fn exists, use rbxthumb:// directly.
	-- This works in Studio and is visually identical to the disk-cached version.
	if IS_STUDIO then
		local uri = string.format(
			"rbxthumb://type=AvatarHeadShot&id=%d&w=48&h=48",
			userId
		)
		if onReady then task.defer(onReady, uri) end
		return uri
	end

	if typeof(filesystem.isfile) ~= "function" then return "" end

	local filePath = avatarFilePath(userId)
	if filesystem.isfile(filePath) then
		local ok, uri = pcall(env.getcustomasset, filePath)
		if ok and type(uri) == "string" then return uri end
	end

	if onReady then
		task.spawn(function()
			local uri = fetchAndCacheAvatar(userId)
			if uri then onReady(uri) end
		end)
	end

	return ""
end

return imageCache
