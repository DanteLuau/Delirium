--!strict

-- Delirium UI Library
-- section.luau — Visual divider with optional label text.
-- Rendered as a horizontal line + label inside a tab's scroll frame.

local constants = require(script.Parent.Parent.utility.constants)
local variables = require(script.Parent.Parent.utility.variables)
local themeUtil = require(script.Parent.Parent.utility.theme)

export type SectionProps = {
	name: string?,
}

export type Section = {
	_frame:   Frame,
	Destroy:  (self: Section) -> (),
}

local Section = {}
Section.__index = Section

function Section.new(props: SectionProps, theme: { [string]: any }, parent: Instance): Section
	local name = props.name or ""

	-- Container
	local container = Instance.new("Frame")
	container.Name             = "Section_" .. name
	container.Size             = UDim2.new(1, 0, 0, 28)
	container.BackgroundTransparency = 1
	container.LayoutOrder      = 0
	container.Parent           = parent

	-- Left line
	local lineLeft = Instance.new("Frame")
	lineLeft.Name                 = "LineLeft"
	lineLeft.AnchorPoint          = Vector2.new(0, 0.5)
	lineLeft.Position             = UDim2.fromScale(0, 0.5)
	lineLeft.Size                 = UDim2.new(0.5, -8, 0, 1)
	lineLeft.BackgroundColor3     = theme.ElementStroke or Color3.fromRGB(50, 42, 80)
	lineLeft.BorderSizePixel      = 0
	lineLeft.Parent               = container

	-- Right line
	local lineRight = Instance.new("Frame")
	lineRight.Name             = "LineRight"
	lineRight.AnchorPoint      = Vector2.new(1, 0.5)
	lineRight.Position         = UDim2.fromScale(1, 0.5)
	lineRight.Size             = UDim2.new(0.5, -8, 0, 1)
	lineRight.BackgroundColor3 = theme.ElementStroke or Color3.fromRGB(50, 42, 80)
	lineRight.BorderSizePixel  = 0
	lineRight.Parent           = container

	-- Label
	local label: TextLabel? = nil
	if name ~= "" then
		label = Instance.new("TextLabel")
		label.Name                  = "Label"
		label.AnchorPoint           = Vector2.new(0.5, 0.5)
		label.Position              = UDim2.fromScale(0.5, 0.5)
		label.Size                  = UDim2.new(0, 0, 1, 0)
		label.AutomaticSize         = Enum.AutomaticSize.X
		label.BackgroundTransparency = 1
		label.Text                  = name
		label.TextColor3            = theme.ContentColor or Color3.fromRGB(220, 215, 240)
		label.TextSize              = 11
		label.FontFace              = theme.Font or Font.new("rbxasset://fonts/families/GothamSSm.json")
		label.TextXAlignment        = Enum.TextXAlignment.Center
		label.Parent                = container

		-- Adjust line widths to leave room for the text label.
		-- Measured synchronously so the sizes are correct on the first frame.
		local textSize = variables.textService:GetTextSize(
			name, 11, Enum.Font.Gotham, Vector2.new(math.huge, math.huge)
		)
		local half = (textSize.X / 2) + 6
		lineLeft.Size  = UDim2.new(0.5, -half, 0, 1)
		lineRight.Size = UDim2.new(0.5, -half, 0, 1)
	else
		-- Full-width line when no name
		lineLeft.Size  = UDim2.new(1, 0, 0, 1)
		lineRight.Size = UDim2.new(0, 0, 0, 0)
		lineRight.Visible = false
	end

	local self = setmetatable({}, Section) :: Section
	self._frame = container
	;(self :: any)._lineLeft = lineLeft
	;(self :: any)._lineRight = lineRight
	;(self :: any)._label = label
	;(self :: any)._themeUnsub = themeUtil.subscribe(function(t)
		lineLeft.BackgroundColor3 = t.ElementStroke or Color3.fromRGB(50, 42, 80)
		lineRight.BackgroundColor3 = t.ElementStroke or Color3.fromRGB(50, 42, 80)
		if label then
			label.TextColor3 = t.ContentColor or Color3.fromRGB(220, 215, 240)
			label.FontFace = t.Font or Font.new("rbxasset://fonts/families/GothamSSm.json")
		end
	end)
	return self
end

function Section:Destroy()
	local s = (self :: any)
	if s._themeUnsub then s._themeUnsub() end
	self._frame:Destroy()
end

return Section
