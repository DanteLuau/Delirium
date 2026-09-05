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

local Tooltip      = require(script.Utils.Tooltip)

-- ── Public types ──────────────────────────────────────────────────────────────

export type PillPosition = "Top" | "Bottom" | "Left" | "Right"

export type WindowConfig = {
	Size:         UDim2?,
	Position:     UDim2?,
	MinSize:      Vector2?,
	AutoScale:    boolean?,
	PillPosition: PillPosition?,
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
Delirium.Tooltip     = Tooltip
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

local Maid    = require(script.Parent.Parent.Utils.Maid)
local Signal  = require(script.Parent.Parent.Utils.Signal)
local Theme   = require(script.Parent.Parent.Theme)
local Tooltip = require(script.Parent.Parent.Utils.Tooltip)

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
	Tooltip: string?,
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
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			releasePress()
		end
	end))

	self._maid:GiveTask(btn.MouseButton1Click:Connect(function()
		if not self._enabled then return end
		clicked:Fire()
	end))

	if config.Tooltip and #config.Tooltip > 0 then
		self._maid:GiveTask(Tooltip.bind(inner, config.Tooltip))
	end

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
local Tooltip     = require(script.Parent.Parent.Utils.Tooltip)

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
	Tooltip:       string?,
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

local function relPos(frame: GuiObject, customPos: Vector2?): Vector2
	local m  = customPos or UserInputService:GetMouseLocation()
	local ap = frame.AbsolutePosition
	local as = frame.AbsoluteSize
	if as.X <= 0 or as.Y <= 0 then return Vector2.zero end
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
	popup.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
	popup.BackgroundTransparency = 1
	popup.BorderSizePixel  = 0
	popup.ZIndex           = POPUP_Z
	popup.Visible          = false
	mkCorner(popup, 8)
	mkStroke(popup, Color3.fromRGB(48, 48, 56), 1)
	maid:GiveTask(popup)

	local bottomGlow                  = Instance.new("Frame")
	bottomGlow.Name                   = "BottomGlow"
	bottomGlow.Position               = UDim2.new(0, 0, 1, -1)
	bottomGlow.Size                   = UDim2.new(1, 0, 0, 1)
	bottomGlow.BackgroundColor3       = Color3.fromHSV(h, s, v)
	bottomGlow.BorderSizePixel        = 0
	bottomGlow.ZIndex                 = POPUP_Z + 1
	bottomGlow.Parent                 = popup

	local glowGrad = Instance.new("UIGradient")
	glowGrad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.35, 0.45),
		NumberSequenceKeypoint.new(0.65, 0.45),
		NumberSequenceKeypoint.new(1, 1),
	})
	glowGrad.Parent = bottomGlow

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
			bottomGlow.BackgroundColor3 = color
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
			bottomGlow.BackgroundColor3 = color
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

	local function pump(pos: Vector2?)
		if dragging == "canvas" then
			local p = relPos(canvas, pos)
			s, v = p.X, 1 - p.Y
		elseif dragging == "hue" then
			h = relPos(hueBar, pos).Y
		elseif dragging == "alpha" and alphaBar then
			a = 1 - relPos(alphaBar, pos).Y
		end
		refresh("drag")
		fireChanged()
	end

	local function beginDrag(target: DragTarget, input: InputObject?)
		if not isEnabled then return end
		dragging = target
		setHeld(target)
		local initPos = if input then Vector2.new(input.Position.X, input.Position.Y) else nil
		pump(initPos)
	end

	maid:GiveTask(UserInputService.InputChanged:Connect(function(input: InputObject)
		if not dragging then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch then
			pump(Vector2.new(input.Position.X, input.Position.Y))
		end
	end))

	maid:GiveTask(UserInputService.InputEnded:Connect(function(input: InputObject)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch then return end
		if dragging then
			dragging = nil
			setHeld(nil)
		end
	end))

	-- ── Drag input bindings ───────────────────────────────────────────────────

	maid:GiveTask(canvasBtn.InputBegan:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			beginDrag("canvas", input)
		end
	end))

	maid:GiveTask(hueBtn.InputBegan:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			beginDrag("hue", input)
		end
	end))

	if showAlpha and alphaBtn then
		local abtn = alphaBtn :: TextButton
		maid:GiveTask(abtn.InputBegan:Connect(function(input: InputObject)
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch then
				beginDrag("alpha", input)
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

		-- Center on the window canvas frame; fall back to full-screen center
		local screenW = overlayParent.AbsoluteSize.X
		local screenH = overlayParent.AbsoluteSize.Y
		local pw = math.min(POPUP_W, screenW - 16)
		local ph = POPUP_H
		popup.Size = UDim2.fromOffset(pw, ph)
		local cx, cy
		if windowCanvas and windowCanvas.Parent then
			local canvasPos  = windowCanvas.AbsolutePosition
			local canvasSize = windowCanvas.AbsoluteSize
			cx = canvasPos.X + canvasSize.X / 2
			cy = canvasPos.Y + canvasSize.Y / 2
		else
			cx = screenW / 2
			cy = screenH / 2
		end
		cx = math.clamp(cx, pw / 2 + 8, screenW - pw / 2 - 8)
		cy = math.clamp(cy, ph / 2 + 8, screenH - ph / 2 - 8)
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

	if config.Tooltip and #config.Tooltip > 0 then
		maid:GiveTask(Tooltip.bind(inner, config.Tooltip))
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
local Tooltip      = require(script.Parent.Parent.Utils.Tooltip)

local TWEEN_PRESS    = TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local TWEEN_RELEASE  = TweenInfo.new(0.30, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local TWEEN_STROKE   = TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local TWEEN_HOVER    = TweenInfo.new(0.20, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local TWEEN_EXPAND   = TweenInfo.new(0.40, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local TWEEN_COLLAPSE = TweenInfo.new(0.32, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local TWEEN_ARROW    = TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local TWEEN_FADE     = TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local TWEEN_SHADOW   = TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

local SD_REST  = { BackgroundTransparency = 0.75, Position = UDim2.new(0.5, 0, 0, 3) }
local SD_HOVER = { BackgroundTransparency = 0.65, Position = UDim2.new(0.5, 0, 0, 5) }
local SD_PRESS = { BackgroundTransparency = 0.90, Position = UDim2.new(0.5, 0, 0, 1) }

local HEADER_H = 36
local LIST_GAP = 4
local OPTION_H = 34
local MAX_H    = 170
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
	Tooltip:     string?,
	-- options: plain string array OR {Label,Value} table array
	Options:     { any }?,
	-- multi-select
	MultiSelect: boolean?,
	-- initial selection: single value OR array of values
	Default:     any?,
	Flag:        string?,
	-- Auto-populating options: "Player" | "Team"
	SpecialType: string?,
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
	_listShadow:    Frame?,
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

	local initialOptions = config.Options or {}
	if config.SpecialType == "Player" then
		local Players = game:GetService("Players")
		local function getPlayerList(): { string }
			local list = {}
			for _, p in ipairs(Players:GetPlayers()) do
				table.insert(list, p.Name)
			end
			return list
		end
		initialOptions = getPlayerList()
		self._maid:GiveTask(Players.PlayerAdded:Connect(function()
			self:SetOptions(getPlayerList())
		end))
		self._maid:GiveTask(Players.PlayerRemoving:Connect(function()
			self:SetOptions(getPlayerList())
		end))
	elseif config.SpecialType == "Team" then
		local Teams = game:GetService("Teams")
		local function getTeamList(): { string }
			local list = {}
			for _, t in ipairs(Teams:GetTeams()) do
				table.insert(list, t.Name)
			end
			return list
		end
		initialOptions = getTeamList()
		self._maid:GiveTask(Teams.ChildAdded:Connect(function()
			self:SetOptions(getTeamList())
		end))
		self._maid:GiveTask(Teams.ChildRemoved:Connect(function()
			self:SetOptions(getTeamList())
		end))
	end

	self._options        = normalizeOptions(initialOptions)
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
	arrow.AnchorPoint            = Vector2.new(0.5, 0.5)
	arrow.Position               = UDim2.new(1, -(ARROW_W / 2 + 6), 0.5, 0)
	arrow.Size                   = UDim2.fromOffset(ARROW_W, ARROW_W)
	arrow.BackgroundTransparency = 1
	arrow.Font                   = Theme.Font.Body
	arrow.Text                   = "▾"
	arrow.TextSize               = 14
	arrow.TextColor3             = Theme.Colors.TextSecondary
	arrow.TextXAlignment         = Enum.TextXAlignment.Center
	arrow.TextYAlignment         = Enum.TextYAlignment.Center
	arrow.Rotation               = 0
	arrow.ZIndex                 = 4
	arrow.Parent                 = inner
	self._arrow                  = arrow

	-- header value text
	local initText, initHas    = headerText(self)
	local valueLabel                  = Instance.new("TextLabel")
	valueLabel.Name                   = "ValueLabel"
	valueLabel.Size                   = UDim2.new(1, -(ARROW_W + 16), 1, 0)
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

	-- ── list container & shadow ───────────────────────────────────────────────
	local listShadow                  = Instance.new("Frame")
	listShadow.Name                   = "ListShadow"
	listShadow.AnchorPoint            = Vector2.new(0.5, 0)
	listShadow.Position               = UDim2.new(0.5, 0, 0, HEADER_H + LIST_GAP + 2)
	listShadow.Size                   = UDim2.new(1, 0, 0, 0)
	listShadow.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
	listShadow.BackgroundTransparency = 1
	listShadow.BorderSizePixel        = 0
	listShadow.ZIndex                 = 1
	local listShadowCorner            = Instance.new("UICorner")
	listShadowCorner.CornerRadius     = UDim.new(0, Theme.Radius.Small + 1)
	listShadowCorner.Parent           = listShadow
	listShadow.Parent                 = frame
	self._listShadow                  = listShadow

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

	-- ── open / close (inline accordion expand / collapse) ──────────────────────
	local function closeDropdown()
		if not self._open then return end
		self._open = false
		TweenService:Create(arrow,      TWEEN_ARROW,    { Rotation = 0 }):Play()
		TweenService:Create(stroke,     TWEEN_STROKE,   { Color = Theme.Colors.Border }):Play()
		TweenService:Create(listWrap,   TWEEN_COLLAPSE, { Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1 }):Play()
		TweenService:Create(listStroke, TWEEN_FADE,     { Transparency = 1 }):Play()
		TweenService:Create(listShadow, TWEEN_COLLAPSE, { Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1 }):Play()
		TweenService:Create(frame,      TWEEN_COLLAPSE, { Size = UDim2.new(1, 0, 0, HEADER_H) }):Play()
	end

	local function openDropdown()
		if self._open or not self._enabled then return end
		self._open = true
		TweenService:Create(arrow,      TWEEN_ARROW,  { Rotation = 180 }):Play()
		TweenService:Create(stroke,     TWEEN_STROKE, { Color = Theme.Colors.Accent }):Play()
		TweenService:Create(listWrap,   TWEEN_EXPAND, { Size = UDim2.new(1, 0, 0, self._targetH), BackgroundTransparency = 0 }):Play()
		TweenService:Create(listStroke, TWEEN_FADE,   { Transparency = 0 }):Play()
		TweenService:Create(listShadow, TWEEN_EXPAND, { Size = UDim2.new(1, 0, 0, self._targetH + 4), BackgroundTransparency = 0.75 }):Play()
		TweenService:Create(frame,      TWEEN_EXPAND, { Size = UDim2.new(1, 0, 0, HEADER_H + LIST_GAP + self._targetH) }):Play()
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
				else Theme.Colors.TextSecondary
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
					BackgroundTransparency = 0.85,
					BackgroundColor3       = Theme.Colors.SurfaceHover,
				}):Play()
				local isSel = if self._multiSelect
					then self._selectedSet[opt.Value] == true
					else self._selectedValue == opt.Value
				if not isSel then
					TweenService:Create(optLabel, TWEEN_HOVER, { TextColor3 = Theme.Colors.TextPrimary }):Play()
				end
			end))
			self._optionMaid:GiveTask(optHit.MouseLeave:Connect(function()
				TweenService:Create(optFrame, TWEEN_HOVER, {
					BackgroundTransparency = 1,
					BackgroundColor3       = Color3.fromHex("#1a1a1a"),
				}):Play()
				local isSel = if self._multiSelect
					then self._selectedSet[opt.Value] == true
					else self._selectedValue == opt.Value
				if not isSel then
					TweenService:Create(optLabel, TWEEN_HOVER, { TextColor3 = Theme.Colors.TextSecondary }):Play()
				end
			end))

			self._optionMaid:GiveTask(optHit.MouseButton1Click:Connect(function()
				if not self._enabled then return end

				if self._multiSelect then
					-- toggle selection
					if self._selectedSet[opt.Value] then
						self._selectedSet[opt.Value] = nil
						optLabel.TextColor3 = Theme.Colors.TextSecondary
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
								lbl.TextColor3 = Theme.Colors.TextSecondary
							end
						end
					end
					optLabel.TextColor3   = Theme.Colors.Accent
					self._selectedValue   = opt.Value
					self.Value            = opt.Value
					valueLabel.Text       = opt.Label
					valueLabel.TextColor3 = Theme.Colors.TextPrimary
					changed:Fire(opt.Value, opt.Label)
					task.delay(0.10, function()
						closeDropdown()
					end)
				end
			end))

			optFrame.Parent = scroll
		end
	end

	self._buildOptions = buildOptions
	buildOptions()

	-- ── hover / click on header ───────────────────────────────────────────────
	local hovering = false
	local pressing = false

	local function releasePress()
		if not pressing then return end
		pressing = false
		local shadowTarget = if hovering then SD_HOVER else SD_REST
		local flashTarget  = if hovering then 0.92 else 1
		TweenService:Create(inner,  TWEEN_RELEASE, { Size = UDim2.new(1, 0, 0, HEADER_H), Position = UDim2.new(0.5, 0, 0, 0) }):Play()
		TweenService:Create(flash,  TWEEN_RELEASE, { BackgroundTransparency = flashTarget }):Play()
		TweenService:Create(shadow, TWEEN_SHADOW,  {
			BackgroundTransparency = shadowTarget.BackgroundTransparency,
			Position               = shadowTarget.Position,
			Size                   = UDim2.new(1, 0, 0, HEADER_H + 4),
		}):Play()
		TweenService:Create(stroke, TWEEN_STROKE, {
			Color = if (hovering or self._open) then Theme.Colors.Accent else Theme.Colors.Border,
		}):Play()
	end

	self._maid:GiveTask(hit.MouseEnter:Connect(function()
		if not self._enabled then return end
		hovering = true
		if not pressing then
			TweenService:Create(stroke, TWEEN_STROKE, { Color = Theme.Colors.Accent }):Play()
			TweenService:Create(flash,  TWEEN_HOVER,  { BackgroundTransparency = 0.92 }):Play()
			TweenService:Create(shadow, TWEEN_SHADOW, SD_HOVER):Play()
		end
	end))

	self._maid:GiveTask(hit.MouseLeave:Connect(function()
		if not self._enabled then return end
		hovering = false
		if pressing then
			releasePress()
		else
			if not self._open then
				TweenService:Create(stroke, TWEEN_STROKE, { Color = Theme.Colors.Border }):Play()
			end
			TweenService:Create(flash,  TWEEN_HOVER,  { BackgroundTransparency = 1 }):Play()
			TweenService:Create(shadow, TWEEN_SHADOW, SD_REST):Play()
		end
	end))

	self._maid:GiveTask(hit.MouseButton1Down:Connect(function()
		if not self._enabled then return end
		pressing = true
		TweenService:Create(inner,  TWEEN_PRESS, { Size = UDim2.new(1, -6, 0, HEADER_H - 2), Position = UDim2.new(0.5, 0, 0, 1) }):Play()
		TweenService:Create(flash,  TWEEN_PRESS, { BackgroundTransparency = 0.84 }):Play()
		TweenService:Create(shadow, TWEEN_PRESS, {
			BackgroundTransparency = SD_PRESS.BackgroundTransparency,
			Position               = SD_PRESS.Position,
			Size                   = UDim2.new(1, -6, 0, HEADER_H + 2),
		}):Play()
		TweenService:Create(stroke, TWEEN_PRESS, { Color = Theme.Colors.AccentHover }):Play()
	end))

	self._maid:GiveTask(hit.MouseButton1Up:Connect(function()
		if not self._enabled then return end
		releasePress()
	end))

	self._maid:GiveTask(UserInputService.InputEnded:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			releasePress()
		end
	end))

	self._maid:GiveTask(hit.MouseButton1Click:Connect(function()
		if not self._enabled then return end
		if self._open then
			closeDropdown()
		else
			openDropdown()
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

	if config.Tooltip and #config.Tooltip > 0 then
		self._maid:GiveTask(Tooltip.bind(inner, config.Tooltip))
	end

	return self
end

-- ── public API ────────────────────────────────────────────────────────────────

function Dropdown:SetOptions(options: { any })
	if self._open then
		self._closeDropdown()
		self._arrow.Rotation                  = 0
		self._listWrap.Size                   = UDim2.new(1, 0, 0, 0)
		self._listWrap.BackgroundTransparency = 1
		self._listStroke.Transparency         = 1
		if self._listShadow then
			self._listShadow.Size                   = UDim2.new(1, 0, 0, 0)
			self._listShadow.BackgroundTransparency = 1
		end
		self._frame.Size                      = UDim2.new(1, 0, 0, HEADER_H)
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
		if self._listShadow then
			self._listShadow.Size                   = UDim2.new(1, 0, 0, 0)
			self._listShadow.BackgroundTransparency = 1
		end
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
	_win:           any?,
	_tabName:       string?,
	_tabIdx:        number?,
	_groupTitle:    string?,
	_layoutOrder:   number,
}

-- ── Class ─────────────────────────────────────────────────────────────────

local Groupbox = {} :: { __index: any }
Groupbox.__index = Groupbox

--[[
	Groupbox.new(title, gui, parentMaid, canvas, window, tabName, tabIdx)

	title      — text shown at the top-left of the bordered box
	gui        — ScreenGui root forwarded to Dropdown as OverlayParent
	parentMaid — the Tab's maid; owns this groupbox's maid (cascade cleanup)
]]
function Groupbox.new(title: string, gui: ScreenGui, parentMaid: any, canvas: Frame?, window: any?, tabName: string?, tabIdx: number?): GroupboxImpl
	local self        = setmetatable({}, Groupbox) :: any
	self._maid        = Maid.new()
	self._gui         = gui
	self._canvas      = canvas
	self._win         = window
	self._tabName     = tabName or "Main"
	self._tabIdx      = tabIdx or 1
	self._groupTitle  = if #title > 0 then title else nil
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
function Groupbox:_addToContent(comp: any, config: any?, typeName: string?): any
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

	if self._win and self._win._search and config and comp.GetFrame then
		local label = config.Label or config.Title or config.Text or config.Name or ""
		if typeof(label) == "string" and #label > 0 then
			self._win._search:Register({
				Label     = label,
				TabName   = self._tabName or "Main",
				TabIdx    = self._tabIdx or 1,
				GroupName = self._groupTitle,
				TypeName  = typeName or "Control",
				Comp      = comp,
				Frame     = comp:GetFrame(),
			})
		end
	end

	self._maid:GiveTask(comp)
	return comp
end

-- ── Public Add* API ────────────────────────────────────────────────────────

function Groupbox:AddButton(config: {
	Label: string, Variant: number?, Enabled: boolean?, description: string?, Tooltip: string?,
})
	local c = config :: any
	c.LayoutOrder = self:_nextOrder()
	return self:_addToContent(Button.new(c), c, "Button")
end

function Groupbox:AddToggle(config: {
	Label: string, Icon: string?, Default: boolean?, Enabled: boolean?, description: string?, Tooltip: string?,
})
	local c = config :: any
	c.LayoutOrder = self:_nextOrder()
	return self:_addToContent(Toggle.new(c), c, "Toggle")
end

function Groupbox:AddLabel(text: string, color: Color3?)
	local lbl = Label.new({
		Text        = text,
		Color       = color,
		LayoutOrder = self:_nextOrder(),
	})
	return self:_addToContent(lbl, nil, "Label")
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
	return self:_addToContent(div, nil, "Divider")
end

function Groupbox:AddSlider(config: {
	Label: string, Min: number?, Max: number?,
	Default: number?, Step: number?, Enabled: boolean?, description: string?, Tooltip: string?,
})
	local c = config :: any
	c.LayoutOrder = self:_nextOrder()
	return self:_addToContent(Slider.new(c), c, "Slider")
end

function Groupbox:AddTextbox(config: {
	Label: string?, Placeholder: string?, Default: string?,
	MaxLength: number?, ClearOnFocus: boolean?, Enabled: boolean?, description: string?, Tooltip: string?,
})
	local c = config :: any
	c.LayoutOrder = self:_nextOrder()
	return self:_addToContent(Textbox.new(c), c, "Textbox")
end

function Groupbox:AddKeybind(config: {
	Label: string, Default: Enum.KeyCode?,
	Blacklist: { any }?, Enabled: boolean?, description: string?, Tooltip: string?,
})
	local c = config :: any
	c.LayoutOrder = self:_nextOrder()
	return self:_addToContent(Keybind.new(c), c, "Keybind")
end

function Groupbox:AddDropdown(config: {
	Label: string?, Options: { any }, MultiSelect: boolean?,
	Default: any?, Placeholder: string?, Enabled: boolean?, description: string?, Tooltip: string?,
})
	local c = config :: any
	c.LayoutOrder   = self:_nextOrder()
	return self:_addToContent(Dropdown.new(c), c, "Dropdown")
end

function Groupbox:AddColorPicker(config: {
	Label: string, Default: Color3?, ShowAlpha: boolean?,
	Flag: string?, Risky: boolean?, Enabled: boolean?, description: string?, Tooltip: string?,
})
	local c = config :: any
	c.LayoutOrder   = self:_nextOrder()
	c.OverlayParent = self._gui
	c.Canvas        = self._canvas
	return self:_addToContent(ColorPicker.new(c), c, "ColorPicker")
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
local Tooltip     = require(script.Parent.Parent.Utils.Tooltip)

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
	Tooltip:     string?,
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
	SyncTo:       (self: KeybindImpl, toggleObj: any) -> (),
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
	inner.ClipsDescendants   = true
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

	-- Pill click — enter / exit binding mode (or trigger action on mobile touch)
	self._maid:GiveTask(pillHit.MouseButton1Click:Connect(function()
		if not self._enabled then return end
		if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
			if self._mode == "Toggle" then
				self._toggleState = not self._toggleState
				toggled:Fire(self._toggleState)
			else
				pressed:Fire()
			end
			TweenService:Create(self._flash, TWEEN_HOVER, { BackgroundTransparency = 0.85 }):Play()
			task.delay(0.15, function()
				TweenService:Create(self._flash, TWEEN_HOVER, { BackgroundTransparency = 1 }):Play()
			end)
			return
		end

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

	if config.Tooltip and #config.Tooltip > 0 then
		self._maid:GiveTask(Tooltip.bind(inner, config.Tooltip))
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

function Keybind:SyncTo(toggleObj: any)
	if not toggleObj then return end
	if self._mode == "Toggle" then
		self._maid:GiveTask(self.Toggled:Connect(function(state: boolean)
			if toggleObj.SetValue then
				toggleObj:SetValue(state)
			end
		end))
	else
		self._maid:GiveTask(self.Pressed:Connect(function()
			if toggleObj.SetValue and toggleObj.Value ~= nil then
				toggleObj:SetValue(not toggleObj.Value)
			end
		end))
	end
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

end)() end,
    function()local wax,script,require=ImportGlobals(12)local ImportGlobals return (function(...)--!strict

local TweenService = game:GetService("TweenService")

local Maid        = require(script.Parent.Parent.Utils.Maid)
local Signal      = require(script.Parent.Parent.Utils.Signal)
local Theme       = require(script.Parent.Parent.Theme)
local SaveManager = require(script.Parent.Parent.Core.SaveManager)
local Tooltip     = require(script.Parent.Parent.Utils.Tooltip)

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
	Tooltip: string?,
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

	if config.Tooltip and #config.Tooltip > 0 then
		self._maid:GiveTask(Tooltip.bind(inner, config.Tooltip))
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
local Tooltip     = require(script.Parent.Parent.Utils.Tooltip)

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
local TRACK_W      = 46
local TRACK_H      = 22
local THUMB_W      = 20
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
	Tooltip: string?,
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
	_maid:        any,
	_frame:       Frame,
	_inner:       Frame,
	_content:     Frame,
	_label:       TextLabel,
	_icon:        ImageLabel?,
	_track:       Frame,
	_trackStroke: UIStroke,
	_thumb:       Frame,
	_thumbStroke: UIStroke,
	_stroke:      UIStroke,
	_scale:       UIScale,
	_flash:       Frame,
	_shadow:      Frame,
	_enabled:     boolean,
	_value:       boolean,
	_risky:       boolean,
	_morphToken:  number?,
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
	inner.ClipsDescendants   = true
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

	-- ── Track ─────────────────────────────────────────────────────────────────
	local track              = Instance.new("Frame")
	track.Name               = "Track"
	track.Size               = UDim2.fromOffset(TRACK_W, TRACK_H)
	track.Position           = UDim2.new(1, -TRACK_W, 0.5, -(TRACK_H / 2))
	track.BackgroundColor3   = if self._value then Theme.Colors.Accent else Color3.fromHex("#1a1a1a")
	track.BorderSizePixel    = 0
	track.ZIndex             = 4
	track.Parent             = inner
	local trackCorner        = Instance.new("UICorner")
	trackCorner.CornerRadius = UDim.new(0, Theme.Radius.Pill)
	trackCorner.Parent       = track
	self._track              = track

	local trackStroke           = Instance.new("UIStroke")
	trackStroke.Color           = if self._value then Theme.Colors.BorderAccent else Theme.Colors.Border
	trackStroke.Thickness       = 1
	trackStroke.Transparency    = if self._value then 0.1 else 0.4
	trackStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	trackStroke.Parent          = track
	self._trackStroke           = trackStroke

	-- ── Thumb (Floating Frosted Capsule) ──────────────────────────────────────
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

	local thumbGrad    = Instance.new("UIGradient")
	thumbGrad.Color    = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromHex("#ffffff")),
		ColorSequenceKeypoint.new(1, Color3.fromHex("#e2e4e8")),
	})
	thumbGrad.Rotation = 90
	thumbGrad.Parent   = thumb

	local thumbStroke           = Instance.new("UIStroke")
	thumbStroke.Color           = Color3.fromRGB(255, 255, 255)
	thumbStroke.Thickness       = 1
	thumbStroke.Transparency    = 0.45
	thumbStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	thumbStroke.Parent          = thumb
	self._thumbStroke           = thumbStroke



	-- Hit target
	local btn                  = Instance.new("TextButton")
	btn.Name                   = "Hit"
	btn.Size                   = UDim2.fromScale(1, 1)
	btn.BackgroundTransparency = 1
	btn.Text                   = ""
	btn.AutoButtonColor        = false
	btn.ZIndex                 = 7
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
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
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

	if config.Tooltip and #config.Tooltip > 0 then
		self._maid:GiveTask(Tooltip.bind(inner, config.Tooltip))
	end

	return self
end

function Toggle:SetValue(value: boolean)
	self._value = value
	self.Value  = value

	-- Token prevents a queued settle from landing after a rapid double-toggle
	self._morphToken = (self._morphToken or 0) + 1
	local currentToken = self._morphToken

	-- Track color & border stroke glide smoothly
	TweenService:Create(self._track, TWEEN_TRACK, {
		BackgroundColor3 = if value then Theme.Colors.Accent else Color3.fromHex("#1a1a1a"),
	}):Play()

	TweenService:Create(self._trackStroke, TWEEN_TRACK, {
		Color        = if value then Theme.Colors.BorderAccent else Theme.Colors.Border,
		Transparency = if value then 0.1 else 0.4,
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

-- Notification — Starlight-inspired notification system for Delirium.
-- Stacking max 6 cards pinned to bottom-right (or top-right on mobile).
-- Ground-up modern redesign: Frosted semantic icon badge, dual-layer acrylic sheen,
-- ambient status glow, ultra-smooth +85px deep slide exit, and fluid stack reflow.

local TweenService     = game:GetService("TweenService")
local TextService      = game:GetService("TextService")
local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local Theme = require(script.Parent.Parent.Theme)

-- ── Constants ─────────────────────────────────────────────────────────────────

local TOAST_W          = 276
local MAX_VISIBLE      = 6
local GAP              = 6
local SLIDE_IN_OFFSET  = 45  -- Inward arrival glide from right margin
local SLIDE_OUT_OFFSET = 85  -- Deep rightward sweep into screen margin on dismiss

-- Entrance: Cubic.Out — responsive initial glide, soft graceful deceleration
local TWEEN_IN_SIZE  = TweenInfo.new(0.42, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
local TWEEN_IN_POS   = TweenInfo.new(0.44, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
local TWEEN_IN_FADE  = TweenInfo.new(0.38, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)

-- Exit: Cubic.Out with long trajectory — immediate tactile response, buttery glide
local TWEEN_OUT_SIZE = TweenInfo.new(0.38, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
local TWEEN_OUT_POS  = TweenInfo.new(0.40, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
local TWEEN_OUT_FADE = TweenInfo.new(0.32, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)

-- Default semantic icons (Lucide / rbxassetid)
local DEFAULT_ICONS: { [string]: string } = {
	info    = "rbxassetid://10723415903",
	success = "rbxassetid://10709790387",
	warning = "rbxassetid://10709752935",
	error   = "rbxassetid://10747384394",
}

-- ── Types ─────────────────────────────────────────────────────────────────────

export type NotifyConfig = {
	Title    : string?,
	Message  : string?,
	Content  : string?,   -- Starlight alias for Message
	Type     : string?,   -- "info" | "success" | "warning" | "error"
	Icon     : (string | number)?,
	Duration : number?,
}

type ActiveToast = {
	wrapper     : Frame,
	card        : CanvasGroup,
	stroke      : UIStroke,
	dismissed   : boolean,
	cancelTimer : () -> (),
}

-- ── Singleton State ───────────────────────────────────────────────────────────

local _gui          : ScreenGui?        = nil
local _container    : Frame?            = nil
local _layout       : UIListLayout?     = nil
local _active       : { ActiveToast }   = {}
local _orderCounter : number            = 0

-- ── Helpers ───────────────────────────────────────────────────────────────────

local function typeColor(notifType: string?): Color3
	local t = string.lower(notifType or "info")
	if     t == "success" then return Theme.Colors.Success
	elseif t == "warning" then return Theme.Colors.Warning
	elseif t == "error"   then return Theme.Colors.Error
	else                       return Theme.Colors.Accent
	end
end

local function resolveIcon(icon: (string | number)?, notifType: string?): string
	if type(icon) == "number" then
		return "rbxassetid://" .. tostring(icon)
	elseif type(icon) == "string" and #icon > 0 then
		if string.sub(icon, 1, 13) == "rbxassetid://" or string.sub(icon, 1, 4) == "http" then
			return icon
		end
		local ok, id = pcall(function()
			return Theme.Icons.Get(icon)
		end)
		if ok and id and id ~= "rbxassetid://0" then
			return id
		end
		return icon
	end

	local t = string.lower(notifType or "info")
	return DEFAULT_ICONS[t] or DEFAULT_ICONS.info
end

local function formatElapsed(elapsed: number): string
	if elapsed <= 4 then
		return "now"
	elseif elapsed < 60 then
		return string.format("%ds ago", math.floor(elapsed))
	elseif elapsed < 3600 then
		return string.format("%dm ago", math.floor(elapsed / 60))
	else
		return string.format("%dh ago", math.floor(elapsed / 3600))
	end
end

-- ── GUI Bootstrap ─────────────────────────────────────────────────────────────

local function ensureGui()
	if _gui and _gui.Parent and _container and _container.Parent then return end

	local gui          = Instance.new("ScreenGui")
	gui.Name           = "DeliriumNotifications"
	gui.ResetOnSpawn   = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.IgnoreGuiInset = true
	pcall(function() gui.DisplayOrder = 1000 end)

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

	local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
	local cam = workspace.CurrentCamera
	local vp = if cam then cam.ViewportSize else Vector2.new(1024, 768)
	if vp.X < 800 or vp.Y < 600 then
		isMobile = true
	end

	local container                  = Instance.new("Frame")
	container.Name                   = "Notifications"
	container.Size                   = UDim2.fromOffset(TOAST_W, 0)
	container.AutomaticSize          = Enum.AutomaticSize.Y
	container.BackgroundTransparency = 1
	container.BorderSizePixel        = 0
	container.ClipsDescendants       = false

	local layout               = Instance.new("UIListLayout")
	layout.FillDirection       = Enum.FillDirection.Vertical
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	layout.SortOrder           = Enum.SortOrder.LayoutOrder
	layout.Padding             = UDim.new(0, GAP)
	layout.Parent              = container

	if isMobile then
		container.AnchorPoint    = Vector2.new(1, 0)
		container.Position       = UDim2.new(1, -12, 0, 44)
		layout.VerticalAlignment = Enum.VerticalAlignment.Top
	else
		container.AnchorPoint    = Vector2.new(1, 1)
		container.Position       = UDim2.new(1, -16, 1, -16)
		layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	end

	container.Parent = gui
	_gui             = gui
	_container       = container
	_layout          = layout
end

-- ── Dismiss Function ──────────────────────────────────────────────────────────

local function dismissToast(toast: ActiveToast)
	if toast.dismissed then return end
	toast.dismissed = true
	toast.cancelTimer()

	local idx = table.find(_active, toast)
	if idx then
		table.remove(_active, idx)
	end

	local card    = toast.card
	local wrapper = toast.wrapper
	local stroke  = toast.stroke

	-- Deep glide off-screen to the right (+85px)
	TweenService:Create(card, TWEEN_OUT_POS, {
		Position = UDim2.fromOffset(SLIDE_OUT_OFFSET, 0),
	}):Play()

	-- Fade out GroupTransparency in sync
	TweenService:Create(card, TWEEN_OUT_FADE, {
		GroupTransparency = 1,
	}):Play()

	-- Fade out border stroke in lockstep
	if stroke and stroke.Parent then
		TweenService:Create(stroke, TWEEN_OUT_FADE, {
			Transparency = 1,
		}):Play()
	end

	-- Simultaneously collapse slot height with smooth deceleration
	local sizeTween = TweenService:Create(wrapper, TWEEN_OUT_SIZE, {
		Size = UDim2.new(1, 0, 0, 0),
	})
	sizeTween:Play()
	sizeTween.Completed:Once(function()
		if wrapper.Parent then
			wrapper:Destroy()
		end
	end)
end

-- ── Public API ────────────────────────────────────────────────────────────────

local Notification = {}

function Notification.notify(config: NotifyConfig)
	ensureGui()

	-- Max 6 stacking: smoothly evict oldest notifications when capacity is reached
	while #_active >= MAX_VISIBLE do
		local oldest = _active[1]
		if oldest then
			dismissToast(oldest)
		else
			break
		end
	end

	local titleText = config.Title or "Notification"
	local msgText   = config.Message or config.Content or ""
	local notifType = config.Type or "info"
	local accent    = typeColor(notifType)
	local iconId    = resolveIcon(config.Icon, notifType)

	local duration: number
	if config.Duration and config.Duration > 0 then
		duration = config.Duration
	elseif config.Duration and config.Duration <= 0 then
		duration = -1 -- persistent
	else
		duration = math.clamp((#msgText * 0.08) + 3, 3.5, 10)
	end

	_orderCounter += 1
	local order = _orderCounter

	-- ── Target Height Calculation (Modern Two-Column Proportions) ─────────────
	-- Card width = 276px
	-- Content inset: 11px left + 28px icon + 9px gap + 11px right = 59px non-text
	-- Usable text width = 276 - 59 = 217px
	local textBounds = TextService:GetTextSize(
		msgText,
		11,
		Theme.Font.Body,
		Vector2.new(217, 2000)
	)
	local msgH = if #msgText > 0 then math.max(textBounds.Y, 13) else 0
	local padV = 20        -- 10px top + 10px bottom padding
	local headerH = 16
	local bodyH = if msgH > 0 then (headerH + 3 + msgH) else headerH
	local contentH = math.max(bodyH, 28) -- minimum height matches 28px icon badge
	local targetH = padV + contentH

	-- ── Slot Wrapper (transparent layout host inside UIListLayout) ────────────
	local wrapper                  = Instance.new("Frame")
	wrapper.Name                   = "ToastSlot"
	wrapper.Size                   = UDim2.new(1, 0, 0, 0)  -- starts at height 0
	wrapper.BackgroundTransparency = 1
	wrapper.BorderSizePixel        = 0
	wrapper.ClipsDescendants       = false                 -- allows smooth glide to right without clipping
	wrapper.LayoutOrder            = order
	wrapper.Parent                 = _container

	-- ── Card (CanvasGroup for perfect rounded clipping & group transparency) ───
	local card                    = Instance.new("CanvasGroup")
	card.Name                     = "ToastCard"
	card.Size                     = UDim2.new(1, 0, 0, targetH)
	card.Position                 = UDim2.fromOffset(SLIDE_IN_OFFSET, 0)
	card.BackgroundColor3         = Color3.fromRGB(24, 24, 28) -- clean modern dark glass surface
	card.BorderSizePixel          = 0
	card.GroupTransparency        = 1                       -- starts fully transparent
	card.ClipsDescendants         = true
	card.Parent                   = wrapper

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = card

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(48, 48, 56)
	stroke.Thickness = 1
	stroke.Transparency = 1 -- Starts fully transparent, synchronized with card.GroupTransparency
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = card

	-- ── Bottom Ambient Status Glow Line (1px gradient strip) ──────────────────
	local bottomGlow                  = Instance.new("Frame")
	bottomGlow.Name                   = "BottomGlow"
	bottomGlow.Position               = UDim2.new(0, 0, 1, -1)
	bottomGlow.Size                   = UDim2.new(1, 0, 0, 1)
	bottomGlow.BackgroundColor3       = accent
	bottomGlow.BorderSizePixel        = 0
	bottomGlow.ZIndex                 = 3
	bottomGlow.Parent                 = card

	local glowGrad = Instance.new("UIGradient")
	glowGrad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.35, 0.45),
		NumberSequenceKeypoint.new(0.65, 0.45),
		NumberSequenceKeypoint.new(1, 1),
	})
	glowGrad.Parent = bottomGlow

	-- ── Main Two-Column Row ───────────────────────────────────────────────────
	local row                  = Instance.new("Frame")
	row.Name                   = "Row"
	row.Position               = UDim2.fromOffset(11, 10)
	row.Size                   = UDim2.new(1, -22, 0, contentH)
	row.BackgroundTransparency = 1
	row.BorderSizePixel        = 0
	row.ZIndex                 = 2
	row.Parent                 = card

	local rLayout               = Instance.new("UIListLayout")
	rLayout.FillDirection       = Enum.FillDirection.Horizontal
	rLayout.VerticalAlignment   = Enum.VerticalAlignment.Top
	rLayout.SortOrder           = Enum.SortOrder.LayoutOrder
	rLayout.Padding             = UDim.new(0, 9)
	rLayout.Parent              = row

	-- ── Left Column: Frosted Semantic Icon Badge (28x28) ──────────────────────
	local iconBadge                  = Instance.new("Frame")
	iconBadge.Name                   = "IconBadge"
	iconBadge.LayoutOrder            = 1
	iconBadge.Size                   = UDim2.fromOffset(28, 28)
	iconBadge.BackgroundColor3       = accent
	iconBadge.BackgroundTransparency = 0.86
	iconBadge.BorderSizePixel        = 0
	iconBadge.Parent                 = row

	local badgeCorner = Instance.new("UICorner")
	badgeCorner.CornerRadius = UDim.new(0, 7)
	badgeCorner.Parent = iconBadge

	local badgeStroke = Instance.new("UIStroke")
	badgeStroke.Color = accent
	badgeStroke.Thickness = 1
	badgeStroke.Transparency = 0.65
	badgeStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	badgeStroke.Parent = iconBadge

	local iconImg                  = Instance.new("ImageLabel")
	iconImg.Name                   = "Icon"
	iconImg.AnchorPoint            = Vector2.new(0.5, 0.5)
	iconImg.Position               = UDim2.fromScale(0.5, 0.5)
	iconImg.Size                   = UDim2.fromOffset(14, 14)
	iconImg.BackgroundTransparency = 1
	iconImg.Image                  = iconId
	iconImg.ImageColor3            = accent
	iconImg.Parent                 = iconBadge

	-- ── Right Column: Text & Header Column ────────────────────────────────────
	local col                  = Instance.new("Frame")
	col.Name                   = "Col"
	col.LayoutOrder            = 2
	col.Size                   = UDim2.new(1, -37, 0, 0)
	col.AutomaticSize          = Enum.AutomaticSize.Y
	col.BackgroundTransparency = 1
	col.BorderSizePixel        = 0
	col.Parent                 = row

	local colLayout               = Instance.new("UIListLayout")
	colLayout.FillDirection       = Enum.FillDirection.Vertical
	colLayout.SortOrder           = Enum.SortOrder.LayoutOrder
	colLayout.Padding             = UDim.new(0, 3)
	colLayout.Parent              = col

	-- Header Row: Title + Spacer + Time + Close Button
	local header                  = Instance.new("Frame")
	header.Name                   = "Header"
	header.LayoutOrder            = 1
	header.Size                   = UDim2.new(1, 0, 0, 16)
	header.BackgroundTransparency = 1
	header.BorderSizePixel        = 0
	header.Parent                 = col

	local hLayout               = Instance.new("UIListLayout")
	hLayout.FillDirection       = Enum.FillDirection.Horizontal
	hLayout.VerticalAlignment   = Enum.VerticalAlignment.Center
	hLayout.SortOrder           = Enum.SortOrder.LayoutOrder
	hLayout.Padding             = UDim.new(0, 4)
	hLayout.Parent              = header

	-- Title (crisp 12px bold)
	local titleLbl                  = Instance.new("TextLabel")
	titleLbl.Name                   = "Title"
	titleLbl.LayoutOrder            = 1
	titleLbl.AutomaticSize          = Enum.AutomaticSize.X
	titleLbl.Size                   = UDim2.new(0, 0, 1, 0)
	titleLbl.BackgroundTransparency = 1
	titleLbl.Font                   = Theme.Font.Title
	titleLbl.Text                   = titleText
	titleLbl.TextSize               = 12
	titleLbl.TextColor3             = Color3.fromRGB(245, 245, 250)
	titleLbl.TextXAlignment         = Enum.TextXAlignment.Left
	titleLbl.TextTruncate           = Enum.TextTruncate.AtEnd
	titleLbl.Parent                 = header

	-- Spacer pushing timestamp and close button to far right
	local spacer                  = Instance.new("Frame")
	spacer.Name                   = "Spacer"
	spacer.LayoutOrder            = 2
	spacer.Size                   = UDim2.new(0, 0, 1, 0)
	spacer.BackgroundTransparency = 1
	spacer.BorderSizePixel        = 0
	spacer.Parent                 = header

	local flex = Instance.new("UIFlexItem")
	flex.FlexMode = Enum.UIFlexMode.Fill
	flex.Parent = spacer

	-- Time Badge ("now", "5s ago")
	local timeLbl                  = Instance.new("TextLabel")
	timeLbl.Name                   = "Time"
	timeLbl.LayoutOrder            = 3
	timeLbl.AutomaticSize          = Enum.AutomaticSize.X
	timeLbl.Size                   = UDim2.new(0, 0, 1, 0)
	timeLbl.BackgroundTransparency = 1
	timeLbl.Font                   = Theme.Font.Body
	timeLbl.Text                   = "now"
	timeLbl.TextSize               = 10
	timeLbl.TextColor3             = Color3.fromRGB(115, 115, 128)
	timeLbl.TextXAlignment         = Enum.TextXAlignment.Right
	timeLbl.Parent                 = header

	-- Close Button (minimalist ×)
	local closeBtn                  = Instance.new("TextButton")
	closeBtn.Name                   = "CloseBtn"
	closeBtn.LayoutOrder            = 4
	closeBtn.Size                   = UDim2.fromOffset(14, 14)
	closeBtn.BackgroundTransparency = 1
	closeBtn.BorderSizePixel        = 0
	closeBtn.Font                   = Enum.Font.GothamMedium
	closeBtn.Text                   = "×"
	closeBtn.TextSize               = 13
	closeBtn.TextColor3             = Color3.fromRGB(115, 115, 128)
	closeBtn.AutoButtonColor        = false
	closeBtn.Parent                 = header

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 3)
	closeCorner.Parent = closeBtn

	-- ── Message Label ─────────────────────────────────────────────────────────
	if #msgText > 0 then
		local msgLbl                  = Instance.new("TextLabel")
		msgLbl.Name                   = "Message"
		msgLbl.LayoutOrder            = 2
		msgLbl.AutomaticSize          = Enum.AutomaticSize.Y
		msgLbl.Size                   = UDim2.new(1, 0, 0, 0)
		msgLbl.BackgroundTransparency = 1
		msgLbl.Font                   = Theme.Font.Body
		msgLbl.Text                   = msgText
		msgLbl.TextSize               = 11
		msgLbl.TextColor3             = Color3.fromRGB(185, 185, 198)
		msgLbl.TextXAlignment         = Enum.TextXAlignment.Left
		msgLbl.TextWrapped            = true
		msgLbl.RichText               = true
		msgLbl.LineHeight             = 1.15
		msgLbl.Parent                 = col
	end

	-- ── Active Toast Tracking ─────────────────────────────────────────────────
	local creationTime = tick()
	local timerThread  : thread? = nil
	local updateThread : thread? = nil

	local toast: ActiveToast = {
		wrapper     = wrapper,
		card        = card,
		stroke      = stroke,
		dismissed   = false,
		cancelTimer = function() end,
	}

	local function cancelTimer()
		toast.dismissed = true
		if timerThread then
			pcall(task.cancel, timerThread)
			timerThread = nil
		end
		if updateThread then
			pcall(task.cancel, updateThread)
			updateThread = nil
		end
	end
	toast.cancelTimer = cancelTimer

	table.insert(_active, toast)

	-- ── Enter Animations (Ultra-Smooth Glide & Bloom In) ──────────────────────
	-- Slot expands vertically:
	TweenService:Create(wrapper, TWEEN_IN_SIZE, {
		Size = UDim2.new(1, 0, 0, targetH),
	}):Play()

	-- Card glides smoothly from +45px to 0px:
	TweenService:Create(card, TWEEN_IN_POS, {
		Position = UDim2.fromOffset(0, 0),
	}):Play()

	-- Card opacity blossoms softly from 1 to 0:
	TweenService:Create(card, TWEEN_IN_FADE, {
		GroupTransparency = 0,
	}):Play()

	-- Border stroke blossoms softly from 1 to 0 in lockstep:
	TweenService:Create(stroke, TWEEN_IN_FADE, {
		Transparency = 0,
	}):Play()

	-- ── Auto-dismiss Timer ────────────────────────────────────────────────────
	if duration > 0 then
		timerThread = task.delay(duration, function()
			dismissToast(toast)
		end)
	end

	-- ── Dynamic "now" / "Xs ago" Update Loop ──────────────────────────────────
	updateThread = task.spawn(function()
		while not toast.dismissed do
			task.wait(1)
			if toast.dismissed then break end
			local elapsed = tick() - creationTime
			timeLbl.Text = formatElapsed(elapsed)
		end
	end)

	-- ── Close Button Interactivity ────────────────────────────────────────────
	closeBtn.MouseButton1Click:Connect(function()
		dismissToast(toast)
	end)
	closeBtn.MouseEnter:Connect(function()
		TweenService:Create(closeBtn, TweenInfo.new(0.15), {
			BackgroundTransparency = 0.85,
			BackgroundColor3       = Theme.Colors.SurfaceHover,
			TextColor3             = Theme.Colors.TextPrimary,
		}):Play()
	end)
	closeBtn.MouseLeave:Connect(function()
		TweenService:Create(closeBtn, TweenInfo.new(0.15), {
			BackgroundTransparency = 1,
			TextColor3             = Color3.fromRGB(115, 115, 128),
		}):Play()
	end)
end

-- Aliases
Notification.Notify = Notification.notify

function Notification.dismissAll()
	for i = #_active, 1, -1 do
		local toast = _active[i]
		if toast then
			dismissToast(toast)
		end
	end
end

return Notification

end)() end,
    function()local wax,script,require=ImportGlobals(16)local ImportGlobals return (function(...)--!strict

local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Maid        = require(script.Parent.Parent.Utils.Maid)
local Theme       = require(script.Parent.Parent.Theme)
local SmoothScroll = require(script.Parent.Parent.Utils.SmoothScroll)

-- ── Constants & Motion ────────────────────────────────────────────────────────

local TWEEN_OPEN_SCALE  = TweenInfo.new(0.32, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
local TWEEN_FADE_IN     = TweenInfo.new(0.28, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)

local TWEEN_CLOSE_SCALE = TweenInfo.new(0.24, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
local TWEEN_FADE_OUT    = TweenInfo.new(0.20, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)

local SCALE_START       = 0.94
local SCALE_CLOSE       = 0.94

local CARD_W = 310

-- Default semantic icons (Lucide / rbxassetid)
local DEFAULT_ICONS: { [string]: string } = {
	info    = "rbxassetid://10723415903",
	success = "rbxassetid://10709790387",
	warning = "rbxassetid://10709752935",
	error   = "rbxassetid://10747384394",
}

-- ZIndex layering
local DIM_Z     = 3
local BASE_Z    = 50
local Z_STRIDE  = 10
local Z_SHELL   = 1
local Z_CONTENT = 2
local Z_BTN     = 3
local Z_BADGE   = 4

local STACK_OFFSET_PX = 5

export type PopupConfig = {
	Title:       string,
	Message:     string,
	OnConfirm:   () -> (),
	OnCancel:    (() -> ())?,
	ConfirmText: string?,
	CancelText:  string?,
	Type:        string?,   -- "info" | "warning" | "error" | "success"
	Icon:        (string | number)?,
	Risky:       boolean?,
}

-- ── Module-level state ────────────────────────────────────────────────────────
local _stack:     { any }   = {}
local _sharedDim: Frame?    = nil   -- singleton overlay; nil when no popups are open

-- ── Helpers ───────────────────────────────────────────────────────────────────

local function corner(inst: Instance, r: number)
	local c        = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r)
	c.Parent       = inst
end

local function typeColor(notifType: string): Color3
	local t = string.lower(notifType)
	if     t == "success" then return Theme.Colors.Success
	elseif t == "warning" then return Theme.Colors.Warning
	elseif t == "error"   then return Theme.Colors.Error
	else                       return Theme.Colors.Accent
	end
end

local function resolveIcon(icon: (string | number)?, notifType: string): string
	if type(icon) == "number" then
		return "rbxassetid://" .. tostring(icon)
	elseif type(icon) == "string" and #icon > 0 then
		if string.sub(icon, 1, 13) == "rbxassetid://" or string.sub(icon, 1, 4) == "http" then
			return icon
		end
		local ok, id = pcall(function()
			return Theme.Icons.Get(icon)
		end)
		if ok and id and id ~= "rbxassetid://0" then
			return id
		end
		return icon
	end

	local t = string.lower(notifType)
	return DEFAULT_ICONS[t] or DEFAULT_ICONS.info
end

-- ── Shared dim management ─────────────────────────────────────────────────────

local function acquireDim(canvas: Frame)
	if _sharedDim then return end

	local dim                  = Instance.new("Frame")
	dim.Name                   = "PopupDim"
	dim.Size                   = UDim2.fromScale(1, 1)
	dim.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
	dim.BackgroundTransparency = 1
	dim.BorderSizePixel        = 0
	dim.ZIndex                 = DIM_Z
	dim.Active                 = true
	corner(dim, Theme.Radius.Medium)
	dim.Parent                 = canvas.Parent

	_sharedDim = dim
	TweenService:Create(dim, TWEEN_FADE_IN, { BackgroundTransparency = 0.55 }):Play()
end

local function releaseDim(fadeInfo: TweenInfo)
	if #_stack > 0 then return end

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
	if #_stack > 0 then return end

	local maid = Maid.new()

	-- Infer semantic type and accent color
	local notifType = config.Type
	if not notifType then
		local combined = string.lower((config.Title or "") .. " " .. (config.ConfirmText or "") .. " " .. (config.Message or ""))
		if config.Risky or string.find(combined, "wipe") or string.find(combined, "delete") or string.find(combined, "unload") or string.find(combined, "danger") or string.find(combined, "ban") then
			notifType = "error"
		elseif string.find(combined, "warn") or string.find(combined, "heads up") or string.find(combined, "restart") or string.find(combined, "careful") then
			notifType = "warning"
		else
			notifType = "info"
		end
	end

	local accent = typeColor(notifType)
	local iconId = resolveIcon(config.Icon, notifType)

	local stackIdx = #_stack + 1
	local shellZ   = BASE_Z + (stackIdx - 1) * Z_STRIDE + Z_SHELL
	local contentZ = BASE_Z + (stackIdx - 1) * Z_STRIDE + Z_CONTENT
	local btnZ     = BASE_Z + (stackIdx - 1) * Z_STRIDE + Z_BTN
	local badgeZ   = BASE_Z + (stackIdx - 1) * Z_STRIDE + Z_BADGE

	local offsetPx = (stackIdx - 1) * STACK_OFFSET_PX

	acquireDim(canvas)

	pcall(function() (canvas :: any).Interactable = false end)
	maid:GiveTask(function() pcall(function() (canvas :: any).Interactable = true end) end)

	SmoothScroll.setPaused(true)
	maid:GiveTask(function() SmoothScroll.setPaused(false) end)

	-- ── Shell (Consistent dark acrylic glass tone) ────────────────────────────
	local shell                  = Instance.new("Frame")
	shell.Name                   = "PopupShell"
	shell.AnchorPoint            = Vector2.new(0.5, 0.5)
	shell.Position               = UDim2.new(0.5, offsetPx, 0.5, offsetPx)
	shell.Size                   = UDim2.fromOffset(CARD_W, 0)
	shell.AutomaticSize          = Enum.AutomaticSize.Y
	shell.BackgroundColor3       = Color3.fromRGB(24, 24, 28) -- matches Notification tone
	shell.BackgroundTransparency = 1
	shell.BorderSizePixel        = 0
	shell.ZIndex                 = shellZ
	shell.ClipsDescendants       = false
	corner(shell, 8)
	shell.Parent = canvas.Parent
	maid:GiveTask(shell)

	local shellScale       = Instance.new("UIScale")
	shellScale.Scale       = SCALE_START
	shellScale.Parent      = shell

	local shellStroke           = Instance.new("UIStroke")
	shellStroke.Color           = Color3.fromRGB(48, 48, 56) -- matches Notification border
	shellStroke.Thickness       = 1
	shellStroke.Transparency    = 1
	shellStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	shellStroke.Parent          = shell

	-- ── Bottom Ambient Status Glow Line (1px gradient strip) ──────────────────
	local bottomGlow                  = Instance.new("Frame")
	bottomGlow.Name                   = "BottomGlow"
	bottomGlow.Position               = UDim2.new(0, 0, 1, -1)
	bottomGlow.Size                   = UDim2.new(1, 0, 0, 1)
	bottomGlow.BackgroundColor3       = accent
	bottomGlow.BackgroundTransparency = 1
	bottomGlow.BorderSizePixel        = 0
	bottomGlow.ZIndex                 = shellZ + 1
	bottomGlow.Parent                 = shell
	maid:GiveTask(bottomGlow)

	local glowGrad = Instance.new("UIGradient")
	glowGrad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.35, 0.45),
		NumberSequenceKeypoint.new(0.65, 0.45),
		NumberSequenceKeypoint.new(1, 1),
	})
	glowGrad.Parent = bottomGlow

	-- ── Stack depth badge ─────────────────────────────────────────────────────
	local stackBadge: Frame? = nil
	if stackIdx > 1 then
		local badge                  = Instance.new("Frame")
		badge.Name                   = "StackBadge"
		badge.AnchorPoint            = Vector2.new(1, 0)
		badge.Position               = UDim2.new(1, 8, 0, -8)
		badge.Size                   = UDim2.fromOffset(20, 20)
		badge.BackgroundColor3       = accent
		badge.BackgroundTransparency = 1
		badge.BorderSizePixel        = 0
		badge.ZIndex                 = badgeZ
		corner(badge, 10)
		badge.Parent = shell
		maid:GiveTask(badge)

		local badgeLbl                  = Instance.new("TextLabel")
		badgeLbl.Name                   = "StackCount"
		badgeLbl.Size                   = UDim2.fromScale(1, 1)
		badgeLbl.BackgroundTransparency = 1
		badgeLbl.Font                   = Theme.Font.Title
		badgeLbl.Text                   = tostring(stackIdx)
		badgeLbl.TextSize               = 10
		badgeLbl.TextColor3             = Color3.fromRGB(10, 10, 10)
		badgeLbl.TextTransparency       = 1
		badgeLbl.TextXAlignment         = Enum.TextXAlignment.Center
		badgeLbl.TextYAlignment         = Enum.TextYAlignment.Center
		badgeLbl.ZIndex                 = badgeZ + 1
		badgeLbl.Parent                 = badge

		stackBadge = badge
	end

	-- ── Content Container ─────────────────────────────────────────────────────
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
	pad.PaddingTop    = UDim.new(0, 14)
	pad.PaddingBottom = UDim.new(0, 12)
	pad.PaddingLeft   = UDim.new(0, 14)
	pad.PaddingRight  = UDim.new(0, 14)
	pad.Parent        = content

	local contentLayout               = Instance.new("UIListLayout")
	contentLayout.FillDirection       = Enum.FillDirection.Vertical
	contentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	contentLayout.SortOrder           = Enum.SortOrder.LayoutOrder
	contentLayout.Padding             = UDim.new(0, 10)
	contentLayout.Parent              = content

	-- ── Two-Column Row (Frosted Icon Badge + Header/Message) ───────────────────
	local topRow                  = Instance.new("Frame")
	topRow.Name                   = "TopRow"
	topRow.Size                   = UDim2.new(1, 0, 0, 0)
	topRow.AutomaticSize          = Enum.AutomaticSize.Y
	topRow.BackgroundTransparency = 1
	topRow.BorderSizePixel        = 0
	topRow.LayoutOrder            = 1
	topRow.ZIndex                 = contentZ
	topRow.Parent                 = content

	local topLayout               = Instance.new("UIListLayout")
	topLayout.FillDirection       = Enum.FillDirection.Horizontal
	topLayout.VerticalAlignment   = Enum.VerticalAlignment.Top
	topLayout.SortOrder           = Enum.SortOrder.LayoutOrder
	topLayout.Padding             = UDim.new(0, 10)
	topLayout.Parent              = topRow

	-- Frosted Semantic Icon Badge (matches Notification exactly)
	local iconBadge                  = Instance.new("Frame")
	iconBadge.Name                   = "IconBadge"
	iconBadge.LayoutOrder            = 1
	iconBadge.Size                   = UDim2.fromOffset(30, 30)
	iconBadge.BackgroundColor3       = accent
	iconBadge.BackgroundTransparency = 1
	iconBadge.BorderSizePixel        = 0
	iconBadge.ZIndex                 = contentZ + 1
	iconBadge.Parent                 = topRow

	local badgeCorner = Instance.new("UICorner")
	badgeCorner.CornerRadius = UDim.new(0, 7)
	badgeCorner.Parent = iconBadge

	local badgeStroke = Instance.new("UIStroke")
	badgeStroke.Color = accent
	badgeStroke.Thickness = 1
	badgeStroke.Transparency = 1
	badgeStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	badgeStroke.Parent = iconBadge

	local iconImg                  = Instance.new("ImageLabel")
	iconImg.Name                   = "Icon"
	iconImg.AnchorPoint            = Vector2.new(0.5, 0.5)
	iconImg.Position               = UDim2.fromScale(0.5, 0.5)
	iconImg.Size                   = UDim2.fromOffset(15, 15)
	iconImg.BackgroundTransparency = 1
	iconImg.Image                  = iconId
	iconImg.ImageColor3            = accent
	iconImg.ImageTransparency      = 1
	iconImg.ZIndex                 = contentZ + 2
	iconImg.Parent                 = iconBadge

	-- Text Column (Title + Message)
	local textCol                  = Instance.new("Frame")
	textCol.Name                   = "TextCol"
	textCol.LayoutOrder            = 2
	textCol.Size                   = UDim2.new(1, -40, 0, 0)
	textCol.AutomaticSize          = Enum.AutomaticSize.Y
	textCol.BackgroundTransparency = 1
	textCol.BorderSizePixel        = 0
	textCol.ZIndex                 = contentZ + 1
	textCol.Parent                 = topRow

	local textLayout               = Instance.new("UIListLayout")
	textLayout.FillDirection       = Enum.FillDirection.Vertical
	textLayout.SortOrder           = Enum.SortOrder.LayoutOrder
	textLayout.Padding             = UDim.new(0, 4)
	textLayout.Parent              = textCol

	-- Header Row: Title + Close Button
	local headerRow                  = Instance.new("Frame")
	headerRow.Name                   = "HeaderRow"
	headerRow.LayoutOrder            = 1
	headerRow.Size                   = UDim2.new(1, 0, 0, 16)
	headerRow.BackgroundTransparency = 1
	headerRow.BorderSizePixel        = 0
	headerRow.ZIndex                 = contentZ + 1
	headerRow.Parent                 = textCol

	local hLayout               = Instance.new("UIListLayout")
	hLayout.FillDirection       = Enum.FillDirection.Horizontal
	hLayout.VerticalAlignment   = Enum.VerticalAlignment.Center
	hLayout.SortOrder           = Enum.SortOrder.LayoutOrder
	hLayout.Padding             = UDim.new(0, 4)
	hLayout.Parent              = headerRow

	local titleLbl                  = Instance.new("TextLabel")
	titleLbl.Name                   = "Title"
	titleLbl.LayoutOrder            = 1
	titleLbl.AutomaticSize          = Enum.AutomaticSize.X
	titleLbl.Size                   = UDim2.new(0, 0, 1, 0)
	titleLbl.BackgroundTransparency = 1
	titleLbl.Font                   = Theme.Font.Title
	titleLbl.Text                   = config.Title
	titleLbl.TextSize               = 13
	titleLbl.TextColor3             = Color3.fromRGB(245, 245, 250)
	titleLbl.TextTransparency       = 1
	titleLbl.TextXAlignment         = Enum.TextXAlignment.Left
	titleLbl.TextTruncate           = Enum.TextTruncate.AtEnd
	titleLbl.ZIndex                 = contentZ + 2
	titleLbl.Parent                 = headerRow

	local headerSpacer = Instance.new("Frame")
	headerSpacer.Name                   = "Spacer"
	headerSpacer.LayoutOrder            = 2
	headerSpacer.Size                   = UDim2.new(0, 0, 1, 0)
	headerSpacer.BackgroundTransparency = 1
	headerSpacer.BorderSizePixel        = 0
	headerSpacer.Parent                 = headerRow

	local flex = Instance.new("UIFlexItem")
	flex.FlexMode = Enum.UIFlexMode.Fill
	flex.Parent = headerSpacer

	local closeBtn                  = Instance.new("TextButton")
	closeBtn.Name                   = "CloseBtn"
	closeBtn.LayoutOrder            = 3
	closeBtn.Size                   = UDim2.fromOffset(16, 16)
	closeBtn.BackgroundTransparency = 1
	closeBtn.BorderSizePixel        = 0
	closeBtn.Font                   = Enum.Font.GothamMedium
	closeBtn.Text                   = "×"
	closeBtn.TextSize               = 13
	closeBtn.TextColor3             = Color3.fromRGB(120, 120, 135)
	closeBtn.TextTransparency       = 1
	closeBtn.AutoButtonColor        = false
	closeBtn.ZIndex                 = contentZ + 2
	closeBtn.Parent                 = headerRow

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 3)
	closeCorner.Parent = closeBtn

	-- Message
	local msgLbl                  = Instance.new("TextLabel")
	msgLbl.Name                   = "Message"
	msgLbl.LayoutOrder            = 2
	msgLbl.AutomaticSize          = Enum.AutomaticSize.Y
	msgLbl.Size                   = UDim2.new(1, 0, 0, 0)
	msgLbl.BackgroundTransparency = 1
	msgLbl.Font                   = Theme.Font.Body
	msgLbl.Text                   = config.Message
	msgLbl.TextSize               = 11
	msgLbl.TextColor3             = Color3.fromRGB(185, 185, 198)
	msgLbl.TextTransparency       = 1
	msgLbl.TextXAlignment         = Enum.TextXAlignment.Left
	msgLbl.TextWrapped            = true
	msgLbl.RichText               = true
	msgLbl.LineHeight             = 1.25
	msgLbl.ZIndex                 = contentZ + 2
	msgLbl.Parent                 = textCol

	-- ── Divider ───────────────────────────────────────────────────────────────
	local divider                  = Instance.new("Frame")
	divider.Name                   = "Divider"
	divider.Size                   = UDim2.new(1, 0, 0, 1)
	divider.BackgroundColor3       = Color3.fromRGB(42, 42, 50)
	divider.BackgroundTransparency = 1
	divider.BorderSizePixel        = 0
	divider.LayoutOrder            = 2
	divider.ZIndex                 = contentZ
	divider.Parent                 = content

	-- ── Button Row ────────────────────────────────────────────────────────────
	local btnRow                  = Instance.new("Frame")
	btnRow.Name                   = "ButtonRow"
	btnRow.Size                   = UDim2.new(1, 0, 0, 28)
	btnRow.BackgroundTransparency = 1
	btnRow.BorderSizePixel        = 0
	btnRow.LayoutOrder            = 3
	btnRow.ZIndex                 = btnZ
	btnRow.Parent                 = content

	local btnLayout               = Instance.new("UIListLayout")
	btnLayout.FillDirection       = Enum.FillDirection.Horizontal
	btnLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	btnLayout.VerticalAlignment   = Enum.VerticalAlignment.Center
	btnLayout.Padding             = UDim.new(0, 8)
	btnLayout.SortOrder           = Enum.SortOrder.LayoutOrder
	btnLayout.Parent              = btnRow

	-- ── Close sequences ───────────────────────────────────────────────────────
	local closed = false

	local function closePopup()
		if closed then return end
		closed = true

		for i = #_stack, 1, -1 do
			if _stack[i] == maid then table.remove(_stack, i) break end
		end

		releaseDim(TWEEN_FADE_OUT)

		-- Smooth exit: slight scale down + unified dissolve
		TweenService:Create(shellScale, TWEEN_CLOSE_SCALE, { Scale = SCALE_CLOSE }):Play()
		TweenService:Create(shell, TWEEN_FADE_OUT, { BackgroundTransparency = 1 }):Play()
		TweenService:Create(shellStroke, TWEEN_FADE_OUT, { Transparency = 1 }):Play()
		TweenService:Create(bottomGlow, TWEEN_FADE_OUT, { BackgroundTransparency = 1 }):Play()
		TweenService:Create(iconBadge, TWEEN_FADE_OUT, { BackgroundTransparency = 1 }):Play()
		TweenService:Create(badgeStroke, TWEEN_FADE_OUT, { Transparency = 1 }):Play()
		TweenService:Create(iconImg, TWEEN_FADE_OUT, { ImageTransparency = 1 }):Play()
		TweenService:Create(titleLbl, TWEEN_FADE_OUT, { TextTransparency = 1 }):Play()
		TweenService:Create(closeBtn, TWEEN_FADE_OUT, { TextTransparency = 1 }):Play()
		TweenService:Create(msgLbl, TWEEN_FADE_OUT, { TextTransparency = 1 }):Play()
		TweenService:Create(divider, TWEEN_FADE_OUT, { BackgroundTransparency = 1 }):Play()

		if stackBadge then
			TweenService:Create(stackBadge, TWEEN_FADE_OUT, { BackgroundTransparency = 1 }):Play()
			local lbl = stackBadge:FindFirstChild("StackCount")
			if lbl and lbl:IsA("TextLabel") then
				TweenService:Create(lbl, TWEEN_FADE_OUT, { TextTransparency = 1 }):Play()
			end
		end

		for _, btn in ipairs(btnRow:GetChildren()) do
			if btn:IsA("TextButton") then
				TweenService:Create(btn, TWEEN_FADE_OUT, {
					BackgroundTransparency = 1,
					TextTransparency       = 1,
				}):Play()
				local s = btn:FindFirstChildOfClass("UIStroke")
				if s then
					TweenService:Create(s, TWEEN_FADE_OUT, { Transparency = 1 }):Play()
				end
			end
		end

		task.delay(TWEEN_CLOSE_SCALE.Time + 0.02, function()
			maid:DoCleaning()
		end)
	end

	-- ── Cancel Button ─────────────────────────────────────────────────────────
	if config.OnCancel or config.CancelText then
		local cancelBtn                  = Instance.new("TextButton")
		cancelBtn.Name                   = "CancelBtn"
		cancelBtn.LayoutOrder            = 1
		cancelBtn.AutomaticSize          = Enum.AutomaticSize.X
		cancelBtn.Size                   = UDim2.fromOffset(0, 28)
		cancelBtn.BackgroundColor3       = Color3.fromRGB(32, 32, 38)
		cancelBtn.BackgroundTransparency = 1
		cancelBtn.BorderSizePixel        = 0
		cancelBtn.Font                   = Theme.Font.Subtitle
		cancelBtn.Text                   = config.CancelText or "Cancel"
		cancelBtn.TextSize               = 11
		cancelBtn.TextColor3             = Color3.fromRGB(180, 180, 195)
		cancelBtn.TextTransparency       = 1
		cancelBtn.AutoButtonColor        = false
		cancelBtn.ZIndex                 = btnZ
		corner(cancelBtn, 6)

		local cPad = Instance.new("UIPadding")
		cPad.PaddingLeft = UDim.new(0, 12)
		cPad.PaddingRight = UDim.new(0, 12)
		cPad.Parent = cancelBtn

		local cStroke           = Instance.new("UIStroke")
		cStroke.Color           = Color3.fromRGB(52, 52, 62)
		cStroke.Thickness       = 1
		cStroke.Transparency    = 1
		cStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		cStroke.Parent          = cancelBtn

		cancelBtn.Parent = btnRow

		maid:GiveTask(cancelBtn.MouseButton1Click:Connect(function()
			closePopup()
			if config.OnCancel then config.OnCancel() end
		end))
		maid:GiveTask(cancelBtn.MouseEnter:Connect(function()
			TweenService:Create(cancelBtn, TweenInfo.new(0.12), {
				BackgroundColor3 = Color3.fromRGB(42, 42, 50),
				TextColor3       = Color3.fromRGB(255, 255, 255),
			}):Play()
		end))
		maid:GiveTask(cancelBtn.MouseLeave:Connect(function()
			TweenService:Create(cancelBtn, TweenInfo.new(0.12), {
				BackgroundColor3 = Color3.fromRGB(32, 32, 38),
				TextColor3       = Color3.fromRGB(180, 180, 195),
			}):Play()
		end))
	end

	-- ── Confirm Button ────────────────────────────────────────────────────────
	local confirmBtn                  = Instance.new("TextButton")
	confirmBtn.Name                   = "ConfirmBtn"
	confirmBtn.LayoutOrder            = 2
	confirmBtn.AutomaticSize          = Enum.AutomaticSize.X
	confirmBtn.Size                   = UDim2.fromOffset(0, 28)
	confirmBtn.BackgroundTransparency = 1
	confirmBtn.BorderSizePixel        = 0
	confirmBtn.Font                   = Theme.Font.Title
	confirmBtn.Text                   = config.ConfirmText or "Confirm"
	confirmBtn.TextSize               = 11
	confirmBtn.TextTransparency       = 1
	confirmBtn.AutoButtonColor        = false
	confirmBtn.ZIndex                 = btnZ
	corner(confirmBtn, 6)

	local cfPad = Instance.new("UIPadding")
	cfPad.PaddingLeft = UDim.new(0, 14)
	cfPad.PaddingRight = UDim.new(0, 14)
	cfPad.Parent = confirmBtn

	local btnRestBg = accent
	local btnHoverBg = accent
	local btnRestFg = Color3.fromRGB(10, 18, 28)

	if notifType == "error" then
		btnRestBg  = Theme.Colors.Error
		btnHoverBg = Theme.Colors.ErrorHover
		btnRestFg  = Color3.fromRGB(255, 255, 255)
	elseif notifType == "warning" then
		btnRestBg  = Theme.Colors.Warning
		btnHoverBg = Color3.fromHex("#fff040")
		btnRestFg  = Color3.fromRGB(15, 15, 20)
	else
		btnRestBg  = Theme.Colors.Accent
		btnHoverBg = Theme.Colors.AccentHover
		btnRestFg  = Color3.fromRGB(10, 18, 28)
	end

	confirmBtn.BackgroundColor3 = btnRestBg
	confirmBtn.TextColor3       = btnRestFg
	confirmBtn.Parent           = btnRow

	maid:GiveTask(confirmBtn.MouseButton1Click:Connect(function()
		closePopup()
		config.OnConfirm()
	end))
	maid:GiveTask(confirmBtn.MouseEnter:Connect(function()
		TweenService:Create(confirmBtn, TweenInfo.new(0.12), { BackgroundColor3 = btnHoverBg }):Play()
	end))
	maid:GiveTask(confirmBtn.MouseLeave:Connect(function()
		TweenService:Create(confirmBtn, TweenInfo.new(0.12), { BackgroundColor3 = btnRestBg }):Play()
	end))

	-- Close button top-right interactivity
	maid:GiveTask(closeBtn.MouseButton1Click:Connect(function()
		closePopup()
		if config.OnCancel then config.OnCancel() end
	end))
	maid:GiveTask(closeBtn.MouseEnter:Connect(function()
		TweenService:Create(closeBtn, TweenInfo.new(0.12), {
			BackgroundTransparency = 0.85,
			BackgroundColor3       = Theme.Colors.SurfaceHover,
			TextColor3             = Color3.fromRGB(255, 255, 255),
		}):Play()
	end))
	maid:GiveTask(closeBtn.MouseLeave:Connect(function()
		TweenService:Create(closeBtn, TweenInfo.new(0.12), {
			BackgroundTransparency = 1,
			TextColor3             = Color3.fromRGB(120, 120, 135),
		}):Play()
	end))

	-- ── Push + escape ─────────────────────────────────────────────────────────
	table.insert(_stack, maid)

	maid:GiveTask(UserInputService.InputBegan:Connect(function(input: InputObject, gpe: boolean)
		if gpe then return end
		if input.KeyCode ~= Enum.KeyCode.Escape then return end
		if _stack[#_stack] == maid then
			closePopup()
			if config.OnCancel then config.OnCancel() end
		end
	end))

	-- ── Open Animation (Smooth scale 0.94 -> 1.0 & fade in) ───────────────────
	TweenService:Create(shellScale, TWEEN_OPEN_SCALE, { Scale = 1 }):Play()
	TweenService:Create(shell, TWEEN_FADE_IN, { BackgroundTransparency = 0 }):Play()
	TweenService:Create(shellStroke, TWEEN_FADE_IN, { Transparency = 0 }):Play()
	TweenService:Create(bottomGlow, TWEEN_FADE_IN, { BackgroundTransparency = 0 }):Play()
	TweenService:Create(iconBadge, TWEEN_FADE_IN, { BackgroundTransparency = 0.86 }):Play()
	TweenService:Create(badgeStroke, TWEEN_FADE_IN, { Transparency = 0.65 }):Play()
	TweenService:Create(iconImg, TWEEN_FADE_IN, { ImageTransparency = 0 }):Play()
	TweenService:Create(titleLbl, TWEEN_FADE_IN, { TextTransparency = 0 }):Play()
	TweenService:Create(closeBtn, TWEEN_FADE_IN, { TextTransparency = 0 }):Play()
	TweenService:Create(msgLbl, TWEEN_FADE_IN, { TextTransparency = 0 }):Play()
	TweenService:Create(divider, TWEEN_FADE_IN, { BackgroundTransparency = 0 }):Play()

	if stackBadge then
		TweenService:Create(stackBadge, TWEEN_FADE_IN, { BackgroundTransparency = 0 }):Play()
		local lbl = stackBadge:FindFirstChild("StackCount")
		if lbl and lbl:IsA("TextLabel") then
			TweenService:Create(lbl, TWEEN_FADE_IN, { TextTransparency = 0 }):Play()
		end
	end

	for _, btn in ipairs(btnRow:GetChildren()) do
		if btn:IsA("TextButton") then
			local targetBgT = (btn.Name == "CancelBtn") and 0 or 0
			TweenService:Create(btn, TWEEN_FADE_IN, {
				BackgroundTransparency = targetBgT,
				TextTransparency       = 0,
			}):Play()
			local s = btn:FindFirstChildOfClass("UIStroke")
			if s then
				TweenService:Create(s, TWEEN_FADE_IN, { Transparency = 0 }):Play()
			end
		end
	end
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

local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Maid         = require(script.Parent.Parent.Utils.Maid)
local Theme        = require(script.Parent.Parent.Theme)
local SmoothScroll = require(script.Parent.Parent.Utils.SmoothScroll)

local TWEEN_MODAL_IN  = TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local TWEEN_MODAL_OUT = TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
local TWEEN_DIM_IN    = TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local TWEEN_DIM_OUT   = TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
local TWEEN_FLASH     = TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

local SEARCH_W    = 360
local SEARCH_MAX_H = 260
local HEADER_H    = 42
local ROW_H       = 38

export type SearchItem = {
	Label:     string,
	TabName:   string,
	TabIdx:    number,
	GroupName: string?,
	TypeName:  string,
	Comp:      any,
	Frame:     GuiObject,
}

export type SearchImpl = {
	Register:  (self: SearchImpl, item: SearchItem) -> (),
	Open:      (self: SearchImpl) -> (),
	Close:     (self: SearchImpl) -> (),
	Toggle:    (self: SearchImpl) -> (),
	Destroy:   (self: SearchImpl) -> (),
}

local Search = {} :: { __index: any }
Search.__index = Search

function Search.new(window: any, overlayGui: ScreenGui, parentCanvas: Frame, windowMaid: any): SearchImpl
	local self    = setmetatable({}, Search) :: any
	self._maid    = Maid.new()
	windowMaid:GiveTask(self._maid)

	self._win     = window
	self._gui     = overlayGui
	self._canvas  = parentCanvas
	self._items   = {} :: { SearchItem }
	self._isOpen  = false
	self._itemMaid = Maid.new()
	self._maid:GiveTask(self._itemMaid)

	-- ── Search Modal Root ─────────────────────────────────────────────────────
	local modal                  = Instance.new("Frame")
	modal.Name                   = "SearchModal"
	modal.AnchorPoint            = Vector2.new(0.5, 0.5)
	modal.Position               = UDim2.fromScale(0.5, 0.45)
	modal.Size                   = UDim2.fromOffset(SEARCH_W, HEADER_H + 8)
	modal.BackgroundColor3       = Theme.Colors.Surface
	modal.BorderSizePixel        = 0
	modal.ZIndex                 = 500
	modal.Visible                = false
	modal.ClipsDescendants       = true
	self._maid:GiveTask(modal)
	self._modal = modal

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, Theme.Radius.Medium)
	corner.Parent = modal

	local stroke = Instance.new("UIStroke")
	stroke.Color           = Theme.Colors.Border
	stroke.Thickness       = 1
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent          = modal
	self._stroke           = stroke

	local scale = Instance.new("UIScale")
	scale.Scale  = 0.90
	scale.Parent = modal
	self._scale  = scale

	-- ── Header (Search Input Bar) ─────────────────────────────────────────────
	local header                  = Instance.new("Frame")
	header.Name                   = "SearchHeader"
	header.Size                   = UDim2.new(1, 0, 0, HEADER_H)
	header.BackgroundColor3       = Theme.Colors.TitleBar
	header.BorderSizePixel        = 0
	header.ZIndex                 = 501
	header.Parent                 = modal

	local headerPad = Instance.new("UIPadding")
	headerPad.PaddingLeft  = UDim.new(0, 12)
	headerPad.PaddingRight = UDim.new(0, 10)
	headerPad.Parent       = header

	local searchIcon                  = Instance.new("TextLabel")
	searchIcon.Name                   = "SearchIcon"
	searchIcon.AnchorPoint            = Vector2.new(0, 0.5)
	searchIcon.Position               = UDim2.new(0, 0, 0.5, 0)
	searchIcon.Size                   = UDim2.fromOffset(18, 18)
	searchIcon.BackgroundTransparency = 1
	searchIcon.Font                   = Theme.Font.Body
	searchIcon.Text                   = "⊙"
	searchIcon.TextSize               = 14
	searchIcon.TextColor3             = Theme.Colors.Accent
	searchIcon.ZIndex                 = 502
	searchIcon.Parent                 = header

	local closeBtn                  = Instance.new("TextButton")
	closeBtn.Name                   = "CloseBtn"
	closeBtn.AnchorPoint            = Vector2.new(1, 0.5)
	closeBtn.Position               = UDim2.new(1, 0, 0.5, 0)
	closeBtn.Size                   = UDim2.fromOffset(20, 20)
	closeBtn.BackgroundColor3       = Theme.Colors.SurfaceHover
	closeBtn.BorderSizePixel        = 0
	closeBtn.Font                   = Theme.Font.Body
	closeBtn.Text                   = "×"
	closeBtn.TextSize               = 14
	closeBtn.TextColor3             = Theme.Colors.TextSecondary
	closeBtn.AutoButtonColor        = false
	closeBtn.ZIndex                 = 502
	closeBtn.Parent                 = header
	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 4)
	btnCorner.Parent = closeBtn

	local input                  = Instance.new("TextBox")
	input.Name                   = "SearchInput"
	input.Position               = UDim2.fromOffset(24, 0)
	input.Size                   = UDim2.new(1, -52, 1, 0)
	input.BackgroundTransparency = 1
	input.BorderSizePixel        = 0
	input.Font                   = Theme.Font.Body
	input.Text                   = ""
	input.PlaceholderText        = "Search features, commands, tabs..."
	input.PlaceholderColor3      = Theme.Colors.TextDisabled
	input.TextSize               = Theme.TextSize.Body
	input.TextColor3             = Theme.Colors.TextPrimary
	input.TextXAlignment         = Enum.TextXAlignment.Left
	input.ClearTextOnFocus       = false
	input.ZIndex                 = 502
	input.Parent                 = header
	self._input                  = input

	local sep             = Instance.new("Frame")
	sep.Name              = "Separator"
	sep.Size              = UDim2.new(1, 0, 0, 1)
	sep.Position          = UDim2.fromOffset(0, HEADER_H)
	sep.BackgroundColor3  = Theme.Colors.Border
	sep.BorderSizePixel   = 0
	sep.ZIndex            = 502
	sep.Parent            = modal

	-- ── Results ScrollingFrame ────────────────────────────────────────────────
	local scroll                  = Instance.new("ScrollingFrame")
	scroll.Name                   = "ResultsScroll"
	scroll.Position               = UDim2.fromOffset(0, HEADER_H + 1)
	scroll.Size                   = UDim2.new(1, 0, 1, -(HEADER_H + 1))
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel        = 0
	scroll.ScrollBarThickness     = 2
	scroll.ScrollBarImageColor3   = Theme.Colors.Border
	scroll.CanvasSize             = UDim2.fromOffset(0, 0)
	scroll.AutomaticCanvasSize    = Enum.AutomaticSize.Y
	scroll.ClipsDescendants       = true
	scroll.ZIndex                 = 501
	scroll.Parent                 = modal
	self._scroll                  = scroll

	local listLayout               = Instance.new("UIListLayout")
	listLayout.FillDirection       = Enum.FillDirection.Vertical
	listLayout.SortOrder           = Enum.SortOrder.LayoutOrder
	listLayout.Padding             = UDim.new(0, 2)
	listLayout.Parent              = scroll

	local scrollPad         = Instance.new("UIPadding")
	scrollPad.PaddingTop    = UDim.new(0, 6)
	scrollPad.PaddingBottom = UDim.new(0, 6)
	scrollPad.PaddingLeft   = UDim.new(0, 8)
	scrollPad.PaddingRight  = UDim.new(0, 8)
	scrollPad.Parent        = scroll

	-- ── Backdrop Dim ──────────────────────────────────────────────────────────
	local backdrop                  = Instance.new("TextButton")
	backdrop.Name                   = "SearchBackdrop"
	backdrop.Size                   = UDim2.fromScale(1, 1)
	backdrop.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
	backdrop.BackgroundTransparency = 1
	backdrop.BorderSizePixel        = 0
	backdrop.Text                   = ""
	backdrop.AutoButtonColor        = false
	backdrop.ZIndex                 = 499
	backdrop.Visible                = false
	self._maid:GiveTask(backdrop)
	self._backdrop                  = backdrop

	-- ── Result builder ────────────────────────────────────────────────────────
	local function rebuildResults(query: string)
		self._itemMaid:DoCleaning()
		for _, child in ipairs(scroll:GetChildren()) do
			if child:IsA("Frame") then child:Destroy() end
		end

		local q = query:lower():gsub("%s+", " ")
		local matches = {}
		for _, it in ipairs(self._items) do
			if #q == 0 or it.Label:lower():find(q, 1, true) or it.TabName:lower():find(q, 1, true) or (it.GroupName and it.GroupName:lower():find(q, 1, true)) then
				table.insert(matches, it)
			end
		end

		local totalCount = #matches
		local contentH = math.min(totalCount * (ROW_H + 2) + 12, SEARCH_MAX_H)
		local targetH = HEADER_H + 1 + (if totalCount == 0 then 48 else contentH)

		local cam = workspace.CurrentCamera
		local vp = if cam then cam.ViewportSize else Vector2.new(1024, 768)
		local modalW = math.min(SEARCH_W, vp.X - 24)

		modal.Size = UDim2.fromOffset(modalW, targetH)

		if totalCount == 0 then
			local emptyLbl                  = Instance.new("TextLabel")
			emptyLbl.Name                   = "EmptyLabel"
			emptyLbl.Size                   = UDim2.new(1, 0, 0, 40)
			emptyLbl.BackgroundTransparency = 1
			emptyLbl.Font                   = Theme.Font.Body
			emptyLbl.Text                   = "No features found"
			emptyLbl.TextSize               = Theme.TextSize.Small
			emptyLbl.TextColor3             = Theme.Colors.TextDisabled
			emptyLbl.ZIndex                 = 503
			emptyLbl.Parent                 = scroll
			return
		end

		for i, item in ipairs(matches) do
			local row                  = Instance.new("Frame")
			row.Name                   = "Result_" .. i
			row.Size                   = UDim2.new(1, 0, 0, ROW_H)
			row.BackgroundColor3       = Theme.Colors.SurfaceHover
			row.BackgroundTransparency = 1
			row.BorderSizePixel        = 0
			row.LayoutOrder            = i
			row.ZIndex                 = 503
			row.Parent                 = scroll

			local rowCorner = Instance.new("UICorner")
			rowCorner.CornerRadius = UDim.new(0, 6)
			rowCorner.Parent = row

			local rowPad = Instance.new("UIPadding")
			rowPad.PaddingLeft  = UDim.new(0, 8)
			rowPad.PaddingRight = UDim.new(0, 8)
			rowPad.Parent       = row

			-- Left: Title + Breadcrumb
			local labelCol                  = Instance.new("Frame")
			labelCol.Name                   = "LabelCol"
			labelCol.Size                   = UDim2.new(1, -70, 1, 0)
			labelCol.BackgroundTransparency = 1
			labelCol.BorderSizePixel        = 0
			labelCol.ZIndex                 = 504
			labelCol.Parent                 = row

			local labelLayout               = Instance.new("UIListLayout")
			labelLayout.FillDirection       = Enum.FillDirection.Vertical
			labelLayout.VerticalAlignment   = Enum.VerticalAlignment.Center
			labelLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
			labelLayout.Padding             = UDim.new(0, 1)
			labelLayout.Parent              = labelCol

			local titleLbl                  = Instance.new("TextLabel")
			titleLbl.Name                   = "ItemTitle"
			titleLbl.Size                   = UDim2.new(1, 0, 0, 15)
			titleLbl.BackgroundTransparency = 1
			titleLbl.Font                   = Theme.Font.Body
			titleLbl.Text                   = item.Label
			titleLbl.TextSize               = Theme.TextSize.Body
			titleLbl.TextColor3             = Theme.Colors.TextPrimary
			titleLbl.TextXAlignment         = Enum.TextXAlignment.Left
			titleLbl.TextTruncate           = Enum.TextTruncate.AtEnd
			titleLbl.ZIndex                 = 505
			titleLbl.Parent                 = labelCol

			local breadcrumb = item.TabName .. (if item.GroupName then "  ›  " .. item.GroupName else "")
			local pathLbl                  = Instance.new("TextLabel")
			pathLbl.Name                   = "ItemPath"
			pathLbl.Size                   = UDim2.new(1, 0, 0, 12)
			pathLbl.BackgroundTransparency = 1
			pathLbl.Font                   = Theme.Font.Subtitle
			pathLbl.Text                   = breadcrumb
			pathLbl.TextSize               = 10
			pathLbl.TextColor3             = Theme.Colors.TextSecondary
			pathLbl.TextXAlignment         = Enum.TextXAlignment.Left
			pathLbl.TextTruncate           = Enum.TextTruncate.AtEnd
			pathLbl.ZIndex                 = 505
			pathLbl.Parent                 = labelCol

			-- Right: Type Badge pill
			local badge                  = Instance.new("Frame")
			badge.Name                   = "TypeBadge"
			badge.AnchorPoint            = Vector2.new(1, 0.5)
			badge.Position               = UDim2.new(1, 0, 0.5, 0)
			badge.Size                   = UDim2.fromOffset(58, 20)
			badge.BackgroundColor3       = Theme.Colors.AccentMuted
			badge.BorderSizePixel        = 0
			badge.ZIndex                 = 504
			badge.Parent                 = row
			local badgeCorner = Instance.new("UICorner")
			badgeCorner.CornerRadius = UDim.new(0, 4)
			badgeCorner.Parent = badge

			local badgeLbl                  = Instance.new("TextLabel")
			badgeLbl.Size                   = UDim2.fromScale(1, 1)
			badgeLbl.BackgroundTransparency = 1
			badgeLbl.Font                   = Theme.Font.Subtitle
			badgeLbl.Text                   = item.TypeName
			badgeLbl.TextSize               = 9
			badgeLbl.TextColor3             = Theme.Colors.Accent
			badgeLbl.TextXAlignment         = Enum.TextXAlignment.Center
			badgeLbl.ZIndex                 = 505
			badgeLbl.Parent                 = badge

			-- Hit button
			local hitBtn                  = Instance.new("TextButton")
			hitBtn.Size                   = UDim2.fromScale(1, 1)
			hitBtn.BackgroundTransparency = 1
			hitBtn.Text                   = ""
			hitBtn.AutoButtonColor        = false
			hitBtn.ZIndex                 = 506
			hitBtn.Parent                 = row

			self._itemMaid:GiveTask(hitBtn.MouseEnter:Connect(function()
				TweenService:Create(row, TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
					BackgroundTransparency = 0.5,
				}):Play()
			end))
			self._itemMaid:GiveTask(hitBtn.MouseLeave:Connect(function()
				TweenService:Create(row, TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
					BackgroundTransparency = 1,
				}):Play()
			end))

			self._itemMaid:GiveTask(hitBtn.MouseButton1Click:Connect(function()
				self:Close()
				-- Switch to tab
				if self._win._activateTab and item.TabIdx > 0 then
					self._win:_activateTab(item.TabIdx)
				end

				-- Scroll to element & flash highlight
				task.defer(function()
					local f = item.Frame
					if not f or not f.Parent then return end
					local pane = f:FindFirstAncestorWhichIsA("ScrollingFrame")
					if pane then
						local relY = f.AbsolutePosition.Y - pane.AbsolutePosition.Y + pane.CanvasPosition.Y
						local paneH = pane.AbsoluteSize.Y
						local targetScroll = math.clamp(relY - paneH * 0.35, 0, math.max(0, pane.AbsoluteCanvasSize.Y - paneH))
						TweenService:Create(pane, TweenInfo.new(0.35, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {
							CanvasPosition = Vector2.new(0, targetScroll),
						}):Play()
					end

					-- Highlight flash
					local stroke_ = f:FindFirstChildOfClass("UIStroke") or f:FindFirstChild("Inner", true) and (f:FindFirstChild("Inner", true) :: Instance):FindFirstChildOfClass("UIStroke")
					if stroke_ then
						local origCol = stroke_.Color
						TweenService:Create(stroke_, TWEEN_FLASH, { Color = Theme.Colors.AccentActive }):Play()
						task.delay(0.6, function()
							if stroke_.Parent then
								TweenService:Create(stroke_, TWEEN_FLASH, { Color = origCol }):Play()
							end
						end)
					end
				end)
			end))
		end
	end

	self._maid:GiveTask(input:GetPropertyChangedSignal("Text"):Connect(function()
		rebuildResults(input.Text)
	end))

	-- ── Backdrop & Close Bindings ─────────────────────────────────────────────
	self._maid:GiveTask(closeBtn.MouseButton1Click:Connect(function()
		self:Close()
	end))
	self._maid:GiveTask(backdrop.MouseButton1Click:Connect(function()
		self:Close()
	end))

	self._maid:GiveTask(UserInputService.InputBegan:Connect(function(inp: InputObject, gpe: boolean)
		if gpe and not input:IsFocused() then return end
		if inp.KeyCode == Enum.KeyCode.Escape and self._isOpen then
			self:Close()
		elseif inp.KeyCode == Enum.KeyCode.F and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
			self:Toggle()
		end
	end))

	self._rebuildResults = rebuildResults
	return self
end

function Search:Register(item: SearchItem)
	table.insert(self._items, item)
end

function Search:Open()
	if self._isOpen then return end
	self._isOpen = true

	local cam = workspace.CurrentCamera
	local vp = if cam then cam.ViewportSize else Vector2.new(1024, 768)
	local modalW = math.min(SEARCH_W, vp.X - 24)

	self._backdrop.Parent = self._gui
	self._backdrop.Visible = true
	self._modal.Parent = self._gui
	self._modal.Size   = UDim2.fromOffset(modalW, HEADER_H + 8)
	self._modal.Visible = true

	self._scale.Scale = 0.88
	self._modal.BackgroundTransparency = 1
	self._stroke.Transparency = 1

	TweenService:Create(self._backdrop, TWEEN_DIM_IN, { BackgroundTransparency = 0.55 }):Play()
	TweenService:Create(self._scale,    TWEEN_MODAL_IN, { Scale = 1 }):Play()
	TweenService:Create(self._modal,    TWEEN_MODAL_IN, { BackgroundTransparency = 0 }):Play()
	TweenService:Create(self._stroke,   TWEEN_MODAL_IN, { Transparency = 0 }):Play()

	self._input.Text = ""
	self._input:CaptureFocus()
	self._rebuildResults("")
end

function Search:Close()
	if not self._isOpen then return end
	self._isOpen = false

	TweenService:Create(self._backdrop, TWEEN_DIM_OUT, { BackgroundTransparency = 1 }):Play()
	TweenService:Create(self._scale,    TWEEN_MODAL_OUT, { Scale = 0.88 }):Play()
	TweenService:Create(self._modal,    TWEEN_MODAL_OUT, { BackgroundTransparency = 1 }):Play()
	TweenService:Create(self._stroke,   TWEEN_MODAL_OUT, { Transparency = 1 }):Play()

	task.delay(TWEEN_MODAL_OUT.Time + 0.02, function()
		if not self._isOpen then
			self._modal.Visible = false
			self._backdrop.Visible = false
			self._modal.Parent = nil
			self._backdrop.Parent = nil
		end
	end)
end

function Search:Toggle()
	if self._isOpen then
		self:Close()
	else
		self:Open()
	end
end

function Search:Destroy()
	self._maid:DoCleaning()
end

return Search

end)() end,
    function()local wax,script,require=ImportGlobals(19)local ImportGlobals return (function(...)--!strict
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
	_win:         any?,
	_tabName:     string?,
	_tabIdx:      number?,
	_layoutOrder: number,
}

-- ── Class ──────────────────────────────────────────────────────────────────

local Tab = {} :: { __index: any }
Tab.__index = Tab

--[[
	Tab.new(pane, gui, windowMaid, canvas, window, tabName, tabIdx)

	pane        — the ScrollingFrame this tab owns
	gui         — the ScreenGui root (forwarded to Dropdown as OverlayParent)
	windowMaid  — the parent window's maid; owns this tab's maid so
	              destroying the window cascades cleanup into all tabs
]]
function Tab.new(pane: ScrollingFrame, gui: ScreenGui, windowMaid: any, canvas: Frame?, window: any?, tabName: string?, tabIdx: number?): TabImpl
	local self        = setmetatable({}, Tab) :: any
	self._maid        = Maid.new()
	windowMaid:GiveTask(self._maid)  -- cascade: window destroy → tab destroy
	self._content     = pane
	self._gui         = gui
	self._canvas      = canvas
	self._win         = window
	self._tabName     = tabName or "Main"
	self._tabIdx      = tabIdx or 1
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
function Tab:_addToContent(comp: any, config: any?, typeName: string?): any
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
		descLabel.RichText                = true
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

	if self._win and self._win._search and config and comp.GetFrame then
		local label = config.Label or config.Title or config.Text or config.Name or ""
		if typeof(label) == "string" and #label > 0 then
			self._win._search:Register({
				Label     = label,
				TabName   = self._tabName or "Main",
				TabIdx    = self._tabIdx or 1,
				GroupName = nil,
				TypeName  = typeName or "Control",
				Comp      = comp,
				Frame     = comp:GetFrame(),
			})
		end
	end

	self._maid:GiveTask(comp)
	return comp
end

-- ── Public Add* API ────────────────────────────────────────────────────────

function Tab:AddButton(config: {
	Label: string, Variant: number?, Enabled: boolean?, description: string?, Tooltip: string?,
})
	local c = config :: any
	c.LayoutOrder = self:_nextOrder()
	return self:_addToContent(Components.Button.new(c), c, "Button")
end

function Tab:AddToggle(config: {
	Label: string, Icon: string?, Default: boolean?, Enabled: boolean?, description: string?, Tooltip: string?,
})
	local c = config :: any
	c.LayoutOrder = self:_nextOrder()
	return self:_addToContent(Components.Toggle.new(c), c, "Toggle")
end

function Tab:AddLabel(text: string, color: Color3?)
	local lbl = Components.Label.new({
		Text        = text,
		Color       = color,
		LayoutOrder = self:_nextOrder(),
	})
	return self:_addToContent(lbl, nil, "Label")
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
	return self:_addToContent(div, nil, "Divider")
end

function Tab:AddSlider(config: {
	Label: string, Min: number?, Max: number?,
	Default: number?, Step: number?, Enabled: boolean?, description: string?, Tooltip: string?,
})
	local c = config :: any
	c.LayoutOrder = self:_nextOrder()
	return self:_addToContent(Components.Slider.new(c), c, "Slider")
end

function Tab:AddTextbox(config: {
	Label: string?, Placeholder: string?, Default: string?,
	MaxLength: number?, ClearOnFocus: boolean?, Enabled: boolean?, description: string?, Tooltip: string?,
})
	local c = config :: any
	c.LayoutOrder = self:_nextOrder()
	return self:_addToContent(Components.Textbox.new(c), c, "Textbox")
end

function Tab:AddKeybind(config: {
	Label: string, Default: Enum.KeyCode?,
	Blacklist: { any }?, Enabled: boolean?, description: string?, Tooltip: string?,
})
	local c = config :: any
	c.LayoutOrder = self:_nextOrder()
	return self:_addToContent(Components.Keybind.new(c), c, "Keybind")
end

function Tab:AddDropdown(config: {
	Label: string?, Options: { any }, MultiSelect: boolean?,
	Default: any?, Placeholder: string?, Enabled: boolean?, description: string?, Tooltip: string?,
})
	local c = config :: any
	c.LayoutOrder   = self:_nextOrder()
	return self:_addToContent(Components.Dropdown.new(c), c, "Dropdown")
end

function Tab:AddColorPicker(config: {
	Label: string, Default: Color3?, ShowAlpha: boolean?,
	Flag: string?, Risky: boolean?, Enabled: boolean?, description: string?, Tooltip: string?,
})
	local c = config :: any
	c.LayoutOrder   = self:_nextOrder()
	c.OverlayParent = self._gui
	c.Canvas        = self._canvas
	return self:_addToContent(Components.ColorPicker.new(c), c, "ColorPicker")
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

		local leftBox  = Groupbox.new(titleA, self._gui, self._maid, self._canvas, self._win, self._tabName, self._tabIdx)
		local rightBox = Groupbox.new(titleB, self._gui, self._maid, self._canvas, self._win, self._tabName, self._tabIdx)

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
		local box = Groupbox.new(titleA, self._gui, self._maid, self._canvas, self._win, self._tabName, self._tabIdx)
		local f   = box:GetFrame()
		f.LayoutOrder = self:_nextOrder()
		f.Parent      = self._content
		return box
	end
end

return Tab

end)() end,
    function()local wax,script,require=ImportGlobals(20)local ImportGlobals return (function(...)--!strict

local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local Players          = game:GetService("Players")
local GuiService        = game:GetService("GuiService")

local Maid         = require(script.Parent.Parent.Utils.Maid)
local Theme        = require(script.Parent.Parent.Theme)
local Components   = require(script.Parent.Parent.Components)
local SmoothScroll = require(script.Parent.Parent.Utils.SmoothScroll)
local Tab          = require(script.Parent.Tab)
local Notification = require(script.Parent.Notification)
local Search       = require(script.Parent.Search)
local Tooltip      = require(script.Parent.Parent.Utils.Tooltip)

local TWEEN_OPEN     = TweenInfo.new(0.3,  Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local TWEEN_CLOSE    = TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
local TWEEN_TAB      = TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local TWEEN_GROUP    = TweenInfo.new(0.20, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local TWEEN_COLLAPSE = TweenInfo.new(0.45, Enum.EasingStyle.Exponential, Enum.EasingDirection.InOut)
local TWEEN_EXPAND   = TweenInfo.new(0.50, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)

-- Pill (hide/show morph)
export type PillPosition = "Top" | "Bottom" | "Left" | "Right"

local function getPillGeometry(side: PillPosition?): (UDim2, UDim2)
	local s = side or "Top"
	if s == "Bottom" then
		return UDim2.fromOffset(170, 36), UDim2.new(0.5, -85, 1, -36)
	elseif s == "Left" then
		return UDim2.fromOffset(130, 36), UDim2.new(0, 0, 0.5, -18)
	elseif s == "Right" then
		return UDim2.fromOffset(130, 36), UDim2.new(1, -130, 0.5, -18)
	else -- "Top"
		return UDim2.fromOffset(170, 36), UDim2.new(0.5, -85, 0, 0)
	end
end

local TWEEN_PILL_MORPH  = TweenInfo.new(0.45, Enum.EasingStyle.Exponential, Enum.EasingDirection.InOut)
local TWEEN_PILL_REVEAL = TweenInfo.new(0.50, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)

-- Rayfield uses these two fixed sizes — desktop 500×475, mobile 500×275.  The mobile
-- variant is just the desktop width with a shorter body (no per-viewport adapt).
-- Replicated here so Delirium can default to the same shape on first open.
local DEFAULT_SIZE_DESKTOP = UDim2.fromOffset(500, 475)
local DEFAULT_SIZE_MOBILE  = UDim2.fromOffset(360, 280)
local MIN_SIZE             = Vector2.new(300, 200)
local MIN_SIZE_MOBILE      = Vector2.new(240, 200)
local VIEWPORT_BREAKPOINT  = Vector2.new(1024, 768)
local VIEWPORT_EDGE_MARGIN = 4
local SIDEBAR_W_EXPANDED  = 136
local SIDEBAR_W_COLLAPSED = 40
local SIDEBAR_HEADER_H    = 44
local SIDEBAR_GAP         = 4
local TAB_ITEM_H          = 24
local TAB_SPACING         = 5

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
	AutoScale: boolean?,
	PillPosition: PillPosition?,
}

-- ── platform detection ───────────────────────────────────────────────────────

local function detectMobile(viewport: Vector2): boolean
	if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
		return true
	end
	return viewport.X < VIEWPORT_BREAKPOINT.X and viewport.Y < VIEWPORT_BREAKPOINT.Y
end

-- ── viewport helpers (cached for hot-path performance) ──────────────────────

local _cachedVp: Vector2? = nil
local function viewportSize(): Vector2
	if _cachedVp then return _cachedVp end
	local cam = workspace.CurrentCamera
	if cam then
		local vs = cam.ViewportSize
		if vs.X > 0 and vs.Y > 0 then
			_cachedVp = vs
			return vs
		end
	end
	return Vector2.new(1024, 768)
end

do
	local cam = workspace.CurrentCamera
	if cam then
		cam:GetPropertyChangedSignal("ViewportSize"):Connect(function()
			_cachedVp = cam.ViewportSize
		end)
	end
end

local function safeInsets(): Vector2
	local ok, inset = pcall(function() return GuiService:GetGuiInset() end)
	if not ok then return Vector2.zero end
	return Vector2.new(inset.X, inset.Y)
end

-- ── clamp helpers — Obsidian-style snap + hard bounds ────────────────────────

local function clampSizeToViewport(size: UDim2, minSize: Vector2): UDim2
	if size.X.Scale ~= 0 or size.Y.Scale ~= 0 then return size end
	local vp   = viewportSize()
	local ins  = safeInsets()
	local maxW = math.max(minSize.X, vp.X - VIEWPORT_EDGE_MARGIN * 2)
	local maxH = math.max(minSize.Y, vp.Y - ins.Y - VIEWPORT_EDGE_MARGIN * 2)
	local w = math.clamp(size.X.Offset, minSize.X, maxW)
	local h = math.clamp(size.Y.Offset, minSize.Y, maxH)
	return UDim2.fromOffset(w, h)
end

local function clampPositionToViewport(pos: UDim2, size: UDim2, leftSidebarOffset: number?): UDim2
	local vp  = viewportSize()
	local ins = safeInsets()
	local w   = size.X.Offset
	local h   = size.Y.Offset

	local inX = pos.X.Scale * vp.X + pos.X.Offset
	local inY = pos.Y.Scale * vp.Y + pos.Y.Offset

	local sidebarReserve = leftSidebarOffset or 0
	local minX = sidebarReserve + VIEWPORT_EDGE_MARGIN
	local maxX = math.max(minX, vp.X - w - VIEWPORT_EDGE_MARGIN)
	local minY = ins.Y + VIEWPORT_EDGE_MARGIN
	local maxY = math.max(minY, vp.Y - h - VIEWPORT_EDGE_MARGIN)

	if minX > maxX or minY > maxY then return pos end

	local x = math.clamp(inX, minX, maxX)
	local y = math.clamp(inY, minY, maxY)
	return UDim2.fromOffset(x, y)
end

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

local function buildWindow(title: string, cfg: WindowConfig, minSize: Vector2)
	local targetSize = cfg.Size or DEFAULT_SIZE
	targetSize = clampSizeToViewport(targetSize, minSize)

	-- Root frame: unified container that holds both canvas (window) and sidebar as siblings
	local root                  = Instance.new("Frame")
	root.Name                   = "WindowRoot"
	root.Size                   = targetSize
	root.AnchorPoint            = Vector2.new(0, 0)
	root.Position               = cfg.Position or UDim2.fromOffset(0, 0)
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
	local collapseBtn = mkTitleBtn("CollapseBtn", "X", 4)
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

local function setupDrag(maid: any, titleBar: Frame, root: Frame, autoScale: boolean)
	local dragging  = false
	local dragStart = Vector3.zero
	local startPos  = UDim2.fromOffset(0, 0)
	local lastX, lastY = 0, 0

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
		local vp = viewportSize()
		lastX = startPos.X.Scale * vp.X + startPos.X.Offset
		lastY = startPos.Y.Scale * vp.Y + startPos.Y.Offset
	end))

	-- Use UserInputService during active drag so fast movement never drops tracking
	maid:GiveTask(UserInputService.InputChanged:Connect(function(input: InputObject)
		if not dragging then return end
		if input.UserInputType ~= Enum.UserInputType.MouseMovement
			and input.UserInputType ~= Enum.UserInputType.Touch then return end

		local delta = input.Position - dragStart
		local nextPos = UDim2.new(
			startPos.X.Scale, startPos.X.Offset + delta.X,
			startPos.Y.Scale, startPos.Y.Offset + delta.Y
		)
		if autoScale then
			local clamped = clampPositionToViewport(nextPos, root.Size)
			local cx = clamped.X.Offset
			local cy = clamped.Y.Offset
			if math.abs(cx - lastX) < 0.5 and math.abs(cy - lastY) < 0.5 then return end
			lastX, lastY = cx, cy
			root.Position = clamped
		else
			root.Position = nextPos
		end
	end))

	maid:GiveTask(UserInputService.InputEnded:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end))
end

local function setupResize(maid: any, handle: Frame, root: Frame, minSize: Vector2, autoScale: boolean)
	local resizing    = false
	local resizeStart = Vector3.zero
	local startSize   = UDim2.fromOffset(0, 0)
	-- Cached bounds for the active resize gesture (computed once on InputBegan, not
	-- per frame).  Saves 2 property reads + 2 math ops per frame on mobile.
	local maxW, maxH = math.huge, math.huge
	local lastW, lastH = 0, 0

	maid:GiveTask(handle.InputBegan:Connect(function(input: InputObject)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch then return end
		resizing    = true
		resizeStart = input.Position
		startSize   = root.Size
		-- Cache bounds for the whole gesture so the per-frame loop is just delta math.
		if autoScale then
			local vp   = viewportSize()
			local ins  = safeInsets()
			maxW = math.max(minSize.X, vp.X)
			maxH = math.max(minSize.Y, vp.Y - ins.Y)
		else
			maxW, maxH = math.huge, math.huge
		end
		lastW = startSize.X.Offset
		lastH = startSize.Y.Offset
	end))

	-- Listen on the HANDLE only, not the global UserInputService, so a sibling
	-- ScrollingFrame's InputChanged is never hijacked while a resize is in progress.
	maid:GiveTask(handle.InputChanged:Connect(function(input: InputObject)
		if not resizing then return end
		if input.UserInputType ~= Enum.UserInputType.MouseMovement
			and input.UserInputType ~= Enum.UserInputType.Touch then return end

		local delta = input.Position - resizeStart
		local newW  = math.clamp(startSize.X.Offset + delta.X, minSize.X, maxW)
		local newH  = math.clamp(startSize.Y.Offset + delta.Y, minSize.Y, maxH)
		-- Skip writes that don't actually move the pixel grid — saves layout passes.
		if math.abs(newW - lastW) < 0.5 and math.abs(newH - lastH) < 0.5 then return end
		lastW, lastH = newW, newH
		root.Size   = UDim2.new(startSize.X.Scale, newW, startSize.Y.Scale, newH)
	end))

	maid:GiveTask(handle.InputEnded:Connect(function(input: InputObject)
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

	-- Platform-aware defaults — Rayfield-style viewport-pixel check.
	-- Mobile is detected exactly once, against the viewport at construction time.
	local vp          = viewportSize()
	local isMobile    = detectMobile(vp)
	self._isMobile    = isMobile

	local defaultSize = if isMobile then DEFAULT_SIZE_MOBILE else DEFAULT_SIZE_DESKTOP
	local defaultMin  = if isMobile then MIN_SIZE_MOBILE     else MIN_SIZE
	local userSize    = cfg.Size or defaultSize
	local userMinSize = cfg.MinSize or defaultMin

	-- Pre-clamp to viewport so DEFAULT_SIZE never overflows a phone screen.
	local resolvedSize  = clampSizeToViewport(userSize, userMinSize)
	local resolvedMin   = Vector2.new(
		math.min(userMinSize.X, resolvedSize.X.Offset),
		math.min(userMinSize.Y, resolvedSize.Y.Offset)
	)

	self._maid             = Maid.new()
	self.Title             = title
	self._closing          = false
	self._collapsed        = false
	self._collapseAnimating = false
	self._expandedSize     = resolvedSize
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
	self._minSize          = resolvedMin
	self._autoScale        = cfg.AutoScale ~= false   -- default true

	local gui = getGui()
	self._gui = gui
	self._maid:GiveTask(gui)

	local buildCfg          = table.clone(cfg) :: any
	buildCfg.Size           = resolvedSize
	-- Default to top-left position (UDim2.fromOffset(EDGE, EDGE+ins.Y)) so the window
	-- never sits off-center on first open.  Respects top inset for mobile status bar.
	buildCfg.Position       = clampPositionToViewport(
		cfg.Position or UDim2.fromOffset(VIEWPORT_EDGE_MARGIN, VIEWPORT_EDGE_MARGIN + safeInsets().Y),
		resolvedSize
	)

	local root, canvas, titleBar, content, handle, stroke, titleLabel, sep = buildWindow(title, buildCfg, resolvedMin)
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
	self._pillPosition  = (cfg.PillPosition or "Top") :: PillPosition
	self._hidden        = false
	self._hideAnimating = false
	self._savedPosition = nil :: UDim2?
	self._pillBg        = nil :: any
	self._pillDot       = nil :: any
	self._pillTitle     = nil :: any
	self._pillSub       = nil :: any
	self._pillInteract  = nil :: any
	self._pillBgStroke  = nil :: any

	-- Search system (Command Palette)
	self._search        = Search.new(self, gui, canvas, self._maid)

	local minSize = resolvedMin

	setupDrag(self._maid, titleBar, root, self._autoScale)
	setupResize(self._maid, handle, root, minSize, self._autoScale)

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
		self._maid:GiveTask((searchBtn_w :: TextButton).MouseButton1Click:Connect(function()
			self._search:Toggle()
		end))
		self._maid:GiveTask((settingsBtn_w :: TextButton).MouseButton1Click:Connect(function()
			Notification.notify({ Title = "Settings", Message = "Coming soon.", Type = "info", Duration = 3 })
		end))
		self._maid:GiveTask(minusBtn_w.MouseButton1Click:Connect(function()
			self:_toggleCollapse()
		end))
		self._maid:GiveTask(collapseBtn_w.MouseButton1Click:Connect(function()
			self:ToggleHide()
		end))

		Tooltip.bind(searchBtn_w :: TextButton, "Search (Ctrl+F)", { ParentGui = gui })
		Tooltip.bind(settingsBtn_w :: TextButton, "Settings", { ParentGui = gui })
		Tooltip.bind(minusBtn_w, "Minimize", { ParentGui = gui })
		Tooltip.bind(collapseBtn_w, "Hide / Pill", { ParentGui = gui })
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
		task.delay(0.12, function()
			if not self._hidden and not self._collapsed then
				self:_revealTabList()
			end
		end)
	end)

	self:_buildPillFace()

	-- ── viewport resize listener (orientation change, window resize, screen flip) ──
	-- Re-clamps size + position so the window can never escape the screen even on mobile.
	if self._autoScale then
		local function refit()
			if self._closing then return end
			if self._hidden or self._collapsed then return end
			local cs = clampSizeToViewport(self._root.Size, self._minSize)
			if cs ~= self._root.Size then
				self._root.Size = cs
				self._expandedSize = cs
			end
			local cp = clampPositionToViewport(self._root.Position, self._root.Size)
			if cp ~= self._root.Position then
				self._root.Position = cp
			end
		end
		-- Re-fit only when the ViewportSize actually changes (orientation flip, screen
		-- resize, etc).  The cache invalidator at module load already updates
		-- _cachedVp, so we just need to also refit ourselves here.
		local cam = workspace.CurrentCamera
		if cam then
			self._maid:GiveTask(cam:GetPropertyChangedSignal("ViewportSize"):Connect(refit))
		end
	end

	return self
end

-- ── component factory helpers ─────────────────────────────────────────────────

function Window:_nextOrder(): number
	self._layoutOrder += 1
	return self._layoutOrder
end

function Window:_addToContent(comp: any, config: any?, typeName: string?): any
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

	if self._search and config and comp.GetFrame then
		local label = config.Label or config.Title or config.Text or config.Name or ""
		if typeof(label) == "string" and #label > 0 then
			self._search:Register({
				Label     = label,
				TabName   = "Main",
				TabIdx    = 1,
				GroupName = nil,
				TypeName  = typeName or "Control",
				Comp      = comp,
				Frame     = comp:GetFrame(),
			})
		end
	end

	self._maid:GiveTask(comp)
	return comp
end

function Window:AddButton(config: { Label: string, Variant: number?, Enabled: boolean?, description: string?, Tooltip: string? })
	local c = config :: any
	c.LayoutOrder = self:_nextOrder()
	return self:_addToContent(Components.Button.new(c), c, "Button")
end

function Window:AddToggle(config: { Label: string, Default: boolean?, Enabled: boolean?, description: string?, Tooltip: string? })
	local c = config :: any
	c.LayoutOrder = self:_nextOrder()
	return self:_addToContent(Components.Toggle.new(c), c, "Toggle")
end

function Window:AddLabel(text: string, color: Color3?)
	local lbl = Components.Label.new({
		Text        = text,
		Color       = color,
		LayoutOrder = self:_nextOrder(),
	})
	return self:_addToContent(lbl, nil, "Label")
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
	return self:_addToContent(div, nil, "Divider")
end

function Window:AddSlider(config: {
	Label: string, Min: number?, Max: number?, Default: number?,
	Step: number?, Enabled: boolean?, description: string?, Tooltip: string?,
})
	local c = config :: any
	c.LayoutOrder = self:_nextOrder()
	return self:_addToContent(Components.Slider.new(c), c, "Slider")
end

function Window:AddTextbox(config: {
	Label: string?, Placeholder: string?, Default: string?, MaxLength: number?,
	ClearOnFocus: boolean?, Enabled: boolean?, description: string?, Tooltip: string?,
})
	local c = config :: any
	c.LayoutOrder = self:_nextOrder()
	return self:_addToContent(Components.Textbox.new(c), c, "Textbox")
end

function Window:AddKeybind(config: {
	Label: string, Default: Enum.KeyCode?, Blacklist: { any }?,
	Enabled: boolean?, description: string?, Tooltip: string?,
})
	local c = config :: any
	c.LayoutOrder = self:_nextOrder()
	return self:_addToContent(Components.Keybind.new(c), c, "Keybind")
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

	-- Pre-hide all cards before the pane becomes visible → clean cascade
	if not self._hidden and not self._hideAnimating then
		self:_preHidePane(tab.pane)
	end
	tab.pane.Visible = true

	-- Cascade the newly visible page top-to-bottom
	if not self._hidden and not self._hideAnimating then
		self:_revealPane(tab.pane)
	end

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

	local tabObj = Tab.new(pane, self._gui, self._maid, self._canvas, self, name, tabIdx)

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

	return Tab.new(pane, self._gui, self._maid, self._canvas, self, name, tabIdx)
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
	Tooltip:     string?,
})
	local c = config :: any
	c.LayoutOrder   = self:_nextOrder()
	return self:_addToContent(Components.Dropdown.new(c), c, "Dropdown")
end

-- ── AddColorPicker ────────────────────────────────────────────────────────────

function Window:AddColorPicker(config: {
	Label:       string,
	Default:     Color3?,
	ShowAlpha:   boolean?,
	Flag:        string?,
	Risky:       boolean?,
	Enabled:     boolean?,
	description: string?,
	Tooltip:     string?,
})
	local c = table.clone(config) :: any
	c.OverlayParent = self._gui
	c.Canvas        = self._canvas
	c.LayoutOrder   = self:_nextOrder()
	return self:_addToContent(Components.ColorPicker.new(c), c, "ColorPicker")
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

		local targetW = if self._sidebarExpanded then SIDEBAR_W_EXPANDED else SIDEBAR_W_COLLAPSED

		-- Grow the frame back smoothly
		TweenService:Create(self._root, TWEEN_EXPAND, {
			Size = self._expandedSize,
		}):Play()

		if self._content then self._content.Visible = true end
		if self._tabHost then self._tabHost.Visible = true end
		if self._sep     then self._sep.Visible     = true end

		if self._sidebar then
			self._sidebar.Visible           = true
			self._sidebar.Position          = UDim2.new(0, 0, 0, 0)
			self._sidebar.Size              = UDim2.new(0, targetW, 0, Theme.TitleBarHeight)
			self._sidebar.GroupTransparency = 1
			local ss = self._sidebar:FindFirstChildOfClass("UIStroke")
			if ss then ss.Transparency = 1 end

			self:_preHideTabList()

			TweenService:Create(self._sidebar,
				TweenInfo.new(0.48, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out),
				{
					Position          = UDim2.new(0, -(targetW + SIDEBAR_GAP), 0, 0),
					Size              = UDim2.new(0, targetW, 1, 0),
					GroupTransparency = 0,
				}
			):Play()
			if ss then
				TweenService:Create(ss,
					TweenInfo.new(0.38, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
					{ Transparency = 0 }
				):Play()
			end

			task.delay(0.12, function()
				if not self._collapsed and not self._hidden then
					self:_revealTabList()
				end
			end)
		end

		task.delay(0.52, function()
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

		-- Hide canvas content so nothing squashes under shrinking frame
		if self._content then self._content.Visible = false end
		if self._tabHost then self._tabHost.Visible = false end
		if self._sep     then self._sep.Visible     = false end

		-- Sidebar folds and tucks into the window titlebar
		if self._sidebar then
			local targetW = if self._sidebarExpanded then SIDEBAR_W_EXPANDED else SIDEBAR_W_COLLAPSED
			local ss = self._sidebar:FindFirstChildOfClass("UIStroke")
			if ss then
				TweenService:Create(ss,
					TweenInfo.new(0.30, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
					{ Transparency = 1 }
				):Play()
			end
			TweenService:Create(self._sidebar,
				TweenInfo.new(0.42, Enum.EasingStyle.Exponential, Enum.EasingDirection.InOut),
				{
					Position          = UDim2.new(0, 0, 0, 0),
					Size              = UDim2.new(0, targetW, 0, Theme.TitleBarHeight),
					GroupTransparency = 1,
				}
			):Play()
			task.delay(0.44, function()
				if self._collapsed and self._sidebar then
					self._sidebar.Visible = false
				end
			end)
		end

		-- Shrink the window to titlebar height
		TweenService:Create(self._root, TWEEN_COLLAPSE, {
			Size = UDim2.fromOffset(
				self._root.AbsoluteSize.X,
				Theme.TitleBarHeight + 2
			),
		}):Play()

		task.delay(0.48, function()
			self._collapseAnimating = false
		end)
	end
end

-- ── pill face ───────────────────────────────────────────────────────────────────

function Window:_buildPillFace()
	-- PillBg: gradient + samar outline — shown only while the window is hidden (pill state).
	-- CanvasGroup's UICorner already clips this to the pill silhouette; no corner needed here.
	local pillBg                 = Instance.new("Frame")
	pillBg.Name                  = "PillBg"
	pillBg.Size                  = UDim2.fromScale(1, 1)
	pillBg.BackgroundColor3      = Color3.fromHex("#1e1e1e")
	pillBg.BorderSizePixel       = 0
	pillBg.BackgroundTransparency = 1
	pillBg.Visible               = false
	pillBg.ZIndex                = 8
	local pillBgGrad             = Instance.new("UIGradient")
	pillBgGrad.Color             = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromHex("#2e2e2e")),
		ColorSequenceKeypoint.new(1, Color3.fromHex("#191919")),
	})
	pillBgGrad.Rotation          = 90
	pillBgGrad.Parent            = pillBg
	local pillBgStroke           = Instance.new("UIStroke")
	pillBgStroke.Color           = Theme.Colors.Border
	pillBgStroke.Thickness       = 1
	pillBgStroke.Transparency    = 1
	pillBgStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	pillBgStroke.Parent          = pillBg
	pillBg.Parent                = self._canvas
	self._pillBg                 = pillBg
	self._pillBgStroke           = pillBgStroke

	-- dot: kept as a zero-size stub so refs remain valid
	local dot                  = Instance.new("Frame")
	dot.Name                   = "PillDot"
	dot.AnchorPoint            = Vector2.new(0.5, 0.5)
	dot.Position               = UDim2.new(0.5, 0, 0.5, 0)
	dot.Size                   = UDim2.fromOffset(0, 0)
	dot.BackgroundColor3       = Theme.Colors.Accent
	dot.BorderSizePixel        = 0
	dot.BackgroundTransparency = 1
	dot.ZIndex                 = 10
	applyCorner(dot, 4)
	dot.Parent = self._canvas

	-- title: window title, centered
	local pillTitle                  = Instance.new("TextLabel")
	pillTitle.Name                   = "PillTitle"
	pillTitle.AnchorPoint            = Vector2.new(0.5, 0.5)
	pillTitle.Position               = UDim2.new(0.5, 0, 0.5, -6)
	pillTitle.Size                   = UDim2.new(1, -16, 0, 14)
	pillTitle.BackgroundTransparency = 1
	pillTitle.Font                   = Theme.Font.Title
	pillTitle.Text                   = self.Title
	pillTitle.TextSize               = 11
	pillTitle.TextColor3             = Theme.Colors.TextPrimary
	pillTitle.TextXAlignment         = Enum.TextXAlignment.Center
	pillTitle.TextTruncate           = Enum.TextTruncate.AtEnd
	pillTitle.TextTransparency       = 1
	pillTitle.ZIndex                 = 11
	pillTitle.Parent                 = self._canvas

	-- subtitle, centered
	local pillSub                    = Instance.new("TextLabel")
	pillSub.Name                     = "PillSubtitle"
	pillSub.AnchorPoint              = Vector2.new(0.5, 0.5)
	pillSub.Position                 = UDim2.new(0.5, 0, 0.5, 7)
	pillSub.Size                     = UDim2.new(1, -16, 0, 11)
	pillSub.BackgroundTransparency   = 1
	pillSub.Font                     = Theme.Font.Body
	pillSub.Text                     = "tap to open"
	pillSub.TextSize                 = 9
	pillSub.TextColor3               = Theme.Colors.TextSecondary
	pillSub.TextXAlignment           = Enum.TextXAlignment.Center
	pillSub.TextTruncate             = Enum.TextTruncate.AtEnd
	pillSub.TextTransparency         = 1
	pillSub.ZIndex                   = 11
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

function Window:SetPillPosition(position: PillPosition)
	self._pillPosition = position
	if self._hidden then
		local pillSize, pillPos = getPillGeometry(self._pillPosition)
		TweenService:Create(self._root, TWEEN_PILL_MORPH, {
			Size     = pillSize,
			Position = pillPos,
		}):Play()
	end
end

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

	-- Sidebar: smoothly slides in toward the window and folds/tucks inside as it dissolves
	if self._sidebar then
		local targetW = if self._sidebarExpanded then SIDEBAR_W_EXPANDED else SIDEBAR_W_COLLAPSED
		local ss = self._sidebar:FindFirstChildOfClass("UIStroke")
		if ss then
			TweenService:Create(ss,
				TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
				{ Transparency = 1 }
			):Play()
		end
		TweenService:Create(self._sidebar,
			TweenInfo.new(0.40, Enum.EasingStyle.Exponential, Enum.EasingDirection.InOut),
			{
				Position          = UDim2.new(0, 0, 0, 0),
				Size              = UDim2.new(0, targetW, 0, 36),
				GroupTransparency = 1,
			}
		):Play()
		task.delay(0.42, function()
			if self._hidden and self._sidebar then
				self._sidebar.Visible = false
			end
		end)
	end

	-- Pill background & canvas color: smooth cross-fade transition into the dark pill gradient
	if self._pillBg then
		self._pillBg.Visible = true
		self._pillBg.BackgroundTransparency = 1
		TweenService:Create(self._pillBg, TWEEN_PILL_MORPH, { BackgroundTransparency = 0 }):Play()
	end
	if self._pillBgStroke then
		self._pillBgStroke.Transparency = 1
		TweenService:Create(self._pillBgStroke, TWEEN_PILL_MORPH, { Transparency = 0.35 }):Play()
	end
	TweenService:Create(self._canvas, TWEEN_PILL_MORPH, { BackgroundColor3 = Color3.fromHex("#1e1e1e") }):Play()

	-- Stroke fades out quickly
	TweenService:Create(self._stroke,
		TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
		{ Transparency = 1 }
	):Play()

	-- Morph root → pill (canvas fills root via fromScale, clips naturally)
	local pillSize, pillPos = getPillGeometry(self._pillPosition)
	TweenService:Create(self._root, TWEEN_PILL_MORPH, {
		Size     = pillSize,
		Position = pillPos,
	}):Play()

	-- Corner → fully rounded (pill shape)
	local corner = self._canvas:FindFirstChildOfClass("UICorner")
	if corner then
		TweenService:Create(corner, TWEEN_PILL_MORPH, { CornerRadius = UDim.new(0, 18) }):Play()
	end

	-- When morph is nearly done: fade pill face in
	local faceInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	task.delay(0.35, function()
		if not self._hidden then return end

		-- Reset pill face to transparent (safe against interrupted Show)
		self._pillDot.BackgroundTransparency = 1
		self._pillTitle.TextTransparency     = 1
		self._pillSub.TextTransparency       = 1

		-- dot is zero-size; only title + subtitle fade in
		TweenService:Create(self._pillTitle, faceInfo, { TextTransparency       = 0   }):Play()
		TweenService:Create(self._pillSub,   faceInfo, { TextTransparency       = 0.4 }):Play()

		task.delay(0.18, function()
			if not self._hidden then return end
			self._pillInteract.Visible = true
			self._hideAnimating = false
		end)
	end)
end

-- ── Page content reveal — staggered top-to-bottom cascade ────────────────────
--
-- Two-phase: _preHidePane snaps all cards to invisible before the pane becomes
-- Visible, then _revealPane stagger-tweens them in top-to-bottom. This prevents
-- the "all appear at once" flash that happens when content turns Visible while
-- cards are still at their constructed BackgroundTransparency = 0.
--
-- Stagger only applies to on-screen elements (visible in the scroll viewport).
-- Off-screen elements are snapped in instantly — same behaviour as Rayfield.

local REVEAL_CARD    = TweenInfo.new(0.28, Enum.EasingStyle.Quint,       Enum.EasingDirection.Out)
local REVEAL_STROKE  = TweenInfo.new(0.22, Enum.EasingStyle.Quint,       Enum.EasingDirection.Out)
local REVEAL_SHADOW  = TweenInfo.new(0.32, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
local REVEAL_STAGGER = 0.038  -- seconds between each on-screen item

type RevealItem = {
	Type: string,
	Object: GuiObject,
}

-- Extract child components inside a GroupboxFrame (Buttons, Toggles, Sliders, Dropdowns, etc.).
-- Excludes styling/layout objects and GroupboxTitle, and sorts them by LayoutOrder.
local function getGroupboxComponents(box: Frame): { GuiObject }
	local comps: { GuiObject } = {}
	for _, child in box:GetChildren() do
		if not child:IsA("GuiObject") then continue end
		if child.Name == "GroupboxTitle" then continue end
		if child:IsA("UIListLayout") or child:IsA("UIPadding") then continue end
		table.insert(comps, child)
	end
	table.sort(comps, function(a, b)
		return a.LayoutOrder < b.LayoutOrder
	end)
	return comps
end

-- Collect items to reveal from a pane in top-to-bottom visual order.
-- For Groupboxes, the container shell (border + title) reveals first, followed by each
-- child component individually. For two-column rows, shells are staggered left-to-right,
-- then components cascade in row-by-row left-to-right so both columns animate fluidly.
local function collectRevealItems(pane: ScrollingFrame): { RevealItem }
	local topLevel: { GuiObject } = {}

	for _, child in pane:GetChildren() do
		if not child:IsA("GuiObject") then continue end
		if child:IsA("UIListLayout") or child:IsA("UIPadding") then continue end
		table.insert(topLevel, child)
	end

	table.sort(topLevel, function(a, b)
		return a.LayoutOrder < b.LayoutOrder
	end)

	local items: { RevealItem } = {}

	for _, child in topLevel do
		if child.Name == "GroupboxRow" then
			local boxes: { Frame } = {}
			for _, sub in child:GetChildren() do
				if sub:IsA("Frame") then
					table.insert(boxes, sub)
				end
			end
			table.sort(boxes, function(a, b)
				local aX = a.Position.X.Scale * 1000 + a.Position.X.Offset
				local bX = b.Position.X.Scale * 1000 + b.Position.X.Offset
				return aX < bX
			end)

			for _, b in boxes do
				table.insert(items, { Type = "GroupboxShell", Object = b })
			end

			local allBoxComps: { { GuiObject } } = {}
			local maxCount = 0
			for _, b in boxes do
				local comps = getGroupboxComponents(b)
				table.insert(allBoxComps, comps)
				if #comps > maxCount then
					maxCount = #comps
				end
			end

			for i = 1, maxCount do
				for _, comps in allBoxComps do
					if comps[i] then
						table.insert(items, { Type = "Element", Object = comps[i] })
					end
				end
			end
		elseif child.Name == "GroupboxFrame" then
			table.insert(items, { Type = "GroupboxShell", Object = child })
			for _, comp in getGroupboxComponents(child :: Frame) do
				table.insert(items, { Type = "Element", Object = comp })
			end
		else
			table.insert(items, { Type = "Element", Object = child })
		end
	end

	return items
end

-- Pre-hide a GuiObject and all its descendants (text, images, strokes, backgrounds, shadows).
-- Remembers resting transparencies via attributes so reveal can restore them accurately.
local function preHideElement(root: GuiObject)
	local function hideObj(obj: Instance)
		if obj:IsA("TextLabel") or obj:IsA("TextBox") or obj:IsA("TextButton") then
			if obj:GetAttribute("RestTextT") == nil then
				obj:SetAttribute("RestTextT", (obj :: any).TextTransparency)
			end
			(obj :: any).TextTransparency = 1
		end

		if obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
			if obj:GetAttribute("RestImgT") == nil then
				obj:SetAttribute("RestImgT", (obj :: any).ImageTransparency)
			end
			(obj :: any).ImageTransparency = 1
		end

		if obj:IsA("UIStroke") then
			if obj:GetAttribute("RestStrokeT") == nil then
				obj:SetAttribute("RestStrokeT", obj.Transparency)
			end
			obj.Transparency = 1
		end

		if obj:IsA("Frame") or obj:IsA("ScrollingFrame") then
			if obj.BackgroundTransparency < 1 then
				if obj:GetAttribute("RestBgT") == nil then
					obj:SetAttribute("RestBgT", obj.BackgroundTransparency)
				end
				obj.BackgroundTransparency = 1
			end
		end
	end

	hideObj(root)
	for _, desc in root:GetDescendants() do
		hideObj(desc)
	end
end

-- Restore resting transparencies for a single instance.
local function restoreObj(obj: Instance)
	local restTextT = obj:GetAttribute("RestTextT")
	if restTextT ~= nil and (obj:IsA("TextLabel") or obj:IsA("TextBox") or obj:IsA("TextButton")) then
		TweenService:Create(obj, REVEAL_CARD, { TextTransparency = restTextT }):Play()
	end

	local restImgT = obj:GetAttribute("RestImgT")
	if restImgT ~= nil and (obj:IsA("ImageLabel") or obj:IsA("ImageButton")) then
		TweenService:Create(obj, REVEAL_CARD, { ImageTransparency = restImgT }):Play()
	end

	local restStrokeT = obj:GetAttribute("RestStrokeT")
	if restStrokeT ~= nil and obj:IsA("UIStroke") then
		TweenService:Create(obj, REVEAL_STROKE, { Transparency = restStrokeT }):Play()
	end

	local restBgT = obj:GetAttribute("RestBgT")
	if restBgT ~= nil and (obj:IsA("Frame") or obj:IsA("ScrollingFrame")) then
		local tInfo = if obj.Name == "Shadow" then REVEAL_SHADOW else REVEAL_CARD
		TweenService:Create(obj, tInfo, { BackgroundTransparency = restBgT }):Play()
	end
end

-- Tween a GuiObject and all its descendants back to resting transparencies.
local function revealElement(root: GuiObject)
	restoreObj(root)
	for _, desc in root:GetDescendants() do
		restoreObj(desc)
	end
end

-- Tween only the Groupbox frame background, border stroke, and title label.
-- Leaves inner components hidden so they can cascade in individually.
local function revealGroupboxShell(box: Frame)
	restoreObj(box)
	local stroke = box:FindFirstChildOfClass("UIStroke")
	if stroke then
		restoreObj(stroke)
	end
	local title = box:FindFirstChild("GroupboxTitle")
	if title then
		restoreObj(title)
	end
end

-- Pre-hide all layout elements in a pane synchronously. Call before Visible = true.
function Window:_preHidePane(pane: ScrollingFrame)
	if not pane then return end
	for _, child in pane:GetChildren() do
		if child:IsA("GuiObject") and not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
			preHideElement(child)
		end
	end
end

-- Stagger-reveal all layout elements in a pane top-to-bottom. Call after Visible = true.
function Window:_revealPane(pane: ScrollingFrame)
	if not pane then return end
	local items = collectRevealItems(pane)

	-- Viewport bounds for on-screen check (read after pane is visible)
	local viewTop    = pane.AbsolutePosition.Y
	local viewBottom = viewTop + pane.AbsoluteWindowSize.Y

	task.spawn(function()
		for _, item in items do
			local elem = item.Object
			local top      = elem.AbsolutePosition.Y
			local bottom   = top + elem.AbsoluteSize.Y
			local onScreen = bottom > viewTop and top < viewBottom

			if item.Type == "GroupboxShell" then
				revealGroupboxShell(elem :: Frame)
			else
				revealElement(elem)
			end

			if onScreen then
				task.wait(REVEAL_STAGGER)
			end
		end
	end)
end

-- ── Tab list reveal — staggered top-to-bottom cascade ────────────────────────
local TWEEN_TAB_REVEAL = TweenInfo.new(0.26, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local TAB_REVEAL_STAGGER = 0.035

function Window:_preHideTabList()
	if not self._tabs then return end
	for _, t in ipairs(self._tabs) do
		local btn = t.btn
		if btn then
			btn.BackgroundTransparency = 1
			local stroke = btn:FindFirstChildOfClass("UIStroke")
			if stroke then stroke.Transparency = 1 end
			local lbl = btn:FindFirstChild("TabLabel")
			if lbl then lbl.TextTransparency = 1 end
			local icon = btn:FindFirstChild("TabIcon", true)
			if icon then icon.ImageTransparency = 1 end
			local ind = btn:FindFirstChild("Indicator")
			if ind then ind.BackgroundTransparency = 1 end
		end
	end
	if self._groups then
		for _, g in ipairs(self._groups) do
			if g.entry and g.entry.header then
				g.entry.header.BackgroundTransparency = 1
				local lbl = g.entry.header:FindFirstChild("GroupLabel")
				if lbl then lbl.TextTransparency = 1 end
			end
		end
	end
end

function Window:_revealTabList()
	if not self._tabs or #self._tabs == 0 then return end
	local tabs = self._tabs

	task.spawn(function()
		for idx, t in ipairs(tabs) do
			local btn = t.btn
			if btn then
				local isActive = self._activeTabIdx == idx
				TweenService:Create(btn, TWEEN_TAB_REVEAL, { BackgroundTransparency = 0 }):Play()
				local stroke = btn:FindFirstChildOfClass("UIStroke")
				if stroke then
					TweenService:Create(stroke, TWEEN_TAB_REVEAL, {
						Transparency = if isActive then 0.3 else 0.45,
					}):Play()
				end
				local lbl = btn:FindFirstChild("TabLabel")
				if lbl then
					TweenService:Create(lbl, TWEEN_TAB_REVEAL, { TextTransparency = 0 }):Play()
				end
				local icon = btn:FindFirstChild("TabIcon", true)
				if icon then
					TweenService:Create(icon, TWEEN_TAB_REVEAL, { ImageTransparency = 0 }):Play()
				end
				local ind = btn:FindFirstChild("Indicator")
				if ind and isActive and self._sidebarExpanded then
					TweenService:Create(ind, TWEEN_TAB_REVEAL, { BackgroundTransparency = 0 }):Play()
				end
			end
			task.wait(TAB_REVEAL_STAGGER)
		end
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
	TweenService:Create(self._pillTitle, fadeInfo, { TextTransparency       = 1 }):Play()
	TweenService:Create(self._pillSub,   fadeInfo, { TextTransparency       = 1 }):Play()

	-- Morph root → window
	if self._autoScale then
		self._expandedSize = clampSizeToViewport(self._expandedSize, self._minSize)
	end
	local target = self._savedPosition or UDim2.fromScale(0.5, 0.5)
	if self._autoScale then
		target = clampPositionToViewport(target, self._expandedSize)
	end
	TweenService:Create(self._root, TWEEN_PILL_REVEAL, {
		Size     = self._expandedSize,
		Position = target,
	}):Play()

	-- Pill background & canvas color: smooth cross-fade transition back to window open color
	if self._pillBg then
		self._pillBg.Visible = true
		self._pillBg.BackgroundTransparency = 0
		TweenService:Create(self._pillBg, TWEEN_PILL_REVEAL, { BackgroundTransparency = 1 }):Play()
	end
	if self._pillBgStroke then
		self._pillBgStroke.Transparency = 0.35
		TweenService:Create(self._pillBgStroke, TWEEN_PILL_REVEAL, { Transparency = 1 }):Play()
	end
	TweenService:Create(self._canvas, TWEEN_PILL_REVEAL, { BackgroundColor3 = Theme.Colors.Surface }):Play()

	-- Sidebar: smoothly unfolds and slides out from the expanding root
	if self._sidebar then
		local targetW = if self._sidebarExpanded then SIDEBAR_W_EXPANDED else SIDEBAR_W_COLLAPSED
		self._sidebar.Position          = UDim2.new(0, 0, 0, 0)
		self._sidebar.Size              = UDim2.new(0, targetW, 0, 36)
		self._sidebar.GroupTransparency = 1
		self._sidebar.Visible           = true
		local ss = self._sidebar:FindFirstChildOfClass("UIStroke")
		if ss then ss.Transparency = 1 end

		-- Pre-hide tabs so they don't pop in before cascading
		self:_preHideTabList()

		TweenService:Create(self._sidebar,
			TweenInfo.new(0.50, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out),
			{
				Position          = UDim2.new(0, -(targetW + SIDEBAR_GAP), 0, 0),
				Size              = UDim2.new(0, targetW, 1, 0),
				GroupTransparency = 0,
			}
		):Play()
		if ss then
			TweenService:Create(ss,
				TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
				{ Transparency = 0 }
			):Play()
		end

		-- Stagger-reveal tabs top-to-bottom as sidebar unfolds
		task.delay(0.12, function()
			if not self._hidden then
				self:_revealTabList()
			end
		end)
	end

	-- Corner → window roundness
	local corner = self._canvas:FindFirstChildOfClass("UICorner")
	if corner then
		TweenService:Create(corner, cornerInfo, {
			CornerRadius = UDim.new(0, Theme.Radius.Medium),
		}):Play()
	end

	-- Halfway through morph: reveal chrome then cascade page content
	task.delay(0.20, function()
		if self._hidden then return end
		if self._titleBar then self._titleBar.Visible = true end
		TweenService:Create(self._stroke, chromeFade, { Transparency = 0 }):Play()

		-- Determine which pane to reveal
		local pane: ScrollingFrame? = nil
		local tabs = self._tabs
		if tabs then
			local idx = self._activeTabIdx
			if idx and idx > 0 and tabs[idx] then
				pane = tabs[idx].pane
			end
		else
			pane = self._content :: any
		end

		-- Pre-hide all cards while pane is still invisible, then show + cascade
		if pane then
			self:_preHidePane(pane)
		end

		if self._sep     then self._sep.Visible     = not self._collapsed end
		if self._content then self._content.Visible = not self._collapsed end
		if self._tabHost then self._tabHost.Visible = not self._collapsed end
		if self._handle  then self._handle.Visible  = not self._collapsed end

		-- Stagger reveal starts immediately — cards are already invisible
		if pane and not self._collapsed then
			self:_revealPane(pane)
		end
	end)

	task.delay(0.52, function()
		self._hideAnimating = false
		if not self._hidden and self._pillBg then
			self._pillBg.Visible = false
		end
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
    function()local wax,script,require=ImportGlobals(21)local ImportGlobals return (function(...)--!strict

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
    function()local wax,script,require=ImportGlobals(22)local ImportGlobals return (function(...)--!strict

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
    function()local wax,script,require=ImportGlobals(23)local ImportGlobals return (function(...)--!strict

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
    [25] = function()local wax,script,require=ImportGlobals(25)local ImportGlobals return (function(...)--!strict

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
    [26] = function()local wax,script,require=ImportGlobals(26)local ImportGlobals return (function(...)--!strict

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
    [27] = function()local wax,script,require=ImportGlobals(27)local ImportGlobals return (function(...)--!strict

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
    [28] = function()local wax,script,require=ImportGlobals(28)local ImportGlobals return (function(...)--!strict

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
	local isPureTouch = UserInputService.TouchEnabled and not UserInputService.MouseEnabled

	-- On pure touch devices (mobile/tablet), keep ScrollingEnabled = true for native inertia swipe.
	-- On desktop/mouse devices, disable native snap-scroll to drive custom smooth CanvasPosition.
	frame.ScrollingEnabled = isPureTouch
	frame.ElasticBehavior  = Enum.ElasticBehavior.WhenScrollable
	frame.Active           = true

	local entry: ManagedEntry = { frame = frame }
	table.insert(_managed, entry)

	local targetY: number     = frame.CanvasPosition.Y
	local activeTween: Tween? = nil

	-- For hybrid touch-enabled PC/laptops: enable native scroll when touch begins
	local touchBeganConn = frame.InputBegan:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.Touch then
			frame.ScrollingEnabled = true
		end
	end)

	local inputConn = UserInputService.InputChanged:Connect(function(input: InputObject)
		if _paused then return end
		if input.UserInputType ~= Enum.UserInputType.MouseWheel then return end

		-- Ensure desktop mouse wheel uses custom smooth tween
		if frame.ScrollingEnabled and not isPureTouch then
			frame.ScrollingEnabled = false
		end

		local mousePos = UserInputService:GetMouseLocation()

		-- Bounds check: mouse must be within this frame's visible area.
		if not isInBounds(frame, mousePos) then return end

		-- Priority: yield to a managed descendant that's also under the cursor.
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
	local sizeConn = frame:GetPropertyChangedSignal("AbsoluteCanvasSize"):Connect(function()
		local maxY = math.max(0, frame.AbsoluteCanvasSize.Y - frame.AbsoluteSize.Y)
		targetY = math.clamp(targetY, 0, maxY)
	end)

	return function()
		touchBeganConn:Disconnect()
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
    [29] = function()local wax,script,require=ImportGlobals(29)local ImportGlobals return (function(...)--!strict

local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players          = game:GetService("Players")

local Theme = require(script.Parent.Parent.Theme)

local TWEEN_IN  = TweenInfo.new(0.20, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local TWEEN_OUT = TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.In)

local _gui: ScreenGui?     = nil
local _tipFrame: Frame?    = nil
local _tipLabel: TextLabel? = nil
local _tipScale: UIScale?  = nil
local _tipStroke: UIStroke? = nil

local _activeTarget: GuiObject? = nil
local _currentText: string      = ""
local _showThread: thread?      = nil
local _hideThread: thread?      = nil
local _isShown                  = false

local function ensureGui(parentGui: ScreenGui?)
	if _tipFrame then return end

	local targetGui = parentGui
	if not targetGui then
		local lp = Players.LocalPlayer
		if lp then
			targetGui = lp:FindFirstChildOfClass("PlayerGui")
		end
	end

	if not targetGui then
		local ok, core = pcall(function() return game:GetService("CoreGui") end)
		if ok and core then
			local g = Instance.new("ScreenGui")
			g.Name = "DeliriumTooltips"
			g.ResetOnSpawn = false
			g.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
			g.IgnoreGuiInset = true
			pcall(function() g.DisplayOrder = 9999 end)
			g.Parent = core
			targetGui = g
		end
	end

	if not targetGui then return end
	_gui = targetGui

	local tip = Instance.new("Frame")
	tip.Name                   = "FloatingTooltip"
	tip.AnchorPoint            = Vector2.new(0, 0)
	tip.Position               = UDim2.fromOffset(0, 0)
	tip.Size                   = UDim2.fromOffset(0, 0)
	tip.AutomaticSize          = Enum.AutomaticSize.XY
	tip.BackgroundColor3       = Color3.fromHex("#141414")
	tip.BackgroundTransparency = 1
	tip.BorderSizePixel        = 0
	tip.ZIndex                 = 10000
	tip.Visible                = false
	tip.Parent                 = targetGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, Theme.Radius.Small + 1)
	corner.Parent = tip

	local stroke = Instance.new("UIStroke")
	stroke.Color           = Theme.Colors.Border
	stroke.Thickness       = 1
	stroke.Transparency    = 1
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent          = tip
	_tipStroke             = stroke

	local scale = Instance.new("UIScale")
	scale.Scale  = 0.90
	scale.Parent = tip
	_tipScale    = scale

	local pad = Instance.new("UIPadding")
	pad.PaddingTop    = UDim.new(0, 5)
	pad.PaddingBottom = UDim.new(0, 5)
	pad.PaddingLeft   = UDim.new(0, 8)
	pad.PaddingRight  = UDim.new(0, 8)
	pad.Parent        = tip

	local lbl = Instance.new("TextLabel")
	lbl.Name                   = "TooltipLabel"
	lbl.AutomaticSize          = Enum.AutomaticSize.XY
	lbl.Size                   = UDim2.fromOffset(0, 0)
	lbl.BackgroundTransparency = 1
	lbl.Font                   = Theme.Font.Body
	lbl.Text                   = ""
	lbl.TextSize               = Theme.TextSize.Small
	lbl.TextColor3             = Theme.Colors.TextPrimary
	lbl.TextTransparency       = 1
	lbl.TextXAlignment         = Enum.TextXAlignment.Left
	lbl.TextYAlignment         = Enum.TextYAlignment.Center
	lbl.RichText               = true
	lbl.ZIndex                 = 10001
	lbl.Parent                 = tip
	_tipLabel                  = lbl

	_tipFrame = tip
end

local function updatePosition(customPos: Vector2?)
	if not _tipFrame or not _tipFrame.Visible then return end
	local pos = customPos or UserInputService:GetMouseLocation()

	local cam = workspace.CurrentCamera
	local vp = if cam then cam.ViewportSize else Vector2.new(1024, 768)

	local tipW = _tipFrame.AbsoluteSize.X
	local tipH = _tipFrame.AbsoluteSize.Y

	local targetX = pos.X + 12
	local targetY = pos.Y + 14

	-- Flip horizontally if overflow
	if targetX + tipW > vp.X - 8 then
		targetX = pos.X - tipW - 8
	end

	-- Flip vertically if overflow
	if targetY + tipH > vp.Y - 8 then
		targetY = pos.Y - tipH - 8
	end

	targetX = math.clamp(targetX, 4, math.max(4, vp.X - tipW - 4))
	targetY = math.clamp(targetY, 4, math.max(4, vp.Y - tipH - 4))

	_tipFrame.Position = UDim2.fromOffset(targetX, targetY)
end

local function hideTooltip()
	if _showThread then
		pcall(task.cancel, _showThread)
		_showThread = nil
	end
	if not _isShown or not _tipFrame then return end
	_isShown = false
	_activeTarget = nil

	if _tipScale then
		TweenService:Create(_tipScale, TWEEN_OUT, { Scale = 0.90 }):Play()
	end
	if _tipFrame then
		TweenService:Create(_tipFrame, TWEEN_OUT, { BackgroundTransparency = 1 }):Play()
	end
	if _tipStroke then
		TweenService:Create(_tipStroke, TWEEN_OUT, { Transparency = 1 }):Play()
	end
	if _tipLabel then
		TweenService:Create(_tipLabel, TWEEN_OUT, { TextTransparency = 1 }):Play()
	end

	_hideThread = task.delay(TWEEN_OUT.Time + 0.02, function()
		if not _isShown and _tipFrame then
			_tipFrame.Visible = false
		end
	end)
end

local function showTooltip(target: GuiObject, text: string, pos: Vector2?, delaySec: number?)
	if _hideThread then
		pcall(task.cancel, _hideThread)
		_hideThread = nil
	end

	ensureGui()
	if not _tipFrame or not _tipLabel or not _tipScale or not _tipStroke then return end

	_activeTarget = target
	_currentText  = text
	_tipLabel.Text = text

	local delayTime = delaySec or 0.28

	if _showThread then pcall(task.cancel, _showThread) end
	_showThread = task.delay(delayTime, function()
		if _activeTarget ~= target then return end
		_isShown = true
		_tipFrame.Visible = true
		updatePosition(pos)

		TweenService:Create(_tipScale,  TWEEN_IN, { Scale = 1 }):Play()
		TweenService:Create(_tipFrame,  TWEEN_IN, { BackgroundTransparency = 0.05 }):Play()
		TweenService:Create(_tipStroke, TWEEN_IN, { Transparency = 0.3 }):Play()
		TweenService:Create(_tipLabel,  TWEEN_IN, { TextTransparency = 0 }):Play()
	end)
end

local Tooltip = {}

function Tooltip.bind(target: GuiObject, text: string, options: { Delay: number?, ParentGui: ScreenGui? }?): () -> ()
	if not text or #text == 0 then return function() end end

	local delaySec = options and options.Delay
	if options and options.ParentGui then
		ensureGui(options.ParentGui)
	end

	local enterConn = target.MouseEnter:Connect(function()
		showTooltip(target, text, nil, delaySec)
	end)

	local moveConn = target.MouseMoved:Connect(function()
		if _isShown and _activeTarget == target then
			updatePosition()
		end
	end)

	local leaveConn = target.MouseLeave:Connect(function()
		if _activeTarget == target then
			hideTooltip()
		end
	end)

	-- Mobile touch support: Tap / touch begin shows tooltip temporarily
	local touchConn = target.InputBegan:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.Touch then
			local pos = Vector2.new(input.Position.X, input.Position.Y)
			showTooltip(target, text, pos, 0.05)
			task.delay(2.0, function()
				if _activeTarget == target then
					hideTooltip()
				end
			end)
		end
	end)

	return function()
		enterConn:Disconnect()
		moveConn:Disconnect()
		leaveConn:Disconnect()
		touchConn:Disconnect()
		if _activeTarget == target then
			hideTooltip()
		end
	end
end

return Tooltip

end)() end,
    [30] = function()local wax,script,require=ImportGlobals(30)local ImportGlobals return (function(...)--!strict

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
                21,
                2,
                {
                    "Theme"
                },
                {
                    {
                        23,
                        2,
                        {
                            "Icons"
                        }
                    },
                    {
                        22,
                        2,
                        {
                            "Colors"
                        }
                    }
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
                        3,
                        2,
                        {
                            "Button"
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
                        4,
                        2,
                        {
                            "ColorPicker"
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
                        8,
                        2,
                        {
                            "Groupbox"
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
                        6,
                        2,
                        {
                            "Divider"
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
                        7,
                        2,
                        {
                            "Dropdown"
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
                        9,
                        2,
                        {
                            "Keybind"
                        }
                    }
                }
            },
            {
                24,
                1,
                {
                    "Utils"
                },
                {
                    {
                        25,
                        2,
                        {
                            "ErrorHandling"
                        }
                    },
                    {
                        29,
                        2,
                        {
                            "Tooltip"
                        }
                    },
                    {
                        26,
                        2,
                        {
                            "Maid"
                        }
                    },
                    {
                        28,
                        2,
                        {
                            "SmoothScroll"
                        }
                    },
                    {
                        27,
                        2,
                        {
                            "Signal"
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
                        18,
                        2,
                        {
                            "Search"
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
                        20,
                        2,
                        {
                            "Window"
                        }
                    },
                    {
                        19,
                        2,
                        {
                            "Tab"
                        }
                    },
                    {
                        17,
                        2,
                        {
                            "SaveManager"
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
            },
            {
                30,
                2,
                {
                    "types"
                }
            }
        }
    }
}

-- Line offsets for debugging (only included when minifyTables is false)
local LineOffsets = {
    8,
    84,
    124,
    509,
    1612,
    1731,
    1812,
    2651,
    2973,
    3612,
    3682,
    4210,
    4504,
    4975,
    4986,
    5569,
    6253,
    6440,
    6914,
    7215,
    9749,
    9796,
    9844,
    [25] = 9913,
    [26] = 9973,
    [27] = 10030,
    [28] = 10108,
    [29] = 10309,
    [30] = 10557
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