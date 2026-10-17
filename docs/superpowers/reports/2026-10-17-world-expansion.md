# Windswept world expansion — 2026-10-17

The user requested original renamed equivalents of classic towns, starting areas and larger regions, then explicitly requested both the first island and entire larger world. Pirate content is excluded. Existing character sprite artwork is unchanged.

## Delivered world

The existing Willowbridge, Whisperwood and Briar Hollow remain. Thirty-one new safe towns each have a hunting route, producing 65 playable maps across 32 regions. Original names include Gullhaven, Starbough, Ironridge, Shadecross, Hollowroot, Skylume, Frostmere, Tickletop, Tideglass, Saffron Reach and Hourglass Sanctum. The packaged WORLD_GUIDE.md contains the complete reference-to-original naming table, route levels and parent connections.

Maps share the existing runtime and original enemy families, with reusable layout templates and themed buildings, backgrounds and terrain. New scenery covers harbor, treehouse, warrior lodge, city guild, root inn, cloud observatory, snow cottage, toy clocktower, desert house, pagoda, alchemy lab and shrine buildings. Separate terrain handles snow/ice, sand, paving, toy blocks, coral, highland rock, marble and beach sand. Generated source PNGs were copied unchanged; sprite regions are metadata, not pixel edits.

Every travel edge has a valid arrival spawn and return connection. All maps are reachable from Willowbridge. Arrivals sit away from portal activation radii. Town residents sit away from portals. New towns regenerate HP and become the current-session death checkpoint; restarting/loading still begins in Willowbridge. Captain Elowen remains available; Warden Bram and Mara Vex reuse the existing Warrior and Thief advancement flows. Character switching resets the checkpoint to Willowbridge.

The atlas browses all regions and town/trail maps, shows local platforms, portals and current position, and computes directions from the current area. Inspecting a region does not teleport the player. Regional enemy HP, damage and XP scale with route level. Wayfarer equipment drops at level35+ routes and Aethersteel/Aetherweave equipment at level60+ routes. Save validation accepts all new catalog equipment.

This is the first world-content pass. Regional quest stories, additional monster families, more bosses and additional playable classes remain subsequent content. Underwater maps use the existing walking/double-jump movement.

## Validation

- New world-expansion test failed before implementation, then passed all 15 checks. It verifies all65 maps instantiate, complete reachability, valid portal arrivals, reciprocal links, world bounds, safe towns, regeneration, checkpoint respawn, Warrior instructor interaction, regional enemy stats, atlas context and pathfinding.
- Full native Godot4.7.2 suite: 302/302 passed with no engine/script errors.
- Read-only review found no correctness blockers in travel, NPCs, checkpoints, loot/save validation, atlas or scenery metadata.
- Native rendered captures inspected for harbor, tree town, warrior town, thief city, snow, desert, underwater, toy town, temple and atlas. Foreground vegetation was moved away from landmark buildings; snow/desert/city/etc use distinct ground textures. Rounded tile end caps are excluded from repeat regions to avoid apparent floor gaps.
- Standalone ZIP integrity, asset presence, script dependencies, explicit directory entries, cache/save exclusion and exact packaged-source parity passed.

- Official Godot Web Editor4.7.2 / Chromium: final ZIP installed and ran. Opened M atlas, inspected Ironridge and its computed Willowbridge > Emberstep Ridge > Ironridge route. Closed atlas, walked to Willowbridge's left portal, traversed Saltwind Road and entered Gullhaven. Rendered harbor scenery, safe-town notice and current-region atlas with onward links confirmed. No script or page errors; upstream editor TCP-listen/Emscripten warnings remain. All65 maps were loaded natively; browser smoke exercised atlas and the first new travel route.

Previews: docs/previews/windswept-world-web-harbor.png, windswept-world-web-routes.png, windswept-world-snow.png, windswept-world-desert.png and windswept-world-underwater.png.
