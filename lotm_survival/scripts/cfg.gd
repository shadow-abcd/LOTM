extends Node
## Settings (Audio / Graphics / Controls / Gameplay / Accessibility) + input map.

signal changed

const PATH := "user://settings.cfg"
const DEFAULTS := {
	"master": 0.85, "music": 0.7, "sfx": 0.9, "ambience": 0.6,
	"fullscreen": false, "vsync": true, "screen_shake": 1.0, "particles": 2, "damage_numbers": true,
	"show_fps": false, "ui_scale": 1.0, "touch_controls": false, "auto_aim": true,
	"open_gates": true, "difficulty": 1, "pause_on_focus_loss": true, "vibration": true,
	"reduce_flashes": false, "high_contrast": false, "big_text": false, "colorblind": false,
}
## action -> [label, icon, default physical keycode]
const ACTIONS := {
	"move_up": ["Move Up", "keyboard", KEY_W],
	"move_down": ["Move Down", "keyboard", KEY_S],
	"move_left": ["Move Left", "keyboard", KEY_A],
	"move_right": ["Move Right", "keyboard", KEY_D],
	"dash": ["Veilstep (Evade)", "dash", KEY_SPACE],
	"spirit": ["Spirit World", "eye", KEY_R],
	"charm_1": ["Charm 1", "charm", KEY_Q],
	"charm_2": ["Charm 2", "charm", KEY_E],
	"artifact": ["Artifact Active", "artifact", KEY_F],
	"pause": ["Pause", "pause", KEY_P],
	"draft_1": ["Draft Choice 1", "star", KEY_1],
	"draft_2": ["Draft Choice 2", "star", KEY_2],
	"draft_3": ["Draft Choice 3", "star", KEY_3],
	"draft_4": ["Draft Choice 4", "star", KEY_4],
}

var v: Dictionary = {}
var keys: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	v = DEFAULTS.duplicate()
	v["touch_controls"] = DisplayServer.is_touchscreen_available()
	_load()
	_setup_input()
	apply()

func get_v(k: String):
	return v.get(k, DEFAULTS.get(k))

func set_v(k: String, val) -> void:
	v[k] = val
	apply()
	save()
	changed.emit()

func _load() -> void:
	var cf = ConfigFile.new()
	if cf.load(PATH) != OK:
		return
	for k in DEFAULTS.keys():
		if cf.has_section_key("settings", k):
			v[k] = cf.get_value("settings", k)
	for a in ACTIONS.keys():
		if cf.has_section_key("keys", a):
			keys[a] = int(cf.get_value("keys", a))

func save() -> void:
	var cf = ConfigFile.new()
	for k in v.keys():
		cf.set_value("settings", k, v[k])
	for a in keys.keys():
		cf.set_value("keys", a, keys[a])
	cf.save(PATH)

func reset_defaults() -> void:
	v = DEFAULTS.duplicate()
	v["touch_controls"] = DisplayServer.is_touchscreen_available()
	keys.clear()
	_setup_input()
	apply()
	save()
	changed.emit()

func _setup_input() -> void:
	for a in ACTIONS.keys():
		if InputMap.has_action(a):
			InputMap.erase_action(a)
		InputMap.add_action(a, 0.3)
		var kc: int = keys.get(a, ACTIONS[a][2])
		var ev = InputEventKey.new()
		ev.physical_keycode = kc
		InputMap.action_add_event(a, ev)
	# secondary bindings that are never rebound
	_extra("move_up", KEY_UP); _extra("move_down", KEY_DOWN); _extra("move_left", KEY_LEFT); _extra("move_right", KEY_RIGHT)
	_extra("pause", KEY_ESCAPE)

func _extra(action: String, key: int) -> void:
	var ev = InputEventKey.new()
	ev.physical_keycode = key
	InputMap.action_add_event(action, ev)

func rebind(action: String, keycode: int) -> void:
	keys[action] = keycode
	_setup_input()
	save()
	changed.emit()

func key_name(action: String) -> String:
	var kc: int = keys.get(action, ACTIONS[action][2])
	return OS.get_keycode_string(kc)

func apply() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if v["fullscreen"] else DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if v["vsync"] else DisplayServer.VSYNC_DISABLED)
	var root = get_tree().root if get_tree() != null else null
	if root != null:
		root.content_scale_factor = float(v["ui_scale"]) * (1.15 if v["big_text"] else 1.0)

func gate_open() -> bool:
	return bool(v["open_gates"])
