--!strict

-- Delirium UI Library
-- button.luau — Clickable action element with hover animation.

local constants = require(script.Parent.Parent.utility.constants)
local tween     = require(script.Parent.Parent.utility.tween)
local element     = require(script.Parent.Parent.utility.element)
local themeUtil   = require(script.Parent.Parent.utility.theme)
local variables   = require(script.Parent.Parent.utility.variables)

export type ButtonProps = {
	name:        string?,
	description: string?,
	callback:    (() -> ())?,
}

export type Button = {
	_frame:  Frame,
	Destroy: (self: Button) -> (),
}

local Button = {}
Button.__index = Button

function Button.new(props: ButtonProps, theme: { [string]: any }, parent: Instance): Button
	local name        = props.name or "Button"
	local description = props.description or ""
	local callback    = props.callback

	local frame, stroke, gradient = element.makeFrame("Button_" .. name, theme, parent)

	-- Inner layout
	local inner = Instance.new("Frame")
	inner.Name                   = "Inner"
	inner.Size                   = UDim2.new(1, 0, 1, 0)
	inner.BackgroundTransparency = 1
	inner.Parent                 = frame

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft  = UDim.new(0, 12)
	padding.PaddingRight = UDim.new(0, 12)
	padding.Parent       = inner

	local layout = Instance.new("UIListLayout")
	layout.FillDirection  = Enum.FillDirection.Vertical
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Padding        = UDim.new(0, 1)
	layout.Parent         = inner

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name                   = "Title"
	titleLabel.Size                   = UDim2.new(1, 0, 0, 18)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text                   = name
	titleLabel.TextColor3             = theme.ContentColor or Color3.fromRGB(220, 215, 240)
	titleLabel.TextSize               = 13
	titleLabel.FontFace               = theme.Font or Font.new("rbxasset://fonts/families/GothamSSm.json")
	titleLabel.TextXAlignment         = Enum.TextXAlignment.Left
	titleLabel.TextTruncate           = Enum.TextTruncate.AtEnd
	titleLabel.Parent                 = inner

	local descLabel: TextLabel? = nil
	if description ~= "" then
		descLabel = Instance.new("TextLabel")
		descLabel.Name                   = "Description"
		descLabel.Size                   = UDim2.new(1, 0, 0, 14)
		descLabel.BackgroundTransparency = 1
		descLabel.Text                   = description
		descLabel.TextColor3             = theme.PlaceholderColor or Color3.fromRGB(140, 130, 175)
		descLabel.TextSize               = 11
		descLabel.FontFace               = theme.Font or Font.new("rbxasset://fonts/families/GothamSSm.json")
		descLabel.TextXAlignment         = Enum.TextXAlignment.Left
		descLabel.TextTruncate           = Enum.TextTruncate.AtEnd
		descLabel.Parent                 = inner
	end

	-- Interaction button overlay
	local btn = Instance.new("TextButton")
	btn.Name                   = "Interact"
	btn.Size                   = UDim2.fromScale(1, 1)
	btn.BackgroundTransparency = 1
	btn.Text                   = ""
	btn.AutoButtonColor        = false
	btn.Parent                 = frame

	-- Hover effect
	btn.MouseEnter:Connect(function()
		if variables.settingsOpen then return end
		tween.fire(frame, constants.tweenFast, {
			BackgroundTransparency = math.max(0, (theme.ElementTransparency or 0) - 0.06),
		})
		tween.fire(stroke, constants.tweenFast, {
			Color = theme.ElementStrokeHover or theme.AccentColor or Color3.fromHex("#4cc2ff"),
			Transparency = theme.ElementStrokeHoverTransparency or 0,
		})
	end)
	btn.MouseLeave:Connect(function()
		tween.fire(frame, constants.tweenFast, {
			BackgroundTransparency = theme.ElementTransparency or 0,
		})
		tween.fire(stroke, constants.tweenFast, {
			Color = theme.ElementStroke or Color3.fromHex("#2b2b2b"),
			Transparency = theme.ElementStrokeTransparency or 0,
		})
	end)
	btn.MouseButton1Click:Connect(function()
		-- Brief press feedback: flash stroke accent
		tween.fire(stroke, constants.tweenFast, {
			Color = theme.AccentColor or Color3.fromHex("#4cc2ff"),
		})
		task.delay(0.15, function()
			tween.fire(stroke, constants.tweenFast, {
				Color = theme.ElementStroke or Color3.fromHex("#2b2b2b"),
			})
		end)
		if callback then
			task.spawn(callback)
		end
	end)

	local self = setmetatable({}, Button) :: Button
	self._frame = frame
	;(self :: any)._themeUnsub = themeUtil.subscribe(function(t)
		frame.BackgroundTransparency = t.ElementTransparency or 0
		stroke.Color = t.ElementStroke or Color3.fromHex("#2b2b2b")
		stroke.Transparency = t.ElementStrokeTransparency or 0
		titleLabel.TextColor3 = t.ContentColor or Color3.fromHex("#ffffff")
		titleLabel.FontFace = t.Font or constants.DEFAULT_FONT
		if descLabel then
			descLabel.TextColor3 = t.PlaceholderColor or Color3.fromHex("#9d9d9d")
			descLabel.FontFace = t.Font or constants.DEFAULT_FONT
		end
		gradient.Color = t.ElementGradient or ColorSequence.new(Color3.fromRGB(28, 24, 44))
		theme = t
	end, frame)
	return self
end

function Button:Destroy()
	local s = (self :: any)
	if s._themeUnsub then s._themeUnsub() end
	self._frame:Destroy()
end

return Button
