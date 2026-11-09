extends Node2D
## An enemy body. Movement + special behaviours; attacks and drops are handled by Run.

var kind = "husk"
var hp = 10.0
var max_hp = 10.0
var speed = 60.0
var dmg = 8.0
var radius = 14.0
var xp = 1.0
var elite = false
var is_boss = false
var is_mini = false
var marked_until = 0.0
var frozen = 0.0
var slow = 0.0
var hit_cd = 0.0
var flash = 0.0
var awake = true
var behaviour = "chase"
var weak: Array = []
var resist: Array = []
var group: Array = []         # reciting choir: shared list
var order = 0
var t = 0.0
var shoot_t = 2.0
var lit = 0
var copies = 0
var climbed = 0.0
var replay: Array = []
var replay_i = 0.0
var grow = 1.0
var base_scale = 1.0
var sprite: Sprite2D
var mark_sprite: Sprite2D
var elite_sprite: Sprite2D
var order_label: Label
var phase = 0
var phase_t = 0.0
var spiral = 0.0

func setup(id: String, d: Dictionary, hp_scale: float, dmg_scale: float) -> void:
	kind = id
	max_hp = float(d["hp"]) * hp_scale
	hp = max_hp
	speed = float(d["speed"])
	dmg = float(d["dmg"]) * dmg_scale
	radius = float(d["r"])
	xp = float(d["xp"])
	behaviour = str(d.get("behaviour", "chase"))
	weak = d.get("weak", [])
	resist = d.get("resist", [])
	awake = behaviour != "sound"
	var tex_name: String = str(d.get("tex", id))
	var sh = Sprite2D.new()
	sh.texture = UI.tex("res://assets/sprites/shadow.png")
	sh.position = Vector2(0, 2)
	sh.scale = Vector2(radius / 16.0, radius / 16.0)
	add_child(sh)
	sprite = Sprite2D.new()
	var tx: Texture2D = UI.tex("res://assets/sprites/enemy_%s.png" % tex_name)
	if tx == null:
		tx = UI.tex("res://assets/sprites/enemy_husk.png")
	sprite.texture = tx
	base_scale = radius * 3.4 / 128.0
	if tx != null:
		base_scale = radius * 3.4 / float(tx.get_width())
	sprite.scale = Vector2(base_scale, base_scale)
	sprite.offset = Vector2(0, -52)
	add_child(sprite)
	if Cfg.get_v("high_contrast"):
		sprite.modulate = Color(1.25, 1.25, 1.25)

func make_elite() -> void:
	elite = true
	max_hp *= 5.0
	hp = max_hp
	radius *= 1.35
	dmg *= 1.4
	xp *= 6.0
	base_scale *= 1.35
	sprite.scale = Vector2(base_scale, base_scale)
	elite_sprite = Sprite2D.new()
	elite_sprite.texture = UI.icon("sigil")
	elite_sprite.modulate = Color(1.0, 0.86, 0.45)
	elite_sprite.scale = Vector2(0.4, 0.4)
	elite_sprite.position = Vector2(0, -radius * 3.6 - 14.0)
	var m = CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	elite_sprite.material = m
	add_child(elite_sprite)
	if Cfg.get_v("colorblind"):
		var d = Sprite2D.new()
		d.texture = UI.icon("crown")
		d.scale = Vector2(0.3, 0.3)
		d.position = Vector2(0, -radius * 3.6 - 40.0)
		add_child(d)

func show_order(n: int) -> void:
	order = n
	order_label = Label.new()
	order_label.text = "●".repeat(n)
	order_label.add_theme_font_size_override("font_size", 14)
	order_label.position = Vector2(-24, -radius * 3.6 - 22.0)
	order_label.custom_minimum_size = Vector2(48, 0)
	order_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(order_label)

func set_marked(until: float) -> void:
	marked_until = until
	if mark_sprite == null:
		mark_sprite = Sprite2D.new()
		mark_sprite.texture = UI.icon("sigil")
		mark_sprite.modulate = Color(1.0, 0.45, 0.3, 0.85)
		mark_sprite.scale = Vector2(0.3, 0.3)
		mark_sprite.position = Vector2(0, -6)
		var m = CanvasItemMaterial.new()
		m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		mark_sprite.material = m
		add_child(mark_sprite)

func hit_flash() -> void:
	flash = 1.0

func tick(delta: float, run) -> void:
	t += delta
	hit_cd = maxf(0.0, hit_cd - delta)
	flash = maxf(0.0, flash - delta * 6.0)
	if mark_sprite != null:
		mark_sprite.rotation += delta * 2.0
		if run.time > marked_until:
			mark_sprite.queue_free()
			mark_sprite = null
	if elite_sprite != null:
		elite_sprite.rotation += delta
	var tint = Color(1, 1, 1)
	if flash > 0.0:
		tint = Color(1.0 + flash, 1.0 + flash * 0.8, 1.0 + flash * 0.8)
	if frozen > 0.0:
		tint = tint * Color(0.6, 0.85, 1.3)
	sprite.modulate = tint
	if frozen > 0.0:
		frozen -= delta
		return
	var spd = speed * run.enemy_speed_mult * (1.0 - clampf(slow, 0.0, 0.8))
	slow = maxf(0.0, slow - delta * 0.5)
	var to: Vector2 = run.player.position - position
	var dist = to.length()
	var dir = to / maxf(dist, 0.01)
	match behaviour:
		"sound":
			if not awake:
				sprite.rotation = sin(t * 0.8) * 0.02
				return
			position += dir * spd * delta
		"ascend":
			climbed += 30.0 * delta
			position.y -= 30.0 * delta
			position.x += dir.x * 18.0 * delta
			if not is_mini and climbed > 520.0:
				is_mini = true
				max_hp *= 8.0
				hp = max_hp
				base_scale *= 1.7
				radius *= 1.7
				sprite.scale = Vector2(base_scale, base_scale)
				run.fx.ring(global_position, Color(0.5, 0.8, 1.0), 220.0, 0.6)
				run.toast_world("The Slow Ascender reached the top.", "bestiary")
		"order":
			position += dir * spd * delta
		"mirror":
			if replay_i < float(replay.size()):
				replay_i += delta * 20.0
				var i = mini(int(replay_i), replay.size() - 1)
				position = replay[i]
				sprite.modulate.a = 0.75
			else:
				grow += 0.01 * delta
				sprite.scale = Vector2(base_scale * grow, base_scale * grow)
				position += dir * spd * delta
		"graft":
			if dist > 220.0:
				position += dir * spd * delta
			shoot_t -= delta
			if shoot_t <= 0.0:
				shoot_t = 2.6
				run.enemy_shoot(self, 1 + copies, 11.0)
		"lamp":
			if dist < 260.0:
				position -= dir * spd * 0.6 * delta
			else:
				position += dir * spd * delta
			shoot_t -= delta
			if shoot_t <= 0.0 and lit < 3:
				shoot_t = 7.0
				lit += 1
				run.light_lantern(self)
		"boss":
			run.boss_tick(self, delta)
		"wander":
			position += (dir.rotated(sin(t * 3.0) * 0.9)) * spd * delta
		_:
			position += dir * spd * delta
	if behaviour != "mirror" or replay_i >= float(replay.size()):
		sprite.flip_h = dir.x < 0.0
