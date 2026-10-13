extends Node2D
var map_id="town"
var width=1800.0
var state
var player
var pickups: Array=[]
var spawns: Array=[]
var portal_position=Vector2.ZERO
var instructor_position=Vector2(500,610)
var sign_label
signal portal_requested(map_id: String,spawn_id: String)
signal advancement_requested(job_id: String)
signal reward_notice(message: String)
func setup(s):
    state=s
    width=1800 if map_id=="town" else 3000
    build_platform(Vector2(width/2,645),Vector2(width,70),false)
    build_platform(Vector2(-20,300),Vector2(40,900),false)
    build_platform(Vector2(width+20,300),Vector2(40,900),false)
    portal_position=Vector2(1580,610) if map_id=="town" else Vector2(150,610)
    if map_id=="town":
        for data in [[730,460,280],[1220,420,260]]:
            build_platform(Vector2(data[0],data[1]+8),Vector2(data[2],16),true)
        var npc=preload("res://visuals/character_visual.gd").new()
        npc.position=instructor_position
        npc.modulate=Color("d0deba")
        add_child(npc)
        npc.set_pose("idle",1,0)
        make_label("Captain Elowen\nJob advancement",instructor_position+Vector2(-85,-115),Color("f8de9f"),17)
        make_label("WILLOWBRIDGE",Vector2(265,330),Color("495e59"),23)
        make_label("Forest →\nUp to enter",portal_position+Vector2(-60,-130),Color("ebf9e7"),17)
        make_label("A quiet place to begin.\nSpeak to Elowen at levels 10 and 30.",Vector2(820,260),Color("516d68"),17)
    else:
        for data in [[750,485,300],[1100,375,280],[1500,475,350],[1940,350,300],[2370,455,380]]:
            build_platform(Vector2(data[0],data[1]+9),Vector2(data[2],18),true)
        make_label("← Willowbridge\nUp to return",portal_position+Vector2(-80,-130),Color("edf5cc"),17)
        make_label("THE WHISPERWOOD",Vector2(670,230),Color("edf5cc"),23)
        make_label("Shift + Shift: double jump\nSpace: attack  •  Z / X: skills after first job",Vector2(390,300),Color("d7e9cc"),16)
        for data in [[640,610,"mossling"],[980,610,"mossling"],[1290,610,"mossling"],[1660,610,"mossling"],[2210,610,"mossling"],[2670,610,"mossling"],[815,485,"lantern"],[1530,475,"lantern"],[2370,455,"lantern"]]:
            var record={"position":Vector2(data[0],data[1]),"id":data[2],"node":null,"timer":0.0}
            spawns.append(record)
            spawn_enemy(record)
    queue_redraw()
func spawn_position(id: String) -> Vector2:
    if id=="entry": return Vector2(260,590) if map_id=="town" else Vector2(250,590)
    if id=="portal": return Vector2(1450,590) if map_id=="town" else Vector2(250,590)
    return Vector2.INF
func build_platform(pos: Vector2,size: Vector2,one_way: bool):
    var body=StaticBody2D.new()
    var shape=CollisionShape2D.new()
    var rectangle=RectangleShape2D.new()
    rectangle.size=size
    shape.shape=rectangle
    shape.one_way_collision=one_way
    body.position=pos
    body.add_child(shape)
    add_child(body)
func make_label(text,pos,color,size):
    var label=Label.new()
    label.text=text
    label.position=pos
    label.mouse_filter=Control.MOUSE_FILTER_IGNORE
    label.add_theme_font_size_override("font_size",size)
    label.add_theme_color_override("font_color",color)
    label.add_theme_color_override("font_outline_color",Color(0.1,0.2,0.22,0.25))
    label.add_theme_constant_override("outline_size",2)
    add_child(label)
func spawn_enemy(record):
    var enemy=preload("res://actors/enemy.gd").new()
    enemy.definition_id=record.id
    enemy.position=record.position
    enemy.player=player
    add_child(enemy)
    record.node=enemy
    enemy.defeated.connect(func(pos,id): on_defeated(pos,id,record))
func on_defeated(pos: Vector2,id: String,record: Dictionary):
    record.timer=7.0
    state.add_xp(40 if id=="mossling" else 60)
    var reward={"coins":randi_range(2,7)}
    var roll=randf()
    if roll<0.18: reward.potions=1
    elif roll<0.3: reward.item="forest_spear" if randf()<0.5 else "forest_armor"
    var loot=preload("res://world/loot_pickup.gd").new()
    loot.setup(reward)
    loot.position=pos
    add_child(loot)
    pickups.append(loot)
func interact():
    if player.global_position.distance_to(portal_position)<90:
        portal_requested.emit("forest" if map_id=="town" else "town","entry")
    elif map_id=="town" and absf(player.position.x-instructor_position.x)<100:
        advancement_requested.emit("warrior" if state.job=="beginner" else "spearman")
    else: reward_notice.emit("Move near a glowing portal or the town instructor, then press Up.")
func _process(delta):
    for record in spawns:
        if not is_instance_valid(record.node):
            record.timer-=delta
            if record.timer<=0: spawn_enemy(record)
    for drop in pickups.duplicate():
        if not is_instance_valid(drop): pickups.erase(drop)
        elif player!=null and player.position.distance_to(drop.position)<35:
            var text="Equipment found! Open Inventory to equip." if drop.reward.has("item") else "Potion found." if drop.reward.has("potions") else "+%d coins" % drop.reward.coins
            if drop.try_collect(state): reward_notice.emit(text)
    queue_redraw()
func tree_at(x: float,y: float,scale_factor: float,tint: Color):
    var trunk=Color("675c58")
    draw_line(Vector2(x,y),Vector2(x+4*scale_factor,y-125*scale_factor),trunk,22*scale_factor)
    draw_line(Vector2(x,y-65*scale_factor),Vector2(x-30*scale_factor,y-115*scale_factor),trunk,10*scale_factor)
    for offset in [Vector2(-38,-130),Vector2(38,-125),Vector2(0,-170),Vector2(0,-110)]:
        draw_circle(Vector2(x,y)+offset*scale_factor,48*scale_factor,tint)
        draw_arc(Vector2(x,y)+offset*scale_factor,36*scale_factor,3.6,5.4,16,tint.lightened(0.08),4,true)
func house(x: float,y: float,size: float):
    var w=180*size
    var h=142*size
    var p=Vector2(x,y)
    draw_rect(Rect2(p+Vector2(-w/2,-h),Vector2(w,h)),Color("e6d1a7"))
    draw_rect(Rect2(p+Vector2(-w/2+8,-h+10),Vector2(w-16,h-12)),Color("eedfc0"))
    for beam in [-0.45,0,0.45]: draw_line(p+Vector2(w*beam,-h),p+Vector2(w*beam,0),Color("92775d"),8)
    draw_line(p+Vector2(-w/2,-h*0.4),p+Vector2(w/2,-h*0.4),Color("92775d"),8)
    draw_colored_polygon(PackedVector2Array([p+Vector2(-w*0.65,-h+8),p+Vector2(0,-h-78*size),p+Vector2(w*0.65,-h+8)]),Color("647e83"))
    draw_polyline(PackedVector2Array([p+Vector2(-w*0.65,-h+8),p+Vector2(0,-h-78*size),p+Vector2(w*0.65,-h+8)]),Color("455f68"),8,true)
    for roofline in range(3):
        draw_line(p+Vector2(-w*(0.49-roofline*0.13),-h-10-roofline*17*size),p+Vector2(w*(0.49-roofline*0.13),-h-10-roofline*17*size),Color("789797"),3)
    draw_rect(Rect2(p+Vector2(-19,-65*size),Vector2(38,65*size)),Color("8e6755"))
    draw_circle(p+Vector2(10,-30),3,Color("e8ca84"))
    for side in [-1,1]:
        var window_pos=p+Vector2(side*w*0.29-17,-h*0.72)
        draw_rect(Rect2(window_pos,Vector2(34,34)),Color("758f88"))
        draw_rect(Rect2(window_pos+Vector2(4,4),Vector2(26,26)),Color("ffdf99"))
        draw_line(window_pos+Vector2(17,0),window_pos+Vector2(17,34),Color("84705c"),3)
        draw_line(window_pos+Vector2(0,17),window_pos+Vector2(34,17),Color("84705c"),3)
func platform_art(center: Vector2,width_value: float):
    var rect=Rect2(center+Vector2(-width_value/2,0),Vector2(width_value,24))
    draw_style_box(rounded(Color("756c58"),7),rect)
    draw_style_box(rounded(Color("91b877"),7),Rect2(rect.position,Vector2(width_value,10)))
    for x in range(int(rect.position.x)+12,int(rect.end.x)-12,25):
        draw_line(Vector2(x,center.y+16),Vector2(x+8,center.y+18),Color("96836c"),2)
func rounded(color: Color,radius: int):
    var style=StyleBoxFlat.new()
    style.bg_color=color
    style.set_corner_radius_all(radius)
    return style
func _draw():
    var forest=map_id=="forest"
    draw_rect(Rect2(-1000,-1000,width+2000,1800),Color("a5c5b6") if forest else Color("b9dcd8"))
    # Layered misty hills behind the playable foreground.
    for layer in range(3):
        var points=PackedVector2Array([Vector2(-1000,800)])
        for x in range(-1000,int(width)+1200,60):
            points.append(Vector2(x,200+layer*90+sin(x*0.004+layer*2)*55+cos(x*0.009)*20))
        points.append(Vector2(width+1200,800))
        draw_colored_polygon(points,[Color("9fc5b9"),Color("89b3a2"),Color("6f9d86")][layer] if forest else [Color("acd0c9"),Color("92bbae"),Color("83ab92")][layer])
    for x in range(0,int(width)+200,160):
        tree_at(x,520,1.4,Color("668e79") if forest else Color("85b295"))
    if not forest:
        house(320,610,1.0)
        house(940,610,1.3)
        house(1280,610,0.8)
        for x in [60,640,1460,1760]: tree_at(x,610,1.6,Color("709c78"))
        for x in [600,1120,1450]:
            draw_line(Vector2(x,610),Vector2(x,470),Color("756c59"),7)
            draw_rect(Rect2(x-12,473,24,31),Color("f1d29b"))
            draw_circle(Vector2(x,488),20,Color(1,0.9,0.65,0.15))
        for data in [[730,460,280],[1220,420,260]]: platform_art(Vector2(data[0],data[1]),data[2])
    else:
        for x in [480,1040,1800,2630,2890]: tree_at(x,610,2.5,Color("476f60"))
        for data in [[750,485,300],[1100,375,280],[1500,475,350],[1940,350,300],[2370,455,380]]: platform_art(Vector2(data[0],data[1]),data[2])
    draw_rect(Rect2(0,610,width,200),Color("776853"))
    draw_rect(Rect2(0,610,width,17),Color("b2c482") if not forest else Color("94b877"))
    draw_line(Vector2(0,628),Vector2(width,628),Color("5d684b"),5)
    for x in range(10,int(width),35):
        var y=653+posmod(x*17,50)
        draw_line(Vector2(x,y),Vector2(x+15,y+3),Color("988269"),3)
        draw_line(Vector2(x,609),Vector2(x+4,601-posmod(x,9)),Color("789862"),2)
        if x%3==0:
            draw_circle(Vector2(x+10,606),3,Color("edc18e"))
    # Portal rune with a pulsing center and arch.
    var portal_color=Color("8fecdf")
    draw_arc(portal_position+Vector2(0,-45),42,PI,TAU,24,Color("b9d3c7"),11,true)
    draw_line(portal_position+Vector2(-42,-45),portal_position+Vector2(-42,0),Color("b9d3c7"),11)
    draw_line(portal_position+Vector2(42,-45),portal_position+Vector2(42,0),Color("b9d3c7"),11)
    draw_set_transform(portal_position+Vector2(0,-38),0,Vector2(29,38))
    draw_circle(Vector2.ZERO,1,Color(0.48,0.95,0.86,0.28+sin(Time.get_ticks_msec()/450.0)*0.07))
    draw_set_transform(Vector2.ZERO)
    draw_arc(portal_position+Vector2(0,-38),23,0,TAU,30,portal_color,2,true)
