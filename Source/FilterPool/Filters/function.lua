return function(Namespace, sandboxInstance)
	return function(unfilteredObject, userdata)
		local functionName = debug.info(unfilteredObject, "n")

		return function(...)
			if sandboxInstance.Hooks.Blocked[functionName] then
				Namespace.Console:warn("Attempted to call Blocked Method: `", functionName, "` [", ..., "]")

				return
			end

			if userdata then
				sandboxInstance.Signals.Namecall:fire(functionName, ...)
			else
				sandboxInstance.Signals.Call:fire(functionName, ...)
			end

			local filteredArguments = table.pack(...)
			local unfilteredArguments = sandboxInstance.FilterPool:sanitizeFilteredList(filteredArguments)

			if sandboxInstance.Hooks.Functions[functionName] then
				unfilteredArguments = table.pack(sandboxInstance.Hooks.Functions[functionName](table.unpack(unfilteredArguments, 1, unfilteredArguments.n)))
			else
				unfilteredArguments = table.pack(unfilteredObject(table.unpack(unfilteredArguments, 1, unfilteredArguments.n)))
			end

			filteredArguments = sandboxInstance.FilterPool:sanitizeUnfilteredList(unfilteredArguments)

			return table.unpack(filteredArguments, 1, unfilteredArguments.n)
		end
	end
end