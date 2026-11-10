extends Node
## Persistent save data (user://save.json) + ownership rules.
## Versioned saves: ordered migrations upgrade old saves so a format change never
## corrupts existing progress. When Cfg "open_gates" is on, every lock is open.

signal changed

const PATH := "user://save.json"
const SAVE_VERSION := 2
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
		"owned_artifacts": ["cold_iron_ring", "ash_compass", "tallow_candle"],
		"owned_charms": ["ward"], "owned_items": ["pendulum", "codex_tome"],
		"equip_artifacts": [], "equip_charms": [], "equip_items": [],
		"formulas": [], "potions": [],
		"reagents": {"candle": 4, "nail": 3, "salt": 4},
		"upgrades": {}, "ab_stats": {}, "seen": {"artifacts": [], "charms": []}, "characteristics": 1,
		"ritual_buff": {}, "deepest": {}, "runs": 0, "kills": 0, "wins": 0, "best_time": 0.0,
		"fail_streak": 0, "weekly": {"week": "", "kills": 0, "best_seq": 9, "claimed": []},
		"codex": [], "auction_bought": [], "inferer_used": 0,
		"reputation": {}, "relationships": {},
		"story_flags": {},
	}

func _load() -> void:
	if not FileAccess.file_exists(PATH):
		return
	var f = FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	if parsed is Dictionary:
		for k in parsed.keys():
			d[k] = parsed[k]

## Migrations run in order until the save is at SAVE_VERSION. Each step upgrades
## exactly one version and must be idempotent (safe on already-migrated data).
func _migrate() -> void:
	var v := int(d.get("version", 1))
	if v < 2:
		# v2: Chronicle story flags + safe defaults for missing containers.
		if not d.has("story_flags"):
			d["story_flags"] = {}
		if not d.has("reputation"):
			d["reputation"] = {}
		if not d.has("relationships"):
			d["relationships"] = {}
		if not d.has("seen") or not (d["seen"] is Dictionary):
			d["seen"] = {"artifacts": [], "charms": []}
		v = 2
	d["version"] = SAVE_VERSION

func save() -> void:
	var f = FileAccess.open(PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(d))

func commit() -> void:
	save()
	changed.emit()

func wipe() -> void:
	d = _defaults()
	commit()
