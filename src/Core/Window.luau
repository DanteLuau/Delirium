--!strict

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
