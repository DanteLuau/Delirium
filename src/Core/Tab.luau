--!strict
-- Tab — a named content pane created by Window:AddTab().
-- Mirrors Window's Add* API so switching over is a one-word change.

local Maid       = require(script.Parent.Parent.Utils.Maid)
local Theme      = require(script.Parent.Parent.Theme)
local Components = require(script.Parent.Parent.Components)
local Groupbox   = require(script.Parent.Parent.Components.Groupbox)

-- ── Types ──────────────────────────────────────────────────────────────────

export type TabImpl = {
	-- public Add* methods (identical surface to Window)
	AddButton:      (self: TabImpl, config: any) -> any,
	AddToggle:      (self: TabImpl, config: any) -> any,
	AddSlider:      (self: TabImpl, config: any) -> any,
	AddTextbox:     (self: TabImpl, config: any) -> any,
	AddKeybind:     (self: TabImpl, config: any) -> any,
	AddDropdown:    (self: TabImpl, config: any) -> any,
	AddColorPicker: (self: TabImpl, config: any) -> any,
	AddLabel:       (self: TabImpl, text: string, color: Color3?) -> any,
	AddDescription: (self: TabImpl, config: any) -> any,
	AddDivider:     (self: TabImpl, text: string?) -> any,
	-- groupbox factory
	AddGroupbox: (self: TabImpl, titleA: string, titleB: string?) -> any,
	-- internals
	_maid:        any,
	_content:     ScrollingFrame,
	_gui:         ScreenGui,
	_canvas:      Frame?,
	_layoutOrder: number,
}

-- ── Class ──────────────────────────────────────────────────────────────────

local Tab = {} :: { __index: any }
Tab.__index = Tab

--[[
	Tab.new(pane, gui, windowMaid)

	pane        — the ScrollingFrame this tab owns
	gui         — the ScreenGui root (forwarded to Dropdown as OverlayParent)
	windowMaid  — the parent window's maid; owns this tab's maid so
	              destroying the window cascades cleanup into all tabs
]]
function Tab.new(pane: ScrollingFrame, gui: ScreenGui, windowMaid: any, canvas: Frame?): TabImpl
	local self        = setmetatable({}, Tab) :: TabImpl
	self._maid        = Maid.new()
	windowMaid:GiveTask(self._maid)  -- cascade: window destroy → tab destroy
	self._content     = pane
	self._gui         = gui
	self._canvas      = canvas
	self._layoutOrder = 0
	return self
end

-- ── Internal helpers ───────────────────────────────────────────────────────

function Tab:_nextOrder(): number
	self._layoutOrder += 1
	return self._layoutOrder
end

--[[
	_addToContent — identical logic to Window:_addToContent.
	Supports the optional `description` key for inline sub-labels.
	Dropdown list overflows; ClipsDescendants = false on wrapper lets it.
]]
function Tab:_addToContent(comp: any, config: any?): any
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
		wrapper.Parent                 = self._content

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

		local descPad        = Instance.new("UIPadding")
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
		comp:GetFrame().Parent = self._content
	end

	self._maid:GiveTask(comp)
	return comp
end

-- ── Public Add* API ────────────────────────────────────────────────────────

function Tab:AddButton(config: {
	Label: string, Variant: number?, Enabled: boolean?, description: string?,
})
	local c = config :: any
	c.LayoutOrder = self:_nextOrder()
	return self:_addToContent(Components.Button.new(c), c)
end

function Tab:AddToggle(config: {
	Label: string, Icon: string?, Default: boolean?, Enabled: boolean?, description: string?,
})
	local c = config :: any
	c.LayoutOrder = self:_nextOrder()
	return self:_addToContent(Components.Toggle.new(c), c)
end

function Tab:AddLabel(text: string, color: Color3?)
	local lbl = Components.Label.new({
		Text        = text,
		Color       = color,
		LayoutOrder = self:_nextOrder(),
	})
	return self:_addToContent(lbl, nil)
end

function Tab:AddDescription(config: { Title: string?, Description: string })
	local c = config :: any
	c.LayoutOrder = self:_nextOrder()
	local desc = Components.Description.new(c)
	desc:GetFrame().Parent = self._content
	self._maid:GiveTask(desc)
	return desc
end

function Tab:AddDivider(text: string?)
	local div = Components.Divider.new({
		Text        = text,
		LayoutOrder = self:_nextOrder(),
	})
	return self:_addToContent(div, nil)
end

function Tab:AddSlider(config: {
	Label: string, Min: number?, Max: number?,
	Default: number?, Step: number?, Enabled: boolean?, description: string?,
})
	local c = config :: any
	c.LayoutOrder = self:_nextOrder()
	return self:_addToContent(Components.Slider.new(c), c)
end

function Tab:AddTextbox(config: {
	Label: string?, Placeholder: string?, Default: string?,
	MaxLength: number?, ClearOnFocus: boolean?, Enabled: boolean?, description: string?,
})
	local c = config :: any
	c.LayoutOrder = self:_nextOrder()
	return self:_addToContent(Components.Textbox.new(c), c)
end

function Tab:AddKeybind(config: {
	Label: string, Default: Enum.KeyCode?,
	Blacklist: { any }?, Enabled: boolean?, description: string?,
})
	local c = config :: any
	c.LayoutOrder = self:_nextOrder()
	return self:_addToContent(Components.Keybind.new(c), c)
end

function Tab:AddDropdown(config: {
	Label: string?, Options: { any }, MultiSelect: boolean?,
	Default: any?, Placeholder: string?, Enabled: boolean?, description: string?,
})
	local c = config :: any
	c.LayoutOrder   = self:_nextOrder()
	return self:_addToContent(Components.Dropdown.new(c), c)
end

function Tab:AddColorPicker(config: {
	Label: string, Default: Color3?, ShowAlpha: boolean?,
	Flag: string?, Risky: boolean?, Enabled: boolean?, description: string?,
})
	local c = config :: any
	c.LayoutOrder   = self:_nextOrder()
	c.OverlayParent = self._gui
	c.Canvas        = self._canvas
	return self:_addToContent(Components.ColorPicker.new(c), c)
end

-- ── Groupbox factory ─────────────────────────────────────────────────────────

--[[
	Tab:AddGroupbox(titleA, titleB?)

	Single column  — returns one  GroupboxImpl
	Two columns    — returns two  GroupboxImpl (left, right)

	Two-column layout: a transparent wrapper frame holds both boxes side-by-side
	with UDim2 relative sizing; wrapper AutomaticSize Y grows to the taller child.
	No UIListLayout on the wrapper — children are positioned, not stacked.
]]
function Tab:AddGroupbox(titleA: string, titleB: string?)
	if titleB then
		-- ── Two-column ──────────────────────────────────────────────────────
		local GAP = Theme.Spacing.XS  -- 4 px gutter between columns

		local wrapper                  = Instance.new("Frame")
		wrapper.Name                   = "GroupboxRow"
		wrapper.Size                   = UDim2.new(1, 0, 0, 0)
		wrapper.AutomaticSize          = Enum.AutomaticSize.Y
		wrapper.BackgroundTransparency = 1
		wrapper.BorderSizePixel        = 0
		wrapper.ClipsDescendants       = false
		wrapper.LayoutOrder            = self:_nextOrder()
		wrapper.Parent                 = self._content
		self._maid:GiveTask(wrapper)

		local leftBox  = Groupbox.new(titleA, self._gui, self._maid, self._canvas)
		local rightBox = Groupbox.new(titleB, self._gui, self._maid, self._canvas)

		local lf          = leftBox:GetFrame()
		lf.AnchorPoint    = Vector2.new(0, 0)
		lf.Position       = UDim2.new(0, 0, 0, 0)
		lf.Size           = UDim2.new(0.5, -(GAP // 2 + GAP % 2), 0, 0)  -- floor half-gap
		lf.Parent         = wrapper

		local rf          = rightBox:GetFrame()
		rf.AnchorPoint    = Vector2.new(0, 0)
		rf.Position       = UDim2.new(0.5, GAP // 2 + GAP % 2, 0, 0)    -- ceil half-gap
		rf.Size           = UDim2.new(0.5, -(GAP // 2 + GAP % 2), 0, 0)
		rf.Parent         = wrapper

		return leftBox, rightBox
	else
		-- ── Single column ───────────────────────────────────────────────────
		local box = Groupbox.new(titleA, self._gui, self._maid, self._canvas)
		local f   = box:GetFrame()
		f.LayoutOrder = self:_nextOrder()
		f.Parent      = self._content
		return box
	end
end

return Tab
