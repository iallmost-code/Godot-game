extends RefCounted
const Character=preload("res://systems/character_state.gd")
const H=preload("res://tests/helpers.gd")
func run(t):
    var warrior=Character.new()
    t.check(warrior.equipment.weapon=="starter_sword","new warrior route starts with a sword")
    for kind in ["warrior","magician","bowman","thief"]:
        var c=Character.new()
        t.check(c.initialize_class(kind) and c.archetype==kind,"%s class can be created" % kind)
    var thief=Character.new()
    t.check(thief.initialize_class("thief") and thief.basic_skill()=="star","thief novice can throw stars immediately")
    t.check(not thief.advance_job("thief"),"thief first job requires level ten")
    H.reach(thief,10)
    t.check(not thief.advance_job("warrior") and thief.advance_job("thief"),"thief route advances to thief rather than warrior")
    t.check(thief.job_name()=="Prowler","thief first job uses its original name")
    t.check(not thief.can_use("power_strike") and not thief.rank_up("power_strike"),"thief cannot learn warrior skills")
    t.check(thief.rank_up("lucky_seven"),"thief can spend its first skill point")
    t.check(thief.add_item("forest_sword") and not thief.equip("forest_sword"),"thief cannot equip a warrior weapon")
    var before=thief.derived_stats().attack
    thief.attributes.LUK+=5
    t.check(thief.derived_stats().attack==before+5,"throwing damage scales with LUK")
    thief.attributes.LUK-=5
    var copy=Character.new()
    t.check(copy.load_record(thief.to_record()) and copy.basic_skill()=="star" and copy.job=="thief" and copy.skill_ranks.lucky_seven==1,"thief save preserves job, skill ranks and attacks")
    var invalid=thief.to_record()
    invalid.skill_ranks.power_strike=1
    t.check(not copy.load_record(invalid),"save rejects cross-class learned skills")
    var mage=H.make("magician",["magician"],12)
    var base=mage.derived_stats().attack
    mage.attributes.INT+=6
    t.check(mage.derived_stats().attack==base+6,"magic attack scales with INT")
    var archer=H.make("bowman",["archer"],12)
    base=archer.derived_stats().attack
    archer.attributes.DEX+=6
    t.check(archer.derived_stats().attack==base+6,"arrow damage scales with DEX")
    # Version 1 saves (two classes, jobs to 100) migrate with a full refund.
    var legacy={"version":1,"level":65,"xp":0,"job":"hermit","archetype":"thief","attributes":{"STR":4,"DEX":4,"INT":4,"LUK":324},"ap":0,
        "sp":{"1":0,"2":0,"3":0,"4":0},"sp_earned":{"1":1,"2":1,"3":16,"4":0},"skill_ranks":{"star":1,"star_fan":5,"shadow_partner":1},"slots":{"z":"","x":"star_fan","c":"shadow_partner"},
        "inventory":["starter_claw","starter_armor","thief_claw"],"equipment":{"weapon":"thief_claw","armor":"starter_armor"},"coins":500,"potions":9}
    var migrated=Character.new()
    t.check(migrated.load_record(legacy),"version 1 save loads")
    t.check(migrated.job=="assassin" and migrated.level==65,"a level-65 third job steps back until the new level-70 requirement")
    t.check(migrated.skill_ranks.is_empty() and migrated.sp["1"]>0 and migrated.sp["2"]>0 and migrated.coins==500,"retired skills are refunded and progress is kept")
    t.check(migrated.migration_note!="","migration explains what happened")
    var again=Character.new()
    t.check(again.load_record(migrated.to_record()) and again.sp==migrated.sp and again.migration_note=="","migrated saves do not refund points a second time")
    var old_warrior={"version":1,"level":1,"xp":0,"job":"beginner","attributes":{"STR":4,"DEX":4,"INT":4,"LUK":4},"ap":0,"sp":{"1":0,"2":0},"sp_earned":{"1":0,"2":0},
        "skill_ranks":{"basic":1},"inventory":["starter_spear","starter_armor"],"equipment":{"weapon":"starter_spear","armor":"starter_armor"}}
    t.check(copy.load_record(old_warrior) and copy.archetype=="warrior","old warrior save still loads")
    H.reach(warrior,10)
    t.check(warrior.advance_job("warrior") and warrior.equipment.weapon=="warrior_sword","first warrior advancement awards and equips a sword")
    var game=load("res://main.tscn").instantiate()
    game.test_mode=true
    t.root.add_child(game)
    game.save_store.slot_paths={"warrior":"user://test-warrior-slot.json","thief":"user://test-thief-slot.json","magician":"user://test-mage-slot.json","bowman":"user://test-bow-slot.json"}
    game.save_store.selection_path="user://test-selected-slot.txt"
    for path in game.save_store.slot_paths.values(): DirAccess.remove_absolute(path)
    game.save_store.use_slot("warrior")
    game.state.coins=137
    t.check(game.has_method("switch_character"),"character menu supports separate slots")
    game.switch_character("thief")
    t.check(game.state.archetype=="thief" and game.state.level==1 and game.state.coins==0,"new thief slot does not inherit warrior progress")
    game.state.coins=29
    game.switch_character("magician")
    t.check(game.state.archetype=="magician" and game.state.equipment.weapon=="starter_staff","mage slot starts a fresh mage")
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
