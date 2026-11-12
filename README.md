# Lord of the Mysteries: Survival

An occult survivors-like in the world of Lord of the Mysteries. Pick a Pathway, descend into the Place, survive the horde, climb Sequences. Built with Godot 4.3 (GL Compatibility renderer, works on mobile). You play as a fully 3D animated character (Red Priest, Hermit, or Demoness) rendered live into a 2D arena.

## Setup

Always download the latest ZIP before opening the project. Old downloads cause "Failed to load script ... Parse error" errors that are not real bugs.

1. Open the repository on GitHub, tap Code, then Download ZIP
2. Delete any old LOTM-main folder on your device
3. Extract the new ZIP (for example with ZArchiver on Android)
4. Open Godot, Import, select lotm_survival/project.godot, then Import and Edit
5. Wait about a minute for the asset import, then press Play

If Godot shows parse errors in enemy.gd, pickup.gd, or store.gd after downloading, your copy is stale. The scripts are fixed on main. Re-download the ZIP, do not try to fix the files by hand.

## Godot version

Use Godot 4.3.x exactly. Time.get_unix_time_from_system() takes no arguments in 4.3; newer editor versions expect a different signature and will flag valid calls as parse errors. Pin the editor to 4.3.x.

## Controls

- Move: WASD / arrows, or the left-half virtual stick on touch
- Veilstep (dash): Space, or the dash button
- Spirit World: R, or the eye button
- Charms: Q and E, or the charm buttons
- Artifact: F, or the artifact button
- Pause: P or Esc, or the pause button

## Project layout

- project.godot: Godot 4.3 project, GL Compatibility renderer
- scenes/main.tscn: single scene, everything else is built in code
- scripts/run/run.gd: main gameplay loop
- scripts/run/character3d.gd: 3D pathway characters, animated live
- scripts/sections: Study screens (altar, auction, chronicle)
- scripts/screens: title, study, settings menu
- assets: sprites, textures, fonts, icons

## Save data

Saves live in user://save.json and settings in user://settings.cfg. Erase from Settings, Gameplay, Erase save (tap twice to confirm).
