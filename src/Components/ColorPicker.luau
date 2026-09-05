--!strict
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
