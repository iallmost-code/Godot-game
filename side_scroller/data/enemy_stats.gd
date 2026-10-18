extends RefCounted
# Monster roster. Levels follow a classic hunting-ground progression from 1 to 200.
# body = art template (visuals/mob_art.gd); behavior = walker, hopper, charger, caster, flyer, tank.
# Legacy sprite monsters keep their hand-made art.
const LEGACY={
    "mossling":{"name":"Mossling","level":3,"base_attack":4,"hp":40,"xp":40,"sprite":true,"behavior":"walker","speed":42},
    "lantern":{"name":"Lantern Bloom","level":6,"base_attack":5,"hp":32,"xp":60,"sprite":true,"behavior":"caster","speed":22},
    "thornling":{"name":"Thornling","level":18,"base_attack":8,"hp":160,"xp":110,"sprite":true,"behavior":"walker","speed":48},
    "briar_lantern":{"name":"Briar Lantern","level":22,"base_attack":9,"hp":100,"xp":140,"sprite":true,"behavior":"caster","speed":22},
    "rootwarden":{"name":"Rootwarden","level":25,"base_attack":10,"hp":2600,"xp":900,"sprite":true,"boss":true}
}
# id: [name, level, body, behavior, main color, accent color, size, extras]
const ROSTER={
    # Dewdrop Meadow
    "pebble_snail":["Pebble Snail",1,"snail","walker","7dbf62","e9d3a3",0.85,{"speed":18}],
    "azure_snail":["Azure Snail",2,"snail","walker","5f9ee0","e9d3a3",0.9,{"speed":20}],
    "ember_snail":["Ember Snail",4,"snail","walker","e0644a","f2d6a0",0.95,{"speed":22}],
    "puffspore":["Puffspore",2,"mushroom","hopper","c7a0db","f4e7d0",0.75,{}],
    "stumpkin":["Stumpkin",5,"stump","walker","8a6440","6fb455",0.95,{"speed":26}],
    "jellop":["Jellop",6,"slime","hopper","62d0b6","ffffff",0.9,{}],
    "tangerine_cap":["Tangerine Cap",8,"mushroom","hopper","f08a3c","f6e6c8",1.0,{}],
    "bristle_hog":["Bristle Hog",9,"boar","walker","f0a6b4","b86b7a",1.0,{"speed":46}],
    # Mossvale Thicket
    "gloom_stump":["Gloom Stump",12,"stump","walker","5c4a3c","4f7a45",1.0,{"speed":28}],
    "inkling":["Inkling",13,"octopus","caster","d8698e","ffe0ea",0.95,{"element":"poison"}],
    "mossy_cap":["Mossy Cap",14,"mushroom","hopper","6fb956","f2ead2",1.0,{}],
    "hatchet_stump":["Hatchet Stump",17,"stump","tank","6e5038","9aa3ab",1.15,{"speed":24,"weapon":"axe"}],
    "horned_cap":["Horned Cap",21,"mushroom","charger","5a86d6","eae3d0",1.05,{"horns":true}],
    "tusker_boar":["Tusker Boar",24,"boar","charger","8b5a3c","f3ead6",1.15,{"tusks":true}],
    # Rotfen Marsh
    "rotcap":["Rotcap",26,"mushroom","walker","8a9a7a","c9c2a8",1.05,{"rot":true,"speed":30}],
    "wisp_wraith":["Wisp Wraith",28,"wraith","flyer","b8c6e0","6a7fb0",0.95,{}],
    "cinder_boar":["Cinder Boar",33,"boar","charger","6b3b32","ff8a4c",1.2,{"tusks":true,"flame":true}],
    "shade_wraith":["Shade Wraith",34,"wraith","flyer","6d5f8f","c7a3ff",1.05,{"ranged":true,"element":"arcane"}],
    "swamp_gator":["Swamp Gator",36,"gator","walker","5f8a4a","e8dfa2",1.2,{"speed":40}],
    "canopy_ape":["Canopy Ape",38,"ape","caster","7a5a3c","e8c79a",1.1,{"element":"fruit"}],
    "rubble_golem":["Rubble Golem",42,"golem","tank","9a958c","6d6a64",1.35,{}],
    # Emberpeak Canyon
    "azure_drake":["Azure Drake",46,"drake","walker","5a8fd6","e0e8f2",1.25,{"speed":44}],
    "dune_lizard":["Dune Lizard",48,"gator","charger","c8a35e","8a6a3a",1.15,{}],
    "obsidian_golem":["Obsidian Golem",50,"golem","tank","3d3946","c06be0",1.45,{}],
    "crimson_drake":["Crimson Drake",54,"drake","caster","d24f4a","f7d0a0",1.3,{"element":"fire"}],
    "frost_drake":["Frost Drake",60,"drake","caster","8fd6ff","ffffff",1.3,{"element":"ice"}],
    # Frostspire Peaks
    "frost_cub":["Frost Cub",58,"yeti","walker","e8f0f8","8fb6d9",1.0,{"speed":40}],
    "rime_wolf":["Rime Wolf",64,"wolf","charger","c9d6e3","6d8aa6",1.15,{}],
    "snowhorn":["Snowhorn",68,"yeti","tank","dfe8f2","7b8fa6",1.45,{"horns":true}],
    "moonfang":["Moonfang Lycan",76,"wolf","charger","6a6f88","f2d27a",1.3,{"upright":true}],
    # Clockwork Spire
    "tick_sentinel":["Tick Sentinel",82,"toy","walker","e2b04a","5a4a8a",1.0,{"speed":38}],
    "stitched_bruin":["Stitched Bruin",86,"teddy","walker","b98a5e","f2d8b8",1.1,{"speed":40}],
    "grim_clockwork":["Grim Clockwork",94,"toy","tank","5a5f74","d24f4a",1.4,{}],
    "phantom_timepiece":["Phantom Timepiece",102,"clock","flyer","9a8ad8","f2ecff",1.05,{"ranged":true,"element":"arcane"}],
    "dread_bruin":["Dread Bruin",106,"teddy","charger","5e4a6a","d24f4a",1.3,{}],
    # Bonepit Mine
    "bonewalker":["Bonewalker",104,"skeleton","walker","e8e0c8","7a6a50",1.05,{"speed":44}],
    "bone_archer":["Bone Archer",108,"skeleton","caster","e8e0c8","5a7a9a",1.05,{"element":"bone","bow":true}],
    "bone_captain":["Bone Captain",114,"skeleton","tank","f2ead2","b23c3c",1.35,{"helmet":true}],
    "magma_golem":["Magma Golem",118,"golem","tank","4a2e28","ff8a4c",1.5,{"flame":true}],
    # Tidegrave Depths
    "reef_snapper":["Reef Snapper",112,"crab","walker","e06a4a","f7d6b0",1.1,{"speed":46}],
    "gloomfin":["Gloomfin",116,"fish","flyer","4a7aa6","c8f0ff",1.1,{}],
    "tide_inkling":["Tide Inkling",120,"octopus","caster","6a5ab8","d8e8ff",1.2,{"element":"ice"}],
    "coral_golem":["Coral Golem",126,"golem","tank","e08a9a","f7e6c8",1.5,{}],
    # Skyreach Plateau
    "storm_centaur":["Storm Centaur",128,"centaur","caster","5a7ad6","f6ef7a",1.3,{"element":"lightning"}],
    "twinhead_birk":["Twinhead Birk",132,"bird","flyer","8a6a4a","f2d27a",1.2,{"twin":true}],
    "cinder_centaur":["Cinder Centaur",138,"centaur","caster","b84a3a","ffb35c",1.3,{"element":"fire"}],
    "bone_wyvern":["Bone Wyvern",145,"drake","flyer","e8e0c8","5a4a6a",1.4,{"wings":true}],
    "skyscale_wyvern":["Skyscale Wyvern",150,"drake","flyer","5ab8a6","f2f7ff",1.45,{"wings":true,"ranged":true,"element":"lightning"}],
    # Timeless Sanctum
    "memory_warden":["Memory Warden",158,"monk","walker","c8b07a","5a6ab8",1.15,{"speed":46}],
    "oblivion_monk":["Oblivion Monk",168,"monk","caster","5a4a7a","c7a3ff",1.15,{"element":"arcane"}],
    "chrono_guardian":["Chrono Guardian",180,"golem","tank","c8c0a8","5ab8d6",1.6,{"statue":true}],
    "gloam_sentinel":["Gloam Sentinel",190,"wraith","flyer","3a3050","ff9ad6",1.25,{"ranged":true,"element":"arcane"}],
}
# Bosses: [name, level, body, main, accent, size, hp multiplier, patterns, minion]
const BOSSES={
    "grand_shellmaw":["Grand Shellmaw",20,"snail","c46a3a","f2d6a0",3.0,40,["slam","summon","charge"],"pebble_snail"],
    "elder_stumpus":["Elder Stumpus",35,"stump","4a3828","5a9a45",3.2,45,["slam","rain","summon"],"gloom_stump"],
    "gelatinous_monarch":["Gelatinous Monarch",40,"slime","4fb8e0","f2c94c",3.4,50,["slam","summon","volley"],"jellop"],
    "mother_cap":["Mother Cap",60,"mushroom","f08a3c","f6e6c8",3.6,55,["slam","volley","summon"],"tangerine_cap"],
    "blight_mother":["Blight Mother Cap",65,"mushroom","7a8a6a","c9c2a8",3.6,60,["slam","rain","summon","volley"],"rotcap"],
    "lesser_hellwing":["Lesser Hellwing",80,"bat","3a2a3a","d24f4a",3.0,60,["rain","charge","volley"],""],
    "crimson_hellwing":["Crimson Hellwing",115,"bat","8a1f2a","ffb35c",3.6,70,["rain","charge","volley","beam"],""],
    "chronovore":["Chronovore",125,"clock","6a5ab8","f2ecff",3.6,75,["beam","rain","summon","slam"],"tick_sentinel"],
    "abyssal_leviathan":["Abyssal Leviathan",130,"fish","2a4a7a","8fd6ff",3.4,80,["charge","volley","beam"],"gloomfin"],
    "molten_colossus":["Molten Colossus",140,"colossus","4a3a32","ff8a4c",2.6,90,["slam","rain","beam","summon"],"magma_golem"],
    "thornscale_wyrm":["Thornscale Wyrm",170,"wyrm","3a5a4a","d24f4a",3.4,110,["beam","rain","slam","volley","summon"],"bone_wyvern"],
    "gloam_idol":["Gloam Idol",190,"idol","3a2f5c","ff9ad6",3.0,130,["beam","rain","slam","volley","summon","charge"],"gloam_sentinel"],
}
# Raid bosses come in parts fought in phases (see data/raids.gd). Same layout as
# BOSSES plus the painted boss whose art they borrow, its scale and a tint.
const RAID_PARTS={
    "tyrant_arm_left":["Tyrant's Left Arm",120,"colossus","5a2a1a","ff7a3c",2.0,30,["slam","rain"],"","molten_colossus",0.55,Color(1.25,0.75,0.55)],
    "tyrant_arm_right":["Tyrant's Right Arm",120,"colossus","5a2a1a","ff7a3c",2.0,30,["volley","slam"],"","molten_colossus",0.55,Color(1.25,0.75,0.55)],
    "tyrant_arm_low_left":["Tyrant's Lower Arm",120,"colossus","5a2a1a","ff7a3c",2.0,30,["beam","slam"],"","molten_colossus",0.5,Color(1.15,0.7,0.5)],
    "tyrant_arm_low_right":["Tyrant's Lower Arm",120,"colossus","5a2a1a","ff7a3c",2.0,30,["charge","rain"],"","molten_colossus",0.5,Color(1.15,0.7,0.5)],
    "ember_tyrant":["Ember Tyrant",125,"colossus","4a1a10","ffb35c",3.2,95,["slam","rain","beam","volley","summon"],"magma_golem","molten_colossus",1.25,Color(1.3,0.85,0.6)],
    "hydra_head_left":["Hydra's Frost Head",160,"wyrm","2a4a7a","8fd6ff",2.6,50,["beam","volley","rain"],"","thornscale_wyrm",0.7,Color(0.65,0.85,1.35)],
    "hydra_head_right":["Hydra's Storm Head",160,"wyrm","4a2a7a","f6ef7a",2.6,50,["rain","charge","volley"],"","thornscale_wyrm",0.7,Color(1.1,1.0,0.55)],
    "stormcrown_hydra":["Stormcrown Hydra",165,"wyrm","2a3a5a","c9a4ff",3.4,115,["beam","rain","slam","volley","summon","charge"],"bone_wyvern","thornscale_wyrm",1.3,Color(0.8,0.85,1.3)],
    "seraph_guardian_dawn":["Dawn Guardian",185,"clock","f2c94c","fff2b8",2.4,32,["beam","volley"],"","chronovore",0.6,Color(1.35,1.2,0.7)],
    "seraph_guardian_dusk":["Dusk Guardian",185,"clock","6a5ab8","c9a4ff",2.4,32,["rain","slam"],"","chronovore",0.6,Color(0.8,0.7,1.35)],
    "seraph_guardian_star":["Star Guardian",185,"clock","8fd6ff","ffffff",2.4,32,["charge","volley"],"","chronovore",0.6,Color(0.8,1.2,1.35)],
    "dreaming_seraph":["Dreaming Seraph",190,"idol","f2ecff","ff9ad6",3.0,85,["beam","rain","volley","summon"],"gloam_sentinel","gloam_idol",1.2,Color(1.25,1.15,1.4)],
    "seraph_awakened":["Seraph Awakened",195,"idol","3a1a3a","ff4d6d",3.2,110,["beam","rain","slam","volley","charge","summon"],"gloam_sentinel","gloam_idol",1.35,Color(1.45,0.75,0.95)],
}
# Hard-mode rematches: "<boss>_hard" is 40 levels higher with one extra pattern.
const HARD_LEVELS=40
# Named field bosses for the deeper hunting grounds: [monster, name].
const FIELD_BOSSES={"dewdrop":["pebble_snail","Old Shellback"],"mossvale":["gloom_stump","Grumblebark"],"rotfen":["swamp_gator","Bogmaw"],
    "emberpeak":["crimson_drake","Cindermaw"],"frostspire":["rime_wolf","Whitefang Alpha"],"clockwork":["tick_sentinel","Overclocked Sentinel"],
    "bonepit":["bone_captain","Marrow Captain"],"tidegrave":["coral_golem","Coralback Ancient"],"skyreach":["storm_centaur","Stormhoof Khan"],
    "timeless":["memory_warden","The Last Warden"]}
static func hp_for(level: int) -> int: return int(20+9*level+0.35*level*level)
static func xp_for(level: int) -> int: return int(24+6*clampi(level,1,200)+0.28*pow(clampi(level,1,200),2))
static func profile(id: String) -> Dictionary:
    if LEGACY.has(id):
        var result=LEGACY[id].duplicate(true)
        result.xp=experience(id,result.level)
        return result
    if ROSTER.has(id):
        var r=ROSTER[id]
        var p={"name":r[0],"level":r[1],"body":r[2],"behavior":r[3],"color":Color(r[4]),"accent":Color(r[5]),"size":r[6],
            "base_attack":4+int(r[1]/8.0),"hp":hp_for(r[1]),"xp":xp_for(r[1])}
        p.merge(r[7])
        if p.behavior=="tank": p.hp=int(p.hp*1.6)
        return p
    if id.ends_with("_hard") and BOSSES.has(id.trim_suffix("_hard")):
        var base=profile(id.trim_suffix("_hard"))
        var hard_level=mini(200,base.level+HARD_LEVELS)
        var factor=float(hp_for(hard_level))/hp_for(base.level)
        base.name=base.name+" (Hard)"
        base.level=hard_level
        base.hp=int(base.hp*factor*1.5)
        base.xp=xp_for(hard_level)*45
        base.base_attack=8+int(hard_level/6.0)
        var extra=["rain","beam","volley","charge"]
        for pattern in extra:
            if not base.patterns.has(pattern):
                base.patterns=base.patterns+[pattern]
                break
        base.art=id.trim_suffix("_hard")
        base.hard=true
        base.damage_mult=1.35
        return base
    if RAID_PARTS.has(id):
        var r=RAID_PARTS[id]
        return {"name":r[0],"level":r[1],"body":r[2],"color":Color(r[3]),"accent":Color(r[4]),"size":r[5],"boss":true,"raid":true,
            "base_attack":10+int(r[1]/5.0),"hp":hp_for(r[1])*r[6]*3,"damage_mult":1.7,"xp":xp_for(r[1])*20,"patterns":r[7],"minion":r[8],"art":r[9],"art_scale":r[10],"tint":r[11]}
    if BOSSES.has(id):
        var b=BOSSES[id]
        return {"name":b[0],"level":b[1],"body":b[2],"color":Color(b[3]),"accent":Color(b[4]),"size":b[5],"boss":true,
            "base_attack":8+int(b[1]/6.0),"hp":hp_for(b[1])*b[6]*2,"xp":xp_for(b[1])*30,"patterns":b[7],"minion":b[8]}
    return {"name":"Monster","level":1,"base_attack":4,"hp":40,"xp":20,"behavior":"walker","body":"slime","color":Color("8fd6b6"),"accent":Color.WHITE,"size":1.0}
static func damage(id: String,level: int,multiplier=1.0) -> int:
    var p=profile(id)
    # Roster monsters placed at another level use that level's base attack.
    var base=p.base_attack if LEGACY.has(id) or level==p.level else (8+int(level/6.0) if BOSSES.has(id) else 4+int(level/8.0))
    var l=clampi(level,1,200)
    return maxi(1,int((base+2*(l-1)+0.006*l*l)*multiplier*p.get("damage_mult",1.0)))
static func is_boss(id: String) -> bool: return BOSSES.has(id) or id=="rootwarden" or RAID_PARTS.has(id) or id.ends_with("_hard") and BOSSES.has(id.trim_suffix("_hard"))

static func experience(id: String,level: int) -> int:
    return xp_for(level)*(10 if id=="rootwarden" else 30 if BOSSES.has(id) else 1)
