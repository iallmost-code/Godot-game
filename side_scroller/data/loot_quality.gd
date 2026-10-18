extends RefCounted
const Catalog=preload("res://data/catalog.gd")
const RANKS={"common":0,"uncommon":1,"rare":2,"epic":3}
const COLORS={"common":Color("e5eaf0"),"uncommon":Color("65cf91"),"rare":Color("62b6ff"),"epic":Color("d78dff")}
const INK={"common":Color("354454"),"uncommon":Color("267048"),"rare":Color("245f9e"),"epic":Color("823ba7")}
const TROPHIES={"rootwarden":"Rootwarden's Oath","grand_shellmaw":"Shellmaw's Keepsake","elder_stumpus":"Heartwood Heirloom","gelatinous_monarch":"Monarch's Jewel","mother_cap":"Ambercap Treasure","blight_mother":"Blightbound Relic","lesser_hellwing":"Duskwing Fang","crimson_hellwing":"Crimson Covenant","chronovore":"Stolen Hour","abyssal_leviathan":"Deepwater Promise","molten_colossus":"Molten Testament","thornscale_wyrm":"Threefold Legacy","gloam_idol":"Gloamstar Wish"}
static func rarity(inst: Dictionary) -> String:return inst.get("rarity","common")
static func color(inst: Dictionary,ink=false) -> Color:return (INK if ink else COLORS).get(rarity(inst),Color.WHITE)
static func decorate(reward: Dictionary,level: int,boss="") -> Dictionary:
    var result=reward.duplicate(true)
    if not result.has("item"):return result
    var roll=randf()
    var progress=clampf(level/200.0,0,1)
    var kind="epic" if TROPHIES.has(boss) or roll<0.015+progress*0.035 else "rare" if roll<0.09+progress*0.08 else "uncommon" if roll<0.27+progress*0.12 else "common"
    result.rarity=kind
    if TROPHIES.has(boss):result.origin=boss
    var rank=RANKS[kind]
    result.affixes={}
    if rank>0:
        var item=Catalog.items()[result.item]
        var strength=rank*(1+int(level/30.0))
        if item.slot=="weapon":
            result.affixes.attack=maxi(1,int(item.attack*0.035*rank))+randi_range(0,rank)
            var stat={"staff":"INT","claw":"LUK","dagger":"LUK","bow":"DEX","crossbow":"DEX"}.get(item.get("weapon","sword"),"STR")
            result.affixes[stat]=strength
        else:
            result.affixes.defense=strength
            result.affixes.ALL=maxi(1,int(strength/2.0))
    return result
static func read(entry: Dictionary,inst: Dictionary) -> bool:
    if entry.has("rarity"):
        if not entry.rarity is String or not RANKS.has(entry.rarity):return false
        inst.rarity=entry.rarity
    if entry.has("locked"):
        if not entry.locked is bool:return false
        inst.locked=entry.locked
    if entry.has("origin"):
        if not entry.origin is String or not TROPHIES.has(entry.origin):return false
        inst.origin=entry.origin
    if entry.has("affixes"):
        if not entry.affixes is Dictionary:return false
        inst.affixes={}
        for key in entry.affixes:
            var value=entry.affixes[key]
            if not key in ["attack","defense","hp","mp","STR","DEX","INT","LUK","ALL"]:return false
            if not (value is int or value is float) or not is_finite(float(value)) or value!=int(value) or value<0 or value>200:return false
            inst.affixes[key]=int(value)
    return true
