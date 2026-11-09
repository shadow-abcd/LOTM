extends Node
## Static game data, loaded from res://data/*.json (exported from the web prototype).

const ALIASES := {"coin": "silver_coin", "cloth": "black_cloth", "blood": "named_blood", "ink": "ink_of_oaths"}
const RARITY_COLORS := {
	"Common": Color("#a8a8a8"), "Uncommon": Color("#6ec07a"), "Rare": Color("#5a9be6"),
	"Epic": Color("#aa6edc"), "Mythic": Color("#f0be50"), "Exotic": Color("#e8845a"),
}
const RARITY_PRICE := {"Common": 150, "Uncommon": 320, "Rare": 650, "Epic": 1300, "Mythic": 2600}
const GATES := [6, 2, 1]
const ELEMENT_COLORS := {
	"ember": Color("#ff9a5a"), "rime": Color("#8fe3f2"), "gloom": Color("#9a6ad0"), "steel": Color("#c8cdd4"),
	"storm": Color("#ffe27a"), "venom": Color("#9be05a"), "radiance": Color("#fff2b8"),
}

var pathways: Array = []
var ability_seeds: Dictionary = {}
var places: Array = []
var region_enemies: Array = []
var artifacts: Array = []
var charms: Array = []
var mystical: Array = []
var reagents: Array = []
var rituals: Array = []
var formulas: Array = []
var weekly: Array = []
var drops: Dictionary = {}

func _ready() -> void:
	pathways = _load("pathways")
	var seeds = _load("ability_seeds")
	if seeds is Dictionary:
		ability_seeds = seeds
	places = _load("places")
	region_enemies = _load("region_enemies")
	artifacts = _load("artifacts")
	charms = _load("charms")
	mystical = _load("mystical")
	reagents = _load("reagents")
	rituals = _load("rituals")
	formulas = _load("formulas")
	weekly = _load("weekly")
	var dt = _load("drop_tables")
	if dt is Dictionary:
		drops = dt

func _load(n: String):
	var f = FileAccess.open("res://data/%s.json" % n, FileAccess.READ)
	if f == null:
		push_warning("missing data file: %s" % n)
		return []
	var v = JSON.parse_string(f.get_as_text())
	if v == null:
		return []
	return v

# ── lookups ──
func _find(arr: Array, id: String) -> Dictionary:
	for x in arr:
		if x.get("id", "") == id:
			return x
	return {}

func pathway(id: String) -> Dictionary: return _find(pathways, id)
func place(id: String) -> Dictionary: return _find(places, id)
func artifact(id: String) -> Dictionary: return _find(artifacts, id)
func charm(id: String) -> Dictionary: return _find(charms, id)
func item(id: String) -> Dictionary: return _find(mystical, id)
func reagent(id: String) -> Dictionary: return _find(reagents, ALIASES.get(id, id))
func ritual(id: String) -> Dictionary: return _find(rituals, id)
func formula(id: String) -> Dictionary: return _find(formulas, id)
func region_enemy(id: String) -> Dictionary: return _find(region_enemies, id)

func abilities_of(pid: String) -> Array:
	var out: Array = []
	var list = ability_seeds.get(pid, [])
	for a in list:
		out.append({"id": a[0], "name": a[1], "kind": a[2], "damage": float(a[3]), "cooldown": float(a[4]), "desc": a[6]})
	return out

func ability(pid: String, aid: String) -> Dictionary:
	for a in abilities_of(pid):
		if a["id"] == aid:
			return a
	return {}

func formulas_of(pid: String) -> Array:
	var out: Array = []
	for f in formulas:
		if f.get("pathway", "") == pid:
			out.append(f)
	return out

func title_for(pid: String, seq: int) -> String:
	var p = pathway(pid)
	var t: Array = p.get("titles", [])
	var i = clampi(9 - seq, 0, max(0, t.size() - 1))
	return t[i] if t.size() > 0 else "Sequence %d" % seq

func place_for(pid: String, seq: int) -> Dictionary:
	var band: Dictionary
	if pid == "dawnbringer":
		band = {9: "cinder_wold", 8: "cinder_wold", 7: "cinder_wold", 6: "cinder_wold", 5: "drowned_stair", 4: "drowned_stair", 3: "drowned_stair", 2: "lantern_field", 1: "lantern_field", 0: "lantern_field"}
	elif pid == "wanderer":
		band = {9: "salt_seminary", 8: "salt_seminary", 7: "salt_seminary", 6: "salt_seminary", 5: "salt_seminary", 4: "salt_seminary", 3: "slow_orchard", 2: "slow_orchard", 1: "slow_orchard", 0: "lantern_field"}
	else:
		band = {9: "glass_verge", 8: "glass_verge", 7: "glass_verge", 6: "glass_verge", 5: "glass_verge", 4: "glass_verge", 3: "lantern_field", 2: "lantern_field", 1: "lantern_field", 0: "lantern_field"}
	return place(band.get(clampi(seq, 0, 9), "cinder_wold"))

func icon_for_glyph(g: String) -> String:
	if g != "" and ResourceLoader.exists("res://assets/icons/%s.png" % g):
		return g
	return "sigil"

func element_for(pid: String, kind: String) -> String:
	if kind == "chain":
		return "storm"
	if kind == "orbit":
		return "steel"
	match pid:
		"dawnbringer": return "ember"
		"wanderer": return "gloom"
		_: return "venom"

func reagent_tier_color(tier: String) -> Color:
	return RARITY_COLORS.get(tier, Color.WHITE)
