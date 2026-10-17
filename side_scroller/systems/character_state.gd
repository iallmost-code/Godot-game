extends RefCounted
const Catalog = preload("res://data/catalog.gd")
const VERSION=2
const POOLS=["0","1","2","3","4"]
const BEGINNER_SP=9
const MAIN_STAT={"warrior":"STR","magician":"INT","bowman":"DEX","thief":"LUK"}
const SECONDARY_STAT={"warrior":"DEX","magician":"LUK","bowman":"STR","thief":"DEX"}
const GROWTH={"warrior":[16,3],"magician":[8,14],"bowman":[12,6],"thief":[12,6]}
const STARTER={"warrior":"starter_sword","magician":"starter_staff","bowman":"starter_bow","thief":"starter_claw"}
signal changed
signal leveled(level: int)
var level = 1
var xp = 0
var job = "beginner"
var archetype = "warrior"
var attributes = {"STR":4, "DEX":4, "INT":4, "LUK":4}
var ap = 0
var sp = {"0":0, "1":0, "2":0, "3":0, "4":0}
var sp_earned = {"0":0, "1":0, "2":0, "3":0, "4":0}
var skill_ranks = {}
var slots = {}
var hp = 120.0
var mp = 40.0
var inventory: Array = ["starter_sword", "starter_armor"]
var equipment = {"weapon":"starter_sword", "armor":"starter_armor"}
var coins = 0
var potions = 5
var potion_cooldown = 0.0
# Runtime only: active buffs {id: {"time": seconds, "rank": n}}.
var buffs = {}
var migration_note = ""
func _init():
    for slot in Catalog.SLOTS: slots[slot]=""
func initialize_class(kind: String) -> bool:
    if not Catalog.ARCHETYPES.has(kind) or job!="beginner" or level!=1 or xp!=0: return false
    archetype=kind
    skill_ranks={}
    inventory=[STARTER[kind],"starter_armor"]
    equipment={"weapon":STARTER[kind],"armor":"starter_armor"}
    hp=derived_stats().max_hp
    mp=derived_stats().max_mp
    return true
static func archetype_name(kind: String) -> String:
    return {"warrior":"Warrior","magician":"Mage","bowman":"Archer","thief":"Thief"}.get(kind,kind.capitalize())
func job_name(id: String = "") -> String: return Catalog.jobs()[job if id=="" else id].name
func lineage() -> Array:
    var chain=[]
    var current=job
    while current!="":
        chain.append(current)
        current=Catalog.jobs()[current].parent
    return chain
func tier() -> int: return Catalog.jobs()[job].tier
func next_jobs() -> Array:
    var result=[]
    for id in Catalog.jobs():
        var entry=Catalog.jobs()[id]
        if entry.parent==job and entry.path==archetype: result.append(id)
    return result
func next_job() -> String:
    var options=next_jobs()
    return options[0] if not options.is_empty() else ""
func weapon_type() -> String: return Catalog.items()[equipment.weapon].get("weapon","sword")
func preferred_weapon() -> String:
    for id in lineage():
        if Catalog.jobs()[id].has("weapon"): return Catalog.jobs()[id].weapon
    return Catalog.items()[STARTER[archetype]].weapon
func basic_skill() -> String:
    var type=weapon_type()
    if type=="claw": return "star"
    if type in ["bow","crossbow"]: return "arrow"
    return "basic"
func basic_star_count() -> int: return 1 if basic_skill()=="star" else 0
func skill_pool(id: String) -> String:
    var skill=Catalog.skill(id)
    if skill.is_empty() or skill.job=="": return ""
    return str(Catalog.jobs()[skill.job].tier)
func skill_belongs(id: String) -> bool:
    var skill=Catalog.skill(id)
    if skill.is_empty(): return false
    if skill.job=="" or skill.job=="beginner": return true
    return Catalog.jobs()[skill.job].path==archetype
func in_lineage(id: String) -> bool:
    var skill=Catalog.skill(id)
    if skill.is_empty(): return false
    return skill.job=="" or lineage().has(skill.job)
func skill_rank(id: String) -> int:
    if Catalog.skill(id).get("job","x")=="": return 1
    return skill_ranks.get(id,0)
func skill_name(id: String) -> String:
    if id=="basic":
        return {"spear":"Spear Combo","dagger":"Dagger Slash","staff":"Staff Strike"}.get(weapon_type(),"Sword Combo")
    if id=="arrow" and weapon_type()=="crossbow": return "Fire Bolt"
    return Catalog.skill(id).get("name",id)
func xp_required(at_level: int) -> int:
    return int(15+10*at_level+1.1*at_level*at_level+0.004*at_level*at_level*at_level)
func add_xp(amount: int):
    if amount <= 0 or level >= Catalog.MAX_LEVEL: return
    xp += amount
    while level < Catalog.MAX_LEVEL and xp >= xp_required(level):
        xp -= xp_required(level)
        level += 1
        ap += 5
        var pool=str(tier())
        var gain=3 if tier()>0 else (1 if sp_earned["0"]<BEGINNER_SP else 0)
        sp[pool]+=gain
        sp_earned[pool]+=gain
        hp = derived_stats().max_hp
        mp = derived_stats().max_mp
        leveled.emit(level)
    if level >= Catalog.MAX_LEVEL: xp = 0
    changed.emit()
# Sum of a stat from learned passives and active buffs.
func bonus(key: String) -> float:
    var total=0.0
    for id in skill_ranks:
        var skill=Catalog.skill(id)
        if skill.is_empty(): continue
        if skill.kind=="passive" and skill.has("stats") and skill.stats.has(key) and lineage().has(skill.job):
            total+=Catalog.value(skill.stats[key],skill_ranks[id],skill.max)
    for id in buffs:
        var skill=Catalog.skill(id)
        if skill.has("stats") and skill.stats.has(key):
            total+=Catalog.value(skill.stats[key],buffs[id].rank,skill.max)
    return total
func has_buff(id: String) -> bool: return buffs.has(id)
func buff_group(group: String) -> String:
    for id in buffs:
        if Catalog.skill(id).get("group","")==group: return id
    return ""
func on_hit_effects() -> Array:
    var result=[]
    for id in skill_ranks:
        var skill=Catalog.skill(id)
        if skill.is_empty(): continue
        if skill.kind=="passive" and skill.has("on_hit") and lineage().has(skill.job):
            result.append({"id":skill.on_hit.id,"chance":Catalog.value(skill.on_hit.chance,skill_ranks[id],skill.max),"time":Catalog.value(skill.on_hit.time,skill_ranks[id],skill.max)})
    for id in buffs:
        var skill=Catalog.skill(id)
        if skill.has("on_hit"):
            result.append({"id":skill.on_hit.id,"chance":Catalog.value(skill.on_hit.chance,buffs[id].rank,skill.max),"time":Catalog.value(skill.on_hit.time,buffs[id].rank,skill.max)})
    return result
func effective_attributes() -> Dictionary:
    var factor=1.0+bonus("stat_pct")
    var result={}
    for key in attributes: result[key]=int(attributes[key]*factor)
    return result
func derived_stats() -> Dictionary:
    var item_defs = Catalog.items()
    var weapon_attack = item_defs[equipment.weapon].attack
    var armor_defense = item_defs[equipment.armor].defense
    var a=effective_attributes()
    var growth=GROWTH[archetype]
    var max_hp=(120+growth[0]*(level-1)+2*(a.STR-4)+bonus("max_hp"))*(1.0+bonus("max_hp_pct"))
    var max_mp=(40+growth[1]*(level-1)+2*(a.INT-4)+bonus("max_mp"))*(1.0+bonus("max_mp_pct"))
    return {"max_hp":int(max_hp),"max_mp":int(max_mp),
        "attack":int(weapon_attack+a[MAIN_STAT[archetype]]+int(a[SECONDARY_STAT[archetype]]/4.0)+bonus("attack")),
        "defense":int(armor_defense+int(a.STR/10.0)+bonus("defense")),
        "crit":minf(0.75,0.05+0.002*(a.LUK-4)+bonus("crit")),
        "crit_damage":0.5+bonus("crit_damage"),
        "avoid":minf(0.6,bonus("avoid")),
        "mastery_min":clampf(0.78+bonus("mastery"),0.78,0.97),
        "attack_speed":minf(0.4,bonus("attack_speed")),
        "speed":bonus("speed"),"jump":bonus("jump"),
        "damage_pct":bonus("damage_pct"),
        "damage_reduction":minf(0.8,bonus("damage_reduction")),
        "reach":bonus("reach")}
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
    if not next_jobs().has(next) or level<Catalog.jobs()[next].level: return false
    job=next
    var pool=str(tier())
    sp[pool]+=1
    sp_earned[pool]+=1
    var reward=Catalog.jobs()[next].reward
    if Catalog.items().has(reward):
        if not inventory.has(reward): inventory.append(reward)
        var current=Catalog.items()[equipment.weapon]
        var offered=Catalog.items()[reward]
        if current.attack<offered.attack: equipment.weapon=reward
    changed.emit()
    return true
func rank_up(id: String) -> bool:
    var skill=Catalog.skill(id)
    if skill.is_empty() or skill.job=="" or not in_lineage(id): return false
    var pool=skill_pool(id)
    if sp.get(pool,0) <= 0 or skill_ranks.get(id,0) >= skill.max: return false
    if skill.has("requires") and skill_ranks.get(skill.requires,0) < 1: return false
    sp[pool] -= 1
    skill_ranks[id] = skill_ranks.get(id,0) + 1
    changed.emit()
    return true
func can_use(id: String) -> bool:
    var skill=Catalog.skill(id)
    if skill.is_empty() or not skill.active: return false
    if skill.job=="": return id==basic_skill()
    return in_lineage(id) and skill_ranks.get(id,0) > 0
func assign_skill(slot: String, id: String) -> bool:
    if not slots.has(slot) or not can_use(id) or Catalog.skill(id).job=="": return false
    var previous=""
    for key in slots:
        if key!=slot and slots[key]==id: previous=key
    var displaced=slots[slot]
    slots[slot]=id
    if previous!="": slots[previous]=displaced
    changed.emit()
    return true
func clear_slot(slot: String):
    if slots.has(slot):
        slots[slot]=""
        changed.emit()
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
    coins = mini(1000000, coins+int(reward.get("coins",0)))
    potions = mini(10000, potions+int(reward.get("potions",0)))
    changed.emit()
    return true
func use_potion() -> bool:
    if potions <= 0 or potion_cooldown > 0 or hp >= derived_stats().max_hp: return false
    potions -= 1
    var amount=(40+4*maxi(0,level-10))*(1.0+bonus("heal_pct"))
    hp = minf(derived_stats().max_hp, hp + amount)
    potion_cooldown = 3
    changed.emit()
    return true
func restore():
    hp = derived_stats().max_hp
    mp = derived_stats().max_mp
    changed.emit()
func regenerate(delta: float, safe_zone: bool):
    var stats=derived_stats()
    mp=minf(stats.max_mp,mp+(2.5+0.006*stats.max_mp+bonus("mp_regen"))*delta)
    var heal=bonus("hp_regen")+(12.0+0.02*stats.max_hp if safe_zone else 0.0)
    if heal>0 and hp>0: hp=minf(stats.max_hp,hp+heal*delta)
    var drain=bonus("hp_drain")
    if drain>0 and hp>1: hp=maxf(1,hp-drain*delta)
func apply_buff(id: String, duration: float):
    var skill=Catalog.skill(id)
    var group=skill.get("group","")
    if group!="":
        for other in buffs.keys():
            if other!=id and Catalog.skill(other).get("group","")==group: buffs.erase(other)
    buffs[id]={"time":duration,"rank":maxi(1,skill_rank(id))}
    var stats=derived_stats()
    hp=minf(hp,stats.max_hp)
    mp=minf(mp,stats.max_mp)
    changed.emit()
func remove_buff(id: String):
    if buffs.erase(id):
        var stats=derived_stats()
        hp=minf(hp,stats.max_hp)
        mp=minf(mp,stats.max_mp)
        changed.emit()
func tick_buffs(delta: float) -> Array:
    var expired=[]
    for id in buffs.keys():
        buffs[id].time-=delta
        if buffs[id].time<=0 or not can_use(id): expired.append(id)
    for id in expired: remove_buff(id)
    return expired
func clear_buffs():
    buffs.clear()
    changed.emit()
func to_record() -> Dictionary:
    return {"version":VERSION,"level":level,"xp":xp,"job":job,"archetype":archetype,"attributes":attributes.duplicate(),"ap":ap,"sp":sp.duplicate(),"sp_earned":sp_earned.duplicate(),"skill_ranks":skill_ranks.duplicate(),"slots":slots.duplicate(),"inventory":inventory.duplicate(),"equipment":equipment.duplicate(),"coins":coins,"potions":potions}
func whole(value,minimum: int,maximum: int) -> bool:
    return (value is int or value is float) and is_finite(float(value)) and value==int(value) and value>=minimum and value<=maximum
# Largest SP a pool could have earned at this level and job.
func pool_limit(pool: String) -> int:
    if pool=="0": return mini(BEGINNER_SP,maxi(0,mini(level,Catalog.jobs()[Catalog.first_job(archetype)].level)-1)) if tier()>0 else mini(BEGINNER_SP,level-1)
    var t=int(pool)
    if t>tier(): return 0
    var start=10
    for id in lineage():
        if Catalog.jobs()[id].tier==t: start=Catalog.jobs()[id].level
    return 1+3*maxi(0,level-start)
# Points a pool holds when every advancement was taken on time.
func natural_pool(pool: String) -> int:
    if pool=="0": return pool_limit("0")
    var t=int(pool)
    if t>tier(): return 0
    var start=0
    var finish=level
    for id in lineage():
        var info=Catalog.jobs()[id]
        if info.tier==t: start=info.level
        if info.tier==t+1: finish=info.level
    return 1+3*maxi(0,finish-start)
# Version 1 saves predate the full job tree: jobs above the new thresholds step back,
# retired skills are dropped and every skill point is refunded.
func migrate_v1(record: Dictionary) -> Dictionary:
    var kind=record.get("archetype","warrior")
    if not kind is String or not kind in ["warrior","thief"]: return {}
    var lv=record.get("level",0)
    if not whole(lv,1,100): return {}
    lv=int(lv)
    var old_job=record.get("job","")
    if not old_job is String: return {}
    var map={"beginner":"beginner","warrior":"warrior","spearman":"spearman","thief":"thief","assassin":"assassin","hermit":"hermit","night_lord":"night_lord"}
    if not map.has(old_job): return {}
    var new_job=map[old_job]
    if new_job=="night_lord" and lv<120: new_job="hermit"
    if new_job=="hermit" and lv<70: new_job="assassin"
    var probe=get_script().new()
    if not probe.initialize_class(kind): return {}
    probe.level=lv
    probe.job=new_job
    if new_job!="beginner" and Catalog.jobs()[new_job].path!=kind: return {}
    var earned={}
    for pool in POOLS: earned[pool]=probe.natural_pool(pool)
    var converted=record.duplicate(true)
    converted.version=VERSION
    converted.archetype=kind
    converted.job=new_job
    converted.skill_ranks={}
    converted.sp=earned.duplicate()
    converted.sp_earned=earned.duplicate()
    var empty={}
    for slot in Catalog.SLOTS: empty[slot]=""
    converted.slots=empty
    converted["migrated"]=true
    return converted
func load_record(record: Dictionary) -> bool:
    var migrated=false
    if record.get("version",0)==1:
        record=migrate_v1(record)
        if record.is_empty(): return false
        migrated=true
    if record.get("version",0)!=VERSION or not whole(record.get("level",0),1,Catalog.MAX_LEVEL): return false
    var trial=get_script().new()
    var kind=record.get("archetype","warrior")
    if not kind is String or not trial.initialize_class(kind): return false
    trial.level=int(record.level)
    if not whole(record.get("xp",-1),0,trial.xp_required(trial.level)-1): return false
    trial.xp=int(record.xp)
    if not record.get("job",null) is String or not Catalog.jobs().has(record.job): return false
    trial.job=record.job
    var job_info=Catalog.jobs()[trial.job]
    if trial.job!="beginner" and job_info.path!=trial.archetype: return false
    if trial.level<job_info.level: return false
    if not record.get("attributes",null) is Dictionary or record.attributes.size()!=4: return false
    var allocated=0
    for key in attributes:
        if not whole(record.attributes.get(key,-1),4,999): return false
        trial.attributes[key]=int(record.attributes[key])
        allocated+=trial.attributes[key]-4
    if not whole(record.get("ap",-1),0,995) or allocated+record.ap!=5*(trial.level-1): return false
    trial.ap=int(record.ap)
    if not record.get("skill_ranks",null) is Dictionary: return false
    var spent={"0":0,"1":0,"2":0,"3":0,"4":0}
    for id in record.skill_ranks:
        var skill=Catalog.skill(str(id))
        if skill.is_empty() or skill.job=="" or not trial.in_lineage(id): return false
        if not whole(record.skill_ranks[id],1,skill.max): return false
        trial.skill_ranks[id]=int(record.skill_ranks[id])
        spent[trial.skill_pool(id)]+=trial.skill_ranks[id]
    for id in trial.skill_ranks:
        var skill=Catalog.skill(id)
        if skill.has("requires") and trial.skill_ranks.get(skill.requires,0)<1: return false
    if not record.get("sp",null) is Dictionary or not record.get("sp_earned",null) is Dictionary: return false
    for pool in POOLS:
        var available=record.sp.get(pool,-1)
        var earned=record.sp_earned.get(pool,-1)
        var limit=trial.pool_limit(pool)
        if not whole(available,0,limit) or not whole(earned,0,limit): return false
        if available+spent[pool]!=earned: return false
        if pool!="0" and int(pool)<=trial.tier() and (earned<1 or (int(earned)-1)%3!=0): return false
        trial.sp[pool]=int(available)
        trial.sp_earned[pool]=int(earned)
    # Each level after the first job yields 3 points to exactly one pool.
    var tier_total=0
    for pool in ["1","2","3","4"]: tier_total+=trial.sp_earned[pool]
    if trial.tier()>0 and tier_total>trial.tier()+3*(trial.level-Catalog.jobs()[Catalog.first_job(trial.archetype)].level): return false
    var slot_record=record.get("slots",{})
    if not slot_record is Dictionary: return false
    var assigned: Array=[]
    for slot in Catalog.SLOTS:
        var id=slot_record.get(slot,"")
        if not id is String or id!="" and (not trial.can_use(id) or Catalog.skill(id).job=="" or assigned.has(id)): return false
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
    buffs.clear()
    migration_note="Your character was updated to the full job tree. All skill points were refunded; open Skills to spend them." if migrated else ""
    hp=derived_stats().max_hp
    mp=derived_stats().max_mp
    changed.emit()
    return true
