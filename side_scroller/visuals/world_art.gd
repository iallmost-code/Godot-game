extends Node2D
const SKY=preload("res://art/sky.png")
const PROPS=preload("res://art/props.png")
const TERRAIN=preload("res://art/terrain.png")
const TREE=Rect2(0,0,744,755)
const COTTAGE=Rect2(748,90,506,665)
const BUSH=Rect2(0,780,790,474)
const SIGN=Rect2(790,768,464,486)
const TILE=Rect2(0,133,2172,591)
var map_id="town"
var width=1800.0
var sky_sprite: Sprite2D
func _ready():
    sky_sprite=Sprite2D.new()
    sky_sprite.texture=SKY
    sky_sprite.centered=false
    sky_sprite.scale=Vector2((width+600)/SKY.get_width(),760.0/SKY.get_height())
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
        draw_texture_rect_region(TERRAIN,Rect2(x+offset,y-12,segment,depth),source)
        offset+=segment
func _draw():
    # Panoramic painted scenery, with organic foreground props on separate layers.
    var forest=map_id=="forest"
    for x in range(-120,int(width)+450,420):
        prop(TREE,Vector2(x,588),Vector2(320,325),Color(0.73,0.87,0.81,0.72))
    if forest:
        for x in [520,1130,1850,2700]: prop(TREE,Vector2(x,610),Vector2(460,467))
        for x in [480,950,1610,2240,2820]: prop(BUSH,Vector2(x,610),Vector2(190,114))
        for data in [[750,485,300],[1100,375,280],[1500,475,350],[1940,350,300],[2370,455,380]]:
            terrain_strip(data[0]-data[2]/2.0,data[1],data[2],77)
        prop(SIGN,Vector2(350,610),Vector2(85,89))
    else:
        prop(COTTAGE,Vector2(300,610),Vector2(270,355))
        prop(COTTAGE,Vector2(930,610),Vector2(245,322))
        prop(COTTAGE,Vector2(1320,610),Vector2(210,276))
        for x in [60,720,1720]: prop(TREE,Vector2(x,610),Vector2(350,355))
        for x in [70,650,1090,1450]: prop(BUSH,Vector2(x,610),Vector2(150,90))
        prop(SIGN,Vector2(600,610),Vector2(78,82))
        for data in [[730,460,280],[1220,420,260]]:
            terrain_strip(data[0]-data[2]/2.0,data[1],data[2],67)
    terrain_strip(0,610,width,150)
