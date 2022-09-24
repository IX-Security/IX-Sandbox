local IXEnvironmentConstructors = require((script and script.Constructors) or "Environment/Constructors/init.lua")
local IXEnvironmentDefinitions = require((script and script.Definitions) or "Environment/Definitions/init.lua")
local Hook = require((script and script.Hook) or "Environment/Hook.lua")

local IXSandboxEnvironment = { Name = "IX-Sandbox-Environment" }

IXSandboxEnvironment.SandboxEnvironment = getfenv()
IXSandboxEnvironment.Prototype = { }

return function(Namespace)
	function IXSandboxEnvironment.Prototype:generateIndex()
		return function(_, index)
			return self.Environment[index]
		end
	end

	function IXSandboxEnvironment.Prototype:generateNewIndex()
		return function(self, index, value)
			rawset(self, index, value)
		end
	end

	function IXSandboxEnvironment.Prototype:generatePsuedoMetaMethods()
		local index = Hook.new(self:generateIndex())
		local newIndex = Hook.new(self:generateNewIndex())

		return { 
			__index = index:generateLuaRawFunction(),
			__newindex = newIndex:generateLuaRawFunction()
		}
	end

	function IXSandboxEnvironment.Prototype:generateEnvironmentFromDefinition()
		local environmentDefinition = IXEnvironmentDefinitions.get(self.Instance.SandboxType)
		local generatedEnvironment = { }

		for key, psuedoTypeInformation in environmentDefinition do
			generatedEnvironment[key] = IXEnvironmentConstructors.constructPsuedoType(psuedoTypeInformation[1], psuedoTypeInformation[2])
		end

		return generatedEnvironment
	end

	function IXSandboxEnvironment.Prototype:protectGeneratedResources()
		local proxyMetaMethods = self:generatePsuedoMetaMethods()
		local genericMetaMethods = { }

		genericMetaMethods.__metatable = "The metatable is locked"

		for metaMethodName, metaMethod in proxyMetaMethods do
			genericMetaMethods[metaMethodName] = metaMethod
		end

		self.GenericMetaTable = genericMetaMethods
		self.Instance.SandboxEnvironment = setmetatable(self.Generic, self.GenericMetaTable)
	end

	function IXSandboxEnvironment.Prototype:generateUniqueEnvironment()
		self.Generic = self:generateEnvironmentFromDefinition()
		self.Ghost = { }

		self:protectGeneratedResources()
	end

	function IXSandboxEnvironment.new(sandboxInstance)
		local environmentInstance = setmetatable({
			Instance = sandboxInstance,
			Environment = sandboxInstance.SandboxEnvironment or IXSandboxEnvironment.SandboxEnvironment
		}, {
			__index = IXSandboxEnvironment.Prototype
		})

		return environmentInstance
	end

	return IXSandboxEnvironment
end