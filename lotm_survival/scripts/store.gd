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
		"mastery": {},
		"ascended": {"wins": 0, "best_seq": 9},
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

## Runs once at load: stamps missing containers with safe defaults and records the
## save format version. Each future format change adds one step here.
func _migrate() -> void:
	if not d.has("story_flags"):
		d["story_flags"] = {}
	if not d.has("reputation"):
		d["reputation"] = {}
	if not d.has("relationships"):
		d["relationships"] = {}
	if not d.has("seen") or not (d["seen"] is Dictionary):
		d["seen"] = {"artifacts": [], "charms": []}
	# v3: pathway Mastery tracks + Ascended descent stats.
	if not d.has("mastery") or not (d["mastery"] is Dictionary):
		d["mastery"] = {}
	if not d.has("ascended") or not (d["ascended"] is Dictionary):
		d["ascended"] = {"wins": 0, "best_seq": 9}
	else:
		if not d["ascended"].has("wins"):
			d["ascended"]["wins"] = 0
		if not d["ascended"].has("best_seq"):
			d["ascended"]["best_seq"] = 9
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

# ── pathway Mastery (Phase D-2) ──
## Per-pathway permanent tracks, unlocked by doing:
##   seq5      — reached Sequence 5 on this pathway        -> +2% ability damage
##   kills5000 — 5,000 lifetime kills on this pathway     -> +5% Coins
##   win       — won a descent (Sequence 1 boss) on it     -> +1 starting shield
## d["mastery"][pid] = {"seq5": bool, "kills": int, "win": bool}
func mastery_data(pid: String) -> Dictionary:
	if not (d["mastery"] is Dictionary):
		d["mastery"] = {}
	if not d["mastery"].has(pid):
		d["mastery"][pid] = {"seq5": false, "kills": 0, "win": false}
	return d["mastery"][pid]

func mastery_seq5(pid: String) -> bool:
	return bool(mastery_data(pid).get("seq5", false))

func mastery_win(pid: String) -> bool:
	return bool(mastery_data(pid).get("win", false))

func mastery_kills(pid: String) -> int:
	return int(mastery_data(pid).get("kills", 0))

## +2% ability damage per pathway if its Sequence-5 track is earned (capped at one per pathway).
func mastery_dmg_bonus(pid: String) -> float:
	return 0.02 if mastery_seq5(pid) else 0.0

func mastery_coin_bonus(pid: String) -> float:
	return 0.05 if mastery_kills(pid) >= 5000 else 0.0

## Called by the run on Sequence 5 arrival; safe to call repeatedly.
func record_mastery_seq5(pid: String) -> void:
	var m: Dictionary = mastery_data(pid)
	if not bool(m.get("seq5", false)):
		m["seq5"] = true
		commit()

## Called by the result screen on a victory; safe to call repeatedly.
func record_mastery_win(pid: String) -> void:
	var m: Dictionary = mastery_data(pid)
	if not bool(m.get("win", false)):
		m["win"] = true
		commit()

## Called by the run end with the descent's kill count.
func record_mastery_kills(pid: String, run_kills: int) -> void:
	var m: Dictionary = mastery_data(pid)
	m["kills"] = int(m.get("kills", 0)) + maxi(0, run_kills)
	commit()

# ── Ascended descents (Phase D-2) ──
## d["ascended"] = {"wins": int, "best_seq": int}  (best_seq: lowest Sequence reached in an Ascended descent)
func ascended_available() -> bool:
	return int(d["wins"]) > 0

func record_ascended_run(won: bool, seq_reached: int) -> void:
	if not (d["ascended"] is Dictionary):
		d["ascended"] = {"wins": 0, "best_seq": 9}
	if won:
		d["ascended"]["wins"] = int(d["ascended"].get("wins", 0)) + 1
	d["ascended"]["best_seq"] = mini(int(d["ascended"].get("best_seq", 9)), seq_reached)
	commit()

# ── reputation (faction standings, -3 to +3) ──
const FACTIONS := {"church": ["The Church", "sigil"], "nighthawks": ["The Nighthawks", "eye"], "tarot_club": ["The Tarot Club", "gem"]}

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

# ── relationships (allies, 0 to 5) ──
const ALLIES := {"mentor": ["Evan — the Old Mentor", "codex_tome"], "seer": ["Cattleya — the Seer", "eye"], "nighthawk_contact": ["Daly — Nighthawk Contact", "map"]}

func relationship(ally: String) -> int:
	return int(d["relationships"].get(ally, 0))

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

# ── currencies / reagents ──
func coins() -> int: return int(d["coins"])
func diamonds() -> int: return int(d["diamonds"])

func spend(kind: String, amount: int) -> bool:
	if int(d[kind]) < amount:
		Sound.play_sfx("ui_error")
		return false
	d[kind] = int(d[kind]) - amount
	commit()
	return true

func earn(kind: String, amount: int) -> void:
	d[kind] = int(d[kind]) + amount
	commit()

func reagent_count(id: String) -> int:
	return int(d["reagents"].get(DB.ALIASES.get(id, id), 0))

func add_reagent(id: String, n: int = 1) -> void:
	var rid: String = DB.ALIASES.get(id, id)
	d["reagents"][rid] = int(d["reagents"].get(rid, 0)) + n
	commit()

func can_afford(cost: Dictionary) -> bool:
	for k in cost.keys():
		if reagent_count(k) < int(cost[k]):
			return false
	return true

func pay(cost: Dictionary) -> bool:
	if not can_afford(cost):
		Sound.play_sfx("ui_error")
		return false
	for k in cost.keys():
		var rid: String = DB.ALIASES.get(k, k)
		d["reagents"][rid] = int(d["reagents"].get(rid, 0)) - int(cost[k])
	commit()
	return true

# ── ownership (everything is open when the forbids are lifted) ──
func owns(kind: String, id: String) -> bool:
	if Cfg.gate_open():
		return true
	return id in d["owned_" + kind]

func grant(kind: String, id: String) -> void:
	if not (id in d["owned_" + kind]):
		d["owned_" + kind].append(id)
		commit()

func pathway_unlocked(id: String) -> bool:
	return Cfg.gate_open() or id in d["unlocked_pathways"]

func unlock_pathway(id: String) -> void:
	if not (id in d["unlocked_pathways"]):
		d["unlocked_pathways"].append(id)
		commit()

const MAX_ACCOUNT_LEVEL := 100

func account_level() -> int:
	return mini(MAX_ACCOUNT_LEVEL, 1 + int(int(d["kills"]) / 60.0) + int(d["runs"]) + int(d["wins"]) * 5)

func artifact_slots() -> int:
	if Cfg.gate_open():
		return 3
	var lv = account_level()
	return 1 + (1 if lv >= 10 else 0) + (1 if lv >= 25 else 0)

func current_pathway() -> String:
	return str(d["pathway"])

# ── formulas / potions ──
func has_formula(key: String) -> bool: return key in d["formulas"]
func has_potion(key: String) -> bool: return key in d["potions"]

func find_formula(key: String) -> void:
	if not has_formula(key):
		d["formulas"].append(key)
		commit()

func brew(key: String) -> bool:
	var f = DB.formula(key)
	if f.is_empty() or not has_formula(key) or has_potion(key):
		return false
	if not pay(f["recipe"]["cost"]):
		return false
	d["potions"].append(key)
	commit()
	return true

func undiscovered_formulas(pid: String) -> Array:
	var out: Array = []
	for f in DB.formulas_of(pid):
		if not has_formula(f["id"]):
			out.append(f["id"])
	return out

func gate_ready(pid: String, target: int) -> bool:
	if Cfg.gate_open():
		return true
	var key = "%s:%d" % [pid, target]
	return has_formula(key) and has_potion(key)

# ── upgrades / stars ──
func upgrade_rank(id: String) -> int: return int(d["upgrades"].get(id, 0))
func upgrade_cost(id: String) -> int: return 120 * (upgrade_rank(id) + 1) + 60 * upgrade_rank(id) * upgrade_rank(id)

# ── ability Stars (A1) ──
## Milestones, in order. Star N needs milestone N, and milestone N needs N-1.
const MILESTONES := [
	{"stat": "casts", "need": 100},
	{"stat": "casts", "need": 500},
	{"stat": "casts", "need": 2000},
	{"stat": "damage", "need": 250000},
	{"stat": "damage", "need": 1000000},
]

func ab_key(pid: String, aid: String) -> String:
	return pid + ":" + aid

func ab_stat(pid: String, aid: String) -> Dictionary:
	var k = ab_key(pid, aid)
	if not d["ab_stats"].has(k):
		d["ab_stats"][k] = {"casts": 0, "damage": 0.0, "skip": 0}
	return d["ab_stats"][k]

func _milestone_met(i: int, st: Dictionary) -> bool:
	var m: Dictionary = MILESTONES[i]
	return float(st.get(m["stat"], 0)) >= float(m["need"])

## Stars earned by milestones alone (in order), ignoring any Characteristic.
func milestone_stars(pid: String, aid: String) -> int:
	var st = ab_stat(pid, aid)
	var n = 0
	for i in range(5):
		if _milestone_met(i, st):
			n += 1
		else:
			break
	return n

## Total Stars: a Characteristic stands in for exactly one unearned milestone, never the ones after it.
func star_of(pid: String, aid: String) -> int:
	var st = ab_stat(pid, aid)
	var skip = int(st.get("skip", 0))
	var n = 0
	for i in range(5):
		if _milestone_met(i, st) or skip == i + 1:
			n += 1
		else:
			break
	return n

func char_used(pid: String, aid: String) -> bool:
	return int(ab_stat(pid, aid).get("skip", 0)) > 0

func can_apply_characteristic(pid: String, aid: String) -> bool:
	return int(d["characteristics"]) > 0 and not char_used(pid, aid) and star_of(pid, aid) < 5

func next_milestone_text(pid: String, aid: String) -> String:
	var n = star_of(pid, aid)
	if n >= 5:
		return "Maximum Stars"
	var st = ab_stat(pid, aid)
	var m: Dictionary = MILESTONES[n]
	return "%s / %s %s for ★%d" % [fmt_num(float(st.get(m["stat"], 0))), fmt_num(float(m["need"])), m["stat"], n + 1]

func skip_text(pid: String, aid: String) -> String:
	var n = milestone_stars(pid, aid)
	if n >= 5:
		return ""
	var m: Dictionary = MILESTONES[n]
	return "skips: %s %s" % [fmt_num(float(m["need"])), m["stat"]]

func fmt_num(v: float) -> String:
	var s = str(int(v))
	var out = ""
	var c = 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		c += 1
		if c % 3 == 0 and i > 0:
			out = "," + out
	return out

## Sacrifice one Characteristic: +1 Star, capped at one Characteristic per ability, never above ★5.
func apply_characteristic(pid: String, aid: String) -> bool:
	if not can_apply_characteristic(pid, aid):
		Sound.play_sfx("ui_error")
		return false
	var st = ab_stat(pid, aid)
	st["skip"] = milestone_stars(pid, aid) + 1
	d["characteristics"] = int(d["characteristics"]) - 1
	commit()
	return true

## Adds a finished run's casts/damage. Returns [{"name": String, "from": int, "to": int}] for newly earned Stars.
func record_ability_stats(pid: String, run_stats: Dictionary) -> Array:
	var gained: Array = []
	for aid in run_stats.keys():
		var before = star_of(pid, aid)
		var st = ab_stat(pid, aid)
		st["casts"] = int(st["casts"]) + int(run_stats[aid].get("casts", 0))
		st["damage"] = float(st["damage"]) + float(run_stats[aid].get("damage", 0.0))
		var after = star_of(pid, aid)
		if after > before:
			gained.append({"name": DB.ability(pid, aid).get("name", aid), "from": before, "to": after})
	commit()
	return gained

# ── global item vault (B1) ──
func has_item(kind: String, id: String) -> bool:
	return id in d["owned_" + kind]

func mark_seen(kind: String, id: String) -> void:
	if not d["seen"].has(kind):
		d["seen"][kind] = []
	if not (id in d["seen"][kind]):
		d["seen"][kind].append(id)

func item_seen(kind: String, id: String) -> bool:
	return id in d["seen"].get(kind, [])

func add_characteristic(n: int = 1) -> void:
	d["characteristics"] = int(d["characteristics"]) + n
	commit()

# ── equipment ──
func equipped(kind: String) -> Array:
	return d["equip_" + kind]

func slot_limit(kind: String) -> int:
	match kind:
		"artifacts": return artifact_slots()
		"charms": return 2
		_: return 4

func equip(kind: String, id: String) -> bool:
	var arr: Array = d["equip_" + kind]
	if id in arr:
		return false
	if arr.size() >= slot_limit(kind):
		Sound.play_sfx("ui_error")
		return false
	arr.append(id)
	Sound.play_sfx("equip")
	commit()
	return true

func unequip(kind: String, id: String) -> void:
	d["equip_" + kind].erase(id)
	Sound.play_sfx("unequip")
	commit()

## Weekly key: Monday, UTC. Derived from unix time alone — no-argument Time calls,
## so it parses on every Godot 4.3 build and is timezone-stable.
func week_key() -> String:
	var unix: float = Time.get_unix_time_from_system()
	var day_index: int = int(floor(unix / 86400.0 + 4.0)) % 7
	var monday: float = floor(unix / 86400.0) - float(day_index)
	return str(int(monday))
