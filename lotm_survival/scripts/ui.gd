extends Node
## UI toolkit: theme, icon loading, buttons, slots, cards, toasts. Everything is built in code.

const GOLD := Color("#d9b46a")
const GOLD_DIM := Color("#8a6f40")
const INK := Color("#0c0a10")
const PANEL_BG := Color("#14111b")
const TEXT := Color("#e8e0d0")
const TEXT_DIM := Color("#9a9080")
const GOOD := Color("#7fd68a")
const BAD := Color("#e0705a")

var _icons: Dictionary = {}
var _tex: Dictionary = {}
var font_serif: Font
var font_bold: Font
var theme: Theme

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	font_serif = _load_font("res://assets/fonts/serif.ttf")
	font_bold = _load_font("res://assets/fonts/serif_bold.ttf")
	theme = _build_theme()
	get_tree().root.theme = theme

func _load_font(p: String) -> Font:
	if ResourceLoader.exists(p):
		return load(p)
	return ThemeDB.fallback_font

# ── textures ──
func icon(n: String) -> Texture2D:
	if _icons.has(n):
		return _icons[n]
	var p = "res://assets/icons/%s.png" % n
	var t: Texture2D = null
	if ResourceLoader.exists(p):
		t = load(p)
	elif ResourceLoader.exists("res://assets/icons/sigil.png"):
		t = load("res://assets/icons/sigil.png")
	_icons[n] = t
	return t

func tex(path: String) -> Texture2D:
	if _tex.has(path):
		return _tex[path]
	var t: Texture2D = null
	if ResourceLoader.exists(path):
		t = load(path)
	_tex[path] = t
	return t

# ── styles ──
func flat(bg: Color, border: Color = GOLD_DIM, bw: int = 2, radius: int = 10, margin: int = 10) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(bw)
	s.set_corner_radius_all(radius)
	s.set_content_margin_all(margin)
	return s

func panel_style(margin: int = 16) -> StyleBox:
	var t = tex("res://assets/ui/panel.png")
	if t == null:
		return flat(PANEL_BG)
	var s = StyleBoxTexture.new()
	s.texture = t
	s.set_texture_margin_all(28)
	s.set_content_margin_all(margin)
	return s

func _build_theme() -> Theme:
	var th = Theme.new()
	th.default_font = font_serif
	th.default_font_size = 18
	var b_norm = flat(Color("#1d1826"), GOLD_DIM, 2, 10, 10)
	var b_hov = flat(Color("#2b2236"), GOLD, 2, 10, 10)
	var b_press = flat(Color("#4a3722"), GOLD, 2, 10, 10)
	var b_dis = flat(Color("#15121b"), Color("#3a3446"), 2, 10, 10)
	for st in ["Button", "OptionButton", "CheckButton", "CheckBox", "MenuButton"]:
		th.set_stylebox("normal", st, b_norm)
		th.set_stylebox("hover", st, b_hov)
		th.set_stylebox("pressed", st, b_press)
		th.set_stylebox("disabled", st, b_dis)
		th.set_stylebox("focus", st, flat(Color(0, 0, 0, 0), GOLD, 2, 10, 10))
		th.set_color("font_color", st, TEXT)
		th.set_color("font_hover_color", st, Color.WHITE)
		th.set_color("font_pressed_color", st, GOLD)
		th.set_color("font_disabled_color", st, Color("#6a6272"))
		th.set_color("icon_normal_color", st, TEXT)
		th.set_color("icon_hover_color", st, Color.WHITE)
		th.set_color("icon_pressed_color", st, GOLD)
		th.set_color("icon_disabled_color", st, Color("#5a5262"))
	th.set_constant("icon_max_width", "Button", 40)
	th.set_constant("h_separation", "Button", 10)
	th.set_stylebox("panel", "PanelContainer", panel_style())
	th.set_stylebox("panel", "Panel", panel_style())
	th.set_color("font_color", "Label", TEXT)
	th.set_color("default_color", "RichTextLabel", TEXT)
	th.set_font("normal_font", "RichTextLabel", font_serif)
	th.set_font("bold_font", "RichTextLabel", font_bold)
	th.set_font_size("normal_font_size", "RichTextLabel", 18)
	# progress bars
	th.set_stylebox("background", "ProgressBar", flat(Color("#0e0c14"), Color("#3a3040"), 1, 6, 2))
	th.set_stylebox("fill", "ProgressBar", flat(GOLD, GOLD, 0, 5, 2))
	# sliders
	th.set_stylebox("slider", "HSlider", flat(Color("#0e0c14"), Color("#3a3040"), 1, 4, 3))
	th.set_stylebox("grabber_area", "HSlider", flat(GOLD_DIM, GOLD_DIM, 0, 4, 3))
	th.set_stylebox("grabber_area_highlight", "HSlider", flat(GOLD, GOLD, 0, 4, 3))
	# scroll
	th.set_stylebox("scroll", "VScrollBar", flat(Color("#0e0c14"), Color(0, 0, 0, 0), 0, 4, 2))
	th.set_stylebox("grabber", "VScrollBar", flat(GOLD_DIM, GOLD_DIM, 0, 4, 2))
	th.set_stylebox("grabber_highlight", "VScrollBar", flat(GOLD, GOLD, 0, 4, 2))
	th.set_stylebox("grabber_pressed", "VScrollBar", flat(GOLD, GOLD, 0, 4, 2))
	th.set_stylebox("panel", "PopupMenu", flat(Color("#14111b"), GOLD_DIM, 2, 8, 8))
	return th

# ── widgets ──
func label(text: String, size: int = 18, color: Color = TEXT, bold: bool = false, align: int = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l = Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if bold:
		l.add_theme_font_override("font", font_bold)
	l.horizontal_alignment = align as HorizontalAlignment
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	return l

func wrap_label(text: String, size: int = 16, color: Color = TEXT_DIM) -> Label:
	var l = label(text, size, color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l

func icon_rect(n: String, size: int = 32, tint: Color = Color.WHITE) -> TextureRect:
	var r = TextureRect.new()
	r.texture = icon(n)
	r.custom_minimum_size = Vector2(size, size)
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.modulate = tint
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r

func button(text: String, icon_name: String = "", cb: Callable = Callable(), min_size: Vector2 = Vector2.ZERO) -> Button:
	var b = Button.new()
	b.text = text
	if icon_name != "":
		b.icon = icon(icon_name)
		b.expand_icon = true
	b.custom_minimum_size = min_size
	_wire(b, cb)
	return b

func icon_button(icon_name: String, tip: String = "", cb: Callable = Callable(), size: int = 52) -> Button:
	var b = Button.new()
	b.icon = icon(icon_name)
	b.expand_icon = true
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.custom_minimum_size = Vector2(size, size)
	b.tooltip_text = tip
	b.add_theme_constant_override("icon_max_width", int(size * 0.62))
	_wire(b, cb)
	return b

func _wire(b: Button, cb: Callable) -> void:
	b.mouse_entered.connect(func(): Sound.play_sfx("ui_hover", -6.0))
	b.pressed.connect(func(): Sound.play_sfx("ui_click"))
	if cb.is_valid():
		b.pressed.connect(cb)

func toggle(text: String, icon_name: String, value: bool, cb: Callable) -> CheckButton:
	var c = CheckButton.new()
	c.text = text
	if icon_name != "":
		c.icon = icon(icon_name)
		c.expand_icon = true
	c.button_pressed = value
	c.custom_minimum_size = Vector2(0, 46)
	c.toggled.connect(func(on: bool):
		Sound.play_sfx("ui_toggle")
		cb.call(on))
	return c

func slider(value: float, cb: Callable, min_v: float = 0.0, max_v: float = 1.0, step: float = 0.01) -> HSlider:
	var s = HSlider.new()
	s.min_value = min_v
	s.max_value = max_v
	s.step = step
	s.value = value
	s.custom_minimum_size = Vector2(240, 28)
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.value_changed.connect(func(v: float):
		Sound.play_sfx("ui_slider", -10.0, 0.8 + v / max_v * 0.6, 0.06)
		cb.call(v))
	return s

func divider() -> TextureRect:
	var t = TextureRect.new()
	t.texture = tex("res://assets/ui/divider.png")
	t.custom_minimum_size = Vector2(0, 20)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_SCALE
	return t

func header(text: String, icon_name: String, size: int = 28) -> Control:
	var box = VBoxContainer.new()
	var h = HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	h.add_child(icon_rect(icon_name, size + 8, GOLD))
	h.add_child(label(text, size, GOLD, true))
	box.add_child(h)
	box.add_child(divider())
	return box

func rarity_color(r: String) -> Color:
	return DB.RARITY_COLORS.get(r, Color.WHITE)

## A framed square slot with an icon (or painted texture). Returns a Control of the given size.
func slot(icon_name: String, rarity: String = "empty", size: int = 72, tint: Color = Color.WHITE, painted: String = "") -> Control:
	var c = Control.new()
	c.custom_minimum_size = Vector2(size, size)
	var frame = TextureRect.new()
	var key = rarity.to_lower()
	frame.texture = tex("res://assets/ui/slot_%s.png" % key)
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame.stretch_mode = TextureRect.STRETCH_SCALE
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(frame)
	var pad = int(size * 0.14)
	if painted != "" and tex(painted) != null:
		var p = TextureRect.new()
		p.texture = tex(painted)
		p.set_anchors_preset(Control.PRESET_FULL_RECT)
		p.offset_left = pad; p.offset_top = pad; p.offset_right = -pad; p.offset_bottom = -pad
		p.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		p.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		c.add_child(p)
	elif icon_name != "":
		var ic = icon_rect(icon_name, size - pad * 2, tint)
		ic.set_anchors_preset(Control.PRESET_FULL_RECT)
		ic.offset_left = pad; ic.offset_top = pad; ic.offset_right = -pad; ic.offset_bottom = -pad
		c.add_child(ic)
	return c

## Clickable slot: wraps slot() with a transparent button on top.
func slot_button(icon_name: String, rarity: String, size: int, tint: Color, cb: Callable, tip: String = "", painted: String = "") -> Control:
	var s = slot(icon_name, rarity, size, tint, painted)
	var b = Button.new()
	b.flat = true
	b.set_anchors_preset(Control.PRESET_FULL_RECT)
	b.tooltip_text = tip
	b.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	b.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	b.add_theme_stylebox_override("hover", flat(Color(1, 1, 1, 0.07), GOLD, 2, 12, 0))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	_wire(b, cb)
	s.add_child(b)
	return s

func pill(text: String, color: Color) -> PanelContainer:
	var p = PanelContainer.new()
	p.add_theme_stylebox_override("panel", flat(color.darkened(0.6), color, 1, 12, 4))
	var l = label(text, 13, color.lightened(0.3))
	p.add_child(l)
	return p

func clear(node: Node) -> void:
	for c in node.get_children():
		node.remove_child(c)
		c.queue_free()

func scroll(content: Control) -> ScrollContainer:
	var sc = ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(content)
	return sc

func toast(text: String, icon_name: String = "info", seconds: float = 2.4) -> void:
	var layer = CanvasLayer.new()
	layer.layer = 90
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	var p = PanelContainer.new()
	var h = HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	h.add_child(icon_rect(icon_name, 28, GOLD))
	h.add_child(label(text, 18))
	p.add_child(h)
	layer.add_child(p)
	get_tree().root.add_child(layer)
	p.set_anchors_preset(Control.PRESET_CENTER_TOP)
	p.position = Vector2(get_viewport().get_visible_rect().size.x / 2.0 - 160, -80)
	var t = create_tween()
	t.tween_property(p, "position:y", 28.0, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_interval(seconds)
	t.tween_property(p, "modulate:a", 0.0, 0.4)
	t.tween_callback(layer.queue_free)
	Sound.play_sfx("ui_confirm", -4.0)

func goto(screen: String, args: Dictionary = {}) -> void:
	var m = get_tree().current_scene
	if m != null and m.has_method("go"):
		m.go(screen, args)

func fmt_cost(cost: Dictionary) -> String:
	var parts: Array = []
	for k in cost.keys():
		var r = DB.reagent(k)
		parts.append("%d× %s" % [int(cost[k]), r.get("name", k)])
	return ", ".join(PackedStringArray(parts))
