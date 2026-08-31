--!strict

local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local TWEEN_SCROLL = TweenInfo.new(0.45, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
local DEFAULT_STEP = 60

-- ── module-level managed registry ────────────────────────────────────────────
--
--  WHY UIS instead of frame.InputChanged:
--
--  frame.InputChanged only fires when that SPECIFIC frame is the Active recipient
--  of input. Any child GuiObject with Active=true (e.g. the optHit TextButtons
--  inside a dropdown list) becomes the topmost hit target and silently starves
--  the scroll frame's InputChanged — so the dropdown list never scrolls.
--
--  UserInputService.InputChanged fires globally for every wheel tick, letting us
--  manually check bounds and pick the right frame.
--
--  WHY the descendant check:
--
--  Both the window content scroll and the dropdown list scroll are "managed".
--  When the mouse is over the dropdown list, both frames' bounds contain the
--  cursor, so both would try to scroll. We only want the innermost (deepest)
--  frame to win. The parent scroll checks: "is any managed descendant of mine
--  also in bounds right now?" — if yes, it yields and the descendant handles it.
--  This eliminates scroll bleed with zero per-frame allocation.

type ManagedEntry = {
	frame:  ScrollingFrame,
}

local _managed: { ManagedEntry } = {}

local function isInBounds(frame: GuiObject, pos: Vector2): boolean
	local ap = frame.AbsolutePosition
	local as = frame.AbsoluteSize
	return as.Y > 0
		and pos.X >= ap.X and pos.X <= ap.X + as.X
		and pos.Y >= ap.Y and pos.Y <= ap.Y + as.Y
end

-- Returns true if `ancestor` is an ancestor of `descendant` in the instance tree.
local function isAncestorOf(ancestor: Instance, descendant: Instance): boolean
	local cur = descendant.Parent
	while cur do
		if cur == ancestor then return true end
		cur = cur.Parent
	end
	return false
end

-- Does any managed frame (other than `self`) descend from `self` AND fall under `mousePos`?
local function hasActiveDescendantScroll(self: ScrollingFrame, mousePos: Vector2): boolean
	for _, entry in _managed do
		local other = entry.frame
		if other ~= self
			and isAncestorOf(self, other)
			and isInBounds(other, mousePos)
		then
			return true
		end
	end
	return false
end

-- ── public API ────────────────────────────────────────────────────────────────

local SmoothScroll = {}

--[[
	SmoothScroll.blockRegion(frame)

	Prevents camera zoom when the mouse wheel is used over any GuiObject that is
	NOT a managed ScrollingFrame — e.g. the window CanvasGroup, the title bar.

	Sets frame.Active = true so the engine's hit-test marks this object as an
	input sink, blocking the wheel event from reaching the camera.  Has zero
	effect on UIS.InputChanged (our scroll logic), which fires globally regardless.

	Returns a cleanup function — pass to Maid:GiveTask().
]]
function SmoothScroll.blockRegion(frame: GuiObject): () -> ()
	local prev = frame.Active
	frame.Active = true
	return function()
		frame.Active = prev
	end
end

--[[
	SmoothScroll.apply(frame, step?)

	Smooth-scrolls a ScrollingFrame without camera zoom or cross-frame bleed.

	• Uses UserInputService.InputChanged (global) instead of frame.InputChanged
	  so child Active=true GuiObjects (dropdown option hit-buttons, etc.) can't
	  starve the scroll frame.

	• Keeps frame.Active = true so the camera ignores wheel events while the
	  cursor hovers over this frame.

	• Parent frames yield to descendant managed frames: when a child scroll is
	  under the cursor, only the child reacts — no double-scroll bleed.

	Returns a cleanup function — pass to Maid:GiveTask().
]]
function SmoothScroll.apply(frame: ScrollingFrame, step: number?): () -> ()
	local scrollStep = step or DEFAULT_STEP

	-- Disable native snap-scroll so we drive CanvasPosition ourselves.
	frame.ScrollingEnabled = false
	-- Active = true → camera ignores wheel; does NOT affect UIS.InputChanged.
	frame.Active = true

	local entry: ManagedEntry = { frame = frame }
	table.insert(_managed, entry)

	local targetY: number     = frame.CanvasPosition.Y
	local activeTween: Tween? = nil

	local inputConn = UserInputService.InputChanged:Connect(function(input: InputObject)
		if input.UserInputType ~= Enum.UserInputType.MouseWheel then return end

		local mousePos = UserInputService:GetMouseLocation()

		-- Bounds check: mouse must be within this frame's visible area.
		if not isInBounds(frame, mousePos) then return end

		-- Priority: yield to a managed descendant that's also under the cursor.
		-- (e.g. dropdown list scroll inside the window content scroll)
		if hasActiveDescendantScroll(frame, mousePos) then return end

		local maxY = math.max(0, frame.AbsoluteCanvasSize.Y - frame.AbsoluteSize.Y)
		if maxY <= 0 then return end

		-- Resync when idle (prevents snap on first tick after idle)
		if not activeTween or activeTween.PlaybackState ~= Enum.PlaybackState.Playing then
			targetY = frame.CanvasPosition.Y
		end

		-- input.Position.Z: +1 = scroll up, -1 = scroll down
		targetY = math.clamp(targetY - input.Position.Z * scrollStep, 0, maxY)

		if activeTween then activeTween:Cancel() end
		activeTween = TweenService:Create(frame, TWEEN_SCROLL, {
			CanvasPosition = Vector2.new(0, targetY),
		})
		activeTween:Play()
	end)

	-- Clamp targetY ceiling whenever canvas content grows or shrinks
	-- (e.g. dropdown rebuilds its option list while open)
	local sizeConn = frame:GetPropertyChangedSignal("AbsoluteCanvasSize"):Connect(function()
		local maxY = math.max(0, frame.AbsoluteCanvasSize.Y - frame.AbsoluteSize.Y)
		targetY = math.clamp(targetY, 0, maxY)
	end)

	return function()
		inputConn:Disconnect()
		sizeConn:Disconnect()
		if activeTween then
			activeTween:Cancel()
			activeTween = nil
		end
		frame.ScrollingEnabled = true
		frame.Active           = false

		-- Unregister from managed list
		local idx = table.find(_managed, entry)
		if idx then
			table.remove(_managed, idx)
		end
	end
end

return SmoothScroll
