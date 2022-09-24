local IXConsole = { Name = "IX-Console" }

return function(Namespace)
	function IXConsole:warn(...)
		warn("[IX-Sandbox][warn]::", ...)
	end

	function IXConsole:log(...)
		print("[IX-Sandbox][log]::", ...)
	end

	function IXConsole.new()
		return IXConsole
	end

	return IXConsole
end