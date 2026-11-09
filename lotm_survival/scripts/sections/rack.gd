extends "res://scripts/sections/base.gd"
## The Rack: Sealed Artifacts. Each one has a benefit and a curse.

const Equip = preload("res://scripts/sections/equipment.gd")

func _init() -> void:
	title = "The Rack — Sealed Artifacts"
	icon_name = "rack"

func build() -> void:
	body.add_child(UI.wrap_label("Sealed Artifacts grant power and charge a price. Slots: %d (more at account levels 10 and 25 — or all three when the Forbids are lifted)." % Store.artifact_slots(), 15))
	for e in Equip.entries("artifacts"):
		var id: String = e["id"]
		var owned = Store.owns("artifacts", id)
		var on = id in Store.equipped("artifacts")
		var price: int = int(DB.RARITY_PRICE.get(e["rarity"], 300))
		var lines: Array = [[str(e["text"]), UI.TEXT_DIM], ["◆ " + str(e["boon"]), UI.GOOD], ["◇ " + str(e["curse"]), UI.BAD]]
		if str(e["source"]) != "":
			lines.append(["Found: " + str(e["source"]), UI.TEXT_DIM])
		var acts: Array = []
		if not owned:
			acts.append(act("%d ●" % price, "coin", func(): _buy(id, price), Store.coins() < price))
		elif on:
			acts.append(act("Unequip", "close", func(): Store.unequip("artifacts", id)))
		else:
			acts.append(act("Equip", "check", func(): Store.equip("artifacts", id)))
		card(UI.slot(DB.icon_for_glyph(str(e["glyph"])), str(e["rarity"]), 96, Color.WHITE, str(e["painted"]) if owned or true else ""),
			str(e["name"]), str(e["rarity"]), UI.rarity_color(str(e["rarity"])), lines, acts)

func _buy(id: String, price: int) -> void:
	if Store.spend("coins", price):
		Store.grant("artifacts", id)
		Sound.play_sfx("unlock")
