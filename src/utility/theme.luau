--!strict

-- Delirium UI Library
-- theme.luau — Theme resolution, merging, validation, diffing, and broadcast.
--
-- ARCHITECTURE NOTE:
-- theme.apply() (pass-bindings style) is kept for backwards compat but is NOT
-- how live ChangeTheme propagation should work — it requires the caller to
-- collect every component's binding list manually, which means anything that
-- wasn't explicitly passed gets skipped.
--
-- The correct pattern is the subscriber registry:
--
--   Component constructor:
--     local unsub = theme.subscribe(function(t)
--         label.TextColor3 = t.ContentColor
--         frame.BackgroundColor3 = t.ElementStroke
--     end)
--
--   Component destructor / Destroy():
--     unsub()
--
--   Window ChangeTheme:
--     local resolved = theme.resolve(input)
--     theme.broadcast(resolved)
--
-- Every subscribed component gets the new theme simultaneously. Nothing slips.

local defaultTheme = require(script.Parent.Parent.themes.default)
local lightTheme   = require(script.Parent.Parent.themes.light)
local draculaTheme = require(script.Parent.Parent.themes.dracula)

-- ── Types ─────────────────────────────────────────────────────────────────────

export type ThemeTable      = { [string]: any }
export type ThemeInput      = string | ThemeTable
export type ThemeListener   = (resolved: ThemeTable) -> ()
export type Unsubscribe     = () -> ()

export type Binding = {
	key: string,
	set: (value: any) -> (),
}
export type BindingList = { Binding }

export type ValidationResult = {
	missing: { string },
	unknown: { string },
}

export type DiffResult = { [string]: { from: any, to: any } }

-- ── Private state ─────────────────────────────────────────────────────────────

local _registry: { [string]: ThemeTable } = {
	Default = defaultTheme,
	Light   = lightTheme,
	Dracula = draculaTheme,
}

local _lower: { [string]: string } = {}
for name in _registry do
	_lower[string.lower(name)] = name
end

-- Subscriber registry. Key = unique auto-incremented id.
local _subscribers: { [number]: ThemeListener } = {}
local _nextId = 0

-- Last broadcast theme, so late-subscribing components can pull it immediately.
local _current: ThemeTable = table.clone(defaultTheme)

-- ── Internal ──────────────────────────────────────────────────────────────────

local function _canonicalName(name: string): string?
	if _registry[name] then return name end
	return _lower[string.lower(name)]
end

-- ── Public API ────────────────────────────────────────────────────────────────

local theme = {}

--[[
	resolve(input?)

	Returns a fully populated ThemeTable (always a fresh copy).

	  nil          → clone of Default
	  string       → Default merged with named variant (case-insensitive)
	  ThemeTable   → Default merged with the partial table
]]
function theme.resolve(input: ThemeInput?): ThemeTable
	if input == nil then
		return table.clone(defaultTheme)
	end

	if typeof(input) == "string" then
		local canonical = _canonicalName(input)
		if not canonical then
			warn(string.format('[Delirium] Unknown theme "%s", falling back to Default.', input))
			return table.clone(defaultTheme)
		end
		if canonical == "Default" then
			return table.clone(defaultTheme)
		end
		-- Variant themes are partial overrides — always merge onto Default.
		return theme.merge(defaultTheme, _registry[canonical])
	end

	return theme.merge(defaultTheme, input :: ThemeTable)
end

--[[
	merge(base, override)

	Shallow-merges `override` on top of `base`. Returns a new table.
	Theme values are leaf scalars or opaque Roblox types — no deep merge needed.
]]
function theme.merge(base: ThemeTable, override: ThemeTable): ThemeTable
	local result = table.clone(base)
	for k, v in override do
		result[k] = v
	end
	return result
end

--[[
	subscribe(listener)

	Registers a callback that fires whenever theme.broadcast() is called.
	The listener is called immediately with the current theme so the component
	initialises correctly without a separate apply() call.

	Returns an Unsubscribe function — call it in the component's Destroy/cleanup.

	  local unsub = theme.subscribe(function(t)
	      frame.BackgroundColor3 = t.ElementStroke
	      label.TextColor3       = t.ContentColor
	  end)
	  -- later:
	  unsub()
]]
function theme.subscribe(listener: ThemeListener): Unsubscribe
	_nextId += 1
	local id = _nextId
	_subscribers[id] = listener

	-- Fire immediately so the component gets the current theme on creation.
	listener(_current)

	return function()
		_subscribers[id] = nil
	end
end

--[[
	broadcast(resolved)

	Pushes a resolved theme to every registered subscriber.
	Call this inside Window:ChangeTheme() after resolving the new input.

	  function Window:ChangeTheme(input: ThemeInput)
	      local resolved = theme.resolve(input)
	      theme.broadcast(resolved)
	  end
]]
function theme.broadcast(resolved: ThemeTable)
	_current = resolved
	for _, listener in _subscribers do
		local ok, err = pcall(listener, resolved)
		if not ok then
			warn("[Delirium] theme.broadcast listener error: " .. tostring(err))
		end
	end
end

--[[
	current()

	Returns the last broadcasted theme table. Read-only reference —
	do not mutate. Useful for one-shot reads without subscribing.
]]
function theme.current(): ThemeTable
	return _current
end

--[[
	apply(resolved, bindings)

	Legacy/manual apply. Kept for backwards compat.
	Prefer subscribe() + broadcast() for live theme switching.

	Warns on unknown binding keys to catch typos early.
]]
function theme.apply(resolved: ThemeTable, bindings: BindingList)
	for _, b in bindings do
		local val = resolved[b.key]
		if val ~= nil then
			b.set(val)
		else
			warn(string.format('[Delirium] theme.apply: unknown key "%s".', b.key))
		end
	end
end

--[[
	registerTheme(name, input)

	Adds a named theme to the runtime registry.
	Partial override tables and full tables both work.
	Cannot overwrite "Default".
]]
function theme.registerTheme(name: string, input: ThemeInput)
	if name == "Default" then
		warn('[Delirium] theme.registerTheme: cannot overwrite "Default".')
		return
	end

	if typeof(input) == "string" then
		local canonical = _canonicalName(input)
		if not canonical then
			warn(string.format('[Delirium] theme.registerTheme: source theme "%s" not found.', input))
			return
		end
		_registry[name] = _registry[canonical]
	else
		_registry[name] = input :: ThemeTable
	end

	_lower[string.lower(name)] = name
end

--[[
	list()
	Returns sorted array of all registered theme names.
]]
function theme.list(): { string }
	local names: { string } = {}
	for name in _registry do
		table.insert(names, name)
	end
	table.sort(names)
	return names
end

--[[
	isTheme(name)
	True when `name` resolves to a registered theme (case-insensitive).
]]
function theme.isTheme(name: string): boolean
	return _canonicalName(name) ~= nil
end

--[[
	extend(baseName, override)
	Resolve `baseName`, merge `override` on top, return result.
	Does not register — use registerTheme() to save it.
]]
function theme.extend(baseName: string, override: ThemeTable): ThemeTable
	return theme.merge(theme.resolve(baseName), override)
end

--[[
	validate(t)
	Checks `t` against Default's key set.
	Returns { missing, unknown } arrays.
]]
function theme.validate(t: ThemeTable): ValidationResult
	local missing: { string } = {}
	local unknown: { string } = {}

	for key in defaultTheme do
		if t[key] == nil then table.insert(missing, key) end
	end
	for key in t do
		if defaultTheme[key] == nil then table.insert(unknown, key) end
	end

	table.sort(missing)
	table.sort(unknown)
	return { missing = missing, unknown = unknown }
end

--[[
	diff(a, b)
	Returns keys that differ between two theme tables.
	{ [key] = { from = a[key], to = b[key] } }
]]
function theme.diff(a: ThemeTable, b: ThemeTable): DiffResult
	local result: DiffResult = {}
	local seen: { [string]: boolean } = {}

	for k in a do seen[k] = true end
	for k in b do seen[k] = true end

	for k in seen do
		if a[k] ~= b[k] then
			result[k] = { from = a[k], to = b[k] }
		end
	end

	return result
end

return theme