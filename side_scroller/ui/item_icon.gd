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
    else:
        var weapons=preload("res://visuals/weapon_layout.gd")
        var weapon=weapons.definition(type,rare)
        var dimensions=weapon.rect.size
        var factor=minf((size.x-12)/dimensions.x,36.0/dimensions.y)
        var fitted=dimensions*factor
        draw_texture_rect_region(weapons.ART,Rect2(-fitted/2,fitted),weapon.rect)
    draw_set_transform(Vector2.ZERO)
