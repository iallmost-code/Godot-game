# Menu styling, shortcuts and damage display — 2026-10-17

The supplied references guided silver window frames, blue headers, green stat rows and an equipment inventory grid. User confirmed that Inner Ability rerolls and damage-formula changes are deferred. Combat values, crit chance and the 1.5x crit multiplier remain unchanged.

Menus use a draggable dark title bar, a close button and consistent tabs. Defaults: I Inventory, M World/Area Map, K Skills, S Stats, Escape Menu/Close. Pressing the current shortcut closes the window; another shortcut switches panels. All shortcuts can be rebound and saved. Old nine-action backups migrate without losing customized gameplay keys; conflicting new menu defaults receive a free key. Capture consumes shortcuts while rebinding, and opening menus pauses gameplay.

Stats retains +1/+5/All drafts and Confirm/Cancel, with two columns for attributes and detailed live values/damage previews. Inventory has selected-item inspection, original drawn item icons, equipped cards, coins and potion counts; selecting an item and equipping are distinct actions. Map displays the three areas, current location, platforms, portals and the boss location.

Damage numbers use bundled DejaVu Sans Bold Oblique (license included), two outline layers and a Compatibility-compatible canvas shader. Normal hits use a red/orange/yellow gradient; crits use deep red/pink. Numbers pop, float, fade and stack upward. A regression caught eight-star Shadow Partner volleys reusing visible rows; all still-visible lines now shift upward when a new hit arrives, including fading lines. World changes free existing number visuals.

Validation:
- Native Godot 4.7.2: 271/271 gameplay checks passed, with no engine/script errors.
- New shortcut tests first failed before implementation. Eight-line overlap regression separately failed before the stacking fix, then passed.
- Native rendered previews inspected for Stats, Inventory, Map, Skills, Controls and both damage colors. The damage-style screenshot uses illustrative amounts injected by an external capture script; gameplay displays actual damage values.
- Official Godot Web Editor 4.7.2 / Chromium: final ZIP installed and ran; I/M/K/S switched panels and repeat presses closed them. Real mouse drag moved the window. Traveled from town to Whisperwood, attacked a mossling and captured the actual orange/yellow 23-damage line; M reflected the new area and location. Font fallback boxes found in early browser captures were removed from the new stats/inventory labels. No script or page errors; the upstream editor logged TCP listen ERR_CANT_CREATE and Emscripten warnings.
- Standalone ZIP integrity, directory entries, all scripts, bundled font/shader and exact source parity passed.
- Read-only reviewer rechecked the stacking correction and found no remaining blockers.

Previews: docs/previews/windswept-menu-stats.png, windswept-menu-inventory.png, windswept-menu-map.png and windswept-damage-style.png.
