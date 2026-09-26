--!strict

-- Delirium UI Library
-- notification.luau — oldsrc-parity redesign.
-- CanvasGroup cards, icon badge, bottom accent glow, stacking eviction (max 6),
-- live timestamp loop, close-btn hover, Cubic.Out slide animations.

local constants = require(script.Parent.Parent.utility.constants)
local variables = require(script.Parent.Parent.utility.variables)
local tween     = require(script.Parent.Parent.utility.tween)

-- ── Constants ─────────────────────────────────────────────────────────────────

local TOAST_W          = 276
local MAX_VISIBLE      = 6
local GAP              = 6
local SLIDE_IN_OFFSET  = 45
local SLIDE_OUT_OFFSET = 85
local MOBILE_SCALE     = 0.65

local TWEEN_IN_SIZE  = TweenInfo.new(0.42, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
local TWEEN_IN_POS   = TweenInfo.new(0.44, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
local TWEEN_IN_FADE  = TweenInfo.new(0.38, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
local TWEEN_OUT_SIZE = TweenInfo.new(0.38, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
local TWEEN_OUT_POS  = TweenInfo.new(0.40, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
local TWEEN_OUT_FADE = TweenInfo.new(0.32, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)

local DEFAULT_ICONS: { [string]: string } = {
	info    = "rbxassetid://10723415903",
	success = "rbxassetid://10709790387",
	warning = "rbxassetid://10709752935",
	error   = "rbxassetid://10747384394",
}

-- ── Types ─────────────────────────────────────────────────────────────────────

export type NotifyProps = {
	title:    string?,
	content:  string?,
	duration: number?,
	type:     string?,           -- "info" | "success" | "warning" | "error"
	icon:     (string | number)?,
}

type ActiveToast = {
	wrapper:      Frame,
	card:         CanvasGroup,
	stroke:       UIStroke,
	dismissed:    boolean,
	cancelTimer:  () -> (),
	timeLabel:    TextLabel,
	creationTime: number,
}

-- ── Singleton State ───────────────────────────────────────────────────────────

local _gui          : ScreenGui?      = nil
local _container    : Frame?          = nil
local _layout       : UIListLayout?   = nil
local _active       : { ActiveToast } = {}
local _orderCounter : number          = 0
local _scale        : number          = 1
local _clockThread  : thread?         = nil

-- ── Helpers ───────────────────────────────────────────────────────────────────

local function typeColor(notifType: string?, theme: { [string]: any }): Color3
	local t = string.lower(notifType or "info")
	if     t == "success" then return Color3.fromHex("#3ecf8e")
	elseif t == "warning" then return Color3.fromHex("#f5a524")
	elseif t == "error"   then return theme.ErrorColor or Color3.fromHex("#ff4f58")
	else                       return theme.AccentColor or Color3.fromHex("#4cc2ff")
	end
end

local function resolveIcon(icon: (string | number)?, notifType: string?): string
	if type(icon) == "number" then
		return "rbxassetid://" .. tostring(icon)
	elseif type(icon) == "string" and #icon > 0 then
		if string.sub(icon, 1, 13) == "rbxassetid://" or string.sub(icon, 1, 4) == "http" then
			return icon
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

	-- Escalate identity: notification.send() can be called from a task.spawn/deferred
	-- thread, which drops to identity 2 and can't parent into guiContainer (CoreGui/PluginGui).
	local _sti = typeof(setthreadidentity) == "function" and setthreadidentity
		or typeof(set_thread_identity) == "function" and set_thread_identity
		or nil
	if _sti then pcall(_sti, 8) end

	local isMobile = variables.userInputService.TouchEnabled and not variables.userInputService.KeyboardEnabled
	if not variables.runService:IsStudio() then
		local cam = workspace.CurrentCamera
		local vp  = if cam then cam.ViewportSize else Vector2.new(1024, 768)
		if vp.X < 800 or vp.Y < 600 then isMobile = true end
	end
	_scale = if isMobile then MOBILE_SCALE else 1

	local gui = Instance.new("ScreenGui")
	gui.Name             = "DeliriumNotifications"
	gui.DisplayOrder     = constants.displayOrder.notification
	gui.ResetOnSpawn     = false
	gui.IgnoreGuiInset   = true
	gui.ZIndexBehavior   = Enum.ZIndexBehavior.Sibling

	gui.Parent           = variables.guiContainer

	local scaledW = math.round(TOAST_W * _scale)

	local c = Instance.new("Frame")
	c.Name                   = "Container"
	c.Size                   = UDim2.fromOffset(scaledW, 0)
	c.AutomaticSize          = Enum.AutomaticSize.Y
	c.BackgroundTransparency = 1
	c.BorderSizePixel        = 0
	c.ClipsDescendants       = false

	local layout = Instance.new("UIListLayout")
	layout.SortOrder           = Enum.SortOrder.LayoutOrder
	layout.FillDirection       = Enum.FillDirection.Vertical
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	layout.Padding             = UDim.new(0, GAP)

	if isMobile then
		c.AnchorPoint          = Vector2.new(1, 0)
		c.Position             = UDim2.new(1, -12, 0, 44)
		layout.VerticalAlignment = Enum.VerticalAlignment.Top
	else
		c.AnchorPoint          = Vector2.new(1, 1)
		c.Position             = UDim2.new(1, -16, 1, -16)
		layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	end

	layout.Parent = c
	c.Parent      = gui

	_gui       = gui
	_container = c
	_layout    = layout
end

-- ── Centralized Clock Loop ───────────────────────────────────────────────────

local function stopClock()
	if #_active == 0 and _clockThread then
		task.cancel(_clockThread)
		_clockThread = nil
	end
end

local function startClock()
	if _clockThread then return end
	_clockThread = task.spawn(function()
		while #_active > 0 do
			task.wait(1)
			local now = tick()
			for _, toast in ipairs(_active) do
				if not toast.dismissed and toast.timeLabel then
					toast.timeLabel.Text = formatElapsed(now - toast.creationTime)
				end
			end
		end
		_clockThread = nil
	end)
end

-- ── Dismiss ───────────────────────────────────────────────────────────────────

local function dismissToast(toast: ActiveToast)
	if toast.dismissed then return end
	toast.dismissed = true
	toast.cancelTimer()

	local idx = table.find(_active, toast)
	if idx then table.remove(_active, idx) end
	stopClock()

	local s   = _scale
	tween.fire(toast.card, TWEEN_OUT_POS, {
		Position = UDim2.fromOffset(math.round(SLIDE_OUT_OFFSET * s), 0),
	})
	tween.fire(toast.card, TWEEN_OUT_FADE, {
		GroupTransparency = 1,
	})
	if toast.stroke and toast.stroke.Parent then
		tween.fire(toast.stroke, TWEEN_OUT_FADE, {
			Transparency = 1,
		})
	end
	local sizeTween = tween.play(toast.wrapper, TWEEN_OUT_SIZE, {
		Size = UDim2.new(1, 0, 0, 0),
	})
	sizeTween.Completed:Once(function()
		-- A5 FIX: destroy the Tween object so it doesn't leak. tween.fire() already
		-- does this; tween.play() callers must manage it themselves at the call site.
		sizeTween:Destroy()
		if toast.wrapper.Parent then toast.wrapper:Destroy() end
	end)
end

-- ── Public API ────────────────────────────────────────────────────────────────

local notification = {}

function notification.send(props: NotifyProps, theme: { [string]: any }?)
	ensureGui()

	local resolvedTheme = theme or variables.activeTheme or {}

	-- Evict oldest when full
	while #_active >= MAX_VISIBLE do
		local oldest = _active[1]
		if oldest then dismissToast(oldest) else break end
	end

	local titleText = props.title   or "Notification"
	local msgText   = props.content or ""
	local notifType = props.type    or "info"
	local accent    = typeColor(notifType, resolvedTheme)
	local iconId    = resolveIcon(props.icon, notifType)

	local duration: number
	if props.duration and props.duration > 0 then
		duration = props.duration
	elseif props.duration and props.duration <= 0 then
		duration = -1
	else
		duration = math.clamp((#msgText * 0.08) + 3, 3.5, 10)
	end

	_orderCounter += 1
	local order = _orderCounter
	local s     = _scale

	local function px(n: number): number return math.max(math.round(n * s), 1) end
	local ts = math.max(math.round(s * 12), 8)   -- title size
	local ms = math.max(math.round(s * 11), 8)   -- message size
	local xs = math.max(math.round(s * 10), 7)   -- timestamp size
	local cs = math.max(math.round(s * 13), 8)   -- close btn size

	-- ── Target height ─────────────────────────────────────────────────────────
	local usableW    = math.round(TOAST_W * s) - px(59)
	local textBounds = variables.textService:GetTextSize(
		msgText, ms,
		Enum.Font.GothamMedium,
		Vector2.new(math.max(usableW, 40), 2000)
	)
	local headerH  = px(16)
	local msgH     = if #msgText > 0 then math.max(textBounds.Y, px(13)) else 0
	local bodyH    = if msgH > 0 then (headerH + px(3) + msgH) else headerH
	local contentH = math.max(bodyH, px(28))
	local targetH  = px(20) + contentH

	-- ── Slot wrapper (animates to 0 on dismiss for smooth stack reflow) ────────
	local wrapper = Instance.new("Frame")
	wrapper.Name                   = "ToastSlot"
	wrapper.Size                   = UDim2.new(1, 0, 0, 0)
	wrapper.BackgroundTransparency = 1
	wrapper.BorderSizePixel        = 0
	wrapper.ClipsDescendants       = false
	wrapper.LayoutOrder            = order
	wrapper.Parent                 = _container

	-- ── Card (CanvasGroup = GroupTransparency tween, whole card fades as one) ──
	local card = Instance.new("CanvasGroup")
	card.Name                  = "ToastCard"
	card.Size                  = UDim2.new(1, 0, 0, targetH)
	card.Position              = UDim2.fromOffset(math.round(SLIDE_IN_OFFSET * s), 0)
	card.BackgroundColor3      = Color3.fromHex("#1a1a1a")
	card.BorderSizePixel       = 0
	card.GroupTransparency     = 1
	card.ClipsDescendants      = true
	card.Parent                = wrapper

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, px(8))
	corner.Parent = card

	local stroke = Instance.new("UIStroke")
	stroke.Color               = Color3.fromHex("#303038")
	stroke.Thickness           = 1
	stroke.Transparency        = 1
	stroke.ApplyStrokeMode     = Enum.ApplyStrokeMode.Border
	stroke.Parent              = card

	-- ── Bottom accent glow bar ────────────────────────────────────────────────
	local bottomGlow = Instance.new("Frame")
	bottomGlow.Name             = "BottomGlow"
	bottomGlow.Position         = UDim2.new(0, 0, 1, -1)
	bottomGlow.Size             = UDim2.new(1, 0, 0, 1)
	bottomGlow.BackgroundColor3 = accent
	bottomGlow.BorderSizePixel  = 0
	bottomGlow.ZIndex           = 3
	bottomGlow.Parent           = card

	local glowGrad = Instance.new("UIGradient")
	glowGrad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0,    1),
		NumberSequenceKeypoint.new(0.35, 0.45),
		NumberSequenceKeypoint.new(0.65, 0.45),
		NumberSequenceKeypoint.new(1,    1),
	})
	glowGrad.Parent = bottomGlow

	-- ── Two-column row ────────────────────────────────────────────────────────
	local row = Instance.new("Frame")
	row.Name                   = "Row"
	row.Position               = UDim2.fromOffset(px(11), px(10))
	row.Size                   = UDim2.new(1, -px(22), 0, contentH)
	row.BackgroundTransparency = 1
	row.BorderSizePixel        = 0
	row.ZIndex                 = 2
	row.Parent                 = card

	local rLayout = Instance.new("UIListLayout")
	rLayout.FillDirection     = Enum.FillDirection.Horizontal
	rLayout.VerticalAlignment = Enum.VerticalAlignment.Top
	rLayout.SortOrder         = Enum.SortOrder.LayoutOrder
	rLayout.Padding           = UDim.new(0, px(9))
	rLayout.Parent            = row

	-- ── Icon badge ────────────────────────────────────────────────────────────
	local iconBadge = Instance.new("Frame")
	iconBadge.Name                   = "IconBadge"
	iconBadge.LayoutOrder            = 1
	iconBadge.Size                   = UDim2.fromOffset(px(28), px(28))
	iconBadge.BackgroundColor3       = accent
	iconBadge.BackgroundTransparency = 0.86
	iconBadge.BorderSizePixel        = 0
	iconBadge.Parent                 = row

	local badgeCorner = Instance.new("UICorner")
	badgeCorner.CornerRadius = UDim.new(0, px(7))
	badgeCorner.Parent = iconBadge

	local badgeStroke = Instance.new("UIStroke")
	badgeStroke.Color           = accent
	badgeStroke.Thickness       = 1
	badgeStroke.Transparency    = 0.65
	badgeStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	badgeStroke.Parent          = iconBadge

	local iconImg = Instance.new("ImageLabel")
	iconImg.Name                   = "Icon"
	iconImg.AnchorPoint            = Vector2.new(0.5, 0.5)
	iconImg.Position               = UDim2.fromScale(0.5, 0.5)
	iconImg.Size                   = UDim2.fromOffset(px(14), px(14))
	iconImg.BackgroundTransparency = 1
	iconImg.Image                  = iconId
	iconImg.ImageColor3            = accent
	iconImg.Parent                 = iconBadge

	-- ── Text column ───────────────────────────────────────────────────────────
	local col = Instance.new("Frame")
	col.Name                   = "Col"
	col.LayoutOrder            = 2
	col.Size                   = UDim2.new(1, -px(37), 0, 0)
	col.AutomaticSize          = Enum.AutomaticSize.Y
	col.BackgroundTransparency = 1
	col.BorderSizePixel        = 0
	col.Parent                 = row

	local colLayout = Instance.new("UIListLayout")
	colLayout.FillDirection     = Enum.FillDirection.Vertical
	colLayout.SortOrder         = Enum.SortOrder.LayoutOrder
	colLayout.Padding           = UDim.new(0, px(3))
	colLayout.Parent            = col

	-- ── Header row (title | spacer | timestamp | close) ──────────────────────
	local header = Instance.new("Frame")
	header.Name                   = "Header"
	header.LayoutOrder            = 1
	header.Size                   = UDim2.new(1, 0, 0, headerH)
	header.BackgroundTransparency = 1
	header.BorderSizePixel        = 0
	header.Parent                 = col

	local hLayout = Instance.new("UIListLayout")
	hLayout.FillDirection     = Enum.FillDirection.Horizontal
	hLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	hLayout.SortOrder         = Enum.SortOrder.LayoutOrder
	hLayout.Padding           = UDim.new(0, px(4))
	hLayout.Parent            = header

	local titleLbl = Instance.new("TextLabel")
	titleLbl.Name                   = "Title"
	titleLbl.LayoutOrder            = 1
	titleLbl.AutomaticSize          = Enum.AutomaticSize.X
	titleLbl.Size                   = UDim2.new(0, 0, 1, 0)
	titleLbl.BackgroundTransparency = 1
	titleLbl.FontFace               = resolvedTheme.TitleFont
		or Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold)
	titleLbl.Text                   = titleText
	titleLbl.TextSize               = ts
	titleLbl.TextColor3             = resolvedTheme.ContentColor or Color3.fromHex("#f5f5fa")
	titleLbl.TextXAlignment         = Enum.TextXAlignment.Left
	titleLbl.TextTruncate           = Enum.TextTruncate.AtEnd
	titleLbl.Parent                 = header

	-- Flex spacer between title and timestamp
	local spacer = Instance.new("Frame")
	spacer.Name                   = "Spacer"
	spacer.LayoutOrder            = 2
	spacer.Size                   = UDim2.new(0, 0, 1, 0)
	spacer.BackgroundTransparency = 1
	spacer.BorderSizePixel        = 0
	spacer.Parent                 = header

	local flex = Instance.new("UIFlexItem")
	flex.FlexMode = Enum.UIFlexMode.Fill
	flex.Parent   = spacer

	local timeLbl = Instance.new("TextLabel")
	timeLbl.Name                   = "Time"
	timeLbl.LayoutOrder            = 3
	timeLbl.AutomaticSize          = Enum.AutomaticSize.X
	timeLbl.Size                   = UDim2.new(0, 0, 1, 0)
	timeLbl.BackgroundTransparency = 1
	timeLbl.FontFace               = resolvedTheme.Font
		or Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium)
	timeLbl.Text                   = "now"
	timeLbl.TextSize               = xs
	timeLbl.TextColor3             = Color3.fromHex("#737380")
	timeLbl.TextXAlignment         = Enum.TextXAlignment.Right
	timeLbl.Parent                 = header

	-- M5 FIX: on mobile the close button is ~9px effective after 0.65 MOBILE_SCALE.
	-- Bump to at least 24px so it's reliably hittable with a fingertip.
	-- _scale < 1 is the mobile proxy (_scale = MOBILE_SCALE = 0.65 on phones).
	local closeBtnPx = if _scale < 1 then math.max(px(14), 24) else px(14)
	local closeBtn = Instance.new("TextButton")
	closeBtn.Name                   = "CloseBtn"
	closeBtn.LayoutOrder            = 4
	closeBtn.Size                   = UDim2.fromOffset(closeBtnPx, closeBtnPx)
	closeBtn.BackgroundTransparency = 1
	closeBtn.BorderSizePixel        = 0
	closeBtn.Font                   = Enum.Font.GothamMedium
	closeBtn.Text                   = "×"
	closeBtn.TextSize               = cs
	closeBtn.TextColor3             = Color3.fromHex("#737380")
	closeBtn.AutoButtonColor        = false
	closeBtn.Parent                 = header

	local closeCrn = Instance.new("UICorner")
	closeCrn.CornerRadius = UDim.new(0, px(3))
	closeCrn.Parent = closeBtn

	-- ── Message ───────────────────────────────────────────────────────────────
	if #msgText > 0 then
		local msgLbl = Instance.new("TextLabel")
		msgLbl.Name                   = "Message"
		msgLbl.LayoutOrder            = 2
		msgLbl.AutomaticSize          = Enum.AutomaticSize.Y
		msgLbl.Size                   = UDim2.new(1, 0, 0, 0)
		msgLbl.BackgroundTransparency = 1
		msgLbl.FontFace               = resolvedTheme.Font
			or Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium)
		msgLbl.Text                   = msgText
		msgLbl.TextSize               = ms
		msgLbl.TextColor3             = resolvedTheme.PlaceholderColor or Color3.fromHex("#b9b9c6")
		msgLbl.TextXAlignment         = Enum.TextXAlignment.Left
		msgLbl.TextWrapped            = true
		msgLbl.RichText               = true
		msgLbl.LineHeight             = 1.15
		msgLbl.Parent                 = col
	end

	-- ── Toast state tracking ──────────────────────────────────────────────────
	local creationTime = tick()
	local timerThread  : thread? = nil

	local toast: ActiveToast = {
		wrapper      = wrapper,
		card         = card,
		stroke       = stroke,
		dismissed    = false,
		cancelTimer  = function() end,
		timeLabel    = timeLbl,
		creationTime = creationTime,
	}

	local function cancelTimer()
		toast.dismissed = true
		if timerThread then pcall(task.cancel, timerThread); timerThread = nil end
	end
	toast.cancelTimer = cancelTimer

	table.insert(_active, toast)

	-- ── Enter animations ──────────────────────────────────────────────────────
	tween.fire(wrapper, TWEEN_IN_SIZE, { Size = UDim2.new(1, 0, 0, targetH) })
	tween.fire(card,    TWEEN_IN_POS,  { Position = UDim2.fromOffset(0, 0)  })
	tween.fire(card,    TWEEN_IN_FADE, { GroupTransparency = 0              })
	tween.fire(stroke,  TWEEN_IN_FADE, { Transparency = 0                  })

	-- ── Auto-dismiss ──────────────────────────────────────────────────────────
	if duration > 0 then
		timerThread = task.delay(duration, function() dismissToast(toast) end)
	end

	-- ── Centralized Clock Pulse ───────────────────────────────────────────────
	startClock()

	-- ── Close button interactivity ────────────────────────────────────────────
	closeBtn.MouseButton1Click:Connect(function() dismissToast(toast) end)
	closeBtn.TouchTap:Connect(function() dismissToast(toast) end)
	closeBtn.MouseEnter:Connect(function()
		tween.fire(closeBtn, TweenInfo.new(0.15), {
			BackgroundTransparency = 0.82,
			BackgroundColor3       = Color3.fromHex("#2e2e38"),
			TextColor3             = resolvedTheme.ContentColor or Color3.fromHex("#ffffff"),
		})
	end)
	closeBtn.MouseLeave:Connect(function()
		tween.fire(closeBtn, TweenInfo.new(0.15), {
			BackgroundTransparency = 1,
			TextColor3             = Color3.fromHex("#737380"),
		})
	end)
end

-- Dismiss all active notifications
function notification.dismissAll()
	for i = #_active, 1, -1 do
		local t = _active[i]
		if t then dismissToast(t) end
	end
end

return notification
