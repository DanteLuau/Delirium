--!strict

-- Delirium UI Library
-- loadingScreen.luau — Centered pill boot overlay with smooth morph transition into Window.

local TweenService = game:GetService("TweenService")
local RunService   = game:GetService("RunService")

local variables = require(script.Parent.Parent.utility.variables)
local constants = require(script.Parent.Parent.utility.constants)

local FONT_BOLD = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold)
local FONT_MED  = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium)

local TW_FADE_IN = TweenInfo.new(0.30, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TW_MORPH   = TweenInfo.new(0.48, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local TW_CONTENT = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

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

function LoadingScreen.new(props: LoadingScreenProps): LoadingScreen
	local title  = props.title  or "Delirium"
	local accent = props.accent or Color3.fromHex("#4cc2ff")

	local gui = Instance.new("ScreenGui")
	gui.Name            = "DeliriumLoading"
	gui.DisplayOrder    = constants.displayOrder.loading -- 100010, above window
	gui.IgnoreGuiInset  = true
	gui.ResetOnSpawn    = false
	gui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
	gui.Parent          = variables.guiContainer

	local pill = Instance.new("Frame")
	pill.Name                   = "Pill"
	pill.AnchorPoint            = Vector2.new(0.5, 0.5)
	pill.Position               = UDim2.fromScale(0.5, 0.5)
	pill.Size                   = UDim2.fromOffset(300, 60)
	pill.BackgroundColor3       = Color3.fromHex("#0e0e12")
	pill.BackgroundTransparency = 1
	pill.BorderSizePixel        = 0
	pill.ClipsDescendants       = true
	pill.ZIndex                 = 2
	pill.Parent                 = gui

	local pillCorner = Instance.new("UICorner")
	pillCorner.CornerRadius = UDim.new(1, 0)
	pillCorner.Parent       = pill

	local stroke = Instance.new("UIStroke")
	stroke.Color        = Color3.fromHex("#1e1e26")
	stroke.Thickness    = 1
	stroke.Transparency = 1
	stroke.Parent       = pill

	-- Internal content container (fades out immediately when morph begins)
	local content = Instance.new("Frame")
	content.Name                   = "Content"
	content.Size                   = UDim2.fromScale(1, 1)
	content.BackgroundTransparency = 1
	content.BorderSizePixel        = 0
	content.ZIndex                 = 3
	content.Parent                 = pill

	local layout = Instance.new("UIListLayout")
	layout.FillDirection       = Enum.FillDirection.Horizontal
	layout.VerticalAlignment   = Enum.VerticalAlignment.Center
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	layout.Padding             = UDim.new(0, 12)
	layout.SortOrder           = Enum.SortOrder.LayoutOrder
	layout.Parent              = content

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft  = UDim.new(0, 16)
	padding.PaddingRight = UDim.new(0, 16)
	padding.Parent       = content

	local badge = Instance.new("Frame")
	badge.Name             = "Badge"
	badge.Size             = UDim2.fromOffset(32, 32)
	badge.BackgroundColor3 = accent
	badge.BorderSizePixel  = 0
	badge.ZIndex           = 4
	badge.LayoutOrder      = 1
	badge.Parent           = content
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
	badgeLbl.ZIndex                 = 5
	badgeLbl.Parent                 = badge

	local textStack = Instance.new("Frame")
	textStack.Name                   = "TextStack"
	textStack.Size                   = UDim2.new(1, -76, 1, 0)
	textStack.BackgroundTransparency = 1
	textStack.LayoutOrder            = 2
	textStack.ZIndex                 = 4
	textStack.Parent                 = content
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
	titleLbl.ZIndex                 = 5
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
	statusLbl.ZIndex                 = 5
	statusLbl.Parent                 = textStack

	TweenService:Create(pill,   TW_FADE_IN, { BackgroundTransparency = 0 }):Play()
	TweenService:Create(stroke, TW_FADE_IN, { Transparency           = 0 }):Play()

	local pulseT = 0
	local pulseConn = RunService.Heartbeat:Connect(function(dt)
		pulseT += dt
		badge.BackgroundTransparency = 0.02 + (math.sin(pulseT * 2.2) + 1) * 0.06
	end)

	local self: LoadingScreen = setmetatable({}, LoadingScreen) :: any
	local s = self :: any
	s._gui        = gui
	s._pill       = pill
	s._pillCorner = pillCorner
	s._stroke     = stroke
	s._content    = content
	s._badge      = badge
	s._badgeLbl   = badgeLbl
	s._titleLbl   = titleLbl
	s._statusLbl  = statusLbl
	s._pulseConn  = pulseConn
	s._dismissed  = false

	return self
end

function LoadingScreen:update(status: string)
	local s = self :: any
	if s._dismissed then return end
	s._statusLbl.Text = status
end

-- Morph pill into window size & position, seamless handoff
function LoadingScreen:dismiss(window: any?)
	local s = self :: any
	if s._dismissed then return end
	s._dismissed = true

	if s._pulseConn then
		s._pulseConn:Disconnect()
		s._pulseConn = nil
	end

	local winFrame: Frame? = if window then (window._windowFrame or (window :: any)._frame) else nil

	-- Fade out text & badge first
	TweenService:Create(s._badge,    TW_CONTENT, { BackgroundTransparency = 1 }):Play()
	TweenService:Create(s._badgeLbl, TW_CONTENT, { TextTransparency       = 1 }):Play()
	TweenService:Create(s._titleLbl, TW_CONTENT, { TextTransparency       = 1 }):Play()
	local fadeOutText = TweenService:Create(s._statusLbl, TW_CONTENT, { TextTransparency = 1 })
	fadeOutText:Play()

	if winFrame and not window.unloaded then
		local winTargetSize = window._windowSize or winFrame.Size
		local winTargetPos  = winFrame.Position
		local winCornerVal  = if window._winCorner then window._winCorner.CornerRadius else UDim.new(0, 10)
		local winStrokeVal  = if window._winStroke then window._winStroke.Color else Color3.fromHex("#1e1e26")

		-- Prepare window invisibly underneath pill
		winFrame.BackgroundTransparency = 0
		winFrame.Visible = true

		-- Hide internal window parts briefly during morph so they don't jump/flash
		local winBody: Frame? = window._body
		local winTitle: Frame? = window._titleBar
		if winBody then winBody.Visible = false end
		if winTitle then winTitle.Visible = false end

		-- Morph the pill frame into the exact size & roundness of windowFrame
		local morphSize   = TweenService:Create(s._pill,       TW_MORPH, { Size = winTargetSize, Position = winTargetPos })
		local morphCorner = TweenService:Create(s._pillCorner, TW_MORPH, { CornerRadius = winCornerVal })
		local morphStroke = TweenService:Create(s._stroke,     TW_MORPH, { Color = winStrokeVal })

		morphSize:Play()
		morphCorner:Play()
		morphStroke:Play()

		morphSize.Completed:Once(function()
			morphSize:Destroy()
			morphCorner:Destroy()
			morphStroke:Destroy()

			-- Show window children smoothly
			if winBody then winBody.Visible = true end
			if winTitle then winTitle.Visible = true end
			window:Show()

			-- Cleanly destroy loading screen without any blink
			if s._gui and s._gui.Parent then
				s._gui:Destroy()
			end
		end)
	else
		-- Fallback if no window passed: simple fade out
		local pillOut   = TweenService:Create(s._pill,   TW_MORPH, { BackgroundTransparency = 1 })
		local strokeOut = TweenService:Create(s._stroke, TW_MORPH, { Transparency           = 1 })
		pillOut:Play()
		strokeOut:Play()

		pillOut.Completed:Once(function()
			pillOut:Destroy()
			strokeOut:Destroy()
			if s._gui and s._gui.Parent then
				s._gui:Destroy()
			end
		end)
	end
end

return LoadingScreen
