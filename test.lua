


local ImportGlobals


local ClosureBindings = {function()local wax,script,require=ImportGlobals(1)local ImportGlobals return (function(...)











local types    = require(script.types)
local flags    = require(script.utility.flags)
local variables = require(script.utility.variables)
local constants = require(script.utility.constants)
local icons     = require(script.utility.icons)
local mediaService  = require(script.utility.mediaService)
local imageCache    = require(script.utility.imageCache)
local imageUtil     = require(script.utility.image)
local saveManager   = require(script.utility.saveManager)


export type Theme         = types.Theme
export type WindowProps   = types.WindowProps
export type TabProps      = types.TabProps
export type SectionProps  = types.SectionProps
export type LabelProps    = types.LabelProps
export type ButtonProps   = types.ButtonProps
export type ToggleProps   = types.ToggleProps
export type SliderProps   = types.SliderProps
export type DropdownProps = types.DropdownProps
export type InputProps    = types.InputProps
export type KeybindProps  = types.KeybindProps
export type ColorPickerProps = types.ColorPickerProps
export type NotifyProps   = types.NotifyProps

export type Window      = types.Window
export type Tab         = types.Tab
export type Section     = types.Section
export type Label       = types.Label
export type Button      = types.Button
export type Toggle      = types.Toggle
export type Slider      = types.Slider
export type Dropdown    = types.Dropdown
export type Input       = types.Input
export type Keybind     = types.Keybind
export type ColorPicker = types.ColorPicker
export type Delirium    = types.Delirium


type WindowModule = { new: (types.WindowProps) -> types.Window }

local delirium = {} :: Delirium


delirium.Flags = flags :: any


delirium.Icons = icons :: any
delirium.NebulaIcons = icons :: any



delirium.MediaService = mediaService :: any



delirium.SaveManager = saveManager :: any



delirium.LoadingScreen = require(script.components.loadingScreen) :: any




delirium._imageCache = imageCache :: any
delirium._image      = imageUtil  :: any

function delirium:CreateWindow(props: types.WindowProps): types.Window
	local made, result = pcall(function()
		return (require(script.components.window) :: WindowModule).new(props)
	end)

	if not made then
		error("[Delirium] CreateWindow failed: " .. tostring(result), 2)
	end

	local window = result :: types.Window

	
	
	task.delay(0.4, function()
		if not window.unloaded then
			window:Show()
		end
	end)

	return window
end

return delirium

end)() end,[3]=function()local wax,script,require=ImportGlobals(3)local ImportGlobals return (function(...)




local constants = require(script.Parent.Parent.utility.constants)
local tween     = require(script.Parent.Parent.utility.tween)
local element     = require(script.Parent.Parent.utility.element)
local themeUtil   = require(script.Parent.Parent.utility.theme)
local variables   = require(script.Parent.Parent.utility.variables)

export type ButtonProps = {
	name:        string?,
	description: string?,
	callback:    (() -> ())?,
}

export type Button = {
	_frame:  Frame,
	Destroy: (self: Button) -> (),
}

local Button = {}
Button.__index = Button

function Button.new(props: ButtonProps, theme: { [string]: any }, parent: Instance): Button
	local name        = props.name or "Button"
	local description = props.description or ""
	local callback    = props.callback

	local frame, stroke, gradient = element.makeFrame("Button_" .. name, theme, parent)

	
	local inner = Instance.new("Frame")
	inner.Name                   = "Inner"
	inner.Size                   = UDim2.new(1, 0, 1, 0)
	inner.BackgroundTransparency = 1
	inner.Parent                 = frame

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft  = UDim.new(0, 12)
	padding.PaddingRight = UDim.new(0, 12)
	padding.Parent       = inner

	local layout = Instance.new("UIListLayout")
	layout.FillDirection  = Enum.FillDirection.Vertical
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Padding        = UDim.new(0, 1)
	layout.Parent         = inner

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name                   = "Title"
	titleLabel.Size                   = UDim2.new(1, 0, 0, 18)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text                   = name
	titleLabel.TextColor3             = theme.ContentColor or Color3.fromRGB(220, 215, 240)
	titleLabel.TextSize               = 13
	titleLabel.FontFace               = theme.Font or Font.new("rbxasset://fonts/families/GothamSSm.json")
	titleLabel.TextXAlignment         = Enum.TextXAlignment.Left
	titleLabel.TextTruncate           = Enum.TextTruncate.AtEnd
	titleLabel.Parent                 = inner

	local descLabel: TextLabel? = nil
	if description ~= "" then
		descLabel = Instance.new("TextLabel")
		descLabel.Name                   = "Description"
		descLabel.Size                   = UDim2.new(1, 0, 0, 14)
		descLabel.BackgroundTransparency = 1
		descLabel.Text                   = description
		descLabel.TextColor3             = theme.PlaceholderColor or Color3.fromRGB(140, 130, 175)
		descLabel.TextSize               = 11
		descLabel.FontFace               = theme.Font or Font.new("rbxasset://fonts/families/GothamSSm.json")
		descLabel.TextXAlignment         = Enum.TextXAlignment.Left
		descLabel.TextTruncate           = Enum.TextTruncate.AtEnd
		descLabel.Parent                 = inner
	end

	
	local btn = Instance.new("TextButton")
	btn.Name                   = "Interact"
	btn.Size                   = UDim2.fromScale(1, 1)
	btn.BackgroundTransparency = 1
	btn.Text                   = ""
	btn.AutoButtonColor        = false
	btn.Parent                 = frame

	
	btn.MouseEnter:Connect(function()
		if variables.settingsOpen then return end
		tween.fire(frame, constants.tweenFast, {
			BackgroundTransparency = math.max(0, (theme.ElementTransparency or 0) - 0.06),
		})
		tween.fire(stroke, constants.tweenFast, {
			Color = theme.ElementStrokeHover or theme.AccentColor or Color3.fromHex("#4cc2ff"),
			Transparency = theme.ElementStrokeHoverTransparency or 0,
		})
	end)
	btn.MouseLeave:Connect(function()
		tween.fire(frame, constants.tweenFast, {
			BackgroundTransparency = theme.ElementTransparency or 0,
		})
		tween.fire(stroke, constants.tweenFast, {
			Color = theme.ElementStroke or Color3.fromHex("#2b2b2b"),
			Transparency = theme.ElementStrokeTransparency or 0,
		})
	end)
	btn.MouseButton1Click:Connect(function()
		
		tween.fire(stroke, constants.tweenFast, {
			Color = theme.AccentColor or Color3.fromHex("#4cc2ff"),
		})
		task.delay(0.15, function()
			tween.fire(stroke, constants.tweenFast, {
				Color = theme.ElementStroke or Color3.fromHex("#2b2b2b"),
			})
		end)
		if callback then
			task.spawn(callback)
		end
	end)

	local self = setmetatable({}, Button) :: Button
	self._frame = frame
	;(self :: any)._themeUnsub = themeUtil.subscribe(function(t)
		frame.BackgroundTransparency = t.ElementTransparency or 0
		stroke.Color = t.ElementStroke or Color3.fromHex("#2b2b2b")
		stroke.Transparency = t.ElementStrokeTransparency or 0
		titleLabel.TextColor3 = t.ContentColor or Color3.fromHex("#ffffff")
		titleLabel.FontFace = t.Font or constants.DEFAULT_FONT
		if descLabel then
			descLabel.TextColor3 = t.PlaceholderColor or Color3.fromHex("#9d9d9d")
			descLabel.FontFace = t.Font or constants.DEFAULT_FONT
		end
		gradient.Color = t.ElementGradient or ColorSequence.new(Color3.fromRGB(28, 24, 44))
		theme = t
	end)
	return self
end

function Button:Destroy()
	local s = (self :: any)
	if s._themeUnsub then s._themeUnsub() end
	self._frame:Destroy()
end

return Button

end)() end,[4]=function()local wax,script,require=ImportGlobals(4)local ImportGlobals return (function(...)




















local constants = require(script.Parent.Parent.utility.constants)
local flags     = require(script.Parent.Parent.utility.flags)
local runtime   = require(script.Parent.Parent.utility.runtime)
local element   = require(script.Parent.Parent.utility.element)
local themeUtil = require(script.Parent.Parent.utility.theme)



local PAD       = 12
local MAP_W     = 175
local MAP_H     = 148
local HUE_W     = 12
local ALPHA_W   = 12
local GAP_CH    = 8
local GAP_HA    = 6
local GAP_AR    = 12
local TITLE_H   = 32
local HEX_H     = 28
local GAP_PH    = 10

local ABOX_W    = 53
local ABOX_GAP  = 5

local POPUP_W   = 360
local CONTENT_Y = TITLE_H + PAD         
local POPUP_H   = CONTENT_Y + MAP_H + PAD 

local PILL_W    = 32
local PILL_H    = 18
local PILL_R    = 4
local CURSOR_D  = 14
local HANDLE_H  = 10

local HUE_CS = ColorSequence.new({
	ColorSequenceKeypoint.new(0.000, Color3.fromRGB(255, 0,   0)),
	ColorSequenceKeypoint.new(0.167, Color3.fromRGB(255, 255, 0)),
	ColorSequenceKeypoint.new(0.333, Color3.fromRGB(0,   255, 0)),
	ColorSequenceKeypoint.new(0.500, Color3.fromRGB(0,   255, 255)),
	ColorSequenceKeypoint.new(0.667, Color3.fromRGB(0,   0,   255)),
	ColorSequenceKeypoint.new(0.833, Color3.fromRGB(255, 0,   255)),
	ColorSequenceKeypoint.new(1.000, Color3.fromRGB(255, 0,   0)),
})



export type ColorPickerProps = {
	name:          string?,
	flag:          string?,
	color:         Color3?,
	alpha:         number?,
	showAlpha:     boolean?,
	overlayParent: Frame?,   
	overlayYOffset: number?, 
	callback:      ((value: Color3, alpha: number) -> ())?,
}

export type ColorPicker = {
	value:   Color3,
	alpha:   number,
	_frame:  Frame,
	Set:     (self: ColorPicker, value: Color3, alpha: number?, skipCallback: boolean?) -> (),
	Destroy: (self: ColorPicker) -> (),
}



local function clamp01(n: number): number
	return math.clamp(n, 0, 1)
end

local function colorToHex(c: Color3): string
	return string.format("#%02X%02X%02X",
		math.round(c.R * 255),
		math.round(c.G * 255),
		math.round(c.B * 255))
end

local function hexToColor(raw: string): Color3?
	local hex = raw:gsub("^#", "")
	if #hex ~= 6 then return nil end
	local r = tonumber(hex:sub(1, 2), 16)
	local g = tonumber(hex:sub(3, 4), 16)
	local b = tonumber(hex:sub(5, 6), 16)
	if not r or not g or not b then return nil end
	return Color3.fromRGB(r, g, b)
end

local function relPos(frame: GuiObject, mousePos: Vector2): Vector2
	local ap = frame.AbsolutePosition
	local as = frame.AbsoluteSize
	if as.X <= 0 or as.Y <= 0 then return Vector2.zero end
	return Vector2.new(
		clamp01((mousePos.X - ap.X) / as.X),
		clamp01((mousePos.Y - ap.Y) / as.Y)
	)
end

local function mkCorner(inst: Instance, r: number)
	local c        = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r)
	c.Parent       = inst
end

local function mkStroke(inst: Instance, col: Color3, thick: number): UIStroke
	local sk              = Instance.new("UIStroke")
	sk.Color              = col
	sk.Thickness          = thick
	sk.ApplyStrokeMode    = Enum.ApplyStrokeMode.Border
	sk.Parent             = inst
	return sk
end



local ColorPicker = {} :: { __index: any }
ColorPicker.__index = ColorPicker

function ColorPicker.new(props: ColorPickerProps, theme: { [string]: any }, parent: Instance): ColorPicker

	local name           = props.name or "ColorPicker"
	local flagKey        = props.flag
	local showAlpha      = props.showAlpha == true
	local callback       = props.callback
	local overlayParent  = (props :: any).overlayParent  :: Frame?
	local overlayYOffset = (props :: any).overlayYOffset :: number? or 0
	local windowMode     = overlayParent ~= nil

	
	
	
	
	
	
	
	local POP_Z: number = if windowMode then constants.zIndex.popup else 2

	
	local initColor: Color3
	local a: number = clamp01(props.alpha or 1)

	if flagKey and flags:Get(flagKey) ~= nil then
		local stored = flags:Get(flagKey)
		initColor = if typeof(stored) == "Color3" then stored :: Color3 else (props.color or Color3.fromRGB(255, 255, 255))
	else
		initColor = props.color or Color3.fromRGB(255, 255, 255)
	end

	local h, s, v = Color3.toHSV(initColor)

	
	local hueX:   number = PAD + MAP_W + GAP_CH
	local alphaX: number = hueX + HUE_W + GAP_HA
	local rightX: number = if showAlpha then (alphaX + ALPHA_W + GAP_AR) else (hueX + HUE_W + GAP_AR)
	local rightW: number = POPUP_W - rightX - PAD

	local PREVIEW_H: number = MAP_H - HEX_H - GAP_PH
	local hexW:  number     = if showAlpha then (rightW - ABOX_W - ABOX_GAP) else rightW
	local aboxX: number     = rightX + hexW + ABOX_GAP
	local hexY:  number     = CONTENT_Y + PREVIEW_H + GAP_PH

	
	local conns: { RBXScriptConnection } = {}
	local function addConn(c: RBXScriptConnection)
		table.insert(conns, c)
	end
	local themeUnsub: (() -> ())? = nil

	
	local frame, stroke = element.makeFrame("ColorPicker_" .. name, theme, parent)

	local titleLabel = Instance.new("TextLabel")
	titleLabel.AnchorPoint            = Vector2.new(0, 0.5)
	titleLabel.Position               = UDim2.new(0, 12, 0.5, 0)
	titleLabel.Size                   = UDim2.new(1, -(PILL_W + 24), 1, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text                   = name
	titleLabel.TextColor3             = theme.ContentColor or Color3.fromRGB(220, 215, 240)
	titleLabel.TextSize               = 13
	titleLabel.FontFace               = theme.Font or Font.new("rbxasset://fonts/families/GothamSSm.json")
	titleLabel.TextXAlignment         = Enum.TextXAlignment.Left
	titleLabel.TextTruncate           = Enum.TextTruncate.AtEnd
	titleLabel.Parent                 = frame

	local pill = Instance.new("Frame")
	pill.AnchorPoint      = Vector2.new(1, 0.5)
	pill.Position         = UDim2.new(1, -12, 0.5, 0)
	pill.Size             = UDim2.fromOffset(PILL_W, PILL_H)
	pill.BackgroundColor3 = initColor
	pill.BorderSizePixel  = 0
	pill.Parent           = frame
	mkCorner(pill, PILL_R)
	mkStroke(pill, theme.ElementStroke or Color3.fromRGB(50, 42, 80), 1)

	local headerBtn = Instance.new("TextButton")
	headerBtn.Size                   = UDim2.fromScale(1, 1)
	headerBtn.BackgroundTransparency = 1
	headerBtn.Text                   = ""
	headerBtn.AutoButtonColor        = false
	headerBtn.Parent                 = frame

	
	local gui: ScreenGui? = nil
	local backdrop: TextButton? = nil

	if not windowMode then
		local g = Instance.new("ScreenGui")
		g.Name           = "DeliriumColorPicker_" .. name
		g.DisplayOrder   = constants.displayOrder.popup
		g.ResetOnSpawn   = false
		g.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		g.Enabled        = false
		g.Parent         = runtime.guiContainer
		gui = g

		local bd = Instance.new("TextButton")
		bd.Size                   = UDim2.fromScale(1, 1)
		bd.BackgroundTransparency = 1
		bd.Text                   = ""
		bd.AutoButtonColor        = false
		bd.ZIndex                 = 1
		bd.Parent                 = g
		backdrop = bd
	end

	
	
	
	local dimOverlay: TextButton? = nil

	if windowMode then
		local ov = Instance.new("TextButton")
		ov.Name                   = "ColorPickerDim"
		ov.Position               = UDim2.fromOffset(0, overlayYOffset)
		ov.Size                   = UDim2.new(1, 0, 1, -overlayYOffset)
		ov.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
		ov.BackgroundTransparency = 0.55
		ov.BorderSizePixel        = 0
		ov.ZIndex                 = constants.zIndex.popup - 1
		ov.Active                 = true
		ov.Text                   = ""
		ov.AutoButtonColor        = false
		ov.Visible                = false
		ov.Parent                 = overlayParent :: Instance
		dimOverlay = ov
	end

	
	
	
	local popupParent: Instance = if windowMode then (overlayParent :: Instance) else (gui :: ScreenGui)

	local popup = Instance.new("Frame")
	popup.Name             = "ColorPickerPopup"
	popup.AnchorPoint      = Vector2.new(0.5, 0.5)
	popup.Position         = UDim2.fromScale(0.5, 0.5)
	popup.Size             = UDim2.fromOffset(POPUP_W, POPUP_H)
	popup.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
	popup.BorderSizePixel  = 0
	popup.ZIndex           = POP_Z
	popup.Visible          = windowMode   
	popup.Parent           = popupParent
	mkCorner(popup, 8)
	mkStroke(popup, Color3.fromRGB(48, 48, 56), 1)

	local popScale = Instance.new("UIScale")
	popScale.Scale = 1
	popScale.Parent = popup

	local function adjustScale()
		local winW: number
		local winH: number
		if windowMode and overlayParent then
			winW = overlayParent.AbsoluteSize.X
			winH = overlayParent.AbsoluteSize.Y - overlayYOffset
		else
			local cam = runtime.workspace.CurrentCamera
			local vp = if cam then cam.ViewportSize else Vector2.new(1366, 768)
			winW = vp.X
			winH = vp.Y
		end

		local uis = runtime.userInputService
		local isTouchDevice = uis.TouchEnabled and (not uis.KeyboardEnabled or not uis.MouseEnabled)
		local isSmallScreen = winW < 650 or winH < 420

		local targetScale: number
		if isTouchDevice or isSmallScreen then
			
			local fitW = (winW * 0.56) / POPUP_W
			local fitH = (winH * 0.60) / POPUP_H
			targetScale = math.clamp(math.min(fitW, fitH, 0.75), 0.48, 0.75)
		else
			
			local fitW = (winW - 32) / POPUP_W
			local fitH = (winH - 32) / POPUP_H
			targetScale = math.clamp(math.min(fitW, fitH, 1.0), 0.60, 1.0)
		end

		popScale.Scale = targetScale
	end

	
	if not windowMode then
		popup.Visible = true   
	else
		popup.Visible = false  
	end

	
	local popHit = Instance.new("TextButton")
	popHit.Size                   = UDim2.fromScale(1, 1)
	popHit.BackgroundTransparency = 1
	popHit.Text                   = ""
	popHit.AutoButtonColor        = false
	popHit.ZIndex                 = POP_Z
	popHit.Parent                 = popup

	
	local popTitle = Instance.new("TextLabel")
	popTitle.Position               = UDim2.fromOffset(PAD, 0)
	popTitle.Size                   = UDim2.new(1, -(PAD * 2 + 28), 0, TITLE_H)
	popTitle.BackgroundTransparency = 1
	popTitle.Text                   = name
	popTitle.TextSize               = 12
	popTitle.FontFace               = theme.Font or Font.new("rbxasset://fonts/families/GothamSSm.json")
	popTitle.TextColor3             = theme.PlaceholderColor or Color3.fromRGB(140, 130, 175)
	popTitle.TextXAlignment         = Enum.TextXAlignment.Left
	popTitle.ZIndex                 = POP_Z + 1
	popTitle.Parent                 = popup

	local popClose = Instance.new("TextButton")
	popClose.Name                   = "Close"
	popClose.AnchorPoint            = Vector2.new(1, 0.5)
	popClose.Position               = UDim2.new(1, -PAD, 0, TITLE_H / 2)
	popClose.Size                   = UDim2.fromOffset(20, 20)
	popClose.BackgroundColor3       = Color3.fromRGB(36, 36, 42)
	popClose.BackgroundTransparency = 0.4
	popClose.Text                   = "✕"
	popClose.TextColor3             = theme.PlaceholderColor or Color3.fromRGB(160, 160, 175)
	popClose.TextSize               = 11
	popClose.FontFace               = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium)
	popClose.AutoButtonColor        = false
	popClose.ZIndex                 = POP_Z + 2
	popClose.Parent                 = popup
	mkCorner(popClose, 4)

	
	local canvas = Instance.new("Frame")
	canvas.Name             = "Canvas"
	canvas.Position         = UDim2.fromOffset(PAD, CONTENT_Y)
	canvas.Size             = UDim2.fromOffset(MAP_W, MAP_H)
	canvas.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
	canvas.BorderSizePixel  = 0
	canvas.ZIndex           = POP_Z + 1
	canvas.Parent           = popup
	mkCorner(canvas, 4)
	mkStroke(canvas, Color3.fromRGB(48, 48, 56), 1)

	
	local satOvl = Instance.new("Frame")
	satOvl.Size                = UDim2.fromScale(1, 1)
	satOvl.BackgroundColor3    = Color3.new(1, 1, 1)
	satOvl.BorderSizePixel     = 0
	satOvl.ZIndex              = POP_Z + 2
	satOvl.Parent              = canvas
	mkCorner(satOvl, 4)
	do
		local g        = Instance.new("UIGradient")
		g.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(1, 1),
		})
		g.Parent = satOvl
	end

	
	local valOvl = Instance.new("Frame")
	valOvl.Size                = UDim2.fromScale(1, 1)
	valOvl.BackgroundColor3    = Color3.new(0, 0, 0)
	valOvl.BorderSizePixel     = 0
	valOvl.ZIndex              = POP_Z + 3
	valOvl.Parent              = canvas
	mkCorner(valOvl, 4)
	do
		local g        = Instance.new("UIGradient")
		g.Rotation     = 90
		g.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(1, 0),
		})
		g.Parent = valOvl
	end

	
	local cursor = Instance.new("Frame")
	cursor.Name             = "SVCursor"
	cursor.AnchorPoint      = Vector2.new(0.5, 0.5)
	cursor.Size             = UDim2.fromOffset(CURSOR_D, CURSOR_D)
	cursor.Position         = UDim2.new(s, 0, 1 - v, 0)
	cursor.BackgroundColor3 = Color3.fromHSV(h, s, v)
	cursor.BorderSizePixel  = 0
	cursor.ZIndex           = POP_Z + 6
	cursor.Parent           = canvas
	mkCorner(cursor, CURSOR_D // 2)
	do
		local cs           = Instance.new("UIStroke")
		cs.Color           = Color3.new(1, 1, 1)
		cs.Thickness       = 2
		cs.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		cs.Parent          = cursor
	end

	
	local canvasBtn = Instance.new("TextButton")
	canvasBtn.BackgroundTransparency = 1
	canvasBtn.Size                   = UDim2.fromScale(1, 1)
	canvasBtn.Text                   = ""
	canvasBtn.AutoButtonColor        = false
	canvasBtn.ZIndex                 = POP_Z + 5
	canvasBtn.Parent                 = canvas

	
	local hueBar = Instance.new("Frame")
	hueBar.Name             = "HueBar"
	hueBar.Position         = UDim2.fromOffset(hueX, CONTENT_Y)
	hueBar.Size             = UDim2.fromOffset(HUE_W, MAP_H)
	hueBar.BackgroundColor3 = Color3.new(1, 1, 1)
	hueBar.BorderSizePixel  = 0
	hueBar.ZIndex           = POP_Z + 1
	hueBar.Parent           = popup
	mkCorner(hueBar, HUE_W // 2)
	do
		local g    = Instance.new("UIGradient")
		g.Color    = HUE_CS
		g.Rotation = 90
		g.Parent   = hueBar
	end

	local hueHandle = Instance.new("Frame")
	hueHandle.AnchorPoint      = Vector2.new(0.5, 0.5)
	hueHandle.Size             = UDim2.fromOffset(HUE_W + 8, HANDLE_H)
	hueHandle.Position         = UDim2.new(0.5, 0, h, 0)
	hueHandle.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
	hueHandle.BorderSizePixel  = 0
	hueHandle.ZIndex           = POP_Z + 3
	hueHandle.Parent           = hueBar
	mkCorner(hueHandle, HANDLE_H // 2)
	do
		local hs           = Instance.new("UIStroke")
		hs.Color           = Color3.new(1, 1, 1)
		hs.Thickness       = 2
		hs.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		hs.Parent          = hueHandle
	end

	local hueBtn = Instance.new("TextButton")
	hueBtn.BackgroundTransparency = 1
	hueBtn.AnchorPoint            = Vector2.new(0.5, 0.5)
	hueBtn.Position               = UDim2.fromScale(0.5, 0.5)
	hueBtn.Size                   = UDim2.new(1, 18, 1, 10)
	hueBtn.Text                   = ""
	hueBtn.AutoButtonColor        = false
	hueBtn.ZIndex                 = POP_Z + 4
	hueBtn.Parent                 = hueBar

	
	local alphaBar:    Frame?      = nil
	local alphaHandle: Frame?      = nil
	local alphaBtn:    TextButton? = nil

	if showAlpha then
		local bar = Instance.new("Frame")
		bar.Name             = "AlphaBar"
		bar.Position         = UDim2.fromOffset(alphaX, CONTENT_Y)
		bar.Size             = UDim2.fromOffset(ALPHA_W, MAP_H)
		bar.BackgroundColor3 = Color3.fromHSV(h, s, v)
		bar.BorderSizePixel  = 0
		bar.ZIndex           = POP_Z + 1
		bar.Parent           = popup
		mkCorner(bar, ALPHA_W // 2)
		do
			local ag        = Instance.new("UIGradient")
			ag.Rotation     = 90
			ag.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0),
				NumberSequenceKeypoint.new(1, 1),
			})
			ag.Parent = bar
		end

		local handle = Instance.new("Frame")
		handle.AnchorPoint      = Vector2.new(0.5, 0.5)
		handle.Size             = UDim2.fromOffset(ALPHA_W + 8, HANDLE_H)
		handle.Position         = UDim2.new(0.5, 0, 1 - a, 0)
		handle.BackgroundColor3 = Color3.fromHSV(h, s, v)
		handle.BorderSizePixel  = 0
		handle.ZIndex           = POP_Z + 3
		handle.Parent           = bar
		mkCorner(handle, HANDLE_H // 2)
		do
			local as_           = Instance.new("UIStroke")
			as_.Color           = Color3.new(1, 1, 1)
			as_.Thickness       = 2
			as_.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			as_.Parent          = handle
		end

		local abtn = Instance.new("TextButton")
		abtn.BackgroundTransparency = 1
		abtn.AnchorPoint            = Vector2.new(0.5, 0.5)
		abtn.Position               = UDim2.fromScale(0.5, 0.5)
		abtn.Size                   = UDim2.new(1, 18, 1, 10)
		abtn.Text                   = ""
		abtn.AutoButtonColor        = false
		abtn.ZIndex                 = POP_Z + 4
		abtn.Parent                 = bar

		alphaBar    = bar
		alphaHandle = handle
		alphaBtn    = abtn
	end

	
	local swatch = Instance.new("Frame")
	swatch.Name             = "Swatch"
	swatch.Position         = UDim2.fromOffset(rightX, CONTENT_Y)
	swatch.Size             = UDim2.fromOffset(rightW, PREVIEW_H)
	swatch.BackgroundColor3 = Color3.fromHSV(h, s, v)
	swatch.BorderSizePixel  = 0
	swatch.ZIndex           = POP_Z + 1
	swatch.Parent           = popup
	mkCorner(swatch, 4)
	mkStroke(swatch, Color3.fromRGB(48, 48, 56), 1)

	
	local hexFrame = Instance.new("Frame")
	hexFrame.Position         = UDim2.fromOffset(rightX, hexY)
	hexFrame.Size             = UDim2.fromOffset(hexW, HEX_H)
	hexFrame.BackgroundColor3 = Color3.fromRGB(32, 32, 36)
	hexFrame.BorderSizePixel  = 0
	hexFrame.ZIndex           = POP_Z + 1
	hexFrame.Parent           = popup
	mkCorner(hexFrame, 4)
	mkStroke(hexFrame, Color3.fromRGB(48, 48, 56), 1)

	local hexInput = Instance.new("TextBox")
	hexInput.AnchorPoint            = Vector2.new(0.5, 0.5)
	hexInput.Position               = UDim2.fromScale(0.5, 0.5)
	hexInput.Size                   = UDim2.new(1, -8, 1, 0)
	hexInput.BackgroundTransparency = 1
	hexInput.Text                   = colorToHex(initColor)
	hexInput.PlaceholderText        = "#RRGGBB"
	hexInput.TextSize               = 11
	hexInput.FontFace               = Font.new("rbxasset://fonts/families/RobotoMono.json")
	hexInput.TextColor3             = theme.ContentColor or Color3.fromRGB(220, 215, 240)
	hexInput.PlaceholderColor3      = theme.PlaceholderColor or Color3.fromRGB(140, 130, 175)
	hexInput.ClearTextOnFocus       = false
	hexInput.TextXAlignment         = Enum.TextXAlignment.Center
	hexInput.ZIndex                 = POP_Z + 2
	hexInput.Parent                 = hexFrame

	
	local alphaInput: TextBox? = nil

	if showAlpha then
		local af = Instance.new("Frame")
		af.Position         = UDim2.fromOffset(aboxX, hexY)
		af.Size             = UDim2.fromOffset(ABOX_W, HEX_H)
		af.BackgroundColor3 = Color3.fromRGB(32, 32, 36)
		af.BorderSizePixel  = 0
		af.ZIndex           = POP_Z + 1
		af.Parent           = popup
		mkCorner(af, 4)
		mkStroke(af, Color3.fromRGB(48, 48, 56), 1)

		local ai = Instance.new("TextBox")
		ai.AnchorPoint            = Vector2.new(0.5, 0.5)
		ai.Position               = UDim2.fromScale(0.5, 0.5)
		ai.Size                   = UDim2.new(1, -6, 1, 0)
		ai.BackgroundTransparency = 1
		ai.Text                   = tostring(math.round(a * 100)) .. "%"
		ai.PlaceholderText        = "100%"
		ai.TextSize               = 11
		ai.FontFace               = Font.new("rbxasset://fonts/families/RobotoMono.json")
		ai.TextColor3             = theme.ContentColor or Color3.fromRGB(220, 215, 240)
		ai.PlaceholderColor3      = theme.PlaceholderColor or Color3.fromRGB(140, 130, 175)
		ai.ClearTextOnFocus       = false
		ai.TextXAlignment         = Enum.TextXAlignment.Center
		ai.ZIndex                 = POP_Z + 2
		ai.Parent                 = af

		alphaInput = ai
	end

	
	type DragTarget = "canvas" | "hue" | "alpha"
	local dragging: DragTarget? = nil

	
	local function refresh()
		local color = Color3.fromHSV(h, s, v)
		local pure  = Color3.fromHSV(h, 1, 1)

		canvas.BackgroundColor3    = pure
		cursor.Position            = UDim2.new(s, 0, 1 - v, 0)
		cursor.BackgroundColor3    = color
		hueHandle.Position         = UDim2.new(0.5, 0, h, 0)
		hueHandle.BackgroundColor3 = pure
		pill.BackgroundColor3      = color
		swatch.BackgroundColor3    = color

		if showAlpha and alphaBar and alphaHandle then
			alphaBar.BackgroundColor3    = color
			alphaHandle.Position         = UDim2.new(0.5, 0, 1 - a, 0)
			alphaHandle.BackgroundColor3 = color
		end

		if not hexInput:IsFocused() then
			hexInput.Text = colorToHex(color)
		end
		if showAlpha and alphaInput and not alphaInput:IsFocused() then
			alphaInput.Text = tostring(math.round(a * 100)) .. "%"
		end
	end

	local function fireChanged()
		local color = Color3.fromHSV(h, s, v)
		if flagKey then flags:Set(flagKey, color) end
		if callback then task.spawn(callback, color, a) end
	end

	
	local function pump(mousePos: Vector2)
		if dragging == "canvas" then
			local p = relPos(canvas, mousePos)
			s = p.X
			v = 1 - p.Y
		elseif dragging == "hue" then
			h = relPos(hueBar, mousePos).Y
		elseif dragging == "alpha" and alphaBar then
			a = 1 - relPos(alphaBar :: Frame, mousePos).Y
		end
		refresh()
		fireChanged()
	end

	
	local isOpen = false

	local function openPopup()
		if isOpen then return end
		isOpen       = true
		adjustScale()
		stroke.Color = theme.AccentColor or Color3.fromHex("#4cc2ff")
		if windowMode then
			popup.Visible = true
			if dimOverlay then dimOverlay.Visible = true end
		else
			(gui :: ScreenGui).Enabled = true
		end
		refresh()
	end

	if windowMode and overlayParent then
		addConn((overlayParent :: Frame):GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
			if isOpen then adjustScale() end
		end))
	else
		local cam = runtime.workspace.CurrentCamera
		if cam then
			addConn(cam:GetPropertyChangedSignal("ViewportSize"):Connect(function()
				if isOpen then adjustScale() end
			end))
		end
	end

	local function closePopup()
		if not isOpen then return end
		isOpen       = false
		dragging     = nil
		stroke.Color = theme.ElementStroke or Color3.fromHex("#2b2b2b")
		if windowMode then
			popup.Visible = false
			if dimOverlay then dimOverlay.Visible = false end
		else
			(gui :: ScreenGui).Enabled = false
		end
	end

	
	addConn(headerBtn.MouseButton1Click:Connect(function()
		if isOpen then closePopup() else openPopup() end
	end))

	
	if not windowMode and backdrop then
		addConn((backdrop :: TextButton).MouseButton1Click:Connect(closePopup))
	end
	if windowMode and dimOverlay then
		addConn((dimOverlay :: TextButton).MouseButton1Click:Connect(closePopup))
	end
	addConn(popClose.MouseButton1Click:Connect(closePopup))

	
	addConn(headerBtn.MouseEnter:Connect(function()
		if not isOpen then
			stroke.Color = theme.ElementStrokeHover or theme.AccentColor or Color3.fromHex("#4cc2ff")
		end
	end))
	addConn(headerBtn.MouseLeave:Connect(function()
		if not isOpen then
			stroke.Color = theme.ElementStroke or Color3.fromHex("#2b2b2b")
		end
	end))

	
	addConn(canvasBtn.InputBegan:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = "canvas"
			pump(Vector2.new(input.Position.X, input.Position.Y))
		end
	end))

	addConn(hueBtn.InputBegan:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = "hue"
			pump(Vector2.new(input.Position.X, input.Position.Y))
		end
	end))

	if showAlpha and alphaBtn then
		local abtn = alphaBtn :: TextButton
		addConn(abtn.InputBegan:Connect(function(input: InputObject)
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch then
				dragging = "alpha"
				pump(Vector2.new(input.Position.X, input.Position.Y))
			end
		end))
	end

	addConn(runtime.userInputService.InputChanged:Connect(function(input: InputObject)
		if not dragging then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch then
			pump(Vector2.new(input.Position.X, input.Position.Y))
		end
	end))

	addConn(runtime.userInputService.InputEnded:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = nil
		end
	end))

	
	addConn(hexInput.FocusLost:Connect(function()
		local color = hexToColor(hexInput.Text)
		if not color then
			hexInput.Text = colorToHex(Color3.fromHSV(h, s, v))
			return
		end
		h, s, v = Color3.toHSV(color)
		refresh()
		fireChanged()
	end))

	if showAlpha and alphaInput then
		local ai = alphaInput :: TextBox
		addConn(ai.FocusLost:Connect(function()
			local n = tonumber((ai.Text:gsub("[^%d%.]", "")))
			if n then
				a = clamp01(n / 100)
				refresh()
				fireChanged()
			else
				ai.Text = tostring(math.round(a * 100)) .. "%"
			end
		end))
	end

	
	themeUnsub = themeUtil.subscribe(function(t)
		theme = t
		frame.BackgroundTransparency = t.ElementTransparency or 0
		local fGrad = frame:FindFirstChildOfClass("UIGradient")
		if fGrad then
			fGrad.Color = t.ElementGradient or ColorSequence.new(Color3.fromRGB(28, 24, 44))
		end
		stroke.Transparency = t.ElementStrokeTransparency or 0
		stroke.Color = if isOpen
			then (t.ElementStrokeHover or t.AccentColor or Color3.fromHex("#4cc2ff"))
			else (t.ElementStroke or Color3.fromHex("#2b2b2b"))

		titleLabel.TextColor3      = t.ContentColor or Color3.fromHex("#ffffff")
		titleLabel.FontFace        = t.Font or constants.DEFAULT_FONT
		popTitle.TextColor3        = t.PlaceholderColor or Color3.fromHex("#9d9d9d")
		popTitle.FontFace          = t.Font or constants.DEFAULT_FONT
		hexInput.TextColor3        = t.ContentColor or Color3.fromHex("#ffffff")
		hexInput.PlaceholderColor3 = t.PlaceholderColor or Color3.fromHex("#9d9d9d")
		if alphaInput then
			alphaInput.TextColor3        = t.ContentColor or Color3.fromHex("#ffffff")
			alphaInput.PlaceholderColor3 = t.PlaceholderColor or Color3.fromHex("#9d9d9d")
		end
	end)

	
	local self = setmetatable({}, ColorPicker) :: ColorPicker
	self.value  = initColor
	self.alpha  = a
	self._frame = frame
	;(self :: any)._flag = flagKey
	if flagKey and flagKey ~= "" then
		flags:Set(flagKey, initColor)
	end

	function self:Set(value: Color3, newAlpha: number?, skipCallback: boolean?)
		h, s, v    = Color3.toHSV(value)
		if newAlpha ~= nil then a = clamp01(newAlpha) end
		self.value = value
		self.alpha = a
		refresh()
		if not skipCallback then fireChanged() end
	end

	function self:Destroy()
		if themeUnsub then themeUnsub() end
		for _, c in conns do c:Disconnect() end
		table.clear(conns)
		
		
		if windowMode then
			popup:Destroy()
			if dimOverlay then dimOverlay:Destroy() end
		else
			if gui then (gui :: ScreenGui):Destroy() end
		end
		frame:Destroy()
	end

	refresh()
	return self
end

return ColorPicker

end)() end,[5]=function()local wax,script,require=ImportGlobals(5)local ImportGlobals return (function(...)







local tween     = require(script.Parent.Parent.utility.tween)
local themeUtil = require(script.Parent.Parent.utility.theme)
local constants = require(script.Parent.Parent.utility.constants)
local variables = require(script.Parent.Parent.utility.variables)

local Players    = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local TWEEN_TAB  = TweenInfo.new(0.16, Enum.EasingStyle.Quad,  Enum.EasingDirection.Out)
local THUMB_TYPE = Enum.ThumbnailType.HeadShot
local THUMB_SIZE = Enum.ThumbnailSize.Size100x100

export type Dashboard = {
	_cardFrame:   Frame,
	_content:     Frame,
	_themeUnsub:  () -> (),
	ShowContent:  (self: Dashboard) -> (),
	HideContent:  (self: Dashboard) -> (),
	Destroy:      (self: Dashboard) -> (),
}

local Dashboard = {}
Dashboard.__index = Dashboard



local function formatAge(days: number): string
	if days >= 365 then
		local y = math.floor(days / 365)
		return y == 1 and "1 year" or y .. " years"
	elseif days >= 30 then
		local m = math.floor(days / 30)
		return m == 1 and "1 month" or m .. " months"
	else
		return days == 1 and "1 day" or days .. " days"
	end
end

local function formatTime(secs: number): string
	local h = math.floor(secs / 3600)
	local m = math.floor((secs % 3600) / 60)
	local s = math.floor(secs % 60)
	if h > 0 then return string.format("%dh %02dm", h, m)
	elseif m > 0 then return string.format("%dm %02ds", m, s)
	else return string.format("%ds", s) end
end

local function makeCircle(parent: Instance, size: number): Frame
	local f = Instance.new("Frame")
	f.Size = UDim2.fromOffset(size, size); f.BackgroundColor3 = Color3.fromRGB(0,0,0)
	f.BorderSizePixel = 0; f.ClipsDescendants = true; f.Parent = parent
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1,0); c.Parent = f
	return f
end








function Dashboard.new(
	sidebarSlot:  Frame,
	_windowFrame: Frame,
	contentArea:  Frame,
	theme:        { [string]: any }
): Dashboard

	local lp: Player = Players.LocalPlayer

	
	local function getTokens(t: { [string]: any })
		return {
			accent        = t.AccentColor        or Color3.fromHex("#4cc2ff"),
			accentDim     = t.AccentMuted         or Color3.fromHex("#1a3d52"),
			border        = t.SurfaceStroke       or Color3.fromHex("#2b2b2b"),
			surface       = t.TitleBarColor       or Color3.fromHex("#111114"),
			surfaceMid    = t.WindowColor.Keypoints[1].Value,
			textPrimary   = t.TitlingColor        or Color3.fromHex("#ffffff"),
			textSecondary = t.PlaceholderColor    or Color3.fromHex("#8a8a92"),
			neutralBtn    = t.NeutralButton       or Color3.fromHex("#1e1e1e"),
			neutralHover  = t.NeutralButtonHover  or Color3.fromHex("#252525"),
			errorColor    = t.ErrorColor          or Color3.fromHex("#ff4f58"),
			font          = t.Font                or Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium),
			fontBold      = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold),
			fontXBold     = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold),
			elemCorner    = t.ElementCornerRadius or UDim.new(0, 8),
			winGradient   = t.WindowColor,
		}
	end

	local tk = getTokens(theme)

	
	
	

	local card = Instance.new("Frame")
	card.Name = "Dashboard"; card.Size = UDim2.new(1,0,1,0)
	card.BackgroundColor3 = tk.surface; card.BorderSizePixel = 0
	card.ClipsDescendants = false; card.Parent = sidebarSlot

	
	local topSep = Instance.new("Frame")
	topSep.Name = "TopSep"; topSep.Size = UDim2.new(1,0,0,1)
	topSep.BackgroundColor3 = tk.border; topSep.BackgroundTransparency = 0.4
	topSep.BorderSizePixel = 0; topSep.Parent = card

	
	local cardHit = Instance.new("TextButton")
	cardHit.Name = "Hit"; cardHit.Size = UDim2.fromScale(1,1)
	cardHit.BackgroundTransparency = 1; cardHit.Text = ""
	cardHit.AutoButtonColor = false; cardHit.ZIndex = 2; cardHit.Parent = card

	
	local avatarClip = makeCircle(card, 36)
	avatarClip.Name = "AvatarClip"; avatarClip.AnchorPoint = Vector2.new(0,0.5)
	avatarClip.Position = UDim2.new(0,10,0.5,0); avatarClip.ZIndex = 2

	local avatarImg = Instance.new("ImageLabel")
	avatarImg.Name = "Avatar"; avatarImg.Size = UDim2.fromScale(1,1)
	avatarImg.BackgroundColor3 = Color3.fromHex("#1c1c1f"); avatarImg.BorderSizePixel = 0
	avatarImg.Image = ""; avatarImg.ScaleType = Enum.ScaleType.Fit
	avatarImg.ZIndex = 2; avatarImg.Parent = avatarClip

	
	local nameStack = Instance.new("Frame")
	nameStack.Name = "NameStack"; nameStack.AnchorPoint = Vector2.new(0,0.5)
	nameStack.Position = UDim2.new(0,54,0.5,0); nameStack.Size = UDim2.new(1,-66,0,36)
	nameStack.BackgroundTransparency = 1; nameStack.ZIndex = 2; nameStack.Parent = card
	do
		local l = Instance.new("UIListLayout"); l.FillDirection = Enum.FillDirection.Vertical
		l.VerticalAlignment = Enum.VerticalAlignment.Center; l.Padding = UDim.new(0,2); l.Parent = nameStack
	end

	local dispLbl = Instance.new("TextLabel")
	dispLbl.Name = "DisplayName"; dispLbl.Size = UDim2.new(1,0,0,16)
	dispLbl.BackgroundTransparency = 1; dispLbl.Text = lp.DisplayName
	dispLbl.TextColor3 = tk.textPrimary; dispLbl.TextSize = 13
	dispLbl.FontFace = tk.fontBold; dispLbl.TextXAlignment = Enum.TextXAlignment.Left
	dispLbl.TextTruncate = Enum.TextTruncate.AtEnd; dispLbl.ZIndex = 3; dispLbl.Parent = nameStack

	local userLbl = Instance.new("TextLabel")
	userLbl.Name = "Username"; userLbl.Size = UDim2.new(1,0,0,13)
	userLbl.BackgroundTransparency = 1; userLbl.Text = "@" .. lp.Name
	userLbl.TextColor3 = tk.textSecondary; userLbl.TextSize = 11
	userLbl.FontFace = tk.font; userLbl.TextXAlignment = Enum.TextXAlignment.Left
	userLbl.TextTruncate = Enum.TextTruncate.AtEnd; userLbl.ZIndex = 3; userLbl.Parent = nameStack

	
	local chevron = Instance.new("TextLabel")
	chevron.Name = "Chevron"; chevron.AnchorPoint = Vector2.new(1,0.5)
	chevron.Position = UDim2.new(1,-8,0.5,0); chevron.Size = UDim2.fromOffset(14,14)
	chevron.BackgroundTransparency = 1; chevron.Text = "›"
	chevron.TextColor3 = tk.textSecondary; chevron.TextSize = 16
	chevron.FontFace = tk.fontBold; chevron.ZIndex = 3; chevron.Parent = card

	
	cardHit.MouseEnter:Connect(function()
		tween.fire(card, TweenInfo.new(0.14, Enum.EasingStyle.Quad), { BackgroundColor3 = tk.neutralHover })
	end)
	cardHit.MouseLeave:Connect(function()
		tween.fire(card, TweenInfo.new(0.14, Enum.EasingStyle.Quad), { BackgroundColor3 = tk.surface })
	end)

	
	
	

	local content = Instance.new("Frame")
	content.Name = "DashboardContent"
	content.Size = UDim2.fromScale(1, 1)
	content.BackgroundTransparency = 1
	content.Visible = false
	content.ClipsDescendants = true
	content.Parent = contentArea

	
	local TAB_BAR_H = 40
	local TAB_DEFS  = { "Profile", "Stats", "Session" }

	local tabBar = Instance.new("Frame")
	tabBar.Name = "TabBar"; tabBar.Size = UDim2.new(1,0,0,TAB_BAR_H)
	tabBar.BackgroundColor3 = tk.surface; tabBar.BackgroundTransparency = 0
	tabBar.BorderSizePixel = 0; tabBar.ZIndex = 2; tabBar.Parent = content
	do
		local l = Instance.new("UIListLayout"); l.FillDirection = Enum.FillDirection.Horizontal
		l.HorizontalAlignment = Enum.HorizontalAlignment.Left
		l.VerticalAlignment = Enum.VerticalAlignment.Center
		l.SortOrder = Enum.SortOrder.LayoutOrder; l.Parent = tabBar
	end

	local tabBarSep = Instance.new("Frame")
	tabBarSep.Name = "TabBarSep"; tabBarSep.AnchorPoint = Vector2.new(0,1)
	tabBarSep.Position = UDim2.new(0,0,1,0); tabBarSep.Size = UDim2.new(1,0,0,1)
	tabBarSep.BackgroundColor3 = tk.border; tabBarSep.BackgroundTransparency = 0.4
	tabBarSep.BorderSizePixel = 0; tabBarSep.ZIndex = 3; tabBarSep.Parent = tabBar

	
	local CONTENT_TOP = TAB_BAR_H + 1

	
	local tabEntries: { { btn: TextButton, underline: Frame, scroll: ScrollingFrame } } = {}
	local activeTabIdx = 1

	local function getTabW(): number
		
		local fullW = contentArea.AbsoluteSize.X
		if fullW < 10 then fullW = 600 end 
		return math.floor(fullW / #TAB_DEFS)
	end

	local function buildTab(label: string, order: number)
		local btn = Instance.new("TextButton")
		btn.Name = "Tab_" .. label
		btn.Size = UDim2.new(1 / #TAB_DEFS, 0, 1, 0) 
		btn.BackgroundTransparency = 1; btn.Text = label
		btn.TextColor3 = tk.textSecondary; btn.TextSize = 12
		btn.FontFace = tk.fontBold; btn.AutoButtonColor = false
		btn.ZIndex = 3; btn.LayoutOrder = order; btn.Parent = tabBar

		local underline = Instance.new("Frame")
		underline.Name = "Underline"; underline.AnchorPoint = Vector2.new(0.5,1)
		underline.Position = UDim2.new(0.5,0,1,0)
		underline.Size = UDim2.fromOffset(0, 2) 
		underline.BackgroundColor3 = tk.accent; underline.BorderSizePixel = 0
		underline.ZIndex = 4; underline.Parent = btn
		do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1,0); c.Parent = underline end

		local scroll = Instance.new("ScrollingFrame")
		scroll.Name = "Content_" .. label
		scroll.Position = UDim2.fromOffset(0, CONTENT_TOP)
		scroll.Size = UDim2.new(1, 0, 1, -CONTENT_TOP)
		scroll.BackgroundTransparency = 1; scroll.BorderSizePixel = 0
		scroll.ScrollBarThickness = 2; scroll.ScrollBarImageColor3 = tk.border
		scroll.ScrollBarImageTransparency = 0.5
		scroll.CanvasSize = UDim2.fromOffset(0,0); scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
		scroll.ClipsDescendants = true; scroll.ZIndex = 2
		scroll.Visible = false; scroll.Parent = content
		do
			local l = Instance.new("UIListLayout"); l.FillDirection = Enum.FillDirection.Vertical
			l.VerticalAlignment = Enum.VerticalAlignment.Top; l.Padding = UDim.new(0,0)
			l.SortOrder = Enum.SortOrder.LayoutOrder; l.Parent = scroll
		end
		do local p = Instance.new("UIPadding"); p.PaddingBottom = UDim.new(0,20); p.Parent = scroll end

		return btn, underline, scroll
	end

	for i, label in ipairs(TAB_DEFS) do
		local btn, ul, scroll = buildTab(label, i)
		table.insert(tabEntries, { btn = btn, underline = ul, scroll = scroll })
	end

	
	local function selectInnerTab(idx: number)
		activeTabIdx = idx
		for i, entry in ipairs(tabEntries) do
			local active = (i == idx)
			TweenService:Create(entry.btn, TWEEN_TAB, {
				TextColor3 = if active then tk.accent else tk.textSecondary
			}):Play()
			
			
			TweenService:Create(entry.underline, TWEEN_TAB, {
				Size = if active then UDim2.fromOffset(60, 2) else UDim2.fromOffset(0, 2)
			}):Play()
			entry.scroll.Visible = active
		end
	end

	for i, entry in ipairs(tabEntries) do
		local idx = i
		entry.btn.MouseButton1Click:Connect(function() selectInnerTab(idx) end)
	end

	
	local function makeSecLabel(parent: ScrollingFrame, text: string, order: number)
		local lbl = Instance.new("TextLabel")
		lbl.Name = "Sec_" .. text; lbl.Size = UDim2.new(1,0,0,28)
		lbl.BackgroundTransparency = 1; lbl.Text = text
		lbl.TextColor3 = tk.textSecondary; lbl.TextTransparency = 0.3
		lbl.TextSize = 9; lbl.FontFace = tk.fontXBold
		lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.LayoutOrder = order
		lbl.ZIndex = 3; lbl.Parent = parent
		do
			local p = Instance.new("UIPadding"); p.PaddingLeft = UDim.new(0,14)
			p.PaddingTop = UDim.new(0,10); p.Parent = lbl
		end
	end

	
	local function makeStatCard(
		parent: ScrollingFrame,
		labelText: string,
		valueText: string,
		order: number,
		accentLeft: boolean?
	): TextLabel
		local wrap = Instance.new("Frame")
		wrap.Name = "Wrap_" .. labelText:gsub(" ","_"); wrap.Size = UDim2.new(1,0,0,42)
		wrap.BackgroundTransparency = 1; wrap.LayoutOrder = order; wrap.ZIndex = 2; wrap.Parent = parent
		do local p = Instance.new("UIPadding"); p.PaddingLeft = UDim.new(0,12); p.PaddingRight = UDim.new(0,12); p.Parent = wrap end

		local row = Instance.new("Frame")
		row.Name = "Row"; row.Size = UDim2.new(1,0,1,-6)
		row.AnchorPoint = Vector2.new(0,0.5); row.Position = UDim2.fromScale(0,0.5)
		row.BackgroundColor3 = Color3.fromRGB(255,255,255); row.BackgroundTransparency = 0.955
		row.BorderSizePixel = 0; row.ZIndex = 2; row.Parent = wrap
		do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,8); c.Parent = row end
		do
			local sk = Instance.new("UIStroke"); sk.Color = tk.border; sk.Thickness = 1
			sk.Transparency = 0.55; sk.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; sk.Parent = row
		end
		do local p = Instance.new("UIPadding"); p.PaddingLeft = UDim.new(0,12); p.PaddingRight = UDim.new(0,12); p.Parent = row end

		if accentLeft then
			local bar = Instance.new("Frame")
			bar.Size = UDim2.new(0,3,0,16); bar.AnchorPoint = Vector2.new(0,0.5)
			bar.Position = UDim2.new(0,0,0.5,0); bar.BackgroundColor3 = tk.accent
			bar.BorderSizePixel = 0; bar.ZIndex = 3; bar.Parent = row
			do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1,0); c.Parent = bar end
		end

		local off = if accentLeft then 10 else 0
		local lbl = Instance.new("TextLabel")
		lbl.Name = "Label"; lbl.AnchorPoint = Vector2.new(0,0.5)
		lbl.Position = UDim2.new(0,off,0.5,0); lbl.Size = UDim2.new(0.55,0,0,14)
		lbl.BackgroundTransparency = 1; lbl.Text = labelText
		lbl.TextColor3 = tk.textSecondary; lbl.TextSize = 12
		lbl.FontFace = tk.font; lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.ZIndex = 3; lbl.Parent = row

		local val = Instance.new("TextLabel")
		val.Name = "Value"; val.AnchorPoint = Vector2.new(1,0.5)
		val.Position = UDim2.fromScale(1,0.5); val.Size = UDim2.new(0.5,0,0,14)
		val.BackgroundTransparency = 1; val.Text = valueText
		val.TextColor3 = tk.textPrimary; val.TextSize = 12
		val.FontFace = tk.fontBold; val.TextXAlignment = Enum.TextXAlignment.Right
		val.TextTruncate = Enum.TextTruncate.AtEnd; val.ZIndex = 3; val.Parent = row

		return val
	end

	
	
	
	local profScroll = tabEntries[1].scroll

	
	local heroCard = Instance.new("Frame")
	heroCard.Name = "HeroCard"; heroCard.Size = UDim2.new(1,0,0,0)
	heroCard.AutomaticSize = Enum.AutomaticSize.Y
	heroCard.BackgroundTransparency = 1; heroCard.LayoutOrder = 1; heroCard.Parent = profScroll
	do
		local p = Instance.new("UIPadding"); p.PaddingTop = UDim.new(0,24)
		p.PaddingBottom = UDim.new(0,16); p.Parent = heroCard
	end
	do
		local l = Instance.new("UIListLayout"); l.FillDirection = Enum.FillDirection.Vertical
		l.HorizontalAlignment = Enum.HorizontalAlignment.Center
		l.VerticalAlignment = Enum.VerticalAlignment.Top
		l.Padding = UDim.new(0,10); l.Parent = heroCard
	end

	local bigRing = Instance.new("Frame")
	bigRing.Name = "BigRing"; bigRing.Size = UDim2.fromOffset(96,96)
	bigRing.BackgroundColor3 = tk.accent; bigRing.BackgroundTransparency = 1
	bigRing.BorderSizePixel = 0; bigRing.ZIndex = 2; bigRing.Parent = heroCard
	do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1,0); c.Parent = bigRing end

	local bigClip = makeCircle(bigRing, 86)
	bigClip.AnchorPoint = Vector2.new(0.5,0.5); bigClip.Position = UDim2.fromScale(0.5,0.5); bigClip.ZIndex = 3

	local bigAvatar = Instance.new("ImageLabel")
	bigAvatar.Name = "BigAvatar"; bigAvatar.Size = UDim2.fromScale(1,1)
	bigAvatar.BackgroundColor3 = Color3.fromHex("#1c1c1f"); bigAvatar.BorderSizePixel = 0
	bigAvatar.Image = ""; bigAvatar.ScaleType = Enum.ScaleType.Fit
	bigAvatar.ZIndex = 4; bigAvatar.Parent = bigClip

	local bigName = Instance.new("TextLabel")
	bigName.Name = "BigName"; bigName.Size = UDim2.new(1,-32,0,24)
	bigName.BackgroundTransparency = 1; bigName.Text = lp.DisplayName
	bigName.TextColor3 = tk.textPrimary; bigName.TextSize = 18
	bigName.FontFace = tk.fontBold; bigName.TextXAlignment = Enum.TextXAlignment.Center
	bigName.TextTruncate = Enum.TextTruncate.AtEnd; bigName.ZIndex = 3; bigName.Parent = heroCard

	
	local chipRow = Instance.new("Frame")
	chipRow.Name = "ChipRow"; chipRow.Size = UDim2.new(1,-32,0,24)
	chipRow.BackgroundTransparency = 1; chipRow.ZIndex = 3; chipRow.Parent = heroCard
	do
		local l = Instance.new("UIListLayout"); l.FillDirection = Enum.FillDirection.Horizontal
		l.HorizontalAlignment = Enum.HorizontalAlignment.Center
		l.VerticalAlignment = Enum.VerticalAlignment.Center
		l.Padding = UDim.new(0,6); l.Parent = chipRow
	end

	local function makeChip(text: string, isAccent: boolean)
		local chip = Instance.new("Frame")
		chip.Size = UDim2.new(0,0,1,0); chip.AutomaticSize = Enum.AutomaticSize.X
		chip.BackgroundColor3 = if isAccent then tk.accentDim else Color3.fromRGB(255,255,255)
		chip.BackgroundTransparency = if isAccent then 0 else 0.92
		chip.BorderSizePixel = 0; chip.ZIndex = 4; chip.Parent = chipRow
		do
			local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1,0); c.Parent = chip
			local p = Instance.new("UIPadding"); p.PaddingLeft = UDim.new(0,8); p.PaddingRight = UDim.new(0,8); p.Parent = chip
		end
		local lbl2 = Instance.new("TextLabel")
		lbl2.Size = UDim2.new(0,0,1,0); lbl2.AutomaticSize = Enum.AutomaticSize.X
		lbl2.BackgroundTransparency = 1; lbl2.Text = text
		lbl2.TextColor3 = if isAccent then tk.accent else tk.textSecondary; lbl2.TextSize = 11
		lbl2.FontFace = tk.fontBold; lbl2.ZIndex = 5; lbl2.Parent = chip
	end
	makeChip("@" .. lp.Name, false)
	makeChip("ID " .. tostring(lp.UserId), true)

	
	local profDiv = Instance.new("Frame")
	profDiv.Name = "Divider"; profDiv.Size = UDim2.new(1,-28,0,1)
	profDiv.BackgroundColor3 = tk.border; profDiv.BackgroundTransparency = 0.45
	profDiv.BorderSizePixel = 0; profDiv.LayoutOrder = 2; profDiv.ZIndex = 2; profDiv.Parent = profScroll

	makeSecLabel(profScroll, "IDENTITY", 3)
	makeStatCard(profScroll, "Display Name", lp.DisplayName,            4, true)
	makeStatCard(profScroll, "Username",     "@" .. lp.Name,            5, true)
	makeStatCard(profScroll, "User ID",      tostring(lp.UserId),       6, true)
	makeStatCard(profScroll, "Account Age",  formatAge(lp.AccountAge),  7, true)

	
	
	
	local statsScroll = tabEntries[2].scroll

	makeSecLabel(statsScroll, "ACCOUNT", 1)
	makeStatCard(statsScroll, "Account Age",  formatAge(lp.AccountAge),                            2)
	makeStatCard(statsScroll, "User ID",      tostring(lp.UserId),                                 3)
	local memberRow = makeStatCard(statsScroll, "Membership", "—",                                 4)
	local teamRow   = makeStatCard(statsScroll, "Team",       lp.Team and lp.Team.Name or "—",     5)

	pcall(function()
		local tier = lp.MembershipType
		memberRow.Text = if tier == Enum.MembershipType.Premium then "Premium"
			elseif tier == Enum.MembershipType.None then "None"
			else "—"
	end)

	makeSecLabel(statsScroll, "PLACE", 10)
	makeStatCard(statsScroll, "Place ID",  tostring(game.PlaceId),                           11)
	makeStatCard(statsScroll, "Game ID",   tostring(game.GameId),                            12)
	local jobIdFull = tostring(game.JobId)
	makeStatCard(statsScroll, "Job ID",    if #jobIdFull > 14 then jobIdFull:sub(1,12) .. "…" else jobIdFull, 13)

	
	local executorName: string = "—"
	pcall(function()
		
		local env: any = (getfenv :: any)(0)
		local fn: any = env.identifyexecutor or env.getexecutorname or env.EXECUTOR_NAME
		if type(fn) == "function" then
			executorName = tostring(fn())
		elseif type(fn) == "string" then
			executorName = fn
		end
	end)

	makeSecLabel(statsScroll, "RUNTIME", 20)
	makeStatCard(statsScroll, "Executor", executorName, 21)

	
	
	
	local sessScroll = tabEntries[3].scroll

	makeSecLabel(sessScroll, "PERFORMANCE", 1)
	local pingRow   = makeStatCard(sessScroll, "Ping",    "—",  2, true)
	local fpsRow    = makeStatCard(sessScroll, "FPS",     "—",  3, true)
	local uptimeRow = makeStatCard(sessScroll, "Session", "0s", 4, true)

	makeSecLabel(sessScroll, "CHARACTER", 10)
	local healthRow = makeStatCard(sessScroll, "Health",    "—", 11, true)
	local wsRow     = makeStatCard(sessScroll, "WalkSpeed", "—", 12, true)
	local jpRow     = makeStatCard(sessScroll, "JumpPower", "—", 13, true)

	makeSecLabel(sessScroll, "SERVER", 20)
	makeStatCard(sessScroll, "Place ID", tostring(game.PlaceId),  21)
	makeStatCard(sessScroll, "Job ID",   if #jobIdFull > 14 then jobIdFull:sub(1,12) .. "…" else jobIdFull, 22)

	
	local sessionStart = os.clock()
	local pingTimer = 0; local fpsTimer = 0; local fpsCount = 0; local charTimer = 0

	local liveConn: RBXScriptConnection = RunService.Heartbeat:Connect(function(dt)
		
		if not content.Visible then return end

		fpsCount += 1; fpsTimer += dt
		if fpsTimer >= 0.5 then
			fpsRow.Text = tostring(math.round(fpsCount / fpsTimer)) .. " fps"
			fpsCount = 0; fpsTimer = 0
		end

		uptimeRow.Text = formatTime(os.clock() - sessionStart)

		pingTimer += dt
		if pingTimer >= 1.5 then
			pingTimer = 0
			local ok, ms = pcall(function()
				return math.round(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue())
			end)
			pingRow.Text = if ok then tostring(ms) .. " ms" else "—"
		end

		charTimer += dt
		if charTimer >= 0.5 then
			charTimer = 0
			pcall(function()
				local char = lp.Character; if not char then return end
				local hum = char:FindFirstChildOfClass("Humanoid"); if not hum then return end
				healthRow.Text = math.round(hum.Health) .. " / " .. math.round(hum.MaxHealth)
				wsRow.Text = tostring(hum.WalkSpeed)
				jpRow.Text = tostring(hum.JumpPower)
			end)
		end
	end)

	
	local teamConn = lp:GetPropertyChangedSignal("Team"):Connect(function()
		teamRow.Text = lp.Team and lp.Team.Name or "—"
	end)

	
	task.spawn(function()
		local ok, url = pcall(function()
			return Players:GetUserThumbnailAsync(lp.UserId, THUMB_TYPE, THUMB_SIZE)
		end)
		if ok and url then
			avatarImg.Image = url
			bigAvatar.Image = url
		end
	end)

	
	
	

	local contentVisible = false

	local function showContent()
		if contentVisible then return end
		contentVisible = true
		content.Visible = true
		selectInnerTab(1) 
		
		tween.fire(card, TweenInfo.new(0.14, Enum.EasingStyle.Quad), { BackgroundColor3 = tk.neutralHover })
		tween.fire(chevron, TweenInfo.new(0.14, Enum.EasingStyle.Quad), { TextColor3 = tk.accent })
	end

	local function hideContent()
		if not contentVisible then return end
		contentVisible = false
		content.Visible = false
		tween.fire(card, TweenInfo.new(0.14, Enum.EasingStyle.Quad), { BackgroundColor3 = tk.surface })
		tween.fire(chevron, TweenInfo.new(0.14, Enum.EasingStyle.Quad), { TextColor3 = tk.textSecondary })
	end

	
	local themeUnsub = themeUtil.subscribe(function(t)
		tk = getTokens(t)
		card.BackgroundColor3    = if contentVisible then tk.neutralHover else tk.surface
		bigRing.BackgroundColor3 = tk.accent
		dispLbl.TextColor3          = tk.textPrimary
		userLbl.TextColor3          = tk.textSecondary
		bigName.TextColor3          = tk.textPrimary
		chevron.TextColor3          = if contentVisible then tk.accent else tk.textSecondary
		tabBar.BackgroundColor3     = tk.surface
		for i, entry in ipairs(tabEntries) do
			entry.underline.BackgroundColor3 = tk.accent
			entry.btn.TextColor3 = if i == activeTabIdx then tk.accent else tk.textSecondary
		end
	end)

	
	local self: Dashboard = setmetatable({}, Dashboard) :: any
	local s = self :: any
	s._cardFrame   = card
	s._content     = content
	s._liveConn    = liveConn
	s._teamConn    = teamConn
	s._themeUnsub  = themeUnsub
	s._showContent = showContent
	s._hideContent = hideContent
	s._cardHit     = cardHit

	return self
end

function Dashboard:ShowContent()
	(self :: any)._showContent()
end

function Dashboard:HideContent()
	(self :: any)._hideContent()
end

function Dashboard:Destroy()
	local s = (self :: any)
	if s._themeUnsub then s._themeUnsub() end
	if s._liveConn   then s._liveConn:Disconnect() end
	if s._teamConn   then s._teamConn:Disconnect() end
	if s._content    then s._content:Destroy() end
	if s._cardFrame  then s._cardFrame:Destroy() end
end

return Dashboard

end)() end,[6]=function()local wax,script,require=ImportGlobals(6)local ImportGlobals return (function(...)






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

end)() end,[7]=function()local wax,script,require=ImportGlobals(7)local ImportGlobals return (function(...)






local constants = require(script.Parent.Parent.utility.constants)
local flags     = require(script.Parent.Parent.utility.flags)
local runtime   = require(script.Parent.Parent.utility.runtime)
local services  = require(script.Parent.Parent.utility.services)
local signal    = require(script.Parent.Parent.utility.signal)
local themeUtil = require(script.Parent.Parent.utility.theme)
local icons     = require(script.Parent.Parent.utility.icons)

local UserInputService = runtime.userInputService
local Players          = services.getService("Players") :: Players
local Teams            = services.getService("Teams") :: Teams

local HEADER_H        = 36
local LIST_GAP        = 4
local OPTION_H        = 34
local CHECK_W         = 20
local SEARCH_H        = 32
local MAX_H_DEFAULT   = 170



local DEFAULT_FONT       = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium)
local DEFAULT_FONT_SEMI  = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold)

export type DropdownOption = { Label: string, Value: any }

export type DropdownProps = {
	name:                    string?,
	Label:                   string?,
	Text:                    string?,
	description:             string?,
	Tooltip:                 string?,
	flag:                    string?,
	Flag:                    string?,
	options:                 { any }?,
	Options:                 { any }?,
	value:                   any?,
	default:                 any?,
	Default:                 any?,
	multiSelect:             boolean?,
	MultiSelect:             boolean?,
	placeholder:             string?,
	Placeholder:             string?,
	searchable:              boolean?,
	Searchable:              boolean?,
	disabledValues:          { any }?,
	DisabledValues:          { any }?,
	formatDisplayValue:      ((value: any) -> string)?,
	FormatDisplayValue:      ((value: any) -> string)?,
	maxVisibleDropdownItems: number?,
	MaxVisibleDropdownItems: number?,
	specialType:             string?,
	SpecialType:             string?,
	enabled:                 boolean?,
	Enabled:                 boolean?,
	layoutOrder:             number?,
	LayoutOrder:             number?,
	callback:                ((value: any) -> ())?,
	Callback:                ((value: any) -> ())?,
}

export type Dropdown = {
	value:      any,
	Value:      any,
	Changed:    any,
	_frame:     Frame,
	Set:        (self: Dropdown, value: any, skipCallback: boolean?) -> (),
	SetValue:   (self: Dropdown, value: any, skipCallback: boolean?) -> (),
	SetOptions: (self: Dropdown, options: { any }) -> (),
	SetEnabled: (self: Dropdown, enabled: boolean) -> (),
	GetFrame:   (self: Dropdown) -> Frame,
	Destroy:    (self: Dropdown) -> (),
}

local Dropdown = {}
Dropdown.__index = Dropdown



local function normalizeOptions(raw: { any }?): { DropdownOption }
	local out: { DropdownOption } = {}
	if not raw then return out end
	for _, v in ipairs(raw) do
		if typeof(v) == "string" then
			table.insert(out, { Label = v, Value = v })
		elseif typeof(v) == "table" and v.Label ~= nil and v.Value ~= nil then
			table.insert(out, v :: DropdownOption)
		else
			table.insert(out, { Label = tostring(v), Value = v })
		end
	end
	return out
end

local function normalizeDefault(raw: any): { any }
	if raw == nil then return {} end
	if typeof(raw) == "table" then return raw end
	return { raw }
end



local function getHeaderText(s: any): (string, boolean)
	if s._multiSelect then
		local labels: { string } = {}
		for _, opt in ipairs(s._options) do
			if s._selectedSet[opt.Value] then
				local display = if s._formatDisplay
					then s._formatDisplay(opt.Value)
					else opt.Label
				table.insert(labels, display)
			end
		end
		if #labels == 0 then return s._placeholder, false end
		return table.concat(labels, ", "), true
	else
		if s._selectedValue == nil then return s._placeholder, false end
		for _, opt in ipairs(s._options) do
			if opt.Value == s._selectedValue then
				local display = if s._formatDisplay
					then s._formatDisplay(opt.Value)
					else opt.Label
				return display, true
			end
		end
		return s._placeholder, false
	end
end



function Dropdown.new(props: DropdownProps, theme: { [string]: any }, parent: Instance): Dropdown
	local name = props.name or props.Label or props.Text
	local flagKey: string? = props.flag or props.Flag
	local isMulti = (props.multiSelect == true) or (props.MultiSelect == true)
	local isSearchable = (props.searchable == true) or (props.Searchable == true)
	local isEnabled = if props.enabled ~= nil then props.enabled
		elseif props.Enabled ~= nil then props.Enabled
		else true
	local callback = props.callback or props.Callback
	local placeholder = props.placeholder or props.Placeholder or (if isMulti then "None selected" else "Select...")
	local formatDisplay = props.formatDisplayValue or props.FormatDisplayValue
	local maxVisible = props.maxVisibleDropdownItems or props.MaxVisibleDropdownItems
	local maxH = if maxVisible and maxVisible > 0 then (maxVisible * OPTION_H) else MAX_H_DEFAULT
	local special = props.specialType or props.SpecialType

	
	local rawDisabled = props.disabledValues or props.DisabledValues or {}
	local disabledSet: { [any]: boolean } = {}
	for _, v in ipairs(rawDisabled) do
		disabledSet[v] = true
	end

	
	local initialOptions = props.options or props.Options or {}
	local specialConns: { RBXScriptConnection } = {}

	if special == "Player" then
		local function getPlayers(): { string }
			local pList = {}
			for _, p in ipairs(Players:GetPlayers()) do
				table.insert(pList, p.Name)
			end
			return pList
		end
		initialOptions = getPlayers()
	elseif special == "Team" then
		local function getTeams(): { string }
			local tList = {}
			for _, t in ipairs(Teams:GetTeams()) do
				table.insert(tList, t.Name)
			end
			return tList
		end
		initialOptions = getTeams()
	end

	local normOpts = normalizeOptions(initialOptions)

	
	local defaults = normalizeDefault(props.value or props.default or props.Default)
	if flagKey and flags:Get(flagKey) ~= nil then
		local stored = flags:Get(flagKey)
		defaults = normalizeDefault(stored)
	end

	local selectedSet: { [any]: boolean } = {}
	local selectedVal: any = nil
	if isMulti then
		for _, v in ipairs(defaults) do
			selectedSet[v] = true
		end
	else
		selectedVal = if #defaults > 0 then defaults[1] else nil
	end

	local hasLabel = name ~= nil and #name > 0
	local LABEL_W = 90
	local leftPad = if hasLabel then (LABEL_W + 12) else 12

	
	local frame = Instance.new("Frame")
	frame.Name = "Dropdown_" .. (name or "Element")
	frame.Size = UDim2.new(1, 0, 0, HEADER_H)
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel = 0
	frame.LayoutOrder = props.layoutOrder or props.LayoutOrder or 0
	frame.ClipsDescendants = false
	frame.Parent = parent



	
	local inner = Instance.new("Frame")
	inner.Name = "Inner"
	inner.AnchorPoint = Vector2.new(0.5, 0)
	inner.Position = UDim2.new(0.5, 0, 0, 0)
	inner.Size = UDim2.new(1, 0, 0, HEADER_H)
	inner.BackgroundColor3 = Color3.new(1, 1, 1)
	inner.BorderSizePixel = 0
	inner.ZIndex = 2
	inner.Parent = frame

	local innerGrad = Instance.new("UIGradient")
	innerGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromHex("#2e2e2e")),
		ColorSequenceKeypoint.new(1, Color3.fromHex("#181818")),
	})
	innerGrad.Rotation = 90
	innerGrad.Parent = inner

	local innerCorner = Instance.new("UICorner")
	innerCorner.CornerRadius = UDim.new(0, 6)
	innerCorner.Parent = inner

	local stroke = Instance.new("UIStroke")
	stroke.Color = theme.ElementStroke or Color3.fromHex("#2b2b2b")
	stroke.Thickness = 1
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = inner

	local innerPad = Instance.new("UIPadding")
	innerPad.PaddingLeft = UDim.new(0, leftPad)
	innerPad.PaddingRight = UDim.new(0, 12)
	innerPad.Parent = inner

	local flash = Instance.new("Frame")
	flash.Name = "Flash"
	flash.Size = UDim2.new(1, leftPad + 12, 1, 0)
	flash.Position = UDim2.new(0, -leftPad, 0, 0)
	flash.BackgroundColor3 = Color3.new(1, 1, 1)
	flash.BackgroundTransparency = 1
	flash.BorderSizePixel = 0
	flash.ZIndex = 3

	local flashCorner = Instance.new("UICorner")
	flashCorner.CornerRadius = UDim.new(0, 6)
	flashCorner.Parent = flash
	flash.Parent = inner

	local ARROW_W = 16
	local MULTI_W = 14
	local arrow = Instance.new("ImageLabel")
	arrow.Name = "Arrow"
	arrow.AnchorPoint = Vector2.new(1, 0.5)
	arrow.Position = UDim2.new(1, 0, 0.5, 0)
	arrow.Size = UDim2.fromOffset(ARROW_W, ARROW_W)
	arrow.BackgroundTransparency = 1
	arrow.Image = icons.Resolve("lucide:chevron-down") or "rbxassetid://88479147175134"
	arrow.ImageColor3 = theme.PlaceholderColor or Color3.fromHex("#9d9d9d")
	arrow.Rotation = 0
	arrow.ZIndex = 4
	arrow.Parent = inner

	local multiIcon: ImageLabel? = nil
	if isMulti then
		local mico = Instance.new("ImageLabel")
		mico.Name = "MultiIcon"
		mico.AnchorPoint = Vector2.new(1, 0.5)
		mico.Position = UDim2.new(1, -(ARROW_W + 6), 0.5, 0)
		mico.Size = UDim2.fromOffset(MULTI_W, MULTI_W)
		mico.BackgroundTransparency = 1
		mico.Image = icons.Resolve("lucide:layers") or icons.Resolve("lucide:list-checks") or "rbxassetid://83827110621355"
		mico.ImageColor3 = theme.PlaceholderColor or Color3.fromHex("#9d9d9d")
		mico.ImageTransparency = 0.3
		mico.ZIndex = 4
		mico.Parent = inner
		multiIcon = mico
	end

	local rightReserve = ARROW_W + (if isMulti then (MULTI_W + 10) else 8)
	local valueLabel = Instance.new("TextLabel")
	valueLabel.Name = "ValueLabel"
	valueLabel.Size = UDim2.new(1, -rightReserve, 1, 0)
	valueLabel.BackgroundTransparency = 1
	valueLabel.Font = Enum.Font.GothamMedium
	valueLabel.FontFace = theme.Font or Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium)
	valueLabel.TextSize = 12
	valueLabel.TextXAlignment = Enum.TextXAlignment.Right
	valueLabel.TextTruncate = Enum.TextTruncate.AtEnd
	valueLabel.ZIndex = 4
	valueLabel.Parent = inner

	local outerLabel: TextLabel? = nil
	if hasLabel then
		local lbl = Instance.new("TextLabel")
		lbl.Name = "Label"
		lbl.Position = UDim2.fromOffset(12, 0)
		lbl.Size = UDim2.fromOffset(LABEL_W, HEADER_H)
		lbl.BackgroundTransparency = 1
		lbl.Font = Enum.Font.GothamMedium
		lbl.FontFace = theme.Font or Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium)
		lbl.Text = name :: string
		lbl.TextSize = 13
		lbl.TextColor3 = if isEnabled then (theme.ContentColor or Color3.fromHex("#ffffff")) else Color3.fromHex("#555555")
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.TextTruncate = Enum.TextTruncate.AtEnd
		lbl.ZIndex = 4
		lbl.Parent = frame
		outerLabel = lbl
	end

	local hit = Instance.new("TextButton")
	hit.Name = "Hit"
	hit.Size = UDim2.fromScale(1, 1)
	hit.BackgroundTransparency = 1
	hit.Text = ""
	hit.AutoButtonColor = false
	hit.ZIndex = 5
	hit.Parent = inner

	
	local listWrap = Instance.new("Frame")
	listWrap.Name = "ListWrap"
	listWrap.Position = UDim2.new(0, 0, 0, HEADER_H + LIST_GAP)
	listWrap.Size = UDim2.new(1, 0, 0, 0)
	listWrap.BackgroundColor3 = Color3.fromHex("#1a1a1a")
	listWrap.BackgroundTransparency = 1
	listWrap.BorderSizePixel = 0
	listWrap.ClipsDescendants = true
	listWrap.Visible = false
	listWrap.ZIndex = 2

	local listCorner = Instance.new("UICorner")
	listCorner.CornerRadius = UDim.new(0, 6)
	listCorner.Parent = listWrap

	local listStroke = Instance.new("UIStroke")
	listStroke.Color = theme.ElementStroke or Color3.fromHex("#2b2b2b")
	listStroke.Thickness = 1
	listStroke.Transparency = 1
	listStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	listStroke.Parent = listWrap
	listWrap.Parent = frame

	
	local searchBox: TextBox? = nil
	if isSearchable then
		local searchBar = Instance.new("Frame")
		searchBar.Name = "SearchBar"
		searchBar.Size = UDim2.new(1, 0, 0, SEARCH_H)
		searchBar.BackgroundColor3 = Color3.fromHex("#1e1e1e")
		searchBar.BackgroundTransparency = 0
		searchBar.BorderSizePixel = 0
		searchBar.ZIndex = 4
		searchBar.Parent = listWrap

		local searchPad = Instance.new("UIPadding")
		searchPad.PaddingLeft = UDim.new(0, 12)
		searchPad.PaddingRight = UDim.new(0, 12)
		searchPad.PaddingTop = UDim.new(0, 5)
		searchPad.PaddingBottom = UDim.new(0, 5)
		searchPad.Parent = searchBar

		local searchInner = Instance.new("Frame")
		searchInner.Name = "SearchInner"
		searchInner.Size = UDim2.fromScale(1, 1)
		searchInner.BackgroundColor3 = Color3.fromHex("#2a2a2a")
		searchInner.BorderSizePixel = 0
		searchInner.ZIndex = 4
		searchInner.Parent = searchBar

		local searchCorner = Instance.new("UICorner")
		searchCorner.CornerRadius = UDim.new(0, 6)
		searchCorner.Parent = searchInner

		local searchStroke = Instance.new("UIStroke")
		searchStroke.Color = theme.ElementStroke or Color3.fromHex("#2b2b2b")
		searchStroke.Thickness = 1
		searchStroke.Transparency = 0.4
		searchStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		searchStroke.Parent = searchInner

		local searchIcon = Instance.new("TextLabel")
		searchIcon.Name = "SearchIcon"
		searchIcon.Size = UDim2.fromOffset(16, 16)
		searchIcon.AnchorPoint = Vector2.new(0, 0.5)
		searchIcon.Position = UDim2.new(0, 6, 0.5, 0)
		searchIcon.BackgroundTransparency = 1
		searchIcon.Font = Enum.Font.GothamMedium
		searchIcon.Text = "⌕"
		searchIcon.TextSize = 13
		searchIcon.TextColor3 = theme.PlaceholderColor or Color3.fromHex("#9d9d9d")
		searchIcon.ZIndex = 5
		searchIcon.Parent = searchInner

		local sb = Instance.new("TextBox")
		sb.Name = "SearchBox"
		sb.Size = UDim2.new(1, -26, 1, 0)
		sb.Position = UDim2.fromOffset(24, 0)
		sb.BackgroundTransparency = 1
		sb.BorderSizePixel = 0
		sb.Font = Enum.Font.GothamMedium
		sb.PlaceholderText = "Search..."
		sb.PlaceholderColor3 = Color3.fromHex("#555555")
		sb.Text = ""
		sb.TextSize = 12
		sb.TextColor3 = theme.ContentColor or Color3.fromHex("#ffffff")
		sb.TextXAlignment = Enum.TextXAlignment.Left
		sb.ClearTextOnFocus = false
		sb.ZIndex = 5
		sb.Parent = searchInner
		searchBox = sb

		local sep = Instance.new("Frame")
		sep.Name = "SearchSep"
		sep.Size = UDim2.new(1, 0, 0, 1)
		sep.Position = UDim2.new(0, 0, 0, SEARCH_H)
		sep.BackgroundColor3 = theme.ElementStroke or Color3.fromHex("#2b2b2b")
		sep.BackgroundTransparency = 0.5
		sep.BorderSizePixel = 0
		sep.ZIndex = 4
		sep.Parent = listWrap
	end

	
	local scrollTopOffset = if isSearchable then SEARCH_H else 0

	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "OptionScroll"
	scroll.Position = UDim2.fromOffset(0, scrollTopOffset)
	scroll.Size = UDim2.new(1, 0, 1, -scrollTopOffset)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 3
	scroll.ScrollBarImageColor3 = theme.ElementStroke or Color3.fromHex("#2b2b2b")
	scroll.CanvasSize = UDim2.fromOffset(0, 0)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.None
	scroll.ClipsDescendants = true
	scroll.ZIndex = 3
	scroll.Parent = listWrap

	local listLayout = Instance.new("UIListLayout")
	listLayout.FillDirection = Enum.FillDirection.Vertical
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Padding = UDim.new(0, 0)
	listLayout.Parent = scroll

	local self = setmetatable({}, Dropdown) :: Dropdown
	self._frame = frame
	self.Changed = signal.new()

	local initVal: any = if isMulti then {} else nil
	if isMulti then
		local arr = {}
		for _, o in ipairs(normOpts) do
			if selectedSet[o.Value] then table.insert(arr, o.Value) end
		end
		initVal = arr
	else
		initVal = selectedVal
	end
	self.value = initVal
	self.Value = initVal

	
	local s = self :: any
	s._enabled = isEnabled
	s._open = false
	s._multiSelect = isMulti
	s._searchEnabled = isSearchable
	s._searchQuery = ""
	s._formatDisplay = formatDisplay
	s._maxH = maxH
	s._targetH = 0
	s._placeholder = placeholder
	s._options = normOpts
	s._selectedSet = selectedSet
	s._selectedValue = selectedVal
	s._disabledSet = disabledSet
	s._flag = flagKey
	s._callback = callback
	s._theme = theme

	s._frame = frame
	s._inner = inner
	s._listWrap = listWrap
	s._listStroke = listStroke
	s._scroll = scroll
	s._arrow = arrow
	s._valueLabel = valueLabel
	s._outerLabel = outerLabel
	s._stroke = stroke
	s._flash = flash
	s._searchBox = searchBox
	s._conns = {} :: { [string]: RBXScriptConnection }
	s._optConns = {} :: { RBXScriptConnection }
	s._specialConns = specialConns

	
	local function getListH(): number
		return s._targetH + (if s._searchEnabled then SEARCH_H else 0)
	end

	local function closeDropdown()
		if not s._open then return end
		s._open = false
		s._flipUp = false
		if s._searchEnabled and s._searchBox then
			s._searchBox.Text = ""
			s._searchQuery = ""
		end

		
		arrow.Rotation = 0
		stroke.Color = s._theme.ElementStroke or Color3.fromHex("#2b2b2b")
		listWrap.Visible = false
		listWrap.Size = UDim2.new(1, 0, 0, 0)
		listWrap.Position = UDim2.new(0, 0, 0, HEADER_H + LIST_GAP)
		listWrap.BackgroundTransparency = 1
		listStroke.Transparency = 1
		frame.Size = UDim2.new(1, 0, 0, HEADER_H)
		
		frame.ZIndex = s._originalZIndex or 1
		s._originalZIndex = nil
	end

	local function openDropdown()
		if s._open or not s._enabled then return end
		s._open = true
		local fullH = getListH()

		
		
		
		
		local flipUp = false
		do
			local clipAncestor: GuiObject? = nil
			do
				local p: Instance? = frame.Parent
				while p ~= nil and not p:IsA("ScreenGui") do
					if p:IsA("GuiObject") and (p :: GuiObject).ClipsDescendants then
						clipAncestor = p :: GuiObject
						break
					end
					p = p.Parent
				end
			end

			local boundaryTop: number
			local boundaryBottom: number
			if clipAncestor then
				boundaryTop    = clipAncestor.AbsolutePosition.Y
				boundaryBottom = clipAncestor.AbsolutePosition.Y + clipAncestor.AbsoluteSize.Y
			else
				
				local pf = frame.Parent
				if pf and pf:IsA("GuiObject") then
					local g = pf :: GuiObject
					boundaryTop    = g.AbsolutePosition.Y
					boundaryBottom = g.AbsolutePosition.Y + g.AbsoluteSize.Y
				else
					boundaryTop    = 0
					boundaryBottom = math.huge
				end
			end

			local frameBottom = frame.AbsolutePosition.Y + HEADER_H + LIST_GAP + fullH
			local spaceAbove  = frame.AbsolutePosition.Y - boundaryTop
			if frameBottom > boundaryBottom and spaceAbove >= fullH + LIST_GAP then
				flipUp = true
			end
		end

		
		
		if not s._originalZIndex then
			s._originalZIndex = frame.ZIndex
		end
		frame.ZIndex = 32766

		s._flipUp = flipUp
		if flipUp then
			
			listWrap.Position = UDim2.new(0, 0, 0, -(fullH + LIST_GAP))
		else
			listWrap.Position = UDim2.new(0, 0, 0, HEADER_H + LIST_GAP)
		end

		
		arrow.Rotation = 180
		stroke.Color = s._theme.AccentColor or Color3.fromHex("#4cc2ff")
		listWrap.Visible = true
		listWrap.Size = UDim2.new(1, 0, 0, fullH)
		listWrap.BackgroundTransparency = 0
		listStroke.Transparency = 0
		
		
		if flipUp then
			frame.Size = UDim2.new(1, 0, 0, HEADER_H)
		else
			frame.Size = UDim2.new(1, 0, 0, HEADER_H + LIST_GAP + fullH)
		end

		if s._searchEnabled and s._searchBox then
			task.defer(function()
				if s._open and s._searchBox then
					local isTouchOnly = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
					if not isTouchOnly then
						s._searchBox:CaptureFocus()
					end
				end
			end)
		end
	end

	s._openDropdown = openDropdown
	s._closeDropdown = closeDropdown

	
	local function buildOptions()
		for _, c in ipairs(s._optConns) do c:Disconnect() end
		table.clear(s._optConns)
		for _, child in ipairs(scroll:GetChildren()) do
			if child:IsA("Frame") then child:Destroy() end
		end

		local query = s._searchQuery or ""
		local filtered: { DropdownOption } = {}
		for _, opt in ipairs(s._options) do
			if query == "" or string.find(opt.Label:lower(), query, 1, true) then
				table.insert(filtered, opt)
			end
		end

		local optCount = #filtered
		local fullH = optCount * OPTION_H
		scroll.CanvasSize = UDim2.fromOffset(0, fullH)
		s._targetH = math.min(fullH, s._maxH)

		if s._open then
			local panelH = getListH()
			listWrap.Size = UDim2.new(1, 0, 0, panelH)
			frame.Size = UDim2.new(1, 0, 0, HEADER_H + LIST_GAP + panelH)
		end

		for i, opt in ipairs(filtered) do
			local isSelected = if s._multiSelect
				then s._selectedSet[opt.Value] == true
				else s._selectedValue == opt.Value
			local isDisabled = s._disabledSet[opt.Value] == true

			local optFrame = Instance.new("Frame")
			optFrame.Name = "Option_" .. i
			optFrame.Size = UDim2.new(1, 0, 0, OPTION_H)
			optFrame.BackgroundColor3 = Color3.fromHex("#1a1a1a")
			optFrame.BackgroundTransparency = 1
			optFrame.BorderSizePixel = 0
			optFrame.LayoutOrder = i
			optFrame.ZIndex = 3

			local checkLabel: any = nil
			if s._multiSelect then
				local ck = Instance.new("ImageLabel")
				ck.Name = "Check"
				ck.Size = UDim2.fromOffset(14, 14)
				ck.AnchorPoint = Vector2.new(0.5, 0.5)
				ck.Position = UDim2.new(0, 4 + CHECK_W / 2, 0.5, 0)
				ck.BackgroundTransparency = 1
				ck.Image = if isSelected
					then (icons.Resolve("lucide:square-check") or "rbxassetid://0")
					else (icons.Resolve("lucide:square") or "rbxassetid://0")
				ck.ImageColor3 = if isDisabled
					then Color3.fromHex("#555555")
					else if isSelected
						then (s._theme.AccentColor or Color3.fromHex("#4cc2ff"))
						else Color3.fromHex("#555555")
				ck.ZIndex = 4
				ck.Parent = optFrame
				checkLabel = ck
			end

			local labelXOffset = if s._multiSelect then (CHECK_W + 4) else 12
			local labelWOffset = if s._multiSelect then -(CHECK_W + 16) else -24

			local displayText = if s._formatDisplay
				then s._formatDisplay(opt.Value)
				else opt.Label

			local textColor = if isDisabled
				then Color3.fromHex("#555555")
				elseif isSelected then (s._theme.AccentColor or Color3.fromHex("#4cc2ff"))
				else (s._theme.PlaceholderColor or Color3.fromHex("#9d9d9d"))

			local optLabel = Instance.new("TextLabel")
			optLabel.Name = "OptionLabel"
			optLabel.Size = UDim2.new(1, labelWOffset, 1, 0)
			optLabel.Position = UDim2.fromOffset(labelXOffset, 0)
			optLabel.BackgroundTransparency = 1
			optLabel.Font = Enum.Font.GothamMedium
			optLabel.FontFace = s._theme.Font or Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium)
			optLabel.Text = displayText
			optLabel.TextSize = 12
			optLabel.TextColor3 = textColor
			optLabel.TextXAlignment = if s._multiSelect then Enum.TextXAlignment.Left else Enum.TextXAlignment.Center
			optLabel.TextTruncate = Enum.TextTruncate.AtEnd
			optLabel.ZIndex = 4
			optLabel.Parent = optFrame

			if isDisabled then
				local disabledTag = Instance.new("TextLabel")
				disabledTag.Name = "DisabledTag"
				disabledTag.AnchorPoint = Vector2.new(1, 0.5)
				disabledTag.Position = UDim2.new(1, -8, 0.5, 0)
				disabledTag.Size = UDim2.fromOffset(36, 14)
				disabledTag.BackgroundColor3 = Color3.fromHex("#2a2a2a")
				disabledTag.BorderSizePixel = 0
				disabledTag.Font = Enum.Font.GothamMedium
				disabledTag.Text = "off"
				disabledTag.TextSize = 9
				disabledTag.TextColor3 = Color3.fromHex("#555555")
				disabledTag.TextXAlignment = Enum.TextXAlignment.Center
				disabledTag.ZIndex = 4

				local dtCorner = Instance.new("UICorner")
				dtCorner.CornerRadius = UDim.new(1, 0)
				dtCorner.Parent = disabledTag
				disabledTag.Parent = optFrame
			end

			if i < optCount then
				local sep = Instance.new("Frame")
				sep.Size = UDim2.new(1, -24, 0, 1)
				sep.Position = UDim2.new(0, 12, 1, -1)
				sep.BackgroundColor3 = s._theme.ElementStroke or Color3.fromHex("#2b2b2b")
				sep.BackgroundTransparency = 0.7
				sep.BorderSizePixel = 0
				sep.ZIndex = 4
				sep.Parent = optFrame
			end

			local optHit = Instance.new("TextButton")
			optHit.Name = "Hit"
			optHit.Size = UDim2.fromScale(1, 1)
			optHit.BackgroundTransparency = 1
			optHit.Text = ""
			optHit.AutoButtonColor = false
			optHit.ZIndex = 5
			optHit.Parent = optFrame

			if not isDisabled then
				table.insert(s._optConns, optHit.MouseEnter:Connect(function()
					optFrame.BackgroundTransparency = 0.85
					optFrame.BackgroundColor3 = Color3.fromHex("#252525")
					local isSel = if s._multiSelect
						then s._selectedSet[opt.Value] == true
						else s._selectedValue == opt.Value
					if not isSel then
						optLabel.TextColor3 = s._theme.ContentColor or Color3.fromHex("#ffffff")
					end
				end))

				table.insert(s._optConns, optHit.MouseLeave:Connect(function()
					optFrame.BackgroundTransparency = 1
					optFrame.BackgroundColor3 = Color3.fromHex("#1a1a1a")
					local isSel = if s._multiSelect
						then s._selectedSet[opt.Value] == true
						else s._selectedValue == opt.Value
					if not isSel then
						optLabel.TextColor3 = s._theme.PlaceholderColor or Color3.fromHex("#9d9d9d")
					end
				end))

				table.insert(s._optConns, optHit.MouseButton1Click:Connect(function()
					if not s._enabled then return end

					if s._multiSelect then
						if s._selectedSet[opt.Value] then
						s._selectedSet[opt.Value] = nil
						optLabel.TextColor3 = s._theme.PlaceholderColor or Color3.fromHex("#9d9d9d")
						if checkLabel then
						  (checkLabel :: ImageLabel).Image = icons.Resolve("lucide:square") or "rbxassetid://0"
						 (checkLabel :: ImageLabel).ImageColor3 = Color3.fromHex("#555555")
						end
						else
						 s._selectedSet[opt.Value] = true
						optLabel.TextColor3 = s._theme.AccentColor or Color3.fromHex("#4cc2ff")
						if checkLabel then
							(checkLabel :: ImageLabel).Image = icons.Resolve("lucide:square-check") or "rbxassetid://0"
							(checkLabel :: ImageLabel).ImageColor3 = s._theme.AccentColor or Color3.fromHex("#4cc2ff")
						end
					end
						local arr: { any } = {}
						for _, o in ipairs(s._options) do
							if s._selectedSet[o.Value] then
								table.insert(arr, o.Value)
							end
						end
						self.value = arr
						self.Value = arr

						local txt, has = getHeaderText(s)
						valueLabel.Text = txt
						valueLabel.TextColor3 = if has
							then (s._theme.ContentColor or Color3.fromHex("#ffffff"))
							else Color3.fromHex("#555555")

						if flagKey then flags:Set(flagKey, arr) end
						self.Changed:Fire(arr)
						if callback then task.spawn(callback, arr) end
					else
						for _, ch in ipairs(scroll:GetChildren()) do
							if ch:IsA("Frame") then
								local lbl = ch:FindFirstChild("OptionLabel")
								if lbl and lbl:IsA("TextLabel") then
									lbl.TextColor3 = s._theme.PlaceholderColor or Color3.fromHex("#9d9d9d")
								end
							end
						end
						optLabel.TextColor3 = s._theme.AccentColor or Color3.fromHex("#4cc2ff")
						s._selectedValue = opt.Value
						self.value = opt.Value
						self.Value = opt.Value

						local txt, has = getHeaderText(s)
						valueLabel.Text = txt
						valueLabel.TextColor3 = if has
							then (s._theme.ContentColor or Color3.fromHex("#ffffff"))
							else Color3.fromHex("#555555")

						if flagKey then flags:Set(flagKey, opt.Value) end
						self.Changed:Fire(opt.Value)
						if callback then task.spawn(callback, opt.Value) end

						closeDropdown()
					end
				end))
			end

			optFrame.Parent = scroll
		end
	end

	s._buildOptions = buildOptions
	buildOptions()

	local initTxt, initHas = getHeaderText(s)
	valueLabel.Text = initTxt
	valueLabel.TextColor3 = if initHas
		then (theme.ContentColor or Color3.fromHex("#ffffff"))
		else Color3.fromHex("#555555")

	if searchBox then
		s._conns.search = searchBox:GetPropertyChangedSignal("Text"):Connect(function()
			s._searchQuery = searchBox.Text:lower()
			buildOptions()
		end)
	end

	
	local hovering = false

	s._conns.hitEnter = hit.MouseEnter:Connect(function()
		if not s._enabled then return end
		hovering = true
		stroke.Color = s._theme.AccentColor or Color3.fromHex("#4cc2ff")
		flash.BackgroundTransparency = 0.92
	end)

	s._conns.hitLeave = hit.MouseLeave:Connect(function()
		if not s._enabled then return end
		hovering = false
		if not s._open then
			stroke.Color = s._theme.ElementStroke or Color3.fromHex("#2b2b2b")
		end
		flash.BackgroundTransparency = 1
	end)

	s._conns.hitClick = hit.MouseButton1Click:Connect(function()
		if not s._enabled then return end
		if s._open then
			closeDropdown()
		else
			openDropdown()
		end
	end)

	
	s._conns.outsideClick = UserInputService.InputBegan:Connect(function(input: InputObject)
		if not s._open then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			local mousePos = input.Position
			local ap = frame.AbsolutePosition
			local as = frame.AbsoluteSize
			local inX = mousePos.X >= ap.X and mousePos.X <= (ap.X + as.X)
			local inY: boolean
			if s._flipUp then
				
				
				
				local listH = getListH()
				local topY = ap.Y - listH - LIST_GAP
				inY = mousePos.Y >= topY and mousePos.Y <= (ap.Y + HEADER_H)
			else
				inY = mousePos.Y >= ap.Y and mousePos.Y <= (ap.Y + as.Y)
			end
			if not (inX and inY) then
				closeDropdown()
			end
		end
	end)

	
	if special == "Player" then
		table.insert(specialConns, Players.PlayerAdded:Connect(function()
			local pList = {}
			for _, p in ipairs(Players:GetPlayers()) do table.insert(pList, p.Name) end
			self:SetOptions(pList)
		end))
		table.insert(specialConns, Players.PlayerRemoving:Connect(function()
			local pList = {}
			for _, p in ipairs(Players:GetPlayers()) do table.insert(pList, p.Name) end
			self:SetOptions(pList)
		end))
	elseif special == "Team" then
		table.insert(specialConns, Teams.ChildAdded:Connect(function()
			local tList = {}
			for _, t in ipairs(Teams:GetTeams()) do table.insert(tList, t.Name) end
			self:SetOptions(tList)
		end))
		table.insert(specialConns, Teams.ChildRemoved:Connect(function()
			local tList = {}
			for _, t in ipairs(Teams:GetTeams()) do table.insert(tList, t.Name) end
			self:SetOptions(tList)
		end))
	end

	s._themeUnsub = themeUtil.subscribe(function(t)
		s._theme = t
		stroke.Color = if s._open or hovering
			then (t.AccentColor or Color3.fromHex("#4cc2ff"))
			else (t.ElementStroke or Color3.fromHex("#2b2b2b"))
		if outerLabel then
			outerLabel.TextColor3 = if s._enabled
				then (t.ContentColor or Color3.fromHex("#ffffff"))
				else Color3.fromHex("#555555")
			
			outerLabel.FontFace = t.Font or DEFAULT_FONT
		end
		
		valueLabel.FontFace = t.Font or DEFAULT_FONT
		arrow.ImageColor3 = t.PlaceholderColor or Color3.fromHex("#9d9d9d")
		if multiIcon then
			multiIcon.ImageColor3 = t.PlaceholderColor or Color3.fromHex("#9d9d9d")
		end
		listStroke.Color = t.ElementStroke or Color3.fromHex("#2b2b2b")
		innerGrad.Color = t.ElementGradient or ColorSequence.new(Color3.fromRGB(28, 24, 44))
		
		
		
		
		if s._open then
			buildOptions()
		end
	end)

	if flagKey and flagKey ~= "" then
		flags:Set(flagKey, initVal)
	end

	return self
end



function Dropdown:SetOptions(options: { any })
	local s = self :: any
	if s._open then
		s._closeDropdown()
	end

	s._options = normalizeOptions(options)

	if s._multiSelect then
		local newSet: { [any]: boolean } = {}
		for _, opt in ipairs(s._options) do
			if s._selectedSet[opt.Value] then
				newSet[opt.Value] = true
			end
		end
		s._selectedSet = newSet
		local arr: { any } = {}
		for _, opt in ipairs(s._options) do
			if s._selectedSet[opt.Value] then table.insert(arr, opt.Value) end
		end
		self.value = arr
		self.Value = arr
	else
		local found = false
		for _, opt in ipairs(s._options) do
			if opt.Value == s._selectedValue then found = true break end
		end
		if not found then
			s._selectedValue = nil
			self.value = nil
			self.Value = nil
		end
	end

	local txt, has = getHeaderText(s)
	s._valueLabel.Text = txt
	s._valueLabel.TextColor3 = if has
		then (s._theme.ContentColor or Color3.fromHex("#ffffff"))
		else Color3.fromHex("#555555")

	s._buildOptions()
end

function Dropdown:Set(value: any, skipCallback: boolean?)
	local s = self :: any

	if s._multiSelect then
		s._selectedSet = {}
		local outArr: { any } = {}
		if typeof(value) == "table" then
			for k, v in pairs(value) do
				if typeof(k) == "number" then
					
					s._selectedSet[v] = true
					table.insert(outArr, v)
				elseif v == true then
					
					s._selectedSet[k] = true
					table.insert(outArr, k)
				end
			end
		elseif value ~= nil then
			s._selectedSet[value] = true
			table.insert(outArr, value)
		end
		self.value = outArr
		self.Value = outArr
	else
		local matchVal: any = nil
		for _, opt in ipairs(s._options) do
			if opt.Value == value or opt.Label == value or tostring(opt.Value) == tostring(value) then
				matchVal = opt.Value
				break
			end
		end
		s._selectedValue = if matchVal ~= nil then matchVal else value
		self.value = s._selectedValue
		self.Value = s._selectedValue
	end

	local txt, has = getHeaderText(s)
	s._valueLabel.Text = txt
	s._valueLabel.TextColor3 = if has
		then (s._theme.ContentColor or Color3.fromHex("#ffffff"))
		else Color3.fromHex("#555555")

	s._buildOptions()

	if s._flag then
		flags:Set(s._flag, self.value)
	end
	self.Changed:Fire(self.value)
	if not skipCallback and s._callback then
		task.spawn(s._callback, self.value)
	end
end

function Dropdown:SetValue(value: any, skipCallback: boolean?)
	self:Set(value, skipCallback)
end

function Dropdown:SetEnabled(enabled: boolean)
	local s = self :: any
	s._enabled = enabled
	s._stroke.Transparency = if enabled then 0 else 0.5
	if s._outerLabel then
		s._outerLabel.TextColor3 = if enabled
			then (s._theme.ContentColor or Color3.fromHex("#ffffff"))
			else Color3.fromHex("#555555")
	end
	if not enabled and s._open then
		s._closeDropdown()
	end
end

function Dropdown:GetFrame(): Frame
	return self._frame
end

function Dropdown:Destroy()
	local s = self :: any
	if s._themeUnsub then s._themeUnsub() end
	if s._conns then
		for _, conn in s._conns do conn:Disconnect() end
		table.clear(s._conns)
	end
	if s._optConns then
		for _, conn in s._optConns do conn:Disconnect() end
		table.clear(s._optConns)
	end
	if s._specialConns then
		for _, conn in s._specialConns do conn:Disconnect() end
		table.clear(s._specialConns)
	end
	self.Changed:Destroy()
	self._frame:Destroy()
end

return Dropdown

end)() end,[8]=function()local wax,script,require=ImportGlobals(8)local ImportGlobals return (function(...)







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
	local callback     = props.callback
	local hasDesc      = desc ~= ""

	local initValue: string
	if flagKey and flags:Get(flagKey) ~= nil then
		initValue = tostring(flags:Get(flagKey))
	else
		initValue = props.value or ""
	end

	local frame, stroke, gradient = element.makeFrame("Input_" .. name, theme, parent, constants.elementHeight)

	
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
	pillCorner.CornerRadius = UDim.new(1, 0) 
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
	textBox.TextTransparency       = 0.4 
	textBox.BorderSizePixel        = 0
	textBox.ZIndex                 = 3
	textBox.Parent                 = pill

	
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
			tween.fire(stroke, constants.tweenFast, {
				Color = theme.ElementStroke or Color3.fromHex("#2b2b2b"),
			})
			tween.fire(pillStroke, constants.tweenFast, {
				Color = theme.ElementStroke or Color3.fromHex("#2b2b2b"),
				Transparency = 0.5,
			})
		end
	end)

	
	hitBtn.MouseButton1Click:Connect(function()
		textBox:CaptureFocus()
	end)

	
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
			if n then
				raw = tostring(n)
			else
				raw = self.value
			end
			textBox.Text = raw
		end

		self:Set(raw, not enterPressed)

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
	end)

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

end)() end,[9]=function()local wax,script,require=ImportGlobals(9)local ImportGlobals return (function(...)








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


local activeRecordingKeybind: any = nil


local function isInside(pos: Vector2, guiObj: GuiObject): boolean
	local min = guiObj.AbsolutePosition
	local max = min + guiObj.AbsoluteSize
	return pos.X >= min.X and pos.X <= max.X and pos.Y >= min.Y and pos.Y <= max.Y
end


local mouseNames: { [EnumItem]: string } = {
	[Enum.UserInputType.MouseButton1] = "MB1",
	[Enum.UserInputType.MouseButton2] = "MB2",
	[Enum.UserInputType.MouseButton3] = "MB3",
}


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
	pill.TextTransparency       = 0.3 
	pill.AutoButtonColor        = false
	pill.Active                 = true
	pill.ZIndex                 = 3
	pill.Parent                 = frame

	local pillCorner = Instance.new("UICorner")
	pillCorner.CornerRadius = UDim.new(1, 0) 
	pillCorner.Parent       = pill

	local pillStroke = Instance.new("UIStroke")
	pillStroke.Color           = theme.ElementStroke or Color3.fromHex("#2b2b2b")
	pillStroke.Thickness       = 1
	pillStroke.Transparency    = 0.4
	pillStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	pillStroke.Parent          = pill

	
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

	
	local hovering = false

	
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
				
				
				
				
				
				suppressNextClick = true
				stopRecording()
				self:Set(Enum.UserInputType.MouseButton1)
				return
			end
			return
		end

		if gameProcessed then return end

		
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

end)() end,[10]=function()local wax,script,require=ImportGlobals(10)local ImportGlobals return (function(...)





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
	local richText  = props.richText ~= false and true  
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

end)() end,[11]=function()local wax,script,require=ImportGlobals(11)local ImportGlobals return (function(...)











local TweenService = game:GetService("TweenService")
local RunService   = game:GetService("RunService")
local Players      = game:GetService("Players")

local FONT_BOLD = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold)
local FONT_MED  = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium)
local FONT_SEMI = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold)

local TW_IN   = TweenInfo.new(0.28, Enum.EasingStyle.Quad,  Enum.EasingDirection.Out)
local TW_OUT  = TweenInfo.new(0.40, Enum.EasingStyle.Quad,  Enum.EasingDirection.In)
local TW_BAR  = TweenInfo.new(0.45, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local TW_SNAP = TweenInfo.new(0.15, Enum.EasingStyle.Quad,  Enum.EasingDirection.Out)

export type LoadingScreenProps = {
	title:    string?,   
	accent:   Color3?,   
}

export type LoadingScreen = {
	
	setProgress: (self: LoadingScreen, label: string, pct: number) -> (),
	
	dismiss:     (self: LoadingScreen) -> (),
}

local LoadingScreen = {}
LoadingScreen.__index = LoadingScreen



function LoadingScreen.new(props: LoadingScreenProps): LoadingScreen
	local title  = props.title  or "Delirium"
	local accent = props.accent or Color3.fromHex("#4cc2ff")

	
	local gui = Instance.new("ScreenGui")
	gui.Name           = "DeliriumLoading"
	gui.DisplayOrder   = 100010        
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn   = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent         = Players.LocalPlayer:WaitForChild("PlayerGui")

	
	local bg = Instance.new("Frame")
	bg.Name                   = "Bg"
	bg.Size                   = UDim2.fromScale(1, 1)
	bg.BackgroundColor3       = Color3.fromHex("#08080b")
	bg.BackgroundTransparency = 1          
	bg.BorderSizePixel        = 0
	bg.ZIndex                 = 1
	bg.Parent                 = gui

	
	local glow = Instance.new("Frame")
	glow.Name                   = "Glow"
	glow.AnchorPoint            = Vector2.new(0.5, 0.5)
	glow.Position               = UDim2.fromScale(0.5, 0.5)
	glow.Size                   = UDim2.fromOffset(480, 480)
	glow.BackgroundColor3       = accent
	glow.BackgroundTransparency = 0.965
	glow.BorderSizePixel        = 0
	glow.ZIndex                 = 2
	glow.Parent                 = bg
	do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1, 0); c.Parent = glow end

	
	local topStrip = Instance.new("Frame")
	topStrip.Name             = "TopStrip"
	topStrip.AnchorPoint      = Vector2.new(0.5, 0)
	topStrip.Position         = UDim2.fromScale(0.5, 0)
	topStrip.Size             = UDim2.new(0, 0, 0, 1)   
	topStrip.BackgroundColor3 = accent
	topStrip.BorderSizePixel  = 0
	topStrip.ZIndex           = 10
	topStrip.Parent           = bg
	do
		local g = Instance.new("UIGradient")
		g.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0.00, 1),
			NumberSequenceKeypoint.new(0.10, 0),
			NumberSequenceKeypoint.new(0.90, 0),
			NumberSequenceKeypoint.new(1.00, 1),
		})
		g.Parent = topStrip
	end

	
	local container = Instance.new("Frame")
	container.Name                   = "Container"
	container.AnchorPoint            = Vector2.new(0.5, 0.5)
	container.Position               = UDim2.fromScale(0.5, 0.5)
	container.Size                   = UDim2.new(0, 260, 0, 0)
	container.AutomaticSize          = Enum.AutomaticSize.Y
	container.BackgroundTransparency = 1
	container.ZIndex                 = 5
	container.Parent                 = bg
	do
		local l = Instance.new("UIListLayout")
		l.FillDirection       = Enum.FillDirection.Vertical
		l.HorizontalAlignment = Enum.HorizontalAlignment.Center
		l.VerticalAlignment   = Enum.VerticalAlignment.Top
		l.Padding             = UDim.new(0, 0)
		l.SortOrder           = Enum.SortOrder.LayoutOrder
		l.Parent              = container
	end

	
	local badgeWrap = Instance.new("Frame")
	badgeWrap.Name                   = "BadgeWrap"
	badgeWrap.Size                   = UDim2.new(1, 0, 0, 56)
	badgeWrap.BackgroundTransparency = 1
	badgeWrap.LayoutOrder            = 1
	badgeWrap.ZIndex                 = 5
	badgeWrap.Parent                 = container

	local badge = Instance.new("Frame")
	badge.Name             = "Badge"
	badge.AnchorPoint      = Vector2.new(0.5, 0.5)
	badge.Position         = UDim2.fromScale(0.5, 0.5)
	badge.Size             = UDim2.fromOffset(44, 44)
	badge.BackgroundColor3 = accent
	badge.BorderSizePixel  = 0
	badge.ZIndex           = 6
	badge.Parent           = badgeWrap
	do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 10); c.Parent = badge end
	do
		local g = Instance.new("UIGradient")
		g.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.40),
			NumberSequenceKeypoint.new(1, 0.68),
		})
		g.Rotation = 135
		g.Parent   = badge
	end
	local badgeLbl = Instance.new("TextLabel")
	badgeLbl.Size                   = UDim2.fromScale(1, 1)
	badgeLbl.BackgroundTransparency = 1
	badgeLbl.Text                   = string.sub(title, 1, 1):upper()
	badgeLbl.TextColor3             = Color3.fromRGB(255, 255, 255)
	badgeLbl.TextSize               = 22
	badgeLbl.FontFace               = FONT_BOLD
	badgeLbl.TextXAlignment         = Enum.TextXAlignment.Center
	badgeLbl.ZIndex                 = 7
	badgeLbl.Parent                 = badge

	
	local titleLbl = Instance.new("TextLabel")
	titleLbl.Name                   = "Title"
	titleLbl.Size                   = UDim2.new(1, 0, 0, 22)
	titleLbl.BackgroundTransparency = 1
	titleLbl.Text                   = title
	titleLbl.TextColor3             = Color3.fromRGB(255, 255, 255)
	titleLbl.TextSize               = 17
	titleLbl.FontFace               = FONT_BOLD
	titleLbl.TextXAlignment         = Enum.TextXAlignment.Center
	titleLbl.LayoutOrder            = 2
	titleLbl.ZIndex                 = 5
	titleLbl.Parent                 = container

	
	do
		local sp = Instance.new("Frame"); sp.Name = "Sp1"
		sp.Size = UDim2.new(1, 0, 0, 6); sp.BackgroundTransparency = 1
		sp.LayoutOrder = 3; sp.Parent = container
	end

	
	local statusLbl = Instance.new("TextLabel")
	statusLbl.Name                   = "Status"
	statusLbl.Size                   = UDim2.new(1, 0, 0, 14)
	statusLbl.BackgroundTransparency = 1
	statusLbl.Text                   = "Starting up..."
	statusLbl.TextColor3             = Color3.fromHex("#52525e")
	statusLbl.TextSize               = 11
	statusLbl.FontFace               = FONT_MED
	statusLbl.TextXAlignment         = Enum.TextXAlignment.Center
	statusLbl.LayoutOrder            = 4
	statusLbl.ZIndex                 = 5
	statusLbl.Parent                 = container

	
	do
		local sp = Instance.new("Frame"); sp.Name = "Sp2"
		sp.Size = UDim2.new(1, 0, 0, 22); sp.BackgroundTransparency = 1
		sp.LayoutOrder = 5; sp.Parent = container
	end

	
	local track = Instance.new("Frame")
	track.Name             = "Track"
	track.Size             = UDim2.new(1, 0, 0, 2)
	track.BackgroundColor3 = Color3.fromHex("#16161c")
	track.BorderSizePixel  = 0
	track.LayoutOrder      = 6
	track.ZIndex           = 5
	track.Parent           = container
	do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1, 0); c.Parent = track end

	
	local fill = Instance.new("Frame")
	fill.Name             = "Fill"
	fill.Size             = UDim2.fromScale(0, 1)
	fill.BackgroundColor3 = accent
	fill.BorderSizePixel  = 0
	fill.ZIndex           = 6
	fill.Parent           = track
	do local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1, 0); c.Parent = fill end
	do
		
		local g = Instance.new("UIGradient")
		g.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.20),
			NumberSequenceKeypoint.new(1, 0),
		})
		g.Parent = fill
	end

	
	do
		local sp = Instance.new("Frame"); sp.Name = "Sp3"
		sp.Size = UDim2.new(1, 0, 0, 10); sp.BackgroundTransparency = 1
		sp.LayoutOrder = 7; sp.Parent = container
	end

	
	local pctLbl = Instance.new("TextLabel")
	pctLbl.Name                   = "Pct"
	pctLbl.Size                   = UDim2.new(1, 0, 0, 12)
	pctLbl.BackgroundTransparency = 1
	pctLbl.Text                   = "0%"
	pctLbl.TextColor3             = Color3.fromHex("#2a2a34")
	pctLbl.TextSize               = 10
	pctLbl.FontFace               = FONT_SEMI
	pctLbl.TextXAlignment         = Enum.TextXAlignment.Center
	pctLbl.LayoutOrder            = 8
	pctLbl.ZIndex                 = 5
	pctLbl.Parent                 = container

	

	
	TweenService:Create(bg, TW_IN, { BackgroundTransparency = 0 }):Play()

	
	task.delay(0.12, function()
		TweenService:Create(topStrip, TweenInfo.new(0.55, Enum.EasingStyle.Quad), {
			Size = UDim2.new(1, 0, 0, 1),
		}):Play()
	end)

	
	local shimmerT  = 0
	local shimmerConn: RBXScriptConnection = RunService.Heartbeat:Connect(function(dt)
		shimmerT += dt
		
		badge.BackgroundTransparency = 0.03 + (math.sin(shimmerT * 2.2) + 1) * 0.07
	end)

	
	local self: LoadingScreen = setmetatable({}, LoadingScreen) :: any
	local s = self :: any
	s._gui         = gui
	s._bg          = bg
	s._fill        = fill
	s._statusLbl   = statusLbl
	s._pctLbl      = pctLbl
	s._shimmerConn = shimmerConn
	s._dismissed   = false
	s._activeFill  = nil  

	return self
end



function LoadingScreen:setProgress(label: string, pct: number)
	local s = self :: any
	if s._dismissed then return end

	local clamped = math.clamp(pct, 0, 100)

	s._statusLbl.Text = label
	s._pctLbl.Text    = math.round(clamped) .. "%"

	
	if s._activeFill then
		pcall(function() (s._activeFill :: Tween):Cancel() end)
	end
	local tw = TweenService:Create(s._fill, TW_BAR, {
		Size = UDim2.fromScale(clamped / 100, 1),
	})
	s._activeFill = tw
	tw:Play()
end

function LoadingScreen:dismiss()
	local s = self :: any
	if s._dismissed then return end
	s._dismissed = true

	
	if s._shimmerConn then
		s._shimmerConn:Disconnect()
		s._shimmerConn = nil
	end

	
	if s._activeFill then
		pcall(function() (s._activeFill :: Tween):Cancel() end)
		s._activeFill = nil
	end

	
	s._statusLbl.Text = "Ready."
	s._pctLbl.Text    = "100%"
	TweenService:Create(s._fill, TW_SNAP, { Size = UDim2.fromScale(1, 1) }):Play()

	
	task.delay(0.22, function()
		local fadeTw = TweenService:Create(
			s._bg :: Frame,
			TW_OUT,
			{ BackgroundTransparency = 1 }
		)
		fadeTw:Play()
		fadeTw.Completed:Once(function()
			fadeTw:Destroy()
			if s._gui and s._gui.Parent then
				s._gui:Destroy()
			end
		end)
	end)
end

return LoadingScreen

end)() end,[12]=function()local wax,script,require=ImportGlobals(12)local ImportGlobals return (function(...)






local constants = require(script.Parent.Parent.utility.constants)
local variables = require(script.Parent.Parent.utility.variables)
local tween     = require(script.Parent.Parent.utility.tween)



local TOAST_W          = 276
local MAX_VISIBLE      = 6
local GAP              = 6
local SLIDE_IN_OFFSET  = 45
local SLIDE_OUT_OFFSET = 85
local MOBILE_SCALE     = 0.65

local TWEEN_IN_SIZE  = TweenInfo.new(0.42, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
local TWEEN_IN_POS   = TweenInfo.new(0.44, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
local TWEEN_IN_FADE  = TweenInfo.new(0.38, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
local TWEEN_OUT_SIZE = TweenInfo.new(0.38, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
local TWEEN_OUT_POS  = TweenInfo.new(0.40, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
local TWEEN_OUT_FADE = TweenInfo.new(0.32, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)

local DEFAULT_ICONS: { [string]: string } = {
	info    = "rbxassetid://10723415903",
	success = "rbxassetid://10709790387",
	warning = "rbxassetid://10709752935",
	error   = "rbxassetid://10747384394",
}



export type NotifyProps = {
	title:    string?,
	content:  string?,
	duration: number?,
	type:     string?,           
	icon:     (string | number)?,
}

type ActiveToast = {
	wrapper:     Frame,
	card:        CanvasGroup,
	stroke:      UIStroke,
	dismissed:   boolean,
	cancelTimer: () -> (),
}



local _gui          : ScreenGui?      = nil
local _container    : Frame?          = nil
local _layout       : UIListLayout?   = nil
local _active       : { ActiveToast } = {}
local _orderCounter : number          = 0
local _scale        : number          = 1



local function typeColor(notifType: string?, theme: { [string]: any }): Color3
	local t = string.lower(notifType or "info")
	if     t == "success" then return Color3.fromHex("#3ecf8e")
	elseif t == "warning" then return Color3.fromHex("#f5a524")
	elseif t == "error"   then return theme.ErrorColor or Color3.fromHex("#ff4f58")
	else                       return theme.AccentColor or Color3.fromHex("#4cc2ff")
	end
end

local function resolveIcon(icon: (string | number)?, notifType: string?): string
	if type(icon) == "number" then
		return "rbxassetid://" .. tostring(icon)
	elseif type(icon) == "string" and #icon > 0 then
		if string.sub(icon, 1, 13) == "rbxassetid://" or string.sub(icon, 1, 4) == "http" then
			return icon
		end
		return icon
	end
	local t = string.lower(notifType or "info")
	return DEFAULT_ICONS[t] or DEFAULT_ICONS.info
end

local function formatElapsed(elapsed: number): string
	if elapsed <= 4 then
		return "now"
	elseif elapsed < 60 then
		return string.format("%ds ago", math.floor(elapsed))
	elseif elapsed < 3600 then
		return string.format("%dm ago", math.floor(elapsed / 60))
	else
		return string.format("%dh ago", math.floor(elapsed / 3600))
	end
end



local function ensureGui()
	if _gui and _gui.Parent and _container and _container.Parent then return end

	local isMobile = variables.userInputService.TouchEnabled and not variables.userInputService.KeyboardEnabled
	if not variables.runService:IsStudio() then
		local cam = workspace.CurrentCamera
		local vp  = if cam then cam.ViewportSize else Vector2.new(1024, 768)
		if vp.X < 800 or vp.Y < 600 then isMobile = true end
	end
	_scale = if isMobile then MOBILE_SCALE else 1

	local gui = Instance.new("ScreenGui")
	gui.Name             = "DeliriumNotifications"
	gui.DisplayOrder     = constants.displayOrder.notification
	gui.ResetOnSpawn     = false
	gui.IgnoreGuiInset   = true
	gui.ZIndexBehavior   = Enum.ZIndexBehavior.Sibling

	local ok = pcall(function() gui.Parent = game:GetService("CoreGui") end)
	if not ok or not gui.Parent then
		gui.Parent = variables.guiContainer
	end

	local scaledW = math.round(TOAST_W * _scale)

	local c = Instance.new("Frame")
	c.Name                   = "Container"
	c.Size                   = UDim2.fromOffset(scaledW, 0)
	c.AutomaticSize          = Enum.AutomaticSize.Y
	c.BackgroundTransparency = 1
	c.BorderSizePixel        = 0
	c.ClipsDescendants       = false

	local layout = Instance.new("UIListLayout")
	layout.SortOrder           = Enum.SortOrder.LayoutOrder
	layout.FillDirection       = Enum.FillDirection.Vertical
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	layout.Padding             = UDim.new(0, GAP)

	if isMobile then
		c.AnchorPoint          = Vector2.new(1, 0)
		c.Position             = UDim2.new(1, -12, 0, 44)
		layout.VerticalAlignment = Enum.VerticalAlignment.Top
	else
		c.AnchorPoint          = Vector2.new(1, 1)
		c.Position             = UDim2.new(1, -16, 1, -16)
		layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	end

	layout.Parent = c
	c.Parent      = gui

	_gui       = gui
	_container = c
	_layout    = layout
end



local function dismissToast(toast: ActiveToast)
	if toast.dismissed then return end
	toast.dismissed = true
	toast.cancelTimer()

	local idx = table.find(_active, toast)
	if idx then table.remove(_active, idx) end

	local s   = _scale
	tween.fire(toast.card, TWEEN_OUT_POS, {
		Position = UDim2.fromOffset(math.round(SLIDE_OUT_OFFSET * s), 0),
	})
	tween.fire(toast.card, TWEEN_OUT_FADE, {
		GroupTransparency = 1,
	})
	if toast.stroke and toast.stroke.Parent then
		tween.fire(toast.stroke, TWEEN_OUT_FADE, {
			Transparency = 1,
		})
	end
	local sizeTween = tween.play(toast.wrapper, TWEEN_OUT_SIZE, {
		Size = UDim2.new(1, 0, 0, 0),
	})
	sizeTween.Completed:Once(function()
		
		
		sizeTween:Destroy()
		if toast.wrapper.Parent then toast.wrapper:Destroy() end
	end)
end



local notification = {}

function notification.send(props: NotifyProps, theme: { [string]: any }?)
	ensureGui()

	local resolvedTheme = theme or variables.activeTheme or {}

	
	while #_active >= MAX_VISIBLE do
		local oldest = _active[1]
		if oldest then dismissToast(oldest) else break end
	end

	local titleText = props.title   or "Notification"
	local msgText   = props.content or ""
	local notifType = props.type    or "info"
	local accent    = typeColor(notifType, resolvedTheme)
	local iconId    = resolveIcon(props.icon, notifType)

	local duration: number
	if props.duration and props.duration > 0 then
		duration = props.duration
	elseif props.duration and props.duration <= 0 then
		duration = -1
	else
		duration = math.clamp((#msgText * 0.08) + 3, 3.5, 10)
	end

	_orderCounter += 1
	local order = _orderCounter
	local s     = _scale

	local function px(n: number): number return math.max(math.round(n * s), 1) end
	local ts = math.max(math.round(s * 12), 8)   
	local ms = math.max(math.round(s * 11), 8)   
	local xs = math.max(math.round(s * 10), 7)   
	local cs = math.max(math.round(s * 13), 8)   

	
	local usableW    = math.round(TOAST_W * s) - px(59)
	local textBounds = variables.textService:GetTextSize(
		msgText, ms,
		Enum.Font.GothamMedium,
		Vector2.new(math.max(usableW, 40), 2000)
	)
	local headerH  = px(16)
	local msgH     = if #msgText > 0 then math.max(textBounds.Y, px(13)) else 0
	local bodyH    = if msgH > 0 then (headerH + px(3) + msgH) else headerH
	local contentH = math.max(bodyH, px(28))
	local targetH  = px(20) + contentH

	
	local wrapper = Instance.new("Frame")
	wrapper.Name                   = "ToastSlot"
	wrapper.Size                   = UDim2.new(1, 0, 0, 0)
	wrapper.BackgroundTransparency = 1
	wrapper.BorderSizePixel        = 0
	wrapper.ClipsDescendants       = false
	wrapper.LayoutOrder            = order
	wrapper.Parent                 = _container

	
	local card = Instance.new("CanvasGroup")
	card.Name                  = "ToastCard"
	card.Size                  = UDim2.new(1, 0, 0, targetH)
	card.Position              = UDim2.fromOffset(math.round(SLIDE_IN_OFFSET * s), 0)
	card.BackgroundColor3      = Color3.fromHex("#1a1a1a")
	card.BorderSizePixel       = 0
	card.GroupTransparency     = 1
	card.ClipsDescendants      = true
	card.Parent                = wrapper

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, px(8))
	corner.Parent = card

	local stroke = Instance.new("UIStroke")
	stroke.Color               = Color3.fromHex("#303038")
	stroke.Thickness           = 1
	stroke.Transparency        = 1
	stroke.ApplyStrokeMode     = Enum.ApplyStrokeMode.Border
	stroke.Parent              = card

	
	local bottomGlow = Instance.new("Frame")
	bottomGlow.Name             = "BottomGlow"
	bottomGlow.Position         = UDim2.new(0, 0, 1, -1)
	bottomGlow.Size             = UDim2.new(1, 0, 0, 1)
	bottomGlow.BackgroundColor3 = accent
	bottomGlow.BorderSizePixel  = 0
	bottomGlow.ZIndex           = 3
	bottomGlow.Parent           = card

	local glowGrad = Instance.new("UIGradient")
	glowGrad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0,    1),
		NumberSequenceKeypoint.new(0.35, 0.45),
		NumberSequenceKeypoint.new(0.65, 0.45),
		NumberSequenceKeypoint.new(1,    1),
	})
	glowGrad.Parent = bottomGlow

	
	local row = Instance.new("Frame")
	row.Name                   = "Row"
	row.Position               = UDim2.fromOffset(px(11), px(10))
	row.Size                   = UDim2.new(1, -px(22), 0, contentH)
	row.BackgroundTransparency = 1
	row.BorderSizePixel        = 0
	row.ZIndex                 = 2
	row.Parent                 = card

	local rLayout = Instance.new("UIListLayout")
	rLayout.FillDirection     = Enum.FillDirection.Horizontal
	rLayout.VerticalAlignment = Enum.VerticalAlignment.Top
	rLayout.SortOrder         = Enum.SortOrder.LayoutOrder
	rLayout.Padding           = UDim.new(0, px(9))
	rLayout.Parent            = row

	
	local iconBadge = Instance.new("Frame")
	iconBadge.Name                   = "IconBadge"
	iconBadge.LayoutOrder            = 1
	iconBadge.Size                   = UDim2.fromOffset(px(28), px(28))
	iconBadge.BackgroundColor3       = accent
	iconBadge.BackgroundTransparency = 0.86
	iconBadge.BorderSizePixel        = 0
	iconBadge.Parent                 = row

	local badgeCorner = Instance.new("UICorner")
	badgeCorner.CornerRadius = UDim.new(0, px(7))
	badgeCorner.Parent = iconBadge

	local badgeStroke = Instance.new("UIStroke")
	badgeStroke.Color           = accent
	badgeStroke.Thickness       = 1
	badgeStroke.Transparency    = 0.65
	badgeStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	badgeStroke.Parent          = iconBadge

	local iconImg = Instance.new("ImageLabel")
	iconImg.Name                   = "Icon"
	iconImg.AnchorPoint            = Vector2.new(0.5, 0.5)
	iconImg.Position               = UDim2.fromScale(0.5, 0.5)
	iconImg.Size                   = UDim2.fromOffset(px(14), px(14))
	iconImg.BackgroundTransparency = 1
	iconImg.Image                  = iconId
	iconImg.ImageColor3            = accent
	iconImg.Parent                 = iconBadge

	
	local col = Instance.new("Frame")
	col.Name                   = "Col"
	col.LayoutOrder            = 2
	col.Size                   = UDim2.new(1, -px(37), 0, 0)
	col.AutomaticSize          = Enum.AutomaticSize.Y
	col.BackgroundTransparency = 1
	col.BorderSizePixel        = 0
	col.Parent                 = row

	local colLayout = Instance.new("UIListLayout")
	colLayout.FillDirection     = Enum.FillDirection.Vertical
	colLayout.SortOrder         = Enum.SortOrder.LayoutOrder
	colLayout.Padding           = UDim.new(0, px(3))
	colLayout.Parent            = col

	
	local header = Instance.new("Frame")
	header.Name                   = "Header"
	header.LayoutOrder            = 1
	header.Size                   = UDim2.new(1, 0, 0, headerH)
	header.BackgroundTransparency = 1
	header.BorderSizePixel        = 0
	header.Parent                 = col

	local hLayout = Instance.new("UIListLayout")
	hLayout.FillDirection     = Enum.FillDirection.Horizontal
	hLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	hLayout.SortOrder         = Enum.SortOrder.LayoutOrder
	hLayout.Padding           = UDim.new(0, px(4))
	hLayout.Parent            = header

	local titleLbl = Instance.new("TextLabel")
	titleLbl.Name                   = "Title"
	titleLbl.LayoutOrder            = 1
	titleLbl.AutomaticSize          = Enum.AutomaticSize.X
	titleLbl.Size                   = UDim2.new(0, 0, 1, 0)
	titleLbl.BackgroundTransparency = 1
	titleLbl.FontFace               = resolvedTheme.TitleFont
		or Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold)
	titleLbl.Text                   = titleText
	titleLbl.TextSize               = ts
	titleLbl.TextColor3             = resolvedTheme.ContentColor or Color3.fromHex("#f5f5fa")
	titleLbl.TextXAlignment         = Enum.TextXAlignment.Left
	titleLbl.TextTruncate           = Enum.TextTruncate.AtEnd
	titleLbl.Parent                 = header

	
	local spacer = Instance.new("Frame")
	spacer.Name                   = "Spacer"
	spacer.LayoutOrder            = 2
	spacer.Size                   = UDim2.new(0, 0, 1, 0)
	spacer.BackgroundTransparency = 1
	spacer.BorderSizePixel        = 0
	spacer.Parent                 = header

	local flex = Instance.new("UIFlexItem")
	flex.FlexMode = Enum.UIFlexMode.Fill
	flex.Parent   = spacer

	local timeLbl = Instance.new("TextLabel")
	timeLbl.Name                   = "Time"
	timeLbl.LayoutOrder            = 3
	timeLbl.AutomaticSize          = Enum.AutomaticSize.X
	timeLbl.Size                   = UDim2.new(0, 0, 1, 0)
	timeLbl.BackgroundTransparency = 1
	timeLbl.FontFace               = resolvedTheme.Font
		or Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium)
	timeLbl.Text                   = "now"
	timeLbl.TextSize               = xs
	timeLbl.TextColor3             = Color3.fromHex("#737380")
	timeLbl.TextXAlignment         = Enum.TextXAlignment.Right
	timeLbl.Parent                 = header

	
	
	
	local closeBtnPx = if _scale < 1 then math.max(px(14), 24) else px(14)
	local closeBtn = Instance.new("TextButton")
	closeBtn.Name                   = "CloseBtn"
	closeBtn.LayoutOrder            = 4
	closeBtn.Size                   = UDim2.fromOffset(closeBtnPx, closeBtnPx)
	closeBtn.BackgroundTransparency = 1
	closeBtn.BorderSizePixel        = 0
	closeBtn.Font                   = Enum.Font.GothamMedium
	closeBtn.Text                   = "×"
	closeBtn.TextSize               = cs
	closeBtn.TextColor3             = Color3.fromHex("#737380")
	closeBtn.AutoButtonColor        = false
	closeBtn.Parent                 = header

	local closeCrn = Instance.new("UICorner")
	closeCrn.CornerRadius = UDim.new(0, px(3))
	closeCrn.Parent = closeBtn

	
	if #msgText > 0 then
		local msgLbl = Instance.new("TextLabel")
		msgLbl.Name                   = "Message"
		msgLbl.LayoutOrder            = 2
		msgLbl.AutomaticSize          = Enum.AutomaticSize.Y
		msgLbl.Size                   = UDim2.new(1, 0, 0, 0)
		msgLbl.BackgroundTransparency = 1
		msgLbl.FontFace               = resolvedTheme.Font
			or Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium)
		msgLbl.Text                   = msgText
		msgLbl.TextSize               = ms
		msgLbl.TextColor3             = resolvedTheme.PlaceholderColor or Color3.fromHex("#b9b9c6")
		msgLbl.TextXAlignment         = Enum.TextXAlignment.Left
		msgLbl.TextWrapped            = true
		msgLbl.RichText               = true
		msgLbl.LineHeight             = 1.15
		msgLbl.Parent                 = col
	end

	
	local creationTime = tick()
	local timerThread  : thread? = nil
	local updateThread : thread? = nil

	local toast: ActiveToast = {
		wrapper     = wrapper,
		card        = card,
		stroke      = stroke,
		dismissed   = false,
		cancelTimer = function() end,
	}

	local function cancelTimer()
		toast.dismissed = true
		if timerThread  then pcall(task.cancel, timerThread);  timerThread  = nil end
		if updateThread then pcall(task.cancel, updateThread); updateThread = nil end
	end
	toast.cancelTimer = cancelTimer

	table.insert(_active, toast)

	
	tween.fire(wrapper, TWEEN_IN_SIZE, { Size = UDim2.new(1, 0, 0, targetH) })
	tween.fire(card,    TWEEN_IN_POS,  { Position = UDim2.fromOffset(0, 0)  })
	tween.fire(card,    TWEEN_IN_FADE, { GroupTransparency = 0              })
	tween.fire(stroke,  TWEEN_IN_FADE, { Transparency = 0                  })

	
	if duration > 0 then
		timerThread = task.delay(duration, function() dismissToast(toast) end)
	end

	
	updateThread = task.spawn(function()
		while not toast.dismissed do
			task.wait(1)
			if toast.dismissed then break end
			timeLbl.Text = formatElapsed(tick() - creationTime)
		end
	end)

	
	closeBtn.MouseButton1Click:Connect(function() dismissToast(toast) end)
	closeBtn.MouseEnter:Connect(function()
		tween.fire(closeBtn, TweenInfo.new(0.15), {
			BackgroundTransparency = 0.82,
			BackgroundColor3       = Color3.fromHex("#2e2e38"),
			TextColor3             = resolvedTheme.ContentColor or Color3.fromHex("#ffffff"),
		})
	end)
	closeBtn.MouseLeave:Connect(function()
		tween.fire(closeBtn, TweenInfo.new(0.15), {
			BackgroundTransparency = 1,
			TextColor3             = Color3.fromHex("#737380"),
		})
	end)
end


function notification.dismissAll()
	for i = #_active, 1, -1 do
		local t = _active[i]
		if t then dismissToast(t) end
	end
end

return notification

end)() end,[13]=function()local wax,script,require=ImportGlobals(13)local ImportGlobals return (function(...)





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

	
	local container = Instance.new("Frame")
	container.Name             = "Section_" .. name
	container.Size             = UDim2.new(1, 0, 0, 28)
	container.BackgroundTransparency = 1
	container.LayoutOrder      = 0
	container.Parent           = parent

	
	local lineLeft = Instance.new("Frame")
	lineLeft.Name                 = "LineLeft"
	lineLeft.AnchorPoint          = Vector2.new(0, 0.5)
	lineLeft.Position             = UDim2.fromScale(0, 0.5)
	lineLeft.Size                 = UDim2.new(0.5, -8, 0, 1)
	lineLeft.BackgroundColor3     = theme.ElementStroke or Color3.fromRGB(50, 42, 80)
	lineLeft.BorderSizePixel      = 0
	lineLeft.Parent               = container

	
	local lineRight = Instance.new("Frame")
	lineRight.Name             = "LineRight"
	lineRight.AnchorPoint      = Vector2.new(1, 0.5)
	lineRight.Position         = UDim2.fromScale(1, 0.5)
	lineRight.Size             = UDim2.new(0.5, -8, 0, 1)
	lineRight.BackgroundColor3 = theme.ElementStroke or Color3.fromRGB(50, 42, 80)
	lineRight.BorderSizePixel  = 0
	lineRight.Parent           = container

	
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

		
		
		local textSize = variables.textService:GetTextSize(
			name, 11, Enum.Font.Gotham, Vector2.new(math.huge, math.huge)
		)
		local half = (textSize.X / 2) + 6
		lineLeft.Size  = UDim2.new(0.5, -half, 0, 1)
		lineRight.Size = UDim2.new(0.5, -half, 0, 1)
	else
		
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
			label.FontFace = t.Font or constants.DEFAULT_FONT
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

end)() end,[14]=function()local wax,script,require=ImportGlobals(14)local ImportGlobals return (function(...)






local constants = require(script.Parent.Parent.utility.constants)
local flags     = require(script.Parent.Parent.utility.flags)
local runtime   = require(script.Parent.Parent.utility.runtime)
local signal    = require(script.Parent.Parent.utility.signal)
local themeUtil   = require(script.Parent.Parent.utility.theme)
local variables   = require(script.Parent.Parent.utility.variables)

local TRACK_H = 15
local KNOB_W  = 30
local KNOB_H  = 18
local VAL_W   = 54
local GAP     = 8


local DEFAULT_FONT = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium)

export type SliderProps = {
	name:               string?,
	Label:              string?,
	Text:               string?,
	description:        string?,
	Tooltip:            string?,
	flag:               string?,
	Flag:               string?,
	range:              { number }?,
	min:                number?,
	Min:                number?,
	max:                number?,
	Max:                number?,
	increment:          number?,
	step:               number?,
	Step:               number?,
	value:              number?,
	default:            number?,
	Default:            number?,
	suffix:             string?,
	Suffix:             string?,
	compact:            boolean?,
	Compact:            boolean?,
	hideMax:            boolean?,
	HideMax:            boolean?,
	formatDisplayValue: ((slider: any, value: number) -> string?)?,
	FormatDisplayValue: ((slider: any, value: number) -> string?)?,
	enabled:            boolean?,
	Enabled:            boolean?,
	layoutOrder:        number?,
	LayoutOrder:        number?,
	callback:           ((value: number) -> ())?,
	Callback:           ((value: number) -> ())?,
}

export type Slider = {
	value:      number,
	Value:      number,
	Changed:    any,
	_frame:     Frame,
	Set:        (self: Slider, value: number, skipCallback: boolean?) -> (),
	SetValue:   (self: Slider, value: number, skipCallback: boolean?) -> (),
	SetEnabled: (self: Slider, enabled: boolean) -> (),
	GetFrame:   (self: Slider) -> Frame,
	Destroy:    (self: Slider) -> (),
}

local Slider = {}
Slider.__index = Slider



local function snap(value: number, step: number, min: number): number
	if step <= 0 then return value end
	return min + math.round((value - min) / step) * step
end

local function fmt(value: number, step: number): string
	if step <= 0 or step >= 1 then
		return tostring(math.round(value))
	elseif step >= 0.1 then
		return string.format("%.1f", value)
	else
		return string.format("%.2f", value)
	end
end





local function tFromMouseX(track: Frame, mouseX: number, knobW: number): number
	local kHalf  = knobW / 2
	local usable = math.max(track.AbsoluteSize.X - knobW, 1)
	local relX   = mouseX - (track.AbsolutePosition.X + kHalf)
	return math.clamp(relX / usable, 0, 1)
end



function Slider.new(props: SliderProps, theme: { [string]: any }, parent: Instance): Slider
	local name = props.name or props.Label or props.Text or "Slider"
	local flagKey: string? = props.flag or props.Flag

	local rangeMin = (props.range and props.range[1]) or props.min or props.Min or 0
	local rangeMax = (props.range and props.range[2]) or props.max or props.Max or 100
	local stepVal = props.increment or props.step or props.Step or 1
	local suffix = props.suffix or props.Suffix or ""
	local callback = props.callback or props.Callback
	local isCompact = (props.compact == true) or (props.Compact == true)
	local hideMaxVal = if props.hideMax ~= nil then props.hideMax
		elseif props.HideMax ~= nil then props.HideMax
		else true
	local isEnabled = if props.enabled ~= nil then props.enabled
		elseif props.Enabled ~= nil then props.Enabled
		else true
	local cfgFormat = props.formatDisplayValue or props.FormatDisplayValue

	
	local initValue: number
	if flagKey and flags:Get(flagKey) ~= nil then
		initValue = flags:Get(flagKey) :: number
	else
		initValue = props.value or props.default or props.Default or rangeMin
	end
	initValue = math.clamp(snap(initValue, stepVal, rangeMin), rangeMin, rangeMax)

	local FRAME_H: number
	local HEADER_H: number
	if isCompact then
		FRAME_H = 36
		HEADER_H = 0
	else
		FRAME_H = 54
		HEADER_H = 20
	end

	
	local frame = Instance.new("Frame")
	frame.Name = "Slider_" .. name
	frame.Size = UDim2.new(1, 0, 0, FRAME_H)
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel = 0
	frame.LayoutOrder = props.layoutOrder or props.LayoutOrder or 0
	frame.ClipsDescendants = false
	frame.Parent = parent

	
	local shadow = Instance.new("Frame")
	shadow.Name = "Shadow"
	shadow.AnchorPoint = Vector2.new(0.5, 0.5)
	shadow.Position = UDim2.new(0.5, 0, 0.5, 3)
	shadow.Size = UDim2.new(1, 0, 1, 4)
	shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	shadow.BackgroundTransparency = 0.75
	shadow.BorderSizePixel = 0
	shadow.ZIndex = 1

	local shadowCorner = Instance.new("UICorner")
	shadowCorner.CornerRadius = UDim.new(0, 7)
	shadowCorner.Parent = shadow
	shadow.Parent = frame

	
	local inner = Instance.new("Frame")
	inner.Name = "Inner"
	inner.AnchorPoint = Vector2.new(0.5, 0.5)
	inner.Position = UDim2.new(0.5, 0, 0.5, 0)
	inner.Size = UDim2.new(1, 0, 1, 0)
	inner.BackgroundColor3 = Color3.new(1, 1, 1)
	inner.BorderSizePixel = 0
	inner.ZIndex = 2
	inner.ClipsDescendants = true
	inner.Parent = frame

	local innerGrad = Instance.new("UIGradient")
	innerGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromHex("#2e2e2e")),
		ColorSequenceKeypoint.new(1, Color3.fromHex("#181818")),
	})
	innerGrad.Rotation = 90
	innerGrad.Parent = inner

	local innerCorner = Instance.new("UICorner")
	innerCorner.CornerRadius = UDim.new(0, 6)
	innerCorner.Parent = inner

	local stroke = Instance.new("UIStroke")
	stroke.Color = theme.ElementStroke or Color3.fromHex("#2b2b2b")
	stroke.Thickness = 1
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = inner

	local innerPad = Instance.new("UIPadding")
	innerPad.PaddingLeft = UDim.new(0, 12)
	innerPad.PaddingRight = UDim.new(0, 12)
	innerPad.PaddingTop = UDim.new(0, 4)
	innerPad.Parent = inner

	local flash = Instance.new("Frame")
	flash.Name = "Flash"
	flash.Size = UDim2.new(1, 24, 1, 0)
	flash.Position = UDim2.new(0, -12, 0, 0)
	flash.BackgroundColor3 = Color3.new(1, 1, 1)
	flash.BackgroundTransparency = 1
	flash.BorderSizePixel = 0
	flash.ZIndex = 3

	local flashCorner = Instance.new("UICorner")
	flashCorner.CornerRadius = UDim.new(0, 6)
	flashCorner.Parent = flash
	flash.Parent = inner

	
	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.AnchorPoint = Vector2.new(0, 0.5)
	label.Position = UDim2.new(0, 0, 0, math.floor(HEADER_H / 2))
	label.Size = UDim2.new(1, -(VAL_W + GAP), 0, HEADER_H)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamMedium
	label.FontFace = theme.Font or Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium)
	label.Text = name
	label.TextSize = 13
	label.TextColor3 = if isEnabled then (theme.ContentColor or Color3.fromHex("#ffffff")) else Color3.fromHex("#555555")
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.TextTruncate = Enum.TextTruncate.AtEnd
	label.ZIndex = 4
	label.Visible = not isCompact
	label.Parent = inner

	local valLabel = Instance.new("TextLabel")
	valLabel.Name = "ValueLabel"
	valLabel.BackgroundTransparency = 1
	valLabel.Font = Enum.Font.GothamMedium
	valLabel.FontFace = theme.Font or Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium)
	valLabel.TextSize = 12
	valLabel.TextColor3 = theme.PlaceholderColor or Color3.fromHex("#9d9d9d")
	valLabel.TextXAlignment = Enum.TextXAlignment.Right
	valLabel.TextYAlignment = Enum.TextYAlignment.Center
	valLabel.ZIndex = 4
	valLabel.Parent = inner

	if isCompact then
		valLabel.AnchorPoint = Vector2.new(1, 0.5)
		valLabel.Position = UDim2.new(1, 0, 0.5, 0)
		valLabel.Size = UDim2.fromOffset(VAL_W, FRAME_H)
	else
		valLabel.AnchorPoint = Vector2.new(1, 0.5)
		valLabel.Position = UDim2.new(1, 0, 0, math.floor(HEADER_H / 2))
		valLabel.Size = UDim2.fromOffset(VAL_W, HEADER_H)
		valLabel.AutomaticSize = Enum.AutomaticSize.X
	end

	
	local TRACK_Y: number
	if isCompact then
		TRACK_Y = math.floor((FRAME_H - TRACK_H) / 2)
	else
		TRACK_Y = HEADER_H + math.floor((FRAME_H - HEADER_H - TRACK_H) / 2)
	end

	local trackRightPad = if isCompact then (VAL_W + GAP) else 0

	local track = Instance.new("Frame")
	track.Name = "Track"
	track.Size = UDim2.new(1, -trackRightPad, 0, TRACK_H)
	track.Position = UDim2.fromOffset(0, TRACK_Y)
	track.BackgroundColor3 = theme.SliderBackground or Color3.fromHex("#222222")
	track.BorderSizePixel = 0
	track.ZIndex = 4
	track.ClipsDescendants = false

	local trackCorner = Instance.new("UICorner")
	trackCorner.CornerRadius = UDim.new(0, 100)
	trackCorner.Parent = track
	track.Parent = inner

	
	
	local knobRef: Frame = nil :: any

	
	
	
	
	
	
	
	
	
	
	
	local function knobPosScale(t: number): number
		local tw = track.AbsoluteSize.X
		local kw = if knobRef ~= nil and knobRef.AbsoluteSize.X > 0
			then knobRef.AbsoluteSize.X
			else nil

		if kw ~= nil and tw > 0 then
			
			local kHalf_frac = kw / (2 * tw)
			return math.clamp(kHalf_frac + t * (1 - 2 * kHalf_frac), 0, 1)
		else
			
			
			local kHalf_frac = KNOB_W / (2 * 200)
			return math.clamp(kHalf_frac + t * (1 - 2 * kHalf_frac), 0, 1)
		end
	end

	local self = setmetatable({}, Slider) :: Slider
	self.value = initValue
	self.Value = initValue
	self._frame = frame
	self.Changed = signal.new()

	local function fmtDisplay(val: number): string
		if cfgFormat then
			local res = cfgFormat(self, val)
			if res ~= nil then return res end
		end
		if not hideMaxVal then
			return fmt(val, stepVal) .. " / " .. fmt(rangeMax, stepVal) .. suffix
		end
		return fmt(val, stepVal) .. suffix
	end

	local t0 = (initValue - rangeMin) / math.max(rangeMax - rangeMin, 1e-9)

	local clipFrame = Instance.new("Frame")
	clipFrame.Name = "FillClip"
	clipFrame.Size = UDim2.new(knobPosScale(t0), 0, 1, 0)
	clipFrame.Position = UDim2.fromOffset(0, 0)
	clipFrame.BackgroundTransparency = 1
	clipFrame.ClipsDescendants = true
	clipFrame.BorderSizePixel = 0
	clipFrame.ZIndex = 5
	clipFrame.Parent = track

	local clipCorner = Instance.new("UICorner")
	clipCorner.CornerRadius = UDim.new(0, 100)
	clipCorner.Parent = clipFrame

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.new(1, 0, 1, 0)
	fill.BackgroundColor3 = theme.AccentColor or Color3.fromHex("#4cc2ff")
	fill.BorderSizePixel = 0
	fill.ZIndex = 5
	fill.Parent = clipFrame

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 100)
	fillCorner.Parent = fill

	local fillGrad = Instance.new("UIGradient")
	fillGrad.Color = theme.SliderProgress
		or ColorSequence.new(Color3.fromHex("#4cc2ff"), Color3.fromHex("#0093fb"))
	fillGrad.Rotation = 0
	fillGrad.Parent = fill

	local knob = Instance.new("Frame")
	knob.Name = "Knob"
	knob.AnchorPoint = Vector2.new(0.5, 0.5)
	knob.Size = UDim2.fromOffset(KNOB_W, KNOB_H)
	knob.Position = UDim2.new(knobPosScale(t0), 0, 0.5, 0)
	knob.BackgroundColor3 = theme.SliderHandle or Color3.fromRGB(255, 255, 255)
	knob.BorderSizePixel = 0
	knob.ZIndex = 6
	knob.ClipsDescendants = false

	local knobCorner = Instance.new("UICorner")
	knobCorner.CornerRadius = UDim.new(0, 100)
	knobCorner.Parent = knob

	local knobShadow = Instance.new("Frame")
	knobShadow.Name = "KnobShadow"
	knobShadow.AnchorPoint = Vector2.new(0.5, 0.5)
	knobShadow.Position = UDim2.new(0.5, 0, 0.5, 1)
	knobShadow.Size = UDim2.new(1, 4, 1, 4)
	knobShadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	knobShadow.BackgroundTransparency = 0.7
	knobShadow.BorderSizePixel = 0
	knobShadow.ZIndex = 5

	local knobShadowCorner = Instance.new("UICorner")
	knobShadowCorner.CornerRadius = UDim.new(0, 100)
	knobShadowCorner.Parent = knobShadow
	knobShadow.Parent = knob
	knob.Parent = track
	knobRef = knob  

	local hit = Instance.new("TextButton")
	hit.Name = "Hit"
	hit.Size = UDim2.fromScale(1, 1)
	hit.BackgroundTransparency = 1
	hit.Text = ""
	hit.AutoButtonColor = false
	hit.ZIndex = 7
	hit.Parent = inner

	valLabel.Text = fmtDisplay(initValue)

	
	local s = self :: any
	s._min = rangeMin
	s._max = rangeMax
	s._step = stepVal
	s._suffix = suffix
	s._flag = flagKey
	s._callback = callback
	s._enabled = isEnabled
	s._theme = theme
	s._knobPosScale = knobPosScale
	s._fmtDisplay = fmtDisplay
	s._track = track
	s._clipFrame = clipFrame
	s._knob = knob
	s._valLabel = valLabel
	s._label = label
	s._stroke = stroke
	s._flash = flash
	s._shadow = shadow
	s._fill = fill
	s._fillGrad = fillGrad
	s._conns = {} :: { [string]: RBXScriptConnection }

	local dragging = false
	local hovering = false
	local pendingTouchStart: Vector2? = nil

	
	
	
	
	local _pendingFireVal: number? = nil
	local _firePending    = false

	local function scheduleChanged(val: number)
		_pendingFireVal = val
		if _firePending then return end
		_firePending = true
		task.defer(function()
			_firePending = false
			local v = _pendingFireVal
			_pendingFireVal = nil
			if v ~= nil then
				self.Changed:Fire(v)
				if callback then callback(v) end
			end
		end)
	end

	local function applyT(t: number)
		local raw = rangeMin + t * (rangeMax - rangeMin)
		local val = math.clamp(snap(raw, stepVal, rangeMin), rangeMin, rangeMax)
		if val == self.value then return end

		self.value = val
		self.Value = val
		valLabel.Text = fmtDisplay(val)

		local st = (val - rangeMin) / math.max(rangeMax - rangeMin, 1e-9)
		
		local posScale = knobPosScale(st)
		clipFrame.Size = UDim2.new(posScale, 0, 1, 0)
		knob.Position = UDim2.new(posScale, 0, 0.5, 0)

		if flagKey then
			flags:Set(flagKey, val)
		end
		
		scheduleChanged(val)
	end

	
	s._conns.hitEnter = hit.MouseEnter:Connect(function()
		if not s._enabled then return end
		if variables.settingsOpen then return end
		hovering = true
		stroke.Color = s._theme.AccentColor or Color3.fromHex("#4cc2ff")
		flash.BackgroundTransparency = 0.92
		shadow.BackgroundTransparency = 0.65
		shadow.Position = UDim2.new(0.5, 0, 0.5, 5)
	end)

	s._conns.hitLeave = hit.MouseLeave:Connect(function()
		if not s._enabled then return end
		hovering = false
		if not dragging then
			stroke.Color = s._theme.ElementStroke or Color3.fromHex("#2b2b2b")
			flash.BackgroundTransparency = 1
			shadow.BackgroundTransparency = 0.75
			shadow.Position = UDim2.new(0.5, 0, 0.5, 3)
		end
	end)

	s._conns.hitBegan = hit.InputBegan:Connect(function(input: InputObject)
		if not s._enabled then return end

		
		
		local touchX: number
		if input.UserInputType == Enum.UserInputType.Touch then
			touchX = input.Position.X
		else
			touchX = variables.userInputService:GetMouseLocation().X
		end

		local trackLeft = track.AbsolutePosition.X
		local trackRight = trackLeft + track.AbsoluteSize.X
		if touchX < (trackLeft - 24) or touchX > (trackRight + KNOB_W / 2 + 24) then return end

		if input.UserInputType == Enum.UserInputType.Touch then
			pendingTouchStart = Vector2.new(input.Position.X, input.Position.Y)
			return
		end

		if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
		dragging = true
		local kw = knob.AbsoluteSize.X > 0 and knob.AbsoluteSize.X or KNOB_W
		applyT(tFromMouseX(track, touchX, kw))
	end)

	s._conns.inputChanged = variables.userInputService.InputChanged:Connect(function(input: InputObject)
		if pendingTouchStart and input.UserInputType == Enum.UserInputType.Touch then
			local dx = math.abs(input.Position.X - pendingTouchStart.X)
			local dy = math.abs(input.Position.Y - pendingTouchStart.Y)
			if dx > 5 or dy > 5 then
				if dx >= dy then
					dragging = true
				end
				pendingTouchStart = nil
			end
		end

		if not dragging then return end
		if input.UserInputType ~= Enum.UserInputType.MouseMovement
			and input.UserInputType ~= Enum.UserInputType.Touch then return end
		
		local inputX: number
		if input.UserInputType == Enum.UserInputType.Touch then
			inputX = input.Position.X
		else
			inputX = variables.userInputService:GetMouseLocation().X
		end
		local kw = knob.AbsoluteSize.X > 0 and knob.AbsoluteSize.X or KNOB_W
		applyT(tFromMouseX(track, inputX, kw))
	end)

	local function onRelease()
		if not dragging then return end
		dragging = false
		if not hovering then
			stroke.Color = s._theme.ElementStroke or Color3.fromHex("#2b2b2b")
			flash.BackgroundTransparency = 1
			shadow.BackgroundTransparency = 0.75
			shadow.Position = UDim2.new(0.5, 0, 0.5, 3)
		end
	end

	s._conns.inputEnded = variables.userInputService.InputEnded:Connect(function(input: InputObject)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch then return end
		pendingTouchStart = nil
		onRelease()
	end)

	s._conns.hitUp = hit.MouseButton1Up:Connect(function()
		onRelease()
	end)

	local function refreshKnobLayout()
		local st = (self.value - rangeMin) / math.max(rangeMax - rangeMin, 1e-9)
		local posScale = knobPosScale(st)
		clipFrame.Size = UDim2.new(posScale, 0, 1, 0)
		knob.Position = UDim2.new(posScale, 0, 0.5, 0)
	end

	
	
	
	
	
	s._conns.trackSize = track:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		task.defer(refreshKnobLayout)
	end)
	
	s._conns.knobSize  = knob:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		task.defer(refreshKnobLayout)
	end)

	s._themeUnsub = themeUtil.subscribe(function(t)
		s._theme = t
		stroke.Color = if hovering then (t.AccentColor or Color3.fromHex("#4cc2ff")) else (t.ElementStroke or Color3.fromHex("#2b2b2b"))
		label.TextColor3 = if s._enabled then (t.ContentColor or Color3.fromHex("#ffffff")) else Color3.fromHex("#555555")
		
		label.FontFace = t.Font or DEFAULT_FONT
		valLabel.TextColor3 = t.PlaceholderColor or Color3.fromHex("#9d9d9d")
		valLabel.FontFace = t.Font or DEFAULT_FONT
		track.BackgroundColor3 = t.SliderBackground or Color3.fromHex("#222222")
		fill.BackgroundColor3 = t.AccentColor or Color3.fromHex("#4cc2ff")
		fillGrad.Color = t.SliderProgress or ColorSequence.new(Color3.fromHex("#4cc2ff"), Color3.fromHex("#0093fb"))
		knob.BackgroundColor3 = t.SliderHandle or Color3.fromRGB(255, 255, 255)
		innerGrad.Color = t.ElementGradient or ColorSequence.new(Color3.fromRGB(28, 24, 44))
		stroke.Transparency = if s._enabled then (t.ElementStrokeTransparency or 0) else 0.5
	end)

	if flagKey and flagKey ~= "" then
		flags:Set(flagKey, initValue)
	end

	return self
end



function Slider:Set(value: number, skipCallback: boolean?)
	local s = self :: any
	local clamped = math.clamp(snap(value, s._step, s._min), s._min, s._max)
	local t = (clamped - s._min) / math.max(s._max - s._min, 1e-9)

	self.value = clamped
	self.Value = clamped
	s._valLabel.Text = s._fmtDisplay(clamped)

	
	local posScale = s._knobPosScale(t)
	s._clipFrame.Size = UDim2.new(posScale, 0, 1, 0)
	s._knob.Position = UDim2.new(posScale, 0, 0.5, 0)

	if s._flag then
		flags:Set(s._flag, clamped)
	end
	self.Changed:Fire(clamped)
	if not skipCallback and s._callback then
		task.spawn(s._callback, clamped)
	end
end

function Slider:SetValue(value: number, skipCallback: boolean?)
	self:Set(value, skipCallback)
end

function Slider:SetEnabled(enabled: boolean)
	local s = self :: any
	s._enabled = enabled
	s._label.TextColor3 = if enabled
		then (s._theme.ContentColor or Color3.fromHex("#ffffff"))
		else Color3.fromHex("#555555")
	s._stroke.Transparency = if enabled then 0 else 0.5
end

function Slider:GetFrame(): Frame
	return self._frame
end

function Slider:Destroy()
	local s = self :: any
	if s._themeUnsub then s._themeUnsub() end
	if s._conns then
		for _, conn in s._conns do
			conn:Disconnect()
		end
		table.clear(s._conns)
	end
	self.Changed:Destroy()
	self._frame:Destroy()
end

return Slider

end)() end,[15]=function()local wax,script,require=ImportGlobals(15)local ImportGlobals return (function(...)







local constants    = require(script.Parent.Parent.utility.constants)
local themeUtil    = require(script.Parent.Parent.utility.theme)
local tween        = require(script.Parent.Parent.utility.tween)
local saveManager  = require(script.Parent.Parent.utility.saveManager)
local Section      = require(script.Parent.section)
local Label        = require(script.Parent.label)
local Button       = require(script.Parent.button)
local Toggle       = require(script.Parent.toggle)
local Slider       = require(script.Parent.slider)
local Input        = require(script.Parent.input)
local Keybind      = require(script.Parent.keybind)
local Dropdown     = require(script.Parent.dropdown)
local ColorPicker  = require(script.Parent.colorpicker)
local Descriptor   = require(script.Parent.descriptor)
local icons        = require(script.Parent.Parent.utility.icons)

export type TabProps = {
	name:    string?,
	icon:    string?,
	badge:   string?,
	columns: number?,
}

export type TabColumn = {
	CreateSection:     (self: TabColumn, props: Section.SectionProps) -> Section.Section,
	CreateLabel:       (self: TabColumn, props: Label.LabelProps) -> Label.Label,
	CreateButton:      (self: TabColumn, props: Button.ButtonProps) -> Button.Button,
	CreateToggle:      (self: TabColumn, props: Toggle.ToggleProps) -> Toggle.Toggle,
	CreateSlider:      (self: TabColumn, props: Slider.SliderProps) -> Slider.Slider,
	AddSlider:         (self: TabColumn, props: Slider.SliderProps) -> Slider.Slider,
	CreateInput:       (self: TabColumn, props: Input.InputProps) -> Input.Input,
	CreateKeybind:     (self: TabColumn, props: Keybind.KeybindProps) -> Keybind.Keybind,
	CreateDropdown:    (self: TabColumn, props: Dropdown.DropdownProps) -> Dropdown.Dropdown,
	AddDropdown:       (self: TabColumn, props: Dropdown.DropdownProps) -> Dropdown.Dropdown,
	CreateColorPicker: (self: TabColumn, props: ColorPicker.ColorPickerProps) -> ColorPicker.ColorPicker,
}

export type Tab = {
	Left:              TabColumn,
	Right:             TabColumn,
	_frame:            Frame,
	_scrollFrame:      ScrollingFrame,
	_tabButton:        TextButton,
	_theme:            { [string]: any },

	CreateSection:     (self: Tab, props: Section.SectionProps) -> Section.Section,
	CreateLabel:       (self: Tab, props: Label.LabelProps) -> Label.Label,
	CreateButton:      (self: Tab, props: Button.ButtonProps) -> Button.Button,
	CreateToggle:      (self: Tab, props: Toggle.ToggleProps) -> Toggle.Toggle,
	CreateSlider:      (self: Tab, props: Slider.SliderProps) -> Slider.Slider,
	AddSlider:         (self: Tab, props: Slider.SliderProps) -> Slider.Slider,
	CreateInput:       (self: Tab, props: Input.InputProps) -> Input.Input,
	CreateKeybind:     (self: Tab, props: Keybind.KeybindProps) -> Keybind.Keybind,
	CreateDropdown:    (self: Tab, props: Dropdown.DropdownProps) -> Dropdown.Dropdown,
	AddDropdown:       (self: Tab, props: Dropdown.DropdownProps) -> Dropdown.Dropdown,
	CreateColorPicker: (self: Tab, props: ColorPicker.ColorPickerProps) -> ColorPicker.ColorPicker,

	CreateLeftSection:     (self: Tab, props: Section.SectionProps) -> Section.Section,
	CreateLeftLabel:       (self: Tab, props: Label.LabelProps) -> Label.Label,
	CreateLeftButton:      (self: Tab, props: Button.ButtonProps) -> Button.Button,
	CreateLeftToggle:      (self: Tab, props: Toggle.ToggleProps) -> Toggle.Toggle,
	CreateLeftSlider:      (self: Tab, props: Slider.SliderProps) -> Slider.Slider,
	CreateLeftInput:       (self: Tab, props: Input.InputProps) -> Input.Input,
	CreateLeftKeybind:     (self: Tab, props: Keybind.KeybindProps) -> Keybind.Keybind,
	CreateLeftDropdown:    (self: Tab, props: Dropdown.DropdownProps) -> Dropdown.Dropdown,
	CreateLeftColorPicker: (self: Tab, props: ColorPicker.ColorPickerProps) -> ColorPicker.ColorPicker,

	CreateRightSection:     (self: Tab, props: Section.SectionProps) -> Section.Section,
	CreateRightLabel:       (self: Tab, props: Label.LabelProps) -> Label.Label,
	CreateRightButton:      (self: Tab, props: Button.ButtonProps) -> Button.Button,
	CreateRightToggle:      (self: Tab, props: Toggle.ToggleProps) -> Toggle.Toggle,
	CreateRightSlider:      (self: Tab, props: Slider.SliderProps) -> Slider.Slider,
	CreateRightInput:       (self: Tab, props: Input.InputProps) -> Input.Input,
	CreateRightKeybind:     (self: Tab, props: Keybind.KeybindProps) -> Keybind.Keybind,
	CreateRightDropdown:    (self: Tab, props: Dropdown.DropdownProps) -> Dropdown.Dropdown,
	CreateRightColorPicker: (self: Tab, props: ColorPicker.ColorPickerProps) -> ColorPicker.ColorPicker,

	Show:    (self: Tab) -> (),
	Hide:    (self: Tab) -> (),
	Destroy: (self: Tab) -> (),
}

local Tab = {}
Tab.__index = Tab



local OVERLAY_Y_OFFSET = 45

local function resolveIcon(icon: string?): string?
	if not icon or icon == "" then return nil end
	return icons.Resolve(icon, "Lucide")
end

function Tab.new(props: TabProps, theme: { [string]: any }, contentParent: Frame, sidebarParent: Frame, windowFrame: Frame?): Tab
	local name      = props.name or "Tab"
	local iconAsset = resolveIcon(props.icon)
	local badgeText = props.badge

	local hasIcon  = iconAsset ~= nil
	local hasBadge = badgeText ~= nil and badgeText ~= ""

	
	local function getTokens(t: { [string]: any })
		return {
			colorBorder       = t.SurfaceStroke     or Color3.fromHex("#2b2b2b"),
			colorAccent       = t.AccentColor       or Color3.fromHex("#4cc2ff"),
			colorSurfaceHover = t.NeutralButtonHover or Color3.fromHex("#252525"),
			colorTextPrimary  = t.TitlingColor      or Color3.fromHex("#ffffff"),
			colorTextSecondary= t.PlaceholderColor  or Color3.fromHex("#8c8c96"),
			font              = t.Font or Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium),
		}
	end

	local tokens = getTokens(theme)

	
	local numColumns = props.columns or 2
	local isDual = numColumns ~= 1

	
	local tabContainer = Instance.new("Frame")
	tabContainer.Name                    = "Tab_" .. name
	tabContainer.Size                    = UDim2.fromScale(1, 1)
	tabContainer.BackgroundTransparency  = 1
	tabContainer.Visible                 = false
	tabContainer.Parent                  = contentParent

	
	local leftScroll = Instance.new("ScrollingFrame")
	leftScroll.Name                    = "Column_Left"
	leftScroll.Position                = UDim2.fromScale(0, 0)
	leftScroll.Size                    = if isDual then UDim2.new(0.5, -4, 1, 0) else UDim2.fromScale(1, 1)
	leftScroll.BackgroundTransparency  = 1
	leftScroll.ScrollBarThickness      = 2
	leftScroll.ScrollBarImageColor3    = tokens.colorBorder
	leftScroll.ScrollBarImageTransparency = 0.5
	leftScroll.BorderSizePixel         = 0
	leftScroll.CanvasSize              = UDim2.fromOffset(0, 0)
	leftScroll.AutomaticCanvasSize     = Enum.AutomaticSize.Y
	leftScroll.ClipsDescendants        = true
	leftScroll.Parent                  = tabContainer

	local leftLayout = Instance.new("UIListLayout")
	leftLayout.SortOrder           = Enum.SortOrder.LayoutOrder
	leftLayout.FillDirection       = Enum.FillDirection.Vertical
	leftLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	leftLayout.Padding             = UDim.new(0, constants.elementPadding)
	leftLayout.Parent              = leftScroll

	local leftPad = Instance.new("UIPadding")
	leftPad.PaddingLeft   = UDim.new(0, constants.contentPadding)
	leftPad.PaddingRight  = if isDual then UDim.new(0, 4) else UDim.new(0, constants.contentPadding)
	leftPad.PaddingTop    = UDim.new(0, 8)
	leftPad.PaddingBottom = UDim.new(0, 8)
	leftPad.Parent        = leftScroll

	
	local rightScroll: ScrollingFrame? = nil
	local columnDivider: Frame? = nil

	if isDual then
		local rs = Instance.new("ScrollingFrame")
		rs.Name                    = "Column_Right"
		rs.AnchorPoint             = Vector2.new(1, 0)
		rs.Position                = UDim2.fromScale(1, 0)
		rs.Size                    = UDim2.new(0.5, -4, 1, 0)
		rs.BackgroundTransparency  = 1
		rs.ScrollBarThickness      = 2
		rs.ScrollBarImageColor3    = tokens.colorBorder
		rs.ScrollBarImageTransparency = 0.5
		rs.BorderSizePixel         = 0
		rs.CanvasSize              = UDim2.fromOffset(0, 0)
		rs.AutomaticCanvasSize     = Enum.AutomaticSize.Y
		rs.ClipsDescendants        = true
		rs.Parent                  = tabContainer

		local rightLayout = Instance.new("UIListLayout")
		rightLayout.SortOrder           = Enum.SortOrder.LayoutOrder
		rightLayout.FillDirection       = Enum.FillDirection.Vertical
		rightLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		rightLayout.Padding             = UDim.new(0, constants.elementPadding)
		rightLayout.Parent              = rs

		local rightPad = Instance.new("UIPadding")
		rightPad.PaddingLeft   = UDim.new(0, 4)
		rightPad.PaddingRight  = UDim.new(0, constants.contentPadding)
		rightPad.PaddingTop    = UDim.new(0, 8)
		rightPad.PaddingBottom = UDim.new(0, 8)
		rightPad.Parent        = rs

		rightScroll = rs

		
		local div = Instance.new("Frame")
		div.Name                   = "ColumnDivider"
		div.AnchorPoint            = Vector2.new(0.5, 0)
		div.Position               = UDim2.new(0.5, 0, 0, 8)
		div.Size                   = UDim2.new(0, 1, 1, -16)
		div.BackgroundColor3       = tokens.colorBorder
		div.BackgroundTransparency = 0.7
		div.BorderSizePixel        = 0
		div.Parent                 = tabContainer
		columnDivider              = div
	end

	
	local tabBtn = Instance.new("TextButton")
	tabBtn.Name                   = "TabBtn_" .. name
	tabBtn.Size                   = UDim2.new(1, 0, 0, 36)
	tabBtn.BackgroundColor3       = tokens.colorAccent
	tabBtn.BackgroundTransparency = 1
	tabBtn.BorderSizePixel        = 0
	tabBtn.AutoButtonColor        = false
	tabBtn.Text                   = ""
	tabBtn.Active                 = true
	tabBtn.Parent                 = sidebarParent

	local tabBtnCorner = Instance.new("UICorner")
	tabBtnCorner.CornerRadius = UDim.new(0, 8)
	tabBtnCorner.Parent       = tabBtn

	local tabStroke = Instance.new("UIStroke")
	tabStroke.Color           = tokens.colorBorder
	tabStroke.Thickness       = 1
	tabStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	tabStroke.Transparency    = 1
	tabStroke.Parent          = tabBtn

	
	local indicator = Instance.new("Frame")
	indicator.Name                   = "Indicator"
	indicator.AnchorPoint            = Vector2.new(0, 0.5)
	indicator.Position               = UDim2.new(0, 4, 0.5, 0)
	indicator.Size                   = UDim2.fromOffset(3, 0)
	indicator.BackgroundColor3       = tokens.colorAccent
	indicator.BackgroundTransparency = 1
	indicator.BorderSizePixel        = 0
	indicator.ZIndex                 = 3
	indicator.Parent                 = tabBtn

	local indCorner = Instance.new("UICorner")
	indCorner.CornerRadius = UDim.new(1, 0)
	indCorner.Parent       = indicator

	
	local contentRow = Instance.new("Frame")
	contentRow.Name                   = "ContentRow"
	contentRow.Size                   = UDim2.fromScale(1, 1)
	contentRow.BackgroundTransparency = 1
	contentRow.Parent                 = tabBtn

	local rowLayout = Instance.new("UIListLayout")
	rowLayout.FillDirection       = Enum.FillDirection.Horizontal
	rowLayout.VerticalAlignment   = Enum.VerticalAlignment.Center
	rowLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	rowLayout.Padding             = UDim.new(0, 8)
	rowLayout.SortOrder           = Enum.SortOrder.LayoutOrder
	rowLayout.Parent              = contentRow

	local rowPad = Instance.new("UIPadding")
	rowPad.PaddingLeft   = UDim.new(0, 13)
	rowPad.PaddingRight  = if hasBadge then UDim.new(0, 46) else UDim.new(0, 8)
	rowPad.Parent        = contentRow

	local iconImg: ImageLabel? = nil
	if hasIcon then
		local img = Instance.new("ImageLabel")
		img.Name                   = "Icon"
		img.Size                   = UDim2.fromOffset(16, 16)
		img.BackgroundTransparency = 1
		img.Image                  = iconAsset :: string
		img.ImageColor3            = tokens.colorTextSecondary
		img.LayoutOrder            = 1
		img.Parent                 = contentRow
		iconImg                    = img
	end

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name                   = "Title"
	titleLabel.Size                   = UDim2.new(1, if hasIcon then -24 else 0, 1, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text                   = name
	titleLabel.TextColor3             = tokens.colorTextSecondary
	titleLabel.TextSize               = 13
	titleLabel.FontFace               = tokens.font
	titleLabel.TextXAlignment         = Enum.TextXAlignment.Left
	titleLabel.TextTruncate           = Enum.TextTruncate.AtEnd
	titleLabel.LayoutOrder            = 2
	titleLabel.Parent                 = contentRow

	local badgeFrame: Frame? = nil
	local badgeLabel: TextLabel? = nil
	local badgeStroke: UIStroke? = nil
	if hasBadge then
		local bf = Instance.new("Frame")
		bf.Name                   = "Badge"
		bf.AnchorPoint            = Vector2.new(1, 0.5)
		bf.Position               = UDim2.new(1, -8, 0.5, 0)
		bf.AutomaticSize          = Enum.AutomaticSize.X
		bf.Size                   = UDim2.fromOffset(0, 16)
		bf.BackgroundColor3       = tokens.colorAccent
		bf.BackgroundTransparency = 0.82
		bf.BorderSizePixel        = 0
		bf.ZIndex                 = 2
		bf.Parent                 = tabBtn

		local bc = Instance.new("UICorner")
		bc.CornerRadius = UDim.new(1, 0)
		bc.Parent       = bf

		local bs = Instance.new("UIStroke")
		bs.Color        = tokens.colorAccent
		bs.Thickness    = 1
		bs.Transparency = 0.45
		bs.Parent       = bf
		badgeStroke     = bs

		local bp = Instance.new("UIPadding")
		bp.PaddingLeft  = UDim.new(0, 6)
		bp.PaddingRight = UDim.new(0, 6)
		bp.Parent       = bf

		local bl = Instance.new("TextLabel")
		bl.Name                   = "Label"
		bl.Size                   = UDim2.fromScale(0, 1)
		bl.AutomaticSize          = Enum.AutomaticSize.X
		bl.BackgroundTransparency = 1
		bl.Text                   = badgeText :: string
		bl.TextColor3             = tokens.colorAccent
		bl.TextSize               = 9
		bl.FontFace               = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold)
		bl.Parent                 = bf
		badgeLabel                = bl
		badgeFrame                = bf
	end

	
	tabBtn.MouseEnter:Connect(function()
		if tabContainer.Visible then return end
		tween.fire(tabBtn, constants.tweenFast, {
			BackgroundColor3       = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 0.94,
		})
		tween.fire(tabStroke, constants.tweenFast, {
			Color        = tokens.colorBorder,
			Transparency = 0.65,
		})
		tween.fire(titleLabel, constants.tweenFast, {
			TextColor3 = tokens.colorTextPrimary:Lerp(tokens.colorTextSecondary, 0.3),
		})
		if iconImg then
			tween.fire(iconImg, constants.tweenFast, {
				ImageColor3 = tokens.colorTextPrimary:Lerp(tokens.colorTextSecondary, 0.3),
			})
		end
	end)

	tabBtn.MouseLeave:Connect(function()
		if tabContainer.Visible then return end
		tween.fire(tabBtn, constants.tweenFast, {
			BackgroundTransparency = 1,
		})
		tween.fire(tabStroke, constants.tweenFast, {
			Transparency = 1,
		})
		tween.fire(titleLabel, constants.tweenFast, {
			TextColor3 = tokens.colorTextSecondary,
		})
		if iconImg then
			tween.fire(iconImg, constants.tweenFast, {
				ImageColor3 = tokens.colorTextSecondary,
			})
		end
	end)

	local self = setmetatable({}, Tab) :: any
	self._frame            = tabContainer
	self._container        = tabContainer
	self._scrollFrame      = leftScroll
	self._leftScrollFrame  = leftScroll
	self._rightScrollFrame = rightScroll
	self._isDual           = isDual
	self._tabButton        = tabBtn
	self._theme            = theme
	self._indicator        = indicator
	self._tabStroke        = tabStroke
	self._titleLabel       = titleLabel
	self._iconImg          = iconImg
	self._badgeFrame       = badgeFrame
	self._badgeLabel       = badgeLabel
	self._badgeStroke      = badgeStroke
	self._tokens           = tokens
	self._elementCount     = 0
	self._elements         = {}
	self._windowFrame      = windowFrame

	
	local function createSideProxy(targetScroll: ScrollingFrame)
		return {
			CreateSection     = function(_, p) return self:_createOn(targetScroll, Section, p) end,
			CreateLabel       = function(_, p) return self:_createOn(targetScroll, Label, p) end,
			CreateButton      = function(_, p) return self:_createOn(targetScroll, Button, p) end,
			CreateToggle      = function(_, p) return self:_createOn(targetScroll, Toggle, p) end,
			CreateSlider      = function(_, p) return self:_createOn(targetScroll, Slider, p) end,
			AddSlider         = function(_, p) return self:_createOn(targetScroll, Slider, p) end,
			CreateInput       = function(_, p) return self:_createOn(targetScroll, Input, p) end,
			CreateKeybind     = function(_, p) return self:_createOn(targetScroll, Keybind, p) end,
			CreateDropdown    = function(_, p) return self:_createOn(targetScroll, Dropdown, p) end,
			AddDropdown       = function(_, p) return self:_createOn(targetScroll, Dropdown, p) end,
			CreateColorPicker = function(_, p) return self:_createColorPickerOn(targetScroll, p) end,
		}
	end

	self.Left  = createSideProxy(leftScroll)
	self.Right = createSideProxy(if isDual and rightScroll then rightScroll else leftScroll)

	
	self._themeUnsub = themeUtil.subscribe(function(t)
		self._theme = t
		tokens = getTokens(t)
		self._tokens = tokens
		leftScroll.ScrollBarImageColor3 = tokens.colorBorder
		if rightScroll then
			rightScroll.ScrollBarImageColor3 = tokens.colorBorder
		end
		if columnDivider then
			columnDivider.BackgroundColor3 = tokens.colorBorder
		end

		if badgeStroke then badgeStroke.Color = tokens.colorAccent end
		if badgeLabel then badgeLabel.TextColor3 = tokens.colorAccent end
		if badgeFrame then badgeFrame.BackgroundColor3 = tokens.colorAccent end

		if tabContainer.Visible then
			tabBtn.BackgroundColor3          = tokens.colorAccent
			tabBtn.BackgroundTransparency    = 0.86
			tabStroke.Color                  = tokens.colorAccent
			tabStroke.Transparency           = 0.4
			indicator.BackgroundColor3       = tokens.colorAccent
			indicator.BackgroundTransparency = 0
			indicator.Size                   = UDim2.fromOffset(3, 18)
			titleLabel.TextColor3            = tokens.colorTextPrimary
			if iconImg then iconImg.ImageColor3 = tokens.colorAccent end
		else
			tabBtn.BackgroundTransparency    = 1
			tabStroke.Color                  = tokens.colorBorder
			tabStroke.Transparency           = 1
			indicator.BackgroundColor3       = tokens.colorAccent
			indicator.BackgroundTransparency = 1
			indicator.Size                   = UDim2.fromOffset(3, 0)
			titleLabel.TextColor3            = tokens.colorTextSecondary
			if iconImg then iconImg.ImageColor3 = tokens.colorTextSecondary end
		end
	end)

	return self
end


local function nextOrder(self: Tab): number
	local count = (self :: any)._elementCount + 1
	(self :: any)._elementCount = count
	return count
end

function Tab:_resolveParent(side: string?): ScrollingFrame
	local s = (self :: any)
	if s._isDual and s._rightScrollFrame and side and (string.lower(side) == "right" or side == "2") then
		return s._rightScrollFrame
	end
	return s._leftScrollFrame
end

function Tab:_createOn(targetScroll: ScrollingFrame, module: any, props: any): any
	
	if props and not props.flag and not (props :: any).Flag
		and not (props :: any).noSave and not (props :: any).ignoreFlag then
		local nameStr = props.name or (props :: any).Label or (props :: any).Text
		if type(nameStr) == "string" and #nameStr > 0 then
			props = table.clone(props)
			props.flag = saveManager.deriveFlagFromName(nameStr)
		end
	end

	local el = module.new(props, self._theme, targetScroll)
	el._frame.LayoutOrder = nextOrder(self)
	table.insert((self :: any)._elements, el)

	
	local flagKey = (el :: any)._flag
	if flagKey and flagKey ~= "" then
		saveManager:Register(flagKey, el)
	end

	local desc = props and (props.description or props.Description or props.Tooltip)
	if desc and desc ~= "" then
		local descObj = Descriptor.new(targetScroll, desc, self._theme, nextOrder(self))
		el._descriptor = descObj
		table.insert((self :: any)._elements, descObj)
	end

	return el
end

function Tab:_createColorPickerOn(targetScroll: ScrollingFrame, props: any): any
	
	if props and not props.flag and not (props :: any).Flag
		and not (props :: any).noSave and not (props :: any).ignoreFlag then
		local nameStr = props.name or (props :: any).Label or (props :: any).Text
		if type(nameStr) == "string" and #nameStr > 0 then
			props = table.clone(props)
			props.flag = saveManager.deriveFlagFromName(nameStr)
		end
	end

	local wf = (self :: any)._windowFrame :: Frame?
	local merged = table.clone(props :: any) :: ColorPicker.ColorPickerProps
	if wf and not (merged :: any).overlayParent then
		(merged :: any).overlayParent  = wf
		;(merged :: any).overlayYOffset = OVERLAY_Y_OFFSET
	end
	local cp = ColorPicker.new(merged, self._theme, targetScroll)
	cp._frame.LayoutOrder = nextOrder(self)
	table.insert((self :: any)._elements, cp)

	
	local flagKey = (cp :: any)._flag
	if flagKey and flagKey ~= "" then
		saveManager:Register(flagKey, function(v: any, skipCallback: boolean?)
			cp:Set(v, nil, skipCallback)
		end)
	end

	local desc = props and (props.description or props.Description or props.Tooltip)
	if desc and desc ~= "" then
		local descObj = Descriptor.new(targetScroll, desc, self._theme, nextOrder(self))
		cp._descriptor = descObj
		table.insert((self :: any)._elements, descObj)
	end

	return cp
end

function Tab:CreateSection(props: Section.SectionProps): Section.Section
	local side = (props :: any).side or (props :: any).Side
	return self:_createOn(self:_resolveParent(side), Section, props)
end

function Tab:CreateLabel(props: Label.LabelProps): Label.Label
	local side = (props :: any).side or (props :: any).Side
	return self:_createOn(self:_resolveParent(side), Label, props)
end

function Tab:CreateButton(props: Button.ButtonProps): Button.Button
	local side = (props :: any).side or (props :: any).Side
	return self:_createOn(self:_resolveParent(side), Button, props)
end

function Tab:CreateToggle(props: Toggle.ToggleProps): Toggle.Toggle
	local side = (props :: any).side or (props :: any).Side
	return self:_createOn(self:_resolveParent(side), Toggle, props)
end

function Tab:CreateSlider(props: Slider.SliderProps): Slider.Slider
	local side = (props :: any).side or (props :: any).Side
	return self:_createOn(self:_resolveParent(side), Slider, props)
end

function Tab:AddSlider(props: Slider.SliderProps): Slider.Slider
	return self:CreateSlider(props)
end

function Tab:CreateInput(props: Input.InputProps): Input.Input
	local side = (props :: any).side or (props :: any).Side
	return self:_createOn(self:_resolveParent(side), Input, props)
end

function Tab:CreateKeybind(props: Keybind.KeybindProps): Keybind.Keybind
	local side = (props :: any).side or (props :: any).Side
	return self:_createOn(self:_resolveParent(side), Keybind, props)
end

function Tab:CreateDropdown(props: Dropdown.DropdownProps): Dropdown.Dropdown
	local side = (props :: any).side or (props :: any).Side
	return self:_createOn(self:_resolveParent(side), Dropdown, props)
end

function Tab:AddDropdown(props: Dropdown.DropdownProps): Dropdown.Dropdown
	return self:CreateDropdown(props)
end

function Tab:CreateColorPicker(props: ColorPicker.ColorPickerProps): ColorPicker.ColorPicker
	local side = (props :: any).side or (props :: any).Side
	return self:_createColorPickerOn(self:_resolveParent(side), props)
end


function Tab:CreateLeftSection(props)     return self:_createOn((self :: any)._leftScrollFrame, Section, props) end
function Tab:CreateLeftLabel(props)       return self:_createOn((self :: any)._leftScrollFrame, Label, props) end
function Tab:CreateLeftButton(props)      return self:_createOn((self :: any)._leftScrollFrame, Button, props) end
function Tab:CreateLeftToggle(props)      return self:_createOn((self :: any)._leftScrollFrame, Toggle, props) end
function Tab:CreateLeftSlider(props)      return self:_createOn((self :: any)._leftScrollFrame, Slider, props) end
function Tab:CreateLeftInput(props)       return self:_createOn((self :: any)._leftScrollFrame, Input, props) end
function Tab:CreateLeftKeybind(props)     return self:_createOn((self :: any)._leftScrollFrame, Keybind, props) end
function Tab:CreateLeftDropdown(props)    return self:_createOn((self :: any)._leftScrollFrame, Dropdown, props) end
function Tab:CreateLeftColorPicker(props) return self:_createColorPickerOn((self :: any)._leftScrollFrame, props) end


function Tab:CreateRightSection(props)     return self:_createOn((self :: any)._rightScrollFrame or (self :: any)._leftScrollFrame, Section, props) end
function Tab:CreateRightLabel(props)       return self:_createOn((self :: any)._rightScrollFrame or (self :: any)._leftScrollFrame, Label, props) end
function Tab:CreateRightButton(props)      return self:_createOn((self :: any)._rightScrollFrame or (self :: any)._leftScrollFrame, Button, props) end
function Tab:CreateRightToggle(props)      return self:_createOn((self :: any)._rightScrollFrame or (self :: any)._leftScrollFrame, Toggle, props) end
function Tab:CreateRightSlider(props)      return self:_createOn((self :: any)._rightScrollFrame or (self :: any)._leftScrollFrame, Slider, props) end
function Tab:CreateRightInput(props)       return self:_createOn((self :: any)._rightScrollFrame or (self :: any)._leftScrollFrame, Input, props) end
function Tab:CreateRightKeybind(props)     return self:_createOn((self :: any)._rightScrollFrame or (self :: any)._leftScrollFrame, Keybind, props) end
function Tab:CreateRightDropdown(props)    return self:_createOn((self :: any)._rightScrollFrame or (self :: any)._leftScrollFrame, Dropdown, props) end
function Tab:CreateRightColorPicker(props) return self:_createColorPickerOn((self :: any)._rightScrollFrame or (self :: any)._leftScrollFrame, props) end

function Tab:Show()
	local s = (self :: any)
	s._container.Visible = true

	local tk         = s._tokens
	local tabBtn_    = self._tabButton
	local tabStroke_ = s._tabStroke
	local indicator_ = s._indicator
	local titleLabel_= s._titleLabel
	local iconImg_   = s._iconImg

	titleLabel_.FontFace = Font.new(tk.font.Family, Enum.FontWeight.SemiBold)

	tween.fire(tabBtn_, constants.tweenFast, {
		BackgroundColor3       = tk.colorAccent,
		BackgroundTransparency = 0.86,
	})
	tween.fire(tabStroke_, constants.tweenFast, {
		Color        = tk.colorAccent,
		Transparency = 0.4,
	})
	tween.fire(indicator_, constants.tweenFast, {
		Size                   = UDim2.fromOffset(3, 18),
		BackgroundTransparency = 0,
		BackgroundColor3       = tk.colorAccent,
	})
	tween.fire(titleLabel_, constants.tweenFast, {
		TextColor3 = tk.colorTextPrimary,
	})
	if iconImg_ then
		tween.fire(iconImg_, constants.tweenFast, {
			ImageColor3 = tk.colorAccent,
		})
	end
end

function Tab:Hide()
	local s = (self :: any)
	s._container.Visible = false

	local tk         = s._tokens
	local tabBtn_    = self._tabButton
	local tabStroke_ = s._tabStroke
	local indicator_ = s._indicator
	local titleLabel_= s._titleLabel
	local iconImg_   = s._iconImg

	titleLabel_.FontFace = Font.new(tk.font.Family, Enum.FontWeight.Medium)

	tween.fire(tabBtn_, constants.tweenFast, {
		BackgroundTransparency = 1,
	})
	tween.fire(tabStroke_, constants.tweenFast, {
		Transparency = 1,
		Color        = tk.colorBorder,
	})
	tween.fire(indicator_, constants.tweenFast, {
		Size                   = UDim2.fromOffset(3, 0),
		BackgroundTransparency = 1,
	})
	tween.fire(titleLabel_, constants.tweenFast, {
		TextColor3 = tk.colorTextSecondary,
	})
	if iconImg_ then
		tween.fire(iconImg_, constants.tweenFast, {
			ImageColor3 = tk.colorTextSecondary,
		})
	end
end

function Tab:Destroy()
	local s = (self :: any)
	if s._themeUnsub then s._themeUnsub() end

	for _, el in s._elements do
		pcall(function() el:Destroy() end)
	end
	s._container:Destroy()
	self._tabButton:Destroy()
end

return Tab

end)() end,[16]=function()local wax,script,require=ImportGlobals(16)local ImportGlobals return (function(...)





local constants = require(script.Parent.Parent.utility.constants)
local tween     = require(script.Parent.Parent.utility.tween)
local flags     = require(script.Parent.Parent.utility.flags)
local element   = require(script.Parent.Parent.utility.element)
local themeUtil   = require(script.Parent.Parent.utility.theme)
local variables   = require(script.Parent.Parent.utility.variables)

export type ToggleProps = {
	name:        string?,
	description: string?,
	flag:        string?,
	value:       boolean?,
	callback:    ((value: boolean) -> ())?,
}

export type Toggle = {
	value:   boolean,
	_frame:  Frame,
	Set:     (self: Toggle, value: boolean, skipCallback: boolean?) -> (),
	Destroy: (self: Toggle) -> (),
}

local Toggle = {}
Toggle.__index = Toggle

function Toggle.new(props: ToggleProps, theme: { [string]: any }, parent: Instance): Toggle
	local name        = props.name or "Toggle"
	local description = props.description or ""
	local flagKey: string? = props.flag or (props :: any).Flag
	local callback    = props.callback

	
	local initValue: boolean
	if flagKey and flags:Get(flagKey) ~= nil then
		initValue = flags:Get(flagKey) :: boolean
	else
		initValue = props.value == true
	end

	
	local frame, stroke, gradient = element.makeFrame("Toggle_" .. name, theme, parent)

	
	local inner = Instance.new("Frame")
	inner.Name                   = "Inner"
	inner.Size                   = UDim2.new(1, -56, 1, 0)  
	inner.BackgroundTransparency = 1
	inner.Parent                 = frame

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 12)
	padding.Parent      = inner

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name                   = "Title"
	titleLabel.Size                   = UDim2.fromScale(1, 1)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text                   = name
	titleLabel.TextColor3             = theme.ContentColor or Color3.fromRGB(220, 215, 240)
	titleLabel.TextSize               = 13
	titleLabel.FontFace               = theme.Font or Font.new("rbxasset://fonts/families/GothamSSm.json")
	titleLabel.TextXAlignment         = Enum.TextXAlignment.Left
	titleLabel.TextYAlignment         = Enum.TextYAlignment.Center
	titleLabel.TextTruncate           = Enum.TextTruncate.AtEnd
	titleLabel.Parent                 = inner

	
	
	local trackW, trackH = 36, 20
	local track = Instance.new("Frame")
	track.Name             = "Track"
	track.AnchorPoint      = Vector2.new(1, 0.5)
	track.Position         = UDim2.new(1, -12, 0.5, 0)
	track.Size             = UDim2.fromOffset(trackW, trackH)
	track.BackgroundColor3 = theme.ToggleTrack or Color3.fromRGB(0, 0, 0)
	track.BackgroundTransparency = theme.ToggleTrackTransparency or 0.85
	track.BorderSizePixel  = 0
	track.Parent           = frame

	local trackCorner = Instance.new("UICorner")
	trackCorner.CornerRadius = UDim.new(1, 0)
	trackCorner.Parent       = track

	
	local knobSize = trackH - 6
	local knob = Instance.new("Frame")
	knob.Name             = "Knob"
	knob.AnchorPoint      = Vector2.new(0, 0.5)
	knob.Position         = UDim2.new(0, 3, 0.5, 0)
	knob.Size             = UDim2.fromOffset(knobSize, knobSize)
	knob.BackgroundColor3 = theme.ToggleKnobOff or Color3.fromRGB(200, 195, 220)
	knob.BackgroundTransparency = theme.ToggleKnobOffTransparency or 0.5
	knob.BorderSizePixel  = 0
	knob.ZIndex           = 2
	knob.Parent           = track

	local knobCorner = Instance.new("UICorner")
	knobCorner.CornerRadius = UDim.new(1, 0)
	knobCorner.Parent       = knob

	
	local glow = Instance.new("Frame")
	glow.Name                   = "Glow"
	glow.Size                   = UDim2.fromScale(1, 1)
	glow.BackgroundColor3       = theme.AccentColor or Color3.fromRGB(124, 58, 237)
	glow.BackgroundTransparency = 1
	glow.BorderSizePixel        = 0
	glow.ZIndex                 = 1
	glow.Parent                 = track

	local glowCorner = Instance.new("UICorner")
	glowCorner.CornerRadius = UDim.new(1, 0)
	glowCorner.Parent       = glow

	
	local self = setmetatable({}, Toggle) :: Toggle
	self.value  = initValue
	self._frame = frame
	;(self :: any)._knob     = knob
	;(self :: any)._glow     = glow
	;(self :: any)._stroke   = stroke
	;(self :: any)._track    = track
	;(self :: any)._theme    = theme
	;(self :: any)._flag     = flagKey
	;(self :: any)._callback = callback
	;(self :: any)._trackW   = trackW
	;(self :: any)._knobSize = knobSize

	
	;(self :: any)._themeUnsub = themeUtil.subscribe(function(t)
		self._theme = t
		frame.BackgroundTransparency = t.ElementTransparency or 0
		stroke.Color = t.ElementStroke or Color3.fromHex("#2b2b2b")
		stroke.Transparency = t.ElementStrokeTransparency or 0
		titleLabel.TextColor3 = t.ContentColor or Color3.fromHex("#ffffff")
		titleLabel.FontFace = t.Font or Font.new("rbxasset://fonts/families/GothamSSm.json")
		track.BackgroundColor3 = t.ToggleTrack or Color3.fromRGB(0, 0, 0)
		track.BackgroundTransparency = t.ToggleTrackTransparency or 0.85
		if self.value then
			knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			knob.BackgroundTransparency = 0
		else
			knob.BackgroundColor3 = t.ToggleKnobOff or Color3.fromHex("#9d9d9d")
			knob.BackgroundTransparency = t.ToggleKnobOffTransparency or 0.5
		end
		glow.BackgroundColor3 = t.AccentColor or Color3.fromHex("#4cc2ff")
		gradient.Color = t.ElementGradient or ColorSequence.new(Color3.fromRGB(28, 24, 44))
		theme = t
	end)

	
	self:Set(initValue, true)

	
	local btn = Instance.new("TextButton")
	btn.Name                   = "Interact"
	btn.Size                   = UDim2.fromScale(1, 1)
	btn.BackgroundTransparency = 1
	btn.Text                   = ""
	btn.AutoButtonColor        = false
	btn.Parent                 = frame

	btn.MouseEnter:Connect(function()
		if variables.settingsOpen then return end
		tween.fire(stroke, constants.tweenFast, {
			Color = theme.ElementStrokeHover or theme.AccentColor or Color3.fromHex("#4cc2ff"),
		})
	end)
	btn.MouseLeave:Connect(function()
		tween.fire(stroke, constants.tweenFast, {
			Color = theme.ElementStroke or Color3.fromHex("#2b2b2b"),
		})
	end)
	btn.MouseButton1Click:Connect(function()
		self:Set(not self.value)
	end)

	return self
end

function Toggle:Set(value: boolean, skipCallback: boolean?)
	self.value = value

	local knob: Frame  = (self :: any)._knob
	local glow: Frame  = (self :: any)._glow
	local theme        = (self :: any)._theme
	local trackW: number = (self :: any)._trackW
	local knobSize: number = (self :: any)._knobSize
	local flagKey      = (self :: any)._flag
	local callback     = (self :: any)._callback

	local accent = theme.AccentColor or Color3.fromRGB(124, 58, 237)
	local knobOffColor = theme.ToggleKnobOff or Color3.fromRGB(200, 195, 220)
	local glowAlpha = theme.AccentGlow or 0.4

	if value then
		tween.fire(knob, constants.tweenFast, {
			Position          = UDim2.new(0, trackW - knobSize - 3, 0.5, 0),
			BackgroundColor3  = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 0,
		})
		tween.fire(glow, constants.tweenFast, {
			BackgroundTransparency = glowAlpha,
		})
	else
		tween.fire(knob, constants.tweenFast, {
			Position          = UDim2.new(0, 3, 0.5, 0),
			BackgroundColor3  = knobOffColor,
			BackgroundTransparency = theme.ToggleKnobOffTransparency or 0.5,
		})
		tween.fire(glow, constants.tweenFast, {
			BackgroundTransparency = 1,
		})
	end

	if flagKey then
		flags:Set(flagKey, value)
	end

	if not skipCallback and callback then
		task.spawn(callback, value)
	end
end

function Toggle:Destroy()
	local s = (self :: any)
	if s._themeUnsub then s._themeUnsub() end
	if s._descriptor then s._descriptor:Destroy() end
	self._frame:Destroy()
end

return Toggle

end)() end,[17]=function()local wax,script,require=ImportGlobals(17)local ImportGlobals return (function(...)








local constants    = require(script.Parent.Parent.utility.constants)
local element      = require(script.Parent.Parent.utility.element)
local variables    = require(script.Parent.Parent.utility.variables)
local tween        = require(script.Parent.Parent.utility.tween)
local themeUtil    = require(script.Parent.Parent.utility.theme)
local windowSizing = require(script.Parent.Parent.utility.windowSizing)
local notification  = require(script.Parent.notification)
local PlayerCard    = require(script.Parent.dashboard)
local Tab          = require(script.Parent.tab)
local icons        = require(script.Parent.Parent.utility.icons)
local ColorPicker  = require(script.Parent.colorpicker)
local Dropdown     = require(script.Parent.dropdown)
local Keybind      = require(script.Parent.keybind)

local ICON_SETTINGS = "rbxassetid://129180860773723" 
local ICON_MINIMIZE = "rbxassetid://108115485663409" 
local ICON_RESTORE  = "rbxassetid://88738500661569"  
local ICON_CLOSE    = "rbxassetid://83277910885129"  

export type WindowProps = {
	name:         string?,
	subtitle:     string?,
	theme:        (string | { [string]: any })?,
	keybind:      (EnumItem | string)?,   
	keepOnScreen: boolean?,               
}

export type Window = {
	unloaded: boolean,
	_gui:     ScreenGui,

	CreateTab:   (self: Window, props: Tab.TabProps) -> Tab.Tab,
	Notify:      (self: Window, props: notification.NotifyProps) -> (),
	Show:        (self: Window) -> (),
	Hide:        (self: Window) -> (),
	ToggleHide:     (self: Window) -> (),
	ToggleMinimise: (self: Window) -> (),
	ChangeTheme: (self: Window, newTheme: string | { [string]: any }) -> (),
	Unload:      (self: Window) -> (),
}

local Window = {}
Window.__index = Window


local VIEWPORT_RECONCILE_INTERVAL = 2


local function resolveKeybind(v: (EnumItem | string)?): EnumItem
	if typeof(v) == "EnumItem" then return v :: EnumItem end
	if typeof(v) == "string" then
		local ok, item = pcall(function() return Enum.KeyCode[v :: string] end)
		if ok and item then return item :: EnumItem end
	end
	return Enum.KeyCode.RightShift
end


local function fitWindowSize(): UDim2
	local cam = workspace.CurrentCamera
	return windowSizing.fit(cam and cam.ViewportSize)
end



function Window.new(props: WindowProps): Window
	local windowName = props.name or "Delirium"
	local subtitle   = props.subtitle or ""
	local toggleKey  = resolveKeybind(props.keybind)
	local keepOnScreen = if props.keepOnScreen ~= nil then props.keepOnScreen else true

	
	local resolvedTheme = themeUtil.resolve(props.theme)
	variables.activeTheme = resolvedTheme

	
	local colorSurface       = resolvedTheme.WindowColor.Keypoints[1].Value
	local colorTitleBar      = resolvedTheme.TitleBarColor   or Color3.fromHex("#111114")
	local colorBorder        = resolvedTheme.SurfaceStroke   or Color3.fromHex("#2b2b2b")
	local colorSurfaceHover  = resolvedTheme.NeutralButton   or Color3.fromHex("#252525")
	local colorAccent        = resolvedTheme.AccentColor     or Color3.fromHex("#4cc2ff")
	local colorError         = resolvedTheme.ErrorColor      or Color3.fromHex("#ff4f58")
	local colorTextPrimary   = resolvedTheme.TitlingColor    or Color3.fromHex("#ffffff")
	local colorTextSecondary = resolvedTheme.PlaceholderColor or Color3.fromHex("#8a8a92")

	
	local gui = Instance.new("ScreenGui")
	gui.Name                   = variables.httpService:GenerateGUID(false)
	gui.DisplayOrder           = constants.displayOrder.window
	gui.IgnoreGuiInset         = true
	gui.ResetOnSpawn           = false
	gui.ZIndexBehavior         = Enum.ZIndexBehavior.Sibling
	gui.ClipToDeviceSafeArea   = false
	gui.Parent                 = variables.guiContainer

	
	local initialSize = fitWindowSize()
	local W = initialSize.X.Offset
	local H = initialSize.Y.Offset

	local cam = variables.workspace.CurrentCamera
	local vp  = if cam then cam.ViewportSize else Vector2.new(1920, 1080)
	local initX = math.floor(vp.X / 2)
	local initY = math.floor(vp.Y / 2)

	
	local windowFrame = Instance.new("Frame")
	windowFrame.Name                   = "Window"
	windowFrame.AnchorPoint            = Vector2.new(0.5, 0.5)
	windowFrame.Position               = UDim2.fromOffset(initX, initY)
	windowFrame.Size                   = UDim2.fromOffset(W, H)
	windowFrame.BackgroundColor3       = Color3.fromRGB(255, 255, 255)
	
	
	windowFrame.BackgroundTransparency = 1
	windowFrame.BorderSizePixel        = 0
	windowFrame.ClipsDescendants       = true   
	windowFrame.Parent                 = gui

	local winScale = Instance.new("UIScale")
	
	
	winScale.Scale = 1.0
	winScale.Parent = windowFrame

	local winCorner = Instance.new("UICorner")
	winCorner.CornerRadius = resolvedTheme.CornerRoundness or UDim.new(0, 10)
	winCorner.Parent       = windowFrame

	local winGradient = Instance.new("UIGradient")
	winGradient.Color    = resolvedTheme.WindowColor
	winGradient.Rotation = 90
	winGradient.Parent   = windowFrame

	local winStroke = Instance.new("UIStroke")
	winStroke.Color           = colorBorder
	winStroke.Thickness       = 1
	winStroke.Transparency    = 0.3
	winStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	winStroke.Parent          = windowFrame


	local TITLEBAR_H = 44

	local titleBar = Instance.new("Frame")
	titleBar.Name                   = "TitleBar"
	titleBar.Size                   = UDim2.new(1, 0, 0, TITLEBAR_H)
	titleBar.BackgroundTransparency = 1   
	titleBar.BorderSizePixel        = 0
	titleBar.ZIndex                 = constants.zIndex.windowChrome
	titleBar.Parent                 = windowFrame

	
	
	local titleBarBg = Instance.new("Frame")
	titleBarBg.Name             = "Background"
	titleBarBg.Size             = UDim2.fromScale(1, 1)
	titleBarBg.BackgroundColor3 = colorTitleBar
	titleBarBg.BorderSizePixel  = 0
	titleBarBg.ZIndex           = constants.zIndex.windowChrome - 1
	titleBarBg.Parent           = titleBar

	local titleBarCorner = Instance.new("UICorner")
	titleBarCorner.CornerRadius = resolvedTheme.CornerRoundness or UDim.new(0, 8)
	titleBarCorner.Parent       = titleBarBg

	local cornerRadiusPx = (resolvedTheme.CornerRoundness or UDim.new(0, 8)).Offset
	local cornerCover = Instance.new("Frame")
	cornerCover.Name             = "CornerCover"
	cornerCover.Size             = UDim2.new(1, 0, 0, cornerRadiusPx)
	cornerCover.Position         = UDim2.new(0, 0, 1, -cornerRadiusPx)
	cornerCover.BackgroundColor3 = colorTitleBar
	cornerCover.BorderSizePixel  = 0
	cornerCover.ZIndex           = constants.zIndex.windowChrome - 1
	cornerCover.Parent           = titleBarBg


	
	local titleSep = Instance.new("Frame")
	titleSep.Name                   = "Separator"
	titleSep.Size                   = UDim2.new(1, 0, 0, 1)
	titleSep.Position               = UDim2.new(0, 0, 1, -1)
	titleSep.BackgroundColor3       = colorBorder
	titleSep.BackgroundTransparency = 0.5
	titleSep.BorderSizePixel        = 0
	titleSep.ZIndex                 = constants.zIndex.windowChrome + 1
	titleSep.Parent                 = titleBar

	local ACCENT_SIDE_PAD = 10
	local accentStrip = Instance.new("Frame")
	accentStrip.Name             = "AccentStrip"
	accentStrip.Size             = UDim2.new(1, -ACCENT_SIDE_PAD * 2, 0, 2)
	accentStrip.Position         = UDim2.fromOffset(ACCENT_SIDE_PAD, 0)
	accentStrip.BackgroundColor3 = colorAccent
	accentStrip.BorderSizePixel  = 0
	accentStrip.ZIndex           = constants.zIndex.windowChrome + 2
	accentStrip.Parent           = windowFrame         
	do
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(1, 0)
		c.Parent       = accentStrip
	end
	local accentStripGrad = Instance.new("UIGradient")
	accentStripGrad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0.00, 1),
		NumberSequenceKeypoint.new(0.12, 0),
		NumberSequenceKeypoint.new(0.88, 0),
		NumberSequenceKeypoint.new(1.00, 1),
	})
	accentStripGrad.Parent = accentStrip



	local logoMark = Instance.new("Frame")
	logoMark.Name             = "LogoMark"
	logoMark.AnchorPoint      = Vector2.new(0, 0.5)
	logoMark.Position         = UDim2.new(0, 12, 0.5, 0)
	logoMark.Size             = UDim2.fromOffset(26, 26)
	logoMark.BackgroundColor3 = colorAccent
	logoMark.BorderSizePixel  = 0
	logoMark.ZIndex           = constants.zIndex.windowChrome + 1
	logoMark.Parent           = titleBar
	do
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, 6)
		c.Parent       = logoMark
	end
	do
		local g = Instance.new("UIGradient")
		g.Color    = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(0, 0, 0))
		g.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.7),
			NumberSequenceKeypoint.new(1, 0.95),
		})
		g.Rotation = 135
		g.Parent   = logoMark
	end
	local logoInitial = Instance.new("TextLabel")
	logoInitial.Name                   = "Initial"
	logoInitial.Size                   = UDim2.fromScale(1, 1)
	logoInitial.BackgroundTransparency = 1
	logoInitial.Text                   = string.sub(windowName, 1, 1):upper()
	logoInitial.TextColor3             = Color3.fromRGB(255, 255, 255)
	logoInitial.TextSize               = 12
	logoInitial.FontFace               = resolvedTheme.TitleFont
		or Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold)
	logoInitial.TextXAlignment         = Enum.TextXAlignment.Center
	logoInitial.ZIndex                 = constants.zIndex.windowChrome + 2
	logoInitial.Parent                 = logoMark

	local TEXT_LEFT          = 48
	local TEXT_RIGHT_RESERVE = 110

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name                   = "Name"
	nameLabel.AnchorPoint            = Vector2.new(0, 0.5)
	nameLabel.Position               = UDim2.new(0, TEXT_LEFT, 0.5, 0)
	nameLabel.Size                   = UDim2.new(1, -TEXT_LEFT - TEXT_RIGHT_RESERVE, 0, 18)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text                   = windowName
	nameLabel.TextColor3             = colorTextPrimary
	nameLabel.TextSize               = 15
	nameLabel.FontFace               = resolvedTheme.TitleFont
		or Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold)
	nameLabel.TextXAlignment         = Enum.TextXAlignment.Left
	nameLabel.ZIndex                 = constants.zIndex.windowChrome + 1  
	nameLabel.Parent                 = titleBar

	local subtitleLabel: TextLabel? = nil
	if subtitle ~= "" then
		nameLabel.Position = UDim2.new(0, TEXT_LEFT, 0.5, -9)
		subtitleLabel = Instance.new("TextLabel")
		subtitleLabel.Name                   = "Subtitle"
		subtitleLabel.AnchorPoint            = Vector2.new(0, 0)
		subtitleLabel.Position               = UDim2.new(0, TEXT_LEFT, 0.5, 3)
		subtitleLabel.Size                   = UDim2.new(1, -TEXT_LEFT - TEXT_RIGHT_RESERVE, 0, 12)
		subtitleLabel.BackgroundTransparency = 1
		subtitleLabel.Text                   = subtitle
		subtitleLabel.TextColor3             = colorTextSecondary
		subtitleLabel.TextSize               = 11
		subtitleLabel.FontFace               = resolvedTheme.Font
			or Font.new("rbxasset://fonts/families/GothamSSm.json")
		subtitleLabel.TextXAlignment         = Enum.TextXAlignment.Left
		subtitleLabel.ZIndex                 = constants.zIndex.windowChrome + 1
		subtitleLabel.Parent                 = titleBar
	end

	
	local controlsFrame = Instance.new("Frame")
	controlsFrame.Name                   = "Controls"
	controlsFrame.AnchorPoint            = Vector2.new(1, 0.5)
	controlsFrame.Position               = UDim2.new(1, -12, 0.5, 0)
	controlsFrame.Size                   = UDim2.fromOffset(96, 28)
	controlsFrame.BackgroundTransparency = 1
	controlsFrame.ZIndex                 = constants.zIndex.windowChrome + 1
	controlsFrame.Parent                 = titleBar

	local controlsLayout = Instance.new("UIListLayout")
	controlsLayout.FillDirection       = Enum.FillDirection.Horizontal
	controlsLayout.VerticalAlignment   = Enum.VerticalAlignment.Center
	controlsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	controlsLayout.Padding             = UDim.new(0, 4)
	controlsLayout.SortOrder           = Enum.SortOrder.LayoutOrder
	controlsLayout.Parent              = controlsFrame


	local function makeTitleBtn(name: string, iconAsset: string, order: number): (TextButton, ImageLabel)
		local b = Instance.new("TextButton")
		b.Name                   = name
		b.Size                   = UDim2.fromOffset(26, 26)
		b.BackgroundColor3       = colorSurfaceHover
		b.BackgroundTransparency = 0
		b.Text                   = ""
		b.AutoButtonColor        = false
		b.ZIndex                 = constants.zIndex.windowChrome + 2
		b.LayoutOrder            = order
		b.Parent                 = controlsFrame

		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(1, 0)
		c.Parent       = b

		do
			local sk = Instance.new("UIStroke")
			sk.Color           = resolvedTheme.NeutralButtonStroke or Color3.fromHex("#2b2b2b")
			sk.Thickness       = 1
			sk.Transparency    = 0
			sk.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			sk.Parent          = b
		end

		local iconImg = Instance.new("ImageLabel")
		iconImg.Name                   = "Icon"
		iconImg.AnchorPoint            = Vector2.new(0.5, 0.5)
		iconImg.Position               = UDim2.fromScale(0.5, 0.5)
		iconImg.Size                   = UDim2.fromOffset(16, 16)
		iconImg.BackgroundTransparency = 1
		iconImg.Image                  = iconAsset
		iconImg.ImageColor3            = colorTextSecondary
		iconImg.ZIndex                 = constants.zIndex.windowChrome + 3
		iconImg.Parent                 = b

		return b, iconImg
	end

	local settingsBtn, settingsIcon = makeTitleBtn("Settings", ICON_SETTINGS, 1)
	local minBtn, minIcon           = makeTitleBtn("Minimize", ICON_MINIMIZE, 2)
	local closeBtn, closeIcon       = makeTitleBtn("Close",    ICON_CLOSE,    3)

	closeBtn.MouseEnter:Connect(function()
		closeBtn.BackgroundColor3 = colorError
		closeIcon.ImageColor3     = Color3.fromRGB(255, 255, 255)
	end)
	closeBtn.MouseLeave:Connect(function()
		closeBtn.BackgroundColor3 = colorSurfaceHover
		closeIcon.ImageColor3     = colorTextSecondary
	end)

	local function genericHover(btn: TextButton, icon: ImageLabel)
		btn.MouseEnter:Connect(function()
			btn.BackgroundColor3 = resolvedTheme.NeutralButtonHover or Color3.fromHex("#2e2e2e")
			icon.ImageColor3     = colorTextPrimary
		end)
		btn.MouseLeave:Connect(function()
			btn.BackgroundColor3 = colorSurfaceHover
			icon.ImageColor3     = colorTextSecondary
		end)
	end

	genericHover(minBtn, minIcon)
	genericHover(settingsBtn, settingsIcon)

	
	local body = Instance.new("Frame")
	body.Name                   = "Body"
	body.Position               = UDim2.fromOffset(0, TITLEBAR_H)
	body.Size                   = UDim2.new(1, 0, 1, -TITLEBAR_H)
	body.BackgroundTransparency = 1
	body.ClipsDescendants       = true
	body.Parent                 = windowFrame

	
	
	
	
	
	local bodyBlocker = Instance.new("TextButton")
	bodyBlocker.Name                   = "BodyBlocker"
	bodyBlocker.Size                   = UDim2.fromScale(1, 1)
	bodyBlocker.Position               = UDim2.fromScale(0, 0)
	bodyBlocker.BackgroundTransparency = 1
	bodyBlocker.Text                   = ""
	bodyBlocker.AutoButtonColor        = false
	bodyBlocker.ZIndex                 = 32767
	bodyBlocker.Visible                = false
	bodyBlocker.Parent                 = body

	local sidebar = Instance.new("Frame")
	sidebar.Name             = "Sidebar"
	sidebar.Size             = UDim2.new(0, constants.sidebarWidth, 1, 0)
	sidebar.BackgroundColor3 = colorTitleBar
	sidebar.BorderSizePixel  = 0
	sidebar.ClipsDescendants = true
	sidebar.Parent           = body

	local sidebarCorner = Instance.new("UICorner")
	sidebarCorner.CornerRadius = UDim.new(0, 0)
	sidebarCorner.Parent       = sidebar

	local sidebarHeader = Instance.new("TextLabel")
	sidebarHeader.Name                   = "SidebarHeader"
	sidebarHeader.Size                   = UDim2.new(1, -20, 0, 16)
	sidebarHeader.Position               = UDim2.fromOffset(12, 10)
	sidebarHeader.BackgroundTransparency = 1
	sidebarHeader.Text                   = "PAGES"
	sidebarHeader.TextColor3             = colorTextSecondary
	sidebarHeader.TextTransparency       = 0.45
	sidebarHeader.TextSize               = 10
	sidebarHeader.FontFace               = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold)
	sidebarHeader.TextXAlignment         = Enum.TextXAlignment.Left
	sidebarHeader.Parent                 = sidebar

	local PLAYER_CARD_H = 64   

	local tabListScroll = Instance.new("ScrollingFrame")
	tabListScroll.Name                    = "TabList"
	tabListScroll.Position                = UDim2.fromOffset(0, 30)
	tabListScroll.Size                    = UDim2.new(1, 0, 1, -(32 + PLAYER_CARD_H))
	tabListScroll.BackgroundTransparency  = 1
	tabListScroll.BorderSizePixel         = 0
	tabListScroll.ScrollBarThickness      = 2
	tabListScroll.ScrollBarImageColor3    = colorBorder
	tabListScroll.ScrollBarImageTransparency = 0.6
	tabListScroll.CanvasSize              = UDim2.new(0, 0, 0, 0)
	tabListScroll.AutomaticCanvasSize     = Enum.AutomaticSize.Y
	tabListScroll.ClipsDescendants        = true
	tabListScroll.Parent                  = sidebar

	local sidebarLayout = Instance.new("UIListLayout")
	sidebarLayout.FillDirection     = Enum.FillDirection.Vertical
	sidebarLayout.VerticalAlignment = Enum.VerticalAlignment.Top
	sidebarLayout.Padding           = UDim.new(0, 4)
	sidebarLayout.SortOrder         = Enum.SortOrder.LayoutOrder
	sidebarLayout.Parent            = tabListScroll

	local sidebarPad = Instance.new("UIPadding")
	sidebarPad.PaddingLeft   = UDim.new(0, 8)
	sidebarPad.PaddingRight  = UDim.new(0, 8)
	sidebarPad.PaddingTop    = UDim.new(0, 2)
	sidebarPad.PaddingBottom = UDim.new(0, 8)
	sidebarPad.Parent        = tabListScroll

	
	local playerCardSlot = Instance.new("Frame")
	playerCardSlot.Name             = "PlayerCardSlot"
	playerCardSlot.AnchorPoint      = Vector2.new(0, 1)
	playerCardSlot.Position         = UDim2.fromScale(0, 1)
	playerCardSlot.Size             = UDim2.new(1, 0, 0, PLAYER_CARD_H)
	playerCardSlot.BackgroundTransparency = 1
	playerCardSlot.BorderSizePixel  = 0
	playerCardSlot.ClipsDescendants = false
	playerCardSlot.Parent           = sidebar

	
	local divider = Instance.new("Frame")
	divider.Name                   = "Divider"
	divider.AnchorPoint            = Vector2.new(0, 0)
	divider.Position               = UDim2.fromOffset(constants.sidebarWidth, 0)
	divider.Size                   = UDim2.new(0, 1, 1, 0)
	divider.BackgroundColor3       = colorBorder
	divider.BackgroundTransparency = 0.5
	divider.BorderSizePixel        = 0
	divider.ZIndex                 = 2
	divider.Parent                 = body

	local contentArea = Instance.new("Frame")
	contentArea.Name                   = "Content"
	contentArea.Position               = UDim2.fromOffset(constants.sidebarWidth + 1, 0)
	contentArea.Size                   = UDim2.new(1, -(constants.sidebarWidth + 1), 1, 0)
	contentArea.BackgroundTransparency = 1
	contentArea.ClipsDescendants       = true
	contentArea.Parent                 = body

	
	local SP_W    = 580
	local SP_H    = 420
	local SP_TB   = 44
	local SP_NAV  = 116

	local spAccent   = colorAccent
	
	
	
	local isTouchOnly = variables.isTouchOnly
	local userScale  = if isTouchOnly then 0.9 else 1.0
	local currentToggleKey = toggleKey
	local keepOnScreenVal  = keepOnScreen

	
	
	local spOverlay = element.makeOverlay(windowFrame, constants.zIndex.popup - 1)
	
	
	spOverlay.Position = UDim2.fromOffset(0, TITLEBAR_H + 1)
	spOverlay.Size     = UDim2.new(1, 0, 1, -(TITLEBAR_H + 1))
	
	
	spOverlay.Active   = true

	
	local settingsPanel = Instance.new("Frame")
	settingsPanel.Name             = "SettingsPanel"
	settingsPanel.AnchorPoint      = Vector2.new(0.5, 0.5)
	settingsPanel.Position         = UDim2.fromScale(0.5, 0.5)
	settingsPanel.Size             = UDim2.fromOffset(SP_W, SP_H)
	settingsPanel.BackgroundColor3 = colorSurface
	settingsPanel.BorderSizePixel  = 0
	settingsPanel.ClipsDescendants = true
	settingsPanel.ZIndex           = constants.zIndex.popup
	settingsPanel.Visible          = false
	settingsPanel.Parent           = windowFrame
	do
		local c = Instance.new("UICorner")
		c.CornerRadius = resolvedTheme.CornerRoundness or UDim.new(0, 8)
		c.Parent       = settingsPanel
	end
	do
		local g = Instance.new("UIGradient")
		g.Color    = resolvedTheme.WindowColor
			or ColorSequence.new(Color3.fromHex("#141414"), Color3.fromHex("#1c1c1c"))
		g.Rotation = 90
		g.Parent   = settingsPanel
	end
	do
		local sk = Instance.new("UIStroke")
		sk.Color           = colorBorder
		sk.Thickness       = 1
		sk.Transparency    = 0
		sk.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		sk.Parent          = settingsPanel
	end

	
	local spTB = Instance.new("Frame")
	spTB.Name             = "TitleBar"
	spTB.Size             = UDim2.new(1, 0, 0, SP_TB)
	spTB.BackgroundColor3 = colorTitleBar
	spTB.BorderSizePixel  = 0
	spTB.ZIndex           = constants.zIndex.popup
	spTB.Parent           = settingsPanel
	local spTBCornerCover: Frame = Instance.new("Frame") 
	spTBCornerCover.Size             = UDim2.new(0, 0, 0, 0)
	spTBCornerCover.BackgroundTransparency = 1
	spTBCornerCover.Parent           = spTB

	do
		local sep = Instance.new("Frame")
		sep.Name             = "Sep"
		sep.Size             = UDim2.new(1, 0, 0, 1)
		sep.Position         = UDim2.new(0, 0, 1, 0)
		sep.BackgroundColor3 = colorBorder
		sep.BorderSizePixel  = 0
		sep.ZIndex           = constants.zIndex.popup
		sep.Parent           = spTB
	end
	
	local spTBBadge = Instance.new("Frame")
	spTBBadge.Name             = "IconBadge"
	spTBBadge.AnchorPoint      = Vector2.new(0, 0.5)
	spTBBadge.Position         = UDim2.new(0, 12, 0.5, 0)
	spTBBadge.Size             = UDim2.fromOffset(26, 26)
	spTBBadge.BackgroundColor3 = colorAccent
	spTBBadge.BorderSizePixel  = 0
	spTBBadge.ZIndex           = constants.zIndex.popup + 1
	spTBBadge.Parent           = spTB
	do
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, 6)
		c.Parent       = spTBBadge
	end
	do
		local g = Instance.new("UIGradient")
		g.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.45),
			NumberSequenceKeypoint.new(1, 0.75),
		})
		g.Rotation = 135
		g.Parent   = spTBBadge
	end
	do
		local settingsIco = Instance.new("ImageLabel")
		settingsIco.Size                   = UDim2.fromOffset(14, 14)
		settingsIco.AnchorPoint            = Vector2.new(0.5, 0.5)
		settingsIco.Position               = UDim2.fromScale(0.5, 0.5)
		settingsIco.BackgroundTransparency = 1
		settingsIco.Image                  = ICON_SETTINGS
		settingsIco.ImageColor3            = Color3.fromRGB(255, 255, 255)
		settingsIco.ZIndex                 = constants.zIndex.popup + 2
		settingsIco.Parent                 = spTBBadge
	end

	local spTitle = Instance.new("TextLabel")
	spTitle.Name                   = "Title"
	spTitle.AnchorPoint            = Vector2.new(0, 0.5)
	spTitle.Position               = UDim2.new(0, 46, 0.5, 0)
	spTitle.Size                   = UDim2.new(0.6, -46, 0, 16)
	spTitle.BackgroundTransparency = 1
	spTitle.Text                   = "Settings"
	spTitle.TextColor3             = colorTextPrimary
	spTitle.TextSize               = 13
	spTitle.FontFace               = resolvedTheme.TitleFont
		or Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold)
	spTitle.TextXAlignment         = Enum.TextXAlignment.Left
	spTitle.ZIndex                 = constants.zIndex.popup + 1
	spTitle.Parent                 = spTB

	local spClose = Instance.new("TextButton")
	spClose.Name                   = "Close"
	spClose.AnchorPoint            = Vector2.new(1, 0.5)
	spClose.Position               = UDim2.new(1, -10, 0.5, 0)
	spClose.Size                   = UDim2.fromOffset(20, 20)
	spClose.BackgroundColor3       = colorSurfaceHover
	spClose.BackgroundTransparency = 0
	spClose.Text                   = ""
	spClose.AutoButtonColor        = false
	spClose.ZIndex                 = constants.zIndex.popup + 1
	spClose.Parent                 = spTB
	do
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, 4)
		c.Parent       = spClose
	end
	local spCloseIcon = Instance.new("ImageLabel")
	spCloseIcon.Name                   = "Icon"
	spCloseIcon.AnchorPoint            = Vector2.new(0.5, 0.5)
	spCloseIcon.Position               = UDim2.fromScale(0.5, 0.5)
	spCloseIcon.Size                   = UDim2.fromOffset(12, 12)
	spCloseIcon.BackgroundTransparency = 1
	spCloseIcon.Image                  = ICON_CLOSE
	spCloseIcon.ImageColor3            = colorTextSecondary
	spCloseIcon.ZIndex                 = constants.zIndex.popup + 2
	spCloseIcon.Parent                 = spClose

	spClose.MouseEnter:Connect(function()
		spClose.BackgroundColor3 = colorError
		spCloseIcon.ImageColor3  = Color3.fromRGB(255, 255, 255)
	end)
	spClose.MouseLeave:Connect(function()
		spClose.BackgroundColor3 = colorSurfaceHover
		spCloseIcon.ImageColor3  = colorTextSecondary
	end)
	spClose.MouseButton1Click:Connect(function()
		settingsPanel.Visible  = false
		spOverlay.Visible      = false
		bodyBlocker.Visible    = false
		variables.settingsOpen = false
	end)

	
	local spBody = Instance.new("Frame")
	spBody.Name                   = "Body"
	spBody.Position               = UDim2.fromOffset(0, SP_TB + 1)
	spBody.Size                   = UDim2.new(1, 0, 1, -(SP_TB + 1))
	spBody.BackgroundTransparency = 1
	spBody.ClipsDescendants       = false
	spBody.ZIndex                 = constants.zIndex.popup
	spBody.Parent                 = settingsPanel

	
	local spNav = Instance.new("Frame")
	spNav.Name             = "Nav"
	spNav.Size             = UDim2.new(0, SP_NAV, 1, 0)
	spNav.BackgroundColor3 = Color3.fromHex("#0e0e0e")
	spNav.BackgroundTransparency = 0
	spNav.BorderSizePixel  = 0
	spNav.ClipsDescendants = true
	spNav.ZIndex           = constants.zIndex.popup
	spNav.Parent           = spBody
	do
		local g = Instance.new("UIGradient")
		g.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromHex("#181818")),
			ColorSequenceKeypoint.new(1, Color3.fromHex("#101010")),
		})
		g.Rotation = 90
		g.Parent   = spNav
	end
	
	local spNavInner = Instance.new("Frame")
	spNavInner.Name             = "NavInner"
	spNavInner.Size             = UDim2.fromScale(1, 1)
	spNavInner.BackgroundTransparency = 1
	spNavInner.ZIndex           = constants.zIndex.popup
	spNavInner.Parent           = spNav
	do
		local p = Instance.new("UIPadding")
		p.PaddingTop    = UDim.new(0, 10)
		p.PaddingBottom = UDim.new(0, 10)
		p.PaddingLeft   = UDim.new(0, 7)
		p.PaddingRight  = UDim.new(0, 7)
		p.Parent        = spNavInner
	end
	local spNavLayout = Instance.new("UIListLayout")
	spNavLayout.FillDirection     = Enum.FillDirection.Vertical
	spNavLayout.VerticalAlignment = Enum.VerticalAlignment.Top
	spNavLayout.Padding           = UDim.new(0, 2)
	spNavLayout.SortOrder         = Enum.SortOrder.LayoutOrder
	spNavLayout.Parent            = spNavInner

	
	local spNavSectionLbl = Instance.new("TextLabel")
	spNavSectionLbl.Name                   = "SectionLbl"
	spNavSectionLbl.Size                   = UDim2.new(1, 0, 0, 22)
	spNavSectionLbl.BackgroundTransparency = 1
	spNavSectionLbl.Text                   = "PREFERENCES"
	spNavSectionLbl.TextColor3             = colorTextSecondary
	spNavSectionLbl.TextTransparency       = 0.5
	spNavSectionLbl.TextSize               = 9
	spNavSectionLbl.FontFace               = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold)
	spNavSectionLbl.TextXAlignment         = Enum.TextXAlignment.Left
	spNavSectionLbl.LayoutOrder            = 0
	spNavSectionLbl.ZIndex                 = constants.zIndex.popup + 1
	spNavSectionLbl.Parent                 = spNavInner
	do
		local p = Instance.new("UIPadding")
		p.PaddingLeft   = UDim.new(0, 5)
		p.PaddingBottom = UDim.new(0, 2)
		p.Parent        = spNavSectionLbl
	end

	
	local spNavDivLine = Instance.new("Frame")
	spNavDivLine.Name             = "NavDivLine"
	spNavDivLine.Position         = UDim2.fromOffset(SP_NAV, 0)
	spNavDivLine.Size             = UDim2.new(0, 1, 1, 0)
	spNavDivLine.BackgroundColor3 = colorBorder
	spNavDivLine.BackgroundTransparency = 0.4
	spNavDivLine.BorderSizePixel  = 0
	spNavDivLine.ZIndex           = constants.zIndex.popup + 1
	spNavDivLine.Parent           = spBody

	
	local spContent = Instance.new("ScrollingFrame")
	spContent.Name                    = "Content"
	spContent.Position                = UDim2.fromOffset(SP_NAV + 1, 0)
	spContent.Size                    = UDim2.new(1, -(SP_NAV + 1), 1, 0)
	spContent.BackgroundTransparency  = 1
	spContent.BorderSizePixel         = 0
	spContent.ScrollBarThickness      = 2
	spContent.ScrollBarImageColor3    = colorBorder
	spContent.ScrollBarImageTransparency = 0.5
	spContent.CanvasSize              = UDim2.fromOffset(0, 0)
	spContent.AutomaticCanvasSize     = Enum.AutomaticSize.Y
	spContent.ClipsDescendants        = true
	spContent.ZIndex                  = constants.zIndex.popup
	spContent.Parent                  = spBody

	local self: Window = nil :: any
	local s: any = nil
	local spAccentUpdaters: { (Color3) -> () } = {}

	
	
	
	
	local _preConns: { RBXScriptConnection } = {}

	
	
	
	
	
	local _accentBroadcastPending = false
	local function updateAccent(col: Color3)
		colorAccent = col
		spAccent = col
		accentStrip.BackgroundColor3 = col
		logoMark.BackgroundColor3 = col
		resolvedTheme.AccentColor = col
		resolvedTheme.ElementStrokeHover = col   
		resolvedTheme.SliderProgress = ColorSequence.new(col, col:Lerp(Color3.fromRGB(0, 0, 0), 0.25))
		resolvedTheme.AccentStroke = col:Lerp(Color3.fromRGB(255, 255, 255), 0.2)
		for _, fn in spAccentUpdaters do
			fn(col)
		end
		
		if not _accentBroadcastPending then
			_accentBroadcastPending = true
			task.defer(function()
				_accentBroadcastPending = false
				themeUtil.broadcast(resolvedTheme)
			end)
		end
	end

	
	local function spMakeRow(parent: Frame, label: string, order: number): Frame
		local row = Instance.new("Frame")
		row.Name                   = label
		row.Size                   = UDim2.new(1, 0, 0, constants.elementHeight)
		row.BackgroundTransparency = resolvedTheme.ElementTransparency or 0.97
		row.BackgroundColor3       = Color3.fromRGB(255, 255, 255)
		row.BorderSizePixel        = 0
		row.LayoutOrder            = order
		row.ZIndex                 = constants.zIndex.popup
		row.Parent                 = parent
		do
			local c = Instance.new("UICorner")
			c.CornerRadius = resolvedTheme.ElementCornerRadius or UDim.new(0, 6)
			c.Parent       = row
		end
		do
			local g = Instance.new("UIGradient")
			g.Color    = resolvedTheme.ElementGradient
				or ColorSequence.new(Color3.fromHex("#1e1e1e"), Color3.fromHex("#1a1a1a"))
			g.Rotation = 90
			g.Parent   = row
		end
		do
			local sk = Instance.new("UIStroke")
			sk.Color           = resolvedTheme.ElementStroke or Color3.fromRGB(50, 42, 80)
			sk.Thickness       = 1
			sk.Transparency    = resolvedTheme.ElementStrokeTransparency or 0.6
			sk.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			sk.Parent          = row
		end
		do
			local p = Instance.new("UIPadding")
			p.PaddingLeft  = UDim.new(0, 10)
			p.PaddingRight = UDim.new(0, 10)
			p.Parent       = row
		end
		local lbl = Instance.new("TextLabel")
		lbl.Name                   = "Label"
		lbl.AnchorPoint            = Vector2.new(0, 0.5)
		lbl.Position               = UDim2.fromScale(0, 0.5)
		lbl.Size                   = UDim2.new(1, -165, 0, 14)
		lbl.BackgroundTransparency = 1
		lbl.ClipsDescendants       = true
		lbl.TextTruncate           = Enum.TextTruncate.AtEnd
		lbl.Text                   = label
		lbl.TextColor3             = resolvedTheme.ContentColor or Color3.fromRGB(220, 215, 240)
		lbl.TextSize               = 12
		lbl.FontFace               = resolvedTheme.Font
			or Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium)
		lbl.TextXAlignment         = Enum.TextXAlignment.Left
		lbl.ZIndex                 = constants.zIndex.popup
		lbl.Parent                 = row
		return row
	end

	
	local function spMakeSlider(
		parent: Frame,
		label: string,
		minVal: number,
		maxVal: number,
		stepVal: number,
		currentVal: number,
		suffix: string,
		order: number,
		callback: (val: number) -> ()
	)
		local row = spMakeRow(parent, label, order)

		local valLabel = Instance.new("TextLabel")
		valLabel.Name                   = "Value"
		valLabel.AnchorPoint            = Vector2.new(1, 0.5)
		valLabel.Position               = UDim2.new(1, -12, 0.5, 0)
		valLabel.Size                   = UDim2.new(0, 42, 0, 14)
		valLabel.BackgroundTransparency = 1
		valLabel.TextColor3             = colorTextSecondary
		valLabel.TextSize               = 11
		valLabel.FontFace               = resolvedTheme.Font
			or Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium)
		valLabel.TextXAlignment         = Enum.TextXAlignment.Right
		valLabel.ZIndex                 = constants.zIndex.popup + 1
		valLabel.Parent                 = row

		local trackW = 100
		local trackH = 4
		local track = Instance.new("Frame")
		track.Name             = "Track"
		track.AnchorPoint      = Vector2.new(1, 0.5)
		track.Position         = UDim2.new(1, -60, 0.5, 0)
		track.Size             = UDim2.new(0, trackW, 0, trackH)
		track.BackgroundColor3 = Color3.fromRGB(38, 36, 52)
		track.BorderSizePixel  = 0
		track.ZIndex           = constants.zIndex.popup + 1
		track.Parent           = row
		do
			local c = Instance.new("UICorner")
			c.CornerRadius = UDim.new(1, 0)
			c.Parent       = track
		end

		local fill = Instance.new("Frame")
		fill.Name             = "Fill"
		fill.Size             = UDim2.fromScale(0, 1)
		fill.BackgroundColor3 = spAccent
		fill.BorderSizePixel  = 0
		fill.ZIndex           = constants.zIndex.popup + 2
		fill.Parent           = track
		do
			local c = Instance.new("UICorner")
			c.CornerRadius = UDim.new(1, 0)
			c.Parent       = fill
		end

		local knob = Instance.new("Frame")
		knob.Name             = "Knob"
		knob.AnchorPoint      = Vector2.new(0.5, 0.5)
		knob.Position         = UDim2.fromScale(0, 0.5)
		knob.Size             = UDim2.fromOffset(10, 10)
		knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		knob.BorderSizePixel  = 0
		knob.ZIndex           = constants.zIndex.popup + 3
		knob.Parent           = track
		do
			local c = Instance.new("UICorner")
			c.CornerRadius = UDim.new(1, 0)
			c.Parent       = knob
		end

		table.insert(spAccentUpdaters, function(newAccent)
			fill.BackgroundColor3 = newAccent
		end)

		local function updateVisual(val: number)
			val = math.clamp(val, minVal, maxVal)
			local alpha = if maxVal > minVal then (val - minVal) / (maxVal - minVal) else 0
			alpha = math.clamp(alpha, 0, 1)
			fill.Size = UDim2.fromScale(alpha, 1)
			knob.Position = UDim2.fromScale(alpha, 0.5)
			if stepVal >= 1 then
				valLabel.Text = string.format("%d%s", math.round(val), suffix)
			else
				valLabel.Text = string.format("%.1f%s", val, suffix)
			end
		end

		updateVisual(currentVal)

		local trigger = Instance.new("TextButton")
		trigger.Name                   = "Trigger"
		trigger.AnchorPoint            = Vector2.new(0.5, 0.5)
		trigger.Position               = UDim2.fromScale(0.5, 0.5)
		trigger.Size                   = UDim2.new(1, 16, 1, 20)
		trigger.BackgroundTransparency = 1
		trigger.Text                   = ""
		trigger.ZIndex                 = constants.zIndex.popup + 4
		trigger.Parent                 = track

		local dragging = false
		local lastSnapped = currentVal

		local function setFromMouse(posX: number)
			local relX = posX - track.AbsolutePosition.X
			local tw = track.AbsoluteSize.X
			local alpha = math.clamp(relX / math.max(tw, 1), 0, 1)
			local rawVal = minVal + alpha * (maxVal - minVal)
			local snapped = if stepVal > 0 then minVal + math.round((rawVal - minVal) / stepVal) * stepVal else rawVal
			snapped = math.clamp(snapped, minVal, maxVal)
			updateVisual(snapped)
			if snapped ~= lastSnapped then
				lastSnapped = snapped
				callback(snapped)
			end
		end

		trigger.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				
				local posX = if input.UserInputType == Enum.UserInputType.Touch
					then input.Position.X
					else variables.userInputService:GetMouseLocation().X
				setFromMouse(posX)
			end
		end)

		
		
		
		table.insert(_preConns, variables.userInputService.InputChanged:Connect(function(input)
			if not settingsPanel.Visible then
				dragging = false
				return
			end
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				local posX = if input.UserInputType == Enum.UserInputType.Touch
					then input.Position.X
					else variables.userInputService:GetMouseLocation().X
				setFromMouse(posX)
			end
		end))

		table.insert(_preConns, variables.userInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = false
			end
		end))

		
		local rowStroke = row:FindFirstChildWhichIsA("UIStroke")
		trigger.MouseEnter:Connect(function()
			if rowStroke then
				rowStroke.Color = spAccent
				rowStroke.Transparency = 0.15
			end
		end)
		trigger.MouseLeave:Connect(function()
			if dragging then return end
			if rowStroke then
				rowStroke.Color = resolvedTheme.ElementStroke or Color3.fromHex("#2b2b2b")
				rowStroke.Transparency = resolvedTheme.ElementStrokeTransparency or 0.6
			end
		end)
	end

	
	
	
	
	

	
	local function spMakePage(parentFrame: ScrollingFrame): Frame
		local pg = Instance.new("Frame")
		pg.Name                   = "Page"
		pg.Size                   = UDim2.new(1, -24, 0, 0)
		pg.Position               = UDim2.fromOffset(12, 8)
		pg.AutomaticSize          = Enum.AutomaticSize.Y
		pg.BackgroundTransparency = 1
		pg.Visible                = false
		pg.ZIndex                 = constants.zIndex.popup
		pg.Parent                 = parentFrame
		do
			local l = Instance.new("UIListLayout")
			l.FillDirection     = Enum.FillDirection.Vertical
			l.VerticalAlignment = Enum.VerticalAlignment.Top
			l.Padding           = UDim.new(0, constants.elementPadding)
			l.SortOrder         = Enum.SortOrder.LayoutOrder
			l.Parent            = pg
		end
		do
			local p = Instance.new("UIPadding")
			p.PaddingBottom = UDim.new(0, 14)
			p.Parent        = pg
		end
		return pg
	end

	
	local spActiveNavItem: Frame? = nil
	local spNavPages: { [Frame]: Frame } = {}

	local function spMakeNavItem(label: string, iconChar: string, order: number): Frame
		local item = Instance.new("Frame")
		item.Name             = "NavItem_" .. label
		item.Size             = UDim2.new(1, 0, 0, 34)
		item.BackgroundColor3 = Color3.fromHex("#1e1e1e")
		item.BackgroundTransparency = 1
		item.BorderSizePixel  = 0
		item.LayoutOrder      = order
		item.ClipsDescendants = false
		item.ZIndex           = constants.zIndex.popup + 1
		item.Parent           = spNavInner
		do
			local c = Instance.new("UICorner")
			c.CornerRadius = UDim.new(0, 6)
			c.Parent       = item
		end

		
		local activeBar = Instance.new("Frame")
		activeBar.Name             = "ActiveBar"
		activeBar.AnchorPoint      = Vector2.new(0, 0.5)
		activeBar.Position         = UDim2.new(0, 0, 0.5, 0)
		activeBar.Size             = UDim2.fromOffset(3, 14)
		activeBar.BackgroundColor3 = colorAccent
		activeBar.BorderSizePixel  = 0
		activeBar.Visible          = false
		activeBar.ZIndex           = constants.zIndex.popup + 2
		activeBar.Parent           = item
		do
			local c = Instance.new("UICorner")
			c.CornerRadius = UDim.new(1, 0)
			c.Parent       = activeBar
		end

		
		local iconBadge = Instance.new("Frame")
		iconBadge.Name             = "IconBadge"
		iconBadge.AnchorPoint      = Vector2.new(0, 0.5)
		iconBadge.Position         = UDim2.new(0, 10, 0.5, 0)
		iconBadge.Size             = UDim2.fromOffset(20, 20)
		iconBadge.BackgroundColor3 = Color3.fromHex("#242424")
		iconBadge.BorderSizePixel  = 0
		iconBadge.ZIndex           = constants.zIndex.popup + 2
		iconBadge.Parent           = item
		do
			local c = Instance.new("UICorner")
			c.CornerRadius = UDim.new(0, 5)
			c.Parent       = iconBadge
		end
		local iconLbl = Instance.new("TextLabel")
		iconLbl.Name                   = "Icon"
		iconLbl.Size                   = UDim2.fromScale(1, 1)
		iconLbl.BackgroundTransparency = 1
		iconLbl.Text                   = iconChar
		iconLbl.TextColor3             = colorTextSecondary
		iconLbl.TextSize               = 10
		iconLbl.FontFace               = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold)
		iconLbl.TextXAlignment         = Enum.TextXAlignment.Center
		iconLbl.ZIndex                 = constants.zIndex.popup + 3
		iconLbl.Parent                 = iconBadge

		
		local lbl = Instance.new("TextLabel")
		lbl.Name                   = "Label"
		lbl.AnchorPoint            = Vector2.new(0, 0.5)
		lbl.Position               = UDim2.new(0, 36, 0.5, 0)
		lbl.Size                   = UDim2.new(1, -36, 0, 14)
		lbl.BackgroundTransparency = 1
		lbl.Text                   = label
		lbl.TextColor3             = colorTextSecondary
		lbl.TextSize               = 11
		lbl.FontFace               = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium)
		lbl.TextXAlignment         = Enum.TextXAlignment.Left
		lbl.ZIndex                 = constants.zIndex.popup + 2
		lbl.Parent                 = item

		
		local hit = Instance.new("TextButton")
		hit.Name                   = "Hit"
		hit.Size                   = UDim2.fromScale(1, 1)
		hit.BackgroundTransparency = 1
		hit.Text                   = ""
		hit.AutoButtonColor        = false
		hit.ZIndex                 = constants.zIndex.popup + 3
		hit.Parent                 = item

		hit.MouseEnter:Connect(function()
			if spActiveNavItem ~= item then
				item.BackgroundTransparency = 0.82
				lbl.TextColor3 = colorTextPrimary
				iconBadge.BackgroundColor3 = Color3.fromHex("#2c2c2c")
			end
		end)
		hit.MouseLeave:Connect(function()
			if spActiveNavItem ~= item then
				item.BackgroundTransparency = 1
				lbl.TextColor3 = colorTextSecondary
				iconBadge.BackgroundColor3 = Color3.fromHex("#242424")
			end
		end)
		hit.MouseButton1Click:Connect(function()
			if spActiveNavItem == item then return end
			
			if spActiveNavItem then
				local oldBar   = spActiveNavItem:FindFirstChild("ActiveBar")
				local oldLbl   = spActiveNavItem:FindFirstChild("Label")
				local oldBadge = spActiveNavItem:FindFirstChild("IconBadge")
				local oldIco   = if oldBadge then (oldBadge :: Frame):FindFirstChild("Icon") else nil
				spActiveNavItem.BackgroundTransparency = 1
				if oldBar   then (oldBar   :: Frame).Visible             = false end
				if oldLbl   then (oldLbl   :: TextLabel).TextColor3      = colorTextSecondary end
				if oldBadge then (oldBadge :: Frame).BackgroundColor3    = Color3.fromHex("#242424") end
				if oldIco   then (oldIco   :: TextLabel).TextColor3      = colorTextSecondary end
				local oldPage = spNavPages[spActiveNavItem]
				if oldPage then oldPage.Visible = false end
			end
			
			spActiveNavItem = item
			item.BackgroundTransparency = 0.86
			item.BackgroundColor3 = colorAccent
			activeBar.Visible     = true
			lbl.TextColor3        = colorAccent
			iconBadge.BackgroundColor3 = colorAccent
			iconLbl.TextColor3    = Color3.fromRGB(255, 255, 255)
			local newPage = spNavPages[item]
			if newPage then
				newPage.Visible = true
				spContent.CanvasPosition = Vector2.zero
			end
		end)

		return item
	end

	
	local pageAppearance = spMakePage(spContent)
	pageAppearance.Name = "PageAppearance"

	local pageControls = spMakePage(spContent)
	pageControls.Name = "PageControls"

	local pageFont = spMakePage(spContent)
	pageFont.Name = "PageFont"

	
	local navItemAppearance = spMakeNavItem("Appearance", "◈",  1)
	local navItemControls   = spMakeNavItem("Controls",   "⌨",  2)
	local navItemFont       = spMakeNavItem("Font",       "Aa", 3)

	spNavPages[navItemAppearance] = pageAppearance
	spNavPages[navItemControls]   = pageControls
	spNavPages[navItemFont]       = pageFont

	
	local currentCornerRadius = (resolvedTheme.CornerRoundness or UDim.new(0, 10)).Offset
	spMakeSlider(pageAppearance, "Corner Roundness", 0, 16, 1, currentCornerRadius, "px", 1, function(r)
		local cr = UDim.new(0, r)
		winCorner.CornerRadius = cr
		titleBarCorner.CornerRadius = cr
		cornerCover.Size = UDim.new(1, 0, 0, r)
		cornerCover.Position = UDim.new(0, 0, 1, -r)
		resolvedTheme.CornerRoundness = cr
	end)

	local function smoothSetScale(factor: number)
		userScale = factor
		if s then s._userScale = factor end
		variables.uiScale = factor
		if s and s._scaleTween then
			s._scaleTween:Cancel()
		end
		local tw = variables.tweenService:Create(
			winScale,
			TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Scale = factor }
		)
		if s then s._scaleTween = tw end
		tw.Completed:Once(function()
			tw:Destroy()
			if s then s._scaleTween = nil end
			if not self then return end
			local wf = (self :: any)._windowFrame
			if not wf then return end
			local screen = (self :: any)._gui.AbsoluteSize
			local margin = 8
			local curW = wf.AbsoluteSize.X
			local curH = wf.AbsoluteSize.Y
			local curPos = wf.Position
			local newX = curPos.X.Offset
			local newY = curPos.Y.Offset
			if curW >= screen.X - margin * 2 then
				newX = math.floor(screen.X / 2)
			else
				newX = math.clamp(newX, margin + math.floor(curW / 2), screen.X - margin - math.ceil(curW / 2))
			end
			if curH >= screen.Y - margin * 2 then
				newY = math.floor(screen.Y / 2)
			else
				newY = math.clamp(newY, margin + math.floor(curH / 2), screen.Y - margin - math.ceil(curH / 2))
			end
			local clamped = UDim2.fromOffset(newX, newY)
			if clamped ~= curPos then
				if s and s._posScaleTween then s._posScaleTween:Cancel() end
				local posTw = variables.tweenService:Create(
					wf,
					TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{ Position = clamped }
				)
				if s then s._posScaleTween = posTw end
				posTw:Play()
			end
		end)
		tw:Play()
	end

	spMakeSlider(pageAppearance, "UI Scale / DPI", 80, 125, 5, 100, "%", 2, function(pct)
		smoothSetScale(pct / 100)
	end)

	do
		local cp = ColorPicker.new({
			name     = "Accent Color",
			color    = colorAccent,
			callback = function(col: Color3, _alpha: number)
				updateAccent(col)
			end,
		}, resolvedTheme, pageAppearance)
		cp._frame.LayoutOrder = 3
	end

	spMakeSlider(pageAppearance, "Background Transparency", 0, 25, 5, 0, "%", 4, function(pct)
		windowFrame.BackgroundTransparency = pct / 100
	end)

	
	do
		local kb = Keybind.new({
			name      = "Menu Keybind",
			value     = currentToggleKey,
			onChanged = function(newKey: Enum.KeyCode)
				currentToggleKey = newKey
				if s then s._toggleKey = newKey end
			end,
		}, resolvedTheme, pageControls)
		kb._frame.LayoutOrder = 1
	end

	
	do
		local FONT_MAP: { [string]: string } = {
			["Gotham"]          = "rbxasset://fonts/families/GothamSSm.json",
			["Roboto"]          = "rbxasset://fonts/families/Roboto.json",
			["Source Sans Pro"] = "rbxasset://fonts/families/SourceSansPro.json",
			["Ubuntu"]          = "rbxasset://fonts/families/Ubuntu.json",
			["Syne"]            = "rbxasset://fonts/families/Syne.json",
			["Nunito"]          = "rbxasset://fonts/families/Nunito.json",
			["Builder Sans"]    = "rbxasset://fonts/families/BuilderSans.json",
			["Jura"]            = "rbxasset://fonts/families/Jura.json",
		}
		local fontDD = Dropdown.new({
			name        = "UI Font",
			options     = { "Gotham", "Roboto", "Source Sans Pro", "Ubuntu", "Syne", "Nunito", "Builder Sans", "Jura" },
			value       = "Gotham",
			layoutOrder = 1,
			callback    = function(val: any)
				local family = FONT_MAP[tostring(val)] or "rbxasset://fonts/families/GothamSSm.json"
				resolvedTheme.Font      = Font.new(family, Enum.FontWeight.Medium)
				resolvedTheme.TitleFont = Font.new(family, Enum.FontWeight.SemiBold)
				themeUtil.broadcast(resolvedTheme)
				for _, desc in windowFrame:GetDescendants() do
					if desc:IsA("TextLabel") or desc:IsA("TextButton") then
						local existing = (desc :: TextLabel).FontFace
						;(desc :: TextLabel).FontFace = Font.new(family, existing.Weight, existing.Style)
					end
				end
			end,
		}, resolvedTheme, pageFont)
		fontDD._frame.LayoutOrder = 1
	end

	
	do
		local firstItem = navItemAppearance
		spActiveNavItem        = firstItem
		firstItem.BackgroundTransparency = 0.86
		firstItem.BackgroundColor3       = colorAccent
		local bar   = firstItem:FindFirstChild("ActiveBar")
		local lbl   = firstItem:FindFirstChild("Label")
		local badge = firstItem:FindFirstChild("IconBadge")
		if bar   then (bar   :: Frame).Visible             = true end
		if lbl   then (lbl   :: TextLabel).TextColor3      = colorAccent end
		if badge then
			(badge :: Frame).BackgroundColor3 = colorAccent
			local ico = (badge :: Frame):FindFirstChild("Icon")
			if ico then (ico :: TextLabel).TextColor3 = Color3.fromRGB(255, 255, 255) end
		end
		pageAppearance.Visible = true
	end

	local function updateSettingsPanelSize()
		local winW = if windowFrame.Size.X.Offset > 0 then windowFrame.Size.X.Offset else windowFrame.AbsoluteSize.X
		local winH = if windowFrame.Size.Y.Offset > 0 then windowFrame.Size.Y.Offset else windowFrame.AbsoluteSize.Y
		local availableW = math.max(200, winW - 24)
		local availableH = math.max(150, winH - (TITLEBAR_H + 20))

		local targetW = math.min(SP_W, availableW)
		local targetH = math.min(SP_H, availableH)
		settingsPanel.Size = UDim2.fromOffset(targetW, targetH)
	end

	
	settingsBtn.MouseButton1Click:Connect(function()
		local next = not settingsPanel.Visible
		if next then
			updateSettingsPanelSize()
		end
		settingsPanel.Visible = next
		spOverlay.Visible     = next
		bodyBlocker.Visible    = next
		variables.settingsOpen = next
	end)

	windowFrame:GetPropertyChangedSignal("Size"):Connect(function()
		if settingsPanel.Visible then
			updateSettingsPanelSize()
		end
	end)

	
	self = setmetatable({}, Window) :: Window
	self.unloaded = false
	self._gui     = gui
	s = (self :: any)
	s._windowFrame   = windowFrame
	s._winScale      = winScale
	s._userScale     = userScale
	s._toggleKey     = currentToggleKey
	s._sidebar       = tabListScroll
	s._sidebarFrame    = sidebar
	s._playerCardSlot  = playerCardSlot
	s._contentArea   = contentArea
	s._divider       = divider
	s._theme         = resolvedTheme
	s._tabs          = {} :: { Tab.Tab }
	s._activeTab     = nil :: Tab.Tab?
	s._visible       = false
	s._minimized     = false
	s._hasBeenDragged = false
	s._windowSize    = initialSize    
	s._titlebarH     = TITLEBAR_H
	s._body          = body
	s._minBtn        = minBtn
	s._minIcon       = minIcon
	s._titleSep      = titleSep
	s._keepOnScreen  = keepOnScreenVal
	s._dragging      = false          
	s._pendingResize = false          
	s._connections   = _preConns      
	s._activeTween    = nil           
	s._scaleTween     = nil           
	s._posScaleTween  = nil           
	s._activeAnimConn = nil           
	s._minimizeAnimId = nil           
	s._titleBarBg     = titleBarBg
	s._titleBarCorner = titleBarCorner
	s._cornerCover    = cornerCover

	
	if userScale ~= 1.0 then
		winScale.Scale       = userScale
		variables.uiScale    = userScale
		s._userScale         = userScale
	end

	
	
	if isTouchOnly then
		for _, btn in { settingsBtn, minBtn, closeBtn } :: { TextButton } do
			btn.Size = UDim2.fromOffset(34, 34)
		end
		
		controlsFrame.Size = UDim2.fromOffset(120, 36)
	end

	
	s._themeUnsub = themeUtil.subscribe(function(t)
		s._theme = t
		winStroke.Color = t.SurfaceStroke
		winGradient.Color = t.WindowColor
		if s._titleBarBg then (s._titleBarBg :: Frame).BackgroundColor3 = t.TitleBarColor end
		titleSep.BackgroundColor3 = t.SurfaceStroke
		sidebar.BackgroundColor3 = t.TitleBarColor
		sidebarHeader.TextColor3 = t.PlaceholderColor
		tabListScroll.ScrollBarImageColor3 = t.SurfaceStroke
		spTB.BackgroundColor3 = t.TitleBarColor
		settingsBtn.BackgroundColor3 = t.NeutralButton
		minBtn.BackgroundColor3 = t.NeutralButton
		closeBtn.BackgroundColor3 = t.NeutralButton
		settingsIcon.ImageColor3 = t.PlaceholderColor
		minIcon.ImageColor3 = t.PlaceholderColor
		closeIcon.ImageColor3 = t.PlaceholderColor
		spClose.BackgroundColor3 = t.NeutralButton
		spCloseIcon.ImageColor3 = t.PlaceholderColor
		colorSurface = t.WindowColor.Keypoints[1].Value
		colorTitleBar = t.TitleBarColor
		colorBorder = t.SurfaceStroke
		colorSurfaceHover = t.NeutralButton
		colorAccent = t.AccentColor
		spAccent = t.AccentColor
		colorError = t.ErrorColor
		colorTextPrimary = t.TitlingColor
		colorTextSecondary = t.PlaceholderColor
		for _, fn in spAccentUpdaters do
			fn(t.AccentColor)
		end
	end)

	
	do
		local uis        = variables.userInputService
		local dragging   = false
		local dragStart  = Vector3.zero
		local startPos   = UDim2.fromOffset(0, 0)
		local lastX, lastY = 0, 0

		
		local function interactive(): boolean
			return (self :: any)._visible
		end

		titleBar.InputBegan:Connect(function(input, processed)
			if processed then return end
			if input.UserInputType ~= Enum.UserInputType.MouseButton1
				and input.UserInputType ~= Enum.UserInputType.Touch then return end
			if not interactive() then return end

			
			local mouse = uis:GetMouseLocation()
			local cp    = controlsFrame.AbsolutePosition
			local cs    = controlsFrame.AbsoluteSize
			if mouse.X >= cp.X - 4 and mouse.X <= cp.X + cs.X + 4
				and mouse.Y >= cp.Y - 4 and mouse.Y <= cp.Y + cs.Y + 4 then
				return
			end

			dragging  = true
			dragStart = input.Position
			startPos  = windowFrame.Position
			lastX     = startPos.X.Offset
			lastY     = startPos.Y.Offset

			local _ds = (self :: any)
			_ds._dragging = true
			_ds._hasBeenDragged = true
		end)

		local inputChangedConn = uis.InputChanged:Connect(function(input)
			if not dragging then return end
			if input.UserInputType ~= Enum.UserInputType.MouseMovement
				and input.UserInputType ~= Enum.UserInputType.Touch then return end
			if not interactive() then return end

			local delta = input.Position - dragStart
			if math.abs(delta.X) < 1 and math.abs(delta.Y) < 1 then return end

			local newX = startPos.X.Offset + delta.X
			local newY = startPos.Y.Offset + delta.Y

			if (self :: any)._keepOnScreen then
				local screen = gui.AbsoluteSize
				local curW   = windowFrame.AbsoluteSize.X
				local curH   = windowFrame.AbsoluteSize.Y
				local margin = 8

				if curW >= screen.X - margin * 2 then
					newX = math.floor(screen.X / 2)
				else
					local minX = margin + math.floor(curW / 2)
					local maxX = screen.X - margin - math.ceil(curW / 2)
					newX = math.clamp(newX, minX, maxX)
				end

				if curH >= screen.Y - margin * 2 then
					newY = math.floor(screen.Y / 2)
				else
					local minY = margin + math.floor(curH / 2)
					local maxY = screen.Y - margin - math.ceil(curH / 2)
					newY = math.clamp(newY, minY, maxY)
				end
			end

			if math.abs(newX - lastX) < 0.5 and math.abs(newY - lastY) < 0.5 then return end
			lastX, lastY = newX, newY
			windowFrame.Position = UDim2.fromOffset(newX, newY)
		end)
		table.insert((self :: any)._connections, inputChangedConn)

		local function release()
			if not dragging then return end
			dragging = false
			local _ds = (self :: any)
			_ds._dragging = false
		end

		local inputEndedConn = uis.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch then
				release()
			end
		end)
		table.insert((self :: any)._connections, inputEndedConn)

		local wfr = uis.WindowFocusReleased:Connect(release)
		table.insert((self :: any)._connections, wfr)
	end

	
	closeBtn.MouseButton1Click:Connect(function()
		self:Unload()
	end)

	minBtn.MouseButton1Click:Connect(function()
		self:ToggleMinimise()
	end)

	
	
	
	table.insert(s._connections, variables.userInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if self.unloaded then return end
		local activeKey = (self :: any)._toggleKey or toggleKey
		if input.KeyCode == activeKey then
			self:ToggleHide()
		end
	end))

	windowFrame.Visible = false

	
	self:_watchViewport()

	return self
end



function Window:_clampedPositionForScale(position: UDim2, scale: number): UDim2
	if not (self :: any)._keepOnScreen then return position end

	local screen = self._gui.AbsoluteSize
	local s      = (self :: any)
	local baseW  = if s._windowFrame then s._windowFrame.Size.X.Offset else s._windowSize.X.Offset
	local baseH  = if s._minimized then s._titlebarH else s._windowSize.Y.Offset
	local curW   = baseW * scale
	local curH   = baseH * scale
	local margin = 8

	local newX = position.X.Offset
	local newY = position.Y.Offset

	if curW >= screen.X - margin * 2 then
		newX = math.floor(screen.X / 2)
	else
		local minX = margin + math.floor(curW / 2)
		local maxX = screen.X - margin - math.ceil(curW / 2)
		newX = math.clamp(newX, minX, maxX)
	end

	if curH >= screen.Y - margin * 2 then
		newY = math.floor(screen.Y / 2)
	else
		local minY = margin + math.floor(curH / 2)
		local maxY = screen.Y - margin - math.ceil(curH / 2)
		newY = math.clamp(newY, minY, maxY)
	end

	if newX == position.X.Offset and newY == position.Y.Offset then return position end
	return UDim2.fromOffset(newX, newY)
end


function Window:_clampedPosition(position: UDim2): UDim2
	if not (self :: any)._keepOnScreen then return position end
	local s = (self :: any)
	local scale = if s._winScale then s._winScale.Scale else 1.0
	return self:_clampedPositionForScale(position, scale)
end

function Window:_clampToScreen()
	local wf: Frame = (self :: any)._windowFrame
	wf.Position = self:_clampedPosition(wf.Position)
end



function Window:_applyWindowSize()
	if self.unloaded then return end
	local s = (self :: any)

	
	local cam = variables.workspace.CurrentCamera
	local userMultiplier = s._userScale or 1.0
	variables.uiScale = userMultiplier
	if s._winScale and s._scaleTween == nil then
		s._winScale.Scale = userMultiplier
	end

	local newSize = fitWindowSize()
	local changed = newSize ~= s._windowSize
	s._windowSize = newSize

	local hidden    = not s._visible
	local minimized = s._minimized
	local dragging  = s._dragging

	if hidden or minimized or dragging or s._activeTween ~= nil then
		if changed then s._pendingResize = true end
		return
	end

	if not changed and not s._pendingResize then return end
	s._pendingResize = false

	local wf: Frame = (self :: any)._windowFrame
	wf.Size = newSize

	if not s._hasBeenDragged and vp then
		wf.Position = UDim2.fromOffset(
			math.max(0, math.floor((vp.X - newSize.X.Offset) / 2)),
			math.max(0, math.floor((vp.Y - newSize.Y.Offset) / 2))
		)
	else
		self:_clampToScreen()
	end
end



function Window:_watchViewport()
	local cameraConn: RBXScriptConnection? = nil
	local pending = false

	local function request()
		if pending then return end
		pending = true
		task.defer(function()
			pending = false
			self:_applyWindowSize()
		end)
	end

	local function bind()
		if cameraConn then cameraConn:Disconnect(); cameraConn = nil end
		local cam = variables.workspace.CurrentCamera
		if cam then
			
			
			
			cameraConn = cam:GetPropertyChangedSignal("ViewportSize"):Connect(request)
		end
		request()
	end

	local camSwapConn = variables.workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(bind)
	table.insert((self :: any)._connections, camSwapConn)
	bind()

	local sinceReconcile = 0
	local hbConn = variables.runService.Heartbeat:Connect(function(delta: number)
		if self.unloaded then return end
		sinceReconcile += delta
		if sinceReconcile < VIEWPORT_RECONCILE_INTERVAL then return end
		sinceReconcile = 0
		self:_applyWindowSize()
	end)
	table.insert((self :: any)._connections, hbConn)
end



function Window:CreateTab(props: Tab.TabProps): Tab.Tab
	local tabs: { Tab.Tab }        = (self :: any)._tabs
	local sidebar: Frame           = (self :: any)._sidebar
	local contentArea: Frame       = (self :: any)._contentArea
	local theme: { [string]: any } = (self :: any)._theme
	local wf: Frame                = (self :: any)._windowFrame

	local t = Tab.new(props, theme, contentArea, sidebar, wf)

	local btn = (t :: any)._tabButton

	btn.MouseButton1Click:Connect(function()
		local _s = (self :: any)
		
		if _s._playerCard then
			(_s._playerCard :: any):HideContent()
		end
		_s:_activateTab(t)
	end)

	table.insert(tabs, t)
	btn.LayoutOrder = #tabs

	if #tabs == 1 then
		local _s = (self :: any)
		_s:_activateTab(t)
	else
		t:Hide()
	end

	return t
end



function Window:CreatePlayerCard()
	local s            = (self :: any)
	local slot: Frame  = s._playerCardSlot
	local wf: Frame    = s._windowFrame
	local ca: Frame    = s._contentArea
	local theme        = s._theme

	local pc = PlayerCard.new(slot, wf, ca, theme)
	s._playerCard = pc

	
	local cardHit = (pc :: any)._cardHit :: TextButton?
	if cardHit then
		cardHit.MouseButton1Click:Connect(function()
			for _, tab in (s._tabs :: { any }) do
				tab:Hide()
			end
			s._activeTab = nil
			pc:ShowContent()
		end)
	end

	return pc
end

function Window:_activateTab(target: Tab.Tab)
	local s = (self :: any)
	local tabs: { Tab.Tab } = s._tabs
	for _, tab in tabs do
		if tab == target then
			tab:Show()
		else
			tab:Hide()
		end
	end
	s._activeTab = target
end



function Window:Notify(props: notification.NotifyProps)
	if self.unloaded then return end
	notification.send(props, (self :: any)._theme)
end



function Window:Show()
	if self.unloaded then return end
	local s = (self :: any)
	local windowFrame: Frame = s._windowFrame

	
	if s._minimized then
		if s._activeTween then
			s._activeTween:Cancel()
			s._activeTween = nil
		end
		s._minimized = false
		;(s._body :: Frame).Visible = true
		if s._divider then (s._divider :: Frame).Visible = true end
		if s._titleSep then (s._titleSep :: Frame).Visible = true end
		if s._cornerCover then (s._cornerCover :: Frame).Visible = true end
		local fullH: number = s._windowSize.Y.Offset
		local topY = windowFrame.Position.Y.Offset - math.floor(s._titlebarH / 2)
		local restoreCenterY = topY + math.floor(fullH / 2)
		windowFrame.Position = self:_clampedPosition(UDim2.fromOffset(windowFrame.Position.X.Offset, restoreCenterY))
		windowFrame.Size = s._windowSize
		;(s._minBtn :: TextButton).Text = ""
		if s._minIcon then (s._minIcon :: ImageLabel).Image = ICON_MINIMIZE end
	end

	
	if s._pendingResize then
		s._pendingResize = false
		windowFrame.Size = s._windowSize
	end

	s._visible   = true
	windowFrame.Position = self:_clampedPosition(windowFrame.Position)

	
	
	
	
	
	windowFrame.BackgroundTransparency = 1
	windowFrame.Visible = true
	task.spawn(function()
		game:GetService("RunService").RenderStepped:Wait()
		if not s._visible or self.unloaded then return end
		tween.fire(windowFrame, constants.tweenNormal, {
			BackgroundTransparency = 0,
		})
	end)
end

function Window:Hide()
	if self.unloaded then return end
	local s = (self :: any)
	local windowFrame: Frame = s._windowFrame
	s._visible = false
	windowFrame.Visible = false
end

function Window:ToggleHide()
	if (self :: any)._visible then
		self:Hide()
	else
		self:Show()
	end
end

function Window:ToggleMinimise()
	if self.unloaded then return end
	local s = (self :: any)
	if not s._visible then return end

	
	if s._activeTween then
		s._activeTween:Cancel()
		s._activeTween = nil
	end

	local windowFrame: Frame    = s._windowFrame
	local body: Frame           = s._body
	local divider: Frame?       = s._divider
	local cornerCover: Frame?   = s._cornerCover
	local titlebarH: number     = s._titlebarH
	local fullH: number         = s._windowSize.Y.Offset
	local width: number         = s._windowSize.X.Offset
	local keepOnScreen: boolean = s._keepOnScreen
	local screen                = self._gui.AbsoluteSize
	local margin                = 8

	
	local absPos  = windowFrame.AbsolutePosition
	local absSize = windowFrame.AbsoluteSize
	local centerX = absPos.X + absSize.X / 2
	local centerY = absPos.Y + absSize.Y / 2
	local topY    = absPos.Y

	if keepOnScreen then
		local halfW = width / 2
		centerX = math.clamp(centerX, halfW + margin, math.max(halfW + margin, screen.X - halfW - margin))
	end

	
	windowFrame.Position = UDim2.fromOffset(centerX, centerY)

	local TWEEN_INFO = TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

	if s._minimized then
		
		s._minimized     = false
		s._pendingResize = false

		local targetCY = topY + fullH / 2
		if keepOnScreen then
			local halfH = fullH / 2
			targetCY = math.clamp(targetCY, halfH + margin, math.max(halfH + margin, screen.Y - halfH - margin))
		end

		body.Visible = true
		if divider then divider.Visible = true end
		if s._titleSep then (s._titleSep :: Frame).Visible = true end

		local tw = tween.play(windowFrame, TWEEN_INFO, {
			Size     = UDim2.fromOffset(width, fullH),
			Position = UDim2.fromOffset(centerX, targetCY),
		})
		s._activeTween = tw
		tw.Completed:Once(function()
			tw:Destroy()
			if s._activeTween == tw then
				s._activeTween = nil
				if not s._minimized then
					if cornerCover then cornerCover.Visible = true end
				end
			end
		end)
		;(s._minBtn :: TextButton).Text = ""
		
		if s._minIcon then
			local _ic = s._minIcon :: ImageLabel
			local _fo = tween.play(_ic, TweenInfo.new(0.1, Enum.EasingStyle.Quad), { ImageTransparency = 1 })
			_fo.Completed:Once(function()
				_fo:Destroy()
				_ic.Image = ICON_MINIMIZE
				tween.fire(_ic, TweenInfo.new(0.1, Enum.EasingStyle.Quad), { ImageTransparency = 0 })
			end)
		end
	else
		
		s._minimized = true

		local targetCY = topY + titlebarH / 2
		if keepOnScreen then
			local halfTH = titlebarH / 2
			targetCY = math.clamp(targetCY, halfTH + margin, math.max(halfTH + margin, screen.Y - halfTH - margin))
		end

		
		if cornerCover then cornerCover.Visible = false end
		if divider then divider.Visible = false end
		if s._titleSep then (s._titleSep :: Frame).Visible = false end

		local animId = {}
		s._minimizeAnimId = animId

		local tw = tween.play(windowFrame, TWEEN_INFO, {
			Size     = UDim2.fromOffset(width, titlebarH),
			Position = UDim2.fromOffset(centerX, targetCY),
		})
		s._activeTween = tw
		tw.Completed:Once(function()
			tw:Destroy()
			if s._activeTween == tw then
				s._activeTween = nil
				body.Visible = false
			end
		end)

		
		task.delay(0.22, function()
			if s._minimizeAnimId ~= animId then return end
			if not s._minimized then return end
			body.Visible = false
		end)

		;(s._minBtn :: TextButton).Text = ""
		
		if s._minIcon then
			local _ic = s._minIcon :: ImageLabel
			local _fo = tween.play(_ic, TweenInfo.new(0.1, Enum.EasingStyle.Quad), { ImageTransparency = 1 })
			_fo.Completed:Once(function()
				_fo:Destroy()
				_ic.Image = ICON_RESTORE
				tween.fire(_ic, TweenInfo.new(0.1, Enum.EasingStyle.Quad), { ImageTransparency = 0 })
			end)
		end
	end
end



function Window:ChangeTheme(newTheme: string | { [string]: any })
	local s = (self :: any)
	local resolved = themeUtil.resolve(newTheme)
	s._theme = resolved
	variables.activeTheme = resolved
	themeUtil.broadcast(resolved)
end



function Window:Unload()
	if self.unloaded then return end
	self.unloaded = true

	local s = (self :: any)
	if s._themeUnsub then s._themeUnsub() end

	if s._activeTween then
		pcall(function() s._activeTween:Cancel() end)
		s._activeTween = nil
	end
	if s._activeAnimConn then
		pcall(function() s._activeAnimConn:Disconnect() end)
		s._activeAnimConn = nil
	end

	for _, conn in s._connections do
		pcall(function() conn:Disconnect() end)
	end
	table.clear(s._connections)

	if s._playerCard then
		pcall(function() s._playerCard:Destroy() end)
	end

	self._gui:Destroy()

	local tabs: { Tab.Tab } = s._tabs
	for _, tab in tabs do
		tab:Destroy()
	end
end

return Window

end)() end,[19]=function()local wax,script,require=ImportGlobals(19)local ImportGlobals return (function(...)





return {
	
	WindowColor = ColorSequence.new({
		ColorSequenceKeypoint.new(0,      Color3.fromHex("#141414")),
		ColorSequenceKeypoint.new(0.9999, Color3.fromHex("#191919")),
		ColorSequenceKeypoint.new(1,      Color3.fromHex("#1c1c1c")),
	}),
	ShadowColor     = Color3.fromRGB(0, 0, 0),
	SurfaceStroke   = Color3.fromHex("#2b2b2b"),
	TitleBarColor   = Color3.fromHex("#111114"),
	CornerRoundness = UDim.new(0, 8),

	
	TabColor      = Color3.fromHex("#9d9d9d"),
	TabBackground = ColorSequence.new(
		Color3.fromHex("#2a2a2a"),
		Color3.fromHex("#191919")
	),
	TabStroke     = ColorSequence.new(
		Color3.fromHex("#2b2b2b"),
		Color3.fromHex("#222222")
	),

	
	ElementGradient = ColorSequence.new({
		ColorSequenceKeypoint.new(0,      Color3.fromHex("#2a2a2a")),
		ColorSequenceKeypoint.new(0.9999, Color3.fromHex("#1e1e1e")),
		ColorSequenceKeypoint.new(1,      Color3.fromHex("#191919")),
	}),
	ElementStroke                  = Color3.fromHex("#2b2b2b"),
	ElementStrokeGradient          = ColorSequence.new(
		Color3.fromHex("#333333"),
		Color3.fromHex("#2b2b2b")
	),
	ElementStrokeHover             = Color3.fromHex("#4cc2ff"),
	ElementTransparency            = 0,
	ElementStrokeTransparency      = 0,
	ElementStrokeHoverTransparency = 0,
	ElementCornerRadius            = UDim.new(0, 6),
	ElementTextHoverColor          = Color3.fromHex("#ffffff"),

	
	TitleFont        = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold),
	Font             = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium),
	ContentColor     = Color3.fromHex("#ffffff"),
	TitlingColor     = Color3.fromHex("#ffffff"),
	PlaceholderColor = Color3.fromHex("#9d9d9d"),

	
	AccentColor  = Color3.fromHex("#4cc2ff"),
	AccentStroke = Color3.fromHex("#60cdff"),
	AccentGlow   = 0.35,

	
	ToggleTrack               = Color3.fromRGB(0, 0, 0),
	ToggleTrackTransparency   = 0.6,
	ToggleKnobOff             = Color3.fromHex("#9d9d9d"),
	ToggleKnobOffTransparency = 0.3,
	DarkToggleOverlay         = false,

	
	SliderBackground      = Color3.fromHex("#222222"),
	SliderBackgroundHover = Color3.fromHex("#2a2a2a"),
	SliderProgress        = ColorSequence.new(
		Color3.fromHex("#4cc2ff"),
		Color3.fromHex("#0093fb")
	),
	SliderHandle = Color3.fromRGB(255, 255, 255),
	SliderStroke = Color3.fromRGB(255, 255, 255),

	
	DropdownHighlight = Color3.fromRGB(255, 255, 255),

	
	FieldBackground   = Color3.fromRGB(255, 255, 255),
	FieldTransparency = 0.90,
	FieldGlow         = Color3.fromHex("#4cc2ff"),

	
	PillCornerRadius = UDim.new(1, 0),

	
	NeutralButton       = Color3.fromHex("#252525"),
	NeutralButtonHover  = Color3.fromHex("#2e2e2e"),
	NeutralButtonStroke = Color3.fromHex("#2b2b2b"),

	
	ErrorColor       = Color3.fromHex("#ff4f58"),
	ErrorStrokeColor = Color3.fromHex("#ff6b74"),
	ActionColor      = Color3.fromRGB(255, 255, 255),
	LiveAnimation    = false,
}

end)() end,[20]=function()local wax,script,require=ImportGlobals(20)local ImportGlobals return (function(...)






return {
	
	WindowColor = ColorSequence.new({
		ColorSequenceKeypoint.new(0,      Color3.fromHex("#282a36")),
		ColorSequenceKeypoint.new(0.9999, Color3.fromHex("#21222c")),
		ColorSequenceKeypoint.new(1,      Color3.fromHex("#191a21")),
	}),
	ShadowColor   = Color3.fromHex("#0b0c10"),
	SurfaceStroke = Color3.fromHex("#44475a"),
	TitleBarColor = Color3.fromHex("#1e1f29"),

	
	TabColor      = Color3.fromHex("#bd93f9"),
	TabBackground = ColorSequence.new(
		Color3.fromHex("#343746"),
		Color3.fromHex("#282a36")
	),
	TabStroke     = ColorSequence.new(
		Color3.fromHex("#44475a"),
		Color3.fromHex("#2f3140")
	),

	
	ElementGradient = ColorSequence.new({
		ColorSequenceKeypoint.new(0,      Color3.fromHex("#343746")),
		ColorSequenceKeypoint.new(0.9999, Color3.fromHex("#2b2d3a")),
		ColorSequenceKeypoint.new(1,      Color3.fromHex("#242630")),
	}),
	ElementStroke               = Color3.fromHex("#44475a"),
	ElementStrokeGradient       = ColorSequence.new(
		Color3.fromHex("#50536a"),
		Color3.fromHex("#44475a")
	),
	ElementStrokeHover          = Color3.fromHex("#6272a4"),
	ElementTextHoverColor       = Color3.fromHex("#f8f8f2"),

	
	ContentColor     = Color3.fromHex("#f8f8f2"),
	TitlingColor     = Color3.fromHex("#ffffff"),
	PlaceholderColor = Color3.fromHex("#8b8fa3"),

	
	AccentColor  = Color3.fromHex("#bd93f9"),
	AccentStroke = Color3.fromHex("#d7b8ff"),
	AccentGlow   = 0.4,

	
	ToggleTrack               = Color3.fromHex("#282a36"),
	ToggleTrackTransparency   = 0.55,
	ToggleKnobOff             = Color3.fromHex("#8b8fa3"),
	ToggleKnobOffTransparency = 0.35,
	DarkToggleOverlay         = false,

	
	SliderBackground      = Color3.fromHex("#2b2d3a"),
	SliderBackgroundHover = Color3.fromHex("#343746"),
	SliderProgress        = ColorSequence.new(
		Color3.fromHex("#bd93f9"),
		Color3.fromHex("#8b5cf6")
	),
	SliderHandle = Color3.fromHex("#f8f8f2"),
	SliderStroke = Color3.fromHex("#f8f8f2"),

	
	DropdownHighlight = Color3.fromHex("#f8f8f2"),

	
	FieldBackground   = Color3.fromHex("#f8f8f2"),
	FieldTransparency = 0.90,
	FieldGlow         = Color3.fromHex("#bd93f9"),

	
	PillCornerRadius = UDim.new(1, 0),

	
	NeutralButton       = Color3.fromHex("#343746"),
	NeutralButtonHover  = Color3.fromHex("#44475a"),
	NeutralButtonStroke = Color3.fromHex("#44475a"),

	
	ErrorColor       = Color3.fromHex("#ff5555"),
	ErrorStrokeColor = Color3.fromHex("#ff6e67"),
	ActionColor      = Color3.fromHex("#f8f8f2"),
	LiveAnimation    = false,
}
end)() end,[21]=function()local wax,script,require=ImportGlobals(21)local ImportGlobals return (function(...)






return {
	
	WindowColor = ColorSequence.new({
		ColorSequenceKeypoint.new(0,      Color3.fromRGB(245, 243, 255)),
		ColorSequenceKeypoint.new(0.9999, Color3.fromRGB(235, 232, 250)),
		ColorSequenceKeypoint.new(1,      Color3.fromRGB(225, 220, 245)),
	}),
	ShadowColor   = Color3.fromRGB(180, 170, 210),
	SurfaceStroke = Color3.fromRGB(190, 180, 220),
	TitleBarColor = Color3.fromRGB(210, 205, 240),

	
	TabColor      = Color3.fromRGB(30, 20, 60),
	TabBackground = ColorSequence.new(
		Color3.fromRGB(210, 205, 240),
		Color3.fromRGB(225, 220, 248)
	),
	TabStroke     = ColorSequence.new(
		Color3.fromRGB(180, 170, 220),
		Color3.fromRGB(195, 185, 230)
	),

	
	ElementGradient = ColorSequence.new({
		ColorSequenceKeypoint.new(0,      Color3.fromRGB(232, 228, 252)),
		ColorSequenceKeypoint.new(0.9999, Color3.fromRGB(238, 235, 255)),
		ColorSequenceKeypoint.new(1,      Color3.fromRGB(238, 235, 255)),
	}),
	ElementStroke               = Color3.fromRGB(200, 190, 235),
	ElementStrokeGradient       = ColorSequence.new(
		Color3.fromRGB(190, 180, 225),
		Color3.fromRGB(200, 190, 235)
	),
	ElementStrokeHover          = Color3.fromRGB(124, 58, 237),
	ElementTextHoverColor       = Color3.fromRGB(30, 20, 60),

	
	ContentColor     = Color3.fromRGB(40,  30,  70),
	TitlingColor     = Color3.fromRGB(20,  10,  50),
	PlaceholderColor = Color3.fromRGB(150, 140, 180),

	
	ToggleTrack               = Color3.fromRGB(180, 170, 215),
	ToggleTrackTransparency   = 0.5,
	ToggleKnobOff             = Color3.fromRGB(120, 110, 165),
	ToggleKnobOffTransparency = 0,
	DarkToggleOverlay         = false,

	
	SliderBackground      = Color3.fromRGB(215, 210, 245),
	SliderBackgroundHover = Color3.fromRGB(200, 195, 235),
	SliderHandle          = Color3.fromRGB(124, 58, 237),
	SliderStroke          = Color3.fromRGB(124, 58, 237),

	
	FieldBackground   = Color3.fromRGB(255, 255, 255),
	FieldTransparency = 0.6,
	FieldGlow         = Color3.fromRGB(124, 58, 237),

	
	NeutralButton       = Color3.fromRGB(220, 215, 245),
	NeutralButtonHover  = Color3.fromRGB(205, 198, 235),
	NeutralButtonStroke = Color3.fromRGB(160, 150, 200),

	
	ActionColor = Color3.fromRGB(30, 20, 60),
}

end)() end,[22]=function()local wax,script,require=ImportGlobals(22)local ImportGlobals return (function(...)







export type Theme = string | { [string]: any }

export type WindowProps = {
	name:     string?,
	subtitle: string?,
	theme:    Theme?,
	keybind:  (EnumItem | string)?,
}

export type TabProps = {
	name:    string?,
	icon:    string?,
	badge:   string?,
	columns: number?,
}

export type SectionProps = {
	name: string?,
}

export type LabelProps = {
	text:      string?,
	richText:  boolean?,
	textSize:  number?,
	textColor: Color3?,
}

export type ButtonProps = {
	name:        string?,
	description: string?,
	callback:    (() -> ())?,
}

export type ToggleProps = {
	name:        string?,
	description: string?,
	flag:        string?,
	value:       boolean?,
	callback:    ((value: boolean) -> ())?,
}

export type SliderProps = {
	name:               string?,
	Label:              string?,
	Text:               string?,
	description:        string?,
	Tooltip:            string?,
	flag:               string?,
	Flag:               string?,
	range:              { number }?,
	min:                number?,
	Min:                number?,
	max:                number?,
	Max:                number?,
	increment:          number?,
	step:               number?,
	Step:               number?,
	value:              number?,
	default:            number?,
	Default:            number?,
	suffix:             string?,
	Suffix:             string?,
	compact:            boolean?,
	Compact:            boolean?,
	hideMax:            boolean?,
	HideMax:            boolean?,
	formatDisplayValue: ((slider: any, value: number) -> string?)?,
	FormatDisplayValue: ((slider: any, value: number) -> string?)?,
	enabled:            boolean?,
	Enabled:            boolean?,
	layoutOrder:        number?,
	LayoutOrder:        number?,
	callback:           ((value: number) -> ())?,
	Callback:           ((value: number) -> ())?,
}

export type DropdownProps = {
	name:                    string?,
	Label:                   string?,
	Text:                    string?,
	description:             string?,
	Tooltip:                 string?,
	flag:                    string?,
	Flag:                    string?,
	options:                 { any }?,
	Options:                 { any }?,
	value:                   any?,
	default:                 any?,
	Default:                 any?,
	multiSelect:             boolean?,
	MultiSelect:             boolean?,
	placeholder:             string?,
	Placeholder:             string?,
	searchable:              boolean?,
	Searchable:              boolean?,
	disabledValues:          { any }?,
	DisabledValues:          { any }?,
	formatDisplayValue:      ((value: any) -> string)?,
	FormatDisplayValue:      ((value: any) -> string)?,
	maxVisibleDropdownItems: number?,
	MaxVisibleDropdownItems: number?,
	specialType:             string?,
	SpecialType:             string?,
	enabled:                 boolean?,
	Enabled:                 boolean?,
	layoutOrder:             number?,
	LayoutOrder:             number?,
	callback:                ((value: any) -> ())?,
	Callback:                ((value: any) -> ())?,
}

export type InputProps = {
	name:         string?,
	description:  string?,
	flag:         string?,
	value:        string?,
	placeholder:  string?,
	numeric:      boolean?,
	clearOnFocus: boolean?,
	callback:     ((value: string) -> ())?,
}

export type KeybindProps = {
	name:       string?,
	description: string?,
	flag:       string?,
	value:      (EnumItem | string)?,
	callback:   ((value: EnumItem) -> ())?,
	onChanged:  ((key: EnumItem) -> ())?,
}

export type ColorPickerProps = {
	name:     string?,
	flag:     string?,
	color:    Color3?,
	alpha:    number?,
	callback: ((value: Color3, alpha: number) -> ())?,
}

export type NotifyProps = {
	title:    string?,
	content:  string?,
	duration: number?,
}



export type Section = {
	Destroy: (self: Section) -> (),
}

export type Label = {
	Set:     (self: Label, text: string) -> (),
	Destroy: (self: Label) -> (),
}

export type Button = {
	Destroy: (self: Button) -> (),
}

export type Toggle = {
	value:   boolean,
	Set:     (self: Toggle, value: boolean, skipCallback: boolean?) -> (),
	Destroy: (self: Toggle) -> (),
}

export type Slider = {
	value:      number,
	Value:      number,
	Changed:    any,
	Set:        (self: Slider, value: number, skipCallback: boolean?) -> (),
	SetValue:   (self: Slider, value: number, skipCallback: boolean?) -> (),
	SetEnabled: (self: Slider, enabled: boolean) -> (),
	GetFrame:   (self: Slider) -> Frame,
	Destroy:    (self: Slider) -> (),
}

export type Dropdown = {
	value:      any,
	Value:      any,
	Changed:    any,
	Set:        (self: Dropdown, value: any, skipCallback: boolean?) -> (),
	SetValue:   (self: Dropdown, value: any, skipCallback: boolean?) -> (),
	SetOptions: (self: Dropdown, options: { any }) -> (),
	SetEnabled: (self: Dropdown, enabled: boolean) -> (),
	GetFrame:   (self: Dropdown) -> Frame,
	Destroy:    (self: Dropdown) -> (),
}

export type Input = {
	value:   string,
	Set:     (self: Input, value: string, skipCallback: boolean?) -> (),
	Destroy: (self: Input) -> (),
}

export type Keybind = {
	value:   EnumItem,
	Set:     (self: Keybind, value: EnumItem | string, skipChanged: boolean?) -> (),
	Destroy: (self: Keybind) -> (),
}

export type ColorPicker = {
	value:    Color3,
	alpha:    number,
	Set:      (self: ColorPicker, value: Color3, skipCallback: boolean?) -> (),
	SetAlpha: (self: ColorPicker, alpha: number, skipCallback: boolean?) -> (),
	Destroy:  (self: ColorPicker) -> (),
}

export type TabColumn = {
	CreateSection:     (self: TabColumn, props: SectionProps) -> Section,
	CreateLabel:       (self: TabColumn, props: LabelProps) -> Label,
	CreateButton:      (self: TabColumn, props: ButtonProps) -> Button,
	CreateToggle:      (self: TabColumn, props: ToggleProps) -> Toggle,
	CreateSlider:      (self: TabColumn, props: SliderProps) -> Slider,
	AddSlider:         (self: TabColumn, props: SliderProps) -> Slider,
	CreateInput:       (self: TabColumn, props: InputProps) -> Input,
	CreateKeybind:     (self: TabColumn, props: KeybindProps) -> Keybind,
	CreateDropdown:    (self: TabColumn, props: DropdownProps) -> Dropdown,
	AddDropdown:       (self: TabColumn, props: DropdownProps) -> Dropdown,
	CreateColorPicker: (self: TabColumn, props: ColorPickerProps) -> ColorPicker,
}

export type Tab = {
	Left:              TabColumn,
	Right:             TabColumn,

	CreateSection:     (self: Tab, props: SectionProps) -> Section,
	CreateLabel:       (self: Tab, props: LabelProps) -> Label,
	CreateButton:      (self: Tab, props: ButtonProps) -> Button,
	CreateToggle:      (self: Tab, props: ToggleProps) -> Toggle,
	CreateSlider:      (self: Tab, props: SliderProps) -> Slider,
	AddSlider:         (self: Tab, props: SliderProps) -> Slider,
	CreateInput:       (self: Tab, props: InputProps) -> Input,
	CreateKeybind:     (self: Tab, props: KeybindProps) -> Keybind,
	CreateDropdown:    (self: Tab, props: DropdownProps) -> Dropdown,
	AddDropdown:       (self: Tab, props: DropdownProps) -> Dropdown,
	CreateColorPicker: (self: Tab, props: ColorPickerProps) -> ColorPicker,

	CreateLeftSection:     (self: Tab, props: SectionProps) -> Section,
	CreateLeftLabel:       (self: Tab, props: LabelProps) -> Label,
	CreateLeftButton:      (self: Tab, props: ButtonProps) -> Button,
	CreateLeftToggle:      (self: Tab, props: ToggleProps) -> Toggle,
	CreateLeftSlider:      (self: Tab, props: SliderProps) -> Slider,
	CreateLeftInput:       (self: Tab, props: InputProps) -> Input,
	CreateLeftKeybind:     (self: Tab, props: KeybindProps) -> Keybind,
	CreateLeftDropdown:    (self: Tab, props: DropdownProps) -> Dropdown,
	CreateLeftColorPicker: (self: Tab, props: ColorPickerProps) -> ColorPicker,

	CreateRightSection:     (self: Tab, props: SectionProps) -> Section,
	CreateRightLabel:       (self: Tab, props: LabelProps) -> Label,
	CreateRightButton:      (self: Tab, props: ButtonProps) -> Button,
	CreateRightToggle:      (self: Tab, props: ToggleProps) -> Toggle,
	CreateRightSlider:      (self: Tab, props: SliderProps) -> Slider,
	CreateRightInput:       (self: Tab, props: InputProps) -> Input,
	CreateRightKeybind:     (self: Tab, props: KeybindProps) -> Keybind,
	CreateRightDropdown:    (self: Tab, props: DropdownProps) -> Dropdown,
	CreateRightColorPicker: (self: Tab, props: ColorPickerProps) -> ColorPicker,

	Show:    (self: Tab) -> (),
	Hide:    (self: Tab) -> (),
	Destroy: (self: Tab) -> (),
}

export type Window = {
	unloaded: boolean,

	CreateTab:   (self: Window, props: TabProps) -> Tab,
	Notify:      (self: Window, props: NotifyProps) -> (),
	Show:        (self: Window) -> (),
	Hide:        (self: Window) -> (),
	ToggleHide:  (self: Window) -> (),
	ChangeTheme: (self: Window, theme: Theme) -> (),
	Unload:      (self: Window) -> (),
}

export type Delirium = {
	Flags:        { [string]: any },
	Icons:        any,
	NebulaIcons:  any,
	CreateWindow: (self: Delirium, props: WindowProps) -> Window,
}

return {}

end)() end,[24]=function()local wax,script,require=ImportGlobals(24)local ImportGlobals return (function(...)







local network  = require(script.Parent.network)
local services = require(script.Parent.services)

local IS_STUDIO = services.getService("RunService"):IsStudio()



export type AssetId = number | string
export type CacheKey = string | number

export type AssetFetcher = {
	resolve:            (self: AssetFetcher, value: unknown) -> AssetId?,
	getContentFromUrl:  (self: AssetFetcher, url: string, cacheKey: CacheKey?, forced: boolean?) -> string?,
	getContentFromId:   (self: AssetFetcher, id: AssetId, forced: boolean?) -> string?,
}





local DOWNLOAD_URL = "https://assetdelivery.roproxy.com/v1/asset?id=%d"


local CACHE_LIMIT = 8



local AssetFetcher = {}
AssetFetcher.__index = AssetFetcher



local function isGoodResponse(response: unknown): boolean
	if type(response) ~= "table" then return false end
	local r = response :: { Body: unknown, StatusCode: unknown, Success: unknown }
	if type(r.Body) ~= "string" or #(r.Body :: string) == 0 then return false end
	if type(r.StatusCode) == "number" then
		local code = r.StatusCode :: number
		return code >= 200 and code < 300
	end
	if type(r.Success) == "boolean" then
		return r.Success :: boolean
	end
	
	return false
end

function AssetFetcher.new(): AssetFetcher
	local self = setmetatable({
		_cache      = {} :: { [CacheKey]: string },
		_cacheOrder = {} :: { CacheKey },
	}, AssetFetcher) :: any
	return self
end






function AssetFetcher.resolve(_self: AssetFetcher, value: unknown): AssetId?
	if type(value) == "number" then return value end
	if type(value) ~= "string" then return nil end
	local s = value :: string
	if string.sub(s, 1, 11) == "rbxasset://" or string.sub(s, 1, 11) == "rbxthumb://" then
		return s
	end
	local id = tonumber(string.match(s, "^rbxassetid://(%d+)$")) or tonumber(s)
	return id or nil
end



function AssetFetcher.getContentFromUrl(
	self: AssetFetcher,
	url: string,
	cacheKey: CacheKey?,
	forced: boolean?
): string?
	local cache = self._cache :: { [CacheKey]: string }
	local order = self._cacheOrder :: { CacheKey }

	if cacheKey ~= nil and not forced then
		local hit = cache[cacheKey]
		if hit then
			
			
			for i = 1, #order do
				if order[i] == cacheKey then
					table.remove(order, i)
					table.insert(order, cacheKey)
					break
				end
			end
			return hit
		end
	end

	local requestFn = network.getRequestFn()
	if not requestFn then
		
		if not IS_STUDIO then
			warn("[Delirium:assetFetcher] No executor request function found.")
		end
		return nil
	end

	local ok, response = pcall(requestFn, { Url = url, Method = "GET" })
	if not ok or not isGoodResponse(response) then
		if not forced then
			warn("[Delirium:assetFetcher] Request failed for: " .. url)
		end
		return nil
	end

	local body = (response :: { Body: string }).Body
	if cacheKey ~= nil then
		if cache[cacheKey] == nil then
			table.insert(order, cacheKey)
			if #order > CACHE_LIMIT then
				local oldest = table.remove(order, 1)
				if oldest ~= nil then
					cache[oldest] = nil
				end
			end
		end
		cache[cacheKey] = body
	end
	return body
end


function AssetFetcher.getContentFromId(
	self: AssetFetcher,
	id: AssetId,
	forced: boolean?
): string?
	local resolved = self:resolve(id)
	if not resolved or type(resolved) ~= "number" then
		warn("[Delirium:assetFetcher] Invalid asset id: " .. tostring(id))
		return nil
	end
	local url = string.format(DOWNLOAD_URL, resolved :: number)
	return self:getContentFromUrl(url, resolved, forced)
end

return AssetFetcher

end)() end,[25]=function()local wax,script,require=ImportGlobals(25)local ImportGlobals return (function(...)





local constants = {}




constants.tweenFast   = TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
constants.tweenNormal = TweenInfo.new(0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
constants.tweenSlow   = TweenInfo.new(0.45, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)


constants.pillResizeInfo = TweenInfo.new(0.35, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
constants.tweenFocus     = TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)


constants.notifySlideIn  = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
constants.notifySlideOut = TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.In)



constants.zIndex = {
	base             = 1,
	element          = 10,
	dropdown         = 50,     
	notification     = 200,    
	windowChrome     = 500,    
	drag             = 1000,   
	popup            = 2000,   
}



constants.displayOrder = {
	window      = 99990,
	notification = 99995,
	popup       = 100000,
}




constants.windowSize       = Vector2.new(720, 580)
constants.windowMinSize    = Vector2.new(560, 440)
constants.sidebarWidth     = 164   
constants.elementHeight    = 38    
constants.elementPadding   = 6     
constants.sectionPadding   = 14    
constants.contentPadding   = 10    






constants.DEFAULT_FONT        = Font.new("rbxasset://fonts/families/GothamSSm.json")
constants.DEFAULT_FONT_MEDIUM = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium)




constants.notifyDuration = 4


constants.clickSoundId = ""

return constants

end)() end,[26]=function()local wax,script,require=ImportGlobals(26)local ImportGlobals return (function(...)






local constants = require(script.Parent.constants)

local element = {}









function element.makeFrame(
	name:   string,
	theme:  { [string]: any },
	parent: Instance,
	height: number?
): (Frame, UIStroke)
	local h = height or constants.elementHeight

	local frame = Instance.new("Frame")
	frame.Name                   = name
	frame.Size                   = UDim2.new(1, 0, 0, h)
	frame.BackgroundColor3       = Color3.fromRGB(255, 255, 255)
	frame.BackgroundTransparency = theme.ElementTransparency or 0
	frame.BorderSizePixel        = 0
	frame.LayoutOrder            = 0
	frame.Parent                 = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = theme.ElementCornerRadius or UDim.new(0, 10)
	corner.Parent       = frame

	local gradient = Instance.new("UIGradient")
	gradient.Color    = theme.ElementGradient
		or ColorSequence.new(Color3.fromRGB(28, 24, 44))
	gradient.Rotation = 90
	gradient.Parent   = frame

	local stroke = Instance.new("UIStroke")
	stroke.Color        = theme.ElementStroke or Color3.fromRGB(50, 42, 80)
	stroke.Thickness    = 1
	stroke.Transparency = theme.ElementStrokeTransparency or 0
	stroke.Parent       = frame

	return frame, stroke, gradient
end





function element.makeOverlay(parent: Instance, zIndex: number, transparency: number?): Frame
	local overlay = Instance.new("Frame")
	overlay.Name                   = "Overlay"
	overlay.Size                   = UDim2.fromScale(1, 1)
	overlay.Position               = UDim2.fromScale(0, 0)
	overlay.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = transparency or 0.55
	overlay.BorderSizePixel        = 0
	overlay.ZIndex                 = zIndex
	overlay.Visible                = false
	overlay.Parent                 = parent
	return overlay
end

return element

end)() end,[27]=function()local wax,script,require=ImportGlobals(27)local ImportGlobals return (function(...)








local services = require(script.Parent.services)

local filesystem = {}

local runService = services.getService("RunService")
local isStudio   = runService:IsStudio()
local hasNativeFS = not isStudio and typeof(writefile) == "function"



if hasNativeFS then

	function filesystem.writefile(path: string, content: string)
		writefile(path, content)
	end

	function filesystem.readfile(path: string): string
		return readfile(path)
	end

	function filesystem.appendfile(path: string, content: string)
		appendfile(path, content)
	end

	function filesystem.isfile(path: string): boolean
		return isfile(path)
	end

	function filesystem.delfile(path: string)
		delfile(path)
	end

	function filesystem.listfiles(folder: string): { string }
		return listfiles(folder)
	end

	function filesystem.makefolder(path: string)
		makefolder(path)
	end

	function filesystem.isfolder(path: string): boolean
		return isfolder(path)
	end

	function filesystem.delfolder(path: string)
		delfolder(path)
	end






elseif isStudio then

	local replicatedStorage = services.getService("ReplicatedStorage")
	local root = replicatedStorage:FindFirstChild("__DeliriumFS__")
	if not root then
		root = Instance.new("Folder")
		root.Name = "__DeliriumFS__"
		root.Parent = replicatedStorage
	end

	local function splitPath(path: string): { string }
		local parts: { string } = {}
		for part in string.gmatch(path, "[^/]+") do
			table.insert(parts, part)
		end
		return parts
	end

	local function resolveParent(parts: { string }, create: boolean): Instance?
		local cur: Instance = root :: Instance
		for i = 1, #parts - 1 do
			local child = cur:FindFirstChild(parts[i])
			if not child then
				if not create then return nil end
				local f = Instance.new("Folder")
				f.Name = parts[i]
				f.Parent = cur
				child = f
			end
			cur = child :: Instance
		end
		return cur
	end

	local function asFile(inst: Instance?): StringValue?
		return if inst and inst:IsA("StringValue") then inst :: StringValue else nil
	end

	function filesystem.writefile(path: string, content: string)
		local parts = splitPath(path)
		assert(#parts > 0, "filesystem.writefile: invalid path")
		local parent = resolveParent(parts, true)
		assert(parent, "filesystem.writefile: could not resolve parent")
		local name = parts[#parts]
		local existing = parent:FindFirstChild(name)
		local file = asFile(existing)
		if file then
			file.Value = content
		else
			if existing then existing:Destroy() end
			local sv = Instance.new("StringValue")
			sv.Name  = name
			sv.Value = content
			sv.Parent = parent
		end
	end

	function filesystem.readfile(path: string): string
		local parts = splitPath(path)
		local parent = resolveParent(parts, false)
		assert(parent, "filesystem.readfile: file not found — " .. path)
		local file = asFile(parent:FindFirstChild(parts[#parts]))
		assert(file, "filesystem.readfile: file not found — " .. path)
		return file.Value
	end

	function filesystem.appendfile(path: string, content: string)
		local parts = splitPath(path)
		local parent = resolveParent(parts, false)
		assert(parent, "filesystem.appendfile: file not found — " .. path)
		local file = asFile(parent:FindFirstChild(parts[#parts]))
		assert(file, "filesystem.appendfile: file not found — " .. path)
		file.Value = file.Value .. content
	end

	function filesystem.isfile(path: string): boolean
		local parts = splitPath(path)
		if #parts == 0 then return false end
		local parent = resolveParent(parts, false)
		if not parent then return false end
		return asFile(parent:FindFirstChild(parts[#parts])) ~= nil
	end

	function filesystem.delfile(path: string)
		local parts = splitPath(path)
		local parent = resolveParent(parts, false)
		assert(parent, "filesystem.delfile: file not found — " .. path)
		local file = asFile(parent:FindFirstChild(parts[#parts]))
		assert(file, "filesystem.delfile: file not found — " .. path)
		file:Destroy()
	end

	function filesystem.listfiles(folder: string): { string }
		local parts = splitPath(folder)
		local cur: Instance = root :: Instance
		for _, part in parts do
			local child = cur:FindFirstChild(part)
			assert(child and child:IsA("Folder"), "filesystem.listfiles: folder not found — " .. folder)
			cur = child
		end
		local results: { string } = {}
		for _, child in cur:GetChildren() do
			table.insert(results, folder .. "/" .. child.Name)
		end
		return results
	end

	function filesystem.makefolder(path: string)
		local parts = splitPath(path)
		local cur: Instance = root :: Instance
		for _, part in parts do
			local child = cur:FindFirstChild(part)
			if not child then
				local f = Instance.new("Folder")
				f.Name   = part
				f.Parent = cur
				child    = f
			end
			cur = child :: Instance
		end
	end

	function filesystem.isfolder(path: string): boolean
		local parts = splitPath(path)
		local cur: Instance = root :: Instance
		for _, part in parts do
			local child = cur:FindFirstChild(part)
			if not child or not child:IsA("Folder") then return false end
			cur = child
		end
		return true
	end

	function filesystem.delfolder(path: string)
		local parts = splitPath(path)
		local parent = resolveParent(parts, false)
		assert(parent, "filesystem.delfolder: folder not found — " .. path)
		local folder = parent:FindFirstChild(parts[#parts])
		assert(folder and folder:IsA("Folder"), "filesystem.delfolder: folder not found — " .. path)
		folder:Destroy()
	end

end




function filesystem.ensureFolder(path: string)
	if not filesystem.isfolder(path) then
		filesystem.makefolder(path)
	end
end



function filesystem.ensureDir(dir: string)
	local built = ""
	for part in string.gmatch(dir, "[^/]+") do
		built = if built == "" then part else built .. "/" .. part
		if not filesystem.isfolder(built) then
			filesystem.makefolder(built)
		end
	end
end

return filesystem

end)() end,[28]=function()local wax,script,require=ImportGlobals(28)local ImportGlobals return (function(...)














export type FlagValue = boolean | number | string | { string } | Color3 | EnumItem

export type FlagsRegistry = {
	[string]: FlagValue,
	Set:    (self: FlagsRegistry, key: string, value: FlagValue) -> (),
	Get:    (self: FlagsRegistry, key: string) -> FlagValue?,
	GetAll: (self: FlagsRegistry) -> { [string]: FlagValue },
	Clear:  (self: FlagsRegistry) -> (),
}

local store: { [string]: FlagValue } = {}

local flags = {} :: FlagsRegistry





function flags:Set(key: string, value: FlagValue)
	store[key] = value
end

function flags:Get(key: string): FlagValue?
	return store[key]
end

function flags:GetAll(): { [string]: FlagValue }
	return table.clone(store)
end

function flags:Clear()
	table.clear(store)
end




local mt = {
	__index = function(_, key: string): FlagValue?
		local method = rawget(flags, key)
		if method ~= nil then
			return method
		end
		return store[key]
	end,
	__newindex = function(_, key: string, value: FlagValue)
		store[key] = value
	end,
}
setmetatable(flags :: any, mt)

return flags

end)() end,[29]=function()local wax,script,require=ImportGlobals(29)local ImportGlobals return (function(...)















local filesystem  = require(script.Parent.filesystem)
local AssetFetcher = require(script.Parent.assetFetcher)
local services    = require(script.Parent.services)

local httpService = services.getService("HttpService")
local runService  = services.getService("RunService")



export type FontFace = {
	name:    string,
	weight:  number,
	style:   string,
	assetId: string,
}

export type FontManifest = {
	name:  string,
	faces: { FontFace },
}

export type CachedFont = {
	customId:      string,           
	manifest:      FontManifest,
	variants:      { [string]: Font },
}

export type LoadOptions = {
	weight:      Enum.FontWeight?,
	style:       Enum.FontStyle?,
	saveToDisk:  boolean?,
	skipCache:   boolean?,
	fallback:    Font?,
}

export type FontLoader = {
	load:    (self: FontLoader, id: number | string, opts: LoadOptions?) -> Font?,
	resolve: (self: FontLoader, id: number | string) -> Font?,
	bind:    (self: FontLoader, instance: Instance, property: string, id: number | string, opts: LoadOptions?) -> (),
}



local FONTS_ROOT    = "Delirium/Fonts"
local DEFAULT_FONT  = Font.fromEnum(Enum.Font.SourceSans)
local IS_STUDIO     = runService:IsStudio()


local FONT_SIGNATURES = { "\0\1\0\0", "OTTO", "true", "ttcf", "wOFF", "wOF2" }



local function isFontBody(body: string): boolean
	for _, sig in FONT_SIGNATURES do
		if string.sub(body, 1, #sig) == sig then return true end
	end
	return false
end



local function sanitizeName(name: string): string
	return string.gsub(name, "[^%w%s%-_%.]+", "")
end

local function variantKey(weight: Enum.FontWeight, style: Enum.FontStyle): string
	return tostring(weight.Value) .. "|" .. tostring(style.Value)
end

local function jsonDecode(s: string): unknown?
	local ok, result = pcall(function()
		return httpService:JSONDecode(s)
	end)
	return if ok then result else nil
end

local function jsonEncode(data: unknown): string?
	local ok, result = pcall(function()
		return httpService:JSONEncode(data)
	end)
	return if ok and type(result) == "string" then result else nil
end



local function validateManifest(raw: unknown): FontManifest?
	if type(raw) ~= "table" then return nil end
	local m = raw :: any
	if type(m.name) ~= "string" or type(m.faces) ~= "table" then return nil end
	m.name = sanitizeName(m.name)
	if #m.name == 0 or #m.faces == 0 then return nil end
	for _, face in m.faces do
		if type(face) ~= "table" then return nil end
		if type(face.name) ~= "string" or type(face.assetId) ~= "string" then return nil end
		face.name = sanitizeName(face.name)
		if #face.name == 0 then return nil end
	end
	return m :: FontManifest
end



local FontLoader = {}
FontLoader.__index = FontLoader

function FontLoader.new(): FontLoader
	local self = setmetatable({
		_cache    = {} :: { [number]: CachedFont },
		_fetcher  = AssetFetcher.new(),
		
		
		_bindings = {} :: { [number]: any },
		_loading  = {} :: { [number]: boolean },
	}, FontLoader) :: any
	pcall(filesystem.ensureDir, FONTS_ROOT)
	return self
end

local function resolveId(value: unknown): number?
	if type(value) == "number" then return value end
	if type(value) == "string" then
		return tonumber(string.match(value :: string, "^rbxassetid://(%d+)$"))
			or tonumber(value)
	end
	return nil
end


function FontLoader.resolve(self: FontLoader, id: number | string): Font?
	local numId = resolveId(id)
	if not numId then return nil end
	local cached = (self :: any)._cache[numId]
	if not cached then return nil end
	for _, font in pairs(cached.variants) do return font end
	return nil
end








function FontLoader.load(
	self:    FontLoader,
	id:      number | string,
	opts:    LoadOptions?
): Font?
	local cache:   { [number]: CachedFont } = (self :: any)._cache
	local fetcher: AssetFetcher            = (self :: any)._fetcher

	local weight     = (opts and opts.weight)     or Enum.FontWeight.Regular
	local style      = (opts and opts.style)      or Enum.FontStyle.Normal
	local saveToDisk = if opts and opts.saveToDisk ~= nil then opts.saveToDisk else true
	local skipCache  = if opts and opts.skipCache  ~= nil then opts.skipCache  else false
	local fallback   = (opts and opts.fallback) or DEFAULT_FONT
	local key        = variantKey(weight, style)

	local numId = resolveId(id)
	if not numId then
		warn("[Delirium:fontLoader] Invalid font id: " .. tostring(id))
		return fallback
	end

	
	if not skipCache then
		local cached = cache[numId]
		if cached then
			local hit = cached.variants[key]
			if hit then return hit end
			
			local ok, built = pcall(Font.new, cached.customId, weight, style)
			if ok and built then
				cached.variants[key] = built
				return built
			end
			
			cache[numId] = nil
		end
	end

	
	if not saveToDisk then return fallback end

	
	local env = getfenv()
	if type(env.getcustomasset) ~= "function" or typeof(filesystem.isfile) ~= "function" then
		return fallback
	end

	pcall(filesystem.ensureDir, FONTS_ROOT)

	
	local manifestPath = FONTS_ROOT .. "/" .. tostring(numId) .. ".json"
	local rawManifest: string? = nil
	local needsWrite = false

	if IS_STUDIO then
		
		rawManifest = '{"name":"Inter","faces":[' ..
			'{"name":"Regular","weight":400,"style":"normal","assetId":"rbxassetid://12187266066"},' ..
			'{"name":"Bold","weight":700,"style":"normal","assetId":"rbxassetid://12187275575"}' ..
		']}'
	elseif filesystem.isfile(manifestPath) then
		local ok, contents = pcall(filesystem.readfile, manifestPath)
		rawManifest = if ok then contents else nil
	else
		rawManifest = fetcher:getContentFromId(numId, false)
		needsWrite  = rawManifest ~= nil
	end

	if not rawManifest then return fallback end

	local manifest = validateManifest(jsonDecode(rawManifest))
	if not manifest then
		
		pcall(filesystem.delfile, manifestPath)
		return fallback
	end
	if needsWrite then
		pcall(filesystem.writefile, manifestPath, rawManifest)
	end

	
	local fontDir    = FONTS_ROOT .. "/" .. manifest.name
	local allLocal   = true

	pcall(filesystem.ensureDir, fontDir)

	for i, face in ipairs(manifest.faces) do
		local faceName = string.gsub(face.name, " ", "-")
		local facePath = fontDir .. "/" .. faceName .. ".ttf"

		if not filesystem.isfile(facePath) then
			local faceId = resolveId(face.assetId)
			local body: string? = if faceId
				then fetcher:getContentFromId(faceId, false)
				else nil

			if not body or not isFontBody(body) then
				allLocal = false
				warn(
					"[Delirium:fontLoader] Face download failed for id "
						.. tostring(numId) .. ", face: " .. face.name
				)
				continue
			end
			pcall(filesystem.writefile, facePath, body)
		end

		local ok, uri = pcall(env.getcustomasset, facePath)
		if ok and type(uri) == "string" then
			manifest.faces[i].assetId = uri
		else
			allLocal = false
			warn(
				"[Delirium:fontLoader] getcustomasset failed for face: "
					.. face.name
			)
		end
	end

	if not allLocal then return fallback end

	
	local rewrittenJson = jsonEncode(manifest)
	if not rewrittenJson then return fallback end

	local localManifestPath = fontDir .. "/manifest.json"
	if not pcall(filesystem.writefile, localManifestPath, rewrittenJson) then
		return fallback
	end

	local mOk, manifestUri = pcall(env.getcustomasset, localManifestPath)
	if not mOk or not manifestUri then return fallback end

	
	local fOk, font = pcall(Font.new, manifestUri, weight, style)
	if not fOk or not font then return fallback end

	local entry = cache[numId]
	if not entry then
		entry = { customId = manifestUri, manifest = manifest, variants = {} }
		cache[numId] = entry
	end
	entry.variants[key] = font
	return font
end




function FontLoader.bind(
	self:     FontLoader,
	instance: Instance,
	property: string,
	id:       number | string,
	opts:     LoadOptions?
)
	local cache:    { [number]: CachedFont }  = (self :: any)._cache
	local bindings: { [number]: any }         = (self :: any)._bindings
	local loading:  { [number]: boolean }     = (self :: any)._loading

	local numId = resolveId(id)
	if not numId then
		warn("[Delirium:fontLoader] bind() — invalid id: " .. tostring(id))
		return
	end

	local weight = (opts and opts.weight) or Enum.FontWeight.Regular
	local style  = (opts and opts.style)  or Enum.FontStyle.Normal
	local key    = variantKey(weight, style)

	
	local cached = cache[numId]
	if cached and cached.variants[key] then
		(instance :: any)[property] = cached.variants[key]
		return
	end

	
	local slot = bindings[numId]
	if not slot then
		slot = setmetatable({}, { __mode = "k" }) :: any
		bindings[numId] = slot
	end
	local props = (slot :: any)[instance]
	if not props then
		props = {}
		(slot :: any)[instance] = props
	end
	(props :: any)[property] = opts

	
	if loading[numId] then return end
	loading[numId] = true

	task.spawn(function()
		
		self:load(numId, opts)
		loading[numId] = nil

		
		local bound = bindings[numId]
		if not bound then return end
		local c = cache[numId]
		if not c then return end

		for inst, instanceProps in (bound :: any) do
			if (inst :: Instance).Parent then
				local t = inst :: any
				for prop, bindOpts in (instanceProps :: any) do
					local bOpts   = bindOpts :: LoadOptions?
					local bWeight = (bOpts and bOpts.weight) or Enum.FontWeight.Regular
					local bStyle  = (bOpts and bOpts.style)  or Enum.FontStyle.Normal
					local bKey    = variantKey(bWeight, bStyle)
					local variant = c.variants[bKey]
					if variant then t[prop] = variant end
				end
			end
		end
	end)
end

return FontLoader

end)() end,[30]=function()local wax,script,require=ImportGlobals(30)local ImportGlobals return (function(...)






local services       = require(script.Parent.services)
local ContentProvider = services.getService("ContentProvider") :: ContentProvider

export type IconPackName =
	"Lucide"
	| "Material"
	| "Phosphor"
	| "Phosphor-Filled"
	| "SF"
	| "Symbols"
	| "Symbols-Filled"
	| "Lab"
	| "Fluency"

local PACK_URLS: { [string]: string } = {
	["Lucide"]          = "https://raw.githubusercontent.com/Nebula-Softworks/Nebula-Icon-Library/master/LucideIcons.luau",
	["Material"]        = "https://raw.githubusercontent.com/Nebula-Softworks/Nebula-Icon-Library/master/MaterialIcons.luau",
	["Phosphor"]        = "https://raw.githubusercontent.com/Nebula-Softworks/Nebula-Icon-Library/refs/heads/master/Phosphor.luau",
	["Phosphor-Filled"] = "https://raw.githubusercontent.com/Nebula-Softworks/Nebula-Icon-Library/refs/heads/master/Phosphor%20Filled.luau",
	["SF"]              = "https://raw.githubusercontent.com/Nebula-Softworks/Nebula-Icon-Library/refs/heads/master/SFSymbols.luau",
	["Symbols"]         = "https://raw.githubusercontent.com/Nebula-Softworks/Nebula-Icon-Library/refs/heads/master/Symbols.luau",
	["Symbols-Filled"]  = "https://raw.githubusercontent.com/Nebula-Softworks/Nebula-Icon-Library/refs/heads/master/Symbols-Filled.luau",
	["Lab"]             = "https://raw.githubusercontent.com/Nebula-Softworks/Nebula-Icon-Library/refs/heads/master/LucideLab.luau",
	["Fluency"]         = "https://raw.githubusercontent.com/Nebula-Softworks/Nebula-Icon-Library/refs/heads/master/Fluency.luau",
}

local PREFIX_TO_PACK: { [string]: string } = {
	["lucide"]          = "Lucide",
	["material"]        = "Material",
	["phosphor"]        = "Phosphor",
	["phosphor-filled"] = "Phosphor-Filled",
	["sf"]              = "SF",
	["symbol"]          = "Symbols",
	["symbols"]         = "Symbols",
	["symbol-filled"]   = "Symbols-Filled",
	["symbols-filled"]  = "Symbols-Filled",
	["lab"]             = "Lab",
	["fluency"]         = "Fluency",
	["nebula"]          = "nebulaIcons",
}


local BUILTIN_ICONS: { [string]: number } = {
	
	["settings"]      = 10734950309,
	["settings-2"]    = 75339943202126,
	["minus"]         = 120931250449806,
	["minimize"]      = 120931250449806,
	["minimize-2"]    = 115725194133672,
	["maximize-2"]    = 108777312690515,
	["x"]             = 136096054247483,
	["close"]         = 136096054247483,
	["check"]         = 83827110621355,
	["plus"]          = 118563428285930,
	["chevron-down"]  = 95086910949405,
	["chevron-right"] = 126507964682213,
	["chevron-left"]  = 83856486110301,
	["chevron-up"]    = 124630674114245,
	["search"]        = 125618569555993,
	["lock"]          = 71897067930472,
	["user"]          = 81899856845503,
	["globe"]         = 111578783307093,
	
	["info"]          = 10723415903,
	["success"]       = 10709790387,
	["warning"]       = 10709752935,
	["error"]         = 10747384394,
	
	["sword"]         = 10723407389,
	["swords"]        = 10723407389,
	["eye"]           = 10734975692,
	["home"]          = 111043355839507,
}

local module: any = {}


module.nebulaIcons = {
	stripes       = 8834748103,
	circles       = 73048796459024,
	nebula        = 76656741080367,
	home          = 111043355839507,
	keycache      = 13587387127,
	apps          = 13300918120,
	view_in_ar    = 113380429914565,
	home_material = 9080449299,
	location      = 6034996695,
	sparkle       = 4483362748,
}



local CACHE_KEY_PREFIX = "__DeliriumNebula_"

local function getGenvTable(packName: string): { [string]: number }?
	if type(getgenv) == "function" then
		local ok, env = pcall(getgenv)
		if ok and type(env) == "table" then
			local t = env[CACHE_KEY_PREFIX .. packName]
			if type(t) == "table" then
				return t
			end
		end
	end
	return nil
end

local function setGenvTable(packName: string, data: { [string]: number })
	if type(getgenv) == "function" then
		local ok, env = pcall(getgenv)
		if ok and type(env) == "table" then
			pcall(function() env[CACHE_KEY_PREFIX .. packName] = data end)
		end
	end
end



local function loadPack(packName: string): { [string]: number }?
	if module[packName] and type(module[packName]) == "table" then
		return module[packName]
	end

	
	local genvData = getGenvTable(packName)
	if genvData then
		module[packName] = genvData
		return genvData
	end

	
	local url = PACK_URLS[packName]
	if not url then return nil end

	local ok, loaded = pcall(function()
		local httpGet = (game :: any).HttpGetAsync or (game :: any).HttpGet
		if not httpGet then return nil end
		local src = httpGet(game, url)
		if not src or #src < 10 then return nil end
		local fn = loadstring(src)
		if not fn then return nil end
		return fn()
	end)

	if ok and type(loaded) == "table" then
		module[packName] = loaded
		setGenvTable(packName, loaded)
		return loaded
	end

	return nil
end





function module:GetIcon(name: string, source: string?): number?
	local packName = source or "Lucide"

	
	if packName == "nebulaIcons" or packName == "nebula" then
		local id = module.nebulaIcons[name]
		if id then return id end
	end

	
	local pack = module[packName] or loadPack(packName)
	if pack and pack[name] then
		local id = pack[name]
		if type(id) == "number" then
			pcall(function()
				ContentProvider:PreloadAsync({ "rbxassetid://" .. tostring(id) })
			end)
			return id
		end
	end

	
	if BUILTIN_ICONS[name] then
		return BUILTIN_ICONS[name]
	end

	return nil
end


function module.GetAssetUri(name: string, source: string?): string?
	local id = module:GetIcon(name, source)
	if id then
		return "rbxassetid://" .. tostring(id)
	end
	return nil
end









function module.Resolve(icon: (string | number)?, defaultSource: string?): string?
	if not icon or icon == "" then return nil end

	
	if type(icon) == "number" or tonumber(icon) ~= nil then
		return "rbxassetid://" .. tostring(icon)
	end

	local str = tostring(icon)

	
	if string.sub(str, 1, 13) == "rbxassetid://" or string.sub(str, 1, 9) == "roblox://" or string.sub(str, 1, 4) == "http" then
		return str
	end

	
	local prefix, iconName = string.match(str, "^([%w%-_]+):([%w%-_]+)$")
	if prefix and iconName then
		local packName = PREFIX_TO_PACK[string.lower(prefix)] or prefix
		local id = module:GetIcon(iconName, packName)
		if id then
			return "rbxassetid://" .. tostring(id)
		end
	end

	
	local fallbackPack = defaultSource or "Lucide"
	local directId = module:GetIcon(str, fallbackPack)
		or module:GetIcon(str, "Symbols")
		or BUILTIN_ICONS[str]

	if directId then
		return "rbxassetid://" .. tostring(directId)
	end

	return str
end


function module.PreloadPack(packName: string)
	task.spawn(function()
		loadPack(packName)
	end)
end

return module

end)() end,[31]=function()local wax,script,require=ImportGlobals(31)local ImportGlobals return (function(...)









local imageCache = require(script.Parent.imageCache)

export type OnSettled   = imageCache.OnSettled
export type AvatarReady = imageCache.AvatarReady



local image = {}


image.rewrites = imageCache.rewrites


image.onBlock = nil :: ((value: unknown) -> ())?





image.pending = {} :: { [number]: { [Instance]: { [string]: boolean } } }


local settled = false


local imageProperties: { [string]: boolean } = {
	Image        = true,
	HoverImage   = true,
	PressedImage = true,
}



local function idOf(value: unknown): number?
	if type(value) == "number" then return value end
	if type(value) == "string" then
		return tonumber(string.match(value :: string, "^rbxassetid://(%d+)$"))
	end
	return nil
end

local function blocked(value: unknown): string
	if image.onBlock then image.onBlock(value) end
	return ""
end



imageCache.onCached = function(id: number)
	local waiting = image.pending[id]
	if not waiting then return end
	local uri = image.rewrites[id]
	if uri then
		for instance, props in waiting do
			if instance.Parent then
				local t = instance :: any
				for prop in props do
					t[prop] = uri
				end
			end
		end
	end
	image.pending[id] = nil
end





function image.preload(manifest: { [number]: string }, onSettled: OnSettled?): (boolean, number)
	settled = false
	return imageCache.preload(manifest, function(failed)
		settled = true
		table.clear(image.pending)
		if onSettled then onSettled(failed) end
	end)
end


function image.avatar(userId: number, onReady: AvatarReady?): string
	return imageCache.avatar(userId, onReady)
end






function image.resolve(value: unknown): string
	if value == nil or value == 0 or value == "" then return "" end

	if type(value) == "string" then
		local s = value :: string
		
		if string.sub(s, 1, 11) == "rbxasset://" then return s end
	end

	local id: number? = idOf(value)
	if id then
		local rewrite = image.rewrites[id]
		if rewrite then return rewrite end
	end

	
	
	if type(value) == "number" then
		return "rbxassetid://" .. tostring(value)
	end
	if type(value) == "string" then
		return value
	end

	return blocked(value)
end




function image.assign(instance: Instance, property: string, value: unknown)
	local target = instance :: any

	if not imageProperties[property] then
		target[property] = value
		return
	end

	target[property] = image.resolve(value)

	
	
	if not settled then
		local id = idOf(value)
		if id and not image.rewrites[id] then
			local slot = image.pending[id]
			if not slot then
				
				slot = setmetatable({}, { __mode = "k" }) :: any
				image.pending[id] = slot
			end
			local props = slot[instance]
			if not props then
				props = {}
				slot[instance] = props
			end
			props[property] = true
		end
	end
end

return image

end)() end,[32]=function()local wax,script,require=ImportGlobals(32)local ImportGlobals return (function(...)








local filesystem = require(script.Parent.filesystem)
local AssetFetcher = require(script.Parent.assetFetcher)
local services    = require(script.Parent.services)

local IS_STUDIO = services.getService("RunService"):IsStudio()



export type RewriteMap  = { [number]: string }
export type OnSettled   = (failed: number) -> ()
export type OnCached    = (id: number) -> ()
export type AvatarReady = (uri: string) -> ()



local CACHE_ROOT    = "Delirium"
local CACHE_ASSETS  = "Delirium/Assets"


local THUMB_ENDPOINT =
	"https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds=%d&size=48x48&format=Png&isCircular=false"

local PNG_MAGIC = "\137PNG\r\n\26\n"


local fetcher = AssetFetcher.new()

local imageCache = {}



imageCache.rewrites = {} :: RewriteMap



imageCache.onCached = nil :: OnCached?



local env = getfenv()






local function cacheFile(filePath: string, url: string, cacheKey: number | string): string?
	if type(env.getcustomasset) ~= "function" or typeof(filesystem.isfile) ~= "function" then
		return nil
	end

	if not filesystem.isfile(filePath) then
		pcall(filesystem.ensureFolder, CACHE_ROOT)
		pcall(filesystem.ensureFolder, CACHE_ASSETS)

		local body = fetcher:getContentFromUrl(url, cacheKey, false)
		
		
		if not body or string.sub(body, 1, 8) ~= PNG_MAGIC then
			return nil
		end
		if not pcall(filesystem.writefile, filePath, body) then
			return nil
		end
	end

	local ok, uri = pcall(env.getcustomasset, filePath)
	return if ok and type(uri) == "string" then uri else nil
end

local function avatarFilePath(userId: number): string
	return CACHE_ASSETS .. "/avatar_" .. tostring(userId) .. ".png"
end



local function decodeThumbnailUrl(body: string): string?
	local services = require(script.Parent.services)
	local httpService = services.getService("HttpService")
	local ok, parsed = pcall(function()
		return httpService:JSONDecode(body)
	end)
	if not ok or type(parsed) ~= "table" then return nil end
	local data = (parsed :: any).data
	if type(data) ~= "table" then return nil end
	local entry = (data :: any)[1]
	if type(entry) ~= "table" then return nil end
	if entry.state == "Completed" and type(entry.imageUrl) == "string" then
		return entry.imageUrl
	end
	return nil
end



local function fetchAndCacheAvatar(userId: number): string?
	local cdnUrl: string? = nil
	for attempt = 1, 4 do
		local url = string.format(THUMB_ENDPOINT, userId)
		local cacheKey = "thumb:" .. tostring(userId)
		local body = fetcher:getContentFromUrl(url, cacheKey, attempt > 1)
		if body then
			local imageUrl = decodeThumbnailUrl(body)
			if imageUrl then
				cdnUrl = imageUrl
				break
			end
		end
		task.wait(0.3)
	end
	if not cdnUrl then return nil end
	return cacheFile(avatarFilePath(userId), cdnUrl, "avatar_" .. tostring(userId))
end









function imageCache.preload(manifest: { [number]: string }, onSettled: OnSettled?): (boolean, number)
	local manifestSize = 0
	for _ in manifest do manifestSize += 1 end

	if IS_STUDIO then
		
		
		if onSettled then task.defer(onSettled, 0) end
		return true, 0
	end

	if type(env.getcustomasset) ~= "function" or typeof(filesystem.isfile) ~= "function" then
		if onSettled then task.defer(onSettled, manifestSize) end
		return false, manifestSize
	end

	local rewrites = imageCache.rewrites
	table.clear(rewrites)

	local function settle()
		if not onSettled then return end
		local failed = 0
		for id in manifest do
			if not rewrites[id] then failed += 1 end
		end
		onSettled(failed)
	end

	local pending  = 0
	local missing  = 0
	local spawning = true 

	for id, url in manifest do
		local filePath = CACHE_ASSETS .. "/" .. tostring(id) .. ".png"

		local uri: string? = nil
		if filesystem.isfile(filePath) then
			local ok, res = pcall(env.getcustomasset, filePath)
			uri = if ok and type(res) == "string" then res else nil
		end

		if uri then
			rewrites[id] = uri
		else
			missing += 1
			pending += 1
			task.spawn(function()
				local cached = cacheFile(filePath, url, id)
				if cached then
					rewrites[id] = cached
					if imageCache.onCached then
						pcall(imageCache.onCached, id)
					end
				end
				pending -= 1
				if pending == 0 and not spawning then
					settle()
				end
			end)
		end
	end

	spawning = false
	if pending == 0 then settle() end

	return missing == 0, missing
end




function imageCache.avatar(userId: number, onReady: AvatarReady?): string
	
	
	if IS_STUDIO then
		local uri = string.format(
			"rbxthumb://type=AvatarHeadShot&id=%d&w=48&h=48",
			userId
		)
		if onReady then task.defer(onReady, uri) end
		return uri
	end

	if typeof(filesystem.isfile) ~= "function" then return "" end

	local filePath = avatarFilePath(userId)
	if filesystem.isfile(filePath) then
		local ok, uri = pcall(env.getcustomasset, filePath)
		if ok and type(uri) == "string" then return uri end
	end

	if onReady then
		task.spawn(function()
			local uri = fetchAndCacheAvatar(userId)
			if uri then onReady(uri) end
		end)
	end

	return ""
end

return imageCache

end)() end,[33]=function()local wax,script,require=ImportGlobals(33)local ImportGlobals return (function(...)





































local image      = require(script.Parent.image)
local FontLoader = require(script.Parent.fontLoader)



local MediaService = {}
MediaService.__index = MediaService



local fontLoader = FontLoader.new()






function MediaService:preloadImages(
	manifest:   { [number]: string },
	onSettled:  ((failed: number) -> ())?
): (boolean, number)
	return image.preload(manifest, onSettled)
end



function MediaService:assignImage(instance: Instance, property: string, value: unknown)
	image.assign(instance, property, value)
end


function MediaService:resolveImage(value: unknown): string
	return image.resolve(value)
end


function MediaService:setOnBlock(fn: (value: unknown) -> ())
	image.onBlock = fn
end





function MediaService:avatar(userId: number, onReady: ((uri: string) -> ())?): string
	return image.avatar(userId, onReady)
end













function MediaService:loadFont(
	id:   number | string,
	opts: {
		weight:     Enum.FontWeight?,
		style:      Enum.FontStyle?,
		saveToDisk: boolean?,
		skipCache:  boolean?,
		fallback:   Font?,
	}?
): Font?
	return fontLoader:load(id, opts)
end


function MediaService:resolveFont(id: number | string): Font?
	return fontLoader:resolve(id)
end











function MediaService:bindFont(
	instance: Instance,
	property: string,
	id:       number | string,
	opts: {
		weight:     Enum.FontWeight?,
		style:      Enum.FontStyle?,
		saveToDisk: boolean?,
		fallback:   Font?,
	}?
)
	fontLoader:bind(instance, property, id, opts)
end

return MediaService

end)() end,[34]=function()local wax,script,require=ImportGlobals(34)local ImportGlobals return (function(...)







local network = {}

export type RequestFn = (...any) -> any



function network.getRequestFn(env: any?): RequestFn?
	env = env or getfenv()
	return env.request
		or env.http_request
		or (env.http and env.http.request)
		or (env.syn and env.syn.request)
		or (env.fluxus and env.fluxus.request)
end

return network

end)() end,[35]=function()local wax,script,require=ImportGlobals(35)local ImportGlobals return (function(...)





local services = require(script.Parent.services)

export type RuntimeState = {
	
	secureMode: boolean,

	
	coreGui: CoreGui,
	workspace: Workspace,
	runService: RunService,
	userInputService: UserInputService,
	guiService: GuiService,
	tweenService: TweenService,
	httpService: HttpService,
	textService: TextService,
	contextActionService: ContextActionService,
	replicatedStorage: ReplicatedStorage,

	localPlayer: Player?,

	
	guiContainer: Instance,
}

local runtime = {} :: RuntimeState


runtime.secureMode = (function(): boolean
	if typeof(getgenv) ~= "function" then
		return false
	end
	local ok, val = pcall(function()
		return getgenv().DELIRIUM_SECURE
	end)
	return ok and val == true
end)()

runtime.coreGui           = services.getService("CoreGui") :: CoreGui
runtime.workspace         = services.getService("Workspace") :: Workspace
runtime.runService        = services.getService("RunService") :: RunService
runtime.userInputService  = services.getService("UserInputService") :: UserInputService
runtime.guiService        = services.getService("GuiService") :: GuiService
runtime.tweenService      = services.getService("TweenService") :: TweenService
runtime.httpService       = services.getService("HttpService") :: HttpService
runtime.textService          = services.getService("TextService") :: TextService
runtime.contextActionService = services.getService("ContextActionService") :: ContextActionService
runtime.replicatedStorage    = services.getService("ReplicatedStorage") :: ReplicatedStorage
runtime.localPlayer       = (services.getService("Players") :: Players).LocalPlayer



runtime.isTouchOnly = (function(): boolean
	local uis = runtime.userInputService
	if not uis.TouchEnabled then return false end
	if uis.KeyboardEnabled then return false end
	
	local cam = runtime.workspace.CurrentCamera
	if cam and cam.ViewportSize.X < 600 then return true end
	return true
end)() :: boolean



runtime.guiContainer = (function(): Instance
	if runtime.runService:IsStudio() then
		return (runtime.localPlayer :: Player).PlayerGui
	end
	if typeof(gethui) == "function" then
		local ok, container = pcall(gethui)
		if ok and container then
			return container :: Instance
		end
	end
	return runtime.coreGui
end)()

return runtime

end)() end,[36]=function()local wax,script,require=ImportGlobals(36)local ImportGlobals return (function(...)


















































































local filesystem  = require(script.Parent.filesystem)
local flags       = require(script.Parent.flags)
local services    = require(script.Parent.services)

local HttpService = services.getService("HttpService") :: HttpService



type Setter      = (value: any, skipCallback: boolean?) -> ()
type FlagEntry   = { element: any?, set: Setter }

export type SaveManager = {
	
	SetFolder:           (self: SaveManager, name: string) -> (),
	SetAutoSaveInterval: (self: SaveManager, seconds: number) -> (),
	
	Register:            (self: SaveManager, flag: string, target: any) -> (),
	RegisterMany:        (self: SaveManager, map: { [string]: any }) -> (),
	Ignore:              (self: SaveManager, flag: string) -> (),
	IgnoreMany:          (self: SaveManager, mapOrList: any) -> (),
	GetRegistry:         (self: SaveManager) -> { [string]: FlagEntry },
	
	Save:                (self: SaveManager, profileName: string?) -> boolean,
	Load:                (self: SaveManager, profileName: string?, skipCallbacks: boolean?) -> number,
	Refresh:             (self: SaveManager, skipCallbacks: boolean?) -> (),
	
	List:                (self: SaveManager) -> { string },
	Delete:              (self: SaveManager, profileName: string) -> boolean,
	
	StopAutoSave:        (self: SaveManager) -> (),
	ScheduleAutoSave:    (self: SaveManager) -> (),
	
	BuildConfigTab:      (self: SaveManager, window: any) -> (),
	
	deriveFlagFromName:  (label: string) -> string,
}



local SaveManager   = {} :: any
SaveManager.__index = SaveManager


local _registry  : { [string]: FlagEntry } = {}


local _pendingLoad : { [string]: any } = {}

local _ignored   : { [string]: boolean } = {}

local _folder    : string  = "Delirium"

local _loading   : boolean = false

local _savePending : boolean = false


local _autoEnabled  : boolean = false
local _autoInterval : number  = 30
local _autoThread   : thread? = nil

local _activeProfile : string = "flags"




local function fnv1a(s: string): number
	local h: number = 2166136261
	for i = 1, #s do
		h = bit32.bxor(h, string.byte(s, i))
		h = bit32.band(h * 16777619, 0xFFFFFFFF)
	end
	return h
end


local function resolveProfile(name: string?): string
	if not name then return _activeProfile end
	local trimmed = (name :: string):match("^%s*(.-)%s*$") or ""
	return if #trimmed > 0 then trimmed else "flags"
end

local function profilePath(name: string?): string
	return _folder .. "/" .. resolveProfile(name) .. ".json"
end


local function serializeValue(v: any): any
	local t = typeof(v)
	if t == "EnumItem" then
		return { __type = "EnumItem", enumType = tostring(v.EnumType), name = v.Name }
	elseif t == "Color3" then
		return { __type = "Color3", r = v.R, g = v.G, b = v.B }
	end
	return v
end

local function deserializeValue(v: any): any
	if type(v) ~= "table" or not v.__type then return v end
	if v.__type == "EnumItem" then
		local ok, result = pcall(function()
			return (Enum :: any)[v.enumType][v.name]
		end)
		return if ok and result then result else nil
	elseif v.__type == "Color3" then
		return Color3.new(v.r or 0, v.g or 0, v.b or 0)
	end
	return v
end



local function atomicWrite(path: string, content: string): boolean
	local tempPath = path .. ".saving"

	filesystem.ensureDir(_folder)

	if not pcall(filesystem.writefile, tempPath, content) then return false end

	
	local rOk, readBack = pcall(filesystem.readfile, tempPath)
	if not rOk or readBack ~= content then
		pcall(filesystem.delfile, tempPath)
		return false
	end

	local promOk = pcall(filesystem.writefile, path, content)
	
	pcall(filesystem.delfile, tempPath)
	return promOk
end



local function stopAutoSave()
	if _autoThread then
		task.cancel(_autoThread)
		_autoThread = nil
	end
	_autoEnabled = false
end

local function startAutoSave()
	stopAutoSave()
	_autoEnabled = true
	_autoThread  = task.spawn(function()
		while _autoEnabled do
			task.wait(_autoInterval)
			if _autoEnabled then
				SaveManager:Save(_activeProfile)
			end
		end
		_autoThread = nil
	end)
end






function SaveManager.deriveFlagFromName(label: string): string
	if #label == 0 then return "" end
	local sanitized = label
		:lower()
		:gsub("%s+", "_")
		:gsub("[^%w_]", "")
		:sub(1, 48)
	return if #sanitized > 0 then sanitized else string.format("Flag%08x", fnv1a(label))
end




function SaveManager:SetFolder(name: string)
	assert(type(name) == "string" and #name > 0, "SaveManager:SetFolder — name must be a non-empty string")
	_folder = name
end


function SaveManager:SetAutoSaveInterval(seconds: number)
	assert(type(seconds) == "number" and seconds > 0, "SaveManager:SetAutoSaveInterval — must be > 0")
	_autoInterval = seconds
end










function SaveManager:Register(flag: string, target: any)
	assert(type(flag) == "string" and #flag > 0, "SaveManager:Register — flag must be a non-empty string")

	local entry: FlagEntry
	if type(target) == "function" then
		entry = { set = target }
	elseif type(target) == "table" and target.Set then
		local el = target
		entry = {
			element = el,
			set = function(value: any, skipCallback: boolean?)
				el:Set(value, skipCallback)
			end,
		}
	else
		error("SaveManager:Register — target must be a function or a component with a :Set method", 2)
	end

	_registry[flag] = entry

	
	local pending = _pendingLoad[flag]
	if pending ~= nil then
		_pendingLoad[flag] = nil
		flags:Set(flag, pending)
		
		
		pcall(entry.set, pending, false)
	end
end



function SaveManager:RegisterMany(map: { [string]: any })
	for flag, target in map do
		self:Register(flag, target)
	end
end


function SaveManager:Ignore(flag: string)
	_ignored[flag] = true
end


function SaveManager:IgnoreMany(mapOrList: any)
	if type(mapOrList) ~= "table" then return end
	for k, v in mapOrList do
		if type(k) == "number" and type(v) == "string" then
			_ignored[v] = true
		elseif type(k) == "string" and v == true then
			_ignored[k] = true
		end
	end
end


function SaveManager:GetRegistry(): { [string]: FlagEntry }
	return _registry
end





function SaveManager:Save(profileName: string?): boolean
	local snapshot = flags:GetAll()
	local data: { [string]: any } = {}

	for k, v in snapshot do
		if not _ignored[k] then
			data[k] = serializeValue(v)
		end
	end

	local ok, encoded = pcall(function()
		return HttpService:JSONEncode(data)
	end)
	if not ok or type(encoded) ~= "string" then return false end

	return atomicWrite(profilePath(profileName), encoded)
end






function SaveManager:Load(profileName: string?, skipCallbacks: boolean?): number
	local path = profilePath(profileName)

	local raw: string? = nil
	pcall(function()
		if filesystem.isfile(path) then
			raw = filesystem.readfile(path)
		end
	end)
	if not raw or raw == "" then return 0 end

	local ok, data = pcall(HttpService.JSONDecode, HttpService, raw :: string)
	if not ok or type(data) ~= "table" then return 0 end

	
	table.clear(_pendingLoad)

	_loading = true
	local count = 0
	local skip = (skipCallbacks == true)

	for flag, rawValue in data do
		if _ignored[flag] then continue end

		local value = deserializeValue(rawValue)
		if value == nil then continue end

		_pendingLoad[flag] = value
		flags:Set(flag, value)

		local entry = _registry[flag]
		if entry then
			if pcall(entry.set, value, skip) then
				count += 1
			end
			_pendingLoad[flag] = nil
		else
			count += 1
		end
	end

	_loading = false
	return count
end




function SaveManager:Refresh(skipCallbacks: boolean?)
	local skip = (skipCallbacks == true)
	for flag, entry in _registry do
		local value = flags:Get(flag)
		if value ~= nil then
			pcall(entry.set, value, skip)
		end
	end
end





function SaveManager:List(): { string }
	local names: { string } = {}
	pcall(function()
		filesystem.ensureDir(_folder)
		for _, path in filesystem.listfiles(_folder) do
			local normalized = path:gsub("\\", "/")
			local filename   = normalized:match("([^/]+)$") or ""
			if filename:match("%.saving$") then continue end
			local name = filename:match("^(.-)%.json$")
			if name and #name > 0 then
				table.insert(names, name)
			end
		end
	end)
	table.sort(names)
	return names
end


function SaveManager:Delete(profileName: string): boolean
	local trimmed = resolveProfile(profileName)
	if trimmed == "flags" and (not profileName or profileName == "") then
		
		return false
	end
	local path = profilePath(trimmed)
	local existed = pcall(function()
		if not filesystem.isfile(path) then error("not found") end
		filesystem.delfile(path)
	end)
	return existed
end




function SaveManager:StopAutoSave()
	stopAutoSave()
end




function SaveManager:ScheduleAutoSave()
	if _loading or _savePending then return end
	_savePending = true
	task.delay(0.5, function()
		_savePending = false
		if not _loading then
			self:Save(_activeProfile)
		end
	end)
end












function SaveManager:BuildConfigTab(window: any)
	
	_ignored["__SM_input_profile"] = true
	_ignored["__SM_dd_profiles"]   = true
	_ignored["__SM_toggle_auto"]   = true

	local tab = window:CreateTab({
		name    = "Config",
		icon    = "lucide:save",
		columns = 1,
	})

	local col = tab.Left

	
	col:CreateSection({ name = "Profile" })

	
	col:CreateInput({
		name         = "Profile Name",
		placeholder  = "flags  (default)",
		flag         = "__SM_input_profile",
		value        = _activeProfile,
		clearOnFocus = false,
		callback     = function(v: string)
			local trimmed = v:match("^%s*(.-)%s*$") or ""
			_activeProfile = if #trimmed > 0 then trimmed else "flags"
		end,
	})

	local ddHandle: any = nil

	local function refreshDropdown()
		if not ddHandle then return end
		local list = self:List()
		ddHandle:SetOptions(if #list > 0 then list else { "(no profiles)" })
	end

	
	ddHandle = col:CreateDropdown({
		name        = "Saved Profiles",
		options     = (function()
			local list = self:List()
			return if #list > 0 then list else { "(no profiles)" }
		end)(),
		placeholder = "select to autofill name...",
		flag        = "__SM_dd_profiles",
		callback    = function(value: string | { string })
			local pick = if type(value) == "string"
				then value :: string
				else (value :: { string })[1] or ""
			
			if pick == "(no profiles)" then return end
			_activeProfile = pick
			
			
			flags:Set("__SM_input_profile", pick)
		end,
	})

	
	col:CreateSection({ name = "Actions" })

	col:CreateButton({
		name        = "Save",
		description = "Write all flags to the active profile.",
		callback    = function()
			local name = _activeProfile
			local ok   = self:Save(name)
			refreshDropdown()
			if ok then
				window:Notify({
					title   = "Saved",
					content = "Profile '" .. name .. "' written to disk.",
					type    = "success",
					duration = 3,
				})
			else
				window:Notify({
					title   = "Save Failed",
					content = "Could not write '" .. name .. "'. Check executor filesystem.",
					type    = "error",
					duration = 4,
				})
			end
		end,
	})

	col:CreateButton({
		name        = "Load",
		description = "Restore flags from the active profile.",
		callback    = function()
			local name  = _activeProfile
			local count = self:Load(name)
			if count > 0 then
				window:Notify({
					title   = "Loaded",
					content = "Profile '" .. name .. "' — " .. tostring(count) .. " flags restored.",
					type    = "success",
					duration = 3,
				})
			else
				window:Notify({
					title   = "Load",
					content = "Profile '" .. name .. "' not found or empty.",
					type    = "warning",
					duration = 3,
				})
			end
		end,
	})

	col:CreateButton({
		name        = "Delete",
		description = "Permanently remove the active profile from disk.",
		callback    = function()
			local name = _activeProfile
			local ok   = self:Delete(name)
			refreshDropdown()
			if ok then
				window:Notify({
					title   = "Deleted",
					content = "Profile '" .. name .. "' removed.",
					type    = "info",
					duration = 3,
				})
			else
				window:Notify({
					title   = "Delete Failed",
					content = "Profile '" .. name .. "' not found.",
					type    = "error",
					duration = 3,
				})
			end
		end,
	})

	
	col:CreateSection({ name = "Auto Save" })

	col:CreateToggle({
		name        = "Auto Save",
		description = "Save every " .. tostring(_autoInterval) .. " s to the active profile.",
		flag        = "__SM_toggle_auto",
		value       = false,
		callback    = function(enabled: boolean)
			if enabled then
				startAutoSave()
				window:Notify({
					title   = "Auto Save On",
					content = "Saving every " .. tostring(_autoInterval) .. " s to '" .. _activeProfile .. "'.",
					type    = "info",
					duration = 3,
				})
			else
				stopAutoSave()
				window:Notify({
					title   = "Auto Save Off",
					content = "Stopped.",
					type    = "info",
					duration = 2,
				})
			end
		end,
	})
end

return SaveManager

end)() end,[37]=function()local wax,script,require=ImportGlobals(37)local ImportGlobals return (function(...)





local services = {}

function services.getService(name: string): Instance
	local service = game:GetService(name)
	return if typeof(cloneref) == "function" then cloneref(service) else service
end

return services

end)() end,[38]=function()local wax,script,require=ImportGlobals(38)local ImportGlobals return (function(...)











export type Connection = {
	Connected: boolean,
	Disconnect: (self: Connection) -> (),
}

export type Signal<T...> = {
	Connect:      (self: Signal<T...>, fn: (T...) -> ()) -> Connection,
	Once:         (self: Signal<T...>, fn: (T...) -> ()) -> Connection,
	Fire:         (self: Signal<T...>,T...) -> (),
	Wait:         (self: Signal<T...>) -> T...,
	DisconnectAll:(self: Signal<T...>) -> (),
	Destroy:      (self: Signal<T...>) -> (),
}

local Signal = {}
Signal.__index = Signal

type Entry = { fn: (...any) -> (), once: boolean }

type InternalSignal = {
	_listeners: { Entry },
	_destroyed: boolean,
}

local function makeConnection(sig: InternalSignal, entry: Entry): Connection
	local conn: { [string]: any } = {
		Connected = true,
	}

	conn.Disconnect = function(c: { [string]: any })
		if not c.Connected then return end
		c.Connected = false
		local listeners = sig._listeners
		for i = #listeners, 1, -1 do
			if listeners[i] == entry then
				table.remove(listeners, i)
				break
			end
		end
	end

	return conn :: any
end

function Signal.new<T...>(): Signal<T...>
	local self: InternalSignal = {
		_listeners = {},
		_destroyed = false,
	}
	return setmetatable(self, Signal) :: any
end

function Signal:Connect(fn: (...any) -> ()): Connection
	assert(not self._destroyed, "Signal:Connect called on a destroyed signal")
	local entry: Entry = { fn = fn, once = false }
	table.insert(self._listeners, entry)
	return makeConnection(self, entry)
end

function Signal:Once(fn: (...any) -> ()): Connection
	assert(not self._destroyed, "Signal:Once called on a destroyed signal")
	local entry: Entry = { fn = fn, once = true }
	table.insert(self._listeners, entry)
	return makeConnection(self, entry)
end

function Signal:Fire(...: any)
	if self._destroyed then return end
	
	local snapshot = table.clone(self._listeners)
	for _, entry in snapshot do
		if entry.once then
			
			for i = #self._listeners, 1, -1 do
				if self._listeners[i] == entry then
					table.remove(self._listeners, i)
					break
				end
			end
		end
		task.spawn(entry.fn, ...)
	end
end

function Signal:Wait(): ...any
	local thread = coroutine.running()
	self:Once(function(...: any)
		task.spawn(thread, ...)
	end)
	return coroutine.yield()
end

function Signal:DisconnectAll()
	table.clear(self._listeners)
end

function Signal:Destroy()
	self._destroyed = true
	table.clear(self._listeners)
end

return Signal

end)() end,[39]=function()local wax,script,require=ImportGlobals(39)local ImportGlobals return (function(...)



























local defaultTheme = require(script.Parent.Parent.themes.default)
local lightTheme   = require(script.Parent.Parent.themes.light)
local draculaTheme = require(script.Parent.Parent.themes.dracula)



export type ThemeTable      = { [string]: any }
export type ThemeInput      = string | ThemeTable
export type ThemeListener   = (resolved: ThemeTable) -> ()
export type Unsubscribe     = () -> ()

export type Binding = {
	key: string,
	set: (value: any) -> (),
}
export type BindingList = { Binding }

export type ValidationResult = {
	missing: { string },
	unknown: { string },
}

export type DiffResult = { [string]: { from: any, to: any } }



local _registry: { [string]: ThemeTable } = {
	Default = defaultTheme,
	Light   = lightTheme,
	Dracula = draculaTheme,
}

local _lower: { [string]: string } = {}
for name in _registry do
	_lower[string.lower(name)] = name
end


local _subscribers: { [number]: ThemeListener } = {}
local _nextId = 0


local _current: ThemeTable = table.clone(defaultTheme)



local function _canonicalName(name: string): string?
	if _registry[name] then return name end
	return _lower[string.lower(name)]
end



local theme = {}










function theme.resolve(input: ThemeInput?): ThemeTable
	if input == nil then
		return table.clone(defaultTheme)
	end

	if typeof(input) == "string" then
		local canonical = _canonicalName(input)
		if not canonical then
			warn(string.format('[Delirium] Unknown theme "%s", falling back to Default.', input))
			return table.clone(defaultTheme)
		end
		if canonical == "Default" then
			return table.clone(defaultTheme)
		end
		
		return theme.merge(defaultTheme, _registry[canonical])
	end

	return theme.merge(defaultTheme, input :: ThemeTable)
end







function theme.merge(base: ThemeTable, override: ThemeTable): ThemeTable
	local result = table.clone(base)
	for k, v in override do
		result[k] = v
	end
	return result
end

















function theme.subscribe(listener: ThemeListener): Unsubscribe
	_nextId += 1
	local id = _nextId
	_subscribers[id] = listener

	
	listener(_current)

	return function()
		_subscribers[id] = nil
	end
end












function theme.broadcast(resolved: ThemeTable)
	_current = resolved
	for _, listener in _subscribers do
		local ok, err = pcall(listener, resolved)
		if not ok then
			warn("[Delirium] theme.broadcast listener error: " .. tostring(err))
		end
	end
end







function theme.current(): ThemeTable
	return _current
end









function theme.apply(resolved: ThemeTable, bindings: BindingList)
	for _, b in bindings do
		local val = resolved[b.key]
		if val ~= nil then
			b.set(val)
		else
			warn(string.format('[Delirium] theme.apply: unknown key "%s".', b.key))
		end
	end
end








function theme.registerTheme(name: string, input: ThemeInput)
	if name == "Default" then
		warn('[Delirium] theme.registerTheme: cannot overwrite "Default".')
		return
	end

	if typeof(input) == "string" then
		local canonical = _canonicalName(input)
		if not canonical then
			warn(string.format('[Delirium] theme.registerTheme: source theme "%s" not found.', input))
			return
		end
		_registry[name] = _registry[canonical]
	else
		_registry[name] = input :: ThemeTable
	end

	_lower[string.lower(name)] = name
end





function theme.list(): { string }
	local names: { string } = {}
	for name in _registry do
		table.insert(names, name)
	end
	table.sort(names)
	return names
end





function theme.isTheme(name: string): boolean
	return _canonicalName(name) ~= nil
end






function theme.extend(baseName: string, override: ThemeTable): ThemeTable
	return theme.merge(theme.resolve(baseName), override)
end






function theme.validate(t: ThemeTable): ValidationResult
	local missing: { string } = {}
	local unknown: { string } = {}

	for key in defaultTheme do
		if t[key] == nil then table.insert(missing, key) end
	end
	for key in t do
		if defaultTheme[key] == nil then table.insert(unknown, key) end
	end

	table.sort(missing)
	table.sort(unknown)
	return { missing = missing, unknown = unknown }
end






function theme.diff(a: ThemeTable, b: ThemeTable): DiffResult
	local result: DiffResult = {}
	local seen: { [string]: boolean } = {}

	for k in a do seen[k] = true end
	for k in b do seen[k] = true end

	for k in seen do
		if a[k] ~= b[k] then
			result[k] = { from = a[k], to = b[k] }
		end
	end

	return result
end

return theme
end)() end,[40]=function()local wax,script,require=ImportGlobals(40)local ImportGlobals return (function(...)





local runtime   = require(script.Parent.runtime)
local constants = require(script.Parent.constants)

local tween = {}


function tween.play(
	instance: Instance,
	tweenInfo: TweenInfo,
	props: { [string]: any }
): Tween
	local t = runtime.tweenService:Create(instance, tweenInfo, props)
	t:Play()
	return t
end



function tween.fire(
	instance: Instance,
	tweenInfo: TweenInfo,
	props: { [string]: any }
)
	local t = runtime.tweenService:Create(instance, tweenInfo, props)
	t:Play()
	t.Completed:Once(function(state)
		t:Destroy()
	end)
end


function tween.cancel(t: Tween?)
	if t then
		t:Cancel()
		t:Destroy()
	end
end



function tween.pulse(
	instance: GuiObject,
	tweenIn: TweenInfo,
	tweenOut: TweenInfo
): (Tween, Tween)
	local fadeIn = runtime.tweenService:Create(instance, tweenIn, { BackgroundTransparency = 0 })
	local fadeOut = runtime.tweenService:Create(instance, tweenOut, { BackgroundTransparency = 1 })
	fadeIn:Play()
	fadeIn.Completed:Once(function(state)
		if state == Enum.PlaybackState.Completed then
			fadeOut:Play()
		end
	end)
	return fadeIn, fadeOut
end


function tween.resizePill(
	instance: GuiObject,
	targetSize: UDim2,
	animated: boolean?
): Tween?
	if animated ~= false then
		return tween.play(instance, constants.pillResizeInfo, { Size = targetSize })
	else
		instance.Size = targetSize
		return nil
	end
end

return tween

end)() end,[41]=function()local wax,script,require=ImportGlobals(41)local ImportGlobals return (function(...)







local runtime  = require(script.Parent.runtime)
local constants = require(script.Parent.constants)

export type VariablesState = typeof(runtime) & {
	
	activeTheme: { [string]: any },

	
	font:      Font,
	titleFont: Font,

	
	isTouchOnly: boolean,
}


local variables: VariablesState = table.clone(runtime) :: any



variables.font      = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium)
variables.titleFont = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold)




variables.activeTheme = {} :: { [string]: any }




variables.uiScale = 1.0



variables.settingsOpen = false

return variables

end)() end,[42]=function()local wax,script,require=ImportGlobals(42)local ImportGlobals return (function(...)
















local constants = require(script.Parent.constants)

local windowSizing = {}

local defaultSize = constants.windowSize
local minSize     = constants.windowMinSize



local maxOccupancyX, maxOccupancyY = 0.86, 0.80



local marginFloorX, marginFloorY = 20, 24



local widthCompensation = 60
local maxAspectRatio    = 1.80


local minPlausibleViewport = 200


local REFERENCE = Vector2.new(1366, 768)

windowSizing.defaultSize = defaultSize
windowSizing.minSize     = minSize




local function heightDeficit(height: number): number
	return math.clamp(
		(defaultSize.Y - height) / (defaultSize.Y - minSize.Y),
		0, 1
	)
end



function windowSizing.fit(viewport: Vector2?): UDim2
	if not viewport
		or viewport.X < minPlausibleViewport
		or viewport.Y < minPlausibleViewport
	then
		return UDim2.fromOffset(defaultSize.X, defaultSize.Y)
	end

	local availableX = math.min(viewport.X * maxOccupancyX, viewport.X - marginFloorX)
	local availableY = math.min(viewport.Y * maxOccupancyY, viewport.Y - marginFloorY)

	
	
	
	local height = math.floor(math.min(availableY, defaultSize.Y))

	local deficit = heightDeficit(height)
	local width   = math.max(defaultSize.X + widthCompensation * deficit, minSize.X)

	
	width = math.floor(math.min(width, availableX, height * maxAspectRatio))

	return UDim2.fromOffset(width, height)
end





function windowSizing.computeScale(viewport: Vector2?): number
	if not viewport
		or viewport.X < minPlausibleViewport
		or viewport.Y < minPlausibleViewport
	then
		return 1.0
	end
	local scaleX = viewport.X / REFERENCE.X
	local scaleY = viewport.Y / REFERENCE.Y
	return math.clamp(math.min(scaleX, scaleY), 0.45, 1.0)
end

return windowSizing

end)() end} 


local ObjectTree = {{1,2,{"Delirium"},{{23,1,{"utility"},{{37,2,{"services"}},{36,2,{"saveManager"}},{29,2,{"fontLoader"}},{38,2,{"signal"}},{34,2,{"network"}},{35,2,{"runtime"}},{26,2,{"element"}},{40,2,{"tween"}},{28,2,{"flags"}},{27,2,{"filesystem"}},{32,2,{"imageCache"}},{24,2,{"assetFetcher"}},{42,2,{"windowSizing"}},{39,2,{"theme"}},{31,2,{"image"}},{30,2,{"icons"}},{41,2,{"variables"}},{33,2,{"mediaService"}},{25,2,{"constants"}}}},{2,1,{"components"},{{12,2,{"notification"}},{9,2,{"keybind"}},{14,2,{"slider"}},{8,2,{"input"}},{5,2,{"dashboard"}},{3,2,{"button"}},{10,2,{"label"}},{11,2,{"loadingScreen"}},{7,2,{"dropdown"}},{16,2,{"toggle"}},{15,2,{"tab"}},{13,2,{"section"}},{17,2,{"window"}},{6,2,{"descriptor"}},{4,2,{"colorpicker"}}}},{22,2,{"types"}},{18,1,{"themes"},{{20,2,{"dracula"}},{21,2,{"light"}},{19,2,{"default"}}}}}}}


local LineOffsets = nil


local WaxVersion = "0.4.1"
local EnvName = "WaxRuntime"




local string, task, setmetatable, error, next, table, unpack, coroutine, script, type, require, pcall, tostring, tonumber, _VERSION =
      string, task, setmetatable, error, next, table, unpack, coroutine, script, type, require, pcall, tostring, tonumber, _VERSION

local table_insert = table.insert
local table_remove = table.remove
local table_freeze = table.freeze or function(t) return t end 

local coroutine_wrap = coroutine.wrap

local string_sub = string.sub
local string_match = string.match
local string_gmatch = string.gmatch



if _VERSION and string_sub(_VERSION, 1, 4) == "Lune" then
    local RequireSuccess, LuneTaskLib = pcall(require, "@lune/task")
    if RequireSuccess and LuneTaskLib then
        task = LuneTaskLib
    end
end

local task_defer = task and task.defer


local Defer = task_defer or function(f, ...)
    coroutine_wrap(f)(...)
end


local ClassNameIdBindings = {
    [1] = "Folder",
    [2] = "ModuleScript",
    [3] = "Script",
    [4] = "LocalScript",
    [5] = "StringValue",
}

local RefBindings = {} 

local ScriptClosures = {}
local ScriptClosureRefIds = {} 
local StoredModuleValues = {}
local ScriptsToRun = {}


local SharedEnvironment = {}



local RefChildren = {} 


local InstanceMethods = {
    GetFullName = { {}, function(self)
        local Path = self.Name
        local ObjectPointer = self.Parent

        while ObjectPointer do
            Path = ObjectPointer.Name .. "." .. Path

            
            ObjectPointer = ObjectPointer.Parent
        end

        return Path
    end},

    GetChildren = { {}, function(self)
        local ReturnArray = {}

        for Child in next, RefChildren[self] do
            table_insert(ReturnArray, Child)
        end

        return ReturnArray
    end},

    GetDescendants = { {}, function(self)
        local ReturnArray = {}

        for Child in next, RefChildren[self] do
            table_insert(ReturnArray, Child)

            for _, Descendant in next, Child:GetDescendants() do
                table_insert(ReturnArray, Descendant)
            end
        end

        return ReturnArray
    end},

    FindFirstChild = { {"string", "boolean?"}, function(self, name, recursive)
        local Children = RefChildren[self]

        for Child in next, Children do
            if Child.Name == name then
                return Child
            end
        end

        if recursive then
            for Child in next, Children do
                
                
                return Child:FindFirstChild(name, true)
            end
        end
    end},

    FindFirstAncestor = { {"string"}, function(self, name)
        local RefPointer = self.Parent
        while RefPointer do
            if RefPointer.Name == name then
                return RefPointer
            end

            RefPointer = RefPointer.Parent
        end
    end},

    
    WaitForChild = { {"string", "number?"}, function(self, name)
        return self:FindFirstChild(name)
    end},
}


local InstanceMethodProxies = {}
for MethodName, MethodObject in next, InstanceMethods do
    local Types = MethodObject[1]
    local Method = MethodObject[2]

    local EvaluatedTypeInfo = {}
    for ArgIndex, TypeInfo in next, Types do
        local ExpectedType, IsOptional = string_match(TypeInfo, "^([^%?]+)(%??)")
        EvaluatedTypeInfo[ArgIndex] = {ExpectedType, IsOptional}
    end

    InstanceMethodProxies[MethodName] = function(self, ...)
        if not RefChildren[self] then
            error("Expected ':' not '.' calling member function " .. MethodName, 2)
        end

        local Args = {...}
        for ArgIndex, TypeInfo in next, EvaluatedTypeInfo do
            local RealArg = Args[ArgIndex]
            local RealArgType = type(RealArg)
            local ExpectedType, IsOptional = TypeInfo[1], TypeInfo[2]

            if RealArg == nil and not IsOptional then
                error("Argument " .. RealArg .. " missing or nil", 3)
            end

            if ExpectedType ~= "any" and RealArgType ~= ExpectedType and not (RealArgType == "nil" and IsOptional) then
                error("Argument " .. ArgIndex .. " expects type \"" .. ExpectedType .. "\", got \"" .. RealArgType .. "\"", 2)
            end
        end

        return Method(self, ...)
    end
end

local function CreateRef(className, name, parent)
    

    
    local StringValue_Value

    
    local Children = setmetatable({}, {__mode = "k"})

    
    local function InvalidMember(member)
        error(member .. " is not a valid (virtual) member of " .. className .. " \"" .. name .. "\"", 3)
    end
    local function ReadOnlyProperty(property)
        error("Unable to assign (virtual) property " .. property .. ". Property is read only", 3)
    end

    local Ref = {}
    local RefMetatable = {}

    RefMetatable.__metatable = false

    RefMetatable.__index = function(_, index)
        if index == "ClassName" then 
            return className
        elseif index == "Name" then
            return name
        elseif index == "Parent" then
            return parent
        elseif className == "StringValue" and index == "Value" then
            
            return StringValue_Value
        else 
            local InstanceMethod = InstanceMethodProxies[index]

            if InstanceMethod then
                return InstanceMethod
            end
        end

        
        for Child in next, Children do
            if Child.Name == index then
                return Child
            end
        end

        
        InvalidMember(index)
    end

    RefMetatable.__newindex = function(_, index, value)
        
        if index == "ClassName" then
            ReadOnlyProperty(index)
        elseif index == "Name" then
            name = value
        elseif index == "Parent" then
            
            if value == Ref then
                return
            end

            if parent ~= nil then
                
                RefChildren[parent][Ref] = nil
            end

            parent = value

            if value ~= nil then
                
                RefChildren[value][Ref] = true
            end
        elseif className == "StringValue" and index == "Value" then
            
            StringValue_Value = value
        else
            
            InvalidMember(index)
        end
    end

    RefMetatable.__tostring = function()
        return name
    end

    setmetatable(Ref, RefMetatable)

    RefChildren[Ref] = Children

    if parent ~= nil then
        RefChildren[parent][Ref] = true
    end

    return Ref
end


local function CreateRefFromObject(object, parent)
    local RefId = object[1]
    local ClassNameId = object[2]
    local Properties = object[3] 
    local Children = object[4] 

    local ClassName = ClassNameIdBindings[ClassNameId]

    local Name = Properties and table_remove(Properties, 1) or ClassName

    local Ref = CreateRef(ClassName, Name, parent) 
    RefBindings[RefId] = Ref

    if Properties then
        for PropertyName, PropertyValue in next, Properties do
            Ref[PropertyName] = PropertyValue
        end
    end

    if Children then
        for _, ChildObject in next, Children do
            CreateRefFromObject(ChildObject, Ref)
        end
    end

    return Ref
end

local RealObjectRoot = CreateRef("Folder", "[" .. EnvName .. "]")
for _, Object in next, ObjectTree do
    CreateRefFromObject(Object, RealObjectRoot)
end


for RefId, Closure in next, ClosureBindings do
    local Ref = RefBindings[RefId]

    ScriptClosures[Ref] = Closure
    ScriptClosureRefIds[Ref] = RefId

    local ClassName = Ref.ClassName
    if ClassName == "LocalScript" or ClassName == "Script" then
        table_insert(ScriptsToRun, Ref)
    end
end

local function LoadScript(scriptRef)
    local ScriptClassName = scriptRef.ClassName

    
    local StoredModuleValue = StoredModuleValues[scriptRef]
    if StoredModuleValue and ScriptClassName == "ModuleScript" then
        return unpack(StoredModuleValue)
    end

    local Closure = ScriptClosures[scriptRef]

    local function FormatError(originalErrorMessage)
        originalErrorMessage = tostring(originalErrorMessage)

        local VirtualFullName = scriptRef:GetFullName()

        
        local OriginalErrorLine, BaseErrorMessage = string_match(originalErrorMessage, "[^:]+:(%d+): (.+)")

        if not OriginalErrorLine or not LineOffsets then
            return VirtualFullName .. ":*: " .. (BaseErrorMessage or originalErrorMessage)
        end

        OriginalErrorLine = tonumber(OriginalErrorLine)

        local RefId = ScriptClosureRefIds[scriptRef]
        local LineOffset = LineOffsets[RefId]

        local RealErrorLine = OriginalErrorLine - LineOffset + 1
        if RealErrorLine < 0 then
            RealErrorLine = "?"
        end

        return VirtualFullName .. ":" .. RealErrorLine .. ": " .. BaseErrorMessage
    end

    
    if ScriptClassName == "LocalScript" or ScriptClassName == "Script" then
        local RunSuccess, ErrorMessage = pcall(Closure)
        if not RunSuccess then
            error(FormatError(ErrorMessage), 0)
        end
    else
        local PCallReturn = {pcall(Closure)}

        local RunSuccess = table_remove(PCallReturn, 1)
        if not RunSuccess then
            local ErrorMessage = table_remove(PCallReturn, 1)
            error(FormatError(ErrorMessage), 0)
        end

        StoredModuleValues[scriptRef] = PCallReturn
        return unpack(PCallReturn)
    end
end



function ImportGlobals(refId)
    local ScriptRef = RefBindings[refId]

    local function RealCall(f, ...)
        local PCallReturn = {pcall(f, ...)}

        local CallSuccess = table_remove(PCallReturn, 1)
        if not CallSuccess then
            error(PCallReturn[1], 3)
        end

        return unpack(PCallReturn)
    end

    
    local WaxShared = table_freeze(setmetatable({}, {
        __index = SharedEnvironment,
        __newindex = function(_, index, value)
            SharedEnvironment[index] = value
        end,
        __len = function()
            return #SharedEnvironment
        end,
        __iter = function()
            return next, SharedEnvironment
        end,
    }))

    local Global_wax = table_freeze({
        
        version = WaxVersion,
        envname = EnvName,

        shared = WaxShared,

        
        script = script,
        require = require,
    })

    local Global_script = ScriptRef

    local function Global_require(module, ...)
        local ModuleArgType = type(module)

        local ErrorNonModuleScript = "Attempted to call require with a non-ModuleScript"
        local ErrorSelfRequire = "Attempted to call require with self"

        if ModuleArgType == "table" and RefChildren[module]  then
            if module.ClassName ~= "ModuleScript" then
                error(ErrorNonModuleScript, 2)
            elseif module == ScriptRef then
                error(ErrorSelfRequire, 2)
            end

            return LoadScript(module)
        elseif ModuleArgType == "string" and string_sub(module, 1, 1) ~= "@" then
            

            if #module == 0 then
                error("Attempted to call require with empty string", 2)
            end

            local CurrentRefPointer = ScriptRef

            if string_sub(module, 1, 1) == "/" then
                CurrentRefPointer = RealObjectRoot
            elseif string_sub(module, 1, 2) == "./" then
                module = string_sub(module, 3)
            end

            local PreviousPathMatch
            for PathMatch in string_gmatch(module, "([^/]*)/?") do
                local RealIndex = PathMatch
                if PathMatch == ".." then
                    RealIndex = "Parent"
                end

                
                if RealIndex ~= "" then
                    local ResultRef = CurrentRefPointer:FindFirstChild(RealIndex)
                    if not ResultRef then
                        local CurrentRefParent = CurrentRefPointer.Parent
                        if CurrentRefParent then
                            ResultRef = CurrentRefParent:FindFirstChild(RealIndex)
                        end
                    end

                    if ResultRef then
                        CurrentRefPointer = ResultRef
                    elseif PathMatch ~= PreviousPathMatch and PathMatch ~= "init" and PathMatch ~= "init.server" and PathMatch ~= "init.client" then
                        error("Virtual script path \"" .. module .. "\" not found", 2)
                    end
                end

                
                PreviousPathMatch = PathMatch
            end

            if CurrentRefPointer.ClassName ~= "ModuleScript" then
                error(ErrorNonModuleScript, 2)
            elseif CurrentRefPointer == ScriptRef then
                error(ErrorSelfRequire, 2)
            end

            return LoadScript(CurrentRefPointer)
        end

        return RealCall(require, module, ...)
    end

    
    return Global_wax, Global_script, Global_require
end

for _, ScriptRef in next, ScriptsToRun do
    Defer(LoadScript, ScriptRef)
end


return LoadScript(RealObjectRoot:GetChildren()[1])