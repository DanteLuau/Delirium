--!strict

local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Maid         = require(script.Parent.Parent.Utils.Maid)
local Signal       = require(script.Parent.Parent.Utils.Signal)
local Theme        = require(script.Parent.Parent.Theme)
local SmoothScroll = require(script.Parent.Parent.Utils.SmoothScroll)

local TWEEN_STROKE   = TweenInfo.new(0.25, Enum.EasingStyle.Quint,       Enum.EasingDirection.Out)
local TWEEN_HOVER    = TweenInfo.new(0.2,  Enum.EasingStyle.Quint,       Enum.EasingDirection.Out)
local TWEEN_EXPAND   = TweenInfo.new(0.5,  Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
local TWEEN_COLLAPSE = TweenInfo.new(0.45, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
local TWEEN_ARROW    = TweenInfo.new(0.65, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
local TWEEN_FADE     = TweenInfo.new(0.35, Enum.EasingStyle.Quint,       Enum.EasingDirection.Out)

local SD_REST  = { BackgroundTransparency = 0.75, Position = UDim2.new(0.5, 0, 0, 3) }
local SD_HOVER = { BackgroundTransparency = 0.65, Position = UDim2.new(0.5, 0, 0, 5) }

local HEADER_H = 36
local LIST_GAP = 4
local OPTION_H = 32
local MAX_H    = 160
local CHECK_W  = 20  -- width reserved for checkmark column in multiSelect

-- ── Option normalisation ──────────────────────────────────────────────────────
-- Accepts either plain strings or { Label, Value } tables.

export type DropdownOption = { Label: string, Value: any }

local function normalizeOptions(raw: { any }): { DropdownOption }
	local out: { DropdownOption } = {}
	for _, v in ipairs(raw) do
		if typeof(v) == "string" then
			table.insert(out, { Label = v, Value = v })
		else
			-- assume already {Label, Value}
			table.insert(out, v :: DropdownOption)
		end
	end
	return out
end

-- Default can be a single value or an array; always normalise to array internally.
local function normalizeDefault(raw: any): { any }
	if raw == nil then return {} end
	if typeof(raw) == "table" then return raw end
	return { raw }
end

export type DropdownConfig = {
	-- display
	Label:       string?,
	Placeholder: string?,
	Enabled:     boolean?,
	LayoutOrder: number?,
	-- options: plain string array OR {Label,Value} table array
	Options:     { any },
	-- multi-select
	MultiSelect: boolean?,
	-- initial selection: single value OR array of values
	Default:     any?,
	-- overlay parent required for z-ordering if inside a ScrollingFrame
	OverlayParent: Instance?,
}

type DropdownImpl = {
	-- public state
	Value:   any,   -- single select: any; multi: { any }
	Changed: any,
	-- methods
	SetOptions: (self: DropdownImpl, options: { any }) -> (),
	SetValue:   (self: DropdownImpl, value: any)       -> (),
	SetEnabled: (self: DropdownImpl, enabled: boolean) -> (),
	GetFrame:   (self: DropdownImpl)                   -> Frame,
	Destroy:    (self: DropdownImpl)                   -> (),
	-- internals
	_maid:          any,
	_optionMaid:    any,
	_frame:         Frame,
	_inner:         Frame,
	_listWrap:      Frame,
	_listStroke:    UIStroke,
	_scroll:        ScrollingFrame,
	_outerLabel:    TextLabel?,
	_valueLabel:    TextLabel,
	_arrow:         TextLabel,
	_stroke:        UIStroke,
	_flash:         Frame,
	_shadow:        Frame,
	_enabled:       boolean,
	_open:          boolean,
	_multiSelect:   boolean,
	_options:       { DropdownOption },
	_selectedSet:   { [any]: boolean },  -- multi: set of selected values
	_selectedValue: any,                  -- single: current value
	_targetH:       number,
	_placeholder:   string,
}

local Dropdown = {} :: { __index: any }
Dropdown.__index = Dropdown

-- ── helpers ───────────────────────────────────────────────────────────────────

local function isInsideFrame(frame: GuiObject, pos: Vector2): boolean
	local ap = frame.AbsolutePosition
	local as = frame.AbsoluteSize
	return pos.X >= ap.X and pos.X <= ap.X + as.X
		and pos.Y >= ap.Y and pos.Y <= ap.Y + as.Y
end

-- Build the text shown in the header value label.
local function headerText(
	self: DropdownImpl
): (string, boolean)  -- text, hasSelection
	if self._multiSelect then
		local labels: { string } = {}
		for _, opt in ipairs(self._options) do
			if self._selectedSet[opt.Value] then
				table.insert(labels, opt.Label)
			end
		end
		if #labels == 0 then return self._placeholder, false end
		return table.concat(labels, ", "), true
	else
		if self._selectedValue == nil then return self._placeholder, false end
		for _, opt in ipairs(self._options) do
			if opt.Value == self._selectedValue then
				return opt.Label, true
			end
		end
		return self._placeholder, false
	end
end

-- ── constructor ───────────────────────────────────────────────────────────────

function Dropdown.new(config: DropdownConfig): DropdownImpl
	local self           = setmetatable({}, Dropdown) :: DropdownImpl
	self._maid           = Maid.new()
	self._optionMaid     = Maid.new()
	self._enabled        = if config.Enabled ~= nil then config.Enabled else true
	self._open           = false
	self._multiSelect    = if config.MultiSelect ~= nil then config.MultiSelect else false
	self._options        = normalizeOptions(config.Options or {})
	self._placeholder    = config.Placeholder or (if self._multiSelect then "None selected" else "Select...")

	-- Initialise selection state
	local defaults = normalizeDefault(config.Default)
	self._selectedSet   = {}
	self._selectedValue = nil

	if self._multiSelect then
		for _, v in ipairs(defaults) do
			self._selectedSet[v] = true
		end
		self.Value = defaults  -- expose array
	else
		self._selectedValue = if #defaults > 0 then defaults[1] else nil
		self.Value          = self._selectedValue
	end

	local hasLabel = config.Label ~= nil and #(config.Label :: string) > 0
	local LABEL_W  = 90
	local leftPad  = if hasLabel then LABEL_W + Theme.Spacing.M else Theme.Spacing.M

	-- ── outer container ───────────────────────────────────────────────────────
	local frame                  = Instance.new("Frame")
	frame.Name                   = "Dropdown"
	frame.Size                   = UDim2.new(1, 0, 0, HEADER_H)
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel        = 0
	frame.LayoutOrder            = config.LayoutOrder or 0
	frame.ClipsDescendants       = false
	self._frame                  = frame

	-- shadow
	local shadow                  = Instance.new("Frame")
	shadow.Name                   = "Shadow"
	shadow.AnchorPoint            = Vector2.new(0.5, 0)
	shadow.Position               = SD_REST.Position
	shadow.Size                   = UDim2.new(1, 0, 0, HEADER_H + 4)
	shadow.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
	shadow.BackgroundTransparency = SD_REST.BackgroundTransparency
	shadow.BorderSizePixel        = 0
	shadow.ZIndex                 = 1
	local shadowCorner            = Instance.new("UICorner")
	shadowCorner.CornerRadius     = UDim.new(0, Theme.Radius.Small + 1)
	shadowCorner.Parent           = shadow
	shadow.Parent                 = frame
	self._shadow                  = shadow

	-- header
	local inner            = Instance.new("Frame")
	inner.Name             = "Inner"
	inner.AnchorPoint      = Vector2.new(0.5, 0)
	inner.Position         = UDim2.new(0.5, 0, 0, 0)
	inner.Size             = UDim2.new(1, 0, 0, HEADER_H)
	inner.BackgroundColor3 = Color3.new(1, 1, 1)
	inner.BorderSizePixel  = 0
	inner.ZIndex           = 2
	inner.Parent           = frame
	self._inner            = inner

	local grad    = Instance.new("UIGradient")
	grad.Color    = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromHex("#2e2e2e")),
		ColorSequenceKeypoint.new(1, Color3.fromHex("#181818")),
	})
	grad.Rotation = 90
	grad.Parent   = inner

	local innerCorner        = Instance.new("UICorner")
	innerCorner.CornerRadius = UDim.new(0, Theme.Radius.Small)
	innerCorner.Parent       = inner

	local stroke           = Instance.new("UIStroke")
	stroke.Color           = Theme.Colors.Border
	stroke.Thickness       = 1
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent          = inner
	self._stroke           = stroke

	local pad        = Instance.new("UIPadding")
	pad.PaddingLeft  = UDim.new(0, leftPad)
	pad.PaddingRight = UDim.new(0, Theme.Spacing.M)
	pad.Parent       = inner

	local flash                  = Instance.new("Frame")
	flash.Name                   = "Flash"
	flash.Size                   = UDim2.new(1, leftPad + Theme.Spacing.M, 1, 0)
	flash.Position               = UDim2.new(0, -leftPad, 0, 0)
	flash.BackgroundColor3       = Color3.new(1, 1, 1)
	flash.BackgroundTransparency = 1
	flash.BorderSizePixel        = 0
	flash.ZIndex                 = 3
	local flashCorner            = Instance.new("UICorner")
	flashCorner.CornerRadius     = UDim.new(0, Theme.Radius.Small)
	flashCorner.Parent           = flash
	flash.Parent                 = inner
	self._flash                  = flash

	local ARROW_W = 16
	local arrow                  = Instance.new("TextLabel")
	arrow.Name                   = "Arrow"
	arrow.AnchorPoint            = Vector2.new(1, 0.5)
	arrow.Position               = UDim2.new(1, 0, 0.5, 0)
	arrow.Size                   = UDim2.fromOffset(ARROW_W, HEADER_H)
	arrow.BackgroundTransparency = 1
	arrow.Font                   = Enum.Font.GothamBold
	arrow.Text                   = "^"
	arrow.TextSize               = 12
	arrow.TextColor3             = Theme.Colors.TextSecondary
	arrow.TextXAlignment         = Enum.TextXAlignment.Center
	arrow.Rotation               = 0
	arrow.ZIndex                 = 4
	arrow.Parent                 = inner
	self._arrow                  = arrow

	-- header value text
	local initText, initHas    = headerText(self)
	local valueLabel                  = Instance.new("TextLabel")
	valueLabel.Name                   = "ValueLabel"
	valueLabel.Size                   = UDim2.new(1, -(ARROW_W + 4), 1, 0)
	valueLabel.BackgroundTransparency = 1
	valueLabel.Font                   = Theme.Font.Body
	valueLabel.Text                   = initText
	valueLabel.TextSize               = Theme.TextSize.Body
	valueLabel.TextColor3             = if initHas
		then Theme.Colors.TextPrimary
		else Theme.Colors.TextDisabled
	valueLabel.TextXAlignment         = Enum.TextXAlignment.Right
	valueLabel.TextTruncate           = Enum.TextTruncate.AtEnd
	valueLabel.ZIndex                 = 4
	valueLabel.Parent                 = inner
	self._valueLabel                  = valueLabel

	-- optional left label
	if hasLabel then
		local outerLabel                  = Instance.new("TextLabel")
		outerLabel.Name                   = "Label"
		outerLabel.Position               = UDim2.fromOffset(Theme.Spacing.M, 0)
		outerLabel.Size                   = UDim2.fromOffset(LABEL_W, HEADER_H)
		outerLabel.BackgroundTransparency = 1
		outerLabel.Font                   = Theme.Font.Body
		outerLabel.Text                   = config.Label :: string
		outerLabel.TextSize               = Theme.TextSize.Body
		outerLabel.TextColor3             = if self._enabled
			then Theme.Colors.TextPrimary
			else Theme.Colors.TextDisabled
		outerLabel.TextXAlignment         = Enum.TextXAlignment.Left
		outerLabel.TextTruncate           = Enum.TextTruncate.AtEnd
		outerLabel.ZIndex                 = 4
		outerLabel.Parent                 = frame
		self._outerLabel                  = outerLabel
	end

	local hit                  = Instance.new("TextButton")
	hit.Name                   = "Hit"
	hit.Size                   = UDim2.fromScale(1, 1)
	hit.BackgroundTransparency = 1
	hit.Text                   = ""
	hit.AutoButtonColor        = false
	hit.ZIndex                 = 5
	hit.Parent                 = inner

	-- ── list container ────────────────────────────────────────────────────────
	local listWrap                  = Instance.new("Frame")
	listWrap.Name                   = "ListWrap"
	listWrap.Position               = UDim2.new(0, 0, 0, HEADER_H + LIST_GAP)
	listWrap.Size                   = UDim2.new(1, 0, 0, 0)
	listWrap.BackgroundColor3       = Color3.fromHex("#1a1a1a")
	listWrap.BackgroundTransparency = 1
	listWrap.BorderSizePixel        = 0
	listWrap.ClipsDescendants       = true
	listWrap.ZIndex                 = 2
	local listCorner                = Instance.new("UICorner")
	listCorner.CornerRadius         = UDim.new(0, Theme.Radius.Small)
	listCorner.Parent               = listWrap
	local listStroke                = Instance.new("UIStroke")
	listStroke.Color                = Theme.Colors.Border
	listStroke.Thickness            = 1
	listStroke.Transparency         = 1
	listStroke.ApplyStrokeMode      = Enum.ApplyStrokeMode.Border
	listStroke.Parent               = listWrap
	listWrap.Parent                 = frame
	self._listWrap                  = listWrap
	self._listStroke                = listStroke

	local scroll                   = Instance.new("ScrollingFrame")
	scroll.Name                    = "OptionScroll"
	scroll.Size                    = UDim2.fromScale(1, 1)
	scroll.BackgroundTransparency  = 1
	scroll.BorderSizePixel         = 0
	scroll.ScrollBarThickness      = 3
	scroll.ScrollBarImageColor3    = Theme.Colors.Border
	scroll.CanvasSize              = UDim2.fromOffset(0, 0)
	scroll.AutomaticCanvasSize     = Enum.AutomaticSize.None
	scroll.ClipsDescendants        = true
	scroll.ZIndex                  = 3
	scroll.Parent                  = listWrap
	self._scroll                   = scroll
	self._maid:GiveTask(SmoothScroll.apply(scroll))

	local listLayout         = Instance.new("UIListLayout")
	listLayout.FillDirection = Enum.FillDirection.Vertical
	listLayout.SortOrder     = Enum.SortOrder.LayoutOrder
	listLayout.Padding       = UDim.new(0, 0)
	listLayout.Parent        = scroll

	-- ── Signal ────────────────────────────────────────────────────────────────
	local changed = Signal.new()
	self.Changed  = changed
	self._maid:GiveTask(changed)
	self._maid:GiveTask(self._optionMaid)

	-- ── open / close ──────────────────────────────────────────────────────────
	local function closeDropdown()
		if not self._open then return end
		self._open = false
		TweenService:Create(arrow,      TWEEN_ARROW,    { Rotation = 0 }):Play()
		TweenService:Create(stroke,     TWEEN_STROKE,   { Color = Theme.Colors.Border }):Play()
		TweenService:Create(listWrap,   TWEEN_COLLAPSE, { Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1 }):Play()
		TweenService:Create(listStroke, TWEEN_FADE,     { Transparency = 1 }):Play()
		TweenService:Create(frame,      TWEEN_COLLAPSE, { Size = UDim2.new(1, 0, 0, HEADER_H) }):Play()
	end

	local function openDropdown()
		if self._open or not self._enabled then return end
		self._open = true
		TweenService:Create(arrow,      TWEEN_ARROW,   { Rotation = -180 }):Play()
		TweenService:Create(stroke,     TWEEN_STROKE,  { Color = Theme.Colors.Accent }):Play()
		TweenService:Create(listWrap,   TWEEN_EXPAND,  { Size = UDim2.new(1, 0, 0, self._targetH), BackgroundTransparency = 0 }):Play()
		TweenService:Create(listStroke, TWEEN_FADE,    { Transparency = 0 }):Play()
		TweenService:Create(frame,      TWEEN_EXPAND,  { Size = UDim2.new(1, 0, 0, HEADER_H + LIST_GAP + self._targetH) }):Play()
	end

	-- Store references so buildOptions closure can reach them
	self._openDropdown  = openDropdown
	self._closeDropdown = closeDropdown

	-- ── build option rows (internal) ──────────────────────────────────────────
	local function buildOptions()
		self._optionMaid:DoCleaning()
		for _, child in ipairs(scroll:GetChildren()) do
			if child:IsA("Frame") then child:Destroy() end
		end

		local optCount = #self._options
		local fullH    = optCount * OPTION_H
		scroll.CanvasSize = UDim2.fromOffset(0, fullH)
		self._targetH  = math.min(fullH, MAX_H)

		for i, opt in ipairs(self._options) do
			local isSelected = if self._multiSelect
				then self._selectedSet[opt.Value] == true
				else self._selectedValue == opt.Value

			local optFrame                  = Instance.new("Frame")
			optFrame.Name                   = "Option_" .. i
			optFrame.Size                   = UDim2.new(1, 0, 0, OPTION_H)
			optFrame.BackgroundColor3       = Color3.fromHex("#1a1a1a")
			optFrame.BackgroundTransparency = 1
			optFrame.BorderSizePixel        = 0
			optFrame.LayoutOrder            = i
			optFrame.ZIndex                 = 3

			-- Checkmark column (multiSelect only)
			local checkLabel: TextLabel? = nil
			if self._multiSelect then
				local ck                  = Instance.new("TextLabel")
				ck.Name                   = "Check"
				ck.Size                   = UDim2.fromOffset(CHECK_W, OPTION_H)
				ck.Position               = UDim2.fromOffset(Theme.Spacing.XS, 0)
				ck.BackgroundTransparency = 1
				ck.Font                   = Enum.Font.GothamBold
				ck.Text                   = if isSelected then "✓" else ""
				ck.TextSize               = 11
				ck.TextColor3             = Theme.Colors.Accent
				ck.TextXAlignment         = Enum.TextXAlignment.Center
				ck.ZIndex                 = 4
				ck.Parent                 = optFrame
				checkLabel                = ck
			end

			local labelXOffset = if self._multiSelect then CHECK_W + Theme.Spacing.XS else Theme.Spacing.M
			local labelWOffset = if self._multiSelect then -(CHECK_W + Theme.Spacing.XS + Theme.Spacing.M) else -(Theme.Spacing.M * 2)

			local optLabel                  = Instance.new("TextLabel")
			optLabel.Name                   = "OptionLabel"
			optLabel.Size                   = UDim2.new(1, labelWOffset, 1, 0)
			optLabel.Position               = UDim2.fromOffset(labelXOffset, 0)
			optLabel.BackgroundTransparency = 1
			optLabel.Font                   = Theme.Font.Body
			optLabel.Text                   = opt.Label
			optLabel.TextSize               = Theme.TextSize.Body
			optLabel.TextColor3             = if isSelected
				then Theme.Colors.Accent
				else Theme.Colors.TextPrimary
			optLabel.TextXAlignment         = if self._multiSelect
				then Enum.TextXAlignment.Left
				else Enum.TextXAlignment.Center
			optLabel.TextTruncate           = Enum.TextTruncate.AtEnd
			optLabel.ZIndex                 = 4
			optLabel.Parent                 = optFrame

			if i < optCount then
				local sep                  = Instance.new("Frame")
				sep.Size                   = UDim2.new(1, -Theme.Spacing.M * 2, 0, 1)
				sep.Position               = UDim2.new(0, Theme.Spacing.M, 1, -1)
				sep.BackgroundColor3       = Theme.Colors.Border
				sep.BackgroundTransparency = 0.7
				sep.BorderSizePixel        = 0
				sep.ZIndex                 = 4
				sep.Parent                 = optFrame
			end

			local optHit                  = Instance.new("TextButton")
			optHit.Name                   = "Hit"
			optHit.Size                   = UDim2.fromScale(1, 1)
			optHit.BackgroundTransparency = 1
			optHit.Text                   = ""
			optHit.AutoButtonColor        = false
			optHit.ZIndex                 = 5
			optHit.Parent                 = optFrame

			self._optionMaid:GiveTask(optHit.MouseEnter:Connect(function()
				TweenService:Create(optFrame, TWEEN_HOVER, {
					BackgroundTransparency = 0.82,
					BackgroundColor3       = Theme.Colors.SurfaceHover,
				}):Play()
			end))
			self._optionMaid:GiveTask(optHit.MouseLeave:Connect(function()
				TweenService:Create(optFrame, TWEEN_HOVER, {
					BackgroundTransparency = 1,
					BackgroundColor3       = Color3.fromHex("#1a1a1a"),
				}):Play()
			end))

			self._optionMaid:GiveTask(optHit.MouseButton1Click:Connect(function()
				if not self._enabled then return end

				if self._multiSelect then
					-- toggle selection
					if self._selectedSet[opt.Value] then
						self._selectedSet[opt.Value] = nil
						optLabel.TextColor3 = Theme.Colors.TextPrimary
						if checkLabel then checkLabel.Text = "" end
					else
						self._selectedSet[opt.Value] = true
						optLabel.TextColor3 = Theme.Colors.Accent
						if checkLabel then checkLabel.Text = "✓" end
					end
					-- rebuild selected array for Value
					local arr: { any } = {}
					for _, o in ipairs(self._options) do
						if self._selectedSet[o.Value] then
							table.insert(arr, o.Value)
						end
					end
					self.Value = arr
					-- update header
					local txt, has = headerText(self)
					valueLabel.Text       = txt
					valueLabel.TextColor3 = if has
						then Theme.Colors.TextPrimary
						else Theme.Colors.TextDisabled
					changed:Fire(arr)
					-- stay open on multi

				else
					-- single select: deselect all then select this
					for _, child in ipairs(scroll:GetChildren()) do
						if child:IsA("Frame") then
							local lbl = child:FindFirstChildWhichIsA("TextLabel")
							if lbl and lbl.Name == "OptionLabel" then
								lbl.TextColor3 = Theme.Colors.TextPrimary
							end
						end
					end
					optLabel.TextColor3   = Theme.Colors.Accent
					self._selectedValue   = opt.Value
					self.Value            = opt.Value
					valueLabel.Text       = opt.Label
					valueLabel.TextColor3 = Theme.Colors.TextPrimary
					changed:Fire(opt.Value, opt.Label)
					closeDropdown()
				end
			end))

			optFrame.Parent = scroll
		end
	end

	self._buildOptions = buildOptions
	buildOptions()

	-- ── hover / click on header ───────────────────────────────────────────────
	local hovering = false

	self._maid:GiveTask(hit.MouseEnter:Connect(function()
		if not self._enabled then return end
		hovering = true
		TweenService:Create(stroke, TWEEN_STROKE, { Color = Theme.Colors.Accent }):Play()
		TweenService:Create(flash,  TWEEN_HOVER,  { BackgroundTransparency = 0.92 }):Play()
		TweenService:Create(shadow, TWEEN_HOVER,  SD_HOVER):Play()
	end))

	self._maid:GiveTask(hit.MouseLeave:Connect(function()
		if not self._enabled then return end
		hovering = false
		if not self._open then
			TweenService:Create(stroke, TWEEN_STROKE, { Color = Theme.Colors.Border }):Play()
			TweenService:Create(flash,  TWEEN_HOVER,  { BackgroundTransparency = 1 }):Play()
			TweenService:Create(shadow, TWEEN_HOVER,  SD_REST):Play()
		end
	end))

	self._maid:GiveTask(hit.MouseButton1Click:Connect(function()
		if not self._enabled then return end
		if self._open then
			closeDropdown()
			if not hovering then
				TweenService:Create(flash,  TWEEN_HOVER, { BackgroundTransparency = 1 }):Play()
				TweenService:Create(shadow, TWEEN_HOVER, SD_REST):Play()
			end
		else
			openDropdown()
		end
	end))

	-- close on click outside
	self._maid:GiveTask(UserInputService.InputBegan:Connect(function(input: InputObject)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch then return end
		if not self._open then return end
		local mousePos = UserInputService:GetMouseLocation()
		if not isInsideFrame(frame, mousePos) then
			closeDropdown()
		end
	end))

	return self
end

-- ── public API ────────────────────────────────────────────────────────────────

function Dropdown:SetOptions(options: { any })
	if self._open then
		self._closeDropdown()
		self._arrow.Rotation                    = 0
		self._listWrap.Size                     = UDim2.new(1, 0, 0, 0)
		self._listWrap.BackgroundTransparency   = 1
		self._listStroke.Transparency           = 1
		self._frame.Size                        = UDim2.new(1, 0, 0, HEADER_H)
		TweenService:Create(self._stroke, TWEEN_STROKE, { Color = Theme.Colors.Border }):Play()
	end

	self._options = normalizeOptions(options)

	-- validate existing selection against new options
	if self._multiSelect then
		local newSet: { [any]: boolean } = {}
		for _, opt in ipairs(self._options) do
			if self._selectedSet[opt.Value] then
				newSet[opt.Value] = true
			end
		end
		self._selectedSet = newSet
		local arr: { any } = {}
		for _, opt in ipairs(self._options) do
			if self._selectedSet[opt.Value] then table.insert(arr, opt.Value) end
		end
		self.Value = arr
	else
		local found = false
		for _, opt in ipairs(self._options) do
			if opt.Value == self._selectedValue then found = true break end
		end
		if not found then
			self._selectedValue = nil
			self.Value          = nil
		end
	end

	local txt, has          = headerText(self)
	self._valueLabel.Text       = txt
	self._valueLabel.TextColor3 = if has
		then Theme.Colors.TextPrimary
		else Theme.Colors.TextDisabled

	self._buildOptions()
end

-- SetValue accepts a single value (single-select) or array (multi-select).
function Dropdown:SetValue(value: any)
	if self._multiSelect then
		local arr: { any } = if typeof(value) == "table" then value else { value }
		self._selectedSet = {}
		for _, v in ipairs(arr) do
			self._selectedSet[v] = true
		end
		self.Value = arr
	else
		local found = false
		for _, opt in ipairs(self._options) do
			if opt.Value == value then found = true break end
		end
		self._selectedValue = if found then value else nil
		self.Value          = self._selectedValue
	end

	local txt, has          = headerText(self)
	self._valueLabel.Text       = txt
	self._valueLabel.TextColor3 = if has
		then Theme.Colors.TextPrimary
		else Theme.Colors.TextDisabled

	-- Rebuild list to reflect new highlight state
	self._buildOptions()
end

function Dropdown:SetEnabled(enabled: boolean)
	self._enabled = enabled
	self._stroke.Transparency = if enabled then 0 else 0.5
	if self._outerLabel then
		self._outerLabel.TextColor3 = if enabled
			then Theme.Colors.TextPrimary
			else Theme.Colors.TextDisabled
	end
	if not enabled and self._open then
		self._closeDropdown()
		self._arrow.Rotation                  = 0
		self._listWrap.Size                   = UDim2.new(1, 0, 0, 0)
		self._listWrap.BackgroundTransparency = 1
		self._listStroke.Transparency         = 1
		self._frame.Size                      = UDim2.new(1, 0, 0, HEADER_H)
	end
end

function Dropdown:GetFrame(): Frame
	return self._frame
end

function Dropdown:Destroy()
	self._maid:DoCleaning()
	if self._frame and self._frame.Parent then
		self._frame:Destroy()
	end
end

return Dropdown
