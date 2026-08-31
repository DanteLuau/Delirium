--!strict

local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local TextService      = game:GetService("TextService")

local Maid   = require(script.Parent.Parent.Utils.Maid)
local Signal = require(script.Parent.Parent.Utils.Signal)
local Theme  = require(script.Parent.Parent.Theme)

local TWEEN_HOVER  = TweenInfo.new(0.38, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local TWEEN_STROKE = TweenInfo.new(0.38, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local TWEEN_SHADOW = TweenInfo.new(0.38, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local TWEEN_PRESS  = TweenInfo.new(0.20, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local TWEEN_RESIZE = TweenInfo.new(0.25, Enum.EasingStyle.Sine,  Enum.EasingDirection.InOut)

local SHADOW_REST  = { BackgroundTransparency = 0.75, Position = UDim2.new(0.5, 0, 0.5, 3) }
local SHADOW_HOVER = { BackgroundTransparency = 0.65, Position = UDim2.new(0.5, 0, 0.5, 5) }

local PILL_H    = 22
local PILL_PAD  = 12   -- horizontal breathing room each side (= Theme.Spacing.M)

-- ── Key name map ───────────────────────────────────────────────────────────
local KEY_NAMES: { [Enum.KeyCode]: string } = {
	[Enum.KeyCode.LeftShift]    = "LeftShift",
	[Enum.KeyCode.RightShift]   = "RightShift",
	[Enum.KeyCode.LeftControl]  = "LeftCtrl",
	[Enum.KeyCode.RightControl] = "RightCtrl",
	[Enum.KeyCode.LeftAlt]      = "LeftAlt",
	[Enum.KeyCode.RightAlt]     = "RightAlt",
	[Enum.KeyCode.Return]       = "Enter",
	[Enum.KeyCode.Backspace]    = "Backspace",
	[Enum.KeyCode.Space]        = "Space",
	[Enum.KeyCode.Tab]          = "Tab",
	[Enum.KeyCode.Delete]       = "Delete",
	[Enum.KeyCode.Insert]       = "Insert",
	[Enum.KeyCode.Home]         = "Home",
	[Enum.KeyCode.End]          = "End",
	[Enum.KeyCode.PageUp]       = "PageUp",
	[Enum.KeyCode.PageDown]     = "PageDown",
	[Enum.KeyCode.CapsLock]     = "Caps",
	[Enum.KeyCode.Escape]       = "Esc",
	[Enum.KeyCode.F1]           = "F1",
	[Enum.KeyCode.F2]           = "F2",
	[Enum.KeyCode.F3]           = "F3",
	[Enum.KeyCode.F4]           = "F4",
	[Enum.KeyCode.F5]           = "F5",
	[Enum.KeyCode.F6]           = "F6",
	[Enum.KeyCode.F7]           = "F7",
	[Enum.KeyCode.F8]           = "F8",
	[Enum.KeyCode.F9]           = "F9",
	[Enum.KeyCode.F10]          = "F10",
	[Enum.KeyCode.F11]          = "F11",
	[Enum.KeyCode.F12]          = "F12",
}

local function keyName(key: Enum.KeyCode): string
	return KEY_NAMES[key] or key.Name
end

-- Returns the pixel width a string occupies at the pill's font + size.
local function measureText(text: string): number
	local v = TextService:GetTextSize(
		text,
		Theme.TextSize.Small,
		Enum.Font.Code,
		Vector2.new(math.huge, math.huge)
	)
	return v.X
end

-- Full pill width including side padding.
local function pillWidth(text: string): number
	return measureText(text) + PILL_PAD * 2
end

-- ── Types ──────────────────────────────────────────────────────────────────
export type KeybindConfig = {
	Label:       string,
	Icon:        string?,
	Default:     Enum.KeyCode?,
	Enabled:     boolean?,
	LayoutOrder: number?,
}

type KeybindImpl = {
	Key:          Enum.KeyCode?,
	Changed:      any,
	SetKey:       (self: KeybindImpl, key: Enum.KeyCode?) -> (),
	SetEnabled:   (self: KeybindImpl, enabled: boolean) -> (),
	GetFrame:     (self: KeybindImpl) -> Frame,
	Destroy:      (self: KeybindImpl) -> (),
	_exitBinding: (self: KeybindImpl, confirmed: boolean) -> (),
	_animatePill: (self: KeybindImpl, text: string) -> (),
	_maid:        any,
	_frame:       Frame,
	_inner:       Frame,
	_shadow:      Frame,
	_stroke:      UIStroke,
	_flash:       Frame,
	_label:       TextLabel,
	_icon:        ImageLabel?,
	_pill:        Frame,
	_pillStroke:  UIStroke,
	_pillLabel:   TextLabel,
	_content:     Frame,
	_enabled:     boolean,
	_binding:     boolean,
	_bindToken:   number,
}

local Keybind = {} :: { __index: any }
Keybind.__index = Keybind

function Keybind.new(config: KeybindConfig): KeybindImpl
	local self          = setmetatable({}, Keybind) :: KeybindImpl
	self._maid          = Maid.new()
	self._enabled       = if config.Enabled ~= nil then config.Enabled else true
	self._binding       = false
	self._bindToken     = 0
	self.Key            = config.Default

	-- ── Outer container ────────────────────────────────────────────────────
	local frame                  = Instance.new("Frame")
	frame.Name                   = "Keybind"
	frame.Size                   = UDim2.new(1, 0, 0, 36)
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel        = 0
	frame.LayoutOrder            = config.LayoutOrder or 0
	frame.ClipsDescendants       = false
	self._frame                  = frame

	-- ── Shadow ─────────────────────────────────────────────────────────────
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

	-- ── Inner row ──────────────────────────────────────────────────────────
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

	local pad        = Instance.new("UIPadding")
	pad.PaddingLeft  = UDim.new(0, Theme.Spacing.M)
	pad.PaddingRight = UDim.new(0, Theme.Spacing.M)
	pad.Parent       = inner

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

	-- ── Content (icon + label) ─────────────────────────────────────────────
	local initPillW = pillWidth(if config.Default then keyName(config.Default) else "—")

	local content                  = Instance.new("Frame")
	content.Name                   = "Content"
	content.Position               = UDim2.fromOffset(0, 0)
	content.Size                   = UDim2.new(1, -(initPillW + Theme.Spacing.M), 1, 0)
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

	-- ── Pill (key box) ─────────────────────────────────────────────────────
	-- Width is NOT AutomaticSize — it is computed via TextService and tweened
	-- so the resize is always animated rather than snapping.
	local pill              = Instance.new("Frame")
	pill.Name               = "Pill"
	pill.AnchorPoint        = Vector2.new(1, 0.5)
	pill.Size               = UDim2.fromOffset(initPillW, PILL_H)
	pill.Position           = UDim2.new(1, 0, 0.5, 0)
	pill.BackgroundColor3   = Theme.Colors.SurfaceActive
	pill.BorderSizePixel    = 0
	pill.ClipsDescendants   = true
	pill.ZIndex             = 4
	pill.Parent             = inner
	self._pill              = pill

	local pillCorner        = Instance.new("UICorner")
	pillCorner.CornerRadius = UDim.new(0, Theme.Radius.Pill)
	pillCorner.Parent       = pill

	-- Gradient slightly lighter than the container so the pill reads as elevated
	local pillGrad    = Instance.new("UIGradient")
	pillGrad.Color    = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromHex("#464646")),
		ColorSequenceKeypoint.new(1, Color3.fromHex("#353535")),
	})
	pillGrad.Rotation = 90
	pillGrad.Parent   = pill
	local pillStroke           = Instance.new("UIStroke")
	pillStroke.Color           = Theme.Colors.Border
	pillStroke.Thickness       = 1
	pillStroke.Transparency    = 0.45
	pillStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	pillStroke.Parent          = pill
	self._pillStroke           = pillStroke

	local pillLabel                  = Instance.new("TextLabel")
	pillLabel.Name                   = "PillLabel"
	pillLabel.Size                   = UDim2.fromScale(1, 1)
	pillLabel.BackgroundTransparency = 1
	pillLabel.Font                   = Theme.Font.Mono or Theme.Font.Body
	pillLabel.Text                   = if self.Key then keyName(self.Key) else "—"
	pillLabel.TextSize               = Theme.TextSize.Small or Theme.TextSize.Body
	pillLabel.TextColor3             = Theme.Colors.TextPrimary
	pillLabel.TextXAlignment         = Enum.TextXAlignment.Center
	pillLabel.TextYAlignment         = Enum.TextYAlignment.Center
	pillLabel.ZIndex                 = 5
	pillLabel.Parent                 = pill
	self._pillLabel                  = pillLabel


	-- ── PillHit covers ONLY the pill box, not the row ─────────────────────
	local pillHit                  = Instance.new("TextButton")
	pillHit.Name                   = "PillHit"
	pillHit.Size                   = UDim2.fromScale(1, 1)
	pillHit.BackgroundTransparency = 1
	pillHit.Text                   = ""
	pillHit.AutoButtonColor        = false
	pillHit.ZIndex                 = 9
	pillHit.Parent                 = pill

	-- ── Sync content width live as the pill tween runs ────────────────────
	-- AbsoluteSize fires every frame during a tween, so content tracks smoothly.
	local function syncContent()
		local pillW = pill.AbsoluteSize.X
		if pillW > 0 then
			content.Size = UDim2.new(1, -(pillW + Theme.Spacing.M), 1, 0)
		end
	end
	self._maid:GiveTask(pill:GetPropertyChangedSignal("AbsoluteSize"):Connect(syncContent))

	-- ── Signal ─────────────────────────────────────────────────────────────
	local changed = Signal.new()
	self.Changed  = changed
	self._maid:GiveTask(changed)

	-- ── Independent hover state ────────────────────────────────────────────
	local rowHovering  = false
	local pillHovering = false

	local function applyRowHover()
		TweenService:Create(stroke, TWEEN_STROKE, { Color = Theme.Colors.Accent }):Play()
		TweenService:Create(flash,  TWEEN_HOVER,  { BackgroundTransparency = 0.94 }):Play()
		TweenService:Create(shadow, TWEEN_SHADOW, {
			BackgroundTransparency = SHADOW_HOVER.BackgroundTransparency,
			Position               = SHADOW_HOVER.Position,
		}):Play()
	end

	local function clearRowHover()
		TweenService:Create(stroke, TWEEN_STROKE, { Color = Theme.Colors.Border }):Play()
		TweenService:Create(flash,  TWEEN_HOVER,  { BackgroundTransparency = 1 }):Play()
		TweenService:Create(shadow, TWEEN_SHADOW, {
			BackgroundTransparency = SHADOW_REST.BackgroundTransparency,
			Position               = SHADOW_REST.Position,
		}):Play()
	end

	local function applyPillHover()
		if self._binding then return end
		TweenService:Create(pillStroke, TWEEN_STROKE, { Color = Theme.Colors.Accent }):Play()
		TweenService:Create(pill,       TWEEN_HOVER,  { BackgroundColor3 = Theme.Colors.SurfaceActive }):Play()
		TweenService:Create(pillLabel,  TWEEN_HOVER,  { TextColor3 = Theme.Colors.TextPrimary }):Play()
		TweenService:Create(flash,      TWEEN_HOVER,  { BackgroundTransparency = 0.90 }):Play()
	end

	local function clearPillHover()
		if self._binding then return end
		TweenService:Create(pillStroke, TWEEN_STROKE, { Color = Theme.Colors.Border }):Play()
		TweenService:Create(pill,       TWEEN_HOVER,  { BackgroundColor3 = Theme.Colors.SurfaceActive }):Play()
		TweenService:Create(pillLabel,  TWEEN_HOVER,  { TextColor3 = Theme.Colors.TextPrimary }):Play()
	end

	self._maid:GiveTask(inner.MouseEnter:Connect(function()
		if not self._enabled then return end
		rowHovering = true
		if not pillHovering and not self._binding then
			applyRowHover()
		end
	end))

	self._maid:GiveTask(inner.MouseLeave:Connect(function()
		if not self._enabled then return end
		rowHovering  = false
		pillHovering = false
		if not self._binding then
			clearRowHover()
			clearPillHover()
		end
	end))

	self._maid:GiveTask(pillHit.MouseEnter:Connect(function()
		if not self._enabled then return end
		pillHovering = true
		applyPillHover()
	end))

	self._maid:GiveTask(pillHit.MouseLeave:Connect(function()
		if not self._enabled then return end
		pillHovering = false
		clearPillHover()
		if rowHovering and not self._binding then
			TweenService:Create(flash, TWEEN_HOVER, { BackgroundTransparency = 0.94 }):Play()
		end
	end))

	self._maid:GiveTask(pillHit.MouseButton1Down:Connect(function()
		if not self._enabled then return end
		TweenService:Create(pill, TWEEN_PRESS, {
			BackgroundColor3 = Theme.Colors.Surface or Theme.Colors.SurfaceActive,
		}):Play()
	end))

	self._maid:GiveTask(pillHit.MouseButton1Up:Connect(function()
		if not self._enabled then return end
		TweenService:Create(pill, TWEEN_PRESS, {
			BackgroundColor3 = Theme.Colors.SurfaceActive,
		}):Play()
	end))

	-- ── Pill click — toggle binding mode ──────────────────────────────────
	self._maid:GiveTask(pillHit.MouseButton1Click:Connect(function()
		if not self._enabled then return end
		self._binding = not self._binding

		if self._binding then
			self._bindToken += 1
			local token = self._bindToken

			-- Animate pill to fit "Recording" then show listening state
			self:_animatePill("Recording")
			pillLabel.Text       = "Recording"
			pillLabel.TextColor3 = Theme.Colors.Accent
			TweenService:Create(stroke,     TWEEN_STROKE, { Color = Theme.Colors.Accent }):Play()
			TweenService:Create(pillStroke, TWEEN_STROKE, { Color = Theme.Colors.Accent }):Play()
		else
			self._bindToken += 1
			self:_exitBinding(false)
		end
	end))

	-- ── Key capture ────────────────────────────────────────────────────────
	self._maid:GiveTask(UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
		if gameProcessed or not self._binding or not self._enabled then return end

		if input.UserInputType == Enum.UserInputType.Keyboard then
			if input.KeyCode == Enum.KeyCode.Escape then
				self._bindToken += 1
				self:_exitBinding(false)
				return
			end
			self._bindToken += 1
			self:SetKey(input.KeyCode)
			changed:Fire(input.KeyCode)
		end
	end))

	return self
end

-- ── Animate pill width to fit a new text string ───────────────────────────
function Keybind:_animatePill(text: string)
	local targetW = pillWidth(text)
	TweenService:Create(self._pill, TWEEN_RESIZE, {
		Size = UDim2.fromOffset(targetW, PILL_H),
	}):Play()
	-- content tracks via AbsoluteSize connection; no extra call needed
end

-- ── Internal: exit binding state cleanly ──────────────────────────────────
function Keybind:_exitBinding(confirmed: boolean)
	self._binding = false
	local restoreText = if self.Key then keyName(self.Key) else "—"
	if not confirmed then
		-- Cancelled — animate back to previous key width, restore label
		self:_animatePill(restoreText)
		self._pillLabel.Text = restoreText
	end
	TweenService:Create(self._flash,      TWEEN_HOVER,  { BackgroundTransparency = 1 }):Play()
	TweenService:Create(self._stroke,     TWEEN_STROKE, { Color = Theme.Colors.Border }):Play()
	TweenService:Create(self._pillStroke, TWEEN_STROKE, { Color = Theme.Colors.Border }):Play()
	self._pill.BackgroundColor3 = Theme.Colors.SurfaceActive
	TweenService:Create(self._pillLabel,  TWEEN_HOVER,  { TextColor3 = Theme.Colors.TextPrimary }):Play()
end

-- ── Public API ─────────────────────────────────────────────────────────────
function Keybind:SetKey(key: Enum.KeyCode?)
	self.Key = key
	local newText = if key then keyName(key) else "—"
	self._pillLabel.Text = newText
	self:_animatePill(newText)
	-- _exitBinding handles dot tween + all cleanup tweens
	self:_exitBinding(true)
end

function Keybind:SetEnabled(enabled: boolean)
	self._enabled          = enabled
	local color            = if enabled then Theme.Colors.TextPrimary else Theme.Colors.TextDisabled
	self._label.TextColor3 = color
	if self._icon then
		self._icon.ImageColor3 = color
	end
	self._stroke.Transparency = if enabled then 0 else 0.5
end

function Keybind:GetFrame(): Frame
	return self._frame
end

function Keybind:Destroy()
	self._maid:DoCleaning()
	if self._frame and self._frame.Parent then
		self._frame:Destroy()
	end
end

return Keybind
