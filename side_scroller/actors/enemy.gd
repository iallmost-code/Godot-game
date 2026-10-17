extends CharacterBody2D
const EnemyStats=preload("res://data/enemy_stats.gd")
var level=0
var area_tint=Color.WHITE
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
var sprite: Sprite2D
signal defeated(position: Vector2, definition_id: String)
func _ready():
    level=EnemyStats.profile(definition_id).level if level<=0 else clampi(level,1,100)
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
    if definition_id in ["lantern","briar_lantern"]:
        hp=32
        max_hp=32
    if definition_id=="thornling":
        hp=160
        max_hp=160
    elif definition_id=="briar_lantern":
        hp=100
        max_hp=100
    max_hp=maxi(12,max_hp+12*(level-EnemyStats.profile(definition_id).level))
    hp=max_hp
    sprite=Sprite2D.new()
    sprite.texture=preload("res://art/enemies.png")
    sprite.region_enabled=true
    sprite.region_filter_clip_enabled=true
    sprite.centered=false
    sprite.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
    sprite.scale=Vector2.ONE*(64.0/735.0 if definition_id in ["lantern","briar_lantern"] else 60.0/626.0)
    var shader=Shader.new()
    shader.code="shader_type canvas_item; uniform float flash=0.0; void fragment(){COLOR.rgb=mix(COLOR.rgb,vec3(1.0),flash);}"
    var mat=ShaderMaterial.new()
    mat.shader=shader
    sprite.material=mat
    if definition_id=="thornling": sprite.modulate=Color("ecb8cd")
    elif definition_id=="briar_lantern": sprite.modulate=Color("b7e6f0")
    sprite.modulate*=area_tint
    add_child(sprite)
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
                if definition_id in ["lantern","briar_lantern"]:
                    var projectile=preload("res://world/projectile.gd").new()
                    get_parent().add_child(projectile)
                    projectile.global_position=global_position+Vector2(0,-25)
                    projectile.direction=(player.global_position+Vector2(0,-25)-projectile.global_position).normalized()
                    projectile.target=player
                    projectile.damage=attack_damage()
                elif absf(distance.x)<65:
                    player.receive_damage(attack_damage(),Vector2(facing*110,-70))
        elif engage and attack_timer<=0 and (absf(distance.x)<52 or definition_id in ["lantern","briar_lantern"]):
            telegraph=0.7
            attack_timer=2.3
        else:
            var speed=48 if definition_id=="thornling" else 42 if definition_id=="mossling" else 22
            var desired=sign(target-global_position.x)*speed if absf(target-global_position.x)>38 else 0
            velocity.x=move_toward(velocity.x,desired,180*delta)
    else: velocity.x=move_toward(velocity.x,0,200*delta)
    move_and_slide()
    try_contact_damage()
    if sprite!=null:
        var lantern=definition_id in ["lantern","briar_lantern"]
        var region=Rect2(806,208,610,735) if lantern else Rect2(91,280,626,626)
        var anchor=Vector2(1100,941) if lantern else Vector2(404,904)
        sprite.region_rect=region
        sprite.flip_h=facing>0 if lantern else facing<0
        var local=anchor-region.position
        sprite.position=Vector2(-(region.size.x-local.x) if sprite.flip_h else -local.x,-local.y)*sprite.scale.x
        sprite.position.y+=sin(Time.get_ticks_msec()/220.0)*1.4
        sprite.material.set_shader_parameter("flash",1.0 if hurt_flash>0 else 0.0)
    queue_redraw()
func attack_damage(multiplier=1.0) -> int:
    return EnemyStats.damage(definition_id,level,multiplier)
func try_contact_damage():
    if dead or not is_instance_valid(player): return
    var offset=player.global_position-global_position
    if absf(offset.x)<(54 if is_heavy else 30) and absf(offset.y)<(55 if is_heavy else 42):
        player.receive_damage(attack_damage(0.6),Vector2((1 if offset.x>=0 else -1)*110,-70))
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
    if not is_heavy:
        var caption="Lv %d  %s" % [level,EnemyStats.profile(definition_id).name]
        var font=ThemeDB.fallback_font
        var start=Vector2(-font.get_string_size(caption,HORIZONTAL_ALIGNMENT_LEFT,-1,12).x/2,-96)
        draw_string_outline(font,start,caption,HORIZONTAL_ALIGNMENT_LEFT,-1,12,3,Color("243449"))
        draw_string(font,start,caption,HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("fff6cf"))
    if hp<max_hp:
        draw_style_box(health_style(Color("243449")),Rect2(-25,-74,50,5))
        draw_rect(Rect2(-25,-74,50*float(hp)/max_hp,5),Color("ff827b"))
    if telegraph>0:
        draw_circle(Vector2(0,-125),10,Color("f7ba63"))
        draw_line(Vector2(0,-131),Vector2(0,-125),Color("47354e"),3)
        draw_circle(Vector2(0,-121),1.5,Color("47354e"))
func health_style(color):
    var style=StyleBoxFlat.new()
    style.bg_color=color
    style.corner_radius_top_left=3
    style.corner_radius_top_right=3
    return style
