extends Control
# Parchment scroll with a seal coloured by its success rate.
const Adventure=preload("res://data/adventure.gd")
var scroll_id=""
func _init(): mouse_filter=Control.MOUSE_FILTER_IGNORE
static func seal_color(id: String) -> Color:
    if id=="scroll_chaos": return Color("b8322e")
    if id=="scroll_clean": return Color("f4f4f4")
    match int(Adventure.scrolls().get(id,{}).get("tier",0)):
        0: return Color("4f8fe0")
        1: return Color("c7ced6")
        2: return Color("f0b93a")
    return Color.WHITE
func _draw():
    var w=size.x
    var h=size.y
    draw_rect(Rect2(w*0.2,h*0.15,w*0.6,h*0.7),Color("f3e2b3"))
    draw_rect(Rect2(w*0.12,h*0.08,w*0.76,h*0.12),Color("c9a86a"))
    draw_rect(Rect2(w*0.12,h*0.8,w*0.76,h*0.12),Color("c9a86a"))
    for i in 3: draw_line(Vector2(w*0.3,h*(0.32+i*0.1)),Vector2(w*0.7,h*(0.32+i*0.1)),Color("b9a37a"),1)
    draw_circle(Vector2(w*0.5,h*0.66),w*0.13,seal_color(scroll_id))
    draw_circle(Vector2(w*0.5,h*0.66),w*0.13,Color(0,0,0,0.35),false,1.5)
