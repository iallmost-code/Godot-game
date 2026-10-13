extends Node2D
var direction=Vector2.RIGHT
var target
var lifetime=3.0
func _physics_process(delta):
    position+=direction*180*delta
    lifetime-=delta
    if target!=null and is_instance_valid(target) and global_position.distance_to(target.global_position+Vector2(0,-26))<23:
        target.receive_damage(7,Vector2(direction.x*80,-40))
        queue_free()
    if lifetime<=0: queue_free()
    queue_redraw()
func _draw():
    draw_circle(Vector2.ZERO,9,Color(0.79,0.61,1,0.25))
    draw_circle(Vector2.ZERO,5,Color("b18bdc"))
    draw_circle(Vector2(-2,-2),2,Color("fff1c1"))
