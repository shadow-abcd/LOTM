extends Control
## Phase D: offered when a descent crosses Sequence 8 / 5 / 2. Choose one rite that
## reshapes this descent and, later, the account. Mirrors the draft overlay's look.

var run = null
var _opts: Array = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var scrim = ColorRect.new()
	scrim.color = Color(0.02, 0.0, 0.05, 0.78)
	scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scrim)
	var c = CenterContainer.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(c)
	var v = VBoxContainer.new()
	v.add_theme_constant_override("separation", 16)
	c.add_child(v)
	v.add_child(UI.label("Sequence %d — the Pathway asks a price" % run.seq, 30, UI.GOLD, true, HORIZONTAL_ALIGNMENT_CENTER))
	v.add_child(UI.wrap_label("Crossing a Sequence bends the Pathway's rules. Choose the vow you can keep.", 16, UI.TEXT_DIM, HORIZONTAL_ALIGNMENT_CENTER))
	v.add_child(UI.divider())
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(row)
	_opts = DB.sequence_rites(run.pid, run.seq)
	for i in _opts.size():
		row.add_child(_card(i, _opts[i]))

func _card(i: int, o: Dictionary) -> Control:
	var b = Button.new()
	b.custom_minimum_size = Vector2(300, 320)
	b.pressed.connect(_pick.bind(i))
	b.mouse_entered.connect(func(): Sound.play_sfx("ui_hover", -8.0))
	var v = VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 12
	v.offset_right = -12
	v.offset_top = 12
	v.offset_bottom = -12
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 8)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var cc = CenterContainer.new()
	cc.add_child(UI.slot(str(o["icon"]), "mythic", 84))
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(cc)
	v.add_child(UI.label(str(o["name"]), 20, UI.GOLD, true, HORIZONTAL_ALIGNMENT_CENTER))
	var d = UI.wrap_label(str(o["desc"]), 15, UI.TEXT_DIM)
	d.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	d.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(d)
	var h = UI.wrap_label(str(o["hint"]), 13, Color("#9ab4e0"))
	h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(h)
	b.add_child(v)
	return b

func _pick(i: int) -> void:
	if i >= _opts.size():
		return
	Sound.play_sfx("ui_confirm")
	run.apply_sequence_rite(_opts[i])
	queue_free()

func _unhandled_input(e: InputEvent) -> void:
	for i in 3:
		if e.is_action_pressed("draft_%d" % (i + 1)) and i < _opts.size():
			get_viewport().set_input_as_handled()
			_pick(i)
			return
