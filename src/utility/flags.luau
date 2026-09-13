--!strict

-- Delirium UI Library
-- flags.luau — Global flag registry.
-- Flags store the persistent state values of stateful elements (Toggle, Slider,
-- Dropdown, Input, Keybind, ColorPicker). Elements write here on change;
-- consumers can read them at any time via Delirium.Flags.
--
-- Usage:
--   Delirium.Flags["MyToggle"]       -- read current value
--   Flags:Set("MyToggle", true)      -- set from outside (fires no callback)
--   Flags:Get("MyToggle")            -- returns current value or nil
--   Flags:GetAll()                   -- returns a shallow copy of the full table
--   Flags:Clear()                    -- wipes all flags (useful on Unload)

export type FlagValue = boolean | number | string | { string } | Color3 | EnumItem

export type FlagsRegistry = {
	[string]: FlagValue,
	Set:    (self: FlagsRegistry, key: string, value: FlagValue) -> (),
	Get:    (self: FlagsRegistry, key: string) -> FlagValue?,
	GetAll: (self: FlagsRegistry) -> { [string]: FlagValue },
	Clear:  (self: FlagsRegistry) -> (),
}

local store: { [string]: FlagValue } = {}

local flags = {} :: FlagsRegistry

-- Define methods FIRST so they sit in the raw table before the metatable is applied.
-- If setmetatable (with __newindex) came first, these assignments would be intercepted
-- and routed into `store` instead — causing infinite __index recursion at runtime.

function flags:Set(key: string, value: FlagValue)
	store[key] = value
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

-- Apply proxy metatable AFTER methods are defined.
-- __index: method names fall through to rawget; everything else reads from store.
-- __newindex: user flag writes (string keys) go into store, not the flags table itself.
local mt = {
	__index = function(_, key: string): FlagValue?
		local method = rawget(flags, key)
		if method ~= nil then
			return method
		end
		return store[key]
	end,
	__newindex = function(_, key: string, value: FlagValue)
		store[key] = value
	end,
}
setmetatable(flags :: any, mt)

return flags
