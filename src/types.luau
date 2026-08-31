--!strict

export type Callback = (...any) -> ()

export type Connection = {
	Connected: boolean,
	Disconnect: (self: Connection) -> (),
}

export type Signal<T...> = {
	Connect: (self: Signal<T...>, callback: (T...) -> ()) -> Connection,
	Once: (self: Signal<T...>, callback: (T...) -> ()) -> Connection,
	Fire: (self: Signal<T...>, T...) -> (),
	Destroy: (self: Signal<T...>) -> (),
}

export type MaidTask =
	RBXScriptConnection
	| (() -> ())
	| Instance
	| { Destroy: (self: any) -> () }

export type WindowConfig = {
	Size: UDim2?,
	Position: UDim2?,
	MinSize: Vector2?,
}

export type ButtonConfig = {
	Label: string,
	Icon: string?,
	Variant: number?,
	Enabled: boolean?,
	LayoutOrder: number?,
}

export type ToggleConfig = {
	Label: string,
	Icon: string?,
	Default: boolean?,
	Enabled: boolean?,
	LayoutOrder: number?,
}

export type LabelConfig = {
	Text: string,
	Color: Color3?,
	LayoutOrder: number?,
}

export type DividerConfig = {
	Text: string?,
	LayoutOrder: number?,
}

return {}
