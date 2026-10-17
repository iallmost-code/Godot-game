extends RefCounted
func key(t,code,echo=false):
    var e=InputEventKey.new()
    e.physical_keycode=code
    e.pressed=true
    e.echo=echo
    t.root.push_input(e)
func run(t):
    var bindings=load("res://systems/input_bindings.gd").new()
    var legacy=bindings.defaults()
    for action in ["menu_inventory","menu_map","menu_skills","menu_stats"]: legacy.erase(action)
    legacy.attack=KEY_I
    t.check(bindings.apply(legacy),"legacy saves with nine bindings still load")
    t.check(bindings.current().attack==KEY_I,"legacy custom attack key is preserved")
    t.check(bindings.current().get("menu_inventory",KEY_I)!=KEY_I,"legacy key collision gets a free menu shortcut")
    bindings.apply(bindings.defaults())
    var game=load("res://main.tscn").instantiate()
    game.test_mode=true
    t.root.add_child(game)
    for entry in [[KEY_I,"inventory"],[KEY_K,"skills"],[KEY_S,"stats"],[KEY_M,"map"]]:
        key(t,entry[0])
        t.check(game.menu.opened and game.menu.selected==entry[1],"key opens panel: "+entry[1])
        key(t,entry[0],true)
        t.check(game.menu.opened,"key repeat does not toggle menu")
        key(t,entry[0])
        t.check(not game.menu.opened and not t.paused,"same shortcut closes panel: "+entry[1])
    key(t,KEY_I)
    key(t,KEY_M)
    t.check(game.menu.opened and game.menu.selected=="map","shortcut switches panels while paused")
    key(t,KEY_ESCAPE)
    t.check(not game.menu.opened,"Escape closes map")
    game.bindings.rebind("menu_inventory",KEY_B)
    key(t,KEY_I)
    t.check(not game.menu.opened,"old inventory shortcut stops opening after rebind")
    key(t,KEY_B)
    t.check(game.menu.opened and game.menu.selected=="inventory","rebound inventory shortcut opens while paused-capable")
    game.menu.open_panel("controls")
    game.menu.current_panel.start_capture("attack")
    key(t,KEY_M)
    t.check(game.menu.selected=="controls" and game.menu.current_panel.capture_action=="attack","menu shortcut is consumed during key capture")
    game.menu.close()
    game.change_map("briar","entry")
    key(t,KEY_M)
    t.check(game.menu.current_panel.get("map_id")=="briar","world map shows current area after travel")
    game.menu.close()
    game.queue_free()
    await t.process_frame
    bindings.apply(bindings.defaults())
    var fx=load("res://visuals/combat_effects.gd").new()
    t.root.add_child(fx)
    fx.show_damage(Vector2(300,200),1234,false)
    fx.show_damage(Vector2(300,200),5678,true)
    t.check(fx.numbers[0].position.x==fx.numbers[1].position.x and fx.numbers[0].position.y!=fx.numbers[1].position.y,"consecutive damage lines stack rather than overlap")
    fx._process(0.7)
    for i in range(6): fx.show_damage(Vector2(300,200),100+i,false)
    var positions=[]
    for number in fx.numbers:
        positions.append(number.position.y)
    positions.sort()
    var separated=true
    for i in range(1,positions.size()):
        if positions[i]-positions[i-1]<35: separated=false
    t.check(fx.numbers.size()==8 and separated,"eight-star partner volleys keep all visible lines separated after 0.65 seconds")
    fx._process(1.2)
    t.check(fx.numbers.is_empty(),"damage lines expire cleanly")
    fx.queue_free()
    await t.process_frame
