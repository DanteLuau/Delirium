--!strict

-- Delirium UI Library
-- slider.luau — Oldsrc slider layout & behavior ported to src, with zero animations.
-- Supports normal (54px) and compact (36px) modes, full/hidden max formats, and flag persistence.

-- B5 FIX: was raw game:GetService — use the cloneref-safe alias from variables.
local constants = require(script.Parent.Parent.utility.constants)
local flags     = require(script.Parent.Parent.utility.flags)
local runtime   = require(script.Parent.Parent.utility.runtime)
local signal    = require(script.Parent.Parent.utility.signal)
local themeUtil   = require(script.Parent.Parent.utility.theme)
local variables   = require(script.Parent.Parent.utility.variables)

local TRACK_H = 15
local KNOB_W  = 30
local KNOB_H  = 18
local VAL_W   = 54
local GAP     = 8

-- B3 FIX: one allocation per module, reused in every theme-listener invocation.
local DEFAULT_FONT = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium)

export type SliderProps = {
	name:               string?,
	Label:              string?,
	Text:               string?,
	description:        string?,
	Tooltip:            string?,
	flag:               string?,
	Flag:               string?,
	range:              { number }?,
	min:                number?,
	Min:                number?,
	max:                number?,
	Max:                number?,
	increment:          number?,
	step:               number?,
	Step:               number?,
	value:              number?,
	default:            number?,
	Default:            number?,
	suffix:             string?,
	Suffix:             string?,
	compact:            boolean?,
	Compact:            boolean?,
	hideMax:            boolean?,
	HideMax:            boolean?,
	formatDisplayValue: ((slider: any, value: number) -> string?)?,
	FormatDisplayValue: ((slider: any, value: number) -> string?)?,
	enabled:            boolean?,
	Enabled:            boolean?,
	layoutOrder:        number?,
	LayoutOrder:        number?,
	callback:           ((value: number) -> ())?,
	Callback:           ((value: number) -> ())?,
}

export type Slider = {
	value:      number,
	Value:      number,
	Changed:    any,
	_frame:     Frame,
	Set:        (self: Slider, value: number, skipCallback: boolean?) -> (),
	SetValue:   (self: Slider, value: number, skipCallback: boolean?) -> (),
	SetEnabled: (self: Slider, enabled: boolean) -> (),
	GetFrame:   (self: Slider) -> Frame,
	Destroy:    (self: Slider) -> (),
}

local Slider = {}
Slider.__index = Slider

-- ── Helpers ───────────────────────────────────────────────────────────────────

local function snap(value: number, step: number, min: number): number
	if step <= 0 then return value end
	return min + math.round((value - min) / step) * step
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

-- tFromMouseX: all args are in screen (viewport) pixels.
-- mouseX        = UserInputService:GetMouseLocation().X
-- track         = the Track Frame
-- knobW         = knob.AbsoluteSize.X (screen px, post-UIScale)
local function tFromMouseX(track: Frame, mouseX: number, knobW: number): number
	local kHalf  = knobW / 2
	local usable = math.max(track.AbsoluteSize.X - knobW, 1)
	local relX   = mouseX - (track.AbsolutePosition.X + kHalf)
	return math.clamp(relX / usable, 0, 1)
end

-- ── Constructor ───────────────────────────────────────────────────────────────

function Slider.new(props: SliderProps, theme: { [string]: any }, parent: Instance): Slider
	local name = props.name or props.Label or props.Text or "Slider"
	local flagKey: string? = props.flag or props.Flag

	local rangeMin = (props.range and props.range[1]) or props.min or props.Min or 0
	local rangeMax = (props.range and props.range[2]) or props.max or props.Max or 100
	local stepVal = props.increment or props.step or props.Step or 1
	local suffix = props.suffix or props.Suffix or ""
	local callback = props.callback or props.Callback
	local isCompact = (props.compact == true) or (props.Compact == true)
	local hideMaxVal = if props.hideMax ~= nil then props.hideMax
		elseif props.HideMax ~= nil then props.HideMax
		else true
	local isEnabled = if props.enabled ~= nil then props.enabled
		elseif props.Enabled ~= nil then props.Enabled
		else true
	local cfgFormat = props.formatDisplayValue or props.FormatDisplayValue

	-- Resolve initial value
	local initValue: number
	if flagKey and flags:Get(flagKey) ~= nil then
		initValue = flags:Get(flagKey) :: number
	else
		initValue = props.value or props.default or props.Default or rangeMin
	end
	initValue = math.clamp(snap(initValue, stepVal, rangeMin), rangeMin, rangeMax)

	local FRAME_H: number
	local HEADER_H: number
	if isCompact then
		FRAME_H = 36
		HEADER_H = 0
	else
		FRAME_H = 54
		HEADER_H = 20
	end

	-- ── Outer Frame ───────────────────────────────────────────────────────────
	local frame = Instance.new("Frame")
	frame.Name = "Slider_" .. name
	frame.Size = UDim2.new(1, 0, 0, FRAME_H)
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel = 0
	frame.LayoutOrder = props.layoutOrder or props.LayoutOrder or 0
	frame.ClipsDescendants = false
	frame.Parent = parent

	-- ── Shadow ────────────────────────────────────────────────────────────────
	local shadow = Instance.new("Frame")
	shadow.Name = "Shadow"
	shadow.AnchorPoint = Vector2.new(0.5, 0.5)
	shadow.Position = UDim2.new(0.5, 0, 0.5, 3)
	shadow.Size = UDim2.new(1, 0, 1, 4)
	shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	shadow.BackgroundTransparency = 0.75
	shadow.BorderSizePixel = 0
	shadow.ZIndex = 1

	local shadowCorner = Instance.new("UICorner")
	shadowCorner.CornerRadius = UDim.new(0, 7)
	shadowCorner.Parent = shadow
	shadow.Parent = frame

	-- ── Inner Shell ───────────────────────────────────────────────────────────
	local inner = Instance.new("Frame")
	inner.Name = "Inner"
	inner.AnchorPoint = Vector2.new(0.5, 0.5)
	inner.Position = UDim2.new(0.5, 0, 0.5, 0)
	inner.Size = UDim2.new(1, 0, 1, 0)
	inner.BackgroundColor3 = Color3.new(1, 1, 1)
	inner.BorderSizePixel = 0
	inner.ZIndex = 2
	inner.ClipsDescendants = true
	inner.Parent = frame

	local innerGrad = Instance.new("UIGradient")
	innerGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromHex("#2e2e2e")),
		ColorSequenceKeypoint.new(1, Color3.fromHex("#181818")),
	})
	innerGrad.Rotation = 90
	innerGrad.Parent = inner

	local innerCorner = Instance.new("UICorner")
	innerCorner.CornerRadius = UDim.new(0, 6)
	innerCorner.Parent = inner

	local stroke = Instance.new("UIStroke")
	stroke.Color = theme.ElementStroke or Color3.fromHex("#2b2b2b")
	stroke.Thickness = 1
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = inner

	local innerPad = Instance.new("UIPadding")
	innerPad.PaddingLeft = UDim.new(0, 12)
	innerPad.PaddingRight = UDim.new(0, 12)
	innerPad.PaddingTop = UDim.new(0, 4)
	innerPad.Parent = inner

	local flash = Instance.new("Frame")
	flash.Name = "Flash"
	flash.Size = UDim2.new(1, 24, 1, 0)
	flash.Position = UDim2.new(0, -12, 0, 0)
	flash.BackgroundColor3 = Color3.new(1, 1, 1)
	flash.BackgroundTransparency = 1
	flash.BorderSizePixel = 0
	flash.ZIndex = 3

	local flashCorner = Instance.new("UICorner")
	flashCorner.CornerRadius = UDim.new(0, 6)
	flashCorner.Parent = flash
	flash.Parent = inner

	-- ── Labels ────────────────────────────────────────────────────────────────
	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.AnchorPoint = Vector2.new(0, 0.5)
	label.Position = UDim2.new(0, 0, 0, math.floor(HEADER_H / 2))
	label.Size = UDim2.new(1, -(VAL_W + GAP), 0, HEADER_H)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamMedium
	label.FontFace = theme.Font or Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium)
	label.Text = name
	label.TextSize = 13
	label.TextColor3 = if isEnabled then (theme.ContentColor or Color3.fromHex("#ffffff")) else Color3.fromHex("#555555")
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.TextTruncate = Enum.TextTruncate.AtEnd
	label.ZIndex = 4
	label.Visible = not isCompact
	label.Parent = inner

	local valLabel = Instance.new("TextLabel")
	valLabel.Name = "ValueLabel"
	valLabel.BackgroundTransparency = 1
	valLabel.Font = Enum.Font.GothamMedium
	valLabel.FontFace = theme.Font or Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium)
	valLabel.TextSize = 12
	valLabel.TextColor3 = theme.PlaceholderColor or Color3.fromHex("#9d9d9d")
	valLabel.TextXAlignment = Enum.TextXAlignment.Right
	valLabel.TextYAlignment = Enum.TextYAlignment.Center
	valLabel.ZIndex = 4
	valLabel.Parent = inner

	if isCompact then
		valLabel.AnchorPoint = Vector2.new(1, 0.5)
		valLabel.Position = UDim2.new(1, 0, 0.5, 0)
		valLabel.Size = UDim2.fromOffset(VAL_W, FRAME_H)
	else
		valLabel.AnchorPoint = Vector2.new(1, 0.5)
		valLabel.Position = UDim2.new(1, 0, 0, math.floor(HEADER_H / 2))
		valLabel.Size = UDim2.fromOffset(VAL_W, HEADER_H)
		valLabel.AutomaticSize = Enum.AutomaticSize.X
	end

	-- ── Track ─────────────────────────────────────────────────────────────────
	local TRACK_Y: number
	if isCompact then
		TRACK_Y = math.floor((FRAME_H - TRACK_H) / 2)
	else
		TRACK_Y = HEADER_H + math.floor((FRAME_H - HEADER_H - TRACK_H) / 2)
	end

	local trackRightPad = if isCompact then (VAL_W + GAP) else 0

	local track = Instance.new("Frame")
	track.Name = "Track"
	track.Size = UDim2.new(1, -trackRightPad, 0, TRACK_H)
	track.Position = UDim2.fromOffset(0, TRACK_Y)
	track.BackgroundColor3 = theme.SliderBackground or Color3.fromHex("#222222")
	track.BorderSizePixel = 0
	track.ZIndex = 4
	track.ClipsDescendants = false

	local trackCorner = Instance.new("UICorner")
	trackCorner.CornerRadius = UDim.new(0, 100)
	trackCorner.Parent = track
	track.Parent = inner

	-- knobRef is set after the knob Instance is created below.
	-- knobPosScale reads it at call-time so it always has the real AbsoluteSize.
	local knobRef: Frame = nil :: any

	-- Returns the knob-CENTER position as a [0..1] fraction of the Track's width.
	-- Uses AbsoluteSize RATIOS — UIScale cancels out algebraically, so this is
	-- immune to any DPI / UIScale value without needing to infer the scale.
	--
	--   kHalf_frac  = knob_screen_px / (2 * track_screen_px)
	--              = (KNOB_W * scale) / (2 * tw_design * scale)   ← scale cancels
	--              = KNOB_W / (2 * tw_design)
	--
	-- Use this value directly in UDim2.new(posScale, 0, ...) — Scale coords are
	-- fractions of the PARENT's Size (design space), so UIScale is never applied
	-- a second time.
	local function knobPosScale(t: number): number
		local tw = track.AbsoluteSize.X
		local kw = if knobRef ~= nil and knobRef.AbsoluteSize.X > 0
			then knobRef.AbsoluteSize.X
			else nil

		if kw ~= nil and tw > 0 then
			-- Post-layout: AbsoluteSize values are valid.
			local kHalf_frac = kw / (2 * tw)
			return math.clamp(kHalf_frac + t * (1 - 2 * kHalf_frac), 0, 1)
		else
			-- Pre-layout fallback: assume design track ~200px wide, UIScale = 1.
			-- The first trackSize signal will immediately correct this.
			local kHalf_frac = KNOB_W / (2 * 200)
			return math.clamp(kHalf_frac + t * (1 - 2 * kHalf_frac), 0, 1)
		end
	end

	local self = setmetatable({}, Slider) :: Slider
	self.value = initValue
	self.Value = initValue
	self._frame = frame
	self.Changed = signal.new()

	local function fmtDisplay(val: number): string
		if cfgFormat then
			local res = cfgFormat(self, val)
			if res ~= nil then return res end
		end
		if not hideMaxVal then
			return fmt(val, stepVal) .. " / " .. fmt(rangeMax, stepVal) .. suffix
		end
		return fmt(val, stepVal) .. suffix
	end

	local t0 = (initValue - rangeMin) / math.max(rangeMax - rangeMin, 1e-9)

	local clipFrame = Instance.new("Frame")
	clipFrame.Name = "FillClip"
	clipFrame.Size = UDim2.new(knobPosScale(t0), 0, 1, 0)
	clipFrame.Position = UDim2.fromOffset(0, 0)
	clipFrame.BackgroundTransparency = 1
	clipFrame.ClipsDescendants = true
	clipFrame.BorderSizePixel = 0
	clipFrame.ZIndex = 5
	clipFrame.Parent = track

	local clipCorner = Instance.new("UICorner")
	clipCorner.CornerRadius = UDim.new(0, 100)
	clipCorner.Parent = clipFrame

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.new(1, 0, 1, 0)
	fill.BackgroundColor3 = theme.AccentColor or Color3.fromHex("#4cc2ff")
	fill.BorderSizePixel = 0
	fill.ZIndex = 5
	fill.Parent = clipFrame

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 100)
	fillCorner.Parent = fill

	local fillGrad = Instance.new("UIGradient")
	fillGrad.Color = theme.SliderProgress
		or ColorSequence.new(Color3.fromHex("#4cc2ff"), Color3.fromHex("#0093fb"))
	fillGrad.Rotation = 0
	fillGrad.Parent = fill

	local knob = Instance.new("Frame")
	knob.Name = "Knob"
	knob.AnchorPoint = Vector2.new(0.5, 0.5)
	knob.Size = UDim2.fromOffset(KNOB_W, KNOB_H)
	knob.Position = UDim2.new(knobPosScale(t0), 0, 0.5, 0)
	knob.BackgroundColor3 = theme.SliderHandle or Color3.fromRGB(255, 255, 255)
	knob.BorderSizePixel = 0
	knob.ZIndex = 6
	knob.ClipsDescendants = false

	local knobCorner = Instance.new("UICorner")
	knobCorner.CornerRadius = UDim.new(0, 100)
	knobCorner.Parent = knob

	local knobShadow = Instance.new("Frame")
	knobShadow.Name = "KnobShadow"
	knobShadow.AnchorPoint = Vector2.new(0.5, 0.5)
	knobShadow.Position = UDim2.new(0.5, 0, 0.5, 1)
	knobShadow.Size = UDim2.new(1, 4, 1, 4)
	knobShadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	knobShadow.BackgroundTransparency = 0.7
	knobShadow.BorderSizePixel = 0
	knobShadow.ZIndex = 5

	local knobShadowCorner = Instance.new("UICorner")
	knobShadowCorner.CornerRadius = UDim.new(0, 100)
	knobShadowCorner.Parent = knobShadow
	knobShadow.Parent = knob
	knob.Parent = track
	knobRef = knob  -- now knobPosScale and tFromMouseX callers can read AbsoluteSize

	local hit = Instance.new("TextButton")
	hit.Name = "Hit"
	hit.Size = UDim2.fromScale(1, 1)
	hit.BackgroundTransparency = 1
	hit.Text = ""
	hit.AutoButtonColor = false
	hit.ZIndex = 7
	hit.Parent = inner

	valLabel.Text = fmtDisplay(initValue)

	-- ── Private Storage ───────────────────────────────────────────────────────
	local s = self :: any
	s._min = rangeMin
	s._max = rangeMax
	s._step = stepVal
	s._suffix = suffix
	s._flag = flagKey
	s._callback = callback
	s._enabled = isEnabled
	s._theme = theme
	s._knobPosScale = knobPosScale
	s._fmtDisplay = fmtDisplay
	s._track = track
	s._clipFrame = clipFrame
	s._knob = knob
	s._valLabel = valLabel
	s._label = label
	s._stroke = stroke
	s._flash = flash
	s._shadow = shadow
	s._fill = fill
	s._fillGrad = fillGrad
	s._conns = {} :: { [string]: RBXScriptConnection }

	local dragging = false
	local hovering = false
	local pendingTouchStart: Vector2? = nil

	-- B2 FIX: coalesce drag-rate Changed + callback fires to once per frame.
	-- Visuals update instantly inside applyT; the signal/callback fires at most
	-- once per task.defer cycle (~1 frame at 60 Hz) no matter how many InputChanged
	-- events arrive per frame (Roblox can report 120+ mouse events/sec).
	local _pendingFireVal: number? = nil
	local _firePending    = false

	local function scheduleChanged(val: number)
		_pendingFireVal = val
		if _firePending then return end
		_firePending = true
		task.defer(function()
			_firePending = false
			local v = _pendingFireVal
			_pendingFireVal = nil
			if v ~= nil then
				self.Changed:Fire(v)
				if callback then callback(v) end
			end
		end)
	end

	local function applyT(t: number)
		local raw = rangeMin + t * (rangeMax - rangeMin)
		local val = math.clamp(snap(raw, stepVal, rangeMin), rangeMin, rangeMax)
		if val == self.value then return end

		self.value = val
		self.Value = val
		valLabel.Text = fmtDisplay(val)

		local st = (val - rangeMin) / math.max(rangeMax - rangeMin, 1e-9)
		-- Zero animations: instant property updates
		local posScale = knobPosScale(st)
		clipFrame.Size = UDim2.new(posScale, 0, 1, 0)
		knob.Position = UDim2.new(posScale, 0, 0.5, 0)

		if flagKey then
			flags:Set(flagKey, val)
		end
		-- B2: defer the signal + callback instead of spawning per input event.
		scheduleChanged(val)
	end

	-- ── Interactivity (Instant — No Tweens) ───────────────────────────────────
	s._conns.hitEnter = hit.MouseEnter:Connect(function()
		if not s._enabled then return end
		if variables.settingsOpen then return end
		hovering = true
		stroke.Color = s._theme.AccentColor or Color3.fromHex("#4cc2ff")
		flash.BackgroundTransparency = 0.92
		shadow.BackgroundTransparency = 0.65
		shadow.Position = UDim2.new(0.5, 0, 0.5, 5)
	end)

	s._conns.hitLeave = hit.MouseLeave:Connect(function()
		if not s._enabled then return end
		hovering = false
		if not dragging then
			stroke.Color = s._theme.ElementStroke or Color3.fromHex("#2b2b2b")
			flash.BackgroundTransparency = 1
			shadow.BackgroundTransparency = 0.75
			shadow.Position = UDim2.new(0.5, 0, 0.5, 3)
		end
	end)

	s._conns.hitBegan = hit.InputBegan:Connect(function(input: InputObject)
		if not s._enabled then return end

		-- DPI fix: mouse position from GetMouseLocation() is always in GUI-space;
		-- input.Position.X on PC can be raw screen pixels on high-DPI displays.
		local touchX: number
		if input.UserInputType == Enum.UserInputType.Touch then
			touchX = input.Position.X
		else
			touchX = variables.userInputService:GetMouseLocation().X
		end

		local trackLeft = track.AbsolutePosition.X
		local trackRight = trackLeft + track.AbsoluteSize.X
		if touchX < (trackLeft - 24) or touchX > (trackRight + KNOB_W / 2 + 24) then return end

		if input.UserInputType == Enum.UserInputType.Touch then
			pendingTouchStart = Vector2.new(input.Position.X, input.Position.Y)
			return
		end

		if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
		dragging = true
		local kw = knob.AbsoluteSize.X > 0 and knob.AbsoluteSize.X or KNOB_W
		applyT(tFromMouseX(track, touchX, kw))
	end)

	s._conns.inputChanged = variables.userInputService.InputChanged:Connect(function(input: InputObject)
		if pendingTouchStart and input.UserInputType == Enum.UserInputType.Touch then
			local dx = math.abs(input.Position.X - pendingTouchStart.X)
			local dy = math.abs(input.Position.Y - pendingTouchStart.Y)
			if dx > 5 or dy > 5 then
				if dx >= dy then
					dragging = true
				end
				pendingTouchStart = nil
			end
		end

		if not dragging then return end
		if input.UserInputType ~= Enum.UserInputType.MouseMovement
			and input.UserInputType ~= Enum.UserInputType.Touch then return end
		-- DPI fix: use GUI-space coordinates for mouse; Touch is already viewport-scaled.
		local inputX: number
		if input.UserInputType == Enum.UserInputType.Touch then
			inputX = input.Position.X
		else
			inputX = variables.userInputService:GetMouseLocation().X
		end
		local kw = knob.AbsoluteSize.X > 0 and knob.AbsoluteSize.X or KNOB_W
		applyT(tFromMouseX(track, inputX, kw))
	end)

	local function onRelease()
		if not dragging and not pendingTouchStart then return end
		dragging = false
		pendingTouchStart = nil
		if not hovering then
			stroke.Color = s._theme.ElementStroke or Color3.fromHex("#2b2b2b")
			flash.BackgroundTransparency = 1
			shadow.BackgroundTransparency = 0.75
			shadow.Position = UDim2.new(0.5, 0, 0.5, 3)
		end
	end

	s._conns.inputEnded = variables.userInputService.InputEnded:Connect(function(input: InputObject)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch then return end
		if pendingTouchStart and input.UserInputType == Enum.UserInputType.Touch then
			local kw = knob.AbsoluteSize.X > 0 and knob.AbsoluteSize.X or KNOB_W
			applyT(tFromMouseX(track, input.Position.X, kw))
		end
		onRelease()
	end)

	s._conns.hitUp = hit.MouseButton1Up:Connect(function()
		onRelease()
	end)

	local function refreshKnobLayout()
		local st = (self.value - rangeMin) / math.max(rangeMax - rangeMin, 1e-9)
		local posScale = knobPosScale(st)
		clipFrame.Size = UDim2.new(posScale, 0, 1, 0)
		knob.Position = UDim2.new(posScale, 0, 0.5, 0)
	end

	-- Refresh on track resize (window resize, UIScale change, etc.)
	-- task.defer: fires AFTER the full layout pass so both track AND knob AbsoluteSize
	-- are settled before knobPosScale reads them. Without defer, trackSize fires first
	-- while knob.AbsoluteSize is still the previous UIScale value, producing a wrong
	-- kHalf_frac that causes knob undershoot at 80% DPI and overshoot at 125% DPI.
	s._conns.trackSize = track:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		task.defer(refreshKnobLayout)
	end)
	-- Refresh when knob AbsoluteSize updates (UIScale tween settling, first layout)
	s._conns.knobSize  = knob:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		task.defer(refreshKnobLayout)
	end)

	s._themeUnsub = themeUtil.subscribe(function(t)
		s._theme = t
		stroke.Color = if hovering then (t.AccentColor or Color3.fromHex("#4cc2ff")) else (t.ElementStroke or Color3.fromHex("#2b2b2b"))
		label.TextColor3 = if s._enabled then (t.ContentColor or Color3.fromHex("#ffffff")) else Color3.fromHex("#555555")
		-- B3 FIX: use module-level constant instead of per-broadcast Font.new()
		label.FontFace = t.Font or DEFAULT_FONT
		valLabel.TextColor3 = t.PlaceholderColor or Color3.fromHex("#9d9d9d")
		valLabel.FontFace = t.Font or DEFAULT_FONT
		track.BackgroundColor3 = t.SliderBackground or Color3.fromHex("#222222")
		fill.BackgroundColor3 = t.AccentColor or Color3.fromHex("#4cc2ff")
		fillGrad.Color = t.SliderProgress or ColorSequence.new(Color3.fromHex("#4cc2ff"), Color3.fromHex("#0093fb"))
		knob.BackgroundColor3 = t.SliderHandle or Color3.fromRGB(255, 255, 255)
		innerGrad.Color = t.ElementGradient or ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromHex("#2e2e2e")),
			ColorSequenceKeypoint.new(1, Color3.fromHex("#181818")),
		})
		stroke.Transparency = if s._enabled then (t.ElementStrokeTransparency or 0) else 0.5
	end, frame)

	if flagKey and flagKey ~= "" then
		flags:Set(flagKey, initValue)
	end

	s._stopDrag = onRelease

	return self
end

-- ── Methods ───────────────────────────────────────────────────────────────────

function Slider:Set(value: number, skipCallback: boolean?)
	local s = self :: any
	local clamped = math.clamp(snap(value, s._step, s._min), s._min, s._max)
	local t = (clamped - s._min) / math.max(s._max - s._min, 1e-9)

	self.value = clamped
	self.Value = clamped
	s._valLabel.Text = s._fmtDisplay(clamped)

	-- Zero animations: direct property assignment
	local posScale = s._knobPosScale(t)
	s._clipFrame.Size = UDim2.new(posScale, 0, 1, 0)
	s._knob.Position = UDim2.new(posScale, 0, 0.5, 0)

	if s._flag then
		flags:Set(s._flag, clamped)
	end
	self.Changed:Fire(clamped)
	if not skipCallback and s._callback then
		task.spawn(s._callback, clamped)
	end
end

function Slider:SetValue(value: number, skipCallback: boolean?)
	self:Set(value, skipCallback)
end

function Slider:SetEnabled(enabled: boolean)
	local s = self :: any
	s._enabled = enabled
	s._label.TextColor3 = if enabled
		then (s._theme.ContentColor or Color3.fromHex("#ffffff"))
		else Color3.fromHex("#555555")
	s._stroke.Transparency = if enabled then 0 else 0.5
end

function Slider:GetFrame(): Frame
	return self._frame
end

function Slider:Destroy()
	local s = self :: any
	if s._stopDrag then s._stopDrag() end
	if s._themeUnsub then s._themeUnsub() end
	if s._conns then
		for _, conn in s._conns do
			conn:Disconnect()
		end
		table.clear(s._conns)
	end
	self.Changed:Destroy()
	self._frame:Destroy()
end

return Slider
