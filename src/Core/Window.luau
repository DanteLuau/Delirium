--!strict

local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local Players          = game:GetService("Players")

local Maid         = require(script.Parent.Parent.Utils.Maid)
local Theme        = require(script.Parent.Parent.Theme)
local Components   = require(script.Parent.Parent.Components)
local SmoothScroll = require(script.Parent.Parent.Utils.SmoothScroll)
local Tab          = require(script.Parent.Tab)
local Notification = require(script.Parent.Notification)

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
	self._pillBg        = nil :: any
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
		self._maid:GiveTask((searchBtn_w :: TextButton).MouseButton1Click:Connect(function()
			Notification.notify({ Title = "Search", Message = "Coming soon.", Type = "info", Duration = 3 })
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
	-- PillBg: gradient + samar outline — shown only while the window is hidden (pill state).
	-- CanvasGroup's UICorner already clips this to the pill silhouette; no corner needed here.
	local pillBg                 = Instance.new("Frame")
	pillBg.Name                  = "PillBg"
	pillBg.Size                  = UDim2.fromScale(1, 1)
	pillBg.BackgroundColor3      = Color3.fromHex("#1e1e1e")
	pillBg.BorderSizePixel       = 0
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
	pillBgStroke.Transparency    = 0.35
	pillBgStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	pillBgStroke.Parent          = pillBg
	pillBg.Parent                = self._canvas
	self._pillBg                 = pillBg

	-- dot: kept as a zero-size stub so Hide/Show refs remain valid
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

	-- title: current game name, centered
	local pillTitle                  = Instance.new("TextLabel")
	pillTitle.Name                   = "PillTitle"
	pillTitle.AnchorPoint            = Vector2.new(0.5, 0.5)
	pillTitle.Position               = UDim2.new(0.5, 0, 0.5, -8)
	pillTitle.Size                   = UDim2.new(1, -24, 0, 16)
	pillTitle.BackgroundTransparency = 1
	pillTitle.Font                   = Theme.Font.Title
	pillTitle.Text                   = self.Title  -- show window title, not game name
	pillTitle.TextSize               = 12
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
	pillSub.Position                 = UDim2.new(0.5, 0, 0.5, 8)
	pillSub.Size                     = UDim2.new(1, -24, 0, 11)
	pillSub.BackgroundTransparency   = 1
	pillSub.Font                     = Theme.Font.Body
	pillSub.Text                     = "tap to show"
	pillSub.TextSize                 = 10
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

	-- Pill background: show immediately so the gradient is visible during morph
	if self._pillBg then self._pillBg.Visible = true end

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
		-- pill bg goes away once the window chrome is revealed
		if self._pillBg then self._pillBg.Visible = false end
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
