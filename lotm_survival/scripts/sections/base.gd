extends VBoxContainer
## Base for every Study section. Subclasses set `title` / `icon_name` and override build().

var title = ""
var icon_name = "study"
var body: VBoxContainer

func _ready() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 6)
	add_child(UI.header(title, icon_name))
	body = VBoxContainer.new()
	body.add_theme_constant_override("separation", 10)
	add_child(UI.scroll(body))
	Store.changed.connect(_refresh)
	_refresh()

func _refresh() -> void:
	if body == null:
		return
	UI.clear(body)
	build()

func build() -> void:
	pass

## A horizontal card: slot on the left, text in the middle, actions on the right.
func card(slot_ctrl: Control, head: String, sub: String, sub_color: Color, lines: Array, actions: Array) -> PanelContainer:
	var p = PanelContainer.new()
	p.add_theme_stylebox_override("panel", UI.flat(Color("#17131f"), Color("#3a3046"), 1, 10, 10))
	var h = HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	p.add_child(h)
	if slot_ctrl != null:
		h.add_child(slot_ctrl)
	var col = VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 2)
	var hr = HBoxContainer.new()
	hr.add_theme_constant_override("separation", 10)
	hr.add_child(UI.label(head, 20, UI.TEXT, true))
	if sub != "":
		hr.add_child(UI.pill(sub, sub_color))
	col.add_child(hr)
	for ln in lines:
		col.add_child(UI.wrap_label(ln[0], 15, ln[1]))
	h.add_child(col)
	if actions.size() > 0:
		var av = VBoxContainer.new()
		av.alignment = BoxContainer.ALIGNMENT_CENTER
		av.add_theme_constant_override("separation", 6)
		for a in actions:
			av.add_child(a)
		h.add_child(av)
	body.add_child(p)
	return p

func act(text: String, icon_name_: String, cb: Callable, disabled: bool = false) -> Button:
	var b = UI.button(text, icon_name_, cb, Vector2(150, 44))
	b.disabled = disabled
	return b

func money(coins_cost: int, diamonds_cost: int = 0) -> String:
	if diamonds_cost > 0:
		return "%d ◆" % diamonds_cost
	return "%d ●" % coins_cost
