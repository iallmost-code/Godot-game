extends Node2D
# Sparse regional particles; positions follow the camera without spawning nodes.
var biome="meadow"
var age=0.0
func _process(delta):
    age+=delta
    queue_redraw()
func _draw():
    var camera=get_viewport().get_camera_2d()
    if camera==null:return
    var view=get_viewport_rect().size/camera.zoom
    var origin=camera.global_position-view/2
    var snow=biome in ["snow","ice"]
    var sparks=biome in ["temple","time","cloud","sky","volcano","desert"]
    var forest=biome in ["forest","mushroom","roots","bamboo","swamp"]
    for i in range(30 if snow else 16):
        var drift=age*(16 if snow else 8)
        var x=fposmod(i*173.7+drift+sin(age*.7+i)*9,view.x)
        var y=fposmod(i*91.3+age*(24 if snow else -7),view.y)
        var at=origin+Vector2(x,y)
        var alpha=.15+.22*(.5+.5*sin(age*2+i))
        if snow:draw_circle(at,1.5+i%2,Color(1,1,1,alpha+.15))
        elif sparks:
            var color=Color("ffd88a") if biome not in ["cloud","sky"] else Color("e5ddff")
            draw_line(at-Vector2(2,0),at+Vector2(2,0),Color(color,alpha),1,true)
            draw_line(at-Vector2(0,2),at+Vector2(0,2),Color(color,alpha),1,true)
        elif forest:draw_circle(at,1.6,Color(.85,1,.5,alpha))
        else:draw_line(at,at+Vector2(5,-1),Color(.98,.92,.74,alpha*.6),1,true)
