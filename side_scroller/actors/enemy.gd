extends CharacterBody2D
var hp=40
var max_hp=40
var is_heavy=false
var definition_id="mossling"
var spawn_position=Vector2.ZERO
var attack_timer=1.5
var telegraph=0.0
var hurt_flash=0.0
var facing=1
var last_source=-1
var dead=false
var player
signal defeated(position: Vector2, definition_id: String)
func _ready():
    add_to_group("enemies")
    collision_layer=4
    collision_mask=1
    spawn_position=position
    var shape=CollisionShape2D.new()
    var capsule=CapsuleShape2D.new()
    capsule.radius=18
    capsule.height=36
    shape.shape=capsule
    shape.position.y=-18
    add_child(shape)
    if definition_id=="lantern":
        hp=32
        max_hp=32
func _physics_process(delta):
    if dead: return
    hurt_flash=maxf(0,hurt_flash-delta)
    attack_timer=maxf(0,attack_timer-delta)
    if not is_on_floor(): velocity.y+=1100*delta
    if player!=null and is_instance_valid(player):
        var distance=player.global_position-global_position
        facing=int(sign(distance.x)) if absf(distance.x)>1 else facing
        var engage=absf(distance.x)<340 and absf(distance.y)<85 and absf(global_position.x-spawn_position.x)<430
        var target=player.global_position.x if engage else spawn_position.x
        if telegraph>0:
            telegraph-=delta
            velocity.x=move_toward(velocity.x,0,600*delta)
            if telegraph<=0 and engage:
                if definition_id=="lantern":
                    var projectile=preload("res://world/projectile.gd").new()
                    get_parent().add_child(projectile)
                    projectile.global_position=global_position+Vector2(0,-25)
                    projectile.direction=(player.global_position+Vector2(0,-25)-projectile.global_position).normalized()
                    projectile.target=player
                elif absf(distance.x)<65:
                    player.receive_damage(6,Vector2(facing*110,-70))
        elif engage and attack_timer<=0 and (absf(distance.x)<52 or definition_id=="lantern"):
            telegraph=0.7
            attack_timer=2.3
        else:
            var speed=42 if definition_id=="mossling" else 22
            var desired=sign(target-global_position.x)*speed if absf(target-global_position.x)>38 else 0
            velocity.x=move_toward(velocity.x,desired,180*delta)
    else: velocity.x=move_toward(velocity.x,0,200*delta)
    move_and_slide()
    queue_redraw()
func receive_hit(damage: int,push: Vector2,source: int) -> bool:
    if dead or source==last_source: return false
    last_source=source
    hp=maxi(0,hp-damage)
    hurt_flash=0.15
    if not is_heavy: velocity+=push
    if hp==0:
        dead=true
        defeated.emit(global_position,definition_id)
        queue_free()
    queue_redraw()
    return true
func _draw():
    var bob=sin(Time.get_ticks_msec()/220.0)*2
    var color=Color("8abc6c") if definition_id=="mossling" else Color("c1a0e0")
    if hurt_flash>0: color=Color.WHITE
    draw_set_transform(Vector2(0,-20+bob),0,Vector2(23,19))
    draw_circle(Vector2.ZERO,1,color)
    draw_set_transform(Vector2.ZERO)
    if definition_id=="mossling":
        for side in [-1,1]:
            draw_colored_polygon(PackedVector2Array([Vector2(side*12,-30),Vector2(side*24,-48),Vector2(side*4,-40)]),Color("527e54"))
        draw_circle(Vector2(-8,-36),7,Color("a8d67e"))
        draw_circle(Vector2(7,-36),9,Color("a8d67e"))
    else:
        for x in [-18,0,18]:
            draw_set_transform(Vector2(x,-38),x*0.025,Vector2(10,17))
            draw_circle(Vector2.ZERO,1,Color("8263bd"))
            draw_set_transform(Vector2.ZERO)
        draw_circle(Vector2(0,-38),9,Color("ffe5a2"))
    for side in [-1,1]:
        draw_circle(Vector2(side*8+facing*2,-20+bob),3,Color("253b43"))
        draw_circle(Vector2(side*8+facing*2-1,-21+bob),1,Color.WHITE)
        draw_line(Vector2(side*13,-3),Vector2(side*22,-3),Color("425d57"),5)
    draw_line(Vector2(-3,-12+bob),Vector2(3,-12+bob),Color("425d57"),2)
    if hp<max_hp:
        draw_style_box(health_style(Color("243449")),Rect2(-25,-58,50,5))
        draw_rect(Rect2(-25,-58,50*float(hp)/max_hp,5),Color("ff827b"))
    if telegraph>0:
        draw_circle(Vector2(0,-67),10,Color("f7ba63"))
        draw_line(Vector2(0,-73),Vector2(0,-67),Color("47354e"),3)
        draw_circle(Vector2(0,-63),1.5,Color("47354e"))
func health_style(color):
    var style=StyleBoxFlat.new()
    style.bg_color=color
    style.corner_radius_top_left=3
    style.corner_radius_top_right=3
    return style
