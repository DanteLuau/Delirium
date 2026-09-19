--!strict

-- Delirium UI Library
-- toggle.luau — Boolean toggle switch with sliding knob animation.
-- Persists value to Flags registry when a flag key is provided.

local constants = require(script.Parent.Parent.utility.constants)
local tween     = require(script.Parent.Parent.utility.tween)
local flags     = require(script.Parent.Parent.utility.flags)
local element   = require(script.Parent.Parent.utility.element)
local themeUtil   = require(script.Parent.Parent.utility.theme)
local variables   = require(script.Parent.Parent.utility.variables)

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
	local description = props.description or ""
	local flagKey: string? = props.flag or (props :: any).Flag
	local callback    = props.callback

	-- Resolve initial value from Flags if the key exists
	local initValue: boolean
	if flagKey and flags:Get(flagKey) ~= nil then
		initValue = flags:Get(flagKey) :: boolean
	else
		initValue = props.value == true
	end

	-- ── Frame ──────────────────────────────────────────────────────────────
	local frame, stroke, gradient = element.makeFrame("Toggle_" .. name, theme, parent)

	-- ── Text content ──────────────────────────────────────────────────────
	local inner = Instance.new("Frame")
	inner.Name                   = "Inner"
	inner.Size                   = UDim2.new(1, -56, 1, 0)  -- leave room for switch
	inner.BackgroundTransparency = 1
	inner.Parent                 = frame

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 12)
	padding.Parent      = inner

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name                   = "Title"
	titleLabel.Size                   = UDim2.fromScale(1, 1)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text                   = name
	titleLabel.TextColor3             = theme.ContentColor or Color3.fromRGB(220, 215, 240)
	titleLabel.TextSize               = 13
	titleLabel.FontFace               = theme.Font or Font.new("rbxasset://fonts/families/GothamSSm.json")
	titleLabel.TextXAlignment         = Enum.TextXAlignment.Left
	titleLabel.TextYAlignment         = Enum.TextYAlignment.Center
	titleLabel.TextTruncate           = Enum.TextTruncate.AtEnd
	titleLabel.Parent                 = inner

	-- ── Switch widget ──────────────────────────────────────────────────────
	-- Track
	local trackW, trackH = 36, 20
	local track = Instance.new("Frame")
	track.Name             = "Track"
	track.AnchorPoint      = Vector2.new(1, 0.5)
	track.Position         = UDim2.new(1, -12, 0.5, 0)
	track.Size             = UDim2.fromOffset(trackW, trackH)
	track.BackgroundColor3 = theme.ToggleTrack or Color3.fromRGB(0, 0, 0)
	track.BackgroundTransparency = theme.ToggleTrackTransparency or 0.85
	track.BorderSizePixel  = 0
	track.Parent           = frame

	local trackCorner = Instance.new("UICorner")
	trackCorner.CornerRadius = UDim.new(1, 0)
	trackCorner.Parent       = track

	-- Knob
	local knobSize = trackH - 6
	local knob = Instance.new("Frame")
	knob.Name             = "Knob"
	knob.AnchorPoint      = Vector2.new(0, 0.5)
	knob.Position         = UDim2.new(0, 3, 0.5, 0)
	knob.Size             = UDim2.fromOffset(knobSize, knobSize)
	knob.BackgroundColor3 = theme.ToggleKnobOff or Color3.fromRGB(200, 195, 220)
	knob.BackgroundTransparency = theme.ToggleKnobOffTransparency or 0.5
	knob.BorderSizePixel  = 0
	knob.ZIndex           = 2
	knob.Parent           = track

	local knobCorner = Instance.new("UICorner")
	knobCorner.CornerRadius = UDim.new(1, 0)
	knobCorner.Parent       = knob

	-- Accent glow on track (hidden when off)
	local glow = Instance.new("Frame")
	glow.Name                   = "Glow"
	glow.Size                   = UDim2.fromScale(1, 1)
	glow.BackgroundColor3       = theme.AccentColor or Color3.fromRGB(124, 58, 237)
	glow.BackgroundTransparency = 1
	glow.BorderSizePixel        = 0
	glow.ZIndex                 = 1
	glow.Parent                 = track

	local glowCorner = Instance.new("UICorner")
	glowCorner.CornerRadius = UDim.new(1, 0)
	glowCorner.Parent       = glow

	-- ── Self ─────────────────────────────────────────────────────────────
	local self = setmetatable({}, Toggle) :: Toggle
	self.value  = initValue
	self._frame = frame
	;(self :: any)._knob     = knob
	;(self :: any)._glow     = glow
	;(self :: any)._stroke   = stroke
	;(self :: any)._track    = track
	;(self :: any)._theme    = theme
	;(self :: any)._flag     = flagKey
	;(self :: any)._callback = callback
	;(self :: any)._trackW   = trackW
	;(self :: any)._knobSize = knobSize

	-- Theme subscription
	;(self :: any)._themeUnsub = themeUtil.subscribe(function(t)
		self._theme = t
		frame.BackgroundTransparency = t.ElementTransparency or 0
		stroke.Color = t.ElementStroke or Color3.fromHex("#2b2b2b")
		stroke.Transparency = t.ElementStrokeTransparency or 0
		titleLabel.TextColor3 = t.ContentColor or Color3.fromHex("#ffffff")
		titleLabel.FontFace = t.Font or Font.new("rbxasset://fonts/families/GothamSSm.json")
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
		gradient.Color = t.ElementGradient or ColorSequence.new(Color3.fromRGB(28, 24, 44))
		theme = t
	end, frame)

	-- Apply initial visual state without firing callback
	self:Set(initValue, true)

	-- ── Interaction ───────────────────────────────────────────────────────
	local btn = Instance.new("TextButton")
	btn.Name                   = "Interact"
	btn.Size                   = UDim2.fromScale(1, 1)
	btn.BackgroundTransparency = 1
	btn.Text                   = ""
	btn.AutoButtonColor        = false
	btn.Parent                 = frame

	btn.MouseEnter:Connect(function()
		if variables.settingsOpen then return end
		tween.fire(stroke, constants.tweenFast, {
			Color = theme.ElementStrokeHover or theme.AccentColor or Color3.fromHex("#4cc2ff"),
		})
	end)
	btn.MouseLeave:Connect(function()
		tween.fire(stroke, constants.tweenFast, {
			Color = theme.ElementStroke or Color3.fromHex("#2b2b2b"),
		})
	end)
	btn.MouseButton1Click:Connect(function()
		self:Set(not self.value)
	end)

	return self
end

function Toggle:Set(value: boolean, skipCallback: boolean?)
	self.value = value

	local knob: Frame  = (self :: any)._knob
	local glow: Frame  = (self :: any)._glow
	local theme        = (self :: any)._theme
	local trackW: number = (self :: any)._trackW
	local knobSize: number = (self :: any)._knobSize
	local flagKey      = (self :: any)._flag
	local callback     = (self :: any)._callback

	local accent = theme.AccentColor or Color3.fromRGB(124, 58, 237)
	local knobOffColor = theme.ToggleKnobOff or Color3.fromRGB(200, 195, 220)
	local glowAlpha = theme.AccentGlow or 0.4

	if value then
		tween.fire(knob, constants.tweenFast, {
			Position          = UDim2.new(0, trackW - knobSize - 3, 0.5, 0),
			BackgroundColor3  = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 0,
		})
		tween.fire(glow, constants.tweenFast, {
			BackgroundTransparency = glowAlpha,
		})
	else
		tween.fire(knob, constants.tweenFast, {
			Position          = UDim2.new(0, 3, 0.5, 0),
			BackgroundColor3  = knobOffColor,
			BackgroundTransparency = theme.ToggleKnobOffTransparency or 0.5,
		})
		tween.fire(glow, constants.tweenFast, {
			BackgroundTransparency = 1,
		})
	end

	if flagKey then
		flags:Set(flagKey, value)
	end

	if not skipCallback and callback then
		task.spawn(callback, value)
	end
end

function Toggle:Destroy()
	local s = (self :: any)
	if s._themeUnsub then s._themeUnsub() end
	if s._descriptor then s._descriptor:Destroy() end
	self._frame:Destroy()
end

return Toggle
