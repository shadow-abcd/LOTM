extends "res://scripts/sections/base.gd"
## The Altar: rituals spend reagents for a buff on the NEXT descent.

func _init() -> void:
	title = "The Altar — Rituals"
	icon_name = "altar"

func build() -> void:
	var rb: Dictionary = Store.d["ritual_buff"]
	if rb.is_empty():
		body.add_child(UI.wrap_label("No offering is waiting. Perform a ritual below; its blessing lasts for one descent.", 15))
	else:
		var parts: Array = []
		for k in rb.keys():
			parts.append("%s %s" % [k, str(rb[k])])
		body.add_child(UI.wrap_label("Waiting on the altar: " + ", ".join(PackedStringArray(parts)), 15, UI.GOLD))
	for r in DB.rituals:
		var rid: String = r["id"]
		var cost: Dictionary = r["cost"]
		var ok = Store.can_afford(cost)
		var acts: Array = [act("Perform", "flame", func(): _perform(rid), not ok)]
		card(UI.slot(DB.icon_for_glyph(str(r["glyph"])), "rare" if ok else "empty", 64, Color.WHITE if ok else Color(1, 1, 1, 0.4)),
			str(r["name"]), "READY" if ok else "MISSING", UI.GOOD if ok else UI.BAD,
			[[str(r["effect"]), UI.TEXT_DIM], ["Offering: " + UI.fmt_cost(cost), UI.TEXT]], acts)

func _perform(rid: String) -> void:
	var r = DB.ritual(rid)
	if r.is_empty() or not Store.pay(r["cost"]):
		return
	var rb: Dictionary = Store.d["ritual_buff"]
	match rid:
		"warmth": rb["hp"] = float(rb.get("hp", 0)) + 20.0
		"iron_vow": rb["hp"] = float(rb.get("hp", 0)) + 10.0
		"clarity": rb["reroll"] = int(rb.get("reroll", 0)) + 1
		"insight": rb["insight"] = float(rb.get("insight", 0.0)) + 0.10
		"moon_offering": rb["insight"] = float(rb.get("insight", 0.0)) + 0.20
		"owl_sight": rb["pickup"] = float(rb.get("pickup", 0.0)) + 0.15
		"blood_oath": rb["dmg"] = float(rb.get("dmg", 0.0)) + 0.10
		"unbound_page": Store.grant("items", "sealed_notebook")
		"borrowed_essence": Store.d["characteristics"] = int(Store.d["characteristics"]) + 1
		"sequential_inferer":
			var left = Store.undiscovered_formulas(Store.current_pathway())
			if left.size() > 0:
				Store.find_formula(left[randi() % left.size()])
	Store.d["ritual_buff"] = rb
	Store.commit()
	Sound.play_sfx("charm_use")
	UI.toast("The ritual is accepted", "flame")
