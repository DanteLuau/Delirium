--!strict

local TweenService = game:GetService("TweenService")

local Maid        = require(script.Parent.Parent.Utils.Maid)
local Signal      = require(script.Parent.Parent.Utils.Signal)
local Theme       = require(script.Parent.Parent.Theme)
local SaveManager = require(script.Parent.Parent.Core.SaveManager)

local TWEEN_STROKE = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TWEEN_HOVER  = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TWEEN_SHADOW = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local SHADOW_REST  = { BackgroundTransparency = 0.75, Position = UDim2.new(0.5, 0, 0.5, 3) }
local SHADOW_HOVER = { BackgroundTransparency = 0.65, Position = UDim2.new(0.5, 0, 0.5, 5) }

-- Fixed width reserved for the optional label portion.
-- If no label, this is 0 and the input fills the full row.
local LABEL_W = 90

export type TextboxConfig = {
	Label: string?,
	Placeholder: string?,
	Default: string?,
	MaxLength: number?,
	ClearOnFocus: boolean?,
	Enabled: boolean?,
	LayoutOrder: number?,
	Flag: string?,
}

type TextboxImpl = {
	Value:      string,
	Changed:    any,
	FocusLost:  any,
	SetValue:   (self: TextboxImpl, text: string) -> (),
	SetEnabled: (self: TextboxImpl, enabled: boolean) -> (),
	GetFrame:   (self: TextboxImpl) -> Frame,
	Destroy:    (self: TextboxImpl) -> (),
	_maid:      any,
	_frame:     Frame,
	_inner:     Frame,
	_outerLabel: TextLabel?,
	_input:     TextBox,
	_stroke:    UIStroke,
	_flash:     Frame,
	_shadow:    Frame,
	_enabled:   boolean,
}

local Textbox = {} :: { __index: any }
Textbox.__index = Textbox

function Textbox.new(config: TextboxConfig): TextboxImpl
	local self    = setmetatable({}, Textbox) :: TextboxImpl
	self._maid    = Maid.new()
	self._enabled = if config.Enabled ~= nil then config.Enabled else true
	self.Value    = config.Default or ""

	local hasLabel   = config.Label ~= nil and #(config.Label :: string) > 0
	local leftPad    = if hasLabel then LABEL_W + Theme.Spacing.M else Theme.Spacing.M

	-- ── Outer container ───────────────────────────────────────────────────────
	local frame                  = Instance.new("Frame")
	frame.Name                   = "Textbox"
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

	-- ── Inner row ─────────────────────────────────────────────────────────────
	local inner            = Instance.new("Frame")
	inner.Name             = "Inner"
	inner.AnchorPoint      = Vector2.new(0.5, 0.5)
	inner.Position         = UDim2.new(0.5, 0, 0.5, 0)
	inner.Size             = UDim2.new(1, 0, 1, 0)
	inner.BackgroundColor3 = Color3.new(1, 1, 1)
	inner.BorderSizePixel  = 0
	inner.ZIndex           = 2
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

	-- Padding: left is wider when a label is present so the input starts after it
	local pad        = Instance.new("UIPadding")
	pad.PaddingLeft  = UDim.new(0, leftPad)
	pad.PaddingRight = UDim.new(0, Theme.Spacing.M)
	pad.Parent       = inner

	-- Flash — bleeds past UIPadding on both sides to cover full row width
	local flash                  = Instance.new("Frame")
	flash.Name                   = "Flash"
	flash.Size                   = UDim2.new(1, leftPad + Theme.Spacing.M, 1, 0)
	flash.Position               = UDim2.new(0, -leftPad, 0, 0)
	flash.BackgroundColor3       = Color3.new(1, 1, 1)
	flash.BackgroundTransparency = 1
	flash.BorderSizePixel        = 0
	flash.ZIndex                 = 3
	local flashCorner            = Instance.new("UICorner")
	flashCorner.CornerRadius     = UDim.new(0, Theme.Radius.Small)
	flashCorner.Parent           = flash
	flash.Parent                 = inner
	self._flash                  = flash

	-- ── Optional label on outer frame ─────────────────────────────────────────
	if hasLabel then
		local outerLabel                  = Instance.new("TextLabel")
		outerLabel.Name                   = "Label"
		outerLabel.Position               = UDim2.fromOffset(Theme.Spacing.M, 0)
		outerLabel.Size                   = UDim2.fromOffset(LABEL_W, 36)
		outerLabel.BackgroundTransparency = 1
		outerLabel.Font                   = Theme.Font.Body
		outerLabel.Text                   = config.Label :: string
		outerLabel.TextSize               = Theme.TextSize.Body
		outerLabel.TextColor3             = if self._enabled
			then Theme.Colors.TextPrimary
			else Theme.Colors.TextDisabled
		outerLabel.TextXAlignment         = Enum.TextXAlignment.Left
		outerLabel.TextTruncate           = Enum.TextTruncate.AtEnd
		outerLabel.ZIndex                 = 4
		outerLabel.Parent                 = frame
		self._outerLabel                  = outerLabel
	end

	-- ── TextBox input ─────────────────────────────────────────────────────────
	local input                  = Instance.new("TextBox")
	input.Name                   = "Input"
	input.Size                   = UDim2.fromScale(1, 1)
	input.BackgroundTransparency = 1
	input.Font                   = Theme.Font.Body
	input.Text                   = config.Default or ""
	input.PlaceholderText        = config.Placeholder or ""
	input.PlaceholderColor3      = Theme.Colors.TextDisabled
	input.TextSize               = Theme.TextSize.Body
	input.TextColor3             = Theme.Colors.TextPrimary
	input.TextXAlignment         = Enum.TextXAlignment.Right
	input.ClearTextOnFocus       = if config.ClearOnFocus ~= nil then config.ClearOnFocus else false
	input.BorderSizePixel        = 0
	input.TextEditable           = self._enabled
	input.ZIndex                 = 4
	input.Parent                 = inner
	self._input                  = input

	-- ── Signals ───────────────────────────────────────────────────────────────
	local changed   = Signal.new()
	local focusLost = Signal.new()
	self.Changed    = changed
	self.FocusLost  = focusLost
	self._maid:GiveTask(changed)
	self._maid:GiveTask(focusLost)

	-- Character limit enforcement
	if config.MaxLength then
		local maxLen = config.MaxLength :: number
		self._maid:GiveTask(input:GetPropertyChangedSignal("Text"):Connect(function()
			if #input.Text > maxLen then
				-- Truncate without triggering a re-entry loop via TextEditable guard
				local clamped = string.sub(input.Text, 1, maxLen)
				input.Text = clamped
			end
		end))
	end

	-- ── Focus / hover states ──────────────────────────────────────────────────
	self._maid:GiveTask(input.Focused:Connect(function()
		if not self._enabled then return end
		TweenService:Create(stroke, TWEEN_STROKE, { Color = Theme.Colors.Accent }):Play()
		TweenService:Create(shadow, TWEEN_SHADOW, SHADOW_HOVER):Play()
	end))

	self._maid:GiveTask(input.FocusLost:Connect(function(enterPressed: boolean)
		TweenService:Create(stroke, TWEEN_STROKE, { Color = Theme.Colors.Border }):Play()
		TweenService:Create(shadow, TWEEN_SHADOW, SHADOW_REST):Play()
		self.Value = input.Text
		focusLost:Fire(input.Text, enterPressed)
	end))

	self._maid:GiveTask(input:GetPropertyChangedSignal("Text"):Connect(function()
		self.Value = input.Text
		changed:Fire(input.Text)
	end))

	self._maid:GiveTask(input.MouseEnter:Connect(function()
		if not self._enabled or input:IsFocused() then return end
		TweenService:Create(stroke, TWEEN_STROKE, { Color = Theme.Colors.Accent }):Play()
		TweenService:Create(flash,  TWEEN_HOVER,  { BackgroundTransparency = 0.96 }):Play()
		TweenService:Create(shadow, TWEEN_SHADOW, SHADOW_HOVER):Play()
	end))

	self._maid:GiveTask(input.MouseLeave:Connect(function()
		if not self._enabled or input:IsFocused() then return end
		TweenService:Create(stroke, TWEEN_STROKE, { Color = Theme.Colors.Border }):Play()
		TweenService:Create(flash,  TWEEN_HOVER,  { BackgroundTransparency = 1 }):Play()
		TweenService:Create(shadow, TWEEN_SHADOW, SHADOW_REST):Play()
	end))

	-- ── SaveManager wiring ────────────────────────────────────────────────
	do
		local rawLabel = config.Label
		local flag = config.Flag
			or (if rawLabel then SaveManager.deriveFlagFromName(rawLabel) else "")
		if flag ~= "" then
			SaveManager.Register(
				flag,
				function() return self.Value end,
				function(v: any)
					if type(v) == "string" then
						self:SetValue(v)
					end
				end
			)
			-- wire on FocusLost (when value is committed) rather than Changed
			-- to avoid hammering disk on every keystroke
			self._maid:GiveTask(focusLost:Connect(function()
				SaveManager._scheduleAutoSave()
			end))
		end
	end

	return self
end

function Textbox:SetValue(text: string)
	self._input.Text = text
	self.Value       = text
end

function Textbox:SetEnabled(enabled: boolean)
	self._enabled            = enabled
	self._input.TextEditable = enabled
	self._stroke.Transparency = if enabled then 0 else 0.5
	if self._outerLabel then
		self._outerLabel.TextColor3 = if enabled
			then Theme.Colors.TextPrimary
			else Theme.Colors.TextDisabled
	end
end

function Textbox:GetFrame(): Frame
	return self._frame
end

function Textbox:Destroy()
	self._maid:DoCleaning()
	if self._frame and self._frame.Parent then
		self._frame:Destroy()
	end
end

return Textbox
