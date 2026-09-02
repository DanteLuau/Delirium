--!strict

local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Maid        = require(script.Parent.Parent.Utils.Maid)
local Theme       = require(script.Parent.Parent.Theme)
local SmoothScroll = require(script.Parent.Parent.Utils.SmoothScroll)

-- Architecture:
--   shell   — Frame centered on canvas. Has UIScale + background + UIStroke.
--             AutomaticSize.Y grows with content.
--   content — Frame INSIDE shell. Fills shell width. Has all text/buttons.
--
-- Stack behaviour:
--   Stacking infrastructure is preserved but disabled — only one popup at a time.
--   A second Popup.show call while one is already open is silently ignored.
--   To re-enable stacking: remove the #_stack > 0 guard in Popup.show.
--   ONE shared dim overlay for the stack. Created on first open, destroyed on last close.
--   Each shell gets its own ZIndex tier (BASE_Z + stackIdx * STRIDE).
--   Stack depth badge appears on shells beyond the first (dormant while stacking disabled).

local TWEEN_OPEN_SCALE    = TweenInfo.new(0.38, Enum.EasingStyle.Back,        Enum.EasingDirection.Out)
local TWEEN_FADE_IN       = TweenInfo.new(0.28, Enum.EasingStyle.Exponential,  Enum.EasingDirection.Out)

local TWEEN_CONFIRM_SCALE = TweenInfo.new(0.42, Enum.EasingStyle.Exponential, Enum.EasingDirection.In)
local TWEEN_CONFIRM_FADE  = TweenInfo.new(0.32, Enum.EasingStyle.Exponential, Enum.EasingDirection.In)

local TWEEN_CLOSE_SCALE   = TweenInfo.new(0.32, Enum.EasingStyle.Quint,       Enum.EasingDirection.In)
local TWEEN_FADE_OUT      = TweenInfo.new(0.24, Enum.EasingStyle.Quint,       Enum.EasingDirection.In)

local SCALE_OPEN          = 1.08
local SCALE_CLOSE_CANCEL  = 1.82
local SCALE_CLOSE_CONFIRM = 2.32

local CARD_W = 290

-- Dim sits at ZIndex 3 in root (above canvas at ZIndex 2, below shells at 50+).
-- Shell/badge live in root too so they render above the dim regardless of CanvasGroup.
local DIM_Z       = 3
local BASE_Z      = 50
local Z_STRIDE    = 10
local Z_SHELL     = 1
local Z_CONTENT   = 2
local Z_BTN       = 3
local Z_BADGE     = 4

local STACK_OFFSET_PX = 5

export type PopupConfig = {
	Title:       string,
	Message:     string,
	OnConfirm:   () -> (),
	OnCancel:    (() -> ())?,
	ConfirmText: string?,
	CancelText:  string?,
}

-- ── Module-level state ────────────────────────────────────────────────────────
local _stack:     { any }   = {}
local _sharedDim: Frame?    = nil   -- singleton overlay; nil when no popups are open

-- ── helpers ───────────────────────────────────────────────────────────────────

local function corner(inst: Instance, r: number)
	local c        = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r)
	c.Parent       = inst
end

local function makeActionBtn(
	text:     string,
	bg:       Color3,
	fg:       Color3,
	order:    number,
	zIndex:   number,
	parent:   Instance,
	isAccent: boolean?
): TextButton
	local btn                  = Instance.new("TextButton")
	btn.Name                   = text .. "Btn"
	btn.AutomaticSize          = Enum.AutomaticSize.X
	btn.Size                   = UDim2.fromOffset(0, 30)
	btn.BackgroundColor3       = bg
	btn.BorderSizePixel        = 0
	btn.Font                   = Theme.Font.Body
	btn.Text                   = text
	btn.TextSize               = Theme.TextSize.Body
	btn.TextColor3             = fg
	btn.AutoButtonColor        = false
	btn.BackgroundTransparency = 1
	btn.TextTransparency       = 1
	btn.LayoutOrder            = order
	btn.ZIndex                 = zIndex
	btn:SetAttribute("IsAccent", isAccent == true)
	corner(btn, Theme.Radius.Small)
	local p        = Instance.new("UIPadding")
	p.PaddingLeft  = UDim.new(0, Theme.Spacing.M)
	p.PaddingRight = UDim.new(0, Theme.Spacing.M)
	p.Parent       = btn
	btn.Parent     = parent
	return btn
end

-- ── Shared dim management ─────────────────────────────────────────────────────

-- Called when the first popup opens. Creates the dim once and fades it in.
local function acquireDim(canvas: Frame)
	if _sharedDim then return end   -- already alive from a previous popup in the stack

	local dim                  = Instance.new("Frame")
	dim.Name                   = "PopupDim"
	dim.Size                   = UDim2.fromScale(1, 1)
	dim.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
	dim.BackgroundTransparency = 1
	dim.BorderSizePixel        = 0
	dim.ZIndex                 = DIM_Z
	dim.Active                 = true   -- blocks input through the overlay immediately
	corner(dim, Theme.Radius.Medium)    -- match canvas rounded corners so dim doesn't bleed past window edge
	dim.Parent                 = canvas.Parent  -- root level: sits above canvas (ZIndex 2) so CanvasGroup no longer flattens the block

	_sharedDim = dim
	TweenService:Create(dim, TWEEN_FADE_IN, { BackgroundTransparency = 0.45 }):Play()
end

-- Called when any popup closes. Fades and destroys the dim only when the stack
-- is fully empty — intermediate closes leave it untouched.
local function releaseDim(fadeInfo: TweenInfo)
	if #_stack > 0 then return end   -- still popups alive; keep the dim

	local dim = _sharedDim
	if not dim then return end
	_sharedDim = nil

	TweenService:Create(dim, fadeInfo, { BackgroundTransparency = 1 }):Play()
	task.delay(fadeInfo.Time + 0.02, function()
		if dim and dim.Parent then
			dim:Destroy()
		end
	end)
end

-- ── Popup.show ────────────────────────────────────────────────────────────────

local Popup = {}

function Popup.show(canvas: Frame, config: PopupConfig)
	-- Only one popup at a time. Stacking infra is preserved — remove this guard to re-enable.
	if #_stack > 0 then return end

	local maid = Maid.new()

	-- Stack index computed BEFORE push — determines ZIndex tier and visual offset.
	local stackIdx = #_stack + 1

	local shellZ   = BASE_Z + (stackIdx - 1) * Z_STRIDE + Z_SHELL
	local contentZ = BASE_Z + (stackIdx - 1) * Z_STRIDE + Z_CONTENT
	local btnZ     = BASE_Z + (stackIdx - 1) * Z_STRIDE + Z_BTN
	local badgeZ   = BASE_Z + (stackIdx - 1) * Z_STRIDE + Z_BADGE

	local offsetPx = (stackIdx - 1) * STACK_OFFSET_PX

	-- Ensure the ONE shared dim is alive (no-op if already exists).
	acquireDim(canvas)

	-- Block hover + click events on canvas content. Interactable=false propagates to all
	-- descendants — every toggle, button, dropdown goes completely dead while popup is open.
	-- Wrapped in pcall: older clients without the Interactable property degrade gracefully.
	pcall(function() (canvas :: any).Interactable = false end)
	maid:GiveTask(function() pcall(function() (canvas :: any).Interactable = true end) end)

	-- Freeze all SmoothScroll-managed frames while this popup is open.
	-- Sidebar tab buttons remain interactive (they are outside canvas, not managed).
	SmoothScroll.setPaused(true)
	maid:GiveTask(function() SmoothScroll.setPaused(false) end)

	-- ── Shell ─────────────────────────────────────────────────────────────────
	local shell                  = Instance.new("Frame")
	shell.Name                   = "PopupShell"
	shell.AnchorPoint            = Vector2.new(0.5, 0.5)
	shell.Position               = UDim2.new(0.5, offsetPx, 0.5, offsetPx)
	shell.Size                   = UDim2.fromOffset(CARD_W, 0)
	shell.AutomaticSize          = Enum.AutomaticSize.Y
	shell.BackgroundColor3       = Theme.Colors.Surface
	shell.BackgroundTransparency = 1
	shell.BorderSizePixel        = 0
	shell.ZIndex                 = shellZ
	shell.ClipsDescendants       = false
	corner(shell, Theme.Radius.Medium)
	shell.Parent = canvas.Parent  -- root level: above dim (ZIndex 3) so confirm/cancel stay interactive
	maid:GiveTask(shell)

	local shellScale       = Instance.new("UIScale")
	shellScale.Scale       = SCALE_OPEN
	shellScale.Parent      = shell

	local shellStroke           = Instance.new("UIStroke")
	shellStroke.Color           = Theme.Colors.Border
	shellStroke.Thickness       = 1
	shellStroke.Transparency    = 1
	shellStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	shellStroke.Parent          = shell

	-- ── Stack depth badge ─────────────────────────────────────────────────────
	local stackBadge: Frame? = nil
	if stackIdx > 1 then
		local badge                  = Instance.new("Frame")
		badge.Name                   = "StackBadge"
		badge.AnchorPoint            = Vector2.new(1, 0)
		badge.Position               = UDim2.new(1, 10, 0, -10)
		badge.Size                   = UDim2.fromOffset(22, 22)
		badge.BackgroundColor3       = Theme.Colors.Accent
		badge.BackgroundTransparency = 1
		badge.BorderSizePixel        = 0
		badge.ZIndex                 = badgeZ
		corner(badge, 11)
		badge.Parent = shell
		maid:GiveTask(badge)

		local badgeLbl                  = Instance.new("TextLabel")
		badgeLbl.Name                   = "StackCount"
		badgeLbl.Size                   = UDim2.fromScale(1, 1)
		badgeLbl.BackgroundTransparency = 1
		badgeLbl.Font                   = Theme.Font.Title
		badgeLbl.Text                   = tostring(stackIdx)
		badgeLbl.TextSize               = 11
		badgeLbl.TextColor3             = Color3.fromRGB(10, 10, 10)
		badgeLbl.TextTransparency       = 1
		badgeLbl.TextXAlignment         = Enum.TextXAlignment.Center
		badgeLbl.TextYAlignment         = Enum.TextYAlignment.Center
		badgeLbl.ZIndex                 = badgeZ + 1
		badgeLbl.Parent                 = badge

		stackBadge = badge

		task.delay(0.08, function()
			if not badge.Parent then return end
			TweenService:Create(badge,    TWEEN_FADE_IN, { BackgroundTransparency = 0 }):Play()
			TweenService:Create(badgeLbl, TWEEN_FADE_IN, { TextTransparency       = 0 }):Play()
		end)
	end

	-- ── Content ───────────────────────────────────────────────────────────────
	local content                  = Instance.new("Frame")
	content.Name                   = "PopupContent"
	content.Size                   = UDim2.fromScale(1, 0)
	content.AutomaticSize          = Enum.AutomaticSize.Y
	content.BackgroundTransparency = 1
	content.BorderSizePixel        = 0
	content.ZIndex                 = contentZ
	content.Parent                 = shell
	maid:GiveTask(content)

	local pad         = Instance.new("UIPadding")
	pad.PaddingTop    = UDim.new(0, Theme.Spacing.M)
	pad.PaddingBottom = UDim.new(0, Theme.Spacing.M)
	pad.PaddingLeft   = UDim.new(0, Theme.Spacing.M)
	pad.PaddingRight  = UDim.new(0, Theme.Spacing.M)
	pad.Parent        = content

	local contentLayout               = Instance.new("UIListLayout")
	contentLayout.FillDirection       = Enum.FillDirection.Vertical
	contentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	contentLayout.SortOrder           = Enum.SortOrder.LayoutOrder
	contentLayout.Padding             = UDim.new(0, Theme.Spacing.S)
	contentLayout.Parent              = content

	-- ── Title ─────────────────────────────────────────────────────────────────
	local titleLbl                  = Instance.new("TextLabel")
	titleLbl.Name                   = "Title"
	titleLbl.AutomaticSize          = Enum.AutomaticSize.Y
	titleLbl.Size                   = UDim2.new(1, 0, 0, 0)
	titleLbl.BackgroundTransparency = 1
	titleLbl.Font                   = Theme.Font.Title
	titleLbl.Text                   = config.Title
	titleLbl.TextSize               = Theme.TextSize.Body
	titleLbl.TextColor3             = Theme.Colors.TextPrimary
	titleLbl.TextTransparency       = 1
	titleLbl.TextXAlignment         = Enum.TextXAlignment.Left
	titleLbl.TextWrapped            = true
	titleLbl.RichText               = false
	titleLbl.LayoutOrder            = 0
	titleLbl.ZIndex                 = btnZ
	titleLbl.Parent                 = content

	-- ── Message ───────────────────────────────────────────────────────────────
	local msgLbl                  = Instance.new("TextLabel")
	msgLbl.Name                   = "Message"
	msgLbl.AutomaticSize          = Enum.AutomaticSize.Y
	msgLbl.Size                   = UDim2.new(1, 0, 0, 0)
	msgLbl.BackgroundTransparency = 1
	msgLbl.Font                   = Theme.Font.Body
	msgLbl.Text                   = config.Message
	msgLbl.TextSize               = Theme.TextSize.Small
	msgLbl.TextColor3             = Theme.Colors.TextSecondary
	msgLbl.TextTransparency       = 1
	msgLbl.TextXAlignment         = Enum.TextXAlignment.Left
	msgLbl.TextWrapped            = true
	msgLbl.RichText               = false
	msgLbl.LayoutOrder            = 1
	msgLbl.ZIndex                 = btnZ
	msgLbl.Parent                 = content

	-- ── Divider ───────────────────────────────────────────────────────────────
	local divider                  = Instance.new("Frame")
	divider.Name                   = "Divider"
	divider.Size                   = UDim2.new(1, 0, 0, 1)
	divider.BackgroundColor3       = Theme.Colors.Border
	divider.BackgroundTransparency = 1
	divider.BorderSizePixel        = 0
	divider.LayoutOrder            = 2
	divider.ZIndex                 = btnZ
	divider.Parent                 = content

	-- ── Button row ────────────────────────────────────────────────────────────
	local btnRow                  = Instance.new("Frame")
	btnRow.Name                   = "ButtonRow"
	btnRow.Size                   = UDim2.new(1, 0, 0, 0)
	btnRow.AutomaticSize          = Enum.AutomaticSize.Y
	btnRow.BackgroundTransparency = 1
	btnRow.BorderSizePixel        = 0
	btnRow.LayoutOrder            = 3
	btnRow.ZIndex                 = btnZ
	btnRow.Parent                 = content

	local btnLayout               = Instance.new("UIListLayout")
	btnLayout.FillDirection       = Enum.FillDirection.Horizontal
	btnLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	btnLayout.VerticalAlignment   = Enum.VerticalAlignment.Center
	btnLayout.Padding             = UDim.new(0, Theme.Spacing.XS)
	btnLayout.SortOrder           = Enum.SortOrder.LayoutOrder
	btnLayout.Parent              = btnRow

	-- ── Animation helpers ─────────────────────────────────────────────────────

	local function tweenShell(ti: TweenInfo, bgT: number, strokeT: number)
		TweenService:Create(shell,       ti, { BackgroundTransparency = bgT     }):Play()
		TweenService:Create(shellStroke, ti, { Transparency           = strokeT }):Play()
	end

	local function tweenContent(ti: TweenInfo, textT: number, divT: number, closing: boolean)
		TweenService:Create(titleLbl, ti, { TextTransparency       = textT }):Play()
		TweenService:Create(msgLbl,   ti, { TextTransparency       = textT }):Play()
		TweenService:Create(divider,  ti, { BackgroundTransparency = divT  }):Play()
		for _, child in ipairs(btnRow:GetChildren()) do
			if not child:IsA("TextButton") then continue end
			local isAccent  = child:GetAttribute("IsAccent") == true
			local targetBgT = closing and 1 or (isAccent and 0 or 0.94)
			TweenService:Create(child, ti, {
				BackgroundTransparency = targetBgT,
				TextTransparency       = textT,
			}):Play()
		end
	end

	local function tweenBadge(ti: TweenInfo, transparency: number)
		if not stackBadge then return end
		local lbl = stackBadge:FindFirstChild("StackCount")
		TweenService:Create(stackBadge, ti, { BackgroundTransparency = transparency }):Play()
		if lbl then
			TweenService:Create(lbl, ti, { TextTransparency = transparency }):Play()
		end
	end

	-- ── Close sequences ───────────────────────────────────────────────────────
	local closed    = false
	local confirmBtn: TextButton

	local function closePopup()
		if closed then return end
		closed = true

		for i = #_stack, 1, -1 do
			if _stack[i] == maid then table.remove(_stack, i) break end
		end

		-- Release shared dim only if this was the last popup in the stack.
		releaseDim(TWEEN_FADE_OUT)

		tweenBadge(TWEEN_FADE_OUT, 1)
		tweenContent(TWEEN_FADE_OUT, 1, 1, true)
		TweenService:Create(shellScale, TWEEN_CLOSE_SCALE, { Scale = SCALE_CLOSE_CANCEL }):Play()
		tweenShell(TWEEN_FADE_OUT, 1, 1)

		task.delay(TWEEN_CLOSE_SCALE.Time + 0.02, function()
			maid:DoCleaning()
		end)
	end

	local function closeConfirm()
		if closed then return end
		closed = true

		for i = #_stack, 1, -1 do
			if _stack[i] == maid then table.remove(_stack, i) break end
		end

		releaseDim(TWEEN_CONFIRM_FADE)

		local btnScale = Instance.new("UIScale")
		btnScale.Scale = 1
		btnScale.Parent = confirmBtn

		tweenBadge(TWEEN_CONFIRM_FADE, 1)

		TweenService:Create(btnScale,   TWEEN_CONFIRM_SCALE, { Scale = 1.22 }):Play()
		TweenService:Create(confirmBtn, TWEEN_CONFIRM_FADE, {
			BackgroundTransparency = 1,
			TextTransparency       = 1,
		}):Play()

		TweenService:Create(shellScale, TWEEN_CONFIRM_SCALE, { Scale = SCALE_CLOSE_CONFIRM }):Play()
		tweenShell(TWEEN_CONFIRM_FADE, 1, 1)

		TweenService:Create(titleLbl, TWEEN_CONFIRM_FADE, { TextTransparency = 1 }):Play()
		TweenService:Create(msgLbl,   TWEEN_CONFIRM_FADE, { TextTransparency = 1 }):Play()
		TweenService:Create(divider,  TWEEN_CONFIRM_FADE, { BackgroundTransparency = 1 }):Play()
		for _, child in ipairs(btnRow:GetChildren()) do
			if child:IsA("TextButton") then
				TweenService:Create(child, TWEEN_CONFIRM_FADE, {
					BackgroundTransparency = 1,
					TextTransparency       = 1,
				}):Play()
			end
		end

		task.delay(TWEEN_CONFIRM_SCALE.Time + 0.02, function()
			maid:DoCleaning()
		end)
	end

	-- ── Cancel button ─────────────────────────────────────────────────────────
	if config.OnCancel then
		local cancelBtn = makeActionBtn(
			config.CancelText or "Cancel",
			Theme.Colors.SurfaceHover,
			Theme.Colors.TextSecondary,
			0,
			btnZ,
			btnRow,
			false
		)
		local cancelStroke           = Instance.new("UIStroke")
		cancelStroke.Color           = Theme.Colors.Border
		cancelStroke.Thickness       = 1
		cancelStroke.Transparency    = 1
		cancelStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		cancelStroke.Parent          = cancelBtn

		maid:GiveTask(cancelBtn.MouseButton1Click:Connect(function()
			closePopup()
			if config.OnCancel then config.OnCancel() end
		end))
		maid:GiveTask(cancelBtn.MouseEnter:Connect(function()
			cancelBtn.BackgroundColor3 = Theme.Colors.SurfaceActive
			cancelBtn.TextColor3       = Theme.Colors.TextPrimary
		end))
		maid:GiveTask(cancelBtn.MouseLeave:Connect(function()
			cancelBtn.BackgroundColor3 = Theme.Colors.SurfaceHover
			cancelBtn.TextColor3       = Theme.Colors.TextSecondary
		end))
	end

	-- ── Confirm button ────────────────────────────────────────────────────────
	confirmBtn = makeActionBtn(
		config.ConfirmText or "Confirm",
		Theme.Colors.Accent,
		Color3.fromRGB(10, 10, 10),
		1,
		btnZ,
		btnRow,
		true
	)

	maid:GiveTask(confirmBtn.MouseButton1Click:Connect(function()
		closeConfirm()
		config.OnConfirm()
	end))
	maid:GiveTask(confirmBtn.MouseEnter:Connect(function()
		confirmBtn.BackgroundColor3 = Theme.Colors.AccentHover
	end))
	maid:GiveTask(confirmBtn.MouseLeave:Connect(function()
		confirmBtn.BackgroundColor3 = Theme.Colors.Accent
	end))

	-- ── Push + escape ─────────────────────────────────────────────────────────
	table.insert(_stack, maid)

	maid:GiveTask(UserInputService.InputBegan:Connect(function(input: InputObject, gpe: boolean)
		if gpe then return end
		if input.KeyCode ~= Enum.KeyCode.Escape then return end
		if _stack[#_stack] == maid then
			closePopup()
		end
	end))

	-- ── Open animation ────────────────────────────────────────────────────────
	shell.BackgroundTransparency = 1
	shellStroke.Transparency     = 1

	TweenService:Create(shellScale, TWEEN_OPEN_SCALE, { Scale = 1 }):Play()
	tweenShell(TWEEN_FADE_IN, 0, 0.88)

	task.delay(0.06, function()
		if closed then return end
		tweenContent(TWEEN_FADE_IN, 0, 0.9, false)
	end)
end

return Popup
