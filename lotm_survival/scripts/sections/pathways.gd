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
		# Phase D-2: Mastery progress for this pathway.
		var m: Dictionary = Store.mastery_data(pid)
		var marks: Array = []
		if bool(m.get("seq5", false)):
			marks.append("Sequence 5 ★")
		if int(m.get("kills", 0)) >= 5000:
			marks.append("5,000 kills ★")
		if bool(m.get("win", false)):
			marks.append("Victor ★")
		var mtext: String = " · ".join(marks) if marks.size() > 0 else "Mastery: %s kills" % Store.fmt_num(float(m.get("kills", 0)))
		lines.append(["Mastery — %s (+2%% dmg / +5%% coins / +10%% vitality when earned)" % mtext, UI.TEXT_DIM])
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
	if Store.ascended_available():
		# Phase D-2: Ascended Descent launcher — unlocks after your first victory.
		var best = int(Store.d["ascended"].get("best_seq", 9))
		var aw = int(Store.d["ascended"].get("wins", 0))
		body.add_child(UI.divider())
		var h = HBoxContainer.new()
		h.add_theme_constant_override("separation", 12)
		var lb = UI.label("ASCENDED DESCENTS", 20, Color(0.9, 0.45, 0.35), true)
		lb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(lb)
		h.add_child(UI.button(" Ascend and Descend", "flame", _start_ascended, Vector2(220, 48)))
		body.add_child(h)
		body.add_child(UI.wrap_label("The Place remembers more than it should: enemies are +40% stronger, elites come twice as often. Reagents drop double and every gate boss carries an extra Characteristic. Best Ascended depth: %s · Victories: %d" % ("Sequence %d" % best if best < 9 else "—", aw), 14, UI.TEXT_DIM))
	else:
		body.add_child(UI.wrap_label("Win a descent once (Sequence 1) to unlock Ascended Descents.", 14, UI.TEXT_DIM))
	body.add_child(UI.wrap_label("Tip: Settings › Gameplay › Lift the Forbids opens every locked pathway.", 14, UI.TEXT_DIM))

func _choose(pid: String) -> void:
	Store.d["pathway"] = pid
	Store.commit()
	Sound.play_sfx("equip")

func _buy(pid: String, price: int) -> void:
	if Store.spend("diamonds", price):
		Store.unlock_pathway(pid)
		Sound.play_sfx("unlock")

## Phase D-2: arm the Ascended flag and begin the descent.
func _start_ascended() -> void:
	Store.d["pending_ascended"] = true
	Store.commit()
	Sound.play_sfx("gate_open", -2.0)
	UI.goto("run")
