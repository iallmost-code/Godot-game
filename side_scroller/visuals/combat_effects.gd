extends Node2D
const EFFECT_ART=preload("res://art/effects.png")
const SLASH_REGION=Rect2(0,0,850,724)
const WAVE_REGION=Rect2(850,90,1322,535)
var effects: Array=[]
var numbers: Array=[]
func clear_numbers():
    for number in numbers:
        if is_instance_valid(number.get("visual")): number.visual.queue_free()
    numbers.clear()
func add_number(pos: Vector2,text: String,critical: bool,celebration=false):
    if numbers.size()>=60:
        var oldest=numbers.pop_front()
        oldest.visual.queue_free()
    # New hits enter at the bottom. Shift every still-visible line upward,
    # including fading lines, so eight-star partner volleys never reuse a row.
    for number in numbers:
        if absf(number.origin.x-pos.x)<48:
            number.position.y-=42
            number.visual.position=number.position+Vector2(0,-number.age*46)
    var visual=preload("res://visuals/damage_number.gd").new()
    visual.setup(text,critical,celebration)
    var stacked=pos
    visual.position=stacked
    add_child(visual)
    numbers.append({"position":stacked,"origin":pos,"critical":critical,"age":0.0,"visual":visual})
func show_damage(pos: Vector2,amount: int,critical: bool):
    add_number(pos,str(amount),critical)
func show_level_up(pos: Vector2):
    add_number(pos+Vector2(0,-70),"LEVEL UP!",true,true)
func show_attack(id: String,origin: Vector2,facing: int,reach=-1.0):
    if id in ["star","shadow_partner","star_fan"]: return
    if effects.size()>=30: effects.pop_front()
    if reach<0: reach=preload("res://data/catalog.gd").skills()[id].reach
    effects.append({"id":id,"position":origin,"facing":facing,"reach":reach,"age":0.0})
func _process(delta):
    for e in effects.duplicate():
        e.age+=delta
        if e.age>0.42: effects.erase(e)
    for n in numbers.duplicate():
        n.age+=delta
        if n.age>1.1:
            n.visual.queue_free()
            numbers.erase(n)
        else:
            n.visual.position=n.position+Vector2(0,-n.age*46)
            n.visual.scale=Vector2.ONE*(1.0+0.18*maxf(0,1-n.age/0.16))
            n.visual.modulate.a=clampf((1.1-n.age)/0.32,0,1)
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
