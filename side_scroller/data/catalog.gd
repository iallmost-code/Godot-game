extends RefCounted
static func skills() -> Dictionary:
    return {
        "basic": {"name":"Spear Combo", "tier":0, "max":1, "active":true, "mana":0, "cooldown":0.38, "reach":110, "targets":2, "power":1.0, "description":"A quick spear combo. Always available."},
        "sweep": {"name":"Crescent Sweep", "tier":1, "max":5, "active":true, "mana":4, "cooldown":1.2, "reach":160, "targets":3, "power":1.4, "description":"Sweep a broad crescent through nearby monsters."},
        "thrust": {"name":"Driving Thrust", "tier":1, "max":5, "active":true, "mana":5, "cooldown":2.0, "reach":190, "targets":3, "power":1.2, "description":"Pierce a line of monsters and push them back."},
        "strength": {"name":"Strength Training", "tier":1, "max":5, "active":false, "description":"Gain 3 attack for each rank."},
        "iron": {"name":"Iron Skin", "tier":1, "max":5, "active":false, "description":"Gain 2 defense for each rank."},
        "mastery": {"name":"Spear Mastery", "tier":2, "max":5, "active":false, "description":"Gain 4 attack per rank. Unlocks Ground Wave."},
        "wave": {"name":"Ground Wave", "tier":2, "max":5, "active":true, "mana":8, "cooldown":3.0, "reach":330, "targets":5, "power":2.0, "requires":"mastery", "description":"A powerful sweeping wave. Ranks 3 and 5 increase reach and targets."},
        "vigor": {"name":"Battle Vigor", "tier":2, "max":5, "active":false, "description":"Gain 15 maximum HP per rank."}
    }
static func jobs() -> Dictionary:
    return {"beginner":{"name":"Beginner", "tier":0, "level":1}, "warrior":{"name":"Warrior", "tier":1, "level":10}, "spearman":{"name":"Spearman", "tier":2, "level":30}, "dragon_knight":{"name":"Dragon Knight", "tier":3, "level":60, "future":true}, "dark_knight":{"name":"Dark Knight", "tier":4, "level":100, "future":true}}
static func items() -> Dictionary:
    return {"starter_spear":{"name":"Oak Spear", "slot":"weapon", "attack":18, "defense":0, "icon":"♜"}, "starter_armor":{"name":"Trail Vest", "slot":"armor", "attack":0, "defense":2, "icon":"◆"}, "forest_spear":{"name":"Windsteel Spear", "slot":"weapon", "attack":24, "defense":0, "icon":"♜"}, "forest_armor":{"name":"Mossguard Coat", "slot":"armor", "attack":0, "defense":5, "icon":"◆"}}
