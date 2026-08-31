--!strict

type Handler = (...any) -> ()

type ConnectionImpl = {
	Connected: boolean,
	Disconnect: (self: ConnectionImpl) -> (),
	_signal: SignalImpl,
	_handler: Handler,
}

type SignalImpl = {
	_handlers: { Handler },
	Connect: (self: SignalImpl, callback: Handler) -> ConnectionImpl,
	Once: (self: SignalImpl, callback: Handler) -> ConnectionImpl,
	Fire: (self: SignalImpl, ...any) -> (),
	Destroy: (self: SignalImpl) -> (),
}

local Connection = {} :: { __index: any }
Connection.__index = Connection

local function newConnection(signal: SignalImpl, handler: Handler): ConnectionImpl
	return setmetatable({
		Connected = true,
		_signal = signal,
		_handler = handler,
	}, Connection) :: any
end

function Connection:Disconnect()
	if not self.Connected then return end
	self.Connected = false
	local handlers = self._signal._handlers
	for i = #handlers, 1, -1 do
		if handlers[i] == self._handler then
			table.remove(handlers, i)
			break
		end
	end
end

local Signal = {} :: { __index: any }
Signal.__index = Signal

local function new(): SignalImpl
	return setmetatable({ _handlers = {} }, Signal) :: any
end

function Signal:Connect(callback: Handler): ConnectionImpl
	local conn = newConnection(self, callback)
	table.insert(self._handlers, callback)
	return conn
end

function Signal:Once(callback: Handler): ConnectionImpl
	local conn: ConnectionImpl
	conn = self:Connect(function(...)
		conn:Disconnect()
		callback(...)
	end)
	return conn
end

function Signal:Fire(...: any)
	local snapshot = table.clone(self._handlers)
	for _, handler in snapshot do
		task.spawn(handler, ...)
	end
end

function Signal:Destroy()
	table.clear(self._handlers)
end

return { new = new } :: { new: () -> SignalImpl }
