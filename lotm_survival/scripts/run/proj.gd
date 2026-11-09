extends Node2D
## A projectile (friendly or hostile). Run drives tick(); returns false when it should be removed.

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
