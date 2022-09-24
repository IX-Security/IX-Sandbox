local IXSandboxFilter = { Name = "IX-Sandbox-Filter" }

IXSandboxFilter.Prototype = { }

return function(Namespace)
	function IXSandboxFilter.Prototype:getDataReference()
		
	end

	function IXSandboxFilter.Prototype:getProxyReference()
		
	end

	function IXSandboxFilter.Prototype:registerUniqueObject()
		
	end

	function IXSandboxFilter.Prototype:sanitizeUnfilteredList()
		
	end

	function IXSandboxFilter.Prototype:sanitizeFilteredList()
		
	end

	function IXSandboxFilter.new(sandboxInstance)
		local filterInstance = setmetatable({
			Instance = sandboxInstance,
			Filters = require((script and script.Filters) or "FilterPool/Filters/init.lua")
		}, {
			__index = IXSandboxFilter.Prototype
		})

		filterInstance.Filters = filterInstance.Filters(filterInstance)

		return filterInstance
	end

	return IXSandboxFilter
end