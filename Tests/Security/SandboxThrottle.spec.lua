local ServerStorage = game:GetService("ServerStorage")

return function()
	local IXSandboxModule = require(ServerStorage.IXSandboxModule)

	describe("Sandbox-Throttling", function()
		it("Expected sandbox to be throttled", function()
			local throttledLimit = 25
			local sandboxSettings = IXSandboxModule.newSandboxSettings()
			sandboxSettings.Context.ThrottleLimit = { 25 }

			local sandbox = IXSandboxModule.newSandbox(function()
				for index = 0, throttledLimit * 10 do
					math.randomseed(index)
				end
			end, sandboxSettings)

			sandbox:execute()

			warn(sandbox.isThrottled)

			expect(sandbox.isThrottled).to.be.equal(true)
		end)
	end)
end