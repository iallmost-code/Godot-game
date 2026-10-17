extends Control
var item_id=""
func _draw():
    var gold=Color("d6ac42")
    var steel=Color("b8e6f4")
    var dark=Color("344c62")
    var item=preload("res://data/catalog.gd").items().get(item_id,{})
    var slot=item.get("slot","weapon")
    var type=item.get("weapon",slot if slot!="weapon" else "sword")
    var rare=item_id.begins_with("warden") or item.get("attack",0)>=60
    var accent=Color("de735d") if rare else Color("658fab")
    var center=Vector2(size.x/2,20)
    draw_set_transform(center)
    if type=="hat":
        var helm=PackedVector2Array([Vector2(-14,8),Vector2(-13,-4),Vector2(-6,-13),Vector2(6,-13),Vector2(13,-4),Vector2(14,8)])
        draw_colored_polygon(helm,accent)
        draw_polyline(helm,dark,2,true)
        draw_line(Vector2(-15,8),Vector2(15,8),gold,4)
    elif type=="gloves":
        for side in [-1,1]:
            var glove=PackedVector2Array([Vector2(side*3,12),Vector2(side*3,-6),Vector2(side*7,-13),Vector2(side*12,-11),Vector2(side*14,-2),Vector2(side*13,12)])
            draw_colored_polygon(glove,accent)
            draw_polyline(glove,dark,2,true)
    elif type=="shoes":
        for side in [-1,1]:
            var boot=PackedVector2Array([Vector2(side*2-6,-12),Vector2(side*2+2,-12),Vector2(side*2+2,6),Vector2(side*2+10,8),Vector2(side*2+10,13),Vector2(side*2-6,13)])
            draw_colored_polygon(boot,Color("8a5a34") if not rare else accent)
            draw_polyline(boot,dark,2,true)
    elif type=="cape":
        var cape=PackedVector2Array([Vector2(-8,-13),Vector2(8,-13),Vector2(15,13),Vector2(0,9),Vector2(-15,13)])
        draw_colored_polygon(cape,Color("b2563f") if not rare else Color("6d4fb0"))
        draw_polyline(cape+PackedVector2Array([cape[0]]),dark,2,true)
        draw_circle(Vector2(0,-11),3,gold)
    elif type=="accessory":
        draw_arc(Vector2(0,-6),7,0,TAU,16,gold,3,true)
        draw_colored_polygon(PackedVector2Array([Vector2(0,2),Vector2(6,9),Vector2(0,16),Vector2(-6,9)]),Color("8fd6ff") if not rare else Color("ff8ad6"))
    elif type=="armor":
        var coat=PackedVector2Array([Vector2(-8,-13),Vector2(-17,-7),Vector2(-13,2),Vector2(-8,0),Vector2(-10,15),Vector2(10,15),Vector2(8,0),Vector2(13,2),Vector2(17,-7),Vector2(8,-13),Vector2(4,-8),Vector2(-4,-8)])
        draw_colored_polygon(coat,Color("479da0") if "briar" in item_id else accent)
        draw_polyline(coat+PackedVector2Array([coat[0]]),dark,2,true)
        draw_line(Vector2(0,-7),Vector2(0,13),gold,3)
        draw_line(Vector2(-8,5),Vector2(8,5),gold,3)
    else:
        var weapons=preload("res://visuals/weapon_layout.gd")
        var weapon=weapons.definition(type,rare)
        var dimensions=weapon.rect.size
        var factor=minf((size.x-12)/dimensions.x,36.0/dimensions.y)
        var fitted=dimensions*factor
        draw_texture_rect_region(weapons.ART,Rect2(-fitted/2,fitted),weapon.rect)
    draw_set_transform(Vector2.ZERO)
