extends RefCounted
func run(t):
    var s=load("res://systems/character_state.gd").new()
    var pickup=load("res://world/loot_pickup.gd").new()
    pickup.setup({"coins":5,"item":"forest_spear"})
    t.check(pickup.try_collect(s),"pickup rewards character")
    t.check(not pickup.try_collect(s) and s.coins==5,"pickup cannot reward twice")
    pickup.free()
    s.add_item("forest_spear")
    t.check(s.equip("forest_spear"),"owned spear equips")
    var damage=s.derived_stats().attack
    s.equip("forest_spear")
    t.check(s.derived_stats().attack==damage and damage==29,"repeat equip cannot stack modifiers")
    t.check(not s.equip("unknown"),"unknown item rejected")
    t.check(not s.equip("forest_armor"),"unowned equipment rejected")
    s.hp=60
    var count=s.potions
    t.check(s.use_potion() and s.hp==100 and s.potions==count-1,"potion heals and consumes one")
    t.check(not s.use_potion(),"potion cooldown enforced")
    t.check(not s.collect_reward({"coins":-5}),"negative reward rejected")
