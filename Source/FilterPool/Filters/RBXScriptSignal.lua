return function(Namespace, sandboxInstance)
	local function generateTostringMetaMethod(object)
		return function()
			return object.Name
		end
	end

	return function(unfilteredObject)
		local filteredObject = newproxy(true)
		local filteredMetatable = getmetatable(filteredObject)

		filteredMetatable.__metatable = "The metatable is locked"
		filteredMetatable.__tostring = generateTostringMetaMethod(unfilteredObject)
		filteredMetatable.__newindex = sandboxInstance.Environment:generateNewIndex(unfilteredObject)
		filteredMetatable.__index = function(_, index)
			if index == "Connect" then
				-- @TODO: Implementation of LuaCFunctions ;; As of right now this Function can be detected.

				return function(self, callback)
					self = sandboxInstance.FilterPool:getUnfilteredReference(self) or self
					callback = sandboxInstance.FilterPool:getUnfilteredReference(callback) or callback

					local selfTypeOf = typeof(self)
					local connectionState = true

					if selfTypeOf ~= "RBXScriptSignal" then
						error("invalid argument #1 to 'Connect' (RBXScriptSignal expected, got " .. selfTypeOf .. ")", 2)
					end

					local internalInvoker = function(...)
						if not connectionState then
							return
						end

						local invokedParameters = table.pack(...)
						local filteredArguments = sandboxInstance.FilterPool:sanitizeUnfilteredList(invokedParameters)

						sandboxInstance.ThreadPool:initiateSpawnedThread(task.spawn(callback, table.unpack(filteredArguments, 1, filteredArguments.n)))
					end
					local unfilteredConnection = unfilteredObject:Connect(internalInvoker)

					table.insert(sandboxInstance.Tracked.Connections, {
						Activate = internalInvoker,
						Connection = unfilteredConnection,

						SetState = function(state)
							connectionState = state
						end
					})

					return sandboxInstance.Environment:filterIndexResult(unfilteredConnection)
				end
			else
				return sandboxInstance.Environment:filterIndexResult(unfilteredObject[index], unfilteredObject)
			end
		end

		return filteredObject
	end
end