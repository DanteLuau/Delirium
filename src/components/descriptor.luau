--!strict

-- Delirium UI Library
-- descriptor.luau — Rayfield Gen2 style description sub-element.
-- Placed directly below the parent element in the scrolling column with
-- soft muted text, word wrapping, and bottom spacing.

local constants = require(script.Parent.Parent.utility.constants)
local themeUtil = require(script.Parent.Parent.utility.theme)

export type Descriptor = {
	_frame:  Frame,
	Destroy: (self: Descriptor) -> (),
}

local Descriptor = {}
Descriptor.__index = Descriptor

function Descriptor.new(parent: Instance, text: string, theme: { [string]: any }, layoutOrder: number?): Descriptor
	local frame = Instance.new("Frame")
	frame.Name                   = "Descriptor"
	frame.Size                   = UDim2.new(1, 0, 0, 0)
	frame.AutomaticSize          = Enum.AutomaticSize.Y
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel        = 0
	frame.LayoutOrder            = layoutOrder or 0
	frame.Parent                 = parent

	local layout = Instance.new("UIListLayout")
	layout.FillDirection     = Enum.FillDirection.Vertical
	layout.VerticalAlignment = Enum.VerticalAlignment.Top
	layout.SortOrder         = Enum.SortOrder.LayoutOrder
	layout.Padding           = UDim.new(0, 0)
	layout.Parent            = frame

	local pad = Instance.new("UIPadding")
	pad.PaddingLeft   = UDim.new(0, 14)
	pad.PaddingRight  = UDim.new(0, 14)
	pad.PaddingTop    = UDim.new(0, 1)
	pad.PaddingBottom = UDim.new(0, 6)
	pad.Parent        = frame

	local label = Instance.new("TextLabel")
	label.Name                   = "Text"
	label.Size                   = UDim2.new(1, 0, 0, 0)
	label.AutomaticSize          = Enum.AutomaticSize.Y
	label.BackgroundTransparency = 1
	label.Text                   = text
	label.TextColor3             = theme.PlaceholderColor or Color3.fromHex("#8a8a92")
	label.TextTransparency       = 0.35
	label.TextSize               = 11
	label.FontFace               = theme.Font or Font.new("rbxasset://fonts/families/GothamSSm.json")
	label.TextXAlignment         = Enum.TextXAlignment.Left
	label.TextYAlignment         = Enum.TextYAlignment.Top
	label.TextWrapped            = true
	label.RichText               = true
	label.Parent                 = frame

	local self = setmetatable({}, Descriptor) :: any
	self._frame = frame
	self._label = label

	self._themeUnsub = themeUtil.subscribe(function(t)
		label.TextColor3 = t.PlaceholderColor or Color3.fromHex("#8a8a92")
		label.FontFace   = t.Font or constants.DEFAULT_FONT
	end)

	return self
end

function Descriptor:Destroy()
	local s = self :: any
	if s._themeUnsub then s._themeUnsub() end
	s._frame:Destroy()
end

return Descriptor
