--!strict

local Theme = require(script.Theme)
local Core  = require(script.Core)

-- Re-export all public types
export type WindowConfig = {
	Size: UDim2?,
	Position: UDim2?,
	MinSize: Vector2?,
}

export type ButtonConfig = {
	Label: string,
	Variant: number?,
	Enabled: boolean?,
}

export type ToggleConfig = {
	Label: string,
	Default: boolean?,
	Enabled: boolean?,
}

-- ── Library object ────────────────────────────────────────────────────────────

local Delirium = {}
Delirium.__index = Delirium

-- Public sub-modules
Delirium.Theme      = Theme
Delirium.Components = Core.Components
Delirium.Version    = "0.0.1Meow"

function Delirium.new()
	return setmetatable({}, Delirium)
end

function Delirium:CreateWindow(title: string, options: WindowConfig?)
	assert(
		type(title) == "string" and #title > 0,
		"[Delirium] CreateWindow — title must be a non-empty string"
	)
	return Core.Window.new(title, options)
end

-- ── Entry point ───────────────────────────────────────────────────────────────
-- Intentionally no SafeCall wrapper here — require errors surface naturally
-- so the developer sees the real stack trace instead of a confusing nil.

return Delirium.new()
