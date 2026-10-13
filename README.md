# Crypt Sovereign — playable prototype

Godot 4.7.2, GDScript, Compatibility renderer. Original generated artwork; no downloads or plugins needed.

## Try it in the Godot Web Editor

1. On the editor landing page, choose the supplied ZIP under **Preload project ZIP**.
2. Click **Start Godot Editor** and open the imported Crypt Sovereign project.
3. Wait for import, then press the editor's **Run Project** button (F6 runs a scene; F5 runs the project). Use the button if the browser captures function keys.
4. Click inside the game window to focus keyboard input.

If the editor is already open, use its project ZIP import flow or return to the landing page after saving your existing project. The ZIP has project.godot at its root.

## Controls

- Left-click the floor to move; walk onto glowing gold or violet loot to collect it.
- **1:** Bone Bolt, aimed at the enemy nearest your cursor.
- **2:** Raise Skeleton from a green corpse, up to three.
- **3:** Corpse Explosion, aimed at a green corpse.
- **4:** Golem Slam, targeted at the floor under the cursor.
- **5:** Soul Siphon, aimed at an enemy; restores health.
- **6:** Undead Frenzy, temporarily speeds up minion attacks.
- **R:** Reset the dungeon and keep collected loot.

Skeletons and the golem fight automatically. The golem returns ten seconds after dying. Dead enemies leave green corpses for thirty seconds. Violet elite loot unlocks Bone Plating for your golem. The larger enemy at the far end is the boss; dodge its marked slam with click-to-move.

## Prototype limits

This is a combat sandbox in one open crypt, not the complete design. Relics automatically increase damage; there is no inventory/equipment screen, navigation maze, projectile travel, or save import/export yet. Generated box-and-sphere characters are placeholder art. Loot survives death and is saved locally when supported. Browser site data is not synchronized with GitHub and clearing it can erase saves. Native/headless checks do not establish browser rendering or storage compatibility; please report any Web Editor errors.
