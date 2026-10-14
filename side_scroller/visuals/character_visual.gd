extends Node2D
# Original sprite artwork. Regions are explicit because animation silhouettes
# have different weapon extents; anchors keep boots on the physics-body origin.
const ATLAS=preload("res://art/warrior_atlas.png")
const FRAMES=[Rect2(0,0,627,352),Rect2(627,0,627,352),Rect2(0,378,627,316),Rect2(627,333,627,331),Rect2(0,707,627,267),Rect2(627,710,627,259),Rect2(0,984,627,270),Rect2(627,982,627,272)]
const ANCHORS=[Vector2(340,351),Vector2(904,351),Vector2(354,693),Vector2(930,664),Vector2(337,974),Vector2(822,969),Vector2(314,1237),Vector2(971,1237)]
const SPRITE_SCALE=0.25
var pose="idle"
var facing=1
var phase=0.0
var pose_started=0.0
var attack_style="basic"
var sprite: Sprite2D
var current_frame=0
func _ready():
    sprite=Sprite2D.new()
    sprite.texture=ATLAS
    sprite.region_enabled=true
    sprite.region_filter_clip_enabled=true
    sprite.centered=false
    sprite.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
    sprite.scale=Vector2.ONE*SPRITE_SCALE
    var shader=Shader.new()
    # Exclude tiny neighboring spear-tip/boot fragments at the two overlapping
    # atlas-row boundaries. This changes rendering only; original art stays intact.
    shader.code="""shader_type canvas_item;
        uniform int frame_no = 0;
        void fragment() {
            vec2 pixel = UV * vec2(1254.0);
            if (frame_no == 1 && pixel.y > 332.0 && pixel.x > 1047.0) discard;
            if (frame_no == 3 && pixel.y < 352.0 && pixel.x < 1047.0) discard;
        }
    """
    var mat=ShaderMaterial.new()
    mat.shader=shader
    sprite.material=mat
    add_child(sprite)
    set_pose(pose,facing,phase)
func set_pose(mode: String,direction: int,time: float):
    if mode!=pose: pose_started=time
    pose=mode
    facing=direction
    phase=time
    if sprite==null: return
    var frame=0
    if mode=="run": frame=1+int(time*8)%2
    elif mode=="jump": frame=3
    elif mode=="hurt": frame=7
    elif mode=="attack":
        frame=4 if time-pose_started<0.08 else 5 if attack_style=="thrust" else 6
    current_frame=frame
    var rect=FRAMES[frame]
    var anchor=ANCHORS[frame]-rect.position
    sprite.region_rect=rect
    sprite.flip_h=direction<0
    sprite.position=Vector2(-(rect.size.x-anchor.x) if sprite.flip_h else -anchor.x,-anchor.y)*SPRITE_SCALE
    sprite.position.y+=sin(time*3)*0.5 if mode=="idle" else 0.0
    sprite.material.set_shader_parameter("frame_no",frame)
    queue_redraw()
func _draw():
    draw_set_transform(Vector2(0,1),0,Vector2(19,4))
    draw_circle(Vector2.ZERO,1,Color(0.05,0.10,0.12,0.20))
    draw_set_transform(Vector2.ZERO)
