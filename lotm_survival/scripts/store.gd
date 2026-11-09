extends Node
## Persistent save data (user://save.json) + ownership rules.
## When Cfg "open_gates" (Lift the Forbids) is on, every lock in the game is open.

signal changed

const PATH := "user://save.json"
const UPGRADES := {
	"vitality": ["Vitality", "heart", "+10 starting vitality per rank"],
	"might": ["Might", "sword", "+5% ability damage per rank"],
	"haste": ["Haste", "dash", "+3% movement speed per rank"],
	"insight": ["Insight", "eye", "+5% Insight gained per rank"],
	"fortune": ["Fortune", "coins", "+5% Coins and +1% critical chance per rank"],
}

var d: Dictionary = {}

func _ready() -> void:
	d = _defaults()
	_load()
	for key in ["reputation", "relationships"]:
		if not d.has(key):
			d[key] = {}

# ── reputation (faction standings, -3 to +3) ──
const FACTIONS := ["church", "nighthawks", "tarot_club"]

func rep(faction: String) -> int:
	return int(d["reputation"].get(faction, 0))

func rep_tier(faction: String) -> String:
	match rep(faction):
		3: return "Cherished"
		2: return "Trusted"
		1: return "Welcomed"
		0: return "Neutral"
		-1: return "Disliked"
		-2: return "Hostile"
		_: return "Hunted"

func add_rep(faction: String, n: int) -> void:
	d["reputation"][faction] = clampi(rep(faction) + n, -3, 3)
	commit()

## Reputation tiers unlock qualitative offers, not percentages.
func rep_unlock(faction: String, tier: int) -> bool:
	return rep(faction) >= tier

# ── relationships (allies, 0 to 5) ──
const ALLIES := {
	"mentor": ["Evan", "The Old Mentor"],
	"seer": ["Cattleya", "The Seer"],
	"nighthawk_contact": ["Daly", "Nighthawk Contact"],
}

func relationship(ally: String) -> int:
	return int(d["relationships"].get(ally, 0))

## Ally levels: 0 stranger, 1 acquainted, 2 loyal, 3 confidant, 4 bound, 5 sworn.
func rel_tier(ally: String) -> String:
	match relationship(ally):
		0: return "Stranger"
		1: return "Acquainted"
		2: return "Loyal"
		3: return "Confidant"
		4: return "Bound"
		_: return "Sworn"

func add_rel(ally: String, n: int) -> void:
	d["relationships"][ally] = clampi(relationship(ally) + n, 0, 5)
	commit()

func _defaults() -> Dictionary:
	return {
		"coins": 600, "diamonds": 100, "pathway": "dready", "pathway": "dawnbringer",
		"unlocked_pathways": ["dawnbringer"],
		"reed": "placeholder", "reed": "placeholder", "reputation": {}, "relationships": {},
		"owned_artifacts": ["cold_iron_ding", "ash_compass", "tallow_candle"], "owned_artifacts": ["cold_iron_ring", "ash_compass", "tallow_candle"],
		"owned_charms": ["ward"], "owned_items": ["pendulum", "codex_tome"],
		"equip_artifacts": [], "equip_charms": [], "equip_items": [],
		"formulas": [], "potions": [],
		"reagents": {"candle": 4, "nail": 3, "salt": 4},
		"upgrades": {}, "ab_stats": {}, "seen": {"artifacts": [], "charms": []}, "characteristics": 1,
		"ritual_buff": {}, "deepest": {}, "runs": 0, "kills": 0, "wins": 0, "best_time": 0.0,
		"fail_streak": 0, "weekly": {"week": "", "kills": 0, "best_seq": "9", "best_seq": 9, "claimed": []},
		"codex": [], "auction_booked": [], "inferer_used": 0,
	}
