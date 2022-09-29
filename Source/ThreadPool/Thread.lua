local IXSandboxThread = { Name = "IX-Sandbox-Thread" }

IXSandboxThread.Prototype = { }

return function(Namespace)
	function IXSandboxThread.Prototype:updateThreadState()
		self.State = coroutine.status(self.Thread)
	end

	function IXSandboxThread.Prototype:onNewThreadCall()
		if self.Yielding then
			self.State = "suspended"

			coroutine.yield()
		end

		self.Calls += 1
	end

	function IXSandboxThread.Prototype:yieldThread()
		self.Yielding = true
	end

	function IXSandboxThread.Prototype:resumeThread()
		local successful = false
		local message

		self.Yielding = false

		if self.State == "suspended" then
			while not successful do
				successful, message = pcall(coroutine.resume, self.Thread)

				if not successful then
					task.wait()

					Namespace.Console:warn("Exception in yielding function:", message)
				end
			end

			self:updateThreadState()
		end
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

	function IXSandboxThread.new(threadObject)
		local threadInstance = setmetatable({
			Thread = threadObject,
			UniqueId = IXSandboxThread.getThreadName(threadObject),
			Clock = os.clock(),
			Calls = 0
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