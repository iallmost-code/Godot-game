# Windswept — Spearbound

An original, single-player 2D side-scrolling RPG prototype for **Godot Web Editor 4.7.2**. Uses the Compatibility renderer, original shaded sprite artwork and painted scenery, and no external assets or plugins.

## Import the playable project

Choose **Side-Scroller-Warrior.zip** in the Web Editor landing page's **Preload project ZIP**, then start the editor. In the Install Project dialog, click **Install** with **Edit Now** checked. Once the project opens, click **Run Project**. Click inside the running game so it receives keyboard input. Use the editor's Run button if your browser captures function keys.

Use this standalone project ZIP, not GitHub's repository-wide Code → Download ZIP: that archive also contains the previous 3D prototype.

## Default controls

| Action | Key |
| --- | --- |
| Move | Left / Right arrows |
| Interact with portal or instructor | Up arrow |
| Jump; press again in air for boosted double jump | Shift |
| Basic spear combo (hold to continue attacking) | Space |
| Assigned skills | Z / X / C |
| Menus | Escape or top-right buttons |

Rebind controls through **Menu → Controls**. Escape cancels a pending key capture. Each action needs a unique key; restore defaults is available. Open menus pause the game.

## Your first journey

1. Begin as a level-1 Beginner in **Willowbridge**. Space and double jump are available immediately. **Z/X/C start unassigned**; they are not broken.
2. Go right to the glowing arch. Press Up nearby to enter the **Whisperwood**.
3. Defeat mosslings and lantern blooms for XP. Walk over drops to collect coins, potions, and equipment. Potion button heals you; mana regenerates over time.
4. Spend attribute points in Stats (STR, DEX, INT, LUK). Compare and equip drops in Inventory.
5. At **level 10**, return to town and speak to **Captain Elowen**, the spear-bearing instructor near the first house. Confirm Warrior advancement. **Z: Crescent Sweep** and **X: Driving Thrust** now unlock automatically.
6. Use the Skills window to rank up first-job skills and passives. Thrust pushes monsters back; double jump is your mobility move.
7. At **level 30**, return to Elowen to advance to Spearman. Learn **Spear Mastery**, then earn more second-job skill points by leveling and learn **Ground Wave**. Assign it to Z or C. Replacing Z with Ground Wave frees Sweep for another slot; clicking another slot moves the skill, or swaps it with that slot’s current skill, so the same skill never occupies two slots.
8. The prototype goes to **level 40**, allowing second-job skill builds. Dragon Knight (60), Dark Knight (100), and Hyper (140+) are **future content**, shown as locked tabs.

Death sends you back to town at full health with collected loot and progression kept. No XP penalty. Town regenerates health and monsters stay in the forest. Enemy warning markers give you time to jump away.

## Saves

Progress and controls save in this browser's local project data. They are not synchronized with GitHub. **Menu → Save** provides explicit save and JSON backup export/import. Keep a JSON backup before clearing browser site data or switching devices. Corrupt saves are rejected and backed up when possible.

## Current scope

One town, one multi-platform forest, two monster types, a warrior/spearman job path, heavy second-job mob attacks, stats, a ranked skill tree, equipment, loot, double jump, key configuration, and saves. Third/fourth jobs, Hyper gameplay, sword/thief branches, quests, bosses, multiplayer, and production art are not implemented yet. Art now uses original shaded character/monster sprites, painted scenery, textured terrain, and illustrated skill effects. It is not extracted MapleStory artwork.

## Development checks

From the project root:

```
godot --headless --editor --import --quit
godot --headless --script res://tests/runner.gd
```

The runner prints positive check counts and exits nonzero for failing assertions. Engine script errors must also be treated as failures even when Godot returns zero. Native checks and visual capture do not alone establish Web Editor compatibility.
