extends Node2D
const Maps=preload("res://data/maps.gd")
const Catalog=preload("res://data/catalog.gd")
const EnemyStats=preload("res://data/enemy_stats.gd")
var map_id="town"
var width=1800.0
var state
var player
var pickups: Array=[]
var spawns: Array=[]
var portal_position=Vector2.ZERO
var instructor_position=Vector2(500,610)
var sign_label
var portals: Array=[]
var boss
signal portal_requested(map_id: String,spawn_id: String)
signal advancement_requested(job_id: String)
signal reward_notice(message: String)
signal boss_spawned(enemy: Node2D)
func setup(s):
    state=s
    var data=Maps.definition(map_id)
    width=data.width
    portals=data.portals
    portal_position=portals[0].position
    build_platform(Vector2(width/2,645),Vector2(width,70),false)
    build_platform(Vector2(-20,300),Vector2(40,900),false)
    build_platform(Vector2(width+20,300),Vector2(40,900),false)
    for platform in data.platforms:
        build_platform(Vector2(platform[0],platform[1]+8),Vector2(platform[2],16),true)
    for portal in portals:
        make_label(portal.label,portal.position+Vector2(-85,-130),Color("edf5cc"),17)
    if map_id=="town":
        var npc=preload("res://visuals/character_visual.gd").new()
        npc.position=instructor_position
        npc.modulate=Color(0.92,0.96,1.0)
        add_child(npc)
        npc.set_pose("idle",1,0)
        make_label("Captain Elowen\nJob advancement",instructor_position+Vector2(-85,-115),Color("f8de9f"),17)
    else:
        make_label(data.get("sign",""),Vector2(380,300),Color("e7d2ed"),16)
        for entry in data.enemies:
            var record={"position":Vector2(entry[0],entry[1]),"id":entry[2],"node":null,"timer":0.0}
            spawns.append(record)
            spawn_enemy(record)
    var artwork=preload("res://visuals/world_art.gd").new()
    artwork.map_id=map_id
    artwork.width=width
    artwork.z_index=-10
    artwork.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
    add_child(artwork)
    queue_redraw()
func spawn_position(id: String) -> Vector2:
    return Maps.definition(map_id).spawns.get(id,Vector2.INF)
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
    var enemy=preload("res://actors/rootwarden.gd").new() if record.id=="rootwarden" else preload("res://actors/boss.gd").new() if EnemyStats.is_boss(record.id) else preload("res://actors/enemy.gd").new()
    enemy.definition_id=record.id
    enemy.position=record.position
    enemy.player=player
    add_child(enemy)
    record.node=enemy
    if EnemyStats.is_boss(record.id):
        boss=enemy
        boss_spawned.emit(enemy)
    enemy.defeated.connect(func(pos,id): on_defeated(pos,id,record))
func reward_for(id: String) -> Dictionary:
    var profile=EnemyStats.profile(id)
    var lv=profile.level
    var loot=Maps.definition(map_id).get("loot","forest")
    var reward={"coins":randi_range(7,14) if loot=="briar" else randi_range(2,7) if loot=="forest" else randi_range(2+lv/2,6+lv)}
    var weapon_type=state.preferred_weapon()
    var roll=randf()
    if id=="rootwarden":
        reward={"coins":75,"potions":3,"item":"warden_"+weapon_type}
        reward_notice.emit("Rootwarden defeated! Collect your guaranteed weapon and potions.")
    elif EnemyStats.is_boss(id):
        reward={"coins":30*lv,"potions":5,"item":("%s_%s" % [weapon_type,loot]) if Catalog.items().has("%s_%s" % [weapon_type,loot]) else "warden_"+weapon_type}
        reward_notice.emit("%s defeated! Collect its treasure." % profile.name)
    elif roll<0.18: reward.potions=1
    elif roll<(0.42 if loot=="briar" else 0.3):
        if loot in ["forest","briar"]: reward.item=loot+"_"+weapon_type if randf()<0.5 else loot+"_armor"
        else: reward.item=("%s_%s" % [weapon_type,loot]) if randf()<0.5 else "armor_"+loot
    return reward
func grant_xp(id: String,node):
    var multiplier=(1.0+state.bonus("xp_pct"))*(node.xp_multiplier() if is_instance_valid(node) and node.has_method("xp_multiplier") else 1.0)
    state.add_xp(int(EnemyStats.profile(id).xp*multiplier))
func on_defeated(pos: Vector2,id: String,record: Dictionary):
    record.timer=45.0 if id=="rootwarden" else 90.0 if EnemyStats.is_boss(id) else 9.0 if map_id=="briar" else 7.0
    grant_xp(id,record.node)
    spawn_loot(pos,reward_for(id))
func spawn_loot(pos: Vector2,reward: Dictionary):
    var loot=preload("res://world/loot_pickup.gd").new()
    loot.setup(reward)
    loot.position=pos
    add_child(loot)
    pickups.append(loot)
func spawn_minion(id: String,pos: Vector2):
    var enemy=preload("res://actors/enemy.gd").new()
    enemy.definition_id=id
    enemy.position=Vector2(clampf(pos.x,80,width-80),pos.y)
    enemy.player=player
    add_child(enemy)
    enemy.add_to_group("boss_minions")
    enemy.defeated.connect(func(_pos,minion_id): grant_xp(minion_id,enemy))
func interact():
    for portal in portals:
        if player.global_position.distance_to(portal.position)<90:
            portal_requested.emit(portal.target,portal.spawn)
            return
    if map_id=="town" and absf(player.position.x-instructor_position.x)<100:
        advancement_requested.emit(state.next_job())
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
    for portal in portals: draw_portal(portal.position)
func draw_portal(portal_position: Vector2):
    # Portal rune with a pulsing center and arch.
    var portal_color=Color("8fecdf")
    draw_arc(portal_position+Vector2(0,-45),42,PI,TAU,24,Color("b9d3c7"),11,true)
    draw_line(portal_position+Vector2(-42,-45),portal_position+Vector2(-42,0),Color("b9d3c7"),11)
    draw_line(portal_position+Vector2(42,-45),portal_position+Vector2(42,0),Color("b9d3c7"),11)
    draw_set_transform(portal_position+Vector2(0,-38),0,Vector2(29,38))
    draw_circle(Vector2.ZERO,1,Color(0.48,0.95,0.86,0.28+sin(Time.get_ticks_msec()/450.0)*0.07))
    draw_set_transform(Vector2.ZERO)
    draw_arc(portal_position+Vector2(0,-38),23,0,TAU,30,portal_color,2,true)
