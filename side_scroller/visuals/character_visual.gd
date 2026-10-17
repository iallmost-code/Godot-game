extends Node2D
const Layout=preload("res://visuals/atlas_layout.gd")
const TEXTURES={"sword":preload("res://art/sword_atlas.png"),"spear":preload("res://art/spear_atlas.png"),"thief":preload("res://art/thief_atlas.png")}
var appearance="spear"
var pose="idle"
var facing=1
var phase=0.0
var walk_phase=0.0
var pose_started=0.0
var attack_style="basic"
var sprite: Sprite2D
var current_frame=8
func walk_frame_count() -> int: return 8
func _ready():
    sprite=Sprite2D.new()
    sprite.region_enabled=true
    sprite.region_filter_clip_enabled=true
    sprite.centered=false
    sprite.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
    add_child(sprite)
    set_pose(pose,facing,phase)
func set_pose(mode: String,direction: int,time: float):
    if mode!=pose: pose_started=time
    pose=mode
    facing=direction
    phase=time
    if sprite==null: return
    var frame=8
    if mode=="run": frame=int(walk_phase*8)%8
    elif mode=="jump": frame=9
    elif mode=="hurt": frame=13
    elif mode=="attack":
        frame=10 if time-pose_started<0.08 else 11 if attack_style in ["thrust","star"] else 15 if attack_style=="star_fan" else 12
    current_frame=frame
    var data=Layout.DATA[appearance]
    var rect=data.rects[frame]
    var anchor=data.anchors[frame]-rect.position
    sprite.texture=TEXTURES[appearance]
    var scale_factor=80.0/data.rects[8].size.y
    sprite.scale=Vector2.ONE*scale_factor
    sprite.region_rect=rect
    sprite.flip_h=direction<0
    sprite.position=Vector2(-(rect.size.x-anchor.x) if sprite.flip_h else -anchor.x,-anchor.y)*scale_factor
    sprite.position.y+=sin(time*3)*0.5 if mode=="idle" else 0.0
    queue_redraw()
func _draw():
    draw_set_transform(Vector2(0,1),0,Vector2(19,4))
    draw_circle(Vector2.ZERO,1,Color(0.05,0.10,0.12,0.20))
    draw_set_transform(Vector2.ZERO)
