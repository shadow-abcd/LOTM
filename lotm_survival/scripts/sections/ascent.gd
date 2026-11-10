extends "res://scripts/sections/base.gd"
## The Ascent: Phase D progression — mastery trees per pathway, lifetime tiers,
## and the Ascended descent toggle (once a Sequence 0 victory has been achieved).

func _init() -> void:
	title = "The Ascent — Mastery"
	icon_name = "star"

func build() -> void:
	var pid = Store.current_pathway()
	var m: Dictionary = DB.mastery(pid)
	var tier := DB.mastery_tier(pid, int(Store.d["kills"]))
	var kills: int = int(Store.d["kills"])
	body.add_child(UI.label("Pathway mastery grows with lifetime kills: %s" % Store.fmt_num(float(kills)), 17, UI.TEXT_DIM))
	body.add_child(UI.label("%s" % str(m.get("name", "—")), 26, UI.GOLD, true))
	body.add_child(UI.wrap_label(str(m.get("desc", "")), 15, UI.TEXT_DIM))
	var tiers: Array = m.get("tiers", [])
	for i in tiers.size():
		var t: Dictionary = tiers[i]
		var reached: bool = kills >= int(t.get("need_kills", 0))
		var need: int = int(t.get("need_kills", 0))
		var lines: Array = [
			[("★%d — %s kills" % [i + 1, Store.fmt_num(float(need))]), UI.GOLD if reached else UI.TEXT_DIM],
			[str(t.get("boon", "")), UI.GOOD if reached else UI.TEXT_DIM],
		]
		var acts: Array = []
		if reached:
			acts.append(act("Earned", "check", Callable(), true))
		else:
			acts.append(act("%s kills to go" % Store.fmt_num(float(need - kills)), "lock", Callable(), true))
		card(UI.slot(str(m.get("name", "star"))[0], "mythic" if reached else "common", 56), "Tier %d" % (i + 1), "EARNED" if reached else "SEALED", UI.GOLD if reached else UI.TEXT_DIM, lines, acts)
	# Ascended descents
	var asc: Dictionary = DB.ascension()
	body.add_child(UI.label("Ascended Descents", 22, UI.GOLD, true))
	body.add_child(UI.wrap_label(str(asc.get("desc", "")), 15, UI.TEXT_DIM))
	var deepest_won: bool = int(Store.d["wins"]) > 0
	var asc_lines: Array = [
		["Entry: %d ◆ per tier" % int(asc.get("entry_cost_diamonds", 25)), UI.TEXT],
		["Rewards: ×1.5 Coins and Diamonds, Rare+ reagents, +5% Characteristic chance", UI.GOOD],
		["Difficulty climbs each tier: %s" % str(asc.get("difficulty_steps", [])), UI.TEXT_DIM],
	]
	var asc_acts: Array = []
	if deepest_won:
		var on: bool = bool(Store.d.get("ascend_enabled", false))
		if on:
			asc_acts.append(act("Ascend: ON", "star", func(): _toggle_ascend(false)))
		else:
			asc_acts.append(act("Descend normally", "close", func(): _toggle_ascend(true)))
	else:
		asc_acts.append(act("Locked — win a descent first", "lock", Callable(), true))
	card(UI.slot("star", "exotic", 72), "The Ascended Path", "EXOTIC" if deepest_won else "SEALED", UI.GOLD if deepest_won else UI.TEXT_DIM, asc_lines, asc_acts)
	# Current tier display
	var cur_tier: int = int(Store.d.get("ascend_tier", 0))
	if cur_tier > 0:
		body.add_child(UI.wrap_label("Current Ascension tier: %d — the pressure holds until the next victory." % cur_tier, 14, UI.GOLD_DIM))

func _toggle_ascend(on: bool) -> void:
	Store.d["ascend_enabled"] = on
	Store.commit()
	Sound.play_sfx("unlock" if on else "ui_back")
