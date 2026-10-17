extends "res://actors/enemy.gd"
const ART=preload("res://art/rootwarden.png")
var phase="idle"
var attack_kind="slam"
var windup=0.0
var recovery=1.2
var slam_flash=0.0
var attack_index=0
func _ready():
    definition_id="rootwarden"
    super._ready()
    is_heavy=true
    hp=2600
    max_hp=2600
    facing=-1
    for child in get_children():
        if child is CollisionShape2D:
            child.shape.radius=40
            child.shape.height=96
            child.position.y=-48
    sprite.texture=ART
    sprite.region_enabled=false
    sprite.scale=Vector2.ONE*(150.0/955.0)
    update_art()
func start_attack(kind: String):
    if dead: return
    attack_kind=kind
    phase="windup"
    windup=0.95 if kind=="slam" else 0.8
    velocity.x=0
func resolve_attack():
    if player==null or not is_instance_valid(player): return
    if attack_kind=="slam":
        slam_flash=0.35
        var offset=player.global_position-global_position
        if absf(offset.x)<170 and offset.y>=-30 and absf(offset.y)<60:
            if player.receive_damage(attack_damage(1.4),Vector2(facing*190,-130),self): player.apply_stun(0.8)
    else:
        for angle in [-0.22,0.0,0.22]:
            var seed=preload("res://world/projectile.gd").new()
            seed.target=player
            seed.damage=attack_damage(0.75)
            seed.source=self
            seed.speed=220
            get_parent().add_child(seed)
            seed.global_position=global_position+Vector2(0,-65)
            seed.direction=(player.global_position+Vector2(0,-26)-seed.global_position).normalized().rotated(angle)
func _physics_process(delta):
    if dead: return
    tick_statuses(delta)
    hurt_flash=maxf(0,hurt_flash-delta)
    slam_flash=maxf(0,slam_flash-delta)
    if not is_on_floor(): velocity.y+=1100*delta
    var engage=false
    if player!=null and is_instance_valid(player):
        var distance=player.global_position-global_position
        engage=absf(distance.x)<580 and absf(distance.y)<200 and absf(position.x-spawn_position.x)<420 and not player_hidden()
        if absf(distance.x)>4: facing=int(sign(distance.x))
        if phase=="windup":
            windup=maxf(0,windup-delta)
            velocity.x=0
            if windup<=0:
                resolve_attack()
                phase="recover"
                recovery=1.5
        elif phase=="recover":
            velocity.x=0
            recovery=maxf(0,recovery-delta)
            if recovery<=0: phase="idle"
        elif engage:
            recovery=maxf(0,recovery-delta)
            if recovery<=0:
                start_attack("slam" if attack_index%2==0 else "volley")
                attack_index+=1
            else: velocity.x=sign(distance.x)*24 if absf(distance.x)>120 else 0.0
        else:
            velocity.x=sign(spawn_position.x-position.x)*28 if absf(position.x-spawn_position.x)>10 else 0.0
    move_and_slide()
    try_contact_damage()
    update_art()
    queue_redraw()
func update_art():
    if sprite==null: return
    var factor=150.0/955.0
    sprite.flip_h=facing>0
    sprite.position=Vector2(-(ART.get_width()-701) if sprite.flip_h else -701,-1042)*factor
    if phase=="windup": sprite.position.y+=sin(windup*7)*3
    sprite.material.set_shader_parameter("flash",1.0 if hurt_flash>0 else 0.0)
func _draw():
    if phase=="windup" and attack_kind=="slam" or slam_flash>0:
        draw_set_transform(Vector2(0,-2),0,Vector2(1,0.14))
        draw_circle(Vector2.ZERO,170,Color(1,0.35,0.22,0.24 if phase=="windup" else slam_flash))
        draw_arc(Vector2.ZERO,170,0,TAU,64,Color("ffd59e"),3,true)
        draw_set_transform(Vector2.ZERO)
    if phase=="windup":
        draw_string_outline(ThemeDB.fallback_font,Vector2(-80,-165),"SLAM — JUMP!" if attack_kind=="slam" else "SEED VOLLEY!",HORIZONTAL_ALIGNMENT_LEFT,-1,19,4,Color("282031"))
        draw_string(ThemeDB.fallback_font,Vector2(-80,-165),"SLAM — JUMP!" if attack_kind=="slam" else "SEED VOLLEY!",HORIZONTAL_ALIGNMENT_LEFT,-1,19,Color("ffdcac"))
