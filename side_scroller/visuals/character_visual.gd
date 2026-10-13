extends Node2D
var pose = "idle"
var facing = 1
var phase = 0.0
func set_pose(mode: String, direction: int, time: float):
    pose = mode
    facing = direction
    phase = time
    queue_redraw()
func oval(pos: Vector2, size: Vector2, color: Color):
    draw_set_transform(pos,0,size)
    draw_circle(Vector2.ZERO,1,color)
    draw_set_transform(Vector2.ZERO)
func _draw():
    var step = sin(phase*15) * 5 if pose == "run" else 0.0
    var bob = absf(step)*0.4 if pose == "run" else sin(phase*3)*0.8
    var attack = pose == "attack"
    # Original layered vector character: oversized head, scarf, armor and articulated boots.
    oval(Vector2(0,1),Vector2(22,5),Color(0.05,0.12,0.18,0.25))
    var boot_color = Color("34334c")
    oval(Vector2(-8+step,-7),Vector2(9,7),boot_color)
    oval(Vector2(8-step,-7),Vector2(9,7),boot_color)
    draw_line(Vector2(-8,-13),Vector2(-8+step,-7),Color("5b668a"),8)
    draw_line(Vector2(8,-13),Vector2(8-step,-7),Color("5b668a"),8)
    var center = Vector2(0,-27-bob)
    # Scarf and tunic.
    var tail = -facing*(20+absf(step))
    draw_colored_polygon(PackedVector2Array([center+Vector2(-5,-10),center+Vector2(tail,-6),center+Vector2(tail+3,9),center+Vector2(-3,5)]),Color("e7725a"))
    oval(center,Vector2(15,17),Color("3d526d"))
    oval(center+Vector2(0,-2),Vector2(13,12),Color("8eb8bf"))
    draw_line(center+Vector2(-10,8),center+Vector2(10,8),Color("d6a56d"),5)
    oval(center+Vector2(-13,-4),Vector2(8,7),Color("aecdd0"))
    oval(center+Vector2(13,-4),Vector2(8,7),Color("aecdd0"))
    # Face, hair, and crown-like leather headband.
    var head = Vector2(0,-51-bob)
    oval(head+Vector2(0,-1),Vector2(20,20),Color("574052"))
    oval(head+Vector2(0,3),Vector2(17,17),Color("f6cdac"))
    draw_colored_polygon(PackedVector2Array([head+Vector2(-20,-2),head+Vector2(-15,-18),head+Vector2(3,-23),head+Vector2(18,-15),head+Vector2(20,-2),head+Vector2(8,-10),head+Vector2(1,-3),head+Vector2(-8,-10)]),Color("53404d"))
    draw_line(head+Vector2(-16,-10),head+Vector2(16,-10),Color("e8b567"),5)
    oval(head+Vector2(0,-10),Vector2(5,5),Color("73e3d6"))
    for eye in [-7,7]:
        oval(head+Vector2(eye+facing*2,4),Vector2(3,5),Color("293649"))
        oval(head+Vector2(eye+facing*2-1,2),Vector2(1,1.5),Color.WHITE)
    draw_line(head+Vector2(2,12),head+Vector2(7,11),Color("bc7971"),2)
    # Spear angle changes during attacks; idle spear extends upward diagonally.
    var hand = center+Vector2(facing*15,1)
    var tip = hand+Vector2(facing*94,-3) if attack else hand+Vector2(facing*39,-69)
    var bottom = hand-(tip-hand)*0.4
    draw_line(bottom,tip,Color("694e42"),5)
    draw_line(bottom+Vector2(-1,0),tip+Vector2(-1,0),Color("d4ac7a"),2)
    var direction = (tip-hand).normalized()
    var normal = Vector2(-direction.y,direction.x)
    draw_colored_polygon(PackedVector2Array([tip+direction*19,tip+normal*8,tip-direction*11,tip-normal*8]),Color("d7f0eb"))
    draw_line(tip-direction*9,tip+direction*17,Color("7dbfc9"),2)
    oval(hand,Vector2(6,6),Color("f6cdac"))
