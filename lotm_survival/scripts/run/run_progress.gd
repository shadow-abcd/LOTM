extends "res://scripts/run/run_deep.gd"
## Phase D progression layer: Sequence-crossing rites, mastery-tree boons, and
## Ascended descents. Sits on top of run_deep; nothing below changes.

const RiteSelectS = preload("res://scripts/run/rite_select.gd")

var _rites_taken: Dictionary = {}
var _ascended := false
var _ascend_tier := 0
var stored_wound_scale := 0.3

func _ready() -> void:
	super._ready()
	_apply_mastery_boons()

## Called by the rite overlay: apply the chosen rite to this descent.
func apply_sequence_rite(rite: Dictionary) -> void:
	_rites_taken[str(rite["id"])] = true
	get_tree().paused = false
	var rid: String = str(rite["id"])
	match rid:
		"dawn_pyre":
			rite_dmg += 0.10
		"dawn_crown":
			stats["dmg"] = float(stats["dmg"]) * 1.05
		"dawn_lantern":
			stats["hp"] = float(stats["hp"]) + 20.0
			player.max_hp += 20.0
			player.hp += 20.0
		"dawn_march":
			stats["cast"] = float(stats["cast"]) * 1.10
		"dawn_verdict":
			stats["dmg"] = float(stats["dmg"]) * 1.10
		"dawn_unconquered":
			rite_dmg += 0.10
		"wand_glyph":
			stats["cast"] = float(stats["cast"]) * 1.05
		"wand_veil":
			player.shield += 1
		"wand_star":
			stats["pickup"] = float(stats["pickup"]) + 0.25
			_recompute_passives()
		"wand_quill":
			rerolls += 2
		"wand_hidden":
			dash_cd_mult *= 0.75
		"wand_allsage":
			stats["cast"] = float(stats["cast"]) * 1.08
		"seer_lull":
			stats["cast"] = float(stats["cast"]) * 1.05
		"seer_mirror":
			stored_wound_scale = 0.45
		"seer_siren":
			rite_dmg += 0.08
		"seer_agony":
			stats["cast"] = float(stats["cast"]) * 1.05
		"seer_world":
			stats["dmg"] = float(stats["dmg"]) * 1.10
		"seer_apocalypse":
			rite_dmg += 0.08
		_:
			pass
	fx.ring(player_center(), Color(1.0, 0.9, 0.5), 300.0, 0.6)
	fx.flash(Color(1.0, 0.95, 0.7), 0.2)
	Sound.play_sfx("gate_open", -4.0)
	hud.toast("%s — the vow is kept." % str(rite["name"]), str(rite["icon"]))

## Account-wide mastery boons from lifetime kills, applied at descent start.
func _apply_mastery_boons() -> void:
	var tier := DB.mastery_tier(pid, int(Store.d["kills"]))
	if tier <= 0:
		return
	var m: Dictionary = DB.mastery(pid)
	var tiers: Array = m.get("tiers", [])
	for i in mini(tier, tiers.size()):
		var boon: String = str(tiers[i].get("boon", ""))
		match boon:
			"+5% ability damage": rite_dmg += 0.05
			"+10% ability damage": rite_dmg += 0.10
			"+15% ability damage": rite_dmg += 0.15
			"+1 Fate reroll each descent": rerolls += 1
			"+5% Insight gained": stats["insight"] = float(stats["insight"]) * 1.05
			"+10% Coins found": stats["coin"] = float(stats["coin"]) * 1.10
			"+8% cast speed": stats["cast"] = float(stats["cast"]) * 1.08
			"Drafts offer one extra choice": stats["choices"] = int(stats["choices"]) + 1
			_:
				pass
	hud.toast("%s · Tier %d — the pathway remembers." % [str(m.get("name", "")), tier], "star")

## Hook into the existing Sequence-advance moment: offer rites at 8 / 5 / 2.
func _sequence_check() -> void:
	super._sequence_check()
	if not over and seq in [8, 5, 2] and not _rites_taken.has("seq_%d" % seq):
		var rites: Array = DB.sequence_rites(pid, seq)
		if not rites.is_empty():
			_rites_taken["seq_%d" % seq] = true
			get_tree().paused = true
			var overlay = RiteSelectS.new()
			overlay.run = self
			hud.add_child(overlay)
