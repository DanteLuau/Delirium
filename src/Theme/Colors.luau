--!strict

local Colors = {}

-- Base surfaces
Colors.Background    = Color3.fromHex("#0f0f0f")
Colors.Surface       = Color3.fromHex("#1c1c1c")
Colors.SurfaceHover  = Color3.fromHex("#252525")
Colors.SurfaceActive = Color3.fromHex("#2e2e2e")
Colors.TitleBar      = Color3.fromHex("#141414")

-- Accent (Win11 blue)
Colors.Accent        = Color3.fromHex("#4cc2ff")
Colors.AccentHover   = Color3.fromHex("#60cdff")
Colors.AccentActive  = Color3.fromHex("#0093fb")
Colors.AccentMuted   = Color3.fromHex("#1a3a52")

-- Accent gradient (3-stop: violet → blue → teal) for Variant 1 buttons
Colors.AccentGradient = ColorSequence.new({
	ColorSequenceKeypoint.new(0,   Color3.fromHex("#a78bfa")),
	ColorSequenceKeypoint.new(0.5, Color3.fromHex("#60cdff")),
	ColorSequenceKeypoint.new(1,   Color3.fromHex("#38d9b5")),
})
Colors.AccentGradientHover = ColorSequence.new({
	ColorSequenceKeypoint.new(0,   Color3.fromHex("#c4b5fd")),
	ColorSequenceKeypoint.new(0.5, Color3.fromHex("#7ce0ff")),
	ColorSequenceKeypoint.new(1,   Color3.fromHex("#5eecd5")),
})

-- Text
Colors.TextPrimary   = Color3.fromHex("#ffffff")
Colors.TextSecondary = Color3.fromHex("#9d9d9d")
Colors.TextDisabled  = Color3.fromHex("#555555")

-- Borders
Colors.Border        = Color3.fromHex("#2b2b2b")
Colors.BorderAccent  = Color3.fromHex("#4cc2ff")
Colors.BorderFocus   = Color3.fromHex("#60cdff")

-- Semantic
Colors.Success       = Color3.fromHex("#6ccb5f")
Colors.Warning       = Color3.fromHex("#fce100")
Colors.Error         = Color3.fromHex("#ff4f58")
Colors.ErrorHover    = Color3.fromHex("#ff6b74")

return Colors
