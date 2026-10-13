extends RefCounted
func run(t):
    var world = Node2D.new()
    t.root.add_child(world)
    var s = load("res://systems/character_state.gd").new()
    while s.level < 10: s.add_xp(s.xp_required(s.level))
    s.advance_job("warrior")
    var player = load("res://actors/player.gd").new()
    player.state = s
    world.add_child(player)
    player.set_physics_process(false)
    player.hurt_timer = 0
    var c = load("res://actors/combat_controller.gd").new()
    world.add_child(c)
    c.setup(player,s)
    c.set_process(false)
    var enemy = load("res://actors/enemy.gd").new()
    enemy.position = Vector2(70,0)
    world.add_child(enemy)
    enemy.set_physics_process(false)
    enemy.hp = 200
    if not c.begin_attack("basic"):
        t.check(false,"basic attack starts")
        world.queue_free()
        await t.process_frame
        return
    t.check(enemy.hp == 200,"windup has no immediate damage")
    c.tick(0.12)
    var first_hp = enemy.hp
    t.check(first_hp < 200,"active swing damages enemy in front")
    c.tick(0.03)
    t.check(enemy.hp == first_hp,"same swing never hits enemy twice")
    t.check(not c.begin_attack("basic"),"recovery prevents attack spam")
    c.tick(1)
    t.check(not c.begin_attack("wave"),"locked skill cannot attack")
    var mana = s.mp
    t.check(c.begin_attack("thrust"),"learned thrust starts")
    c.tick(0.12)
    t.check(enemy.velocity.x > 0,"thrust pushes normal mob")
    t.check(s.mp == mana-5,"cast consumes configured mana")
    c.tick(1)
    t.check(not c.begin_attack("thrust"),"cooldown prevents second thrust")
    c.tick(3)
    enemy.is_heavy = true
    enemy.velocity = Vector2.ZERO
    first_hp = enemy.hp
    c.begin_attack("thrust")
    c.tick(0.12)
    t.check(enemy.hp < first_hp and enemy.velocity.x == 0,"heavy mob takes damage but resists push")
    c.tick(3)
    enemy.position.x = -60
    first_hp = enemy.hp
    c.begin_attack("basic")
    c.tick(0.12)
    t.check(enemy.hp == first_hp,"attack does not hit behind player")
    player.hurt_timer=0
    var hp = s.hp
    t.check(player.receive_damage(10,Vector2.ZERO),"first incoming hit accepted")
    t.check(not player.receive_damage(10,Vector2.ZERO) and s.hp >= hp-10,"invulnerability blocks overlapping hit")
    c.tick(3)
    s.mp=0
    t.check(not c.begin_attack("sweep"),"no-mana cast rejected")
    c.tick(3)
    s.job="spearman"
    s.skill_ranks.wave=2
    s.mp=100
    var cluster=[]
    for i in range(6):
        var mob=load("res://actors/enemy.gd").new()
        mob.position=Vector2(20+i*20,0)
        world.add_child(mob)
        mob.set_physics_process(false)
        mob.hp=200
        cluster.append(mob)
    c.begin_attack("wave")
    c.tick(0.12)
    t.check(cluster[5].hp==200,"Wave rank two retains five-target limit")
    c.tick(3)
    s.skill_ranks.wave=3
    c.begin_attack("wave")
    c.tick(0.12)
    t.check(cluster[5].hp<200,"Wave rank three gains sixth target")
    for mob in cluster:
        if is_instance_valid(mob): mob.queue_free()
    await t.process_frame
    c.tick(3)
    enemy.position.x=60
    enemy.hp=200
    var previous=enemy.hp
    c.begin_attack("basic")
    c.tick(0.4)
    t.check(enemy.hp<previous,"large frame delta does not skip attack hit window")
    c.tick(3)
    enemy.position=Vector2(70,0)
    enemy.hp=200
    var behind=load("res://actors/enemy.gd").new()
    behind.position=Vector2(-70,0)
    world.add_child(behind)
    behind.set_physics_process(false)
    behind.hp=200
    player.position=Vector2.ZERO
    player.facing=1
    c.begin_attack("basic")
    player.facing=-1
    player.position=Vector2(-20,0)
    c.tick(0.12)
    t.check(enemy.hp<200 and behind.hp==200,"turning during windup keeps damage on the displayed attack side")
    world.queue_free()
    await t.process_frame
