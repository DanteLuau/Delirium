--!strict

-- Delirium UI Library
-- tween.luau — Convenience wrappers around TweenService.
-- All tweens in Delirium are created through here so cleanup is consistent.

local runtime   = require(script.Parent.runtime)
local constants = require(script.Parent.constants)

local tween = {}

-- Create and play a tween. Returns the Tween instance (for chaining or cancelling).
function tween.play(
	instance: Instance,
	tweenInfo: TweenInfo,
	props: { [string]: any }
): Tween
	local t = runtime.tweenService:Create(instance, tweenInfo, props)
	t:Play()
	return t
end

-- Tween a property and destroy the Tween object once it completes.
-- Use this for fire-and-forget transitions where you don't need the handle.
function tween.fire(
	instance: Instance,
	tweenInfo: TweenInfo,
	props: { [string]: any }
)
	local t = runtime.tweenService:Create(instance, tweenInfo, props)
	t:Play()
	t.Completed:Once(function(state)
		t:Destroy()
	end)
end

-- Cancel a tween if it's still running, then destroy it.
function tween.cancel(t: Tween?)
	if t then
		t:Cancel()
		t:Destroy()
	end
end

-- Tween transparency to 0 (fully visible) then back to 1 (transparent) — pulse effect.
-- Returns both tweens so they can be cancelled.
function tween.pulse(
	instance: GuiObject,
	tweenIn: TweenInfo,
	tweenOut: TweenInfo
): (Tween, Tween)
	local fadeIn = runtime.tweenService:Create(instance, tweenIn, { BackgroundTransparency = 0 })
	local fadeOut = runtime.tweenService:Create(instance, tweenOut, { BackgroundTransparency = 1 })
	fadeIn:Play()
	fadeIn.Completed:Once(function(state)
		if state == Enum.PlaybackState.Completed then
			fadeOut:Play()
		end
	end)
	return fadeIn, fadeOut
end

-- Pill resize helper (for Input and Keybind dynamic width hugging)
function tween.resizePill(
	instance: GuiObject,
	targetSize: UDim2,
	animated: boolean?
): Tween?
	if animated ~= false then
		return tween.play(instance, constants.pillResizeInfo, { Size = targetSize })
	else
		instance.Size = targetSize
		return nil
	end
end

return tween
