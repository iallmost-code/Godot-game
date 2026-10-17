extends Control
# Corner map: ledges, ropes, portals, NPCs and you.
const Maps=preload("res://data/maps.gd")
var map
var player
func _init():
    mouse_filter=Control.MOUSE_FILTER_IGNORE
    custom_minimum_size=Vector2(240,92)
    size=custom_minimum_size
func _process(_delta): queue_redraw()
func _draw():
    draw_rect(Rect2(Vector2.ZERO,size),Color(0.08,0.14,0.2,0.62))
    draw_rect(Rect2(Vector2.ZERO,size),Color("9bcce5"),false,2)
    if map==null or not is_instance_valid(map): return
    var data=Maps.definition(map.map_id)
    var top=minf(float(data.get("top",137.0)),150.0)
    var span=Vector2(map.width,650.0-top)
    var scale_factor=minf((size.x-12)/span.x,(size.y-12)/span.y)
    var inner=span*scale_factor
    var origin=Vector2((size.x-inner.x)/2,(size.y-inner.y)/2)
    var to_map=func(p: Vector2) -> Vector2: return origin+Vector2(p.x,p.y-top)*scale_factor
    draw_line(to_map.call(Vector2(0,610)),to_map.call(Vector2(map.width,610)),Color("c9e3a0"),2)
    for p in data.platforms:
        draw_line(to_map.call(Vector2(p[0]-p[2]/2.0,p[1])),to_map.call(Vector2(p[0]+p[2]/2.0,p[1])),Color("a9cf86"),2)
    for c in data.get("climbs",[]):
        draw_line(to_map.call(Vector2(c[0],c[1])),to_map.call(Vector2(c[0],c[2])),Color("d6a866"),1.5)
    for portal in map.portals:
        draw_circle(to_map.call(portal.position+Vector2(0,-10)),3.5,Color("5fd4ff"))
    if data.safe:
        draw_circle(to_map.call(Vector2(map.instructor_position.x,600)),3,Color("7ee07a"))
        draw_circle(to_map.call(Vector2(map.merchant_position.x,600)),3,Color("7ee07a"))
        for giver in map.quest_givers: draw_circle(to_map.call(Vector2(giver.x,600)),3.5,Color("ffd23f"))
    if map.boss!=null and is_instance_valid(map.boss) and map.boss.hp>0:
        draw_circle(to_map.call(map.boss.position+Vector2(0,-10)),4.5,Color("ff4d4d"))
    if player!=null and is_instance_valid(player):
        var at=to_map.call(player.position+Vector2(0,-10))
        draw_circle(at,4.5,Color("3a2a05"))
        draw_circle(at,3.5,Color("ffe14d"))
