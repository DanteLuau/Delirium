--!strict

-- Delirium UI Library
-- constants.luau — Immutable visual and structural constants.
-- Theme-varying values (colors, fonts) live in themes/; put everything else here.

local constants = {}

-- ── Tween presets ────────────────────────────────────────────────────────────

-- General UI element transitions (hover in/out, show/hide)
constants.tweenFast   = TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
constants.tweenNormal = TweenInfo.new(0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
constants.tweenSlow   = TweenInfo.new(0.45, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)

-- Pill-shaped input/keybind width tween (matches the animated resize feel)
constants.pillResizeInfo = TweenInfo.new(0.35, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
constants.tweenFocus     = TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

-- Notification slide-in / slide-out
constants.notifySlideIn  = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
constants.notifySlideOut = TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.In)

-- ── ZIndex layers (assumes Global ZIndexBehavior) ─────────────────────────────

constants.zIndex = {
	base             = 1,
	element          = 10,
	dropdown         = 50,     -- Dropdown overlay sits above elements
	notification     = 200,    -- Corner notification cards
	windowChrome     = 500,    -- Window title bar / buttons
	drag             = 1000,   -- Drag ghost layer
	popup            = 2000,   -- Modal popups dim + content
}

-- ── DisplayOrder for top-level ScreenGuis ────────────────────────────────────

constants.displayOrder = {
	window      = 99990,
	notification = 99995,
	popup       = 100000,
}

-- ── Layout ───────────────────────────────────────────────────────────────────

-- Default window dimensions
constants.windowSize       = Vector2.new(720, 580)
constants.windowMinSize    = Vector2.new(560, 440)
constants.sidebarWidth     = 164   -- Tab sidebar width in pixels
constants.elementHeight    = 38    -- Standard element row height
constants.elementPadding   = 6     -- Gap between stacked elements
constants.sectionPadding   = 14    -- Gap before/after section dividers
constants.contentPadding   = 10    -- Left/right inset inside the content pane

-- ── Misc ─────────────────────────────────────────────────────────────────────

-- Notification auto-dismiss default duration (seconds)
constants.notifyDuration = 4

-- Slider/Dropdown click sound (optional; Delirium plays nothing by default)
constants.clickSoundId = ""

return constants
