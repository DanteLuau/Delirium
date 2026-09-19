--!strict

-- Delirium UI Library
-- flags.luau — Global flag registry.
-- Flags store the persistent state values of stateful elements (Toggle, Slider,
-- Dropdown, Input, Keybind, ColorPicker). Elements write here on change;
-- consumers can read them at any time via Delirium.Flags.
--
-- Usage:
--   Delirium.Flags["MyToggle"]       -- read current value
--   Flags:Set("MyToggle", true)      -- set from outside (fires callbacks)
--   Flags:Get("MyToggle")            -- returns current value or nil
--   Flags:GetAll()                   -- returns a shallow copy of the full table
--   Flags:Clear()                    -- wipes all flags (useful on Unload)
--   Flags:Subscribe(fn)              -- listen to every flag change; returns unsubscribe fn
--   Flags:Unsubscribe(fn)            -- remove a listener

export type FlagValue = boolean | number | string | { string } | Color3 | EnumItem
export type FlagListener = (key: string, value: FlagValue) -> ()

export type FlagsRegistry = {
	[string]: FlagValue,
	Set:         (self: FlagsRegistry, key: string, value: FlagValue) -> (),
	Get:         (self: FlagsRegistry, key: string) -> FlagValue?,
	GetAll:      (self: FlagsRegistry) -> { [string]: FlagValue },
	Clear:       (self: FlagsRegistry) -> (),
	Subscribe:   (self: FlagsRegistry, fn: FlagListener) -> () -> (),
	Unsubscribe: (self: FlagsRegistry, fn: FlagListener) -> (),
}

local store: { [string]: FlagValue } = {}
-- Map from listener function → true. Using a table as a set avoids duplicate
-- registration and makes O(1) removal via pairs() safe.
local listeners: { [any]: boolean } = {}

local flags = {} :: FlagsRegistry

-- Define methods FIRST so they sit in the raw table before the metatable is applied.
-- If setmetatable (with __newindex) came first, these assignments would be intercepted
-- and routed into `store` instead — causing infinite __index recursion at runtime.

function flags:Set(key: string, value: FlagValue)
	store[key] = value
	-- Notify all subscribers (e.g. SaveManager auto-save hook).
	for fn in pairs(listeners) do
		pcall(fn, key, value)
	end
end

function flags:Get(key: string): FlagValue?
	return store[key]
end

function flags:GetAll(): { [string]: FlagValue }
	return table.clone(store)
end

function flags:Clear()
	table.clear(store)
end

-- Register a listener that fires on every flags:Set() call.
-- Returns an unsubscribe function for convenience.
function flags:Subscribe(fn: FlagListener): () -> ()
	listeners[fn] = true
	return function()
		listeners[fn] = nil
	end
end

-- Remove a previously registered listener.
function flags:Unsubscribe(fn: FlagListener)
	listeners[fn] = nil
end

-- Apply proxy metatable AFTER methods are defined.
-- __index: method names fall through to rawget; everything else reads from store.
-- __newindex: direct assignment goes through Set() so listeners also fire.
local mt = {
	__index = function(_, key: string): FlagValue?
		local method = rawget(flags, key)
		if method ~= nil then
			return method
		end
		return store[key]
	end,
	__newindex = function(_, key: string, value: FlagValue)
		-- Route through Set so listeners are fired for direct index assignment too.
		flags:Set(key, value)
	end,
}
setmetatable(flags :: any, mt)

return flags
