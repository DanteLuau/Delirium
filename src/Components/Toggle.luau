--!strict

local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Maid   = require(script.Parent.Parent.Utils.Maid)
local Signal = require(script.Parent.Parent.Utils.Signal)
local Theme  = require(script.Parent.Parent.Theme)

-- Press / release feedback (unchanged — these are interaction, not state-change)
local TWEEN_PRESS   = TweenInfo.new(0.20, Enum.EasingStyle.Quint,       Enum.EasingDirection.Out)
local TWEEN_RELEASE = TweenInfo.new(0.35, Enum.EasingStyle.Quint,       Enum.EasingDirection.Out)
local TWEEN_HOVER   = TweenInfo.new(0.25, Enum.EasingStyle.Quint,       Enum.EasingDirection.Out)
local TWEEN_STROKE  = TweenInfo.new(0.25, Enum.EasingStyle.Quint,       Enum.EasingDirection.Out)
local TWEEN_SHADOW  = TweenInfo.new(0.25, Enum.EasingStyle.Quint,       Enum.EasingDirection.Out)

-- Toggle state-change animations — slower + smoother
local TWEEN_TRACK   = TweenInfo.new(0.45, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
local TWEEN_SLIDE   = TweenInfo.new(0.50, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
local TWEEN_STRETCH = TweenInfo.new(0.15, Enum.EasingStyle.Quint,       Enum.EasingDirection.Out)
local TWEEN_SETTLE  = TweenInfo.new(0.35, Enum.EasingStyle.Back,        Enum.EasingDirection.Out)

-- Shadow states
local SHADOW_REST  = { BackgroundTransparency = 0.75, Position = UDim2.new(0.5, 0, 0.5, 3) }
local SHADOW_HOVER = { BackgroundTransparency = 0.65, Position = UDim2.new(0.5, 0, 0.5, 5) }
local SHADOW_PRESS = { BackgroundTransparency = 0.92, Position = UDim2.new(0.5, 0, 0.5, 1) }

-- Track / thumb geometry
local TRACK_W      = 44
local TRACK_H      = 22
local THUMB_W      = 18
local THUMB_H      = 16
local THUMB_SQUISH = 6    -- how much the thumb widens mid-slide
local THUMB_PAD    = 3
local THUMB_OFF    = THUMB_PAD
local THUMB_ON     = TRACK_W - THUMB_W - THUMB_PAD
local THUMB_Y      = (TRACK_H - THUMB_H) / 2

export type ToggleConfig = {
	Label: string,
	Icon: string?,
	Default: boolean?,
	Enabled: boolean?,
	LayoutOrder: number?,
}

type ToggleImpl = {
	Value: boolean,
	Changed: any,
	SetValue:   (self: ToggleImpl, value: boolean) -> (),
	SetEnabled: (self: ToggleImpl, enabled: boolean) -> (),
	GetFrame:   (self: ToggleImpl) -> Frame,
	Destroy:    (self: ToggleImpl) -> (),
	_maid:    any,
	_frame:   Frame,
	_inner:   Frame,
	_content: Frame,
	_label:   TextLabel,
	_icon:    ImageLabel?,
	_track:   Frame,
	_thumb:   Frame,
	_stroke:  UIStroke,
	_scale:   UIScale,
	_flash:   Frame,
	_shadow:  Frame,
	_enabled: boolean,
	_value:   boolean,
}

local Toggle = {} :: { __index: any }
Toggle.__index = Toggle

function Toggle.new(config: ToggleConfig): ToggleImpl
	local self    = setmetatable({}, Toggle) :: ToggleImpl
	self._maid    = Maid.new()
	self._value   = if config.Default ~= nil then config.Default else false
	self._enabled = if config.Enabled ~= nil then config.Enabled else true

	-- ── Outer container ───────────────────────────────────────────────────────
	local frame                  = Instance.new("Frame")
	frame.Name                   = "Toggle"
	frame.Size                   = UDim2.new(1, 0, 0, 36)
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel        = 0
	frame.LayoutOrder            = config.LayoutOrder or 0
	frame.ClipsDescendants       = false
	self._frame                  = frame

	-- ── Shadow ────────────────────────────────────────────────────────────────
	local shadow                  = Instance.new("Frame")
	shadow.Name                   = "Shadow"
	shadow.AnchorPoint            = Vector2.new(0.5, 0.5)
	shadow.Position               = SHADOW_REST.Position
	shadow.Size                   = UDim2.new(1, 0, 1, 4)
	shadow.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
	shadow.BackgroundTransparency = SHADOW_REST.BackgroundTransparency
	shadow.BorderSizePixel        = 0
	shadow.ZIndex                 = 1
	local shadowCorner            = Instance.new("UICorner")
	shadowCorner.CornerRadius     = UDim.new(0, Theme.Radius.Small + 1)
	shadowCorner.Parent           = shadow
	shadow.Parent                 = frame
	self._shadow                  = shadow

	-- ── Inner visible row ─────────────────────────────────────────────────────
	local inner              = Instance.new("Frame")
	inner.Name               = "Inner"
	inner.AnchorPoint        = Vector2.new(0.5, 0.5)
	inner.Position           = UDim2.new(0.5, 0, 0.5, 0)
	inner.Size               = UDim2.new(1, 0, 1, 0)
	inner.BackgroundColor3   = Color3.new(1, 1, 1)
	inner.BorderSizePixel    = 0
	inner.ZIndex             = 2
	inner.Parent             = frame
	self._inner              = inner

	local grad    = Instance.new("UIGradient")
	grad.Color    = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromHex("#2e2e2e")),
		ColorSequenceKeypoint.new(1, Color3.fromHex("#181818")),
	})
	grad.Rotation = 90
	grad.Parent   = inner

	local innerCorner        = Instance.new("UICorner")
	innerCorner.CornerRadius = UDim.new(0, Theme.Radius.Small)
	innerCorner.Parent       = inner

	local stroke           = Instance.new("UIStroke")
	stroke.Color           = Theme.Colors.Border
	stroke.Thickness       = 1
	stroke.Transparency    = 0
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent          = inner
	self._stroke           = stroke

	local uiScale  = Instance.new("UIScale")
	uiScale.Scale  = 1
	uiScale.Parent = inner
	self._scale    = uiScale

	local pad        = Instance.new("UIPadding")
	pad.PaddingLeft  = UDim.new(0, Theme.Spacing.M)
	pad.PaddingRight = UDim.new(0, Theme.Spacing.M)
	pad.Parent       = inner

	-- Flash overlay
	local flash                  = Instance.new("Frame")
	flash.Name                   = "Flash"
	flash.Size                   = UDim2.new(1, Theme.Spacing.M * 2, 1, 0)
	flash.Position               = UDim2.new(0, -Theme.Spacing.M, 0, 0)
	flash.BackgroundColor3       = Color3.new(1, 1, 1)
	flash.BackgroundTransparency = 1
	flash.BorderSizePixel        = 0
	flash.ZIndex                 = 3
	local flashCorner            = Instance.new("UICorner")
	flashCorner.CornerRadius     = UDim.new(0, Theme.Radius.Small)
	flashCorner.Parent           = flash
	flash.Parent                 = inner
	self._flash                  = flash

	-- Track
	local track              = Instance.new("Frame")
	track.Name               = "Track"
	track.Size               = UDim2.fromOffset(TRACK_W, TRACK_H)
	track.Position           = UDim2.new(1, -TRACK_W, 0.5, -(TRACK_H / 2))
	track.BackgroundColor3   = if self._value then Theme.Colors.Accent else Theme.Colors.Border
	track.BorderSizePixel    = 0
	track.ZIndex             = 4
	track.Parent             = inner
	local trackCorner        = Instance.new("UICorner")
	trackCorner.CornerRadius = UDim.new(0, Theme.Radius.Pill)
	trackCorner.Parent       = track
	self._track              = track

	-- Thumb
	local thumb              = Instance.new("Frame")
	thumb.Name               = "Thumb"
	thumb.Size               = UDim2.fromOffset(THUMB_W, THUMB_H)
	thumb.Position           = UDim2.fromOffset(
		if self._value then THUMB_ON else THUMB_OFF,
		THUMB_Y
	)
	thumb.BackgroundColor3   = Color3.fromRGB(255, 255, 255)
	thumb.BorderSizePixel    = 0
	thumb.ZIndex             = 5
	thumb.Parent             = track
	local thumbCorner        = Instance.new("UICorner")
	thumbCorner.CornerRadius = UDim.new(0, Theme.Radius.Pill)
	thumbCorner.Parent       = thumb
	self._thumb              = thumb

	-- Hit target
	local btn                  = Instance.new("TextButton")
	btn.Name                   = "Hit"
	btn.Size                   = UDim2.fromScale(1, 1)
	btn.BackgroundTransparency = 1
	btn.Text                   = ""
	btn.AutoButtonColor        = false
	btn.ZIndex                 = 6
	btn.Parent                 = inner

	-- ── Content (icon + label) ────────────────────────────────────────────────
	local content                  = Instance.new("Frame")
	content.Name                   = "Content"
	content.Position               = UDim2.fromOffset(0, 0)
	content.Size                   = UDim2.new(1, -(TRACK_W + Theme.Spacing.M), 1, 0)
	content.BackgroundTransparency = 1
	content.BorderSizePixel        = 0
	content.ClipsDescendants       = true
	content.ZIndex                 = 4
	content.Parent                 = inner
	self._content                  = content

	local layout               = Instance.new("UIListLayout")
	layout.FillDirection       = Enum.FillDirection.Horizontal
	layout.VerticalAlignment   = Enum.VerticalAlignment.Center
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	layout.Padding             = UDim.new(0, 6)
	layout.SortOrder           = Enum.SortOrder.LayoutOrder
	layout.Parent              = content

	if config.Icon then
		local icon                  = Instance.new("ImageLabel")
		icon.Name                   = "Icon"
		icon.Image                  = config.Icon
		icon.Size                   = UDim2.fromOffset(16, 16)
		icon.BackgroundTransparency = 1
		icon.BorderSizePixel        = 0
		icon.ImageColor3            = if self._enabled
			then Theme.Colors.TextPrimary
			else Theme.Colors.TextDisabled
		icon.LayoutOrder            = 0
		icon.ZIndex                 = 4
		icon.Parent                 = content
		self._icon                  = icon
	end

	local label                  = Instance.new("TextLabel")
	label.Name                   = "Label"
	label.AutomaticSize          = Enum.AutomaticSize.X
	label.Size                   = UDim2.fromOffset(0, Theme.TextSize.Body)
	label.BackgroundTransparency = 1
	label.Font                   = Theme.Font.Body
	label.Text                   = config.Label
	label.TextSize               = Theme.TextSize.Body
	label.TextColor3             = if self._enabled
		then Theme.Colors.TextPrimary
		else Theme.Colors.TextDisabled
	label.TextXAlignment         = Enum.TextXAlignment.Left
	label.TextTruncate           = Enum.TextTruncate.AtEnd
	label.LayoutOrder            = 1
	label.ZIndex                 = 4
	label.Parent                 = content
	self._label                  = label

	local flex    = Instance.new("UIFlexItem")
	flex.FlexMode = Enum.UIFlexMode.Shrink
	flex.Parent   = label

	-- ── Signal ────────────────────────────────────────────────────────────────
	local changed = Signal.new()
	self.Changed  = changed
	self.Value    = self._value
	self._maid:GiveTask(changed)

	local pressing = false
	local hovering = false

	local function releasePress()
		if not pressing then return end
		pressing = false
		local shadowTarget = if hovering then SHADOW_HOVER else SHADOW_REST
		local flashTarget  = if hovering then 0.94 else 1
		TweenService:Create(inner,   TWEEN_RELEASE, { Size = UDim2.new(1, 0, 1, 0) }):Play()
		TweenService:Create(flash,   TWEEN_RELEASE, { BackgroundTransparency = flashTarget }):Play()
		TweenService:Create(shadow,  TWEEN_SHADOW,  {
			BackgroundTransparency = shadowTarget.BackgroundTransparency,
			Position               = shadowTarget.Position,
			Size                   = UDim2.new(1, 0, 1, 4),
		}):Play()
		TweenService:Create(stroke, TWEEN_STROKE, {
			Color = if hovering then Theme.Colors.Accent else Theme.Colors.Border,
		}):Play()
	end

	self._maid:GiveTask(btn.MouseEnter:Connect(function()
		if not self._enabled then return end
		hovering = true
		if not pressing then
			TweenService:Create(stroke, TWEEN_STROKE, { Color = Theme.Colors.Accent }):Play()
			TweenService:Create(flash,  TWEEN_HOVER,  { BackgroundTransparency = 0.94 }):Play()
			TweenService:Create(shadow, TWEEN_SHADOW,  SHADOW_HOVER):Play()
			TweenService:Create(label,  TWEEN_HOVER,  { TextColor3 = Theme.Colors.TextPrimary }):Play()
			if self._icon then
				TweenService:Create(self._icon, TWEEN_HOVER, { ImageColor3 = Theme.Colors.TextPrimary }):Play()
			end
		end
	end))

	self._maid:GiveTask(btn.MouseLeave:Connect(function()
		if not self._enabled then return end
		hovering = false
		if pressing then
			releasePress()
		else
			TweenService:Create(stroke, TWEEN_STROKE, { Color = Theme.Colors.Border }):Play()
			TweenService:Create(flash,  TWEEN_HOVER,  { BackgroundTransparency = 1 }):Play()
			TweenService:Create(shadow, TWEEN_SHADOW,  SHADOW_REST):Play()
		end
	end))

	self._maid:GiveTask(btn.MouseButton1Down:Connect(function()
		if not self._enabled then return end
		pressing = true
		TweenService:Create(inner,  TWEEN_PRESS, { Size = UDim2.new(1, -6, 1, -2) }):Play()
		TweenService:Create(flash,  TWEEN_PRESS, { BackgroundTransparency = 0.82 }):Play()
		TweenService:Create(shadow, TWEEN_PRESS, {
			BackgroundTransparency = SHADOW_PRESS.BackgroundTransparency,
			Position               = SHADOW_PRESS.Position,
			Size                   = UDim2.new(1, -6, 1, 2),
		}):Play()
		TweenService:Create(stroke, TWEEN_PRESS, { Color = Theme.Colors.AccentHover }):Play()
	end))

	self._maid:GiveTask(btn.MouseButton1Up:Connect(function()
		if not self._enabled then return end
		releasePress()
	end))

	self._maid:GiveTask(UserInputService.InputEnded:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			releasePress()
		end
	end))

	self._maid:GiveTask(btn.MouseButton1Click:Connect(function()
		if not self._enabled then return end
		self:SetValue(not self._value)
		changed:Fire(self._value)
	end))

	return self
end

function Toggle:SetValue(value: boolean)
	self._value = value
	self.Value  = value

	-- Token prevents a queued settle from landing after a rapid double-toggle
	self._morphToken = (self._morphToken or 0) + 1
	local currentToken = self._morphToken

	-- Track color glides smoothly
	TweenService:Create(self._track, TWEEN_TRACK, {
		BackgroundColor3 = if value then Theme.Colors.Accent else Theme.Colors.Border,
	}):Play()

	-- Thumb slides with exponential decel (iOS-like)
	TweenService:Create(self._thumb, TWEEN_SLIDE, {
		Position = UDim2.fromOffset(if value then THUMB_ON else THUMB_OFF, THUMB_Y),
	}):Play()

	-- Squish: thumb widens quickly at the start of travel…
	TweenService:Create(self._thumb, TWEEN_STRETCH, {
		Size = UDim2.fromOffset(THUMB_W + THUMB_SQUISH, THUMB_H),
	}):Play()

	-- …then snaps back with a slight elastic overshoot (Back easing)
	task.delay(TWEEN_STRETCH.Time, function()
		if self._morphToken ~= currentToken then return end
		if not self._thumb or not self._thumb.Parent then return end
		TweenService:Create(self._thumb, TWEEN_SETTLE, {
			Size = UDim2.fromOffset(THUMB_W, THUMB_H),
		}):Play()
	end)
end

function Toggle:SetEnabled(enabled: boolean)
	self._enabled          = enabled
	local color            = if enabled then Theme.Colors.TextPrimary else Theme.Colors.TextDisabled
	self._label.TextColor3 = color
	if self._icon then
		self._icon.ImageColor3 = color
	end
	self._stroke.Transparency = if enabled then 0 else 0.5
end

function Toggle:GetFrame(): Frame
	return self._frame
end

function Toggle:Destroy()
	self._maid:DoCleaning()
	if self._frame and self._frame.Parent then
		self._frame:Destroy()
	end
end

return Toggle
