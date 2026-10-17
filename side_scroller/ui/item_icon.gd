extends Control
var item_id=""
func _draw():
    var gold=Color("d6ac42")
    var steel=Color("b8e6f4")
    var dark=Color("344c62")
    var item=preload("res://data/catalog.gd").items().get(item_id,{})
    var type=item.get("weapon","armor" if item.get("slot","")=="armor" else "sword")
    var rare=item_id.begins_with("warden") or item.get("attack",0)>=60
    var accent=Color("de735d") if rare else Color("658fab")
    var center=Vector2(size.x/2,20)
    draw_set_transform(center)
    if type=="armor":
        var coat=PackedVector2Array([Vector2(-8,-13),Vector2(-17,-7),Vector2(-13,2),Vector2(-8,0),Vector2(-10,15),Vector2(10,15),Vector2(8,0),Vector2(13,2),Vector2(17,-7),Vector2(8,-13),Vector2(4,-8),Vector2(-4,-8)])
        draw_colored_polygon(coat,Color("479da0") if "briar" in item_id else accent)
        draw_polyline(coat+PackedVector2Array([coat[0]]),dark,2,true)
        draw_line(Vector2(0,-7),Vector2(0,13),gold,3)
        draw_line(Vector2(-8,5),Vector2(8,5),gold,3)
    elif type=="staff":
        draw_line(Vector2(-10,16),Vector2(8,-12),dark,6,true)
        draw_line(Vector2(-10,16),Vector2(8,-12),Color("8a5a34"),4,true)
        draw_circle(Vector2(10,-15),7,Color(0.6,0.75,1,0.4))
        draw_circle(Vector2(10,-15),4.5,Color("e07ad8") if rare else Color("9fd0ff"))
    elif type in ["bow","crossbow"]:
        if type=="crossbow":
            draw_line(Vector2(-14,6),Vector2(14,-6),Color("8a5a34"),5,true)
            draw_arc(Vector2(6,-3),14,PI*0.15+0.4,PI*1.15+0.4,12,dark,3,true)
        else:
            draw_arc(Vector2(-6,0),18,-1.2,1.2,14,dark,5,true)
            draw_arc(Vector2(-6,0),18,-1.2,1.2,14,Color("b07a44") if not rare else gold,3,true)
            draw_line(Vector2(-6,0)+Vector2(cos(-1.2),sin(-1.2))*18,Vector2(-6,0)+Vector2(cos(1.2),sin(1.2))*18,Color("efe6d2"),1.5)
        draw_line(Vector2(-12,0),Vector2(16,0),steel,2)
    elif type=="dagger":
        var blade=PackedVector2Array([Vector2(-2,4),Vector2(10,-16),Vector2(4,6)])
        draw_colored_polygon(blade,steel if not rare else Color("efd58a"))
        draw_polyline(blade+PackedVector2Array([blade[0]]),dark,2,true)
        draw_line(Vector2(-7,2),Vector2(7,8),gold,4,true)
        draw_line(Vector2(0,6),Vector2(-6,16),Color("6b4a2c"),4,true)
    elif type=="claw":
        draw_style_box(preload("res://ui/style.gd").box(accent,dark,4,0),Rect2(-14,-3,27,20))
        for x in [-8,0,8]:
            var blade=PackedVector2Array([Vector2(x-3,-2),Vector2(x-1,-19),Vector2(x+3,-4)])
            draw_colored_polygon(blade,steel)
            draw_polyline(blade+PackedVector2Array([blade[0]]),dark,1.5,true)
        draw_circle(Vector2(0,7),4,gold)
    else:
        draw_line(Vector2(-12,15),Vector2(13,-14),dark,6,true)
        draw_line(Vector2(-12,15),Vector2(13,-14),Color("956c40"),3,true)
        if type=="spear":
            var blade=PackedVector2Array([Vector2(1,-9),Vector2(17,-21),Vector2(11,-3)])
            draw_colored_polygon(blade,steel)
            draw_polyline(blade+PackedVector2Array([blade[0]]),dark,2,true)
        else:
            var blade=PackedVector2Array([Vector2(-6,2),Vector2(9,-17),Vector2(16,-20),Vector2(15,-12),Vector2(0,7)])
            draw_colored_polygon(blade,steel if not rare else Color("efd58a"))
            draw_polyline(blade+PackedVector2Array([blade[0]]),dark,2,true)
            draw_line(Vector2(-9,-1),Vector2(4,10),gold,4,true)
    draw_set_transform(Vector2.ZERO)
