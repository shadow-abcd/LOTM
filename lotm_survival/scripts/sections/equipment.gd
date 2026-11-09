extends "res://scripts/sections/base.gd"
## Loadout: equipped slots (artifacts / charms / mystical items), live stats, and the inventory grid.

const Loadout = preload("res://scripts/loadout.gd")
var cat = "artifacts"
var sel_id = ""

func _init() -> void:
	title = "Equipment"
	icon_name = "equipment"

static func entries(kind: String) -> Array:
	var out: Array = []
	if kind == "artifacts":
		for a in DB.artifacts:
			var painted = "res://assets/portraits/relic_%s.jpg" % a["id"]
			out.append({"id": a["id"], "name": a["name"], "glyph": a["glyph"], "rarity": a["rarity"], "painted": painted,
				"boon": a["boon"], "curse": a["curse"], "text": a["description"], "source": a.get("source", "")})
	elif kind == "charms":
		for c in DB.charms:
			out.append({"id": c["id"], "name": c["name"], "glyph": c["glyph"], "rarity": c["rarity"], "painted": "",
				"boon": c["description"], "curse": "Cooldown %ds" % int(c["cooldown"]), "text": "", "source": c.get("source", "")})
	else:
		for m in DB.mystical:
			out.append({"id": m["id"], "name": m["name"], "glyph": m["glyph"], "rarity": "Uncommon", "painted": "",
				"boon": m["description"], "curse": "", "text": "", "source": m.get("source", "")})
	return out

static func find_entry(kind: String, id: String) -> Dictionary:
	for e in entries(kind):
		if e["id"] == id:
			return e
	return {}

func build() -> void:
	# equipped slots
	var top = HBoxContainer.new()
	top.add_theme_constant_override("separation", 26)
	body.add_child(top)
	for kind in ["artifacts", "charms", "items"]:
		var col = VBoxContainer.new()
		col.add_child(UI.label({"artifacts": "Artifacts", "charms": "Charms", "items": "Mystical Items"}[kind], 16, UI.GOLD))
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var eq: Array = Store.equipped(kind)
		var limit = Store.slot_limit(kind)
		var total = 3 if kind == "artifacts" else (2 if kind == "charms" else 4)
		for i in range(total):
			if i < eq.size():
				var e = find_entry(kind, eq[i])
				var id: String = eq[i]
				row.add_child(UI.slot_button(DB.icon_for_glyph(str(e.get("glyph", ""))), str(e.get("rarity", "Common")), 68, Color.WHITE,
					func(): Store.unequip(kind, id), "Unequip %s" % e.get("name", id), str(e.get("painted", ""))))
			elif i < limit:
				row.add_child(UI.slot("plus", "empty", 68, Color(1, 1, 1, 0.25)))
			else:
				row.add_child(UI.slot("lock", "empty", 68, Color(1, 1, 1, 0.35)))
		col.add_child(row)
		top.add_child(col)
	# stats
	var stats = Loadout.compute(true)
	var sp = PanelContainer.new()
	sp.add_theme_stylebox_override("panel", UI.flat(Color("#120f19"), Color("#3a3046"), 1, 10, 10))
	var gc = GridContainer.new()
	gc.columns = 4
	gc.add_theme_constant_override("h_separation", 26)
	for ln in Loadout.lines(stats):
		var h = HBoxContainer.new()
		h.add_child(UI.icon_rect(ln[0], 22, UI.GOLD))
		h.add_child(UI.label(" " + ln[1], 15))
		gc.add_child(h)
	sp.add_child(gc)
	body.add_child(sp)
	# category tabs
	var tabs = HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 8)
	for t in [["artifacts", "Artifacts", "artifact"], ["charms", "Charms", "charm"], ["items", "Items", "compass"]]:
		var b = UI.button(" " + t[1], t[2], _set_cat.bind(t[0]), Vector2(170, 46))
		b.toggle_mode = true
		b.button_pressed = (cat == t[0])
		tabs.add_child(b)
	body.add_child(tabs)
	# grid
	var grid = GridContainer.new()
	grid.columns = 8
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	var eqc: Array = Store.equipped(cat)
	for e in entries(cat):
		var id: String = e["id"]
		var owned = Store.owns(cat, id)
		var on = id in eqc
		var tint = Color.WHITE if owned else Color(1, 1, 1, 0.25)
		var s = UI.slot_button("lock" if not owned else DB.icon_for_glyph(str(e["glyph"])), str(e["rarity"]) if owned else "empty", 72, tint,
			_pick.bind(id), str(e["name"]), str(e["painted"]) if owned else "")
		if on:
			var ck = UI.icon_rect("check", 24, UI.GOOD)
			ck.position = Vector2(46, 2)
			s.add_child(ck)
		grid.add_child(s)
	body.add_child(grid)
	# detail
	if sel_id != "":
		var e = find_entry(cat, sel_id)
		if not e.is_empty():
			var owned = Store.owns(cat, sel_id)
			var on = sel_id in eqc
			var lines: Array = []
			if str(e["text"]) != "":
				lines.append([str(e["text"]), UI.TEXT_DIM])
			if str(e["boon"]) != "":
				lines.append(["◆ " + str(e["boon"]), UI.GOOD])
			if str(e["curse"]) != "":
				lines.append(["◇ " + str(e["curse"]), UI.BAD])
			if str(e["source"]) != "":
				lines.append(["Found: " + str(e["source"]), UI.TEXT_DIM])
			var acts: Array = []
			var sid = sel_id
			if not owned:
				acts.append(act("Locked", "lock", Callable(), true))
			elif on:
				acts.append(act("Unequip", "close", func(): Store.unequip(cat, sid)))
			else:
				acts.append(act("Equip", "check", func(): Store.equip(cat, sid)))
			card(UI.slot(DB.icon_for_glyph(str(e["glyph"])), str(e["rarity"]), 84, Color.WHITE, str(e["painted"]) if owned else ""),
				str(e["name"]), str(e["rarity"]), UI.rarity_color(str(e["rarity"])), lines, acts)

func _set_cat(c: String) -> void:
	cat = c
	sel_id = ""
	_refresh()

func _pick(id: String) -> void:
	sel_id = id
	_refresh()
