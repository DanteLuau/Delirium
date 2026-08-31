--!strict

local Theme = require(script.Parent.Parent.Theme)

export type DescriptionConfig = {
	Title:       string?,
	Description: string,
	LayoutOrder: number?,
}

type DescriptionImpl = {
	SetTitle:       (self: DescriptionImpl, text: string)  -> (),
	SetDescription: (self: DescriptionImpl, text: string)  -> (),
	GetFrame:       (self: DescriptionImpl)                -> Frame,
	Destroy:        (self: DescriptionImpl)                -> (),
	_frame:  Frame,
	_title:  TextLabel,
	_body:   TextLabel,
}

local Description = {} :: { __index: any }
Description.__index = Description

function Description.new(config: DescriptionConfig): DescriptionImpl
	local self = setmetatable({}, Description) :: DescriptionImpl

	-- Root container — height driven by children
	local frame                  = Instance.new("Frame")
	frame.Name                   = "Description"
	frame.AutomaticSize          = Enum.AutomaticSize.Y
	frame.Size                   = UDim2.new(1, 0, 0, 0)
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel        = 0
	frame.LayoutOrder            = config.LayoutOrder or 0
	self._frame                  = frame

	local pad            = Instance.new("UIPadding")
	pad.PaddingLeft      = UDim.new(0, Theme.Spacing.M)
	pad.PaddingRight     = UDim.new(0, Theme.Spacing.M)
	pad.PaddingTop       = UDim.new(0, Theme.Spacing.XS)
	pad.Parent           = frame

	local layout               = Instance.new("UIListLayout")
	layout.FillDirection       = Enum.FillDirection.Vertical
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	layout.SortOrder           = Enum.SortOrder.LayoutOrder
	layout.Padding             = UDim.new(0, Theme.Spacing.XS)
	layout.Parent              = frame

	-- Optional title row
	local hasTitle = config.Title ~= nil and config.Title ~= ""

	local titleLabel                  = Instance.new("TextLabel")
	titleLabel.Name                   = "Title"
	titleLabel.LayoutOrder            = 0
	titleLabel.AutomaticSize          = Enum.AutomaticSize.Y
	titleLabel.Size                   = UDim2.new(1, 0, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font                   = Theme.Font.Subtitle
	titleLabel.Text                   = config.Title or ""
	titleLabel.TextSize               = Theme.TextSize.Subtitle
	titleLabel.TextColor3             = Theme.Colors.TextPrimary
	titleLabel.TextXAlignment         = Enum.TextXAlignment.Left
	titleLabel.TextWrapped            = true
	titleLabel.Visible                = hasTitle
	titleLabel.Parent                 = frame
	self._title                       = titleLabel

	-- Description body
	local bodyLabel                   = Instance.new("TextLabel")
	bodyLabel.Name                    = "Body"
	bodyLabel.LayoutOrder             = 1
	bodyLabel.AutomaticSize           = Enum.AutomaticSize.Y
	bodyLabel.Size                    = UDim2.new(1, 0, 0, 0)
	bodyLabel.BackgroundTransparency  = 1
	bodyLabel.Font                    = Theme.Font.Body
	bodyLabel.Text                    = config.Description
	bodyLabel.TextSize                = Theme.TextSize.Small
	bodyLabel.TextColor3              = Theme.Colors.TextSecondary
	bodyLabel.TextXAlignment          = Enum.TextXAlignment.Left
	bodyLabel.TextWrapped             = true
	bodyLabel.RichText                = true
	bodyLabel.Parent                  = frame
	self._body                        = bodyLabel

	-- Bottom spacer so content below has breathing room
	local spacer             = Instance.new("Frame")
	spacer.Name              = "Spacer"
	spacer.LayoutOrder       = 2
	spacer.BackgroundTransparency = 1
	spacer.BorderSizePixel   = 0
	spacer.Size              = UDim2.fromOffset(0, Theme.Spacing.XL)
	spacer.Parent            = frame

	return self
end

function Description:SetTitle(text: string)
	self._title.Text    = text
	self._title.Visible = text ~= ""
end

function Description:SetDescription(text: string)
	self._body.Text = text
end

function Description:GetFrame(): Frame
	return self._frame
end

function Description:Destroy()
	if self._frame and self._frame.Parent then
		self._frame:Destroy()
	end
end

return Description
