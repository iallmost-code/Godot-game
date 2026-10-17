# Windswept — Spearbound

An original, single-player 2D side-scrolling RPG prototype for **Godot Web Editor 4.7.2**. Uses the Compatibility renderer, original chibi sprites, bold cartoon outlines and layered pixel-style scenery, and no external assets or plugins.

## Import the playable project

Choose **Side-Scroller-Warrior.zip** in the Web Editor landing page's **Preload project ZIP**, then start the editor. In the Install Project dialog, click **Install** with **Edit Now** checked. Once the project opens, click **Run Project**. Click inside the running game so it receives keyboard input. Use the editor's Run button if your browser captures function keys.

Use this standalone project ZIP, not GitHub's repository-wide Code → Download ZIP: that archive also contains the previous 3D prototype.

## Default controls

| Action | Key |
| --- | --- |
| Move | Left / Right arrows |
| Interact with portal or instructor | Up arrow |
| Jump; press again in air for boosted double jump | Shift |
| Basic sword/spear attack or star throw (hold to repeat) | Space |
| Assigned skills | Z / X / C |
| Inventory | I |
| World / area map | M |
| Skills | K |
| Character stats | S |
| Menu / close window | Escape or top-right buttons |

Menus use a silver frame, blue headers and green stat rows. Drag the dark title bar to move the window. The same shortcut closes its panel; another menu shortcut switches panels. Inventory uses a selectable equipment grid: click an item to inspect it, then Equip. The map shows all three connected areas, your location, portals and the boss location.

Rebind all gameplay and menu shortcuts through **Menu → Controls**. Escape cancels a pending key capture. Each action needs a unique key; restore defaults is available. Open menus pause the game.

## Your first journey

1. Begin as a level-1 Beginner on the Warrior route in **Willowbridge**, carrying a sword. To try the throwing-star Thief, open **Menu → Characters → Play / Continue: Thief**. The two slots keep their own character progress and controls; switching saves the current character. Space and double jump are available immediately. **Z/X/C start unassigned**.
2. Go right to the glowing arch. Press Up nearby to enter the **Whisperwood**.
3. Defeat mosslings and lantern blooms for XP. Walk over drops to collect coins, potions, and equipment. Potion button heals you; mana regenerates over time.
4. Spend attribute points in Stats (STR, DEX, INT, LUK). Each row has **+1, +5, and All**; +5 uses up to five remaining points and All puts every remaining point into that attribute. Review the preview, then Confirm points, or Cancel draft. Warrior weapon damage scales with STR; throwing damage scales with LUK, with a smaller DEX contribution to both. Compare and equip class-appropriate drops in Inventory.
5. At **level 10**, return to town, stand beside **Captain Elowen**, and **press Up** (clicking the NPC does not interact). Confirm your route's advancement. Warriors receive a sword and **Z: Crescent Sweep / X: Driving Thrust**. Thieves receive a claw and **X: Shadow Fan** (Z is free). Skills are assigned automatically.
6. Use Skills to increase ranks and assign or swap learned skills onto Z/X/C. **Driving Thrust lunges roughly 64 pixels forward**, respects walls, and pushes monsters. Thieves have actual traveling star projectiles, job-based basic volleys and a three-star fan; walls block projectiles. Stars need no ammunition.
7. On the **Warrior route**, at **level 30**, return to Elowen to advance to Spearman and receive a spear. Learn **Spear Mastery**, then earn more second-job skill points by leveling and learn **Ground Wave**. Assign it to Z or C. Replacing Z with Ground Wave frees Sweep for another slot; clicking another slot moves the skill, or swaps it with that slot’s current skill, so the same skill never occupies two slots.
8. The prototype now goes to **level 100**. Thief advancements with Elowen: **Thief 10 → Assassin 30 → Hermit 60 → Night Lord 100**. Basic attacks throw **1 → 2 → 3 → 4 stars** respectively. Hermit automatically learns **Shadow Partner on C**: a shadow follows behind you for **60 seconds** and mirrors every star you throw, giving **6 basic stars at third job** and **8 at fourth job**. Shadow Fan is mirrored too. Menus pause the timer; death, character switching and restarting end the summon. Warrior third/fourth jobs and Hyper skills remain future content.

9. Around **level 15**, continue to the far-right portal in Whisperwood to enter **Briar Hollow**. Thornlings and briar lanterns are tougher and drop better equipment. **Rootwarden**, the first miniboss, guards the far end; level 25+ and upgraded gear are recommended. Jump over the marked ground slam and dodge the seed volley. Victory grants a class-appropriate weapon, potions, coins and XP. The boss returns after 45 seconds. The left portal returns to the far end of Whisperwood.

Death sends you back to town at full health with collected loot and progression kept. No XP penalty. Town regenerates health and monsters stay in the forest. Enemy warning markers give you time to jump away. Damage numbers stack, pop and float upward: orange/yellow means a normal hit, deep red means a critical hit, and purple negative numbers show HP lost to enemy hits. Monster names show their level. Contact, melee attacks, lantern shots and boss attacks all damage you; armor reduces each hit to a minimum of 1, with 0.8 seconds of invulnerability after a hit. Enemy attack = type base attack + 2 × (enemy level − 1), then the attack modifier applies (contact 60%, regular melee/projectile 100%, boss slam 140%, boss seeds 75%) before armor. Levels are fixed by type: Mossling 3, Lantern Bloom 6, Thornling 18, Briar Lantern 22 and Rootwarden 25. Starter enemies stay weak as your character grows. Detailed Stats shows the current damage calculation and a preview including pending points.

## Saves

Progress and controls save in this browser's local project data. They are not synchronized with GitHub. **Menu → Save** provides explicit save and JSON backup export/import. Keep a JSON backup before clearing browser site data or switching devices. Import backups into the matching Warrior or Thief slot; cross-class imports are rejected to protect the other character. Older Warrior and Thief backups remain compatible. Missing menu shortcuts are added on import; if an old custom gameplay key uses I/M/K/S, it is preserved and that menu receives a free shortcut. Twin Stars is removed; invested Twin Stars points are refunded once and its old hotbar slot is cleared. Corrupt saves are rejected and backed up when possible.

## Current scope

One town, two hunting maps, four regular monster variants, the Rootwarden miniboss, a sword Warrior/Spearman route, four Thief advancements with growing basic volleys and a timed Shadow Partner, separate character slots, eight-frame walking cycles, heavy Warrior second-job mob attacks, bulk stat allocation, a ranked skill tree, equipment, loot, double jump, key configuration, and saves. Additional second/fourth-job Thief skills, third/fourth Warrior jobs, Hyper gameplay, quests, multiplayer, and final production art remain future content. Art uses original chibi sprites, bold outlines, mushroom cottages, chunky grass terrain and layered backgrounds inspired by classic side-scrolling RPGs.

## Development checks

From the project root:

```
godot --headless --editor --import --quit
godot --headless --script res://tests/runner.gd
```

The runner prints positive check counts and exits nonzero for failing assertions. Engine script errors must also be treated as failures even when Godot returns zero. Native checks and visual capture do not alone establish Web Editor compatibility.
