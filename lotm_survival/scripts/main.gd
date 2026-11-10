extends Node
## Scene manager. Screens are scripts that build their own nodes; `go("title")` swaps them with a fade.

const SCREENS := {
	"title": "res://scripts/screens/title.gd",
	"study": "res://scripts/screens/study.gd",
	"run": "res://scripts/run/run_progress.gd",
}

var current: Node = null
var _fade: ColorRect
var _busy = false
var _fps: Label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var layer = CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	_fade = ColorRect.new()
	_fade.color = Color.BLACK
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_fade)
	_fps = Label.new()
	_fps.position = Vector2(8, 4)
	_fps.add_theme_font_size_override("font_size", 14)
	layer.add_child(_fps)
	get_window().focus_exited.connect(_on_focus_lost)
	go("title")

func _process(_d: float) -> void:
	_fps.visible = bool(Cfg.get_v("show_fps"))
	if _fps.visible:
		_fps.text = "%d FPS" % Engine.get_frames_per_second()

func _on_focus_lost() -> void:
	if Cfg.get_v("pause_on_focus_loss") and current != null and current.has_method("auto_pause"):
		current.auto_pause()

func go(screen: String, args: Dictionary = {}) -> void:
	if _busy:
		return
	_busy = true
	get_tree().paused = false
	var t = create_tween()
	t.tween_property(_fade, "color:a", 1.0, 0.22)
	await t.finished
	if current != null:
		current.queue_free()
		current = null
		await get_tree().process_frame
	var scr = load(SCREENS[screen])
	current = scr.new()
	current.process_mode = Node.PROCESS_MODE_PAUSABLE
	if current.has_method("setup"):
		current.setup(args)
	add_child(current)
	move_child(current, 0)
	var t2 = create_tween()
	t2.tween_property(_fade, "color:a", 0.0, 0.3)
	await t2.finished
	_busy = false
