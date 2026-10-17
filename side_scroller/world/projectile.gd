extends Node2D
var direction=Vector2.RIGHT
var target
var lifetime=3.0
var damage=7
var speed=180.0
func _ready(): add_to_group("enemy_projectiles")
func _physics_process(delta):
    var end=global_position+direction*speed*delta
    var query=PhysicsRayQueryParameters2D.create(global_position,end,1|2)
    query.hit_from_inside=true
    var collision=get_world_2d().direct_space_state.intersect_ray(query)
    if not collision.is_empty():
        if collision.collider==target and is_instance_valid(target):
            target.receive_damage(damage,Vector2(direction.x*80,-40))
        queue_free()
        return
    global_position=end
    lifetime-=delta
    if lifetime<=0: queue_free()
    queue_redraw()
func _draw():
    draw_circle(Vector2.ZERO,9,Color(0.79,0.61,1,0.25))
    draw_circle(Vector2.ZERO,5,Color("b18bdc"))
    draw_circle(Vector2(-2,-2),2,Color("fff1c1"))
