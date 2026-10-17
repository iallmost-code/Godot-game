extends RefCounted
const H=preload("res://tests/helpers.gd")
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
    H.learn(s,"lucky_seven")
    t.check(c.begin_attack("lucky_seven"),"Double Toss starts")
    c.tick(0.2)
    t.check(t.get_nodes_in_group("player_stars").size()==2,"Double Toss launches two separate stars even with a large frame delta")
    for i in range(22): await t.physics_frame
    t.check(mob.hp<hp and t.get_nodes_in_group("player_stars").is_empty(),"both Double Toss projectiles resolve")
    H.reach(s,30)
    s.advance_job("assassin")
    H.reach(s,70)
    s.advance_job("hermit")
    H.reach(s,120)
    s.advance_job("night_lord")
    H.learn(s,"triple_throw")
    s.mp=999
    c.tick(2)
    c.begin_attack("triple_throw")
    c.tick(0.3)
    var volley=t.get_nodes_in_group("player_stars")
    t.check(volley.size()==3,"Triple Toss launches three stars")
    for star in volley: star.queue_free()
    await t.physics_frame
    # Grand Shuriken pierces a line of monsters.
    H.learn(s,"avenger")
    var line=[]
    for i in range(3): line.append(H.mob(world,Vector2(260+i*40,0),5000))
    mob.position.x=900
    await t.physics_frame
    c.tick(2)
    c.begin_attack("avenger")
    c.tick(0.12)
    for i in range(70): await t.physics_frame
    var pierced=0
    for m in line:
        if m.hp<5000: pierced+=1
    t.check(pierced==3,"Grand Shuriken pierces every monster in its path")
    for m in line: m.queue_free()
    mob.position.x=220
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
