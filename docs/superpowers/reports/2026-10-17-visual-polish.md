# Character, weapon and combat visual pass

Based on the user's updated branch `claude/peaceful-brahmagupta-fzzn7z` at `63829913ddaab4d58372493ae3d03624867717b1`, preserving its full job tree, skills, enemy roster, boss encounters and merged world.

## Changes

- Four dedicated unarmed character sheets with eight walking frames, idle/jump/hurt and attack poses. Mage and archer no longer borrow tinted thief art.
- Separate painted equipment for sword, spear, dagger, claw, staff, bow and crossbow, with normal/upgraded appearances shared by the inventory icons.
- Frame-specific foot and hand anchors keep body placement stable and attach weapons to the hand; facing mirrors the entire grip assembly.
- Windup, strike, follow-through and recovery use the actual combat clock. Consecutive attacks restart; long volleys keep their attack pose. Shadow Twin mirrors equipment and timing.
- Textured slash, thrust, wave, impacts and elemental effects. Melee/spell visuals wait for windup; projectiles gain launch effects and short fading trails. Chain lightning rendering no longer consumes combat RNG.
- Sixteen painted common monster families with palette tint and subtle idle motion. Bosses and special variants retain their authored features; existing Mossling, Lantern Bloom and Rootwarden art remains.
- No damage, collision, cooldown, loot or progression balance changes in this pass.

## Verification

- Baseline updated branch: 335/335 checks passed.
- Native Godot 4.7.2 import and rendered captures: all four class pose rows, mirrored grips, town and melee combat inspected. Captures are in `docs/previews/visual-polish-*.png`.
- Final native regression suite: **350/350 passed**, with no script errors.
- Added regression coverage for real combat timing, repeated attacks, long volleys, actual dagger/crossbow equipment, mirrored grips and delayed melee/spell effects.
- Official Godot Web Editor 4.7.2 in Chromium: final ZIP imported and run; movement, sword attack/effect, inventory icons and switching to Mage/Archer/Thief exercised. No game script or JavaScript page errors. Upstream editor TCP-listen/thread warnings remain visible in this local browser harness. The first capture attempt timed out during cold import; the second allowed the larger art import to finish.
- ZIP integrity, directory entries, asset inclusion and shipped-source parity checked by `tools/test_package.py`.

The images are a first painted character/effect pass, not a finished customization or equipment layering system. Armor remains an inventory/stat item and does not change the body sheet. Common monsters use idle deformation rather than full frame-by-frame locomotion.
