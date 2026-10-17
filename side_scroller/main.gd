extends Node2D
const Maps=preload("res://data/maps.gd")
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
    player.damaged.connect(func(amount): effects.show_player_damage(player.global_position+Vector2(0,-75),amount))
    player.evaded.connect(func(text): effects.show_evade(player.global_position+Vector2(0,-75),text))
    combat.effect_requested.connect(effects.show_effect)
    combat.loot_requested.connect(func(pos,reward): if map!=null: map.spawn_loot(pos,reward))
    combat.door_requested.connect(func():
        change_map("town","entry")
        hud.show_notice("The Wayshrine carries you back to Willowbridge.",5))
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
    menu.player=player
    hud.menu_requested.connect(menu.open_panel)
    combat.feedback.connect(hud.show_notice)
    player.interact_requested.connect(func(): if map!=null: map.interact())
    player.died.connect(return_to_town,CONNECT_DEFERRED)
    state.leveled.connect(func(lv):
        hud.show_notice("LEVEL %d! +5 attribute points. Open Stats to spend them." % lv,6)
        effects.show_level_up(player.position))
    save_store=preload("res://systems/save_store.gd").new()
    save_store.process_mode=Node.PROCESS_MODE_ALWAYS
    add_child(save_store)
    save_store.warning.connect(func(message):
        startup_warning=message
        hud.show_notice(message,10))
    if not test_mode:
        var selected=save_store.selected_slot()
        save_store.use_slot(selected)
        state.initialize_class(selected)
        save_store.load_into(state,bindings)
        if state.migration_note!="": startup_warning=state.migration_note
    state.changed.connect(func(): call_deferred("persist"))
    menu.binding_changed.connect(persist)
    menu.character_requested.connect(switch_character)
    menu.travel_requested.connect(func(target): change_map(target,"entry"))
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
    var definition=Maps.definition(id)
    if definition.is_empty() or not definition.spawns.has(spawn): return false
    var next=preload("res://world/map_controller.gd").new()
    next.map_id=id
    next.player=player
    next.z_index=-5
    add_child(next)
    next.setup(state)
    next.portal_requested.connect(change_map)
    next.advancement_requested.connect(show_advancement)
    next.reward_notice.connect(hud.show_notice)
    next.boss_spawned.connect(func(enemy): hud.boss_target=enemy)
    if map!=null:
        remove_child(map)
        map.queue_free()
    map=next
    map_id=id
    menu.world_map_id=id
    combat.cancel()
    for star in get_tree().get_nodes_in_group("player_stars"): star.queue_free()
    for summon in get_tree().get_nodes_in_group("summons"):
        if summon.config.get("decoy",false): summon.queue_free()
    effects.effects.clear()
    effects.shapes.clear()
    effects.clear_numbers()
    player.reset_at(map.spawn_position(spawn))
    hud.map_label.text=definition.title
    hud.boss_target=next.boss
    hud.player=player
    if id=="forest": hud.show_notice("Briar Hollow lies beyond the far-right portal. Recommended level 15+.",7)
    elif id=="briar": hud.show_notice("Briar Hollow: stronger monsters, better loot. Rootwarden waits at the far end.",7)
    elif definition.has("boss"): hud.show_notice("%s awaits. Watch its warnings!" % preload("res://data/enemy_stats.gd").profile(definition.boss).name,6)
    elif definition.has("level_range"): hud.show_notice("%s  •  Recommended %s" % [definition.title.split("  /")[0].capitalize(),definition.level_range],6)
    camera.position=Vector2(clampf(player.position.x,557,map.width-557),450)
    return true
func return_to_town():
    combat.clear_partner()
    combat.clear_summons()
    combat.combo_orbs=0
    state.clear_buffs()
    state.restore()
    change_map("town","entry")
    hud.show_notice("Back on your feet. All collected loot and progress are kept.",7)
func switch_character(slot: String) -> bool:
    if not save_store.slot_paths.has(slot) or slot==save_store.active_slot: return false
    if not save_store.save(state,bindings): return false
    var previous_slot=save_store.active_slot
    var previous_bindings=bindings.current()
    save_store.use_slot(slot)
    var next=preload("res://systems/character_state.gd").new()
    next.initialize_class(slot)
    if FileAccess.file_exists(save_store.path) and not save_store.load_into(next,bindings):
        save_store.use_slot(previous_slot)
        bindings.apply(previous_bindings)
        hud.show_notice("Could not load that character. Your current character is kept.",7)
        return false
    if not save_store.remember_slot(slot):
        save_store.use_slot(previous_slot)
        bindings.apply(previous_bindings)
        return false
    combat.cancel()
    combat.cooldowns.clear()
    combat.clear_partner()
    combat.clear_summons()
    combat.combo_orbs=0
    for star in get_tree().get_nodes_in_group("player_stars"): star.queue_free()
    state.load_record(next.to_record())
    menu.close()
    change_map("town","entry")
    var first=preload("res://data/catalog.gd").first_job(slot)
    hud.show_notice(state.migration_note if state.migration_note!="" else "%s loaded. At level %d, stand beside Elowen and press Up to advance." % [state.archetype_name(slot),preload("res://data/catalog.gd").jobs()[first].level],8)
    return true
const JOB_BLURBS={
    "warrior":"Front-line fighter. Heavy Blow, Cleave and Steel Skin.","magician":"Spellcaster. Arcane Bolt, Spell Talons and Mana Shield.","archer":"Ranged hunter. Power Shot, Twin Shot and Steady Aim.","thief":"Swift and deadly. Double Toss, Twin Fang and Vanish.",
    "fighter":"Sword master: Bloodlust, Blade Tempo and Follow-Through. Becomes Warlord, then Champion.","page":"Shield knight: Intimidate and Iron Riposte. Becomes Runeknight with elemental brands, then Templar.","spearman":"Spear wielder: Titan's Vigor and Bulwark. Becomes Wyrm Knight, then Dread Knight.",
    "fp_wizard":"Fire and poison. Flame Dart, Toxic Breath, Blink. Becomes Cinder Magus, then Inferno Archon.","il_wizard":"Ice and lightning. Frost Lance, Thunderclap, Blink. Becomes Storm Magus, then Tempest Archon.","cleric":"Holy healer. Mending Light, Benediction, Sacred Bolt. Becomes Oracle, then Hierarch.",
    "hunter":"Bow user: Blast Arrow, Spirit Quiver. Becomes Falconer, then Windmaster.","crossbowman":"Crossbow user: Piercing Bolt, Spirit Quiver. Becomes Deadeye, then Sharpshooter.",
    "assassin":"Claw and stars: Leeching Star, Swiftness, Vital Throw. Becomes Shadeweaver, then Nightblade.","bandit":"Daggers up close: Frenzy Cuts, Pilfer. Becomes Cutthroat, then Duskreaper."}
func show_advancement(_id: String=""):
    var Catalog=preload("res://data/catalog.gd")
    var options=state.next_jobs()
    if options.is_empty():
        hud.show_notice("Elowen: You have mastered every advancement on your path.",7)
        return
    var required=Catalog.jobs()[options[0]].level
    if state.level<required:
        hud.show_notice("Elowen: Return at level %d for your next advancement." % required,6)
        return
    menu.open_panel("stats")
    var box=VBoxContainer.new()
    Style.clear(menu.content)
    menu.content.add_child(box)
    box.add_child(Style.label("JOB ADVANCEMENT",26,Color("f4d48a")))
    box.add_child(Style.label("Choose your path. This choice is permanent." if options.size()>1 else "You are ready for your next advancement.",18))
    for option in options:
        var job=Catalog.jobs()[option]
        var reward=Catalog.items().get(job.get("reward",""),{})
        box.add_child(Style.label(job.name.to_upper(),21,Color("8ed9d0")))
        box.add_child(Style.label(JOB_BLURBS.get(option,"Unlocks new %s skills and a %s." % [job.name,reward.get("name","weapon")])+("\nReward: %s (ATK %d)" % [reward.name,reward.attack] if not reward.is_empty() else ""),16))
        box.add_child(Style.button("Become a %s" % job.name,func():
            if state.advance_job(option):
                menu.close()
                hud.show_notice("You are now a %s! Open Skills to spend your new skill point." % job.name,7)))
    box.add_child(Style.button("Not yet",menu.close))
func _process(delta):
    state.potion_cooldown=maxf(0,state.potion_cooldown-delta)
    state.regenerate(delta,map_id=="town")
    if player.position.y>950: return_to_town()
    if map!=null:
        player.position.x=clampf(player.position.x,20,map.width-20)
        camera.position=Vector2(lerpf(camera.position.x,clampf(player.position.x,557,map.width-557),minf(1,delta*6)),450)

func persist():
    if not test_mode and save_store!=null: save_store.save(state,bindings)
