extends RefCounted
func run(t):
    var bindings = load("res://systems/input_bindings.gd").new()
    t.check(bindings.apply(bindings.defaults()),"default InputMap actions install")
    t.check(not bindings.rebind("attack",KEY_SHIFT),"duplicate binding rejected")
    t.check(bindings.current().attack == KEY_SPACE,"rejected binding keeps attack")
    t.check(bindings.rebind("attack",KEY_A),"valid remapping works")
    bindings.apply(bindings.defaults())
    var world = Node2D.new()
    t.root.add_child(world)
    var floor_node = StaticBody2D.new()
    var collision = CollisionShape2D.new()
    var rectangle = RectangleShape2D.new()
    rectangle.size = Vector2(1000,40)
    collision.shape = rectangle
    floor_node.add_child(collision)
    floor_node.position = Vector2(0,620)
    world.add_child(floor_node)
    var p = load("res://actors/player.gd").new()
    p.movement_enabled = false
    p.position = Vector2(0,570)
    world.add_child(p)
    for i in range(40): await t.physics_frame
    t.check(p.is_on_floor(),"real collision floor supports player")
    p.request_jump()
    for i in range(2): await t.physics_frame
    t.check(p.jumps_used == 1 and p.velocity.y < 0,"first jump has upward impulse")
    p.request_jump()
    for i in range(2): await t.physics_frame
    t.check(p.jumps_used == 2 and p.velocity.x > 0,"second jump boosts facing direction")
    var y_speed = p.velocity.y
    p.request_jump()
    for i in range(2): await t.physics_frame
    t.check(p.jumps_used == 2 and p.velocity.y > y_speed,"third jump rejected")
    for i in range(90): await t.physics_frame
    t.check(p.is_on_floor() and p.jumps_used == 0,"landing restores jump count")
    p.position.y -= 1
    p.coyote = 0.08
    p.request_jump()
    for i in range(2): await t.physics_frame
    t.check(p.jumps_used == 1,"coyote jump treated as first jump")
    world.queue_free()
    await t.process_frame
