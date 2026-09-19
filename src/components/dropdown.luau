--!strict

-- Delirium UI Library
-- dropdown.luau — Oldsrc dropdown layout & behavior ported to src, with zero animations.
-- Supports single/multi-select, searchable lists, special types (Player/Team), per-item disable, and flag persistence.

-- B5 FIX: was raw game:GetService — use cloneref-safe wrappers.
local constants = require(script.Parent.Parent.utility.constants)
local flags     = require(script.Parent.Parent.utility.flags)
local runtime   = require(script.Parent.Parent.utility.runtime)
local services  = require(script.Parent.Parent.utility.services)
local signal    = require(script.Parent.Parent.utility.signal)
local themeUtil = require(script.Parent.Parent.utility.theme)
local icons     = require(script.Parent.Parent.utility.icons)

local UserInputService = runtime.userInputService
local Players          = services.getService("Players") :: Players
local Teams            = services.getService("Teams") :: Teams

local HEADER_H        = 36
local LIST_GAP        = 4
local OPTION_H        = 34
local CHECK_W         = 20
local SEARCH_H        = 32
local MAX_H_DEFAULT   = 170

-- B3 FIX: module-level font constants so every theme-listener broadcast doesn't
-- allocate a fresh Font object per element that omits t.Font.
local DEFAULT_FONT       = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium)
local DEFAULT_FONT_SEMI  = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold)

export type DropdownOption = { Label: string, Value: any }

export type DropdownProps = {
	name:                    string?,
	Label:                   string?,
	Text:                    string?,
	description:             string?,
	Tooltip:                 string?,
	flag:                    string?,
	Flag:                    string?,
	options:                 { any }?,
	Options:                 { any }?,
	value:                   any?,
	default:                 any?,
	Default:                 any?,
	multiSelect:             boolean?,
	MultiSelect:             boolean?,
	placeholder:             string?,
	Placeholder:             string?,
	searchable:              boolean?,
	Searchable:              boolean?,
	disabledValues:          { any }?,
	DisabledValues:          { any }?,
	formatDisplayValue:      ((value: any) -> string)?,
	FormatDisplayValue:      ((value: any) -> string)?,
	maxVisibleDropdownItems: number?,
	MaxVisibleDropdownItems: number?,
	specialType:             string?,
	SpecialType:             string?,
	enabled:                 boolean?,
	Enabled:                 boolean?,
	layoutOrder:             number?,
	LayoutOrder:             number?,
	callback:                ((value: any) -> ())?,
	Callback:                ((value: any) -> ())?,
}

export type Dropdown = {
	value:      any,
	Value:      any,
	Changed:    any,
	_frame:     Frame,
	Set:        (self: Dropdown, value: any, skipCallback: boolean?) -> (),
	SetValue:   (self: Dropdown, value: any, skipCallback: boolean?) -> (),
	SetOptions: (self: Dropdown, options: { any }) -> (),
	SetEnabled: (self: Dropdown, enabled: boolean) -> (),
	GetFrame:   (self: Dropdown) -> Frame,
	Destroy:    (self: Dropdown) -> (),
}

local Dropdown = {}
Dropdown.__index = Dropdown

-- ── Option Normalization ──────────────────────────────────────────────────────

local function normalizeOptions(raw: { any }?): { DropdownOption }
	local out: { DropdownOption } = {}
	if not raw then return out end
	for _, v in ipairs(raw) do
		if typeof(v) == "string" then
			table.insert(out, { Label = v, Value = v })
		elseif typeof(v) == "table" and v.Label ~= nil and v.Value ~= nil then
			table.insert(out, v :: DropdownOption)
		else
			table.insert(out, { Label = tostring(v), Value = v })
		end
	end
	return out
end

local function normalizeDefault(raw: any): { any }
	if raw == nil then return {} end
	if typeof(raw) == "table" then return raw end
	return { raw }
end

-- ── Header Text Builder ───────────────────────────────────────────────────────

local function getHeaderText(s: any): (string, boolean)
	if s._multiSelect then
		local labels: { string } = {}
		for _, opt in ipairs(s._options) do
			if s._selectedSet[opt.Value] then
				local display = if s._formatDisplay
					then s._formatDisplay(opt.Value)
					else opt.Label
				table.insert(labels, display)
			end
		end
		if #labels == 0 then return s._placeholder, false end
		return table.concat(labels, ", "), true
	else
		if s._selectedValue == nil then return s._placeholder, false end
		for _, opt in ipairs(s._options) do
			if opt.Value == s._selectedValue then
				local display = if s._formatDisplay
					then s._formatDisplay(opt.Value)
					else opt.Label
				return display, true
			end
		end
		return s._placeholder, false
	end
end

-- ── Constructor ───────────────────────────────────────────────────────────────

function Dropdown.new(props: DropdownProps, theme: { [string]: any }, parent: Instance): Dropdown
	local name = props.name or props.Label or props.Text
	local flagKey: string? = props.flag or props.Flag
	local isMulti = (props.multiSelect == true) or (props.MultiSelect == true)
	local isSearchable = (props.searchable == true) or (props.Searchable == true)
	local isEnabled = if props.enabled ~= nil then props.enabled
		elseif props.Enabled ~= nil then props.Enabled
		else true
	local callback = props.callback or props.Callback
	local placeholder = props.placeholder or props.Placeholder or (if isMulti then "None selected" else "Select...")
	local formatDisplay = props.formatDisplayValue or props.FormatDisplayValue
	local maxVisible = props.maxVisibleDropdownItems or props.MaxVisibleDropdownItems
	local maxH = if maxVisible and maxVisible > 0 then (maxVisible * OPTION_H) else MAX_H_DEFAULT
	local special = props.specialType or props.SpecialType

	-- Disabled values set
	local rawDisabled = props.disabledValues or props.DisabledValues or {}
	local disabledSet: { [any]: boolean } = {}
	for _, v in ipairs(rawDisabled) do
		disabledSet[v] = true
	end

	-- Options resolution
	local initialOptions = props.options or props.Options or {}
	local specialConns: { RBXScriptConnection } = {}

	if special == "Player" then
		local function getPlayers(): { string }
			local pList = {}
			for _, p in ipairs(Players:GetPlayers()) do
				table.insert(pList, p.Name)
			end
			return pList
		end
		initialOptions = getPlayers()
	elseif special == "Team" then
		local function getTeams(): { string }
			local tList = {}
			for _, t in ipairs(Teams:GetTeams()) do
				table.insert(tList, t.Name)
			end
			return tList
		end
		initialOptions = getTeams()
	end

	local normOpts = normalizeOptions(initialOptions)

	-- Initial selection resolution
	local defaults = normalizeDefault(props.value or props.default or props.Default)
	if flagKey and flags:Get(flagKey) ~= nil then
		local stored = flags:Get(flagKey)
		defaults = normalizeDefault(stored)
	end

	local selectedSet: { [any]: boolean } = {}
	local selectedVal: any = nil
	if isMulti then
		for _, v in ipairs(defaults) do
			selectedSet[v] = true
		end
	else
		selectedVal = if #defaults > 0 then defaults[1] else nil
	end

	local hasLabel = name ~= nil and #name > 0
	local LABEL_W = 90
	local leftPad = if hasLabel then (LABEL_W + 12) else 12

	-- ── Outer Container Frame ─────────────────────────────────────────────────
	local frame = Instance.new("Frame")
	frame.Name = "Dropdown_" .. (name or "Element")
	frame.Size = UDim2.new(1, 0, 0, HEADER_H)
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel = 0
	frame.LayoutOrder = props.layoutOrder or props.LayoutOrder or 0
	frame.ClipsDescendants = false
	frame.Parent = parent



	-- ── Inner Shell ───────────────────────────────────────────────────────────
	local inner = Instance.new("Frame")
	inner.Name = "Inner"
	inner.AnchorPoint = Vector2.new(0.5, 0)
	inner.Position = UDim2.new(0.5, 0, 0, 0)
	inner.Size = UDim2.new(1, 0, 0, HEADER_H)
	inner.BackgroundColor3 = Color3.new(1, 1, 1)
	inner.BorderSizePixel = 0
	inner.ZIndex = 2
	inner.Parent = frame

	local innerGrad = Instance.new("UIGradient")
	innerGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromHex("#2e2e2e")),
		ColorSequenceKeypoint.new(1, Color3.fromHex("#181818")),
	})
	innerGrad.Rotation = 90
	innerGrad.Parent = inner

	local innerCorner = Instance.new("UICorner")
	innerCorner.CornerRadius = UDim.new(0, 6)
	innerCorner.Parent = inner

	local stroke = Instance.new("UIStroke")
	stroke.Color = theme.ElementStroke or Color3.fromHex("#2b2b2b")
	stroke.Thickness = 1
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = inner

	local innerPad = Instance.new("UIPadding")
	innerPad.PaddingLeft = UDim.new(0, leftPad)
	innerPad.PaddingRight = UDim.new(0, 12)
	innerPad.Parent = inner

	local flash = Instance.new("Frame")
	flash.Name = "Flash"
	flash.Size = UDim2.new(1, leftPad + 12, 1, 0)
	flash.Position = UDim2.new(0, -leftPad, 0, 0)
	flash.BackgroundColor3 = Color3.new(1, 1, 1)
	flash.BackgroundTransparency = 1
	flash.BorderSizePixel = 0
	flash.ZIndex = 3

	local flashCorner = Instance.new("UICorner")
	flashCorner.CornerRadius = UDim.new(0, 6)
	flashCorner.Parent = flash
	flash.Parent = inner

	local ARROW_W = 16
	local MULTI_W = 14
	local arrow = Instance.new("ImageLabel")
	arrow.Name = "Arrow"
	arrow.AnchorPoint = Vector2.new(1, 0.5)
	arrow.Position = UDim2.new(1, 0, 0.5, 0)
	arrow.Size = UDim2.fromOffset(ARROW_W, ARROW_W)
	arrow.BackgroundTransparency = 1
	arrow.Image = icons.Resolve("lucide:chevron-down") or "rbxassetid://88479147175134"
	arrow.ImageColor3 = theme.PlaceholderColor or Color3.fromHex("#9d9d9d")
	arrow.Rotation = 0
	arrow.ZIndex = 4
	arrow.Parent = inner

	local multiIcon: ImageLabel? = nil
	if isMulti then
		local mico = Instance.new("ImageLabel")
		mico.Name = "MultiIcon"
		mico.AnchorPoint = Vector2.new(1, 0.5)
		mico.Position = UDim2.new(1, -(ARROW_W + 6), 0.5, 0)
		mico.Size = UDim2.fromOffset(MULTI_W, MULTI_W)
		mico.BackgroundTransparency = 1
		mico.Image = icons.Resolve("lucide:layers") or icons.Resolve("lucide:list-checks") or "rbxassetid://83827110621355"
		mico.ImageColor3 = theme.PlaceholderColor or Color3.fromHex("#9d9d9d")
		mico.ImageTransparency = 0.3
		mico.ZIndex = 4
		mico.Parent = inner
		multiIcon = mico
	end

	local rightReserve = ARROW_W + (if isMulti then (MULTI_W + 10) else 8)
	local valueLabel = Instance.new("TextLabel")
	valueLabel.Name = "ValueLabel"
	valueLabel.Size = UDim2.new(1, -rightReserve, 1, 0)
	valueLabel.BackgroundTransparency = 1
	valueLabel.Font = Enum.Font.GothamMedium
	valueLabel.FontFace = theme.Font or Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium)
	valueLabel.TextSize = 12
	valueLabel.TextXAlignment = Enum.TextXAlignment.Right
	valueLabel.TextTruncate = Enum.TextTruncate.AtEnd
	valueLabel.ZIndex = 4
	valueLabel.Parent = inner

	local outerLabel: TextLabel? = nil
	if hasLabel then
		local lbl = Instance.new("TextLabel")
		lbl.Name = "Label"
		lbl.Position = UDim2.fromOffset(12, 0)
		lbl.Size = UDim2.fromOffset(LABEL_W, HEADER_H)
		lbl.BackgroundTransparency = 1
		lbl.Font = Enum.Font.GothamMedium
		lbl.FontFace = theme.Font or Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium)
		lbl.Text = name :: string
		lbl.TextSize = 13
		lbl.TextColor3 = if isEnabled then (theme.ContentColor or Color3.fromHex("#ffffff")) else Color3.fromHex("#555555")
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.TextTruncate = Enum.TextTruncate.AtEnd
		lbl.ZIndex = 4
		lbl.Parent = frame
		outerLabel = lbl
	end

	local hit = Instance.new("TextButton")
	hit.Name = "Hit"
	hit.Size = UDim2.fromScale(1, 1)
	hit.BackgroundTransparency = 1
	hit.Text = ""
	hit.AutoButtonColor = false
	hit.ZIndex = 5
	hit.Parent = inner

	-- ── List Container ─────────────────────────────────────────────────────────
	local listWrap = Instance.new("Frame")
	listWrap.Name = "ListWrap"
	listWrap.Position = UDim2.new(0, 0, 0, HEADER_H + LIST_GAP)
	listWrap.Size = UDim2.new(1, 0, 0, 0)
	listWrap.BackgroundColor3 = Color3.fromHex("#1a1a1a")
	listWrap.BackgroundTransparency = 1
	listWrap.BorderSizePixel = 0
	listWrap.ClipsDescendants = true
	listWrap.Visible = false
	listWrap.ZIndex = 2

	local listCorner = Instance.new("UICorner")
	listCorner.CornerRadius = UDim.new(0, 6)
	listCorner.Parent = listWrap

	local listStroke = Instance.new("UIStroke")
	listStroke.Color = theme.ElementStroke or Color3.fromHex("#2b2b2b")
	listStroke.Thickness = 1
	listStroke.Transparency = 1
	listStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	listStroke.Parent = listWrap
	listWrap.Parent = frame

	-- ── Search Bar (Optional) ─────────────────────────────────────────────────
	local searchBox: TextBox? = nil
	if isSearchable then
		local searchBar = Instance.new("Frame")
		searchBar.Name = "SearchBar"
		searchBar.Size = UDim2.new(1, 0, 0, SEARCH_H)
		searchBar.BackgroundColor3 = Color3.fromHex("#1e1e1e")
		searchBar.BackgroundTransparency = 0
		searchBar.BorderSizePixel = 0
		searchBar.ZIndex = 4
		searchBar.Parent = listWrap

		local searchPad = Instance.new("UIPadding")
		searchPad.PaddingLeft = UDim.new(0, 12)
		searchPad.PaddingRight = UDim.new(0, 12)
		searchPad.PaddingTop = UDim.new(0, 5)
		searchPad.PaddingBottom = UDim.new(0, 5)
		searchPad.Parent = searchBar

		local searchInner = Instance.new("Frame")
		searchInner.Name = "SearchInner"
		searchInner.Size = UDim2.fromScale(1, 1)
		searchInner.BackgroundColor3 = Color3.fromHex("#2a2a2a")
		searchInner.BorderSizePixel = 0
		searchInner.ZIndex = 4
		searchInner.Parent = searchBar

		local searchCorner = Instance.new("UICorner")
		searchCorner.CornerRadius = UDim.new(0, 6)
		searchCorner.Parent = searchInner

		local searchStroke = Instance.new("UIStroke")
		searchStroke.Color = theme.ElementStroke or Color3.fromHex("#2b2b2b")
		searchStroke.Thickness = 1
		searchStroke.Transparency = 0.4
		searchStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		searchStroke.Parent = searchInner

		local searchIcon = Instance.new("TextLabel")
		searchIcon.Name = "SearchIcon"
		searchIcon.Size = UDim2.fromOffset(16, 16)
		searchIcon.AnchorPoint = Vector2.new(0, 0.5)
		searchIcon.Position = UDim2.new(0, 6, 0.5, 0)
		searchIcon.BackgroundTransparency = 1
		searchIcon.Font = Enum.Font.GothamMedium
		searchIcon.Text = "⌕"
		searchIcon.TextSize = 13
		searchIcon.TextColor3 = theme.PlaceholderColor or Color3.fromHex("#9d9d9d")
		searchIcon.ZIndex = 5
		searchIcon.Parent = searchInner

		local sb = Instance.new("TextBox")
		sb.Name = "SearchBox"
		sb.Size = UDim2.new(1, -26, 1, 0)
		sb.Position = UDim2.fromOffset(24, 0)
		sb.BackgroundTransparency = 1
		sb.BorderSizePixel = 0
		sb.Font = Enum.Font.GothamMedium
		sb.PlaceholderText = "Search..."
		sb.PlaceholderColor3 = Color3.fromHex("#555555")
		sb.Text = ""
		sb.TextSize = 12
		sb.TextColor3 = theme.ContentColor or Color3.fromHex("#ffffff")
		sb.TextXAlignment = Enum.TextXAlignment.Left
		sb.ClearTextOnFocus = false
		sb.ZIndex = 5
		sb.Parent = searchInner
		searchBox = sb

		local sep = Instance.new("Frame")
		sep.Name = "SearchSep"
		sep.Size = UDim2.new(1, 0, 0, 1)
		sep.Position = UDim2.new(0, 0, 0, SEARCH_H)
		sep.BackgroundColor3 = theme.ElementStroke or Color3.fromHex("#2b2b2b")
		sep.BackgroundTransparency = 0.5
		sep.BorderSizePixel = 0
		sep.ZIndex = 4
		sep.Parent = listWrap
	end

	-- ── Scrolling Options Area ────────────────────────────────────────────────
	local scrollTopOffset = if isSearchable then SEARCH_H else 0

	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "OptionScroll"
	scroll.Position = UDim2.fromOffset(0, scrollTopOffset)
	scroll.Size = UDim2.new(1, 0, 1, -scrollTopOffset)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 3
	scroll.ScrollBarImageColor3 = theme.ElementStroke or Color3.fromHex("#2b2b2b")
	scroll.CanvasSize = UDim2.fromOffset(0, 0)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.None
	scroll.ClipsDescendants = true
	scroll.ZIndex = 3
	scroll.Parent = listWrap

	local listLayout = Instance.new("UIListLayout")
	listLayout.FillDirection = Enum.FillDirection.Vertical
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Padding = UDim.new(0, 0)
	listLayout.Parent = scroll

	local self = setmetatable({}, Dropdown) :: Dropdown
	self._frame = frame
	self.Changed = signal.new()

	local initVal: any = if isMulti then {} else nil
	if isMulti then
		local arr = {}
		for _, o in ipairs(normOpts) do
			if selectedSet[o.Value] then table.insert(arr, o.Value) end
		end
		initVal = arr
	else
		initVal = selectedVal
	end
	self.value = initVal
	self.Value = initVal

	-- ── Private Storage ───────────────────────────────────────────────────────
	local s = self :: any
	s._enabled = isEnabled
	s._open = false
	s._multiSelect = isMulti
	s._searchEnabled = isSearchable
	s._searchQuery = ""
	s._formatDisplay = formatDisplay
	s._maxH = maxH
	s._targetH = 0
	s._placeholder = placeholder
	s._options = normOpts
	s._selectedSet = selectedSet
	s._selectedValue = selectedVal
	s._disabledSet = disabledSet
	s._flag = flagKey
	s._callback = callback
	s._theme = theme

	s._frame = frame
	s._inner = inner
	s._listWrap = listWrap
	s._listStroke = listStroke
	s._scroll = scroll
	s._arrow = arrow
	s._valueLabel = valueLabel
	s._outerLabel = outerLabel
	s._stroke = stroke
	s._flash = flash
	s._searchBox = searchBox
	s._conns = {} :: { [string]: RBXScriptConnection }
	s._optConns = {} :: { RBXScriptConnection }
	s._specialConns = specialConns

	-- ── Open / Close (Instant — Zero Animations) ──────────────────────────────
	local function getListH(): number
		return s._targetH + (if s._searchEnabled then SEARCH_H else 0)
	end

	local function closeDropdown()
		if not s._open then return end
		s._open = false
		s._flipUp = false
		if s._searchEnabled and s._searchBox then
			s._searchBox.Text = ""
			s._searchQuery = ""
		end

		-- Instant close: zero animations
		arrow.Rotation = 0
		stroke.Color = s._theme.ElementStroke or Color3.fromHex("#2b2b2b")
		listWrap.Visible = false
		listWrap.Size = UDim2.new(1, 0, 0, 0)
		listWrap.Position = UDim2.new(0, 0, 0, HEADER_H + LIST_GAP)
		listWrap.BackgroundTransparency = 1
		listStroke.Transparency = 1
		frame.Size = UDim2.new(1, 0, 0, HEADER_H)
		-- Restore ZIndex that was raised on open.
		frame.ZIndex = s._originalZIndex or 1
		s._originalZIndex = nil
	end

	local function openDropdown()
		if s._open or not s._enabled then return end
		s._open = true
		local fullH = getListH()

		-- Flip detection: walk up to the nearest ClipsDescendants ancestor to get the
		-- real visible boundary. frame.Parent may be an AutomaticSize frame that grows
		-- with content — using it as boundary causes a false positive that always flips
		-- the list upward inside settings panels and nested layouts.
		local flipUp = false
		do
			local clipAncestor: GuiObject? = nil
			do
				local p: Instance? = frame.Parent
				while p ~= nil and not p:IsA("ScreenGui") do
					if p:IsA("GuiObject") and (p :: GuiObject).ClipsDescendants then
						clipAncestor = p :: GuiObject
						break
					end
					p = p.Parent
				end
			end

			local boundaryTop: number
			local boundaryBottom: number
			if clipAncestor then
				boundaryTop    = clipAncestor.AbsolutePosition.Y
				boundaryBottom = clipAncestor.AbsolutePosition.Y + clipAncestor.AbsoluteSize.Y
			else
				-- No clipping ancestor — fall back to frame.Parent.
				local pf = frame.Parent
				if pf and pf:IsA("GuiObject") then
					local g = pf :: GuiObject
					boundaryTop    = g.AbsolutePosition.Y
					boundaryBottom = g.AbsolutePosition.Y + g.AbsoluteSize.Y
				else
					boundaryTop    = 0
					boundaryBottom = math.huge
				end
			end

			local frameBottom = frame.AbsolutePosition.Y + HEADER_H + LIST_GAP + fullH
			local spaceAbove  = frame.AbsolutePosition.Y - boundaryTop
			if frameBottom > boundaryBottom and spaceAbove >= fullH + LIST_GAP then
				flipUp = true
			end
		end

		-- Raise ZIndex so the open list renders above sibling rows (e.g. inside
		-- the settings panel where rows have ZIndex 2000). Stored and restored on close.
		if not s._originalZIndex then
			s._originalZIndex = frame.ZIndex
		end
		frame.ZIndex = 32766

		s._flipUp = flipUp
		if flipUp then
			-- List opens above the header row. Don't expand frame downward.
			listWrap.Position = UDim2.new(0, 0, 0, -(fullH + LIST_GAP))
		else
			listWrap.Position = UDim2.new(0, 0, 0, HEADER_H + LIST_GAP)
		end

		-- Instant open: zero animations
		arrow.Rotation = 180
		stroke.Color = s._theme.AccentColor or Color3.fromHex("#4cc2ff")
		listWrap.Visible = true
		listWrap.Size = UDim2.new(1, 0, 0, fullH)
		listWrap.BackgroundTransparency = 0
		listStroke.Transparency = 0
		-- Only expand frame downward when list is below the header.
		-- With flipUp the list sits above; growing downward just pushes layout siblings.
		if flipUp then
			frame.Size = UDim2.new(1, 0, 0, HEADER_H)
		else
			frame.Size = UDim2.new(1, 0, 0, HEADER_H + LIST_GAP + fullH)
		end

		if s._searchEnabled and s._searchBox then
			task.defer(function()
				if s._open and s._searchBox then
					local isTouchOnly = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
					if not isTouchOnly then
						s._searchBox:CaptureFocus()
					end
				end
			end)
		end
	end

	s._openDropdown = openDropdown
	s._closeDropdown = closeDropdown

	-- ── Build Option Rows ─────────────────────────────────────────────────────
	local function buildOptions()
		for _, c in ipairs(s._optConns) do c:Disconnect() end
		table.clear(s._optConns)
		for _, child in ipairs(scroll:GetChildren()) do
			if child:IsA("Frame") then child:Destroy() end
		end

		local query = s._searchQuery or ""
		local filtered: { DropdownOption } = {}
		for _, opt in ipairs(s._options) do
			if query == "" or string.find(opt.Label:lower(), query, 1, true) then
				table.insert(filtered, opt)
			end
		end

		local optCount = #filtered
		local fullH = optCount * OPTION_H
		scroll.CanvasSize = UDim2.fromOffset(0, fullH)
		s._targetH = math.min(fullH, s._maxH)

		if s._open then
			local panelH = getListH()
			listWrap.Size = UDim2.new(1, 0, 0, panelH)
			frame.Size = UDim2.new(1, 0, 0, HEADER_H + LIST_GAP + panelH)
		end

		for i, opt in ipairs(filtered) do
			local isSelected = if s._multiSelect
				then s._selectedSet[opt.Value] == true
				else s._selectedValue == opt.Value
			local isDisabled = s._disabledSet[opt.Value] == true

			local optFrame = Instance.new("Frame")
			optFrame.Name = "Option_" .. i
			optFrame.Size = UDim2.new(1, 0, 0, OPTION_H)
			optFrame.BackgroundColor3 = Color3.fromHex("#1a1a1a")
			optFrame.BackgroundTransparency = 1
			optFrame.BorderSizePixel = 0
			optFrame.LayoutOrder = i
			optFrame.ZIndex = 3

			local checkLabel: any = nil
			if s._multiSelect then
				local ck = Instance.new("ImageLabel")
				ck.Name = "Check"
				ck.Size = UDim2.fromOffset(14, 14)
				ck.AnchorPoint = Vector2.new(0.5, 0.5)
				ck.Position = UDim2.new(0, 4 + CHECK_W / 2, 0.5, 0)
				ck.BackgroundTransparency = 1
				ck.Image = if isSelected
					then (icons.Resolve("lucide:square-check") or "rbxassetid://0")
					else (icons.Resolve("lucide:square") or "rbxassetid://0")
				ck.ImageColor3 = if isDisabled
					then Color3.fromHex("#555555")
					else if isSelected
						then (s._theme.AccentColor or Color3.fromHex("#4cc2ff"))
						else Color3.fromHex("#555555")
				ck.ZIndex = 4
				ck.Parent = optFrame
				checkLabel = ck
			end

			local labelXOffset = if s._multiSelect then (CHECK_W + 4) else 12
			local labelWOffset = if s._multiSelect then -(CHECK_W + 16) else -24

			local displayText = if s._formatDisplay
				then s._formatDisplay(opt.Value)
				else opt.Label

			local textColor = if isDisabled
				then Color3.fromHex("#555555")
				elseif isSelected then (s._theme.AccentColor or Color3.fromHex("#4cc2ff"))
				else (s._theme.PlaceholderColor or Color3.fromHex("#9d9d9d"))

			local optLabel = Instance.new("TextLabel")
			optLabel.Name = "OptionLabel"
			optLabel.Size = UDim2.new(1, labelWOffset, 1, 0)
			optLabel.Position = UDim2.fromOffset(labelXOffset, 0)
			optLabel.BackgroundTransparency = 1
			optLabel.Font = Enum.Font.GothamMedium
			optLabel.FontFace = s._theme.Font or Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium)
			optLabel.Text = displayText
			optLabel.TextSize = 12
			optLabel.TextColor3 = textColor
			optLabel.TextXAlignment = if s._multiSelect then Enum.TextXAlignment.Left else Enum.TextXAlignment.Center
			optLabel.TextTruncate = Enum.TextTruncate.AtEnd
			optLabel.ZIndex = 4
			optLabel.Parent = optFrame

			if isDisabled then
				local disabledTag = Instance.new("TextLabel")
				disabledTag.Name = "DisabledTag"
				disabledTag.AnchorPoint = Vector2.new(1, 0.5)
				disabledTag.Position = UDim2.new(1, -8, 0.5, 0)
				disabledTag.Size = UDim2.fromOffset(36, 14)
				disabledTag.BackgroundColor3 = Color3.fromHex("#2a2a2a")
				disabledTag.BorderSizePixel = 0
				disabledTag.Font = Enum.Font.GothamMedium
				disabledTag.Text = "off"
				disabledTag.TextSize = 9
				disabledTag.TextColor3 = Color3.fromHex("#555555")
				disabledTag.TextXAlignment = Enum.TextXAlignment.Center
				disabledTag.ZIndex = 4

				local dtCorner = Instance.new("UICorner")
				dtCorner.CornerRadius = UDim.new(1, 0)
				dtCorner.Parent = disabledTag
				disabledTag.Parent = optFrame
			end

			if i < optCount then
				local sep = Instance.new("Frame")
				sep.Size = UDim2.new(1, -24, 0, 1)
				sep.Position = UDim2.new(0, 12, 1, -1)
				sep.BackgroundColor3 = s._theme.ElementStroke or Color3.fromHex("#2b2b2b")
				sep.BackgroundTransparency = 0.7
				sep.BorderSizePixel = 0
				sep.ZIndex = 4
				sep.Parent = optFrame
			end

			local optHit = Instance.new("TextButton")
			optHit.Name = "Hit"
			optHit.Size = UDim2.fromScale(1, 1)
			optHit.BackgroundTransparency = 1
			optHit.Text = ""
			optHit.AutoButtonColor = false
			optHit.ZIndex = 5
			optHit.Parent = optFrame

			if not isDisabled then
				table.insert(s._optConns, optHit.MouseEnter:Connect(function()
					optFrame.BackgroundTransparency = 0.85
					optFrame.BackgroundColor3 = Color3.fromHex("#252525")
					local isSel = if s._multiSelect
						then s._selectedSet[opt.Value] == true
						else s._selectedValue == opt.Value
					if not isSel then
						optLabel.TextColor3 = s._theme.ContentColor or Color3.fromHex("#ffffff")
					end
				end))

				table.insert(s._optConns, optHit.MouseLeave:Connect(function()
					optFrame.BackgroundTransparency = 1
					optFrame.BackgroundColor3 = Color3.fromHex("#1a1a1a")
					local isSel = if s._multiSelect
						then s._selectedSet[opt.Value] == true
						else s._selectedValue == opt.Value
					if not isSel then
						optLabel.TextColor3 = s._theme.PlaceholderColor or Color3.fromHex("#9d9d9d")
					end
				end))

				table.insert(s._optConns, optHit.MouseButton1Click:Connect(function()
					if not s._enabled then return end

					if s._multiSelect then
						if s._selectedSet[opt.Value] then
						s._selectedSet[opt.Value] = nil
						optLabel.TextColor3 = s._theme.PlaceholderColor or Color3.fromHex("#9d9d9d")
						if checkLabel then
						  (checkLabel :: ImageLabel).Image = icons.Resolve("lucide:square") or "rbxassetid://0"
						 (checkLabel :: ImageLabel).ImageColor3 = Color3.fromHex("#555555")
						end
						else
						 s._selectedSet[opt.Value] = true
						optLabel.TextColor3 = s._theme.AccentColor or Color3.fromHex("#4cc2ff")
						if checkLabel then
							(checkLabel :: ImageLabel).Image = icons.Resolve("lucide:square-check") or "rbxassetid://0"
							(checkLabel :: ImageLabel).ImageColor3 = s._theme.AccentColor or Color3.fromHex("#4cc2ff")
						end
					end
						local arr: { any } = {}
						for _, o in ipairs(s._options) do
							if s._selectedSet[o.Value] then
								table.insert(arr, o.Value)
							end
						end
						self.value = arr
						self.Value = arr

						local txt, has = getHeaderText(s)
						valueLabel.Text = txt
						valueLabel.TextColor3 = if has
							then (s._theme.ContentColor or Color3.fromHex("#ffffff"))
							else Color3.fromHex("#555555")

						if flagKey then flags:Set(flagKey, arr) end
						self.Changed:Fire(arr)
						if callback then task.spawn(callback, arr) end
					else
						for _, ch in ipairs(scroll:GetChildren()) do
							if ch:IsA("Frame") then
								local lbl = ch:FindFirstChild("OptionLabel")
								if lbl and lbl:IsA("TextLabel") then
									lbl.TextColor3 = s._theme.PlaceholderColor or Color3.fromHex("#9d9d9d")
								end
							end
						end
						optLabel.TextColor3 = s._theme.AccentColor or Color3.fromHex("#4cc2ff")
						s._selectedValue = opt.Value
						self.value = opt.Value
						self.Value = opt.Value

						local txt, has = getHeaderText(s)
						valueLabel.Text = txt
						valueLabel.TextColor3 = if has
							then (s._theme.ContentColor or Color3.fromHex("#ffffff"))
							else Color3.fromHex("#555555")

						if flagKey then flags:Set(flagKey, opt.Value) end
						self.Changed:Fire(opt.Value)
						if callback then task.spawn(callback, opt.Value) end

						closeDropdown()
					end
				end))
			end

			optFrame.Parent = scroll
		end
	end

	s._buildOptions = buildOptions
	buildOptions()

	local initTxt, initHas = getHeaderText(s)
	valueLabel.Text = initTxt
	valueLabel.TextColor3 = if initHas
		then (theme.ContentColor or Color3.fromHex("#ffffff"))
		else Color3.fromHex("#555555")

	if searchBox then
		s._conns.search = searchBox:GetPropertyChangedSignal("Text"):Connect(function()
			s._searchQuery = searchBox.Text:lower()
			buildOptions()
		end)
	end

	-- ── Interactivity (Instant — Zero Animations) ─────────────────────────────
	local hovering = false

	s._conns.hitEnter = hit.MouseEnter:Connect(function()
		if not s._enabled then return end
		hovering = true
		stroke.Color = s._theme.AccentColor or Color3.fromHex("#4cc2ff")
		flash.BackgroundTransparency = 0.92
	end)

	s._conns.hitLeave = hit.MouseLeave:Connect(function()
		if not s._enabled then return end
		hovering = false
		if not s._open then
			stroke.Color = s._theme.ElementStroke or Color3.fromHex("#2b2b2b")
		end
		flash.BackgroundTransparency = 1
	end)

	s._conns.hitClick = hit.MouseButton1Click:Connect(function()
		if not s._enabled then return end
		if s._open then
			closeDropdown()
		else
			openDropdown()
		end
	end)

	-- Close when clicking outside dropdown
	s._conns.outsideClick = UserInputService.InputBegan:Connect(function(input: InputObject)
		if not s._open then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			local mousePos = input.Position
			local ap = frame.AbsolutePosition
			local as = frame.AbsoluteSize
			local inX = mousePos.X >= ap.X and mousePos.X <= (ap.X + as.X)
			local inY: boolean
			if s._flipUp then
				-- List renders above the header frame — bounds check must include that region.
				-- frame.Size stays HEADER_H when flipped, so as.Y only covers the header;
				-- clicks on list items appear above ap.Y and get wrongly treated as outside.
				local listH = getListH()
				local topY = ap.Y - listH - LIST_GAP
				inY = mousePos.Y >= topY and mousePos.Y <= (ap.Y + HEADER_H)
			else
				inY = mousePos.Y >= ap.Y and mousePos.Y <= (ap.Y + as.Y)
			end
			if not (inX and inY) then
				closeDropdown()
			end
		end
	end)

	-- Special types wiring
	if special == "Player" then
		table.insert(specialConns, Players.PlayerAdded:Connect(function()
			local pList = {}
			for _, p in ipairs(Players:GetPlayers()) do table.insert(pList, p.Name) end
			self:SetOptions(pList)
		end))
		table.insert(specialConns, Players.PlayerRemoving:Connect(function()
			local pList = {}
			for _, p in ipairs(Players:GetPlayers()) do table.insert(pList, p.Name) end
			self:SetOptions(pList)
		end))
	elseif special == "Team" then
		table.insert(specialConns, Teams.ChildAdded:Connect(function()
			local tList = {}
			for _, t in ipairs(Teams:GetTeams()) do table.insert(tList, t.Name) end
			self:SetOptions(tList)
		end))
		table.insert(specialConns, Teams.ChildRemoved:Connect(function()
			local tList = {}
			for _, t in ipairs(Teams:GetTeams()) do table.insert(tList, t.Name) end
			self:SetOptions(tList)
		end))
	end

	s._themeUnsub = themeUtil.subscribe(function(t)
		s._theme = t
		stroke.Color = if s._open or hovering
			then (t.AccentColor or Color3.fromHex("#4cc2ff"))
			else (t.ElementStroke or Color3.fromHex("#2b2b2b"))
		if outerLabel then
			outerLabel.TextColor3 = if s._enabled
				then (t.ContentColor or Color3.fromHex("#ffffff"))
				else Color3.fromHex("#555555")
			-- B3 FIX: use cached constant instead of allocating a new Font
			outerLabel.FontFace = t.Font or DEFAULT_FONT
		end
		-- B3 FIX: cached constant
		valueLabel.FontFace = t.Font or DEFAULT_FONT
		arrow.ImageColor3 = t.PlaceholderColor or Color3.fromHex("#9d9d9d")
		if multiIcon then
			multiIcon.ImageColor3 = t.PlaceholderColor or Color3.fromHex("#9d9d9d")
		end
		listStroke.Color = t.ElementStroke or Color3.fromHex("#2b2b2b")
		innerGrad.Color = t.ElementGradient or ColorSequence.new(Color3.fromRGB(28, 24, 44))
		-- B1 FIX: only rebuild option rows when the list is open.
		-- When closed, options are invisible; re-coloring happens on next open().
		-- This prevents dozens of instance destroy/recreate cycles per mouse-move
		-- during accent-color drag (which triggers a broadcast per frame).
		if s._open then
			buildOptions()
		end
	end)

	if flagKey and flagKey ~= "" then
		flags:Set(flagKey, initVal)
	end

	return self
end

-- ── Methods ───────────────────────────────────────────────────────────────────

function Dropdown:SetOptions(options: { any })
	local s = self :: any
	if s._open then
		s._closeDropdown()
	end

	s._options = normalizeOptions(options)

	if s._multiSelect then
		local newSet: { [any]: boolean } = {}
		for _, opt in ipairs(s._options) do
			if s._selectedSet[opt.Value] then
				newSet[opt.Value] = true
			end
		end
		s._selectedSet = newSet
		local arr: { any } = {}
		for _, opt in ipairs(s._options) do
			if s._selectedSet[opt.Value] then table.insert(arr, opt.Value) end
		end
		self.value = arr
		self.Value = arr
	else
		local found = false
		for _, opt in ipairs(s._options) do
			if opt.Value == s._selectedValue then found = true break end
		end
		if not found then
			s._selectedValue = nil
			self.value = nil
			self.Value = nil
		end
	end

	local txt, has = getHeaderText(s)
	s._valueLabel.Text = txt
	s._valueLabel.TextColor3 = if has
		then (s._theme.ContentColor or Color3.fromHex("#ffffff"))
		else Color3.fromHex("#555555")

	s._buildOptions()
end

function Dropdown:Set(value: any, skipCallback: boolean?)
	local s = self :: any

	if s._multiSelect then
		s._selectedSet = {}
		local outArr: { any } = {}
		if typeof(value) == "table" then
			for k, v in pairs(value) do
				if typeof(k) == "number" then
					-- Array element: v is the option value
					s._selectedSet[v] = true
					table.insert(outArr, v)
				elseif v == true then
					-- Dictionary element: k is the option value
					s._selectedSet[k] = true
					table.insert(outArr, k)
				end
			end
		elseif value ~= nil then
			s._selectedSet[value] = true
			table.insert(outArr, value)
		end
		self.value = outArr
		self.Value = outArr
	else
		local matchVal: any = nil
		for _, opt in ipairs(s._options) do
			if opt.Value == value or opt.Label == value or tostring(opt.Value) == tostring(value) then
				matchVal = opt.Value
				break
			end
		end
		s._selectedValue = if matchVal ~= nil then matchVal else value
		self.value = s._selectedValue
		self.Value = s._selectedValue
	end

	local txt, has = getHeaderText(s)
	s._valueLabel.Text = txt
	s._valueLabel.TextColor3 = if has
		then (s._theme.ContentColor or Color3.fromHex("#ffffff"))
		else Color3.fromHex("#555555")

	s._buildOptions()

	if s._flag then
		flags:Set(s._flag, self.value)
	end
	self.Changed:Fire(self.value)
	if not skipCallback and s._callback then
		task.spawn(s._callback, self.value)
	end
end

function Dropdown:SetValue(value: any, skipCallback: boolean?)
	self:Set(value, skipCallback)
end

function Dropdown:SetEnabled(enabled: boolean)
	local s = self :: any
	s._enabled = enabled
	s._stroke.Transparency = if enabled then 0 else 0.5
	if s._outerLabel then
		s._outerLabel.TextColor3 = if enabled
			then (s._theme.ContentColor or Color3.fromHex("#ffffff"))
			else Color3.fromHex("#555555")
	end
	if not enabled and s._open then
		s._closeDropdown()
	end
end

function Dropdown:GetFrame(): Frame
	return self._frame
end

function Dropdown:Destroy()
	local s = self :: any
	if s._themeUnsub then s._themeUnsub() end
	if s._conns then
		for _, conn in s._conns do conn:Disconnect() end
		table.clear(s._conns)
	end
	if s._optConns then
		for _, conn in s._optConns do conn:Disconnect() end
		table.clear(s._optConns)
	end
	if s._specialConns then
		for _, conn in s._specialConns do conn:Disconnect() end
		table.clear(s._specialConns)
	end
	self.Changed:Destroy()
	self._frame:Destroy()
end

return Dropdown
