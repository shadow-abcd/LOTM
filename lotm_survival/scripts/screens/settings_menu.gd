extends Control
## Settings overlay. Five separate sections: Audio, Graphics, Controls, Gameplay, Accessibility.

const TABS := [
	["audio", "Audio", "audio"], ["graphics", "Graphics", "graphics"], ["controls", "Controls", "controls"],
	["gameplay", "Gameplay", "gameplay"], ["access", "Accessibility", "accessibility"],
]
var _body: VBoxContainer
var _tab_buttons: Dictionary = {}
var _cur = "audio"
var _waiting = ""
var _wait_btn: Button = null
var _erase_armed = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var scrim = ColorRect.new()
	scrim.color = Color(0, 0, 0, 0.72)
	scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scrim)
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(900, 560)
	center.add_child(panel)
	var outer = VBoxContainer.new()
	outer.add_theme_constant_override("separation", 8)
	panel.add_child(outer)
	var top = HBoxContainer.new()
	var hd = UI.header("Settings", "settings")
	hd.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(hd)
	top.add_child(UI.icon_button("close", "Close", close, 48))
	outer.add_child(top)
	var mid = HBoxContainer.new()
	mid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mid.add_theme_constant_override("separation", 16)
	outer.add_child(mid)
	var side = VBoxContainer.new()
	side.add_theme_constant_override("separation", 8)
	mid.add_child(side)
	for t in TABS:
		var b = UI.button(" " + t[1], t[2], _select.bind(t[0]), Vector2(190, 52))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.toggle_mode = true
		side.add_child(b)
		_tab_buttons[t[0]] = b
	var sp = Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	side.add_child(sp)
	side.add_child(UI.button(" Defaults", "reset", _reset, Vector2(190, 48)))
	_body = VBoxContainer.new()
	_body.add_theme_constant_override("separation", 10)
	mid.add_child(UI.scroll(_body))
	_select("audio")
	Sound.play_sfx("ui_open")

func close() -> void:
	Sound.play_sfx("ui_back")
	queue_free()

func _reset() -> void:
	Cfg.reset_defaults()
	_select(_cur)

func _select(tab: String) -> void:
	_cur = tab
	for k in _tab_buttons.keys():
		_tab_buttons[k].button_pressed = (k == tab)
	UI.clear(_body)
	_erase_armed = false
	match tab:
		"audio": _audio()
		"graphics": _graphics()
		"controls": _controls()
		"gameplay": _gameplay()
		"access": _access()

func _row(icon_name: String, text: String, ctrl: Control, hint: String = "") -> void:
	var h = HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	h.custom_minimum_size = Vector2(0, 44)
	h.add_child(UI.icon_rect(icon_name, 30, UI.GOLD))
	var col = VBoxContainer.new()
	col.custom_minimum_size = Vector2(210, 0)
	col.add_child(UI.label(text, 18))
	if hint != "":
		col.add_child(UI.label(hint, 12, UI.TEXT_DIM))
	h.add_child(col)
	ctrl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(ctrl)
	_body.add_child(h)

func _section(title: String) -> void:
	_body.add_child(UI.label(title, 20, UI.GOLD, true))

func _audio() -> void:
	_section("Volume")
	_row("audio", "Master", UI.slider(float(Cfg.get_v("master")), func(v): Cfg.set_v("master", v)))
	_row("music", "Music", UI.slider(float(Cfg.get_v("music")), func(v): Cfg.set_v("music", v)))
	_row("sfx", "Effects", UI.slider(float(Cfg.get_v("sfx")), func(v): Cfg.set_v("sfx", v)))
	_row("map", "Ambience", UI.slider(float(Cfg.get_v("ambience")), func(v): Cfg.set_v("ambience", v)))
	_body.add_child(UI.button(" Test sound", "play", func(): Sound.play_sfx("levelup"), Vector2(200, 46)))

func _graphics() -> void:
	_section("Display")
	_row("fullscreen", "Fullscreen", UI.toggle("", "", bool(Cfg.get_v("fullscreen")), func(on): Cfg.set_v("fullscreen", on)))
	_row("timer", "V-Sync", UI.toggle("", "", bool(Cfg.get_v("vsync")), func(on): Cfg.set_v("vsync", on)))
	_row("info", "Show FPS", UI.toggle("", "", bool(Cfg.get_v("show_fps")), func(on): Cfg.set_v("show_fps", on)))
	_row("graphics", "UI scale", UI.slider(float(Cfg.get_v("ui_scale")), func(v): Cfg.set_v("ui_scale", v), 0.75, 1.5, 0.05))
	_section("Performance")
	_row("bolt", "Performance mode", UI.toggle("", "", bool(Cfg.get_v("performance_mode")), func(on): Cfg.apply_performance_mode(on)), "Caps the crowd, halts damage numbers, softens shake — for weaker phones")
	_section("Effects")
	var opt = OptionButton.new()
	for n in ["Low", "Medium", "High"]:
		opt.add_item(n)
	opt.selected = int(Cfg.get_v("particles"))
	opt.item_selected.connect(func(i): Cfg.set_v("particles", i))
	_row("effects", "Particles", opt, "Lower for weaker phones")
	_row("shake", "Screen shake", UI.slider(float(Cfg.get_v("screen_shake")), func(v): Cfg.set_v("screen_shake", v), 0.0, 1.5, 0.05))
	_row("skull", "Damage numbers", UI.toggle("", "", bool(Cfg.get_v("damage_numbers")), func(on): Cfg.set_v("damage_numbers", on)))

func _controls() -> void:
	_section("Devices")
	_row("joystick", "Touch controls", UI.toggle("", "", bool(Cfg.get_v("touch_controls")), func(on): Cfg.set_v("touch_controls", on)), "On-screen stick and buttons")
	_row("vibration", "Vibration", UI.toggle("", "", bool(Cfg.get_v("vibration")), func(on): Cfg.set_v("vibration", on)))
	_section("Keyboard — click a key to rebind")
	for a in Cfg.ACTIONS.keys():
		var b = Button.new()
		b.text = Cfg.key_name(a)
		b.custom_minimum_size = Vector2(150, 40)
		b.pressed.connect(_begin_rebind.bind(a, b))
		_row(Cfg.ACTIONS[a][1], Cfg.ACTIONS[a][0], b)

func _begin_rebind(action: String, b: Button) -> void:
	_waiting = action
	_wait_btn = b
	b.text = "press a key…"

func _input(e: InputEvent) -> void:
	if _waiting != "" and e is InputEventKey and e.pressed and not e.echo:
		get_viewport().set_input_as_handled()
		if e.physical_keycode != KEY_ESCAPE:
			Cfg.rebind(_waiting, e.physical_keycode)
			Sound.play_sfx("ui_confirm")
			_waiting = ""
			_select("controls")
	elif e.is_action_pressed("pause") and _waiting == "":
		get_viewport().set_input_as_handled()
		close()

func _gameplay() -> void:
	_section("The Forbids")
	_row("unlock", "Lift the Forbids", UI.toggle("", "", bool(Cfg.get_v("open_gates")), func(on): Cfg.set_v("open_gates", on); _select("gameplay")),
		"Opens every lock: Formula gates, pathways, slots, Places")
	var info = UI.wrap_label("ON — Sequence gates never block a descent, every pathway, artifact and charm is open to equip.\nOFF — the original rules: a gate needs its Formula found AND its potion brewed, and unlocks cost Diamonds and Coins.", 14)
	_body.add_child(info)
	_section("Difficulty")
	var opt = OptionButton.new()
	for n in ["Calm", "Normal", "Haunting"]:
		opt.add_item(n)
	opt.selected = int(Cfg.get_v("difficulty"))
	opt.item_selected.connect(func(i): Cfg.set_v("difficulty", i))
	_row("difficulty", "Difficulty", opt)
	_row("pause", "Pause when unfocused", UI.toggle("", "", bool(Cfg.get_v("pause_on_focus_loss")), func(on): Cfg.set_v("pause_on_focus_loss", on)))
	_section("Save data")
	var erase_btn = UI.button(" Erase save", "reset", _erase, Vector2(0, 46))
	if _erase_armed:
		erase_btn.text = " Tap again to erase everything"
		erase_btn.add_theme_color_override("font_color", Color("#e0705a"))
	elif Input.is_key_pressed(KEY_SHIFT):
		erase_btn.text = " Erase save (shift held — will erase)"
	_body.add_child(erase_btn)
	_body.add_child(UI.wrap_label("Tap once to arm, twice to erase. On a keyboard you may hold Shift instead of the first tap.", 12, UI.TEXT_DIM))

func _erase() -> void:
	if not _erase_armed and not Input.is_key_pressed(KEY_SHIFT):
		_erase_armed = true
		Sound.play_sfx("ui_error")
		_select("gameplay")
		return
	_erase_armed = false
	Store.wipe()
	UI.toast("Save erased", "reset")

func _access() -> void:
	_section("Readability")
	_row("accessibility", "Larger text", UI.toggle("", "", bool(Cfg.get_v("big_text")), func(on): Cfg.set_v("big_text", on)))
	_row("eye", "High contrast", UI.toggle("", "", bool(Cfg.get_v("high_contrast")), func(on): Cfg.set_v("high_contrast", on)), "Brighter enemy outlines in the field")
	_row("gem", "Colour-blind marks", UI.toggle("", "", bool(Cfg.get_v("colorblind")), func(on): Cfg.set_v("colorblind", on)), "Adds shapes to elite and marked enemies")
	_section("Comfort")
	_row("storm", "Reduce flashes", UI.toggle("", "", bool(Cfg.get_v("reduce_flashes")), func(on): Cfg.set_v("reduce_flashes", on)), "Softens screen flashes and strobing")
	_row("shake", "Screen shake", UI.slider(float(Cfg.get_v("screen_shake")), func(v): Cfg.set_v("screen_shake", v), 0.0, 1.5, 0.05))
