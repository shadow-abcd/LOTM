extends Node2D
## Visual effects: particle bursts, expanding rings, lightning lines, floating damage numbers, shake and flash.

var run = null
var _additive: CanvasItemMaterial
var _live = 0
var shake_amt = 0.0

func _ready() -> void:
	_additive = CanvasItemMaterial.new()
	_additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD

func quality() -> int:
	return int(Cfg.get_v("particles"))

func burst(pos: Vector2, color: Color, amount: int = 10, speed: float = 160.0, life: float = 0.5, size: float = 0.22) -> void:
	var q = quality()
	if q == 0:
		amount = int(amount * 0.35)
	elif q == 1:
		amount = int(amount * 0.65)
	if amount <= 0 or _live > 70:
		return
	var p = CPUParticles2D.new()
	p.texture = UI.tex("res://assets/sprites/spark.png")
	p.material = _additive
	p.one_shot = true
	p.emitting = true
	p.amount = amount
	p.lifetime = life
	p.explosiveness = 1.0
	p.direction = Vector2.UP
	p.spread = 180.0
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = speed * 0.4
	p.initial_velocity_max = speed
	p.scale_amount_min = size * 0.5
	p.scale_amount_max = size
	p.color = color
	p.position = pos
	add_child(p)
	_live += 1
	get_tree().create_timer(life + 0.2).timeout.connect(_free_node.bind(p))

func _free_node(n: Node) -> void:
	_live = maxi(0, _live - 1)
	if is_instance_valid(n):
		n.queue_free()

func ring(pos: Vector2, color: Color, radius: float, time: float = 0.4) -> void:
	if _live > 90:
		return
	var s = Sprite2D.new()
	s.texture = UI.tex("res://assets/sprites/ring.png")
	s.material = _additive
	s.modulate = color
	s.position = pos
	s.scale = Vector2(0.05, 0.05)
	add_child(s)
	_live += 1
	var target = radius / 128.0
	var tw = create_tween().set_parallel(true)
	tw.tween_property(s, "scale", Vector2(target, target), time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(s, "modulate:a", 0.0, time)
	tw.chain().tween_callback(_free_node.bind(s))

func glow_pop(pos: Vector2, color: Color, radius: float, time: float = 0.3) -> void:
	var s = Sprite2D.new()
	s.texture = UI.tex("res://assets/sprites/glow.png")
	s.material = _additive
	s.modulate = color
	s.position = pos
	s.scale = Vector2(radius / 64.0, radius / 64.0)
	add_child(s)
	_live += 1
	var tw = create_tween()
	tw.tween_property(s, "modulate:a", 0.0, time)
	tw.tween_callback(_free_node.bind(s))

func zap(a: Vector2, b: Vector2, color: Color) -> void:
	var l = Line2D.new()
	var pts = PackedVector2Array()
	var steps = 6
	for i in range(steps + 1):
		var t = float(i) / steps
		var pt = a.lerp(b, t)
		if i > 0 and i < steps:
			pt += Vector2(randf_range(-10, 10), randf_range(-10, 10))
		l.points = pts
	l.points = pts
	l.width = 4.0
	l.default_color = color
	l.material = _additive
	add_child(l)
	_live += 1
	var tw = create_tween()
	tw.tween_property(l, "modulate:a", 0.0, 0.18)
	tw.tween_callback(_free_node.bind(l))

func slash(pos: Vector2, color: Color) -> void:
	var s = Sprite2D.new()
	s.texture = UI.tex("res://assets/sprites/slash.png")
	s.material = _additive
	s.modulate = color
	s.position = pos
	s.rotation = randf() * TAU
	s.scale = Vector2(0.5, 0.5)
	add_child(s)
	_live += 1
	var tw = create_tween().set_parallel(true)
	tw.tween_property(s, "scale", Vector2(0.9, 0.9), 0.15)
	tw.tween_property(s, "modulate:a", 0.0, 0.15)
	tw.chain().tween_callback(_free_node.bind(s))

func number(pos: Vector2, value: float, color: Color = Color.WHITE, crit: bool = false) -> void:
	if not Cfg.get_v("damage_numbers") or _live > 60:
		return
	var l = Label.new()
	l.text = str(int(round(value))) + ("!" if crit else "")
	l.add_theme_font_size_override("font_size", 26 if crit else 17)
	l.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3) if crit else color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("outline_size", 5)
	l.position = pos + Vector2(randf_range(-14, 14) - 10, -30)
	l.z_index = 50
	add_child(l)
	_live += 1
	var tw = create_tween().set_parallel(true)
	tw.tween_property(l, "position:y", l.position.y - 38.0, 0.55)
	tw.tween_property(l, "modulate:a", 0.0, 0.55).set_delay(0.2)
	tw.chain().tween_callback(_free_node.bind(l))

func text_pop(pos: Vector2, text: String, color: Color) -> void:
	var l = Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 20)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	l.add_theme_constant_override("outline_size", 5)
	l.position = pos + Vector2(-40, -70)
	l.z_index = 50
	add_child(l)
	var tw = create_tween().set_parallel(true)
	tw.tween_property(l, "position:y", l.position.y - 50.0, 1.0)
	tw.tween_property(l, "modulate:a", 0.0, 1.0).set_delay(0.5)
	tw.chain().tween_callback(l.queue_free)

func shake(amount: float) -> void:
	shake_amt = maxf(shake_amt, amount * float(Cfg.get_v("screen_shake")))

func flash(color: Color, alpha: float = 0.3) -> void:
	if run != null and run.hud != null:
		run.hud.flash(color, alpha * (0.4 if Cfg.get_v("reduce_flashes") else 1.0))
