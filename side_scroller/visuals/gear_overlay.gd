extends Node2D
# Light equipment layers follow the same body/head anchors as painted hairstyles.
const C=preload("res://data/catalog.gd")
const Q=preload("res://data/loot_quality.gd")
var equipment={}
var head=Vector2(0,-60)
var facing=1
var phase=0.0
var pose="idle"
var behind=false
func tint(slot: String) -> Color:
    var item=equipment.get(slot,{})
    var rank=int(C.items().get(item.get("id",""),{}).get("req",1)/30.0)
    var colors=[Color("a98560"),Color("68a8b8"),Color("82b964"),Color("b28cce"),Color("d0a84b"),Color("dd8174")]
    return colors[clampi(rank,0,colors.size()-1)]
func polygon(points: Array,color: Color):
    var poly=PackedVector2Array(points)
    draw_colored_polygon(poly,color)
    poly.append(poly[0])
    draw_polyline(poly,Color("30253b"),2,true)
func _draw():
    if pose=="climb":return
    draw_set_transform(Vector2.ZERO,0,Vector2(facing,1))
    var bounce=sin(phase*9)*2 if pose=="run" else sin(phase*3)*.4
    if behind:
        if equipment.has("cape"):
            var flutter=sin(phase*6)*4
            polygon([Vector2(-9,-33+bounce),Vector2(-24-flutter,-27+bounce),Vector2(-26-flutter,-7),Vector2(-12,-12),Vector2(0,-30)],tint("cape"))
            draw_line(Vector2(-15,-36),Vector2(-20-flutter,-13),tint("cape").lightened(.3),2,true)
    else:
        if equipment.has("armor") and C.items().get(equipment.armor.id,{}).get("req",0)>=5:
            polygon([Vector2(-10,-29+bounce),Vector2(7,-29+bounce),Vector2(8,-17+bounce),Vector2(-10,-17+bounce)],tint("armor"))
            draw_line(Vector2(-1,-27+bounce),Vector2(-1,-19+bounce),Color("f6dda4"),2,true)
        if equipment.has("hat"):
            var at=Vector2(head.x*facing,head.y-17)
            var color=tint("hat")
            polygon([at+Vector2(-17,5),at+Vector2(-14,-6),at+Vector2(-5,-12),at+Vector2(9,-9),at+Vector2(16,4)],color)
            draw_line(at+Vector2(-19,5),at+Vector2(18,5),Color("30253b"),5,true)
            draw_line(at+Vector2(-17,4),at+Vector2(16,4),color.lightened(.3),2,true)
            var rarity=Q.rarity(equipment.hat)
            if rarity in ["rare","epic"]:
                draw_circle(at+Vector2(6,-2),3,Q.COLORS[rarity])
        if equipment.has("shoes"):
            for x in [-8,6]:draw_line(Vector2(x,-4),Vector2(x+5,-4),tint("shoes"),4,true)
    draw_set_transform(Vector2.ZERO)
