extends Control
## Level-up draft: choose one rite. Keys 1–4 or tap a card. Fate rerolls shuffle the offer.

var run = null
var _opts: Array = []
var _row: HBoxContainer
var _reroll_btn: Button

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var scrim = ColorRect.new()
	scrim.color = Color(0, 0, 0, 0.66)
	scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scrim)
	var c = CenterContainer.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(c)
	var v = VBoxContainer.new()
	v.add_theme_constant_override("separation", 16)
	c.add_child(v)
	v.add_child(UI.label("Level %d / %d — choose a rite" % [run.level, run.MAX_LEVEL], 34, UI.GOLD, true, HORIZONTAL_ALIGNMENT_CENTER))
	v.add_child(UI.divider())
	_row = HBoxContainer.new()
	_row.add_theme_constant_override("separation", 16)
	_row.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(_row)
	_reroll_btn = UI.button("  Fate reroll", "fate", _reroll, Vector2(240, 52))
	var hb = HBoxContainer.new()
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.add_child(_reroll_btn)
	v.add_child(hb)
	_roll()

func _roll() -> void:
	_opts = run.draft_options()
	UI.clear(_row)
	for i in _opts.size():
		_row.add_child(_card(i, _opts[i]))
	_reroll_btn.text = "  Fate reroll ×%d" % run.rerolls
	_reroll_btn.disabled = run.rerolls <= 0

func _card(i: int, o: Dictionary) -> Control:
	var tag = {"new": "NEW ABILITY", "up": "UPGRADE", "rite": "RITE"}[o["type"]]
	var tag_col = {"new": UI.GOOD, "up": UI.GOLD, "rite": Color("#9ab4e0")}[o["type"]]
	var b = Button.new()
	b.custom_minimum_size = Vector2(230, 300)
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
	v.add_child(UI.label("[%d]" % (i + 1), 14, UI.TEXT_DIM, false, HORIZONTAL_ALIGNMENT_CENTER))
	var ic = UI.slot(str(o["icon"]), "mythic" if o["type"] == "new" else ("rare" if o["type"] == "up" else "common"), 84)
	var cc = CenterContainer.new()
	cc.add_child(ic)
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(cc)
	v.add_child(UI.label(str(o["name"]), 19, UI.TEXT, true, HORIZONTAL_ALIGNMENT_CENTER))
	v.add_child(UI.label(tag, 12, tag_col, true, HORIZONTAL_ALIGNMENT_CENTER))
	var d = UI.wrap_label(str(o["desc"]), 14, UI.TEXT_DIM)
	d.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	d.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(d)
	b.add_child(v)
	return b

func _pick(i: int) -> void:
	if i >= _opts.size():
		return
	Sound.play_sfx("ui_confirm")
	run.choose(_opts[i])
	queue_free()

func _reroll() -> void:
	if run.end_draft_reroll():
		_roll()

func _unhandled_input(e: InputEvent) -> void:
	for i in 4:
		if e.is_action_pressed("draft_%d" % (i + 1)) and i < _opts.size():
			get_viewport().set_input_as_handled()
			_pick(i)
			return
