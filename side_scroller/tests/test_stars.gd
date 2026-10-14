extends RefCounted
func run(t):
    var world=Node2D.new()
    t.root.add_child(world)
    var s=load("res://systems/character_state.gd").new()
    s.initialize_class("thief")
    while s.level<10: s.add_xp(s.xp_required(s.level))
    s.advance_job("thief")
    var p=load("res://actors/player.gd").new()
    p.state=s
    world.add_child(p)
    p.set_physics_process(false)
    var c=load("res://actors/combat_controller.gd").new()
    world.add_child(c)
    c.setup(p,s)
    c.set_process(false)
    var mob=load("res://actors/enemy.gd").new()
    mob.position=Vector2(220,0)
    world.add_child(mob)
    mob.set_physics_process(false)
    mob.hp=500
    await t.physics_frame
    t.check(c.begin_attack("star"),"thief basic star attack starts")
    c.tick(0.12)
    t.check(mob.hp==500 and t.get_nodes_in_group("player_stars").size()==1,"star has travel time and a visible projectile")
    for i in range(22): await t.physics_frame
    t.check(mob.hp<500 and t.get_nodes_in_group("player_stars").is_empty(),"ranged star damages and ends on an enemy")
    c.tick(1)
    var hp=mob.hp
    t.check(c.begin_attack("twin_stars"),"thief learned twin attack starts")
    c.tick(0.2)
    t.check(t.get_nodes_in_group("player_stars").size()==2,"Twin Stars launches two separate stars even with a large frame delta")
    for i in range(22): await t.physics_frame
    t.check(mob.hp<hp and t.get_nodes_in_group("player_stars").is_empty(),"both twin projectiles resolve")
    c.tick(2)
    c.begin_attack("star_fan")
    c.tick(0.12)
    var fan=t.get_nodes_in_group("player_stars")
    t.check(fan.size()==3,"Shadow Fan launches three stars")
    t.check(fan[0].direction.y<0 and fan[2].direction.y>0,"fan spreads above and below the central throw")
    for star in fan: star.queue_free()
    await t.physics_frame
    var wall=StaticBody2D.new()
    wall.position=Vector2(110,-30)
    var collision=CollisionShape2D.new()
    var rectangle=RectangleShape2D.new()
    rectangle.size=Vector2(20,160)
    collision.shape=rectangle
    wall.add_child(collision)
    world.add_child(wall)
    await t.physics_frame
    hp=mob.hp
    c.tick(2)
    c.begin_attack("star")
    c.tick(0.12)
    for i in range(22): await t.physics_frame
    t.check(mob.hp==hp and t.get_nodes_in_group("player_stars").is_empty(),"stars stop at walls instead of hitting enemies behind them")
    p.position.x=27
    wall.position.x=50
    await t.physics_frame
    c.tick(2)
    c.begin_attack("star")
    c.tick(0.12)
    for i in range(22): await t.physics_frame
    t.check(mob.hp==hp,"star cannot spawn through a wall when the player is touching it")
    rectangle.size.x=2
    wall.position.x=43
    await t.physics_frame
    c.tick(2)
    c.begin_attack("star")
    c.tick(0.12)
    for i in range(22): await t.physics_frame
    t.check(mob.hp==hp,"thin walls between the player and throwing hand block stars")
    wall.queue_free()
    mob.queue_free()
    await t.physics_frame
    c.tick(2)
    p.facing=-1
    c.begin_attack("star")
    p.facing=1
    c.tick(0.12)
    var star=t.get_nodes_in_group("player_stars")[0]
    t.check(star.direction.x<0,"star keeps the cast direction during windup")
    for i in range(55): await t.physics_frame
    t.check(t.get_nodes_in_group("player_stars").is_empty(),"missed stars expire at their maximum range")
    world.queue_free()
    await t.process_frame
