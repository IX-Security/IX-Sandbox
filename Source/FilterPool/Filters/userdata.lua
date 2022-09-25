return function(Namespace, sandboxInstance)
	local function generateTostringMetaMethod(object)
		return function()
			return object.Name
		end
	end

	return function(unfilteredObject)
		local filteredObject = newproxy(true)
		local filteredMetatable = getmetatable(filteredObject)

		local generatedMetaMethods = sandboxInstance.Environment:generatePsuedoMetaMethods(unfilteredObject)

		filteredMetatable.__metatable = "The metatable is locked"
		filteredMetatable.__tostring = generateTostringMetaMethod(unfilteredObject)

		for metaMethodName, metaMethod in generatedMetaMethods do
			filteredMetatable[metaMethodName] = metaMethod
		end

		return filteredObject
	end
end