--!strict

-- Notification — singleton toast system.
-- Slide-in from right, semantic left-border color, auto-dismiss + manual X dismiss.
-- Queue: max 3 visible at once, rest enqueue and show when a slot opens.

local TweenService = game:GetService("TweenService")
local Players      = game:GetService("Players")

local Theme = require(script.Parent.Parent.Theme)

-- ── Constants ─────────────────────────────────────────────────────────────────

local TOAST_W           = 280
local TOAST_MAX_VISIBLE = 3
local DEFAULT_DURATION  = 4
local LEFT_BAR_W        = 4
local PAD_H             = 12   -- horizontal padding inside body
local PAD_V             = 10   -- vertical padding inside body
local GAP               = 8    -- gap between stacked toasts

local TWEEN_IN  = TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local TWEEN_OUT = TweenInfo.new(0.20, Enum.EasingStyle.Quint, Enum.EasingDirection.In)

-- ── Types ─────────────────────────────────────────────────────────────────────

export type NotifyConfig = {
	Title    : string?,
	Message  : string,
	Type     : string?,   -- "info" | "success" | "warning" | "error"
	Duration : number?,
}

type ActiveToast = {
	wrapper     : Frame,
	card        : CanvasGroup,
	cancelTimer : () -> (),
}

-- ── Singleton state ───────────────────────────────────────────────────────────

local _gui          : ScreenGui?        = nil
local _container    : Frame?            = nil
local _active       : { ActiveToast }   = {}
local _queue        : { NotifyConfig }  = {}
local _orderCounter : number            = 10000   -- decrements so newest = lowest = top of list

-- ── Helpers ───────────────────────────────────────────────────────────────────

local function typeColor(notifType: string?): Color3
	local t = notifType or "info"
	if     t == "success" then return Theme.Colors.Success
	elseif t == "warning" then return Theme.Colors.Warning
	elseif t == "error"   then return Theme.Colors.Error
	else                       return Theme.Colors.Accent
	end
end

local function applyCorner(parent: Instance, radius: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = parent
end

-- ── GUI bootstrap (lazy, first notify call) ───────────────────────────────────

local function ensureGui()
	if _gui then return end

	local gui          = Instance.new("ScreenGui")
	gui.Name           = "DeliriumNotifications"
	gui.ResetOnSpawn   = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.IgnoreGuiInset = true
	pcall(function() gui.DisplayOrder = 1000 end)

	-- Parent: CoreGui first, PlayerGui fallback
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

	-- Bottom-right container; AnchorPoint (1,1) so AutomaticSize Y expands upward
	local container                  = Instance.new("Frame")
	container.Name                   = "NotifContainer"
	container.AnchorPoint            = Vector2.new(1, 1)
	container.Position               = UDim2.new(1, -16, 1, -16)
	container.Size                   = UDim2.fromOffset(TOAST_W, 0)
	container.AutomaticSize          = Enum.AutomaticSize.Y
	container.BackgroundTransparency = 1
	container.BorderSizePixel        = 0
	container.ClipsDescendants       = false
	container.Parent                 = gui

	local layout               = Instance.new("UIListLayout")
	layout.FillDirection       = Enum.FillDirection.Vertical
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	layout.SortOrder           = Enum.SortOrder.LayoutOrder
	layout.Padding             = UDim.new(0, GAP)
	layout.Parent              = container

	_gui       = gui
	_container = container
end

-- ── Dismiss ───────────────────────────────────────────────────────────────────

local function dismissToast(toast: ActiveToast)
	toast.cancelTimer()

	-- Slide out to right + fade
	local t = TweenService:Create(toast.card, TWEEN_OUT, {
		Position          = UDim2.fromOffset(TOAST_W + 24, 0),
		GroupTransparency = 1,
	})
	t:Play()
	t.Completed:Once(function()
		if toast.wrapper.Parent then
			toast.wrapper:Destroy()
		end

		-- Remove from active list
		local idx = table.find(_active, toast)
		if idx then
			table.remove(_active, idx)
		end

		-- Pop next from queue
		if #_queue > 0 then
			local next = table.remove(_queue, 1)
			-- require the module itself for the recursive call — avoid upvalue capture issues
			local Notification = require(script) :: any
			Notification.notify(next)
		end
	end)
end

-- ── Public ────────────────────────────────────────────────────────────────────

local Notification = {}

function Notification.notify(config: NotifyConfig)
	ensureGui()

	-- Queue if at capacity
	if #_active >= TOAST_MAX_VISIBLE then
		table.insert(_queue, config)
		return
	end

	local accent   = typeColor(config.Type)
	local duration = config.Duration or DEFAULT_DURATION

	-- Newest toast gets the lowest LayoutOrder → top of the vertical list
	_orderCounter -= 1
	local order = _orderCounter

	-- ── Wrapper (layout slot, transparent) ────────────────────────────────────
	local wrapper                  = Instance.new("Frame")
	wrapper.Name                   = "ToastWrapper"
	wrapper.Size                   = UDim2.fromOffset(TOAST_W, 0)
	wrapper.AutomaticSize          = Enum.AutomaticSize.Y
	wrapper.BackgroundTransparency = 1
	wrapper.BorderSizePixel        = 0
	wrapper.ClipsDescendants       = false
	wrapper.LayoutOrder            = order
	wrapper.Parent                 = _container

	-- ── Card (CanvasGroup for group fade) ─────────────────────────────────────
	local card                    = Instance.new("CanvasGroup")
	card.Name                     = "ToastCard"
	card.Size                     = UDim2.fromOffset(TOAST_W, 0)
	card.AutomaticSize            = Enum.AutomaticSize.Y
	-- Start off-screen to the right, fully transparent
	card.Position                 = UDim2.fromOffset(TOAST_W + 24, 0)
	card.BackgroundColor3         = Theme.Colors.Surface
	card.BorderSizePixel          = 0
	card.GroupTransparency        = 1
	card.ClipsDescendants         = false
	card.Parent                   = wrapper
	applyCorner(card, Theme.Radius.Medium)

	local stroke           = Instance.new("UIStroke")
	stroke.Color           = Theme.Colors.Border
	stroke.Thickness       = 1
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent          = card

	-- ── Colored left accent strip ──────────────────────────────────────────────
	local leftBar                  = Instance.new("Frame")
	leftBar.Name                   = "AccentBar"
	leftBar.AnchorPoint            = Vector2.new(0, 0)
	leftBar.Position               = UDim2.fromOffset(0, 0)
	leftBar.Size                   = UDim2.new(0, LEFT_BAR_W, 1, 0)
	leftBar.BackgroundColor3       = accent
	leftBar.BorderSizePixel        = 0
	leftBar.ZIndex                 = 2
	leftBar.Parent                 = card
	applyCorner(leftBar, Theme.Radius.Medium)

	-- ── Body (right of left bar) ───────────────────────────────────────────────
	local body                     = Instance.new("Frame")
	body.Name                      = "Body"
	body.Position                  = UDim2.fromOffset(LEFT_BAR_W + PAD_H, 0)
	body.Size                      = UDim2.new(1, -(LEFT_BAR_W + PAD_H + 28), 0, 0)
	body.AutomaticSize             = Enum.AutomaticSize.Y
	body.BackgroundTransparency    = 1
	body.BorderSizePixel           = 0
	body.ZIndex                    = 2
	body.Parent                    = card

	local bodyLayout               = Instance.new("UIListLayout")
	bodyLayout.FillDirection       = Enum.FillDirection.Vertical
	bodyLayout.SortOrder           = Enum.SortOrder.LayoutOrder
	bodyLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	bodyLayout.Padding             = UDim.new(0, 3)
	bodyLayout.Parent              = body

	local bodyPad         = Instance.new("UIPadding")
	bodyPad.PaddingTop    = UDim.new(0, PAD_V)
	bodyPad.PaddingBottom = UDim.new(0, PAD_V)
	bodyPad.Parent        = body

	-- Title (optional)
	if config.Title and #config.Title > 0 then
		local titleLbl                  = Instance.new("TextLabel")
		titleLbl.Name                   = "Title"
		titleLbl.LayoutOrder            = 0
		titleLbl.AutomaticSize          = Enum.AutomaticSize.Y
		titleLbl.Size                   = UDim2.new(1, 0, 0, 0)
		titleLbl.BackgroundTransparency = 1
		titleLbl.Font                   = Theme.Font.Title
		titleLbl.Text                   = config.Title
		titleLbl.TextSize               = Theme.TextSize.Body
		titleLbl.TextColor3             = Theme.Colors.TextPrimary
		titleLbl.TextXAlignment         = Enum.TextXAlignment.Left
		titleLbl.TextWrapped            = true
		titleLbl.ZIndex                 = 3
		titleLbl.Parent                 = body
	end

	-- Message
	local msgLbl                  = Instance.new("TextLabel")
	msgLbl.Name                   = "Message"
	msgLbl.LayoutOrder            = 1
	msgLbl.AutomaticSize          = Enum.AutomaticSize.Y
	msgLbl.Size                   = UDim2.new(1, 0, 0, 0)
	msgLbl.BackgroundTransparency = 1
	msgLbl.Font                   = Theme.Font.Body
	msgLbl.Text                   = config.Message
	msgLbl.TextSize               = Theme.TextSize.Small
	msgLbl.TextColor3             = Theme.Colors.TextSecondary
	msgLbl.TextXAlignment         = Enum.TextXAlignment.Left
	msgLbl.TextWrapped            = true
	msgLbl.ZIndex                 = 3
	msgLbl.Parent                 = body

	-- ── Close button ──────────────────────────────────────────────────────────
	local closeBtn                  = Instance.new("TextButton")
	closeBtn.Name                   = "CloseBtn"
	closeBtn.AnchorPoint            = Vector2.new(1, 0)
	closeBtn.Position               = UDim2.new(1, -8, 0, 8)
	closeBtn.Size                   = UDim2.fromOffset(18, 18)
	closeBtn.BackgroundColor3       = Theme.Colors.SurfaceHover
	closeBtn.BorderSizePixel        = 0
	closeBtn.Font                   = Theme.Font.Body
	closeBtn.Text                   = "×"
	closeBtn.TextSize               = 14
	closeBtn.TextColor3             = Theme.Colors.TextSecondary
	closeBtn.AutoButtonColor        = false
	closeBtn.ZIndex                 = 5
	closeBtn.Parent                 = card
	applyCorner(closeBtn, 4)

	-- ── Build ActiveToast ─────────────────────────────────────────────────────

	local timerThread : thread? = nil
	local dismissed             = false

	local function cancelTimer()
		dismissed = true
		if timerThread then
			pcall(task.cancel, timerThread)
			timerThread = nil
		end
	end

	local toast: ActiveToast = {
		wrapper     = wrapper,
		card        = card,
		cancelTimer = cancelTimer,
	}
	table.insert(_active, toast)

	-- ── Tween in ──────────────────────────────────────────────────────────────
	TweenService:Create(card, TWEEN_IN, {
		Position          = UDim2.fromOffset(0, 0),
		GroupTransparency = 0,
	}):Play()

	-- ── Auto-dismiss timer ────────────────────────────────────────────────────
	timerThread = task.delay(duration, function()
		if not dismissed then
			dismissToast(toast)
		end
	end)

	-- ── Close button interactions ─────────────────────────────────────────────
	closeBtn.MouseButton1Click:Connect(function()
		dismissToast(toast)
	end)
	closeBtn.MouseEnter:Connect(function()
		closeBtn.BackgroundColor3 = Theme.Colors.Error
		closeBtn.TextColor3       = Theme.Colors.TextPrimary
	end)
	closeBtn.MouseLeave:Connect(function()
		closeBtn.BackgroundColor3 = Theme.Colors.SurfaceHover
		closeBtn.TextColor3       = Theme.Colors.TextSecondary
	end)
end

return Notification
