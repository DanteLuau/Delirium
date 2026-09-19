--!strict

-- Delirium UI Library
-- init.luau — Public entry point.
-- Require this module to get the Delirium API surface.
--
-- Basic usage:
--   local Delirium = require(game.ReplicatedStorage.Delirium)
--   local win = Delirium:CreateWindow({ name = "My Script" })
--   local tab = win:CreateTab({ name = "Main" })
--   tab:CreateToggle({ name = "God Mode", flag = "GodMode", callback = function(v) ... end })

local types    = require(script.types)
local flags    = require(script.utility.flags)
local variables = require(script.utility.variables)
local constants = require(script.utility.constants)
local icons     = require(script.utility.icons)
local mediaService  = require(script.utility.mediaService)
local imageCache    = require(script.utility.imageCache)
local imageUtil     = require(script.utility.image)
local saveManager   = require(script.utility.saveManager)

-- Re-export public types so consumers can annotate against Delirium.Window etc
export type Theme         = types.Theme
export type WindowProps   = types.WindowProps
export type TabProps      = types.TabProps
export type SectionProps  = types.SectionProps
export type LabelProps    = types.LabelProps
export type ButtonProps   = types.ButtonProps
export type ToggleProps   = types.ToggleProps
export type SliderProps   = types.SliderProps
export type DropdownProps = types.DropdownProps
export type InputProps    = types.InputProps
export type KeybindProps  = types.KeybindProps
export type ColorPickerProps = types.ColorPickerProps
export type NotifyProps   = types.NotifyProps

export type Window      = types.Window
export type Tab         = types.Tab
export type Section     = types.Section
export type Label       = types.Label
export type Button      = types.Button
export type Toggle      = types.Toggle
export type Slider      = types.Slider
export type Dropdown    = types.Dropdown
export type Input       = types.Input
export type Keybind     = types.Keybind
export type ColorPicker = types.ColorPicker
export type Delirium    = types.Delirium

-- Window module constructor type (untyped internally)
type WindowModule = { new: (types.WindowProps) -> types.Window }

local delirium = {} :: Delirium

-- Flags registry — accessible as Delirium.Flags["MyFlag"]
delirium.Flags = flags :: any

-- Nebula Icon Library interface — accessible as Delirium.Icons or Delirium.NebulaIcons
delirium.Icons = icons :: any
delirium.NebulaIcons = icons :: any

-- MediaService — image preloading, avatar headshots, external fonts
-- Accessible as Delirium.MediaService so executor bundles don't need a second require.
delirium.MediaService = mediaService :: any

-- SaveManager — flag persistence (Save/Load/List/Delete + Register for UI sync)
-- Accessible as Delirium.SaveManager
delirium.SaveManager = saveManager :: any

-- LoadingScreen component — exposed so executor bundles don't need a second require.
-- Usage: local loading = Delirium.LoadingScreen.new({ title = "MyCheat", accent = ... })
delirium.LoadingScreen = require(script.components.loadingScreen) :: any

-- Internal debug accessors — exposed so executor scripts can inspect internal
-- state without requiring via game.ReplicatedStorage (which doesn't exist on executor).
-- These are the same singleton instances used by the library internally.
delirium._imageCache = imageCache :: any
delirium._image      = imageUtil  :: any

function delirium:CreateWindow(props: types.WindowProps): types.Window
	local made, result = pcall(function()
		return (require(script.components.window) :: WindowModule).new(props)
	end)

	if not made then
		error("[Delirium] CreateWindow failed: " .. tostring(result), 2)
	end

	local window = result :: types.Window

	-- Show the window after a brief settle delay
	-- (gives the executor environment time to finish rendering initial frames)
	task.delay(0.4, function()
		if not window.unloaded then
			window:Show()
		end
	end)

	return window
end

return delirium
