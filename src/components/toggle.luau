--!strict

-- Delirium UI Library
-- toggle.luau — Boolean toggle switch with sliding knob animation.

local constants = require(script.Parent.Parent.utility.constants)
local tween     = require(script.Parent.Parent.utility.tween)
local flags     = require(script.Parent.Parent.utility.flags)
local element   = require(script.Parent.Parent.utility.element)
local themeUtil = require(script.Parent.Parent.utility.theme)

export type ToggleProps = {
	name:        string?,
	description: string?,
	flag:        string?,
	value:       boolean?,
	callback:    ((value: boolean) -> ())?,
}

export type Toggle = {
	value:   boolean,
	_frame:  Frame,
	Set:     (self: Toggle, value: boolean, skipCallback: boolean?) -> (),
	Destroy: (self: Toggle) -> (),
}

local Toggle = {}
Toggle.__index = Toggle

function Toggle.new(props: ToggleProps, theme: { [string]: any }, parent: Instance): Toggle
	local name        = props.name or "Toggle"
	local flagKey: string? = props.flag or (props :: any).Flag
	local callback    = props.callback

	local initValue: boolean
	if flagKey and flags:Get(flagKey) ~= nil then
		initValue = flags:Get(flagKey) :: boolean
	else
		initValue = props.value == true
	end

	local frame, stroke, gradient = element.makeFrame("Toggle_" .. name, theme, parent)
	local titleLabel = element.createTitle(frame, name, nil, theme, 56)

	-- Track & Knob
	local trackW, trackH = 36, 20
	local knobSize = trackH - 6

	local track = Instance.new("Frame")
	track.Name                   = "Track"
	track.AnchorPoint            = Vector2.new(1, 0.5)
	track.Position               = UDim2.new(1, -12, 0.5, 0)
	track.Size                   = UDim2.fromOffset(trackW, trackH)
	track.BackgroundColor3       = theme.ToggleTrack or Color3.fromRGB(0, 0, 0)
	track.BackgroundTransparency = theme.ToggleTrackTransparency or 0.85
	track.BorderSizePixel        = 0
	track.Parent                 = frame
	do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1, 0); c.Parent = track end

	local knob = Instance.new("Frame")
	knob.Name                   = "Knob"
	knob.AnchorPoint            = Vector2.new(0, 0.5)
	knob.Position               = UDim2.new(0, 3, 0.5, 0)
	knob.Size                   = UDim2.fromOffset(knobSize, knobSize)
	knob.BackgroundColor3       = theme.ToggleKnobOff or Color3.fromRGB(200, 195, 220)
	knob.BackgroundTransparency = theme.ToggleKnobOffTransparency or 0.5
	knob.BorderSizePixel        = 0
	knob.ZIndex                 = 2
	knob.Parent                 = track
	do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1, 0); c.Parent = knob end

	local glow = Instance.new("Frame")
	glow.Name                   = "Glow"
	glow.Size                   = UDim2.fromScale(1, 1)
	glow.BackgroundColor3       = theme.AccentColor or Color3.fromRGB(124, 58, 237)
	glow.BackgroundTransparency = 1
	glow.BorderSizePixel        = 0
	glow.ZIndex                 = 1
	glow.Parent                 = track
	do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1, 0); c.Parent = glow end

	local self = setmetatable({}, Toggle) :: Toggle
	self.value  = initValue
	self._frame = frame

	local s = self :: any
	s._knob     = knob
	s._glow     = glow
	s._track    = track
	s._theme    = theme
	s._flag     = flagKey
	s._callback = callback
	s._trackW   = trackW
	s._knobSize = knobSize

	local currentTheme = theme
	element.wireHover(frame, stroke, function() return currentTheme end, function()
		self:Set(not self.value)
	end)

	s._themeUnsub = themeUtil.subscribe(function(t)
		currentTheme = t
		s._theme     = t
		frame.BackgroundTransparency = t.ElementTransparency or 0
		stroke.Color = t.ElementStroke or Color3.fromHex("#2b2b2b")
		stroke.Transparency = t.ElementStrokeTransparency or 0
		titleLabel.TextColor3 = t.ContentColor or Color3.fromHex("#ffffff")
		titleLabel.FontFace = t.Font or constants.DEFAULT_FONT
		track.BackgroundColor3 = t.ToggleTrack or Color3.fromRGB(0, 0, 0)
		track.BackgroundTransparency = t.ToggleTrackTransparency or 0.85
		if self.value then
			knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			knob.BackgroundTransparency = 0
		else
			knob.BackgroundColor3 = t.ToggleKnobOff or Color3.fromHex("#9d9d9d")
			knob.BackgroundTransparency = t.ToggleKnobOffTransparency or 0.5
		end
		glow.BackgroundColor3 = t.AccentColor or Color3.fromHex("#4cc2ff")
		gradient.Color = t.ElementGradient or ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromHex("#2e2e2e")),
			ColorSequenceKeypoint.new(1, Color3.fromHex("#181818")),
		})
	end, frame)

	self:Set(initValue, true)
	return self
end

function Toggle:Set(value: boolean, skipCallback: boolean?)
	self.value = value

	local s = self :: any
	local knob: Frame      = s._knob
	local glow: Frame      = s._glow
	local theme            = s._theme
	local trackW: number   = s._trackW
	local knobSize: number = s._knobSize

	local knobOffColor = theme.ToggleKnobOff or Color3.fromRGB(200, 195, 220)
	local glowAlpha    = theme.AccentGlow or 0.4

	if value then
		tween.fire(knob, constants.tweenFast, {
			Position               = UDim2.new(0, trackW - knobSize - 3, 0.5, 0),
			BackgroundColor3       = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 0,
		})
		tween.fire(glow, constants.tweenFast, {
			BackgroundTransparency = glowAlpha,
		})
	else
		tween.fire(knob, constants.tweenFast, {
			Position               = UDim2.new(0, 3, 0.5, 0),
			BackgroundColor3       = knobOffColor,
			BackgroundTransparency = theme.ToggleKnobOffTransparency or 0.5,
		})
		tween.fire(glow, constants.tweenFast, {
			BackgroundTransparency = 1,
		})
	end

	if s._flag then
		flags:Set(s._flag, value)
	end

	if not skipCallback and s._callback then
		task.spawn(s._callback, value)
	end
end

function Toggle:Destroy()
	local s = self :: any
	if s._themeUnsub then s._themeUnsub() end
	if s._descriptor then s._descriptor:Destroy() end
	self._frame:Destroy()
end

return Toggle
