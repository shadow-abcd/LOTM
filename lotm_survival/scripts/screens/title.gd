extends Control
## Title screen: painted key art, floating embers, icon menu.

var _settings_layer: Control = null

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	Sound.play_music("study_theme")
	Sound.stop_ambience()
	var bg = TextureRect.new()
	bg.texture = UI.tex("res://assets/textures/title_art.jpg")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.modulate = Color(0.55, 0.5, 0.6)
	add_child(bg)
	var shade = ColorRect.new()
	shade.color = Color(0.03, 0.02, 0.05, 0.55)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	_embers()

	var root = HBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 80; root.offset_right = -80; root.offset_top = 40; root.offset_bottom = -40
	root.add_theme_constant_override("separation", 60)
	add_child(root)

	var left = VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.alignment = BoxContainer.ALIGNMENT_CENTER
	left.add_theme_constant_override("separation", 6)
	root.add_child(left)
	left.add_child(UI.label("LORD OF THE MYSTERIES", 22, UI.GOLD_DIM, false))
	left.add_child(UI.label("SURVIVAL", 76, UI.GOLD, true))
	left.add_child(UI.divider())
	left.add_child(UI.wrap_label("Descend into the Places that remember. Brew the Formula, drink the potion, and do not act in a way the Pathway forbids.", 18, UI.TEXT_DIM))

	var right = VBoxContainer.new()
	right.custom_minimum_size = Vector2(360, 0)
	right.alignment = BoxContainer.ALIGNMENT_CENTER
	right.add_theme_constant_override("separation", 14)
	root.add_child(right)
	right.add_child(UI.button("  Descend", "play", func(): UI.goto("run"), Vector2(0, 66)))
	right.add_child(UI.button("  The Study", "study", func(): UI.goto("study"), Vector2(0, 60)))
	right.add_child(UI.button("  Settings", "settings", _open_settings, Vector2(0, 60)))
	right.add_child(UI.button("  Quit", "quit", func(): get_tree().quit(), Vector2(0, 60)))
	var foot = UI.label("v3.0 · Godot 4 · Forbids lifted: %s" % ("yes" if Cfg.gate_open() else "no"), 14, UI.TEXT_DIM)
	right.add_child(foot)

func _embers() -> void:
	var p = CPUParticles2D.new()
	p.texture = UI.tex("res://assets/sprites/soft_dot.png")
	p.amount = 60 if int(Cfg.get_v("particles")) > 0 else 12
	p.lifetime = 9.0
	p.preprocess = 9.0
	p.position = Vector2(640, 760)
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(700, 10)
	p.direction = Vector2(0, -1)
	p.spread = 18.0
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = 25.0
	p.initial_velocity_max = 70.0
	p.scale_amount_min = 0.08
	p.scale_amount_max = 0.28
	p.color = Color(1.0, 0.62, 0.3, 0.8)
	var m = CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	p.material = m
	add_child(p)

func _open_settings() -> void:
	var S = load("res://scripts/screens/settings_menu.gd")
	var s = S.new()
	add_child(s)
