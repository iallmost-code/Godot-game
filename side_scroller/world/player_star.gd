extends Node2D
# Player projectile: stars, arrows, spell bolts, shells and coins.
const ELEMENT_COLORS={"fire":Color("ff8a4c"),"ice":Color("8fd6ff"),"lightning":Color("f6ef7a"),"poison":Color("9be36b"),"holy":Color("fff2b8"),"arcane":Color("c9a4ff"),"neutral":Color("b9c8ff"),"":Color("d3d8f5")}
var direction=Vector2.RIGHT
var speed=680.0
var max_distance=480.0
var traveled=0.0
var damage=20
var critical=false
var spin=0.0
var style="star"
var element=""
var pierce=0
var skill_id="star"
var rank=1
var scale_factor=1.0
var combat
var already_hit: Array=[]
signal hit(position: Vector2,amount: int,critical: bool)
func _ready():
    add_to_group("player_stars")
    if style in ["arrow","bolt"]: speed=820.0
    if style=="big_star": speed=560.0
func _physics_process(delta):
    var step=minf(speed*delta,max_distance-traveled)
    var start=global_position
    var end=start+direction*step
    var excluded: Array=[]
    # Continuous rays prevent tunneling at low frame rates and stop projectiles at walls.
    while true:
        var query=PhysicsRayQueryParameters2D.create(start,end,1|4,excluded)
        query.hit_from_inside=true
        var result=get_world_2d().direct_space_state.intersect_ray(query)
        if result.is_empty(): break
        var body=result.collider
        if not body.is_in_group("enemies"):
            queue_free()
            return
        excluded.append(result.rid)
        if already_hit.has(body.get_instance_id()): continue
        already_hit.append(body.get_instance_id())
        var dealt=0
        if combat!=null and is_instance_valid(combat): dealt=combat.projectile_hit(self,body)
        elif body.receive_hit(damage,Vector2.ZERO,get_instance_id()): dealt=damage
        if dealt>0: hit.emit(body.global_position+Vector2(0,-35),dealt,critical)
        if pierce<=0:
            queue_free()
            return
        pierce-=1
    global_position=end
    traveled+=step
    spin+=delta*19
    if traveled>=max_distance: queue_free()
    queue_redraw()
func _draw():
    var color=ELEMENT_COLORS.get(element,ELEMENT_COLORS[""])
    match style:
        "arrow":
            draw_line(-direction*26,direction*6,Color("8a6040"),3,true)
            draw_colored_polygon(PackedVector2Array([direction*14,direction*2+direction.orthogonal()*5,direction*2-direction.orthogonal()*5]),Color("dfe7ef") if element=="" else color)
            draw_line(-direction*26+direction.orthogonal()*4,-direction*20,Color("f1f1f1"),2)
            draw_line(-direction*26-direction.orthogonal()*4,-direction*20,Color("f1f1f1"),2)
            if element!="": draw_circle(direction*10,6,Color(color,0.35))
        "bolt":
            draw_line(-direction*30,Vector2.ZERO,Color(color,0.35),9,true)
            draw_circle(Vector2.ZERO,9,Color(color,0.45))
            draw_circle(Vector2.ZERO,5,color)
            draw_circle(Vector2(-2,-2),2,Color.WHITE)
        "snail":
            draw_set_transform(Vector2.ZERO,spin*0.5)
            draw_circle(Vector2.ZERO,8,Color("e9a65a"))
            draw_arc(Vector2.ZERO,5,0,TAU*0.8,12,Color("8a5326"),2)
            draw_set_transform(Vector2.ZERO)
        "coin":
            draw_circle(Vector2.ZERO,7,Color("f2c94c"))
            draw_circle(Vector2.ZERO,7,Color("a87920"),false,2)
            draw_line(-direction*20,Vector2.ZERO,Color(1,0.85,0.4,0.4),4,true)
        _:
            var size=2.1 if style=="big_star" else 1.0
            draw_line(-direction*24*size,Vector2.ZERO,Color(0.69,0.52,1,0.3),5*size,true)
            draw_set_transform(Vector2.ZERO,spin,Vector2.ONE*size)
            var points=PackedVector2Array([Vector2(0,-11),Vector2(3,-3),Vector2(11,0),Vector2(3,3),Vector2(0,11),Vector2(-3,3),Vector2(-11,0),Vector2(-3,-3)])
            draw_colored_polygon(points,Color("d3d8f5"))
            draw_polyline(points,Color("6c56a9"),1,true)
            draw_circle(Vector2.ZERO,2,Color("504264"))
            draw_set_transform(Vector2.ZERO)
