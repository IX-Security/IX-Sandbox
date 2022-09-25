

local IX_YIELD_FUNCTION_WARNING_MESSAGE = ""

local Janitor = require((script and script.Janitor) or "Context/Janitor.lua")

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

	function IXSandboxContext.Prototype:loadModule(moduleSource)
		local sourceType = type(moduleSource)

		if sourceType == "string" then
			local success, result = pcall(loadstring, self.Instance.Source)

			assert(success, result)

			return result
		else
			return moduleSource
		end
	end

	function IXSandboxContext.Prototype:loadFunction()
		local sourceType = type(self.Instance.Source)

		if sourceType == "string" then
			local success, result = pcall(loadstring, self.Instance.Source)

			assert(success, result)

			self.SourceFunction = result
			self.SourceThread = coroutine.create(self.SourceFunction)

			self.Instance.ThreadPool:initiateSandboxThread(self.SourceThread)
		else
			self.SourceFunction = self.Instance.Source
			self.SourceThread = coroutine.create(self.SourceFunction)

			self.Instance.Source = "<Unknown>"
			self.Instance.ThreadPool:initiateSandboxThread(self.SourceThread)
		end
	end

	function IXSandboxContext.Prototype:generateParameters()
		if self.Instance.SandboxContext then
			IXContextParameterSetters.loadParameters(self.Instance.SandboxContext, self.Instance)
		end
	end

	function IXSandboxContext.Prototype:generateRequireHook()
		self.Instance:hookMethod("require", function(module)
			local moduleType = type(module)

			if moduleType == "number" then
				if self.Instance.Tracked.Modules[module] then
					return self.Instance.Tracked.Modules[module]()
				end

				Namespace.Console:warn("Unknown module required:", module)

				error("Downloading asset failed for asset id -1.  Is the asset id correct and is the asset type \"Model\"?", 2)
			elseif moduleType == "userdata" and module:IsA("ModuleScript") then
				if self.Instance.Tracked.Modules[module.Name] then
					return self.Instance.Tracked.Modules[module.Name]()
				end
			end

			Namespace.Console:warn("Unknown module required:", module)

			error("Attempted to call require with invalid argument(s).", 2)
		end)
	end

	function IXSandboxContext.Prototype:parseLogArguments(...)
		local argList = { }

		for _, argument in { ... } do
			local argumentType = type(argument)

			if argumentType == "function" then
				table.insert(argList, self:parseLogFunction(argument))
			else
				table.insert(argList, tostring(argument))
			end
		end

		return argList
	end

	function IXSandboxContext.Prototype:parseLogFunction(object)
		if type(object) == "function" then
			local functionName = debug.info(object, "n")
			local functionMemoryLoc = tostring(object)

			if functionName == functionMemoryLoc then
				return functionMemoryLoc
			else
				return string.format("%s [%s]", functionName, string.gsub(functionMemoryLoc, "function: ", ""))
			end
		end

		return tostring(object)
	end

	function IXSandboxContext.Prototype:createSandboxLog(message)
		table.insert(self.Instance.Activity, message)
	end

	function IXSandboxContext.Prototype:createActivityLogger()
		self.ActivityLoggerJanitor = Janitor.new()

		self.ActivityLoggerJanitor:add(self.Instance.Signals.Index:connect(function(index, result)
			result = self:parseLogFunction(result)

			self:createSandboxLog(string.format("[INDEX]:: _ENV.%s :== %s", index, tostring(result)))
		end))

		self.ActivityLoggerJanitor:add(self.Instance.Signals.NewIndex:connect(function(index, result)
			result = self:parseLogFunction(result)

			self:createSandboxLog(string.format("[NEW-INDEX]:: _ENV.%s = %s", index, tostring(result)))
		end))

		self.ActivityLoggerJanitor:add(self.Instance.Signals.NameIndex:connect(function(object, index, result, hooked)
			self:createSandboxLog(string.format("[INDEX@%s]:: %s.%s :== %s", hooked and "HOOKED" or "SOURCE", tostring(object), index, tostring(result)))
		end))

		self.ActivityLoggerJanitor:add(self.Instance.Signals.NameNewIndex:connect(function(object, index, value, hooked)
			index = self:parseLogFunction(index)
			value = self:parseLogFunction(value)

			self:createSandboxLog(string.format("[NEW-INDEX@%s]:: %s.%s = %s", hooked and "HOOKED" or "SOURCE", tostring(object), index, tostring(value)))
		end))

		self.ActivityLoggerJanitor:add(self.Instance.Signals.Call:connect(function(functionName, resultArguments, ...)
			local rArgList = self:parseLogArguments(table.unpack(resultArguments, 1, resultArguments.n))
			local argList = self:parseLogArguments(...)

			if (rArgList.n and rArgList.n > 0) or #rArgList > 0 then
				self:createSandboxLog(string.format("[CALL]:: %s [ %s ] :== [ %s ]", functionName, table.concat(argList, ", "), table.concat(rArgList, ", ")))
			else
				self:createSandboxLog(string.format("[CALL]:: %s [ %s ]", functionName, table.concat(argList, ", ")))
			end
		end))

		self.ActivityLoggerJanitor:add(self.Instance.Signals.Namecall:connect(function(object, functionName, resultArguments, ...)
			local rArgList = self:parseLogArguments(table.unpack(resultArguments, 1, resultArguments.n))
			local argList = self:parseLogArguments(...)

			if (rArgList.n and rArgList.n > 0) or #rArgList > 0 then
				self:createSandboxLog(string.format("[NAMECALL]:: %s.%s [ %s ] :== [ %s ]", tostring(object), functionName, table.concat(argList, ", "), table.concat(rArgList, ", ")))
			else
				self:createSandboxLog(string.format("[NAMECALL]:: %s.%s [ %s ]", tostring(object), functionName, table.concat(argList, ", ")))
			end
		end))

		self.ActivityLoggerJanitor:add(self.Instance.Signals.ThreadSpawned:connect(function(generatedThread)
			self:createSandboxLog(string.format("[NEW-THREAD]:: %s", generatedThread.UniqueId))
		end))

		self.ActivityLoggerJanitor:add(self.Instance.Signals.Initiated:connect(function()
			self.ActivityStartClock = os.clock()

			self:createSandboxLog(string.format("[INITIATED]:: %s", self.Instance.SandboxThread.UniqueId))
		end))

		self.ActivityLoggerJanitor:add(self.Instance.Signals.Terminated:connect(function()
			self:createSandboxLog(string.format("[TERMINATED]:: %s (%dMS)", self.Instance.SandboxThread.UniqueId, os.clock() - self.ActivityStartClock))

			self.ActivityStartClock = nil
		end))
	end

	function IXSandboxContext.new(sandboxInstance)
		local contextInstance = setmetatable({ Instance = sandboxInstance }, {
			__index = IXSandboxContext.Prototype
		})

		return contextInstance
	end

	return IXSandboxContext
end