extends RefCounted
func run(t):
    var visual=load("res://visuals/character_visual.gd").new()
    t.root.add_child(visual)
    t.check(visual.has_method("walk_frame_count"),"character has a full walk cycle")
    if not visual.has_method("walk_frame_count"):
        visual.queue_free()
        return
    for kind in ["sword","thief","spear"]:
        visual.appearance=kind
        t.check(visual.walk_frame_count()==8,"eight walking frames for "+kind)
        var seen={}
        for i in range(8):
            visual.walk_phase=i/8.0
            visual.set_pose("run",1,0)
            seen[visual.current_frame]=true
            var size=visual.sprite.texture.get_size()
            t.check(Rect2(Vector2.ZERO,size).encloses(visual.sprite.region_rect),"atlas frame remains inside texture: "+kind)
        t.check(seen.size()==8,"walking uses all eight poses: "+kind)
        visual.walk_phase=0
        visual.set_pose("run",1,1)
        var right=visual.sprite.position
        visual.set_pose("run",-1,1)
        var rect=visual.sprite.region_rect
        t.check(is_equal_approx(right.x+visual.sprite.position.x,-rect.size.x*visual.sprite.scale.x),"flipping keeps the character's anchor stable: "+kind)
    visual.queue_free()
    await t.process_frame
