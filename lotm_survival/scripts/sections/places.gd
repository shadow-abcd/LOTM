extends "res://scripts/sections/base.gd"
## The six Places: each has a hazard, an ambient gesture and a unique enemy. Sequence-locked per pathway.

func _init() -> void:
	title = "The Six Places"
	icon_name = "map"

func build() -> void:
	var pid = Store.current_pathway()
	for pl in DB.places:
		var here = false
		for s in range(10):
			if DB.place_for(pid, s).get("id", "") == pl["id"]:
				here = true
		var yields: Array = pl["yields"]
		var ys = ", ".join(PackedStringArray(yields.map(func(x): return str(int(x)))))
		var acc = Color(str(pl["accent"]))
		var ground = "res://assets/textures/ground_%s.png" % pl["id"]
		var lines: Array = [
			[str(pl["line"]), UI.TEXT],
			[str(pl["backstory"]), UI.TEXT_DIM],
			["Landmark — " + str(pl["landmark"]), UI.TEXT_DIM],
			["Hazard · %s — %s" % [pl["hazard"]["name"], pl["hazard"]["description"]], UI.BAD],
			["Sequences %s · unique enemy: %s" % [ys, DB.region_enemy(str(pl["uniqueEnemy"])).get("name", "?")], UI.GOLD_DIM],
		]
		card(UI.slot("", "rare" if here else "common", 110, Color.WHITE, ground), "%s · %s" % [pl["roman"], pl["name"]],
			"YOUR PATH" if here else "OTHER PATHWAY", acc, lines, [])
