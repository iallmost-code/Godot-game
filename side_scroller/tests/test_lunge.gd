extends RefCounted
const H=preload("res://tests/helpers.gd")
func run(t):
    var s=H.make("warrior",["warrior","fighter","crusader","hero"],120)
    H.learn(s,"rush_hero")
    s.mp=999
    var world=Node2D.new()
    t.root.add_child(world)
    var p=load("res://actors/player.gd").new()
    p.state=s
    p.movement_enabled=false
    world.add_child(p)
    await t.physics_frame
    var c=load("res://actors/combat_controller.gd").new()
    world.add_child(c)
    c.setup(p,s)
    c.set_process(false)
    t.check(c.begin_attack("rush_hero"),"Onslaught starts")
    for i in range(40): await t.physics_frame
    t.check(p.position.x>150 and p.position.x<340,"Onslaught charges a controlled distance")
    c.cancel()
    c.cooldowns.clear()
    p.reset_at(Vector2.ZERO)
    p.facing=-1
    c.begin_attack("rush_hero")
    p.facing=1
    for i in range(40): await t.physics_frame
    t.check(p.position.x< -150,"lunge keeps its cast direction if facing changes")
    var wall=StaticBody2D.new()
    wall.position=Vector2(50,-10)
    var shape=CollisionShape2D.new()
    var rect=RectangleShape2D.new()
    rect.size=Vector2(20,500)
    shape.shape=rect
    wall.add_child(shape)
    world.add_child(wall)
    await t.physics_frame
    c.cancel()
    c.cooldowns.clear()
    p.reset_at(Vector2.ZERO)
    p.facing=1
    c.begin_attack("rush_hero")
    for i in range(40): await t.physics_frame
    t.check(p.position.x>10 and p.position.x<28,"charge stops at real wall collision")
    c.cancel()
    c.cooldowns.clear()
    p.reset_at(Vector2.ZERO)
    s.mp=0
    t.check(not c.begin_attack("rush_hero"),"failed charge does not start")
    for i in range(15): await t.physics_frame
    t.check(is_zero_approx(p.position.x),"rejected charge gives no free lunge")
    # Blink teleports forward but never through walls.
    var mage=H.make("magician",["magician","fp_wizard"],30)
    H.learn(mage,"teleport_fp")
    p.state=mage
    c.setup(p,mage)
    p.reset_at(Vector2(-200,0))
    p.facing=1
    t.check(c.begin_attack("teleport_fp") and p.position.x>-200+100,"Blink moves the caster forward")
    p.reset_at(Vector2(0,0))
    c.cooldowns.clear()
    c.begin_attack("teleport_fp")
    t.check(p.position.x<28,"Blink stops at walls")
    world.queue_free()
    await t.process_frame
