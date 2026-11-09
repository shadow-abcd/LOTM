extends "res://scripts/run/run.gd"
## Patch layer over run.gd: wires the Auto-aim setting (Settings > Controls) into
## targeting. The setting existed but nothing read it — abilities always auto-targeted.
##
##   Auto-aim ON  — original behaviour: shots seek the nearest enemies.
##   Auto-aim OFF — bolt abilities fire a forward fan in your facing direction,
##                  even with no enemy nearby.
##
## Why a subclass instead of editing run.gd: run.gd is the battle-tested core of
## the descent; this layer keeps it untouched and revertible with one line in
## main.gd. Long-term, fold this override back into run.gd's cast()/ _has_target().

func _has_target(a: Dictionary) -> bool:
	# Manual aim: bolt abilities may fire forward even with no enemy in range.
	if a["kind"] in ["shot", "clones"] and not bool(Cfg.get_v("auto_aim")):
		return true
	return super(a)

func cast(a: Dictionary) -> void:
	cast_count += 1
	_cur_aid = str(a["id"])
	_ab_add(_cur_aid, "casts", 1)
	var l = int(a["level"])
	var dmg = ability_damage(a)
	var el: String = a["element"]
	var col: Color = DB.ELEMENT_COLORS.get(el, Color.WHITE)
	var c = player_center()
	var big = false
	if pid == "wanderer" and cast_count % 4 == 0:
		dmg *= 2.0
		big = true
		fx.ring(c, Color(0.7, 0.6, 1.0), 120.0, 0.4)
	if quill_charges > 0:
		dmg *= 2.0
		quill_charges -= 1
	wake_near(c)
	match a["kind"]:
		"shot", "clones":
			var n = mini(6, 1 + int(l / 2.0) + (1 if a["kind"] == "clones" else 0))
			# Auto-aim ON: seek the nearest enemies. OFF: forward fan in the facing direction.
			var aim: Array = []
			if bool(Cfg.get_v("auto_aim")):
				for t in nearest_n(c, n, 620.0):
					aim.append(t.position + Vector2(0, -20))
			else:
				var fwd := Vector2(player.face, 0.0)
				for i in n:
					aim.append(c + fwd.rotated((i - float(n - 1) / 2.0) * 0.14) * 560.0)
			if aim.is_empty():
				return
			Sound.play_sfx("shoot_ember" if pid == "dawnbringer" else ("shoot_sigil" if pid == "wanderer" else "shoot_shard"), -4.0)
			for i in n:
				var origin = c
				if a["kind"] == "clones":
					origin = c + Vector2.from_angle(TAU * i / n) * 60.0
				_fire(origin, aim[i % aim.size()], dmg, el, 540.0, mini(4, int(l / 3.0)), randf_range(-0.05, 0.05) if i > 0 else 0.0)
		"aura":
			var r = minf(260.0, 85.0 + 14.0 * l)
			fx.ring(c, col, r, 0.35)
			Sound.play_sfx("cast_aura", -8.0)
			for e in enemies_near(c, r):
				damage_enemy(e, dmg, el, "aura")
		"pulse":
			var r2 = minf(420.0, 150.0 + 22.0 * l) + (60.0 if big else 0.0)
			fx.ring(c, col, r2, 0.5)
			fx.glow_pop(c, col, r2 * 0.8, 0.35)
			fx.shake(4.0 + l)
			Sound.play_sfx("cast_pulse", -2.0)
			for e in enemies_near(c, r2):
				damage_enemy(e, dmg, el, "pulse")
		"sigil":
			var t2 = nearest(c, 560.0)
			if t2 == null:
				return
			var at = t2.position
			var r3 = 80.0 + 8.0 * l
			fx.ring(at, col, r3, 0.55)
			Sound.play_sfx("telegraph", -10.0)
			get_tree().create_timer(0.55).timeout.connect(_sigil_strike.bind(at, r3, dmg, el, _cur_aid))
		"chain":
			var first = nearest(c, 420.0)
			if first == null:
				return
			Sound.play_sfx("chain_zap", -4.0)
			var hit: Dictionary = {}
			var prev = c
			var cur: Node2D = first
			for j in range(mini(9, 2 + l)):
				if cur == null:
					break
				hit[cur.get_instance_id()] = true
				fx.zap(prev, cur.position + Vector2(0, -20), col)
				damage_enemy(cur, dmg * pow(0.9, j), el, "chain")
				prev = cur.position + Vector2(0, -20)
				cur = nearest(cur.position, 190.0, hit)
		"mirror":
			if player.shield < 1 + int(l / 2.0):
				player.shield += 1
				fx.ring(c, Color(0.75, 0.85, 1.0), 70.0, 0.35)
				Sound.play_sfx("cast_aura", -8.0)
		"marionette":
			if allies.size() < 1 + int(l / 2.0) and ally_cd <= 0.0:
				ally_cd = 6.0
				_add_ally(10.0 + l * 2.0, dmg)
		"sleep":
			var r4 = minf(360.0, 160.0 + 16.0 * l)
			fx.ring(c, Color(0.6, 0.5, 0.9), r4, 0.6)
			Sound.play_sfx("cast_aura", -6.0)
			for e in enemies_near(c, r4):
				e.frozen = 1.5 + 0.3 * l
				if dmg > 0.0:
					damage_enemy(e, dmg, el, "sleep")
