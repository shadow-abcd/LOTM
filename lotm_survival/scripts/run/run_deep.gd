extends "res://scripts/run/run.gd"
## Combat depth + performance + VFX-polish layer for the descent. Extends the
## battle-tested loop without touching it: signature pathway abilities, potions
## establishing the signature at run start, roaming Formula bearers, object
## pooling for projectiles & pickups, and Phase B combat polish (hit-stop,
## layered death bursts, boss muzzle telegraphs).

const FxPolishS = preload("res://scripts/run/fx_polish.gd")

const SIGNATURE_KINDS := ["flame_wave", "starfall", "mirror_world"]

var bearer_t := 95.0
var _proj_pool: Array = []
var _pickup_pool: Array = []

func _ready() -> void:
	super._ready()
	# Phase B: swap in the polished FX layer (hit-stop, death bursts, telegraphs).
	if fx != null and fx is FxPolishS:
		pass
	else:
		var old_fx = fx
		remove_child(old_fx)
		old_fx.queue_free()
		var new_fx: Node2D = FxPolishS.new()
		new_fx.run = self
		new_fx.z_index = 20
		add_child(new_fx)
		fx = new_fx
	_connect_potion_abilities()

# ───────── signature pathway abilities ─────────

func _signature_ability() -> Dictionary:
	for s in DB.abilities_of(pid):
		if str(s["kind"]) in SIGNATURE_KINDS:
			return s
	return {}

## Potion establishment: every potion brewed on this pathway stirs the pathway's
## signature ability at descent start. 1 potion = Lv 1, 2 = Lv 2, 3+ = Lv 3.
func _connect_potion_abilities() -> void:
	var brewed := 0
	for key in Store.d["potions"]:
		var f: Dictionary = DB.formula(str(key))
		if not f.is_empty() and str(f.get("pathway", "")) == pid:
			brewed += 1
	if brewed <= 0:
		return
	var sig := _signature_ability()
	if sig.is_empty():
		return
	add_ability(sig, false)
	for a in abilities:
		if str(a["id"]) == str(sig["id"]):
			a["level"] = mini(3, brewed)
			break
	hud.toast("%s answers your potions." % str(sig["name"]), "potion")
	Sound.play_sfx("potion_done", -6.0)

func _has_target(a: Dictionary) -> bool:
	if str(a["kind"]) in SIGNATURE_KINDS:
		return nearest(player_center(), 560.0) != null
	return super._has_target(a)

func cast(a: Dictionary) -> void:
	if str(a["kind"]) in SIGNATURE_KINDS:
		_cast_signature(a)
	else:
		super.cast(a)

func _cast_signature(a: Dictionary) -> void:
	cast_count += 1
	_cur_aid = str(a["id"])
	_ab_add(_cur_aid, "casts", 1)
	var l := int(a["level"])
	var dmg := ability_damage(a)
	var el: String = a["element"]
	var col: Color = DB.ELEMENT_COLORS.get(el, Color.WHITE)
	var c := player_center()
	if quill_charges > 0:
		dmg *= 2.0
		quill_charges -= 1
	wake_near(c)
	match str(a["kind"]):
		"flame_wave":
			var r := minf(560.0, 300.0 + 30.0 * l)
			fx.ring(c, col, r, 0.7)
			fx.glow_pop(c, col, r * 0.9, 0.5)
			fx.burst(c, col, 26, r, 0.8, 0.3)
			Sound.play_sfx("cast_pulse", -2.0)
			var hits := 0
			for e in enemies_near(c, r):
				damage_enemy(e, dmg, el, "pulse")
				hits += 1
			if hits > 0:
				var heal := 2.0 * minf(hits, 8)
				player.hp = minf(player.max_hp, player.hp + heal)
				fx.number(player.position + Vector2(0, -30), heal, Color(0.5, 1.0, 0.6))
		"starfall":
			var n := 4 + l
			for i in n:
				var ang := TAU * float(i) / float(n) + time
				var at := c + Vector2.from_angle(ang) * randf_range(120.0, 320.0)
				get_tree().create_timer(0.1 + 0.12 * float(i)).timeout.connect(_starfall_strike.bind(at, dmg, el, _cur_aid))
		"mirror_world":
			var r := minf(520.0, 320.0 + 20.0 * l)
			fx.ring(c, col, r, 0.8)
			fx.flash(Color(0.45, 0.3, 0.7), 0.25)
			Sound.play_sfx("cast_aura", -4.0)
			for e in enemies_near(c, r):
				e.frozen = 1.2 + 0.2 * l
				e.set_marked(time + 6.0)
				damage_enemy(e, dmg, el, "sleep")
			if stored_wound > 0.0:
				var boom := stored_wound
				stored_wound = 0.0
				fx.ring(c, Color(0.7, 0.4, 1.0), r, 0.5)
				fx.shake(8.0)
				for e in enemies_near(c, r):
					damage_enemy(e, boom * 2.0, "gloom", "wound")
	_cur_aid = ""

func _starfall_strike(at: Vector2, dmg: float, el: String, aid: String) -> void:
	if over:
		return
	_cur_aid = aid
	var col: Color = DB.ELEMENT_COLORS.get(el, Color.WHITE)
	fx.burst(at, col, 10, 180.0, 0.4, 0.25)
	fx.glow_pop(at, col, 95.0, 0.25)
	Sound.play_sfx("boss_hit", -10.0, 1.8)
	for e in enemies_near(at, 95.0):
		damage_enemy(e, dmg, el, "sigil")
	_cur_aid = ""

# ───────── Formula bearers ─────────

func _timers(delta: float) -> void:
	super._timers(delta)
	bearer_t -= delta
	if bearer_t <= 0.0 and boss == null and not over:
		bearer_t = 95.0
		_spawn_formula_bearer()

func _spawn_formula_bearer() -> void:
	var left: Array = Store.undiscovered_formulas(pid)
	if left.is_empty():
		return
	var e := spawn_enemy("grafter", _ring_pos(), false)
	e.make_elite()
	e.set_meta("formula_bearer", true)
	var badge := Sprite2D.new()
	badge.texture = UI.icon("scroll")
	badge.modulate = Color(1.0, 0.9, 0.5)
	badge.scale = Vector2(0.35, 0.35)
	badge.position = Vector2(0, -e.radius * 3.6 - 8.0)
	e.add_child(badge)
	hud.toast("A Formula bearer crosses the field — strike it down to claim its secret.", "scroll")
	Sound.play_sfx("telegraph", -8.0)
	fx.ring(e.position, Color(1.0, 0.9, 0.5), 140.0, 0.6)

func kill_enemy(e: Node2D) -> void:
	var was_bearer: bool = e.has_meta("formula_bearer")
	super.kill_enemy(e)
	if was_bearer:
		_find_formula(-1)
		hud.toast("The bearer's note dissolves into knowledge.", "scroll")
		fx.flash(Color(1.0, 0.95, 0.7), 0.2)
		Sound.play_sfx("unlock", -2.0)

## Phase B: hit-stop + layered death burst on heavy kills (elite, boss, bearer).
func _boss_down(e: Node2D) -> void:
	super._boss_down(e)
	fx.hitstop(0.09, 0.25)
	fx.death_burst(e.position, Color(1.0, 0.85, 0.4), true)

func _elite_loot(pos: Vector2) -> void:
	super._elite_loot(pos)
	fx.death_burst(pos, Color(1.0, 0.7, 0.3), false)
	fx.hitstop(0.05, 0.35)

# ───────── object pooling ─────────

func _pooled_proj() -> Node2D:
	while not _proj_pool.is_empty():
		var p: Node2D = _proj_pool.pop_back()
		if is_instance_valid(p):
			if not p.is_inside_tree():
				add_child(p)
			return p
	var fresh: Node2D = ProjS.new()
	add_child(fresh)
	return fresh

func _return_proj(p: Node2D) -> void:
	if not is_instance_valid(p):
		return
	if p.is_inside_tree():
		remove_child(p)
	if _proj_pool.size() < 90:
		_proj_pool.append(p)
	else:
		p.queue_free()

func _pooled_pickup() -> Node2D:
	while not _pickup_pool.is_empty():
		var p: Node2D = _pickup_pool.pop_back()
		if is_instance_valid(p):
			if not p.is_inside_tree():
				add_child(p)
			return p
	var fresh: Node2D = PickupS.new()
	add_child(fresh)
	return fresh

func _return_pickup(p: Node2D) -> void:
	if not is_instance_valid(p):
		return
	if p.is_inside_tree():
		remove_child(p)
	if _pickup_pool.size() < 260:
		_pickup_pool.append(p)
	else:
		p.queue_free()

## Phase B: muzzle telegraph where hostile shots originate, so volleys are readable.
func _boss_shot(from: Vector2, target: Vector2, dmg: float, speed: float, spread: float) -> Node2D:
	fx.muzzle_telegraph(from, Color(1.0, 0.4, 0.35))
	return super._boss_shot(from, target, dmg, speed, spread)

func _fire(from: Vector2, target: Vector2, dmg: float, el: String, speed: float = 520.0, pierce: int = 0, spread: float = 0.0) -> void:
	var p: Node2D = _pooled_proj()
	var dir = (target - from).normalized().rotated(spread)
	p.reconfigure(from, "res://assets/sprites/bolt.png", DB.ELEMENT_COLORS.get(el, Color.WHITE), 0.7)
	p.vel = dir * speed
	p.dmg = dmg
	p.pierce = pierce
	p.life = 1.6
	p.element = el
	p.aid = _cur_aid
	p.rotation = dir.angle()
	projs.append(p)

func _drop(kind: String, pos: Vector2, v: float, ref: String = "", color: Color = Color.WHITE) -> void:
	if pickups.size() > 260 and kind == "frag":
		insight_gain(v)
		return
	var p: Node2D = _pooled_pickup()
	p.reconfigure(pos, kind, v, ref, color)
	pickups.append(p)

func _projectiles(delta: float) -> void:
	for p in projs.duplicate():
		if not is_instance_valid(p) or not p.tick(delta, self):
			projs.erase(p)
			if is_instance_valid(p):
				_return_proj(p)

func _pickups(delta: float) -> void:
	for p in pickups.duplicate():
		if not p.tick(delta, self):
			pickups.erase(p)
			_return_pickup(p)

# ───────── performance: capped spawning ─────────

func _spawn(delta: float) -> void:
	var cap = Cfg.enemy_cap()
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
