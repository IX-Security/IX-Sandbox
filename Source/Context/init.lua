

local IX_YIELD_FUNCTION_WARNING_MESSAGE = ""

local IXContextParameterSetters = require((script and script.Setters) or "Context/Setters/init.lua")
local IXSandboxContext = { Name = "IX-Sandbox-Context" }
IXSandboxContext.Prototype = { }

return function(Namespace)
	function IXSandboxContext.Prototype:executeFunction(yield, ...)
		if yield then
			Namespace.Console:warn(IX_YIELD_FUNCTION_WARNING_MESSAGE)

			return xpcall(self.SourceThread, function(e)
				Namespace.Console:warn("Exception in yielding function:", e)
			end, ...)
		else
			return task.spawn(self.SourceThread, ...)
		end
	end

	function IXSandboxContext.Prototype:terminateFunction()
		for _, threadObject in self.Instance.ThreadPool:toThreadList() do
			threadObject:closeThread()
		end
	end

	function IXSandboxContext.Prototype:writeFunctionEnvironment()
		assert(self.SourceFunction ~= nil, "Expected call :loadFunction before :writeFunctionEnvironment")

		local targetInstanceEnvironment = self.Instance.SandboxEnvironment

		return setfenv(self.SourceFunction, targetInstanceEnvironment)
	end

	function IXSandboxContext.Prototype:loadFunction()
		local success, result = pcall(loadstring, self.Instance.Source)

		assert(success, result)

		self.SourceFunction = result
		self.SourceThread = coroutine.create(self.SourceFunction)

		self.Instance.ThreadPool:initiateSandboxThread(self.SourceThread)
	end

	function IXSandboxContext.Prototype:generateParameters()
		if self.Instance.SandboxContext then
			IXContextParameterSetters.loadParameters(self.Instance.SandboxContext, self.Instance)
		end
	end

	function IXSandboxContext.new(sandboxInstance)
		local contextInstance = setmetatable({ Instance = sandboxInstance }, {
			__index = IXSandboxContext.Prototype
		})

		return contextInstance
	end

	return IXSandboxContext
end