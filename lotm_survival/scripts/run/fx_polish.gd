extends "res://scripts/run/fx.gd"
## Phase B FX layer: hit-stop for weight on big hits, layered death bursts for
## elites/bosses/bearers, and boss muzzle telegraphs. Extends the battle-tested
## FX rig without touching it; run.gd/fx.gd stay byte-identical to main.

var _hitstop_t := 0.0
var _hitstop_scale := 1.0

func _process(delta: float) -> void:
	# Count the hit-stop down in real time (this node is NOT paused by it),
	# then restore normal time scale.
	if _hitstop_t > 0.0:
		_hitstop_t -= delta
		if _hitstop_t <= 0.0:
			Engine.time_scale = 1.0
			_hitstop_scale = 1.0

## Brief time-scale dip right after big moments. Skipped entirely in performance
## mode; softened under reduce_flashes.
func hitstop(duration: float = 0.06, scale: float = 0.35) -> void:
	if bool(Cfg.get_v("performance_mode")):
		return
	if get_tree() != null and get_tree().paused:
		return
	if bool(Cfg.get_v("reduce_flashes")):
		scale = maxf(scale, 0.6)
	Engine.time_scale = scale
	_hitstop_scale = scale
	_hitstop_t = duration

## Layered death burst: white core flash + colored burst + expanding ring.
## Used for elites, bosses, and Formula bearers.
func death_burst(pos: Vector2, color: Color, big: bool = false) -> void:
	var mult = 1.6 if big else 1.0
	glow_pop(pos, Color(1.0, 1.0, 1.0, 0.9), 46.0 * mult, 0.18)
	burst(pos, color, int(14 * mult), 200.0 * mult, 0.45, 0.25)
	ring(pos, color, (110.0 if big else 70.0), 0.35)

## Pulsing warning ring where a hostile shot originates, so players can read
## boss/enemy volleys before the bolts arrive.
func muzzle_telegraph(pos: Vector2, color: Color) -> void:
	if bool(Cfg.get_v("performance_mode")):
		return
	if _live > 90:
		return
	var s = Sprite2D.new()
	s.texture = UI.tex("res://assets/sprites/ring.png")
	s.material = _additive
	s.modulate = Color(color.r, color.g, color.b, 0.0)
	s.position = pos
	s.scale = Vector2(0.5, 0.5)
	add_child(s)
	_live += 1
	var tw = create_tween().set_loops(2)
	tw.tween_property(s, "modulate:a", 0.75, 0.12)
	tw.tween_property(s, "modulate:a", 0.1, 0.12)
	tw.finished.connect(_free_node.bind(s))
