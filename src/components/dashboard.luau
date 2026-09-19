--!strict

-- Delirium UI Library
-- dashboard.luau — Compact sidebar card widget + full-screen tabbed player dashboard.
-- Clicking the sidebar card deselects all real tabs and shows the dashboard content
-- in the main contentArea — identical to how a regular Tab.Show() behaves.
-- Wiring is done externally by Window:CreatePlayerCard().

local services  = require(script.Parent.Parent.utility.services)
local tween     = require(script.Parent.Parent.utility.tween)
local themeUtil = require(script.Parent.Parent.utility.theme)
local constants = require(script.Parent.Parent.utility.constants)
local variables = require(script.Parent.Parent.utility.variables)

local Players      = services.getService("Players") :: Players
local TweenService = services.getService("TweenService") :: TweenService
local RunService   = services.getService("RunService") :: RunService
local StatsService = services.getService("Stats") :: Stats

local TWEEN_TAB  = TweenInfo.new(0.16, Enum.EasingStyle.Quad,  Enum.EasingDirection.Out)
local THUMB_TYPE = Enum.ThumbnailType.HeadShot
local THUMB_SIZE = Enum.ThumbnailSize.Size100x100

export type Dashboard = {
	_cardFrame:   Frame,
	_content:     Frame,
	_themeUnsub:  () -> (),
	ShowContent:  (self: Dashboard) -> (),
	HideContent:  (self: Dashboard) -> (),
	Destroy:      (self: Dashboard) -> (),
}

local Dashboard = {}
Dashboard.__index = Dashboard

-- ── Helpers ───────────────────────────────────────────────────────────────────

local function formatAge(days: number): string
	if days >= 365 then
		local y = math.floor(days / 365)
		return y == 1 and "1 year" or y .. " years"
	elseif days >= 30 then
		local m = math.floor(days / 30)
		return m == 1 and "1 month" or m .. " months"
	else
		return days == 1 and "1 day" or days .. " days"
	end
end

local function formatTime(secs: number): string
	local h = math.floor(secs / 3600)
	local m = math.floor((secs % 3600) / 60)
	local s = math.floor(secs % 60)
	if h > 0 then return string.format("%dh %02dm", h, m)
	elseif m > 0 then return string.format("%dm %02ds", m, s)
	else return string.format("%ds", s) end
end

local function makeCircle(parent: Instance, size: number): Frame
	local f = Instance.new("Frame")
	f.Size = UDim2.fromOffset(size, size); f.BackgroundColor3 = Color3.fromRGB(0,0,0)
	f.BorderSizePixel = 0; f.ClipsDescendants = true; f.Parent = parent
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1,0); c.Parent = f
	return f
end

-- ── Dashboard.new ─────────────────────────────────────────────────────────────
--[[
	sidebarSlot  — Frame at the bottom of the sidebar (compact card lives here)
	contentArea  — main content Frame (dashboard page parented here, like a Tab)
	theme        — resolved theme table
	(windowFrame param kept for signature compat but unused here)
]]
function Dashboard.new(
	sidebarSlot:  Frame,
	_windowFrame: Frame,
	contentArea:  Frame,
	theme:        { [string]: any }
): Dashboard

	local lp: Player = Players.LocalPlayer

	-- ── Tokens ────────────────────────────────────────────────────────────
	local function getTokens(t: { [string]: any })
		return {
			accent        = t.AccentColor        or Color3.fromHex("#4cc2ff"),
			accentDim     = t.AccentMuted         or Color3.fromHex("#1a3d52"),
			border        = t.SurfaceStroke       or Color3.fromHex("#2b2b2b"),
			surface       = t.TitleBarColor       or Color3.fromHex("#111114"),
			surfaceMid    = t.WindowColor.Keypoints[1].Value,
			textPrimary   = t.TitlingColor        or Color3.fromHex("#ffffff"),
			textSecondary = t.PlaceholderColor    or Color3.fromHex("#8a8a92"),
			neutralBtn    = t.NeutralButton       or Color3.fromHex("#1e1e1e"),
			neutralHover  = t.NeutralButtonHover  or Color3.fromHex("#252525"),
			errorColor    = t.ErrorColor          or Color3.fromHex("#ff4f58"),
			font          = t.Font                or Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium),
			fontBold      = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold),
			fontXBold     = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold),
			elemCorner    = t.ElementCornerRadius or UDim.new(0, 8),
			winGradient   = t.WindowColor,
		}
	end

	local tk = getTokens(theme)

	-- ═══════════════════════════════════════════════════════════════════════
	-- PART 1: Compact sidebar card
	-- ═══════════════════════════════════════════════════════════════════════

	local card = Instance.new("Frame")
	card.Name = "Dashboard"; card.Size = UDim2.new(1,0,1,0)
	card.BackgroundColor3 = tk.surface; card.BorderSizePixel = 0
	card.ClipsDescendants = false; card.Parent = sidebarSlot

	-- Top separator
	local topSep = Instance.new("Frame")
	topSep.Name = "TopSep"; topSep.Size = UDim2.new(1,0,0,1)
	topSep.BackgroundColor3 = tk.border; topSep.BackgroundTransparency = 0.4
	topSep.BorderSizePixel = 0; topSep.Parent = card

	-- Full-card hit button (click = switch to dashboard content like a tab)
	local cardHit = Instance.new("TextButton")
	cardHit.Name = "Hit"; cardHit.Size = UDim2.fromScale(1,1)
	cardHit.BackgroundTransparency = 1; cardHit.Text = ""
	cardHit.AutoButtonColor = false; cardHit.ZIndex = 2; cardHit.Parent = card

	-- Avatar clip — plain circle, no ring/stroke
	local avatarClip = makeCircle(card, 36)
	avatarClip.Name = "AvatarClip"; avatarClip.AnchorPoint = Vector2.new(0,0.5)
	avatarClip.Position = UDim2.new(0,10,0.5,0); avatarClip.ZIndex = 2

	local avatarImg = Instance.new("ImageLabel")
	avatarImg.Name = "Avatar"; avatarImg.Size = UDim2.fromScale(1,1)
	avatarImg.BackgroundColor3 = Color3.fromHex("#1c1c1f"); avatarImg.BorderSizePixel = 0
	avatarImg.Image = ""; avatarImg.ScaleType = Enum.ScaleType.Fit
	avatarImg.ZIndex = 2; avatarImg.Parent = avatarClip

	-- Name stack
	local nameStack = Instance.new("Frame")
	nameStack.Name = "NameStack"; nameStack.AnchorPoint = Vector2.new(0,0.5)
	nameStack.Position = UDim2.new(0,54,0.5,0); nameStack.Size = UDim2.new(1,-66,0,36)
	nameStack.BackgroundTransparency = 1; nameStack.ZIndex = 2; nameStack.Parent = card
	do
		local l = Instance.new("UIListLayout"); l.FillDirection = Enum.FillDirection.Vertical
		l.VerticalAlignment = Enum.VerticalAlignment.Center; l.Padding = UDim.new(0,2); l.Parent = nameStack
	end

	local dispLbl = Instance.new("TextLabel")
	dispLbl.Name = "DisplayName"; dispLbl.Size = UDim2.new(1,0,0,16)
	dispLbl.BackgroundTransparency = 1; dispLbl.Text = lp.DisplayName
	dispLbl.TextColor3 = tk.textPrimary; dispLbl.TextSize = 13
	dispLbl.FontFace = tk.fontBold; dispLbl.TextXAlignment = Enum.TextXAlignment.Left
	dispLbl.TextTruncate = Enum.TextTruncate.AtEnd; dispLbl.ZIndex = 3; dispLbl.Parent = nameStack

	local userLbl = Instance.new("TextLabel")
	userLbl.Name = "Username"; userLbl.Size = UDim2.new(1,0,0,13)
	userLbl.BackgroundTransparency = 1; userLbl.Text = "@" .. lp.Name
	userLbl.TextColor3 = tk.textSecondary; userLbl.TextSize = 11
	userLbl.FontFace = tk.font; userLbl.TextXAlignment = Enum.TextXAlignment.Left
	userLbl.TextTruncate = Enum.TextTruncate.AtEnd; userLbl.ZIndex = 3; userLbl.Parent = nameStack

	-- Chevron hint — rotates to accent when content is active
	local chevron = Instance.new("TextLabel")
	chevron.Name = "Chevron"; chevron.AnchorPoint = Vector2.new(1,0.5)
	chevron.Position = UDim2.new(1,-8,0.5,0); chevron.Size = UDim2.fromOffset(14,14)
	chevron.BackgroundTransparency = 1; chevron.Text = "›"
	chevron.TextColor3 = tk.textSecondary; chevron.TextSize = 16
	chevron.FontFace = tk.fontBold; chevron.ZIndex = 3; chevron.Parent = card

	-- Card hover
	cardHit.MouseEnter:Connect(function()
		tween.fire(card, TweenInfo.new(0.14, Enum.EasingStyle.Quad), { BackgroundColor3 = tk.neutralHover })
	end)
	cardHit.MouseLeave:Connect(function()
		tween.fire(card, TweenInfo.new(0.14, Enum.EasingStyle.Quad), { BackgroundColor3 = tk.surface })
	end)

	-- ═══════════════════════════════════════════════════════════════════════
	-- PART 2: Dashboard content (lives in contentArea like a Tab canvas)
	-- ═══════════════════════════════════════════════════════════════════════

	local content = Instance.new("Frame")
	content.Name = "DashboardContent"
	content.Size = UDim2.fromScale(1, 1)
	content.BackgroundTransparency = 1
	content.Visible = false
	content.ClipsDescendants = true
	content.Parent = contentArea

	-- ── Inner tab bar (Profile / Stats / Session) ──────────────────────────
	local TAB_BAR_H = 40
	local TAB_DEFS  = { "Profile", "Stats", "Session" }

	local tabBar = Instance.new("Frame")
	tabBar.Name = "TabBar"; tabBar.Size = UDim2.new(1,0,0,TAB_BAR_H)
	tabBar.BackgroundColor3 = tk.surface; tabBar.BackgroundTransparency = 0
	tabBar.BorderSizePixel = 0; tabBar.ZIndex = 2; tabBar.Parent = content
	do
		local l = Instance.new("UIListLayout"); l.FillDirection = Enum.FillDirection.Horizontal
		l.HorizontalAlignment = Enum.HorizontalAlignment.Left
		l.VerticalAlignment = Enum.VerticalAlignment.Center
		l.SortOrder = Enum.SortOrder.LayoutOrder; l.Parent = tabBar
	end

	local tabBarSep = Instance.new("Frame")
	tabBarSep.Name = "TabBarSep"; tabBarSep.AnchorPoint = Vector2.new(0,1)
	tabBarSep.Position = UDim2.new(0,0,1,0); tabBarSep.Size = UDim2.new(1,0,0,1)
	tabBarSep.BackgroundColor3 = tk.border; tabBarSep.BackgroundTransparency = 0.4
	tabBarSep.BorderSizePixel = 0; tabBarSep.ZIndex = 3; tabBarSep.Parent = tabBar

	-- Content area below tab bar
	local CONTENT_TOP = TAB_BAR_H + 1

	-- ── Build inner tabs ──────────────────────────────────────────────────
	local tabEntries: { { btn: TextButton, underline: Frame, scroll: ScrollingFrame } } = {}
	local activeTabIdx = 1

	local function getTabW(): number
		-- Use content AbsoluteSize if available, fallback to full contentArea size hint
		local fullW = contentArea.AbsoluteSize.X
		if fullW < 10 then fullW = 600 end -- sane fallback before first render
		return math.floor(fullW / #TAB_DEFS)
	end

	local function buildTab(label: string, order: number)
		local btn = Instance.new("TextButton")
		btn.Name = "Tab_" .. label
		btn.Size = UDim2.new(1 / #TAB_DEFS, 0, 1, 0) -- equal thirds, auto-distributes
		btn.BackgroundTransparency = 1; btn.Text = label
		btn.TextColor3 = tk.textSecondary; btn.TextSize = 12
		btn.FontFace = tk.fontBold; btn.AutoButtonColor = false
		btn.ZIndex = 3; btn.LayoutOrder = order; btn.Parent = tabBar

		local underline = Instance.new("Frame")
		underline.Name = "Underline"; underline.AnchorPoint = Vector2.new(0.5,1)
		underline.Position = UDim2.new(0.5,0,1,0)
		underline.Size = UDim2.fromOffset(0, 2) -- starts hidden, tweens to width on activate
		underline.BackgroundColor3 = tk.accent; underline.BorderSizePixel = 0
		underline.ZIndex = 4; underline.Parent = btn
		do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1,0); c.Parent = underline end

		local scroll = Instance.new("ScrollingFrame")
		scroll.Name = "Content_" .. label
		scroll.Position = UDim2.fromOffset(0, CONTENT_TOP)
		scroll.Size = UDim2.new(1, 0, 1, -CONTENT_TOP)
		scroll.BackgroundTransparency = 1; scroll.BorderSizePixel = 0
		scroll.ScrollBarThickness = 2; scroll.ScrollBarImageColor3 = tk.border
		scroll.ScrollBarImageTransparency = 0.5
		scroll.CanvasSize = UDim2.fromOffset(0,0); scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
		scroll.ClipsDescendants = true; scroll.ZIndex = 2
		scroll.Visible = false; scroll.Parent = content
		do
			local l = Instance.new("UIListLayout"); l.FillDirection = Enum.FillDirection.Vertical
			l.VerticalAlignment = Enum.VerticalAlignment.Top; l.Padding = UDim.new(0,0)
			l.SortOrder = Enum.SortOrder.LayoutOrder; l.Parent = scroll
		end
		do local p = Instance.new("UIPadding"); p.PaddingBottom = UDim.new(0,20); p.Parent = scroll end

		return btn, underline, scroll
	end

	for i, label in ipairs(TAB_DEFS) do
		local btn, ul, scroll = buildTab(label, i)
		table.insert(tabEntries, { btn = btn, underline = ul, scroll = scroll })
	end

	-- ── Tab switcher ──────────────────────────────────────────────────────
	local function selectInnerTab(idx: number)
		activeTabIdx = idx
		for i, entry in ipairs(tabEntries) do
			local active = (i == idx)
			TweenService:Create(entry.btn, TWEEN_TAB, {
				TextColor3 = if active then tk.accent else tk.textSecondary
			}):Play()
			-- underline width = button AbsoluteSize.X - 32px padding each side
			-- use a generous fixed width since AbsoluteSize may not be computed yet
			TweenService:Create(entry.underline, TWEEN_TAB, {
				Size = if active then UDim2.fromOffset(60, 2) else UDim2.fromOffset(0, 2)
			}):Play()
			entry.scroll.Visible = active
		end
	end

	for i, entry in ipairs(tabEntries) do
		local idx = i
		entry.btn.MouseButton1Click:Connect(function() selectInnerTab(idx) end)
	end

	-- ── Helper: section label ─────────────────────────────────────────────
	local function makeSecLabel(parent: ScrollingFrame, text: string, order: number)
		local lbl = Instance.new("TextLabel")
		lbl.Name = "Sec_" .. text; lbl.Size = UDim2.new(1,0,0,28)
		lbl.BackgroundTransparency = 1; lbl.Text = text
		lbl.TextColor3 = tk.textSecondary; lbl.TextTransparency = 0.3
		lbl.TextSize = 9; lbl.FontFace = tk.fontXBold
		lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.LayoutOrder = order
		lbl.ZIndex = 3; lbl.Parent = parent
		do
			local p = Instance.new("UIPadding"); p.PaddingLeft = UDim.new(0,14)
			p.PaddingTop = UDim.new(0,10); p.Parent = lbl
		end
	end

	-- ── Helper: stat row card ─────────────────────────────────────────────
	local function makeStatCard(
		parent: ScrollingFrame,
		labelText: string,
		valueText: string,
		order: number,
		accentLeft: boolean?
	): TextLabel
		local wrap = Instance.new("Frame")
		wrap.Name = "Wrap_" .. labelText:gsub(" ","_"); wrap.Size = UDim2.new(1,0,0,42)
		wrap.BackgroundTransparency = 1; wrap.LayoutOrder = order; wrap.ZIndex = 2; wrap.Parent = parent
		do local p = Instance.new("UIPadding"); p.PaddingLeft = UDim.new(0,12); p.PaddingRight = UDim.new(0,12); p.Parent = wrap end

		local row = Instance.new("Frame")
		row.Name = "Row"; row.Size = UDim2.new(1,0,1,-6)
		row.AnchorPoint = Vector2.new(0,0.5); row.Position = UDim2.fromScale(0,0.5)
		row.BackgroundColor3 = Color3.fromRGB(255,255,255); row.BackgroundTransparency = 0.955
		row.BorderSizePixel = 0; row.ZIndex = 2; row.Parent = wrap
		do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,8); c.Parent = row end
		do
			local sk = Instance.new("UIStroke"); sk.Color = tk.border; sk.Thickness = 1
			sk.Transparency = 0.55; sk.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; sk.Parent = row
		end
		do local p = Instance.new("UIPadding"); p.PaddingLeft = UDim.new(0,12); p.PaddingRight = UDim.new(0,12); p.Parent = row end

		if accentLeft then
			local bar = Instance.new("Frame")
			bar.Size = UDim2.new(0,3,0,16); bar.AnchorPoint = Vector2.new(0,0.5)
			bar.Position = UDim2.new(0,0,0.5,0); bar.BackgroundColor3 = tk.accent
			bar.BorderSizePixel = 0; bar.ZIndex = 3; bar.Parent = row
			do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1,0); c.Parent = bar end
		end

		local off = if accentLeft then 10 else 0
		local lbl = Instance.new("TextLabel")
		lbl.Name = "Label"; lbl.AnchorPoint = Vector2.new(0,0.5)
		lbl.Position = UDim2.new(0,off,0.5,0); lbl.Size = UDim2.new(0.55,0,0,14)
		lbl.BackgroundTransparency = 1; lbl.Text = labelText
		lbl.TextColor3 = tk.textSecondary; lbl.TextSize = 12
		lbl.FontFace = tk.font; lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.ZIndex = 3; lbl.Parent = row

		local val = Instance.new("TextLabel")
		val.Name = "Value"; val.AnchorPoint = Vector2.new(1,0.5)
		val.Position = UDim2.fromScale(1,0.5); val.Size = UDim2.new(0.5,0,0,14)
		val.BackgroundTransparency = 1; val.Text = valueText
		val.TextColor3 = tk.textPrimary; val.TextSize = 12
		val.FontFace = tk.fontBold; val.TextXAlignment = Enum.TextXAlignment.Right
		val.TextTruncate = Enum.TextTruncate.AtEnd; val.ZIndex = 3; val.Parent = row

		return val
	end

	-- ══════════════════════════
	-- TAB 1: Profile
	-- ══════════════════════════
	local profScroll = tabEntries[1].scroll

	-- Hero card (centered avatar + name + chips)
	local heroCard = Instance.new("Frame")
	heroCard.Name = "HeroCard"; heroCard.Size = UDim2.new(1,0,0,0)
	heroCard.AutomaticSize = Enum.AutomaticSize.Y
	heroCard.BackgroundTransparency = 1; heroCard.LayoutOrder = 1; heroCard.Parent = profScroll
	do
		local p = Instance.new("UIPadding"); p.PaddingTop = UDim.new(0,24)
		p.PaddingBottom = UDim.new(0,16); p.Parent = heroCard
	end
	do
		local l = Instance.new("UIListLayout"); l.FillDirection = Enum.FillDirection.Vertical
		l.HorizontalAlignment = Enum.HorizontalAlignment.Center
		l.VerticalAlignment = Enum.VerticalAlignment.Top
		l.Padding = UDim.new(0,10); l.Parent = heroCard
	end

	local bigRing = Instance.new("Frame")
	bigRing.Name = "BigRing"; bigRing.Size = UDim2.fromOffset(96,96)
	bigRing.BackgroundColor3 = tk.accent; bigRing.BackgroundTransparency = 1
	bigRing.BorderSizePixel = 0; bigRing.ZIndex = 2; bigRing.Parent = heroCard
	do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1,0); c.Parent = bigRing end

	local bigClip = makeCircle(bigRing, 86)
	bigClip.AnchorPoint = Vector2.new(0.5,0.5); bigClip.Position = UDim2.fromScale(0.5,0.5); bigClip.ZIndex = 3

	local bigAvatar = Instance.new("ImageLabel")
	bigAvatar.Name = "BigAvatar"; bigAvatar.Size = UDim2.fromScale(1,1)
	bigAvatar.BackgroundColor3 = Color3.fromHex("#1c1c1f"); bigAvatar.BorderSizePixel = 0
	bigAvatar.Image = ""; bigAvatar.ScaleType = Enum.ScaleType.Fit
	bigAvatar.ZIndex = 4; bigAvatar.Parent = bigClip

	local bigName = Instance.new("TextLabel")
	bigName.Name = "BigName"; bigName.Size = UDim2.new(1,-32,0,24)
	bigName.BackgroundTransparency = 1; bigName.Text = lp.DisplayName
	bigName.TextColor3 = tk.textPrimary; bigName.TextSize = 18
	bigName.FontFace = tk.fontBold; bigName.TextXAlignment = Enum.TextXAlignment.Center
	bigName.TextTruncate = Enum.TextTruncate.AtEnd; bigName.ZIndex = 3; bigName.Parent = heroCard

	-- Chip row
	local chipRow = Instance.new("Frame")
	chipRow.Name = "ChipRow"; chipRow.Size = UDim2.new(1,-32,0,24)
	chipRow.BackgroundTransparency = 1; chipRow.ZIndex = 3; chipRow.Parent = heroCard
	do
		local l = Instance.new("UIListLayout"); l.FillDirection = Enum.FillDirection.Horizontal
		l.HorizontalAlignment = Enum.HorizontalAlignment.Center
		l.VerticalAlignment = Enum.VerticalAlignment.Center
		l.Padding = UDim.new(0,6); l.Parent = chipRow
	end

	local function makeChip(text: string, isAccent: boolean)
		local chip = Instance.new("Frame")
		chip.Size = UDim2.new(0,0,1,0); chip.AutomaticSize = Enum.AutomaticSize.X
		chip.BackgroundColor3 = if isAccent then tk.accentDim else Color3.fromRGB(255,255,255)
		chip.BackgroundTransparency = if isAccent then 0 else 0.92
		chip.BorderSizePixel = 0; chip.ZIndex = 4; chip.Parent = chipRow
		do
			local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1,0); c.Parent = chip
			local p = Instance.new("UIPadding"); p.PaddingLeft = UDim.new(0,8); p.PaddingRight = UDim.new(0,8); p.Parent = chip
		end
		local lbl2 = Instance.new("TextLabel")
		lbl2.Size = UDim2.new(0,0,1,0); lbl2.AutomaticSize = Enum.AutomaticSize.X
		lbl2.BackgroundTransparency = 1; lbl2.Text = text
		lbl2.TextColor3 = if isAccent then tk.accent else tk.textSecondary; lbl2.TextSize = 11
		lbl2.FontFace = tk.fontBold; lbl2.ZIndex = 5; lbl2.Parent = chip
	end
	makeChip("@" .. lp.Name, false)
	makeChip("ID " .. tostring(lp.UserId), true)

	-- Divider
	local profDiv = Instance.new("Frame")
	profDiv.Name = "Divider"; profDiv.Size = UDim2.new(1,-28,0,1)
	profDiv.BackgroundColor3 = tk.border; profDiv.BackgroundTransparency = 0.45
	profDiv.BorderSizePixel = 0; profDiv.LayoutOrder = 2; profDiv.ZIndex = 2; profDiv.Parent = profScroll

	makeSecLabel(profScroll, "IDENTITY", 3)
	makeStatCard(profScroll, "Display Name", lp.DisplayName,            4, true)
	makeStatCard(profScroll, "Username",     "@" .. lp.Name,            5, true)
	makeStatCard(profScroll, "User ID",      tostring(lp.UserId),       6, true)
	makeStatCard(profScroll, "Account Age",  formatAge(lp.AccountAge),  7, true)

	-- ══════════════════════════
	-- TAB 2: Stats
	-- ══════════════════════════
	local statsScroll = tabEntries[2].scroll

	makeSecLabel(statsScroll, "ACCOUNT", 1)
	makeStatCard(statsScroll, "Account Age",  formatAge(lp.AccountAge),                            2)
	makeStatCard(statsScroll, "User ID",      tostring(lp.UserId),                                 3)
	local memberRow = makeStatCard(statsScroll, "Membership", "—",                                 4)
	local teamRow   = makeStatCard(statsScroll, "Team",       lp.Team and lp.Team.Name or "—",     5)

	pcall(function()
		local tier = lp.MembershipType
		memberRow.Text = if tier == Enum.MembershipType.Premium then "Premium"
			elseif tier == Enum.MembershipType.None then "None"
			else "—"
	end)

	makeSecLabel(statsScroll, "PLACE", 10)
	makeStatCard(statsScroll, "Place ID",  tostring(game.PlaceId),                           11)
	makeStatCard(statsScroll, "Game ID",   tostring(game.GameId),                            12)
	local jobIdFull = tostring(game.JobId)
	makeStatCard(statsScroll, "Job ID",    if #jobIdFull > 14 then jobIdFull:sub(1,12) .. "…" else jobIdFull, 13)

	-- Executor detection — tries executor-injected globals, safe fallback in Studio
	local executorName: string = "—"
	pcall(function()
		-- getfenv is re-enabled by most executors; nil in vanilla → pcall catches the call error
		local env: any = (getfenv :: any)(0)
		local fn: any = env.identifyexecutor or env.getexecutorname or env.EXECUTOR_NAME
		if type(fn) == "function" then
			executorName = tostring(fn())
		elseif type(fn) == "string" then
			executorName = fn
		end
	end)

	makeSecLabel(statsScroll, "RUNTIME", 20)
	makeStatCard(statsScroll, "Executor", executorName, 21)

	-- ══════════════════════════
	-- TAB 3: Session
	-- ══════════════════════════
	local sessScroll = tabEntries[3].scroll

	makeSecLabel(sessScroll, "PERFORMANCE", 1)
	local pingRow   = makeStatCard(sessScroll, "Ping",    "—",  2, true)
	local fpsRow    = makeStatCard(sessScroll, "FPS",     "—",  3, true)
	local uptimeRow = makeStatCard(sessScroll, "Session", "0s", 4, true)

	makeSecLabel(sessScroll, "CHARACTER", 10)
	local healthRow = makeStatCard(sessScroll, "Health",    "—", 11, true)
	local wsRow     = makeStatCard(sessScroll, "WalkSpeed", "—", 12, true)
	local jpRow     = makeStatCard(sessScroll, "JumpPower", "—", 13, true)

	makeSecLabel(sessScroll, "SERVER", 20)
	makeStatCard(sessScroll, "Place ID", tostring(game.PlaceId),  21)
	makeStatCard(sessScroll, "Job ID",   if #jobIdFull > 14 then jobIdFull:sub(1,12) .. "…" else jobIdFull, 22)

	-- ── Live update heartbeat (dynamic: active only when dashboard is visible) ──
	local sessionStart = os.clock()
	local pingTimer = 0; local fpsTimer = 0; local fpsCount = 0; local charTimer = 0
	local liveConn: RBXScriptConnection? = nil

	local function startLiveUpdates()
		if liveConn then return end
		liveConn = RunService.Heartbeat:Connect(function(dt)
			if not contentVisible then return end

			fpsCount += 1; fpsTimer += dt
			if fpsTimer >= 0.5 then
				fpsRow.Text = tostring(math.round(fpsCount / fpsTimer)) .. " fps"
				fpsCount = 0; fpsTimer = 0
			end

			uptimeRow.Text = formatTime(os.clock() - sessionStart)

			pingTimer += dt
			if pingTimer >= 1.5 then
				pingTimer = 0
				local ok, ms = pcall(function()
					return math.round((StatsService :: any).Network.ServerStatsItem["Data Ping"]:GetValue())
				end)
				pingRow.Text = if ok then tostring(ms) .. " ms" else "—"
			end

			charTimer += dt
			if charTimer >= 0.5 then
				charTimer = 0
				pcall(function()
					local char = lp.Character; if not char then return end
					local hum = char:FindFirstChildOfClass("Humanoid"); if not hum then return end
					healthRow.Text = math.round(hum.Health) .. " / " .. math.round(hum.MaxHealth)
					wsRow.Text = tostring(hum.WalkSpeed)
					jpRow.Text = tostring(hum.JumpPower)
				end)
			end
		end)
	end

	local function stopLiveUpdates()
		if liveConn then
			liveConn:Disconnect()
			liveConn = nil
		end
	end

	-- Team watcher
	local teamConn = lp:GetPropertyChangedSignal("Team"):Connect(function()
		teamRow.Text = lp.Team and lp.Team.Name or "—"
	end)

	-- ── Async avatar fetch ────────────────────────────────────────────────
	task.spawn(function()
		local ok, url = pcall(function()
			return Players:GetUserThumbnailAsync(lp.UserId, THUMB_TYPE, THUMB_SIZE)
		end)
		if ok and url then
			avatarImg.Image = url
			bigAvatar.Image = url
		end
	end)

	-- ═══════════════════════════════════════════════════════════════════════
	-- PART 3: ShowContent / HideContent (called by window.luau)
	-- ═══════════════════════════════════════════════════════════════════════

	local contentVisible = false

	local function showContent()
		if contentVisible then return end
		contentVisible = true
		content.Visible = true
		selectInnerTab(1) -- always reset to Profile tab on open
		startLiveUpdates()
		-- Make card look "active" (like a selected tab button)
		tween.fire(card, TweenInfo.new(0.14, Enum.EasingStyle.Quad), { BackgroundColor3 = tk.neutralHover })
		tween.fire(chevron, TweenInfo.new(0.14, Enum.EasingStyle.Quad), { TextColor3 = tk.accent })
	end

	local function hideContent()
		if not contentVisible then return end
		contentVisible = false
		content.Visible = false
		stopLiveUpdates()
		tween.fire(card, TweenInfo.new(0.14, Enum.EasingStyle.Quad), { BackgroundColor3 = tk.surface })
		tween.fire(chevron, TweenInfo.new(0.14, Enum.EasingStyle.Quad), { TextColor3 = tk.textSecondary })
	end

	-- ── Theme subscription ────────────────────────────────────────────────
	local themeUnsub = themeUtil.subscribe(function(t)
		tk = getTokens(t)
		card.BackgroundColor3    = if contentVisible then tk.neutralHover else tk.surface
		bigRing.BackgroundColor3 = tk.accent
		dispLbl.TextColor3          = tk.textPrimary
		userLbl.TextColor3          = tk.textSecondary
		bigName.TextColor3          = tk.textPrimary
		chevron.TextColor3          = if contentVisible then tk.accent else tk.textSecondary
		tabBar.BackgroundColor3     = tk.surface
		for i, entry in ipairs(tabEntries) do
			entry.underline.BackgroundColor3 = tk.accent
			entry.btn.TextColor3 = if i == activeTabIdx then tk.accent else tk.textSecondary
		end
	end)

	-- ── Finalise ──────────────────────────────────────────────────────────
	local self: Dashboard = setmetatable({}, Dashboard) :: any
	local s = self :: any
	s._cardFrame   = card
	s._content     = content
	s._stopLiveUpdates = stopLiveUpdates
	s._teamConn        = teamConn
	s._themeUnsub      = themeUnsub
	s._showContent     = showContent
	s._hideContent     = hideContent
	s._cardHit         = cardHit

	return self
end

function Dashboard:ShowContent()
	(self :: any)._showContent()
end

function Dashboard:HideContent()
	(self :: any)._hideContent()
end

function Dashboard:Destroy()
	local s = (self :: any)
	if s._stopLiveUpdates then s._stopLiveUpdates() end
	if s._themeUnsub      then s._themeUnsub() end
	if s._teamConn        then s._teamConn:Disconnect() end
	if s._content         then s._content:Destroy() end
	if s._cardFrame       then s._cardFrame:Destroy() end
end

return Dashboard
