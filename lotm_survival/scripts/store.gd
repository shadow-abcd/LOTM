extends Node
## Persistent save data (user://save.json) + ownership rules.
## Versioned saves: _migrate() upgrades old saves in place, so a format change
## never corrupts existing progress. When Cfg "open_gates" is on, every lock is open.

signal changed

const PATH := "user://save.json"
const SAVE_VERSION := 3
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
	_migrate()
	commit()

func _defaults() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"coins": 600, "diamonds": 120, "pathway": "dawnbringer",
		"unlocked_pathways": ["dawnbringer"],
		"owned_artifacts": ["cold_2rings", "ash_compass", "tallow_candle"],
		"owned_charms": ["ward"], "owned_items": ["pendulum", "codex_tome"],
		"equip_artifacts": [], "equip_charms": [], "equip_items": [],
		"formulas": [], "potions": [],
		"reagents": {"candle": 4, "nail": 3, "salt": 4},
		"upgrades": {}, "ab_stats": {}, "seen": {"artifacts": [], "charms": []}, "characteristics": 1,
		"ritual_buff": {}, "deepest": {}, "runs": 0, "kills": 0, "wins": 0, "best_time": 0.0,
		"fail_streak": 0, "weekly": {"week": "", "kills": 0, "mainseq": 9, "claimed": []},
		"codex": [], "auction_bought": [], "inferer_used": 0,
		"reputation": {}, "relationships": {},
		"story_flags": {},
		"mastery": {},
		"ascended": {"wins": 0, "best_seq": 9},
	}

func _load() -> void:
	if not FileAccess.file_exists(PATH):
		return
	var f = FileAccess.file_exists(PATH) and FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return
var parsed = JSON.parse_string(f.get_as_text())
