local IXSandboxThread = { Name = "IX-Sandbox-Thread" }

IXSandboxThread.Prototype = { }

return function(Namespace)
	function IXSandboxThread.Prototype:updateThreadState()
		self.State = coroutine.status(self.Thread)
	end

	function IXSandboxThread.Prototype:closeThread()
		local successful = false
		local message

		while not successful do
			successful, message = pcall(coroutine.close, self.Thread)

			if not successful then
				task.wait()

				Namespace.Console:warn("Exception in closing function:", message)
			end
		end

		self:updateThreadState()
	end

	function IXSandboxThread.Prototype:destroy()
		if self.State ~= "dead" then
			self:closeThread()
		end

		setmetatable(self, { __mode = "kv" })
	end

	function IXSandboxThread.new(threadObject)
		local threadInstance = setmetatable({
			Thread = threadObject,
			UniqueId = IXSandboxThread.getThreadName(threadObject),
			Clock = os.clock()
		}, {
			__index = IXSandboxThread.Prototype
		})

		threadInstance:updateThreadState()

		return threadInstance
	end

	function IXSandboxThread.getThreadName(threadObject)
		local threadMemoryLoc = tostring(threadObject)

		return string.gsub(threadMemoryLoc, "thread: ", "")
	end

	return IXSandboxThread
end