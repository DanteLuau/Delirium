--!strict

local Theme = require(script.Parent.Parent.Theme)

export type DividerConfig = {
	Text: string?,
	LayoutOrder: number?,
}

type DividerImpl = {
	GetFrame: (self: DividerImpl) -> Frame,
	Destroy: (self: DividerImpl) -> (),
	_frame: Frame,
}

local Divider = {} :: { __index: any }
Divider.__index = Divider

function Divider.new(config: DividerConfig?): DividerImpl
	local cfg   = config or {}
	local self  = setmetatable({}, Divider) :: DividerImpl

	local frame              = Instance.new("Frame")
	frame.Name               = "Divider"
	frame.Size               = UDim2.new(1, 0, 0, 20)
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel    = 0
	frame.LayoutOrder        = cfg.LayoutOrder or 0
	self._frame              = frame

	local pad        = Instance.new("UIPadding")
	pad.PaddingLeft  = UDim.new(0, Theme.Spacing.M)
	pad.PaddingRight = UDim.new(0, Theme.Spacing.M)
	pad.Parent       = frame

	-- Horizontal rule — always full width, vertically centered
	local line             = Instance.new("Frame")
	line.Name              = "Line"
	line.Size              = UDim2.new(1, 0, 0, 1)
	line.Position          = UDim2.fromScale(0, 0.5)
	line.BackgroundColor3  = Theme.Colors.Border
	line.BorderSizePixel   = 0
	line.Parent            = frame

	local text = cfg.Text
	if text and #text > 0 then
		local lbl                    = Instance.new("TextLabel")
		lbl.Name                     = "Text"
		lbl.AutomaticSize            = Enum.AutomaticSize.X
		lbl.Size                     = UDim2.new(0, 0, 1, 0)
		lbl.AnchorPoint              = Vector2.new(0.5, 0)
		lbl.Position                 = UDim2.fromScale(0.5, 0)
		lbl.BackgroundColor3         = Theme.Colors.Surface
		lbl.BorderSizePixel          = 0
		lbl.Font                     = Theme.Font.Body
		lbl.Text                     = text
		lbl.TextSize                 = Theme.TextSize.Small
		lbl.TextColor3               = Theme.Colors.TextSecondary
		local textPad                = Instance.new("UIPadding")
		textPad.PaddingLeft          = UDim.new(0, Theme.Spacing.XS)
		textPad.PaddingRight         = UDim.new(0, Theme.Spacing.XS)
		textPad.Parent               = lbl
		lbl.Parent                   = frame
	end

	return self
end

function Divider:GetFrame(): Frame
	return self._frame
end

function Divider:Destroy()
	if self._frame and self._frame.Parent then
		self._frame:Destroy()
	end
end

return Divider
