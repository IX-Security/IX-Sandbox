return function(sandboxInstance, sandboxSourceName)
	local sandboxEnvironment = sandboxInstance.SandboxEnvironment

	if sandboxEnvironment and sandboxEnvironment.script then
		sandboxInstance.SandboxEnvironment.script.Name = sandboxSourceName
	end
end