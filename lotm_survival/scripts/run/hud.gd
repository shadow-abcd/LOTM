extends CanvasLayer
## In-run HUD: vitality, insight, sequence, abilities, boss bar, timers, touch controls, screen overlays.

const Cab = preload("res://scripts/sections/cabinet.gd")

var run = null
var touch_vec = Vector2.ZERO
var _root: Control
var _hp_bar: ProgressBar
var _hp_lbl: Label
var _xp_bar: ProgressBar
var _lvl_lbl: Label
var _seq_lbl: Label
var _place_lbl: Label
var _time_lbl: Label
var _coin_lbl: Label
var _kill_lbl: Label
var _status_lbl: Label
var _boss_box: Control
var _boss_bar: ProgressBar
var _boss_name: Label
var _announce: VBoxContainer
var _ann_title: Label
var _ann_sub: Label
var _toasts: VBoxContainer
var _ab_row: HBoxContainer
var _ab_sig = ""
var _ab_slots: Array = []
var _dash_btn: Button
var _spirit_btn: Button
var _charm_btns: Array = []
var _art_btn: Button
var _vignette: TextureRect
var _dark: ColorRect
var _dark_mat: ShaderMaterial
var _water: ColorRect
var _flash: ColorRect
var _accent = Color.WHITE
var _touch_idx = -1
var _touch_origin = Vector2.ZERO
var _stick_base: TextureRect
var _stick_knob: TextureRect
var _flash_tween: Tween
var _slow_t = 0.0

func _ready() -> void:
	layer = 10
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	_overlays()
	_top_left()
	_top_right()
	_boss()
	_announce_ui()
	_toasts = VBoxContainer.new()
	_toasts.position = Vector2(18, 150)
	_toasts.add_theme_constant_override("separation", 6)
	_toasts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_toasts)
	_bottom()
	if Cfg.get_v("touch_controls"):
		_stick()

func _overlays() -> void:
	_vignette = TextureRect.new()
	_vignette.texture = UI.tex("res://assets/sprites/vignette.png")
	_vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	_vignette.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_vignette.stretch_mode = TextureRect.STRETCH_SCALE
	_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vignette.modulate = Color(0, 0, 0, 0.6)
	_root.add_child(_vignette)
	_dark = ColorRect.new()
	_dark.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh = Shader.new()
	sh.code = "shader_type canvas_item;\nuniform float radius = 0.3;\nuniform float soft = 0.25;\nuniform float aspect = 1.78;\nuniform float strength = 0.9;\nvoid fragment() {\n\tvec2 uv = UV - vec2(0.5, 0.46);\n\tuv.x *= aspect;\n\tfloat d = length(uv);\n\tCOLOR = vec4(0.0, 0.0, 0.03, smoothstep(radius, radius + soft, d) * strength);\n}\n"
	_dark_mat = ShaderMaterial.new()
	_dark_mat.shader = sh
	_dark.material = _dark_mat
	_dark.visible = false
	_root.add_child(_dark)
	_water = ColorRect.new()
	_water.color = Color(0.2, 0.5, 0.65, 0.35)
	_water.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_water.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_water.visible = false
	_root.add_child(_water)
	_flash = ColorRect.new()
	_flash.color = Color(1, 1, 1, 0)
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_flash)

func _bar(col: Color, w: int, h: int) -> ProgressBar:
	var b = ProgressBar.new()
	b.custom_minimum_size = Vector2(w, h)
	b.show_percentage = false
	b.add_theme_stylebox_override("fill", UI.flat(col, col, 0, 5, 2))
	return b

func _top_left() -> void:
	var p = PanelContainer.new()
	p.position = Vector2(14, 12)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var v = VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	p.add_child(v)
	var h1 = HBoxContainer.new()
	h1.add_child(UI.icon_rect("heart", 24, Color(1, 0.4, 0.4)))
	_hp_bar = _bar(Color("#c8483c"), 220, 20)
	h1.add_child(_hp_bar)
	_hp_lbl = UI.label("", 14)
	h1.add_child(_hp_lbl)
	v.add_child(h1)
	var h2 = HBoxContainer.new()
	h2.add_child(UI.icon_rect("gem", 24, Color(0.55, 0.85, 1.0)))
	_xp_bar = _bar(Color("#5ab4e0"), 220, 14)
	h2.add_child(_xp_bar)
	_lvl_lbl = UI.label("Lv 1", 14)
	h2.add_child(_lvl_lbl)
	v.add_child(h2)
	_seq_lbl = UI.label("", 16, UI.GOLD, true)
	v.add_child(_seq_lbl)
	_place_lbl = UI.label("", 13, UI.TEXT_DIM)
	v.add_child(_place_lbl)
	_status_lbl = UI.label("", 13, UI.GOOD)
	v.add_child(_status_lbl)
	_root.add_child(p)

func _top_right() -> void:
	var h = HBoxContainer.new()
	h.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	h.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	h.offset_right = -14
	h.offset_top = 12
	h.add_theme_constant_override("separation", 14)
	h.add_child(UI.icon_rect("timer", 26, UI.GOLD))
	_time_lbl = UI.label("0:00", 20, UI.TEXT, true)
	h.add_child(_time_lbl)
	h.add_child(UI.icon_rect("coin", 26, Color("#e8c060")))
	_coin_lbl = UI.label("0", 20, Color("#e8c060"), true)
	h.add_child(_coin_lbl)
	h.add_child(UI.icon_rect("skull", 26, Color(0.8, 0.8, 0.85)))
	_kill_lbl = UI.label("0", 20, UI.TEXT, true)
	h.add_child(_kill_lbl)
	h.add_child(UI.icon_button("pause", "Pause", func(): run.open_pause(), 50))
	_root.add_child(h)

func _boss() -> void:
	_boss_box = VBoxContainer.new()
	_boss_box.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_boss_box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_boss_box.offset_top = 64
	_boss_box.visible = false
	_boss_name = UI.label("", 20, Color(1, 0.8, 0.5), true, HORIZONTAL_ALIGNMENT_CENTER)
	_boss_box.add_child(_boss_name)
	_boss_bar = _bar(Color("#b03040"), 520, 18)
	_boss_bar.max_value = 1.0
	_boss_bar.step = 0.001
	_boss_box.add_child(_boss_bar)
	_root.add_child(_boss_box)

func _announce_ui() -> void:
	_announce = VBoxContainer.new()
	_announce.set_anchors_preset(Control.PRESET_CENTER)
	_announce.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_announce.grow_vertical = Control.GROW_DIRECTION_BOTH
	_announce.offset_top = -160
	_announce.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ann_title = UI.label("", 40, UI.GOLD, true, HORIZONTAL_ALIGNMENT_CENTER)
	_ann_sub = UI.label("", 20, UI.TEXT_DIM, false, HORIZONTAL_ALIGNMENT_CENTER)
	_announce.add_child(_ann_title)
	_announce.add_child(_ann_sub)
	_announce.modulate.a = 0.0
	_root.add_child(_announce)

func _bottom() -> void:
	_ab_row = HBoxContainer.new()
	_ab_row.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_ab_row.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_ab_row.offset_left = 14
	_ab_row.offset_bottom = -14
	_ab_row.add_theme_constant_override("separation", 6)
	_ab_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_ab_row)
	var br = HBoxContainer.new()
	br.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	br.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	br.grow_vertical = Control.GROW_DIRECTION_BEGIN
	br.offset_right = -14
	br.offset_bottom = -14
	br.add_theme_constant_override("separation", 8)
	_root.add_child(br)
	_charm_btns = []
	for i in 2:
		var b = UI.icon_button("charm", "Charm %d" % (i + 1), func(): run.use_charm(i), 60)
		_charm_btns.append(b)
		br.add_child(b)
	_art_btn = UI.icon_button("artifact", "Artifact active", func(): run.use_artifact(), 60)
	br.add_child(_art_btn)
	_spirit_btn = UI.icon_button("eye", "Spirit World", func(): run.use_spirit(), 60)
	br.add_child(_spirit_btn)
	_dash_btn = UI.icon_button("dash", "Veilstep", func(): run._dash(Vector2.ZERO), 76)
	br.add_child(_dash_btn)

func _stick() -> void:
	_stick_base = TextureRect.new()
	_stick_base.texture = UI.icon("joystick")
	_stick_base.custom_minimum_size = Vector2(150, 150)
	_stick_base.size = Vector2(150, 150)
	_stick_base.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_stick_base.modulate = Color(1, 1, 1, 0.0)
	_stick_base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_stick_base)
	_stick_knob = TextureRect.new()
	_stick_knob.texture = UI.tex("res://assets/sprites/glow.png")
	_stick_knob.size = Vector2(80, 80)
	_stick_knob.modulate = Color(1, 1, 1, 0.0)
	_stick_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_stick_knob)

func _input(e: InputEvent) -> void:
	if not Cfg.get_v("touch_controls") or _stick_base == null:
		return
	var half = get_viewport().get_visible_rect().size.x * 0.5
	if e is InputEventScreenTouch:
		if e.pressed and _touch_idx == -1 and e.position.x < half:
			_touch_idx = e.index
			_touch_origin = e.position
			_stick_base.position = e.position - Vector2(75, 75)
			_stick_base.modulate.a = 0.55
			_stick_knob.modulate.a = 0.7
			_stick_knob.position = e.position - Vector2(40, 40)
		elif not e.pressed and e.index == _touch_idx:
			_touch_idx = -1
			touch_vec = Vector2.ZERO
			_stick_base.modulate.a = 0.0
			_stick_knob.modulate.a = 0.0
	elif e is InputEventScreenDrag and e.index == _touch_idx:
		var off = e.position - _touch_origin
		touch_vec = (off / 70.0).limit_length(1.0)
		_stick_knob.position = _touch_origin + touch_vec * 60.0 - Vector2(40, 40)

# ── public API used by Run ──
func set_place(place: Dictionary) -> void:
	_accent = Color(str(place.get("accent", "#ffffff")))
	_place_lbl.text = str(place.get("name", ""))
	var hz = str(place.get("hazard", {}).get("id", ""))
	_dark.visible = hz == "darkness"
	_water.visible = hz == "rising_water"

func announce(title: String, sub: String = "") -> void:
	_ann_title.text = title
	_ann_sub.text = sub
	var t = create_tween()
	t.tween_property(_announce, "modulate:a", 1.0, 0.4)
	t.tween_interval(2.0)
	t.tween_property(_announce, "modulate:a", 0.0, 0.8)

func toast(text: String, icon_name: String = "info") -> void:
	if _toasts.get_child_count() >= 4:
		_toasts.get_child(0).queue_free()
	var p = PanelContainer.new()
	p.add_theme_stylebox_override("panel", UI.flat(Color(0.08, 0.06, 0.12, 0.85), UI.GOLD_DIM, 1, 8, 6))
	var h = HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	h.add_child(UI.icon_rect(icon_name, 22, UI.GOLD))
	h.add_child(UI.label(text, 15))
	p.add_child(h)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toasts.add_child(p)
	var t = create_tween()
	t.tween_interval(3.2)
	t.tween_property(p, "modulate:a", 0.0, 0.6)
	t.tween_callback(p.queue_free)

func show_boss(n: String) -> void:
	_boss_box.visible = true
	_boss_name.text = n
	_boss_bar.value = 1.0

func set_boss(frac: float) -> void:
	_boss_bar.value = clampf(frac, 0.0, 1.0)

func hide_boss() -> void:
	_boss_box.visible = false

func flash(color: Color, alpha: float) -> void:
	_flash.color = Color(color.r, color.g, color.b, alpha)
	if _flash_tween != null:
		_flash_tween.kill()
	_flash_tween = create_tween()
	_flash_tween.tween_property(_flash, "color:a", 0.0, 0.35)

func _rebuild_abilities() -> void:
	UI.clear(_ab_row)
	_ab_slots = []
	for a in run.abilities:
		var lv = int(a["level"])
		var s = UI.slot(Cab._icon_for(str(a["kind"])), ["common", "uncommon", "rare", "epic", "mythic"][clampi(int((lv - 1) / 2.0), 0, 4)], 58, DB.ELEMENT_COLORS.get(a["element"], Color.WHITE))
		s.tooltip_text = "%s (Lv %d)" % [a["name"], lv]
		var ov = ColorRect.new()
		ov.color = Color(0, 0, 0, 0.55)
		ov.mouse_filter = Control.MOUSE_FILTER_IGNORE
		s.add_child(ov)
		ov.anchor_left = 0.0
		ov.anchor_right = 1.0
		ov.anchor_top = 0.0
		ov.anchor_bottom = 0.0
		ov.offset_left = 0
		ov.offset_right = 0
		ov.offset_top = 0
		ov.offset_bottom = 0
		var l = UI.label(str(lv), 13, UI.GOLD, true)
		l.position = Vector2(4, 36)
		s.add_child(l)
		_ab_row.add_child(s)
		_ab_slots.append([ov, a])

func _cool(b: Button, t: float) -> void:
	b.disabled = t > 0.05
	b.text = "" if t <= 0.05 else str(int(ceil(t)))

func refresh() -> void:
	_hp_bar.max_value = run.player.max_hp
	_hp_bar.value = run.player.hp
	_xp_bar.max_value = run.need
	_xp_bar.value = run.insight
	_slow_t -= get_process_delta_time()
	if _slow_t > 0.0:
		_refresh_overlays()
		return
	_slow_t = 0.1
	_hp_lbl.text = "%d" % int(ceil(run.player.hp))
	_lvl_lbl.text = "Lv %d/%d" % [run.level, run.MAX_LEVEL]
	_seq_lbl.text = "Seq %d · %s" % [run.seq, DB.title_for(run.pid, run.seq)]
	var tm = int(run.time)
	_time_lbl.text = "%d:%02d" % [int(tm / 60.0), tm % 60]
	_coin_lbl.text = str(run.coins_run)
	_kill_lbl.text = str(run.kills)
	var st = ""
	if run.hunt_stacks > 0:
		st += "Hunt ×%d  " % run.hunt_stacks
	if run.player.shield > 0:
		st += "Shield ×%d  " % run.player.shield
	if run.quill_charges > 0:
		st += "Quill ×%d  " % run.quill_charges
	if run.spirit_t > 0.0:
		st += "Spirit World  "
	if run.rerolls > 0:
		st += "Fate ×%d" % run.rerolls
	if run.stats["show_next"]:
		st += "  Next: Seq %d" % maxi(0, run.seq - 1)
	if run.stats["show_count"]:
		st += "  Foes: %d" % run.enemies.size()
	_status_lbl.text = st
	var sig = ""
	for a in run.abilities:
		sig += "%s%d," % [a["id"], int(a["level"])]
	if sig != _ab_sig:
		_ab_sig = sig
		_rebuild_abilities()
	for pair in _ab_slots:
		var a = pair[1]
		var frac = 0.0
		if float(a["cooldown"]) > 0.0 and not (a["kind"] in run.PASSIVES) and a["kind"] != "orbit":
			frac = clampf(float(a["timer"]) / float(a["cooldown"]), 0.0, 1.0)
		pair[0].anchor_bottom = frac
	_cool(_dash_btn, run.player.dash_cd_t)
	_cool(_spirit_btn, run.spirit_cd)
	_cool(_art_btn, run.quill_cd if run.stats["has_quill"] else 0.0)
	_art_btn.visible = run.stats["has_quill"]
	var eq: Array = Store.equipped("charms")
	for i in 2:
		_charm_btns[i].visible = i < eq.size()
		if i < eq.size():
			_cool(_charm_btns[i], float(run.charm_cd[i]))
	_refresh_overlays()

func _refresh_overlays() -> void:
	var low = 1.0 - run.player.hp / run.player.max_hp
	var vc = _accent.darkened(0.55)
	var pulse = (0.5 + 0.5 * sin(Time.get_ticks_msec() / 160.0)) * clampf(low - 0.55, 0.0, 0.45) * 2.0
	_vignette.modulate = Color(lerpf(vc.r, 0.7, pulse), lerpf(vc.g, 0.05, pulse), lerpf(vc.b, 0.05, pulse), 0.55 + pulse * 0.3)
	if _dark.visible:
		var vs = get_viewport().get_visible_rect().size
		_dark_mat.set_shader_parameter("aspect", vs.x / maxf(vs.y, 1.0))
		_dark_mat.set_shader_parameter("radius", 0.2 + 0.03 * run.level * 0.2)
	if _water.visible:
		_water.offset_top = -run.water_h
