--!strict

local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Maid         = require(script.Parent.Parent.Utils.Maid)
local Theme        = require(script.Parent.Parent.Theme)
local SmoothScroll = require(script.Parent.Parent.Utils.SmoothScroll)

local TWEEN_MODAL_IN  = TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local TWEEN_MODAL_OUT = TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
local TWEEN_DIM_IN    = TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local TWEEN_DIM_OUT   = TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
local TWEEN_FLASH     = TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

local SEARCH_W    = 360
local SEARCH_MAX_H = 260
local HEADER_H    = 42
local ROW_H       = 38

export type SearchItem = {
	Label:     string,
	TabName:   string,
	TabIdx:    number,
	GroupName: string?,
	TypeName:  string,
	Comp:      any,
	Frame:     GuiObject,
}

export type SearchImpl = {
	Register:  (self: SearchImpl, item: SearchItem) -> (),
	Open:      (self: SearchImpl) -> (),
	Close:     (self: SearchImpl) -> (),
	Toggle:    (self: SearchImpl) -> (),
	Destroy:   (self: SearchImpl) -> (),
}

local Search = {} :: { __index: any }
Search.__index = Search

function Search.new(window: any, overlayGui: ScreenGui, parentCanvas: Frame, windowMaid: any): SearchImpl
	local self    = setmetatable({}, Search) :: any
	self._maid    = Maid.new()
	windowMaid:GiveTask(self._maid)

	self._win     = window
	self._gui     = overlayGui
	self._canvas  = parentCanvas
	self._items   = {} :: { SearchItem }
	self._isOpen  = false
	self._itemMaid = Maid.new()
	self._maid:GiveTask(self._itemMaid)

	-- ── Search Modal Root ─────────────────────────────────────────────────────
	local modal                  = Instance.new("Frame")
	modal.Name                   = "SearchModal"
	modal.AnchorPoint            = Vector2.new(0.5, 0.5)
	modal.Position               = UDim2.fromScale(0.5, 0.45)
	modal.Size                   = UDim2.fromOffset(SEARCH_W, HEADER_H + 8)
	modal.BackgroundColor3       = Theme.Colors.Surface
	modal.BorderSizePixel        = 0
	modal.ZIndex                 = 500
	modal.Visible                = false
	modal.ClipsDescendants       = true
	self._maid:GiveTask(modal)
	self._modal = modal

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, Theme.Radius.Medium)
	corner.Parent = modal

	local stroke = Instance.new("UIStroke")
	stroke.Color           = Theme.Colors.Border
	stroke.Thickness       = 1
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent          = modal
	self._stroke           = stroke

	local scale = Instance.new("UIScale")
	scale.Scale  = 0.90
	scale.Parent = modal
	self._scale  = scale

	-- ── Header (Search Input Bar) ─────────────────────────────────────────────
	local header                  = Instance.new("Frame")
	header.Name                   = "SearchHeader"
	header.Size                   = UDim2.new(1, 0, 0, HEADER_H)
	header.BackgroundColor3       = Theme.Colors.TitleBar
	header.BorderSizePixel        = 0
	header.ZIndex                 = 501
	header.Parent                 = modal

	local headerPad = Instance.new("UIPadding")
	headerPad.PaddingLeft  = UDim.new(0, 12)
	headerPad.PaddingRight = UDim.new(0, 10)
	headerPad.Parent       = header

	local searchIcon                  = Instance.new("TextLabel")
	searchIcon.Name                   = "SearchIcon"
	searchIcon.AnchorPoint            = Vector2.new(0, 0.5)
	searchIcon.Position               = UDim2.new(0, 0, 0.5, 0)
	searchIcon.Size                   = UDim2.fromOffset(18, 18)
	searchIcon.BackgroundTransparency = 1
	searchIcon.Font                   = Theme.Font.Body
	searchIcon.Text                   = "⊙"
	searchIcon.TextSize               = 14
	searchIcon.TextColor3             = Theme.Colors.Accent
	searchIcon.ZIndex                 = 502
	searchIcon.Parent                 = header

	local closeBtn                  = Instance.new("TextButton")
	closeBtn.Name                   = "CloseBtn"
	closeBtn.AnchorPoint            = Vector2.new(1, 0.5)
	closeBtn.Position               = UDim2.new(1, 0, 0.5, 0)
	closeBtn.Size                   = UDim2.fromOffset(20, 20)
	closeBtn.BackgroundColor3       = Theme.Colors.SurfaceHover
	closeBtn.BorderSizePixel        = 0
	closeBtn.Font                   = Theme.Font.Body
	closeBtn.Text                   = "×"
	closeBtn.TextSize               = 14
	closeBtn.TextColor3             = Theme.Colors.TextSecondary
	closeBtn.AutoButtonColor        = false
	closeBtn.ZIndex                 = 502
	closeBtn.Parent                 = header
	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 4)
	btnCorner.Parent = closeBtn

	local input                  = Instance.new("TextBox")
	input.Name                   = "SearchInput"
	input.Position               = UDim2.fromOffset(24, 0)
	input.Size                   = UDim2.new(1, -52, 1, 0)
	input.BackgroundTransparency = 1
	input.BorderSizePixel        = 0
	input.Font                   = Theme.Font.Body
	input.Text                   = ""
	input.PlaceholderText        = "Search features, commands, tabs..."
	input.PlaceholderColor3      = Theme.Colors.TextDisabled
	input.TextSize               = Theme.TextSize.Body
	input.TextColor3             = Theme.Colors.TextPrimary
	input.TextXAlignment         = Enum.TextXAlignment.Left
	input.ClearTextOnFocus       = false
	input.ZIndex                 = 502
	input.Parent                 = header
	self._input                  = input

	local sep             = Instance.new("Frame")
	sep.Name              = "Separator"
	sep.Size              = UDim2.new(1, 0, 0, 1)
	sep.Position          = UDim2.fromOffset(0, HEADER_H)
	sep.BackgroundColor3  = Theme.Colors.Border
	sep.BorderSizePixel   = 0
	sep.ZIndex            = 502
	sep.Parent            = modal

	-- ── Results ScrollingFrame ────────────────────────────────────────────────
	local scroll                  = Instance.new("ScrollingFrame")
	scroll.Name                   = "ResultsScroll"
	scroll.Position               = UDim2.fromOffset(0, HEADER_H + 1)
	scroll.Size                   = UDim2.new(1, 0, 1, -(HEADER_H + 1))
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel        = 0
	scroll.ScrollBarThickness     = 2
	scroll.ScrollBarImageColor3   = Theme.Colors.Border
	scroll.CanvasSize             = UDim2.fromOffset(0, 0)
	scroll.AutomaticCanvasSize    = Enum.AutomaticSize.Y
	scroll.ClipsDescendants       = true
	scroll.ZIndex                 = 501
	scroll.Parent                 = modal
	self._scroll                  = scroll

	local listLayout               = Instance.new("UIListLayout")
	listLayout.FillDirection       = Enum.FillDirection.Vertical
	listLayout.SortOrder           = Enum.SortOrder.LayoutOrder
	listLayout.Padding             = UDim.new(0, 2)
	listLayout.Parent              = scroll

	local scrollPad         = Instance.new("UIPadding")
	scrollPad.PaddingTop    = UDim.new(0, 6)
	scrollPad.PaddingBottom = UDim.new(0, 6)
	scrollPad.PaddingLeft   = UDim.new(0, 8)
	scrollPad.PaddingRight  = UDim.new(0, 8)
	scrollPad.Parent        = scroll

	-- ── Backdrop Dim ──────────────────────────────────────────────────────────
	local backdrop                  = Instance.new("TextButton")
	backdrop.Name                   = "SearchBackdrop"
	backdrop.Size                   = UDim2.fromScale(1, 1)
	backdrop.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
	backdrop.BackgroundTransparency = 1
	backdrop.BorderSizePixel        = 0
	backdrop.Text                   = ""
	backdrop.AutoButtonColor        = false
	backdrop.ZIndex                 = 499
	backdrop.Visible                = false
	self._maid:GiveTask(backdrop)
	self._backdrop                  = backdrop

	-- ── Result builder ────────────────────────────────────────────────────────
	local function rebuildResults(query: string)
		self._itemMaid:DoCleaning()
		for _, child in ipairs(scroll:GetChildren()) do
			if child:IsA("Frame") then child:Destroy() end
		end

		local q = query:lower():gsub("%s+", " ")
		local matches = {}
		for _, it in ipairs(self._items) do
			if #q == 0 or it.Label:lower():find(q, 1, true) or it.TabName:lower():find(q, 1, true) or (it.GroupName and it.GroupName:lower():find(q, 1, true)) then
				table.insert(matches, it)
			end
		end

		local totalCount = #matches
		local contentH = math.min(totalCount * (ROW_H + 2) + 12, SEARCH_MAX_H)
		local targetH = HEADER_H + 1 + (if totalCount == 0 then 48 else contentH)

		local cam = workspace.CurrentCamera
		local vp = if cam then cam.ViewportSize else Vector2.new(1024, 768)
		local modalW = math.min(SEARCH_W, vp.X - 24)

		modal.Size = UDim2.fromOffset(modalW, targetH)

		if totalCount == 0 then
			local emptyLbl                  = Instance.new("TextLabel")
			emptyLbl.Name                   = "EmptyLabel"
			emptyLbl.Size                   = UDim2.new(1, 0, 0, 40)
			emptyLbl.BackgroundTransparency = 1
			emptyLbl.Font                   = Theme.Font.Body
			emptyLbl.Text                   = "No features found"
			emptyLbl.TextSize               = Theme.TextSize.Small
			emptyLbl.TextColor3             = Theme.Colors.TextDisabled
			emptyLbl.ZIndex                 = 503
			emptyLbl.Parent                 = scroll
			return
		end

		for i, item in ipairs(matches) do
			local row                  = Instance.new("Frame")
			row.Name                   = "Result_" .. i
			row.Size                   = UDim2.new(1, 0, 0, ROW_H)
			row.BackgroundColor3       = Theme.Colors.SurfaceHover
			row.BackgroundTransparency = 1
			row.BorderSizePixel        = 0
			row.LayoutOrder            = i
			row.ZIndex                 = 503
			row.Parent                 = scroll

			local rowCorner = Instance.new("UICorner")
			rowCorner.CornerRadius = UDim.new(0, 6)
			rowCorner.Parent = row

			local rowPad = Instance.new("UIPadding")
			rowPad.PaddingLeft  = UDim.new(0, 8)
			rowPad.PaddingRight = UDim.new(0, 8)
			rowPad.Parent       = row

			-- Left: Title + Breadcrumb
			local labelCol                  = Instance.new("Frame")
			labelCol.Name                   = "LabelCol"
			labelCol.Size                   = UDim2.new(1, -70, 1, 0)
			labelCol.BackgroundTransparency = 1
			labelCol.BorderSizePixel        = 0
			labelCol.ZIndex                 = 504
			labelCol.Parent                 = row

			local labelLayout               = Instance.new("UIListLayout")
			labelLayout.FillDirection       = Enum.FillDirection.Vertical
			labelLayout.VerticalAlignment   = Enum.VerticalAlignment.Center
			labelLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
			labelLayout.Padding             = UDim.new(0, 1)
			labelLayout.Parent              = labelCol

			local titleLbl                  = Instance.new("TextLabel")
			titleLbl.Name                   = "ItemTitle"
			titleLbl.Size                   = UDim2.new(1, 0, 0, 15)
			titleLbl.BackgroundTransparency = 1
			titleLbl.Font                   = Theme.Font.Body
			titleLbl.Text                   = item.Label
			titleLbl.TextSize               = Theme.TextSize.Body
			titleLbl.TextColor3             = Theme.Colors.TextPrimary
			titleLbl.TextXAlignment         = Enum.TextXAlignment.Left
			titleLbl.TextTruncate           = Enum.TextTruncate.AtEnd
			titleLbl.ZIndex                 = 505
			titleLbl.Parent                 = labelCol

			local breadcrumb = item.TabName .. (if item.GroupName then "  ›  " .. item.GroupName else "")
			local pathLbl                  = Instance.new("TextLabel")
			pathLbl.Name                   = "ItemPath"
			pathLbl.Size                   = UDim2.new(1, 0, 0, 12)
			pathLbl.BackgroundTransparency = 1
			pathLbl.Font                   = Theme.Font.Subtitle
			pathLbl.Text                   = breadcrumb
			pathLbl.TextSize               = 10
			pathLbl.TextColor3             = Theme.Colors.TextSecondary
			pathLbl.TextXAlignment         = Enum.TextXAlignment.Left
			pathLbl.TextTruncate           = Enum.TextTruncate.AtEnd
			pathLbl.ZIndex                 = 505
			pathLbl.Parent                 = labelCol

			-- Right: Type Badge pill
			local badge                  = Instance.new("Frame")
			badge.Name                   = "TypeBadge"
			badge.AnchorPoint            = Vector2.new(1, 0.5)
			badge.Position               = UDim2.new(1, 0, 0.5, 0)
			badge.Size                   = UDim2.fromOffset(58, 20)
			badge.BackgroundColor3       = Theme.Colors.AccentMuted
			badge.BorderSizePixel        = 0
			badge.ZIndex                 = 504
			badge.Parent                 = row
			local badgeCorner = Instance.new("UICorner")
			badgeCorner.CornerRadius = UDim.new(0, 4)
			badgeCorner.Parent = badge

			local badgeLbl                  = Instance.new("TextLabel")
			badgeLbl.Size                   = UDim2.fromScale(1, 1)
			badgeLbl.BackgroundTransparency = 1
			badgeLbl.Font                   = Theme.Font.Subtitle
			badgeLbl.Text                   = item.TypeName
			badgeLbl.TextSize               = 9
			badgeLbl.TextColor3             = Theme.Colors.Accent
			badgeLbl.TextXAlignment         = Enum.TextXAlignment.Center
			badgeLbl.ZIndex                 = 505
			badgeLbl.Parent                 = badge

			-- Hit button
			local hitBtn                  = Instance.new("TextButton")
			hitBtn.Size                   = UDim2.fromScale(1, 1)
			hitBtn.BackgroundTransparency = 1
			hitBtn.Text                   = ""
			hitBtn.AutoButtonColor        = false
			hitBtn.ZIndex                 = 506
			hitBtn.Parent                 = row

			self._itemMaid:GiveTask(hitBtn.MouseEnter:Connect(function()
				TweenService:Create(row, TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
					BackgroundTransparency = 0.5,
				}):Play()
			end))
			self._itemMaid:GiveTask(hitBtn.MouseLeave:Connect(function()
				TweenService:Create(row, TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
					BackgroundTransparency = 1,
				}):Play()
			end))

			self._itemMaid:GiveTask(hitBtn.MouseButton1Click:Connect(function()
				self:Close()
				-- Switch to tab
				if self._win._activateTab and item.TabIdx > 0 then
					self._win:_activateTab(item.TabIdx)
				end

				-- Scroll to element & flash highlight
				task.defer(function()
					local f = item.Frame
					if not f or not f.Parent then return end
					local pane = f:FindFirstAncestorWhichIsA("ScrollingFrame")
					if pane then
						local relY = f.AbsolutePosition.Y - pane.AbsolutePosition.Y + pane.CanvasPosition.Y
						local paneH = pane.AbsoluteSize.Y
						local targetScroll = math.clamp(relY - paneH * 0.35, 0, math.max(0, pane.AbsoluteCanvasSize.Y - paneH))
						TweenService:Create(pane, TweenInfo.new(0.35, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {
							CanvasPosition = Vector2.new(0, targetScroll),
						}):Play()
					end

					-- Highlight flash
					local stroke_ = f:FindFirstChildOfClass("UIStroke") or f:FindFirstChild("Inner", true) and (f:FindFirstChild("Inner", true) :: Instance):FindFirstChildOfClass("UIStroke")
					if stroke_ then
						local origCol = stroke_.Color
						TweenService:Create(stroke_, TWEEN_FLASH, { Color = Theme.Colors.AccentActive }):Play()
						task.delay(0.6, function()
							if stroke_.Parent then
								TweenService:Create(stroke_, TWEEN_FLASH, { Color = origCol }):Play()
							end
						end)
					end
				end)
			end))
		end
	end

	self._maid:GiveTask(input:GetPropertyChangedSignal("Text"):Connect(function()
		rebuildResults(input.Text)
	end))

	-- ── Backdrop & Close Bindings ─────────────────────────────────────────────
	self._maid:GiveTask(closeBtn.MouseButton1Click:Connect(function()
		self:Close()
	end))
	self._maid:GiveTask(backdrop.MouseButton1Click:Connect(function()
		self:Close()
	end))

	self._maid:GiveTask(UserInputService.InputBegan:Connect(function(inp: InputObject, gpe: boolean)
		if gpe and not input:IsFocused() then return end
		if inp.KeyCode == Enum.KeyCode.Escape and self._isOpen then
			self:Close()
		elseif inp.KeyCode == Enum.KeyCode.F and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
			self:Toggle()
		end
	end))

	self._rebuildResults = rebuildResults
	return self
end

function Search:Register(item: SearchItem)
	table.insert(self._items, item)
end

function Search:Open()
	if self._isOpen then return end
	self._isOpen = true

	local cam = workspace.CurrentCamera
	local vp = if cam then cam.ViewportSize else Vector2.new(1024, 768)
	local modalW = math.min(SEARCH_W, vp.X - 24)

	self._backdrop.Parent = self._gui
	self._backdrop.Visible = true
	self._modal.Parent = self._gui
	self._modal.Size   = UDim2.fromOffset(modalW, HEADER_H + 8)
	self._modal.Visible = true

	self._scale.Scale = 0.88
	self._modal.BackgroundTransparency = 1
	self._stroke.Transparency = 1

	TweenService:Create(self._backdrop, TWEEN_DIM_IN, { BackgroundTransparency = 0.55 }):Play()
	TweenService:Create(self._scale,    TWEEN_MODAL_IN, { Scale = 1 }):Play()
	TweenService:Create(self._modal,    TWEEN_MODAL_IN, { BackgroundTransparency = 0 }):Play()
	TweenService:Create(self._stroke,   TWEEN_MODAL_IN, { Transparency = 0 }):Play()

	self._input.Text = ""
	self._input:CaptureFocus()
	self._rebuildResults("")
end

function Search:Close()
	if not self._isOpen then return end
	self._isOpen = false

	TweenService:Create(self._backdrop, TWEEN_DIM_OUT, { BackgroundTransparency = 1 }):Play()
	TweenService:Create(self._scale,    TWEEN_MODAL_OUT, { Scale = 0.88 }):Play()
	TweenService:Create(self._modal,    TWEEN_MODAL_OUT, { BackgroundTransparency = 1 }):Play()
	TweenService:Create(self._stroke,   TWEEN_MODAL_OUT, { Transparency = 1 }):Play()

	task.delay(TWEEN_MODAL_OUT.Time + 0.02, function()
		if not self._isOpen then
			self._modal.Visible = false
			self._backdrop.Visible = false
			self._modal.Parent = nil
			self._backdrop.Parent = nil
		end
	end)
end

function Search:Toggle()
	if self._isOpen then
		self:Close()
	else
		self:Open()
	end
end

function Search:Destroy()
	self._maid:DoCleaning()
end

return Search
