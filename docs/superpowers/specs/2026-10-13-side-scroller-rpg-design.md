# Side-scrolling RPG: Warrior to Spearman

## Purpose and direction

Start a new game, replacing the necromancer concept. Build an original single-player 2D side-scrolling action RPG inspired by the user's long experience with MapleStory: cozy exploration and meaningful character progression combined with responsive modern movement, double jumping, clear damage numbers, and flashy mob attacks. The user's preferred first class is Warrior, with the spear branch as the first advancement path. No MapleStory assets, music, maps, or proprietary code are required.

This spec covers the first playable milestone and the progression model that supports later jobs. It does not promise a full MMORPG or every class in the initial ZIP. Existing crypt files and unfinished changes remain preserved; the new game will have its own Godot project under side_scroller/ in the existing checkout. Cloud tasks already run in isolation; no worktree is needed.

## First playable scope

Deliver a Godot 4.7.2 Compatibility-renderer project usable in the Godot Web Editor. Include one compact town with an instructor, a connected forest monster map with multiple platforms, a recognizable animated warrior with a spear, two original enemy types, pickups, basic equipment, XP and levels, stat allocation, a skill window, rebindable controls, local saving, and advancement from Beginner to Warrior to Spearman.

Use bright original 2D art with layered backgrounds, readable silhouettes, and animation for idle, running, jumping, attacking, and taking damage. Avoid static boxes as the final character presentation. Begin with compact original vector/sprite artwork rather than a large asset pipeline. The prototype needs coherent presentation and functional menus, not production-scale content.

The initial content implements first and second job skills. Third and fourth jobs and Hyper skills appear as clearly locked future tiers with descriptions; unimplemented abilities cannot be purchased or cast. Prototype XP is accelerated so the player can reach second job within roughly 15–20 minutes. This is a tuning target that requires playtesting, not a claim of measured completion time.

## Controls and movement

Default actions: Left/Right arrows move; Up interacts with an instructor or portal; Shift jumps; Space performs the basic attack; Z and X cast assigned skills; C is reserved for a future unlocked skill. Escape opens/closes the pause menu. Menus include buttons for Stats, Skills, and Controls, usable without keyboard shortcuts.

Use CharacterBody2D and collision-based platform movement. The first Shift press jumps; a second distinct press while airborne performs a forward-boosting double jump. The boost uses held horizontal direction, or facing direction when no direction is held. Holding Shift never repeatedly triggers jumps. Landing restores the double jump. Add short jump buffering and coyote time for forgiving controls. Attacks are permitted in the air, with a brief action lock rather than stopping all movement indefinitely.

The Controls menu lists actions, captures one key per action, rejects duplicate bindings with clear feedback, supports cancel and restore defaults, and saves bindings. Suppress gameplay input while menus capture keys. Use named InputMap actions everywhere; do not hardcode gameplay keys in actor scripts.

## Combat readability and balance

Space triggers a short spear combo with visible windup, active hit frames, and recovery. Damage uses a facing hitbox; an enemy is hit at most once per swing. Show impact effects, floating damage numbers, enemy health during combat, and a visible swing trail. The HUD shows health, mana, XP, level, job, potion count, and skill readiness.

Z starts as a small frontal sweep hitting several enemies. X starts as a forward thrust that damages and pushes normal mobs away. Double jump supplies mobility; there is no separate dash skill. Bosses and other explicitly heavy targets can resist push without taking reduced attack damage. C has no fake ready ability before one is unlocked and assigned.

Include a slow melee creature and a ranged creature with a clearly telegraphed attack. Enemies have a spawn area, aggro/leash rules, damage cooldowns, and predictable respawns. The town is safe. Spawn monsters away from portals and the forest entry. Brief invulnerability after a hit prevents overlapping monsters from deleting the player instantly. Early encounters should let a new player survive long enough to learn both skills. A starter healing potion button provides recovery with a cooldown.

Death returns the player to town at full HP/MP and preserves level, XP, allocated attributes, skills, job, collected currency, and equipment. Ground drops are temporary. No death XP penalty in this first milestone.

## Attributes, equipment, and stats window

Default assumption for approval: STR, DEX, INT, and LUK are the four allocatable attributes; HP, MP, attack, and defense are derived stats. Stamina is not an additional point pool in this version. Warrior strength affects melee damage; dexterity gives a smaller melee contribution; intelligence increases mana; luck affects critical chance with a cap. Every attribute also appears in the UI with an explanation, avoiding hidden effects.

Start at level 1 with 4 in each attribute. Gain 5 attribute points per level. Proposed initial formulas: maximum HP = 120 + 12 × (level − 1) + 2 × (STR − 4); maximum MP = 40 + 3 × (level − 1) + 2 × (INT − 4); base melee damage = weapon attack + STR + floor(DEX / 4); defense = equipment defense + floor(STR / 10); critical chance = min(25%, 5% + 0.2% × (LUK − 4)). Centralize these formulas for tuning. Allocate points with an explicit confirmation; show pending effects before spending. Do not silently auto-spend points.

Equipment initially has a weapon slot and an armor slot, with a small inventory showing icon, name, attack/defense, and an Equip action. Forest monsters drop coins, potions, and occasional spear/armor upgrades. Changes recompute derived values rather than stacking modifiers repeatedly. Save collected items and equipment. Inventory, currency, and potions remain separate from attributes.

## Jobs and skill progression

| Job tier | Level threshold | Spear branch | Sword branch (future) |
| --- | --- | --- | --- |
| First | 10 | Warrior | Warrior |
| Second | 30 | Spearman | Swordsman |
| Third | 60 | Dragon Knight | Crusader |
| Fourth | 100 | Dark Knight | Hero |
| Hyper | 140+ | Dark Knight enhancements | Hero enhancements |

These thresholds are the proposed approved-concept defaults, not an attempt to reproduce every version of MapleStory. The first prototype implements only the spear route through level 30 advancement. The instructor checks level, current job, and branch eligibility; advancement requires deliberate confirmation and cannot be repeated for extra points. First job provides 1 skill point and later levels provide 3 points in the current tier. Advancement to second job grants 1 second-tier point. Earlier-tier points remain available in their own pool; high-level points cannot accidentally be spent on a locked tier.

The skill window has job tabs, a prerequisite diagram, current/max rank, next-rank effect, cost, and an explicit Spend action. Use definitions with stable IDs, tier, level prerequisite, prerequisite ranks, maximum rank, active/passive type, skill-point pool, cooldown, mana cost, target count, and per-rank effects. Active skills can be assigned to Z/X/C through the window; reject duplicate assignments and visibly distinguish locked, learnable, learned, and equipped skills.

Beginner has a basic attack and double jump without skill-point costs. Warrior unlocks Spear Sweep on Z and Driving Thrust on X at first job with one usable starter rank each. Suggested Warrior passives are Strength Training (damage) and Iron Skin (defense). Starter ranks are recorded once, and are not charged again on load or repeat interaction.

Spearman introduces heavy mob clearing: Ground Wave sends a visible forward attack across several enemies; upgrades increase damage, reach, and target count. Spear Mastery strengthens earlier attacks, and Battle Vigor boosts durability. Ground Wave can replace Z while Driving Thrust remains useful on X. Skill ranks never hide the actual area reached by the effect.

Later design direction: Dragon Knight adds a larger erupting-spear area attack; Dark Knight adds powerful normal mob clearing, dedicated boss damage, and a long-cooldown map attack. Hero gets a distinct sword branch. Hyper begins at level 140 with passive modifiers (targets, reach, cooldowns), followed by active buffs and large burst skills at later milestones. Exact later-tier skills, milestone unlocks, and numbers require a separate content design before implementation. No placeholder entries may advertise working gameplay.

## Technical boundaries

Separate player movement, combat/ability execution, enemy AI, map/portal state, character progression, inventory/equipment, save storage, input bindings, and UI. Definitions use resources or validated data files with stable IDs; character state records allocated attributes, skill ranks/point pools, job branch, XP, inventory, equipment IDs, currency, potions, and bindings. UI requests validated operations from those systems rather than altering stats directly.

Scenes: town, forest, player, enemies, loot, HUD, pause menu, stats window, skill window, inventory, and controls. A shared game-state service persists the character between maps. Use collision layers to distinguish ground, player, enemies, damage hitboxes, and pickups. Pool or limit transient effects and floating numbers for browser performance. Pause world simulation while progression/control menus are open.

## Saving and delivery

Use versioned JSON under user:// with validation and atomic replacement. Save after leveling, point spending, advancement, item pickup/equip, and binding changes. Reject negative/overspent values, unknown skill/equipment IDs, impossible job states, and duplicate bindings safely. Corrupt saves produce a visible warning and preserve the original when possible.

Include explicit JSON save export/import for browser backup; browser-local storage is not automatic GitHub synchronization. Test native save logic independently from browser file transfer. Deliver a ZIP containing project.godot at its root and all necessary original source/assets, excluding Git metadata, caches, and credentials. Do not claim a workspace link is a downloadable attachment when the chat only previews it. GitHub artifact publishing requires the user's authorization for the new deliverable; prepare and verify the ZIP before that step.

## Acceptance and verification

Automated checks cover first/second jump eligibility and reset, buffered jump behavior, one hit per swing, multiple-target limits, thrust push, cooldown/mana consumption, post-hit invulnerability, equipment recalculation, stat spending, skill prerequisites/point pools, job threshold/duplicate advancement protection, multiple-level XP rewards, retained progression on death/map transition, binding conflict/capture behavior, and save round trips/corrupt data handling.

Playtest the actual presentation: town and forest transition; readable running/jumping/swinging animations; damage numbers; early survival; both Warrior skills; double jump across platforms; item equip; stat and skill upgrades; level-10 and level-30 advancement; remapping jump/attack; persistence after restart; and ZIP import in the Web Editor. Native/headless passing tests are separate from browser acceptance, which must remain marked unverified unless actually performed. Adjust early balance based on observed combat rather than promising that formulas alone make it fun.

## Next handoff

Review this written design before writing the implementation plan. The plan should stage movement/presentation, readable combat, progression/menus, maps/advancement, persistence, and tested ZIP delivery. The old 3D prototype is not the base gameplay architecture for this new game.
