extends Node2D
const Style=preload("res://ui/style.gd")
var test_mode=false
var state
var bindings
var player
var combat
var effects
var camera
var map
var map_id=""
var hud
var menu
var advancement_dialog
var pending_job=""
var save_store
var mana_tick=0.0
var startup_warning=""
func _ready():
    state=preload("res://systems/character_state.gd").new()
    bindings=preload("res://systems/input_bindings.gd").new()
    bindings.apply(bindings.defaults())
    player=preload("res://actors/player.gd").new()
    player.state=state
    add_child(player)
    player.z_index=5
    combat=preload("res://actors/combat_controller.gd").new()
    add_child(combat)
    combat.setup(player,state)
    effects=preload("res://visuals/combat_effects.gd").new()
    effects.z_index=12
    add_child(effects)
    combat.attack_started.connect(func(id,origin,direction,reach): effects.show_attack(id,origin,direction,reach))
    combat.impact.connect(effects.show_damage)
    camera=Camera2D.new()
    camera.zoom=Vector2(1.15,1.15)
    camera.position_smoothing_enabled=false
    add_child(camera)
    hud=preload("res://ui/hud.gd").new()
    add_child(hud)
    hud.bind(state,combat,bindings)
    menu=preload("res://ui/menu.gd").new()
    add_child(menu)
    menu.setup(state,bindings)
    hud.menu_requested.connect(menu.open_panel)
    combat.feedback.connect(hud.show_notice)
    player.interact_requested.connect(func(): if map!=null: map.interact())
    player.died.connect(return_to_town,CONNECT_DEFERRED)
    state.leveled.connect(func(lv):
        hud.show_notice("LEVEL %d! +5 attribute points. Open Stats to spend them." % lv,6)
        effects.show_attack("wave",player.position,1))
    save_store=preload("res://systems/save_store.gd").new()
    save_store.process_mode=Node.PROCESS_MODE_ALWAYS
    add_child(save_store)
    save_store.warning.connect(func(message):
        startup_warning=message
        hud.show_notice(message,10))
    if not test_mode: save_store.load_into(state,bindings)
    state.changed.connect(func(): call_deferred("persist"))
    menu.binding_changed.connect(persist)
    menu.save_requested.connect(func():
        if save_store.save(state,bindings): hud.show_notice("Character saved."))
    menu.export_requested.connect(func(): save_store.export_backup(state,bindings))
    menu.import_requested.connect(func(): save_store.import_backup(state,bindings))
    change_map("town","entry")
    if startup_warning=="": hud.show_notice("Welcome! Arrows move • Shift jumps twice • Space attacks • Up interacts",10)
    else: hud.show_notice(startup_warning,10)
    if test_mode:
        player.set_physics_process(false)
        set_process(false)
func change_map(id: String,spawn: String) -> bool:
    if not ["town","forest"].has(id) or not ["entry","portal"].has(spawn): return false
    var next=preload("res://world/map_controller.gd").new()
    next.map_id=id
    next.player=player
    next.z_index=-5
    add_child(next)
    next.setup(state)
    next.portal_requested.connect(change_map)
    next.advancement_requested.connect(show_advancement)
    next.reward_notice.connect(hud.show_notice)
    if map!=null:
        remove_child(map)
        map.queue_free()
    map=next
    map_id=id
    combat.cancel()
    player.reset_at(map.spawn_position(spawn))
    hud.map_label.text="WILLOWBRIDGE  /  SAFE TOWN" if id=="town" else "THE WHISPERWOOD  /  MONSTER FIELD"
    if id=="forest": hud.show_notice("Defeat creatures for XP. Job advancement begins at level 10 in town.",7)
    camera.position=Vector2(clampf(player.position.x,557,map.width-557),450)
    return true
func return_to_town():
    state.restore()
    change_map("town","entry")
    hud.show_notice("Back on your feet. All collected loot and progress are kept.",7)
func show_advancement(id: String):
    var required=10 if id=="warrior" else 30
    if state.level<required or (state.job=="spearman"):
        hud.show_notice("Elowen: Return at level %d. Later jobs are coming in a future build." % required,6)
        return
    pending_job=id
    menu.open_panel("stats")
    var box=VBoxContainer.new()
    Style.clear(menu.content)
    menu.content.add_child(box)
    box.add_child(Style.label("JOB ADVANCEMENT",26,Color("f4d48a")))
    box.add_child(Style.label("Become a %s?\n\n%s" % [id.capitalize(),"Unlock Crescent Sweep and Driving Thrust, plus the first-job skill tree." if id=="warrior" else "Unlock Spear Mastery -> Ground Wave and Battle Vigor."],20))
    box.add_child(Style.button("Confirm advancement",func():
        if state.advance_job(pending_job):
            menu.close()
            hud.show_notice("You are now a %s! Open Skills to learn and equip abilities." % state.job.capitalize(),7)))
    box.add_child(Style.button("Not yet",menu.close))
func _process(delta):
    state.potion_cooldown=maxf(0,state.potion_cooldown-delta)
    state.mp=minf(state.derived_stats().max_mp,state.mp+2.5*delta)
    if map_id=="town": state.hp=minf(state.derived_stats().max_hp,state.hp+12*delta)
    if player.position.y>950: return_to_town()
    if map!=null:
        player.position.x=clampf(player.position.x,20,map.width-20)
        camera.position=Vector2(lerpf(camera.position.x,clampf(player.position.x,557,map.width-557),minf(1,delta*6)),450)

func persist():
    if not test_mode and save_store!=null: save_store.save(state,bindings)
