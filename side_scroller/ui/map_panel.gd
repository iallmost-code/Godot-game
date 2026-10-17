extends VBoxContainer
const Style=preload("res://ui/style.gd")
const Maps=preload("res://data/maps.gd")
var map_id="town"
var player_position=Vector2.ZERO
func bind(s,_bindings=null):
    state=s
    refresh()
func set_context(id: String,pos: Vector2):
    map_id=id
    player_position=pos
    refresh()
signal travel_requested(map_id: String)
var state
func refresh():
    Style.clear(self)
    add_child(Style.section("WINDSWEPT ISLAND  /  WORLD MAP"))
    var in_town=map_id=="town"
    add_child(Style.label("Travel: Elowen's airship carries you to any hunting ground from Willowbridge." if in_town else "Return to Willowbridge to travel by airship. Portals lead between areas and to boss lairs.",14,Color("2f5f74")))
    var grid=GridContainer.new()
    grid.columns=4
    grid.add_theme_constant_override("h_separation",8)
    grid.add_theme_constant_override("v_separation",6)
    add_child(grid)
    var areas=[["town","Willowbridge","Safe town • Job instructor",""],["forest","Whisperwood","Lv 3-8 • starter field",""],["briar","Briar Hollow","Lv 15-25 • Rootwarden",""]]
    for r in Maps.regions():
        var bosses=[]
        for boss in r[7]: bosses.append(preload("res://data/enemy_stats.gd").profile(boss).name)
        areas.append([r[0],r[1].capitalize(),r[2]+(" • "+", ".join(bosses) if not bosses.is_empty() else ""),""])
    for area in areas:
        var here=area[0]==map_id or map_id.begins_with("arena_") and Maps.definition(map_id).get("portals",[{}])[0].get("target","")==area[0]
        var card=PanelContainer.new()
        card.custom_minimum_size=Vector2(206,84)
        card.add_theme_stylebox_override("panel",Style.box(Color("e5f2c5") if here else Color("e3edf4"),Color("8daf45") if here else Color("a0b7c6"),4,8))
        var layout=VBoxContainer.new()
        card.add_child(layout)
        layout.add_child(Style.label(area[1],16))
        var info=Style.label(area[2],11)
        info.autowrap_mode=TextServer.AUTOWRAP_WORD
        info.custom_minimum_size.x=190
        layout.add_child(info)
        if here: layout.add_child(Style.label("YOU ARE HERE",11))
        elif in_town and area[0]!="town":
            var id=area[0]
            var go=Style.button("Travel",func(): travel_requested.emit(id))
            go.custom_minimum_size.y=22
            layout.add_child(go)
        grid.add_child(card)
    add_child(Style.section(Maps.definition(map_id).title+"  /  AREA MAP",true))
    var chart=Chart.new()
    chart.map_id=map_id
    chart.player_position=player_position
    chart.custom_minimum_size=Vector2(820,210)
    add_child(chart)
    add_child(Style.label("Yellow dot: you   •   Blue diamonds: portals   •   Red crown: boss",14))
class Chart extends Control:
    var map_id="town"
    var player_position=Vector2.ZERO
    func _draw():
        var definition=Maps.definition(map_id)
        var w=size.x-50
        var factor=w/definition.width
        draw_style_box(Style.box(Color("f6f9fb"),Color("b7c8d3"),4,4),Rect2(Vector2.ZERO,size))
        var ground=165.0
        draw_line(Vector2(25,ground),Vector2(size.x-25,ground),Color("8daa61"),7)
        for platform in definition.platforms:
            var x=25+(platform[0]-platform[2]/2.0)*factor
            var y=ground-(610-platform[1])*0.34
            draw_line(Vector2(x,y),Vector2(x+platform[2]*factor,y),Color("759a6f"),6)
        for portal in definition.portals:
            var p=Vector2(25+portal.position.x*factor,ground-10)
            draw_colored_polygon(PackedVector2Array([p+Vector2(0,-9),p+Vector2(7,0),p+Vector2(0,9),p+Vector2(-7,0)]),Color("3d9ccd"))
        var pos=Vector2(25+player_position.x*factor,ground-(610-player_position.y)*0.34-13)
        draw_circle(pos,7,Color("bb8627"))
        draw_circle(pos,4,Color("fff16c"))
        for entry in definition.enemies:
            if not preload("res://data/enemy_stats.gd").is_boss(entry[2]): continue
            var boss=Vector2(25+entry[0]*factor,ground-10)
            draw_colored_polygon(PackedVector2Array([boss+Vector2(-10,0),boss+Vector2(-10,-13),boss+Vector2(-3,-6),boss+Vector2(0,-17),boss+Vector2(4,-6),boss+Vector2(10,-13),boss+Vector2(10,0)]),Color("c54b67"))
