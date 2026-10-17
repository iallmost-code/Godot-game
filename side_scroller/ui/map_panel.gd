extends VBoxContainer
const Style=preload("res://ui/style.gd")
const Maps=preload("res://data/maps.gd")
var map_id="town"
var player_position=Vector2.ZERO
func bind(_state,_bindings=null):
    refresh()
func set_context(id: String,pos: Vector2):
    map_id=id
    player_position=pos
    refresh()
func refresh():
    Style.clear(self)
    add_child(Style.section("WINDSWEPT ISLAND  /  WORLD MAP"))
    var route=HBoxContainer.new()
    route.add_theme_constant_override("separation",10)
    add_child(route)
    var areas=[["town","Willowbridge","Safe town • Job instructor"],["forest","Whisperwood","Starter hunting grounds"],["briar","Briar Hollow","Level 15+ • Rootwarden 25+"]]
    for area in areas:
        var card=PanelContainer.new()
        card.custom_minimum_size=Vector2(268,92)
        card.add_theme_stylebox_override("panel",Style.box(Color("e5f2c5") if area[0]==map_id else Color("e3edf4"),Color("8daf45") if area[0]==map_id else Color("a0b7c6"),5,10))
        var layout=VBoxContainer.new()
        card.add_child(layout)
        layout.add_child(Style.label(area[1],19))
        layout.add_child(Style.label(area[2],13))
        layout.add_child(Style.label("YOU ARE HERE" if area[0]==map_id else "Connected by ground portal",12))
        route.add_child(card)
    add_child(Style.section(Maps.definition(map_id).title+"  /  AREA MAP",true))
    var chart=Chart.new()
    chart.map_id=map_id
    chart.player_position=player_position
    chart.custom_minimum_size=Vector2(820,210)
    add_child(chart)
    add_child(Style.label("Yellow dot: you   •   Blue diamonds: portals   •   Red crown: Rootwarden\nTravel in the world: stand by a portal and press your Interact key. This map does not teleport you.",14))
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
        if map_id=="briar":
            var boss=Vector2(25+2920*factor,ground-10)
            draw_colored_polygon(PackedVector2Array([boss+Vector2(-10,0),boss+Vector2(-10,-13),boss+Vector2(-3,-6),boss+Vector2(0,-17),boss+Vector2(4,-6),boss+Vector2(10,-13),boss+Vector2(10,0)]),Color("c54b67"))
