--!strict

-- Delirium UI Library
-- variables.luau — Shared mutable state singleton.
-- Extends runtime with library-wide state that components and utility modules read.
-- This is the single source of truth for anything that changes at runtime
-- (active theme, current font, etc.).

local runtime  = require(script.Parent.runtime)
local constants = require(script.Parent.constants)

export type VariablesState = typeof(runtime) & {
	-- Active theme table (resolved, full copy)
	activeTheme: { [string]: any },

	-- Primary and title fonts (can be swapped by ChangeTheme)
	font:      Font,
	titleFont: Font,

	-- isTouchOnly forwarded from runtime for convenience
	isTouchOnly: boolean,
}

-- Clone the runtime fields into our mutable state table
local variables: VariablesState = table.clone(runtime) :: any

-- Default fonts — GothamSSm is the Roblox brand font used as Delirium default
-- (same asset as Rayfield). Swap here or via ChangeTheme's Font/TitleFont keys.
variables.font      = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium)
variables.titleFont = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold)

-- ── Shared mutable state ────────────────────────────────────────────────────

-- Active theme starts nil; init.luau calls theme.resolve() on CreateWindow
variables.activeTheme = {} :: { [string]: any }

-- Current UI scale relative to the desktop reference (1366×768).
-- Updated by Window:_applyWindowSize() on every viewport change.
-- Notification and other floating layers read this at creation time.
variables.uiScale = 1.0

-- True while the settings panel is open; component hover handlers check this
-- to suppress visual feedback when input is blocked by the modal overlay.
variables.settingsOpen = false

return variables
