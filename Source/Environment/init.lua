local IXEnvironmentConstructors = require((script and script.Constructors) or "Environment/Constructors/init.lua")
local IXEnvironmentDefinitions = require((script and script.Definitions) or "Environment/Definitions/init.lua")
local Hook = require((script and script.Hook) or "Environment/Hook.lua")

local IXSandboxEnvironment = { Name = "IX-Sandbox-Environment" }

IXSandboxEnvironment.SandboxEnvironment = getfenv()
IXSandboxEnvironment.Prototype = { }

return function(Namespace)
	function IXSandboxEnvironment.Prototype:filterIndexResult(uniqueObject, ...)
		if self.Instance.FilterPool:isObjectFilterable(uniqueObject) then
			return self.Instance.FilterPool:sanitize(uniqueObject, ...)
		else
			return uniqueObject
		end
	end

	function IXSandboxEnvironment.Prototype:generateIndex(object)
		return function(_, index)
			if object then
				if self.Instance.Hooks.MetaMethods.__index then
					local hookedResult = self.Instance.Hooks.MetaMethods.__index(object, index)
					local hookedResultType = type(hookedResult)

					if hookedResultType == "function" and debug.info(hookedResult, "s") ~= "[C]" then
						hookedResult = self.Instance:newLuaFunction(hookedResult)
					end

					self.Instance:invokeSandboxSignal("NameIndex", object, index, hookedResult, true)

					return self:filterIndexResult(hookedResult, object)
				end

				self.Instance:invokeSandboxSignal("NameIndex", object, index, object[index])

				return self:filterIndexResult(object[index], object)
			else
				if self.Internal[index] then
					self.Instance:invokeSandboxSignal("Index", index, self.Internal[index], true)

					return self.Internal[index]
				end

				self.Instance:invokeSandboxSignal("Index", index, self.InternalEnvironment[index])

				return self:filterIndexResult(self.InternalEnvironment[index])
			end
		end
	end

	function IXSandboxEnvironment.Prototype:generateNewIndex(object)
		return function(environment, index, value)
			if object then
				self.Instance:invokeSandboxSignal("NameNewIndex", object, index, value)

				if self.Instance.Hooks.MetaMethods.__newindex then
					self.Instance.Hooks.MetaMethods.__newindex(object, index, value)

					return
				end

				object[index] = value
			else
				self.Instance:invokeSandboxSignal("NewIndex", index, value)

				rawset(environment, index, value)
			end
		end
	end

	function IXSandboxEnvironment.Prototype:generatePsuedoMetaMethods(...)
		local index = self:generateIndex(...)
		local newIndex = self:generateNewIndex(...)

		return { 
			__index = index,
			__newindex = newIndex
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
		self.Instance.SandboxEnvironment = setmetatable(self.Environment, self.GenericMetaTable)
	end

	function IXSandboxEnvironment.Prototype:generateUniqueEnvironment()
		self.Environment = self:generateEnvironmentFromDefinition()

		self:protectGeneratedResources()
	end

	function IXSandboxEnvironment.new(sandboxInstance)
		local environmentInstance = setmetatable({
			Internal = { ["getfenv"] = getfenv, ["setfenv"] = setfenv, ["xpcall"] = xpcall, ["pcall"] = pcall, ["ypcall"] = ypcall },
			Instance = sandboxInstance,
			InternalEnvironment = sandboxInstance.SandboxEnvironment or IXSandboxEnvironment.SandboxEnvironment
		}, {
			__index = IXSandboxEnvironment.Prototype
		})

		return environmentInstance
	end

	return IXSandboxEnvironment
end