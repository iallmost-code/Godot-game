# Sword, lunge, animation and Thief update

Approved scope: sword starter, controlled Driving Thrust lunge, improved walking, and a throwing-star Thief with a separate character slot.

Implemented:

- New Warrior-route characters carry a sword. First job awards Elowen's Sword; Spearman awards a spear. Older saves and owned weapons remain compatible.
- Driving Thrust uses a 0.16-second, approximately 64-pixel lunge through CharacterBody2D collision movement. Cast direction is fixed; rejected casts grant no movement. Hit recoil and map changes cancel the lunge.
- Original sword, spear and thief atlases provide eight walking poses per appearance. Animation phase follows movement speed, with explicit source rectangles and stable body/foot anchors. PNG artwork is unchanged by layout extraction.
- A separate Thief slot starts with a claw and ranged Star Throw. Elowen's level-10 advancement awards a claw, Twin Stars and Shadow Fan, with its own ranked skills, LUK damage scaling and equipment drops. Later Thief jobs are visibly marked as future content.
- Character switching saves the current slot before loading the other. Warrior retains the original save path; the selected slot persists. Cross-class backup imports reject atomically.
- Stars travel through space with continuous collision queries, stop at walls, hit enemies, and expire at their maximum range. Map changes remove old stars.

Validation:

- `python3 tools/verify_side_scroller.py`: **183/183 passed**, no script errors. Includes real collision lunge checks, projectile travel/impact/range/walls, separate slot round trips, legacy saves, class isolation and atlas alignment.
- Watched new class/animation/lunge checks fail before implementation. Review found that a forward muzzle could bypass a wall when pressed against it. Added touching-wall and thin-wall regressions; both failed before the body-origin/inside-hit fix and passed afterward.
- Read-only code review found no remaining Critical or Important issues after the fix.
- Godot 4.7.2 editor import completed without script errors. Native rendered sword town, Thief combat/Skills and a contact sheet of all walking poses were visually inspected; previews are in `docs/previews/`.
- Official Godot 4.7.2 Web Editor in Chromium: imported/installed the ZIP; confirmed sword startup; clicked Characters to create a Thief; used a valid level-10 backup fixture through the game's import callback; walked to Elowen and pressed Up; clicked Confirm advancement; pressed Z and observed two traveling stars and mana/cooldown updates. Switched back to the original level-1 Warrior without inheriting the Thief's level/job.
- `python3 tools/test_package.py`: archive integrity, root layout, script/art dependencies, explicit directory entries, cache/save exclusion and shipped ZIP/source byte parity passed. Final ZIP contains 82 source files (~18 MB); final metadata regeneration added only the test script UID after browser import.

Web Editor logs retained its upstream unsupported TCP debugger and main-thread warnings, with no game script errors. Software rendering was used for browser validation, so this does not establish browser performance. This remains a prototype; Thief first job is playable, Night Lord progression is future work.
