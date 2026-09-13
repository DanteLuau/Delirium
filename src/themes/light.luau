--!strict

-- Delirium UI Library — Light Theme
-- High-contrast light variant. Override only the keys that differ from Default;
-- the resolver in theme.luau merges this on top of the default table.
-- Keep in sync with default.luau when adding new keys.

return {
	-- ── Window ───────────────────────────────────────────────────────────────
	WindowColor = ColorSequence.new({
		ColorSequenceKeypoint.new(0,      Color3.fromRGB(245, 243, 255)),
		ColorSequenceKeypoint.new(0.9999, Color3.fromRGB(235, 232, 250)),
		ColorSequenceKeypoint.new(1,      Color3.fromRGB(225, 220, 245)),
	}),
	ShadowColor   = Color3.fromRGB(180, 170, 210),
	SurfaceStroke = Color3.fromRGB(190, 180, 220),
	TitleBarColor = Color3.fromRGB(210, 205, 240),

	-- ── Tab sidebar ───────────────────────────────────────────────────────────
	TabColor      = Color3.fromRGB(30, 20, 60),
	TabBackground = ColorSequence.new(
		Color3.fromRGB(210, 205, 240),
		Color3.fromRGB(225, 220, 248)
	),
	TabStroke     = ColorSequence.new(
		Color3.fromRGB(180, 170, 220),
		Color3.fromRGB(195, 185, 230)
	),

	-- ── Elements ──────────────────────────────────────────────────────────────
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

	-- ── Typography ────────────────────────────────────────────────────────────
	ContentColor     = Color3.fromRGB(40,  30,  70),
	TitlingColor     = Color3.fromRGB(20,  10,  50),
	PlaceholderColor = Color3.fromRGB(150, 140, 180),

	-- ── Toggle ────────────────────────────────────────────────────────────────
	ToggleTrack               = Color3.fromRGB(180, 170, 215),
	ToggleTrackTransparency   = 0.5,
	ToggleKnobOff             = Color3.fromRGB(120, 110, 165),
	ToggleKnobOffTransparency = 0,
	DarkToggleOverlay         = false,

	-- ── Slider ────────────────────────────────────────────────────────────────
	SliderBackground      = Color3.fromRGB(215, 210, 245),
	SliderBackgroundHover = Color3.fromRGB(200, 195, 235),
	SliderHandle          = Color3.fromRGB(124, 58, 237),
	SliderStroke          = Color3.fromRGB(124, 58, 237),

	-- ── Input / Keybind fields ────────────────────────────────────────────────
	FieldBackground   = Color3.fromRGB(255, 255, 255),
	FieldTransparency = 0.6,
	FieldGlow         = Color3.fromRGB(124, 58, 237),

	-- ── Popup buttons ─────────────────────────────────────────────────────────
	NeutralButton       = Color3.fromRGB(220, 215, 245),
	NeutralButtonHover  = Color3.fromRGB(205, 198, 235),
	NeutralButtonStroke = Color3.fromRGB(160, 150, 200),

	-- ── Misc ──────────────────────────────────────────────────────────────────
	ActionColor = Color3.fromRGB(30, 20, 60),
}
