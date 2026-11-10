extends Node2D
## A projectile (friendly or hostile). Run drives tick(); returns false when it should be removed.
## Pool-friendly: reconfigure() reuses the existing sprite + material instead of rebuilding.
## Phase B: optional elemental trail (High particles quality only, skipped in performance mode).

var vel = Vector2.ZERO
var dmg = 10.0
var pierce = 0
var life = 2.0
var radius = 10.0
var hostile = false
var element = "ember"
var crit_ok = true
var hit_ids: Dictionary = {}
var sprite: Sprite2D
var slow_player = 0.0
var aid = ""
var trail: CPUParticles2D

func setup(tex_path: String, color: Color, sc: float) -> void:
	sprite = Sprite2D.new()
	sprite.texture = UI.tex(tex_path)
	sprite.modulate = color
	sprite.scale = Vector2(sc, sc)
	var m = CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	sprite.material = m
	add_child(sprite)
	rotation = vel.angle()

func _ensure_trail() -> void:
	if trail != null:
		return
	trail = CPUParticles2D.new()
	trail.texture = UI.tex("res://assets/sprites/spark.png")
	trail.amount = 10
	trail.lifetime = 0.28
	trail.explosiveness = 0.0
	trail.emitting = false
	trail.direction = Vector2.ZERO
	trail.spread = 180.0
	trail.gravity = Vector2.ZERO
	trail.initial_velocity_min = 4.0
	trail.initial_velocity_max = 14.0
	trail.scale_amount_min = 0.10
	trail.scale_amount_max = 0.18
	trail.local_coords = true
	add_child(trail)

## Pool entry: reset all state for reuse without allocating a new sprite or material.
func reconfigure(from: Vector2, tex_path: String, color: Color, sc: float) -> void:
	position = from
	if sprite == null:
		setup(tex_path, color, sc)
		return
	var t: Texture2D = UI.tex(tex_path)
	if sprite.texture != t:
		sprite.texture = t
	sprite.modulate = color
	sprite.scale = Vector2(sc, sc)
	vel = Vector2.ZERO
	dmg = 10.0
	pierce = 0
	life = 2.0
	radius = 10.0
	hostile = false
	element = "ember"
	crit_ok = true
	slow_player = 0.0
	aid = ""
	hit_ids.clear()
	# Phase B: elemental trail at High quality only — skipped on low-end presets.
	var want_trail: bool = int(Cfg.get_v("particles")) >= 2 and not bool(Cfg.get_v("performance_mode"))
	if want_trail:
		_ensure_trail()
	if trail != null:
		trail.color = color
		trail.emitting = want_trail

func tick(delta: float, run) -> bool:
	position += vel * delta
	life -= delta
	if life <= 0.0:
		return false
	if hostile:
		if position.distance_to(run.player.position + Vector2(0, -24)) < radius + run.player.radius:
			run.hurt_player(dmg, null)
			if slow_player > 0.0:
				run.slow_player(slow_player)
			return false
		return true
	for e in run.enemies_near(position, radius + 6.0):
		var id: int = e.get_instance_id()
		if hit_ids.has(id):
			continue
		hit_ids[id] = true
		run.damage_enemy(e, dmg, element, "proj", aid)
		if pierce <= 0:
			return false
		pierce -= 1
	return true
