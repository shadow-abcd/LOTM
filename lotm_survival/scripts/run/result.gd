extends Control
## End-of-descent summary with rewards.

var run = null
var won = false
var total_coins = 0
var total_dia = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var scrim = ColorRect.new()
	scrim.color = Color(0, 0, 0, 0.78)
	scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scrim)
	var c = CenterContainer.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(c)
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(620, 0)
	c.add_child(panel)
	var v = VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	panel.add_child(v)
	var title = "ASCENDED" if won else "THE DESCENT ENDS"
	var sub = ("You answered the Pathway and kept your name." if won else "The Place remembers you. You will return.")
	v.add_child(UI.label(title, 44, UI.GOLD if won else Color("#c8483c"), true, HORIZONTAL_ALIGNMENT_CENTER))
	v.add_child(UI.label(sub, 16, UI.TEXT_DIM, false, HORIZONTAL_ALIGNMENT_CENTER))
	v.add_child(UI.divider())
	var g = GridContainer.new()
	g.columns = 2
	g.add_theme_constant_override("h_separation", 40)
	g.add_theme_constant_override("v_separation", 8)
	var rows = [
		["timer", "Time survived", "%d:%02d" % [int(run.time / 60.0), int(run.time) % 60]],
		["skull", "Enemies vanquished", str(run.kills)],
		["levelup", "Level reached", "%d / %d" % [run.level, run.MAX_LEVEL]],
		["pathways", "Sequence", "%d — %s" % [run.seq, DB.title_for(run.pid, run.seq)]],
		["crown", "Gates passed", str(run.bosses_down)],
		["coin", "Coins earned", "+%d" % total_coins],
		["diamond", "Diamonds earned", "+%d" % total_dia],
		["scroll", "Formulas found", str(run.formulas_found.size())],
	]
	for r in rows:
		var h = HBoxContainer.new()
		h.add_theme_constant_override("separation", 8)
		h.add_child(UI.icon_rect(r[0], 26, UI.GOLD))
		h.add_child(UI.label(r[1], 17))
		g.add_child(h)
		g.add_child(UI.label(r[2], 18, UI.TEXT, true, HORIZONTAL_ALIGNMENT_RIGHT))
	v.add_child(g)
	var rg = ""
	for k in run.reagents_found.keys():
		rg += "%s ×%d   " % [DB.reagent(k).get("name", k), int(run.reagents_found[k])]
	if rg != "":
		v.add_child(UI.wrap_label("Reagents: " + rg, 15, UI.TEXT_DIM))
	if run.star_gains.size() > 0:
		var sg = ""
		for st in run.star_gains:
			sg += "%s ★%d → ★%d   " % [st["name"], int(st["from"]), int(st["to"])]
		v.add_child(UI.wrap_label("New Stars: " + sg, 16, UI.GOLD))
	if run.items_found.size() > 0:
		v.add_child(UI.wrap_label("Vault: " + ", ".join(PackedStringArray(run.items_found)), 15, UI.GOOD))
	v.add_child(UI.divider())
	var b = HBoxContainer.new()
	b.alignment = BoxContainer.ALIGNMENT_CENTER
	b.add_theme_constant_override("separation", 14)
	b.add_child(UI.button("  The Study", "study", func(): UI.goto("study"), Vector2(220, 56)))
	b.add_child(UI.button("  Descend again", "play", func(): UI.goto("run"), Vector2(240, 56)))
	v.add_child(b)
