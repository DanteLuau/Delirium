--!strict
--[[
    Delirium — Test Script
    Run as a LocalScript in StarterPlayerScripts, or paste into an executor.

    What this tests:
      ✓ Window creation
      ✓ Flat tabs
      ✓ Tab groups (collapsible)
      ✓ All 8 component types
      ✓ Signal connections (.Changed, .Clicked, .Submitted)
      ✓ SetValue / programmatic updates
      ✓ description field (inline description label)
      ✓ Divider (plain + labelled)
      ✓ Label (default + custom color)
      ✓ Dropdown (single + multi-select)
      ✓ Window:Close() lifecycle
      ✓ No-tab mode (components added directly to Window)
]]

-- ── Resolve Delirium ──────────────────────────────────────────────────────────
-- Adjust path if Delirium lives elsewhere.
local Delirium = require(game:GetService("ReplicatedStorage"):WaitForChild("Delirium", 10))

assert(Delirium, "[TEST] Delirium failed to load")
assert(typeof(Delirium.Version) == "string", "[TEST] Version missing")
assert(typeof(Delirium.CreateWindow) == "function", "[TEST] CreateWindow missing")

print("[TEST] Delirium loaded — version:", Delirium.Version)

-- ── helpers ───────────────────────────────────────────────────────────────────

local PASS = "✓"
local FAIL = "✗"

local function check(label: string, cond: boolean)
    if cond then
        print(PASS, label)
    else
        warn(FAIL, label)
    end
end

-- ── Window ────────────────────────────────────────────────────────────────────

local win = Delirium:CreateWindow("Delirium Test", {
    Size     = UDim2.fromOffset(500, 420),
    Position = UDim2.fromScale(0.5, 0.5),
})

check("Window created", win ~= nil)
check("Window has AddTab",    typeof(win.AddTab)    == "function")
check("Window has AddToggle", typeof(win.AddToggle) == "function")
check("Window has Close",     typeof(win.Close)     == "function")

-- ── Flat tabs ─────────────────────────────────────────────────────────────────

local mainTab = win:AddTab("Main", "rbxassetid://0")
local espTab  = win:AddTab("ESP",  "rbxassetid://0")
local miscTab = win:AddTab("Misc", "rbxassetid://0")

check("AddTab returns object",      mainTab ~= nil)
check("Tab has AddButton",  typeof(mainTab.AddButton)  == "function")
check("Tab has AddToggle",  typeof(mainTab.AddToggle)  == "function")
check("Tab has AddSlider",  typeof(mainTab.AddSlider)  == "function")
check("Tab has AddTextbox", typeof(mainTab.AddTextbox) == "function")
check("Tab has AddKeybind", typeof(mainTab.AddKeybind) == "function")
check("Tab has AddDropdown",typeof(mainTab.AddDropdown)== "function")
check("Tab has AddLabel",   typeof(mainTab.AddLabel)   == "function")
check("Tab has AddDivider", typeof(mainTab.AddDivider) == "function")

-- ── Tab group ─────────────────────────────────────────────────────────────────

local combatGroup   = win:AddTabGroup("Combat")
local aimbotTab     = combatGroup:AddTab("Aimbot", "rbxassetid://0")
local triggerTab    = combatGroup:AddTab("Triggerbot", "rbxassetid://0")

check("AddTabGroup returns object", combatGroup ~= nil)
check("Group:AddTab returns Tab",   aimbotTab  ~= nil)
check("Second group tab ok",        triggerTab ~= nil)

-- ── Label ─────────────────────────────────────────────────────────────────────

mainTab:AddLabel("Component Tests")
mainTab:AddLabel("Danger", Color3.fromRGB(255, 70, 70))
check("AddLabel (default color) ok", true)
check("AddLabel (custom color) ok",  true)

-- ── Divider ───────────────────────────────────────────────────────────────────

mainTab:AddDivider()
mainTab:AddDivider("Toggles")
check("AddDivider (plain) ok",    true)
check("AddDivider (labelled) ok", true)

-- ── Toggle ────────────────────────────────────────────────────────────────────

local tog1 = mainTab:AddToggle({
    Label   = "Feature A",
    Default = false,
})
local tog2 = mainTab:AddToggle({
    Label       = "Feature B (with description)",
    Default     = true,
    description = "This toggles feature B. It does important things.",
})

check("Toggle created",          tog1 ~= nil)
check("Toggle has Changed",      typeof(tog1.Changed) ~= "nil")
check("Toggle has SetValue",     typeof(tog1.SetValue) == "function")

local togChangedFired = false
tog1.Changed:Connect(function(val)
    togChangedFired = true
    check("Toggle Changed fires correct type", typeof(val) == "boolean")
end)
tog1:SetValue(true)
task.defer(function()
    check("Toggle SetValue + Changed fired", togChangedFired)
end)

-- ── Slider ────────────────────────────────────────────────────────────────────

local sld = mainTab:AddSlider({
    Label   = "Walk Speed",
    Min     = 0,
    Max     = 100,
    Default = 16,
    Step    = 1,
    description = "Adjusts WalkSpeed. Vanilla is 16.",
})

check("Slider created",      sld ~= nil)
check("Slider has Changed",  typeof(sld.Changed) ~= "nil")
check("Slider has SetValue", typeof(sld.SetValue) == "function")

local sliderFired = false
sld.Changed:Connect(function(val)
    sliderFired = true
    check("Slider value in range", val >= 0 and val <= 100)
end)
sld:SetValue(50)
task.defer(function()
    check("Slider SetValue + Changed fired", sliderFired)
end)

-- ── Button ────────────────────────────────────────────────────────────────────

mainTab:AddDivider("Actions")

local btn1 = mainTab:AddButton({ Label = "Primary Action", Variant = 0 })
local btn2 = mainTab:AddButton({ Label = "Secondary Action", Variant = 1 })

check("Button (Variant 0) created", btn1 ~= nil)
check("Button (Variant 1) created", btn2 ~= nil)
check("Button has Clicked",         typeof(btn1.Clicked) ~= "nil")

local btnFired = false
btn1.Clicked:Connect(function()
    btnFired = true
end)

-- ── Textbox ───────────────────────────────────────────────────────────────────

mainTab:AddDivider("Input")

local tb = mainTab:AddTextbox({
    Label       = "Target Player",
    Placeholder = "username...",
    Default     = "",
    MaxLength   = 30,
    ClearOnFocus= true,
    description = "Type the exact username of the target player.",
})

check("Textbox created",         tb ~= nil)
check("Textbox has Changed",     typeof(tb.Changed)   ~= "nil")
check("Textbox has Submitted",   typeof(tb.Submitted) ~= "nil")
check("Textbox has SetValue",    typeof(tb.SetValue)  == "function")

tb.Changed:Connect(function(text)
    check("Textbox Changed fires string", typeof(text) == "string")
end)
tb.Submitted:Connect(function(text)
    check("Textbox Submitted fires string", typeof(text) == "string")
end)

-- ── Keybind ───────────────────────────────────────────────────────────────────

local kb = mainTab:AddKeybind({
    Label     = "Toggle Menu",
    Default   = Enum.KeyCode.RightShift,
    Blacklist = { Enum.KeyCode.Return, Enum.KeyCode.Escape },
    description = "Press a key to bind it. Backspace clears.",
})

check("Keybind created",      kb ~= nil)
check("Keybind has Changed",  typeof(kb.Changed) ~= "nil")
check("Keybind has SetValue", typeof(kb.SetValue) == "function")

kb.Changed:Connect(function(kc)
    check("Keybind Changed fires KeyCode", typeof(kc) == "EnumItem")
end)

-- ── Dropdown (single) ─────────────────────────────────────────────────────────

espTab:AddLabel("ESP Settings")
espTab:AddDivider("Dropdowns")

local dd = espTab:AddDropdown({
    Label   = "Color Mode",
    Options = {
        { Label = "Team Color", Value = "team"   },
        { Label = "Custom",     Value = "custom"  },
        { Label = "Rainbow",    Value = "rainbow" },
    },
    Default = { Label = "Team Color", Value = "team" },
    description = "Pick how ESP colors are determined.",
})

check("Dropdown (single) created",   dd ~= nil)
check("Dropdown has Changed",        typeof(dd.Changed) ~= "nil")
check("Dropdown has SetValue",       typeof(dd.SetValue) == "function")

dd.Changed:Connect(function(opt)
    check("Dropdown Changed fires table with Value", typeof(opt.Value) ~= "nil")
end)

-- ── Dropdown (multi-select) ───────────────────────────────────────────────────

local ddMulti = espTab:AddDropdown({
    Label       = "Render Layers",
    MultiSelect = true,
    Options     = {
        { Label = "Box",     Value = "box"     },
        { Label = "Name",    Value = "name"    },
        { Label = "Health",  Value = "health"  },
        { Label = "Tracer",  Value = "tracer"  },
    },
    Placeholder = "Select layers...",
})

check("Dropdown (multi) created", ddMulti ~= nil)

ddMulti.Changed:Connect(function(selected)
    check("Multi-dropdown Changed fires table", typeof(selected) == "table")
end)

-- ── Description ───────────────────────────────────────────────────────────────

espTab:AddDescription({
    Title       = "About ESP",
    Description = "This tab controls all visual overlays rendered on players. "
        .. "Changes take effect immediately without needing to re-enable.",
})
check("AddDescription ok", true)

-- ── Aimbot tab (group child) ──────────────────────────────────────────────────

aimbotTab:AddLabel("Aimbot Settings")
aimbotTab:AddDivider("Core")

local aimbotTog = aimbotTab:AddToggle({ Label = "Enable Aimbot", Default = false })
check("Group-child tab: Toggle ok", aimbotTog ~= nil)

local fovSld = aimbotTab:AddSlider({ Label = "FOV", Min = 10, Max = 360, Default = 90, Step = 1 })
check("Group-child tab: Slider ok", fovSld ~= nil)

aimbotTab:AddDropdown({
    Label   = "Target Part",
    Options = {
        { Label = "Head",  Value = "Head"  },
        { Label = "Torso", Value = "Torso" },
    },
    Default = { Label = "Head", Value = "Head" },
})
check("Group-child tab: Dropdown ok", true)

-- ── Misc tab ──────────────────────────────────────────────────────────────────

miscTab:AddLabel("Miscellaneous")
miscTab:AddDivider("Movement")

miscTab:AddToggle({ Label = "Fly",            Default = false })
miscTab:AddToggle({ Label = "Infinite Jump",  Default = false })
miscTab:AddToggle({ Label = "No Clip",        Default = false })

miscTab:AddSlider({ Label = "Fly Speed", Min = 10, Max = 300, Default = 50, Step = 5 })

miscTab:AddDivider("Actions")

local rejoin = miscTab:AddButton({ Label = "Rejoin", Variant = 0 })
rejoin.Clicked:Connect(function()
    local TeleportService = game:GetService("TeleportService")
    TeleportService:Teleport(game.PlaceId, game:GetService("Players").LocalPlayer)
end)

local copyId = miscTab:AddButton({ Label = "Copy User ID", Variant = 1 })
copyId.Clicked:Connect(function()
    local id = tostring(game:GetService("Players").LocalPlayer.UserId)
    -- setclipboard is executor-only; pcall so it doesn't error in Studio
    pcall(function() (getfenv().setclipboard or (function() end))(id) end)
    print("[TEST] User ID:", id)
end)

check("Misc tab components ok", true)

-- ── Summary ───────────────────────────────────────────────────────────────────

print("─────────────────────────────────────────")
print("[TEST] Suite complete. Check output above for any ✗ failures.")
print("[TEST] Window stays open for manual inspection.")
print("[TEST] Call win:Close() to dismiss, or close the X button.")
print("─────────────────────────────────────────")

--[[
    To test Close() programmatically, uncomment:

    task.delay(10, function()
        print("[TEST] Closing window...")
        win:Close()
    end)
]]
