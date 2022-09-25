local Janitor = { }

function Janitor:add(dynamicObject)
	table.insert(self._trash, dynamicObject)

	return function()
		local trashIndex = table.find(self._trash, dynamicObject)

		if trashIndex then
			table.remove(self._trash, trashIndex)
		end
	end
end

function Janitor:remove(dynamicObject)
	for index, localDynamicObject in ipairs(self._trash) do
		if localDynamicObject == dynamicObject then
			return table.remove(self._trash, index)
		end
	end
end

function Janitor:deconstructor(Type, Callback)
	self._deconstructors[Type] = Callback
end

function Janitor:clean()
	for _, DynamicTrashObject in ipairs(self._trash) do
		local DynamicTrashType = typeof(DynamicTrashObject)

		if self._deconstructors[DynamicTrashType] then
			self._deconstructors[DynamicTrashType](DynamicTrashObject)
		end
	end
end

function Janitor:destroy()
	self:clean()

	setmetatable({ }, { __mode = "kv" })
end

function Janitor.new()
	local self = setmetatable({ 
		_deconstructors = { },
		_trash = { }
	}, {
		__index = Janitor
	})

	self:deconstructor("function", function(value)
		return value()
	end)

	self:deconstructor("RBXScriptConnection", function(value)
		return value.Connected and value:Disconnect()
	end)

	return self
end

return Janitor