# Necromancer Crypt: first playable design

## Goal and agreed direction

Create a small single-player dungeon action RPG inspired by the user's favorite Diablo 3 summon build, with original characters, assets, and ability details. The player is a power-hungry necromancer commanding skeletons and a golem, chaining corpse explosions, collecting loot, and growing stronger. Success means that this combat-and-loot loop feels satisfying in one complete short dungeon.

Use Godot 4.7.2 with GDScript and the Compatibility renderer for the browser-based Godot Web Editor. Use low-detail stylized 3D, a fixed angled overhead camera, dark gothic stonework, and bright readable spell effects. Start with original primitive geometry and simple effects; polished assets are a later step.

## First playable scope

One handcrafted crypt with an entrance, two combat rooms, an elite encounter, and a boss chamber; target roughly five minutes for a successful run. Include one hero, three skeletons maximum, one golem, two regular enemy types, one elite variant, one boss, and six abilities. Exclude random dungeon generation, multiple classes, multiplayer, a town, quests, skill trees, and browser game deployment from this first build.

Enemy types: a melee crypt guard and a ranged grave acolyte. The elite is an armored guard that yields the first golem trait. The boss has a clearly telegraphed area slam and summons guards at a health threshold. All enemies have readable health feedback and distinct silhouettes.

## Movement and combat

Left-click valid floor to move using navigation around walls. Clicking an unreachable destination must leave the last valid command intact. The camera stays at a fixed angle and follows the hero. Keys 1–6 cast toward the cursor's ground position or target. UI clicks never issue movement commands. Invalid casts consume no resources and show brief feedback.

Skeletons and the golem follow the hero, acquire nearby enemies automatically, and return when enemies leave their leash range. Clicking to move does not require holding the mouse. The hero begins each fresh run with three skeletons and one golem. Summons have health and can die; the golem respawns after a cooldown. Raise Skeleton replaces lost skeletons, up to the cap.

| Key | Ability | Rule |
| --- | --- | --- |
| 1 | Bone Bolt | Aimed basic projectile; no corpse requirement and always available between its short cooldowns. |
| 2 | Raise Skeleton | Consumes the nearest valid corpse to the cursor within cast range; fails at the summon cap. |
| 3 | Corpse Explosion | Consumes one eligible corpse within range and damages nearby enemies; damage can create further corpses. |
| 4 | Golem Slam | Commands the living golem to move toward a valid target point and slam; uses a cooldown. |
| 5 | Soul Siphon | Damages one enemy within range and heals the hero; uses a cooldown. |
| 6 | Undead Frenzy | Temporarily increases living summons' attack speed; uses a longer cooldown. |

Initial balancing values will be centralized as editable resources. No mana system is needed for the first version: cooldowns and corpses provide the constraints. Corpses are one-use resources shared by Raise Skeleton and Corpse Explosion, expire after 30 seconds, and have a visible marker. One corpse cannot be consumed twice, including by simultaneous input.

## Loot, progression, and original twist

Normal enemies can drop a small selection of equipment; the elite and boss have guaranteed drops. Use two equipment slots initially: focus and charm. Items improve one clear stat, such as Bone Bolt damage or summon damage, and show an understandable comparison before equipping. Inventory and equipment persist across death and reload.

The first original mechanic is stealing an elite trait for the golem. Defeating the armored elite grants Bone Plating: equipping that trait reduces golem damage taken and visibly adds armor pieces. Implement one trait and one trait slot; expanding to mutually exclusive traits is later work. Picking up the trait is explicit and permanent, and a saved collection flag prevents duplicate unlocks after death resets.

Loot is picked up by clicking a nearby drop; clicking a distant drop first moves within pickup range. Include a small inventory panel and ability bar with cooldowns, player health, summon counts, and golem state. Enemy health bars appear during combat. Boss defeat displays a clear victory message and offers a new run retaining owned loot.

## Death and saving

Death returns the hero to the entrance with full health, three skeletons, and a golem. Reset enemies, corpses, ground drops, and room progress while retaining collected items, equipment, and the unlocked golem trait. Starting another run after victory uses the same reset rules.

Save a versioned JSON record under user:// after item pickup, equipment changes, and trait acquisition. Validate loaded fields and provide defaults for missing fields. A corrupt save is preserved as a backup when possible and triggers a visible fresh-start warning rather than crashing. Use an atomic temporary-file replacement strategy.

Browser persistence belongs to the browser editor's project storage and may be lost when site data is cleared or a different browser is used. Add JSON save export/import through browser-supported download/file selection so retained loot can be backed up explicitly. A project ZIP is source transfer and must not be described as an automatic save backup. Native validation can verify save logic; browser storage and download/upload behavior require an actual browser check.

## Technical structure

Separate scenes/scripts for the dungeon, hero controller, combatants, summons, enemy AI, corpses, loot pickups, HUD, and inventory. Use resources for abilities, enemy parameters, and item definitions. A run controller owns room and death resets; a progression service owns inventory, equipment, traits, and save validation. Combat events feed health changes, death/corpse creation, loot drops, and UI through explicit signals rather than UI-dependent combat logic.

Use NavigationRegion3D and NavigationAgent3D for floor movement, CharacterBody3D for mobile combatants, and collision layers separating floor, blockers, actors, projectiles, and pickups. Cast aiming uses a floor raycast; projectile and area damage track targets to prevent repeated accidental hits. Keep effects and shadow counts small for browser performance. Deliver a ZIP with project.godot at its root, required source/assets, and no .git, .godot cache, or credentials.

## Validation and acceptance

Run headless import and meaningful automated checks for damage/death, single-use corpses, summon caps, ability cooldowns, equipment modifiers, persistence round trips, corrupt saves, and death resets retaining loot. Exercise a complete encounter and boss progression in a headless simulation with explicit assertions; a zero-test result does not count.

Manual browser acceptance: import the ZIP in Godot Web Editor 4.7.2; run the project; click around obstacles; cast all six abilities; recover lost skeletons; chain an explosion; command a golem slam; acquire and equip loot and Bone Plating; die and verify retained loot; defeat the boss; reload and verify persistence; export and import a save. Check that UI clicks do not move the hero and combat remains readable. Browser acceptance is pending until actually performed and must be reported separately from native/headless results.

## Current repository and delivery constraints

The inspected checkout /workspace/Godot-game is empty and has an unborn work branch. This is a new project. Existing verified native Godot 4.7.2 tooling assists validation but does not connect to or control the user's open Web Editor. No synchronization with browser storage is assumed. Work in the existing isolated checkout without a worktree. Implementation requires a separately reviewed implementation plan after this written design is approved.
