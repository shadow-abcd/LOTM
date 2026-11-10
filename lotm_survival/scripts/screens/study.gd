extends Control
## The Study: the safe house hub. A sidebar of icon tabs — one separate section per tab.

const SECTIONS := [
	["pathways", "Pathways", "pathways", "res://scripts/sections/pathways.gd"],
	["equipment", "Equipment", "equipment", "res://scripts/sections/equipment.gd"],
	["rack", "Rack", "rack", "res://scripts/sections/rack.gd"],
	["shelf", "Shelf", "shelf", "res://scripts/sections/shelf.gd"],
	["desk", "Desk", "desk", "res://scripts/sections/desk.gd"],
	["levels", "Levels", "levelup", "res://scripts/sections/levels.gd"],
	["chronicle", "Chronicle", "codex", "res://scripts/sections/chronicle.gd"],
	["grimoire", "Grimoire", "grimoire", "res://scripts/sections/grimoire.gd"],
	["cabinet", "Cabinet", "cabinet", "res://scripts/sections/cabinet.gd"],
	["ascent", "Ascent", "star", "res://scripts/sections/ascent.gd"],
	["altar", "Altar", "altar", "res://scripts/sections/altar.gd"],
	["auction", "Auction", "auction", "res://scripts/sections/auction.gd"],
	["bestiary", "Bestiary", "bestiary", "res://scripts/sections/bestiary.gd"],
	["places", "Places", "map", "res://scripts/sections/places.gd"],
]
static var last_tab = "equipment"

var _content: Control
var _tab_btns: Dictionary = {}
var _coin_lbl: Label
var _dia_lbl: Label
var _path_lbl: Label
var _section: Control = null

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	Sound.play_music("study_theme")
	Sound.stop_ambience()
	var bg = TextureRect.new()
	bg.texture = UI.tex("res://assets/textures/study_room.jpg")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.modulate = Color(0.32, 0.3, 0.36)
	add_child(bg)
	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for s in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + s, 18)
	add_child(margin)
	var root = VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	margin.add_child(root)

	# top bar
	var top = HBoxContainer.new()
	top.add_theme_constant_override("separation", 14)
	top.add_child(UI.icon_button("home", "Title", func(): UI.goto("title"), 52))
	top.add_child(UI.icon_rect("study", 36, UI.GOLD))
	top.add_child(UI.label("THE STUDY", 28, UI.GOLD, true))
	_path_lbl = UI.label("", 18, UI.TEXT_DIM)
	top.add_child(_path_lbl)
	var sp = Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(sp)
	top.add_child(UI.icon_rect("coin", 30, Color("#e8c060")))
	_coin_lbl = UI.label("0", 20, Color("#e8c060"), true)
	top.add_child(_coin_lbl)
	top.add_child(UI.icon_rect("diamond", 30, Color("#7fd8f0")))
	_dia_lbl = UI.label("0", 20, Color("#7fd8f0"), true)
	top.add_child(_dia_lbl)
	top.add_child(UI.icon_button("settings", "Settings", _open_settings, 52))
	top.add_child(UI.button("  Descend", "play", _descend, Vector2(190, 52)))
	root.add_child(top)

	var mid = HBoxContainer.new()
	mid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mid.add_theme_constant_override("separation", 12)
	root.add_child(mid)
	# sidebar
	var side_panel = PanelContainer.new()
	side_panel.add_theme_stylebox_override("panel", UI.flat(Color("#100d16"), Color("#3a3046"), 2, 12, 6))
	var side = VBoxContainer.new()
	side.add_theme_constant_override("separation", 4)
	side_panel.add_child(side)
	for s in SECTIONS:
		var b = Button.new()
		b.text = "  " + s[1]
		b.icon = UI.icon(s[2])
		b.expand_icon = true
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.toggle_mode = true
		b.custom_minimum_size = Vector2(172, 46)
		b.tooltip_text = s[1]
		b.mouse_entered.connect(func(): Sound.play_sfx("ui_hover", -8.0))
		b.pressed.connect(_select.bind(s[0]))
		side.add_child(b)
		_tab_btns[s[0]] = b
	mid.add_child(side_panel)
	_content = PanelContainer.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mid.add_child(_content)
	Store.changed.connect(_update_bar)
	_update_bar()
	_select(last_tab)

## Chronicle: "Play double agent" — both shops answer to you, but every descent is paid for.
func _descend() -> void:
	var entry := int(Store.d.get("run_entry_cost", 0))
	if entry > 0:
		if not Store.spend("coins", entry):
			UI.toast("The factions want %d Coins before you descend. You cannot pay." % entry, "coin")
			return
		UI.toast("Entry tithe paid: %d Coins. Both factions watch you descend." % entry, "eye")
	UI.goto("run")

func _update_bar() -> void:
	_coin_lbl.text = str(Store.coins())
	_dia_lbl.text = str(Store.diamonds())
	var p = DB.pathway(Store.current_pathway())
	_path_lbl.text = "· %s · Account Lv %d/100 (%s)" % [p.get("name", "?"), Store.account_level(), "forbids lifted" if Cfg.gate_open() else "forbids active"]

func _select(id: String) -> void:
	Sound.play_sfx("ui_open", -6.0)
	last_tab = id
	for k in _tab_btns.keys():
		_tab_btns[k].button_pressed = (k == id)
	if _section != null:
		_content.remove_child(_section)
		_section.queue_free()
	for s in SECTIONS:
		if s[0] == id:
			var scr = load(s[3])
			_section = scr.new()
			_content.add_child(_section)

func _open_settings() -> void:
	var S = load("res://scripts/screens/settings_menu.gd")
	add_child(S.new())
