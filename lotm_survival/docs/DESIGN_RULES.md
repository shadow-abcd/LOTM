# Design rules implemented

## A1 — Beyonder Characteristics (`scripts/store.gd`, `scripts/sections/cabinet.gd`)
- Sacrifice 1 Characteristic: +1 Star on any ability, permanent.
- **One Characteristic per ability, ever** (`char_used`). Refused at ★5 (`Capacity reached.` tooltip).
- **Milestone order preserved.** Stars come from milestones in order (`MILESTONES`): ★1 100 casts · ★2 500 casts · ★3 2,000 casts · ★4 250,000 damage · ★5 1,000,000 damage. A Characteristic fills only the next unearned milestone, so ★2 → ★3 still leaves ★4 needing its 250,000 damage.
- Pathway-agnostic: the Cabinet lists the current pathway's abilities plus any ability from another pathway you have used.
- Casts and damage are tracked per ability during a run (orbit abilities count one cast per second, passives one per 5 s) and added to the save when the run ends; new Stars show on the result screen.
- Sources: final boss (guaranteed), weekly top tier, Borrowed Essence ritual, Mythic elite drop (0.15%).
- Star effect: +8% damage per Star on that ability.

## B1 — One global drop pool (`data/drop_tables.json`, `scripts/loot.gd`)
- Every pathway rolls the same table; sources only choose a rarity. Charms no longer carry a pathway tag.
- File is JSON instead of `.tres` so the web-exported data and the game share one format. Edit `data/drop_tables.json` to rebalance everything at once.

| Source | Implemented as |
|---|---|
| Common enemies | coins, hearts, Common reagents; a Poisson clock (mean 180 s) queues a Common charm |
| Elites | 35% Uncommon/Rare charm, 35% first-seen artifact, 1–2 Common reagents, formula chance, 0.15% Characteristic; a 20-minute clock queues a Rare artifact for the next elite |
| Boss gate (first clear, once per run per gate) | guaranteed Rare artifact + the next Sequence's Formula + 2 reagents |
| Final boss | 1 Characteristic + Epic artifact |
| Ritual Altar | in-run event every ~4 min; spend run Coins on a Rare reagent (60) or an Epic artifact (300) |
| Dark Auction | weekly: one Common, Uncommon, Rare and Epic item + 2 Formulas, paid in Diamonds |
| Codex milestones | 2nd, 4th and 6th unique enemy met grants a Mystical Item |

Duplicates convert to Coins (40 / 90 / 200 / 500 / 1,200 by rarity).

## Decision log status
1 pathways 0 / 400 / 650 ◆ ✔ · 2 run structure ✔ · 3 milestone Stars ✔ · 4 Formulas required ✔ (when *Lift the Forbids* is OFF; it is ON by default) · 5 ✔ · 6 ✔ · 7 ✔ · 8 ✔ · 9 not started (22 pathways is content work).
