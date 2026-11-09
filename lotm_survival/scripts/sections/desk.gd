extends "res://scripts/sections/base.gd"
## The Desk: permanent research, weekly field challenges, and the ledger of your descents.

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
	body.add_child(UI.label("Ledger", 20, UI.GOLD, true))
	body.add_child(UI.wrap_label("Descents: %d   ·   Victories: %d   ·   Enemies vanquished: %d   ·   Longest descent: %d:%02d   ·   Account level %d" % [
		int(Store.d["runs"]), int(Store.d["wins"]), int(Store.d["kills"]), int(float(Store.d["best_time"]) / 60.0), int(float(Store.d["best_time"])) % 60, Store.account_level()], 16))

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
