extends CharacterBody2D
const EnemyStats=preload("res://data/enemy_stats.gd")
const MobArt=preload("res://visuals/mob_art.gd")
const STATUS_TINTS={"poison":Color("9be36b"),"freeze":Color("8fd6ff"),"stun":Color("f6ef7a"),"slow":Color("a0b8ff"),"seal":Color("c9a4ff"),"doom":Color("9a9a9a"),"weaken":Color("ff9a9a"),"armor_break":Color("ffb35c"),"web":Color("6a5a8a"),"blind":Color("3a3a4a"),"taunt":Color("ff6b6b")}
const ELEMENT_COLORS={"fire":Color("ff8a4c"),"ice":Color("8fd6ff"),"lightning":Color("f6ef7a"),"poison":Color("9be36b"),"arcane":Color("c9a4ff"),"fruit":Color("f2c94c"),"bone":Color("e8e0c8")}
var level=0
var hp=40
var max_hp=40
var is_heavy=false
var definition_id="mossling"
var profile={}
var behavior="walker"
var spawn_position=Vector2.ZERO
var attack_timer=1.5
var telegraph=0.0
var hurt_flash=0.0
var facing=1
var last_source=-1
var dead=false
var stolen=false
var player
var sprite: Sprite2D
var statuses={}
var poison_tick=1.0
var poison_damage=1
var hop_timer=1.0
var charge_time=0.0
var charge_windup=0.0
var charge_cooldown=2.0
var age=0.0
signal defeated(position: Vector2, definition_id: String)
func _ready():
    profile=EnemyStats.profile(definition_id)
    level=profile.level if level<=0 else clampi(level,1,200)
    behavior=profile.get("behavior","walker")
    hp=profile.hp
    max_hp=profile.hp
    if behavior=="tank": is_heavy=true
    add_to_group("enemies")
    collision_layer=4
    collision_mask=0 if behavior=="flyer" else 1
    spawn_position=position
    var shape=CollisionShape2D.new()
    var capsule=CapsuleShape2D.new()
    var size=profile.get("size",1.0)
    capsule.radius=18*clampf(size,0.8,1.6)
    capsule.height=36*clampf(size,0.8,1.6)
    shape.shape=capsule
    shape.position.y=-capsule.height/2-(26 if behavior=="flyer" else 0)
    add_child(shape)
    attack_timer=randf_range(0.8,1.8)
    if profile.get("sprite",false): build_sprite()
func build_sprite():
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
    add_child(sprite)
# ---------------- Status effects ----------------
func has_status(id: String) -> bool: return statuses.get(id,0.0)>0
func immune_to(id: String) -> bool:
    return is_heavy and EnemyStats.is_boss(definition_id) and id in ["stun","freeze","doom","seal","web"]
func apply_status(id: String,time: float,strength: int=1):
    if dead or immune_to(id): return
    statuses[id]=maxf(statuses.get(id,0.0),time)
    if id=="poison": poison_damage=maxi(poison_damage,strength)
    if id in ["stun","freeze"]: telegraph=0.0
    queue_redraw()
func tick_statuses(delta: float):
    for id in statuses.keys():
        statuses[id]-=delta
        if statuses[id]<=0: statuses.erase(id)
    if has_status("poison"):
        poison_tick-=delta
        if poison_tick<=0:
            poison_tick=1.0
            var amount=mini(poison_damage,hp-1)
            if amount>0:
                hp-=amount
                var fx=get_tree().get_first_node_in_group("combat_effects")
                if fx!=null: fx.add_number(global_position+Vector2(0,-50),str(amount),false,false,false,Color("9be36b"))
func immobile() -> bool: return has_status("stun") or has_status("freeze")
func can_attack() -> bool: return not immobile() and not has_status("seal") and not has_status("doom")
func damage_taken_multiplier() -> float:
    return (1.25 if has_status("armor_break") else 1.0)*(1.3 if has_status("taunt") else 1.0)
func xp_multiplier() -> float: return 1.3 if has_status("taunt") else 1.0
func speed_multiplier() -> float:
    if has_status("web") or immobile(): return 0.0
    return (0.5 if has_status("slow") else 1.0)*(0.6 if has_status("doom") else 1.0)
# ---------------- Behaviour ----------------
func player_hidden() -> bool:
    return player!=null and is_instance_valid(player) and player.state!=null and player.state.bonus("invisible")>0
func lure_x(default_x: float) -> float:
    for decoy in get_tree().get_nodes_in_group("decoys"):
        if absf(decoy.global_position.x-global_position.x)<420: return decoy.global_position.x
    return default_x
func _physics_process(delta):
    if dead: return
    age+=delta
    tick_statuses(delta)
    hurt_flash=maxf(0,hurt_flash-delta)
    attack_timer=maxf(0,attack_timer-delta*(0.5 if has_status("slow") else 1.0))
    charge_cooldown=maxf(0,charge_cooldown-delta)
    if behavior=="flyer": fly(delta)
    else: walk(delta)
    try_contact_damage()
    update_sprite()
    queue_redraw()
func walk(delta):
    if not is_on_floor(): velocity.y+=1100*delta
    if player!=null and is_instance_valid(player):
        var distance=player.global_position-global_position
        if not immobile(): facing=int(sign(distance.x)) if absf(distance.x)>1 else facing
        var engage=absf(distance.x)<340 and absf(distance.y)<85 and absf(global_position.x-spawn_position.x)<430 and not player_hidden()
        var target=lure_x(player.global_position.x) if engage else spawn_position.x
        var ranged=behavior=="caster"
        if immobile():
            velocity.x=move_toward(velocity.x,0,900*delta)
        elif charge_time>0:
            charge_time-=delta
            velocity.x=facing*320*speed_multiplier()
        elif charge_windup>0:
            charge_windup-=delta
            velocity.x=move_toward(velocity.x,0,900*delta)
            if charge_windup<=0 and engage: charge_time=0.7
        elif telegraph>0:
            telegraph-=delta
            velocity.x=move_toward(velocity.x,0,600*delta)
            if telegraph<=0 and engage and can_attack(): perform_attack(distance)
        elif engage and can_attack() and behavior=="charger" and charge_cooldown<=0 and absf(distance.x)<260 and absf(distance.x)>60 and is_on_floor():
            charge_windup=0.55
            charge_cooldown=3.5
        elif engage and can_attack() and attack_timer<=0 and (absf(distance.x)<(80 if behavior=="tank" else 52) or ranged):
            telegraph=0.9 if behavior=="tank" else 0.7
            attack_timer=2.3
        else:
            var speed=profile.get("speed",22 if ranged else 42)*speed_multiplier()
            var desired=sign(target-global_position.x)*speed if absf(target-global_position.x)>38 else 0.0
            if ranged and engage and absf(distance.x)<160: desired=-sign(distance.x)*speed
            if behavior=="hopper" and speed_multiplier()>0:
                hop_timer-=delta
                if is_on_floor():
                    velocity.x=move_toward(velocity.x,0,500*delta)
                    if hop_timer<=0 and desired!=0:
                        hop_timer=randf_range(1.0,1.6)
                        velocity=Vector2(sign(desired)*110,-330)
            else: velocity.x=move_toward(velocity.x,desired,180*delta)
    else: velocity.x=move_toward(velocity.x,0,200*delta)
    move_and_slide()
func fly(delta):
    if player==null or not is_instance_valid(player):
        velocity=Vector2.ZERO
        return
    var distance=player.global_position-global_position
    if not immobile(): facing=int(sign(distance.x)) if absf(distance.x)>1 else facing
    var engage=absf(distance.x)<380 and absf(distance.y)<220 and absf(global_position.x-spawn_position.x)<480 and not player_hidden()
    var home=Vector2(lure_x(player.global_position.x),player.global_position.y-80) if engage else spawn_position
    var speed=70.0*speed_multiplier()
    if immobile():
        velocity=Vector2.ZERO
    elif charge_time>0:
        charge_time-=delta
        velocity=(player.global_position+Vector2(0,-20)-global_position).normalized()*260*speed_multiplier()
    elif telegraph>0:
        telegraph-=delta
        velocity=velocity.move_toward(Vector2.ZERO,400*delta)
        if telegraph<=0 and engage and can_attack(): perform_attack(distance)
    elif engage and can_attack() and attack_timer<=0:
        if profile.get("ranged",false): telegraph=0.7
        else: charge_time=0.6
        attack_timer=2.6
    else:
        var to_home=home-global_position+Vector2(sin(age*1.7)*40,sin(age*2.3)*14)
        velocity=to_home.normalized()*minf(speed,to_home.length()*3)
    position+=velocity*delta
    position.y=clampf(position.y,140,620)
func perform_attack(distance: Vector2):
    if behavior=="caster" or behavior=="flyer" and profile.get("ranged",false):
        shoot(attack_damage())
    elif behavior=="tank":
        if absf(distance.x)<95 and absf(distance.y)<60:
            player.receive_damage(attack_damage(1.3),Vector2(facing*170,-110),self)
        var fx=get_tree().get_first_node_in_group("combat_effects")
        if fx!=null: fx.effect_burst(global_position,95,Color(1,0.6,0.3))
    elif absf(distance.x)<65:
        player.receive_damage(attack_damage(),Vector2(facing*110,-70),self)
func shoot(amount: int,angle: float=0.0,origin_offset:=Vector2(0,-25)):
    var projectile=preload("res://world/projectile.gd").new()
    get_parent().add_child(projectile)
    projectile.global_position=global_position+origin_offset
    projectile.direction=(player.global_position+Vector2(0,-25)-projectile.global_position).normalized().rotated(angle)
    projectile.target=player
    projectile.damage=amount
    projectile.source=self
    var element=profile.get("element","")
    if ELEMENT_COLORS.has(element): projectile.color=ELEMENT_COLORS[element]
    return projectile
func attack_damage(multiplier=1.0) -> int:
    var weakened=0.7 if has_status("weaken") else 1.0
    return EnemyStats.damage(definition_id,level,multiplier*weakened)
func try_contact_damage():
    if dead or not is_instance_valid(player) or has_status("doom") or immobile(): return
    var offset=player.global_position-global_position
    var reach=54 if is_heavy else 30
    var height=55 if is_heavy else 42
    if behavior=="flyer": offset.y+=26
    if absf(offset.x)<reach*profile.get("size",1.0) and absf(offset.y)<height:
        player.receive_damage(attack_damage(0.9 if charge_time>0 else 0.6),Vector2((1 if offset.x>=0 else -1)*110,-70),self)
func receive_hit(damage: int,push: Vector2,source: int) -> bool:
    if dead or source==last_source: return false
    last_source=source
    hp=maxi(0,hp-damage)
    hurt_flash=0.15
    if not is_heavy and not immobile(): velocity+=push
    if hp==0:
        dead=true
        defeated.emit(global_position,definition_id)
        queue_free()
    queue_redraw()
    return true
func update_sprite():
    if sprite==null: return
    var lantern=definition_id in ["lantern","briar_lantern"]
    var region=Rect2(806,208,610,735) if lantern else Rect2(91,280,626,626)
    var anchor=Vector2(1100,941) if lantern else Vector2(404,904)
    sprite.region_rect=region
    sprite.flip_h=facing>0 if lantern else facing<0
    var local=anchor-region.position
    sprite.position=Vector2(-(region.size.x-local.x) if sprite.flip_h else -local.x,-local.y)*sprite.scale.x
    sprite.position.y+=sin(Time.get_ticks_msec()/220.0)*1.4
    sprite.material.set_shader_parameter("flash",1.0 if hurt_flash>0 else 0.0)
    sprite.modulate=Color("bfe9ff") if has_status("freeze") else Color("ecb8cd") if definition_id=="thornling" else Color("b7e6f0") if definition_id=="briar_lantern" else Color.WHITE
func art_height() -> float:
    return 60.0*profile.get("size",1.0)+(26 if behavior=="flyer" else 0)
func _draw():
    if sprite==null and not profile.is_empty():
        draw_set_transform(Vector2(0,-26 if behavior=="flyer" else 0))
        MobArt.draw(self,profile,age,facing,hurt_flash/0.15,{"frozen":has_status("freeze"),"doom":has_status("doom")})
        draw_set_transform(Vector2.ZERO)
    var top=-maxf(74,art_height()+14) if sprite==null else -74
    if not is_heavy or not EnemyStats.is_boss(definition_id):
        var caption="Lv %d  %s" % [level,profile.get("name","Monster")]
        var font=ThemeDB.fallback_font
        var start=Vector2(-font.get_string_size(caption,HORIZONTAL_ALIGNMENT_LEFT,-1,12).x/2,top-22)
        draw_string_outline(font,start,caption,HORIZONTAL_ALIGNMENT_LEFT,-1,12,3,Color("243449"))
        draw_string(font,start,caption,HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("fff6cf"))
    if hp<max_hp and not EnemyStats.is_boss(definition_id):
        draw_style_box(health_style(Color("243449")),Rect2(-25,top,50,5))
        draw_rect(Rect2(-25,top,50*float(hp)/max_hp,5),Color("ff827b"))
    var x=-((statuses.size()-1)*7.0)
    for id in statuses:
        draw_circle(Vector2(x,top-30),3.5,STATUS_TINTS.get(id,Color.WHITE))
        x+=14
    if telegraph>0 or charge_windup>0:
        draw_circle(Vector2(0,top-52),10,Color("f7ba63"))
        draw_line(Vector2(0,top-58),Vector2(0,top-52),Color("47354e"),3)
        draw_circle(Vector2(0,top-48),1.5,Color("47354e"))
    if has_status("stun"):
        for i in range(3):
            var a=age*5+i*TAU/3
            draw_circle(Vector2(cos(a)*12,top+4+sin(a)*3),2.5,Color("f6ef7a"))
func health_style(color):
    var style=StyleBoxFlat.new()
    style.bg_color=color
    style.corner_radius_top_left=3
    style.corner_radius_top_right=3
    return style
