--!strict

-- Delirium UI Library
-- section.luau — Visual divider with optional label text.

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
	local strokeColor = theme.ElementStroke or Color3.fromRGB(50, 42, 80)

	local container = Instance.new("Frame")
	container.Name                   = "Section_" .. name
	container.Size                   = UDim2.new(1, 0, 0, 28)
	container.BackgroundTransparency = 1
	container.LayoutOrder            = 0
	container.Parent                 = parent

	local function makeLine(anchorX: number, posX: number): Frame
		local line = Instance.new("Frame")
		line.AnchorPoint      = Vector2.new(anchorX, 0.5)
		line.Position         = UDim2.fromScale(posX, 0.5)
		line.Size             = UDim2.new(0.5, -8, 0, 1)
		line.BackgroundColor3 = strokeColor
		line.BorderSizePixel  = 0
		line.Parent           = container
		return line
	end

	local lineLeft  = makeLine(0, 0)
	local lineRight = makeLine(1, 1)
	local label: TextLabel? = nil

	if name ~= "" then
		label = Instance.new("TextLabel")
		label.Name                   = "Label"
		label.AnchorPoint            = Vector2.new(0.5, 0.5)
		label.Position               = UDim2.fromScale(0.5, 0.5)
		label.Size                   = UDim2.new(0, 0, 1, 0)
		label.AutomaticSize          = Enum.AutomaticSize.X
		label.BackgroundTransparency = 1
		label.Text                   = name
		label.TextColor3             = theme.ContentColor or Color3.fromRGB(220, 215, 240)
		label.TextSize               = 11
		label.FontFace               = theme.Font or constants.DEFAULT_FONT
		label.TextXAlignment         = Enum.TextXAlignment.Center
		label.Parent                 = container

		local textSize = variables.textService:GetTextSize(
			name, 11, Enum.Font.Gotham, Vector2.new(math.huge, math.huge)
		)
		local half = (textSize.X / 2) + 6
		lineLeft.Size  = UDim2.new(0.5, -half, 0, 1)
		lineRight.Size = UDim2.new(0.5, -half, 0, 1)
	else
		lineLeft.Size     = UDim2.new(1, 0, 0, 1)
		lineRight.Size    = UDim2.new(0, 0, 0, 0)
		lineRight.Visible = false
	end

	local self = setmetatable({}, Section) :: Section
	self._frame = container

	local s = self :: any
	s._themeUnsub = themeUtil.subscribe(function(t)
		local c = t.ElementStroke or Color3.fromRGB(50, 42, 80)
		lineLeft.BackgroundColor3  = c
		lineRight.BackgroundColor3 = c
		if label then
			label.TextColor3 = t.ContentColor or Color3.fromRGB(220, 215, 240)
			label.FontFace   = t.Font or constants.DEFAULT_FONT
		end
	end, container)

	return self
end

function Section:Destroy()
	local s = self :: any
	if s._themeUnsub then s._themeUnsub() end
	self._frame:Destroy()
end

return Section
