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

	function IXSandbox.new(psuedoSandbox)
		local sandboxInstance = setmetatable({
			Tracked = { Datas = { }, Proxies = { } },
			IndexExceptions = { }, Signals = {
				Index = Signal.new(),
				Newindex = Signal.new(),
				Nameindex = Signal.new(),

				Call = Signal.new(),
				Namecall = Signal.new(),

				ThreadSpawned = Signal.new(),
				ObjectFiltered = Signal.new(),
				ConnectionSpawned = Signal.new(),

				Initiated = Signal.new(),
				Terminated = Signal.new(),
				Destroyed = Signal.new(),
			},

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

		return sandboxInstance:createProxyInterface()
	end

	return IXSandbox
end