extends "res://scripts/sections/base.gd"
## The Grimoire: nine permanent Formulas per pathway. A Formula must be FOUND, then its potion BREWED.

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
		card(UI.slot("potion" if found else "scroll", rar, 64, Color.WHITE if found else Color(1, 1, 1, 0.35)),
			"Seq %d · %s" % [int(f["target"]), DB.title_for(pid, int(f["target"]))], state.to_upper() + gate, UI.GOLD if brewed else UI.TEXT_DIM, lines, acts)

func _brew(key: String) -> void:
	if Store.brew(key):
		Sound.play_sfx("brew")
		Sound.play_sfx("potion_done", -2.0)
		UI.toast("Potion brewed", "potion")

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
