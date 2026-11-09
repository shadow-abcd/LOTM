extends Node2D
## Insight fragments, coins, hearts and reagents. Magnetised toward the player.

var kind = "frag"        # frag | coin | heart | reagent
var value = 1.0
var ref = ""
var attracted = false
var _t = 0.0
var sprite: Sprite2D

func setup(k: String, v: float, r: String = "", color: Color = Color.WHITE) -> void:
	kind = k
	# Chronicle: Bounty runs pay double for field coins.
	if k == "coin":
		v = Chronicle.coin_value(v)
	value = v
	ref = r
	sprite = Sprite2D.new()
	match k:
		"frag":
			sprite.texture = UI.tex("res://assets/sprites/fragment.png")
			sprite.modulate = Color(0.55, 0.85, 1.0) if v < 5.0 else Color(1.0, 0.8, 0.4)
			sprite.scale = Vector2(0.45, 0.45) if v < 5.0 else Vector2(0.7, 0.7)
		"coin":
			sprite.texture = UI.icon("coin")
			sprite.modulate = Color(1.0, 0.82, 0.35)
			sprite.scale = Vector2(0.3, 0.3)
		"heart":
			sprite.texture = UI.icon("heart")
			sprite.modulate = Color(1.0, 0.4, 0.4)
			sprite.scale = Vector2(0.34, 0.34)
		_:
			sprite.texture = UI.icon(ref)
			sprite.modulate = color
			sprite.scale = Vector2(0.38, 0.38)
	var m = CanvasItemMaterial()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD if k == "frag" else CanvasItemMaterial.BLEND_MODE_MIX
	sprite.material = m
	add_child(sprite)
	_t = randf() * 6.0

func tick(delta: float, run) -> bool:
	_t += delta
	sprite.position.y = sin(_t * 4.0) * 2.5
	var to: Vector2 = run.player.position + Vector2(0, -20) - position
	var d = to.length()
	if d < run.pickup_radius:
		attracted = true
	if attracted:
		position += to.normalized() * (260.0 + 340.0 * run.stats["frag_speed"]) * delta
	if d < 20.0:
		run.collect(self)
		return false
	return true
