return function(Namespace, sandboxInstance)
	local filterTableObject do
		function filterTableObject(unfilteredObject)
			local filteredTable = { }

			for key, value in unfilteredObject do
				if sandboxInstance.FilterPool:isObjectFilterable(key) then
					key = sandboxInstance.FilterPool:sanitize(key)
				end

				if sandboxInstance.FilterPool:isObjectFilterable(value) then
					value = sandboxInstance.FilterPool:sanitize(value)
				end

				filteredTable[key] = value
			end

			return filteredTable
		end
	end

	return function(unfilteredObject)
		return filterTableObject(unfilteredObject)
	end
end