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
        var npc_path="warrior" if id=="ironridge" else "thief" if id=="shadecross" else ""
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
    return world
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
