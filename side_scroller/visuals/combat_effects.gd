extends Node2D
var effects: Array=[]
var numbers: Array=[]
func show_damage(pos: Vector2,amount: int,critical: bool):
    if numbers.size()>=60: numbers.pop_front()
    numbers.append({"position":pos+Vector2(randf_range(-12,12),0),"amount":amount,"critical":critical,"age":0.0})
func show_attack(id: String,origin: Vector2,facing: int,reach=-1.0):
    if effects.size()>=30: effects.pop_front()
    if reach<0: reach=preload("res://data/catalog.gd").skills()[id].reach
    effects.append({"id":id,"position":origin,"facing":facing,"reach":reach,"age":0.0})
func _process(delta):
    for e in effects.duplicate():
        e.age+=delta
        if e.age>0.42: effects.erase(e)
    for n in numbers.duplicate():
        n.age+=delta
        if n.age>0.95: numbers.erase(n)
    queue_redraw()
func _draw():
    for e in effects:
        var fade=1-e.age/0.42
        var p=e.position+Vector2(0,-30)
        var face=e.facing
        var color=Color("fff2b2")
        color.a=fade
        if e.id=="wave":
            draw_line(p+Vector2(face*15,12),p+Vector2(face*e.reach,12),Color(0.45,0.92,0.9,fade*0.6),8*fade)
            for i in range(3):
                var tip=face*e.reach*(0.4+i*0.3)
                var poly=PackedVector2Array([p+Vector2(tip-face*90,12),p+Vector2(tip-face*45,-65+i*9),p+Vector2(tip,12)])
                draw_colored_polygon(poly,Color(0.45,0.92,0.9,fade*(0.7-i*0.12)))
        elif e.id=="thrust":
            draw_line(p+Vector2(face*12,0),p+Vector2(face*(e.reach-8),0),Color(0.5,0.9,1,fade),12*fade)
            draw_line(p+Vector2(face*12,0),p+Vector2(face*(e.reach-15),0),color,4)
            draw_colored_polygon(PackedVector2Array([p+Vector2(face*(e.reach-30),-12),p+Vector2(face*e.reach,0),p+Vector2(face*(e.reach-30),12)]),color)
        else:
            var radius=float(e.reach)
            var base_angle=0.0 if face==1 else PI
            draw_arc(p,radius,base_angle-0.95,base_angle+0.95,24,Color(1,0.74,0.39,fade),12*fade,true)
            draw_arc(p,radius-8,base_angle-0.85,base_angle+0.85,24,color,5*fade,true)
    var font=ThemeDB.fallback_font
    for n in numbers:
        var pos=n.position+Vector2(0,-n.age*60)
        var text=str(n.amount)+( "!" if n.critical else "")
        var size=27 if n.critical else 23
        var color=Color("ffe88b") if n.critical else Color("fff9e4")
        color.a=minf(1,(1-n.age)*3)
        draw_string_outline(font,pos,text,HORIZONTAL_ALIGNMENT_LEFT,-1,size,4,Color(0.2,0.16,0.27,color.a))
        draw_string(font,pos,text,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)
