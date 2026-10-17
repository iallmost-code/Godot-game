extends RefCounted
func run(t):
    var bindings = load("res://systems/input_bindings.gd").new()
    t.check(bindings.apply(bindings.defaults()),"default InputMap actions install")
    t.check(not bindings.rebind("attack",KEY_SHIFT),"duplicate binding rejected")
    t.check(bindings.current().attack == KEY_SPACE,"rejected binding keeps attack")
    t.check(bindings.rebind("attack",KEY_Q),"valid remapping works")
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
    p.reset_at(Vector2(0,590))
    p.movement_enabled=true
    for i in range(10): await t.physics_frame
    var press=InputEventKey.new()
    press.physical_keycode=KEY_SHIFT
    press.pressed=true
    Input.parse_input_event(press)
    var maximum_jumps=0
    for i in range(100):
        await t.physics_frame
        maximum_jumps=maxi(maximum_jumps,p.jumps_used)
        if i==20:
            var echo=InputEventKey.new()
            echo.physical_keycode=KEY_SHIFT
            echo.pressed=true
            echo.echo=true
            Input.parse_input_event(echo)
    var release=InputEventKey.new()
    release.physical_keycode=KEY_SHIFT
    release.pressed=false
    Input.parse_input_event(release)
    t.check(maximum_jumps==1 and p.is_on_floor(),"held real Shift input and key echo produce only one jump")
    p.movement_enabled=false
    p.position=Vector2(0,580)
    p.velocity=Vector2(0,220)
    await t.physics_frame
    await t.physics_frame
    p.jumps_used=2
    p.request_jump()
    var buffered=false
    for i in range(12):
        await t.physics_frame
        if p.velocity.y<0: buffered=true
    t.check(buffered,"near-landing jump buffer triggers after the floor is reached")
    world.queue_free()
    await t.process_frame
