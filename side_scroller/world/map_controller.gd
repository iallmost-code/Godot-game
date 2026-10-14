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
        npc.modulate=Color(0.92,0.96,1.0)
        add_child(npc)
        npc.set_pose("idle",1,0)
        make_label("Captain Elowen\nJob advancement",instructor_position+Vector2(-85,-115),Color("f8de9f"),17)
        make_label("Forest ->\nUp to enter",portal_position+Vector2(-60,-130),Color("ebf9e7"),17)
    else:
        for data in [[750,485,300],[1100,375,280],[1500,475,350],[1940,350,300],[2370,455,380]]:
            build_platform(Vector2(data[0],data[1]+9),Vector2(data[2],18),true)
        make_label("<- Willowbridge\nUp to return",portal_position+Vector2(-80,-130),Color("edf5cc"),17)
        make_label("Shift + Shift: double jump\nSpace: attack  •  Z / X: skills after first job",Vector2(390,300),Color("d7e9cc"),16)
        for data in [[640,610,"mossling"],[980,610,"mossling"],[1290,610,"mossling"],[1660,610,"mossling"],[2210,610,"mossling"],[2670,610,"mossling"],[815,485,"lantern"],[1530,475,"lantern"],[2370,455,"lantern"]]:
            var record={"position":Vector2(data[0],data[1]),"id":data[2],"node":null,"timer":0.0}
            spawns.append(record)
            spawn_enemy(record)
    var artwork=preload("res://visuals/world_art.gd").new()
    artwork.map_id=map_id
    artwork.width=width
    artwork.z_index=-10
    artwork.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
    add_child(artwork)
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
    label.add_theme_color_override("font_outline_color",Color(0.1,0.2,0.22,0.85))
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
func _draw():
    # Portal rune with a pulsing center and arch.
    var portal_color=Color("8fecdf")
    draw_arc(portal_position+Vector2(0,-45),42,PI,TAU,24,Color("b9d3c7"),11,true)
    draw_line(portal_position+Vector2(-42,-45),portal_position+Vector2(-42,0),Color("b9d3c7"),11)
    draw_line(portal_position+Vector2(42,-45),portal_position+Vector2(42,0),Color("b9d3c7"),11)
    draw_set_transform(portal_position+Vector2(0,-38),0,Vector2(29,38))
    draw_circle(Vector2.ZERO,1,Color(0.48,0.95,0.86,0.28+sin(Time.get_ticks_msec()/450.0)*0.07))
    draw_set_transform(Vector2.ZERO)
    draw_arc(portal_position+Vector2(0,-38),23,0,TAU,30,portal_color,2,true)
