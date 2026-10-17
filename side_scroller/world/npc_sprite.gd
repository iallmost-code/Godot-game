extends Node2D
# Painted town NPC with a two-frame idle; falls back to a tinted adventurer.
const Layout=preload("res://visuals/npc_layout.gd")
var npc_name=""
var age=0.0
func _ready():
    if not Layout.DATA.has(npc_name):
        var fallback=preload("res://visuals/character_visual.gd").new()
        fallback.modulate=Color(0.85,1.0,0.85)
        add_child(fallback)
        fallback.set_pose("idle",1,0)
        set_process(false)
func _process(delta):
    age+=delta
    queue_redraw()
func _draw():
    var info=Layout.DATA.get(npc_name,{})
    if info.is_empty(): return
    var index=int(age*info.fps)%info.rects.size()
    var rect: Rect2=info.rects[index]
    var factor=float(info.height)/rect.size.y*1.15
    var anchor: Vector2=(info.anchors[index]-rect.position)*factor
    draw_set_transform(Vector2.ZERO,0,Vector2(1,1))
    draw_circle(Vector2(0,1),14,Color(0,0,0,0.15))
    draw_texture_rect_region(Layout.ART,Rect2(-anchor,rect.size*factor),rect)
