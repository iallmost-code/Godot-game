extends RefCounted
func run(t):
    var game=load("res://main.tscn").instantiate()
    game.test_mode=true
    t.root.add_child(game)
    game.change_map("forest","entry")
    for enemy in t.get_nodes_in_group("enemies"): enemy.set_physics_process(false)
    var mob=game.map.spawns[0].node
    t.check(mob.get("level")!=null and mob.has_method("attack_damage"),"enemies expose a level and level-scaled attack")
    if not mob.has_method("attack_damage"):
        game.queue_free()
        await t.process_frame
        return
    var base_damage=mob.attack_damage()
    var original_level=mob.level
    mob.level+=10
    t.check(mob.attack_damage()>base_damage,"higher-level version of the same enemy hits harder")
    mob.level=original_level
    var lantern
    for record in game.map.spawns:
        if record.id=="lantern": lantern=record.node; break
    t.check(lantern.level>mob.level and lantern.attack_damage()>base_damage,"forest ranged enemy has a higher level and damage")
    game.player.position=mob.position
    game.player.hurt_timer=0
    var hp=game.state.hp
    mob._physics_process(0.016)
    t.check(game.state.hp<hp,"touching a live monster damages the player")
    var hit_hp=game.state.hp
    mob._physics_process(0.016)
    t.check(game.state.hp==hit_hp,"contact invulnerability stops repeated-frame damage")
    t.check(game.effects.numbers.size()>0,"accepted enemy hit creates visible player damage feedback")
    game.player.hurt_timer=0
    game.state.restore()
    game.player.position=mob.position+Vector2(45,0)
    mob.telegraph=0.05
    hp=game.state.hp
    mob._physics_process(0.1)
    t.check(game.state.hp==hp-maxi(1,mob.attack_damage()-game.state.derived_stats().defense),"melee attack uses level-scaled damage after armor")
    game.player.hurt_timer=0
    game.state.restore()
    game.state.inventory.append("briar_armor")
    game.state.equip("briar_armor")
    hp=game.state.hp
    game.player.receive_damage(30,Vector2.ZERO)
    t.check(hp-game.state.hp==21,"equipped armor reduces real incoming damage")
    game.player.hurt_timer=0
    hp=game.state.hp
    game.player.receive_damage(1,Vector2.ZERO)
    t.check(hp-game.state.hp==1,"armor cannot remove all damage from a hit")
    game.player.hurt_timer=0
    game.state.restore()
    lantern.position=Vector2(600,610)
    game.player.position=Vector2(730,610)
    lantern.telegraph=0.05
    hp=game.state.hp
    lantern._physics_process(0.1)
    var bolts=t.get_nodes_in_group("enemy_projectiles")
    t.check(bolts.size()==1 and bolts[0].damage==lantern.attack_damage(),"lantern projectile carries its enemy's scaled damage")
    for i in range(80): await t.physics_frame
    t.check(game.state.hp<hp,"real moving enemy projectile collides with player and removes HP")
    while game.state.level<20: game.state.add_xp(game.state.xp_required(game.state.level))
    t.check(mob.level==original_level and mob.attack_damage()==base_damage,"leveling the player does not secretly level up starter enemies")
    game.change_map("briar","entry")
    for enemy in t.get_nodes_in_group("enemies"): enemy.set_physics_process(false)
    var thorn=game.map.spawns[0].node
    var boss=game.map.boss
    t.check(thorn.level>original_level and thorn.attack_damage()>base_damage,"Briar enemies have stronger level-based attacks")
    t.check(boss.level>=25 and boss.attack_damage(1.4)>thorn.attack_damage(),"boss slam is stronger than regular higher-area attacks")
    game.player.position=boss.position+Vector2(-80,0)
    game.player.hurt_timer=0
    hp=game.state.hp
    boss.attack_kind="slam"
    boss.resolve_attack()
    t.check(hp-game.state.hp==maxi(1,boss.attack_damage(1.4)-game.state.derived_stats().defense),"boss slam applies the same level and armor rules")
    game.player.hurt_timer=0
    game.state.hp=1
    game.player.position=thorn.position
    thorn._physics_process(0.016)
    await t.process_frame
    await t.process_frame
    t.check(game.map_id=="town" and game.state.hp==game.state.derived_stats().max_hp,"lethal enemy contact triggers safe town respawn with restored HP")
    game.queue_free()
    await t.process_frame
