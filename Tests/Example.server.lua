local ServerStorage = game:GetService("ServerStorage")
local IXSandboxModule = require(ServerStorage.IXSandboxModule)

local SandboxSettings = IXSandboxModule.newSandboxSettings()
local Sandbox = IXSandboxModule.newSandbox(function()
	game.Workspace.DescendantAdded:Connect(function(Object)
		warn(Object)
	end)
end, SandboxSettings)

Sandbox:execute()

task.wait(5)

print(Sandbox:generateActivityReport())