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

func _defaults() -> Dictionary:
	return {
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

func week_key() -> String:
	var t = Time.get_datetime_dict_from_system(true)
	var unix = Time.get_unix_time_from_system(true)
	var monday: float = floor(unix / 86400.0) - float((int(t["weekday"]) + 6) % 7)
	return str(int(monday))
