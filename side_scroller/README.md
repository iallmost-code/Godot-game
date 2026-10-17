# Windswept

An original, single-player 2D side-scrolling RPG for **Godot Web Editor 4.7.2**, built on the classic job-tree formula: four classes, ten advancement paths, level 200, hunting grounds and bosses. Uses the Compatibility renderer and no external assets or plugins. All class, job, skill, monster and boss names are original.

## Import the playable project

Choose **Side-Scroller-Warrior.zip** in the Web Editor landing page's **Preload project ZIP**, then start the editor. In the Install Project dialog, click **Install** with **Edit Now** checked. Once the project opens, click **Run Project**. Click inside the running game so it receives keyboard input. Use the editor's Run button if your browser captures function keys.

Use this standalone project ZIP, not GitHub's repository-wide Code → Download ZIP: that archive also contains the previous 3D prototype.

## Default controls

| Action | Key |
| --- | --- |
| Move | Left / Right arrows |
| Interact with portal or instructor | Up arrow |
| Jump; press again in air for a boosted double jump | Shift |
| Basic attack (sword/spear/dagger/staff swing, star or arrow; hold to repeat) | Space |
| Skill hotkeys | Z, X, C, V, A, D, F |
| Inventory / Map / Skills / Stats | I / M / K / S |
| Menu / close window | Escape or top-right buttons |

Rebind every key in **Menu → Controls**. Open menus pause the game.

## Classes and jobs

Pick a class in **Menu → Characters**. Each class has its own save slot. Advance by standing beside **Captain Elowen** in Willowbridge and pressing **Up**. At the second job you choose a path, and that choice is permanent.

| Class | 1st job | 2nd job (Lv 30) | 3rd job (Lv 70) | 4th job (Lv 120) |
| --- | --- | --- | --- | --- |
| Warrior | Squire (Lv 10) | Duelist | Warlord | Champion |
| | | Shieldbearer | Runeknight | Templar |
| | | Lancer | Wyrm Knight | Dread Knight |
| Mage | Initiate (Lv 8) | Ember Adept (fire/poison) | Cinder Magus | Inferno Archon |
| | | Frost Adept (ice/lightning) | Storm Magus | Tempest Archon |
| | | Acolyte (holy/healing) | Oracle | Hierarch |
| Archer | Scout (Lv 10) | Tracker (bow) | Falconer | Windmaster |
| | | Arbalist (crossbow) | Deadeye | Sharpshooter |
| Thief | Prowler (Lv 10) | Stalker (claw) | Shadeweaver | Nightblade |
| | | Brigand (dagger) | Cutthroat | Duskreaper |

Each advancement grants 1 skill point and a job weapon; every level after that grants 3 skill points for your current job. Novices earn up to 9 points for Shell Toss, Second Wind and Quickstep. Every level grants 5 attribute points. Main stats: Warrior **STR**, Mage **INT**, Archer **DEX**, Thief **LUK**.

There are 242 skills: attacks (melee, projectiles, area blasts, spells that fall from the sky, chain lightning, charges), buffs, passives, summons (Light Drake, Silverwing, Firebird, Dread Eye, Scarecrow decoys…), heals, Blink, Wayshrine (return to town), Shadow Twin, Momentum combo orbs and elemental Brands. Open **Skills (K)** to spend points (+1 or +5), read each skill's numbers and assign attacks and buffs to any hotkey. Later jobs show a preview of each path you could pick.

## Hunting grounds and bosses

From Willowbridge, open **Map (M)** and use **Travel** to fly to any hunting ground. Each ground has a portal back to town and portals to its boss lairs.

| Region | Levels | Monsters | Bosses |
| --- | --- | --- | --- |
| Whisperwood / Briar Hollow | 3-25 | Mossling, Lantern Bloom, Thornling, Briar Lantern | Rootwarden |
| Dewdrop Meadow | 1-12 | Pebble/Azure/Ember Snail, Puffspore, Stumpkin, Jellop, Tangerine Cap, Bristle Hog | Grand Shellmaw |
| Mossvale Thicket | 12-25 | Gloom Stump, Inkling, Mossy Cap, Hatchet Stump, Horned Cap, Tusker Boar | Elder Stumpus, Gelatinous Monarch |
| Rotfen Marsh | 25-45 | Rotcap, Wisp/Shade Wraith, Cinder Boar, Swamp Gator, Canopy Ape, Rubble Golem | Mother Cap, Blight Mother Cap |
| Emberpeak Canyon | 45-70 | Azure/Crimson/Frost Drake, Dune Lizard, Obsidian Golem | Lesser Hellwing |
| Frostspire Peaks | 60-85 | Frost Cub, Rime Wolf, Snowhorn, Moonfang Lycan | — |
| Clockwork Spire | 80-110 | Tick Sentinel, Stitched/Dread Bruin, Grim Clockwork, Phantom Timepiece | Chronovore |
| Bonepit Mine | 100-125 | Bonewalker, Bone Archer, Bone Captain, Magma Golem | Crimson Hellwing, Molten Colossus |
| Tidegrave Depths | 110-135 | Reef Snapper, Gloomfin, Tide Inkling, Coral Golem | Abyssal Leviathan |
| Skyreach Plateau | 125-160 | Storm/Cinder Centaur, Twinhead Birk, Bone/Skyscale Wyvern | Thornscale Wyrm |
| Timeless Sanctum | 155-200 | Memory Warden, Oblivion Monk, Chrono Guardian, Gloam Sentinel | Gloam Idol |

Monsters walk, hop, charge, cast, fly or tank. Bosses cycle through telegraphed patterns: **SLAM** and **LOW SWEEP** (jump over them), volleys, rain from above (move out of the red circles), summoned minions and charges. At half health they enrage and attack faster. Bosses resist stuns and freezes but not poison, armor breaks or weakening. Bosses always drop a weapon for your class; regular monsters drop coins, potions and level-banded gear.

Status effects shown as coloured dots over monsters: stun, freeze, poison (never kills), slow, silence, wither (harmless), weaken, armor break, snare, blind and mock (more damage and experience). You can dodge (**MISS**), block (**BLOCK**) and revive with Rebirth (**REBIRTH**).

Death returns you to town at full health with all progress kept.

## Saves

Progress and controls save in this browser's local project data. **Menu → Save** offers explicit saves and JSON backup export/import into the matching class slot. Saves from the earlier two-class version load automatically: jobs above the new thresholds step back (for example a level-65 Hermit becomes a Stalker until level 70), retired skills are removed, and **every skill point is refunded** once.

## Adding towns, art and content

- **Towns and starting areas:** add a fixed entry in `data/maps.gd` (`definition()`), with platforms, spawns, portals and optional enemies. Captain Elowen (job advancement) is placed by `world/map_controller.gd` in the `town` map.
- **Hunting grounds and bosses:** one row in `REGIONS` in `data/maps.gd`. Monster stats are in `data/enemy_stats.gd` (`ROSTER` and `BOSSES`).
- **Monster art:** monsters are drawn in code by `visuals/mob_art.gd` (one template per body type). To use a sprite instead, follow the `sprite` path in `actors/enemy.gd` used by the Mossling.
- **Player art:** Mage and Archer reuse the thief sprite sheet with a tint and a drawn staff/bow. Add `mage`/`archer` atlases to `visuals/character_visual.gd` and `visuals/atlas_layout.gd` to replace them.
- **Skills:** every skill is one entry in `data/catalog.gd`; display names are in `RENAMES` and `FAMILY_NAMES`.

## Development checks

From the project root:

```
godot --headless --editor --import --quit
godot --headless --script res://tests/runner.gd
```

The runner prints positive check counts and exits nonzero for failing assertions. It casts every skill of every fourth-job path and visits every hunting ground and boss arena. Engine script errors must also be treated as failures even when Godot returns zero. Native checks and visual capture do not alone establish Web Editor compatibility.
