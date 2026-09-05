--!strict

local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Maid        = require(script.Parent.Parent.Utils.Maid)
local Theme       = require(script.Parent.Parent.Theme)
local SmoothScroll = require(script.Parent.Parent.Utils.SmoothScroll)

-- ── Constants & Motion ────────────────────────────────────────────────────────

local TWEEN_OPEN_SCALE  = TweenInfo.new(0.32, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
local TWEEN_FADE_IN     = TweenInfo.new(0.28, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)

local TWEEN_CLOSE_SCALE = TweenInfo.new(0.24, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
local TWEEN_FADE_OUT    = TweenInfo.new(0.20, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)

local SCALE_START       = 0.94
local SCALE_CLOSE       = 0.94

local CARD_W = 310

-- Default semantic icons (Lucide / rbxassetid)
local DEFAULT_ICONS: { [string]: string } = {
	info    = "rbxassetid://10723415903",
	success = "rbxassetid://10709790387",
	warning = "rbxassetid://10709752935",
	error   = "rbxassetid://10747384394",
}

-- ZIndex layering
local DIM_Z     = 3
local BASE_Z    = 50
local Z_STRIDE  = 10
local Z_SHELL   = 1
local Z_CONTENT = 2
local Z_BTN     = 3
local Z_BADGE   = 4

local STACK_OFFSET_PX = 5

export type PopupConfig = {
	Title:       string,
	Message:     string,
	OnConfirm:   () -> (),
	OnCancel:    (() -> ())?,
	ConfirmText: string?,
	CancelText:  string?,
	Type:        string?,   -- "info" | "warning" | "error" | "success"
	Icon:        (string | number)?,
	Risky:       boolean?,
}

-- ── Module-level state ────────────────────────────────────────────────────────
local _stack:     { any }   = {}
local _sharedDim: Frame?    = nil   -- singleton overlay; nil when no popups are open

-- ── Helpers ───────────────────────────────────────────────────────────────────

local function corner(inst: Instance, r: number)
	local c        = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r)
	c.Parent       = inst
end

local function typeColor(notifType: string): Color3
	local t = string.lower(notifType)
	if     t == "success" then return Theme.Colors.Success
	elseif t == "warning" then return Theme.Colors.Warning
	elseif t == "error"   then return Theme.Colors.Error
	else                       return Theme.Colors.Accent
	end
end

local function resolveIcon(icon: (string | number)?, notifType: string): string
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

	local t = string.lower(notifType)
	return DEFAULT_ICONS[t] or DEFAULT_ICONS.info
end

-- ── Shared dim management ─────────────────────────────────────────────────────

local function acquireDim(canvas: Frame)
	if _sharedDim then return end

	local dim                  = Instance.new("Frame")
	dim.Name                   = "PopupDim"
	dim.Size                   = UDim2.fromScale(1, 1)
	dim.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
	dim.BackgroundTransparency = 1
	dim.BorderSizePixel        = 0
	dim.ZIndex                 = DIM_Z
	dim.Active                 = true
	corner(dim, Theme.Radius.Medium)
	dim.Parent                 = canvas.Parent

	_sharedDim = dim
	TweenService:Create(dim, TWEEN_FADE_IN, { BackgroundTransparency = 0.55 }):Play()
end

local function releaseDim(fadeInfo: TweenInfo)
	if #_stack > 0 then return end

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
	if #_stack > 0 then return end

	local maid = Maid.new()

	-- Infer semantic type and accent color
	local notifType = config.Type
	if not notifType then
		local combined = string.lower((config.Title or "") .. " " .. (config.ConfirmText or "") .. " " .. (config.Message or ""))
		if config.Risky or string.find(combined, "wipe") or string.find(combined, "delete") or string.find(combined, "unload") or string.find(combined, "danger") or string.find(combined, "ban") then
			notifType = "error"
		elseif string.find(combined, "warn") or string.find(combined, "heads up") or string.find(combined, "restart") or string.find(combined, "careful") then
			notifType = "warning"
		else
			notifType = "info"
		end
	end

	local accent = typeColor(notifType)
	local iconId = resolveIcon(config.Icon, notifType)

	local stackIdx = #_stack + 1
	local shellZ   = BASE_Z + (stackIdx - 1) * Z_STRIDE + Z_SHELL
	local contentZ = BASE_Z + (stackIdx - 1) * Z_STRIDE + Z_CONTENT
	local btnZ     = BASE_Z + (stackIdx - 1) * Z_STRIDE + Z_BTN
	local badgeZ   = BASE_Z + (stackIdx - 1) * Z_STRIDE + Z_BADGE

	local offsetPx = (stackIdx - 1) * STACK_OFFSET_PX

	acquireDim(canvas)

	pcall(function() (canvas :: any).Interactable = false end)
	maid:GiveTask(function() pcall(function() (canvas :: any).Interactable = true end) end)

	SmoothScroll.setPaused(true)
	maid:GiveTask(function() SmoothScroll.setPaused(false) end)

	-- ── Shell (Consistent dark acrylic glass tone) ────────────────────────────
	local shell                  = Instance.new("Frame")
	shell.Name                   = "PopupShell"
	shell.AnchorPoint            = Vector2.new(0.5, 0.5)
	shell.Position               = UDim2.new(0.5, offsetPx, 0.5, offsetPx)
	shell.Size                   = UDim2.fromOffset(CARD_W, 0)
	shell.AutomaticSize          = Enum.AutomaticSize.Y
	shell.BackgroundColor3       = Color3.fromRGB(24, 24, 28) -- matches Notification tone
	shell.BackgroundTransparency = 1
	shell.BorderSizePixel        = 0
	shell.ZIndex                 = shellZ
	shell.ClipsDescendants       = false
	corner(shell, 8)
	shell.Parent = canvas.Parent
	maid:GiveTask(shell)

	local shellScale       = Instance.new("UIScale")
	shellScale.Scale       = SCALE_START
	shellScale.Parent      = shell

	local shellStroke           = Instance.new("UIStroke")
	shellStroke.Color           = Color3.fromRGB(48, 48, 56) -- matches Notification border
	shellStroke.Thickness       = 1
	shellStroke.Transparency    = 1
	shellStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	shellStroke.Parent          = shell

	-- ── Bottom Ambient Status Glow Line (1px gradient strip) ──────────────────
	local bottomGlow                  = Instance.new("Frame")
	bottomGlow.Name                   = "BottomGlow"
	bottomGlow.Position               = UDim2.new(0, 0, 1, -1)
	bottomGlow.Size                   = UDim2.new(1, 0, 0, 1)
	bottomGlow.BackgroundColor3       = accent
	bottomGlow.BackgroundTransparency = 1
	bottomGlow.BorderSizePixel        = 0
	bottomGlow.ZIndex                 = shellZ + 1
	bottomGlow.Parent                 = shell
	maid:GiveTask(bottomGlow)

	local glowGrad = Instance.new("UIGradient")
	glowGrad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.35, 0.45),
		NumberSequenceKeypoint.new(0.65, 0.45),
		NumberSequenceKeypoint.new(1, 1),
	})
	glowGrad.Parent = bottomGlow

	-- ── Stack depth badge ─────────────────────────────────────────────────────
	local stackBadge: Frame? = nil
	if stackIdx > 1 then
		local badge                  = Instance.new("Frame")
		badge.Name                   = "StackBadge"
		badge.AnchorPoint            = Vector2.new(1, 0)
		badge.Position               = UDim2.new(1, 8, 0, -8)
		badge.Size                   = UDim2.fromOffset(20, 20)
		badge.BackgroundColor3       = accent
		badge.BackgroundTransparency = 1
		badge.BorderSizePixel        = 0
		badge.ZIndex                 = badgeZ
		corner(badge, 10)
		badge.Parent = shell
		maid:GiveTask(badge)

		local badgeLbl                  = Instance.new("TextLabel")
		badgeLbl.Name                   = "StackCount"
		badgeLbl.Size                   = UDim2.fromScale(1, 1)
		badgeLbl.BackgroundTransparency = 1
		badgeLbl.Font                   = Theme.Font.Title
		badgeLbl.Text                   = tostring(stackIdx)
		badgeLbl.TextSize               = 10
		badgeLbl.TextColor3             = Color3.fromRGB(10, 10, 10)
		badgeLbl.TextTransparency       = 1
		badgeLbl.TextXAlignment         = Enum.TextXAlignment.Center
		badgeLbl.TextYAlignment         = Enum.TextYAlignment.Center
		badgeLbl.ZIndex                 = badgeZ + 1
		badgeLbl.Parent                 = badge

		stackBadge = badge
	end

	-- ── Content Container ─────────────────────────────────────────────────────
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
	pad.PaddingTop    = UDim.new(0, 14)
	pad.PaddingBottom = UDim.new(0, 12)
	pad.PaddingLeft   = UDim.new(0, 14)
	pad.PaddingRight  = UDim.new(0, 14)
	pad.Parent        = content

	local contentLayout               = Instance.new("UIListLayout")
	contentLayout.FillDirection       = Enum.FillDirection.Vertical
	contentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	contentLayout.SortOrder           = Enum.SortOrder.LayoutOrder
	contentLayout.Padding             = UDim.new(0, 10)
	contentLayout.Parent              = content

	-- ── Two-Column Row (Frosted Icon Badge + Header/Message) ───────────────────
	local topRow                  = Instance.new("Frame")
	topRow.Name                   = "TopRow"
	topRow.Size                   = UDim2.new(1, 0, 0, 0)
	topRow.AutomaticSize          = Enum.AutomaticSize.Y
	topRow.BackgroundTransparency = 1
	topRow.BorderSizePixel        = 0
	topRow.LayoutOrder            = 1
	topRow.ZIndex                 = contentZ
	topRow.Parent                 = content

	local topLayout               = Instance.new("UIListLayout")
	topLayout.FillDirection       = Enum.FillDirection.Horizontal
	topLayout.VerticalAlignment   = Enum.VerticalAlignment.Top
	topLayout.SortOrder           = Enum.SortOrder.LayoutOrder
	topLayout.Padding             = UDim.new(0, 10)
	topLayout.Parent              = topRow

	-- Frosted Semantic Icon Badge (matches Notification exactly)
	local iconBadge                  = Instance.new("Frame")
	iconBadge.Name                   = "IconBadge"
	iconBadge.LayoutOrder            = 1
	iconBadge.Size                   = UDim2.fromOffset(30, 30)
	iconBadge.BackgroundColor3       = accent
	iconBadge.BackgroundTransparency = 1
	iconBadge.BorderSizePixel        = 0
	iconBadge.ZIndex                 = contentZ + 1
	iconBadge.Parent                 = topRow

	local badgeCorner = Instance.new("UICorner")
	badgeCorner.CornerRadius = UDim.new(0, 7)
	badgeCorner.Parent = iconBadge

	local badgeStroke = Instance.new("UIStroke")
	badgeStroke.Color = accent
	badgeStroke.Thickness = 1
	badgeStroke.Transparency = 1
	badgeStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	badgeStroke.Parent = iconBadge

	local iconImg                  = Instance.new("ImageLabel")
	iconImg.Name                   = "Icon"
	iconImg.AnchorPoint            = Vector2.new(0.5, 0.5)
	iconImg.Position               = UDim2.fromScale(0.5, 0.5)
	iconImg.Size                   = UDim2.fromOffset(15, 15)
	iconImg.BackgroundTransparency = 1
	iconImg.Image                  = iconId
	iconImg.ImageColor3            = accent
	iconImg.ImageTransparency      = 1
	iconImg.ZIndex                 = contentZ + 2
	iconImg.Parent                 = iconBadge

	-- Text Column (Title + Message)
	local textCol                  = Instance.new("Frame")
	textCol.Name                   = "TextCol"
	textCol.LayoutOrder            = 2
	textCol.Size                   = UDim2.new(1, -40, 0, 0)
	textCol.AutomaticSize          = Enum.AutomaticSize.Y
	textCol.BackgroundTransparency = 1
	textCol.BorderSizePixel        = 0
	textCol.ZIndex                 = contentZ + 1
	textCol.Parent                 = topRow

	local textLayout               = Instance.new("UIListLayout")
	textLayout.FillDirection       = Enum.FillDirection.Vertical
	textLayout.SortOrder           = Enum.SortOrder.LayoutOrder
	textLayout.Padding             = UDim.new(0, 4)
	textLayout.Parent              = textCol

	-- Header Row: Title + Close Button
	local headerRow                  = Instance.new("Frame")
	headerRow.Name                   = "HeaderRow"
	headerRow.LayoutOrder            = 1
	headerRow.Size                   = UDim2.new(1, 0, 0, 16)
	headerRow.BackgroundTransparency = 1
	headerRow.BorderSizePixel        = 0
	headerRow.ZIndex                 = contentZ + 1
	headerRow.Parent                 = textCol

	local hLayout               = Instance.new("UIListLayout")
	hLayout.FillDirection       = Enum.FillDirection.Horizontal
	hLayout.VerticalAlignment   = Enum.VerticalAlignment.Center
	hLayout.SortOrder           = Enum.SortOrder.LayoutOrder
	hLayout.Padding             = UDim.new(0, 4)
	hLayout.Parent              = headerRow

	local titleLbl                  = Instance.new("TextLabel")
	titleLbl.Name                   = "Title"
	titleLbl.LayoutOrder            = 1
	titleLbl.AutomaticSize          = Enum.AutomaticSize.X
	titleLbl.Size                   = UDim2.new(0, 0, 1, 0)
	titleLbl.BackgroundTransparency = 1
	titleLbl.Font                   = Theme.Font.Title
	titleLbl.Text                   = config.Title
	titleLbl.TextSize               = 13
	titleLbl.TextColor3             = Color3.fromRGB(245, 245, 250)
	titleLbl.TextTransparency       = 1
	titleLbl.TextXAlignment         = Enum.TextXAlignment.Left
	titleLbl.TextTruncate           = Enum.TextTruncate.AtEnd
	titleLbl.ZIndex                 = contentZ + 2
	titleLbl.Parent                 = headerRow

	local headerSpacer = Instance.new("Frame")
	headerSpacer.Name                   = "Spacer"
	headerSpacer.LayoutOrder            = 2
	headerSpacer.Size                   = UDim2.new(0, 0, 1, 0)
	headerSpacer.BackgroundTransparency = 1
	headerSpacer.BorderSizePixel        = 0
	headerSpacer.Parent                 = headerRow

	local flex = Instance.new("UIFlexItem")
	flex.FlexMode = Enum.UIFlexMode.Fill
	flex.Parent = headerSpacer

	local closeBtn                  = Instance.new("TextButton")
	closeBtn.Name                   = "CloseBtn"
	closeBtn.LayoutOrder            = 3
	closeBtn.Size                   = UDim2.fromOffset(16, 16)
	closeBtn.BackgroundTransparency = 1
	closeBtn.BorderSizePixel        = 0
	closeBtn.Font                   = Enum.Font.GothamMedium
	closeBtn.Text                   = "×"
	closeBtn.TextSize               = 13
	closeBtn.TextColor3             = Color3.fromRGB(120, 120, 135)
	closeBtn.TextTransparency       = 1
	closeBtn.AutoButtonColor        = false
	closeBtn.ZIndex                 = contentZ + 2
	closeBtn.Parent                 = headerRow

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 3)
	closeCorner.Parent = closeBtn

	-- Message
	local msgLbl                  = Instance.new("TextLabel")
	msgLbl.Name                   = "Message"
	msgLbl.LayoutOrder            = 2
	msgLbl.AutomaticSize          = Enum.AutomaticSize.Y
	msgLbl.Size                   = UDim2.new(1, 0, 0, 0)
	msgLbl.BackgroundTransparency = 1
	msgLbl.Font                   = Theme.Font.Body
	msgLbl.Text                   = config.Message
	msgLbl.TextSize               = 11
	msgLbl.TextColor3             = Color3.fromRGB(185, 185, 198)
	msgLbl.TextTransparency       = 1
	msgLbl.TextXAlignment         = Enum.TextXAlignment.Left
	msgLbl.TextWrapped            = true
	msgLbl.RichText               = true
	msgLbl.LineHeight             = 1.25
	msgLbl.ZIndex                 = contentZ + 2
	msgLbl.Parent                 = textCol

	-- ── Divider ───────────────────────────────────────────────────────────────
	local divider                  = Instance.new("Frame")
	divider.Name                   = "Divider"
	divider.Size                   = UDim2.new(1, 0, 0, 1)
	divider.BackgroundColor3       = Color3.fromRGB(42, 42, 50)
	divider.BackgroundTransparency = 1
	divider.BorderSizePixel        = 0
	divider.LayoutOrder            = 2
	divider.ZIndex                 = contentZ
	divider.Parent                 = content

	-- ── Button Row ────────────────────────────────────────────────────────────
	local btnRow                  = Instance.new("Frame")
	btnRow.Name                   = "ButtonRow"
	btnRow.Size                   = UDim2.new(1, 0, 0, 28)
	btnRow.BackgroundTransparency = 1
	btnRow.BorderSizePixel        = 0
	btnRow.LayoutOrder            = 3
	btnRow.ZIndex                 = btnZ
	btnRow.Parent                 = content

	local btnLayout               = Instance.new("UIListLayout")
	btnLayout.FillDirection       = Enum.FillDirection.Horizontal
	btnLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	btnLayout.VerticalAlignment   = Enum.VerticalAlignment.Center
	btnLayout.Padding             = UDim.new(0, 8)
	btnLayout.SortOrder           = Enum.SortOrder.LayoutOrder
	btnLayout.Parent              = btnRow

	-- ── Close sequences ───────────────────────────────────────────────────────
	local closed = false

	local function closePopup()
		if closed then return end
		closed = true

		for i = #_stack, 1, -1 do
			if _stack[i] == maid then table.remove(_stack, i) break end
		end

		releaseDim(TWEEN_FADE_OUT)

		-- Smooth exit: slight scale down + unified dissolve
		TweenService:Create(shellScale, TWEEN_CLOSE_SCALE, { Scale = SCALE_CLOSE }):Play()
		TweenService:Create(shell, TWEEN_FADE_OUT, { BackgroundTransparency = 1 }):Play()
		TweenService:Create(shellStroke, TWEEN_FADE_OUT, { Transparency = 1 }):Play()
		TweenService:Create(bottomGlow, TWEEN_FADE_OUT, { BackgroundTransparency = 1 }):Play()
		TweenService:Create(iconBadge, TWEEN_FADE_OUT, { BackgroundTransparency = 1 }):Play()
		TweenService:Create(badgeStroke, TWEEN_FADE_OUT, { Transparency = 1 }):Play()
		TweenService:Create(iconImg, TWEEN_FADE_OUT, { ImageTransparency = 1 }):Play()
		TweenService:Create(titleLbl, TWEEN_FADE_OUT, { TextTransparency = 1 }):Play()
		TweenService:Create(closeBtn, TWEEN_FADE_OUT, { TextTransparency = 1 }):Play()
		TweenService:Create(msgLbl, TWEEN_FADE_OUT, { TextTransparency = 1 }):Play()
		TweenService:Create(divider, TWEEN_FADE_OUT, { BackgroundTransparency = 1 }):Play()

		if stackBadge then
			TweenService:Create(stackBadge, TWEEN_FADE_OUT, { BackgroundTransparency = 1 }):Play()
			local lbl = stackBadge:FindFirstChild("StackCount")
			if lbl and lbl:IsA("TextLabel") then
				TweenService:Create(lbl, TWEEN_FADE_OUT, { TextTransparency = 1 }):Play()
			end
		end

		for _, btn in ipairs(btnRow:GetChildren()) do
			if btn:IsA("TextButton") then
				TweenService:Create(btn, TWEEN_FADE_OUT, {
					BackgroundTransparency = 1,
					TextTransparency       = 1,
				}):Play()
				local s = btn:FindFirstChildOfClass("UIStroke")
				if s then
					TweenService:Create(s, TWEEN_FADE_OUT, { Transparency = 1 }):Play()
				end
			end
		end

		task.delay(TWEEN_CLOSE_SCALE.Time + 0.02, function()
			maid:DoCleaning()
		end)
	end

	-- ── Cancel Button ─────────────────────────────────────────────────────────
	if config.OnCancel or config.CancelText then
		local cancelBtn                  = Instance.new("TextButton")
		cancelBtn.Name                   = "CancelBtn"
		cancelBtn.LayoutOrder            = 1
		cancelBtn.AutomaticSize          = Enum.AutomaticSize.X
		cancelBtn.Size                   = UDim2.fromOffset(0, 28)
		cancelBtn.BackgroundColor3       = Color3.fromRGB(32, 32, 38)
		cancelBtn.BackgroundTransparency = 1
		cancelBtn.BorderSizePixel        = 0
		cancelBtn.Font                   = Theme.Font.Subtitle
		cancelBtn.Text                   = config.CancelText or "Cancel"
		cancelBtn.TextSize               = 11
		cancelBtn.TextColor3             = Color3.fromRGB(180, 180, 195)
		cancelBtn.TextTransparency       = 1
		cancelBtn.AutoButtonColor        = false
		cancelBtn.ZIndex                 = btnZ
		corner(cancelBtn, 6)

		local cPad = Instance.new("UIPadding")
		cPad.PaddingLeft = UDim.new(0, 12)
		cPad.PaddingRight = UDim.new(0, 12)
		cPad.Parent = cancelBtn

		local cStroke           = Instance.new("UIStroke")
		cStroke.Color           = Color3.fromRGB(52, 52, 62)
		cStroke.Thickness       = 1
		cStroke.Transparency    = 1
		cStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		cStroke.Parent          = cancelBtn

		cancelBtn.Parent = btnRow

		maid:GiveTask(cancelBtn.MouseButton1Click:Connect(function()
			closePopup()
			if config.OnCancel then config.OnCancel() end
		end))
		maid:GiveTask(cancelBtn.MouseEnter:Connect(function()
			TweenService:Create(cancelBtn, TweenInfo.new(0.12), {
				BackgroundColor3 = Color3.fromRGB(42, 42, 50),
				TextColor3       = Color3.fromRGB(255, 255, 255),
			}):Play()
		end))
		maid:GiveTask(cancelBtn.MouseLeave:Connect(function()
			TweenService:Create(cancelBtn, TweenInfo.new(0.12), {
				BackgroundColor3 = Color3.fromRGB(32, 32, 38),
				TextColor3       = Color3.fromRGB(180, 180, 195),
			}):Play()
		end))
	end

	-- ── Confirm Button ────────────────────────────────────────────────────────
	local confirmBtn                  = Instance.new("TextButton")
	confirmBtn.Name                   = "ConfirmBtn"
	confirmBtn.LayoutOrder            = 2
	confirmBtn.AutomaticSize          = Enum.AutomaticSize.X
	confirmBtn.Size                   = UDim2.fromOffset(0, 28)
	confirmBtn.BackgroundTransparency = 1
	confirmBtn.BorderSizePixel        = 0
	confirmBtn.Font                   = Theme.Font.Title
	confirmBtn.Text                   = config.ConfirmText or "Confirm"
	confirmBtn.TextSize               = 11
	confirmBtn.TextTransparency       = 1
	confirmBtn.AutoButtonColor        = false
	confirmBtn.ZIndex                 = btnZ
	corner(confirmBtn, 6)

	local cfPad = Instance.new("UIPadding")
	cfPad.PaddingLeft = UDim.new(0, 14)
	cfPad.PaddingRight = UDim.new(0, 14)
	cfPad.Parent = confirmBtn

	local btnRestBg = accent
	local btnHoverBg = accent
	local btnRestFg = Color3.fromRGB(10, 18, 28)

	if notifType == "error" then
		btnRestBg  = Theme.Colors.Error
		btnHoverBg = Theme.Colors.ErrorHover
		btnRestFg  = Color3.fromRGB(255, 255, 255)
	elseif notifType == "warning" then
		btnRestBg  = Theme.Colors.Warning
		btnHoverBg = Color3.fromHex("#fff040")
		btnRestFg  = Color3.fromRGB(15, 15, 20)
	else
		btnRestBg  = Theme.Colors.Accent
		btnHoverBg = Theme.Colors.AccentHover
		btnRestFg  = Color3.fromRGB(10, 18, 28)
	end

	confirmBtn.BackgroundColor3 = btnRestBg
	confirmBtn.TextColor3       = btnRestFg
	confirmBtn.Parent           = btnRow

	maid:GiveTask(confirmBtn.MouseButton1Click:Connect(function()
		closePopup()
		config.OnConfirm()
	end))
	maid:GiveTask(confirmBtn.MouseEnter:Connect(function()
		TweenService:Create(confirmBtn, TweenInfo.new(0.12), { BackgroundColor3 = btnHoverBg }):Play()
	end))
	maid:GiveTask(confirmBtn.MouseLeave:Connect(function()
		TweenService:Create(confirmBtn, TweenInfo.new(0.12), { BackgroundColor3 = btnRestBg }):Play()
	end))

	-- Close button top-right interactivity
	maid:GiveTask(closeBtn.MouseButton1Click:Connect(function()
		closePopup()
		if config.OnCancel then config.OnCancel() end
	end))
	maid:GiveTask(closeBtn.MouseEnter:Connect(function()
		TweenService:Create(closeBtn, TweenInfo.new(0.12), {
			BackgroundTransparency = 0.85,
			BackgroundColor3       = Theme.Colors.SurfaceHover,
			TextColor3             = Color3.fromRGB(255, 255, 255),
		}):Play()
	end))
	maid:GiveTask(closeBtn.MouseLeave:Connect(function()
		TweenService:Create(closeBtn, TweenInfo.new(0.12), {
			BackgroundTransparency = 1,
			TextColor3             = Color3.fromRGB(120, 120, 135),
		}):Play()
	end))

	-- ── Push + escape ─────────────────────────────────────────────────────────
	table.insert(_stack, maid)

	maid:GiveTask(UserInputService.InputBegan:Connect(function(input: InputObject, gpe: boolean)
		if gpe then return end
		if input.KeyCode ~= Enum.KeyCode.Escape then return end
		if _stack[#_stack] == maid then
			closePopup()
			if config.OnCancel then config.OnCancel() end
		end
	end))

	-- ── Open Animation (Smooth scale 0.94 -> 1.0 & fade in) ───────────────────
	TweenService:Create(shellScale, TWEEN_OPEN_SCALE, { Scale = 1 }):Play()
	TweenService:Create(shell, TWEEN_FADE_IN, { BackgroundTransparency = 0 }):Play()
	TweenService:Create(shellStroke, TWEEN_FADE_IN, { Transparency = 0 }):Play()
	TweenService:Create(bottomGlow, TWEEN_FADE_IN, { BackgroundTransparency = 0 }):Play()
	TweenService:Create(iconBadge, TWEEN_FADE_IN, { BackgroundTransparency = 0.86 }):Play()
	TweenService:Create(badgeStroke, TWEEN_FADE_IN, { Transparency = 0.65 }):Play()
	TweenService:Create(iconImg, TWEEN_FADE_IN, { ImageTransparency = 0 }):Play()
	TweenService:Create(titleLbl, TWEEN_FADE_IN, { TextTransparency = 0 }):Play()
	TweenService:Create(closeBtn, TWEEN_FADE_IN, { TextTransparency = 0 }):Play()
	TweenService:Create(msgLbl, TWEEN_FADE_IN, { TextTransparency = 0 }):Play()
	TweenService:Create(divider, TWEEN_FADE_IN, { BackgroundTransparency = 0 }):Play()

	if stackBadge then
		TweenService:Create(stackBadge, TWEEN_FADE_IN, { BackgroundTransparency = 0 }):Play()
		local lbl = stackBadge:FindFirstChild("StackCount")
		if lbl and lbl:IsA("TextLabel") then
			TweenService:Create(lbl, TWEEN_FADE_IN, { TextTransparency = 0 }):Play()
		end
	end

	for _, btn in ipairs(btnRow:GetChildren()) do
		if btn:IsA("TextButton") then
			local targetBgT = (btn.Name == "CancelBtn") and 0 or 0
			TweenService:Create(btn, TWEEN_FADE_IN, {
				BackgroundTransparency = targetBgT,
				TextTransparency       = 0,
			}):Play()
			local s = btn:FindFirstChildOfClass("UIStroke")
			if s then
				TweenService:Create(s, TWEEN_FADE_IN, { Transparency = 0 }):Play()
			end
		end
	end
end

return Popup
