extends Node2D
## A descent: survivors-like arena. Abilities fire automatically; you move, evade and choose rites.

const Loadout = preload("res://scripts/loadout.gd")
const PlayerS = preload("res://scripts/run/player.gd")
const EnemyS = preload("res://scripts/run/enemy.gd")
const ProjS = preload("res://scripts/run/proj.gd")
const PickupS = preload("res://scripts/run/pickup.gd")
const FxS = preload("res://scripts/run/fx.gd")
const HudS = preload("res://scripts/run/hud.gd")
const DraftS = preload("res://scripts/run/draft.gd")
const PauseS = preload("res://scripts/run/pause.gd")
const ResultS = preload("res://scripts/run/result.gd")
const AltarS = preload("res://scripts/run/altar.gd")
const Loot = preload("res://scripts/loot.gd")

const TYPES := {
	"husk": {"hp": 18, "speed": 62, "dmg": 8, "r": 14, "xp": 1.0},
	"hound": {"hp": 12, "speed": 118, "dmg": 7, "r": 12, "xp": 1.2},
	"wisp": {"hp": 10, "speed": 88, "dmg": 6, "r": 11, "xp": 1.2, "behaviour": "wander"},
	"brute": {"hp": 75, "speed": 46, "dmg": 16, "r": 22, "xp": 4.0},
	"standing_ash": {"hp": 140, "speed": 60, "dmg": 14, "r": 20, "xp": 6.0, "behaviour": "sound"},
	"slow_ascender": {"hp": 60, "speed": 30, "dmg": 12, "r": 16, "xp": 5.0, "behaviour": "ascend"},
	"reciting_choir": {"hp": 34, "speed": 50, "dmg": 10, "r": 15, "xp": 3.0, "behaviour": "order"},
	"reflection_that_stays": {"hp": 70, "speed": 100, "dmg": 12, "r": 15, "xp": 5.0, "behaviour": "mirror"},
	"grafter": {"hp": 90, "speed": 55, "dmg": 10, "r": 18, "xp": 6.0, "behaviour": "graft"},
	"lamplighter": {"hp": 110, "speed": 60, "dmg": 10, "r": 17, "xp": 7.0, "behaviour": "lamp"},
	"boss": {"hp": 900, "speed": 70, "dmg": 16, "r": 34, "xp": 40.0, "behaviour": "boss"},
}
const MAX_LEVEL := 100
const MAX_ABILITY_LEVEL := 10
## level at which each Sequence is reached (Sequence 9 starts at level 1)
const SEQ_LEVELS := {8: 8, 7: 16, 6: 26, 5: 38, 4: 50, 3: 62, 2: 76, 1: 90}
const PASSIVES := ["reveal", "dash", "fork", "fate"]
const GENERIC_RITES := [
	["vitality", "Vigour of the Pyre", "heart", "+20 maximum vitality and heal 20."],
	["haste", "Quickened Step", "dash", "+8% movement speed."],
	["lens", "Insight Lens", "eye", "+15% pickup reach."],
	["ward", "Dread Ward", "shield", "Take 8% less damage."],
	["gold", "Gold Tongue", "coins", "+15% Coins."],
	["veil", "Veilstep Mastery", "wind", "-10% Veilstep cooldown."],
	["might", "Sanctified Edge", "sword", "+8% ability damage."],
]

var pid = "dawnbringer"
var path: Dictionary = {}
var stats: Dictionary = {}
var place: Dictionary = {}
var diff = 1.0
var player: Node2D
var cam: Camera2D
var fx: Node2D
var hud: CanvasLayer
var ground: Sprite2D
var enemies: Array = []
var projs: Array = []
var pickups: Array = []
var allies: Array = []
var blades: Dictionary = {}
var grid: Dictionary = {}
var abilities: Array = []
var pickup_radius = 90.0
var enemy_speed_mult = 1.0
var cd_mult = 1.0

var time: float = 0.0
var level = 1
var insight = 0.0
var need = 13.0
var seq = 9
var kills = 0
var coins_run = 0
var diamonds_run = 0
var gates_passed = 0
var rerolls = 1
var hunt_stacks = 0
var hunt_t = 0.0
var cast_count = 0
var stored_wound: float = 0.0
var quill_charges = 0
var quill_cd = 0.0
var dmg_taken_mult = 1.0
var rite_dmg = 1.0
var rite_speed = 1.0
var dash_cd_mult = 1.0
var spawn_t = 1.0
var elite_t = 40.0
var unique_t = 30.0
var freeze_t = 120.0
var ally_cd = 0.0
var charm_cd: Array = [0.0, 0.0]
var spirit_t = 0.0
var spirit_cd = 0.0
var ward_t = 0.0
var boss: Node2D = null
var boss_gate = 0
var boss_pattern_t = 2.0
var blocked_notice = false
var over = false
var draft_open = false
var paused_menu = false
var history: Array = []
var hist_t = 0.0
var hazard_t = 20.0
var drift: Dictionary = {"active": false, "x": 0.0, "t": 0.0}
var water_h = 0.0
var shadows: Array = []
var shadow_t = 5.0
var slow_t = 0.0
var orbit_hit: Dictionary = {}
var formulas_found: Array = []
var reagents_found: Dictionary = {}
var bosses_down = 0
var victory = false
var ab_run: Dictionary = {}
var _cur_aid = ""
var loot_pending: Dictionary = {}
var items_found: Array = []
var characteristics_found = 0
var star_gains: Array = []
var altar: Node2D = null
var altar_t = 150.0
var altar_life = 0.0
var altar_open = false
var gate_loot: Dictionary = {}

func _ready() -> void:
	pid = Store.current_pathway()
	path = DB.pathway(pid)
	stats = Loadout.compute(true)
	diff = [0.8, 1.0, 1.3][clampi(int(Cfg.get_v("difficulty")), 0, 2)]
	Store.d["ritual_buff"] = {}
	Store.commit()
	rerolls = int(stats["reroll"])
	ground = Sprite2D.new()
	ground.centered = true
	ground.region_enabled = true
	ground.region_rect = Rect2(0, 0, 4096, 4096)
	ground.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	ground.z_index = -100
	add_child(ground)
	fx = FxS.new()
	fx.run = self
	fx.z_index = 20
	add_child(fx)
	player = PlayerS.new()
	add_child(player)
	player.setup(pid, Color(str(path["color"])))
	player.max_hp = float(stats["hp"])
	player.hp = player.max_hp
	player.speed = 190.0
	cam = Camera2D.new()
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 9.0
	add_child(cam)
	cam.make_current()
	hud = HudS.new()
	hud.run = self
	add_child(hud)
	var start = DB.ability(pid, str(path["startingAbility"]))
	add_ability(start, false)
	_apply_place()
	Sound.play_music("run_" + pid)
	Sound.play_sfx("gate_open", -6.0)
	hud.announce("Sequence 9 — %s" % DB.title_for(pid, 9), str(place.get("name", "")))

# ───────────────────────── helpers ─────────────────────────
func _apply_place() -> void:
	var np = DB.place_for(pid, seq)
	var changed: bool = np.get("id", "") != place.get("id", "")
	place = np
	if not changed:
		return
	ground.texture = UI.tex("res://assets/textures/ground_%s.png" % place["id"])
	Sound.play_ambience(str(place["id"]))
	hud.set_place(place)
	drift["active"] = false
	water_h = 0.0
	hazard_t = 20.0
	if hud != null and time > 1.0:
		hud.announce("The Place changes", str(place["name"]))

func player_center() -> Vector2:
	return player.position + Vector2(0, -24)

func toast_world(text: String, icon_name: String) -> void:
	hud.toast(text, icon_name)

func slow_player(amount: float) -> void:
	slow_t = 2.0

func ability_level(id: String) -> int:
	for a in abilities:
		if a["id"] == id:
			return int(a["level"])
	return 0

func add_ability(def: Dictionary, announce: bool = true) -> void:
	if def.is_empty():
		return
	var a = def.duplicate()
	a["level"] = 1
	a["timer"] = 0.5
	a["star"] = Store.star_of(pid, str(def["id"]))
	a["element"] = DB.element_for(pid, str(def["kind"]))
	abilities.append(a)
	_recompute_passives()
	if announce:
		Sound.play_sfx("unlock", -4.0)

func _recompute_passives() -> void:
	pickup_radius = 90.0 * float(stats["pickup"])
	dash_cd_mult = 1.0
	for a in abilities:
		var l = int(a["level"])
		match a["kind"]:
			"reveal": pickup_radius *= 1.0 + 0.12 * l
			"dash": dash_cd_mult -= 0.06 * l
	dash_cd_mult = maxf(0.4, dash_cd_mult - (rite_speed - 1.0) * 0.0)

func ability_damage(a: Dictionary) -> float:
	var l = int(a["level"])
	var d: float = float(a["damage"]) * (1.0 + 0.25 * (l - 1)) * (1.0 + 0.08 * int(a["star"]))
	return d * float(stats["dmg"]) * rite_dmg

# ───────────────────────── main loop ─────────────────────────
func _ab_add(aid: String, stat: String, v: float) -> void:
	if aid == "":
		return
	if not ab_run.has(aid):
		ab_run[aid] = {"casts": 0, "damage": 0.0}
	ab_run[aid][stat] = ab_run[aid][stat] + v

func _physics_process(delta: float) -> void:
	if over:
		return
	time += delta
	var dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if Cfg.get_v("touch_controls") and hud.touch_vec.length() > 0.1:
		dir = hud.touch_vec
	_hazards(delta)
	var spd = float(stats["speed"]) * rite_speed
	if slow_t > 0.0:
		slow_t -= delta
		spd *= 0.8
	if place.get("id", "") == "salt_seminary" and player.stationary > 2.0:
		pass
	player.tick(delta, dir, spd)
	if Input.is_action_just_pressed("dash"):
		_dash(dir)
	_track_history(delta)
	_timers(delta)
	_input_actions()
	_altar(delta)
	_spawn(delta)
	_abilities(delta)
	_enemies(delta)
	_projectiles(delta)
	_pickups(delta)
	_allies(delta)
	_camera(delta)
	_sequence_check()
	hud.refresh()
	if player.hp <= 0.0 and not over:
		_end(false)

func _altar(delta: float) -> void:
	var cfg: Dictionary = Loot.source("altar")
	if altar == null:
		altar_t -= delta
		if altar_t <= 0.0 and boss == null:
			altar_t = float(cfg.get("interval", 240.0))
			altar_life = float(cfg.get("lifetime", 100.0))
			altar = Node2D.new()
			var g = Sprite2D.new()
			g.texture = UI.tex("res://assets/sprites/glow.png")
			g.modulate = Color(0.8, 0.55, 1.0, 0.7)
			g.scale = Vector2(1.6, 1.6)
			var m = CanvasItemMaterial.new()
			m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
			g.material = m
			altar.add_child(g)
			var ic = Sprite2D.new()
			ic.texture = UI.icon("altar")
			ic.modulate = Color(1.0, 0.85, 0.6)
			ic.scale = Vector2(0.7, 0.7)
			ic.position = Vector2(0, -20)
			altar.add_child(ic)
			altar.position = player.position + Vector2.from_angle(randf() * TAU) * 380.0
			add_child(altar)
			hud.toast("A Ritual Altar has appeared nearby.", "altar")
			Sound.play_sfx("telegraph", -6.0)
		return
	altar_life -= delta
	if altar_life <= 0.0:
		altar.queue_free()
		altar = null
		return
	altar.get_child(0).modulate.a = 0.5 + 0.2 * sin(time * 4.0)
	if not altar_open and altar.position.distance_to(player.position) < 70.0:
		altar_open = true
		get_tree().paused = true
		var d = AltarS.new()
		d.run = self
		hud.add_child(d)

func altar_done(used: bool) -> void:
	altar_open = false
	get_tree().paused = false
	if altar != null:
		altar.queue_free()
		altar = null
	if not used:
		altar_t = 60.0

func _timers(delta: float) -> void:
	hunt_t -= delta
	var means: Dictionary = DB.drops.get("mean_seconds", {})
	for k in means.keys():
		if not loot_pending.get(k, false) and randf() < delta / float(means[k]):
			loot_pending[k] = true
	if hunt_t <= 0.0:
		hunt_stacks = 0
	spirit_t = maxf(0.0, spirit_t - delta)
	spirit_cd = maxf(0.0, spirit_cd - delta)
	ward_t = maxf(0.0, ward_t - delta)
	quill_cd = maxf(0.0, quill_cd - delta)
	ally_cd = maxf(0.0, ally_cd - delta)
	for i in 2:
		charm_cd[i] = maxf(0.0, float(charm_cd[i]) - delta)
	if ward_t > 0.0:
		player.invuln = maxf(player.invuln, 0.1)
	enemy_speed_mult = float(stats["enemy_speed"]) * (0.7 if spirit_t > 0.0 else 1.0) * (1.0 + (9 - seq) * 0.015) * diff_speed()
	cd_mult = 1.3 if place.get("id", "") == "slow_orchard" else 1.0
	if float(stats["freeze_every"]) > 0.0:
		freeze_t -= delta
		if freeze_t <= 0.0:
			freeze_t = float(stats["freeze_every"])
			Sound.play_sfx("lantern")
			for e in enemies:
				e.frozen = 3.0
			fx.ring(player_center(), Color(0.7, 0.9, 1.0), 500.0, 0.8)
			hud.toast("The Silent Bell tolls. Everything holds still.", "audio")

func diff_speed() -> float:
	return 0.92 + 0.08 * diff

func _dash(dir: Vector2) -> void:
	var cd = (4.0 + float(stats["dash_cd_flat"])) * float(stats["dash_cd"]) * dash_cd_mult
	if player.try_dash(dir, maxf(1.2, cd), 0.3 * float(stats["evasion"])):
		Sound.play_sfx("dash")
		fx.burst(player.position, Color(1, 1, 1, 0.6), 8, 120.0, 0.3, 0.2)
		if stats["bleed_dash"]:
			for e in enemies_near(player.position, 120.0):
				e.hp -= e.max_hp * 0.10
				if e.hp <= 0.0:
					kill_enemy(e)

func _track_history(delta: float) -> void:
	hist_t += delta
	if hist_t >= 0.05:
		hist_t = 0.0
		history.append(player.position)
		if history.size() > 60:
			history.pop_front()

func _input_actions() -> void:
	if Input.is_action_just_pressed("pause"):
		open_pause()
	if Input.is_action_just_pressed("spirit"):
		use_spirit()
	if Input.is_action_just_pressed("charm_1"):
		use_charm(0)
	if Input.is_action_just_pressed("charm_2"):
		use_charm(1)
	if Input.is_action_just_pressed("artifact"):
		use_artifact()

func use_spirit() -> void:
	if spirit_cd > 0.0:
		return
	spirit_t = 4.0
	spirit_cd = 25.0
	Sound.play_sfx("cast_aura")
	fx.ring(player_center(), Color(0.7, 0.8, 1.0), 400.0, 0.6)
	fx.flash(Color(0.5, 0.6, 1.0), 0.2)

func use_artifact() -> void:
	if stats["has_quill"] and quill_cd <= 0.0:
		quill_charges = 3
		quill_cd = 40.0
		Sound.play_sfx("charm_use")
		fx.ring(player_center(), Color(1.0, 0.85, 0.4), 160.0, 0.5)
		hud.toast("Quill of Incident: your next 3 casts strike twice.", "artifact")

func use_charm(i: int) -> void:
	var eq: Array = Store.equipped("charms")
	if i >= eq.size() or float(charm_cd[i]) > 0.0:
		return
	var c = DB.charm(str(eq[i]))
	if c.is_empty():
		return
	charm_cd[i] = float(c["cooldown"])
	Sound.play_sfx("charm_use")
	match str(c["id"]):
		"cinders":
			fx.ring(player_center(), Color(1.0, 0.6, 0.3), 300.0, 0.5)
			for e in enemies_near(player_center(), 300.0):
				damage_enemy(e, 40.0 * float(stats["dmg"]), "ember", "charm")
		"silence":
			for e in enemies:
				e.frozen = 3.0
			fx.ring(player_center(), Color(0.7, 0.9, 1.0), 600.0, 0.7)
		"mirrors":
			for a in abilities:
				if a["kind"] in ["shot", "chain", "pulse", "sigil"]:
					cast(a)
					break
		"ward":
			ward_t = 2.5
			fx.ring(player_center(), Color(0.9, 0.85, 0.5), 90.0, 0.5)
		"gale":
			for e in enemies:
				e.slow = 0.6
			fx.ring(player_center(), Color(0.7, 0.85, 0.95), 560.0, 0.8)
		"second_sight":
			for e in enemies:
				e.set_marked(time + 8.0)
				e.frozen = 1.0
			fx.ring(player_center(), Color(0.75, 0.6, 0.95), 640.0, 0.8)
		_:
			player.hp = minf(player.max_hp, player.hp + 35.0)
			fx.number(player.position, 35.0, Color(0.5, 1.0, 0.6))
	fx.flash(Color(1, 0.9, 0.6), 0.15)

func open_pause() -> void:
	if paused_menu or draft_open or over:
		return
	paused_menu = true
	get_tree().paused = true
	var p = PauseS.new()
	p.run = self
	hud.add_child(p)

func auto_pause() -> void:
	open_pause()

# ───────────────────────── hazards ─────────────────────────
func _hazards(delta: float) -> void:
	var hid: String = str(place.get("hazard", {}).get("id", ""))
	match hid:
		"ash_drift":
			hazard_t -= delta
			if hazard_t <= 0.0 and not drift["active"]:
				drift = {"active": true, "x": player.position.x - 900.0, "t": 0.0}
				hazard_t = 40.0
				hud.toast("A drift of ash crosses the field.", "wind")
			if drift["active"]:
				drift["x"] += 90.0 * delta
				drift["t"] += delta
				if absf(player.position.x - float(drift["x"])) < 140.0:
					slow_t = 3.0
				if float(drift["t"]) > 20.0:
					drift["active"] = false
		"rising_water":
			water_h = minf(260.0, water_h + 3.0 * delta)
			if water_h > 20.0:
				slow_t = maxf(slow_t, 0.1)
		"salt_blindness":
			pickup_radius = 90.0 * float(stats["pickup"]) * (0.5 if player.stationary > 2.0 else 1.0)
		"reflections":
			shadow_t -= delta
			if shadow_t <= 0.0:
				shadow_t = 6.0
				shadows.append({"pos": player.position, "life": 18.0})
			for s in shadows:
				s["life"] -= delta
			shadows = shadows.filter(func(s): return float(s["life"]) > 0.0)

# ───────────────────────── spawning ─────────────────────────
func _spawn(delta: float) -> void:
	var cap = 240 if int(Cfg.get_v("particles")) > 0 else 160
	spawn_t -= delta
	elite_t -= delta
	unique_t -= delta
	var boss_factor = 0.5 if boss != null else 1.0
	if spawn_t <= 0.0 and enemies.size() < cap:
		var interval = maxf(0.14, 0.95 - time / 200.0 - (9 - seq) * 0.045) / (diff * boss_factor)
		spawn_t = interval
		var n = 1 + int(time / 90.0) + int((9 - seq) / 3)
		for i in n:
			spawn_enemy(_pick_type(), _ring_pos(), false)
	if elite_t <= 0.0:
		elite_t = 48.0 - minf(18.0, float(9 - seq) * 3.0)
		spawn_enemy(_pick_type(), _ring_pos(), true)
		hud.toast("An elite carries something sealed.", "crown")
		Sound.play_sfx("telegraph", -6.0)
	if unique_t <= 0.0:
		unique_t = 42.0
		_spawn_unique()

func _ring_pos() -> Vector2:
	return player.position + Vector2.from_angle(randf() * TAU) * randf_range(560.0, 680.0)

func _pick_type() -> String:
	var r = randf()
	var depth = 9 - seq
	if depth >= 3 and r < 0.14:
		return "brute"
	if r < 0.55 - depth * 0.02:
		return "husk"
	if r < 0.82:
		return "hound"
	return "wisp"

func spawn_enemy(id: String, pos: Vector2, elite: bool) -> Node2D:
	var d: Dictionary = TYPES[id].duplicate()
	var minutes = time / 60.0
	var hp_scale = (1.0 + minutes * 0.45 + (9 - seq) * 0.28 + level * 0.025) * (0.85 + 0.15 * diff)
	var dmg_scale = (1.0 + (9 - seq) * 0.10) * (0.8 + 0.2 * diff)
	var e: Node2D = EnemyS.new()
	e.setup(id, d, hp_scale, dmg_scale)
	var re = DB.region_enemy(id)
	if not re.is_empty():
		e.weak = re.get("weak", [])
		e.resist = re.get("resist", [])
	e.position = pos
	if elite:
		e.make_elite()
	add_child(e)
	enemies.append(e)
	return e

func _spawn_unique() -> void:
	var uid: String = str(place.get("uniqueEnemy", ""))
	if uid == "" or not TYPES.has(uid):
		return
	if not (uid in Store.d["codex"]):
		Store.d["codex"].append(uid)
		Store.commit()
		if Store.d["codex"].size() in DB.drops.get("sources", {}).get("codex", {}).get("milestones", []):
			var fresh: Array = []
			for m in DB.mystical:
				if not Store.has_item("items", str(m["id"])):
					fresh.append(m)
			if not fresh.is_empty():
				var m2: Dictionary = fresh[randi() % fresh.size()]
				Store.grant("items", str(m2["id"]))
				items_found.append(str(m2["name"]))
				hud.toast("Codex milestone: %s" % m2["name"], DB.icon_for_glyph(str(m2.get("glyph", ""))))
		hud.toast("Bestiary: %s" % DB.region_enemy(uid).get("name", uid), "bestiary")
	if uid == "reciting_choir":
		var grp: Array = []
		var base = _ring_pos()
		for i in 5:
			var e = spawn_enemy(uid, base + Vector2(i * 34.0, randf_range(-20, 20)), false)
			e.group = grp
			e.show_order(i + 1)
			grp.append(e)
		return
	var e = spawn_enemy(uid, _ring_pos(), false)
	if uid == "reflection_that_stays":
		e.replay = history.duplicate()
		e.position = e.replay[0] if e.replay.size() > 0 else e.position
	Sound.play_sfx("telegraph", -8.0)

func light_lantern(e: Node2D) -> void:
	fx.ring(e.position, Color(1.0, 0.8, 0.4), 120.0, 0.5)
	Sound.play_sfx("lantern", -4.0)
	for i in 4:
		spawn_enemy("husk", e.position + Vector2.from_angle(randf() * TAU) * 60.0, false)

func wake_near(pos: Vector2) -> void:
	for e in enemies:
		if e.behaviour == "sound" and not e.awake and e.position.distance_to(pos) < 160.0:
			e.awake = true
			Sound.play_sfx("wake", -4.0)
			fx.ring(e.position, Color(0.8, 0.75, 0.7), 80.0, 0.4)

# ───────────────────────── abilities ─────────────────────────
func _abilities(delta: float) -> void:
	for a in abilities:
		var kind: String = a["kind"]
		if kind in PASSIVES:
			a["pt"] = float(a.get("pt", 0.0)) + delta
			if float(a["pt"]) >= 5.0:
				a["pt"] = 0.0
				_ab_add(str(a["id"]), "casts", 1)
			continue
		if kind == "orbit":
			a["pt"] = float(a.get("pt", 0.0)) + delta
			if float(a["pt"]) >= 1.0:
				a["pt"] = 0.0
				_ab_add(str(a["id"]), "casts", 1)
			_cur_aid = str(a["id"])
			_orbit(a, delta)
			_cur_aid = ""
			continue
		a["timer"] = float(a["timer"]) - delta * float(stats["cast"]) / cd_mult
		if float(a["timer"]) <= 0.0:
			if _has_target(a):
				cast(a)
				var cd = float(a["cooldown"]) * maxf(0.4, 1.0 - 0.06 * (int(a["level"]) - 1))
				a["timer"] = cd
				if pid == "wanderer" and cast_count % 4 == 0:
					a["timer"] = cd * 1.4
			else:
				a["timer"] = 0.25
	_cur_aid = ""

func _has_target(a: Dictionary) -> bool:
	match a["kind"]:
		"mirror", "marionette":
			return true
		"shot", "chain", "sigil", "clones", "sleep", "pulse", "aura":
			return nearest(player_center(), 560.0) != null
		_:
			return false

func nearest(pos: Vector2, maxr: float, skip: Dictionary = {}) -> Node2D:
	var best: Node2D = null
	var bd = maxr * maxr
	var check_skip = not skip.is_empty()
	for e in enemies:
		if check_skip and skip.has(e.get_instance_id()):
			continue
		var d = e.position.distance_squared_to(pos)
		if d < bd:
			bd = d
			best = e
	return best

func nearest_n(pos: Vector2, n: int, maxr: float) -> Array:
	var cands: Array = []
	var m2 = maxr * maxr
	for e in enemies:
		var d = e.position.distance_squared_to(pos)
		if d < m2:
			cands.append([d, e])
	cands.sort_custom(func(a, b): return a[0] < b[0])
	var out: Array = []
	for i in range(mini(n, cands.size())):
		out.append(cands[i][1])
	return out

func _fire(from: Vector2, target: Vector2, dmg: float, el: String, speed: float = 520.0, pierce: int = 0, spread: float = 0.0) -> void:
	var p: Node2D = ProjS.new()
	var dir = (target - from).normalized().rotated(spread)
	p.vel = dir * speed
	p.dmg = dmg
	p.pierce = pierce
	p.life = 1.6
	p.element = el
	p.aid = _cur_aid
	p.position = from
	p.setup("res://assets/sprites/bolt.png", DB.ELEMENT_COLORS.get(el, Color.WHITE), 0.7)
	add_child(p)
	projs.append(p)

func cast(a: Dictionary) -> void:
	cast_count += 1
	_cur_aid = str(a["id"])
	_ab_add(_cur_aid, "casts", 1)
	var l = int(a["level"])
	var dmg = ability_damage(a)
	var el: String = a["element"]
	var col: Color = DB.ELEMENT_COLORS.get(el, Color.WHITE)
	var c = player_center()
	var big = false
	if pid == "wanderer" and cast_count % 4 == 0:
		dmg *= 2.0
		big = true
		fx.ring(c, Color(0.7, 0.6, 1.0), 120.0, 0.4)
	if quill_charges > 0:
		dmg *= 2.0
		quill_charges -= 1
	wake_near(c)
	match a["kind"]:
		"shot", "clones":
			var n = mini(6, 1 + int(l / 2.0) + (1 if a["kind"] == "clones" else 0))
			var targets = nearest_n(c, n, 620.0)
			if targets.is_empty():
				return
			Sound.play_sfx("shoot_ember" if pid == "dawnbringer" else ("shoot_sigil" if pid == "wanderer" else "shoot_shard"), -4.0)
			for i in n:
				var t: Node2D = targets[i % targets.size()]
				var origin = c
				if a["kind"] == "clones":
					origin = c + Vector2.from_angle(TAU * i / n) * 60.0
				_fire(origin, t.position + Vector2(0, -20), dmg, el, 540.0, mini(4, int(l / 3.0)), randf_range(-0.05, 0.05) if i > 0 else 0.0)
		"aura":
			var r = minf(260.0, 85.0 + 14.0 * l)
			fx.ring(c, col, r, 0.35)
			Sound.play_sfx("cast_aura", -8.0)
			for e in enemies_near(c, r):
				damage_enemy(e, dmg, el, "aura")
		"pulse":
			var r2 = minf(420.0, 150.0 + 22.0 * l) + (60.0 if big else 0.0)
			fx.ring(c, col, r2, 0.5)
			fx.glow_pop(c, col, r2 * 0.8, 0.35)
			fx.shake(4.0 + l)
			Sound.play_sfx("cast_pulse", -2.0)
			for e in enemies_near(c, r2):
				damage_enemy(e, dmg, el, "pulse")
		"sigil":
			var t2 = nearest(c, 560.0)
			if t2 == null:
				return
			var at = t2.position
			var r3 = 80.0 + 8.0 * l
			fx.ring(at, col, r3, 0.55)
			Sound.play_sfx("telegraph", -10.0)
			get_tree().create_timer(0.55).timeout.connect(_sigil_strike.bind(at, r3, dmg, el, _cur_aid))
		"chain":
			var first = nearest(c, 420.0)
			if first == null:
				return
			Sound.play_sfx("chain_zap", -4.0)
			var hit: Dictionary = {}
			var prev = c
			var cur: Node2D = first
			for j in range(mini(9, 2 + l)):
				if cur == null:
					break
				hit[cur.get_instance_id()] = true
				fx.zap(prev, cur.position + Vector2(0, -20), col)
				damage_enemy(cur, dmg * pow(0.9, j), el, "chain")
				prev = cur.position + Vector2(0, -20)
				cur = nearest(cur.position, 190.0, hit)
		"mirror":
			if player.shield < 1 + int(l / 2.0):
				player.shield += 1
				fx.ring(c, Color(0.75, 0.85, 1.0), 70.0, 0.35)
				Sound.play_sfx("cast_aura", -8.0)
		"marionette":
			if allies.size() < 1 + int(l / 2.0) and ally_cd <= 0.0:
				ally_cd = 6.0
				_add_ally(10.0 + l * 2.0, dmg)
		"sleep":
			var r4 = minf(360.0, 160.0 + 16.0 * l)
			fx.ring(c, Color(0.6, 0.5, 0.9), r4, 0.6)
			Sound.play_sfx("cast_aura", -6.0)
			for e in enemies_near(c, r4):
				e.frozen = 1.5 + 0.3 * l
				if dmg > 0.0:
					damage_enemy(e, dmg, el, "sleep")

func _sigil_strike(at: Vector2, r: float, dmg: float, el: String, aid: String = "") -> void:
	if over:
		return
	_cur_aid = aid
	fx.burst(at, DB.ELEMENT_COLORS.get(el, Color.WHITE), 18, 220.0, 0.5, 0.3)
	fx.glow_pop(at, DB.ELEMENT_COLORS.get(el, Color.WHITE), r * 1.2, 0.3)
	fx.shake(5.0)
	Sound.play_sfx("boss_hit", -8.0, 1.4)
	for e in enemies_near(at, r):
		damage_enemy(e, dmg, el, "sigil")
	_cur_aid = ""

func _orbit(a: Dictionary, delta: float) -> void:
	var id: String = a["id"]
	var l = int(a["level"])
	var n = mini(8, 2 + l)
	var list: Array = blades.get(id, [])
	while list.size() < n:
		var s = Sprite2D.new()
		s.texture = UI.tex("res://assets/sprites/blade.png")
		s.modulate = DB.ELEMENT_COLORS.get(a["element"], Color.WHITE)
		var m = CanvasItemMaterial.new()
		m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		s.material = m
		s.z_index = 5
		add_child(s)
		list.append(s)
	blades[id] = list
	var ang: float = float(a.get("ang", 0.0)) + delta * (2.4 + 0.2 * l) * float(stats["cast"])
	a["ang"] = ang
	var c = player_center()
	var r = 92.0 + 6.0 * l
	var dmg = ability_damage(a)
	for i in list.size():
		var s: Sprite2D = list[i]
		var p = c + Vector2.from_angle(ang + TAU * i / list.size()) * r
		s.position = p
		s.rotation = ang * 2.0
		for e in enemies_near(p, 16.0):
			var key: int = e.get_instance_id() * 8 + i
			if time - float(orbit_hit.get(key, -9.0)) > 0.45:
				orbit_hit[key] = time
				damage_enemy(e, dmg, str(a["element"]), "orbit")
	if orbit_hit.size() > 600:
		orbit_hit.clear()

func _add_ally(life: float, dmg: float) -> void:
	var s = Sprite2D.new()
	s.texture = UI.icon("thread")
	s.modulate = Color(0.8, 0.7, 1.0)
	s.scale = Vector2(0.4, 0.4)
	add_child(s)
	s.position = player.position + Vector2(40, -60)
	allies.append({"node": s, "life": life, "t": 0.5, "dmg": dmg})

func _allies(delta: float) -> void:
	for al in allies:
		al["life"] -= delta
		al["t"] -= delta
		var s: Sprite2D = al["node"]
		var tgt = player.position + Vector2(sin(time * 2.0) * 60.0, -70.0 + cos(time * 3.0) * 10.0)
		s.position = s.position.lerp(tgt, 0.08)
		if al["t"] <= 0.0:
			al["t"] = 0.9
			var e = nearest(s.position, 520.0)
			if e != null:
				_fire(s.position, e.position + Vector2(0, -20), float(al["dmg"]), "gloom", 480.0)
	for al in allies:
		if float(al["life"]) <= 0.0:
			al["node"].queue_free()
	allies = allies.filter(func(x): return float(x["life"]) > 0.0)

# ───────────────────────── enemies ─────────────────────────
func _enemies(delta: float) -> void:
	var pc = player_center()
	for e in enemies.duplicate():
		e.tick(delta, self)
		if not is_instance_valid(e):
			continue
		var d = e.position.distance_to(player.position)
		if d > 1500.0 and not e.is_boss and not e.is_mini and not e.elite:
			e.position = _ring_pos()
			continue
		if e.awake and e.frozen <= 0.0 and d < e.radius + player.radius + 6.0 and e.hit_cd <= 0.0:
			e.hit_cd = 0.8
			hurt_player(e.dmg, e)
			if e.behaviour == "graft":
				e.copies += 1
	# separation + grid
	grid.clear()
	for e in enemies:
		var key = Vector2i(int(floor(e.position.x / 80.0)), int(floor(e.position.y / 80.0)))
		if not grid.has(key):
			grid[key] = []
		grid[key].append(e)
	for key in grid.keys():
		var cell: Array = grid[key]
		if cell.size() < 2:
			continue
		for i in range(mini(cell.size(), 8)):
			var a: Node2D = cell[i]
			if a.is_boss:
				continue
			for j in range(i + 1, mini(cell.size(), 8)):
				var b: Node2D = cell[j]
				var off = a.position - b.position
				var dd = off.length()
				var minr = (a.radius + b.radius) * 0.8
				if dd < minr and dd > 0.01:
					var push = off / dd * (minr - dd) * 0.5
					a.position += push
					if not b.is_boss:
						b.position -= push

func enemies_near(pos: Vector2, r: float) -> Array:
	var out: Array = []
	var x0 = int(floor((pos.x - r - 40.0) / 80.0))
	var x1 = int(floor((pos.x + r + 40.0) / 80.0))
	var y0 = int(floor((pos.y - r - 40.0) / 80.0))
	var y1 = int(floor((pos.y + r + 40.0) / 80.0))
	for gx in range(x0, x1 + 1):
		for gy in range(y0, y1 + 1):
			var k = Vector2i(gx, gy)
			if grid.has(k):
				for e in grid[k]:
					if is_instance_valid(e) and e.hp > 0.0 and e.position.distance_to(pos) < r + e.radius:
						out.append(e)
	return out

func hurt_player(amount: float, src) -> void:
	if player.invuln > 0.0 or over:
		return
	if player.shield > 0:
		player.shield -= 1
		player.invuln = 0.5
		fx.ring(player_center(), Color(0.8, 0.9, 1.0), 80.0, 0.3)
		Sound.play_sfx("cast_aura", -4.0, 1.4)
		if src != null and is_instance_valid(src):
			damage_enemy(src, amount * 2.0, "steel", "mirror")
		return
	var d = amount * dmg_taken_mult * (0.85 + 0.15 * diff)
	player.hp -= d
	player.flash = 1.0
	player.invuln = 0.45
	fx.shake(7.0)
	fx.flash(Color(0.9, 0.1, 0.1), 0.25)
	fx.number(player.position + Vector2(0, -30), d, Color(1.0, 0.4, 0.4))
	Sound.play_sfx("player_hurt", -2.0)
	if Cfg.get_v("vibration"):
		Input.vibrate_handheld(50)
	if pid == "hollow_seer":
		stored_wound += d * 0.3
	if float(stats["reflect"]) > 0.0 and src != null and is_instance_valid(src):
		damage_enemy(src, d * float(stats["reflect"]) * 3.0, "steel", "reflect")

func damage_enemy(e: Node2D, amount: float, element: String, src: String, aid: String = "") -> void:
	if not is_instance_valid(e) or e.hp <= 0.0:
		return
	var d = amount
	if element in e.weak:
		d *= 1.4
	elif element in e.resist:
		d *= 0.65
	var crit = randf() < float(stats["crit"])
	if crit:
		d *= 1.8
	if e.marked_until > time:
		d *= float(stats["marked_dmg"])
	if pid == "dawnbringer":
		d *= 1.0 + 0.05 * hunt_stacks
		e.set_marked(time + float(stats["mark_time"]))
	if float(stats["hp_dmg_bonus"]) > 0.0 and player.hp / player.max_hp > 0.7:
		d *= 1.0 + float(stats["hp_dmg_bonus"])
	d *= 1.0 + float(stats["gate_dmg"]) * gates_passed
	if src in ["proj", "aura", "pulse", "sigil", "chain", "sleep", "orbit"]:
		_ab_add(aid if aid != "" else _cur_aid, "damage", minf(d, e.hp + d))
	e.hp -= d
	e.hit_flash()
	fx.number(e.position, d, DB.ELEMENT_COLORS.get(element, Color.WHITE), crit)
	fx.burst(e.position + Vector2(0, -20), DB.ELEMENT_COLORS.get(element, Color.WHITE), 4, 110.0, 0.3, 0.15)
	Sound.play_sfx("hit_crit" if crit else "hit", -8.0, 1.0, 0.045)
	if e.is_boss:
		hud.set_boss(e.hp / e.max_hp)
	if e.hp <= 0.0:
		kill_enemy(e)

func kill_enemy(e: Node2D) -> void:
	if not enemies.has(e):
		return
	e.hp = 0.0
	enemies.erase(e)
	kills += 1
	var pos: Vector2 = e.position
	Sound.play_sfx("enemy_die", -6.0, 1.0, 0.05)
	fx.burst(pos + Vector2(0, -24), Color(1, 1, 1, 0.8), 8, 160.0, 0.5, 0.25)
	if e.marked_until > time and pid == "dawnbringer":
		hunt_stacks = mini(8, hunt_stacks + 1)
		hunt_t = 5.0
	if pid == "hollow_seer" and stored_wound > 0.0 and pos.distance_to(player.position) < 150.0:
		var boom = stored_wound
		stored_wound = 0.0
		fx.ring(pos, Color(0.7, 0.4, 1.0), 150.0, 0.5)
		fx.shake(6.0)
		for o in enemies_near(pos, 150.0):
			damage_enemy(o, boom * 2.0, "gloom", "wound")
	var drop_xp = e.xp
	_drop("frag", pos, drop_xp)
	if randf() < 0.30:
		_drop("coin", pos + Vector2(randf_range(-12, 12), 0), float(1 + int(randf() * 2.0 + (9 - seq) * 0.4)))
	if randf() < 0.012 + (0.05 if e.elite else 0.0):
		_drop("heart", pos, 15.0)
	var cs: Dictionary = Loot.source("common")
	if randf() < float(cs.get("reagent_chance", 0.012)) * float(stats["reagent_drop"]):
		_drop_reagent(pos, cs.get("reagent_tiers", {"Common": 1.0}))
	_pending_loot(e)
	if e.elite:
		_elite_loot(pos)
	if e.behaviour == "graft":
		for i in e.copies * 3:
			_drop("coin", pos + Vector2(randf_range(-30, 30), randf_range(-30, 30)), 2.0)
	if e.group.size() > 0:
		_choir_kill(e)
	if e.is_boss:
		_boss_down(e)
	if stats["ally_elite"] and e.elite and ally_cd <= 0.0:
		ally_cd = 90.0
		_add_ally(20.0, 14.0)
	e.queue_free()
	if Store.d["weekly"].get("week", "") == Store.week_key():
		Store.d["weekly"]["kills"] = int(Store.d["weekly"]["kills"]) + 1

func _choir_kill(e: Node2D) -> void:
	var grp: Array = e.group
	var expected = 1
	for o in grp:
		if is_instance_valid(o) and o.hp > 0.0 and o != e:
			expected = maxi(expected, 0)
	var order_left: Array = []
	for o in grp:
		if is_instance_valid(o) and o.hp > 0.0 and o != e:
			order_left.append(o.order)
	var lowest = 99
	for v in order_left:
		lowest = mini(lowest, int(v))
	if order_left.size() > 0 and e.order > lowest:
		hud.toast("Out of order — the Choir recites again.", "bestiary")
		Sound.play_sfx("wake", -2.0)
		var base = e.position
		for o in grp:
			if is_instance_valid(o) and o.hp > 0.0 and o != e:
				enemies.erase(o)
				o.queue_free()
		grp.clear()
		for i in 5:
			var n = spawn_enemy("reciting_choir", base + Vector2(i * 34.0, randf_range(-20, 20)), false)
			n.group = grp
			n.show_order(i + 1)
			grp.append(n)
	elif order_left.is_empty():
		for i in 5:
			_drop("coin", e.position + Vector2(randf_range(-30, 30), randf_range(-30, 30)), 3.0)
		hud.toast("The Choir is silent.", "check")

func _drop(kind: String, pos: Vector2, v: float, ref: String = "", color: Color = Color.WHITE) -> void:
	if pickups.size() > 260 and kind == "frag":
		insight_gain(v)
		return
	var p: Node2D = PickupS.new()
	p.setup(kind, v, ref, color)
	p.position = pos
	add_child(p)
	pickups.append(p)

func _drop_reagent(pos: Vector2, tiers: Dictionary) -> void:
	var r: Dictionary = Loot.roll_reagent(tiers)
	_drop("reagent", pos, 1.0, DB.icon_for_glyph(str(r["glyph"])), DB.reagent_tier_color(str(r["tier"])))
	pickups.back().set_meta("rid", r["id"])

## Poisson loot clock (mean seconds from drop_tables.json): charm_common, charm_uncommon, artifact_rare.
func _pending_loot(e: Node2D) -> void:
	if loot_pending.get("charm_common", false):
		loot_pending["charm_common"] = false
		give_item("charms", Loot.roll("charms", {"Common": 1.0}))
	if loot_pending.get("charm_uncommon", false):
		loot_pending["charm_uncommon"] = false
		give_item("charms", Loot.roll("charms", {"Uncommon": 1.0}))
	if loot_pending.get("artifact_rare", false) and e.elite:
		loot_pending["artifact_rare"] = false
		give_item("artifacts", Loot.roll("artifacts", {"Rare": 1.0}))

func _elite_loot(pos: Vector2) -> void:
	var s: Dictionary = Loot.source("elite")
	if randf() < float(s.get("charm_chance", 0.35)):
		give_item("charms", Loot.roll("charms", s.get("charm_tiers", {"Uncommon": 1.0})))
	if randf() < float(s.get("first_seen_artifact_chance", 0.35)):
		give_item("artifacts", Loot.roll("artifacts", s.get("artifact_tiers", {"Uncommon": 1.0}), true))
	var cnt: Array = s.get("reagent_count", [1, 2])
	for i in range(randi_range(int(cnt[0]), int(cnt[1]))):
		_drop_reagent(pos + Vector2(randf_range(-30, 30), randf_range(-30, 30)), s.get("reagent_tiers", {"Common": 1.0}))
	if randf() < float(s.get("characteristic_chance", 0.0015)):
		give_characteristic()
	var chance = float(s.get("formula_chance", 0.22)) + 0.05 * int(Store.d["fail_streak"])
	if randf() < chance:
		_find_formula(seq - 1)
	_drop("coin", pos, 6.0)

## Adds an item from the global pool to the account vault and reports it.
func give_item(kind: String, entry: Dictionary) -> void:
	if entry.is_empty():
		return
	var res: Dictionary = Loot.award(kind, entry)
	items_found.append(str(res["msg"]))
	hud.toast(str(res["msg"]), str(res["icon"]))
	Sound.play_sfx("coin" if res["dupe"] else "unlock", -4.0)

func give_characteristic() -> void:
	characteristics_found += 1
	Store.add_characteristic(1)
	items_found.append("Beyonder Characteristic")
	hud.toast("A Beyonder Characteristic condenses from the dead.", "star")
	Sound.play_sfx("charm_use")
	fx.flash(Color(0.8, 0.6, 1.0), 0.3)

func _find_formula(target: int = -1) -> void:
	var left = Store.undiscovered_formulas(pid)
	if left.is_empty():
		return
	var key: String = left[0]
	for k in left:
		if int(DB.formula(k).get("target", 0)) == target:
			key = k
			break
	Store.find_formula(key)
	formulas_found.append(key)
	hud.toast("Formula found: %s" % DB.formula(key).get("name", key), "scroll")
	Sound.play_sfx("unlock")

func collect(p: Node2D) -> void:
	match p.kind:
		"frag":
			insight_gain(p.value)
			Sound.play_sfx("pickup", -10.0, 1.0 + randf() * 0.3, 0.03)
		"coin":
			var v = int(round(p.value * float(stats["coin"]) * (1.0 + 0.0)))
			coins_run += maxi(1, v)
			Sound.play_sfx("coin", -8.0, 1.0, 0.04)
		"heart":
			player.hp = minf(player.max_hp, player.hp + p.value)
			fx.number(player.position, p.value, Color(0.5, 1.0, 0.6))
			Sound.play_sfx("heal", -4.0)
		"reagent":
			var rid: String = str(p.get_meta("rid", "salt"))
			Store.add_reagent(rid, 1)
			reagents_found[rid] = int(reagents_found.get(rid, 0)) + 1
			hud.toast("%s collected" % DB.reagent(rid).get("name", rid), p.ref)
			Sound.play_sfx("pickup", -4.0, 0.8)

func _pickups(delta: float) -> void:
	for p in pickups.duplicate():
		if not p.tick(delta, self):
			pickups.erase(p)
			p.queue_free()

func _projectiles(delta: float) -> void:
	for p in projs.duplicate():
		if not is_instance_valid(p) or not p.tick(delta, self):
			projs.erase(p)
			if is_instance_valid(p):
				p.queue_free()

# ───────────────────────── progression ─────────────────────────
func need_for(lv: int) -> float:
	return 9.0 + lv * 3.0 + pow(float(lv), 1.45) * 0.5

func insight_gain(v: float) -> void:
	var gain = v * float(stats["insight"]) * (1.0 + (9 - seq) * 0.30 + time / 900.0)
	if level >= MAX_LEVEL:
		coins_run += int(gain * 0.5)
		return
	insight += gain
	while insight >= need and not over and level < MAX_LEVEL:
		insight -= need
		level += 1
		need = need_for(level)
		_level_up()
		if draft_open:
			break
	if level >= MAX_LEVEL:
		insight = 0.0

func _level_up() -> void:
	player.max_hp += 2.0
	player.hp = minf(player.max_hp, player.hp + 4.0)
	rite_dmg += 0.01
	if level % 10 == 0:
		_milestone()
	Sound.play_sfx("levelup")
	fx.ring(player_center(), Color(1.0, 0.9, 0.5), 220.0, 0.6)
	fx.burst(player_center(), Color(1.0, 0.85, 0.4), 24, 240.0, 0.8, 0.3)
	_open_draft()

func _open_draft() -> void:
	if draft_open:
		return
	draft_open = true
	get_tree().paused = true
	var d = DraftS.new()
	d.run = self
	hud.add_child(d)

func _milestone() -> void:
	player.hp = player.max_hp
	rite_dmg += 0.05
	if level % 20 == 0:
		rerolls += 1
	diamonds_run += 1
	hud.announce("Level %d" % level, "Milestone: fully restored, +5% damage, +1 Diamond")
	fx.flash(Color(1, 0.95, 0.7), 0.3)
	fx.ring(player_center(), Color(1, 0.9, 0.5), 520.0, 0.9)
	Sound.play_sfx("victory", -6.0)

func draft_options() -> Array:
	var opts: Array = []
	var seeds = DB.abilities_of(pid)
	var owned_ids: Array = []
	for a in abilities:
		owned_ids.append(a["id"])
	var pool: Array = []
	for i in seeds.size():
		var s: Dictionary = seeds[i]
		if not (s["id"] in owned_ids) and abilities.size() < 6 and seq <= 9 - int(i / 2.0) + 1:
			pool.append({"type": "new", "id": s["id"], "name": s["name"], "icon": _kind_icon(s["kind"]), "desc": s["desc"], "level": 0, "def": s})
	for a in abilities:
		if int(a["level"]) < MAX_ABILITY_LEVEL:
			pool.append({"type": "up", "id": a["id"], "name": a["name"], "icon": _kind_icon(a["kind"]), "desc": "Level %d → %d. %s" % [int(a["level"]), int(a["level"]) + 1, a["desc"]], "level": int(a["level"])})
	for r in GENERIC_RITES:
		pool.append({"type": "rite", "id": r[0], "name": r[1], "icon": r[2], "desc": r[3], "level": 0})
	pool.shuffle()
	var want = int(stats["choices"])
	# guarantee at least one ability option when possible
	var has_ab = false
	for o in pool.slice(0, want):
		if o["type"] != "rite":
			has_ab = true
	opts = pool.slice(0, want)
	if not has_ab:
		for o in pool:
			if o["type"] != "rite":
				opts[want - 1] = o
				break
	return opts

func _kind_icon(kind: String) -> String:
	const Cab = preload("res://scripts/sections/cabinet.gd")
	return Cab._icon_for(kind)

func choose(opt: Dictionary) -> void:
	match opt["type"]:
		"new":
			add_ability(opt["def"])
		"up":
			for a in abilities:
				if a["id"] == opt["id"]:
					a["level"] = int(a["level"]) + 1
					if a["kind"] == "fate":
						rerolls += 1
					if a["kind"] == "fork":
						rerolls += 1
			_recompute_passives()
		"rite":
			match opt["id"]:
				"vitality":
					player.max_hp += 20.0
					player.hp = minf(player.max_hp, player.hp + 20.0)
				"haste": rite_speed += 0.08
				"lens":
					stats["pickup"] = float(stats["pickup"]) + 0.15
					_recompute_passives()
				"ward": dmg_taken_mult *= 0.92
				"gold": stats["coin"] = float(stats["coin"]) + 0.15
				"veil": stats["dash_cd"] = float(stats["dash_cd"]) * 0.9
				"might": rite_dmg += 0.08
	draft_open = false
	get_tree().paused = false
	# chained level ups
	if insight >= need:
		insight_gain(0.0)

func end_draft_reroll() -> bool:
	if rerolls <= 0:
		Sound.play_sfx("ui_error")
		return false
	rerolls -= 1
	Sound.play_sfx("fate_reroll")
	return true

# ───────────────────────── sequences & gates ─────────────────────────
func _seq_for_level() -> int:
	var s = 9
	for k in SEQ_LEVELS.keys():
		if level >= int(SEQ_LEVELS[k]):
			s = mini(s, int(k))
	return s

func _sequence_check() -> void:
	if boss != null or seq <= 1 or over:
		return
	var target = _seq_for_level()
	if target >= seq:
		return
	var nxt = seq - 1
	if nxt in DB.GATES:
		if not Store.gate_ready(pid, nxt):
			if not blocked_notice:
				blocked_notice = true
				hud.toast("Sequence %d is sealed. Find its Formula and brew the potion." % nxt, "lock")
				Sound.play_sfx("ui_error")
			return
		blocked_notice = false
		seq = nxt
		gates_passed += 1
		_apply_place()
		_spawn_boss(nxt)
	else:
		seq = nxt
		_apply_place()
		hud.announce("Sequence %d — %s" % [seq, DB.title_for(pid, seq)], str(place.get("name", "")))
		Sound.play_sfx("gate_open", -4.0)
		fx.flash(Color(1, 0.9, 0.6), 0.25)
		fx.ring(player_center(), Color(1, 0.9, 0.6), 400.0, 0.8)

func _spawn_boss(gate: int) -> void:
	boss_gate = gate
	var hp_by = {6: 900.0, 2: 2600.0, 1: 5200.0}
	var d: Dictionary = TYPES["boss"].duplicate()
	d["hp"] = float(hp_by.get(gate, 900.0)) * (0.8 + 0.2 * diff)
	d["dmg"] = 14.0 + (6 - gate) * 1.5
	var e: Node2D = EnemyS.new()
	e.setup("boss", d, 1.0, 1.0)
	e.is_boss = true
	e.behaviour = "boss"
	e.position = player.position + Vector2.from_angle(randf() * TAU) * 520.0
	add_child(e)
	enemies.append(e)
	boss = e
	boss_pattern_t = 2.5
	var names = {6: "%s's Echo" % DB.title_for(pid, 6), 2: "Warden of the Veil", 1: str(path["boss"])}
	hud.show_boss(str(names.get(gate, "Guardian")))
	hud.announce("Gate of Sequence %d" % gate, str(names.get(gate, "")))
	Sound.play_music("boss_theme")
	Sound.play_sfx("boss_appear")
	fx.flash(Color(0.6, 0.1, 0.2), 0.35)
	fx.shake(10.0)

func boss_tick(e: Node2D, delta: float) -> void:
	var to: Vector2 = player.position - e.position
	var d = to.length()
	var dir = to / maxf(d, 0.01)
	if d > 300.0:
		e.position += dir * e.speed * enemy_speed_mult * delta
	else:
		e.position += dir.rotated(PI / 2.0) * e.speed * 0.5 * delta
	e.sprite.flip_h = dir.x < 0.0
	e.phase_t -= delta
	var c: Vector2 = e.position + Vector2(0, -60)
	match str(path.get("bossPattern", "solar")):
		"solar":
			if e.phase_t <= 0.0:
				e.phase += 1
				e.phase_t = 2.4
				if e.phase % 3 == 0:
					for i in 3:
						_boss_shot(c, player_center(), 11.0, 300.0, (i - 1) * 0.18)
					Sound.play_sfx("shoot_ember", -2.0, 0.7)
				else:
					fx.ring(c, Color(1.0, 0.6, 0.3), 120.0, 0.5)
					Sound.play_sfx("telegraph", -6.0)
					for i in 12:
						_boss_shot(c, c + Vector2.from_angle(TAU * i / 12.0 + e.phase * 0.2), 10.0, 230.0, 0.0)
		"mirrors":
			if e.phase_t <= 0.0:
				e.phase += 1
				e.phase_t = 2.0
				for i in 3:
					_boss_shot(c, player_center(), 10.0, 320.0, (i - 1) * 0.22)
				Sound.play_sfx("shoot_shard", -2.0, 0.7)
				if e.phase % 4 == 0:
					for i in 2:
						spawn_enemy("husk", e.position + Vector2.from_angle(randf() * TAU) * 80.0, false)
					fx.ring(c, Color(0.7, 0.7, 1.0), 140.0, 0.5)
		_:
			e.spiral += delta * 3.0
			if e.phase_t <= 0.0:
				e.phase += 1
				e.phase_t = 0.2
				_boss_shot(c, c + Vector2.from_angle(e.spiral), 9.0, 250.0, 0.0)
				_boss_shot(c, c + Vector2.from_angle(e.spiral + PI), 9.0, 250.0, 0.0)
				if e.phase % 30 == 0:
					Sound.play_sfx("telegraph", -6.0)
					var p = _boss_shot(c, player_center(), 8.0, 200.0, 0.0)
					p.slow_player = 1.5

func _boss_shot(from: Vector2, target: Vector2, dmg: float, speed: float, spread: float) -> Node2D:
	var p: Node2D = ProjS.new()
	p.vel = (target - from).normalized().rotated(spread) * speed
	p.dmg = dmg * (0.85 + 0.15 * diff)
	p.hostile = true
	p.life = 6.0
	p.radius = 10.0
	p.position = from
	p.setup("res://assets/sprites/bolt.png", Color(1.0, 0.4, 0.35), 0.9)
	add_child(p)
	projs.append(p)
	return p

func enemy_shoot(e: Node2D, n: int, dmg: float) -> void:
	var c: Vector2 = e.position + Vector2(0, -30)
	for i in n:
		_boss_shot(c, player_center(), dmg, 220.0, (i - (n - 1) / 2.0) * 0.2)
	Sound.play_sfx("shoot_shard", -10.0, 0.8)

func _boss_down(e: Node2D) -> void:
	bosses_down += 1
	boss = null
	hud.hide_boss()
	diamonds_run += 3
	Sound.play_sfx("victory", -2.0)
	fx.flash(Color(1, 0.95, 0.7), 0.5)
	fx.ring(e.position, Color(1, 0.9, 0.6), 500.0, 1.0)
	fx.shake(14.0)
	for i in 12:
		_drop("coin", e.position + Vector2.from_angle(TAU * i / 12.0) * 40.0, 5.0)
	var bg: Dictionary = Loot.source("boss_gate")
	var fb: Dictionary = Loot.source("final_boss")
	if boss_gate == 1:
		for i in int(fb.get("characteristic", 1)):
			give_characteristic()
		give_item("artifacts", Loot.roll("artifacts", fb.get("artifact_tiers", {"Epic": 1.0})))
	else:
		if not gate_loot.has(boss_gate):
			gate_loot[boss_gate] = true
			give_item("artifacts", Loot.roll("artifacts", bg.get("artifact_tiers", {"Rare": 1.0})))
			_find_formula(boss_gate - 1)
	for i in int(bg.get("reagents", 2)):
		_drop_reagent(e.position + Vector2.from_angle(randf() * TAU) * 50.0, {"Rare": 0.8, "Common": 0.2})
	if boss_gate == 1:
		victory = true
		get_tree().create_timer(1.6).timeout.connect(_end.bind(true))
	else:
		Sound.play_music("run_" + pid)
		hud.toast("The gate opens. Press on.", "unlock")

func _camera(delta: float) -> void:
	var off = Vector2.ZERO
	if fx.shake_amt > 0.1:
		off = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * fx.shake_amt
		fx.shake_amt = lerpf(fx.shake_amt, 0.0, 8.0 * delta)
	cam.position = player.position + Vector2(0, -30)
	cam.offset = off
	ground.position = Vector2(round(cam.position.x / 512.0) * 512.0, round(cam.position.y / 512.0) * 512.0)

func _end(won: bool) -> void:
	if over:
		return
	over = true
	Sound.stop_ambience()
	if won:
		Sound.play_sfx("victory")
	else:
		Sound.play_sfx("death")
		fx.flash(Color(0.4, 0.0, 0.0), 0.5)
	star_gains = Store.record_ability_stats(pid, ab_run)
	var coins_bonus = int(time / 10.0)
	var total_coins = coins_run + coins_bonus + (150 if won else 0)
	var dia = diamonds_run + (20 if won else 0)
	Store.d["runs"] = int(Store.d["runs"]) + 1
	Store.d["kills"] = int(Store.d["kills"]) + kills
	Store.d["coins"] = int(Store.d["coins"]) + total_coins
	Store.d["diamonds"] = int(Store.d["diamonds"]) + dia
	if won:
		Store.d["wins"] = int(Store.d["wins"]) + 1
		Store.d["fail_streak"] = 0
	else:
		Store.d["fail_streak"] = int(Store.d["fail_streak"]) + 1
	var reached = 0 if won else seq
	var prev = int(Store.d["deepest"].get(pid, 10))
	Store.d["deepest"][pid] = mini(prev, reached)
	Store.d["best_time"] = maxf(float(Store.d["best_time"]), time)
	var wk: Dictionary = Store.d["weekly"]
	if str(wk.get("week", "")) != Store.week_key():
		wk = {"week": Store.week_key(), "kills": 0, "best_seq": 9, "claimed": []}
		Store.d["weekly"] = wk
	wk["kills"] = int(wk["kills"]) + kills
	wk["best_seq"] = mini(int(wk["best_seq"]), reached)
	Store.commit()
	get_tree().paused = true
	var r = ResultS.new()
	r.run = self
	r.won = won
	r.total_coins = total_coins
	r.total_dia = dia
	hud.add_child(r)
