--!strict

-- Delirium UI Library
-- network.luau — Executor HTTP request function detection.
-- Probes the executor environment for a usable request fn in priority order.
-- Every module that needs to hit the network goes through this; never call
-- syn.request or http_request raw — executors disagree on which name exists.

local network = {}

export type RequestFn = (...any) -> any

-- Returns the first callable request fn found in the given environment,
-- or nil when the executor exposes none (e.g. non-network environments).
function network.getRequestFn(env: any?): RequestFn?
	env = env or getfenv()
	return env.request
		or env.http_request
		or (env.http and env.http.request)
		or (env.syn and env.syn.request)
		or (env.fluxus and env.fluxus.request)
end

return network
