--!strict
-- Groupbox — a labeled section container that hosts components vertically.
-- Used by Tab:AddGroupbox; supports single and two-column layouts.
-- Mirrors Tab's full Add* API. Dropdown OverlayParent wired internally.

local Maid  = require(script.Parent.Parent.Utils.Maid)
local Theme = require(script.Parent.Parent.Theme)

-- Require siblings directly — importing Components/init would be circular.
local Button      = require(script.Parent.Button)
local Toggle      = require(script.Parent.Toggle)
local Label       = require(script.Parent.Label)
local Description = require(script.Parent.Description)
local Divider     = require(script.Parent.Divider)
local Slider      = require(script.Parent.Slider)
local Textbox     = require(script.Parent.Textbox)
local Keybind     = require(script.Parent.Keybind)
local Dropdown    = require(script.Parent.Dropdown)
local ColorPicker = require(script.Parent.ColorPicker)

-- ── Types ─────────────────────────────────────────────────────────────────

export type GroupboxImpl = {
	AddButton:      (self: GroupboxImpl, config: any) -> any,
	AddToggle:      (self: GroupboxImpl, config: any) -> any,
	AddSlider:      (self: GroupboxImpl, config: any) -> any,
	AddTextbox:     (self: GroupboxImpl, config: any) -> any,
	AddKeybind:     (self: GroupboxImpl, config: any) -> any,
	AddDropdown:    (self: GroupboxImpl, config: any) -> any,
	AddColorPicker: (self: GroupboxImpl, config: any) -> any,
	AddLabel:       (self: GroupboxImpl, text: string, color: Color3?) -> any,
	AddDescription: (self: GroupboxImpl, config: any) -> any,
	AddDivider:     (self: GroupboxImpl, text: string?) -> any,
	GetFrame:       (self: GroupboxImpl) -> Frame,
	Destroy:        (self: GroupboxImpl) -> (),
	_maid:          any,
	_frame:         Frame,
	_gui:           ScreenGui,
	_canvas:        Frame?,
	_layoutOrder:   number,
}

-- ── Class ─────────────────────────────────────────────────────────────────

local Groupbox = {} :: { __index: any }
Groupbox.__index = Groupbox

--[[
	Groupbox.new(title, gui, parentMaid)

	title      — text shown at the top-left of the bordered box
	gui        — ScreenGui root forwarded to Dropdown as OverlayParent
	parentMaid — the Tab's maid; owns this groupbox's maid (cascade cleanup)
]]
function Groupbox.new(title: string, gui: ScreenGui, parentMaid: any, canvas: Frame?): GroupboxImpl
	local self        = setmetatable({}, Groupbox) :: GroupboxImpl
	self._maid        = Maid.new()
	self._gui         = gui
	self._canvas      = canvas
	self._layoutOrder = 0
	parentMaid:GiveTask(self._maid)

	-- ── Outer frame (the bordered Surface box) ──────────────────────────

	local frame                   = Instance.new("Frame")
	frame.Name                    = "GroupboxFrame"
	frame.AutomaticSize           = Enum.AutomaticSize.Y
	frame.Size                    = UDim2.new(1, 0, 0, 0)
	frame.BackgroundColor3        = Theme.Colors.Surface
	frame.BorderSizePixel         = 0
	frame.ClipsDescendants        = false   -- Dropdown overlay must escape the clip boundary
	self._frame                   = frame
	self._maid:GiveTask(frame)

	local corner           = Instance.new("UICorner")
	corner.CornerRadius    = UDim.new(0, Theme.Radius.Medium - 2)  -- 6px
	corner.Parent          = frame

	local stroke           = Instance.new("UIStroke")
	stroke.Color           = Theme.Colors.Border
	stroke.Thickness       = 1
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent          = frame

	local pad         = Instance.new("UIPadding")
	pad.PaddingTop    = UDim.new(0, Theme.Spacing.S)
	pad.PaddingBottom = UDim.new(0, Theme.Spacing.S)
	pad.PaddingLeft   = UDim.new(0, Theme.Spacing.S)
	pad.PaddingRight  = UDim.new(0, Theme.Spacing.S)
	pad.Parent        = frame

	local layout               = Instance.new("UIListLayout")
	layout.FillDirection       = Enum.FillDirection.Vertical
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	layout.SortOrder           = Enum.SortOrder.LayoutOrder
	layout.Padding             = UDim.new(0, Theme.Spacing.XS)
	layout.Parent              = frame

	-- ── Title label (LayoutOrder 0, always rendered first) ───────────────

	if #title > 0 then
		local titleLabel                  = Instance.new("TextLabel")
		titleLabel.Name                   = "GroupboxTitle"
		titleLabel.LayoutOrder            = 0
		titleLabel.AutomaticSize          = Enum.AutomaticSize.XY
		titleLabel.Size                   = UDim2.new(0, 0, 0, 0)
		titleLabel.BackgroundTransparency = 1
		titleLabel.BorderSizePixel        = 0
		titleLabel.Font                   = Theme.Font.Body
		titleLabel.Text                   = title
		titleLabel.TextSize               = Theme.TextSize.Small
		titleLabel.TextColor3             = Theme.Colors.TextSecondary
		titleLabel.TextXAlignment         = Enum.TextXAlignment.Left
		titleLabel.RichText               = false
		titleLabel.Parent                 = frame
	end

	return self
end

-- ── Internal helpers ───────────────────────────────────────────────────────

function Groupbox:_nextOrder(): number
	self._layoutOrder += 1
	return self._layoutOrder
end

--[[
	_addToContent — mirrors Tab:_addToContent exactly.
	Supports optional `description` key for inline sub-labels.
	ComponentWrapper has ClipsDescendants = false so Dropdown overlays escape.
]]
function Groupbox:_addToContent(comp: any, config: any?): any
	local desc = config and (config.description or config.Description)

	if typeof(desc) == "string" and #desc > 0 then
		local compFrame       = comp:GetFrame()
		compFrame.LayoutOrder = 0

		local wrapper                  = Instance.new("Frame")
		wrapper.Name                   = "ComponentWrapper"
		wrapper.AutomaticSize          = Enum.AutomaticSize.Y
		wrapper.Size                   = UDim2.new(1, 0, 0, 0)
		wrapper.BackgroundTransparency = 1
		wrapper.BorderSizePixel        = 0
		wrapper.ClipsDescendants       = false
		wrapper.LayoutOrder            = config.LayoutOrder or 0
		wrapper.Parent                 = self._frame

		local wLayout               = Instance.new("UIListLayout")
		wLayout.FillDirection       = Enum.FillDirection.Vertical
		wLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
		wLayout.SortOrder           = Enum.SortOrder.LayoutOrder
		wLayout.Padding             = UDim.new(0, Theme.Spacing.XS)
		wLayout.Parent              = wrapper

		compFrame.Parent = wrapper

		local descLabel                  = Instance.new("TextLabel")
		descLabel.Name                   = "ComponentDescription"
		descLabel.LayoutOrder            = 1
		descLabel.AutomaticSize          = Enum.AutomaticSize.Y
		descLabel.Size                   = UDim2.new(1, 0, 0, 0)
		descLabel.BackgroundTransparency = 1
		descLabel.BorderSizePixel        = 0
		descLabel.Font                   = Theme.Font.Body
		descLabel.Text                   = desc
		descLabel.TextSize               = Theme.TextSize.Small
		descLabel.TextColor3             = Theme.Colors.TextSecondary
		descLabel.TextXAlignment         = Enum.TextXAlignment.Left
		descLabel.TextWrapped            = true
		descLabel.RichText               = true
		descLabel.Parent                 = wrapper

		local descPad       = Instance.new("UIPadding")
		descPad.PaddingLeft  = UDim.new(0, Theme.Spacing.M)
		descPad.PaddingRight = UDim.new(0, Theme.Spacing.M)
		descPad.PaddingTop   = UDim.new(0, Theme.Spacing.XS)
		descPad.Parent       = descLabel

		local spacer                  = Instance.new("Frame")
		spacer.Name                   = "DescriptionSpacer"
		spacer.LayoutOrder            = 2
		spacer.BackgroundTransparency = 1
		spacer.BorderSizePixel        = 0
		spacer.Size                   = UDim2.fromOffset(0, Theme.Spacing.M)
		spacer.Parent                 = wrapper
	else
		comp:GetFrame().Parent = self._frame
	end

	self._maid:GiveTask(comp)
	return comp
end

-- ── Public Add* API ────────────────────────────────────────────────────────

function Groupbox:AddButton(config: {
	Label: string, Variant: number?, Enabled: boolean?, description: string?,
})
	local c = config :: any
	c.LayoutOrder = self:_nextOrder()
	return self:_addToContent(Button.new(c), c)
end

function Groupbox:AddToggle(config: {
	Label: string, Icon: string?, Default: boolean?, Enabled: boolean?, description: string?,
})
	local c = config :: any
	c.LayoutOrder = self:_nextOrder()
	return self:_addToContent(Toggle.new(c), c)
end

function Groupbox:AddLabel(text: string, color: Color3?)
	local lbl = Label.new({
		Text        = text,
		Color       = color,
		LayoutOrder = self:_nextOrder(),
	})
	return self:_addToContent(lbl, nil)
end

function Groupbox:AddDescription(config: { Title: string?, Description: string })
	local c = config :: any
	c.LayoutOrder = self:_nextOrder()
	local d = Description.new(c)
	d:GetFrame().Parent = self._frame
	self._maid:GiveTask(d)
	return d
end

function Groupbox:AddDivider(text: string?)
	local div = Divider.new({
		Text        = text,
		LayoutOrder = self:_nextOrder(),
	})
	return self:_addToContent(div, nil)
end

function Groupbox:AddSlider(config: {
	Label: string, Min: number?, Max: number?,
	Default: number?, Step: number?, Enabled: boolean?, description: string?,
})
	local c = config :: any
	c.LayoutOrder = self:_nextOrder()
	return self:_addToContent(Slider.new(c), c)
end

function Groupbox:AddTextbox(config: {
	Label: string?, Placeholder: string?, Default: string?,
	MaxLength: number?, ClearOnFocus: boolean?, Enabled: boolean?, description: string?,
})
	local c = config :: any
	c.LayoutOrder = self:_nextOrder()
	return self:_addToContent(Textbox.new(c), c)
end

function Groupbox:AddKeybind(config: {
	Label: string, Default: Enum.KeyCode?,
	Blacklist: { any }?, Enabled: boolean?, description: string?,
})
	local c = config :: any
	c.LayoutOrder = self:_nextOrder()
	return self:_addToContent(Keybind.new(c), c)
end

function Groupbox:AddDropdown(config: {
	Label: string?, Options: { any }, MultiSelect: boolean?,
	Default: any?, Placeholder: string?, Enabled: boolean?, description: string?,
})
	local c = config :: any
	c.LayoutOrder   = self:_nextOrder()
	c.OverlayParent = self._gui   -- wired internally, never exposed to caller
	return self:_addToContent(Dropdown.new(c), c)
end

function Groupbox:AddColorPicker(config: {
	Label: string, Default: Color3?, ShowAlpha: boolean?,
	Flag: string?, Risky: boolean?, Enabled: boolean?, description: string?,
})
	local c = config :: any
	c.LayoutOrder   = self:_nextOrder()
	c.OverlayParent = self._gui
	c.Canvas        = self._canvas
	return self:_addToContent(ColorPicker.new(c), c)
end

-- ── Lifecycle ─────────────────────────────────────────────────────────────

function Groupbox:GetFrame(): Frame
	return self._frame
end

function Groupbox:Destroy()
	self._maid:Destroy()
end

return Groupbox
