--!strict

local Theme = require(script.Parent.Parent.Theme)

export type LabelConfig = {
	Text: string,
	Color: Color3?,
	LayoutOrder: number?,
}

type LabelImpl = {
	SetText: (self: LabelImpl, text: string) -> (),
	GetFrame: (self: LabelImpl) -> Frame,
	Destroy: (self: LabelImpl) -> (),
	_frame: Frame,
	_label: TextLabel,
}

local Label = {} :: { __index: any }
Label.__index = Label

function Label.new(config: LabelConfig): LabelImpl
	local self  = setmetatable({}, Label) :: LabelImpl

	local frame              = Instance.new("Frame")
	frame.Name               = "Label"
	frame.Size               = UDim2.new(1, 0, 0, 24)
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel    = 0
	frame.LayoutOrder        = config.LayoutOrder or 0
	self._frame              = frame

	local pad        = Instance.new("UIPadding")
	pad.PaddingLeft  = UDim.new(0, Theme.Spacing.M)
	pad.PaddingRight = UDim.new(0, Theme.Spacing.M)
	pad.Parent       = frame

	local label               = Instance.new("TextLabel")
	label.Name                = "Text"
	label.Size                = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font                = Theme.Font.Body
	label.Text                = config.Text
	label.TextSize            = Theme.TextSize.Small
	label.TextColor3          = config.Color or Theme.Colors.TextSecondary
	label.TextXAlignment      = Enum.TextXAlignment.Left
	label.TextWrapped         = true
	label.Parent              = frame
	self._label               = label

	return self
end

function Label:SetText(text: string)
	self._label.Text = text
end

function Label:GetFrame(): Frame
	return self._frame
end

function Label:Destroy()
	if self._frame and self._frame.Parent then
		self._frame:Destroy()
	end
end

return Label
