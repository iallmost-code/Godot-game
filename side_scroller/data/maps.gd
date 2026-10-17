extends RefCounted
# Map data. Towns and starting areas are hand-made; hunting grounds and boss arenas
# below are generated from compact region tables so new regions are one entry each.
# theme = [sky tint, ground tint, tree tint]
const REGIONS=[
    # id, title, level range, loot band, theme, ground monsters, platform monsters, bosses
    ["dewdrop","DEWDROP MEADOW","Lv 1-12",10,["d8f0ff","ffffff","c8f0c0"],["pebble_snail","azure_snail","puffspore","stumpkin","ember_snail","jellop","tangerine_cap","bristle_hog"],["puffspore","jellop","tangerine_cap"],["grand_shellmaw"]],
    ["mossvale","MOSSVALE THICKET","Lv 12-25",10,["c8e8d0","d8f0c8","9ad89a"],["gloom_stump","mossy_cap","hatchet_stump","horned_cap","tusker_boar","gloom_stump"],["inkling","mossy_cap","inkling"],["elder_stumpus","gelatinous_monarch"]],
    ["rotfen","ROTFEN MARSH","Lv 25-45",30,["b8c8b0","b8c8a0","8aa080"],["rotcap","swamp_gator","cinder_boar","rotcap","rubble_golem","swamp_gator"],["wisp_wraith","canopy_ape","shade_wraith"],["mother_cap","blight_mother"]],
    ["emberpeak","EMBERPEAK CANYON","Lv 45-70",50,["ffd0a8","f0b890","d89a70"],["azure_drake","dune_lizard","obsidian_golem","crimson_drake","azure_drake","frost_drake"],["crimson_drake","frost_drake","azure_drake"],["lesser_hellwing"]],
    ["frostspire","FROSTSPIRE PEAKS","Lv 60-85",70,["e0f0ff","f0f8ff","d0e8f8"],["frost_cub","rime_wolf","snowhorn","frost_cub","moonfang","rime_wolf"],["frost_cub","rime_wolf","moonfang"],[]],
    ["clockwork","CLOCKWORK SPIRE","Lv 80-110",90,["e8d8ff","e0d0f0","c8b8e8"],["tick_sentinel","stitched_bruin","grim_clockwork","dread_bruin","tick_sentinel","stitched_bruin"],["phantom_timepiece","tick_sentinel","phantom_timepiece"],["chronovore"]],
    ["bonepit","BONEPIT MINE","Lv 100-125",110,["c8b8a8","b8a898","9a8a7a"],["bonewalker","bone_captain","magma_golem","bonewalker","bone_archer","bone_captain"],["bone_archer","bone_archer","bonewalker"],["crimson_hellwing","molten_colossus"]],
    ["tidegrave","TIDEGRAVE DEPTHS","Lv 110-135",110,["a8d8f0","a8c8e0","88b8d0"],["reef_snapper","coral_golem","reef_snapper","tide_inkling","coral_golem","reef_snapper"],["gloomfin","tide_inkling","gloomfin"],["abyssal_leviathan"]],
    ["skyreach","SKYREACH PLATEAU","Lv 125-160",130,["fff0d0","f0e8c8","e0d0a0"],["storm_centaur","cinder_centaur","storm_centaur","cinder_centaur"],["twinhead_birk","bone_wyvern","skyscale_wyvern"],["thornscale_wyrm"]],
    ["timeless","TIMELESS SANCTUM","Lv 155-200",150,["d8d0f0","d0c8e8","b8b0d8"],["memory_warden","oblivion_monk","chrono_guardian","memory_warden","oblivion_monk"],["gloam_sentinel","oblivion_monk","gloam_sentinel"],["gloam_idol"]],
]
const LAYOUTS=[
    [[700,480,300],[1100,370,280],[1550,470,340],[2000,360,300],[2450,460,360]],
    [[650,500,280],[1050,390,260],[1500,490,360],[1940,380,280],[2370,470,320]],
    [[600,470,320],[980,360,240],[1400,460,300],[1820,350,260],[2260,450,340],[2700,370,220]],
]
static func regions() -> Array: return REGIONS
static func region(id: String) -> Array:
    for r in REGIONS:
        if r[0]==id: return r
    return []
static func boss_arena_id(boss: String) -> String: return "arena_"+boss
static func definition(id: String) -> Dictionary:
    var fixed={
        "town": {"width":1800,"title":"WILLOWBRIDGE  /  SAFE TOWN", "platforms":[[730,460,280],[1220,420,260]],
            "spawns":{"entry":Vector2(260,590),"portal":Vector2(1450,590)},
            "portals":[{"position":Vector2(1580,610),"target":"forest","spawn":"entry","label":"Whisperwood →\nUp to enter"}],"enemies":[],"loot":"forest"},
        "forest": {"width":3000,"title":"THE WHISPERWOOD  /  MONSTER FIELD", "platforms":[[750,485,300],[1100,375,280],[1500,475,350],[1940,350,300],[2370,455,380]],
            "spawns":{"entry":Vector2(250,590),"portal":Vector2(250,590),"exit":Vector2(2700,590)},
            "portals":[{"position":Vector2(150,610),"target":"town","spawn":"entry","label":"← Willowbridge\nUp to return"},{"position":Vector2(2850,610),"target":"briar","spawn":"entry","label":"Briar Hollow →\nLv 15+ • Up to enter"}],
            "enemies":[[640,610,"mossling"],[980,610,"mossling"],[1290,610,"mossling"],[1660,610,"mossling"],[2210,610,"mossling"],[2670,610,"mossling"],[815,485,"lantern"],[1530,475,"lantern"],[2370,455,"lantern"]],
            "loot":"forest","sign":"Briar Hollow: tougher enemies and better loot →"},
        "briar": {"width":3400,"title":"BRIAR HOLLOW  /  LV 15+ HUNTING", "platforms":[[650,500,280],[1050,390,260],[1500,490,360],[1940,380,280],[2370,470,320]],
            "spawns":{"entry":Vector2(250,590),"portal":Vector2(250,590)},
            "portals":[{"position":Vector2(150,610),"target":"forest","spawn":"exit","label":"← Whisperwood\nUp to return"}],
            "enemies":[[630,610,"thornling"],[1000,610,"thornling"],[1320,610,"thornling"],[1730,610,"thornling"],[2100,610,"briar_lantern"],[2510,610,"thornling"],[700,500,"briar_lantern"],[1500,490,"thornling"],[2920,610,"rootwarden"]],
            "loot":"briar","sign":"ROOTWARDEN ahead →\nLv 25 recommended • Jump over the slam!"}
    }
    if fixed.has(id): return fixed[id]
    for index in REGIONS.size():
        var r=REGIONS[index]
        if id==r[0]: return field(r,index)
        for boss in r[7]:
            if id==boss_arena_id(boss): return arena(r,boss)
    return {}
static func field(r: Array,index: int) -> Dictionary:
    var layout: Array=LAYOUTS[index%LAYOUTS.size()]
    var width=3200
    var enemies=[]
    var ground: Array=r[5]
    for i in range(ground.size()):
        enemies.append([560+i*int(2300.0/ground.size()),610,ground[i]])
    var high: Array=r[6]
    for i in range(high.size()):
        var platform=layout[(i*2+1)%layout.size()]
        enemies.append([platform[0],platform[1],high[i]])
    var portals=[{"position":Vector2(150,610),"target":"town","spawn":"entry","label":"← Willowbridge\nUp to return"}]
    var bosses: Array=r[7]
    for i in range(bosses.size()):
        var name=preload("res://data/enemy_stats.gd").profile(bosses[i]).name
        portals.append({"position":Vector2(width-150-i*260,610),"target":boss_arena_id(bosses[i]),"spawn":"entry","label":"%s →\nBoss • Up to enter" % name})
    return {"width":width,"title":"%s  /  %s" % [r[1],r[2].to_upper()],"platforms":layout,
        "spawns":{"entry":Vector2(250,590),"portal":Vector2(250,590),"exit":Vector2(width-420,590)},
        "portals":portals,"enemies":enemies,"loot":"lv%d" % r[3],"theme":r[4],"level_range":r[2],
        "sign":"%s  •  %s" % [r[1].capitalize(),r[2]]}
static func arena(r: Array,boss: String) -> Dictionary:
    var p=preload("res://data/enemy_stats.gd").profile(boss)
    return {"width":2000,"title":"%s  /  BOSS LV %d" % [p.name.to_upper(),p.level],"platforms":[[520,470,260],[1480,470,260]],
        "spawns":{"entry":Vector2(250,590),"portal":Vector2(250,590)},
        "portals":[{"position":Vector2(150,610),"target":r[0],"spawn":"exit","label":"← %s\nUp to leave" % r[1].capitalize()}],
        "enemies":[[1350,610,boss]],"loot":"lv%d" % r[3],"theme":r[4],"boss":boss,
        "sign":"%s  •  Lv %d boss\nWatch its warnings and jump over slams and sweeps!" % [p.name,p.level]}
