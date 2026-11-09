extends Node
## Chronicle Hooks: applies permanent story-flag effects during a descent
## without rewriting run.gd wholesale. Call Chronicles.bind(run) from a small
## patch in run.gd; until then, loadout-side and enemy-side effects still apply.

var run = null
var blessing_used := false

func bind(r) -> void:
	run = r
	blessing_used = false

## Called from run.gd's death check: returns true if the descent continues.
func on_death() -> bool:
	if run == null:
		return false
	if Store.d.get("start_blessing", "") == "revive_half" and not blessing_used:
		blessing_used = true
		run.player.hp = run.player.max_hp * 0.5
		run.player.invuln = 1.5
		run.hud.announce("The Refused Pact Wakes", "You kept your soul. It keeps you — once.")
		run.fx.ring(run.player_center(), Color(1.0, 0.9, 0.6), 420.0, 0.8)
		run.fx.flash(Color(1.0, 0.9, 0.6), 0.4)
		Sound.play_sfx("victory", -6.0)
		for e in run.enemies:
			e.frozen = 1.2
		return true
	return false

## Called from run.gd's elite spawn timer: returns the adjusted interval.
func elite_interval(base: float) -> float:
	if str(Store.d.get("run_variant", "")) == "bounty":
		return base * 0.5
	return base

## Called from run.gd's coin pickup: returns the adjusted value.
func coin_value(v: int) -> int:
	if str(Store.d.get("run_variant", "")) == "bounty":
		return v * 2
	return v

## Called from run.gd's elite loot roll: returns the adjusted characteristic chance.
func characteristic_chance(base: float) -> float:
	if str(Store.d.get("run_variant", "")) == "confession":
		return base * 5.0
	return base
