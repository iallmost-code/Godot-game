extends RefCounted
# Scrolls, pets, character looks and quest items.
const GEAR_SLOTS=["weapon","hat","armor","gloves","shoes","cape","accessory"]
# Upgrade slots each piece of gear starts with.
const UPGRADE_SLOTS={"weapon":7,"hat":7,"armor":7,"gloves":5,"shoes":5,"cape":5,"accessory":5}
# Stat gains for 100% / 60% / 10% scrolls.
const SCROLL_STATS={
    "weapon":{"attack":[1,3,5]},
    "hat":{"defense":[1,2,5],"hp":[5,15,40]},
    "armor":{"defense":[2,4,8],"hp":[0,10,30]},
    "gloves":{"attack":[1,2,3]},
    "shoes":{"defense":[1,2,4],"DEX":[0,1,2]},
    "cape":{"defense":[1,2,4],"ALL":[0,1,2]},
    "accessory":{"ALL":[1,2,4]}}
const SCROLL_TIERS=[100,60,10]
const SLOT_WORDS={"weapon":"Weapon","hat":"Helm","armor":"Armor","gloves":"Glove","shoes":"Boot","cape":"Cloak","accessory":"Earring"}
static var _scrolls: Dictionary={}
static func scrolls() -> Dictionary:
    if not _scrolls.is_empty(): return _scrolls
    for slot in GEAR_SLOTS:
        for i in SCROLL_TIERS.size():
            var pct=SCROLL_TIERS[i]
            var gains={}
            for key in SCROLL_STATS[slot]:
                if SCROLL_STATS[slot][key][i]>0: gains[key]=SCROLL_STATS[slot][key][i]
            var words=[]
            for key in gains: words.append("+%d %s" % [gains[key],stat_word(key)])
            _scrolls["scroll_%s_%d" % [slot,pct]]={"name":"%s Scroll %d%%" % [SLOT_WORDS[slot],pct],"slot":slot,"chance":pct/100.0,"gains":gains,"tier":i,
                "text":"%d%% chance: %s. Uses an upgrade slot either way." % [pct,", ".join(words)],"value":[400,900,2500][i]}
    _scrolls["scroll_chaos"]={"name":"Chaos Scroll 60%","slot":"","chance":0.6,"gains":{},"tier":3,"value":6000,
        "text":"60% chance: every stat on the item shifts by -5 to +5. Uses an upgrade slot."}
    _scrolls["scroll_clean"]={"name":"Clean Slate Scroll 10%","slot":"","chance":0.1,"gains":{},"tier":3,"value":4000,
        "text":"10% chance to restore one upgrade slot lost to a failed scroll."}
    return _scrolls
static func stat_word(key: String) -> String:
    return {"attack":"ATK","defense":"DEF","hp":"HP","ALL":"All stats"}.get(key,key)
static func random_scroll() -> String:
    var roll=randf()
    if roll<0.03: return "scroll_chaos"
    if roll<0.06: return "scroll_clean"
    var tier=0 if roll<0.55 else 1 if roll<0.87 else 2
    return "scroll_%s_%d" % [GEAR_SLOTS.pick_random(),SCROLL_TIERS[tier]]

const PETS={
    "puppy":{"name":"Brown Pup","price":15000},
    "kitten":{"name":"Ginger Kitten","price":15000},
    "bunny":{"name":"Snow Bunny","price":15000},
    "penguin":{"name":"Tuxedo Penguin","price":40000},
    "slime":{"name":"Pet Jellop","price":40000},
    "baby_dragon":{"name":"Baby Drake","price":120000}}
const PET_LOOT_RADIUS=230.0

# "classic" keeps the class's original painted head.
const HAIR={"classic":"Classic","spiky":"Spiky","long":"Long","ponytail":"Ponytail","bowl":"Bowl Cut","messy":"Messy","braid":"Braid","mohawk":"Mohawk","bun":"Bun"}
const HAIR_COLORS=[Color("6b4428"),Color("1f1b1d"),Color("e8c766"),Color("b8452c"),Color("e9e7ef"),Color("5f8de0"),Color("e07fb5"),Color("62b56a")]
const HAIR_COLOR_NAMES=["Brown","Black","Blonde","Red","Silver","Blue","Pink","Green"]
const FACES={"default":"Default","determined":"Determined","sleepy":"Sleepy","angry":"Fierce","smiling":"Smiling","cool":"Cool"}
const SKINS=[Color("ffe2c8"),Color("f2c49b"),Color("c98f62"),Color("7d5236")]
const SKIN_NAMES=["Light","Warm","Tan","Deep"]
static func default_looks() -> Dictionary: return {"hair":"classic","hair_color":0,"face":"default","skin":0}
static func valid_looks(looks) -> bool:
    if not looks is Dictionary: return false
    if not HAIR.has(looks.get("hair","")) or not FACES.has(looks.get("face","")): return false
    for key in [["hair_color",HAIR_COLORS.size()],["skin",SKINS.size()]]:
        var v=looks.get(key[0],-1)
        if not (v is int or v is float) or v!=int(v) or v<0 or v>=key[1]: return false
    return true

# Quest drops, keyed by the monster family they come from.
const QUEST_ITEMS={
    "snail_shell":"Snail Shell","mushroom_cap":"Mushroom Cap","slime_goo":"Jellop Goo","stump_bark":"Stump Bark","boar_tusk":"Boar Tusk",
    "bat_wing":"Wraith Wisp","golem_rock":"Golem Rock","fairy_wing":"Spore Puff","ice_shard":"Ice Shard","fire_ore":"Cinder Ore",
    "gear_cog":"Clockwork Cog","bone_fragment":"Bone Fragment","scale":"Drake Scale","feather":"Feather","star_fragment":"Star Fragment",
    "cursed_doll":"Stitched Doll","ectoplasm":"Ectoplasm","lizard_tail":"Lizard Tail","crab_claw":"Snapper Claw","pig_ribbon":"Hog Ribbon"}
# Which quest item a monster carries, by a word in its id.
const ITEM_BY_WORD=[["snail","snail_shell"],["cap","mushroom_cap"],["spore","fairy_wing"],["jellop","slime_goo"],["stump","stump_bark"],["boar","boar_tusk"],["hog","pig_ribbon"],
    ["wraith","bat_wing"],["wisp","bat_wing"],["golem","golem_rock"],["cub","ice_shard"],["wolf","ice_shard"],["snowhorn","ice_shard"],["frost","ice_shard"],["cinder","fire_ore"],["magma","fire_ore"],
    ["tick","gear_cog"],["clock","gear_cog"],["timepiece","gear_cog"],["bone","bone_fragment"],["drake","scale"],["wyvern","scale"],["birk","feather"],["centaur","feather"],["ape","feather"],
    ["bruin","cursed_doll"],["inkling","ectoplasm"],["gloomfin","ectoplasm"],["shade","ectoplasm"],["lizard","lizard_tail"],["gator","lizard_tail"],["snapper","crab_claw"],["coral","crab_claw"],
    ["warden","star_fragment"],["monk","star_fragment"],["guardian","star_fragment"],["sentinel","star_fragment"],["moonfang","boar_tusk"]]
# Painted icon id for a scroll or quest item (ui_icon_layout uses earring / clean_slate).
static func icon_id(id: String) -> String:
    return id.replace("scroll_accessory_","scroll_earring_").replace("scroll_clean","scroll_clean_slate")
static func quest_item_for(monster: String) -> String:
    for pair in ITEM_BY_WORD:
        if monster.contains(pair[0]): return pair[1]
    return "star_fragment"
