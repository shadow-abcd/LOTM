extends RefCounted
## Global drop pool (B1). Every item can drop on every pathway; sources only choose a rarity.

const ORDER := ["Common", "Uncommon", "Rare", "Epic", "Mythic"]

static func weighted(w: Dictionary) -> String:
	var total = 0.0
	for k in w.keys():
		total += float(w[k])
	var r = randf() * total
	for k in w.keys():
		r -= float(w[k])
		if r <= 0.0:
			return str(k)
	return str(w.keys()[0])

static func source(name: String) -> Dictionary:
	return DB.drops.get("sources", {}).get(name, {})

## All entries of a kind ("artifacts" | "charms") at a rarity, falling back to lower rarities if empty.
static func pool(kind: String, rarity: String) -> Array:
	var list: Array = DB.artifacts if kind == "artifacts" else DB.charms
	var i = ORDER.find(rarity)
	while i >= 0:
		var out: Array = []
		for e in list:
			if str(e["rarity"]) == ORDER[i]:
				out.append(e)
		if not out.is_empty():
			return out
		i -= 1
	return list

## Roll one item. `unseen_only` prefers entries the account has never found.
static func roll(kind: String, tiers: Dictionary, unseen_only: bool = false) -> Dictionary:
	var p = pool(kind, weighted(tiers))
	if unseen_only:
		var fresh: Array = []
		for e in p:
			if not Store.item_seen(kind, str(e["id"])):
				fresh.append(e)
		if fresh.is_empty():
			return {}
		p = fresh
	if p.is_empty():
		return {}
	return p[randi() % p.size()]

## Gives the item to the account vault. Returns {"msg": String, "icon": String, "dupe": bool}.
static func award(kind: String, e: Dictionary) -> Dictionary:
	var id = str(e["id"])
	Store.mark_seen(kind, id)
	var icon = DB.icon_for_glyph(str(e.get("glyph", "")))
	if Store.has_item(kind, id):
		var coins = int(DB.drops.get("duplicate_coins", {}).get(str(e.get("rarity", "Common")), 40))
		Store.earn("coins", coins)
		return {"msg": "%s (duplicate: +%d coins)" % [e["name"], coins], "icon": icon, "dupe": true, "coins": coins}
	Store.grant(kind, id)
	return {"msg": "Found: %s" % e["name"], "icon": icon, "dupe": false, "coins": 0}

static func roll_reagent(tiers: Dictionary) -> Dictionary:
	var t = weighted(tiers)
	var out: Array = []
	for r in DB.reagents:
		if str(r["tier"]) == t:
			out.append(r)
	if out.is_empty():
		out = DB.reagents
	return out[randi() % out.size()]
