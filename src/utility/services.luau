--!strict

-- Delirium UI Library
-- services.luau — Thin wrapper around game:GetService with cloneref guard.
-- Every service in Delirium is fetched through here; never call game:GetService raw.

local services = {}

function services.getService(name: string): Instance
	local service = game:GetService(name)
	return if typeof(cloneref) == "function" then cloneref(service) else service
end

return services
