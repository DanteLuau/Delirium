--[[
	Delirium — Example Script
	Run as a LocalScript in StarterPlayerScripts, or paste into an executor.
	Adjust the require path if Delirium lives somewhere other than ReplicatedStorage.
--]]

local Delirium = require(game.ReplicatedStorage.Delirium)

-- ── Window ────────────────────────────────────────────────────────────────────

local win = Delirium:CreateWindow("Delirium", {
	Size = UDim2.fromOffset(480, 400),
})

-- ── Tabs ──────────────────────────────────────────────────────────────────────
-- Second arg is your rbxassetid illustration. Drop your asset IDs here.

local espTab  = win:AddTab("ESP",    "rbxassetid://0") -- replace 0 with your Auto icon ID
local aimTab  = win:AddTab("Aimbot", "rbxassetid://0") -- replace 0 with your Aura icon ID
local miscTab = win:AddTab("Misc",   "rbxassetid://0") -- replace 0 with your Skid icon ID

-- ══════════════════════════════════════════════════════════════════════════════
-- ESP
-- ══════════════════════════════════════════════════════════════════════════════

espTab:AddLabel("Player ESP")

local espEnabled = espTab:AddToggle({
	Label   = "Enable ESP",
	Default = false,
	description = "Renders tracers, boxes, and labels on all players.",
})
espEnabled.Changed:Connect(function(val)
	print("ESP enabled:", val)
end)

espTab:AddToggle({ Label = "Show Names",  Default = true })
espTab:AddToggle({ Label = "Show Health", Default = true })
espTab:AddToggle({ Label = "Show Distance", Default = false })

espTab:AddDivider("Appearance")

espTab:AddDropdown({
	Label   = "Color Mode",
	Options = {
		{ Label = "Team Color", Value = "team"   },
		{ Label = "Custom",     Value = "custom"  },
		{ Label = "Rainbow",    Value = "rainbow" },
	},
	Default = { Label = "Team Color", Value = "team" },
})

espTab:AddSlider({
	Label   = "Max Distance",
	Min     = 50,
	Max     = 1000,
	Default = 500,
	Step    = 10,
	description = "Players beyond this stud range are hidden.",
})

espTab:AddDivider("Box ESP")

espTab:AddToggle({ Label = "Enable Box", Default = false })

espTab:AddDropdown({
	Label   = "Box Style",
	Options = {
		{ Label = "2D Box",      Value = "2d"      },
		{ Label = "3D Box",      Value = "3d"      },
		{ Label = "Corner Box",  Value = "corner"  },
	},
	Placeholder = "Select style...",
})

-- ══════════════════════════════════════════════════════════════════════════════
-- Aimbot
-- ══════════════════════════════════════════════════════════════════════════════

aimTab:AddLabel("Aimbot Settings")

local aimbotEnabled = aimTab:AddToggle({
	Label   = "Enable Aimbot",
	Default = false,
})
aimbotEnabled.Changed:Connect(function(val)
	print("Aimbot enabled:", val)
end)

aimTab:AddSlider({
	Label   = "FOV",
	Min     = 10,
	Max     = 360,
	Default = 90,
	Step    = 1,
	description = "Aimbot cone radius in pixels. Lower = tighter.",
})

aimTab:AddSlider({
	Label   = "Smoothness",
	Min     = 1,
	Max     = 20,
	Default = 8,
	Step    = 1,
	description = "Higher values make aim movement look more natural.",
})

aimTab:AddDivider("Targeting")

aimTab:AddDropdown({
	Label   = "Priority",
	Options = {
		{ Label = "Nearest",    Value = "nearest"    },
		{ Label = "Lowest HP",  Value = "lowest_hp"  },
		{ Label = "Most Kills", Value = "most_kills" },
		{ Label = "Random",     Value = "random"     },
	},
	Default = { Label = "Nearest", Value = "nearest" },
})

aimTab:AddDropdown({
	Label   = "Target Part",
	Options = {
		{ Label = "Head",    Value = "Head"    },
		{ Label = "Torso",   Value = "Torso"   },
		{ Label = "Nearest", Value = "nearest" },
	},
	Default = { Label = "Head", Value = "Head" },
})

aimTab:AddToggle({
	Label   = "Prediction",
	Default = true,
	description = "Leads the target based on velocity to compensate for ping.",
})

aimTab:AddToggle({
	Label   = "Visible Only",
	Default = true,
	description = "Only locks onto targets with unobstructed line of sight.",
})

-- ══════════════════════════════════════════════════════════════════════════════
-- Misc
-- ══════════════════════════════════════════════════════════════════════════════

miscTab:AddLabel("Movement")

local flyEnabled = miscTab:AddToggle({ Label = "Fly", Default = false })
flyEnabled.Changed:Connect(function(val)
	print("Fly:", val)
end)

miscTab:AddSlider({
	Label   = "Fly Speed",
	Min     = 10,
	Max     = 200,
	Default = 50,
	Step    = 5,
})

miscTab:AddToggle({ Label = "Infinite Jump",  Default = false })
miscTab:AddToggle({ Label = "No Clip",        Default = false })
miscTab:AddToggle({ Label = "Speed Hack",     Default = false })

miscTab:AddSlider({
	Label   = "Walk Speed",
	Min     = 0,
	Max     = 100,
	Default = 16,
	Step    = 1,
})

miscTab:AddDivider("Keybinds")

local menuKey = miscTab:AddKeybind({
	Label    = "Toggle Menu",
	Default  = Enum.KeyCode.RightShift,
	Blacklist = { Enum.KeyCode.Return, Enum.KeyCode.Escape },
})
menuKey.Changed:Connect(function(kc)
	print("Menu key:", kc.Name)
end)

local espKey = miscTab:AddKeybind({
	Label   = "Toggle ESP",
	Default = Enum.KeyCode.Z,
})
espKey.Changed:Connect(function(kc)
	print("ESP key:", kc.Name)
end)

local aimKey = miscTab:AddKeybind({
	Label   = "Aimbot Hold",
	Default = Enum.KeyCode.LeftAlt,
})
aimKey.Changed:Connect(function(kc)
	print("Aimbot key:", kc.Name)
end)

miscTab:AddDivider("Actions")

local rejoinBtn = miscTab:AddButton({
	Label   = "Rejoin",
	Variant = 0,
})
rejoinBtn.Clicked:Connect(function()
	local TeleportService = game:GetService("TeleportService")
	TeleportService:Teleport(game.PlaceId, game.Players.LocalPlayer)
end)

local copyBtn = miscTab:AddButton({
	Label   = "Copy User ID",
	Variant = 1,
})
copyBtn.Clicked:Connect(function()
	local id = tostring(game.Players.LocalPlayer.UserId)
	setclipboard(id)
	print("Copied:", id)
end)
