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
