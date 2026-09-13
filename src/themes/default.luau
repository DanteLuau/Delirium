--!strict

-- Delirium UI Library — Default Dark Theme
-- Win11-style near-black palette with blue (#4cc2ff) accent.
-- Ported from oldsrc design language.

return {
	-- ── Window ───────────────────────────────────────────────────────────────
	WindowColor = ColorSequence.new({
		ColorSequenceKeypoint.new(0,      Color3.fromHex("#141414")),
		ColorSequenceKeypoint.new(0.9999, Color3.fromHex("#191919")),
		ColorSequenceKeypoint.new(1,      Color3.fromHex("#1c1c1c")),
	}),
	ShadowColor     = Color3.fromRGB(0, 0, 0),
	SurfaceStroke   = Color3.fromHex("#2b2b2b"),
	TitleBarColor   = Color3.fromHex("#111114"),
	CornerRoundness = UDim.new(0, 8),

	-- ── Tab sidebar ───────────────────────────────────────────────────────────
	TabColor      = Color3.fromHex("#9d9d9d"),
	TabBackground = ColorSequence.new(
		Color3.fromHex("#2a2a2a"),
		Color3.fromHex("#191919")
	),
	TabStroke     = ColorSequence.new(
		Color3.fromHex("#2b2b2b"),
		Color3.fromHex("#222222")
	),

	-- ── Elements ──────────────────────────────────────────────────────────────
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

	-- ── Typography ────────────────────────────────────────────────────────────
	TitleFont        = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold),
	Font             = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium),
	ContentColor     = Color3.fromHex("#ffffff"),
	TitlingColor     = Color3.fromHex("#ffffff"),
	PlaceholderColor = Color3.fromHex("#9d9d9d"),

	-- ── Accent (Win11 blue) ───────────────────────────────────────────────────
	AccentColor  = Color3.fromHex("#4cc2ff"),
	AccentStroke = Color3.fromHex("#60cdff"),
	AccentGlow   = 0.35,

	-- ── Toggle ────────────────────────────────────────────────────────────────
	ToggleTrack               = Color3.fromRGB(0, 0, 0),
	ToggleTrackTransparency   = 0.6,
	ToggleKnobOff             = Color3.fromHex("#9d9d9d"),
	ToggleKnobOffTransparency = 0.3,
	DarkToggleOverlay         = false,

	-- ── Slider ────────────────────────────────────────────────────────────────
	SliderBackground      = Color3.fromHex("#222222"),
	SliderBackgroundHover = Color3.fromHex("#2a2a2a"),
	SliderProgress        = ColorSequence.new(
		Color3.fromHex("#4cc2ff"),
		Color3.fromHex("#0093fb")
	),
	SliderHandle = Color3.fromRGB(255, 255, 255),
	SliderStroke = Color3.fromRGB(255, 255, 255),

	-- ── Dropdown ──────────────────────────────────────────────────────────────
	DropdownHighlight = Color3.fromRGB(255, 255, 255),

	-- ── Input / Keybind fields ────────────────────────────────────────────────
	FieldBackground   = Color3.fromRGB(255, 255, 255),
	FieldTransparency = 0.90,
	FieldGlow         = Color3.fromHex("#4cc2ff"),

	-- ── Pill corner (tab pills + collapsed icon) ───────────────────────────────
	PillCornerRadius = UDim.new(1, 0),

	-- ── Popup buttons ─────────────────────────────────────────────────────────
	NeutralButton       = Color3.fromHex("#252525"),
	NeutralButtonHover  = Color3.fromHex("#2e2e2e"),
	NeutralButtonStroke = Color3.fromHex("#2b2b2b"),

	-- ── Misc ──────────────────────────────────────────────────────────────────
	ErrorColor       = Color3.fromHex("#ff4f58"),
	ErrorStrokeColor = Color3.fromHex("#ff6b74"),
	ActionColor      = Color3.fromRGB(255, 255, 255),
	LiveAnimation    = false,
}
