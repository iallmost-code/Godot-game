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
    event.physical_keycode=KEY_G
    t.root.push_input(event)
    t.check(b.current().attack==KEY_G,"captured key rebinds attack")
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
    s.add_xp(s.xp_required(s.level))
    s.rank_up("power_strike")
    s.rank_up("slash_blast")
    s.assign_skill("z","power_strike")
    s.assign_skill("x","slash_blast")
    t.check(s.assign_skill("c","power_strike"),"learned skill can move to an empty hotbar slot")
    t.check(s.slots.c=="power_strike" and s.slots.z=="","moving a skill clears its previous slot")
    t.check(s.assign_skill("x","power_strike"),"learned skills can swap occupied slots")
    t.check(s.slots.x=="power_strike" and s.slots.c=="slash_blast","occupied-slot reassignment preserves both skills")
    t.check(not s.assign_skill("z","iron_body"),"unlearned skill assignment rejected")
    var game=load("res://main.tscn").instantiate()
    game.test_mode=true
    t.root.add_child(game)
    game.player.set_physics_process(true)
    game.menu.open_panel("controls")
    var before=game.player.position
    var attacks=game.combat.sequence
    var control=game.menu.current_panel
    control.start_capture("jump")
    var captured=InputEventKey.new()
    captured.physical_keycode=KEY_SPACE
    captured.pressed=true
    Input.parse_input_event(captured.duplicate())
    Input.flush_buffered_events()
    for i in range(3): await t.physics_frame
    t.check(game.player.position==before and game.combat.sequence==attacks,"paused key capture cannot move or attack with a real player")
    captured.pressed=false
    Input.parse_input_event(captured.duplicate())
    Input.flush_buffered_events()
    captured=InputEventKey.new()
    captured.physical_keycode=KEY_ESCAPE
    captured.pressed=true
    Input.parse_input_event(captured.duplicate())
    Input.flush_buffered_events()
    t.check(game.menu.opened and control.capture_action=="","Escape cancels capture before closing the paused menu")
    captured.pressed=false
    Input.parse_input_event(captured.duplicate())
    Input.flush_buffered_events()
    control.start_capture("attack")
    game.menu.open_panel("stats")
    await t.process_frame
    game.menu.open_panel("controls")
    t.check(game.menu.current_panel.capture_action=="","switching panels does not retain keyboard capture")
    game.menu.close()
    game.queue_free()
    await t.process_frame
    var assign_game=load("res://main.tscn").instantiate()
    assign_game.test_mode=true
    t.root.add_child(assign_game)
    while assign_game.state.level<10: assign_game.state.add_xp(assign_game.state.xp_required(assign_game.state.level))
    assign_game.state.advance_job("warrior")
    assign_game.state.rank_up("power_strike")
    assign_game.state.assign_skill("z","power_strike")
    assign_game.menu.open_panel("skills")
    await t.process_frame
    var button=find_button(assign_game.menu.current_panel,"C")
    t.check(button!=null and not button.disabled,"learned skill has an active assignment button")
    if button!=null:
        button.pressed.emit()
        await t.process_frame
        t.check(assign_game.state.slots.c=="power_strike" and assign_game.state.slots.z=="","paused-menu button callback moves a learned skill")
        t.check(assign_game.hud.skills[3].icon.footer.contains("Heavy Blow"),"hotbar updates after a menu assignment")
    assign_game.menu.close()
    assign_game.queue_free()
    await t.process_frame

func find_button(node: Node,text: String):
    if node is Button and node.text==text: return node
    for child in node.get_children():
        var found=find_button(child,text)
        if found!=null: return found
    return null
