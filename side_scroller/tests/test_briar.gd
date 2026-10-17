extends RefCounted
func run(t):
    var game=load("res://main.tscn").instantiate()
    game.test_mode=true
    t.root.add_child(game)
    t.check(game.change_map("briar","entry"),"new Briar Hollow hunting area loads")
    if game.map_id!="briar":
        game.queue_free()
        await t.process_frame
        return
    t.check(game.map.boss!=null and game.map.boss.is_heavy,"Briar Hollow contains a heavy miniboss")
    var boss=game.map.boss
    boss.set_physics_process(false)
    t.check(boss.max_hp>=2000,"miniboss has a distinct health pool")
    var before=boss.velocity
    boss.receive_hit(1,Vector2(900,-400),451)
    t.check(boss.velocity==before,"Rootwarden resists mob-push knockback")
    game.player.position=Vector2(boss.position.x-80,610)
    game.state.hp=500
    game.player.hurt_timer=0
    boss.start_attack("slam")
    boss._physics_process(0.3)
    t.check(game.state.hp==500,"boss slam windup gives time to react")
    boss._physics_process(0.7)
    t.check(game.state.hp<500,"telegraphed slam hits a nearby grounded player")
    game.state.hp=500
    game.player.hurt_timer=0
    game.player.position.y=510
    boss.start_attack("slam")
    boss._physics_process(1.1)
    t.check(game.state.hp==500,"jumping above the slam avoids damage")
    boss.start_attack("volley")
    boss._physics_process(1.1)
    t.check(t.get_nodes_in_group("enemy_projectiles").size()==3,"boss ranged pattern launches three seeds")
    var xp=game.state.xp
    boss.receive_hit(100000,Vector2.ZERO,452)
    var rewarded=game.state.to_record()
    t.check(not boss.receive_hit(100000,Vector2.ZERO,453) and game.state.to_record()==rewarded,"boss cannot grant duplicate XP or loot from overlapping hits")
    t.check(game.map.pickups.size()==1 and game.map.pickups[0].reward.item=="warden_sword","boss drops a guaranteed class weapon")
    game.map.pickups[0].try_collect(game.state)
    t.check(game.state.inventory.has("warden_sword"),"boss weapon can be collected")
    await t.process_frame
    game.map._process(45.1)
    t.check(is_instance_valid(game.map.boss) and game.map.boss!=boss,"miniboss respawns after its longer timer")
    t.check(game.hud.boss_target==game.map.boss,"health bar follows the respawned miniboss")
    game.state.advance_job("warrior")
    game.state.equip("warden_sword")
    while game.state.level<30: game.state.add_xp(game.state.xp_required(game.state.level))
    game.state.advance_job("spearman")
    t.check(game.state.derived_stats().attack>=50,"job reward cannot downgrade stronger boss equipment")
    var copy=load("res://systems/character_state.gd").new()
    t.check(copy.load_record(game.state.to_record()),"new boss loot survives character save validation")
    game.change_map("forest","entry")
    game.player.position=Vector2(2850,610)
    game.map.interact()
    t.check(game.map_id=="briar","far forest portal leads into Briar Hollow")
    game.player.position=Vector2(150,610)
    game.map.interact()
    t.check(game.map_id=="forest" and game.player.position.x>2500,"Briar return portal arrives at the far forest entrance")
    await t.process_frame
    t.check(t.get_nodes_in_group("enemy_projectiles").is_empty(),"leaving boss area cleans its projectiles")
    game.change_map("briar","entry")
    var current=game.map
    t.check(not game.change_map("briar","invalid") and game.map==current,"invalid spawn cannot replace the current area")
    game.return_to_town()
    await t.process_frame
    t.check(game.map_id=="town" and t.get_nodes_in_group("enemies").is_empty(),"death return from new area leaves town safe")
    game.queue_free()
    await t.process_frame
