# Windswept

The current game is an original **2D side-scrolling RPG** in the classic job-tree style, for **Godot Web Editor 4.7.2**.

Download **Side-Scroller-Warrior.zip** from this repository using GitHub's file download button. Choose it under **Preload project ZIP** in the Godot Web Editor, install the imported project, and click **Run Project**. Do not import the repository-wide Code → Download ZIP: the repository also preserves the earlier crypt prototype.

Current project source: [`side_scroller/`](side_scroller/). Full controls, classes, hunting grounds and modding notes: [`side_scroller/README.md`](side_scroller/README.md).

- **Four classes, ten paths, level 200:** Warrior (Duelist/Warlord/Champion, Shieldbearer/Runeknight/Templar, Lancer/Wyrm Knight/Dread Knight), Mage (Ember, Frost and Acolyte lines), Archer (Tracker and Arbalist lines) and Thief (Stalker and Brigand lines). Job advancements are at 10 / 30 / 70 / 120 (Mage at 8).
- **242 skills** with original names: attacks, buffs, passives, summons, heals, teleports, combo orbs, elemental brands and Shadow Twin.
- **An 87-map world:** 32 safe towns with regional hunting routes, ten deeper hunting grounds that run to level 200, and **12 boss lairs** reached from their towns. See [`side_scroller/WORLD_GUIDE.md`](side_scroller/WORLD_GUIDE.md).
- **49 new monsters** placed by theme (snails and mushrooms early, toys in Tickletop, fish and crabs in Tideglass, drakes in Wyrmrest...) and **12 bosses** with telegraphed attack patterns.
- **Ropes, ladders and tall hunting maps**, **128 town quests**, upgrade **scrolls**, **pets** that fetch loot, hair/face/skin **looks**, a **minimap**, painted **skill icons** and a level-up light pillar.
- Town Merchants with potions, gear, pets, selling, dismantling and the Forge.
- Seven skill hotkeys (Z X C V A D F), rebindable controls, four save slots and JSON backups. Saves from the earlier two-class version migrate with a full skill-point refund.

Default controls: **arrows** move, **Up** interacts and climbs, **Down** climbs down, **Shift** jumps/double jumps, **Space** attacks, **Z X C V A D F** use skills, **1/2** drink HP/MP potions, **I/M/K/S/Q** open Inventory/Map/Skills/Stats/Quests.

Full town names and travel guide: [World guide](side_scroller/WORLD_GUIDE.md). This is the first playable world pass; Pirate content is excluded. The current visual pass adds four dedicated character sheets, separate equipped weapons, attack poses, projectile trails, elemental effects and painted common monsters.

The original 3D crypt project remains at the repository root for preservation; the new standalone ZIP contains only the new 2D project.
