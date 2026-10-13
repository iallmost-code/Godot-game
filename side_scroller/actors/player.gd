extends CharacterBody2D
var facing = 1
var movement_enabled = true
var jumps_used = 0
var jump_buffer = 0.0
var coyote = 0.0
var boost_timer = 0.0
var hurt_timer = 0.0
var attack_timer = 0.0
var state
var visual: Node2D
var combat
signal interact_requested
signal died
func _ready():
    collision_layer = 2
    collision_mask = 1
    var shape = CollisionShape2D.new()
    var capsule = CapsuleShape2D.new()
    capsule.radius = 13
    capsule.height = 52
    shape.shape = capsule
    shape.position.y = -26
    add_child(shape)
    visual = preload("res://visuals/character_visual.gd").new()
    add_child(visual)
func reset_at(pos: Vector2):
    position = pos
    velocity = Vector2.ZERO
    jumps_used = 0
    jump_buffer = 0
    coyote = 0
    hurt_timer = 1.5
    attack_timer = 0
func request_jump():
    jump_buffer = 0.12
func apply_knockback(impulse: Vector2): velocity += impulse
func _physics_process(delta):
    hurt_timer = maxf(0, hurt_timer-delta)
    attack_timer = maxf(0, attack_timer-delta)
    var direction = Input.get_axis("move_left", "move_right") if movement_enabled else 0.0
    if direction != 0: facing = int(sign(direction))
    if is_on_floor():
        coyote = 0.10
        jumps_used = 0
    else:
        coyote = maxf(0, coyote-delta)
        velocity.y += 1100 * delta
    if movement_enabled and Input.is_action_just_pressed("jump"): request_jump()
    if jump_buffer > 0:
        if is_on_floor() or coyote > 0:
            velocity.y = -420
            jumps_used = 1
            coyote = 0
            jump_buffer = 0
        elif jumps_used < 2:
            velocity.y = -360
            jumps_used = 2
            boost_timer = 0.22
            jump_buffer = 0
        else: jump_buffer = maxf(0, jump_buffer-delta)
    if boost_timer > 0:
        boost_timer -= delta
        velocity.x = facing * 320
    else: velocity.x = move_toward(velocity.x, direction * 220, 1600 * delta)
    move_and_slide()
    if movement_enabled:
        if Input.is_action_just_pressed("interact"): interact_requested.emit()
        if combat != null:
            if Input.is_action_pressed("attack"): combat.begin_attack("basic")
            for slot in ["z","x","c"]:
                if Input.is_action_just_pressed("skill_"+slot):
                    combat.begin_attack(state.slots[slot])
    var pose = "idle"
    if not is_on_floor(): pose = "jump"
    elif absf(velocity.x) > 15: pose = "run"
    if attack_timer > 0: pose = "attack"
    if hurt_timer > 0 and int(hurt_timer*12)%2 == 0: visual.modulate.a = 0.55
    else: visual.modulate.a = 1
    var visual_facing=combat.attack_facing if combat!=null and combat.active!="" else facing
    visual.set_pose(pose, visual_facing, Time.get_ticks_msec()/1000.0)
func receive_damage(amount: int, impulse: Vector2) -> bool:
    if state == null or hurt_timer > 0 or state.hp <= 0: return false
    state.hp = maxf(0, state.hp-maxi(1,amount-int(state.derived_stats().defense)))
    hurt_timer = 0.8
    apply_knockback(impulse)
    state.changed.emit()
    if state.hp <= 0: died.emit()
    return true
