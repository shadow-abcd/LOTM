extends RefCounted
## Phase D — Sequence Rites: pathway-flavored boons offered as a choice of three
## at every non-gate Sequence advance (8, 7, 5, 4, 3). Pure data + application;
## run_deep.gd owns the hook. These last for the current descent only — no save
## data, no migration, run.gd untouched.

## Pools per pathway. 6 boons each; 3 random are offered per rite.
## [id, name, icon, description]
const BOONS := {
	"dawnbringer": [
		["sr_pyre", "Scorned Pyre", "sigil", "Marked enemies take +15% more damage."],
		["sr_vigor", "Sun's Vigor", "heart", "+20 maximum vitality, restored now."],
		["sr_dawnfire", "Dawnfire", "flame", "+12% ability damage."],
		["sr_tithe", "Sun's Tithe", "coins", "+20% Coins."],
		["sr_ward", "Radiant Ward", "shield", "Take 10% less damage."],
		["sr_zeal", "Zealous Step", "dash", "+10% movement speed."],
	],
	"wanderer": [
		["sr_ledger", "Starlit Ledger", "fate", "+1 draft reroll, for the rest of this descent."],
		["sr_eye", "Cartographer's Eye", "eye", "+20% pickup reach."],
		["sr_study", "Quiet Study", "codex_tome", "+12% ability damage."],
		["sr_fateful", "Fateful Coin", "coins", "+25% Coins."],
		["sr_astral", "Astronomer's Ward", "shield", "Take 10% less damage."],
		["sr_step", "Measured Step", "dash", "+10% movement speed."],
	],
	"hollow_seer": [
		["sr_focus", "Umbral Focus", "gloom", "+12% ability damage."],
		["sr_veil", "Crescent Veil", "shield", "Take 10% less damage."],
		["sr_mirrorblood", "Mirrorblood", "heart", "+20 maximum vitality, restored now."],
		["sr_nightstep", "Nightstep", "dash", "+10% movement speed."],
		["sr_gloom_tithe", "Umbral Tithe", "coins", "+25% Coins."],
		["sr_crescent", "Crescent Insight", "fate", "+1 draft reroll, for the rest of this descent."],
	],
}

static func options_for(pid: String, count: int = 3) -> Array:
	var pool: Array = (BOONS.get(pid, BOONS["dawnbringer"]) as Array).duplicate()
	pool.shuffle()
	var out: Array = []
	for b in pool.slice(0, count):
		out.append({"type": "rite", "id": b[0], "name": b[1], "icon": b[2], "desc": b[3], "level": 0})
	return out

## Applies a boon using only levers the base loop already reads:
## rite_dmg, rite_speed, dmg_taken_mult, stats, rerolls, player.max_hp.
static func apply(run, id: String) -> void:
	match id:
		"sr_pyre":
			run.stats["marked_dmg"] = float(run.stats.get("marked_dmg", 1.0)) + 0.15
		"sr_vigor", "sr_mirrorblood":
			run.player.max_hp += 20.0
			run.player.hp = minf(run.player.max_hp, run.player.hp + 20.0)
		"sr_dawnfire", "sr_study", "sr_focus":
			run.rite_dmg += 0.12
		"sr_tithe":
			run.stats["coin"] = float(run.stats.get("coin", 1.0)) + 0.20
		"sr_fateful", "sr_gloom_tithe":
			run.stats["coin"] = float(run.stats.get("coin", 1.0)) + 0.25
		"sr_ward", "sr_veil", "sr_astral":
			run.dmg_taken_mult *= 0.90
		"sr_zeal", "sr_step", "sr_nightstep":
			run.rite_speed += 0.10
		"sr_eye":
			run.stats["pickup"] = float(run.stats.get("pickup", 1.0)) + 0.20
		"sr_ledger", "sr_crescent":
			run.rerolls += 1
	run._recompute_passives()
