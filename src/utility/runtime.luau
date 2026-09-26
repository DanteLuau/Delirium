--!strict

-- Delirium UI Library
-- runtime.luau — Platform detection and cached service references.
-- Singleton. All other modules consume this via variables.luau (which extends it).

local services = require(script.Parent.services)

export type RuntimeState = {
	-- true when DELIRIUM_SECURE is set in getgenv(); toggles asset proxy caching
	secureMode: boolean,

	-- Cached Roblox services (cloneref-safe)
	coreGui: CoreGui,
	workspace: Workspace,
	runService: RunService,
	userInputService: UserInputService,
	guiService: GuiService,
	tweenService: TweenService,
	httpService: HttpService,
	textService: TextService,
	contextActionService: ContextActionService,
	replicatedStorage: ReplicatedStorage,

	localPlayer: Player?,

	-- Where ScreenGuis are parented. gethui() > CoreGui fallback.
	guiContainer: Instance,
}

local runtime = {} :: RuntimeState

-- Secure mode: executor sets getgenv().DELIRIUM_SECURE = true before requiring
runtime.secureMode = (function(): boolean
	if typeof(getgenv) ~= "function" then
		return false
	end
	local ok, val = pcall(function()
		return getgenv().DELIRIUM_SECURE
	end)
	return ok and val == true
end)()

runtime.coreGui           = services.getService("CoreGui") :: CoreGui
runtime.workspace         = services.getService("Workspace") :: Workspace
runtime.runService        = services.getService("RunService") :: RunService
runtime.userInputService  = services.getService("UserInputService") :: UserInputService
runtime.guiService        = services.getService("GuiService") :: GuiService
runtime.tweenService      = services.getService("TweenService") :: TweenService
runtime.httpService       = services.getService("HttpService") :: HttpService
runtime.textService          = services.getService("TextService") :: TextService
runtime.contextActionService = services.getService("ContextActionService") :: ContextActionService
runtime.replicatedStorage    = services.getService("ReplicatedStorage") :: ReplicatedStorage
runtime.localPlayer       = (services.getService("Players") :: Players).LocalPlayer

-- M1/M5: computed once at module load so all consumers share one truth.
-- Touch-only = has touch hardware but no keyboard (phone/tablet without bluetooth kbd).
runtime.isTouchOnly = (function(): boolean
	local uis = runtime.userInputService
	if not uis.TouchEnabled then return false end
	if uis.KeyboardEnabled then return false end
	-- Fallback: very narrow viewport is a reliable phone signal.
	local cam = runtime.workspace.CurrentCamera
	if cam and cam.ViewportSize.X < 600 then return true end
	return true
end)() :: boolean

-- Resolve the best parent container for ScreenGuis.
-- Studio → PlayerGui. Exploit → gethui(). Fallback → CoreGui (tested via pcall) → PlayerGui.
runtime.guiContainer = (function(): Instance
	-- Escalate identity: module may run in a wax Defer'd thread (identity 2 by default)
	local _sti = typeof(setthreadidentity) == "function" and setthreadidentity
		or typeof(set_thread_identity) == "function" and set_thread_identity
		or nil
	if _sti then pcall(_sti, 8) end

	if runtime.runService:IsStudio() then
		local lp = runtime.localPlayer or (services.getService("Players") :: Players).LocalPlayer
		if lp then
			local pg = lp:FindFirstChildOfClass("PlayerGui") or lp:FindFirstChild("PlayerGui")
			if pg then return pg end
		end
	end
	if typeof(gethui) == "function" then
		local ok, container = pcall(gethui)
		if ok and container then
			return container :: Instance
		end
	end
	-- Verify CoreGui accessibility (avoids 'lacking capability Plugin' error)
	local coreGui = runtime.coreGui
	if coreGui then
		local ok = pcall(function()
			local test = Instance.new("Folder")
			test.Parent = coreGui
			test:Destroy()
		end)
		if ok then
			return coreGui
		end
	end
	-- Safe universal fallback for all execution contexts
	local lp = runtime.localPlayer or (services.getService("Players") :: Players).LocalPlayer
	if lp then
		local pg = lp:FindFirstChildOfClass("PlayerGui") or lp:WaitForChild("PlayerGui", 5)
		if pg then return pg end
	end
	return coreGui
end)()

return runtime
