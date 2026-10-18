extends "res://actors/enemy.gd"
# Data-driven boss: cycles through telegraphed patterns from its profile and
# speeds up below half health.
const LABELS={"slam":"SLAM — JUMP!","volley":"VOLLEY!","rain":"LOOK UP!","beam":"LOW SWEEP — JUMP!","summon":"MINIONS!","charge":"CHARGE!"}
var phase="idle"
var pattern="slam"
var pattern_index=0
var windup=0.0
var recovery=2.0
var flash=0.0
var flash_kind=""
var enraged=false
var stage=1
var rain_marks: Array=[]
func _ready():
    super._ready()
    is_heavy=true
    facing=-1
    var size=profile.get("size",3.0)
    for child in get_children():
        if child is CollisionShape2D:
            child.shape.radius=16*size
            child.shape.height=maxf(child.shape.radius*2,34*size)
            child.position.y=-child.shape.height/2
    collision_mask=1
func slam_radius() -> float: return 60.0*profile.get("size",3.0)*(1.0+0.08*(stage-1))
func start_pattern():
    var patterns: Array=profile.get("patterns",["slam"])
    pattern=patterns[pattern_index%patterns.size()]
    pattern_index+=1
    if pattern=="summon" and get_tree().get_nodes_in_group("boss_minions").size()>=5:
        pattern="slam"
    phase="windup"
    var warning_sound=get_tree().get_first_node_in_group("soundscape")
    if warning_sound!=null:warning_sound.play_effect("warning")
    windup=maxf(0.65,(1.0 if pattern in ["slam","beam"] else 0.8)*(1.0-0.12*(stage-1)))
    velocity.x=0
    if pattern=="rain":
        rain_marks.clear()
        for i in range(2+stage*2):
            rain_marks.append(player.global_position.x+randf_range(-280,280) if is_instance_valid(player) else global_position.x)
func resolve_pattern():
    if player==null or not is_instance_valid(player): return
    var offset=player.global_position-global_position
    var grounded=offset.y>=-30 and absf(offset.y)<70
    match pattern:
        "slam":
            flash=0.35
            flash_kind="slam"
            if absf(offset.x)<slam_radius() and grounded:
                if player.receive_damage(attack_damage(1.5),Vector2(facing*200,-140),self): player.apply_stun(0.9)
        "beam":
            flash=0.4
            flash_kind="beam"
            if absf(offset.x)<620 and grounded: player.receive_damage(attack_damage(1.3),Vector2(facing*160,-100),self)
        "volley":
            for angle in ([-0.36,-0.24,-0.12,0.0,0.12,0.24,0.36] if stage==3 else [-0.3,-0.15,0.0,0.15,0.3] if stage==2 else [-0.22,0.0,0.22]):
                var shot=shoot(attack_damage(0.8),angle,Vector2(0,-30*profile.get("size",3.0)))
                shot.speed=230
        "rain":
            for x in rain_marks:
                var drop=preload("res://world/projectile.gd").new()
                get_parent().add_child(drop)
                drop.global_position=Vector2(x,player.global_position.y-460)
                drop.direction=Vector2.DOWN
                drop.speed=420
                drop.target=player
                drop.damage=attack_damage(0.9)
                drop.source=self
                drop.color=Color(profile.get("accent",Color("ff8a4c")))
            rain_marks.clear()
        "summon":
            var map=get_parent()
            var minion=profile.get("minion","")
            if minion!="" and map.has_method("spawn_minion"):
                for side in [-1,1]: map.spawn_minion(minion,global_position+Vector2(side*120,-10))
        "charge":
            charge_time=0.8+stage*0.1
func _physics_process(delta):
    if dead: return
    age+=delta
    tick_statuses(delta)
    hurt_flash=maxf(0,hurt_flash-delta)
    flash=maxf(0,flash-delta)
    if not is_on_floor(): velocity.y+=1100*delta
    update_stage()
    var engage=false
    if player!=null and is_instance_valid(player):
        var distance=player.global_position-global_position
        engage=absf(distance.x)<620 and absf(distance.y)<240 and absf(position.x-spawn_position.x)<520 and not player_hidden()
        if absf(distance.x)>4 and phase!="windup" and charge_time<=0: facing=int(sign(distance.x))
        if charge_time>0:
            charge_time-=delta
            velocity.x=facing*(350+stage*30)*speed_multiplier()
        elif phase=="windup":
            windup=maxf(0,windup-delta)
            velocity.x=0
            if windup<=0:
                resolve_pattern()
                phase="recover"
                recovery=2.4-(stage-1)*0.35
        elif phase=="recover":
            velocity.x=move_toward(velocity.x,0,600*delta)
            recovery=maxf(0,recovery-delta)
            if recovery<=0: phase="idle"
        elif engage and can_attack():
            start_pattern()
        elif engage:
            velocity.x=0
        else:
            velocity.x=sign(spawn_position.x-position.x)*30 if absf(position.x-spawn_position.x)>10 else 0.0
        if phase=="idle" and engage and absf(distance.x)>140: velocity.x=sign(distance.x)*30*speed_multiplier()
    move_and_slide()
    try_contact_damage()
    queue_redraw()
func try_contact_damage():
    if dead or not is_instance_valid(player) or has_status("doom"): return
    var offset=player.global_position-global_position
    var size=profile.get("size",3.0)
    if absf(offset.x)<18*size and offset.y>-40*size and offset.y<20:
        player.receive_damage(attack_damage(1.1 if charge_time>0 else 0.45),Vector2((1 if offset.x>=0 else -1)*160,-90),self)
func art_height() -> float: return 60.0*profile.get("size",3.0)*(1.0+0.08*(stage-1))
func _draw():
    var boss_profile=profile.duplicate()
    boss_profile["boss"]=true
    var shake=Vector2(sin(age*40)*2,0) if phase=="windup" else Vector2.ZERO
    var painted=preload("res://visuals/boss_layout.gd")
    if not painted.draw(self,definition_id,phase=="windup" or flash>0 or charge_time>0,facing,hurt_flash/0.15,has_status("freeze"),shake):
        draw_set_transform(shake)
        MobArt.draw(self,boss_profile,age,facing,hurt_flash/0.15,{"frozen":has_status("freeze")})
    draw_set_transform(Vector2.ZERO)
    var radius=slam_radius()
    if phase=="windup" and pattern=="charge":
        var length=((350+stage*30)*(.8+stage*.1)+18*profile.get("size",3.0))*facing
        draw_rect(Rect2(minf(0,length),-22,absf(length),20),Color(1,.42,.2,.25))
        for i in range(6):
            var x=facing*(35+i*65)
            draw_polyline(PackedVector2Array([Vector2(x,-20),Vector2(x+facing*16,-12),Vector2(x,-4)]),Color("ffd59e"),3,true)
    if phase=="windup" and pattern in ["volley","summon"]:
        draw_arc(Vector2(0,-art_height()*.45),36,0,TAU,40,Color("ffd59e"),3,true)
    if phase=="windup" and pattern=="slam" or flash>0 and flash_kind=="slam":
        draw_set_transform(Vector2(0,-2),0,Vector2(1,0.14))
        draw_circle(Vector2.ZERO,radius,Color(1,0.35,0.22,0.24 if phase=="windup" else flash))
        draw_arc(Vector2.ZERO,radius,0,TAU,64,Color("ffd59e"),3,true)
        draw_set_transform(Vector2.ZERO)
    if phase=="windup" and pattern=="beam" or flash>0 and flash_kind=="beam":
        var alpha=0.25 if phase=="windup" else flash*2
        draw_rect(Rect2(-620,-26,1240,22),Color(1,0.45,0.3,alpha))
        draw_line(Vector2(-620,-15),Vector2(620,-15),Color(1,0.85,0.6,alpha+0.2),2)
    for x in rain_marks:
        var local=Vector2(x-global_position.x,-4)
        draw_circle(local,18,Color(1,0.3,0.25,0.25+0.15*sin(age*12)))
    if phase=="windup":
        var text=LABELS.get(pattern,"")
        var top=-art_height()-40
        draw_string_outline(ThemeDB.fallback_font,Vector2(-90,top),text,HORIZONTAL_ALIGNMENT_LEFT,-1,20,4,Color("282031"))
        draw_string(ThemeDB.fallback_font,Vector2(-90,top),text,HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color("ffdcac"))
    if has_status("poison") or has_status("armor_break") or has_status("weaken"):
        var x=-((statuses.size()-1)*7.0)
        for id in statuses:
            draw_circle(Vector2(x,-art_height()-12),4,STATUS_TINTS.get(id,Color.WHITE))
            x+=14

func update_stage():
    var next_stage=3 if hp<=max_hp*.35 else 2 if hp<=max_hp*.60 else 1
    if next_stage<=stage:return
    stage=next_stage
    enraged=stage>=2
    var fx=get_tree().get_first_node_in_group("combat_effects")
    if fx!=null:fx.add_number(global_position+Vector2(0,-40-art_height()),"PHASE %d!" % stage,true,true)
    var sound=get_tree().get_first_node_in_group("soundscape")
    if sound!=null:sound.play_effect("warning")
