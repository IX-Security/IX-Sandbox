local IXContextParameterSetters = { }

IXContextParameterSetters.Setters = { }

function IXContextParameterSetters.importSetterModule(setterName)
	local setterPath = (script and script[setterName]) or string.format("/Context/Setters/%s", setterName)
	local setterResolve = require(setterPath)

	IXContextParameterSetters.Setters[setterName] = setterResolve
end

function IXContextParameterSetters.loadParameters(parameterList, sandboxInstance)
	for parameterKey, parameterArguments in parameterList do
		assert(IXContextParameterSetters.Setters[parameterKey] ~= nil, "Unknown Sandbox ContextParameter: " .. tostring(parameterKey))

		IXContextParameterSetters.Setters[parameterKey](sandboxInstance, table.unpack(parameterArguments))
	end
end

IXContextParameterSetters.importSetterModule("SourceName")
IXContextParameterSetters.importSetterModule("Caller")

return IXContextParameterSetters