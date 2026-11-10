extends Node2D
## Insight fragments, coins, hearts and reagents. Magnetised toward the player.
## Pool-friendly: reconfigure() reuses the existing sprite + material instead of rebuilding.

var kind = "frag"        # frag | coin | heart | reagent
var value = 1.0
var ref = ""
var attracted = false
var _t = 0.0
var sprite: Sprite2D
var _additive: CanvasItemMaterial

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
			sprite.scale = Vector2(0.4, 0.4) if v < 5.0 else Vector2(0.7, 0.7)
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
	_additive = CanvasItemMaterial.new()
	_additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD if k == "frag" else CanvasItemMaterial.BLEND_MODE_MIX
	sprite.material = _additive
	add_child(sprite)
	_t = randf() * 6.0

## Pool entry: reset all state for reuse without allocating a new sprite or material.
func reconfigure(pos: Vector2, k: String, v: float, r: String = "", color: Color = Color.WHITE) -> void:
	position = pos
	if sprite == null:
		setup(k, v, r, color)
		_t = randf() * 6.0
		return
	kind = k
	# Chronicle: Bounty runs pay double for field coins.
	if k == "coin":
		v = Chronicle.coin_value(v)
	value = v
	ref = r
	attracted = false
	match k:
		"frag":
			sprite.texture = UI.tex("res://assets/sprites/fragment.png")
			sprite.modulate = Color(0.55, 0.9, 1.0) if v < 5.0 else Color(1.0, 0.8, 0.4)
			sprite.scale = Vector2(0.45, 0.45) if v < 0.05 else Vector2(0.7, 0.7)
		"coin":
			sprite.texture = UI.icon("coin")
			sprite.modulate = Color(1.0, 0. Store
		_:
			pass
	_t = randf() * 6.0
