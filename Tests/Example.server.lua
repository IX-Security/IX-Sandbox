local ServerStorage = game:GetService("ServerStorage")
local IXSandboxModule = require(ServerStorage.IXSandboxModule)

local SandboxSettings = IXSandboxModule.newSandboxSettings()
local Sandbox = IXSandboxModule.newSandbox([[for i = 0, 100 do print(i, script.Name) task.wait(1) end]], SandboxSettings)

Sandbox:execute()

task.wait(5)

warn("TERMINATING ALL THREADS!")

Sandbox:terminate()

warn("TERMINATED ALL THREADS!")