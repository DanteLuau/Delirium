--!strict

-- Delirium UI Library
-- windowSizing.luau — Responsive window sizing against the active viewport.
-- Ported from Rayfield Gen2 (windowSizing.luau) and tuned for Delirium's layout.
--
-- fit(viewport) returns a UDim2.fromOffset(w, h) that:
--   • never exceeds 86% width / 80% height of the screen
--   • never drops below a pixel floor margin (20px x, 24px y)
--   • is capped at defaultSize on large screens
--   • scales down freely on small screens (no minSize floor that could exceed viewport)
--   • compensates width when height is forced down (so a short screen earns width back)
--   • returns the default size for any implausible viewport (camera mid-init, 1x1 reports)
--
-- computeScale(viewport) returns a 0–1 scale factor relative to a 1366×768 desktop
-- reference. Used by variables.uiScale and notification.luau to scale floating layers.

local constants = require(script.Parent.constants)

local windowSizing = {}

local defaultSize = constants.windowSize
local minSize     = constants.windowMinSize

-- Fraction of the viewport each axis is allowed to consume.
-- Vertical is tighter so the window never reads as filling the screen.
local maxOccupancyX, maxOccupancyY = 0.86, 0.80

-- Pixel floors: on a large monitor these dominate and give a margin.
-- On small screens the occupancy caps take over instead.
local marginFloorX, marginFloorY = 20, 24

-- When a short screen forces height down from the default, the window earns
-- extra width proportional to how much height it lost, capped by the aspect ceiling.
local widthCompensation = 60
local maxAspectRatio    = 1.80

-- Any axis below this is treated as a stale camera report. Skip sizing.
local minPlausibleViewport = 200

-- Desktop reference for computeScale(). 1366×768 = 1.0.
local REFERENCE = Vector2.new(1366, 768)

windowSizing.defaultSize = defaultSize
windowSizing.minSize     = minSize

-- Fraction of height lost relative to the full default→min range. 0 = nothing lost.
-- NOTE: on screens smaller than minSize.Y this exceeds 1.0; that is intentional—
-- the width compensation is then capped by availableX downstream.
local function heightDeficit(height: number): number
	return math.clamp(
		(defaultSize.Y - height) / (defaultSize.Y - minSize.Y),
		0, 1
	)
end

-- Returns the UDim2 size Delirium should use for the given viewport.
-- Pass nil (or an implausible viewport) to get the unmodified default.
function windowSizing.fit(viewport: Vector2?): UDim2
	if not viewport
		or viewport.X < minPlausibleViewport
		or viewport.Y < minPlausibleViewport
	then
		return UDim2.fromOffset(defaultSize.X, defaultSize.Y)
	end

	local availableX = math.min(viewport.X * maxOccupancyX, viewport.X - marginFloorX)
	local availableY = math.min(viewport.Y * maxOccupancyY, viewport.Y - marginFloorY)

	-- Height: cap at defaultSize but NEVER clamp up to minSize — on a phone screen
	-- where availableY < minSize.Y, the old clamp would produce a window taller than
	-- the viewport. Let it shrink freely; minSize is only a soft hint on large screens.
	local height = math.floor(math.min(availableY, defaultSize.Y))

	local deficit = heightDeficit(height)
	local width   = math.max(defaultSize.X + widthCompensation * deficit, minSize.X)

	-- Hard limits: screen edge and aspect ceiling.
	width = math.floor(math.min(width, availableX, height * maxAspectRatio))

	return UDim2.fromOffset(width, height)
end

-- Returns a 0–1 UI scale factor proportional to the current viewport relative to
-- the 1366×768 desktop reference. Clamped: never above 1.0 (desktop doesn't zoom),
-- never below 0.45 (smallest practical usable size).
-- Consumers: variables.uiScale (updated by Window), notification.luau.
function windowSizing.computeScale(viewport: Vector2?): number
	if not viewport
		or viewport.X < minPlausibleViewport
		or viewport.Y < minPlausibleViewport
	then
		return 1.0
	end
	local scaleX = viewport.X / REFERENCE.X
	local scaleY = viewport.Y / REFERENCE.Y
	return math.clamp(math.min(scaleX, scaleY), 0.45, 1.0)
end

return windowSizing
