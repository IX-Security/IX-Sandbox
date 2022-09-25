return function(Namespace, sandboxInstance)
	return function(unfilteredObject)
		sandboxInstance.ThreadPool:initiateSpawnedThread(unfilteredObject)

		return unfilteredObject
	end
end