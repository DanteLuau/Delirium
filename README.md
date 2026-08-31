# Delirium

A clean, dark-themed Roblox UI library for cheat menus and developer tools.  
Tabbed sidebar layout · Smooth animations · Full component suite.

**Version:** `0.0.1Meow`

---

## Installation

### Loadstring (executor users)
```lua
local Delirium = loadstring(game:HttpGet("https://raw.githubusercontent.com/YOUR_USERNAME/Delirium-Reworked/main/delirium.bundle.lua"))()
```

### Rojo / model file (developers)
Download `delirium.rbxm` and drag it into **ReplicatedStorage** in Studio.  
Then require it:
```lua
local Delirium = require(game.ReplicatedStorage.Delirium)
```

### Build from source
```bash
# Install toolchain
aftman install

# Rebuild the .rbxm from src/
rojo build bundle.project.json --output delirium.rbxm

# Bundle to single Lua file
lune run wax bundle input=delirium.rbxm output=delirium.bundle.lua
```

---

## Quick Start

```lua
local Delirium = require(game.ReplicatedStorage.Delirium)

local win = Delirium:CreateWindow("My Menu", {
    Size = UDim2.fromOffset(480, 400),
})

local tab = win:AddTab("Main", "rbxassetid://0")

tab:AddLabel("Hello World")

local toggle = tab:AddToggle({ Label = "Enable", Default = false })
toggle.Changed:Connect(function(val)
    print("Toggle:", val)
end)
```

---

## API

### `Delirium:CreateWindow(title, options?)`
Creates and opens a window. Returns a `Window`.

| Option | Type | Default |
|---|---|---|
| `Size` | `UDim2` | `500×340` |
| `Position` | `UDim2` | `0.5, 0.5 (centered)` |
| `MinSize` | `Vector2` | `300×200` |

---

### Window

| Method | Description |
|---|---|
| `win:AddTab(name, icon?)` | Flat tab in sidebar. Returns `Tab`. |
| `win:AddTabGroup(name, icon?)` | Collapsible group. Returns `GroupProxy`. |
| `win:AddButton(config)` | Button directly on window (no-tab mode). |
| `win:AddToggle(config)` | Toggle directly on window. |
| `win:AddLabel(text, color?)` | Label directly on window. |
| `win:AddDivider(text?)` | Divider directly on window. |
| `win:AddSlider(config)` | Slider directly on window. |
| `win:AddTextbox(config)` | Textbox directly on window. |
| `win:AddKeybind(config)` | Keybind directly on window. |
| `win:AddDropdown(config)` | Dropdown directly on window. |
| `win:Close()` | Animates close and destroys. |
| `win:Destroy()` | Immediate destroy. |

---

### Tab / GroupProxy

```lua
local tab = win:AddTab("ESP")

-- or inside a group:
local group = win:AddTabGroup("Combat")
local tab   = group:AddTab("Aimbot")
```

Tab methods mirror Window component methods — same signatures:

| Method | Returns |
|---|---|
| `tab:AddButton(config)` | `Button` — `.Clicked` signal |
| `tab:AddToggle(config)` | `Toggle` — `.Changed` signal |
| `tab:AddLabel(text, color?)` | `Label` |
| `tab:AddDivider(text?)` | `Divider` |
| `tab:AddSlider(config)` | `Slider` — `.Changed` signal |
| `tab:AddTextbox(config)` | `Textbox` — `.Changed`, `.Submitted` signals |
| `tab:AddKeybind(config)` | `Keybind` — `.Changed` signal |
| `tab:AddDropdown(config)` | `Dropdown` — `.Changed` signal |
| `tab:AddDescription(config)` | `Description` |

---

### Components

#### Button
```lua
local btn = tab:AddButton({ Label = "Rejoin", Variant = 0 })
btn.Clicked:Connect(function() end)
```
`Variant`: `0` = default · `1` = secondary

#### Toggle
```lua
local tog = tab:AddToggle({ Label = "Fly", Default = false })
tog.Changed:Connect(function(value: boolean) end)
tog:SetValue(true)
```

#### Slider
```lua
local sld = tab:AddSlider({ Label = "Speed", Min = 0, Max = 100, Default = 16, Step = 1 })
sld.Changed:Connect(function(value: number) end)
sld:SetValue(50)
```

#### Textbox
```lua
local tb = tab:AddTextbox({ Label = "Player", Placeholder = "name..." })
tb.Changed:Connect(function(text: string) end)
tb.Submitted:Connect(function(text: string) end)
```

#### Keybind
```lua
local kb = tab:AddKeybind({ Label = "Toggle Menu", Default = Enum.KeyCode.RightShift })
kb.Changed:Connect(function(keyCode: Enum.KeyCode) end)
```

#### Dropdown
```lua
local dd = tab:AddDropdown({
    Label   = "Team",
    Options = { { Label = "Red", Value = "red" }, { Label = "Blue", Value = "blue" } },
    Default = { Label = "Red", Value = "red" },
})
dd.Changed:Connect(function(option) print(option.Value) end)
```

#### Divider
```lua
tab:AddDivider("Section Name")  -- or tab:AddDivider() for a plain line
```

#### Label
```lua
tab:AddLabel("Some text")
tab:AddLabel("Warning", Color3.fromRGB(255, 80, 80))
```

#### Description
```lua
tab:AddDescription({ Title = "Note", Description = "This does a thing." })
```

---

## Theme

```lua
local Theme = Delirium.Theme  -- Colors, Spacing, Font, etc.
print(Theme.Colors.Accent)
```

---

## License

MIT — do whatever you want with it.
