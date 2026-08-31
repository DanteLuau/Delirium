--!strict

local Colors = require(script.Colors)
local Icons = require(script.Icons)

-- Non-blocking icon init — fails gracefully if HTTP is off
task.defer(Icons.Init)

local Theme = {
	Colors = Colors,
	Icons  = Icons,

	Font = {
		Title    = Enum.Font.GothamBold,
		Subtitle = Enum.Font.GothamMedium,
		Body     = Enum.Font.Gotham,
		Mono     = Enum.Font.Code,
	},

	TextSize = {
		Title    = 14,
		Subtitle = 13,
		Body     = 13,
		Small    = 11,
	},

	Radius = {
		Small  = 4,
		Medium = 8,
		Large  = 12,
		Pill   = 100,
	},

	Spacing = {
		XS = 4,
		S  = 8,
		M  = 12,
		L  = 16,
		XL = 24,
	},

	TitleBarHeight = 40,
}

return Theme
