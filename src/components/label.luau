--!strict

-- Delirium UI Library
-- label.luau — Static informational text element.
-- Renders a read-only text block inside a tab. Supports rich text.

local constants = require(script.Parent.Parent.utility.constants)
local themeUtil = require(script.Parent.Parent.utility.theme)

export type LabelProps = {
	text:      string?,
	richText:  boolean?,
	textSize:  number?,
	textColor: Color3?,
}

export type Label = {
	_frame:   Frame,
	Set:     (self: Label, text: string) -> (),
	Destroy: (self: Label) -> (),
}

local Label = {}
Label.__index = Label

function Label.new(props: LabelProps, theme: { [string]: any }, parent: Instance): Label
	local text      = props.text or ""
	local richText  = props.richText ~= false and true  -- default true
	local textSize  = props.textSize or 13
	local textColor = props.textColor or theme.ContentColor or Color3.fromRGB(220, 215, 240)

	local container = Instance.new("Frame")
	container.Name                   = "Label"
	container.BackgroundTransparency = 1
	container.Size                   = UDim2.new(1, 0, 0, 0)
	container.AutomaticSize          = Enum.AutomaticSize.Y
	container.LayoutOrder            = 0
	container.Parent                 = parent

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft   = UDim.new(0, 4)
	padding.PaddingRight  = UDim.new(0, 4)
	padding.PaddingTop    = UDim.new(0, 4)
	padding.PaddingBottom = UDim.new(0, 4)
	padding.Parent        = container

	local label = Instance.new("TextLabel")
	label.Name                   = "Text"
	label.Size                   = UDim2.new(1, 0, 0, 0)
	label.AutomaticSize          = Enum.AutomaticSize.Y
	label.BackgroundTransparency = 1
	label.Text                   = text
	label.RichText               = richText
	label.TextColor3             = textColor
	label.TextSize               = textSize
	label.FontFace               = theme.Font or Font.new("rbxasset://fonts/families/GothamSSm.json")
	label.TextWrapped            = true
	label.TextXAlignment         = Enum.TextXAlignment.Left
	label.Parent                 = container

	local self = setmetatable({}, Label) :: Label
	self._frame = container
	;(self :: any)._label = label
	;(self :: any)._themeUnsub = themeUtil.subscribe(function(t)
		label.TextColor3 = props.textColor or t.ContentColor or Color3.fromRGB(220, 215, 240)
		label.FontFace = t.Font or constants.DEFAULT_FONT
	end)
	return self
end

function Label:Set(text: string)
	local label: TextLabel = (self :: any)._label
	label.Text = text
end

function Label:Destroy()
	local s = (self :: any)
	if s._themeUnsub then s._themeUnsub() end
	self._frame:Destroy()
end

return Label
