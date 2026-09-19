--!strict

-- Delirium UI Library
-- window.luau — Root window component.
-- Handles: ScreenGui creation, drag (clamped, RenderStepped), viewport-reactive sizing,
-- minimize/close/keybind toggle, tab sidebar, notification routing, and theme application.
--
-- Sizing / clamping ported from Rayfield Gen2.

local constants    = require(script.Parent.Parent.utility.constants)
local element      = require(script.Parent.Parent.utility.element)
local variables    = require(script.Parent.Parent.utility.variables)
local tween        = require(script.Parent.Parent.utility.tween)
local themeUtil    = require(script.Parent.Parent.utility.theme)
local windowSizing = require(script.Parent.Parent.utility.windowSizing)
local notification  = require(script.Parent.notification)
local PlayerCard    = require(script.Parent.dashboard)
local Tab          = require(script.Parent.tab)
local icons        = require(script.Parent.Parent.utility.icons)
local ColorPicker  = require(script.Parent.colorpicker)
local Dropdown     = require(script.Parent.dropdown)
local Keybind      = require(script.Parent.keybind)

local ICON_SETTINGS = "rbxassetid://129180860773723" -- Unified vector settings
local ICON_MINIMIZE = "rbxassetid://108115485663409" -- Unified vector minimize
local ICON_RESTORE  = "rbxassetid://88738500661569"  -- Unified vector restore / maximize
local ICON_CLOSE    = "rbxassetid://83277910885129"  -- Unified vector close

export type WindowProps = {
	name:         string?,
	subtitle:     string?,
	theme:        (string | { [string]: any })?,
	keybind:      (EnumItem | string)?,   -- toggle key (default RightShift)
	keepOnScreen: boolean?,               -- clamp drag so window can't be pulled off screen (default true)
}

export type Window = {
	unloaded: boolean,
	_gui:     ScreenGui,

	CreateTab:   (self: Window, props: Tab.TabProps) -> Tab.Tab,
	Notify:      (self: Window, props: notification.NotifyProps) -> (),
	Show:        (self: Window) -> (),
	Hide:        (self: Window) -> (),
	ToggleHide:     (self: Window) -> (),
	ToggleMinimise: (self: Window) -> (),
	ChangeTheme: (self: Window, newTheme: string | { [string]: any }) -> (),
	Unload:      (self: Window) -> (),
}

local Window = {}
Window.__index = Window

-- Resolve toggle keybind (default RightShift)
local function resolveKeybind(v: (EnumItem | string)?): EnumItem
	if typeof(v) == "EnumItem" then return v :: EnumItem end
	if typeof(v) == "string" then
		local ok, item = pcall(function() return Enum.KeyCode[v :: string] end)
		if ok and item then return item :: EnumItem end
	end
	return Enum.KeyCode.RightShift
end

-- Initial size from the current camera viewport (safe to call before layout exists).
local function fitWindowSize(): UDim2
	local cam = workspace.CurrentCamera
	return windowSizing.fit(cam and cam.ViewportSize)
end

-- ── Window.new ────────────────────────────────────────────────────────────────

function Window.new(props: WindowProps): Window
	local windowName = props.name or "Delirium"
	local subtitle   = props.subtitle or ""
	local toggleKey  = resolveKeybind(props.keybind)
	local keepOnScreen = if props.keepOnScreen ~= nil then props.keepOnScreen else true

	-- Resolve theme
	local resolvedTheme = themeUtil.resolve(props.theme)
	variables.activeTheme = resolvedTheme

	-- ── Design tokens ─────────────────────────────────────────────────────
	local colorSurface       = resolvedTheme.WindowColor.Keypoints[1].Value
	local colorTitleBar      = resolvedTheme.TitleBarColor   or Color3.fromHex("#111114")
	local colorBorder        = resolvedTheme.SurfaceStroke   or Color3.fromHex("#2b2b2b")
	local colorSurfaceHover  = resolvedTheme.NeutralButton   or Color3.fromHex("#252525")
	local colorAccent        = resolvedTheme.AccentColor     or Color3.fromHex("#4cc2ff")
	local colorError         = resolvedTheme.ErrorColor      or Color3.fromHex("#ff4f58")
	local colorTextPrimary   = resolvedTheme.TitlingColor    or Color3.fromHex("#ffffff")
	local colorTextSecondary = resolvedTheme.PlaceholderColor or Color3.fromHex("#8a8a92")

	-- ── ScreenGui ────────────────────────────────────────────────────────
	local gui = Instance.new("ScreenGui")
	gui.Name                   = variables.httpService:GenerateGUID(false)
	gui.DisplayOrder           = constants.displayOrder.window
	gui.IgnoreGuiInset         = true
	gui.ResetOnSpawn           = false
	gui.ZIndexBehavior         = Enum.ZIndexBehavior.Sibling
	gui.ClipToDeviceSafeArea   = false
	gui.Parent                 = variables.guiContainer

	-- ── Initial window size (viewport-fitted) ─────────────────────────────
	local initialSize = fitWindowSize()
	local W = initialSize.X.Offset
	local H = initialSize.Y.Offset

	local cam = variables.workspace.CurrentCamera
	local vp  = if cam then cam.ViewportSize else Vector2.new(1920, 1080)
	local initX = math.floor(vp.X / 2)
	local initY = math.floor(vp.Y / 2)

	-- ── Main window frame ─────────────────────────────────────────────────
	local windowFrame = Instance.new("Frame")
	windowFrame.Name                   = "Window"
	windowFrame.AnchorPoint            = Vector2.new(0.5, 0.5)
	windowFrame.Position               = UDim2.fromOffset(initX, initY)
	windowFrame.Size                   = UDim2.fromOffset(W, H)
	windowFrame.BackgroundColor3       = Color3.fromRGB(255, 255, 255)
	-- Start transparent so UICorner has time to clip before the frame is opaque.
	-- Show() tweens this to 0; avoids the one-frame square-corner flash on open.
	windowFrame.BackgroundTransparency = 1
	windowFrame.BorderSizePixel        = 0
	windowFrame.ClipsDescendants       = true   -- UICorner clips children to rounded shape
	windowFrame.Parent                 = gui

	local winScale = Instance.new("UIScale")
	-- M1 FIX: initial scale applied below after isTouchOnly is computed (see userScale).
	-- Assigned here as 1.0 placeholder; overwritten by the self init block.
	winScale.Scale = 1.0
	winScale.Parent = windowFrame

	local winCorner = Instance.new("UICorner")
	winCorner.CornerRadius = resolvedTheme.CornerRoundness or UDim.new(0, 10)
	winCorner.Parent       = windowFrame

	local winGradient = Instance.new("UIGradient")
	winGradient.Color    = resolvedTheme.WindowColor
	winGradient.Rotation = 90
	winGradient.Parent   = windowFrame

	local winStroke = Instance.new("UIStroke")
	winStroke.Color           = colorBorder
	winStroke.Thickness       = 1
	winStroke.Transparency    = 0.3
	winStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	winStroke.Parent          = windowFrame

-- ── Title bar ─────────────────────────────────────────────────────────
	local TITLEBAR_H = 44

	local titleBar = Instance.new("Frame")
	titleBar.Name                   = "TitleBar"
	titleBar.Size                   = UDim2.new(1, 0, 0, TITLEBAR_H)
	titleBar.BackgroundTransparency = 1   -- bg drawn by titleBarBg child
	titleBar.BorderSizePixel        = 0
	titleBar.ZIndex                 = constants.zIndex.windowChrome
	titleBar.Parent                 = windowFrame

	-- Colored bg child with UICorner matching windowFrame so top corners are always cleanly rounded.
	-- Bottom corners are flattened while open using cornerCover, and rounded when minimized.
	local titleBarBg = Instance.new("Frame")
	titleBarBg.Name             = "Background"
	titleBarBg.Size             = UDim2.fromScale(1, 1)
	titleBarBg.BackgroundColor3 = colorTitleBar
	titleBarBg.BorderSizePixel  = 0
	titleBarBg.ZIndex           = constants.zIndex.windowChrome - 1
	titleBarBg.Parent           = titleBar

	local titleBarCorner = Instance.new("UICorner")
	titleBarCorner.CornerRadius = resolvedTheme.CornerRoundness or UDim.new(0, 8)
	titleBarCorner.Parent       = titleBarBg

	local cornerRadiusPx = (resolvedTheme.CornerRoundness or UDim.new(0, 8)).Offset
	local cornerCover = Instance.new("Frame")
	cornerCover.Name             = "CornerCover"
	cornerCover.Size             = UDim2.new(1, 0, 0, cornerRadiusPx)
	cornerCover.Position         = UDim2.new(0, 0, 1, -cornerRadiusPx)
	cornerCover.BackgroundColor3 = colorTitleBar
	cornerCover.BorderSizePixel  = 0
	cornerCover.ZIndex           = constants.zIndex.windowChrome - 1
	cornerCover.Parent           = titleBarBg


	-- Separator: garis tipis 1px di bawah titlebar
	local titleSep = Instance.new("Frame")
	titleSep.Name                   = "Separator"
	titleSep.Size                   = UDim2.new(1, 0, 0, 1)
	titleSep.Position               = UDim2.new(0, 0, 1, -1)
	titleSep.BackgroundColor3       = colorBorder
	titleSep.BackgroundTransparency = 0.5
	titleSep.BorderSizePixel        = 0
	titleSep.ZIndex                 = constants.zIndex.windowChrome + 1
	titleSep.Parent                 = titleBar

	local ACCENT_SIDE_PAD = 10
	local accentStrip = Instance.new("Frame")
	accentStrip.Name             = "AccentStrip"
	accentStrip.Size             = UDim2.new(1, -ACCENT_SIDE_PAD * 2, 0, 2)
	accentStrip.Position         = UDim2.fromOffset(ACCENT_SIDE_PAD, 0)
	accentStrip.BackgroundColor3 = colorAccent
	accentStrip.BorderSizePixel  = 0
	accentStrip.ZIndex           = constants.zIndex.windowChrome + 2
	accentStrip.Parent           = windowFrame         -- ← pindah dari titleBar
	do
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(1, 0)
		c.Parent       = accentStrip
	end
	local accentStripGrad = Instance.new("UIGradient")
	accentStripGrad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0.00, 1),
		NumberSequenceKeypoint.new(0.12, 0),
		NumberSequenceKeypoint.new(0.88, 0),
		NumberSequenceKeypoint.new(1.00, 1),
	})
	accentStripGrad.Parent = accentStrip


-- Logo mark: geser ke kiri biar masuk area merah di pojok
	local logoMark = Instance.new("Frame")
	logoMark.Name             = "LogoMark"
	logoMark.AnchorPoint      = Vector2.new(0, 0.5)
	logoMark.Position         = UDim2.new(0, 12, 0.5, 0)
	logoMark.Size             = UDim2.fromOffset(26, 26)
	logoMark.BackgroundColor3 = colorAccent
	logoMark.BorderSizePixel  = 0
	logoMark.ZIndex           = constants.zIndex.windowChrome + 1
	logoMark.Parent           = titleBar
	do
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, 6)
		c.Parent       = logoMark
	end
	do
		local g = Instance.new("UIGradient")
		g.Color    = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(0, 0, 0))
		g.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.7),
			NumberSequenceKeypoint.new(1, 0.95),
		})
		g.Rotation = 135
		g.Parent   = logoMark
	end
	local logoInitial = Instance.new("TextLabel")
	logoInitial.Name                   = "Initial"
	logoInitial.Size                   = UDim2.fromScale(1, 1)
	logoInitial.BackgroundTransparency = 1
	logoInitial.Text                   = string.sub(windowName, 1, 1):upper()
	logoInitial.TextColor3             = Color3.fromRGB(255, 255, 255)
	logoInitial.TextSize               = 12
	logoInitial.FontFace               = resolvedTheme.TitleFont
		or Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold)
	logoInitial.TextXAlignment         = Enum.TextXAlignment.Center
	logoInitial.ZIndex                 = constants.zIndex.windowChrome + 2
	logoInitial.Parent                 = logoMark

	local TEXT_LEFT          = 48
	local TEXT_RIGHT_RESERVE = 110

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name                   = "Name"
	nameLabel.AnchorPoint            = Vector2.new(0, 0.5)
	nameLabel.Position               = UDim2.new(0, TEXT_LEFT, 0.5, 0)
	nameLabel.Size                   = UDim2.new(1, -TEXT_LEFT - TEXT_RIGHT_RESERVE, 0, 18)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text                   = windowName
	nameLabel.TextColor3             = colorTextPrimary
	nameLabel.TextSize               = 15
	nameLabel.FontFace               = resolvedTheme.TitleFont
		or Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold)
	nameLabel.TextXAlignment         = Enum.TextXAlignment.Left
	nameLabel.ZIndex                 = constants.zIndex.windowChrome + 1  -- above titleBarBg (windowChrome-1 = 499)
	nameLabel.Parent                 = titleBar

	local subtitleLabel: TextLabel? = nil
	if subtitle ~= "" then
		nameLabel.Position = UDim2.new(0, TEXT_LEFT, 0.5, -9)
		subtitleLabel = Instance.new("TextLabel")
		subtitleLabel.Name                   = "Subtitle"
		subtitleLabel.AnchorPoint            = Vector2.new(0, 0)
		subtitleLabel.Position               = UDim2.new(0, TEXT_LEFT, 0.5, 3)
		subtitleLabel.Size                   = UDim2.new(1, -TEXT_LEFT - TEXT_RIGHT_RESERVE, 0, 12)
		subtitleLabel.BackgroundTransparency = 1
		subtitleLabel.Text                   = subtitle
		subtitleLabel.TextColor3             = colorTextSecondary
		subtitleLabel.TextSize               = 11
		subtitleLabel.FontFace               = resolvedTheme.Font
			or Font.new("rbxasset://fonts/families/GothamSSm.json")
		subtitleLabel.TextXAlignment         = Enum.TextXAlignment.Left
		subtitleLabel.ZIndex                 = constants.zIndex.windowChrome + 1
		subtitleLabel.Parent                 = titleBar
	end

	-- ── Title bar controls (right-anchored pill buttons) ──────────────────
	local controlsFrame = Instance.new("Frame")
	controlsFrame.Name                   = "Controls"
	controlsFrame.AnchorPoint            = Vector2.new(1, 0.5)
	controlsFrame.Position               = UDim2.new(1, -12, 0.5, 0)
	controlsFrame.Size                   = UDim2.fromOffset(96, 28)
	controlsFrame.BackgroundTransparency = 1
	controlsFrame.ZIndex                 = constants.zIndex.windowChrome + 1
	controlsFrame.Parent                 = titleBar

	local controlsLayout = Instance.new("UIListLayout")
	controlsLayout.FillDirection       = Enum.FillDirection.Horizontal
	controlsLayout.VerticalAlignment   = Enum.VerticalAlignment.Center
	controlsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	controlsLayout.Padding             = UDim.new(0, 4)
	controlsLayout.SortOrder           = Enum.SortOrder.LayoutOrder
	controlsLayout.Parent              = controlsFrame


	local function makeTitleBtn(name: string, iconAsset: string, order: number): (TextButton, ImageLabel)
		local b = Instance.new("TextButton")
		b.Name                   = name
		b.Size                   = UDim2.fromOffset(26, 26)
		b.BackgroundColor3       = colorSurfaceHover
		b.BackgroundTransparency = 0
		b.Text                   = ""
		b.AutoButtonColor        = false
		b.ZIndex                 = constants.zIndex.windowChrome + 2
		b.LayoutOrder            = order
		b.Parent                 = controlsFrame

		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(1, 0)
		c.Parent       = b

		do
			local sk = Instance.new("UIStroke")
			sk.Color           = resolvedTheme.NeutralButtonStroke or Color3.fromHex("#2b2b2b")
			sk.Thickness       = 1
			sk.Transparency    = 0
			sk.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			sk.Parent          = b
		end

		local iconImg = Instance.new("ImageLabel")
		iconImg.Name                   = "Icon"
		iconImg.AnchorPoint            = Vector2.new(0.5, 0.5)
		iconImg.Position               = UDim2.fromScale(0.5, 0.5)
		iconImg.Size                   = UDim2.fromOffset(16, 16)
		iconImg.BackgroundTransparency = 1
		iconImg.Image                  = iconAsset
		iconImg.ImageColor3            = colorTextSecondary
		iconImg.ZIndex                 = constants.zIndex.windowChrome + 3
		iconImg.Parent                 = b

		return b, iconImg
	end

	local settingsBtn, settingsIcon = makeTitleBtn("Settings", ICON_SETTINGS, 1)
	local minBtn, minIcon           = makeTitleBtn("Minimize", ICON_MINIMIZE, 2)
	local closeBtn, closeIcon       = makeTitleBtn("Close",    ICON_CLOSE,    3)

	closeBtn.MouseEnter:Connect(function()
		closeBtn.BackgroundColor3 = colorError
		closeIcon.ImageColor3     = Color3.fromRGB(255, 255, 255)
	end)
	closeBtn.MouseLeave:Connect(function()
		closeBtn.BackgroundColor3 = colorSurfaceHover
		closeIcon.ImageColor3     = colorTextSecondary
	end)

	local function genericHover(btn: TextButton, icon: ImageLabel)
		btn.MouseEnter:Connect(function()
			btn.BackgroundColor3 = resolvedTheme.NeutralButtonHover or Color3.fromHex("#2e2e2e")
			icon.ImageColor3     = colorTextPrimary
		end)
		btn.MouseLeave:Connect(function()
			btn.BackgroundColor3 = colorSurfaceHover
			icon.ImageColor3     = colorTextSecondary
		end)
	end

	genericHover(minBtn, minIcon)
	genericHover(settingsBtn, settingsIcon)

	-- ── Body layout ───────────────────────────────────────────────────────
	local body = Instance.new("Frame")
	body.Name                   = "Body"
	body.Position               = UDim2.fromOffset(0, TITLEBAR_H)
	body.Size                   = UDim2.new(1, 0, 1, -TITLEBAR_H)
	body.BackgroundTransparency = 1
	body.ClipsDescendants       = true
	body.Parent                 = windowFrame

	-- Input blocker: lives inside body at max ZIndex so it's in the same
	-- stacking context as sidebar tabs and all elements.
	-- When the settings panel opens, this catches every click/drag/scroll
	-- aimed at the body — buttons, sliders, dropdowns, scroll frames, all of it.
	-- The dim visual is handled separately by spOverlay.
	local bodyBlocker = Instance.new("TextButton")
	bodyBlocker.Name                   = "BodyBlocker"
	bodyBlocker.Size                   = UDim2.fromScale(1, 1)
	bodyBlocker.Position               = UDim2.fromScale(0, 0)
	bodyBlocker.BackgroundTransparency = 1
	bodyBlocker.Text                   = ""
	bodyBlocker.AutoButtonColor        = false
	bodyBlocker.ZIndex                 = 32767
	bodyBlocker.Visible                = false
	bodyBlocker.Parent                 = body

	local sidebar = Instance.new("Frame")
	sidebar.Name             = "Sidebar"
	sidebar.Size             = UDim2.new(0, constants.sidebarWidth, 1, 0)
	sidebar.BackgroundColor3 = colorTitleBar
	sidebar.BorderSizePixel  = 0
	sidebar.ClipsDescendants = true
	sidebar.Parent           = body

	local sidebarCorner = Instance.new("UICorner")
	sidebarCorner.CornerRadius = UDim.new(0, 0)
	sidebarCorner.Parent       = sidebar

	local sidebarHeader = Instance.new("TextLabel")
	sidebarHeader.Name                   = "SidebarHeader"
	sidebarHeader.Size                   = UDim2.new(1, -20, 0, 16)
	sidebarHeader.Position               = UDim2.fromOffset(12, 10)
	sidebarHeader.BackgroundTransparency = 1
	sidebarHeader.Text                   = "PAGES"
	sidebarHeader.TextColor3             = colorTextSecondary
	sidebarHeader.TextTransparency       = 0.45
	sidebarHeader.TextSize               = 10
	sidebarHeader.FontFace               = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold)
	sidebarHeader.TextXAlignment         = Enum.TextXAlignment.Left
	sidebarHeader.Parent                 = sidebar

	local PLAYER_CARD_H = 64   -- reserved height at sidebar bottom for PlayerCard

	local tabListScroll = Instance.new("ScrollingFrame")
	tabListScroll.Name                    = "TabList"
	tabListScroll.Position                = UDim2.fromOffset(0, 30)
	tabListScroll.Size                    = UDim2.new(1, 0, 1, -(32 + PLAYER_CARD_H))
	tabListScroll.BackgroundTransparency  = 1
	tabListScroll.BorderSizePixel         = 0
	tabListScroll.ScrollBarThickness      = 2
	tabListScroll.ScrollBarImageColor3    = colorBorder
	tabListScroll.ScrollBarImageTransparency = 0.6
	tabListScroll.CanvasSize              = UDim2.new(0, 0, 0, 0)
	tabListScroll.AutomaticCanvasSize     = Enum.AutomaticSize.Y
	tabListScroll.ClipsDescendants        = true
	tabListScroll.Parent                  = sidebar

	local sidebarLayout = Instance.new("UIListLayout")
	sidebarLayout.FillDirection     = Enum.FillDirection.Vertical
	sidebarLayout.VerticalAlignment = Enum.VerticalAlignment.Top
	sidebarLayout.Padding           = UDim.new(0, 4)
	sidebarLayout.SortOrder         = Enum.SortOrder.LayoutOrder
	sidebarLayout.Parent            = tabListScroll

	local sidebarPad = Instance.new("UIPadding")
	sidebarPad.PaddingLeft   = UDim.new(0, 8)
	sidebarPad.PaddingRight  = UDim.new(0, 8)
	sidebarPad.PaddingTop    = UDim.new(0, 2)
	sidebarPad.PaddingBottom = UDim.new(0, 8)
	sidebarPad.Parent        = tabListScroll

	-- Slot at the bottom of the sidebar for the PlayerCard widget
	local playerCardSlot = Instance.new("Frame")
	playerCardSlot.Name             = "PlayerCardSlot"
	playerCardSlot.AnchorPoint      = Vector2.new(0, 1)
	playerCardSlot.Position         = UDim2.fromScale(0, 1)
	playerCardSlot.Size             = UDim2.new(1, 0, 0, PLAYER_CARD_H)
	playerCardSlot.BackgroundTransparency = 1
	playerCardSlot.BorderSizePixel  = 0
	playerCardSlot.ClipsDescendants = false
	playerCardSlot.Parent           = sidebar

	-- Divider: garis vertikal pemisah antara sidebar dan contentArea
	local divider = Instance.new("Frame")
	divider.Name                   = "Divider"
	divider.AnchorPoint            = Vector2.new(0, 0)
	divider.Position               = UDim2.fromOffset(constants.sidebarWidth, 0)
	divider.Size                   = UDim2.new(0, 1, 1, 0)
	divider.BackgroundColor3       = colorBorder
	divider.BackgroundTransparency = 0.5
	divider.BorderSizePixel        = 0
	divider.ZIndex                 = 2
	divider.Parent                 = body

	local contentArea = Instance.new("Frame")
	contentArea.Name                   = "Content"
	contentArea.Position               = UDim2.fromOffset(constants.sidebarWidth + 1, 0)
	contentArea.Size                   = UDim2.new(1, -(constants.sidebarWidth + 1), 1, 0)
	contentArea.BackgroundTransparency = 1
	contentArea.ClipsDescendants       = true
	contentArea.Parent                 = body

	-- ── Settings panel ──────────────────────────────────────────────────────
	local self: Window = nil :: any
	local s: any = nil
	local _preConns: { RBXScriptConnection } = {}

	local SP_W    = 580
	local SP_H    = 420
	local SP_TB   = 44
	local SP_NAV  = 116

	local spAccent   = colorAccent
	-- M1 FIX: on touch-only devices the default 1.0 scale leaves 11-13px text
	-- cramped in a ~335px window. Boot at 0.9 so controls are slightly smaller
	-- and more content fits, while staying readable. User can override via Settings.
	local isTouchOnly = variables.isTouchOnly
	local userScale  = if isTouchOnly then 0.9 else 1.0
	local currentToggleKey = toggleKey
	local keepOnScreenVal  = keepOnScreen

	-- Overlay: dims the entire windowFrame while settings panel is open.
	-- Reuse element.makeOverlay anywhere else a modal dim is needed.
	local spOverlay = element.makeOverlay(windowFrame, constants.zIndex.popup - 1)
	-- Exclude the title bar from the overlay so drag/close/settings buttons
	-- remain interactive while the settings panel is open.
	spOverlay.Position = UDim2.fromOffset(0, TITLEBAR_H + 1)
	spOverlay.Size     = UDim2.new(1, 0, 1, -(TITLEBAR_H + 1))
	-- Active = true makes the Frame actually consume mouse events so the body
	-- (sidebar tabs, scroll frames) can't be clicked or scrolled through it.
	spOverlay.Active   = true

	-- Panel frame
	local openingSettings = false
	local settingsPanel = Instance.new("Frame")
	settingsPanel.Name             = "SettingsPanel"
	settingsPanel.AnchorPoint      = Vector2.new(0.5, 0.5)
	settingsPanel.Position         = UDim2.fromScale(0.5, 0.5)
	settingsPanel.Size             = UDim2.fromOffset(SP_W, SP_H)
	settingsPanel.BackgroundColor3 = colorSurface
	settingsPanel.BorderSizePixel  = 0
	settingsPanel.ClipsDescendants = true
	settingsPanel.ZIndex           = constants.zIndex.popup
	settingsPanel.Visible          = false
	settingsPanel.Parent           = windowFrame
	do
		local c = Instance.new("UICorner")
		c.CornerRadius = resolvedTheme.CornerRoundness or UDim.new(0, 8)
		c.Parent       = settingsPanel
	end
	do
		local g = Instance.new("UIGradient")
		g.Color    = resolvedTheme.WindowColor
			or ColorSequence.new(Color3.fromHex("#141414"), Color3.fromHex("#1c1c1c"))
		g.Rotation = 90
		g.Parent   = settingsPanel
	end
	do
		local sk = Instance.new("UIStroke")
		sk.Color           = colorBorder
		sk.Thickness       = 1
		sk.Transparency    = 0
		sk.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		sk.Parent          = settingsPanel
	end

	-- Panel titlebar
	local spTB = Instance.new("Frame")
	spTB.Name             = "TitleBar"
	spTB.Size             = UDim2.new(1, 0, 0, SP_TB)
	spTB.BackgroundColor3 = colorTitleBar
	spTB.BorderSizePixel  = 0
	spTB.ZIndex           = constants.zIndex.popup
	spTB.Parent           = settingsPanel
	local spTBCornerCover: Frame = Instance.new("Frame") -- kept as stub for references below; invisible
	spTBCornerCover.Size             = UDim2.new(0, 0, 0, 0)
	spTBCornerCover.BackgroundTransparency = 1
	spTBCornerCover.Parent           = spTB

	do
		local sep = Instance.new("Frame")
		sep.Name             = "Sep"
		sep.Size             = UDim2.new(1, 0, 0, 1)
		sep.Position         = UDim2.new(0, 0, 1, 0)
		sep.BackgroundColor3 = colorBorder
		sep.BorderSizePixel  = 0
		sep.ZIndex           = constants.zIndex.popup
		sep.Parent           = spTB
	end
	-- Icon badge in settings titlebar
	local spTBBadge = Instance.new("Frame")
	spTBBadge.Name             = "IconBadge"
	spTBBadge.AnchorPoint      = Vector2.new(0, 0.5)
	spTBBadge.Position         = UDim2.new(0, 12, 0.5, 0)
	spTBBadge.Size             = UDim2.fromOffset(26, 26)
	spTBBadge.BackgroundColor3 = colorAccent
	spTBBadge.BorderSizePixel  = 0
	spTBBadge.ZIndex           = constants.zIndex.popup + 1
	spTBBadge.Parent           = spTB
	do
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, 6)
		c.Parent       = spTBBadge
	end
	do
		local g = Instance.new("UIGradient")
		g.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.45),
			NumberSequenceKeypoint.new(1, 0.75),
		})
		g.Rotation = 135
		g.Parent   = spTBBadge
	end
	do
		local settingsIco = Instance.new("ImageLabel")
		settingsIco.Size                   = UDim2.fromOffset(14, 14)
		settingsIco.AnchorPoint            = Vector2.new(0.5, 0.5)
		settingsIco.Position               = UDim2.fromScale(0.5, 0.5)
		settingsIco.BackgroundTransparency = 1
		settingsIco.Image                  = ICON_SETTINGS
		settingsIco.ImageColor3            = Color3.fromRGB(255, 255, 255)
		settingsIco.ZIndex                 = constants.zIndex.popup + 2
		settingsIco.Parent                 = spTBBadge
	end

	local spTitle = Instance.new("TextLabel")
	spTitle.Name                   = "Title"
	spTitle.AnchorPoint            = Vector2.new(0, 0.5)
	spTitle.Position               = UDim2.new(0, 46, 0.5, 0)
	spTitle.Size                   = UDim2.new(0.6, -46, 0, 16)
	spTitle.BackgroundTransparency = 1
	spTitle.Text                   = "Settings"
	spTitle.TextColor3             = colorTextPrimary
	spTitle.TextSize               = 13
	spTitle.FontFace               = resolvedTheme.TitleFont
		or Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold)
	spTitle.TextXAlignment         = Enum.TextXAlignment.Left
	spTitle.ZIndex                 = constants.zIndex.popup + 1
	spTitle.Parent                 = spTB

	local spClose = Instance.new("TextButton")
	spClose.Name                   = "Close"
	spClose.AnchorPoint            = Vector2.new(1, 0.5)
	spClose.Position               = UDim2.new(1, -10, 0.5, 0)
	spClose.Size                   = UDim2.fromOffset(20, 20)
	spClose.BackgroundColor3       = colorSurfaceHover
	spClose.BackgroundTransparency = 0
	spClose.Text                   = ""
	spClose.AutoButtonColor        = false
	spClose.ZIndex                 = constants.zIndex.popup + 1
	spClose.Parent                 = spTB
	do
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, 4)
		c.Parent       = spClose
	end
	local spCloseIcon = Instance.new("ImageLabel")
	spCloseIcon.Name                   = "Icon"
	spCloseIcon.AnchorPoint            = Vector2.new(0.5, 0.5)
	spCloseIcon.Position               = UDim2.fromScale(0.5, 0.5)
	spCloseIcon.Size                   = UDim2.fromOffset(12, 12)
	spCloseIcon.BackgroundTransparency = 1
	spCloseIcon.Image                  = ICON_CLOSE
	spCloseIcon.ImageColor3            = colorTextSecondary
	spCloseIcon.ZIndex                 = constants.zIndex.popup + 2
	spCloseIcon.Parent                 = spClose

	spClose.MouseEnter:Connect(function()
		spClose.BackgroundColor3 = colorError
		spCloseIcon.ImageColor3  = Color3.fromRGB(255, 255, 255)
	end)
	spClose.MouseLeave:Connect(function()
		spClose.BackgroundColor3 = colorSurfaceHover
		spCloseIcon.ImageColor3  = colorTextSecondary
	end)
	local function closeSettings()
		openingSettings        = false
		settingsPanel.Visible  = false
		spOverlay.Visible      = false
		bodyBlocker.Visible    = false
		variables.settingsOpen = false
	end

	table.insert(_preConns, spClose.MouseButton1Click:Connect(closeSettings))
	table.insert(_preConns, spClose.TouchTap:Connect(closeSettings))

	table.insert(_preConns, spOverlay.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			closeSettings()
		end
	end))

	-- Body: horizontal split (nav sidebar | scrolling content)
	local spBody = Instance.new("Frame")
	spBody.Name                   = "Body"
	spBody.Position               = UDim2.fromOffset(0, SP_TB + 1)
	spBody.Size                   = UDim2.new(1, 0, 1, -(SP_TB + 1))
	spBody.BackgroundTransparency = 1
	spBody.ClipsDescendants       = false
	spBody.ZIndex                 = constants.zIndex.popup
	spBody.Parent                 = settingsPanel

	-- Nav sidebar
	local spNav = Instance.new("Frame")
	spNav.Name             = "Nav"
	spNav.Size             = UDim2.new(0, SP_NAV, 1, 0)
	spNav.BackgroundColor3 = Color3.fromHex("#0e0e0e")
	spNav.BackgroundTransparency = 0
	spNav.BorderSizePixel  = 0
	spNav.ClipsDescendants = true
	spNav.ZIndex           = constants.zIndex.popup
	spNav.Parent           = spBody
	do
		local g = Instance.new("UIGradient")
		g.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromHex("#181818")),
			ColorSequenceKeypoint.new(1, Color3.fromHex("#101010")),
		})
		g.Rotation = 90
		g.Parent   = spNav
	end
	-- Nav inner (for padding without clipping the active bar)
	local spNavInner = Instance.new("Frame")
	spNavInner.Name             = "NavInner"
	spNavInner.Size             = UDim2.fromScale(1, 1)
	spNavInner.BackgroundTransparency = 1
	spNavInner.ZIndex           = constants.zIndex.popup
	spNavInner.Parent           = spNav
	do
		local p = Instance.new("UIPadding")
		p.PaddingTop    = UDim.new(0, 10)
		p.PaddingBottom = UDim.new(0, 10)
		p.PaddingLeft   = UDim.new(0, 7)
		p.PaddingRight  = UDim.new(0, 7)
		p.Parent        = spNavInner
	end
	local spNavLayout = Instance.new("UIListLayout")
	spNavLayout.FillDirection     = Enum.FillDirection.Vertical
	spNavLayout.VerticalAlignment = Enum.VerticalAlignment.Top
	spNavLayout.Padding           = UDim.new(0, 2)
	spNavLayout.SortOrder         = Enum.SortOrder.LayoutOrder
	spNavLayout.Parent            = spNavInner

	-- "PREFERENCES" section label in nav
	local spNavSectionLbl = Instance.new("TextLabel")
	spNavSectionLbl.Name                   = "SectionLbl"
	spNavSectionLbl.Size                   = UDim2.new(1, 0, 0, 22)
	spNavSectionLbl.BackgroundTransparency = 1
	spNavSectionLbl.Text                   = "PREFERENCES"
	spNavSectionLbl.TextColor3             = colorTextSecondary
	spNavSectionLbl.TextTransparency       = 0.5
	spNavSectionLbl.TextSize               = 9
	spNavSectionLbl.FontFace               = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold)
	spNavSectionLbl.TextXAlignment         = Enum.TextXAlignment.Left
	spNavSectionLbl.LayoutOrder            = 0
	spNavSectionLbl.ZIndex                 = constants.zIndex.popup + 1
	spNavSectionLbl.Parent                 = spNavInner
	do
		local p = Instance.new("UIPadding")
		p.PaddingLeft   = UDim.new(0, 5)
		p.PaddingBottom = UDim.new(0, 2)
		p.Parent        = spNavSectionLbl
	end

	-- Vertical divider between nav and content
	local spNavDivLine = Instance.new("Frame")
	spNavDivLine.Name             = "NavDivLine"
	spNavDivLine.Position         = UDim2.fromOffset(SP_NAV, 0)
	spNavDivLine.Size             = UDim2.new(0, 1, 1, 0)
	spNavDivLine.BackgroundColor3 = colorBorder
	spNavDivLine.BackgroundTransparency = 0.4
	spNavDivLine.BorderSizePixel  = 0
	spNavDivLine.ZIndex           = constants.zIndex.popup + 1
	spNavDivLine.Parent           = spBody

	-- Content ScrollingFrame (right of nav)
	local spContent = Instance.new("ScrollingFrame")
	spContent.Name                    = "Content"
	spContent.Position                = UDim2.fromOffset(SP_NAV + 1, 0)
	spContent.Size                    = UDim2.new(1, -(SP_NAV + 1), 1, 0)
	spContent.BackgroundTransparency  = 1
	spContent.BorderSizePixel         = 0
	spContent.ScrollBarThickness      = 2
	spContent.ScrollBarImageColor3    = colorBorder
	spContent.ScrollBarImageTransparency = 0.5
	spContent.CanvasSize              = UDim2.fromOffset(0, 0)
	spContent.AutomaticCanvasSize     = Enum.AutomaticSize.Y
	spContent.ClipsDescendants        = true
	spContent.ZIndex                  = constants.zIndex.popup
	spContent.Parent                  = spBody

	local spAccentUpdaters: { (Color3) -> () } = {}

	-- B1 FIX: coalesce accent-drag broadcasts to once per frame.
	-- ColorPicker.callback fires at drag rate (60-120 Hz); without this every
	-- mouse-move during accent drag triggers a full subscriber iteration + (previously)
	-- a Dropdown.buildOptions() on every open dropdown — dozens of instance allocs
	-- per frame. task.defer collapses multiple same-frame calls into one broadcast.
	local _accentBroadcastPending = false
	local function updateAccent(col: Color3)
		colorAccent = col
		spAccent = col
		accentStrip.BackgroundColor3 = col
		logoMark.BackgroundColor3 = col
		resolvedTheme.AccentColor = col
		resolvedTheme.ElementStrokeHover = col   -- keep hover tint in sync with accent
		resolvedTheme.SliderProgress = ColorSequence.new(col, col:Lerp(Color3.fromRGB(0, 0, 0), 0.25))
		resolvedTheme.AccentStroke = col:Lerp(Color3.fromRGB(255, 255, 255), 0.2)
		for _, fn in spAccentUpdaters do
			fn(col)
		end
		-- Coalesce: only one broadcast per frame even if drag fires multiple InputChanged.
		if not _accentBroadcastPending then
			_accentBroadcastPending = true
			task.defer(function()
				_accentBroadcastPending = false
				themeUtil.broadcast(resolvedTheme)
			end)
		end
	end

	-- Helper: standard setting row container
	local function spMakeRow(parent: Frame, label: string, order: number): Frame
		local row = Instance.new("Frame")
		row.Name                   = label
		row.Size                   = UDim2.new(1, 0, 0, constants.elementHeight)
		row.BackgroundTransparency = resolvedTheme.ElementTransparency or 0.97
		row.BackgroundColor3       = Color3.fromRGB(255, 255, 255)
		row.BorderSizePixel        = 0
		row.LayoutOrder            = order
		row.ZIndex                 = constants.zIndex.popup
		row.Parent                 = parent
		do
			local c = Instance.new("UICorner")
			c.CornerRadius = resolvedTheme.ElementCornerRadius or UDim.new(0, 6)
			c.Parent       = row
		end
		do
			local g = Instance.new("UIGradient")
			g.Color    = resolvedTheme.ElementGradient
				or ColorSequence.new(Color3.fromHex("#1e1e1e"), Color3.fromHex("#1a1a1a"))
			g.Rotation = 90
			g.Parent   = row
		end
		do
			local sk = Instance.new("UIStroke")
			sk.Color           = resolvedTheme.ElementStroke or Color3.fromRGB(50, 42, 80)
			sk.Thickness       = 1
			sk.Transparency    = resolvedTheme.ElementStrokeTransparency or 0.6
			sk.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			sk.Parent          = row
		end
		do
			local p = Instance.new("UIPadding")
			p.PaddingLeft  = UDim.new(0, 10)
			p.PaddingRight = UDim.new(0, 10)
			p.Parent       = row
		end
		local lbl = Instance.new("TextLabel")
		lbl.Name                   = "Label"
		lbl.AnchorPoint            = Vector2.new(0, 0.5)
		lbl.Position               = UDim2.fromScale(0, 0.5)
		lbl.Size                   = UDim2.new(1, -165, 0, 14)
		lbl.BackgroundTransparency = 1
		lbl.ClipsDescendants       = true
		lbl.TextTruncate           = Enum.TextTruncate.AtEnd
		lbl.Text                   = label
		lbl.TextColor3             = resolvedTheme.ContentColor or Color3.fromRGB(220, 215, 240)
		lbl.TextSize               = 12
		lbl.FontFace               = resolvedTheme.Font
			or Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium)
		lbl.TextXAlignment         = Enum.TextXAlignment.Left
		lbl.ZIndex                 = constants.zIndex.popup
		lbl.Parent                 = row
		return row
	end

	-- Helper: interactive slider row
	local function spMakeSlider(
		parent: Frame,
		label: string,
		minVal: number,
		maxVal: number,
		stepVal: number,
		currentVal: number,
		suffix: string,
		order: number,
		callback: (val: number) -> ()
	)
		local row = spMakeRow(parent, label, order)

		local valLabel = Instance.new("TextLabel")
		valLabel.Name                   = "Value"
		valLabel.AnchorPoint            = Vector2.new(1, 0.5)
		valLabel.Position               = UDim2.new(1, -12, 0.5, 0)
		valLabel.Size                   = UDim2.new(0, 42, 0, 14)
		valLabel.BackgroundTransparency = 1
		valLabel.TextColor3             = colorTextSecondary
		valLabel.TextSize               = 11
		valLabel.FontFace               = resolvedTheme.Font
			or Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium)
		valLabel.TextXAlignment         = Enum.TextXAlignment.Right
		valLabel.ZIndex                 = constants.zIndex.popup + 1
		valLabel.Parent                 = row

		local trackW = 100
		local trackH = 4
		local track = Instance.new("Frame")
		track.Name             = "Track"
		track.AnchorPoint      = Vector2.new(1, 0.5)
		track.Position         = UDim2.new(1, -60, 0.5, 0)
		track.Size             = UDim2.new(0, trackW, 0, trackH)
		track.BackgroundColor3 = Color3.fromRGB(38, 36, 52)
		track.BorderSizePixel  = 0
		track.ZIndex           = constants.zIndex.popup + 1
		track.Parent           = row
		do
			local c = Instance.new("UICorner")
			c.CornerRadius = UDim.new(1, 0)
			c.Parent       = track
		end

		local fill = Instance.new("Frame")
		fill.Name             = "Fill"
		fill.Size             = UDim2.fromScale(0, 1)
		fill.BackgroundColor3 = spAccent
		fill.BorderSizePixel  = 0
		fill.ZIndex           = constants.zIndex.popup + 2
		fill.Parent           = track
		do
			local c = Instance.new("UICorner")
			c.CornerRadius = UDim.new(1, 0)
			c.Parent       = fill
		end

		local knob = Instance.new("Frame")
		knob.Name             = "Knob"
		knob.AnchorPoint      = Vector2.new(0.5, 0.5)
		knob.Position         = UDim2.fromScale(0, 0.5)
		knob.Size             = UDim2.fromOffset(10, 10)
		knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		knob.BorderSizePixel  = 0
		knob.ZIndex           = constants.zIndex.popup + 3
		knob.Parent           = track
		do
			local c = Instance.new("UICorner")
			c.CornerRadius = UDim.new(1, 0)
			c.Parent       = knob
		end

		table.insert(spAccentUpdaters, function(newAccent)
			fill.BackgroundColor3 = newAccent
		end)

		local function updateVisual(val: number)
			val = math.clamp(val, minVal, maxVal)
			local alpha = if maxVal > minVal then (val - minVal) / (maxVal - minVal) else 0
			alpha = math.clamp(alpha, 0, 1)
			fill.Size = UDim2.fromScale(alpha, 1)
			knob.Position = UDim2.fromScale(alpha, 0.5)
			if stepVal >= 1 then
				valLabel.Text = string.format("%d%s", math.round(val), suffix)
			else
				valLabel.Text = string.format("%.1f%s", val, suffix)
			end
		end

		updateVisual(currentVal)

		local trigger = Instance.new("TextButton")
		trigger.Name                   = "Trigger"
		trigger.AnchorPoint            = Vector2.new(0.5, 0.5)
		trigger.Position               = UDim2.fromScale(0.5, 0.5)
		trigger.Size                   = UDim2.new(1, 16, 1, 20)
		trigger.BackgroundTransparency = 1
		trigger.Text                   = ""
		trigger.ZIndex                 = constants.zIndex.popup + 4
		trigger.Parent                 = track

		local dragging = false
		local lastSnapped = currentVal

		local function setFromMouse(posX: number)
			local relX = posX - track.AbsolutePosition.X
			local tw = track.AbsoluteSize.X
			local alpha = math.clamp(relX / math.max(tw, 1), 0, 1)
			local rawVal = minVal + alpha * (maxVal - minVal)
			local snapped = if stepVal > 0 then minVal + math.round((rawVal - minVal) / stepVal) * stepVal else rawVal
			snapped = math.clamp(snapped, minVal, maxVal)
			updateVisual(snapped)
			if snapped ~= lastSnapped then
				lastSnapped = snapped
				callback(snapped)
			end
		end

		trigger.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				-- DPI fix: use GetMouseLocation for mouse; Touch position is already viewport-scaled.
				local posX = if input.UserInputType == Enum.UserInputType.Touch
					then input.Position.X
					else variables.userInputService:GetMouseLocation().X
				setFromMouse(posX)
			end
		end)

		-- A2 FIX: these global UIS connections capture the whole settings-panel
		-- closure chain. They must be tracked and disconnected on Unload().
		-- _preConns is seeded into s._connections once self is initialized.
		table.insert(_preConns, variables.userInputService.InputChanged:Connect(function(input)
			if not settingsPanel.Visible then
				dragging = false
				return
			end
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				local posX = if input.UserInputType == Enum.UserInputType.Touch
					then input.Position.X
					else variables.userInputService:GetMouseLocation().X
				setFromMouse(posX)
			end
		end))

		table.insert(_preConns, variables.userInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = false
			end
		end))

		-- Hover highlight on the row stroke
		local rowStroke = row:FindFirstChildWhichIsA("UIStroke")
		trigger.MouseEnter:Connect(function()
			if rowStroke then
				rowStroke.Color = spAccent
				rowStroke.Transparency = 0.15
			end
		end)
		trigger.MouseLeave:Connect(function()
			if dragging then return end
			if rowStroke then
				rowStroke.Color = resolvedTheme.ElementStroke or Color3.fromHex("#2b2b2b")
				rowStroke.Transparency = resolvedTheme.ElementStrokeTransparency or 0.6
			end
		end)
	end

	-- A3 FIX: spMakeToggle, spMakeKeybind, spMakeAccentPicker were defined here
	-- but never called — the settings panel uses the real Toggle/Keybind/ColorPicker
	-- components instead (Keybind.new, ColorPicker.new). They were also carrying an
	-- untracked UserInputService.InputBegan connection inside spMakeKeybind (line 1022
	-- in the original). Removed all three dead closures.

	-- ── Category page frame builder ─────────────────────────────────────────
	local function spMakePage(parentFrame: ScrollingFrame): Frame
		local pg = Instance.new("Frame")
		pg.Name                   = "Page"
		pg.Size                   = UDim2.new(1, -24, 0, 0)
		pg.Position               = UDim2.fromOffset(12, 8)
		pg.AutomaticSize          = Enum.AutomaticSize.Y
		pg.BackgroundTransparency = 1
		pg.Visible                = false
		pg.ZIndex                 = constants.zIndex.popup
		pg.Parent                 = parentFrame
		do
			local l = Instance.new("UIListLayout")
			l.FillDirection     = Enum.FillDirection.Vertical
			l.VerticalAlignment = Enum.VerticalAlignment.Top
			l.Padding           = UDim.new(0, constants.elementPadding)
			l.SortOrder         = Enum.SortOrder.LayoutOrder
			l.Parent            = pg
		end
		do
			local p = Instance.new("UIPadding")
			p.PaddingBottom = UDim.new(0, 14)
			p.Parent        = pg
		end
		return pg
	end

	-- ── Nav item builder ──────────────────────────────────────────────────
	local spActiveNavItem: Frame? = nil
	local spNavPages: { [Frame]: Frame } = {}

	local function spMakeNavItem(label: string, iconChar: string, order: number): Frame
		local item = Instance.new("Frame")
		item.Name             = "NavItem_" .. label
		item.Size             = UDim2.new(1, 0, 0, 34)
		item.BackgroundColor3 = Color3.fromHex("#1e1e1e")
		item.BackgroundTransparency = 1
		item.BorderSizePixel  = 0
		item.LayoutOrder      = order
		item.ClipsDescendants = false
		item.ZIndex           = constants.zIndex.popup + 1
		item.Parent           = spNavInner
		do
			local c = Instance.new("UICorner")
			c.CornerRadius = UDim.new(0, 6)
			c.Parent       = item
		end

		-- Left accent bar (visible when active)
		local activeBar = Instance.new("Frame")
		activeBar.Name             = "ActiveBar"
		activeBar.AnchorPoint      = Vector2.new(0, 0.5)
		activeBar.Position         = UDim2.new(0, 0, 0.5, 0)
		activeBar.Size             = UDim2.fromOffset(3, 14)
		activeBar.BackgroundColor3 = colorAccent
		activeBar.BorderSizePixel  = 0
		activeBar.Visible          = false
		activeBar.ZIndex           = constants.zIndex.popup + 2
		activeBar.Parent           = item
		do
			local c = Instance.new("UICorner")
			c.CornerRadius = UDim.new(1, 0)
			c.Parent       = activeBar
		end

		-- Icon badge
		local iconBadge = Instance.new("Frame")
		iconBadge.Name             = "IconBadge"
		iconBadge.AnchorPoint      = Vector2.new(0, 0.5)
		iconBadge.Position         = UDim2.new(0, 10, 0.5, 0)
		iconBadge.Size             = UDim2.fromOffset(20, 20)
		iconBadge.BackgroundColor3 = Color3.fromHex("#242424")
		iconBadge.BorderSizePixel  = 0
		iconBadge.ZIndex           = constants.zIndex.popup + 2
		iconBadge.Parent           = item
		do
			local c = Instance.new("UICorner")
			c.CornerRadius = UDim.new(0, 5)
			c.Parent       = iconBadge
		end
		local iconLbl = Instance.new("TextLabel")
		iconLbl.Name                   = "Icon"
		iconLbl.Size                   = UDim2.fromScale(1, 1)
		iconLbl.BackgroundTransparency = 1
		iconLbl.Text                   = iconChar
		iconLbl.TextColor3             = colorTextSecondary
		iconLbl.TextSize               = 10
		iconLbl.FontFace               = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold)
		iconLbl.TextXAlignment         = Enum.TextXAlignment.Center
		iconLbl.ZIndex                 = constants.zIndex.popup + 3
		iconLbl.Parent                 = iconBadge

		-- Label
		local lbl = Instance.new("TextLabel")
		lbl.Name                   = "Label"
		lbl.AnchorPoint            = Vector2.new(0, 0.5)
		lbl.Position               = UDim2.new(0, 36, 0.5, 0)
		lbl.Size                   = UDim2.new(1, -36, 0, 14)
		lbl.BackgroundTransparency = 1
		lbl.Text                   = label
		lbl.TextColor3             = colorTextSecondary
		lbl.TextSize               = 11
		lbl.FontFace               = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium)
		lbl.TextXAlignment         = Enum.TextXAlignment.Left
		lbl.ZIndex                 = constants.zIndex.popup + 2
		lbl.Parent                 = item

		-- Invisible hit button
		local hit = Instance.new("TextButton")
		hit.Name                   = "Hit"
		hit.Size                   = UDim2.fromScale(1, 1)
		hit.BackgroundTransparency = 1
		hit.Text                   = ""
		hit.AutoButtonColor        = false
		hit.ZIndex                 = constants.zIndex.popup + 3
		hit.Parent                 = item

		hit.MouseEnter:Connect(function()
			if spActiveNavItem ~= item then
				item.BackgroundTransparency = 0.82
				lbl.TextColor3 = colorTextPrimary
				iconBadge.BackgroundColor3 = Color3.fromHex("#2c2c2c")
			end
		end)
		hit.MouseLeave:Connect(function()
			if spActiveNavItem ~= item then
				item.BackgroundTransparency = 1
				lbl.TextColor3 = colorTextSecondary
				iconBadge.BackgroundColor3 = Color3.fromHex("#242424")
			end
		end)
		hit.MouseButton1Click:Connect(function()
			if spActiveNavItem == item then return end
			-- Deactivate old
			if spActiveNavItem then
				local oldBar   = spActiveNavItem:FindFirstChild("ActiveBar")
				local oldLbl   = spActiveNavItem:FindFirstChild("Label")
				local oldBadge = spActiveNavItem:FindFirstChild("IconBadge")
				local oldIco   = if oldBadge then (oldBadge :: Frame):FindFirstChild("Icon") else nil
				spActiveNavItem.BackgroundTransparency = 1
				if oldBar   then (oldBar   :: Frame).Visible             = false end
				if oldLbl   then (oldLbl   :: TextLabel).TextColor3      = colorTextSecondary end
				if oldBadge then (oldBadge :: Frame).BackgroundColor3    = Color3.fromHex("#242424") end
				if oldIco   then (oldIco   :: TextLabel).TextColor3      = colorTextSecondary end
				local oldPage = spNavPages[spActiveNavItem]
				if oldPage then oldPage.Visible = false end
			end
			-- Activate new
			spActiveNavItem = item
			item.BackgroundTransparency = 0.86
			item.BackgroundColor3 = colorAccent
			activeBar.Visible     = true
			lbl.TextColor3        = colorAccent
			iconBadge.BackgroundColor3 = colorAccent
			iconLbl.TextColor3    = Color3.fromRGB(255, 255, 255)
			local newPage = spNavPages[item]
			if newPage then
				newPage.Visible = true
				spContent.CanvasPosition = Vector2.zero
			end
		end)

		return item
	end

	-- ── Create the 3 pages ───────────────────────────────────────────────
	local pageAppearance = spMakePage(spContent)
	pageAppearance.Name = "PageAppearance"

	local pageControls = spMakePage(spContent)
	pageControls.Name = "PageControls"

	local pageFont = spMakePage(spContent)
	pageFont.Name = "PageFont"

	-- ── Create nav items ─────────────────────────────────────────────────
	local navItemAppearance = spMakeNavItem("Appearance", "◈",  1)
	local navItemControls   = spMakeNavItem("Controls",   "⌨",  2)
	local navItemFont       = spMakeNavItem("Font",       "Aa", 3)

	spNavPages[navItemAppearance] = pageAppearance
	spNavPages[navItemControls]   = pageControls
	spNavPages[navItemFont]       = pageFont

	-- ── Populate: Appearance ─────────────────────────────────────────────
	local currentCornerRadius = (resolvedTheme.CornerRoundness or UDim.new(0, 10)).Offset
	spMakeSlider(pageAppearance, "Corner Roundness", 0, 16, 1, currentCornerRadius, "px", 1, function(r)
		local cr = UDim.new(0, r)
		winCorner.CornerRadius = cr
		titleBarCorner.CornerRadius = cr
		cornerCover.Size = UDim.new(1, 0, 0, r)
		cornerCover.Position = UDim.new(0, 0, 1, -r)
		resolvedTheme.CornerRoundness = cr
	end)

	local function smoothSetScale(factor: number)
		userScale = factor
		if s then s._userScale = factor end
		variables.uiScale = factor
		if s and s._scaleTween then
			s._scaleTween:Cancel()
		end
		local tw = variables.tweenService:Create(
			winScale,
			TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Scale = factor }
		)
		if s then s._scaleTween = tw end
		tw.Completed:Once(function()
			tw:Destroy()
			if s then s._scaleTween = nil end
			if not self then return end
			local wf = (self :: any)._windowFrame
			if not wf then return end
			local screen = (self :: any)._gui.AbsoluteSize
			local margin = 8
			local curW = wf.AbsoluteSize.X
			local curH = wf.AbsoluteSize.Y
			local curPos = wf.Position
			local newX = curPos.X.Offset
			local newY = curPos.Y.Offset
			if curW >= screen.X - margin * 2 then
				newX = math.floor(screen.X / 2)
			else
				newX = math.clamp(newX, margin + math.floor(curW / 2), screen.X - margin - math.ceil(curW / 2))
			end
			if curH >= screen.Y - margin * 2 then
				newY = math.floor(screen.Y / 2)
			else
				newY = math.clamp(newY, margin + math.floor(curH / 2), screen.Y - margin - math.ceil(curH / 2))
			end
			local clamped = UDim2.fromOffset(newX, newY)
			if clamped ~= curPos then
				if s and s._posScaleTween then s._posScaleTween:Cancel() end
				local posTw = variables.tweenService:Create(
					wf,
					TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{ Position = clamped }
				)
				if s then s._posScaleTween = posTw end
				posTw:Play()
			end
		end)
		tw:Play()
	end

	spMakeSlider(pageAppearance, "UI Scale / DPI", 80, 125, 5, 100, "%", 2, function(pct)
		smoothSetScale(pct / 100)
	end)

	do
		local cp = ColorPicker.new({
			name     = "Accent Color",
			color    = colorAccent,
			callback = function(col: Color3, _alpha: number)
				updateAccent(col)
			end,
		}, resolvedTheme, pageAppearance)
		cp._frame.LayoutOrder = 3
	end

	spMakeSlider(pageAppearance, "Background Transparency", 0, 25, 5, 0, "%", 4, function(pct)
		windowFrame.BackgroundTransparency = pct / 100
	end)

	-- ── Populate: Controls ───────────────────────────────────────────────
	do
		local kb = Keybind.new({
			name      = "Menu Keybind",
			value     = currentToggleKey,
			onChanged = function(newKey: Enum.KeyCode)
				currentToggleKey = newKey
				if s then s._toggleKey = newKey end
			end,
		}, resolvedTheme, pageControls)
		kb._frame.LayoutOrder = 1
	end

	-- ── Populate: Font ───────────────────────────────────────────────────
	do
		local FONT_MAP: { [string]: string } = {
			["Gotham"]          = "rbxasset://fonts/families/GothamSSm.json",
			["Roboto"]          = "rbxasset://fonts/families/Roboto.json",
			["Source Sans Pro"] = "rbxasset://fonts/families/SourceSansPro.json",
			["Ubuntu"]          = "rbxasset://fonts/families/Ubuntu.json",
			["Syne"]            = "rbxasset://fonts/families/Syne.json",
			["Nunito"]          = "rbxasset://fonts/families/Nunito.json",
			["Builder Sans"]    = "rbxasset://fonts/families/BuilderSans.json",
			["Jura"]            = "rbxasset://fonts/families/Jura.json",
		}
		local fontDD = Dropdown.new({
			name        = "UI Font",
			options     = { "Gotham", "Roboto", "Source Sans Pro", "Ubuntu", "Syne", "Nunito", "Builder Sans", "Jura" },
			value       = "Gotham",
			layoutOrder = 1,
			callback    = function(val: any)
				local family = FONT_MAP[tostring(val)] or "rbxasset://fonts/families/GothamSSm.json"
				resolvedTheme.Font      = Font.new(family, Enum.FontWeight.Medium)
				resolvedTheme.TitleFont = Font.new(family, Enum.FontWeight.SemiBold)
				themeUtil.broadcast(resolvedTheme)
				for _, desc in windowFrame:GetDescendants() do
					if desc:IsA("TextLabel") or desc:IsA("TextButton") then
						local existing = (desc :: TextLabel).FontFace
						;(desc :: TextLabel).FontFace = Font.new(family, existing.Weight, existing.Style)
					end
				end
			end,
		}, resolvedTheme, pageFont)
		fontDD._frame.LayoutOrder = 1
	end

	-- ── Activate Appearance by default ───────────────────────────────────
	do
		local firstItem = navItemAppearance
		spActiveNavItem        = firstItem
		firstItem.BackgroundTransparency = 0.86
		firstItem.BackgroundColor3       = colorAccent
		local bar   = firstItem:FindFirstChild("ActiveBar")
		local lbl   = firstItem:FindFirstChild("Label")
		local badge = firstItem:FindFirstChild("IconBadge")
		if bar   then (bar   :: Frame).Visible             = true end
		if lbl   then (lbl   :: TextLabel).TextColor3      = colorAccent end
		if badge then
			(badge :: Frame).BackgroundColor3 = colorAccent
			local ico = (badge :: Frame):FindFirstChild("Icon")
			if ico then (ico :: TextLabel).TextColor3 = Color3.fromRGB(255, 255, 255) end
		end
		pageAppearance.Visible = true
	end

	local function updateSettingsPanelSize()
		local winW = if s and s._windowSize then s._windowSize.X.Offset else (if windowFrame.Size.X.Offset > 0 then windowFrame.Size.X.Offset else windowFrame.AbsoluteSize.X)
		local winH = if s and s._windowSize then s._windowSize.Y.Offset else (if windowFrame.Size.Y.Offset > 0 then windowFrame.Size.Y.Offset else windowFrame.AbsoluteSize.Y)
		local availableW = math.max(200, winW - 24)
		local availableH = math.max(150, winH - (TITLEBAR_H + 20))

		local targetW = math.min(SP_W, availableW)
		local targetH = math.min(SP_H, availableH)
		settingsPanel.Size = UDim2.fromOffset(targetW, targetH)
	end

	local function toggleSettings()
		if openingSettings then return end
		local next = not settingsPanel.Visible
		if next then
			local function showSettings()
				openingSettings = false
				updateSettingsPanelSize()
				settingsPanel.Visible = true
				spOverlay.Visible     = true
				bodyBlocker.Visible    = true
				variables.settingsOpen = true
			end

			if s and s._minimized then
				openingSettings = true
				self:ToggleMinimise()
				local tw = s._activeTween
				if tw then
					tw.Completed:Once(function()
						if not s._minimized then
							showSettings()
						else
							openingSettings = false
						end
					end)
				else
					showSettings()
				end
			else
				showSettings()
			end
		else
			openingSettings       = false
			settingsPanel.Visible = false
			spOverlay.Visible     = false
			bodyBlocker.Visible    = false
			variables.settingsOpen = false
		end
	end

	table.insert(_preConns, settingsBtn.MouseButton1Click:Connect(toggleSettings))
	table.insert(_preConns, settingsBtn.TouchTap:Connect(toggleSettings))

	table.insert(_preConns, windowFrame:GetPropertyChangedSignal("Size"):Connect(function()
		if settingsPanel.Visible then
			updateSettingsPanelSize()
		end
	end))

	-- ── Self ──────────────────────────────────────────────────────────────
	self = setmetatable({}, Window) :: Window
	self.unloaded = false
	self._gui     = gui
	s = (self :: any)
	s._windowFrame   = windowFrame
	s._winScale      = winScale
	s._userScale     = userScale
	s._toggleKey     = currentToggleKey
	s._sidebar       = tabListScroll
	s._sidebarFrame    = sidebar
	s._playerCardSlot  = playerCardSlot
	s._contentArea   = contentArea
	s._divider       = divider
	s._theme         = resolvedTheme
	s._tabs          = {} :: { Tab.Tab }
	s._activeTab     = nil :: Tab.Tab?
	s._visible       = false
	s._minimized     = false
	s._hasBeenDragged = false
	s._windowSize    = initialSize    -- UDim2, updated by _applyWindowSize
	s._titlebarH     = TITLEBAR_H
	s._body          = body
	s._minBtn        = minBtn
	s._minIcon       = minIcon
	s._titleSep      = titleSep
	s._keepOnScreen  = keepOnScreenVal
	s._dragging      = false          -- true while titleBar is being dragged
	s._pendingResize = false          -- resize banked while hidden/minimized
	s._connections   = _preConns      -- A2 FIX: seeded with pre-init UIS conns from spMakeSlider
	s._activeTween    = nil           -- running minimize/restore Size tween
	s._scaleTween     = nil           -- running UI scale tween
	s._posScaleTween  = nil           -- running position clamp tween on scale
	s._activeAnimConn = nil           -- RenderStepped position-tracker connection
	s._minimizeAnimId = nil           -- guard token for body-hide task.delay
	s._titleBarBg     = titleBarBg
	s._titleBarCorner = titleBarCorner
	s._cornerCover    = cornerCover
	s._settingsPanel  = settingsPanel
	s._spOverlay      = spOverlay
	s._bodyBlocker    = bodyBlocker

	-- M1 FIX: apply initial scale (0.9 on touch, 1.0 on desktop) now that s exists.
	if userScale ~= 1.0 then
		winScale.Scale       = userScale
		variables.uiScale    = userScale
		s._userScale         = userScale
	end

	-- M5 FIX: title bar buttons are 26×26 — below 38px ergonomic floor on touch.
	-- Bump to 34×34 on touch-only so they're reliably hittable with a fingertip.
	if isTouchOnly then
		for _, btn in { settingsBtn, minBtn, closeBtn } :: { TextButton } do
			btn.Size = UDim2.fromOffset(34, 34)
		end
		-- Widen the controls frame to fit the larger buttons.
		controlsFrame.Size = UDim2.fromOffset(120, 36)
	end

	-- Theme subscription: reactive properties that update on theme change
	s._themeUnsub = themeUtil.subscribe(function(t)
		s._theme = t
		winStroke.Color = t.SurfaceStroke
		winGradient.Color = t.WindowColor
		if s._titleBarBg then (s._titleBarBg :: Frame).BackgroundColor3 = t.TitleBarColor end
		titleSep.BackgroundColor3 = t.SurfaceStroke
		sidebar.BackgroundColor3 = t.TitleBarColor
		sidebarHeader.TextColor3 = t.PlaceholderColor
		tabListScroll.ScrollBarImageColor3 = t.SurfaceStroke
		spTB.BackgroundColor3 = t.TitleBarColor
		settingsBtn.BackgroundColor3 = t.NeutralButton
		minBtn.BackgroundColor3 = t.NeutralButton
		closeBtn.BackgroundColor3 = t.NeutralButton
		settingsIcon.ImageColor3 = t.PlaceholderColor
		minIcon.ImageColor3 = t.PlaceholderColor
		closeIcon.ImageColor3 = t.PlaceholderColor
		spClose.BackgroundColor3 = t.NeutralButton
		spCloseIcon.ImageColor3 = t.PlaceholderColor
		colorSurface = t.WindowColor.Keypoints[1].Value
		colorTitleBar = t.TitleBarColor
		colorBorder = t.SurfaceStroke
		colorSurfaceHover = t.NeutralButton
		colorAccent = t.AccentColor
		spAccent = t.AccentColor
		colorError = t.ErrorColor
		colorTextPrimary = t.TitlingColor
		colorTextSecondary = t.PlaceholderColor
		for _, fn in spAccentUpdaters do
			fn(t.AccentColor)
		end
	end, windowFrame)

	-- ── Drag system (RenderStepped, clamped) ──────────────────────────────
	do
		local uis        = variables.userInputService
		local dragging   = false
		local dragStart  = Vector3.zero
		local startPos   = UDim2.fromOffset(0, 0)
		local lastX, lastY = 0, 0

		-- Guard: skip interactive frames while fully hidden.
		local function interactive(): boolean
			return (self :: any)._visible
		end

		table.insert(s._connections, titleBar.InputBegan:Connect(function(input, processed)
			if processed then return end
			if input.UserInputType ~= Enum.UserInputType.MouseButton1
				and input.UserInputType ~= Enum.UserInputType.Touch then return end
			if not interactive() then return end

			-- If clicking within controlsFrame (minimize, close, settings), ignore drag
			local inputPos = if input.UserInputType == Enum.UserInputType.Touch
				then Vector2.new(input.Position.X, input.Position.Y)
				else uis:GetMouseLocation()
			local cp = controlsFrame.AbsolutePosition
			local cs = controlsFrame.AbsoluteSize
			if inputPos.X >= cp.X - 6 and inputPos.X <= cp.X + cs.X + 6
				and inputPos.Y >= cp.Y - 6 and inputPos.Y <= cp.Y + cs.Y + 6 then
				return
			end

			dragging  = true
			dragStart = input.Position
			startPos  = windowFrame.Position
			lastX     = startPos.X.Offset
			lastY     = startPos.Y.Offset

			local _ds = (self :: any)
			_ds._dragging = true
			_ds._hasBeenDragged = true

			local dragMoveConn: RBXScriptConnection? = nil
			local dragEndConn: RBXScriptConnection? = nil
			local wfrConn: RBXScriptConnection? = nil

			local function stopDrag()
				if not dragging then return end
				dragging = false
				_ds._dragging = false

				if dragMoveConn then dragMoveConn:Disconnect(); dragMoveConn = nil end
				if dragEndConn then dragEndConn:Disconnect(); dragEndConn = nil end
				if wfrConn then wfrConn:Disconnect(); wfrConn = nil end
			end

			dragMoveConn = uis.InputChanged:Connect(function(moveInput)
				if not dragging then return end
				if moveInput.UserInputType ~= Enum.UserInputType.MouseMovement
					and moveInput.UserInputType ~= Enum.UserInputType.Touch then return end
				if not interactive() then return end

				local delta = moveInput.Position - dragStart
				if math.abs(delta.X) < 1 and math.abs(delta.Y) < 1 then return end

				local newX = startPos.X.Offset + delta.X
				local newY = startPos.Y.Offset + delta.Y

				if (self :: any)._keepOnScreen then
					local screen = gui.AbsoluteSize
					local curW   = windowFrame.AbsoluteSize.X
					local curH   = windowFrame.AbsoluteSize.Y
					local margin = 8

					if curW >= screen.X - margin * 2 then
						newX = math.floor(screen.X / 2)
					else
						local minX = margin + math.floor(curW / 2)
						local maxX = screen.X - margin - math.ceil(curW / 2)
						newX = math.clamp(newX, minX, maxX)
					end

					if curH >= screen.Y - margin * 2 then
						newY = math.floor(screen.Y / 2)
					else
						local minY = margin + math.floor(curH / 2)
						local maxY = screen.Y - margin - math.ceil(curH / 2)
						newY = math.clamp(newY, minY, maxY)
					end
				end

				if math.abs(newX - lastX) < 0.5 and math.abs(newY - lastY) < 0.5 then return end
				lastX, lastY = newX, newY
				windowFrame.Position = UDim2.fromOffset(newX, newY)
			end)

			dragEndConn = uis.InputEnded:Connect(function(endInput)
				if endInput.UserInputType == Enum.UserInputType.MouseButton1
					or endInput.UserInputType == Enum.UserInputType.Touch then
					stopDrag()
				end
			end)

			wfrConn = uis.WindowFocusReleased:Connect(stopDrag)
		end))
	end

	-- ── Window controls ───────────────────────────────────────────────────
	table.insert(s._connections, closeBtn.MouseButton1Click:Connect(function()
		self:Unload()
	end))
	table.insert(s._connections, closeBtn.TouchTap:Connect(function()
		self:Unload()
	end))

	table.insert(s._connections, minBtn.MouseButton1Click:Connect(function()
		self:ToggleMinimise()
	end))
	table.insert(s._connections, minBtn.TouchTap:Connect(function()
		self:ToggleMinimise()
	end))

	-- ── Toggle keybind ────────────────────────────────────────────────────
	-- A1 FIX: capture this global InputBegan connection so Unload() disconnects it.
	-- Without this the closure pins self + the whole window instance graph in memory.
	table.insert(s._connections, variables.userInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if self.unloaded then return end
		local activeKey = (self :: any)._toggleKey or toggleKey
		if input.KeyCode == activeKey then
			self:ToggleHide()
		end
	end))

	windowFrame.Visible = false

	-- Start viewport watcher — keeps the window sized to the screen on resize/rotation.
	self:_watchViewport()

	-- ── Mobile / Touch iOS-style Gesture Bar ──────────────────────────────
	-- Strictly mobile-only: PC players use keyboard keybind exclusively.
	local isMobile = variables.isTouchOnly or (variables.userInputService.TouchEnabled and not variables.userInputService.KeyboardEnabled)
	local showGestureBar = isMobile and (props.gestureBar ~= false)

	if showGestureBar then
		local barContainer = Instance.new("Frame")
		barContainer.Name                   = "Delirium_GestureBar"
		barContainer.AnchorPoint            = Vector2.new(0, 0.5)
		barContainer.Position               = UDim2.new(0, 0, 0.5, 0)
		barContainer.Size                   = UDim2.fromOffset(36, 110)
		barContainer.BackgroundTransparency = 1
		barContainer.BorderSizePixel        = 0
		barContainer.ZIndex                 = constants.zIndex.tooltip + 10
		barContainer.Parent                 = gui

		local barPill = Instance.new("Frame")
		barPill.Name             = "Pill"
		barPill.AnchorPoint      = Vector2.new(0, 0.5)
		barPill.Position         = UDim2.new(0, 4, 0.5, 0)
		barPill.Size             = UDim2.fromOffset(5, 76)
		barPill.BackgroundColor3 = colorAccent
		barPill.BackgroundTransparency = 0.55
		barPill.BorderSizePixel  = 0
		barPill.ZIndex           = constants.zIndex.tooltip + 11
		barPill.Parent           = barContainer

		local pillCorner = Instance.new("UICorner")
		pillCorner.CornerRadius = UDim.new(1, 0)
		pillCorner.Parent       = barPill

		local pillStroke = Instance.new("UIStroke")
		pillStroke.Color           = Color3.fromRGB(255, 255, 255)
		pillStroke.Thickness       = 1
		pillStroke.Transparency    = 0.75
		pillStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		pillStroke.Parent          = barPill

		table.insert(spAccentUpdaters, function(newAccent)
			barPill.BackgroundColor3 = newAccent
		end)

		local isGestureDragging = false
		local startTouchX = 0
		local currentDeltaX = 0
		local dragMoveConn: RBXScriptConnection? = nil
		local dragEndConn: RBXScriptConnection? = nil

		local function stopGestureDrag()
			if not isGestureDragging then return end
			isGestureDragging = false
			if dragMoveConn then dragMoveConn:Disconnect(); dragMoveConn = nil end
			if dragEndConn then dragEndConn:Disconnect(); dragEndConn = nil end

			tween.fire(barPill, constants.tweenFast, {
				Position               = UDim2.new(0, 4, 0.5, 0),
				Size                   = UDim2.fromOffset(5, 76),
				BackgroundTransparency = 0.55,
			})
			tween.fire(pillStroke, constants.tweenFast, {
				Transparency = 0.75,
				Color        = Color3.fromRGB(255, 255, 255),
			})

			if currentDeltaX >= 25 then
				self:ToggleHide()
			end
			currentDeltaX = 0
		end

		table.insert(s._connections, barContainer.InputBegan:Connect(function(input)
			if input.UserInputType ~= Enum.UserInputType.Touch then
				return
			end
			isGestureDragging = true
			startTouchX = input.Position.X
			currentDeltaX = 0

			tween.fire(barPill, constants.tweenFast, {
				Size                   = UDim2.fromOffset(8, 88),
				BackgroundTransparency = 0.15,
			})
			tween.fire(pillStroke, constants.tweenFast, {
				Transparency = 0.2,
				Color        = colorAccent,
			})

			if dragMoveConn then dragMoveConn:Disconnect() end
			if dragEndConn then dragEndConn:Disconnect() end

			dragMoveConn = variables.userInputService.InputChanged:Connect(function(moveInput)
				if not isGestureDragging then return end
				if moveInput.UserInputType ~= Enum.UserInputType.Touch then
					return
				end

				local delta = math.max(0, moveInput.Position.X - startTouchX)
				currentDeltaX = delta
				local visualX = math.min(delta, 80)
				barPill.Position = UDim2.new(0, 4 + visualX, 0.5, 0)
			end)

			dragEndConn = variables.userInputService.InputEnded:Connect(function(endInput)
				if endInput.UserInputType == Enum.UserInputType.Touch then
					stopGestureDrag()
				end
			end)
		end))

		s._gestureCleanup = stopGestureDrag
	end

	return self
end

-- ── Sizing & clamping methods ─────────────────────────────────────────────────

function Window:_clampedPositionForScale(position: UDim2, scale: number): UDim2
	if not (self :: any)._keepOnScreen then return position end

	local screen = self._gui.AbsoluteSize
	local s      = (self :: any)
	local baseW  = if s._windowFrame then s._windowFrame.Size.X.Offset else s._windowSize.X.Offset
	local baseH  = if s._minimized then s._titlebarH else s._windowSize.Y.Offset
	local curW   = baseW * scale
	local curH   = baseH * scale
	local margin = 8

	local newX = position.X.Offset
	local newY = position.Y.Offset

	if curW >= screen.X - margin * 2 then
		newX = math.floor(screen.X / 2)
	else
		local minX = margin + math.floor(curW / 2)
		local maxX = screen.X - margin - math.ceil(curW / 2)
		newX = math.clamp(newX, minX, maxX)
	end

	if curH >= screen.Y - margin * 2 then
		newY = math.floor(screen.Y / 2)
	else
		local minY = margin + math.floor(curH / 2)
		local maxY = screen.Y - margin - math.ceil(curH / 2)
		newY = math.clamp(newY, minY, maxY)
	end

	if newX == position.X.Offset and newY == position.Y.Offset then return position end
	return UDim2.fromOffset(newX, newY)
end

-- Where position ends up once clamped to the current screen.
function Window:_clampedPosition(position: UDim2): UDim2
	if not (self :: any)._keepOnScreen then return position end
	local s = (self :: any)
	local scale = if s._winScale then s._winScale.Scale else 1.0
	return self:_clampedPositionForScale(position, scale)
end

function Window:_clampToScreen()
	local wf: Frame = (self :: any)._windowFrame
	wf.Position = self:_clampedPosition(wf.Position)
end

-- Apply a new viewport-fitted size. Banks the change if the window is hidden,
-- minimized, or mid-drag (to avoid fighting a tween or a live drag).
function Window:_applyWindowSize()
	if self.unloaded then return end
	local s = (self :: any)

	-- Recompute both the window size and the shared UI scale for this viewport.
	local cam = variables.workspace.CurrentCamera
	local userMultiplier = s._userScale or 1.0
	variables.uiScale = userMultiplier
	if s._winScale and s._scaleTween == nil then
		s._winScale.Scale = userMultiplier
	end

	local newSize = fitWindowSize()
	local changed = newSize ~= s._windowSize
	s._windowSize = newSize

	local hidden    = not s._visible
	local minimized = s._minimized
	local dragging  = s._dragging

	if hidden or minimized or dragging or s._activeTween ~= nil then
		if changed then s._pendingResize = true end
		return
	end

	if not changed and not s._pendingResize then return end
	s._pendingResize = false

	local wf: Frame = (self :: any)._windowFrame
	wf.Size = newSize

	local vp = if cam then cam.ViewportSize else nil
	if not s._hasBeenDragged and vp then
		wf.Position = UDim2.fromOffset(
			math.max(0, math.floor((vp.X - newSize.X.Offset) / 2)),
			math.max(0, math.floor((vp.Y - newSize.Y.Offset) / 2))
		)
	else
		self:_clampToScreen()
	end
end

-- Watch CurrentCamera.ViewportSize. Rebinds when the camera is swapped.
function Window:_watchViewport()
	local s = (self :: any)
	local pending = false

	local function request()
		if pending then return end
		pending = true
		task.defer(function()
			pending = false
			self:_applyWindowSize()
		end)
	end

	local function bind()
		if s._cameraConn then
			s._cameraConn:Disconnect()
			s._cameraConn = nil
		end
		local cam = variables.workspace.CurrentCamera
		if cam then
			s._cameraConn = cam:GetPropertyChangedSignal("ViewportSize"):Connect(request)
		end
		request()
	end

	local camSwapConn = variables.workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(bind)
	table.insert(s._connections, camSwapConn)
	bind()
end

-- ── Tab management ────────────────────────────────────────────────────────────

function Window:CreateTab(props: Tab.TabProps): Tab.Tab
	local tabs: { Tab.Tab }        = (self :: any)._tabs
	local sidebar: Frame           = (self :: any)._sidebar
	local contentArea: Frame       = (self :: any)._contentArea
	local theme: { [string]: any } = (self :: any)._theme
	local wf: Frame                = (self :: any)._windowFrame

	local t = Tab.new(props, theme, contentArea, sidebar, wf)

	local btn = (t :: any)._tabButton

	btn.MouseButton1Click:Connect(function()
		local _s = (self :: any)
		-- hide dashboard content when switching to a real tab
		if _s._playerCard then
			(_s._playerCard :: any):HideContent()
		end
		_s:_activateTab(t)
	end)

	table.insert(tabs, t)
	btn.LayoutOrder = #tabs

	if #tabs == 1 then
		local _s = (self :: any)
		_s:_activateTab(t)
	else
		t:Hide()
	end

	return t
end

-- ── PlayerCard ───────────────────────────────────────────────────────────────

function Window:CreatePlayerCard()
	local s            = (self :: any)
	local slot: Frame  = s._playerCardSlot
	local wf: Frame    = s._windowFrame
	local ca: Frame    = s._contentArea
	local theme        = s._theme

	local pc = PlayerCard.new(slot, wf, ca, theme)
	s._playerCard = pc

	-- Wire card click → deselect all real tabs → show dashboard content
	local cardHit = (pc :: any)._cardHit :: TextButton?
	if cardHit then
		cardHit.MouseButton1Click:Connect(function()
			for _, tab in (s._tabs :: { any }) do
				tab:Hide()
			end
			s._activeTab = nil
			pc:ShowContent()
		end)
	end

	return pc
end

function Window:_activateTab(target: Tab.Tab)
	local s = (self :: any)
	local tabs: { Tab.Tab } = s._tabs
	for _, tab in tabs do
		if tab == target then
			tab:Show()
		else
			tab:Hide()
		end
	end
	s._activeTab = target
end

-- ── Notify ────────────────────────────────────────────────────────────────────

function Window:Notify(props: notification.NotifyProps)
	if self.unloaded then return end
	notification.send(props, (self :: any)._theme)
end

-- ── Show / Hide / ToggleHide ──────────────────────────────────────────────────

function Window:Show()
	if self.unloaded then return end
	local s = (self :: any)
	local windowFrame: Frame = s._windowFrame

	-- If previously minimised, restore full geometry before the show tween.
	if s._minimized then
		if s._activeTween then
			s._activeTween:Cancel()
			s._activeTween = nil
		end
		s._minimized = false
		;(s._body :: Frame).Visible = true
		if s._divider then (s._divider :: Frame).Visible = true end
		if s._titleSep then (s._titleSep :: Frame).Visible = true end
		if s._cornerCover then (s._cornerCover :: Frame).Visible = true end
		local fullH: number = s._windowSize.Y.Offset
		local topY = windowFrame.Position.Y.Offset - math.floor(s._titlebarH / 2)
		local restoreCenterY = topY + math.floor(fullH / 2)
		windowFrame.Position = self:_clampedPosition(UDim2.fromOffset(windowFrame.Position.X.Offset, restoreCenterY))
		windowFrame.Size = s._windowSize
		;(s._minBtn :: TextButton).Text = ""
		if s._minIcon then (s._minIcon :: ImageLabel).Image = ICON_MINIMIZE end
	end

	-- Apply any banked resize before we show.
	if s._pendingResize then
		s._pendingResize = false
		windowFrame.Size = s._windowSize
	end

	s._visible   = true
	windowFrame.Position = self:_clampedPosition(windowFrame.Position)

	-- BackgroundTransparency starts at 1 (set in constructor) so the frame is
	-- invisible on the first rendered frame. We must wait until after that frame
	-- has been drawn before tweening opacity — otherwise Roblox may render one
	-- frame where UICorner hasn't been computed yet, producing a square-corner
	-- flash the moment the window becomes visible.
	windowFrame.BackgroundTransparency = 1
	windowFrame.Visible = true
	task.spawn(function()
		game:GetService("RunService").RenderStepped:Wait()
		if not s._visible or self.unloaded then return end
		tween.fire(windowFrame, constants.tweenNormal, {
			BackgroundTransparency = 0,
		})
	end)
end

function Window:Hide()
	if self.unloaded then return end
	local s = (self :: any)
	local windowFrame: Frame = s._windowFrame
	s._visible = false
	windowFrame.Visible = false
end

function Window:ToggleHide()
	if (self :: any)._visible then
		self:Hide()
	else
		self:Show()
	end
end

function Window:ToggleMinimise()
	if self.unloaded then return end
	local s = (self :: any)
	if not s._visible then return end

	-- Cancel any running animation
	if s._activeTween then
		s._activeTween:Cancel()
		s._activeTween = nil
	end

	local windowFrame: Frame    = s._windowFrame
	local body: Frame           = s._body
	local divider: Frame?       = s._divider
	local cornerCover: Frame?   = s._cornerCover
	local titlebarH: number     = s._titlebarH
	local fullH: number         = s._windowSize.Y.Offset
	local width: number         = s._windowSize.X.Offset
	local keepOnScreen: boolean = s._keepOnScreen
	local screen                = self._gui.AbsoluteSize
	local margin                = 8

	-- Snapshot actual rendered geometry to avoid floating-point / subpixel rounding jitter.
	local absPos  = windowFrame.AbsolutePosition
	local absSize = windowFrame.AbsoluteSize
	local centerX = absPos.X + absSize.X / 2
	local centerY = absPos.Y + absSize.Y / 2
	local topY    = absPos.Y

	if keepOnScreen then
		local halfW = width / 2
		centerX = math.clamp(centerX, halfW + margin, math.max(halfW + margin, screen.X - halfW - margin))
	end

	-- Normalize position to pure integer Offset centered at the current visual position
	windowFrame.Position = UDim2.fromOffset(centerX, centerY)

	local TWEEN_INFO = TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

	if s._minimized then
		-- ── RESTORE ──────────────────────────────────────────────
		s._minimized     = false
		s._pendingResize = false

		local targetCY = topY + fullH / 2
		if keepOnScreen then
			local halfH = fullH / 2
			targetCY = math.clamp(targetCY, halfH + margin, math.max(halfH + margin, screen.Y - halfH - margin))
		end

		body.Visible = true
		if divider then divider.Visible = true end
		if s._titleSep then (s._titleSep :: Frame).Visible = true end

		local tw = tween.play(windowFrame, TWEEN_INFO, {
			Size     = UDim2.fromOffset(width, fullH),
			Position = UDim2.fromOffset(centerX, targetCY),
		})
		s._activeTween = tw
		tw.Completed:Once(function()
			tw:Destroy()
			if s._activeTween == tw then
				s._activeTween = nil
				if not s._minimized then
					if cornerCover then cornerCover.Visible = true end
				end
			end
		end)
		;(s._minBtn :: TextButton).Text = ""
		-- Fade icon: RESTORE → MINIMIZE
		if s._minIcon then
			local _ic = s._minIcon :: ImageLabel
			local _fo = tween.play(_ic, TweenInfo.new(0.1, Enum.EasingStyle.Quad), { ImageTransparency = 1 })
			_fo.Completed:Once(function()
				_fo:Destroy()
				_ic.Image = ICON_MINIMIZE
				tween.fire(_ic, TweenInfo.new(0.1, Enum.EasingStyle.Quad), { ImageTransparency = 0 })
			end)
		end
	else
		-- ── MINIMIZE ─────────────────────────────────────────────
		s._minimized = true

		-- Close settings panel if open so it doesn't get trapped in collapsed titlebar
		if s._settingsPanel and s._settingsPanel.Visible then
			s._settingsPanel.Visible = false
			if s._spOverlay then s._spOverlay.Visible = false end
			if s._bodyBlocker then s._bodyBlocker.Visible = false end
			variables.settingsOpen = false
		end

		local targetCY = topY + titlebarH / 2
		if keepOnScreen then
			local halfTH = titlebarH / 2
			targetCY = math.clamp(targetCY, halfTH + margin, math.max(halfTH + margin, screen.Y - halfTH - margin))
		end

		-- Flatten bottom corners to rounded immediately so the pill is cleanly rounded during the whole tween
		if cornerCover then cornerCover.Visible = false end
		if divider then divider.Visible = false end
		if s._titleSep then (s._titleSep :: Frame).Visible = false end

		local animId = {}
		s._minimizeAnimId = animId

		local tw = tween.play(windowFrame, TWEEN_INFO, {
			Size     = UDim2.fromOffset(width, titlebarH),
			Position = UDim2.fromOffset(centerX, targetCY),
		})
		s._activeTween = tw
		tw.Completed:Once(function()
			tw:Destroy()
			if s._activeTween == tw then
				s._activeTween = nil
				body.Visible = false
			end
		end)

		-- Defer hiding body contents slightly to avoid frame-0 layout reflow jitter
		task.delay(0.22, function()
			if s._minimizeAnimId ~= animId then return end
			if not s._minimized then return end
			body.Visible = false
		end)

		;(s._minBtn :: TextButton).Text = ""
		-- Fade icon: MINIMIZE → RESTORE
		if s._minIcon then
			local _ic = s._minIcon :: ImageLabel
			local _fo = tween.play(_ic, TweenInfo.new(0.1, Enum.EasingStyle.Quad), { ImageTransparency = 1 })
			_fo.Completed:Once(function()
				_fo:Destroy()
				_ic.Image = ICON_RESTORE
				tween.fire(_ic, TweenInfo.new(0.1, Enum.EasingStyle.Quad), { ImageTransparency = 0 })
			end)
		end
	end
end

-- ── ChangeTheme ───────────────────────────────────────────────────────────────

function Window:ChangeTheme(newTheme: string | { [string]: any })
	local s = (self :: any)
	local resolved = themeUtil.resolve(newTheme)
	s._theme = resolved
	variables.activeTheme = resolved
	themeUtil.broadcast(resolved)
end

-- ── Unload ────────────────────────────────────────────────────────────────────

function Window:Unload()
	if self.unloaded then return end
	self.unloaded = true

	local s = (self :: any)
	if s._themeUnsub then s._themeUnsub() end

	if s._activeTween then
		pcall(function() s._activeTween:Cancel() end)
		s._activeTween = nil
	end
	if s._activeAnimConn then
		pcall(function() s._activeAnimConn:Disconnect() end)
		s._activeAnimConn = nil
	end

	for _, conn in s._connections do
		pcall(function() conn:Disconnect() end)
	end
	table.clear(s._connections)

	if s._gestureCleanup then
		pcall(function() s._gestureCleanup() end)
		s._gestureCleanup = nil
	end

	if s._cameraConn then
		pcall(function() s._cameraConn:Disconnect() end)
		s._cameraConn = nil
	end

	if s._playerCard then
		pcall(function() s._playerCard:Destroy() end)
	end

	self._gui:Destroy()

	local tabs: { Tab.Tab } = s._tabs
	for _, tab in tabs do
		tab:Destroy()
	end
end

return Window
