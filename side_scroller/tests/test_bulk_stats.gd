extends RefCounted
func button(node,text):
    if node is Button and node.text==text: return node
    for child in node.get_children():
        var found=button(child,text)
        if found!=null: return found
    return null
func run(t):
    var state=load("res://systems/character_state.gd").new()
    while state.level<5: state.add_xp(state.xp_required(state.level))
    var panel=load("res://ui/stats_panel.gd").new()
    t.root.add_child(panel)
    panel.bind(state)
    var add_five=button(panel,"+5")
    t.check(add_five!=null,"stats offer a five-point button beside each attribute")
    if add_five==null:
        panel.queue_free()
        return
    for attribute in ["STR","DEX","INT","LUK"]:
        panel.cancel()
        panel.stage(attribute,5)
        t.check(panel.draft.get(attribute,0)==5 and state.attributes[attribute]==4,"five-point draft does not apply early: "+attribute)
    panel.cancel()
    panel.stage("STR",5)
    panel.stage("LUK",-1)
    t.check(panel.draft.STR==5 and panel.draft.LUK==15,"All uses only points remaining after other draft allocations")
    t.check(panel.confirm() and state.ap==0 and state.attributes.STR==9 and state.attributes.LUK==19,"mixed bulk draft confirms exact total once")
    panel.stage("DEX",5)
    t.check(panel.draft.is_empty(),"no points means no extra draft allocation")
    state.add_xp(state.xp_required(state.level))
    panel.stage("INT",1)
    panel.stage("INT",1)
    panel.stage("DEX",5)
    t.check(panel.draft.DEX==3,"five-point request uses final three points without overspending")
    panel.cancel()
    t.check(state.ap==5 and state.attributes.DEX==4,"cancel removes whole bulk draft")
    for key in ["STR","DEX","INT","LUK"]:
        panel.stage(key,-1)
        t.check(panel.draft.get(key,0)==5,"All is available for "+key)
        panel.cancel()
    panel.queue_free()
    await t.process_frame
    var game=load("res://main.tscn").instantiate()
    game.test_mode=true
    t.root.add_child(game)
    game.state.add_xp(game.state.xp_required(1))
    game.menu.open_panel("stats")
    button(game.menu.current_panel,"+5").pressed.emit()
    button(game.menu.current_panel,"Confirm points").pressed.emit()
    t.check(game.state.attributes.STR==9 and game.state.ap==0,"bulk allocation buttons confirm while game is paused")
    game.menu.close()
    game.queue_free()
    await t.process_frame
