extends Node2D
# A pet that trails the player and fetches nearby loot.
const Adventure=preload("res://data/adventure.gd")
const Layout=preload("res://visuals/pet_layout.gd")
var pet_id="puppy"
var player
var map
var target=null
var age=0.0
var facing=1
var hop=0.0
func _process(delta):
    age+=delta
    if player==null or not is_instance_valid(player): return
    if target!=null and not is_instance_valid(target): target=null
    if target==null and map!=null and is_instance_valid(map):
        var best=Adventure.PET_LOOT_RADIUS
        for drop in map.pickups:
            if not is_instance_valid(drop) or drop.get_meta("full_warned",false): continue
            var d=drop.position.distance_to(player.position)
            if d<best:
                best=d
                target=drop
    var goal=target.position if target!=null else player.position+Vector2(-55*player.facing,0)
    if target==null and player.climbing: goal=Vector2(player.climb[0]-40,player.climb[2])
    var step=goal-position
    var speed=420.0 if target!=null else 260.0
    if step.length()>3:
        if absf(step.x)>2: facing=int(sign(step.x))
        position+=step.normalized()*minf(step.length(),speed*delta)
        hop+=delta*10
    else: hop=0.0
    if step.length()>700: position=player.position+Vector2(-55*player.facing,0)
    if target!=null and position.distance_to(target.position)<22:
        map.collect(target)
        target=null
    queue_redraw()
func _draw():
    var info=Layout.DATA.get(pet_id,Layout.DATA.puppy)
    var moving=hop>0
    var frames: Array=info.walk if moving else info.idle
    var fps: float=info.walk_fps if moving else info.idle_fps
    var index: int=frames[int(age*fps)%frames.size()]
    if moving and target!=null and absf(sin(hop))>0.8: index=info.jump[0]
    var rect: Rect2=info.rects[index]
    var anchor: Vector2=info.anchors[index]-rect.position
    var size=rect.size*(46.0/info.height)
    var foot=anchor*(46.0/info.height)
    draw_set_transform(Vector2.ZERO,0,Vector2(facing*info.facing,1))
    draw_circle(Vector2(0,1),11,Color(0,0,0,0.15))
    draw_texture_rect_region(Layout.ART,Rect2(-foot,size),rect)
    draw_set_transform(Vector2.ZERO)
