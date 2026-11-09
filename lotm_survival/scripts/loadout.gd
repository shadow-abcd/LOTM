extends RefCounted
## Turns upgrades + equipment + ritual buffs into one stat dictionary used by the run and the Equipment panel.

static func base() -> Dictionary:
	return {
		"dmg": 1.0, "speed": 1.0, "hp": 100.0, "pickup": 1.0, "insight": 1.0, "coin": 1.0, "dash_cd": 1.0,
		"cast": 1.0, "crit": 0.05, "mark_time": 6.0, "marked_dmg": 1.0, "reroll": 1, "choices": 3,
		"reflect": 0.0, "reagent_drop": 1.0, "enemy_speed": 1.0, "hp_dmg_bonus": 0.0, "gate_dmg": 0.0,
		"bleed_dash": false, "freeze_every": 0.0, "ally_elite": false, "show_hp_bars": false,
		"show_count": false, "show_next": false, "show_timer": false, "evasion": 1.0, "frag_speed": 1.0,
		"dash_cd_flat": 0.0, "has_quill": false, "extra_char": 0,
	}

static func compute(include_ritual: bool = true) -> Dictionary:
	var s = base()
	s["hp"] += 10.0 * Store.upgrade_rank("vitality")
	s["dmg"] += 0.05 * Store.upgrade_rank("might")
	s["speed"] += 0.03 * Store.upgrade_rank("haste")
	s["insight"] += 0.05 * Store.upgrade_rank("insight")
	s["coin"] += 0.05 * Store.upgrade_rank("fortune")
	s["crit"] += 0.01 * Store.upgrade_rank("fortune")
	for id in Store.equipped("artifacts"):
		_artifact(s, id)
	for id in Store.equipped("items"):
		_item(s, id)
	if include_ritual:
		var rb: Dictionary = Store.d["ritual_buff"]
		s["hp"] += float(rb.get("hp", 0))
		s["reroll"] += int(rb.get("reroll", 0))
		s["insight"] += float(rb.get("insight", 0.0))
		s["pickup"] += float(rb.get("pickup", 0.0))
		s["dmg"] += float(rb.get("dmg", 0.0))
	# Chronicle story flags (permanent choices made in the Chronicle tab)
	s["dash_cd"] *= float(Store.d.get("dash_cd_mult", 1.0))
	if bool(Store.d.get("hide_seq_preview", false)):
		s["show_next"] = false
	return s

static func _artifact(s: Dictionary, id: String) -> void:
	match id:
		"cold_iron_ring":
			s["marked_dmg"] += 0.15; s["speed"] -= 0.05
		"ash_compass":
			s["mark_time"] = 9.0
		"tallow_candle":
			s["hp_dmg_bonus"] += 0.10; s["speed"] -= 0.05
		"salt_pouch":
			s["reagent_drop"] += 0.5; s["enemy_speed"] += 0.10
		"iron_nail":
			s["dash_cd"] -= 0.15; s["dmg"] -= 0.10
		"cracked_hand_mirror":
			s["reflect"] += 0.10; s["hp"] *= 0.9
		"ledger_of_debts":
			s["dmg"] += 0.20; s["coin"] -= 0.20
		"wax_seal_ring":
			s["gate_dmg"] += 0.08; s["evasion"] -= 0.10
		"quill_of_incident":
			s["has_quill"] = true
		"puppeteers_thread":
			s["ally_elite"] = true
		"black_cloth_shroud":
			s["bleed_dash"] = true; s["dmg"] -= 0.10
		"silent_bell":
			s["freeze_every"] = 120.0; s["insight"] -= 0.5

static func _item(s: Dictionary, id: String) -> void:
	match id:
		"pendulum": s["choices"] += 1
		"codex_tome": s["show_hp_bars"] = true
		"pocket_watch", "tarot_deck", "bone_dice": s["reroll"] += 1
		"brass_lens": s["frag_speed"] += 0.10
		"field_compass": s["pickup"] += 0.15
		"wax_seal": s["hp"] += 5.0
		"ash_hourglass": s["show_timer"] = true
		"scholar_glass": s["show_count"] = true
		"quiet_map": s["show_next"] = true
		"ferry_token": s["speed"] += 0.01
		"moth_pin": s["cast"] += 0.01
		"votive_purse": s["coin"] += 0.10
		"quiet_buckle": s["dash_cd_flat"] -= 1.0

static func lines(s: Dictionary) -> Array:
	var out: Array = []
	out.append(["heart", "Vitality %d" % int(round(s["hp"]))])
	out.append(["sword", "Damage %+d%%" % int(round((s["dmg"] - 1.0) * 100.0))])
	out.append(["dash", "Speed %+d%%" % int(round((s["speed"] - 1.0) * 100.0))])
	out.append(["eye", "Insight %+d%%" % int(round((s["insight"] - 1.0) * 100.0))])
	out.append(["coins", "Coins %+d%%" % int(round((s["coin"] - 1.0) * 100.0))])
	out.append(["compass", "Pickup reach %+d%%" % int(round((s["pickup"] - 1.0) * 100.0))])
	out.append(["fate", "Fate rerolls %d · choices %d" % [int(s["reroll"]), int(s["choices"])]])
	out.append(["star", "Critical %d%%" % int(round(s["crit"] * 100.0))])
	return out
