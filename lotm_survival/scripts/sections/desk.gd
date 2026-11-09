extends "res://scripts/sections/base.gd"
## The Desk: permanent research, weekly field challenges, the level path 1-100, and the ledger.

const STEP_SEQ := {8: 8, 7: 16, 6: 26, 5: 38, 4: 50, 3: 62, 2: 76, 1: 90}

func _init() -> void:
	title = "The Desk — Research"
	icon_name = "desk"

func build() -> void:
	body.add_child(UI.label("Research (Coins)", 20, UI.GOLD, true))
	for id in Store.UPGRADES.keys():
		var u: Array = Store.UPGRADES[id]
		var rank = Store.upgrade_rank(id)
		var cost = Store.upgrade_cost(id)
		var maxed = rank >= 10
		var pips = ""
		for i in range(10):
			pips += "◆" if i < rank else "◇"
		var acts: Array = [act("MAX" if maxed else "%d ●" % cost, "plus", func(): _up(id, cost), maxed or Store.coins() < cost)]
		card(UI.slot(u[1], "rare", 64), u[0], "Rank %d/10" % rank, UI.GOLD, [[u[2], UI.TEXT_DIM], [pips, UI.GOLD]], acts)
	body.add_child(UI.label("Weekly field challenges", 20, UI.GOLD, true))
	var wk: Dictionary = Store.d["weekly"]
	if str(wk.get("week", "")) != Store.week_key():
		wk = {"week": Store.week_key(), "kills": 0, "best_seq": 9, "claimed": []}
		Store.d["weekly"] = wk
	for ch in DB.weekly:
		var cid: String = ch["id"]
		var done: bool = int(wk["kills"]) >= 50 if cid == "field_work" else (int(wk["kills"]) >= 150 and int(wk["best_seq"]) <= 2)
		var claimed: bool = cid in wk["claimed"]
		var acts2: Array = [act("Claimed" if claimed else "Claim", "gem" if not claimed else "check", func(): _claim(cid), claimed or not done)]
		card(UI.slot(DB.icon_for_glyph(str(ch["glyph"])), "epic", 64), str(ch["name"]), str(ch["reward"]), UI.GOLD,
			[[str(ch["description"]), UI.TEXT_DIM], ["Progress this week: %d kills · best Sequence %d" % [int(wk["kills"]), int(wk["best_seq"])], UI.GOLD_DIM]], acts2)
	_level_path()
	body.add_child(UI.label("Ledger", 20, UI.GOLD, true))
	body.add_child(UI.wrap_label("Descents: %d   ·   Victories: %d   ·   Enemies vanquished: %d   ·   Longest descent: %d:%02d   ·   Account level %d" % [
		int(Store.d["runs"]), int(Store.d["wins"]), int(Store.d["kills"]), int(float(Store.d["best_time"]) / 60.0), int(float(Store.d["best_time"])) % 60, Store.account_level()], 16))

## The Path of Levels 1-100: what happens at every step of a descent.
func _level_path() -> void:
	body.add_child(UI.label("The Path of Levels — 1 to 100", 20, UI.GOLD, true))
	body.add_child(UI.wrap_label("Every level: +2 max vitality, heal 4, +1% rite damage. Every 10th level is a milestone (full restore, +5% damage, +1 Diamond) and every 20th also grants a Fate reroll. Sequence gates arrive at the levels marked below.", 15))
	var grid = GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for lv in range(1, 101):
		grid.add_child(_level_chip(lv))
	body.add_child(grid)

func _level_note(lv: int) -> Array:
	var notes: Array = []
	for s in STEP_SEQ.keys():
		if lv == int(STEP_SEQ[s]):
			var gate: bool = s in DB.GATES
			notes.append(["Seq %d · %s%s" % [s, DB.title_for(Store.current_pathway(), s), " — BOSS GATE" if gate else ""], gate])
	if notes.is_empty():
		return []
	return notes

func _level_chip(lv: int) -> Control:
	var p = PanelContainer.new()
	p.add_theme_stylebox_override("panel", UI.flat(Color(" #17131f" if false else "#17131f"), Color("#3a3046"), 1, 8, 6))
	var v = VBoxContainer.new()
	v.add_theme_constant_override("separation", 1)
	var is_milestone: bool = lv % 10 == 0
	var is_reroll: bool = lv % 20 == 0
	var seq_notes: Array = _level_note(lv)
	var head_color = UI.TEXT_DIM
	var head_icon = "star"
	if not seq_notes.is_empty():
		head_color = Color("#c86ee0") if seq_notes[0][1] else UI.GOLD
		head_icon = "sword" if seq_notes[0][1] else "pathways"
	elif is_reroll:
		head_color = Color("#7fd68a")
		head_icon = "fate"
	elif is_milestone:
		head_color = UI.GOLD
		head_icon = "levelup"
	var h = HBoxContainer.new()
	h.add_theme_constant_override("separation", 4)
	h.add_child(UI.icon_rect(head_icon, 14, head_color))
	var t = UI.label("Lv %d" % lv, 14, head_color, true)
	h.add_child(t)
	v.add_child(h)
	if not seq_notes.is_empty():
		var n = UI.label(str(seq_notes[0][0]), 12, head_color)
		n.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		n.custom_minimum_size = Vector2(150, 0)
		v.add_child(n)
	elif is_reroll:
		v.add_child(UI.label("Milestone + Fate reroll", 12, Color("#7fd68a")))
	elif is_milestone:
		v.add_child(UI.label("Milestone: restore, +5% dmg, +1 ◆", 12, UI.GOLD))
	else:
		v.add_child(UI.label("+2 vitality · heal 4 · +1% dmg", 12, UI.TEXT_DIM))
	p.add_child(v)
	return p

func _up(id: String, cost: int) -> void:
	if Store.spend("coins", cost):
		Store.d["upgrades"][id] = Store.upgrade_rank(id) + 1
		Store.commit()
		Sound.play_sfx("levelup", -6.0)

func _claim(cid: String) -> void:
	var wk: Dictionary = Store.d["weekly"]
	if cid in wk["claimed"]:
		return
	wk["claimed"].append(cid)
	if cid == "field_work":
		Store.earn("diamonds", 2)
	else:
		Store.d["characteristics"] = int(Store.d["characteristics"]) + 1
	Store.commit()
	Sound.play_sfx("unlock")
