extends "res://scripts/sections/base.gd"
## The Shelf: Charms (active, cooldown) and Mystical Items (passive utilities).

const Equip = preload("res://scripts/sections/equipment.gd")

func _init() -> void:
	title = "The Shelf — Charms & Items"
	icon_name = "shelf"

func build() -> void:
	body.add_child(UI.label("Charms  (Q / E in a descent)", 20, UI.GOLD, true))
	_rows("charms", 300)
	body.add_child(UI.label("Mystical Items", 20, UI.GOLD, true))
	_rows("items", 180)

func _rows(kind: String, price: int) -> void:
	for e in Equip.entries(kind):
		var id: String = e["id"]
		var owned = Store.owns(kind, id)
		var on = id in Store.equipped(kind)
		var lines: Array = [["◆ " + str(e["boon"]), UI.GOOD]]
		if str(e["curse"]) != "":
			lines.append([str(e["curse"]), UI.TEXT_DIM])
		if str(e["source"]) != "":
			lines.append(["Found: " + str(e["source"]), UI.TEXT_DIM])
		var acts: Array = []
		if not owned:
			acts.append(act("%d ●" % price, "coin", func(): _buy(kind, id, price), Store.coins() < price))
		elif on:
			acts.append(act("Unequip", "close", func(): Store.unequip(kind, id)))
		else:
			acts.append(act("Equip", "check", func(): Store.equip(kind, id)))
		card(UI.slot(DB.icon_for_glyph(str(e["glyph"])), str(e["rarity"]), 72), str(e["name"]), str(e["rarity"]) if kind == "charms" else "Item",
			UI.rarity_color(str(e["rarity"])), lines, acts)

func _buy(kind: String, id: String, price: int) -> void:
	if Store.spend("coins", price):
		Store.grant(kind, id)
		Sound.play_sfx("unlock")
