extends VBoxContainer
const Style=preload("res://ui/style.gd")
const Maps=preload("res://data/maps.gd")
const Travel=preload("res://systems/world_travel.gd")
signal travel_requested(destination: String)
signal town_requested
var state
var mode="guide"
var map_id="town"
var player_position=Vector2.ZERO
var selected_region="town"
var selected_area="town"
func bind(_state,_bindings=null):
    state=_state
    refresh()
func set_context(id: String,pos: Vector2):
    map_id=id
    player_position=pos
    selected_region=Maps.definition(id).region
    selected_area=id
    refresh()
func inspect_region(id: String):
    selected_region=id
    selected_area=id
    refresh()
func refresh():
    Style.clear(self)
    var navigation=HFlowContainer.new()
    add_child(navigation)
    navigation.add_child(Style.button("Level guide",show_guide))
    navigation.add_child(Style.button("All towns",func(): mode="towns"; refresh()))
    navigation.add_child(Style.button("Area atlas",func(): mode="atlas"; refresh()))
    navigation.add_child(Style.button("Nearest town [T]",func(): town_requested.emit()))
    navigation.add_child(Style.button("Portal hub [H]",func(): travel_requested.emit("portal_hub")))
    if mode=="guide":
        draw_guide()
        return
    if mode=="towns":
        add_child(Style.section("TOWN DIRECTORY / FREE TELEPORT"))
        for town in Maps.regions():
            var destination=town.id
            add_child(Style.button("Lv %d+  •  %s  —  Travel" % [town.level,town.name],func(): travel_requested.emit(destination)))
        return
    add_child(Style.section("WINDSWEPT WORLD ATLAS  /  %d regions - %d playable maps" % [Maps.regions().size(),Maps.all_ids().size()]))
    var columns=HBoxContainer.new()
    columns.add_theme_constant_override("separation",10)
    add_child(columns)
    var scroll=ScrollContainer.new()
    scroll.custom_minimum_size=Vector2(220,340)
    scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
    columns.add_child(scroll)
    var regions=VBoxContainer.new()
    scroll.add_child(regions)
    var active_index=0
    var index=0
    for region in Maps.regions():
        var id=region.id
        var button=Style.button(region.name,func(): inspect_region(id))
        button.custom_minimum_size=Vector2(198,30)
        button.tooltip_text="Inspect this region. Travel through world portals to visit."
        if id==selected_region:
            button.modulate=Color("bbdc96")
            active_index=index
        regions.add_child(button)
        index+=1
    scroll.set_deferred("scroll_vertical",maxi(0,active_index*35-100))
    var info=VBoxContainer.new()
    info.custom_minimum_size.x=610
    columns.add_child(info)
    var region=Maps.definition(selected_region)
    var area=Maps.definition(selected_area)
    info.add_child(Style.section(region.name.to_upper()+"  /  "+region.biome.capitalize()))
    var areas=HFlowContainer.new()
    info.add_child(areas)
    for id in Maps.all_ids():
        var definition=Maps.definition(id)
        if definition.region!=selected_region: continue
        var button=Style.button(definition.name,func(): selected_area=id; refresh())
        if id==selected_area: button.modulate=Color("bbdc96")
        areas.add_child(button)
    info.add_child(Style.label("Safe town - health recovery and respawn checkpoint" if area.safe else ("Boss lair - Lv %d boss" % area.level if area.has("boss") else "Level %d+ hunting - scaled enemies and equipment drops" % area.level),14))
    var routes=[]
    for portal in area.portals:
        routes.append(Maps.definition(portal.target).name)
    var steps=[]
    for id in Maps.route_between(map_id,selected_area): steps.append(Maps.definition(id).name)
    var route_text=Style.label("Portals: "+", ".join(routes)+"\nRoute from here: "+" > ".join(steps),13)
    route_text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    route_text.custom_minimum_size.x=580
    info.add_child(route_text)
    var chart=Chart.new()
    chart.map_id=selected_area
    chart.player_position=player_position
    chart.show_player=selected_area==map_id
    chart.custom_minimum_size=Vector2(600,195)
    info.add_child(chart)
    info.add_child(Style.button("Travel to "+area.name,func(): travel_requested.emit(selected_area)))
    info.add_child(Style.section("YOU ARE IN: "+Maps.definition(map_id).name,true))
    var local=Style.button("Show my current area",func(): set_context(map_id,player_position))
    info.add_child(local)
    add_child(Style.label("Yellow: you   Blue: portals   Red crown: boss. Use Travel to visit the selected area. Boss travel stops at the gate town.
Travel by standing at the named portal and pressing your Interact key. Towns are safe checkpoints.",13))
class Chart extends Control:
    var map_id="town"
    var player_position=Vector2.ZERO
    var show_player=true
    func _draw():
        var definition=Maps.definition(map_id)
        var w=size.x-50
        var factor=w/definition.width
        draw_style_box(Style.box(Color("f6f9fb"),Color("b7c8d3"),4,4),Rect2(Vector2.ZERO,size))
        var ground=165.0
        var vertical=minf(0.34,135.0/maxf(400,610-definition.get("top",0)))
        draw_line(Vector2(25,ground),Vector2(size.x-25,ground),Color("8daa61"),7)
        for platform in definition.platforms:
            var x=25+(platform[0]-platform[2]/2.0)*factor
            var y=ground-(610-platform[1])*vertical
            draw_line(Vector2(x,y),Vector2(x+platform[2]*factor,y),Color("759a6f"),6)
        for portal in definition.portals:
            var p=Vector2(25+portal.position.x*factor,ground-10)
            draw_colored_polygon(PackedVector2Array([p+Vector2(0,-9),p+Vector2(7,0),p+Vector2(0,9),p+Vector2(-7,0)]),Color("3d9ccd"))
        var pos=Vector2(25+player_position.x*factor,ground-(610-player_position.y)*vertical-13)
        if show_player:
            draw_circle(pos,7,Color("bb8627"))
            draw_circle(pos,4,Color("fff16c"))
        for entry in definition.enemies:
            if not preload("res://data/enemy_stats.gd").is_boss(entry[2]): continue
            var boss=Vector2(25+entry[0]*factor,ground-10)
            draw_colored_polygon(PackedVector2Array([boss+Vector2(-10,0),boss+Vector2(-10,-13),boss+Vector2(-3,-6),boss+Vector2(0,-17),boss+Vector2(4,-6),boss+Vector2(10,-13),boss+Vector2(10,0)]),Color("c54b67"))

func show_guide():
    mode="guide"
    refresh()
func draw_guide():
    var level=state.level if state!=null else 1
    var recommended=Travel.recommended(level)
    add_child(Style.section("YOUR JOURNEY  /  LEVEL %d" % level))
    var next_job=Travel.next_job_level(state) if state!=null else 10
    var heading=Style.label("Recommended: "+Maps.definition(recommended.field).name+" • Lv %d–%d" % [recommended.low,recommended.high],19)
    add_child(heading)
    add_child(Style.button("Travel to recommended hunting grounds",func(): travel_requested.emit(recommended.field)))
    if next_job>0:
        add_child(Style.label("Next job advancement: level %d. Visit Captain Elowen in a town and press Up." % next_job,14))
    var help=Style.label("Follow the level bands below. Fight nearby monsters, collect loot and complete town quests.
Hold Down + Jump to descend through platforms. Up climbs or enters a portal.
H opens the all-town portal hub; T returns to the nearest town. Travel is free.",14)
    help.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    add_child(help)
    for stage in Travel.STAGES:
        var destination=stage.field
        var row=HBoxContainer.new()
        add_child(row)
        var label=Style.label(("> " if stage==recommended else "")+"Lv %d–%d  •  %s  /  %s" % [stage.low,stage.high,Maps.definition(stage.field).name,Maps.definition(stage.town).name],14)
        label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
        row.add_child(label)
        row.add_child(Style.button("Travel",func(): travel_requested.emit(destination)))
