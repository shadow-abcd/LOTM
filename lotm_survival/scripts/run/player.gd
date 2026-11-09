extends Node2D
## The player body. Movement/dash/hurt state; the Run script drives tick().
## The visible character is now a fully 3D model (character3d.gd) rendered live
## through a transparent viewport; movement, hitbox and stats are unchanged.

const Character3D = preload("res://scripts/run/character3d.gd")

var hp = 100.0
var max_hp = 100.0
var speed = 190.0
var radius = 12.0
var invuln = 0.0
var dash_t = 0.0
var dash_cd_t = 0.0
var dash_dir = Vector2.RIGHT
var shield = 0
var flash = 0.0
var stationary = 0.0
var slow_mult = 1.0
var face = 1.0
var moving = false
var _t = 0.0
var char3d = null
var glow: Sprite2D

func setup(pid: String, accent: Color) -> void:
	var sh = Sprite2D.new()
	sh.texture = UI.tex("res://assets/sprites/shadow.png")
	sh.position = Vector2(0, 4)
	sh.scale = Vector2(0.9, 0.9)
	add_child(sh)
	glow = Sprite2D.new()
	glow.texture = UI.tex("res://assets/sprites/glow.png")
	glow.modulate = Color(accent.r, accent.g, accent.b, 0.35)
	glow.position = Vector2(0, -44)
	glow.scale = Vector2(1.5, 1.8)
	var m = CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	glow.material = m
	add_child(glow)
	char3d = Character3D.new()
	char3d.setup(pid, accent)
	add_child(char3d)

func tick(delta: float, dir: Vector2, spd_mult: float) -> void:
	_t += delta
	invuln = maxf(0.0, invuln - delta)
	dash_cd_t = maxf(0.0, dash_cd_t - delta)
	flash = maxf(0.0, flash - delta * 4.0)
	if dash_t > 0.0:
		dash_t -= delta
		position += dash_dir * 560.0 * delta
	else:
		position += dir * speed * spd_mult * slow_mult * delta
	moving = dir.length() > 0.1
	if moving:
		stationary = 0.0
		if absf(dir.x) > 0.1:
			face = signf(dir.x)
	else:
		stationary += delta
	if char3d != null:
		char3d.flip_h = face < 0.0
		char3d.position.y = -absf(sin(_t * 11.0)) * 3.0 if moving else sin(_t * 2.0) * 1.2
	var a = 1.0
	if invuln > 0.0:
		a = 0.55 + 0.25 * sin(_t * 40.0)
	if char3d != null:
		char3d.modulate = Color(1.0, 1.0 - flash * 0.7, 1.0 - flash * 0.7, a)
	glow.modulate.a = 0.28 + 0.1 * sin(_t * 3.0)

func try_dash(dir: Vector2, cd: float, duration: float) -> bool:
	if dash_cd_t > 0.0 or dash_t > 0.0:
		return false
	dash_dir = dir if dir.length() > 0.1 else Vector2(face, 0.0)
	dash_dir = dash_dir.normalized()
	dash_t = 0.18
	invuln = maxf(invuln, duration)
	dash_cd_t = cd
	return true
