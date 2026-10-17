extends RefCounted
static var _cache: Dictionary={}
static func definition(id: String) -> Dictionary:
    if _cache.is_empty(): _cache=build_world()
    return _cache.get(id,{})
static func all_ids() -> Array:
    if _cache.is_empty(): _cache=build_world()
    return _cache.keys()
static func regions() -> Array:
    var result=[]
    for id in all_ids():
        var data=definition(id)
        if data.safe: result.append(data)
    return result
static func base_maps() -> Dictionary:
    return {
        "town": {"width":1800,"title":"WILLOWBRIDGE  /  SAFE TOWN", "platforms":[[730,460,280],[1220,420,260]],
            "spawns":{"entry":Vector2(260,590),"portal":Vector2(1450,590)},
            "portals":[{"position":Vector2(1580,610),"target":"forest","spawn":"entry","label":"Whisperwood →\nUp to enter"}],"enemies":[]},
        "forest": {"width":3000,"title":"THE WHISPERWOOD  /  MONSTER FIELD", "platforms":[[750,485,300],[1100,375,280],[1500,475,350],[1940,350,300],[2370,455,380]],
            "spawns":{"entry":Vector2(250,590),"portal":Vector2(250,590),"exit":Vector2(2700,590)},
            "portals":[{"position":Vector2(150,610),"target":"town","spawn":"entry","label":"← Willowbridge\nUp to return"},{"position":Vector2(2850,610),"target":"briar","spawn":"entry","label":"Briar Hollow →\nLv 15+ • Up to enter"}],
            "enemies":[[640,610,"mossling"],[980,610,"mossling"],[1290,610,"mossling"],[1660,610,"mossling"],[2210,610,"mossling"],[2670,610,"mossling"],[815,485,"lantern"],[1530,475,"lantern"],[2370,455,"lantern"]]},
        "briar": {"width":3400,"title":"BRIAR HOLLOW  /  LV 15+ HUNTING", "platforms":[[650,500,280],[1050,390,260],[1500,490,360],[1940,380,280],[2370,470,320]],
            "spawns":{"entry":Vector2(250,590),"portal":Vector2(250,590)},
            "portals":[{"position":Vector2(150,610),"target":"forest","spawn":"exit","label":"← Whisperwood\nUp to return"}],
            "enemies":[[630,610,"thornling"],[1000,610,"thornling"],[1320,610,"thornling"],[1730,610,"thornling"],[2100,610,"briar_lantern"],[2510,610,"thornling"],[700,500,"briar_lantern"],[1500,490,"thornling"],[2920,610,"rootwarden"]]}
    }
const ROWS=[
    ["firstlight", "Firstlight Isle", "meadow", 1, "Snailgrass Path", "gullhaven", "Guide Wren"],
    ["gullhaven", "Gullhaven", "coast", 3, "Saltwind Road", "town", "Harbormaster Fenn"],
    ["starbough", "Starbough", "forest", 10, "Canopy Stair", "town", "Arcanist Ilyra"],
    ["ironridge", "Ironridge", "highland", 12, "Emberstep Ridge", "town", "Warden Bram"],
    ["shadecross", "Shadecross", "city", 12, "Gutterlane", "town", "Mara Vex"],
    ["hollowroot", "Hollowroot", "roots", 20, "Rootcellar Depths", "town", "Lanternkeeper Oren"],
    ["sunpetal", "Sunpetal Cove", "coast", 15, "Sunpetal Strand", "gullhaven", "Shellkeeper Nessa"],
    ["skylume", "Skylume", "cloud", 25, "Cloudspire Steps", "gullhaven", "Waykeeper Astra"],
    ["frostmere", "Frostmere", "snow", 35, "Whitefang Pass", "skylume", "Watchkeeper Edda"],
    ["tickletop", "Tickletop", "toy", 35, "Clockwork Warrens", "skylume", "Clockkeeper Tock"],
    ["brasswatch", "Brasswatch", "tech", 40, "Starfall Fields", "tickletop", "Sentinel Cora"],
    ["lanternvale", "Lanternvale", "eastern", 40, "Foxfire Hollow", "tickletop", "Storykeeper Mei"],
    ["tideglass", "Tideglass", "underwater", 40, "Coral Cathedral", "skylume", "Pearlkeeper Luma"],
    ["wyrmrest", "Wyrmrest", "dragon", 60, "Wyrmwood Reach", "skylume", "Drakewarden Sol"],
    ["peachspire", "Peachspire", "eastern", 45, "Peachwind Terrace", "skylume", "Master Sora"],
    ["reedhaven", "Reedhaven", "coast", 45, "Reedwater Marsh", "peachspire", "Herbalist Ren"],
    ["saffron", "Saffron Reach", "desert", 45, "Sunscar Dunes", "skylume", "Caravaner Yasra"],
    ["verdigris", "Verdigris", "alchemy", 50, "Glasscoil Works", "saffron", "Alchemist Vela"],
    ["hourglass", "Hourglass Sanctum", "temple", 80, "Echoes of Tomorrow", "wyrmrest", "Archivist Aeon"],
    ["moonshrine", "Moonpetal Shrine", "shrine", 45, "Foxmoon Grove", "gullhaven", "Shrinekeeper Aki"],
    ["emberlane", "Emberlane", "city", 45, "Ashmarket Rooftops", "moonshrine", "Broker Rook"],
    ["mistkeep", "Mistblade Keep", "shrine", 60, "Silent Ramparts", "moonshrine", "Sentinel Kiri"],
    ["copperwick", "Copperwick", "tech", 35, "Hollowlight Estate", "gullhaven", "Engineer Flint"],
    ["thornscar", "Thornscar Lodge", "roots", 65, "Thornscar Wilds", "copperwick", "Ranger Vale"],
    ["rainport", "Rainport", "city", 50, "Lantern Wreck", "gullhaven", "Dockkeeper Juno"],
    ["bloomkamp", "Bloomkamp", "coast", 50, "Wonderwheel Park", "gullhaven", "Fairkeeper Poppy"],
    ["farmeadow", "Farmeadow", "farm", 2, "Whisperwheat Fields", "town", "Farmer Rowan"],
    ["crownreach", "Crownreach", "cloud", 2, "Gleaming Steps", "skylume", "Keeper Aurin"],
    ["rimehaven", "Rimehaven", "snow", 2, "Snowbell Trail", "frostmere", "Guide Lumi"],
    ["jadehaven", "Jadehaven", "eastern", 45, "Jadegrain Fields", "gullhaven", "Grower Lin"],
    ["lotusquay", "Lotus Quay", "coast", 45, "Lotuswater Crossing", "gullhaven", "Boatkeeper Suri"]
]

static func region_rows() -> Array:
    return ROWS
static func build_world() -> Dictionary:
    var world=base_maps()
    for id in world:
        world[id].id=id
        world[id].name={"town":"Willowbridge","forest":"Whisperwood","briar":"Briar Hollow"}[id]
        world[id].safe=id=="town"
        world[id].biome="mushroom" if id=="town" else "forest" if id=="forest" else "roots"
        world[id].region="town"
        world[id].level=1 if id=="town" else 3 if id=="forest" else 18
        world[id].loot_zone="briar" if id=="briar" else "forest"
    world.town.width=3400
    world.town.npc={"name":"Captain Elowen","greeting":"Welcome to Willowbridge.","path":"all"}
    world.forest.notice="Briar Hollow lies beyond the far-right portal. Recommended level 15+."
    world.briar.notice="Rootwarden guards the far end. Recommended level 25+. Jump over the slam."
    for row in region_rows():
        var id=row[0]
        var trail=id+"_trail"
        var npc_path="warrior" if id=="ironridge" else "thief" if id=="shadecross" else "magician" if id=="starbough" else "bowman" if id=="thornscar" else ""
        world[id]={"id":id,"name":row[1],"title":row[1].to_upper()+"  /  SAFE TOWN","safe":true,"region":id,"biome":row[2],"level":row[3],"width":2200,"platforms":[[1100,465,280],[1720,410,300]],"spawns":{"entry":Vector2(350,590)},"portals":[],"enemies":[],"loot_zone":"forest","npc":{"name":row[6],"greeting":"Welcome to "+row[1]+". Open your map to plan the next journey.","path":npc_path}}
        var level=int(row[3])
        var left_type="thornling" if level>=18 else "mossling"
        var right_type="briar_lantern" if level>=18 else "lantern"
        world[trail]={"id":trail,"name":row[4],"title":row[4].to_upper()+"  /  LV %d+ HUNTING" % level,"safe":false,"region":id,"biome":row[2],"level":level,"width":2600,"platforms":[[700,500,300],[1150,410,280],[1600,490,360],[2050,380,280]],"spawns":{"entry":Vector2(250,590),"exit":Vector2(2350,590)},"portals":[],"enemies":[[650,610,left_type,level],[1030,610,left_type,level],[1410,610,left_type,level],[1860,610,left_type,level],[760,500,right_type,mini(100,level+2)],[1600,490,right_type,mini(100,level+2)]],"loot_zone":"relic" if level>=60 else "expedition" if level>=35 else "briar" if level>=15 else "forest","notice":"Level %d+ hunting. The opposite portal leads to %s." % [level,row[1]]}
    for row in region_rows():
        var id=row[0]
        var trail=id+"_trail"
        var parent=row[5]
        add_portal(world,trail,150,parent,"route_"+id,"Return to "+world[parent].name)
        add_portal(world,trail,2450,id,"entry","To "+row[1])
        add_portal(world,id,150,trail,"exit",row[4]+" / Lv %d+" % int(row[3]))
        var x=1000+int(world[parent].get("branches",0))*260
        if parent=="town":
            x=[150,1000,2100,2360,2620,2880][int(world[parent].get("branches",0))]
        world[parent].branches=int(world[parent].get("branches",0))+1
        world[parent].width=maxi(world[parent].width,x+300)
        world[parent].spawns["route_"+id]=Vector2(x+100,590)
        add_portal(world,parent,x,trail,"entry",row[1]+"\n"+row[4]+" (Lv %d+)" % int(row[3]))
    add_extensions(world)
    for id in world: add_tiers(world[id])
    return world
# Upper tiers: long ledges above each hunting map reached by ropes and ladders.
# climbs: [x, top y, bottom y, "rope" or "ladder"]; top: highest point the camera shows.
const TIER_A=230
const TIER_B=-20
static func add_tiers(map: Dictionary):
    map.climbs=[]
    map.top=137
    if map.safe or map.has("boss"): return
    var ground=[]
    var high=[]
    for entry in map.get("enemies",[]):
        if entry[2]=="rootwarden": continue
        if entry[1]>=600: ground.append(entry)
        else: high.append(entry)
    if ground.is_empty(): return
    map.platforms=map.platforms.duplicate(true)
    map.enemies=map.enemies.duplicate(true)
    var index=0
    var c=700
    while c<map.width-520:
        var kind="rope" if index%2==0 else "ladder"
        map.platforms.append([c,TIER_A,440])
        map.climbs.append([c-160,TIER_A,610,kind])
        map.platforms.append([c+180,TIER_B,360])
        map.climbs.append([c+110,TIER_B,TIER_A,"ladder" if kind=="rope" else "rope"])
        var upper=(high if not high.is_empty() else ground)[index%(high.size() if not high.is_empty() else ground.size())]
        var lower=ground[(index*2+1)%ground.size()]
        var a=[c-90,TIER_A,upper[2]]
        var b=[c+180,TIER_B,lower[2]]
        if upper.size()>3: a.append(mini(200,upper[3]+1))
        if lower.size()>3: b.append(mini(200,lower[3]+3))
        map.enemies.append(a)
        map.enemies.append([c+120,TIER_A,upper[2]]+([a[3]] if a.size()>3 else []))
        map.enemies.append(b)
        index+=1
        c+=1000
    if index>0: map.top=TIER_B-260

# Themed monsters for each regional hunting route: [ground x4, platform x2].
const ROUTE_MONSTERS={
    "firstlight":[["pebble_snail","azure_snail","pebble_snail","ember_snail"],["puffspore","puffspore"]],
    "farmeadow":[["stumpkin","bristle_hog","puffspore","stumpkin"],["jellop","puffspore"]],
    "crownreach":[["azure_snail","jellop","pebble_snail","jellop"],["puffspore","jellop"]],
    "rimehaven":[["frost_cub","azure_snail","frost_cub","azure_snail"],["jellop","puffspore"]],
    "gullhaven":[["ember_snail","tangerine_cap","bristle_hog","tangerine_cap"],["jellop","puffspore"]],
    "starbough":[["gloom_stump","jellop","mossy_cap","stumpkin"],["jellop","puffspore"]],
    "ironridge":[["stumpkin","hatchet_stump","tusker_boar","gloom_stump"],["gloom_stump","hatchet_stump"]],
    "shadecross":[["inkling","swamp_gator","horned_cap","inkling"],["inkling","wisp_wraith"]],
    "sunpetal":[["reef_snapper","ember_snail","reef_snapper","tangerine_cap"],["inkling","jellop"]],
    "hollowroot":[["rotcap","horned_cap","rotcap","cinder_boar"],["wisp_wraith","shade_wraith"]],
    "skylume":[["jellop","canopy_ape","mossy_cap","canopy_ape"],["wisp_wraith","twinhead_birk"]],
    "frostmere":[["frost_cub","rime_wolf","snowhorn","frost_cub"],["rime_wolf","frost_cub"]],
    "tickletop":[["tick_sentinel","stitched_bruin","tick_sentinel","grim_clockwork"],["phantom_timepiece","tick_sentinel"]],
    "copperwick":[["rotcap","shade_wraith","bonewalker","rotcap"],["wisp_wraith","shade_wraith"]],
    "brasswatch":[["grim_clockwork","rubble_golem","tick_sentinel","obsidian_golem"],["phantom_timepiece","phantom_timepiece"]],
    "lanternvale":[["canopy_ape","horned_cap","rime_wolf","mossy_cap"],["wisp_wraith","canopy_ape"]],
    "tideglass":[["reef_snapper","coral_golem","reef_snapper","tide_inkling"],["gloomfin","gloomfin"]],
    "peachspire":[["canopy_ape","stitched_bruin","canopy_ape","rime_wolf"],["twinhead_birk","canopy_ape"]],
    "reedhaven":[["swamp_gator","mossy_cap","swamp_gator","inkling"],["wisp_wraith","mossy_cap"]],
    "saffron":[["dune_lizard","rubble_golem","dune_lizard","cinder_boar"],["twinhead_birk","dune_lizard"]],
    "verdigris":[["obsidian_golem","rubble_golem","tick_sentinel","obsidian_golem"],["phantom_timepiece","shade_wraith"]],
    "moonshrine":[["tangerine_cap","horned_cap","mossy_cap","rotcap"],["puffspore","wisp_wraith"]],
    "emberlane":[["cinder_boar","bonewalker","horned_cap","cinder_boar"],["shade_wraith","bone_archer"]],
    "mistkeep":[["memory_warden","oblivion_monk","memory_warden","moonfang"],["shade_wraith","bone_archer"]],
    "rainport":[["bonewalker","bone_archer","bone_captain","bonewalker"],["wisp_wraith","shade_wraith"]],
    "bloomkamp":[["stitched_bruin","tick_sentinel","dread_bruin","stitched_bruin"],["phantom_timepiece","jellop"]],
    "wyrmrest":[["azure_drake","crimson_drake","frost_drake","storm_centaur"],["skyscale_wyvern","twinhead_birk"]],
    "thornscar":[["moonfang","rime_wolf","cinder_centaur","moonfang"],["bone_wyvern","shade_wraith"]],
    "hourglass":[["memory_warden","oblivion_monk","chrono_guardian","memory_warden"],["gloam_sentinel","oblivion_monk"]],
    "jadehaven":[["mossy_cap","tusker_boar","canopy_ape","horned_cap"],["twinhead_birk","mossy_cap"]],
    "lotusquay":[["swamp_gator","reef_snapper","tide_inkling","swamp_gator"],["gloomfin","inkling"]]}
# Deeper hunting grounds that continue past the regional routes, up to level 200.
# id, name, level range, loot band, biome, parent town, ground monsters, platform monsters
const FIELDS=[
    ["dewdrop","Dewdrop Meadow","Lv 1-12",10,"meadow","farmeadow",["pebble_snail","azure_snail","puffspore","stumpkin","ember_snail","jellop","tangerine_cap","bristle_hog"],["puffspore","jellop","tangerine_cap"]],
    ["mossvale","Mossvale Thicket","Lv 12-25",10,"forest","starbough",["gloom_stump","mossy_cap","hatchet_stump","horned_cap","tusker_boar","gloom_stump"],["inkling","mossy_cap","inkling"]],
    ["rotfen","Rotfen Marsh","Lv 25-45",30,"roots","hollowroot",["rotcap","swamp_gator","cinder_boar","rotcap","rubble_golem","swamp_gator"],["wisp_wraith","canopy_ape","shade_wraith"]],
    ["emberpeak","Emberpeak Canyon","Lv 45-70",50,"highland","ironridge",["azure_drake","dune_lizard","obsidian_golem","crimson_drake","azure_drake","frost_drake"],["crimson_drake","frost_drake","azure_drake"]],
    ["frostspire","Frostspire Peaks","Lv 60-85",70,"snow","frostmere",["frost_cub","rime_wolf","snowhorn","frost_cub","moonfang","rime_wolf"],["frost_cub","rime_wolf","moonfang"]],
    ["clockwork","Clockwork Spire","Lv 80-110",90,"toy","tickletop",["tick_sentinel","stitched_bruin","grim_clockwork","dread_bruin","tick_sentinel","stitched_bruin"],["phantom_timepiece","tick_sentinel","phantom_timepiece"]],
    ["bonepit","Bonepit Mine","Lv 100-125",110,"roots","frostmere",["bonewalker","bone_captain","magma_golem","bonewalker","bone_archer","bone_captain"],["bone_archer","bone_archer","bonewalker"]],
    ["tidegrave","Tidegrave Depths","Lv 110-135",110,"underwater","tideglass",["reef_snapper","coral_golem","reef_snapper","tide_inkling","coral_golem","reef_snapper"],["gloomfin","tide_inkling","gloomfin"]],
    ["skyreach","Skyreach Plateau","Lv 125-160",130,"dragon","wyrmrest",["storm_centaur","cinder_centaur","storm_centaur","cinder_centaur"],["twinhead_birk","bone_wyvern","skyscale_wyvern"]],
    ["timeless","Timeless Sanctum","Lv 155-200",150,"temple","hourglass",["memory_warden","oblivion_monk","chrono_guardian","memory_warden","oblivion_monk"],["gloam_sentinel","oblivion_monk","gloam_sentinel"]],
]
# Boss lairs and the town whose gate leads to them.
const LAIRS={"grand_shellmaw":"sunpetal","elder_stumpus":"ironridge","gelatinous_monarch":"shadecross","mother_cap":"moonshrine",
    "blight_mother":"hollowroot","lesser_hellwing":"hollowroot","crimson_hellwing":"thornscar","chronovore":"tickletop",
    "abyssal_leviathan":"tideglass","molten_colossus":"frostmere","thornscale_wyrm":"wyrmrest","gloam_idol":"hourglass"}
const LAYOUTS=[
    [[700,480,300],[1100,370,280],[1550,470,340],[2000,360,300],[2450,460,360]],
    [[650,500,280],[1050,390,260],[1500,490,360],[1940,380,280],[2370,470,320]],
    [[600,470,320],[980,360,240],[1400,460,300],[1820,350,260],[2260,450,340],[2700,370,220]],
]
static func fields() -> Array: return FIELDS
static func boss_arena_id(boss: String) -> String: return "arena_"+boss
static func band_for(level: int) -> String:
    var best=10
    for band in [10,30,50,70,90,110,130,150,170]:
        if level>=band: best=band
    return "lv%d" % best
# Adds a two-way gate between a town and a new map.
static func link(world: Dictionary,town: String,target: String,label: String):
    var x=1000
    for portal in world[town].portals: x=maxi(x,int(portal.position.x)+260)
    world[town].width=maxi(world[town].width,x+300)
    world[town].spawns["from_"+target]=Vector2(x+100,590)
    add_portal(world,town,x,target,"entry",label)
    add_portal(world,target,150,town,"from_"+target,"Return to "+world[town].name)
static func add_extensions(world: Dictionary):
    var EnemyStats=preload("res://data/enemy_stats.gd")
    for row in region_rows():
        var id=row[0]
        var trail=world[id+"_trail"]
        var level=int(row[3])
        var lists=ROUTE_MONSTERS.get(id,[])
        if lists.is_empty(): continue
        var enemies=[]
        for i in range(4): enemies.append([650+i*400 if i<3 else 1860,610,lists[0][i],level])
        enemies.append([760,500,lists[1][0],mini(200,level+2)])
        enemies.append([1600,490,lists[1][1],mini(200,level+2)])
        trail.enemies=enemies
        trail.loot_zone=trail.loot_zone if level<35 else band_for(level)
    for index in FIELDS.size():
        var f=FIELDS[index]
        var layout: Array=LAYOUTS[index%LAYOUTS.size()]
        var enemies=[]
        var ground: Array=f[6]
        for i in range(ground.size()): enemies.append([560+i*int(2300.0/ground.size()),610,ground[i]])
        var high: Array=f[7]
        for i in range(high.size()):
            var platform=layout[(i*2+1)%layout.size()]
            enemies.append([platform[0],platform[1],high[i]])
        var low=int(f[2].split(" ")[1].split("-")[0])
        world[f[0]]={"id":f[0],"name":f[1],"title":"%s  /  %s" % [f[1].to_upper(),f[2].to_upper()],"safe":false,"region":f[5],"biome":f[4],"level":low,
            "width":3200,"platforms":layout,"spawns":{"entry":Vector2(250,590)},"portals":[],"enemies":enemies,"loot_zone":"lv%d" % f[3],
            "notice":"%s  •  Recommended %s" % [f[1],f[2]]}
        link(world,f[5],f[0],f[1]+"\n"+f[2])
    for boss in LAIRS:
        var town=LAIRS[boss]
        var p=EnemyStats.profile(boss)
        var arena=boss_arena_id(boss)
        world[arena]={"id":arena,"name":p.name+"'s Lair","title":"%s  /  BOSS LV %d" % [p.name.to_upper(),p.level],"safe":false,"region":town,"biome":world[town].biome,"level":p.level,
            "width":2000,"platforms":[[520,470,260],[1480,470,260]],"spawns":{"entry":Vector2(250,590)},"portals":[],"enemies":[[1350,610,boss]],
            "loot_zone":band_for(p.level),"boss":boss,"notice":"%s  •  Lv %d boss. Jump over slams and low sweeps!" % [p.name,p.level]}
        link(world,town,arena,"Boss: %s\nLv %d" % [p.name,p.level])
static func add_portal(world: Dictionary,id: String,x: int,target: String,spawn: String,text: String):
    world[id].portals.append({"position":Vector2(x,610),"target":target,"spawn":spawn,"label":text+"\nUp to travel"})
static func route_between(start_id: String,end_id: String) -> Array:
    if definition(start_id).is_empty() or definition(end_id).is_empty(): return []
    var queue=[start_id]
    var previous={start_id:""}
    while not queue.is_empty():
        var current=queue.pop_front()
        if current==end_id:
            var path=[]
            while current!="":
                path.push_front(current)
                current=previous[current]
            return path
        for portal in definition(current).portals:
            if not previous.has(portal.target):
                previous[portal.target]=current
                queue.append(portal.target)
    return []
