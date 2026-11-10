extends Node2D
## Visual effects: particle bursts, expanding rings, lightning lines, floating damage numbers, shake and flash.
## Phase B: hit-stop for weight on big hits, layered death bursts, boss muzzle telegraphs.

var run = null
var _additive: CanvasItemMaterial
var _live = 0
var shake_amt = 0.0
var _hitstop_t := 0.0
var _hitstop_scale := 1.0

func _ready() -> void:
	_additive = CanvasItemMaterial.new()
	_additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD

func quality() -> int:
	return int(Cfg.get_v("particles"))

func _process(delta: float) -> void:
	# Hit-stop: a brief time-scale dip right after big moments. Applied to the
	# tree by run_deep via Engine.time_scale; this node counts it down.
	if _hitstop_t > 0.0:
		_hitstop_t -= delta / maxf(_hitstop_scale, 0.01) * 0.05
		if _hitstop_t <= 0.0:
			Engine.time_scale = 1.0
			_hitstop_scale = 1.0

## Brief time-scale dip: 0.06s at 30% speed for normal weight, deeper for bosses.
func hitstop(duration: float = 0.06, scale: float = 0.3) -> void:
	if run != null and run.is_inside_tree() and get_tree().paused:
		return
	if bool(Cfg.get_v("performance_mode")):
		return
	if bool(Cfg.get_v("reduce_flashes")):
		scale = maxf(scale, 0.5)
	Engine.time_scale = scale
	_hitstop_scale = scale
	_hitstop_t = duration

func burst(pos: Vector2, color: Color, amount: int = 10, speed: float = 160.0, life: float = 0.5, size: float = 0.22) -> void:
	var q = quality()
	if q == 0:
		amount = int(amount * 0.35)
	elif q == 1:
		amount = int(amount * 0.66)
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
	get_tree().create_timer(life + 0_2).timeout.connect(_free_node.bind(p))

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

func glow_pop(pos: Vector2, color: Color, radius: float, time: float =  popsicle
