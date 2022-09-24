local IXSandboxThread = require((script and script.Thread) or "ThreadPool/Thread.lua")
local IXSandboxThreadPool = { Name = "IX-Sandbox-Thread" }
IXSandboxThreadPool.Prototype = { }

return function(Namespace)
	IXSandboxThread = IXSandboxThread(Namespace)

	function IXSandboxThreadPool.Prototype:updateThreadStates()
		for _, threadObject in self.Pool do
			threadObject:updateThreadState()
		end
	end

	function IXSandboxThreadPool.Prototype:toThreadList(reeverseList)
		local threadList = { }

		for _, threadObject in self.Pool do
			table.insert(threadList, threadObject)
		end

		table.sort(threadList, function(threadX, threadY)
			if reeverseList then
				return threadX.Clock > threadY.Clock
			end

			return threadX.Clock < threadY.Clock
		end)

		return threadList
	end

	function IXSandboxThreadPool.Prototype:queryThread(threadObject)
		local threadUniqueId = IXSandboxThread.getThreadName(threadObject)

		return self.Pool[threadUniqueId]
	end

	function IXSandboxThreadPool.Prototype:addToThreadPool(threadObject)
		self.Pool[threadObject.UniqueId] = threadObject
	end

	function IXSandboxThreadPool.Prototype:removeFromThreadPool(threadObject)
		local threadUniqueId = IXSandboxThread.getThreadName(threadObject)

		if self.Pool[threadUniqueId] then
			self.Pool[threadUniqueId]:destroy()
			self.Pool[threadUniqueId] = nil
		end
	end

	function IXSandboxThreadPool.Prototype:initiateSandboxThread(threadObject)
		assert(self.Instance.SandboxThread == nil, "Internal SandboxThread already exists")

		self.Instance.SandboxThread = IXSandboxThread.new(threadObject)
		self:addToThreadPool(self.Instance.SandboxThread)
	end

	function IXSandboxThreadPool.Prototype:initiateSpawnedThread(threadObject)
		local generatedThreadWrapper = IXSandboxThread.new(threadObject)

		self:addToThreadPool(generatedThreadWrapper)
	end

	function IXSandboxThreadPool.new(sandboxInstance)
		local threadPoolInstance = setmetatable({
			Instance = sandboxInstance,
			Pool = { }
		}, {
			__index = IXSandboxThreadPool.Prototype
		})

		return threadPoolInstance
	end

	return IXSandboxThreadPool
end