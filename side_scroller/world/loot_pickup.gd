extends Node2D
const Catalog=preload("res://data/catalog.gd")
var reward={}
var collected=false
var age=0.0
signal picked_up
func setup(value: Dictionary):
    reward=value
func try_collect(state) -> bool:
    if collected or not state.collect_reward(reward): return false
    collected=true
    picked_up.emit()
    if is_inside_tree(): queue_free()
    return true
func _process(delta):
    age+=delta
    queue_redraw()
func _draw():
    var bob=sin(age*4)*3
    var tint=preload("res://data/loot_quality.gd").color(reward) if reward.has("item") else Color("efc775")
    draw_circle(Vector2(0,-10+bob),13,Color(tint,0.2))
    if reward.get("rarity","common") in ["rare","epic"]:
        draw_line(Vector2(0,0),Vector2(0,-90),Color(tint,0.22),7,true)
        draw_circle(Vector2(0,-10+bob),17+sin(age*3)*2,Color(tint,0.6),false,2,true)
        var label=reward.get("rarity","").to_upper()
        draw_string_outline(ThemeDB.fallback_font,Vector2(-23,-35+bob),label,HORIZONTAL_ALIGNMENT_LEFT,-1,12,3,Color("292235"))
        draw_string(ThemeDB.fallback_font,Vector2(-23,-35+bob),label,HORIZONTAL_ALIGNMENT_LEFT,-1,12,tint)
    if reward.has("item"):
        draw_colored_polygon(PackedVector2Array([Vector2(0,-25+bob),Vector2(9,-12+bob),Vector2(0,bob),Vector2(-9,-12+bob)]),tint)
        draw_line(Vector2(0,-22+bob),Vector2(0,-3+bob),Color.WHITE,2)
    elif reward.has("consumable"):
        var mana=reward.consumable.begins_with("mp")
        draw_rect(Rect2(-7,-17+bob,14,16),Color("7fb3ef") if mana else Color("ef8b9a"))
        draw_rect(Rect2(-4,-21+bob,8,5),Color("fae4ba"))
    elif reward.has("scroll") or reward.has("quest_item"):
        preload("res://ui/scroll_icon.gd").draw_icon(self,reward.get("scroll",reward.get("quest_item","")),Rect2(-15,-30+bob,30,30))
    elif reward.has("shards"):
        draw_colored_polygon(PackedVector2Array([Vector2(0,-24+bob),Vector2(7,-12+bob),Vector2(0,-1+bob),Vector2(-7,-12+bob)]),Color("b48ef2"))
        draw_line(Vector2(-3,-16+bob),Vector2(2,-10+bob),Color.WHITE,2)
    elif reward.get("potions",0)>0:
        draw_rect(Rect2(-7,-17+bob,14,16),Color("ef8b9a"))
        draw_rect(Rect2(-4,-21+bob,8,5),Color("fae4ba"))
    else:
        draw_circle(Vector2(0,-10+bob),8,Color("efc775"))
        draw_circle(Vector2(0,-10+bob),5,Color("bb854a"),false,2)
