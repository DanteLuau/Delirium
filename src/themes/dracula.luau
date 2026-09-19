--!strict

-- Delirium UI Library — Dracula Theme
-- Deep violet/indigo palette inspired by the Dracula color scheme.
-- Override only the keys that differ from Default; the resolver in theme.luau
-- merges this on top of the default table. Keep in sync with default.luau.

return {
	-- ── Window ───────────────────────────────────────────────────────────────
	WindowColor = ColorSequence.new({
		ColorSequenceKeypoint.new(0,      Color3.fromHex("#282a36")),
		ColorSequenceKeypoint.new(0.9999, Color3.fromHex("#21222c")),
		ColorSequenceKeypoint.new(1,      Color3.fromHex("#191a21")),
	}),
	ShadowColor   = Color3.fromHex("#0b0c10"),
	SurfaceStroke = Color3.fromHex("#44475a"),
	TitleBarColor = Color3.fromHex("#1e1f29"),

	-- ── Tab sidebar ───────────────────────────────────────────────────────────
	TabColor      = Color3.fromHex("#bd93f9"),
	TabBackground = ColorSequence.new(
		Color3.fromHex("#343746"),
		Color3.fromHex("#282a36")
	),
	TabStroke     = ColorSequence.new(
		Color3.fromHex("#44475a"),
		Color3.fromHex("#2f3140")
	),

	-- ── Elements ──────────────────────────────────────────────────────────────
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
	ElementStrokeHover          = Color3.fromHex("#bd93f9"),
	ElementTextHoverColor       = Color3.fromHex("#f8f8f2"),

	-- ── Typography ────────────────────────────────────────────────────────────
	ContentColor     = Color3.fromHex("#f8f8f2"),
	TitlingColor     = Color3.fromHex("#ffffff"),
	PlaceholderColor = Color3.fromHex("#8b8fa3"),

	-- ── Accent (Dracula purple) ───────────────────────────────────────────────
	AccentColor  = Color3.fromHex("#bd93f9"),
	AccentStroke = Color3.fromHex("#d7b8ff"),
	AccentGlow   = 0.4,

	-- ── Toggle ────────────────────────────────────────────────────────────────
	ToggleTrack               = Color3.fromHex("#282a36"),
	ToggleTrackTransparency   = 0.55,
	ToggleKnobOff             = Color3.fromHex("#8b8fa3"),
	ToggleKnobOffTransparency = 0.35,
	DarkToggleOverlay         = false,

	-- ── Slider ────────────────────────────────────────────────────────────────
	SliderBackground      = Color3.fromHex("#2b2d3a"),
	SliderBackgroundHover = Color3.fromHex("#343746"),
	SliderProgress        = ColorSequence.new(
		Color3.fromHex("#bd93f9"),
		Color3.fromHex("#8b5cf6")
	),
	SliderHandle = Color3.fromHex("#f8f8f2"),
	SliderStroke = Color3.fromHex("#f8f8f2"),

	-- ── Dropdown ──────────────────────────────────────────────────────────────
	DropdownHighlight = Color3.fromHex("#f8f8f2"),

	-- ── Input / Keybind fields ────────────────────────────────────────────────
	FieldBackground   = Color3.fromHex("#f8f8f2"),
	FieldTransparency = 0.90,
	FieldGlow         = Color3.fromHex("#bd93f9"),

	-- ── Pill corner (tab pills + collapsed icon) ───────────────────────────────
	PillCornerRadius = UDim.new(1, 0),

	-- ── Popup buttons ─────────────────────────────────────────────────────────
	NeutralButton       = Color3.fromHex("#343746"),
	NeutralButtonHover  = Color3.fromHex("#44475a"),
	NeutralButtonStroke = Color3.fromHex("#44475a"),

	-- ── Misc ──────────────────────────────────────────────────────────────────
	ErrorColor       = Color3.fromHex("#ff5555"),
	ErrorStrokeColor = Color3.fromHex("#ff6e67"),
	ActionColor      = Color3.fromHex("#f8f8f2"),
	LiveAnimation    = false,
}