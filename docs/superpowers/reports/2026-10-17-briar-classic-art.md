# Briar Hollow, bulk stats and classic art — 2026-10-17

Original artwork now uses chibi proportions, simplified clothing, bold outlines, mushroom cottages and chunky grass terrain, following the classic screenshot supplied in the conversation. Sword, spear and thief atlases retain eight walking frames with individual region/foot anchors. Monster and boss sprites, distant scenery and props use the same direction.

Briar Hollow is reached through the far-right Whisperwood portal (recommended level 15+). It contains stronger thornlings and briar lanterns, improved gear drops and Rootwarden (recommended 25+). The boss alternates a marked, jumpable ground slam with three seed projectiles, drops a matching weapon, and respawns after 45 seconds. Boss HUD reconnects on respawn. Spearman advancement preserves stronger equipped weapons.

Stats provides +1, +5 and All per attribute, remaining-point accounting, derived-stat previews and Confirm/Cancel. +5 clamps to the remaining budget; All stages all remaining points.

Validation:
- Native Godot 4.7.2: 247/247 gameplay checks passed, without engine/script errors. Includes bulk allocation, boss windups and jump avoidance, loot/save roundtrip, respawn/HUD binding, projectile cleanup and portal return positions.
- Native rendered captures inspected for town, stat layout, Briar and Rootwarden foot alignment/ground warning.
- Official Godot Web Editor 4.7.2 in Chromium: final standalone ZIP installed, project ran with revised art. Imported level-10 Warrior fixture, clicked STR +5, DEX All and Confirm, downloaded backup and asserted STR9/DEX44/AP0. No script or page errors. Editor itself logs TCP listen ERR_CANT_CREATE and Emscripten warnings in this browser environment.
- New-map travel and boss mechanics were verified natively; browser smoke covered import, town rendering, actual stat-button clicks and JSON export.
- ZIP integrity, required new assets/scripts, directory entries, cache/save exclusion and exact packaged-source parity passed.
- Read-only code review reported no Critical or Important findings.

Previews are in docs/previews/windswept-classic-web.png, windswept-bulk-web.png and windswept-rootwarden.png. Warrior third/fourth jobs, Hyper skills and additional Thief skills remain future content.
