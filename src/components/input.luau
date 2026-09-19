--!strict

-- Delirium UI Library
-- input.luau — Rayfield Gen2 style text input element.
-- Standard row height, left-aligned title, right-aligned dynamic hugging pill.

local constants = require(script.Parent.Parent.utility.constants)
local tween     = require(script.Parent.Parent.utility.tween)
local flags     = require(script.Parent.Parent.utility.flags)
local runtime   = require(script.Parent.Parent.utility.runtime)
local element   = require(script.Parent.Parent.utility.element)
local themeUtil = require(script.Parent.Parent.utility.theme)
local variables = require(script.Parent.Parent.utility.variables)

export type InputProps = {
	name:         string?,
	description:  string?,
	flag:         string?,
	value:        string?,
	placeholder:  string?,
	numeric:      boolean?,
	clearOnFocus: boolean?,
	enterOnly:    boolean?,
	callback:     ((value: string) -> ())?,
}

export type Input = {
	value:   string,
	_frame:  Frame,
	Set:     (self: Input, value: string, skipCallback: boolean?) -> (),
	Destroy: (self: Input) -> (),
}

local Input = {}
Input.__index = Input

local function parseExp(text: string): number?
	local a, b = text:match("^([%d%.%-]+)%^([%d%.%-]+)$")
	if a and b then
		local na, nb = tonumber(a), tonumber(b)
		if na and nb then return na ^ nb end
	end
	return tonumber(text)
end

function Input.new(props: InputProps, theme: { [string]: any }, parent: Instance): Input
	local name         = props.name or "Input"
	local flagKey      = props.flag
	local placeholder  = props.placeholder or "Enter text..."
	local isNumeric    = props.numeric == true
	local clearOnFocus = props.clearOnFocus == true
	local enterOnly    = props.enterOnly == true
	local callback     = props.callback

	local initValue: string = if flagKey and flags:Get(flagKey) ~= nil
		then tostring(flags:Get(flagKey))
		else (props.value or "")

	local frame, stroke, gradient = element.makeFrame("Input_" .. name, theme, parent, constants.elementHeight)

	-- Left Title Container
	local textContainer = Instance.new("Frame")
	textContainer.Name                   = "TextContainer"
	textContainer.Position               = UDim2.new(0, 12, 0.5, 0)
	textContainer.AnchorPoint            = Vector2.new(0, 0.5)
	textContainer.Size                   = UDim2.new(1, -98, 1, -8)
	textContainer.BackgroundTransparency = 1
	textContainer.BorderSizePixel        = 0
	textContainer.Parent                 = frame

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name                   = "Title"
	titleLabel.Size                   = UDim2.fromScale(1, 1)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text                   = name
	titleLabel.TextColor3             = theme.ContentColor or Color3.fromHex("#ffffff")
	titleLabel.TextSize               = 13
	titleLabel.FontFace               = theme.Font or constants.DEFAULT_FONT_MEDIUM
	titleLabel.TextXAlignment         = Enum.TextXAlignment.Left
	titleLabel.TextYAlignment         = Enum.TextYAlignment.Center
	titleLabel.TextTruncate           = Enum.TextTruncate.AtEnd
	titleLabel.Parent                 = textContainer

	-- Right Pill
	local pill = Instance.new("Frame")
	pill.Name                   = "FieldPill"
	pill.AnchorPoint            = Vector2.new(1, 0.5)
	pill.Position               = UDim2.new(1, -12, 0.5, 0)
	pill.Size                   = UDim2.fromOffset(80, 26)
	pill.BackgroundColor3       = theme.FieldBackground or Color3.fromRGB(255, 255, 255)
	pill.BackgroundTransparency = theme.FieldTransparency or 0.90
	pill.BorderSizePixel        = 0
	pill.ZIndex                 = 2
	pill.Parent                 = frame
	do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1, 0); c.Parent = pill end

	local pillStroke = Instance.new("UIStroke")
	pillStroke.Color           = theme.ElementStroke or Color3.fromHex("#2b2b2b")
	pillStroke.Thickness       = 1
	pillStroke.Transparency    = 0.5
	pillStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	pillStroke.Parent          = pill

	local textBox = Instance.new("TextBox")
	textBox.Name                   = "Box"
	textBox.AnchorPoint            = Vector2.new(0.5, 0.5)
	textBox.Position               = UDim2.fromScale(0.5, 0.5)
	textBox.Size                   = UDim2.new(1, -16, 1, 0)
	textBox.BackgroundTransparency = 1
	textBox.PlaceholderText        = placeholder
	textBox.PlaceholderColor3      = theme.PlaceholderColor or Color3.fromHex("#9d9d9d")
	textBox.Text                   = initValue
	textBox.TextColor3             = theme.ContentColor or Color3.fromHex("#ffffff")
	textBox.TextSize               = 12
	textBox.FontFace               = theme.Font or constants.DEFAULT_FONT
	textBox.TextXAlignment         = Enum.TextXAlignment.Center
	textBox.TextTruncate           = Enum.TextTruncate.AtEnd
	textBox.ClearTextOnFocus       = clearOnFocus
	textBox.TextTransparency       = 0.4
	textBox.BorderSizePixel        = 0
	textBox.ZIndex                 = 3
	textBox.Parent                 = pill

	local self = setmetatable({}, Input) :: Input
	self.value  = initValue
	self._frame = frame

	local s = self :: any
	s._textBox  = textBox
	s._flag     = flagKey
	s._callback = callback

	-- Dynamic Pill Width Hugging
	local function sizePill(animate: boolean)
		local shown = if textBox.Text ~= "" then textBox.Text else placeholder
		local txtWidth = runtime.textService:GetTextSize(
			shown, 12, Enum.Font.GothamMedium, Vector2.new(10000, 10000)
		).X
		local frameW = frame.AbsoluteSize.X
		local isNarrow = frameW > 0 and frameW < 380
		local maxW = if isNarrow then math.clamp(math.floor(frameW * 0.44), 65, 120) else 220
		local minW = if isNarrow then 52 else 70
		local targetWidth = math.clamp(math.floor(txtWidth + 24), minW, maxW)

		tween.resizePill(pill, UDim2.fromOffset(targetWidth, 26), animate)
		textContainer.Size = UDim2.new(1, -(targetWidth + 28), 1, -8)
	end
	s._sizePill = sizePill
	sizePill(false)

	frame:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() sizePill(false) end)

	-- Interaction & Focus
	local hovering = false
	local hitBtn = Instance.new("TextButton")
	hitBtn.Name                   = "Interact"
	hitBtn.Size                   = UDim2.fromScale(1, 1)
	hitBtn.BackgroundTransparency = 1
	hitBtn.Text                   = ""
	hitBtn.AutoButtonColor        = false
	hitBtn.ZIndex                 = 1
	hitBtn.Parent                 = frame

	hitBtn.MouseEnter:Connect(function()
		if variables.settingsOpen then return end
		hovering = true
		tween.fire(stroke, constants.tweenFast, {
			Color = theme.ElementStrokeHover or theme.AccentColor or Color3.fromHex("#4cc2ff"),
		})
		if not textBox:IsFocused() then
			tween.fire(pillStroke, constants.tweenFast, {
				Color = theme.AccentColor or Color3.fromHex("#4cc2ff"),
			})
		end
	end)

	hitBtn.MouseLeave:Connect(function()
		hovering = false
		if not textBox:IsFocused() then
			tween.fire(stroke, constants.tweenFast, { Color = theme.ElementStroke or Color3.fromHex("#2b2b2b") })
			tween.fire(pillStroke, constants.tweenFast, {
				Color = theme.ElementStroke or Color3.fromHex("#2b2b2b"),
				Transparency = 0.5,
			})
		end
	end)

	hitBtn.MouseButton1Click:Connect(function() textBox:CaptureFocus() end)

	textBox:GetPropertyChangedSignal("Text"):Connect(function()
		if isNumeric then
			local cleaned = textBox.Text:gsub("[^%d%.%-eE%^]", "")
			if cleaned ~= textBox.Text then
				textBox.Text = cleaned
				return
			end
		end
		sizePill(true)
	end)

	textBox.Focused:Connect(function()
		tween.fire(textBox, constants.tweenFocus, { TextTransparency = 0 })
		tween.fire(pillStroke, constants.tweenFocus, {
			Color = theme.AccentColor or Color3.fromHex("#4cc2ff"),
			Transparency = 0,
		})
		tween.fire(stroke, constants.tweenFocus, {
			Color = theme.ElementStrokeHover or theme.AccentColor or Color3.fromHex("#4cc2ff"),
		})
	end)

	textBox.FocusLost:Connect(function(enterPressed)
		tween.fire(textBox, constants.tweenFocus, { TextTransparency = 0.4 })
		local raw = textBox.Text
		if isNumeric then
			local n = parseExp(raw)
			raw = if n then tostring(n) else self.value
			textBox.Text = raw
		end

		local isMobile = runtime.userInputService.TouchEnabled and not runtime.userInputService.KeyboardEnabled
		local skip = if enterOnly and not isMobile then not enterPressed else false
		self:Set(raw, skip)

		local strokeColor = if hovering
			then (theme.ElementStrokeHover or theme.AccentColor or Color3.fromHex("#4cc2ff"))
			else (theme.ElementStroke or Color3.fromHex("#2b2b2b"))

		tween.fire(pillStroke, constants.tweenFast, {
			Color = if hovering then (theme.AccentColor or Color3.fromHex("#4cc2ff")) else (theme.ElementStroke or Color3.fromHex("#2b2b2b")),
			Transparency = 0.5,
		})
		tween.fire(stroke, constants.tweenFast, { Color = strokeColor })
	end)

	s._themeUnsub = themeUtil.subscribe(function(t)
		theme = t
		frame.BackgroundTransparency = t.ElementTransparency or 0
		titleLabel.TextColor3       = t.ContentColor or Color3.fromHex("#ffffff")
		titleLabel.FontFace         = t.Font or constants.DEFAULT_FONT_MEDIUM
		pill.BackgroundColor3       = t.FieldBackground or Color3.fromRGB(255, 255, 255)
		pill.BackgroundTransparency = t.FieldTransparency or 0.90
		pillStroke.Color            = t.ElementStroke or Color3.fromHex("#2b2b2b")
		stroke.Color                = t.ElementStroke or Color3.fromHex("#2b2b2b")
		stroke.Transparency         = t.ElementStrokeTransparency or 0
		textBox.PlaceholderColor3   = t.PlaceholderColor or Color3.fromHex("#9d9d9d")
		textBox.TextColor3          = t.ContentColor or Color3.fromHex("#ffffff")
		textBox.FontFace            = t.Font or constants.DEFAULT_FONT
		gradient.Color              = t.ElementGradient or ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromHex("#2e2e2e")),
			ColorSequenceKeypoint.new(1, Color3.fromHex("#181818")),
		})
	end, frame)

	return self
end

function Input:Set(value: string, skipCallback: boolean?)
	local s = self :: any
	local textBox: TextBox = s._textBox
	self.value = value

	if textBox.Text ~= value then textBox.Text = value end
	if s._sizePill then s._sizePill(true) end
	if s._flag then flags:Set(s._flag, value) end
	if not skipCallback and s._callback then task.spawn(s._callback, value) end
end

function Input:Destroy()
	local s = self :: any
	if s._themeUnsub then s._themeUnsub() end
	if s._descriptor then s._descriptor:Destroy() end
	self._frame:Destroy()
end

return Input
