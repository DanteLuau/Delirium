--!strict

local Theme        = require(script.Theme)
local Core         = require(script.Core)
local SaveManager  = require(script.Core.SaveManager)
local Notification = require(script.Core.Notification)
local Popup        = require(script.Core.Popup)

local Tooltip      = require(script.Utils.Tooltip)

-- ── Public types ──────────────────────────────────────────────────────────────

export type PillPosition = "Top" | "Bottom" | "Left" | "Right"

export type WindowConfig = {
	Size:         UDim2?,
	Position:     UDim2?,
	MinSize:      Vector2?,
	AutoScale:    boolean?,
	PillPosition: PillPosition?,
}

export type NotifyConfig = Notification.NotifyConfig
export type PopupConfig  = Popup.PopupConfig

-- ── Library object ────────────────────────────────────────────────────────────

local Delirium = {}
Delirium.__index = Delirium

-- Sub-modules exposed to script authors
Delirium.Theme       = Theme
Delirium.Components  = Core.Components
Delirium.SaveManager = SaveManager
Delirium.Tooltip     = Tooltip
Delirium.Flags       = SaveManager.Flags   -- live read-only flag table
Delirium.Version     = "0.0.1"

function Delirium.new()
	return setmetatable({}, Delirium)
end

-- ── Windows ───────────────────────────────────────────────────────────────────

function Delirium:CreateWindow(title: string, options: WindowConfig?)
	assert(
		type(title) == "string" and #title > 0,
		"[Delirium] CreateWindow — title must be a non-empty string"
	)
	local win        = Core.Window.new(title, options)
	self._activeWin  = win
	return win
end

-- ── Notifications ─────────────────────────────────────────────────────────────

function Delirium:Notify(config: NotifyConfig)
	Notification.notify(config)
end

-- ── Popups ───────────────────────────────────────────────────────────────────

function Delirium:Popup(config: PopupConfig)
	local win = self._activeWin
	if not win then
		warn("[Delirium] Popup — no active window. Call CreateWindow first.")
		return
	end
	Popup.show(win._canvas, config)
end

-- ── Entry point ───────────────────────────────────────────────────────────────

return Delirium.new()
