return function(Namespace, sandboxInstance)
	return function(unfilteredObject, userdata)
		local functionName = debug.info(unfilteredObject, "n")

		return function(...)
			sandboxInstance.ThreadPool:queryThread():onNewThreadCall()

			if sandboxInstance.Hooks.Blocked[functionName] then
				Namespace.Console:warn("Attempted to call Blocked Method: `", functionName, "` [", ..., "]")

				return
			end

			local filteredArguments = table.pack(...)
			local unfilteredArguments = sandboxInstance.FilterPool:sanitizeFilteredList(filteredArguments)

			if sandboxInstance.Hooks.Functions[functionName] then
				unfilteredArguments = table.pack(sandboxInstance.Hooks.Functions[functionName](table.unpack(unfilteredArguments, 1, unfilteredArguments.n)))
			else
				unfilteredArguments = table.pack(unfilteredObject(table.unpack(unfilteredArguments, 1, unfilteredArguments.n)))
			end

			filteredArguments = sandboxInstance.FilterPool:sanitizeUnfilteredList(unfilteredArguments)

			if userdata then
				sandboxInstance:invokeSandboxSignal("Namecall", userdata, functionName, filteredArguments, ...)
			else
				sandboxInstance:invokeSandboxSignal("Call", functionName, filteredArguments, ...)
			end

			return table.unpack(filteredArguments, 1, unfilteredArguments.n)
		end
	end
end