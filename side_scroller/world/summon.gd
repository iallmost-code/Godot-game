extends Node2D
# A summoned ally: follows the player and periodically strikes nearby monsters,
# or (decoy) stands still and lures monsters away.
const Catalog=preload("res://data/catalog.gd")
var skill_id=""
var combat
var player
var config={}
var rank=1
var max_rank=1
var lifetime=60.0
var timer=0.8
var age=0.0
var strikes: Array=[]
func _ready():
    z_index=6
    add_to_group("summons")
    if config.get("decoy",false): add_to_group("decoys")
func value(key: String,fallback=0.0) -> float:
    if not config.has(key): return fallback
    return Catalog.value(config[key],rank,max_rank)
func _process(delta):
    age+=delta
    lifetime-=delta
    if lifetime<=0 or player==null or not is_instance_valid(player) or combat==null or combat.state.hp<=0:
        queue_free()
        return
    if config.get("follow",true):
        var target=player.global_position+Vector2(-player.facing*55,-78+sin(age*3)*6)
        global_position=global_position.lerp(target,minf(1,delta*5)) if global_position.distance_to(target)<500 else target
    for strike in strikes.duplicate():
        strike.age+=delta
        if strike.age>0.18: strikes.erase(strike)
    timer-=delta
    if timer<=0:
        timer=value("interval",3.0)
        act()
    queue_redraw()
func act():
    var state=combat.state
    if config.get("style","")=="beholder":
        var heal=state.bonus("beholder_heal")
        if heal>0:
            var amount=heal*state.derived_stats().max_hp
            state.hp=minf(state.derived_stats().max_hp,state.hp+amount)
            combat.effect_requested.emit("heal",{"position":player.global_position,"amount":int(amount)})
        var power=state.bonus("beholder_power")
        if power<=0: return
        strike_targets(power,3,300)
        return
    var power_value=value("power")
    if power_value<=0: return
    strike_targets(power_value,int(value("targets",1)),value("reach",300))
func strike_targets(power: float,cap: int,reach: float):
    var found: Array=[]
    for e in get_tree().get_nodes_in_group("enemies"):
        if e.hp>0 and e.global_position.distance_to(global_position)<reach: found.append(e)
    found.sort_custom(func(a,b): return a.global_position.distance_to(global_position)<b.global_position.distance_to(global_position))
    for e in found.slice(0,cap):
        strikes.append({"target":e.global_position+Vector2(0,-30),"age":0.0})
        combat.apply_hit(e,skill_id,rank,power)
        if config.has("status") and is_instance_valid(e) and e.hp>0 and randf()<float(config.status.chance):
            e.apply_status(config.status.id,float(config.status.time),maxi(1,int(combat.state.derived_stats().attack*0.25)))
func _draw():
    var color=Color(config.get("color","ffffff"))
    var flap=sin(age*12)
    var art=preload("res://visuals/attack_art.gd")
    if art.SUMMONS.has(skill_id):
        var data=art.SUMMONS[skill_id]
        var dimensions=data.rect.size*(float(data.height)/data.rect.size.y)
        var decoy=config.get("decoy",false)
        var facing=player.facing if is_instance_valid(player) else 1
        var offset=Vector2(0,0 if decoy else 12)
        draw_set_transform(offset,0 if decoy else sin(age*5)*0.035,Vector2(facing,1 if decoy else 1+flap*0.025))
        draw_texture_rect_region(art.SUMMON_ART,Rect2(Vector2(-dimensions.x/2,-dimensions.y),dimensions),data.rect)
        draw_set_transform(Vector2.ZERO)
    else:
        match config.get("style",""):
            "puppet":
                draw_line(Vector2(0,0),Vector2(0,-60),Color("6b4a2c"),5)
                draw_line(Vector2(-22,-42),Vector2(22,-42),Color("6b4a2c"),4)
                draw_circle(Vector2(0,-66),11,Color("e8d29a"))
                draw_rect(Rect2(-12,-48,24,26),Color("b2563f"))
                draw_line(Vector2(-5,-69),Vector2(-2,-66),Color("3a2a20"),2)
                draw_line(Vector2(5,-69),Vector2(2,-66),Color("3a2a20"),2)
            "beholder":
                draw_circle(Vector2.ZERO,16,color.darkened(0.3))
                draw_circle(Vector2.ZERO,12,Color("efe6ff"))
                draw_circle(Vector2(2,0),6,Color("d23d5c"))
                draw_circle(Vector2(2,0),3,Color("1b1020"))
                for i in range(5):
                    var angle=PI+i*0.6-1.2+sin(age*4+i)*0.15
                    draw_line(Vector2.ZERO,Vector2(cos(angle),sin(angle))*28,color,3,true)
            "spirit":
                draw_circle(Vector2.ZERO,18,Color(color,0.25))
                draw_circle(Vector2.ZERO,11,Color(color,0.8))
                draw_circle(Vector2(-4,-3),2.5,Color.WHITE)
                draw_circle(Vector2(4,-3),2.5,Color.WHITE)
                draw_colored_polygon(PackedVector2Array([Vector2(-9,6),Vector2(9,6),Vector2(0,26+flap*3)]),Color(color,0.6))
            "dragon":
                var big=1.4 if skill_id=="bahamut" else 1.0
                draw_set_transform(Vector2.ZERO,0,Vector2(big*(-1 if player.facing<0 else 1),big))
                draw_colored_polygon(PackedVector2Array([Vector2(-8,-4),Vector2(-26,-18-flap*6),Vector2(-14,2)]),color.darkened(0.15))
                draw_colored_polygon(PackedVector2Array([Vector2(8,-4),Vector2(24,-20-flap*6),Vector2(14,2)]),color.darkened(0.15))
                draw_circle(Vector2.ZERO,10,color)
                draw_circle(Vector2(12,-6),7,color)
                draw_circle(Vector2(15,-8),1.8,Color("2a1c10"))
                draw_line(Vector2(-10,4),Vector2(-24,12),color,4,true)
                draw_set_transform(Vector2.ZERO)
            _:
                draw_set_transform(Vector2.ZERO,0,Vector2(-1 if player.facing<0 else 1,1))
                draw_colored_polygon(PackedVector2Array([Vector2(-4,0),Vector2(-24,-12-flap*8),Vector2(-10,4)]),color.darkened(0.1))
                draw_colored_polygon(PackedVector2Array([Vector2(4,0),Vector2(22,-14-flap*8),Vector2(10,4)]),color.darkened(0.1))
                draw_circle(Vector2.ZERO,8,color)
                draw_circle(Vector2(9,-4),5,color)
                draw_colored_polygon(PackedVector2Array([Vector2(13,-5),Vector2(19,-3),Vector2(13,-1)]),Color("e8a43a"))
                draw_circle(Vector2(10,-5),1.4,Color("1b1020"))
                draw_set_transform(Vector2.ZERO)
    for strike in strikes:
        draw_line(Vector2.ZERO,to_local(strike.target),Color(color,1.0-strike.age/0.18),3,true)
    if lifetime<5: modulate.a=0.5+0.5*sin(age*14)
