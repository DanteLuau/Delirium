--!strict

-- Delirium UI Library
-- image.luau — Image resolution & property assignment facade.
-- Wraps imageCache so callers never touch the cache or pending-rebind tables
-- directly. Key idea: in a normal executor run, images that aren't disk-cached
-- yet resolve to "" on first assign. The pending table remembers which
-- instances are waiting, and once imageCache fires onCached those properties
-- get the real URI dropped in.

local imageCache = require(script.Parent.imageCache)

export type OnSettled   = imageCache.OnSettled
export type AvatarReady = imageCache.AvatarReady

-- ── Module state ──────────────────────────────────────────────────────────────

local image = {}

-- Expose the rewrite map so external callers (e.g. icon helpers) can read it.
image.rewrites = imageCache.rewrites

-- Set this to intercept blocked/empty image assignments (optional telemetry hook).
image.onBlock = nil :: ((value: unknown) -> ())?

-- Tracks instances waiting on a background download, keyed weakly on Instance
-- so destroyed UI doesn't stay pinned. Layout: pending[id][instance][property] = true
--
-- Weak-key metatable applied per id-slot so individual instances GC freely.
image.pending = {} :: { [number]: { [Instance]: { [string]: boolean } } }

-- Once preload() fires onSettled nothing else can land, so we drop the table.
local settled = false

-- Only these properties on ImageLabel / ImageButton take image URIs.
local imageProperties: { [string]: boolean } = {
	Image        = true,
	HoverImage   = true,
	PressedImage = true,
}

-- ── Helpers ───────────────────────────────────────────────────────────────────

local function idOf(value: unknown): number?
	if type(value) == "number" then return value end
	if type(value) == "string" then
		return tonumber(string.match(value :: string, "^rbxassetid://(%d+)$"))
	end
	return nil
end

local function blocked(value: unknown): string
	if image.onBlock then image.onBlock(value) end
	return ""
end

-- ── imageCache callback: rebind pending instances when a download lands ───────

imageCache.onCached = function(id: number)
	local waiting = image.pending[id]
	if not waiting then return end
	local uri = image.rewrites[id]
	if uri then
		for instance, props in waiting do
			if instance.Parent then
				local t = instance :: any
				for prop in props do
					t[prop] = uri
				end
			end
		end
	end
	image.pending[id] = nil
end

-- ── Public API ────────────────────────────────────────────────────────────────

-- Kick off manifest pre-caching. onSettled(failed) fires once every background
-- download resolves. Returns (allAlreadyCached, missCount).
function image.preload(manifest: { [number]: string }, onSettled: OnSettled?): (boolean, number)
	settled = false
	return imageCache.preload(manifest, function(failed)
		settled = true
		table.clear(image.pending)
		if onSettled then onSettled(failed) end
	end)
end

-- Returns the custom asset URI for a user avatar headshot.
function image.avatar(userId: number, onReady: AvatarReady?): string
	return imageCache.avatar(userId, onReady)
end

-- Resolves any image value to a string safe to assign to an image property:
--   number        → "rbxassetid://<n>"  (or rewrite URI if cached)
--   "rbxassetid://..." → rewrite URI if cached, else the string itself
--   "rbxasset://..."   → passthrough (built-in asset, always valid)
--   nil / 0 / "" → ""
function image.resolve(value: unknown): string
	if value == nil or value == 0 or value == "" then return "" end

	if type(value) == "string" then
		local s = value :: string
		-- built-in assets: always valid, no disk needed
		if string.sub(s, 1, 11) == "rbxasset://" then return s end
	end

	local id: number? = idOf(value)
	if id then
		local rewrite = image.rewrites[id]
		if rewrite then return rewrite end
	end

	-- Not yet cached. If we have no id at all (e.g. a bare URL string or
	-- rbxthumb) we can't cache it, so just pass it through.
	if type(value) == "number" then
		return "rbxassetid://" .. tostring(value)
	end
	if type(value) == "string" then
		return value
	end

	return blocked(value)
end

-- Assigns an image value to `property` on `instance`, queuing a rebind if the
-- image isn't cached yet so it appears automatically once the download lands.
-- For non-image properties (e.g. BackgroundColor3) this degrades to a direct set.
function image.assign(instance: Instance, property: string, value: unknown)
	local target = instance :: any

	if not imageProperties[property] then
		target[property] = value
		return
	end

	target[property] = image.resolve(value)

	-- Queue a rebind if the image is missing from the rewrite map and
	-- preload hasn't settled yet (after settle, nothing new will ever land).
	if not settled then
		local id = idOf(value)
		if id and not image.rewrites[id] then
			local slot = image.pending[id]
			if not slot then
				-- weak so destroyed instances don't pin this table forever
				slot = setmetatable({}, { __mode = "k" }) :: any
				image.pending[id] = slot
			end
			local props = slot[instance]
			if not props then
				props = {}
				slot[instance] = props
			end
			props[property] = true
		end
	end
end

return image
