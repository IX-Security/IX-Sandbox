return function(className, classProperties)
	local object = Instance.new(className)

	for classProperty, classValue in classProperties do
		object[classProperty] = classValue
	end

	return object
end