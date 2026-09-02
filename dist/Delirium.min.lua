-- ++++++++ WAX BUNDLED DATA BELOW ++++++++ --

-- Will be used later for getting flattened globals
local ImportGlobals

-- Holds direct closure data (defining this before the DOM tree for line debugging etc)
local ClosureBindings = {
    function()local wax,script,require=ImportGlobals(1)local ImportGlobals return (function(...)--!strict

local Theme        = require(script.Theme)
local Core         = require(script.Core)
local SaveManager  = require(script.Core.SaveManager)
local Notification = require(script.Core.Notification)
local Popup        = require(script.Core.Popup)

-- ── Public types ──────────────────────────────────────────────────────────────

export type WindowConfig = {
	Size:     UDim2?,
	Position: UDim2?,
	MinSize:  Vector2?,
}

export type NotifyConfig = Notification.NotifyConfig
export type PopupConfig  = Popup.PopupConfig

-- ── Library object ────────────────────────────────────────────────────────────

local Delirium = {}
Delirium.__index = Delirium

-- Sub-modules exposed to script authors
Delirium.Theme       = Theme
Delirium.Components  = Core.Components
Delirium.SaveManager = SaveManager
Delirium.Flags       = SaveManager.Flags   -- live read-only flag table
Delirium.Version     = "0.0.1"

function Delirium.new()
	return setmetatable({}, Delirium)
end

-- ── Windows ───────────────────────────────────────────────────────────────────

function Delirium:CreateWindow(title: string, options: WindowConfig?)
	assert(
		type(title) == "string" and #title > 0,
		"[Delirium] CreateWindow — title must be a non-empty string"
	)
	local win        = Core.Window.new(title, options)
	self._activeWin  = win
	return win
end

-- ── Notifications ─────────────────────────────────────────────────────────────

function Delirium:Notify(config: NotifyConfig)
	Notification.notify(config)
end

-- ── Popups ───────────────────────────────────────────────────────────────────

function Delirium:Popup(config: PopupConfig)
	local win = self._activeWin
	if not win then
		warn("[Delirium] Popup — no active window. Call CreateWindow first.")
		return
	end
	Popup.show(win._canvas, config)
end

-- ── Entry point ───────────────────────────────────────────────────────────────

return Delirium.new()

end)() end,
    function()local wax,script,require=ImportGlobals(2)local ImportGlobals return (function(...)--!strict

-- Isolated requires: if one component fails to load, the error is surfaced
-- immediately with context instead of producing a cryptic "module failed" at
-- the library entry point.

local function safeRequire(loader: () -> any, name: string): any
	local ok, result = pcall(loader)
	if not ok then
		warn(string.format("[Delirium] Component '%s' failed to load: %s", name, tostring(result)))
		return nil
	end
	return result
end

local Button      = safeRequire(function() return require(script.Button)      end, "Button")
local Toggle      = safeRequire(function() return require(script.Toggle)      end, "Toggle")
local Label       = safeRequire(function() return require(script.Label)       end, "Label")
local Description = safeRequire(function() return require(script.Description) end, "Description")
local Divider     = safeRequire(function() return require(script.Divider)     end, "Divider")
local Slider      = safeRequire(function() return require(script.Slider)      end, "Slider")
local Textbox     = safeRequire(function() return require(script.Textbox)     end, "Textbox")
local Keybind     = safeRequire(function() return require(script.Keybind)     end, "Keybind")
local Dropdown    = safeRequire(function() return require(script.Dropdown)    end, "Dropdown")
local ColorPicker = safeRequire(function() return require(script.ColorPicker) end, "ColorPicker")

return {
	Button      = Button,
	Toggle      = Toggle,
	Label       = Label,
	Description = Description,
	Divider     = Divider,
	Slider      = Slider,
	Textbox     = Textbox,
	Keybind     = Keybind,
	Dropdown    = Dropdown,
	ColorPicker = ColorPicker,
}

end)() end,
    function()local wax,script,require=ImportGlobals(3)local ImportGlobals return (function(...)--!strict

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

end)() end,
    function()local wax,script,require=ImportGlobals(4)local ImportGlobals return (function(...)--!strict
-- ColorPicker — Delirium Reworked
--
-- Container row: styled identical to Button/Toggle (shadow, gradient inner, stroke,
-- UIScale, flash overlay, hover/press/release animations).
-- Click → centered floating popup on OverlayParent (ScreenGui).
--
-- Popup layout:
--   [ SV canvas ] | [ hue ] | [ alpha? ] | [ swatch ]
--                                           [ hex  | alpha% ]
--
-- Drag is pumped via RenderStepped; handles swell when grabbed (Rayfield-style).
-- Popup is sized safely for both desktop (360px) and mobile (7.5px margin on 375px).

local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local RunService       = game:GetService("RunService")

local Maid        = require(script.Parent.Parent.Utils.Maid)
local Signal      = require(script.Parent.Parent.Utils.Signal)
local Theme       = require(script.Parent.Parent.Theme)
local SaveManager = require(script.Parent.Parent.Core.SaveManager)
local SmoothScroll = require(script.Parent.Parent.Utils.SmoothScroll)

-- ── Container interaction constants (mirrors Button / Toggle exactly) ─────────

local TW_HOVER   = TweenInfo.new(0.25, Enum.EasingStyle.Quint,       Enum.EasingDirection.Out)
local TW_PRESS   = TweenInfo.new(0.18, Enum.EasingStyle.Quint,       Enum.EasingDirection.Out)
local TW_RELEASE = TweenInfo.new(0.30, Enum.EasingStyle.Quint,       Enum.EasingDirection.Out)
local TW_STROKE  = TweenInfo.new(0.25, Enum.EasingStyle.Quint,       Enum.EasingDirection.Out)
local TW_SHADOW  = TweenInfo.new(0.25, Enum.EasingStyle.Quint,       Enum.EasingDirection.Out)

local SHADOW_REST  = { BackgroundTransparency = 0.75, Position = UDim2.new(0.5, 0, 0.5, 3) }
local SHADOW_HOVER = { BackgroundTransparency = 0.65, Position = UDim2.new(0.5, 0, 0.5, 5) }
local SHADOW_PRESS = { BackgroundTransparency = 0.92, Position = UDim2.new(0.5, 0, 0.5, 1) }

-- ── Popup geometry ────────────────────────────────────────────────────────────

local HEADER_H = 36     -- container row height (same as Button / Toggle)
local PILL_W   = 32     -- preview pill width in the header
local PILL_H   = 18
local PILL_R   = 4

local POPUP_W  = 360    -- popup total width — fits 375px mobile with 7.5px each side
local POPUP_Z  = 200

local PAD      = 12     -- popup inner padding
local MAP_W    = 175    -- SV canvas width
local MAP_H    = 148    -- SV canvas + strip height
local CURSOR_D = 14     -- SV cursor diameter
local HUE_W    = 12     -- hue strip width
local ALPHA_W  = 12     -- alpha strip width
local HANDLE_H = 10     -- strip knob height (rest)
local HANDLE_H_HELD = 14 -- strip knob height when grabbed (swell)
local GAP_CH   = 8      -- canvas → hue gap
local GAP_HA   = 6      -- hue → alpha gap
local GAP_AR   = 12     -- (alpha or hue) → right section gap

local TITLE_H  = 32
local HEX_H    = 28
local GAP_PH   = 10

-- Derived horizontal positions (computed once at module load for the no-alpha case;
-- alpha case shifts rightX right by ALPHA_W + GAP_HA).
local hueX_base: number   = PAD + MAP_W + GAP_CH            -- 195
local alphaX_base: number = hueX_base + HUE_W + GAP_HA      -- 213
local rightX_noAlpha: number = hueX_base + HUE_W + GAP_AR   -- 219
local rightX_alpha: number   = alphaX_base + ALPHA_W + GAP_AR -- 237

local ABOX_W   = 53
local ABOX_GAP = 5

local CONTENT_Y = TITLE_H + PAD                             -- 44
local POPUP_H   = CONTENT_Y + MAP_H + PAD                   -- 204

-- Canvas cursor swell sizes
local CURSOR_SIZE_REST = UDim2.fromOffset(CURSOR_D, CURSOR_D)
local CURSOR_SIZE_HELD = UDim2.fromOffset(CURSOR_D + 4, CURSOR_D + 4)

local HUE_HANDLE_SIZE_REST = UDim2.fromOffset(HUE_W + 8,   HANDLE_H)
local HUE_HANDLE_SIZE_HELD = UDim2.fromOffset(HUE_W + 12,  HANDLE_H_HELD)
local ALP_HANDLE_SIZE_REST = UDim2.fromOffset(ALPHA_W + 8,  HANDLE_H)
local ALP_HANDLE_SIZE_HELD = UDim2.fromOffset(ALPHA_W + 12, HANDLE_H_HELD)

local TW_SWELL  = TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

-- Hue spectrum
local HUE_CS = ColorSequence.new({
	ColorSequenceKeypoint.new(0.000, Color3.fromRGB(255, 0,   0)),
	ColorSequenceKeypoint.new(0.167, Color3.fromRGB(255, 255, 0)),
	ColorSequenceKeypoint.new(0.333, Color3.fromRGB(0,   255, 0)),
	ColorSequenceKeypoint.new(0.500, Color3.fromRGB(0,   255, 255)),
	ColorSequenceKeypoint.new(0.667, Color3.fromRGB(0,   0,   255)),
	ColorSequenceKeypoint.new(0.833, Color3.fromRGB(255, 0,   255)),
	ColorSequenceKeypoint.new(1.000, Color3.fromRGB(255, 0,   0)),
})

local TW_OPEN    = TweenInfo.new(0.30, Enum.EasingStyle.Back,        Enum.EasingDirection.Out)
local TW_CLOSE   = TweenInfo.new(0.18, Enum.EasingStyle.Quint,       Enum.EasingDirection.In)
local TW_DRAG    = TweenInfo.new(0.10, Enum.EasingStyle.Quint,       Enum.EasingDirection.Out)
local TW_SET     = TweenInfo.new(0.22, Enum.EasingStyle.Quint,       Enum.EasingDirection.Out)
local TW_DIM_IN  = TweenInfo.new(0.28, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
local TW_DIM_OUT = TweenInfo.new(0.24, Enum.EasingStyle.Quint,       Enum.EasingDirection.In)

local DIM_TRANSPARENCY = 0.45

-- ── Types ─────────────────────────────────────────────────────────────────────

export type ColorPickerConfig = {
	Label:         string,
	Default:       Color3?,
	ShowAlpha:     boolean?,
	Flag:          string?,
	Risky:         boolean?,
	Enabled:       boolean?,
	OverlayParent: ScreenGui?,
	Canvas:        Frame?,
	LayoutOrder:   number?,
	description:   string?,
}

export type ColorPickerImpl = {
	Changed:    any,
	SetValue:   (self: ColorPickerImpl, color: Color3, alpha: number?) -> (),
	SetEnabled: (self: ColorPickerImpl, enabled: boolean) -> (),
	GetFrame:   (self: ColorPickerImpl) -> Frame,
	Destroy:    (self: ColorPickerImpl) -> (),
}

-- ── Helpers ───────────────────────────────────────────────────────────────────

local function mkCorner(inst: Instance, r: number)
	local c        = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r)
	c.Parent       = inst
end

local function mkStroke(inst: Instance, col: Color3, thick: number): UIStroke
	local s            = Instance.new("UIStroke")
	s.Color            = col
	s.Thickness        = thick
	s.ApplyStrokeMode  = Enum.ApplyStrokeMode.Border
	s.Parent           = inst
	return s
end

local function clamp01(n: number): number
	return math.clamp(n, 0, 1)
end

local function colorToHex(c: Color3): string
	return string.format("#%02X%02X%02X",
		math.round(c.R * 255),
		math.round(c.G * 255),
		math.round(c.B * 255))
end

local function hexToColor(raw: string): Color3?
	local hex = raw:gsub("^#", "")
	if #hex ~= 6 then return nil end
	local r = tonumber(hex:sub(1, 2), 16)
	local g = tonumber(hex:sub(3, 4), 16)
	local b = tonumber(hex:sub(5, 6), 16)
	if not r or not g or not b then return nil end
	return Color3.fromRGB(r, g, b)
end

local function relPos(frame: GuiObject): Vector2
	local m  = UserInputService:GetMouseLocation()
	local ap = frame.AbsolutePosition
	local as = frame.AbsoluteSize
	return Vector2.new(
		clamp01((m.X - ap.X) / as.X),
		clamp01((m.Y - ap.Y) / as.Y)
	)
end

-- ── Module ────────────────────────────────────────────────────────────────────

local ColorPicker = {} :: { __index: any }
ColorPicker.__index = ColorPicker

function ColorPicker.new(config: ColorPickerConfig): ColorPickerImpl
	local maid          = Maid.new()
	local showAlpha     = config.ShowAlpha == true
	local isEnabled     = config.Enabled ~= false
	local overlayParent = config.OverlayParent
	local windowCanvas  = (config :: any).Canvas :: Frame?
	local isOpen        = false

	local h, s, v, a = 0.0, 1.0, 1.0, 1.0
	if config.Default then
		h, s, v = Color3.toHSV(config.Default)
	end

	local changed = Signal.new()
	maid:GiveTask(changed)

	-- Resolved horizontal layout
	local hueX:   number = hueX_base
	local alphaX: number = alphaX_base
	local rightX: number = showAlpha and rightX_alpha or rightX_noAlpha
	local rightW: number = POPUP_W - rightX - PAD

	local hexW: number  = showAlpha
		and (rightW - ABOX_W - ABOX_GAP)
		or  rightW
	local aboxX: number = rightX + hexW + ABOX_GAP

	local PREVIEW_H = MAP_H - HEX_H - GAP_PH   -- 110px

	-- ── Outer container (36px, same frame as Button / Toggle) ─────────────────

	local root = Instance.new("Frame")
	root.Name  = "ColorPicker"
	root.Size  = UDim2.new(1, 0, 0, HEADER_H)
	root.BackgroundTransparency = 1
	root.BorderSizePixel        = 0
	root.LayoutOrder            = config.LayoutOrder or 0
	root.ClipsDescendants       = false
	maid:GiveTask(root)

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
	mkCorner(shadow, Theme.Radius.Small + 1)
	shadow.Parent = root

	-- ── Inner shell (gradient + stroke, same as Button) ───────────────────────

	local inner            = Instance.new("Frame")
	inner.Name             = "Inner"
	inner.AnchorPoint      = Vector2.new(0.5, 0.5)
	inner.Position         = UDim2.new(0.5, 0, 0.5, 0)
	inner.Size             = UDim2.new(1, 0, 1, 0)
	inner.BackgroundColor3 = Color3.new(1, 1, 1)
	inner.BorderSizePixel  = 0
	inner.ZIndex           = 2
	inner.Parent           = root

	local innerGrad    = Instance.new("UIGradient")
	innerGrad.Color    = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromHex("#2e2e2e")),
		ColorSequenceKeypoint.new(1, Color3.fromHex("#181818")),
	})
	innerGrad.Rotation = 90
	innerGrad.Parent   = inner

	mkCorner(inner, Theme.Radius.Small)

	local stroke = mkStroke(inner, Theme.Colors.Border, 1)

	local uiScale  = Instance.new("UIScale")
	uiScale.Scale  = 1
	uiScale.Parent = inner

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
	mkCorner(flash, Theme.Radius.Small)
	flash.Parent = inner

	-- ── Content: label (left) + pill + arrow (right) ──────────────────────────

	local labelText = Instance.new("TextLabel")
	labelText.AnchorPoint    = Vector2.new(0, 0.5)
	labelText.Position       = UDim2.new(0, 0, 0.5, 0)
	labelText.Size           = UDim2.new(1, -(PILL_W + 6), 1, 0)
	labelText.BackgroundTransparency = 1
	labelText.Font           = Theme.Font.Body
	labelText.Text           = config.Label
	labelText.TextSize       = Theme.TextSize.Body
	labelText.TextColor3     = config.Risky
		and Theme.Colors.Error
		or  Theme.Colors.TextPrimary
	labelText.TextXAlignment = Enum.TextXAlignment.Left
	labelText.TextTruncate   = Enum.TextTruncate.AtEnd
	labelText.ZIndex         = 4
	labelText.Parent         = inner

	local pill = Instance.new("Frame")
	pill.AnchorPoint      = Vector2.new(1, 0.5)
	pill.Position         = UDim2.new(1, 0, 0.5, 0)
	pill.Size             = UDim2.fromOffset(PILL_W, PILL_H)
	pill.BackgroundColor3 = Color3.fromHSV(h, s, v)
	pill.BackgroundTransparency = 0
	pill.BorderSizePixel  = 0
	pill.ZIndex           = 4
	mkCorner(pill, PILL_R)
	mkStroke(pill, Theme.Colors.Border, 1)
	pill.Parent = inner

	-- Full-row hit button (sits above everything inside inner)
	local btn = Instance.new("TextButton")
	btn.Name  = "Hit"
	btn.Size  = UDim2.fromScale(1, 1)
	btn.BackgroundTransparency = 1
	btn.Text  = ""
	btn.AutoButtonColor = false
	btn.ZIndex = 5
	btn.Parent = inner

	-- ── Container hover / press animations (identical to Button) ──────────────

	local pressing = false
	local hovering = false

	local function releasePress()
		if not pressing then return end
		pressing = false
		local shadowTarget = if hovering then SHADOW_HOVER else SHADOW_REST
		local flashTarget  = if hovering then 0.94 else 1
		TweenService:Create(inner,  TW_RELEASE, { Size = UDim2.new(1, 0, 1, 0) }):Play()
		TweenService:Create(flash,  TW_RELEASE, { BackgroundTransparency = flashTarget }):Play()
		TweenService:Create(shadow, TW_SHADOW,  {
			BackgroundTransparency = shadowTarget.BackgroundTransparency,
			Position               = shadowTarget.Position,
			Size                   = UDim2.new(1, 0, 1, 4),
		}):Play()
		TweenService:Create(stroke, TW_STROKE, {
			Color = if (hovering or isOpen) then Theme.Colors.Accent else Theme.Colors.Border,
		}):Play()
	end

	maid:GiveTask(btn.MouseEnter:Connect(function()
		if not isEnabled then return end
		hovering = true
		if not pressing then
			TweenService:Create(stroke, TW_STROKE, { Color = Theme.Colors.Accent }):Play()
			TweenService:Create(flash,  TW_HOVER,  { BackgroundTransparency = 0.94 }):Play()
			TweenService:Create(shadow, TW_SHADOW,  SHADOW_HOVER):Play()
			TweenService:Create(labelText, TW_HOVER, { TextColor3 = Theme.Colors.TextPrimary }):Play()
		end
	end))

	maid:GiveTask(btn.MouseLeave:Connect(function()
		if not isEnabled then return end
		hovering = false
		if pressing then
			releasePress()
		else
			TweenService:Create(stroke, TW_STROKE, {
				Color = if isOpen then Theme.Colors.Accent else Theme.Colors.Border,
			}):Play()
			TweenService:Create(flash,  TW_HOVER,  { BackgroundTransparency = 1 }):Play()
			TweenService:Create(shadow, TW_SHADOW,  SHADOW_REST):Play()
		end
	end))

	maid:GiveTask(btn.MouseButton1Down:Connect(function()
		if not isEnabled then return end
		pressing = true
		TweenService:Create(inner,  TW_PRESS, { Size = UDim2.new(1, -6, 1, -2) }):Play()
		TweenService:Create(flash,  TW_PRESS, { BackgroundTransparency = 0.82 }):Play()
		TweenService:Create(shadow, TW_PRESS, {
			BackgroundTransparency = SHADOW_PRESS.BackgroundTransparency,
			Position               = SHADOW_PRESS.Position,
			Size                   = UDim2.new(1, -6, 1, 2),
		}):Play()
		TweenService:Create(stroke, TW_PRESS, { Color = Theme.Colors.AccentHover }):Play()
	end))

	maid:GiveTask(btn.MouseButton1Up:Connect(function()
		if not isEnabled then return end
		releasePress()
	end))

	maid:GiveTask(UserInputService.InputEnded:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			releasePress()
		end
	end))

	-- ── Popup frame ───────────────────────────────────────────────────────────

	local popup = Instance.new("Frame")
	popup.Name  = "ColorPickerPopup"
	popup.Size  = UDim2.fromOffset(POPUP_W, POPUP_H)
	popup.BackgroundColor3 = Theme.Colors.Surface
	popup.BackgroundTransparency = 1
	popup.BorderSizePixel  = 0
	popup.ZIndex           = POPUP_Z
	popup.Visible          = false
	mkCorner(popup, Theme.Radius.Medium)
	mkStroke(popup, Theme.Colors.Border, 1)
	maid:GiveTask(popup)

	local popupScale  = Instance.new("UIScale")
	popupScale.Scale  = 1
	popupScale.Parent = popup

	-- In-popup click absorber (prevents backdrop from firing for clicks inside popup)
	local hitbox = Instance.new("TextButton")
	hitbox.Size  = UDim2.fromScale(1, 1)
	hitbox.BackgroundTransparency = 1
	hitbox.Text  = ""
	hitbox.AutoButtonColor = false
	hitbox.ZIndex = POPUP_Z
	hitbox.Parent = popup

	-- ── Popup title ───────────────────────────────────────────────────────────

	local popTitle = Instance.new("TextLabel")
	popTitle.Position = UDim2.fromOffset(PAD, 0)
	popTitle.Size     = UDim2.new(1, -PAD * 2, 0, TITLE_H)
	popTitle.BackgroundTransparency = 1
	popTitle.Font     = Theme.Font.Subtitle
	popTitle.Text     = config.Label
	popTitle.TextSize = Theme.TextSize.Body
	popTitle.TextColor3 = config.Risky
		and Theme.Colors.Error
		or  Theme.Colors.TextSecondary
	popTitle.TextXAlignment = Enum.TextXAlignment.Left
	popTitle.ZIndex   = POPUP_Z + 1
	popTitle.Parent   = popup

	-- ── SV canvas ─────────────────────────────────────────────────────────────

	local canvas = Instance.new("Frame")
	canvas.Name  = "Canvas"
	canvas.Position = UDim2.fromOffset(PAD, CONTENT_Y)
	canvas.Size     = UDim2.fromOffset(MAP_W, MAP_H)
	canvas.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
	canvas.BorderSizePixel  = 0
	canvas.ZIndex = POPUP_Z + 1
	mkCorner(canvas, Theme.Radius.Small + 2)
	mkStroke(canvas, Theme.Colors.Border, 1)
	canvas.Parent = popup

	-- Saturation overlay (white left → transparent right)
	local satOvl = Instance.new("Frame")
	satOvl.Size  = UDim2.fromScale(1, 1)
	satOvl.BackgroundColor3 = Color3.new(1, 1, 1)
	satOvl.BorderSizePixel  = 0
	satOvl.ZIndex = POPUP_Z + 2
	mkCorner(satOvl, Theme.Radius.Small + 2)
	do
		local g        = Instance.new("UIGradient")
		g.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(1, 1),
		})
		g.Parent = satOvl
	end
	satOvl.Parent = canvas

	-- Value overlay (transparent top → black bottom)
	local valOvl = Instance.new("Frame")
	valOvl.Size  = UDim2.fromScale(1, 1)
	valOvl.BackgroundColor3 = Color3.new(0, 0, 0)
	valOvl.BorderSizePixel  = 0
	valOvl.ZIndex = POPUP_Z + 3
	mkCorner(valOvl, Theme.Radius.Small + 2)
	do
		local g        = Instance.new("UIGradient")
		g.Rotation     = 90
		g.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(1, 0),
		})
		g.Parent = valOvl
	end
	valOvl.Parent = canvas

	-- SV cursor
	local satCursor = Instance.new("Frame")
	satCursor.Name  = "SatCursor"
	satCursor.AnchorPoint = Vector2.new(0.5, 0.5)
	satCursor.Size  = CURSOR_SIZE_REST
	satCursor.Position = UDim2.new(s, 0, 1 - v, 0)
	satCursor.BackgroundColor3 = Color3.fromHSV(h, s, v)
	satCursor.BorderSizePixel  = 0
	satCursor.ZIndex = POPUP_Z + 8
	mkCorner(satCursor, CURSOR_D // 2)
	do
		local cs = Instance.new("UIStroke")
		cs.Color = Color3.new(1, 1, 1)
		cs.Thickness = 2
		cs.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		cs.Parent = satCursor
	end
	satCursor.Parent = canvas

	-- Canvas hit button (above overlays, below cursor)
	local canvasBtn = Instance.new("TextButton")
	canvasBtn.BackgroundTransparency = 1
	canvasBtn.Size = UDim2.fromScale(1, 1)
	canvasBtn.Text = ""
	canvasBtn.AutoButtonColor = false
	canvasBtn.ZIndex = POPUP_Z + 7
	canvasBtn.Parent = canvas

	-- ── Hue strip (vertical) ──────────────────────────────────────────────────

	local hueBar = Instance.new("Frame")
	hueBar.Name  = "HueBar"
	hueBar.Position = UDim2.fromOffset(hueX, CONTENT_Y)
	hueBar.Size     = UDim2.fromOffset(HUE_W, MAP_H)
	hueBar.BackgroundColor3 = Color3.new(1, 1, 1)
	hueBar.BorderSizePixel  = 0
	hueBar.ZIndex = POPUP_Z + 1
	mkCorner(hueBar, HUE_W // 2)
	do
		local g    = Instance.new("UIGradient")
		g.Color    = HUE_CS
		g.Rotation = 90
		g.Parent   = hueBar
	end
	hueBar.Parent = popup

	local hueHandle = Instance.new("Frame")
	hueHandle.Name  = "HueHandle"
	hueHandle.AnchorPoint = Vector2.new(0.5, 0.5)
	hueHandle.Size  = HUE_HANDLE_SIZE_REST
	hueHandle.Position = UDim2.new(0.5, 0, h, 0)
	hueHandle.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
	hueHandle.BorderSizePixel  = 0
	hueHandle.ZIndex = POPUP_Z + 4
	mkCorner(hueHandle, HANDLE_H // 2)
	do
		local hs = Instance.new("UIStroke")
		hs.Color = Color3.new(1, 1, 1)
		hs.Thickness = 2
		hs.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		hs.Parent = hueHandle
	end
	hueHandle.Parent = hueBar

	local hueBtn = Instance.new("TextButton")
	hueBtn.BackgroundTransparency = 1
	hueBtn.AnchorPoint = Vector2.new(0.5, 0.5)
	hueBtn.Position    = UDim2.fromScale(0.5, 0.5)
	hueBtn.Size        = UDim2.new(1, 18, 1, 10)
	hueBtn.Text        = ""
	hueBtn.AutoButtonColor = false
	hueBtn.ZIndex = POPUP_Z + 6
	hueBtn.Parent = hueBar

	-- ── Alpha strip (vertical, optional) ──────────────────────────────────────

	local alphaBar:    Frame?      = nil
	local alphaHandle: Frame?      = nil
	local alphaBtn:    TextButton? = nil

	if showAlpha then
		local bar = Instance.new("Frame")
		bar.Name  = "AlphaBar"
		bar.Position = UDim2.fromOffset(alphaX, CONTENT_Y)
		bar.Size     = UDim2.fromOffset(ALPHA_W, MAP_H)
		bar.BackgroundColor3 = Color3.fromHSV(h, s, v)
		bar.BorderSizePixel  = 0
		bar.ZIndex = POPUP_Z + 1
		mkCorner(bar, ALPHA_W // 2)
		do
			local ag    = Instance.new("UIGradient")
			ag.Rotation = 90
			ag.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0),
				NumberSequenceKeypoint.new(1, 1),
			})
			ag.Parent = bar
		end
		bar.Parent = popup

		local handle = Instance.new("Frame")
		handle.Name  = "AlphaHandle"
		handle.AnchorPoint = Vector2.new(0.5, 0.5)
		handle.Size  = ALP_HANDLE_SIZE_REST
		handle.Position = UDim2.new(0.5, 0, 1 - a, 0)
		handle.BackgroundColor3 = Color3.fromHSV(h, s, v)
		handle.BorderSizePixel  = 0
		handle.ZIndex = POPUP_Z + 4
		mkCorner(handle, HANDLE_H // 2)
		do
			local as_ = Instance.new("UIStroke")
			as_.Color = Color3.new(1, 1, 1)
			as_.Thickness = 2
			as_.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			as_.Parent = handle
		end
		handle.Parent = bar

		local abtn = Instance.new("TextButton")
		abtn.BackgroundTransparency = 1
		abtn.AnchorPoint = Vector2.new(0.5, 0.5)
		abtn.Position    = UDim2.fromScale(0.5, 0.5)
		abtn.Size        = UDim2.new(1, 18, 1, 10)
		abtn.Text        = ""
		abtn.AutoButtonColor = false
		abtn.ZIndex = POPUP_Z + 6
		abtn.Parent = bar

		alphaBar    = bar
		alphaHandle = handle
		alphaBtn    = abtn
	end

	-- ── Preview swatch ────────────────────────────────────────────────────────

	local swatch = Instance.new("Frame")
	swatch.Name  = "Swatch"
	swatch.Position = UDim2.fromOffset(rightX, CONTENT_Y)
	swatch.Size     = UDim2.fromOffset(rightW, PREVIEW_H)
	swatch.BackgroundColor3 = Color3.fromHSV(h, s, v)
	swatch.BorderSizePixel  = 0
	swatch.ZIndex = POPUP_Z + 1
	mkCorner(swatch, Theme.Radius.Small + 2)
	mkStroke(swatch, Theme.Colors.Border, 1)
	swatch.Parent = popup

	-- ── Hex input ─────────────────────────────────────────────────────────────

	local hexY = CONTENT_Y + PREVIEW_H + GAP_PH

	local hexFrame = Instance.new("Frame")
	hexFrame.Name  = "HexFrame"
	hexFrame.Position = UDim2.fromOffset(rightX, hexY)
	hexFrame.Size     = UDim2.fromOffset(hexW, HEX_H)
	hexFrame.BackgroundColor3 = Theme.Colors.SurfaceHover
	hexFrame.BorderSizePixel  = 0
	hexFrame.ZIndex = POPUP_Z + 1
	mkCorner(hexFrame, Theme.Radius.Small)
	mkStroke(hexFrame, Theme.Colors.Border, 1)
	hexFrame.Parent = popup

	local hexInput = Instance.new("TextBox")
	hexInput.AnchorPoint = Vector2.new(0.5, 0.5)
	hexInput.Position    = UDim2.fromScale(0.5, 0.5)
	hexInput.Size        = UDim2.new(1, -8, 1, 0)
	hexInput.BackgroundTransparency = 1
	hexInput.Font        = Theme.Font.Mono
	hexInput.Text        = colorToHex(Color3.fromHSV(h, s, v))
	hexInput.PlaceholderText  = "#RRGGBB"
	hexInput.TextSize    = Theme.TextSize.Small
	hexInput.TextColor3  = Theme.Colors.TextPrimary
	hexInput.PlaceholderColor3 = Theme.Colors.TextSecondary
	hexInput.ClearTextOnFocus  = false
	hexInput.TextXAlignment    = Enum.TextXAlignment.Center
	hexInput.ZIndex = POPUP_Z + 2
	hexInput.Parent = hexFrame

	-- ── Alpha% input (optional) ────────────────────────────────────────────────

	local alphaInputFrame: Frame?   = nil
	local alphaInput:      TextBox? = nil

	if showAlpha then
		local af = Instance.new("Frame")
		af.Name  = "AlphaFrame"
		af.Position = UDim2.fromOffset(aboxX, hexY)
		af.Size     = UDim2.fromOffset(ABOX_W, HEX_H)
		af.BackgroundColor3 = Theme.Colors.SurfaceHover
		af.BorderSizePixel  = 0
		af.ZIndex = POPUP_Z + 1
		mkCorner(af, Theme.Radius.Small)
		mkStroke(af, Theme.Colors.Border, 1)
		af.Parent = popup

		local ai = Instance.new("TextBox")
		ai.AnchorPoint = Vector2.new(0.5, 0.5)
		ai.Position    = UDim2.fromScale(0.5, 0.5)
		ai.Size        = UDim2.new(1, -6, 1, 0)
		ai.BackgroundTransparency = 1
		ai.Font        = Theme.Font.Mono
		ai.Text        = "100%"
		ai.PlaceholderText = "100%"
		ai.TextSize    = Theme.TextSize.Small
		ai.TextColor3  = Theme.Colors.TextPrimary
		ai.PlaceholderColor3 = Theme.Colors.TextSecondary
		ai.ClearTextOnFocus  = false
		ai.TextXAlignment    = Enum.TextXAlignment.Center
		ai.ZIndex = POPUP_Z + 2
		ai.Parent = af

		alphaInputFrame = af
		alphaInput      = ai
	end

	-- ── Drag state ────────────────────────────────────────────────────────────

	type DragTarget = "canvas" | "hue" | "alpha"
	local dragging: DragTarget?          = nil
	local dragConn: RBXScriptConnection? = nil

	maid:GiveTask(function()
		if dragConn then dragConn:Disconnect(); dragConn = nil end
	end)

	-- ── Handle swell (Rayfield-inspired) ──────────────────────────────────────
	-- Swells the grabbed control on beginDrag, shrinks back on endDrag.

	local function setHeld(target: DragTarget?)
		local cursorSize = if target == "canvas" then CURSOR_SIZE_HELD else CURSOR_SIZE_REST
		local hueSize    = if target == "hue"    then HUE_HANDLE_SIZE_HELD else HUE_HANDLE_SIZE_REST
		local alphaSize  = if target == "alpha"  then ALP_HANDLE_SIZE_HELD else ALP_HANDLE_SIZE_REST

		TweenService:Create(satCursor,  TW_SWELL, { Size = cursorSize }):Play()
		TweenService:Create(hueHandle,  TW_SWELL, { Size = hueSize }):Play()
		if alphaHandle then
			TweenService:Create(alphaHandle, TW_SWELL, { Size = alphaSize }):Play()
		end
	end

	-- ── Refresh ───────────────────────────────────────────────────────────────
	-- "instant": snaps all UI (used for init or closed SetValue)
	-- "drag":    short tween while mouse is held
	-- "animate": longer ease for programmatic SetValue while popup is open

	local function refresh(mode: string?)
		local m     = mode or "drag"
		local color = Color3.fromHSV(h, s, v)
		local pure  = Color3.fromHSV(h, 1, 1)

		canvas.BackgroundColor3 = pure  -- always instant — just a color swap

		local ti = if m == "animate" then TW_SET else TW_DRAG

		if m == "instant" then
			satCursor.Position         = UDim2.new(s, 0, 1 - v, 0)
			satCursor.BackgroundColor3 = color
			hueHandle.Position         = UDim2.new(0.5, 0, h, 0)
			hueHandle.BackgroundColor3 = pure
			pill.BackgroundColor3      = color
			pill.BackgroundTransparency = 1 - a
			swatch.BackgroundColor3    = color
			if showAlpha and alphaBar and alphaHandle then
				alphaBar.BackgroundColor3    = color
				alphaHandle.Position         = UDim2.new(0.5, 0, 1 - a, 0)
				alphaHandle.BackgroundColor3 = color
			end
		else
			TweenService:Create(satCursor, ti, {
				Position         = UDim2.new(s, 0, 1 - v, 0),
				BackgroundColor3 = color,
			}):Play()
			TweenService:Create(hueHandle, ti, {
				Position         = UDim2.new(0.5, 0, h, 0),
				BackgroundColor3 = pure,
			}):Play()
			TweenService:Create(pill,   ti, { BackgroundColor3 = color, BackgroundTransparency = 1 - a }):Play()
			TweenService:Create(swatch, ti, { BackgroundColor3 = color }):Play()
			if showAlpha and alphaBar and alphaHandle then
				TweenService:Create(alphaBar, ti, { BackgroundColor3 = color }):Play()
				TweenService:Create(alphaHandle, ti, {
					Position         = UDim2.new(0.5, 0, 1 - a, 0),
					BackgroundColor3 = color,
				}):Play()
			end
		end

		if not hexInput:IsFocused() then
			hexInput.Text = colorToHex(color)
		end
		if showAlpha and alphaInput and not alphaInput:IsFocused() then
			alphaInput.Text = tostring(math.round(a * 100)) .. "%"
		end
	end

	-- Lightweight pill-only update (when popup is closed and we just need the header chip)
	local function refreshPill()
		pill.BackgroundColor3      = Color3.fromHSV(h, s, v)
		pill.BackgroundTransparency = 1 - a
	end

	local function fireChanged()
		changed:Fire(Color3.fromHSV(h, s, v), a)
		if config.Flag then
			SaveManager._scheduleAutoSave()
		end
	end

	-- ── Drag pump ─────────────────────────────────────────────────────────────

	local function pump()
		if dragging == "canvas" then
			local p = relPos(canvas)
			s, v = p.X, 1 - p.Y
		elseif dragging == "hue" then
			h = relPos(hueBar).Y
		elseif dragging == "alpha" and alphaBar then
			a = 1 - relPos(alphaBar).Y
		end
		refresh("drag")
		fireChanged()
	end

	local function beginDrag(target: DragTarget)
		if not isEnabled then return end
		dragging = target
		setHeld(target)
		pump()
		if dragConn then dragConn:Disconnect() end
		dragConn = RunService.RenderStepped:Connect(function()
			if not dragging then
				dragConn:Disconnect(); dragConn = nil
				return
			end
			if not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
				dragging = nil
				setHeld(nil)
				dragConn:Disconnect(); dragConn = nil
				return
			end
			pump()
		end)
	end

	maid:GiveTask(UserInputService.InputEnded:Connect(function(input: InputObject)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch then return end
		if dragging then
			dragging = nil
			setHeld(nil)
			if dragConn then dragConn:Disconnect(); dragConn = nil end
		end
	end))

	-- ── Drag input bindings ───────────────────────────────────────────────────

	maid:GiveTask(canvasBtn.InputBegan:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			beginDrag("canvas")
		end
	end))

	maid:GiveTask(hueBtn.InputBegan:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			beginDrag("hue")
		end
	end))

	if showAlpha and alphaBtn then
		local abtn = alphaBtn :: TextButton
		maid:GiveTask(abtn.InputBegan:Connect(function(input: InputObject)
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch then
				beginDrag("alpha")
			end
		end))
	end

	-- ── Hex / Alpha text input ────────────────────────────────────────────────

	maid:GiveTask(hexInput.FocusLost:Connect(function()
		local color = hexToColor(hexInput.Text)
		if not color then
			hexInput.Text = colorToHex(Color3.fromHSV(h, s, v))
			return
		end
		h, s, v = Color3.toHSV(color)
		refresh("animate")
		fireChanged()
	end))

	if showAlpha and alphaInput then
		local ai = alphaInput :: TextBox
		maid:GiveTask(ai.FocusLost:Connect(function()
			local n = tonumber((ai.Text:gsub("[^%d%.]", "")))
			if n then
				a = clamp01(n / 100)
				refresh("animate")
				fireChanged()
			else
				ai.Text = tostring(math.round(a * 100)) .. "%"
			end
		end))
	end

	-- ── Popup open / close ────────────────────────────────────────────────────

	local popMaid   = Maid.new()
	local backdrop: TextButton? = nil
	local dim:      Frame?      = nil
	maid:GiveTask(popMaid)

	-- Leak guard: destroyed while popup open
	maid:GiveTask(function()
		if backdrop then backdrop:Destroy(); backdrop = nil end
		if dim then dim:Destroy(); dim = nil end
		if windowCanvas then
			pcall(function() (windowCanvas :: any).Interactable = true end)
		end
		SmoothScroll.setPaused(false)
	end)

	local function closePopup()
		if not isOpen then return end
		isOpen = false

		-- Stroke back to rest
		if not hovering then
			TweenService:Create(stroke, TW_STROKE, { Color = Theme.Colors.Border }):Play()
		end

		local capturedDim      = dim;      dim      = nil
		local capturedBackdrop = backdrop; backdrop = nil

		if windowCanvas then
			pcall(function() (windowCanvas :: any).Interactable = true end)
		end
		SmoothScroll.setPaused(false)

		if capturedDim then
			TweenService:Create(capturedDim, TW_DIM_OUT, { BackgroundTransparency = 1 }):Play()
			task.delay(TW_DIM_OUT.Time + 0.02, function()
				if capturedDim.Parent then capturedDim:Destroy() end
			end)
		end
		if capturedBackdrop then
			capturedBackdrop:Destroy()
		end

		TweenService:Create(popupScale, TW_CLOSE, { Scale = 0.90 }):Play()
		TweenService:Create(popup, TW_CLOSE, { BackgroundTransparency = 1 }):Play()
		task.delay(TW_CLOSE.Time + 0.02, function()
			popup.Visible = false
			popup.Parent  = nil
		end)

		popMaid:DoCleaning()
	end

	local function openPopup()
		if not isEnabled or isOpen then return end
		if not overlayParent then return end
		isOpen = true

		-- Keep accent stroke while open
		TweenService:Create(stroke, TW_STROKE, { Color = Theme.Colors.Accent }):Play()
		if windowCanvas and windowCanvas.Parent then
			local d                  = Instance.new("Frame")
			d.Name                   = "ColorPickerDim"
			d.Size                   = UDim2.fromScale(1, 1)
			d.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
			d.BackgroundTransparency = 1
			d.BorderSizePixel        = 0
			d.ZIndex                 = 3
			d.Parent                 = windowCanvas.Parent
			dim                      = d
			TweenService:Create(d, TW_DIM_IN, { BackgroundTransparency = DIM_TRANSPARENCY }):Play()
			pcall(function() (windowCanvas :: any).Interactable = false end)
			SmoothScroll.setPaused(true)
		end

		-- Center in the overlay parent; clamp to screen on mobile
		local screenW = overlayParent.AbsoluteSize.X
		local screenH = overlayParent.AbsoluteSize.Y
		local pw = math.min(POPUP_W, screenW - 16)
		local ph = POPUP_H
		popup.Size = UDim2.fromOffset(pw, ph)
		-- Re-center after size change so it stays in bounds
		local cx = math.clamp(screenW / 2, pw / 2 + 8, screenW - pw / 2 - 8)
		local cy = math.clamp(screenH / 2, ph / 2 + 8, screenH - ph / 2 - 8)
		popup.AnchorPoint            = Vector2.new(0.5, 0.5)
		popup.Position               = UDim2.fromOffset(cx, cy)
		popup.BackgroundTransparency = 1
		popupScale.Scale             = 0.88
		popup.Visible                = true
		popup.Parent                 = overlayParent

		TweenService:Create(popupScale, TW_OPEN, { Scale = 1 }):Play()
		TweenService:Create(popup, TW_OPEN, { BackgroundTransparency = 0 }):Play()

		local bd                      = Instance.new("TextButton")
		bd.Name                       = "ColorPickerBackdrop"
		bd.Size                       = UDim2.fromScale(1, 1)
		bd.BackgroundColor3           = Color3.fromRGB(0, 0, 0)
		bd.BackgroundTransparency     = 1
		bd.Text                       = ""
		bd.AutoButtonColor            = false
		bd.ZIndex                     = POPUP_Z - 1
		bd.Active                     = true
		bd.Parent                     = overlayParent
		backdrop                      = bd

		popMaid:GiveTask(bd.MouseButton1Click:Connect(function()
			closePopup()
		end))
	end

	-- Wire the header button to open / close
	maid:GiveTask(btn.MouseButton1Click:Connect(function()
		if isOpen then
			closePopup()
		else
			openPopup()
		end
	end))

	-- ── Public API ────────────────────────────────────────────────────────────

	local impl = setmetatable({}, ColorPicker) :: ColorPickerImpl
	impl.Changed = changed

	function impl:SetValue(color: Color3, alpha: number?)
		h, s, v = Color3.toHSV(color)
		if alpha ~= nil then a = clamp01(alpha) end
		if isOpen then
			refresh("animate")
		else
			refresh("instant")
		end
	end

	function impl:SetEnabled(enabled: boolean)
		isEnabled = enabled
		labelText.TextColor3 = not enabled
			and Theme.Colors.TextDisabled
			or (config.Risky and Theme.Colors.Error or Theme.Colors.TextPrimary)
		stroke.Color = not enabled
			and Theme.Colors.Border
			or stroke.Color
		stroke.Transparency = if enabled then 0 else 0.5
	end

	function impl:GetFrame(): Frame
		return root
	end

	function impl:Destroy()
		maid:DoCleaning()
	end

	-- ── SaveManager ───────────────────────────────────────────────────────────

	if config.Flag and #config.Flag > 0 then
		SaveManager.Register(
			config.Flag,
			function(): any
				local c = Color3.fromHSV(h, s, v)
				return { r = c.R, g = c.G, b = c.B, a = a }
			end,
			function(val: any)
				if type(val) ~= "table" then return end
				local nr = clamp01(tonumber(val.r) or 0)
				local ng = clamp01(tonumber(val.g) or 0)
				local nb = clamp01(tonumber(val.b) or 0)
				local na = clamp01(tonumber(val.a) or 1)
				h, s, v = Color3.toHSV(Color3.new(nr, ng, nb))
				a = na
				refresh("instant")
			end
		)
	end

	refresh("instant")
	return impl
end

return ColorPicker

end)() end,
    function()local wax,script,require=ImportGlobals(5)local ImportGlobals return (function(...)--!strict

local Theme = require(script.Parent.Parent.Theme)

export type DescriptionConfig = {
	Title:       string?,
	Description: string,
	LayoutOrder: number?,
}

type DescriptionImpl = {
	SetTitle:       (self: DescriptionImpl, text: string)  -> (),
	SetDescription: (self: DescriptionImpl, text: string)  -> (),
	GetFrame:       (self: DescriptionImpl)                -> Frame,
	Destroy:        (self: DescriptionImpl)                -> (),
	_frame:  Frame,
	_title:  TextLabel,
	_body:   TextLabel,
}

local Description = {} :: { __index: any }
Description.__index = Description

function Description.new(config: DescriptionConfig): DescriptionImpl
	local self = setmetatable({}, Description) :: DescriptionImpl

	-- Root container — height driven by children
	local frame                  = Instance.new("Frame")
	frame.Name                   = "Description"
	frame.AutomaticSize          = Enum.AutomaticSize.Y
	frame.Size                   = UDim2.new(1, 0, 0, 0)
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel        = 0
	frame.LayoutOrder            = config.LayoutOrder or 0
	self._frame                  = frame

	local pad            = Instance.new("UIPadding")
	pad.PaddingLeft      = UDim.new(0, Theme.Spacing.M)
	pad.PaddingRight     = UDim.new(0, Theme.Spacing.M)
	pad.PaddingTop       = UDim.new(0, Theme.Spacing.XS)
	pad.Parent           = frame

	local layout               = Instance.new("UIListLayout")
	layout.FillDirection       = Enum.FillDirection.Vertical
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	layout.SortOrder           = Enum.SortOrder.LayoutOrder
	layout.Padding             = UDim.new(0, Theme.Spacing.XS)
	layout.Parent              = frame

	-- Optional title row
	local hasTitle = config.Title ~= nil and config.Title ~= ""

	local titleLabel                  = Instance.new("TextLabel")
	titleLabel.Name                   = "Title"
	titleLabel.LayoutOrder            = 0
	titleLabel.AutomaticSize          = Enum.AutomaticSize.Y
	titleLabel.Size                   = UDim2.new(1, 0, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font                   = Theme.Font.Subtitle
	titleLabel.Text                   = config.Title or ""
	titleLabel.TextSize               = Theme.TextSize.Subtitle
	titleLabel.TextColor3             = Theme.Colors.TextPrimary
	titleLabel.TextXAlignment         = Enum.TextXAlignment.Left
	titleLabel.TextWrapped            = true
	titleLabel.Visible                = hasTitle
	titleLabel.Parent                 = frame
	self._title                       = titleLabel

	-- Description body
	local bodyLabel                   = Instance.new("TextLabel")
	bodyLabel.Name                    = "Body"
	bodyLabel.LayoutOrder             = 1
	bodyLabel.AutomaticSize           = Enum.AutomaticSize.Y
	bodyLabel.Size                    = UDim2.new(1, 0, 0, 0)
	bodyLabel.BackgroundTransparency  = 1
	bodyLabel.Font                    = Theme.Font.Body
	bodyLabel.Text                    = config.Description
	bodyLabel.TextSize                = Theme.TextSize.Small
	bodyLabel.TextColor3              = Theme.Colors.TextSecondary
	bodyLabel.TextXAlignment          = Enum.TextXAlignment.Left
	bodyLabel.TextWrapped             = true
	bodyLabel.RichText                = true
	bodyLabel.Parent                  = frame
	self._body                        = bodyLabel

	-- Bottom spacer so content below has breathing room
	local spacer             = Instance.new("Frame")
	spacer.Name              = "Spacer"
	spacer.LayoutOrder       = 2
	spacer.BackgroundTransparency = 1
	spacer.BorderSizePixel   = 0
	spacer.Size              = UDim2.fromOffset(0, Theme.Spacing.XL)
	spacer.Parent            = frame

	return self
end

function Description:SetTitle(text: string)
	self._title.Text    = text
	self._title.Visible = text ~= ""
end

function Description:SetDescription(text: string)
	self._body.Text = text
end

function Description:GetFrame(): Frame
	return self._frame
end

function Description:Destroy()
	if self._frame and self._frame.Parent then
		self._frame:Destroy()
	end
end

return Description

end)() end,
    function()local wax,script,require=ImportGlobals(6)local ImportGlobals return (function(...)--!strict

local Theme = require(script.Parent.Parent.Theme)

export type DividerConfig = {
	Text: string?,
	LayoutOrder: number?,
}

type DividerImpl = {
	GetFrame: (self: DividerImpl) -> Frame,
	Destroy: (self: DividerImpl) -> (),
	_frame: Frame,
}

local Divider = {} :: { __index: any }
Divider.__index = Divider

function Divider.new(config: DividerConfig?): DividerImpl
	local cfg   = config or {}
	local self  = setmetatable({}, Divider) :: DividerImpl

	local frame              = Instance.new("Frame")
	frame.Name               = "Divider"
	frame.Size               = UDim2.new(1, 0, 0, 20)
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel    = 0
	frame.LayoutOrder        = cfg.LayoutOrder or 0
	self._frame              = frame

	local pad        = Instance.new("UIPadding")
	pad.PaddingLeft  = UDim.new(0, Theme.Spacing.M)
	pad.PaddingRight = UDim.new(0, Theme.Spacing.M)
	pad.Parent       = frame

	-- Horizontal rule — always full width, vertically centered
	local line             = Instance.new("Frame")
	line.Name              = "Line"
	line.Size              = UDim2.new(1, 0, 0, 1)
	line.Position          = UDim2.fromScale(0, 0.5)
	line.BackgroundColor3  = Theme.Colors.Border
	line.BorderSizePixel   = 0
	line.Parent            = frame

	local text = cfg.Text
	if text and #text > 0 then
		local lbl                    = Instance.new("TextLabel")
		lbl.Name                     = "Text"
		lbl.AutomaticSize            = Enum.AutomaticSize.X
		lbl.Size                     = UDim2.new(0, 0, 1, 0)
		lbl.AnchorPoint              = Vector2.new(0.5, 0)
		lbl.Position                 = UDim2.fromScale(0.5, 0)
		lbl.BackgroundColor3         = Theme.Colors.Surface
		lbl.BorderSizePixel          = 0
		lbl.Font                     = Theme.Font.Body
		lbl.Text                     = text
		lbl.TextSize                 = Theme.TextSize.Small
		lbl.TextColor3               = Theme.Colors.TextSecondary
		local textPad                = Instance.new("UIPadding")
		textPad.PaddingLeft          = UDim.new(0, Theme.Spacing.XS)
		textPad.PaddingRight         = UDim.new(0, Theme.Spacing.XS)
		textPad.Parent               = lbl
		lbl.Parent                   = frame
	end

	return self
end

function Divider:GetFrame(): Frame
	return self._frame
end

function Divider:Destroy()
	if self._frame and self._frame.Parent then
		self._frame:Destroy()
	end
end

return Divider

end)() end,
    function()local wax,script,require=ImportGlobals(7)local ImportGlobals return (function(...)--!strict

local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Maid         = require(script.Parent.Parent.Utils.Maid)
local Signal       = require(script.Parent.Parent.Utils.Signal)
local Theme        = require(script.Parent.Parent.Theme)
local SmoothScroll = require(script.Parent.Parent.Utils.SmoothScroll)
local SaveManager  = require(script.Parent.Parent.Core.SaveManager)

local TWEEN_STROKE   = TweenInfo.new(0.25, Enum.EasingStyle.Quint,       Enum.EasingDirection.Out)
local TWEEN_HOVER    = TweenInfo.new(0.2,  Enum.EasingStyle.Quint,       Enum.EasingDirection.Out)
local TWEEN_EXPAND   = TweenInfo.new(0.5,  Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
local TWEEN_COLLAPSE = TweenInfo.new(0.45, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
local TWEEN_ARROW    = TweenInfo.new(0.65, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
local TWEEN_FADE     = TweenInfo.new(0.35, Enum.EasingStyle.Quint,       Enum.EasingDirection.Out)

local SD_REST  = { BackgroundTransparency = 0.75, Position = UDim2.new(0.5, 0, 0, 3) }
local SD_HOVER = { BackgroundTransparency = 0.65, Position = UDim2.new(0.5, 0, 0, 5) }

local HEADER_H = 36
local LIST_GAP = 4
local OPTION_H = 32
local MAX_H    = 160
local CHECK_W  = 20  -- width reserved for checkmark column in multiSelect

-- ── Option normalisation ──────────────────────────────────────────────────────
-- Accepts either plain strings or { Label, Value } tables.

export type DropdownOption = { Label: string, Value: any }

local function normalizeOptions(raw: { any }): { DropdownOption }
	local out: { DropdownOption } = {}
	for _, v in ipairs(raw) do
		if typeof(v) == "string" then
			table.insert(out, { Label = v, Value = v })
		else
			-- assume already {Label, Value}
			table.insert(out, v :: DropdownOption)
		end
	end
	return out
end

-- Default can be a single value or an array; always normalise to array internally.
local function normalizeDefault(raw: any): { any }
	if raw == nil then return {} end
	if typeof(raw) == "table" then return raw end
	return { raw }
end

export type DropdownConfig = {
	-- display
	Label:       string?,
	Placeholder: string?,
	Enabled:     boolean?,
	LayoutOrder: number?,
	-- options: plain string array OR {Label,Value} table array
	Options:     { any },
	-- multi-select
	MultiSelect: boolean?,
	-- initial selection: single value OR array of values
	Default:     any?,
	-- overlay parent required for z-ordering if inside a ScrollingFrame
	OverlayParent: Instance?,
	Flag: string?,
}

type DropdownImpl = {
	-- public state
	Value:   any,   -- single select: any; multi: { any }
	Changed: any,
	-- methods
	SetOptions: (self: DropdownImpl, options: { any }) -> (),
	SetValue:   (self: DropdownImpl, value: any)       -> (),
	SetEnabled: (self: DropdownImpl, enabled: boolean) -> (),
	GetFrame:   (self: DropdownImpl)                   -> Frame,
	Destroy:    (self: DropdownImpl)                   -> (),
	-- internals
	_maid:          any,
	_optionMaid:    any,
	_frame:         Frame,
	_inner:         Frame,
	_listWrap:      Frame,
	_listStroke:    UIStroke,
	_scroll:        ScrollingFrame,
	_outerLabel:    TextLabel?,
	_valueLabel:    TextLabel,
	_arrow:         TextLabel,
	_stroke:        UIStroke,
	_flash:         Frame,
	_shadow:        Frame,
	_enabled:       boolean,
	_open:          boolean,
	_multiSelect:   boolean,
	_options:       { DropdownOption },
	_selectedSet:   { [any]: boolean },  -- multi: set of selected values
	_selectedValue: any,                  -- single: current value
	_targetH:       number,
	_placeholder:   string,
}

local Dropdown = {} :: { __index: any }
Dropdown.__index = Dropdown

-- ── helpers ───────────────────────────────────────────────────────────────────

local function isInsideFrame(frame: GuiObject, pos: Vector2): boolean
	local ap = frame.AbsolutePosition
	local as = frame.AbsoluteSize
	return pos.X >= ap.X and pos.X <= ap.X + as.X
		and pos.Y >= ap.Y and pos.Y <= ap.Y + as.Y
end

-- Build the text shown in the header value label.
local function headerText(
	self: DropdownImpl
): (string, boolean)  -- text, hasSelection
	if self._multiSelect then
		local labels: { string } = {}
		for _, opt in ipairs(self._options) do
			if self._selectedSet[opt.Value] then
				table.insert(labels, opt.Label)
			end
		end
		if #labels == 0 then return self._placeholder, false end
		return table.concat(labels, ", "), true
	else
		if self._selectedValue == nil then return self._placeholder, false end
		for _, opt in ipairs(self._options) do
			if opt.Value == self._selectedValue then
				return opt.Label, true
			end
		end
		return self._placeholder, false
	end
end

-- ── constructor ───────────────────────────────────────────────────────────────

function Dropdown.new(config: DropdownConfig): DropdownImpl
	local self           = setmetatable({}, Dropdown) :: DropdownImpl
	self._maid           = Maid.new()
	self._optionMaid     = Maid.new()
	self._enabled        = if config.Enabled ~= nil then config.Enabled else true
	self._open           = false
	self._multiSelect    = if config.MultiSelect ~= nil then config.MultiSelect else false
	self._options        = normalizeOptions(config.Options or {})
	self._placeholder    = config.Placeholder or (if self._multiSelect then "None selected" else "Select...")

	-- Initialise selection state
	local defaults = normalizeDefault(config.Default)
	self._selectedSet   = {}
	self._selectedValue = nil

	if self._multiSelect then
		for _, v in ipairs(defaults) do
			self._selectedSet[v] = true
		end
		self.Value = defaults  -- expose array
	else
		self._selectedValue = if #defaults > 0 then defaults[1] else nil
		self.Value          = self._selectedValue
	end

	local hasLabel = config.Label ~= nil and #(config.Label :: string) > 0
	local LABEL_W  = 90
	local leftPad  = if hasLabel then LABEL_W + Theme.Spacing.M else Theme.Spacing.M

	-- ── outer container ───────────────────────────────────────────────────────
	local frame                  = Instance.new("Frame")
	frame.Name                   = "Dropdown"
	frame.Size                   = UDim2.new(1, 0, 0, HEADER_H)
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel        = 0
	frame.LayoutOrder            = config.LayoutOrder or 0
	frame.ClipsDescendants       = false
	self._frame                  = frame

	-- shadow
	local shadow                  = Instance.new("Frame")
	shadow.Name                   = "Shadow"
	shadow.AnchorPoint            = Vector2.new(0.5, 0)
	shadow.Position               = SD_REST.Position
	shadow.Size                   = UDim2.new(1, 0, 0, HEADER_H + 4)
	shadow.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
	shadow.BackgroundTransparency = SD_REST.BackgroundTransparency
	shadow.BorderSizePixel        = 0
	shadow.ZIndex                 = 1
	local shadowCorner            = Instance.new("UICorner")
	shadowCorner.CornerRadius     = UDim.new(0, Theme.Radius.Small + 1)
	shadowCorner.Parent           = shadow
	shadow.Parent                 = frame
	self._shadow                  = shadow

	-- header
	local inner            = Instance.new("Frame")
	inner.Name             = "Inner"
	inner.AnchorPoint      = Vector2.new(0.5, 0)
	inner.Position         = UDim2.new(0.5, 0, 0, 0)
	inner.Size             = UDim2.new(1, 0, 0, HEADER_H)
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

	local pad        = Instance.new("UIPadding")
	pad.PaddingLeft  = UDim.new(0, leftPad)
	pad.PaddingRight = UDim.new(0, Theme.Spacing.M)
	pad.Parent       = inner

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

	local ARROW_W = 16
	local arrow                  = Instance.new("TextLabel")
	arrow.Name                   = "Arrow"
	arrow.AnchorPoint            = Vector2.new(1, 0.5)
	arrow.Position               = UDim2.new(1, 0, 0.5, 0)
	arrow.Size                   = UDim2.fromOffset(ARROW_W, HEADER_H)
	arrow.BackgroundTransparency = 1
	arrow.Font                   = Enum.Font.GothamBold
	arrow.Text                   = "^"
	arrow.TextSize               = 12
	arrow.TextColor3             = Theme.Colors.TextSecondary
	arrow.TextXAlignment         = Enum.TextXAlignment.Center
	arrow.Rotation               = 0
	arrow.ZIndex                 = 4
	arrow.Parent                 = inner
	self._arrow                  = arrow

	-- header value text
	local initText, initHas    = headerText(self)
	local valueLabel                  = Instance.new("TextLabel")
	valueLabel.Name                   = "ValueLabel"
	valueLabel.Size                   = UDim2.new(1, -(ARROW_W + 4), 1, 0)
	valueLabel.BackgroundTransparency = 1
	valueLabel.Font                   = Theme.Font.Body
	valueLabel.Text                   = initText
	valueLabel.TextSize               = Theme.TextSize.Body
	valueLabel.TextColor3             = if initHas
		then Theme.Colors.TextPrimary
		else Theme.Colors.TextDisabled
	valueLabel.TextXAlignment         = Enum.TextXAlignment.Right
	valueLabel.TextTruncate           = Enum.TextTruncate.AtEnd
	valueLabel.ZIndex                 = 4
	valueLabel.Parent                 = inner
	self._valueLabel                  = valueLabel

	-- optional left label
	if hasLabel then
		local outerLabel                  = Instance.new("TextLabel")
		outerLabel.Name                   = "Label"
		outerLabel.Position               = UDim2.fromOffset(Theme.Spacing.M, 0)
		outerLabel.Size                   = UDim2.fromOffset(LABEL_W, HEADER_H)
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

	local hit                  = Instance.new("TextButton")
	hit.Name                   = "Hit"
	hit.Size                   = UDim2.fromScale(1, 1)
	hit.BackgroundTransparency = 1
	hit.Text                   = ""
	hit.AutoButtonColor        = false
	hit.ZIndex                 = 5
	hit.Parent                 = inner

	-- ── list container ────────────────────────────────────────────────────────
	local listWrap                  = Instance.new("Frame")
	listWrap.Name                   = "ListWrap"
	listWrap.Position               = UDim2.new(0, 0, 0, HEADER_H + LIST_GAP)
	listWrap.Size                   = UDim2.new(1, 0, 0, 0)
	listWrap.BackgroundColor3       = Color3.fromHex("#1a1a1a")
	listWrap.BackgroundTransparency = 1
	listWrap.BorderSizePixel        = 0
	listWrap.ClipsDescendants       = true
	listWrap.ZIndex                 = 2
	local listCorner                = Instance.new("UICorner")
	listCorner.CornerRadius         = UDim.new(0, Theme.Radius.Small)
	listCorner.Parent               = listWrap
	local listStroke                = Instance.new("UIStroke")
	listStroke.Color                = Theme.Colors.Border
	listStroke.Thickness            = 1
	listStroke.Transparency         = 1
	listStroke.ApplyStrokeMode      = Enum.ApplyStrokeMode.Border
	listStroke.Parent               = listWrap
	listWrap.Parent                 = frame
	self._listWrap                  = listWrap
	self._listStroke                = listStroke

	local scroll                   = Instance.new("ScrollingFrame")
	scroll.Name                    = "OptionScroll"
	scroll.Size                    = UDim2.fromScale(1, 1)
	scroll.BackgroundTransparency  = 1
	scroll.BorderSizePixel         = 0
	scroll.ScrollBarThickness      = 3
	scroll.ScrollBarImageColor3    = Theme.Colors.Border
	scroll.CanvasSize              = UDim2.fromOffset(0, 0)
	scroll.AutomaticCanvasSize     = Enum.AutomaticSize.None
	scroll.ClipsDescendants        = true
	scroll.ZIndex                  = 3
	scroll.Parent                  = listWrap
	self._scroll                   = scroll
	self._maid:GiveTask(SmoothScroll.apply(scroll))

	local listLayout         = Instance.new("UIListLayout")
	listLayout.FillDirection = Enum.FillDirection.Vertical
	listLayout.SortOrder     = Enum.SortOrder.LayoutOrder
	listLayout.Padding       = UDim.new(0, 0)
	listLayout.Parent        = scroll

	-- ── Signal ────────────────────────────────────────────────────────────────
	local changed = Signal.new()
	self.Changed  = changed
	self._maid:GiveTask(changed)
	self._maid:GiveTask(self._optionMaid)

	-- ── open / close ──────────────────────────────────────────────────────────
	local function closeDropdown()
		if not self._open then return end
		self._open = false
		TweenService:Create(arrow,      TWEEN_ARROW,    { Rotation = 0 }):Play()
		TweenService:Create(stroke,     TWEEN_STROKE,   { Color = Theme.Colors.Border }):Play()
		TweenService:Create(listWrap,   TWEEN_COLLAPSE, { Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1 }):Play()
		TweenService:Create(listStroke, TWEEN_FADE,     { Transparency = 1 }):Play()
		TweenService:Create(frame,      TWEEN_COLLAPSE, { Size = UDim2.new(1, 0, 0, HEADER_H) }):Play()
	end

	local function openDropdown()
		if self._open or not self._enabled then return end
		self._open = true
		TweenService:Create(arrow,      TWEEN_ARROW,   { Rotation = -180 }):Play()
		TweenService:Create(stroke,     TWEEN_STROKE,  { Color = Theme.Colors.Accent }):Play()
		TweenService:Create(listWrap,   TWEEN_EXPAND,  { Size = UDim2.new(1, 0, 0, self._targetH), BackgroundTransparency = 0 }):Play()
		TweenService:Create(listStroke, TWEEN_FADE,    { Transparency = 0 }):Play()
		TweenService:Create(frame,      TWEEN_EXPAND,  { Size = UDim2.new(1, 0, 0, HEADER_H + LIST_GAP + self._targetH) }):Play()
	end

	-- Store references so buildOptions closure can reach them
	self._openDropdown  = openDropdown
	self._closeDropdown = closeDropdown

	-- ── build option rows (internal) ──────────────────────────────────────────
	local function buildOptions()
		self._optionMaid:DoCleaning()
		for _, child in ipairs(scroll:GetChildren()) do
			if child:IsA("Frame") then child:Destroy() end
		end

		local optCount = #self._options
		local fullH    = optCount * OPTION_H
		scroll.CanvasSize = UDim2.fromOffset(0, fullH)
		self._targetH  = math.min(fullH, MAX_H)

		for i, opt in ipairs(self._options) do
			local isSelected = if self._multiSelect
				then self._selectedSet[opt.Value] == true
				else self._selectedValue == opt.Value

			local optFrame                  = Instance.new("Frame")
			optFrame.Name                   = "Option_" .. i
			optFrame.Size                   = UDim2.new(1, 0, 0, OPTION_H)
			optFrame.BackgroundColor3       = Color3.fromHex("#1a1a1a")
			optFrame.BackgroundTransparency = 1
			optFrame.BorderSizePixel        = 0
			optFrame.LayoutOrder            = i
			optFrame.ZIndex                 = 3

			-- Checkmark column (multiSelect only)
			local checkLabel: TextLabel? = nil
			if self._multiSelect then
				local ck                  = Instance.new("TextLabel")
				ck.Name                   = "Check"
				ck.Size                   = UDim2.fromOffset(CHECK_W, OPTION_H)
				ck.Position               = UDim2.fromOffset(Theme.Spacing.XS, 0)
				ck.BackgroundTransparency = 1
				ck.Font                   = Enum.Font.GothamBold
				ck.Text                   = if isSelected then "✓" else ""
				ck.TextSize               = 11
				ck.TextColor3             = Theme.Colors.Accent
				ck.TextXAlignment         = Enum.TextXAlignment.Center
				ck.ZIndex                 = 4
				ck.Parent                 = optFrame
				checkLabel                = ck
			end

			local labelXOffset = if self._multiSelect then CHECK_W + Theme.Spacing.XS else Theme.Spacing.M
			local labelWOffset = if self._multiSelect then -(CHECK_W + Theme.Spacing.XS + Theme.Spacing.M) else -(Theme.Spacing.M * 2)

			local optLabel                  = Instance.new("TextLabel")
			optLabel.Name                   = "OptionLabel"
			optLabel.Size                   = UDim2.new(1, labelWOffset, 1, 0)
			optLabel.Position               = UDim2.fromOffset(labelXOffset, 0)
			optLabel.BackgroundTransparency = 1
			optLabel.Font                   = Theme.Font.Body
			optLabel.Text                   = opt.Label
			optLabel.TextSize               = Theme.TextSize.Body
			optLabel.TextColor3             = if isSelected
				then Theme.Colors.Accent
				else Theme.Colors.TextPrimary
			optLabel.TextXAlignment         = if self._multiSelect
				then Enum.TextXAlignment.Left
				else Enum.TextXAlignment.Center
			optLabel.TextTruncate           = Enum.TextTruncate.AtEnd
			optLabel.ZIndex                 = 4
			optLabel.Parent                 = optFrame

			if i < optCount then
				local sep                  = Instance.new("Frame")
				sep.Size                   = UDim2.new(1, -Theme.Spacing.M * 2, 0, 1)
				sep.Position               = UDim2.new(0, Theme.Spacing.M, 1, -1)
				sep.BackgroundColor3       = Theme.Colors.Border
				sep.BackgroundTransparency = 0.7
				sep.BorderSizePixel        = 0
				sep.ZIndex                 = 4
				sep.Parent                 = optFrame
			end

			local optHit                  = Instance.new("TextButton")
			optHit.Name                   = "Hit"
			optHit.Size                   = UDim2.fromScale(1, 1)
			optHit.BackgroundTransparency = 1
			optHit.Text                   = ""
			optHit.AutoButtonColor        = false
			optHit.ZIndex                 = 5
			optHit.Parent                 = optFrame

			self._optionMaid:GiveTask(optHit.MouseEnter:Connect(function()
				TweenService:Create(optFrame, TWEEN_HOVER, {
					BackgroundTransparency = 0.82,
					BackgroundColor3       = Theme.Colors.SurfaceHover,
				}):Play()
			end))
			self._optionMaid:GiveTask(optHit.MouseLeave:Connect(function()
				TweenService:Create(optFrame, TWEEN_HOVER, {
					BackgroundTransparency = 1,
					BackgroundColor3       = Color3.fromHex("#1a1a1a"),
				}):Play()
			end))

			self._optionMaid:GiveTask(optHit.MouseButton1Click:Connect(function()
				if not self._enabled then return end

				if self._multiSelect then
					-- toggle selection
					if self._selectedSet[opt.Value] then
						self._selectedSet[opt.Value] = nil
						optLabel.TextColor3 = Theme.Colors.TextPrimary
						if checkLabel then checkLabel.Text = "" end
					else
						self._selectedSet[opt.Value] = true
						optLabel.TextColor3 = Theme.Colors.Accent
						if checkLabel then checkLabel.Text = "✓" end
					end
					-- rebuild selected array for Value
					local arr: { any } = {}
					for _, o in ipairs(self._options) do
						if self._selectedSet[o.Value] then
							table.insert(arr, o.Value)
						end
					end
					self.Value = arr
					-- update header
					local txt, has = headerText(self)
					valueLabel.Text       = txt
					valueLabel.TextColor3 = if has
						then Theme.Colors.TextPrimary
						else Theme.Colors.TextDisabled
					changed:Fire(arr)
					-- stay open on multi

				else
					-- single select: deselect all then select this
					for _, child in ipairs(scroll:GetChildren()) do
						if child:IsA("Frame") then
							local lbl = child:FindFirstChildWhichIsA("TextLabel")
							if lbl and lbl.Name == "OptionLabel" then
								lbl.TextColor3 = Theme.Colors.TextPrimary
							end
						end
					end
					optLabel.TextColor3   = Theme.Colors.Accent
					self._selectedValue   = opt.Value
					self.Value            = opt.Value
					valueLabel.Text       = opt.Label
					valueLabel.TextColor3 = Theme.Colors.TextPrimary
					changed:Fire(opt.Value, opt.Label)
					closeDropdown()
				end
			end))

			optFrame.Parent = scroll
		end
	end

	self._buildOptions = buildOptions
	buildOptions()

	-- ── hover / click on header ───────────────────────────────────────────────
	local hovering = false

	self._maid:GiveTask(hit.MouseEnter:Connect(function()
		if not self._enabled then return end
		hovering = true
		TweenService:Create(stroke, TWEEN_STROKE, { Color = Theme.Colors.Accent }):Play()
		TweenService:Create(flash,  TWEEN_HOVER,  { BackgroundTransparency = 0.92 }):Play()
		TweenService:Create(shadow, TWEEN_HOVER,  SD_HOVER):Play()
	end))

	self._maid:GiveTask(hit.MouseLeave:Connect(function()
		if not self._enabled then return end
		hovering = false
		if not self._open then
			TweenService:Create(stroke, TWEEN_STROKE, { Color = Theme.Colors.Border }):Play()
			TweenService:Create(flash,  TWEEN_HOVER,  { BackgroundTransparency = 1 }):Play()
			TweenService:Create(shadow, TWEEN_HOVER,  SD_REST):Play()
		end
	end))

	self._maid:GiveTask(hit.MouseButton1Click:Connect(function()
		if not self._enabled then return end
		if self._open then
			closeDropdown()
			if not hovering then
				TweenService:Create(flash,  TWEEN_HOVER, { BackgroundTransparency = 1 }):Play()
				TweenService:Create(shadow, TWEEN_HOVER, SD_REST):Play()
			end
		else
			openDropdown()
		end
	end))

	-- close on click outside
	self._maid:GiveTask(UserInputService.InputBegan:Connect(function(input: InputObject)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch then return end
		if not self._open then return end
		local mousePos = UserInputService:GetMouseLocation()
		if not isInsideFrame(frame, mousePos) then
			closeDropdown()
		end
	end))

	-- ── SaveManager wiring ────────────────────────────────────────────────
	do
		local rawLabel = config.Label
		local flag = config.Flag
			or (if rawLabel then SaveManager.deriveFlagFromName(rawLabel) else "")
		if flag ~= "" then
			if self._multiSelect then
				SaveManager.Register(
					flag,
					function() return self.Value end,
					function(v: any)
						if typeof(v) == "table" then
							self:SetValue(v)
						end
					end
				)
			else
				SaveManager.Register(
					flag,
					function() return self.Value end,
					function(v: any) self:SetValue(v) end
				)
			end
			self._maid:GiveTask(changed:Connect(function()
				SaveManager._scheduleAutoSave()
			end))
		end
	end

	return self
end

-- ── public API ────────────────────────────────────────────────────────────────

function Dropdown:SetOptions(options: { any })
	if self._open then
		self._closeDropdown()
		self._arrow.Rotation                    = 0
		self._listWrap.Size                     = UDim2.new(1, 0, 0, 0)
		self._listWrap.BackgroundTransparency   = 1
		self._listStroke.Transparency           = 1
		self._frame.Size                        = UDim2.new(1, 0, 0, HEADER_H)
		TweenService:Create(self._stroke, TWEEN_STROKE, { Color = Theme.Colors.Border }):Play()
	end

	self._options = normalizeOptions(options)

	-- validate existing selection against new options
	if self._multiSelect then
		local newSet: { [any]: boolean } = {}
		for _, opt in ipairs(self._options) do
			if self._selectedSet[opt.Value] then
				newSet[opt.Value] = true
			end
		end
		self._selectedSet = newSet
		local arr: { any } = {}
		for _, opt in ipairs(self._options) do
			if self._selectedSet[opt.Value] then table.insert(arr, opt.Value) end
		end
		self.Value = arr
	else
		local found = false
		for _, opt in ipairs(self._options) do
			if opt.Value == self._selectedValue then found = true break end
		end
		if not found then
			self._selectedValue = nil
			self.Value          = nil
		end
	end

	local txt, has          = headerText(self)
	self._valueLabel.Text       = txt
	self._valueLabel.TextColor3 = if has
		then Theme.Colors.TextPrimary
		else Theme.Colors.TextDisabled

	self._buildOptions()
end

-- SetValue accepts a single value (single-select) or array (multi-select).
function Dropdown:SetValue(value: any)
	if self._multiSelect then
		local arr: { any } = if typeof(value) == "table" then value else { value }
		self._selectedSet = {}
		for _, v in ipairs(arr) do
			self._selectedSet[v] = true
		end
		self.Value = arr
	else
		local found = false
		for _, opt in ipairs(self._options) do
			if opt.Value == value then found = true break end
		end
		self._selectedValue = if found then value else nil
		self.Value          = self._selectedValue
	end

	local txt, has          = headerText(self)
	self._valueLabel.Text       = txt
	self._valueLabel.TextColor3 = if has
		then Theme.Colors.TextPrimary
		else Theme.Colors.TextDisabled

	-- Rebuild list to reflect new highlight state
	self._buildOptions()
end

function Dropdown:SetEnabled(enabled: boolean)
	self._enabled = enabled
	self._stroke.Transparency = if enabled then 0 else 0.5
	if self._outerLabel then
		self._outerLabel.TextColor3 = if enabled
			then Theme.Colors.TextPrimary
			else Theme.Colors.TextDisabled
	end
	if not enabled and self._open then
		self._closeDropdown()
		self._arrow.Rotation                  = 0
		self._listWrap.Size                   = UDim2.new(1, 0, 0, 0)
		self._listWrap.BackgroundTransparency = 1
		self._listStroke.Transparency         = 1
		self._frame.Size                      = UDim2.new(1, 0, 0, HEADER_H)
	end
end

function Dropdown:GetFrame(): Frame
	return self._frame
end

function Dropdown:Destroy()
	self._maid:DoCleaning()
	if self._frame and self._frame.Parent then
		self._frame:Destroy()
	end
end

return Dropdown

end)() end,
    function()local wax,script,require=ImportGlobals(8)local ImportGlobals return (function(...)--!strict
-- Groupbox — a labeled section container that hosts components vertically.
-- Used by Tab:AddGroupbox; supports single and two-column layouts.
-- Mirrors Tab's full Add* API. Dropdown OverlayParent wired internally.

local Maid  = require(script.Parent.Parent.Utils.Maid)
local Theme = require(script.Parent.Parent.Theme)

-- Require siblings directly — importing Components/init would be circular.
local Button      = require(script.Parent.Button)
local Toggle      = require(script.Parent.Toggle)
local Label       = require(script.Parent.Label)
local Description = require(script.Parent.Description)
local Divider     = require(script.Parent.Divider)
local Slider      = require(script.Parent.Slider)
local Textbox     = require(script.Parent.Textbox)
local Keybind     = require(script.Parent.Keybind)
local Dropdown    = require(script.Parent.Dropdown)
local ColorPicker = require(script.Parent.ColorPicker)

-- ── Types ─────────────────────────────────────────────────────────────────

export type GroupboxImpl = {
	AddButton:      (self: GroupboxImpl, config: any) -> any,
	AddToggle:      (self: GroupboxImpl, config: any) -> any,
	AddSlider:      (self: GroupboxImpl, config: any) -> any,
	AddTextbox:     (self: GroupboxImpl, config: any) -> any,
	AddKeybind:     (self: GroupboxImpl, config: any) -> any,
	AddDropdown:    (self: GroupboxImpl, config: any) -> any,
	AddColorPicker: (self: GroupboxImpl, config: any) -> any,
	AddLabel:       (self: GroupboxImpl, text: string, color: Color3?) -> any,
	AddDescription: (self: GroupboxImpl, config: any) -> any,
	AddDivider:     (self: GroupboxImpl, text: string?) -> any,
	GetFrame:       (self: GroupboxImpl) -> Frame,
	Destroy:        (self: GroupboxImpl) -> (),
	_maid:          any,
	_frame:         Frame,
	_gui:           ScreenGui,
	_canvas:        Frame?,
	_layoutOrder:   number,
}

-- ── Class ─────────────────────────────────────────────────────────────────

local Groupbox = {} :: { __index: any }
Groupbox.__index = Groupbox

--[[
	Groupbox.new(title, gui, parentMaid)

	title      — text shown at the top-left of the bordered box
	gui        — ScreenGui root forwarded to Dropdown as OverlayParent
	parentMaid — the Tab's maid; owns this groupbox's maid (cascade cleanup)
]]
function Groupbox.new(title: string, gui: ScreenGui, parentMaid: any, canvas: Frame?): GroupboxImpl
	local self        = setmetatable({}, Groupbox) :: GroupboxImpl
	self._maid        = Maid.new()
	self._gui         = gui
	self._canvas      = canvas
	self._layoutOrder = 0
	parentMaid:GiveTask(self._maid)

	-- ── Outer frame (the bordered Surface box) ──────────────────────────

	local frame                   = Instance.new("Frame")
	frame.Name                    = "GroupboxFrame"
	frame.AutomaticSize           = Enum.AutomaticSize.Y
	frame.Size                    = UDim2.new(1, 0, 0, 0)
	frame.BackgroundColor3        = Theme.Colors.Surface
	frame.BorderSizePixel         = 0
	frame.ClipsDescendants        = false   -- Dropdown overlay must escape the clip boundary
	self._frame                   = frame
	self._maid:GiveTask(frame)

	local corner           = Instance.new("UICorner")
	corner.CornerRadius    = UDim.new(0, Theme.Radius.Medium - 2)  -- 6px
	corner.Parent          = frame

	local stroke           = Instance.new("UIStroke")
	stroke.Color           = Theme.Colors.Border
	stroke.Thickness       = 1
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent          = frame

	local pad         = Instance.new("UIPadding")
	pad.PaddingTop    = UDim.new(0, Theme.Spacing.S)
	pad.PaddingBottom = UDim.new(0, Theme.Spacing.S)
	pad.PaddingLeft   = UDim.new(0, Theme.Spacing.S)
	pad.PaddingRight  = UDim.new(0, Theme.Spacing.S)
	pad.Parent        = frame

	local layout               = Instance.new("UIListLayout")
	layout.FillDirection       = Enum.FillDirection.Vertical
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	layout.SortOrder           = Enum.SortOrder.LayoutOrder
	layout.Padding             = UDim.new(0, Theme.Spacing.XS)
	layout.Parent              = frame

	-- ── Title label (LayoutOrder 0, always rendered first) ───────────────

	if #title > 0 then
		local titleLabel                  = Instance.new("TextLabel")
		titleLabel.Name                   = "GroupboxTitle"
		titleLabel.LayoutOrder            = 0
		titleLabel.AutomaticSize          = Enum.AutomaticSize.XY
		titleLabel.Size                   = UDim2.new(0, 0, 0, 0)
		titleLabel.BackgroundTransparency = 1
		titleLabel.BorderSizePixel        = 0
		titleLabel.Font                   = Theme.Font.Body
		titleLabel.Text                   = title
		titleLabel.TextSize               = Theme.TextSize.Small
		titleLabel.TextColor3             = Theme.Colors.TextSecondary
		titleLabel.TextXAlignment         = Enum.TextXAlignment.Left
		titleLabel.RichText               = false
		titleLabel.Parent                 = frame
	end

	return self
end

-- ── Internal helpers ───────────────────────────────────────────────────────

function Groupbox:_nextOrder(): number
	self._layoutOrder += 1
	return self._layoutOrder
end

--[[
	_addToContent — mirrors Tab:_addToContent exactly.
	Supports optional `description` key for inline sub-labels.
	ComponentWrapper has ClipsDescendants = false so Dropdown overlays escape.
]]
function Groupbox:_addToContent(comp: any, config: any?): any
	local desc = config and (config.description or config.Description)

	if typeof(desc) == "string" and #desc > 0 then
		local compFrame       = comp:GetFrame()
		compFrame.LayoutOrder = 0

		local wrapper                  = Instance.new("Frame")
		wrapper.Name                   = "ComponentWrapper"
		wrapper.AutomaticSize          = Enum.AutomaticSize.Y
		wrapper.Size                   = UDim2.new(1, 0, 0, 0)
		wrapper.BackgroundTransparency = 1
		wrapper.BorderSizePixel        = 0
		wrapper.ClipsDescendants       = false
		wrapper.LayoutOrder            = config.LayoutOrder or 0
		wrapper.Parent                 = self._frame

		local wLayout               = Instance.new("UIListLayout")
		wLayout.FillDirection       = Enum.FillDirection.Vertical
		wLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
		wLayout.SortOrder           = Enum.SortOrder.LayoutOrder
		wLayout.Padding             = UDim.new(0, Theme.Spacing.XS)
		wLayout.Parent              = wrapper

		compFrame.Parent = wrapper

		local descLabel                  = Instance.new("TextLabel")
		descLabel.Name                   = "ComponentDescription"
		descLabel.LayoutOrder            = 1
		descLabel.AutomaticSize          = Enum.AutomaticSize.Y
		descLabel.Size                   = UDim2.new(1, 0, 0, 0)
		descLabel.BackgroundTransparency = 1
		descLabel.BorderSizePixel        = 0
		descLabel.Font                   = Theme.Font.Body
		descLabel.Text                   = desc
		descLabel.TextSize               = Theme.TextSize.Small
		descLabel.TextColor3             = Theme.Colors.TextSecondary
		descLabel.TextXAlignment         = Enum.TextXAlignment.Left
		descLabel.TextWrapped            = true
		descLabel.RichText               = true
		descLabel.Parent                 = wrapper

		local descPad       = Instance.new("UIPadding")
		descPad.PaddingLeft  = UDim.new(0, Theme.Spacing.M)
		descPad.PaddingRight = UDim.new(0, Theme.Spacing.M)
		descPad.PaddingTop   = UDim.new(0, Theme.Spacing.XS)
		descPad.Parent       = descLabel

		local spacer                  = Instance.new("Frame")
		spacer.Name                   = "DescriptionSpacer"
		spacer.LayoutOrder            = 2
		spacer.BackgroundTransparency = 1
		spacer.BorderSizePixel        = 0
		spacer.Size                   = UDim2.fromOffset(0, Theme.Spacing.M)
		spacer.Parent                 = wrapper
	else
		comp:GetFrame().Parent = self._frame
	end

	self._maid:GiveTask(comp)
	return comp
end

-- ── Public Add* API ────────────────────────────────────────────────────────

function Groupbox:AddButton(config: {
	Label: string, Variant: number?, Enabled: boolean?, description: string?,
})
	local c = config :: any
	c.LayoutOrder = self:_nextOrder()
	return self:_addToContent(Button.new(c), c)
end

function Groupbox:AddToggle(config: {
	Label: string, Icon: string?, Default: boolean?, Enabled: boolean?, description: string?,
})
	local c = config :: any
	c.LayoutOrder = self:_nextOrder()
	return self:_addToContent(Toggle.new(c), c)
end

function Groupbox:AddLabel(text: string, color: Color3?)
	local lbl = Label.new({
		Text        = text,
		Color       = color,
		LayoutOrder = self:_nextOrder(),
	})
	return self:_addToContent(lbl, nil)
end

function Groupbox:AddDescription(config: { Title: string?, Description: string })
	local c = config :: any
	c.LayoutOrder = self:_nextOrder()
	local d = Description.new(c)
	d:GetFrame().Parent = self._frame
	self._maid:GiveTask(d)
	return d
end

function Groupbox:AddDivider(text: string?)
	local div = Divider.new({
		Text        = text,
		LayoutOrder = self:_nextOrder(),
	})
	return self:_addToContent(div, nil)
end

function Groupbox:AddSlider(config: {
	Label: string, Min: number?, Max: number?,
	Default: number?, Step: number?, Enabled: boolean?, description: string?,
})
	local c = config :: any
	c.LayoutOrder = self:_nextOrder()
	return self:_addToContent(Slider.new(c), c)
end

function Groupbox:AddTextbox(config: {
	Label: string?, Placeholder: string?, Default: string?,
	MaxLength: number?, ClearOnFocus: boolean?, Enabled: boolean?, description: string?,
})
	local c = config :: any
	c.LayoutOrder = self:_nextOrder()
	return self:_addToContent(Textbox.new(c), c)
end

function Groupbox:AddKeybind(config: {
	Label: string, Default: Enum.KeyCode?,
	Blacklist: { any }?, Enabled: boolean?, description: string?,
})
	local c = config :: any
	c.LayoutOrder = self:_nextOrder()
	return self:_addToContent(Keybind.new(c), c)
end

function Groupbox:AddDropdown(config: {
	Label: string?, Options: { any }, MultiSelect: boolean?,
	Default: any?, Placeholder: string?, Enabled: boolean?, description: string?,
})
	local c = config :: any
	c.LayoutOrder   = self:_nextOrder()
	c.OverlayParent = self._gui   -- wired internally, never exposed to caller
	return self:_addToContent(Dropdown.new(c), c)
end

function Groupbox:AddColorPicker(config: {
	Label: string, Default: Color3?, ShowAlpha: boolean?,
	Flag: string?, Risky: boolean?, Enabled: boolean?, description: string?,
})
	local c = config :: any
	c.LayoutOrder   = self:_nextOrder()
	c.OverlayParent = self._gui
	c.Canvas        = self._canvas
	return self:_addToContent(ColorPicker.new(c), c)
end

-- ── Lifecycle ─────────────────────────────────────────────────────────────

function Groupbox:GetFrame(): Frame
	return self._frame
end

function Groupbox:Destroy()
	self._maid:Destroy()
end

return Groupbox

end)() end,
    function()local wax,script,require=ImportGlobals(9)local ImportGlobals return (function(...)--!strict

local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local TextService      = game:GetService("TextService")

local Maid        = require(script.Parent.Parent.Utils.Maid)
local Signal      = require(script.Parent.Parent.Utils.Signal)
local Theme       = require(script.Parent.Parent.Theme)
local SaveManager = require(script.Parent.Parent.Core.SaveManager)

local TWEEN_HOVER  = TweenInfo.new(0.38, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local TWEEN_STROKE = TweenInfo.new(0.38, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local TWEEN_SHADOW = TweenInfo.new(0.38, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local TWEEN_PRESS  = TweenInfo.new(0.20, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local TWEEN_RESIZE = TweenInfo.new(0.25, Enum.EasingStyle.Sine,  Enum.EasingDirection.InOut)

local SHADOW_REST  = { BackgroundTransparency = 0.75, Position = UDim2.new(0.5, 0, 0.5, 3) }
local SHADOW_HOVER = { BackgroundTransparency = 0.65, Position = UDim2.new(0.5, 0, 0.5, 5) }

local PILL_H   = 22
local PILL_PAD = 12

-- ── Key name map ───────────────────────────────────────────────────────────────

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
	[Enum.KeyCode.F1]  = "F1",  [Enum.KeyCode.F2]  = "F2",  [Enum.KeyCode.F3]  = "F3",
	[Enum.KeyCode.F4]  = "F4",  [Enum.KeyCode.F5]  = "F5",  [Enum.KeyCode.F6]  = "F6",
	[Enum.KeyCode.F7]  = "F7",  [Enum.KeyCode.F8]  = "F8",  [Enum.KeyCode.F9]  = "F9",
	[Enum.KeyCode.F10] = "F10", [Enum.KeyCode.F11] = "F11", [Enum.KeyCode.F12] = "F12",
}

local function keyName(key: Enum.KeyCode): string
	return KEY_NAMES[key] or key.Name
end

local function measureText(text: string): number
	local v = TextService:GetTextSize(
		text,
		Theme.TextSize.Small,
		Enum.Font.Code,
		Vector2.new(math.huge, math.huge)
	)
	return v.X
end

local function pillWidth(text: string): number
	return measureText(text) + PILL_PAD * 2
end

-- ── Types ──────────────────────────────────────────────────────────────────────

export type KeybindConfig = {
	Label:       string,
	Icon:        string?,
	Default:     Enum.KeyCode?,
	Enabled:     boolean?,
	LayoutOrder: number?,
	Flag:        string?,
	-- Execution mode.
	-- "Press"  (default) — fires Pressed once per keydown, respects Enabled.
	-- "Toggle"           — alternates boolean state, fires Toggled, respects Enabled.
	-- "Hold"             — fires HoldStart on down, HoldEnd on up, respects Enabled.
	-- "Always"           — fires Pressed regardless of Enabled state.
	Mode: string?,
}

type KeybindImpl = {
	Key:          Enum.KeyCode?,
	-- Capture signal (key was rebound)
	Changed:      any,
	-- Execution signals
	Pressed:      any,
	Toggled:      any,
	HoldStart:    any,
	HoldEnd:      any,
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
	_mode:        string,
	_toggleState: boolean,
	_morphToken:  number?,
}

local Keybind = {} :: { __index: any }
Keybind.__index = Keybind

function Keybind.new(config: KeybindConfig): KeybindImpl
	local self          = setmetatable({}, Keybind) :: KeybindImpl
	self._maid          = Maid.new()
	self._enabled       = if config.Enabled ~= nil then config.Enabled else true
	self._binding       = false
	self._bindToken     = 0
	self._mode          = config.Mode or "Press"
	self._toggleState   = false
	self.Key            = config.Default

	-- ── Outer container ────────────────────────────────────────────────────────
	local frame                  = Instance.new("Frame")
	frame.Name                   = "Keybind"
	frame.Size                   = UDim2.new(1, 0, 0, 36)
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel        = 0
	frame.LayoutOrder            = config.LayoutOrder or 0
	frame.ClipsDescendants       = false
	self._frame                  = frame

	-- ── Shadow ─────────────────────────────────────────────────────────────────
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

	-- ── Inner row ──────────────────────────────────────────────────────────────
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

	-- ── Content (icon + label) ─────────────────────────────────────────────────
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

	-- ── Pill (key display box) ─────────────────────────────────────────────────
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

	local pillHit                  = Instance.new("TextButton")
	pillHit.Name                   = "PillHit"
	pillHit.Size                   = UDim2.fromScale(1, 1)
	pillHit.BackgroundTransparency = 1
	pillHit.Text                   = ""
	pillHit.AutoButtonColor        = false
	pillHit.ZIndex                 = 9
	pillHit.Parent                 = pill

	-- Content tracks pill width during its resize tween
	local function syncContent()
		local pillW = pill.AbsoluteSize.X
		if pillW > 0 then
			content.Size = UDim2.new(1, -(pillW + Theme.Spacing.M), 1, 0)
		end
	end
	self._maid:GiveTask(pill:GetPropertyChangedSignal("AbsoluteSize"):Connect(syncContent))

	-- ── Signals ────────────────────────────────────────────────────────────────

	-- Fires when the bound key changes (capture complete)
	local changed = Signal.new()
	self.Changed  = changed
	self._maid:GiveTask(changed)

	-- Execution signals — which ones are useful depends on Mode
	local pressed   = Signal.new()
	local toggled   = Signal.new()
	local holdStart = Signal.new()
	local holdEnd   = Signal.new()
	self.Pressed   = pressed
	self.Toggled   = toggled
	self.HoldStart = holdStart
	self.HoldEnd   = holdEnd
	self._maid:GiveTask(pressed)
	self._maid:GiveTask(toggled)
	self._maid:GiveTask(holdStart)
	self._maid:GiveTask(holdEnd)

	-- ── Hover / pill interaction ────────────────────────────────────────────────

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

	-- Pill click — enter / exit binding mode
	self._maid:GiveTask(pillHit.MouseButton1Click:Connect(function()
		if not self._enabled then return end
		self._binding = not self._binding

		if self._binding then
			self._bindToken += 1
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

	-- ── Key capture (binding mode) ─────────────────────────────────────────────

	self._maid:GiveTask(UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
		if gameProcessed or not self._binding or not self._enabled then return end
		if input.UserInputType ~= Enum.UserInputType.Keyboard then return end

		if input.KeyCode == Enum.KeyCode.Escape then
			self._bindToken += 1
			self:_exitBinding(false)
			return
		end

		self._bindToken += 1
		self:SetKey(input.KeyCode)
		changed:Fire(input.KeyCode)
	end))

	-- ── Execution listener — InputBegan ────────────────────────────────────────
	-- Fires independently of binding mode; does NOT interfere with rebind flow.

	self._maid:GiveTask(UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
		if gameProcessed then return end
		if self._binding then return end  -- rebind in progress; don't execute
		if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
		if input.KeyCode ~= self.Key then return end

		-- "Always" ignores _enabled; every other mode respects it
		if self._mode ~= "Always" and not self._enabled then return end

		if self._mode == "Toggle" then
			self._toggleState = not self._toggleState
			toggled:Fire(self._toggleState)
		elseif self._mode == "Hold" then
			holdStart:Fire()
		else
			-- "Press" and "Always" both fire Pressed
			pressed:Fire()
		end
	end))

	-- ── Execution listener — InputEnded (Hold release) ─────────────────────────

	self._maid:GiveTask(UserInputService.InputEnded:Connect(function(input: InputObject)
		if self._binding then return end
		if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
		if input.KeyCode ~= self.Key then return end
		if self._mode ~= "Hold" then return end
		if not self._enabled then return end
		holdEnd:Fire()
	end))

	-- ── SaveManager wiring ────────────────────────────────────────────────────

	do
		local flag = config.Flag
			or SaveManager.deriveFlagFromName(config.Label)
		if flag ~= "" then
			SaveManager.Register(
				flag,
				function()
					return if self.Key then self.Key.Name else nil
				end,
				function(v: any)
					if type(v) == "string" then
						local kc = (Enum.KeyCode :: any)[v] :: Enum.KeyCode?
						if kc then self:SetKey(kc) end
					end
				end
			)
			self._maid:GiveTask(changed:Connect(function()
				SaveManager._scheduleAutoSave()
			end))
		end
	end

	return self
end

-- ── Animate pill width to fit new text ────────────────────────────────────────

function Keybind:_animatePill(text: string)
	local targetW = pillWidth(text)
	TweenService:Create(self._pill, TWEEN_RESIZE, {
		Size = UDim2.fromOffset(targetW, PILL_H),
	}):Play()
end

-- ── Exit binding state ─────────────────────────────────────────────────────────

function Keybind:_exitBinding(confirmed: boolean)
	self._binding = false
	local restoreText = if self.Key then keyName(self.Key) else "—"
	if not confirmed then
		self:_animatePill(restoreText)
		self._pillLabel.Text = restoreText
	end
	TweenService:Create(self._flash,      TWEEN_HOVER,  { BackgroundTransparency = 1 }):Play()
	TweenService:Create(self._stroke,     TWEEN_STROKE, { Color = Theme.Colors.Border }):Play()
	TweenService:Create(self._pillStroke, TWEEN_STROKE, { Color = Theme.Colors.Border }):Play()
	self._pill.BackgroundColor3 = Theme.Colors.SurfaceActive
	TweenService:Create(self._pillLabel,  TWEEN_HOVER,  { TextColor3 = Theme.Colors.TextPrimary }):Play()
end

-- ── Public API ─────────────────────────────────────────────────────────────────

function Keybind:SetKey(key: Enum.KeyCode?)
	self.Key = key
	local newText = if key then keyName(key) else "—"
	self._pillLabel.Text = newText
	self:_animatePill(newText)
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

end)() end,
    function()local wax,script,require=ImportGlobals(10)local ImportGlobals return (function(...)--!strict

local Theme = require(script.Parent.Parent.Theme)

export type LabelConfig = {
	Text: string,
	Color: Color3?,
	LayoutOrder: number?,
}

type LabelImpl = {
	SetText: (self: LabelImpl, text: string) -> (),
	GetFrame: (self: LabelImpl) -> Frame,
	Destroy: (self: LabelImpl) -> (),
	_frame: Frame,
	_label: TextLabel,
}

local Label = {} :: { __index: any }
Label.__index = Label

function Label.new(config: LabelConfig): LabelImpl
	local self  = setmetatable({}, Label) :: LabelImpl

	local frame              = Instance.new("Frame")
	frame.Name               = "Label"
	frame.Size               = UDim2.new(1, 0, 0, 24)
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel    = 0
	frame.LayoutOrder        = config.LayoutOrder or 0
	self._frame              = frame

	local pad        = Instance.new("UIPadding")
	pad.PaddingLeft  = UDim.new(0, Theme.Spacing.M)
	pad.PaddingRight = UDim.new(0, Theme.Spacing.M)
	pad.Parent       = frame

	local label               = Instance.new("TextLabel")
	label.Name                = "Text"
	label.Size                = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font                = Theme.Font.Body
	label.Text                = config.Text
	label.TextSize            = Theme.TextSize.Small
	label.TextColor3          = config.Color or Theme.Colors.TextSecondary
	label.TextXAlignment      = Enum.TextXAlignment.Left
	label.TextWrapped         = true
	label.Parent              = frame
	self._label               = label

	return self
end

function Label:SetText(text: string)
	self._label.Text = text
end

function Label:GetFrame(): Frame
	return self._frame
end

function Label:Destroy()
	if self._frame and self._frame.Parent then
		self._frame:Destroy()
	end
end

return Label

end)() end,
    function()local wax,script,require=ImportGlobals(11)local ImportGlobals return (function(...)--!strict

local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Maid        = require(script.Parent.Parent.Utils.Maid)
local Signal      = require(script.Parent.Parent.Utils.Signal)
local Theme       = require(script.Parent.Parent.Theme)
local SaveManager = require(script.Parent.Parent.Core.SaveManager)

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
local TRACK_W  = 120    -- total track width
local TRACK_H  = 15     -- slim pill track
local KNOB_W   = 30     -- knob width  (flat pill, wider than tall)
local KNOB_H   = 18     -- knob height (gepeng)
local KNOB_PAD = 0      -- gap between knob edge and track edge at extremes

-- Knob X-center bounds (keeps knob fully inside the track)
local KNOB_X_MIN = KNOB_W / 2 + KNOB_PAD          -- left extreme
local KNOB_X_MAX = TRACK_W - KNOB_W / 2 - KNOB_PAD -- right extreme

local VAL_W = 34
local GAP   = 8

-- ── Knob scale states ─────────────────────────────────────────────────────────
local KNOB_SCALE_REST  = 1.00
local KNOB_SCALE_HOVER = 1.10
local KNOB_SCALE_PRESS = 0.92

-- Knob X-center range (pixels): knob travels [KNOB_X_MIN, KNOB_X_MAX]
-- Fill visible width is driven by a ClipFrame that matches knob center X,
-- so fill always ends exactly at the knob center with no offset error.
-- Fill itself is statically wide (TRACK_W * 2) so the right rounded corner
-- is always beyond the clip boundary → clean flat right edge always visible.

export type SliderConfig = {
	Label:       string,
	Min:         number?,
	Max:         number?,
	Default:     number?,
	Step:        number?,
	Enabled:     boolean?,
	LayoutOrder: number?,
	Flag:        string?,
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

-- Returns the knob X-center pixel position for a normalized t ∈ [0, 1]
local function knobX(t: number): number
	return KNOB_X_MIN + t * (KNOB_X_MAX - KNOB_X_MIN)
end

-- Returns the normalized t from a mouse X position relative to track
local function tFromMouseX(track: Frame, mouseX: number): number
	local relX = mouseX - track.AbsolutePosition.X
	-- Map from KNOB_X_MIN..KNOB_X_MAX
	return math.clamp(
		(relX - KNOB_X_MIN) / (KNOB_X_MAX - KNOB_X_MIN),
		0, 1
	)
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
	local frame                  = Instance.new("Frame")
	frame.Name                   = "Slider"
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

	-- ── Track (iOS pill) ──────────────────────────────────────────────────────
	local track              = Instance.new("Frame")
	track.Name               = "Track"
	track.Size               = UDim2.fromOffset(TRACK_W, TRACK_H)
	track.Position           = UDim2.new(1, -TRACK_W, 0.5, -(TRACK_H / 2))
	track.BackgroundColor3   = Theme.Colors.Border
	track.BorderSizePixel    = 0
	track.ZIndex             = 4
	track.ClipsDescendants   = false
	local trackCorner        = Instance.new("UICorner")
	trackCorner.CornerRadius = UDim.new(0, Theme.Radius.Pill)
	trackCorner.Parent       = track
	track.Parent             = inner
	self._track              = track

	-- FillClip: controls the visible right boundary of the fill.
	-- By animating THIS frame's width (= knobX(t) pixels), the fill always
	-- ends exactly at the knob center. ClipsDescendants trims the fill's
	-- right edge cleanly so the fill's own rounded corners never deform.
	local clipFrame                  = Instance.new("Frame")
	clipFrame.Name                   = "FillClip"
	clipFrame.Size                   = UDim2.fromOffset(knobX(t0), TRACK_H)
	clipFrame.Position               = UDim2.fromOffset(0, 0)
	clipFrame.BackgroundTransparency = 1
	clipFrame.ClipsDescendants       = true
	clipFrame.BorderSizePixel        = 0
	clipFrame.ZIndex                 = 5
	clipFrame.Parent                 = track
	self._clipFrame                  = clipFrame

	-- Fill: static width (2× track) so its right pill corner is always
	-- beyond the clip boundary → right edge is always a clean flat cut.
	local fill            = Instance.new("Frame")
	fill.Name             = "Fill"
	fill.Size             = UDim2.fromOffset(TRACK_W * 2, TRACK_H)
	fill.BackgroundColor3 = Theme.Colors.Accent
	fill.BorderSizePixel  = 0
	fill.ZIndex           = 5
	local fillCorner      = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, Theme.Radius.Pill)
	fillCorner.Parent     = fill
	fill.Parent           = clipFrame
	self._fill            = fill

	-- ── Knob — AnchorPoint 0.5,0.5 so UIScale animates around center ──────────
	local knob            = Instance.new("Frame")
	knob.Name             = "Knob"
	knob.AnchorPoint      = Vector2.new(0.5, 0.5)
	knob.Size             = UDim2.fromOffset(KNOB_W, KNOB_H)
	knob.Position         = UDim2.fromOffset(knobX(t0), TRACK_H / 2)
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

	-- ── Value readout ─────────────────────────────────────────────────────────
	local valLabel                  = Instance.new("TextLabel")
	valLabel.Name                   = "ValueLabel"
	valLabel.AnchorPoint            = Vector2.new(0, 0.5)
	valLabel.Position               = UDim2.new(1, -(TRACK_W + VAL_W + GAP), 0.5, 0)
	valLabel.Size                   = UDim2.fromOffset(VAL_W, 36)
	valLabel.BackgroundTransparency = 1
	valLabel.Font                   = Theme.Font.Body
	valLabel.Text                   = fmt(self._value, self._step)
	valLabel.TextSize               = Theme.TextSize.Body
	valLabel.TextColor3             = Theme.Colors.TextSecondary
	valLabel.TextXAlignment         = Enum.TextXAlignment.Right
	valLabel.ZIndex                 = 4
	valLabel.Parent                 = inner
	self._valLabel                  = valLabel

	-- ── Label ─────────────────────────────────────────────────────────────────
	local rightReserved = TRACK_W + VAL_W + GAP
	local label                  = Instance.new("TextLabel")
	label.Name                   = "Label"
	label.Position               = UDim2.fromOffset(Theme.Spacing.M, 0)
	label.Size                   = UDim2.new(1, -(rightReserved + Theme.Spacing.M * 2 + GAP), 1, 0)
	label.BackgroundTransparency = 1
	label.Font                   = Theme.Font.Body
	label.Text                   = config.Label
	label.TextSize               = Theme.TextSize.Body
	label.TextColor3             = if self._enabled
		then Theme.Colors.TextPrimary
		else Theme.Colors.TextDisabled
	label.TextXAlignment         = Enum.TextXAlignment.Left
	label.TextTruncate           = Enum.TextTruncate.AtEnd
	label.ZIndex                 = 4
	label.Parent                 = frame
	self._label                  = label

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

		-- ClipFrame: drive visible fill width to match knob center (pixels)
		TweenService:Create(clipFrame, TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.fromOffset(knobX(st), TRACK_H),
		}):Play()

		-- Knob: direct set — zero lag while dragging
		knob.Position = UDim2.fromOffset(knobX(st), TRACK_H / 2)

		changed:Fire(value)
	end

	-- ── Row hover (stroke / flash / shadow) — full inner area ──────────────────
	-- Knob scale is intentionally NOT here; it lives on knob.MouseEnter/Leave
	-- so it only fires when the cursor is actually over the knob.
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

	-- ── Knob hover (scale only) — fires only when cursor is over the knob ──────
	-- GuiObject.MouseEnter/Leave fire on bounding-box position regardless of
	-- ZIndex occlusion, so this works even though hit (ZIndex 7) sits on top.
	self._maid:GiveTask(knob.MouseEnter:Connect(function()
		if not self._enabled or dragging then return end
		TweenService:Create(knobScale, TWEEN_KNOB_HOVER, { Scale = KNOB_SCALE_HOVER }):Play()
	end))

	self._maid:GiveTask(knob.MouseLeave:Connect(function()
		if not self._enabled or dragging then return end
		TweenService:Create(knobScale, TWEEN_KNOB_REL, { Scale = KNOB_SCALE_REST }):Play()
	end))

	-- ── Press (scale down) ────────────────────────────────────────────────────
	-- Guard: only start drag when the click lands within the track's horizontal
	-- bounds. Without this, clicking the label on the left calls tFromMouseX
	-- with a negative relX → clamps to 0 → silently zeros the value.
	self._maid:GiveTask(hit.MouseButton1Down:Connect(function()
		if not self._enabled then return end
		local mouseX    = UserInputService:GetMouseLocation().X
		local trackLeft = track.AbsolutePosition.X
		if mouseX < trackLeft or mouseX > trackLeft + TRACK_W + KNOB_W / 2 then return end
		dragging = true
		TweenService:Create(knobScale, TWEEN_KNOB_PRESS, { Scale = KNOB_SCALE_PRESS }):Play()
		applyT(tFromMouseX(track, mouseX))
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
		-- Always restore to rest; knob.MouseEnter will re-trigger hover scale
		-- if the cursor is still over the knob after release.
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

	return self
end

-- ── SetValue (programmatic — smooth tween) ────────────────────────────────────

function Slider:SetValue(value: number)
	local clamped = math.clamp(snap(value, self._step), self._min, self._max)
	local t       = (clamped - self._min) / math.max(self._max - self._min, 1e-9)

	self._value         = clamped
	self.Value          = clamped
	self._valLabel.Text = fmt(clamped, self._step)

	TweenService:Create(self._clipFrame, TWEEN_FILL, {
		Size = UDim2.fromOffset(knobX(t), TRACK_H),
	}):Play()
	TweenService:Create(self._knob, TWEEN_KNOB_SLIDE, {
		Position = UDim2.fromOffset(knobX(t), TRACK_H / 2),
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

end)() end,
    function()local wax,script,require=ImportGlobals(12)local ImportGlobals return (function(...)--!strict

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

end)() end,
    function()local wax,script,require=ImportGlobals(13)local ImportGlobals return (function(...)--!strict

local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Maid        = require(script.Parent.Parent.Utils.Maid)
local Signal      = require(script.Parent.Parent.Utils.Signal)
local Theme       = require(script.Parent.Parent.Theme)
local SaveManager = require(script.Parent.Parent.Core.SaveManager)

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
	Flag: string?,
	-- When true, label renders in Theme.Colors.Error (visual-only danger signal).
	-- Does not affect toggle behaviour, value, or save logic.
	Risky: boolean?,
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
	_risky:   boolean,
}

local Toggle = {} :: { __index: any }
Toggle.__index = Toggle

function Toggle.new(config: ToggleConfig): ToggleImpl
	local self    = setmetatable({}, Toggle) :: ToggleImpl
	self._maid    = Maid.new()
	self._value   = if config.Default ~= nil then config.Default else false
	self._enabled = if config.Enabled ~= nil then config.Enabled else true
	self._risky   = config.Risky == true

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

	-- ── SaveManager wiring ────────────────────────────────────────────────
	local flag = config.Flag
		or SaveManager.deriveFlagFromName(config.Label)
	if flag ~= "" then
		SaveManager.Register(
			flag,
			function() return self._value end,
			function(v: any) self:SetValue(v == true) end
		)
		self._maid:GiveTask(changed:Connect(function()
			SaveManager._scheduleAutoSave()
		end))
	end

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
	local color            = if not enabled
		then Theme.Colors.TextDisabled
		elseif self._risky then Theme.Colors.Error
		else Theme.Colors.TextPrimary
	self._label.TextColor3 = color
	if self._icon then
		-- icon stays neutral; Risky only tints the label
		self._icon.ImageColor3 = if enabled then Theme.Colors.TextPrimary else Theme.Colors.TextDisabled
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

end)() end,
    function()local wax,script,require=ImportGlobals(14)local ImportGlobals return (function(...)--!strict

local Window     = require(script.Window)
local Components = require(script.Parent.Components)

return {
	Window     = Window,
	Components = Components,
}

end)() end,
    function()local wax,script,require=ImportGlobals(15)local ImportGlobals return (function(...)--!strict

-- Notification — singleton toast system.
-- Slide-in from right, semantic left-border color, auto-dismiss + manual X dismiss.
-- Queue: max 3 visible at once, rest enqueue and show when a slot opens.

local TweenService = game:GetService("TweenService")
local Players      = game:GetService("Players")

local Theme = require(script.Parent.Parent.Theme)

-- ── Constants ─────────────────────────────────────────────────────────────────

local TOAST_W           = 280
local TOAST_MAX_VISIBLE = 3
local DEFAULT_DURATION  = 4
local LEFT_BAR_W        = 4
local PAD_H             = 12   -- horizontal padding inside body
local PAD_V             = 10   -- vertical padding inside body
local GAP               = 8    -- gap between stacked toasts

local TWEEN_IN  = TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local TWEEN_OUT = TweenInfo.new(0.20, Enum.EasingStyle.Quint, Enum.EasingDirection.In)

-- ── Types ─────────────────────────────────────────────────────────────────────

export type NotifyConfig = {
	Title    : string?,
	Message  : string,
	Type     : string?,   -- "info" | "success" | "warning" | "error"
	Duration : number?,
}

type ActiveToast = {
	wrapper     : Frame,
	card        : CanvasGroup,
	cancelTimer : () -> (),
}

-- ── Singleton state ───────────────────────────────────────────────────────────

local _gui          : ScreenGui?        = nil
local _container    : Frame?            = nil
local _active       : { ActiveToast }   = {}
local _queue        : { NotifyConfig }  = {}
local _orderCounter : number            = 10000   -- decrements so newest = lowest = top of list

-- ── Helpers ───────────────────────────────────────────────────────────────────

local function typeColor(notifType: string?): Color3
	local t = notifType or "info"
	if     t == "success" then return Theme.Colors.Success
	elseif t == "warning" then return Theme.Colors.Warning
	elseif t == "error"   then return Theme.Colors.Error
	else                       return Theme.Colors.Accent
	end
end

local function applyCorner(parent: Instance, radius: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = parent
end

-- ── GUI bootstrap (lazy, first notify call) ───────────────────────────────────

local function ensureGui()
	if _gui then return end

	local gui          = Instance.new("ScreenGui")
	gui.Name           = "DeliriumNotifications"
	gui.ResetOnSpawn   = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.IgnoreGuiInset = true
	pcall(function() gui.DisplayOrder = 1000 end)

	-- Parent: CoreGui first, PlayerGui fallback
	local ok = pcall(function()
		gui.Parent = game:GetService("CoreGui")
	end)
	if not ok or not gui.Parent then
		local lp = Players.LocalPlayer
		if lp then
			local pg = lp:FindFirstChildOfClass("PlayerGui")
			if pg then
				gui.Parent = pg
			else
				local waited = lp:WaitForChild("PlayerGui", 3)
				if waited then gui.Parent = waited end
			end
		end
	end

	-- Bottom-right container; AnchorPoint (1,1) so AutomaticSize Y expands upward
	local container                  = Instance.new("Frame")
	container.Name                   = "NotifContainer"
	container.AnchorPoint            = Vector2.new(1, 1)
	container.Position               = UDim2.new(1, -16, 1, -16)
	container.Size                   = UDim2.fromOffset(TOAST_W, 0)
	container.AutomaticSize          = Enum.AutomaticSize.Y
	container.BackgroundTransparency = 1
	container.BorderSizePixel        = 0
	container.ClipsDescendants       = false
	container.Parent                 = gui

	local layout               = Instance.new("UIListLayout")
	layout.FillDirection       = Enum.FillDirection.Vertical
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	layout.SortOrder           = Enum.SortOrder.LayoutOrder
	layout.Padding             = UDim.new(0, GAP)
	layout.Parent              = container

	_gui       = gui
	_container = container
end

-- ── Dismiss ───────────────────────────────────────────────────────────────────

local function dismissToast(toast: ActiveToast)
	toast.cancelTimer()

	-- Slide out to right + fade
	local t = TweenService:Create(toast.card, TWEEN_OUT, {
		Position          = UDim2.fromOffset(TOAST_W + 24, 0),
		GroupTransparency = 1,
	})
	t:Play()
	t.Completed:Once(function()
		if toast.wrapper.Parent then
			toast.wrapper:Destroy()
		end

		-- Remove from active list
		local idx = table.find(_active, toast)
		if idx then
			table.remove(_active, idx)
		end

		-- Pop next from queue
		if #_queue > 0 then
			local next = table.remove(_queue, 1)
			-- require the module itself for the recursive call — avoid upvalue capture issues
			local Notification = require(script) :: any
			Notification.notify(next)
		end
	end)
end

-- ── Public ────────────────────────────────────────────────────────────────────

local Notification = {}

function Notification.notify(config: NotifyConfig)
	ensureGui()

	-- Queue if at capacity
	if #_active >= TOAST_MAX_VISIBLE then
		table.insert(_queue, config)
		return
	end

	local accent   = typeColor(config.Type)
	local duration = config.Duration or DEFAULT_DURATION

	-- Newest toast gets the lowest LayoutOrder → top of the vertical list
	_orderCounter -= 1
	local order = _orderCounter

	-- ── Wrapper (layout slot, transparent) ────────────────────────────────────
	local wrapper                  = Instance.new("Frame")
	wrapper.Name                   = "ToastWrapper"
	wrapper.Size                   = UDim2.fromOffset(TOAST_W, 0)
	wrapper.AutomaticSize          = Enum.AutomaticSize.Y
	wrapper.BackgroundTransparency = 1
	wrapper.BorderSizePixel        = 0
	wrapper.ClipsDescendants       = false
	wrapper.LayoutOrder            = order
	wrapper.Parent                 = _container

	-- ── Card (CanvasGroup for group fade) ─────────────────────────────────────
	local card                    = Instance.new("CanvasGroup")
	card.Name                     = "ToastCard"
	card.Size                     = UDim2.fromOffset(TOAST_W, 0)
	card.AutomaticSize            = Enum.AutomaticSize.Y
	-- Start off-screen to the right, fully transparent
	card.Position                 = UDim2.fromOffset(TOAST_W + 24, 0)
	card.BackgroundColor3         = Theme.Colors.Surface
	card.BorderSizePixel          = 0
	card.GroupTransparency        = 1
	card.ClipsDescendants         = false
	card.Parent                   = wrapper
	applyCorner(card, Theme.Radius.Medium)

	local stroke           = Instance.new("UIStroke")
	stroke.Color           = Theme.Colors.Border
	stroke.Thickness       = 1
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent          = card

	-- ── Colored left accent strip ──────────────────────────────────────────────
	local leftBar                  = Instance.new("Frame")
	leftBar.Name                   = "AccentBar"
	leftBar.AnchorPoint            = Vector2.new(0, 0)
	leftBar.Position               = UDim2.fromOffset(0, 0)
	leftBar.Size                   = UDim2.new(0, LEFT_BAR_W, 1, 0)
	leftBar.BackgroundColor3       = accent
	leftBar.BorderSizePixel        = 0
	leftBar.ZIndex                 = 2
	leftBar.Parent                 = card
	applyCorner(leftBar, Theme.Radius.Medium)

	-- ── Body (right of left bar) ───────────────────────────────────────────────
	local body                     = Instance.new("Frame")
	body.Name                      = "Body"
	body.Position                  = UDim2.fromOffset(LEFT_BAR_W + PAD_H, 0)
	body.Size                      = UDim2.new(1, -(LEFT_BAR_W + PAD_H + 28), 0, 0)
	body.AutomaticSize             = Enum.AutomaticSize.Y
	body.BackgroundTransparency    = 1
	body.BorderSizePixel           = 0
	body.ZIndex                    = 2
	body.Parent                    = card

	local bodyLayout               = Instance.new("UIListLayout")
	bodyLayout.FillDirection       = Enum.FillDirection.Vertical
	bodyLayout.SortOrder           = Enum.SortOrder.LayoutOrder
	bodyLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	bodyLayout.Padding             = UDim.new(0, 3)
	bodyLayout.Parent              = body

	local bodyPad         = Instance.new("UIPadding")
	bodyPad.PaddingTop    = UDim.new(0, PAD_V)
	bodyPad.PaddingBottom = UDim.new(0, PAD_V)
	bodyPad.Parent        = body

	-- Title (optional)
	if config.Title and #config.Title > 0 then
		local titleLbl                  = Instance.new("TextLabel")
		titleLbl.Name                   = "Title"
		titleLbl.LayoutOrder            = 0
		titleLbl.AutomaticSize          = Enum.AutomaticSize.Y
		titleLbl.Size                   = UDim2.new(1, 0, 0, 0)
		titleLbl.BackgroundTransparency = 1
		titleLbl.Font                   = Theme.Font.Title
		titleLbl.Text                   = config.Title
		titleLbl.TextSize               = Theme.TextSize.Body
		titleLbl.TextColor3             = Theme.Colors.TextPrimary
		titleLbl.TextXAlignment         = Enum.TextXAlignment.Left
		titleLbl.TextWrapped            = true
		titleLbl.ZIndex                 = 3
		titleLbl.Parent                 = body
	end

	-- Message
	local msgLbl                  = Instance.new("TextLabel")
	msgLbl.Name                   = "Message"
	msgLbl.LayoutOrder            = 1
	msgLbl.AutomaticSize          = Enum.AutomaticSize.Y
	msgLbl.Size                   = UDim2.new(1, 0, 0, 0)
	msgLbl.BackgroundTransparency = 1
	msgLbl.Font                   = Theme.Font.Body
	msgLbl.Text                   = config.Message
	msgLbl.TextSize               = Theme.TextSize.Small
	msgLbl.TextColor3             = Theme.Colors.TextSecondary
	msgLbl.TextXAlignment         = Enum.TextXAlignment.Left
	msgLbl.TextWrapped            = true
	msgLbl.ZIndex                 = 3
	msgLbl.Parent                 = body

	-- ── Close button ──────────────────────────────────────────────────────────
	local closeBtn                  = Instance.new("TextButton")
	closeBtn.Name                   = "CloseBtn"
	closeBtn.AnchorPoint            = Vector2.new(1, 0)
	closeBtn.Position               = UDim2.new(1, -8, 0, 8)
	closeBtn.Size                   = UDim2.fromOffset(18, 18)
	closeBtn.BackgroundColor3       = Theme.Colors.SurfaceHover
	closeBtn.BorderSizePixel        = 0
	closeBtn.Font                   = Theme.Font.Body
	closeBtn.Text                   = "×"
	closeBtn.TextSize               = 14
	closeBtn.TextColor3             = Theme.Colors.TextSecondary
	closeBtn.AutoButtonColor        = false
	closeBtn.ZIndex                 = 5
	closeBtn.Parent                 = card
	applyCorner(closeBtn, 4)

	-- ── Build ActiveToast ─────────────────────────────────────────────────────

	local timerThread : thread? = nil
	local dismissed             = false

	local function cancelTimer()
		dismissed = true
		if timerThread then
			pcall(task.cancel, timerThread)
			timerThread = nil
		end
	end

	local toast: ActiveToast = {
		wrapper     = wrapper,
		card        = card,
		cancelTimer = cancelTimer,
	}
	table.insert(_active, toast)

	-- ── Tween in ──────────────────────────────────────────────────────────────
	TweenService:Create(card, TWEEN_IN, {
		Position          = UDim2.fromOffset(0, 0),
		GroupTransparency = 0,
	}):Play()

	-- ── Auto-dismiss timer ────────────────────────────────────────────────────
	timerThread = task.delay(duration, function()
		if not dismissed then
			dismissToast(toast)
		end
	end)

	-- ── Close button interactions ─────────────────────────────────────────────
	closeBtn.MouseButton1Click:Connect(function()
		dismissToast(toast)
	end)
	closeBtn.MouseEnter:Connect(function()
		closeBtn.BackgroundColor3 = Theme.Colors.Error
		closeBtn.TextColor3       = Theme.Colors.TextPrimary
	end)
	closeBtn.MouseLeave:Connect(function()
		closeBtn.BackgroundColor3 = Theme.Colors.SurfaceHover
		closeBtn.TextColor3       = Theme.Colors.TextSecondary
	end)
end

return Notification

end)() end,
    function()local wax,script,require=ImportGlobals(16)local ImportGlobals return (function(...)--!strict

local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Maid        = require(script.Parent.Parent.Utils.Maid)
local Theme       = require(script.Parent.Parent.Theme)
local SmoothScroll = require(script.Parent.Parent.Utils.SmoothScroll)

-- Architecture:
--   shell   — Frame centered on canvas. Has UIScale + background + UIStroke.
--             AutomaticSize.Y grows with content.
--   content — Frame INSIDE shell. Fills shell width. Has all text/buttons.
--
-- Stack behaviour:
--   Stacking infrastructure is preserved but disabled — only one popup at a time.
--   A second Popup.show call while one is already open is silently ignored.
--   To re-enable stacking: remove the #_stack > 0 guard in Popup.show.
--   ONE shared dim overlay for the stack. Created on first open, destroyed on last close.
--   Each shell gets its own ZIndex tier (BASE_Z + stackIdx * STRIDE).
--   Stack depth badge appears on shells beyond the first (dormant while stacking disabled).

local TWEEN_OPEN_SCALE    = TweenInfo.new(0.38, Enum.EasingStyle.Back,        Enum.EasingDirection.Out)
local TWEEN_FADE_IN       = TweenInfo.new(0.28, Enum.EasingStyle.Exponential,  Enum.EasingDirection.Out)

local TWEEN_CONFIRM_SCALE = TweenInfo.new(0.42, Enum.EasingStyle.Exponential, Enum.EasingDirection.In)
local TWEEN_CONFIRM_FADE  = TweenInfo.new(0.32, Enum.EasingStyle.Exponential, Enum.EasingDirection.In)

local TWEEN_CLOSE_SCALE   = TweenInfo.new(0.32, Enum.EasingStyle.Quint,       Enum.EasingDirection.In)
local TWEEN_FADE_OUT      = TweenInfo.new(0.24, Enum.EasingStyle.Quint,       Enum.EasingDirection.In)

local SCALE_OPEN          = 1.08
local SCALE_CLOSE_CANCEL  = 1.82
local SCALE_CLOSE_CONFIRM = 2.32

local CARD_W = 290

-- Dim sits at ZIndex 3 in root (above canvas at ZIndex 2, below shells at 50+).
-- Shell/badge live in root too so they render above the dim regardless of CanvasGroup.
local DIM_Z       = 3
local BASE_Z      = 50
local Z_STRIDE    = 10
local Z_SHELL     = 1
local Z_CONTENT   = 2
local Z_BTN       = 3
local Z_BADGE     = 4

local STACK_OFFSET_PX = 5

export type PopupConfig = {
	Title:       string,
	Message:     string,
	OnConfirm:   () -> (),
	OnCancel:    (() -> ())?,
	ConfirmText: string?,
	CancelText:  string?,
}

-- ── Module-level state ────────────────────────────────────────────────────────
local _stack:     { any }   = {}
local _sharedDim: Frame?    = nil   -- singleton overlay; nil when no popups are open

-- ── helpers ───────────────────────────────────────────────────────────────────

local function corner(inst: Instance, r: number)
	local c        = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r)
	c.Parent       = inst
end

local function makeActionBtn(
	text:     string,
	bg:       Color3,
	fg:       Color3,
	order:    number,
	zIndex:   number,
	parent:   Instance,
	isAccent: boolean?
): TextButton
	local btn                  = Instance.new("TextButton")
	btn.Name                   = text .. "Btn"
	btn.AutomaticSize          = Enum.AutomaticSize.X
	btn.Size                   = UDim2.fromOffset(0, 30)
	btn.BackgroundColor3       = bg
	btn.BorderSizePixel        = 0
	btn.Font                   = Theme.Font.Body
	btn.Text                   = text
	btn.TextSize               = Theme.TextSize.Body
	btn.TextColor3             = fg
	btn.AutoButtonColor        = false
	btn.BackgroundTransparency = 1
	btn.TextTransparency       = 1
	btn.LayoutOrder            = order
	btn.ZIndex                 = zIndex
	btn:SetAttribute("IsAccent", isAccent == true)
	corner(btn, Theme.Radius.Small)
	local p        = Instance.new("UIPadding")
	p.PaddingLeft  = UDim.new(0, Theme.Spacing.M)
	p.PaddingRight = UDim.new(0, Theme.Spacing.M)
	p.Parent       = btn
	btn.Parent     = parent
	return btn
end

-- ── Shared dim management ─────────────────────────────────────────────────────

-- Called when the first popup opens. Creates the dim once and fades it in.
local function acquireDim(canvas: Frame)
	if _sharedDim then return end   -- already alive from a previous popup in the stack

	local dim                  = Instance.new("Frame")
	dim.Name                   = "PopupDim"
	dim.Size                   = UDim2.fromScale(1, 1)
	dim.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
	dim.BackgroundTransparency = 1
	dim.BorderSizePixel        = 0
	dim.ZIndex                 = DIM_Z
	dim.Active                 = true   -- blocks input through the overlay immediately
	corner(dim, Theme.Radius.Medium)    -- match canvas rounded corners so dim doesn't bleed past window edge
	dim.Parent                 = canvas.Parent  -- root level: sits above canvas (ZIndex 2) so CanvasGroup no longer flattens the block

	_sharedDim = dim
	TweenService:Create(dim, TWEEN_FADE_IN, { BackgroundTransparency = 0.45 }):Play()
end

-- Called when any popup closes. Fades and destroys the dim only when the stack
-- is fully empty — intermediate closes leave it untouched.
local function releaseDim(fadeInfo: TweenInfo)
	if #_stack > 0 then return end   -- still popups alive; keep the dim

	local dim = _sharedDim
	if not dim then return end
	_sharedDim = nil

	TweenService:Create(dim, fadeInfo, { BackgroundTransparency = 1 }):Play()
	task.delay(fadeInfo.Time + 0.02, function()
		if dim and dim.Parent then
			dim:Destroy()
		end
	end)
end

-- ── Popup.show ────────────────────────────────────────────────────────────────

local Popup = {}

function Popup.show(canvas: Frame, config: PopupConfig)
	-- Only one popup at a time. Stacking infra is preserved — remove this guard to re-enable.
	if #_stack > 0 then return end

	local maid = Maid.new()

	-- Stack index computed BEFORE push — determines ZIndex tier and visual offset.
	local stackIdx = #_stack + 1

	local shellZ   = BASE_Z + (stackIdx - 1) * Z_STRIDE + Z_SHELL
	local contentZ = BASE_Z + (stackIdx - 1) * Z_STRIDE + Z_CONTENT
	local btnZ     = BASE_Z + (stackIdx - 1) * Z_STRIDE + Z_BTN
	local badgeZ   = BASE_Z + (stackIdx - 1) * Z_STRIDE + Z_BADGE

	local offsetPx = (stackIdx - 1) * STACK_OFFSET_PX

	-- Ensure the ONE shared dim is alive (no-op if already exists).
	acquireDim(canvas)

	-- Block hover + click events on canvas content. Interactable=false propagates to all
	-- descendants — every toggle, button, dropdown goes completely dead while popup is open.
	-- Wrapped in pcall: older clients without the Interactable property degrade gracefully.
	pcall(function() (canvas :: any).Interactable = false end)
	maid:GiveTask(function() pcall(function() (canvas :: any).Interactable = true end) end)

	-- Freeze all SmoothScroll-managed frames while this popup is open.
	-- Sidebar tab buttons remain interactive (they are outside canvas, not managed).
	SmoothScroll.setPaused(true)
	maid:GiveTask(function() SmoothScroll.setPaused(false) end)

	-- ── Shell ─────────────────────────────────────────────────────────────────
	local shell                  = Instance.new("Frame")
	shell.Name                   = "PopupShell"
	shell.AnchorPoint            = Vector2.new(0.5, 0.5)
	shell.Position               = UDim2.new(0.5, offsetPx, 0.5, offsetPx)
	shell.Size                   = UDim2.fromOffset(CARD_W, 0)
	shell.AutomaticSize          = Enum.AutomaticSize.Y
	shell.BackgroundColor3       = Theme.Colors.Surface
	shell.BackgroundTransparency = 1
	shell.BorderSizePixel        = 0
	shell.ZIndex                 = shellZ
	shell.ClipsDescendants       = false
	corner(shell, Theme.Radius.Medium)
	shell.Parent = canvas.Parent  -- root level: above dim (ZIndex 3) so confirm/cancel stay interactive
	maid:GiveTask(shell)

	local shellScale       = Instance.new("UIScale")
	shellScale.Scale       = SCALE_OPEN
	shellScale.Parent      = shell

	local shellStroke           = Instance.new("UIStroke")
	shellStroke.Color           = Theme.Colors.Border
	shellStroke.Thickness       = 1
	shellStroke.Transparency    = 1
	shellStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	shellStroke.Parent          = shell

	-- ── Stack depth badge ─────────────────────────────────────────────────────
	local stackBadge: Frame? = nil
	if stackIdx > 1 then
		local badge                  = Instance.new("Frame")
		badge.Name                   = "StackBadge"
		badge.AnchorPoint            = Vector2.new(1, 0)
		badge.Position               = UDim2.new(1, 10, 0, -10)
		badge.Size                   = UDim2.fromOffset(22, 22)
		badge.BackgroundColor3       = Theme.Colors.Accent
		badge.BackgroundTransparency = 1
		badge.BorderSizePixel        = 0
		badge.ZIndex                 = badgeZ
		corner(badge, 11)
		badge.Parent = shell
		maid:GiveTask(badge)

		local badgeLbl                  = Instance.new("TextLabel")
		badgeLbl.Name                   = "StackCount"
		badgeLbl.Size                   = UDim2.fromScale(1, 1)
		badgeLbl.BackgroundTransparency = 1
		badgeLbl.Font                   = Theme.Font.Title
		badgeLbl.Text                   = tostring(stackIdx)
		badgeLbl.TextSize               = 11
		badgeLbl.TextColor3             = Color3.fromRGB(10, 10, 10)
		badgeLbl.TextTransparency       = 1
		badgeLbl.TextXAlignment         = Enum.TextXAlignment.Center
		badgeLbl.TextYAlignment         = Enum.TextYAlignment.Center
		badgeLbl.ZIndex                 = badgeZ + 1
		badgeLbl.Parent                 = badge

		stackBadge = badge

		task.delay(0.08, function()
			if not badge.Parent then return end
			TweenService:Create(badge,    TWEEN_FADE_IN, { BackgroundTransparency = 0 }):Play()
			TweenService:Create(badgeLbl, TWEEN_FADE_IN, { TextTransparency       = 0 }):Play()
		end)
	end

	-- ── Content ───────────────────────────────────────────────────────────────
	local content                  = Instance.new("Frame")
	content.Name                   = "PopupContent"
	content.Size                   = UDim2.fromScale(1, 0)
	content.AutomaticSize          = Enum.AutomaticSize.Y
	content.BackgroundTransparency = 1
	content.BorderSizePixel        = 0
	content.ZIndex                 = contentZ
	content.Parent                 = shell
	maid:GiveTask(content)

	local pad         = Instance.new("UIPadding")
	pad.PaddingTop    = UDim.new(0, Theme.Spacing.M)
	pad.PaddingBottom = UDim.new(0, Theme.Spacing.M)
	pad.PaddingLeft   = UDim.new(0, Theme.Spacing.M)
	pad.PaddingRight  = UDim.new(0, Theme.Spacing.M)
	pad.Parent        = content

	local contentLayout               = Instance.new("UIListLayout")
	contentLayout.FillDirection       = Enum.FillDirection.Vertical
	contentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	contentLayout.SortOrder           = Enum.SortOrder.LayoutOrder
	contentLayout.Padding             = UDim.new(0, Theme.Spacing.S)
	contentLayout.Parent              = content

	-- ── Title ─────────────────────────────────────────────────────────────────
	local titleLbl                  = Instance.new("TextLabel")
	titleLbl.Name                   = "Title"
	titleLbl.AutomaticSize          = Enum.AutomaticSize.Y
	titleLbl.Size                   = UDim2.new(1, 0, 0, 0)
	titleLbl.BackgroundTransparency = 1
	titleLbl.Font                   = Theme.Font.Title
	titleLbl.Text                   = config.Title
	titleLbl.TextSize               = Theme.TextSize.Body
	titleLbl.TextColor3             = Theme.Colors.TextPrimary
	titleLbl.TextTransparency       = 1
	titleLbl.TextXAlignment         = Enum.TextXAlignment.Left
	titleLbl.TextWrapped            = true
	titleLbl.RichText               = false
	titleLbl.LayoutOrder            = 0
	titleLbl.ZIndex                 = btnZ
	titleLbl.Parent                 = content

	-- ── Message ───────────────────────────────────────────────────────────────
	local msgLbl                  = Instance.new("TextLabel")
	msgLbl.Name                   = "Message"
	msgLbl.AutomaticSize          = Enum.AutomaticSize.Y
	msgLbl.Size                   = UDim2.new(1, 0, 0, 0)
	msgLbl.BackgroundTransparency = 1
	msgLbl.Font                   = Theme.Font.Body
	msgLbl.Text                   = config.Message
	msgLbl.TextSize               = Theme.TextSize.Small
	msgLbl.TextColor3             = Theme.Colors.TextSecondary
	msgLbl.TextTransparency       = 1
	msgLbl.TextXAlignment         = Enum.TextXAlignment.Left
	msgLbl.TextWrapped            = true
	msgLbl.RichText               = false
	msgLbl.LayoutOrder            = 1
	msgLbl.ZIndex                 = btnZ
	msgLbl.Parent                 = content

	-- ── Divider ───────────────────────────────────────────────────────────────
	local divider                  = Instance.new("Frame")
	divider.Name                   = "Divider"
	divider.Size                   = UDim2.new(1, 0, 0, 1)
	divider.BackgroundColor3       = Theme.Colors.Border
	divider.BackgroundTransparency = 1
	divider.BorderSizePixel        = 0
	divider.LayoutOrder            = 2
	divider.ZIndex                 = btnZ
	divider.Parent                 = content

	-- ── Button row ────────────────────────────────────────────────────────────
	local btnRow                  = Instance.new("Frame")
	btnRow.Name                   = "ButtonRow"
	btnRow.Size                   = UDim2.new(1, 0, 0, 0)
	btnRow.AutomaticSize          = Enum.AutomaticSize.Y
	btnRow.BackgroundTransparency = 1
	btnRow.BorderSizePixel        = 0
	btnRow.LayoutOrder            = 3
	btnRow.ZIndex                 = btnZ
	btnRow.Parent                 = content

	local btnLayout               = Instance.new("UIListLayout")
	btnLayout.FillDirection       = Enum.FillDirection.Horizontal
	btnLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	btnLayout.VerticalAlignment   = Enum.VerticalAlignment.Center
	btnLayout.Padding             = UDim.new(0, Theme.Spacing.XS)
	btnLayout.SortOrder           = Enum.SortOrder.LayoutOrder
	btnLayout.Parent              = btnRow

	-- ── Animation helpers ─────────────────────────────────────────────────────

	local function tweenShell(ti: TweenInfo, bgT: number, strokeT: number)
		TweenService:Create(shell,       ti, { BackgroundTransparency = bgT     }):Play()
		TweenService:Create(shellStroke, ti, { Transparency           = strokeT }):Play()
	end

	local function tweenContent(ti: TweenInfo, textT: number, divT: number, closing: boolean)
		TweenService:Create(titleLbl, ti, { TextTransparency       = textT }):Play()
		TweenService:Create(msgLbl,   ti, { TextTransparency       = textT }):Play()
		TweenService:Create(divider,  ti, { BackgroundTransparency = divT  }):Play()
		for _, child in ipairs(btnRow:GetChildren()) do
			if not child:IsA("TextButton") then continue end
			local isAccent  = child:GetAttribute("IsAccent") == true
			local targetBgT = closing and 1 or (isAccent and 0 or 0.94)
			TweenService:Create(child, ti, {
				BackgroundTransparency = targetBgT,
				TextTransparency       = textT,
			}):Play()
		end
	end

	local function tweenBadge(ti: TweenInfo, transparency: number)
		if not stackBadge then return end
		local lbl = stackBadge:FindFirstChild("StackCount")
		TweenService:Create(stackBadge, ti, { BackgroundTransparency = transparency }):Play()
		if lbl then
			TweenService:Create(lbl, ti, { TextTransparency = transparency }):Play()
		end
	end

	-- ── Close sequences ───────────────────────────────────────────────────────
	local closed    = false
	local confirmBtn: TextButton

	local function closePopup()
		if closed then return end
		closed = true

		for i = #_stack, 1, -1 do
			if _stack[i] == maid then table.remove(_stack, i) break end
		end

		-- Release shared dim only if this was the last popup in the stack.
		releaseDim(TWEEN_FADE_OUT)

		tweenBadge(TWEEN_FADE_OUT, 1)
		tweenContent(TWEEN_FADE_OUT, 1, 1, true)
		TweenService:Create(shellScale, TWEEN_CLOSE_SCALE, { Scale = SCALE_CLOSE_CANCEL }):Play()
		tweenShell(TWEEN_FADE_OUT, 1, 1)

		task.delay(TWEEN_CLOSE_SCALE.Time + 0.02, function()
			maid:DoCleaning()
		end)
	end

	local function closeConfirm()
		if closed then return end
		closed = true

		for i = #_stack, 1, -1 do
			if _stack[i] == maid then table.remove(_stack, i) break end
		end

		releaseDim(TWEEN_CONFIRM_FADE)

		local btnScale = Instance.new("UIScale")
		btnScale.Scale = 1
		btnScale.Parent = confirmBtn

		tweenBadge(TWEEN_CONFIRM_FADE, 1)

		TweenService:Create(btnScale,   TWEEN_CONFIRM_SCALE, { Scale = 1.22 }):Play()
		TweenService:Create(confirmBtn, TWEEN_CONFIRM_FADE, {
			BackgroundTransparency = 1,
			TextTransparency       = 1,
		}):Play()

		TweenService:Create(shellScale, TWEEN_CONFIRM_SCALE, { Scale = SCALE_CLOSE_CONFIRM }):Play()
		tweenShell(TWEEN_CONFIRM_FADE, 1, 1)

		TweenService:Create(titleLbl, TWEEN_CONFIRM_FADE, { TextTransparency = 1 }):Play()
		TweenService:Create(msgLbl,   TWEEN_CONFIRM_FADE, { TextTransparency = 1 }):Play()
		TweenService:Create(divider,  TWEEN_CONFIRM_FADE, { BackgroundTransparency = 1 }):Play()
		for _, child in ipairs(btnRow:GetChildren()) do
			if child:IsA("TextButton") then
				TweenService:Create(child, TWEEN_CONFIRM_FADE, {
					BackgroundTransparency = 1,
					TextTransparency       = 1,
				}):Play()
			end
		end

		task.delay(TWEEN_CONFIRM_SCALE.Time + 0.02, function()
			maid:DoCleaning()
		end)
	end

	-- ── Cancel button ─────────────────────────────────────────────────────────
	if config.OnCancel then
		local cancelBtn = makeActionBtn(
			config.CancelText or "Cancel",
			Theme.Colors.SurfaceHover,
			Theme.Colors.TextSecondary,
			0,
			btnZ,
			btnRow,
			false
		)
		local cancelStroke           = Instance.new("UIStroke")
		cancelStroke.Color           = Theme.Colors.Border
		cancelStroke.Thickness       = 1
		cancelStroke.Transparency    = 1
		cancelStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		cancelStroke.Parent          = cancelBtn

		maid:GiveTask(cancelBtn.MouseButton1Click:Connect(function()
			closePopup()
			if config.OnCancel then config.OnCancel() end
		end))
		maid:GiveTask(cancelBtn.MouseEnter:Connect(function()
			cancelBtn.BackgroundColor3 = Theme.Colors.SurfaceActive
			cancelBtn.TextColor3       = Theme.Colors.TextPrimary
		end))
		maid:GiveTask(cancelBtn.MouseLeave:Connect(function()
			cancelBtn.BackgroundColor3 = Theme.Colors.SurfaceHover
			cancelBtn.TextColor3       = Theme.Colors.TextSecondary
		end))
	end

	-- ── Confirm button ────────────────────────────────────────────────────────
	confirmBtn = makeActionBtn(
		config.ConfirmText or "Confirm",
		Theme.Colors.Accent,
		Color3.fromRGB(10, 10, 10),
		1,
		btnZ,
		btnRow,
		true
	)

	maid:GiveTask(confirmBtn.MouseButton1Click:Connect(function()
		closeConfirm()
		config.OnConfirm()
	end))
	maid:GiveTask(confirmBtn.MouseEnter:Connect(function()
		confirmBtn.BackgroundColor3 = Theme.Colors.AccentHover
	end))
	maid:GiveTask(confirmBtn.MouseLeave:Connect(function()
		confirmBtn.BackgroundColor3 = Theme.Colors.Accent
	end))

	-- ── Push + escape ─────────────────────────────────────────────────────────
	table.insert(_stack, maid)

	maid:GiveTask(UserInputService.InputBegan:Connect(function(input: InputObject, gpe: boolean)
		if gpe then return end
		if input.KeyCode ~= Enum.KeyCode.Escape then return end
		if _stack[#_stack] == maid then
			closePopup()
		end
	end))

	-- ── Open animation ────────────────────────────────────────────────────────
	shell.BackgroundTransparency = 1
	shellStroke.Transparency     = 1

	TweenService:Create(shellScale, TWEEN_OPEN_SCALE, { Scale = 1 }):Play()
	tweenShell(TWEEN_FADE_IN, 0, 0.88)

	task.delay(0.06, function()
		if closed then return end
		tweenContent(TWEEN_FADE_IN, 0, 0.9, false)
	end)
end

return Popup

end)() end,
    function()local wax,script,require=ImportGlobals(17)local ImportGlobals return (function(...)--!strict

-- SaveManager — singleton flag registry + persistence layer.
-- Components register their own get/set callbacks via Register().
-- Save/Load use executor writefile/readfile (pcall-guarded, silent on failure).
-- AutoSave fires on every component Changed event (debounced 0.5s).
-- _loading guard prevents autosave loops during Load().
-- _pendingLoad carries forward flags loaded before a component registered.

local HttpService = game:GetService("HttpService")

-- ── Types ─────────────────────────────────────────────────────────────────────

type FlagEntry = {
	get : () -> any,
	set : (value: any) -> (),
}

-- ── Module state ──────────────────────────────────────────────────────────────

local SaveManager = {}
SaveManager.__index = SaveManager

-- Live flag values exposed to the outside world.
-- Read-only by convention — components update via their own SetValue, not here.
local Flags: { [string]: any } = {}

local _registry    : { [string]: FlagEntry } = {}
local _pendingLoad : { [string]: any }        = {}  -- deserialized values for late-registered flags
local _folder      : string  = "Delirium"
local _loading     : boolean = false
local _loaded      : boolean = false

-- ── Helpers ───────────────────────────────────────────────────────────────────

local function filePath(): string
	return _folder .. "/flags.json"
end

-- Serializes a KeyCode to its name string so it survives JSON round-trips.
local function serializeValue(v: any): any
	if typeof(v) == "EnumItem" then
		return { __enumType = "KeyCode", __name = (v :: Enum.KeyCode).Name }
	end
	return v
end

-- Inverse of serializeValue.
local function deserializeValue(v: any): any
	if type(v) == "table" and v.__enumType == "KeyCode" then
		local ok, result = pcall(function()
			return (Enum.KeyCode :: any)[v.__name]
		end)
		if ok and result then
			return result
		end
	end
	return v
end

-- ── Public API ────────────────────────────────────────────────────────────────

-- Derives a deterministic flag name from a human-readable label.
-- Lowercase, spaces → underscore, non-alphanumeric stripped, capped at 48 chars.
-- Returns "" if the result is empty (caller should skip registration).
function SaveManager.deriveFlagFromName(label: string): string
	local sanitized = label
		:lower()
		:gsub("%s+", "_")
		:gsub("[^%w_]", "")
		:sub(1, 48)
	return sanitized
end

-- Register a flag. Called by components in their constructor.
-- get() must return the current value.
-- set(value) must apply the value WITHOUT firing Changed (to avoid autoSave loops).
-- If Load() already ran and this flag had a stored value, it is applied immediately.
function SaveManager.Register(flag: string, get: () -> any, set: (value: any) -> ())
	-- Silent overwrite: Studio's module cache keeps the singleton alive between re-runs,
	-- so duplicate registration is expected noise, not a real collision.
	-- Components that genuinely share a flag name will still silently clobber each other
	-- (which is the correct behavior — last writer wins, first load wins via _pendingLoad).
	_registry[flag] = { get = get, set = set }
	Flags[flag]     = get()

	-- Apply any value that was loaded before this component registered.
	local pending = _pendingLoad[flag]
	if pending ~= nil then
		pcall(set, pending)
		Flags[flag] = pending
		-- Do NOT clear from _pendingLoad — a second Register (duplicate) may need it.
	end
end

-- Change the folder name. Call before Load/Save.
function SaveManager.SetFolder(name: string)
	_folder = name
end

-- Serialize all flags to JSON and write to disk.
-- Silent no-op if writefile is not available (non-executor context).
function SaveManager.Save()
	local data: { [string]: any } = {}
	for flag, entry in pairs(_registry) do
		local v = entry.get()
		Flags[flag] = v
		data[flag] = serializeValue(v)
	end

	local ok, encoded = pcall(HttpService.JSONEncode, HttpService, data)
	if not ok then return end

	-- writefile is an executor global — not available in Studio/live Roblox.
	local wfOk = pcall(function()
		local writefile = (getfenv and getfenv(0).writefile) or rawget(_G, "writefile")
		if type(writefile) == "function" then
			-- makefolder if available — ignore errors
			local makefolder = (getfenv and getfenv(0).makefolder) or rawget(_G, "makefolder")
			if type(makefolder) == "function" then
				pcall(makefolder, _folder)
			end
			writefile(filePath(), encoded)
		end
	end)
	_ = wfOk
end

-- Read from disk and apply to all registered flags.
-- Flags that have no registered entry yet are stored in _pendingLoad
-- and applied the moment their component calls Register().
function SaveManager.Load()
	local raw: string? = nil

	pcall(function()
		local readfile = (getfenv and getfenv(0).readfile) or rawget(_G, "readfile")
		if type(readfile) ~= "function" then return end

		local isfile = (getfenv and getfenv(0).isfile) or rawget(_G, "isfile")
		if type(isfile) == "function" and not isfile(filePath()) then return end

		raw = readfile(filePath())
	end)

	if not raw or raw == "" then return end

	local ok, data = pcall(HttpService.JSONDecode, HttpService, raw)
	if not ok or type(data) ~= "table" then return end

	-- Guard: suppress _scheduleAutoSave for the duration of Load.
	_loading = true

	for flag, rawValue in pairs(data) do
		local value = deserializeValue(rawValue)
		-- Store for any component that registers after this Load() call.
		_pendingLoad[flag] = value

		local entry = _registry[flag]
		if entry then
			pcall(entry.set, value)
			Flags[flag] = value
		end
	end

	_loading = false
	_loaded  = true
end

-- Called by components after Changed fires to persist the updated value.
-- Debounced at the module level to avoid hammering disk on rapid changes.
local _savePending = false
function SaveManager._scheduleAutoSave()
	if _loading then return end
	if _savePending then return end
	_savePending = true
	task.delay(0.5, function()
		_savePending = false
		SaveManager.Save()
	end)
end

-- Expose live Flags table (read-only by convention).
SaveManager.Flags = Flags

return SaveManager

end)() end,
    function()local wax,script,require=ImportGlobals(18)local ImportGlobals return (function(...)--!strict
-- Tab — a named content pane created by Window:AddTab().
-- Mirrors Window's Add* API so switching over is a one-word change.

local Maid       = require(script.Parent.Parent.Utils.Maid)
local Theme      = require(script.Parent.Parent.Theme)
local Components = require(script.Parent.Parent.Components)
local Groupbox   = require(script.Parent.Parent.Components.Groupbox)

-- ── Types ──────────────────────────────────────────────────────────────────

export type TabImpl = {
	-- public Add* methods (identical surface to Window)
	AddButton:      (self: TabImpl, config: any) -> any,
	AddToggle:      (self: TabImpl, config: any) -> any,
	AddSlider:      (self: TabImpl, config: any) -> any,
	AddTextbox:     (self: TabImpl, config: any) -> any,
	AddKeybind:     (self: TabImpl, config: any) -> any,
	AddDropdown:    (self: TabImpl, config: any) -> any,
	AddColorPicker: (self: TabImpl, config: any) -> any,
	AddLabel:       (self: TabImpl, text: string, color: Color3?) -> any,
	AddDescription: (self: TabImpl, config: any) -> any,
	AddDivider:     (self: TabImpl, text: string?) -> any,
	-- groupbox factory
	AddGroupbox: (self: TabImpl, titleA: string, titleB: string?) -> any,
	-- internals
	_maid:        any,
	_content:     ScrollingFrame,
	_gui:         ScreenGui,
	_canvas:      Frame?,
	_layoutOrder: number,
}

-- ── Class ──────────────────────────────────────────────────────────────────

local Tab = {} :: { __index: any }
Tab.__index = Tab

--[[
	Tab.new(pane, gui, windowMaid)

	pane        — the ScrollingFrame this tab owns
	gui         — the ScreenGui root (forwarded to Dropdown as OverlayParent)
	windowMaid  — the parent window's maid; owns this tab's maid so
	              destroying the window cascades cleanup into all tabs
]]
function Tab.new(pane: ScrollingFrame, gui: ScreenGui, windowMaid: any, canvas: Frame?): TabImpl
	local self        = setmetatable({}, Tab) :: TabImpl
	self._maid        = Maid.new()
	windowMaid:GiveTask(self._maid)  -- cascade: window destroy → tab destroy
	self._content     = pane
	self._gui         = gui
	self._canvas      = canvas
	self._layoutOrder = 0
	return self
end

-- ── Internal helpers ───────────────────────────────────────────────────────

function Tab:_nextOrder(): number
	self._layoutOrder += 1
	return self._layoutOrder
end

--[[
	_addToContent — identical logic to Window:_addToContent.
	Supports the optional `description` key for inline sub-labels.
	Dropdown list overflows; ClipsDescendants = false on wrapper lets it.
]]
function Tab:_addToContent(comp: any, config: any?): any
	local desc = config and (config.description or config.Description)

	if typeof(desc) == "string" and #desc > 0 then
		local compFrame       = comp:GetFrame()
		compFrame.LayoutOrder = 0

		local wrapper                  = Instance.new("Frame")
		wrapper.Name                   = "ComponentWrapper"
		wrapper.AutomaticSize          = Enum.AutomaticSize.Y
		wrapper.Size                   = UDim2.new(1, 0, 0, 0)
		wrapper.BackgroundTransparency = 1
		wrapper.BorderSizePixel        = 0
		wrapper.ClipsDescendants       = false
		wrapper.LayoutOrder            = config.LayoutOrder or 0
		wrapper.Parent                 = self._content

		local wLayout               = Instance.new("UIListLayout")
		wLayout.FillDirection       = Enum.FillDirection.Vertical
		wLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
		wLayout.SortOrder           = Enum.SortOrder.LayoutOrder
		wLayout.Padding             = UDim.new(0, Theme.Spacing.XS)
		wLayout.Parent              = wrapper

		compFrame.Parent = wrapper

		local descLabel                  = Instance.new("TextLabel")
		descLabel.Name                   = "ComponentDescription"
		descLabel.LayoutOrder            = 1
		descLabel.AutomaticSize          = Enum.AutomaticSize.Y
		descLabel.Size                   = UDim2.new(1, 0, 0, 0)
		descLabel.BackgroundTransparency = 1
		descLabel.BorderSizePixel        = 0
		descLabel.Font                   = Theme.Font.Body
		descLabel.Text                   = desc
		descLabel.TextSize               = Theme.TextSize.Small
		descLabel.TextColor3             = Theme.Colors.TextSecondary
		descLabel.TextXAlignment         = Enum.TextXAlignment.Left
		descLabel.TextWrapped            = true
		descLabel.RichText               = true
		descLabel.Parent                 = wrapper

		local descPad        = Instance.new("UIPadding")
		descPad.PaddingLeft  = UDim.new(0, Theme.Spacing.M)
		descPad.PaddingRight = UDim.new(0, Theme.Spacing.M)
		descPad.PaddingTop   = UDim.new(0, Theme.Spacing.XS)
		descPad.Parent       = descLabel

		local spacer                  = Instance.new("Frame")
		spacer.Name                   = "DescriptionSpacer"
		spacer.LayoutOrder            = 2
		spacer.BackgroundTransparency = 1
		spacer.BorderSizePixel        = 0
		spacer.Size                   = UDim2.fromOffset(0, Theme.Spacing.M)
		spacer.Parent                 = wrapper
	else
		comp:GetFrame().Parent = self._content
	end

	self._maid:GiveTask(comp)
	return comp
end

-- ── Public Add* API ────────────────────────────────────────────────────────

function Tab:AddButton(config: {
	Label: string, Variant: number?, Enabled: boolean?, description: string?,
})
	local c = config :: any
	c.LayoutOrder = self:_nextOrder()
	return self:_addToContent(Components.Button.new(c), c)
end

function Tab:AddToggle(config: {
	Label: string, Icon: string?, Default: boolean?, Enabled: boolean?, description: string?,
})
	local c = config :: any
	c.LayoutOrder = self:_nextOrder()
	return self:_addToContent(Components.Toggle.new(c), c)
end

function Tab:AddLabel(text: string, color: Color3?)
	local lbl = Components.Label.new({
		Text        = text,
		Color       = color,
		LayoutOrder = self:_nextOrder(),
	})
	return self:_addToContent(lbl, nil)
end

function Tab:AddDescription(config: { Title: string?, Description: string })
	local c = config :: any
	c.LayoutOrder = self:_nextOrder()
	local desc = Components.Description.new(c)
	desc:GetFrame().Parent = self._content
	self._maid:GiveTask(desc)
	return desc
end

function Tab:AddDivider(text: string?)
	local div = Components.Divider.new({
		Text        = text,
		LayoutOrder = self:_nextOrder(),
	})
	return self:_addToContent(div, nil)
end

function Tab:AddSlider(config: {
	Label: string, Min: number?, Max: number?,
	Default: number?, Step: number?, Enabled: boolean?, description: string?,
})
	local c = config :: any
	c.LayoutOrder = self:_nextOrder()
	return self:_addToContent(Components.Slider.new(c), c)
end

function Tab:AddTextbox(config: {
	Label: string?, Placeholder: string?, Default: string?,
	MaxLength: number?, ClearOnFocus: boolean?, Enabled: boolean?, description: string?,
})
	local c = config :: any
	c.LayoutOrder = self:_nextOrder()
	return self:_addToContent(Components.Textbox.new(c), c)
end

function Tab:AddKeybind(config: {
	Label: string, Default: Enum.KeyCode?,
	Blacklist: { any }?, Enabled: boolean?, description: string?,
})
	local c = config :: any
	c.LayoutOrder = self:_nextOrder()
	return self:_addToContent(Components.Keybind.new(c), c)
end

function Tab:AddDropdown(config: {
	Label: string?, Options: { any }, MultiSelect: boolean?,
	Default: any?, Placeholder: string?, Enabled: boolean?, description: string?,
})
	local c = config :: any
	c.LayoutOrder   = self:_nextOrder()
	c.OverlayParent = self._gui
	return self:_addToContent(Components.Dropdown.new(c), c)
end

function Tab:AddColorPicker(config: {
	Label: string, Default: Color3?, ShowAlpha: boolean?,
	Flag: string?, Risky: boolean?, Enabled: boolean?, description: string?,
})
	local c = config :: any
	c.LayoutOrder   = self:_nextOrder()
	c.OverlayParent = self._gui
	c.Canvas        = self._canvas
	return self:_addToContent(Components.ColorPicker.new(c), c)
end

-- ── Groupbox factory ─────────────────────────────────────────────────────────

--[[
	Tab:AddGroupbox(titleA, titleB?)

	Single column  — returns one  GroupboxImpl
	Two columns    — returns two  GroupboxImpl (left, right)

	Two-column layout: a transparent wrapper frame holds both boxes side-by-side
	with UDim2 relative sizing; wrapper AutomaticSize Y grows to the taller child.
	No UIListLayout on the wrapper — children are positioned, not stacked.
]]
function Tab:AddGroupbox(titleA: string, titleB: string?)
	if titleB then
		-- ── Two-column ──────────────────────────────────────────────────────
		local GAP = Theme.Spacing.XS  -- 4 px gutter between columns

		local wrapper                  = Instance.new("Frame")
		wrapper.Name                   = "GroupboxRow"
		wrapper.Size                   = UDim2.new(1, 0, 0, 0)
		wrapper.AutomaticSize          = Enum.AutomaticSize.Y
		wrapper.BackgroundTransparency = 1
		wrapper.BorderSizePixel        = 0
		wrapper.ClipsDescendants       = false
		wrapper.LayoutOrder            = self:_nextOrder()
		wrapper.Parent                 = self._content
		self._maid:GiveTask(wrapper)

		local leftBox  = Groupbox.new(titleA, self._gui, self._maid, self._canvas)
		local rightBox = Groupbox.new(titleB, self._gui, self._maid, self._canvas)

		local lf          = leftBox:GetFrame()
		lf.AnchorPoint    = Vector2.new(0, 0)
		lf.Position       = UDim2.new(0, 0, 0, 0)
		lf.Size           = UDim2.new(0.5, -(GAP // 2 + GAP % 2), 0, 0)  -- floor half-gap
		lf.Parent         = wrapper

		local rf          = rightBox:GetFrame()
		rf.AnchorPoint    = Vector2.new(0, 0)
		rf.Position       = UDim2.new(0.5, GAP // 2 + GAP % 2, 0, 0)    -- ceil half-gap
		rf.Size           = UDim2.new(0.5, -(GAP // 2 + GAP % 2), 0, 0)
		rf.Parent         = wrapper

		return leftBox, rightBox
	else
		-- ── Single column ───────────────────────────────────────────────────
		local box = Groupbox.new(titleA, self._gui, self._maid, self._canvas)
		local f   = box:GetFrame()
		f.LayoutOrder = self:_nextOrder()
		f.Parent      = self._content
		return box
	end
end

return Tab

end)() end,
    function()local wax,script,require=ImportGlobals(19)local ImportGlobals return (function(...)--!strict

local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local Players          = game:GetService("Players")

local Maid         = require(script.Parent.Parent.Utils.Maid)
local Theme        = require(script.Parent.Parent.Theme)
local Components   = require(script.Parent.Parent.Components)
local SmoothScroll = require(script.Parent.Parent.Utils.SmoothScroll)
local Tab          = require(script.Parent.Tab)

local TWEEN_OPEN     = TweenInfo.new(0.3,  Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local TWEEN_CLOSE    = TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
local TWEEN_TAB      = TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local TWEEN_GROUP    = TweenInfo.new(0.20, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local TWEEN_COLLAPSE = TweenInfo.new(0.45, Enum.EasingStyle.Exponential, Enum.EasingDirection.InOut)
local TWEEN_EXPAND   = TweenInfo.new(0.50, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)

-- Pill (hide/show morph) ─ same concept as Rayfield's collapsed pill
local PILL_SIZE = UDim2.fromOffset(185, 50)
local PILL_POS  = UDim2.new(0.5, 0, 0, 45) -- AnchorPoint(0.5,0.5) so center = 20+25 from top
local TWEEN_PILL_MORPH  = TweenInfo.new(0.45, Enum.EasingStyle.Exponential, Enum.EasingDirection.InOut)
local TWEEN_PILL_REVEAL = TweenInfo.new(0.50, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)

local DEFAULT_SIZE        = UDim2.fromOffset(500, 340)
local MIN_SIZE            = Vector2.new(300, 200)
local SIDEBAR_W_EXPANDED  = 136        -- trimmed from 148
local SIDEBAR_W_COLLAPSED = 40
local SIDEBAR_HEADER_H    = 44
local SIDEBAR_GAP         = 4
local TAB_ITEM_H          = 24
local TAB_SPACING         = 5          -- gap between tab rows / groups

-- Group geometry
local GROUP_HEADER_H      = 20
local GROUP_CHILD_GAP     = 3
local GROUP_CHILD_PAD_TOP = 4
local GROUP_CHILD_PAD_BOT = 4
local GROUP_CHILD_INDENT  = 6

-- Inactive tab gradient (matches component container gradient)
local TAB_GRAD_SEQ = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromHex("#2a2a2a")),
	ColorSequenceKeypoint.new(1, Color3.fromHex("#191919")),
})

export type WindowConfig = {
	Size: UDim2?,
	Position: UDim2?,
	MinSize: Vector2?,
}

-- ── GUI parenting ─────────────────────────────────────────────────────────────

local function getGui(): ScreenGui
	local gui          = Instance.new("ScreenGui")
	gui.Name           = "Window"
	gui.ResetOnSpawn   = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.IgnoreGuiInset = true
	pcall(function() gui.DisplayOrder = 999 end)

	local parentedToCoreGui = pcall(function()
		gui.Parent = game:GetService("CoreGui")
	end)

	if not parentedToCoreGui or not gui.Parent then
		local lp = Players.LocalPlayer
		if lp then
			local playerGui = lp:FindFirstChildOfClass("PlayerGui")
			if playerGui then
				gui.Parent = playerGui
			else
				gui.Parent = lp:WaitForChild("PlayerGui", 3)
			end
		end
	end

	if not gui.Parent then
		pcall(function() gui.Parent = game:GetService("StarterGui") end)
	end

	if not gui.Parent then
		warn("[Delirium] Window: failed to parent ScreenGui — window will not be visible.")
	end

	return gui
end

-- ── helpers ───────────────────────────────────────────────────────────────────

local function applyCorner(parent: Instance, radius: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = parent
end

local function applyStroke(parent: Instance, color: Color3, thickness: number): UIStroke
	local s = Instance.new("UIStroke")
	s.Color           = color
	s.Thickness       = thickness
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = parent
	return s
end

-- ── window hierarchy ──────────────────────────────────────────────────────────

local function buildWindow(title: string, cfg: WindowConfig)
	local targetSize = cfg.Size or DEFAULT_SIZE

	-- Root frame: unified container that holds both canvas (window) and sidebar as siblings
	local root                  = Instance.new("Frame")
	root.Name                   = "WindowRoot"
	root.Size                   = targetSize
	root.AnchorPoint            = Vector2.new(0.5, 0.5)
	root.Position               = cfg.Position or UDim2.fromScale(0.5, 0.5)
	root.BackgroundTransparency = 1
	root.BorderSizePixel        = 0
	root.ClipsDescendants       = false

	local canvas             = Instance.new("CanvasGroup")
	canvas.Name              = "WindowFrame"
	canvas.Size              = UDim2.fromScale(1, 1)
	canvas.Position          = UDim2.fromOffset(0, 0)
	canvas.AnchorPoint       = Vector2.new(0, 0)
	canvas.BackgroundColor3  = Theme.Colors.Surface
	canvas.BorderSizePixel   = 0
	canvas.GroupTransparency = 1
	canvas.ZIndex            = 2
	applyCorner(canvas, Theme.Radius.Medium)
	local stroke = applyStroke(canvas, Theme.Colors.Border, 1)
	stroke.Transparency = 1

	local titleBar            = Instance.new("Frame")
	titleBar.Name             = "TitleBar"
	titleBar.Size             = UDim2.new(1, 0, 0, Theme.TitleBarHeight)
	titleBar.BackgroundColor3 = Theme.Colors.TitleBar
	titleBar.BorderSizePixel  = 0
	applyCorner(titleBar, Theme.Radius.Medium)

	local cornerCover            = Instance.new("Frame")
	cornerCover.Name             = "CornerCover"
	cornerCover.Size             = UDim2.new(1, 0, 0, Theme.Radius.Medium)
	cornerCover.Position         = UDim2.new(0, 0, 1, -Theme.Radius.Medium)
	cornerCover.BackgroundColor3 = Theme.Colors.TitleBar
	cornerCover.BorderSizePixel  = 0
	cornerCover.Parent           = titleBar

	local titleLabel                  = Instance.new("TextLabel")
	titleLabel.Name                   = "TitleLabel"
	titleLabel.BackgroundTransparency = 1
	titleLabel.Position               = UDim2.fromOffset(Theme.Spacing.M, 0)
	titleLabel.Size                   = UDim2.new(1, -(Theme.Spacing.M + 108), 1, 0)
	titleLabel.Font                   = Theme.Font.Title
	titleLabel.Text                   = title
	titleLabel.TextSize               = Theme.TextSize.Title
	titleLabel.TextColor3             = Theme.Colors.TextPrimary
	titleLabel.TextXAlignment         = Enum.TextXAlignment.Left
	titleLabel.TextTruncate           = Enum.TextTruncate.AtEnd
	titleLabel.Parent                 = titleBar

	-- ── Title bar button row: Search | Settings | Minus | Collapse ─────────────
	local function mkTitleBtn(name: string, text: string, order: number): TextButton
		local b              = Instance.new("TextButton")
		b.Name               = name
		b.Size               = UDim2.fromOffset(20, 20)
		b.BackgroundColor3   = Theme.Colors.SurfaceHover
		b.Font               = Theme.Font.Body
		b.Text               = text
		b.TextSize           = 11
		b.TextColor3         = Theme.Colors.TextSecondary
		b.BorderSizePixel    = 0
		b.AutoButtonColor    = false
		applyCorner(b, 4)
		return b
	end

	local btnRow               = Instance.new("Frame")
	btnRow.Name                = "BtnRow"
	btnRow.AnchorPoint         = Vector2.new(1, 0.5)
	btnRow.Position            = UDim2.new(1, -8, 0.5, 0)
	btnRow.Size                = UDim2.fromOffset(0, 20)
	btnRow.AutomaticSize       = Enum.AutomaticSize.X
	btnRow.BackgroundTransparency = 1
	btnRow.BorderSizePixel     = 0

	local btnRowLayout                 = Instance.new("UIListLayout")
	btnRowLayout.FillDirection         = Enum.FillDirection.Horizontal
	btnRowLayout.VerticalAlignment     = Enum.VerticalAlignment.Center
	btnRowLayout.HorizontalAlignment   = Enum.HorizontalAlignment.Right
	btnRowLayout.SortOrder             = Enum.SortOrder.LayoutOrder
	btnRowLayout.Padding               = UDim.new(0, 4)
	btnRowLayout.Parent                = btnRow

	local searchBtn   = mkTitleBtn("SearchBtn",   "⊙", 1)
	local settingsBtn = mkTitleBtn("SettingsBtn", "⚙", 2)
	local minusBtn    = mkTitleBtn("MinusBtn",    "—", 3)
	local collapseBtn = mkTitleBtn("CollapseBtn", "✕", 4)
	searchBtn.LayoutOrder   = 1
	settingsBtn.LayoutOrder = 2
	minusBtn.LayoutOrder    = 3
	collapseBtn.LayoutOrder = 4
	searchBtn.Parent        = btnRow
	settingsBtn.Parent      = btnRow
	minusBtn.Parent         = btnRow
	collapseBtn.Parent      = btnRow
	btnRow.Parent           = titleBar

	local sep             = Instance.new("Frame")
	sep.Name              = "Separator"
	sep.Size              = UDim2.new(1, 0, 0, 1)
	sep.Position          = UDim2.new(0, 0, 0, Theme.TitleBarHeight)
	sep.BackgroundColor3  = Theme.Colors.Border
	sep.BorderSizePixel   = 0

	local content                      = Instance.new("ScrollingFrame")
	content.Name                       = "Content"
	content.Size                       = UDim2.new(1, 0, 1, -(Theme.TitleBarHeight + 1))
	content.Position                   = UDim2.new(0, 0, 0, Theme.TitleBarHeight + 1)
	content.BackgroundTransparency     = 1
	content.BorderSizePixel            = 0
	content.ScrollBarThickness         = 3
	content.ScrollBarImageColor3       = Theme.Colors.Border
	content.CanvasSize                 = UDim2.fromOffset(0, 0)
	content.AutomaticCanvasSize        = Enum.AutomaticSize.Y
	content.ClipsDescendants           = true

	local pad              = Instance.new("UIPadding")
	pad.PaddingTop         = UDim.new(0, Theme.Spacing.S)
	pad.PaddingBottom      = UDim.new(0, Theme.Spacing.S)
	pad.PaddingLeft        = UDim.new(0, Theme.Spacing.S)
	pad.PaddingRight       = UDim.new(0, Theme.Spacing.S)
	pad.Parent             = content

	local layout                   = Instance.new("UIListLayout")
	layout.FillDirection           = Enum.FillDirection.Vertical
	layout.HorizontalAlignment     = Enum.HorizontalAlignment.Left
	layout.SortOrder               = Enum.SortOrder.LayoutOrder
	layout.Padding                 = UDim.new(0, Theme.Spacing.XS)
	layout.Parent                  = content

	local handle              = Instance.new("Frame")
	handle.Name               = "ResizeHandle"
	handle.Size               = UDim2.fromOffset(18, 18)
	handle.Position           = UDim2.new(1, -18, 1, -18)
	handle.BackgroundColor3   = Theme.Colors.Accent
	handle.BackgroundTransparency = 0.65
	handle.BorderSizePixel    = 0
	handle.ZIndex             = 10
	applyCorner(handle, 3)

	titleBar.Parent = canvas
	sep.Parent      = canvas
	content.Parent  = canvas
	handle.Parent   = canvas
	canvas.Parent   = root

	return root, canvas, titleBar, content :: any, handle, stroke, titleLabel, sep
end

-- ── interaction setup ─────────────────────────────────────────────────────────

local function setupDrag(maid: any, titleBar: Frame, root: Frame)
	local dragging  = false
	local dragStart = Vector3.zero
	local startPos  = UDim2.fromOffset(0, 0)

	maid:GiveTask(titleBar.InputBegan:Connect(function(input: InputObject)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch then return end

		local btnRow_ = titleBar:FindFirstChild("BtnRow") :: Frame?
		if btnRow_ then
			local mouse = UserInputService:GetMouseLocation()
			local bPos  = btnRow_.AbsolutePosition
			local bSize = btnRow_.AbsoluteSize
			if mouse.X >= bPos.X and mouse.X <= bPos.X + bSize.X
				and mouse.Y >= bPos.Y and mouse.Y <= bPos.Y + bSize.Y then
				return
			end
		end

		dragging  = true
		dragStart = input.Position
		startPos  = root.Position
	end))

	maid:GiveTask(UserInputService.InputChanged:Connect(function(input: InputObject)
		if not dragging then return end
		if input.UserInputType ~= Enum.UserInputType.MouseMovement
			and input.UserInputType ~= Enum.UserInputType.Touch then return end

		local delta = input.Position - dragStart
		root.Position = UDim2.new(
			startPos.X.Scale, startPos.X.Offset + delta.X,
			startPos.Y.Scale, startPos.Y.Offset + delta.Y
		)
	end))

	maid:GiveTask(UserInputService.InputEnded:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end))
end

local function setupResize(maid: any, handle: Frame, root: Frame, minSize: Vector2)
	local resizing    = false
	local resizeStart = Vector3.zero
	local startSize   = UDim2.fromOffset(0, 0)

	maid:GiveTask(handle.InputBegan:Connect(function(input: InputObject)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch then return end
		resizing    = true
		resizeStart = input.Position
		startSize   = root.Size
	end))

	maid:GiveTask(UserInputService.InputChanged:Connect(function(input: InputObject)
		if not resizing then return end
		if input.UserInputType ~= Enum.UserInputType.MouseMovement
			and input.UserInputType ~= Enum.UserInputType.Touch then return end

		local delta = input.Position - resizeStart
		local newW  = math.max(minSize.X, startSize.X.Offset + delta.X)
		local newH  = math.max(minSize.Y, startSize.Y.Offset + delta.Y)
		root.Size   = UDim2.new(startSize.X.Scale, newW, startSize.Y.Scale, newH)
	end))

	maid:GiveTask(UserInputService.InputEnded:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			resizing = false
		end
	end))
end

local function setupTitleBtnHovers(
	maid: any,
	searchBtn: TextButton,
	settingsBtn: TextButton,
	minusBtn: TextButton,
	collapseBtn: TextButton
)
	-- search + settings: coming soon — subtle hover only
	for _, b in ipairs({ searchBtn, settingsBtn }) do
		maid:GiveTask(b.MouseEnter:Connect(function()
			b.BackgroundColor3 = Theme.Colors.SurfaceActive
			b.TextColor3       = Theme.Colors.TextPrimary
		end))
		maid:GiveTask(b.MouseLeave:Connect(function()
			b.BackgroundColor3 = Theme.Colors.SurfaceHover
			b.TextColor3       = Theme.Colors.TextSecondary
		end))
	end
	-- minus: destructive red
	maid:GiveTask(minusBtn.MouseEnter:Connect(function()
		minusBtn.BackgroundColor3 = Theme.Colors.Error
		minusBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
	end))
	maid:GiveTask(minusBtn.MouseLeave:Connect(function()
		minusBtn.BackgroundColor3 = Theme.Colors.SurfaceHover
		minusBtn.TextColor3       = Theme.Colors.TextSecondary
	end))
	-- collapse: neutral accent
	maid:GiveTask(collapseBtn.MouseEnter:Connect(function()
		collapseBtn.BackgroundColor3 = Theme.Colors.SurfaceActive
		collapseBtn.TextColor3       = Theme.Colors.TextPrimary
	end))
	maid:GiveTask(collapseBtn.MouseLeave:Connect(function()
		collapseBtn.BackgroundColor3 = Theme.Colors.SurfaceHover
		collapseBtn.TextColor3       = Theme.Colors.TextSecondary
	end))
end

-- ── Window class ──────────────────────────────────────────────────────────────

local Window = {} :: any
Window.__index = Window

function Window.new(title: string, options: WindowConfig?)
	local cfg  = options or {}
	local self = setmetatable({}, Window)

	self._maid             = Maid.new()
	self.Title             = title
	self._closing          = false
	self._collapsed        = false
	self._collapseAnimating = false
	self._expandedSize     = cfg.Size or DEFAULT_SIZE
	self._collapseBtn      = nil :: any
	self._minusBtn         = nil :: any
	self._handle           = nil :: any
	self._tabs             = nil :: any
	self._groups           = nil :: any
	self._sidebar          = nil :: any
	self._tabList          = nil :: any
	self._tabHost          = nil :: any
	self._sidebarToggle    = nil :: any
	self._sidebarExpanded  = true
	self._sidebarW         = SIDEBAR_W_EXPANDED
	self._activeTabIdx     = 0

	local gui = getGui()
	self._gui = gui
	self._maid:GiveTask(gui)

	local root, canvas, titleBar, content, handle, stroke, titleLabel, sep = buildWindow(title, cfg)
	root.Parent       = gui
	self._root        = root
	self._canvas      = canvas
	self._titleBar    = titleBar
	self._content     = content
	self._stroke      = stroke
	self._titleLabel  = titleLabel
	self._handle      = handle
	self._sep         = sep
	self._layoutOrder = 0

	-- pill / hide-restore state
	self._hidden        = false
	self._hideAnimating = false
	self._savedPosition = nil :: UDim2?
	self._pillDot       = nil :: any
	self._pillTitle     = nil :: any
	self._pillSub       = nil :: any
	self._pillInteract  = nil :: any

	local minSize = cfg.MinSize or MIN_SIZE

	setupDrag(self._maid, titleBar, root)
	setupResize(self._maid, handle, root, minSize)

	self._maid:GiveTask(SmoothScroll.blockRegion(root))
	self._maid:GiveTask(SmoothScroll.blockRegion(titleBar))
	self._maid:GiveTask(SmoothScroll.apply(content))

	local btnRow_w      = titleBar:FindFirstChild("BtnRow")
	local searchBtn_w   = btnRow_w and btnRow_w:FindFirstChild("SearchBtn")   :: TextButton?
	local settingsBtn_w = btnRow_w and btnRow_w:FindFirstChild("SettingsBtn") :: TextButton?
	local minusBtn_w    = btnRow_w and btnRow_w:FindFirstChild("MinusBtn")    :: TextButton?
	local collapseBtn_w = btnRow_w and btnRow_w:FindFirstChild("CollapseBtn") :: TextButton?
	self._collapseBtn   = collapseBtn_w
	self._minusBtn      = minusBtn_w

	if searchBtn_w and settingsBtn_w and minusBtn_w and collapseBtn_w then
		setupTitleBtnHovers(
			self._maid,
			searchBtn_w   :: TextButton,
			settingsBtn_w :: TextButton,
			minusBtn_w,
			collapseBtn_w
		)
		self._maid:GiveTask(minusBtn_w.MouseButton1Click:Connect(function()
			self:_toggleCollapse()
		end))
		self._maid:GiveTask(collapseBtn_w.MouseButton1Click:Connect(function()
			self:ToggleHide()
		end))
	end

	-- Frame-zero guard: Visible=false means Roblox never renders the uninitialised
	-- CanvasGroup composite buffer, so nothing can flash white on first open.
	-- task.defer lets one render cycle pass, then we flip Visible=true at GT=1
	-- and tween cleanly to 0. No Completed snap — that re-composite was itself
	-- causing an extra flash artifact.
	canvas.Visible = false
	task.defer(function()
		canvas.Visible           = true
		canvas.GroupTransparency = 1
		TweenService:Create(canvas, TWEEN_OPEN, { GroupTransparency = 0 }):Play()
		TweenService:Create(stroke, TWEEN_OPEN, { Transparency = 0 }):Play()
	end)

	self:_buildPillFace()

	return self
end

-- ── component factory helpers ─────────────────────────────────────────────────

function Window:_nextOrder(): number
	self._layoutOrder += 1
	return self._layoutOrder
end

function Window:_addToContent(comp: any, config: any?): any
	local desc = config and (config.description or config.Description)

	if typeof(desc) == "string" and #desc > 0 then
		local compFrame        = comp:GetFrame()
		compFrame.LayoutOrder  = 0

		local wrapper                  = Instance.new("Frame")
		wrapper.Name                   = "ComponentWrapper"
		wrapper.AutomaticSize          = Enum.AutomaticSize.Y
		wrapper.Size                   = UDim2.new(1, 0, 0, 0)
		wrapper.BackgroundTransparency = 1
		wrapper.BorderSizePixel        = 0
		wrapper.ClipsDescendants       = false
		wrapper.LayoutOrder            = config.LayoutOrder or 0
		wrapper.Parent                 = self._content

		local wLayout               = Instance.new("UIListLayout")
		wLayout.FillDirection       = Enum.FillDirection.Vertical
		wLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
		wLayout.SortOrder           = Enum.SortOrder.LayoutOrder
		wLayout.Padding             = UDim.new(0, Theme.Spacing.XS)
		wLayout.Parent              = wrapper

		compFrame.Parent = wrapper

		local descLabel                   = Instance.new("TextLabel")
		descLabel.Name                    = "ComponentDescription"
		descLabel.LayoutOrder             = 1
		descLabel.AutomaticSize           = Enum.AutomaticSize.Y
		descLabel.Size                    = UDim2.new(1, 0, 0, 0)
		descLabel.BackgroundTransparency  = 1
		descLabel.BorderSizePixel         = 0
		descLabel.Font                    = Theme.Font.Body
		descLabel.Text                    = desc
		descLabel.TextSize                = Theme.TextSize.Small
		descLabel.TextColor3              = Theme.Colors.TextSecondary
		descLabel.TextXAlignment          = Enum.TextXAlignment.Left
		descLabel.TextWrapped             = true
		descLabel.RichText                = true
		descLabel.Parent                  = wrapper

		local descPad        = Instance.new("UIPadding")
		descPad.PaddingLeft  = UDim.new(0, Theme.Spacing.M)
		descPad.PaddingRight = UDim.new(0, Theme.Spacing.M)
		descPad.PaddingTop   = UDim.new(0, Theme.Spacing.XS)
		descPad.Parent       = descLabel

		local spacer                     = Instance.new("Frame")
		spacer.Name                      = "DescriptionSpacer"
		spacer.LayoutOrder               = 2
		spacer.BackgroundTransparency    = 1
		spacer.BorderSizePixel           = 0
		spacer.Size                      = UDim2.fromOffset(0, Theme.Spacing.M)
		spacer.Parent                    = wrapper
	else
		comp:GetFrame().Parent = self._content
	end

	self._maid:GiveTask(comp)
	return comp
end

function Window:AddButton(config: { Label: string, Variant: number?, Enabled: boolean?, description: string? })
	local c = config :: any
	c.LayoutOrder = self:_nextOrder()
	return self:_addToContent(Components.Button.new(c), c)
end

function Window:AddToggle(config: { Label: string, Default: boolean?, Enabled: boolean?, description: string? })
	local c = config :: any
	c.LayoutOrder = self:_nextOrder()
	return self:_addToContent(Components.Toggle.new(c), c)
end

function Window:AddLabel(text: string, color: Color3?)
	local lbl = Components.Label.new({
		Text        = text,
		Color       = color,
		LayoutOrder = self:_nextOrder(),
	})
	return self:_addToContent(lbl, nil)
end

function Window:AddDescription(config: { Title: string?, Description: string })
	local c = config :: any
	c.LayoutOrder = self:_nextOrder()
	local desc = Components.Description.new(c)
	desc:GetFrame().Parent = self._content
	self._maid:GiveTask(desc)
	return desc
end

function Window:AddDivider(text: string?)
	local div = Components.Divider.new({
		Text        = text,
		LayoutOrder = self:_nextOrder(),
	})
	return self:_addToContent(div, nil)
end

function Window:AddSlider(config: {
	Label: string, Min: number?, Max: number?, Default: number?,
	Step: number?, Enabled: boolean?, description: string?,
})
	local c = config :: any
	c.LayoutOrder = self:_nextOrder()
	return self:_addToContent(Components.Slider.new(c), c)
end

function Window:AddTextbox(config: {
	Label: string?, Placeholder: string?, Default: string?, MaxLength: number?,
	ClearOnFocus: boolean?, Enabled: boolean?, description: string?,
})
	local c = config :: any
	c.LayoutOrder = self:_nextOrder()
	return self:_addToContent(Components.Textbox.new(c), c)
end

function Window:AddKeybind(config: {
	Label: string, Default: Enum.KeyCode?, Blacklist: { any }?,
	Enabled: boolean?, description: string?,
})
	local c = config :: any
	c.LayoutOrder = self:_nextOrder()
	return self:_addToContent(Components.Keybind.new(c), c)
end

-- ── Tab system ────────────────────────────────────────────────────────────────

function Window:_initTabSystem()
	if self._sidebar then return end

	self._content.Visible = false

	local BODY_TOP = Theme.TitleBarHeight + 1
	local canvas   = self._canvas
	local root     = self._root

	-- ── Sidebar frame (child of WindowRoot, pinned directly to left of window) ─
	-- CanvasGroup so UICorner masks ALL children (header, tabListBg, etc.)
	-- instead of just the sidebar's own background — fixes the sharp-corner bleed.
	local sidebar                  = Instance.new("CanvasGroup")
	sidebar.Name                   = "Sidebar"
	sidebar.AnchorPoint            = Vector2.new(0, 0)
	sidebar.Position               = UDim2.new(0, -SIDEBAR_W_EXPANDED - SIDEBAR_GAP, 0, 0)
	sidebar.Size                   = UDim2.new(0, SIDEBAR_W_EXPANDED, 1, 0)
	sidebar.BackgroundColor3       = Theme.Colors.TitleBar
	sidebar.BorderSizePixel        = 0
	sidebar.ClipsDescendants       = true
	sidebar.GroupTransparency      = 0
	sidebar.ZIndex                 = 1
	sidebar.Parent                 = root
	self._sidebar                  = sidebar
	self._sidebarExpanded          = true
	self._sidebarW                 = SIDEBAR_W_EXPANDED
	self._maid:GiveTask(SmoothScroll.blockRegion(sidebar))
	applyCorner(sidebar, Theme.Radius.Medium)
	applyStroke(sidebar, Theme.Colors.Border, 1)

	-- Smooth collapse/expand animation
	local function updateSidebarWidth(expanded: boolean)
		local targetW = if expanded then SIDEBAR_W_EXPANDED else SIDEBAR_W_COLLAPSED
		TweenService:Create(sidebar, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			Position = UDim2.new(0, -targetW - SIDEBAR_GAP, 0, 0),
			Size     = UDim2.new(0, targetW, 1, 0),
		}):Play()
	end
	self._updateSidebarWidth = updateSidebarWidth

	-- ── Sidebar header (TitleBar color — same as window) ──────────────────────
	local header                  = Instance.new("Frame")
	header.Name                   = "SidebarHeader"
	header.Size                   = UDim2.new(1, 0, 0, SIDEBAR_HEADER_H)
	header.Position               = UDim2.fromOffset(0, 0)
	header.BackgroundColor3       = Theme.Colors.TitleBar
	header.BackgroundTransparency = 0
	header.BorderSizePixel        = 0
	header.ZIndex                 = 5
	header.Parent                 = sidebar

	-- Separator — identical to window titlebar separator (full width, 1px, Border)
	local sidebarSep             = Instance.new("Frame")
	sidebarSep.Name              = "SidebarSep"
	sidebarSep.Size              = UDim2.new(1, 0, 0, 1)
	sidebarSep.Position          = UDim2.fromOffset(0, SIDEBAR_HEADER_H)
	sidebarSep.BackgroundColor3  = Theme.Colors.Border
	sidebarSep.BorderSizePixel   = 0
	sidebarSep.ZIndex            = 6
	sidebarSep.Parent            = sidebar

	-- "SubTab" label inside header
	local headerLabel                  = Instance.new("TextLabel")
	headerLabel.Name                   = "HeaderLabel"
	headerLabel.Position               = UDim2.fromOffset(10, 0)
	headerLabel.Size                   = UDim2.new(1, -44, 1, 0)
	headerLabel.BackgroundTransparency = 1
	headerLabel.BorderSizePixel        = 0
	headerLabel.Font                   = Theme.Font.Subtitle
	headerLabel.Text                   = "SubTab"
	headerLabel.TextSize               = Theme.TextSize.Small
	headerLabel.TextColor3             = Theme.Colors.TextSecondary
	headerLabel.TextXAlignment         = Enum.TextXAlignment.Left
	headerLabel.TextTruncate           = Enum.TextTruncate.AtEnd
	headerLabel.ZIndex                 = 6
	headerLabel.Parent                 = header
	self._sidebarHeaderLabel           = headerLabel

	-- Chevron collapse button
	local chevronBtn                  = Instance.new("TextButton")
	chevronBtn.Name                   = "ChevronBtn"
	chevronBtn.AnchorPoint            = Vector2.new(1, 0.5)
	chevronBtn.Position               = UDim2.new(1, -8, 0.5, 0)
	chevronBtn.Size                   = UDim2.fromOffset(24, 24)
	chevronBtn.BackgroundColor3       = Theme.Colors.SurfaceHover
	chevronBtn.BorderSizePixel        = 0
	chevronBtn.Font                   = Theme.Font.Body
	chevronBtn.Text                   = "‹"
	chevronBtn.TextSize               = 14
	chevronBtn.TextColor3             = Theme.Colors.TextSecondary
	chevronBtn.AutoButtonColor        = false
	chevronBtn.ZIndex                 = 7
	chevronBtn.Parent                 = header
	applyCorner(chevronBtn, 5)
	applyStroke(chevronBtn, Theme.Colors.Border, 1)
	self._sidebarToggle = chevronBtn

	-- ── Tab list background — same color as window frame (Surface) ────────────
	local tabListBg                  = Instance.new("Frame")
	tabListBg.Name                   = "TabListBg"
	tabListBg.Position               = UDim2.fromOffset(0, SIDEBAR_HEADER_H + 1)
	tabListBg.Size                   = UDim2.new(1, 0, 1, -(SIDEBAR_HEADER_H + 1))
	tabListBg.BackgroundColor3       = Theme.Colors.Surface  -- matches window frame
	tabListBg.BorderSizePixel        = 0
	tabListBg.ZIndex                 = 1
	tabListBg.Parent                 = sidebar

	-- ── Tab list (scrollable, above tabListBg) ────────────────────────────────
	local tabList                     = Instance.new("ScrollingFrame")
	tabList.Name                      = "TabList"
	tabList.Position                  = UDim2.fromOffset(0, SIDEBAR_HEADER_H + 1)
	tabList.Size                      = UDim2.new(1, 0, 1, -(SIDEBAR_HEADER_H + 1))
	tabList.BackgroundTransparency    = 1
	tabList.BorderSizePixel           = 0
	tabList.ScrollBarThickness        = 0
	tabList.CanvasSize                = UDim2.fromOffset(0, 0)
	tabList.AutomaticCanvasSize       = Enum.AutomaticSize.Y
	tabList.ClipsDescendants          = true
	tabList.ZIndex                    = 4
	tabList.Parent                    = sidebar
	self._tabList                     = tabList

	local tabListPad              = Instance.new("UIPadding")
	tabListPad.PaddingTop         = UDim.new(0, 6)
	tabListPad.PaddingBottom      = UDim.new(0, 6)
	tabListPad.PaddingLeft        = UDim.new(0, 6)
	tabListPad.PaddingRight       = UDim.new(0, 6)
	tabListPad.Parent             = tabList

	local tabListLayout               = Instance.new("UIListLayout")
	tabListLayout.FillDirection       = Enum.FillDirection.Vertical
	tabListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	tabListLayout.SortOrder           = Enum.SortOrder.LayoutOrder
	tabListLayout.Padding             = UDim.new(0, TAB_SPACING)  -- 5px gap between items
	tabListLayout.Parent              = tabList

	-- ── Tab content host ──────────────────────────────────────────────────────
	local tabHost                  = Instance.new("Frame")
	tabHost.Name                   = "TabHost"
	tabHost.Position               = UDim2.new(0, 0, 0, BODY_TOP)
	tabHost.Size                   = UDim2.new(1, 0, 1, -BODY_TOP)
	tabHost.BackgroundTransparency = 1
	tabHost.BorderSizePixel        = 0
	tabHost.ClipsDescendants       = false
	tabHost.ZIndex                 = 2
	tabHost.Parent                 = canvas
	self._tabHost                  = tabHost

	self._tabs         = {}
	self._groups       = {}
	self._activeTabIdx = 0

	-- ── Sidebar chevron: toggle expanded / collapsed ───────────────────────────
	self._maid:GiveTask(chevronBtn.MouseButton1Click:Connect(function()
		local expanded        = not self._sidebarExpanded
		self._sidebarExpanded = expanded

		chevronBtn.Text          = if expanded then "‹" else "›"
		headerLabel.Visible      = expanded
		updateSidebarWidth(expanded)

		tabListLayout.HorizontalAlignment = if expanded then Enum.HorizontalAlignment.Left else Enum.HorizontalAlignment.Center
		tabListPad.PaddingLeft  = UDim.new(0, if expanded then 6 else 0)
		tabListPad.PaddingRight = UDim.new(0, if expanded then 6 else 0)

		-- Update top-level (non-group) tabs
		for _, t in ipairs(self._tabs) do
			if t.group then continue end
			local lbl    : TextLabel?    = t.btn:FindFirstChild("TabLabel") :: any
			local layout : UIListLayout? = t.btn:FindFirstChild("TabLayout") :: any
			local pad    : UIPadding?    = t.btn:FindFirstChild("TabPad")   :: any
			local ind    : Frame?        = t.btn:FindFirstChild("Indicator") :: any
			local slot   : Frame?        = t.iconSlot :: any

			t.btn.Size = if expanded then UDim2.new(1, 0, 0, TAB_ITEM_H) else UDim2.fromOffset(TAB_ITEM_H, TAB_ITEM_H)
			if lbl    then lbl.Visible = expanded end
			if layout then layout.HorizontalAlignment = if expanded then Enum.HorizontalAlignment.Left else Enum.HorizontalAlignment.Center end
			if pad    then
				pad.PaddingLeft  = UDim.new(0, if expanded then 10 else 0)
				pad.PaddingRight = UDim.new(0, if expanded then 6  else 0)
			end
			if ind    then ind.Visible = expanded end
			-- Icon slot: when no icon, show slot+letter only in collapsed mode
			if slot then
				if t.hasIcon then
					slot.Visible = true  -- always show real icon slot
				else
					slot.Visible = not expanded  -- collapsed → show letter pill
					local letter : TextLabel? = slot:FindFirstChild("TabLetter") :: any
					if letter then letter.Visible = not expanded end
				end
			end
		end

		-- Update groups
		for _, g in ipairs(self._groups) do
			local gEntry = g.entry

			-- Group header adjustments
			local gHeaderLayout : UIListLayout? = gEntry._headerBtn:FindFirstChild("GroupLayout") :: any
			local gHeaderPad    : UIPadding?    = gEntry._headerBtn:FindFirstChild("GroupPad")   :: any
			if gHeaderLayout then
				gHeaderLayout.HorizontalAlignment = if expanded then Enum.HorizontalAlignment.Left else Enum.HorizontalAlignment.Center
			end
			if gHeaderPad then
				gHeaderPad.PaddingLeft  = UDim.new(0, if expanded then 8 else 0)
				gHeaderPad.PaddingRight = UDim.new(0, if expanded then 8 else 0)
			end

			-- Group name label visibility
			if g.nameLabel then g.nameLabel.Visible = expanded end

			-- Child indent when collapsed sidebar → remove indent (icon-only mode)
			if gEntry._childPad then
				gEntry._childPad.PaddingLeft = UDim.new(0, if expanded then GROUP_CHILD_INDENT else 0)
			end

			-- Update child tabs
			for _, t in ipairs(self._tabs) do
				if t.group ~= gEntry then continue end
				local lbl    : TextLabel?    = t.btn:FindFirstChild("TabLabel") :: any
				local layout : UIListLayout? = t.btn:FindFirstChild("TabLayout") :: any
				local pad    : UIPadding?    = t.btn:FindFirstChild("TabPad")   :: any
				local ind    : Frame?        = t.btn:FindFirstChild("Indicator") :: any
				local slot   : Frame?        = t.iconSlot :: any

				t.btn.Size = if expanded then UDim2.new(1, 0, 0, TAB_ITEM_H) else UDim2.fromOffset(TAB_ITEM_H, TAB_ITEM_H)
				if lbl    then lbl.Visible = expanded end
				if layout then layout.HorizontalAlignment = if expanded then Enum.HorizontalAlignment.Left else Enum.HorizontalAlignment.Center end
				if pad    then
					pad.PaddingLeft  = UDim.new(0, if expanded then 10 else 0)
					pad.PaddingRight = UDim.new(0, if expanded then 6  else 0)
				end
				if ind    then ind.Visible = expanded end
				-- Icon slot: when no icon, show slot+letter only in collapsed mode
				if slot then
					if t.hasIcon then
						slot.Visible = true
					else
						slot.Visible = not expanded
						local letter : TextLabel? = slot:FindFirstChild("TabLetter") :: any
						if letter then letter.Visible = not expanded end
					end
				end
			end

			-- Recompute clip height after icon-size change
			if gEntry._expanded then
				local newH = gEntry._computeExpandedH()
				gEntry._childClip.Size = UDim2.new(1, 0, 0, newH)
			end
		end
	end))

	self._maid:GiveTask(chevronBtn.MouseEnter:Connect(function()
		chevronBtn.BackgroundColor3 = Theme.Colors.SurfaceActive
		chevronBtn.TextColor3       = Theme.Colors.TextPrimary
	end))
	self._maid:GiveTask(chevronBtn.MouseLeave:Connect(function()
		chevronBtn.BackgroundColor3 = Theme.Colors.SurfaceHover
		chevronBtn.TextColor3       = Theme.Colors.TextSecondary
	end))
end

-- ── _activateTab ──────────────────────────────────────────────────────────────

function Window:_activateTab(idx: number)
	local tabs = self._tabs
	if not tabs then return end

	-- Deactivate previous
	if self._activeTabIdx > 0 then
		local old = tabs[self._activeTabIdx]
		old.pane.Visible = false

		-- Re-enable gradient (return to inactive state)
		if old.grad then old.grad.Enabled = true end

		-- Dim stroke back to subtle inactive outline
		local oldStroke = old.btn:FindFirstChildOfClass("UIStroke")
		if oldStroke then
			TweenService:Create(oldStroke, TWEEN_TAB, {
				Transparency = 0.45,
				Color        = Theme.Colors.Border,
			}):Play()
		end
		local oldInd = old.btn:FindFirstChild("Indicator")
		if oldInd then
			TweenService:Create(oldInd, TWEEN_TAB, { BackgroundTransparency = 1 }):Play()
		end
		local oldIcon = old.btn:FindFirstChild("TabIcon", true)
		if oldIcon then
			TweenService:Create(oldIcon, TWEEN_TAB, { ImageColor3 = Theme.Colors.TextSecondary }):Play()
		end
		local oldLbl = old.btn:FindFirstChild("TabLabel")
		if oldLbl then
			TweenService:Create(oldLbl, TWEEN_TAB, { TextColor3 = Theme.Colors.TextSecondary }):Play()
		end
	end

	self._activeTabIdx = idx
	local tab = tabs[idx]
	tab.pane.Visible = true

	-- Auto-expand group if this tab lives inside a collapsed group
	if tab.group and not tab.group._expanded then
		tab.group._expanded = true
		if tab.group._chevron then tab.group._chevron.Text = "▾" end
		local h = tab.group._computeExpandedH()
		TweenService:Create(tab.group._childClip, TWEEN_GROUP, {
			Size = UDim2.new(1, 0, 0, h),
		}):Play()
	end

	-- Breadcrumb
	if self._titleLabel then
		self._titleLabel.Text = self.Title .. "  /  " .. tab.name
	end

	-- Activate: disable gradient, show AccentMuted bg
	if tab.grad then tab.grad.Enabled = false end
	TweenService:Create(tab.btn, TWEEN_TAB, {
		BackgroundColor3 = Theme.Colors.AccentMuted,
	}):Play()
	local btnStroke = tab.btn:FindFirstChildOfClass("UIStroke")
	if btnStroke then
		TweenService:Create(btnStroke, TWEEN_TAB, {
			Transparency = 0.3,
			Color        = Theme.Colors.Accent,
		}):Play()
	end
	local ind = tab.btn:FindFirstChild("Indicator")
	if ind and self._sidebarExpanded then
		TweenService:Create(ind, TWEEN_TAB, { BackgroundTransparency = 0 }):Play()
	end
	local icon = tab.btn:FindFirstChild("TabIcon", true)
	if icon then
		TweenService:Create(icon, TWEEN_TAB, { ImageColor3 = Theme.Colors.Accent }):Play()
	end
	local lbl = tab.btn:FindFirstChild("TabLabel")
	if lbl then
		TweenService:Create(lbl, TWEEN_TAB, { TextColor3 = Theme.Colors.TextPrimary }):Play()
	end

	-- Auto-scroll sidebar tab list so the active tab button stays in view
	task.defer(function()
		local tabList = self._tabList
		if not tabList then return end
		local totalH = tabList.AbsoluteCanvasSize.Y
		local listH  = tabList.AbsoluteSize.Y
		if totalH <= listH then return end
		local relY    = tab.btn.AbsolutePosition.Y - tabList.AbsolutePosition.Y + tabList.CanvasPosition.Y
		local btnH    = tab.btn.AbsoluteSize.Y
		local targetY = math.clamp(relY - (listH - btnH) * 0.5, 0, totalH - listH)
		TweenService:Create(tabList, TWEEN_TAB, { CanvasPosition = Vector2.new(0, targetY) }):Play()
	end)
end

-- ── _buildTabBtn — shared button factory (top-level and group child) ──────────

function Window:_buildTabBtn(
	name     : string,
	icon     : string?,
	parent   : Instance,
	tabIdx   : number,
	layoutOrder: number
): (TextButton, UIGradient, Frame)

	local btn                  = Instance.new("TextButton")
	btn.Name                   = "Tab_" .. name
	btn.Size                   = UDim2.new(1, 0, 0, TAB_ITEM_H)
	btn.BackgroundColor3       = Color3.fromHex("#222222")
	btn.BackgroundTransparency = 0       -- visible so gradient shows
	btn.BorderSizePixel        = 0
	btn.Text                   = ""
	btn.AutoButtonColor        = false
	btn.LayoutOrder            = layoutOrder
	btn.ZIndex                 = 4
	btn.ClipsDescendants       = false
	btn.Parent                 = parent
	applyCorner(btn, 6)

	-- Inactive gradient — matches component container gradient
	local tabGrad    = Instance.new("UIGradient")
	tabGrad.Color    = TAB_GRAD_SEQ
	tabGrad.Rotation = 90
	tabGrad.Enabled  = true   -- enabled = inactive state visual
	tabGrad.Parent   = btn

	-- Subtle inactive stroke ("outline samar")
	local btnStroke           = Instance.new("UIStroke")
	btnStroke.Color           = Theme.Colors.Border
	btnStroke.Thickness       = 1
	btnStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	btnStroke.Transparency    = 0.45   -- visible but faint
	btnStroke.Parent          = btn

	-- Horizontal layout: icon + label
	local btnLayout                    = Instance.new("UIListLayout")
	btnLayout.Name                     = "TabLayout"
	btnLayout.FillDirection            = Enum.FillDirection.Horizontal
	btnLayout.VerticalAlignment        = Enum.VerticalAlignment.Center
	btnLayout.HorizontalAlignment      = Enum.HorizontalAlignment.Left
	btnLayout.Padding                  = UDim.new(0, 8)
	btnLayout.SortOrder                = Enum.SortOrder.LayoutOrder
	btnLayout.Parent                   = btn

	local btnPad              = Instance.new("UIPadding")
	btnPad.Name               = "TabPad"
	btnPad.PaddingLeft        = UDim.new(0, 10)
	btnPad.PaddingRight       = UDim.new(0, 6)
	btnPad.Parent             = btn

	-- Icon slot — in layout flow; hidden when no icon so text isn't pushed left
	local hasIconFlag                = icon ~= nil and icon ~= ""

	local iconSlot                   = Instance.new("Frame")
	iconSlot.Name                    = "IconSlot"
	iconSlot.Size                    = UDim2.fromOffset(14, 14)
	iconSlot.BackgroundTransparency  = 1
	iconSlot.BorderSizePixel         = 0
	iconSlot.LayoutOrder             = 0
	iconSlot.ZIndex                  = 5
	iconSlot.Visible                 = hasIconFlag   -- hidden in expanded+no-icon state
	iconSlot.Parent                  = btn

	-- Actual icon image (visible only when icon provided)
	local iconLabel                  = Instance.new("ImageLabel")
	iconLabel.Name                   = "TabIcon"
	iconLabel.Size                   = UDim2.fromScale(1, 1)
	iconLabel.BackgroundTransparency = 1
	iconLabel.BorderSizePixel        = 0
	iconLabel.Image                  = icon or ""
	iconLabel.ImageColor3            = Theme.Colors.TextSecondary
	iconLabel.ScaleType              = Enum.ScaleType.Fit
	iconLabel.ZIndex                 = 6
	iconLabel.Visible                = hasIconFlag
	iconLabel.Parent                 = iconSlot

	-- Letter placeholder — shown only when sidebar is collapsed and tab has no icon
	local letterLabel                  = Instance.new("TextLabel")
	letterLabel.Name                   = "TabLetter"
	letterLabel.Size                   = UDim2.fromScale(1, 1)
	letterLabel.BackgroundColor3       = Theme.Colors.AccentMuted
	letterLabel.BackgroundTransparency = 0
	letterLabel.BorderSizePixel        = 0
	letterLabel.Font                   = Theme.Font.Subtitle
	letterLabel.Text                   = string.upper(string.sub(name, 1, 1))
	letterLabel.TextSize               = 9
	letterLabel.TextColor3             = Theme.Colors.Accent
	letterLabel.TextXAlignment         = Enum.TextXAlignment.Center
	letterLabel.TextYAlignment         = Enum.TextYAlignment.Center
	letterLabel.ZIndex                 = 6
	letterLabel.Visible                = false
	applyCorner(letterLabel, 3)
	letterLabel.Parent                 = iconSlot

	-- Label
	local tabLabel                   = Instance.new("TextLabel")
	tabLabel.Name                    = "TabLabel"
	tabLabel.AutomaticSize           = Enum.AutomaticSize.X
	tabLabel.Size                    = UDim2.fromOffset(0, Theme.TextSize.Body)
	tabLabel.BackgroundTransparency  = 1
	tabLabel.BorderSizePixel         = 0
	tabLabel.Font                    = Theme.Font.Body
	tabLabel.Text                    = name
	tabLabel.TextSize                = Theme.TextSize.Body
	tabLabel.TextColor3              = Theme.Colors.TextSecondary
	tabLabel.TextXAlignment          = Enum.TextXAlignment.Left
	tabLabel.TextTruncate            = Enum.TextTruncate.AtEnd
	tabLabel.LayoutOrder             = 1
	tabLabel.ZIndex                  = 5
	tabLabel.Parent                  = btn
	pcall(function()
		local flex    = Instance.new("UIFlexItem")
		flex.FlexMode = Enum.UIFlexMode.Shrink
		flex.Parent   = tabLabel
	end)

	-- Right-edge accent indicator pill
	local indicator                  = Instance.new("Frame")
	indicator.Name                   = "Indicator"
	indicator.AnchorPoint            = Vector2.new(1, 0.5)
	indicator.Position               = UDim2.new(1, -4, 0.5, 0)
	indicator.Size                   = UDim2.fromOffset(3, 14)
	indicator.BackgroundColor3       = Theme.Colors.Accent
	indicator.BackgroundTransparency = 1
	indicator.BorderSizePixel        = 0
	indicator.ZIndex                 = 6
	applyCorner(indicator, 2)
	indicator.Parent = btn

	return btn, tabGrad, indicator
end

-- ── AddTab — flat (top-level, no group) ───────────────────────────────────────

function Window:AddTab(name: string, icon: string?): any
	self:_initTabSystem()

	local tabs   = self._tabs
	local tabIdx = #tabs + 1

	local btn, tabGrad, indicator = self:_buildTabBtn(
		name, icon, self._tabList, tabIdx, tabIdx
	)

	-- Pane
	local pane                      = Instance.new("ScrollingFrame")
	pane.Name                       = "Pane_" .. name
	pane.Size                       = UDim2.fromScale(1, 1)
	pane.BackgroundTransparency     = 1
	pane.BorderSizePixel            = 0
	pane.ScrollBarThickness         = 3
	pane.ScrollBarImageColor3       = Theme.Colors.Border
	pane.CanvasSize                 = UDim2.fromOffset(0, 0)
	pane.AutomaticCanvasSize        = Enum.AutomaticSize.Y
	pane.ClipsDescendants           = true
	pane.Visible                    = false
	pane.ZIndex                     = 2
	pane.Parent                     = self._tabHost
	self._maid:GiveTask(SmoothScroll.apply(pane))

	local panePad         = Instance.new("UIPadding")
	panePad.PaddingTop    = UDim.new(0, Theme.Spacing.S)
	panePad.PaddingBottom = UDim.new(0, Theme.Spacing.S)
	panePad.PaddingLeft   = UDim.new(0, Theme.Spacing.S)
	panePad.PaddingRight  = UDim.new(0, Theme.Spacing.S)
	panePad.Parent        = pane

	local paneLayout               = Instance.new("UIListLayout")
	paneLayout.FillDirection       = Enum.FillDirection.Vertical
	paneLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	paneLayout.SortOrder           = Enum.SortOrder.LayoutOrder
	paneLayout.Padding             = UDim.new(0, Theme.Spacing.XS)
	paneLayout.Parent              = pane

	local iconSlotRef = btn:FindFirstChild("IconSlot")
	local tabInfo = {
		name     = name,
		btn      = btn,
		pane     = pane,
		indicator = indicator,
		grad     = tabGrad,
		group    = nil,
		iconSlot = iconSlotRef,
		hasIcon  = icon ~= nil and icon ~= "",
	}
	table.insert(tabs, tabInfo)

	local tabObj = Tab.new(pane, self._gui, self._maid, self._canvas)

	if tabIdx == 1 then self:_activateTab(1) end

	-- Interactions
	self._maid:GiveTask(btn.MouseButton1Click:Connect(function()
		self:_activateTab(tabIdx)
	end))
	self._maid:GiveTask(btn.MouseEnter:Connect(function()
		if self._activeTabIdx ~= tabIdx then
			tabGrad.Enabled = false
			TweenService:Create(btn, TWEEN_TAB, { BackgroundColor3 = Theme.Colors.SurfaceHover }):Play()
		end
	end))
	self._maid:GiveTask(btn.MouseLeave:Connect(function()
		if self._activeTabIdx ~= tabIdx then
			tabGrad.Enabled = true
		end
	end))

	return tabObj
end

-- ── AddTabGroup — collapsible sidebar section ─────────────────────────────────

function Window:AddTabGroup(name: string, icon: string?): any
	self:_initTabSystem()

	if not self._groups then self._groups = {} end

	local groupOrder = #self._groups + 1000  -- ensure groups sort after any flat tabs

	-- Group entry (internal state)
	local gEntry = {
		_tabs           = {},
		_expanded       = true,
		_headerBtn      = nil :: any,
		_childClip      = nil :: any,
		_childInner     = nil :: any,
		_chevron        = nil :: any,
		_childPad       = nil :: any,
		_computeExpandedH = nil :: any,
	}

	-- ── Group container (header + children clip, auto-sizes vertically) ────────
	local groupContainer                  = Instance.new("Frame")
	groupContainer.Name                   = "Group_" .. name
	groupContainer.Size                   = UDim2.new(1, 0, 0, 0)
	groupContainer.AutomaticSize          = Enum.AutomaticSize.Y
	groupContainer.BackgroundTransparency = 1
	groupContainer.BorderSizePixel        = 0
	groupContainer.LayoutOrder            = groupOrder
	groupContainer.ZIndex                 = 4
	groupContainer.Parent                 = self._tabList

	local containerLayout               = Instance.new("UIListLayout")
	containerLayout.FillDirection       = Enum.FillDirection.Vertical
	containerLayout.SortOrder           = Enum.SortOrder.LayoutOrder
	containerLayout.Padding             = UDim.new(0, 0)
	containerLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	containerLayout.Parent              = groupContainer

	-- ── Group header button ────────────────────────────────────────────────────
	local headerBtn                  = Instance.new("TextButton")
	headerBtn.Name                   = "GroupHeader"
	headerBtn.Size                   = UDim2.new(1, 0, 0, GROUP_HEADER_H)
	headerBtn.BackgroundTransparency = 1
	headerBtn.Text                   = ""
	headerBtn.AutoButtonColor        = false
	headerBtn.LayoutOrder            = 0
	headerBtn.ZIndex                 = 5
	headerBtn.ClipsDescendants       = false
	headerBtn.Parent                 = groupContainer
	gEntry._headerBtn = headerBtn

	local gHeaderLayout                    = Instance.new("UIListLayout")
	gHeaderLayout.Name                     = "GroupLayout"
	gHeaderLayout.FillDirection            = Enum.FillDirection.Horizontal
	gHeaderLayout.VerticalAlignment        = Enum.VerticalAlignment.Center
	gHeaderLayout.HorizontalAlignment      = Enum.HorizontalAlignment.Left
	gHeaderLayout.Padding                  = UDim.new(0, 5)
	gHeaderLayout.SortOrder               = Enum.SortOrder.LayoutOrder
	gHeaderLayout.Parent                  = headerBtn

	local gHeaderPad         = Instance.new("UIPadding")
	gHeaderPad.Name          = "GroupPad"
	gHeaderPad.PaddingLeft   = UDim.new(0, 8)
	gHeaderPad.PaddingRight  = UDim.new(0, 8)
	gHeaderPad.Parent        = headerBtn

	-- Expand/collapse chevron (▾ expanded · ▸ collapsed)
	local chevron                  = Instance.new("TextLabel")
	chevron.Name                   = "Chevron"
	chevron.Size                   = UDim2.fromOffset(10, 10)
	chevron.BackgroundTransparency = 1
	chevron.Font                   = Theme.Font.Body
	chevron.Text                   = "▾"
	chevron.TextSize               = 9
	chevron.TextColor3             = Theme.Colors.TextDisabled
	chevron.LayoutOrder            = 0
	chevron.ZIndex                 = 6
	chevron.Parent                 = headerBtn
	gEntry._chevron = chevron

	-- Group name label
	local groupNameLbl                  = Instance.new("TextLabel")
	groupNameLbl.Name                   = "GroupName"
	groupNameLbl.AutomaticSize          = Enum.AutomaticSize.X
	groupNameLbl.Size                   = UDim2.fromOffset(0, 13)
	groupNameLbl.BackgroundTransparency = 1
	groupNameLbl.Font                   = Theme.Font.Subtitle
	groupNameLbl.Text                   = name
	groupNameLbl.TextSize               = 11
	groupNameLbl.TextColor3             = Theme.Colors.TextDisabled
	groupNameLbl.TextXAlignment         = Enum.TextXAlignment.Left
	groupNameLbl.TextTruncate           = Enum.TextTruncate.AtEnd
	groupNameLbl.LayoutOrder            = 1
	groupNameLbl.ZIndex                 = 6
	groupNameLbl.Parent                 = headerBtn

	-- Hairline below header
	local groupSep                  = Instance.new("Frame")
	groupSep.Name                   = "GroupSep"
	groupSep.AnchorPoint            = Vector2.new(0, 1)
	groupSep.Position               = UDim2.new(0, 4, 1, 0)
	groupSep.Size                   = UDim2.new(1, -8, 0, 1)
	groupSep.BackgroundColor3       = Theme.Colors.Border
	groupSep.BackgroundTransparency = 0.5
	groupSep.BorderSizePixel        = 0
	groupSep.ZIndex                 = 5
	groupSep.Parent                 = headerBtn

	-- ── Children clip frame (tweens height for collapse animation) ─────────────
	local childClip                  = Instance.new("Frame")
	childClip.Name                   = "ChildrenClip"
	childClip.Size                   = UDim2.new(1, 0, 0, 0)
	childClip.BackgroundTransparency = 1
	childClip.ClipsDescendants       = true
	childClip.BorderSizePixel        = 0
	childClip.LayoutOrder            = 1
	childClip.ZIndex                 = 4
	childClip.Parent                 = groupContainer
	gEntry._childClip = childClip

	-- Children inner (auto-sizes, has padding)
	local childInner                  = Instance.new("Frame")
	childInner.Name                   = "ChildrenInner"
	childInner.Size                   = UDim2.new(1, 0, 0, 0)
	childInner.AutomaticSize          = Enum.AutomaticSize.Y
	childInner.BackgroundTransparency = 1
	childInner.BorderSizePixel        = 0
	childInner.ZIndex                 = 4
	childInner.Parent                 = childClip
	gEntry._childInner = childInner

	local childLayout               = Instance.new("UIListLayout")
	childLayout.FillDirection       = Enum.FillDirection.Vertical
	childLayout.SortOrder           = Enum.SortOrder.LayoutOrder
	childLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	childLayout.Padding             = UDim.new(0, GROUP_CHILD_GAP)
	childLayout.Parent              = childInner

	local childPad         = Instance.new("UIPadding")
	childPad.PaddingTop    = UDim.new(0, GROUP_CHILD_PAD_TOP)
	childPad.PaddingBottom = UDim.new(0, GROUP_CHILD_PAD_BOT)
	childPad.PaddingLeft   = UDim.new(0, GROUP_CHILD_INDENT)
	childPad.PaddingRight  = UDim.new(0, 0)
	childPad.Parent        = childInner
	gEntry._childPad = childPad

	-- Height calculator: total px needed for all child tabs
	local function computeExpandedH(): number
		local count = #gEntry._tabs
		if count == 0 then return 0 end
		return GROUP_CHILD_PAD_TOP
			+ count * TAB_ITEM_H
			+ math.max(0, count - 1) * GROUP_CHILD_GAP
			+ GROUP_CHILD_PAD_BOT
	end
	gEntry._computeExpandedH = computeExpandedH

	-- ── Toggle expand / collapse ───────────────────────────────────────────────
	local function toggleGroup()
		local nowExpanded    = not gEntry._expanded
		gEntry._expanded     = nowExpanded
		chevron.Text         = if nowExpanded then "▾" else "▸"
		chevron.TextColor3   = if nowExpanded then Theme.Colors.TextSecondary else Theme.Colors.TextDisabled
		local targetH        = if nowExpanded then computeExpandedH() else 0
		TweenService:Create(childClip, TWEEN_GROUP, {
			Size = UDim2.new(1, 0, 0, targetH),
		}):Play()
	end

	self._maid:GiveTask(headerBtn.MouseButton1Click:Connect(toggleGroup))
	self._maid:GiveTask(headerBtn.MouseEnter:Connect(function()
		chevron.TextColor3      = Theme.Colors.TextSecondary
		groupNameLbl.TextColor3 = Theme.Colors.TextSecondary
	end))
	self._maid:GiveTask(headerBtn.MouseLeave:Connect(function()
		chevron.TextColor3      = Theme.Colors.TextDisabled
		groupNameLbl.TextColor3 = Theme.Colors.TextDisabled
	end))

	-- Register group for sidebar collapse sync
	table.insert(self._groups, { entry = gEntry, nameLabel = groupNameLbl })

	-- ── Group proxy returned to caller ────────────────────────────────────────
	local groupProxy = { _win = self, _entry = gEntry }
	function groupProxy:AddTab(tabName: string, tabIcon: string?): any
		return self._win:_addTabToGroup(self._entry, tabName, tabIcon)
	end

	return groupProxy
end

-- ── _addTabToGroup — creates a tab inside a group ────────────────────────────

function Window:_addTabToGroup(gEntry: any, name: string, icon: string?): any
	local tabs    = self._tabs
	local tabIdx  = #tabs + 1
	local childN  = #gEntry._tabs + 1

	local btn, tabGrad, indicator = self:_buildTabBtn(
		name, icon, gEntry._childInner, tabIdx, childN
	)

	-- Pane (same as AddTab — lives in tabHost)
	local pane                      = Instance.new("ScrollingFrame")
	pane.Name                       = "Pane_" .. name
	pane.Size                       = UDim2.fromScale(1, 1)
	pane.BackgroundTransparency     = 1
	pane.BorderSizePixel            = 0
	pane.ScrollBarThickness         = 3
	pane.ScrollBarImageColor3       = Theme.Colors.Border
	pane.CanvasSize                 = UDim2.fromOffset(0, 0)
	pane.AutomaticCanvasSize        = Enum.AutomaticSize.Y
	pane.ClipsDescendants           = true
	pane.Visible                    = false
	pane.ZIndex                     = 2
	pane.Parent                     = self._tabHost
	self._maid:GiveTask(SmoothScroll.apply(pane))

	local panePad         = Instance.new("UIPadding")
	panePad.PaddingTop    = UDim.new(0, Theme.Spacing.S)
	panePad.PaddingBottom = UDim.new(0, Theme.Spacing.S)
	panePad.PaddingLeft   = UDim.new(0, Theme.Spacing.S)
	panePad.PaddingRight  = UDim.new(0, Theme.Spacing.S)
	panePad.Parent        = pane

	local paneLayout               = Instance.new("UIListLayout")
	paneLayout.FillDirection       = Enum.FillDirection.Vertical
	paneLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	paneLayout.SortOrder           = Enum.SortOrder.LayoutOrder
	paneLayout.Padding             = UDim.new(0, Theme.Spacing.XS)
	paneLayout.Parent              = pane

	-- Register in flat tabs array (with group reference)
	local iconSlotRef2 = btn:FindFirstChild("IconSlot")
	local tabInfo = {
		name     = name,
		btn      = btn,
		pane     = pane,
		indicator = indicator,
		grad     = tabGrad,
		group    = gEntry,
		iconSlot = iconSlotRef2,
		hasIcon  = icon ~= nil and icon ~= "",
	}
	table.insert(tabs, tabInfo)
	table.insert(gEntry._tabs, tabInfo)

	-- Expand clip to fit the new child (if group is open)
	if gEntry._expanded then
		local newH = gEntry._computeExpandedH()
		gEntry._childClip.Size = UDim2.new(1, 0, 0, newH)
	end

	-- Activate first tab ever
	if tabIdx == 1 then
		self:_activateTab(1)
	end

	-- Interactions
	self._maid:GiveTask(btn.MouseButton1Click:Connect(function()
		self:_activateTab(tabIdx)
	end))
	self._maid:GiveTask(btn.MouseEnter:Connect(function()
		if self._activeTabIdx ~= tabIdx then
			tabGrad.Enabled = false
			TweenService:Create(btn, TWEEN_TAB, { BackgroundColor3 = Theme.Colors.SurfaceHover }):Play()
		end
	end))
	self._maid:GiveTask(btn.MouseLeave:Connect(function()
		if self._activeTabIdx ~= tabIdx then
			tabGrad.Enabled = true
		end
	end))

	return Tab.new(pane, self._gui, self._maid, self._canvas)
end

-- ── AddDropdown ───────────────────────────────────────────────────────────────

function Window:AddDropdown(config: {
	Label:       string?,
	Options:     { any },
	MultiSelect: boolean?,
	Default:     any?,
	Placeholder: string?,
	Enabled:     boolean?,
	description: string?,
})
	local c = config :: any
	c.LayoutOrder   = self:_nextOrder()
	c.OverlayParent = self._gui
	return self:_addToContent(Components.Dropdown.new(c), c)
end

-- ── Collapse / expand ────────────────────────────────────────────────────────

function Window:_toggleCollapse()
	if self._closing or self._collapseAnimating then return end
	self._collapseAnimating = true

	local minusBtn = self._minusBtn :: TextButton?

	if self._collapsed then
		-- ── EXPAND ────────────────────────────────────────────────────────────
		self._collapsed = false
		if minusBtn then minusBtn.Text = "—" end
		if self._handle then self._handle.Visible = true end

		-- Grow the frame back first
		TweenService:Create(self._root, TWEEN_EXPAND, {
			Size = self._expandedSize,
		}):Play()

		-- Once the frame is large enough, reveal content and sidebar
		task.delay(0.15, function()
			if self._content  then self._content.Visible  = true end
			if self._tabHost  then self._tabHost.Visible  = true end
			if self._sidebar  then
				TweenService:Create(self._sidebar,
				TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
				{ GroupTransparency = 0 }
				):Play()
				local sidebarStroke = self._sidebar:FindFirstChildOfClass("UIStroke")
				if sidebarStroke then
					TweenService:Create(sidebarStroke,
						TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
						{ Transparency = 0 }
					):Play()
				end
				if self._tabList then self._tabList.Visible = true end
			end
		end)

		task.delay(0.55, function()
			self._collapseAnimating = false
		end)
	else
		-- ── COLLAPSE — snapshot live size before shrinking ────────────────────
		self._collapsed    = true
		self._expandedSize = UDim2.fromOffset(
			self._root.AbsoluteSize.X,
			self._root.AbsoluteSize.Y
		)
		if minusBtn then minusBtn.Text = "▲" end
		if self._handle then self._handle.Visible = false end

		-- Hide content and sidebar immediately so nothing squashes
		-- under the shrinking frame — same pattern as Rayfield's ToggleMinimise
		if self._content then self._content.Visible = false end
		if self._tabHost then self._tabHost.Visible = false end
		if self._sidebar then
			if self._tabList then self._tabList.Visible = false end
			TweenService:Create(self._sidebar,
			TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
			{ GroupTransparency = 1 }
			):Play()
			local sidebarStroke = self._sidebar:FindFirstChildOfClass("UIStroke")
			if sidebarStroke then
				TweenService:Create(sidebarStroke,
					TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
					{ Transparency = 1 }
				):Play()
			end
		end

		-- Shrink the window to titlebar height
		TweenService:Create(self._root, TWEEN_COLLAPSE, {
			Size = UDim2.fromOffset(
				self._root.AbsoluteSize.X,
				Theme.TitleBarHeight + 2
			),
		}):Play()

		task.delay(0.50, function()
			self._collapseAnimating = false
		end)
	end
end

-- ── pill face ───────────────────────────────────────────────────────────────────

function Window:_buildPillFace()
	-- accent dot (left side)
	local dot                  = Instance.new("Frame")
	dot.Name                   = "PillDot"
	dot.AnchorPoint            = Vector2.new(0, 0.5)
	dot.Position               = UDim2.new(0, 14, 0.5, 0)
	dot.Size                   = UDim2.fromOffset(8, 8)
	dot.BackgroundColor3       = Theme.Colors.Accent
	dot.BorderSizePixel        = 0
	dot.BackgroundTransparency = 1
	dot.ZIndex                 = 10
	applyCorner(dot, 4)
	dot.Parent = self._canvas

	-- title
	local pillTitle                  = Instance.new("TextLabel")
	pillTitle.Name                   = "PillTitle"
	pillTitle.AnchorPoint            = Vector2.new(0, 0.5)
	pillTitle.Position               = UDim2.new(0, 30, 0.5, -7)
	pillTitle.Size                   = UDim2.new(1, -38, 0, 16)
	pillTitle.BackgroundTransparency = 1
	pillTitle.Font                   = Theme.Font.Title
	pillTitle.Text                   = self.Title
	pillTitle.TextSize               = 13
	pillTitle.TextColor3             = Theme.Colors.TextPrimary
	pillTitle.TextXAlignment         = Enum.TextXAlignment.Left
	pillTitle.TextTruncate           = Enum.TextTruncate.AtEnd
	pillTitle.TextTransparency       = 1
	pillTitle.ZIndex                 = 10
	pillTitle.Parent                 = self._canvas

	-- subtitle
	local pillSub                    = Instance.new("TextLabel")
	pillSub.Name                     = "PillSubtitle"
	pillSub.AnchorPoint              = Vector2.new(0, 0.5)
	pillSub.Position                 = UDim2.new(0, 30, 0.5, 8)
	pillSub.Size                     = UDim2.new(1, -38, 0, 12)
	pillSub.BackgroundTransparency   = 1
	pillSub.Font                     = Theme.Font.Body
	pillSub.Text                     = "Tap to show"
	pillSub.TextSize                 = 11
	pillSub.TextColor3               = Theme.Colors.TextSecondary
	pillSub.TextXAlignment           = Enum.TextXAlignment.Left
	pillSub.TextTruncate             = Enum.TextTruncate.AtEnd
	pillSub.TextTransparency         = 1
	pillSub.ZIndex                   = 10
	pillSub.Parent                   = self._canvas

	-- full-canvas interact (click to restore)
	local interact                   = Instance.new("TextButton")
	interact.Name                    = "PillInteract"
	interact.Size                    = UDim2.fromScale(1, 1)
	interact.BackgroundTransparency  = 1
	interact.Text                    = ""
	interact.TextTransparency        = 1
	interact.Visible                 = false
	interact.ZIndex                  = 20
	interact.Parent                  = self._canvas

	self._pillDot      = dot
	self._pillTitle    = pillTitle
	self._pillSub      = pillSub
	self._pillInteract = interact

	self._maid:GiveTask(interact.MouseButton1Click:Connect(function()
		self:Show()
	end))
end

-- ── Hide / Show / ToggleHide ──────────────────────────────────────────────────

function Window:Hide()
	if self._closing or self._hideAnimating or self._hidden then return end
	self._hideAnimating = true
	self._hidden        = true

	-- Snapshot position + expanded size for restore
	self._savedPosition = self._root.Position
	if not self._collapsed then
		self._expandedSize = UDim2.fromOffset(
			self._root.AbsoluteSize.X,
			self._root.AbsoluteSize.Y
		)
	end

	-- Immediately hide all chrome — no fade, keeps morph clean
	if self._titleBar then self._titleBar.Visible = false end
	if self._sep      then self._sep.Visible      = false end
	if self._content  then self._content.Visible  = false end
	if self._tabHost  then self._tabHost.Visible  = false end
	if self._handle   then self._handle.Visible   = false end
	if self._tabList  then self._tabList.Visible  = false end

	-- Sidebar: fold behind canvas — position accelerates in (Quint.In = "sucked in" feel),
	-- transparency fades fast and independently
	if self._sidebar then
		TweenService:Create(self._sidebar,
			TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
			{ Position = UDim2.new(0, 0, 0, 0) }
		):Play()
		TweenService:Create(self._sidebar,
			TweenInfo.new(0.16, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
			{ GroupTransparency = 1 }
		):Play()
		local ss = self._sidebar:FindFirstChildOfClass("UIStroke")
		if ss then
			TweenService:Create(ss,
				TweenInfo.new(0.16, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
				{ Transparency = 1 }
			):Play()
		end
		task.delay(0.24, function()
			if not self._hidden then return end
			self._sidebar.Visible = false
		end)
	end

	-- Stroke fades out quickly
	TweenService:Create(self._stroke,
		TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
		{ Transparency = 1 }
	):Play()

	-- Morph root → pill (canvas fills root via fromScale, clips naturally)
	TweenService:Create(self._root, TWEEN_PILL_MORPH, {
		Size     = PILL_SIZE,
		Position = PILL_POS,
	}):Play()

	-- Corner → fully rounded (pill shape)
	local corner = self._canvas:FindFirstChildOfClass("UICorner")
	if corner then
		TweenService:Create(corner, TWEEN_PILL_MORPH, { CornerRadius = UDim.new(1, 0) }):Play()
	end

	-- When morph is nearly done: fade pill face in
	local faceInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	task.delay(0.35, function()
		if not self._hidden then return end

		-- Reset pill face to transparent (safe against interrupted Show)
		self._pillDot.BackgroundTransparency = 1
		self._pillTitle.TextTransparency     = 1
		self._pillSub.TextTransparency       = 1

		TweenService:Create(self._pillDot,   faceInfo, { BackgroundTransparency = 0   }):Play()
		TweenService:Create(self._pillTitle, faceInfo, { TextTransparency       = 0   }):Play()
		TweenService:Create(self._pillSub,   faceInfo, { TextTransparency       = 0.4 }):Play()

		task.delay(0.18, function()
			if not self._hidden then return end
			self._pillInteract.Visible = true
			self._hideAnimating = false
		end)
	end)
end

function Window:Show()
	if self._closing or self._hideAnimating or not self._hidden then return end
	self._hideAnimating = true
	self._hidden        = false

	self._pillInteract.Visible = false

	local fadeInfo   = TweenInfo.new(0.15, Enum.EasingStyle.Quint,       Enum.EasingDirection.Out)
	local chromeFade = TweenInfo.new(0.30, Enum.EasingStyle.Quint,       Enum.EasingDirection.Out)
	local cornerInfo = TweenInfo.new(0.50, Enum.EasingStyle.Exponential,  Enum.EasingDirection.Out)

	-- Fade pill face out
	TweenService:Create(self._pillDot,   fadeInfo, { BackgroundTransparency = 1 }):Play()
	TweenService:Create(self._pillTitle, fadeInfo, { TextTransparency       = 1 }):Play()
	TweenService:Create(self._pillSub,   fadeInfo, { TextTransparency       = 1 }):Play()

	-- Morph root → window
	local target = self._savedPosition or UDim2.fromScale(0.5, 0.5)
	TweenService:Create(self._root, TWEEN_PILL_REVEAL, {
		Size     = self._expandedSize,
		Position = target,
	}):Play()

	-- Sidebar: spring out concurrent with root expand — Back easing gives overshoot,
	-- transparency fades on a separate Quint curve so it doesn't over-dip
	if self._sidebar then
		local targetW = if self._sidebarExpanded then SIDEBAR_W_EXPANDED else SIDEBAR_W_COLLAPSED
		self._sidebar.Position          = UDim2.new(0, 0, 0, 0)
		self._sidebar.GroupTransparency = 1
		self._sidebar.Visible           = true
		if self._tabList then self._tabList.Visible = true end
		TweenService:Create(self._sidebar,
			TweenInfo.new(0.52, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ Position = UDim2.new(0, -(targetW + SIDEBAR_GAP), 0, 0) }
		):Play()
		TweenService:Create(self._sidebar,
			TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
			{ GroupTransparency = 0 }
		):Play()
		local ss = self._sidebar:FindFirstChildOfClass("UIStroke")
		if ss then
			TweenService:Create(ss,
				TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
				{ Transparency = 0 }
			):Play()
		end
	end

	-- Corner → window roundness
	local corner = self._canvas:FindFirstChildOfClass("UICorner")
	if corner then
		TweenService:Create(corner, cornerInfo, {
			CornerRadius = UDim.new(0, Theme.Radius.Medium),
		}):Play()
	end

	-- Halfway through morph: reveal chrome
	-- Canvas stays at GT=0 (fully opaque) throughout — the old GT=0.97 snap
	-- was bleeding the game background through for one frame, causing a white flash.
	-- At t=0.22, Exponential.Out has already covered ~95% of the expand distance,
	-- so chrome snapping visible here looks invisible in practice.
	task.delay(0.22, function()
		if self._hidden then return end
		if self._titleBar then self._titleBar.Visible = true end
		if self._sep      then self._sep.Visible      = not self._collapsed end
		if self._content  then self._content.Visible  = not self._collapsed end
		if self._tabHost  then self._tabHost.Visible  = not self._collapsed end
		if self._handle   then self._handle.Visible   = not self._collapsed end
		if self._tabList  then self._tabList.Visible  = true end
		TweenService:Create(self._stroke, chromeFade, { Transparency = 0 }):Play()
	end)

	task.delay(0.58, function()
		self._hideAnimating = false
	end)
end

function Window:ToggleHide()
	if self._hidden then
		self:Show()
	else
		self:Hide()
	end
end

-- ── lifecycle ─────────────────────────────────────────────────────────────────

function Window:Close()
	if self._closing then return end
	self._closing = true

	local canvas = self._canvas

	TweenService:Create(self._stroke, TWEEN_CLOSE, { Transparency = 1 }):Play()
	if self._sidebar then
		local sidebarStroke = self._sidebar:FindFirstChildOfClass("UIStroke")
		if sidebarStroke then
			TweenService:Create(sidebarStroke, TWEEN_CLOSE, { Transparency = 1 }):Play()
		end
	end

	local tween = TweenService:Create(canvas, TWEEN_CLOSE, {
		GroupTransparency = 1,
	})
	tween:Play()
	tween.Completed:Once(function()
		self:Destroy()
	end)
end

function Window:GetContent(): Frame
	return self._content
end

function Window:Destroy()
	self._maid:DoCleaning()
end

return Window

end)() end,
    function()local wax,script,require=ImportGlobals(20)local ImportGlobals return (function(...)--!strict

local Colors = require(script.Colors)
local Icons = require(script.Icons)

-- Non-blocking icon init — fails gracefully if HTTP is off
task.defer(Icons.Init)

local Theme = {
	Colors = Colors,
	Icons  = Icons,

	Font = {
		Title    = Enum.Font.GothamBold,
		Subtitle = Enum.Font.GothamMedium,
		Body     = Enum.Font.Gotham,
		Mono     = Enum.Font.Code,
	},

	TextSize = {
		Title    = 14,
		Subtitle = 13,
		Body     = 13,
		Small    = 11,
	},

	Radius = {
		Small  = 4,
		Medium = 8,
		Large  = 12,
		Pill   = 100,
	},

	Spacing = {
		XS = 4,
		S  = 8,
		M  = 12,
		L  = 16,
		XL = 24,
	},

	TitleBarHeight = 40,
}

return Theme

end)() end,
    function()local wax,script,require=ImportGlobals(21)local ImportGlobals return (function(...)--!strict

local Colors = {}

-- Base surfaces
Colors.Background    = Color3.fromHex("#0f0f0f")
Colors.Surface       = Color3.fromHex("#1c1c1c")
Colors.SurfaceHover  = Color3.fromHex("#252525")
Colors.SurfaceActive = Color3.fromHex("#2e2e2e")
Colors.TitleBar      = Color3.fromHex("#141414")

-- Accent (Win11 blue)
Colors.Accent        = Color3.fromHex("#4cc2ff")
Colors.AccentHover   = Color3.fromHex("#60cdff")
Colors.AccentActive  = Color3.fromHex("#0093fb")
Colors.AccentMuted   = Color3.fromHex("#1a3a52")

-- Accent gradient (3-stop: violet → blue → teal) for Variant 1 buttons
Colors.AccentGradient = ColorSequence.new({
	ColorSequenceKeypoint.new(0,   Color3.fromHex("#a78bfa")),
	ColorSequenceKeypoint.new(0.5, Color3.fromHex("#60cdff")),
	ColorSequenceKeypoint.new(1,   Color3.fromHex("#38d9b5")),
})
Colors.AccentGradientHover = ColorSequence.new({
	ColorSequenceKeypoint.new(0,   Color3.fromHex("#c4b5fd")),
	ColorSequenceKeypoint.new(0.5, Color3.fromHex("#7ce0ff")),
	ColorSequenceKeypoint.new(1,   Color3.fromHex("#5eecd5")),
})

-- Text
Colors.TextPrimary   = Color3.fromHex("#ffffff")
Colors.TextSecondary = Color3.fromHex("#9d9d9d")
Colors.TextDisabled  = Color3.fromHex("#555555")

-- Borders
Colors.Border        = Color3.fromHex("#2b2b2b")
Colors.BorderAccent  = Color3.fromHex("#4cc2ff")
Colors.BorderFocus   = Color3.fromHex("#60cdff")

-- Semantic
Colors.Success       = Color3.fromHex("#6ccb5f")
Colors.Warning       = Color3.fromHex("#fce100")
Colors.Error         = Color3.fromHex("#ff4f58")
Colors.ErrorHover    = Color3.fromHex("#ff6b74")

return Colors

end)() end,
    function()local wax,script,require=ImportGlobals(22)local ImportGlobals return (function(...)--!strict

local NEBULA_URL = "https://raw.githubusercontent.com/Nebula-Softworks/Nebula-Icon-Library/refs/heads/master/Loader.luau"
local FALLBACK_ID = "rbxassetid://0"

local _cache: { [string]: string } = {}
local _lib: any = nil
local _loaded = false

local function tryLoad(): boolean
	if _loaded then return _lib ~= nil end
	_loaded = true

	local httpOk, httpResult = pcall(function()
		return game:GetService("HttpService")
	end)
	if not httpOk then return false end

	local fetchOk, source = pcall(function()
		return game:HttpGet(NEBULA_URL)
	end)
	if not fetchOk or type(source) ~= "string" then
		warn("[Delirium Icons] HTTP fetch failed — falling back to placeholder icons.")
		return false
	end

	local loadOk, result = pcall(function()
		return loadstring(source)()
	end)
	if not loadOk or type(result) ~= "table" then
		warn("[Delirium Icons] Nebula loadstring failed — falling back to placeholder icons.")
		return false
	end

	_lib = result
	return true
end

local Icons = {}
Icons.IsLoaded = false

function Icons.Init()
	Icons.IsLoaded = tryLoad()
end

function Icons.Get(name: string): string
	if _cache[name] then return _cache[name] end

	if not _lib then
		_cache[name] = FALLBACK_ID
		return FALLBACK_ID
	end

	local ok, id = pcall(function()
		return _lib[name] or _lib.get and _lib:get(name) or FALLBACK_ID
	end)

	local result = (ok and type(id) == "string") and id or FALLBACK_ID
	_cache[name] = result
	return result
end

function Icons.ClearCache()
	table.clear(_cache)
end

return Icons

end)() end,
    [24] = function()local wax,script,require=ImportGlobals(24)local ImportGlobals return (function(...)--!strict

type ErrorEntry = {
	message: string,
	trace: string,
	context: string,
	time: number,
}

type OnErrorSignal = {
	Fire: (self: any, ...any) -> (),
}

local ErrorHandler = {}
local _queue: { ErrorEntry } = {}
local _onError: OnErrorSignal? = nil

function ErrorHandler.Init(signal: OnErrorSignal)
	_onError = signal
end

function ErrorHandler.SafeCall<T>(fn: () -> T, context: string?): T?
	local ctx = context or "Unknown"

	local success, result = xpcall(fn, function(err: any)
		local trace = debug.traceback(tostring(err), 2)
		local msg = string.format("[Delirium] Error in %s:\n%s", ctx, trace)
		warn(msg)

		table.insert(_queue, {
			message = tostring(err),
			trace = trace,
			context = ctx,
			time = os.time(),
		})

		if _onError then
			pcall(function()
				_onError:Fire(msg)
			end)
		end
	end)

	if success then
		return result :: T
	end
	return nil
end

function ErrorHandler.GetQueue(): { ErrorEntry }
	return _queue
end

function ErrorHandler.ClearQueue()
	table.clear(_queue)
end

return ErrorHandler

end)() end,
    [25] = function()local wax,script,require=ImportGlobals(25)local ImportGlobals return (function(...)--!strict

type MaidTask =
	RBXScriptConnection
	| (() -> ())
	| Instance
	| { Destroy: (self: any) -> () }

type MaidImpl = {
	_tasks: { MaidTask },
	GiveTask: (self: MaidImpl, task: MaidTask) -> MaidTask,
	DoCleaning: (self: MaidImpl) -> (),
	Destroy: (self: MaidImpl) -> (),
}

local Maid = {} :: { __index: any }
Maid.__index = Maid

local function new(): MaidImpl
	return setmetatable({ _tasks = {} }, Maid) :: any
end

function Maid:GiveTask(task: MaidTask): MaidTask
	assert(task ~= nil, "Maid: task cannot be nil")
	table.insert(self._tasks, task)
	return task
end

function Maid:DoCleaning()
	local tasks = self._tasks
	self._tasks = {}

	for _, task in tasks do
		local ok, err = pcall(function()
			if typeof(task) == "RBXScriptConnection" then
				task:Disconnect()
			elseif typeof(task) == "Instance" then
				task:Destroy()
			elseif type(task) == "function" then
				task()
			elseif type(task) == "table" and type(task.Destroy) == "function" then
				task:Destroy()
			end
		end)
		if not ok then
			warn("[Delirium Maid] Cleanup error:", err)
		end
	end
end

function Maid:Destroy()
	self:DoCleaning()
end

return { new = new } :: { new: () -> MaidImpl }

end)() end,
    [26] = function()local wax,script,require=ImportGlobals(26)local ImportGlobals return (function(...)--!strict

type Handler = (...any) -> ()

type ConnectionImpl = {
	Connected: boolean,
	Disconnect: (self: ConnectionImpl) -> (),
	_signal: SignalImpl,
	_handler: Handler,
}

type SignalImpl = {
	_handlers: { Handler },
	Connect: (self: SignalImpl, callback: Handler) -> ConnectionImpl,
	Once: (self: SignalImpl, callback: Handler) -> ConnectionImpl,
	Fire: (self: SignalImpl, ...any) -> (),
	Destroy: (self: SignalImpl) -> (),
}

local Connection = {} :: { __index: any }
Connection.__index = Connection

local function newConnection(signal: SignalImpl, handler: Handler): ConnectionImpl
	return setmetatable({
		Connected = true,
		_signal = signal,
		_handler = handler,
	}, Connection) :: any
end

function Connection:Disconnect()
	if not self.Connected then return end
	self.Connected = false
	local handlers = self._signal._handlers
	for i = #handlers, 1, -1 do
		if handlers[i] == self._handler then
			table.remove(handlers, i)
			break
		end
	end
end

local Signal = {} :: { __index: any }
Signal.__index = Signal

local function new(): SignalImpl
	return setmetatable({ _handlers = {} }, Signal) :: any
end

function Signal:Connect(callback: Handler): ConnectionImpl
	local conn = newConnection(self, callback)
	table.insert(self._handlers, callback)
	return conn
end

function Signal:Once(callback: Handler): ConnectionImpl
	local conn: ConnectionImpl
	conn = self:Connect(function(...)
		conn:Disconnect()
		callback(...)
	end)
	return conn
end

function Signal:Fire(...: any)
	local snapshot = table.clone(self._handlers)
	for _, handler in snapshot do
		task.spawn(handler, ...)
	end
end

function Signal:Destroy()
	table.clear(self._handlers)
end

return { new = new } :: { new: () -> SignalImpl }

end)() end,
    [27] = function()local wax,script,require=ImportGlobals(27)local ImportGlobals return (function(...)--!strict

local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local TWEEN_SCROLL = TweenInfo.new(0.45, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
local DEFAULT_STEP = 60

-- ── module-level managed registry ────────────────────────────────────────────
--
--  WHY UIS instead of frame.InputChanged:
--
--  frame.InputChanged only fires when that SPECIFIC frame is the Active recipient
--  of input. Any child GuiObject with Active=true (e.g. the optHit TextButtons
--  inside a dropdown list) becomes the topmost hit target and silently starves
--  the scroll frame's InputChanged — so the dropdown list never scrolls.
--
--  UserInputService.InputChanged fires globally for every wheel tick, letting us
--  manually check bounds and pick the right frame.
--
--  WHY the descendant check:
--
--  Both the window content scroll and the dropdown list scroll are "managed".
--  When the mouse is over the dropdown list, both frames' bounds contain the
--  cursor, so both would try to scroll. We only want the innermost (deepest)
--  frame to win. The parent scroll checks: "is any managed descendant of mine
--  also in bounds right now?" — if yes, it yields and the descendant handles it.
--  This eliminates scroll bleed with zero per-frame allocation.

type ManagedEntry = {
	frame:  ScrollingFrame,
}

local _managed: { ManagedEntry } = {}
local _paused = false

local function isInBounds(frame: GuiObject, pos: Vector2): boolean
	local ap = frame.AbsolutePosition
	local as = frame.AbsoluteSize
	return as.Y > 0
		and pos.X >= ap.X and pos.X <= ap.X + as.X
		and pos.Y >= ap.Y and pos.Y <= ap.Y + as.Y
end

-- Returns true if `ancestor` is an ancestor of `descendant` in the instance tree.
local function isAncestorOf(ancestor: Instance, descendant: Instance): boolean
	local cur = descendant.Parent
	while cur do
		if cur == ancestor then return true end
		cur = cur.Parent
	end
	return false
end

-- Does any managed frame (other than `self`) descend from `self` AND fall under `mousePos`?
local function hasActiveDescendantScroll(self: ScrollingFrame, mousePos: Vector2): boolean
	for _, entry in _managed do
		local other = entry.frame
		if other ~= self
			and isAncestorOf(self, other)
			and isInBounds(other, mousePos)
		then
			return true
		end
	end
	return false
end

-- ── public API ────────────────────────────────────────────────────────────────

local SmoothScroll = {}

-- Pause / resume all managed scroll frames.
-- Called by Popup.show to freeze scroll while a modal is open.
function SmoothScroll.setPaused(paused: boolean)
	_paused = paused
end

--[[
	SmoothScroll.blockRegion(frame)

	Prevents camera zoom when the mouse wheel is used over any GuiObject that is
	NOT a managed ScrollingFrame — e.g. the window CanvasGroup, the title bar.

	Sets frame.Active = true so the engine's hit-test marks this object as an
	input sink, blocking the wheel event from reaching the camera.  Has zero
	effect on UIS.InputChanged (our scroll logic), which fires globally regardless.

	Returns a cleanup function — pass to Maid:GiveTask().
]]
function SmoothScroll.blockRegion(frame: GuiObject): () -> ()
	local prev = frame.Active
	frame.Active = true
	return function()
		frame.Active = prev
	end
end

--[[
	SmoothScroll.apply(frame, step?)

	Smooth-scrolls a ScrollingFrame without camera zoom or cross-frame bleed.

	• Uses UserInputService.InputChanged (global) instead of frame.InputChanged
	  so child Active=true GuiObjects (dropdown option hit-buttons, etc.) can't
	  starve the scroll frame.

	• Keeps frame.Active = true so the camera ignores wheel events while the
	  cursor hovers over this frame.

	• Parent frames yield to descendant managed frames: when a child scroll is
	  under the cursor, only the child reacts — no double-scroll bleed.

	Returns a cleanup function — pass to Maid:GiveTask().
]]
function SmoothScroll.apply(frame: ScrollingFrame, step: number?): () -> ()
	local scrollStep = step or DEFAULT_STEP

	-- Disable native snap-scroll so we drive CanvasPosition ourselves.
	frame.ScrollingEnabled = false
	-- Active = true → camera ignores wheel; does NOT affect UIS.InputChanged.
	frame.Active = true

	local entry: ManagedEntry = { frame = frame }
	table.insert(_managed, entry)

	local targetY: number     = frame.CanvasPosition.Y
	local activeTween: Tween? = nil

	local inputConn = UserInputService.InputChanged:Connect(function(input: InputObject)
		if _paused then return end
		if input.UserInputType ~= Enum.UserInputType.MouseWheel then return end

		local mousePos = UserInputService:GetMouseLocation()

		-- Bounds check: mouse must be within this frame's visible area.
		if not isInBounds(frame, mousePos) then return end

		-- Priority: yield to a managed descendant that's also under the cursor.
		-- (e.g. dropdown list scroll inside the window content scroll)
		if hasActiveDescendantScroll(frame, mousePos) then return end

		local maxY = math.max(0, frame.AbsoluteCanvasSize.Y - frame.AbsoluteSize.Y)
		if maxY <= 0 then return end

		-- Resync when idle (prevents snap on first tick after idle)
		if not activeTween or activeTween.PlaybackState ~= Enum.PlaybackState.Playing then
			targetY = frame.CanvasPosition.Y
		end

		-- input.Position.Z: +1 = scroll up, -1 = scroll down
		targetY = math.clamp(targetY - input.Position.Z * scrollStep, 0, maxY)

		if activeTween then activeTween:Cancel() end
		activeTween = TweenService:Create(frame, TWEEN_SCROLL, {
			CanvasPosition = Vector2.new(0, targetY),
		})
		activeTween:Play()
	end)

	-- Clamp targetY ceiling whenever canvas content grows or shrinks
	-- (e.g. dropdown rebuilds its option list while open)
	local sizeConn = frame:GetPropertyChangedSignal("AbsoluteCanvasSize"):Connect(function()
		local maxY = math.max(0, frame.AbsoluteCanvasSize.Y - frame.AbsoluteSize.Y)
		targetY = math.clamp(targetY, 0, maxY)
	end)

	return function()
		inputConn:Disconnect()
		sizeConn:Disconnect()
		if activeTween then
			activeTween:Cancel()
			activeTween = nil
		end
		frame.ScrollingEnabled = true
		frame.Active           = false

		-- Unregister from managed list
		local idx = table.find(_managed, entry)
		if idx then
			table.remove(_managed, idx)
		end
	end
end

return SmoothScroll

end)() end,
    [28] = function()local wax,script,require=ImportGlobals(28)local ImportGlobals return (function(...)--!strict

export type Callback = (...any) -> ()

export type Connection = {
	Connected: boolean,
	Disconnect: (self: Connection) -> (),
}

export type Signal<T...> = {
	Connect: (self: Signal<T...>, callback: (T...) -> ()) -> Connection,
	Once: (self: Signal<T...>, callback: (T...) -> ()) -> Connection,
	Fire: (self: Signal<T...>, T...) -> (),
	Destroy: (self: Signal<T...>) -> (),
}

export type MaidTask =
	RBXScriptConnection
	| (() -> ())
	| Instance
	| { Destroy: (self: any) -> () }

export type WindowConfig = {
	Size: UDim2?,
	Position: UDim2?,
	MinSize: Vector2?,
}

export type ButtonConfig = {
	Label: string,
	Icon: string?,
	Variant: number?,
	Enabled: boolean?,
	LayoutOrder: number?,
}

export type ToggleConfig = {
	Label: string,
	Icon: string?,
	Default: boolean?,
	Enabled: boolean?,
	Flag: string?,
	LayoutOrder: number?,
}

export type LabelConfig = {
	Text: string,
	Color: Color3?,
	LayoutOrder: number?,
}

export type DividerConfig = {
	Text: string?,
	LayoutOrder: number?,
}

return {}

end)() end
} -- [RefId] = Closure

-- Holds the actual DOM data
local ObjectTree = {
    {
        1,
        2,
        {
            "Delirium"
        },
        {
            {
                20,
                2,
                {
                    "Theme"
                },
                {
                    {
                        21,
                        2,
                        {
                            "Colors"
                        }
                    },
                    {
                        22,
                        2,
                        {
                            "Icons"
                        }
                    }
                }
            },
            {
                23,
                1,
                {
                    "Utils"
                },
                {
                    {
                        25,
                        2,
                        {
                            "Maid"
                        }
                    },
                    {
                        24,
                        2,
                        {
                            "ErrorHandling"
                        }
                    },
                    {
                        26,
                        2,
                        {
                            "Signal"
                        }
                    },
                    {
                        27,
                        2,
                        {
                            "SmoothScroll"
                        }
                    }
                }
            },
            {
                28,
                2,
                {
                    "types"
                }
            },
            {
                2,
                2,
                {
                    "Components"
                },
                {
                    {
                        8,
                        2,
                        {
                            "Groupbox"
                        }
                    },
                    {
                        4,
                        2,
                        {
                            "ColorPicker"
                        }
                    },
                    {
                        12,
                        2,
                        {
                            "Textbox"
                        }
                    },
                    {
                        10,
                        2,
                        {
                            "Label"
                        }
                    },
                    {
                        5,
                        2,
                        {
                            "Description"
                        }
                    },
                    {
                        13,
                        2,
                        {
                            "Toggle"
                        }
                    },
                    {
                        11,
                        2,
                        {
                            "Slider"
                        }
                    },
                    {
                        3,
                        2,
                        {
                            "Button"
                        }
                    },
                    {
                        7,
                        2,
                        {
                            "Dropdown"
                        }
                    },
                    {
                        6,
                        2,
                        {
                            "Divider"
                        }
                    },
                    {
                        9,
                        2,
                        {
                            "Keybind"
                        }
                    }
                }
            },
            {
                14,
                2,
                {
                    "Core"
                },
                {
                    {
                        17,
                        2,
                        {
                            "SaveManager"
                        }
                    },
                    {
                        19,
                        2,
                        {
                            "Window"
                        }
                    },
                    {
                        18,
                        2,
                        {
                            "Tab"
                        }
                    },
                    {
                        16,
                        2,
                        {
                            "Popup"
                        }
                    },
                    {
                        15,
                        2,
                        {
                            "Notification"
                        }
                    }
                }
            }
        }
    }
}

-- Line offsets for debugging (only included when minifyTables is false)
local LineOffsets = {
    8,
    77,
    117,
    495,
    1568,
    1687,
    1768,
    2495,
    2795,
    3395,
    3465,
    3986,
    4274,
    4702,
    4713,
    5048,
    5560,
    5747,
    6028,
    7882,
    7929,
    7977,
    [24] = 8046,
    [25] = 8106,
    [26] = 8163,
    [27] = 8241,
    [28] = 8429
}

-- Misc AOT variable imports
local WaxVersion = "0.4.2"
local EnvName = "WaxRuntime"

-- ++++++++ RUNTIME IMPL BELOW ++++++++ --

-- Localizing certain libraries and built-ins for runtime efficiency
local string, task, setmetatable, error, next, table, unpack, coroutine, script, type, require, pcall, tostring, tonumber, _VERSION =
      string, task, setmetatable, error, next, table, unpack, coroutine, script, type, require, pcall, tostring, tonumber, _VERSION

local table_insert = table.insert
local table_remove = table.remove
local table_freeze = table.freeze or function(t) return t end -- lol

local coroutine_wrap = coroutine.wrap

local string_sub = string.sub
local string_match = string.match
local string_gmatch = string.gmatch

-- The Lune runtime has its own `task` impl, but it must be imported by its builtin
-- module path, "@lune/task"
if _VERSION and string_sub(_VERSION, 1, 4) == "Lune" then
    local RequireSuccess, LuneTaskLib = pcall(require, "@lune/task")
    if RequireSuccess and LuneTaskLib then
        task = LuneTaskLib
    end
end

local task_defer = task and task.defer

-- If we're not running on the Roblox engine, we won't have a `task` global
local Defer = task_defer or function(f, ...)
    coroutine_wrap(f)(...)
end

-- ClassName "IDs"
local ClassNameIdBindings = {
    [1] = "Folder",
    [2] = "ModuleScript",
    [3] = "Script",
    [4] = "LocalScript",
    [5] = "StringValue",
}

local RefBindings = {} -- [RefId] = RealObject

local ScriptClosures = {}
local ScriptClosureRefIds = {} -- [ScriptClosure] = RefId
local StoredModuleValues = {}
local ScriptsToRun = {}

-- wax.shared __index/__newindex
local SharedEnvironment = {}

-- We're creating 'fake' instance refs soley for traversal of the DOM for require() compatibility
-- It's meant to be as lazy as possible
local RefChildren = {} -- [Ref] = {ChildrenRef, ...}

-- Implemented instance methods
local InstanceMethods = {
    GetFullName = { {}, function(self)
        local Path = self.Name
        local ObjectPointer = self.Parent

        while ObjectPointer do
            Path = ObjectPointer.Name .. "." .. Path

            -- Move up the DOM (parent will be nil at the end, and this while loop will stop)
            ObjectPointer = ObjectPointer.Parent
        end

        return Path
    end},

    GetChildren = { {}, function(self)
        local ReturnArray = {}

        for Child in next, RefChildren[self] do
            table_insert(ReturnArray, Child)
        end

        return ReturnArray
    end},

    GetDescendants = { {}, function(self)
        local ReturnArray = {}

        for Child in next, RefChildren[self] do
            table_insert(ReturnArray, Child)

            for _, Descendant in next, Child:GetDescendants() do
                table_insert(ReturnArray, Descendant)
            end
        end

        return ReturnArray
    end},

    FindFirstChild = { {"string", "boolean?"}, function(self, name, recursive)
        local Children = RefChildren[self]

        for Child in next, Children do
            if Child.Name == name then
                return Child
            end
        end

        if recursive then
            for Child in next, Children do
                -- Yeah, Roblox follows this behavior- instead of searching the entire base of a
                -- ref first, the engine uses a direct recursive call
                return Child:FindFirstChild(name, true)
            end
        end
    end},

    FindFirstAncestor = { {"string"}, function(self, name)
        local RefPointer = self.Parent
        while RefPointer do
            if RefPointer.Name == name then
                return RefPointer
            end

            RefPointer = RefPointer.Parent
        end
    end},

    -- Just to implement for traversal usage
    WaitForChild = { {"string", "number?"}, function(self, name)
        return self:FindFirstChild(name)
    end},
}

-- "Proxies" to instance methods, with err checks etc
local InstanceMethodProxies = {}
for MethodName, MethodObject in next, InstanceMethods do
    local Types = MethodObject[1]
    local Method = MethodObject[2]

    local EvaluatedTypeInfo = {}
    for ArgIndex, TypeInfo in next, Types do
        local ExpectedType, IsOptional = string_match(TypeInfo, "^([^%?]+)(%??)")
        EvaluatedTypeInfo[ArgIndex] = {ExpectedType, IsOptional}
    end

    InstanceMethodProxies[MethodName] = function(self, ...)
        if not RefChildren[self] then
            error("Expected ':' not '.' calling member function " .. MethodName, 2)
        end

        local Args = {...}
        for ArgIndex, TypeInfo in next, EvaluatedTypeInfo do
            local RealArg = Args[ArgIndex]
            local RealArgType = type(RealArg)
            local ExpectedType, IsOptional = TypeInfo[1], TypeInfo[2]

            if RealArg == nil and not IsOptional then
                error("Argument " .. RealArg .. " missing or nil", 3)
            end

            if ExpectedType ~= "any" and RealArgType ~= ExpectedType and not (RealArgType == "nil" and IsOptional) then
                error("Argument " .. ArgIndex .. " expects type \"" .. ExpectedType .. "\", got \"" .. RealArgType .. "\"", 2)
            end
        end

        return Method(self, ...)
    end
end

local function CreateRef(className, name, parent)
    -- `name` and `parent` can also be set later by the init script if they're absent

    -- Extras
    local StringValue_Value

    -- Will be set to RefChildren later aswell
    local Children = setmetatable({}, {__mode = "k"})

    -- Err funcs
    local function InvalidMember(member)
        error(member .. " is not a valid (virtual) member of " .. className .. " \"" .. name .. "\"", 3)
    end
    local function ReadOnlyProperty(property)
        error("Unable to assign (virtual) property " .. property .. ". Property is read only", 3)
    end

    local Ref = {}
    local RefMetatable = {}

    RefMetatable.__metatable = false

    RefMetatable.__index = function(_, index)
        if index == "ClassName" then -- First check "properties"
            return className
        elseif index == "Name" then
            return name
        elseif index == "Parent" then
            return parent
        elseif className == "StringValue" and index == "Value" then
            -- Supporting StringValue.Value for Rojo .txt file conv
            return StringValue_Value
        else -- Lastly, check "methods"
            local InstanceMethod = InstanceMethodProxies[index]

            if InstanceMethod then
                return InstanceMethod
            end
        end

        -- Next we'll look thru child refs
        for Child in next, Children do
            if Child.Name == index then
                return Child
            end
        end

        -- At this point, no member was found; this is the same err format as Roblox
        InvalidMember(index)
    end

    RefMetatable.__newindex = function(_, index, value)
        -- __newindex is only for props fyi
        if index == "ClassName" then
            ReadOnlyProperty(index)
        elseif index == "Name" then
            name = value
        elseif index == "Parent" then
            -- We'll just ignore the process if it's trying to set itself
            if value == Ref then
                return
            end

            if parent ~= nil then
                -- Remove this ref from the CURRENT parent
                RefChildren[parent][Ref] = nil
            end

            parent = value

            if value ~= nil then
                -- And NOW we're setting the new parent
                RefChildren[value][Ref] = true
            end
        elseif className == "StringValue" and index == "Value" then
            -- Supporting StringValue.Value for Rojo .txt file conv
            StringValue_Value = value
        else
            -- Same err as __index when no member is found
            InvalidMember(index)
        end
    end

    RefMetatable.__tostring = function()
        return name
    end

    setmetatable(Ref, RefMetatable)

    RefChildren[Ref] = Children

    if parent ~= nil then
        RefChildren[parent][Ref] = true
    end

    return Ref
end

-- Create real ref DOM from object tree
local function CreateRefFromObject(object, parent)
    local RefId = object[1]
    local ClassNameId = object[2]
    local Properties = object[3] -- Optional
    local Children = object[4] -- Optional

    local ClassName = ClassNameIdBindings[ClassNameId]

    local Name = Properties and table_remove(Properties, 1) or ClassName

    local Ref = CreateRef(ClassName, Name, parent) -- 3rd arg may be nil if this is from root
    RefBindings[RefId] = Ref

    if Properties then
        for PropertyName, PropertyValue in next, Properties do
            Ref[PropertyName] = PropertyValue
        end
    end

    if Children then
        for _, ChildObject in next, Children do
            CreateRefFromObject(ChildObject, Ref)
        end
    end

    return Ref
end

local RealObjectRoot = CreateRef("Folder", "[" .. EnvName .. "]")
for _, Object in next, ObjectTree do
    CreateRefFromObject(Object, RealObjectRoot)
end

-- Now we'll set script closure refs and check if they should be ran as a BaseScript
for RefId, Closure in next, ClosureBindings do
    local Ref = RefBindings[RefId]

    ScriptClosures[Ref] = Closure
    ScriptClosureRefIds[Ref] = RefId

    local ClassName = Ref.ClassName
    if ClassName == "LocalScript" or ClassName == "Script" then
        table_insert(ScriptsToRun, Ref)
    end
end

local function LoadScript(scriptRef)
    local ScriptClassName = scriptRef.ClassName

    -- First we'll check for a cached module value (packed into a tbl)
    local StoredModuleValue = StoredModuleValues[scriptRef]
    if StoredModuleValue and ScriptClassName == "ModuleScript" then
        return unpack(StoredModuleValue)
    end

    local Closure = ScriptClosures[scriptRef]

    local function FormatError(originalErrorMessage)
        originalErrorMessage = tostring(originalErrorMessage)

        local VirtualFullName = scriptRef:GetFullName()

        -- Check for vanilla/Roblox format
        local OriginalErrorLine, BaseErrorMessage = string_match(originalErrorMessage, "[^:]+:(%d+): (.+)")

        if not OriginalErrorLine or not LineOffsets then
            return VirtualFullName .. ":*: " .. (BaseErrorMessage or originalErrorMessage)
        end

        OriginalErrorLine = tonumber(OriginalErrorLine)

        local RefId = ScriptClosureRefIds[scriptRef]
        local LineOffset = LineOffsets[RefId]

        local RealErrorLine = OriginalErrorLine - LineOffset + 1
        if RealErrorLine < 0 then
            RealErrorLine = "?"
        end

        return VirtualFullName .. ":" .. RealErrorLine .. ": " .. BaseErrorMessage
    end

    -- If it's a BaseScript, we'll just run it directly!
    if ScriptClassName == "LocalScript" or ScriptClassName == "Script" then
        local RunSuccess, ErrorMessage = pcall(Closure)
        if not RunSuccess then
            error(FormatError(ErrorMessage), 0)
        end
    else
        local PCallReturn = {pcall(Closure)}

        local RunSuccess = table_remove(PCallReturn, 1)
        if not RunSuccess then
            local ErrorMessage = table_remove(PCallReturn, 1)
            error(FormatError(ErrorMessage), 0)
        end

        StoredModuleValues[scriptRef] = PCallReturn
        return unpack(PCallReturn)
    end
end

-- We'll assign the actual func from the top of this output for flattening user globals at runtime
-- Returns (in a tuple order): wax, script, require
function ImportGlobals(refId)
    local ScriptRef = RefBindings[refId]

    local function RealCall(f, ...)
        local PCallReturn = {pcall(f, ...)}

        local CallSuccess = table_remove(PCallReturn, 1)
        if not CallSuccess then
            error(PCallReturn[1], 3)
        end

        return unpack(PCallReturn)
    end

    -- `wax.shared` index
    local WaxShared = table_freeze(setmetatable({}, {
        __index = SharedEnvironment,
        __newindex = function(_, index, value)
            SharedEnvironment[index] = value
        end,
        __len = function()
            return #SharedEnvironment
        end,
        __iter = function()
            return next, SharedEnvironment
        end,
    }))

    local Global_wax = table_freeze({
        -- From AOT variable imports
        version = WaxVersion,
        envname = EnvName,

        shared = WaxShared,

        -- "Real" globals instead of the env set ones
        script = script,
        require = require,
    })

    local Global_script = ScriptRef

    local function Global_require(module, ...)
        local ModuleArgType = type(module)

        local ErrorNonModuleScript = "Attempted to call require with a non-ModuleScript"
        local ErrorSelfRequire = "Attempted to call require with self"

        if ModuleArgType == "table" and RefChildren[module]  then
            if module.ClassName ~= "ModuleScript" then
                error(ErrorNonModuleScript, 2)
            elseif module == ScriptRef then
                error(ErrorSelfRequire, 2)
            end

            return LoadScript(module)
        elseif ModuleArgType == "string" and string_sub(module, 1, 1) ~= "@" then
            -- The control flow on this SUCKS

            if #module == 0 then
                error("Attempted to call require with empty string", 2)
            end

            local CurrentRefPointer = ScriptRef

            if string_sub(module, 1, 1) == "/" then
                CurrentRefPointer = RealObjectRoot
            elseif string_sub(module, 1, 2) == "./" then
                module = string_sub(module, 3)
            end

            local PreviousPathMatch
            for PathMatch in string_gmatch(module, "([^/]*)/?") do
                local RealIndex = PathMatch
                if PathMatch == ".." then
                    RealIndex = "Parent"
                end

                -- Don't advance dir if it's just another "/" either
                if RealIndex ~= "" then
                    local ResultRef = CurrentRefPointer:FindFirstChild(RealIndex)
                    if not ResultRef then
                        local CurrentRefParent = CurrentRefPointer.Parent
                        if CurrentRefParent then
                            ResultRef = CurrentRefParent:FindFirstChild(RealIndex)
                        end
                    end

                    if ResultRef then
                        CurrentRefPointer = ResultRef
                    elseif PathMatch ~= PreviousPathMatch and PathMatch ~= "init" and PathMatch ~= "init.server" and PathMatch ~= "init.client" then
                        error("Virtual script path \"" .. module .. "\" not found", 2)
                    end
                end

                -- For possible checks next cycle
                PreviousPathMatch = PathMatch
            end

            if CurrentRefPointer.ClassName ~= "ModuleScript" then
                error(ErrorNonModuleScript, 2)
            elseif CurrentRefPointer == ScriptRef then
                error(ErrorSelfRequire, 2)
            end

            return LoadScript(CurrentRefPointer)
        end

        return RealCall(require, module, ...)
    end

    -- Now, return flattened globals ready for direct runtime exec
    return Global_wax, Global_script, Global_require
end

for _, ScriptRef in next, ScriptsToRun do
    Defer(LoadScript, ScriptRef)
end

-- AoT adjustment: Load init module (MainModule behavior)
return LoadScript(RealObjectRoot:GetChildren()[1])