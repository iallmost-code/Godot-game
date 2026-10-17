extends Control
var item_id=""
func _draw():
    var gold=Color("d6ac42")
    var steel=Color("b8e6f4")
    var dark=Color("344c62")
    var rare=item_id.begins_with("warden")
    var accent=Color("de735d") if rare else Color("658fab")
    var center=Vector2(size.x/2,20)
    draw_set_transform(center)
    if "armor" in item_id:
        var coat=PackedVector2Array([Vector2(-8,-13),Vector2(-17,-7),Vector2(-13,2),Vector2(-8,0),Vector2(-10,15),Vector2(10,15),Vector2(8,0),Vector2(13,2),Vector2(17,-7),Vector2(8,-13),Vector2(4,-8),Vector2(-4,-8)])
        draw_colored_polygon(coat,Color("479da0") if "briar" in item_id else accent)
        draw_polyline(coat+PackedVector2Array([coat[0]]),dark,2,true)
        draw_line(Vector2(0,-7),Vector2(0,13),gold,3)
        draw_line(Vector2(-8,5),Vector2(8,5),gold,3)
    elif "claw" in item_id:
        draw_style_box(preload("res://ui/style.gd").box(accent,dark,4,0),Rect2(-14,-3,27,20))
        for x in [-8,0,8]:
            var blade=PackedVector2Array([Vector2(x-3,-2),Vector2(x-1,-19),Vector2(x+3,-4)])
            draw_colored_polygon(blade,steel)
            draw_polyline(blade+PackedVector2Array([blade[0]]),dark,1.5,true)
        draw_circle(Vector2(0,7),4,gold)
    else:
        draw_line(Vector2(-12,15),Vector2(13,-14),dark,6,true)
        draw_line(Vector2(-12,15),Vector2(13,-14),Color("956c40"),3,true)
        if "spear" in item_id:
            var blade=PackedVector2Array([Vector2(1,-9),Vector2(17,-21),Vector2(11,-3)])
            draw_colored_polygon(blade,steel)
            draw_polyline(blade+PackedVector2Array([blade[0]]),dark,2,true)
        else:
            var blade=PackedVector2Array([Vector2(-6,2),Vector2(9,-17),Vector2(16,-20),Vector2(15,-12),Vector2(0,7)])
            draw_colored_polygon(blade,steel if not rare else Color("efd58a"))
            draw_polyline(blade+PackedVector2Array([blade[0]]),dark,2,true)
            draw_line(Vector2(-9,-1),Vector2(4,10),gold,4,true)
    draw_set_transform(Vector2.ZERO)
