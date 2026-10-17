# Enemy hits and level scaling — 2026-10-17

User requested confirmation that enemies damage the player and that damage scales by enemy type and level. Existing melee/projectiles already removed HP, but damage was hard-coded and body contact did not hurt the player.

EnemyStats now defines names, fixed levels and type-specific base attack. Raw attack = base attack + 2 × (level − 1), with level clamped to 1–100. Contact uses 60%, regular melee/projectiles 100%, Rootwarden slam 140% and seeds 75%, truncating to integer before armor. Player armor subtracts from the hit with a minimum of 1 HP; existing 0.8-second invulnerability prevents overlapping hits from draining HP every frame. Starter enemies do not automatically level with the player.

| Enemy | Level | Normal raw attack |
| --- | --- | --- |
| Mossling | 3 | 8 |
| Lantern Bloom | 6 | 15 |
| Thornling | 18 | 42 |
| Briar Lantern | 22 | 51 |
| Rootwarden | 25 | 58 (slam 81, seed 43) |

Body contact applies to regular enemies and the boss, independently of their attack windups. Touching the boss during windup can hurt you; its slam remains avoidable by jumping outside body-contact range. Names show enemy levels; boss HUD includes level. Accepted hits emit actual HP lost and create purple negative numbers above the player. Outgoing critical numbers remain deep red. Death still returns the player to safe town with restored health and retained loot.

Validation: new enemy_damage suite first failed before implementation; 16/16 checks now pass, including contact, melee, real moving projectile collision, armor/minimum damage, invulnerability, stronger higher-level variants, boss attack calculation, fixed starter levels and lethal contact/town respawn. Full native suite: 287/287 passed without script/engine errors. Read-only review found no correctness blockers. Native contact capture shows level-1 player HP118/120 and a purple -2 from touching a level-3 Mossling. ZIP source parity and integrity passed.

Official Godot Web Editor 4.7.2 / Chromium: installed the final ZIP, entered Whisperwood through the town portal and walked into a level-3 Mossling. Browser capture confirms HP118/120 and purple -2. Enemy names/levels render correctly; the map window still opens. No script/page errors; upstream editor TCP-listen/Emscripten warnings remain. Preview: docs/previews/windswept-enemy-damage-web.png.
