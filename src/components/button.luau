--!strict

-- Delirium UI Library
-- button.luau — Clickable action element with hover animation.

local constants = require(script.Parent.Parent.utility.constants)
local tween     = require(script.Parent.Parent.utility.tween)
local element   = require(script.Parent.Parent.utility.element)
local themeUtil = require(script.Parent.Parent.utility.theme)

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
	local titleLabel, descLabel = element.createTitle(frame, name, description, theme, 12)

	local currentTheme = theme
	local btn = element.wireHover(frame, stroke, function() return currentTheme end, function()
		tween.fire(stroke, constants.tweenFast, {
			Color = currentTheme.AccentColor or Color3.fromHex("#4cc2ff"),
		})
		task.delay(0.15, function()
			tween.fire(stroke, constants.tweenFast, {
				Color = currentTheme.ElementStroke or Color3.fromHex("#2b2b2b"),
			})
		end)
		if callback then task.spawn(callback) end
	end)

	local self = setmetatable({}, Button) :: Button
	self._frame = frame
	;(self :: any)._themeUnsub = themeUtil.subscribe(function(t)
		currentTheme = t
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
	end, frame)

	return self
end

function Button:Destroy()
	local s = self :: any
	if s._themeUnsub then s._themeUnsub() end
	self._frame:Destroy()
end

return Button
