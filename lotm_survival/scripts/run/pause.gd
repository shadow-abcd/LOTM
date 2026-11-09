extends Control
## Pause menu: Resume, Equipment overview, Settings, Abandon.

const Loadout = preload("res://scripts/loadout.gd")
var run = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var scrim = ColorRect.new()
	scrim.color = Color(0, 0, 0, 0.7)
	scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scrim)
	var c = CenterContainer.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(c)
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(760, 0)
	c.add_child(panel)
	var h = HBoxContainer.new()
	h.add_theme_constant_override("separation", 26)
	panel.add_child(h)
	var left = VBoxContainer.new()
	left.add_theme_constant_override("separation", 10)
	left.add_child(UI.header("Paused", "pause"))
	left.add_child(UI.button("  Resume", "play", _resume, Vector2(260, 56)))
	left.add_child(UI.button("  Settings", "settings", _settings, Vector2(260, 52)))
	left.add_child(UI.button("  Abandon descent", "home", _abandon, Vector2(260, 52)))
	h.add_child(left)
	var right = VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 6)
	right.add_child(UI.label("Equipment", 20, UI.GOLD, true))
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	for id in Store.equipped("artifacts"):
		var a = DB.artifact(str(id))
		row.add_child(UI.slot(DB.icon_for_glyph(str(a.get("glyph", ""))), str(a.get("rarity", "Common")), 52))
	for id in Store.equipped("charms"):
		var ch = DB.charm(str(id))
		row.add_child(UI.slot(DB.icon_for_glyph(str(ch.get("glyph", ""))), str(ch.get("rarity", "Common")), 52))
	for id in Store.equipped("items"):
		var it = DB.item(str(id))
		row.add_child(UI.slot(DB.icon_for_glyph(str(it.get("glyph", ""))), "uncommon", 52))
	right.add_child(row)
	right.add_child(UI.label("Abilities", 20, UI.GOLD, true))
	for a in run.abilities:
		right.add_child(UI.label("%s  Lv %d  ·  %s" % [a["name"], int(a["level"]), str(a["kind"]).to_upper()], 15))
	right.add_child(UI.label("Stats", 20, UI.GOLD, true))
	var gc = GridContainer.new()
	gc.columns = 2
	gc.add_theme_constant_override("h_separation", 18)
	for ln in Loadout.lines(run.stats):
		gc.add_child(UI.label(ln[1], 14, UI.TEXT_DIM))
	right.add_child(gc)
	h.add_child(right)
	Sound.play_sfx("ui_open")

func _resume() -> void:
	run.paused_menu = false
	get_tree().paused = false
	Sound.play_sfx("ui_back")
	queue_free()

func _settings() -> void:
	var S = load("res://scripts/screens/settings_menu.gd")
	add_child(S.new())

func _abandon() -> void:
	get_tree().paused = false
	run._end(false)
	queue_free()

func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		_resume()
