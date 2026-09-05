--!strict

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
