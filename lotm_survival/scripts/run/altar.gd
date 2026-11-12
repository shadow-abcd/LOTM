extends Control
## In-run Ritual Altar: spend this run's Coins on a Rare reagent or an Epic artifact from the global pool.

const Loot = preload("res://scripts/loot.gd")
var run = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var cfg = Loot.source("altar")
	var c1 = int(cfg.get("rare_reagent_cost", 60))
	var c2 = int(cfg.get("epic_artifact_cost", 300))
	var scrim = ColorRect.new()
	scrim.color = Color(0, 0, 0, 0.7)
	scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scrim)
	var c = CenterContainer.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(c)
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(560, 0)
	c.add_child(panel)
	var v = VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	panel.add_child(v)
	v.add_child(UI.header("Ritual Altar", "altar"))
	v.add_child(UI.wrap_label("Offer the Coins you carry. Whatever the altar gives is yours to keep, in every future descent. Coins held: %d" % run.coins_run, 16))
	v.add_child(UI.button("  Rare reagent — %d coins" % c1, "potion", _reagent.bind(c1), Vector2(0, 56)))
	v.add_child(UI.button("  Epic artifact — %d coins" % c2, "artifact", _artifact.bind(c2), Vector2(0, 56)))
	(v.get_child(v.get_child_count() - 2) as Button).disabled = run.coins_run < c1
	(v.get_child(v.get_child_count() - 1) as Button).disabled = run.coins_run < c2
	v.add_child(UI.button("  Leave", "back", _leave, Vector2(0, 48)))
	Sound.play_sfx("ui_open")

func _reagent(cost: int) -> void:
	if run.coins_run < cost:
		return
	run.coins_run -= cost
	var r = Loot.roll_reagent({"Rare": 1.0})
	Store.add_reagent(str(r["id"]), 1)
	run.reagents_found[str(r["id"])] = int(run.reagents_found.get(str(r["id"]), 0)) + 1
	run.hud.toast("%s received" % r["name"], DB.icon_for_glyph(str(r["glyph"])))
	Sound.play_sfx("charm_use")
	_close(true)

func _artifact(cost: int) -> void:
	if run.coins_run < cost:
		return
	run.coins_run -= cost
	run.give_item("artifacts", Loot.roll("artifacts", {"Epic": 1.0}))
	_close(true)

func _leave() -> void:
	Sound.play_sfx("ui_back")
	_close(false)

func _close(used: bool) -> void:
	run.altar_done(used)
	queue_free()
