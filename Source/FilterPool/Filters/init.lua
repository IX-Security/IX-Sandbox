local IXSandboxFilters = { }

IXSandboxFilters.Filters = { }

function IXSandboxFilters.importFilterModule(filterType, ...)
	local filterPath = (script and script[filterType]) or string.format("/FilterPool/Filters/%s", filterType)
	local filterResolve = require(filterPath)

	IXSandboxFilters.Filters[filterType] = filterResolve(...)
end

return function(Namespace, sandboxInstance)
	function IXSandboxFilters.mutateUniqueObject(object, ...)
		local filterType = typeof(object)

		if not IXSandboxFilters.Filters[filterType] then
			filterType = type(object)
		end

		if not IXSandboxFilters.Filters[filterType] then
			Namespace.Console:warn("Unknown Filter Type: " .. filterType)

			return object
		end

		return IXSandboxFilters.Filters[filterType](object, ...)
	end

	IXSandboxFilters.importFilterModule("table", Namespace, sandboxInstance)
	IXSandboxFilters.importFilterModule("function", Namespace, sandboxInstance)
	IXSandboxFilters.importFilterModule("userdata", Namespace, sandboxInstance)

	IXSandboxFilters.importFilterModule("thread", Namespace, sandboxInstance)
	IXSandboxFilters.importFilterModule("RBXScriptSignal", Namespace, sandboxInstance)

	return IXSandboxFilters
end