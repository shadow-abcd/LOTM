extends "res://scripts/sections/base.gd"

func _init() -> void:
	title = "Pathways"
	icon_name = "pathways"

func build() -> void:
	for p in DB.pathways:
		var pid: String = p["id"]
		var unlocked = Store.pathway_unlocked(pid)
		var selected = Store.current_pathway() == pid
		var col = Color(str(p["color"]))
		var portrait = "res://assets/portraits/card_%s.jpg" % pid
		var art = UI.slot("", "mythic" if selected else "common", 120, Color.WHITE, portrait)
		var deepest = int(Store.d["deepest"].get(pid, 10))
		var lines: Array = [
			[str(p["fantasy"]), col],
			["Signature — %s: %s" % [p["mechanic"], p["description"]], UI.TEXT_DIM],
			["Boss — %s · starts with %s" % [p["boss"], DB.ability(pid, p["startingAbility"]).get("name", "?")], UI.TEXT_DIM],
			["Deepest Sequence reached: %s" % (("%d — %s" % [deepest, DB.title_for(pid, deepest)]) if deepest < 10 else "not yet descended"), UI.GOLD_DIM],
		]
		var actions: Array = []
		if selected:
			actions.append(act("Chosen", "check", Callable(), true))
		elif unlocked:
			actions.append(act("Choose", "play", func(): _choose(pid)))
		else:
			var price = int(p["price"])
			actions.append(act("%d ◆ Unlock" % price, "lock", func(): _buy(pid, price), Store.diamonds() < price))
		var head = "%s · %s" % [p["roman"], p["name"]]
		card(art, head, "LOCKED" if not unlocked else ("CHOSEN" if selected else "READY"), col, lines, actions)
	body.add_child(UI.wrap_label("Tip: Settings › Gameplay › Lift the Forbids opens every locked pathway.", 14, UI.TEXT_DIM))

func _choose(pid: String) -> void:
	Store.d["pathway"] = pid
	Store.commit()
	Sound.play_sfx("equip")

func _buy(pid: String, price: int) -> void:
	if Store.spend("diamonds", price):
		Store.unlock_pathway(pid)
		Sound.play_sfx("unlock")
