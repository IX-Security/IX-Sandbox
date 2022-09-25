local ServerStorage = game:GetService("ServerStorage")
local IXSandboxModule = require(ServerStorage.IXSandboxModule)

local SandboxSettings = IXSandboxModule.newSandboxSettings()
local Sandbox = IXSandboxModule.newSandbox(function()
	print(game.Workspace:GetRealPhysicsFPS())
end, SandboxSettings)

Sandbox:execute()