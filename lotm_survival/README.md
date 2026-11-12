# Lord of the Mysteries: Survival — Godot 4 edition

Port + upgrade of the `LOTM_SURVIVAL` web prototype to **Godot 4.3+** (GL Compatibility renderer, runs on desktop, Android, iOS and Web).

## Run it
1. Install Godot 4.3 or newer.
2. Open `project.godot` in the editor and let it import assets once (about a minute).
3. Press F5.

Command line, first time only: `godot --headless --import`, then `godot --path .`

## What is in the game
| Area | Details |
|---|---|
| **Title** | Painted key art, embers, icon menu: Descend, Study, Settings, Quit |
| **Study** (hub) | One separate section per sidebar tab, each with its own icon: Pathways, Equipment, Rack, Shelf, Desk, Grimoire, Cabinet, Altar, Auction, Bestiary, Places |
| **Settings** | Five sections: Audio, Graphics, Controls (key rebinding + touch), Gameplay, Accessibility |
| **Descent** | Auto-fire survivors-like. 3 pathways, 10 abilities each, level-up draft, levels 1–100, Sequence 9 → 1, three gate bosses, six Places with hazards and unique enemies, Veilstep, spirit World, charms, artifact active |
| **HUD** | Vitality, Insight, Sequence and Place, ability slots with cooldown fill, boss bar, timers, charm/dash buttons, virtual stick on touch devices |

## "Forbid the forbids" — Lift the Forbids
Settings › Gameplay › **Lift the Forbids** (default **OFF**) enforces the original strict rules:
- Sequence gates (6, 2, 1) block a descent until the gate's Formula is found **and** its potion brewed
- Pathways, artifacts, charms and items must be purchased/unlocked (Diamonds and Coins)
- Artifact slots are earned, not given

Turn it ON to lift every lock: gates never block, all pathways, artifacts, charms and items are open to equip, and all three artifact slots are available.

## Controls
WASD / arrows move · Space Veilstep · R Spirit World · Q / E charms · F artifact active · 1–4 pick a draft card · P / Esc pause. All rebindable in Settings.

## Assets (all included)
- `assets/icons` — 76 generated icons (settings, equipment, inventory, every Study section, currencies, UI actions…), white on transparent so they can be tinted
- `assets/sprites`, `assets/portraits`, `assets/textures` — characters, relics, bestiary cut from your painted sheets; generated enemies, particles, ground tiles for each Place
- `assets/audio/sfx` — 39 sound effects · `assets/audio/music` — study, 3 pathway themes, boss theme · `assets/audio/ambience` — one loop per Place
- Everything procedural can be regenerated: `tools/build_all.sh [path/to/original/web/project]`

## Code map
`scripts/` autoloads: `db.gd` (JSON data), `cfg.gd` (settings + input), `store.gd` (save), `sound.gd` (buses, music, SFX), `ui.gd` (theme and widgets).
`scripts/screens`, `scripts/sections`, `scripts/run` — title/study/settings, the Study sections, the arena.
Game data lives in `data/*.json` (exported from the web version's JS modules).

## Design rules (A1 / B1)
Characteristics (+1 Star, one per ability, milestone order preserved) and the single global drop pool are implemented. Details and balance knobs: `docs/DESIGN_RULES.md` and `data/drop_tables.json`.

## Not verified
This was authored without a Godot editor available, so it has not been run. `tools/check_gd.py` checks indentation, brackets and autoload calls, but not the full GDScript grammar. Expect to fix a few small errors on first launch (the debugger will point at the line).

## Levels 1–100
- **In a descent:** level 1 to 100. Insight needed per level grows smoothly; each level adds +2 vitality and +1% damage. Every 10 levels is a milestone (full heal, +5% damage, +1 Diamond); every 20 adds a Fate reroll. At level 100 Insight turns into Coins.
- **Sequences by level:** 8 @ 8 · 7 @ 16 · 6 @ 26 (gate) · 5 @ 38 · 4 @ 50 · 3 @ 62 · 2 @ 76 (gate) · 1 @ 90 (final gate). Defeating the final gate boss ascends you.
- **Abilities** now level up to 10 (was 5), with scaling caps on blades, chains and areas.
- **Account level** also runs 1–100 (kills, descents and victories) and shows in the Study bar.
