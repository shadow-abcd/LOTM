extends Node
## Chronicle Hooks (autoload): applies permanent story-flag effects during a
## descent without touching the large run.gd. run.gd / player.gd / pickup.gd
## call into these helpers; each one is safe to call with any arguments.

## Refused-pact blessing: revive once per descent at half vitality.
## Returns true if the player was revived (the descent continues).
var blessing_used := false

func reset_descent() -> void:
	blessing_used = false

func on_death(r) -> bool:
	if r == null or blessing_used:
		return false
	if Store.d.get("start_blessing", "") != "revive_half":
		return false
	blessing_used = true
	r.player.hp = r.player.max_hp * 0.5
	r.player.invuln = 1.5
	r.hud.announce("The Refused Pact Wakes", "You kept your soul. It keeps you — once.")
	r.fx.ring(r.player_center(), Color(1.0, 0.9, 0.6), 420.0, 0.8)
	r.fx.flash(Color(1.0, 0.9, 0.6), 0.4)
	Sound.play_sfx("victory", -6.0)
	for e in r.enemies:
		e.frozen = 1.2
	return true

## Bounty run: elites arrive twice as often. Call with the base interval.
func elite_interval(base: float) -> float:
	if str(Store.d.get("run_variant", "")) == "bounty":
		return base * 0.5
	return base

## Bounty run: coins picked up in the field are worth double.
func coin_value(v: float) -> float:
	if str(Store.d.get("run_variant", "")) == "bounty":
		return v * 2.0
	return v

## Confession run: Characteristics condense from elites five times as often.
func characteristic_chance(base: float) -> float:
	if str(Store.d.get("run_variant", "")) == "confession":
		return base * 5.0
	return base
