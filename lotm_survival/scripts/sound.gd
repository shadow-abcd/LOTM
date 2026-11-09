extends Node
## Audio: buses (Music / Sfx / Ambience), crossfading music, pooled SFX, place ambience.

const SFX_DIR := "res://assets/audio/sfx/"
const MUSIC_DIR := "res://assets/audio/music/"
const AMB_DIR := "res://assets/audio/ambience/"

var _cache: Dictionary = {}
var _pool: Array = []
var _pool_i = 0
var _music: Array = []      # two players for crossfade
var _music_cur = 0
var _music_name = ""
var _amb: AudioStreamPlayer
var _amb_name = ""
var _last_play: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for b in ["Music", "Sfx", "Ambience"]:
		if AudioServer.get_bus_index(b) == -1:
			AudioServer.add_bus()
			var i = AudioServer.get_bus_count() - 1
			AudioServer.set_bus_name(i, b)
			AudioServer.set_bus_send(i, "Master")
	for i in 14:
		var p = AudioStreamPlayer.new()
		p.bus = "Sfx"
		add_child(p)
		_pool.append(p)
	for i in 2:
		var m = AudioStreamPlayer.new()
		m.bus = "Music"
		m.volume_db = -80.0
		m.finished.connect(_on_music_finished.bind(m))
		add_child(m)
		_music.append(m)
	_amb = AudioStreamPlayer.new()
	_amb.bus = "Ambience"
	_amb.volume_db = -80.0
	_amb.finished.connect(_on_amb_finished)
	add_child(_amb)
	Cfg.changed.connect(apply_volumes)
	apply_volumes()

func apply_volumes() -> void:
	_set_bus("Master", float(Cfg.get_v("master")))
	_set_bus("Music", float(Cfg.get_v("music")))
	_set_bus("Sfx", float(Cfg.get_v("sfx")))
	_set_bus("Ambience", float(Cfg.get_v("ambience")))

func _set_bus(n: String, lin: float) -> void:
	var i = AudioServer.get_bus_index(n)
	if i == -1:
		return
	AudioServer.set_bus_volume_db(i, linear_to_db(maxf(lin, 0.0001)))
	AudioServer.set_bus_mute(i, lin <= 0.001)

func _res(path: String) -> AudioStream:
	if _cache.has(path):
		return _cache[path]
	var s: AudioStream = null
	if ResourceLoader.exists(path):
		s = load(path)
	_cache[path] = s
	return s

func play_sfx(n: String, vol_db: float = 0.0, pitch: float = 1.0, min_gap: float = 0.03) -> void:
	var now = Time.get_ticks_msec() / 1000.0
	if now - float(_last_play.get(n, -10.0)) < min_gap:
		return
	_last_play[n] = now
	var s = _res(SFX_DIR + n + ".wav")
	if s == null:
		return
	var p: AudioStreamPlayer = _pool[_pool_i]
	_pool_i = (_pool_i + 1) % _pool.size()
	p.stream = s
	p.volume_db = vol_db
	p.pitch_scale = pitch * randf_range(0.97, 1.03)
	p.play()

func play_music(n: String, fade: float = 1.6) -> void:
	if n == _music_name:
		return
	_music_name = n
	var s = _res(MUSIC_DIR + n + ".ogg")
	var old: AudioStreamPlayer = _music[_music_cur]
	_music_cur = 1 - _music_cur
	var nw: AudioStreamPlayer = _music[_music_cur]
	var t = create_tween().set_parallel(true)
	t.tween_property(old, "volume_db", -80.0, fade)
	if s != null:
		if "loop" in s:
			s.loop = true
		nw.stream = s
		nw.volume_db = -80.0
		nw.play()
		t.tween_property(nw, "volume_db", -4.0, fade)
	t.chain().tween_callback(_stop_old.bind(old, nw))

func stop_music(fade: float = 1.0) -> void:
	_music_name = ""
	for m in _music:
		var t = create_tween()
		t.tween_property(m, "volume_db", -80.0, fade)

func _on_music_finished(p: AudioStreamPlayer) -> void:
	if p.stream != null and _music[_music_cur] == p:
		p.play()

func play_ambience(n: String) -> void:
	if n == _amb_name:
		return
	_amb_name = n
	var s = _res(AMB_DIR + n + ".ogg")
	var t = create_tween()
	t.tween_property(_amb, "volume_db", -80.0, 0.6)
	t.tween_callback(func():
		if s != null:
			if "loop" in s:
				s.loop = true
			_amb.stream = s
			_amb.play()
		else:
			_amb.stop())
	if s != null:
		t.tween_property(_amb, "volume_db", -8.0, 1.2)

func stop_ambience() -> void:
	_amb_name = ""
	var t = create_tween()
	t.tween_property(_amb, "volume_db", -80.0, 0.8)
	t.tween_callback(_amb.stop)

func _on_amb_finished() -> void:
	if _amb.stream != null:
		_amb.play()

func _stop_old(old: AudioStreamPlayer, nw: AudioStreamPlayer) -> void:
	if old != nw:
		old.stop()
