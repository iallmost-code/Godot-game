extends RefCounted
func run(t):
    var game=load("res://main.tscn").instantiate()
    game.test_mode=true
    t.root.add_child(game)
    if not game.change_map("forest","entry"):
        t.check(false,"town connects to forest")
        game.queue_free()
        await t.process_frame
        return
    t.check(game.map_id=="forest","forest map active")
    game.state.coins=55
    var old=game.map
    t.check(game.change_map("town","entry") and game.state.coins==55,"map transition preserves character")
    await t.process_frame
    t.check(not is_instance_valid(old),"previous map released")
    t.check(game.map.get_tree().get_nodes_in_group("enemies").is_empty(),"town is safe")
    t.check(not game.change_map("invalid","entry") and game.map_id=="town","invalid destination preserves map")
    game.state.hp=0
    game.return_to_town()
    t.check(game.state.hp==game.state.derived_stats().max_hp and game.state.coins==55,"death retains loot and restores health")
    game.queue_free()
    await t.process_frame
    var save_path="user://side_scroller.json"
    var existed=FileAccess.file_exists(save_path)
    var original=""
    if existed:
        var old_file=FileAccess.open(save_path,FileAccess.READ)
        original=old_file.get_as_text()
        old_file.close()
    var corrupt=FileAccess.open(save_path,FileAccess.WRITE)
    corrupt.store_string("{not valid json")
    corrupt.close()
    var startup=load("res://main.tscn").instantiate()
    t.root.add_child(startup)
    await t.process_frame
    t.check(startup.hud.notice.text.to_lower().contains("invalid"),"corrupt-save explanation survives startup rendering")
    t.check(FileAccess.file_exists(save_path+".corrupt-backup"),"corrupt original is backed up")
    startup.queue_free()
    await t.process_frame
    if existed:
        var restore=FileAccess.open(save_path,FileAccess.WRITE)
        restore.store_string(original)
        restore.close()
    else: DirAccess.remove_absolute(save_path)
    var repeated=load("res://main.tscn").instantiate()
    repeated.test_mode=true
    t.root.add_child(repeated)
    for i in range(4):
        repeated.change_map("forest","entry")
        await t.process_frame
        t.check(t.get_nodes_in_group("enemies").size()==preload("res://data/maps.gd").definition("forest").enemies.size(),"forest transition keeps one set of enemies")
        repeated.change_map("town","entry")
        await t.process_frame
        t.check(t.get_nodes_in_group("enemies").is_empty(),"return to town clears forest enemies")
    repeated.change_map("forest","entry")
    var entry=repeated.map.spawns[0]
    var dead=entry.node
    dead.receive_hit(10000,Vector2.ZERO,9381)
    await t.process_frame
    repeated.map._process(7.1)
    t.check(is_instance_valid(entry.node) and entry.node!=dead,"defeated forest monster respawns once after timer")
    var mob=entry.node
    mob.position.x=mob.spawn_position.x+500
    mob._physics_process(0.1)
    t.check(mob.velocity.x<0,"monster beyond its leash returns toward spawn")
    while repeated.state.level<10: repeated.state.add_xp(repeated.state.xp_required(repeated.state.level))
    repeated.state.advance_job("warrior")
    while repeated.state.level<30: repeated.state.add_xp(repeated.state.xp_required(repeated.state.level))
    repeated.state.advance_job("spearman")
    while repeated.state.level<70: repeated.state.add_xp(repeated.state.xp_required(repeated.state.level))
    repeated.state.advance_job("dragon_knight")
    repeated.state.rank_up("dragon_fury")
    repeated.combat.begin_attack("dragon_fury")
    t.check(repeated.effects.effects.back().get("reach",0)==300,"Wyrm Sweep presentation uses the skill's reach")
    repeated.queue_free()
    await t.process_frame
