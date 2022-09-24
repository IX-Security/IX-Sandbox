local IXEnvironmentDefinitions = { }

function IXEnvironmentDefinitions.get(definition)
	if definition and script:FindFirstChild(definition) then
		return require((script and script[definition]) or string.format("Environment/Definitions/%s", definition))
	else
		return require((script and script.Roblox) or "Environment/Definitions/Roblox")
	end
end

return IXEnvironmentDefinitions