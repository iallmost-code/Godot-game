extends RefCounted
func run(t):
    var s=load("res://systems/character_state.gd").new()
    s.add_xp(s.xp_required(1))
    var b=load("res://systems/input_bindings.gd").new()
    b.apply(b.defaults())
    var panel=load("res://ui/stats_panel.gd").new()
    t.root.add_child(panel)
    panel.bind(s,b)
    panel.stage("STR")
    t.check(s.attributes.STR==4 and s.ap==5,"stat preview does not mutate character")
    t.check(panel.confirm() and s.attributes.STR==5 and s.ap==4,"confirm commits attribute draft")
    panel.stage("DEX")
    panel.cancel()
    t.check(s.attributes.DEX==4,"cancel discards draft")
    panel.queue_free()
    await t.process_frame
    var path="res://ui/controls_panel.gd"
    if not FileAccess.file_exists(path): return
    var controls=load(path).new()
    t.root.add_child(controls)
    controls.bind(s,b)
    controls.start_capture("attack")
    var event=InputEventKey.new()
    event.physical_keycode=KEY_SHIFT
    event.pressed=true
    t.root.push_input(event)
    t.check(b.current().attack==KEY_SPACE,"captured duplicate key rejected")
    controls.start_capture("attack")
    event.physical_keycode=KEY_A
    t.root.push_input(event)
    t.check(b.current().attack==KEY_A,"captured key rebinds attack")
    controls.start_capture("jump")
    event.physical_keycode=KEY_ESCAPE
    t.root.push_input(event)
    t.check(controls.capture_action=="" and b.current().jump==KEY_SHIFT,"Escape cancels capture")
    controls.restore_defaults()
    t.check(b.current().attack==KEY_SPACE,"defaults restored")
    controls.queue_free()
    await t.process_frame
    while s.level<10: s.add_xp(s.xp_required(s.level))
    s.advance_job("warrior")
    t.check(not s.assign_skill("c","sweep"),"duplicate skill assignment rejected")
    t.check(not s.assign_skill("z","wave"),"unlearned skill assignment rejected")
