extends Node2D
const Maps=preload("res://data/maps.gd")
const Scenery=preload("res://visuals/world_theme.gd")
const BACKGROUNDS=preload("res://art/regional_backgrounds.png")
const BUILDINGS=preload("res://art/regional_buildings.png")
const BRIAR=preload("res://art/briar_background.png")
const SKY=preload("res://art/sky.png")
const PROPS=preload("res://art/props.png")
const REGION_TERRAIN=preload("res://art/regional_terrain.png")
const TERRAIN=preload("res://art/terrain.png")
const TREE=Rect2(74,10,622,634)
const COTTAGE=Rect2(782,56,724,583)
const BUSH=Rect2(134,680,597,334)
const SIGN=Rect2(949,690,378,316)
const TILE=Rect2(0,185,2048,459)
var map_id="town"
var width=1800.0
var sky_sprite: Sprite2D
var data={}
var palette={}
var biome="mushroom"
func _ready():
    data=Maps.definition(map_id)
    biome=data.biome
    palette=Scenery.palette(biome)
    sky_sprite=Sprite2D.new()
    var backdrop=BRIAR if biome=="roots" else SKY
    sky_sprite.texture=backdrop
    sky_sprite.centered=false
    var backdrop_size=Vector2(backdrop.get_width(),backdrop.get_height())
    if palette.background>=0:
        sky_sprite.texture=BACKGROUNDS
        sky_sprite.region_enabled=true
        sky_sprite.region_filter_clip_enabled=true
        var index=int(palette.background)
        backdrop_size=Vector2(BACKGROUNDS.get_width()/2.0,BACKGROUNDS.get_height()/2.0)
        sky_sprite.region_rect=Rect2(Vector2((index%2)*backdrop_size.x,int(index/2.0)*backdrop_size.y),backdrop_size)
    var sky_top=minf(-100.0,data.get("top",137.0)-160.0)
    sky_sprite.scale=Vector2((width+600)/backdrop_size.x,(860.0-sky_top-100.0)/backdrop_size.y)
    sky_sprite.modulate=palette.sky
    sky_sprite.position=Vector2(-300,sky_top)
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
    var ground_index=Scenery.ground_index(biome)
    var tile=TILE if ground_index<0 else Scenery.GROUND[ground_index]
    # Repeat the rectangular interior, excluding each sprite's rounded end caps.
    if ground_index>=0: tile=Rect2(tile.position+Vector2(20,0),tile.size-Vector2(40,0))
    var texture=TERRAIN if ground_index<0 else REGION_TERRAIN
    var tint=palette.tile if ground_index<0 else Color.WHITE
    var natural_width=360.0
    var offset=0.0
    while offset<length:
        var segment=minf(natural_width,length-offset)
        var source=Rect2(tile.position,Vector2(tile.size.x*segment/natural_width,tile.size.y))
        draw_texture_rect_region(texture,Rect2(x+offset,y-12,segment,depth),source,tint)
        offset+=segment
func _draw():
    if map_id not in ["town","forest","briar"]:
        draw_region()
    elif map_id=="briar":
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
        terrain_strip(platform[0]-platform[2]/2.0,platform[1],platform[2],67 if data.safe else 77)
    terrain_strip(0,610,width,150)
    for c in data.get("climbs",[]): draw_climb(c)
# Painted rope/ladder pieces when the climb atlas exists, otherwise drawn ones.
static var climb_art=null
static func climb_atlas() -> Dictionary:
    if climb_art==null:
        climb_art={}
        if ResourceLoader.exists("res://art/climb_atlas.png") and ResourceLoader.exists("res://visuals/climb_layout.gd"):
            var script=load("res://visuals/climb_layout.gd")
            for value in script.get_script_constant_map().values():
                if value is Dictionary and not value.is_empty():
                    climb_art={"texture":load("res://art/climb_atlas.png"),"regions":value}
                    break
    return climb_art
func draw_climb(c: Array):
    var x: float=c[0]
    var top: float=c[1]-14
    var bottom: float=c[2]
    var kind: String=c[3]
    var art=climb_atlas()
    if not art.is_empty():
        var pieces=art.regions.get(biome,art.regions.values()[0])
        var mid: Rect2=pieces.get(kind+"_mid",Rect2())
        if mid.size.x>0:
            var w=16.0 if kind=="rope" else 32.0
            var y=top
            while y<bottom:
                var piece=minf(64.0,bottom-y)
                draw_texture_rect_region(art.texture,Rect2(x-w/2,y,w,piece),Rect2(mid.position,Vector2(mid.size.x,mid.size.y*piece/64.0)))
                y+=64.0
            var cap: Rect2=pieces.get(kind+"_top",Rect2())
            if cap.size.x>0: draw_texture_rect_region(art.texture,Rect2(x-w/2,top-cap.size.y*w/cap.size.x,w,cap.size.y*w/cap.size.x),cap)
            return
    if kind=="rope":
        draw_line(Vector2(x,top),Vector2(x,bottom-4),Color("6d4a26"),7)
        draw_line(Vector2(x-1,top),Vector2(x-1,bottom-4),Color("b98a4d"),3)
        var y=top+10.0
        while y<bottom-8:
            draw_line(Vector2(x-3,y),Vector2(x+3,y+6),Color("5a3c1e"),2)
            y+=14.0
        draw_circle(Vector2(x,top),6,Color("5a3c1e"))
    else:
        for side in [-13,13]:
            draw_line(Vector2(x+side,top),Vector2(x+side,bottom),Color("5b3d22"),6)
            draw_line(Vector2(x+side-1,top),Vector2(x+side-1,bottom),Color("a77a45"),2)
        var y=top+12.0
        while y<bottom-4:
            draw_line(Vector2(x-13,y),Vector2(x+13,y),Color("7b5530"),5)
            draw_line(Vector2(x-13,y-1),Vector2(x+13,y-1),Color("c49660"),1)
            y+=22.0

func building(x: float,size=Vector2(360,320)):
    var region=Scenery.BUILDINGS[palette.building]
    var height=size.x*region.size.y/region.size.x
    draw_texture_rect_region(BUILDINGS,Rect2(Vector2(x-size.x/2,610-height),Vector2(size.x,height)),region)
func draw_region():
    if biome=="coast":
        draw_rect(Rect2(0,440,width,170),Color("67c6dd"))
        for x in range(0,int(width),100):
            draw_line(Vector2(x,490),Vector2(x+60,490),Color("b5e9f1"),3)
            draw_line(Vector2(x+30,540),Vector2(x+90,540),Color("9ddfe9"),2)
    elif biome in ["city","tech"]:
        for x in range(0,int(width)+200,170):
            var height=170+int(x/170)%3*55
            draw_rect(Rect2(x,610-height,140,height),Color("48546b") if biome=="city" else Color("647987"))
            for floor_y in range(640-height,580,45):
                for column in [25,65,105]: draw_rect(Rect2(x+column,floor_y,15,22),Color("e7c584"))
    elif biome=="underwater":
        draw_rect(Rect2(0,-100,width,710),Color(0.05,0.35,0.55,0.25))
        for x in range(50,int(width),110):
            draw_arc(Vector2(x,160+(int(x/110)%4)*95),8+(int(x)%3)*3,0,TAU,20,Color(0.7,0.96,1,0.5),2)
            draw_line(Vector2(x,610),Vector2(x-18,525),Color("75bbbc"),5)
            draw_line(Vector2(x-10,570),Vector2(x-33,540),Color("94d6c9"),4)
    elif biome=="cloud":
        for x in range(-80,int(width)+180,170):
            draw_circle(Vector2(x,480),62,Color("ecebfa"))
            draw_circle(Vector2(x+65,500),58,Color("f5f3ff"))
    if data.safe:
        building(630,Vector2(390,320))
        for x in range(1200,int(width)-180,600): building(x,Vector2(300,270))
    else:
        building(430,Vector2(210,190))
    if biome not in ["city","tech","desert","underwater","highland","dragon","temple","snow"]:
        for x in range(100,int(width),1000 if data.safe else 560):
            prop(TREE,Vector2(x,610),Vector2(270,275),palette.foliage)
            prop(BUSH,Vector2(x+220,610),Vector2(140,84),palette.foliage)
    if biome=="farm":
        for x in range(70,int(width),35):
            draw_line(Vector2(x,605),Vector2(x+6,560),Color("d4b55d"),3)
            draw_circle(Vector2(x+6,560),5,Color("efce67"))
    if biome=="snow":
        draw_line(Vector2(0,608),Vector2(width,608),Color("f3fbff"),12)
    prop(SIGN,Vector2(350,610),Vector2(78,65))
