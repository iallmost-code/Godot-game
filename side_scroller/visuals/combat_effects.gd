extends Node2D
const EFFECT_ART=preload("res://art/effects.png")
const SLASH_REGION=Rect2(0,0,850,724)
const WAVE_REGION=Rect2(850,90,1322,535)
var effects: Array=[]
var numbers: Array=[]
func show_damage(pos: Vector2,amount: int,critical: bool):
    if numbers.size()>=60: numbers.pop_front()
    numbers.append({"position":pos+Vector2(randf_range(-12,12),0),"amount":amount,"critical":critical,"age":0.0})
func show_level_up(pos: Vector2):
    if numbers.size()>=60: numbers.pop_front()
    numbers.append({"position":pos+Vector2(-35,-70),"amount":0,"critical":true,"age":0.0,"text":"LEVEL UP!"})
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
        var tint=Color(1,1,1,fade)
        if e.id=="wave":
            draw_set_transform(e.position,0,Vector2(face,1))
            draw_texture_rect_region(EFFECT_ART,Rect2(0,-115,e.reach,115),WAVE_REGION,tint)
        elif e.id=="thrust":
            draw_set_transform(p,0,Vector2(face,1))
            draw_texture_rect_region(EFFECT_ART,Rect2(0,-28,e.reach,48),WAVE_REGION,tint)
        else:
            draw_set_transform(p,0,Vector2(face,1))
            draw_texture_rect_region(EFFECT_ART,Rect2(0,-65,e.reach,130),SLASH_REGION,tint)
        draw_set_transform(Vector2.ZERO)
    var font=ThemeDB.fallback_font
    for n in numbers:
        var pos=n.position+Vector2(0,-n.age*60)
        var text=n.get("text",str(n.amount)+( "!" if n.critical else ""))
        var size=27 if n.critical else 23
        var color=Color("ffe88b") if n.critical else Color("fff9e4")
        color.a=minf(1,(1-n.age)*3)
        draw_string_outline(font,pos,text,HORIZONTAL_ALIGNMENT_LEFT,-1,size,4,Color(0.2,0.16,0.27,color.a))
        draw_string(font,pos,text,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)
