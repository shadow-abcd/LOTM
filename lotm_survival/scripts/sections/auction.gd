extends "res://scripts/sections/base.gd"
## The Dark Auction: weekly rotation, same lots for everyone that week, paid in Diamonds.
## One item of each rarity from the global pool, plus two Formulas.

const Loot = preload("res://scripts/loot.gd")
const PRICES := {"Common": 15, "Uncommon": 30, "Rare": 70, "Epic": 140}

func _init() -> void:
	title = "The Dark Auction"
	icon_name = "auction"

func _lots() -> Array:
	var rng = RandomNumberGenerator.new()
	rng.seed = int(Store.week_key()) * 7919 + 13
	var lots: Array = []
	for tier in DB.drops.get("sources", {}).get("auction", {}).get("tiers", ["Common", "Uncommon", "Rare", "Epic"]):
		var kind = "charms" if tier in ["Common", "Uncommon"] else "artifacts"
		var pool: Array = Loot.pool(kind, tier)
		var e: Dictionary = pool[rng.randi() % pool.size()]
		lots.append({"id": "i_" + str(e["id"]), "kind": kind, "ref": e["id"], "price": int(PRICES.get(tier, 50)), "tier": tier})
	var pool2: Array = []
	for f in DB.formulas:
		pool2.append(f["id"])
	for i in 2:
		var key: String = pool2[rng.randi() % pool2.size()]
		pool2.erase(key)
		var tgt = int(DB.formula(key).get("target", 8))
		lots.append({"id": "f_" + key, "kind": "formula", "ref": key, "price": 60 if tgt >= 6 else (90 if tgt >= 3 else 150), "tier": "Rare"})
	return lots

func build() -> void:
	body.add_child(UI.wrap_label("The lots change every week (UTC) and come from the same global pool every pathway finds. Diamonds: %d ◆" % Store.diamonds(), 15, UI.GOLD))
	var bought: Array = Store.d["auction_bought"]
	for lot in _lots():
		var lid = "%s:%s" % [Store.week_key(), lot["id"]]
		var sold = lid in bought
		var price: int = lot["price"]
		var head = ""
		var sub = ""
		var line = ""
		var ic = "scroll"
		var rar = str(lot["tier"])
		if lot["kind"] == "formula":
			var f = DB.formula(str(lot["ref"]))
			head = str(f.get("name", "Formula"))
			sub = "FORMULA"
			line = str(f.get("hint", ""))
		elif lot["kind"] == "artifacts":
			var a = DB.artifact(str(lot["ref"]))
			head = str(a.get("name", "Artifact"))
			sub = str(a.get("rarity", "")).to_upper()
			line = "◆ %s   ◇ %s" % [a.get("boon", ""), a.get("curse", "")]
			ic = DB.icon_for_glyph(str(a.get("glyph", "")))
		else:
			var c = DB.charm(str(lot["ref"]))
			head = str(c.get("name", "Charm"))
			sub = str(c.get("rarity", "")).to_upper() + " CHARM"
			line = str(c.get("description", ""))
			ic = DB.icon_for_glyph(str(c.get("glyph", "")))
		var owned = lot["kind"] != "formula" and Store.has_item(str(lot["kind"]), str(lot["ref"]))
		if owned:
			line += "   (already in your vault)"
		var acts: Array = [act("Sold" if sold else "%d ◆" % price, "diamond", func(): _buy(lot, lid, price), sold or Store.diamonds() < price)]
		card(UI.slot(ic, rar, 64), head, sub, UI.rarity_color(rar), [[line, UI.TEXT_DIM]], acts)

func _buy(lot: Dictionary, lid: String, price: int) -> void:
	if not Store.spend("diamonds", price):
		return
	Store.d["auction_bought"].append(lid)
	match lot["kind"]:
		"formula": Store.find_formula(str(lot["ref"]))
		"artifacts": Loot.award("artifacts", DB.artifact(str(lot["ref"])))
		_: Loot.award("charms", DB.charm(str(lot["ref"])))
	Store.commit()
	Sound.play_sfx("unlock")
