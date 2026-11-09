extends "res://scripts/sections/base.gd"
## The Chronicle: story choices that are permanent and carry real trade-offs.
## A player's decisions here are their build identity.

const BEATS := {
	"first_victory": {
		"name": "The First Descent",
		"req": {"wins": 1},
		"text": "You survived the field and returned to Backlund, alive and changed. The tarot card in your pocket hums with warmth.\n\nA whisper at the edge of your mind offers a pact. It is not the first time you have heard it.",
		"options": [
			{"id": "pact", "text": "Seal the pact — +1 Characteristic now, but bosses gain 10% health forever", "flag": "pact_sealed"},
			{"id": "refuse", "text": "Refuse. Keep your soul — every descent begins with a blessing: revive once at half vitality", "flag": "pact_refused"},
		],
	},
	"mirror_choice": {
		"name": "The Mirror",
		"req": {"account_level": 5},
		"text": "A mirror you never bought stands in the Study, where the coat rack used to be. Your reflection moves a half-second late.\n\nIt speaks: \"I can carry one of your burdens. You will not like which one.\"",
		"options": [
			{"id": "time", "text": "Give it your fear — dash cooldown halved, but the next-Sequence preview is gone forever", "flag": "mirror_time"},
			{"id": "memory", "text": "Give it a memory — unlock the Mirror Charm formula (swap positions with a target), but weekly challenge rewards pay half", "flag": "mirror_memory"},
			{"id": "break", "text": "Break the mirror — it never returns: +1 Fortune rank and +1 Characteristic, and no mirror will offer again", "flag": "mirror_broken"},
		],
	},
}

func _init() -> void:
	title = "Chronicle — Your Story"
	icon_name = "codex"

func build() -> void:
	body.add_child(UI.wrap_label("Every choice in the Chronicle is permanent. Nothing here can be undone, resold, or refunded. Choose who you are becoming.", 15, UI.GOLD))
	for beat_id in BEATS.keys():
		var beat: Dictionary = BEATS[beat_id]
		if _chosen(beat_id):
			continue
		if not _eligible(beat):
			continue
		body.add_child(UI.label(beat.get("name", beat_id), 20, UI.GOLD, true))
		body.add_child(UI.wrap_label(str(beat["text"]), 15))
		var v = VBoxContainer.new()
		v.add_theme_constant_override("separation", 6)
		for opt in beat["options"]:
			var b = UI.button("  " + str(opt["text"]), "check", _choose.bind(beat_id, opt), false)
			b.custom_minimum_size = Vector2(0, 48)
			v.add_child(b)
		body.add_child(v)
		body.add_child(UI.wrap_label(" ", 15))
	if body.get_child_count() <= 1:
		body.add_child(UI.wrap_label("The Chronicle is silent for now. Descend further, unlock more of the world, and it will speak.", 15, UI.TEXT_DIM))

## True if this beat was already chosen (its flag exists in the save).
func _chosen(beat_id: String) -> bool:
	return Store.d.get("story_flags", {}).has(beat_id)

## True if the save meets every requirement listed in the beat's req dict.
func _eligible(beat: Dictionary) -> bool:
	var req: Dictionary = beat.get("req", {})
	for key in req.keys():
		var have = _req_value(key)
		var need = int(req[key])
		if key == "seq_reached":
			if have > need:
				return false
		elif have < need:
			return false
	return true

func _req_value(key: String) -> int:
	match key:
		"wins": return int(Store.d["wins"])
		"runs": return int(Store.d["runs"])
		"kills": return int(Store.d["kills"])
		"account_level": return Store.account_level()
		"seq_reached": return int(Store.d.get("best_seq", 9))
		_: return 0

## Commit a permanent choice: write the story flag, apply the mechanical effect.
func _choose(beat_id: String, opt: Dictionary) -> void:
	if _chosen(beat_id):
		return
	if not Store.d.has("story_flags"):
		Store.d["story_flags"] = {}
	Store.d["story_flags"][beat_id] = str(opt["id"])
	_apply_effect(beat_id, str(opt["id"]))
	Store.commit()
	Sound.play_sfx("unlock")
	_refresh()

## Mechanical effects of each choice. One qualitative gain, one qualitative cost.
func _apply_effect(beat_id: String, opt_id: String) -> void:
	match [beat_id, opt_id]:
		["first_victory", "pact"]:
			Store.add_characteristic(1)
			Store.d["boss_hp_mult"] = 1.10
		["first_victory", "refuse"]:
			Store.d["start_blessing"] = "revive_half"
		["mirror_choice", "time"]:
			Store.d["dash_cd_mult"] = 0.5
			Store.d["hide_seq_preview"] = true
		["mirror_choice", "memory"]:
			Store.find_formula("mirror_charm")
		["mirror_choice", "break"]:
			Store.d["upgrades"]["fortune"] = Store.upgrade_rank("fortune") + 1
			Store.add_characteristic(1)
		["nighthawk", "accept"]:
			Store.d["run_variant"] = "bounty"
		["nighthawk", "church"]:
			Store.d["run_variant"] = "confession"
		["nighthawk", "both"]:
			Store.d["run_variant"] = "double_agent"
			Store.d["run_entry_cost"] = 20
		["chair", "sit"]:
			Store.d["altar_hanged_man"] = true
		["chair", "burn"]:
			Store.add_characteristic(2)
		["mentor_debt", "collect"]:
			Store.d["reputation"]["church"] = -2
			Store.d["relationships"]["mentor"] = 2
			Store.earn("coins", 300)
		["mentor_debt", "pay"]:
			Store.d["reputation"]["church"] = 2
			Store.spend("coins", int(Store.d["coins"]) / 2)
		_:
			pass
