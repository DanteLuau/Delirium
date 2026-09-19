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

-- Creates standard left-aligned title (+ optional description inside same row)
function element.createTitle(
	parent: Instance,
	name: string,
	desc: string?,
	theme: { [string]: any },
	rightOffset: number?
): (TextLabel, TextLabel?)
	local offset = rightOffset or 12
	local inner = Instance.new("Frame")
	inner.Name                   = "Inner"
	inner.Size                   = UDim2.new(1, -offset, 1, 0)
	inner.BackgroundTransparency = 1
	inner.Parent                 = parent

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft  = UDim.new(0, 12)
	padding.PaddingRight = UDim.new(0, 4)
	padding.Parent       = inner

	local hasDesc = desc ~= nil and desc ~= ""
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name                   = "Title"
	titleLabel.Size                   = if hasDesc then UDim2.new(1, 0, 0, 18) else UDim2.fromScale(1, 1)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text                   = name
	titleLabel.TextColor3             = theme.ContentColor or Color3.fromRGB(220, 215, 240)
	titleLabel.TextSize               = 13
	titleLabel.FontFace               = theme.Font or constants.DEFAULT_FONT
	titleLabel.TextXAlignment         = Enum.TextXAlignment.Left
	titleLabel.TextYAlignment         = Enum.TextYAlignment.Center
	titleLabel.TextTruncate           = Enum.TextTruncate.AtEnd
	titleLabel.Parent                 = inner

	local descLabel: TextLabel? = nil
	if hasDesc then
		local layout = Instance.new("UIListLayout")
		layout.FillDirection     = Enum.FillDirection.Vertical
		layout.VerticalAlignment = Enum.VerticalAlignment.Center
		layout.Padding           = UDim.new(0, 1)
		layout.Parent            = inner

		descLabel = Instance.new("TextLabel")
		descLabel.Name                   = "Description"
		descLabel.Size                   = UDim2.new(1, 0, 0, 14)
		descLabel.BackgroundTransparency = 1
		descLabel.Text                   = desc :: string
		descLabel.TextColor3             = theme.PlaceholderColor or Color3.fromRGB(140, 130, 175)
		descLabel.TextSize               = 11
		descLabel.FontFace               = theme.Font or constants.DEFAULT_FONT
		descLabel.TextXAlignment         = Enum.TextXAlignment.Left
		descLabel.TextTruncate           = Enum.TextTruncate.AtEnd
		descLabel.Parent                 = inner
	end

	return titleLabel, descLabel
end

-- Standard interaction overlay with hover/leave tweening
function element.wireHover(
	frame: Frame,
	stroke: UIStroke,
	themeRef: () -> { [string]: any },
	onClick: (() -> ())?
): TextButton
	local btn = Instance.new("TextButton")
	btn.Name                   = "Interact"
	btn.Size                   = UDim2.fromScale(1, 1)
	btn.BackgroundTransparency = 1
	btn.Text                   = ""
	btn.AutoButtonColor        = false
	btn.Parent                 = frame

	btn.MouseEnter:Connect(function()
		local variables = require(script.Parent.variables)
		local tween = require(script.Parent.tween)
		if variables.settingsOpen then return end
		local t = themeRef()
		tween.fire(frame, constants.tweenFast, {
			BackgroundTransparency = math.max(0, (t.ElementTransparency or 0) - 0.06),
		})
		tween.fire(stroke, constants.tweenFast, {
			Color        = t.ElementStrokeHover or t.AccentColor or Color3.fromHex("#4cc2ff"),
			Transparency = t.ElementStrokeHoverTransparency or 0,
		})
	end)

	btn.MouseLeave:Connect(function()
		local tween = require(script.Parent.tween)
		local t = themeRef()
		tween.fire(frame, constants.tweenFast, {
			BackgroundTransparency = t.ElementTransparency or 0,
		})
		tween.fire(stroke, constants.tweenFast, {
			Color        = t.ElementStroke or Color3.fromHex("#2b2b2b"),
			Transparency = t.ElementStrokeTransparency or 0,
		})
	end)

	if onClick then
		btn.MouseButton1Click:Connect(onClick)
	end

	return btn
end

return element
