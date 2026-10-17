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
var overlay: WeaponOverlay
# Mage and archer reuse the thief atlas with a tint and a drawn weapon until
# dedicated atlases are added (add "mage"/"archer" entries to TEXTURES and atlas_layout).
const FALLBACK={"mage":"thief","archer":"thief"}
const TINTS={"mage":Color(0.8,0.85,1.2),"archer":Color(0.85,1.1,0.85)}
func walk_frame_count() -> int: return 8
func _ready():
    sprite=Sprite2D.new()
    sprite.region_enabled=true
    sprite.region_filter_clip_enabled=true
    sprite.centered=false
    sprite.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
    add_child(sprite)
    overlay=WeaponOverlay.new()
    add_child(overlay)
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
    var key=appearance if TEXTURES.has(appearance) else FALLBACK.get(appearance,"sword")
    var data=Layout.DATA[key]
    var rect=data.rects[frame]
    var anchor=data.anchors[frame]-rect.position
    sprite.texture=TEXTURES[key]
    sprite.self_modulate=TINTS.get(appearance,Color.WHITE)
    if overlay!=null:
        overlay.kind=appearance if FALLBACK.has(appearance) else ""
        overlay.facing=direction
        overlay.attacking=mode=="attack"
        overlay.queue_redraw()
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

class WeaponOverlay extends Node2D:
    var kind=""
    var facing=1
    var attacking=false
    func _draw():
        if kind=="": return
        draw_set_transform(Vector2.ZERO,0,Vector2(facing,1))
        var hand=Vector2(22,-40) if attacking else Vector2(15,-34)
        if kind=="mage":
            draw_line(hand+Vector2(-2,22),hand+Vector2(4,-30),Color("2b2233"),6,true)
            draw_line(hand+Vector2(-2,22),hand+Vector2(4,-30),Color("8a5a34"),4,true)
            draw_circle(hand+Vector2(5,-34),7,Color(0.6,0.75,1,0.35))
            draw_circle(hand+Vector2(5,-34),4.5,Color("9fd0ff"))
            draw_circle(hand+Vector2(4,-36),1.6,Color.WHITE)
        else:
            draw_arc(hand+Vector2(-4,0),22,-1.25,1.25,16,Color("2b2233"),5,true)
            draw_arc(hand+Vector2(-4,0),22,-1.25,1.25,16,Color("9a6a3c"),3,true)
            var top=hand+Vector2(-4,0)+Vector2(cos(-1.25),sin(-1.25))*22
            var bottom=hand+Vector2(-4,0)+Vector2(cos(1.25),sin(1.25))*22
            draw_line(top,bottom if not attacking else hand+Vector2(-10,0),Color("efe6d2"),1.2)
            if attacking: draw_line(hand+Vector2(-10,0),bottom,Color("efe6d2"),1.2)
        draw_set_transform(Vector2.ZERO)
