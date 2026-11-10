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
		"upgrades": routing
