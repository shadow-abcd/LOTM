extends "res://scripts/sections/base.gd"
## The Grimoire: nine permanent Formulas per pathway. A Formula must be FOUND, then its potion BREWED.
## Brew plays a bubbling potion animation; brewed cards glow; brewable cards shimmer.

func _init() -> void:
	title = "The Grimoire — Formulas"
	icon_name = "grimoire"

func build() -> void:
	var pid = Store.current_pathway()
	var p = DB.pathway(pid)
	body.add_child(UI.wrap_label("%s pathway. %s" % [p.get("name", pid), "The Forbids are lifted: gates open without potions, but brewing still grants lasting pride." if Cfg.gate_open() else "A Sequence gate (6, 2, 1) cannot advance until its Formula is found and its potion is brewed."], 15))
	var inf_row = HBoxContainer.new()
	inf_row.add_theme_constant_override("separation", 10)
	inf_row.add_child(UI.button(" Sequential Inferer · 1000 ●", "eye", _infer, Vector2(300, 46)))
	inf_row.add_child(UI.button(" Emergency unlock · 150 ◆", "diamond", _emergency, Vector2(280, 46)))
	body.add_child(inf_row)
	for f in DB.formulas_of(pid):
		_formula_card(pid, f)

func _formula_card(pid: String, f: Dictionary) -> void:
	var key: String = f["id"]
	var found = Store.has_formula(key)
	var brewed = Store.has_potion(key)
	var cost: Dictionary = f["recipe"]["cost"]
	var state = "prepared" if brewed else ("sealed" if found else "blank")
	var rar = "mythic" if brewed else ("rare" if found else "empty")
	var lines: Array = []
	if found:
		lines.append(["Recipe: %s" % UI.fmt_cost(cost), UI.TEXT])
		var have = Store.can_afford(cost)
		lines.append(["Reagents %s · band %s" % ["ready" if have else "missing", f["recipe"]["band"]], UI.GOOD if have else UI.BAD])
	else:
		lines.append([str(f["hint"]), UI.TEXT_DIM])
	var acts: Array = []
	if brewed:
		acts.append(act("Potion ready", "check", Callable(), true))
	elif found:
		acts.append(act("Brew", "potion", func(): _brew(key), not Store.can_afford(cost)))
	else:
		acts.append(act("Not found", "lock", Callable(), true))
	var gate = " · GATE" if int(f["target"]) in DB.GATES else ""
	var the_card = card(UI.slot("potion" if found else "scroll", rar, 64, Color.WHITE if found else Color(1, 1, 1, 0.35)),
		"Seq %d · %s" % [int(f["target"]), DB.title_for(pid, int(f["target"]))], state.to_upper() + gate, UI.GOLD if brewed else UI.TEXT_DIM, lines, acts)
	if brewed:
		the_card.add_theme_stylebox_override("panel", UI.flat(Color("#1f1a10"), Color("#d9a066"), 1, 10, 10))
	elif found and Store.can_afford(cost):
		var tw = the_card.create_tween().set_loops()
		tw.tween_property(the_card, "modulate", Color(1.06, 1.04, 0.98), 0.9)
		tw.tween_property(the_card, "modulate", Color(1.0, 1.0, 1.0), 1.1)

func _brew(key: String) -> void:
	if not Store.can_afford(DB.formula(key)["recipe"]["cost"]):
		UI.toast("Reagents missing", "lock")
		return
	if Store.brew(key):
		Sound.play_sfx("brew")
		_brew_vfx()
		UI.toast("Potion brewed: %s" % DB.formula(key).get("name", key), "potion")
		Sound.play_sfx("potion_done", -2.0)

## Bubbling potion VFX: rising golden bubbles over the Grimoire while brewing.
func _brew_vfx() -> void:
	var vp = get_viewport()
	if vp == null:
		return
	var overlay = Control.new()
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	vp.add_child(overlay)
	for i in 6:
		var bub = Sprite2D.new()
		bub.texture = UI.tex("res://assets/sprites/glow.png")
		bub.modulate = Color(0.95, 0.75, 0.35, 0.85)
		bub.scale = Vector2(0.2, 0.2) * (1.0 + 0.25 * float(i % 3))
		bub.position = Vector2(overlay.size.x * 0.5 + (i - 2.5) * 24.0, overlay.size.y * 0.5)
		overlay.add_child(bub)
		var tw = bub.create_tween()
		tw.set_parallel(true)
		tw.tween_property(bub, "position:y", bub.position.y - 130.0, 0.7 + 0.2 * float(i % 3)).set_trans(Tween.TRANS_SINE)
		tw.tween_property(bub, "modulate:a", 0.0, 0.9)
		tw.tween_property(bub, "scale", Vector2(0.55, 0.55), 0.9)
	var kill = overlay.create_tween()
	kill.tween_interval(1.3)
	kill.tween_callback(overlay.queue_free)

func _infer() -> void:
	var left = Store.undiscovered_formulas(Store.current_pathway())
	if left.is_empty():
		UI.toast("Every Formula of this pathway is known", "check")
		return
	if Store.spend("coins", 1000):
		var key: String = left[randi() % left.size()]
		Store.find_formula(key)
		Sound.play_sfx("unlock")
		UI.toast("Revealed: %s" % DB.formula(key).get("name", key), "scroll")

func _emergency() -> void:
	var left = Store.undiscovered_formulas(Store.current_pathway())
	if left.is_empty():
		UI.toast("Nothing left to unlock", "check")
		return
	if Store.spend("diamonds", 150):
		Store.find_formula(left[0])
		Sound.play_sfx("unlock")
		UI.toast("Emergency unlock: %s" % DB.formula(left[0]).get("name", left[0]), "diamond")
