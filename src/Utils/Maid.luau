--!strict

type MaidTask =
	RBXScriptConnection
	| (() -> ())
	| Instance
	| { Destroy: (self: any) -> () }

type MaidImpl = {
	_tasks: { MaidTask },
	GiveTask: (self: MaidImpl, task: MaidTask) -> MaidTask,
	DoCleaning: (self: MaidImpl) -> (),
	Destroy: (self: MaidImpl) -> (),
}

local Maid = {} :: { __index: any }
Maid.__index = Maid

local function new(): MaidImpl
	return setmetatable({ _tasks = {} }, Maid) :: any
end

function Maid:GiveTask(task: MaidTask): MaidTask
	assert(task ~= nil, "Maid: task cannot be nil")
	table.insert(self._tasks, task)
	return task
end

function Maid:DoCleaning()
	local tasks = self._tasks
	self._tasks = {}

	for _, task in tasks do
		local ok, err = pcall(function()
			if typeof(task) == "RBXScriptConnection" then
				task:Disconnect()
			elseif typeof(task) == "Instance" then
				task:Destroy()
			elseif type(task) == "function" then
				task()
			elseif type(task) == "table" and type(task.Destroy) == "function" then
				task:Destroy()
			end
		end)
		if not ok then
			warn("[Delirium Maid] Cleanup error:", err)
		end
	end
end

function Maid:Destroy()
	self:DoCleaning()
end

return { new = new } :: { new: () -> MaidImpl }
