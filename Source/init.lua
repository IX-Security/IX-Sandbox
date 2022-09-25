local TypesModule = require((script and script.Types) or "/Types")

local IXSandboxModule: TypesModule.Module = { }

local IXSandboxNamespace = { Name = "SandboxIXSandboxNamespace" }
local IXSupportedSandboxTypes = {
	["Roblox"] = true,
	["Lua"] = true,
}

function IXSandboxModule.initiateIXDependency(dependencyName)
	local dependencyPath = (script and script[dependencyName]) or string.format("/%s/init", dependencyName)
	local dependencyResolve = require(dependencyPath)
	local dependencyResolveType = type(dependencyResolve)

	if dependencyResolveType == "function" then
		IXSandboxNamespace[dependencyName] = dependencyResolve(IXSandboxNamespace)
	else
		IXSandboxNamespace[dependencyName] = dependencyResolve
	end
end

function IXSandboxModule.newSandboxSettings(): TypesModule.Settings
	return {
		Type = "Roblox",
		Environment = false,
		Context = {
			SourceName = { "IX-Sandbox-Script" }
		}
	}
end

function IXSandboxModule.newSandbox(source: string, sandboxSettings: TypesModule.Settings): TypesModule.Class
	local sourceType = type(source)

	if sourceType == "string" then
		assert(#source > 0, "Expected Source: string, Got: <EmptyString>")
	end

	if sandboxSettings then
		assert(IXSupportedSandboxTypes[sandboxSettings.Type], "Unsupported SandboxType: " .. tostring(sandboxSettings.Type))
	end

	local psuedoSandboxInstance = { }

	psuedoSandboxInstance.SandboxType = sandboxSettings.Type or IXSupportedSandboxTypes[1]
	psuedoSandboxInstance.SandboxEnvironment = sandboxSettings.Environment
	psuedoSandboxInstance.SandboxContext = sandboxSettings.Context
	psuedoSandboxInstance.Caller = debug.info(2, "s")
	psuedoSandboxInstance.Source = source

	return IXSandboxNamespace.Sandbox.new(psuedoSandboxInstance)
end

IXSandboxModule.initiateIXDependency("Console")
IXSandboxModule.initiateIXDependency("ThreadPool")
IXSandboxModule.initiateIXDependency("FilterPool")
IXSandboxModule.initiateIXDependency("Environment")
IXSandboxModule.initiateIXDependency("Context")
IXSandboxModule.initiateIXDependency("Sandbox")

return IXSandboxModule