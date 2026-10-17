extends Node2D
const Maps=preload("res://data/maps.gd")
const BRIAR=preload("res://art/briar_background.png")
const SKY=preload("res://art/sky.png")
const PROPS=preload("res://art/props.png")
const TERRAIN=preload("res://art/terrain.png")
const TREE=Rect2(74,10,622,634)
const COTTAGE=Rect2(782,56,724,583)
const BUSH=Rect2(134,680,597,334)
const SIGN=Rect2(949,690,378,316)
const TILE=Rect2(0,185,2048,459)
var map_id="town"
var width=1800.0
var sky_sprite: Sprite2D
func _ready():
    sky_sprite=Sprite2D.new()
    var backdrop=BRIAR if map_id=="briar" else SKY
    sky_sprite.texture=backdrop
    sky_sprite.centered=false
    sky_sprite.scale=Vector2((width+600)/backdrop.get_width(),760.0/backdrop.get_height())
    sky_sprite.position=Vector2(-300,-100)
    sky_sprite.z_index=-20
    add_child(sky_sprite)
func _process(_delta):
    var camera=get_viewport().get_camera_2d()
    if camera!=null:
        sky_sprite.position.x=-300+maxf(0,camera.global_position.x-557)*0.65
func prop(region: Rect2,foot: Vector2,size: Vector2,tint=Color.WHITE):
    var destination=Rect2(foot-Vector2(size.x/2,size.y),size)
    draw_texture_rect_region(PROPS,destination,region,tint)
func terrain_strip(x: float,y: float,length: float,depth: float):
    var natural_width=360.0
    var offset=0.0
    while offset<length:
        var segment=minf(natural_width,length-offset)
        var source=Rect2(TILE.position,Vector2(TILE.size.x*segment/natural_width,TILE.size.y))
        draw_texture_rect_region(TERRAIN,Rect2(x+offset,y-12,segment,depth),source,Color("c7bddc") if map_id=="briar" else Color.WHITE)
        offset+=segment
func _draw():
    if map_id=="briar":
        for x in [560,1720,2440]: prop(TREE,Vector2(x,610),Vector2(270,275),Color("b5a5c8"))
        for x in [420,1220,2070,2600,3250]: prop(BUSH,Vector2(x,610),Vector2(150,90),Color("d7bbd8"))
        prop(SIGN,Vector2(2650,610),Vector2(85,89))
    else:
        for x in range(-120,int(width)+450,420):
            prop(TREE,Vector2(x,588),Vector2(320,325),Color(0.73,0.87,0.81,0.72))
        if map_id=="forest":
            for x in [520,1130,1850,2700]: prop(TREE,Vector2(x,610),Vector2(460,467))
            for x in [480,950,1610,2240,2820]: prop(BUSH,Vector2(x,610),Vector2(190,114))
            prop(SIGN,Vector2(350,610),Vector2(85,89))
        else:
            prop(COTTAGE,Vector2(300,610),Vector2(350,300))
            prop(COTTAGE,Vector2(930,610),Vector2(315,270))
            prop(COTTAGE,Vector2(1320,610),Vector2(280,240))
            for x in [60,720,1720]: prop(TREE,Vector2(x,610),Vector2(350,355))
            for x in [70,650,1090,1450]: prop(BUSH,Vector2(x,610),Vector2(150,90))
            prop(SIGN,Vector2(600,610),Vector2(78,65))
    for platform in Maps.definition(map_id).platforms:
        terrain_strip(platform[0]-platform[2]/2.0,platform[1],platform[2],67 if map_id=="town" else 77)
    terrain_strip(0,610,width,150)
