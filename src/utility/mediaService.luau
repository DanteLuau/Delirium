--!strict

-- Delirium UI Library
-- mediaService.luau — Single entry-point for external images and fonts.
-- Require this once in Init.lua (or wherever the library boots) and pass the
-- returned singleton around. Neither image.luau nor fontLoader.luau need to be
-- required directly by components — call through here.
--
-- Usage example (Init.lua):
--
--   local MediaService = require(script.utility.mediaService)
--
--   -- Optional: preload an icon manifest before the window opens so icons are
--   -- ready on first render. manifest = { [id: number]: url: string }
--   MediaService:preloadImages(MY_ICON_MANIFEST, function(failed)
--     if failed > 0 then
--       warn("[Delirium] " .. failed .. " icon(s) failed to cache")
--     end
--   end)
--
--   -- Assign an image to a GUI property (handles pending rebind automatically)
--   MediaService:assignImage(myLabel, "Image", 80384652)
--
--   -- Resolve an image to a URI string
--   local uri = MediaService:resolveImage(80384652)
--
--   -- Load an external font by manifest asset id (e.g. an Inter manifest)
--   local inter = MediaService:loadFont(123456789, {
--     weight = Enum.FontWeight.SemiBold,
--     style  = Enum.FontStyle.Normal,
--   })
--   myLabel.FontFace = inter or Font.fromEnum(Enum.Font.SourceSans)
--
--   -- Avatar headshots
--   local uri = MediaService:avatar(userId, function(resolved)
--     myLabel.Image = resolved
--   end)

local image      = require(script.Parent.image)
local FontLoader = require(script.Parent.fontLoader)

-- ── Singleton ─────────────────────────────────────────────────────────────────

local MediaService = {}
MediaService.__index = MediaService

-- One FontLoader instance shared across all font requests so the memory cache
-- is global and a font never downloads twice in the same session.
local fontLoader = FontLoader.new()

-- ── Image API ─────────────────────────────────────────────────────────────────

-- Kick off background caching of all images in `manifest`.
-- manifest: { [id: number]: url: string }
-- onSettled(failed) fires when every download has resolved.
function MediaService:preloadImages(
	manifest:   { [number]: string },
	onSettled:  ((failed: number) -> ())?
): (boolean, number)
	return image.preload(manifest, onSettled)
end

-- Assigns `value` (id, rbxassetid string, or number) to `instance[property]`,
-- with an automatic rebind queued if the file hasn't cached yet.
function MediaService:assignImage(instance: Instance, property: string, value: unknown)
	image.assign(instance, property, value)
end

-- Resolves `value` to a URI string; returns "" if the asset isn't available yet.
function MediaService:resolveImage(value: unknown): string
	return image.resolve(value)
end

-- Hooks into the onBlock callback so you can surface missed images.
function MediaService:setOnBlock(fn: (value: unknown) -> ())
	image.onBlock = fn
end

-- ── Avatar API ────────────────────────────────────────────────────────────────

-- Returns a custom asset URI for a user's headshot if already on disk.
-- If not yet cached, fires `onReady(uri)` when the download lands.
function MediaService:avatar(userId: number, onReady: ((uri: string) -> ())?): string
	return image.avatar(userId, onReady)
end

-- ── Font API ──────────────────────────────────────────────────────────────────

-- Loads an external font by Roblox asset id (the manifest JSON asset).
-- Returns a Font object or opts.fallback / SourceSans on any failure.
--
-- opts: {
--   weight:     Enum.FontWeight  (default Regular)
--   style:      Enum.FontStyle   (default Normal)
--   saveToDisk: boolean          (default true — false degrades to fallback)
--   skipCache:  boolean          (default false)
--   fallback:   Font             (default SourceSans)
-- }
function MediaService:loadFont(
	id:   number | string,
	opts: {
		weight:     Enum.FontWeight?,
		style:      Enum.FontStyle?,
		saveToDisk: boolean?,
		skipCache:  boolean?,
		fallback:   Font?,
	}?
): Font?
	return fontLoader:load(id, opts)
end

-- Quick lookup: returns the cached Font for an id (any variant), nil if not loaded.
function MediaService:resolveFont(id: number | string): Font?
	return fontLoader:resolve(id)
end

-- Assigns a font to instance[property] and registers an auto-rebind so the
-- property updates automatically once the download lands — no restart needed.
--
-- Usage:
--   MediaService:bindFont(myLabel, "FontFace", 12187277209, {
--     weight = Enum.FontWeight.SemiBold,
--   })
--
-- Every call to bindFont with the same id shares one background load task.
-- Instances that are destroyed before the font lands are silently skipped.
function MediaService:bindFont(
	instance: Instance,
	property: string,
	id:       number | string,
	opts: {
		weight:     Enum.FontWeight?,
		style:      Enum.FontStyle?,
		saveToDisk: boolean?,
		fallback:   Font?,
	}?
)
	fontLoader:bind(instance, property, id, opts)
end

return MediaService
