extends Node2D
var direction=Vector2.RIGHT
var speed=680.0
var max_distance=480.0
var traveled=0.0
var damage=20
var critical=false
var spin=0.0
signal hit(position: Vector2,amount: int,critical: bool)
func _ready(): add_to_group("player_stars")
func _physics_process(delta):
    var step=minf(speed*delta,max_distance-traveled)
    var end=global_position+direction*step
    # Continuous ray prevents tunneling at low frame rates and stops stars at walls.
    var query=PhysicsRayQueryParameters2D.create(global_position,end,1|4)
    query.hit_from_inside=true
    var result=get_world_2d().direct_space_state.intersect_ray(query)
    if not result.is_empty():
        var body=result.collider
        if body.is_in_group("enemies") and body.receive_hit(damage,Vector2.ZERO,get_instance_id()):
            hit.emit(body.global_position+Vector2(0,-35),damage,critical)
        queue_free()
        return
    global_position=end
    traveled+=step
    spin+=delta*19
    if traveled>=max_distance: queue_free()
    queue_redraw()
func _draw():
    draw_line(-direction*24,Vector2.ZERO,Color(0.69,0.52,1,0.3),5,true)
    draw_set_transform(Vector2.ZERO,spin)
    var points=PackedVector2Array([Vector2(0,-11),Vector2(3,-3),Vector2(11,0),Vector2(3,3),Vector2(0,11),Vector2(-3,3),Vector2(-11,0),Vector2(-3,-3)])
    draw_colored_polygon(points,Color("d3d8f5"))
    draw_polyline(points,Color("6c56a9"),1,true)
    draw_circle(Vector2.ZERO,2,Color("504264"))
    draw_set_transform(Vector2.ZERO)
