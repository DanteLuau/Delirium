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

-- Resolve the best parent container for ScreenGuis.
-- Studio → PlayerGui. Exploit → gethui(). Fallback → CoreGui.
runtime.guiContainer = (function(): Instance
	if runtime.runService:IsStudio() then
		return (runtime.localPlayer :: Player).PlayerGui
	end
	if typeof(gethui) == "function" then
		local ok, container = pcall(gethui)
		if ok and container then
			return container :: Instance
		end
	end
	return runtime.coreGui
end)()

return runtime
