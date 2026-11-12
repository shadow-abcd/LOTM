extends Node2D
## A fully 3D, animated pathway character, rendered live through a transparent
## SubViewport and shown in the 2D arena as the player's body.
## Detail pass: robe skirt, chest, sash, collar, head with glowing eyes that
## blink, hood/hat, arms, hands, pauldrons, boots, a swaying cape, chest emblem
## and a held pathway weapon (sun staff / star lantern / hand mirror) — plus
## pathway accessories (sun halo + ember orbs, scroll + star sparks, crescent
## headpiece + mirror shards + mist), each with its own 3D lighting rig.
## Exposes flip_h / modulate / position so the existing player.gd drives it
## exactly like the old Sprite2D.

const VIEW_SIZE := Vector2i(320, 400)
const DISPLAY_HEIGHT := 128.0
const SKIN := Color(0.79, 0.61, 0.48)
const NO_EMISSION := Color(0, 0, 0)

var flip_h: bool = false:
	set(v):
		flip_h = v
		if _view != null:
			_view.flip_h = v

var _vp: SubViewport
var _view: Sprite2D
var _root3d: Node3D
var _rig: Dictionary = {}
var _orbiters: Array = []
var _t := 0.0
var _last_pos := Vector2.ZERO
var _have_last := false
var _walk_amp := 0.0

func setup(pid: String, accent: Color) -> void:
	_vp = SubViewport.new()
	_vp.size = VIEW_SIZE
	_vp.transparent_bg = true
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_vp)
	_root3d = Node3D.new()
	_vp.add_child(_root3d)
	var cam := Camera3D.new()
	cam.fov = 32.0
	cam.position = Vector3(0.0, 1.55, 3.6)
	_root3d.add_child(cam)
	cam.look_at(Vector3(0.0, 0.95, 0.0), Vector3.UP)
	_lights(accent)
	match pid:
		"wanderer":
			_build_wanderer()
		"hollow_seer":
			_build_hollow_seer()
		_:
			_build_dawnbringer()
	_view = Sprite2D.new()
	_view.texture = _vp.get_texture()
	var s := DISPLAY_HEIGHT / float(VIEW_SIZE.y)
	_view.scale = Vector2(s, s)
	_view.position = Vector2(0.0, -DISPLAY_HEIGHT / 2.0 + 6.0)
	add_child(_view)

# ── 3D scene ──────────────────────────────────────────────────

func _lights(accent: Color) -> void:
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-48.0, -30.0, 0.0)
	key.light_energy = 1.1
	key.light_color = Color(1.0, 0.95, 0.9)
	_root3d.add_child(key)
	var fill := OmniLight3D.new()
	fill.position = Vector3(1.4, 2.2, 2.2)
	fill.omni_range = 6.0
	fill.light_energy = 0.55
	fill.light_color = Color(1.0, 0.9, 0.8)
	_root3d.add_child(fill)
	var rim := OmniLight3D.new()
	rim.position = Vector3(-0.4, 1.7, -1.6)
	rim.omni_range = 5.0
	rim.light_energy = 0.9
	rim.light_color = accent
	_root3d.add_child(rim)
	_rig["rim"] = rim

func _humanoid(robe: Color, robe_dark: Color, trim: Color, cape_col: Color) -> void:
	_rig["skirt"] = _mesh(_cyl(0.30, 0.55, 0.85), robe, Vector3(0, 0.55, 0))
	_rig["chest"] = _mesh(_cap(0.26, 0.62), robe_dark, Vector3(0, 1.05, 0))
	_mesh(_torus(0.255, 0.30), trim, Vector3(0, 0.98, 0), Vector3(90, 0, 0))
	_rig["head"] = _mesh(_sph(0.17, 0.34), SKIN, Vector3(0, 1.47, 0))
	_rig["arm_l"] = _mesh(_cap(0.07, 0.52), robe_dark, Vector3(-0.32, 1.05, 0.02))
	_rig["arm_r"] = _mesh(_cap(0.07, 0.52), robe_dark, Vector3(0.32, 1.05, 0.02))
	_mesh(_sph(0.08, 0.16), SKIN, Vector3(-0.37, 0.80, 0.04))
	_mesh(_sph(0.08, 0.16), SKIN, Vector3(0.37, 0.80, 0.04))
	_mesh(_sph(0.13, 0.26), robe, Vector3(-0.30, 1.28, 0), Vector3.ZERO, Vector3(1, 0.7, 1))
	_mesh(_sph(0.13, 0.26), robe, Vector3(0.30, 1.28, 0), Vector3.ZERO, Vector3(1, 0.7, 1))
	_mesh(_cyl(0.10, 0.12, 0.18), Color(0.23, 0.16, 0.12), Vector3(-0.13, 0.09, 0.02))
	_mesh(_cyl(0.10, 0.12, 0.18), Color(0.23, 0.16, 0.12), Vector3(0.13, 0.09, 0.02))
	# collar around the neck
	_mesh(_torus(0.155, 0.185), trim, Vector3(0, 1.33, 0), Vector3(90, 0, 0))
	# glowing eyes on the face (they blink in _process)
	var eye_glow := Color(1.0, 0.92, 0.78)
	_rig["eye_l"] = _mesh(_sph(0.028, 0.056), Color(1, 1, 1), Vector3(-0.055, 1.49, 0.148), Vector3.ZERO, Vector3.ONE, eye_glow, 0.0, 0.2)
	_rig["eye_r"] = _mesh(_sph(0.028, 0.056), Color(1, 1, 1), Vector3(0.055, 1.49, 0.148), Vector3.ZERO, Vector3.ONE, eye_glow, 0.0, 0.2)
	# cape, sways while walking
	var cape := _mesh(_plane(0.54, 0.80), cape_col, Vector3(0, 1.10, -0.27), Vector3(10.0, 0.0, 0.0))
	var cape_mat := cape.material_override as StandardMaterial3D
	cape_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_rig["cape"] = cape

func _pivot(pos: Vector3) -> Node3D:
	var n := Node3D.new()
	n.position = pos
	_root3d.add_child(n)
	return n

func _build_dawnbringer() -> void:
	var robe := Color("8a3b2a")
	var dark := Color("5e2418")
	var trim := Color("d9a066")
	_humanoid(robe, dark, trim, Color("4a1e14"))
	_mesh(_cone(0.25, 0.32), dark, Vector3(0, 1.70, 0))
	_mesh(_torus(0.20, 0.235), trim, Vector3(0, 1.42, 0), Vector3(90, 0, 0))
	_mesh(_sph(0.045, 0.09), Color("ffd27a"), Vector3(0, 1.09, 0.245), Vector3.ZERO, Vector3.ONE, Color("ff8c3a"), 0.0, 0.4)
	_rig["halo"] = _mesh(_torus(0.30, 0.35), Color("ffd27a"), Vector3(0, 1.95, 0), Vector3(72, 0, 0), Vector3.ONE, Color("ffb347"), 0.0, 0.4)
	for i in range(3):
		var orb := _mesh(_sph(0.05, 0.10), Color("ff9a4a"), Vector3(0, 1.2, 0), Vector3.ZERO, Vector3.ONE, Color("ff6a00"), 0.0, 0.4)
		_orbiters.append({"node": orb, "r": 0.75, "y": 1.15 + 0.12 * float(i), "speed": 1.6 + 0.3 * float(i), "phase": TAU * float(i) / 3.0})
	# sun staff in the right hand
	var hand := _pivot(Vector3(0.34, 0.82, 0.16))
	_rig["hand_r"] = hand
	_rig["hand_r_y"] = 0.82
	_mesh(_cyl(0.022, 0.024, 1.10), Color(0.32, 0.20, 0.13), Vector3(0.0, 0.08, 0.0), Vector3(0, 0, -6), Vector3.ONE, NO_EMISSION, 0.0, 0.8, hand)
	_mesh(_sph(0.055, 0.11), Color("ffd27a"), Vector3(0.05, 0.62, 0.0), Vector3.ZERO, Vector3.ONE, Color("ff9a3a"), 0.0, 0.4, hand)

func _build_wanderer() -> void:
	var robe := Color("3f5a4a")
	var dark := Color("2a3d33")
	var trim := Color("b5d3bd")
	_humanoid(robe, dark, trim, Color("22332a"))
	_mesh(_cyl(0.52, 0.52, 0.05), dark, Vector3(0, 1.66, 0))
	_mesh(_cyl(0.15, 0.19, 0.34), robe, Vector3(0, 1.84, 0))
	_rig["scroll"] = _mesh(_box(Vector3(0.30, 0.07, 0.22)), Color("d8c9a3"), Vector3(0.46, 0.86, 0.16), Vector3(0, -18, 8))
	_mesh(_torus(0.28, 0.33), Color("8a6f4d"), Vector3(0, 0.98, 0), Vector3(90, 0, 0))
	_mesh(_sph(0.04, 0.08), Color("d2f5dc"), Vector3(0, 1.08, 0.245), Vector3.ZERO, Vector3.ONE, Color("7fe3a1"), 0.0, 0.3)
	for i in range(4):
		var spark := _mesh(_sph(0.035, 0.07), Color("d2f5dc"), Vector3(0, 1.5, 0), Vector3.ZERO, Vector3.ONE, Color("7fe3a1"), 0.0, 0.3)
		_orbiters.append({"node": spark, "r": 0.55 + 0.08 * float(i % 2), "y": 1.35 + 0.25 * float(int(i / 2)), "speed": 1.1 + 0.25 * float(i), "phase": TAU * float(i) / 4.0})
	# star lantern in the left hand
	var hand := _pivot(Vector3(-0.34, 0.82, 0.16))
	_rig["hand_l"] = hand
	_rig["hand_l_y"] = 0.82
	_mesh(_cyl(0.012, 0.012, 0.16), Color(0.30, 0.24, 0.16), Vector3(0, -0.02, 0), Vector3.ZERO, Vector3.ONE, NO_EMISSION, 0.0, 0.7, hand)
	_mesh(_box(Vector3(0.11, 0.15, 0.11)), Color(0.35, 0.28, 0.18), Vector3(0, -0.15, 0), Vector3.ZERO, Vector3.ONE, NO_EMISSION, 0.25, 0.55, hand)
	_mesh(_sph(0.045, 0.09), Color("fff2c0"), Vector3(0, -0.15, 0), Vector3.ZERO, Vector3.ONE, Color("ffd76a"), 0.0, 0.3, hand)

func _build_hollow_seer() -> void:
	var robe := Color("4a2a44")
	var dark := Color("331c30")
	var trim := Color("c9a0c6")
	_humanoid(robe, dark, trim, Color("2a1630"))
	_mesh(_cone(0.24, 0.30), dark, Vector3(0, 1.72, 0))
	_rig["halo"] = _mesh(_torus(0.14, 0.175), Color("e3b8e0"), Vector3(0, 1.80, -0.02), Vector3(90, 0, 0), Vector3.ONE, Color("b46ac2"), 0.0, 0.3)
	_mesh(_sph(0.04, 0.08), Color("e3b8e0"), Vector3(0, 1.08, 0.245), Vector3.ZERO, Vector3.ONE, Color("b46ac2"), 0.0, 0.3)
	var mist := _mesh(_sph(0.75, 1.5), Color(0.55, 0.42, 0.60), Vector3(0, 0.45, 0), Vector3.ZERO, Vector3(1, 0.75, 1), Color("5a3a6a"), 0.0, 1.0)
	var mist_mat := mist.material_override as StandardMaterial3D
	mist_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mist_mat.albedo_color = Color(0.55, 0.42, 0.60, 0.16)
	for i in range(3):
		var shard := _mesh(_box(Vector3(0.10, 0.24, 0.02)), Color("cfd6e8"), Vector3(0, 1.3, 0), Vector3.ZERO, Vector3.ONE, NO_EMISSION, 1.0, 0.12)
		_orbiters.append({"node": shard, "r": 0.62, "y": 1.25 + 0.15 * float(i), "speed": 1.3, "phase": TAU * float(i) / 3.0})
	# hand mirror in the left hand
	var hand := _pivot(Vector3(-0.34, 0.82, 0.16))
	_rig["hand_l"] = hand
	_rig["hand_l_y"] = 0.82
	_mesh(_cyl(0.013, 0.013, 0.15), Color(0.55, 0.52, 0.60), Vector3(0, -0.03, 0), Vector3.ZERO, Vector3.ONE, NO_EMISSION, 0.6, 0.3, hand)
	_mesh(_torus(0.075, 0.09), Color(0.75, 0.72, 0.80), Vector3(0, -0.13, 0), Vector3(90, 0, 0), Vector3.ONE, NO_EMISSION, 0.8, 0.25, hand)
	_mesh(_cyl(0.065, 0.065, 0.014), Color(0.75, 0.85, 1.0), Vector3(0, -0.13, 0), Vector3(90, 0, 0), Vector3.ONE, Color("9fd8ff"), 0.9, 0.1, hand)

# ── mesh helpers ─────────────────────────────────────────────

func _mesh(mesh: Mesh, col: Color, pos: Vector3, rot := Vector3.ZERO, scl := Vector3.ONE, emission := NO_EMISSION, metallic := 0.0, rough := 0.85, parent: Node3D = null) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.metallic = metallic
	mat.roughness = rough
	if emission != NO_EMISSION:
		mat.emission_enabled = true
		mat.emission = emission
		mat.emission_energy_multiplier = 1.5
	mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees = rot
	mi.scale = scl
	var host := _root3d if parent == null else parent
	host.add_child(mi)
	return mi

func _box(s: Vector3) -> BoxMesh:
	var m := BoxMesh.new()
	m.size = s
	return m

func _sph(r: float, h: float) -> SphereMesh:
	var m := SphereMesh.new()
	m.radius = r
	m.height = h
	return m

func _cyl(top: float, bot: float, h: float) -> CylinderMesh:
	var m := CylinderMesh.new()
	m.top_radius = top
	m.bottom_radius = bot
	m.height = h
	return m

func _cap(r: float, h: float) -> CapsuleMesh:
	var m := CapsuleMesh.new()
	m.radius = r
	m.height = h
	return m

func _cone(r: float, h: float) -> CylinderMesh:
	var m := CylinderMesh.new()
	m.top_radius = 0.0
	m.bottom_radius = r
	m.height = h
	return m

func _torus(inner: float, outer: float) -> TorusMesh:
	var m := TorusMesh.new()
	m.inner_radius = inner
	m.outer_radius = outer
	return m

func _plane(w: float, h: float) -> PlaneMesh:
	var m := PlaneMesh.new()
	m.size = Vector2(w, h)
	return m

# ── animation ───────────────────────────────────────────────

func _process(delta: float) -> void:
	_t += delta
	if not _have_last:
		_have_last = true
		_last_pos = position
	var vel := position.distance_to(_last_pos) / maxf(delta, 0.001)
	_last_pos = position
	var moving := vel > 20.0
	_walk_amp = lerpf(_walk_amp, 1.0 if moving else 0.0, 6.0 * delta)
	# breathing chest
	if _rig.has("chest") and _rig["chest"] != null:
		var b := 1.0 + 0.02 * sin(_t * 2.4)
		(_rig["chest"] as MeshInstance3D).scale = Vector3(b, 1.0 + 0.015 * sin(_t * 2.4), b)
	# arm sway, stronger while walking
	for side in ["arm_l", "arm_r"]:
		if _rig.has(side) and _rig[side] != null:
			var arm := _rig[side] as MeshInstance3D
			var phase := 0.0 if side == "arm_l" else PI
			arm.rotation.z = 0.16 * sin(_t * 3.2 + phase) * (0.4 + 0.6 * _walk_amp) * (1.0 if side == "arm_l" else -1.0)
	# blinking eyes
	var blink := 1.0
	if fmod(_t, 3.7) > 3.55:
		blink = 0.12
	for k in ["eye_l", "eye_r"]:
		if _rig.has(k) and _rig[k] != null:
			(_rig[k] as MeshInstance3D).scale = Vector3(1.0, blink, 1.0)
	# swaying cape
	if _rig.has("cape") and _rig["cape"] != null:
		(_rig["cape"] as MeshInstance3D).rotation_degrees.x = 10.0 + 4.5 * sin(_t * 2.1) * (0.35 + 0.65 * _walk_amp)
	# held weapon sway + bob
	for k in ["hand_r", "hand_l"]:
		if _rig.has(k) and _rig[k] != null:
			var p := _rig[k] as Node3D
			var ph := 0.0 if k == "hand_r" else PI
			p.rotation.z = 0.14 * sin(_t * 3.2 + ph) * (0.4 + 0.6 * _walk_amp)
			p.position.y = float(_rig[k + "_y"]) + 0.02 * sin(_t * 3.2 + ph) * _walk_amp
	# skirt sway while walking
	if _rig.has("skirt") and _rig["skirt"] != null:
		(_rig["skirt"] as MeshInstance3D).rotation.y = 0.06 * sin(_t * 2.0) * _walk_amp
	# spinning halo
	if _rig.has("halo") and _rig["halo"] != null:
		(_rig["halo"] as MeshInstance3D).rotate_y(1.2 * delta)
	# orbiting accessories (orbs, sparks, shards)
	for o in _orbiters:
		var n := o["node"] as MeshInstance3D
		var a := _t * float(o["speed"]) + float(o["phase"])
		n.position = Vector3(cos(a) * float(o["r"]), float(o["y"]) + 0.05 * sin(a * 2.0), sin(a) * float(o["r"]))
		n.rotation.y = a
	# rim light flicker
	if _rig.has("rim") and _rig["rim"] != null:
		(_rig["rim"] as OmniLight3D).light_energy = 0.8 + 0.15 * sin(_t * 5.0)
