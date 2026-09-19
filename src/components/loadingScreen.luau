--!strict

-- Delirium UI Library
-- loadingScreen.luau — Centered pill boot overlay.
--
-- Usage:
--   local loading = Delirium.LoadingScreen.new({ title = "MyCheat" })
--   loading:update("Initializing...")
--   task.wait(1)
--   loading:dismiss(window)   -- pill fades out, then window fades in

local TweenService = game:GetService("TweenService")
local RunService   = game:GetService("RunService")

local variables  = require(script.Parent.Parent.utility.variables)
local constants  = require(script.Parent.Parent.utility.constants)

local FONT_BOLD = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold)
local FONT_MED  = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium)

local TW_FADE_IN  = TweenInfo.new(0.30, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TW_FADE_OUT = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

export type LoadingScreenProps = {
	title:  string?,
	accent: Color3?,
}

export type LoadingScreen = {
	update:  (self: LoadingScreen, status: string) -> (),
	dismiss: (self: LoadingScreen, window: any?)   -> (),
}

local LoadingScreen = {}
LoadingScreen.__index = LoadingScreen

-- ── LoadingScreen.new ─────────────────────────────────────────────────────────

function LoadingScreen.new(props: LoadingScreenProps): LoadingScreen
	local title  = props.title  or "Delirium"
	local accent = props.accent or Color3.fromHex("#4cc2ff")

	-- ── ScreenGui — same container as window so DisplayOrder works ──────────
	local gui = Instance.new("ScreenGui")
	gui.Name            = "DeliriumLoading"
	gui.DisplayOrder    = constants.displayOrder.loading  -- 100010, above window
	gui.IgnoreGuiInset  = true
	gui.ResetOnSpawn    = false
	gui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
	gui.Parent          = variables.guiContainer

	-- ── Pill container ──────────────────────────────────────────────────────
	local pill = Instance.new("Frame")
	pill.Name                   = "Pill"
	pill.AnchorPoint            = Vector2.new(0.5, 0.5)
	pill.Position               = UDim2.fromScale(0.5, 0.5)
	pill.Size                   = UDim2.fromOffset(300, 60)
	pill.BackgroundColor3       = Color3.fromHex("#0e0e12")
	pill.BackgroundTransparency = 1    -- starts transparent, fades in
	pill.BorderSizePixel        = 0
	pill.ZIndex                 = 2
	pill.Parent                 = gui
	do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1, 0); c.Parent = pill end

	-- Subtle stroke
	local stroke = Instance.new("UIStroke")
	stroke.Color       = Color3.fromHex("#1e1e26")
	stroke.Thickness   = 1
	stroke.Transparency = 1    -- fades in with pill
	stroke.Parent      = pill

	-- Horizontal layout inside pill
	local layout = Instance.new("UIListLayout")
	layout.FillDirection       = Enum.FillDirection.Horizontal
	layout.VerticalAlignment   = Enum.VerticalAlignment.Center
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	layout.Padding             = UDim.new(0, 12)
	layout.SortOrder           = Enum.SortOrder.LayoutOrder
	layout.Parent              = pill

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft   = UDim.new(0, 16)
	padding.PaddingRight  = UDim.new(0, 16)
	padding.Parent        = pill

	-- Badge
	local badge = Instance.new("Frame")
	badge.Name             = "Badge"
	badge.Size             = UDim2.fromOffset(32, 32)
	badge.BackgroundColor3 = accent
	badge.BorderSizePixel  = 0
	badge.ZIndex           = 3
	badge.LayoutOrder      = 1
	badge.Parent           = pill
	do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = badge end
	do
		local g = Instance.new("UIGradient")
		g.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.35),
			NumberSequenceKeypoint.new(1, 0.65),
		})
		g.Rotation = 135
		g.Parent   = badge
	end

	local badgeLbl = Instance.new("TextLabel")
	badgeLbl.Size                   = UDim2.fromScale(1, 1)
	badgeLbl.BackgroundTransparency = 1
	badgeLbl.Text                   = string.sub(title, 1, 1):upper()
	badgeLbl.TextColor3             = Color3.fromRGB(255, 255, 255)
	badgeLbl.TextSize               = 16
	badgeLbl.FontFace               = FONT_BOLD
	badgeLbl.TextXAlignment         = Enum.TextXAlignment.Center
	badgeLbl.ZIndex                 = 4
	badgeLbl.Parent                 = badge

	-- Text stack
	local textStack = Instance.new("Frame")
	textStack.Name                   = "TextStack"
	textStack.Size                   = UDim2.new(1, -76, 1, 0)  -- fill remaining width
	textStack.BackgroundTransparency = 1
	textStack.LayoutOrder            = 2
	textStack.ZIndex                 = 3
	textStack.Parent                 = pill
	do
		local l = Instance.new("UIListLayout")
		l.FillDirection       = Enum.FillDirection.Vertical
		l.VerticalAlignment   = Enum.VerticalAlignment.Center
		l.HorizontalAlignment = Enum.HorizontalAlignment.Left
		l.Padding             = UDim.new(0, 2)
		l.SortOrder           = Enum.SortOrder.LayoutOrder
		l.Parent              = textStack
	end

	local titleLbl = Instance.new("TextLabel")
	titleLbl.Name                   = "Title"
	titleLbl.Size                   = UDim2.new(1, 0, 0, 18)
	titleLbl.BackgroundTransparency = 1
	titleLbl.Text                   = title
	titleLbl.TextColor3             = Color3.fromRGB(230, 230, 240)
	titleLbl.TextSize               = 13
	titleLbl.FontFace               = FONT_BOLD
	titleLbl.TextXAlignment         = Enum.TextXAlignment.Left
	titleLbl.TextTruncate           = Enum.TextTruncate.AtEnd
	titleLbl.LayoutOrder            = 1
	titleLbl.ZIndex                 = 4
	titleLbl.Parent                 = textStack

	local statusLbl = Instance.new("TextLabel")
	statusLbl.Name                   = "Status"
	statusLbl.Size                   = UDim2.new(1, 0, 0, 14)
	statusLbl.BackgroundTransparency = 1
	statusLbl.Text                   = "Starting up..."
	statusLbl.TextColor3             = Color3.fromHex("#52525e")
	statusLbl.TextSize               = 11
	statusLbl.FontFace               = FONT_MED
	statusLbl.TextXAlignment         = Enum.TextXAlignment.Left
	statusLbl.TextTruncate           = Enum.TextTruncate.AtEnd
	statusLbl.LayoutOrder            = 2
	statusLbl.ZIndex                 = 4
	statusLbl.Parent                 = textStack

	-- ── Fade in pill ────────────────────────────────────────────────────────
	TweenService:Create(pill,   TW_FADE_IN, { BackgroundTransparency = 0   }):Play()
	TweenService:Create(stroke, TW_FADE_IN, { Transparency           = 0   }):Play()

	-- Badge heartbeat pulse
	local pulseT: number = 0
	local pulseConn: RBXScriptConnection = RunService.Heartbeat:Connect(function(dt)
		pulseT += dt
		badge.BackgroundTransparency = 0.02 + (math.sin(pulseT * 2.2) + 1) * 0.06
	end)

	-- ── Build self ──────────────────────────────────────────────────────────
	local self: LoadingScreen = setmetatable({}, LoadingScreen) :: any
	local s = self :: any
	s._gui        = gui
	s._pill       = pill
	s._stroke     = stroke
	s._statusLbl  = statusLbl
	s._pulseConn  = pulseConn
	s._dismissed  = false

	return self
end

-- ── Methods ───────────────────────────────────────────────────────────────────

-- Update the status text shown inside the pill.
function LoadingScreen:update(status: string)
	local s = self :: any
	if s._dismissed then return end
	s._statusLbl.Text = status
end

-- Fade out pill, then show window (if passed), then destroy.
function LoadingScreen:dismiss(window: any?)
	local s = self :: any
	if s._dismissed then return end
	s._dismissed = true

	-- Stop pulse
	if s._pulseConn then
		s._pulseConn:Disconnect()
		s._pulseConn = nil
	end

	-- Fade pill out
	local pillOut = TweenService:Create(s._pill,   TW_FADE_OUT, { BackgroundTransparency = 1 })
	local strokeOut = TweenService:Create(s._stroke, TW_FADE_OUT, { Transparency           = 1 })
	pillOut:Play()
	strokeOut:Play()

	pillOut.Completed:Once(function()
		pillOut:Destroy()
		strokeOut:Destroy()

		-- Destroy loading screen gui
		if s._gui and s._gui.Parent then
			s._gui:Destroy()
		end

		-- Show window after pill is gone
		if window and not window.unloaded then
			window:Show()
		end
	end)
end

return LoadingScreen
