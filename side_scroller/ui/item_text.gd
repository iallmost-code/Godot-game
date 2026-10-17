extends RefCounted
# Shared item wording for the inventory and the merchant.
const Catalog=preload("res://data/catalog.gd")
const SLOT_NAMES={"weapon":"Weapon","hat":"Hat","armor":"Armor","gloves":"Gloves","shoes":"Shoes","cape":"Cape","accessory":"Earring"}
static func title(inst: Dictionary) -> String:
    var item=Catalog.items()[inst.id]
    return ("+%d " % inst.plus if inst.plus>0 else "")+item.name
static func stats_line(state,inst: Dictionary) -> String:
    var item=Catalog.items()[inst.id]
    var parts=[]
    var attack=state.item_attack(inst)
    var defense=state.item_defense(inst)
    if attack>0: parts.append("ATK %d" % attack)
    if defense>0: parts.append("DEF %d" % defense)
    for key in item.stats:
        var label="All stats" if key=="ALL" else key.to_upper()
        parts.append("+%d %s" % [item.stats[key],label])
    if item.slot!="weapon" and inst.plus>0: parts.append("+%d HP (forge)" % (inst.plus*(5+int(item.req/4.0))))
    var bonus=inst.get("bonus",{})
    for key in bonus:
        if key in ["attack","defense"] or bonus[key]==0: continue
        parts.append("%+d %s (scroll)" % [bonus[key],"All stats" if key=="ALL" else key.to_upper()])
    return "  •  ".join(parts)
static func upgrades(state,inst: Dictionary) -> String:
    var text="%d upgrade slots left" % state.upgrade_slots(inst)
    if inst.get("scrolled",0)>0: text+="  •  %d scrolls passed" % inst.scrolled
    if inst.get("failed",0)>0: text+="  •  %d failed" % inst.failed
    return text
static func requirement(state,inst: Dictionary) -> String:
    var item=Catalog.items()[inst.id]
    var problem=state.equip_problem(inst.id)
    return "%s  •  Lv %d%s" % [SLOT_NAMES.get(item.slot,item.slot.capitalize()),item.req,("  •  "+problem) if problem!="" else ""]
# "ATK 40 -> 52 (+12)" style comparison with what is worn in the same slot.
static func compare(state,inst: Dictionary) -> String:
    var item=Catalog.items()[inst.id]
    var worn=state.instance(state.equipped.get(item.slot,0))
    if worn.is_empty(): return "Slot is empty."
    if worn.uid==inst.uid: return "Currently worn."
    var parts=[]
    for pair in [["ATK",state.item_attack(worn),state.item_attack(inst)],["DEF",state.item_defense(worn),state.item_defense(inst)]]:
        if pair[1]!=0 or pair[2]!=0:
            parts.append("%s %d → %d (%+d)" % [pair[0],pair[1],pair[2],pair[2]-pair[1]])
    return "Compared with worn: "+("  •  ".join(parts) if not parts.is_empty() else "no ATK/DEF change")
