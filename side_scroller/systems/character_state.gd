extends RefCounted
const Catalog = preload("res://data/catalog.gd")
signal changed
signal leveled(level: int)
var level = 1
var xp = 0
var job = "beginner"
var attributes = {"STR":4, "DEX":4, "INT":4, "LUK":4}
var ap = 0
var sp = {"1":0, "2":0}
var sp_earned = {"1":0, "2":0}
var skill_ranks = {"basic":1}
var slots = {"z":"", "x":"", "c":""}
var hp = 120.0
var mp = 40.0
var inventory: Array = ["starter_spear", "starter_armor"]
var equipment = {"weapon":"starter_spear", "armor":"starter_armor"}
var coins = 0
var potions = 5
var potion_cooldown = 0.0
func xp_required(at_level: int) -> int: return 25 + 8 * at_level
func tier() -> int: return Catalog.jobs()[job].tier
func add_xp(amount: int):
    if amount <= 0 or level >= 40: return
    xp += amount
    while level < 40 and xp >= xp_required(level):
        xp -= xp_required(level)
        level += 1
        ap += 5
        if tier() > 0:
            sp[str(tier())] += 3
            sp_earned[str(tier())] += 3
        hp = derived_stats().max_hp
        mp = derived_stats().max_mp
        leveled.emit(level)
    if level >= 40: xp = 0
    changed.emit()
func derived_stats() -> Dictionary:
    var item_defs = Catalog.items()
    var weapon_attack = item_defs[equipment.weapon].attack
    var armor_defense = item_defs[equipment.armor].defense
    return {"max_hp":120 + 12 * (level-1) + 2 * (attributes.STR-4) + skill_ranks.get("vigor",0)*15,
        "max_mp":40 + 3 * (level-1) + 2 * (attributes.INT-4),
        "attack":weapon_attack + attributes.STR + int(attributes.DEX/4.0) + skill_ranks.get("strength",0)*3 + skill_ranks.get("mastery",0)*4,
        "defense":armor_defense + int(attributes.STR/10.0) + skill_ranks.get("iron",0)*2,
        "crit":minf(0.25, 0.05 + 0.002 * (attributes.LUK-4))}
func allocate_attributes(delta: Dictionary) -> bool:
    var total = 0
    for key in delta:
        if not attributes.has(key) or not delta[key] is int or delta[key] < 0: return false
        total += delta[key]
    if total <= 0 or total > ap: return false
    for key in delta: attributes[key] += delta[key]
    ap -= total
    changed.emit()
    return true
func advance_job(next: String) -> bool:
    if (next == "warrior" and job == "beginner" and level >= 10):
        job = next
        sp["1"] += 1
        sp_earned["1"] += 1
        skill_ranks.sweep = 1
        skill_ranks.thrust = 1
        slots.z = "sweep"
        slots.x = "thrust"
    elif next == "spearman" and job == "warrior" and level >= 30:
        job = next
        sp["2"] += 1
        sp_earned["2"] += 1
    else: return false
    changed.emit()
    return true
func rank_up(id: String) -> bool:
    var defs = Catalog.skills()
    if not defs.has(id): return false
    var skill = defs[id]
    var pool = str(skill.tier)
    if skill.tier < 1 or skill.tier > tier() or sp.get(pool,0) <= 0: return false
    if skill_ranks.get(id,0) >= skill.max: return false
    if skill.has("requires") and skill_ranks.get(skill.requires,0) < 1: return false
    sp[pool] -= 1
    skill_ranks[id] = skill_ranks.get(id,0) + 1
    changed.emit()
    return true
func can_use(id: String) -> bool:
    var defs = Catalog.skills()
    return defs.has(id) and defs[id].active and defs[id].tier <= tier() and skill_ranks.get(id,0) > 0
func assign_skill(slot: String, id: String) -> bool:
    if not slots.has(slot) or not can_use(id) or id == "basic": return false
    for key in slots:
        if key != slot and slots[key] == id: return false
    slots[slot] = id
    changed.emit()
    return true
func add_item(id: String) -> bool:
    if not Catalog.items().has(id): return false
    if not inventory.has(id): inventory.append(id)
    changed.emit()
    return true
func equip(id: String) -> bool:
    if not inventory.has(id) or not Catalog.items().has(id): return false
    equipment[Catalog.items()[id].slot] = id
    changed.emit()
    return true
func collect_reward(reward: Dictionary) -> bool:
    if reward.has("item") and not Catalog.items().has(reward.item): return false
    if int(reward.get("coins",0)) < 0 or int(reward.get("potions",0)) < 0: return false
    if reward.has("item"): add_item(reward.item)
    coins += int(reward.get("coins",0))
    potions += int(reward.get("potions",0))
    changed.emit()
    return true
func use_potion() -> bool:
    if potions <= 0 or potion_cooldown > 0 or hp >= derived_stats().max_hp: return false
    potions -= 1
    hp = minf(derived_stats().max_hp, hp + 40)
    potion_cooldown = 3
    changed.emit()
    return true
func restore():
    hp = derived_stats().max_hp
    mp = derived_stats().max_mp
    changed.emit()
func to_record() -> Dictionary:
    return {"version":1,"level":level,"xp":xp,"job":job,"attributes":attributes.duplicate(),"ap":ap,"sp":sp.duplicate(),"sp_earned":sp_earned.duplicate(),"skill_ranks":skill_ranks.duplicate(),"slots":slots.duplicate(),"inventory":inventory.duplicate(),"equipment":equipment.duplicate(),"coins":coins,"potions":potions}
func whole(value,minimum: int,maximum: int) -> bool:
    return (value is int or value is float) and is_finite(float(value)) and value==int(value) and value>=minimum and value<=maximum
func load_record(record: Dictionary) -> bool:
    if record.get("version",0)!=1 or not whole(record.get("level",0),1,40): return false
    var trial=get_script().new()
    trial.level=int(record.level)
    if not whole(record.get("xp",-1),0,trial.xp_required(trial.level)-1): return false
    trial.xp=int(record.xp)
    if not record.get("job",null) is String: return false
    trial.job=record.job
    if not ["beginner","warrior","spearman"].has(trial.job): return false
    if trial.level<Catalog.jobs()[trial.job].level: return false
    if not record.get("attributes",null) is Dictionary or record.attributes.size()!=4: return false
    var allocated=0
    for key in attributes:
        if not whole(record.attributes.get(key,-1),4,199): return false
        trial.attributes[key]=int(record.attributes[key])
        allocated+=trial.attributes[key]-4
    if not whole(record.get("ap",-1),0,195) or allocated+record.ap!=5*(trial.level-1): return false
    trial.ap=int(record.ap)
    if not record.get("skill_ranks",null) is Dictionary: return false
    trial.skill_ranks.clear()
    var spent={"1":0,"2":0}
    for id in record.skill_ranks:
        var defs=Catalog.skills()
        if not defs.has(id): return false
        var skill=defs[id]
        if not whole(record.skill_ranks[id],1,skill.max) or skill.tier>trial.tier(): return false
        var rank=int(record.skill_ranks[id])
        trial.skill_ranks[id]=rank
        if skill.tier>0: spent[str(skill.tier)]+=rank-(1 if id in ["sweep","thrust"] else 0)
    if trial.skill_ranks.get("basic",0)!=1: return false
    if trial.tier()>=1 and (trial.skill_ranks.get("sweep",0)<1 or trial.skill_ranks.get("thrust",0)<1): return false
    for id in trial.skill_ranks:
        var skill=Catalog.skills()[id]
        if skill.has("requires") and trial.skill_ranks.get(skill.requires,0)<1: return false
    if not record.get("sp",null) is Dictionary or not record.get("sp_earned",null) is Dictionary: return false
    for pool in ["1","2"]:
        var maximum=0
        if pool=="1" and trial.tier()>=1: maximum=1+3*(trial.level-10)
        if pool=="2" and trial.tier()>=2: maximum=1+3*(trial.level-30)
        if not whole(record.sp.get(pool,-1),0,maximum) or not whole(record.sp_earned.get(pool,-1),0,maximum): return false
        if record.sp[pool]+spent[pool]!=record.sp_earned[pool]: return false
        trial.sp[pool]=int(record.sp[pool])
        trial.sp_earned[pool]=int(record.sp_earned[pool])
    var slot_record=record.get("slots",{"z":"sweep" if trial.tier()>0 else "","x":"thrust" if trial.tier()>0 else "","c":""})
    if not slot_record is Dictionary: return false
    var assigned: Array=[]
    for slot in ["z","x","c"]:
        var id=slot_record.get(slot,"")
        if not id is String or id!="" and (not trial.can_use(id) or id=="basic" or assigned.has(id)): return false
        trial.slots[slot]=id
        if id!="": assigned.append(id)
    if not record.get("inventory",null) is Array or record.inventory.size()>100: return false
    trial.inventory.clear()
    for id in record.inventory:
        if not id is String or not Catalog.items().has(id) or trial.inventory.has(id): return false
        trial.inventory.append(id)
    if not record.get("equipment",null) is Dictionary: return false
    for slot in ["weapon","armor"]:
        var id=record.equipment.get(slot,"")
        if not id is String or not trial.inventory.has(id) or Catalog.items()[id].slot!=slot: return false
        trial.equipment[slot]=id
    if not whole(record.get("coins",0),0,1000000) or not whole(record.get("potions",5),0,10000): return false
    trial.coins=int(record.get("coins",0))
    trial.potions=int(record.get("potions",5))
    for key in ["level","xp","job","attributes","ap","sp","sp_earned","skill_ranks","slots","inventory","equipment","coins","potions"]:
        set(key,trial.get(key))
    hp=derived_stats().max_hp
    mp=derived_stats().max_mp
    changed.emit()
    return true
