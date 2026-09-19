--!strict

-- Delirium UI Library
-- keybind.luau — Rayfield Gen2 style Keybind element.
-- Standard row height, left-aligned title (+ optional description),
-- right-aligned pill button with animated dynamic width hugging (constants.pillResizeInfo),
-- recording mode with animated resize, keyboard + mouse button capture (MB1/MB2/MB3),
-- hold mode support, and flag persistence.

local constants = require(script.Parent.Parent.utility.constants)
local tween     = require(script.Parent.Parent.utility.tween)
local flags     = require(script.Parent.Parent.utility.flags)
local runtime   = require(script.Parent.Parent.utility.runtime)
local element   = require(script.Parent.Parent.utility.element)
local themeUtil   = require(script.Parent.Parent.utility.theme)
local variables   = require(script.Parent.Parent.utility.variables)

export type KeybindProps = {
	name:          string?,
	description:   string?,
	flag:          string?,
	value:         (EnumItem | string)?,
	hold:          boolean?,
	holdThreshold: number?,
	callback:      ((value: any) -> ())?,
	onChanged:     ((key: EnumItem) -> ())?,
}

export type Keybind = {
	value:   EnumItem,
	_frame:  Frame,
	Set:     (self: Keybind, value: EnumItem | string, skipChanged: boolean?) -> (),
	Destroy: (self: Keybind) -> (),
}

local Keybind = {}
Keybind.__index = Keybind

-- Track globally active recording keybind across the library
local activeRecordingKeybind: any = nil

-- Helper to check whether a screen point is inside a GuiObject
local function isInside(pos: Vector2, guiObj: GuiObject): boolean
	local min = guiObj.AbsolutePosition
	local max = min + guiObj.AbsoluteSize
	return pos.X >= min.X and pos.X <= max.X and pos.Y >= min.Y and pos.Y <= max.Y
end

-- Friendly mouse button mapping
local mouseNames: { [EnumItem]: string } = {
	[Enum.UserInputType.MouseButton1] = "MB1",
	[Enum.UserInputType.MouseButton2] = "MB2",
	[Enum.UserInputType.MouseButton3] = "MB3",
}

-- Resolve any input (KeyCode, UserInputType, string) to an EnumItem
local function coerceKey(v: any): EnumItem
	if typeof(v) == "EnumItem" then
		return v
	end
	if type(v) == "string" then
		local ok, item = pcall(function()
			return Enum.KeyCode[v]
		end)
		if ok and item then
			return item
		end
		local mouseOk, button = pcall(function()
			return Enum.UserInputType[v]
		end)
		if mouseOk and button and mouseNames[button] then
			return button
		end
	end
	return Enum.KeyCode.Unknown
end

-- Friendly display name for common keys
local keyOverrides: { [string]: string } = {
	LeftControl  = "L-Ctrl",
	RightControl = "R-Ctrl",
	LeftShift    = "L-Shift",
	RightShift   = "R-Shift",
	LeftAlt      = "L-Alt",
	RightAlt     = "R-Alt",
	Unknown      = "None",
}

local function keyLabel(key: EnumItem): string
	if mouseNames[key] then
		return mouseNames[key]
	end
	local name = key.Name
	return keyOverrides[name] or name
end

function Keybind.new(props: KeybindProps, theme: { [string]: any }, parent: Instance): Keybind
	local name          = props.name or "Keybind"
	local desc          = props.description or ""
	local flagKey       = props.flag
	local hold          = props.hold == true
	local holdThreshold = props.holdThreshold or 0.2
	local callback      = props.callback
	local onChanged     = props.onChanged
	local hasDesc       = desc ~= ""

	local initKey: EnumItem
	if flagKey and flags:Get(flagKey) ~= nil then
		initKey = coerceKey(flags:Get(flagKey))
	else
		initKey = coerceKey(props.value)
	end

	local frame, stroke, gradient = element.makeFrame("Keybind_" .. name, theme, parent, constants.elementHeight)
	frame.Active = true

	-- ── Left Side: Title ──────────────────────────────────────────────────
	local textContainer = Instance.new("Frame")
	textContainer.Name                   = "TextContainer"
	textContainer.Position               = UDim2.new(0, 12, 0.5, 0)
	textContainer.AnchorPoint            = Vector2.new(0, 0.5)
	textContainer.Size                   = UDim2.new(1, -74, 1, -8)
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
	local pill = Instance.new("TextButton")
	pill.Name                   = "Pill"
	pill.AnchorPoint            = Vector2.new(1, 0.5)
	pill.Position               = UDim2.new(1, -12, 0.5, 0)
	pill.Size                   = UDim2.fromOffset(50, 26)
	pill.BackgroundColor3       = theme.FieldBackground or Color3.fromRGB(255, 255, 255)
	pill.BackgroundTransparency = theme.FieldTransparency or 0.90
	pill.BorderSizePixel        = 0
	pill.Text                   = keyLabel(initKey)
	pill.TextColor3             = theme.ContentColor or Color3.fromHex("#ffffff")
	pill.TextSize               = 12
	pill.FontFace               = theme.Font or Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium)
	pill.TextTransparency       = 0.3 -- Muted at rest (Rayfield feel)
	pill.AutoButtonColor        = false
	pill.Active                 = true
	pill.ZIndex                 = 3
	pill.Parent                 = frame

	local pillCorner = Instance.new("UICorner")
	pillCorner.CornerRadius = UDim.new(1, 0) -- Full pill curve
	pillCorner.Parent       = pill

	local pillStroke = Instance.new("UIStroke")
	pillStroke.Color           = theme.ElementStroke or Color3.fromHex("#2b2b2b")
	pillStroke.Thickness       = 1
	pillStroke.Transparency    = 0.4
	pillStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	pillStroke.Parent          = pill

	-- ── Self Instance ─────────────────────────────────────────────────────
	local self = setmetatable({}, Keybind) :: Keybind
	self.value = initKey
	self._frame = frame
	;(self :: any)._pill       = pill
	;(self :: any)._pillStroke = pillStroke
	;(self :: any)._stroke     = stroke
	;(self :: any)._theme      = theme
	;(self :: any)._flag       = flagKey
	;(self :: any)._callback   = callback
	;(self :: any)._onChanged  = onChanged
	;(self :: any)._recording  = false
	;(self :: any)._hold       = hold
	;(self :: any)._threshold  = holdThreshold

	-- ── Dynamic Pill Width Hugging (Utility Animation) ────────────────────
	local function sizePill(animate: boolean)
		local label = pill.Text
		local txtWidth = runtime.textService:GetTextSize(
			label,
			12,
			Enum.Font.GothamMedium,
			Vector2.new(10000, 10000)
		).X
		local frameW = frame.AbsoluteSize.X
		local isNarrow = frameW > 0 and frameW < 380
		local maxW = if isNarrow then math.clamp(math.floor(frameW * 0.40), 55, 100) else 160
		local minW = if isNarrow then 40 else 44
		local targetWidth = math.clamp(math.floor(txtWidth + 24), minW, maxW)

		tween.resizePill(pill, UDim2.fromOffset(targetWidth, 26), animate)
		textContainer.Size = UDim2.new(1, -(targetWidth + 24), 1, -8)
	end
	;(self :: any)._sizePill = sizePill
	sizePill(false)

	frame:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		sizePill(false)
	end)

	-- ── Interactivity & Recording Animations ──────────────────────────────
	local hovering = false

	-- Hover listener
	local hitBtn = Instance.new("TextButton")
	hitBtn.Name                   = "Interact"
	hitBtn.Size                   = UDim2.fromScale(1, 1)
	hitBtn.BackgroundTransparency = 1
	hitBtn.Text                   = ""
	hitBtn.AutoButtonColor        = false
	hitBtn.Active                 = true
	hitBtn.ZIndex                 = 1
	hitBtn.Parent                 = frame

	hitBtn.MouseEnter:Connect(function()
		if variables.settingsOpen then return end
		hovering = true
		tween.fire(stroke, constants.tweenFast, {
			Color = theme.ElementStrokeHover or theme.AccentColor or Color3.fromHex("#4cc2ff"),
		})
		if not (self :: any)._recording then
			tween.fire(pillStroke, constants.tweenFast, {
				Color = theme.AccentColor or Color3.fromHex("#4cc2ff"),
			})
		end
	end)

	hitBtn.MouseLeave:Connect(function()
		hovering = false
		if not (self :: any)._recording then
			tween.fire(stroke, constants.tweenFast, {
				Color = theme.ElementStroke or Color3.fromHex("#2b2b2b"),
			})
			tween.fire(pillStroke, constants.tweenFast, {
				Color = theme.ElementStroke or Color3.fromHex("#2b2b2b"),
				Transparency = 0.4,
			})
		end
	end)

	local sinkActionName = "Delirium_KeybindSink_" .. runtime.httpService:GenerateGUID(false)

	local function stopRecording()
		if not (self :: any)._recording then return end
		;(self :: any)._recording = false
		if activeRecordingKeybind == self then
			activeRecordingKeybind = nil
		end

		pill.Modal = false
		pcall(function()
			runtime.contextActionService:UnbindAction(sinkActionName)
		end)

		pill.Text = keyLabel(self.value)
		pill.TextTransparency = 0.3
		sizePill(true)
		tween.fire(pillStroke, constants.tweenFocus, {
			Color = if hovering
				then (theme.AccentColor or Color3.fromHex("#4cc2ff"))
				else (theme.ElementStroke or Color3.fromHex("#2b2b2b")),
			Transparency = 0.4,
		})
		tween.fire(pill, constants.tweenFocus, {
			BackgroundColor3       = theme.FieldBackground or Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = theme.FieldTransparency or 0.90,
		})
	end

	local function startRecording()
		if (self :: any)._recording then
			stopRecording()
			return
		end

		if activeRecordingKeybind and activeRecordingKeybind ~= self then
			local other = activeRecordingKeybind
			if (other :: any)._stopRecording then
				(other :: any):_stopRecording()
			end
		end
		activeRecordingKeybind = self

		;(self :: any)._recording = true
		pill.Modal = true

		pcall(function()
			local keyCodes = Enum.KeyCode:GetEnumItems()
			runtime.contextActionService:BindActionAtPriority(
				sinkActionName,
				function()
					return Enum.ContextActionResult.Sink
				end,
				false,
				Enum.ContextActionPriority.High.Value + 2000,
				Enum.UserInputType.MouseButton1,
				Enum.UserInputType.MouseButton2,
				Enum.UserInputType.MouseButton3,
				Enum.UserInputType.Touch,
				table.unpack(keyCodes)
			)
		end)

		pill.Text = "..."
		pill.TextTransparency = 0
		sizePill(true)
		tween.fire(pillStroke, constants.tweenFocus, {
			Color        = theme.AccentColor or Color3.fromHex("#4cc2ff"),
			Transparency = 0,
		})
		tween.fire(pill, constants.tweenFocus, {
			BackgroundColor3       = theme.AccentColor or Color3.fromHex("#4cc2ff"),
			BackgroundTransparency = 0.85,
		})
	end

	;(self :: any)._stopRecording = stopRecording
	;(self :: any)._sinkAction    = sinkActionName

	-- suppressNextClick: when InputBegan captures MB1, the paired MouseButton1Click
	-- fires right after on release. Without this flag that click would call startRecording()
	-- again, re-entering recording immediately after we just bound MB1.
	local suppressNextClick = false

	pill.MouseButton1Click:Connect(function()
		if suppressNextClick then
			suppressNextClick = false
			return
		end
		if (self :: any)._recording then
			stopRecording()
		else
			startRecording()
		end
	end)

	hitBtn.MouseButton1Click:Connect(function()
		if suppressNextClick then
			suppressNextClick = false
			return
		end
		if (self :: any)._recording then
			stopRecording()
		else
			startRecording()
		end
	end)

	-- ── Input Listening (Capture & Key Triggers) ──────────────────────────
	local isHolding = false
	local holdStartTime = 0

	local inputConn = runtime.userInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
		if (self :: any)._recording then
			if input.UserInputType == Enum.UserInputType.Keyboard then
				if input.KeyCode == Enum.KeyCode.Escape then
					stopRecording()
					return
				end
				if input.KeyCode == Enum.KeyCode.Backspace then
					stopRecording()
					self:Set(Enum.KeyCode.Unknown)
					return
				end
				stopRecording()
				self:Set(input.KeyCode)
				return
			elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
				-- Capturable. Set suppressNextClick so the release-paired
				-- MouseButton1Click doesn't re-enter startRecording().
				suppressNextClick = true
				stopRecording()
				self:Set(input.UserInputType)
				return
			elseif input.UserInputType == Enum.UserInputType.MouseButton2
				or input.UserInputType == Enum.UserInputType.MouseButton3 then
				stopRecording()
				self:Set(input.UserInputType)
				return
			elseif input.UserInputType == Enum.UserInputType.Touch then
				-- M3 FIX: touch-only devices can never set a keybind because Touch
				-- falls through all branches and leaves the pill stuck on "..."
				-- (re-entering recording on every subsequent tap).
				-- Collapse Touch → MB1 the same way Roblox collapses tap → click
				-- everywhere else, so mobile users get a usable binding.
				suppressNextClick = true
				stopRecording()
				self:Set(Enum.UserInputType.MouseButton1)
				return
			end
			return
		end

		if gameProcessed then return end

		-- Check if input matches bound key
		local matches = false
		if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == self.value then
			matches = true
		elseif input.UserInputType == self.value then
			matches = true
		end

		if matches then
			if hold then
				isHolding = true
				holdStartTime = os.clock()
				task.delay(holdThreshold, function()
					if isHolding and (os.clock() - holdStartTime) >= holdThreshold then
						if callback then task.spawn(callback, true) end
					end
				end)
			else
				if callback then task.spawn(callback, self.value) end
			end
		end
	end)

	local inputEndedConn: RBXScriptConnection? = nil
	if hold then
		inputEndedConn = runtime.userInputService.InputEnded:Connect(function(input: InputObject)
			if not isHolding then return end
			local matches = false
			if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == self.value then
				matches = true
			elseif input.UserInputType == self.value then
				matches = true
			end
			if matches then
				isHolding = false
				if (os.clock() - holdStartTime) >= holdThreshold then
					if callback then task.spawn(callback, false) end
				end
			end
		end)
	end

	;(self :: any)._inputConn      = inputConn
	;(self :: any)._inputEndedConn = inputEndedConn

	-- ── Theme Subscription ────────────────────────────────────────────────
	;(self :: any)._themeUnsub = themeUtil.subscribe(function(t)
		self._theme = t
		theme = t
		titleLabel.TextColor3 = t.ContentColor or Color3.fromHex("#ffffff")
		titleLabel.FontFace   = t.Font or constants.DEFAULT_FONT_MEDIUM
		pill.BackgroundColor3       = t.FieldBackground or Color3.fromRGB(255, 255, 255)
		pill.BackgroundTransparency = t.FieldTransparency or 0.90
		pill.TextColor3             = t.ContentColor or Color3.fromHex("#ffffff")
		pill.FontFace               = t.Font or constants.DEFAULT_FONT_MEDIUM
		pillStroke.Color            = t.ElementStroke or Color3.fromHex("#2b2b2b")
		stroke.Color                = t.ElementStroke or Color3.fromHex("#2b2b2b")
		gradient.Color              = t.ElementGradient or ColorSequence.new(Color3.fromRGB(28, 24, 44))
	end)

	return self
end

function Keybind:Set(value: EnumItem | string, skipChanged: boolean?)
	local key = coerceKey(value)
	self.value = key

	local pill: TextButton = (self :: any)._pill
	local flagKey          = (self :: any)._flag
	local onChanged        = (self :: any)._onChanged

	pill.Text = keyLabel(key)

	local sizePill = (self :: any)._sizePill
	if sizePill then
		sizePill(true)
	end

	if flagKey then
		flags:Set(flagKey, key.Name)
	end
	if not skipChanged and onChanged then
		task.spawn(onChanged, key)
	end
end

function Keybind:Destroy()
	local s = (self :: any)
	if s._recording and s._stopRecording then
		s._stopRecording()
	end
	if s._sinkAction then
		pcall(function()
			runtime.contextActionService:UnbindAction(s._sinkAction)
		end)
	end
	if s._inputConn then s._inputConn:Disconnect() end
	if s._inputEndedConn then s._inputEndedConn:Disconnect() end
	if s._themeUnsub then s._themeUnsub() end
	if s._descriptor then s._descriptor:Destroy() end
	self._frame:Destroy()
end

return Keybind
