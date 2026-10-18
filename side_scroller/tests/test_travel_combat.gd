extends RefCounted
const H=preload("res://tests/helpers.gd")
func run(t):
    var player_script=load("res://actors/player.gd")
    var projectile_script=load("res://world/player_star.gd")
    var p=player_script.new()
    t.root.add_child(p)
    p.set_physics_process(false)
    t.check(p.has_method("request_drop_through"),"player supports dropping through only one-way platforms")
    var drop_supported=p.has_method("request_drop_through")
    p.queue_free()
    var star=projectile_script.new()
    t.root.add_child(star)
    star.set_physics_process(false)
    t.check(star.has_method("find_tracking_target"),"ranged attacks can acquire a visible enemy ahead")
    var tracking_supported=star.has_method("find_tracking_target")
    star.queue_free()
    await t.process_frame
    if not drop_supported or not tracking_supported: return
    var world=Node2D.new()
    t.root.add_child(world)
    var ground=StaticBody2D.new()
    ground.position=Vector2(0,640)
    var ground_shape=CollisionShape2D.new()
    var rect=RectangleShape2D.new()
    rect.size=Vector2(900,40)
    ground_shape.shape=rect
    ground.add_child(ground_shape)
    world.add_child(ground)
    var platform=StaticBody2D.new()
    platform.position=Vector2(0,440)
    var shape=CollisionShape2D.new()
    rect=RectangleShape2D.new()
    rect.size=Vector2(300,16)
    shape.shape=rect
    shape.one_way_collision=true
    platform.add_child(shape)
    world.add_child(platform)
    p=player_script.new()
    p.position=Vector2(0,420)
    p.movement_enabled=false
    world.add_child(p)
    for i in range(15): await t.physics_frame
    t.check(p.is_on_floor() and p.position.y<450,"test character lands on a real one-way platform")
    t.check(p.request_drop_through(),"drop request releases the supporting one-way platform")
    for i in range(60): await t.physics_frame
    t.check(p.is_on_floor() and p.position.y>600,"drop lands on solid ground underneath")
    t.check(not p.request_drop_through(),"solid ground cannot be dropped through")
    t.check(p.get_collision_exceptions().is_empty(),"temporary platform exceptions are restored")
    p.reset_at(Vector2(0,420))
    p.movement_enabled=true
    var bindings=load("res://systems/input_bindings.gd").new()
    bindings.apply(bindings.defaults())
    for i in range(15): await t.physics_frame
    var key=InputEventKey.new()
    key.physical_keycode=KEY_DOWN
    key.pressed=true
    Input.parse_input_event(key)
    key=InputEventKey.new()
    key.physical_keycode=KEY_SHIFT
    key.pressed=true
    Input.parse_input_event(key)
    for i in range(5): await t.physics_frame
    t.check(p.velocity.y>0 and p.position.y>440,"real Down + Shift input drops instead of jumping")
    for code in [KEY_DOWN,KEY_SHIFT]:
        key=InputEventKey.new()
        key.physical_keycode=code
        key.pressed=false
        Input.parse_input_event(key)
    p.start_climbing([0,440,620,"rope"])
    p.position.y=480
    for code in [KEY_DOWN,KEY_SHIFT]:
        key=InputEventKey.new()
        key.physical_keycode=code
        key.pressed=true
        Input.parse_input_event(key)
    for i in range(3): await t.physics_frame
    t.check(not p.climbing and p.velocity.y>0 and p.collision_mask==1,"Down + Jump releases a rope downward with collisions restored")
    for code in [KEY_DOWN,KEY_SHIFT]:
        key=InputEventKey.new()
        key.physical_keycode=code
        key.pressed=false
        Input.parse_input_event(key)
    p.movement_enabled=false
    p.reset_at(Vector2(0,620))
    t.check(p.get_collision_exceptions().is_empty(),"map respawn clears a pending platform drop")
    p.set_physics_process(false)
    var mob=H.mob(world,Vector2(220,550),500)
    var behind=H.mob(world,Vector2(-100,620),500)
    await t.physics_frame
    for style in ["star","arrow","bolt"]:
        star=projectile_script.new()
        star.style=style
        star.position=Vector2(0,590)
        star.direction=Vector2.RIGHT
        star.damage=20
        world.add_child(star)
        star.set_physics_process(false)
        t.check(star.find_tracking_target()==mob,"tracking chooses an elevated enemy ahead for "+style)
        star.set_physics_process(true)
        var hp=mob.hp
        for i in range(35): await t.physics_frame
        t.check(mob.hp<hp,"homing "+style+" connects with an elevated enemy")
    star=projectile_script.new()
    star.position=Vector2(0,590)
    world.add_child(star)
    star.set_physics_process(false)
    star.already_hit.append(mob.get_instance_id())
    t.check(star.find_tracking_target()==null,"tracking ignores previously hit and behind-the-player enemies")
    star.already_hit.clear()
    mob.dead=true
    t.check(star.find_tracking_target()==null,"tracking ignores defeated enemies")
    mob.dead=false
    var wall=StaticBody2D.new()
    wall.position=Vector2(100,500)
    var wall_shape=CollisionShape2D.new()
    var wall_rect=RectangleShape2D.new()
    wall_rect.size=Vector2(20,300)
    wall_shape.shape=wall_rect
    wall.add_child(wall_shape)
    world.add_child(wall)
    await t.physics_frame
    t.check(star.find_tracking_target()==null,"tracking does not acquire targets behind solid walls")
    world.queue_free()
    await t.process_frame
