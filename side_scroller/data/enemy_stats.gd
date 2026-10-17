extends RefCounted
static func profile(id: String) -> Dictionary:
    return {
        "mossling":{"name":"Mossling","level":3,"base_attack":4},
        "lantern":{"name":"Lantern Bloom","level":6,"base_attack":5},
        "thornling":{"name":"Thornling","level":18,"base_attack":8},
        "briar_lantern":{"name":"Briar Lantern","level":22,"base_attack":9},
        "rootwarden":{"name":"Rootwarden","level":25,"base_attack":10}
    }.get(id,{"name":"Monster","level":1,"base_attack":4})
static func damage(id: String,level: int,multiplier=1.0) -> int:
    var base=profile(id).base_attack
    return maxi(1,int((base+2*(clampi(level,1,100)-1))*multiplier))
