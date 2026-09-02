--!strict

-- Isolated requires: if one component fails to load, the error is surfaced
-- immediately with context instead of producing a cryptic "module failed" at
-- the library entry point.

local function safeRequire(loader: () -> any, name: string): any
	local ok, result = pcall(loader)
	if not ok then
		warn(string.format("[Delirium] Component '%s' failed to load: %s", name, tostring(result)))
		return nil
	end
	return result
end

local Button      = safeRequire(function() return require(script.Button)      end, "Button")
local Toggle      = safeRequire(function() return require(script.Toggle)      end, "Toggle")
local Label       = safeRequire(function() return require(script.Label)       end, "Label")
local Description = safeRequire(function() return require(script.Description) end, "Description")
local Divider     = safeRequire(function() return require(script.Divider)     end, "Divider")
local Slider      = safeRequire(function() return require(script.Slider)      end, "Slider")
local Textbox     = safeRequire(function() return require(script.Textbox)     end, "Textbox")
local Keybind     = safeRequire(function() return require(script.Keybind)     end, "Keybind")
local Dropdown    = safeRequire(function() return require(script.Dropdown)    end, "Dropdown")
local ColorPicker = safeRequire(function() return require(script.ColorPicker) end, "ColorPicker")

return {
	Button      = Button,
	Toggle      = Toggle,
	Label       = Label,
	Description = Description,
	Divider     = Divider,
	Slider      = Slider,
	Textbox     = Textbox,
	Keybind     = Keybind,
	Dropdown    = Dropdown,
	ColorPicker = ColorPicker,
}
