--!strict

-- Delirium UI Library
-- loadingScreen.luau — Full-screen boot overlay with real progress tracking.
--
-- Usage:
--   local LoadingScreen = require(path.to.loadingScreen)
--   local loading = LoadingScreen.new({ title = "MyCheat", accent = Color3.fromHex("#4cc2ff") })
--   loading:setProgress("Initializing...", 5)
--   loading:setProgress("Building interface...", 80)
--   loading:dismiss()   -- snaps to 100%, fades out, destroys itself

local TweenService = game:GetService("TweenService")
local RunService   = game:GetService("RunService")
local Players      = game:GetService("Players")

local FONT_BOLD = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold)
local FONT_MED  = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium)
local FONT_SEMI = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold)

local TW_IN   = TweenInfo.new(0.28, Enum.EasingStyle.Quad,  Enum.EasingDirection.Out)
local TW_OUT  = TweenInfo.new(0.40, Enum.EasingStyle.Quad,  Enum.EasingDirection.In)
local TW_BAR  = TweenInfo.new(0.45, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local TW_SNAP = TweenInfo.new(0.15, Enum.EasingStyle.Quad,  Enum.EasingDirection.Out)

export type LoadingScreenProps = {
	title:    string?,   -- window/cheat name shown in center
	accent:   Color3?,   -- accent bar + badge color
}

export type LoadingScreen = {
	-- Update label and fill the bar to pct (0–100). Safe to call many times.
	setProgress: (self: LoadingScreen, label: string, pct: number) -> (),
	-- Snap to 100%, wait a beat, fade out, destroy ScreenGui.
	dismiss:     (self: LoadingScreen) -> (),
}

local LoadingScreen = {}
LoadingScreen.__index = LoadingScreen

-- ── LoadingScreen.new ─────────────────────────────────────────────────────────

function LoadingScreen.new(props: LoadingScreenProps): LoadingScreen
	local title  = props.title  or "Delirium"
	local accent = props.accent or Color3.fromHex("#4cc2ff")

	-- ── ScreenGui ─────────────────────────────────────────────────────────
	local gui = Instance.new("ScreenGui")
	gui.Name           = "DeliriumLoading"
	gui.DisplayOrder   = 100010        -- above window (99990), popup (100000), everything
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn   = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent         = Players.LocalPlayer:WaitForChild("PlayerGui")

	-- ── Background ────────────────────────────────────────────────────────
	local bg = Instance.new("Frame")
	bg.Name                   = "Bg"
	bg.Size                   = UDim2.fromScale(1, 1)
	bg.BackgroundColor3       = Color3.fromHex("#08080b")
	bg.BackgroundTransparency = 1          -- fade in on boot
	bg.BorderSizePixel        = 0
	bg.ZIndex                 = 1
	bg.Parent                 = gui

	-- Soft radial accent glow — very faint, just depth
	local glow = Instance.new("Frame")
	glow.Name                   = "Glow"
	glow.AnchorPoint            = Vector2.new(0.5, 0.5)
	glow.Position               = UDim2.fromScale(0.5, 0.5)
	glow.Size                   = UDim2.fromOffset(480, 480)
	glow.BackgroundColor3       = accent
	glow.BackgroundTransparency = 0.965
	glow.BorderSizePixel        = 0
	glow.ZIndex                 = 2
	glow.Parent                 = bg
	do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1, 0); c.Parent = glow end

	-- Top accent strip (animates width 0 → 1 on appear)
	local topStrip = Instance.new("Frame")
	topStrip.Name             = "TopStrip"
	topStrip.AnchorPoint      = Vector2.new(0.5, 0)
	topStrip.Position         = UDim2.fromScale(0.5, 0)
	topStrip.Size             = UDim2.new(0, 0, 0, 1)   -- width tweens to 1
	topStrip.BackgroundColor3 = accent
	topStrip.BorderSizePixel  = 0
	topStrip.ZIndex           = 10
	topStrip.Parent           = bg
	do
		local g = Instance.new("UIGradient")
		g.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0.00, 1),
			NumberSequenceKeypoint.new(0.10, 0),
			NumberSequenceKeypoint.new(0.90, 0),
			NumberSequenceKeypoint.new(1.00, 1),
		})
		g.Parent = topStrip
	end

	-- ── Center container (UIListLayout stack) ─────────────────────────────
	local container = Instance.new("Frame")
	container.Name                   = "Container"
	container.AnchorPoint            = Vector2.new(0.5, 0.5)
	container.Position               = UDim2.fromScale(0.5, 0.5)
	container.Size                   = UDim2.new(0, 260, 0, 0)
	container.AutomaticSize          = Enum.AutomaticSize.Y
	container.BackgroundTransparency = 1
	container.ZIndex                 = 5
	container.Parent                 = bg
	do
		local l = Instance.new("UIListLayout")
		l.FillDirection       = Enum.FillDirection.Vertical
		l.HorizontalAlignment = Enum.HorizontalAlignment.Center
		l.VerticalAlignment   = Enum.VerticalAlignment.Top
		l.Padding             = UDim.new(0, 0)
		l.SortOrder           = Enum.SortOrder.LayoutOrder
		l.Parent              = container
	end

	-- Badge wrapper (gives vertical breathing room)
	local badgeWrap = Instance.new("Frame")
	badgeWrap.Name                   = "BadgeWrap"
	badgeWrap.Size                   = UDim2.new(1, 0, 0, 56)
	badgeWrap.BackgroundTransparency = 1
	badgeWrap.LayoutOrder            = 1
	badgeWrap.ZIndex                 = 5
	badgeWrap.Parent                 = container

	local badge = Instance.new("Frame")
	badge.Name             = "Badge"
	badge.AnchorPoint      = Vector2.new(0.5, 0.5)
	badge.Position         = UDim2.fromScale(0.5, 0.5)
	badge.Size             = UDim2.fromOffset(44, 44)
	badge.BackgroundColor3 = accent
	badge.BorderSizePixel  = 0
	badge.ZIndex           = 6
	badge.Parent           = badgeWrap
	do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 10); c.Parent = badge end
	do
		local g = Instance.new("UIGradient")
		g.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.40),
			NumberSequenceKeypoint.new(1, 0.68),
		})
		g.Rotation = 135
		g.Parent   = badge
	end
	local badgeLbl = Instance.new("TextLabel")
	badgeLbl.Size                   = UDim2.fromScale(1, 1)
	badgeLbl.BackgroundTransparency = 1
	badgeLbl.Text                   = string.sub(title, 1, 1):upper()
	badgeLbl.TextColor3             = Color3.fromRGB(255, 255, 255)
	badgeLbl.TextSize               = 22
	badgeLbl.FontFace               = FONT_BOLD
	badgeLbl.TextXAlignment         = Enum.TextXAlignment.Center
	badgeLbl.ZIndex                 = 7
	badgeLbl.Parent                 = badge

	-- Title
	local titleLbl = Instance.new("TextLabel")
	titleLbl.Name                   = "Title"
	titleLbl.Size                   = UDim2.new(1, 0, 0, 22)
	titleLbl.BackgroundTransparency = 1
	titleLbl.Text                   = title
	titleLbl.TextColor3             = Color3.fromRGB(255, 255, 255)
	titleLbl.TextSize               = 17
	titleLbl.FontFace               = FONT_BOLD
	titleLbl.TextXAlignment         = Enum.TextXAlignment.Center
	titleLbl.LayoutOrder            = 2
	titleLbl.ZIndex                 = 5
	titleLbl.Parent                 = container

	-- Gap
	do
		local sp = Instance.new("Frame"); sp.Name = "Sp1"
		sp.Size = UDim2.new(1, 0, 0, 6); sp.BackgroundTransparency = 1
		sp.LayoutOrder = 3; sp.Parent = container
	end

	-- Status label
	local statusLbl = Instance.new("TextLabel")
	statusLbl.Name                   = "Status"
	statusLbl.Size                   = UDim2.new(1, 0, 0, 14)
	statusLbl.BackgroundTransparency = 1
	statusLbl.Text                   = "Starting up..."
	statusLbl.TextColor3             = Color3.fromHex("#52525e")
	statusLbl.TextSize               = 11
	statusLbl.FontFace               = FONT_MED
	statusLbl.TextXAlignment         = Enum.TextXAlignment.Center
	statusLbl.LayoutOrder            = 4
	statusLbl.ZIndex                 = 5
	statusLbl.Parent                 = container

	-- Gap before bar
	do
		local sp = Instance.new("Frame"); sp.Name = "Sp2"
		sp.Size = UDim2.new(1, 0, 0, 22); sp.BackgroundTransparency = 1
		sp.LayoutOrder = 5; sp.Parent = container
	end

	-- Progress track
	local track = Instance.new("Frame")
	track.Name             = "Track"
	track.Size             = UDim2.new(1, 0, 0, 2)
	track.BackgroundColor3 = Color3.fromHex("#16161c")
	track.BorderSizePixel  = 0
	track.LayoutOrder      = 6
	track.ZIndex           = 5
	track.Parent           = container
	do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1, 0); c.Parent = track end

	-- Progress fill
	local fill = Instance.new("Frame")
	fill.Name             = "Fill"
	fill.Size             = UDim2.fromScale(0, 1)
	fill.BackgroundColor3 = accent
	fill.BorderSizePixel  = 0
	fill.ZIndex           = 6
	fill.Parent           = track
	do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1, 0); c.Parent = fill end
	do
		-- Subtle left-to-right brightness gradient on fill
		local g = Instance.new("UIGradient")
		g.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.20),
			NumberSequenceKeypoint.new(1, 0),
		})
		g.Parent = fill
	end

	-- Gap after bar
	do
		local sp = Instance.new("Frame"); sp.Name = "Sp3"
		sp.Size = UDim2.new(1, 0, 0, 10); sp.BackgroundTransparency = 1
		sp.LayoutOrder = 7; sp.Parent = container
	end

	-- Percentage
	local pctLbl = Instance.new("TextLabel")
	pctLbl.Name                   = "Pct"
	pctLbl.Size                   = UDim2.new(1, 0, 0, 12)
	pctLbl.BackgroundTransparency = 1
	pctLbl.Text                   = "0%"
	pctLbl.TextColor3             = Color3.fromHex("#2a2a34")
	pctLbl.TextSize               = 10
	pctLbl.FontFace               = FONT_SEMI
	pctLbl.TextXAlignment         = Enum.TextXAlignment.Center
	pctLbl.LayoutOrder            = 8
	pctLbl.ZIndex                 = 5
	pctLbl.Parent                 = container

	-- ── Boot animations ───────────────────────────────────────────────────

	-- Fade in background
	TweenService:Create(bg, TW_IN, { BackgroundTransparency = 0 }):Play()

	-- Accent strip sweeps across after a short delay
	task.delay(0.12, function()
		TweenService:Create(topStrip, TweenInfo.new(0.55, Enum.EasingStyle.Quad), {
			Size = UDim2.new(1, 0, 0, 1),
		}):Play()
	end)

	-- Badge breathing pulse (Heartbeat)
	local shimmerT  = 0
	local shimmerConn: RBXScriptConnection = RunService.Heartbeat:Connect(function(dt)
		shimmerT += dt
		-- gentle sine pulse 0.0 → 0.14 transparency
		badge.BackgroundTransparency = 0.03 + (math.sin(shimmerT * 2.2) + 1) * 0.07
	end)

	-- ── Build self ────────────────────────────────────────────────────────
	local self: LoadingScreen = setmetatable({}, LoadingScreen) :: any
	local s = self :: any
	s._gui         = gui
	s._bg          = bg
	s._fill        = fill
	s._statusLbl   = statusLbl
	s._pctLbl      = pctLbl
	s._shimmerConn = shimmerConn
	s._dismissed   = false
	s._activeFill  = nil  -- active fill tween reference

	return self
end

-- ── Methods ───────────────────────────────────────────────────────────────────

function LoadingScreen:setProgress(label: string, pct: number)
	local s = self :: any
	if s._dismissed then return end

	local clamped = math.clamp(pct, 0, 100)

	s._statusLbl.Text = label
	s._pctLbl.Text    = math.round(clamped) .. "%"

	-- Cancel previous bar tween to avoid fighting
	if s._activeFill then
		pcall(function() (s._activeFill :: Tween):Cancel() end)
	end
	local tw = TweenService:Create(s._fill, TW_BAR, {
		Size = UDim2.fromScale(clamped / 100, 1),
	})
	s._activeFill = tw
	tw:Play()
end

function LoadingScreen:dismiss()
	local s = self :: any
	if s._dismissed then return end
	s._dismissed = true

	-- Stop pulse
	if s._shimmerConn then
		s._shimmerConn:Disconnect()
		s._shimmerConn = nil
	end

	-- Cancel pending bar tween
	if s._activeFill then
		pcall(function() (s._activeFill :: Tween):Cancel() end)
		s._activeFill = nil
	end

	-- Snap status + bar to completion
	s._statusLbl.Text = "Ready."
	s._pctLbl.Text    = "100%"
	TweenService:Create(s._fill, TW_SNAP, { Size = UDim2.fromScale(1, 1) }):Play()

	-- Brief pause so user sees 100%, then fade entire screen out
	task.delay(0.22, function()
		local fadeTw = TweenService:Create(
			s._bg :: Frame,
			TW_OUT,
			{ BackgroundTransparency = 1 }
		)
		fadeTw:Play()
		fadeTw.Completed:Once(function()
			fadeTw:Destroy()
			if s._gui and s._gui.Parent then
				s._gui:Destroy()
			end
		end)
	end)
end

return LoadingScreen
