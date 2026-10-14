extends RefCounted
const Character=preload("res://systems/character_state.gd")
func run(t):
    var warrior=Character.new()
    t.check(warrior.equipment.weapon=="starter_sword","new warrior route starts with a sword")
    t.check(warrior.has_method("initialize_class"),"character supports an independent thief route")
    if not warrior.has_method("initialize_class"): return
    var thief=Character.new()
    t.check(thief.initialize_class("thief") and thief.basic_skill()=="star","thief novice can throw stars immediately")
    t.check(not thief.advance_job("thief"),"thief first job requires level ten")
    while thief.level<10: thief.add_xp(thief.xp_required(thief.level))
    t.check(not thief.advance_job("warrior") and thief.advance_job("thief"),"thief route advances to thief rather than warrior")
    t.check(thief.slots.z=="twin_stars" and thief.slots.x=="star_fan","thief advancement assigns its two attacks")
    t.check(not thief.can_use("thrust") and not thief.rank_up("strength"),"thief cannot learn warrior skills")
    t.check(thief.rank_up("precision"),"thief can spend its first skill point")
    t.check(thief.add_item("forest_sword") and not thief.equip("forest_sword"),"thief cannot equip a warrior weapon")
    var before=thief.derived_stats().attack
    thief.attributes.LUK+=5
    t.check(thief.derived_stats().attack==before+5,"throwing damage scales with LUK")
    thief.attributes.LUK-=5
    var copy=Character.new()
    t.check(copy.load_record(thief.to_record()) and copy.basic_skill()=="star" and copy.job=="thief","thief save preserves job, skill ranks and attacks")
    var invalid=thief.to_record()
    invalid.skill_ranks.thrust=1
    t.check(not copy.load_record(invalid),"save rejects cross-class learned skills")
    var legacy=warrior.to_record()
    legacy.erase("archetype")
    legacy.inventory=["starter_spear","starter_armor"]
    legacy.equipment.weapon="starter_spear"
    t.check(copy.load_record(legacy) and copy.archetype=="warrior","old warrior save still loads")
    while warrior.level<10: warrior.add_xp(warrior.xp_required(warrior.level))
    t.check(warrior.advance_job("warrior") and warrior.equipment.weapon=="warrior_sword","first warrior advancement awards and equips a sword")
    var game=load("res://main.tscn").instantiate()
    game.test_mode=true
    t.root.add_child(game)
    game.save_store.slot_paths={"warrior":"user://test-warrior-slot.json","thief":"user://test-thief-slot.json"}
    game.save_store.selection_path="user://test-selected-slot.txt"
    for path in game.save_store.slot_paths.values(): DirAccess.remove_absolute(path)
    game.save_store.use_slot("warrior")
    game.state.coins=137
    t.check(game.has_method("switch_character"),"character menu supports separate slots")
    if game.has_method("switch_character"):
        game.switch_character("thief")
        t.check(game.state.archetype=="thief" and game.state.level==1 and game.state.coins==0,"new thief slot does not inherit warrior progress")
        game.state.coins=29
        game.switch_character("warrior")
        t.check(game.state.coins==137 and game.state.archetype=="warrior","switching back restores warrior progress")
        game.switch_character("thief")
        t.check(game.state.coins==29,"thief progress survives a return trip")
        game.combat.begin_attack("star")
        game.combat.tick(0.12)
        game.change_map("forest","entry")
        await t.process_frame
        t.check(t.get_nodes_in_group("player_stars").is_empty(),"map travel clears stars from the previous map")
    game.queue_free()
    await t.process_frame
