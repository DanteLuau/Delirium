--!strict

-- Delirium UI Library
-- element.luau — Shared element frame factory.
-- Builds the standard Frame + UICorner + UIGradient + UIStroke structure
-- used by all interactive components. Previously duplicated across 7 files.

local constants = require(script.Parent.constants)
local runtime   = require(script.Parent.runtime)

local element = {}

-- Returns the root Frame and its UIStroke so callers can tween the stroke
-- without a FindFirstChildOfClass search.
--
-- Parameters:
--   name   — Instance.Name for the frame (e.g. "Toggle_MyFlag")
--   theme  — active theme table (may be {})
--   parent — where to parent the frame
--   height — pixel height; defaults to constants.elementHeight if nil
function element.makeFrame(
	name:   string,
	theme:  { [string]: any },
	parent: Instance,
	height: number?
): (Frame, UIStroke)
	local h = height or constants.elementHeight

	local frame = Instance.new("Frame")
	frame.Name                   = name
	frame.Size                   = UDim2.new(1, 0, 0, h)
	frame.BackgroundColor3       = Color3.fromRGB(255, 255, 255)
	frame.BackgroundTransparency = theme.ElementTransparency or 0
	frame.BorderSizePixel        = 0
	frame.LayoutOrder            = 0
	frame.Parent                 = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = theme.ElementCornerRadius or UDim.new(0, 10)
	corner.Parent       = frame

	local gradient = Instance.new("UIGradient")
	gradient.Color    = theme.ElementGradient
		or ColorSequence.new(Color3.fromRGB(28, 24, 44))
	gradient.Rotation = 90
	gradient.Parent   = frame

	local stroke = Instance.new("UIStroke")
	stroke.Color        = theme.ElementStroke or Color3.fromRGB(50, 42, 80)
	stroke.Thickness    = 1
	stroke.Transparency = theme.ElementStrokeTransparency or 0
	stroke.Parent       = frame

	return frame, stroke, gradient
end

-- Creates a full-coverage dark overlay parented to `parent`.
-- Toggle .Visible to show/hide. Reuse for any modal, panel, or picker dim.
-- `zIndex`       — ZIndex relative to parent's other children (Sibling mode)
-- `transparency` — 0 = fully opaque black, 1 = invisible (default 0.55)
function element.makeOverlay(parent: Instance, zIndex: number, transparency: number?): Frame
	local overlay = Instance.new("Frame")
	overlay.Name                   = "Overlay"
	overlay.Size                   = UDim2.fromScale(1, 1)
	overlay.Position               = UDim2.fromScale(0, 0)
	overlay.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = transparency or 0.55
	overlay.BorderSizePixel        = 0
	overlay.ZIndex                 = zIndex
	overlay.Visible                = false
	overlay.Parent                 = parent
	return overlay
end

-- Checks whether a screen coordinate (Vector2 or Vector3) is inside a GuiObject.
function element.isInside(pos: Vector2 | Vector3, guiObj: GuiObject): boolean
	local ap = guiObj.AbsolutePosition
	local as = guiObj.AbsoluteSize
	return pos.X >= ap.X and pos.X <= (ap.X + as.X) and pos.Y >= ap.Y and pos.Y <= (ap.Y + as.Y)
end

-- Dynamically listens for clicks or touches outside the given GuiObjects.
-- Returns an unsubscribe cleanup function.
function element.onOutsideClick(targets: { GuiObject }, callback: () -> ()): () -> ()
	local conn: RBXScriptConnection? = nil
	conn = runtime.userInputService.InputBegan:Connect(function(input: InputObject)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		local pos = input.Position
		for _, target in ipairs(targets) do
			if target.Visible and element.isInside(pos, target) then
				return
			end
		end
		callback()
	end)

	return function()
		if conn then
			conn:Disconnect()
			conn = nil
		end
	end
end

return element
