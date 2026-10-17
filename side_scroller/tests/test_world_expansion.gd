extends RefCounted
func run(t):
    var maps=load("res://data/maps.gd")
    var towns=["firstlight","gullhaven","starbough","ironridge","shadecross","hollowroot","sunpetal","skylume","frostmere","tickletop","brasswatch","lanternvale","tideglass","wyrmrest","peachspire","reedhaven","saffron","verdigris","hourglass","moonshrine","emberlane","mistkeep","copperwick","thornscar","rainport","bloomkamp","farmeadow","crownreach","rimehaven","jadehaven","lotusquay"]
    var present=true
    for id in towns:
        if maps.definition(id).is_empty(): present=false
    t.check(present,"all original regional towns exist, with no Pirate town")
    if not present: return
    t.check(maps.has_method("route_between"),"atlas can plan a walking route to any inspected region")
    if maps.has_method("route_between"):
        var route=maps.route_between("town","frostmere")
        t.check(route.size()>3 and route[0]=="town" and route.back()=="frostmere","route planner connects starter town to the snow region")
        t.check(maps.route_between("missing","town").is_empty(),"invalid route request returns no path")
    var ids=maps.all_ids()
    var reached=["town"]
    var pending=["town"]
    var valid=true
    var reciprocal=true
    while not pending.is_empty():
        var id=pending.pop_front()
        var data=maps.definition(id)
        for portal in data.portals:
            var destination=maps.definition(portal.target)
            if destination.is_empty() or not destination.spawns.has(portal.spawn):
                valid=false
                continue
            var back=false
            for reverse in destination.portals:
                if reverse.target==id: back=true
            if not back: reciprocal=false
            if not reached.has(portal.target):
                reached.append(portal.target)
                pending.append(portal.target)
    t.check(valid,"every world portal has a valid map and named arrival spawn")
    t.check(reciprocal,"all routes have a return connection")
    t.check(reached.size()==ids.size(),"the entire world is reachable from Willowbridge")
    var safe=true
    var bounds=true
    for id in ids:
        var data=maps.definition(id)
        if data.get("safe",false) and not data.enemies.is_empty(): safe=false
        for portal in data.portals:
            if portal.position.x<90 or portal.position.x>data.width-90: bounds=false
        for spawn in data.spawns.values():
            if spawn.x<30 or spawn.x>data.width-30: bounds=false
    t.check(safe,"safe towns contain no hostile spawns")
    t.check(bounds,"portals and arrival points remain within walkable world bounds")
    var game=load("res://main.tscn").instantiate()
    game.test_mode=true
    t.root.add_child(game)
    var all_load=true
    for id in ids:
        if not game.change_map(id,"entry"): all_load=false
        await t.process_frame
    t.check(all_load,"every town and hunting area loads into the playable scene")
    game.change_map("shadecross","entry")
    game.state.hp=20
    game._process(0.5)
    t.check(game.state.hp>20,"new towns regenerate player health")
    game.change_map("shadecross_trail","entry")
    game.state.hp=0
    game.return_to_town()
    t.check(game.map_id=="shadecross" and game.state.hp==game.state.derived_stats().max_hp,"death returns to the most recently entered safe town")
    game.change_map("ironridge","entry")
    game.player.position=game.map.instructor_position
    while game.state.level<10: game.state.add_xp(game.state.xp_required(game.state.level))
    game.map.interact()
    t.check(game.menu.opened and game.pending_job=="warrior","warrior town instructor opens the existing advancement flow")
    game.menu.close()
    game.change_map("hourglass_trail","entry")
    var enemy=game.map.spawns[0].node
    enemy.set_physics_process(false)
    t.check(enemy.level>=70 and enemy.max_hp>160 and enemy.attack_damage()>50,"late-world enemies scale HP and damage with regional levels")
    game.menu.open_panel("map")
    t.check(game.menu.current_panel.get("map_id")=="hourglass_trail","atlas tracks the current new-world area")
    game.menu.close()
    game.queue_free()
    await t.process_frame
