# Windswept

An original, single-player 2D side-scrolling RPG for **Godot Web Editor 4.7.2**, built on the classic job-tree formula: four classes, ten advancement paths, level 200, hunting grounds and bosses. Uses the Compatibility renderer and no external assets or plugins. All class, job, skill, monster and boss names are original.

## Play in the browser

Once GitHub Pages is switched on for this repository (Settings → Pages → Deploy from a branch → `main`, folder `/docs`), the game runs at **https://iallmost-code.github.io/Godot-game/**, with no editor needed. Saves stay in that browser. Rebuild the web version after changes with `python3 tools/export_web.py /path/to/godot`.

## Import the playable project

Choose **Side-Scroller-Warrior.zip** in the Web Editor landing page's **Preload project ZIP**, then start the editor. In the Install Project dialog, click **Install** with **Edit Now** checked. Once the project opens, click **Run Project**. Click inside the running game so it receives keyboard input. Use the editor's Run button if your browser captures function keys.

Use this standalone project ZIP, not GitHub's repository-wide Code → Download ZIP: that archive also contains the previous 3D prototype.

## Main menu and character selection

The game starts at a title screen. **Continue** resumes your last saved character; **Character Select** shows Warrior, Mage, Archer and Thief as four independent slots, with saved levels, jobs and equipment previews. Pick an empty slot to start that class, or an existing one to continue it. Arrow keys select a class and Enter plays it.

The title also has **Settings**, **How to Play** and **Quit / Exit**. In game, press Escape and click **Main menu** in a window header to save and return. The world stays paused while the title or character screen is open. In the web version, Exit explains how to close the tab after saving.

## Default controls

| Action | Key |
| --- | --- |
| Move | Left / Right arrows |
| Interact with portal or NPC; climb a rope or ladder | Up arrow |
| Climb down a rope or ladder | Down arrow |
| Jump; press again in air for a boosted double jump | Shift |
| Drop through a platform; release a rope downward | Hold Down + press Shift |
| Central hub with gates to all 32 towns | H |
| Teleport to nearest connected town | T |
| Basic attack (sword/spear/dagger/staff swing, star or arrow; hold to repeat) | Space |
| Skills | Any key you choose (Menu → Keys, or **Set key** in the Skill Book) |
| HP / MP potion | 1 / 2 |
| Inventory / Map / Skills / Stats / Quests | I / M / K / S / Q |
| Character Journey / Boss Journal | J / B |
| Menu / close window | Escape or top-right buttons |

**Key config (Menu → Keys):** a keyboard where any key can hold a skill or an action, like the classic key config. Pick an action or skill from the lists, then click a key. Click a key first to pick up what is on it and move it, and right-click a key to clear it. Put as many skills on keys as you like; the hotbar shows the first nine in keyboard order. Holding an attack skill's key keeps using it. Skills on keys are saved per character; action keys are shared. Left, Right, Down, Up, Jump, Attack and Menu always need a key but can move; potions, menus and travel can be cleared to free their keys. In the Skill Book, **Set key** next to a skill waits for the next key you press (Backspace removes it).

 Open menus pause the game. Windows stay open independently: drag their title bars, press their shortcut to toggle one, or press Escape to close the front window.

## Where to go

Press **M** for the **Level guide**. It highlights your next hunting area and offers a free **Travel** button. **All towns** lists every town; **Area atlas** shows each region, its local platforms and portal routes. Boss travel stops at the gate town so you enter the lair through its portal.

Press **H** or click **Portal hub** to visit **Wayfarer's Concourse**. Its two decks hold physical portals to every town; stand beside one and press **Up**. Every town also has a return gate at its far end. Press **T** or click **Nearest town** to leave a hunting area safely. Teleporting preserves your equipment, money and XP.

| Level | Hunting ground | Town |
| --- | --- | --- |
| 1–11 | Dewdrop Meadow | Farmeadow |
| 12–24 | Mossvale Thicket | Starbough |
| 25–44 | Rotfen Marsh | Hollowroot |
| 45–59 | Emberpeak Canyon | Ironridge |
| 60–79 | Frostspire Peaks | Frostmere |
| 80–99 | Clockwork Spire | Tickletop |
| 100–109 | Bonepit Mine | Frostmere |
| 110–124 | Tidegrave Trench | Tideglass |
| 125–154 | Skyreach Cliffs | Wyrmrest |
| 155–200 | Timeless Sanctum | Hourglass |

Monster XP now follows the actual spawned level: `24 + 6 × level + 0.28 × level²` (rounded down). Ordinary level 10 / 30 / 70 enemies give 112 / 456 / 1,816 XP before bonuses. Bosses give 30 times the normal level reward; Rootwarden gives 10 times. Equipment and potion drops also follow monster level. The EXP bar shows current progress and the latest kill reward. Town quest XP rewards follow the same improved curve.

Stars, arrows and magic bolts steer toward visible enemies ahead within their remaining range. Solid walls block targeting and projectiles; piercing shots skip targets already hit.

## Classes and jobs

Pick a class in **Menu → Characters**. Each class has its own save slot. Advance by standing beside **Captain Elowen** in Willowbridge and pressing **Up**. At the second job you choose a path, and that choice is permanent.

| Class | 1st job | 2nd job (Lv 30) | 3rd job (Lv 70) | 4th job (Lv 120) |
| --- | --- | --- | --- | --- |
| Warrior | Squire (Lv 10) | Duelist | Warlord | Champion |
| | | Shieldbearer | Runeknight | Templar |
| | | Lancer | Wyrm Knight | Dread Knight |
| Mage | Initiate (Lv 8) | Ember Adept (fire/poison) | Cinder Magus | Inferno Archon |
| | | Frost Adept (ice/lightning) | Storm Magus | Tempest Archon |
| | | Acolyte (holy/healing) | Oracle | Hierarch |
| Archer | Scout (Lv 10) | Tracker (bow) | Falconer | Windmaster |
| | | Arbalist (crossbow) | Deadeye | Sharpshooter |
| Thief | Prowler (Lv 10) | Stalker (claw) | Shadeweaver | Nightblade |
| | | Brigand (dagger) | Cutthroat | Duskreaper |

Each advancement grants 1 skill point and a job weapon; every level after that grants 3 skill points for your current job. Novices earn up to 9 points for Shell Toss, Second Wind and Quickstep. Every level grants 5 attribute points. Main stats: Warrior **STR**, Mage **INT**, Archer **DEX**, Thief **LUK**.

There are 242 skills: attacks (melee, projectiles, area blasts, spells that fall from the sky, chain lightning, charges), buffs, passives, summons (Light Drake, Silverwing, Firebird, Dread Eye, Scarecrow decoys…), heals, Blink, Wayshrine (return to town), Shadow Twin, Momentum combo orbs and elemental Brands. Open **Skills (K)** to spend points (+1 or +5), read each skill's numbers and assign attacks and buffs to any hotkey. Later jobs show a preview of each path you could pick.

## World, hunting grounds and bosses

The world has 32 safe towns, each with a regional hunting route, plus ten deeper hunting grounds and twelve boss lairs; see [WORLD_GUIDE.md](WORLD_GUIDE.md) for every town and route. Travel on foot: stand at a named portal and press **Up**. **Map (M)** shows every region, its areas and the walking route from where you are. Towns heal you and become your respawn point.

Job instructors: **Captain Elowen** (Willowbridge) advances every class. **Warden Bram** (Ironridge) advances Warriors, **Arcanist Ilyra** (Starbough) advances Mages, **Mara Vex** (Shadecross) advances Thieves and **Ranger Vale** (Thornscar Lodge) advances Archers.

Regional routes use themed monsters at the route's level. The deeper grounds and boss lairs are gates in these towns:

| Gate in town | Deeper hunting ground (levels) | Boss lair (level) |
| --- | --- | --- |
| Farmeadow | Dewdrop Meadow (1-12) | — |
| Sunpetal Cove | — | Grand Shellmaw (20) |
| Starbough | Mossvale Thicket (12-25) | — |
| Ironridge | Emberpeak Canyon (45-70) | Elder Stumpus (35) |
| Shadecross | — | Gelatinous Monarch (40) |
| Moonpetal Shrine | — | Mother Cap (60) |
| Hollowroot | Rotfen Marsh (25-45) | Blight Mother Cap (65), Lesser Hellwing (80) |
| Thornscar Lodge | — | Crimson Hellwing (115) |
| Frostmere | Frostspire Peaks (60-85), Bonepit Mine (100-125) | Molten Colossus (140) |
| Tickletop | Clockwork Spire (80-110) | Chronovore (125) |
| Tideglass | Tidegrave Depths (110-135) | Abyssal Leviathan (130) |
| Wyrmrest | Skyreach Plateau (125-160) | Thornscale Wyrm (170) |
| Hourglass Sanctum | Timeless Sanctum (155-200) | Gloam Idol (190) |

Monsters walk, hop, charge, cast, fly or tank. Bosses cycle through telegraphed patterns: **SLAM** and **LOW SWEEP** (jump over them), volleys, rain from above (move out of the red circles), summoned minions and charges. At half health they enrage and attack faster. Bosses resist stuns and freezes but not poison, armor breaks or weakening. Bosses always drop a weapon for your class; regular monsters drop coins, potions and level-banded gear.

Status effects shown as coloured dots over monsters: stun, freeze, poison (never kills), slow, silence, wither (harmless), weaken, armor break, snare, blind and mock (more damage and experience). You can dodge (**MISS**), block (**BLOCK**) and revive with Rebirth (**REBIRTH**).

Death returns you to town at full health with all progress kept.

### Endgame: raids, hard mode and field bosses

- **Raids** have a RAID gate in their town and are fought in phases. Each phase's parts must all fall before the next one appears.
  - **Ember Tyrant** (Lv 120, Frostmere): four arms, then the body.
  - **Stormcrown Hydra** (Lv 160, Wyrmrest): Frost and Storm heads, then the Hydra.
  - **Dreaming Seraph** (Lv 190, Hourglass Sanctum): three guardians, then the Seraph, then Seraph Awakened.
- **Raid chest:** pays out once a week per character. It holds a raid weapon for your class (Tyrant's / Stormcrown / Seraphic), a raid piece (Eye of the Tyrant earring, Stormcrown Cloak, Seraphic Halo), Shards, coins, scrolls and a Chaos Scroll. Repeat clears in the same week give coins.
- **Hard mode:** every lair has a second "Hard" gate. The boss is 40 levels higher (up to 200), has more health and one extra attack pattern, and drops five scrolls plus extra Shards.
- **Field bosses:** a named giant shows up on every hunting map 20–45 seconds after you arrive, with an announcement and a health bar. Examples are Old Shellback in Dewdrop Meadow, Grumblebark, Bogmaw, Cindermaw, Whitefang Alpha, Overclocked Sentinel, Marrow Captain, Coralback Ancient, Stormhoof Khan and The Last Warden; regional routes get a "Chief" version of their monster. It drops a weapon, an armor piece, Shards, coins and two scrolls, then returns about 10 minutes after it falls.

Leveling past 100 slows down gradually: each level needs about 3× more experience at 150 and about 5× near 200.

### Ropes, ladders and the minimap

Hunting maps have upper ledges. Stand at the foot of a rope or ladder and hold **Up** to climb, or stand at the top and hold **Down** to climb down. Hold **Up** while jumping into a rope to grab it, and press **Shift** with **Left** or **Right** to jump off. Getting hit knocks you off. Monsters on ledges stay on their ledge. The camera follows you up. The minimap in the top-left corner shows ledges, ropes, portals, NPCs (yellow: quest givers), the boss and you.

## Quests

Every town has a quest giver with a chain of four written quests (128 in all): hunts and collection quests along that town's route. A yellow **!** over an NPC means a new quest, a grey one means you are not high enough yet, **…** means it is in progress and **?** means you can hand it in. Stand next to the NPC and press **Up** to talk. Collection quests make the right monster drop quest items while the quest is active. Rewards are XP, coins, potions, upgrade scrolls and a helm. **Quests (Q)** lists what you are doing and what is available. Quest text can be replaced by writing `data/quests.json` (format in `systems/quests.gd`).

## Gear, shops and the Forge

You wear seven pieces: **weapon, hat, armor, gloves, shoes, cape and earring**. Each piece has a level requirement and its own stats (attack, defense, HP, MP or all stats). Monsters drop gear for every slot, potions matched to their level and Shards. Your bag holds 128 items, and duplicate copies are kept.

Every town has a **Merchant** beside its instructor. Stand next to the Merchant and press **Up**, or open the **Shop** tab while you are in a town:

- **Buy Potions:** Red/Orange/White Tonic and Golden Elixir (HP), Blue Tonic, Mana Draught and Mana Elixir (MP), and Phoenix Elixir (full HP and MP). Stronger potions are sold in higher-level towns. Use them with **1** (HP) and **2** (MP); each button picks the smallest potion that fills the gap.
- **Buy Gear:** weapons for your job's weapon type plus armor pieces for the town's level.
- **Sell / Dismantle:** sell unworn gear for coins, or break it into **Shards**. "Sell all worse gear" and "Dismantle all worse gear" clear out everything weaker than what you wear, plus other classes' weapons.
- **Forge:** spend Shards and coins to enhance gear from +1 to +10. Weapons gain attack; armor pieces gain defense and HP. The chance drops from 100% at +1 to 35% at +10. A failure keeps the item's level and only uses the materials.

Dismantling works anywhere from the Inventory; selling needs a Merchant.

### Scrolls

Monsters sometimes drop upgrade scrolls; bosses drop two and quests give them too. Each piece of gear has upgrade slots (7 for weapons, helms and armor; 5 for gloves, boots, cloaks and earrings). Select an item in the Inventory and use a scroll on it:

- **100% / 60% / 10%** scrolls for each gear slot: the lower the chance, the bigger the gain (weapon scrolls give +1 / +3 / +5 ATK). Pass or fail, the scroll uses one slot.
- **Chaos Scroll 60%:** every stat on the item shifts by -5 to +5.
- **Clean Slate Scroll 10%:** restores a slot lost to a failed scroll.

Scrolls never destroy gear. Scrolls and the Forge stack.

### Pets and looks

Merchants also sell pets (**Pets** tab): Brown Pup, Ginger Kitten, Snow Bunny, Tuxedo Penguin, Pet Jellop and Baby Drake. Your pet follows you between maps and fetches coins, potions, gear, scrolls and quest items that drop nearby. Switch pets in **Characters**. That panel also sets hair (8 styles), hair colour, face and skin tone, with a live preview. **Classic** keeps your class's original painted head.

Your save remembers the last town you visited and starts you there.

## Saves

Progress and controls save in this browser's local project data. **Menu → Save** offers explicit saves and JSON backup export/import into the matching class slot. Saves from the earlier two-class version load automatically: jobs above the new thresholds step back (for example a level-65 Hermit becomes a Stalker until level 70), retired skills are removed, and **every skill point is refunded** once.

## Adding towns, art and content

- **Towns and starting areas:** add a fixed entry in `data/maps.gd` (`definition()`), with platforms, spawns, portals and optional enemies. Captain Elowen (job advancement) is placed by `world/map_controller.gd` in the `town` map.
- **Hunting grounds and bosses:** one row in `REGIONS` in `data/maps.gd`. Monster stats are in `data/enemy_stats.gd` (`ROSTER` and `BOSSES`).
- **Monster art:** sixteen common body families use the painted `art/monster_atlas.png`, with regions in `visuals/monster_layout.gd` and palette/idle motion in `visuals/mob_art.gd`. Bosses and special variants retain their individual vector features; Mossling, Lantern Bloom and Rootwarden retain their existing sprite art.
- **Player art:** four dedicated unarmed body sheets (`art/*_body.png`), frame/foot/hand anchors in `visuals/body_layout.gd`, and separate equipment in `art/weapons_atlas.png` / `visuals/weapon_layout.gd`. All seven weapon types have normal and upgraded art shared with inventory icons. Attacks follow the real combat clock through windup, strike, follow-through and recovery.
- **Combat effects:** `art/combat_atlas.png` / `visuals/attack_art.gd` contain slash, thrust, wave, impact and elemental art. Projectiles have fading trails; spell and melee effects wait for their combat windup.
- **Skills:** every skill is one entry in `data/catalog.gd`; display names are in `RENAMES` and `FAMILY_NAMES`. Icons come from `art/skill_icons.png` / `visuals/skill_icon_layout.gd`.
- **Ropes and ledges:** `add_tiers()` in `data/maps.gd` adds ledges, climbs (`[x, top, bottom, "rope"|"ladder"]`) and ledge monsters to every hunting map. Painted rope and ladder pieces are used when `art/climb_atlas.png` and `visuals/climb_layout.gd` exist.
- **Scrolls, pets, looks and quest items:** `data/adventure.gd`. Quests: `systems/quests.gd` reads `data/quests.json` (128 written quests). Art: `visuals/looks_layout.gd` + `custom_body_layout.gd` (hair-free bodies with skin masks), `pet_layout.gd`, `npc_layout.gd`, `ui_icon_layout.gd`, `levelup_layout.gd` and the `CLIMB` frames in `body_layout.gd`.

## Development checks

From the project root:

```
godot --headless --editor --import --quit
godot --headless --script res://tests/runner.gd
```

The runner prints positive check counts and exits nonzero for failing assertions. It casts every skill of every fourth-job path and visits every hunting ground and boss arena. Engine script errors must also be treated as failures even when Godot returns zero. Native checks and visual capture do not alone establish Web Editor compatibility.

## Combat, equipment and world polish

**J — Character Journey** shows your current job, all completed advancements, upcoming paths and skill unlocks. It links directly to Captain Elowen, your next hunting ground and the skill book. **B — Boss Journal** lists all 13 bosses with painted portraits, recommended levels, named rewards, tactics and travel to their gate town.

Bosses enter a second phase at 60% HP and a final phase at 35%. Later phases add projectiles, widen slams and reduce recovery time, while preserving readable wind-ups of at least 0.65 seconds. Ground attacks and charges mark their danger lanes. The boss health bar shows the phase.

Monster equipment can be **Common, Uncommon, Rare or Epic**, with better odds at higher levels. Rarity bonuses add attack, defense or attributes independently of scroll upgrades. Each boss guarantees a named epic class weapon with its own trophy title. Rare and epic drops have colored ground beams; inventory borders and tooltips identify their quality. Hats, armor, capes, boots and weapon quality appear on your character; Shadow Twin mirrors your gear and looks.

In Inventory, sort by level, rarity or slot, double-click to equip, and **Lock item** to protect a favorite. Locked gear cannot be sold or dismantled. Bulk cleanup preserves locked, rare and epic equipment, plus any item that improves a stat over your worn gear. The comparison lists attack, defense and attribute changes. Existing items and saves remain compatible; old gear defaults to Common.

The world now includes nine original looping music pieces, three ambient beds, twelve synthesized effects and regional particles. Projectiles, hits, criticals, loot and level-ups have distinct sounds. **Menu → Controls** has music and effects sliders and a camera-shake toggle; these preferences save locally. A zero slider value mutes its channel. Click inside the game to enable browser audio.

Audio is composed by `tools/generate_windswept_audio.py`, with no external samples or borrowed melodies. The script requires Python 3 and ffmpeg to regenerate the shipped WAV and Ogg assets.
