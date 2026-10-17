extends Node2D
# A pet that trails the player and fetches nearby loot.
const Adventure=preload("res://data/adventure.gd")
var pet_id="puppy"
var player
var map
var target=null
var age=0.0
var facing=1
var hop=0.0
func _process(delta):
    age+=delta
    if player==null or not is_instance_valid(player): return
    if target!=null and not is_instance_valid(target): target=null
    if target==null and map!=null and is_instance_valid(map):
        var best=Adventure.PET_LOOT_RADIUS
        for drop in map.pickups:
            if not is_instance_valid(drop) or drop.get_meta("full_warned",false): continue
            var d=drop.position.distance_to(player.position)
            if d<best:
                best=d
                target=drop
    var goal=target.position if target!=null else player.position+Vector2(-55*player.facing,0)
    var step=goal-position
    var speed=420.0 if target!=null else 260.0
    if step.length()>3:
        if absf(step.x)>2: facing=int(sign(step.x))
        position+=step.normalized()*minf(step.length(),speed*delta)
        hop+=delta*10
    else: hop=0.0
    if step.length()>700: position=player.position+Vector2(-55*player.facing,0)
    if target!=null and position.distance_to(target.position)<22:
        map.collect(target)
        target=null
    queue_redraw()
func _draw():
    var info=Adventure.PETS.get(pet_id,Adventure.PETS.puppy)
    var body: Color=info.body
    var accent: Color=info.accent
    var bounce=-absf(sin(hop))*6 if hop>0 else sin(age*3)*1.5
    draw_set_transform(Vector2(0,bounce),0,Vector2(facing,1))
    draw_circle(Vector2(0,-bounce+1),12,Color(0,0,0,0.15))
    match info.shape:
        "slime":
            draw_colored_polygon(PackedVector2Array([Vector2(-16,0),Vector2(-14,-14),Vector2(-6,-22),Vector2(6,-22),Vector2(14,-14),Vector2(16,0)]),body)
            draw_circle(Vector2(-5,-24),4,accent)
        "penguin":
            draw_circle(Vector2(0,-14),13,body)
            draw_circle(Vector2(2,-12),8,accent)
            draw_colored_polygon(PackedVector2Array([Vector2(10,-17),Vector2(17,-15),Vector2(10,-13)]),Color("f5a623"))
        "dragon":
            draw_colored_polygon(PackedVector2Array([Vector2(-6,-18),Vector2(-20,-30),Vector2(-14,-14)]),accent)
            draw_circle(Vector2(0,-12),12,body)
            draw_circle(Vector2(9,-20),8,body)
            draw_colored_polygon(PackedVector2Array([Vector2(5,-27),Vector2(4,-35),Vector2(9,-27)]),accent)
            draw_line(Vector2(-11,-8),Vector2(-21,-4),body,4)
        _:
            draw_circle(Vector2(-2,-11),11,body)
            draw_circle(Vector2(9,-19),9,body)
            draw_circle(Vector2(0,-8),6,accent)
            match info.shape:
                "bunny":
                    draw_colored_polygon(PackedVector2Array([Vector2(5,-26),Vector2(4,-40),Vector2(9,-27)]),body)
                    draw_colored_polygon(PackedVector2Array([Vector2(10,-26),Vector2(12,-40),Vector2(14,-26)]),body)
                    draw_line(Vector2(5,-28),Vector2(5,-37),accent,2)
                "cat":
                    draw_colored_polygon(PackedVector2Array([Vector2(3,-25),Vector2(4,-33),Vector2(9,-27)]),body)
                    draw_colored_polygon(PackedVector2Array([Vector2(11,-27),Vector2(15,-33),Vector2(16,-23)]),body)
                    draw_line(Vector2(-12,-12),Vector2(-18,-24),body,3)
                _:
                    draw_colored_polygon(PackedVector2Array([Vector2(3,-24),Vector2(0,-14),Vector2(6,-20)]),accent.darkened(0.3))
                    draw_circle(Vector2(17,-17),3,Color("3a2a22"))
                    draw_line(Vector2(-12,-12),Vector2(-17,-19),body,3)
    draw_circle(Vector2(11,-21) if info.shape in ["dog","cat","bunny","dragon"] else Vector2(5,-15),2.2,Color("1d1d24"))
    draw_set_transform(Vector2.ZERO)
