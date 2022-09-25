local SANDBOX_TYPE_STRING = "IX-Sandbox"

local SANDBOX_TRACER_NAME = "SANDBOX_TRACER"
local SANDBOX_PARALLEL_NAME = "SANDBOX_PARALLEL"
local SANDBOX_YIELD_CALL = "SANDBOX_YIELD_CALL"

local Signal = require((script and script.Signal) or "Sandbox/Signal.lua")

local IXSandbox = { Name = SANDBOX_TYPE_STRING }
IXSandbox.Prototype = { }

return function(Namespace)
	function IXSandbox.Prototype:createProxyInterface()
		local proxy = newproxy(true)
		local proxyMetatable = getmetatable(proxy)

		function proxyMetatable.__index(_, index)
			return self[index]
		end

		function proxyMetatable.__newindex(_, index, value)
			self[index] = value
		end

		function proxyMetatable.__tostring()
			return string.gsub(tostring(self), "table", SANDBOX_TYPE_STRING)
		end

		return proxy
	end

	function IXSandbox.Prototype:setFlagState(flagName, state)
		assert(self.ExtensionFlags[flagName] ~= nil, string.format("Invalid flag name: %s", flagName))
		assert(state ~= nil, string.format("Illegal state value: %s", tostring(state)))

		self.ExtensionFlags[flagName] = state
	end

	function IXSandbox.Prototype:execute(...)
		self.Signals.Initiated:fire()

		return self.Context:executeFunction(self.ExtensionFlags[SANDBOX_YIELD_CALL], ...)
	end

	function IXSandbox.Prototype:terminate(exitMessage)
		self.Signals.Terminated:fire(exitMessage)

		return self.Context:terminateFunction()
	end

	function IXSandbox.Prototype:destroy()
		self.Signals.Destroyed:fire()

		setmetatable(self, { __mode = "kv" })
	end

	function IXSandbox.Prototype:newLuaFunction(luaFunction)
		assert(self.SandboxEnvironment ~= nil, "LuaFunctions can only be defined once an environment is created")
		setfenv(luaFunction, self.SandboxEnvironment)

		return luaFunction
	end

	function IXSandbox.Prototype:getThreads()
		self.ThreadPool:updateThreadStates()

		return self.ThreadPool.Pool
	end

	function IXSandbox.Prototype:importModule(moduleName, moduleValue)
		self.Tracked.Modules[moduleName] = self:newLuaFunction(self.Context:loadModule(moduleValue))
	end

	function IXSandbox.Prototype:hookMethod(dynamicFunctionDescriptor, hookedFunction)
		local descriptorType = type(dynamicFunctionDescriptor)
		local functionName

		if descriptorType == "function" then
			functionName = debug.info(dynamicFunctionDescriptor, "n")
		else
			functionName = dynamicFunctionDescriptor
		end

		self.Hooks.Functions[functionName] = hookedFunction
	end

	function IXSandbox.Prototype:hookMetaMethod(metaMethod, hookedMethod)
		self.Hooks.MetaMethods[metaMethod] = hookedMethod
	end

	function IXSandbox.Prototype:addLibrary(libraryName, library)
		assert(type(libraryName) == "string", "Expected libraryName to be a string")

		local filterTable

		function filterTable(source)
			for key, value in source do
				local valueType = type(value)

				if valueType == "function" then
					source[key] = self.FilterPool:sanitize(self:newLuaFunction(value))
				elseif valueType == "table" then
					source[key] = filterTable(value)
				elseif self.FilterPool:isObjectFilterable(value) then
					source[key] = self.FilterPool:sanitize(value)
				end
			end
		end

		self.Environment.Internal[libraryName] = filterTable(library)
	end

	function IXSandbox.Prototype:addGlobal(globalName, value)
		local typeValue = type(value)

		assert(type(globalName) == "string", "Expected globalName to be a string")

		if typeValue == "function" then
			value = self:newLuaFunction(value)
		end

		self.Environment.Internal[globalName] = value
	end

	function IXSandbox.Prototype:blockMethod(dynamicFunctionDescriptor)
		local descriptorType = type(dynamicFunctionDescriptor)
		local functionName

		if descriptorType == "function" then
			functionName = debug.info(dynamicFunctionDescriptor, "n")
		else
			functionName = dynamicFunctionDescriptor
		end

		self.Hooks.Blocked[functionName] = true
	end

	function IXSandbox.new(psuedoSandbox)
		local sandboxInstance = setmetatable({
			Tracked = { Filtered = { }, Unfiltered = { }, Connections = { }, Modules = { } },
			Signals = {
				Index = Signal.new(),
				NameIndex = Signal.new(),
				NewIndex = Signal.new(),
				NameNewIndex = Signal.new(),

				Call = Signal.new(),
				Namecall = Signal.new(),

				ThreadSpawned = Signal.new(),

				Initiated = Signal.new(),
				Terminated = Signal.new(),
				Destroyed = Signal.new(),
			},

			Hooks = { Functions = { }, MetaMethods = { }, Blocked = { } },

			ExtensionFlags = {
				[SANDBOX_PARALLEL_NAME] = true,
				[SANDBOX_TRACER_NAME] = true,
				[SANDBOX_YIELD_CALL] = false
 			},
		}, {
			__index = IXSandbox.Prototype
		})

		sandboxInstance.FilterPool = Namespace.FilterPool.new(sandboxInstance)
		sandboxInstance.ThreadPool = Namespace.ThreadPool.new(sandboxInstance)
		sandboxInstance.Environment = Namespace.Environment.new(sandboxInstance)
		sandboxInstance.Context = Namespace.Context.new(sandboxInstance)

		for psuedoIndex, psuedoValue in psuedoSandbox do
			sandboxInstance[psuedoIndex] = psuedoValue
		end

		sandboxInstance.Environment:generateUniqueEnvironment()

		sandboxInstance.Context:loadFunction()
		sandboxInstance.Context:writeFunctionEnvironment()
		sandboxInstance.Context:generateParameters()
		sandboxInstance.Context:generateRequireHook()

		return sandboxInstance:createProxyInterface()
	end

	return IXSandbox
end