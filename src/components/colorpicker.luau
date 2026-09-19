--!strict

-- Delirium UI Library
-- colorpicker.luau — HSV+alpha color picker. SV canvas, hue strip, optional alpha strip.
--
-- Popup layout:
--   [ SV canvas ] | [ hue ] | [ alpha? ] | [ swatch ]
--                                           [ hex  | alpha% ]
--
-- Two display modes:
--   ScreenGui mode  (overlayParent = nil):
--       Popup lives in its own ScreenGui. Backdrop = transparent full-screen TextButton.
--
--   Window mode     (overlayParent = Frame):
--       Popup + dim overlay are parented directly to overlayParent (the windowFrame).
--       Dim overlay covers the body below the title bar (pass overlayYOffset = TITLEBAR_H+1).
--       ZIndex values are all offset by constants.zIndex.popup so they sit above window chrome.
--       Clicking the dim overlay closes the picker (same as clicking outside in ScreenGui mode).
--
-- No animations. All state changes are instant property assignments.

local constants = require(script.Parent.Parent.utility.constants)
local flags     = require(script.Parent.Parent.utility.flags)
local runtime   = require(script.Parent.Parent.utility.runtime)
local element   = require(script.Parent.Parent.utility.element)
local themeUtil = require(script.Parent.Parent.utility.theme)

-- ── Popup geometry ────────────────────────────────────────────────────────────

local PAD       = 12
local MAP_W     = 175
local MAP_H     = 148
local HUE_W     = 12
local ALPHA_W   = 12
local GAP_CH    = 8
local GAP_HA    = 6
local GAP_AR    = 12
local TITLE_H   = 32
local HEX_H     = 28
local GAP_PH    = 10

local ABOX_W    = 53
local ABOX_GAP  = 5

local POPUP_W   = 360
local CONTENT_Y = TITLE_H + PAD         -- 44
local POPUP_H   = CONTENT_Y + MAP_H + PAD -- 204

local PILL_W    = 32
local PILL_H    = 18
local PILL_R    = 4
local CURSOR_D  = 14
local HANDLE_H  = 10

local HUE_CS = ColorSequence.new({
	ColorSequenceKeypoint.new(0.000, Color3.fromRGB(255, 0,   0)),
	ColorSequenceKeypoint.new(0.167, Color3.fromRGB(255, 255, 0)),
	ColorSequenceKeypoint.new(0.333, Color3.fromRGB(0,   255, 0)),
	ColorSequenceKeypoint.new(0.500, Color3.fromRGB(0,   255, 255)),
	ColorSequenceKeypoint.new(0.667, Color3.fromRGB(0,   0,   255)),
	ColorSequenceKeypoint.new(0.833, Color3.fromRGB(255, 0,   255)),
	ColorSequenceKeypoint.new(1.000, Color3.fromRGB(255, 0,   0)),
})

-- ── Types ─────────────────────────────────────────────────────────────────────

export type ColorPickerProps = {
	name:          string?,
	flag:          string?,
	color:         Color3?,
	alpha:         number?,
	showAlpha:     boolean?,
	overlayParent: Frame?,   -- pass windowFrame to enable window-mode
	overlayYOffset: number?, -- Y px to skip (e.g. TITLEBAR_H + 1). default 0
	callback:      ((value: Color3, alpha: number) -> ())?,
}

export type ColorPicker = {
	value:   Color3,
	alpha:   number,
	_frame:  Frame,
	Set:     (self: ColorPicker, value: Color3, alpha: number?, skipCallback: boolean?) -> (),
	Destroy: (self: ColorPicker) -> (),
}

-- ── Helpers ───────────────────────────────────────────────────────────────────

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

local function relPos(frame: GuiObject, mousePos: Vector2): Vector2
	local ap = frame.AbsolutePosition
	local as = frame.AbsoluteSize
	if as.X <= 0 or as.Y <= 0 then return Vector2.zero end
	return Vector2.new(
		clamp01((mousePos.X - ap.X) / as.X),
		clamp01((mousePos.Y - ap.Y) / as.Y)
	)
end

local function mkCorner(inst: Instance, r: number)
	local c        = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r)
	c.Parent       = inst
end

local function mkStroke(inst: Instance, col: Color3, thick: number): UIStroke
	local sk              = Instance.new("UIStroke")
	sk.Color              = col
	sk.Thickness          = thick
	sk.ApplyStrokeMode    = Enum.ApplyStrokeMode.Border
	sk.Parent             = inst
	return sk
end

-- ── Module ────────────────────────────────────────────────────────────────────

local ColorPicker = {} :: { __index: any }
ColorPicker.__index = ColorPicker

function ColorPicker.new(props: ColorPickerProps, theme: { [string]: any }, parent: Instance): ColorPicker

	local name           = props.name or "ColorPicker"
	local flagKey        = props.flag
	local showAlpha      = props.showAlpha == true
	local callback       = props.callback
	local overlayParent  = (props :: any).overlayParent  :: Frame?
	local overlayYOffset = (props :: any).overlayYOffset :: number? or 0
	local windowMode     = overlayParent ~= nil

	-- In ScreenGui mode the popup sits in its own isolated ScreenGui, so low ZIndex values
	-- are fine. In window mode the popup lives inside windowFrame alongside window chrome,
	-- so every ZIndex must be above constants.zIndex.popup.
	--
	-- POP_Z = the ZIndex of the popup frame itself.
	-- All children of popup are already visually above popup, but in ZIndexBehavior.Sibling
	-- the ZIndex is global to the ScreenGui, so children need explicit higher values too.
	local POP_Z: number = if windowMode then constants.zIndex.popup else 2

	-- ── Initial color ──────────────────────────────────────────────────────
	local initColor: Color3
	local a: number = clamp01(props.alpha or 1)

	if flagKey and flags:Get(flagKey) ~= nil then
		local stored = flags:Get(flagKey)
		initColor = if typeof(stored) == "Color3" then stored :: Color3 else (props.color or Color3.fromRGB(255, 255, 255))
	else
		initColor = props.color or Color3.fromRGB(255, 255, 255)
	end

	local h, s, v = Color3.toHSV(initColor)

	-- ── Popup horizontal layout ────────────────────────────────────────────
	local hueX:   number = PAD + MAP_W + GAP_CH
	local alphaX: number = hueX + HUE_W + GAP_HA
	local rightX: number = if showAlpha then (alphaX + ALPHA_W + GAP_AR) else (hueX + HUE_W + GAP_AR)
	local rightW: number = POPUP_W - rightX - PAD

	local PREVIEW_H: number = MAP_H - HEX_H - GAP_PH
	local hexW:  number     = if showAlpha then (rightW - ABOX_W - ABOX_GAP) else rightW
	local aboxX: number     = rightX + hexW + ABOX_GAP
	local hexY:  number     = CONTENT_Y + PREVIEW_H + GAP_PH

	-- ── Connections & cleanup ──────────────────────────────────────────────
	local conns: { RBXScriptConnection } = {}
	local function addConn(c: RBXScriptConnection)
		table.insert(conns, c)
	end
	local themeUnsub: (() -> ())? = nil

	-- ── Header frame (standard element row) ───────────────────────────────
	local frame, stroke = element.makeFrame("ColorPicker_" .. name, theme, parent)

	local titleLabel = Instance.new("TextLabel")
	titleLabel.AnchorPoint            = Vector2.new(0, 0.5)
	titleLabel.Position               = UDim2.new(0, 12, 0.5, 0)
	titleLabel.Size                   = UDim2.new(1, -(PILL_W + 24), 1, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text                   = name
	titleLabel.TextColor3             = theme.ContentColor or Color3.fromRGB(220, 215, 240)
	titleLabel.TextSize               = 13
	titleLabel.FontFace               = theme.Font or Font.new("rbxasset://fonts/families/GothamSSm.json")
	titleLabel.TextXAlignment         = Enum.TextXAlignment.Left
	titleLabel.TextTruncate           = Enum.TextTruncate.AtEnd
	titleLabel.Parent                 = frame

	local pill = Instance.new("Frame")
	pill.AnchorPoint      = Vector2.new(1, 0.5)
	pill.Position         = UDim2.new(1, -12, 0.5, 0)
	pill.Size             = UDim2.fromOffset(PILL_W, PILL_H)
	pill.BackgroundColor3 = initColor
	pill.BorderSizePixel  = 0
	pill.Parent           = frame
	mkCorner(pill, PILL_R)
	mkStroke(pill, theme.ElementStroke or Color3.fromRGB(50, 42, 80), 1)

	local headerBtn = Instance.new("TextButton")
	headerBtn.Size                   = UDim2.fromScale(1, 1)
	headerBtn.BackgroundTransparency = 1
	headerBtn.Text                   = ""
	headerBtn.AutoButtonColor        = false
	headerBtn.Parent                 = frame

	-- ── ScreenGui (ScreenGui mode only) ───────────────────────────────────
	local gui: ScreenGui? = nil
	local backdrop: TextButton? = nil

	if not windowMode then
		local g = Instance.new("ScreenGui")
		g.Name           = "DeliriumColorPicker_" .. name
		g.DisplayOrder   = constants.displayOrder.popup
		g.ResetOnSpawn   = false
		g.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		g.Enabled        = false
		g.Parent         = runtime.guiContainer
		gui = g

		local bd = Instance.new("TextButton")
		bd.Size                   = UDim2.fromScale(1, 1)
		bd.BackgroundTransparency = 1
		bd.Text                   = ""
		bd.AutoButtonColor        = false
		bd.ZIndex                 = 1
		bd.Parent                 = g
		backdrop = bd
	end

	-- ── Dim overlay (window mode only) ────────────────────────────────────
	-- Covers the body area below the title bar. Active = true consumes mouse events.
	-- Acts as the click-outside target (MouseButton1Click → closePopup).
	local dimOverlay: TextButton? = nil

	if windowMode then
		local ov = Instance.new("TextButton")
		ov.Name                   = "ColorPickerDim"
		ov.Position               = UDim2.fromOffset(0, overlayYOffset)
		ov.Size                   = UDim2.new(1, 0, 1, -overlayYOffset)
		ov.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
		ov.BackgroundTransparency = 0.55
		ov.BorderSizePixel        = 0
		ov.ZIndex                 = constants.zIndex.popup - 1
		ov.Active                 = true
		ov.Text                   = ""
		ov.AutoButtonColor        = false
		ov.Visible                = false
		ov.Parent                 = overlayParent :: Instance
		dimOverlay = ov
	end

	-- ── Popup frame ───────────────────────────────────────────────────────
	-- ScreenGui mode: parented to gui, ZIndex = POP_Z (2).
	-- Window mode:    parented to overlayParent (windowFrame), ZIndex = POP_Z (popup layer).
	local popupParent: Instance = if windowMode then (overlayParent :: Instance) else (gui :: ScreenGui)

	local popup = Instance.new("Frame")
	popup.Name             = "ColorPickerPopup"
	popup.AnchorPoint      = Vector2.new(0.5, 0.5)
	popup.Position         = UDim2.fromScale(0.5, 0.5)
	popup.Size             = UDim2.fromOffset(POPUP_W, POPUP_H)
	popup.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
	popup.BorderSizePixel  = 0
	popup.ZIndex           = POP_Z
	popup.Visible          = windowMode   -- window mode: hidden by default but already parented
	popup.Parent           = popupParent
	mkCorner(popup, 8)
	mkStroke(popup, Color3.fromRGB(48, 48, 56), 1)

	local popScale = Instance.new("UIScale")
	popScale.Scale = 1
	popScale.Parent = popup

	local function adjustScale()
		local winW: number
		local winH: number
		if windowMode and overlayParent then
			winW = overlayParent.AbsoluteSize.X
			winH = overlayParent.AbsoluteSize.Y - overlayYOffset
		else
			local cam = runtime.workspace.CurrentCamera
			local vp = if cam then cam.ViewportSize else Vector2.new(1366, 768)
			winW = vp.X
			winH = vp.Y
		end

		local uis = runtime.userInputService
		local isTouchDevice = uis.TouchEnabled and (not uis.KeyboardEnabled or not uis.MouseEnabled)
		local isSmallScreen = winW < 650 or winH < 420

		local targetScale: number
		if isTouchDevice or isSmallScreen then
			-- On mobile or small screen: scale down so it occupies ~55% of the window
			local fitW = (winW * 0.56) / POPUP_W
			local fitH = (winH * 0.60) / POPUP_H
			targetScale = math.clamp(math.min(fitW, fitH, 0.75), 0.48, 0.75)
		else
			-- On desktop: fit if window is tight, otherwise standard 1.0
			local fitW = (winW - 32) / POPUP_W
			local fitH = (winH - 32) / POPUP_H
			targetScale = math.clamp(math.min(fitW, fitH, 1.0), 0.60, 1.0)
		end

		popScale.Scale = targetScale
	end

	-- ScreenGui mode: hide popup until opened (gui.Enabled handles it, but also set Visible)
	if not windowMode then
		popup.Visible = true   -- visibility managed via gui.Enabled
	else
		popup.Visible = false  -- managed directly
	end

	-- Click absorber inside popup: stops dimOverlay/backdrop from firing for intra-popup clicks
	local popHit = Instance.new("TextButton")
	popHit.Size                   = UDim2.fromScale(1, 1)
	popHit.BackgroundTransparency = 1
	popHit.Text                   = ""
	popHit.AutoButtonColor        = false
	popHit.ZIndex                 = POP_Z
	popHit.Parent                 = popup

	-- ── Popup title & Close button ────────────────────────────────────────
	local popTitle = Instance.new("TextLabel")
	popTitle.Position               = UDim2.fromOffset(PAD, 0)
	popTitle.Size                   = UDim2.new(1, -(PAD * 2 + 28), 0, TITLE_H)
	popTitle.BackgroundTransparency = 1
	popTitle.Text                   = name
	popTitle.TextSize               = 12
	popTitle.FontFace               = theme.Font or Font.new("rbxasset://fonts/families/GothamSSm.json")
	popTitle.TextColor3             = theme.PlaceholderColor or Color3.fromRGB(140, 130, 175)
	popTitle.TextXAlignment         = Enum.TextXAlignment.Left
	popTitle.ZIndex                 = POP_Z + 1
	popTitle.Parent                 = popup

	local popClose = Instance.new("TextButton")
	popClose.Name                   = "Close"
	popClose.AnchorPoint            = Vector2.new(1, 0.5)
	popClose.Position               = UDim2.new(1, -PAD, 0, TITLE_H / 2)
	popClose.Size                   = UDim2.fromOffset(20, 20)
	popClose.BackgroundColor3       = Color3.fromRGB(36, 36, 42)
	popClose.BackgroundTransparency = 0.4
	popClose.Text                   = "✕"
	popClose.TextColor3             = theme.PlaceholderColor or Color3.fromRGB(160, 160, 175)
	popClose.TextSize               = 11
	popClose.FontFace               = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium)
	popClose.AutoButtonColor        = false
	popClose.ZIndex                 = POP_Z + 2
	popClose.Parent                 = popup
	mkCorner(popClose, 4)

	-- ── SV canvas ─────────────────────────────────────────────────────────
	local canvas = Instance.new("Frame")
	canvas.Name             = "Canvas"
	canvas.Position         = UDim2.fromOffset(PAD, CONTENT_Y)
	canvas.Size             = UDim2.fromOffset(MAP_W, MAP_H)
	canvas.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
	canvas.BorderSizePixel  = 0
	canvas.ZIndex           = POP_Z + 1
	canvas.Parent           = popup
	mkCorner(canvas, 4)
	mkStroke(canvas, Color3.fromRGB(48, 48, 56), 1)

	-- Saturation overlay
	local satOvl = Instance.new("Frame")
	satOvl.Size                = UDim2.fromScale(1, 1)
	satOvl.BackgroundColor3    = Color3.new(1, 1, 1)
	satOvl.BorderSizePixel     = 0
	satOvl.ZIndex              = POP_Z + 2
	satOvl.Parent              = canvas
	mkCorner(satOvl, 4)
	do
		local g        = Instance.new("UIGradient")
		g.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(1, 1),
		})
		g.Parent = satOvl
	end

	-- Value overlay
	local valOvl = Instance.new("Frame")
	valOvl.Size                = UDim2.fromScale(1, 1)
	valOvl.BackgroundColor3    = Color3.new(0, 0, 0)
	valOvl.BorderSizePixel     = 0
	valOvl.ZIndex              = POP_Z + 3
	valOvl.Parent              = canvas
	mkCorner(valOvl, 4)
	do
		local g        = Instance.new("UIGradient")
		g.Rotation     = 90
		g.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(1, 0),
		})
		g.Parent = valOvl
	end

	-- SV cursor
	local cursor = Instance.new("Frame")
	cursor.Name             = "SVCursor"
	cursor.AnchorPoint      = Vector2.new(0.5, 0.5)
	cursor.Size             = UDim2.fromOffset(CURSOR_D, CURSOR_D)
	cursor.Position         = UDim2.new(s, 0, 1 - v, 0)
	cursor.BackgroundColor3 = Color3.fromHSV(h, s, v)
	cursor.BorderSizePixel  = 0
	cursor.ZIndex           = POP_Z + 6
	cursor.Parent           = canvas
	mkCorner(cursor, CURSOR_D // 2)
	do
		local cs           = Instance.new("UIStroke")
		cs.Color           = Color3.new(1, 1, 1)
		cs.Thickness       = 2
		cs.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		cs.Parent          = cursor
	end

	-- Canvas hit button (above overlays, below cursor)
	local canvasBtn = Instance.new("TextButton")
	canvasBtn.BackgroundTransparency = 1
	canvasBtn.Size                   = UDim2.fromScale(1, 1)
	canvasBtn.Text                   = ""
	canvasBtn.AutoButtonColor        = false
	canvasBtn.ZIndex                 = POP_Z + 5
	canvasBtn.Parent                 = canvas

	-- ── Hue strip ─────────────────────────────────────────────────────────
	local hueBar = Instance.new("Frame")
	hueBar.Name             = "HueBar"
	hueBar.Position         = UDim2.fromOffset(hueX, CONTENT_Y)
	hueBar.Size             = UDim2.fromOffset(HUE_W, MAP_H)
	hueBar.BackgroundColor3 = Color3.new(1, 1, 1)
	hueBar.BorderSizePixel  = 0
	hueBar.ZIndex           = POP_Z + 1
	hueBar.Parent           = popup
	mkCorner(hueBar, HUE_W // 2)
	do
		local g    = Instance.new("UIGradient")
		g.Color    = HUE_CS
		g.Rotation = 90
		g.Parent   = hueBar
	end

	local hueHandle = Instance.new("Frame")
	hueHandle.AnchorPoint      = Vector2.new(0.5, 0.5)
	hueHandle.Size             = UDim2.fromOffset(HUE_W + 8, HANDLE_H)
	hueHandle.Position         = UDim2.new(0.5, 0, h, 0)
	hueHandle.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
	hueHandle.BorderSizePixel  = 0
	hueHandle.ZIndex           = POP_Z + 3
	hueHandle.Parent           = hueBar
	mkCorner(hueHandle, HANDLE_H // 2)
	do
		local hs           = Instance.new("UIStroke")
		hs.Color           = Color3.new(1, 1, 1)
		hs.Thickness       = 2
		hs.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		hs.Parent          = hueHandle
	end

	local hueBtn = Instance.new("TextButton")
	hueBtn.BackgroundTransparency = 1
	hueBtn.AnchorPoint            = Vector2.new(0.5, 0.5)
	hueBtn.Position               = UDim2.fromScale(0.5, 0.5)
	hueBtn.Size                   = UDim2.new(1, 18, 1, 10)
	hueBtn.Text                   = ""
	hueBtn.AutoButtonColor        = false
	hueBtn.ZIndex                 = POP_Z + 4
	hueBtn.Parent                 = hueBar

	-- ── Alpha strip (optional) ────────────────────────────────────────────
	local alphaBar:    Frame?      = nil
	local alphaHandle: Frame?      = nil
	local alphaBtn:    TextButton? = nil

	if showAlpha then
		local bar = Instance.new("Frame")
		bar.Name             = "AlphaBar"
		bar.Position         = UDim2.fromOffset(alphaX, CONTENT_Y)
		bar.Size             = UDim2.fromOffset(ALPHA_W, MAP_H)
		bar.BackgroundColor3 = Color3.fromHSV(h, s, v)
		bar.BorderSizePixel  = 0
		bar.ZIndex           = POP_Z + 1
		bar.Parent           = popup
		mkCorner(bar, ALPHA_W // 2)
		do
			local ag        = Instance.new("UIGradient")
			ag.Rotation     = 90
			ag.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0),
				NumberSequenceKeypoint.new(1, 1),
			})
			ag.Parent = bar
		end

		local handle = Instance.new("Frame")
		handle.AnchorPoint      = Vector2.new(0.5, 0.5)
		handle.Size             = UDim2.fromOffset(ALPHA_W + 8, HANDLE_H)
		handle.Position         = UDim2.new(0.5, 0, 1 - a, 0)
		handle.BackgroundColor3 = Color3.fromHSV(h, s, v)
		handle.BorderSizePixel  = 0
		handle.ZIndex           = POP_Z + 3
		handle.Parent           = bar
		mkCorner(handle, HANDLE_H // 2)
		do
			local as_           = Instance.new("UIStroke")
			as_.Color           = Color3.new(1, 1, 1)
			as_.Thickness       = 2
			as_.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			as_.Parent          = handle
		end

		local abtn = Instance.new("TextButton")
		abtn.BackgroundTransparency = 1
		abtn.AnchorPoint            = Vector2.new(0.5, 0.5)
		abtn.Position               = UDim2.fromScale(0.5, 0.5)
		abtn.Size                   = UDim2.new(1, 18, 1, 10)
		abtn.Text                   = ""
		abtn.AutoButtonColor        = false
		abtn.ZIndex                 = POP_Z + 4
		abtn.Parent                 = bar

		alphaBar    = bar
		alphaHandle = handle
		alphaBtn    = abtn
	end

	-- ── Preview swatch ────────────────────────────────────────────────────
	local swatch = Instance.new("Frame")
	swatch.Name             = "Swatch"
	swatch.Position         = UDim2.fromOffset(rightX, CONTENT_Y)
	swatch.Size             = UDim2.fromOffset(rightW, PREVIEW_H)
	swatch.BackgroundColor3 = Color3.fromHSV(h, s, v)
	swatch.BorderSizePixel  = 0
	swatch.ZIndex           = POP_Z + 1
	swatch.Parent           = popup
	mkCorner(swatch, 4)
	mkStroke(swatch, Color3.fromRGB(48, 48, 56), 1)

	-- ── Hex input ─────────────────────────────────────────────────────────
	local hexFrame = Instance.new("Frame")
	hexFrame.Position         = UDim2.fromOffset(rightX, hexY)
	hexFrame.Size             = UDim2.fromOffset(hexW, HEX_H)
	hexFrame.BackgroundColor3 = Color3.fromRGB(32, 32, 36)
	hexFrame.BorderSizePixel  = 0
	hexFrame.ZIndex           = POP_Z + 1
	hexFrame.Parent           = popup
	mkCorner(hexFrame, 4)
	mkStroke(hexFrame, Color3.fromRGB(48, 48, 56), 1)

	local hexInput = Instance.new("TextBox")
	hexInput.AnchorPoint            = Vector2.new(0.5, 0.5)
	hexInput.Position               = UDim2.fromScale(0.5, 0.5)
	hexInput.Size                   = UDim2.new(1, -8, 1, 0)
	hexInput.BackgroundTransparency = 1
	hexInput.Text                   = colorToHex(initColor)
	hexInput.PlaceholderText        = "#RRGGBB"
	hexInput.TextSize               = 11
	hexInput.FontFace               = Font.new("rbxasset://fonts/families/RobotoMono.json")
	hexInput.TextColor3             = theme.ContentColor or Color3.fromRGB(220, 215, 240)
	hexInput.PlaceholderColor3      = theme.PlaceholderColor or Color3.fromRGB(140, 130, 175)
	hexInput.ClearTextOnFocus       = false
	hexInput.TextXAlignment         = Enum.TextXAlignment.Center
	hexInput.ZIndex                 = POP_Z + 2
	hexInput.Parent                 = hexFrame

	-- ── Alpha% input (optional) ───────────────────────────────────────────
	local alphaInput: TextBox? = nil

	if showAlpha then
		local af = Instance.new("Frame")
		af.Position         = UDim2.fromOffset(aboxX, hexY)
		af.Size             = UDim2.fromOffset(ABOX_W, HEX_H)
		af.BackgroundColor3 = Color3.fromRGB(32, 32, 36)
		af.BorderSizePixel  = 0
		af.ZIndex           = POP_Z + 1
		af.Parent           = popup
		mkCorner(af, 4)
		mkStroke(af, Color3.fromRGB(48, 48, 56), 1)

		local ai = Instance.new("TextBox")
		ai.AnchorPoint            = Vector2.new(0.5, 0.5)
		ai.Position               = UDim2.fromScale(0.5, 0.5)
		ai.Size                   = UDim2.new(1, -6, 1, 0)
		ai.BackgroundTransparency = 1
		ai.Text                   = tostring(math.round(a * 100)) .. "%"
		ai.PlaceholderText        = "100%"
		ai.TextSize               = 11
		ai.FontFace               = Font.new("rbxasset://fonts/families/RobotoMono.json")
		ai.TextColor3             = theme.ContentColor or Color3.fromRGB(220, 215, 240)
		ai.PlaceholderColor3      = theme.PlaceholderColor or Color3.fromRGB(140, 130, 175)
		ai.ClearTextOnFocus       = false
		ai.TextXAlignment         = Enum.TextXAlignment.Center
		ai.ZIndex                 = POP_Z + 2
		ai.Parent                 = af

		alphaInput = ai
	end

	-- ── Drag state ────────────────────────────────────────────────────────
	type DragTarget = "canvas" | "hue" | "alpha"
	local dragging: DragTarget? = nil

	-- ── Refresh — instant, no tweens ──────────────────────────────────────
	local function refresh()
		local color = Color3.fromHSV(h, s, v)
		local pure  = Color3.fromHSV(h, 1, 1)

		canvas.BackgroundColor3    = pure
		cursor.Position            = UDim2.new(s, 0, 1 - v, 0)
		cursor.BackgroundColor3    = color
		hueHandle.Position         = UDim2.new(0.5, 0, h, 0)
		hueHandle.BackgroundColor3 = pure
		pill.BackgroundColor3      = color
		swatch.BackgroundColor3    = color

		if showAlpha and alphaBar and alphaHandle then
			alphaBar.BackgroundColor3    = color
			alphaHandle.Position         = UDim2.new(0.5, 0, 1 - a, 0)
			alphaHandle.BackgroundColor3 = color
		end

		if not hexInput:IsFocused() then
			hexInput.Text = colorToHex(color)
		end
		if showAlpha and alphaInput and not alphaInput:IsFocused() then
			alphaInput.Text = tostring(math.round(a * 100)) .. "%"
		end
	end

	local function fireChanged()
		local color = Color3.fromHSV(h, s, v)
		if flagKey then flags:Set(flagKey, color) end
		if callback then task.spawn(callback, color, a) end
	end

	-- ── Drag pump ──────────────────────────────────────────────────────────
	local function pump(mousePos: Vector2)
		if dragging == "canvas" then
			local p = relPos(canvas, mousePos)
			s = p.X
			v = 1 - p.Y
		elseif dragging == "hue" then
			h = relPos(hueBar, mousePos).Y
		elseif dragging == "alpha" and alphaBar then
			a = 1 - relPos(alphaBar :: Frame, mousePos).Y
		end
		refresh()
		fireChanged()
	end

	-- ── Open / close ──────────────────────────────────────────────────────
	local isOpen = false

	local function openPopup()
		if isOpen then return end
		isOpen       = true
		adjustScale()
		stroke.Color = theme.AccentColor or Color3.fromHex("#4cc2ff")
		if windowMode then
			popup.Visible = true
			if dimOverlay then dimOverlay.Visible = true end
		else
			(gui :: ScreenGui).Enabled = true
		end
		refresh()
	end

	if windowMode and overlayParent then
		addConn((overlayParent :: Frame):GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
			if isOpen then adjustScale() end
		end))
	else
		local cam = runtime.workspace.CurrentCamera
		if cam then
			addConn(cam:GetPropertyChangedSignal("ViewportSize"):Connect(function()
				if isOpen then adjustScale() end
			end))
		end
	end

	local function closePopup()
		if not isOpen then return end
		isOpen       = false
		dragging     = nil
		stroke.Color = theme.ElementStroke or Color3.fromHex("#2b2b2b")
		if windowMode then
			popup.Visible = false
			if dimOverlay then dimOverlay.Visible = false end
		else
			(gui :: ScreenGui).Enabled = false
		end
	end

	-- Header toggle
	addConn(headerBtn.MouseButton1Click:Connect(function()
		if isOpen then closePopup() else openPopup() end
	end))

	-- Backdrop / dim click → close
	if not windowMode and backdrop then
		addConn((backdrop :: TextButton).MouseButton1Click:Connect(closePopup))
	end
	if windowMode and dimOverlay then
		addConn((dimOverlay :: TextButton).MouseButton1Click:Connect(closePopup))
	end
	addConn(popClose.MouseButton1Click:Connect(closePopup))

	-- Header hover (stroke color hint only)
	addConn(headerBtn.MouseEnter:Connect(function()
		if not isOpen then
			stroke.Color = theme.ElementStrokeHover or theme.AccentColor or Color3.fromHex("#4cc2ff")
		end
	end))
	addConn(headerBtn.MouseLeave:Connect(function()
		if not isOpen then
			stroke.Color = theme.ElementStroke or Color3.fromHex("#2b2b2b")
		end
	end))

	-- ── Drag input bindings ───────────────────────────────────────────────
	addConn(canvasBtn.InputBegan:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = "canvas"
			pump(Vector2.new(input.Position.X, input.Position.Y))
		end
	end))

	addConn(hueBtn.InputBegan:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = "hue"
			pump(Vector2.new(input.Position.X, input.Position.Y))
		end
	end))

	if showAlpha and alphaBtn then
		local abtn = alphaBtn :: TextButton
		addConn(abtn.InputBegan:Connect(function(input: InputObject)
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch then
				dragging = "alpha"
				pump(Vector2.new(input.Position.X, input.Position.Y))
			end
		end))
	end

	addConn(runtime.userInputService.InputChanged:Connect(function(input: InputObject)
		if not dragging then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch then
			pump(Vector2.new(input.Position.X, input.Position.Y))
		end
	end))

	addConn(runtime.userInputService.InputEnded:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = nil
		end
	end))

	-- ── Hex / Alpha% text inputs ──────────────────────────────────────────
	addConn(hexInput.FocusLost:Connect(function()
		local color = hexToColor(hexInput.Text)
		if not color then
			hexInput.Text = colorToHex(Color3.fromHSV(h, s, v))
			return
		end
		h, s, v = Color3.toHSV(color)
		refresh()
		fireChanged()
	end))

	if showAlpha and alphaInput then
		local ai = alphaInput :: TextBox
		addConn(ai.FocusLost:Connect(function()
			local n = tonumber((ai.Text:gsub("[^%d%.]", "")))
			if n then
				a = clamp01(n / 100)
				refresh()
				fireChanged()
			else
				ai.Text = tostring(math.round(a * 100)) .. "%"
			end
		end))
	end

	-- ── Theme subscription ────────────────────────────────────────────────
	themeUnsub = themeUtil.subscribe(function(t)
		theme = t
		frame.BackgroundTransparency = t.ElementTransparency or 0
		local fGrad = frame:FindFirstChildOfClass("UIGradient")
		if fGrad then
			fGrad.Color = t.ElementGradient or ColorSequence.new(Color3.fromRGB(28, 24, 44))
		end
		stroke.Transparency = t.ElementStrokeTransparency or 0
		stroke.Color = if isOpen
			then (t.ElementStrokeHover or t.AccentColor or Color3.fromHex("#4cc2ff"))
			else (t.ElementStroke or Color3.fromHex("#2b2b2b"))

		titleLabel.TextColor3      = t.ContentColor or Color3.fromHex("#ffffff")
		titleLabel.FontFace        = t.Font or constants.DEFAULT_FONT
		popTitle.TextColor3        = t.PlaceholderColor or Color3.fromHex("#9d9d9d")
		popTitle.FontFace          = t.Font or constants.DEFAULT_FONT
		hexInput.TextColor3        = t.ContentColor or Color3.fromHex("#ffffff")
		hexInput.PlaceholderColor3 = t.PlaceholderColor or Color3.fromHex("#9d9d9d")
		if alphaInput then
			alphaInput.TextColor3        = t.ContentColor or Color3.fromHex("#ffffff")
			alphaInput.PlaceholderColor3 = t.PlaceholderColor or Color3.fromHex("#9d9d9d")
		end
	end)

	-- ── Public API ────────────────────────────────────────────────────────
	local self = setmetatable({}, ColorPicker) :: ColorPicker
	self.value  = initColor
	self.alpha  = a
	self._frame = frame
	;(self :: any)._flag = flagKey
	if flagKey and flagKey ~= "" then
		flags:Set(flagKey, initColor)
	end

	function self:Set(value: Color3, newAlpha: number?, skipCallback: boolean?)
		h, s, v    = Color3.toHSV(value)
		if newAlpha ~= nil then a = clamp01(newAlpha) end
		self.value = value
		self.alpha = a
		refresh()
		if not skipCallback then fireChanged() end
	end

	function self:Destroy()
		if themeUnsub then themeUnsub() end
		for _, c in conns do c:Disconnect() end
		table.clear(conns)
		-- In window mode the popup + dim are parented to windowFrame, destroy them individually.
		-- In ScreenGui mode the whole gui is destroyed, which takes popup with it.
		if windowMode then
			popup:Destroy()
			if dimOverlay then dimOverlay:Destroy() end
		else
			if gui then (gui :: ScreenGui):Destroy() end
		end
		frame:Destroy()
	end

	refresh()
	return self
end

return ColorPicker
