local ServerStorage = game:GetService("ServerStorage")
local IXSandboxModule = require(ServerStorage.IXSandboxModule)

local SandboxSettings = IXSandboxModule.newSandboxSettings()
local Sandbox = IXSandboxModule.newSandbox(function()
	local module = require(game.ReplicatedStorage.test)

	print(module.text)
end, SandboxSettings)

Sandbox:importModule("test", function()
	return {
		text = "Hello, World!"
	}
end)

Sandbox:execute()