local Signal = { }
local Connection = { }

function Connection:reconnect()
    if self.connected then return end

    self.connected = true
    self._connect()
end

function Connection:disconnect()
    if not self.connected then return end

    self.connected = false
    self._disconnect()
end

function Signal:wait()
    local thread = coroutine.running()

    table.insert(self._yield, thread)
    return coroutine.yield()
end

function Signal:connect(callback)
    local signalConnection = Signal.newConnection(function()
        table.insert(self._tasks, callback)
    end, function()
        for index, taskCallback in ipairs(self._tasks) do
            if taskCallback == callback then
               return table.remove(self._tasks, index)
            end
        end
    end)

    signalConnection:Reconnect()
    return signalConnection
end

function Signal:fire(...)
    for _, taskCallback in ipairs(self._tasks) do
        local callback = taskCallback

        callback(...)
    end

    for _, yieldCoroutine in ipairs(self._yield) do
        task.spawn(yieldCoroutine, ...)
    end

    self._yield = { }
end

-- // Signal Functions
function Signal.newConnection(ConnectCallback, disconnectCallback)
    return setmetatable({ 
        _connect = ConnectCallback,
        _disconnect = disconnectCallback,
        connected = false
    }, Connection)
end

function Signal.new()
	local self = setmetatable({ 
        _tasks = { }, _yield = { }
    }, {
		__index = Signal
	})

	return self
end

-- // Module
return Signal