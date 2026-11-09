extends "res://scripts/sections/base.gd"
## Bestiary: painted portraits + the six region-unique enemies and their rules.

const PORTRAITS := ["hound", "knight", "eye", "lamplighter", "gilded", "bell", "lamp_man", "spider", "crowned"]
const NAMES := ["Torch Hound", "Rust Knight", "Wrapped Eye", "Lamplighter's Shade", "Gilded Sentinel", "Bell Widow", "The Lantern Man", "Stitched Brood", "The Crowned Shade"]

func _init() -> void:
	title = "Bestiary"
	icon_name = "bestiary"

func build() -> void:
	body.add_child(UI.label("Seen in the dark", 20, UI.GOLD, true))
	var grid = GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	for i in PORTRAITS.size():
		var v = VBoxContainer.new()
		var tr = TextureRect.new()
		tr.texture = UI.tex("res://assets/portraits/beast_%s.jpg" % PORTRAITS[i])
		tr.custom_minimum_size = Vector2(250, 166)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		v.add_child(tr)
		v.add_child(UI.label(NAMES[i], 15, UI.TEXT, false, HORIZONTAL_ALIGNMENT_CENTER))
		grid.add_child(v)
	body.add_child(grid)
	body.add_child(UI.label("Region-unique threats", 20, UI.GOLD, true))
	for e in DB.region_enemies:
		var seen: bool = str(e["id"]) in Store.d["codex"] or Cfg.gate_open()
		var sprite = "res://assets/sprites/enemy_%s.png" % e["id"]
		var elc: Color = DB.ELEMENT_COLORS.get(e["element"], Color.WHITE)
		var lines: Array = [
			[str(e["line"]), UI.TEXT_DIM],
			[str(e["detail"]), UI.TEXT],
			["Weak: %s   ·   Resists: %s" % [", ".join(PackedStringArray(e["weak"])), ", ".join(PackedStringArray(e["resist"]))], UI.GOLD_DIM],
		]
		var place = DB.place(str(e["place"]))
		card(UI.slot("", "epic", 96, Color.WHITE, sprite), str(e["name"]) if seen else "???", str(e["element"]).to_upper(), elc,
			lines if seen else [["Descend into %s to meet it." % place.get("name", "its Place"), UI.TEXT_DIM]], [])
