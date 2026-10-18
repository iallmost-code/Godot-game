extends CharacterBody2D
const Catalog=preload("res://data/catalog.gd")
var facing = 1
var movement_enabled = true
var jumps_used = 0
var jump_buffer = 0.0
var coyote = 0.0
var boost_timer = 0.0
var hurt_timer = 0.0
var attack_timer = 0.0
var damage_recoil=0.0
var lunge_time=0.0
var lunge_direction=1
var walk_phase=0.0
var lunge_speed=400.0
var stun_time=0.0
var status_immunity=0.0
var dropped_platforms: Array=[]
var state
# Ropes and ladders of the current map: [x, top y, bottom y, kind].
var climbs: Array=[]
var climbing=false
var climb: Array=[]
const CLIMB_SPEED=150.0
var visual: Node2D
var combat
signal interact_requested
signal damaged(amount: int)
signal evaded(text: String)
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
    for entry in dropped_platforms:
        if is_instance_valid(entry.body): remove_collision_exception_with(entry.body)
    dropped_platforms.clear()
    stop_climbing()
    position = pos
    velocity = Vector2.ZERO
    jumps_used = 0
    jump_buffer = 0
    coyote = 0
    hurt_timer = 1.5
    attack_timer = 0
    damage_recoil=0
    lunge_time=0
    stun_time=0
func start_lunge(direction: int,duration: float=0.16,speed: float=400.0):
    lunge_direction=direction
    lunge_time=duration
    lunge_speed=speed
func apply_stun(duration: float):
    if status_immunity>0 or state!=null and state.bonus("status_immune")>0: return
    stun_time=maxf(stun_time,duration)
func teleport(offset: float):
    # move_and_collide stops at walls so a blink never passes through them.
    move_and_collide(Vector2(offset,0))
    velocity.x=0
func request_jump():
    jump_buffer = 0.12
func request_drop_through() -> bool:
    if not is_on_floor(): return false
    var released=false
    for i in get_slide_collision_count():
        var collision=get_slide_collision(i)
        var body=collision.get_collider()
        if collision.get_normal().y>-0.7 or not body is StaticBody2D: continue
        var owner=collision.get_collider_shape()
        if not owner is CollisionShape2D or not owner.one_way_collision: continue
        add_collision_exception_with(body)
        var bottom=owner.global_position.y+owner.shape.get_rect().size.y/2
        dropped_platforms.append({"body":body,"bottom":bottom,"age":0.0})
        released=true
    if released:
        position.y+=4
        velocity.y=maxf(140,velocity.y)
        jumps_used=1
        coyote=0
        jump_buffer=0
        boost_timer=0
    return released
func update_dropped_platforms(delta: float):
    for entry in dropped_platforms.duplicate():
        entry.age+=delta
        if not is_instance_valid(entry.body):
            dropped_platforms.erase(entry)
        elif global_position.y-52>entry.bottom+2 or entry.age>1.0:
            remove_collision_exception_with(entry.body)
            dropped_platforms.erase(entry)
func apply_knockback(impulse: Vector2):
    stop_climbing()
    velocity += impulse
# The rope or ladder the player can grab moving up (dir -1) or down (dir 1).
func climb_at(dir: int) -> Array:
    for c in climbs:
        if absf(position.x-c[0])>16: continue
        if dir<0 and position.y>c[1]+4 and position.y<=c[2]+4: return c
        if dir>0 and position.y>=c[1]-4 and position.y<c[2]-4: return c
    return []
func start_climbing(c: Array):
    climbing=true
    climb=c
    position.x=c[0]
    velocity=Vector2.ZERO
    lunge_time=0
    boost_timer=0
    collision_mask=0
func stop_climbing():
    if not climbing: return
    climbing=false
    climb=[]
    collision_mask=1
    jumps_used=1
func climb_step(delta: float,can_move: bool):
    var dir=0.0
    if can_move: dir=(1.0 if Input.is_action_pressed("move_down") else 0.0)-(1.0 if Input.is_action_pressed("interact") else 0.0)
    position.y+=dir*CLIMB_SPEED*delta
    position.x=climb[0]
    if position.y<=climb[1]:
        position.y=climb[1]-1
        stop_climbing()
        jumps_used=0
        return
    if position.y>=climb[2]:
        position.y=climb[2]-1
        stop_climbing()
        jumps_used=0
        return
    if can_move and Input.is_action_just_pressed("jump"):
        var side=Input.get_axis("move_left","move_right")
        if side!=0:
            stop_climbing()
            facing=int(sign(side))
            velocity=Vector2(side*230,-300)
func _physics_process(delta):
    update_dropped_platforms(delta)
    hurt_timer = maxf(0, hurt_timer-delta)
    attack_timer = maxf(0, attack_timer-delta)
    damage_recoil=maxf(0,damage_recoil-delta)
    stun_time=maxf(0,stun_time-delta)
    status_immunity=maxf(0,status_immunity-delta)
    var stats=state.derived_stats() if state!=null else {"speed":0.0,"jump":0.0}
    var flash_jump=state.bonus("flash_jump") if state!=null else 0.0
    var can_move=movement_enabled and stun_time<=0
    var down=Input.is_action_pressed("move_down") if InputMap.has_action("move_down") else Input.is_physical_key_pressed(KEY_DOWN)
    var drop_chord=can_move and not climbing and is_on_floor() and down and Input.is_action_just_pressed("jump")
    var dropping_now=request_drop_through() if drop_chord else false
    if climbing and can_move and down and Input.is_action_just_pressed("jump"):
        stop_climbing()
        request_drop_through()
        velocity.y=140
        jump_buffer=0
        drop_chord=true
        dropping_now=true
    if climbing:
        if state!=null:
            visual.appearance=appearance_for(state)
            visual.looks=state.looks
            visual.set_equipment(state.equipment.weapon)
            visual.set_worn(state)
        visual.climb_kind=climb[3]
        climb_step(delta,can_move)
        if climbing:
            visual.set_pose("climb",facing,Time.get_ticks_msec()/1000.0)
            visual.walk_phase=position.y/40.0
            return
    elif can_move and InputMap.has_action("move_down") and Input.is_action_pressed("move_down") and is_on_floor() and not drop_chord:
        var below=climb_at(1)
        if not below.is_empty():
            start_climbing(below)
            return
    elif can_move and Input.is_action_pressed("interact") and (Input.is_action_just_pressed("interact") or not is_on_floor()):
        var above=climb_at(-1)
        if not above.is_empty() and not near_portal():
            start_climbing(above)
            return
    var direction = Input.get_axis("move_left", "move_right") if can_move else 0.0
    if direction != 0: facing = int(sign(direction))
    if is_on_floor() and not dropping_now:
        coyote = 0.10
        jumps_used = 0
    else:
        coyote = maxf(0, coyote-delta)
        velocity.y += 1100 * delta
    if can_move and Input.is_action_just_pressed("jump") and not drop_chord: request_jump()
    if jump_buffer > 0:
        if is_on_floor() or coyote > 0:
            velocity.y = -420*(1.0+stats.jump)
            jumps_used = 1
            coyote = 0
            jump_buffer = 0
        elif jumps_used < 2 or flash_jump>0 and jumps_used<3:
            velocity.y = -360*(1.0+stats.jump)*(0.75 if jumps_used==2 else 1.0)
            jumps_used += 1
            boost_timer = 0.22*maxf(1.0,flash_jump)
            jump_buffer = 0
        else: jump_buffer = maxf(0, jump_buffer-delta)
    var finishing_lunge=lunge_time>0 and lunge_time<=delta
    if lunge_time > 0:
        # Account for the remaining fraction so travel does not vary with frame rate.
        velocity.x=lunge_direction*lunge_speed*minf(delta,lunge_time)/delta
        lunge_time=maxf(0,lunge_time-delta)
        facing=lunge_direction
    elif boost_timer > 0:
        boost_timer -= delta
        velocity.x = facing * 320*maxf(1.0,flash_jump)
    else: velocity.x = move_toward(velocity.x, direction * 220*(1.0+stats.speed), 1600 * delta)
    move_and_slide()
    if finishing_lunge: velocity.x=0
    if movement_enabled:
        if Input.is_action_just_pressed("interact") and stun_time<=0: interact_requested.emit()
        if state!=null and InputMap.has_action("potion_hp") and Input.is_action_just_pressed("potion_hp"): state.use_potion("hp")
        if state!=null and InputMap.has_action("potion_mp") and Input.is_action_just_pressed("potion_mp"): state.use_potion("mp")
        if combat != null:
            if Input.is_action_pressed("attack"): combat.begin_attack(state.basic_skill())
            # Skills on any key; holding an attack skill keeps using it.
            for code in state.keys:
                var action="key_%d" % code
                if not InputMap.has_action(action): continue
                var id=state.keys[code]
                if Input.is_action_just_pressed(action) or Catalog.skill(id).kind=="attack" and Input.is_action_pressed(action):
                    combat.begin_attack(id)
    var pose = "idle"
    if not is_on_floor(): pose = "jump"
    elif absf(velocity.x) > 15: pose = "run"
    if attack_timer > 0 or combat!=null and combat.active!="": pose = "attack"
    elif damage_recoil>0 or stun_time>0: pose="hurt"
    if combat!=null and combat.active!="":
        visual.attack_style=combat.active
        visual.set_attack_clock(combat.elapsed,combat.swing_end,combat.windup)
    else: visual.attack_elapsed=-1.0
    if state!=null and state.bonus("invisible")>0: visual.modulate.a = 0.3
    elif hurt_timer > 0 and int(hurt_timer*12)%2 == 0: visual.modulate.a = 0.55
    else: visual.modulate.a = 1
    var visual_facing=combat.attack_facing if combat!=null and combat.active!="" else facing
    if state!=null:
        visual.appearance=appearance_for(state)
        visual.looks=state.looks
        visual.set_equipment(state.equipment.weapon)
        visual.set_worn(state)
    if pose=="run": walk_phase+=absf(velocity.x)*delta/150.0
    else: walk_phase=0.0
    visual.walk_phase=walk_phase
    visual.set_pose(pose, visual_facing, Time.get_ticks_msec()/1000.0)
func near_portal() -> bool:
    var map=get_parent().get("map") if get_parent()!=null else null
    if map==null: return false
    for portal in map.portals:
        if global_position.distance_to(portal.position)<90: return true
    return false
static func appearance_for(character) -> String:
    match character.archetype:
        "thief": return "thief"
        "magician": return "mage"
        "bowman": return "archer"
    return "spear" if character.weapon_type()=="spear" else "sword"
# Incoming damage pipeline: hidden/immune -> evade -> block -> reductions -> MP/coin
# soaks -> reflect -> knock-back resistance -> revive.
func receive_damage(amount: int, impulse: Vector2, source=null) -> bool:
    if state == null or hurt_timer > 0 or state.hp <= 0 or amount<=0: return false
    if state.bonus("invisible")>0 or state.bonus("invincible")>0: return false
    var stats=state.derived_stats()
    if source!=null and is_instance_valid(source) and source.has_method("has_status") and source.has_status("blind") and randf()<0.4 or randf()<stats.avoid:
        hurt_timer=0.5
        evaded.emit("MISS")
        return false
    if randf()<state.bonus("block"):
        hurt_timer=0.5
        evaded.emit("BLOCK")
        return false
    var incoming=float(maxi(1,amount-int(stats.defense)))*(1.0-stats.damage_reduction)
    var reflect=state.bonus("reflect")
    if reflect>0 and source!=null and is_instance_valid(source) and source.has_method("receive_hit") and not source.dead:
        var back=maxi(1,int(amount*reflect*4))
        if source.receive_hit(back,Vector2.ZERO,randi()):
            var fx=get_tree().get_first_node_in_group("combat_effects")
            if fx!=null: fx.show_damage(source.global_position+Vector2(0,-45),back,false)
        incoming*=1.0-reflect*0.5
    var guard=state.bonus("magic_guard")
    if guard>0:
        var soak=minf(incoming*guard,state.mp)
        state.mp-=soak
        incoming-=soak
    var coin_guard=state.bonus("meso_guard")
    if coin_guard>0:
        var soak=incoming*coin_guard
        var cost=int(ceil(soak*0.5))
        if state.coins>=cost:
            state.coins-=cost
            incoming-=soak
    var previous_hp=state.hp
    state.hp = maxf(0, state.hp-maxi(1,int(incoming)))
    lunge_time=0
    hurt_timer = 0.8
    damage_recoil=0.16
    if randf()>=state.bonus("knockback_resist"): apply_knockback(impulse)
    if state.hp<=0 and state.bonus("revive")>0:
        for id in state.buffs.keys():
            if Catalog.skill(id).get("stats",{}).has("revive"): state.remove_buff(id)
        state.hp=state.derived_stats().max_hp*0.5
        evaded.emit("REBIRTH")
    state.changed.emit()
    damaged.emit(ceili(previous_hp-state.hp))
    if state.hp <= 0: died.emit()
    return true
