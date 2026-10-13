# Side-scrolling Warrior RPG Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deliver a readable, animated side-scrolling RPG prototype with a town, forest, Warrior-to-Spearman advancement, stats, skills, equipment, configurable controls, and an importable ZIP.

**Architecture:** Create a separate project in `side_scroller/`; preserve the existing crypt project and its unfinished changes. Keep progression and data independent of world scenes, with player/enemy controllers owning movement and combat and UI calling validated services. Use original 2D artwork and short animations, with distinct visual effects for each attack.

**Tech Stack:** Godot 4.7.2, GDScript, CharacterBody2D, Compatibility renderer, original SVG/sprite assets, versioned JSON saves; Python standard-library ZIP tooling.

**Spec:** `docs/superpowers/specs/2026-10-13-side-scroller-rpg-design.md`

## Global Constraints

- Use the Godot Web Editor 4.7.2; native headless checks do not establish browser acceptance.
- Use the existing isolated checkout; do not create a worktree. Preserve `main.gd` and `tests/input_smoke.gd` changes in the crypt prototype.
- New Godot project root is `side_scroller/`; original source/art only, no external runtime dependencies.
- Default controls: arrows move, Up interacts, Shift jumps/double jumps, Space attacks, Z/X/C are skill slots, Escape opens menus.
- Implement Beginner, Warrior at level 10, and Spearman at level 30. Display third job at 60, fourth at 100, and Hyper at 140+ as unavailable future tiers.
- Four attributes STR/DEX/INT/LUK; start at 4 each, gain 5 allocation points per level. Keep HP/MP separate.
- First and second job advancement grant 1 tier-specific SP each; levels after advancement grant 3 SP in the current tier. Grant Sweep/Thrust starter ranks once without charging SP.
- Death retains character progression/equipment/loot and returns to town at full HP/MP; no XP penalty.
- Packaging places `project.godot` at ZIP root and excludes `.git`, `.godot`, saves, and credentials. A preview link is not a verified attachment.

## Review Focus

- Held jump keys and UI-focused key events: one press must produce one jump; rebinding must not cast or move the player (Tasks 2 and 5).
- Overlapping targets and simultaneous damage: each swing hits once per target, and player damage has invulnerability protection (Task 3).
- Large XP rewards and repeated instructor clicks: reward every earned level once; prevent duplicate advancement rewards (Tasks 1 and 6).
- Malformed/imported save data: unknown IDs, invalid jobs, negative/overspent points, and duplicate bindings cannot break the game (Task 7).
- Repeated map/menu transitions: no duplicate signals, item modifiers, enemies, or keyboard-capture state (Tasks 4–6).

## File and interface map

All paths below are relative to `side_scroller/` unless explicitly stated otherwise.

- `project.godot`, `main.tscn`, `main.gd`: configure the project, own map switching and service/UI assembly.
- `data/catalog.gd`: immutable skill, item, enemy, and job definitions keyed by stable IDs.
- `systems/character_state.gd`: owns level/XP, point pools, jobs, attributes, skills, resources, and equipment state.
- `systems/input_bindings.gd`: named InputMap actions, duplicate detection, capture validation, default bindings.
- `systems/save_store.gd`: validates and persists character/binding data; browser export/import.
- `actors/player.tscn`, `actors/player.gd`: player collision movement and interaction.
- `actors/combat_controller.gd`: timed attack windows and ability execution.
- `actors/enemy.tscn`, `actors/enemy.gd`: enemy movement, telegraphs, damage, death, and leash.
- `world/town.tscn`, `world/forest.tscn`, `world/map_controller.gd`: static platform layout, spawns, instructor, portals, and temporary drops.
- `world/loot_pickup.gd`: one-use pickup collision and state changes.
- `art/warrior.svg`, `art/spear.svg`, `art/forest_creature.svg`, `art/ranged_creature.svg`, `art/tiles.svg`, `art/town.svg`, `art/forest.svg`: original coherent art sources.
- `visuals/character_visual.gd`, `visuals/combat_effects.gd`: animated presentation and short-lived effects/damage numbers.
- `ui/hud.gd`, `ui/menu.gd`, `ui/stats_panel.gd`, `ui/skills_panel.gd`, `ui/inventory_panel.gd`, `ui/controls_panel.gd`: individual presentation/input responsibilities.
- `tests/runner.gd`, `tests/test_progression.gd`, `tests/test_movement.gd`, `tests/test_combat.gd`, `tests/test_equipment.gd`, `tests/test_ui.gd`, `tests/test_world.gd`, `tests/test_save.gd`: meaningful headless checks, nonzero failure exit.
- `README.md` and repository-root `tools/package_side_scroller.py`: user instructions and deterministic artifact creation.

## Common verification commands

Before commands, set `PATH=/workspace/tools/bin:$PATH`, `XDG_CACHE_HOME=/workspace/scratch/godot-cache`, `XDG_DATA_HOME=/workspace/scratch/side-scroller-tests-data`, and `XDG_CONFIG_HOME=/workspace/scratch/side-scroller-tests-config`; create these directories. From `/workspace/Godot-game`:

```bash
godot --headless --path side_scroller --editor --import --quit
godot --headless --path side_scroller --script res://tests/runner.gd -- --suite progression
godot --headless --path side_scroller --script res://tests/runner.gd
```

Suite names below map to `tests/test_<name>.gd`. The runner discovers its explicit list of suite files, prints executed assertion counts, reports failures, and returns 1 on any failure or zero checks. Individual suites expose `run(tree: SceneTree) -> void`. Write tests before their production behavior, run them red, then implement and run green. Missing scripts are a harness smoke failure, not the final regression demonstration; obtain a behavioral failing assertion before declaring the red step complete.

### Task 1: Character progression and project foundation

**Files:** Create `project.godot`, `main.tscn`, `main.gd`, `data/catalog.gd`, `systems/character_state.gd`, `tests/runner.gd`, `tests/test_progression.gd`.

**Interfaces:** `CharacterState` extends RefCounted and exposes `level: int`, `xp: int`, `job: String`, `attributes: Dictionary`, `ap: int`, `sp: Dictionary`, `skill_ranks: Dictionary`, `hp: float`, `mp: float`, and signal `changed`. Produce `add_xp(amount: int) -> void`, `xp_required(level: int) -> int`, `allocate_attributes(delta: Dictionary) -> bool`, `advance_job(job_id: String) -> bool`, `rank_up(skill_id: String) -> bool`, `derived_stats() -> Dictionary`, and `can_use(skill_id: String) -> bool`. Catalog exposes static `skills() -> Dictionary`, `items() -> Dictionary`, `jobs() -> Dictionary`. Later tasks extend this state without bypassing validation.

- [ ] Write progression assertions: initial level 1/attributes 4/AP 0; large XP advances multiple levels and grants `5 * levels_gained` AP; negative rewards do nothing; overspending attributes leaves all values unchanged; level 9 cannot advance; level 10 advances once and grants only 1 first-tier SP; level 30 advances to Spearman once; locked future jobs/skills remain unavailable; prerequisites and tier SP are enforced.
- [ ] Run `--suite progression` and record the failing behavior.
- [ ] Implement these interfaces. Use `xp_required(level) = 25 + 8 * level`, max implemented level 30; clamp rewards at that cap while keeping future thresholds in catalog metadata. Fill the exact derived-stat formulas from the spec. Define basic/Sweep/Thrust, Strength Training, Iron Skin, Ground Wave, Spear Mastery, Battle Vigor; max rank 5. Ground Wave requires Spear Mastery rank 1. Skill rows list next-rank values; active cooldowns/costs/targets are data, never UI constants. Suggested base values: Sweep 1.4× damage/3 targets/4 MP/1.2s; Thrust 1.2×/3 targets/5 MP/2s; Wave 2×/5 targets/8 MP/3s. Ranks add 0.15× damage and Wave adds reach/targets at ranks 3 and 5.
- [ ] Run progression suite and full runner; require positive assertion counts and exit 0.
- [ ] Commit only Task 1 paths with `feat: add side-scroller character progression`.

### Task 2: Animated player and platform movement

**Files:** Create `actors/player.tscn`, `actors/player.gd`, `systems/input_bindings.gd`, `visuals/character_visual.gd`, `art/warrior.svg`, `art/spear.svg`, `tests/test_movement.gd`; update `main.tscn`, `project.godot`.

**Interfaces:** Player exposes `facing: int`, `movement_enabled: bool`, `reset_at(position: Vector2) -> void`, `apply_knockback(impulse: Vector2) -> void`, signal `interact_requested`. InputBindings exposes `defaults() -> Dictionary`, `apply(bindings: Dictionary) -> bool`, `rebind(action: String, keycode: int) -> bool`, `current() -> Dictionary`. CharacterVisual exposes `set_pose(mode: String, facing: int, phase: float) -> void` for idle/run/jump/attack/hurt.

- [ ] Write physics tests using real player/floor nodes: one grounded jump, one airborne boost, third press rejected, landing restores jump, held input never repeats, 0.10s coyote time and 0.12s jump buffer work, double jump uses held direction or facing. Duplicate/invalid action bindings leave previous controls intact.
- [ ] Run `--suite movement` red.
- [ ] Implement collision movement with speed 220 px/s, gravity 1100, jump impulse −420, second jump −360 plus a brief 320 px/s horizontal boost. Use actions `move_left`, `move_right`, `interact`, `jump`, `attack`, `skill_z`, `skill_x`, `skill_c`, `menu`; assign approved defaults and named actions throughout. Draw a recognizable layered warrior/spear and animate it using pose phase; do not reuse crypt meshes.
- [ ] Run movement suite/full runner and import; visually verify running, both jumps, and camera framing in a render-capable environment if available.
- [ ] Commit Task 2 paths with `feat: add animated warrior and double jump`.

### Task 3: Readable, survivable combat

**Files:** Create `actors/combat_controller.gd`, `actors/enemy.tscn`, `actors/enemy.gd`, `visuals/combat_effects.gd`, creature art, `tests/test_combat.gd`; update player wiring and catalog enemy definitions.

**Interfaces:** CombatController consumes CharacterState and player facing/position; exposes `begin_attack(skill_id: String) -> bool`, `cancel() -> void`, signals `attack_started(skill_id: String)` and `impact(position: Vector2, damage: int, critical: bool)`. Enemy exposes `receive_hit(damage: int, push: Vector2, source_id: int) -> bool`, `is_heavy: bool`, signal `defeated(position: Vector2, definition_id: String)`. Player exposes `receive_damage(amount: int, impulse: Vector2) -> bool` with 0.8s invulnerability. Effects exposes `show_damage(position: Vector2, amount: int, critical: bool) -> void` and `show_attack(skill_id: String, origin: Vector2, facing: int) -> void`.

- [ ] Write assertions for one hit per swing, facing/range/target count, MP and cooldown charged only on valid activation, locked/unassigned skills rejected, airborne casts, thrust pushing ordinary enemies while heavy enemies take damage without push, overlapping attacks respecting invulnerability. Verify deaths reward once and skill visual lifetime spans active hit frames.
- [ ] Run `--suite combat` red.
- [ ] Implement short windup/active/recovery windows and two-step basic combo; base weapon attack 18, basic reach 100 px, Sweep 145 px, Thrust 170 px, Wave 300 px. Slow early enemies have 40 HP/6 contact damage; ranged enemies 32 HP/7 damage with a 0.7s visible tell. Telegraphs stop while paused. Add animated spear trails, distinct shockwave/thrust effects, impact flashes, floating numbers, and brief hurt feedback. Automatic per-target hit tracking prevents duplicate damage within a swing.
- [ ] Run combat/full suites. Play a zero-loot early encounter; verify the hero can survive several hits and every attack is visibly different. Report graphical checks as unrun if rendering is unavailable.
- [ ] Commit Task 3 paths with `feat: add spear combat and visible hit feedback`.

### Task 4: Equipment and pickups

**Files:** Create `world/loot_pickup.gd`, `ui/inventory_panel.gd`, `tests/test_equipment.gd`; extend state/catalog.

**Interfaces:** CharacterState adds `inventory: Array`, `equipment: Dictionary`, `coins: int`, `potions: int`, `add_item(item_id: String) -> bool`, `equip(item_id: String) -> bool`, `collect_reward(reward: Dictionary) -> bool`, `use_potion() -> bool`. LootPickup exposes `setup(reward: Dictionary) -> void` and emits `collected` once. InventoryPanel exposes `bind(state: CharacterState) -> void`.

- [ ] Test repeat equipping does not stack stats, wrong-slot/unknown IDs fail safely, pickups cannot reward twice, potion use respects inventory/cooldown and maximum HP, weapon/armor modifiers match the derived-stat formula.
- [ ] Run equipment suite red.
- [ ] Implement a starter spear (18 attack), training armor (2 defense), forest spear (24 attack), and forest armor (5 defense); start with 5 potions healing 40 HP and a 3s cooldown. Forest drops coins each defeat; add potion/gear drops through a centrally tunable loot table. Show item icons, stat comparisons, and Equip buttons; state owns all rewards and modifier computation.
- [ ] Run equipment/full suites; manually equip the same weapon twice and observe unchanged displayed damage.
- [ ] Commit Task 4 paths with `feat: add equipment inventory and loot`.

### Task 5: HUD, stats, skill trees, and controls menus

**Files:** Create all remaining `ui/` scripts and `tests/test_ui.gd`; update `main.gd` and bindings.

**Interfaces:** HUD exposes `bind(state: CharacterState, combat: CombatController) -> void`. Menu exposes `open_panel(panel_id: String) -> void`, `close() -> void`, signal `visibility_changed(open: bool)`. StatsPanel/SkillsPanel/ControlsPanel expose `bind(state: CharacterState, bindings: InputBindings) -> void`; SkillsPanel additionally produces validated `assign_skill(slot: String, skill_id: String) -> bool` via state. Bindings exposes capture result signal; controls cancel/reset use its existing APIs.

- [ ] Write actual UI/input-event tests: allocation preview does not mutate state before Confirm; Cancel restores draft; prerequisites/max ranks block spending; job tabs clearly distinguish future tiers; duplicate slots rejected; key capture suppresses jumps/attacks; Escape cancels capture before closing menu; duplicate keys rejected; restore defaults works; repeated open/close never multiplies signal listeners.
- [ ] Run UI suite red.
- [ ] Implement pause-aware menu nodes (`PROCESS_MODE_ALWAYS`) while world controllers remain pausable. Build HP/MP/XP bars, level/job/currency/potion display and Z/X/C readiness. Implement job tabs with connecting prerequisite lines, descriptions/rank upgrades/assignment buttons and locked later-tier descriptions. Add visible explanations for every attribute and pending derived-stat changes. C is clearly unassigned until explicitly equipped with an unlocked unique skill.
- [ ] Run UI/full suites; verify real viewport key events, not only direct function calls.
- [ ] Commit Task 5 paths with `feat: add progression and configurable controls menus`.

### Task 6: Town, forest, portals, and instructor advancement

**Files:** Create world scenes/controller, town/forest/tiles art, `tests/test_world.gd`; update main wiring.

**Interfaces:** Main exposes `change_map(map_id: String, spawn_id: String) -> bool`. MapController exposes `setup(state: CharacterState) -> void`, `spawn_position(spawn_id: String) -> Vector2`, signals `portal_requested(map_id: String, spawn_id: String)` and `advancement_requested(job_id: String)`. CharacterState owns advancement; instructor UI asks confirmation before calling it.

- [ ] Test transition retains character/equipment, old maps/enemies are released, invalid destinations leave current map intact, repeated portal interaction does not duplicate instances, town contains no hostile damage, monsters leash and respawn, death restores full resources in town while retaining XP/loot, instructor reward cannot repeat.
- [ ] Run world suite red.
- [ ] Build a cozy 1800 px town and a 3000 px forest with several reachable platform routes and layered parallax scenery. Keep a 400 px safe forest entry and no portal-adjacent spawns. Add visible interact prompts, an advancement confirmation panel, and direction signs. Give melee enemies 40 XP and ranged enemies 60 XP initially; mark the 15–20 minute second-job pacing as a playtest tuning target. Begin at level 1 with basic attack/double jump; instructor grants Warrior at 10 and Spearman at 30.
- [ ] Run world/full suites and play through town/forest/advancement with a test fixture setting XP rather than introducing an undocumented gameplay cheat.
- [ ] Commit Task 6 paths with `feat: add town forest and job advancement`.

### Task 7: Validated saving and browser backups

**Files:** Create `systems/save_store.gd`, `tests/test_save.gd`; extend state serialization and menu save controls.

**Interfaces:** State exposes `to_record() -> Dictionary`, `load_record(record: Dictionary) -> bool`. SaveStore exposes `save(state: CharacterState, bindings: InputBindings) -> bool`, `load_into(state: CharacterState, bindings: InputBindings) -> bool`, `export_json(state: CharacterState, bindings: InputBindings) -> String`, `import_json(text: String, state: CharacterState, bindings: InputBindings) -> bool`, signal `warning(message: String)`. Stage/validate both character and bindings before applying either.

- [ ] Test round trips retain all fields; invalid JSON/negative points/unknown IDs/impossible jobs/overspent ranks/duplicate keys reject atomically; missing optional fields use defaults; a failed save preserves the previous file; repeated load does not re-grant starter ranks or modifiers. Use a temporary test save directory.
- [ ] Run save suite red.
- [ ] Implement version 1 JSON in `user://side_scroller.json`; write a temporary sibling then replace after successful write, preserve corrupt originals with a backup name when possible. Connect saves to the spec's state-changing events. Export using `JavaScriptBridge.download_buffer` on web and a native file dialog elsewhere; import via a web file-selection bridge with FileReader and a native file dialog fallback. Disconnect browser callbacks on menu destruction, limit import size to 1 MiB, and visibly explain browser-local persistence and backup.
- [ ] Run save/full suites; test native export/import and record browser behavior separately, without claiming native checks prove browser APIs.
- [ ] Commit Task 7 paths with `feat: add validated saves and browser backup`.

### Task 8: Playtest, package, and delivery evidence

**Files:** Create `README.md`, repository-root `tools/package_side_scroller.py`; output ZIP outside the project (e.g. `/workspace/shared/downloads/Side-Scroller-Warrior.zip`).

**Interfaces:** Packaging CLI `python3 tools/package_side_scroller.py --output PATH` includes the new project only; it checks required entry files, archive integrity, duplicate paths, and excluded directories. README records controls, version, first/second job scope, and browser import steps.

- [ ] Write a packaging check proving archive root `project.godot`, all referenced assets/scenes included, no caches/Git/save files, and no crypt-project files. Run it red before implementing packaging.
- [ ] Implement packaging and truthful README. Exclude tests only if not referenced by runtime; keep documentation lightweight. Do not substitute a source ZIP of the whole repository for the importable project ZIP.
- [ ] Run full runner, clean headless import and `--quit-after 120` startup, then inspect archive contents/integrity. Record exact check counts and unresolved failures.
- [ ] Perform the spec's visual/manual acceptance checklist in a render-capable environment. In the Web Editor test ZIP import, keyboard focus, both jumps, attacks/effects, stat/skill allocation, job progression, controls capture, menu pause, map transition, and browser save backup. If browser access is unavailable, explicitly request this user playtest and label it unverified; do not claim completion of that check.
- [ ] Commit the source/documentation/packager with `feat: package side-scrolling warrior prototype`. Prepare a separate new ZIP file in the repository only if needed for an authorized GitHub download. Confirm the user's existing push authorization applies to this new deliverable before publishing; otherwise request approval of the concrete verified files.

## Self-review and delivery limits

The plan covers every first-milestone system in the approved spec, including controls configuration, both implemented job tiers, branch/future-tier metadata, persistence, and browser backup. Third/fourth/Hyper gameplay and other classes are deliberately future content, visibly locked. A successful automated suite is necessary but does not validate the art or Web Editor; final reporting must distinguish those outcomes. Do not continue old crypt fixes as part of this plan.
