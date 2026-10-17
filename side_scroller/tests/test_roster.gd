extends RefCounted
# Every hunting ground and boss arena loads, spawns its monsters and runs their AI.
const Maps=preload("res://data/maps.gd")
const EnemyStats=preload("res://data/enemy_stats.gd")
func run(t):
    var game=load("res://main.tscn").instantiate()
    game.test_mode=true
    t.root.add_child(game)
    game.player.set_physics_process(true)
    var ids=[]
    for f in Maps.fields(): ids.append(f[0])
    for boss in Maps.LAIRS: ids.append(Maps.boss_arena_id(boss))
    t.check(Maps.LAIRS.size()==12,"twelve bosses have lairs off regional towns")
    var broken=[]
    var levels=[]
    for id in ids:
        if not game.change_map(id,"entry"):
            broken.append(id)
            continue
        await t.process_frame
        var enemies=t.get_nodes_in_group("enemies")
        if enemies.is_empty(): broken.append(id+" (no monsters)")
        var definition=Maps.definition(id)
        if definition.has("boss"):
            if game.map.boss==null or not EnemyStats.is_boss(game.map.boss.definition_id): broken.append(id+" (no boss)")
            else:
                # Stand in front of the boss and let it run its pattern cycle.
                game.player.position=game.map.boss.position+Vector2(-220,0)
                game.state.restore()
        for frame in range(90): await t.physics_frame
        for e in enemies:
            if is_instance_valid(e): levels.append(e.level)
        game.state.restore()
    t.check(broken.is_empty(),"all regions and arenas load with monsters: "+", ".join(broken))
    t.check(levels.max()>=180 and levels.min()<=2,"monster levels span the whole level 1-200 journey")
    # Bosses summon minions and drop treasure that the character can keep.
    game.change_map(Maps.boss_arena_id("gelatinous_monarch"),"entry")
    await t.process_frame
    var boss=game.map.boss
    boss.pattern_index=1
    boss.start_pattern()
    boss.windup=0.0
    boss._physics_process(0.016)
    await t.process_frame
    t.check(t.get_nodes_in_group("boss_minions").size()>=2,"Gelatinous Monarch summons Jellops")
    boss.receive_hit(boss.hp,Vector2.ZERO,123456)
    await t.process_frame
    var loot=null
    for drop in game.map.pickups:
        if drop.reward.has("item"): loot=drop
    t.check(loot!=null and loot.try_collect(game.state),"bosses drop a weapon for your class")
    var copy=load("res://systems/character_state.gd").new()
    t.check(copy.load_record(game.state.to_record()),"boss loot survives save validation")
    game.change_map("town","entry")
    game.queue_free()
    await t.process_frame
