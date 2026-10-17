extends Node2D
const EFFECT_ART=preload("res://art/effects.png")
const SLASH_REGION=Rect2(0,0,850,724)
const WAVE_REGION=Rect2(850,90,1322,535)
const ELEMENT_COLORS={"fire":Color("ff8a4c"),"ice":Color("8fd6ff"),"lightning":Color("f6ef7a"),"poison":Color("9be36b"),"holy":Color("fff2b8"),"arcane":Color("c9a4ff"),"neutral":Color("b9c8ff"),"":Color("e8f0ff")}
var effects: Array=[]
var shapes: Array=[]
func _ready(): add_to_group("combat_effects")
var numbers: Array=[]
func clear_numbers():
    for number in numbers:
        if is_instance_valid(number.get("visual")): number.visual.queue_free()
    numbers.clear()
func add_number(pos: Vector2,text: String,critical: bool,celebration=false,incoming=false,tint=Color(0,0,0,0)):
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
    visual.setup(text,critical,celebration,incoming,tint)
    var stacked=pos
    visual.position=stacked
    add_child(visual)
    numbers.append({"position":stacked,"origin":pos,"critical":critical,"age":0.0,"visual":visual})
func show_damage(pos: Vector2,amount: int,critical: bool):
    add_number(pos,str(amount),critical)
func show_player_damage(pos: Vector2,amount: int):
    add_number(pos,"-"+str(amount),false,false,true)
func show_level_up(pos: Vector2):
    add_number(pos+Vector2(0,-70),"LEVEL UP!",true,true)
func show_heal(pos: Vector2,amount: int):
    add_number(pos+Vector2(0,-80),"+"+str(amount),false,false,false,Color("6fdc8c"))
    add_shape("heal",{"position":pos,"color":Color("8ff0a8"),"radius":60})
func show_evade(pos: Vector2,text: String):
    add_number(pos,text,false,false,false,Color("f2a0e0") if text=="MISS" else Color("fff2b8"))
func effect_burst(pos: Vector2,radius: float,color: Color):
    add_shape("burst",{"position":pos,"color":color,"radius":radius})
func add_shape(kind: String,data: Dictionary):
    if shapes.size()>=40: shapes.pop_front()
    data.kind=kind
    data.age=0.0
    shapes.append(data)
func show_effect(kind: String,data: Dictionary):
    var color=ELEMENT_COLORS.get(data.get("element",""),ELEMENT_COLORS[""])
    match kind:
        "heal": show_heal(data.position,data.amount)
        "aura": add_shape("aura",{"position":data.position,"color":color,"radius":46})
        "burst": add_shape("burst",{"position":data.position,"color":color,"radius":data.get("radius",80)})
        "chain": add_shape("chain",{"points":data.points,"color":color})
        "element":
            var reach=data.reach
            var center=data.position+Vector2(0 if data.both else data.facing*reach/2,0)
            add_shape("rain" if data.shape=="drop" else "burst",{"position":center,"color":color,"radius":reach if data.both else reach/2,"width":reach*(2 if data.both else 1)})
func show_attack(id: String,origin: Vector2,facing: int,reach=-1.0):
    var skill=preload("res://data/catalog.gd").skill(id)
    if skill.is_empty() or skill.get("shape","melee")=="projectile": return
    if effects.size()>=30: effects.pop_front()
    if reach<0: reach=skill.reach
    var fx=skill.get("fx","slash")
    if fx in ["burst","rain","lightning","aura","heal"] and skill.get("element","")!="": return
    effects.append({"id":id,"fx":fx,"position":origin,"facing":facing,"reach":reach,"age":0.0,"both":skill.get("both",false)})
func _process(delta):
    for e in effects.duplicate():
        e.age+=delta
        if e.age>0.42: effects.erase(e)
    for shape in shapes.duplicate():
        shape.age+=delta
        if shape.age>0.5: shapes.erase(shape)
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
        if e.fx in ["burst","rain","lightning","aura","heal"]:
            draw_set_transform(Vector2.ZERO)
            var color=Color(0.9,0.95,1,fade*0.5)
            var r=e.reach*(1.0 if e.both else 0.5)
            var center=e.position+Vector2(0 if e.both else face*r,-30)
            draw_set_transform(center,0,Vector2(1,0.35))
            draw_circle(Vector2.ZERO,r*(0.6+0.4*(1-fade)),color)
            draw_arc(Vector2.ZERO,r*(0.6+0.4*(1-fade)),0,TAU,40,Color(1,1,1,fade),3,true)
        elif e.fx=="wave" or e.id=="wave":
            draw_set_transform(e.position,0,Vector2(face,1))
            draw_texture_rect_region(EFFECT_ART,Rect2(0,-115,e.reach,115),WAVE_REGION,tint)
        elif e.fx=="thrust" or e.id=="thrust":
            draw_set_transform(p,0,Vector2(face,1))
            draw_texture_rect_region(EFFECT_ART,Rect2(0,-28,e.reach,48),WAVE_REGION,tint)
        else:
            draw_set_transform(p,0,Vector2(face,1))
            draw_texture_rect_region(EFFECT_ART,Rect2(0,-65,e.reach,130),SLASH_REGION,tint)
        draw_set_transform(Vector2.ZERO)
    for shape in shapes:
        var fade=1.0-shape.age/0.5
        var color: Color=shape.get("color",Color.WHITE)
        match shape.kind:
            "aura":
                draw_arc(shape.position+Vector2(0,-35),shape.radius*(0.6+shape.age),0,TAU,40,Color(color,fade),4,true)
                draw_arc(shape.position+Vector2(0,-35),shape.radius*(0.3+shape.age*1.5),0,TAU,40,Color(color,fade*0.6),2,true)
            "heal":
                for i in range(6):
                    var a=i*TAU/6+shape.age*3
                    var p=shape.position+Vector2(cos(a)*shape.radius*0.6,-40-shape.age*80+sin(a)*10)
                    draw_line(p+Vector2(-5,0),p+Vector2(5,0),Color(color,fade),3)
                    draw_line(p+Vector2(0,-5),p+Vector2(0,5),Color(color,fade),3)
            "burst":
                draw_set_transform(shape.position+Vector2(0,-25),0,Vector2(1,0.45))
                var r=shape.radius*(0.5+shape.age)
                draw_circle(Vector2.ZERO,r,Color(color,fade*0.35))
                draw_arc(Vector2.ZERO,r,0,TAU,40,Color(color,fade),4,true)
                draw_set_transform(Vector2.ZERO)
            "rain":
                var w=shape.get("width",400.0)
                for i in range(14):
                    var x=shape.position.x-w/2+fmod(i*97.0,w)
                    var y=shape.position.y-260+fmod(shape.age*900+i*53,260)
                    draw_line(Vector2(x,y),Vector2(x-10,y+34),Color(color,fade),4,true)
                    draw_circle(Vector2(x-10,y+34),5,Color(color,fade))
            "chain":
                var pts: Array=shape.points
                for i in range(pts.size()-1):
                    var a: Vector2=pts[i]
                    var b: Vector2=pts[i+1]
                    var mid=(a+b)/2+Vector2(randf_range(-14,14),randf_range(-14,14))
                    draw_polyline(PackedVector2Array([a,mid,b]),Color(color,fade),4,true)
                    draw_polyline(PackedVector2Array([a,mid,b]),Color(1,1,1,fade),1.5,true)
