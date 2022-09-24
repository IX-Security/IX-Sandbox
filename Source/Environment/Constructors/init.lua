local IXEnvironmentConstructors = { }

IXEnvironmentConstructors.Types = { }

function IXEnvironmentConstructors.importTypeModule(constructorName)
	local constructorPath = (script and script[constructorName]) or string.format("/Environment/Constructors/%s", constructorName)
	local constructorResolve = require(constructorPath)

	IXEnvironmentConstructors.Types[constructorName] = constructorResolve
end


function IXEnvironmentConstructors.constructPsuedoType(psuedoType, psuedoArguments)
	local arguments = psuedoArguments or { }

	return IXEnvironmentConstructors.Types[psuedoType](table.unpack(arguments))
end

IXEnvironmentConstructors.importTypeModule("Instance")

return IXEnvironmentConstructors