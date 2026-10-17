extends Node2D
# Painted level-up pillar (or skill-learned sparkle) that follows the player.
const LENGTH=1.9
const Art=preload("res://visuals/levelup_layout.gd")
# "level_up" or "skill_learned".
var kind="level_up"
var follow: Node2D
var age=0.0
func _ready(): z_index=14
func _process(delta):
    age+=delta
    if follow!=null and is_instance_valid(follow): position=follow.global_position
    if age>=LENGTH: queue_free()
    queue_redraw()
func _draw():
    var fade=clampf((LENGTH-age)/0.6,0,1)
    var anim=Art.DATA[kind]
    var frame=mini(int(age*anim.fps),anim.rects.size()-1)
    var rect: Rect2=anim.rects[frame]
    var anchor: Vector2=anim.anchors[frame]-rect.position
    var scale_factor=1.35 if kind=="level_up" else 0.8
    for i in 6:
        var t=fmod(age*0.9+i*0.17,1.0)
        draw_circle(Vector2(sin(i*2.1+age*2)*40,-30-t*240),2.5,Color(1,0.97,0.8,(1-t)*fade))
    draw_texture_rect_region(Art.ART,Rect2(-anchor*scale_factor,rect.size*scale_factor),rect,Color(1,1,1,fade))
