extends RefCounted
const Catalog = preload("res://data/catalog.gd")
const Adventure = preload("res://data/adventure.gd")
const Quality=preload("res://data/loot_quality.gd")
const VERSION=3
const INVENTORY_LIMIT=128
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
# Equipment instances {"uid", "id", "plus"}; duplicates allowed.
var inventory: Array = []
# Worn instance per gear slot (uid) and a matching slot -> item id view for visuals.
var equipped = {}
var equipment = {}
var next_uid = 1
var coins = 0
var shards = 0
var consumables = {"hp_1":5}
# Basic red tonics; kept as a property for older code and saves.
var potions: int:
    get: return int(consumables.get("hp_1",0))
    set(value): consumables["hp_1"]=value
# Last safe town visited; loading a save starts here.
var town = "town"
# Quest progress {id: {"status": "active"/"done", "count": n}} and quest drops {item: n}.
var quests = {}
var quest_items = {}
# Upgrade scrolls {scroll id: n}.
var scrolls = {}
var looks = Adventure.default_looks()
var pets: Array = []
var pet = ""
var potion_cooldown = 0.0
var mana_potion_cooldown = 0.0
# Runtime only: active buffs {id: {"time": seconds, "rank": n}}.
var buffs = {}
var migration_note = ""
func _init():
    for slot in Catalog.SLOTS: slots[slot]=""
    # A fresh character is a warrior novice until initialize_class picks a class.
    equip(add_item_uid(STARTER.warrior))
    equip(add_item_uid("starter_armor"))
func initialize_class(kind: String) -> bool:
    if not Catalog.ARCHETYPES.has(kind) or job!="beginner" or level!=1 or xp!=0: return false
    archetype=kind
    skill_ranks={}
    inventory=[]
    equipped={}
    equipment={}
    next_uid=1
    equip(add_item_uid(STARTER[kind]))
    equip(add_item_uid("starter_armor"))
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
func weapon_type() -> String: return Catalog.items()[equipment.get("weapon","starter_sword")].get("weapon","sword")
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
# Early levels are quick; from level 120 each level takes four times the base curve.
func xp_required(at_level: int) -> int:
    var base=15+10*at_level+1.1*at_level*at_level+0.004*at_level*at_level*at_level
    return int(base*(1.0+minf(3.0,at_level/40.0)))
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
# Totals from every worn item: attack, defense and stat bonuses.
func gear_totals() -> Dictionary:
    var total={"attack":0,"defense":0,"STR":0,"DEX":0,"INT":0,"LUK":0,"hp":0,"mp":0}
    for slot in equipped:
        var inst=instance(equipped[slot])
        if inst.is_empty(): continue
        var item=Catalog.items()[inst.id]
        total.attack+=item_attack(inst)
        total.defense+=item_defense(inst)
        for key in item.stats:
            if key=="ALL":
                for stat in ["STR","DEX","INT","LUK"]: total[stat]+=item.stats.ALL
            else: total[key]+=item.stats[key]
        if item.slot!="weapon": total.hp+=inst.plus*(5+int(item.req/4.0))
        var bonus=inst.get("bonus",{}).duplicate()
        for key in inst.get("affixes",{}): bonus[key]=bonus.get(key,0)+inst.affixes[key]
        for key in bonus:
            if key=="ALL":
                for stat in ["STR","DEX","INT","LUK"]: total[stat]+=bonus.ALL
            elif key in ["hp","mp","STR","DEX","INT","LUK"]: total[key]+=bonus[key]
    for key in ["hp","mp"]: total[key]=maxi(0,total[key])
    return total
func effective_attributes() -> Dictionary:
    var factor=1.0+bonus("stat_pct")
    var gear=gear_totals()
    var result={}
    for key in attributes: result[key]=int((attributes[key]+gear[key])*factor)
    return result
func derived_stats() -> Dictionary:
    var gear=gear_totals()
    var a=effective_attributes()
    var growth=GROWTH[archetype]
    var max_hp=(120+growth[0]*(level-1)+2*(a.STR-4)+bonus("max_hp")+gear.hp)*(1.0+bonus("max_hp_pct"))
    var max_mp=(40+growth[1]*(level-1)+2*(a.INT-4)+bonus("max_mp")+gear.mp)*(1.0+bonus("max_mp_pct"))
    return {"max_hp":int(max_hp),"max_mp":int(max_mp),
        "attack":int(gear.attack+a[MAIN_STAT[archetype]]+int(a[SECONDARY_STAT[archetype]]/4.0)+bonus("attack")),
        "defense":int(gear.defense+int(a.STR/10.0)+bonus("defense")),
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
        var uid=find_uid(reward)
        if uid==0: uid=add_item_uid(reward)
        var worn=instance(equipped.get("weapon",0))
        if uid>0 and (worn.is_empty() or item_attack(worn)<item_attack(instance(uid))): equip(uid)
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
# ---------------- Items ----------------
func instance(uid) -> Dictionary:
    if not (uid is int or uid is float): return {}
    for inst in inventory:
        if inst.uid==int(uid): return inst
    return {}
func find_uid(id: String) -> int:
    var best=null
    for inst in inventory:
        if inst.id==id and (best==null or inst.plus>best.plus): best=inst
    return best.uid if best!=null else 0
func has_item(id: String) -> bool: return find_uid(id)!=0
func is_equipped(uid: int) -> bool: return equipped.values().has(uid)
func equipped_id(slot: String) -> String: return equipment.get(slot,"")
func add_item_uid(id: String,plus: int=0) -> int:
    if not Catalog.items().has(id) or inventory.size()>=INVENTORY_LIMIT: return 0
    var uid=next_uid
    next_uid+=1
    inventory.append({"uid":uid,"id":id,"plus":clampi(plus,0,Catalog.MAX_PLUS)})
    changed.emit()
    return uid
func add_item(id: String) -> bool: return add_item_uid(id)!=0
func item_attack(inst: Dictionary) -> int:
    var item=Catalog.items()[inst.id]
    var base=0 if item.attack<=0 else item.attack+inst.plus*maxi(1,int(round(item.attack*0.06)))
    return maxi(0,base+int(inst.get("bonus",{}).get("attack",0))+int(inst.get("affixes",{}).get("attack",0)))
func item_defense(inst: Dictionary) -> int:
    var item=Catalog.items()[inst.id]
    var base=0 if item.defense<=0 and item.slot=="weapon" else item.defense+inst.plus*maxi(1,int(round(item.defense*0.1)))
    return maxi(0,base+int(inst.get("bonus",{}).get("defense",0))+int(inst.get("affixes",{}).get("defense",0)))
# Why an item cannot be worn, or "" when it can.
func equip_problem(id: String) -> String:
    var item=Catalog.items().get(id,{})
    if item.is_empty(): return "Unknown item."
    if item.get("path",archetype)!=archetype: return "Another class's weapon."
    if level<item.req: return "Requires level %d." % item.req
    return ""
func equip(target) -> bool:
    var uid=find_uid(target) if target is String else int(target) if (target is int or target is float) else 0
    var inst=instance(uid)
    if inst.is_empty() or equip_problem(inst.id)!="": return false
    var slot=Catalog.items()[inst.id].slot
    equipped[slot]=uid
    equipment[slot]=inst.id
    changed.emit()
    return true
func unequip(slot: String) -> bool:
    if slot=="weapon" or not equipped.has(slot): return false
    equipped.erase(slot)
    equipment.erase(slot)
    hp=minf(hp,derived_stats().max_hp)
    mp=minf(mp,derived_stats().max_mp)
    changed.emit()
    return true
func remove_instance(uid: int) -> bool:
    for i in inventory.size():
        if inventory[i].uid==uid:
            inventory.remove_at(i)
            return true
    return false
func sell_value(inst: Dictionary) -> int:
    return int(Catalog.items()[inst.id].value*(1.0+inst.plus*0.25))
func shard_yield(inst: Dictionary) -> int:
    return 1+int(Catalog.items()[inst.id].req/10.0)+inst.plus*2
func sell(uid: int) -> int:
    var inst=instance(uid)
    if inst.is_empty() or is_equipped(uid) or inst.get("locked",false): return 0
    var amount=sell_value(inst)
    remove_instance(uid)
    coins=mini(1000000,coins+amount)
    changed.emit()
    return amount
func dismantle(uid: int) -> int:
    var inst=instance(uid)
    if inst.is_empty() or is_equipped(uid) or inst.get("locked",false): return 0
    var amount=shard_yield(inst)
    remove_instance(uid)
    shards=mini(1000000,shards+amount)
    changed.emit()
    return amount
# Unequipped gear weaker than what you wear in the same slot, or unusable by your class.
func worse_gear() -> Array:
    var result=[]
    for inst in inventory:
        if is_equipped(inst.uid) or inst.get("locked",false) or Quality.RANKS[Quality.rarity(inst)]>=2: continue
        var item=Catalog.items()[inst.id]
        if item.get("path",archetype)!=archetype:
            result.append(inst.uid)
            continue
        var worn=instance(equipped.get(item.slot,0))
        if worn.is_empty(): continue
        var candidate=item_properties(inst)
        var baseline=item_properties(worn)
        var improves=false
        for key in candidate:
            if candidate[key]>baseline[key]:improves=true
        if not improves:result.append(inst.uid)
    return result
func forge_cost(inst: Dictionary) -> Dictionary:
    if inst.plus>=Catalog.MAX_PLUS: return {}
    var req=Catalog.items()[inst.id].req
    return {"shards":(inst.plus+1)*(2+int(req/20.0)),"coins":(inst.plus+1)*(40+req*8),"chance":Catalog.FORGE_CHANCE[inst.plus]}
# Returns "success", "fail", "max" or "cost". A failure only spends the materials.
func forge(uid: int,roll: float=-1.0) -> String:
    var inst=instance(uid)
    if inst.is_empty(): return "cost"
    var cost=forge_cost(inst)
    if cost.is_empty(): return "max"
    if shards<cost.shards or coins<cost.coins: return "cost"
    shards-=cost.shards
    coins-=cost.coins
    var result="fail"
    if (randf() if roll<0 else roll)<cost.chance:
        inst.plus+=1
        result="success"
    hp=minf(hp,derived_stats().max_hp)
    changed.emit()
    return result
func buy_consumable(id: String,count: int,town_level: int) -> bool:
    var info=Catalog.consumables().get(id,{})
    if info.is_empty() or count<=0 or town_level<info.town: return false
    var cost=info.price*count
    if coins<cost or int(consumables.get(id,0))+count>9999: return false
    coins-=cost
    consumables[id]=int(consumables.get(id,0))+count
    changed.emit()
    return true
func buy_price(id: String) -> int: return Catalog.items()[id].value*4
func buy_item(id: String) -> bool:
    if not Catalog.items().has(id) or coins<buy_price(id) or inventory.size()>=INVENTORY_LIMIT: return false
    coins-=buy_price(id)
    add_item_uid(id)
    return true
func collect_reward(reward: Dictionary) -> bool:
    if reward.has("item") and not Catalog.items().has(reward.item): return false
    if reward.has("item") and inventory.size()>=INVENTORY_LIMIT: return false
    if reward.has("consumable") and not Catalog.consumables().has(reward.consumable): return false
    for key in ["coins","potions","shards"]:
        if int(reward.get(key,0)) < 0: return false
    if reward.has("scroll") and not Adventure.scrolls().has(reward.scroll): return false
    if reward.has("quest_item") and not Adventure.QUEST_ITEMS.has(reward.quest_item): return false
    var metadata={}
    if reward.has("item") and not Quality.read(reward,metadata): return false
    if reward.has("item"):
        var uid=add_item_uid(reward.item)
        var added=instance(uid)
        added.merge(metadata,true)
    if reward.has("scroll"): scrolls[reward.scroll]=mini(9999,int(scrolls.get(reward.scroll,0))+1)
    if reward.has("quest_item"): quest_items[reward.quest_item]=mini(9999,int(quest_items.get(reward.quest_item,0))+1)
    coins = mini(1000000, coins+int(reward.get("coins",0)))
    potions = mini(9999, potions+int(reward.get("potions",0)))
    shards = mini(1000000, shards+int(reward.get("shards",0)))
    if reward.has("consumable"): consumables[reward.consumable]=mini(9999,int(consumables.get(reward.consumable,0))+int(reward.get("count",1)))
    changed.emit()
    return true
func potion_amount(id: String) -> float:
    var info=Catalog.consumables()[id]
    var stats=derived_stats()
    var pool=stats.max_mp if info.kind=="mp" else stats.max_hp
    var amount=info.get("amount",0.0) if not info.has("pct") else pool*info.pct
    return amount*(1.0+bonus("heal_pct"))
# Uses the smallest potion that fills the gap, or the strongest one owned.
func best_potion(kind: String) -> String:
    var stats=derived_stats()
    var missing=(stats.max_mp-mp) if kind=="mp" else (stats.max_hp-hp)
    var owned=[]
    for id in Catalog.consumables():
        var info=Catalog.consumables()[id]
        if (info.kind==kind or info.kind=="full") and int(consumables.get(id,0))>0: owned.append(id)
    owned.sort_custom(func(a,b): return potion_amount(a)<potion_amount(b))
    for id in owned:
        if potion_amount(id)>=missing and Catalog.consumables()[id].kind!="full": return id
    return owned.back() if not owned.is_empty() else ""
func use_potion(kind: String="hp") -> bool:
    var stats=derived_stats()
    if kind=="mp":
        if mana_potion_cooldown>0 or mp>=stats.max_mp: return false
    elif potion_cooldown>0 or hp>=stats.max_hp: return false
    var id=best_potion(kind)
    if id=="": return false
    consumables[id]=int(consumables[id])-1
    var info=Catalog.consumables()[id]
    if info.kind in ["hp","full"]: hp=minf(stats.max_hp,hp+potion_amount(id) if info.kind=="hp" else stats.max_hp)
    if info.kind in ["mp","full"]: mp=minf(stats.max_mp,mp+potion_amount(id) if info.kind=="mp" else stats.max_mp)
    if kind=="mp": mana_potion_cooldown=1.5
    else: potion_cooldown=3
    changed.emit()
    return true
func count_potions(kind: String) -> int:
    var total=0
    for id in Catalog.consumables():
        var info=Catalog.consumables()[id]
        if info.kind==kind: total+=int(consumables.get(id,0))
    return total
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
    return {"version":VERSION,"level":level,"xp":xp,"job":job,"archetype":archetype,"attributes":attributes.duplicate(),"ap":ap,"sp":sp.duplicate(),"sp_earned":sp_earned.duplicate(),"skill_ranks":skill_ranks.duplicate(),"slots":slots.duplicate(),"inventory":inventory.duplicate(true),"equipped":equipped.duplicate(),"next_uid":next_uid,"coins":coins,"shards":shards,"consumables":consumables.duplicate(),
        "town":town,"quests":quests.duplicate(true),"quest_items":quest_items.duplicate(),"scrolls":scrolls.duplicate(),"looks":looks.duplicate(),"pets":pets.duplicate(),"pet":pet}
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
    converted.version=2
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
# Version 2 saves held one copy per item id and a single potion count.
func migrate_v2(record: Dictionary) -> Dictionary:
    var converted=record.duplicate(true)
    if not record.get("inventory",null) is Array or record.inventory.size()>100 or not record.get("equipment",null) is Dictionary: return {}
    var items=[]
    var uid=1
    var seen=[]
    for id in record.inventory:
        if not id is String or seen.has(id): return {}
        seen.append(id)
        items.append({"uid":uid,"id":id,"plus":0})
        uid+=1
    var worn={}
    for slot in record.equipment:
        var id=record.equipment[slot]
        if not id is String or not seen.has(id): return {}
        worn[slot]=seen.find(id)+1
    var level_value=record.get("level",1)
    # Items whose new level requirement is above the character are taken off.
    for slot in worn.keys():
        var item=Catalog.items().get(items[worn[slot]-1].id,{})
        if item.is_empty() or slot=="weapon" or not whole(level_value,1,Catalog.MAX_LEVEL): continue
        if item.req>int(level_value): worn.erase(slot)
    if worn.has("weapon"):
        var weapon=Catalog.items().get(items[worn.weapon-1].id,{})
        if not weapon.is_empty() and whole(level_value,1,Catalog.MAX_LEVEL) and weapon.req>int(level_value):
            var starter=STARTER.get(record.get("archetype","warrior"),"starter_sword")
            if not seen.has(starter):
                items.append({"uid":uid,"id":starter,"plus":0})
                uid+=1
                seen.append(starter)
            worn.weapon=seen.find(starter)+1
    var potion_count=record.get("potions",5)
    if not whole(potion_count,0,10000): return {}
    converted.version=VERSION
    converted.inventory=items
    converted.equipped=worn
    converted.next_uid=uid
    converted.consumables={"hp_1":mini(9999,int(potion_count))}
    converted.shards=0
    converted.erase("equipment")
    converted.erase("potions")
    return converted
func load_record(record: Dictionary) -> bool:
    var migrated=false
    if record.get("version",0)==1:
        record=migrate_v1(record)
        if record.is_empty(): return false
        migrated=true
    if record.get("version",0)==2:
        record=migrate_v2(record)
        if record.is_empty(): return false
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
    if not record.get("inventory",null) is Array or record.inventory.size()>INVENTORY_LIMIT: return false
    trial.inventory.clear()
    var uids=[]
    for entry in record.inventory:
        if not entry is Dictionary or not entry.get("id",null) is String or not Catalog.items().has(entry.id): return false
        if not whole(entry.get("uid",-1),1,1000000000) or not whole(entry.get("plus",-1),0,Catalog.MAX_PLUS) or uids.has(int(entry.uid)): return false
        uids.append(int(entry.uid))
        var inst={"uid":int(entry.uid),"id":entry.id,"plus":int(entry.plus)}
        if not trial.read_upgrades(entry,inst) or not Quality.read(entry,inst): return false
        trial.inventory.append(inst)
    if not whole(record.get("next_uid",-1),1,1000000001) or (not uids.is_empty() and int(record.next_uid)<=uids.max()): return false
    trial.next_uid=int(record.next_uid)
    if not record.get("equipped",null) is Dictionary: return false
    trial.equipped.clear()
    trial.equipment.clear()
    for slot in record.equipped:
        if not slot is String or not Catalog.GEAR_SLOTS.has(slot): return false
        var inst=trial.instance(record.equipped[slot])
        if inst.is_empty() or Catalog.items()[inst.id].slot!=slot or trial.equip_problem(inst.id)!="" or trial.equipped.values().has(inst.uid): return false
        trial.equipped[slot]=inst.uid
        trial.equipment[slot]=inst.id
    if not trial.equipped.has("weapon"): return false
    if not whole(record.get("coins",0),0,1000000) or not whole(record.get("shards",0),0,1000000): return false
    trial.coins=int(record.get("coins",0))
    trial.shards=int(record.get("shards",0))
    if not record.get("consumables",{}) is Dictionary: return false
    trial.consumables={}
    for id in record.get("consumables",{}):
        if not Catalog.consumables().has(id) or not whole(record.consumables[id],0,9999): return false
        trial.consumables[id]=int(record.consumables[id])
    if not trial.read_extras(record): return false
    for key in ["level","xp","job","archetype","attributes","ap","sp","sp_earned","skill_ranks","slots","inventory","equipped","equipment","next_uid","coins","shards","consumables","town","quests","quest_items","scrolls","looks","pets","pet"]:
        set(key,trial.get(key))
    buffs.clear()
    migration_note="Your character was updated to the full job tree. All skill points were refunded; open Skills to spend them." if migrated else ""
    hp=derived_stats().max_hp
    mp=derived_stats().max_mp
    changed.emit()
    return true

# Optional fields added after version 3; missing ones keep their defaults.
func read_extras(record: Dictionary) -> bool:
    var Maps=load("res://data/maps.gd")
    var saved_town=record.get("town","town")
    if not saved_town is String or not Maps.definition(saved_town).get("safe",false): saved_town="town"
    town=saved_town
    var Quests=load("res://systems/quests.gd")
    quests={}
    var quest_record=record.get("quests",{})
    if not quest_record is Dictionary: return false
    for id in quest_record:
        var entry=quest_record[id]
        if not Quests.all().has(id): continue
        if not entry is Dictionary or not entry.get("status","") in ["active","done"] or not whole(entry.get("count",0),0,100000): return false
        quests[id]={"status":entry.status,"count":int(entry.get("count",0))}
    quest_items={}
    if not record.get("quest_items",{}) is Dictionary or not record.get("scrolls",{}) is Dictionary: return false
    for id in record.get("quest_items",{}):
        if not Adventure.QUEST_ITEMS.has(id) or not whole(record.quest_items[id],0,9999): return false
        quest_items[id]=int(record.quest_items[id])
    scrolls={}
    for id in record.get("scrolls",{}):
        if not Adventure.scrolls().has(id) or not whole(record.scrolls[id],0,9999): return false
        scrolls[id]=int(record.scrolls[id])
    var saved_looks=record.get("looks",Adventure.default_looks())
    if not Adventure.valid_looks(saved_looks): return false
    looks={"hair":saved_looks.hair,"hair_color":int(saved_looks.hair_color),"face":saved_looks.face,"skin":int(saved_looks.skin)}
    var owned=record.get("pets",[])
    if not owned is Array: return false
    pets=[]
    for id in owned:
        if not id is String or not Adventure.PETS.has(id) or pets.has(id): return false
        pets.append(id)
    var active=record.get("pet","")
    if not active is String or active!="" and not pets.has(active): return false
    pet=active
    return true
func read_upgrades(entry: Dictionary,inst: Dictionary) -> bool:
    var slot=Catalog.items()[inst.id].slot
    var limit=Adventure.UPGRADE_SLOTS.get(slot,5)
    for key in ["slots","failed","scrolled"]:
        if entry.has(key):
            if not whole(entry[key],0,limit): return false
            inst[key]=int(entry[key])
    if entry.has("bonus"):
        if not entry.bonus is Dictionary: return false
        inst.bonus={}
        for key in entry.bonus:
            if not key in ["attack","defense","hp","mp","STR","DEX","INT","LUK","ALL"] or not whole(entry.bonus[key],-200,500): return false
            inst.bonus[key]=int(entry.bonus[key])
    # Every scroll moves one slot to "scrolled" or "failed"; Clean Slate moves one back.
    if inst.has("slots") or inst.has("failed") or inst.has("scrolled"):
        return int(inst.get("slots",limit))+int(inst.get("failed",0))+int(inst.get("scrolled",0))==limit
    return true
func remember_town(id: String):
    if town!=id:
        town=id
        changed.emit()

# --- Upgrade scrolls ---
func upgrade_slots(inst: Dictionary) -> int:
    if inst.has("slots"): return int(inst.slots)
    return Adventure.UPGRADE_SLOTS.get(Catalog.items()[inst.id].slot,5)
func add_scroll(id: String,count: int=1) -> bool:
    if not Adventure.scrolls().has(id): return false
    scrolls[id]=mini(9999,int(scrolls.get(id,0))+count)
    changed.emit()
    return true
# Why a scroll cannot be used on an item, or "" when it can.
func scroll_problem(uid: int,id: String) -> String:
    var inst=instance(uid)
    var info=Adventure.scrolls().get(id,{})
    if inst.is_empty() or info.is_empty(): return "Pick an item and a scroll."
    if int(scrolls.get(id,0))<=0: return "You have no %s." % info.name
    if info.slot!="" and info.slot!=Catalog.items()[inst.id].slot: return "This scroll is for %s." % Adventure.SLOT_WORDS[info.slot].to_lower()+(" gear" if info.slot!="weapon" else "s")
    if id=="scroll_clean":
        if int(inst.get("failed",0))<=0: return "No failed upgrade slots to restore."
    elif upgrade_slots(inst)<=0: return "No upgrade slots left."
    return ""
# Returns "success", "fail" or the problem text. roll<0 rolls randomly.
func apply_scroll(uid: int,id: String,roll: float=-1.0) -> String:
    var problem=scroll_problem(uid,id)
    if problem!="": return problem
    var inst=instance(uid)
    var info=Adventure.scrolls()[id]
    scrolls[id]-=1
    if scrolls[id]<=0: scrolls.erase(id)
    var hit=(randf() if roll<0 else roll)<info.chance
    if id=="scroll_clean":
        if hit:
            inst.failed=int(inst.get("failed",0))-1
            inst.slots=upgrade_slots(inst)+1
    else:
        inst.slots=upgrade_slots(inst)-1
        if hit:
            inst.scrolled=int(inst.get("scrolled",0))+1
            var bonus=inst.get("bonus",{}).duplicate()
            if id=="scroll_chaos":
                var item=Catalog.items()[inst.id]
                var keys=bonus.keys()
                for key in ["attack","defense"]:
                    if item[key]>0 and not keys.has(key): keys.append(key)
                for key in item.stats:
                    if not keys.has(key): keys.append(key)
                for key in keys: bonus[key]=int(bonus.get(key,0))+randi_range(-5,5)
            else:
                for key in info.gains: bonus[key]=int(bonus.get(key,0))+info.gains[key]
            inst.bonus=bonus
        else: inst.failed=int(inst.get("failed",0))+1
    hp=minf(hp,derived_stats().max_hp)
    changed.emit()
    return "success" if hit else "fail"

# --- Pets and looks ---
func buy_pet(id: String) -> bool:
    if not Adventure.PETS.has(id) or pets.has(id) or coins<Adventure.PETS[id].price: return false
    coins-=Adventure.PETS[id].price
    pets.append(id)
    pet=id
    changed.emit()
    return true
func set_pet(id: String) -> bool:
    if id!="" and not pets.has(id): return false
    pet=id
    changed.emit()
    return true
func set_looks(next: Dictionary) -> bool:
    if not Adventure.valid_looks(next): return false
    looks=next.duplicate()
    changed.emit()
    return true

func set_item_locked(uid: int,locked: bool) -> bool:
    var inst=instance(uid)
    if inst.is_empty():return false
    inst.locked=locked
    changed.emit()
    return true
func sort_inventory(mode="level"):
    inventory.sort_custom(func(a,b):
        if mode=="rarity":
            var delta=Quality.RANKS[Quality.rarity(a)]-Quality.RANKS[Quality.rarity(b)]
            if delta!=0:return delta>0
        if mode=="slot":
            var left=Catalog.GEAR_SLOTS.find(Catalog.items()[a.id].slot)
            var right=Catalog.GEAR_SLOTS.find(Catalog.items()[b.id].slot)
            if left!=right:return left<right
        var level_delta=Catalog.items()[a.id].req-Catalog.items()[b.id].req
        return level_delta>0 if level_delta!=0 else a.uid<b.uid)
    changed.emit()

func item_properties(inst: Dictionary) -> Dictionary:
    var item=Catalog.items()[inst.id]
    var total={"attack":item_attack(inst),"defense":item_defense(inst),"STR":0,"DEX":0,"INT":0,"LUK":0,"hp":0,"mp":0}
    for values in [item.stats,inst.get("bonus",{}),inst.get("affixes",{})]:
        for key in values:
            if key=="ALL":
                for stat in ["STR","DEX","INT","LUK"]:total[stat]+=values[key]
            elif key in ["STR","DEX","INT","LUK","hp","mp"]:total[key]+=values[key]
    if item.slot!="weapon":total.hp+=inst.plus*(5+int(item.req/4.0))
    return total
