export type SandboxThread = {
	State: nil | string,
	Thread: thread,
	UniqueId: string,
	Clock: number,
	Calls: number
}

export type Sandbox = {
	isThrottled: boolean,

	setFlagState: (self: Sandbox, flagName: string, state: boolean) -> nil,

	execute: (...any) -> ...any,
	terminate: (exitMessage: string) -> nil,
	destroy: () -> nil,

	newLuaFunction: (luaFunction: (...any) -> ...any) -> (...any) -> ...any,

	getThreads: () -> { [number]: SandboxThread },
	importModule: (moduleName: string | number, module: (...any) -> ...any) -> nil,

	hookMethod: (dynamicFunctionDescriptor: string, hookedFunction: (...any) -> ...any) -> nil,
	hookMetaMethod: (metaMethod: string, hookedMethod: (...any) -> ...any) -> nil,

	addLibrary: (libraryName: string, library: { [any]: any }) -> nil,
	addGlobal: (globalName: string, value: any) -> nil,

	blockMethod: (dynamicFunctionDescriptor: string) -> nil,
	generateActivityReport: (history: number) -> string,

	throttleOutboundRequests: (int: number) -> nil,
	incrementThrottledRequest: () -> nil,

	invokeSandboxSignal: (signal: string, ...any) -> nil,
}

export type SettingContext = { 
	SourceName: { [string]: string },
	ExposeCaller: boolean,
	ThrottleLimit: number | nil | false
}

export type Settings = {
	Type: string,
	Environment: false | { [string]: any },
	Context: SettingContext
}

export type Module = {
	newSandboxSettings: () -> Settings,
	newSandbox: (source: (...any) -> ...any, settings: Settings) -> Sandbox
}

return "Sandbox-Types"