--!strict

-- Delirium UI Library
-- filesystem.luau — Executor FS abstraction.
-- In a live executor: wraps the raw globals (writefile, readfile, etc.)
-- In Studio: simulates the same API through a StringValue/Folder instance tree
-- under ReplicatedStorage, so modules can require() without erroring.
-- Never call writefile/readfile raw anywhere else in Delirium — use this.

local services = require(script.Parent.services)

local filesystem = {}

local runService = services.getService("RunService")
local isStudio   = runService:IsStudio()
local hasNativeFS = not isStudio and typeof(writefile) == "function"

-- ── Native executor path ─────────────────────────────────────────────────────

if hasNativeFS then

	function filesystem.writefile(path: string, content: string)
		writefile(path, content)
	end

	function filesystem.readfile(path: string): string
		return readfile(path)
	end

	function filesystem.appendfile(path: string, content: string)
		appendfile(path, content)
	end

	function filesystem.isfile(path: string): boolean
		return isfile(path)
	end

	function filesystem.delfile(path: string)
		delfile(path)
	end

	function filesystem.listfiles(folder: string): { string }
		return listfiles(folder)
	end

	function filesystem.makefolder(path: string)
		makefolder(path)
	end

	function filesystem.isfolder(path: string): boolean
		return isfolder(path)
	end

	function filesystem.delfolder(path: string)
		delfolder(path)
	end

-- ── Studio simulation path ────────────────────────────────────────────────────
-- Files → StringValues, folders → Folders, all rooted under ReplicatedStorage.
-- This is Glass — fragile and reset-safe, not a real disk. It's here so requires
-- don't throw in Studio; never rely on it for persistence.

elseif isStudio then

	local replicatedStorage = services.getService("ReplicatedStorage")
	local root = replicatedStorage:FindFirstChild("__DeliriumFS__")
	if not root then
		root = Instance.new("Folder")
		root.Name = "__DeliriumFS__"
		root.Parent = replicatedStorage
	end

	local function splitPath(path: string): { string }
		local parts: { string } = {}
		for part in string.gmatch(path, "[^/]+") do
			table.insert(parts, part)
		end
		return parts
	end

	local function resolveParent(parts: { string }, create: boolean): Instance?
		local cur: Instance = root :: Instance
		for i = 1, #parts - 1 do
			local child = cur:FindFirstChild(parts[i])
			if not child then
				if not create then return nil end
				local f = Instance.new("Folder")
				f.Name = parts[i]
				f.Parent = cur
				child = f
			end
			cur = child :: Instance
		end
		return cur
	end

	local function asFile(inst: Instance?): StringValue?
		return if inst and inst:IsA("StringValue") then inst :: StringValue else nil
	end

	function filesystem.writefile(path: string, content: string)
		local parts = splitPath(path)
		assert(#parts > 0, "filesystem.writefile: invalid path")
		local parent = resolveParent(parts, true)
		assert(parent, "filesystem.writefile: could not resolve parent")
		local name = parts[#parts]
		local existing = parent:FindFirstChild(name)
		local file = asFile(existing)
		if file then
			file.Value = content
		else
			if existing then existing:Destroy() end
			local sv = Instance.new("StringValue")
			sv.Name  = name
			sv.Value = content
			sv.Parent = parent
		end
	end

	function filesystem.readfile(path: string): string
		local parts = splitPath(path)
		local parent = resolveParent(parts, false)
		assert(parent, "filesystem.readfile: file not found — " .. path)
		local file = asFile(parent:FindFirstChild(parts[#parts]))
		assert(file, "filesystem.readfile: file not found — " .. path)
		return file.Value
	end

	function filesystem.appendfile(path: string, content: string)
		local parts = splitPath(path)
		local parent = resolveParent(parts, false)
		assert(parent, "filesystem.appendfile: file not found — " .. path)
		local file = asFile(parent:FindFirstChild(parts[#parts]))
		assert(file, "filesystem.appendfile: file not found — " .. path)
		file.Value = file.Value .. content
	end

	function filesystem.isfile(path: string): boolean
		local parts = splitPath(path)
		if #parts == 0 then return false end
		local parent = resolveParent(parts, false)
		if not parent then return false end
		return asFile(parent:FindFirstChild(parts[#parts])) ~= nil
	end

	function filesystem.delfile(path: string)
		local parts = splitPath(path)
		local parent = resolveParent(parts, false)
		assert(parent, "filesystem.delfile: file not found — " .. path)
		local file = asFile(parent:FindFirstChild(parts[#parts]))
		assert(file, "filesystem.delfile: file not found — " .. path)
		file:Destroy()
	end

	function filesystem.listfiles(folder: string): { string }
		local parts = splitPath(folder)
		local cur: Instance = root :: Instance
		for _, part in parts do
			local child = cur:FindFirstChild(part)
			assert(child and child:IsA("Folder"), "filesystem.listfiles: folder not found — " .. folder)
			cur = child
		end
		local results: { string } = {}
		for _, child in cur:GetChildren() do
			table.insert(results, folder .. "/" .. child.Name)
		end
		return results
	end

	function filesystem.makefolder(path: string)
		local parts = splitPath(path)
		local cur: Instance = root :: Instance
		for _, part in parts do
			local child = cur:FindFirstChild(part)
			if not child then
				local f = Instance.new("Folder")
				f.Name   = part
				f.Parent = cur
				child    = f
			end
			cur = child :: Instance
		end
	end

	function filesystem.isfolder(path: string): boolean
		local parts = splitPath(path)
		local cur: Instance = root :: Instance
		for _, part in parts do
			local child = cur:FindFirstChild(part)
			if not child or not child:IsA("Folder") then return false end
			cur = child
		end
		return true
	end

	function filesystem.delfolder(path: string)
		local parts = splitPath(path)
		local parent = resolveParent(parts, false)
		assert(parent, "filesystem.delfolder: folder not found — " .. path)
		local folder = parent:FindFirstChild(parts[#parts])
		assert(folder and folder:IsA("Folder"), "filesystem.delfolder: folder not found — " .. path)
		folder:Destroy()
	end

end

-- ── Helpers ───────────────────────────────────────────────────────────────────

-- Creates the folder only when it doesn't exist yet.
function filesystem.ensureFolder(path: string)
	if not filesystem.isfolder(path) then
		filesystem.makefolder(path)
	end
end

-- Creates every segment of a multi-level path in one shot.
-- e.g. "Delirium/Assets/Fonts" → creates Delirium, then Assets, then Fonts.
function filesystem.ensureDir(dir: string)
	local built = ""
	for part in string.gmatch(dir, "[^/]+") do
		built = if built == "" then part else built .. "/" .. part
		if not filesystem.isfolder(built) then
			filesystem.makefolder(built)
		end
	end
end

return filesystem
