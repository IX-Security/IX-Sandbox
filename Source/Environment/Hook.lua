local Hook = { }

function Hook:prefix(callback)
	assert(type(callback) == "function", "Expected Argument #1 function")

	self._prefixCallback = callback
end

function Hook:postfix(callback)
	assert(type(callback) == "function", "Expected Argument #1 function")

	self._postfixCallback = callback
end

function Hook:patch(callback)
	assert(type(callback) == "function", "Expected Argument #1 function")

	self.callback = callback
end

function Hook:invoke(...)
	if not self.callback then return end

	if self._prefixCallback then
		local breakIter, exception = self._prefixCallback(...)

		if breakIter then return exception end
	end

	if self._postfixCallback then
		return self._postfixCallback(
			self.callback(...)
		)
	end

	return self.callback(...)
end

function Hook:generateLuaRawFunction()
	return function(...)
		return self:invoke(...)
	end
end

function Hook.new(callback)
	return setmetatable({ callback = callback }, {
		__index = Hook,
		__call = function(self, ...)
			return self:invoke(...)
		end
	})
end

return Hook