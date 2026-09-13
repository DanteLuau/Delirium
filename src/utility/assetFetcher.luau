--!strict

-- Delirium UI Library
-- assetFetcher.luau — Downloads asset bodies by id or URL.
-- Wraps executor HTTP with an LRU session cache (8 slots) so rapid duplicate
-- fetches don't spam the wire. The disk layer in imageCache/fontLoader is what
-- persists across sessions; this is just the in-memory fast path for the current run.

local network  = require(script.Parent.network)
local services = require(script.Parent.services)

local IS_STUDIO = services.getService("RunService"):IsStudio()

-- ── Types ─────────────────────────────────────────────────────────────────────

export type AssetId = number | string
export type CacheKey = string | number

export type AssetFetcher = {
	resolve:            (self: AssetFetcher, value: unknown) -> AssetId?,
	getContentFromUrl:  (self: AssetFetcher, url: string, cacheKey: CacheKey?, forced: boolean?) -> string?,
	getContentFromId:   (self: AssetFetcher, id: AssetId, forced: boolean?) -> string?,
}

-- ── Private constants ─────────────────────────────────────────────────────────

-- roproxy mirrors the assetdelivery endpoint without Roblox's anti-exploit
-- CDN restrictions that break executor requests.
local DOWNLOAD_URL = "https://assetdelivery.roproxy.com/v1/asset?id=%d"

-- Session LRU cap — bodies are whole PNGs/TTFs, keep it lean.
local CACHE_LIMIT = 8

-- ── Implementation ────────────────────────────────────────────────────────────

local AssetFetcher = {}
AssetFetcher.__index = AssetFetcher

-- Executors disagree on response shape; treat the body as valid only when the
-- executor also reports success (2xx status or Success=true).
local function isGoodResponse(response: unknown): boolean
	if type(response) ~= "table" then return false end
	local r = response :: { Body: unknown, StatusCode: unknown, Success: unknown }
	if type(r.Body) ~= "string" or #(r.Body :: string) == 0 then return false end
	if type(r.StatusCode) == "number" then
		local code = r.StatusCode :: number
		return code >= 200 and code < 300
	end
	if type(r.Success) == "boolean" then
		return r.Success :: boolean
	end
	-- unknown shape — can't confirm the body is the asset
	return false
end

function AssetFetcher.new(): AssetFetcher
	local self = setmetatable({
		_cache      = {} :: { [CacheKey]: string },
		_cacheOrder = {} :: { CacheKey },
	}, AssetFetcher) :: any
	return self
end

-- Canonicalise a user-supplied value into a usable AssetId:
--   number  → returned as-is
--   "12345" → 12345 (bare numeric string)
--   "rbxassetid://12345" → 12345
--   "rbxasset://..." / "rbxthumb://..." → returned as-is (passthrough)
function AssetFetcher.resolve(_self: AssetFetcher, value: unknown): AssetId?
	if type(value) == "number" then return value end
	if type(value) ~= "string" then return nil end
	local s = value :: string
	if string.sub(s, 1, 11) == "rbxasset://" or string.sub(s, 1, 11) == "rbxthumb://" then
		return s
	end
	local id = tonumber(string.match(s, "^rbxassetid://(%d+)$")) or tonumber(s)
	return id or nil
end

-- Fetch a URL body, optionally keyed into the LRU session cache.
-- `forced = true` skips the session cache (used by retry loops).
function AssetFetcher.getContentFromUrl(
	self: AssetFetcher,
	url: string,
	cacheKey: CacheKey?,
	forced: boolean?
): string?
	local cache = self._cache :: { [CacheKey]: string }
	local order = self._cacheOrder :: { CacheKey }

	if cacheKey ~= nil and not forced then
		local hit = cache[cacheKey]
		if hit then
			-- B5 FIX: Refresh recency so a frequently-hit asset isn't evicted while
			-- a cold one stays. Without this, the LRU is effectively FIFO on hits.
			for i = 1, #order do
				if order[i] == cacheKey then
					table.remove(order, i)
					table.insert(order, cacheKey)
					break
				end
			end
			return hit
		end
	end

	local requestFn = network.getRequestFn()
	if not requestFn then
		-- Studio has no executor globals; warn only when running live.
		if not IS_STUDIO then
			warn("[Delirium:assetFetcher] No executor request function found.")
		end
		return nil
	end

	local ok, response = pcall(requestFn, { Url = url, Method = "GET" })
	if not ok or not isGoodResponse(response) then
		if not forced then
			warn("[Delirium:assetFetcher] Request failed for: " .. url)
		end
		return nil
	end

	local body = (response :: { Body: string }).Body
	if cacheKey ~= nil then
		if cache[cacheKey] == nil then
			table.insert(order, cacheKey)
			if #order > CACHE_LIMIT then
				local oldest = table.remove(order, 1)
				if oldest ~= nil then
					cache[oldest] = nil
				end
			end
		end
		cache[cacheKey] = body
	end
	return body
end

-- Convenience: resolve an asset id to a download URL and fetch it.
function AssetFetcher.getContentFromId(
	self: AssetFetcher,
	id: AssetId,
	forced: boolean?
): string?
	local resolved = self:resolve(id)
	if not resolved or type(resolved) ~= "number" then
		warn("[Delirium:assetFetcher] Invalid asset id: " .. tostring(id))
		return nil
	end
	local url = string.format(DOWNLOAD_URL, resolved :: number)
	return self:getContentFromUrl(url, resolved, forced)
end

return AssetFetcher
