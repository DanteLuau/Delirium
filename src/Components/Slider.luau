--!strict

local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Maid        = require(script.Parent.Parent.Utils.Maid)
local Signal      = require(script.Parent.Parent.Utils.Signal)
local Theme       = require(script.Parent.Parent.Theme)
local SaveManager = require(script.Parent.Parent.Core.SaveManager)
local Tooltip     = require(script.Parent.Parent.Utils.Tooltip)

-- ── Tween presets ──────────────────────────────────────────────────────────────
local TWEEN_FILL        = TweenInfo.new(0.18, Enum.EasingStyle.Quint,        Enum.EasingDirection.Out)
local TWEEN_STROKE      = TweenInfo.new(0.20, Enum.EasingStyle.Quint,        Enum.EasingDirection.Out)
local TWEEN_HOVER       = TweenInfo.new(0.20, Enum.EasingStyle.Quint,        Enum.EasingDirection.Out)
local TWEEN_SHADOW      = TweenInfo.new(0.20, Enum.EasingStyle.Quint,        Enum.EasingDirection.Out)

-- Knob scale animation
local TWEEN_KNOB_HOVER  = TweenInfo.new(0.25, Enum.EasingStyle.Back,         Enum.EasingDirection.Out)
local TWEEN_KNOB_PRESS  = TweenInfo.new(0.12, Enum.EasingStyle.Quad,         Enum.EasingDirection.Out)
local TWEEN_KNOB_REL    = TweenInfo.new(0.40, Enum.EasingStyle.Back,         Enum.EasingDirection.Out)
-- Knob slide (SetValue programmatic call)
local TWEEN_KNOB_SLIDE  = TweenInfo.new(0.22, Enum.EasingStyle.Quint,        Enum.EasingDirection.Out)

-- ── Shadow states ──────────────────────────────────────────────────────────────
local SHADOW_REST  = { BackgroundTransparency = 0.75, Position = UDim2.new(0.5, 0, 0.5, 3) }
local SHADOW_HOVER = { BackgroundTransparency = 0.65, Position = UDim2.new(0.5, 0, 0.5, 5) }

-- ── Track / knob geometry ───────────────────────────────────────────────────────
local TRACK_H  = 15     -- slim pill track height
local KNOB_W   = 30     -- knob width  (flat pill, wider than tall)
local KNOB_H   = 18     -- knob height

local VAL_W = 34
local GAP   = 8

-- ── Knob scale states ─────────────────────────────────────────────────────────
local KNOB_SCALE_REST  = 1.00
local KNOB_SCALE_HOVER = 1.10
local KNOB_SCALE_PRESS = 0.92

-- Track fills the full container width (UDim2.new(1,0,...)).
-- Clip frame and knob positions are scale-based [0..1] → auto-adapt to any width.


export type SliderConfig = {
	Label:       string,
	Min:         number?,
	Max:         number?,
	Default:     number?,
	Step:        number?,
	Enabled:     boolean?,
	LayoutOrder: number?,
	Flag:        string?,
	Tooltip:     string?,
}

type SliderImpl = {
	Value:      number,
	Changed:    any,
	SetValue:   (self: SliderImpl, value: number) -> (),
	SetEnabled: (self: SliderImpl, enabled: boolean) -> (),
	GetFrame:   (self: SliderImpl) -> Frame,
	Destroy:    (self: SliderImpl) -> (),
	_maid:      any,
	_frame:     Frame,
	_inner:     Frame,
	_label:     TextLabel,
	_valLabel:  TextLabel,
	_track:     Frame,
	_clipFrame: Frame,
	_fill:      Frame,
	_knob:      Frame,
	_knobScale: UIScale,
	_stroke:    UIStroke,
	_flash:     Frame,
	_shadow:    Frame,
	_enabled:   boolean,
	_value:     number,
	_min:       number,
	_max:       number,
	_step:      number,
}

local Slider = {} :: { __index: any }
Slider.__index = Slider

-- ── Helpers ───────────────────────────────────────────────────────────────────

local function snap(value: number, step: number): number
	if step <= 0 then return value end
	return math.round(value / step) * step
end

local function fmt(value: number, step: number): string
	if step <= 0 or step >= 1 then
		return tostring(math.round(value))
	elseif step >= 0.1 then
		return string.format("%.1f", value)
	else
		return string.format("%.2f", value)
	end
end

-- Returns the normalized t from a mouse X position relative to track
local function tFromMouseX(track: Frame, mouseX: number): number
	local relX = mouseX - track.AbsolutePosition.X
	local tw   = track.AbsoluteSize.X
	return math.clamp(relX / math.max(tw, 1), 0, 1)
end


-- ── Constructor ───────────────────────────────────────────────────────────────

function Slider.new(config: SliderConfig): SliderImpl
	local self    = setmetatable({}, Slider) :: SliderImpl
	self._maid    = Maid.new()
	self._min     = config.Min  or 0
	self._max     = config.Max  or 100
	self._step    = config.Step or 1
	self._enabled = if config.Enabled ~= nil then config.Enabled else true

	local rawDef = if config.Default ~= nil then config.Default else self._min
	self._value  = math.clamp(snap(rawDef, self._step), self._min, self._max)
	self.Value   = self._value

	local t0 = (self._value - self._min) / math.max(self._max - self._min, 1e-9)

	-- ── Outer container ───────────────────────────────────────────────────────
	-- Two-row layout: top row = label + value readout, bottom row = track
	-- This makes the label always readable at any container width.
	local FRAME_H   = 52   -- total row height (was 36)
	local HEADER_H  = 18   -- top row: label + value
	local TRACK_ROW = 14   -- vertical center offset for track within the bottom half

	local frame                  = Instance.new("Frame")
	frame.Name                   = "Slider"
	frame.Size                   = UDim2.new(1, 0, 0, FRAME_H)
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

	-- ── Inner row ─────────────────────────────────────────────────────────────
	local inner            = Instance.new("Frame")
	inner.Name             = "Inner"
	inner.AnchorPoint      = Vector2.new(0.5, 0.5)
	inner.Position         = UDim2.new(0.5, 0, 0.5, 0)
	inner.Size             = UDim2.new(1, 0, 1, 0)
	inner.BackgroundColor3 = Color3.new(1, 1, 1)
	inner.BorderSizePixel  = 0
	inner.ZIndex           = 2
	inner.ClipsDescendants = true
	inner.Parent           = frame
	self._inner            = inner

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
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent          = inner
	self._stroke           = stroke

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

	-- ── Label (top-left of inner) ─────────────────────────────────────────────
	-- Gets its own full-width row so it never competes with the track for space.
	local label                  = Instance.new("TextLabel")
	label.Name                   = "Label"
	label.Position               = UDim2.fromOffset(0, 0)
	label.Size                   = UDim2.new(1, -(VAL_W + GAP), 0, HEADER_H)
	label.BackgroundTransparency = 1
	label.Font                   = Theme.Font.Body
	label.Text                   = config.Label
	label.TextSize               = Theme.TextSize.Body
	label.TextColor3             = if self._enabled
		then Theme.Colors.TextPrimary
		else Theme.Colors.TextDisabled
	label.TextXAlignment         = Enum.TextXAlignment.Left
	label.TextYAlignment         = Enum.TextYAlignment.Center
	label.TextTruncate           = Enum.TextTruncate.AtEnd
	label.ZIndex                 = 4
	label.Parent                 = inner
	self._label                  = label

	-- ── Value readout (top-right of inner) ───────────────────────────────────
	local valLabel                  = Instance.new("TextLabel")
	valLabel.Name                   = "ValueLabel"
	valLabel.AnchorPoint            = Vector2.new(1, 0)
	valLabel.Position               = UDim2.new(1, 0, 0, 0)
	valLabel.Size                   = UDim2.fromOffset(VAL_W, HEADER_H)
	valLabel.BackgroundTransparency = 1
	valLabel.Font                   = Theme.Font.Body
	valLabel.Text                   = fmt(self._value, self._step)
	valLabel.TextSize               = Theme.TextSize.Body
	valLabel.TextColor3             = Theme.Colors.TextSecondary
	valLabel.TextXAlignment         = Enum.TextXAlignment.Right
	valLabel.TextYAlignment         = Enum.TextYAlignment.Center
	valLabel.ZIndex                 = 4
	valLabel.Parent                 = inner
	self._valLabel                  = valLabel

	-- ── Track (iOS pill) — sits in the bottom half of the inner frame ─────────
	-- Vertical center of track: HEADER_H + TRACK_ROW pixels from top of inner.
	local TRACK_Y    = HEADER_H + TRACK_ROW - TRACK_H / 2
	local track              = Instance.new("Frame")
	track.Name               = "Track"
	track.Size               = UDim2.new(1, 0, 0, TRACK_H)
	track.Position           = UDim2.fromOffset(0, TRACK_Y)
	track.BackgroundColor3   = Theme.Colors.Border
	track.BorderSizePixel    = 0
	track.ZIndex             = 4
	track.ClipsDescendants   = false
	local trackCorner        = Instance.new("UICorner")
	trackCorner.CornerRadius = UDim.new(0, Theme.Radius.Pill)
	trackCorner.Parent       = track
	track.Parent             = inner
	self._track              = track

	-- Recompute knobX bounds to use dynamic track width via AbsoluteSize.
	-- During construction AbsoluteSize is 0, so we keep the static constants
	-- for layout; the drag handler calls tFromMouseX which uses AbsoluteSize
	-- live.  FillClip also uses the track's full pixel width at runtime.
	local function dynKnobX(t: number): number
		local tw = track.AbsoluteSize.X
		if tw <= 0 then tw = 200 end -- safe fallback before first render
		local kmin = KNOB_W / 2
		local kmax = tw - KNOB_W / 2
		return kmin + t * (kmax - kmin)
	end

	-- FillClip: controls the visible right boundary of the fill.
	local clipFrame                  = Instance.new("Frame")
	clipFrame.Name                   = "FillClip"
	clipFrame.Size                   = UDim2.new(t0, 0, 1, 0)   -- scale-based → auto-adapts
	clipFrame.Position               = UDim2.fromOffset(0, 0)
	clipFrame.BackgroundTransparency = 1
	clipFrame.ClipsDescendants       = true
	clipFrame.BorderSizePixel        = 0
	clipFrame.ZIndex                 = 5
	clipFrame.Parent                 = track
	self._clipFrame                  = clipFrame

	-- Fill: static width so right pill corner is beyond clip → clean flat cut.
	local fill            = Instance.new("Frame")
	fill.Name             = "Fill"
	fill.Size             = UDim2.new(2, 0, 1, 0)   -- 2× track width, scale-based
	fill.BackgroundColor3 = Theme.Colors.Accent
	fill.BorderSizePixel  = 0
	fill.ZIndex           = 5
	local fillCorner      = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, Theme.Radius.Pill)
	fillCorner.Parent     = fill
	fill.Parent           = clipFrame
	self._fill            = fill

	-- ── Knob — centered vertically in the track ───────────────────────────────
	local knob            = Instance.new("Frame")
	knob.Name             = "Knob"
	knob.AnchorPoint      = Vector2.new(0.5, 0.5)
	knob.Size             = UDim2.fromOffset(KNOB_W, KNOB_H)
	-- Position X set via scale on clip; just center Y here. X repositioned via dynKnobX after render.
	knob.Position         = UDim2.new(t0, 0, 0.5, 0)
	knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	knob.BorderSizePixel  = 0
	knob.ZIndex           = 6
	knob.ClipsDescendants = false

	local knobCorner        = Instance.new("UICorner")
	knobCorner.CornerRadius = UDim.new(0, Theme.Radius.Pill)
	knobCorner.Parent       = knob

	-- Subtle drop shadow on knob
	local knobShadow                  = Instance.new("Frame")
	knobShadow.Name                   = "KnobShadow"
	knobShadow.AnchorPoint            = Vector2.new(0.5, 0.5)
	knobShadow.Position               = UDim2.new(0.5, 0, 0.5, 1)
	knobShadow.Size                   = UDim2.new(1, 4, 1, 4)
	knobShadow.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
	knobShadow.BackgroundTransparency = 0.7
	knobShadow.BorderSizePixel        = 0
	knobShadow.ZIndex                 = 5
	local knobShadowCorner            = Instance.new("UICorner")
	knobShadowCorner.CornerRadius     = UDim.new(0, Theme.Radius.Pill)
	knobShadowCorner.Parent           = knobShadow
	knobShadow.Parent                 = knob

	-- UIScale for hover/press animation (scales around AnchorPoint 0.5,0.5)
	local knobScale  = Instance.new("UIScale")
	knobScale.Scale  = KNOB_SCALE_REST
	knobScale.Parent = knob
	self._knobScale  = knobScale

	knob.Parent = track
	self._knob  = knob

	-- ── Hit target ────────────────────────────────────────────────────────────
	local hit                  = Instance.new("TextButton")
	hit.Name                   = "Hit"
	hit.Size                   = UDim2.fromScale(1, 1)
	hit.BackgroundTransparency = 1
	hit.Text                   = ""
	hit.AutoButtonColor        = false
	hit.ZIndex                 = 7
	hit.Parent                 = inner

	-- ── Signal ────────────────────────────────────────────────────────────────
	local changed = Signal.new()
	self.Changed  = changed
	self._maid:GiveTask(changed)

	-- ── State ─────────────────────────────────────────────────────────────────
	local dragging = false
	local hovering = false

	-- ── Apply a normalized t during drag (direct, no tween = responsive) ──────
	local function applyT(t: number)
		local raw   = self._min + t * (self._max - self._min)
		local value = math.clamp(snap(raw, self._step), self._min, self._max)
		if value == self._value then return end

		local st = (value - self._min) / math.max(self._max - self._min, 1e-9)

		self._value    = value
		self.Value     = value
		valLabel.Text  = fmt(value, self._step)

		-- ClipFrame: scale-based → always matches track width automatically
		TweenService:Create(clipFrame, TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.new(st, 0, 1, 0),
		}):Play()

		-- Knob: direct set — zero lag while dragging (scale-based X)
		knob.Position = UDim2.new(st, 0, 0.5, 0)

		changed:Fire(value)
	end

	-- ── Row hover (stroke / flash / shadow) — full inner area ──────────────────
	self._maid:GiveTask(hit.MouseEnter:Connect(function()
		if not self._enabled then return end
		hovering = true
		TweenService:Create(stroke, TWEEN_STROKE, { Color = Theme.Colors.Accent }):Play()
		TweenService:Create(flash,  TWEEN_HOVER,  { BackgroundTransparency = 0.92 }):Play()
		TweenService:Create(shadow, TWEEN_SHADOW, SHADOW_HOVER):Play()
	end))

	self._maid:GiveTask(hit.MouseLeave:Connect(function()
		if not self._enabled then return end
		hovering = false
		if not dragging then
			TweenService:Create(stroke, TWEEN_STROKE, { Color = Theme.Colors.Border }):Play()
			TweenService:Create(flash,  TWEEN_HOVER,  { BackgroundTransparency = 1 }):Play()
			TweenService:Create(shadow, TWEEN_SHADOW, SHADOW_REST):Play()
		end
	end))

	-- ── Knob hover (scale only) ───────────────────────────────────────────────
	self._maid:GiveTask(knob.MouseEnter:Connect(function()
		if not self._enabled or dragging then return end
		TweenService:Create(knobScale, TWEEN_KNOB_HOVER, { Scale = KNOB_SCALE_HOVER }):Play()
	end))

	self._maid:GiveTask(knob.MouseLeave:Connect(function()
		if not self._enabled or dragging then return end
		TweenService:Create(knobScale, TWEEN_KNOB_REL, { Scale = KNOB_SCALE_REST }):Play()
	end))

	-- ── Press (scale down) ────────────────────────────────────────────────────
	self._maid:GiveTask(hit.InputBegan:Connect(function(input: InputObject)
		if not self._enabled then return end
		if input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch then return end

		local touchX    = input.Position.X
		local trackLeft = track.AbsolutePosition.X
		local trackRight = trackLeft + track.AbsoluteSize.X
		if touchX < (trackLeft - 24) or touchX > (trackRight + KNOB_W / 2 + 24) then return end
		dragging = true
		TweenService:Create(knobScale, TWEEN_KNOB_PRESS, { Scale = KNOB_SCALE_PRESS }):Play()
		applyT(tFromMouseX(track, touchX))
	end))

	-- ── Drag move ─────────────────────────────────────────────────────────────
	self._maid:GiveTask(UserInputService.InputChanged:Connect(function(input: InputObject)
		if not dragging then return end
		if input.UserInputType ~= Enum.UserInputType.MouseMovement
			and input.UserInputType ~= Enum.UserInputType.Touch then return end
		applyT(tFromMouseX(track, input.Position.X))
	end))

	-- ── Release (scale restore with spring) ───────────────────────────────────
	local function onRelease()
		if not dragging then return end
		dragging = false
		TweenService:Create(knobScale, TWEEN_KNOB_REL, { Scale = KNOB_SCALE_REST }):Play()
		if not hovering then
			TweenService:Create(stroke, TWEEN_STROKE, { Color = Theme.Colors.Border }):Play()
			TweenService:Create(flash,  TWEEN_HOVER,  { BackgroundTransparency = 1 }):Play()
			TweenService:Create(shadow, TWEEN_SHADOW, SHADOW_REST):Play()
		end
	end

	self._maid:GiveTask(UserInputService.InputEnded:Connect(function(input: InputObject)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch then return end
		onRelease()
	end))

	self._maid:GiveTask(hit.MouseButton1Up:Connect(function()
		onRelease()
	end))

	-- ── SaveManager wiring ────────────────────────────────────────────────
	local flag = config.Flag
		or SaveManager.deriveFlagFromName(config.Label)
	if flag ~= "" then
		SaveManager.Register(
			flag,
			function() return self._value end,
			function(v: any)
				if type(v) == "number" then
					self:SetValue(v)
				end
			end
		)
		self._maid:GiveTask(changed:Connect(function()
			SaveManager._scheduleAutoSave()
		end))
	end

	if config.Tooltip and #config.Tooltip > 0 then
		self._maid:GiveTask(Tooltip.bind(inner, config.Tooltip))
	end

	return self
end

-- ── SetValue (programmatic — smooth tween) ────────────────────────────────────

function Slider:SetValue(value: number)
	local clamped = math.clamp(snap(value, self._step), self._min, self._max)
	local t       = (clamped - self._min) / math.max(self._max - self._min, 1e-9)

	self._value         = clamped
	self.Value          = clamped
	self._valLabel.Text = fmt(clamped, self._step)

	-- Scale-based: auto-adapts to container width
	TweenService:Create(self._clipFrame, TWEEN_FILL, {
		Size = UDim2.new(t, 0, 1, 0),
	}):Play()
	TweenService:Create(self._knob, TWEEN_KNOB_SLIDE, {
		Position = UDim2.new(t, 0, 0.5, 0),
	}):Play()
end

-- ── SetEnabled ────────────────────────────────────────────────────────────────

function Slider:SetEnabled(enabled: boolean)
	self._enabled             = enabled
	self._label.TextColor3    = if enabled
		then Theme.Colors.TextPrimary
		else Theme.Colors.TextDisabled
	self._stroke.Transparency = if enabled then 0 else 0.5
end

function Slider:GetFrame(): Frame
	return self._frame
end

function Slider:Destroy()
	self._maid:DoCleaning()
	if self._frame and self._frame.Parent then
		self._frame:Destroy()
	end
end

return Slider
