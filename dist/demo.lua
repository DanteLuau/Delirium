local ImportGlobals
local ClosureBindings = {
    function()
        local wax, script, require = ImportGlobals(1)
        local ImportGlobals

        return (function(...)
            local types = require(script.types)
            local flags = require(script.utility.flags)
            local variables = require(script.utility.variables)
            local constants = require(script.utility.constants)
            local icons = require(script.utility.icons)
            local mediaService = require(script.utility.mediaService)
            local imageCache = require(script.utility.imageCache)
            local imageUtil = require(script.utility.image)
            local saveManager = require(script.utility.saveManager)
            local tasks = require(script.utility.tasks)
            local keySystemModule = require(script.components.keySystem)

            export type Theme = types.Theme
            export type WindowProps = types.WindowProps
            export type TabProps = types.TabProps
            export type SectionProps = types.SectionProps
            export type LabelProps = types.LabelProps
            export type ButtonProps = types.ButtonProps
            export type ToggleProps = types.ToggleProps
            export type SliderProps = types.SliderProps
            export type DropdownProps = types.DropdownProps
            export type InputProps = types.InputProps
            export type KeybindProps = types.KeybindProps
            export type ColorPickerProps = types.ColorPickerProps
            export type NotifyProps = types.NotifyProps
            export type TextProps = types.TextProps
            export type DividerProps = types.DividerProps
            export type ProgressProps = types.ProgressProps
            export type StatProps = types.StatProps
            export type ConsoleProps = types.ConsoleProps
            export type GroupProps = types.GroupProps
            export type TagProps = types.TagProps
            export type ToastProps = types.ToastProps
            export type TaskEntry = types.TaskEntry
            export type TaskContext = types.TaskContext
            export type StartupOptions = types.StartupOptions
            export type KeySystemConfig = types.KeySystemConfig
            export type KeySystem = types.KeySystem
            export type Window = types.Window
            export type Tab = types.Tab
            export type Section = types.Section
            export type Label = types.Label
            export type Button = types.Button
            export type Toggle = types.Toggle
            export type Slider = types.Slider
            export type Dropdown = types.Dropdown
            export type Input = types.Input
            export type Keybind = types.Keybind
            export type ColorPicker = types.ColorPicker
            export type Text = types.Text
            export type Divider = types.Divider
            export type Progress = types.Progress
            export type Stat = types.Stat
            export type Console = types.Console
            export type Group = types.Group
            export type Tag = types.Tag
            export type Delirium = types.Delirium
            type WindowModule = {new: (types.WindowProps) -> types.Window}

            local delirium = {}::Delirium

            delirium.Flags = flags::any
            delirium.Icons = icons::any
            delirium.NebulaIcons = icons::any
            delirium.MediaService = mediaService::any
            delirium.SaveManager = saveManager::any
            delirium.Tasks = tasks::any
            delirium.KeySystem = keySystemModule::any
            delirium.LoadingScreen = require(script.components.loadingScreen)::any
            delirium._imageCache = imageCache::any
            delirium._image = imageUtil::any

            function delirium:CreateWindow(props: types.WindowProps): types.Window
                local made, result = pcall(function()
                    return (require(script.components.window)::WindowModule).new(props)
                end)

                if not made then
                    error('[Delirium] CreateWindow failed: ' .. tostring(result), 2)
                end

                local window = result::types.Window

                return window
            end
            function delirium:Startup(config: string | types.StartupOptions, callback: (window:types.Window, ctx:any?) -> ()): types.Window
                local title = 'Delirium'
                local subtitle = nil::string?
                local icon = nil::(string | number)?
                local accent = nil::Color3?
                local theme = nil::types.Theme?
                local keybind = nil::(EnumItem | string)?
                local keepOnScreen = true
                local gestureBar = nil::boolean?
                local tabsHeader = nil::string?
                local loadCfg: types.LoadingConfig = {}
                local taskList: {types.TaskEntry}? = nil

                if type(config) == 'table' then
                    title = config.title or config.name or 'Delirium'
                    subtitle = config.subtitle
                    icon = config.icon
                    accent = config.accent
                    theme = config.theme
                    keybind = config.keybind
                    keepOnScreen = if config.keepOnScreen ~= nil then config.keepOnScreen else true
                    gestureBar = config.gestureBar
                    tabsHeader = config.tabsHeader

                    if config.loading then
                        loadCfg = config.loading
                    end

                    taskList = config.tasks
                else
                    title = tostring(config or 'Delirium')
                end

                local keySystemCfg = if type(config) == 'table'then config.keySystem else nil

                if not taskList or #taskList == 0 then
                    taskList = {
                        delirium.Tasks.LoadSave(),
                        delirium.Tasks.CheckExecutor(),
                    }
                end

                local function startFlow()
                    local ls = delirium.LoadingScreen.new({
                        title = title,
                        subtitle = subtitle,
                        icon = icon,
                        accent = accent,
                        showProgress = if loadCfg.showProgress ~= nil then loadCfg.showProgress else true,
                        minDuration = loadCfg.minDuration or (constants.loading and constants.loading.minDuration) or 0.6,
                        allowCancel = loadCfg.allowCancel == true,
                    })

                    for _, t in ipairs(taskList)do
                        (ls::any):Task(t.name, t.weight, t.run)
                    end

                    task.spawn(function()
                        local ok, err = (ls::any):Run({
                            minDuration = loadCfg.minDuration,
                        })

                        if not ok and err == 'cancelled' then
                            return
                        end

                        local window = delirium:CreateWindow({
                            name = title,
                            subtitle = subtitle,
                            icon = icon,
                            theme = theme,
                            keybind = keybind,
                            keepOnScreen = keepOnScreen,
                            gestureBar = gestureBar,
                            tabsHeader = tabsHeader,
                        })
                        local cbOk, cbErr = pcall(callback, window, ls)

                        if not cbOk then
                            warn('[Delirium] Startup callback error: ' .. tostring(cbErr))
                        end

                        (ls::any):Morph(window)
                    end)
                end

                if keySystemCfg then
                    local ks = delirium.KeySystem.new(keySystemCfg)

                    ks:Prompt(function(ok, _key)
                        if ok then
                            startFlow()
                        else
                            warn(
[[[Delirium] Startup cancelled: Key validation was dismissed or failed.]])
                        end
                    end)
                else
                    startFlow()
                end

                return nil::any
            end

            export type BootOptions = types.BootOptions

            function delirium:Boot(
                config: string | types.BootOptions,
                callback: (window:types.Window, loadingScreen:any) -> (),
                messages: {string}?
            )
                local title = 'Delirium'
                local sub: string? = nil
                local ic: (string | number)? = nil
                local acc: Color3? = nil
                local th: types.Theme? = nil
                local customTasks: {types.TaskEntry}? = nil
                local rawMsgs: {string}? = messages

                if type(config) == 'table' then
                    title = config.title or config.name or 'Delirium'
                    sub = config.subtitle
                    ic = config.icon
                    acc = config.accent
                    th = config.theme
                    customTasks = config.tasks
                    rawMsgs = config.messages or messages
                else
                    title = tostring(config or 'Delirium')
                end

                local startupTasks: {types.TaskEntry} = {}

                if customTasks and #customTasks > 0 then
                    startupTasks = customTasks
                elseif rawMsgs and #rawMsgs > 0 then
                    warn(
[[[Delirium] Boot with messages array is deprecated. Use Delirium:Startup with Task presets instead.]])

                    for _, m in ipairs(rawMsgs)do
                        table.insert(startupTasks, {
                            name = m,
                            weight = 1,
                            run = function(_ctx)
                                task.wait(0.2)
                            end,
                        })
                    end
                else
                    startupTasks = {
                        delirium.Tasks.LoadSave(),
                        delirium.Tasks.CheckExecutor(),
                    }
                end

                return delirium:Startup({
                    title = title,
                    subtitle = sub,
                    icon = ic,
                    accent = acc,
                    theme = th,
                    tasks = startupTasks,
                }, callback)
            end

            return delirium
        end)()
    end,
    [59] = function()
        local wax, script, require = ImportGlobals(59)
        local ImportGlobals

        return (function(...)
            local services = require(script.Parent.services)

            export type RuntimeState = {secureMode: boolean, coreGui: CoreGui, workspace: Workspace, runService: RunService, userInputService: UserInputService, tweenService: TweenService, httpService: HttpService, textService: TextService, contextActionService: ContextActionService, replicatedStorage: ReplicatedStorage, localPlayer: Player?, guiContainer: Instance}

            local runtime = {}::RuntimeState

            runtime.secureMode = (function(): boolean
                if typeof(getgenv) ~= 'function' then
                    return false
                end

                local ok, val = pcall(function()
                    return getgenv().DELIRIUM_SECURE
                end)

                return ok and val == true
            end)()
            runtime.coreGui = services.getService('CoreGui')::CoreGui
            runtime.workspace = services.getService('Workspace')::Workspace
            runtime.runService = services.getService('RunService')::RunService
            runtime.userInputService = services.getService('UserInputService')::UserInputService
            runtime.tweenService = services.getService('TweenService')::TweenService
            runtime.httpService = services.getService('HttpService')::HttpService
            runtime.textService = services.getService('TextService')::TextService
            runtime.contextActionService = services.getService('ContextActionService')::ContextActionService
            runtime.replicatedStorage = services.getService('ReplicatedStorage')::ReplicatedStorage
            runtime.players = services.getService('Players')::Players
            runtime.marketplaceService = services.getService('MarketplaceService')::MarketplaceService
            runtime.stats = services.getService('Stats')::Stats
            runtime.localPlayer = runtime.players.LocalPlayer
            runtime.isTouchOnly = (function(): boolean
                local uis = runtime.userInputService

                if not uis.TouchEnabled then
                    return false
                end
                if uis.KeyboardEnabled then
                    return false
                end

                local cam = runtime.workspace.CurrentCamera

                if cam and cam.ViewportSize.X < 600 then
                    return true
                end

                return cam ~= nil and cam.ViewportSize.X < 800
            end)()::boolean
            runtime.guiContainer = (function(): Instance
                if runtime.runService:IsStudio() then
                    local lp = runtime.localPlayer or (services.getService('Players')::Players).LocalPlayer

                    if lp then
                        local pg = lp:FindFirstChildOfClass('PlayerGui') or lp:FindFirstChild('PlayerGui')

                        if pg then
                            return pg
                        end
                    end
                end
                if typeof(gethui) == 'function' then
                    local ok, container = pcall(gethui)

                    if ok and container then
                        return container::Instance
                    end
                end

                local coreGui = runtime.coreGui

                if coreGui then
                    local ok = pcall(function()
                        local test = Instance.new('Folder')

                        test.Parent = coreGui

                        test:Destroy()
                    end)

                    if ok then
                        return coreGui
                    end
                end

                local lp = runtime.localPlayer or (services.getService('Players')::Players).LocalPlayer

                if lp then
                    local pg = lp:FindFirstChildOfClass('PlayerGui') or lp:WaitForChild('PlayerGui', 5)

                    if pg then
                        return pg
                    end
                end

                return coreGui
            end)()

            return runtime
        end)()
    end,
    [14] = function()
        local wax, script, require = ImportGlobals(14)
        local ImportGlobals

        return (function(...)
            local constants = require(script.Parent.Parent.utility.constants)
            local element = require(script.Parent.Parent.utility.element)
            local tween = require(script.Parent.Parent.utility.tween)

            export type LabelProps = {text: string?, richText: boolean?, textSize: number?, textColor: Color3?}
            export type Label = {_frame: Frame, Set: (self:Label, text:string) -> (), Destroy: (self:Label) -> ()}

            local Label = {}

            Label.__index = Label

            function Label.new(
                props: LabelProps,
                theme: {[string]: any},
                parent: Instance
            ): Label
                local text = props.text or ''
                local richText = props.richText ~= false and true
                local textSize = props.textSize or 13
                local textColor = props.textColor or theme.ContentColor or Color3.fromRGB(220, 215, 240)
                local container = Instance.new('Frame')

                container.Name = 'Label'
                container.BackgroundTransparency = 1
                container.Size = UDim2.new(1, 0, 0, 0)
                container.AutomaticSize = Enum.AutomaticSize.Y
                container.LayoutOrder = 0
                container.Parent = parent

                local padding = Instance.new('UIPadding')

                padding.PaddingLeft = UDim.new(0, 4)
                padding.PaddingRight = UDim.new(0, 4)
                padding.PaddingTop = UDim.new(0, 4)
                padding.PaddingBottom = UDim.new(0, 4)
                padding.Parent = container

                local label = Instance.new('TextLabel')

                label.Name = 'Text'
                label.Size = UDim2.new(1, 0, 0, 0)
                label.AutomaticSize = Enum.AutomaticSize.Y
                label.BackgroundTransparency = 1
                label.Text = text
                label.RichText = richText
                label.TextColor3 = textColor
                label.TextSize = textSize
                label.FontFace = theme.Font or constants.DEFAULT_FONT
                label.TextWrapped = true
                label.TextXAlignment = Enum.TextXAlignment.Left
                label.Parent = container

                local self = setmetatable({}, Label)::Label

                self._frame = container;
                (self::any)._label = label;
                (self::any)._themeUnsub = element.subscribeTheme(container, {
                    title = label,
                    titleFont = constants.DEFAULT_FONT,
                    extra = function(t)
                        if props.textColor then
                            label.TextColor3 = props.textColor
                        else
                            label.TextColor3 = t.ContentColor or Color3.fromRGB(220, 215, 240)
                        end
                    end,
                })

                return self
            end
            function Label:Set(text: string)
                local label: TextLabel = (self::any)._label

                label.Text = text
            end
            function Label:_setShown(shown: boolean, animate: boolean?)
                local s = self::any
                local info = if animate ~= false then constants.tweenNormal else nil
                local textTrans = if shown then 0 else 1

                if info then
                    if s._label then
                        tween.play(s._label, info, {TextTransparency = textTrans})
                    end
                else
                    if s._label then
                        s._label.TextTransparency = textTrans
                    end
                end
            end
            function Label:Destroy()
                local s = (self::any)

                if s._themeUnsub then
                    s._themeUnsub()
                end

                self._frame:Destroy()
            end

            return Label
        end)()
    end,
    [8] = function()
        local wax, script, require = ImportGlobals(8)
        local ImportGlobals

        return (function(...)
            local constants = require(script.Parent.Parent.utility.constants)
            local tween = require(script.Parent.Parent.utility.tween)
            local locale = require(script.Parent.Parent.utility.locale)
            local moveable = require(script.Parent.Parent.utility.moveable)

            export type DividerProps = {text: string?, spacing: number?, line: boolean?}
            export type Divider = {_frame: Frame, Set: (self:Divider, text:string) -> (), _setShown: (self:Divider, shown:boolean, animate:boolean?) -> (), Destroy: (self:Divider) -> ()}

            local Divider = {}

            Divider.__index = Divider

            local LINE_THICKNESS = 1
            local DEFAULT_SPACING = 12
            local LABEL_GAP = 10
            local LABEL_HEIGHT = 14
            local TEXT_SIZE = 12
            local LINE_OPACITY = 0.88
            local LABEL_OPACITY = 0.55

            local function buildHalfRule(
                parent: Frame,
                order: number,
                theme: {[string]: any}
            ): Frame
                local rule = Instance.new('Frame')

                rule.Name = 'Line' .. order
                rule.Size = UDim2.new(0, 0, 0, LINE_THICKNESS)
                rule.BackgroundColor3 = theme.ContentColor or Color3.fromRGB(200, 200, 220)
                rule.BackgroundTransparency = LINE_OPACITY
                rule.BorderSizePixel = 0
                rule.LayoutOrder = order
                rule.Parent = parent

                local flex = Instance.new('UIFlexItem')

                flex.FlexMode = Enum.UIFlexMode.Fill
                flex.Parent = rule

                return rule
            end

            function Divider.new(
                props: DividerProps,
                theme: {[string]: any},
                parent: Instance
            ): Divider
                local rawText = props.text
                local bodyText = if rawText ~= nil then tostring(rawText)else''
                local spacing = if typeof(props.spacing) == 'number'then math.max(props.spacing, 0)else DEFAULT_SPACING
                local hasLine = props.line ~= false
                local contentH = if bodyText ~= ''
                    then LABEL_HEIGHT
                    elseif hasLine
                    then LINE_THICKNESS
                    else 0
                local totalH = spacing * 2 + contentH
                local frame = Instance.new('Frame')

                frame.Name = 'Divider'
                frame.Size = UDim2.new(1, -40, 0, totalH)
                frame.BackgroundTransparency = 1
                frame.BorderSizePixel = 0
                frame.Parent = parent

                local layout = Instance.new('UIListLayout')

                layout.FillDirection = Enum.FillDirection.Horizontal
                layout.Padding = UDim.new(0, LABEL_GAP)
                layout.SortOrder = Enum.SortOrder.LayoutOrder
                layout.VerticalAlignment = Enum.VerticalAlignment.Center
                layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
                layout.Parent = frame

                local leftRule: Frame? = nil

                if hasLine then
                    leftRule = buildHalfRule(frame, 1, theme)
                end

                local centreLabel: TextLabel? = nil
                local rightRule: Frame? = nil

                local function buildLabel()
                    local lbl = Instance.new('TextLabel')

                    lbl.Name = 'Label'
                    lbl.Text = locale.t(bodyText)
                    lbl.Size = UDim2.fromOffset(0, LABEL_HEIGHT)
                    lbl.AutomaticSize = Enum.AutomaticSize.X
                    lbl.BackgroundTransparency = 1
                    lbl.BorderSizePixel = 0
                    lbl.TextColor3 = theme.ContentColor or Color3.fromRGB(200, 200, 220)
                    lbl.TextTransparency = LABEL_OPACITY
                    lbl.TextSize = TEXT_SIZE
                    lbl.FontFace = theme.Font or constants.DEFAULT_FONT
                    lbl.TextXAlignment = Enum.TextXAlignment.Center
                    lbl.LayoutOrder = 2
                    lbl.Parent = frame
                    centreLabel = lbl

                    if hasLine then
                        rightRule = buildHalfRule(frame, 3, theme)
                    end
                end

                if bodyText ~= '' then
                    buildLabel()
                end

                local self = setmetatable({}, Divider)::Divider

                self._frame = frame

                local s = self::any

                s._leftRule = leftRule
                s._rightRule = rightRule
                s._centreLabel = centreLabel
                s._hasLine = hasLine
                s._spacing = spacing
                s._theme = theme

                local function applyHeight(text: string)
                    local ch = if text ~= ''
                        then LABEL_HEIGHT
                        elseif hasLine
                        then LINE_THICKNESS
                        else 0

                    frame.Size = UDim2.new(1, -40, 0, spacing * 2 + ch)
                end

                s._applyHeight = applyHeight
                s._buildLabel = buildLabel

                moveable(Divider)

                return self
            end
            function Divider:Set(text: string)
                local s = self::any
                local body = if text ~= nil then tostring(text)else''

                if body ~= '' and not s._centreLabel then
                    s._buildLabel()
                end
                if s._centreLabel then
                    s._centreLabel.Text = locale.t(body)
                    s._centreLabel.Visible = body ~= ''
                end
                if s._rightRule then
                    s._rightRule.Visible = body ~= ''
                end

                s._applyHeight(body)
            end
            function Divider:_setShown(shown: boolean, animate: boolean?)
                local s = self::any
                local info = if animate ~= false then constants.tweenNormal else nil
                local lineOpacity = if shown then LINE_OPACITY else 1
                local labelOpacity = if shown then LABEL_OPACITY else 1

                if info then
                    if s._leftRule then
                        tween.play(s._leftRule, info, {BackgroundTransparency = lineOpacity})
                    end
                    if s._rightRule then
                        tween.play(s._rightRule, info, {BackgroundTransparency = lineOpacity})
                    end
                    if s._centreLabel then
                        tween.play(s._centreLabel, info, {TextTransparency = labelOpacity})
                    end
                else
                    if s._leftRule then
                        s._leftRule.BackgroundTransparency = lineOpacity
                    end
                    if s._rightRule then
                        s._rightRule.BackgroundTransparency = lineOpacity
                    end
                    if s._centreLabel then
                        s._centreLabel.TextTransparency = labelOpacity
                    end
                end
            end
            function Divider:Destroy()
                self._frame:Destroy()
            end

            return Divider
        end)()
    end,
    [15] = function()
        local wax, script, require = ImportGlobals(15)
        local ImportGlobals

        return (function(...)
            local variables = require(script.Parent.Parent.utility.variables)
            local constants = require(script.Parent.Parent.utility.constants)
            local types = require(script.Parent.Parent.types)
            local icons = require(script.Parent.Parent.utility.icons)
            local TweenService = variables.tweenService
            local RunService = variables.runService
            local FONT_BOLD = constants.DEFAULT_FONT_BOLD
            local FONT_MED = constants.DEFAULT_FONT_MEDIUM
            local TW_FADE_IN = TweenInfo.new(0.32, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            local TW_MORPH = TweenInfo.new(0.48, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
            local TW_CONTENT = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            local TW_PROGRESS = TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            local TW_STATUS = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

            export type TaskContext = types.TaskContext
            export type TaskEntry = types.TaskEntry
            export type LoadingScreenProps = types.LoadingScreenProps
            export type LoadingScreen = types.LoadingScreen

            local LoadingScreen = {}

            LoadingScreen.__index = LoadingScreen

            function LoadingScreen.new(props: LoadingScreenProps): LoadingScreen
                local title = props.title or 'Delirium'
                local subtitle = props.subtitle
                local iconProp = props.icon
                local accent = props.accent or Color3.fromHex('#4cc2ff')
                local hasSub = subtitle ~= nil and subtitle ~= ''
                local allowCancel = props.allowCancel == true
                local minDuration = (props.minDuration or (constants.loading and constants.loading.minDuration) or 0.6)
                local resolvedIcon: string? = nil

                if iconProp then
                    resolvedIcon = icons.Resolve(iconProp)
                end

                local gui = Instance.new('ScreenGui')

                gui.Name = 'DeliriumLoading'
                gui.DisplayOrder = constants.displayOrder.loading
                gui.IgnoreGuiInset = true
                gui.ResetOnSpawn = false
                gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
                gui.Parent = variables.guiContainer

                local baseHeight = if hasSub then 72 else 64
                local baseWidth = 340
                local pill = Instance.new('Frame')

                pill.Name = 'Pill'
                pill.AnchorPoint = Vector2.new(0.5, 0.5)
                pill.Position = UDim2.fromScale(0.5, 0.5)
                pill.Size = UDim2.fromOffset(baseWidth, baseHeight)
                pill.BackgroundColor3 = Color3.fromHex('#0c0c10')
                pill.BackgroundTransparency = 1
                pill.BorderSizePixel = 0
                pill.ClipsDescendants = true
                pill.ZIndex = 2
                pill.Parent = gui

                local pillCorner = Instance.new('UICorner')

                pillCorner.CornerRadius = UDim.new(0, 16)
                pillCorner.Parent = pill

                local stroke = Instance.new('UIStroke')

                stroke.Color = Color3.fromHex('#1e1e28')
                stroke.Thickness = 1
                stroke.Transparency = 1
                stroke.Parent = pill

                local topGlow = Instance.new('Frame')

                topGlow.Name = 'TopGlow'
                topGlow.Size = UDim2.new(1, 0, 0, 1)
                topGlow.Position = UDim2.fromScale(0, 0)
                topGlow.BackgroundColor3 = accent
                topGlow.BackgroundTransparency = 0.5
                topGlow.BorderSizePixel = 0
                topGlow.ZIndex = 3
                topGlow.Parent = pill

                local topGlowGrad = Instance.new('UIGradient')

                topGlowGrad.Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 1),
                    NumberSequenceKeypoint.new(0.25, 0.2),
                    NumberSequenceKeypoint.new(0.75, 0.2),
                    NumberSequenceKeypoint.new(1, 1),
                })
                topGlowGrad.Parent = topGlow

                local bgGrad = Instance.new('UIGradient')

                bgGrad.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromHex('#13131a')),
                    ColorSequenceKeypoint.new(1, Color3.fromHex('#0a0a0e')),
                })
                bgGrad.Rotation = 45
                bgGrad.Parent = pill

                local content = Instance.new('Frame')

                content.Name = 'Content'
                content.Size = UDim2.new(1, 0, 0, baseHeight - 4)
                content.BackgroundTransparency = 1
                content.BorderSizePixel = 0
                content.ZIndex = 3
                content.Parent = pill

                local layout = Instance.new('UIListLayout')

                layout.FillDirection = Enum.FillDirection.Horizontal
                layout.VerticalAlignment = Enum.VerticalAlignment.Center
                layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
                layout.Padding = UDim.new(0, 12)
                layout.SortOrder = Enum.SortOrder.LayoutOrder
                layout.Parent = content

                local padding = Instance.new('UIPadding')

                padding.PaddingLeft = UDim.new(0, 14)
                padding.PaddingRight = UDim.new(0, 14)
                padding.Parent = content

                local badge = Instance.new('Frame')

                badge.Name = 'Badge'
                badge.Size = UDim2.fromOffset(34, 34)
                badge.BackgroundColor3 = accent
                badge.BorderSizePixel = 0
                badge.ZIndex = 4
                badge.LayoutOrder = 1
                badge.Parent = content

                do
                    local c = Instance.new('UICorner')

                    c.CornerRadius = UDim.new(0, 9)
                    c.Parent = badge
                end
                do
                    local g = Instance.new('UIGradient')

                    g.Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                        ColorSequenceKeypoint.new(1, Color3.fromRGB(160, 160, 175)),
                    })
                    g.Transparency = NumberSequence.new({
                        NumberSequenceKeypoint.new(0, 0.25),
                        NumberSequenceKeypoint.new(1, 0.6),
                    })
                    g.Rotation = 135
                    g.Parent = badge
                end

                local badgeLbl: TextLabel? = nil
                local badgeImg: ImageLabel? = nil

                if resolvedIcon then
                    badgeImg = Instance.new('ImageLabel')
                    badgeImg.Size = UDim2.fromOffset(18, 18)
                    badgeImg.AnchorPoint = Vector2.new(0.5, 0.5)
                    badgeImg.Position = UDim2.fromScale(0.5, 0.5)
                    badgeImg.BackgroundTransparency = 1
                    badgeImg.Image = resolvedIcon
                    badgeImg.ImageColor3 = Color3.fromRGB(255, 255, 255)
                    badgeImg.ScaleType = Enum.ScaleType.Fit
                    badgeImg.ZIndex = 5
                    badgeImg.Parent = badge
                else
                    badgeLbl = Instance.new('TextLabel')
                    badgeLbl.Size = UDim2.fromScale(1, 1)
                    badgeLbl.BackgroundTransparency = 1
                    badgeLbl.Text = string.sub(title, 1, 1):upper()
                    badgeLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
                    badgeLbl.TextSize = 16
                    badgeLbl.FontFace = FONT_BOLD
                    badgeLbl.TextXAlignment = Enum.TextXAlignment.Center
                    badgeLbl.ZIndex = 5
                    badgeLbl.Parent = badge
                end

                local textStack = Instance.new('Frame')

                textStack.Name = 'TextStack'
                textStack.Size = UDim2.new(1, -94, 1, 0)
                textStack.BackgroundTransparency = 1
                textStack.LayoutOrder = 2
                textStack.ZIndex = 4
                textStack.Parent = content

                do
                    local l = Instance.new('UIListLayout')

                    l.FillDirection = Enum.FillDirection.Vertical
                    l.VerticalAlignment = Enum.VerticalAlignment.Center
                    l.HorizontalAlignment = Enum.HorizontalAlignment.Left
                    l.Padding = UDim.new(0, 1)
                    l.SortOrder = Enum.SortOrder.LayoutOrder
                    l.Parent = textStack
                end

                local titleRow = Instance.new('Frame')

                titleRow.Name = 'TitleRow'
                titleRow.Size = UDim2.new(1, 0, 0, 16)
                titleRow.BackgroundTransparency = 1
                titleRow.LayoutOrder = 1
                titleRow.ZIndex = 5
                titleRow.Parent = textStack

                do
                    local rl = Instance.new('UIListLayout')

                    rl.FillDirection = Enum.FillDirection.Horizontal
                    rl.VerticalAlignment = Enum.VerticalAlignment.Center
                    rl.HorizontalAlignment = Enum.HorizontalAlignment.Left
                    rl.Padding = UDim.new(0, 6)
                    rl.Parent = titleRow
                end

                local titleLbl = Instance.new('TextLabel')

                titleLbl.Name = 'Title'
                titleLbl.Size = UDim2.new(0, 0, 1, 0)
                titleLbl.AutomaticSize = Enum.AutomaticSize.X
                titleLbl.BackgroundTransparency = 1
                titleLbl.Text = title
                titleLbl.TextColor3 = Color3.fromRGB(240, 240, 248)
                titleLbl.TextSize = 13
                titleLbl.FontFace = FONT_BOLD
                titleLbl.TextXAlignment = Enum.TextXAlignment.Left
                titleLbl.TextTruncate = Enum.TextTruncate.AtEnd
                titleLbl.ZIndex = 5
                titleLbl.Parent = titleRow

                local subLbl: TextLabel? = nil

                if hasSub then
                    subLbl = Instance.new('TextLabel')
                    subLbl.Name = 'Subtitle'
                    subLbl.Size = UDim2.new(0, 0, 1, 0)
                    subLbl.AutomaticSize = Enum.AutomaticSize.X
                    subLbl.BackgroundTransparency = 1
                    subLbl.Text = subtitle::string
                    subLbl.TextColor3 = Color3.fromHex('#6b6b7a')
                    subLbl.TextSize = 11
                    subLbl.FontFace = FONT_MED
                    subLbl.TextXAlignment = Enum.TextXAlignment.Left
                    subLbl.ZIndex = 5
                    subLbl.Parent = titleRow
                end

                local statusRow = Instance.new('Frame')

                statusRow.Name = 'StatusRow'
                statusRow.Size = UDim2.new(1, 0, 0, 14)
                statusRow.BackgroundTransparency = 1
                statusRow.LayoutOrder = 2
                statusRow.ZIndex = 5
                statusRow.Parent = textStack

                local statusLbl = Instance.new('TextLabel')

                statusLbl.Name = 'Status'
                statusLbl.Size = UDim2.new(1, if allowCancel then-78 else-44, 1, 0)
                statusLbl.Position = UDim2.fromScale(0, 0)
                statusLbl.BackgroundTransparency = 1
                statusLbl.Text = 'Starting up...'
                statusLbl.TextColor3 = Color3.fromHex('#656575')
                statusLbl.TextSize = 11
                statusLbl.FontFace = FONT_MED
                statusLbl.TextXAlignment = Enum.TextXAlignment.Left
                statusLbl.TextTruncate = Enum.TextTruncate.AtEnd
                statusLbl.ZIndex = 5
                statusLbl.Parent = statusRow

                local percentLbl = Instance.new('TextLabel')

                percentLbl.Name = 'Percent'
                percentLbl.Size = UDim2.new(0, 36, 1, 0)
                percentLbl.Position = UDim2.new(1, if allowCancel then-74 else-36, 0, 0)
                percentLbl.BackgroundTransparency = 1
                percentLbl.Text = '0%'
                percentLbl.TextColor3 = accent
                percentLbl.TextSize = 11
                percentLbl.FontFace = FONT_MED
                percentLbl.TextXAlignment = Enum.TextXAlignment.Right
                percentLbl.ZIndex = 5
                percentLbl.Parent = statusRow

                local cancelBtn: TextButton? = nil

                if allowCancel then
                    cancelBtn = Instance.new('TextButton')
                    cancelBtn.Name = 'CancelBtn'
                    cancelBtn.Size = UDim2.new(0, 34, 0, 14)
                    cancelBtn.Position = UDim2.new(1, -34, 0, 0)
                    cancelBtn.BackgroundTransparency = 1
                    cancelBtn.Text = 'Cancel'
                    cancelBtn.TextColor3 = Color3.fromHex('#888898')
                    cancelBtn.TextSize = 10
                    cancelBtn.FontFace = FONT_MED
                    cancelBtn.ZIndex = 6
                    cancelBtn.Parent = statusRow
                end

                local progressTrack = Instance.new('Frame')

                progressTrack.Name = 'ProgressTrack'
                progressTrack.Size = UDim2.new(1, 0, 0, 3)
                progressTrack.Position = UDim2.new(0, 0, 1, -3)
                progressTrack.BackgroundColor3 = Color3.fromHex('#16161f')
                progressTrack.BackgroundTransparency = 0
                progressTrack.BorderSizePixel = 0
                progressTrack.ZIndex = 4
                progressTrack.Parent = pill

                local progressFill = Instance.new('Frame')

                progressFill.Name = 'ProgressFill'
                progressFill.Size = UDim2.new(0, 0, 1, 0)
                progressFill.BackgroundColor3 = accent
                progressFill.BorderSizePixel = 0
                progressFill.ZIndex = 5
                progressFill.Parent = progressTrack

                do
                    local fillGrad = Instance.new('UIGradient')

                    fillGrad.Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, accent),
                        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
                    })
                    fillGrad.Transparency = NumberSequence.new({
                        NumberSequenceKeypoint.new(0, 0),
                        NumberSequenceKeypoint.new(0.85, 0),
                        NumberSequenceKeypoint.new(1, 0.4),
                    })
                    fillGrad.Parent = progressFill
                end

                local actionRow = Instance.new('Frame')

                actionRow.Name = 'ActionRow'
                actionRow.Size = UDim2.new(1, -28, 0, 24)
                actionRow.Position = UDim2.new(0, 14, 0, baseHeight)
                actionRow.BackgroundTransparency = 1
                actionRow.Visible = false
                actionRow.ZIndex = 6
                actionRow.Parent = pill

                do
                    local al = Instance.new('UIListLayout')

                    al.FillDirection = Enum.FillDirection.Horizontal
                    al.VerticalAlignment = Enum.VerticalAlignment.Center
                    al.HorizontalAlignment = Enum.HorizontalAlignment.Right
                    al.Padding = UDim.new(0, 8)
                    al.Parent = actionRow
                end

                local function makeActionBtn(text: string, color: Color3): TextButton
                    local btn = Instance.new('TextButton')

                    btn.Name = text .. 'Btn'
                    btn.Size = UDim2.new(0, 48, 0, 20)
                    btn.BackgroundColor3 = Color3.fromHex('#181822')
                    btn.Text = text
                    btn.TextColor3 = color
                    btn.TextSize = 11
                    btn.FontFace = FONT_MED
                    btn.AutoButtonColor = true
                    btn.ZIndex = 7
                    btn.Parent = actionRow

                    do
                        local c = Instance.new('UICorner')

                        c.CornerRadius = UDim.new(0, 6)
                        c.Parent = btn
                    end
                    do
                        local s = Instance.new('UIStroke')

                        s.Color = Color3.fromHex('#282838')
                        s.Thickness = 1
                        s.Parent = btn
                    end

                    return btn
                end

                local skipBtn = makeActionBtn('Skip', Color3.fromHex('#8c8c9a'))
                local retryBtn = makeActionBtn('Retry', accent)
                local exitBtn = makeActionBtn('Exit', Color3.fromHex('#ff4f58'))

                TweenService:Create(pill, TW_FADE_IN, {BackgroundTransparency = 0}):Play()
                TweenService:Create(stroke, TW_FADE_IN, {Transparency = 0}):Play()

                local pulseT = 0
                local pulseConn = RunService.Heartbeat:Connect(function(dt)
                    pulseT += dt

                    badge.BackgroundTransparency = 0.02 + (math.sin(pulseT * 2.4) + 1) * 0.05
                end)
                local self: LoadingScreen = setmetatable({}, LoadingScreen)::any
                local s = self::any

                s._gui = gui
                s._pill = pill
                s._pillCorner = pillCorner
                s._stroke = stroke
                s._topGlow = topGlow
                s._content = content
                s._badge = badge
                s._badgeLbl = badgeLbl
                s._badgeImg = badgeImg
                s._titleLbl = titleLbl
                s._subLbl = subLbl
                s._statusLbl = statusLbl
                s._percentLbl = percentLbl
                s._cancelBtn = cancelBtn
                s._actionRow = actionRow
                s._skipBtn = skipBtn
                s._retryBtn = retryBtn
                s._exitBtn = exitBtn
                s._progressTrack = progressTrack
                s._progressFill = progressFill
                s._pulseConn = pulseConn
                s._dismissed = false
                s._cancelled = false
                s._baseHeight = baseHeight
                s._baseWidth = baseWidth
                s._accent = accent
                s._minDuration = minDuration
                s._currentProg = 0
                s._tasks = {}::{TaskEntry}
                s._totalWeight = 0
                s._doneWeight = 0
                s._currentTask = nil::TaskEntry?

                if cancelBtn then
                    cancelBtn.Activated:Connect(function()
                        self:Cancel()
                    end)
                end

                return self
            end
            function LoadingScreen:Task(
                name: string,
                weight: number?,
                run: (ctx:TaskContext) -> ()
            ): LoadingScreen
                local s = self::any
                local w = weight or (constants.loading and constants.loading.defaultTaskWeight) or 1

                table.insert(s._tasks, {
                    name = name,
                    weight = math.max(0, w),
                    run = run,
                    progress = 0,
                })

                s._totalWeight += math.max(0, w)

                return self
            end
            function LoadingScreen:SetTotalWeight(total: number)
                local s = self::any

                s._totalWeight = total
            end
            function LoadingScreen:update(status: string, progress: number?)
                local s = self::any

                if s._dismissed then
                    return
                end

                local statusLbl = s._statusLbl::TextLabel

                if statusLbl.Text ~= status then
                    local fadeOut = TweenService:Create(statusLbl, TW_STATUS, {TextTransparency = 0.6})

                    fadeOut:Play()
                    fadeOut.Completed:Once(function()
                        fadeOut:Destroy()

                        if s._dismissed then
                            return
                        end

                        statusLbl.Text = status

                        local fadeIn = TweenService:Create(statusLbl, TW_STATUS, {TextTransparency = 0})

                        fadeIn:Play()
                        fadeIn.Completed:Once(function()
                            fadeIn:Destroy()
                        end)
                    end)
                end
                if progress ~= nil then
                    local p = math.clamp(progress, 0, if progress > 1 then 100 else 1)
                    local frac = if progress > 1 then p / 100 else p

                    s._currentProg = frac

                    local fill = s._progressFill::Frame

                    TweenService:Create(fill, TW_PROGRESS, {
                        Size = UDim2.new(frac, 0, 1, 0),
                    }):Play()

                    local percentLbl = s._percentLbl::TextLabel

                    percentLbl.Text = string.format('%d%%', math.round(frac * 100))
                end
            end
            function LoadingScreen:Cancel()
                local s = self::any

                if s._dismissed or s._cancelled then
                    return
                end

                s._cancelled = true

                local warnCol = (constants.loading and constants.loading.cancelledColor) or Color3.fromHex('#f5a524')

                s._statusLbl.TextColor3 = warnCol
                s._statusLbl.Text = 'Cancelled'
                s._percentLbl.TextColor3 = warnCol
                s._skipBtn.Visible = false
                s._retryBtn.Visible = false
                s._exitBtn.Visible = true
                s._actionRow.Visible = true

                TweenService:Create(s._pill, TW_PROGRESS, {
                    Size = UDim2.fromOffset(s._baseWidth, s._baseHeight + 30),
                }):Play()
                s._exitBtn.Activated:Once(function()
                    self:dismiss(nil)
                end)
            end
            function LoadingScreen:SetError(message: string)
                local s = self::any

                if s._dismissed then
                    return
                end

                local errCol = (constants.loading and constants.loading.errorColor) or Color3.fromHex('#ff4f58')

                s._statusLbl.TextColor3 = errCol
                s._statusLbl.Text = 'Error: ' .. string.sub(message, 1, 32)
                s._percentLbl.TextColor3 = errCol
                s._skipBtn.Visible = true
                s._retryBtn.Visible = true
                s._exitBtn.Visible = true
                s._actionRow.Visible = true

                TweenService:Create(s._pill, TW_PROGRESS, {
                    Size = UDim2.fromOffset(s._baseWidth, s._baseHeight + 30),
                }):Play()
            end
            function LoadingScreen:Run(options: {minDuration: number?}?): (boolean,string?)
                local s = self::any

                if s._dismissed then
                    return false, 'dismissed'
                end

                local minDur = (options and options.minDuration) or s._minDuration or 0.6
                local startTime = os.clock()
                local totalWeight = s._totalWeight

                if totalWeight <= 0 then
                    totalWeight = math.max(1, #s._tasks)
                end

                local doneWeight = 0
                local taskIdx = 1

                local function computeFraction(extraTaskFraction: number): number
                    if totalWeight <= 0 then
                        return 1
                    end

                    local curW = if s._currentTask then(s._currentTask.weight or 1)else 0
                    local effectiveDone = doneWeight + (curW * math.clamp(extraTaskFraction, 0, 1))

                    return math.clamp(effectiveDone / totalWeight, 0, 1)
                end

                while taskIdx <= #s._tasks do
                    if s._cancelled then
                        return false, 'cancelled'
                    end

                    local taskEntry = s._tasks[taskIdx]

                    s._currentTask = taskEntry

                    local tWeight = taskEntry.weight or 1

                    self:update(taskEntry.name, computeFraction(0))

                    local taskAborted = false
                    local currentTaskFraction = 0
                    local ctx: TaskContext = {
                        Status = function(_, msg: string)
                            self:update(msg, nil)
                        end,
                        SetProgress = function(_, frac: number)
                            currentTaskFraction = frac
                            taskEntry.progress = frac

                            self:update(taskEntry.name, computeFraction(frac))
                        end,
                        Abort = function(_, _msg: string?)
                            taskAborted = true

                            self:Cancel()
                        end,
                        ShouldAbort = function(_)
                            return s._cancelled or taskAborted
                        end,
                    }
                    local ok, err = pcall(taskEntry.run, ctx)

                    if s._cancelled or taskAborted then
                        return false, 'cancelled'
                    end
                    if not ok then
                        self:SetError(tostring(err))

                        local actionChosen = nil
                        local actionThread = coroutine.running()
                        local cSkip, cRetry, cExit

                        cSkip = s._skipBtn.Activated:Connect(function()
                            actionChosen = 'skip'

                            if coroutine.status(actionThread) == 'suspended' then
                                task.spawn(actionThread)
                            end
                        end)
                        cRetry = s._retryBtn.Activated:Connect(function()
                            actionChosen = 'retry'

                            if coroutine.status(actionThread) == 'suspended' then
                                task.spawn(actionThread)
                            end
                        end)
                        cExit = s._exitBtn.Activated:Connect(function()
                            actionChosen = 'exit'

                            if coroutine.status(actionThread) == 'suspended' then
                                task.spawn(actionThread)
                            end
                        end)

                        coroutine.yield()
                        cSkip:Disconnect()
                        cRetry:Disconnect()
                        cExit:Disconnect()

                        s._actionRow.Visible = false

                        TweenService:Create(s._pill, TW_PROGRESS, {
                            Size = UDim2.fromOffset(s._baseWidth, s._baseHeight),
                        }):Play()

                        s._statusLbl.TextColor3 = Color3.fromHex('#656575')
                        s._percentLbl.TextColor3 = s._accent

                        if actionChosen == 'exit' then
                            self:dismiss(nil)

                            return false, tostring(err)
                        elseif actionChosen == 'retry' then
                            continue
                        elseif actionChosen == 'skip' then
                        end
                    end

                    doneWeight += tWeight

                    self:update(taskEntry.name, computeFraction(1))

                    taskIdx += 1
                end

                local elapsed = os.clock() - startTime

                if elapsed < minDur then
                    task.wait(minDur - elapsed)
                end

                self:update('Ready!', 1)
                task.wait(0.12)

                return true, nil
            end
            function LoadingScreen:dismiss(window: any?)
                local s = self::any

                if s._dismissed then
                    return
                end

                s._dismissed = true

                if s._pulseConn then
                    s._pulseConn:Disconnect()

                    s._pulseConn = nil
                end

                local winFrame: Frame? = if window then(window._windowFrame or (window::any)._frame)else nil

                TweenService:Create(s._badge, TW_CONTENT, {BackgroundTransparency = 1}):Play()

                if s._badgeLbl then
                    TweenService:Create(s._badgeLbl, TW_CONTENT, {TextTransparency = 1}):Play()
                end
                if s._badgeImg then
                    TweenService:Create(s._badgeImg, TW_CONTENT, {ImageTransparency = 1}):Play()
                end

                TweenService:Create(s._titleLbl, TW_CONTENT, {TextTransparency = 1}):Play()

                if s._subLbl then
                    TweenService:Create(s._subLbl, TW_CONTENT, {TextTransparency = 1}):Play()
                end

                TweenService:Create(s._statusLbl, TW_CONTENT, {TextTransparency = 1}):Play()
                TweenService:Create(s._percentLbl, TW_CONTENT, {TextTransparency = 1}):Play()

                if s._cancelBtn then
                    TweenService:Create(s._cancelBtn, TW_CONTENT, {TextTransparency = 1}):Play()
                end

                TweenService:Create(s._progressTrack, TW_CONTENT, {BackgroundTransparency = 1}):Play()
                TweenService:Create(s._progressFill, TW_CONTENT, {BackgroundTransparency = 1}):Play()

                if s._topGlow then
                    TweenService:Create(s._topGlow, TW_CONTENT, {BackgroundTransparency = 1}):Play()
                end
                if s._actionRow and s._actionRow.Visible then
                    s._actionRow.Visible = false
                end
                if winFrame and not window.unloaded then
                    local winTargetSize = window._windowSize or winFrame.Size
                    local winTargetPos = winFrame.Position
                    local winCornerVal = if window._winCorner then window._winCorner.CornerRadius else UDim.new(0, 10)
                    local winStrokeVal = if window._winStroke then window._winStroke.Color else Color3.fromHex('#1e1e26')

                    winFrame.BackgroundTransparency = 0
                    winFrame.Visible = true

                    local winBody: Frame? = window._body
                    local winTitle: Frame? = window._titleBar

                    if winBody then
                        winBody.Visible = false
                    end
                    if winTitle then
                        winTitle.Visible = false
                    end

                    local morphSize = TweenService:Create(s._pill, TW_MORPH, {
                        Size = winTargetSize,
                        Position = winTargetPos,
                    })
                    local morphCorner = TweenService:Create(s._pillCorner, TW_MORPH, {CornerRadius = winCornerVal})
                    local morphStroke = TweenService:Create(s._stroke, TW_MORPH, {Color = winStrokeVal})

                    morphSize:Play()
                    morphCorner:Play()
                    morphStroke:Play()
                    morphSize.Completed:Once(function()
                        morphSize:Destroy()
                        morphCorner:Destroy()
                        morphStroke:Destroy()

                        if winBody then
                            winBody.Visible = true
                        end
                        if winTitle then
                            winTitle.Visible = true
                        end

                        window:Show()

                        if s._gui and s._gui.Parent then
                            s._gui:Destroy()
                        end
                    end)
                else
                    local pillOut = TweenService:Create(s._pill, TW_MORPH, {BackgroundTransparency = 1})
                    local strokeOut = TweenService:Create(s._stroke, TW_MORPH, {Transparency = 1})

                    pillOut:Play()
                    strokeOut:Play()
                    pillOut.Completed:Once(function()
                        pillOut:Destroy()
                        strokeOut:Destroy()

                        if s._gui and s._gui.Parent then
                            s._gui:Destroy()
                        end
                    end)
                end
            end

            LoadingScreen.Morph = LoadingScreen.dismiss

            return LoadingScreen
        end)()
    end,
    [21] = function()
        local wax, script, require = ImportGlobals(21)
        local ImportGlobals

        return (function(...)
            local constants = require(script.Parent.Parent.utility.constants)
            local element = require(script.Parent.Parent.utility.element)
            local tween = require(script.Parent.Parent.utility.tween)
            local locale = require(script.Parent.Parent.utility.locale)
            local moveable = require(script.Parent.Parent.utility.moveable)
            local odometer = require(script.Parent.Parent.utility.odometer)
            local functions = require(script.Parent.Parent.utility.functions)
            local variables = require(script.Parent.Parent.utility.variables)

            export type StatProps = {name: string?, icon: (string | number)?, value: number?, prefix: string?, suffix: string?, changeMode: string?, changeBaseline: string?, numberEasing: boolean?}
            export type Stat = {_frame: Frame, value: number, Set: (self:Stat, value:number) -> (), Get: (self:Stat) -> number, ResetBaseline: (self:Stat, newBaseline:number?) -> (), _setShown: (self:Stat, shown:boolean, animate:boolean?) -> (), Destroy: (self:Stat) -> ()}

            local Stat = {}

            Stat.__index = Stat

            local CARD_H = 90
            local ACCENT_INFO = TweenInfo.new(0.6, Enum.EasingStyle.Exponential)
            local ACCENT_TRANS = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.85),
                NumberSequenceKeypoint.new(1, 0),
            })
            local accents = constants.statAccents

            local function formatValue(v: number): string
                local rounded = math.round(math.abs(v))
                local s = string.format('%.0f', rounded)
                local result = s:reverse():gsub('%d%d%d', '%0,'):reverse()

                if result:sub(1, 1) == ',' then
                    result = result:sub(2)
                end

                return if v < 0 and rounded ~= 0 then'-' .. result else result
            end
            local function formatChange(delta: number): string
                local rounded = math.round(delta)

                if rounded > 0 then
                    return '+' .. formatValue(rounded)
                elseif rounded < 0 then
                    return formatValue(rounded)
                else
                    return '0'
                end
            end
            local function formatPct(pct: number): string
                if pct > 0 then
                    return string.format('+%.1f%%', pct)
                elseif pct < 0 then
                    return string.format('%.1f%%', pct)
                else
                    return '0%'
                end
            end

            function Stat.new(
                props: StatProps,
                theme: {[string]: any},
                parent: Instance
            ): Stat
                local name = props.name or 'Stat'
                local iconId = props.icon
                local prefix = props.prefix or ''
                local suffix = props.suffix or ''
                local changeMode = props.changeMode or 'percentage'
                local changeBase = props.changeBaseline or 'previous'
                local numEasing = props.numberEasing ~= false
                local initValue = props.value
                local hasValue = initValue ~= nil
                local frame, stroke = element.makeFrame('Stat_' .. name, theme, parent, CARD_H)

                frame.ZIndex = 5

                local gradContainer = Instance.new('Frame')

                gradContainer.Name = 'GradientContainer'
                gradContainer.Size = UDim2.fromScale(1, 1)
                gradContainer.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                gradContainer.BackgroundTransparency = 0
                gradContainer.BorderSizePixel = 0
                gradContainer.ZIndex = 5
                gradContainer.Parent = frame

                local gradCorner = Instance.new('UICorner')

                gradCorner.CornerRadius = theme.ElementCornerRadius or UDim.new(0, 10)
                gradCorner.Parent = gradContainer

                local strokeGrad = Instance.new('UIGradient')

                strokeGrad.Color = accents.neutral.stroke
                strokeGrad.Transparency = ACCENT_TRANS
                strokeGrad.Rotation = 2
                strokeGrad.Offset = Vector2.new(0, 0.5)
                strokeGrad.Parent = stroke

                local mainGrad = Instance.new('UIGradient')

                mainGrad.Color = accents.neutral.fill
                mainGrad.Transparency = ACCENT_TRANS
                mainGrad.Rotation = 2
                mainGrad.Offset = Vector2.new(0, 0.5)
                mainGrad.Parent = gradContainer

                local titleContainer = Instance.new('Frame')

                titleContainer.Name = 'TitleRow'
                titleContainer.Size = UDim2.new(1, -40, 0, 32)
                titleContainer.Position = UDim2.fromOffset(20, 15)
                titleContainer.BackgroundTransparency = 1
                titleContainer.BorderSizePixel = 0
                titleContainer.ZIndex = 10
                titleContainer.Parent = frame

                local titleList = Instance.new('UIListLayout')

                titleList.Padding = UDim.new(0, 8)
                titleList.FillDirection = Enum.FillDirection.Horizontal
                titleList.VerticalAlignment = Enum.VerticalAlignment.Center
                titleList.SortOrder = Enum.SortOrder.LayoutOrder
                titleList.Parent = titleContainer

                local iconLabel: ImageLabel? = nil

                if iconId then
                    local img = Instance.new('ImageLabel')

                    img.Name = 'Icon'
                    img.Image = 'rbxassetid://' .. tostring(iconId)
                    img.ImageColor3 = theme.ContentColor or Color3.fromRGB(220, 215, 240)
                    img.ImageTransparency = 1
                    img.Size = UDim2.fromOffset(32, 32)
                    img.BackgroundTransparency = 1
                    img.BorderSizePixel = 0
                    img.ZIndex = 10
                    img.Parent = titleContainer
                    iconLabel = img
                end

                local titleLabel = Instance.new('TextLabel')

                titleLabel.Name = 'Title'
                titleLabel.Text = locale.t(name)
                titleLabel.Size = UDim2.fromOffset(300, 19)
                titleLabel.AutomaticSize = Enum.AutomaticSize.X
                titleLabel.BackgroundTransparency = 1
                titleLabel.BorderSizePixel = 0
                titleLabel.TextColor3 = theme.ContentColor or Color3.fromRGB(200, 200, 220)
                titleLabel.TextTransparency = 1
                titleLabel.TextSize = 19
                titleLabel.FontFace = theme.TitleFont or constants.DEFAULT_FONT_SEMI
                titleLabel.TextXAlignment = Enum.TextXAlignment.Left
                titleLabel.TextWrapped = true
                titleLabel.ZIndex = 10
                titleLabel.LayoutOrder = 1
                titleLabel.Parent = titleContainer

                local valueHost = Instance.new('Frame')

                valueHost.Name = 'ValueHost'
                valueHost.AnchorPoint = Vector2.new(0, 1)
                valueHost.Position = UDim2.new(0, 20, 1, -15)
                valueHost.Size = UDim2.fromOffset(200, 20)
                valueHost.BackgroundTransparency = 1
                valueHost.BorderSizePixel = 0
                valueHost.ZIndex = 10
                valueHost.Parent = frame

                local changeHost = Instance.new('Frame')

                changeHost.Name = 'ChangeHost'
                changeHost.AnchorPoint = Vector2.new(1, 1)
                changeHost.Position = UDim2.new(1, -20, 1, -15)
                changeHost.Size = UDim2.fromOffset(200, 15)
                changeHost.BackgroundTransparency = 1
                changeHost.BorderSizePixel = 0
                changeHost.ZIndex = 10
                changeHost.Parent = frame

                local self = setmetatable({}, Stat)::Stat

                self._frame = frame
                self.value = if hasValue then(initValue::number)else 0

                local s = self::any

                s._stroke = stroke
                s._strokeGrad = strokeGrad
                s._mainGrad = mainGrad
                s._gradContainer = gradContainer
                s._titleLabel = titleLabel
                s._iconLabel = iconLabel
                s._theme = theme
                s._prefix = prefix
                s._suffix = suffix
                s._changeMode = changeMode
                s._changeBase = changeBase
                s._numEasing = numEasing
                s._hasValue = hasValue
                s._initialValue = initValue
                s._lastChange = 0

                local valueOdo = odometer.new(nil, valueHost, {
                    textSize = 20,
                    alignment = Enum.HorizontalAlignment.Left,
                    transparency = 1,
                    theme = theme,
                })
                local changeOdo = odometer.new(nil, changeHost, {
                    textSize = 15,
                    alignment = Enum.HorizontalAlignment.Right,
                    transparency = 1,
                    theme = theme,
                })

                s._valueOdo = valueOdo
                s._changeOdo = changeOdo

                local function fmtValue(v: number): string
                    return prefix .. formatValue(v) .. suffix
                end
                local function fmtChange(delta: number): string
                    return if changeMode == 'absolute'then formatChange(delta)else formatPct(delta)
                end

                s._fmtValue = fmtValue
                s._fmtChange = fmtChange

                valueOdo:snap(fmtValue(self.value))
                changeOdo:snap(fmtChange(0))

                s._themeUnsub = element.subscribeTheme(frame, {
                    frame = frame,
                    stroke = stroke,
                    extra = function(t)
                        s._theme = t
                        titleLabel.TextColor3 = t.ContentColor or Color3.fromRGB(200, 200, 220)
                        titleLabel.FontFace = t.TitleFont or constants.DEFAULT_FONT_SEMI

                        if iconLabel then
                            iconLabel.ImageColor3 = t.ContentColor or Color3.fromRGB(220, 215, 240)
                        end
                    end,
                })

                moveable(Stat)

                return self
            end

            local function setAccent(
                s: any,
                key: string,
                direction: number
            )
                local accent = accents[key] or accents.neutral

                s._strokeGrad.Color = accent.stroke
                s._mainGrad.Color = accent.fill

                local rotation = if direction == 1
                    then 14
                    elseif direction == -1
                    then-10
                    else 2
                local offset = if direction == 1
                    then Vector2.new(0.04, 0.5)
                    elseif direction == -1
                    then Vector2.new(-0.04, 0.5)
                    else Vector2.new(0, 0.5)

                variables.tweenService:Create(s._strokeGrad, ACCENT_INFO, {
                    Rotation = rotation,
                    Offset = offset,
                }):Play()
                variables.tweenService:Create(s._mainGrad, ACCENT_INFO, {
                    Rotation = rotation,
                    Offset = offset,
                }):Play()
            end

            function Stat:Set(value: number)
                local s = self::any

                assert(type(value) == 'number', 'Stat:Set() \u{2014} value must be a number')

                local prev = self.value
                local hasNoHistory = not s._hasValue

                self.value = value
                s._hasValue = true

                if hasNoHistory then
                    s._initialValue = value
                end

                local refValue = if s._changeBase == 'initial'then s._initialValue else prev
                local noChange = hasNoHistory or refValue == value
                local targetChange: number = 0
                local infinityText: string? = nil
                local accentKey = 'neutral'
                local direction = 0

                if not noChange then
                    if refValue == 0 then
                        local sign = if value > 0 then'+'else'-'
                        local sfx = if s._changeMode == 'percentage'then'\u{221e}%'else'\u{221e}'

                        infinityText = sign .. sfx
                        accentKey = if value > 0 then'positive'else'negative'
                        direction = if value > 0 then 1 else-1
                    elseif s._changeMode == 'percentage' then
                        targetChange = ((value - refValue) / math.abs(refValue)) * 100
                        direction = if targetChange > 0
                            then 1
                            elseif targetChange < 0
                            then-1
                            else 0
                        accentKey = if direction == 1
                            then'positive'
                            elseif direction == -1
                            then'negative'
                            else'neutral'
                    else
                        targetChange = value - refValue
                        direction = if targetChange > 0
                            then 1
                            elseif targetChange < 0
                            then-1
                            else 0
                        accentKey = if direction == 1
                            then'positive'
                            elseif direction == -1
                            then'negative'
                            else'neutral'
                    end
                end

                setAccent(s, accentKey, direction)

                if s._numEasing and not hasNoHistory then
                    s._valueOdo:to(s._fmtValue(value), value >= prev)
                else
                    s._valueOdo:snap(s._fmtValue(value))
                end
                if infinityText then
                    s._changeOdo:snap(infinityText)

                    s._lastChange = 0
                elseif s._numEasing and not noChange then
                    s._changeOdo:to(s._fmtChange(targetChange), targetChange >= s._lastChange)

                    s._lastChange = targetChange
                else
                    s._changeOdo:snap(s._fmtChange(targetChange))

                    s._lastChange = targetChange
                end
            end
            function Stat:Get(): number
                return self.value
            end
            function Stat:ResetBaseline(newBaseline: number?)
                local s = self::any
                local prev = self.value
                local hasNoHistory = not s._hasValue
                local baseline = if type(newBaseline) == 'number'then newBaseline else self.value

                s._initialValue = baseline
                self.value = baseline
                s._hasValue = true
                s._lastChange = 0

                s._changeOdo:snap(s._fmtChange(0))

                if s._numEasing and not hasNoHistory then
                    s._valueOdo:to(s._fmtValue(baseline), baseline >= prev)
                else
                    s._valueOdo:snap(s._fmtValue(baseline))
                end

                setAccent(s, 'neutral', 0)
            end
            function Stat:_setShown(shown: boolean, animate: boolean?)
                local s = self::any
                local t = s._theme or {}
                local info = if animate ~= false then constants.tweenNormal else nil
                local frameTrans = if shown then(t.ElementTransparency or 0)else 1
                local strokeTrans = if shown then(t.ElementStrokeTransparency or 0)else 1
                local titleTrans = if shown then 0 else 1
                local gradTrans = if shown then 0 else 1

                if info then
                    tween.play(self._frame, info, {BackgroundTransparency = frameTrans})
                    tween.play(s._gradContainer, info, {BackgroundTransparency = gradTrans})

                    if s._stroke then
                        tween.play(s._stroke, info, {Transparency = strokeTrans})
                    end
                    if s._titleLabel then
                        tween.play(s._titleLabel, info, {TextTransparency = titleTrans})
                    end
                    if s._iconLabel then
                        tween.play(s._iconLabel, info, {ImageTransparency = titleTrans})
                    end
                else
                    self._frame.BackgroundTransparency = frameTrans
                    s._gradContainer.BackgroundTransparency = gradTrans

                    if s._stroke then
                        s._stroke.Transparency = strokeTrans
                    end
                    if s._titleLabel then
                        s._titleLabel.TextTransparency = titleTrans
                    end
                    if s._iconLabel then
                        s._iconLabel.ImageTransparency = titleTrans
                    end
                end
                if s._valueOdo then
                    s._valueOdo:reveal(if shown then 0 else 1, animate)
                end
                if s._changeOdo then
                    s._changeOdo:reveal(if shown then 0 else 1, animate)
                end
            end
            function Stat:Destroy()
                local s = self::any

                if s._themeUnsub then
                    s._themeUnsub()
                end

                self._frame:Destroy()
            end

            return Stat
        end)()
    end,
    [20] = function()
        local wax, script, require = ImportGlobals(20)
        local ImportGlobals

        return (function(...)
            local constants = require(script.Parent.Parent.utility.constants)
            local flags = require(script.Parent.Parent.utility.flags)
            local runtime = require(script.Parent.Parent.utility.runtime)
            local signal = require(script.Parent.Parent.utility.signal)
            local themeUtil = require(script.Parent.Parent.utility.theme)
            local variables = require(script.Parent.Parent.utility.variables)
            local tween = require(script.Parent.Parent.utility.tween)
            local hapticEngine = require(script.Parent.Parent.utility.HapticEngine)
            local moveable = require(script.Parent.Parent.utility.moveable)
            local lockable = require(script.Parent.Parent.utility.lockable)
            local TRACK_H = 15
            local KNOB_W = 30
            local KNOB_H = 18
            local VAL_W = 54
            local GAP = 8
            local DEFAULT_FONT = constants.DEFAULT_FONT_MEDIUM

            export type SliderProps = {name: string?, Label: string?, Text: string?, description: string?, Tooltip: string?, flag: string?, Flag: string?, range: {number}?, min: number?, Min: number?, max: number?, Max: number?, increment: number?, step: number?, Step: number?, value: number?, default: number?, Default: number?, suffix: string?, Suffix: string?, compact: boolean?, Compact: boolean?, hideMax: boolean?, HideMax: boolean?, formatDisplayValue: ((slider:any, value:number) -> string?)?, FormatDisplayValue: ((slider:any, value:number) -> string?)?, enabled: boolean?, Enabled: boolean?, layoutOrder: number?, LayoutOrder: number?, callback: ((value:number) -> ())?, Callback: ((value:number) -> ())?}
            export type Slider = {value: number, Value: number, Changed: any, _frame: Frame, Set: (self:Slider, value:number, skipCallback:boolean?) -> (), SetValue: (self:Slider, value:number, skipCallback:boolean?) -> (), SetEnabled: (self:Slider, enabled:boolean) -> (), GetFrame: (self:Slider) -> Frame, Destroy: (self:Slider) -> ()}

            local Slider = {}

            Slider.__index = Slider

            local function snap(value: number, step: number, min: number): number
                if step <= 0 then
                    return value
                end

                return min + math.round((value - min) / step) * step
            end
            local function fmt(value: number, step: number): string
                if step <= 0 or step >= 1 then
                    return tostring(math.round(value))
                elseif step >= 0.1 then
                    return string.format('%.1f', value)
                else
                    return string.format('%.2f', value)
                end
            end
            local function tFromMouseX(
                track: Frame,
                mouseX: number,
                knobW: number
            ): number
                local kHalf = knobW / 2
                local usable = math.max(track.AbsoluteSize.X - knobW, 1)
                local relX = mouseX - (track.AbsolutePosition.X + kHalf)

                return math.clamp(relX / usable, 0, 1)
            end

            function Slider.new(
                props: SliderProps,
                theme: {[string]: any},
                parent: Instance
            ): Slider
                local name = props.name or props.Label or props.Text or 'Slider'
                local flagKey: string? = props.flag or props.Flag
                local rangeMin = (props.range and props.range[1]) or props.min or props.Min or 0
                local rangeMax = (props.range and props.range[2]) or props.max or props.Max or 100
                local stepVal = props.increment or props.step or props.Step or 1
                local suffix = props.suffix or props.Suffix or ''
                local callback = props.callback or props.Callback
                local isCompact = (props.compact == true) or (props.Compact == true)
                local hideMaxVal = if props.hideMax ~= nil
                    then props.hideMax
                    elseif props.HideMax ~= nil
                    then props.HideMax
                    else true
                local isEnabled = if props.enabled ~= nil
                    then props.enabled
                    elseif props.Enabled ~= nil
                    then props.Enabled
                    else true
                local cfgFormat = props.formatDisplayValue or props.FormatDisplayValue
                local initValue: number

                if flagKey and flags:Get(flagKey) ~= nil then
                    initValue = flags:Get(flagKey)::number
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

                local frame = Instance.new('Frame')

                frame.Name = 'Slider_' .. name
                frame.Size = UDim2.new(1, 0, 0, FRAME_H)
                frame.BackgroundTransparency = 1
                frame.BorderSizePixel = 0
                frame.LayoutOrder = props.layoutOrder or props.LayoutOrder or 0
                frame.ClipsDescendants = false
                frame.Parent = parent

                local shadow = Instance.new('Frame')

                shadow.Name = 'Shadow'
                shadow.AnchorPoint = Vector2.new(0.5, 0.5)
                shadow.Position = UDim2.new(0.5, 0, 0.5, 3)
                shadow.Size = UDim2.new(1, 0, 1, 4)
                shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                shadow.BackgroundTransparency = 0.75
                shadow.BorderSizePixel = 0
                shadow.ZIndex = 1

                local shadowCorner = Instance.new('UICorner')

                shadowCorner.CornerRadius = UDim.new(0, 7)
                shadowCorner.Parent = shadow

                if variables.isTouchOnly then
                    shadow.Visible = false
                end

                shadow.Parent = frame

                local inner = Instance.new('Frame')

                inner.Name = 'Inner'
                inner.AnchorPoint = Vector2.new(0.5, 0.5)
                inner.Position = UDim2.new(0.5, 0, 0.5, 0)
                inner.Size = UDim2.new(1, 0, 1, 0)
                inner.BackgroundColor3 = Color3.new(1, 1, 1)
                inner.BackgroundTransparency = theme.ElementTransparency or 0
                inner.BorderSizePixel = 0
                inner.ZIndex = 2
                inner.ClipsDescendants = true
                inner.Parent = frame

                local innerGrad = Instance.new('UIGradient')

                innerGrad.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromHex('#2e2e2e')),
                    ColorSequenceKeypoint.new(1, Color3.fromHex('#181818')),
                })
                innerGrad.Rotation = 90
                innerGrad.Parent = inner

                local innerCorner = Instance.new('UICorner')

                innerCorner.CornerRadius = UDim.new(0, 6)
                innerCorner.Parent = inner

                local stroke = Instance.new('UIStroke')

                stroke.Color = theme.ElementStroke or Color3.fromHex('#2b2b2b')
                stroke.Thickness = 1
                stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                stroke.Parent = inner

                local innerPad = Instance.new('UIPadding')

                innerPad.PaddingLeft = UDim.new(0, 12)
                innerPad.PaddingRight = UDim.new(0, 12)
                innerPad.PaddingTop = UDim.new(0, 4)
                innerPad.Parent = inner

                local flash = Instance.new('Frame')

                flash.Name = 'Flash'
                flash.Size = UDim2.new(1, 24, 1, 0)
                flash.Position = UDim2.new(0, -12, 0, 0)
                flash.BackgroundColor3 = Color3.new(1, 1, 1)
                flash.BackgroundTransparency = 1
                flash.BorderSizePixel = 0
                flash.ZIndex = 3

                local flashCorner = Instance.new('UICorner')

                flashCorner.CornerRadius = UDim.new(0, 6)
                flashCorner.Parent = flash
                flash.Parent = inner

                local label = Instance.new('TextLabel')

                label.Name = 'Label'
                label.AnchorPoint = Vector2.new(0, 0.5)
                label.Position = UDim2.new(0, 0, 0, math.floor(HEADER_H / 2))
                label.Size = UDim2.new(1, -(VAL_W + GAP), 0, HEADER_H)
                label.BackgroundTransparency = 1
                label.Font = Enum.Font.GothamMedium
                label.FontFace = theme.Font or DEFAULT_FONT
                label.Text = name
                label.TextSize = 13
                label.TextColor3 = if isEnabled then(theme.ContentColor or Color3.fromHex('#ffffff'))else Color3.fromHex('#555555')
                label.TextXAlignment = Enum.TextXAlignment.Left
                label.TextYAlignment = Enum.TextYAlignment.Center
                label.TextTruncate = Enum.TextTruncate.AtEnd
                label.ZIndex = 4
                label.Visible = not isCompact
                label.Parent = inner

                local valLabel = Instance.new('TextLabel')

                valLabel.Name = 'ValueLabel'
                valLabel.BackgroundTransparency = 1
                valLabel.Font = Enum.Font.GothamMedium
                valLabel.FontFace = theme.Font or DEFAULT_FONT
                valLabel.TextSize = 12
                valLabel.TextColor3 = theme.PlaceholderColor or Color3.fromHex('#9d9d9d')
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

                local trackRightPad = if isCompact then(VAL_W + GAP)else 0
                local track = Instance.new('Frame')

                track.Name = 'Track'
                track.Size = UDim2.new(1, -trackRightPad, 0, TRACK_H)
                track.Position = UDim2.fromOffset(0, TRACK_Y)
                track.BackgroundColor3 = theme.SliderBackground or Color3.fromHex('#222222')
                track.BorderSizePixel = 0
                track.ZIndex = 4
                track.ClipsDescendants = false

                local trackCorner = Instance.new('UICorner')

                trackCorner.CornerRadius = UDim.new(0, 100)
                trackCorner.Parent = track
                track.Parent = inner

                local knobRef: Frame = nil::any

                local function knobPosScale(t: number): number
                    local tw = track.AbsoluteSize.X
                    local kw = if knobRef ~= nil and knobRef.AbsoluteSize.X > 0 then knobRef.AbsoluteSize.X else nil

                    if kw ~= nil and tw > 0 then
                        local kHalf_frac = kw / (2 * tw)

                        return math.clamp(kHalf_frac + t * (1 - 2 * kHalf_frac), 0, 1)
                    else
                        local kHalf_frac = KNOB_W / (2 * 200)

                        return math.clamp(kHalf_frac + t * (1 - 2 * kHalf_frac), 0, 1)
                    end
                end

                local self = setmetatable({}, Slider)::Slider

                self.value = initValue
                self.Value = initValue
                self._frame = frame
                self.Changed = signal.new()

                local function fmtDisplay(val: number): string
                    if cfgFormat then
                        local res = cfgFormat(self, val)

                        if res ~= nil then
                            return res
                        end
                    end
                    if not hideMaxVal then
                        return fmt(val, stepVal) .. ' / ' .. fmt(rangeMax, stepVal) .. suffix
                    end

                    return fmt(val, stepVal) .. suffix
                end

                local t0 = (initValue - rangeMin) / math.max(rangeMax - rangeMin, 1e-9)
                local clipFrame = Instance.new('Frame')

                clipFrame.Name = 'FillClip'
                clipFrame.Size = UDim2.new(knobPosScale(t0), 0, 1, 0)
                clipFrame.Position = UDim2.fromOffset(0, 0)
                clipFrame.BackgroundTransparency = 1
                clipFrame.ClipsDescendants = true
                clipFrame.BorderSizePixel = 0
                clipFrame.ZIndex = 5
                clipFrame.Parent = track

                local clipCorner = Instance.new('UICorner')

                clipCorner.CornerRadius = UDim.new(0, 100)
                clipCorner.Parent = clipFrame

                local fill = Instance.new('Frame')

                fill.Name = 'Fill'
                fill.Size = UDim2.new(1, 0, 1, 0)
                fill.BackgroundColor3 = theme.AccentColor or Color3.fromHex('#4cc2ff')
                fill.BorderSizePixel = 0
                fill.ZIndex = 5
                fill.Parent = clipFrame

                local fillCorner = Instance.new('UICorner')

                fillCorner.CornerRadius = UDim.new(0, 100)
                fillCorner.Parent = fill

                local fillGrad = Instance.new('UIGradient')

                fillGrad.Color = ColorSequence.new(theme.AccentColor or Color3.fromHex('#4cc2ff'), theme.AccentColor or Color3.fromHex('#4cc2ff'))
                fillGrad.Rotation = 0
                fillGrad.Parent = fill

                local knob = Instance.new('Frame')

                knob.Name = 'Knob'
                knob.AnchorPoint = Vector2.new(0.5, 0.5)
                knob.Size = UDim2.fromOffset(KNOB_W, KNOB_H)
                knob.Position = UDim2.new(knobPosScale(t0), 0, 0.5, 0)
                knob.BackgroundColor3 = theme.SliderHandle or Color3.fromRGB(255, 255, 255)
                knob.BorderSizePixel = 0
                knob.ZIndex = 6
                knob.ClipsDescendants = false

                local knobCorner = Instance.new('UICorner')

                knobCorner.CornerRadius = UDim.new(0, 100)
                knobCorner.Parent = knob
                knob.Parent = track
                knobRef = knob

                local hit = Instance.new('TextButton')

                hit.Name = 'Hit'
                hit.Size = UDim2.fromScale(1, 1)
                hit.BackgroundTransparency = 1
                hit.Text = ''
                hit.AutoButtonColor = false
                hit.ZIndex = 7
                hit.Parent = inner
                valLabel.Text = fmtDisplay(initValue)

                local s = self::any

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
                s._inner = inner
                s._conns = {}::{[string]: RBXScriptConnection}

                local dragging = false
                local pendingTouchStart: Vector2? = nil
                local _pendingFireVal: number? = nil
                local _firePending = false

                local function scheduleChanged(val: number)
                    _pendingFireVal = val

                    if _firePending then
                        return
                    end

                    _firePending = true

                    task.defer(function()
                        _firePending = false

                        local v = _pendingFireVal

                        _pendingFireVal = nil

                        if v ~= nil then
                            self.Changed:Fire(v)

                            if callback then
                                callback(v)
                            end
                        end
                    end)
                end
                local function applyT(t: number)
                    local raw = rangeMin + t * (rangeMax - rangeMin)
                    local val = math.clamp(snap(raw, stepVal, rangeMin), rangeMin, rangeMax)

                    if val == self.value then
                        return
                    end

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
                local function syncStrokeFromDrag()
                    if not s._enabled then
                        return
                    end

                    local targetColor = if dragging then(s._theme.AccentColor or Color3.fromHex('#4cc2ff'))else(s._theme.ElementStroke or Color3.fromHex('#2b2b2b'))

                    tween.fire(stroke, constants.tweenFast, {Color = targetColor})
                end
                local function onRelease()
                    if not dragging and not pendingTouchStart then
                        return
                    end

                    dragging = false
                    pendingTouchStart = nil

                    if s._dragChangedConn then
                        s._dragChangedConn:Disconnect()

                        s._dragChangedConn = nil
                    end
                    if s._dragEndedConn then
                        s._dragEndedConn:Disconnect()

                        s._dragEndedConn = nil
                    end

                    syncStrokeFromDrag()
                end

                s._conns.hitBegan = hit.InputBegan:Connect(function(
                    input: InputObject
                )
                    if not s._enabled then
                        return
                    end

                    local touchX: number

                    if input.UserInputType == Enum.UserInputType.Touch then
                        touchX = input.Position.X
                    else
                        touchX = variables.userInputService:GetMouseLocation().X
                    end

                    local trackLeft = track.AbsolutePosition.X
                    local trackRight = trackLeft + track.AbsoluteSize.X

                    if touchX < (trackLeft - 24) or touchX > (trackRight + KNOB_W / 2 + 24) then
                        return
                    end
                    if input.UserInputType == Enum.UserInputType.Touch then
                        pendingTouchStart = Vector2.new(input.Position.X, input.Position.Y)
                    elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = true

                        syncStrokeFromDrag()

                        local kw = knob.AbsoluteSize.X > 0 and knob.AbsoluteSize.X or KNOB_W

                        applyT(tFromMouseX(track, touchX, kw))
                    else
                        return
                    end
                    if not s._dragChangedConn then
                        s._dragChangedConn = variables.userInputService.InputChanged:Connect(function(
                            inp: InputObject
                        )
                            if pendingTouchStart and inp.UserInputType == Enum.UserInputType.Touch then
                                local dx = math.abs(inp.Position.X - pendingTouchStart.X)
                                local dy = math.abs(inp.Position.Y - pendingTouchStart.Y)

                                if dx > 5 or dy > 5 then
                                    if dx >= dy then
                                        dragging = true

                                        syncStrokeFromDrag()
                                    end

                                    pendingTouchStart = nil
                                end
                            end
                            if not dragging then
                                return
                            end
                            if inp.UserInputType ~= Enum.UserInputType.MouseMovement and inp.UserInputType ~= Enum.UserInputType.Touch then
                                return
                            end

                            local inputX: number

                            if inp.UserInputType == Enum.UserInputType.Touch then
                                inputX = inp.Position.X
                            else
                                inputX = variables.userInputService:GetMouseLocation().X
                            end

                            local kw = knob.AbsoluteSize.X > 0 and knob.AbsoluteSize.X or KNOB_W

                            applyT(tFromMouseX(track, inputX, kw))
                        end)
                    end
                    if not s._dragEndedConn then
                        s._dragEndedConn = variables.userInputService.InputEnded:Connect(function(
                            inp: InputObject
                        )
                            if inp.UserInputType ~= Enum.UserInputType.MouseButton1 and inp.UserInputType ~= Enum.UserInputType.Touch then
                                return
                            end
                            if pendingTouchStart and inp.UserInputType == Enum.UserInputType.Touch then
                                local kw = knob.AbsoluteSize.X > 0 and knob.AbsoluteSize.X or KNOB_W

                                applyT(tFromMouseX(track, inp.Position.X, kw))
                            end

                            onRelease()
                        end)
                    end
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

                s._conns.trackSize = track:GetPropertyChangedSignal('AbsoluteSize'):Connect(function(
                )
                    task.defer(refreshKnobLayout)
                end)
                s._conns.knobSize = knob:GetPropertyChangedSignal('AbsoluteSize'):Connect(function(
                )
                    task.defer(refreshKnobLayout)
                end)
                s._themeUnsub = themeUtil.subscribe(function(t)
                    s._theme = t
                    inner.BackgroundTransparency = t.ElementTransparency or 0
                    stroke.Color = if dragging then(t.AccentColor or Color3.fromHex('#4cc2ff'))else(t.ElementStroke or Color3.fromHex('#2b2b2b'))
                    label.TextColor3 = if s._enabled then(t.ContentColor or Color3.fromHex('#ffffff'))else Color3.fromHex('#555555')
                    label.FontFace = t.Font or DEFAULT_FONT
                    valLabel.TextColor3 = t.PlaceholderColor or Color3.fromHex('#9d9d9d')
                    valLabel.FontFace = t.Font or DEFAULT_FONT
                    track.BackgroundColor3 = t.SliderBackground or Color3.fromHex('#222222')
                    fill.BackgroundColor3 = t.AccentColor or Color3.fromHex('#4cc2ff')
                    fillGrad.Color = t.SliderProgress or ColorSequence.new(Color3.fromHex('#4cc2ff'), Color3.fromHex('#0093fb'))
                    knob.BackgroundColor3 = t.SliderHandle or Color3.fromRGB(255, 255, 255)
                    innerGrad.Color = t.ElementGradient or ColorSequence.new({
                        ColorSequenceKeypoint.new(0, Color3.fromHex('#2e2e2e')),
                        ColorSequenceKeypoint.new(1, Color3.fromHex('#181818')),
                    })
                    stroke.Transparency = if s._enabled then(t.ElementStrokeTransparency or 0)else 0.5
                end, frame)

                if flagKey and flagKey ~= '' then
                    flags:Set(flagKey, initValue)
                end

                s._stopDrag = onRelease

                return self
            end
            function Slider:Set(value: number, skipCallback: boolean?)
                local s = self::any

                if s.locked and not skipCallback then
                    return
                end

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
                local s = self::any

                s._enabled = enabled
                s._label.TextColor3 = if enabled then(s._theme.ContentColor or Color3.fromHex('#ffffff'))else Color3.fromHex('#555555')
                s._stroke.Transparency = if enabled then 0 else 0.5
            end
            function Slider:GetFrame(): Frame
                return self._frame
            end
            function Slider:_setShown(shown: boolean, animate: boolean?)
                local s = self::any
                local t = s._theme or {}
                local info = if animate ~= false then constants.tweenNormal else nil
                local innerTrans = if shown then(t.ElementTransparency or 0)else 1
                local strokeTrans = if shown then(t.ElementStrokeTransparency or 0)else 1
                local textTrans = if shown then 0 else 1

                if info then
                    if s._inner then
                        tween.play(s._inner, info, {BackgroundTransparency = innerTrans})
                    end
                    if s._stroke then
                        tween.play(s._stroke, info, {Transparency = strokeTrans})
                    end
                    if s._label then
                        tween.play(s._label, info, {TextTransparency = textTrans})
                    end
                    if s._valLabel then
                        tween.play(s._valLabel, info, {TextTransparency = textTrans})
                    end
                else
                    if s._inner then
                        s._inner.BackgroundTransparency = innerTrans
                    end
                    if s._stroke then
                        s._stroke.Transparency = strokeTrans
                    end
                    if s._label then
                        s._label.TextTransparency = textTrans
                    end
                    if s._valLabel then
                        s._valLabel.TextTransparency = textTrans
                    end
                end
            end
            function Slider:Destroy()
                local s = self::any

                if s._stopDrag then
                    s._stopDrag()
                end
                if s._dragChangedConn then
                    s._dragChangedConn:Disconnect()

                    s._dragChangedConn = nil
                end
                if s._dragEndedConn then
                    s._dragEndedConn:Disconnect()

                    s._dragEndedConn = nil
                end
                if s._themeUnsub then
                    s._themeUnsub()
                end
                if s._conns then
                    for _, conn in s._conns do
                        conn:Disconnect()
                    end

                    table.clear(s._conns)
                end

                self.Changed:Destroy()
                self._frame:Destroy()
            end

            moveable(Slider)
            lockable(Slider)

            return Slider
        end)()
    end,
    [36] = function()
        local wax, script, require = ImportGlobals(36)
        local ImportGlobals

        return (function(...)
            local colors = {}

            function colors.contrastColor(color: Color3): Color3
                local luminance = 0.299 * color.R + 0.587 * color.G + 0.114 * color.B

                return if luminance > 0.5 then Color3.fromRGB(0, 0, 0)else Color3.fromRGB(255, 255, 255)
            end
            function colors.contrastText(color: Color3): Color3
                local luminance = 0.299 * color.R + 0.587 * color.G + 0.114 * color.B

                return if luminance > 0.6 then Color3.fromRGB(20, 20, 20)else Color3.fromRGB(255, 255, 255)
            end
            function colors.toColorSequence(color: Color3 | ColorSequence): ColorSequence
                return if typeof(color) == 'ColorSequence'then color else ColorSequence.new(color)
            end
            function colors.toColor3(color: any, fallback: Color3?): Color3
                if typeof(color) == 'Color3' then
                    return color
                end
                if typeof(color) == 'ColorSequence' then
                    return color.Keypoints[1].Value
                end

                return fallback or Color3.fromRGB(255, 255, 255)
            end

            return colors
        end)()
    end,
    [9] = function()
        local wax, script, require = ImportGlobals(9)
        local ImportGlobals

        return (function(...)
            local constants = require(script.Parent.Parent.utility.constants)
            local flags = require(script.Parent.Parent.utility.flags)
            local runtime = require(script.Parent.Parent.utility.runtime)
            local services = require(script.Parent.Parent.utility.services)
            local signal = require(script.Parent.Parent.utility.signal)
            local themeUtil = require(script.Parent.Parent.utility.theme)
            local icons = require(script.Parent.Parent.utility.icons)
            local element = require(script.Parent.Parent.utility.element)
            local variables = require(script.Parent.Parent.utility.variables)
            local tween = require(script.Parent.Parent.utility.tween)
            local hapticEngine = require(script.Parent.Parent.utility.HapticEngine)
            local moveable = require(script.Parent.Parent.utility.moveable)
            local lockable = require(script.Parent.Parent.utility.lockable)
            local UserInputService = runtime.userInputService
            local Players = services.getService('Players')::Players
            local Teams = services.getService('Teams')::Teams
            local HEADER_H = 36
            local LIST_GAP = 4
            local OPTION_H = 34
            local CHECK_W = 20
            local SEARCH_H = 32
            local MAX_H_DEFAULT = 170
            local DEFAULT_FONT = constants.DEFAULT_FONT_MEDIUM
            local DEFAULT_FONT_SEMI = constants.DEFAULT_FONT_SEMI

            export type DropdownOption = {Label: string, Value: any}
            export type DropdownProps = {name: string?, Label: string?, Text: string?, description: string?, Tooltip: string?, flag: string?, Flag: string?, options: {any}?, Options: {any}?, value: any?, default: any?, Default: any?, multiSelect: boolean?, MultiSelect: boolean?, placeholder: string?, Placeholder: string?, searchable: boolean?, Searchable: boolean?, disabledValues: {any}?, DisabledValues: {any}?, formatDisplayValue: ((value:any) -> string)?, FormatDisplayValue: ((value:any) -> string)?, maxVisibleDropdownItems: number?, MaxVisibleDropdownItems: number?, specialType: string?, SpecialType: string?, enabled: boolean?, Enabled: boolean?, layoutOrder: number?, LayoutOrder: number?, callback: ((value:any) -> ())?, Callback: ((value:any) -> ())?, onOpen: ((self:any) -> {any}?)?}
            export type Dropdown = {value: any, Value: any, Changed: any, _frame: Frame, Set: (self:Dropdown, value:any, skipCallback:boolean?) -> (), SetValue: (self:Dropdown, value:any, skipCallback:boolean?) -> (), SetOptions: (self:Dropdown, options:{any}) -> (), SetEnabled: (self:Dropdown, enabled:boolean) -> (), GetFrame: (self:Dropdown) -> Frame, Destroy: (self:Dropdown) -> ()}

            local Dropdown = {}

            Dropdown.__index = Dropdown

            local function normalizeOptions(raw: {any}?): {DropdownOption}
                local out: {DropdownOption} = {}

                if not raw then
                    return out
                end

                for _, v in ipairs(raw)do
                    if typeof(v) == 'string' then
                        table.insert(out, {
                            Label = v,
                            Value = v,
                        })
                    elseif typeof(v) == 'table' and v.Label ~= nil and v.Value ~= nil then
                        table.insert(out, v::DropdownOption)
                    else
                        table.insert(out, {
                            Label = tostring(v),
                            Value = v,
                        })
                    end
                end

                return out
            end
            local function normalizeDefault(raw: any): {any}
                if raw == nil then
                    return {}
                end
                if typeof(raw) == 'table' then
                    return raw
                end

                return {raw}
            end
            local function getHeaderText(s: any): (string,boolean)
                if s._multiSelect then
                    local labels: {string} = {}

                    for _, opt in ipairs(s._options)do
                        if s._selectedSet[opt.Value] then
                            local display = if s._formatDisplay then s._formatDisplay(opt.Value)else opt.Label

                            table.insert(labels, display)
                        end
                    end

                    if #labels == 0 then
                        return s._placeholder, false
                    end

                    return table.concat(labels, ', '), true
                else
                    if s._selectedValue == nil then
                        return s._placeholder, false
                    end

                    for _, opt in ipairs(s._options)do
                        if opt.Value == s._selectedValue then
                            local display = if s._formatDisplay then s._formatDisplay(opt.Value)else opt.Label

                            return display, true
                        end
                    end

                    return s._placeholder, false
                end
            end

            function Dropdown.new(
                props: DropdownProps,
                theme: {[string]: any},
                parent: Instance
            ): Dropdown
                local name = props.name or props.Label or props.Text
                local flagKey: string? = props.flag or props.Flag
                local isMulti = (props.multiSelect == true) or (props.MultiSelect == true)
                local explicitSearch: boolean? = nil

                if props.searchable ~= nil then
                    explicitSearch = props.searchable
                elseif props.Searchable ~= nil then
                    explicitSearch = props.Searchable
                end

                local rawOptionsCount = #(props.options or props.Options or {})
                local isSearchable = if explicitSearch ~= nil then explicitSearch else rawOptionsCount > 8
                local isEnabled = if props.enabled ~= nil
                    then props.enabled
                    elseif props.Enabled ~= nil
                    then props.Enabled
                    else true
                local callback = props.callback or props.Callback
                local placeholder = props.placeholder or props.Placeholder or (if isMulti then'None selected'else'Select...')
                local formatDisplay = props.formatDisplayValue or props.FormatDisplayValue
                local maxVisible = props.maxVisibleDropdownItems or props.MaxVisibleDropdownItems
                local maxH = if maxVisible and maxVisible > 0 then(maxVisible * OPTION_H)else MAX_H_DEFAULT
                local special = props.specialType or props.SpecialType
                local rawDisabled = props.disabledValues or props.DisabledValues or {}
                local disabledSet: {[any]: boolean} = {}

                for _, v in ipairs(rawDisabled)do
                    disabledSet[v] = true
                end

                local initialOptions = props.options or props.Options or {}
                local specialConns: {RBXScriptConnection} = {}

                if special == 'Player' then
                    local function getPlayers(): {string}
                        local pList = {}

                        for _, p in ipairs(Players:GetPlayers())do
                            table.insert(pList, p.Name)
                        end

                        return pList
                    end

                    initialOptions = getPlayers()
                elseif special == 'Team' then
                    local function getTeams(): {string}
                        local tList = {}

                        for _, t in ipairs(Teams:GetTeams())do
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

                local selectedSet: {[any]: boolean} = {}
                local selectedVal: any = nil

                if isMulti then
                    for _, v in ipairs(defaults)do
                        selectedSet[v] = true
                    end
                else
                    selectedVal = if#defaults > 0 then defaults[1]else nil
                end

                local hasLabel = name ~= nil and #name > 0
                local LABEL_W = 90
                local leftPad = if hasLabel then(LABEL_W + 12)else 12
                local frame = Instance.new('Frame')

                frame.Name = 'Dropdown_' .. (name or 'Element')
                frame.Size = UDim2.new(1, 0, 0, HEADER_H)
                frame.BackgroundTransparency = 1
                frame.BorderSizePixel = 0
                frame.LayoutOrder = props.layoutOrder or props.LayoutOrder or 0
                frame.ClipsDescendants = false
                frame.Parent = parent

                local inner = Instance.new('Frame')

                inner.Name = 'Inner'
                inner.AnchorPoint = Vector2.new(0.5, 0)
                inner.Position = UDim2.new(0.5, 0, 0, 0)
                inner.Size = UDim2.new(1, 0, 0, HEADER_H)
                inner.BackgroundColor3 = Color3.new(1, 1, 1)
                inner.BackgroundTransparency = theme.ElementTransparency or 0
                inner.BorderSizePixel = 0
                inner.ZIndex = 2
                inner.Parent = frame

                local innerGrad = Instance.new('UIGradient')

                innerGrad.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromHex('#2e2e2e')),
                    ColorSequenceKeypoint.new(1, Color3.fromHex('#181818')),
                })
                innerGrad.Rotation = 90
                innerGrad.Parent = inner

                local innerCorner = Instance.new('UICorner')

                innerCorner.CornerRadius = UDim.new(0, 6)
                innerCorner.Parent = inner

                local stroke = Instance.new('UIStroke')

                stroke.Color = theme.ElementStroke or Color3.fromHex('#2b2b2b')
                stroke.Thickness = 1
                stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                stroke.Parent = inner

                local innerPad = Instance.new('UIPadding')

                innerPad.PaddingLeft = UDim.new(0, leftPad)
                innerPad.PaddingRight = UDim.new(0, 12)
                innerPad.Parent = inner

                local flash = Instance.new('Frame')

                flash.Name = 'Flash'
                flash.Size = UDim2.new(1, leftPad + 12, 1, 0)
                flash.Position = UDim2.new(0, -leftPad, 0, 0)
                flash.BackgroundColor3 = Color3.new(1, 1, 1)
                flash.BackgroundTransparency = 1
                flash.BorderSizePixel = 0
                flash.ZIndex = 3

                local flashCorner = Instance.new('UICorner')

                flashCorner.CornerRadius = UDim.new(0, 6)
                flashCorner.Parent = flash
                flash.Parent = inner

                local ARROW_W = 16
                local MULTI_W = 14
                local arrow = Instance.new('ImageLabel')

                arrow.Name = 'Arrow'
                arrow.AnchorPoint = Vector2.new(1, 0.5)
                arrow.Position = UDim2.new(1, 0, 0.5, 0)
                arrow.Size = UDim2.fromOffset(ARROW_W, ARROW_W)
                arrow.BackgroundTransparency = 1
                arrow.Image = icons.Resolve('lucide:chevron-down') or 'rbxassetid://88479147175134'
                arrow.ImageColor3 = theme.PlaceholderColor or Color3.fromHex('#9d9d9d')
                arrow.Rotation = 0
                arrow.ZIndex = 4
                arrow.Parent = inner

                local multiIcon: ImageLabel? = nil

                if isMulti then
                    local mico = Instance.new('ImageLabel')

                    mico.Name = 'MultiIcon'
                    mico.AnchorPoint = Vector2.new(1, 0.5)
                    mico.Position = UDim2.new(1, -(ARROW_W + 6), 0.5, 0)
                    mico.Size = UDim2.fromOffset(MULTI_W, MULTI_W)
                    mico.BackgroundTransparency = 1
                    mico.Image = icons.Resolve('lucide:layers') or icons.Resolve('lucide:list-checks') or 'rbxassetid://83827110621355'
                    mico.ImageColor3 = theme.PlaceholderColor or Color3.fromHex('#9d9d9d')
                    mico.ImageTransparency = 0.3
                    mico.ZIndex = 4
                    mico.Parent = inner
                    multiIcon = mico
                end

                local rightReserve = ARROW_W + (if isMulti then(MULTI_W + 10)else 8)
                local valueLabel = Instance.new('TextLabel')

                valueLabel.Name = 'ValueLabel'
                valueLabel.Size = UDim2.new(1, -rightReserve, 1, 0)
                valueLabel.BackgroundTransparency = 1
                valueLabel.Font = Enum.Font.GothamMedium
                valueLabel.FontFace = theme.Font or DEFAULT_FONT
                valueLabel.TextSize = 12
                valueLabel.TextXAlignment = Enum.TextXAlignment.Right
                valueLabel.TextTruncate = Enum.TextTruncate.AtEnd
                valueLabel.ZIndex = 4
                valueLabel.Parent = inner

                local outerLabel: TextLabel? = nil

                if hasLabel then
                    local lbl = Instance.new('TextLabel')

                    lbl.Name = 'Label'
                    lbl.Position = UDim2.fromOffset(12, 0)
                    lbl.Size = UDim2.fromOffset(LABEL_W, HEADER_H)
                    lbl.BackgroundTransparency = 1
                    lbl.Font = Enum.Font.GothamMedium
                    lbl.FontFace = theme.Font or DEFAULT_FONT
                    lbl.Text = name::string
                    lbl.TextSize = 13
                    lbl.TextColor3 = if isEnabled then(theme.ContentColor or Color3.fromHex('#ffffff'))else Color3.fromHex('#555555')
                    lbl.TextXAlignment = Enum.TextXAlignment.Left
                    lbl.TextTruncate = Enum.TextTruncate.AtEnd
                    lbl.ZIndex = 4
                    lbl.Parent = frame
                    outerLabel = lbl
                end

                local hit = Instance.new('TextButton')

                hit.Name = 'Hit'
                hit.Size = UDim2.fromScale(1, 1)
                hit.BackgroundTransparency = 1
                hit.Text = ''
                hit.AutoButtonColor = false
                hit.ZIndex = 5
                hit.Parent = inner

                local listWrap = Instance.new('Frame')

                listWrap.Name = 'ListWrap'
                listWrap.Position = UDim2.new(0, 0, 0, HEADER_H + LIST_GAP)
                listWrap.Size = UDim2.new(1, 0, 0, 0)
                listWrap.BackgroundColor3 = Color3.fromHex('#1a1a1a')
                listWrap.BackgroundTransparency = 1
                listWrap.BorderSizePixel = 0
                listWrap.ClipsDescendants = true
                listWrap.Visible = false
                listWrap.ZIndex = 2

                local listCorner = Instance.new('UICorner')

                listCorner.CornerRadius = UDim.new(0, 6)
                listCorner.Parent = listWrap

                local listStroke = Instance.new('UIStroke')

                listStroke.Color = theme.ElementStroke or Color3.fromHex('#2b2b2b')
                listStroke.Thickness = 1
                listStroke.Transparency = 1
                listStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                listStroke.Parent = listWrap
                listWrap.Parent = frame

                local capturedSearchBar: Frame? = nil
                local capturedSearchInner: Frame? = nil
                local capturedSearchStroke: UIStroke? = nil
                local capturedSearchIcon: TextLabel? = nil
                local capturedSearchSep: Frame? = nil
                local searchBox: TextBox? = nil

                if isSearchable then
                    local searchBar = Instance.new('Frame')

                    searchBar.Name = 'SearchBar'
                    searchBar.Size = UDim2.new(1, 0, 0, SEARCH_H)
                    searchBar.BackgroundColor3 = Color3.fromHex('#1e1e1e')
                    searchBar.BackgroundTransparency = theme.WindowTransparency or 0
                    searchBar.BorderSizePixel = 0
                    searchBar.ZIndex = 4
                    searchBar.Parent = listWrap

                    local searchPad = Instance.new('UIPadding')

                    searchPad.PaddingLeft = UDim.new(0, 12)
                    searchPad.PaddingRight = UDim.new(0, 12)
                    searchPad.PaddingTop = UDim.new(0, 5)
                    searchPad.PaddingBottom = UDim.new(0, 5)
                    searchPad.Parent = searchBar

                    local searchInner = Instance.new('Frame')

                    searchInner.Name = 'SearchInner'
                    searchInner.Size = UDim2.fromScale(1, 1)
                    searchInner.BackgroundColor3 = Color3.fromHex('#2a2a2a')
                    searchInner.BackgroundTransparency = math.clamp((theme.WindowTransparency or 0) * 0.5, 0, 0.6)
                    searchInner.BorderSizePixel = 0
                    searchInner.ZIndex = 4
                    searchInner.Parent = searchBar

                    local searchCorner = Instance.new('UICorner')

                    searchCorner.CornerRadius = UDim.new(0, 6)
                    searchCorner.Parent = searchInner

                    local searchStroke = Instance.new('UIStroke')

                    searchStroke.Color = theme.ElementStroke or Color3.fromHex('#2b2b2b')
                    searchStroke.Thickness = 1
                    searchStroke.Transparency = 0.4
                    searchStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                    searchStroke.Parent = searchInner

                    local searchIcon = Instance.new('TextLabel')

                    searchIcon.Name = 'SearchIcon'
                    searchIcon.Size = UDim2.fromOffset(16, 16)
                    searchIcon.AnchorPoint = Vector2.new(0, 0.5)
                    searchIcon.Position = UDim2.new(0, 6, 0.5, 0)
                    searchIcon.BackgroundTransparency = 1
                    searchIcon.Font = Enum.Font.GothamMedium
                    searchIcon.Text = '\u{2315}'
                    searchIcon.TextSize = 13
                    searchIcon.TextColor3 = theme.PlaceholderColor or Color3.fromHex('#9d9d9d')
                    searchIcon.ZIndex = 5
                    searchIcon.Parent = searchInner

                    local sb = Instance.new('TextBox')

                    sb.Name = 'SearchBox'
                    sb.Size = UDim2.new(1, -26, 1, 0)
                    sb.Position = UDim2.fromOffset(24, 0)
                    sb.BackgroundTransparency = 1
                    sb.BorderSizePixel = 0
                    sb.Font = Enum.Font.GothamMedium
                    sb.PlaceholderText = 'Search...'
                    sb.PlaceholderColor3 = Color3.fromHex('#555555')
                    sb.Text = ''
                    sb.TextSize = 12
                    sb.TextColor3 = theme.ContentColor or Color3.fromHex('#ffffff')
                    sb.TextXAlignment = Enum.TextXAlignment.Left
                    sb.ClearTextOnFocus = false
                    sb.ZIndex = 5
                    sb.Parent = searchInner
                    searchBox = sb

                    local sep = Instance.new('Frame')

                    sep.Name = 'SearchSep'
                    sep.Size = UDim2.new(1, 0, 0, 1)
                    sep.Position = UDim2.new(0, 0, 0, SEARCH_H)
                    sep.BackgroundColor3 = theme.ElementStroke or Color3.fromHex('#2b2b2b')
                    sep.BackgroundTransparency = 0.5
                    sep.BorderSizePixel = 0
                    sep.ZIndex = 4
                    sep.Parent = listWrap
                    capturedSearchBar = searchBar
                    capturedSearchInner = searchInner
                    capturedSearchStroke = searchStroke
                    capturedSearchIcon = searchIcon
                    capturedSearchSep = sep
                end

                local scrollTopOffset = if isSearchable then SEARCH_H else 0
                local scroll = Instance.new('ScrollingFrame')

                scroll.Name = 'OptionScroll'
                scroll.Position = UDim2.fromOffset(0, scrollTopOffset)
                scroll.Size = UDim2.new(1, 0, 1, -scrollTopOffset)
                scroll.BackgroundTransparency = 1
                scroll.BorderSizePixel = 0
                scroll.ScrollBarThickness = 3
                scroll.ScrollBarImageColor3 = theme.ElementStroke or Color3.fromHex('#2b2b2b')
                scroll.CanvasSize = UDim2.fromOffset(0, 0)
                scroll.AutomaticCanvasSize = Enum.AutomaticSize.None
                scroll.ScrollingDirection = Enum.ScrollingDirection.Y
                scroll.ClipsDescendants = true
                scroll.ZIndex = 3
                scroll.Parent = listWrap

                local listLayout = Instance.new('UIListLayout')

                listLayout.FillDirection = Enum.FillDirection.Vertical
                listLayout.SortOrder = Enum.SortOrder.LayoutOrder
                listLayout.Padding = UDim.new(0, 0)
                listLayout.Parent = scroll

                local self = setmetatable({}, Dropdown)::Dropdown

                self._frame = frame
                self.Changed = signal.new()

                local initVal: any = if isMulti then{}else nil

                if isMulti then
                    local arr = {}

                    for _, o in ipairs(normOpts)do
                        if selectedSet[o.Value] then
                            table.insert(arr, o.Value)
                        end
                    end

                    initVal = arr
                else
                    initVal = selectedVal
                end

                self.value = initVal
                self.Value = initVal

                local s = self::any

                s._enabled = isEnabled
                s._open = false
                s._multiSelect = isMulti
                s._searchEnabled = isSearchable
                s._searchQuery = ''
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
                s._conns = {}::{[string]: RBXScriptConnection}
                s._optConns = {}::{RBXScriptConnection}
                s._specialConns = specialConns

                local function getListH(): number
                    return s._targetH + (if s._searchEnabled then SEARCH_H else 0)
                end

                local refreshOptionTheme: () -> () = nil::any
                local searchDebounceThread: thread? = nil

                local function closeDropdown()
                    if not s._open then
                        return
                    end

                    s._open = false

                    if searchDebounceThread then
                        pcall(task.cancel, searchDebounceThread)

                        searchDebounceThread = nil
                    end
                    if s._searchEnabled and s._searchBox then
                        s._searchBox.Text = ''
                        s._searchQuery = ''
                    end

                    arrow.Rotation = 0

                    tween.fire(stroke, constants.tweenFast, {
                        Color = s._theme.ElementStroke or Color3.fromHex('#2b2b2b'),
                    })

                    listWrap.Visible = false
                    listWrap.Size = UDim2.new(1, 0, 0, 0)
                    listWrap.Position = UDim2.new(0, 0, 0, HEADER_H + LIST_GAP)
                    listWrap.BackgroundTransparency = 1
                    listStroke.Transparency = 1
                    frame.Size = UDim2.new(1, 0, 0, HEADER_H)

                    if s._outsideUnsub then
                        s._outsideUnsub()

                        s._outsideUnsub = nil
                    end

                    frame.ZIndex = s._originalZIndex or 1
                    s._originalZIndex = nil
                end
                local function openDropdown()
                    if s._open or not s._enabled then
                        return
                    end
                    if props.onOpen then
                        local ok, res = pcall(props.onOpen, self)

                        if ok and type(res) == 'table' then
                            self:SetOptions(res)
                        end
                    end

                    s._open = true

                    local fullH = getListH()

                    if s._optionVisualsDirty then
                        refreshOptionTheme()

                        s._optionVisualsDirty = false
                    end
                    if not s._originalZIndex then
                        s._originalZIndex = frame.ZIndex
                    end

                    frame.ZIndex = 32766
                    listWrap.Position = UDim2.new(0, 0, 0, HEADER_H + LIST_GAP)
                    arrow.Rotation = 180

                    tween.fire(stroke, constants.tweenFast, {
                        Color = s._theme.AccentColor or Color3.fromHex('#4cc2ff'),
                    })

                    listWrap.Visible = true
                    listWrap.Size = UDim2.new(1, 0, 0, fullH)
                    listWrap.BackgroundTransparency = s._theme.WindowTransparency or 0
                    listStroke.Transparency = 0
                    frame.Size = UDim2.new(1, 0, 0, HEADER_H + LIST_GAP + fullH)

                    if s._outsideUnsub then
                        s._outsideUnsub()

                        s._outsideUnsub = nil
                    end

                    s._outsideUnsub = element.onOutsideClick({frame, listWrap}, closeDropdown)

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

                type OptionEntry = {opt: DropdownOption, frame: Frame, label: TextLabel, check: ImageLabel?, sep: Frame?}

                local optionEntries: {OptionEntry} = {}

                local function checkIcon(selected: boolean): string
                    return if selected then(icons.Resolve('lucide:square-check') or 'rbxassetid://88479147175134')else(icons.Resolve('lucide:square') or 'rbxassetid://11928872664')
                end
                local function applySearchFilter()
                    local query = s._searchQuery or ''
                    local visibleCount = 0

                    for _, entry in ipairs(optionEntries)do
                        local matches = query == '' or string.find(entry.labelLower, query, 1, true) ~= nil

                        entry.frame.Visible = matches

                        if matches then
                            visibleCount += 1

                            entry.frame.LayoutOrder = visibleCount

                            if entry.sep then
                                entry.sep.Visible = true
                            end
                        end
                    end

                    local fullH = visibleCount * OPTION_H

                    scroll.CanvasSize = UDim2.fromOffset(0, fullH)
                    s._targetH = math.min(fullH, s._maxH)

                    if s._open then
                        local panelH = getListH()

                        listWrap.Size = UDim2.new(1, 0, 0, panelH)
                        frame.Size = UDim2.new(1, 0, 0, HEADER_H + LIST_GAP + panelH)
                    end
                end
                local function createOptionRows()
                    for _, c in ipairs(s._optConns)do
                        c:Disconnect()
                    end

                    table.clear(s._optConns)
                    table.clear(optionEntries)

                    for _, child in ipairs(scroll:GetChildren())do
                        if child:IsA('Frame') then
                            child:Destroy()
                        end
                    end

                    local optCount = #s._options

                    for i, opt in ipairs(s._options)do
                        local isSelected = if s._multiSelect then s._selectedSet[opt.Value] == true else s._selectedValue == opt.Value
                        local isDisabled = s._disabledSet[opt.Value] == true
                        local optFrame = Instance.new('Frame')

                        optFrame.Name = 'Option_' .. i
                        optFrame.Size = UDim2.new(1, 0, 0, OPTION_H)
                        optFrame.BackgroundColor3 = (s._theme.WindowColor and s._theme.WindowColor.Keypoints[1].Value) or Color3.fromHex('#1a1a1a')
                        optFrame.BackgroundTransparency = 1
                        optFrame.BorderSizePixel = 0
                        optFrame.LayoutOrder = i
                        optFrame.ZIndex = 3

                        local checkLabel: any = nil

                        if s._multiSelect then
                            local ck = Instance.new('ImageLabel')

                            ck.Name = 'Check'
                            ck.Size = UDim2.fromOffset(14, 14)
                            ck.AnchorPoint = Vector2.new(0.5, 0.5)
                            ck.Position = UDim2.new(0, 4 + CHECK_W / 2, 0.5, 0)
                            ck.BackgroundTransparency = 1
                            ck.Image = checkIcon(isSelected)
                            ck.ImageColor3 = if isDisabled then Color3.fromHex('#555555')else if isSelected then(s._theme.AccentColor or Color3.fromHex('#4cc2ff'))else Color3.fromHex('#555555')
                            ck.ZIndex = 4
                            ck.Parent = optFrame
                            checkLabel = ck
                        end

                        local labelXOffset = if s._multiSelect then(CHECK_W + 4)else 12
                        local labelWOffset = if s._multiSelect then-(CHECK_W + 16)else
-24
                        local displayText = if s._formatDisplay then s._formatDisplay(opt.Value)else opt.Label
                        local textColor = if isDisabled
                            then Color3.fromHex('#555555')
                            elseif isSelected
                            then(s._theme.AccentColor or Color3.fromHex('#4cc2ff'))
                            else(s._theme.PlaceholderColor or Color3.fromHex('#9d9d9d'))
                        local optLabel = Instance.new('TextLabel')

                        optLabel.Name = 'OptionLabel'
                        optLabel.Size = UDim2.new(1, labelWOffset, 1, 0)
                        optLabel.Position = UDim2.fromOffset(labelXOffset, 0)
                        optLabel.BackgroundTransparency = 1
                        optLabel.Font = Enum.Font.GothamMedium
                        optLabel.FontFace = s._theme.Font or DEFAULT_FONT
                        optLabel.Text = displayText
                        optLabel.TextSize = 12
                        optLabel.TextColor3 = textColor
                        optLabel.TextXAlignment = Enum.TextXAlignment.Center
                        optLabel.TextTruncate = Enum.TextTruncate.AtEnd
                        optLabel.ZIndex = 4
                        optLabel.Parent = optFrame

                        if isDisabled then
                            local disabledTag = Instance.new('TextLabel')

                            disabledTag.Name = 'DisabledTag'
                            disabledTag.AnchorPoint = Vector2.new(1, 0.5)
                            disabledTag.Position = UDim2.new(1, -8, 0.5, 0)
                            disabledTag.Size = UDim2.fromOffset(36, 14)
                            disabledTag.BackgroundColor3 = Color3.fromHex('#2a2a2a')
                            disabledTag.BorderSizePixel = 0
                            disabledTag.Font = Enum.Font.GothamMedium
                            disabledTag.Text = 'off'
                            disabledTag.TextSize = 9
                            disabledTag.TextColor3 = Color3.fromHex('#555555')
                            disabledTag.TextXAlignment = Enum.TextXAlignment.Center
                            disabledTag.ZIndex = 4

                            local dtCorner = Instance.new('UICorner')

                            dtCorner.CornerRadius = UDim.new(1, 0)
                            dtCorner.Parent = disabledTag
                            disabledTag.Parent = optFrame
                        end

                        local sep: Frame? = nil

                        if i < optCount then
                            local sFrame = Instance.new('Frame')

                            sFrame.Size = UDim2.new(1, -24, 0, 1)
                            sFrame.Position = UDim2.new(0, 12, 1, -1)
                            sFrame.BackgroundColor3 = s._theme.ElementStroke or Color3.fromHex('#2b2b2b')
                            sFrame.BackgroundTransparency = 0.7
                            sFrame.BorderSizePixel = 0
                            sFrame.ZIndex = 4
                            sFrame.Parent = optFrame
                            sep = sFrame
                        end

                        local optHit = Instance.new('TextButton')

                        optHit.Name = 'Hit'
                        optHit.Size = UDim2.fromScale(1, 1)
                        optHit.BackgroundTransparency = 1
                        optHit.Text = ''
                        optHit.AutoButtonColor = false
                        optHit.ZIndex = 5
                        optHit.Parent = optFrame

                        if not isDisabled then
                            if not variables.isTouchOnly then
                                table.insert(s._optConns, optHit.MouseEnter:Connect(function(
                                )
                                    optFrame.BackgroundTransparency = 0.85
                                    optFrame.BackgroundColor3 = Color3.fromHex('#252525')

                                    local isSel = if s._multiSelect then s._selectedSet[opt.Value] == true else s._selectedValue == opt.Value

                                    if not isSel then
                                        optLabel.TextColor3 = s._theme.ContentColor or Color3.fromHex('#ffffff')
                                    end
                                end))
                                table.insert(s._optConns, optHit.MouseLeave:Connect(function(
                                )
                                    optFrame.BackgroundTransparency = 1
                                    optFrame.BackgroundColor3 = (s._theme.WindowColor and s._theme.WindowColor.Keypoints[1].Value) or Color3.fromHex('#1a1a1a')

                                    local isSel = if s._multiSelect then s._selectedSet[opt.Value] == true else s._selectedValue == opt.Value

                                    if not isSel then
                                        optLabel.TextColor3 = s._theme.PlaceholderColor or Color3.fromHex('#9d9d9d')
                                    end
                                end))
                            end

                            table.insert(s._optConns, optHit.Activated:Connect(function(
                            )
                                if not s._enabled then
                                    return
                                end
                                if s._multiSelect then
                                    if s._selectedSet[opt.Value] then
                                        s._selectedSet[opt.Value] = nil
                                        optLabel.TextColor3 = s._theme.PlaceholderColor or constants.COLORS.TEXT_MUTED

                                        if checkLabel then
                                            local ck = checkLabel::ImageLabel

                                            ck.Image = checkIcon(false)
                                            ck.ImageColor3 = constants.COLORS.TEXT_DISABLED
                                        end
                                    else
                                        s._selectedSet[opt.Value] = true
                                        optLabel.TextColor3 = s._theme.AccentColor or constants.COLORS.ACCENT

                                        if checkLabel then
                                            local ck = checkLabel::ImageLabel

                                            ck.Image = checkIcon(true)
                                            ck.ImageColor3 = s._theme.AccentColor or constants.COLORS.ACCENT
                                        end
                                    end

                                    local arr: {any} = {}

                                    for _, o in ipairs(s._options)do
                                        if s._selectedSet[o.Value] then
                                            table.insert(arr, o.Value)
                                        end
                                    end

                                    self.value = arr
                                    self.Value = arr

                                    local txt, has = getHeaderText(s)

                                    valueLabel.Text = txt
                                    valueLabel.TextColor3 = if has then(s._theme.ContentColor or Color3.fromHex('#ffffff'))else Color3.fromHex('#555555')

                                    if flagKey then
                                        flags:Set(flagKey, arr)
                                    end

                                    self.Changed:Fire(arr)

                                    if callback then
                                        task.spawn(callback, arr)
                                    end
                                else
                                    for _, entry in ipairs(optionEntries)do
                                        entry.label.TextColor3 = s._theme.PlaceholderColor or Color3.fromHex('#9d9d9d')
                                    end

                                    optLabel.TextColor3 = s._theme.AccentColor or Color3.fromHex('#4cc2ff')
                                    s._selectedValue = opt.Value
                                    self.value = opt.Value
                                    self.Value = opt.Value

                                    local txt, has = getHeaderText(s)

                                    valueLabel.Text = txt
                                    valueLabel.TextColor3 = if has then(s._theme.ContentColor or Color3.fromHex('#ffffff'))else Color3.fromHex('#555555')

                                    if flagKey then
                                        flags:Set(flagKey, opt.Value)
                                    end

                                    self.Changed:Fire(opt.Value)

                                    if callback then
                                        task.spawn(callback, opt.Value)
                                    end

                                    closeDropdown()
                                end
                            end))
                        end

                        optFrame.Parent = scroll

                        table.insert(optionEntries, {
                            opt = opt,
                            frame = optFrame,
                            label = optLabel,
                            check = checkLabel,
                            sep = sep,
                            labelLower = opt.Label:lower(),
                        })
                    end

                    applySearchFilter()
                end
                local function updateOptionVisuals()
                    if #optionEntries == 0 then
                        return
                    end

                    local accentCol = s._theme.AccentColor or Color3.fromHex('#4cc2ff')
                    local placeholderCol = s._theme.PlaceholderColor or Color3.fromHex('#9d9d9d')

                    for _, entry in ipairs(optionEntries)do
                        local isSelected = if s._multiSelect then s._selectedSet[entry.opt.Value] == true else s._selectedValue == entry.opt.Value
                        local isDisabled = s._disabledSet[entry.opt.Value] == true

                        if not isDisabled then
                            entry.label.TextColor3 = if isSelected then accentCol else placeholderCol

                            if entry.check then
                                entry.check.Image = checkIcon(isSelected)
                                entry.check.ImageColor3 = if isSelected then accentCol else Color3.fromHex('#555555')
                            end
                        end
                    end
                end

                s._buildOptions = createOptionRows
                s._updateVisuals = updateOptionVisuals
                s._applySearchFilter = applySearchFilter

                createOptionRows()

                refreshOptionTheme = function()
                    if #optionEntries == 0 then
                        return
                    end

                    local t = s._theme or {}
                    local winCol = if t.WindowColor and typeof(t.WindowColor) == 'ColorSequence' and #t.WindowColor.Keypoints > 0 then t.WindowColor.Keypoints[1].Value else Color3.fromHex('#1a1a1a')
                    local strokeCol = t.ElementStroke or constants.COLORS.STROKE
                    local accentCol = t.AccentColor or constants.COLORS.ACCENT
                    local placeholderCol = t.PlaceholderColor or constants.COLORS.TEXT_MUTED

                    for _, entry in ipairs(optionEntries)do
                        entry.frame.BackgroundColor3 = winCol

                        local isSelected = if s._multiSelect then s._selectedSet[entry.opt.Value] == true else s._selectedValue == entry.opt.Value
                        local isDisabled = s._disabledSet[entry.opt.Value] == true

                        if not isDisabled then
                            entry.label.TextColor3 = if isSelected then accentCol else placeholderCol
                            entry.label.FontFace = t.Font or DEFAULT_FONT

                            if entry.check then
                                entry.check.ImageColor3 = if isSelected then accentCol else constants.COLORS.TEXT_DISABLED
                            end
                        end
                        if entry.sep then
                            entry.sep.BackgroundColor3 = strokeCol
                        end
                    end
                end

                local initTxt, initHas = getHeaderText(s)

                valueLabel.Text = initTxt
                valueLabel.TextColor3 = if initHas then(theme.ContentColor or Color3.fromHex('#ffffff'))else Color3.fromHex('#555555')

                if searchBox then
                    s._conns.search = searchBox:GetPropertyChangedSignal('Text'):Connect(function(
                    )
                        s._searchQuery = searchBox.Text:lower()

                        if searchDebounceThread then
                            pcall(task.cancel, searchDebounceThread)

                            searchDebounceThread = nil
                        end

                        searchDebounceThread = task.delay(0.08, function()
                            searchDebounceThread = nil

                            applySearchFilter()
                        end)
                    end)
                end

                s._conns.hitClick = hit.Activated:Connect(function()
                    if not s._enabled then
                        return
                    end
                    if s._open then
                        closeDropdown()
                    else
                        openDropdown()
                    end
                end)

                if special == 'Player' then
                    table.insert(specialConns, Players.PlayerAdded:Connect(function(
                    )
                        local pList = {}

                        for _, p in ipairs(Players:GetPlayers())do
                            table.insert(pList, p.Name)
                        end

                        self:SetOptions(pList)
                    end))
                    table.insert(specialConns, Players.PlayerRemoving:Connect(function(
                    )
                        local pList = {}

                        for _, p in ipairs(Players:GetPlayers())do
                            table.insert(pList, p.Name)
                        end

                        self:SetOptions(pList)
                    end))
                elseif special == 'Team' then
                    table.insert(specialConns, Teams.ChildAdded:Connect(function(
                    )
                        local tList = {}

                        for _, t in ipairs(Teams:GetTeams())do
                            table.insert(tList, t.Name)
                        end

                        self:SetOptions(tList)
                    end))
                    table.insert(specialConns, Teams.ChildRemoved:Connect(function(
                    )
                        local tList = {}

                        for _, t in ipairs(Teams:GetTeams())do
                            table.insert(tList, t.Name)
                        end

                        self:SetOptions(tList)
                    end))
                end

                s._themeUnsub = themeUtil.subscribe(function(t)
                    s._theme = t
                    inner.BackgroundTransparency = t.ElementTransparency or 0
                    stroke.Color = if s._open then(t.AccentColor or Color3.fromHex('#4cc2ff'))else(t.ElementStroke or Color3.fromHex('#2b2b2b'))
                    stroke.Transparency = t.ElementStrokeTransparency or 0

                    if outerLabel then
                        outerLabel.TextColor3 = if s._enabled then(t.ContentColor or Color3.fromHex('#ffffff'))else Color3.fromHex('#555555')
                        outerLabel.FontFace = t.Font or DEFAULT_FONT
                    end

                    valueLabel.FontFace = t.Font or DEFAULT_FONT

                    do
                        local _, has = getHeaderText(s)

                        valueLabel.TextColor3 = if has then(t.ContentColor or Color3.fromHex('#ffffff'))else Color3.fromHex('#555555')
                    end

                    arrow.ImageColor3 = t.PlaceholderColor or Color3.fromHex('#9d9d9d')

                    if multiIcon then
                        multiIcon.ImageColor3 = t.PlaceholderColor or Color3.fromHex('#9d9d9d')
                    end

                    listStroke.Color = t.ElementStroke or Color3.fromHex('#2b2b2b')
                    scroll.ScrollBarImageColor3 = t.ElementStroke or Color3.fromHex('#2b2b2b')
                    innerGrad.Color = t.ElementGradient or ColorSequence.new({
                        ColorSequenceKeypoint.new(0, Color3.fromHex('#2e2e2e')),
                        ColorSequenceKeypoint.new(1, Color3.fromHex('#181818')),
                    })
                    listWrap.BackgroundColor3 = if t.WindowColor then t.WindowColor.Keypoints[1].Value else Color3.fromHex('#1a1a1a')

                    if s._open then
                        listWrap.BackgroundTransparency = t.WindowTransparency or 0
                    end
                    if capturedSearchBar then
                        capturedSearchBar.BackgroundColor3 = t.TitleBarColor or Color3.fromHex('#1e1e1e')
                        capturedSearchBar.BackgroundTransparency = t.WindowTransparency or 0
                    end
                    if capturedSearchInner then
                        capturedSearchInner.BackgroundColor3 = t.NeutralButton or Color3.fromHex('#2a2a2a')
                        capturedSearchInner.BackgroundTransparency = math.clamp((t.WindowTransparency or 0) * 0.5, 0, 0.6)
                    end
                    if capturedSearchStroke then
                        capturedSearchStroke.Color = t.ElementStroke or Color3.fromHex('#2b2b2b')
                    end
                    if capturedSearchIcon then
                        capturedSearchIcon.TextColor3 = t.PlaceholderColor or Color3.fromHex('#9d9d9d')
                    end
                    if searchBox then
                        local sb = searchBox::TextBox

                        sb.TextColor3 = t.ContentColor or Color3.fromHex('#ffffff')
                    end
                    if capturedSearchSep then
                        capturedSearchSep.BackgroundColor3 = t.ElementStroke or Color3.fromHex('#2b2b2b')
                    end
                    if #optionEntries > 0 then
                        if s._open then
                            refreshOptionTheme()
                        else
                            s._optionVisualsDirty = true
                        end
                    end
                end, frame)

                if flagKey and flagKey ~= '' then
                    flags:Set(flagKey, initVal)
                end

                return self
            end
            function Dropdown:SetOptions(options: {any})
                local s = self::any

                if s._open then
                    s._closeDropdown()
                end

                s._options = normalizeOptions(options)

                if s._multiSelect then
                    local newSet: {[any]: boolean} = {}

                    for _, opt in ipairs(s._options)do
                        if s._selectedSet[opt.Value] then
                            newSet[opt.Value] = true
                        end
                    end

                    s._selectedSet = newSet

                    local arr: {any} = {}

                    for _, opt in ipairs(s._options)do
                        if s._selectedSet[opt.Value] then
                            table.insert(arr, opt.Value)
                        end
                    end

                    self.value = arr
                    self.Value = arr
                else
                    local found = false

                    for _, opt in ipairs(s._options)do
                        if opt.Value == s._selectedValue then
                            found = true

                            break
                        end
                    end

                    if not found then
                        s._selectedValue = nil
                        self.value = nil
                        self.Value = nil
                    end
                end

                local txt, has = getHeaderText(s)

                s._valueLabel.Text = txt
                s._valueLabel.TextColor3 = if has then(s._theme.ContentColor or Color3.fromHex('#ffffff'))else Color3.fromHex('#555555')

                s._buildOptions()
            end
            function Dropdown:Set(value: any, skipCallback: boolean?)
                local s = self::any

                if s.locked and not skipCallback then
                    return
                end
                if s._multiSelect then
                    s._selectedSet = {}

                    local outArr: {any} = {}

                    if typeof(value) == 'table' then
                        for k, v in pairs(value)do
                            if typeof(k) == 'number' then
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

                    for _, opt in ipairs(s._options)do
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
                s._valueLabel.TextColor3 = if has then(s._theme.ContentColor or Color3.fromHex('#ffffff'))else Color3.fromHex('#555555')

                if s._updateVisuals and #s._options > 0 then
                    s._updateVisuals()
                else
                    s._buildOptions()
                end
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
                local s = self::any

                s._enabled = enabled
                s._stroke.Transparency = if enabled then 0 else 0.5

                if s._outerLabel then
                    s._outerLabel.TextColor3 = if enabled then(s._theme.ContentColor or Color3.fromHex('#ffffff'))else Color3.fromHex('#555555')
                end
                if not enabled and s._open then
                    s._closeDropdown()
                end
            end
            function Dropdown:GetFrame(): Frame
                return self._frame
            end
            function Dropdown:_setShown(shown: boolean, animate: boolean?)
                local s = self::any
                local t = s._theme or {}
                local info = if animate ~= false then constants.tweenNormal else nil
                local innerTrans = if shown then(t.ElementTransparency or 0)else 1
                local strokeTrans = if shown then(t.ElementStrokeTransparency or 0)else 1
                local textTrans = if shown then 0 else 1

                if info then
                    if s._inner then
                        tween.play(s._inner, info, {BackgroundTransparency = innerTrans})
                    end
                    if s._stroke then
                        tween.play(s._stroke, info, {Transparency = strokeTrans})
                    end
                    if s._valueLabel then
                        tween.play(s._valueLabel, info, {TextTransparency = textTrans})
                    end
                    if s._outerLabel then
                        tween.play(s._outerLabel, info, {TextTransparency = textTrans})
                    end
                else
                    if s._inner then
                        s._inner.BackgroundTransparency = innerTrans
                    end
                    if s._stroke then
                        s._stroke.Transparency = strokeTrans
                    end
                    if s._valueLabel then
                        s._valueLabel.TextTransparency = textTrans
                    end
                    if s._outerLabel then
                        s._outerLabel.TextTransparency = textTrans
                    end
                end
            end
            function Dropdown:Destroy()
                local s = self::any

                if s._themeUnsub then
                    s._themeUnsub()
                end
                if s._outsideUnsub then
                    s._outsideUnsub()

                    s._outsideUnsub = nil
                end
                if s._conns then
                    for _, conn in s._conns do
                        conn:Disconnect()
                    end

                    table.clear(s._conns)
                end
                if s._optConns then
                    for _, conn in s._optConns do
                        conn:Disconnect()
                    end

                    table.clear(s._optConns)
                end
                if s._specialConns then
                    for _, conn in s._specialConns do
                        conn:Disconnect()
                    end

                    table.clear(s._specialConns)
                end

                self.Changed:Destroy()
                self._frame:Destroy()
            end

            Dropdown.Refresh = Dropdown.SetOptions

            moveable(Dropdown)
            lockable(Dropdown)

            return Dropdown
        end)()
    end,
    [43] = function()
        local wax, script, require = ImportGlobals(43)
        local ImportGlobals

        return (function(...)
            export type FlagValue = boolean | number | string | {string} | Color3 | EnumItem
            export type FlagListener = (key:string, value:FlagValue) -> ()
            export type FlagsRegistry = {[string]: FlagValue, Set: (self:FlagsRegistry, key:string, value:FlagValue) -> (), Get: (self:FlagsRegistry, key:string) -> FlagValue?, GetAll: (self:FlagsRegistry) -> {[string]: FlagValue}, Clear: (self:FlagsRegistry) -> (), Subscribe: (self:FlagsRegistry, fn:FlagListener) -> () -> (), Unsubscribe: (self:FlagsRegistry, fn:FlagListener) -> ()}

            local store: {[string]: FlagValue} = {}
            local listeners: {[any]: boolean} = {}
            local flags = {}::FlagsRegistry

            function flags:Set(key: string, value: FlagValue)
                store[key] = value

                for fn in pairs(listeners)do
                    pcall(fn, key, value)
                end
            end
            function flags:Get(key: string): FlagValue?
                return store[key]
            end
            function flags:GetAll(): {[string]: FlagValue}
                return table.clone(store)
            end
            function flags:Clear()
                table.clear(store)
            end
            function flags:Subscribe(fn: FlagListener): () -> ()
                listeners[fn] = true

                return function()
                    listeners[fn] = nil
                end
            end
            function flags:Unsubscribe(fn: FlagListener)
                listeners[fn] = nil
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
                    flags:Set(key, value)
                end,
            }

            setmetatable(flags::any, mt)

            return flags
        end)()
    end,
    [64] = function()
        local wax, script, require = ImportGlobals(64)
        local ImportGlobals

        return (function(...)
            local variables = require(script.Parent.variables)
            local textService = variables.textService
            local textMetrics = {}
            local widthCache: {[string]: number} = {}
            local widthCacheCount = 0
            local CACHE_CAP = 1024

            local function getTextBounds(params: GetTextBoundsParams): Vector2?
                local ok, bounds = pcall(textService.GetTextBoundsAsync, textService, params)

                return if ok and typeof(bounds) == 'Vector2'then bounds else nil
            end

            function textMetrics.textWidth(
                font: Font,
                size: number,
                text: any
            ): number
                text = tostring(text)

                local key = tostring(font.Family) .. '|' .. tostring(font.Weight) .. '|' .. tostring(font.Style) .. '|' .. tostring(size) .. '|' .. text
                local cached = widthCache[key]

                if cached then
                    return cached
                end

                local params = Instance.new('GetTextBoundsParams')

                params.Text = text
                params.Font = font
                params.Size = size
                params.Width = math.huge

                local bounds = getTextBounds(params)
                local width: number

                if bounds then
                    width = math.ceil(bounds.X)
                else
                    local length = utf8.len(text) or #text

                    return math.ceil(size * 0.55 * length)
                end
                if widthCacheCount >= CACHE_CAP then
                    widthCache = {}
                    widthCacheCount = 0
                end

                widthCache[key] = width

                widthCacheCount += 1

                return width
            end
            function textMetrics.textHeight(
                font: Font,
                size: number,
                text: any,
                width: number
            ): number
                local params = Instance.new('GetTextBoundsParams')

                params.Text = tostring(text)
                params.Font = font
                params.Size = size
                params.Width = width

                local bounds = getTextBounds(params)

                return if bounds then math.ceil(bounds.Y)else size
            end

            return textMetrics
        end)()
    end,
    [53] = function()
        local wax, script, require = ImportGlobals(53)
        local ImportGlobals

        return (function(...)
            local image = require(script.Parent.image)
            local FontLoader = require(script.Parent.fontLoader)
            local MediaService = {}

            MediaService.__index = MediaService

            local fontLoader = FontLoader.new()

            function MediaService:preloadImages(
                manifest: {[number]: string},
                onSettled: ((failed:number) -> ())?
            ): (boolean,number)
                return image.preload(manifest, onSettled)
            end
            function MediaService:assignImage(
                instance: Instance,
                property: string,
                value: unknown
            )
                image.assign(instance, property, value)
            end
            function MediaService:resolveImage(value: unknown): string
                return image.resolve(value)
            end
            function MediaService:setOnBlock(fn: (value:unknown) -> ())
                image.onBlock = fn
            end
            function MediaService:avatar(userId: number, onReady: ((uri:string) -> ())?): string
                return image.avatar(userId, onReady)
            end
            function MediaService:loadFont(id: number | string, opts: {weight: Enum.FontWeight?, style: Enum.FontStyle?, saveToDisk: boolean?, skipCache: boolean?, fallback: Font?}?): Font?
                return fontLoader:load(id, opts)
            end
            function MediaService:resolveFont(id: number | string): Font?
                return fontLoader:resolve(id)
            end
            function MediaService:bindFont(
                instance: Instance,
                property: string,
                id: number | string,
                opts: {weight: Enum.FontWeight?, style: Enum.FontStyle?, saveToDisk: boolean?, fallback: Font?}?
            )
                fontLoader:bind(instance, property, id, opts)
            end

            return MediaService
        end)()
    end,
    [54] = function()
        local wax, script, require = ImportGlobals(54)
        local ImportGlobals

        return (function(...)
            local function moveable<T>(class: T): T
                local target = class::any

                function target:MoveTo(index: number)
                    if self.tab and self.tab._moveElement then
                        self.tab:_moveElement(self, index)
                    end
                end
                function target:MoveToTop()
                    if self.tab and self.tab._moveElement then
                        self.tab:_moveElement(self, 1)
                    end
                end
                function target:MoveToBottom()
                    if self.tab and self.tab._moveElement then
                        self.tab:_moveElement(self, #self.tab._elements)
                    end
                end
                function target:MoveUp()
                    if not self.tab then
                        return
                    end

                    local idx = table.find(self.tab._elements, self)

                    if idx then
                        self.tab:_moveElement(self, idx - 1)
                    end
                end
                function target:MoveDown()
                    if not self.tab then
                        return
                    end

                    local idx = table.find(self.tab._elements, self)

                    if idx then
                        self.tab:_moveElement(self, idx + 1)
                    end
                end

                return class
            end

            return moveable
        end)()
    end,
    [66] = function()
        local wax, script, require = ImportGlobals(66)
        local ImportGlobals

        return (function(...)
            local runtime = require(script.Parent.runtime)
            local constants = require(script.Parent.constants)
            local tween = {}

            function tween.play(
                instance: Instance,
                tweenInfo: TweenInfo,
                props: {[string]: any}
            ): Tween
                local t = runtime.tweenService:Create(instance, tweenInfo, props)

                t:Play()

                return t
            end
            function tween.fire(
                instance: Instance,
                tweenInfo: TweenInfo,
                props: {[string]: any}
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
            ): (Tween,Tween)
                local fadeIn = runtime.tweenService:Create(instance, tweenIn, {BackgroundTransparency = 0})
                local fadeOut = runtime.tweenService:Create(instance, tweenOut, {BackgroundTransparency = 1})

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
                    return tween.play(instance, constants.pillResizeInfo, {Size = targetSize})
                else
                    instance.Size = targetSize

                    return nil
                end
            end

            return tween
        end)()
    end,
    [50] = function()
        local wax, script, require = ImportGlobals(50)
        local ImportGlobals

        return (function(...)
            local variables = require(script.Parent.variables)
            local log = require(script.Parent.log)
            local locale = {}

            export type Translator = (source:string, localeId:string) -> string?
            export type TranslationTables = {[string]: {[string]: string}}

            locale.strings = {}::TranslationTables
            locale.current = 'en'
            locale.translator = nil::Translator?

            local function languageOf(id: string): string
                return string.match(id, '^(%a+)') or id
            end

            function locale.resolve(source: unknown): string
                if type(source) ~= 'string' then
                    return if source == nil then''else tostring(source)
                end
                if source == '' then
                    return ''
                end
                if locale.translator then
                    local ok, translated = pcall(locale.translator, source, locale.current)

                    if ok and type(translated) == 'string' and translated ~= '' then
                        return translated
                    end
                end

                local exact = locale.strings[locale.current]

                if exact and exact[source] then
                    return exact[source]
                end

                local lang = languageOf(locale.current)
                local langTable = locale.strings[lang]

                if langTable and langTable[source] then
                    return langTable[source]
                end

                return source
            end
            function locale.t(source: unknown): string
                return locale.resolve(source)
            end
            function locale.register(tables: TranslationTables?)
                if type(tables) ~= 'table' then
                    return
                end

                for id, entries in tables do
                    if type(id) == 'string' and type(entries) == 'table' then
                        local key = string.lower(id)
                        local target = locale.strings[key]

                        if not target then
                            target = {}
                            locale.strings[key] = target
                        end

                        for src, trans in entries do
                            if type(src) == 'string' and type(trans) == 'string' then
                                target[src] = trans
                            else
                                log.warn("Delirium locale: skipping invalid translation entry in '" .. key .. "'.")
                            end
                        end
                    end
                end
            end
            function locale.setActive(localeId: string?): string
                locale.current = if type(localeId) == 'string' and localeId ~= ''then string.lower(localeId)else'en'

                return locale.current
            end
            function locale.detect(): string
                local svc = (variables::any).localizationService or (game::any):GetService('LocalizationService')

                if svc and svc.RobloxLocaleId then
                    local id = svc.RobloxLocaleId

                    if type(id) == 'string' and id ~= '' then
                        return string.lower(id)
                    end
                end

                return 'en'
            end

            return locale
        end)()
    end,
    [41] = function()
        local wax, script, require = ImportGlobals(41)
        local ImportGlobals

        return (function(...)
            local services = require(script.Parent.services)
            local filesystem = {}
            local runService = services.getService('RunService')
            local isStudio = runService:IsStudio()
            local hasNativeFS = not isStudio and typeof(writefile) == 'function'

            if hasNativeFS then
                function filesystem.writefile(
                    path: string,
                    content: string
                )
                    writefile(path, content)
                end
                function filesystem.readfile(path: string): string
                    return readfile(path)
                end
                function filesystem.appendfile(
                    path: string,
                    content: string
                )
                    appendfile(path, content)
                end
                function filesystem.isfile(path: string): boolean
                    return isfile(path)
                end
                function filesystem.delfile(path: string)
                    delfile(path)
                end
                function filesystem.listfiles(folder: string): {string}
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
                local replicatedStorage = services.getService('ReplicatedStorage')
                local root = replicatedStorage:FindFirstChild('__DeliriumFS__')

                if not root then
                    root = Instance.new('Folder')
                    root.Name = '__DeliriumFS__'
                    root.Parent = replicatedStorage
                end

                local function splitPath(path: string): {string}
                    local parts: {string} = {}

                    for part in string.gmatch(path, '[^/]+')do
                        table.insert(parts, part)
                    end

                    return parts
                end
                local function resolveParent(parts: {string}, create: boolean): Instance?
                    local cur: Instance = root::Instance

                    for i = 1, #parts - 1 do
                        local child = cur:FindFirstChild(parts[i])

                        if not child then
                            if not create then
                                return nil
                            end

                            local f = Instance.new('Folder')

                            f.Name = parts[i]
                            f.Parent = cur
                            child = f
                        end

                        cur = child::Instance
                    end

                    return cur
                end
                local function asFile(inst: Instance?): StringValue?
                    return if inst and inst:IsA('StringValue')then inst::StringValue else nil
                end

                function filesystem.writefile(
                    path: string,
                    content: string
                )
                    local parts = splitPath(path)

                    assert(#parts > 0, 'filesystem.writefile: invalid path')

                    local parent = resolveParent(parts, true)

                    assert(parent, 'filesystem.writefile: could not resolve parent')

                    local name = parts[#parts]
                    local existing = parent:FindFirstChild(name)
                    local file = asFile(existing)

                    if file then
                        file.Value = content
                    else
                        if existing then
                            existing:Destroy()
                        end

                        local sv = Instance.new('StringValue')

                        sv.Name = name
                        sv.Value = content
                        sv.Parent = parent
                    end
                end
                function filesystem.readfile(path: string): string
                    local parts = splitPath(path)
                    local parent = resolveParent(parts, false)

                    assert(parent, 'filesystem.readfile: file not found \u{2014} ' .. path)

                    local file = asFile(parent:FindFirstChild(parts[#parts]))

                    assert(file, 'filesystem.readfile: file not found \u{2014} ' .. path)

                    return file.Value
                end
                function filesystem.appendfile(
                    path: string,
                    content: string
                )
                    local parts = splitPath(path)
                    local parent = resolveParent(parts, false)

                    assert(parent, 'filesystem.appendfile: file not found \u{2014} ' .. path)

                    local file = asFile(parent:FindFirstChild(parts[#parts]))

                    assert(file, 'filesystem.appendfile: file not found \u{2014} ' .. path)

                    file.Value = file.Value .. content
                end
                function filesystem.isfile(path: string): boolean
                    local parts = splitPath(path)

                    if #parts == 0 then
                        return false
                    end

                    local parent = resolveParent(parts, false)

                    if not parent then
                        return false
                    end

                    return asFile(parent:FindFirstChild(parts[#parts])) ~= nil
                end
                function filesystem.delfile(path: string)
                    local parts = splitPath(path)
                    local parent = resolveParent(parts, false)

                    assert(parent, 'filesystem.delfile: file not found \u{2014} ' .. path)

                    local file = asFile(parent:FindFirstChild(parts[#parts]))

                    assert(file, 'filesystem.delfile: file not found \u{2014} ' .. path)
                    file:Destroy()
                end
                function filesystem.listfiles(folder: string): {string}
                    local parts = splitPath(folder)
                    local cur: Instance = root::Instance

                    for _, part in parts do
                        local child = cur:FindFirstChild(part)

                        assert(child and child:IsA('Folder'), 'filesystem.listfiles: folder not found \u{2014} ' .. folder)

                        cur = child
                    end

                    local results: {string} = {}

                    for _, child in cur:GetChildren()do
                        table.insert(results, folder .. '/' .. child.Name)
                    end

                    return results
                end
                function filesystem.makefolder(path: string)
                    local parts = splitPath(path)
                    local cur: Instance = root::Instance

                    for _, part in parts do
                        local child = cur:FindFirstChild(part)

                        if not child then
                            local f = Instance.new('Folder')

                            f.Name = part
                            f.Parent = cur
                            child = f
                        end

                        cur = child::Instance
                    end
                end
                function filesystem.isfolder(path: string): boolean
                    local parts = splitPath(path)
                    local cur: Instance = root::Instance

                    for _, part in parts do
                        local child = cur:FindFirstChild(part)

                        if not child or not child:IsA('Folder') then
                            return false
                        end

                        cur = child
                    end

                    return true
                end
                function filesystem.delfolder(path: string)
                    local parts = splitPath(path)
                    local parent = resolveParent(parts, false)

                    assert(parent, 'filesystem.delfolder: folder not found \u{2014} ' .. path)

                    local folder = parent:FindFirstChild(parts[#parts])

                    assert(folder and folder:IsA('Folder'), 'filesystem.delfolder: folder not found \u{2014} ' .. path)
                    folder:Destroy()
                end
            end

            function filesystem.ensureFolder(path: string)
                if not filesystem.isfolder(path) then
                    filesystem.makefolder(path)
                end
            end
            function filesystem.ensureDir(dir: string)
                local built = ''

                for part in string.gmatch(dir, '[^/]+')do
                    built = if built == ''then part else built .. '/' .. part

                    if not filesystem.isfolder(built) then
                        filesystem.makefolder(built)
                    end
                end
            end

            return filesystem
        end)()
    end,
    [26] = function()
        local wax, script, require = ImportGlobals(26)
        local ImportGlobals

        return (function(...)
            local constants = require(script.Parent.Parent.utility.constants)
            local tween = require(script.Parent.Parent.utility.tween)
            local flags = require(script.Parent.Parent.utility.flags)
            local element = require(script.Parent.Parent.utility.element)
            local themeUtil = require(script.Parent.Parent.utility.theme)
            local hapticEngine = require(script.Parent.Parent.utility.HapticEngine)
            local moveable = require(script.Parent.Parent.utility.moveable)
            local lockable = require(script.Parent.Parent.utility.lockable)

            export type ToggleProps = {name: string?, description: string?, flag: string?, value: boolean?, callback: ((value:boolean) -> ())?}
            export type Toggle = {value: boolean, _frame: Frame, Set: (self:Toggle, value:boolean, skipCallback:boolean?) -> (), Destroy: (self:Toggle) -> ()}

            local Toggle = {}

            Toggle.__index = Toggle

            function Toggle.new(
                props: ToggleProps,
                theme: {[string]: any},
                parent: Instance
            ): Toggle
                local name = props.name or 'Toggle'
                local flagKey: string? = props.flag or (props::any).Flag
                local callback = props.callback
                local initValue: boolean

                if flagKey and flags:Get(flagKey) ~= nil then
                    initValue = flags:Get(flagKey)::boolean
                else
                    initValue = props.value == true
                end

                local frame, stroke, gradient = element.makeFrame('Toggle_' .. name, theme, parent)
                local titleLabel = element.createTitle(frame, name, nil, theme, 56)
                local trackW, trackH = 36, 20
                local knobSize = trackH - 6
                local track = Instance.new('Frame')

                track.Name = 'Track'
                track.AnchorPoint = Vector2.new(1, 0.5)
                track.Position = UDim2.new(1, -12, 0.5, 0)
                track.Size = UDim2.fromOffset(trackW, trackH)
                track.BackgroundColor3 = theme.ToggleTrack or Color3.fromRGB(0, 0, 0)
                track.BackgroundTransparency = theme.ToggleTrackTransparency or 0.85
                track.BorderSizePixel = 0
                track.Parent = frame

                do
                    local c = Instance.new('UICorner')

                    c.CornerRadius = UDim.new(1, 0)
                    c.Parent = track
                end

                local knob = Instance.new('Frame')

                knob.Name = 'Knob'
                knob.AnchorPoint = Vector2.new(0, 0.5)
                knob.Position = UDim2.new(0, 3, 0.5, 0)
                knob.Size = UDim2.fromOffset(knobSize, knobSize)
                knob.BackgroundColor3 = theme.ToggleKnobOff or Color3.fromRGB(200, 195, 220)
                knob.BackgroundTransparency = theme.ToggleKnobOffTransparency or 0.5
                knob.BorderSizePixel = 0
                knob.ZIndex = 2
                knob.Parent = track

                do
                    local c = Instance.new('UICorner')

                    c.CornerRadius = UDim.new(1, 0)
                    c.Parent = knob
                end

                local glow = Instance.new('Frame')

                glow.Name = 'Glow'
                glow.Size = UDim2.fromScale(1, 1)
                glow.BackgroundColor3 = theme.AccentColor or Color3.fromRGB(124, 58, 237)
                glow.BackgroundTransparency = 1
                glow.BorderSizePixel = 0
                glow.ZIndex = 1
                glow.Parent = track

                do
                    local c = Instance.new('UICorner')

                    c.CornerRadius = UDim.new(1, 0)
                    c.Parent = glow
                end

                local self = setmetatable({}, Toggle)::Toggle

                self.value = initValue
                self._frame = frame

                local s = self::any

                s._knob = knob
                s._glow = glow
                s._track = track
                s._theme = theme
                s._stroke = stroke
                s._titleLabel = titleLabel
                s._flag = flagKey
                s._callback = callback
                s._trackW = trackW
                s._knobSize = knobSize

                local currentTheme = theme

                element.wireHover(frame, stroke, function()
                    return currentTheme
                end, function()
                    if (self::any).locked then
                        return
                    end

                    hapticEngine.click()
                    tween.fire(stroke, constants.tweenFast, {
                        Color = currentTheme.AccentColor or Color3.fromHex('#4cc2ff'),
                        Transparency = 0,
                    })
                    task.delay(0.18, function()
                        if not frame.Parent then
                            return
                        end

                        tween.fire(stroke, constants.tweenFast, {
                            Color = currentTheme.ElementStroke or Color3.fromHex('#2b2b2b'),
                            Transparency = currentTheme.ElementStrokeTransparency or 0,
                        })
                    end)
                    self:Set(not self.value)
                end)

                s._themeUnsub = themeUtil.subscribe(function(t)
                    currentTheme = t
                    s._theme = t
                    frame.BackgroundTransparency = t.ElementTransparency or 0
                    stroke.Color = t.ElementStroke or Color3.fromHex('#2b2b2b')
                    stroke.Transparency = t.ElementStrokeTransparency or 0
                    titleLabel.TextColor3 = t.ContentColor or Color3.fromHex('#ffffff')
                    titleLabel.FontFace = t.Font or constants.DEFAULT_FONT
                    track.BackgroundColor3 = t.ToggleTrack or Color3.fromRGB(0, 0, 0)
                    track.BackgroundTransparency = t.ToggleTrackTransparency or 0.85

                    if self.value then
                        knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                        knob.BackgroundTransparency = 0
                    else
                        knob.BackgroundColor3 = t.ToggleKnobOff or Color3.fromHex('#9d9d9d')
                        knob.BackgroundTransparency = t.ToggleKnobOffTransparency or 0.5
                    end

                    glow.BackgroundColor3 = t.AccentColor or Color3.fromHex('#4cc2ff')
                    gradient.Color = t.ElementGradient or ColorSequence.new({
                        ColorSequenceKeypoint.new(0, Color3.fromHex('#2e2e2e')),
                        ColorSequenceKeypoint.new(1, Color3.fromHex('#181818')),
                    })
                end, frame)

                self:Set(initValue, true)

                return self
            end
            function Toggle:Set(value: boolean, skipCallback: boolean?)
                local s = self::any

                if s.locked and not skipCallback then
                    return
                end

                self.value = value

                local knob: Frame = s._knob
                local glow: Frame = s._glow
                local theme = s._theme
                local trackW: number = s._trackW
                local knobSize: number = s._knobSize
                local knobOffColor = theme.ToggleKnobOff or Color3.fromRGB(200, 195, 220)
                local glowAlpha = theme.AccentGlow or 0.4

                if value then
                    tween.fire(knob, constants.tweenFast, {
                        Position = UDim2.new(0, trackW - knobSize - 3, 0.5, 0),
                        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                        BackgroundTransparency = 0,
                    })
                    tween.fire(glow, constants.tweenFast, {BackgroundTransparency = glowAlpha})
                else
                    tween.fire(knob, constants.tweenFast, {
                        Position = UDim2.new(0, 3, 0.5, 0),
                        BackgroundColor3 = knobOffColor,
                        BackgroundTransparency = theme.ToggleKnobOffTransparency or 0.5,
                    })
                    tween.fire(glow, constants.tweenFast, {BackgroundTransparency = 1})
                end
                if s._flag then
                    flags:Set(s._flag, value)
                end
                if not skipCallback and s._callback then
                    task.spawn(s._callback, value)
                end
            end
            function Toggle:_setShown(shown: boolean, animate: boolean?)
                local s = self::any
                local t = s._theme or {}
                local info = if animate ~= false then constants.tweenNormal else nil
                local frameTrans = if shown then(t.ElementTransparency or 0)else 1
                local strokeTrans = if shown then(t.ElementStrokeTransparency or 0)else 1
                local textTrans = if shown then 0 else 1
                local trackTrans = if shown then(t.ToggleTrackTransparency or 0.85)else 1
                local knobTrans = if shown then(if self.value then 0 else(t.ToggleKnobOffTransparency or 0.5))else 1
                local glowTrans = if shown and self.value then(t.AccentGlow or 0.4)else 1

                if info then
                    tween.play(self._frame, info, {BackgroundTransparency = frameTrans})

                    if s._stroke then
                        tween.play(s._stroke, info, {Transparency = strokeTrans})
                    end
                    if s._titleLabel then
                        tween.play(s._titleLabel, info, {TextTransparency = textTrans})
                    end
                    if s._track then
                        tween.play(s._track, info, {BackgroundTransparency = trackTrans})
                    end
                    if s._knob then
                        tween.play(s._knob, info, {BackgroundTransparency = knobTrans})
                    end
                    if s._glow then
                        tween.play(s._glow, info, {BackgroundTransparency = glowTrans})
                    end
                else
                    self._frame.BackgroundTransparency = frameTrans

                    if s._stroke then
                        s._stroke.Transparency = strokeTrans
                    end
                    if s._titleLabel then
                        s._titleLabel.TextTransparency = textTrans
                    end
                    if s._track then
                        s._track.BackgroundTransparency = trackTrans
                    end
                    if s._knob then
                        s._knob.BackgroundTransparency = knobTrans
                    end
                    if s._glow then
                        s._glow.BackgroundTransparency = glowTrans
                    end
                end
            end
            function Toggle:Destroy()
                local s = self::any

                if s._themeUnsub then
                    s._themeUnsub()
                end
                if s._descriptor then
                    s._descriptor:Destroy()
                end

                self._frame:Destroy()
            end

            moveable(Toggle)
            lockable(Toggle)

            return Toggle
        end)()
    end,
    [12] = function()
        local wax, script, require = ImportGlobals(12)
        local ImportGlobals

        return (function(...)
            local variables = require(script.Parent.Parent.utility.variables)
            local constants = require(script.Parent.Parent.utility.constants)
            local types = require(script.Parent.Parent.types)
            local TweenService = variables.tweenService
            local RunService = variables.runService

            export type Config = types.KeySystemConfig
            export type KeySystem = types.KeySystem

            local function tw(inst: Instance, t: number, props: {[string]: any})
                TweenService:Create(inst, TweenInfo.new(t, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), props):Play()
            end
            local function readCache(path: string): string?
                local okCheck, exists = pcall(function()
                    return (isfile::any)(path)
                end)

                if not (okCheck and exists) then
                    return nil
                end

                local okRead, v = pcall(function()
                    return (readfile::any)(path)
                end)

                if okRead and typeof(v) == 'string' and #v > 0 then
                    return v:gsub('%s+', '')
                end

                return nil
            end
            local function writeCache(path: string, key: string)
                pcall(function()
                    if typeof(writefile) == 'function' then
                        (writefile::any)(path, key)
                    end
                end)
            end
            local function runLoadScript(self: any, key: string)
                local cfg = self._cfg

                if not cfg.ScriptId or cfg.LoadScript == false then
                    return
                end
                if typeof(getgenv) == 'function' then
                    pcall(function()
                        getgenv().SCRIPT_KEY = key
                    end)
                end

                task.spawn(function()
                    local sdk = self:_loadSDK()
                    local ok, err = pcall(sdk.load_script)

                    if not ok then
                        warn('[Delirium/keySystem] load_script() failed: ' .. tostring(err))
                    end
                end)
            end

            local KeySystemModule = {}

            KeySystemModule.__index = KeySystemModule

            function KeySystemModule.new(cfg: Config)
                assert(cfg.Service, '[Delirium/keySystem] Service is required')
                assert(cfg.Identifier, '[Delirium/keySystem] Identifier is required')

                local self = setmetatable({}, KeySystemModule)::any

                self._cfg = cfg
                self._sdk = nil
                self._gui = nil

                return self
            end
            function KeySystemModule:_loadSDK()
                if self._sdk then
                    return self._sdk
                end

                local cfg = self._cfg

                if cfg.MockKeys and #cfg.MockKeys > 0 then
                    local keys = cfg.MockKeys
                    local mockLib = {}

                    function mockLib.check_key(_: any, key: string)
                        for _, k in ipairs(keys)do
                            if k == key then
                                return {
                                    valid = true,
                                    is_keyless = false,
                                    is_premium = false,
                                    message = 'KEY_VALID',
                                }
                            end
                        end

                        return {
                            valid = false,
                            error = 'INVALID_KEY',
                        }
                    end
                    function mockLib.get_key_link(_: any)
                        return 'https://jnkie.com (Mock Key: ' .. (keys[1] or 'test') .. ')', nil
                    end
                    function mockLib.load_script()
                        print('[Delirium/keySystem] Mock load_script() \u{2014} no script loaded in MockKeys mode.')
                    end

                    self._sdk = mockLib

                    return mockLib
                end
                if RunService:IsStudio() then
                    warn(
[[[Delirium/keySystem] Studio detected without MockKeys. Enabling automatic fallback key: 'delirium-test']])

                    local mockLib = {}

                    function mockLib.check_key(_: any, key: string)
                        if key == 'delirium-test' or key == 'test' then
                            return {
                                valid = true,
                                is_keyless = false,
                                is_premium = false,
                                message = 'KEY_VALID',
                            }
                        end

                        return {
                            valid = false,
                            error = "INVALID_KEY (Use 'delirium-test' in Studio)",
                        }
                    end
                    function mockLib.get_key_link(_: any)
                        return 'https://jnkie.com (Studio test key: delirium-test)', nil
                    end
                    function mockLib.load_script()
                        print('[Delirium/keySystem] Mock load_script() \u{2014} no script loaded in Studio mode.')
                    end

                    self._sdk = mockLib

                    return mockLib
                end

                local ok, lib = pcall(function()
                    return loadstring(game:HttpGet('https://jnkie.com/sdk/library.lua'))()
                end)

                assert(ok and lib, '[Delirium/keySystem] Failed to load Jnkie SDK: ' .. tostring(lib))

                lib.service = self._cfg.Service
                lib.identifier = self._cfg.Identifier

                if self._cfg.Provider then
                    lib.provider = self._cfg.Provider
                end
                if self._cfg.ScriptId then
                    lib.script_id = self._cfg.ScriptId
                end

                self._sdk = lib

                return lib
            end
            function KeySystemModule:_buildUI()
                local cfg = self._cfg
                local accent = cfg.Accent or constants.COLORS.ACCENT
                local T = {
                    BG = Color3.fromHex('#0c0c10'),
                    SURFACE = Color3.fromHex('#14141a'),
                    BORDER = Color3.fromHex('#22222e'),
                    ACCENT = accent,
                    TEXT = constants.COLORS.TEXT,
                    MUTED = constants.COLORS.TEXT_MUTED,
                    ERROR = constants.COLORS.ERROR,
                    SUCCESS = constants.COLORS.SUCCESS,
                    FONTB = constants.DEFAULT_FONT_BOLD,
                    FONT = constants.DEFAULT_FONT_MEDIUM,
                    MONO = constants.DEFAULT_FONT_MONO,
                }

                self._theme = T

                local gui = Instance.new('ScreenGui')

                gui.Name = 'DeliriumKey'
                gui.ResetOnSpawn = false
                gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
                gui.DisplayOrder = (constants.displayOrder.loading or 100010) + 20
                gui.IgnoreGuiInset = true
                gui.Parent = variables.guiContainer

                local bg = Instance.new('Frame')

                bg.Size = UDim2.fromScale(1, 1)
                bg.BackgroundColor3 = Color3.new(0, 0, 0)
                bg.BackgroundTransparency = 1
                bg.BorderSizePixel = 0
                bg.Parent = gui

                tw(bg, 0.3, {BackgroundTransparency = 0.45})

                local cardHeight = if cfg.Provider then 232 else 210
                local card = Instance.new('Frame')

                card.Size = UDim2.fromOffset(340, cardHeight)
                card.AnchorPoint = Vector2.new(0.5, 0.5)
                card.Position = UDim2.new(0.5, 0, 0.5, 18)
                card.BackgroundColor3 = T.SURFACE
                card.BackgroundTransparency = 1
                card.BorderSizePixel = 0
                card.ClipsDescendants = true
                card.Parent = gui

                local cardCorner = Instance.new('UICorner')

                cardCorner.CornerRadius = UDim.new(0, 10)
                cardCorner.Parent = card

                local stroke = Instance.new('UIStroke')

                stroke.Color = T.BORDER
                stroke.Thickness = 1
                stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                stroke.Parent = card

                local bar = Instance.new('Frame')

                bar.Size = UDim2.new(1, 0, 0, 2)
                bar.BackgroundColor3 = T.ACCENT
                bar.BorderSizePixel = 0
                bar.Parent = card

                local title = Instance.new('TextLabel')

                title.Size = UDim2.new(1, -60, 0, 22)
                title.Position = UDim2.fromOffset(16, 16)
                title.Text = cfg.Title or 'DELIRIUM'
                title.TextColor3 = T.TEXT
                title.BackgroundTransparency = 1
                title.FontFace = T.FONTB
                title.TextSize = 14
                title.TextXAlignment = Enum.TextXAlignment.Left
                title.Parent = card

                local sub = Instance.new('TextLabel')

                sub.Size = UDim2.new(1, -60, 0, 14)
                sub.Position = UDim2.fromOffset(16, 38)
                sub.Text = cfg.Subtitle or 'Enter your key to continue'
                sub.TextColor3 = T.MUTED
                sub.BackgroundTransparency = 1
                sub.FontFace = T.FONT
                sub.TextSize = 11
                sub.TextXAlignment = Enum.TextXAlignment.Left
                sub.Parent = card

                local closeBtn = nil

                if cfg.AllowCancel then
                    closeBtn = Instance.new('TextButton')
                    closeBtn.Size = UDim2.fromOffset(24, 24)
                    closeBtn.AnchorPoint = Vector2.new(1, 0)
                    closeBtn.Position = UDim2.new(1, -12, 0, 14)
                    closeBtn.BackgroundTransparency = 1
                    closeBtn.Text = '\u{2715}'
                    closeBtn.TextColor3 = T.MUTED
                    closeBtn.TextSize = 12
                    closeBtn.FontFace = T.FONTB
                    closeBtn.BorderSizePixel = 0
                    closeBtn.Parent = card

                    closeBtn.MouseEnter:Connect(function()
                        tw(closeBtn, 0.15, {
                            TextColor3 = T.TEXT,
                        })
                    end)
                    closeBtn.MouseLeave:Connect(function()
                        tw(closeBtn, 0.15, {
                            TextColor3 = T.MUTED,
                        })
                    end)
                end

                local div = Instance.new('Frame')

                div.Size = UDim2.new(1, -32, 0, 1)
                div.Position = UDim2.fromOffset(16, 60)
                div.BackgroundColor3 = T.BORDER
                div.BorderSizePixel = 0
                div.Parent = card

                local ibg = Instance.new('Frame')

                ibg.Size = UDim2.new(1, -32, 0, 36)
                ibg.Position = UDim2.fromOffset(16, 74)
                ibg.BackgroundColor3 = T.BG
                ibg.BorderSizePixel = 0
                ibg.Parent = card

                local icorner = Instance.new('UICorner')

                icorner.CornerRadius = UDim.new(0, 6)
                icorner.Parent = ibg

                local istroke = Instance.new('UIStroke')

                istroke.Color = T.BORDER
                istroke.Thickness = 1
                istroke.Parent = ibg

                local input = Instance.new('TextBox')

                input.Size = UDim2.new(1, -16, 1, 0)
                input.Position = UDim2.fromOffset(8, 0)
                input.Text = ''
                input.PlaceholderText = 'Paste key here...'
                input.PlaceholderColor3 = T.MUTED
                input.TextColor3 = T.TEXT
                input.BackgroundTransparency = 1
                input.FontFace = T.MONO
                input.TextSize = 12
                input.TextXAlignment = Enum.TextXAlignment.Left
                input.ClearTextOnFocus = false
                input.Parent = ibg

                local status = Instance.new('TextLabel')

                status.Size = UDim2.new(1, -32, 0, 14)
                status.Position = UDim2.fromOffset(16, 116)
                status.Text = ''
                status.TextColor3 = T.MUTED
                status.BackgroundTransparency = 1
                status.FontFace = T.FONT
                status.TextSize = 11
                status.TextXAlignment = Enum.TextXAlignment.Left
                status.Parent = card

                local btn = Instance.new('TextButton')

                btn.Size = UDim2.new(1, -32, 0, 34)
                btn.Position = UDim2.fromOffset(16, 136)
                btn.Text = 'VALIDATE'
                btn.TextColor3 = Color3.fromHex('#0c0c10')
                btn.BackgroundColor3 = T.ACCENT
                btn.FontFace = T.FONTB
                btn.TextSize = 12
                btn.BorderSizePixel = 0
                btn.AutoButtonColor = false
                btn.Parent = card

                local btnCorner = Instance.new('UICorner')

                btnCorner.CornerRadius = UDim.new(0, 6)
                btnCorner.Parent = btn

                btn.MouseEnter:Connect(function()
                    if btn.Active then
                        tw(btn, 0.15, {BackgroundTransparency = 0.15})
                    end
                end)
                btn.MouseLeave:Connect(function()
                    if btn.Active then
                        tw(btn, 0.15, {BackgroundTransparency = 0})
                    end
                end)

                local getKeyBtn = nil

                if cfg.Provider then
                    getKeyBtn = Instance.new('TextButton')
                    getKeyBtn.Size = UDim2.new(1, -32, 0, 16)
                    getKeyBtn.Position = UDim2.fromOffset(16, 180)
                    getKeyBtn.Text = 'get key \u{2192}'
                    getKeyBtn.TextColor3 = T.ACCENT
                    getKeyBtn.BackgroundTransparency = 1
                    getKeyBtn.FontFace = T.FONT
                    getKeyBtn.TextSize = 11
                    getKeyBtn.TextXAlignment = Enum.TextXAlignment.Left
                    getKeyBtn.BorderSizePixel = 0
                    getKeyBtn.Parent = card
                end

                task.delay(0.04, function()
                    tw(card, 0.28, {
                        Position = UDim2.new(0.5, 0, 0.5, 0),
                        BackgroundTransparency = 0,
                    })
                end)

                self._gui = gui
                self._card = card
                self._input = input
                self._istroke = istroke
                self._status = status
                self._btn = btn
                self._getKeyBtn = getKeyBtn
                self._closeBtn = closeBtn
            end
            function KeySystemModule:_setStatus(msg: string, color: Color3?)
                if self._status then
                    self._status.Text = msg
                    self._status.TextColor3 = color or self._theme.MUTED
                end
            end
            function KeySystemModule:_setBtnState(active: boolean)
                if not self._btn then
                    return
                end

                self._btn.Active = active
                self._btn.Text = if active then'VALIDATE'else'...'

                tw(self._btn, 0.12, {
                    BackgroundColor3 = if active then self._theme.ACCENT else self._theme.BORDER,
                    TextColor3 = if active then Color3.fromHex('#0c0c10')else self._theme.MUTED,
                })
            end
            function KeySystemModule:_shake()
                if not self._card then
                    return
                end

                local base = self._card.Position
                local offsets = {
                    -6,
                    6,
                    -4,
                    4,
                    -2,
                    2,
                }

                local function step()
                    if #offsets == 0 then
                        tw(self._card, 0.1, {Position = base})

                        return
                    end

                    local x = table.remove(offsets, 1)

                    tw(self._card, 0.05, {
                        Position = UDim2.new(base.X.Scale, base.X.Offset + x, base.Y.Scale, base.Y.Offset),
                    })
                    task.delay(0.05, step)
                end

                step()
            end
            function KeySystemModule:_dismiss(up: boolean)
                if not self._card then
                    return
                end

                tw(self._card, 0.22, {
                    Position = UDim2.new(0.5, 0, 0.5, if up then-24 else 18),
                    BackgroundTransparency = 1,
                })
                task.delay(0.25, function()
                    if self._gui then
                        self._gui:Destroy()

                        self._gui = nil
                    end
                end)
            end
            function KeySystemModule:Prompt(callback: (success:boolean, key:string?) -> ())
                local cfg = self._cfg

                if cfg.SaveKey ~= false then
                    local cached = readCache(cfg.CacheFile or 'delirium_key.dat')

                    if cached then
                        task.spawn(function()
                            local sdk = self:_loadSDK()
                            local ok, result = pcall(sdk.check_key, sdk, cached)

                            if ok and result and result.valid then
                                if cfg.ScriptId and cfg.LoadScript ~= false and typeof(getgenv) == 'function' then
                                    pcall(function()
                                        getgenv().SCRIPT_KEY = cached
                                    end)
                                end

                                callback(true, cached)
                                runLoadScript(self, cached)

                                return
                            end

                            self:_buildUI()
                            self:_wire(callback)
                        end)

                        return
                    end
                end

                self:_buildUI()
                self:_wire(callback)
            end
            function KeySystemModule:_wire(callback: (success:boolean, key:string?) -> ())
                local cfg = self._cfg
                local T = self._theme

                if self._closeBtn then
                    self._closeBtn.MouseButton1Click:Connect(function()
                        self:_dismiss(false)
                        callback(false, nil)
                    end)
                end
                if self._input and self._istroke then
                    self._input.Focused:Connect(function()
                        tw(self._istroke, 0.15, {
                            Color = T.ACCENT,
                        })
                    end)
                    self._input.FocusLost:Connect(function()
                        tw(self._istroke, 0.15, {
                            Color = T.BORDER,
                        })
                    end)
                end
                if self._getKeyBtn then
                    local busy = false

                    self._getKeyBtn.MouseButton1Click:Connect(function()
                        if busy then
                            return
                        end

                        busy = true
                        self._getKeyBtn.Text = 'requesting...'
                        self._getKeyBtn.TextColor3 = T.MUTED

                        task.spawn(function()
                            local sdk = self:_loadSDK()
                            local ok, link, err = pcall(sdk.get_key_link, sdk)

                            if ok and link then
                                if typeof(setclipboard) == 'function' then
                                    pcall(setclipboard, link)

                                    self._getKeyBtn.Text = 'link copied \u{2713}'
                                else
                                    print('[Delirium/keySystem] Key link:', link)

                                    self._getKeyBtn.Text = 'link in console \u{2713}'
                                end

                                self._getKeyBtn.TextColor3 = T.SUCCESS

                                task.delay(3, function()
                                    if self._getKeyBtn then
                                        self._getKeyBtn.Text = 'get key \u{2192}'
                                        self._getKeyBtn.TextColor3 = T.ACCENT
                                        busy = false
                                    end
                                end)
                            else
                                local errMsg = (not ok and tostring(link)) or (err == 'RATE_LIMITTED' and 'rate limited, wait a bit') or tostring(err or 'failed')

                                self._getKeyBtn.Text = errMsg
                                self._getKeyBtn.TextColor3 = T.ERROR

                                task.delay(3, function()
                                    if self._getKeyBtn then
                                        self._getKeyBtn.Text = 'get key \u{2192}'
                                        self._getKeyBtn.TextColor3 = T.ACCENT
                                        busy = false
                                    end
                                end)
                            end
                        end)
                    end)
                end

                local function attempt()
                    local key = if self._input then self._input.Text:match('^%s*(.-)%s*$') or ''else''

                    if key == '' then
                        self:_setStatus('key cannot be empty', T.ERROR)

                        if self._istroke then
                            tw(self._istroke, 0.1, {
                                Color = T.ERROR,
                            })
                        end

                        self:_shake()

                        return
                    end

                    self:_setStatus('validating...', T.MUTED)

                    if self._istroke then
                        tw(self._istroke, 0.1, {
                            Color = T.MUTED,
                        })
                    end

                    self:_setBtnState(false)
                    task.spawn(function()
                        local sdk = self:_loadSDK()
                        local ok, result = pcall(sdk.check_key, sdk, key)

                        if not ok then
                            self:_setStatus('request failed, try again', T.ERROR)

                            if self._istroke then
                                tw(self._istroke, 0.1, {
                                    Color = T.ERROR,
                                })
                            end

                            self:_shake()
                            self:_setBtnState(true)

                            return
                        end
                        if result and result.valid then
                            if cfg.SaveKey ~= false then
                                writeCache(cfg.CacheFile or 'delirium_key.dat', key)
                            end

                            self:_setStatus('\u{2713} key accepted', T.SUCCESS)

                            if self._istroke then
                                tw(self._istroke, 0.1, {
                                    Color = T.SUCCESS,
                                })
                            end
                            if cfg.ScriptId and cfg.LoadScript ~= false and typeof(getgenv) == 'function' then
                                pcall(function()
                                    getgenv().SCRIPT_KEY = key
                                end)
                            end

                            task.delay(0.5, function()
                                self:_dismiss(true)
                                task.delay(0.25, function()
                                    callback(true, key)
                                    runLoadScript(self, key)
                                end)
                            end)
                        else
                            local reason = (result and result.error) and tostring(result.error) or 'invalid key'

                            self:_setStatus('\u{2717} ' .. reason, T.ERROR)

                            if self._istroke then
                                tw(self._istroke, 0.1, {
                                    Color = T.ERROR,
                                })
                            end

                            self:_shake()
                            self:_setBtnState(true)
                        end
                    end)
                end

                if self._btn then
                    self._btn.MouseButton1Click:Connect(attempt)
                end
                if self._input then
                    self._input.FocusLost:Connect(function(enter)
                        if enter then
                            attempt()
                        end
                    end)
                end
            end
            function KeySystemModule:Destroy()
                if self._gui then
                    self._gui:Destroy()

                    self._gui = nil
                end
            end

            return KeySystemModule
        end)()
    end,
    [6] = function()
        local wax, script, require = ImportGlobals(6)
        local ImportGlobals

        return (function(...)
            local constants = require(script.Parent.Parent.utility.constants)
            local variables = require(script.Parent.Parent.utility.variables)
            local tween = require(script.Parent.Parent.utility.tween)
            local themeUtil = require(script.Parent.Parent.utility.theme)
            local icons = require(script.Parent.Parent.utility.icons)

            export type PlayerCard = {_cardFrame: Frame, _content: Frame, _cardHit: TextButton, _openButton: TextButton, ShowContent: (self:PlayerCard) -> (), HideContent: (self:PlayerCard) -> (), Destroy: (self:PlayerCard) -> ()}

            local PlayerCard = {}

            PlayerCard.__index = PlayerCard

            local _Players = variables.players::Players
            local _StatsService = variables.stats::Stats
            local _RunService = variables.runService
            local _IS_TOUCH = variables.isTouchOnly
            local _THUMB_TYPE = Enum.ThumbnailType.HeadShot
            local _THUMB_SIZE = Enum.ThumbnailSize.Size100x100

            local function mk(class, props, parent)
                local inst = Instance.new(class)

                for k, v in props do
                    inst[k] = v
                end

                if parent then
                    inst.Parent = parent
                end

                return inst
            end
            local function _formatTime(secs)
                local h, m, s = math.floor(secs / 3600), math.floor((secs % 3600) / 60), math.floor(secs % 60)

                if h > 0 then
                    return string.format('%dh %02dm %02ds', h, m, s)
                end
                if m > 0 then
                    return string.format('%02dm %02ds', m, s)
                end

                return string.format('%02ds', s)
            end
            local function _formatAge(days)
                if days >= 365 then
                    local y = math.floor(days / 365)

                    return y == 1 and '1 yr' or y .. ' yrs'
                end
                if days >= 30 then
                    local m = math.floor(days / 30)

                    return m == 1 and '1 mo' or m .. ' mos'
                end

                return days == 1 and '1 day' or days .. ' days'
            end
            local function _getExecutorName(): string?
                local executorName: string? = nil

                pcall(function()
                    local env = (getfenv::any)(0)
                    local fn = env.identifyexecutor or env.getexecutorname or env.EXECUTOR_NAME

                    if type(fn) == 'function' then
                        local ok, res = pcall(fn)

                        if ok and type(res) == 'string' and #res > 0 then
                            executorName = res
                        end
                    elseif type(fn) == 'string' and #fn > 0 then
                        executorName = fn
                    end
                end)

                return executorName
            end

            function PlayerCard.new(
                footerSlot: Frame,
                _windowFrame: Frame,
                contentArea: Frame,
                theme: {[string]: any}
            ): PlayerCard
                local lp = _Players.LocalPlayer
                local executorName = _getExecutorName()

                local function getTokens(t)
                    return {
                        accent = t.AccentColor or constants.COLORS.ACCENT,
                        border = t.SurfaceStroke or constants.COLORS.STROKE,
                        surface = t.TitleBarColor or constants.COLORS.TITLE_BAR,
                        textPrimary = t.TitlingColor or constants.COLORS.TEXT,
                        textSecondary = t.PlaceholderColor or constants.COLORS.TEXT_SUBTLE,
                        neutralBtn = t.NeutralButton or constants.COLORS.SURFACE_ALT,
                        errorColor = t.ErrorColor or constants.COLORS.ERROR,
                        font = t.Font or constants.DEFAULT_FONT_MEDIUM,
                        fontBold = constants.DEFAULT_FONT_BOLD,
                        fontSemi = constants.DEFAULT_FONT_SEMI,
                        fontMono = constants.DEFAULT_FONT_MONO,
                        elemCorner = t.ElementCornerRadius or constants.elementCornerRadius,
                        elemTrans = t.ElementTransparency or 0,
                        elemStrokeTrans = t.ElementStrokeTransparency or 0,
                    }
                end

                local tk = getTokens(theme)
                local cards, strokes, accentStrokes, dividers, pills = {}, {}, {}, {}, {}
                local liveAccents, iconImages, rowLabels, rowValues = {}, {}, {}, {}
                local footerRoot = mk('Frame', {
                    Name = 'FooterContent',
                    Size = UDim2.fromScale(1, 1),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    ZIndex = 1,
                }, footerSlot)
                local cardHit = mk('TextButton', {
                    Name = 'Hit',
                    Size = UDim2.fromScale(1, 1),
                    BackgroundTransparency = 1,
                    Text = '',
                    AutoButtonColor = false,
                    ZIndex = 0,
                }, footerRoot)
                local leftGroup = mk('Frame', {
                    Name = 'Left',
                    Position = UDim2.fromOffset(10, 0),
                    Size = UDim2.new(1, -20, 1, 0),
                    BackgroundTransparency = 1,
                    ZIndex = 2,
                }, footerRoot)

                mk('UIListLayout', {
                    FillDirection = Enum.FillDirection.Horizontal,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                    Padding = UDim.new(0, 8),
                }, leftGroup)

                local avatarClip = mk('Frame', {
                    Name = 'AvatarClip',
                    Size = UDim2.fromOffset(26, 26),
                    BackgroundColor3 = tk.surface,
                    BorderSizePixel = 0,
                    ClipsDescendants = true,
                    ZIndex = 2,
                }, leftGroup)

                mk('UICorner', {
                    CornerRadius = UDim.new(1, 0),
                }, avatarClip)

                local avatarStroke = mk('UIStroke', {
                    Color = tk.border,
                    Thickness = 1,
                    Transparency = 0.4,
                }, avatarClip)
                local avatarImg = mk('ImageLabel', {
                    Name = 'Avatar',
                    Size = UDim2.fromScale(1, 1),
                    BackgroundTransparency = 1,
                    Image = '',
                    ScaleType = Enum.ScaleType.Fit,
                    ZIndex = 2,
                }, avatarClip)

                mk('UICorner', {
                    CornerRadius = UDim.new(1, 0),
                }, avatarImg)

                local dispLbl = mk('TextLabel', {
                    Name = 'DisplayName',
                    AutomaticSize = Enum.AutomaticSize.X,
                    Size = UDim2.new(0, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = lp.DisplayName,
                    TextColor3 = tk.textPrimary,
                    TextSize = 13,
                    FontFace = tk.fontSemi,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    ZIndex = 2,
                }, leftGroup)

                table.insert(rowValues, dispLbl)

                local openBtn = mk('TextButton', {
                    Name = 'OpenDashboard',
                    Size = UDim2.fromOffset(20, 20),
                    BackgroundColor3 = tk.neutralBtn,
                    BackgroundTransparency = 0.3,
                    BorderSizePixel = 0,
                    Text = '',
                    AutoButtonColor = false,
                    ZIndex = 3,
                }, leftGroup)

                mk('UICorner', {
                    CornerRadius = UDim.new(0, 5),
                }, openBtn)

                local openStroke = mk('UIStroke', {
                    Color = tk.border,
                    Thickness = 1,
                    Transparency = 0.5,
                }, openBtn)
                local openIconAsset = icons.Resolve('chevron-right', 'Lucide') or 'rbxassetid://126507964682213'
                local openIcon = mk('ImageLabel', {
                    Name = 'Icon',
                    Size = UDim2.fromOffset(10, 10),
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.fromScale(0.5, 0.5),
                    BackgroundTransparency = 1,
                    Image = openIconAsset,
                    ImageColor3 = tk.textSecondary,
                    ScaleType = Enum.ScaleType.Fit,
                    ZIndex = 4,
                }, openBtn)

                if not _IS_TOUCH then
                    openBtn.MouseEnter:Connect(function()
                        tween.fire(openBtn, constants.tweenFast, {
                            BackgroundTransparency = 0.05,
                            BackgroundColor3 = tk.accent,
                        })
                        tween.fire(openIcon, constants.tweenFast, {
                            ImageColor3 = Color3.fromRGB(255, 255, 255),
                        })
                    end)
                    openBtn.MouseLeave:Connect(function()
                        tween.fire(openBtn, constants.tweenFast, {
                            BackgroundTransparency = 0.3,
                            BackgroundColor3 = tk.neutralBtn,
                        })
                        tween.fire(openIcon, constants.tweenFast, {
                            ImageColor3 = tk.textSecondary,
                        })
                    end)
                end

                local rightGroup = mk('Frame', {
                    Name = 'Right',
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, -10, 0.5, 0),
                    Size = UDim2.new(0, 0, 1, 0),
                    AutomaticSize = Enum.AutomaticSize.X,
                    BackgroundTransparency = 1,
                    ZIndex = 2,
                }, footerRoot)

                mk('UIListLayout', {
                    FillDirection = Enum.FillDirection.Horizontal,
                    HorizontalAlignment = Enum.HorizontalAlignment.Right,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                    Padding = UDim.new(0, 6),
                }, rightGroup)

                local function makePill(iconKey, order): TextLabel
                    local pill = mk('Frame', {
                        Name = 'Pill',
                        AutomaticSize = Enum.AutomaticSize.X,
                        Size = UDim2.new(0, 0, 0, 22),
                        BackgroundColor3 = Color3.fromRGB(20, 20, 24),
                        BackgroundTransparency = 0.35,
                        BorderSizePixel = 0,
                        LayoutOrder = order,
                        ZIndex = 3,
                    }, rightGroup)

                    mk('UICorner', {
                        CornerRadius = UDim.new(0, 5),
                    }, pill)
                    table.insert(strokes, mk('UIStroke', {
                        Color = tk.border,
                        Thickness = 1,
                        Transparency = 0.55,
                    }, pill))
                    mk('UIPadding', {
                        PaddingLeft = UDim.new(0, 8),
                        PaddingRight = UDim.new(0, 8),
                    }, pill)
                    mk('UIListLayout', {
                        FillDirection = Enum.FillDirection.Horizontal,
                        VerticalAlignment = Enum.VerticalAlignment.Center,
                        Padding = UDim.new(0, 5),
                    }, pill)

                    local asset = icons.Resolve(iconKey)

                    if asset then
                        local img = mk('ImageLabel', {
                            Name = 'Icon',
                            Size = UDim2.fromOffset(11, 11),
                            BackgroundTransparency = 1,
                            Image = asset,
                            ImageColor3 = tk.textSecondary,
                            ScaleType = Enum.ScaleType.Fit,
                            ZIndex = 4,
                        }, pill)

                        table.insert(iconImages, img)
                    end

                    local lbl = mk('TextLabel', {
                        Name = 'Text',
                        AutomaticSize = Enum.AutomaticSize.X,
                        Size = UDim2.new(0, 0, 1, 0),
                        BackgroundTransparency = 1,
                        Text = '',
                        TextColor3 = tk.textSecondary,
                        TextSize = 10,
                        FontFace = tk.fontSemi,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ZIndex = 4,
                    }, pill)

                    table.insert(rowLabels, lbl)

                    return lbl
                end

                local executorLbl = makePill('zap', 1)

                executorLbl.Text = executorName or '-'

                local fpsLbl = makePill('activity', 2)

                fpsLbl.Text = '\u{2014} FPS'

                table.insert(liveAccents, fpsLbl)

                local membershipText = if lp.MembershipType == Enum.MembershipType.Premium then'Premium'else'Free'
                local tierLbl = makePill('sparkle', 3)

                tierLbl.Text = membershipText

                local content = mk('Frame', {
                    Name = 'DashboardContent',
                    Size = UDim2.fromScale(1, 1),
                    BackgroundTransparency = 1,
                    Visible = false,
                    ClipsDescendants = true,
                }, contentArea)
                local mainScroll = mk('ScrollingFrame', {
                    Name = 'MainScroll',
                    Size = UDim2.fromScale(1, 1),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    ScrollBarThickness = 2,
                    ScrollBarImageColor3 = tk.border,
                    ScrollBarImageTransparency = 0.5,
                    CanvasSize = UDim2.fromOffset(0, 0),
                    AutomaticCanvasSize = Enum.AutomaticSize.Y,
                    ClipsDescendants = true,
                    ZIndex = 2,
                }, content)

                mk('UIPadding', {
                    PaddingLeft = UDim.new(0, 14),
                    PaddingRight = UDim.new(0, 14),
                    PaddingTop = UDim.new(0, 14),
                    PaddingBottom = UDim.new(0, 20),
                }, mainScroll)
                mk('UIListLayout', {
                    FillDirection = Enum.FillDirection.Vertical,
                    VerticalAlignment = Enum.VerticalAlignment.Top,
                    Padding = UDim.new(0, 12),
                    SortOrder = Enum.SortOrder.LayoutOrder,
                }, mainScroll)

                local function styleCard(inst)
                    table.insert(cards, inst)
                    mk('UICorner', {
                        CornerRadius = tk.elemCorner,
                    }, inst)
                    table.insert(strokes, mk('UIStroke', {
                        Color = tk.border,
                        Thickness = 1,
                        Transparency = tk.elemStrokeTrans,
                        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                    }, inst))
                end

                local hero = mk('Frame', {
                    Name = 'HeroCard',
                    Size = UDim2.new(1, 0, 0, 82),
                    BackgroundColor3 = tk.neutralBtn,
                    BackgroundTransparency = tk.elemTrans,
                    BorderSizePixel = 0,
                    LayoutOrder = 1,
                    ClipsDescendants = true,
                    ZIndex = 2,
                }, mainScroll)

                styleCard(hero)

                local ring = mk('Frame', {
                    Name = 'AvatarRing',
                    AnchorPoint = Vector2.new(0, 0.5),
                    Position = UDim2.new(0, 14, 0.5, 0),
                    Size = UDim2.fromOffset(56, 56),
                    BackgroundColor3 = tk.surface,
                    BorderSizePixel = 0,
                    ClipsDescendants = true,
                    ZIndex = 3,
                }, hero)

                mk('UICorner', {
                    CornerRadius = UDim.new(1, 0),
                }, ring)

                local ringStroke = mk('UIStroke', {
                    Color = tk.accent,
                    Thickness = 1.5,
                    Transparency = 0.2,
                }, ring)
                local bigAvatar = mk('ImageLabel', {
                    Name = 'Avatar',
                    Size = UDim2.fromScale(1, 1),
                    BackgroundTransparency = 1,
                    Image = '',
                    ScaleType = Enum.ScaleType.Fit,
                    ZIndex = 3,
                }, ring)

                mk('UICorner', {
                    CornerRadius = UDim.new(1, 0),
                }, bigAvatar)

                local details = mk('Frame', {
                    Name = 'Details',
                    AnchorPoint = Vector2.new(0, 0.5),
                    Position = UDim2.new(0, 82, 0.5, 0),
                    Size = UDim2.new(1, -96, 1, -12),
                    BackgroundTransparency = 1,
                    ZIndex = 3,
                }, hero)

                mk('UIListLayout', {
                    FillDirection = Enum.FillDirection.Vertical,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                    Padding = UDim.new(0, 4),
                    SortOrder = Enum.SortOrder.LayoutOrder,
                }, details)

                local row1 = mk('Frame', {
                    Name = 'Row1',
                    Size = UDim2.new(1, 0, 0, 20),
                    BackgroundTransparency = 1,
                    LayoutOrder = 1,
                    ZIndex = 4,
                }, details)

                mk('UIListLayout', {
                    FillDirection = Enum.FillDirection.Horizontal,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                    Padding = UDim.new(0, 8),
                    SortOrder = Enum.SortOrder.LayoutOrder,
                }, row1)
                mk('TextLabel', {
                    Name = 'DisplayName',
                    AutomaticSize = Enum.AutomaticSize.X,
                    Size = UDim2.new(0, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = lp.DisplayName,
                    TextColor3 = tk.textPrimary,
                    TextSize = 15,
                    FontFace = tk.fontBold,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    LayoutOrder = 1,
                    ZIndex = 4,
                }, row1)

                local function metaTag(text, order)
                    local tag = mk('Frame', {
                        AutomaticSize = Enum.AutomaticSize.X,
                        Size = UDim2.new(0, 0, 0, 18),
                        BackgroundColor3 = Color3.fromRGB(24, 24, 30),
                        BackgroundTransparency = 0.35,
                        BorderSizePixel = 0,
                        LayoutOrder = order,
                        ZIndex = 4,
                    }, row1)

                    mk('UICorner', {
                        CornerRadius = UDim.new(1, 0),
                    }, tag)
                    mk('UIPadding', {
                        PaddingLeft = UDim.new(0, 8),
                        PaddingRight = UDim.new(0, 8),
                    }, tag)
                    table.insert(strokes, mk('UIStroke', {
                        Color = tk.border,
                        Thickness = 1,
                        Transparency = 0.65,
                    }, tag))

                    local lbl = mk('TextLabel', {
                        Size = UDim2.new(0, 0, 1, 0),
                        AutomaticSize = Enum.AutomaticSize.X,
                        BackgroundTransparency = 1,
                        Text = text,
                        TextColor3 = tk.textSecondary,
                        TextSize = 9,
                        FontFace = tk.fontSemi,
                        ZIndex = 5,
                    }, tag)

                    table.insert(rowLabels, lbl)
                end

                metaTag('ID: ' .. tostring(lp.UserId), 2)
                metaTag('Age: ' .. _formatAge(lp.AccountAge), 3)

                local row2 = mk('Frame', {
                    Name = 'Row2',
                    Size = UDim2.new(1, 0, 0, 18),
                    BackgroundTransparency = 1,
                    LayoutOrder = 2,
                    ZIndex = 4,
                }, details)

                mk('UIListLayout', {
                    FillDirection = Enum.FillDirection.Horizontal,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                    Padding = UDim.new(0, 8),
                    SortOrder = Enum.SortOrder.LayoutOrder,
                }, row2)

                local platformPill = mk('Frame', {
                    Name = 'PlatformPill',
                    AutomaticSize = Enum.AutomaticSize.X,
                    Size = UDim2.new(0, 0, 0, 18),
                    BackgroundColor3 = tk.accent,
                    BackgroundTransparency = 0.88,
                    BorderSizePixel = 0,
                    LayoutOrder = 1,
                    ZIndex = 4,
                }, row2)

                mk('UICorner', {
                    CornerRadius = UDim.new(0, 6),
                }, platformPill)
                mk('UIPadding', {
                    PaddingLeft = UDim.new(0, 7),
                    PaddingRight = UDim.new(0, 7),
                    PaddingTop = UDim.new(0, 2),
                    PaddingBottom = UDim.new(0, 2),
                }, platformPill)
                table.insert(accentStrokes, mk('UIStroke', {
                    Color = tk.accent,
                    Thickness = 1,
                    Transparency = 0.45,
                }, platformPill))
                mk('UIListLayout', {
                    FillDirection = Enum.FillDirection.Horizontal,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                    Padding = UDim.new(0, 5),
                }, platformPill)

                local monitorAsset = icons.Resolve('monitor')

                if monitorAsset then
                    local m = mk('ImageLabel', {
                        Name = 'PlatformIcon',
                        Size = UDim2.fromOffset(12, 12),
                        BackgroundTransparency = 1,
                        Image = monitorAsset,
                        ImageColor3 = tk.accent,
                        ScaleType = Enum.ScaleType.Fit,
                        ZIndex = 5,
                    }, platformPill)

                    table.insert(liveAccents, m)
                end

                local platformText = mk('TextLabel', {
                    Name = 'PlatformText',
                    AutomaticSize = Enum.AutomaticSize.X,
                    Size = UDim2.new(0, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = string.upper(if _IS_TOUCH then'MOBILE'else'DESKTOP'),
                    TextColor3 = tk.accent,
                    TextSize = 9,
                    FontFace = tk.fontBold,
                    ZIndex = 5,
                }, platformPill)

                table.insert(liveAccents, platformText)

                local userLblHero = mk('TextLabel', {
                    Name = 'Username',
                    AutomaticSize = Enum.AutomaticSize.X,
                    Size = UDim2.new(0, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Text = '@' .. lp.Name,
                    TextColor3 = tk.textSecondary,
                    TextSize = 11,
                    FontFace = tk.font,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    LayoutOrder = 2,
                    ZIndex = 4,
                }, row2)

                table.insert(rowLabels, userLblHero)

                local kpiGrid = mk('Frame', {
                    Name = 'KpiGrid',
                    Size = UDim2.new(1, 0, 0, 78),
                    BackgroundTransparency = 1,
                    LayoutOrder = 2,
                    ZIndex = 2,
                }, mainScroll)

                mk('UIListLayout', {
                    FillDirection = Enum.FillDirection.Horizontal,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                    Padding = UDim.new(0, 8),
                    SortOrder = Enum.SortOrder.LayoutOrder,
                }, kpiGrid)

                local function kpiTile(order, title, iconKey, initial, sub): TextLabel
                    local tile = mk('Frame', {
                        Name = 'Tile_' .. title,
                        Size = UDim2.new(0.25, -6, 1, 0),
                        BackgroundColor3 = tk.neutralBtn,
                        BackgroundTransparency = tk.elemTrans,
                        BorderSizePixel = 0,
                        LayoutOrder = order,
                        ZIndex = 2,
                    }, kpiGrid)

                    styleCard(tile)
                    mk('UIPadding', {
                        PaddingLeft = UDim.new(0, 10),
                        PaddingRight = UDim.new(0, 10),
                        PaddingTop = UDim.new(0, 8),
                        PaddingBottom = UDim.new(0, 8),
                    }, tile)
                    mk('UIListLayout', {
                        FillDirection = Enum.FillDirection.Vertical,
                        VerticalAlignment = Enum.VerticalAlignment.Center,
                        Padding = UDim.new(0, 5),
                    }, tile)

                    local topRow = mk('Frame', {
                        Name = 'TopRow',
                        Size = UDim2.new(1, 0, 0, 30),
                        BackgroundTransparency = 1,
                        ZIndex = 3,
                    }, tile)

                    mk('UIListLayout', {
                        FillDirection = Enum.FillDirection.Horizontal,
                        VerticalAlignment = Enum.VerticalAlignment.Center,
                        Padding = UDim.new(0, 8),
                    }, topRow)

                    local iconBox = mk('Frame', {
                        Name = 'IconBox',
                        Size = UDim2.fromOffset(30, 30),
                        BackgroundColor3 = Color3.fromRGB(22, 22, 28),
                        BackgroundTransparency = 0.25,
                        BorderSizePixel = 0,
                        ZIndex = 3,
                    }, topRow)

                    mk('UICorner', {
                        CornerRadius = UDim.new(0, 6),
                    }, iconBox)
                    table.insert(strokes, mk('UIStroke', {
                        Color = tk.border,
                        Thickness = 1,
                        Transparency = 0.6,
                    }, iconBox))

                    local iconAsset = icons.Resolve(iconKey)

                    if iconAsset then
                        local iconImg = mk('ImageLabel', {
                            Name = 'Icon',
                            AnchorPoint = Vector2.new(0.5, 0.5),
                            Position = UDim2.fromScale(0.5, 0.5),
                            Size = UDim2.fromOffset(16, 16),
                            BackgroundTransparency = 1,
                            Image = iconAsset,
                            ImageColor3 = tk.textSecondary,
                            ScaleType = Enum.ScaleType.Fit,
                            ZIndex = 4,
                        }, iconBox)

                        table.insert(iconImages, iconImg)
                    end

                    local textStack = mk('Frame', {
                        Name = 'TextStack',
                        Size = UDim2.new(1, -38, 1, 0),
                        BackgroundTransparency = 1,
                        ZIndex = 3,
                    }, topRow)

                    mk('UIListLayout', {
                        FillDirection = Enum.FillDirection.Vertical,
                        VerticalAlignment = Enum.VerticalAlignment.Center,
                        Padding = UDim.new(0, 1),
                    }, textStack)

                    local titleLbl = mk('TextLabel', {
                        Name = 'Header',
                        Size = UDim2.new(1, 0, 0, 13),
                        BackgroundTransparency = 1,
                        Text = string.upper(title),
                        TextColor3 = tk.textPrimary,
                        TextSize = 10,
                        FontFace = tk.fontBold,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ZIndex = 4,
                    }, textStack)

                    table.insert(rowValues, titleLbl)

                    local subLbl = mk('TextLabel', {
                        Name = 'Sub',
                        Size = UDim2.new(1, 0, 0, 11),
                        BackgroundTransparency = 1,
                        Text = sub,
                        TextColor3 = tk.textSecondary,
                        TextTransparency = 0.35,
                        TextSize = 9,
                        FontFace = tk.font,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ZIndex = 4,
                    }, textStack)

                    table.insert(rowLabels, subLbl)

                    local val = mk('TextLabel', {
                        Name = 'Value',
                        Size = UDim2.new(1, 0, 0, 22),
                        BackgroundTransparency = 1,
                        Text = initial,
                        TextColor3 = tk.textPrimary,
                        TextSize = 18,
                        FontFace = tk.fontBold,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        TextTruncate = Enum.TextTruncate.AtEnd,
                        ZIndex = 3,
                    }, tile)

                    return val
                end

                local fpsVal = kpiTile(1, 'FPS', 'zap', '\u{2014}', 'Client Rate')
                local pingVal = kpiTile(2, 'Latency', 'signal', '\u{2014}', 'Server RTT')
                local memVal = kpiTile(3, 'Memory', 'cpu', '\u{2014}', 'Client Usage')
                local uptimeVal = kpiTile(4, 'Uptime', 'clock', '00s', 'Session Active')

                local function sectionCard(title, order): Frame
                    local box = mk('Frame', {
                        Name = 'Card_' .. title:gsub('%s+', ''),
                        Size = UDim2.new(1, 0, 0, 0),
                        AutomaticSize = Enum.AutomaticSize.Y,
                        BackgroundColor3 = tk.neutralBtn,
                        BackgroundTransparency = tk.elemTrans,
                        BorderSizePixel = 0,
                        ClipsDescendants = true,
                        LayoutOrder = order,
                        ZIndex = 2,
                    }, mainScroll)

                    styleCard(box)
                    mk('UIListLayout', {
                        FillDirection = Enum.FillDirection.Vertical,
                        VerticalAlignment = Enum.VerticalAlignment.Top,
                        Padding = UDim.new(0, 0),
                        SortOrder = Enum.SortOrder.LayoutOrder,
                    }, box)

                    local header = mk('Frame', {
                        Name = 'Header',
                        Size = UDim2.new(1, 0, 0, 36),
                        BackgroundTransparency = 1,
                        BorderSizePixel = 0,
                        LayoutOrder = 1,
                        ZIndex = 2,
                    }, box)

                    mk('UIPadding', {
                        PaddingLeft = UDim.new(0, 12),
                        PaddingRight = UDim.new(0, 12),
                    }, header)

                    local pill = mk('Frame', {
                        Name = 'Pill',
                        AnchorPoint = Vector2.new(0, 0.5),
                        Position = UDim2.new(0, 0, 0.5, 0),
                        Size = UDim2.fromOffset(3, 14),
                        BackgroundColor3 = tk.accent,
                        BorderSizePixel = 0,
                        ZIndex = 4,
                    }, header)

                    mk('UICorner', {
                        CornerRadius = UDim.new(1, 0),
                    }, pill)
                    table.insert(pills, pill)
                    mk('TextLabel', {
                        Name = 'Title',
                        AnchorPoint = Vector2.new(0, 0.5),
                        Position = UDim2.new(0, 10, 0.5, 0),
                        Size = UDim2.new(1, -10, 1, 0),
                        BackgroundTransparency = 1,
                        Text = title,
                        TextColor3 = tk.textPrimary,
                        TextSize = 13,
                        FontFace = tk.fontBold,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ZIndex = 4,
                    }, header)
                    table.insert(dividers, mk('Frame', {
                        Name = 'HeaderDiv',
                        Size = UDim2.new(1, 0, 0, 1),
                        BackgroundColor3 = tk.border,
                        BackgroundTransparency = 0.55,
                        BorderSizePixel = 0,
                        LayoutOrder = 2,
                        ZIndex = 3,
                    }, box))

                    local body = mk('Frame', {
                        Name = 'ContentBody',
                        Size = UDim2.new(1, 0, 0, 0),
                        AutomaticSize = Enum.AutomaticSize.Y,
                        BackgroundTransparency = 1,
                        BorderSizePixel = 0,
                        LayoutOrder = 3,
                        ZIndex = 3,
                    }, box)

                    mk('UIListLayout', {
                        FillDirection = Enum.FillDirection.Vertical,
                        VerticalAlignment = Enum.VerticalAlignment.Top,
                        Padding = UDim.new(0, 0),
                        SortOrder = Enum.SortOrder.LayoutOrder,
                    }, body)
                    mk('UIPadding', {
                        PaddingLeft = UDim.new(0, 12),
                        PaddingRight = UDim.new(0, 12),
                        PaddingTop = UDim.new(0, 4),
                        PaddingBottom = UDim.new(0, 6),
                    }, body)

                    return body
                end
                local function dataRow(
                    body,
                    iconKey,
                    label,
                    initial,
                    order,
                    live,
                    mono,
                    hasDivider
                ): TextLabel
                    local row = mk('Frame', {
                        Name = 'Row_' .. label:gsub('%s+', ''),
                        Size = UDim2.new(1, 0, 0, 34),
                        BackgroundTransparency = 1,
                        BorderSizePixel = 0,
                        LayoutOrder = order,
                        ZIndex = 3,
                    }, body)
                    local leftStack = mk('Frame', {
                        Name = 'LeftStack',
                        AnchorPoint = Vector2.new(0, 0.5),
                        Position = UDim2.new(0, 0, 0.5, 0),
                        Size = UDim2.new(0.55, 0, 1, 0),
                        BackgroundTransparency = 1,
                        ZIndex = 4,
                    }, row)

                    mk('UIListLayout', {
                        FillDirection = Enum.FillDirection.Horizontal,
                        VerticalAlignment = Enum.VerticalAlignment.Center,
                        Padding = UDim.new(0, 8),
                    }, leftStack)

                    local iconBox = mk('Frame', {
                        Name = 'IconBox',
                        Size = UDim2.fromOffset(22, 22),
                        BackgroundColor3 = Color3.fromRGB(24, 24, 30),
                        BackgroundTransparency = 0.4,
                        BorderSizePixel = 0,
                        ZIndex = 4,
                    }, leftStack)

                    mk('UICorner', {
                        CornerRadius = UDim.new(0, 5),
                    }, iconBox)

                    local iconAsset = icons.Resolve(iconKey)

                    if iconAsset then
                        local iconImg = mk('ImageLabel', {
                            Name = 'Icon',
                            AnchorPoint = Vector2.new(0.5, 0.5),
                            Position = UDim2.fromScale(0.5, 0.5),
                            Size = UDim2.fromOffset(13, 13),
                            BackgroundTransparency = 1,
                            Image = iconAsset,
                            ImageColor3 = tk.textSecondary,
                            ScaleType = Enum.ScaleType.Fit,
                            ZIndex = 5,
                        }, iconBox)

                        table.insert(iconImages, iconImg)
                    end

                    local lbl = mk('TextLabel', {
                        Name = 'Label',
                        AutomaticSize = Enum.AutomaticSize.X,
                        Size = UDim2.new(0, 0, 1, 0),
                        BackgroundTransparency = 1,
                        Text = label,
                        TextColor3 = tk.textSecondary,
                        TextSize = 11,
                        FontFace = tk.font,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ZIndex = 4,
                    }, leftStack)

                    table.insert(rowLabels, lbl)

                    local val = mk('TextLabel', {
                        Name = 'Value',
                        AnchorPoint = Vector2.new(1, 0.5),
                        Position = UDim2.fromScale(1, 0.5),
                        Size = UDim2.new(0.45, 0, 0, 16),
                        BackgroundTransparency = 1,
                        Text = initial,
                        TextColor3 = if live then tk.accent else tk.textPrimary,
                        TextSize = 11,
                        FontFace = if mono then tk.fontMono else tk.fontSemi,
                        TextXAlignment = Enum.TextXAlignment.Right,
                        TextTruncate = Enum.TextTruncate.AtEnd,
                        ZIndex = 4,
                    }, row)

                    table.insert(rowValues, val)

                    if live then
                        table.insert(liveAccents, val)
                    end
                    if hasDivider then
                        local sep = mk('Frame', {
                            Name = 'RowSep',
                            AnchorPoint = Vector2.new(0, 1),
                            Position = UDim2.fromScale(0, 1),
                            Size = UDim2.new(1, 0, 0, 1),
                            BackgroundColor3 = tk.border,
                            BackgroundTransparency = 0.75,
                            BorderSizePixel = 0,
                            ZIndex = 3,
                        }, row)

                        table.insert(dividers, sep)
                    end

                    return val
                end

                local sessBody = sectionCard('Session & Environment', 3)

                dataRow(sessBody, 'map-pin', 'Place ID', tostring(game.PlaceId), 1, false, true, true)

                local rawJob = tostring(game.JobId)
                local cleanJob = if#rawJob > 16
                    then rawJob:sub(1, 14) .. '\u{2026}'
                    elseif#rawJob > 0
                    then rawJob
                    else'00000000-0000-\u{2026}'

                dataRow(sessBody, 'server', 'Server Job ID', cleanJob, 2, false, true, true)

                local envLabel = if executorName then executorName else'-'
                local envIsLive = executorName ~= nil

                dataRow(sessBody, 'file-text', 'Script Environment', envLabel, 3, envIsLive, false, true)

                local membership = if lp.MembershipType == Enum.MembershipType.Premium then'Roblox Premium'else'Standard'

                dataRow(sessBody, 'user', 'Account Membership', membership, 4, false, false, false)

                local sessionStart = os.clock()
                local pingT, fpsT, fpsN, memT, uptimeT = 0, 0, 0, 0, 0
                local liveConn: RBXScriptConnection? = nil

                local function startLive()
                    if liveConn then
                        return
                    end

                    liveConn = _RunService.Heartbeat:Connect(function(dt)
                        fpsN += 1
                        fpsT += dt

                        if fpsT >= 0.5 then
                            local fps = math.round(fpsN / fpsT)

                            fpsLbl.Text = fps .. ' FPS'

                            if content.Visible then
                                fpsVal.Text = fps .. ' FPS'
                            end

                            fpsN, fpsT = 0, 0
                        end
                        if not content.Visible then
                            return
                        end

                        uptimeT += dt

                        if uptimeT >= 1 then
                            uptimeT = 0
                            uptimeVal.Text = _formatTime(os.clock() - sessionStart)
                        end

                        memT += dt

                        if memT >= 2 then
                            memT = 0

                            pcall(function()
                                memVal.Text = math.round((_StatsService::any):GetTotalMemoryUsageMb()) .. ' MB'
                            end)
                        end

                        pingT += dt

                        if pingT >= 1.5 then
                            pingT = 0

                            local ok, ms = pcall(function()
                                return math.round((_StatsService::any).Network.ServerStatsItem['Data Ping']:GetValue())
                            end)

                            pingVal.Text = if ok then tostring(ms) .. ' ms'else'\u{2014}'
                        end
                    end)
                end
                local function stopLive()
                    if liveConn then
                        liveConn:Disconnect()

                        liveConn = nil
                    end
                end

                task.spawn(function()
                    local ok, url = pcall(function()
                        return _Players:GetUserThumbnailAsync(lp.UserId, _THUMB_TYPE, _THUMB_SIZE)
                    end)

                    if ok and url then
                        avatarImg.Image = url
                        bigAvatar.Image = url
                    end
                end)

                local function showContent()
                    content.Visible = true
                end
                local function hideContent()
                    content.Visible = false
                end

                local themeUnsub = themeUtil.subscribe(function(t)
                    tk = getTokens(t)

                    for _, c in cards do
                        c.BackgroundColor3 = tk.neutralBtn
                        c.BackgroundTransparency = tk.elemTrans
                    end
                    for _, s in strokes do
                        s.Color = tk.border
                        s.Transparency = tk.elemStrokeTrans
                    end
                    for _, s in accentStrokes do
                        s.Color = tk.accent
                    end
                    for _, d in dividers do
                        d.BackgroundColor3 = tk.border
                    end
                    for _, p in pills do
                        p.BackgroundColor3 = tk.accent
                    end
                    for _, l in rowLabels do
                        l.TextColor3 = tk.textSecondary
                        l.FontFace = tk.font
                    end
                    for _, v in rowValues do
                        v.FontFace = tk.fontSemi
                    end
                    for _, a in liveAccents do
                        if a:IsA('TextLabel') then
                            local al = a::TextLabel

                            al.TextColor3 = tk.accent
                        elseif a:IsA('ImageLabel') then
                            local al = a::ImageLabel

                            al.ImageColor3 = tk.accent
                        end
                    end
                    for _, img in iconImages do
                        img.ImageColor3 = tk.textSecondary
                    end

                    ringStroke.Color = tk.accent
                    dispLbl.TextColor3 = tk.textPrimary
                    avatarStroke.Color = tk.border
                    openIcon.ImageColor3 = tk.textSecondary
                    openBtn.BackgroundColor3 = tk.neutralBtn
                    openStroke.Color = tk.border
                end, footerRoot)

                startLive()

                local self = setmetatable({}, PlayerCard)::any

                self._cardFrame = footerRoot
                self._content = content
                self._cardHit = cardHit
                self._openButton = openBtn
                self._showContent = showContent
                self._hideContent = hideContent
                self._themeUnsub = themeUnsub
                self._stopLiveUpdates = stopLive

                return self
            end
            function PlayerCard:ShowContent()
                (self::any)._showContent()
            end
            function PlayerCard:HideContent()
                (self::any)._hideContent()
            end
            function PlayerCard:Destroy()
                local s = (self::any)

                if s._stopLiveUpdates then
                    s._stopLiveUpdates()
                end
                if s._themeUnsub then
                    s._themeUnsub()
                end
                if s._content then
                    s._content:Destroy()
                end
                if s._cardFrame then
                    s._cardFrame:Destroy()
                end
            end

            return PlayerCard
        end)()
    end,
    [10] = function()
        local wax, script, require = ImportGlobals(10)
        local ImportGlobals

        return (function(...)
            local assignOrder = require(script.Parent.Parent.utility.ordering)
            local log = require(script.Parent.Parent.utility.log)
            local moveable = require(script.Parent.Parent.utility.moveable)

            export type GroupProps = {direction: string?}

            local Group = {}

            Group.__index = Group

            local ELEMENT_PAD = 8
            local COMPACT_CAPABLE = {
                button = true,
                toggle = true,
                stat = true,
                slider = true,
            }

            function Group.new(tab: any, props: GroupProps)
                props = if typeof(props) == 'table'then props else{}::GroupProps

                local dir = string.lower(tostring(props.direction or 'row'))
                local vertical = dir == 'column' or dir == 'vertical'
                local fillDir = if vertical then Enum.FillDirection.Vertical else Enum.FillDirection.Horizontal
                local self = setmetatable({
                    window = tab.window,
                    tab = tab,
                    tabPage = nil::Frame?,
                    direction = fillDir,
                    compact = not vertical,
                    forgetState = tab.forgetState,
                    elements = {}::{any},
                }, Group)
                local nestedInRow = (tab::any).direction == Enum.FillDirection.Horizontal
                local frame = Instance.new('Frame')

                frame.Name = 'Group'
                frame.BackgroundTransparency = 1
                frame.BorderSizePixel = 0
                frame.AutomaticSize = Enum.AutomaticSize.Y
                frame.Size = if nestedInRow
                    then UDim2.new(0, 0, 0, 0)
                    elseif vertical
                    then UDim2.new(1, 0, 0, 0)
                    else UDim2.new(1, -20, 0, 0)
                frame.Parent = (tab::any).tabPage

                if nestedInRow then
                    local flex = Instance.new('UIFlexItem')

                    flex.FlexMode = Enum.UIFlexMode.Fill
                    flex.Parent = frame
                end

                local layout = Instance.new('UIListLayout')

                layout.FillDirection = fillDir
                layout.SortOrder = Enum.SortOrder.LayoutOrder
                layout.Padding = UDim.new(0, ELEMENT_PAD)
                layout.VerticalAlignment = if not vertical then Enum.VerticalAlignment.Center else Enum.VerticalAlignment.Top
                layout.HorizontalAlignment = if not vertical then Enum.HorizontalAlignment.Left else Enum.HorizontalAlignment.Center
                layout.Parent = frame
                self.tabPage = frame;
                (self::any)._frame = frame;
                (self::any)._layout = layout

                local function add(compName: string, p: any): any?
                    if self.compact and not COMPACT_CAPABLE[compName] then
                        log.warn(
[[Delirium Group: row only holds compact elements (button/toggle/stat/slider), skipping ']] .. compName .. "'.")

                        return nil
                    end

                    local Module = require(script.Parent[compName]::any)
                    local el = (self::any):_createOn(Module, p)

                    return el
                end

                function self:CreateButton(p)
                    return add('button', p)
                end
                function self:CreateToggle(p)
                    return add('toggle', p)
                end
                function self:CreateSwitch(p)
                    return add('toggle', p)
                end
                function self:CreateSlider(p)
                    return add('slider', p)
                end
                function self:CreateStat(p)
                    return add('stat', p)
                end
                function self:CreateDropdown(p)
                    return add('dropdown', p)
                end
                function self:CreateInput(p)
                    return add('input', p)
                end
                function self:CreateKeybind(p)
                    return add('keybind', p)
                end
                function self:CreateLabel(p)
                    return add('label', p)
                end
                function self:CreateText(p)
                    return add('text', p)
                end
                function self:CreateDivider(p)
                    return add('divider', p)
                end
                function self:CreateSection(p)
                    return add('section', p)
                end
                function self:CreateProgress(p)
                    return add('progress', p)
                end
                function self:CreateConsole(p)
                    return add('console', p)
                end
                function self:CreateGroup(p: GroupProps)
                    if self.direction == Enum.FillDirection.Horizontal then
                        layout.VerticalAlignment = Enum.VerticalAlignment.Top

                        if tab.direction ~= Enum.FillDirection.Horizontal then
                            frame.Size = UDim2.new(1, 0, 0, 0)
                        end
                    end

                    local g = Group.new(self, p)

                    table.insert(self.elements, g);

                    (g::any)._frame.LayoutOrder = #self.elements * 10

                    self:_reflowRow()

                    return g
                end

                moveable(Group)

                return self
            end
            function Group:_createOn(Module: any, props: any): any
                local s = self::any
                local theme = s.window and (s.window::any)._theme or {}
                local el = Module.new(props, theme, s.tabPage)

                el.tab = self
                el.window = s.window

                table.insert(s.elements, el)
                assignOrder(el, #s.elements * 10)

                if self.compact then
                    self:_wrapChild(el)
                end

                self:_reflowRow()

                if s.window and not (s.window::any).hidden then
                    el:_setShown(true, true)
                end

                return el
            end
            function Group:_wrapChild(el: any)
                local s = self::any

                s._layout.Wraps = true
                s._layout.HorizontalFlex = Enum.UIFlexAlignment.Fill
                el._widthManaged = true

                local minW = if el._minWidth then el:_minWidth()else 0

                if minW > 0 then
                    el._frame.AutomaticSize = Enum.AutomaticSize.None
                    el._frame.Size = UDim2.new(0, minW, el._frame.Size.Y.Scale, el._frame.Size.Y.Offset)
                end
            end
            function Group:_reflowRow()
                local s = self::any

                if self.direction ~= Enum.FillDirection.Horizontal then
                    return
                end

                local onlyGroups = #s.elements > 0

                for _, el in ipairs(s.elements)do
                    if (el::any).__type ~= 'Group' then
                        onlyGroups = false

                        break
                    end
                end

                s._layout.Padding = if onlyGroups then UDim.new(0, -10)else UDim.new(0, ELEMENT_PAD)
            end
            function Group:_moveElement(
                element: any,
                targetIndex: number
            )
                local s = self::any
                local idx = table.find(s.elements, element)

                if not idx then
                    return
                end

                table.remove(s.elements, idx)

                targetIndex = math.clamp(targetIndex, 1, #s.elements + 1)

                table.insert(s.elements, targetIndex, element)

                for i, el in ipairs(s.elements)do
                    assignOrder(el, i * 10)
                end
            end
            function Group:_setShown(shown: boolean, animate: boolean?)
                local s = self::any

                for _, el in ipairs(s.elements)do
                    if el._setShown then
                        el:_setShown(shown, animate)
                    end
                end
            end
            function Group:_refreshTheme()
                local s = self::any

                for _, el in ipairs(s.elements)do
                    if el._refreshTheme then
                        el:_refreshTheme()
                    end
                end
            end
            function Group:Destroy()
                local s = self::any

                for _, el in ipairs(s.elements)do
                    if el.Destroy then
                        el:Destroy()
                    end
                end

                s._frame:Destroy()
            end

            return Group
        end)()
    end,
    [63] = function()
        local wax, script, require = ImportGlobals(63)
        local ImportGlobals

        return (function(...)
            local types = require(script.Parent.Parent.types)

            export type TaskEntry = types.TaskEntry
            export type TaskContext = types.TaskContext

            local Tasks = {}

            function Tasks.LoadSave(profileName: string?): TaskEntry
                return {
                    name = 'Loading saved configuration',
                    weight = 2,
                    run = function(ctx: TaskContext)
                        ctx:Status('Restoring saved profile...')

                        local saveManager = require(script.Parent.saveManager)
                        local count = saveManager:Load(profileName)

                        ctx:SetProgress(1)

                        if count > 0 then
                            ctx:Status(string.format('Restored %d saved settings', count))
                        else
                            ctx:Status('Default settings applied')
                        end
                    end,
                }
            end
            function Tasks.PreloadIcons(list: {string | number}): TaskEntry
                return {
                    name = 'Preloading icon assets',
                    weight = 3,
                    run = function(ctx: TaskContext)
                        if not list or #list == 0 then
                            ctx:SetProgress(1)

                            return
                        end

                        local icons = require(script.Parent.icons)

                        ctx:Status(string.format('Caching %d icons...', #list))

                        local done = false
                        local thread = coroutine.running()

                        task.spawn(function()
                            pcall(function()
                                icons.Preload(list)
                            end)

                            done = true

                            if coroutine.status(thread) == 'suspended' then
                                task.spawn(thread)
                            end
                        end)
                        task.delay(12, function()
                            if not done and coroutine.status(thread) == 'suspended' then
                                done = true

                                task.spawn(thread)
                            end
                        end)

                        if not done then
                            coroutine.yield()
                        end

                        ctx:SetProgress(1)
                        ctx:Status('Icons preloaded')
                    end,
                }
            end
            function Tasks.FetchAssets(manifest: {[any]: string}): TaskEntry
                return {
                    name = 'Downloading custom media',
                    weight = 5,
                    run = function(ctx: TaskContext)
                        if not manifest or next(manifest) == nil then
                            ctx:SetProgress(1)

                            return
                        end

                        local mediaService = require(script.Parent.mediaService)

                        ctx:Status('Downloading external assets...')

                        local done = false
                        local thread = coroutine.running()

                        pcall(function()
                            mediaService:preloadImages(manifest::any, function(
                                _failed: number
                            )
                                done = true

                                if coroutine.status(thread) == 'suspended' then
                                    task.spawn(thread)
                                end
                            end)
                        end)
                        task.delay(15, function()
                            if not done and coroutine.status(thread) == 'suspended' then
                                done = true

                                task.spawn(thread)
                            end
                        end)

                        if not done then
                            coroutine.yield()
                        end

                        ctx:SetProgress(1)
                        ctx:Status('Assets cached')
                    end,
                }
            end
            function Tasks.AwaitCharacter(timeout: number?): TaskEntry
                local maxWait = timeout or 10

                return {
                    name = 'Waiting for character',
                    weight = 4,
                    run = function(ctx: TaskContext)
                        local services = require(script.Parent.services)
                        local players = services.getService('Players')::Players
                        local lp = players.LocalPlayer

                        if not lp then
                            ctx:SetProgress(1)

                            return
                        end
                        if lp.Character and lp.Character:FindFirstChild('HumanoidRootPart') then
                            ctx:SetProgress(1)
                            ctx:Status('Character ready')

                            return
                        end

                        ctx:Status('Awaiting character spawn...')

                        local start = os.clock()

                        while os.clock() - start < maxWait do
                            if ctx:ShouldAbort() then
                                return
                            end
                            if lp.Character and lp.Character:FindFirstChild('HumanoidRootPart') then
                                break
                            end

                            local elapsed = os.clock() - start

                            ctx:SetProgress(math.clamp(elapsed / maxWait, 0, 0.95))
                            task.wait(0.1)
                        end

                        ctx:SetProgress(1)
                        ctx:Status('Character loaded')
                    end,
                }
            end
            function Tasks.AwaitPlayer(timeout: number?): TaskEntry
                local maxWait = timeout or 8

                return {
                    name = 'Waiting for player data',
                    weight = 2,
                    run = function(ctx: TaskContext)
                        local services = require(script.Parent.services)
                        local players = services.getService('Players')::Players
                        local lp = players.LocalPlayer

                        if not lp then
                            ctx:SetProgress(1)

                            return
                        end

                        local start = os.clock()

                        while os.clock() - start < maxWait do
                            if ctx:ShouldAbort() then
                                return
                            end
                            if lp:FindFirstChild('PlayerGui') then
                                break
                            end

                            ctx:SetProgress(math.clamp((os.clock() - start) / maxWait, 0, 0.9))
                            task.wait(0.1)
                        end

                        ctx:SetProgress(1)
                    end,
                }
            end
            function Tasks.CheckExecutor(): TaskEntry
                return {
                    name = 'Verifying environment',
                    weight = 1,
                    run = function(ctx: TaskContext)
                        ctx:Status('Checking environment...')

                        local missing: {string} = {}
                        local hasReq = typeof(request) == 'function' or typeof(http_request) == 'function' or typeof(syn and syn.request) == 'function'
                        local hasFs = typeof(readfile) == 'function' and typeof(writefile) == 'function'

                        if not hasReq then
                            table.insert(missing, 'http')
                        end
                        if not hasFs then
                            table.insert(missing, 'fs')
                        end
                        if #missing > 0 then
                            ctx:Status('Limited executor capabilities (' .. table.concat(missing, ', ') .. ')')
                        else
                            ctx:Status('Environment verified')
                        end

                        ctx:SetProgress(1)
                    end,
                }
            end
            function Tasks.Wait(duration: number, label: string?): TaskEntry
                local waitTime = math.max(0.01, duration)

                return {
                    name = label or 'Preparing environment',
                    weight = 1,
                    run = function(ctx: TaskContext)
                        local start = os.clock()

                        while os.clock() - start < waitTime do
                            if ctx:ShouldAbort() then
                                return
                            end

                            local frac = math.clamp((os.clock() - start) / waitTime, 0, 1)

                            ctx:SetProgress(frac)
                            task.wait(0.03)
                        end

                        ctx:SetProgress(1)
                    end,
                }
            end

            return Tasks
        end)()
    end,
    [5] = function()
        local wax, script, require = ImportGlobals(5)
        local ImportGlobals

        return (function(...)
            local constants = require(script.Parent.Parent.utility.constants)
            local element = require(script.Parent.Parent.utility.element)
            local tween = require(script.Parent.Parent.utility.tween)
            local locale = require(script.Parent.Parent.utility.locale)
            local moveable = require(script.Parent.Parent.utility.moveable)

            export type ConsoleProps = {name: string?, text: string?, height: number?, follow: boolean?, maxLines: number?}
            export type Console = {_frame: Frame, Set: (self:Console, text:string) -> (), Append: (self:Console, line:string) -> (), Clear: (self:Console) -> (), Get: (self:Console) -> string, Copy: (self:Console) -> boolean, SetHeight: (self:Console, height:number) -> (), _setShown: (self:Console, shown:boolean, animate:boolean?) -> (), Destroy: (self:Console) -> ()}

            local Console = {}

            Console.__index = Console

            local DEFAULT_H = 120
            local MIN_H = 48
            local TITLE_H = 24
            local PADDING = 17
            local TEXT_PAD = 12
            local TEXT_SIZE = 12
            local LINE_HEIGHT = 1.25
            local DEFAULT_MAX = 200
            local MONO_FONT = Font.fromEnum(Enum.Font.Code)

            local function rowText(line: string): string
                return if line == ''then' 'else line
            end

            function Console.new(
                props: ConsoleProps,
                theme: {[string]: any},
                parent: Instance
            ): Console
                local name = props.name
                local initText = props.text or ''
                local height = math.max(tonumber(props.height) or DEFAULT_H, MIN_H)
                local follow = props.follow == true
                local maxLines = math.max(tonumber(props.maxLines) or DEFAULT_MAX, 1)
                local topH = if name then TITLE_H else 0
                local totalH = height + topH + PADDING * 2
                local frame, stroke = element.makeFrame('Console_' .. (name or 'Console'), theme, parent, totalH)
                local titleLabel: TextLabel? = nil

                if name then
                    local titleContainer = Instance.new('Frame')

                    titleContainer.Name = 'TitleContainer'
                    titleContainer.Size = UDim2.new(1, -PADDING * 2, 0, 16)
                    titleContainer.Position = UDim2.new(0, PADDING, 0, PADDING)
                    titleContainer.BackgroundTransparency = 1
                    titleContainer.BorderSizePixel = 0
                    titleContainer.Parent = frame

                    local lbl = Instance.new('TextLabel')

                    lbl.Name = 'Title'
                    lbl.Text = locale.t(name)
                    lbl.Size = UDim2.fromScale(1, 1)
                    lbl.BackgroundTransparency = 1
                    lbl.BorderSizePixel = 0
                    lbl.TextColor3 = theme.ContentColor or Color3.fromRGB(200, 200, 220)
                    lbl.TextTransparency = 1
                    lbl.TextSize = 16
                    lbl.FontFace = theme.Font or constants.DEFAULT_FONT
                    lbl.TextXAlignment = Enum.TextXAlignment.Left
                    lbl.Parent = titleContainer
                    titleLabel = lbl
                end

                local panel = Instance.new('Frame')

                panel.Name = 'Panel'
                panel.AnchorPoint = Vector2.new(0.5, 1)
                panel.Position = UDim2.new(0.5, 0, 1, -PADDING)
                panel.Size = UDim2.new(1, -PADDING * 2, 0, height)
                panel.BackgroundColor3 = theme.StatBackground or Color3.fromRGB(20, 20, 24)
                panel.BackgroundTransparency = 0
                panel.BorderSizePixel = 0
                panel.ClipsDescendants = true
                panel.Parent = frame

                local panelCorner = Instance.new('UICorner')

                panelCorner.CornerRadius = theme.ElementCornerRadius or UDim.new(0, 8)
                panelCorner.Parent = panel

                local panelStroke = Instance.new('UIStroke')

                panelStroke.Color = theme.SurfaceStroke or Color3.fromRGB(50, 50, 60)
                panelStroke.Transparency = 0.9
                panelStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                panelStroke.Parent = panel

                local scroll = Instance.new('ScrollingFrame')

                scroll.Name = 'Scroll'
                scroll.Size = UDim2.new(1, -TEXT_PAD * 2, 1, -TEXT_PAD * 2)
                scroll.Position = UDim2.fromScale(0.5, 0.5)
                scroll.AnchorPoint = Vector2.new(0.5, 0.5)
                scroll.BackgroundTransparency = 1
                scroll.BorderSizePixel = 0
                scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
                scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
                scroll.ScrollBarThickness = 0
                scroll.ScrollingDirection = Enum.ScrollingDirection.Y
                scroll.Parent = panel

                local scrollLayout = Instance.new('UIListLayout')

                scrollLayout.FillDirection = Enum.FillDirection.Vertical
                scrollLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
                scrollLayout.VerticalAlignment = Enum.VerticalAlignment.Top
                scrollLayout.SortOrder = Enum.SortOrder.LayoutOrder
                scrollLayout.Parent = scroll

                local self = setmetatable({}, Console)::Console

                self._frame = frame

                local s = self::any

                s._stroke = stroke
                s._titleLabel = titleLabel
                s._panel = panel
                s._panelStroke = panelStroke
                s._scroll = scroll
                s._scrollLayout = scrollLayout
                s._theme = theme
                s._height = height
                s._topH = topH
                s._name = name
                s._follow = follow
                s._maxLines = maxLines
                s._lines = {}
                s._lineLabels = {}
                s._head = 1
                s._nextOrder = 1
                s._textDirty = true
                s._textTransparency = 1
                s._canvasConn = scrollLayout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function(
                )
                    if s._follow then
                        scroll.CanvasPosition = Vector2.new(0, scroll.AbsoluteCanvasSize.Y)
                    end
                end)
                s._themeUnsub = element.subscribeTheme(frame, {
                    frame = frame,
                    stroke = stroke,
                    extra = function(t)
                        s._theme = t
                        panel.BackgroundColor3 = t.StatBackground or Color3.fromRGB(20, 20, 24)
                        panelStroke.Color = t.SurfaceStroke or Color3.fromRGB(50, 50, 60)

                        if titleLabel then
                            titleLabel.TextColor3 = t.ContentColor or Color3.fromRGB(200, 200, 220)
                            titleLabel.FontFace = t.Font or constants.DEFAULT_FONT
                        end

                        for _, lbl in ipairs(s._lineLabels)do
                            lbl.TextColor3 = t.ContentColor or Color3.fromRGB(200, 200, 220)
                        end
                    end,
                })

                moveable(Console)
                self:Set(initText)

                return self
            end
            function Console:_makeLabel(): TextLabel
                local s = self::any
                local lbl = Instance.new('TextLabel')

                lbl.Name = 'Line'
                lbl.Size = UDim2.new(1, 0, 0, 0)
                lbl.AutomaticSize = Enum.AutomaticSize.Y
                lbl.BackgroundTransparency = 1
                lbl.BorderSizePixel = 0
                lbl.FontFace = MONO_FONT
                lbl.TextSize = TEXT_SIZE
                lbl.TextColor3 = s._theme.ContentColor or Color3.fromRGB(200, 200, 220)
                lbl.TextTransparency = s._textTransparency
                lbl.TextXAlignment = Enum.TextXAlignment.Left
                lbl.TextYAlignment = Enum.TextYAlignment.Top
                lbl.TextWrapped = true
                lbl.LineHeight = LINE_HEIGHT
                lbl.RichText = false
                lbl.Parent = s._scroll

                return lbl
            end
            function Console:_trim()
                local s = self::any
                local excess = #s._lines - s._maxLines

                if excess <= 0 then
                    return
                end

                table.move(s._lines, excess + 1, #s._lines, 1)

                for i = #s._lines, #s._lines - excess + 1, -1 do
                    s._lines[i] = nil
                end
            end
            function Console:_flush()
                local s = self::any

                s._textDirty = true

                for i, line in ipairs(s._lines)do
                    local lbl = s._lineLabels[i]

                    if not lbl then
                        lbl = self:_makeLabel()
                        s._lineLabels[i] = lbl
                    end

                    lbl.LayoutOrder = i
                    lbl.Text = rowText(line)
                    lbl.Visible = true
                end

                for i = #s._lines + 1, #s._lineLabels do
                    s._lineLabels[i].Visible = false
                end

                s._head = 1
                s._nextOrder = #s._lines + 1

                self:_pin()
            end
            function Console:_setLines(text: string)
                local s = self::any

                text = if type(text) == 'string'then text else tostring(text)

                table.clear(s._lines)

                if text ~= '' then
                    for line in string.gmatch(text .. '\n', '([^\n]*)\n')do
                        table.insert(s._lines, line)
                    end
                end

                self:_trim()
                self:_flush()
            end
            function Console:_pushLine(line: string)
                local s = self::any

                s._textDirty = true

                if #s._lines < s._maxLines then
                    table.insert(s._lines, line)

                    local idx = #s._lines
                    local lbl = s._lineLabels[idx]

                    if not lbl then
                        lbl = self:_makeLabel()
                        s._lineLabels[idx] = lbl
                    end

                    lbl.LayoutOrder = s._nextOrder
                    lbl.Text = rowText(line)
                    lbl.Visible = true

                    s._nextOrder += 1

                    return
                end

                table.move(s._lines, 2, #s._lines, 1)

                s._lines[#s._lines] = line

                local lbl = s._lineLabels[s._head]

                lbl.LayoutOrder = s._nextOrder
                lbl.Text = rowText(line)
                lbl.Visible = true

                s._nextOrder += 1

                s._head = (s._head % #s._lineLabels) + 1
            end
            function Console:_pin()
                local s = self::any

                if not s._scroll or not s._scroll.Parent then
                    return
                end

                s._scroll.CanvasPosition = Vector2.new(0, s._scroll.AbsoluteCanvasSize.Y)
            end
            function Console:Set(text: string)
                self:_setLines(text)
            end
            function Console:Append(line: string)
                local s = self::any

                line = if type(line) == 'string'then line else tostring(line)

                for part in string.gmatch(line .. '\n', '([^\n]*)\n')do
                    self:_pushLine(part)
                end

                if s._follow then
                    self:_pin()
                end
            end
            function Console:Clear()
                local s = self::any

                table.clear(s._lines)
                self:_flush()
            end
            function Console:Get(): string
                local s = self::any

                if s._textDirty then
                    s._text = table.concat(s._lines, '\n')
                    s._textDirty = false
                end

                return s._text or ''
            end
            function Console:Copy(): boolean
                local clipboard = (getgenv and getgenv().setclipboard) or (getgenv and getgenv().Clipboard and getgenv().Clipboard.set)

                if typeof(clipboard) ~= 'function' then
                    return false
                end

                local ok = pcall(clipboard, self:Get())

                return ok
            end
            function Console:SetHeight(height: number)
                local s = self::any

                s._height = math.max(tonumber(height) or DEFAULT_H, MIN_H)
                s._panel.Size = UDim2.new(1, -PADDING * 2, 0, s._height)
                self._frame.Size = UDim2.new(1, 0, 0, s._height + s._topH + PADDING * 2)
            end
            function Console:_setShown(shown: boolean, animate: boolean?)
                local s = self::any
                local t = s._theme or {}
                local info = if animate ~= false then constants.tweenNormal else nil
                local frameTrans = if shown then(t.ElementTransparency or 0)else 1
                local strokeTrans = if shown then(t.ElementStrokeTransparency or 0)else 1
                local panelTrans = if shown then 0 else 1
                local panelStkTrans = if shown then 0.9 else 1
                local textTrans = if shown then 0.15 else 1
                local titleTrans = if shown then 0 else 1

                s._textTransparency = textTrans

                if info then
                    tween.play(self._frame, info, {BackgroundTransparency = frameTrans})

                    if s._stroke then
                        tween.play(s._stroke, info, {Transparency = strokeTrans})
                    end

                    tween.play(s._panel, info, {BackgroundTransparency = panelTrans})
                    tween.play(s._panelStroke, info, {Transparency = panelStkTrans})

                    if s._titleLabel then
                        tween.play(s._titleLabel, info, {TextTransparency = titleTrans})
                    end

                    for _, lbl in ipairs(s._lineLabels)do
                        tween.play(lbl, info, {TextTransparency = textTrans})
                    end
                else
                    self._frame.BackgroundTransparency = frameTrans

                    if s._stroke then
                        s._stroke.Transparency = strokeTrans
                    end

                    s._panel.BackgroundTransparency = panelTrans
                    s._panelStroke.Transparency = panelStkTrans

                    if s._titleLabel then
                        s._titleLabel.TextTransparency = titleTrans
                    end

                    for _, lbl in ipairs(s._lineLabels)do
                        lbl.TextTransparency = textTrans
                    end
                end
            end
            function Console:Destroy()
                local s = self::any

                if s._canvasConn then
                    s._canvasConn:Disconnect()
                end
                if s._themeUnsub then
                    s._themeUnsub()
                end

                self._frame:Destroy()
            end

            return Console
        end)()
    end,
    [52] = function()
        local wax, script, require = ImportGlobals(52)
        local ImportGlobals

        return (function(...)
            local runtime = require(script.Parent.runtime)
            local log = {}

            type SuppressPredicate = () -> boolean

            local function defaultSource(): boolean
                return runtime.secureMode == true
            end

            local secureModeSource: SuppressPredicate = defaultSource
            local suppressPredicate: SuppressPredicate? = nil

            function log.setSecureModeSource(source: SuppressPredicate?)
                secureModeSource = if type(source) == 'function'then source else defaultSource
            end
            function log.setSuppressPredicate(predicate: SuppressPredicate?)
                suppressPredicate = if type(predicate) == 'function'then predicate else nil
            end

            local function suppressed(): boolean
                if suppressPredicate and suppressPredicate() then
                    return true
                end

                return secureModeSource()
            end

            function log.warn(...)
                if suppressed() then
                    return
                end

                warn('[Delirium]', ...)
            end
            function log.print(...)
                if suppressed() then
                    return
                end

                print('[Delirium]', ...)
            end
            function log.err(msg: string)
                error('[Delirium] ' .. msg, 2)
            end
            function log.debug(...)
                if suppressed() then
                    return
                end

                local flags = require(script.Parent.flags)

                if flags.debugMode then
                    print('[Delirium:debug]', ...)
                end
            end

            return log
        end)()
    end,
    [18] = function()
        local wax, script, require = ImportGlobals(18)
        local ImportGlobals

        return (function(...)
            local constants = require(script.Parent.Parent.utility.constants)
            local element = require(script.Parent.Parent.utility.element)
            local tween = require(script.Parent.Parent.utility.tween)
            local locale = require(script.Parent.Parent.utility.locale)
            local moveable = require(script.Parent.Parent.utility.moveable)
            local variables = require(script.Parent.Parent.utility.variables)
            local functions = require(script.Parent.Parent.utility.functions)

            export type ProgressProps = {name: string?, icon: (string | number)?, value: number?, range: {number}?, steps: number?, text: string?, format: ((value:number, min:number, max:number) -> string)?, showValue: boolean?, indeterminate: boolean?}
            export type Progress = {_frame: Frame, value: number, Set: (self:Progress, value:number) -> (), Get: (self:Progress) -> number, GetPercentage: (self:Progress) -> number, SetRange: (self:Progress, min:number, max:number) -> (), SetText: (self:Progress, text:string?) -> (), SetIndeterminate: (self:Progress, state:boolean) -> (), _setShown: (self:Progress, shown:boolean, animate:boolean?) -> (), Destroy: (self:Progress) -> ()}

            local Progress = {}

            Progress.__index = Progress

            local ROW_H = 60
            local TRACK_H = 8
            local STEP_H = 6
            local STEP_GAP = 6
            local INSET = 20
            local TITLE_SIZE = 16
            local READOUT_SIZE = 14
            local READOUT_OPACITY = 0.4
            local FILL_INFO = TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
            local SWEEP_INFO = TweenInfo.new(0.9, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut, 
-1, true)
            local FILL_TRANSPARENCY = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.85),
                NumberSequenceKeypoint.new(1, 0),
            })

            local function finite(v: unknown): number?
                local n = tonumber(v)

                if n == nil or n ~= n or math.abs(n) == math.huge then
                    return nil
                end

                return n
            end

            function Progress.new(
                props: ProgressProps,
                theme: {[string]: any},
                parent: Instance
            ): Progress
                local steps = finite(props.steps)

                steps = if steps and steps >= 2 then math.floor(steps)else nil

                local range = props.range
                local minVal = finite(range and range[1]) or 0
                local maxVal = finite(range and range[2]) or steps or 1

                if minVal > maxVal then
                    minVal, maxVal = maxVal, minVal
                end

                local name = props.name or 'Progress'
                local iconId = props.icon
                local showValue = if props.showValue == nil then true else props.showValue == true
                local frame, stroke = element.makeFrame('Progress_' .. name, theme, parent, ROW_H)
                local titleRow = Instance.new('Frame')

                titleRow.Name = 'TitleRow'
                titleRow.Size = UDim2.new(0, 170, 0, TITLE_SIZE)
                titleRow.Position = UDim2.new(0, INSET, 0, 20)
                titleRow.AnchorPoint = Vector2.new(0, 0.5)
                titleRow.BackgroundTransparency = 1
                titleRow.BorderSizePixel = 0
                titleRow.Parent = frame

                local titleLayout = Instance.new('UIListLayout')

                titleLayout.FillDirection = Enum.FillDirection.Horizontal
                titleLayout.Padding = UDim.new(0, 6)
                titleLayout.VerticalAlignment = Enum.VerticalAlignment.Center
                titleLayout.SortOrder = Enum.SortOrder.LayoutOrder
                titleLayout.Parent = titleRow

                local iconLabel: ImageLabel? = nil

                if iconId then
                    local img = Instance.new('ImageLabel')

                    img.Name = 'Icon'
                    img.Size = UDim2.fromOffset(16, 16)
                    img.BackgroundTransparency = 1
                    img.BorderSizePixel = 0
                    img.Image = 'rbxassetid://' .. tostring(iconId)
                    img.ImageColor3 = theme.ContentColor or Color3.fromRGB(220, 215, 240)
                    img.LayoutOrder = 0
                    img.Parent = titleRow
                    iconLabel = img
                end

                local titleLabel = Instance.new('TextLabel')

                titleLabel.Name = 'Title'
                titleLabel.Text = locale.t(name)
                titleLabel.Size = UDim2.fromOffset(250, TITLE_SIZE)
                titleLabel.AutomaticSize = Enum.AutomaticSize.X
                titleLabel.BackgroundTransparency = 1
                titleLabel.BorderSizePixel = 0
                titleLabel.TextColor3 = theme.ContentColor or Color3.fromRGB(200, 200, 220)
                titleLabel.TextSize = TITLE_SIZE
                titleLabel.FontFace = theme.Font or constants.DEFAULT_FONT
                titleLabel.TextXAlignment = Enum.TextXAlignment.Left
                titleLabel.TextWrapped = true
                titleLabel.LayoutOrder = 1
                titleLabel.Parent = titleRow

                local readoutLabel = Instance.new('TextLabel')

                readoutLabel.Name = 'Readout'
                readoutLabel.Text = ''
                readoutLabel.AnchorPoint = Vector2.new(1, 0.5)
                readoutLabel.Position = UDim2.new(1, -INSET, 0, 20)
                readoutLabel.Size = UDim2.fromOffset(50, READOUT_SIZE)
                readoutLabel.AutomaticSize = Enum.AutomaticSize.X
                readoutLabel.BackgroundTransparency = 1
                readoutLabel.BorderSizePixel = 0
                readoutLabel.TextColor3 = theme.ContentColor or Color3.fromRGB(200, 200, 220)
                readoutLabel.TextTransparency = READOUT_OPACITY
                readoutLabel.TextSize = READOUT_SIZE
                readoutLabel.FontFace = theme.Font or constants.DEFAULT_FONT
                readoutLabel.TextXAlignment = Enum.TextXAlignment.Right
                readoutLabel.Visible = showValue
                readoutLabel.Parent = frame

                local self = setmetatable({}, Progress)::Progress

                self._frame = frame
                self.value = minVal

                local s = self::any

                s._stroke = stroke
                s._titleLabel = titleLabel
                s._readoutLabel = readoutLabel
                s._iconLabel = iconLabel
                s._min = minVal
                s._max = maxVal
                s._steps = steps
                s._stepFrames = nil
                s._track = nil
                s._fill = nil
                s._fillGlow = nil
                s._sweep = nil
                s._shown = false
                s._theme = theme
                s._text = props.text
                s._format = props.format
                s._indeterminate = props.indeterminate or false

                local function clampVal(v: number): number
                    return math.clamp(finite(v) or s._min, s._min, s._max)
                end

                s._clampVal = clampVal
                self.value = clampVal(finite(props.value) or minVal)

                if steps then
                    local trackFrame = Instance.new('Frame')

                    trackFrame.Name = 'Track'
                    trackFrame.AnchorPoint = Vector2.new(0.5, 1)
                    trackFrame.Position = UDim2.new(0.5, 0, 1, -17)
                    trackFrame.Size = UDim2.new(1, -INSET * 2, 0, STEP_H)
                    trackFrame.BackgroundTransparency = 1
                    trackFrame.BorderSizePixel = 0
                    trackFrame.Parent = frame

                    local trackList = Instance.new('UIListLayout')

                    trackList.Padding = UDim.new(0, STEP_GAP)
                    trackList.FillDirection = Enum.FillDirection.Horizontal
                    trackList.VerticalAlignment = Enum.VerticalAlignment.Center
                    trackList.SortOrder = Enum.SortOrder.LayoutOrder
                    trackList.Parent = trackFrame

                    local stepFrames = {}

                    for i = 1, steps do
                        local seg = Instance.new('Frame')

                        seg.Size = UDim2.new(1 / steps, -(STEP_GAP * (steps - 1)) / steps, 1, 0)
                        seg.BackgroundColor3 = theme.SliderBackground or Color3.fromRGB(50, 50, 60)
                        seg.BackgroundTransparency = 0
                        seg.BorderSizePixel = 0
                        seg.LayoutOrder = i
                        seg.Parent = trackFrame

                        local segCorner = Instance.new('UICorner')

                        segCorner.CornerRadius = UDim.new(1, 0)
                        segCorner.Parent = seg

                        local fill = Instance.new('Frame')

                        fill.Size = UDim2.fromScale(1, 1)
                        fill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                        fill.BackgroundTransparency = 1
                        fill.BorderSizePixel = 0
                        fill.ZIndex = 2
                        fill.Parent = seg

                        local fillCorner = Instance.new('UICorner')

                        fillCorner.CornerRadius = UDim.new(1, 0)
                        fillCorner.Parent = fill

                        local fillGrad = Instance.new('UIGradient')

                        fillGrad.Color = functions.toColorSequence(theme.SliderProgress or theme.AccentColor or Color3.fromRGB(0, 180, 120))
                        fillGrad.Rotation = 90
                        fillGrad.Parent = fill

                        table.insert(stepFrames, {
                            segment = seg,
                            fill = fill,
                            grad = fillGrad,
                        })
                    end

                    s._track = trackFrame
                    s._stepFrames = stepFrames
                else
                    local trackFrame = Instance.new('Frame')

                    trackFrame.Name = 'Track'
                    trackFrame.AnchorPoint = Vector2.new(0.5, 1)
                    trackFrame.Position = UDim2.new(0.5, 0, 1, -16)
                    trackFrame.Size = UDim2.new(1, -INSET * 2, 0, TRACK_H)
                    trackFrame.BackgroundColor3 = theme.SliderBackground or Color3.fromRGB(50, 50, 60)
                    trackFrame.BackgroundTransparency = 0
                    trackFrame.BorderSizePixel = 0
                    trackFrame.Parent = frame

                    local trackCorner = Instance.new('UICorner')

                    trackCorner.CornerRadius = UDim.new(1, 0)
                    trackCorner.Parent = trackFrame

                    local fillFrame = Instance.new('Frame')

                    fillFrame.Name = 'Fill'
                    fillFrame.AnchorPoint = Vector2.new(0, 0.5)
                    fillFrame.Position = UDim2.fromScale(0, 0.5)
                    fillFrame.Size = UDim2.fromScale(if s._indeterminate then 0 else self:GetPercentage(), 1)
                    fillFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    fillFrame.BackgroundTransparency = 0
                    fillFrame.BorderSizePixel = 0
                    fillFrame.ZIndex = 2
                    fillFrame.Parent = trackFrame

                    local fillCorner = Instance.new('UICorner')

                    fillCorner.CornerRadius = UDim.new(1, 0)
                    fillCorner.Parent = fillFrame

                    local fillGrad = Instance.new('UIGradient')

                    fillGrad.Offset = Vector2.new(0, 0.5)
                    fillGrad.Rotation = 2
                    fillGrad.Transparency = FILL_TRANSPARENCY
                    fillGrad.Color = functions.toColorSequence(theme.SliderProgress or theme.AccentColor or Color3.fromRGB(0, 180, 120))
                    fillGrad.Parent = fillFrame
                    s._track = trackFrame
                    s._fill = fillFrame
                    s._fillGrad = fillGrad

                    local glowFrame = Instance.new('Frame')

                    glowFrame.Name = 'FillGlow'
                    glowFrame.AnchorPoint = Vector2.new(0, 0.5)
                    glowFrame.Position = UDim2.fromScale(0, 0.5)
                    glowFrame.Size = fillFrame.Size
                    glowFrame.BackgroundColor3 = theme.AccentColor or Color3.fromRGB(0, 180, 120)
                    glowFrame.BackgroundTransparency = theme.AccentGlow or 0.85
                    glowFrame.BorderSizePixel = 0
                    glowFrame.ZIndex = 1
                    glowFrame.Parent = trackFrame

                    local glowCorner = Instance.new('UICorner')

                    glowCorner.CornerRadius = UDim.new(1, 0)
                    glowCorner.Parent = glowFrame
                    s._fillGlow = glowFrame

                    if s._indeterminate then
                        s._sweep = variables.tweenService:Create(fillFrame, SWEEP_INFO, {
                            Size = UDim2.fromScale(1, 1),
                        })

                        s._sweep:Play()
                    end
                end

                s._themeUnsub = element.subscribeTheme(frame, {
                    frame = frame,
                    stroke = stroke,
                    extra = function(t)
                        s._theme = t
                        titleLabel.TextColor3 = t.ContentColor or Color3.fromRGB(200, 200, 220)
                        titleLabel.FontFace = t.Font or constants.DEFAULT_FONT
                        readoutLabel.TextColor3 = t.ContentColor or Color3.fromRGB(200, 200, 220)
                        readoutLabel.FontFace = t.Font or constants.DEFAULT_FONT

                        if iconLabel then
                            iconLabel.ImageColor3 = t.ContentColor or Color3.fromRGB(220, 215, 240)
                        end
                        if s._fill and s._fillGrad then
                            s._fillGrad.Color = functions.toColorSequence(t.SliderProgress or t.AccentColor or Color3.fromRGB(0, 180, 120))
                        end
                        if s._fillGlow then
                            s._fillGlow.BackgroundColor3 = t.AccentColor or Color3.fromRGB(0, 180, 120)
                            s._fillGlow.BackgroundTransparency = t.AccentGlow or 0.85
                        end
                        if s._track and not s._stepFrames then
                            s._track.BackgroundColor3 = t.SliderBackground or Color3.fromRGB(50, 50, 60)
                        end
                        if s._stepFrames then
                            for _, step in s._stepFrames do
                                step.segment.BackgroundColor3 = t.SliderBackground or Color3.fromRGB(50, 50, 60)
                                step.grad.Color = functions.toColorSequence(t.SliderProgress or t.AccentColor or Color3.fromRGB(0, 180, 120))
                            end
                        end
                    end,
                })
                readoutLabel.Text = self:_readout()

                if s._stepFrames then
                    self:_render(false)
                end

                moveable(Progress)

                return self
            end
            function Progress:_ratio(): number
                local s = self::any
                local span = s._max - s._min

                if span <= 0 then
                    return 1
                end

                return (self.value - s._min) / span
            end
            function Progress:_filledSteps(): number
                local s = self::any

                return math.clamp(math.round(self:_ratio() * s._steps), 0, s._steps)
            end
            function Progress:_readout(): string
                local s = self::any

                if s._text then
                    return locale.resolve(s._text)
                end
                if s._format then
                    local ok, fmt = pcall(s._format, self.value, s._min, s._max)

                    if ok and type(fmt) == 'string' then
                        return fmt
                    end
                end
                if s._steps then
                    return string.format('%d/%d', self:_filledSteps(), s._steps)
                end

                return string.format('%d%%', math.round(self:_ratio() * 100))
            end
            function Progress:_render(animate: boolean?)
                local s = self::any

                s._readoutLabel.Text = self:_readout()

                if s._stepFrames then
                    local filled = self:_filledSteps()

                    for i, step in ipairs(s._stepFrames)do
                        local target = if i <= filled then 0 else 1

                        if animate == false then
                            step.fill.BackgroundTransparency = target
                        else
                            variables.tweenService:Create(step.fill, FILL_INFO, {BackgroundTransparency = target}):Play()
                        end
                    end

                    return
                end
                if s._fill then
                    local size = UDim2.fromScale(self:_ratio(), 1)

                    if animate == false then
                        s._fill.Size = size

                        if s._fillGlow then
                            s._fillGlow.Size = size
                        end
                    else
                        variables.tweenService:Create(s._fill, FILL_INFO, {Size = size}):Play()

                        if s._fillGlow then
                            variables.tweenService:Create(s._fillGlow, FILL_INFO, {Size = size}):Play()
                        end
                    end
                end
            end
            function Progress:Set(value: number)
                local s = self::any

                self.value = s._clampVal(value)

                if s._indeterminate then
                    s._indeterminate = false

                    if s._sweep then
                        s._sweep:Cancel()

                        s._sweep = nil
                    end
                    if s._fill then
                        s._fill.AnchorPoint = Vector2.new(0, 0.5)
                        s._fill.Position = UDim2.fromScale(0, 0.5)
                    end
                end

                self:_render()
            end
            function Progress:Get(): number
                return self.value
            end
            function Progress:GetPercentage(): number
                return self:_ratio()
            end
            function Progress:SetRange(min: number, max: number)
                local s = self::any
                local a = finite(min) or s._min
                local b = finite(max) or s._max

                if a > b then
                    a, b = b, a
                end

                s._min, s._max = a, b
                self.value = s._clampVal(self.value)

                self:_render()
            end
            function Progress:SetText(text: string?)
                local s = self::any

                s._text = text
                s._readoutLabel.Text = self:_readout()
            end
            function Progress:SetIndeterminate(state: boolean)
                local s = self::any
                local on = state == true

                if on == s._indeterminate then
                    return
                end

                s._indeterminate = on

                if on then
                    if s._fill then
                        s._fill.AnchorPoint = Vector2.new(0, 0.5)
                        s._fill.Position = UDim2.fromScale(0, 0.5)
                        s._fill.Size = UDim2.fromScale(0, 1)
                        s._sweep = variables.tweenService:Create(s._fill, SWEEP_INFO, {
                            Size = UDim2.fromScale(1, 1),
                        })

                        s._sweep:Play()
                    end
                else
                    if s._sweep then
                        s._sweep:Cancel()

                        s._sweep = nil
                    end
                    if s._fill then
                        s._fill.AnchorPoint = Vector2.new(0, 0.5)
                        s._fill.Position = UDim2.fromScale(0, 0.5)
                    end

                    self:_render(false)
                end
            end
            function Progress:_setShown(shown: boolean, animate: boolean?)
                local s = self::any
                local t = s._theme or {}
                local info = if animate ~= false then constants.tweenNormal else nil

                s._shown = shown

                local frameTrans = if shown then(t.ElementTransparency or 0)else 1
                local strokeTrans = if shown then(t.ElementStrokeTransparency or 0)else 1
                local titleTrans = if shown then 0 else 1
                local readoutTrans = if shown then READOUT_OPACITY else 1
                local trackTrans = if shown then 0 else 1

                if info then
                    tween.play(self._frame, info, {BackgroundTransparency = frameTrans})

                    if s._stroke then
                        tween.play(s._stroke, info, {Transparency = strokeTrans})
                    end
                    if s._titleLabel then
                        tween.play(s._titleLabel, info, {TextTransparency = titleTrans})
                    end
                    if s._readoutLabel then
                        tween.play(s._readoutLabel, info, {TextTransparency = readoutTrans})
                    end
                    if s._iconLabel then
                        tween.play(s._iconLabel, info, {ImageTransparency = titleTrans})
                    end
                    if s._track and not s._stepFrames then
                        tween.play(s._track, info, {BackgroundTransparency = trackTrans})
                    end
                    if s._fill then
                        tween.play(s._fill, info, {BackgroundTransparency = trackTrans})
                    end
                    if s._fillGlow then
                        tween.play(s._fillGlow, info, {
                            BackgroundTransparency = if shown then(t.AccentGlow or 0.85)else 1,
                        })
                    end
                    if s._stepFrames then
                        local filled = self:_filledSteps()

                        for i, step in ipairs(s._stepFrames)do
                            tween.play(step.segment, info, {BackgroundTransparency = trackTrans})
                            tween.play(step.fill, info, {
                                BackgroundTransparency = if shown and i <= filled then 0 else 1,
                            })
                        end
                    end
                else
                    self._frame.BackgroundTransparency = frameTrans

                    if s._stroke then
                        s._stroke.Transparency = strokeTrans
                    end
                    if s._titleLabel then
                        s._titleLabel.TextTransparency = titleTrans
                    end
                    if s._readoutLabel then
                        s._readoutLabel.TextTransparency = readoutTrans
                    end
                    if s._iconLabel then
                        s._iconLabel.ImageTransparency = titleTrans
                    end
                    if s._track and not s._stepFrames then
                        s._track.BackgroundTransparency = trackTrans
                    end
                    if s._fill then
                        s._fill.BackgroundTransparency = trackTrans
                    end
                    if s._fillGlow then
                        s._fillGlow.BackgroundTransparency = if shown then(t.AccentGlow or 0.85)else 1
                    end
                    if s._stepFrames then
                        local filled = self:_filledSteps()

                        for i, step in ipairs(s._stepFrames)do
                            step.segment.BackgroundTransparency = trackTrans
                            step.fill.BackgroundTransparency = if shown and i <= filled then 0 else 1
                        end
                    end
                end
            end
            function Progress:Destroy()
                local s = self::any

                if s._sweep then
                    s._sweep:Cancel()
                end
                if s._themeUnsub then
                    s._themeUnsub()
                end

                self._frame:Destroy()
            end

            return Progress
        end)()
    end,
    [7] = function()
        local wax, script, require = ImportGlobals(7)
        local ImportGlobals

        return (function(...)
            local constants = require(script.Parent.Parent.utility.constants)
            local element = require(script.Parent.Parent.utility.element)

            export type Descriptor = {_frame: Frame, Destroy: (self:Descriptor) -> ()}

            local Descriptor = {}

            Descriptor.__index = Descriptor

            function Descriptor.new(
                parent: Instance,
                text: string,
                theme: {[string]: any},
                layoutOrder: number?
            ): Descriptor
                local frame = Instance.new('Frame')

                frame.Name = 'Descriptor'
                frame.Size = UDim2.new(1, 0, 0, 0)
                frame.AutomaticSize = Enum.AutomaticSize.Y
                frame.BackgroundTransparency = 1
                frame.BorderSizePixel = 0
                frame.LayoutOrder = layoutOrder or 0
                frame.Parent = parent

                local layout = Instance.new('UIListLayout')

                layout.FillDirection = Enum.FillDirection.Vertical
                layout.VerticalAlignment = Enum.VerticalAlignment.Top
                layout.SortOrder = Enum.SortOrder.LayoutOrder
                layout.Padding = UDim.new(0, 0)
                layout.Parent = frame

                local pad = Instance.new('UIPadding')

                pad.PaddingLeft = UDim.new(0, 14)
                pad.PaddingRight = UDim.new(0, 14)
                pad.PaddingTop = UDim.new(0, 1)
                pad.PaddingBottom = UDim.new(0, 6)
                pad.Parent = frame

                local label = Instance.new('TextLabel')

                label.Name = 'Text'
                label.Size = UDim2.new(1, 0, 0, 0)
                label.AutomaticSize = Enum.AutomaticSize.Y
                label.BackgroundTransparency = 1
                label.Text = text
                label.TextColor3 = theme.PlaceholderColor or Color3.fromHex('#8a8a92')
                label.TextTransparency = 0.35
                label.TextSize = 11
                label.FontFace = theme.Font or constants.DEFAULT_FONT
                label.TextXAlignment = Enum.TextXAlignment.Left
                label.TextYAlignment = Enum.TextYAlignment.Top
                label.TextWrapped = true
                label.RichText = true
                label.Parent = frame

                local self = setmetatable({}, Descriptor)::any

                self._frame = frame
                self._label = label
                self._themeUnsub = element.subscribeTheme(frame, {
                    extra = function(t)
                        label.TextColor3 = t.PlaceholderColor or constants.COLORS.TEXT_SUBTLE
                        label.FontFace = t.Font or constants.DEFAULT_FONT
                    end,
                })

                return self
            end
            function Descriptor:Destroy()
                local s = self::any

                if s._themeUnsub then
                    s._themeUnsub()
                end

                s._frame:Destroy()
            end

            return Descriptor
        end)()
    end,
    [13] = function()
        local wax, script, require = ImportGlobals(13)
        local ImportGlobals

        return (function(...)
            local constants = require(script.Parent.Parent.utility.constants)
            local tween = require(script.Parent.Parent.utility.tween)
            local flags = require(script.Parent.Parent.utility.flags)
            local runtime = require(script.Parent.Parent.utility.runtime)
            local textMetrics = require(script.Parent.Parent.utility.textMetrics)
            local element = require(script.Parent.Parent.utility.element)
            local themeUtil = require(script.Parent.Parent.utility.theme)
            local variables = require(script.Parent.Parent.utility.variables)
            local enums = require(script.Parent.Parent.utility.enums)
            local hapticEngine = require(script.Parent.Parent.utility.HapticEngine)
            local moveable = require(script.Parent.Parent.utility.moveable)
            local lockable = require(script.Parent.Parent.utility.lockable)

            export type KeybindProps = {name: string?, description: string?, flag: string?, value: (EnumItem | string)?, hold: boolean?, holdThreshold: number?, callback: ((value:any) -> ())?, onChanged: ((key:EnumItem) -> ())?}
            export type Keybind = {value: EnumItem, _frame: Frame, Set: (self:Keybind, value:EnumItem | string, skipChanged:boolean?) -> (), Destroy: (self:Keybind) -> ()}

            local Keybind = {}

            Keybind.__index = Keybind

            local activeRecordingKeybind: any = nil
            local mouseNames: {[EnumItem]: string} = {
                [Enum.UserInputType.MouseButton1] = 'MB1',
                [Enum.UserInputType.MouseButton2] = 'MB2',
                [Enum.UserInputType.MouseButton3] = 'MB3',
            }

            local function coerceKey(v: any): EnumItem
                if typeof(v) == 'EnumItem' then
                    return v
                end
                if type(v) == 'string' then
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

            local keyOverrides: {[string]: string} = {
                LeftControl = 'L-Ctrl',
                RightControl = 'R-Ctrl',
                LeftShift = 'L-Shift',
                RightShift = 'R-Shift',
                LeftAlt = 'L-Alt',
                RightAlt = 'R-Alt',
                Unknown = 'None',
            }

            local function keyLabel(key: EnumItem): string
                if mouseNames[key] then
                    return mouseNames[key]
                end

                local name = key.Name

                return keyOverrides[name] or name
            end

            function Keybind.new(
                props: KeybindProps,
                theme: {[string]: any},
                parent: Instance
            ): Keybind
                local name = props.name or 'Keybind'
                local desc = props.description or ''
                local flagKey = props.flag
                local hold = props.hold == true
                local holdThreshold = props.holdThreshold or 0.2
                local callback = props.callback
                local onChanged = props.onChanged
                local hasDesc = desc ~= ''
                local initKey: EnumItem

                if flagKey and flags:Get(flagKey) ~= nil then
                    local stored = flags:Get(flagKey)

                    if type(stored) == 'number' then
                        initKey = enums.itemFromValue(Enum.KeyCode, stored) or Enum.KeyCode.Unknown
                    else
                        initKey = coerceKey(stored)
                    end
                else
                    initKey = coerceKey(props.value)
                end

                local frame, stroke, gradient = element.makeFrame('Keybind_' .. name, theme, parent, constants.elementHeight)

                frame.Active = true

                local textContainer = Instance.new('Frame')

                textContainer.Name = 'TextContainer'
                textContainer.Position = UDim2.new(0, 12, 0.5, 0)
                textContainer.AnchorPoint = Vector2.new(0, 0.5)
                textContainer.Size = UDim2.new(1, -74, 1, -8)
                textContainer.BackgroundTransparency = 1
                textContainer.BorderSizePixel = 0
                textContainer.Parent = frame

                local titleLabel = Instance.new('TextLabel')

                titleLabel.Name = 'Title'
                titleLabel.Size = UDim2.fromScale(1, 1)
                titleLabel.BackgroundTransparency = 1
                titleLabel.Text = name
                titleLabel.TextColor3 = theme.ContentColor or Color3.fromHex('#ffffff')
                titleLabel.TextSize = 13
                titleLabel.FontFace = theme.Font or constants.DEFAULT_FONT_MEDIUM
                titleLabel.TextXAlignment = Enum.TextXAlignment.Left
                titleLabel.TextYAlignment = Enum.TextYAlignment.Center
                titleLabel.TextTruncate = Enum.TextTruncate.AtEnd
                titleLabel.Parent = textContainer

                local pill = Instance.new('TextButton')

                pill.Name = 'Pill'
                pill.AnchorPoint = Vector2.new(1, 0.5)
                pill.Position = UDim2.new(1, -12, 0.5, 0)
                pill.Size = UDim2.fromOffset(50, 26)
                pill.BackgroundColor3 = theme.FieldBackground or Color3.fromRGB(255, 255, 255)
                pill.BackgroundTransparency = theme.FieldTransparency or 0.9
                pill.BorderSizePixel = 0
                pill.Text = keyLabel(initKey)
                pill.TextColor3 = theme.ContentColor or Color3.fromHex('#ffffff')
                pill.TextSize = 12
                pill.FontFace = theme.Font or constants.DEFAULT_FONT_MEDIUM
                pill.TextTransparency = 0.3
                pill.AutoButtonColor = false
                pill.Active = true
                pill.ZIndex = 3
                pill.Parent = frame

                local pillCorner = Instance.new('UICorner')

                pillCorner.CornerRadius = UDim.new(1, 0)
                pillCorner.Parent = pill

                local pillStroke = Instance.new('UIStroke')

                pillStroke.Color = theme.ElementStroke or Color3.fromHex('#2b2b2b')
                pillStroke.Thickness = 1
                pillStroke.Transparency = 0.4
                pillStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                pillStroke.Parent = pill

                local self = setmetatable({}, Keybind)::Keybind

                self.value = initKey
                self._frame = frame;
                (self::any)._pill = pill;
                (self::any)._pillStroke = pillStroke;
                (self::any)._stroke = stroke;
                (self::any)._theme = theme;
                (self::any)._flag = flagKey;
                (self::any)._callback = callback;
                (self::any)._onChanged = onChanged;
                (self::any)._recording = false
                (self::any)._hold = hold;
                (self::any)._threshold = holdThreshold;
                (self::any)._titleLabel = titleLabel

                local pillTween_kb: Tween? = nil

                local function sizePill(animate: boolean)
                    local label = pill.Text
                    local txtWidth = textMetrics.textWidth(constants.DEFAULT_FONT_MEDIUM, 12, label)
                    local frameW = frame.AbsoluteSize.X
                    local isNarrow = frameW > 0 and frameW < 380
                    local maxW = if isNarrow then math.clamp(math.floor(frameW * 0.4), 55, 100)else 160
                    local minW = if isNarrow then 40 else 44
                    local targetWidth = math.clamp(math.floor(txtWidth + 24), minW, maxW)

                    if pillTween_kb then
                        tween.cancel(pillTween_kb)

                        pillTween_kb = nil
                    end

                    pillTween_kb = tween.resizePill(pill, UDim2.fromOffset(targetWidth, 26), animate)
                    textContainer.Size = UDim2.new(1, -(targetWidth + 24), 1, -8)
                end

                (self::any)._sizePill = sizePill

                sizePill(false)
                frame:GetPropertyChangedSignal('AbsoluteSize'):Connect(function()
                    sizePill(false)
                end)

                local hitBtn = Instance.new('TextButton')

                hitBtn.Name = 'Interact'
                hitBtn.Size = UDim2.fromScale(1, 1)
                hitBtn.BackgroundTransparency = 1
                hitBtn.Text = ''
                hitBtn.AutoButtonColor = false
                hitBtn.Active = true
                hitBtn.ZIndex = 1
                hitBtn.Parent = frame

                local sinkActionName = 'Delirium_KeybindSink_' .. runtime.httpService:GenerateGUID(false)

                local function stopRecording()
                    local _s = self::any

                    if not _s._recording then
                        return
                    end

                    _s._recording = false

                    if _s._updateListeners then
                        _s._updateListeners()
                    end
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
                        Color = theme.ElementStroke or Color3.fromHex('#2b2b2b'),
                        Transparency = 0.4,
                    })
                    tween.fire(pill, constants.tweenFocus, {
                        BackgroundColor3 = theme.FieldBackground or Color3.fromRGB(255, 255, 255),
                        BackgroundTransparency = theme.FieldTransparency or 0.9,
                    })
                end
                local function startRecording()
                    local _s = self::any

                    if _s._recording then
                        stopRecording()

                        return
                    end
                    if activeRecordingKeybind and activeRecordingKeybind ~= self then
                        local other = activeRecordingKeybind
                        local _o = other::any

                        if _o._stopRecording then
                            _o:_stopRecording()
                        end
                    end

                    activeRecordingKeybind = self
                    _s._recording = true

                    if _s._updateListeners then
                        _s._updateListeners()
                    end

                    pill.Modal = true

                    pcall(function()
                        local keyCodes = Enum.KeyCode:GetEnumItems()

                        runtime.contextActionService:BindActionAtPriority(sinkActionName, function(
                        )
                            return Enum.ContextActionResult.Sink
                        end, false, Enum.ContextActionPriority.High.Value + 2000, Enum.UserInputType.MouseButton1, Enum.UserInputType.MouseButton2, Enum.UserInputType.MouseButton3, Enum.UserInputType.Touch, table.unpack(keyCodes))
                    end)

                    pill.Text = '...'
                    pill.TextTransparency = 0

                    sizePill(true)
                    tween.fire(pillStroke, constants.tweenFocus, {
                        Color = theme.AccentColor or Color3.fromHex('#4cc2ff'),
                        Transparency = 0,
                    })
                    tween.fire(pill, constants.tweenFocus, {
                        BackgroundColor3 = theme.AccentColor or Color3.fromHex('#4cc2ff'),
                        BackgroundTransparency = 0.85,
                    })
                end

                (self::any)._stopRecording = stopRecording;
                (self::any)._sinkAction = sinkActionName

                local suppressNextClick = false

                pill.Activated:Connect(function()
                    if suppressNextClick then
                        suppressNextClick = false

                        return
                    end
                    if (self::any)._recording then
                        stopRecording()
                    else
                        startRecording()
                    end
                end)
                hitBtn.Activated:Connect(function()
                    if suppressNextClick then
                        suppressNextClick = false

                        return
                    end
                    if (self::any)._recording then
                        stopRecording()
                    else
                        startRecording()
                    end
                end)

                local isHolding = false
                local hasFiredHold = false
                local holdStartTime = 0

                local function matchesInput(
                    input: InputObject,
                    targetKey: EnumItem
                ): boolean
                    if targetKey == Enum.KeyCode.Unknown then
                        return false
                    end
                    if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == targetKey then
                        return true
                    elseif input.UserInputType == targetKey then
                        return true
                    elseif input.UserInputType == Enum.UserInputType.Touch and targetKey == Enum.UserInputType.MouseButton1 then
                        return true
                    end

                    return false
                end
                local function onInputBegan(
                    input: InputObject,
                    gameProcessed: boolean
                )
                    if (self::any)._recording then
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
                        elseif input.UserInputType == Enum.UserInputType.MouseButton2 or input.UserInputType == Enum.UserInputType.MouseButton3 then
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
                    if gameProcessed then
                        return
                    end
                    if matchesInput(input, self.value) then
                        if hold then
                            isHolding = true
                            hasFiredHold = false
                            holdStartTime = os.clock()

                            task.delay(holdThreshold, function()
                                if isHolding and (os.clock() - holdStartTime) >= holdThreshold then
                                    hasFiredHold = true

                                    if callback then
                                        task.spawn(callback, self.value, true)
                                    end
                                end
                            end)
                        else
                            if callback then
                                task.spawn(callback, self.value, false)
                            end
                        end
                    end
                end
                local function onInputEnded(input: InputObject)
                    if not isHolding then
                        return
                    end
                    if matchesInput(input, self.value) then
                        isHolding = false

                        if hasFiredHold then
                            hasFiredHold = false

                            if callback then
                                task.spawn(callback, self.value, false)
                            end
                        end
                    end
                end
                local function updateListeners()
                    local s = self::any
                    local needsListener = s._recording or (self.value ~= Enum.KeyCode.Unknown)

                    if needsListener then
                        if not s._inputConn then
                            s._inputConn = runtime.userInputService.InputBegan:Connect(onInputBegan)
                        end
                        if hold then
                            if not s._inputEndedConn then
                                s._inputEndedConn = runtime.userInputService.InputEnded:Connect(onInputEnded)
                            end
                        end
                    else
                        if s._inputConn then
                            s._inputConn:Disconnect()

                            s._inputConn = nil
                        end
                        if s._inputEndedConn then
                            s._inputEndedConn:Disconnect()

                            s._inputEndedConn = nil
                        end
                    end
                end

                (self::any)._updateListeners = updateListeners

                updateListeners();

                (self::any)._themeUnsub = themeUtil.subscribe(function(t)
                    self._theme = t
                    theme = t
                    titleLabel.TextColor3 = t.ContentColor or Color3.fromHex('#ffffff')
                    titleLabel.FontFace = t.Font or constants.DEFAULT_FONT_MEDIUM
                    frame.BackgroundTransparency = t.ElementTransparency or 0
                    pill.BackgroundColor3 = t.FieldBackground or Color3.fromRGB(255, 255, 255)
                    pill.BackgroundTransparency = t.FieldTransparency or 0.9
                    pill.TextColor3 = t.ContentColor or Color3.fromHex('#ffffff')
                    pill.FontFace = t.Font or constants.DEFAULT_FONT_MEDIUM
                    pillStroke.Color = t.ElementStroke or Color3.fromHex('#2b2b2b')
                    stroke.Color = t.ElementStroke or Color3.fromHex('#2b2b2b')
                    stroke.Transparency = t.ElementStrokeTransparency or 0
                    gradient.Color = t.ElementGradient or ColorSequence.new({
                        ColorSequenceKeypoint.new(0, Color3.fromHex('#2e2e2e')),
                        ColorSequenceKeypoint.new(1, Color3.fromHex('#181818')),
                    })
                end, frame)

                return self
            end
            function Keybind:Set(value: EnumItem | string, skipChanged: boolean?)
                if (self::any).locked and not skipChanged then
                    return
                end

                local key = coerceKey(value)

                self.value = key

                local pill: TextButton = (self::any)._pill
                local flagKey = (self::any)._flag
                local onChanged = (self::any)._onChanged

                pill.Text = keyLabel(key)

                local sizePill = (self::any)._sizePill

                if sizePill then
                    sizePill(true)
                end

                local updateListeners = (self::any)._updateListeners

                if updateListeners then
                    updateListeners()
                end
                if flagKey then
                    flags:Set(flagKey, key.Name)
                end
                if not skipChanged and onChanged then
                    task.spawn(onChanged, key)
                end
            end
            function Keybind:_setShown(shown: boolean, animate: boolean?)
                local s = self::any
                local t = (s._theme or {})::{[string]: any}
                local info = if animate ~= false then constants.tweenNormal else nil
                local frameTrans = if shown then(t.ElementTransparency or 0)else 1
                local strokeTrans = if shown then(t.ElementStrokeTransparency or 0)else 1
                local textTrans = if shown then 0 else 1
                local pillTrans = if shown then(t.FieldTransparency or 0.9)else 1

                if info then
                    tween.play(self._frame, info, {BackgroundTransparency = frameTrans})

                    if s._stroke then
                        tween.play(s._stroke, info, {Transparency = strokeTrans})
                    end
                    if s._titleLabel then
                        tween.play(s._titleLabel, info, {TextTransparency = textTrans})
                    end
                    if s._pill then
                        tween.play(s._pill, info, {BackgroundTransparency = pillTrans})
                    end
                else
                    self._frame.BackgroundTransparency = frameTrans

                    if s._stroke then
                        s._stroke.Transparency = strokeTrans
                    end
                    if s._titleLabel then
                        s._titleLabel.TextTransparency = textTrans
                    end
                    if s._pill then
                        s._pill.BackgroundTransparency = pillTrans
                    end
                end
            end
            function Keybind:Destroy()
                local s = (self::any)

                if s._recording and s._stopRecording then
                    s._stopRecording()
                end
                if s._sinkAction then
                    pcall(function()
                        runtime.contextActionService:UnbindAction(s._sinkAction)
                    end)
                end
                if s._inputConn then
                    s._inputConn:Disconnect()
                end
                if s._inputEndedConn then
                    s._inputEndedConn:Disconnect()
                end
                if s._themeUnsub then
                    s._themeUnsub()
                end
                if s._descriptor then
                    s._descriptor:Destroy()
                end

                self._frame:Destroy()
            end

            moveable(Keybind)
            lockable(Keybind)

            return Keybind
        end)()
    end,
    [23] = function()
        local wax, script, require = ImportGlobals(23)
        local ImportGlobals

        return (function(...)
            local constants = require(script.Parent.Parent.utility.constants)
            local tween = require(script.Parent.Parent.utility.tween)
            local functions = require(script.Parent.Parent.utility.functions)
            local variables = require(script.Parent.Parent.utility.variables)

            export type TagProps = {text: string?, icon: (string | number)?, color: Color3?, order: number?, title: string?}
            export type Tag = {color: Color3, text: string?, SetColor: (self:Tag, color:Color3) -> (), SetText: (self:Tag, text:string?) -> (), SetIcon: (self:Tag, icon:(string | number)?) -> (), Set: (self:Tag, props:TagProps) -> (), _setShown: (self:Tag, shown:boolean, animate:boolean?) -> (), Remove: (self:Tag) -> ()}

            local Tag = {}

            Tag.__index = Tag

            local DEFAULT_COLOR = Color3.fromRGB(255, 175, 15)
            local TAG_TWEEN = TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

            function Tag.new(window: any, props: TagProps): Tag
                props = if typeof(props) == 'table'then props else{}::TagProps

                local text = props.text or props.title
                local iconId = props.icon
                local color = if typeof(props.color) == 'Color3'then props.color else DEFAULT_COLOR

                assert(iconId or (text and text ~= ''), 'Tag requires icon, text, or both')

                local container: Frame = window.tagContainer
                local contrast = functions.contrastColor(color)
                local pill = Instance.new('Frame')

                pill.Name = 'Tag'
                pill.Size = UDim2.fromOffset(10, 24)
                pill.AutomaticSize = Enum.AutomaticSize.X
                pill.BackgroundColor3 = color
                pill.BackgroundTransparency = 1
                pill.BorderSizePixel = 0
                pill.LayoutOrder = props.order or 0
                pill.Parent = container

                local pillCorner = Instance.new('UICorner')

                pillCorner.CornerRadius = UDim.new(1, 0)
                pillCorner.Parent = pill

                local pillPad = Instance.new('UIPadding')

                pillPad.PaddingLeft = UDim.new(0, 10)
                pillPad.PaddingRight = UDim.new(0, 10)
                pillPad.Parent = pill

                local pillList = Instance.new('UIListLayout')

                pillList.Padding = UDim.new(0, 5)
                pillList.FillDirection = Enum.FillDirection.Horizontal
                pillList.VerticalAlignment = Enum.VerticalAlignment.Center
                pillList.SortOrder = Enum.SortOrder.LayoutOrder
                pillList.Parent = pill

                local iconLabel = Instance.new('ImageLabel')

                iconLabel.Name = 'Icon'
                iconLabel.Image = if iconId then'rbxassetid://' .. tostring(iconId)else''
                iconLabel.ImageColor3 = contrast
                iconLabel.ImageTransparency = 1
                iconLabel.Size = UDim2.fromOffset(16, 16)
                iconLabel.BackgroundTransparency = 1
                iconLabel.BorderSizePixel = 0
                iconLabel.Visible = iconId ~= nil
                iconLabel.ZIndex = 5
                iconLabel.LayoutOrder = 0
                iconLabel.Parent = pill

                local titleLabel = Instance.new('TextLabel')

                titleLabel.Name = 'Title'
                titleLabel.Size = UDim2.fromOffset(10, 15)
                titleLabel.AutomaticSize = Enum.AutomaticSize.X
                titleLabel.BackgroundTransparency = 1
                titleLabel.BorderSizePixel = 0
                titleLabel.Text = text or ''
                titleLabel.TextColor3 = contrast
                titleLabel.TextTransparency = 1
                titleLabel.TextSize = 15
                titleLabel.FontFace = Font.fromName('GothamSSm', Enum.FontWeight.SemiBold)
                titleLabel.TextXAlignment = Enum.TextXAlignment.Left
                titleLabel.TextWrapped = true
                titleLabel.RichText = true
                titleLabel.Visible = text ~= nil and text ~= ''
                titleLabel.LayoutOrder = 1
                titleLabel.ZIndex = 5
                titleLabel.Parent = pill
                container.Visible = true

                local self = setmetatable({}, Tag)::Tag

                self.color = color
                self.text = text

                local s = self::any

                s._pill = pill
                s._iconLabel = iconLabel
                s._titleLabel = titleLabel
                s._window = window

                if not window.hidden then
                    local target = 0

                    variables.tweenService:Create(pill, TAG_TWEEN, {BackgroundTransparency = target}):Play()
                    variables.tweenService:Create(iconLabel, TAG_TWEEN, {ImageTransparency = target}):Play()
                    variables.tweenService:Create(titleLabel, TAG_TWEEN, {TextTransparency = target}):Play()
                end

                return self
            end
            function Tag:SetColor(color: Color3)
                local s = self::any

                self.color = color

                local contrast = functions.contrastColor(color)

                variables.tweenService:Create(s._pill, TAG_TWEEN, {BackgroundColor3 = color}):Play()
                variables.tweenService:Create(s._iconLabel, TAG_TWEEN, {ImageColor3 = contrast}):Play()
                variables.tweenService:Create(s._titleLabel, TAG_TWEEN, {TextColor3 = contrast}):Play()
            end
            function Tag:SetText(text: string?)
                local s = self::any

                self.text = text
                s._titleLabel.Text = text or ''
                s._titleLabel.Visible = text ~= nil and text ~= ''
            end
            function Tag:SetIcon(icon: (string | number)?)
                local s = self::any

                s._iconLabel.Image = if icon then'rbxassetid://' .. tostring(icon)else''
                s._iconLabel.Visible = icon ~= nil
            end
            function Tag:Set(props: TagProps)
                local color = props.color or (props::any).Color
                local text = props.text or props.title or (props::any).Text or (props::any).Title
                local icon = props.icon or (props::any).Icon

                if color then
                    self:SetColor(color)
                end
                if text ~= nil then
                    self:SetText(text)
                end
                if icon ~= nil then
                    self:SetIcon(icon)
                end
            end
            function Tag:_setShown(shown: boolean, animate: boolean?)
                local s = self::any
                local target = if shown then 0 else 1
                local info = if animate ~= false then TAG_TWEEN else nil

                if info then
                    variables.tweenService:Create(s._pill, info, {BackgroundTransparency = target}):Play()
                    variables.tweenService:Create(s._iconLabel, info, {ImageTransparency = target}):Play()
                    variables.tweenService:Create(s._titleLabel, info, {TextTransparency = target}):Play()
                else
                    s._pill.BackgroundTransparency = target
                    s._iconLabel.ImageTransparency = target
                    s._titleLabel.TextTransparency = target
                end
            end
            function Tag:Remove()
                local s = self::any
                local w = s._window
                local remaining = 0

                for _, child in ipairs(w.tagContainer:GetChildren())do
                    if child:IsA('Frame') and child ~= s._pill then
                        remaining += 1
                    end
                end

                if remaining == 0 then
                    w.tagContainer.Visible = false
                end

                s._pill:Destroy()
            end

            return Tag
        end)()
    end,
    [51] = function()
        local wax, script, require = ImportGlobals(51)
        local ImportGlobals

        return (function(...)
            local function lockable<T>(class: T): T
                local target = class::any

                function target:Lock(reason: string?)
                    if self.window and self.window._setElementLocked then
                        self.window:_setElementLocked(self, true, reason)
                    else
                        self.locked = true
                    end
                end
                function target:Unlock()
                    if self.window and self.window._setElementLocked then
                        self.window:_setElementLocked(self, false)
                    else
                        self.locked = false
                    end
                end
                function target:IsLocked(): boolean
                    return self.locked == true
                end

                return class
            end

            return lockable
        end)()
    end,
    [25] = function()
        local wax, script, require = ImportGlobals(25)
        local ImportGlobals

        return (function(...)
            local constants = require(script.Parent.Parent.utility.constants)
            local functions = require(script.Parent.Parent.utility.functions)
            local tween = require(script.Parent.Parent.utility.tween)
            local variables = require(script.Parent.Parent.utility.variables)

            export type ToastProps = {title: string?, subtitle: string?, icon: (string | number)?, duration: number?, position: string?, subtitleAbove: boolean?, minWidth: number?}

            local Toast = {}

            Toast.__index = Toast

            local SLIDE_INFO = TweenInfo.new(0.6, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
            local GROW_INFO = TweenInfo.new(0.6, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
            local FADE_LONG = TweenInfo.new(0.4, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
            local FADE_SHORT = TweenInfo.new(0.3, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
            local SHRINK_INFO = TweenInfo.new(0.6, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
            local ICON_SIZE = 24
            local LEFT_PAD = 18
            local RIGHT_PAD = 18
            local ICON_GAP = 12
            local STACK_PAD = 8
            local MIN_WIDTH = 140
            local MAX_WIDTH = 320
            local MAX_LIVE = 6
            local OFFSCREEN_ABOVE = UDim2.new(0.5, 0, 0.5, -180)
            local OFFSCREEN_BELOW = UDim2.new(0.5, 0, 0.5, 180)
            local CENTRED = UDim2.new(0.5, 0, 0.5, 0)

            local function autoDuration(title: string, sub: string?): number
                return math.clamp(#title * 0.06 + (if sub then#sub * 0.04 else 0) + 3, 3, 9)
            end

            function Toast.new(
                window: any,
                props: ToastProps,
                container: Frame
            )
                props = if typeof(props) == 'table'then props else{}::ToastProps

                local title = props.title or ''
                local subtitle = props.subtitle
                local iconId = props.icon
                local position = props.position or 'Top'
                local subtitleAbove = props.subtitleAbove == true
                local minWidth = math.clamp(props.minWidth or 0, MIN_WIDTH, MAX_WIDTH)
                local duration = props.duration or autoDuration(title, subtitle)
                local hasIcon = iconId ~= nil and iconId ~= 0 and iconId ~= ''
                local hasSubtitle = subtitle ~= nil and subtitle ~= ''
                local theme = (window::any)._theme or {}
                local main = Instance.new('Frame')

                main.Name = 'Toast'
                main.BackgroundTransparency = 1
                main.Size = UDim2.new(0, 0, 0, 0)
                main.BorderSizePixel = 0
                main.ZIndex = constants.zIndex.toast
                main.Parent = container

                local slotPad = Instance.new('UIPadding')

                slotPad.PaddingTop = UDim.new(0, STACK_PAD)
                slotPad.Parent = main

                local body = Instance.new('Frame')

                body.Name = 'Body'
                body.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                body.BackgroundTransparency = 1
                body.Size = UDim2.new(1, 0, 1, 0)
                body.Position = if position == 'Bottom'then OFFSCREEN_BELOW else OFFSCREEN_ABOVE
                body.AnchorPoint = Vector2.new(0.5, 0.5)
                body.Active = true
                body.BorderSizePixel = 0
                body.ZIndex = constants.zIndex.toast
                body.Parent = main

                local bodyGrad = Instance.new('UIGradient')

                bodyGrad.Color = functions.toColorSequence(theme.WindowColor or Color3.fromRGB(30, 30, 35))
                bodyGrad.Rotation = 270
                bodyGrad.Offset = Vector2.new(0, -0.1)
                bodyGrad.Parent = body

                local bodyCorner = Instance.new('UICorner')

                bodyCorner.CornerRadius = UDim.new(1, 0)
                bodyCorner.Parent = body

                local stroke = Instance.new('UIStroke')

                stroke.Color = theme.SurfaceStroke or Color3.fromRGB(60, 60, 70)
                stroke.Transparency = 1
                stroke.Thickness = 1
                stroke.Parent = body

                local bodyPad = Instance.new('UIPadding')

                bodyPad.PaddingLeft = UDim.new(0, LEFT_PAD)
                bodyPad.PaddingRight = UDim.new(0, RIGHT_PAD)
                bodyPad.Parent = body

                local bodyList = Instance.new('UIListLayout')

                bodyList.FillDirection = Enum.FillDirection.Horizontal
                bodyList.VerticalAlignment = Enum.VerticalAlignment.Center
                bodyList.HorizontalAlignment = Enum.HorizontalAlignment.Left
                bodyList.SortOrder = Enum.SortOrder.LayoutOrder
                bodyList.Padding = UDim.new(0, ICON_GAP)
                bodyList.Parent = body

                local iconLabel: ImageLabel? = nil

                if hasIcon then
                    local img = Instance.new('ImageLabel')

                    img.Name = 'Icon'
                    img.Image = 'rbxassetid://' .. tostring(iconId)
                    img.ImageColor3 = theme.ContentColor or Color3.fromRGB(220, 215, 240)
                    img.ImageTransparency = 1
                    img.Size = UDim2.fromOffset(ICON_SIZE, ICON_SIZE)
                    img.BackgroundTransparency = 1
                    img.BorderSizePixel = 0
                    img.LayoutOrder = 1
                    img.ZIndex = constants.zIndex.toastContent
                    img.Parent = body

                    local imgCorner = Instance.new('UICorner')

                    imgCorner.CornerRadius = UDim.new(1, 0)
                    imgCorner.Parent = img
                    iconLabel = img
                end

                local textCol = Instance.new('Frame')

                textCol.Name = 'Text'
                textCol.AutomaticSize = Enum.AutomaticSize.X
                textCol.Size = UDim2.fromOffset(0, if hasSubtitle then 32 else 16)
                textCol.BackgroundTransparency = 1
                textCol.BorderSizePixel = 0
                textCol.LayoutOrder = 2
                textCol.ZIndex = constants.zIndex.toastContent
                textCol.Parent = body

                local textList = Instance.new('UIListLayout')

                textList.FillDirection = Enum.FillDirection.Vertical
                textList.VerticalAlignment = Enum.VerticalAlignment.Center
                textList.SortOrder = Enum.SortOrder.LayoutOrder
                textList.Padding = UDim.new(0, 1)
                textList.Parent = textCol

                local titleLabel = Instance.new('TextLabel')

                titleLabel.Name = 'Title'
                titleLabel.Text = title
                titleLabel.AutomaticSize = Enum.AutomaticSize.X
                titleLabel.Size = UDim2.fromOffset(0, 16)
                titleLabel.BackgroundTransparency = 1
                titleLabel.BorderSizePixel = 0
                titleLabel.TextColor3 = theme.ContentColor or Color3.fromRGB(255, 255, 255)
                titleLabel.TextTransparency = 1
                titleLabel.TextSize = 16
                titleLabel.FontFace = theme.TitleFont or constants.DEFAULT_FONT_SEMI
                titleLabel.TextXAlignment = Enum.TextXAlignment.Left
                titleLabel.LayoutOrder = if subtitleAbove then 2 else 1
                titleLabel.ZIndex = constants.zIndex.toastContent
                titleLabel.Parent = textCol

                local subtitleLabel: TextLabel? = nil

                if hasSubtitle then
                    local sub = Instance.new('TextLabel')

                    sub.Name = 'Subtitle'
                    sub.Text = subtitle::string
                    sub.AutomaticSize = Enum.AutomaticSize.X
                    sub.Size = UDim2.fromOffset(0, 14)
                    sub.BackgroundTransparency = 1
                    sub.BorderSizePixel = 0
                    sub.TextColor3 = theme.ContentColor or Color3.fromRGB(200, 200, 220)
                    sub.TextTransparency = 1
                    sub.TextSize = 14
                    sub.FontFace = theme.Font or constants.DEFAULT_FONT
                    sub.TextXAlignment = Enum.TextXAlignment.Left
                    sub.LayoutOrder = if subtitleAbove then 1 else 2
                    sub.ZIndex = constants.zIndex.toastContent
                    sub.Parent = textCol
                    subtitleLabel = sub
                end

                local w = window::any

                w._toastCount = (w._toastCount or 0) + 1
                main.LayoutOrder = -w._toastCount

                if not w._liveToasts then
                    w._liveToasts = {}
                end

                local live = w._liveToasts[container]

                if not live then
                    live = {}
                    w._liveToasts[container] = live
                end

                local self = setmetatable({}, Toast)
                local s = self::any

                s._main = main
                s._body = body
                s._stroke = stroke
                s._titleLabel = titleLabel
                s._subtitleLabel = subtitleLabel
                s._iconLabel = iconLabel
                s._live = live
                s._hovered = false
                s._dismissed = false
                s._duration = duration
                s._position = position
                s._minWidth = minWidth
                s._hasIcon = hasIcon
                s._theme = theme
                s._window = window
                s._connections = {}

                table.insert(live, self)

                while#live > MAX_LIVE do
                    local oldest = table.remove(live, 1)

                    if oldest and oldest ~= self then
                        task.spawn(function()
                            oldest:_dismiss()
                        end)
                    end
                end

                local function addConn(sig, fn)
                    local c = sig:Connect(fn)

                    table.insert(s._connections, c)
                end

                addConn(body.MouseEnter, function()
                    s._hovered = true
                end)
                addConn(body.MouseLeave, function()
                    s._hovered = false
                end)
                addConn(body.InputBegan, function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        self:_dismiss()
                    end
                end)
                task.spawn(function()
                    self:_show()
                end)

                return self
            end
            function Toast:_measure(): (number,number)
                local s = self::any
                local t = s._theme or {}
                local titleW = functions.textWidth(t.TitleFont or constants.DEFAULT_FONT_SEMI, 16, (s._titleLabel::TextLabel).Text)
                local subW = if s._subtitleLabel then functions.textWidth(t.Font or constants.DEFAULT_FONT, 14, s._subtitleLabel.Text)else 0
                local textW = math.max(titleW, subW)
                local leftTotal = if s._hasIcon then LEFT_PAD + ICON_SIZE + ICON_GAP else LEFT_PAD
                local width = math.clamp(leftTotal + textW + RIGHT_PAD, s._minWidth, MAX_WIDTH)

                if leftTotal + textW + RIGHT_PAD > MAX_WIDTH then
                    local col = MAX_WIDTH - leftTotal - RIGHT_PAD

                    for _, lbl in {
                        s._titleLabel,
                        s._subtitleLabel,
                    }do
                        if lbl then
                            lbl.AutomaticSize = Enum.AutomaticSize.None
                            lbl.TextTruncate = Enum.TextTruncate.AtEnd
                            lbl.Size = UDim2.fromOffset(col, lbl.Size.Y.Offset)
                        end
                    end
                end

                local textH = if s._subtitleLabel then 31 else 16
                local height = math.max(textH, if s._hasIcon then ICON_SIZE else 0) + 18

                return width, height
            end
            function Toast:_show()
                local s = self::any

                if not s._main.Parent then
                    return
                end

                local width, height = self:_measure()

                if s._dismissed or not s._main.Parent then
                    return
                end

                s._main.Size = UDim2.new(0, width, 0, 0)

                variables.tweenService:Create(s._main, GROW_INFO, {
                    Size = UDim2.new(0, width, 0, height + STACK_PAD),
                }):Play()
                variables.tweenService:Create(s._body, SLIDE_INFO, {Position = CENTRED}):Play()
                variables.tweenService:Create(s._body, FADE_LONG, {BackgroundTransparency = 0}):Play()
                variables.tweenService:Create(s._stroke, FADE_LONG, {Transparency = 0.9}):Play()
                variables.tweenService:Create(s._titleLabel, FADE_SHORT, {TextTransparency = 0}):Play()
                task.wait(0.05)

                if s._dismissed or not s._main.Parent then
                    return
                end
                if s._iconLabel then
                    variables.tweenService:Create(s._iconLabel, FADE_SHORT, {ImageTransparency = 0}):Play()
                end

                task.wait(0.05)

                if s._dismissed or not s._main.Parent then
                    return
                end
                if s._subtitleLabel then
                    variables.tweenService:Create(s._subtitleLabel, FADE_SHORT, {TextTransparency = 0.5}):Play()
                end

                local elapsed = 0

                while elapsed < s._duration and not s._dismissed and s._main.Parent do
                    local dt = task.wait()

                    if not s._hovered then
                        elapsed += dt
                    end
                end

                self:_dismiss()
            end
            function Toast:_dismiss()
                local s = self::any

                if s._dismissed then
                    return
                end

                s._dismissed = true

                local idx = table.find(s._live, self)

                if idx then
                    table.remove(s._live, idx)
                end
                if not s._main.Parent then
                    for _, c in ipairs(s._connections)do
                        c:Disconnect()
                    end

                    return
                end

                variables.tweenService:Create(s._body, FADE_LONG, {BackgroundTransparency = 1}):Play()
                variables.tweenService:Create(s._stroke, FADE_LONG, {Transparency = 1}):Play()
                variables.tweenService:Create(s._titleLabel, FADE_SHORT, {TextTransparency = 1}):Play()

                if s._subtitleLabel then
                    variables.tweenService:Create(s._subtitleLabel, FADE_SHORT, {TextTransparency = 1}):Play()
                end
                if s._iconLabel then
                    variables.tweenService:Create(s._iconLabel, FADE_SHORT, {ImageTransparency = 1}):Play()
                end

                variables.tweenService:Create(s._body, SHRINK_INFO, {
                    Size = UDim2.new(1, -60, 1, 0),
                }):Play()

                local collapse = variables.tweenService:Create(s._main, SHRINK_INFO, {
                    Size = UDim2.new(0, s._main.Size.X.Offset, 0, 0),
                })

                collapse:Play()
                collapse.Completed:Wait()

                for _, c in ipairs(s._connections)do
                    c:Disconnect()
                end

                if s._main.Parent then
                    s._main:Destroy()
                end
            end

            return Toast
        end)()
    end,
    [47] = function()
        local wax, script, require = ImportGlobals(47)
        local ImportGlobals

        return (function(...)
            local imageCache = require(script.Parent.imageCache)

            export type OnSettled = imageCache.OnSettled
            export type AvatarReady = imageCache.AvatarReady

            local image = {}

            image.rewrites = imageCache.rewrites
            image.onBlock = nil::((value:unknown) -> ())?
            image.pending = {}::{[number]: {[Instance]: {[string]: boolean}}}

            local settled = false
            local imageProperties: {[string]: boolean} = {
                Image = true,
                HoverImage = true,
                PressedImage = true,
            }

            local function idOf(value: unknown): number?
                if type(value) == 'number' then
                    return value
                end
                if type(value) == 'string' then
                    return tonumber(string.match(value::string, '^rbxassetid://(%d+)$'))
                end

                return nil
            end
            local function blocked(value: unknown): string
                if image.onBlock then
                    image.onBlock(value)
                end

                return ''
            end

            imageCache.onCached = function(id: number)
                local waiting = image.pending[id]

                if not waiting then
                    return
                end

                local uri = image.rewrites[id]

                if uri then
                    for instance, props in waiting do
                        if instance.Parent then
                            local t = instance::any

                            for prop in props do
                                t[prop] = uri
                            end
                        end
                    end
                end

                image.pending[id] = nil
            end

            function image.preload(manifest: {[number]: string}, onSettled: OnSettled?): (boolean,number)
                settled = false

                return imageCache.preload(manifest, function(failed)
                    settled = true

                    table.clear(image.pending)

                    if onSettled then
                        onSettled(failed)
                    end
                end)
            end
            function image.avatar(userId: number, onReady: AvatarReady?): string
                return imageCache.avatar(userId, onReady)
            end
            function image.resolve(value: unknown): string
                if value == nil or value == 0 or value == '' then
                    return ''
                end
                if type(value) == 'string' then
                    local s = value::string

                    if string.sub(s, 1, 11) == 'rbxasset://' then
                        return s
                    end
                end

                local id: number? = idOf(value)

                if id then
                    local rewrite = image.rewrites[id]

                    if rewrite then
                        return rewrite
                    end
                end
                if type(value) == 'number' then
                    return 'rbxassetid://' .. tostring(value)
                end
                if type(value) == 'string' then
                    return value
                end

                return blocked(value)
            end
            function image.assign(
                instance: Instance,
                property: string,
                value: unknown
            )
                local target = instance::any

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
                            slot = setmetatable({}, {
                                __mode = 'k',
                            })::any
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
        end)()
    end,
    [65] = function()
        local wax, script, require = ImportGlobals(65)
        local ImportGlobals

        return (function(...)
            local defaultTheme = require(script.Parent.Parent.themes.default)
            local lightTheme = require(script.Parent.Parent.themes.light)
            local draculaTheme = require(script.Parent.Parent.themes.dracula)

            export type ThemeTable = {[string]: any}
            export type ThemeInput = string | ThemeTable
            export type ThemeListener = (resolved:ThemeTable) -> ()
            export type Unsubscribe = () -> ()
            export type Binding = {key: string, set: (value:any) -> ()}
            export type BindingList = {Binding}
            export type ValidationResult = {missing: {string}, unknown: {string}}
            export type DiffResult = {[string]: {from: any, to: any}}

            local _registry: {[string]: ThemeTable} = {
                Default = defaultTheme,
                Light = lightTheme,
                Dracula = draculaTheme,
            }
            local _lower: {[string]: string} = {}

            for name in _registry do
                _lower[string.lower(name)] = name
            end

            local _subscribers: {[number]: ThemeListener} = {}
            local _nextId = 0
            local _current: ThemeTable = table.clone(defaultTheme)

            local function _canonicalName(name: string): string?
                if _registry[name] then
                    return name
                end

                return _lower[string.lower(name)]
            end

            local theme = {}

            function theme.resolve(input: ThemeInput?): ThemeTable
                if input == nil then
                    return table.clone(defaultTheme)
                end
                if typeof(input) == 'string' then
                    local canonical = _canonicalName(input)

                    if not canonical then
                        warn(string.format('[Delirium] Unknown theme "%s", falling back to Default.', input))

                        return table.clone(defaultTheme)
                    end
                    if canonical == 'Default' then
                        return table.clone(defaultTheme)
                    end

                    return theme.merge(defaultTheme, _registry[canonical])
                end

                return theme.merge(defaultTheme, input::ThemeTable)
            end
            function theme.merge(base: ThemeTable, override: ThemeTable): ThemeTable
                local result = table.clone(base)

                for k, v in override do
                    result[k] = v
                end

                return result
            end
            function theme.subscribe(
                listener: ThemeListener,
                boundInstance: Instance?
            ): Unsubscribe
                _nextId += 1

                local id = _nextId

                _subscribers[id] = listener

                local destroyConn: RBXScriptConnection? = nil

                if boundInstance then
                    destroyConn = boundInstance.Destroying:Connect(function()
                        _subscribers[id] = nil

                        if destroyConn then
                            destroyConn:Disconnect()

                            destroyConn = nil
                        end
                    end)
                end

                listener(_current)

                return function()
                    _subscribers[id] = nil

                    if destroyConn then
                        destroyConn:Disconnect()

                        destroyConn = nil
                    end
                end
            end
            function theme.broadcast(resolved: ThemeTable)
                _current = resolved

                for _, listener in _subscribers do
                    local ok, err = pcall(listener, resolved)

                    if not ok then
                        warn('[Delirium] theme.broadcast listener error: ' .. tostring(err))
                    end
                end
            end
            function theme.current(): ThemeTable
                return _current
            end
            function theme.setCurrent(t: ThemeTable)
                _current = t
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
                if name == 'Default' then
                    warn('[Delirium] theme.registerTheme: cannot overwrite "Default".')

                    return
                end
                if typeof(input) == 'string' then
                    local canonical = _canonicalName(input)

                    if not canonical then
                        warn(string.format(
[[[Delirium] theme.registerTheme: source theme "%s" not found.]], input))

                        return
                    end

                    _registry[name] = _registry[canonical]
                else
                    _registry[name] = input::ThemeTable
                end

                _lower[string.lower(name)] = name
            end
            function theme.list(): {string}
                local names: {string} = {}

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
                local missing: {string} = {}
                local unknown: {string} = {}

                for key in defaultTheme do
                    if t[key] == nil then
                        table.insert(missing, key)
                    end
                end
                for key in t do
                    if defaultTheme[key] == nil then
                        table.insert(unknown, key)
                    end
                end

                table.sort(missing)
                table.sort(unknown)

                return {
                    missing = missing,
                    unknown = unknown,
                }
            end
            function theme.diff(a: ThemeTable, b: ThemeTable): DiffResult
                local result: DiffResult = {}
                local seen: {[string]: boolean} = {}

                for k in a do
                    seen[k] = true
                end
                for k in b do
                    seen[k] = true
                end
                for k in seen do
                    if a[k] ~= b[k] then
                        result[k] = {
                            from = a[k],
                            to = b[k],
                        }
                    end
                end

                return result
            end

            return theme
        end)()
    end,
    [30] = function()
        local wax, script, require = ImportGlobals(30)
        local ImportGlobals

        return (function(...)
            return {
                WindowColor = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromHex('#282a36')),
                    ColorSequenceKeypoint.new(0.9999, Color3.fromHex('#21222c')),
                    ColorSequenceKeypoint.new(1, Color3.fromHex('#191a21')),
                }),
                ShadowColor = Color3.fromHex('#0b0c10'),
                SurfaceStroke = Color3.fromHex('#44475a'),
                TitleBarColor = Color3.fromHex('#1e1f29'),
                TabColor = Color3.fromHex('#bd93f9'),
                TabBackground = ColorSequence.new(Color3.fromHex('#343746'), Color3.fromHex('#282a36')),
                TabStroke = ColorSequence.new(Color3.fromHex('#44475a'), Color3.fromHex('#2f3140')),
                ElementGradient = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromHex('#343746')),
                    ColorSequenceKeypoint.new(0.9999, Color3.fromHex('#2b2d3a')),
                    ColorSequenceKeypoint.new(1, Color3.fromHex('#242630')),
                }),
                ElementStroke = Color3.fromHex('#44475a'),
                ElementStrokeGradient = ColorSequence.new(Color3.fromHex('#50536a'), Color3.fromHex('#44475a')),
                ElementStrokeHover = Color3.fromHex('#bd93f9'),
                ElementTextHoverColor = Color3.fromHex('#f8f8f2'),
                ContentColor = Color3.fromHex('#f8f8f2'),
                TitlingColor = Color3.fromHex('#ffffff'),
                PlaceholderColor = Color3.fromHex('#8b8fa3'),
                AccentColor = Color3.fromHex('#bd93f9'),
                AccentStroke = Color3.fromHex('#d7b8ff'),
                AccentGlow = 0.4,
                ToggleTrack = Color3.fromHex('#282a36'),
                ToggleTrackTransparency = 0.55,
                ToggleKnobOff = Color3.fromHex('#8b8fa3'),
                ToggleKnobOffTransparency = 0.35,
                DarkToggleOverlay = false,
                SliderBackground = Color3.fromHex('#2b2d3a'),
                SliderBackgroundHover = Color3.fromHex('#343746'),
                SliderProgress = ColorSequence.new(Color3.fromHex('#bd93f9'), Color3.fromHex('#8b5cf6')),
                SliderHandle = Color3.fromHex('#f8f8f2'),
                SliderStroke = Color3.fromHex('#f8f8f2'),
                DropdownHighlight = Color3.fromHex('#f8f8f2'),
                FieldBackground = Color3.fromHex('#f8f8f2'),
                FieldTransparency = 0.9,
                FieldGlow = Color3.fromHex('#bd93f9'),
                PillCornerRadius = UDim.new(1, 0),
                NeutralButton = Color3.fromHex('#343746'),
                NeutralButtonHover = Color3.fromHex('#44475a'),
                NeutralButtonStroke = Color3.fromHex('#44475a'),
                ErrorColor = Color3.fromHex('#ff5555'),
                ErrorStrokeColor = Color3.fromHex('#ff6e67'),
                ActionColor = Color3.fromHex('#f8f8f2'),
                LiveAnimation = false,
            }
        end)()
    end,
    [16] = function()
        local wax, script, require = ImportGlobals(16)
        local ImportGlobals

        return (function(...)
            local constants = require(script.Parent.Parent.utility.constants)
            local variables = require(script.Parent.Parent.utility.variables)
            local runtime = require(script.Parent.Parent.utility.runtime)
            local themeUtil = require(script.Parent.Parent.utility.theme)
            local tween = require(script.Parent.Parent.utility.tween)
            local icons = require(script.Parent.Parent.utility.icons)
            local executor = require(script.Parent.Parent.utility.executor)
            local hapticEngine = require(script.Parent.Parent.utility.HapticEngine)
            local FONT_SEMI = constants.DEFAULT_FONT_SEMI
            local FONT_MED = constants.DEFAULT_FONT_MEDIUM
            local HAS_SERVER_TIME = runtime.workspace ~= nil and typeof((runtime.workspace::any).GetServerTimeNow) == 'function'

            local function now(): number
                if HAS_SERVER_TIME then
                    return (runtime.workspace::any):GetServerTimeNow()
                end

                return os.clock()
            end

            local TOAST_W = 276
            local MAX_VISIBLE = 6
            local GAP = 6
            local MOBILE_SCALE = 0.65
            local TWEEN_IN_SIZE = TweenInfo.new(0.6, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
            local TWEEN_IN_FADE = TweenInfo.new(0.4, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
            local TWEEN_OUT_FADE = TweenInfo.new(0.4, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
            local TWEEN_OUT_SIZE = TweenInfo.new(0.9, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
            local DEFAULT_ICONS: {[string]: string} = {
                info = 'rbxassetid://10723415903',
                success = 'rbxassetid://10709790387',
                warning = 'rbxassetid://10709752935',
                error = 'rbxassetid://10747384394',
            }

            export type NotifyProps = {title: string?, content: string?, duration: number?, type: string?, icon: (string | number)?}
            type ActiveToast = {wrapper: Frame, card: CanvasGroup, stroke: UIStroke, dismissed: boolean, cancelTimer: () -> (), timeLabel: TextLabel, creationTime: number, notifType: string, bottomGlow: Frame, iconBadge: Frame, badgeStroke: UIStroke, iconImg: ImageLabel, titleLbl: TextLabel, msgLbl: TextLabel?, closeBtn: TextButton}

            local _gui: ScreenGui? = nil
            local _container: Frame? = nil
            local _layout: UIListLayout? = nil
            local _active: {ActiveToast} = {}
            local _orderCounter: number = 0
            local _scale: number = 1
            local _clockThread: thread? = nil

            local function typeColor(notifType: string?, theme: {[string]: any}): Color3
                local t = string.lower(notifType or 'info')

                if t == 'success' then
                    return Color3.fromHex('#3ecf8e')
                elseif t == 'warning' then
                    return Color3.fromHex('#f5a524')
                elseif t == 'error' then
                    return theme.ErrorColor or Color3.fromHex('#ff4f58')
                else
                    return theme.AccentColor or Color3.fromHex('#4cc2ff')
                end
            end
            local function resolveIcon(icon: (string | number)?, notifType: string?): string
                if icon and icon ~= '' then
                    local resolved = icons.Resolve(icon)

                    if resolved then
                        return resolved
                    end
                end

                local t = string.lower(notifType or 'info')

                return DEFAULT_ICONS[t] or DEFAULT_ICONS.info
            end
            local function formatElapsed(elapsed: number): string
                if elapsed <= 4 then
                    return 'now'
                elseif elapsed < 60 then
                    return string.format('%ds ago', math.floor(elapsed))
                elseif elapsed < 3600 then
                    return string.format('%dm ago', math.floor(elapsed / 60))
                else
                    return string.format('%dh ago', math.floor(elapsed / 3600))
                end
            end
            local function ensureGui()
                if _gui and _gui.Parent and _container and _container.Parent then
                    return
                end

                local escalated = executor.escalate(8)
                local resolvedContainer = variables.guiContainer

                if not escalated then
                    local lp = variables.localPlayer

                    if lp then
                        local pg = lp:FindFirstChildOfClass('PlayerGui') or lp:FindFirstChild('PlayerGui')

                        if pg then
                            resolvedContainer = pg
                        end
                    end
                end

                local isMobile = variables.userInputService.TouchEnabled and not variables.userInputService.KeyboardEnabled

                if not variables.runService:IsStudio() then
                    local cam = variables.workspace.CurrentCamera
                    local vp = if cam then cam.ViewportSize else Vector2.new(1024, 768)

                    if vp.X < 800 or vp.Y < 600 then
                        isMobile = true
                    end
                end

                _scale = if isMobile then MOBILE_SCALE else 1

                local gui = Instance.new('ScreenGui')

                gui.Name = 'DeliriumNotifications'
                gui.DisplayOrder = constants.displayOrder.notification
                gui.ResetOnSpawn = false
                gui.IgnoreGuiInset = true
                gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
                gui.Parent = resolvedContainer

                local scaledW = math.round(TOAST_W * _scale)
                local c = Instance.new('Frame')

                c.Name = 'Container'
                c.Size = UDim2.fromOffset(scaledW, 0)
                c.AutomaticSize = Enum.AutomaticSize.Y
                c.BackgroundTransparency = 1
                c.BorderSizePixel = 0
                c.ClipsDescendants = false

                local layout = Instance.new('UIListLayout')

                layout.SortOrder = Enum.SortOrder.LayoutOrder
                layout.FillDirection = Enum.FillDirection.Vertical
                layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
                layout.Padding = UDim.new(0, GAP)

                if isMobile then
                    c.AnchorPoint = Vector2.new(1, 0)
                    c.Position = UDim2.new(1, -12, 0, 44)
                    layout.VerticalAlignment = Enum.VerticalAlignment.Top
                else
                    c.AnchorPoint = Vector2.new(1, 1)
                    c.Position = UDim2.new(1, -16, 1, -16)
                    layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
                end

                layout.Parent = c
                c.Parent = gui
                _gui = gui
                _container = c
                _layout = layout
            end
            local function stopClock()
                if #_active == 0 and _clockThread then
                    task.cancel(_clockThread)

                    _clockThread = nil
                end
            end
            local function startClock()
                if _clockThread then
                    return
                end

                _clockThread = task.spawn(function()
                    while#_active > 0 do
                        task.wait(1)

                        local t = now()

                        for _, toast in ipairs(_active)do
                            if not toast.dismissed and toast.timeLabel then
                                toast.timeLabel.Text = formatElapsed(t - toast.creationTime)
                            end
                        end
                    end

                    _clockThread = nil
                end)
            end
            local function dismissToast(toast: ActiveToast)
                if toast.dismissed then
                    return
                end

                toast.dismissed = true

                toast.cancelTimer()

                local idx = table.find(_active, toast)

                if idx then
                    table.remove(_active, idx)
                end

                stopClock()
                tween.fire(toast.card, TWEEN_OUT_FADE, {GroupTransparency = 1})

                if toast.stroke and toast.stroke.Parent then
                    tween.fire(toast.stroke, TWEEN_OUT_FADE, {Transparency = 1})
                end

                local sizeTween = tween.play(toast.wrapper, TWEEN_OUT_SIZE, {
                    Size = UDim2.new(1, 0, 0, 0),
                })

                sizeTween.Completed:Once(function()
                    sizeTween:Destroy()

                    if toast.wrapper.Parent then
                        toast.wrapper:Destroy()
                    end
                end)
            end
            local function applyThemeToToast(toast: ActiveToast, t: {[string]: any})
                if toast.dismissed then
                    return
                end

                local accent = typeColor(toast.notifType, t)

                toast.iconBadge.BackgroundColor3 = accent
                toast.badgeStroke.Color = accent
                toast.iconImg.ImageColor3 = accent
                toast.bottomGlow.BackgroundColor3 = accent
                toast.card.BackgroundColor3 = if t.WindowColor and typeof(t.WindowColor) == 'ColorSequence' and #t.WindowColor.Keypoints > 0 then t.WindowColor.Keypoints[1].Value else constants.COLORS.SURFACE
                toast.stroke.Color = t.SurfaceStroke or constants.COLORS.STROKE_SURFACE
                toast.titleLbl.TextColor3 = t.ContentColor or Color3.fromHex('#f5f5fa')
                toast.titleLbl.FontFace = t.TitleFont or FONT_SEMI

                if toast.msgLbl then
                    toast.msgLbl.TextColor3 = t.PlaceholderColor or Color3.fromHex('#b9b9c6')
                    toast.msgLbl.FontFace = t.Font or FONT_MED
                end

                toast.timeLabel.TextColor3 = t.PlaceholderColor or constants.COLORS.TEXT_FAINT
                toast.timeLabel.FontFace = t.Font or FONT_MED
                toast.closeBtn.TextColor3 = t.PlaceholderColor or constants.COLORS.TEXT_FAINT
            end

            themeUtil.subscribe(function(t)
                for _, toast in ipairs(_active)do
                    applyThemeToToast(toast, t)
                end
            end)

            local notification = {}

            function notification.send(props: NotifyProps, theme: {[string]: any}?)
                hapticEngine.notify()
                ensureGui()

                local resolvedTheme = theme or variables.activeTheme or {}

                while#_active >= MAX_VISIBLE do
                    local oldest = _active[1]

                    if oldest then
                        dismissToast(oldest)
                    else
                        break
                    end
                end

                local titleText = props.title or 'Notification'
                local msgText = props.content or ''
                local notifType = props.type or 'info'
                local accent = typeColor(notifType, resolvedTheme)
                local iconId = resolveIcon(props.icon, notifType)
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
                local s = _scale

                local function px(n: number): number
                    return math.max(math.round(n * s), 1)
                end

                local ts = math.max(math.round(s * 12), 8)
                local ms = math.max(math.round(s * 11), 8)
                local xs = math.max(math.round(s * 10), 7)
                local cs = math.max(math.round(s * 13), 8)
                local usableW = math.round(TOAST_W * s) - px(59)
                local textBounds = variables.textService:GetTextSize(msgText, ms, Enum.Font.GothamMedium, Vector2.new(math.max(usableW, 40), 2000))
                local headerH = px(16)
                local msgH = if#msgText > 0 then math.max(textBounds.Y, px(13))else 0
                local bodyH = if msgH > 0 then(headerH + px(3) + msgH)else headerH
                local contentH = math.max(bodyH, px(28))
                local targetH = px(20) + contentH
                local wrapper = Instance.new('Frame')

                wrapper.Name = 'ToastSlot'
                wrapper.Size = UDim2.new(1, 0, 0, 0)
                wrapper.BackgroundTransparency = 1
                wrapper.BorderSizePixel = 0
                wrapper.ClipsDescendants = false
                wrapper.LayoutOrder = order
                wrapper.Parent = _container

                local card = Instance.new('CanvasGroup')

                card.Name = 'ToastCard'
                card.Size = UDim2.new(1, 0, 0, targetH)
                card.Position = UDim2.fromOffset(0, 0)
                card.BackgroundColor3 = if resolvedTheme.WindowColor and typeof(resolvedTheme.WindowColor) == 'ColorSequence' and #resolvedTheme.WindowColor.Keypoints > 0 then resolvedTheme.WindowColor.Keypoints[1].Value else constants.COLORS.SURFACE
                card.BorderSizePixel = 0
                card.GroupTransparency = 1
                card.ClipsDescendants = true
                card.Parent = wrapper

                local corner = Instance.new('UICorner')

                corner.CornerRadius = UDim.new(0, px(8))
                corner.Parent = card

                local stroke = Instance.new('UIStroke')

                stroke.Color = resolvedTheme.SurfaceStroke or constants.COLORS.STROKE_SURFACE
                stroke.Thickness = 1
                stroke.Transparency = 1
                stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                stroke.Parent = card

                local bottomGlow = Instance.new('Frame')

                bottomGlow.Name = 'BottomGlow'
                bottomGlow.Position = UDim2.new(0, 0, 1, -1)
                bottomGlow.Size = UDim2.new(1, 0, 0, 1)
                bottomGlow.BackgroundColor3 = accent
                bottomGlow.BorderSizePixel = 0
                bottomGlow.ZIndex = 3
                bottomGlow.Parent = card

                local glowGrad = Instance.new('UIGradient')

                glowGrad.Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 1),
                    NumberSequenceKeypoint.new(0.35, 0.45),
                    NumberSequenceKeypoint.new(0.65, 0.45),
                    NumberSequenceKeypoint.new(1, 1),
                })
                glowGrad.Parent = bottomGlow

                local row = Instance.new('Frame')

                row.Name = 'Row'
                row.Position = UDim2.fromOffset(px(11), px(10))
                row.Size = UDim2.new(1, -px(22), 0, contentH)
                row.BackgroundTransparency = 1
                row.BorderSizePixel = 0
                row.ZIndex = 2
                row.Parent = card

                local rLayout = Instance.new('UIListLayout')

                rLayout.FillDirection = Enum.FillDirection.Horizontal
                rLayout.VerticalAlignment = Enum.VerticalAlignment.Top
                rLayout.SortOrder = Enum.SortOrder.LayoutOrder
                rLayout.Padding = UDim.new(0, px(9))
                rLayout.Parent = row

                local iconBadge = Instance.new('Frame')

                iconBadge.Name = 'IconBadge'
                iconBadge.LayoutOrder = 1
                iconBadge.Size = UDim2.fromOffset(px(28), px(28))
                iconBadge.BackgroundColor3 = accent
                iconBadge.BackgroundTransparency = 0.86
                iconBadge.BorderSizePixel = 0
                iconBadge.Parent = row

                local badgeCorner = Instance.new('UICorner')

                badgeCorner.CornerRadius = UDim.new(0, px(7))
                badgeCorner.Parent = iconBadge

                local badgeStroke = Instance.new('UIStroke')

                badgeStroke.Color = accent
                badgeStroke.Thickness = 1
                badgeStroke.Transparency = 0.65
                badgeStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                badgeStroke.Parent = iconBadge

                local iconImg = Instance.new('ImageLabel')

                iconImg.Name = 'Icon'
                iconImg.AnchorPoint = Vector2.new(0.5, 0.5)
                iconImg.Position = UDim2.fromScale(0.5, 0.5)
                iconImg.Size = UDim2.fromOffset(px(14), px(14))
                iconImg.BackgroundTransparency = 1
                iconImg.Image = iconId
                iconImg.ImageColor3 = accent
                iconImg.Parent = iconBadge

                local col = Instance.new('Frame')

                col.Name = 'Col'
                col.LayoutOrder = 2
                col.Size = UDim2.new(1, -px(37), 0, 0)
                col.AutomaticSize = Enum.AutomaticSize.Y
                col.BackgroundTransparency = 1
                col.BorderSizePixel = 0
                col.Parent = row

                local colLayout = Instance.new('UIListLayout')

                colLayout.FillDirection = Enum.FillDirection.Vertical
                colLayout.SortOrder = Enum.SortOrder.LayoutOrder
                colLayout.Padding = UDim.new(0, px(3))
                colLayout.Parent = col

                local header = Instance.new('Frame')

                header.Name = 'Header'
                header.LayoutOrder = 1
                header.Size = UDim2.new(1, 0, 0, headerH)
                header.BackgroundTransparency = 1
                header.BorderSizePixel = 0
                header.Parent = col

                local hLayout = Instance.new('UIListLayout')

                hLayout.FillDirection = Enum.FillDirection.Horizontal
                hLayout.VerticalAlignment = Enum.VerticalAlignment.Center
                hLayout.SortOrder = Enum.SortOrder.LayoutOrder
                hLayout.Padding = UDim.new(0, px(4))
                hLayout.Parent = header

                local titleLbl = Instance.new('TextLabel')

                titleLbl.Name = 'Title'
                titleLbl.LayoutOrder = 1
                titleLbl.AutomaticSize = Enum.AutomaticSize.X
                titleLbl.Size = UDim2.new(0, 0, 1, 0)
                titleLbl.BackgroundTransparency = 1
                titleLbl.FontFace = resolvedTheme.TitleFont or FONT_SEMI
                titleLbl.Text = titleText
                titleLbl.TextSize = ts
                titleLbl.TextColor3 = resolvedTheme.ContentColor or Color3.fromHex('#f5f5fa')
                titleLbl.TextXAlignment = Enum.TextXAlignment.Left
                titleLbl.TextTruncate = Enum.TextTruncate.AtEnd
                titleLbl.Parent = header

                local spacer = Instance.new('Frame')

                spacer.Name = 'Spacer'
                spacer.LayoutOrder = 2
                spacer.Size = UDim2.new(0, 0, 1, 0)
                spacer.BackgroundTransparency = 1
                spacer.BorderSizePixel = 0
                spacer.Parent = header

                local flex = Instance.new('UIFlexItem')

                flex.FlexMode = Enum.UIFlexMode.Fill
                flex.Parent = spacer

                local timeLbl = Instance.new('TextLabel')

                timeLbl.Name = 'Time'
                timeLbl.LayoutOrder = 3
                timeLbl.AutomaticSize = Enum.AutomaticSize.X
                timeLbl.Size = UDim2.new(0, 0, 1, 0)
                timeLbl.BackgroundTransparency = 1
                timeLbl.FontFace = resolvedTheme.Font or FONT_MED
                timeLbl.Text = 'now'
                timeLbl.TextSize = xs
                timeLbl.TextColor3 = resolvedTheme.PlaceholderColor or constants.COLORS.TEXT_FAINT
                timeLbl.TextXAlignment = Enum.TextXAlignment.Right
                timeLbl.Parent = header

                local closeBtnPx = if _scale < 1 then math.max(px(14), 24)else px(14)
                local closeBtn = Instance.new('TextButton')

                closeBtn.Name = 'CloseBtn'
                closeBtn.LayoutOrder = 4
                closeBtn.Size = UDim2.fromOffset(closeBtnPx, closeBtnPx)
                closeBtn.BackgroundTransparency = 1
                closeBtn.BorderSizePixel = 0
                closeBtn.Font = Enum.Font.GothamMedium
                closeBtn.Text = '\u{d7}'
                closeBtn.TextSize = cs
                closeBtn.TextColor3 = resolvedTheme.PlaceholderColor or constants.COLORS.TEXT_FAINT
                closeBtn.AutoButtonColor = false
                closeBtn.Parent = header

                local closeCrn = Instance.new('UICorner')

                closeCrn.CornerRadius = UDim.new(0, px(3))
                closeCrn.Parent = closeBtn

                local msgLbl: TextLabel? = nil

                if #msgText > 0 then
                    msgLbl = Instance.new('TextLabel')
                    msgLbl.Name = 'Message'
                    msgLbl.LayoutOrder = 2
                    msgLbl.AutomaticSize = Enum.AutomaticSize.Y
                    msgLbl.Size = UDim2.new(1, 0, 0, 0)
                    msgLbl.BackgroundTransparency = 1
                    msgLbl.FontFace = resolvedTheme.Font or FONT_MED
                    msgLbl.Text = msgText
                    msgLbl.TextSize = ms
                    msgLbl.TextColor3 = resolvedTheme.PlaceholderColor or Color3.fromHex('#b9b9c6')
                    msgLbl.TextXAlignment = Enum.TextXAlignment.Left
                    msgLbl.TextWrapped = true
                    msgLbl.RichText = true
                    msgLbl.LineHeight = 1.15
                    msgLbl.Parent = col
                end

                local creationTime = now()
                local timerThread: thread? = nil
                local toast: ActiveToast = {
                    wrapper = wrapper,
                    card = card,
                    stroke = stroke,
                    dismissed = false,
                    cancelTimer = function() end,
                    timeLabel = timeLbl,
                    creationTime = creationTime,
                    notifType = notifType,
                    bottomGlow = bottomGlow,
                    iconBadge = iconBadge,
                    badgeStroke = badgeStroke,
                    iconImg = iconImg,
                    titleLbl = titleLbl,
                    msgLbl = msgLbl,
                    closeBtn = closeBtn,
                }

                local function cancelTimer()
                    toast.dismissed = true

                    if timerThread then
                        pcall(task.cancel, timerThread)

                        timerThread = nil
                    end
                end

                toast.cancelTimer = cancelTimer

                table.insert(_active, toast)
                tween.fire(wrapper, TWEEN_IN_SIZE, {
                    Size = UDim2.new(1, 0, 0, targetH),
                })
                task.delay(0.12, function()
                    if toast.dismissed then
                        return
                    end

                    tween.fire(card, TWEEN_IN_FADE, {GroupTransparency = 0})
                    tween.fire(stroke, TWEEN_IN_FADE, {Transparency = 0})
                end)

                if duration > 0 then
                    timerThread = task.delay(duration, function()
                        dismissToast(toast)
                    end)
                end

                startClock()
                closeBtn.Activated:Connect(function()
                    dismissToast(toast)
                end)

                if not variables.isTouchOnly then
                    closeBtn.MouseEnter:Connect(function()
                        tween.fire(closeBtn, constants.tweenFocus, {
                            BackgroundTransparency = 0.82,
                            BackgroundColor3 = Color3.fromHex('#2e2e38'),
                            TextColor3 = resolvedTheme.ContentColor or Color3.fromHex('#ffffff'),
                        })
                    end)
                    closeBtn.MouseLeave:Connect(function()
                        tween.fire(closeBtn, constants.tweenFocus, {
                            BackgroundTransparency = 1,
                            TextColor3 = Color3.fromHex('#737380'),
                        })
                    end)
                end
            end
            function notification.dismissAll()
                for i = #_active, 1, -1 do
                    local t = _active[i]

                    if t then
                        dismissToast(t)
                    end
                end
            end

            return notification
        end)()
    end,
    [57] = function()
        local wax, script, require = ImportGlobals(57)
        local ImportGlobals

        return (function(...)
            type OrderedElement = {main: GuiObject?, descriptor: {main: GuiObject?, _frame: GuiObject?}?, _frame: GuiObject?}

            local function assignOrder(element: OrderedElement, order: number)
                local target = element.main or element._frame

                if target then
                    target.LayoutOrder = order
                end

                local desc = element.descriptor

                if desc then
                    local descFrame = desc.main or desc._frame

                    if descFrame then
                        descFrame.LayoutOrder = order + 1
                    end
                end
            end

            return assignOrder
        end)()
    end,
    [40] = function()
        local wax, script, require = ImportGlobals(40)
        local ImportGlobals

        return (function(...)
            local executor = {}

            local function probeSetter()
                if typeof(setthreadidentity) == 'function' then
                    return setthreadidentity
                end
                if typeof(set_thread_identity) == 'function' then
                    return set_thread_identity
                end

                return nil
            end

            local _cachedSetter = nil

            function executor.escalate(level: number?): boolean
                if not _cachedSetter then
                    _cachedSetter = probeSetter()
                end
                if not _cachedSetter then
                    return false
                end

                return pcall(_cachedSetter, level or 8)
            end

            return executor
        end)()
    end,
    [31] = function()
        local wax, script, require = ImportGlobals(31)
        local ImportGlobals

        return (function(...)
            return {
                WindowColor = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(245, 243, 255)),
                    ColorSequenceKeypoint.new(0.9999, Color3.fromRGB(235, 232, 250)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(225, 220, 245)),
                }),
                ShadowColor = Color3.fromRGB(180, 170, 210),
                SurfaceStroke = Color3.fromRGB(190, 180, 220),
                TitleBarColor = Color3.fromRGB(210, 205, 240),
                TabColor = Color3.fromRGB(30, 20, 60),
                TabBackground = ColorSequence.new(Color3.fromRGB(210, 205, 240), Color3.fromRGB(225, 220, 248)),
                TabStroke = ColorSequence.new(Color3.fromRGB(180, 170, 220), Color3.fromRGB(195, 185, 230)),
                ElementGradient = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(232, 228, 252)),
                    ColorSequenceKeypoint.new(0.9999, Color3.fromRGB(238, 235, 255)),
                    ColorSequenceKeypoint.new(1, Color3.fromRGB(238, 235, 255)),
                }),
                ElementStroke = Color3.fromRGB(200, 190, 235),
                ElementStrokeGradient = ColorSequence.new(Color3.fromRGB(190, 180, 225), Color3.fromRGB(200, 190, 235)),
                ElementStrokeHover = Color3.fromRGB(124, 58, 237),
                ElementTextHoverColor = Color3.fromRGB(30, 20, 60),
                ContentColor = Color3.fromRGB(40, 30, 70),
                TitlingColor = Color3.fromRGB(20, 10, 50),
                PlaceholderColor = Color3.fromRGB(150, 140, 180),
                AccentColor = Color3.fromRGB(124, 58, 237),
                AccentStroke = Color3.fromRGB(167, 139, 250),
                AccentGlow = 0.35,
                ToggleTrack = Color3.fromRGB(180, 170, 215),
                ToggleTrackTransparency = 0.5,
                ToggleKnobOff = Color3.fromRGB(120, 110, 165),
                ToggleKnobOffTransparency = 0,
                DarkToggleOverlay = false,
                SliderBackground = Color3.fromRGB(215, 210, 245),
                SliderBackgroundHover = Color3.fromRGB(200, 195, 235),
                SliderProgress = ColorSequence.new(Color3.fromRGB(124, 58, 237), Color3.fromRGB(99, 30, 220)),
                SliderHandle = Color3.fromRGB(124, 58, 237),
                SliderStroke = Color3.fromRGB(124, 58, 237),
                DropdownHighlight = Color3.fromRGB(40, 30, 70),
                FieldBackground = Color3.fromRGB(255, 255, 255),
                FieldTransparency = 0.6,
                FieldGlow = Color3.fromRGB(124, 58, 237),
                NeutralButton = Color3.fromRGB(220, 215, 245),
                NeutralButtonHover = Color3.fromRGB(205, 198, 235),
                NeutralButtonStroke = Color3.fromRGB(160, 150, 200),
                ActionColor = Color3.fromRGB(30, 20, 60),
            }
        end)()
    end,
    [17] = function()
        local wax, script, require = ImportGlobals(17)
        local ImportGlobals

        return (function(...)
            local constants = require(script.Parent.Parent.utility.constants)
            local element = require(script.Parent.Parent.utility.element)
            local icons = require(script.Parent.Parent.utility.icons)
            local tween = require(script.Parent.Parent.utility.tween)
            local variables = require(script.Parent.Parent.utility.variables)
            local FONT_SEMI = constants.DEFAULT_FONT_SEMI
            local FONT_MED = constants.DEFAULT_FONT_MEDIUM
            local FONT_REG = constants.DEFAULT_FONT
            local DEFAULT_W = 380
            local PAD = 18
            local ICON_SIZE = 34
            local TITLE_H = 20
            local BTN_H = 30
            local BTN_PAD_X = 14
            local BTN_GAP = 6

            export type PopupButton = {text: string, variant: string?, callback: (() -> ())?, closeOnClick: boolean?}
            export type PopupProps = {title: string?, description: string?, icon: (string | number)?, iconVariant: string?, buttons: {PopupButton}?, dismissible: boolean?, autoOpen: boolean?, width: number?, onClose: (() -> ())?}
            export type Popup = {_card: Frame?, _overlay: TextButton?, Open: (self:Popup) -> (), Close: (self:Popup) -> (), IsOpen: (self:Popup) -> boolean, Destroy: (self:Popup) -> ()}

            local function variantColor(variant: string?, t: {[string]: any}): Color3
                if variant == 'success' then
                    return constants.COLORS.SUCCESS
                elseif variant == 'warning' then
                    return constants.COLORS.WARNING
                elseif variant == 'error' then
                    return t.ErrorColor or constants.COLORS.ERROR
                else
                    return t.AccentColor or constants.COLORS.ACCENT
                end
            end
            local function flatWindowColor(t: {[string]: any}): Color3
                if typeof(t.WindowColor) == 'ColorSequence' and #t.WindowColor.Keypoints > 0 then
                    return t.WindowColor.Keypoints[1].Value
                end

                return constants.COLORS.SURFACE
            end

            local Popup = {}::{__index: any}

            Popup.__index = Popup

            function Popup.new(
                props: PopupProps,
                theme: {[string]: any},
                parent: Instance
            ): Popup
                local title = props.title
                local description = props.description
                local iconProp = props.icon
                local iconVariant = props.iconVariant or 'info'
                local buttons = props.buttons or {
                    {
                        text = 'OK',
                        variant = 'primary',
                    },
                }
                local dismissible = props.dismissible ~= false
                local autoOpen = props.autoOpen == true
                local cardWidth = props.width or DEFAULT_W
                local onClose = props.onClose
                local hasTitle = title ~= nil and title ~= ''
                local hasDesc = description ~= nil and description ~= ''
                local hasIcon = iconProp ~= nil and iconProp ~= ''
                local iconAsset: string? = nil

                if hasIcon then
                    iconAsset = icons.Resolve(iconProp)

                    if not iconAsset then
                        hasIcon = false
                    end
                end

                local self: any = setmetatable({}, Popup)
                local isOpen = false
                local destroyed = false
                local overlay = Instance.new('TextButton')

                overlay.Name = 'PopupOverlay'
                overlay.Size = UDim2.fromScale(1, 1)
                overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                overlay.BackgroundTransparency = 0.55
                overlay.BorderSizePixel = 0
                overlay.Text = ''
                overlay.AutoButtonColor = false
                overlay.ZIndex = constants.zIndex.popup - 1
                overlay.Active = true
                overlay.Visible = false
                overlay.Parent = parent

                local card = Instance.new('Frame')

                card.Name = 'PopupCard'
                card.AnchorPoint = Vector2.new(0.5, 0.5)
                card.Position = UDim2.fromScale(0.5, 0.5)
                card.Size = UDim2.fromOffset(cardWidth, 0)
                card.AutomaticSize = Enum.AutomaticSize.Y
                card.BackgroundColor3 = flatWindowColor(theme)
                card.BorderSizePixel = 0
                card.ZIndex = constants.zIndex.popup
                card.Visible = false
                card.Parent = parent

                element.mkCorner(card, 12)

                local cardGrad: UIGradient? = nil

                do
                    local g = Instance.new('UIGradient')

                    g.Color = if typeof(theme.WindowColor) == 'ColorSequence'then theme.WindowColor else ColorSequence.new({
                        ColorSequenceKeypoint.new(0, constants.COLORS.SURFACE_ALT),
                        ColorSequenceKeypoint.new(1, constants.COLORS.SURFACE),
                    })
                    g.Rotation = 90
                    g.Parent = card
                    cardGrad = g
                end

                local cardStroke = element.mkStroke(card, theme.SurfaceStroke or constants.COLORS.STROKE_SURFACE, 1)
                local cardPad = Instance.new('UIPadding')

                cardPad.PaddingTop = UDim.new(0, PAD)
                cardPad.PaddingBottom = UDim.new(0, PAD)
                cardPad.PaddingLeft = UDim.new(0, PAD)
                cardPad.PaddingRight = UDim.new(0, PAD)
                cardPad.Parent = card

                local root = Instance.new('Frame')

                root.Name = 'Root'
                root.Size = UDim2.new(1, 0, 0, 0)
                root.AutomaticSize = Enum.AutomaticSize.Y
                root.BackgroundTransparency = 1
                root.BorderSizePixel = 0
                root.ZIndex = constants.zIndex.popup + 2
                root.Parent = card

                local rootLayout = Instance.new('UIListLayout')

                rootLayout.FillDirection = Enum.FillDirection.Vertical
                rootLayout.VerticalAlignment = Enum.VerticalAlignment.Top
                rootLayout.SortOrder = Enum.SortOrder.LayoutOrder
                rootLayout.Padding = UDim.new(0, 10)
                rootLayout.Parent = root

                local iconBadge: Frame? = nil
                local iconImg: ImageLabel? = nil
                local badgeStroke: UIStroke? = nil

                if hasIcon then
                    local headerRow = Instance.new('Frame')

                    headerRow.Name = 'Header'
                    headerRow.Size = UDim2.new(1, 0, 0, ICON_SIZE)
                    headerRow.BackgroundTransparency = 1
                    headerRow.BorderSizePixel = 0
                    headerRow.LayoutOrder = 1
                    headerRow.ZIndex = constants.zIndex.popup + 3
                    headerRow.Parent = root

                    local hLayout = Instance.new('UIListLayout')

                    hLayout.FillDirection = Enum.FillDirection.Horizontal
                    hLayout.VerticalAlignment = Enum.VerticalAlignment.Center
                    hLayout.SortOrder = Enum.SortOrder.LayoutOrder
                    hLayout.Padding = UDim.new(0, 10)
                    hLayout.Parent = headerRow

                    local badge = Instance.new('Frame')

                    badge.Name = 'IconBadge'
                    badge.Size = UDim2.fromOffset(ICON_SIZE, ICON_SIZE)
                    badge.BackgroundColor3 = variantColor(iconVariant, theme)
                    badge.BackgroundTransparency = 0.85
                    badge.BorderSizePixel = 0
                    badge.LayoutOrder = 1
                    badge.ZIndex = constants.zIndex.popup + 4
                    badge.Parent = headerRow

                    element.mkCorner(badge, 8)

                    badgeStroke = element.mkStroke(badge, variantColor(iconVariant, theme), 1)
                    badgeStroke.Transparency = 0.6

                    local img = Instance.new('ImageLabel')

                    img.Name = 'Icon'
                    img.AnchorPoint = Vector2.new(0.5, 0.5)
                    img.Position = UDim2.fromScale(0.5, 0.5)
                    img.Size = UDim2.fromOffset(18, 18)
                    img.BackgroundTransparency = 1
                    img.Image = iconAsset
                    img.ImageColor3 = variantColor(iconVariant, theme)
                    img.ZIndex = constants.zIndex.popup + 5
                    img.Parent = badge
                    iconBadge = badge
                    iconImg = img
                end

                local titleLbl: TextLabel? = nil
                local descLbl: TextLabel? = nil

                if hasTitle or hasDesc then
                    local textStack = Instance.new('Frame')

                    textStack.Name = 'TextStack'
                    textStack.Size = UDim2.new(1, 0, 0, 0)
                    textStack.AutomaticSize = Enum.AutomaticSize.Y
                    textStack.BackgroundTransparency = 1
                    textStack.BorderSizePixel = 0
                    textStack.LayoutOrder = if hasIcon then 2 else 1
                    textStack.ZIndex = constants.zIndex.popup + 3
                    textStack.Parent = root

                    local tsLayout = Instance.new('UIListLayout')

                    tsLayout.FillDirection = Enum.FillDirection.Vertical
                    tsLayout.VerticalAlignment = Enum.VerticalAlignment.Top
                    tsLayout.SortOrder = Enum.SortOrder.LayoutOrder
                    tsLayout.Padding = UDim.new(0, 4)
                    tsLayout.Parent = textStack

                    if hasTitle then
                        titleLbl = Instance.new('TextLabel')
                        titleLbl.Name = 'Title'
                        titleLbl.Size = UDim2.new(1, 0, 0, TITLE_H)
                        titleLbl.BackgroundTransparency = 1
                        titleLbl.Text = title
                        titleLbl.TextColor3 = theme.TitlingColor or theme.ContentColor or constants.COLORS.TEXT
                        titleLbl.TextSize = 14
                        titleLbl.FontFace = theme.TitleFont or FONT_SEMI
                        titleLbl.TextXAlignment = Enum.TextXAlignment.Left
                        titleLbl.TextYAlignment = Enum.TextYAlignment.Center
                        titleLbl.TextTruncate = Enum.TextTruncate.AtEnd
                        titleLbl.LayoutOrder = 1
                        titleLbl.ZIndex = constants.zIndex.popup + 4
                        titleLbl.Parent = textStack
                    end
                    if hasDesc then
                        descLbl = Instance.new('TextLabel')
                        descLbl.Name = 'Description'
                        descLbl.Size = UDim2.new(1, 0, 0, 0)
                        descLbl.AutomaticSize = Enum.AutomaticSize.Y
                        descLbl.BackgroundTransparency = 1
                        descLbl.Text = description
                        descLbl.TextColor3 = theme.PlaceholderColor or constants.COLORS.TEXT_SUBTLE
                        descLbl.TextSize = 12
                        descLbl.FontFace = theme.Font or FONT_REG
                        descLbl.TextXAlignment = Enum.TextXAlignment.Left
                        descLbl.TextYAlignment = Enum.TextYAlignment.Top
                        descLbl.TextWrapped = true
                        descLbl.LineHeight = 1.2
                        descLbl.LayoutOrder = 2
                        descLbl.ZIndex = constants.zIndex.popup + 4
                        descLbl.Parent = textStack
                    end
                end

                local footer = Instance.new('Frame')

                footer.Name = 'Footer'
                footer.Size = UDim2.new(1, 0, 0, BTN_H)
                footer.BackgroundTransparency = 1
                footer.BorderSizePixel = 0
                footer.LayoutOrder = 3
                footer.ZIndex = constants.zIndex.popup + 3
                footer.Parent = root

                local footerLayout = Instance.new('UIListLayout')

                footerLayout.FillDirection = Enum.FillDirection.Horizontal
                footerLayout.VerticalAlignment = Enum.VerticalAlignment.Center
                footerLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
                footerLayout.SortOrder = Enum.SortOrder.LayoutOrder
                footerLayout.Padding = UDim.new(0, BTN_GAP)
                footerLayout.Parent = footer

                type BtnRef = {btn: TextButton, variant: string, label: TextLabel}

                local buttonRefs: {BtnRef} = {}

                for i, cfg in ipairs(buttons)do
                    local variant = cfg.variant or 'secondary'
                    local btn = Instance.new('TextButton')

                    btn.Name = 'Btn_' .. (cfg.text or ('Action' .. i))
                    btn.Size = UDim2.new(0, 0, 1, 0)
                    btn.AutomaticSize = Enum.AutomaticSize.X
                    btn.BackgroundColor3 = constants.COLORS.SURFACE_HOVER
                    btn.BackgroundTransparency = 0.4
                    btn.BorderSizePixel = 0
                    btn.Text = ''
                    btn.AutoButtonColor = false
                    btn.LayoutOrder = i
                    btn.ZIndex = constants.zIndex.popup + 4
                    btn.Parent = footer

                    element.mkCorner(btn, 6)

                    local pad = Instance.new('UIPadding')

                    pad.PaddingLeft = UDim.new(0, BTN_PAD_X)
                    pad.PaddingRight = UDim.new(0, BTN_PAD_X)
                    pad.Parent = btn

                    local lbl = Instance.new('TextLabel')

                    lbl.Name = 'Label'
                    lbl.Size = UDim2.fromScale(1, 1)
                    lbl.BackgroundTransparency = 1
                    lbl.Text = cfg.text or ('Action ' .. i)
                    lbl.TextSize = 12
                    lbl.FontFace = theme.Font or FONT_MED
                    lbl.TextXAlignment = Enum.TextXAlignment.Center
                    lbl.TextYAlignment = Enum.TextYAlignment.Center
                    lbl.ZIndex = constants.zIndex.popup + 5
                    lbl.Parent = btn

                    local myRef: BtnRef = {
                        btn = btn,
                        variant = variant,
                        label = lbl,
                    }

                    table.insert(buttonRefs, myRef)
                    btn.Activated:Connect(function()
                        if destroyed then
                            return
                        end

                        local cb = cfg.callback
                        local closeOnClick = cfg.closeOnClick ~= false

                        if cb then
                            task.spawn(cb)
                        end
                        if closeOnClick then
                            self:Close()
                        end
                    end)

                    if not variables.isTouchOnly then
                        btn.MouseEnter:Connect(function()
                            if destroyed then
                                return
                            end

                            tween.fire(btn, constants.tweenFast, {BackgroundTransparency = 0.25})
                        end)
                        btn.MouseLeave:Connect(function()
                            if destroyed then
                                return
                            end

                            tween.fire(btn, constants.tweenFast, {
                                BackgroundTransparency = if variant == 'ghost'then 1 else 0.4,
                            })
                        end)
                    end
                end

                local function applyTheme(t: {[string]: any})
                    card.BackgroundColor3 = flatWindowColor(t)

                    if cardGrad and typeof(t.WindowColor) == 'ColorSequence' then
                        cardGrad.Color = t.WindowColor
                    end

                    cardStroke.Color = t.SurfaceStroke or constants.COLORS.STROKE_SURFACE

                    if iconBadge and iconImg and badgeStroke then
                        local col = variantColor(iconVariant, t)

                        iconBadge.BackgroundColor3 = col
                        iconImg.ImageColor3 = col
                        badgeStroke.Color = col
                    end
                    if titleLbl then
                        titleLbl.TextColor3 = t.TitlingColor or t.ContentColor or constants.COLORS.TEXT
                        titleLbl.FontFace = t.TitleFont or FONT_SEMI
                    end
                    if descLbl then
                        descLbl.TextColor3 = t.PlaceholderColor or constants.COLORS.TEXT_SUBTLE
                        descLbl.FontFace = t.Font or FONT_REG
                    end

                    for _, ref in buttonRefs do
                        local v = ref.variant
                        local bg: Color3
                        local fg: Color3
                        local bgTrans: number

                        if v == 'primary' then
                            bg = t.AccentColor or constants.COLORS.ACCENT
                            fg = t.AccentColor or constants.COLORS.ACCENT
                            bgTrans = 0.82
                        elseif v == 'danger' then
                            bg = t.ErrorColor or constants.COLORS.ERROR
                            fg = t.ErrorColor or constants.COLORS.ERROR
                            bgTrans = 0.82
                        elseif v == 'ghost' then
                            bg = t.NeutralButton or constants.COLORS.SURFACE_HOVER
                            fg = t.PlaceholderColor or constants.COLORS.TEXT_SUBTLE
                            bgTrans = 1
                        else
                            bg = t.NeutralButton or constants.COLORS.SURFACE_HOVER
                            fg = t.ContentColor or constants.COLORS.TEXT
                            bgTrans = 0.4
                        end

                        ref.btn.BackgroundColor3 = bg
                        ref.btn.BackgroundTransparency = bgTrans
                        ref.label.TextColor3 = fg
                        ref.label.FontFace = t.Font or FONT_MED
                    end
                end

                local unsub = element.subscribeTheme(card, {
                    stroke = cardStroke,
                    gradient = cardGrad,
                    title = titleLbl,
                    titleFont = theme.TitleFont or FONT_SEMI,
                    extra = applyTheme,
                })

                self._card = card
                self._overlay = overlay

                function self.Open()
                    if destroyed or isOpen then
                        return
                    end

                    isOpen = true
                    overlay.Visible = true
                    card.Visible = true
                end
                function self.Close()
                    if destroyed or not isOpen then
                        return
                    end

                    isOpen = false
                    overlay.Visible = false
                    card.Visible = false

                    if onClose then
                        task.spawn(onClose)
                    end
                end
                function self.IsOpen(): boolean
                    return isOpen
                end
                function self.Destroy()
                    if destroyed then
                        return
                    end

                    destroyed = true

                    if unsub then
                        unsub()
                    end

                    overlay.Visible = false
                    card.Visible = false

                    overlay:Destroy()
                    card:Destroy()
                end

                if dismissible then
                    overlay.Activated:Connect(function()
                        if destroyed or not isOpen then
                            return
                        end

                        self:Close()
                    end)
                end
                if autoOpen then
                    self:Open()
                end

                return self::Popup
            end

            return Popup
        end)()
    end,
    [38] = function()
        local wax, script, require = ImportGlobals(38)
        local ImportGlobals

        return (function(...)
            local constants = require(script.Parent.constants)
            local runtime = require(script.Parent.runtime)
            local tween = require(script.Parent.tween)
            local themeUtil = require(script.Parent.theme)
            local variables = require(script.Parent.variables)

            type ThemeTable = {[string]: any}
            type ThemeExtraFn = (t:ThemeTable) -> ()
            type SubscribeTargets = {frame: GuiObject?, stroke: UIStroke?, gradient: UIGradient?, title: (TextLabel | TextButton)?, titleFont: Font?, extra: ThemeExtraFn?}

            local element = {}

            function element.makeFrame(
                name: string,
                theme: {[string]: any},
                parent: Instance,
                height: number?
            ): (Frame,UIStroke,UIGradient)
                local h = height or constants.elementHeight
                local frame = Instance.new('Frame')

                frame.Name = name
                frame.Size = UDim2.new(1, 0, 0, h)
                frame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                frame.BackgroundTransparency = theme.ElementTransparency or 0
                frame.BorderSizePixel = 0
                frame.LayoutOrder = 0
                frame.Parent = parent

                local corner = Instance.new('UICorner')

                corner.CornerRadius = theme.ElementCornerRadius or UDim.new(0, 10)
                corner.Parent = frame

                local gradient = Instance.new('UIGradient')

                gradient.Color = theme.ElementGradient or ColorSequence.new(Color3.fromRGB(28, 24, 44))
                gradient.Rotation = 90
                gradient.Parent = frame

                local stroke = Instance.new('UIStroke')

                stroke.Color = theme.ElementStroke or Color3.fromRGB(50, 42, 80)
                stroke.Thickness = 1
                stroke.Transparency = theme.ElementStrokeTransparency or 0
                stroke.Parent = frame

                return frame, stroke, gradient
            end
            function element.makeOverlay(
                parent: Instance,
                zIndex: number,
                transparency: number?
            ): Frame
                local overlay = Instance.new('Frame')

                overlay.Name = 'Overlay'
                overlay.Size = UDim2.fromScale(1, 1)
                overlay.Position = UDim2.fromScale(0, 0)
                overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                overlay.BackgroundTransparency = transparency or 0.55
                overlay.BorderSizePixel = 0
                overlay.ZIndex = zIndex
                overlay.Visible = false
                overlay.Parent = parent

                return overlay
            end
            function element.isInside(pos: Vector2 | Vector3, guiObj: GuiObject): boolean
                local ap = guiObj.AbsolutePosition
                local as = guiObj.AbsoluteSize

                return pos.X >= ap.X and pos.X <= (ap.X + as.X) and pos.Y >= ap.Y and pos.Y <= (ap.Y + as.Y)
            end
            function element.onOutsideClick(
                targets: {GuiObject},
                callback: () -> ()
            ): () -> ()
                local conn: RBXScriptConnection? = nil

                conn = runtime.userInputService.InputBegan:Connect(function(
                    input: InputObject
                )
                    if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
                        return
                    end

                    local pos = input.Position

                    for _, target in ipairs(targets)do
                        if target.Visible and element.isInside(pos, target) then
                            return
                        end
                    end

                    callback()
                end)

                return function()
                    if conn then
                        conn:Disconnect()

                        conn = nil
                    end
                end
            end
            function element.createTitle(
                parent: Instance,
                name: string,
                desc: string?,
                theme: {[string]: any},
                rightOffset: number?
            ): (TextLabel,TextLabel?)
                local offset = rightOffset or 12
                local inner = Instance.new('Frame')

                inner.Name = 'Inner'
                inner.Size = UDim2.new(1, -offset, 1, 0)
                inner.BackgroundTransparency = 1
                inner.Parent = parent

                local padding = Instance.new('UIPadding')

                padding.PaddingLeft = UDim.new(0, 12)
                padding.PaddingRight = UDim.new(0, 4)
                padding.Parent = inner

                local hasDesc = desc ~= nil and desc ~= ''
                local titleLabel = Instance.new('TextLabel')

                titleLabel.Name = 'Title'
                titleLabel.Size = if hasDesc then UDim2.new(1, 0, 0, 18)else UDim2.fromScale(1, 1)
                titleLabel.BackgroundTransparency = 1
                titleLabel.Text = name
                titleLabel.TextColor3 = theme.ContentColor or Color3.fromRGB(220, 215, 240)
                titleLabel.TextSize = 13
                titleLabel.FontFace = theme.Font or constants.DEFAULT_FONT
                titleLabel.TextXAlignment = Enum.TextXAlignment.Left
                titleLabel.TextYAlignment = Enum.TextYAlignment.Center
                titleLabel.TextTruncate = Enum.TextTruncate.AtEnd
                titleLabel.Parent = inner

                local descLabel: TextLabel? = nil

                if hasDesc then
                    local layout = Instance.new('UIListLayout')

                    layout.FillDirection = Enum.FillDirection.Vertical
                    layout.VerticalAlignment = Enum.VerticalAlignment.Center
                    layout.Padding = UDim.new(0, 1)
                    layout.Parent = inner
                    descLabel = Instance.new('TextLabel')
                    descLabel.Name = 'Description'
                    descLabel.Size = UDim2.new(1, 0, 0, 14)
                    descLabel.BackgroundTransparency = 1
                    descLabel.Text = desc::string
                    descLabel.TextColor3 = theme.PlaceholderColor or Color3.fromRGB(140, 130, 175)
                    descLabel.TextSize = 11
                    descLabel.FontFace = theme.Font or constants.DEFAULT_FONT
                    descLabel.TextXAlignment = Enum.TextXAlignment.Left
                    descLabel.TextTruncate = Enum.TextTruncate.AtEnd
                    descLabel.Parent = inner
                end

                return titleLabel, descLabel
            end
            function element.wireHover(
                frame: Frame,
                stroke: UIStroke,
                themeRef: () -> {[string]: any},
                onClick: (() -> ())?
            ): TextButton
                local btn = Instance.new('TextButton')

                btn.Name = 'Interact'
                btn.Size = UDim2.fromScale(1, 1)
                btn.BackgroundTransparency = 1
                btn.Text = ''
                btn.AutoButtonColor = false
                btn.Parent = frame

                if onClick then
                    btn.Activated:Connect(function()
                        if variables.settingsOpen then
                            local sp = variables.settingsPanelInstance

                            if not sp or not frame:IsDescendantOf(sp) then
                                return
                            end
                        end

                        onClick()
                    end)
                end

                return btn
            end
            function element.mkCorner(inst: Instance, radius: number): UICorner
                local c = Instance.new('UICorner')

                c.CornerRadius = UDim.new(0, radius)
                c.Parent = inst

                return c
            end
            function element.mkStroke(
                inst: Instance,
                color: Color3,
                thickness: number?
            ): UIStroke
                local s = Instance.new('UIStroke')

                s.Color = color
                s.Thickness = thickness or 1
                s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                s.Parent = inst

                return s
            end
            function element.subscribeTheme(
                boundFrame: Instance,
                targets: SubscribeTargets
            ): () -> ()
                return themeUtil.subscribe(function(t)
                    local f = targets.frame

                    if f then
                        f.BackgroundTransparency = t.ElementTransparency or 0
                    end

                    local st = targets.stroke

                    if st then
                        st.Color = t.ElementStroke or constants.COLORS.STROKE
                        st.Transparency = t.ElementStrokeTransparency or 0
                    end

                    local g = targets.gradient

                    if g then
                        g.Color = t.ElementGradient or constants.DEFAULT_ELEMENT_GRADIENT
                    end

                    local tl = targets.title

                    if tl then
                        tl.TextColor3 = t.ContentColor or constants.COLORS.TEXT
                        tl.FontFace = t.Font or targets.titleFont or constants.DEFAULT_FONT
                    end
                    if targets.extra then
                        targets.extra(t)
                    end
                end, boundFrame)
            end

            return element
        end)()
    end,
    [39] = function()
        local wax, script, require = ImportGlobals(39)
        local ImportGlobals

        return (function(...)
            local enums = {}

            function enums.itemFromValue(enumType: any, value: number): EnumItem?
                local ok, item = pcall(function()
                    return enumType:FromValue(value)
                end)

                if ok and item then
                    return item
                end

                local scanOk, items = pcall(function()
                    return enumType:GetEnumItems()
                end)

                if not scanOk then
                    return nil
                end

                for _, enumItem in items do
                    if enumItem.Value == value then
                        return enumItem
                    end
                end

                return nil
            end

            return enums
        end)()
    end,
    [3] = function()
        local wax, script, require = ImportGlobals(3)
        local ImportGlobals

        return (function(...)
            local constants = require(script.Parent.Parent.utility.constants)
            local tween = require(script.Parent.Parent.utility.tween)
            local element = require(script.Parent.Parent.utility.element)
            local themeUtil = require(script.Parent.Parent.utility.theme)
            local variables = require(script.Parent.Parent.utility.variables)
            local hapticEngine = require(script.Parent.Parent.utility.HapticEngine)
            local moveable = require(script.Parent.Parent.utility.moveable)
            local lockable = require(script.Parent.Parent.utility.lockable)

            export type ButtonProps = {name: string?, description: string?, callback: (() -> ())?}
            export type Button = {_frame: Frame, Destroy: (self:Button) -> ()}

            local Button = {}

            Button.__index = Button

            function Button.new(
                props: ButtonProps,
                theme: {[string]: any},
                parent: Instance
            ): Button
                local name = props.name or 'Button'
                local callback = props.callback
                local h = variables.isTouchOnly and 44 or constants.elementHeight
                local frame, stroke, gradient = element.makeFrame('Button_' .. name, theme, parent, h)
                local titleLabel = element.createTitle(frame, name, nil, theme, 0)
                local self = setmetatable({}, Button)::Button

                self._frame = frame

                local currentTheme = theme
                local flashTweenIn: Tween? = nil
                local flashTweenOut: Tween? = nil
                local btn = element.wireHover(frame, stroke, function()
                    return currentTheme
                end, function()
                    if self.locked then
                        return
                    end

                    hapticEngine.click()

                    if flashTweenIn then
                        tween.cancel(flashTweenIn)

                        flashTweenIn = nil
                    end
                    if flashTweenOut then
                        tween.cancel(flashTweenOut)

                        flashTweenOut = nil
                    end

                    flashTweenIn = tween.play(stroke, constants.tweenFast, {
                        Color = currentTheme.AccentColor or Color3.fromHex('#4cc2ff'),
                    })

                    flashTweenIn.Completed:Once(function(state)
                        flashTweenIn = nil

                        if state ~= Enum.PlaybackState.Completed then
                            return
                        end

                        flashTweenOut = tween.play(stroke, constants.tweenFast, {
                            Color = currentTheme.ElementStroke or Color3.fromHex('#2b2b2b'),
                        })

                        flashTweenOut.Completed:Once(function()
                            flashTweenOut = nil
                        end)
                    end)

                    if callback then
                        task.spawn(callback)
                    end
                end)
                local s = self::any

                s._getFlashTweens = function()
                    return flashTweenIn, flashTweenOut
                end
                s._stroke = stroke
                s._theme = theme
                s._titleLabel = titleLabel
                s._themeUnsub = element.subscribeTheme(frame, {
                    frame = frame,
                    stroke = stroke,
                    gradient = gradient,
                    title = titleLabel,
                    titleFont = constants.DEFAULT_FONT,
                    extra = function(t)
                        currentTheme = t
                        s._theme = t
                    end,
                })

                return self
            end
            function Button:_setShown(shown: boolean, animate: boolean?)
                local s = self::any
                local t = s._theme or {}
                local info = if animate ~= false then constants.tweenNormal else nil
                local frameTrans = if shown then(t.ElementTransparency or 0)else 1
                local strokeTrans = if shown then(t.ElementStrokeTransparency or 0)else 1
                local textTrans = if shown then 0 else 1

                if info then
                    tween.play(self._frame, info, {BackgroundTransparency = frameTrans})

                    if s._stroke then
                        tween.play(s._stroke, info, {Transparency = strokeTrans})
                    end
                    if s._titleLabel then
                        tween.play(s._titleLabel, info, {TextTransparency = textTrans})
                    end
                else
                    self._frame.BackgroundTransparency = frameTrans

                    if s._stroke then
                        s._stroke.Transparency = strokeTrans
                    end
                    if s._titleLabel then
                        s._titleLabel.TextTransparency = textTrans
                    end
                end
            end
            function Button:Destroy()
                local s = self::any

                if s._getFlashTweens then
                    local tweenIn, tweenOut = s._getFlashTweens()

                    tween.cancel(tweenIn)
                    tween.cancel(tweenOut)
                end
                if s._themeUnsub then
                    s._themeUnsub()
                end

                self._frame:Destroy()
            end

            moveable(Button)
            lockable(Button)

            return Button
        end)()
    end,
    [4] = function()
        local wax, script, require = ImportGlobals(4)
        local ImportGlobals

        return (function(...)
            local constants = require(script.Parent.Parent.utility.constants)
            local flags = require(script.Parent.Parent.utility.flags)
            local runtime = require(script.Parent.Parent.utility.runtime)
            local element = require(script.Parent.Parent.utility.element)
            local themeUtil = require(script.Parent.Parent.utility.theme)
            local variables = require(script.Parent.Parent.utility.variables)
            local icons = require(script.Parent.Parent.utility.icons)
            local tween = require(script.Parent.Parent.utility.tween)
            local hapticEngine = require(script.Parent.Parent.utility.HapticEngine)
            local moveable = require(script.Parent.Parent.utility.moveable)
            local lockable = require(script.Parent.Parent.utility.lockable)
            local FONT_MONO = constants.DEFAULT_FONT_MONO
            local FONT_SEMI = constants.DEFAULT_FONT_SEMI
            local FONT_REG = constants.DEFAULT_FONT
            local FONT_BOLD = constants.DEFAULT_FONT_BOLD
            local POPUP_W = 500
            local POPUP_H = 244
            local POPUP_PAD = 18
            local TITLE_Y = 14
            local CONTENT_Y = 46
            local CANVAS_W = 170
            local CANVAS_H = 132
            local STRIP_W = 16
            local STRIP_GAP = 8
            local HUE_GAP = 14
            local PREVIEW_H = 104
            local PILL_H = 32
            local PILL_GAP = 8
            local ALPHA_PILL_W = 62
            local NAV_Y = 204
            local NAV_H = 26
            local NAV_BTN = 22
            local CURSOR_D = 18
            local HANDLE_W = STRIP_W + 10
            local HANDLE_H = 14
            local HUE_CS = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
                ColorSequenceKeypoint.new(0.167, Color3.fromRGB(255, 255, 0)),
                ColorSequenceKeypoint.new(0.333, Color3.fromRGB(0, 255, 0)),
                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
                ColorSequenceKeypoint.new(0.667, Color3.fromRGB(0, 0, 255)),
                ColorSequenceKeypoint.new(0.833, Color3.fromRGB(255, 0, 255)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
            })
            local DEFAULT_PRESETS: {Color3} = {
                Color3.fromHex('#FF4757'),
                Color3.fromHex('#FF7F50'),
                Color3.fromHex('#FFB142'),
                Color3.fromHex('#2ED573'),
                Color3.fromHex('#1E90FF'),
                Color3.fromHex('#A55EEA'),
                Color3.fromHex('#EE5A6F'),
                Color3.fromHex('#4ECDC4'),
                Color3.fromHex('#FFB8B8'),
                Color3.fromHex('#FFD3A5'),
                Color3.fromHex('#FFF3A0'),
                Color3.fromHex('#A8E6CF'),
                Color3.fromHex('#B3D9FF'),
                Color3.fromHex('#D5B8FF'),
                Color3.fromHex('#FFC8DD'),
                Color3.fromHex('#CDB4DB'),
                Color3.fromHex('#B71C1C'),
                Color3.fromHex('#D84315'),
                Color3.fromRGB(245, 127, 23),
                Color3.fromRGB(27, 94, 32),
                Color3.fromHex('#FFFFFF'),
                Color3.fromHex('#A1A1AA'),
                Color3.fromHex('#52525B'),
                Color3.fromHex('#000000'),
            }

            export type ColorPickerProps = {name: string?, flag: string?, color: Color3?, alpha: number?, showAlpha: boolean?, overlayParent: Frame?, overlayYOffset: number?, presets: {Color3}?, callback: ((value:Color3, alpha:number) -> ())?}
            export type ColorPicker = {value: Color3, alpha: number, _frame: Frame, Set: (self:ColorPicker, value:Color3, alpha:number?, skipCallback:boolean?) -> (), Destroy: (self:ColorPicker) -> ()}

            local function clamp01(n: number): number
                return math.clamp(n, 0, 1)
            end
            local function colorToHex(c: Color3): string
                return string.format('#%02X%02X%02X', math.round(c.R * 255), math.round(c.G * 255), math.round(c.B * 255))
            end
            local function hexToColor(raw: string): Color3?
                local hex = raw:gsub('[^%x]', '')

                if #hex < 3 then
                    return nil
                end
                if #hex == 3 then
                    hex = hex:sub(1, 1):rep(2) .. hex:sub(2, 2):rep(2) .. hex:sub(3, 3):rep(2)
                end
                if #hex ~= 6 then
                    return nil
                end

                local r = tonumber(hex:sub(1, 2), 16)
                local g = tonumber(hex:sub(3, 4), 16)
                local b = tonumber(hex:sub(5, 6), 16)

                if not r or not g or not b then
                    return nil
                end

                return Color3.fromRGB(r, g, b)
            end
            local function relPos(frame: GuiObject, mousePos: Vector2): Vector2
                local ap = frame.AbsolutePosition
                local as = frame.AbsoluteSize

                if as.X <= 0 or as.Y <= 0 then
                    return Vector2.zero
                end

                return Vector2.new(clamp01((mousePos.X - ap.X) / as.X), clamp01((mousePos.Y - ap.Y) / as.Y))
            end
            local function flatColor(v: any, fallback: Color3): Color3
                if typeof(v) == 'Color3' then
                    return v
                end
                if typeof(v) == 'ColorSequence' and #(v::ColorSequence).Keypoints > 0 then
                    return v.Keypoints[1].Value
                end

                return fallback
            end

            local ColorPicker = {}::{__index: any}

            ColorPicker.__index = ColorPicker

            function ColorPicker.new(
                props: ColorPickerProps,
                theme: {[string]: any},
                parent: Instance
            ): ColorPicker
                local name = props.name or 'ColorPicker'
                local flagKey = props.flag
                local showAlpha = props.showAlpha ~= false
                local callback = props.callback
                local overlayParent = props.overlayParent
                local overlayYOffset = props.overlayYOffset or 0
                local windowMode = overlayParent ~= nil
                local userPresets = props.presets
                local presets: {Color3} = if userPresets and #userPresets > 0 then userPresets else DEFAULT_PRESETS
                local POP_Z: number = if windowMode then constants.zIndex.popup else 2
                local canvasX = POPUP_PAD
                local hueX = canvasX + CANVAS_W + HUE_GAP
                local alphaX = hueX + STRIP_W + STRIP_GAP
                local contentEndX = if showAlpha then alphaX + STRIP_W else hueX + STRIP_W
                local previewX = contentEndX + 14
                local previewW = POPUP_W - POPUP_PAD - previewX
                local hexW = if showAlpha then previewW - ALPHA_PILL_W - PILL_GAP else previewW
                local alphaPillX = previewX + hexW + PILL_GAP
                local initColor: Color3
                local a: number = clamp01(props.alpha or 1)

                if flagKey and flags:Get(flagKey) ~= nil then
                    local stored = flags:Get(flagKey)

                    initColor = if typeof(stored) == 'Color3'then stored::Color3 else(props.color or Color3.fromRGB(255, 255, 255))
                else
                    initColor = props.color or Color3.fromRGB(255, 255, 255)
                end

                local h, s, v = Color3.toHSV(initColor)
                local conns: {RBXScriptConnection} = {}

                local function addConn(c: RBXScriptConnection)
                    table.insert(conns, c)
                end

                local themeUnsub: (() -> ())? = nil
                local frame, stroke, frameGrad = element.makeFrame('ColorPicker_' .. name, theme, parent)
                local pill = Instance.new('Frame')

                pill.AnchorPoint = Vector2.new(1, 0.5)
                pill.Position = UDim2.new(1, -12, 0.5, 0)
                pill.Size = UDim2.fromOffset(32, 18)
                pill.BackgroundColor3 = initColor
                pill.BorderSizePixel = 0
                pill.Parent = frame

                element.mkCorner(pill, 4)
                element.mkStroke(pill, theme.ElementStroke or Color3.fromRGB(50, 42, 80), 1)

                local headerTitle = Instance.new('TextLabel')

                headerTitle.AnchorPoint = Vector2.new(0, 0.5)
                headerTitle.Position = UDim2.new(0, 12, 0.5, 0)
                headerTitle.Size = UDim2.new(1, -(32 + 24), 1, 0)
                headerTitle.BackgroundTransparency = 1
                headerTitle.Text = name
                headerTitle.TextColor3 = theme.ContentColor or Color3.fromRGB(220, 215, 240)
                headerTitle.TextSize = 13
                headerTitle.FontFace = theme.Font or FONT_REG
                headerTitle.TextXAlignment = Enum.TextXAlignment.Left
                headerTitle.TextTruncate = Enum.TextTruncate.AtEnd
                headerTitle.Parent = frame

                local headerBtn = Instance.new('TextButton')

                headerBtn.Size = UDim2.fromScale(1, 1)
                headerBtn.BackgroundTransparency = 1
                headerBtn.Text = ''
                headerBtn.AutoButtonColor = false
                headerBtn.Parent = frame

                local gui: ScreenGui? = nil
                local backdrop: TextButton? = nil

                if not windowMode then
                    local g = Instance.new('ScreenGui')

                    g.Name = 'DeliriumColorPicker_' .. name
                    g.DisplayOrder = constants.displayOrder.popup
                    g.ResetOnSpawn = false
                    g.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
                    g.Enabled = false
                    g.Parent = runtime.guiContainer
                    gui = g

                    local bd = Instance.new('TextButton')

                    bd.Size = UDim2.fromScale(1, 1)
                    bd.BackgroundTransparency = 1
                    bd.Text = ''
                    bd.AutoButtonColor = false
                    bd.ZIndex = 1
                    bd.Parent = g
                    backdrop = bd
                end

                local dimOverlay: TextButton? = nil

                if windowMode then
                    local ov = Instance.new('TextButton')

                    ov.Name = 'ColorPickerDim'
                    ov.Position = UDim2.fromOffset(0, overlayYOffset)
                    ov.Size = UDim2.new(1, 0, 1, -overlayYOffset)
                    ov.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                    ov.BackgroundTransparency = 0.55
                    ov.BorderSizePixel = 0
                    ov.ZIndex = constants.zIndex.popup - 1
                    ov.Active = true
                    ov.Text = ''
                    ov.AutoButtonColor = false
                    ov.Visible = false
                    ov.Parent = overlayParent::Instance
                    dimOverlay = ov
                end

                local popupParent: Instance = if windowMode then(overlayParent::Instance)else(gui::ScreenGui)
                local popup = Instance.new('Frame')

                popup.Name = 'ColorPickerPopup'
                popup.AnchorPoint = Vector2.new(0.5, 0.5)
                popup.Position = UDim2.fromScale(0.5, 0.5)
                popup.Size = UDim2.fromOffset(POPUP_W, POPUP_H)
                popup.BackgroundColor3 = flatColor(theme.WindowColor, Color3.fromRGB(20, 20, 24))
                popup.BorderSizePixel = 0
                popup.ZIndex = POP_Z
                popup.Visible = not windowMode
                popup.ClipsDescendants = true
                popup.Parent = popupParent

                element.mkCorner(popup, 14)

                local popupStroke = element.mkStroke(popup, (theme.SurfaceStroke::Color3?) or Color3.fromRGB(40, 40, 50), 1)

                popupStroke.Transparency = 0.4

                local popupGrad: UIGradient? = nil

                do
                    local g = Instance.new('UIGradient')

                    g.Color = if typeof(theme.WindowColor) == 'ColorSequence'then theme.WindowColor else ColorSequence.new({
                        ColorSequenceKeypoint.new(0, Color3.fromRGB(26, 26, 32)),
                        ColorSequenceKeypoint.new(1, Color3.fromRGB(16, 16, 20)),
                    })
                    g.Rotation = 90
                    g.Parent = popup
                    popupGrad = g
                end

                popup.BackgroundTransparency = theme.WindowTransparency or 0

                local popScale = Instance.new('UIScale')

                popScale.Scale = 1
                popScale.Parent = popup

                local popHit = Instance.new('TextButton')

                popHit.Size = UDim2.fromScale(1, 1)
                popHit.BackgroundTransparency = 1
                popHit.Text = ''
                popHit.AutoButtonColor = false
                popHit.ZIndex = POP_Z
                popHit.Parent = popup

                local popTitle = Instance.new('TextLabel')

                popTitle.Position = UDim2.fromOffset(POPUP_PAD, TITLE_Y)
                popTitle.Size = UDim2.new(1, -POPUP_PAD * 2 - 30, 0, 22)
                popTitle.BackgroundTransparency = 1
                popTitle.Text = name
                popTitle.TextSize = 15
                popTitle.FontFace = FONT_SEMI
                popTitle.TextColor3 = theme.TitlingColor or Color3.fromRGB(245, 245, 250)
                popTitle.TextXAlignment = Enum.TextXAlignment.Left
                popTitle.ZIndex = POP_Z + 2
                popTitle.Parent = popup

                local popClose = Instance.new('TextButton')

                popClose.AnchorPoint = Vector2.new(1, 0)
                popClose.Position = UDim2.new(1, -POPUP_PAD, 0, TITLE_Y + 2)
                popClose.Size = UDim2.fromOffset(20, 20)
                popClose.BackgroundColor3 = Color3.fromRGB(52, 38, 48)
                popClose.BackgroundTransparency = 0.3
                popClose.Text = ''
                popClose.AutoButtonColor = false
                popClose.ZIndex = POP_Z + 2
                popClose.Parent = popup

                element.mkCorner(popClose, 6)

                local closeStroke = element.mkStroke(popClose, Color3.fromRGB(180, 60, 80), 1)

                closeStroke.Transparency = 0.4

                local closeIcon = Instance.new('ImageLabel')

                closeIcon.AnchorPoint = Vector2.new(0.5, 0.5)
                closeIcon.Position = UDim2.fromScale(0.5, 0.5)
                closeIcon.Size = UDim2.fromOffset(10, 10)
                closeIcon.BackgroundTransparency = 1
                closeIcon.Image = icons.Resolve('x', 'Lucide') or 'rbxassetid://136096054247483'
                closeIcon.ImageColor3 = Color3.fromRGB(240, 140, 150)
                closeIcon.ZIndex = POP_Z + 3
                closeIcon.Parent = popClose

                local viewport = Instance.new('Frame')

                viewport.Position = UDim2.fromOffset(0, CONTENT_Y)
                viewport.Size = UDim2.new(1, 0, 1, -(CONTENT_Y + (POPUP_H - NAV_Y)))
                viewport.BackgroundTransparency = 1
                viewport.BorderSizePixel = 0
                viewport.ClipsDescendants = true
                viewport.ZIndex = POP_Z + 1
                viewport.Parent = popup

                local pagesContainer = Instance.new('Frame')

                pagesContainer.Size = UDim2.new(2, 0, 1, 0)
                pagesContainer.Position = UDim2.fromOffset(0, 0)
                pagesContainer.BackgroundTransparency = 1
                pagesContainer.BorderSizePixel = 0
                pagesContainer.ZIndex = POP_Z + 1
                pagesContainer.Parent = viewport

                local page1 = Instance.new('Frame')

                page1.Name = 'Page_Picker'
                page1.Size = UDim2.new(0.5, 0, 1, 0)
                page1.Position = UDim2.fromOffset(0, 0)
                page1.BackgroundTransparency = 1
                page1.BorderSizePixel = 0
                page1.ZIndex = POP_Z + 1
                page1.Parent = pagesContainer

                local canvas = Instance.new('Frame')

                canvas.Name = 'Canvas'
                canvas.Position = UDim2.fromOffset(canvasX, 0)
                canvas.Size = UDim2.fromOffset(CANVAS_W, CANVAS_H)
                canvas.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
                canvas.BorderSizePixel = 0
                canvas.ZIndex = POP_Z + 2
                canvas.ClipsDescendants = true
                canvas.Parent = page1

                element.mkCorner(canvas, 10)

                local satOvl = Instance.new('Frame')

                satOvl.Size = UDim2.fromScale(1, 1)
                satOvl.BackgroundColor3 = Color3.new(1, 1, 1)
                satOvl.BorderSizePixel = 0
                satOvl.ZIndex = POP_Z + 3
                satOvl.Parent = canvas

                element.mkCorner(satOvl, 10)

                do
                    local g = Instance.new('UIGradient')

                    g.Transparency = NumberSequence.new({
                        NumberSequenceKeypoint.new(0, 0),
                        NumberSequenceKeypoint.new(1, 1),
                    })
                    g.Parent = satOvl
                end

                local valOvl = Instance.new('Frame')

                valOvl.Size = UDim2.fromScale(1, 1)
                valOvl.BackgroundColor3 = Color3.new(0, 0, 0)
                valOvl.BorderSizePixel = 0
                valOvl.ZIndex = POP_Z + 4
                valOvl.Parent = canvas

                element.mkCorner(valOvl, 10)

                do
                    local g = Instance.new('UIGradient')

                    g.Rotation = 90
                    g.Transparency = NumberSequence.new({
                        NumberSequenceKeypoint.new(0, 1),
                        NumberSequenceKeypoint.new(1, 0),
                    })
                    g.Parent = valOvl
                end

                local cursor = Instance.new('Frame')

                cursor.Name = 'SVCursor'
                cursor.AnchorPoint = Vector2.new(0.5, 0.5)
                cursor.Size = UDim2.fromOffset(CURSOR_D, CURSOR_D)
                cursor.Position = UDim2.new(s, 0, 1 - v, 0)
                cursor.BackgroundTransparency = 1
                cursor.BorderSizePixel = 0
                cursor.ZIndex = POP_Z + 8
                cursor.Parent = canvas

                element.mkCorner(cursor, CURSOR_D // 2)

                do
                    local cs = Instance.new('UIStroke')

                    cs.Color = Color3.new(1, 1, 1)
                    cs.Thickness = 2
                    cs.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                    cs.Transparency = 0
                    cs.Parent = cursor
                end

                local canvasBtn = Instance.new('TextButton')

                canvasBtn.BackgroundTransparency = 1
                canvasBtn.Size = UDim2.fromScale(1, 1)
                canvasBtn.Text = ''
                canvasBtn.AutoButtonColor = false
                canvasBtn.ZIndex = POP_Z + 6
                canvasBtn.Parent = canvas

                local hueBar = Instance.new('Frame')

                hueBar.Name = 'HueBar'
                hueBar.Position = UDim2.fromOffset(hueX, 0)
                hueBar.Size = UDim2.fromOffset(STRIP_W, CANVAS_H)
                hueBar.BackgroundColor3 = Color3.new(1, 1, 1)
                hueBar.BorderSizePixel = 0
                hueBar.ZIndex = POP_Z + 2
                hueBar.Parent = page1

                element.mkCorner(hueBar, STRIP_W // 2)

                do
                    local g = Instance.new('UIGradient')

                    g.Color = HUE_CS
                    g.Rotation = 90
                    g.Parent = hueBar
                end

                local hueHandle = Instance.new('Frame')

                hueHandle.Name = 'HueHandle'
                hueHandle.AnchorPoint = Vector2.new(0.5, 0.5)
                hueHandle.Size = UDim2.fromOffset(HANDLE_W, HANDLE_H)
                hueHandle.Position = UDim2.fromOffset(hueX + STRIP_W // 2, CANVAS_H * h)
                hueHandle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                hueHandle.BorderSizePixel = 0
                hueHandle.ZIndex = POP_Z + 4
                hueHandle.Parent = page1

                element.mkCorner(hueHandle, 4)

                do
                    local hs = Instance.new('UIStroke')

                    hs.Color = Color3.fromRGB(20, 20, 24)
                    hs.Thickness = 1.5
                    hs.Transparency = 0.3
                    hs.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                    hs.Parent = hueHandle
                end

                local hueBtn = Instance.new('TextButton')

                hueBtn.BackgroundTransparency = 1
                hueBtn.AnchorPoint = Vector2.new(0.5, 0.5)
                hueBtn.Position = UDim2.fromScale(0.5, 0.5)
                hueBtn.Size = UDim2.new(1, 16, 1, 8)
                hueBtn.Text = ''
                hueBtn.AutoButtonColor = false
                hueBtn.ZIndex = POP_Z + 5
                hueBtn.Parent = hueBar

                local alphaBar: Frame? = nil
                local alphaHandle: Frame? = nil
                local alphaBtn: TextButton? = nil
                local alphaColorOvl: Frame? = nil

                if showAlpha then
                    local bar = Instance.new('CanvasGroup')

                    bar.Name = 'AlphaBar'
                    bar.Position = UDim2.fromOffset(alphaX, 0)
                    bar.Size = UDim2.fromOffset(STRIP_W, CANVAS_H)
                    bar.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
                    bar.BorderSizePixel = 0
                    bar.ClipsDescendants = true
                    bar.ZIndex = POP_Z + 2
                    bar.Parent = page1

                    element.mkCorner(bar, STRIP_W // 2)

                    local SQ = 8
                    local cols = math.ceil(STRIP_W / SQ) + 1
                    local rows = math.ceil(CANVAS_H / SQ) + 1

                    for y = 0, rows do
                        for x = 0, cols do
                            if (x + y) % 2 == 1 then
                                local sq = Instance.new('Frame')

                                sq.Position = UDim2.fromOffset(x * SQ, y * SQ)
                                sq.Size = UDim2.fromOffset(SQ, SQ)
                                sq.BackgroundColor3 = Color3.fromRGB(140, 140, 140)
                                sq.BorderSizePixel = 0
                                sq.ZIndex = POP_Z + 2
                                sq.Parent = bar
                            end
                        end
                    end

                    local colorOvl = Instance.new('Frame')

                    colorOvl.Size = UDim2.fromScale(1, 1)
                    colorOvl.BackgroundColor3 = Color3.fromHSV(h, s, v)
                    colorOvl.BackgroundTransparency = 0
                    colorOvl.BorderSizePixel = 0
                    colorOvl.ZIndex = POP_Z + 3
                    colorOvl.Parent = bar

                    do
                        local g = Instance.new('UIGradient')

                        g.Rotation = 90
                        g.Transparency = NumberSequence.new({
                            NumberSequenceKeypoint.new(0, 0),
                            NumberSequenceKeypoint.new(1, 1),
                        })
                        g.Parent = colorOvl
                    end

                    alphaColorOvl = colorOvl

                    local handle = Instance.new('Frame')

                    handle.Name = 'AlphaHandle'
                    handle.AnchorPoint = Vector2.new(0.5, 0.5)
                    handle.Size = UDim2.fromOffset(HANDLE_W, HANDLE_H)
                    handle.Position = UDim2.fromOffset(alphaX + STRIP_W // 2, CANVAS_H * (1 - a))
                    handle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    handle.BorderSizePixel = 0
                    handle.ZIndex = POP_Z + 5
                    handle.Parent = page1

                    element.mkCorner(handle, 4)

                    do
                        local hs = Instance.new('UIStroke')

                        hs.Color = Color3.fromRGB(20, 20, 24)
                        hs.Thickness = 1.5
                        hs.Transparency = 0.3
                        hs.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                        hs.Parent = handle
                    end

                    local abtn = Instance.new('TextButton')

                    abtn.BackgroundTransparency = 1
                    abtn.AnchorPoint = Vector2.new(0.5, 0.5)
                    abtn.Position = UDim2.fromScale(0.5, 0.5)
                    abtn.Size = UDim2.new(1, 16, 1, 8)
                    abtn.Text = ''
                    abtn.AutoButtonColor = false
                    abtn.ZIndex = POP_Z + 6
                    abtn.Parent = bar
                    alphaBar = bar
                    alphaHandle = handle
                    alphaBtn = abtn
                end

                local previewBox = Instance.new('CanvasGroup')

                previewBox.Name = 'PreviewBox'
                previewBox.Position = UDim2.fromOffset(previewX, 0)
                previewBox.Size = UDim2.fromOffset(previewW, PREVIEW_H)
                previewBox.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
                previewBox.BorderSizePixel = 0
                previewBox.ClipsDescendants = true
                previewBox.ZIndex = POP_Z + 2
                previewBox.Parent = page1

                element.mkCorner(previewBox, 12)

                do
                    local SQ = 12
                    local cols = math.ceil(previewW / SQ) + 1
                    local rows = math.ceil(PREVIEW_H / SQ) + 1

                    for y = 0, rows do
                        for x = 0, cols do
                            if (x + y) % 2 == 1 then
                                local sq = Instance.new('Frame')

                                sq.Position = UDim2.fromOffset(x * SQ, y * SQ)
                                sq.Size = UDim2.fromOffset(SQ, SQ)
                                sq.BackgroundColor3 = Color3.fromRGB(140, 140, 140)
                                sq.BorderSizePixel = 0
                                sq.ZIndex = POP_Z + 2
                                sq.Parent = previewBox
                            end
                        end
                    end
                end

                local previewFill = Instance.new('Frame')

                previewFill.Size = UDim2.fromScale(1, 1)
                previewFill.BackgroundColor3 = initColor
                previewFill.BackgroundTransparency = 1 - a
                previewFill.BorderSizePixel = 0
                previewFill.ZIndex = POP_Z + 3
                previewFill.Parent = previewBox

                local hexFrame = Instance.new('Frame')

                hexFrame.Position = UDim2.fromOffset(previewX, PREVIEW_H + PILL_GAP)
                hexFrame.Size = UDim2.fromOffset(hexW, PILL_H)
                hexFrame.BackgroundColor3 = Color3.fromRGB(38, 38, 44)
                hexFrame.BorderSizePixel = 0
                hexFrame.ZIndex = POP_Z + 2
                hexFrame.Parent = page1

                element.mkCorner(hexFrame, 10)

                local hexInput = Instance.new('TextBox')

                hexInput.AnchorPoint = Vector2.new(0.5, 0.5)
                hexInput.Position = UDim2.fromScale(0.5, 0.5)
                hexInput.Size = UDim2.new(1, -12, 1, 0)
                hexInput.BackgroundTransparency = 1
                hexInput.Text = colorToHex(initColor)
                hexInput.PlaceholderText = '#RRGGBB'
                hexInput.TextSize = 15
                hexInput.FontFace = FONT_SEMI
                hexInput.TextColor3 = theme.ContentColor or Color3.fromRGB(230, 230, 240)
                hexInput.PlaceholderColor3 = theme.PlaceholderColor or Color3.fromRGB(140, 130, 175)
                hexInput.ClearTextOnFocus = false
                hexInput.TextXAlignment = Enum.TextXAlignment.Center
                hexInput.ZIndex = POP_Z + 3
                hexInput.Parent = hexFrame

                addConn(hexInput:GetPropertyChangedSignal('Text'):Connect(function(
                )
                    local raw = hexInput.Text:gsub('[^%x#]', '')

                    if #raw == 0 or raw:sub(1, 1) ~= '#' then
                        raw = '#' .. raw:gsub('#', '')
                    else
                        raw = '#' .. raw:sub(2):gsub('#', '')
                    end
                    if #raw > 7 then
                        raw = raw:sub(1, 7)
                    end
                    if hexInput.Text ~= raw then
                        hexInput.Text = raw
                    end
                end))

                local alphaInput: TextBox? = nil

                if showAlpha then
                    local af = Instance.new('Frame')

                    af.Position = UDim2.fromOffset(alphaPillX, PREVIEW_H + PILL_GAP)
                    af.Size = UDim2.fromOffset(ALPHA_PILL_W, PILL_H)
                    af.BackgroundColor3 = Color3.fromRGB(38, 38, 44)
                    af.BorderSizePixel = 0
                    af.ZIndex = POP_Z + 2
                    af.Parent = page1

                    element.mkCorner(af, 10)

                    local ai = Instance.new('TextBox')

                    ai.AnchorPoint = Vector2.new(0.5, 0.5)
                    ai.Position = UDim2.fromScale(0.5, 0.5)
                    ai.Size = UDim2.new(1, -8, 1, 0)
                    ai.BackgroundTransparency = 1
                    ai.Text = tostring(math.round(a * 100))
                    ai.PlaceholderText = '100'
                    ai.TextSize = 15
                    ai.FontFace = FONT_SEMI
                    ai.TextColor3 = theme.ContentColor or Color3.fromRGB(230, 230, 240)
                    ai.PlaceholderColor3 = theme.PlaceholderColor or Color3.fromRGB(140, 130, 175)
                    ai.ClearTextOnFocus = false
                    ai.TextXAlignment = Enum.TextXAlignment.Center
                    ai.ZIndex = POP_Z + 3
                    ai.Parent = af
                    alphaInput = ai

                    addConn(ai:GetPropertyChangedSignal('Text'):Connect(function(
                    )
                        local raw = ai.Text:gsub('%D', '')

                        if #raw > 3 then
                            raw = raw:sub(1, 3)
                        end
                        if ai.Text ~= raw then
                            ai.Text = raw
                        end
                    end))
                end

                local page2 = Instance.new('Frame')

                page2.Name = 'Page_Palette'
                page2.Size = UDim2.new(0.5, 0, 1, 0)
                page2.Position = UDim2.new(0.5, 0, 0, 0)
                page2.BackgroundTransparency = 1
                page2.BorderSizePixel = 0
                page2.ZIndex = POP_Z + 1
                page2.Parent = pagesContainer

                local gridHost = Instance.new('Frame')

                gridHost.Position = UDim2.fromOffset(POPUP_PAD, 8)
                gridHost.Size = UDim2.new(1, -POPUP_PAD * 2, 1, -8)
                gridHost.BackgroundTransparency = 1
                gridHost.BorderSizePixel = 0
                gridHost.ZIndex = POP_Z + 2
                gridHost.Parent = page2

                local GRID_COLS = 8
                local GRID_GAP = 10
                local availW = POPUP_W - POPUP_PAD * 2
                local cellW = math.floor((availW - GRID_GAP * (GRID_COLS - 1)) / GRID_COLS)
                local gridLayout = Instance.new('UIGridLayout')

                gridLayout.CellSize = UDim2.fromOffset(cellW, 40)
                gridLayout.CellPadding = UDim2.fromOffset(GRID_GAP, GRID_GAP)
                gridLayout.FillDirection = Enum.FillDirection.Horizontal
                gridLayout.FillDirectionMaxCells = GRID_COLS
                gridLayout.StartCorner = Enum.StartCorner.TopLeft
                gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
                gridLayout.VerticalAlignment = Enum.VerticalAlignment.Top
                gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
                gridLayout.Parent = gridHost

                type SwatchEntry = {frame: Frame, stroke: UIStroke, color: Color3}

                local swatches: {SwatchEntry} = {}
                local refresh: () -> () = nil::any
                local fireChanged: (immediate:boolean?) -> () = nil::any

                for i, preset in ipairs(presets)do
                    local sw = Instance.new('Frame')

                    sw.Name = 'Swatch'
                    sw.BackgroundColor3 = preset
                    sw.BorderSizePixel = 0
                    sw.LayoutOrder = i
                    sw.ZIndex = POP_Z + 3
                    sw.Parent = gridHost

                    element.mkCorner(sw, 8)

                    local st = element.mkStroke(sw, Color3.fromRGB(60, 60, 70), 1.5)

                    st.Transparency = 0.4
                    st.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                    st.ZIndex = POP_Z + 4

                    local hit = Instance.new('TextButton')

                    hit.Name = 'Hit'
                    hit.Size = UDim2.fromScale(1, 1)
                    hit.BackgroundTransparency = 1
                    hit.Text = ''
                    hit.AutoButtonColor = false
                    hit.Active = true
                    hit.ZIndex = POP_Z + 5
                    hit.Parent = sw

                    hit.Activated:Connect(function()
                        h, s, v = Color3.toHSV(preset)
                        a = 1

                        refresh()
                        fireChanged(true)
                    end)

                    if not variables.isTouchOnly then
                        hit.MouseEnter:Connect(function()
                            tween.fire(st, constants.tweenFast, {Transparency = 0.1})
                        end)
                        hit.MouseLeave:Connect(function()
                            refresh()
                        end)
                    end

                    table.insert(swatches, {
                        frame = sw,
                        stroke = st,
                        color = preset,
                    })
                end

                local nav = Instance.new('Frame')

                nav.Name = 'Nav'
                nav.AnchorPoint = Vector2.new(0.5, 0)
                nav.Position = UDim2.fromOffset(POPUP_W // 2, NAV_Y)
                nav.Size = UDim2.fromOffset(140, NAV_H)
                nav.BackgroundTransparency = 1
                nav.BorderSizePixel = 0
                nav.ZIndex = POP_Z + 3
                nav.Parent = popup

                local navLayout = Instance.new('UIListLayout')

                navLayout.FillDirection = Enum.FillDirection.Horizontal
                navLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
                navLayout.VerticalAlignment = Enum.VerticalAlignment.Center
                navLayout.Padding = UDim.new(0, 10)
                navLayout.SortOrder = Enum.SortOrder.LayoutOrder
                navLayout.Parent = nav

                local function makeNavBtn(order: number, isNext: boolean): (TextButton,ImageLabel)
                    local btn = Instance.new('TextButton')

                    btn.Name = if isNext then'Next'else'Prev'
                    btn.Size = UDim2.fromOffset(NAV_BTN, NAV_BTN)
                    btn.BackgroundColor3 = Color3.fromRGB(38, 38, 44)
                    btn.BackgroundTransparency = 0.3
                    btn.BorderSizePixel = 0
                    btn.Text = ''
                    btn.AutoButtonColor = false
                    btn.LayoutOrder = order
                    btn.ZIndex = POP_Z + 4
                    btn.Parent = nav

                    element.mkCorner(btn, 6)

                    local iconAsset = icons.Resolve(if isNext then'chevron-right'else'chevron-left', 'Lucide') or 'rbxassetid://126507964682213'
                    local ic = Instance.new('ImageLabel')

                    ic.AnchorPoint = Vector2.new(0.5, 0.5)
                    ic.Position = UDim2.fromScale(0.5, 0.5)
                    ic.Size = UDim2.fromOffset(12, 12)
                    ic.BackgroundTransparency = 1
                    ic.Image = iconAsset
                    ic.ImageColor3 = theme.PlaceholderColor or Color3.fromRGB(180, 180, 200)
                    ic.ZIndex = POP_Z + 5
                    ic.Parent = btn

                    if not variables.isTouchOnly then
                        btn.MouseEnter:Connect(function()
                            tween.fire(btn, constants.tweenFocus, {BackgroundTransparency = 0.05})
                            tween.fire(ic, constants.tweenFocus, {
                                ImageColor3 = Color3.fromRGB(240, 240, 250),
                            })
                        end)
                        btn.MouseLeave:Connect(function()
                            tween.fire(btn, constants.tweenFocus, {BackgroundTransparency = 0.3})
                            tween.fire(ic, constants.tweenFocus, {
                                ImageColor3 = Color3.fromRGB(180, 180, 200),
                            })
                        end)
                    end

                    return btn, ic
                end

                local prevBtn, prevIcon = makeNavBtn(1, false)
                local dotRow = Instance.new('Frame')

                dotRow.Name = 'DotRow'
                dotRow.Size = UDim2.fromOffset(60, NAV_H)
                dotRow.BackgroundTransparency = 1
                dotRow.LayoutOrder = 2
                dotRow.ZIndex = POP_Z + 3
                dotRow.Parent = nav

                local dotLayout = Instance.new('UIListLayout')

                dotLayout.FillDirection = Enum.FillDirection.Horizontal
                dotLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
                dotLayout.VerticalAlignment = Enum.VerticalAlignment.Center
                dotLayout.Padding = UDim.new(0, 6)
                dotLayout.Parent = dotRow

                local function makeDot(order: number): TextButton
                    local dot = Instance.new('TextButton')

                    dot.Name = 'Dot' .. order
                    dot.Size = UDim2.fromOffset(6, 6)
                    dot.BackgroundColor3 = theme.PlaceholderColor or Color3.fromRGB(140, 130, 175)
                    dot.BackgroundTransparency = 0.5
                    dot.BorderSizePixel = 0
                    dot.Text = ''
                    dot.AutoButtonColor = false
                    dot.LayoutOrder = order
                    dot.ZIndex = POP_Z + 4
                    dot.Parent = dotRow

                    element.mkCorner(dot, 3)

                    return dot
                end

                local dot1 = makeDot(1)
                local dot2 = makeDot(2)
                local nextBtn, nextIcon = makeNavBtn(3, true)
                local currentPage = 1
                local dragActive = false
                local dragStartX = 0
                local dragStartOffset = 0
                local dragOffset = 0

                local function vw(): number
                    local w = viewport.AbsoluteSize.X

                    return if w > 0 then w else POPUP_W
                end
                local function setDotVisual(
                    dot: TextButton,
                    active: boolean,
                    t: {[string]: any}
                )
                    local activeCol = t.AccentColor or Color3.fromHex('#4cc2ff')
                    local inactiveCol = t.PlaceholderColor or Color3.fromRGB(140, 130, 175)

                    tween.fire(dot, constants.tweenFast, {
                        Size = if active then UDim2.fromOffset(18, 6)else UDim2.fromOffset(6, 6),
                        BackgroundColor3 = if active then activeCol else inactiveCol,
                        BackgroundTransparency = if active then 0 else 0.5,
                    })
                end
                local function snapTo(page: number, animated: boolean)
                    page = math.clamp(page, 1, 2)
                    currentPage = page

                    local targetX = -(page - 1) * vw()

                    dragOffset = targetX

                    if animated then
                        tween.fire(pagesContainer, constants.tweenNormal, {
                            Position = UDim2.fromOffset(targetX, 0),
                        })
                    else
                        pagesContainer.Position = UDim2.fromOffset(targetX, 0)
                    end

                    local t = theme

                    setDotVisual(dot1, page == 1, t)
                    setDotVisual(dot2, page == 2, t)
                end

                addConn(popup:GetPropertyChangedSignal('AbsoluteSize'):Connect(function(
                )
                    if popup.AbsoluteSize.X > 0 then
                        snapTo(currentPage, false)
                    end
                end))
                addConn(dot1.Activated:Connect(function()
                    snapTo(1, true)
                end))
                addConn(dot2.Activated:Connect(function()
                    snapTo(2, true)
                end))
                prevBtn.Activated:Connect(function()
                    snapTo(currentPage - 1, true)
                end)
                nextBtn.Activated:Connect(function()
                    snapTo(currentPage + 1, true)
                end)

                local function pointInFrame(
                    gui: GuiObject?,
                    x: number,
                    y: number
                ): boolean
                    if not gui or not gui.Visible then
                        return false
                    end

                    local ap = gui.AbsolutePosition
                    local as = gui.AbsoluteSize

                    return x >= ap.X and x <= ap.X + as.X and y >= ap.Y and y <= ap.Y + as.Y
                end

                addConn(popup.InputBegan:Connect(function(input: InputObject)
                    if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
                        return
                    end

                    local pos = input.Position

                    if pointInFrame(canvasBtn, pos.X, pos.Y) then
                        return
                    end
                    if pointInFrame(hueBtn, pos.X, pos.Y) then
                        return
                    end
                    if alphaBtn and pointInFrame(alphaBtn, pos.X, pos.Y) then
                        return
                    end
                    if pointInFrame(prevBtn, pos.X, pos.Y) then
                        return
                    end
                    if pointInFrame(nextBtn, pos.X, pos.Y) then
                        return
                    end
                    if pointInFrame(dot1, pos.X, pos.Y) then
                        return
                    end
                    if pointInFrame(dot2, pos.X, pos.Y) then
                        return
                    end

                    dragActive = true
                    dragStartX = pos.X
                    dragStartOffset = dragOffset

                    local moved = false
                    local moveConn: RBXScriptConnection? = nil
                    local endConn: RBXScriptConnection? = nil

                    local function finish()
                        if moveConn then
                            moveConn:Disconnect()

                            moveConn = nil
                        end
                        if endConn then
                            endConn:Disconnect()

                            endConn = nil
                        end

                        dragActive = false

                        if not moved then
                            return
                        end

                        local w = vw()
                        local currentSnapX = -(currentPage - 1) * w
                        local dx = dragOffset - currentSnapX
                        local threshold = w * 0.22
                        local target = currentPage

                        if dx <= -threshold and currentPage < 2 then
                            target = currentPage + 1
                        end
                        if dx >= threshold and currentPage > 1 then
                            target = currentPage - 1
                        end

                        snapTo(target, true)
                    end

                    moveConn = runtime.userInputService.InputChanged:Connect(function(
                        io: InputObject
                    )
                        if not dragActive then
                            return
                        end
                        if io.UserInputType ~= Enum.UserInputType.MouseMovement and io.UserInputType ~= Enum.UserInputType.Touch then
                            return
                        end

                        local dx = io.Position.X - dragStartX

                        if math.abs(dx) > 4 then
                            moved = true
                        end

                        local w = vw()
                        local minX = -(2 - 1) * w
                        local targetX = math.clamp(dragStartOffset + dx, minX, 0)

                        dragOffset = targetX
                        pagesContainer.Position = UDim2.fromOffset(targetX, 0)
                    end)
                    endConn = runtime.userInputService.InputEnded:Connect(function(
                        io: InputObject
                    )
                        if io.UserInputType == Enum.UserInputType.MouseButton1 or io.UserInputType == Enum.UserInputType.Touch then
                            finish()
                        end
                    end)
                end))

                local dragging: string? = nil
                local colorMoveConn: RBXScriptConnection? = nil
                local colorEndConn: RBXScriptConnection? = nil

                local function stopColorDrag()
                    dragging = nil

                    if colorMoveConn then
                        colorMoveConn:Disconnect()

                        colorMoveConn = nil
                    end
                    if colorEndConn then
                        colorEndConn:Disconnect()

                        colorEndConn = nil
                    end

                    fireChanged(true)
                end
                local function pump(mousePos: Vector2)
                    if dragging == 'canvas' then
                        local p = relPos(canvas, mousePos)

                        s = p.X
                        v = 1 - p.Y
                    elseif dragging == 'hue' then
                        h = relPos(hueBar, mousePos).Y
                    elseif dragging == 'alpha' and alphaBar then
                        a = 1 - relPos(alphaBar::Frame, mousePos).Y
                    end

                    refresh()
                    fireChanged(false)
                end
                local function startColorDrag(
                    target: string,
                    mousePos: Vector2
                )
                    dragging = target

                    pump(mousePos)

                    if not colorMoveConn then
                        colorMoveConn = runtime.userInputService.InputChanged:Connect(function(
                            input: InputObject
                        )
                            if not dragging then
                                return
                            end
                            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                                pump(Vector2.new(input.Position.X, input.Position.Y))
                            end
                        end)
                    end
                    if not colorEndConn then
                        colorEndConn = runtime.userInputService.InputEnded:Connect(function(
                            input: InputObject
                        )
                            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                                stopColorDrag()
                            end
                        end)
                    end
                end

                addConn(canvasBtn.InputBegan:Connect(function(input: InputObject)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        startColorDrag('canvas', Vector2.new(input.Position.X, input.Position.Y))
                    end
                end))
                addConn(hueBtn.InputBegan:Connect(function(input: InputObject)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        startColorDrag('hue', Vector2.new(input.Position.X, input.Position.Y))
                    end
                end))

                if alphaBtn then
                    addConn((alphaBtn::TextButton).InputBegan:Connect(function(
                        input: InputObject
                    )
                        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                            startColorDrag('alpha', Vector2.new(input.Position.X, input.Position.Y))
                        end
                    end))
                end

                local _firePending = false

                refresh = function()
                    local color = Color3.fromHSV(h, s, v)
                    local pure = Color3.fromHSV(h, 1, 1)

                    canvas.BackgroundColor3 = pure
                    cursor.Position = UDim2.new(s, 0, 1 - v, 0)
                    hueHandle.Position = UDim2.fromOffset(hueX + STRIP_W // 2, CANVAS_H * h)
                    pill.BackgroundColor3 = color
                    previewFill.BackgroundColor3 = color
                    previewFill.BackgroundTransparency = 1 - a

                    if showAlpha then
                        if alphaBar then
                            local ab = alphaBar::Frame

                            ab.BackgroundColor3 = color
                        end
                        if alphaColorOvl then
                            alphaColorOvl.BackgroundColor3 = color
                        end
                        if alphaHandle then
                            alphaHandle.Position = UDim2.fromOffset(alphaX + STRIP_W // 2, CANVAS_H * (1 - a))
                        end
                    end
                    if not hexInput:IsFocused() then
                        hexInput.Text = colorToHex(color)
                    end
                    if alphaInput and not alphaInput:IsFocused() then
                        alphaInput.Text = tostring(math.round(a * 100))
                    end

                    for _, entry in ipairs(swatches)do
                        local matches = entry.color.R == color.R and entry.color.G == color.G and entry.color.B == color.B

                        if matches then
                            entry.stroke.Color = Color3.fromRGB(255, 255, 255)
                            entry.stroke.Thickness = 2
                            entry.stroke.Transparency = 0
                        else
                            entry.stroke.Color = Color3.fromRGB(60, 60, 70)
                            entry.stroke.Thickness = 1.5
                            entry.stroke.Transparency = 0.4
                        end
                    end
                end
                fireChanged = function(immediate: boolean?)
                    local color = Color3.fromHSV(h, s, v)

                    if flagKey then
                        flags:Set(flagKey, color)
                    end
                    if not callback then
                        return
                    end
                    if immediate then
                        _firePending = false

                        task.spawn(callback, color, a)

                        return
                    end
                    if _firePending then
                        return
                    end

                    _firePending = true

                    task.defer(function()
                        if not _firePending then
                            return
                        end

                        _firePending = false

                        local curCol = Color3.fromHSV(h, s, v)

                        task.spawn(callback, curCol, a)
                    end)
                end

                addConn(hexInput.FocusLost:Connect(function()
                    local color = hexToColor(hexInput.Text)

                    if not color then
                        hexInput.Text = colorToHex(Color3.fromHSV(h, s, v))

                        return
                    end

                    h, s, v = Color3.toHSV(color)

                    refresh()
                    fireChanged(true)
                end))

                if alphaInput then
                    addConn(alphaInput.FocusLost:Connect(function()
                        local n = tonumber((alphaInput::TextBox).Text)

                        if n then
                            a = clamp01(n / 100)

                            refresh()
                            fireChanged(true)
                        else
                            local ai = alphaInput::TextBox

                            ai.Text = tostring(math.round(a * 100))
                        end
                    end))
                end

                local isOpen = false

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

                    local fitW = (winW - 40) / POPUP_W
                    local fitH = (winH - 40) / POPUP_H

                    popScale.Scale = math.clamp(math.min(fitW, fitH, 1), 0.55, 1)
                end
                local function openPopup()
                    if isOpen then
                        return
                    end

                    isOpen = true

                    adjustScale()
                    tween.fire(stroke, constants.tweenFocus, {
                        Color = theme.AccentColor or Color3.fromHex('#4cc2ff'),
                        Transparency = 0,
                    })

                    if windowMode then
                        popup.Visible = true

                        if dimOverlay then
                            local dov = dimOverlay::TextButton

                            dov.Visible = true
                        end
                    else
                        local sg = gui::ScreenGui

                        sg.Enabled = true
                    end

                    refresh()
                end
                local function closePopup()
                    if not isOpen then
                        return
                    end

                    isOpen = false

                    stopColorDrag()
                    tween.fire(stroke, constants.tweenFocus, {
                        Color = theme.ElementStroke or Color3.fromHex('#2b2b2b'),
                        Transparency = theme.ElementStrokeTransparency or 0,
                    })

                    if windowMode then
                        popup.Visible = false

                        if dimOverlay then
                            local dov = dimOverlay::TextButton

                            dov.Visible = false
                        end
                    else
                        local sg = gui::ScreenGui

                        sg.Enabled = false
                    end
                end

                if windowMode and overlayParent then
                    addConn((overlayParent::Frame):GetPropertyChangedSignal('AbsoluteSize'):Connect(function(
                    )
                        if isOpen then
                            adjustScale()
                        end
                    end))
                else
                    local cam = runtime.workspace.CurrentCamera

                    if cam then
                        addConn(cam:GetPropertyChangedSignal('ViewportSize'):Connect(function(
                        )
                            if isOpen then
                                adjustScale()
                            end
                        end))
                    end
                end

                addConn(headerBtn.Activated:Connect(function()
                    if isOpen then
                        closePopup()
                    else
                        openPopup()
                    end
                end))

                if backdrop then
                    addConn((backdrop::TextButton).Activated:Connect(closePopup))
                end
                if dimOverlay then
                    addConn((dimOverlay::TextButton).Activated:Connect(closePopup))
                end

                addConn(popClose.Activated:Connect(closePopup))
                addConn(runtime.userInputService.InputBegan:Connect(function(
                    input: InputObject,
                    processed: boolean
                )
                    if processed or not isOpen then
                        return
                    end
                    if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.Escape then
                        closePopup()
                    end
                end))

                themeUnsub = element.subscribeTheme(frame, {
                    frame = frame,
                    stroke = stroke,
                    gradient = frameGrad,
                    title = headerTitle,
                    titleFont = FONT_REG,
                    extra = function(t)
                        theme = t
                        stroke.Color = if isOpen then(t.ElementStrokeHover or t.AccentColor or constants.COLORS.ACCENT)else(t.ElementStroke or constants.COLORS.STROKE)
                        popTitle.TextColor3 = t.TitlingColor or constants.COLORS.TEXT
                        popTitle.FontFace = t.TitleFont or FONT_SEMI
                        hexInput.TextColor3 = t.ContentColor or constants.COLORS.TEXT
                        hexInput.PlaceholderColor3 = t.PlaceholderColor or constants.COLORS.TEXT_MUTED

                        if alphaInput then
                            alphaInput.TextColor3 = t.ContentColor or constants.COLORS.TEXT
                            alphaInput.PlaceholderColor3 = t.PlaceholderColor or constants.COLORS.TEXT_MUTED
                        end

                        popup.BackgroundColor3 = flatColor(t.WindowColor, Color3.fromRGB(20, 20, 24))
                        popup.BackgroundTransparency = t.WindowTransparency or 0

                        if popupGrad and typeof(t.WindowColor) == 'ColorSequence' then
                            popupGrad.Color = t.WindowColor
                        end

                        popupStroke.Color = t.SurfaceStroke or constants.COLORS.STROKE_SURFACE
                        closeIcon.ImageColor3 = t.ErrorColor or constants.COLORS.ERROR
                        closeStroke.Color = t.ErrorColor or constants.COLORS.ERROR
                        hexFrame.BackgroundColor3 = t.NeutralButton or Color3.fromRGB(38, 38, 44)

                        if alphaInput then
                            local af = (alphaInput::TextBox).Parent

                            if af and af:IsA('Frame') then
                                local afFrame = af::Frame

                                afFrame.BackgroundColor3 = t.NeutralButton or Color3.fromRGB(38, 38, 44)
                            end
                        end

                        prevIcon.ImageColor3 = t.PlaceholderColor or Color3.fromRGB(180, 180, 200)
                        nextIcon.ImageColor3 = t.PlaceholderColor or Color3.fromRGB(180, 180, 200)
                        prevBtn.BackgroundColor3 = t.NeutralButton or Color3.fromRGB(38, 38, 44)
                        nextBtn.BackgroundColor3 = t.NeutralButton or Color3.fromRGB(38, 38, 44)

                        for _, entry in ipairs(swatches)do
                            entry.stroke.Color = t.SurfaceStroke or Color3.fromRGB(60, 60, 70)
                        end

                        setDotVisual(dot1, currentPage == 1, t)
                        setDotVisual(dot2, currentPage == 2, t)
                    end,
                })

                local self = setmetatable({}, ColorPicker)::ColorPicker

                self.value = initColor
                self.alpha = a
                self._frame = frame;
                (self::any)._flag = flagKey

                if flagKey and flagKey ~= '' then
                    flags:Set(flagKey, initColor)
                end

                function self:Set(
                    value: Color3,
                    newAlpha: number?,
                    skipCallback: boolean?
                )
                    if (self::any).locked and not skipCallback then
                        return
                    end

                    h, s, v = Color3.toHSV(value)

                    if newAlpha ~= nil then
                        a = clamp01(newAlpha)
                    end

                    self.value = value
                    self.alpha = a

                    refresh()

                    if not skipCallback then
                        fireChanged()
                    end
                end
                function self:_setShown(shown: boolean, animate: boolean?)
                    local t = theme or {}
                    local info = if animate ~= false then constants.tweenNormal else nil
                    local frameTrans = if shown then(t.ElementTransparency or 0)else 1
                    local strokeTrans = if shown then(t.ElementStrokeTransparency or 0)else 1
                    local textTrans = if shown then 0 else 1

                    if info then
                        tween.play(frame, info, {BackgroundTransparency = frameTrans})
                        tween.play(stroke, info, {Transparency = strokeTrans})
                        tween.play(headerTitle, info, {TextTransparency = textTrans})
                    else
                        frame.BackgroundTransparency = frameTrans
                        stroke.Transparency = strokeTrans
                        headerTitle.TextTransparency = textTrans
                    end
                end
                function self:Destroy()
                    stopColorDrag()

                    if themeUnsub then
                        themeUnsub()
                    end

                    for _, c in conns do
                        c:Disconnect()
                    end

                    table.clear(conns)

                    if windowMode then
                        popup:Destroy()

                        if dimOverlay then
                            dimOverlay:Destroy()
                        end
                    else
                        if gui then
                            (gui::ScreenGui):Destroy()
                        end
                    end

                    frame:Destroy()
                end

                snapTo(1, false)
                refresh()
                moveable(ColorPicker)
                lockable(ColorPicker)

                return self
            end

            return ColorPicker
        end)()
    end,
    [67] = function()
        local wax, script, require = ImportGlobals(67)
        local ImportGlobals

        return (function(...)
            local runtime = require(script.Parent.runtime)
            local constants = require(script.Parent.constants)

            export type VariablesState = typeof(runtime)&{activeTheme: {[string]: any}, isTouchOnly: boolean}

            local variables: VariablesState = table.clone(runtime)::any

            variables.activeTheme = {}::{[string]: any}
            variables.uiScale = 1
            variables.settingsOpen = false
            variables.settingsPanelInstance = nil

            return variables
        end)()
    end,
    [56] = function()
        local wax, script, require = ImportGlobals(56)
        local ImportGlobals

        return (function(...)
            local variables = require(script.Parent.variables)
            local tween = require(script.Parent.tween)
            local constants = require(script.Parent.constants)
            local tweenService = variables.tweenService
            local Odometer = {}

            Odometer.__index = Odometer

            export type Options = {textSize: number?, transparency: number?, duration: number?, alignment: Enum.HorizontalAlignment?, padding: number?, font: Font?, color: Color3?}
            type Cell = {frame: Frame, label: TextLabel, char: string}

            function Odometer.new(
                window: any,
                parent: Instance,
                opts: Options?
            ): any
                opts = opts or {}

                local self = setmetatable({}, Odometer)::any
                local textSize = opts.textSize or 22
                local transparency = opts.transparency or 0
                local duration = opts.duration or 0.45
                local alignment = opts.alignment or Enum.HorizontalAlignment.Right
                local padding = opts.padding or 0
                local font = opts.font or constants.DEFAULT_FONT_BOLD
                local color = opts.color or Color3.fromRGB(255, 255, 255)
                local container = Instance.new('Frame')

                container.Name = 'Odometer'
                container.Size = UDim2.new(1, 0, 0, textSize + 8)
                container.BackgroundTransparency = 1
                container.Parent = parent

                local layout = Instance.new('UIListLayout')

                layout.FillDirection = Enum.FillDirection.Horizontal
                layout.HorizontalAlignment = alignment
                layout.VerticalAlignment = Enum.VerticalAlignment.Center
                layout.Padding = UDim.new(0, padding)
                layout.SortOrder = Enum.SortOrder.LayoutOrder
                layout.Parent = container
                self._window = window
                self._container = container
                self._layout = layout
                self._cells = {}::{Cell}
                self._pool = {}::{Cell}
                self._duration = duration
                self._transparency = transparency
                self._textSize = textSize
                self._font = font
                self._color = color
                self._current = ''

                return self
            end

            local function acquireCell(self: any): Cell
                local pooled = table.remove(self._pool)

                if pooled then
                    pooled.frame.Visible = true

                    return pooled
                end

                local frame = Instance.new('Frame')

                frame.BackgroundTransparency = 1
                frame.AutomaticSize = Enum.AutomaticSize.X
                frame.Size = UDim2.new(0, 0, 1, 0)
                frame.Parent = self._container

                local label = Instance.new('TextLabel')

                label.BackgroundTransparency = 1
                label.AutomaticSize = Enum.AutomaticSize.X
                label.Size = UDim2.new(0, 0, 1, 0)
                label.FontFace = self._font
                label.TextSize = self._textSize
                label.TextColor3 = self._color
                label.TextTransparency = self._transparency
                label.Text = '0'
                label.Parent = frame

                return {
                    frame = frame,
                    label = label,
                    char = '0',
                }
            end
            local function releaseCell(self: any, cell: Cell)
                cell.frame.Visible = false

                table.insert(self._pool, cell)
            end

            function Odometer:snap(text: any)
                text = tostring(text)
                self._current = text

                local targetLen = utf8.len(text) or #text

                while#self._cells < targetLen do
                    local c = acquireCell(self)

                    table.insert(self._cells, c)
                end
                while#self._cells > targetLen do
                    local c = table.remove(self._cells)

                    if c then
                        releaseCell(self, c)
                    end
                end

                local idx = 1

                for c in text:gmatch('.')do
                    local cell = self._cells[idx]

                    if cell then
                        cell.label.Text = c
                        cell.label.TextTransparency = self._transparency
                        cell.char = c
                    end

                    idx += 1
                end
            end
            function Odometer:to(text: any, animate: boolean?)
                text = tostring(text)

                if not animate then
                    self:snap(text)

                    return
                end

                self._current = text

                local targetLen = utf8.len(text) or #text

                while#self._cells < targetLen do
                    local c = acquireCell(self)

                    table.insert(self._cells, c)
                end
                while#self._cells > targetLen do
                    local c = table.remove(self._cells)

                    if c then
                        releaseCell(self, c)
                    end
                end

                local idx = 1

                for c in text:gmatch('.')do
                    local cell = self._cells[idx]

                    if cell and cell.char ~= c then
                        cell.char = c
                        cell.label.Text = c

                        local start = cell.label.Position

                        cell.label.Position = UDim2.new(0, 0, 0, 10)
                        cell.label.TextTransparency = 1

                        tweenService:Create(cell.label, TweenInfo.new(self._duration, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {
                            Position = start,
                            TextTransparency = self._transparency,
                        }):Play()
                    end

                    idx += 1
                end
            end
            function Odometer:reveal(
                transparency: number,
                animate: boolean?,
                _roll: any?
            )
                local T = TweenInfo.new(if animate then 0.25 else 0, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

                for _, cell in self._cells do
                    if animate then
                        tweenService:Create(cell.label, T, {TextTransparency = transparency}):Play()
                    else
                        cell.label.TextTransparency = transparency
                    end
                end
            end
            function Odometer:Destroy()
                for _, c in self._cells do
                    if c.frame.Parent then
                        c.frame:Destroy()
                    end
                end
                for _, c in self._pool do
                    if c.frame.Parent then
                        c.frame:Destroy()
                    end
                end

                table.clear(self._cells)
                table.clear(self._pool)

                if self._container then
                    self._container:Destroy()
                end
            end

            return Odometer
        end)()
    end,
    [24] = function()
        local wax, script, require = ImportGlobals(24)
        local ImportGlobals

        return (function(...)
            local constants = require(script.Parent.Parent.utility.constants)
            local element = require(script.Parent.Parent.utility.element)
            local tween = require(script.Parent.Parent.utility.tween)
            local locale = require(script.Parent.Parent.utility.locale)
            local moveable = require(script.Parent.Parent.utility.moveable)

            export type TextProps = {name: string?, text: string?, icon: (string | number)?, richText: boolean?}
            export type Text = {_frame: Frame, value: string, Set: (self:Text, text:string) -> (), SetTitle: (self:Text, title:string) -> (), _setShown: (self:Text, shown:boolean, animate:boolean?) -> (), Destroy: (self:Text) -> ()}

            local Text = {}

            Text.__index = Text

            local TITLE_SIZE = 16
            local BODY_SIZE = 14
            local BODY_OPACITY = 0.45

            function Text.new(
                props: TextProps,
                theme: {[string]: any},
                parent: Instance
            ): Text
                local name = props.name or ''
                local body = props.text or ''
                local richText = props.richText ~= false
                local iconId = props.icon
                local frame = Instance.new('Frame')

                frame.Name = if name ~= ''then locale.t(name)else'Text'
                frame.Size = UDim2.new(1, 0, 0, 0)
                frame.AutomaticSize = Enum.AutomaticSize.Y
                frame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                frame.BackgroundTransparency = theme.ElementTransparency or 0
                frame.BorderSizePixel = 0
                frame.Parent = parent

                local corner = Instance.new('UICorner')

                corner.CornerRadius = theme.ElementCornerRadius or UDim.new(0, 10)
                corner.Parent = frame

                local stroke = Instance.new('UIStroke')

                stroke.Color = theme.ElementStroke or Color3.fromRGB(55, 55, 60)
                stroke.Transparency = theme.ElementStrokeTransparency or 0.6
                stroke.Thickness = 1
                stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                stroke.Parent = frame

                local padding = Instance.new('UIPadding')

                padding.PaddingTop = UDim.new(0, 14)
                padding.PaddingBottom = UDim.new(0, 14)
                padding.PaddingLeft = UDim.new(0, 20)
                padding.PaddingRight = UDim.new(0, 20)
                padding.Parent = frame

                local list = Instance.new('UIListLayout')

                list.Padding = UDim.new(0, 6)
                list.SortOrder = Enum.SortOrder.LayoutOrder
                list.Parent = frame

                local titleRow = Instance.new('Frame')

                titleRow.Name = 'TitleRow'
                titleRow.Size = UDim2.new(1, 0, 0, 0)
                titleRow.AutomaticSize = Enum.AutomaticSize.Y
                titleRow.BackgroundTransparency = 1
                titleRow.BorderSizePixel = 0
                titleRow.LayoutOrder = 1
                titleRow.Visible = name ~= '' or iconId ~= nil
                titleRow.Parent = frame

                local titleRowList = Instance.new('UIListLayout')

                titleRowList.FillDirection = Enum.FillDirection.Horizontal
                titleRowList.Padding = UDim.new(0, 6)
                titleRowList.SortOrder = Enum.SortOrder.LayoutOrder
                titleRowList.VerticalAlignment = Enum.VerticalAlignment.Center
                titleRowList.Parent = titleRow

                local iconLabel: ImageLabel? = nil

                if iconId then
                    local img = Instance.new('ImageLabel')

                    img.Name = 'Icon'
                    img.Size = UDim2.fromOffset(16, 16)
                    img.BackgroundTransparency = 1
                    img.BorderSizePixel = 0
                    img.Image = 'rbxassetid://' .. tostring(iconId)
                    img.ImageColor3 = theme.ContentColor or Color3.fromRGB(220, 215, 240)
                    img.LayoutOrder = 0
                    img.Parent = titleRow
                    iconLabel = img
                end

                local titleLabel = Instance.new('TextLabel')

                titleLabel.Name = 'Title'
                titleLabel.Size = UDim2.new(1, if iconId then-22 else 0, 0, 0)
                titleLabel.AutomaticSize = Enum.AutomaticSize.Y
                titleLabel.BackgroundTransparency = 1
                titleLabel.BorderSizePixel = 0
                titleLabel.Text = locale.t(name)
                titleLabel.RichText = richText
                titleLabel.TextColor3 = theme.TitlingColor or Color3.fromRGB(255, 255, 255)
                titleLabel.TextSize = TITLE_SIZE
                titleLabel.FontFace = theme.TitleFont or constants.DEFAULT_FONT_SEMI
                titleLabel.TextWrapped = true
                titleLabel.TextXAlignment = Enum.TextXAlignment.Left
                titleLabel.LayoutOrder = 1
                titleLabel.Parent = titleRow

                local bodyLabel = Instance.new('TextLabel')

                bodyLabel.Name = 'Body'
                bodyLabel.Size = UDim2.new(1, 0, 0, 0)
                bodyLabel.AutomaticSize = Enum.AutomaticSize.Y
                bodyLabel.BackgroundTransparency = 1
                bodyLabel.BorderSizePixel = 0
                bodyLabel.Text = locale.t(body)
                bodyLabel.RichText = richText
                bodyLabel.TextColor3 = theme.ContentColor or Color3.fromRGB(200, 200, 220)
                bodyLabel.TextTransparency = BODY_OPACITY
                bodyLabel.TextSize = BODY_SIZE
                bodyLabel.FontFace = theme.Font or constants.DEFAULT_FONT
                bodyLabel.TextWrapped = true
                bodyLabel.TextXAlignment = Enum.TextXAlignment.Left
                bodyLabel.LayoutOrder = 2
                bodyLabel.Visible = body ~= ''
                bodyLabel.Parent = frame

                local self = setmetatable({}, Text)::Text

                self._frame = frame
                self.value = body

                local s = self::any

                s._stroke = stroke
                s._titleRow = titleRow
                s._titleLabel = titleLabel
                s._bodyLabel = bodyLabel
                s._iconLabel = iconLabel
                s._bodyOpacity = BODY_OPACITY
                s._richText = richText
                s._theme = theme
                s._themeUnsub = element.subscribeTheme(frame, {
                    frame = frame,
                    stroke = stroke,
                    extra = function(t)
                        s._theme = t
                        titleLabel.TextColor3 = t.TitlingColor or Color3.fromRGB(255, 255, 255)
                        titleLabel.FontFace = t.TitleFont or constants.DEFAULT_FONT_SEMI
                        bodyLabel.TextColor3 = t.ContentColor or Color3.fromRGB(200, 200, 220)
                        bodyLabel.FontFace = t.Font or constants.DEFAULT_FONT

                        if iconLabel then
                            iconLabel.ImageColor3 = t.ContentColor or Color3.fromRGB(220, 215, 240)
                        end
                    end,
                })

                moveable(Text)

                return self
            end
            function Text:Set(text: string)
                local s = self::any
                local body = tostring(text)

                self.value = body
                s._bodyLabel.Text = locale.t(body)
                s._bodyLabel.Visible = body ~= ''
            end
            function Text:SetTitle(title: string)
                local s = self::any
                local name = tostring(title)

                s._titleLabel.Text = locale.t(name)
                s._titleRow.Visible = name ~= '' or s._iconLabel ~= nil
            end
            function Text:_setShown(shown: boolean, animate: boolean?)
                local s = self::any
                local t = s._theme or {}
                local info = if animate ~= false then constants.tweenNormal else nil
                local frameTrans = if shown then(t.ElementTransparency or 0)else 1
                local strokeTrans = if shown then(t.ElementStrokeTransparency or 0)else 1
                local titleTrans = if shown then 0 else 1
                local bodyTrans = if shown then(s._bodyOpacity or 0.45)else 1

                if info then
                    tween.play(self._frame, info, {BackgroundTransparency = frameTrans})

                    if s._stroke then
                        tween.play(s._stroke, info, {Transparency = strokeTrans})
                    end
                    if s._titleLabel then
                        tween.play(s._titleLabel, info, {TextTransparency = titleTrans})
                    end
                    if s._bodyLabel then
                        tween.play(s._bodyLabel, info, {TextTransparency = bodyTrans})
                    end
                    if s._iconLabel then
                        tween.play(s._iconLabel, info, {ImageTransparency = titleTrans})
                    end
                else
                    self._frame.BackgroundTransparency = frameTrans

                    if s._stroke then
                        s._stroke.Transparency = strokeTrans
                    end
                    if s._titleLabel then
                        s._titleLabel.TextTransparency = titleTrans
                    end
                    if s._bodyLabel then
                        s._bodyLabel.TextTransparency = bodyTrans
                    end
                    if s._iconLabel then
                        s._iconLabel.ImageTransparency = titleTrans
                    end
                end
            end
            function Text:Destroy()
                local s = self::any

                if s._themeUnsub then
                    s._themeUnsub()
                end

                self._frame:Destroy()
            end

            return Text
        end)()
    end,
    [68] = function()
        local wax, script, require = ImportGlobals(68)
        local ImportGlobals

        return (function(...)
            local constants = require(script.Parent.constants)
            local windowSizing = {}
            local defaultSize = constants.windowSize
            local minSize = constants.windowMinSize
            local maxOccupancyX, maxOccupancyY = 0.86, 0.8
            local marginFloorX, marginFloorY = 20, 24
            local widthCompensation = 60
            local maxAspectRatio = 1.8
            local minPlausibleViewport = 200
            local REFERENCE = Vector2.new(1366, 768)

            windowSizing.defaultSize = defaultSize
            windowSizing.minSize = minSize

            local function heightDeficit(height: number): number
                return math.clamp((defaultSize.Y - height) / (defaultSize.Y - minSize.Y), 0, 1)
            end

            function windowSizing.fit(viewport: Vector2?): UDim2
                if not viewport or viewport.X < minPlausibleViewport or viewport.Y < minPlausibleViewport then
                    return UDim2.fromOffset(defaultSize.X, defaultSize.Y)
                end

                local availableX = math.min(viewport.X * maxOccupancyX, viewport.X - marginFloorX)
                local availableY = math.min(viewport.Y * maxOccupancyY, viewport.Y - marginFloorY)
                local height = math.floor(math.min(availableY, defaultSize.Y))
                local deficit = heightDeficit(height)
                local width = math.max(defaultSize.X + widthCompensation * deficit, minSize.X)

                width = math.floor(math.min(width, availableX, height * maxAspectRatio))

                return UDim2.fromOffset(width, height)
            end
            function windowSizing.computeScale(viewport: Vector2?): number
                if not viewport or viewport.X < minPlausibleViewport or viewport.Y < minPlausibleViewport then
                    return 1
                end

                local scaleX = viewport.X / REFERENCE.X
                local scaleY = viewport.Y / REFERENCE.Y

                return math.clamp(math.min(scaleX, scaleY), 0.45, 1)
            end

            return windowSizing
        end)()
    end,
    [19] = function()
        local wax, script, require = ImportGlobals(19)
        local ImportGlobals

        return (function(...)
            local constants = require(script.Parent.Parent.utility.constants)
            local themeUtil = require(script.Parent.Parent.utility.theme)
            local tween = require(script.Parent.Parent.utility.tween)
            local icons = require(script.Parent.Parent.utility.icons)
            local variables = require(script.Parent.Parent.utility.variables)
            local Label = require(script.Parent.label)
            local Button = require(script.Parent.button)
            local Toggle = require(script.Parent.toggle)
            local Slider = require(script.Parent.slider)
            local Input = require(script.Parent.input)
            local Keybind = require(script.Parent.keybind)
            local Dropdown = require(script.Parent.dropdown)
            local ColorPicker = require(script.Parent.colorpicker)
            local TextComp = require(script.Parent.text)
            local Divider = require(script.Parent.divider)
            local Progress = require(script.Parent.progress)
            local Stat = require(script.Parent.stat)
            local Console = require(script.Parent.console)
            local Group = require(script.Parent.group)
            local COMPACT_THRESHOLD = 380

            export type SectionProps = {name: string?, icon: (string | number)?, description: string?, defaultOpen: boolean?, opened: boolean?, closed: boolean?, compact: boolean?, variant: string?}
            export type Section = {_frame: Frame, _content: Frame, _open: boolean, SetText: (self:Section, text:string) -> (), Set: (self:Section, text:string) -> (), SetOpen: (self:Section, open:boolean) -> (), Toggle: (self:Section) -> (), Collapse: (self:Section) -> (), Expand: (self:Section) -> (), CreateSection: (self:Section, props:SectionProps) -> Section, CreateLabel: (self:Section, props:Label.LabelProps) -> Label.Label, CreateButton: (self:Section, props:Button.ButtonProps) -> Button.Button, CreateToggle: (self:Section, props:Toggle.ToggleProps) -> Toggle.Toggle, CreateSlider: (self:Section, props:Slider.SliderProps) -> Slider.Slider, AddSlider: (self:Section, props:Slider.SliderProps) -> Slider.Slider, CreateInput: (self:Section, props:Input.InputProps) -> Input.Input, CreateKeybind: (self:Section, props:Keybind.KeybindProps) -> Keybind.Keybind, CreateDropdown: (self:Section, props:Dropdown.DropdownProps) -> Dropdown.Dropdown, AddDropdown: (self:Section, props:Dropdown.DropdownProps) -> Dropdown.Dropdown, CreateColorPicker: (self:Section, props:ColorPicker.ColorPickerProps) -> ColorPicker.ColorPicker, Destroy: (self:Section) -> ()}

            local Section = {}

            Section.__index = Section

            function Section.new(
                props: SectionProps,
                theme: {[string]: any},
                parent: Instance,
                tab: any?
            ): Section
                local name = props.name or 'Section'
                local iconName = props.icon
                local descriptionText = props.description
                local defaultOpen = true

                if props.closed == true then
                    defaultOpen = false
                elseif props.opened ~= nil then
                    defaultOpen = props.opened
                elseif props.defaultOpen ~= nil then
                    defaultOpen = props.defaultOpen
                end

                local manualCompact: boolean? = nil

                if props.compact ~= nil then
                    manualCompact = props.compact
                elseif props.variant == 'compact' then
                    manualCompact = true
                elseif props.variant == 'default' then
                    manualCompact = false
                end

                local isCompact: boolean = manualCompact == true
                local box = Instance.new('Frame')

                box.Name = 'Section_' .. name
                box.Size = UDim2.new(1, 0, 0, 0)
                box.AutomaticSize = Enum.AutomaticSize.Y
                box.BackgroundColor3 = theme.NeutralButton or Color3.fromHex('#1e1e1e')
                box.BackgroundTransparency = theme.ElementTransparency or 0
                box.BorderSizePixel = 0
                box.ClipsDescendants = false
                box.LayoutOrder = 0
                box.Parent = parent

                local corner = Instance.new('UICorner')

                corner.CornerRadius = theme.ElementCornerRadius or constants.elementCornerRadius
                corner.Parent = box

                local stroke = Instance.new('UIStroke')

                stroke.Color = theme.ElementStroke or Color3.fromHex('#2b2b2b')
                stroke.Thickness = 1
                stroke.Transparency = theme.ElementStrokeTransparency or 0
                stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                stroke.Parent = box

                local boxLayout = Instance.new('UIListLayout')

                boxLayout.FillDirection = Enum.FillDirection.Vertical
                boxLayout.SortOrder = Enum.SortOrder.LayoutOrder
                boxLayout.Padding = UDim.new(0, 0)
                boxLayout.Parent = box

                local hasDesc = descriptionText ~= nil and descriptionText ~= ''
                local header = Instance.new('TextButton')

                header.Name = 'Header'
                header.Size = UDim2.new(1, 0, 0, 36)
                header.BackgroundTransparency = 1
                header.BackgroundColor3 = theme.NeutralButtonHover or Color3.fromHex('#252525')
                header.BorderSizePixel = 0
                header.AutoButtonColor = false
                header.Text = ''
                header.LayoutOrder = 1
                header.ZIndex = 2
                header.Parent = box

                local headerCorner = Instance.new('UICorner')

                headerCorner.CornerRadius = theme.ElementCornerRadius or constants.elementCornerRadius
                headerCorner.Parent = header

                local iconBadge: Frame? = nil
                local iconLabel: ImageLabel? = nil
                local iconBadgeCorner: UICorner? = nil
                local BADGE_SIZE = 28
                local BADGE_R = 7
                local BADGE_GAP = 10
                local leftOffset = 12

                if iconName and iconName ~= '' then
                    local resolvedIcon = icons.Resolve(iconName)

                    if resolvedIcon and resolvedIcon ~= '' then
                        local badge = Instance.new('Frame')

                        badge.Name = 'IconBadge'
                        badge.AnchorPoint = Vector2.new(0, 0.5)
                        badge.Position = UDim2.new(0, leftOffset, 0.5, 0)
                        badge.Size = UDim2.fromOffset(BADGE_SIZE, BADGE_SIZE)
                        badge.BackgroundColor3 = theme.AccentColor or Color3.fromHex('#4cc2ff')
                        badge.BackgroundTransparency = 0.82
                        badge.BorderSizePixel = 0
                        badge.Parent = header

                        local bc = Instance.new('UICorner')

                        bc.CornerRadius = UDim.new(0, BADGE_R)
                        bc.Parent = badge
                        iconBadgeCorner = bc
                        iconBadge = badge

                        local img = Instance.new('ImageLabel')

                        img.Name = 'Icon'
                        img.AnchorPoint = Vector2.new(0.5, 0.5)
                        img.Position = UDim2.fromScale(0.5, 0.5)
                        img.Size = UDim2.fromOffset(15, 15)
                        img.BackgroundTransparency = 1
                        img.Image = resolvedIcon
                        img.ImageColor3 = theme.AccentColor or Color3.fromHex('#4cc2ff')
                        img.Parent = badge
                        iconLabel = img

                        leftOffset += BADGE_SIZE + BADGE_GAP
                    end
                end

                local textsFrame = Instance.new('Frame')

                textsFrame.Name = 'Texts'
                textsFrame.AnchorPoint = Vector2.new(0, 0.5)
                textsFrame.Position = UDim2.new(0, leftOffset, 0.5, 0)
                textsFrame.Size = UDim2.new(1, -(leftOffset + 32), 1, -4)
                textsFrame.BackgroundTransparency = 1
                textsFrame.BorderSizePixel = 0
                textsFrame.Parent = header

                local textsLayout = Instance.new('UIListLayout')

                textsLayout.FillDirection = Enum.FillDirection.Vertical
                textsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
                textsLayout.Padding = UDim.new(0, 1)
                textsLayout.SortOrder = Enum.SortOrder.LayoutOrder
                textsLayout.Parent = textsFrame

                local label = Instance.new('TextLabel')

                label.Name = 'Title'
                label.Size = UDim2.new(1, 0, 0, 16)
                label.BackgroundTransparency = 1
                label.Text = name
                label.TextColor3 = theme.TitlingColor or Color3.fromHex('#ffffff')
                label.TextSize = 13
                label.FontFace = theme.TitleFont or constants.DEFAULT_FONT_MEDIUM
                label.TextXAlignment = Enum.TextXAlignment.Left
                label.TextTruncate = Enum.TextTruncate.AtEnd
                label.LayoutOrder = 1
                label.Parent = textsFrame

                local descLabel: TextLabel? = nil

                if hasDesc then
                    descLabel = Instance.new('TextLabel')
                    descLabel.Name = 'Description'
                    descLabel.Size = UDim2.new(1, 0, 0, 14)
                    descLabel.BackgroundTransparency = 1
                    descLabel.Text = descriptionText::string
                    descLabel.TextColor3 = theme.PlaceholderColor or Color3.fromHex('#8c8c96')
                    descLabel.TextSize = 11
                    descLabel.FontFace = theme.Font or constants.DEFAULT_FONT
                    descLabel.TextXAlignment = Enum.TextXAlignment.Left
                    descLabel.TextTruncate = Enum.TextTruncate.AtEnd
                    descLabel.LayoutOrder = 2
                    descLabel.Parent = textsFrame
                end

                local chevron = Instance.new('ImageLabel')

                chevron.Name = 'Chevron'
                chevron.AnchorPoint = Vector2.new(1, 0.5)
                chevron.Position = UDim2.new(1, -12, 0.5, 0)
                chevron.Size = UDim2.fromOffset(14, 14)
                chevron.BackgroundTransparency = 1
                chevron.Image = icons.Resolve('chevron-down')
                chevron.ImageColor3 = theme.PlaceholderColor or Color3.fromHex('#8c8c96')
                chevron.Rotation = if defaultOpen then 0 else-90
                chevron.Parent = header

                local divider = Instance.new('Frame')

                divider.Name = 'Divider'
                divider.Size = UDim2.new(1, 0, 0, 1)
                divider.Position = UDim2.new(0, 0, 1, -1)
                divider.AnchorPoint = Vector2.new(0, 1)
                divider.BackgroundColor3 = theme.ElementStroke or Color3.fromHex('#2b2b2b')
                divider.BackgroundTransparency = theme.ElementStrokeTransparency or 0.6
                divider.BorderSizePixel = 0
                divider.Visible = defaultOpen
                divider.LayoutOrder = 2
                divider.Parent = box

                local content = Instance.new('Frame')

                content.Name = 'Content'
                content.Size = UDim2.new(1, 0, 0, 0)
                content.AutomaticSize = if defaultOpen then Enum.AutomaticSize.Y else Enum.AutomaticSize.None
                content.BackgroundTransparency = 1
                content.BorderSizePixel = 0
                content.ClipsDescendants = true
                content.Visible = true
                content.LayoutOrder = 3
                content.Parent = box

                local contentLayout = Instance.new('UIListLayout')

                contentLayout.FillDirection = Enum.FillDirection.Vertical
                contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
                contentLayout.Padding = UDim.new(0, constants.elementPadding)
                contentLayout.Parent = content

                local function forceAncestorScrollReflow(start: Instance?)
                    local node: Instance? = start

                    while node ~= nil do
                        if node:IsA('ScrollingFrame') then
                            local sf = node::ScrollingFrame
                            local auto = sf.AutomaticCanvasSize

                            if auto ~= Enum.AutomaticSize.None then
                                sf.AutomaticCanvasSize = Enum.AutomaticSize.None

                                task.defer(function()
                                    if sf.Parent then
                                        sf.AutomaticCanvasSize = auto
                                    end
                                end)
                            end

                            return
                        end

                        node = node.Parent
                    end
                end

                local contentPad = Instance.new('UIPadding')

                contentPad.PaddingLeft = UDim.new(0, 8)
                contentPad.PaddingRight = UDim.new(0, 8)
                contentPad.PaddingTop = UDim.new(0, constants.elementPadding)
                contentPad.PaddingBottom = UDim.new(0, constants.elementPadding)
                contentPad.Parent = content

                if not variables.isTouchOnly then
                    header.MouseEnter:Connect(function()
                        header.BackgroundTransparency = 0.95
                    end)
                    header.MouseLeave:Connect(function()
                        header.BackgroundTransparency = 1
                    end)
                end

                local self = setmetatable({}, Section)::Section

                self._frame = box
                self._content = content
                self._open = defaultOpen

                local s = self::any

                s._label = label
                s._descLabel = descLabel
                s._iconLabel = iconLabel
                s._iconBadge = iconBadge
                s._iconBadgeCorner = iconBadgeCorner
                s._forceAncestorScrollReflow = forceAncestorScrollReflow
                s._box = box
                s._stroke = stroke
                s._chevron = chevron
                s._divider = divider
                s._header = header
                s._headerCorner = headerCorner
                s._contentPad = contentPad
                s._contentLayout = contentLayout
                s._tab = tab
                s._theme = theme
                s._elements = {}
                s._manualCompact = manualCompact
                s._isCompact = isCompact

                local function applyDensity()
                    local compact = s._isCompact
                    local headerH = if compact then(hasDesc and 40 or 32)else(hasDesc and 44 or 36)

                    header.Size = UDim2.new(1, 0, 0, headerH)

                    if iconBadge and iconLabel then
                        local bs = if compact then 24 else 28
                        local br = if compact then 6 else 7
                        local is = if compact then 13 else 15

                        iconBadge.Size = UDim2.fromOffset(bs, bs)
                        iconLabel.Size = UDim2.fromOffset(is, is)

                        if iconBadgeCorner then
                            iconBadgeCorner.CornerRadius = UDim.new(0, br)
                        end

                        local newLeft = 12 + bs + BADGE_GAP

                        textsFrame.Position = UDim2.new(0, newLeft, 0.5, 0)
                        textsFrame.Size = UDim2.new(1, -(newLeft + 32), 1, -4)
                    end

                    label.TextSize = if compact then 12 else 13

                    if descLabel then
                        descLabel.TextSize = if compact then 10 else 11
                    end

                    contentPad.PaddingLeft = UDim.new(0, if compact then 6 else 8)
                    contentPad.PaddingRight = UDim.new(0, if compact then 6 else 8)
                    contentPad.PaddingTop = UDim.new(0, if compact then 5 else constants.elementPadding)
                    contentPad.PaddingBottom = UDim.new(0, if compact then 5 else constants.elementPadding)
                    contentLayout.Padding = UDim.new(0, if compact then 5 else constants.elementPadding)

                    local liveTheme = s._theme or theme
                    local cr = liveTheme.ElementCornerRadius or constants.elementCornerRadius

                    if compact then
                        corner.CornerRadius = UDim.new(0, math.max(4, (cr.Offset or 6) - 1))
                        headerCorner.CornerRadius = corner.CornerRadius
                    else
                        corner.CornerRadius = cr
                        headerCorner.CornerRadius = cr
                    end
                end

                s._applyDensity = applyDensity

                applyDensity()

                if manualCompact == nil then
                    local lastCompactState = isCompact

                    box:GetPropertyChangedSignal('AbsoluteSize'):Connect(function(
                    )
                        local w = box.AbsoluteSize.X

                        if w <= 0 then
                            return
                        end

                        local shouldCompact = w < COMPACT_THRESHOLD

                        if shouldCompact ~= lastCompactState then
                            lastCompactState = shouldCompact
                            s._isCompact = shouldCompact

                            applyDensity()
                        end
                    end)
                end

                header.Activated:Connect(function()
                    self:Toggle()
                end)

                s._themeUnsub = themeUtil.subscribe(function(t)
                    s._theme = t
                    box.BackgroundColor3 = t.NeutralButton or Color3.fromHex('#1e1e1e')
                    box.BackgroundTransparency = t.ElementTransparency or 0
                    stroke.Color = t.ElementStroke or Color3.fromHex('#2b2b2b')
                    stroke.Transparency = t.ElementStrokeTransparency or 0
                    label.TextColor3 = t.TitlingColor or Color3.fromHex('#ffffff')
                    label.FontFace = t.TitleFont or constants.DEFAULT_FONT_MEDIUM
                    chevron.ImageColor3 = t.PlaceholderColor or Color3.fromHex('#8c8c96')
                    divider.BackgroundColor3 = t.ElementStroke or Color3.fromHex('#2b2b2b')

                    if descLabel then
                        descLabel.TextColor3 = t.PlaceholderColor or Color3.fromHex('#8c8c96')
                        descLabel.FontFace = t.Font or constants.DEFAULT_FONT
                    end
                    if iconBadge then
                        iconBadge.BackgroundColor3 = t.AccentColor or Color3.fromHex('#4cc2ff')
                    end
                    if iconLabel then
                        iconLabel.ImageColor3 = t.AccentColor or Color3.fromHex('#4cc2ff')
                    end

                    applyDensity()
                end, box)

                return self
            end
            function Section:SetText(text: string)
                local s = self::any

                if s._label then
                    s._label.Text = text
                end
            end
            function Section:Set(text: string)
                self:SetText(text)
            end
            function Section:SetOpen(open: boolean)
                local s = self::any

                if s._open == open then
                    return
                end

                s._open = open
                self._open = open

                tween.fire(s._chevron, constants.tweenFast, {
                    Rotation = if open then 0 else-90,
                })

                s._divider.Visible = open

                local content = s._content

                if not content then
                    return
                end
                if open then
                    do
                        local node: Instance? = s._box.Parent

                        while node ~= nil do
                            if node:IsA('ScrollingFrame') then
                                local sf = node::ScrollingFrame

                                if sf.AutomaticCanvasSize ~= Enum.AutomaticSize.None then
                                    local bufferH = sf.AbsoluteCanvasSize.Y + 4000

                                    sf.CanvasSize = UDim2.fromOffset(0, bufferH)

                                    task.defer(function()
                                        if sf.Parent then
                                            sf.CanvasSize = UDim2.fromOffset(0, 0)
                                        end
                                    end)
                                end

                                break
                            end

                            node = node.Parent
                        end
                    end

                    content.ClipsDescendants = false
                    content.Size = UDim2.new(1, 0, 0, 0)
                    content.AutomaticSize = Enum.AutomaticSize.Y

                    task.defer(function()
                        if content.Parent then
                            content.ClipsDescendants = true
                        end
                    end)
                else
                    content.ClipsDescendants = true
                    content.AutomaticSize = Enum.AutomaticSize.None
                    content.Size = UDim2.new(1, 0, 0, 0)

                    if s._forceAncestorScrollReflow then
                        task.defer(function()
                            s._forceAncestorScrollReflow(s._box)
                        end)
                        task.defer(function()
                            task.defer(function()
                                s._forceAncestorScrollReflow(s._box)
                            end)
                        end)
                    end
                end
            end
            function Section:Toggle()
                self:SetOpen(not self._open)
            end
            function Section:Expand()
                self:SetOpen(true)
            end
            function Section:Collapse()
                self:SetOpen(false)
            end
            function Section:_create(module: any, props: any): any
                local s = self::any

                if s._tab and typeof(s._tab._createOn) == 'function' then
                    return s._tab:_createOn(self._content, module, props)
                else
                    local el = module.new(props, s._theme, self._content)
                    local eAny = el::any

                    eAny.tab = s._tab
                    eAny.window = if s._tab then(s._tab::any)._window else nil

                    table.insert(s._elements, el)

                    return el
                end
            end
            function Section:CreateLabel(props: Label.LabelProps): Label.Label
                return self:_create(Label, props)
            end
            function Section:CreateButton(props: Button.ButtonProps): Button.Button
                return self:_create(Button, props)
            end
            function Section:CreateToggle(props: Toggle.ToggleProps): Toggle.Toggle
                return self:_create(Toggle, props)
            end
            function Section:CreateSlider(props: Slider.SliderProps): Slider.Slider
                return self:_create(Slider, props)
            end
            function Section:AddSlider(props: Slider.SliderProps): Slider.Slider
                return self:CreateSlider(props)
            end
            function Section:CreateInput(props: Input.InputProps): Input.Input
                return self:_create(Input, props)
            end
            function Section:CreateKeybind(props: Keybind.KeybindProps): Keybind.Keybind
                return self:_create(Keybind, props)
            end
            function Section:CreateDropdown(props: Dropdown.DropdownProps): Dropdown.Dropdown
                return self:_create(Dropdown, props)
            end
            function Section:AddDropdown(props: Dropdown.DropdownProps): Dropdown.Dropdown
                return self:CreateDropdown(props)
            end
            function Section:CreateColorPicker(props: ColorPicker.ColorPickerProps): ColorPicker.ColorPicker
                local s = self::any

                if s._tab and typeof(s._tab._createColorPickerOn) == 'function' then
                    return s._tab:_createColorPickerOn(self._content, props)
                else
                    local cp = ColorPicker.new(props, s._theme, self._content)
                    local cpAny = cp::any

                    cpAny.tab = s._tab
                    cpAny.window = if s._tab then(s._tab::any)._window else nil

                    table.insert(s._elements, cp)

                    return cp
                end
            end
            function Section:CreateSection(props: SectionProps): Section
                local s = self::any

                return Section.new(props, s._theme, s._content, s._tab)
            end
            function Section:CreateText(props: any): any
                return self:_create(TextComp, props)
            end
            function Section:CreateDivider(props: any): any
                return self:_create(Divider, props)
            end
            function Section:CreateProgress(props: any): any
                return self:_create(Progress, props)
            end
            function Section:CreateStat(props: any): any
                return self:_create(Stat, props)
            end
            function Section:CreateConsole(props: any): any
                return self:_create(Console, props)
            end
            function Section:CreateGroup(props: any): any
                local s = self::any

                if s._tab and typeof(s._tab._createGroupOn) == 'function' then
                    return s._tab:_createGroupOn(self._content, props)
                else
                    local g = Group.new(s._tab, props)
                    local gAny = g::any

                    gAny.tab = s._tab
                    gAny.window = if s._tab then(s._tab::any)._window else nil

                    table.insert(s._elements, g)

                    return g
                end
            end
            function Section:_setShown(shown: boolean, animate: boolean?)
                local s = self::any
                local t = s._theme or {}
                local info = if animate ~= false then constants.tweenNormal else nil
                local frameTrans = if shown then(t.ElementTransparency or 0)else 1
                local strokeTrans = if shown then(t.ElementStrokeTransparency or 0)else 1
                local textTrans = if shown then 0 else 1

                if info then
                    if s._box then
                        tween.play(s._box, info, {BackgroundTransparency = frameTrans})
                    end
                    if s._stroke then
                        tween.play(s._stroke, info, {Transparency = strokeTrans})
                    end
                    if s._label then
                        tween.play(s._label, info, {TextTransparency = textTrans})
                    end
                    if s._descLabel then
                        tween.play(s._descLabel, info, {TextTransparency = textTrans})
                    end
                    if s._chevron then
                        tween.play(s._chevron, info, {ImageTransparency = textTrans})
                    end
                    if s._iconLabel then
                        tween.play(s._iconLabel, info, {ImageTransparency = textTrans})
                    end
                    if s._divider then
                        tween.play(s._divider, info, {
                            BackgroundTransparency = if shown then(t.ElementStrokeTransparency or 0.6)else 1,
                        })
                    end
                else
                    if s._box then
                        s._box.BackgroundTransparency = frameTrans
                    end
                    if s._stroke then
                        s._stroke.Transparency = strokeTrans
                    end
                    if s._label then
                        s._label.TextTransparency = textTrans
                    end
                    if s._descLabel then
                        s._descLabel.TextTransparency = textTrans
                    end
                    if s._chevron then
                        s._chevron.ImageTransparency = textTrans
                    end
                    if s._iconLabel then
                        s._iconLabel.ImageTransparency = textTrans
                    end
                    if s._divider then
                        s._divider.BackgroundTransparency = if shown then(t.ElementStrokeTransparency or 0.6)else 1
                    end
                end
            end
            function Section:Destroy()
                local s = self::any

                if s._themeUnsub then
                    s._themeUnsub()
                end

                for _, el in s._elements do
                    if el and typeof(el.Destroy) == 'function' then
                        pcall(function()
                            el:Destroy()
                        end)
                    end
                end

                self._frame:Destroy()
            end

            return Section
        end)()
    end,
    [62] = function()
        local wax, script, require = ImportGlobals(62)
        local ImportGlobals

        return (function(...)
            export type Connection = {Connected: boolean, Disconnect: (self:Connection) -> ()}
            export type Signal<T...> = {Connect: (self:Signal<T...>, fn:(T...) -> ()) -> Connection, Once: (self:Signal<T...>, fn:(T...) -> ()) -> Connection, Fire: (self:Signal<T...>, T...) -> (), DisconnectAll: (self:Signal<T...>) -> (), Destroy: (self:Signal<T...>) -> ()}

            local Signal = {}

            Signal.__index = Signal

            type Entry = {fn: (...any) -> (), once: boolean}
            type InternalSignal = {_listeners: {Entry}, _destroyed: boolean}

            local function makeConnection(sig: InternalSignal, entry: Entry): Connection
                local conn: {[string]: any} = {Connected = true}

                conn.Disconnect = function(c: {[string]: any})
                    if not c.Connected then
                        return
                    end

                    c.Connected = false

                    local listeners = sig._listeners

                    for i = #listeners, 1, -1 do
                        if listeners[i] == entry then
                            table.remove(listeners, i)

                            break
                        end
                    end
                end

                return conn::any
            end

            function Signal.new<T...>(): Signal<T...>
                local self: InternalSignal = {
                    _listeners = {},
                    _destroyed = false,
                }

                return setmetatable(self, Signal)::any
            end
            function Signal:Connect(fn: (...any) -> ()): Connection
                assert(not self._destroyed, 'Signal:Connect called on a destroyed signal')

                local entry: Entry = {
                    fn = fn,
                    once = false,
                }

                table.insert(self._listeners, entry)

                return makeConnection(self, entry)
            end
            function Signal:Once(fn: (...any) -> ()): Connection
                assert(not self._destroyed, 'Signal:Once called on a destroyed signal')

                local entry: Entry = {
                    fn = fn,
                    once = true,
                }

                table.insert(self._listeners, entry)

                return makeConnection(self, entry)
            end
            function Signal:Fire(...: any)
                if self._destroyed then
                    return
                end

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
            function Signal:DisconnectAll()
                table.clear(self._listeners)
            end
            function Signal:Destroy()
                self._destroyed = true

                table.clear(self._listeners)
            end

            return Signal
        end)()
    end,
    [22] = function()
        local wax, script, require = ImportGlobals(22)
        local ImportGlobals

        return (function(...)
            local constants = require(script.Parent.Parent.utility.constants)
            local themeUtil = require(script.Parent.Parent.utility.theme)
            local tween = require(script.Parent.Parent.utility.tween)
            local saveManager = require(script.Parent.Parent.utility.saveManager)
            local assignOrder = require(script.Parent.Parent.utility.ordering)
            local hapticEngine = require(script.Parent.Parent.utility.HapticEngine)
            local Section = require(script.Parent.section)
            local Label = require(script.Parent.label)
            local Button = require(script.Parent.button)
            local Toggle = require(script.Parent.toggle)
            local Slider = require(script.Parent.slider)
            local Input = require(script.Parent.input)
            local Keybind = require(script.Parent.keybind)
            local Dropdown = require(script.Parent.dropdown)
            local ColorPicker = require(script.Parent.colorpicker)
            local Descriptor = require(script.Parent.descriptor)
            local TextComp = require(script.Parent.text)
            local Divider = require(script.Parent.divider)
            local Progress = require(script.Parent.progress)
            local Stat = require(script.Parent.stat)
            local Console = require(script.Parent.console)
            local Group = require(script.Parent.group)
            local icons = require(script.Parent.Parent.utility.icons)
            local variables = require(script.Parent.Parent.utility.variables)
            local DEFAULT_FONT_BOLD = constants.DEFAULT_FONT_BOLD
            local OVERLAY_Y_OFFSET = 45

            export type TabProps = {name: string?, icon: (string | number)?, badge: string?, columns: number?, neglectSelector: boolean?, forgetState: boolean?}
            export type TabColumn = {CreateSection: (self:TabColumn, props:Section.SectionProps) -> Section.Section, CreateLabel: (self:TabColumn, props:Label.LabelProps) -> Label.Label, CreateButton: (self:TabColumn, props:Button.ButtonProps) -> Button.Button, CreateToggle: (self:TabColumn, props:Toggle.ToggleProps) -> Toggle.Toggle, CreateSlider: (self:TabColumn, props:Slider.SliderProps) -> Slider.Slider, AddSlider: (self:TabColumn, props:Slider.SliderProps) -> Slider.Slider, CreateInput: (self:TabColumn, props:Input.InputProps) -> Input.Input, CreateKeybind: (self:TabColumn, props:Keybind.KeybindProps) -> Keybind.Keybind, CreateDropdown: (self:TabColumn, props:Dropdown.DropdownProps) -> Dropdown.Dropdown, AddDropdown: (self:TabColumn, props:Dropdown.DropdownProps) -> Dropdown.Dropdown, CreateColorPicker: (self:TabColumn, props:ColorPicker.ColorPickerProps) -> ColorPicker.ColorPicker}
            export type Tab = {Left: TabColumn, Right: TabColumn, _frame: Frame, _theme: {[string]: any}, CreateSection: (self:Tab, props:Section.SectionProps) -> Section.Section, CreateLabel: (self:Tab, props:Label.LabelProps) -> Label.Label, CreateButton: (self:Tab, props:Button.ButtonProps) -> Button.Button, CreateToggle: (self:Tab, props:Toggle.ToggleProps) -> Toggle.Toggle, CreateSlider: (self:Tab, props:Slider.SliderProps) -> Slider.Slider, AddSlider: (self:Tab, props:Slider.SliderProps) -> Slider.Slider, CreateInput: (self:Tab, props:Input.InputProps) -> Input.Input, CreateKeybind: (self:Tab, props:Keybind.KeybindProps) -> Keybind.Keybind, CreateDropdown: (self:Tab, props:Dropdown.DropdownProps) -> Dropdown.Dropdown, AddDropdown: (self:Tab, props:Dropdown.DropdownProps) -> Dropdown.Dropdown, CreateColorPicker: (self:Tab, props:ColorPicker.ColorPickerProps) -> ColorPicker.ColorPicker, Show: (self:Tab) -> (), Hide: (self:Tab) -> (), SetSide: (self:Tab, element:any, side:string) -> (), MoveToSide: (self:Tab, element:any, side:string) -> (), SetPosition: (self:Tab, index:number) -> (), SetColumns: (self:Tab, columns:number) -> (), Destroy: (self:Tab) -> ()}

            local Tab = {}

            Tab.__index = Tab

            local function resolveIcon(icon: (string | number)?): string?
                if not icon or icon == '' then
                    return nil
                end

                return icons.Resolve(icon, 'Lucide')
            end

            function Tab.new(
                props: TabProps,
                theme: {[string]: any},
                contentParent: Frame,
                sidebarParent: Frame,
                windowFrame: Frame?
            ): Tab
                local name = props.name or 'Tab'
                local iconAsset = resolveIcon(props.icon)
                local badgeText = props.badge
                local hasIcon = iconAsset ~= nil
                local hasBadge = badgeText ~= nil and badgeText ~= ''

                local function getTokens(t: {[string]: any})
                    return {
                        colorBorder = t.SurfaceStroke or Color3.fromHex('#2b2b2b'),
                        colorAccent = t.AccentColor or Color3.fromHex('#4cc2ff'),
                        colorSurfaceHover = t.NeutralButtonHover or Color3.fromHex('#252525'),
                        colorTextPrimary = t.TitlingColor or Color3.fromHex('#ffffff'),
                        colorTextSecondary = t.PlaceholderColor or Color3.fromHex('#8c8c96'),
                        font = t.Font or constants.DEFAULT_FONT_MEDIUM,
                    }
                end

                local tokens = getTokens(theme)
                local numColumns = props.columns or 1
                local isDual = numColumns ~= 1
                local tabContainer = Instance.new('Frame')

                tabContainer.Name = 'Tab_' .. name
                tabContainer.Size = UDim2.fromScale(1, 1)
                tabContainer.BackgroundTransparency = 1
                tabContainer.Visible = false
                tabContainer.Parent = contentParent

                local SCROLLBAR_W = 4
                local COL_GAP = 6
                local leftScroll = Instance.new('ScrollingFrame')

                leftScroll.Name = 'Column_Left'
                leftScroll.Position = UDim2.fromScale(0, 0)
                leftScroll.Size = if isDual then UDim2.new(0.5, -COL_GAP / 2, 1, 0)else UDim2.fromScale(1, 1)
                leftScroll.BackgroundTransparency = 1
                leftScroll.ScrollBarThickness = 2
                leftScroll.ScrollBarImageColor3 = tokens.colorBorder
                leftScroll.ScrollBarImageTransparency = 0.5
                leftScroll.BorderSizePixel = 0
                leftScroll.CanvasSize = UDim2.fromOffset(0, 0)
                leftScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
                leftScroll.ScrollingDirection = Enum.ScrollingDirection.Y
                leftScroll.ClipsDescendants = true
                leftScroll.Parent = tabContainer

                local leftLayout = Instance.new('UIListLayout')

                leftLayout.SortOrder = Enum.SortOrder.LayoutOrder
                leftLayout.FillDirection = Enum.FillDirection.Vertical
                leftLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
                leftLayout.Padding = UDim.new(0, constants.elementPadding)
                leftLayout.Parent = leftScroll

                local leftPad = Instance.new('UIPadding')

                leftPad.PaddingLeft = UDim.new(0, constants.contentPadding)
                leftPad.PaddingRight = if isDual then UDim.new(0, 4)else UDim.new(0, constants.contentPadding)
                leftPad.PaddingTop = UDim.new(0, 8)
                leftPad.PaddingBottom = UDim.new(0, 8)
                leftPad.Parent = leftScroll

                local rightScroll: ScrollingFrame? = nil
                local columnDivider: Frame? = nil

                if isDual then
                    local rs = Instance.new('ScrollingFrame')

                    rs.Name = 'Column_Right'
                    rs.AnchorPoint = Vector2.new(1, 0)
                    rs.Position = UDim2.fromScale(1, 0)
                    rs.Size = UDim2.new(0.5, -COL_GAP / 2, 1, 0)
                    rs.BackgroundTransparency = 1
                    rs.ScrollBarThickness = 2
                    rs.ScrollBarImageColor3 = tokens.colorBorder
                    rs.ScrollBarImageTransparency = 0.5
                    rs.BorderSizePixel = 0
                    rs.CanvasSize = UDim2.fromOffset(0, 0)
                    rs.AutomaticCanvasSize = Enum.AutomaticSize.Y
                    rs.ScrollingDirection = Enum.ScrollingDirection.Y
                    rs.ClipsDescendants = true
                    rs.Parent = tabContainer

                    local rightLayout = Instance.new('UIListLayout')

                    rightLayout.SortOrder = Enum.SortOrder.LayoutOrder
                    rightLayout.FillDirection = Enum.FillDirection.Vertical
                    rightLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
                    rightLayout.Padding = UDim.new(0, constants.elementPadding)
                    rightLayout.Parent = rs

                    local rightPad = Instance.new('UIPadding')

                    rightPad.PaddingLeft = UDim.new(0, 4)
                    rightPad.PaddingRight = UDim.new(0, constants.contentPadding)
                    rightPad.PaddingTop = UDim.new(0, 8)
                    rightPad.PaddingBottom = UDim.new(0, 8)
                    rightPad.Parent = rs
                    rightScroll = rs

                    local div = Instance.new('Frame')

                    div.Name = 'ColumnDivider'
                    div.AnchorPoint = Vector2.new(0.5, 0)
                    div.Position = UDim2.new(0.5, 0, 0, 8)
                    div.Size = UDim2.new(0, 1, 1, -16)
                    div.BackgroundColor3 = tokens.colorBorder
                    div.BackgroundTransparency = 0.7
                    div.BorderSizePixel = 0
                    div.Parent = tabContainer
                    columnDivider = div
                end

                local tabBtn = Instance.new('TextButton')

                tabBtn.Name = 'TabBtn_' .. name
                tabBtn.Size = if props.neglectSelector then UDim2.fromOffset(0, 0)else UDim2.new(1, 0, 0, 36)
                tabBtn.BackgroundColor3 = tokens.colorAccent
                tabBtn.BackgroundTransparency = 1
                tabBtn.BorderSizePixel = 0
                tabBtn.AutoButtonColor = false
                tabBtn.Text = ''
                tabBtn.Active = not props.neglectSelector
                tabBtn.Visible = not props.neglectSelector
                tabBtn.Parent = sidebarParent

                local tabBtnCorner = Instance.new('UICorner')

                tabBtnCorner.CornerRadius = UDim.new(0, 8)
                tabBtnCorner.Parent = tabBtn

                local tabStroke = Instance.new('UIStroke')

                tabStroke.Color = tokens.colorBorder
                tabStroke.Thickness = 1
                tabStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                tabStroke.Transparency = 1
                tabStroke.Parent = tabBtn

                local tabScale = Instance.new('UIScale')

                tabScale.Scale = 1
                tabScale.Parent = tabBtn

                local indicator = Instance.new('Frame')

                indicator.Name = 'Indicator'
                indicator.AnchorPoint = Vector2.new(0, 0.5)
                indicator.Position = UDim2.new(0, 4, 0.5, 0)
                indicator.Size = UDim2.fromOffset(3, 0)
                indicator.BackgroundColor3 = tokens.colorAccent
                indicator.BackgroundTransparency = 1
                indicator.BorderSizePixel = 0
                indicator.ZIndex = 3
                indicator.Parent = tabBtn

                local indCorner = Instance.new('UICorner')

                indCorner.CornerRadius = UDim.new(1, 0)
                indCorner.Parent = indicator

                local contentRow = Instance.new('Frame')

                contentRow.Name = 'ContentRow'
                contentRow.Size = UDim2.fromScale(1, 1)
                contentRow.BackgroundTransparency = 1
                contentRow.Parent = tabBtn

                local rowLayout = Instance.new('UIListLayout')

                rowLayout.FillDirection = Enum.FillDirection.Horizontal
                rowLayout.VerticalAlignment = Enum.VerticalAlignment.Center
                rowLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
                rowLayout.Padding = UDim.new(0, 8)
                rowLayout.SortOrder = Enum.SortOrder.LayoutOrder
                rowLayout.Parent = contentRow

                local rowPad = Instance.new('UIPadding')

                rowPad.PaddingLeft = UDim.new(0, 13)
                rowPad.PaddingRight = if hasBadge then UDim.new(0, 46)else UDim.new(0, 8)
                rowPad.Parent = contentRow

                local iconImg: ImageLabel? = nil

                if hasIcon then
                    local img = Instance.new('ImageLabel')

                    img.Name = 'Icon'
                    img.Size = UDim2.fromOffset(16, 16)
                    img.BackgroundTransparency = 1
                    img.Image = iconAsset::string
                    img.ImageColor3 = tokens.colorTextSecondary
                    img.LayoutOrder = 1
                    img.Parent = contentRow
                    iconImg = img
                end

                local titleLabel = Instance.new('TextLabel')

                titleLabel.Name = 'Title'
                titleLabel.Size = UDim2.new(1, if hasIcon then-24 else 0, 1, 0)
                titleLabel.BackgroundTransparency = 1
                titleLabel.Text = name
                titleLabel.TextColor3 = tokens.colorTextSecondary
                titleLabel.TextSize = 13
                titleLabel.FontFace = tokens.font
                titleLabel.TextXAlignment = Enum.TextXAlignment.Left
                titleLabel.TextTruncate = Enum.TextTruncate.AtEnd
                titleLabel.LayoutOrder = 2
                titleLabel.Parent = contentRow

                local badgeFrame: Frame? = nil
                local badgeLabel: TextLabel? = nil
                local badgeStroke: UIStroke? = nil

                if hasBadge then
                    local bf = Instance.new('Frame')

                    bf.Name = 'Badge'
                    bf.AnchorPoint = Vector2.new(1, 0.5)
                    bf.Position = UDim2.new(1, -8, 0.5, 0)
                    bf.AutomaticSize = Enum.AutomaticSize.X
                    bf.Size = UDim2.fromOffset(0, 16)
                    bf.BackgroundColor3 = tokens.colorAccent
                    bf.BackgroundTransparency = 0.82
                    bf.BorderSizePixel = 0
                    bf.ZIndex = 2
                    bf.Parent = tabBtn

                    local bc = Instance.new('UICorner')

                    bc.CornerRadius = UDim.new(1, 0)
                    bc.Parent = bf

                    local bs = Instance.new('UIStroke')

                    bs.Color = tokens.colorAccent
                    bs.Thickness = 1
                    bs.Transparency = 0.45
                    bs.Parent = bf
                    badgeStroke = bs

                    local bp = Instance.new('UIPadding')

                    bp.PaddingLeft = UDim.new(0, 6)
                    bp.PaddingRight = UDim.new(0, 6)
                    bp.Parent = bf

                    local bl = Instance.new('TextLabel')

                    bl.Name = 'Label'
                    bl.Size = UDim2.fromScale(0, 1)
                    bl.AutomaticSize = Enum.AutomaticSize.X
                    bl.BackgroundTransparency = 1
                    bl.Text = badgeText::string
                    bl.TextColor3 = tokens.colorAccent
                    bl.TextSize = 9
                    bl.FontFace = DEFAULT_FONT_BOLD
                    bl.Parent = bf
                    badgeLabel = bl
                    badgeFrame = bf
                end

                local tabRef: {ref: any} = {ref = nil}

                if not variables.isTouchOnly then
                    tabBtn.MouseEnter:Connect(function()
                        if tabContainer.Visible then
                            return
                        end

                        local ref = tabRef.ref
                        local win = ref and ref._window

                        if win and (win::any)._isDraggingAnyTab then
                            return
                        end

                        tween.fire(tabBtn, constants.tweenFast, {
                            BackgroundColor3 = tokens.colorSurfaceHover,
                            BackgroundTransparency = 0.94,
                        })
                        tween.fire(tabStroke, constants.tweenFast, {
                            Color = tokens.colorBorder,
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
                        if tabContainer.Visible then
                            return
                        end

                        tween.fire(tabBtn, constants.tweenFast, {BackgroundTransparency = 1})
                        tween.fire(tabStroke, constants.tweenFast, {Transparency = 1})
                        tween.fire(titleLabel, constants.tweenFast, {
                            TextColor3 = tokens.colorTextSecondary,
                        })

                        if iconImg then
                            tween.fire(iconImg, constants.tweenFast, {
                                ImageColor3 = tokens.colorTextSecondary,
                            })
                        end
                    end)
                end

                local self = setmetatable({}, Tab)::any

                tabRef.ref = self
                self._name = name
                self._frame = tabContainer
                self._container = tabContainer
                self._scrollFrame = leftScroll
                self._leftScrollFrame = leftScroll
                self._rightScrollFrame = rightScroll
                self._isDual = isDual
                self._tabButton = tabBtn
                self._tabScale = tabScale
                self._neglectSelector = props.neglectSelector == true
                self._theme = theme
                self._indicator = indicator
                self._tabStroke = tabStroke
                self._titleLabel = titleLabel
                self._iconImg = iconImg
                self._badgeFrame = badgeFrame
                self._badgeLabel = badgeLabel
                self._badgeStroke = badgeStroke
                self._tokens = tokens
                self._elementCount = 0
                self._elements = {}
                self._windowFrame = windowFrame

                local function nextOrder(): number
                    self._elementCount += 1

                    return self._elementCount
                end
                local function maybeDeriveFlag(props: any): any
                    if props and not props.flag and not (props::any).Flag and not (props::any).noSave and not (props::any).ignoreFlag then
                        local nameStr = props.name or (props::any).Label or (props::any).Text

                        if type(nameStr) == 'string' and #nameStr > 0 then
                            props = table.clone(props)
                            props.flag = saveManager.deriveFlagFromName(nameStr)
                        end
                    end

                    return props
                end

                function self:_createOn(
                    targetScroll: ScrollingFrame,
                    module: any,
                    props: any
                ): any
                    props = maybeDeriveFlag(props)

                    local ord = nextOrder()
                    local el = module.new(props, self._theme, targetScroll, self)
                    local eAny = el::any

                    eAny.tab = self
                    eAny.window = self._window

                    if el._frame then
                        el._frame.LayoutOrder = ord * 10
                    end

                    table.insert(self._elements, el)

                    local flagKey = (el::any)._flag

                    if flagKey and flagKey ~= '' then
                        saveManager:Register(flagKey, el)
                    end

                    local desc = props and (props.description or props.Description or props.Tooltip)

                    if desc and desc ~= '' and not module.noDescriptor then
                        local descObj = Descriptor.new(targetScroll, desc, self._theme, ord * 10 + 1)

                        el._descriptor = descObj

                        table.insert(self._elements, descObj)
                    end

                    return el
                end
                function self:_createColorPickerOn(
                    targetScroll: ScrollingFrame,
                    props: any
                ): any
                    props = maybeDeriveFlag(props)

                    local wf = self._windowFrame
                    local merged = table.clone(props::any)::ColorPicker.ColorPickerProps

                    if wf and not (merged::any).overlayParent then
                        local m = merged::any

                        m.overlayParent = wf
                        m.overlayYOffset = OVERLAY_Y_OFFSET
                    end

                    local ord = nextOrder()
                    local cp = ColorPicker.new(merged, self._theme, targetScroll)
                    local cpAny = cp::any

                    cpAny.tab = self
                    cpAny.window = self._window
                    cp._frame.LayoutOrder = ord * 10

                    table.insert(self._elements, cp)

                    local flagKey = (cp::any)._flag

                    if flagKey and flagKey ~= '' then
                        saveManager:Register(flagKey, function(
                            v: any,
                            skipCallback: boolean?
                        )
                            cp:Set(v, nil, skipCallback)
                        end)
                    end

                    local desc = props and (props.description or props.Description or props.Tooltip)

                    if desc and desc ~= '' then
                        local descObj = Descriptor.new(targetScroll, desc, self._theme, ord * 10 + 1)

                        cp._descriptor = descObj

                        table.insert(self._elements, descObj)
                    end

                    return cp
                end
                function self:_createGroupOn(
                    targetScroll: ScrollingFrame,
                    props: any
                ): any
                    local host = {
                        window = self._window,
                        tabPage = targetScroll,
                        direction = nil,
                        forgetState = (self::any).forgetState,
                        elements = self._elements,
                    }
                    local g = Group.new(host, props);

                    (g::any)._frame.Parent = targetScroll;
                    (g::any).tab = self;
                    (g::any).window = self._window

                    table.insert(self._elements, g)

                    return g
                end
                function self:_moveElement(
                    element: any,
                    targetIndex: number
                )
                    local idx = table.find(self._elements, element)

                    if not idx then
                        return
                    end

                    targetIndex = math.clamp(targetIndex, 1, #self._elements)

                    if idx == targetIndex then
                        return
                    end

                    table.remove(self._elements, idx)
                    table.insert(self._elements, targetIndex, element)

                    for i, el in self._elements do
                        assignOrder({
                            _frame = el._frame,
                            descriptor = el._descriptor,
                        }, i * 10)
                    end
                end

                local function makeSideProxy(primaryScroll: ScrollingFrame)
                    return {
                        CreateSection = function(_, p)
                            return self:_createOn(primaryScroll, Section, p)
                        end,
                        CreateLabel = function(_, p)
                            return self:_createOn(primaryScroll, Label, p)
                        end,
                        CreateButton = function(_, p)
                            return self:_createOn(primaryScroll, Button, p)
                        end,
                        CreateToggle = function(_, p)
                            return self:_createOn(primaryScroll, Toggle, p)
                        end,
                        CreateSlider = function(_, p)
                            return self:_createOn(primaryScroll, Slider, p)
                        end,
                        AddSlider = function(_, p)
                            return self:_createOn(primaryScroll, Slider, p)
                        end,
                        CreateInput = function(_, p)
                            return self:_createOn(primaryScroll, Input, p)
                        end,
                        CreateKeybind = function(_, p)
                            return self:_createOn(primaryScroll, Keybind, p)
                        end,
                        CreateDropdown = function(_, p)
                            return self:_createOn(primaryScroll, Dropdown, p)
                        end,
                        AddDropdown = function(_, p)
                            return self:_createOn(primaryScroll, Dropdown, p)
                        end,
                        CreateColorPicker = function(_, p)
                            return self:_createColorPickerOn(primaryScroll, p)
                        end,
                        CreateText = function(_, p)
                            return self:_createOn(primaryScroll, TextComp, p)
                        end,
                        CreateDivider = function(_, p)
                            return self:_createOn(primaryScroll, Divider, p)
                        end,
                        CreateProgress = function(_, p)
                            return self:_createOn(primaryScroll, Progress, p)
                        end,
                        CreateStat = function(_, p)
                            return self:_createOn(primaryScroll, Stat, p)
                        end,
                        CreateConsole = function(_, p)
                            return self:_createOn(primaryScroll, Console, p)
                        end,
                        CreateGroup = function(_, p)
                            return self:_createGroupOn(primaryScroll, p)
                        end,
                    }
                end

                self.Left = makeSideProxy(leftScroll)
                self.Right = makeSideProxy(if isDual and rightScroll then rightScroll else leftScroll)

                function self:CreateSection(props)
                    return self:_createOn(leftScroll, Section, props)
                end
                function self:CreateLabel(props)
                    return self:_createOn(leftScroll, Label, props)
                end
                function self:CreateButton(props)
                    return self:_createOn(leftScroll, Button, props)
                end
                function self:CreateToggle(props)
                    return self:_createOn(leftScroll, Toggle, props)
                end
                function self:CreateSlider(props)
                    return self:_createOn(leftScroll, Slider, props)
                end
                function self:AddSlider(props)
                    return self:_createOn(leftScroll, Slider, props)
                end
                function self:CreateInput(props)
                    return self:_createOn(leftScroll, Input, props)
                end
                function self:CreateKeybind(props)
                    return self:_createOn(leftScroll, Keybind, props)
                end
                function self:CreateDropdown(props)
                    return self:_createOn(leftScroll, Dropdown, props)
                end
                function self:AddDropdown(props)
                    return self:_createOn(leftScroll, Dropdown, props)
                end
                function self:CreateColorPicker(props)
                    return self:_createColorPickerOn(leftScroll, props)
                end
                function self:CreateText(props)
                    return self:_createOn(leftScroll, TextComp, props)
                end
                function self:CreateDivider(props)
                    return self:_createOn(leftScroll, Divider, props)
                end
                function self:CreateProgress(props)
                    return self:_createOn(leftScroll, Progress, props)
                end
                function self:CreateStat(props)
                    return self:_createOn(leftScroll, Stat, props)
                end
                function self:CreateConsole(props)
                    return self:_createOn(leftScroll, Console, props)
                end
                function self:CreateGroup(props)
                    return self:_createGroupOn(leftScroll, props)
                end
                function self:SetColumns(columns: number)
                    local wantDual = columns == 2

                    if wantDual == self._isDual and wantDual == true then
                        return
                    end
                    if wantDual then
                        leftScroll.Size = UDim2.new(0.5, -COL_GAP / 2, 1, 0)

                        if not self._rightScrollFrame then
                            local rs = Instance.new('ScrollingFrame')

                            rs.Name = 'Column_Right'
                            rs.AnchorPoint = Vector2.new(1, 0)
                            rs.Position = UDim2.fromScale(1, 0)
                            rs.Size = UDim2.new(0.5, -COL_GAP / 2, 1, 0)
                            rs.BackgroundTransparency = 1
                            rs.ScrollBarThickness = 2
                            rs.ScrollBarImageColor3 = self._tokens.colorBorder
                            rs.ScrollBarImageTransparency = 0.5
                            rs.BorderSizePixel = 0
                            rs.CanvasSize = UDim2.fromOffset(0, 0)
                            rs.AutomaticCanvasSize = Enum.AutomaticSize.Y
                            rs.ScrollingDirection = Enum.ScrollingDirection.Y
                            rs.ClipsDescendants = true
                            rs.Parent = tabContainer

                            local rightLayout = Instance.new('UIListLayout')

                            rightLayout.SortOrder = Enum.SortOrder.LayoutOrder
                            rightLayout.FillDirection = Enum.FillDirection.Vertical
                            rightLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
                            rightLayout.Padding = UDim.new(0, constants.elementPadding)
                            rightLayout.Parent = rs

                            local rightPad = Instance.new('UIPadding')

                            rightPad.PaddingLeft = UDim.new(0, 4)
                            rightPad.PaddingRight = UDim.new(0, constants.contentPadding)
                            rightPad.PaddingTop = UDim.new(0, 8)
                            rightPad.PaddingBottom = UDim.new(0, 8)
                            rightPad.Parent = rs
                            self._rightScrollFrame = rs
                            self.Right = makeSideProxy(rs)
                        end

                        self._rightScrollFrame.Visible = true

                        if not columnDivider then
                            local div = Instance.new('Frame')

                            div.Name = 'ColumnDivider'
                            div.AnchorPoint = Vector2.new(0.5, 0)
                            div.Position = UDim2.new(0.5, 0, 0, 8)
                            div.Size = UDim2.new(0, 1, 1, -16)
                            div.BackgroundColor3 = self._tokens.colorBorder
                            div.BackgroundTransparency = 0.7
                            div.BorderSizePixel = 0
                            div.Parent = tabContainer
                            columnDivider = div
                        end

                        columnDivider.Visible = true
                        self._isDual = true
                    else
                        leftScroll.Size = UDim2.fromScale(1, 1)

                        if self._rightScrollFrame then
                            for _, child in self._rightScrollFrame:GetChildren()do
                                if child:IsA('GuiObject') and not child:IsA('UIListLayout') and not child:IsA('UIPadding') then
                                    child.Parent = leftScroll
                                end
                            end

                            self._rightScrollFrame.Visible = false
                        end
                        if columnDivider then
                            columnDivider.Visible = false
                        end

                        self._isDual = false
                    end
                end

                local function resolveFrame(element: any): Frame?
                    if typeof(element) == 'Instance' then
                        return (element::any):IsA('GuiObject') and element or nil
                    end

                    return element and element._frame or nil
                end

                function self:SetSide(element: any, side: string)
                    local frame = resolveFrame(element)

                    if not frame then
                        return
                    end

                    local isRight = side and (string.lower(side) == 'right' or side == '2')
                    local targets: ScrollingFrame? = if isRight then self._rightScrollFrame else self._leftScrollFrame

                    if not targets then
                        return
                    end

                    frame.Parent = targets
                end
                function self:MoveToSide(element: any, side: string)
                    self:SetSide(element, side)
                end
                function self:SetPosition(index: number)
                    if self._window and self._window.ReorderTab then
                        self._window:ReorderTab(self, index)
                    end
                end
                function self:Show()
                    hapticEngine.click()

                    tabContainer.Position = UDim2.fromOffset(0, 18)
                    tabContainer.Visible = true

                    tween.fire(tabContainer, constants.tweenNormal, {
                        Position = UDim2.fromScale(0, 0),
                    })

                    if not self._neglectSelector then
                        titleLabel.FontFace = self._theme.TitleFont or constants.DEFAULT_FONT_SEMI

                        tween.fire(tabBtn, constants.tweenFast, {
                            BackgroundColor3 = tokens.colorAccent,
                            BackgroundTransparency = 0.86,
                        })
                        tween.fire(tabStroke, constants.tweenFast, {
                            Color = tokens.colorAccent,
                            Transparency = 0.4,
                        })
                        tween.fire(indicator, constants.tweenFast, {
                            Size = UDim2.fromOffset(3, 18),
                            BackgroundTransparency = 0,
                            BackgroundColor3 = tokens.colorAccent,
                        })
                        tween.fire(titleLabel, constants.tweenFast, {
                            TextColor3 = tokens.colorTextPrimary,
                        })

                        if iconImg then
                            tween.fire(iconImg, constants.tweenFast, {
                                ImageColor3 = tokens.colorAccent,
                            })
                        end
                    end
                end
                function self:Hide()
                    tabContainer.Visible = false
                    tabContainer.Position = UDim2.fromScale(0, 0)

                    if not self._neglectSelector then
                        titleLabel.FontFace = tokens.font or constants.DEFAULT_FONT_MEDIUM

                        tween.fire(tabBtn, constants.tweenFast, {BackgroundTransparency = 1})
                        tween.fire(tabStroke, constants.tweenFast, {
                            Transparency = 1,
                            Color = tokens.colorBorder,
                        })
                        tween.fire(indicator, constants.tweenFast, {
                            Size = UDim2.fromOffset(3, 0),
                            BackgroundTransparency = 1,
                        })
                        tween.fire(titleLabel, constants.tweenFast, {
                            TextColor3 = tokens.colorTextSecondary,
                        })

                        if iconImg then
                            tween.fire(iconImg, constants.tweenFast, {
                                ImageColor3 = tokens.colorTextSecondary,
                            })
                        end
                    end
                end
                function self:Destroy()
                    if self._themeUnsub then
                        self._themeUnsub()

                        self._themeUnsub = nil
                    end

                    for _, el in self._elements do
                        pcall(function()
                            el:Destroy()
                        end)
                    end

                    table.clear(self._elements)

                    if tabContainer.Parent then
                        tabContainer:Destroy()
                    end
                    if tabBtn.Parent then
                        tabBtn:Destroy()
                    end

                    self.Left = nil::any
                    self.Right = nil::any
                    self._leftScrollFrame = nil
                    self._rightScrollFrame = nil
                    self._window = nil
                    self._windowFrame = nil
                end

                self._themeUnsub = themeUtil.subscribe(function(t)
                    self._theme = t
                    tokens = getTokens(t)
                    self._tokens = tokens
                    leftScroll.ScrollBarImageColor3 = tokens.colorBorder

                    if self._rightScrollFrame then
                        self._rightScrollFrame.ScrollBarImageColor3 = tokens.colorBorder
                    end
                    if columnDivider then
                        columnDivider.BackgroundColor3 = tokens.colorBorder
                    end
                    if badgeStroke then
                        badgeStroke.Color = tokens.colorAccent
                    end
                    if badgeLabel then
                        badgeLabel.TextColor3 = tokens.colorAccent
                    end
                    if badgeFrame then
                        badgeFrame.BackgroundColor3 = tokens.colorAccent
                    end
                    if not self._neglectSelector then
                        if tabContainer.Visible then
                            tabBtn.BackgroundColor3 = tokens.colorAccent
                            tabBtn.BackgroundTransparency = 0.86
                            tabStroke.Color = tokens.colorAccent
                            tabStroke.Transparency = 0.4
                            indicator.BackgroundColor3 = tokens.colorAccent
                            indicator.BackgroundTransparency = 0
                            indicator.Size = UDim2.fromOffset(3, 18)
                            titleLabel.TextColor3 = tokens.colorTextPrimary

                            if iconImg then
                                iconImg.ImageColor3 = tokens.colorAccent
                            end
                        else
                            tabBtn.BackgroundTransparency = 1
                            tabStroke.Color = tokens.colorBorder
                            tabStroke.Transparency = 1
                            indicator.BackgroundColor3 = tokens.colorAccent
                            indicator.BackgroundTransparency = 1
                            indicator.Size = UDim2.fromOffset(3, 0)
                            titleLabel.TextColor3 = tokens.colorTextSecondary

                            if iconImg then
                                iconImg.ImageColor3 = tokens.colorTextSecondary
                            end
                        end
                    end
                end, tabContainer)

                return self
            end

            return Tab
        end)()
    end,
    [32] = function()
        local wax, script, require = ImportGlobals(32)
        local ImportGlobals

        return (function(...)
            export type Theme = string | {[string]: any}
            export type WindowProps = {name: string?, subtitle: string?, theme: Theme?, keybind: (EnumItem | string)?, keepOnScreen: boolean?, gestureBar: boolean?, tabsHeader: string?, icon: (string | number)?}
            export type TabProps = {name: string?, icon: (string | number)?, badge: string?, columns: number?, neglectSelector: boolean?, forgetState: boolean?}
            export type SectionProps = {name: string?, icon: (string | number)?, description: string?, defaultOpen: boolean?, opened: boolean?, closed: boolean?}
            export type LabelProps = {text: string?, richText: boolean?, textSize: number?, textColor: Color3?}
            export type ButtonProps = {name: string?, description: string?, callback: (() -> ())?}
            export type ToggleProps = {name: string?, description: string?, flag: string?, value: boolean?, callback: ((value:boolean) -> ())?}
            export type SliderProps = {name: string?, Label: string?, Text: string?, description: string?, Tooltip: string?, flag: string?, Flag: string?, range: {number}?, min: number?, Min: number?, max: number?, Max: number?, increment: number?, step: number?, Step: number?, value: number?, default: number?, Default: number?, suffix: string?, Suffix: string?, compact: boolean?, Compact: boolean?, hideMax: boolean?, HideMax: boolean?, formatDisplayValue: ((slider:any, value:number) -> string?)?, FormatDisplayValue: ((slider:any, value:number) -> string?)?, enabled: boolean?, Enabled: boolean?, layoutOrder: number?, LayoutOrder: number?, callback: ((value:number) -> ())?, Callback: ((value:number) -> ())?}
            export type DropdownProps = {name: string?, Label: string?, Text: string?, description: string?, Tooltip: string?, flag: string?, Flag: string?, options: {any}?, Options: {any}?, value: any?, default: any?, Default: any?, multiSelect: boolean?, MultiSelect: boolean?, placeholder: string?, Placeholder: string?, searchable: boolean?, Searchable: boolean?, disabledValues: {any}?, DisabledValues: {any}?, formatDisplayValue: ((value:any) -> string)?, FormatDisplayValue: ((value:any) -> string)?, maxVisibleDropdownItems: number?, MaxVisibleDropdownItems: number?, specialType: string?, SpecialType: string?, enabled: boolean?, Enabled: boolean?, layoutOrder: number?, LayoutOrder: number?, callback: ((value:any) -> ())?, Callback: ((value:any) -> ())?}
            export type InputProps = {name: string?, description: string?, flag: string?, value: string?, placeholder: string?, numeric: boolean?, clearOnFocus: boolean?, enterOnly: boolean?, callback: ((value:string) -> ())?}
            export type KeybindProps = {name: string?, description: string?, flag: string?, value: (EnumItem | string)?, hold: boolean?, holdThreshold: number?, callback: ((key:EnumItem, isHolding:boolean) -> ())?, onChanged: ((key:EnumItem) -> ())?}
            export type ColorPickerProps = {name: string?, flag: string?, color: Color3?, alpha: number?, callback: ((value:Color3, alpha:number) -> ())?}
            export type NotifyProps = {title: string?, content: string?, duration: number?}
            export type TextProps = {name: string?, text: string?, icon: (string | number)?, richText: boolean?}
            export type DividerProps = {text: string?, spacing: number?, line: boolean?}
            export type ProgressProps = {name: string?, icon: (string | number)?, value: number?, range: {number}?, steps: number?, text: string?, format: ((value:number, min:number, max:number) -> string)?, showValue: boolean?, indeterminate: boolean?}
            export type StatProps = {name: string?, icon: (string | number)?, value: number?, prefix: string?, suffix: string?, changeMode: string?, changeBaseline: string?, numberEasing: boolean?}
            export type ConsoleProps = {name: string?, text: string?, height: number?, follow: boolean?, maxLines: number?}
            export type GroupProps = {direction: string?}
            export type TagProps = {text: string?, icon: (string | number)?, color: Color3?, order: number?, title: string?}
            export type ToastProps = {title: string?, subtitle: string?, icon: (string | number)?, duration: number?, position: string?, subtitleAbove: boolean?, minWidth: number?}
            export type TaskContext = {Status: (self:TaskContext, message:string) -> (), SetProgress: (self:TaskContext, fraction:number) -> (), Abort: (self:TaskContext, message:string?) -> (), ShouldAbort: (self:TaskContext) -> boolean}
            export type TaskEntry = {name: string, weight: number?, run: (ctx:TaskContext) -> (), progress: number?}
            export type LoadingConfig = {showProgress: boolean?, minDuration: number?, dismissible: boolean?, allowCancel: boolean?}
            export type LoadingScreenProps = {title: string?, subtitle: string?, icon: (string | number)?, accent: Color3?, showProgress: boolean?, minDuration: number?, dismissible: boolean?, allowCancel: boolean?, theme: Theme?}
            export type LoadingScreen = {update: (self:LoadingScreen, status:string, progress:number?) -> (), dismiss: (self:LoadingScreen, window:any?) -> (), Morph: (self:LoadingScreen, window:any?) -> (), Task: (self:LoadingScreen, name:string, weight:number?, run:(ctx:TaskContext) -> ()) -> LoadingScreen, Run: (self:LoadingScreen, options:{minDuration: number?}?) -> (boolean,string?), Cancel: (self:LoadingScreen) -> (), SetError: (self:LoadingScreen, message:string) -> (), SetTotalWeight: (self:LoadingScreen, total:number) -> ()}
            export type KeySystemConfig = {Service: string, Identifier: string, Provider: string?, ScriptId: string?, LoadScript: boolean?, Title: string?, Subtitle: string?, Accent: Color3?, SaveKey: boolean?, CacheFile: string?, MockKeys: {string}?, AllowCancel: boolean?}
            export type KeySystem = {Prompt: (self:KeySystem, callback:(success:boolean, key:string?) -> ()) -> (), Destroy: (self:KeySystem) -> ()}
            export type StartupOptions = {title: string?, name: string?, subtitle: string?, icon: (string | number)?, accent: Color3?, theme: Theme?, keybind: (EnumItem | string)?, keepOnScreen: boolean?, gestureBar: boolean?, tabsHeader: string?, loading: LoadingConfig?, tasks: {TaskEntry}?, keySystem: KeySystemConfig?}
            export type BootOptions = {title: string?, name: string?, subtitle: string?, icon: (string | number)?, accent: Color3?, theme: Theme?, messages: {string}?, tasks: {TaskEntry}?}
            export type Section = {_frame: Frame, _content: Frame, _open: boolean, SetText: (self:Section, text:string) -> (), Set: (self:Section, text:string) -> (), SetDescription: (self:Section, text:string?) -> (), SetOpen: (self:Section, open:boolean) -> (), SetCollapsed: (self:Section, collapsed:boolean) -> (), Toggle: (self:Section) -> (), Expand: (self:Section) -> (), Collapse: (self:Section) -> (), CreateSection: (self:Section, props:SectionProps) -> Section, CreateLabel: (self:Section, props:LabelProps) -> Label, CreateButton: (self:Section, props:ButtonProps) -> Button, CreateToggle: (self:Section, props:ToggleProps) -> Toggle, CreateSlider: (self:Section, props:SliderProps) -> Slider, AddSlider: (self:Section, props:SliderProps) -> Slider, CreateInput: (self:Section, props:InputProps) -> Input, CreateKeybind: (self:Section, props:KeybindProps) -> Keybind, CreateDropdown: (self:Section, props:DropdownProps) -> Dropdown, AddDropdown: (self:Section, props:DropdownProps) -> Dropdown, CreateColorPicker: (self:Section, props:ColorPickerProps) -> ColorPicker, Destroy: (self:Section) -> ()}
            export type Label = {Set: (self:Label, text:string) -> (), Destroy: (self:Label) -> ()}
            export type Button = {Destroy: (self:Button) -> ()}
            export type Toggle = {value: boolean, Set: (self:Toggle, value:boolean, skipCallback:boolean?) -> (), Destroy: (self:Toggle) -> ()}
            export type Slider = {value: number, Value: number, Changed: any, Set: (self:Slider, value:number, skipCallback:boolean?) -> (), SetValue: (self:Slider, value:number, skipCallback:boolean?) -> (), SetEnabled: (self:Slider, enabled:boolean) -> (), GetFrame: (self:Slider) -> Frame, Destroy: (self:Slider) -> ()}
            export type Dropdown = {value: any, Value: any, Changed: any, Set: (self:Dropdown, value:any, skipCallback:boolean?) -> (), SetValue: (self:Dropdown, value:any, skipCallback:boolean?) -> (), SetOptions: (self:Dropdown, options:{any}) -> (), SetEnabled: (self:Dropdown, enabled:boolean) -> (), GetFrame: (self:Dropdown) -> Frame, Destroy: (self:Dropdown) -> ()}
            export type Input = {value: string, Set: (self:Input, value:string, skipCallback:boolean?) -> (), Destroy: (self:Input) -> ()}
            export type Keybind = {value: EnumItem, Set: (self:Keybind, value:EnumItem | string, skipChanged:boolean?) -> (), Destroy: (self:Keybind) -> ()}
            export type ColorPicker = {value: Color3, alpha: number, Set: (self:ColorPicker, value:Color3, alpha:number?, skipCallback:boolean?) -> (), Destroy: (self:ColorPicker) -> ()}
            export type Text = {_frame: Frame, value: string, Set: (self:Text, text:string) -> (), SetTitle: (self:Text, title:string) -> (), Destroy: (self:Text) -> ()}
            export type Divider = {_frame: Frame, Set: (self:Divider, text:string) -> (), Destroy: (self:Divider) -> ()}
            export type Progress = {_frame: Frame, value: number, Set: (self:Progress, value:number) -> (), Get: (self:Progress) -> number, GetPercentage: (self:Progress) -> number, SetRange: (self:Progress, min:number, max:number) -> (), SetText: (self:Progress, text:string?) -> (), SetIndeterminate: (self:Progress, state:boolean) -> (), Destroy: (self:Progress) -> ()}
            export type Stat = {_frame: Frame, value: number, Set: (self:Stat, value:number) -> (), Get: (self:Stat) -> number, ResetBaseline: (self:Stat, newBaseline:number?) -> (), Destroy: (self:Stat) -> ()}
            export type Console = {_frame: Frame, Set: (self:Console, text:string) -> (), Append: (self:Console, line:string) -> (), Clear: (self:Console) -> (), Get: (self:Console) -> string, Copy: (self:Console) -> boolean, SetHeight: (self:Console, height:number) -> (), Destroy: (self:Console) -> ()}
            export type Tag = {color: Color3, text: string?, SetColor: (self:Tag, color:Color3) -> (), SetText: (self:Tag, text:string?) -> (), SetIcon: (self:Tag, icon:(string | number)?) -> (), Set: (self:Tag, props:TagProps) -> (), Remove: (self:Tag) -> ()}
            export type Group = {_frame: Frame, CreateButton: (self:Group, props:ButtonProps) -> Button, CreateToggle: (self:Group, props:ToggleProps) -> Toggle, CreateSwitch: (self:Group, props:ToggleProps) -> Toggle, CreateSlider: (self:Group, props:SliderProps) -> Slider, CreateStat: (self:Group, props:StatProps) -> Stat, CreateDropdown: (self:Group, props:DropdownProps) -> Dropdown, CreateInput: (self:Group, props:InputProps) -> Input, CreateKeybind: (self:Group, props:KeybindProps) -> Keybind, CreateLabel: (self:Group, props:LabelProps) -> Label, CreateText: (self:Group, props:TextProps) -> Text, CreateDivider: (self:Group, props:DividerProps) -> Divider, CreateSection: (self:Group, props:SectionProps) -> Section, CreateProgress: (self:Group, props:ProgressProps) -> Progress, CreateConsole: (self:Group, props:ConsoleProps) -> Console, CreateGroup: (self:Group, props:GroupProps) -> Group, Destroy: (self:Group) -> ()}
            export type TabColumn = {CreateSection: (self:TabColumn, props:SectionProps) -> Section, CreateLabel: (self:TabColumn, props:LabelProps) -> Label, CreateButton: (self:TabColumn, props:ButtonProps) -> Button, CreateToggle: (self:TabColumn, props:ToggleProps) -> Toggle, CreateSlider: (self:TabColumn, props:SliderProps) -> Slider, AddSlider: (self:TabColumn, props:SliderProps) -> Slider, CreateInput: (self:TabColumn, props:InputProps) -> Input, CreateKeybind: (self:TabColumn, props:KeybindProps) -> Keybind, CreateDropdown: (self:TabColumn, props:DropdownProps) -> Dropdown, AddDropdown: (self:TabColumn, props:DropdownProps) -> Dropdown, CreateColorPicker: (self:TabColumn, props:ColorPickerProps) -> ColorPicker, CreateText: (self:TabColumn, props:TextProps) -> Text, CreateDivider: (self:TabColumn, props:DividerProps) -> Divider, CreateProgress: (self:TabColumn, props:ProgressProps) -> Progress, CreateStat: (self:TabColumn, props:StatProps) -> Stat, CreateConsole: (self:TabColumn, props:ConsoleProps) -> Console, CreateGroup: (self:TabColumn, props:GroupProps) -> Group}
            export type Tab = {Left: TabColumn, Right: TabColumn, CreateSection: (self:Tab, props:SectionProps) -> Section, CreateLabel: (self:Tab, props:LabelProps) -> Label, CreateButton: (self:Tab, props:ButtonProps) -> Button, CreateToggle: (self:Tab, props:ToggleProps) -> Toggle, CreateSlider: (self:Tab, props:SliderProps) -> Slider, AddSlider: (self:Tab, props:SliderProps) -> Slider, CreateInput: (self:Tab, props:InputProps) -> Input, CreateKeybind: (self:Tab, props:KeybindProps) -> Keybind, CreateDropdown: (self:Tab, props:DropdownProps) -> Dropdown, AddDropdown: (self:Tab, props:DropdownProps) -> Dropdown, CreateColorPicker: (self:Tab, props:ColorPickerProps) -> ColorPicker, CreateText: (self:Tab, props:TextProps) -> Text, CreateDivider: (self:Tab, props:DividerProps) -> Divider, CreateProgress: (self:Tab, props:ProgressProps) -> Progress, CreateStat: (self:Tab, props:StatProps) -> Stat, CreateConsole: (self:Tab, props:ConsoleProps) -> Console, CreateGroup: (self:Tab, props:GroupProps) -> Group, CreateLeftSection: (self:Tab, props:SectionProps) -> Section, CreateLeftLabel: (self:Tab, props:LabelProps) -> Label, CreateLeftButton: (self:Tab, props:ButtonProps) -> Button, CreateLeftToggle: (self:Tab, props:ToggleProps) -> Toggle, CreateLeftSlider: (self:Tab, props:SliderProps) -> Slider, CreateLeftInput: (self:Tab, props:InputProps) -> Input, CreateLeftKeybind: (self:Tab, props:KeybindProps) -> Keybind, CreateLeftDropdown: (self:Tab, props:DropdownProps) -> Dropdown, CreateLeftColorPicker: (self:Tab, props:ColorPickerProps) -> ColorPicker, CreateRightSection: (self:Tab, props:SectionProps) -> Section, CreateRightLabel: (self:Tab, props:LabelProps) -> Label, CreateRightButton: (self:Tab, props:ButtonProps) -> Button, CreateRightToggle: (self:Tab, props:ToggleProps) -> Toggle, CreateRightSlider: (self:Tab, props:SliderProps) -> Slider, CreateRightInput: (self:Tab, props:InputProps) -> Input, CreateRightKeybind: (self:Tab, props:KeybindProps) -> Keybind, CreateRightDropdown: (self:Tab, props:DropdownProps) -> Dropdown, CreateRightColorPicker: (self:Tab, props:ColorPickerProps) -> ColorPicker, Show: (self:Tab) -> (), Hide: (self:Tab) -> (), SetSide: (self:Tab, element:any, side:string) -> (), MoveToSide: (self:Tab, element:any, side:string) -> (), SetPosition: (self:Tab, index:number) -> (), SetColumns: (self:Tab, columns:number) -> (), Destroy: (self:Tab) -> ()}
            export type TabDivider = {_frame: Frame, SetText: (self:TabDivider, text:string) -> (), Destroy: (self:TabDivider) -> ()}
            export type Window = {unloaded: boolean, CreateTab: (self:Window, props:TabProps) -> Tab, CreateTabDivider: (self:Window, text:string?) -> TabDivider, ReorderTab: (self:Window, tab:Tab, newIndex:number) -> (), GetTabs: (self:Window) -> {Tab}, SetTabsHeader: (self:Window, header:string) -> (), Notify: (self:Window, props:NotifyProps) -> (), Toast: (self:Window, props:ToastProps) -> any, CreateTag: (self:Window, props:TagProps) -> Tag, ToggleSearch: (self:Window) -> (), OpenSearch: (self:Window) -> (), CloseSearch: (self:Window) -> (), Save: (self:Window, name:string?) -> boolean, Load: (self:Window, name:string?) -> number, ListConfigs: (self:Window) -> {string}, DeleteConfig: (self:Window, name:string) -> boolean, SetAutoLoad: (self:Window, name:string) -> boolean, Show: (self:Window) -> (), Hide: (self:Window) -> (), ToggleHide: (self:Window) -> (), ToggleMinimise: (self:Window) -> (), ChangeTheme: (self:Window, theme:Theme) -> (), Unload: (self:Window) -> ()}
            export type BuiltinTasks = {LoadSave: (profileName:string?) -> TaskEntry, PreloadIcons: (list:{string | number}) -> TaskEntry, FetchAssets: (manifest:{[string]: any}) -> TaskEntry, AwaitCharacter: (timeout:number?) -> TaskEntry, AwaitPlayer: (timeout:number?) -> TaskEntry, CheckExecutor: () -> TaskEntry, Wait: (duration:number, label:string?) -> TaskEntry}
            export type Delirium = {Flags: {[string]: any}, Icons: any, NebulaIcons: any, MediaService: any, SaveManager: any, Tasks: BuiltinTasks, LoadingScreen: {new: (props:LoadingScreenProps) -> LoadingScreen}, KeySystem: {new: (cfg:KeySystemConfig) -> KeySystem}, CreateWindow: (self:Delirium, props:WindowProps) -> Window, Startup: (self:Delirium, config:string | StartupOptions, callback:(window:Window, ctx:any?) -> ()) -> Window, Boot: (self:Delirium, config:string | BootOptions, callback:(window:Window, loadingScreen:LoadingScreen) -> (), messages:{string}?) -> ()}

            return {}
        end)()
    end,
    [58] = function()
        local wax, script, require = ImportGlobals(58)
        local ImportGlobals

        return (function(...)
            local path = {}

            function path.join(basePath: string, childPath: string?): string
                if not childPath or childPath == '' then
                    return basePath
                end

                return basePath .. '/' .. childPath
            end

            local function stripTraversal(text: string): string
                local prev

                repeat
                    prev = text
                    text = text:gsub('%.%.', '')
                until text == prev

                return text
            end

            function path.sanitizeFolder(value: unknown): string
                local text = tostring(value):gsub('\\', '/'):gsub('[:<>"|?*%c]', '')

                text = stripTraversal(text):gsub('/+', '/')

                return (text:gsub('^/+', ''))
            end
            function path.sanitizeFile(value: unknown): string
                local text = tostring(value):gsub('[/\\]', ''):gsub('[:<>"|?*%c]', '')

                return stripTraversal(text)
            end
            function path.basename(value: unknown): string
                return tostring(value):match('[^/\\]+$') or tostring(value)
            end
            function path.stripExtension(value: unknown, extension: string?): string
                if extension and extension ~= '' then
                    local text = tostring(value)

                    return if text:sub(-#extension) == extension then text:sub(1, 
-#extension - 1)else text
                end

                return tostring(value):match('^(.+)%.%w+$') or tostring(value)
            end

            return path
        end)()
    end,
    [44] = function()
        local wax, script, require = ImportGlobals(44)
        local ImportGlobals

        return (function(...)
            local filesystem = require(script.Parent.filesystem)
            local AssetFetcher = require(script.Parent.assetFetcher)
            local services = require(script.Parent.services)
            local httpService = services.getService('HttpService')
            local runService = services.getService('RunService')

            export type FontFace = {name: string, weight: number, style: string, assetId: string}
            export type FontManifest = {name: string, faces: {FontFace}}
            export type CachedFont = {customId: string, manifest: FontManifest, variants: {[string]: Font}}
            export type LoadOptions = {weight: Enum.FontWeight?, style: Enum.FontStyle?, saveToDisk: boolean?, skipCache: boolean?, fallback: Font?}
            export type FontLoader = {load: (self:FontLoader, id:number | string, opts:LoadOptions?) -> Font?, resolve: (self:FontLoader, id:number | string) -> Font?, bind: (self:FontLoader, instance:Instance, property:string, id:number | string, opts:LoadOptions?) -> ()}

            local FONTS_ROOT = 'workspace/Delirium/assets/fonts'
            local DEFAULT_FONT = Font.fromEnum(Enum.Font.SourceSans)
            local IS_STUDIO = runService:IsStudio()
            local FONT_SIGNATURES = {
                '\0\1\0\0',
                'OTTO',
                'true',
                'ttcf',
                'wOFF',
                'wOF2',
            }

            local function isFontBody(body: string): boolean
                for _, sig in FONT_SIGNATURES do
                    if string.sub(body, 1, #sig) == sig then
                        return true
                    end
                end

                return false
            end
            local function sanitizeName(name: string): string
                return string.gsub(name, '[^%w%s%-_%.]+', '')
            end
            local function variantKey(weight: Enum.FontWeight, style: Enum.FontStyle): string
                return tostring(weight.Value) .. '|' .. tostring(style.Value)
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

                return if ok and type(result) == 'string'then result else nil
            end
            local function validateManifest(raw: unknown): FontManifest?
                if type(raw) ~= 'table' then
                    return nil
                end

                local m = raw::any

                if type(m.name) ~= 'string' or type(m.faces) ~= 'table' then
                    return nil
                end

                m.name = sanitizeName(m.name)

                if #m.name == 0 or #m.faces == 0 then
                    return nil
                end

                for _, face in m.faces do
                    if type(face) ~= 'table' then
                        return nil
                    end
                    if type(face.name) ~= 'string' or type(face.assetId) ~= 'string' then
                        return nil
                    end

                    face.name = sanitizeName(face.name)

                    if #face.name == 0 then
                        return nil
                    end
                end

                return m::FontManifest
            end

            local FontLoader = {}

            FontLoader.__index = FontLoader

            function FontLoader.new(): FontLoader
                local self = setmetatable({
                    _cache = {}::{[number]: CachedFont},
                    _fetcher = AssetFetcher.new(),
                    _bindings = {}::{[number]: any},
                    _loading = {}::{[number]: boolean},
                }, FontLoader)::any

                pcall(filesystem.ensureDir, FONTS_ROOT)

                return self
            end

            local function resolveId(value: unknown): number?
                if type(value) == 'number' then
                    return value
                end
                if type(value) == 'string' then
                    return tonumber(string.match(value::string, '^rbxassetid://(%d+)$')) or tonumber(value)
                end

                return nil
            end

            function FontLoader.resolve(self: FontLoader, id: number | string): Font?
                local numId = resolveId(id)

                if not numId then
                    return nil
                end

                local cached = (self::any)._cache[numId]

                if not cached then
                    return nil
                end

                for _, font in pairs(cached.variants)do
                    return font
                end

                return nil
            end
            function FontLoader.load(
                self: FontLoader,
                id: number | string,
                opts: LoadOptions?
            ): Font?
                local cache: {[number]: CachedFont} = (self::any)._cache
                local fetcher: AssetFetcher = (self::any)._fetcher
                local weight = (opts and opts.weight) or Enum.FontWeight.Regular
                local style = (opts and opts.style) or Enum.FontStyle.Normal
                local saveToDisk = if opts and opts.saveToDisk ~= nil then opts.saveToDisk else true
                local skipCache = if opts and opts.skipCache ~= nil then opts.skipCache else false
                local fallback = (opts and opts.fallback) or DEFAULT_FONT
                local key = variantKey(weight, style)
                local numId = resolveId(id)

                if not numId then
                    warn('[Delirium:fontLoader] Invalid font id: ' .. tostring(id))

                    return fallback
                end
                if not skipCache then
                    local cached = cache[numId]

                    if cached then
                        local hit = cached.variants[key]

                        if hit then
                            return hit
                        end

                        local ok, built = pcall(Font.new, cached.customId, weight, style)

                        if ok and built then
                            cached.variants[key] = built

                            return built
                        end

                        cache[numId] = nil
                    end
                end
                if not saveToDisk then
                    return fallback
                end

                local customAsset: ((string) -> string)? = (rawget::any)(_G, 'getcustomasset')

                if type(customAsset) ~= 'function' or typeof(filesystem.isfile) ~= 'function' then
                    return fallback
                end

                pcall(filesystem.ensureDir, FONTS_ROOT)

                local manifestPath = FONTS_ROOT .. '/' .. tostring(numId) .. '.json'
                local rawManifest: string? = nil
                local needsWrite = false

                if IS_STUDIO then
                    rawManifest = '{"name":"Inter","faces":[' .. 
[[{"name":"Regular","weight":400,"style":"normal","assetId":"rbxassetid://12187266066"},]] .. 
[[{"name":"Bold","weight":700,"style":"normal","assetId":"rbxassetid://12187275575"}]] .. ']}'
                elseif filesystem.isfile(manifestPath) then
                    local ok, contents = pcall(filesystem.readfile, manifestPath)

                    rawManifest = if ok then contents else nil
                else
                    rawManifest = fetcher:getContentFromId(numId, false)
                    needsWrite = rawManifest ~= nil
                end
                if not rawManifest then
                    return fallback
                end

                local manifest = validateManifest(jsonDecode(rawManifest))

                if not manifest then
                    pcall(filesystem.delfile, manifestPath)

                    return fallback
                end
                if needsWrite then
                    pcall(filesystem.writefile, manifestPath, rawManifest)
                end

                local fontDir = FONTS_ROOT .. '/' .. manifest.name
                local allLocal = true

                pcall(filesystem.ensureDir, fontDir)

                for i, face in ipairs(manifest.faces)do
                    local faceName = string.gsub(face.name, ' ', '-')
                    local facePath = fontDir .. '/' .. faceName .. '.ttf'

                    if not filesystem.isfile(facePath) then
                        local faceId = resolveId(face.assetId)
                        local body: string? = if faceId then fetcher:getContentFromId(faceId, false)else nil

                        if not body or not isFontBody(body) then
                            allLocal = false

                            warn('[Delirium:fontLoader] Face download failed for id ' .. tostring(numId) .. ', face: ' .. face.name)

                            continue
                        end

                        pcall(filesystem.writefile, facePath, body)
                    end

                    local ok, uri = pcall(customAsset, facePath)

                    if ok and type(uri) == 'string' then
                        manifest.faces[i].assetId = uri
                    else
                        allLocal = false

                        warn('[Delirium:fontLoader] getcustomasset failed for face: ' .. face.name)
                    end
                end

                if not allLocal then
                    return fallback
                end

                local rewrittenJson = jsonEncode(manifest)

                if not rewrittenJson then
                    return fallback
                end

                local localManifestPath = fontDir .. '/manifest.json'

                if not pcall(filesystem.writefile, localManifestPath, rewrittenJson) then
                    return fallback
                end

                local mOk, manifestUri = pcall(customAsset, localManifestPath)

                if not mOk or not manifestUri then
                    return fallback
                end

                local fOk, font = pcall(Font.new, manifestUri, weight, style)

                if not fOk or not font then
                    return fallback
                end

                local entry = cache[numId]

                if not entry then
                    entry = {
                        customId = manifestUri,
                        manifest = manifest,
                        variants = {},
                    }
                    cache[numId] = entry
                end

                entry.variants[key] = font

                return font
            end
            function FontLoader.bind(
                self: FontLoader,
                instance: Instance,
                property: string,
                id: number | string,
                opts: LoadOptions?
            )
                local cache: {[number]: CachedFont} = (self::any)._cache
                local bindings: {[number]: any} = (self::any)._bindings
                local loading: {[number]: boolean} = (self::any)._loading
                local numId = resolveId(id)

                if not numId then
                    warn('[Delirium:fontLoader] bind() \u{2014} invalid id: ' .. tostring(id))

                    return
                end

                local weight = (opts and opts.weight) or Enum.FontWeight.Regular
                local style = (opts and opts.style) or Enum.FontStyle.Normal
                local key = variantKey(weight, style)
                local cached = cache[numId]

                if cached and cached.variants[key] then
                    (instance::any)[property] = cached.variants[key]

                    return
                end

                local slot = bindings[numId]

                if not slot then
                    slot = setmetatable({}, {
                        __mode = 'k',
                    })::any
                    bindings[numId] = slot
                end

                local props = (slot::any)[instance]

                if not props then
                    props = {}
                    (slot::any)[instance] = props
                end

                (props::any)[property] = opts

                if loading[numId] then
                    return
                end

                loading[numId] = true

                task.spawn(function()
                    self:load(numId, opts)

                    loading[numId] = nil

                    local bound = bindings[numId]

                    if not bound then
                        return
                    end

                    local c = cache[numId]

                    if not c then
                        return
                    end

                    for inst, instanceProps in (bound::any)do
                        if (inst::Instance).Parent then
                            local t = inst::any

                            for prop, bindOpts in (instanceProps::any)do
                                local bOpts = bindOpts::LoadOptions?
                                local bWeight = (bOpts and bOpts.weight) or Enum.FontWeight.Regular
                                local bStyle = (bOpts and bOpts.style) or Enum.FontStyle.Normal
                                local bKey = variantKey(bWeight, bStyle)
                                local variant = c.variants[bKey]

                                if variant then
                                    t[prop] = variant
                                end
                            end
                        end
                    end
                end)
            end

            return FontLoader
        end)()
    end,
    [29] = function()
        local wax, script, require = ImportGlobals(29)
        local ImportGlobals

        return (function(...)
            return {
                WindowColor = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromHex('#141414')),
                    ColorSequenceKeypoint.new(0.9999, Color3.fromHex('#191919')),
                    ColorSequenceKeypoint.new(1, Color3.fromHex('#1c1c1c')),
                }),
                ShadowColor = Color3.fromRGB(0, 0, 0),
                SurfaceStroke = Color3.fromHex('#2b2b2b'),
                TitleBarColor = Color3.fromHex('#111114'),
                CornerRoundness = UDim.new(0, 8),
                TabColor = Color3.fromHex('#9d9d9d'),
                TabBackground = ColorSequence.new(Color3.fromHex('#2a2a2a'), Color3.fromHex('#191919')),
                TabStroke = ColorSequence.new(Color3.fromHex('#2b2b2b'), Color3.fromHex('#222222')),
                ElementGradient = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromHex('#2a2a2a')),
                    ColorSequenceKeypoint.new(0.9999, Color3.fromHex('#1e1e1e')),
                    ColorSequenceKeypoint.new(1, Color3.fromHex('#191919')),
                }),
                ElementStroke = Color3.fromHex('#2b2b2b'),
                ElementStrokeGradient = ColorSequence.new(Color3.fromHex('#333333'), Color3.fromHex('#2b2b2b')),
                ElementStrokeHover = Color3.fromHex('#4cc2ff'),
                ElementTransparency = 0,
                ElementStrokeTransparency = 0,
                ElementStrokeHoverTransparency = 0,
                ElementCornerRadius = UDim.new(0, 6),
                ElementTextHoverColor = Color3.fromHex('#ffffff'),
                TitleFont = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold),
                Font = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.Medium),
                ContentColor = Color3.fromHex('#ffffff'),
                TitlingColor = Color3.fromHex('#ffffff'),
                PlaceholderColor = Color3.fromHex('#9d9d9d'),
                AccentColor = Color3.fromHex('#4cc2ff'),
                AccentStroke = Color3.fromHex('#60cdff'),
                AccentGlow = 0.35,
                ToggleTrack = Color3.fromRGB(0, 0, 0),
                ToggleTrackTransparency = 0.6,
                ToggleKnobOff = Color3.fromHex('#9d9d9d'),
                ToggleKnobOffTransparency = 0.3,
                DarkToggleOverlay = false,
                SliderBackground = Color3.fromHex('#222222'),
                SliderBackgroundHover = Color3.fromHex('#2a2a2a'),
                SliderProgress = ColorSequence.new(Color3.fromHex('#4cc2ff'), Color3.fromHex('#0093fb')),
                SliderHandle = Color3.fromRGB(255, 255, 255),
                SliderStroke = Color3.fromRGB(255, 255, 255),
                DropdownHighlight = Color3.fromRGB(255, 255, 255),
                FieldBackground = Color3.fromRGB(255, 255, 255),
                FieldTransparency = 0.9,
                FieldGlow = Color3.fromHex('#4cc2ff'),
                PillCornerRadius = UDim.new(1, 0),
                NeutralButton = Color3.fromHex('#252525'),
                NeutralButtonHover = Color3.fromHex('#2e2e2e'),
                NeutralButtonStroke = Color3.fromHex('#2b2b2b'),
                ErrorColor = Color3.fromHex('#ff4f58'),
                ErrorStrokeColor = Color3.fromHex('#ff6b74'),
                ActionColor = Color3.fromRGB(255, 255, 255),
                LiveAnimation = false,
            }
        end)()
    end,
    [48] = function()
        local wax, script, require = ImportGlobals(48)
        local ImportGlobals

        return (function(...)
            local filesystem = require(script.Parent.filesystem)
            local AssetFetcher = require(script.Parent.assetFetcher)
            local services = require(script.Parent.services)
            local IS_STUDIO = services.getService('RunService'):IsStudio()

            export type RewriteMap = {[number]: string}
            export type OnSettled = (failed:number) -> ()
            export type OnCached = (id:number) -> ()
            export type AvatarReady = (uri:string) -> ()

            local CACHE_ROOT = 'workspace/Delirium'
            local CACHE_ASSETS = 'workspace/Delirium/assets/images'
            local THUMB_ENDPOINT = 
[[https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds=%d&size=48x48&format=Png&isCircular=false]]
            local PNG_MAGIC = '\137PNG\r\n\26\n'
            local fetcher = AssetFetcher.new()
            local imageCache = {}

            imageCache.rewrites = {}::RewriteMap
            imageCache.onCached = nil::OnCached?

            local function getCustomAssetFn(): ((string) -> string)?
                local fn = (rawget::any)(_G, 'getcustomasset')

                return if type(fn) == 'function'then fn else nil
            end
            local function cacheFile(
                filePath: string,
                url: string,
                cacheKey: number | string
            ): string?
                local customAsset = getCustomAssetFn()

                if not customAsset then
                    return nil
                end
                if not filesystem.isfile(filePath) then
                    pcall(filesystem.ensureDir, CACHE_ROOT)
                    pcall(filesystem.ensureDir, CACHE_ASSETS)

                    local body = fetcher:getContentFromUrl(url, cacheKey, false)

                    if not body or string.sub(body, 1, 8) ~= PNG_MAGIC then
                        return nil
                    end
                    if not pcall(filesystem.writefile, filePath, body) then
                        return nil
                    end
                end

                local ok, uri = pcall(customAsset, filePath)

                return if ok and type(uri) == 'string'then uri else nil
            end
            local function avatarFilePath(userId: number): string
                return CACHE_ASSETS .. '/avatar_' .. tostring(userId) .. '.png'
            end
            local function decodeThumbnailUrl(body: string): string?
                local httpService = services.getService('HttpService')
                local ok, parsed = pcall(function()
                    return httpService:JSONDecode(body)
                end)

                if not ok or type(parsed) ~= 'table' then
                    return nil
                end

                local data = (parsed::any).data

                if type(data) ~= 'table' then
                    return nil
                end

                local entry = (data::any)[1]

                if type(entry) ~= 'table' then
                    return nil
                end
                if entry.state == 'Completed' and type(entry.imageUrl) == 'string' then
                    return entry.imageUrl
                end

                return nil
            end
            local function fetchAndCacheAvatar(userId: number): string?
                local cdnUrl: string? = nil

                for attempt = 1, 4 do
                    local url = string.format(THUMB_ENDPOINT, userId)
                    local cacheKey = 'thumb:' .. tostring(userId)
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

                if not cdnUrl then
                    return nil
                end

                return cacheFile(avatarFilePath(userId), cdnUrl, 'avatar_' .. tostring(userId))
            end

            function imageCache.preload(
                manifest: {[number]: string},
                onSettled: OnSettled?
            ): (boolean,number)
                local manifestSize = 0

                for _ in manifest do
                    manifestSize += 1
                end

                if IS_STUDIO then
                    if onSettled then
                        task.defer(onSettled, 0)
                    end

                    return true, 0
                end
                if not getCustomAssetFn() then
                    if onSettled then
                        task.defer(onSettled, manifestSize)
                    end

                    return false, manifestSize
                end

                local rewrites = imageCache.rewrites

                table.clear(rewrites)

                local function settle()
                    if not onSettled then
                        return
                    end

                    local failed = 0

                    for id in manifest do
                        if not rewrites[id] then
                            failed += 1
                        end
                    end

                    onSettled(failed)
                end

                local pending = 0
                local missing = 0
                local spawning = true

                for id, url in manifest do
                    local filePath = CACHE_ASSETS .. '/' .. tostring(id) .. '.png'
                    local uri: string? = nil

                    if filesystem.isfile(filePath) then
                        local customAsset = getCustomAssetFn()

                        if customAsset then
                            local ok, res = pcall(customAsset, filePath)

                            uri = if ok and type(res) == 'string'then res else nil
                        end
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

                if pending == 0 then
                    settle()
                end

                return missing == 0, missing
            end
            function imageCache.avatar(userId: number, onReady: AvatarReady?): string
                if IS_STUDIO then
                    local uri = string.format('rbxthumb://type=AvatarHeadShot&id=%d&w=48&h=48', userId)

                    if onReady then
                        task.defer(onReady, uri)
                    end

                    return uri
                end
                if typeof(filesystem.isfile) ~= 'function' then
                    return ''
                end

                local filePath = avatarFilePath(userId)

                if filesystem.isfile(filePath) then
                    local customAsset = getCustomAssetFn()

                    if customAsset then
                        local ok, uri = pcall(customAsset, filePath)

                        if ok and type(uri) == 'string' then
                            return uri
                        end
                    end
                end
                if onReady then
                    task.spawn(function()
                        local uri = fetchAndCacheAvatar(userId)

                        if uri then
                            onReady(uri)
                        end
                    end)
                end

                return ''
            end

            return imageCache
        end)()
    end,
    [34] = function()
        local wax, script, require = ImportGlobals(34)
        local ImportGlobals

        return (function(...)
            local HapticEngine = {}

            HapticEngine.__index = HapticEngine

            local HAS_HAPTIC: boolean = (function(): boolean
                local ok = pcall(function()
                    local probe = Instance.new('HapticEffect')

                    probe:Destroy()
                end)

                return ok
            end)()

            local function tryType(name: string): Enum.HapticEffectType?
                local ok, value = pcall(function()
                    return (Enum.HapticEffectType::any)[name]
                end)

                if ok and typeof(value) == 'EnumItem' then
                    return value::Enum.HapticEffectType
                end

                return nil
            end

            local CLICK_TYPE = tryType('UIHover') or tryType('UIClick') or tryType('UISelect')
            local NOTIFY_TYPE = tryType('UIClick') or tryType('UINotification') or tryType('UIHover')
            local engine = {enabled = true}
            local _container: Instance? = nil
            local _clickEffect: HapticEffect? = nil
            local _notifyEffect: HapticEffect? = nil

            local function makePreset(parent: Instance, type_: Enum.HapticEffectType?): HapticEffect?
                if not HAS_HAPTIC then
                    return nil
                end

                local ok, effect = pcall(function()
                    local e = Instance.new('HapticEffect')

                    if type_ then
                        e.Type = type_
                    end

                    e.Parent = parent

                    return e
                end)

                return if ok then(effect::HapticEffect)else nil
            end

            function engine.setEnabled(v: boolean): ()
                engine.enabled = v == true
            end
            function engine.IsEnabled(): boolean
                return engine.enabled
            end
            function engine.setContainer(gui: Instance)
                if not HAS_HAPTIC then
                    return
                end

                engine.teardown()

                _container = gui
                _clickEffect = makePreset(gui, CLICK_TYPE)
                _notifyEffect = makePreset(gui, NOTIFY_TYPE)
            end
            function engine.releaseContainer(gui: Instance)
                if _container ~= gui then
                    return
                end

                engine.teardown()

                _container = nil
            end
            function engine.click()
                if not engine.enabled or not _clickEffect then
                    return
                end

                pcall(function()
                    _clickEffect:Play()
                end)
            end
            function engine.notify()
                if not engine.enabled or not _notifyEffect then
                    return
                end

                pcall(function()
                    _notifyEffect:Play()
                end)
            end
            function engine.teardown()
                if _clickEffect then
                    pcall(function()
                        _clickEffect:Destroy()
                    end)

                    _clickEffect = nil
                end
                if _notifyEffect then
                    pcall(function()
                        _notifyEffect:Destroy()
                    end)

                    _notifyEffect = nil
                end
            end

            return engine
        end)()
    end,
    [11] = function()
        local wax, script, require = ImportGlobals(11)
        local ImportGlobals

        return (function(...)
            local constants = require(script.Parent.Parent.utility.constants)
            local tween = require(script.Parent.Parent.utility.tween)
            local flags = require(script.Parent.Parent.utility.flags)
            local runtime = require(script.Parent.Parent.utility.runtime)
            local textMetrics = require(script.Parent.Parent.utility.textMetrics)
            local element = require(script.Parent.Parent.utility.element)
            local themeUtil = require(script.Parent.Parent.utility.theme)
            local variables = require(script.Parent.Parent.utility.variables)
            local hapticEngine = require(script.Parent.Parent.utility.HapticEngine)
            local moveable = require(script.Parent.Parent.utility.moveable)
            local lockable = require(script.Parent.Parent.utility.lockable)

            export type InputProps = {name: string?, description: string?, flag: string?, value: string?, placeholder: string?, numeric: boolean?, clearOnFocus: boolean?, enterOnly: boolean?, callback: ((value:string) -> ())?}
            export type Input = {value: string, _frame: Frame, Set: (self:Input, value:string, skipCallback:boolean?) -> (), Destroy: (self:Input) -> ()}

            local Input = {}

            Input.__index = Input

            local function parseExp(text: string): number?
                local a, b = text:match('^([%d%.%-]+)%^([%d%.%-]+)$')

                if a and b then
                    local na, nb = tonumber(a), tonumber(b)

                    if na and nb then
                        return na ^ nb
                    end
                end

                return tonumber(text)
            end

            function Input.new(
                props: InputProps,
                theme: {[string]: any},
                parent: Instance
            ): Input
                local name = props.name or 'Input'
                local flagKey = props.flag
                local placeholder = props.placeholder or 'Enter text...'
                local isNumeric = props.numeric == true
                local clearOnFocus = props.clearOnFocus == true
                local enterOnly = props.enterOnly == true
                local callback = props.callback
                local initValue: string = if flagKey and flags:Get(flagKey) ~= nil then tostring(flags:Get(flagKey))else(props.value or '')
                local frame, stroke, gradient = element.makeFrame('Input_' .. name, theme, parent, constants.elementHeight)
                local textContainer = Instance.new('Frame')

                textContainer.Name = 'TextContainer'
                textContainer.Position = UDim2.new(0, 12, 0.5, 0)
                textContainer.AnchorPoint = Vector2.new(0, 0.5)
                textContainer.Size = UDim2.new(1, -98, 1, -8)
                textContainer.BackgroundTransparency = 1
                textContainer.BorderSizePixel = 0
                textContainer.Parent = frame

                local titleLabel = Instance.new('TextLabel')

                titleLabel.Name = 'Title'
                titleLabel.Size = UDim2.fromScale(1, 1)
                titleLabel.BackgroundTransparency = 1
                titleLabel.Text = name
                titleLabel.TextColor3 = theme.ContentColor or Color3.fromHex('#ffffff')
                titleLabel.TextSize = 13
                titleLabel.FontFace = theme.Font or constants.DEFAULT_FONT_MEDIUM
                titleLabel.TextXAlignment = Enum.TextXAlignment.Left
                titleLabel.TextYAlignment = Enum.TextYAlignment.Center
                titleLabel.TextTruncate = Enum.TextTruncate.AtEnd
                titleLabel.Parent = textContainer

                local pill = Instance.new('Frame')

                pill.Name = 'FieldPill'
                pill.AnchorPoint = Vector2.new(1, 0.5)
                pill.Position = UDim2.new(1, -12, 0.5, 0)
                pill.Size = UDim2.fromOffset(80, 26)
                pill.BackgroundColor3 = theme.FieldBackground or Color3.fromRGB(255, 255, 255)
                pill.BackgroundTransparency = theme.FieldTransparency or 0.9
                pill.BorderSizePixel = 0
                pill.ZIndex = 2
                pill.Parent = frame

                do
                    local c = Instance.new('UICorner')

                    c.CornerRadius = UDim.new(1, 0)
                    c.Parent = pill
                end

                local pillStroke = Instance.new('UIStroke')

                pillStroke.Color = theme.ElementStroke or Color3.fromHex('#2b2b2b')
                pillStroke.Thickness = 1
                pillStroke.Transparency = 0.5
                pillStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                pillStroke.Parent = pill

                local textBox = Instance.new('TextBox')

                textBox.Name = 'Box'
                textBox.AnchorPoint = Vector2.new(0.5, 0.5)
                textBox.Position = UDim2.fromScale(0.5, 0.5)
                textBox.Size = UDim2.new(1, -16, 1, 0)
                textBox.BackgroundTransparency = 1
                textBox.PlaceholderText = placeholder
                textBox.PlaceholderColor3 = theme.PlaceholderColor or Color3.fromHex('#9d9d9d')
                textBox.Text = initValue
                textBox.TextColor3 = theme.ContentColor or Color3.fromHex('#ffffff')
                textBox.TextSize = 12
                textBox.FontFace = theme.Font or constants.DEFAULT_FONT
                textBox.TextXAlignment = Enum.TextXAlignment.Center
                textBox.TextTruncate = Enum.TextTruncate.AtEnd
                textBox.ClearTextOnFocus = clearOnFocus
                textBox.TextTransparency = 0.4
                textBox.BorderSizePixel = 0
                textBox.ZIndex = 3
                textBox.Parent = pill

                local self = setmetatable({}, Input)::Input

                self.value = initValue
                self._frame = frame

                local s = self::any

                s._textBox = textBox
                s._flag = flagKey
                s._callback = callback
                s._stroke = stroke
                s._titleLabel = titleLabel

                local pillTween: Tween? = nil

                local function sizePill(animate: boolean)
                    local shown = if textBox.Text ~= ''then textBox.Text else placeholder
                    local txtWidth = textMetrics.textWidth(constants.DEFAULT_FONT_MEDIUM, 12, shown)
                    local frameW = frame.AbsoluteSize.X
                    local isNarrow = frameW > 0 and frameW < 380
                    local maxW = if isNarrow then math.clamp(math.floor(frameW * 0.44), 65, 120)else 220
                    local minW = if isNarrow then 52 else 70
                    local targetWidth = math.clamp(math.floor(txtWidth + 24), minW, maxW)

                    if pillTween then
                        tween.cancel(pillTween)

                        pillTween = nil
                    end

                    pillTween = tween.resizePill(pill, UDim2.fromOffset(targetWidth, 26), animate)
                    s._pillTween = pillTween
                    textContainer.Size = UDim2.new(1, -(targetWidth + 28), 1, -8)
                end

                s._sizePill = sizePill

                sizePill(false)
                frame:GetPropertyChangedSignal('AbsoluteSize'):Connect(function()
                    sizePill(false)
                end)

                local hitBtn = Instance.new('TextButton')

                hitBtn.Name = 'Interact'
                hitBtn.Size = UDim2.fromScale(1, 1)
                hitBtn.BackgroundTransparency = 1
                hitBtn.Text = ''
                hitBtn.AutoButtonColor = false
                hitBtn.ZIndex = 1
                hitBtn.Parent = frame

                hitBtn.Activated:Connect(function()
                    textBox:CaptureFocus()
                end)
                textBox:GetPropertyChangedSignal('Text'):Connect(function()
                    if isNumeric then
                        local cleaned = textBox.Text:gsub('[^%d%.%-eE%^]', '')

                        if cleaned ~= textBox.Text then
                            textBox.Text = cleaned

                            return
                        end
                    end

                    sizePill(true)
                end)
                textBox.Focused:Connect(function()
                    tween.fire(textBox, constants.tweenFocus, {TextTransparency = 0})
                    tween.fire(pillStroke, constants.tweenFocus, {
                        Color = theme.AccentColor or Color3.fromHex('#4cc2ff'),
                        Transparency = 0,
                    })
                    tween.fire(stroke, constants.tweenFocus, {
                        Color = theme.ElementStrokeHover or theme.AccentColor or Color3.fromHex('#4cc2ff'),
                    })
                end)
                textBox.FocusLost:Connect(function(enterPressed)
                    tween.fire(textBox, constants.tweenFocus, {TextTransparency = 0.4})

                    local raw = textBox.Text

                    if isNumeric then
                        local n = parseExp(raw)

                        raw = if n then tostring(n)else self.value
                        textBox.Text = raw
                    end

                    local isMobile = runtime.userInputService.TouchEnabled and not runtime.userInputService.KeyboardEnabled
                    local skip = if enterOnly and not isMobile then not enterPressed else false

                    self:Set(raw, skip)
                    tween.fire(pillStroke, constants.tweenFast, {
                        Color = theme.ElementStroke or Color3.fromHex('#2b2b2b'),
                        Transparency = 0.5,
                    })
                    tween.fire(stroke, constants.tweenFast, {
                        Color = theme.ElementStroke or Color3.fromHex('#2b2b2b'),
                    })
                end)

                s._themeUnsub = themeUtil.subscribe(function(t)
                    theme = t
                    s._theme = t
                    frame.BackgroundTransparency = t.ElementTransparency or 0
                    titleLabel.TextColor3 = t.ContentColor or Color3.fromHex('#ffffff')
                    titleLabel.FontFace = t.Font or constants.DEFAULT_FONT_MEDIUM
                    pill.BackgroundColor3 = t.FieldBackground or Color3.fromRGB(255, 255, 255)
                    pill.BackgroundTransparency = t.FieldTransparency or 0.9
                    pillStroke.Color = t.ElementStroke or Color3.fromHex('#2b2b2b')
                    stroke.Color = t.ElementStroke or Color3.fromHex('#2b2b2b')
                    stroke.Transparency = t.ElementStrokeTransparency or 0
                    textBox.PlaceholderColor3 = t.PlaceholderColor or Color3.fromHex('#9d9d9d')
                    textBox.TextColor3 = t.ContentColor or Color3.fromHex('#ffffff')
                    textBox.FontFace = t.Font or constants.DEFAULT_FONT
                    gradient.Color = t.ElementGradient or ColorSequence.new({
                        ColorSequenceKeypoint.new(0, Color3.fromHex('#2e2e2e')),
                        ColorSequenceKeypoint.new(1, Color3.fromHex('#181818')),
                    })
                end, frame)

                return self
            end
            function Input:Set(value: string, skipCallback: boolean?)
                local s = self::any

                if s.locked and not skipCallback then
                    return
                end

                local textBox: TextBox = s._textBox

                self.value = value

                if textBox.Text ~= value then
                    textBox.Text = value
                end
                if s._sizePill then
                    s._sizePill(true)
                end
                if s._flag then
                    flags:Set(s._flag, value)
                end
                if not skipCallback and s._callback then
                    task.spawn(s._callback, value)
                end
            end
            function Input:_setShown(shown: boolean, animate: boolean?)
                local s = self::any
                local t = (s._theme or {})::{[string]: any}
                local info = if animate ~= false then constants.tweenNormal else nil
                local frameTrans = if shown then(t.ElementTransparency or 0)else 1
                local strokeTrans = if shown then(t.ElementStrokeTransparency or 0)else 1
                local textTrans = if shown then 0 else 1

                if info then
                    tween.play(self._frame, info, {BackgroundTransparency = frameTrans})

                    if s._stroke then
                        tween.play(s._stroke, info, {Transparency = strokeTrans})
                    end
                    if s._titleLabel then
                        tween.play(s._titleLabel, info, {TextTransparency = textTrans})
                    end
                else
                    self._frame.BackgroundTransparency = frameTrans

                    if s._stroke then
                        s._stroke.Transparency = strokeTrans
                    end
                    if s._titleLabel then
                        s._titleLabel.TextTransparency = textTrans
                    end
                end
            end
            function Input:Destroy()
                local s = self::any

                if s._pillTween then
                    tween.cancel(s._pillTween)

                    s._pillTween = nil
                end
                if s._themeUnsub then
                    s._themeUnsub()
                end
                if s._descriptor then
                    s._descriptor:Destroy()
                end

                self._frame:Destroy()
            end

            moveable(Input)
            lockable(Input)

            return Input
        end)()
    end,
    [37] = function()
        local wax, script, require = ImportGlobals(37)
        local ImportGlobals

        return (function(...)
            local constants = {}

            constants.tweenFast = TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
            constants.tweenNormal = TweenInfo.new(0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
            constants.tweenSlow = TweenInfo.new(0.45, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
            constants.pillResizeInfo = TweenInfo.new(0.35, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
            constants.tweenFocus = TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
            constants.notifySlideIn = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
            constants.notifySlideOut = TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
            constants.zIndex = {
                base = 1,
                element = 10,
                dropdown = 50,
                elementLock = 60,
                elementLockContent = 65,
                notification = 200,
                windowChrome = 500,
                drag = 1000,
                popup = 2000,
                toast = 2000,
                toastContent = 2001,
                tooltip = 2500,
                restoreContent = 100001,
                restoreInteract = 100002,
            }
            constants.displayOrder = {
                window = 99990,
                notification = 99995,
                popup = 100000,
                loading = 100010,
            }
            constants.windowSize = Vector2.new(720, 580)
            constants.windowMinSize = Vector2.new(560, 440)
            constants.sidebarWidth = 164
            constants.elementHeight = 38
            constants.elementPadding = 6
            constants.elementCornerRadius = UDim.new(0, 6)
            constants.sectionPadding = 14
            constants.contentPadding = 10
            constants.DEFAULT_FONT = Font.new('rbxasset://fonts/families/GothamSSm.json')
            constants.DEFAULT_FONT_MEDIUM = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.Medium)
            constants.DEFAULT_FONT_SEMI = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold)
            constants.DEFAULT_FONT_BOLD = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.Bold)
            constants.DEFAULT_FONT_MONO = Font.new('rbxasset://fonts/families/RobotoMono.json')
            constants.elementCornerRadius = UDim.new(0, 6)
            constants.contentPadding = 10
            constants.COLORS = {
                ACCENT = Color3.fromHex('#4cc2ff'),
                ACCENT_DARK = Color3.fromHex('#0093fb'),
                STROKE = Color3.fromHex('#2b2b2b'),
                STROKE_SURFACE = Color3.fromHex('#303038'),
                TEXT = Color3.fromHex('#ffffff'),
                TEXT_SUBTLE = Color3.fromHex('#8a8a92'),
                TEXT_MUTED = Color3.fromHex('#9d9d9d'),
                TEXT_DISABLED = Color3.fromHex('#555555'),
                TEXT_FAINT = Color3.fromHex('#737380'),
                SURFACE = Color3.fromHex('#1a1a1a'),
                SURFACE_ALT = Color3.fromHex('#1e1e1e'),
                SURFACE_HOVER = Color3.fromHex('#252525'),
                TITLE_BAR = Color3.fromHex('#111114'),
                FIELD_BG = Color3.fromRGB(255, 255, 255),
                ERROR = Color3.fromHex('#ff4f58'),
                SUCCESS = Color3.fromHex('#3ecf8e'),
                WARNING = Color3.fromHex('#f5a524'),
            }
            constants.DEFAULT_ELEMENT_GRADIENT = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromHex('#2e2e2e')),
                ColorSequenceKeypoint.new(1, Color3.fromHex('#181818')),
            })
            constants.DEFAULT_FIELD_TRANSPARENCY = 0.9
            constants.loading = {
                minDuration = 0.6,
                defaultTaskWeight = 1,
                cancelledColor = Color3.fromHex('#f5a524'),
                errorColor = Color3.fromHex('#ff4f58'),
                progressTickInterval = 0.05,
                tweenFadeIn = TweenInfo.new(0.32, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                tweenMorph = TweenInfo.new(0.48, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
                tweenContent = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                tweenProgress = TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                tweenStatus = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            }
            constants.statAccents = {
                positive = {
                    fill = ColorSequence.new(Color3.fromRGB(0, 170, 127), Color3.fromRGB(0, 134, 98)),
                    stroke = ColorSequence.new(Color3.fromRGB(0, 213, 156), Color3.fromRGB(0, 189, 135)),
                },
                negative = {
                    fill = ColorSequence.new(Color3.fromRGB(172, 47, 47), Color3.fromRGB(135, 37, 37)),
                    stroke = ColorSequence.new(Color3.fromRGB(255, 75, 75), Color3.fromRGB(244, 67, 67)),
                },
                neutral = {
                    fill = ColorSequence.new(Color3.fromRGB(0, 170, 127), Color3.fromRGB(0, 134, 98)),
                    stroke = ColorSequence.new(Color3.fromRGB(0, 213, 156), Color3.fromRGB(0, 189, 135)),
                },
            }
            constants.icons = {
                close = 83277910885129,
                minimise = 108115485663409,
                settings = 129180860773723,
            }

            return constants
        end)()
    end,
    [61] = function()
        local wax, script, require = ImportGlobals(61)
        local ImportGlobals

        return (function(...)
            local services = {}

            function services.getService(name: string): Instance
                local service = game:GetService(name)

                return if typeof(cloneref) == 'function'then cloneref(service)else service
            end

            return services
        end)()
    end,
    [45] = function()
        local wax, script, require = ImportGlobals(45)
        local ImportGlobals

        return (function(...)
            local functions = {}
            local textMetrics = require(script.Parent.textMetrics)
            local colors = require(script.Parent.colors)
            local flags = require(script.Parent.flags)

            functions.textWidth = textMetrics.textWidth
            functions.textHeight = textMetrics.textHeight
            functions.contrastColor = colors.contrastColor
            functions.contrastText = colors.contrastText
            functions.toColorSequence = colors.toColorSequence
            functions.toColor3 = colors.toColor3
            functions.flags = flags

            return functions
        end)()
    end,
    [42] = function()
        local wax, script, require = ImportGlobals(42)
        local ImportGlobals

        return (function(...)
            local filesystem = require(script.Parent.filesystem)
            local path = require(script.Parent.path)
            local DEFAULT_ROOT = 'workspace/Delirium'
            local FileSystemManager = {}

            FileSystemManager.__index = FileSystemManager

            export type FileSystemManager = {root: string, assets: string, getPath: (self:FileSystemManager, subpath:string?) -> string, getAssetsFolder: (self:FileSystemManager, subfolder:string?) -> string, getRootFolder: (self:FileSystemManager) -> string}

            function FileSystemManager.new(name: string?): FileSystemManager
                local root = name or DEFAULT_ROOT
                local self = setmetatable({
                    root = root,
                    assets = root .. '/assets',
                }, FileSystemManager)::any

                pcall(filesystem.ensureDir, self.root)
                pcall(filesystem.ensureDir, self.assets)

                return self
            end
            function FileSystemManager:getPath(subpath: string?): string
                return path.join(self.root, if subpath then path.sanitizeFile(subpath)else nil)
            end
            function FileSystemManager:getAssetsFolder(subfolder: string?): string
                if subfolder then
                    local sub = path.join(self.assets, path.sanitizeFolder(subfolder))

                    pcall(filesystem.ensureDir, sub)

                    return sub
                end

                return self.assets
            end
            function FileSystemManager:getRootFolder(): string
                return self.root
            end

            return FileSystemManager
        end)()
    end,
    [49] = function()
        local wax, script, require = ImportGlobals(49)
        local ImportGlobals

        return (function(...)
            local layouts = {}

            export type Mode = 'sidebar'
            export type Layout = {mode: Mode, topbarHeight: number, footerHeight: number, chromeHeight: number, rowHeight: number, contentPadding: number}

            layouts.sidebar = {
                mode = 'sidebar'::Mode,
                topbarHeight = 44,
                footerHeight = 40,
                chromeHeight = 84,
                rowHeight = 36,
                contentPadding = 10,
            }::Layout

            function layouts.get(mode: unknown): Layout?
                if mode == 'sidebar' then
                    return layouts.sidebar
                end

                return nil
            end

            return layouts
        end)()
    end,
    [60] = function()
        local wax, script, require = ImportGlobals(60)
        local ImportGlobals

        return (function(...)
            local filesystem = require(script.Parent.filesystem)
            local flags = require(script.Parent.flags)
            local services = require(script.Parent.services)
            local pathUtil = require(script.Parent.path)
            local HttpService = services.getService('HttpService')::HttpService
            local MarketplaceService = services.getService('MarketplaceService')::MarketplaceService

            export type InitOptions = {folder: string?, subFolder: string?, profile: string?, autoSave: boolean?, autoLoad: boolean?, debounce: number?, buildConfigTab: boolean?, configTabName: string?, configTabIcon: string?, onLoaded: ((count:number) -> ())?, onSaved: ((ok:boolean) -> ())?}

            local SaveManager = {}::any

            SaveManager.__index = SaveManager

            local _initialized: boolean = false
            local _folder: string = 'Workspace/Delirium'
            local _subFolder: string? = nil
            local _activeProfile: string = 'default'
            local _detectedGame: string? = nil
            local _autoSaveOn: boolean = false
            local _autoLoadOn: boolean = true
            local _debounceSecs: number = 0.4
            local _buildConfigTab: boolean = false
            local _configTabName: string = 'Config'
            local _configTabIcon: string = 'lucide:save'
            local _onLoaded: ((count:number) -> ())? = nil
            local _onSaved: ((ok:boolean) -> ())? = nil
            local _registry: {[string]: {set: (value:any, skip:boolean?) -> ()}} = {}
            local _ignored: {[string]: boolean} = {}
            local _saveHook: (() -> ())? = nil
            local _loading: boolean = false
            local _suspended: boolean = false
            local _savePending: boolean = false
            local _autoLoadedThisRun: boolean = false
            local _configTabAttached: {[any]: boolean} = {}
            local AUTOLOAD_GRACE = 1.5

            local function pick(t: any, ...: string): any
                for _, k in ipairs({...})do
                    if t[k] ~= nil then
                        return t[k]
                    end
                end

                return nil
            end
            local function sanitizeName(name: string): string
                return pathUtil.sanitizeFile(name)
            end
            local function getGameName(): string
                if _detectedGame then
                    return _detectedGame
                end

                local resolved: string? = nil
                local placeId = game.PlaceId

                pcall(function()
                    local info = MarketplaceService:GetProductInfo(placeId)

                    if info and type(info.Name) == 'string' and #info.Name > 0 then
                        resolved = sanitizeName(info.Name)
                    end
                end)

                if not resolved or #resolved == 0 then
                    resolved = tostring(placeId)
                end

                _detectedGame = resolved

                return resolved::string
            end
            local function resolveProfile(name: string?): string
                if not name then
                    return _activeProfile
                end

                local trimmed = (name::string):match('^%s*(.-)%s*$') or ''

                return if#trimmed > 0 then trimmed else'default'
            end
            local function getConfigDir(): string
                local sub: string? = nil

                if _subFolder ~= nil then
                    if #_subFolder > 0 then
                        sub = _subFolder
                    end
                else
                    sub = getGameName()
                end
                if sub and #sub > 0 then
                    return _folder .. '/configs/' .. sub
                end

                return _folder .. '/configs'
            end
            local function profilePath(name: string?): string
                return getConfigDir() .. '/' .. pathUtil.sanitizeFile(resolveProfile(name)) .. '.json'
            end
            local function metaPath(): string
                return getConfigDir() .. '/_meta.json'
            end
            local function readMeta(): {[string]: any}
                local p = metaPath()
                local ok, raw = pcall(function()
                    if filesystem.isfile(p) then
                        return filesystem.readfile(p)
                    end

                    return nil
                end)

                if not ok or not raw or raw == '' then
                    return {}
                end

                local decOk, data = pcall(HttpService.JSONDecode, HttpService, raw)

                if not decOk or type(data) ~= 'table' then
                    return {}
                end

                return data
            end
            local function writeMeta()
                local data = {
                    autoSave = _autoSaveOn,
                    autoLoad = _autoLoadOn,
                    lastProfile = _activeProfile,
                }
                local ok, encoded = pcall(HttpService.JSONEncode, HttpService, data)

                if not ok or type(encoded) ~= 'string' then
                    return
                end

                pcall(filesystem.ensureDir, getConfigDir())
                pcall(filesystem.writefile, metaPath(), encoded)
            end
            local function serializeValue(v: any): any
                local t = typeof(v)

                if t == 'EnumItem' then
                    local enumName = 'Unknown'

                    pcall(function()
                        enumName = v.EnumType.Name
                    end)

                    return {
                        __type = 'EnumItem',
                        enumType = enumName,
                        name = v.Name,
                    }
                elseif t == 'Color3' then
                    return {
                        __type = 'Color3',
                        r = v.R,
                        g = v.G,
                        b = v.B,
                    }
                end

                return v
            end
            local function deserializeValue(v: any): any
                if type(v) ~= 'table' or not v.__type then
                    return v
                end
                if v.__type == 'EnumItem' then
                    local ok, result = pcall(function()
                        return (Enum::any)[v.enumType][v.name]
                    end)

                    return if ok and result then result else nil
                elseif v.__type == 'Color3' then
                    return Color3.new(v.r or 0, v.g or 0, v.b or 0)
                end

                return v
            end
            local function atomicWrite(path: string, content: string): boolean
                local tempPath = path .. '.saving'
                local targetDir = getConfigDir()

                pcall(filesystem.ensureDir, targetDir)

                if not pcall(filesystem.writefile, tempPath, content) then
                    return false
                end

                local rOk, readBack = pcall(filesystem.readfile, tempPath)

                if not rOk or readBack ~= content then
                    pcall(filesystem.delfile, tempPath)

                    return false
                end

                local promOk = pcall(filesystem.writefile, path, content)

                pcall(filesystem.delfile, tempPath)

                return promOk
            end
            local function scheduleSave()
                if _savePending then
                    return
                end

                _savePending = true

                task.delay(_debounceSecs, function()
                    _savePending = false

                    if _loading or not _autoSaveOn then
                        return
                    end

                    SaveManager:Save(_activeProfile)
                end)
            end
            local function installSaveHook()
                if _saveHook then
                    return
                end

                _saveHook = flags:Subscribe(function(
                    key: string,
                    _value: any
                )
                    if _loading or _suspended then
                        return
                    end
                    if not _autoSaveOn then
                        return
                    end
                    if _ignored[key] then
                        return
                    end
                    if key:sub(1, 1) == '_' then
                        return
                    end

                    scheduleSave()
                end)
            end
            local function fnv1a(s: string): number
                local h: number = 2166136261

                for i = 1, #s do
                    h = bit32.bxor(h, string.byte(s, i))
                    h = bit32.band(h * 16777619, 0xffffffff)
                end

                return h
            end

            function SaveManager.deriveFlagFromName(label: string): string
                if #label == 0 then
                    return ''
                end

                local sanitized = label:lower():gsub('%s+', '_'):gsub('[^%w_]', ''):sub(1, 48)

                return if#sanitized > 0 then sanitized else string.format('Flag%08x', fnv1a(label))
            end
            function SaveManager:Init(opts: InitOptions?)
                opts = opts or {}

                local folder = pick(opts, 'folder', 'Folder', 'SetFolder', 'setFolder')
                local subFolder = pick(opts, 'subFolder', 'SubFolder', 'SetSubFolder', 'setSubFolder')
                local profile = pick(opts, 'profile', 'Profile', 'activeProfile')
                local debounce = pick(opts, 'debounce', 'Debounce', 'SetDebounceSeconds', 'debounceSeconds')
                local autoSave = pick(opts, 'autoSave', 'AutoSave', 'autosave')
                local autoLoad = pick(opts, 'autoLoad', 'AutoLoad', 'autoload')
                local buildTab = pick(opts, 'buildConfigTab', 'BuildConfigTab', 'configTab')
                local tabName = pick(opts, 'configTabName', 'ConfigTabName', 'tabName')
                local tabIcon = pick(opts, 'configTabIcon', 'ConfigTabIcon', 'tabIcon')

                if type(folder) == 'string' and #folder > 0 then
                    _folder = folder
                end
                if subFolder ~= nil then
                    if type(subFolder) == 'string' and #subFolder > 0 then
                        _subFolder = sanitizeName(subFolder)
                    elseif subFolder == '' then
                        _subFolder = ''
                    end
                end
                if type(profile) == 'string' and #profile > 0 then
                    _activeProfile = resolveProfile(profile)
                end
                if type(debounce) == 'number' and debounce >= 0 then
                    _debounceSecs = debounce
                end
                if type(autoSave) == 'boolean' then
                    _autoSaveOn = autoSave
                end
                if type(autoLoad) == 'boolean' then
                    _autoLoadOn = autoLoad
                end
                if type(buildTab) == 'boolean' then
                    _buildConfigTab = buildTab
                end
                if type(tabName) == 'string' and #tabName > 0 then
                    _configTabName = tabName
                end
                if type(tabIcon) == 'string' and #tabIcon > 0 then
                    _configTabIcon = tabIcon
                end
                if type(opts.onLoaded) == 'function' then
                    _onLoaded = opts.onLoaded
                end
                if type(opts.onSaved) == 'function' then
                    _onSaved = opts.onSaved
                end

                local meta = readMeta()

                if type(meta.autoSave) == 'boolean' then
                    _autoSaveOn = meta.autoSave
                end
                if type(meta.autoLoad) == 'boolean' then
                    _autoLoadOn = meta.autoLoad
                end
                if type(meta.lastProfile) == 'string' and #meta.lastProfile > 0 then
                    _activeProfile = meta.lastProfile
                end

                _initialized = true

                if _autoSaveOn then
                    installSaveHook()
                end

                return self
            end
            function SaveManager:SetFolder(name: string)
                assert(type(name) == 'string' and #name > 0, 'SaveManager:SetFolder \u{2014} must be non-empty')

                _folder = name
            end
            function SaveManager:SetSubFolder(name: string?)
                if name == nil then
                    _subFolder = nil
                elseif #name > 0 then
                    _subFolder = sanitizeName(name)
                else
                    _subFolder = ''
                end
            end

            SaveManager.SetSubfolder = SaveManager.SetSubFolder

            function SaveManager:SetDebounceSeconds(seconds: number)
                assert(type(seconds) == 'number' and seconds >= 0, 'SaveManager:SetDebounceSeconds \u{2014} must be >= 0')

                _debounceSecs = seconds
            end
            function SaveManager:SetAutoSaveEnabled(enabled: boolean)
                _autoSaveOn = enabled == true

                if _autoSaveOn then
                    installSaveHook()
                end

                writeMeta()
            end
            function SaveManager:IsAutoSaveEnabled(): boolean
                return _autoSaveOn
            end
            function SaveManager:SetAutoLoadEnabled(enabled: boolean)
                _autoLoadOn = enabled == true

                writeMeta()
            end
            function SaveManager:IsAutoLoadEnabled(): boolean
                return _autoLoadOn
            end
            function SaveManager:GetFolderPath(): string
                return getConfigDir()
            end
            function SaveManager:Register(flag: string, target: any)
                assert(type(flag) == 'string' and #flag > 0, 'SaveManager:Register \u{2014} flag must be non-empty')

                local entry: {set: (value:any, skip:boolean?) -> ()}

                if type(target) == 'function' then
                    entry = {set = target}
                elseif typeof(target) == 'table' and target.Set then
                    local el = target

                    entry = {
                        set = function(value: any, skip: boolean?)
                            el:Set(value, skip)
                        end,
                    }
                else
                    error('SaveManager:Register \u{2014} target must be a function or component with :Set', 2)
                end

                _registry[flag] = entry
            end
            function SaveManager:Ignore(flag: string)
                _ignored[flag] = true
            end
            function SaveManager:IgnoreMany(mapOrList: any)
                if type(mapOrList) ~= 'table' then
                    return
                end

                for k, v in mapOrList do
                    if type(k) == 'number' and type(v) == 'string' then
                        _ignored[v] = true
                    elseif type(k) == 'string' and v == true then
                        _ignored[k] = true
                    end
                end
            end
            function SaveManager:Save(profileName: string?): boolean
                local snapshot = flags:GetAll()
                local data: {[string]: any} = {}

                for k, v in snapshot do
                    if not _ignored[k] and k:sub(1, 1) ~= '_' then
                        data[k] = serializeValue(v)
                    end
                end

                local ok, encoded = pcall(function()
                    return HttpService:JSONEncode(data)
                end)

                if not ok or type(encoded) ~= 'string' then
                    if _onSaved then
                        pcall(_onSaved, false)
                    end

                    return false
                end

                local wrote = atomicWrite(profilePath(profileName), encoded)

                if wrote and profileName and #profileName > 0 then
                    _activeProfile = resolveProfile(profileName)
                end

                writeMeta()

                if _onSaved then
                    pcall(_onSaved, wrote)
                end

                return wrote
            end
            function SaveManager:Load(profileName: string?): number
                local path = profilePath(profileName)
                local raw: string? = nil

                pcall(function()
                    if filesystem.isfile(path) then
                        raw = filesystem.readfile(path)
                    end
                end)

                if not raw or raw == '' then
                    return 0
                end

                local ok, data = pcall(HttpService.JSONDecode, HttpService, raw::string)

                if not ok or type(data) ~= 'table' then
                    return 0
                end

                _loading = true

                local count = 0

                for flag, rawValue in data do
                    if _ignored[flag] then
                        continue
                    end

                    local value = deserializeValue(rawValue)

                    if value == nil then
                        continue
                    end

                    flags:Set(flag, value)

                    local entry = _registry[flag]

                    if entry then
                        local skip = (value == false or value == '' or value == nil)

                        pcall(entry.set, value, skip)

                        count += 1
                    else
                        count += 1
                    end
                end

                _loading = false

                if profileName and #profileName > 0 then
                    _activeProfile = resolveProfile(profileName)

                    writeMeta()
                end

                return count
            end
            function SaveManager:Refresh(skipCallbacks: boolean?)
                local forceSkip = skipCallbacks == true

                for flag, entry in _registry do
                    local value = flags:Get(flag)

                    if value ~= nil then
                        local skip = forceSkip or (value == false or value == '' or value == nil)

                        pcall(entry.set, value, skip)
                    end
                end
            end
            function SaveManager:AutoLoad(): number
                if _autoLoadedThisRun then
                    return 0
                end

                _autoLoadedThisRun = true

                if not _initialized then
                    local meta = readMeta()

                    if type(meta.autoSave) == 'boolean' then
                        _autoSaveOn = meta.autoSave
                    end
                    if type(meta.autoLoad) == 'boolean' then
                        _autoLoadOn = meta.autoLoad
                    end
                    if type(meta.lastProfile) == 'string' and #meta.lastProfile > 0 then
                        _activeProfile = meta.lastProfile
                    end

                    _initialized = true
                end
                if _autoSaveOn then
                    installSaveHook()
                end
                if not _autoLoadOn then
                    return 0
                end

                _suspended = true

                local n = self:Load(_activeProfile)

                task.delay(AUTOLOAD_GRACE, function()
                    _suspended = false
                end)

                if _onLoaded then
                    pcall(_onLoaded, n)
                end

                return n
            end
            function SaveManager:List(): {string}
                local names: {string} = {}
                local targetDir = getConfigDir()

                pcall(function()
                    pcall(filesystem.ensureDir, targetDir)

                    for _, path in filesystem.listfiles(targetDir)do
                        local normalized = path:gsub('\\', '/')
                        local filename = normalized:match('([^/]+)$') or ''

                        if filename:match('%.saving$') then
                            continue
                        end

                        local name = filename:match('^(.-)%.json$')

                        if name and #name > 0 and name:sub(1, 1) ~= '_' then
                            table.insert(names, name)
                        end
                    end
                end)
                table.sort(names)

                return names
            end
            function SaveManager:Delete(profileName: string): boolean
                if not profileName or profileName == '' then
                    return false
                end

                local trimmed = resolveProfile(profileName)
                local path = profilePath(trimmed)
                local existed = pcall(function()
                    if not filesystem.isfile(path) then
                        error('not found')
                    end

                    filesystem.delfile(path)
                end)

                return existed
            end
            function SaveManager:GetActiveProfile(): string
                return _activeProfile
            end
            function SaveManager:SetActiveProfile(name: string)
                _activeProfile = resolveProfile(name)

                writeMeta()
            end
            function SaveManager:_attachConfigTabIfEnabled(window: any)
                if not _initialized or not _buildConfigTab then
                    return
                end
                if not window or window.unloaded then
                    return
                end
                if _configTabAttached[window] then
                    return
                end

                _configTabAttached[window] = true

                self:BuildConfigTab(window)
            end
            function SaveManager:BuildConfigTab(window: any)
                _ignored['_SM_input_name'] = true
                _ignored['_SM_dd_configs'] = true
                _ignored['_SM_toggle_autoSave'] = true

                local tab = window:CreateTab({
                    name = _configTabName,
                    icon = _configTabIcon,
                    columns = 2,
                })
                local colLeft = tab.Left
                local colRight = tab.Right or tab.Left

                local function listConfigs(): {string}
                    return self:List()
                end

                local secConfigs = colLeft:CreateSection({
                    name = 'Configs',
                    icon = 'lucide:folder',
                    description = 'Choose, save, or manage your configs.',
                    defaultOpen = true,
                })
                local initialList = listConfigs()
                local initialValue: string? = nil

                for _, name in initialList do
                    if name == _activeProfile then
                        initialValue = name

                        break
                    end
                end

                local ddHandle: any = secConfigs:CreateDropdown({
                    name = 'Saved Configs',
                    description = 'Pick a config to load, save, or delete.',
                    options = initialList,
                    value = initialValue,
                    placeholder = 'Select a config...',
                    flag = '_SM_dd_configs',
                    onOpen = function()
                        return listConfigs()
                    end,
                })
                local nameInput = secConfigs:CreateInput({
                    name = 'New Config Name',
                    description = 
[[Save under this name. Leave empty to overwrite the selection.]],
                    placeholder = 'e.g. pvp, farm, default',
                    flag = '_SM_input_name',
                    value = '',
                    clearOnFocus = false,
                })

                local function getSelection(): string
                    if not ddHandle then
                        return ''
                    end

                    local v = ddHandle.value

                    if type(v) == 'string' and #v > 0 then
                        return v
                    end

                    return ''
                end
                local function getTypedName(): string
                    local raw = ((nameInput::any)._textBox.Text) or ''

                    return (raw:match('^%s*(.-)%s*$')) or ''
                end
                local function refreshDropdown(selectAfter: string?)
                    if not ddHandle then
                        return
                    end

                    ddHandle:SetOptions(listConfigs())

                    if selectAfter and #selectAfter > 0 then
                        ddHandle:Set(selectAfter, true)
                    end
                end

                local secActions = colLeft:CreateSection({
                    name = 'Actions',
                    icon = 'lucide:file-cog',
                    description = 'Save, load, or delete a config.',
                    defaultOpen = true,
                })

                secActions:CreateButton({
                    name = 'Save Config',
                    description = 'Write current state to the named config (or the selection).',
                    callback = function()
                        local typed = getTypedName()
                        local target = if#typed > 0 then typed else getSelection()

                        if #target == 0 then
                            window:Notify({
                                title = 'Nothing to Save',
                                content = 'Type a config name or select one first.',
                                type = 'warning',
                                duration = 3,
                            })

                            return
                        end

                        local ok = self:Save(target)

                        if not ok then
                            window:Notify({
                                title = 'Save Failed',
                                content = "Could not write '" .. target .. "'.",
                                type = 'error',
                                duration = 3,
                            })

                            return
                        end

                        _activeProfile = target

                        writeMeta()
                        refreshDropdown(target);
                        (nameInput::any):Set('', true)
                        window:Notify({
                            title = 'Config Saved',
                            content = "Wrote '" .. target .. "'.",
                            type = 'success',
                            duration = 3,
                        })
                    end,
                })
                secActions:CreateButton({
                    name = 'Load Selected',
                    description = 'Apply the selected config to every component.',
                    callback = function()
                        local target = getSelection()

                        if #target == 0 then
                            window:Notify({
                                title = 'Nothing Selected',
                                content = 'Pick a config from the dropdown first.',
                                type = 'warning',
                                duration = 3,
                            })

                            return
                        end

                        local n = self:Load(target)

                        if n > 0 then
                            _activeProfile = target

                            writeMeta()
                            window:Notify({
                                title = 'Config Loaded',
                                content = 'Restored ' .. n .. " flag(s) from '" .. target .. "'.",
                                type = 'success',
                                duration = 3,
                            })
                        else
                            window:Notify({
                                title = 'Load Failed',
                                content = "'" .. target .. "' is empty or missing.",
                                type = 'warning',
                                duration = 3,
                            })
                        end
                    end,
                })
                secActions:CreateButton({
                    name = 'Delete Selected',
                    description = 'Permanently remove the selected config.',
                    callback = function()
                        local target = getSelection()

                        if #target == 0 then
                            window:Notify({
                                title = 'Nothing Selected',
                                content = 'Pick a config to delete first.',
                                type = 'warning',
                                duration = 3,
                            })

                            return
                        end

                        local ok = self:Delete(target)

                        if ok then
                            refreshDropdown()
                            ddHandle:Set(nil::any, true)
                            window:Notify({
                                title = 'Config Deleted',
                                content = "Removed '" .. target .. "'.",
                                type = 'info',
                                duration = 3,
                            })
                        else
                            window:Notify({
                                title = 'Delete Failed',
                                content = "Could not remove '" .. target .. "'.",
                                type = 'error',
                                duration = 3,
                            })
                        end
                    end,
                })

                local secAuto = colRight:CreateSection({
                    name = 'Auto',
                    icon = 'lucide:refresh-cw',
                    description = 'Automatic persistence and startup behavior.',
                    defaultOpen = true,
                })

                secAuto:CreateToggle({
                    name = 'Auto Save on Change',
                    description = 'Write every flag change to disk automatically.',
                    flag = '_SM_toggle_autoSave',
                    value = _autoSaveOn,
                    callback = function(enabled: boolean)
                        self:SetAutoSaveEnabled(enabled)
                        window:Notify({
                            title = if enabled then'Auto Save Enabled'else'Auto Save Disabled',
                            content = if enabled then'Changes will be written automatically.'else'Use Save Config to commit changes.',
                            type = 'info',
                            duration = 2,
                        })
                    end,
                })
                secAuto:CreateButton({
                    name = 'Set as Auto Load',
                    description = 'Load this config automatically on the next script run.',
                    callback = function()
                        local target = getSelection()

                        if #target == 0 then
                            window:Notify({
                                title = 'Nothing Selected',
                                content = 'Pick a config from the dropdown first.',
                                type = 'warning',
                                duration = 3,
                            })

                            return
                        end

                        self:SetActiveProfile(target)
                        self:SetAutoLoadEnabled(true)
                        window:Notify({
                            title = 'Auto Load Set',
                            content = "Next launch will restore '" .. target .. "'.",
                            type = 'success',
                            duration = 3,
                        })
                    end,
                })

                local secInfo = colRight:CreateSection({
                    name = 'Info',
                    icon = 'lucide:info',
                    description = 'Storage paths and startup target.',
                    defaultOpen = true,
                })

                secInfo:CreateLabel({
                    text = 'Path: ' .. getConfigDir(),
                })
                secInfo:CreateLabel({
                    text = 'Startup: ' .. _activeProfile,
                })
            end
            function SaveManager.StartAutoSave()
                self:SetAutoSaveEnabled(true)
            end
            function SaveManager.StopAutoSave()
                self:SetAutoSaveEnabled(false)
            end

            return SaveManager
        end)()
    end,
    [35] = function()
        local wax, script, require = ImportGlobals(35)
        local ImportGlobals

        return (function(...)
            local network = require(script.Parent.network)
            local services = require(script.Parent.services)
            local IS_STUDIO = services.getService('RunService'):IsStudio()

            export type AssetId = number | string
            export type CacheKey = string | number
            export type AssetFetcher = {resolve: (self:AssetFetcher, value:unknown) -> AssetId?, getContentFromUrl: (self:AssetFetcher, url:string, cacheKey:CacheKey?, forced:boolean?) -> string?, getContentFromId: (self:AssetFetcher, id:AssetId, forced:boolean?) -> string?}

            local DOWNLOAD_URL = 'https://assetdelivery.roproxy.com/v1/asset?id=%d'
            local CACHE_LIMIT = 8
            local AssetFetcher = {}

            AssetFetcher.__index = AssetFetcher

            local function isGoodResponse(response: unknown): boolean
                if type(response) ~= 'table' then
                    return false
                end

                local r = response::{Body: unknown, StatusCode: unknown, Success: unknown}

                if type(r.Body) ~= 'string' or #(r.Body::string) == 0 then
                    return false
                end
                if type(r.StatusCode) == 'number' then
                    local code = r.StatusCode::number

                    return code >= 200 and code < 300
                end
                if type(r.Success) == 'boolean' then
                    return r.Success::boolean
                end

                return false
            end

            function AssetFetcher.new(): AssetFetcher
                local self = setmetatable({
                    _cache = {}::{[CacheKey]: string},
                    _cacheOrder = {}::{CacheKey},
                }, AssetFetcher)::any

                return self
            end
            function AssetFetcher.resolve(_self: AssetFetcher, value: unknown): AssetId?
                if type(value) == 'number' then
                    return value
                end
                if type(value) ~= 'string' then
                    return nil
                end

                local s = value::string

                if string.sub(s, 1, 11) == 'rbxasset://' or string.sub(s, 1, 11) == 'rbxthumb://' then
                    return s
                end

                local id = tonumber(string.match(s, '^rbxassetid://(%d+)$')) or tonumber(s)

                return id or nil
            end
            function AssetFetcher.getContentFromUrl(
                self: AssetFetcher,
                url: string,
                cacheKey: CacheKey?,
                forced: boolean?
            ): string?
                local cache = self._cache::{[CacheKey]: string}
                local order = self._cacheOrder::{CacheKey}

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
                        warn('[Delirium:assetFetcher] No executor request function found.')
                    end

                    return nil
                end

                local ok, response = pcall(requestFn, {
                    Url = url,
                    Method = 'GET',
                })

                if not ok or not isGoodResponse(response) then
                    if not forced then
                        warn('[Delirium:assetFetcher] Request failed for: ' .. url)
                    end

                    return nil
                end

                local body = (response::{Body: string}).Body

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

                if not resolved or type(resolved) ~= 'number' then
                    warn('[Delirium:assetFetcher] Invalid asset id: ' .. tostring(id))

                    return nil
                end

                local url = string.format(DOWNLOAD_URL, resolved::number)

                return self:getContentFromUrl(url, resolved, forced)
            end

            return AssetFetcher
        end)()
    end,
    [46] = function()
        local wax, script, require = ImportGlobals(46)
        local ImportGlobals

        return (function(...)
            local services = require(script.Parent.services)
            local ContentProvider = services.getService('ContentProvider')::ContentProvider
            local icons: any = {}

            icons.builtins = {
                settings = 10734950309,
                ['settings-2'] = 75339943202126,
                minus = 120931250449806,
                minimize = 120931250449806,
                ['minimize-2'] = 115725194133672,
                ['maximize-2'] = 108777312690515,
                x = 136096054247483,
                close = 136096054247483,
                check = 83827110621355,
                plus = 118563428285930,
                ['chevron-down'] = 95086910949405,
                ['chevron-up'] = 124630674114245,
                ['chevron-left'] = 83856486110301,
                ['chevron-right'] = 126507964682213,
                search = 125618569555993,
                lock = 71897067930472,
                user = 81899856845503,
                globe = 111578783307093,
                info = 10723415903,
                success = 10709790387,
                warning = 10709752935,
                error = 10747384394,
                sword = 10723407389,
                swords = 10723407389,
                eye = 10734975692,
                home = 111043355839507,
                stripes = 8834748103,
                circles = 73048796459024,
                nebula = 76656741080367,
                keycache = 13587387127,
                apps = 13300918120,
                ['view-in-ar'] = 113380429914565,
                ['home-material'] = 9080449299,
                location = 6034996695,
                sparkle = 4483362748,
                zap = 99546940565021,
                signal = 86317434523846,
                activity = 116785635688905,
                cpu = 115781787166822,
                clock = 96835529467684,
                monitor = 73331152826648,
                server = 72203285684743,
                ['map-pin'] = 125589857044225,
                ['file-text'] = 77346633411296,
            }
            icons.nebulaIcons = icons.builtins

            local function normalize(name: string): string
                return (string.lower(name):gsub('[_%s]+', '-'))
            end

            local collapsedIndex: {[string]: number} = {}

            for key, id in icons.builtins do
                collapsedIndex[normalize(key):gsub('-', '')] = id
            end

            local function findInMap(map: {[string]: number}, rawKey: string): number?
                if map[rawKey] then
                    return map[rawKey]
                end

                local k = normalize(rawKey)

                if map[k] then
                    return map[k]
                end

                return collapsedIndex[k:gsub('-', '')]
            end

            function icons:GetIcon(name: string, _source: string?): number?
                return findInMap(icons.builtins, name)
            end
            function icons.GetAssetUri(name: string, _source: string?): string?
                local id = icons:GetIcon(name)

                return if id then('rbxassetid://' .. tostring(id))else nil
            end
            function icons.Resolve(icon: (string | number)?, defaultSource: string?): string?
                if icon == nil or icon == '' then
                    return nil
                end
                if type(icon) == 'number' then
                    return 'rbxassetid://' .. tostring(icon)
                end

                local str = tostring(icon)
                local lower = string.lower(str)

                if string.sub(lower, 1, 13) == 'rbxassetid://' or string.sub(lower, 1, 11) == 'rbxasset://' or string.sub(lower, 1, 11) == 'rbxthumb://' or string.sub(lower, 1, 4) == 'http' then
                    return str
                end

                local asNum = tonumber(str)

                if asNum then
                    return 'rbxassetid://' .. tostring(asNum)
                end

                local _, iconName = string.match(str, '^([%w%-_]+)[:/]([%w%-_]+)$')
                local lookup = (iconName and iconName ~= '' and iconName) or str
                local id = icons:GetIcon(lookup, defaultSource)

                if id then
                    return 'rbxassetid://' .. tostring(id)
                end

                return nil
            end
            function icons.Preload(items: {string | number})
                local uris: {string} = {}

                for _, item in ipairs(items)do
                    local uri = icons.Resolve(item)

                    if uri then
                        table.insert(uris, uri)
                    end
                end

                if #uris > 0 then
                    pcall(function()
                        ContentProvider:PreloadAsync(uris)
                    end)
                end
            end

            return icons
        end)()
    end,
    [55] = function()
        local wax, script, require = ImportGlobals(55)
        local ImportGlobals

        return (function(...)
            local network = {}

            export type RequestFn = (...any) -> any

            function network.getRequestFn(env: any?): RequestFn?
                env = env or getfenv()

                return env.request or env.http_request or (env.http and env.http.request) or (env.syn and env.syn.request) or (env.fluxus and env.fluxus.request)
            end

            return network
        end)()
    end,
    [27] = function()
        local wax, script, require = ImportGlobals(27)
        local ImportGlobals

        return (function(...)
            local constants = require(script.Parent.Parent.utility.constants)
            local element = require(script.Parent.Parent.utility.element)
            local variables = require(script.Parent.Parent.utility.variables)
            local tween = require(script.Parent.Parent.utility.tween)
            local themeUtil = require(script.Parent.Parent.utility.theme)
            local windowSizing = require(script.Parent.Parent.utility.windowSizing)
            local layouts = require(script.Parent.Parent.utility.layouts)
            local notification = require(script.Parent.notification)
            local Tab = require(script.Parent.tab)
            local PlayerCard = require(script.Parent.dashboard)
            local icons = require(script.Parent.Parent.utility.icons)
            local PopupModule = require(script.Parent.popup)
            local ColorPicker = require(script.Parent.colorpicker)
            local Dropdown = require(script.Parent.dropdown)
            local Keybind = require(script.Parent.keybind)
            local Slider = require(script.Parent.slider)
            local Section = require(script.Parent.section)
            local saveManager = require(script.Parent.Parent.utility.saveManager)
            local executor = require(script.Parent.Parent.utility.executor)
            local hapticEngine = require(script.Parent.Parent.utility.HapticEngine)
            local ICON_SETTINGS = 'rbxassetid://129180860773723'
            local ICON_MINIMIZE = 'rbxassetid://108115485663409'
            local ICON_RESTORE = 'rbxassetid://88738500661569'
            local ICON_CLOSE = 'rbxassetid://83277910885129'

            export type WindowProps = {name: string?, subtitle: string?, theme: (string | {[string]: any})?, keybind: (EnumItem | string)?, keepOnScreen: boolean?, gestureBar: boolean?, tabsHeader: string?, icon: (string | number)?}
            export type TabDivider = {_frame: Frame, SetText: (self:TabDivider, text:string) -> (), Destroy: (self:TabDivider) -> ()}
            export type Window = {unloaded: boolean, _gui: ScreenGui, CreateTab: (self:Window, props:Tab.TabProps) -> Tab.Tab, CreateTabDivider: (self:Window, text:string?) -> TabDivider, ReorderTab: (self:Window, tab:Tab.Tab, newIndex:number) -> (), GetTabs: (self:Window) -> {Tab.Tab}, SetTabsHeader: (self:Window, header:string) -> (), Notify: (self:Window, props:notification.NotifyProps) -> (), Show: (self:Window) -> (), Hide: (self:Window) -> (), ToggleHide: (self:Window) -> (), ToggleMinimise: (self:Window) -> (), ChangeTheme: (self:Window, newTheme:string | {[string]: any}) -> (), Unload: (self:Window) -> ()}

            local Window = {}

            Window.__index = Window

            local function resolveKeybind(v: (EnumItem | string)?): EnumItem
                if typeof(v) == 'EnumItem' then
                    return v::EnumItem
                end
                if typeof(v) == 'string' then
                    local ok, item = pcall(function()
                        return Enum.KeyCode[v::string]
                    end)

                    if ok and item then
                        return item::EnumItem
                    end
                end

                return Enum.KeyCode.RightShift
            end
            local function fitWindowSize(): UDim2
                local cam = workspace.CurrentCamera

                return windowSizing.fit(cam and cam.ViewportSize)
            end

            function Window.new(props: WindowProps): Window
                executor.escalate(8)
                saveManager:AutoLoad()

                local windowName = props.name or 'Delirium'
                local subtitle = props.subtitle or ''
                local toggleKey = resolveKeybind(props.keybind)
                local keepOnScreen = if props.keepOnScreen ~= nil then props.keepOnScreen else true
                local resolvedTheme = themeUtil.resolve(props.theme)

                variables.activeTheme = resolvedTheme

                themeUtil.setCurrent(resolvedTheme)

                local colorSurface = if typeof(resolvedTheme.WindowColor) == 'ColorSequence' and #resolvedTheme.WindowColor.Keypoints > 0 then resolvedTheme.WindowColor.Keypoints[1].Value else Color3.fromHex('#111114')
                local colorTitleBar = resolvedTheme.TitleBarColor or Color3.fromHex('#111114')
                local colorBorder = resolvedTheme.SurfaceStroke or Color3.fromHex('#2b2b2b')
                local colorSurfaceHover = resolvedTheme.NeutralButton or Color3.fromHex('#252525')
                local colorAccent = resolvedTheme.AccentColor or Color3.fromHex('#4cc2ff')
                local colorError = resolvedTheme.ErrorColor or Color3.fromHex('#ff4f58')
                local colorTextPrimary = resolvedTheme.TitlingColor or Color3.fromHex('#ffffff')
                local colorTextSecondary = resolvedTheme.PlaceholderColor or Color3.fromHex('#8a8a92')
                local instances: {Instance} = {}
                local connections: {RBXScriptConnection} = {}

                local function make(
                    className: string,
                    parent: Instance?,
                    props: {[string]: any}?
                ): any
                    local inst = Instance.new(className)

                    if props then
                        for k, v in props do
                            inst[k] = v
                        end
                    end

                    inst.Parent = parent
                    instances[#instances + 1] = inst

                    return inst
                end
                local function connect(signal: RBXScriptSignal, callback: (...any) -> ()): RBXScriptConnection
                    local conn = signal:Connect(callback)

                    connections[#connections + 1] = conn

                    return conn
                end

                local gui = Instance.new('ScreenGui')

                gui.Name = variables.httpService:GenerateGUID(false)
                gui.DisplayOrder = constants.displayOrder.window
                gui.IgnoreGuiInset = true
                gui.ResetOnSpawn = false
                gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
                gui.ClipToDeviceSafeArea = false

                local initialSize = fitWindowSize()
                local W = initialSize.X.Offset
                local H = initialSize.Y.Offset
                local cam = variables.workspace.CurrentCamera
                local vp = if cam then cam.ViewportSize else Vector2.new(1920, 1080)
                local initX = math.floor(vp.X / 2)
                local initY = math.floor(vp.Y / 2)
                local windowFrame = Instance.new('Frame')

                windowFrame.Name = 'Window'
                windowFrame.Active = true
                windowFrame.AnchorPoint = Vector2.new(0.5, 0.5)
                windowFrame.Position = UDim2.fromOffset(initX, initY)
                windowFrame.Size = UDim2.fromOffset(W, H)
                windowFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                windowFrame.BackgroundTransparency = 1
                windowFrame.BorderSizePixel = 0
                windowFrame.ClipsDescendants = true
                windowFrame.Parent = gui

                local winScale = Instance.new('UIScale')

                winScale.Scale = 1
                winScale.Parent = windowFrame

                local winCorner = Instance.new('UICorner')

                winCorner.CornerRadius = resolvedTheme.CornerRoundness or UDim.new(0, 10)
                winCorner.Parent = windowFrame

                local winGradient = Instance.new('UIGradient')

                winGradient.Color = resolvedTheme.WindowColor
                winGradient.Rotation = 90
                winGradient.Parent = windowFrame

                local winStroke = Instance.new('UIStroke')

                winStroke.Color = colorBorder
                winStroke.Thickness = 1
                winStroke.Transparency = 0.3
                winStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                winStroke.Parent = windowFrame

                local TITLEBAR_H = layouts.sidebar.topbarHeight
                local FOOTER_H = layouts.sidebar.footerHeight
                local cornerRadius = resolvedTheme.CornerRoundness or UDim.new(0, 10)
                local cornerOffset = cornerRadius.Offset > 0 and cornerRadius.Offset or 10
                local titleBar = Instance.new('Frame')

                titleBar.Name = 'TitleBar'
                titleBar.Active = true
                titleBar.Size = UDim2.new(1, 0, 0, TITLEBAR_H)
                titleBar.BackgroundTransparency = 1
                titleBar.BorderSizePixel = 0
                titleBar.ClipsDescendants = true
                titleBar.ZIndex = constants.zIndex.windowChrome
                titleBar.Parent = windowFrame

                local titleBarBg = Instance.new('Frame')

                titleBarBg.Name = 'Background'
                titleBarBg.Position = UDim2.fromOffset(0, 0)
                titleBarBg.Size = UDim2.new(1, 0, 0, TITLEBAR_H + cornerOffset)
                titleBarBg.BackgroundColor3 = colorTitleBar
                titleBarBg.BorderSizePixel = 0
                titleBarBg.ZIndex = constants.zIndex.windowChrome - 1
                titleBarBg.Parent = titleBar

                local titleBarCorner = Instance.new('UICorner')

                titleBarCorner.CornerRadius = cornerRadius
                titleBarCorner.Parent = titleBarBg

                local titleSep = Instance.new('Frame')

                titleSep.Name = 'Separator'
                titleSep.Size = UDim2.new(1, 0, 0, 1)
                titleSep.Position = UDim2.new(0, 0, 1, -1)
                titleSep.BackgroundColor3 = colorBorder
                titleSep.BackgroundTransparency = 1
                titleSep.BorderSizePixel = 0
                titleSep.ZIndex = constants.zIndex.windowChrome + 1
                titleSep.Parent = titleBar

                local accentStrip = Instance.new('Frame')

                accentStrip.Name = 'AccentHairline'
                accentStrip.Size = UDim2.new(1, 0, 0, 1)
                accentStrip.Position = UDim2.fromOffset(0, TITLEBAR_H - 1)
                accentStrip.BackgroundColor3 = colorAccent
                accentStrip.BackgroundTransparency = 0.35
                accentStrip.BorderSizePixel = 0
                accentStrip.ZIndex = constants.zIndex.windowChrome + 2
                accentStrip.Parent = windowFrame

                local accentStripGrad = Instance.new('UIGradient')

                accentStripGrad.Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0.9),
                    NumberSequenceKeypoint.new(0.2, 0.15),
                    NumberSequenceKeypoint.new(0.8, 0.15),
                    NumberSequenceKeypoint.new(1, 0.9),
                })
                accentStripGrad.Parent = accentStrip

                local logoMark = Instance.new('Frame')

                logoMark.Name = 'LogoMark'
                logoMark.AnchorPoint = Vector2.new(0, 0.5)
                logoMark.Position = UDim2.new(0, 12, 0.5, 0)
                logoMark.Size = UDim2.fromOffset(26, 26)
                logoMark.BackgroundColor3 = colorAccent
                logoMark.BorderSizePixel = 0
                logoMark.ZIndex = constants.zIndex.windowChrome + 1
                logoMark.Parent = titleBar

                do
                    local c = Instance.new('UICorner')

                    c.CornerRadius = UDim.new(0, 6)
                    c.Parent = logoMark
                end
                do
                    local g = Instance.new('UIGradient')

                    g.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(0, 0, 0))
                    g.Transparency = NumberSequence.new({
                        NumberSequenceKeypoint.new(0, 0.7),
                        NumberSequenceKeypoint.new(1, 0.95),
                    })
                    g.Rotation = 135
                    g.Parent = logoMark
                end

                local windowIconAsset = if props.icon and props.icon ~= ''then icons.Resolve(props.icon)else nil

                if windowIconAsset then
                    local logoImg = Instance.new('ImageLabel')

                    logoImg.Name = 'Icon'
                    logoImg.AnchorPoint = Vector2.new(0.5, 0.5)
                    logoImg.Position = UDim2.fromScale(0.5, 0.5)
                    logoImg.Size = UDim2.fromOffset(16, 16)
                    logoImg.BackgroundTransparency = 1
                    logoImg.Image = windowIconAsset
                    logoImg.ImageColor3 = Color3.fromRGB(255, 255, 255)
                    logoImg.ZIndex = constants.zIndex.windowChrome + 2
                    logoImg.Parent = logoMark
                else
                    local logoInitial = Instance.new('TextLabel')

                    logoInitial.Name = 'Initial'
                    logoInitial.Size = UDim2.fromScale(1, 1)
                    logoInitial.BackgroundTransparency = 1
                    logoInitial.Text = string.sub(windowName, 1, 1):upper()
                    logoInitial.TextColor3 = Color3.fromRGB(255, 255, 255)
                    logoInitial.TextSize = 12
                    logoInitial.FontFace = resolvedTheme.TitleFont or constants.DEFAULT_FONT_BOLD
                    logoInitial.TextXAlignment = Enum.TextXAlignment.Center
                    logoInitial.ZIndex = constants.zIndex.windowChrome + 2
                    logoInitial.Parent = logoMark
                end

                local TEXT_LEFT = 48
                local TEXT_RIGHT_RESERVE = 110
                local nameLabel = Instance.new('TextLabel')

                nameLabel.Name = 'Name'
                nameLabel.AnchorPoint = Vector2.new(0, 0.5)
                nameLabel.Position = UDim2.new(0, TEXT_LEFT, 0.5, 0)
                nameLabel.Size = UDim2.new(1, -TEXT_LEFT - TEXT_RIGHT_RESERVE, 0, 18)
                nameLabel.BackgroundTransparency = 1
                nameLabel.Text = windowName
                nameLabel.TextColor3 = colorTextPrimary
                nameLabel.TextSize = 15
                nameLabel.FontFace = resolvedTheme.TitleFont or constants.DEFAULT_FONT_SEMI
                nameLabel.TextXAlignment = Enum.TextXAlignment.Left
                nameLabel.ZIndex = constants.zIndex.windowChrome + 1
                nameLabel.Parent = titleBar

                local subtitleLabel: TextLabel? = nil

                if subtitle ~= '' then
                    nameLabel.Position = UDim2.new(0, TEXT_LEFT, 0.5, -9)
                    subtitleLabel = Instance.new('TextLabel')
                    subtitleLabel.Name = 'Subtitle'
                    subtitleLabel.AnchorPoint = Vector2.new(0, 0)
                    subtitleLabel.Position = UDim2.new(0, TEXT_LEFT, 0.5, 3)
                    subtitleLabel.Size = UDim2.new(1, -TEXT_LEFT - TEXT_RIGHT_RESERVE, 0, 12)
                    subtitleLabel.BackgroundTransparency = 1
                    subtitleLabel.Text = subtitle
                    subtitleLabel.TextColor3 = colorTextSecondary
                    subtitleLabel.TextSize = 11
                    subtitleLabel.FontFace = resolvedTheme.Font or constants.DEFAULT_FONT
                    subtitleLabel.TextXAlignment = Enum.TextXAlignment.Left
                    subtitleLabel.ZIndex = constants.zIndex.windowChrome + 1
                    subtitleLabel.Parent = titleBar
                end

                local tagContainer = Instance.new('Frame')

                tagContainer.Name = 'TagContainer'
                tagContainer.AnchorPoint = Vector2.new(1, 0.5)

                local _tui = variables.isTouchOnly
                local _tagRightOffset = if _tui then 12 + 120 + 8 + 34 + 6 else 12 + 96 + 8 + 26 + 6

                tagContainer.Position = UDim2.new(1, -_tagRightOffset, 0.5, 0)
                tagContainer.Size = UDim2.fromOffset(50, 24)
                tagContainer.AutomaticSize = Enum.AutomaticSize.XY
                tagContainer.BackgroundTransparency = 1
                tagContainer.Visible = false
                tagContainer.ZIndex = constants.zIndex.windowChrome + 1
                tagContainer.Parent = titleBar

                local tagContainerLayout = Instance.new('UIListLayout')

                tagContainerLayout.Padding = UDim.new(0, 5)
                tagContainerLayout.FillDirection = Enum.FillDirection.Horizontal
                tagContainerLayout.VerticalAlignment = Enum.VerticalAlignment.Center
                tagContainerLayout.SortOrder = Enum.SortOrder.LayoutOrder
                tagContainerLayout.Parent = tagContainer

                local controlsFrame = Instance.new('Frame')

                controlsFrame.Name = 'Controls'
                controlsFrame.AnchorPoint = Vector2.new(1, 0.5)
                controlsFrame.Position = UDim2.new(1, -12, 0.5, 0)
                controlsFrame.Size = UDim2.fromOffset(96, 28)
                controlsFrame.BackgroundTransparency = 1
                controlsFrame.ZIndex = constants.zIndex.windowChrome + 1
                controlsFrame.Parent = titleBar

                local controlsLayout = Instance.new('UIListLayout')

                controlsLayout.FillDirection = Enum.FillDirection.Horizontal
                controlsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
                controlsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
                controlsLayout.Padding = UDim.new(0, 4)
                controlsLayout.SortOrder = Enum.SortOrder.LayoutOrder
                controlsLayout.Parent = controlsFrame

                local function makeTitleBtn(
                    name: string,
                    iconAsset: string,
                    order: number
                ): (TextButton,ImageLabel)
                    local b = make('TextButton', controlsFrame, {
                        Name = name,
                        Size = UDim2.fromOffset(26, 26),
                        BackgroundColor3 = colorSurfaceHover,
                        BackgroundTransparency = 0,
                        Text = '',
                        AutoButtonColor = false,
                        ZIndex = constants.zIndex.windowChrome + 2,
                        LayoutOrder = order,
                    })

                    make('UICorner', b, {
                        CornerRadius = UDim.new(1, 0),
                    })
                    make('UIStroke', b, {
                        Color = resolvedTheme.NeutralButtonStroke or Color3.fromHex('#2b2b2b'),
                        Thickness = 1,
                        Transparency = 0,
                        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                    })

                    local iconImg = make('ImageLabel', b, {
                        Name = 'Icon',
                        AnchorPoint = Vector2.new(0.5, 0.5),
                        Position = UDim2.fromScale(0.5, 0.5),
                        Size = UDim2.fromOffset(16, 16),
                        BackgroundTransparency = 1,
                        Image = iconAsset,
                        ImageColor3 = colorTextSecondary,
                        ZIndex = constants.zIndex.windowChrome + 3,
                    })

                    return b, iconImg
                end

                local settingsBtn, settingsIcon = makeTitleBtn('Settings', ICON_SETTINGS, 1)
                local minBtn, minIcon = makeTitleBtn('Minimize', ICON_MINIMIZE, 2)
                local closeBtn, closeIcon = makeTitleBtn('Close', ICON_CLOSE, 3)

                closeBtn.MouseEnter:Connect(function()
                    closeBtn.BackgroundColor3 = colorError
                    closeIcon.ImageColor3 = Color3.fromRGB(255, 255, 255)
                end)
                closeBtn.MouseLeave:Connect(function()
                    closeBtn.BackgroundColor3 = colorSurfaceHover
                    closeIcon.ImageColor3 = colorTextSecondary
                end)

                local function genericHover(btn: TextButton, icon: ImageLabel)
                    btn.MouseEnter:Connect(function()
                        btn.BackgroundColor3 = resolvedTheme.NeutralButtonHover or Color3.fromHex('#2e2e2e')
                        icon.ImageColor3 = colorTextPrimary
                    end)
                    btn.MouseLeave:Connect(function()
                        btn.BackgroundColor3 = colorSurfaceHover
                        icon.ImageColor3 = colorTextSecondary
                    end)
                end

                genericHover(minBtn, minIcon)
                genericHover(settingsBtn, settingsIcon)

                local body = make('Frame', windowFrame, {
                    Name = 'Body',
                    Position = UDim2.fromOffset(0, TITLEBAR_H),
                    Size = UDim2.new(1, 0, 1, -(TITLEBAR_H + FOOTER_H)),
                    BackgroundTransparency = 1,
                    ClipsDescendants = true,
                })
                local footerBar = make('Frame', windowFrame, {
                    Name = 'FooterBar',
                    Position = UDim2.new(0, 0, 1, -FOOTER_H),
                    Size = UDim2.new(1, 0, 0, FOOTER_H),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    ClipsDescendants = true,
                    ZIndex = 4,
                })
                local footerBg = make('Frame', footerBar, {
                    Name = 'Bg',
                    Position = UDim2.fromOffset(0, -cornerOffset),
                    Size = UDim2.new(1, 0, 1, cornerOffset),
                    BackgroundColor3 = colorTitleBar,
                    BackgroundTransparency = resolvedTheme.WindowTransparency or 0,
                    BorderSizePixel = 0,
                    ZIndex = 0,
                })
                local footerCorner = make('UICorner', footerBg, {CornerRadius = cornerRadius})
                local footerTopSep = make('Frame', footerBar, {
                    Name = 'TopSep',
                    Position = UDim2.fromOffset(0, 0),
                    Size = UDim2.new(1, 0, 0, 1),
                    BackgroundColor3 = colorBorder,
                    BackgroundTransparency = 0.5,
                    BorderSizePixel = 0,
                    ZIndex = 5,
                })
                local sidebar = make('Frame', body, {
                    Name = 'Sidebar',
                    Size = UDim2.new(0, constants.sidebarWidth, 1, 0),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    ClipsDescendants = true,
                })
                local sidebarBg = make('Frame', sidebar, {
                    Name = 'Background',
                    Position = UDim2.fromOffset(0, -cornerOffset),
                    Size = UDim2.new(0, constants.sidebarWidth + cornerOffset, 1, cornerOffset),
                    BackgroundColor3 = colorTitleBar,
                    BorderSizePixel = 0,
                    ZIndex = 0,
                })
                local sidebarCorner = make('UICorner', sidebarBg, {CornerRadius = cornerRadius})
                local sidebarHeader = make('Frame', sidebar, {
                    Name = 'SidebarHeader',
                    Size = UDim2.new(1, -16, 0, 16),
                    Position = UDim2.fromOffset(10, 10),
                    BackgroundTransparency = 1,
                })
                local sidebarHeaderAccent = make('Frame', sidebarHeader, {
                    Name = 'AccentIndicator',
                    AnchorPoint = Vector2.new(0, 0.5),
                    Position = UDim2.new(0, 2, 0.5, 0),
                    Size = UDim2.fromOffset(3, 10),
                    BackgroundColor3 = colorAccent,
                    BorderSizePixel = 0,
                })

                make('UICorner', sidebarHeaderAccent, {
                    CornerRadius = UDim.new(1, 0),
                })

                local sidebarHeaderText = make('TextLabel', sidebarHeader, {
                    Name = 'Label',
                    Size = UDim2.new(1, -12, 1, 0),
                    Position = UDim2.fromOffset(10, 0),
                    BackgroundTransparency = 1,
                    Text = string.upper(props.tabsHeader or 'PAGES'),
                    TextColor3 = colorTextSecondary,
                    TextTransparency = 0.35,
                    TextSize = 9,
                    FontFace = constants.DEFAULT_FONT_BOLD,
                    TextXAlignment = Enum.TextXAlignment.Left,
                })
                local tabListScroll = make('ScrollingFrame', sidebar, {
                    Name = 'TabList',
                    Position = UDim2.fromOffset(0, 30),
                    Size = UDim2.new(1, 0, 1, -32),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    ScrollBarThickness = 2,
                    ScrollBarImageColor3 = colorBorder,
                    ScrollBarImageTransparency = 0.6,
                    CanvasSize = UDim2.new(0, 0, 0, 0),
                    AutomaticCanvasSize = Enum.AutomaticSize.Y,
                    ScrollingDirection = Enum.ScrollingDirection.Y,
                    ClipsDescendants = true,
                })

                make('UIListLayout', tabListScroll, {
                    FillDirection = Enum.FillDirection.Vertical,
                    VerticalAlignment = Enum.VerticalAlignment.Top,
                    Padding = UDim.new(0, 4),
                    SortOrder = Enum.SortOrder.LayoutOrder,
                })
                make('UIPadding', tabListScroll, {
                    PaddingLeft = UDim.new(0, 8),
                    PaddingRight = UDim.new(0, 8),
                    PaddingTop = UDim.new(0, 2),
                    PaddingBottom = UDim.new(0, 8),
                })

                local divider = make('Frame', body, {
                    Name = 'Divider',
                    AnchorPoint = Vector2.new(0, 0),
                    Position = UDim2.fromOffset(constants.sidebarWidth, 0),
                    Size = UDim2.new(0, 1, 1, 0),
                    BackgroundColor3 = colorBorder,
                    BackgroundTransparency = 0.5,
                    BorderSizePixel = 0,
                    ZIndex = 2,
                })
                local contentArea = make('Frame', body, {
                    Name = 'Content',
                    Position = UDim2.fromOffset(constants.sidebarWidth + 1, 0),
                    Size = UDim2.new(1, -(constants.sidebarWidth + 1), 1, 0),
                    BackgroundTransparency = 1,
                    ClipsDescendants = true,
                })
                local self: Window = setmetatable({}, Window)::Window

                self.unloaded = false
                self.hidden = true
                self._gui = gui

                local s = (self::any)

                s.hidden = true

                local isTouchOnly = variables.isTouchOnly
                local userScale = if isTouchOnly then 0.9 else 1
                local currentToggleKey = toggleKey
                local keepOnScreenVal = keepOnScreen

                s._windowFrame = windowFrame
                s._winCorner = winCorner
                s._winStroke = winStroke
                s._winGradient = winGradient
                s._titleBar = titleBar
                s._titleBarBg = titleBarBg
                s._titleBarCorner = titleBarCorner
                s._sidebarCorner = sidebarCorner
                s._footerCorner = footerCorner
                s._sidebarBg = sidebarBg
                s._winScale = winScale
                s._userScale = userScale
                s._toggleKey = currentToggleKey
                s._sidebar = tabListScroll
                s._sidebarFrame = sidebar
                s._sidebarHeader = sidebarHeader
                s._footerBar = footerBar
                s._contentArea = contentArea
                s._divider = divider
                s._theme = resolvedTheme
                s._tabs = {}::{Tab.Tab}
                s._activeTab = nil::Tab.Tab?
                s._visible = false
                s._minimized = false
                s._hasBeenDragged = false
                s._windowSize = initialSize
                s._titlebarH = TITLEBAR_H
                s._body = body
                s._minBtn = minBtn
                s._minIcon = minIcon
                s._titleSep = titleSep
                s._accentStrip = accentStrip
                s._nameLabel = nameLabel
                s._subtitleLabel = subtitleLabel
                s._tagContainer = tagContainer
                s._tagContainerLayout = tagContainerLayout
                self.tagContainer = tagContainer
                self._tagContainer = tagContainer
                s._logoMark = logoMark
                s._keepOnScreen = keepOnScreenVal
                s._dragging = false
                s._pendingResize = false
                s._connections = connections
                s._instances = instances
                s.controls = {}::{[string]: any}
                s.themeProperties = {}::{[Instance]: any}
                s.localeProperties = {}::{[Instance]: {[string]: string}}
                self.localeProperties = s.localeProperties
                s.theme = resolvedTheme
                self.theme = resolvedTheme
                s._loading = false
                s._loadedConfig = nil::{[string]: any}?
                s._loadedConfigPath = nil::string?
                s._activeTween = nil
                s._scaleTween = nil
                s._posScaleTween = nil
                s._activeAnimConn = nil
                s._minimizeAnimId = nil
                s._cornerOffset = cornerOffset
                s._toastCount = 0
                s._liveToasts = {}::{[string]: {any}}
                self._toastCount = 0
                self._liveToasts = s._liveToasts

                do
                    local _touch = variables.isTouchOnly
                    local SEARCH_W_IDLE = if _touch then 34 else 26
                    local SEARCH_W_EXP = if _touch then 200 else 180
                    local SEARCH_H = if _touch then 34 else 26
                    local SEARCH_ICON_SIZE = if _touch then 14 else 12
                    local SEARCH_ICON_X = math.floor((SEARCH_W_IDLE - SEARCH_ICON_SIZE) / 2)
                    local SEARCH_INPUT_X = if _touch then 30 else 25
                    local SEARCH_INPUT_RIGHT = 10
                    local SEARCH_ROW_H = if _touch then 32 else 26
                    local CONTROLS_W = if _touch then 120 else 96
                    local SEARCH_RIGHT_OFFSET = 12 + CONTROLS_W - 4
                    local MAX_RESULTS = 8
                    local searchBar = Instance.new('Frame')

                    searchBar.Name = 'TitlebarSearch'
                    searchBar.AnchorPoint = Vector2.new(1, 0.5)
                    searchBar.Position = UDim2.new(1, -SEARCH_RIGHT_OFFSET, 0.5, 0)
                    searchBar.Size = UDim2.fromOffset(SEARCH_W_IDLE, SEARCH_H)
                    searchBar.BackgroundColor3 = colorSurfaceHover
                    searchBar.BackgroundTransparency = 0
                    searchBar.BorderSizePixel = 0
                    searchBar.ClipsDescendants = true
                    searchBar.ZIndex = constants.zIndex.windowChrome + 1
                    searchBar.Parent = titleBar

                    local searchCorner = Instance.new('UICorner')

                    searchCorner.CornerRadius = UDim.new(1, 0)
                    searchCorner.Parent = searchBar

                    local searchStroke = Instance.new('UIStroke')

                    searchStroke.Color = resolvedTheme.NeutralButtonStroke or colorBorder
                    searchStroke.Thickness = 1
                    searchStroke.Transparency = 0
                    searchStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                    searchStroke.Parent = searchBar

                    local searchIcon = Instance.new('ImageLabel')

                    searchIcon.Name = 'Icon'
                    searchIcon.AnchorPoint = Vector2.new(0, 0.5)
                    searchIcon.Position = UDim2.new(0, SEARCH_ICON_X, 0.5, 0)
                    searchIcon.Size = UDim2.fromOffset(SEARCH_ICON_SIZE, SEARCH_ICON_SIZE)
                    searchIcon.BackgroundTransparency = 1
                    searchIcon.Image = icons.Resolve('search', 'Lucide') or 'rbxassetid://125618569555993'
                    searchIcon.ImageColor3 = colorTextSecondary
                    searchIcon.ZIndex = constants.zIndex.windowChrome + 4
                    searchIcon.Parent = searchBar

                    local searchBox = Instance.new('TextBox')

                    searchBox.Name = 'Input'
                    searchBox.AnchorPoint = Vector2.new(0, 0.5)
                    searchBox.Position = UDim2.new(0, SEARCH_INPUT_X, 0.5, 0)
                    searchBox.Size = UDim2.new(1, -(SEARCH_INPUT_X + SEARCH_INPUT_RIGHT), 1, 0)
                    searchBox.BackgroundTransparency = 1
                    searchBox.BorderSizePixel = 0
                    searchBox.Text = ''
                    searchBox.PlaceholderText = 'Search...'
                    searchBox.PlaceholderColor3 = colorTextSecondary
                    searchBox.TextColor3 = colorTextPrimary
                    searchBox.TextSize = if _touch then 12 else 11
                    searchBox.FontFace = resolvedTheme.Font or constants.DEFAULT_FONT
                    searchBox.TextXAlignment = Enum.TextXAlignment.Left
                    searchBox.TextTransparency = 1
                    searchBox.ClearTextOnFocus = false
                    searchBox.ZIndex = constants.zIndex.windowChrome + 3
                    searchBox.Parent = searchBar

                    local searchHit = Instance.new('TextButton')

                    searchHit.Name = 'Hit'
                    searchHit.Size = UDim2.fromScale(1, 1)
                    searchHit.BackgroundTransparency = 1
                    searchHit.Text = ''
                    searchHit.AutoButtonColor = false
                    searchHit.ZIndex = constants.zIndex.windowChrome + 2
                    searchHit.Parent = searchBar

                    local searchResults = Instance.new('Frame')

                    searchResults.Name = 'TitlebarSearchResults'
                    searchResults.AnchorPoint = Vector2.new(1, 0)
                    searchResults.Position = UDim2.new(1, -SEARCH_RIGHT_OFFSET, 0, TITLEBAR_H + 4)
                    searchResults.Size = UDim2.new(0, SEARCH_W_EXP, 0, 0)
                    searchResults.BackgroundColor3 = colorSurface
                    searchResults.BackgroundTransparency = 0
                    searchResults.BorderSizePixel = 0
                    searchResults.ClipsDescendants = true
                    searchResults.Visible = false
                    searchResults.ZIndex = constants.zIndex.windowChrome + 20
                    searchResults.Parent = windowFrame

                    local srCorner = Instance.new('UICorner')

                    srCorner.CornerRadius = UDim.new(0, 8)
                    srCorner.Parent = searchResults

                    local srStroke = Instance.new('UIStroke')

                    srStroke.Color = colorBorder
                    srStroke.Thickness = 1
                    srStroke.Transparency = 0.3
                    srStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                    srStroke.Parent = searchResults

                    local srLayout = Instance.new('UIListLayout')

                    srLayout.FillDirection = Enum.FillDirection.Vertical
                    srLayout.SortOrder = Enum.SortOrder.LayoutOrder
                    srLayout.Padding = UDim.new(0, 0)
                    srLayout.Parent = searchResults

                    local srPad = Instance.new('UIPadding')

                    srPad.PaddingTop = UDim.new(0, 4)
                    srPad.PaddingBottom = UDim.new(0, 4)
                    srPad.PaddingLeft = UDim.new(0, 4)
                    srPad.PaddingRight = UDim.new(0, 4)
                    srPad.Parent = searchResults

                    local searchScrim = Instance.new('TextButton')

                    searchScrim.Name = 'TitlebarSearchScrim'
                    searchScrim.Size = UDim2.fromScale(1, 1)
                    searchScrim.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                    searchScrim.BackgroundTransparency = 0.55
                    searchScrim.BorderSizePixel = 0
                    searchScrim.Text = ''
                    searchScrim.AutoButtonColor = false
                    searchScrim.Active = true
                    searchScrim.Visible = false
                    searchScrim.ZIndex = 100
                    searchScrim.Parent = body

                    local searchEmpty = Instance.new('TextLabel')

                    searchEmpty.Name = 'Empty'
                    searchEmpty.Size = UDim2.new(1, 0, 0, SEARCH_ROW_H)
                    searchEmpty.BackgroundTransparency = 1
                    searchEmpty.Text = 'No matches'
                    searchEmpty.TextColor3 = colorTextSecondary
                    searchEmpty.TextTransparency = 0.3
                    searchEmpty.TextSize = if _touch then 12 else 11
                    searchEmpty.FontFace = resolvedTheme.Font or constants.DEFAULT_FONT
                    searchEmpty.Visible = false
                    searchEmpty.ZIndex = constants.zIndex.windowChrome + 21
                    searchEmpty.Parent = searchResults

                    local searchExpanded = false
                    local searchDebounceThread: thread? = nil
                    local searchRows: {TextButton} = {}

                    s._searchBar = searchBar
                    s._searchBox = searchBox
                    s._searchIcon = searchIcon
                    s._searchStroke = searchStroke
                    s._searchResults = searchResults
                    s._searchResultsStroke = srStroke
                    s._searchEmpty = searchEmpty
                    s._searchExpanded = false

                    local function clearSearchRows()
                        for _, row in ipairs(searchRows)do
                            if row.Parent then
                                row:Destroy()
                            end
                        end

                        table.clear(searchRows)
                    end
                    local function getElementName(el: any): string?
                        local frame = el._frame

                        if not frame then
                            return nil
                        end

                        local fname = frame.Name

                        if fname == 'Descriptor' or fname == 'Group' then
                            return nil
                        end

                        local candidates = {
                            el._titleLabel,
                            el._outerLabel,
                            el._label,
                            el._centreLabel,
                        }

                        for _, lbl in ipairs(candidates)do
                            if lbl and lbl.Text and #lbl.Text > 0 then
                                return lbl.Text
                            end
                        end

                        local _, suffix = fname:match('^(%w+)_(.+)$')

                        if suffix and #suffix > 0 then
                            return suffix
                        end

                        return nil
                    end
                    local function isSection(el: any): boolean
                        return el._open ~= nil and el._content ~= nil and el._frame ~= nil
                    end
                    local function scoreOf(
                        name: string,
                        q: string,
                        kind: string
                    ): number
                        local n = string.lower(name)
                        local isPrefix = string.sub(n, 1, #q) == q
                        local kindWeight = if kind == 'element'
                            then 0
                            elseif kind == 'section'
                            then 100
                            else 200

                        return (if isPrefix then 0 else 50) + kindWeight
                    end
                    local function collectMatches(
                        query: string,
                        limit: number
                    ): {any}
                        local q = string.lower(query)
                        local out: {any} = {}

                        if #q < 2 then
                            return out
                        end

                        local scored: {{item: any, score: number, order: number}} = {}
                        local order = 0

                        for _, tab in s._tabs do
                            local tabAny: any = tab

                            if tabAny._neglectSelector then
                                continue
                            end

                            local tabName = tabAny._name or ''

                            if #tabName > 0 and string.find(string.lower(tabName), q, 1, true) then
                                order += 1

                                table.insert(scored, {
                                    item = {
                                        tab = tab,
                                        element = nil,
                                        text = tabName,
                                        kind = 'tab',
                                    },
                                    score = scoreOf(tabName, q, 'tab'),
                                    order = order,
                                })
                            end

                            for _, el in tabAny._elements or {}do
                                local elAny: any = el
                                local name = getElementName(elAny)

                                if not name or #name == 0 then
                                    continue
                                end
                                if not string.find(string.lower(name), q, 1, true) then
                                    continue
                                end

                                local kind = if isSection(elAny)then'section'else'element'

                                order += 1

                                table.insert(scored, {
                                    item = {
                                        tab = tab,
                                        element = el,
                                        text = name,
                                        kind = kind,
                                    },
                                    score = scoreOf(name, q, kind),
                                    order = order,
                                })
                            end
                        end

                        table.sort(scored, function(a, b)
                            if a.score ~= b.score then
                                return a.score < b.score
                            end

                            return a.order < b.order
                        end)

                        for _, entry in scored do
                            table.insert(out, entry.item)

                            if #out >= limit then
                                return out
                            end
                        end

                        return out
                    end
                    local function findScrollingAncestor(frame: Instance?): ScrollingFrame?
                        local node: Instance? = frame and frame.Parent

                        while node and node ~= windowFrame do
                            if node:IsA('ScrollingFrame') then
                                return node::ScrollingFrame
                            end

                            node = node.Parent
                        end

                        return nil
                    end
                    local function scrollToElement(el: any)
                        local frame = el and el._frame

                        if not frame or not frame.Parent then
                            return
                        end

                        local scroll = findScrollingAncestor(frame)

                        if not scroll then
                            return
                        end

                        local targetY = frame.AbsolutePosition.Y - scroll.AbsolutePosition.Y + scroll.CanvasPosition.Y

                        scroll.CanvasPosition = Vector2.new(0, math.max(0, targetY - 40))
                    end
                    local function buildResultRow(
                        match: any,
                        order: number
                    ): TextButton
                        local row = Instance.new('TextButton')

                        row.Name = 'Result_' .. order
                        row.Size = UDim2.new(1, 0, 0, SEARCH_ROW_H)
                        row.BackgroundColor3 = colorSurfaceHover
                        row.BackgroundTransparency = 1
                        row.BorderSizePixel = 0
                        row.Text = ''
                        row.AutoButtonColor = false
                        row.LayoutOrder = order
                        row.ZIndex = constants.zIndex.windowChrome + 21
                        row.Parent = searchResults

                        table.insert(searchRows, row)

                        local rc = Instance.new('UICorner')

                        rc.CornerRadius = UDim.new(0, 5)
                        rc.Parent = row

                        local kindIcon = Instance.new('ImageLabel')

                        kindIcon.Name = 'Kind'
                        kindIcon.AnchorPoint = Vector2.new(1, 0.5)
                        kindIcon.Position = UDim2.new(1, -6, 0.5, 0)
                        kindIcon.Size = UDim2.fromOffset(10, 10)
                        kindIcon.BackgroundTransparency = 1
                        kindIcon.Image = if match.kind == 'tab'
                            then(icons.Resolve('layers', 'Lucide') or 'rbxassetid://81899856845503')
                            elseif match.kind == 'section'
                            then(icons.Resolve('folder-tree', 'Lucide') or 'rbxassetid://77346633411296')
                            else(icons.Resolve('zap', 'Lucide') or 'rbxassetid://99546940565021')
                        kindIcon.ImageColor3 = colorTextSecondary
                        kindIcon.ZIndex = constants.zIndex.windowChrome + 22
                        kindIcon.Parent = row

                        local lbl = Instance.new('TextLabel')

                        lbl.Name = 'Label'
                        lbl.Position = UDim2.fromOffset(8, 0)
                        lbl.Size = UDim2.new(1, -26, 1, 0)
                        lbl.BackgroundTransparency = 1
                        lbl.Text = match.text
                        lbl.TextColor3 = colorTextPrimary
                        lbl.TextSize = if _touch then 12 else 11
                        lbl.FontFace = resolvedTheme.Font or constants.DEFAULT_FONT
                        lbl.TextXAlignment = Enum.TextXAlignment.Left
                        lbl.TextTruncate = Enum.TextTruncate.AtEnd
                        lbl.ZIndex = constants.zIndex.windowChrome + 22
                        lbl.Parent = row

                        if not variables.isTouchOnly then
                            row.MouseEnter:Connect(function()
                                row.BackgroundTransparency = 0.85
                                row.BackgroundColor3 = colorAccent
                            end)
                            row.MouseLeave:Connect(function()
                                row.BackgroundTransparency = 1
                            end)
                        end

                        row.Activated:Connect(function()
                            if self.unloaded then
                                return
                            end

                            searchBox.Text = ''

                            searchBox:ReleaseFocus()

                            searchResults.Visible = false
                            searchEmpty.Visible = false

                            clearSearchRows()
                            s:_activateTab(match.tab)

                            if match.element then
                                task.defer(function()
                                    if not self.unloaded then
                                        scrollToElement(match.element)
                                    end
                                end)
                            end
                        end)

                        return row
                    end
                    local function hideResults()
                        searchResults.Visible = false
                        searchEmpty.Visible = false
                        searchScrim.Visible = false

                        clearSearchRows()
                    end
                    local function showResults(query: string)
                        if self.unloaded then
                            return
                        end
                        if #query == 0 then
                            hideResults()

                            return
                        end

                        clearSearchRows()

                        local matches = collectMatches(query, MAX_RESULTS)

                        if #matches == 0 then
                            searchResults.Size = UDim2.new(0, SEARCH_W_EXP, 0, SEARCH_ROW_H + 8)
                            searchEmpty.LayoutOrder = 0
                            searchEmpty.Visible = true
                        else
                            searchEmpty.Visible = false

                            for i, m in matches do
                                buildResultRow(m, i)
                            end

                            searchResults.Size = UDim2.new(0, SEARCH_W_EXP, 0, #matches * SEARCH_ROW_H + 8)
                        end

                        searchResults.Visible = true
                        searchScrim.Visible = true
                    end
                    local function expandSearch()
                        if searchExpanded then
                            return
                        end

                        searchExpanded = true
                        s._searchExpanded = true

                        tween.fire(searchBar, constants.tweenFast, {
                            Size = UDim2.fromOffset(SEARCH_W_EXP, SEARCH_H),
                        })
                        tween.fire(searchIcon, constants.tweenFast, {ImageColor3 = colorAccent})
                        tween.fire(searchBox, constants.tweenFocus, {TextTransparency = 0})
                        tween.fire(searchStroke, constants.tweenFast, {
                            Color = colorAccent,
                            Transparency = 0.2,
                        })
                    end
                    local function collapseSearch(force: boolean?)
                        if not searchExpanded then
                            return
                        end
                        if not force then
                            if searchBox:IsFocused() then
                                return
                            end
                            if #searchBox.Text > 0 then
                                return
                            end
                        end

                        searchExpanded = false
                        s._searchExpanded = false

                        hideResults()
                        tween.fire(searchBar, constants.tweenFast, {
                            Size = UDim2.fromOffset(SEARCH_W_IDLE, SEARCH_H),
                        })
                        tween.fire(searchIcon, constants.tweenFast, {ImageColor3 = colorTextSecondary})
                        tween.fire(searchBox, constants.tweenFocus, {TextTransparency = 1})
                        tween.fire(searchStroke, constants.tweenFast, {
                            Color = colorBorder,
                            Transparency = 0.5,
                        })
                    end

                    s._expandSearch = expandSearch
                    s._collapseSearch = collapseSearch
                    s._hideSearchResults = hideResults
                    s._openSearch = function()
                        expandSearch()
                        searchBox:CaptureFocus()
                    end
                    s._closeSearch = function()
                        searchBox.Text = ''

                        searchBox:ReleaseFocus()
                        hideResults()
                        collapseSearch(true)
                    end
                    s._toggleSearch = function()
                        if s._searchExpanded then
                            s._closeSearch()
                        else
                            s._openSearch()
                        end
                    end

                    searchHit.Activated:Connect(function()
                        if self.unloaded then
                            return
                        end

                        expandSearch()
                        searchBox:CaptureFocus()
                    end)
                    searchBox.Focused:Connect(function()
                        expandSearch()

                        if #searchBox.Text > 0 then
                            showResults(searchBox.Text)
                        end
                    end)
                    searchBox.FocusLost:Connect(function()
                        if #searchBox.Text == 0 then
                            task.delay(0.1, collapseSearch)
                        end
                    end)
                    searchBox:GetPropertyChangedSignal('Text'):Connect(function()
                        if self.unloaded then
                            return
                        end

                        local q = searchBox.Text

                        if searchDebounceThread then
                            pcall(task.cancel, searchDebounceThread)

                            searchDebounceThread = nil
                        end

                        searchDebounceThread = task.delay(0.08, function()
                            searchDebounceThread = nil

                            if self.unloaded then
                                return
                            end

                            showResults(q)
                        end)
                    end)
                    connect(variables.userInputService.InputBegan, function(
                        input,
                        processed
                    )
                        if processed then
                            return
                        end
                        if self.unloaded then
                            return
                        end
                        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
                            return
                        end
                        if not searchResults.Visible then
                            return
                        end

                        local pos = input.Position

                        local function inside(gui: GuiObject): boolean
                            if not gui.Visible then
                                return false
                            end

                            local ap, as = gui.AbsolutePosition, gui.AbsoluteSize

                            return pos.X >= ap.X and pos.X <= ap.X + as.X and pos.Y >= ap.Y and pos.Y <= ap.Y + as.Y
                        end

                        if not inside(searchBar) and not inside(searchResults) then
                            hideResults()
                        end
                    end)
                    connect(variables.userInputService.InputBegan, function(
                        input,
                        processed
                    )
                        if processed then
                            return
                        end
                        if self.unloaded or not s._visible then
                            return
                        end
                        if input.KeyCode == Enum.KeyCode.Slash then
                            searchBox:CaptureFocus()
                        end
                    end)
                end

                local spAccentUpdaters: {(Color3) -> ()} = {}
                local _accentBroadcastPending = false
                local _lastAppliedAccent: Color3? = nil

                local function updateAccent(
                    col: Color3,
                    skipBroadcast: boolean?
                )
                    if col == _lastAppliedAccent then
                        if skipBroadcast or _accentBroadcastPending then
                            return
                        end

                        _accentBroadcastPending = true

                        task.defer(function()
                            _accentBroadcastPending = false

                            themeUtil.broadcast(resolvedTheme)
                        end)

                        return
                    end

                    _lastAppliedAccent = col
                    colorAccent = col

                    if accentStrip then
                        accentStrip.BackgroundColor3 = col
                    end
                    if logoMark then
                        logoMark.BackgroundColor3 = col
                    end
                    if sidebarHeaderAccent then
                        sidebarHeaderAccent.BackgroundColor3 = col
                    end

                    resolvedTheme.AccentColor = col
                    resolvedTheme.AccentStroke = col:Lerp(Color3.fromRGB(255, 255, 255), 0.2)
                    resolvedTheme.ElementStrokeHover = col
                    resolvedTheme.FieldGlow = col
                    resolvedTheme.SliderProgress = ColorSequence.new(col, col:Lerp(Color3.fromRGB(0, 0, 0), 0.25))

                    if variables.activeTheme then
                        variables.activeTheme.AccentColor = col
                        variables.activeTheme.AccentStroke = resolvedTheme.AccentStroke
                        variables.activeTheme.ElementStrokeHover = col
                        variables.activeTheme.FieldGlow = col
                        variables.activeTheme.SliderProgress = resolvedTheme.SliderProgress
                    end
                    if s then
                        s._theme = resolvedTheme
                    end

                    for _, fn in spAccentUpdaters do
                        fn(col)
                    end

                    if not skipBroadcast then
                        if _accentBroadcastPending then
                            return
                        end

                        _accentBroadcastPending = true

                        task.defer(function()
                            _accentBroadcastPending = false

                            themeUtil.broadcast(resolvedTheme)
                        end)
                    end
                end

                s._updateAccent = updateAccent

                local function smoothSetScale(factor: number)
                    userScale = factor

                    if s then
                        s._userScale = factor
                    end

                    variables.uiScale = factor

                    if s and s._scaleTween then
                        s._scaleTween:Cancel()
                    end

                    local tw = variables.tweenService:Create(winScale, constants.tweenFast, {Scale = factor})

                    if s then
                        s._scaleTween = tw
                    end

                    tw.Completed:Once(function()
                        tw:Destroy()

                        if s then
                            s._scaleTween = nil
                        end
                        if not self then
                            return
                        end

                        local wf = (self::any)._windowFrame

                        if not wf then
                            return
                        end

                        local screen = (self::any)._gui.AbsoluteSize
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
                            if s and s._posScaleTween then
                                s._posScaleTween:Cancel()
                            end

                            local posTw = variables.tweenService:Create(wf, constants.tweenFocus, {Position = clamped})

                            if s then
                                s._posScaleTween = posTw
                            end

                            posTw:Play()
                        end
                    end)
                    tw:Play()
                end

                local rfSettings = self:CreateTab({
                    name = 'Settings',
                    icon = 'lucide:settings',
                    columns = 2,
                    neglectSelector = true,
                    forgetState = true,
                })

                s.rfSettings = rfSettings
                s._settingsPanel = (rfSettings::any)._frame

                local spSections: {any} = {}
                local spSliders: {any} = {}
                local spColorPicker: any = nil
                local spKeybind: any = nil
                local spFontDropdown: any = nil
                local secAppearance = rfSettings.Left:CreateSection({
                    name = 'Appearance',
                    icon = 'lucide:palette',
                    description = 'Window styling, scaling, and transparency',
                })

                table.insert(spSections, secAppearance)

                local currentCornerRadius = (resolvedTheme.CornerRoundness or UDim.new(0, 10)).Offset
                local slCorner = secAppearance:CreateSlider({
                    name = 'Corner Roundness',
                    min = 0,
                    max = 16,
                    step = 1,
                    value = currentCornerRadius,
                    suffix = 'px',
                    callback = function(r: number)
                        local cr = UDim.new(0, r)

                        winCorner.CornerRadius = cr

                        if s._titleBarCorner then
                            s._titleBarCorner.CornerRadius = cr
                        end
                        if s._sidebarCorner then
                            s._sidebarCorner.CornerRadius = cr
                        end
                        if s._footerCorner then
                            s._footerCorner.CornerRadius = cr
                        end

                        resolvedTheme.CornerRoundness = cr

                        if s._theme then
                            s._theme.CornerRoundness = cr
                        end
                    end,
                })

                table.insert(spSliders, slCorner)

                local slScale = secAppearance:CreateSlider({
                    name = 'UI Scale / DPI',
                    min = 80,
                    max = 125,
                    step = 5,
                    value = math.round(userScale * 100),
                    suffix = '%',
                    callback = function(pct: number)
                        smoothSetScale(pct / 100)
                    end,
                })

                table.insert(spSliders, slScale)

                local cpAccent = secAppearance:CreateColorPicker({
                    name = 'Accent Color',
                    color = colorAccent,
                    overlayParent = windowFrame,
                    overlayYOffset = TITLEBAR_H + 1,
                    callback = function(col: Color3, _alpha: number)
                        updateAccent(col)
                    end,
                })

                spColorPicker = cpAccent

                local initWinT = resolvedTheme.WindowTransparency or 0
                local initTransPct = math.clamp(math.round((initWinT / 0.85) * 100), 0, 80)
                local slTrans = secAppearance:CreateSlider({
                    name = 'Background Transparency',
                    min = 0,
                    max = 80,
                    step = 5,
                    value = initTransPct,
                    suffix = '%',
                    callback = function(pct: number)
                        local t = pct / 100

                        resolvedTheme.WindowTransparency = math.clamp(t * 0.85, 0, 0.9)
                        resolvedTheme.ElementTransparency = math.clamp(t * 0.8, 0, 0.75)
                        resolvedTheme.ElementStrokeTransparency = math.clamp(t * 0.4, 0, 0.55)
                        resolvedTheme.FieldTransparency = math.clamp(0.85 + t * 0.1, 0.8, 0.95)

                        themeUtil.broadcast(resolvedTheme)
                    end,
                })

                table.insert(spSliders, slTrans)

                local secConfig = rfSettings.Left:CreateSection({
                    name = 'Configurations',
                    icon = 'lucide:folder',
                    description = 'Save, load, and manage custom profiles',
                    defaultOpen = true,
                })

                table.insert(spSections, secConfig)

                local selectedConfig: string? = nil
                local initialConfigList = saveManager:List()

                if #initialConfigList > 0 then
                    local active = saveManager:GetActiveProfile()

                    if table.find(initialConfigList, active) then
                        selectedConfig = active
                    else
                        selectedConfig = initialConfigList[1]
                    end
                end

                local configDropdown: any = nil
                local configNameInput: any = nil

                local function refreshConfigs(selectAfter: string?)
                    if not configDropdown then
                        return
                    end

                    local currentList = saveManager:List()

                    configDropdown:Refresh(currentList)

                    if selectAfter and #selectAfter > 0 then
                        selectedConfig = selectAfter

                        configDropdown:Set(selectAfter, true)
                    elseif selectedConfig and not table.find(currentList, selectedConfig) then
                        selectedConfig = currentList[1]

                        if selectedConfig then
                            configDropdown:Set(selectedConfig, true)
                        else
                            configDropdown:Set(nil, true)
                        end
                    end
                end

                configDropdown = secConfig:CreateDropdown({
                    name = 'Saved Configurations',
                    description = 'Pick a configuration to load, overwrite, or delete.',
                    options = initialConfigList,
                    value = selectedConfig,
                    placeholder = 'No saved configurations',
                    callback = function(val: any)
                        selectedConfig = if val and val ~= ''then tostring(val)else nil
                    end,
                })
                configNameInput = secConfig:CreateInput({
                    name = 'Configuration Name',
                    description = 
[[Name a new configuration, or leave blank to overwrite the selected one.]],
                    placeholder = 'e.g. Default, PvP, Farm',
                    value = '',
                    clearOnFocus = false,
                })

                secConfig:CreateButton({
                    name = 'Save',
                    description = 'Save current settings under the typed or selected name',
                    callback = function()
                        if self.unloaded then
                            return
                        end

                        local inputTb = (configNameInput::any)._textBox
                        local rawName = if inputTb and inputTb.Text ~= ''then inputTb.Text else(configNameInput.value or '')
                        local target = (rawName:match('^%s*(.-)%s*$')) or ''

                        if #target == 0 and selectedConfig then
                            target = selectedConfig
                        end
                        if #target == 0 then
                            self:Notify({
                                title = 'Name Required',
                                content = 'Enter a configuration name first.',
                                type = 'warning',
                                duration = 3,
                            })

                            return
                        end

                        local ok = self:Save(target)

                        if ok then
                            selectedConfig = target

                            refreshConfigs(target)
                            configNameInput:Set('', true)
                            self:Notify({
                                title = 'Configuration Saved',
                                content = "'" .. target .. "' has been saved successfully.",
                                type = 'success',
                                duration = 3,
                            })
                        else
                            self:Notify({
                                title = 'Save Failed',
                                content = "Could not save configuration '" .. target .. "'.",
                                type = 'error',
                                duration = 3,
                            })
                        end
                    end,
                })
                secConfig:CreateButton({
                    name = 'Load',
                    description = 'Apply the selected configuration to all elements',
                    callback = function()
                        if self.unloaded then
                            return
                        end

                        local target = selectedConfig or ''

                        if #target == 0 then
                            self:Notify({
                                title = 'Nothing Selected',
                                content = 'Pick a configuration from the dropdown to load.',
                                type = 'warning',
                                duration = 3,
                            })

                            return
                        end

                        local count = self:Load(target)

                        if count > 0 then
                            self:Notify({
                                title = 'Configuration Loaded',
                                content = 'Restored ' .. tostring(count) .. " value(s) from '" .. target .. "'.",
                                type = 'success',
                                duration = 3,
                            })
                        else
                            self:Notify({
                                title = 'Load Completed',
                                content = "Loaded '" .. target .. "' (0 flags or empty).",
                                type = 'info',
                                duration = 3,
                            })
                        end
                    end,
                })
                secConfig:CreateButton({
                    name = 'Set as Auto Load',
                    description = 'Automatically load this configuration on next startup',
                    callback = function()
                        if self.unloaded then
                            return
                        end

                        local target = selectedConfig or ''

                        if #target == 0 then
                            self:Notify({
                                title = 'Nothing Selected',
                                content = 'Pick a configuration from the dropdown first.',
                                type = 'warning',
                                duration = 3,
                            })

                            return
                        end

                        self:SetAutoLoad(target)
                        self:Notify({
                            title = 'Auto Load Set',
                            content = "Startup will automatically restore '" .. target .. "'.",
                            type = 'success',
                            duration = 3,
                        })
                    end,
                })
                secConfig:CreateButton({
                    name = 'Delete',
                    description = 'Permanently remove the selected configuration from disk',
                    callback = function()
                        if self.unloaded then
                            return
                        end

                        local target = selectedConfig or ''

                        if #target == 0 then
                            self:Notify({
                                title = 'Nothing Selected',
                                content = 'Pick a configuration from the dropdown to delete.',
                                type = 'warning',
                                duration = 3,
                            })

                            return
                        end

                        local ok = self:DeleteConfig(target)

                        if ok then
                            selectedConfig = nil

                            refreshConfigs()
                            self:Notify({
                                title = 'Configuration Deleted',
                                content = "Removed '" .. target .. "'.",
                                type = 'info',
                                duration = 3,
                            })
                        else
                            self:Notify({
                                title = 'Delete Failed',
                                content = "Could not delete '" .. target .. "'.",
                                type = 'error',
                                duration = 3,
                            })
                        end
                    end,
                })
                secConfig:CreateToggle({
                    name = 'Auto Save on Change',
                    description = 'Automatically save flag changes to disk',
                    value = saveManager:IsAutoSaveEnabled(),
                    callback = function(enabled: boolean)
                        saveManager:SetAutoSaveEnabled(enabled)
                        self:Notify({
                            title = if enabled then'Auto Save Enabled'else'Auto Save Disabled',
                            content = if enabled then'Changes will be written automatically.'else'Use the Save button to commit changes.',
                            type = 'info',
                            duration = 2,
                        })
                    end,
                })

                local secControls = rfSettings.Right:CreateSection({
                    name = 'Controls',
                    icon = 'lucide:keyboard',
                    description = 'Hotkeys and menu shortcuts',
                })

                table.insert(spSections, secControls)

                local kbMenu = secControls:CreateKeybind({
                    name = 'Menu Keybind',
                    value = currentToggleKey,
                    onChanged = function(newKey: Enum.KeyCode)
                        currentToggleKey = newKey

                        if s then
                            s._toggleKey = newKey
                        end
                    end,
                })

                spKeybind = kbMenu

                local mouseOverrideEnabled = true

                local function applyMouseFree()
                    if not mouseOverrideEnabled then
                        return
                    end
                    if s == nil or not s._visible or s._minimized then
                        return
                    end

                    local uis = variables.userInputService

                    if uis:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
                        return
                    end

                    pcall(function()
                        if uis.MouseBehavior ~= Enum.MouseBehavior.Default then
                            uis.MouseBehavior = Enum.MouseBehavior.Default
                        end
                        if not uis.MouseIconEnabled then
                            uis.MouseIconEnabled = true
                        end
                    end)
                end

                connect(variables.userInputService:GetPropertyChangedSignal('MouseBehavior'), applyMouseFree)
                connect(variables.userInputService:GetPropertyChangedSignal('MouseIconEnabled'), applyMouseFree)
                connect(variables.userInputService.InputEnded, function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton2 then
                        applyMouseFree()
                    end
                end)
                secControls:CreateToggle({
                    name = 'Haptic Feedback',
                    description = 'Vibrate on interaction (mobile/gamepad)',
                    value = hapticEngine.IsEnabled(),
                    callback = function(state: boolean)
                        hapticEngine.setEnabled(state)
                    end,
                })
                secControls:CreateButton({
                    name = 'Center Window',
                    description = 'Snap window to the middle of the screen',
                    callback = function()
                        if self.unloaded then
                            return
                        end

                        local screen = gui.AbsoluteSize
                        local target = UDim2.fromOffset(math.floor(screen.X / 2), math.floor(screen.Y / 2))

                        variables.tweenService:Create(windowFrame, TweenInfo.new(0.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Position = target}):Play()

                        s._hasBeenDragged = false
                    end,
                })

                local secTypography = rfSettings.Right:CreateSection({
                    name = 'Typography',
                    icon = 'lucide:type',
                    description = 'Global typeface and font scaling',
                })

                table.insert(spSections, secTypography)

                local FONT_MAP: {[string]: string} = {
                    ['Gotham'] = 'rbxasset://fonts/families/GothamSSm.json',
                    ['Roboto'] = 'rbxasset://fonts/families/Roboto.json',
                    ['Source Sans Pro'] = 'rbxasset://fonts/families/SourceSansPro.json',
                    ['Ubuntu'] = 'rbxasset://fonts/families/Ubuntu.json',
                    ['Syne'] = 'rbxasset://fonts/families/Syne.json',
                    ['Nunito'] = 'rbxasset://fonts/families/Nunito.json',
                    ['Builder Sans'] = 'rbxasset://fonts/families/BuilderSans.json',
                    ['Jura'] = 'rbxasset://fonts/families/Jura.json',
                }
                local fontDD = secTypography:CreateDropdown({
                    name = 'UI Font',
                    options = {
                        'Gotham',
                        'Roboto',
                        'Source Sans Pro',
                        'Ubuntu',
                        'Syne',
                        'Nunito',
                        'Builder Sans',
                        'Jura',
                    },
                    value = 'Gotham',
                    callback = function(val: any)
                        local family = FONT_MAP[tostring(val)] or 'rbxasset://fonts/families/GothamSSm.json'

                        resolvedTheme.Font = Font.new(family, Enum.FontWeight.Medium)
                        resolvedTheme.TitleFont = Font.new(family, Enum.FontWeight.SemiBold)

                        themeUtil.broadcast(resolvedTheme)

                        for _, desc in windowFrame:GetDescendants()do
                            if desc:IsA('TextLabel') or desc:IsA('TextButton') then
                                local tl = desc::any

                                tl.FontFace = Font.new(family, tl.FontFace.Weight, tl.FontFace.Style)
                            end
                        end
                    end,
                })

                spFontDropdown = fontDD

                local lastActiveTab: any = nil

                local function updateSettingsBtnVisual(active: boolean)
                    if active then
                        tween.fire(settingsBtn, constants.tweenFast, {
                            BackgroundColor3 = resolvedTheme.AccentColor or Color3.fromHex('#4cc2ff'),
                            BackgroundTransparency = 0.8,
                        })
                        tween.fire(settingsIcon, constants.tweenFast, {
                            ImageColor3 = resolvedTheme.AccentColor or Color3.fromHex('#4cc2ff'),
                        })
                    else
                        tween.fire(settingsBtn, constants.tweenFast, {
                            BackgroundColor3 = colorSurfaceHover,
                            BackgroundTransparency = 0,
                        })
                        tween.fire(settingsIcon, constants.tweenFast, {ImageColor3 = colorTextSecondary})
                    end
                end

                s._updateSettingsBtnVisual = updateSettingsBtnVisual

                local function toggleSettings()
                    if s.unloaded then
                        return
                    end
                    if s._activeTab == rfSettings then
                        if lastActiveTab and lastActiveTab ~= rfSettings then
                            self:_activateTab(lastActiveTab)
                        else
                            for _, tb in s._tabs do
                                if not (tb::any)._neglectSelector then
                                    self:_activateTab(tb)

                                    break
                                end
                            end
                        end
                    else
                        if s._activeTab and s._activeTab ~= rfSettings then
                            lastActiveTab = s._activeTab
                        end

                        self:_activateTab(rfSettings)
                    end
                end

                connect(settingsBtn.Activated, toggleSettings)

                local function closeSettings()
                    if s._activeTab == rfSettings then
                        if lastActiveTab and lastActiveTab ~= rfSettings then
                            self:_activateTab(lastActiveTab)
                        else
                            for _, tb in s._tabs do
                                if not (tb::any)._neglectSelector then
                                    self:_activateTab(tb)

                                    break
                                end
                            end
                        end
                    end
                end

                s._closeSettings = closeSettings
                s._spSections = spSections
                s._spSliders = spSliders
                s._spColorPicker = spColorPicker
                s._spKeybind = spKeybind
                s._spFontDropdown = spFontDropdown

                function self:_setElementLocked(
                    element: any,
                    locked: boolean,
                    reason: string?
                )
                    locked = locked == true

                    local wasLocked = element.locked == true

                    if wasLocked == locked and not (locked and reason) then
                        return
                    end

                    element.locked = locked

                    local scrim = element._lockScrim

                    if not scrim then
                        local parent = element._frame or element.main

                        if not parent then
                            return
                        end

                        local bgColor = if self._theme.WindowColor and typeof(self._theme.WindowColor) == 'ColorSequence' and #self._theme.WindowColor.Keypoints > 0 then self._theme.WindowColor.Keypoints[1].Value else Color3.fromHex('#111114')

                        scrim = self:Create('TextButton', {
                            Name = 'ElementLock',
                            Active = true,
                            AutoButtonColor = false,
                            Size = UDim2.fromScale(1, 1),
                            BorderSizePixel = 0,
                            Text = '',
                            TextTransparency = 1,
                            ZIndex = 100,
                            Visible = false,
                            BackgroundColor3 = bgColor,
                            BackgroundTransparency = 1,
                        }, parent)
                        element._lockScrim = scrim
                    end

                    local info = constants.tweenFast

                    if locked then
                        scrim.Visible = true
                    end

                    variables.tweenService:Create(scrim, info, {
                        BackgroundTransparency = if locked then 0.55 else 1,
                    }):Play()

                    if not locked then
                        task.delay(info.Time, function()
                            if not element.locked and scrim and scrim.Parent then
                                scrim.Visible = false
                            end
                        end)
                    end

                    local descriptor = element._descriptor or element.descriptor

                    if not descriptor then
                        return
                    end

                    local label = descriptor._label or descriptor.titleLabel

                    if not label then
                        return
                    end
                    if locked then
                        element._descriptionBefore = element._descriptionBefore or label.Text
                        label.Text = reason or 'Locked'
                    elseif element._descriptionBefore then
                        label.Text = element._descriptionBefore
                        element._descriptionBefore = nil
                    end
                end

                if userScale ~= 1 then
                    winScale.Scale = userScale
                    variables.uiScale = userScale
                    s._userScale = userScale
                end
                if isTouchOnly then
                    for _, btn in {settingsBtn, minBtn, closeBtn}::{TextButton}do
                        btn.Size = UDim2.fromOffset(34, 34)
                    end

                    controlsFrame.Size = UDim2.fromOffset(120, 36)
                    nameLabel.Size = UDim2.new(1, -TEXT_LEFT - 138, 0, 18)

                    if subtitleLabel then
                        subtitleLabel.Size = UDim2.new(1, -TEXT_LEFT - 138, 0, 12)
                    end
                end

                s._themeUnsub = themeUtil.subscribe(function(t)
                    s._theme = t

                    local winT = t.WindowTransparency or 0

                    windowFrame.BackgroundTransparency = winT
                    titleBarBg.BackgroundTransparency = winT
                    sidebarBg.BackgroundTransparency = winT
                    winStroke.Color = t.SurfaceStroke
                    winGradient.Color = t.WindowColor

                    if s._titleBarBg then
                        (s._titleBarBg::Frame).BackgroundColor3 = t.TitleBarColor
                    end

                    titleSep.BackgroundColor3 = t.SurfaceStroke
                    sidebar.BackgroundColor3 = t.TitleBarColor
                    sidebarBg.BackgroundColor3 = t.TitleBarColor

                    if sidebarHeaderText then
                        sidebarHeaderText.TextColor3 = t.PlaceholderColor
                    end
                    if sidebarHeaderAccent and t.AccentColor then
                        sidebarHeaderAccent.BackgroundColor3 = t.AccentColor
                    end
                    if footerBg then
                        footerBg.BackgroundColor3 = t.TitleBarColor
                        footerBg.BackgroundTransparency = winT
                    end
                    if footerTopSep then
                        footerTopSep.BackgroundColor3 = t.SurfaceStroke
                        footerTopSep.BackgroundTransparency = math.clamp(winT + 0.5, 0, 0.95)
                    end
                    if accentStrip and t.AccentColor then
                        accentStrip.BackgroundColor3 = t.AccentColor
                    end
                    if logoMark and t.AccentColor then
                        logoMark.BackgroundColor3 = t.AccentColor
                    end

                    tabListScroll.ScrollBarImageColor3 = t.SurfaceStroke
                    settingsBtn.BackgroundColor3 = t.NeutralButton
                    minBtn.BackgroundColor3 = t.NeutralButton
                    closeBtn.BackgroundColor3 = t.NeutralButton
                    settingsIcon.ImageColor3 = t.PlaceholderColor
                    minIcon.ImageColor3 = t.PlaceholderColor
                    closeIcon.ImageColor3 = t.PlaceholderColor
                    colorSurface = if typeof(t.WindowColor) == 'ColorSequence' and #t.WindowColor.Keypoints > 0 then t.WindowColor.Keypoints[1].Value else Color3.fromHex('#111114')
                    colorTitleBar = t.TitleBarColor
                    colorBorder = t.SurfaceStroke
                    colorSurfaceHover = t.NeutralButton
                    colorAccent = t.AccentColor
                    colorError = t.ErrorColor
                    colorTextPrimary = t.TitlingColor
                    colorTextSecondary = t.PlaceholderColor

                    for _, fn in spAccentUpdaters do
                        fn(t.AccentColor)
                    end

                    nameLabel.TextColor3 = t.TitlingColor

                    if subtitleLabel then
                        subtitleLabel.TextColor3 = t.PlaceholderColor
                    end

                    local acc, ph, cs = t.AccentColor or constants.COLORS.ACCENT, t.PlaceholderColor or constants.COLORS.TEXT_SUBTLE, t.ContentColor or constants.COLORS.TEXT
                    local exp = s._searchExpanded

                    if s._searchBar then
                        s._searchBar.BackgroundColor3 = t.NeutralButton or constants.COLORS.SURFACE_HOVER
                    end
                    if s._searchStroke then
                        s._searchStroke.Color = if exp then acc else(t.SurfaceStroke or constants.COLORS.STROKE)
                    end
                    if s._searchIcon then
                        s._searchIcon.ImageColor3 = if exp then acc else ph
                    end
                    if s._searchBox then
                        s._searchBox.TextColor3, s._searchBox.PlaceholderColor3, s._searchBox.FontFace = cs, ph, t.Font or constants.DEFAULT_FONT
                    end
                    if s._searchResults then
                        s._searchResults.BackgroundColor3 = if typeof(t.WindowColor) == 'ColorSequence' and #t.WindowColor.Keypoints > 0 then t.WindowColor.Keypoints[1].Value else constants.COLORS.SURFACE
                    end
                    if s._searchResultsStroke then
                        s._searchResultsStroke.Color = t.SurfaceStroke or constants.COLORS.STROKE_SURFACE
                    end
                    if s._searchEmpty then
                        s._searchEmpty.TextColor3 = t.PlaceholderColor or constants.COLORS.TEXT_SUBTLE
                        s._searchEmpty.FontFace = t.Font or constants.DEFAULT_FONT
                    end
                end, windowFrame)

                do
                    local uis = variables.userInputService
                    local dragging = false
                    local dragStart = Vector3.zero
                    local startPos = UDim2.fromOffset(0, 0)
                    local lastX, lastY = 0, 0
                    local targetX, targetY = 0, 0
                    local smoothConn: RBXScriptConnection? = nil

                    local function interactive(): boolean
                        return (self::any)._visible
                    end

                    connect(titleBar.InputBegan, function(input, processed)
                        if processed then
                            return
                        end
                        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
                            return
                        end
                        if not interactive() then
                            return
                        end

                        local inputPos = if input.UserInputType == Enum.UserInputType.Touch then Vector2.new(input.Position.X, input.Position.Y)else uis:GetMouseLocation()
                        local cp = controlsFrame.AbsolutePosition
                        local cs = controlsFrame.AbsoluteSize

                        if inputPos.X >= cp.X - 6 and inputPos.X <= cp.X + cs.X + 6 and inputPos.Y >= cp.Y - 6 and inputPos.Y <= cp.Y + cs.Y + 6 then
                            return
                        end

                        dragging = true
                        dragStart = input.Position
                        startPos = windowFrame.Position
                        lastX = startPos.X.Offset
                        lastY = startPos.Y.Offset
                        targetX = lastX
                        targetY = lastY

                        local _ds = (self::any)

                        _ds._dragging = true
                        _ds._hasBeenDragged = true

                        if smoothConn then
                            smoothConn:Disconnect()
                        end

                        smoothConn = variables.runService.RenderStepped:Connect(function(
                            dt: number
                        )
                            if not dragging then
                                if smoothConn then
                                    smoothConn:Disconnect()

                                    smoothConn = nil
                                end

                                return
                            end

                            local cx = windowFrame.Position.X.Offset
                            local cy = windowFrame.Position.Y.Offset
                            local dx = targetX - cx
                            local dy = targetY - cy

                            if math.abs(dx) < 0.4 and math.abs(dy) < 0.4 then
                                windowFrame.Position = UDim2.fromOffset(targetX, targetY)

                                return
                            end

                            local alpha = 1 - (1e-7) ^ dt

                            windowFrame.Position = UDim2.fromOffset(cx + dx * alpha, cy + dy * alpha)
                        end)

                        local CAS_DRAG_SINK = 'Delirium_WindowDragSink'

                        if input.UserInputType == Enum.UserInputType.Touch then
                            pcall(function()
                                variables.contextActionService:BindActionAtPriority(CAS_DRAG_SINK, function(
                                )
                                    return Enum.ContextActionResult.Sink
                                end, false, Enum.ContextActionPriority.High.Value + 3000, Enum.UserInputType.Touch)
                            end)
                        end

                        local dragMoveConn: RBXScriptConnection? = nil
                        local dragEndConn: RBXScriptConnection? = nil
                        local wfrConn: RBXScriptConnection? = nil

                        local function stopDrag()
                            if not dragging then
                                return
                            end

                            dragging = false
                            _ds._dragging = false

                            if smoothConn then
                                smoothConn:Disconnect()

                                smoothConn = nil
                            end

                            windowFrame.Position = UDim2.fromOffset(targetX, targetY)

                            pcall(function()
                                variables.contextActionService:UnbindAction(CAS_DRAG_SINK)
                            end)

                            if dragMoveConn then
                                dragMoveConn:Disconnect()

                                dragMoveConn = nil
                            end
                            if dragEndConn then
                                dragEndConn:Disconnect()

                                dragEndConn = nil
                            end
                            if wfrConn then
                                wfrConn:Disconnect()

                                wfrConn = nil
                            end

                            task.defer(function()
                                if not self.unloaded then
                                    self:_applyWindowSize()
                                end
                            end)
                        end

                        dragMoveConn = uis.InputChanged:Connect(function(
                            moveInput
                        )
                            if not dragging then
                                return
                            end
                            if moveInput.UserInputType ~= Enum.UserInputType.MouseMovement and moveInput.UserInputType ~= Enum.UserInputType.Touch then
                                return
                            end
                            if not interactive() then
                                return
                            end

                            local delta = moveInput.Position - dragStart

                            if math.abs(delta.X) < 1 and math.abs(delta.Y) < 1 then
                                return
                            end

                            local newX = startPos.X.Offset + delta.X
                            local newY = startPos.Y.Offset + delta.Y

                            if (self::any)._keepOnScreen then
                                local screen = gui.AbsoluteSize
                                local curW = windowFrame.AbsoluteSize.X
                                local curH = windowFrame.AbsoluteSize.Y
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

                            local _dragThreshold = if isTouchOnly then 1 else 0.5

                            if math.abs(newX - lastX) < _dragThreshold and math.abs(newY - lastY) < _dragThreshold then
                                return
                            end

                            lastX, lastY = newX, newY
                            targetX = newX
                            targetY = newY
                        end)
                        dragEndConn = uis.InputEnded:Connect(function(endInput)
                            if endInput.UserInputType == Enum.UserInputType.MouseButton1 or endInput.UserInputType == Enum.UserInputType.Touch then
                                stopDrag()
                            end
                        end)
                        wfrConn = uis.WindowFocusReleased:Connect(stopDrag)
                    end)
                end

                local function requestClose()
                    if self.unloaded then
                        return
                    end
                    if not s._closeConfirmPopup then
                        s._closeConfirmPopup = PopupModule.new({
                            title = 'Close Window?',
                            description = 
[[Your current settings will be saved automatically before closing. You can restore them next time.]],
                            icon = 'lucide:warning',
                            iconVariant = 'warning',
                            width = 380,
                            buttons = {
                                {
                                    text = 'Cancel',
                                    variant = 'secondary',
                                },
                                {
                                    text = 'Close',
                                    variant = 'danger',
                                    callback = function()
                                        task.defer(function()
                                            if not self.unloaded then
                                                self:Unload()
                                            end
                                        end)
                                    end,
                                },
                            },
                        }, s._theme, windowFrame)
                    end
                    if not s._closeConfirmPopup:IsOpen() then
                        s._closeConfirmPopup:Open()
                    end
                end

                connect(closeBtn.Activated, requestClose)
                connect(minBtn.Activated, function()
                    self:ToggleMinimise()
                end)
                connect(variables.userInputService.InputBegan, function(
                    input,
                    gameProcessed
                )
                    if gameProcessed then
                        return
                    end
                    if self.unloaded then
                        return
                    end

                    local activeKey = (self::any)._toggleKey or toggleKey

                    if input.KeyCode == activeKey then
                        self:ToggleHide()
                    end
                end)

                windowFrame.Visible = false
                gui.Parent = variables.guiContainer

                hapticEngine.setContainer(gui)
                self:_watchViewport()

                local isMobile = variables.isTouchOnly or (variables.userInputService.TouchEnabled and not variables.userInputService.KeyboardEnabled)
                local showGestureBar = isMobile and (props.gestureBar ~= false)

                if showGestureBar then
                    local PILL_W_REST = 5
                    local PILL_H_REST = 64
                    local PILL_W_ACTIVE = 8
                    local PILL_H_ACTIVE = 80
                    local PILL_X_REST = 6
                    local HIT_W = 44
                    local HIT_H = 110
                    local THRESHOLD = 50
                    local MAX_TRAVEL = 70
                    local COLOR_REST = colorAccent
                    local COLOR_CONFIRM = resolvedTheme.ErrorColor or Color3.fromHex('#ff4f58')
                    local barContainer = Instance.new('Frame')

                    barContainer.Name = 'Delirium_GestureBar'
                    barContainer.AnchorPoint = Vector2.new(0, 0.5)
                    barContainer.Position = UDim2.new(0, 0, 0.5, 0)
                    barContainer.Size = UDim2.fromOffset(HIT_W, HIT_H)
                    barContainer.BackgroundTransparency = 1
                    barContainer.BorderSizePixel = 0
                    barContainer.ZIndex = constants.zIndex.tooltip + 10
                    barContainer.Parent = gui

                    local barPill = make('Frame', barContainer, {
                        Name = 'Pill',
                        AnchorPoint = Vector2.new(0, 0.5),
                        Position = UDim2.fromOffset(PILL_X_REST, 0),
                        Size = UDim2.fromOffset(PILL_W_REST, PILL_H_REST),
                        BackgroundColor3 = COLOR_REST,
                        BackgroundTransparency = 0.45,
                        BorderSizePixel = 0,
                        ZIndex = constants.zIndex.tooltip + 11,
                    })

                    make('UICorner', barPill, {
                        CornerRadius = UDim.new(1, 0),
                    })

                    local pillStroke = make('UIStroke', barPill, {
                        Color = Color3.fromRGB(255, 255, 255),
                        Thickness = 1,
                        Transparency = 0.72,
                        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                    })
                    local chevron = Instance.new('TextLabel')

                    chevron.Name = 'Chevron'
                    chevron.AnchorPoint = Vector2.new(0.5, 0.5)
                    chevron.Position = UDim2.fromScale(0.5, 0.5)
                    chevron.Size = UDim2.fromOffset(10, 18)
                    chevron.BackgroundTransparency = 1
                    chevron.Text = '\u{203a}'
                    chevron.TextColor3 = Color3.fromRGB(255, 255, 255)
                    chevron.TextTransparency = 0.55
                    chevron.TextSize = 16
                    chevron.FontFace = constants.DEFAULT_FONT_BOLD
                    chevron.TextXAlignment = Enum.TextXAlignment.Center
                    chevron.ZIndex = constants.zIndex.tooltip + 12
                    chevron.Parent = barPill

                    table.insert(spAccentUpdaters, function(newAccent)
                        COLOR_REST = newAccent

                        if not isGestureDragging then
                            barPill.BackgroundColor3 = newAccent
                        end
                    end)

                    local isGestureDragging = false
                    local startTouchX = 0
                    local currentDeltaX = 0
                    local dragMoveConn: RBXScriptConnection? = nil
                    local dragEndConn: RBXScriptConnection? = nil
                    local pulseThread: thread? = nil

                    local function startPulse()
                        if pulseThread then
                            return
                        end

                        pulseThread = task.spawn(function()
                            while true do
                                task.wait(3)

                                if isGestureDragging then
                                    continue
                                end

                                tween.fire(barPill, TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {BackgroundTransparency = 0.15})
                                task.wait(0.45)

                                if isGestureDragging then
                                    continue
                                end

                                tween.fire(barPill, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {BackgroundTransparency = 0.45})
                            end
                        end)
                    end
                    local function stopPulse()
                        if pulseThread then
                            task.cancel(pulseThread)

                            pulseThread = nil
                        end
                    end
                    local function restorePill()
                        local windowVisible = (self::any)._visible

                        chevron.Text = if windowVisible then'\u{2039}'else'\u{203a}'

                        tween.fire(barPill, constants.tweenFast, {
                            Position = UDim2.fromOffset(PILL_X_REST, 0),
                            Size = UDim2.fromOffset(PILL_W_REST, PILL_H_REST),
                            BackgroundColor3 = COLOR_REST,
                            BackgroundTransparency = 0.45,
                        })
                        tween.fire(pillStroke, constants.tweenFast, {
                            Transparency = 0.72,
                            Color = Color3.fromRGB(255, 255, 255),
                        })
                        tween.fire(chevron, constants.tweenFast, {TextTransparency = 0.55})
                        startPulse()
                    end
                    local function stopGestureDrag()
                        if not isGestureDragging then
                            return
                        end

                        isGestureDragging = false

                        if dragMoveConn then
                            dragMoveConn:Disconnect()

                            dragMoveConn = nil
                        end
                        if dragEndConn then
                            dragEndConn:Disconnect()

                            dragEndConn = nil
                        end

                        local windowVisible = (self::any)._visible
                        local committed = (windowVisible and currentDeltaX <= -THRESHOLD) or (not windowVisible and currentDeltaX >= THRESHOLD)

                        restorePill()

                        if committed then
                            self:ToggleHide()
                        end

                        currentDeltaX = 0
                    end

                    connect(barContainer.InputBegan, function(
                        input,
                        gameProcessed
                    )
                        if gameProcessed then
                            return
                        end
                        if input.UserInputType ~= Enum.UserInputType.Touch then
                            return
                        end

                        local screenH = gui.AbsoluteSize.Y

                        if screenH > 0 and input.Position.Y > screenH * 0.72 then
                            return
                        end

                        stopPulse()

                        isGestureDragging = true
                        startTouchX = input.Position.X
                        currentDeltaX = 0

                        tween.fire(barPill, constants.tweenFast, {
                            Size = UDim2.fromOffset(PILL_W_ACTIVE, PILL_H_ACTIVE),
                            BackgroundTransparency = 0.1,
                        })
                        tween.fire(pillStroke, constants.tweenFast, {
                            Transparency = 0.1,
                            Color = colorAccent,
                        })
                        tween.fire(chevron, constants.tweenFast, {TextTransparency = 0.1})

                        if dragMoveConn then
                            dragMoveConn:Disconnect()
                        end
                        if dragEndConn then
                            dragEndConn:Disconnect()
                        end

                        local _lastVisualX = math.maxinteger

                        dragMoveConn = variables.userInputService.InputChanged:Connect(function(
                            moveInput
                        )
                            if not isGestureDragging then
                                return
                            end
                            if moveInput.UserInputType ~= Enum.UserInputType.Touch then
                                return
                            end

                            local windowVisible = (self::any)._visible
                            local rawDelta = moveInput.Position.X - startTouchX

                            currentDeltaX = rawDelta

                            local travel: number

                            if windowVisible then
                                travel = math.max(-MAX_TRAVEL, math.min(0, rawDelta))
                            else
                                travel = math.min(MAX_TRAVEL, math.max(0, rawDelta))
                            end

                            local visualX = math.floor(PILL_X_REST + travel)

                            if visualX == _lastVisualX then
                                return
                            end

                            _lastVisualX = visualX

                            local ratio = math.clamp(math.abs(travel) / THRESHOLD, 0, 1)
                            local blendColor = COLOR_REST:Lerp(COLOR_CONFIRM, math.max(0, (ratio - 0.5) * 2))

                            barPill.Position = UDim2.fromOffset(visualX, 0)
                            barPill.BackgroundColor3 = blendColor
                        end)
                        dragEndConn = variables.userInputService.InputEnded:Connect(function(
                            endInput
                        )
                            if endInput.UserInputType == Enum.UserInputType.Touch then
                                stopGestureDrag()
                            end
                        end)
                    end)

                    chevron.Text = if(self::any)._visible then'\u{2039}'else'\u{203a}'
                    s._gestureRestorePill = restorePill
                    s._gestureCleanup = function()
                        stopPulse()
                        stopGestureDrag()
                    end

                    task.delay(1.5, startPulse)
                end

                task.defer(function()
                    if not self.unloaded then
                        saveManager:_attachConfigTabIfEnabled(self)
                    end
                end)

                return self
            end
            function Window:Create(
                className: string,
                properties: {[string]: any}?,
                parent: Instance?
            ): any
                local inst = Instance.new(className)

                if properties then
                    for k, v in properties do
                        inst[k] = v
                    end
                end
                if parent then
                    inst.Parent = parent
                end

                table.insert(self._instances, inst)

                return inst
            end
            function Window:Connect(signal: RBXScriptSignal, callback: (...any) -> ()): RBXScriptConnection
                local conn = signal:Connect(callback)

                table.insert(self._connections, conn)

                return conn
            end
            function Window:ConnectFor(
                owner: any,
                signal: RBXScriptSignal,
                callback: (...any) -> ()
            ): RBXScriptConnection
                local conn = self:Connect(signal, callback)

                if owner then
                    owner._connections = owner._connections or {}

                    table.insert(owner._connections, conn)
                end

                return conn
            end
            function Window:Disconnect(connection: RBXScriptConnection?)
                if not connection then
                    return
                end

                local idx = table.find(self._connections, connection)

                if idx then
                    table.remove(self._connections, idx)
                end

                connection:Disconnect()
            end
            function Window:DisconnectMany(
                owner: any,
                connections: {RBXScriptConnection}?
            )
                if not connections or #connections == 0 then
                    return
                end

                local dropping: {[RBXScriptConnection]: boolean} = {}

                for _, conn in connections do
                    dropping[conn] = true

                    conn:Disconnect()
                end

                local function filter(list: {RBXScriptConnection}?)
                    if not list then
                        return
                    end

                    local kept = 0

                    for i = 1, #list do
                        local entry = list[i]

                        if not dropping[entry] then
                            kept += 1

                            list[kept] = entry
                        end
                    end
                    for i = #list, kept + 1, -1 do
                        list[i] = nil
                    end
                end

                filter(self._connections)

                if owner and owner ~= self and owner._connections then
                    filter(owner._connections)
                end
            end
            function Window:DestroySubtree(root: Instance?)
                if not root then
                    return
                end

                local inSubtree: {[Instance]: boolean} = {[root] = true}

                for _, descendant in root:GetDescendants()do
                    inSubtree[descendant] = true
                end

                for i = #self._instances, 1, -1 do
                    local inst = self._instances[i]

                    if inSubtree[inst] then
                        table.remove(self._instances, i)

                        self.themeProperties[inst] = nil
                    end
                end

                root:Destroy()
            end
            function Window:DestroySubtrees(roots: {Instance}?)
                if not roots or #roots == 0 then
                    return
                end

                local inSubtree: {[Instance]: boolean} = {}

                for _, root in roots do
                    inSubtree[root] = true

                    for _, descendant in root:GetDescendants()do
                        inSubtree[descendant] = true
                    end
                end

                local kept = 0

                for i = 1, #self._instances do
                    local inst = self._instances[i]

                    if inSubtree[inst] then
                        self.themeProperties[inst] = nil
                    else
                        kept += 1

                        self._instances[kept] = inst
                    end
                end
                for i = #self._instances, kept + 1, -1 do
                    self._instances[i] = nil
                end

                for _, root in roots do
                    root:Destroy()
                end
            end
            function Window:_runGuarded(element: any, fn: (...any) -> (), ...: any)
                if element and element.locked then
                    return
                end

                local args = table.pack(...)

                task.spawn(function()
                    local ok, err = pcall(function()
                        return fn(table.unpack(args, 1, args.n))
                    end)

                    if ok or (element and element._errored) then
                        return
                    end
                    if element then
                        element._errored = true
                    end

                    local flashFrame = element and (element._flashTarget or element._frame or element.main) or nil
                    local stroke = element and (element._stroke or element.stroke) or nil
                    local errColor = self._theme.ErrorColor or Color3.fromHex('#ff4f58')

                    if flashFrame and typeof(flashFrame) == 'Instance' and flashFrame.Parent then
                        variables.tweenService:Create(flashFrame, constants.tweenFast, {BackgroundColor3 = errColor}):Play()
                    end
                    if stroke and typeof(stroke) == 'Instance' and stroke.Parent then
                        variables.tweenService:Create(stroke, constants.tweenFast, {Color = errColor}):Play()
                    end

                    warn('[Delirium] callback error in ' .. tostring(element and element.__type or 'element') .. " '" .. tostring(element and element.name or '?') .. "': " .. tostring(err))
                    task.wait(1)

                    if element and element._flashToken then
                    end
                    if flashFrame and typeof(flashFrame) == 'Instance' and flashFrame.Parent then
                        variables.tweenService:Create(flashFrame, constants.tweenSlow, {
                            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                        }):Play()
                    end
                    if stroke and typeof(stroke) == 'Instance' and stroke.Parent then
                        variables.tweenService:Create(stroke, constants.tweenSlow, {
                            Color = self._theme.ElementStroke or Color3.fromHex('#2b2b2b'),
                        }):Play()
                    end
                    if element then
                        element._errored = false
                    end
                end)
            end
            function Window:_reveal(
                instance: Instance?,
                props: {[string]: any},
                animate: boolean?,
                info: TweenInfo?
            )
                if not instance then
                    return
                end
                if animate then
                    variables.tweenService:Create(instance, info or constants.tweenNormal, props):Play()
                else
                    for property, value in props do
                        instance[property] = value
                    end
                end
            end
            function Window:_revealCommon(element: any, animate: boolean?)
                local e = element
                local frame = e._frame or e.main
                local stroke = e._stroke or e.stroke
                local title = e._title or e.title
                local iconLabel = e._iconLabel or e.iconLabel
                local descriptor = e._descriptor or e.descriptor
                local theme = self._theme

                if stroke then
                    self:_reveal(stroke, {
                        Color = theme.ElementStroke or Color3.fromHex('#2b2b2b'),
                        Transparency = theme.ElementStrokeTransparency or 0,
                    }, animate)
                end
                if title then
                    self:_reveal(title, {
                        TextColor3 = theme.ContentColor or Color3.fromHex('#ffffff'),
                    }, animate)
                end
                if frame then
                    self:_reveal(frame, {
                        BackgroundTransparency = theme.ElementTransparency or 0,
                    }, animate)
                end
                if iconLabel then
                    self:_reveal(iconLabel, {
                        ImageColor3 = theme.ContentColor or Color3.fromHex('#ffffff'),
                    }, animate)
                end
                if descriptor then
                    local label = descriptor._label or descriptor.titleLabel

                    if label then
                        self:_reveal(label, {TextTransparency = 0.35}, animate)
                    end
                end
            end
            function Window:_hideCommon(element: any, animate: boolean?)
                local e = element
                local frame = e._frame or e.main
                local stroke = e._stroke or e.stroke
                local title = e._title or e.title
                local iconLabel = e._iconLabel or e.iconLabel
                local descriptor = e._descriptor or e.descriptor

                self:_reveal(stroke, {Transparency = 1}, animate)
                self:_reveal(title, {TextTransparency = 1}, animate)
                self:_reveal(frame, {BackgroundTransparency = 1}, animate)

                if iconLabel then
                    self:_reveal(iconLabel, {ImageTransparency = 1}, animate)
                end
                if descriptor then
                    local label = descriptor._label or descriptor.titleLabel

                    if label then
                        self:_reveal(label, {TextTransparency = 1}, animate)
                    end
                end
            end
            function Window:StyleElementBody(main: GuiObject): UIStroke
                local theme = self._theme or self.theme or {}
                local grad = self:Create('UIGradient', {
                    Rotation = 270,
                    Parent = main,
                })

                grad.Color = theme.ElementGradient or ColorSequence.new(Color3.fromRGB(255, 255, 255))

                self:Create('UICorner', {
                    CornerRadius = theme.ElementCornerRadius or UDim.new(0, 10),
                    Parent = main,
                })

                return self:Create('UIStroke', {
                    Color = theme.ElementStroke or Color3.fromRGB(55, 55, 60),
                    Transparency = 1,
                    Thickness = 1,
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                    Parent = main,
                })
            end
            function Window:CreateGlow(
                parent: GuiObject,
                color: (Color3 | string)?,
                blur: number?,
                transparency: number?
            ): any
                local theme = self._theme or self.theme or {}
                local resolvedColor = Color3.fromRGB(255, 255, 255)

                if typeof(color) == 'Color3' then
                    resolvedColor = color
                elseif typeof(color) == 'string' then
                    local c = theme[color]

                    if typeof(c) == 'Color3' then
                        resolvedColor = c
                    elseif typeof(c) == 'ColorSequence' then
                        resolvedColor = c.Keypoints[1].Value
                    else
                        resolvedColor = theme.AccentColor or Color3.fromRGB(0, 180, 120)
                    end
                end

                local b = blur or 13
                local t = transparency or 1
                local ok, shadow = pcall(function()
                    return self:Create('UIShadow', {
                        BlurRadius = UDim.new(0, b),
                        Color = resolvedColor,
                        Transparency = t,
                        ZIndex = -1,
                        Parent = parent,
                    })
                end)

                if ok and shadow then
                    return shadow
                end

                local glow = self:Create('Frame', {
                    Name = 'Glow',
                    Size = UDim2.new(1, b, 1, b),
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.fromScale(0.5, 0.5),
                    BackgroundColor3 = resolvedColor,
                    BackgroundTransparency = t,
                    BorderSizePixel = 0,
                    ZIndex = -1,
                    Parent = parent,
                })

                self:Create('UICorner', {
                    CornerRadius = UDim.new(0, b),
                    Parent = glow,
                })

                return glow
            end
            function Window:_bindLocale(
                instance: Instance,
                property: string,
                source: string
            )
                local locale = require(script.Parent.Parent.utility.locale)

                instance[property] = locale.resolve(source)

                local props = self.localeProperties or {}

                self.localeProperties = props

                local entries = props[instance]

                if not entries then
                    entries = {}
                    props[instance] = entries
                end

                entries[property] = source
            end
            function Window:SetLocale(localeId: string)
                local locale = require(script.Parent.Parent.utility.locale)

                locale.setActive(localeId)

                if self.localeProperties then
                    for instance, entries in self.localeProperties do
                        local target: any = instance

                        if target.Parent then
                            for property, source in entries do
                                target[property] = locale.resolve(source)
                            end
                        end
                    end
                end
            end
            function Window:_flashResult(element: any, ok: boolean)
                local box = element._flashTarget or element._frame or element.main
                local stroke = element._stroke or element.stroke
                local glow = element._glow or element.glow
                local fill = if ok then(self._theme.AccentColor or Color3.fromHex('#4cc2ff'))else(self._theme.ErrorColor or Color3.fromHex('#ff4f58'))
                local edge = fill

                if box and typeof(box) == 'Instance' and box.Parent then
                    variables.tweenService:Create(box, constants.tweenFocus, {BackgroundColor3 = fill}):Play()
                end
                if stroke and typeof(stroke) == 'Instance' and stroke.Parent then
                    variables.tweenService:Create(stroke, constants.tweenFocus, {
                        Color = edge,
                        Transparency = 0.4,
                    }):Play()
                end
                if glow and typeof(glow) == 'Instance' and glow.Parent then
                    variables.tweenService:Create(glow, constants.tweenFocus, {
                        Color = edge,
                        Transparency = 0.6,
                    }):Play()
                end

                element._flashToken = (element._flashToken or 0) + 1

                local token = element._flashToken

                task.delay(0.22, function()
                    if element._flashToken ~= token then
                        return
                    end
                    if box and box.Parent then
                        variables.tweenService:Create(box, constants.tweenFast, {
                            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                        }):Play()
                    end
                    if stroke and stroke.Parent then
                        variables.tweenService:Create(stroke, constants.tweenFast, {
                            Color = self._theme.ElementStroke or Color3.fromHex('#2b2b2b'),
                            Transparency = self._theme.ElementStrokeTransparency or 0,
                        }):Play()
                    end
                    if glow and glow.Parent then
                        variables.tweenService:Create(glow, constants.tweenFast, {
                            Transparency = element._glowIdle or 1,
                        }):Play()
                    end
                end)
            end
            function Window:_registerControl(control: any)
                local flagKey = control._flag or control.flag

                if not flagKey or flagKey == '' then
                    return
                end
                if self.controls[flagKey] and self.controls[flagKey] ~= control then
                    local base = flagKey
                    local n = 2

                    while self.controls[base .. tostring(n)] do
                        n += 1
                    end

                    flagKey = base .. tostring(n)

                    warn("[Delirium] duplicate config flag '" .. base .. "', saving this one as '" .. flagKey .. "'")

                    control._flag = flagKey
                    control.flag = flagKey
                end

                self.controls[flagKey] = control

                saveManager:Register(flagKey, control)

                return flagKey
            end
            function Window:_persist(_control: any) end
            function Window:_restoreLate(_element: any) end
            function Window:_refreshElementThemes()
                local s = (self::any)
                local tabs = s._tabs

                if not tabs then
                    return
                end

                for _, tab in tabs do
                    local elements = (tab::any)._elements

                    if elements then
                        for _, el in elements do
                            if el and typeof(el._refreshTheme) == 'function' then
                                pcall(el._refreshTheme, el)
                            end
                        end
                    end
                end
            end
            function Window:_clampedPositionForScale(
                position: UDim2,
                scale: number
            ): UDim2
                if not (self::any)._keepOnScreen then
                    return position
                end

                local screen = self._gui.AbsoluteSize
                local s = (self::any)
                local baseW = if s._windowFrame then s._windowFrame.Size.X.Offset else s._windowSize.X.Offset
                local baseH = if s._minimized then s._titlebarH else s._windowSize.Y.Offset
                local curW = baseW * scale
                local curH = baseH * scale
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
                if newX == position.X.Offset and newY == position.Y.Offset then
                    return position
                end

                return UDim2.fromOffset(newX, newY)
            end
            function Window:_clampedPosition(position: UDim2): UDim2
                if not (self::any)._keepOnScreen then
                    return position
                end

                local s = (self::any)
                local scale = if s._winScale then s._winScale.Scale else 1

                return self:_clampedPositionForScale(position, scale)
            end
            function Window:_clampToScreen()
                local wf: Frame = (self::any)._windowFrame

                wf.Position = self:_clampedPosition(wf.Position)
            end
            function Window:_applyWindowSize()
                if self.unloaded then
                    return
                end

                local s = (self::any)
                local cam = variables.workspace.CurrentCamera
                local userMultiplier = s._userScale or 1

                variables.uiScale = userMultiplier

                if s._winScale and s._scaleTween == nil then
                    s._winScale.Scale = userMultiplier
                end

                local newSize = fitWindowSize()
                local changed = newSize ~= s._windowSize

                s._windowSize = newSize

                local hidden = not s._visible
                local minimized = s._minimized
                local dragging = s._dragging

                if hidden or minimized or dragging or s._activeTween ~= nil then
                    if changed then
                        s._pendingResize = true
                    end

                    return
                end
                if not changed and not s._pendingResize then
                    return
                end

                s._pendingResize = false

                local wf: Frame = (self::any)._windowFrame

                wf.Size = newSize

                local vp = if cam then cam.ViewportSize else nil

                if not s._hasBeenDragged and vp then
                    wf.Position = UDim2.fromOffset(math.floor(vp.X / 2), math.floor(vp.Y / 2))
                else
                    self:_clampToScreen()
                end
            end
            function Window:_watchViewport()
                local s = (self::any)
                local pending = false

                local function request()
                    if pending then
                        return
                    end

                    pending = true

                    task.defer(function()
                        pending = false

                        self:_applyWindowSize()
                    end)
                end
                local function bind()
                    if s._cameraConn then
                        s._cameraConn:Disconnect()

                        s._cameraConn = nil
                    end

                    local cam = variables.workspace.CurrentCamera

                    if cam then
                        s._cameraConn = cam:GetPropertyChangedSignal('ViewportSize'):Connect(request)
                    end

                    request()
                end

                local camSwapConn = variables.workspace:GetPropertyChangedSignal('CurrentCamera'):Connect(bind)

                table.insert(s._connections, camSwapConn)
                bind()
            end
            function Window:CreateTab(props: Tab.TabProps): Tab.Tab
                local tabs: {Tab.Tab} = (self::any)._tabs
                local sidebar: Frame = (self::any)._sidebar
                local contentArea: Frame = (self::any)._contentArea
                local theme: {[string]: any} = (self::any)._theme
                local wf: Frame = (self::any)._windowFrame
                local selfAny = self::any
                local t = Tab.new(props, theme, contentArea, sidebar, wf)
                local tabAny = t::any

                tabAny._window = self

                local btn = tabAny._tabButton

                if not props.neglectSelector then
                    local isDraggingTab = false
                    local dragInputConn: RBXScriptConnection? = nil
                    local dragEndConn: RBXScriptConnection? = nil
                    local startY = 0

                    btn.InputBegan:Connect(function(input: InputObject)
                        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
                            return
                        end

                        startY = input.Position.Y
                        isDraggingTab = false

                        if dragInputConn then
                            dragInputConn:Disconnect()
                        end
                        if dragEndConn then
                            dragEndConn:Disconnect()
                        end

                        local tabScale = tabAny._tabScale

                        if not tabScale then
                            tabScale = Instance.new('UIScale')
                            tabScale.Scale = 1
                            tabScale.Parent = btn
                            tabAny._tabScale = tabScale
                        end

                        local tabStroke = tabAny._tabStroke
                        local indicator = tabAny._indicator

                        local function resetDragVisual()
                            btn.ZIndex = constants.zIndex.base

                            tween.fire(tabScale, constants.tweenFast, {Scale = 1})

                            local isActive = selfAny._activeTab == t

                            if isActive then
                                tween.fire(btn, constants.tweenFast, {
                                    BackgroundColor3 = theme.AccentColor or Color3.fromHex('#4cc2ff'),
                                    BackgroundTransparency = 0.86,
                                })

                                if tabStroke then
                                    tween.fire(tabStroke, constants.tweenFast, {
                                        Color = theme.AccentColor or Color3.fromHex('#4cc2ff'),
                                        Transparency = 0.4,
                                        Thickness = 1,
                                    })
                                end
                                if indicator and indicator:IsA('GuiObject') then
                                    tween.fire(indicator, constants.tweenFast, {
                                        Size = UDim2.fromOffset(3, 18),
                                        BackgroundTransparency = 0,
                                    })
                                end
                            else
                                tween.fire(btn, constants.tweenFast, {BackgroundTransparency = 1})

                                if tabStroke then
                                    tween.fire(tabStroke, constants.tweenFast, {
                                        Transparency = 1,
                                        Color = theme.SurfaceStroke or Color3.fromHex('#2b2b2b'),
                                        Thickness = 1,
                                    })
                                end
                                if indicator and indicator:IsA('GuiObject') then
                                    tween.fire(indicator, constants.tweenFast, {
                                        Size = UDim2.fromOffset(3, 0),
                                        BackgroundTransparency = 1,
                                    })
                                end
                            end
                        end

                        local startTouchX = input.Position.X

                        dragInputConn = variables.userInputService.InputChanged:Connect(function(
                            moveInput: InputObject
                        )
                            if moveInput.UserInputType ~= Enum.UserInputType.MouseMovement and moveInput.UserInputType ~= Enum.UserInputType.Touch then
                                return
                            end

                            local deltaY = moveInput.Position.Y - startY
                            local deltaX = moveInput.Position.X - startTouchX

                            if not isDraggingTab then
                                local absY = math.abs(deltaY)
                                local absX = math.abs(deltaX)
                                local DRAG_THRESHOLD = if variables.isTouchOnly then 22 else 18

                                if absY < DRAG_THRESHOLD then
                                    return
                                end
                                if variables.isTouchOnly and absY < absX * 1.5 then
                                    return
                                end

                                isDraggingTab = true
                                selfAny._isDraggingAnyTab = true
                                btn.ZIndex = constants.zIndex.drag

                                tween.fire(tabScale, constants.tweenFast, {Scale = 1.05})
                                tween.fire(btn, constants.tweenFast, {
                                    BackgroundColor3 = theme.AccentColor or Color3.fromHex('#4cc2ff'),
                                    BackgroundTransparency = 0.78,
                                })

                                if tabStroke then
                                    tween.fire(tabStroke, constants.tweenFast, {
                                        Color = theme.AccentColor or Color3.fromHex('#4cc2ff'),
                                        Transparency = 0.15,
                                        Thickness = 1.5,
                                    })
                                end
                                if indicator and indicator:IsA('GuiObject') then
                                    tween.fire(indicator, constants.tweenFast, {
                                        Size = UDim2.fromOffset(3, 20),
                                        BackgroundTransparency = 0,
                                    })
                                end
                            end
                            if isDraggingTab then
                                local curIdx = table.find(tabs, t)

                                if curIdx then
                                    local btnH = btn.AbsoluteSize.Y
                                    local btnMidY = btn.AbsolutePosition.Y + btnH * 0.5
                                    local cursorY = moveInput.Position.Y
                                    local SWAP_ZONE = 0.45
                                    local SWAP_COOLDOWN = 0.18
                                    local now = os.clock()
                                    local lastSwap = tabAny._lastSwapTime or 0

                                    if (now - lastSwap) >= SWAP_COOLDOWN then
                                        if cursorY < btnMidY - btnH * SWAP_ZONE and curIdx > 1 then
                                            tabAny._lastSwapTime = now

                                            local aboveTab = tabs[curIdx - 1]

                                            tabs[curIdx - 1] = t
                                            tabs[curIdx] = aboveTab

                                            local abScale = (aboveTab::any)._tabScale

                                            if abScale then
                                                abScale.Scale = 0.94

                                                tween.fire(abScale, constants.tweenFast, {Scale = 1})
                                            end

                                            for i, tb in ipairs(tabs)do
                                                local b = (tb::any)._tabButton

                                                if b then
                                                    b.LayoutOrder = i
                                                end
                                            end
                                        elseif cursorY > btnMidY + btnH * SWAP_ZONE and curIdx < #tabs then
                                            tabAny._lastSwapTime = now

                                            local belowTab = tabs[curIdx + 1]

                                            tabs[curIdx + 1] = t
                                            tabs[curIdx] = belowTab

                                            local bbScale = (belowTab::any)._tabScale

                                            if bbScale then
                                                bbScale.Scale = 0.94

                                                tween.fire(bbScale, constants.tweenFast, {Scale = 1})
                                            end

                                            for i, tb in ipairs(tabs)do
                                                local b = (tb::any)._tabButton

                                                if b then
                                                    b.LayoutOrder = i
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end)
                        dragEndConn = variables.userInputService.InputEnded:Connect(function(
                            endInput: InputObject
                        )
                            if endInput.UserInputType ~= Enum.UserInputType.MouseButton1 and endInput.UserInputType ~= Enum.UserInputType.Touch then
                                return
                            end
                            if dragInputConn then
                                dragInputConn:Disconnect()

                                dragInputConn = nil
                            end
                            if dragEndConn then
                                dragEndConn:Disconnect()

                                dragEndConn = nil
                            end

                            tabAny._activeDragMoveConn = nil
                            tabAny._activeDragEndConn = nil

                            if isDraggingTab then
                                resetDragVisual()

                                tabAny._lastSwapTime = 0

                                for i, tb in ipairs(tabs)do
                                    local b = (tb::any)._tabButton

                                    if b then
                                        b.LayoutOrder = i
                                    end
                                end

                                task.delay(0.08, function()
                                    isDraggingTab = false
                                    selfAny._isDraggingAnyTab = false
                                end)
                            else
                                resetDragVisual()
                            end
                        end)
                        tabAny._activeDragMoveConn = dragInputConn
                        tabAny._activeDragEndConn = dragEndConn
                    end)
                    btn.Activated:Connect(function()
                        if isDraggingTab then
                            return
                        end

                        (self::any):_activateTab(t)
                    end)
                end

                table.insert(tabs, t)

                if not props.neglectSelector then
                    local maxOrder = 0

                    for _, child in sidebar:GetChildren()do
                        if child:IsA('GuiObject') and child.LayoutOrder > maxOrder then
                            maxOrder = child.LayoutOrder
                        end
                    end

                    btn.LayoutOrder = maxOrder + 1

                    local selectorCount = 0

                    for _, tb in tabs do
                        if not (tb::any)._neglectSelector then
                            selectorCount += 1
                        end
                    end

                    if selectorCount == 1 then
                        local _s = (self::any)

                        _s:_activateTab(t)
                    else
                        t:Hide()
                    end
                else
                    t:Hide()
                end

                return t
            end
            function Window:CreateTabDivider(text: string?): TabDivider
                local s = (self::any)
                local sidebar: Frame = s._sidebar
                local theme: {[string]: any} = s._theme
                local colorBorder = theme.SurfaceStroke or Color3.fromRGB(48, 48, 58)
                local colorTextSec = theme.PlaceholderColor or Color3.fromRGB(150, 150, 160)
                local colorAccent = theme.AccentColor or Color3.fromHex('#4cc2ff')
                local dividerFrame = Instance.new('Frame')

                dividerFrame.Name = 'TabDivider'
                dividerFrame.BackgroundTransparency = 1
                dividerFrame.BorderSizePixel = 0

                local currentOrder = 0

                if sidebar then
                    for _, child in sidebar:GetChildren()do
                        if child:IsA('GuiObject') and child.LayoutOrder > currentOrder then
                            currentOrder = child.LayoutOrder
                        end
                    end
                end

                dividerFrame.LayoutOrder = currentOrder + 1

                local labelText: TextLabel? = nil
                local leftLine: Frame? = nil
                local rightLine: Frame? = nil
                local accentDot: Frame? = nil

                if text and #text > 0 then
                    dividerFrame.Size = UDim2.new(1, 0, 0, 20)

                    local row = Instance.new('Frame')

                    row.Name = 'Row'
                    row.Size = UDim2.fromScale(1, 1)
                    row.BackgroundTransparency = 1
                    row.Parent = dividerFrame

                    local rowLayout = Instance.new('UIListLayout')

                    rowLayout.FillDirection = Enum.FillDirection.Horizontal
                    rowLayout.VerticalAlignment = Enum.VerticalAlignment.Center
                    rowLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
                    rowLayout.Padding = UDim.new(0, 6)
                    rowLayout.Parent = row

                    local rowPad = Instance.new('UIPadding')

                    rowPad.PaddingLeft = UDim.new(0, 4)
                    rowPad.PaddingRight = UDim.new(0, 4)
                    rowPad.Parent = row
                    accentDot = Instance.new('Frame')
                    accentDot.Name = 'Dot'
                    accentDot.Size = UDim2.fromOffset(3, 3)
                    accentDot.BackgroundColor3 = colorAccent
                    accentDot.BorderSizePixel = 0
                    accentDot.Parent = row

                    do
                        local c = Instance.new('UICorner')

                        c.CornerRadius = UDim.new(1, 0)
                        c.Parent = accentDot
                    end

                    labelText = Instance.new('TextLabel')
                    labelText.Name = 'Label'
                    labelText.AutomaticSize = Enum.AutomaticSize.X
                    labelText.Size = UDim2.new(0, 0, 1, 0)
                    labelText.BackgroundTransparency = 1
                    labelText.Text = string.upper(text)
                    labelText.TextColor3 = colorTextSec
                    labelText.TextTransparency = 0.4
                    labelText.TextSize = 9
                    labelText.FontFace = constants.DEFAULT_FONT_BOLD
                    labelText.TextXAlignment = Enum.TextXAlignment.Left
                    labelText.Parent = row
                    rightLine = Instance.new('Frame')
                    rightLine.Name = 'Line'
                    rightLine.Size = UDim2.new(1, 0, 0, 1)
                    rightLine.BackgroundColor3 = colorBorder
                    rightLine.BackgroundTransparency = 0.65
                    rightLine.BorderSizePixel = 0
                    rightLine.Parent = row
                else
                    dividerFrame.Size = UDim2.new(1, 0, 0, 10)

                    local line = Instance.new('Frame')

                    line.Name = 'Line'
                    line.AnchorPoint = Vector2.new(0.5, 0.5)
                    line.Position = UDim2.fromScale(0.5, 0.5)
                    line.Size = UDim2.new(1, -8, 0, 1)
                    line.BackgroundColor3 = colorBorder
                    line.BackgroundTransparency = 0.7
                    line.BorderSizePixel = 0
                    line.Parent = dividerFrame
                    rightLine = line
                end

                dividerFrame.Parent = sidebar

                local themeUnsub = themeUtil.subscribe(function(t)
                    if labelText then
                        labelText.TextColor3 = t.PlaceholderColor
                    end
                    if rightLine then
                        rightLine.BackgroundColor3 = t.SurfaceStroke
                    end
                    if leftLine then
                        leftLine.BackgroundColor3 = t.SurfaceStroke
                    end
                    if accentDot then
                        accentDot.BackgroundColor3 = t.AccentColor
                    end
                end, dividerFrame)
                local dividerObj: TabDivider = {
                    _frame = dividerFrame,
                    SetText = function(_, newText: string)
                        if labelText then
                            labelText.Text = string.upper(newText)
                        end
                    end,
                    Destroy = function(_)
                        if themeUnsub then
                            themeUnsub()

                            themeUnsub = nil::any
                        end

                        dividerFrame:Destroy()
                    end,
                }

                if s._tabDividers == nil then
                    s._tabDividers = {}
                end

                table.insert(s._tabDividers, dividerObj)

                return dividerObj
            end
            function Window:ReorderTab(targetTab: Tab.Tab, newIndex: number)
                local s = (self::any)
                local tabs: {Tab.Tab} = s._tabs
                local oldIndex = table.find(tabs, targetTab)

                if not oldIndex then
                    return
                end

                newIndex = math.clamp(newIndex, 1, #tabs)

                if oldIndex == newIndex then
                    return
                end

                table.remove(tabs, oldIndex)
                table.insert(tabs, newIndex, targetTab)

                for i, tab in ipairs(tabs)do
                    local btn = (tab::any)._tabButton

                    if btn then
                        btn.LayoutOrder = i
                    end
                end
            end
            function Window:GetTabs(): {Tab.Tab}
                local s = (self::any)
                local result: {Tab.Tab} = {}

                for _, tab in s._tabs do
                    if not (tab::any)._neglectSelector then
                        table.insert(result, tab)
                    end
                end

                return result
            end
            function Window:SetTabsHeader(header: string)
                local s = (self::any)

                if s._sidebarHeader then
                    local lbl = s._sidebarHeader:FindFirstChild('Label')::TextLabel?

                    if lbl then
                        lbl.Text = string.upper(header)
                    end
                end
            end
            function Window:CreatePlayerCard()
                local s = (self::any)
                local slot: Frame = s._footerBar
                local wf: Frame = s._windowFrame
                local ca: Frame = s._contentArea
                local theme = s._theme
                local pc = PlayerCard.new(slot, wf, ca, theme)

                s._playerCard = pc

                local function openDashboard()
                    if s._updateSettingsBtnVisual then
                        s._updateSettingsBtnVisual(false)
                    end

                    variables.settingsOpen = false
                    variables.settingsPanelInstance = nil

                    for _, tab in (s._tabs::{any})do
                        tab:Hide()
                    end

                    s._activeTab = nil

                    pc:ShowContent()
                end

                local openBtn = (pc::any)._openButton::TextButton?

                if openBtn then
                    openBtn.Activated:Connect(openDashboard)
                end

                local cardHit = (pc::any)._cardHit::TextButton?

                if cardHit then
                    cardHit.Active = false
                    cardHit.Size = UDim2.fromScale(0, 0)
                end

                return pc
            end
            function Window:_activateTab(target: Tab.Tab)
                local s = (self::any)

                s._activeTab = target

                local pc: any = s._playerCard

                if pc and typeof(pc.HideContent) == 'function' then
                    pc:HideContent()
                end

                local isSettings = (target == s.rfSettings)

                variables.settingsOpen = isSettings
                variables.settingsPanelInstance = if isSettings then(s.rfSettings::any)._frame else nil

                if s._updateSettingsBtnVisual then
                    s._updateSettingsBtnVisual(isSettings)
                end

                local tabs: {Tab.Tab} = s._tabs

                for _, tab in tabs do
                    if tab == target then
                        tab:Show()
                    else
                        tab:Hide()
                    end
                end
            end
            function Window:Notify(props: notification.NotifyProps)
                if self.unloaded then
                    return
                end

                local p = table.clone(props)::any

                if not p.content and p.subtitle then
                    p.content = p.subtitle
                end

                notification.send(p, (self::any)._theme)
            end
            function Window:Toast(props: any): any
                if self.unloaded then
                    return
                end

                local s = self::any
                local position = props.position or props.Position or 'Top'
                local isTop = typeof(position) ~= 'string' or string.lower(position) ~= 'bottom'
                local containerKey = if isTop then'_toastsTop'else'_toastsBottom'
                local container = s[containerKey]

                if not container then
                    local maxToastWidth = 320
                    local toastFrame = Instance.new('Frame')

                    toastFrame.Name = if isTop then'ToastsTop'else'ToastsBottom'
                    toastFrame.Size = UDim2.new(0, maxToastWidth, 1, -24)
                    toastFrame.Position = if isTop then UDim2.new(0.5, 0, 0, 12)else UDim2.new(0.5, 0, 1, 
-12)
                    toastFrame.AnchorPoint = if isTop then Vector2.new(0.5, 0)else Vector2.new(0.5, 1)
                    toastFrame.BackgroundTransparency = 1
                    toastFrame.BorderSizePixel = 0
                    toastFrame.ZIndex = constants.zIndex.toast
                    toastFrame.Parent = s._gui or variables.guiContainer

                    local list = Instance.new('UIListLayout')

                    list.FillDirection = Enum.FillDirection.Vertical
                    list.VerticalAlignment = if isTop then Enum.VerticalAlignment.Top else Enum.VerticalAlignment.Bottom
                    list.HorizontalAlignment = Enum.HorizontalAlignment.Center
                    list.SortOrder = Enum.SortOrder.LayoutOrder
                    list.Padding = UDim.new(0, 6)
                    list.Parent = toastFrame
                    s[containerKey] = toastFrame
                    self[containerKey] = toastFrame

                    if not s.toasts then
                        s.toasts = toastFrame
                        self.toasts = toastFrame
                    end

                    container = toastFrame
                end

                s._toastCount = (s._toastCount or 0) + 1
                self._toastCount = s._toastCount

                local success, toastModule = pcall(function()
                    return require(script.Parent.toast)
                end)

                if success and toastModule and typeof(toastModule.new) == 'function' then
                    return toastModule.new(self, props, container)
                else
                    self:Notify(props)

                    return nil
                end
            end
            function Window:CreateTag(props: any): any
                if self.unloaded then
                    return
                end

                local Tag = require(script.Parent.tag)

                return Tag.new(self, props)
            end
            function Window:ToggleSearch()
                if self.unloaded then
                    return
                end

                local s = self::any

                if s._toggleSearch then
                    s._toggleSearch()
                end
            end
            function Window:OpenSearch()
                if self.unloaded then
                    return
                end

                local s = self::any

                if s._openSearch then
                    s._openSearch()
                end
            end
            function Window:CloseSearch()
                if self.unloaded then
                    return
                end

                local s = self::any

                if s._closeSearch then
                    s._closeSearch()
                end
            end
            function Window:Save(name: string?): boolean
                if self.unloaded then
                    return false
                end

                return saveManager:Save(name)
            end
            function Window:Load(name: string?): number
                if self.unloaded then
                    return 0
                end

                return saveManager:Load(name)
            end
            function Window:ListConfigs(): {string}
                if self.unloaded then
                    return {}
                end

                return saveManager:List()
            end
            function Window:DeleteConfig(name: string): boolean
                if self.unloaded then
                    return false
                end

                return saveManager:Delete(name)
            end
            function Window:SetAutoLoad(name: string)
                if self.unloaded then
                    return
                end

                saveManager:SetActiveProfile(name)
                saveManager:SetAutoLoadEnabled(true)
            end
            function Window:Show()
                if self.unloaded then
                    return
                end

                local s = (self::any)
                local windowFrame: Frame = s._windowFrame

                if s._minimized then
                    if s._activeTween then
                        s._activeTween:Cancel()

                        s._activeTween = nil
                    end

                    s._minimized = false

                    if s._body then
                        s._body.Visible = true
                    end
                    if s._divider then
                        s._divider.Visible = true
                    end
                    if s._titleSep then
                        s._titleSep.Visible = true
                    end
                    if s._footerBar then
                        (s._footerBar::Frame).Visible = true
                    end

                    local fullH: number = s._windowSize.Y.Offset
                    local _scale = s._userScale or 1
                    local topY = windowFrame.Position.Y.Offset - math.floor(s._titlebarH * _scale / 2)
                    local restoreCenterY = topY + math.floor(fullH * _scale / 2)

                    windowFrame.Position = self:_clampedPosition(UDim2.fromOffset(windowFrame.Position.X.Offset, restoreCenterY))
                    windowFrame.Size = s._windowSize

                    if s._titleBarBg then
                        s._titleBarBg.Size = UDim2.new(1, 0, 0, s._titlebarH + (s._cornerOffset or 10))
                    end
                    if s._minBtn then
                        s._minBtn.Text = ''
                    end
                    if s._minIcon then
                        (s._minIcon::ImageLabel).Image = ICON_MINIMIZE
                    end
                end
                if s._pendingResize then
                    s._pendingResize = false
                    windowFrame.Size = s._windowSize
                end

                s._visible = true
                self.hidden = false
                s.hidden = false

                pcall(function()
                    local uis = variables.userInputService

                    s._savedMouseBehavior = uis.MouseBehavior
                    s._savedMouseIconEnabled = uis.MouseIconEnabled
                    uis.MouseBehavior = Enum.MouseBehavior.Default
                    uis.MouseIconEnabled = true
                end)

                windowFrame.Position = self:_clampedPosition(windowFrame.Position)

                if windowFrame.Visible then
                    return
                end

                windowFrame.BackgroundTransparency = (s._theme and s._theme.WindowTransparency) or 0
                windowFrame.Visible = true

                local revealOverlay = windowFrame:FindFirstChild('_RevealOverlay')

                if not revealOverlay then
                    local ov = Instance.new('Frame')

                    ov.Name = '_RevealOverlay'
                    ov.Size = UDim2.fromScale(1, 1)
                    ov.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                    ov.BackgroundTransparency = 0
                    ov.BorderSizePixel = 0
                    ov.ZIndex = 9999
                    ov.Parent = windowFrame

                    if s._winCorner then
                        local ovCorner = Instance.new('UICorner')

                        ovCorner.CornerRadius = s._winCorner.CornerRadius
                        ovCorner.Parent = ov
                    end

                    revealOverlay = ov

                    local ro: Frame = revealOverlay::any

                    ro.BackgroundTransparency = 0
                end

                task.spawn(function()
                    variables.runService.RenderStepped:Wait()

                    if not s._visible or self.unloaded then
                        return
                    end

                    tween.fire(revealOverlay::Frame, constants.tweenNormal, {BackgroundTransparency = 1})
                end)

                if s._gestureRestorePill then
                    s._gestureRestorePill()
                end
            end
            function Window:Hide()
                if self.unloaded then
                    return
                end

                local s = (self::any)
                local windowFrame: Frame = s._windowFrame

                if s._settingsPanel and s._settingsPanel.Visible then
                    if s._closeSettings then
                        s._closeSettings()
                    else
                        s._settingsPanel.Visible = false
                        variables.settingsOpen = false
                        variables.settingsPanelInstance = nil
                    end
                end

                s._visible = false
                self.hidden = true
                s.hidden = true

                pcall(function()
                    local uis = variables.userInputService

                    if s._savedMouseBehavior ~= nil then
                        uis.MouseBehavior = s._savedMouseBehavior
                        s._savedMouseBehavior = nil
                    end
                    if s._savedMouseIconEnabled ~= nil then
                        uis.MouseIconEnabled = s._savedMouseIconEnabled
                        s._savedMouseIconEnabled = nil
                    end
                end)

                windowFrame.Visible = false

                if s._searchBox then
                    s._searchBox.Text = ''
                end
                if s._hideSearchResults then
                    s._hideSearchResults()
                end
                if s._collapseSearch then
                    s._collapseSearch(true)
                end
                if s._gestureRestorePill then
                    s._gestureRestorePill()
                end
            end
            function Window:ToggleHide()
                if (self::any)._visible then
                    self:Hide()
                else
                    self:Show()
                end
            end
            function Window:ToggleMinimise()
                if self.unloaded then
                    return
                end

                local s = (self::any)

                if not s._visible then
                    return
                end
                if s._activeTween then
                    s._activeTween:Cancel()

                    s._activeTween = nil
                end

                local windowFrame: Frame = s._windowFrame
                local body: Frame = s._body
                local divider: Frame? = s._divider
                local titlebarH: number = s._titlebarH
                local fullH: number = s._windowSize.Y.Offset
                local width: number = s._windowSize.X.Offset
                local keepOnScreen: boolean = s._keepOnScreen
                local screen = self._gui.AbsoluteSize
                local margin = 8
                local posX = windowFrame.Position.X.Offset
                local posY = windowFrame.Position.Y.Offset
                local scale = s._userScale or 1

                if keepOnScreen then
                    local halfW = math.floor(width * scale / 2)

                    posX = math.clamp(posX, halfW + margin, math.max(halfW + margin, screen.X - halfW - margin))
                end

                local TWEEN_INFO = constants.tweenNormal

                if s._minimized then
                    s._minimized = false
                    s._pendingResize = false

                    local topY = posY - math.floor(titlebarH * scale / 2)
                    local targetCY = topY + math.floor(fullH * scale / 2)

                    if keepOnScreen then
                        local halfH = math.floor(fullH * scale / 2)

                        targetCY = math.clamp(targetCY, halfH + margin, math.max(halfH + margin, screen.Y - halfH - margin))
                    end

                    body.Visible = false

                    if divider then
                        divider.Visible = true
                    end
                    if s._titleSep then
                        (s._titleSep::Frame).Visible = true
                    end
                    if s._footerBar then
                        (s._footerBar::Frame).Visible = true
                    end

                    local tw = tween.play(windowFrame, TWEEN_INFO, {
                        Size = UDim2.fromOffset(width, fullH),
                        Position = UDim2.fromOffset(posX, targetCY),
                    })

                    s._activeTween = tw

                    if s._titleBarBg then
                        s._titleBarBg.Size = UDim2.new(1, 0, 0, titlebarH + (s._cornerOffset or 10))
                    end

                    tw.Completed:Once(function()
                        tw:Destroy()

                        if s._activeTween == tw then
                            s._activeTween = nil

                            if not s._minimized then
                                body.Visible = true

                                if s._footerBar then
                                    (s._footerBar::Frame).Visible = true
                                end
                            end
                        end
                    end)

                    if s._minBtn then
                        s._minBtn.Text = ''
                    end
                    if s._minIcon then
                        local _ic = s._minIcon::ImageLabel
                        local _fo = tween.play(_ic, constants.tweenFocus, {ImageTransparency = 1})

                        _fo.Completed:Once(function()
                            _fo:Destroy()

                            _ic.Image = ICON_MINIMIZE

                            tween.fire(_ic, constants.tweenFocus, {ImageTransparency = 0})
                        end)
                    end
                else
                    s._minimized = true

                    if s._settingsPanel and s._settingsPanel.Visible then
                        s._settingsPanel.Visible = false
                        variables.settingsOpen = false
                        variables.settingsPanelInstance = nil
                    end

                    local topY = posY - math.floor(fullH * scale / 2)
                    local targetCY = topY + math.floor(titlebarH * scale / 2)

                    if keepOnScreen then
                        local halfTH = math.floor(titlebarH * scale / 2)

                        targetCY = math.clamp(targetCY, halfTH + margin, math.max(halfTH + margin, screen.Y - halfTH - margin))
                    end

                    body.Visible = false

                    if divider then
                        divider.Visible = false
                    end
                    if s._titleSep then
                        (s._titleSep::Frame).Visible = false
                    end
                    if s._footerBar then
                        (s._footerBar::Frame).Visible = false
                    end
                    if s._titleBarBg then
                        s._titleBarBg.Size = UDim2.fromScale(1, 1)
                    end

                    local tw = tween.play(windowFrame, TWEEN_INFO, {
                        Size = UDim2.fromOffset(width, titlebarH),
                        Position = UDim2.fromOffset(posX, targetCY),
                    })

                    s._activeTween = tw

                    tw.Completed:Once(function()
                        tw:Destroy()

                        if s._activeTween == tw then
                            s._activeTween = nil
                        end
                    end)

                    if s._minBtn then
                        s._minBtn.Text = ''
                    end
                    if s._minIcon then
                        local _ic = s._minIcon::ImageLabel
                        local _fo = tween.play(_ic, constants.tweenFocus, {ImageTransparency = 1})

                        _fo.Completed:Once(function()
                            _fo:Destroy()

                            _ic.Image = ICON_RESTORE

                            tween.fire(_ic, constants.tweenFocus, {ImageTransparency = 0})
                        end)
                    end
                end
            end
            function Window:ChangeTheme(newTheme: string | {[string]: any})
                local s = (self::any)
                local resolved = themeUtil.resolve(newTheme)
                local live: {[string]: any} = s._theme or resolved
                local KEEP = {
                    'ElementTransparency',
                    'ElementStrokeTransparency',
                    'WindowTransparency',
                    'FieldTransparency',
                }
                local snapshot: {[string]: any} = {}

                for _, k in KEEP do
                    snapshot[k] = live[k]
                end
                for k, v in resolved do
                    live[k] = v
                end
                for _, k in KEEP do
                    if snapshot[k] ~= nil then
                        live[k] = snapshot[k]
                    else
                        live[k] = nil
                    end
                end

                s._theme = live
                variables.activeTheme = live

                local wf = s._windowFrame::Frame?

                if wf then
                    if s._winGradient and resolved.WindowColor then
                        s._winGradient.Color = resolved.WindowColor
                    end
                    if s._winStroke and resolved.SurfaceStroke then
                        s._winStroke.Color = resolved.SurfaceStroke
                    end
                    if s._titleBarBg and resolved.TitleBarColor then
                        s._titleBarBg.BackgroundColor3 = resolved.TitleBarColor
                    end
                    if s._sidebarFrame and resolved.TitleBarColor then
                        s._sidebarFrame.BackgroundColor3 = resolved.TitleBarColor
                    end
                    if s._sidebarBg and resolved.TitleBarColor then
                        s._sidebarBg.BackgroundColor3 = resolved.TitleBarColor
                    end
                    if resolved.CornerRoundness then
                        if s._winCorner then
                            s._winCorner.CornerRadius = resolved.CornerRoundness
                        end
                        if s._titleBarCorner then
                            s._titleBarCorner.CornerRadius = resolved.CornerRoundness
                        end
                        if s._sidebarCorner then
                            s._sidebarCorner.CornerRadius = resolved.CornerRoundness
                        end
                    end
                    if s._divider and resolved.SurfaceStroke then
                        s._divider.BackgroundColor3 = resolved.SurfaceStroke
                    end
                    if s._titleSep and resolved.SurfaceStroke then
                        s._titleSep.BackgroundColor3 = resolved.SurfaceStroke
                    end
                    if s._nameLabel and resolved.ContentColor then
                        s._nameLabel.TextColor3 = resolved.ContentColor
                    end
                    if s._subtitleLabel and resolved.PlaceholderColor then
                        s._subtitleLabel.TextColor3 = resolved.PlaceholderColor
                    end
                    if s._logoMark and resolved.AccentColor then
                        s._logoMark.BackgroundColor3 = resolved.AccentColor
                    end
                    if s._accentStrip and resolved.AccentColor then
                        s._accentStrip.BackgroundColor3 = resolved.AccentColor
                    end
                end
                if resolved.AccentColor and s._updateAccent then
                    s._updateAccent(resolved.AccentColor, true)
                end
                if s._spColorPicker and resolved.AccentColor then
                    s._spColorPicker:Set(resolved.AccentColor, nil, true)
                end

                themeUtil.broadcast(live)

                if not s._visible or not s._settingsPanel or not s._settingsPanel.Visible then
                    self:_refreshElementThemes()
                end
            end
            function Window:Unload()
                if self.unloaded then
                    return
                end

                self.unloaded = true

                local s = (self::any)

                if themeUtil.current() == s._theme then
                    themeUtil.setCurrent(themeUtil.resolve(nil))
                end
                if s._themeUnsub then
                    s._themeUnsub()
                end
                if s._activeTween then
                    pcall(function()
                        s._activeTween:Cancel()
                    end)
                end
                if s._activeAnimConn then
                    pcall(function()
                        s._activeAnimConn:Disconnect()
                    end)
                end
                if s._cameraConn then
                    pcall(function()
                        s._cameraConn:Disconnect()
                    end)
                end
                if s._gestureCleanup then
                    pcall(s._gestureCleanup)
                end
                if s._playerCard then
                    pcall(function()
                        s._playerCard:Destroy()
                    end)
                end
                if s._spColorPicker then
                    pcall(function()
                        s._spColorPicker:Destroy()
                    end)
                end
                if s._spKeybind then
                    pcall(function()
                        s._spKeybind:Destroy()
                    end)
                end
                if s._spFontDropdown then
                    pcall(function()
                        s._spFontDropdown:Destroy()
                    end)
                end
                if s._closeConfirmPopup then
                    pcall(function()
                        s._closeConfirmPopup:Destroy()
                    end)
                end

                for _, sec in (s._spSections or {})do
                    pcall(function()
                        sec:Destroy()
                    end)
                end
                for _, sl in (s._spSliders or {})do
                    pcall(function()
                        sl:Destroy()
                    end)
                end
                for _, div in (s._tabDividers or {})do
                    pcall(function()
                        div:Destroy()
                    end)
                end
                for _, tab in (s._tabs or {})do
                    local tabAny = tab::any

                    if tabAny._activeDragMoveConn then
                        pcall(function()
                            tabAny._activeDragMoveConn:Disconnect()
                        end)
                    end
                    if tabAny._activeDragEndConn then
                        pcall(function()
                            tabAny._activeDragEndConn:Disconnect()
                        end)
                    end

                    pcall(function()
                        tab:Destroy()
                    end)
                end
                for _, conn in (s._connections or {})do
                    pcall(function()
                        conn:Disconnect()
                    end)
                end
                for _, inst in (s._instances or {})do
                    pcall(function()
                        inst:Destroy()
                    end)
                end

                hapticEngine.releaseContainer(self._gui)
                hapticEngine.teardown()
                pcall(function()
                    self._gui:Destroy()
                end)
                pcall(function()
                    variables.contextActionService:UnbindAction('Delirium_WindowDragSink')
                end)
                table.clear(s._connections or {})
                table.clear(s._instances or {})
                table.clear(s.controls or {})
                table.clear(s.themeProperties or {})

                s.controls = nil
                s.themeProperties = nil
                s._loading = nil
                s._loadedConfig = nil
                s._loadedConfigPath = nil
                s._themeUnsub = nil
                s._gestureCleanup = nil
                s._activeTween = nil
                s._activeAnimConn = nil
                s._cameraConn = nil
                s._playerCard = nil
                s._spColorPicker = nil
                s._spKeybind = nil
                s._spFontDropdown = nil
                s._closeConfirmPopup = nil
                s._spSections = nil
                s._spSliders = nil
                s._tabDividers = nil
                s._tabs = nil
                s._connections = nil
                s._instances = nil
            end

            return Window
        end)()
    end,
}
local ObjectTree = {
    {
        1,
        2,
        {
            'Delirium',
        },
        {
            {
                33,
                1,
                {
                    'utility',
                },
                {
                    {
                        49,
                        2,
                        {
                            'layouts',
                        },
                    },
                    {
                        53,
                        2,
                        {
                            'mediaService',
                        },
                    },
                    {
                        60,
                        2,
                        {
                            'saveManager',
                        },
                    },
                    {
                        46,
                        2,
                        {
                            'icons',
                        },
                    },
                    {
                        45,
                        2,
                        {
                            'functions',
                        },
                    },
                    {
                        55,
                        2,
                        {
                            'network',
                        },
                    },
                    {
                        61,
                        2,
                        {
                            'services',
                        },
                    },
                    {
                        38,
                        2,
                        {
                            'element',
                        },
                    },
                    {
                        40,
                        2,
                        {
                            'executor',
                        },
                    },
                    {
                        52,
                        2,
                        {
                            'log',
                        },
                    },
                    {
                        35,
                        2,
                        {
                            'assetFetcher',
                        },
                    },
                    {
                        42,
                        2,
                        {
                            'filesystemManager',
                        },
                    },
                    {
                        37,
                        2,
                        {
                            'constants',
                        },
                    },
                    {
                        41,
                        2,
                        {
                            'filesystem',
                        },
                    },
                    {
                        56,
                        2,
                        {
                            'odometer',
                        },
                    },
                    {
                        51,
                        2,
                        {
                            'lockable',
                        },
                    },
                    {
                        68,
                        2,
                        {
                            'windowSizing',
                        },
                    },
                    {
                        43,
                        2,
                        {
                            'flags',
                        },
                    },
                    {
                        67,
                        2,
                        {
                            'variables',
                        },
                    },
                    {
                        66,
                        2,
                        {
                            'tween',
                        },
                    },
                    {
                        39,
                        2,
                        {
                            'enums',
                        },
                    },
                    {
                        57,
                        2,
                        {
                            'ordering',
                        },
                    },
                    {
                        58,
                        2,
                        {
                            'path',
                        },
                    },
                    {
                        50,
                        2,
                        {
                            'locale',
                        },
                    },
                    {
                        64,
                        2,
                        {
                            'textMetrics',
                        },
                    },
                    {
                        59,
                        2,
                        {
                            'runtime',
                        },
                    },
                    {
                        54,
                        2,
                        {
                            'moveable',
                        },
                    },
                    {
                        47,
                        2,
                        {
                            'image',
                        },
                    },
                    {
                        36,
                        2,
                        {
                            'colors',
                        },
                    },
                    {
                        48,
                        2,
                        {
                            'imageCache',
                        },
                    },
                    {
                        63,
                        2,
                        {
                            'tasks',
                        },
                    },
                    {
                        65,
                        2,
                        {
                            'theme',
                        },
                    },
                    {
                        34,
                        2,
                        {
                            'HapticEngine',
                        },
                    },
                    {
                        62,
                        2,
                        {
                            'signal',
                        },
                    },
                    {
                        44,
                        2,
                        {
                            'fontLoader',
                        },
                    },
                },
            },
            {
                32,
                2,
                {
                    'types',
                },
            },
            {
                28,
                1,
                {
                    'themes',
                },
                {
                    {
                        31,
                        2,
                        {
                            'light',
                        },
                    },
                    {
                        29,
                        2,
                        {
                            'default',
                        },
                    },
                    {
                        30,
                        2,
                        {
                            'dracula',
                        },
                    },
                },
            },
            {
                2,
                1,
                {
                    'components',
                },
                {
                    {
                        4,
                        2,
                        {
                            'colorpicker',
                        },
                    },
                    {
                        22,
                        2,
                        {
                            'tab',
                        },
                    },
                    {
                        24,
                        2,
                        {
                            'text',
                        },
                    },
                    {
                        27,
                        2,
                        {
                            'window',
                        },
                    },
                    {
                        3,
                        2,
                        {
                            'button',
                        },
                    },
                    {
                        20,
                        2,
                        {
                            'slider',
                        },
                    },
                    {
                        17,
                        2,
                        {
                            'popup',
                        },
                    },
                    {
                        19,
                        2,
                        {
                            'section',
                        },
                    },
                    {
                        8,
                        2,
                        {
                            'divider',
                        },
                    },
                    {
                        12,
                        2,
                        {
                            'keySystem',
                        },
                    },
                    {
                        11,
                        2,
                        {
                            'input',
                        },
                    },
                    {
                        10,
                        2,
                        {
                            'group',
                        },
                    },
                    {
                        23,
                        2,
                        {
                            'tag',
                        },
                    },
                    {
                        13,
                        2,
                        {
                            'keybind',
                        },
                    },
                    {
                        7,
                        2,
                        {
                            'descriptor',
                        },
                    },
                    {
                        26,
                        2,
                        {
                            'toggle',
                        },
                    },
                    {
                        5,
                        2,
                        {
                            'console',
                        },
                    },
                    {
                        21,
                        2,
                        {
                            'stat',
                        },
                    },
                    {
                        25,
                        2,
                        {
                            'toast',
                        },
                    },
                    {
                        6,
                        2,
                        {
                            'dashboard',
                        },
                    },
                    {
                        18,
                        2,
                        {
                            'progress',
                        },
                    },
                    {
                        9,
                        2,
                        {
                            'dropdown',
                        },
                    },
                    {
                        15,
                        2,
                        {
                            'loadingScreen',
                        },
                    },
                    {
                        16,
                        2,
                        {
                            'notification',
                        },
                    },
                    {
                        14,
                        2,
                        {
                            'label',
                        },
                    },
                },
            },
        },
    },
}
local LineOffsets = nil
local WaxVersion = '0.4.1'
local EnvName = 'WaxRuntime'
local string, task, setmetatable, error, next, table, unpack, coroutine, script, type, require, pcall, tostring, tonumber, _VERSION = string, task, setmetatable, error, next, table, unpack, coroutine, script, type, require, pcall, tostring, tonumber, _VERSION
local table_insert = table.insert
local table_remove = table.remove
local table_freeze = table.freeze or function(t)
    return t
end
local coroutine_wrap = coroutine.wrap
local string_sub = string.sub
local string_match = string.match
local string_gmatch = string.gmatch

if _VERSION and string_sub(_VERSION, 1, 4) == 'Lune' then
    local RequireSuccess, LuneTaskLib = pcall(require, '@lune/task')

    if RequireSuccess and LuneTaskLib then
        task = LuneTaskLib
    end
end

local task_defer = task and task.defer
local Defer = task_defer or function(f, ...)
    coroutine_wrap(f)(...)
end
local ClassNameIdBindings = {
    [1] = 'Folder',
    [2] = 'ModuleScript',
    [3] = 'Script',
    [4] = 'LocalScript',
    [5] = 'StringValue',
}
local RefBindings = {}
local ScriptClosures = {}
local ScriptClosureRefIds = {}
local StoredModuleValues = {}
local ScriptsToRun = {}
local SharedEnvironment = {}
local RefChildren = {}
local InstanceMethods = {
    GetFullName = {
        {},
        function(self)
            local Path = self.Name
            local ObjectPointer = self.Parent

            while ObjectPointer do
                Path = ObjectPointer.Name .. '.' .. Path
                ObjectPointer = ObjectPointer.Parent
            end

            return Path
        end,
    },
    GetChildren = {
        {},
        function(self)
            local ReturnArray = {}

            for Child in next, RefChildren[self]do
                table_insert(ReturnArray, Child)
            end

            return ReturnArray
        end,
    },
    GetDescendants = {
        {},
        function(self)
            local ReturnArray = {}

            for Child in next, RefChildren[self]do
                table_insert(ReturnArray, Child)

                for _, Descendant in next, Child:GetDescendants()do
                    table_insert(ReturnArray, Descendant)
                end
            end

            return ReturnArray
        end,
    },
    FindFirstChild = {
        {
            'string',
            'boolean?',
        },
        function(self, name, recursive)
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
        end,
    },
    FindFirstAncestor = {
        {
            'string',
        },
        function(self, name)
            local RefPointer = self.Parent

            while RefPointer do
                if RefPointer.Name == name then
                    return RefPointer
                end

                RefPointer = RefPointer.Parent
            end
        end,
    },
    WaitForChild = {
        {
            'string',
            'number?',
        },
        function(self, name)
            return self:FindFirstChild(name)
        end,
    },
}
local InstanceMethodProxies = {}

for MethodName, MethodObject in next, InstanceMethods do
    local Types = MethodObject[1]
    local Method = MethodObject[2]
    local EvaluatedTypeInfo = {}

    for ArgIndex, TypeInfo in next, Types do
        local ExpectedType, IsOptional = string_match(TypeInfo, '^([^%?]+)(%??)')

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
                error('Argument ' .. RealArg .. ' missing or nil', 3)
            end
            if ExpectedType ~= 'any' and RealArgType ~= ExpectedType and not (RealArgType == 'nil' and IsOptional) then
                error('Argument ' .. ArgIndex .. ' expects type "' .. ExpectedType .. '", got "' .. RealArgType .. '"', 2)
            end
        end

        return Method(self, ...)
    end
end

local function CreateRef(className, name, parent)
    local StringValue_Value
    local Children = setmetatable({}, {
        __mode = 'k',
    })

    local function InvalidMember(member)
        error(member .. ' is not a valid (virtual) member of ' .. className .. ' "' .. name .. '"', 3)
    end
    local function ReadOnlyProperty(property)
        error('Unable to assign (virtual) property ' .. property .. '. Property is read only', 3)
    end

    local Ref = {}
    local RefMetatable = {}

    RefMetatable.__metatable = false
    RefMetatable.__index = function(_, index)
        if index == 'ClassName' then
            return className
        elseif index == 'Name' then
            return name
        elseif index == 'Parent' then
            return parent
        elseif className == 'StringValue' and index == 'Value' then
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
        if index == 'ClassName' then
            ReadOnlyProperty(index)
        elseif index == 'Name' then
            name = value
        elseif index == 'Parent' then
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
        elseif className == 'StringValue' and index == 'Value' then
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

local RealObjectRoot = CreateRef('Folder', '[' .. EnvName .. ']')

for _, Object in next, ObjectTree do
    CreateRefFromObject(Object, RealObjectRoot)
end
for RefId, Closure in next, ClosureBindings do
    local Ref = RefBindings[RefId]

    ScriptClosures[Ref] = Closure
    ScriptClosureRefIds[Ref] = RefId

    local ClassName = Ref.ClassName

    if ClassName == 'LocalScript' or ClassName == 'Script' then
        table_insert(ScriptsToRun, Ref)
    end
end

local function LoadScript(scriptRef)
    local ScriptClassName = scriptRef.ClassName
    local StoredModuleValue = StoredModuleValues[scriptRef]

    if StoredModuleValue and ScriptClassName == 'ModuleScript' then
        return unpack(StoredModuleValue)
    end

    local Closure = ScriptClosures[scriptRef]

    local function FormatError(originalErrorMessage)
        originalErrorMessage = tostring(originalErrorMessage)

        local VirtualFullName = scriptRef:GetFullName()
        local OriginalErrorLine, BaseErrorMessage = string_match(originalErrorMessage, '[^:]+:(%d+): (.+)')

        if not OriginalErrorLine or not LineOffsets then
            return VirtualFullName .. ':*: ' .. (BaseErrorMessage or originalErrorMessage)
        end

        OriginalErrorLine = tonumber(OriginalErrorLine)

        local RefId = ScriptClosureRefIds[scriptRef]
        local LineOffset = LineOffsets[RefId]
        local RealErrorLine = OriginalErrorLine - LineOffset + 1

        if RealErrorLine < 0 then
            RealErrorLine = '?'
        end

        return VirtualFullName .. ':' .. RealErrorLine .. ': ' .. BaseErrorMessage
    end

    if ScriptClassName == 'LocalScript' or ScriptClassName == 'Script' then
        local RunSuccess, ErrorMessage = pcall(Closure)

        if not RunSuccess then
            error(FormatError(ErrorMessage), 0)
        end
    else
        local PCallReturn = {
            pcall(Closure),
        }
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
        local PCallReturn = {
            pcall(f, ...),
        }
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
        local ErrorNonModuleScript = 'Attempted to call require with a non-ModuleScript'
        local ErrorSelfRequire = 'Attempted to call require with self'

        if ModuleArgType == 'table' and RefChildren[module] then
            if module.ClassName ~= 'ModuleScript' then
                error(ErrorNonModuleScript, 2)
            elseif module == ScriptRef then
                error(ErrorSelfRequire, 2)
            end

            return LoadScript(module)
        elseif ModuleArgType == 'string' and string_sub(module, 1, 1) ~= '@' then
            if #module == 0 then
                error('Attempted to call require with empty string', 2)
            end

            local CurrentRefPointer = ScriptRef

            if string_sub(module, 1, 1) == '/' then
                CurrentRefPointer = RealObjectRoot
            elseif string_sub(module, 1, 2) == './' then
                module = string_sub(module, 3)
            end

            local PreviousPathMatch

            for PathMatch in string_gmatch(module, '([^/]*)/?')do
                local RealIndex = PathMatch

                if PathMatch == '..' then
                    RealIndex = 'Parent'
                end
                if RealIndex ~= '' then
                    local ResultRef = CurrentRefPointer:FindFirstChild(RealIndex)

                    if not ResultRef then
                        local CurrentRefParent = CurrentRefPointer.Parent

                        if CurrentRefParent then
                            ResultRef = CurrentRefParent:FindFirstChild(RealIndex)
                        end
                    end
                    if ResultRef then
                        CurrentRefPointer = ResultRef
                    elseif PathMatch ~= PreviousPathMatch and PathMatch ~= 'init' and PathMatch ~= 'init.server' and PathMatch ~= 'init.client' then
                        error('Virtual script path "' .. module .. '" not found', 2)
                    end
                end

                PreviousPathMatch = PathMatch
            end

            if CurrentRefPointer.ClassName ~= 'ModuleScript' then
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
