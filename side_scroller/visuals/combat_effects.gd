extends Node2D
const AttackArt=preload("res://visuals/attack_art.gd")
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
    data.age=-data.get("delay",0.0)
    shapes.append(data)
func show_effect(kind: String,data: Dictionary):
    var color=ELEMENT_COLORS.get(data.get("element",""),ELEMENT_COLORS[""])
    match kind:
        "launch": add_shape("muzzle",{"position":data.position,"color":color,"index":AttackArt.element_index(data.get("element","")),"style":data.get("style","star")})
        "heal": show_heal(data.position,data.amount)
        "aura": add_shape("aura",{"position":data.position,"color":color,"radius":46})
        "burst": add_shape("burst",{"position":data.position,"color":color,"radius":data.get("radius",80)})
        "chain": add_shape("chain",{"points":data.points,"color":color})
        "element":
            var reach=data.reach
            var center=data.position+Vector2(0 if data.both else data.facing*reach/2,0)
            add_shape("rain" if data.shape=="drop" else "element_burst",{"position":center,"color":color,"radius":reach if data.both else reach/2,"width":reach*(2 if data.both else 1),"index":AttackArt.element_index(data.get("element","")),"delay":data.get("delay",0.0)})
func show_hit(pos: Vector2,critical=false):
    add_shape("impact",{"position":pos,"radius":28 if critical else 19,"color":Color("ffcf78") if critical else Color.WHITE})
func show_attack(id: String,origin: Vector2,facing: int,reach=-1.0,windup=0.08):
    var skill=preload("res://data/catalog.gd").skill(id)
    if skill.is_empty() or skill.get("shape","melee")=="projectile": return
    if effects.size()>=30: effects.pop_front()
    if reach<0: reach=skill.reach
    var fx=skill.get("fx","slash")
    if fx in ["burst","rain","lightning","aura","heal"] and skill.get("element","")!="": return
    effects.append({"id":id,"fx":fx,"position":origin,"facing":facing,"reach":reach,"age":-windup,"both":skill.get("both",false)})
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
        if e.age<0:
            var point=e.position+Vector2(e.facing*20,-32)
            AttackArt.draw(self,3,Rect2(point-Vector2(9,9),Vector2(18,18)),Color(1,1,1,0.3))
            continue
        var fade=clampf((0.42-e.age)/0.18,0,1)
        var growth=0.8+0.2*minf(1,e.age/0.08)
        var tint=Color(1,1,1,fade)
        var sides=[e.facing,-e.facing] if e.both else [e.facing]
        for face in sides:
            draw_set_transform(e.position,0,Vector2(face,1))
            if e.fx=="rain":
                # Physical rain (Arrow Storm/Bolt Eruption) has no element event.
                for i in range(8):
                    var x=fmod(i*97.0,maxf(1,e.reach))
                    var y=-230+fmod(e.age*650+i*41,230)
                    AttackArt.draw_named(self,"rain_arrows",Rect2(x-22,y-32,44,64),Color(1,1,1,fade))
            elif e.fx in ["burst","lightning","aura","heal"]:
                var radius=e.reach*(1.0 if e.both else 0.5)
                AttackArt.draw_named(self,"burst_arcane",Rect2(0,-radius*0.8,radius*2,radius*1.2),Color(1,1,1,fade*0.8))
            elif e.fx=="wave" or e.id=="wave":
                AttackArt.draw(self,2,Rect2(0,-125,e.reach,135),tint)
            elif e.fx=="thrust" or e.id=="thrust":
                AttackArt.draw(self,1,Rect2(0,-61,e.reach*growth,49),tint)
            else:
                AttackArt.draw(self,0,Rect2(3,-116,e.reach*growth,128),tint)
            draw_set_transform(Vector2.ZERO)
    for shape in shapes:
        if shape.age<0: continue
        var fade=clampf((0.5-shape.age)/0.22,0,1)
        var color: Color=shape.get("color",Color.WHITE)
        var progress=shape.age/0.5
        match shape.kind:
            "impact":
                var r=shape.radius*(0.65+progress*0.5)
                AttackArt.draw(self,3,Rect2(shape.position-Vector2(r,r),Vector2(r*2,r*2)),Color(color,fade))
            "muzzle":
                if shape.age>0.16: continue
                var r=14.0 if shape.style=="arrow" else 23.0
                AttackArt.draw(self,shape.index,Rect2(shape.position-Vector2(r,r),Vector2(r*2,r*2)),Color(1,1,1,(1-shape.age/0.16)*0.8))
            "aura":
                var r=shape.radius*(0.9+progress*0.3)
                draw_set_transform(shape.position+Vector2(0,-30),shape.age*0.4)
                AttackArt.draw_named(self,"buff_aura",Rect2(-r,-r,r*2,r*2),Color(1,1,1,fade*0.8))
                draw_set_transform(Vector2.ZERO)
            "heal":
                for i in range(6):
                    var angle=i*TAU/6+shape.age*3
                    var point=shape.position+Vector2(cos(angle)*shape.radius*0.6,-40-shape.age*80+sin(angle)*10)
                    AttackArt.draw_named(self,"heal_sparkles",Rect2(point-Vector2(14,14),Vector2(28,28)),Color(1,1,1,fade))
            "burst","element_burst":
                var r=shape.radius*(0.8+progress*0.2)
                var origin=shape.position+Vector2(-r,-r*0.8-25)
                AttackArt.draw_named(self,"burst_"+AttackArt.element_for_color(color),Rect2(origin,Vector2(r*2,r*1.4)),Color(1,1,1,fade*0.9))
            "rain":
                var width=shape.get("width",400.0)
                for i in range(10):
                    var x=shape.position.x-width/2+fmod(i*97.0,width)
                    var y=shape.position.y-240+fmod(shape.age*650+i*53,250)
                    var rain_kind="rain_"+AttackArt.element_for_color(color)
                    if not AttackArt.EFFECTS.has(rain_kind): rain_kind="rain_holy"
                    var holy=rain_kind=="rain_holy"
                    AttackArt.draw_named(self,rain_kind,Rect2(x-26,y-62 if holy else y-32,52,112 if holy else 64),Color(1,1,1,fade))
            "chain":
                var points: Array=shape.points
                for i in range(points.size()-1):
                    var a: Vector2=points[i]
                    var b: Vector2=points[i+1]
                    var chain=PackedVector2Array([a])
                    for step in range(1,6):
                        var offset=sin(i*7.0+step*2.3+int(shape.age*18)*1.7)*12
                        chain.append(a.lerp(b,step/6.0)+Vector2(0,offset))
                    chain.append(b)
                    draw_set_transform(a,(b-a).angle())
                    AttackArt.draw_named(self,"chain_lightning",Rect2(0,-15,a.distance_to(b),30),Color(1,1,1,fade))
                    draw_set_transform(Vector2.ZERO)
                    draw_polyline(chain,Color(color,fade*0.3),10,true)
                    draw_polyline(chain,Color(color,fade),4,true)
                    draw_polyline(chain,Color(1,1,1,fade),1.5,true)
                    AttackArt.draw(self,3,Rect2(b-Vector2(16,16),Vector2(32,32)),Color(1,1,1,fade))
