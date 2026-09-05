--!strict

local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players          = game:GetService("Players")

local Theme = require(script.Parent.Parent.Theme)

local TWEEN_IN  = TweenInfo.new(0.20, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local TWEEN_OUT = TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.In)

local _gui: ScreenGui?     = nil
local _tipFrame: Frame?    = nil
local _tipLabel: TextLabel? = nil
local _tipScale: UIScale?  = nil
local _tipStroke: UIStroke? = nil

local _activeTarget: GuiObject? = nil
local _currentText: string      = ""
local _showThread: thread?      = nil
local _hideThread: thread?      = nil
local _isShown                  = false

local function ensureGui(parentGui: ScreenGui?)
	if _tipFrame then return end

	local targetGui = parentGui
	if not targetGui then
		local lp = Players.LocalPlayer
		if lp then
			targetGui = lp:FindFirstChildOfClass("PlayerGui")
		end
	end

	if not targetGui then
		local ok, core = pcall(function() return game:GetService("CoreGui") end)
		if ok and core then
			local g = Instance.new("ScreenGui")
			g.Name = "DeliriumTooltips"
			g.ResetOnSpawn = false
			g.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
			g.IgnoreGuiInset = true
			pcall(function() g.DisplayOrder = 9999 end)
			g.Parent = core
			targetGui = g
		end
	end

	if not targetGui then return end
	_gui = targetGui

	local tip = Instance.new("Frame")
	tip.Name                   = "FloatingTooltip"
	tip.AnchorPoint            = Vector2.new(0, 0)
	tip.Position               = UDim2.fromOffset(0, 0)
	tip.Size                   = UDim2.fromOffset(0, 0)
	tip.AutomaticSize          = Enum.AutomaticSize.XY
	tip.BackgroundColor3       = Color3.fromHex("#141414")
	tip.BackgroundTransparency = 1
	tip.BorderSizePixel        = 0
	tip.ZIndex                 = 10000
	tip.Visible                = false
	tip.Parent                 = targetGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, Theme.Radius.Small + 1)
	corner.Parent = tip

	local stroke = Instance.new("UIStroke")
	stroke.Color           = Theme.Colors.Border
	stroke.Thickness       = 1
	stroke.Transparency    = 1
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent          = tip
	_tipStroke             = stroke

	local scale = Instance.new("UIScale")
	scale.Scale  = 0.90
	scale.Parent = tip
	_tipScale    = scale

	local pad = Instance.new("UIPadding")
	pad.PaddingTop    = UDim.new(0, 5)
	pad.PaddingBottom = UDim.new(0, 5)
	pad.PaddingLeft   = UDim.new(0, 8)
	pad.PaddingRight  = UDim.new(0, 8)
	pad.Parent        = tip

	local lbl = Instance.new("TextLabel")
	lbl.Name                   = "TooltipLabel"
	lbl.AutomaticSize          = Enum.AutomaticSize.XY
	lbl.Size                   = UDim2.fromOffset(0, 0)
	lbl.BackgroundTransparency = 1
	lbl.Font                   = Theme.Font.Body
	lbl.Text                   = ""
	lbl.TextSize               = Theme.TextSize.Small
	lbl.TextColor3             = Theme.Colors.TextPrimary
	lbl.TextTransparency       = 1
	lbl.TextXAlignment         = Enum.TextXAlignment.Left
	lbl.TextYAlignment         = Enum.TextYAlignment.Center
	lbl.RichText               = true
	lbl.ZIndex                 = 10001
	lbl.Parent                 = tip
	_tipLabel                  = lbl

	_tipFrame = tip
end

local function updatePosition(customPos: Vector2?)
	if not _tipFrame or not _tipFrame.Visible then return end
	local pos = customPos or UserInputService:GetMouseLocation()

	local cam = workspace.CurrentCamera
	local vp = if cam then cam.ViewportSize else Vector2.new(1024, 768)

	local tipW = _tipFrame.AbsoluteSize.X
	local tipH = _tipFrame.AbsoluteSize.Y

	local targetX = pos.X + 12
	local targetY = pos.Y + 14

	-- Flip horizontally if overflow
	if targetX + tipW > vp.X - 8 then
		targetX = pos.X - tipW - 8
	end

	-- Flip vertically if overflow
	if targetY + tipH > vp.Y - 8 then
		targetY = pos.Y - tipH - 8
	end

	targetX = math.clamp(targetX, 4, math.max(4, vp.X - tipW - 4))
	targetY = math.clamp(targetY, 4, math.max(4, vp.Y - tipH - 4))

	_tipFrame.Position = UDim2.fromOffset(targetX, targetY)
end

local function hideTooltip()
	if _showThread then
		pcall(task.cancel, _showThread)
		_showThread = nil
	end
	if not _isShown or not _tipFrame then return end
	_isShown = false
	_activeTarget = nil

	if _tipScale then
		TweenService:Create(_tipScale, TWEEN_OUT, { Scale = 0.90 }):Play()
	end
	if _tipFrame then
		TweenService:Create(_tipFrame, TWEEN_OUT, { BackgroundTransparency = 1 }):Play()
	end
	if _tipStroke then
		TweenService:Create(_tipStroke, TWEEN_OUT, { Transparency = 1 }):Play()
	end
	if _tipLabel then
		TweenService:Create(_tipLabel, TWEEN_OUT, { TextTransparency = 1 }):Play()
	end

	_hideThread = task.delay(TWEEN_OUT.Time + 0.02, function()
		if not _isShown and _tipFrame then
			_tipFrame.Visible = false
		end
	end)
end

local function showTooltip(target: GuiObject, text: string, pos: Vector2?, delaySec: number?)
	if _hideThread then
		pcall(task.cancel, _hideThread)
		_hideThread = nil
	end

	ensureGui()
	if not _tipFrame or not _tipLabel or not _tipScale or not _tipStroke then return end

	_activeTarget = target
	_currentText  = text
	_tipLabel.Text = text

	local delayTime = delaySec or 0.28

	if _showThread then pcall(task.cancel, _showThread) end
	_showThread = task.delay(delayTime, function()
		if _activeTarget ~= target then return end
		_isShown = true
		_tipFrame.Visible = true
		updatePosition(pos)

		TweenService:Create(_tipScale,  TWEEN_IN, { Scale = 1 }):Play()
		TweenService:Create(_tipFrame,  TWEEN_IN, { BackgroundTransparency = 0.05 }):Play()
		TweenService:Create(_tipStroke, TWEEN_IN, { Transparency = 0.3 }):Play()
		TweenService:Create(_tipLabel,  TWEEN_IN, { TextTransparency = 0 }):Play()
	end)
end

local Tooltip = {}

function Tooltip.bind(target: GuiObject, text: string, options: { Delay: number?, ParentGui: ScreenGui? }?): () -> ()
	if not text or #text == 0 then return function() end end

	local delaySec = options and options.Delay
	if options and options.ParentGui then
		ensureGui(options.ParentGui)
	end

	local enterConn = target.MouseEnter:Connect(function()
		showTooltip(target, text, nil, delaySec)
	end)

	local moveConn = target.MouseMoved:Connect(function()
		if _isShown and _activeTarget == target then
			updatePosition()
		end
	end)

	local leaveConn = target.MouseLeave:Connect(function()
		if _activeTarget == target then
			hideTooltip()
		end
	end)

	-- Mobile touch support: Tap / touch begin shows tooltip temporarily
	local touchConn = target.InputBegan:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.Touch then
			local pos = Vector2.new(input.Position.X, input.Position.Y)
			showTooltip(target, text, pos, 0.05)
			task.delay(2.0, function()
				if _activeTarget == target then
					hideTooltip()
				end
			end)
		end
	end)

	return function()
		enterConn:Disconnect()
		moveConn:Disconnect()
		leaveConn:Disconnect()
		touchConn:Disconnect()
		if _activeTarget == target then
			hideTooltip()
		end
	end
end

return Tooltip
