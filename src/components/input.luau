--!strict

-- Delirium UI Library
-- input.luau — Rayfield Gen2 style text input element.
-- Standard row height, left-aligned title (+ optional description),
-- right-aligned pill container with animated dynamic width hugging (constants.pillResizeInfo),
-- focus animations, optional numeric mode with expression parsing, and flag persistence.

local constants = require(script.Parent.Parent.utility.constants)
local tween     = require(script.Parent.Parent.utility.tween)
local flags     = require(script.Parent.Parent.utility.flags)
local runtime   = require(script.Parent.Parent.utility.runtime)
local element   = require(script.Parent.Parent.utility.element)
local themeUtil   = require(script.Parent.Parent.utility.theme)
local variables   = require(script.Parent.Parent.utility.variables)

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

-- Parse simple math expressions like "5^3" -> 125, falls back to tonumber
local function parseExp(text: string): number?
	local a, b = text:match("^([%d%.%-]+)%^([%d%.%-]+)$")
	if a and b then
		local na, nb = tonumber(a), tonumber(b)
		if na and nb then
			return na ^ nb
		end
	end
	return tonumber(text)
end

function Input.new(props: InputProps, theme: { [string]: any }, parent: Instance): Input
	local name         = props.name or "Input"
	local desc         = props.description or ""
	local flagKey      = props.flag
	local placeholder  = props.placeholder or "Enter text..."
	local isNumeric    = props.numeric == true
	local clearOnFocus = props.clearOnFocus == true
	local enterOnly    = props.enterOnly == true
	local callback     = props.callback
	local hasDesc      = desc ~= ""

	local initValue: string
	if flagKey and flags:Get(flagKey) ~= nil then
		initValue = tostring(flags:Get(flagKey))
	else
		initValue = props.value or ""
	end

	local frame, stroke, gradient = element.makeFrame("Input_" .. name, theme, parent, constants.elementHeight)

	-- ── Left Side: Title ──────────────────────────────────────────────────
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
	titleLabel.FontFace               = theme.Font or Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium)
	titleLabel.TextXAlignment         = Enum.TextXAlignment.Left
	titleLabel.TextYAlignment         = Enum.TextYAlignment.Center
	titleLabel.TextTruncate           = Enum.TextTruncate.AtEnd
	titleLabel.Parent                 = textContainer

	-- ── Right Side: Rayfield-style hugging Pill ───────────────────────────
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

	local pillCorner = Instance.new("UICorner")
	pillCorner.CornerRadius = UDim.new(1, 0) -- Full pill curve
	pillCorner.Parent       = pill

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
	textBox.FontFace               = theme.Font or Font.new("rbxasset://fonts/families/GothamSSm.json")
	textBox.TextXAlignment         = Enum.TextXAlignment.Center
	textBox.TextTruncate           = Enum.TextTruncate.AtEnd
	textBox.ClearTextOnFocus       = clearOnFocus
	textBox.TextTransparency       = 0.4 -- Muted when not typing (Rayfield feel)
	textBox.BorderSizePixel        = 0
	textBox.ZIndex                 = 3
	textBox.Parent                 = pill

	-- ── Self Instance ─────────────────────────────────────────────────────
	local self = setmetatable({}, Input) :: Input
	self.value  = initValue
	self._frame = frame
	;(self :: any)._textBox     = textBox
	;(self :: any)._pill        = pill
	;(self :: any)._pillStroke  = pillStroke
	;(self :: any)._stroke      = stroke
	;(self :: any)._theme       = theme
	;(self :: any)._flag        = flagKey
	;(self :: any)._callback    = callback
	;(self :: any)._numeric     = isNumeric
	;(self :: any)._placeholder = placeholder

	-- ── Dynamic Pill Width Hugging (Utility Animation) ────────────────────
	local function sizePill(animate: boolean)
		local shown = if textBox.Text ~= "" then textBox.Text else placeholder
		local txtWidth = runtime.textService:GetTextSize(
			shown,
			12,
			Enum.Font.GothamMedium,
			Vector2.new(10000, 10000)
		).X

		local frameW = frame.AbsoluteSize.X
		local isNarrow = frameW > 0 and frameW < 380
		-- In split view / narrow column, adjust max size so it doesn't crowd out the title
		local maxW = if isNarrow then math.clamp(math.floor(frameW * 0.44), 65, 120) else 220
		local minW = if isNarrow then 52 else 70
		local targetWidth = math.clamp(math.floor(txtWidth + 24), minW, maxW)

		tween.resizePill(pill, UDim2.fromOffset(targetWidth, 26), animate)
		textContainer.Size = UDim2.new(1, -(targetWidth + 28), 1, -8)
	end
	;(self :: any)._sizePill = sizePill
	sizePill(false)

	frame:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		sizePill(false)
	end)

	-- ── Interactivity & Focus Animations ──────────────────────────────────
	local hovering = false

	-- Hover listener
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
			tween.fire(stroke, constants.tweenFast, {
				Color = theme.ElementStroke or Color3.fromHex("#2b2b2b"),
			})
			tween.fire(pillStroke, constants.tweenFast, {
				Color = theme.ElementStroke or Color3.fromHex("#2b2b2b"),
				Transparency = 0.5,
			})
		end
	end)

	-- Click on frame to focus box
	hitBtn.MouseButton1Click:Connect(function()
		textBox:CaptureFocus()
	end)

	-- Text changed listener (animates pill width as text changes)
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

	-- Focus In: opaque text, accent strokes
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

	-- Focus Out: commit, persist, animate back
	textBox.FocusLost:Connect(function(enterPressed)
		tween.fire(textBox, constants.tweenFocus, { TextTransparency = 0.4 })

		local raw = textBox.Text
		if isNumeric then
			local n = parseExp(raw)
			if n then
				raw = tostring(n)
			else
				raw = self.value
			end
			textBox.Text = raw
		end

		local isMobile = runtime.userInputService.TouchEnabled and not runtime.userInputService.KeyboardEnabled
		local skipCallback = if enterOnly and not isMobile then not enterPressed else false
		self:Set(raw, skipCallback)

		tween.fire(pillStroke, constants.tweenFast, {
			Color = if hovering
				then (theme.AccentColor or Color3.fromHex("#4cc2ff"))
				else (theme.ElementStroke or Color3.fromHex("#2b2b2b")),
			Transparency = 0.5,
		})
		tween.fire(stroke, constants.tweenFast, {
			Color = if hovering
				then (theme.ElementStrokeHover or theme.AccentColor or Color3.fromHex("#4cc2ff"))
				else (theme.ElementStroke or Color3.fromHex("#2b2b2b")),
		})
	end)

	-- ── Theme Subscription ────────────────────────────────────────────────
	;(self :: any)._themeUnsub = themeUtil.subscribe(function(t)
		self._theme = t
		theme = t
		titleLabel.TextColor3 = t.ContentColor or Color3.fromHex("#ffffff")
		titleLabel.FontFace   = t.Font or constants.DEFAULT_FONT_MEDIUM
		pill.BackgroundColor3       = t.FieldBackground or Color3.fromRGB(255, 255, 255)
		pill.BackgroundTransparency = t.FieldTransparency or 0.90
		pillStroke.Color            = t.ElementStroke or Color3.fromHex("#2b2b2b")
		stroke.Color                = t.ElementStroke or Color3.fromHex("#2b2b2b")
		textBox.PlaceholderColor3   = t.PlaceholderColor or Color3.fromHex("#9d9d9d")
		textBox.TextColor3          = t.ContentColor or Color3.fromHex("#ffffff")
		textBox.FontFace            = t.Font or constants.DEFAULT_FONT
		gradient.Color              = t.ElementGradient or ColorSequence.new(Color3.fromRGB(28, 24, 44))
	end, frame)

	return self
end

function Input:Set(value: string, skipCallback: boolean?)
	local textBox: TextBox = (self :: any)._textBox
	local flagKey          = (self :: any)._flag
	local callback         = (self :: any)._callback

	self.value = value
	if textBox.Text ~= value then
		textBox.Text = value
	end

	local sizePill = (self :: any)._sizePill
	if sizePill then
		sizePill(true)
	end

	if flagKey then
		flags:Set(flagKey, value)
	end
	if not skipCallback and callback then
		task.spawn(callback, value)
	end
end

function Input:Destroy()
	local s = (self :: any)
	if s._themeUnsub then s._themeUnsub() end
	if s._descriptor then s._descriptor:Destroy() end
	self._frame:Destroy()
end

return Input
