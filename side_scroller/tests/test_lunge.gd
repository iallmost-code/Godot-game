extends RefCounted
func run(t):
    var world=Node2D.new()
    t.root.add_child(world)
    var s=load("res://systems/character_state.gd").new()
    while s.level<10: s.add_xp(s.xp_required(s.level))
    s.advance_job("warrior")
    var p=load("res://actors/player.gd").new()
    p.state=s
    p.movement_enabled=false
    world.add_child(p)
    await t.physics_frame
    var c=load("res://actors/combat_controller.gd").new()
    world.add_child(c)
    c.setup(p,s)
    c.set_process(false)
    t.check(c.begin_attack("thrust"),"thrust starts for lunge test")
    for i in range(15): await t.physics_frame
    t.check(p.position.x>45 and p.position.x<90,"Driving Thrust lunges a short controlled distance")
    c.cancel()
    c.cooldowns.clear()
    p.reset_at(Vector2.ZERO)
    p.facing=-1
    c.begin_attack("thrust")
    p.facing=1
    for i in range(15): await t.physics_frame
    t.check(p.position.x< -45,"lunge keeps its cast direction if facing changes")
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
    c.begin_attack("thrust")
    for i in range(15): await t.physics_frame
    t.check(p.position.x>10 and p.position.x<28,"thrust stops at real wall collision")
    c.cancel()
    c.cooldowns.clear()
    p.reset_at(Vector2.ZERO)
    s.mp=0
    t.check(not c.begin_attack("thrust"),"failed thrust does not start")
    for i in range(15): await t.physics_frame
    t.check(is_zero_approx(p.position.x),"rejected thrust gives no free lunge")
    world.queue_free()
    await t.process_frame
