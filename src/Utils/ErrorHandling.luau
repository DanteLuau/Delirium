--!strict

type ErrorEntry = {
	message: string,
	trace: string,
	context: string,
	time: number,
}

type OnErrorSignal = {
	Fire: (self: any, ...any) -> (),
}

local ErrorHandler = {}
local _queue: { ErrorEntry } = {}
local _onError: OnErrorSignal? = nil

function ErrorHandler.Init(signal: OnErrorSignal)
	_onError = signal
end

function ErrorHandler.SafeCall<T>(fn: () -> T, context: string?): T?
	local ctx = context or "Unknown"

	local success, result = xpcall(fn, function(err: any)
		local trace = debug.traceback(tostring(err), 2)
		local msg = string.format("[Delirium] Error in %s:\n%s", ctx, trace)
		warn(msg)

		table.insert(_queue, {
			message = tostring(err),
			trace = trace,
			context = ctx,
			time = os.time(),
		})

		if _onError then
			pcall(function()
				_onError:Fire(msg)
			end)
		end
	end)

	if success then
		return result :: T
	end
	return nil
end

function ErrorHandler.GetQueue(): { ErrorEntry }
	return _queue
end

function ErrorHandler.ClearQueue()
	table.clear(_queue)
end

return ErrorHandler
