export type Class = {
	
}

export type Module = {
	
}

export type SettingContext = { 
	SourceName: { [string]: string }
}

export type Settings = {
	Type: string,
	Environment: { [any]: any },
	Context: SettingContext
}

return "Sandbox-Types"