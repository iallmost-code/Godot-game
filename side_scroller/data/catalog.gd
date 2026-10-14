extends RefCounted
static func skills() -> Dictionary:
    return {
        "basic": {"name":"Sword Combo", "path":"warrior", "tier":0, "max":1, "active":true, "mana":0, "cooldown":0.38, "reach":110, "targets":2, "power":1.0, "description":"A quick weapon combo. Always available."},
        "sweep": {"name":"Crescent Sweep", "path":"warrior", "tier":1, "max":5, "active":true, "mana":4, "cooldown":1.2, "reach":160, "targets":3, "power":1.4, "description":"Sweep a broad crescent through nearby monsters."},
        "thrust": {"name":"Driving Thrust", "path":"warrior", "tier":1, "max":5, "active":true, "mana":5, "cooldown":2.0, "reach":190, "targets":3, "power":1.2, "description":"Lunge forward, pierce a line of monsters and push them back."},
        "strength": {"name":"Strength Training", "path":"warrior", "tier":1, "max":5, "active":false, "description":"Gain 3 attack for each rank."},
        "iron": {"name":"Iron Skin", "path":"warrior", "tier":1, "max":5, "active":false, "description":"Gain 2 defense for each rank."},
        "mastery": {"name":"Spear Mastery", "path":"warrior", "tier":2, "max":5, "active":false, "description":"Gain 4 attack per rank. Unlocks Ground Wave."},
        "wave": {"name":"Ground Wave", "path":"warrior", "tier":2, "max":5, "active":true, "mana":8, "cooldown":3.0, "reach":330, "targets":5, "power":2.0, "requires":"mastery", "description":"A powerful sweeping wave. Ranks 3 and 5 increase reach and targets."},
        "vigor": {"name":"Battle Vigor", "path":"warrior", "tier":2, "max":5, "active":false, "description":"Gain 15 maximum HP per rank."},
        "star": {"name":"Star Throw", "path":"thief", "tier":0, "max":1, "active":true, "mana":0, "cooldown":0.38, "reach":480, "targets":1, "power":1.0, "projectile":true, "description":"Throw a spinning star. No ammunition needed."},
        "twin_stars": {"name":"Twin Stars", "path":"thief", "tier":1, "max":5, "active":true, "mana":4, "cooldown":0.8, "reach":540, "targets":1, "power":0.85, "projectile":true, "description":"Throw two stars in quick succession at a distant target."},
        "star_fan": {"name":"Shadow Fan", "path":"thief", "tier":1, "max":5, "active":true, "mana":6, "cooldown":1.6, "reach":440, "targets":3, "power":1.25, "projectile":true, "description":"Send three stars across a wide fan to clear nearby monsters."},
        "precision": {"name":"Claw Precision", "path":"thief", "tier":1, "max":5, "active":false, "description":"Gain 3 throwing attack per rank."},
        "shadow_guard": {"name":"Shadow Guard", "path":"thief", "tier":1, "max":5, "active":false, "description":"Gain 2 defense per rank."}
    }
static func jobs() -> Dictionary:
    return {"beginner":{"name":"Beginner", "tier":0, "level":1}, "warrior":{"name":"Warrior", "tier":1, "level":10}, "thief":{"name":"Thief", "tier":1, "level":10}, "spearman":{"name":"Spearman", "tier":2, "level":30}, "dragon_knight":{"name":"Dragon Knight", "tier":3, "level":60, "future":true}, "dark_knight":{"name":"Dark Knight", "tier":4, "level":100, "future":true}}
static func items() -> Dictionary:
    return {
        "starter_sword":{"name":"Trail Sword", "slot":"weapon", "path":"warrior", "attack":18, "defense":0, "icon":"⚔"},
        "warrior_sword":{"name":"Elowen's Sword", "slot":"weapon", "path":"warrior", "attack":25, "defense":0, "icon":"⚔"},
        "forest_sword":{"name":"Windsteel Sword", "slot":"weapon", "path":"warrior", "attack":28, "defense":0, "icon":"⚔"},
        "starter_spear":{"name":"Oak Spear", "slot":"weapon", "path":"warrior", "attack":18, "defense":0, "icon":"♜"},
        "forest_spear":{"name":"Windsteel Spear", "slot":"weapon", "path":"warrior", "attack":24, "defense":0, "icon":"♜"},
        "job_spear":{"name":"Elowen's Spear", "slot":"weapon", "path":"warrior", "attack":30, "defense":0, "icon":"♜"},
        "starter_claw":{"name":"Moonlit Claw", "slot":"weapon", "path":"thief", "attack":18, "defense":0, "icon":"✦"},
        "thief_claw":{"name":"Elowen's Shadow Claw", "slot":"weapon", "path":"thief", "attack":25, "defense":0, "icon":"✦"},
        "forest_claw":{"name":"Nightwind Claw", "slot":"weapon", "path":"thief", "attack":30, "defense":0, "icon":"✦"},
        "starter_armor":{"name":"Trail Vest", "slot":"armor", "attack":0, "defense":2, "icon":"◆"},
        "forest_armor":{"name":"Mossguard Coat", "slot":"armor", "attack":0, "defense":5, "icon":"◆"}}
