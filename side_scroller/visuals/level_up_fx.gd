extends Node2D
# Gold pillar of light with rising sparks and "LEVEL UP" lettering.
const LENGTH=1.9
var follow: Node2D
var age=0.0
var title="LEVEL UP"
var tint=Color("ffd76a")
func _ready(): z_index=14
func _process(delta):
    age+=delta
    if follow!=null and is_instance_valid(follow): position=follow.global_position
    if age>=LENGTH: queue_free()
    queue_redraw()
func _draw():
    var grow=minf(1.0,age/0.25)
    var fade=clampf((LENGTH-age)/0.6,0,1)
    var height=330.0*grow
    for i in 5:
        var w=(70-i*12)*grow
        draw_rect(Rect2(-w/2,-height,w,height),Color(tint.r,tint.g,tint.b,0.10*fade+i*0.035*fade))
    draw_rect(Rect2(-5,-height,10,height),Color(1,1,0.9,0.55*fade))
    for ring in 3:
        var t=fmod(age*1.4+ring*0.33,1.0)
        draw_set_transform(Vector2(0,-6-t*40),0,Vector2(1,0.28))
        draw_arc(Vector2.ZERO,30+t*70,0,TAU,40,Color(tint.r,tint.g,tint.b,(1-t)*0.8*fade),4,true)
        draw_set_transform(Vector2.ZERO)
    for i in 14:
        var t=fmod(age*0.9+i*0.071,1.0)
        var x=sin(i*2.7+age*2)*(18+i*3)
        var p=Vector2(x,-20-t*300)
        var r=2.5+float(i%3)
        draw_colored_polygon(PackedVector2Array([p+Vector2(0,-r*2),p+Vector2(r*0.6,0),p+Vector2(0,r*2),p+Vector2(-r*0.6,0)]),Color(1,0.97,0.8,(1-t)*fade))
    var font=ThemeDB.fallback_font
    var pop=1.0+0.4*maxf(0,1-age/0.2)
    draw_set_transform(Vector2(0,-150-minf(age,0.5)*30),0,Vector2(pop,pop))
    draw_string_outline(font,Vector2(-160,0),title,HORIZONTAL_ALIGNMENT_CENTER,320,40,10,Color(0.45,0.25,0.02,fade))
    draw_string(font,Vector2(-160,0),title,HORIZONTAL_ALIGNMENT_CENTER,320,40,Color(1,0.93,0.55,fade))
    draw_set_transform(Vector2.ZERO)
