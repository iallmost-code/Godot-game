extends Control
# Painted skill icon with optional hotkey letter, cooldown shade and MP cost.
const Icons=preload("res://visuals/skill_icon_layout.gd")
var skill_id=""
var key_text=""
var cooldown=0.0
var cooldown_total=0.0
var footer=""
func _init(): mouse_filter=Control.MOUSE_FILTER_IGNORE
func set_state(id: String,key: String="",remaining: float=0.0,total: float=0.0,bottom: String=""):
    if id==skill_id and key==key_text and is_equal_approx(remaining,cooldown) and bottom==footer: return
    skill_id=id
    key_text=key
    cooldown=remaining
    cooldown_total=maxf(total,remaining)
    footer=bottom
    queue_redraw()
func _draw():
    var side=minf(size.x,size.y-(14 if footer!="" else 0))
    var area=Rect2(Vector2((size.x-side)/2,0),Vector2(side,side))
    draw_rect(area,Color("1d2c38"))
    if skill_id!="" and Icons.DATA.has(skill_id):
        Icons.draw(self,skill_id,area.grow(-2))
    if cooldown>0 and cooldown_total>0:
        var shade=area.grow(-2)
        var portion=clampf(cooldown/cooldown_total,0,1)
        draw_rect(Rect2(shade.position,Vector2(shade.size.x,shade.size.y*portion)),Color(0.05,0.08,0.12,0.68))
        var font=get_theme_default_font()
        var text="%.1f" % cooldown if cooldown<10 else str(ceili(cooldown))
        draw_string_outline(font,area.position+Vector2(0,side/2+7),text,HORIZONTAL_ALIGNMENT_CENTER,side,18,4,Color("1d2c38"))
        draw_string(font,area.position+Vector2(0,side/2+7),text,HORIZONTAL_ALIGNMENT_CENTER,side,18,Color.WHITE)
    draw_rect(area,Color("9cabb7"),false,2)
    var font=get_theme_default_font()
    if key_text!="":
        draw_string_outline(font,area.position+Vector2(4,15),key_text,HORIZONTAL_ALIGNMENT_LEFT,-1,14,4,Color("1d2c38"))
        draw_string(font,area.position+Vector2(4,15),key_text,HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("fff1c2"))
    if footer!="":
        draw_string(font,Vector2(0,size.y-2),footer,HORIZONTAL_ALIGNMENT_CENTER,size.x,11,Color("354454"))
