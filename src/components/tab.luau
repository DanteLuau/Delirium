--!strict

-- Delirium UI Library
-- tab.luau — Tab panel that hosts all element types.
-- Each Tab owns a scroll frame. Elements are appended in order via Create* methods.
-- Modern floating capsule item with animated glowing indicator, icon/badge support,
-- and smooth state transitions.

local constants    = require(script.Parent.Parent.utility.constants)
local themeUtil    = require(script.Parent.Parent.utility.theme)
local tween        = require(script.Parent.Parent.utility.tween)
local saveManager  = require(script.Parent.Parent.utility.saveManager)
local Section      = require(script.Parent.section)
local Label        = require(script.Parent.label)
local Button       = require(script.Parent.button)
local Toggle       = require(script.Parent.toggle)
local Slider       = require(script.Parent.slider)
local Input        = require(script.Parent.input)
local Keybind      = require(script.Parent.keybind)
local Dropdown     = require(script.Parent.dropdown)
local ColorPicker  = require(script.Parent.colorpicker)
local Descriptor   = require(script.Parent.descriptor)
local icons        = require(script.Parent.Parent.utility.icons)

export type TabProps = {
	name:    string?,
	icon:    string?,
	badge:   string?,
	columns: number?,
}

export type TabColumn = {
	CreateSection:     (self: TabColumn, props: Section.SectionProps) -> Section.Section,
	CreateLabel:       (self: TabColumn, props: Label.LabelProps) -> Label.Label,
	CreateButton:      (self: TabColumn, props: Button.ButtonProps) -> Button.Button,
	CreateToggle:      (self: TabColumn, props: Toggle.ToggleProps) -> Toggle.Toggle,
	CreateSlider:      (self: TabColumn, props: Slider.SliderProps) -> Slider.Slider,
	AddSlider:         (self: TabColumn, props: Slider.SliderProps) -> Slider.Slider,
	CreateInput:       (self: TabColumn, props: Input.InputProps) -> Input.Input,
	CreateKeybind:     (self: TabColumn, props: Keybind.KeybindProps) -> Keybind.Keybind,
	CreateDropdown:    (self: TabColumn, props: Dropdown.DropdownProps) -> Dropdown.Dropdown,
	AddDropdown:       (self: TabColumn, props: Dropdown.DropdownProps) -> Dropdown.Dropdown,
	CreateColorPicker: (self: TabColumn, props: ColorPicker.ColorPickerProps) -> ColorPicker.ColorPicker,
}

export type Tab = {
	Left:              TabColumn,
	Right:             TabColumn,
	_frame:            Frame,
	_scrollFrame:      ScrollingFrame,
	_tabButton:        TextButton,
	_theme:            { [string]: any },

	CreateSection:     (self: Tab, props: Section.SectionProps) -> Section.Section,
	CreateLabel:       (self: Tab, props: Label.LabelProps) -> Label.Label,
	CreateButton:      (self: Tab, props: Button.ButtonProps) -> Button.Button,
	CreateToggle:      (self: Tab, props: Toggle.ToggleProps) -> Toggle.Toggle,
	CreateSlider:      (self: Tab, props: Slider.SliderProps) -> Slider.Slider,
	AddSlider:         (self: Tab, props: Slider.SliderProps) -> Slider.Slider,
	CreateInput:       (self: Tab, props: Input.InputProps) -> Input.Input,
	CreateKeybind:     (self: Tab, props: Keybind.KeybindProps) -> Keybind.Keybind,
	CreateDropdown:    (self: Tab, props: Dropdown.DropdownProps) -> Dropdown.Dropdown,
	AddDropdown:       (self: Tab, props: Dropdown.DropdownProps) -> Dropdown.Dropdown,
	CreateColorPicker: (self: Tab, props: ColorPicker.ColorPickerProps) -> ColorPicker.ColorPicker,

	CreateLeftSection:     (self: Tab, props: Section.SectionProps) -> Section.Section,
	CreateLeftLabel:       (self: Tab, props: Label.LabelProps) -> Label.Label,
	CreateLeftButton:      (self: Tab, props: Button.ButtonProps) -> Button.Button,
	CreateLeftToggle:      (self: Tab, props: Toggle.ToggleProps) -> Toggle.Toggle,
	CreateLeftSlider:      (self: Tab, props: Slider.SliderProps) -> Slider.Slider,
	CreateLeftInput:       (self: Tab, props: Input.InputProps) -> Input.Input,
	CreateLeftKeybind:     (self: Tab, props: Keybind.KeybindProps) -> Keybind.Keybind,
	CreateLeftDropdown:    (self: Tab, props: Dropdown.DropdownProps) -> Dropdown.Dropdown,
	CreateLeftColorPicker: (self: Tab, props: ColorPicker.ColorPickerProps) -> ColorPicker.ColorPicker,

	CreateRightSection:     (self: Tab, props: Section.SectionProps) -> Section.Section,
	CreateRightLabel:       (self: Tab, props: Label.LabelProps) -> Label.Label,
	CreateRightButton:      (self: Tab, props: Button.ButtonProps) -> Button.Button,
	CreateRightToggle:      (self: Tab, props: Toggle.ToggleProps) -> Toggle.Toggle,
	CreateRightSlider:      (self: Tab, props: Slider.SliderProps) -> Slider.Slider,
	CreateRightInput:       (self: Tab, props: Input.InputProps) -> Input.Input,
	CreateRightKeybind:     (self: Tab, props: Keybind.KeybindProps) -> Keybind.Keybind,
	CreateRightDropdown:    (self: Tab, props: Dropdown.DropdownProps) -> Dropdown.Dropdown,
	CreateRightColorPicker: (self: Tab, props: ColorPicker.ColorPickerProps) -> ColorPicker.ColorPicker,

	Show:    (self: Tab) -> (),
	Hide:    (self: Tab) -> (),
	Destroy: (self: Tab) -> (),
}

local Tab = {}
Tab.__index = Tab

-- Offset that skips the window title bar when positioning the color-picker dim overlay.
-- Matches TITLEBAR_H + 1 as defined in window.luau.
local OVERLAY_Y_OFFSET = 45

local function resolveIcon(icon: string?): string?
	if not icon or icon == "" then return nil end
	return icons.Resolve(icon, "Lucide")
end

function Tab.new(props: TabProps, theme: { [string]: any }, contentParent: Frame, sidebarParent: Frame, windowFrame: Frame?): Tab
	local name      = props.name or "Tab"
	local iconAsset = resolveIcon(props.icon)
	local badgeText = props.badge

	local hasIcon  = iconAsset ~= nil
	local hasBadge = badgeText ~= nil and badgeText ~= ""

	-- ── Design tokens (initial) ──────────────────────────────────────────────
	local function getTokens(t: { [string]: any })
		return {
			colorBorder       = t.SurfaceStroke     or Color3.fromHex("#2b2b2b"),
			colorAccent       = t.AccentColor       or Color3.fromHex("#4cc2ff"),
			colorSurfaceHover = t.NeutralButtonHover or Color3.fromHex("#252525"),
			colorTextPrimary  = t.TitlingColor      or Color3.fromHex("#ffffff"),
			colorTextSecondary= t.PlaceholderColor  or Color3.fromHex("#8c8c96"),
			font              = t.Font or Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium),
		}
	end

	local tokens = getTokens(theme)

	-- ── Content panel: Obsidian-style dual-column split view ─────────────
	local numColumns = props.columns or 2
	local isDual = numColumns ~= 1

	-- Root tab panel frame (holds both columns)
	local tabContainer = Instance.new("Frame")
	tabContainer.Name                    = "Tab_" .. name
	tabContainer.Size                    = UDim2.fromScale(1, 1)
	tabContainer.BackgroundTransparency  = 1
	tabContainer.Visible                 = false
	tabContainer.Parent                  = contentParent

	-- Left Column ScrollingFrame (independent scroll)
	local leftScroll = Instance.new("ScrollingFrame")
	leftScroll.Name                    = "Column_Left"
	leftScroll.Position                = UDim2.fromScale(0, 0)
	leftScroll.Size                    = if isDual then UDim2.new(0.5, -4, 1, 0) else UDim2.fromScale(1, 1)
	leftScroll.BackgroundTransparency  = 1
	leftScroll.ScrollBarThickness      = 2
	leftScroll.ScrollBarImageColor3    = tokens.colorBorder
	leftScroll.ScrollBarImageTransparency = 0.5
	leftScroll.BorderSizePixel         = 0
	leftScroll.CanvasSize              = UDim2.fromOffset(0, 0)
	leftScroll.AutomaticCanvasSize     = Enum.AutomaticSize.Y
	leftScroll.ClipsDescendants        = true
	leftScroll.Parent                  = tabContainer

	local leftLayout = Instance.new("UIListLayout")
	leftLayout.SortOrder           = Enum.SortOrder.LayoutOrder
	leftLayout.FillDirection       = Enum.FillDirection.Vertical
	leftLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	leftLayout.Padding             = UDim.new(0, constants.elementPadding)
	leftLayout.Parent              = leftScroll

	local leftPad = Instance.new("UIPadding")
	leftPad.PaddingLeft   = UDim.new(0, constants.contentPadding)
	leftPad.PaddingRight  = if isDual then UDim.new(0, 4) else UDim.new(0, constants.contentPadding)
	leftPad.PaddingTop    = UDim.new(0, 8)
	leftPad.PaddingBottom = UDim.new(0, 8)
	leftPad.Parent        = leftScroll

	-- Right Column ScrollingFrame (independent scroll)
	local rightScroll: ScrollingFrame? = nil
	local columnDivider: Frame? = nil

	if isDual then
		local rs = Instance.new("ScrollingFrame")
		rs.Name                    = "Column_Right"
		rs.AnchorPoint             = Vector2.new(1, 0)
		rs.Position                = UDim2.fromScale(1, 0)
		rs.Size                    = UDim2.new(0.5, -4, 1, 0)
		rs.BackgroundTransparency  = 1
		rs.ScrollBarThickness      = 2
		rs.ScrollBarImageColor3    = tokens.colorBorder
		rs.ScrollBarImageTransparency = 0.5
		rs.BorderSizePixel         = 0
		rs.CanvasSize              = UDim2.fromOffset(0, 0)
		rs.AutomaticCanvasSize     = Enum.AutomaticSize.Y
		rs.ClipsDescendants        = true
		rs.Parent                  = tabContainer

		local rightLayout = Instance.new("UIListLayout")
		rightLayout.SortOrder           = Enum.SortOrder.LayoutOrder
		rightLayout.FillDirection       = Enum.FillDirection.Vertical
		rightLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		rightLayout.Padding             = UDim.new(0, constants.elementPadding)
		rightLayout.Parent              = rs

		local rightPad = Instance.new("UIPadding")
		rightPad.PaddingLeft   = UDim.new(0, 4)
		rightPad.PaddingRight  = UDim.new(0, constants.contentPadding)
		rightPad.PaddingTop    = UDim.new(0, 8)
		rightPad.PaddingBottom = UDim.new(0, 8)
		rightPad.Parent        = rs

		rightScroll = rs

		-- Vertical divider between columns
		local div = Instance.new("Frame")
		div.Name                   = "ColumnDivider"
		div.AnchorPoint            = Vector2.new(0.5, 0)
		div.Position               = UDim2.new(0.5, 0, 0, 8)
		div.Size                   = UDim2.new(0, 1, 1, -16)
		div.BackgroundColor3       = tokens.colorBorder
		div.BackgroundTransparency = 0.7
		div.BorderSizePixel        = 0
		div.Parent                 = tabContainer
		columnDivider              = div
	end

	-- ── Sidebar modern tab button ─────────────────────────────────────────
	local tabBtn = Instance.new("TextButton")
	tabBtn.Name                   = "TabBtn_" .. name
	tabBtn.Size                   = UDim2.new(1, 0, 0, 36)
	tabBtn.BackgroundColor3       = tokens.colorAccent
	tabBtn.BackgroundTransparency = 1
	tabBtn.BorderSizePixel        = 0
	tabBtn.AutoButtonColor        = false
	tabBtn.Text                   = ""
	tabBtn.Active                 = true
	tabBtn.Parent                 = sidebarParent

	local tabBtnCorner = Instance.new("UICorner")
	tabBtnCorner.CornerRadius = UDim.new(0, 8)
	tabBtnCorner.Parent       = tabBtn

	local tabStroke = Instance.new("UIStroke")
	tabStroke.Color           = tokens.colorBorder
	tabStroke.Thickness       = 1
	tabStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	tabStroke.Transparency    = 1
	tabStroke.Parent          = tabBtn

	-- Left glowing active indicator pill
	local indicator = Instance.new("Frame")
	indicator.Name                   = "Indicator"
	indicator.AnchorPoint            = Vector2.new(0, 0.5)
	indicator.Position               = UDim2.new(0, 4, 0.5, 0)
	indicator.Size                   = UDim2.fromOffset(3, 0)
	indicator.BackgroundColor3       = tokens.colorAccent
	indicator.BackgroundTransparency = 1
	indicator.BorderSizePixel        = 0
	indicator.ZIndex                 = 3
	indicator.Parent                 = tabBtn

	local indCorner = Instance.new("UICorner")
	indCorner.CornerRadius = UDim.new(1, 0)
	indCorner.Parent       = indicator

	-- Content row inside tab button
	local contentRow = Instance.new("Frame")
	contentRow.Name                   = "ContentRow"
	contentRow.Size                   = UDim2.fromScale(1, 1)
	contentRow.BackgroundTransparency = 1
	contentRow.Parent                 = tabBtn

	local rowLayout = Instance.new("UIListLayout")
	rowLayout.FillDirection       = Enum.FillDirection.Horizontal
	rowLayout.VerticalAlignment   = Enum.VerticalAlignment.Center
	rowLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	rowLayout.Padding             = UDim.new(0, 8)
	rowLayout.SortOrder           = Enum.SortOrder.LayoutOrder
	rowLayout.Parent              = contentRow

	local rowPad = Instance.new("UIPadding")
	rowPad.PaddingLeft   = UDim.new(0, 13)
	rowPad.PaddingRight  = if hasBadge then UDim.new(0, 46) else UDim.new(0, 8)
	rowPad.Parent        = contentRow

	local iconImg: ImageLabel? = nil
	if hasIcon then
		local img = Instance.new("ImageLabel")
		img.Name                   = "Icon"
		img.Size                   = UDim2.fromOffset(16, 16)
		img.BackgroundTransparency = 1
		img.Image                  = iconAsset :: string
		img.ImageColor3            = tokens.colorTextSecondary
		img.LayoutOrder            = 1
		img.Parent                 = contentRow
		iconImg                    = img
	end

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name                   = "Title"
	titleLabel.Size                   = UDim2.new(1, if hasIcon then -24 else 0, 1, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text                   = name
	titleLabel.TextColor3             = tokens.colorTextSecondary
	titleLabel.TextSize               = 13
	titleLabel.FontFace               = tokens.font
	titleLabel.TextXAlignment         = Enum.TextXAlignment.Left
	titleLabel.TextTruncate           = Enum.TextTruncate.AtEnd
	titleLabel.LayoutOrder            = 2
	titleLabel.Parent                 = contentRow

	local badgeFrame: Frame? = nil
	local badgeLabel: TextLabel? = nil
	local badgeStroke: UIStroke? = nil
	if hasBadge then
		local bf = Instance.new("Frame")
		bf.Name                   = "Badge"
		bf.AnchorPoint            = Vector2.new(1, 0.5)
		bf.Position               = UDim2.new(1, -8, 0.5, 0)
		bf.AutomaticSize          = Enum.AutomaticSize.X
		bf.Size                   = UDim2.fromOffset(0, 16)
		bf.BackgroundColor3       = tokens.colorAccent
		bf.BackgroundTransparency = 0.82
		bf.BorderSizePixel        = 0
		bf.ZIndex                 = 2
		bf.Parent                 = tabBtn

		local bc = Instance.new("UICorner")
		bc.CornerRadius = UDim.new(1, 0)
		bc.Parent       = bf

		local bs = Instance.new("UIStroke")
		bs.Color        = tokens.colorAccent
		bs.Thickness    = 1
		bs.Transparency = 0.45
		bs.Parent       = bf
		badgeStroke     = bs

		local bp = Instance.new("UIPadding")
		bp.PaddingLeft  = UDim.new(0, 6)
		bp.PaddingRight = UDim.new(0, 6)
		bp.Parent       = bf

		local bl = Instance.new("TextLabel")
		bl.Name                   = "Label"
		bl.Size                   = UDim2.fromScale(0, 1)
		bl.AutomaticSize          = Enum.AutomaticSize.X
		bl.BackgroundTransparency = 1
		bl.Text                   = badgeText :: string
		bl.TextColor3             = tokens.colorAccent
		bl.TextSize               = 9
		bl.FontFace               = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold)
		bl.Parent                 = bf
		badgeLabel                = bl
		badgeFrame                = bf
	end

	-- Hover animations (inactive state only)
	tabBtn.MouseEnter:Connect(function()
		if tabContainer.Visible then return end
		tween.fire(tabBtn, constants.tweenFast, {
			BackgroundColor3       = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 0.94,
		})
		tween.fire(tabStroke, constants.tweenFast, {
			Color        = tokens.colorBorder,
			Transparency = 0.65,
		})
		tween.fire(titleLabel, constants.tweenFast, {
			TextColor3 = tokens.colorTextPrimary:Lerp(tokens.colorTextSecondary, 0.3),
		})
		if iconImg then
			tween.fire(iconImg, constants.tweenFast, {
				ImageColor3 = tokens.colorTextPrimary:Lerp(tokens.colorTextSecondary, 0.3),
			})
		end
	end)

	tabBtn.MouseLeave:Connect(function()
		if tabContainer.Visible then return end
		tween.fire(tabBtn, constants.tweenFast, {
			BackgroundTransparency = 1,
		})
		tween.fire(tabStroke, constants.tweenFast, {
			Transparency = 1,
		})
		tween.fire(titleLabel, constants.tweenFast, {
			TextColor3 = tokens.colorTextSecondary,
		})
		if iconImg then
			tween.fire(iconImg, constants.tweenFast, {
				ImageColor3 = tokens.colorTextSecondary,
			})
		end
	end)

	local self = setmetatable({}, Tab) :: any
	self._frame            = tabContainer
	self._container        = tabContainer
	self._scrollFrame      = leftScroll
	self._leftScrollFrame  = leftScroll
	self._rightScrollFrame = rightScroll
	self._isDual           = isDual
	self._tabButton        = tabBtn
	self._theme            = theme
	self._indicator        = indicator
	self._tabStroke        = tabStroke
	self._titleLabel       = titleLabel
	self._iconImg          = iconImg
	self._badgeFrame       = badgeFrame
	self._badgeLabel       = badgeLabel
	self._badgeStroke      = badgeStroke
	self._tokens           = tokens
	self._elementCount     = 0
	self._elements         = {}
	self._windowFrame      = windowFrame

	-- Proxies for tab.Left and tab.Right (Obsidian style)
	local function createSideProxy(targetScroll: ScrollingFrame)
		return {
			CreateSection     = function(_, p) return self:_createOn(targetScroll, Section, p) end,
			CreateLabel       = function(_, p) return self:_createOn(targetScroll, Label, p) end,
			CreateButton      = function(_, p) return self:_createOn(targetScroll, Button, p) end,
			CreateToggle      = function(_, p) return self:_createOn(targetScroll, Toggle, p) end,
			CreateSlider      = function(_, p) return self:_createOn(targetScroll, Slider, p) end,
			AddSlider         = function(_, p) return self:_createOn(targetScroll, Slider, p) end,
			CreateInput       = function(_, p) return self:_createOn(targetScroll, Input, p) end,
			CreateKeybind     = function(_, p) return self:_createOn(targetScroll, Keybind, p) end,
			CreateDropdown    = function(_, p) return self:_createOn(targetScroll, Dropdown, p) end,
			AddDropdown       = function(_, p) return self:_createOn(targetScroll, Dropdown, p) end,
			CreateColorPicker = function(_, p) return self:_createColorPickerOn(targetScroll, p) end,
		}
	end

	self.Left  = createSideProxy(leftScroll)
	self.Right = createSideProxy(if isDual and rightScroll then rightScroll else leftScroll)

	-- Theme subscription
	self._themeUnsub = themeUtil.subscribe(function(t)
		self._theme = t
		tokens = getTokens(t)
		self._tokens = tokens
		leftScroll.ScrollBarImageColor3 = tokens.colorBorder
		if rightScroll then
			rightScroll.ScrollBarImageColor3 = tokens.colorBorder
		end
		if columnDivider then
			columnDivider.BackgroundColor3 = tokens.colorBorder
		end

		if badgeStroke then badgeStroke.Color = tokens.colorAccent end
		if badgeLabel then badgeLabel.TextColor3 = tokens.colorAccent end
		if badgeFrame then badgeFrame.BackgroundColor3 = tokens.colorAccent end

		if tabContainer.Visible then
			tabBtn.BackgroundColor3          = tokens.colorAccent
			tabBtn.BackgroundTransparency    = 0.86
			tabStroke.Color                  = tokens.colorAccent
			tabStroke.Transparency           = 0.4
			indicator.BackgroundColor3       = tokens.colorAccent
			indicator.BackgroundTransparency = 0
			indicator.Size                   = UDim2.fromOffset(3, 18)
			titleLabel.TextColor3            = tokens.colorTextPrimary
			if iconImg then iconImg.ImageColor3 = tokens.colorAccent end
		else
			tabBtn.BackgroundTransparency    = 1
			tabStroke.Color                  = tokens.colorBorder
			tabStroke.Transparency           = 1
			indicator.BackgroundColor3       = tokens.colorAccent
			indicator.BackgroundTransparency = 1
			indicator.Size                   = UDim2.fromOffset(3, 0)
			titleLabel.TextColor3            = tokens.colorTextSecondary
			if iconImg then iconImg.ImageColor3 = tokens.colorTextSecondary end
		end
	end)

	return self
end

-- Helper: assign layout order to each new element
local function nextOrder(self: Tab): number
	local count = (self :: any)._elementCount + 1
	(self :: any)._elementCount = count
	return count
end

function Tab:_resolveParent(side: string?): ScrollingFrame
	local s = (self :: any)
	if s._isDual and s._rightScrollFrame and side and (string.lower(side) == "right" or side == "2") then
		return s._rightScrollFrame
	end
	return s._leftScrollFrame
end

function Tab:_createOn(targetScroll: ScrollingFrame, module: any, props: any): any
	-- Auto-derive flagKey from name when no explicit flag is provided
	if props and not props.flag and not (props :: any).Flag
		and not (props :: any).noSave and not (props :: any).ignoreFlag then
		local nameStr = props.name or (props :: any).Label or (props :: any).Text
		if type(nameStr) == "string" and #nameStr > 0 then
			props = table.clone(props)
			props.flag = saveManager.deriveFlagFromName(nameStr)
		end
	end

	local el = module.new(props, self._theme, targetScroll)
	el._frame.LayoutOrder = nextOrder(self)
	table.insert((self :: any)._elements, el)

	-- Central registration: any element that exposes ._flag gets auto-registered.
	local flagKey = (el :: any)._flag
	if flagKey and flagKey ~= "" then
		saveManager:Register(flagKey, el)
	end

	local desc = props and (props.description or props.Description or props.Tooltip)
	if desc and desc ~= "" then
		local descObj = Descriptor.new(targetScroll, desc, self._theme, nextOrder(self))
		el._descriptor = descObj
		table.insert((self :: any)._elements, descObj)
	end

	return el
end

function Tab:_createColorPickerOn(targetScroll: ScrollingFrame, props: any): any
	-- Auto-derive flagKey from name when no explicit flag is provided
	if props and not props.flag and not (props :: any).Flag
		and not (props :: any).noSave and not (props :: any).ignoreFlag then
		local nameStr = props.name or (props :: any).Label or (props :: any).Text
		if type(nameStr) == "string" and #nameStr > 0 then
			props = table.clone(props)
			props.flag = saveManager.deriveFlagFromName(nameStr)
		end
	end

	local wf = (self :: any)._windowFrame :: Frame?
	local merged = table.clone(props :: any) :: ColorPicker.ColorPickerProps
	if wf and not (merged :: any).overlayParent then
		(merged :: any).overlayParent  = wf
		;(merged :: any).overlayYOffset = OVERLAY_Y_OFFSET
	end
	local cp = ColorPicker.new(merged, self._theme, targetScroll)
	cp._frame.LayoutOrder = nextOrder(self)
	table.insert((self :: any)._elements, cp)

	-- ColorPicker:Set(value, alpha?, skipCallback?) — wrap for saveManager compatibility
	local flagKey = (cp :: any)._flag
	if flagKey and flagKey ~= "" then
		saveManager:Register(flagKey, function(v: any, skipCallback: boolean?)
			cp:Set(v, nil, skipCallback)
		end)
	end

	local desc = props and (props.description or props.Description or props.Tooltip)
	if desc and desc ~= "" then
		local descObj = Descriptor.new(targetScroll, desc, self._theme, nextOrder(self))
		cp._descriptor = descObj
		table.insert((self :: any)._elements, descObj)
	end

	return cp
end

function Tab:CreateSection(props: Section.SectionProps): Section.Section
	local side = (props :: any).side or (props :: any).Side
	return self:_createOn(self:_resolveParent(side), Section, props)
end

function Tab:CreateLabel(props: Label.LabelProps): Label.Label
	local side = (props :: any).side or (props :: any).Side
	return self:_createOn(self:_resolveParent(side), Label, props)
end

function Tab:CreateButton(props: Button.ButtonProps): Button.Button
	local side = (props :: any).side or (props :: any).Side
	return self:_createOn(self:_resolveParent(side), Button, props)
end

function Tab:CreateToggle(props: Toggle.ToggleProps): Toggle.Toggle
	local side = (props :: any).side or (props :: any).Side
	return self:_createOn(self:_resolveParent(side), Toggle, props)
end

function Tab:CreateSlider(props: Slider.SliderProps): Slider.Slider
	local side = (props :: any).side or (props :: any).Side
	return self:_createOn(self:_resolveParent(side), Slider, props)
end

function Tab:AddSlider(props: Slider.SliderProps): Slider.Slider
	return self:CreateSlider(props)
end

function Tab:CreateInput(props: Input.InputProps): Input.Input
	local side = (props :: any).side or (props :: any).Side
	return self:_createOn(self:_resolveParent(side), Input, props)
end

function Tab:CreateKeybind(props: Keybind.KeybindProps): Keybind.Keybind
	local side = (props :: any).side or (props :: any).Side
	return self:_createOn(self:_resolveParent(side), Keybind, props)
end

function Tab:CreateDropdown(props: Dropdown.DropdownProps): Dropdown.Dropdown
	local side = (props :: any).side or (props :: any).Side
	return self:_createOn(self:_resolveParent(side), Dropdown, props)
end

function Tab:AddDropdown(props: Dropdown.DropdownProps): Dropdown.Dropdown
	return self:CreateDropdown(props)
end

function Tab:CreateColorPicker(props: ColorPicker.ColorPickerProps): ColorPicker.ColorPicker
	local side = (props :: any).side or (props :: any).Side
	return self:_createColorPickerOn(self:_resolveParent(side), props)
end

-- ── Left-Column Convenience Helpers ─────────────────────────────────────
function Tab:CreateLeftSection(props)     return self:_createOn((self :: any)._leftScrollFrame, Section, props) end
function Tab:CreateLeftLabel(props)       return self:_createOn((self :: any)._leftScrollFrame, Label, props) end
function Tab:CreateLeftButton(props)      return self:_createOn((self :: any)._leftScrollFrame, Button, props) end
function Tab:CreateLeftToggle(props)      return self:_createOn((self :: any)._leftScrollFrame, Toggle, props) end
function Tab:CreateLeftSlider(props)      return self:_createOn((self :: any)._leftScrollFrame, Slider, props) end
function Tab:CreateLeftInput(props)       return self:_createOn((self :: any)._leftScrollFrame, Input, props) end
function Tab:CreateLeftKeybind(props)     return self:_createOn((self :: any)._leftScrollFrame, Keybind, props) end
function Tab:CreateLeftDropdown(props)    return self:_createOn((self :: any)._leftScrollFrame, Dropdown, props) end
function Tab:CreateLeftColorPicker(props) return self:_createColorPickerOn((self :: any)._leftScrollFrame, props) end

-- ── Right-Column Convenience Helpers ────────────────────────────────────
function Tab:CreateRightSection(props)     return self:_createOn((self :: any)._rightScrollFrame or (self :: any)._leftScrollFrame, Section, props) end
function Tab:CreateRightLabel(props)       return self:_createOn((self :: any)._rightScrollFrame or (self :: any)._leftScrollFrame, Label, props) end
function Tab:CreateRightButton(props)      return self:_createOn((self :: any)._rightScrollFrame or (self :: any)._leftScrollFrame, Button, props) end
function Tab:CreateRightToggle(props)      return self:_createOn((self :: any)._rightScrollFrame or (self :: any)._leftScrollFrame, Toggle, props) end
function Tab:CreateRightSlider(props)      return self:_createOn((self :: any)._rightScrollFrame or (self :: any)._leftScrollFrame, Slider, props) end
function Tab:CreateRightInput(props)       return self:_createOn((self :: any)._rightScrollFrame or (self :: any)._leftScrollFrame, Input, props) end
function Tab:CreateRightKeybind(props)     return self:_createOn((self :: any)._rightScrollFrame or (self :: any)._leftScrollFrame, Keybind, props) end
function Tab:CreateRightDropdown(props)    return self:_createOn((self :: any)._rightScrollFrame or (self :: any)._leftScrollFrame, Dropdown, props) end
function Tab:CreateRightColorPicker(props) return self:_createColorPickerOn((self :: any)._rightScrollFrame or (self :: any)._leftScrollFrame, props) end

function Tab:Show()
	local s = (self :: any)
	s._container.Visible = true

	local tk         = s._tokens
	local tabBtn_    = self._tabButton
	local tabStroke_ = s._tabStroke
	local indicator_ = s._indicator
	local titleLabel_= s._titleLabel
	local iconImg_   = s._iconImg

	titleLabel_.FontFace = Font.new(tk.font.Family, Enum.FontWeight.SemiBold)

	tween.fire(tabBtn_, constants.tweenFast, {
		BackgroundColor3       = tk.colorAccent,
		BackgroundTransparency = 0.86,
	})
	tween.fire(tabStroke_, constants.tweenFast, {
		Color        = tk.colorAccent,
		Transparency = 0.4,
	})
	tween.fire(indicator_, constants.tweenFast, {
		Size                   = UDim2.fromOffset(3, 18),
		BackgroundTransparency = 0,
		BackgroundColor3       = tk.colorAccent,
	})
	tween.fire(titleLabel_, constants.tweenFast, {
		TextColor3 = tk.colorTextPrimary,
	})
	if iconImg_ then
		tween.fire(iconImg_, constants.tweenFast, {
			ImageColor3 = tk.colorAccent,
		})
	end
end

function Tab:Hide()
	local s = (self :: any)
	s._container.Visible = false

	local tk         = s._tokens
	local tabBtn_    = self._tabButton
	local tabStroke_ = s._tabStroke
	local indicator_ = s._indicator
	local titleLabel_= s._titleLabel
	local iconImg_   = s._iconImg

	titleLabel_.FontFace = Font.new(tk.font.Family, Enum.FontWeight.Medium)

	tween.fire(tabBtn_, constants.tweenFast, {
		BackgroundTransparency = 1,
	})
	tween.fire(tabStroke_, constants.tweenFast, {
		Transparency = 1,
		Color        = tk.colorBorder,
	})
	tween.fire(indicator_, constants.tweenFast, {
		Size                   = UDim2.fromOffset(3, 0),
		BackgroundTransparency = 1,
	})
	tween.fire(titleLabel_, constants.tweenFast, {
		TextColor3 = tk.colorTextSecondary,
	})
	if iconImg_ then
		tween.fire(iconImg_, constants.tweenFast, {
			ImageColor3 = tk.colorTextSecondary,
		})
	end
end

function Tab:Destroy()
	local s = (self :: any)
	if s._themeUnsub then s._themeUnsub() end

	for _, el in s._elements do
		pcall(function() el:Destroy() end)
	end
	s._container:Destroy()
	self._tabButton:Destroy()
end

return Tab
