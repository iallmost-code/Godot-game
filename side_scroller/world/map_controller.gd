extends Node2D
const Maps=preload("res://data/maps.gd")
const Catalog=preload("res://data/catalog.gd")
const EnemyStats=preload("res://data/enemy_stats.gd")
const Quests=preload("res://systems/quests.gd")
const Adventure=preload("res://data/adventure.gd")
const UiIcons=preload("res://visuals/ui_icon_layout.gd")
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
signal shop_requested
signal quest_requested(npc: String)
var climbs: Array=[]
var top=137.0
var quest_givers: Array=[]
var merchant_position=Vector2(800,610)
func setup(s):
    state=s
    var data=Maps.definition(map_id)
    width=data.width
    portals=data.portals
    portal_position=portals[0].position
    climbs=data.get("climbs",[])
    top=data.get("top",137.0)
    build_platform(Vector2(width/2,645),Vector2(width,70),false)
    build_platform(Vector2(-20,300),Vector2(40,900),false)
    build_platform(Vector2(width+20,300),Vector2(40,900),false)
    for platform in data.platforms:
        build_platform(Vector2(platform[0],platform[1]+8),Vector2(platform[2],16),true)
    for portal in portals:
        make_label(portal.label,portal.position+Vector2(-85,-160),Color("edf5cc"),15)
    if data.safe:
        var npc=preload("res://visuals/character_visual.gd").new()
        instructor_position=Vector2(500 if map_id=="town" else 600,610)
        npc.position=instructor_position
        npc.modulate=Color(0.92,0.96,1.0)
        add_child(npc)
        npc.set_pose("idle",1,0)
        make_label(data.npc.name+("\nJob advancement" if data.npc.path!="" else "\nUp to talk"),instructor_position+Vector2(-85,-115),Color("f8de9f"),17)
        var merchant=preload("res://visuals/character_visual.gd").new()
        merchant.position=merchant_position
        merchant.modulate=Color(1.0,0.9,0.75)
        add_child(merchant)
        merchant.set_pose("idle",-1,0)
        make_label("Merchant\nShop • Sell • Forge",merchant_position+Vector2(-75,-115),Color("ffe2a8"),17)
        for giver in Quests.givers(map_id):
            var npc_visual=preload("res://world/npc_sprite.gd").new()
            npc_visual.npc_name=giver.name
            npc_visual.position=Vector2(giver.x,610)
            add_child(npc_visual)
            quest_givers.append(giver)
            make_label(giver.name+"\nQuests",Vector2(giver.x-75,495),Color("d6f5b0"),17)
    else:
        make_label(data.get("notice","Explore the trails and return to town to recover."),Vector2(380,300),Color("e7d2ed"),16)
        for entry in data.enemies:
            var record={"position":Vector2(entry[0],entry[1]),"id":entry[2],"node":null,"timer":0.0,"level":entry[3] if entry.size()>3 else 0}
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
    enemy.level=record.level
    enemy.area_tint=preload("res://visuals/world_theme.gd").enemy_tint(Maps.definition(map_id).biome)
    add_child(enemy)
    record.node=enemy
    if record.position.y<600:
        for platform in Maps.definition(map_id).platforms:
            if absf(platform[1]-record.position.y)<4 and absf(platform[0]-record.position.x)<=platform[2]/2.0:
                enemy.set_meta("span",Vector2(platform[0]-platform[2]/2.0+18,platform[0]+platform[2]/2.0-18))
    if EnemyStats.is_boss(record.id):
        boss=enemy
        boss_spawned.emit(enemy)
    enemy.defeated.connect(func(pos,id): on_defeated(pos,id,record))
func monster_level(id: String,record) -> int:
    if record is Dictionary and record.get("level",0)>0: return record.level
    return EnemyStats.profile(id).level
func reward_for(id: String,lv: int) -> Dictionary:
    var profile=EnemyStats.profile(id)
    var data=Maps.definition(map_id)
    var loot=data.get("loot_zone","forest")
    var advanced=data.get("level",1)>=15
    var reward={"coins":randi_range(2+int(lv/2.0),6+lv) if lv>=25 else randi_range(7,14) if advanced else randi_range(2,7)}
    var weapon_type=state.preferred_weapon()
    var roll=randf()
    if id=="rootwarden":
        reward={"coins":75,"potions":3,"item":"warden_"+weapon_type}
        reward_notice.emit("Rootwarden defeated! Collect your guaranteed weapon and potions.")
    elif EnemyStats.is_boss(id):
        var prize="%s_%s" % [weapon_type,loot] if loot.begins_with("lv") else "%s_%s" % [loot,weapon_type]
        reward={"coins":30*lv,"potions":5,"item":prize if Catalog.items().has(prize) else "warden_"+weapon_type}
        reward_notice.emit("%s defeated! Collect its treasure." % profile.name)
    elif roll<0.18:
        # Potions match the monster's level; about a third are mana.
        if randf()<0.33: reward.consumable="mp_1" if lv<40 else "mp_2" if lv<100 else "mp_3"
        else: reward.consumable="hp_1" if lv<20 else "hp_2" if lv<50 else "hp_3" if lv<100 else "hp_4"
    elif roll<(0.42 if advanced else 0.3):
        var band=loot if loot.begins_with("lv") else Maps.band_for(maxi(lv,data.get("level",1)))
        var pick=randf()
        if pick<0.4: reward.item=("%s_%s" % [weapon_type,loot]) if loot.begins_with("lv") else loot+"_"+weapon_type
        elif pick<0.6: reward.item=("armor_"+loot) if loot.begins_with("lv") else loot+"_armor"
        else: reward.item="%s_%s" % [["hat","gloves","shoes","cape","earring"].pick_random(),band]
    elif roll<0.48: reward.shards=1+int(lv/25.0)
    elif roll<0.505: reward={"scroll":Adventure.random_scroll()}
    if EnemyStats.is_boss(id): reward.shards=5+int(lv/10.0)
    return reward
func grant_xp(id: String,node,lv: int=0):
    var profile=EnemyStats.profile(id)
    if lv<=0: lv=profile.level
    var base=profile.xp
    if lv!=profile.level: base=int(profile.xp*float(lv)/profile.level) if profile.get("sprite",false) else int(profile.xp*float(EnemyStats.xp_for(lv))/EnemyStats.xp_for(profile.level))
    var multiplier=(1.0+state.bonus("xp_pct"))*(node.xp_multiplier() if is_instance_valid(node) and node.has_method("xp_multiplier") else 1.0)
    state.add_xp(maxi(1,int(base*multiplier)))
func on_defeated(pos: Vector2,id: String,record: Dictionary):
    record.timer=45.0 if id=="rootwarden" else 90.0 if EnemyStats.is_boss(id) else 9.0 if map_id=="briar" else 7.0
    var lv=monster_level(id,record)
    grant_xp(id,record.node,lv)
    spawn_loot(pos,reward_for(id,lv))
    for note in Quests.on_kill(state,id): reward_notice.emit(note)
    var wanted=Quests.wanted_drop(state,id)
    if wanted!="" and randf()<0.6: spawn_loot(pos+Vector2(randf_range(-30,30),0),{"quest_item":wanted})
    if EnemyStats.is_boss(id):
        for i in 2: spawn_loot(pos+Vector2(40+i*30,0),{"scroll":Adventure.random_scroll()})
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
    var data=Maps.definition(map_id)
    for giver in quest_givers:
        if absf(player.position.x-giver.x)<70 and player.position.y>560:
            quest_requested.emit(giver.name)
            return
    if data.safe and absf(player.position.x-merchant_position.x)<80:
        shop_requested.emit()
        return
    if data.safe and absf(player.position.x-instructor_position.x)<100:
        var instructor=data.npc
        if instructor.path=="all" or instructor.path==state.archetype:
            advancement_requested.emit(state.next_job())
        else: reward_notice.emit(instructor.name+": "+instructor.greeting)
    else: reward_notice.emit("Move near a glowing portal or the town instructor, then press Up.")
func _process(delta):
    for record in spawns:
        if not is_instance_valid(record.node):
            record.timer-=delta
            if record.timer<=0: spawn_enemy(record)
    for drop in pickups.duplicate():
        if not is_instance_valid(drop): pickups.erase(drop)
        elif player!=null and player.position.distance_to(drop.position)<35: collect(drop)
    queue_redraw()
func collect(drop) -> bool:
    if not is_instance_valid(drop): return false
    var r=drop.reward
    var text="%s found! Open Inventory to equip." % Catalog.items()[r.item].name if r.has("item") else "%s found." % Catalog.consumables()[r.consumable].name if r.has("consumable") else "Potion found." if r.has("potions") else "+%d Shards" % r.shards if r.has("shards") else "%s found!" % Adventure.scrolls()[r.scroll].name if r.has("scroll") else "%s (%d)" % [Adventure.QUEST_ITEMS[r.quest_item],int(state.quest_items.get(r.quest_item,0))+1] if r.has("quest_item") else "+%d coins" % r.get("coins",0)
    if drop.try_collect(state):
        reward_notice.emit(text)
        pickups.erase(drop)
        return true
    if r.has("item") and not drop.get_meta("full_warned",false):
        drop.set_meta("full_warned",true)
        reward_notice.emit("Inventory full. Sell or dismantle gear to make room.")
    return false
func _draw():
    for portal in portals: draw_portal(portal.position)
    for giver in quest_givers:
        var mark=Quests.marker(state,map_id,giver.name)
        if mark=="": continue
        var key={"!":"quest_available","!locked":"quest_locked","?":"quest_ready","…":"quest_progress"}[mark]
        var bob=sin(Time.get_ticks_msec()/260.0)*4
        draw_texture_rect_region(UiIcons.ART,Rect2(giver.x-22,430+bob,44,44),UiIcons.DATA[key])
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
