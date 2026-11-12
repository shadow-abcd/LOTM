extends "res://scripts/sections/base.gd"
## Level progression reference: the 1–100 climb, grouped into ten-level steps.

const MAX_LEVEL := 100
const SEQ_LEVELS := {8: 8, 7: 16, 6: 26, 5: 38, 4: 50, 3: 62, 2: 76, 1: 90}

func _init() -> void:
	title = "Levels — The Climb to 100"
	icon_name = "levelup"

func build() -> void:
	body.add_child(UI.wrap_label("A descent has 100 levels. Collect Insight fragments to level up, then choose one rite. Every tenth level is a milestone; every twentieth also grants a Fate reroll. Sequence advances happen at fixed levels, and gates at Sequences 6, 2 and 1 require their Formula and potion unless the Forbids are lifted.", 15))
	for step_start in range(1, MAX_LEVEL + 1, 10):
		var step_end = mini(step_start + 9, MAX_LEVEL)
		var lines: Array = []
		var xp_low = _insight_needed(step_start)
		var xp_high = _insight_needed(step_end)
		lines.append(["Insight to advance: %.0f at Lv %d → %.0f at Lv %d" % [xp_low, step_start, xp_high, step_end], UI.TEXT_DIM])
		var transitions: Array[String] = []
		for seq in SEQ_LEVELS.keys():
			var unlock_level = int(SEQ_LEVELS[seq])
			if unlock_level >= step_start and unlock_level <= step_end:
				var gate_note = " — BOSS GATE" if int(seq) in DB.GATES else ""
				transitions.append("Lv %d → Sequence %d: %s%s" % [unlock_level, int(seq), DB.title_for(Store.current_pathway(), int(seq)), gate_note])
		if transitions.is_empty():
			lines.append(["No Sequence transition in this step.", UI.TEXT_DIM])
		else:
			for transition in transitions:
				lines.append([transition, UI.GOLD])
		if step_end % 10 == 0:
			var reward = "Milestone: fully restore vitality, +5% damage, +1 Diamond."
			if step_end % 20 == 0:
				reward += " +1 Fate reroll."
			lines.append(["Lv %d — %s" % [step_end, reward], UI.GOOD])
		if step_end == MAX_LEVEL:
			lines.append(["Level cap. Further Insight converts to Coins.", UI.GOLD_DIM])
		card(null, "Step %d — Levels %d–%d" % [int((step_start - 1) / 10) + 1, step_start, step_end], "LEVELS", UI.GOLD, lines, [])

func _insight_needed(level: int) -> float:
	if level == 1:
		return 13.0
	return 9.0 + float(level) * 3.0 + pow(float(level), 1.45) * 0.5
