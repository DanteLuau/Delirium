--!strict

-- Delirium UI Library
-- types.luau — All public-facing exported types.
-- Consumers import from here to annotate their own scripts.

-- ── Primitive prop types ──────────────────────────────────────────────────────

export type Theme = string | { [string]: any }

export type WindowProps = {
	name:         string?,
	subtitle:     string?,
	theme:        Theme?,
	keybind:      (EnumItem | string)?,
	keepOnScreen: boolean?,
	gestureBar:   boolean?,
}

export type TabProps = {
	name:    string?,
	icon:    string?,
	badge:   string?,
	columns: number?,
}

export type SectionProps = {
	name: string?,
}

export type LabelProps = {
	text:      string?,
	richText:  boolean?,
	textSize:  number?,
	textColor: Color3?,
}

export type ButtonProps = {
	name:        string?,
	description: string?,
	callback:    (() -> ())?,
}

export type ToggleProps = {
	name:        string?,
	description: string?,
	flag:        string?,
	value:       boolean?,
	callback:    ((value: boolean) -> ())?,
}

export type SliderProps = {
	name:               string?,
	Label:              string?,
	Text:               string?,
	description:        string?,
	Tooltip:            string?,
	flag:               string?,
	Flag:               string?,
	range:              { number }?,
	min:                number?,
	Min:                number?,
	max:                number?,
	Max:                number?,
	increment:          number?,
	step:               number?,
	Step:               number?,
	value:              number?,
	default:            number?,
	Default:            number?,
	suffix:             string?,
	Suffix:             string?,
	compact:            boolean?,
	Compact:            boolean?,
	hideMax:            boolean?,
	HideMax:            boolean?,
	formatDisplayValue: ((slider: any, value: number) -> string?)?,
	FormatDisplayValue: ((slider: any, value: number) -> string?)?,
	enabled:            boolean?,
	Enabled:            boolean?,
	layoutOrder:        number?,
	LayoutOrder:        number?,
	callback:           ((value: number) -> ())?,
	Callback:           ((value: number) -> ())?,
}

export type DropdownProps = {
	name:                    string?,
	Label:                   string?,
	Text:                    string?,
	description:             string?,
	Tooltip:                 string?,
	flag:                    string?,
	Flag:                    string?,
	options:                 { any }?,
	Options:                 { any }?,
	value:                   any?,
	default:                 any?,
	Default:                 any?,
	multiSelect:             boolean?,
	MultiSelect:             boolean?,
	placeholder:             string?,
	Placeholder:             string?,
	searchable:              boolean?,
	Searchable:              boolean?,
	disabledValues:          { any }?,
	DisabledValues:          { any }?,
	formatDisplayValue:      ((value: any) -> string)?,
	FormatDisplayValue:      ((value: any) -> string)?,
	maxVisibleDropdownItems: number?,
	MaxVisibleDropdownItems: number?,
	specialType:             string?,
	SpecialType:             string?,
	enabled:                 boolean?,
	Enabled:                 boolean?,
	layoutOrder:             number?,
	LayoutOrder:             number?,
	callback:                ((value: any) -> ())?,
	Callback:                ((value: any) -> ())?,
}

export type InputProps = {
	name:         string?,
	description:  string?,
	flag:         string?,
	value:        string?,
	placeholder:  string?,
	numeric:      boolean?,
	clearOnFocus: boolean?,
	enterOnly:    boolean?,
	callback:     ((value: string) -> ())?,
}

export type KeybindProps = {
	name:       string?,
	description: string?,
	flag:       string?,
	value:      (EnumItem | string)?,
	callback:   ((value: EnumItem) -> ())?,
	onChanged:  ((key: EnumItem) -> ())?,
}

export type ColorPickerProps = {
	name:     string?,
	flag:     string?,
	color:    Color3?,
	alpha:    number?,
	callback: ((value: Color3, alpha: number) -> ())?,
}

export type NotifyProps = {
	title:    string?,
	content:  string?,
	duration: number?,
}

-- ── Handle types ──────────────────────────────────────────────────────────────

export type Section = {
	Destroy: (self: Section) -> (),
}

export type Label = {
	Set:     (self: Label, text: string) -> (),
	Destroy: (self: Label) -> (),
}

export type Button = {
	Destroy: (self: Button) -> (),
}

export type Toggle = {
	value:   boolean,
	Set:     (self: Toggle, value: boolean, skipCallback: boolean?) -> (),
	Destroy: (self: Toggle) -> (),
}

export type Slider = {
	value:      number,
	Value:      number,
	Changed:    any,
	Set:        (self: Slider, value: number, skipCallback: boolean?) -> (),
	SetValue:   (self: Slider, value: number, skipCallback: boolean?) -> (),
	SetEnabled: (self: Slider, enabled: boolean) -> (),
	GetFrame:   (self: Slider) -> Frame,
	Destroy:    (self: Slider) -> (),
}

export type Dropdown = {
	value:      any,
	Value:      any,
	Changed:    any,
	Set:        (self: Dropdown, value: any, skipCallback: boolean?) -> (),
	SetValue:   (self: Dropdown, value: any, skipCallback: boolean?) -> (),
	SetOptions: (self: Dropdown, options: { any }) -> (),
	SetEnabled: (self: Dropdown, enabled: boolean) -> (),
	GetFrame:   (self: Dropdown) -> Frame,
	Destroy:    (self: Dropdown) -> (),
}

export type Input = {
	value:   string,
	Set:     (self: Input, value: string, skipCallback: boolean?) -> (),
	Destroy: (self: Input) -> (),
}

export type Keybind = {
	value:   EnumItem,
	Set:     (self: Keybind, value: EnumItem | string, skipChanged: boolean?) -> (),
	Destroy: (self: Keybind) -> (),
}

export type ColorPicker = {
	value:    Color3,
	alpha:    number,
	Set:      (self: ColorPicker, value: Color3, skipCallback: boolean?) -> (),
	SetAlpha: (self: ColorPicker, alpha: number, skipCallback: boolean?) -> (),
	Destroy:  (self: ColorPicker) -> (),
}

export type TabColumn = {
	CreateSection:     (self: TabColumn, props: SectionProps) -> Section,
	CreateLabel:       (self: TabColumn, props: LabelProps) -> Label,
	CreateButton:      (self: TabColumn, props: ButtonProps) -> Button,
	CreateToggle:      (self: TabColumn, props: ToggleProps) -> Toggle,
	CreateSlider:      (self: TabColumn, props: SliderProps) -> Slider,
	AddSlider:         (self: TabColumn, props: SliderProps) -> Slider,
	CreateInput:       (self: TabColumn, props: InputProps) -> Input,
	CreateKeybind:     (self: TabColumn, props: KeybindProps) -> Keybind,
	CreateDropdown:    (self: TabColumn, props: DropdownProps) -> Dropdown,
	AddDropdown:       (self: TabColumn, props: DropdownProps) -> Dropdown,
	CreateColorPicker: (self: TabColumn, props: ColorPickerProps) -> ColorPicker,
}

export type Tab = {
	Left:              TabColumn,
	Right:             TabColumn,

	CreateSection:     (self: Tab, props: SectionProps) -> Section,
	CreateLabel:       (self: Tab, props: LabelProps) -> Label,
	CreateButton:      (self: Tab, props: ButtonProps) -> Button,
	CreateToggle:      (self: Tab, props: ToggleProps) -> Toggle,
	CreateSlider:      (self: Tab, props: SliderProps) -> Slider,
	AddSlider:         (self: Tab, props: SliderProps) -> Slider,
	CreateInput:       (self: Tab, props: InputProps) -> Input,
	CreateKeybind:     (self: Tab, props: KeybindProps) -> Keybind,
	CreateDropdown:    (self: Tab, props: DropdownProps) -> Dropdown,
	AddDropdown:       (self: Tab, props: DropdownProps) -> Dropdown,
	CreateColorPicker: (self: Tab, props: ColorPickerProps) -> ColorPicker,

	CreateLeftSection:     (self: Tab, props: SectionProps) -> Section,
	CreateLeftLabel:       (self: Tab, props: LabelProps) -> Label,
	CreateLeftButton:      (self: Tab, props: ButtonProps) -> Button,
	CreateLeftToggle:      (self: Tab, props: ToggleProps) -> Toggle,
	CreateLeftSlider:      (self: Tab, props: SliderProps) -> Slider,
	CreateLeftInput:       (self: Tab, props: InputProps) -> Input,
	CreateLeftKeybind:     (self: Tab, props: KeybindProps) -> Keybind,
	CreateLeftDropdown:    (self: Tab, props: DropdownProps) -> Dropdown,
	CreateLeftColorPicker: (self: Tab, props: ColorPickerProps) -> ColorPicker,

	CreateRightSection:     (self: Tab, props: SectionProps) -> Section,
	CreateRightLabel:       (self: Tab, props: LabelProps) -> Label,
	CreateRightButton:      (self: Tab, props: ButtonProps) -> Button,
	CreateRightToggle:      (self: Tab, props: ToggleProps) -> Toggle,
	CreateRightSlider:      (self: Tab, props: SliderProps) -> Slider,
	CreateRightInput:       (self: Tab, props: InputProps) -> Input,
	CreateRightKeybind:     (self: Tab, props: KeybindProps) -> Keybind,
	CreateRightDropdown:    (self: Tab, props: DropdownProps) -> Dropdown,
	CreateRightColorPicker: (self: Tab, props: ColorPickerProps) -> ColorPicker,

	Show:    (self: Tab) -> (),
	Hide:    (self: Tab) -> (),
	Destroy: (self: Tab) -> (),
}

export type Window = {
	unloaded: boolean,

	CreateTab:      (self: Window, props: TabProps) -> Tab,
	Notify:         (self: Window, props: NotifyProps) -> (),
	Show:           (self: Window) -> (),
	Hide:           (self: Window) -> (),
	ToggleHide:     (self: Window) -> (),
	ToggleMinimise: (self: Window) -> (),
	ChangeTheme:    (self: Window, theme: Theme) -> (),
	Unload:         (self: Window) -> (),
}

export type Delirium = {
	Flags:         { [string]: any },
	Icons:         any,
	NebulaIcons:   any,
	MediaService:  any,
	SaveManager:   any,
	LoadingScreen: any,
	CreateWindow:  (self: Delirium, props: WindowProps) -> Window,
}

return {}
