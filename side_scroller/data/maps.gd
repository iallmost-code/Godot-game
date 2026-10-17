extends RefCounted
static func definition(id: String) -> Dictionary:
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
    }.get(id,{})
