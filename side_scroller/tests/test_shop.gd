extends RefCounted
const H=preload("res://tests/helpers.gd")
const Catalog=preload("res://data/catalog.gd")
func run(t):
    var s=H.make("warrior",["warrior"],30)
    t.check(Catalog.GEAR_SLOTS.size()==7,"seven gear slots: weapon, hat, armor, gloves, shoes, cape, earring")
    # Duplicates and gear slots.
    var a=s.add_item_uid("hat_lv30")
    var b=s.add_item_uid("hat_lv30")
    t.check(a>0 and b>0 and a!=b and s.inventory.size()>=4,"duplicate items are kept as separate copies")
    var before=s.derived_stats()
    t.check(s.equip(a) and s.derived_stats().defense>before.defense and s.derived_stats().max_hp>before.max_hp,"a worn hat adds defense and HP")
    var low=H.make("warrior",[],5)
    low.add_item("hat_lv30")
    t.check(not low.equip("hat_lv30") and low.equip_problem("hat_lv30").contains("Requires level"),"level requirements block gear above your level")
    t.check(s.unequip("hat") and not s.equipped.has("hat") and not s.unequip("weapon"),"armor pieces come off; the weapon stays")
    s.equip(a)
    # Selling and dismantling.
    var coins=s.coins
    t.check(s.sell(a)==0 and s.instance(a).size()>0,"worn gear cannot be sold")
    var value=s.sell_value(s.instance(b))
    t.check(s.sell(b)==value and s.coins==coins+value and s.instance(b).is_empty(),"selling removes the copy and pays its value")
    var c=s.add_item_uid("gloves_lv30")
    var yield_amount=s.shard_yield(s.instance(c))
    t.check(s.dismantle(c)==yield_amount and s.shards==yield_amount,"dismantling turns gear into Shards")
    s.add_item("starter_armor")
    s.add_item("forest_spear")
    var worse=s.worse_gear()
    t.check(worse.size()>=2,"weaker unworn gear is found for bulk selling")
    for uid in worse: s.sell(uid)
    t.check(s.worse_gear().is_empty(),"bulk selling clears weaker gear")
    # Forge.
    s.shards=1000
    s.coins=100000
    var weapon=s.instance(s.equipped.weapon)
    var attack=s.derived_stats().attack
    t.check(s.forge(weapon.uid,0.0)=="success" and weapon.plus==1 and s.derived_stats().attack>attack,"a successful forge raises attack")
    var shards=s.shards
    t.check(s.forge(weapon.uid,0.999)=="fail" and weapon.plus==1 and s.shards<shards,"a failed forge keeps the level and spends materials")
    weapon.plus=Catalog.MAX_PLUS
    t.check(s.forge(weapon.uid,0.0)=="max","gear stops at +10")
    weapon.plus=1
    var plus_value=s.sell_value(weapon)
    t.check(plus_value>Catalog.items()[weapon.id].value,"enhanced gear is worth more")
    # Potions.
    s.coins=1000
    t.check(not s.buy_consumable("hp_4",1,1) and s.buy_consumable("hp_2",10,1) and s.coins==1000-650,"potions cost coins and higher tiers need higher-level towns")
    t.check(not s.buy_consumable("hp_1",1000000,1),"cannot buy without enough coins")
    s.hp=s.derived_stats().max_hp-120
    var count=s.consumables.hp_2
    t.check(s.use_potion("hp") and s.consumables.hp_2==count-1,"the HP button picks a potion that fits the missing health")
    s.mp=0
    s.consumables["mp_1"]=3
    t.check(s.use_potion("mp") and s.mp>0 and s.consumables.mp_1==2,"MP potions restore mana")
    s.coins=s.buy_price("cape_lv30")
    t.check(s.buy_item("cape_lv30") and s.has_item("cape_lv30") and s.coins==0,"gear can be bought")
    # Save round trip with copies, plus levels, shards and potions.
    var copy=load("res://systems/character_state.gd").new()
    t.check(copy.load_record(s.to_record()) and copy.shards==s.shards and copy.instance(weapon.uid).plus==1 and copy.consumables.hp_2==s.consumables.hp_2,"enhanced gear, Shards and potions survive saving")
    var tampered=s.to_record()
    tampered.inventory[0].plus=99
    t.check(not copy.load_record(tampered),"impossible enhancement levels are rejected")
    tampered=s.to_record()
    tampered.inventory.append(tampered.inventory[0].duplicate())
    t.check(not copy.load_record(tampered),"duplicate copy ids are rejected")
    # Version 2 saves convert.
    var v2={"version":2,"level":30,"xp":0,"job":"warrior","archetype":"warrior","attributes":{"STR":149,"DEX":4,"INT":4,"LUK":4},"ap":0,
        "sp":s.sp.duplicate(),"sp_earned":s.sp_earned.duplicate(),"skill_ranks":{},"slots":{"z":"","x":"","c":"","v":"","a":"","d":"","f":""},
        "inventory":["starter_sword","starter_armor","warrior_sword","briar_armor"],"equipment":{"weapon":"warrior_sword","armor":"briar_armor"},"coins":77,"potions":12}
    for pool in v2.sp: v2.sp[pool]=v2.sp_earned[pool]
    var migrated=load("res://systems/character_state.gd").new()
    t.check(migrated.load_record(v2) and migrated.equipment.weapon=="warrior_sword" and migrated.equipment.armor=="briar_armor" and migrated.potions==12 and migrated.coins==77,"version 2 saves keep their gear, coins and potions")
    # Merchant in town.
    var game=load("res://main.tscn").instantiate()
    game.test_mode=true
    t.root.add_child(game)
    game.change_map("frostmere","entry")
    game.player.position=game.map.merchant_position
    game.map.interact()
    t.check(game.menu.opened and game.menu.selected=="shop" and game.menu.current_panel.in_town(),"pressing Up at a town Merchant opens the shop")
    game.menu.close()
    game.change_map("frostmere_trail","entry")
    game.menu.open_panel("shop")
    t.check(not game.menu.current_panel.in_town(),"the shop only trades in towns")
    game.menu.open_panel("inventory")
    t.check(game.menu.current_panel!=null,"inventory opens with gear slots")
    game.menu.close()
    var reward_seen={"consumable":false,"slot":false,"shards":false}
    game.state.level=80
    for i in range(400):
        var reward=game.map.reward_for("frost_cub",70)
        if reward.has("consumable"): reward_seen.consumable=true
        if reward.has("shards"): reward_seen.shards=true
        if reward.has("item") and Catalog.items()[reward.item].slot in ["hat","gloves","shoes","cape","accessory"]: reward_seen.slot=true
    t.check(reward_seen.consumable and reward_seen.slot and reward_seen.shards,"monsters drop level-matched potions, armor pieces and Shards")
    game.queue_free()
    await t.process_frame
