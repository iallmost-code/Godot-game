extends Node2D
const Layout=preload("res://visuals/body_layout.gd")
const Weapons=preload("res://visuals/weapon_layout.gd")
const Catalog=preload("res://data/catalog.gd")
const TEXTURES={"warrior":preload("res://art/warrior_body.png"),"thief":preload("res://art/thief_body.png"),"mage":preload("res://art/mage_body.png"),"archer":preload("res://art/archer_body.png")}
var appearance="spear"
var pose="idle"
var facing=1
var phase=0.0
var walk_phase=0.0
var pose_started=0.0
var attack_style="basic"
var attack_elapsed=-1.0
var attack_duration=0.32
var attack_windup=0.08
var equipment_id=""
var weapon_kind="spear"
var weapon_rare=false
var sprite: Sprite2D
var weapon_mount: Node2D
var weapon_pivot: Node2D
var weapon_sprite: Sprite2D
var current_frame=8
func walk_frame_count() -> int: return 8
func _ready():
    sprite=Sprite2D.new()
    sprite.region_enabled=true
    sprite.region_filter_clip_enabled=true
    sprite.centered=false
    sprite.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
    add_child(sprite)
    weapon_mount=Node2D.new()
    weapon_mount.z_index=1
    add_child(weapon_mount)
    weapon_pivot=Node2D.new()
    weapon_mount.add_child(weapon_pivot)
    weapon_sprite=Sprite2D.new()
    weapon_sprite.texture=Weapons.ART
    weapon_sprite.region_enabled=true
    weapon_sprite.region_filter_clip_enabled=true
    weapon_sprite.centered=false
    weapon_sprite.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
    weapon_pivot.add_child(weapon_sprite)
    set_pose(pose,facing,phase)
func set_equipment(id: String) -> bool:
    var item=Catalog.items().get(id,{})
    if item.get("slot","")!="weapon": return false
    equipment_id=id
    weapon_kind=item.get("weapon","sword")
    weapon_rare=item.get("attack",0)>=60
    return true
func set_attack_clock(elapsed: float,duration: float,windup: float):
    attack_elapsed=elapsed
    attack_duration=maxf(0.1,duration)
    attack_windup=clampf(windup,0.0,attack_duration*0.8)
func attack_frame(elapsed: float) -> int:
    if elapsed<attack_windup: return 14 if weapon_kind in ["bow","crossbow"] else 10
    var progress=clampf((elapsed-attack_windup)/maxf(0.01,attack_duration-attack_windup),0,1)
    if progress<0.42: return 11
    if progress<0.80: return 15 if weapon_kind=="staff" else 12
    return 8 if weapon_kind in ["bow","crossbow"] else 14
func set_pose(mode: String,direction: int,time: float):
    if mode!=pose: pose_started=time
    pose=mode
    facing=direction
    phase=time
    if sprite==null: return
    if equipment_id=="": weapon_kind={"spear":"spear","thief":"claw","mage":"staff","archer":"bow"}.get(appearance,"sword")
    var elapsed=attack_elapsed if attack_elapsed>=0 else maxf(0,time-pose_started)
    var frame=8
    if mode=="run": frame=posmod(int(walk_phase*8),8)
    elif mode=="jump": frame=9
    elif mode=="hurt": frame=13
    elif mode=="attack": frame=attack_frame(elapsed)
    current_frame=frame
    var key=appearance if TEXTURES.has(appearance) else "warrior"
    var data=Layout.DATA[key]
    var rect=data.rects[frame]
    var anchor=data.anchors[frame]-rect.position
    var factor=80.0/data.rects[8].size.y
    var breath=sin(time*3)*0.5 if mode=="idle" else 0.0
    sprite.texture=TEXTURES[key]
    sprite.scale=Vector2.ONE*factor
    sprite.region_rect=rect
    sprite.flip_h=direction<0
    sprite.position=Vector2(-(rect.size.x-anchor.x) if sprite.flip_h else -anchor.x,-anchor.y)*factor+Vector2(0,breath)
    var hand=data.hands[frame]*factor
    weapon_mount.position=Vector2(hand.x*direction,hand.y+breath)
    weapon_mount.scale=Vector2(direction,1)
    var weapon=Weapons.definition(weapon_kind,weapon_rare)
    var weapon_factor=weapon.length/maxf(weapon.rect.size.x,weapon.rect.size.y)
    weapon_sprite.region_rect=weapon.rect
    weapon_sprite.scale=Vector2.ONE*weapon_factor
    weapon_sprite.position=-weapon.grip*weapon_factor
    weapon_pivot.rotation=weapon_angle(mode,elapsed)
    if mode=="run": weapon_pivot.rotation+=sin(walk_phase*TAU)*0.09
    queue_redraw()
func weapon_angle(mode: String,elapsed: float) -> float:
    var rest={"sword":1.9,"spear":0.2,"dagger":1.7,"claw":0.0,"staff":0.1,"bow":0.0,"crossbow":0.0}.get(weapon_kind,0.0)
    if mode!="attack": return rest
    if weapon_kind in ["bow","crossbow","claw"]: return 0.0
    if weapon_kind=="staff": return -0.25 if elapsed<attack_windup else 0.12
    var skill=Catalog.skill(attack_style)
    var thrust=weapon_kind=="spear" or skill.get("fx","")=="thrust"
    if elapsed<attack_windup: return 0.1 if thrust else -0.8
    var p=clampf((elapsed-attack_windup)/maxf(0.01,attack_duration-attack_windup),0,1)
    if thrust: return PI/2 if p<0.8 else lerpf(PI/2,rest,(p-0.8)/0.2)
    return lerpf(0.9,2.5,smoothstep(0,0.75,p))
func _draw():
    draw_set_transform(Vector2(0,1),0,Vector2(19,4))
    draw_circle(Vector2.ZERO,1,Color(0.05,0.10,0.12,0.20))
    draw_set_transform(Vector2.ZERO)
