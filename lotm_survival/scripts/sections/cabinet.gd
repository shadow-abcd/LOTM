extends "res://scripts/sections/base.gd"
## The Cabinet: Beyonder Characteristics (+1 Star on an ability) and the reagent inventory.

func _init() -> void:
	title = "The Cabinet — Characteristics & Reagents"
	icon_name = "cabinet"

func build() -> void:
	var cur = Store.current_pathway()
	var n = int(Store.d["characteristics"])
	body.add_child(UI.label("Beyonder Characteristics in your pouch: %d" % n, 20, UI.GOLD, true))
	body.add_child(UI.wrap_label("Sacrifice one Characteristic to give any ability +1 Star. Each ability accepts a single Characteristic, ever, and never beyond ★5. It replaces the next unearned milestone only; later Stars still have to be earned.", 15))
	for p in DB.pathways:
		var pid: String = p["id"]
		var rows: Array = []
		for a in DB.abilities_of(pid):
			var st = Store.ab_stat(pid, str(a["id"]))
			var used = int(st["casts"]) > 0 or float(st["damage"]) > 0.0 or Store.char_used(pid, str(a["id"]))
			if pid == cur or used:
				rows.append(a)
		if rows.is_empty():
			continue
		body.add_child(UI.label("%s %s" % [p["roman"], p["name"]], 18, Color(str(p["color"])), true))
		for a in rows:
			_ability_card(pid, a)
	body.add_child(UI.label("Ritual Reagents", 20, UI.GOLD, true))
	var grid = GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 8)
	for r in DB.reagents:
		var cnt = Store.reagent_count(str(r["id"]))
		var h = HBoxContainer.new()
		h.add_theme_constant_override("separation", 8)
		h.add_child(UI.slot(DB.icon_for_glyph(str(r["glyph"])), str(r["tier"]), 48, Color.WHITE if cnt > 0 else Color(1, 1, 1, 0.3)))
		var v = VBoxContainer.new()
		v.add_child(UI.label(str(r["name"]), 15, UI.TEXT if cnt > 0 else UI.TEXT_DIM))
		v.add_child(UI.label("×%d · %s" % [cnt, r["tier"]], 12, UI.rarity_color(str(r["tier"]))))
		h.add_child(v)
		grid.add_child(h)
	body.add_child(grid)

func _ability_card(pid: String, a: Dictionary) -> void:
	var aid: String = a["id"]
	var stars = Store.star_of(pid, aid)
	var pips = ""
	for i in range(5):
		pips += "★ " if i < stars else "☆ "
	var used = Store.char_used(pid, aid)
	var can = Store.can_apply_characteristic(pid, aid)
	var lines: Array = [[str(a["desc"]), UI.TEXT_DIM], [pips.strip_edges() + ("   (Characteristic applied)" if used else ""), UI.GOLD], [Store.next_milestone_text(pid, aid), UI.GOLD_DIM]]
	if can:
		lines.append(["%s: ★%d → ★%d (%s)" % [a["name"], stars, stars + 1, Store.skip_text(pid, aid)], UI.GOOD])
	var btn = act("Apply", "star", func(): _apply(pid, aid), not can)
	if not can:
		btn.tooltip_text = "Capacity reached." if (used or stars >= 5) else "No Characteristic in your pouch."
	card(UI.slot(_icon_for(a["kind"]), "epic" if stars > 0 else "common", 56), str(a["name"]), str(a["kind"]).to_upper(), UI.GOLD_DIM, lines, [btn])

static func _icon_for(kind: String) -> String:
	match kind:
		"shot": return "sword"
		"aura": return "flame"
		"pulse": return "sigil"
		"sigil": return "sigil"
		"orbit": return "orbit"
		"chain": return "storm"
		"mirror": return "shield"
		"marionette": return "thread"
		"reveal": return "eye"
		"dash": return "dash"
		"fork": return "pathways"
		"clones": return "moon"
		"fate": return "fate"
		"sleep": return "moon"
		"flame_wave": return "flame"
		"starfall": return "star"
		"mirror_world": return "moon"
		_: return "star"

func _apply(pid: String, aid: String) -> void:
	if Store.apply_characteristic(pid, aid):
		Sound.play_sfx("levelup", -4.0)
		UI.toast("Characteristic consumed: ★%d" % Store.star_of(pid, aid), "star")
