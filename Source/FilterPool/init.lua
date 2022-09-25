local IXSandboxFilter = { Name = "IX-Sandbox-Filter" }

IXSandboxFilter.Prototype = { }
IXSandboxFilter.FilteredDataTypes = {
	["number"] = false,
	["boolean"] = false,
	["nil"] = false,
	["string"] = false,

	["userdata"] = true,
	["function"] = true,
	["table"] = true,
	["thread"] = true,
}

-- Unfiltered - Real implementation of XYZ object
-- Filtered - Proxy implementation of Real object

return function(Namespace)
	function IXSandboxFilter.Prototype:isObjectFilterable(uniqueObject)
		local uniqueObjectType = type(uniqueObject)

		return IXSandboxFilter.FilteredDataTypes[uniqueObjectType]
	end

	function IXSandboxFilter.Prototype:getFilterReference(unfilteredObject)
		return self.Instance.Tracked.Filtered[unfilteredObject]
	end

	function IXSandboxFilter.Prototype:getUnfilteredReference(filteredObject)
		return self.Instance.Tracked.Unfiltered[filteredObject]
	end

	function IXSandboxFilter.Prototype:registerUnfilteredObject(unfilteredObject, ...)
		local filteredObject = self.Filters.mutateUniqueObject(unfilteredObject, ...)

		self.Instance.Tracked.Filtered[unfilteredObject] = filteredObject
		self.Instance.Tracked.Unfiltered[filteredObject] = unfilteredObject

		return filteredObject
	end

	function IXSandboxFilter.Prototype:sanitize(uniqueObject, ...)
		return self:getFilterReference(uniqueObject) or self:registerUnfilteredObject(uniqueObject, ...)
	end

	function IXSandboxFilter.Prototype:sanitizeUnfilteredList(unfilteredList)
		local filtered = { }

		for objectKey, object in unfilteredList do
			if self:isObjectFilterable(object) then
				object = self:getFilterReference(object) or self:registerUnfilteredObject(object)
			end

			filtered[objectKey] = object
		end

		return filtered
	end

	function IXSandboxFilter.Prototype:sanitizeFilteredList(filteredList)
		local unfiltered = { }

		for objectKey, object in filteredList do
			if self:isObjectFilterable(object) then
				object = self:getUnfilteredReference(object) or object
			end

			unfiltered[objectKey] = object
		end

		return unfiltered
	end

	function IXSandboxFilter.new(sandboxInstance)
		local filterInstance = setmetatable({
			Instance = sandboxInstance,
			Filters = require((script and script.Filters) or "FilterPool/Filters/init.lua")
		}, {
			__index = IXSandboxFilter.Prototype
		})

		filterInstance.Filters = filterInstance.Filters(Namespace, filterInstance.Instance)

		return filterInstance
	end

	return IXSandboxFilter
end