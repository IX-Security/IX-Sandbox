local IXSandboxFilters = { }

IXSandboxFilters.Filters = { }

function IXSandboxFilters.importFilterModule(filterType)
	local filterPath = (script and script[filterType]) or string.format("/FilterPool/Filters/%s", filterType)
	local filterResolve = require(filterPath)

	IXSandboxFilters.Filters[filterType] = filterResolve
end

return function(filterInstance)
	function IXSandboxFilters.mutateUniqueObject(filterType, object)
		return IXSandboxFilters.Filters[filterType](filterInstance.Instance, object)
	end

	return IXSandboxFilters
end