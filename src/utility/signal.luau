--!strict

-- Delirium UI Library
-- signal.luau — Lightweight typed signal / event system.
--
-- Usage:
--   local sig = Signal.new()
--   local conn = sig:Connect(function(value) print(value) end)
--   sig:Fire("hello")
--   conn:Disconnect()
--   sig:Destroy()

export type Connection = {
	Connected: boolean,
	Disconnect: (self: Connection) -> (),
}

export type Signal<T...> = {
	Connect:      (self: Signal<T...>, fn: (T...) -> ()) -> Connection,
	Once:         (self: Signal<T...>, fn: (T...) -> ()) -> Connection,
	Fire:         (self: Signal<T...>, T...) -> (),
	Wait:         (self: Signal<T...>) -> T...,
	DisconnectAll:(self: Signal<T...>) -> (),
	Destroy:      (self: Signal<T...>) -> (),
}

local Signal = {}
Signal.__index = Signal

type Entry = { fn: (...any) -> (), once: boolean }

type InternalSignal = {
	_listeners: { Entry },
	_destroyed: boolean,
}

local function makeConnection(sig: InternalSignal, entry: Entry): Connection
	local conn: { [string]: any } = {
		Connected = true,
	}

	conn.Disconnect = function(c: { [string]: any })
		if not c.Connected then return end
		c.Connected = false
		local listeners = sig._listeners
		for i = #listeners, 1, -1 do
			if listeners[i] == entry then
				table.remove(listeners, i)
				break
			end
		end
	end

	return conn :: any
end

function Signal.new<T...>(): Signal<T...>
	local self: InternalSignal = {
		_listeners = {},
		_destroyed = false,
	}
	return setmetatable(self, Signal) :: any
end

function Signal:Connect(fn: (...any) -> ()): Connection
	assert(not self._destroyed, "Signal:Connect called on a destroyed signal")
	local entry: Entry = { fn = fn, once = false }
	table.insert(self._listeners, entry)
	return makeConnection(self, entry)
end

function Signal:Once(fn: (...any) -> ()): Connection
	assert(not self._destroyed, "Signal:Once called on a destroyed signal")
	local entry: Entry = { fn = fn, once = true }
	table.insert(self._listeners, entry)
	return makeConnection(self, entry)
end

function Signal:Fire(...: any)
	if self._destroyed then return end
	-- Snapshot to handle mutations during iteration
	local snapshot = table.clone(self._listeners)
	for _, entry in snapshot do
		if entry.once then
			-- Remove from live list before calling
			for i = #self._listeners, 1, -1 do
				if self._listeners[i] == entry then
					table.remove(self._listeners, i)
					break
				end
			end
		end
		task.spawn(entry.fn, ...)
	end
end

function Signal:Wait(): ...any
	local thread = coroutine.running()
	self:Once(function(...: any)
		task.spawn(thread, ...)
	end)
	return coroutine.yield()
end

function Signal:DisconnectAll()
	table.clear(self._listeners)
end

function Signal:Destroy()
	self._destroyed = true
	table.clear(self._listeners)
end

return Signal
