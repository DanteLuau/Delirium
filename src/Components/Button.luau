--!strict

local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Maid   = require(script.Parent.Parent.Utils.Maid)
local Signal = require(script.Parent.Parent.Utils.Signal)
local Theme  = require(script.Parent.Parent.Theme)

local TWEEN_HOVER   = TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local TWEEN_PRESS   = TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local TWEEN_RELEASE = TweenInfo.new(0.3,  Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local TWEEN_STROKE  = TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local TWEEN_SHADOW  = TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

-- Shadow states
local SHADOW_REST  = { BackgroundTransparency = 0.75, Position = UDim2.new(0.5, 0, 0.5, 3) }
local SHADOW_HOVER = { BackgroundTransparency = 0.65, Position = UDim2.new(0.5, 0, 0.5, 5) }
local SHADOW_PRESS = { BackgroundTransparency = 0.92, Position = UDim2.new(0.5, 0, 0.5, 1) }

export type ButtonConfig = {
	Label: string,
	Icon: string?,   -- optional rbxassetid or image url
	Variant: number?,
	Enabled: boolean?,
	LayoutOrder: number?,
	-- When true, label renders in Theme.Colors.Error (visual-only danger signal).
	-- Does not affect click behaviour or any other logic.
	Risky: boolean?,
}

type ButtonImpl = {
	Clicked: any,
	SetLabel:   (self: ButtonImpl, text: string) -> (),
	SetEnabled: (self: ButtonImpl, enabled: boolean) -> (),
	GetFrame:   (self: ButtonImpl) -> Frame,
	Destroy:    (self: ButtonImpl) -> (),
	_maid:      any,
	_frame:     Frame,
	_inner:     Frame,
	_content:   Frame,
	_label:     TextLabel,
	_icon:      ImageLabel?,
	_btn:       TextButton,
	_stroke:    UIStroke,
	_scale:     UIScale,
	_flash:     Frame,
	_shadow:    Frame,
	_enabled:   boolean,
	_variant:   number,
	_risky:     boolean,
	_strokeGrad: UIGradient?,
}

local Button = {} :: { __index: any }
Button.__index = Button

function Button.new(config: ButtonConfig): ButtonImpl
	local self    = setmetatable({}, Button) :: ButtonImpl
	self._maid    = Maid.new()
	self._variant = config.Variant or 0
	self._enabled = if config.Enabled ~= nil then config.Enabled else true
	self._risky   = config.Risky == true

	-- ── Outer container ───────────────────────────────────────────────────────
	local frame                  = Instance.new("Frame")
	frame.Name                   = "Button"
	frame.Size                   = UDim2.new(1, 0, 0, 36)
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel        = 0
	frame.LayoutOrder            = config.LayoutOrder or 0
	frame.ClipsDescendants       = false
	self._frame                  = frame

	-- ── Shadow — behind inner, gives depth ───────────────────────────────────
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

	-- ── Inner visual shell ───────────────────────────────────────────────────
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

	local corner        = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, Theme.Radius.Small)
	corner.Parent       = inner

	local grad    = Instance.new("UIGradient")
	grad.Color    = if (config.Variant or 0) == 1
		then Theme.Colors.AccentGradient
		else ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromHex("#2e2e2e")),
			ColorSequenceKeypoint.new(1, Color3.fromHex("#181818")),
		})
	grad.Rotation = if (config.Variant or 0) == 1 then 0 else 90
	grad.Parent   = inner

	local stroke           = Instance.new("UIStroke")
	stroke.Color           = Theme.Colors.Border
	stroke.Thickness       = 1
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent          = inner
	self._stroke           = stroke

	local uiScale  = Instance.new("UIScale")
	uiScale.Scale  = 1
	uiScale.Parent = inner
	self._scale    = uiScale

	-- Flash overlay
	local flashColor             = if (config.Variant or 0) == 1
		then Theme.Colors.Accent
		else Color3.new(1, 1, 1)
	local flash                  = Instance.new("Frame")
	flash.Name                   = "Flash"
	flash.Size                   = UDim2.fromScale(1, 1)
	flash.BackgroundColor3       = flashColor
	flash.BackgroundTransparency = 1
	flash.BorderSizePixel        = 0
	flash.ZIndex                 = 3
	local flashCorner            = Instance.new("UICorner")
	flashCorner.CornerRadius     = UDim.new(0, Theme.Radius.Small)
	flashCorner.Parent           = flash
	flash.Parent                 = inner
	self._flash                  = flash

	-- ── Hit target ────────────────────────────────────────────────────────────
	local btn                  = Instance.new("TextButton")
	btn.Name                   = "Hit"
	btn.Size                   = UDim2.fromScale(1, 1)
	btn.BackgroundTransparency = 1
	btn.Text                   = ""
	btn.AutoButtonColor        = false
	btn.ZIndex                 = 5
	btn.Parent                 = inner
	self._btn                  = btn

	-- ── Content container — inside inner so UIScale carries it on press ────────
	-- Icon + Label sit here side-by-side via UIListLayout.
	local content                  = Instance.new("Frame")
	content.Name                   = "Content"
	content.Position               = UDim2.fromOffset(Theme.Spacing.M, 0)
	content.Size                   = UDim2.new(1, -(Theme.Spacing.M * 2), 1, 0)
	content.BackgroundTransparency = 1
	content.BorderSizePixel        = 0
	content.ClipsDescendants       = true
	content.ZIndex                 = 4
	content.Parent                 = inner
	self._content                  = content

	local layout                    = Instance.new("UIListLayout")
	layout.FillDirection            = Enum.FillDirection.Horizontal
	layout.VerticalAlignment        = Enum.VerticalAlignment.Center
	layout.HorizontalAlignment      = Enum.HorizontalAlignment.Left
	layout.Padding                  = UDim.new(0, 6)
	layout.SortOrder                = Enum.SortOrder.LayoutOrder
	layout.Parent                   = content

	-- Optional icon
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

	-- Label — AutomaticSize X so it fills remaining space, Shrink so it gives up to icon
	local label                  = Instance.new("TextLabel")
	label.Name                   = "Label"
	label.AutomaticSize          = Enum.AutomaticSize.X
	label.Size                   = UDim2.fromOffset(0, Theme.TextSize.Body)
	label.BackgroundTransparency = 1
	label.Font                   = Theme.Font.Body
	label.Text                   = config.Label
	label.TextSize               = Theme.TextSize.Body
	label.TextColor3             = if not self._enabled
		then Theme.Colors.TextDisabled
		elseif self._risky then Theme.Colors.Error
		else Theme.Colors.TextPrimary
	label.TextXAlignment         = Enum.TextXAlignment.Left
	label.TextTruncate           = Enum.TextTruncate.AtEnd
	label.LayoutOrder            = 1
	label.ZIndex                 = 4
	label.Parent                 = content
	self._label                  = label

	-- Shrinks to let icon breathe when space is tight
	local flex     = Instance.new("UIFlexItem")
	flex.FlexMode  = Enum.UIFlexMode.Shrink
	flex.Parent    = label

	-- ── Interactions ──────────────────────────────────────────────────────────

	local clicked = Signal.new()
	self.Clicked  = clicked
	self._maid:GiveTask(clicked)

	local pressing = false
	local hovering = false

	local function releasePress()
		if not pressing then return end
		pressing = false
		local shadowTarget = if hovering then SHADOW_HOVER else SHADOW_REST
		local flashTarget  = if hovering then (if self._variant == 1 then 0.88 else 0.94) else 1
		TweenService:Create(inner,  TWEEN_RELEASE, { Size = UDim2.new(1, 0, 1, 0) }):Play()
		TweenService:Create(flash,  TWEEN_RELEASE, { BackgroundTransparency = flashTarget }):Play()
		TweenService:Create(shadow, TWEEN_SHADOW,  {
			BackgroundTransparency = shadowTarget.BackgroundTransparency,
			Position = shadowTarget.Position,
			Size = UDim2.new(1, 0, 1, 4),
		}):Play()
		if self._variant == 1 then
			-- restore gradient state based on hover
			local nextGrad = if hovering
				then Theme.Colors.AccentGradientHover
				else Theme.Colors.AccentGradient
			grad.Color = nextGrad
			if self._strokeGrad then
				self._strokeGrad.Color = nextGrad
			end
		else
			local restColor = Theme.Colors.Border
			local restAlpha = if hovering then 0 else 0
			TweenService:Create(stroke, TWEEN_STROKE, {
				Color = if hovering then Theme.Colors.Accent else restColor,
				Transparency = restAlpha,
			}):Play()
		end
	end

	if self._variant == 1 then
		-- Gradient border: UIGradient child overrides stroke.Color visually
		local strokeGrad    = Instance.new("UIGradient")
		strokeGrad.Color    = Theme.Colors.AccentGradient
		strokeGrad.Rotation = 0
		strokeGrad.Parent   = stroke
		self._strokeGrad    = strokeGrad
		stroke.Color        = Color3.new(1, 1, 1) -- overridden by UIGradient
		stroke.Transparency = 0
	end

	self._maid:GiveTask(btn.MouseEnter:Connect(function()
		if not self._enabled then return end
		hovering = true
		if not pressing then
			if self._variant == 1 then
				-- UIGradient.Color can't be tweened — swap directly
				grad.Color = Theme.Colors.AccentGradientHover
				if self._strokeGrad then
					self._strokeGrad.Color = Theme.Colors.AccentGradientHover
				end
			else
				TweenService:Create(stroke, TWEEN_STROKE, { Color = Theme.Colors.Accent, Transparency = 0 }):Play()
			end
			TweenService:Create(flash,  TWEEN_HOVER,  { BackgroundTransparency = if self._variant == 1 then 0.88 else 0.94 }):Play()
			TweenService:Create(shadow, TWEEN_SHADOW, SHADOW_HOVER):Play()
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
			if self._variant == 1 then
				grad.Color = Theme.Colors.AccentGradient
				if self._strokeGrad then
					self._strokeGrad.Color = Theme.Colors.AccentGradient
				end
			else
				TweenService:Create(stroke, TWEEN_STROKE, { Color = Theme.Colors.Border, Transparency = 0 }):Play()
			end
			TweenService:Create(flash,  TWEEN_HOVER,  { BackgroundTransparency = 1 }):Play()
			TweenService:Create(shadow, TWEEN_SHADOW, SHADOW_REST):Play()
		end
	end))

	self._maid:GiveTask(btn.MouseButton1Down:Connect(function()
		if not self._enabled then return end
		pressing = true
		TweenService:Create(inner,   TWEEN_PRESS,  { Size = UDim2.new(1, -6, 1, -2) }):Play()
		TweenService:Create(flash,   TWEEN_PRESS,  { BackgroundTransparency = 0.82 }):Play()
		TweenService:Create(shadow,  TWEEN_PRESS,  {
			BackgroundTransparency = SHADOW_PRESS.BackgroundTransparency,
			Position = SHADOW_PRESS.Position,
			Size = UDim2.new(1, -6, 1, 2),
		}):Play()
		if self._variant ~= 1 then
			TweenService:Create(stroke, TWEEN_PRESS, { Color = Theme.Colors.AccentHover, Transparency = 0 }):Play()
		end
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
		clicked:Fire()
	end))

	return self
end

function Button:SetLabel(text: string)
	self._label.Text = text
end

function Button:SetEnabled(enabled: boolean)
	self._enabled             = enabled
	local color               = if not enabled
		then Theme.Colors.TextDisabled
		elseif self._risky then Theme.Colors.Error
		else Theme.Colors.TextPrimary
	self._label.TextColor3    = color
	if self._icon then
		-- icon stays neutral; Risky only tints the label
		self._icon.ImageColor3 = if enabled then Theme.Colors.TextPrimary else Theme.Colors.TextDisabled
	end
	self._stroke.Color        = Theme.Colors.Border
	self._stroke.Transparency = if enabled then 0 else 0.5
end

function Button:GetFrame(): Frame
	return self._frame
end

function Button:Destroy()
	self._maid:DoCleaning()
	if self._frame and self._frame.Parent then
		self._frame:Destroy()
	end
end

return Button
