extends Node2D
const Catalog=preload("res://data/catalog.gd")
var reward={}
var collected=false
var age=0.0
signal picked_up
func setup(value: Dictionary):
    reward=value
func try_collect(state) -> bool:
    if collected or not state.collect_reward(reward): return false
    collected=true
    picked_up.emit()
    if is_inside_tree(): queue_free()
    return true
func _process(delta):
    age+=delta
    queue_redraw()
func _draw():
    var bob=sin(age*4)*3
    draw_circle(Vector2(0,-10+bob),13,Color(1,0.85,0.43,0.15))
    if reward.has("item"):
        draw_colored_polygon(PackedVector2Array([Vector2(0,-25+bob),Vector2(9,-12+bob),Vector2(0,bob),Vector2(-9,-12+bob)]),Color("89e7da"))
        draw_line(Vector2(0,-22+bob),Vector2(0,-3+bob),Color.WHITE,2)
    elif reward.get("potions",0)>0:
        draw_rect(Rect2(-7,-17+bob,14,16),Color("ef8b9a"))
        draw_rect(Rect2(-4,-21+bob,8,5),Color("fae4ba"))
    else:
        draw_circle(Vector2(0,-10+bob),8,Color("efc775"))
        draw_circle(Vector2(0,-10+bob),5,Color("bb854a"),false,2)
