# Windswept — Spearbound delivery evidence

First playable milestone: an original single-player 2D side-scrolling RPG for Godot Web Editor 4.7.2. Town, forest, animated warrior, double jump, readable attacks/damage numbers, XP, loot, equipment, attributes, skill ranks, configurable controls, saves, and Warrior/Spearman advancement are implemented. Third/fourth jobs and Hyper gameplay remain visibly locked future content.

## Verification

- Full native suite: **105/105 checks passed**, including real held input/echo, buffered jumping, one-hit-per-swing, target limits, knockback, cooldowns/mana, invulnerability, progression budgets, equipment, paused key capture, repeated map transitions, respawn/leash, atomic rejection of invalid save imports, and persistent startup warnings.
- Clean Godot 4.7.2 project import and 120-frame headless startup: no engine/script errors.
- Native OpenGL rendering: town, forest/attacks, and skill panel captured and visually inspected.
- Actual official Godot Web Editor 4.7.2 in Chromium: project ZIP imported and game started. Missing ZIP directory entries were caught in this real importer, fixed, and pinned by a packaging regression check.
- Browser UI: menus and skill trees displayed; a JSON backup downloaded and parsed successfully; a level-31 Spearman fixture imported through the registered browser callback and updated job, skills, and assignments visibly. Native tests cover invalid imports.
- Independent read-only whole-branch review found three Important issues: cross-tier SP budgets, overwritten corrupt-save warnings, and damage/visual direction drift. Each was reproduced with a failing test and fixed; the full suite is green afterward.
- Rank-dependent Ground Wave visuals were treated as Important, rather than the reviewer's Minor label, because hidden hit range harms combat readability. Presentation now receives the same effective range/origin/direction as damage.
- ZIP checks: standard archive integrity, all script dependencies included, project.godot at root, explicit directory entries, no caches/Git metadata/character saves.

## Remaining validation limits

The test browser uses software WebGL in a CPU-limited cloud environment; it is not a meaningful real-hardware combat/performance benchmark. Complete the normal-browser playtest for combat feel, platform routes, long-run pacing, and actual file-picker import. The browser callback import and download were exercised, but the file chooser was not used to select the fixture. The official web editor logs unsupported TCP-debugger and thread warnings; no game script errors appeared. The two-map art/content are prototype scope, not a full online world or a replica of commercial assets.

## Decisions carried from the execution ledger

- Track tasks/commits/test evidence manually because cloud skill helper scripts had no local executable path. Cost if wrong: bookkeeping can drift; commits and the verification report provide the retained evidence.
- Cap this prototype at level 40 rather than 30 so Spearman can earn enough points to learn Ground Wave after Mastery. Cost if wrong: extra progression to retune; later jobs remain unavailable.
- Use original articulated vector drawing rather than static SVG character sprites. Cost if wrong: future art work may replace drawing code with sprite animations.
- Construct map/platform/actor scenes in focused scripts rather than adding redundant scene-file wrappers. Cost if wrong: less convenience when arranging them in the scene editor; components remain separate.

Old crypt project files and its unrelated unfinished local changes are preserved. No worktree was created. Delivery follows the user's existing GitHub repository workflow; no force push or unrelated repository changes are needed.
