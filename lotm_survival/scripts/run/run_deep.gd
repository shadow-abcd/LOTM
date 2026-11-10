extends "res://scripts/run/run.gd"
## Combat depth layer for the descent. Extends the battle-tested run loop without
## touching it: signature pathway abilities (Flame of Purification / Starfall
## Judgment / Mirror World), potions establishing the signature at run start,
## and roaming Formula bearers that carry undiscovered Formulas.

const SIGNATURE_KINDS := ["flame_wave", "starfall", "mirror_world"]

var bearer_t := 95.0

func _ready() -> void:
	super._ready()
	_connect_potion_abilities()

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
			# Red Priest: a ring of purifying fire expands, burning everything it
			# touches and restoring vitality per enemy scorched.
			var r := minf(560.0, 300.0 + 30.0 * l)
			fx.ring(c, col, r, 0.7)
			fx.glow_pop(c, col, r * 0.9, 0.5)
			fx.burst(c, col, 26, r, 0.8, 0.3)
			fx.shake(6.0 + l)
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
			# Hermit: falling stars bombard the crowd, each impact bursting.
			var n := 4 + l
			for i in n:
				var ang := TAU * float(i) / float(n) + time
				var at := c + Vector2.from_angle(ang) * randf_range(120.0, 320.0)
				get_tree().create_timer(0.1 + 0.12 * float(i)).timeout.connect(_starfall_strike.bind(at, dmg, el, _cur_aid))
		"mirror_world":
			# Demoness: the crowd is pulled into the Mirror World — frozen, marked
			# and struck; stored wounds detonate inside the ring.
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

func _timers(delta: float) -> void:
	super._timers(delta)
	bearer_t -= delta
	if bearer_t <= 0.0 and boss == null and not over:
		bearer_t = 95.0
		_spawn_formula_bearer()

## Formula discovery encounter: a sealed courier roams the field, carrying the
## next undiscovered Formula of your pathway. Strike it down to claim the secret.
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
