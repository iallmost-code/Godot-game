extends RefCounted
const Catalog = preload("res://data/catalog.gd")
signal changed
signal leveled(level: int)
var level = 1
var xp = 0
var job = "beginner"
var archetype = "warrior"
var attributes = {"STR":4, "DEX":4, "INT":4, "LUK":4}
var ap = 0
var sp = {"1":0, "2":0, "3":0, "4":0}
var sp_earned = {"1":0, "2":0, "3":0, "4":0}
var skill_ranks = {"basic":1}
var slots = {"z":"", "x":"", "c":""}
var hp = 120.0
var mp = 40.0
var inventory: Array = ["starter_sword", "starter_armor"]
var equipment = {"weapon":"starter_sword", "armor":"starter_armor"}
var coins = 0
var potions = 5
var potion_cooldown = 0.0
func initialize_class(kind: String) -> bool:
    if not ["warrior","thief"].has(kind) or job!="beginner" or level!=1 or xp!=0: return false
    archetype=kind
    skill_ranks={basic_skill():1}
    var weapon="starter_claw" if kind=="thief" else "starter_sword"
    inventory=[weapon,"starter_armor"]
    equipment={"weapon":weapon,"armor":"starter_armor"}
    return true
func basic_skill() -> String: return "star" if archetype=="thief" else "basic"
func basic_star_count() -> int: return maxi(1,tier()) if archetype=="thief" else 0
func next_job() -> String:
    if job=="beginner": return archetype
    return {"warrior":"spearman","thief":"assassin","assassin":"hermit","hermit":"night_lord"}.get(job,"")
func skill_belongs(id: String) -> bool:
    return Catalog.skills().has(id) and Catalog.skills()[id].path==archetype
func skill_name(id: String) -> String:
    if id=="basic" and equipment.weapon.contains("spear"): return "Spear Combo"
    if id=="star": return "Star Throw ×%d" % basic_star_count()
    return Catalog.skills()[id].name
func xp_required(at_level: int) -> int: return 25 + 8 * at_level
func tier() -> int: return Catalog.jobs()[job].tier
func add_xp(amount: int):
    if amount <= 0 or level >= 100: return
    xp += amount
    while level < 100 and xp >= xp_required(level):
        xp -= xp_required(level)
        level += 1
        ap += 5
        if tier() > 0:
            sp[str(tier())] += 3
            sp_earned[str(tier())] += 3
        hp = derived_stats().max_hp
        mp = derived_stats().max_mp
        leveled.emit(level)
    if level >= 100: xp = 0
    changed.emit()
func derived_stats() -> Dictionary:
    var item_defs = Catalog.items()
    var weapon_attack = item_defs[equipment.weapon].attack
    var armor_defense = item_defs[equipment.armor].defense
    return {"max_hp":120 + 12 * (level-1) + 2 * (attributes.STR-4) + skill_ranks.get("vigor",0)*15,
        "max_mp":40 + 3 * (level-1) + 2 * (attributes.INT-4),
        "attack":weapon_attack + (attributes.LUK if archetype=="thief" else attributes.STR) + int(attributes.DEX/4.0) + (skill_ranks.get("precision",0) if archetype=="thief" else skill_ranks.get("strength",0))*3 + skill_ranks.get("mastery",0)*4,
        "defense":armor_defense + int(attributes.STR/10.0) + (skill_ranks.get("iron",0)+skill_ranks.get("shadow_guard",0))*2,
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
    if (next in ["warrior","thief"] and next==archetype and job == "beginner" and level >= 10):
        job = next
        sp["1"] += 1
        sp_earned["1"] += 1
        var starters=["star_fan"] if archetype=="thief" else ["sweep","thrust"]
        for id in starters: skill_ranks[id]=1
        slots.z="" if archetype=="thief" else starters[0]
        slots.x=starters[0] if archetype=="thief" else starters[1]
        var reward="thief_claw" if archetype=="thief" else "warrior_sword"
        if not inventory.has(reward): inventory.append(reward)
        if Catalog.items()[equipment.weapon].attack<Catalog.items()[reward].attack: equipment.weapon=reward
    elif next == "spearman" and job == "warrior" and level >= 30:
        job = next
        sp["2"] += 1
        sp_earned["2"] += 1
        if not inventory.has("job_spear"): inventory.append("job_spear")
        equipment.weapon="job_spear"
    elif archetype=="thief" and next==next_job() and next in ["assassin","hermit","night_lord"] and level>=Catalog.jobs()[next].level:
        job=next
        var pool=str(tier())
        sp[pool]+=1
        sp_earned[pool]+=1
        if next=="hermit":
            skill_ranks.shadow_partner=1
            if slots.c!="":
                for slot in ["z","x"]:
                    if slots[slot]=="":
                        slots[slot]=slots.c
                        break
            slots.c="shadow_partner"
    else: return false
    changed.emit()
    return true
func rank_up(id: String) -> bool:
    var defs = Catalog.skills()
    if not skill_belongs(id): return false
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
    return skill_belongs(id) and defs[id].active and defs[id].tier <= tier() and skill_ranks.get(id,0) > 0
func assign_skill(slot: String, id: String) -> bool:
    if not slots.has(slot) or not can_use(id) or id in ["basic","star"]: return false
    var previous=""
    for key in slots:
        if key!=slot and slots[key]==id: previous=key
    var displaced=slots[slot]
    slots[slot]=id
    if previous!="": slots[previous]=displaced
    changed.emit()
    return true
func add_item(id: String) -> bool:
    if not Catalog.items().has(id): return false
    if not inventory.has(id): inventory.append(id)
    changed.emit()
    return true
func equip(id: String) -> bool:
    if not inventory.has(id) or not Catalog.items().has(id): return false
    if Catalog.items()[id].get("path",archetype)!=archetype: return false
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
    return {"version":1,"level":level,"xp":xp,"job":job,"archetype":archetype,"attributes":attributes.duplicate(),"ap":ap,"sp":sp.duplicate(),"sp_earned":sp_earned.duplicate(),"skill_ranks":skill_ranks.duplicate(),"slots":slots.duplicate(),"inventory":inventory.duplicate(),"equipment":equipment.duplicate(),"coins":coins,"potions":potions}
func whole(value,minimum: int,maximum: int) -> bool:
    return (value is int or value is float) and is_finite(float(value)) and value==int(value) and value>=minimum and value<=maximum
func load_record(record: Dictionary) -> bool:
    if record.get("version",0)!=1 or not whole(record.get("level",0),1,100): return false
    var trial=get_script().new()
    var kind=record.get("archetype","warrior")
    if not kind is String or not trial.initialize_class(kind): return false
    trial.level=int(record.level)
    if not whole(record.get("xp",-1),0,trial.xp_required(trial.level)-1): return false
    trial.xp=int(record.xp)
    if not record.get("job",null) is String: return false
    trial.job=record.job
    if not ["beginner","warrior","spearman","thief","assassin","hermit","night_lord"].has(trial.job): return false
    if trial.job!="beginner" and ((trial.archetype=="thief")!=(trial.job in ["thief","assassin","hermit","night_lord"])): return false
    if trial.level<Catalog.jobs()[trial.job].level: return false
    if not record.get("attributes",null) is Dictionary or record.attributes.size()!=4: return false
    var allocated=0
    for key in attributes:
        if not whole(record.attributes.get(key,-1),4,499): return false
        trial.attributes[key]=int(record.attributes[key])
        allocated+=trial.attributes[key]-4
    if not whole(record.get("ap",-1),0,495) or allocated+record.ap!=5*(trial.level-1): return false
    trial.ap=int(record.ap)
    if not record.get("skill_ranks",null) is Dictionary: return false
    trial.skill_ranks.clear()
    var spent={"1":0,"2":0,"3":0,"4":0}
    var legacy_refund=0
    var retired_twin=false
    for id in record.skill_ranks:
        var defs=Catalog.skills()
        if id=="twin_stars" and trial.archetype=="thief" and trial.tier()>0:
            if not whole(record.skill_ranks[id],1,5): return false
            legacy_refund=int(record.skill_ranks[id])-1
            retired_twin=true
            continue
        if not trial.skill_belongs(id): return false
        var skill=defs[id]
        if not whole(record.skill_ranks[id],1,skill.max) or skill.tier>trial.tier(): return false
        var rank=int(record.skill_ranks[id])
        trial.skill_ranks[id]=rank
        if skill.tier>0: spent[str(skill.tier)]+=rank-(1 if id in ["sweep","thrust","star_fan","shadow_partner"] else 0)
    if trial.skill_ranks.get(trial.basic_skill(),0)!=1: return false
    var starters=["star_fan"] if trial.archetype=="thief" else ["sweep","thrust"]
    if trial.tier()>=1:
        for id in starters:
            if trial.skill_ranks.get(id,0)<1: return false
    if trial.archetype=="thief" and trial.tier()>=3 and trial.skill_ranks.get("shadow_partner",0)!=1: return false
    for id in trial.skill_ranks:
        var skill=Catalog.skills()[id]
        if skill.has("requires") and trial.skill_ranks.get(skill.requires,0)<1: return false
    if not record.get("sp",null) is Dictionary or not record.get("sp_earned",null) is Dictionary: return false
    for pool in ["1","2","3","4"]:
        var threshold={"1":10,"2":30,"3":60,"4":100}[pool]
        var maximum=1+3*(trial.level-threshold) if trial.tier()>=int(pool) else 0
        var available=record.sp.get(pool,0 if int(pool)>2 else -1)
        var earned=record.sp_earned.get(pool,0 if int(pool)>2 else -1)
        if not whole(available,0,maximum) or not whole(earned,0,maximum): return false
        if available+spent[pool]+(legacy_refund if pool=="1" else 0)!=earned: return false
        trial.sp[pool]=int(available)+(legacy_refund if pool=="1" else 0)
        trial.sp_earned[pool]=int(earned)
    var total_max=0 if trial.tier()==0 else trial.tier()+3*(trial.level-10)
    var total_earned=0
    for pool in ["1","2","3","4"]:
        var earned=trial.sp_earned[pool]
        total_earned+=earned
        if int(pool)<=trial.tier():
            if earned<1 or (earned-1)%3!=0: return false
        elif earned!=0: return false
    if total_earned>total_max: return false
    var defaults={"z":"sweep" if trial.archetype=="warrior" and trial.tier()>0 else "","x":("star_fan" if trial.archetype=="thief" else "thrust") if trial.tier()>0 else "","c":"shadow_partner" if trial.archetype=="thief" and trial.tier()>=3 else ""}
    var slot_record=record.get("slots",defaults)
    if not slot_record is Dictionary: return false
    var assigned: Array=[]
    for slot in ["z","x","c"]:
        var id=slot_record.get(slot,"")
        if id=="twin_stars":
            if not retired_twin: return false
            id=""
        if not id is String or id!="" and (not trial.can_use(id) or id in ["basic","star"] or assigned.has(id)): return false
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
        if Catalog.items()[id].get("path",trial.archetype)!=trial.archetype: return false
        trial.equipment[slot]=id
    if not whole(record.get("coins",0),0,1000000) or not whole(record.get("potions",5),0,10000): return false
    trial.coins=int(record.get("coins",0))
    trial.potions=int(record.get("potions",5))
    for key in ["level","xp","job","archetype","attributes","ap","sp","sp_earned","skill_ranks","slots","inventory","equipment","coins","potions"]:
        set(key,trial.get(key))
    hp=derived_stats().max_hp
    mp=derived_stats().max_mp
    changed.emit()
    return true
