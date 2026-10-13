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
        if tier() > 0: sp[str(tier())] += 3
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
        skill_ranks.sweep = 1
        skill_ranks.thrust = 1
        slots.z = "sweep"
        slots.x = "thrust"
    elif next == "spearman" and job == "warrior" and level >= 30:
        job = next
        sp["2"] += 1
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
    return {"version":1,"level":level,"xp":xp,"job":job,"attributes":attributes.duplicate(),"ap":ap,"sp":sp.duplicate(),"skill_ranks":skill_ranks.duplicate(),"slots":slots.duplicate(),"inventory":inventory.duplicate(),"equipment":equipment.duplicate(),"coins":coins,"potions":potions}
