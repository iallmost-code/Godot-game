extends Node2D
const Travel=preload("res://systems/world_travel.gd")
const Maps=preload("res://data/maps.gd")
const Style=preload("res://ui/style.gd")
var sound
var shake_time=0.0
var shake_power=0.0
var step_time=0.0
var frontend
var loaded_character=false
var protected_startup_save=false
var test_mode=false
var state
var bindings
var player
var combat
var effects
var camera
var map
var map_id=""
var respawn_map_id="town"
var hud
var menu
var advancement_dialog
var pending_job=""
var save_store
var mana_tick=0.0
var startup_warning=""
var dialog
var pet_node
func _ready():
    sound=preload("res://systems/soundscape.gd").new()
    sound.enabled=not test_mode
    add_child(sound)
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
    combat.attack_started.connect(func(id,origin,direction,reach):
        effects.show_attack(id,origin,direction,reach,combat.windup)
        var skill=preload("res://data/catalog.gd").skill(id)
        if skill.get("shape","")!="projectile":sound.play_effect("spell" if skill.get("element","")!="" else "swing"))
    combat.impact.connect(func(pos,amount,critical):
        effects.show_damage(pos,amount,critical)
        effects.show_hit(pos,critical)
        sound.play_effect("crit" if critical else "hit")
        if sound.shake_enabled and critical:shake_time=.12;shake_power=2.5)
    player.damaged.connect(func(amount):
        effects.show_player_damage(player.global_position+Vector2(0,-75),amount)
        sound.play_effect("hurt")
        if sound.shake_enabled:shake_time=.15;shake_power=3)
    player.evaded.connect(func(text): effects.show_evade(player.global_position+Vector2(0,-75),text))
    combat.effect_requested.connect(effects.show_effect)
    combat.effect_requested.connect(func(kind,data):
        if kind=="launch":
            var style=data.get("style","star")
            sound.play_effect("arrow" if style=="arrow" else "spell" if style=="bolt" else "star"))
    combat.loot_requested.connect(func(pos,reward): if map!=null: map.spawn_loot(pos,reward))
    combat.door_requested.connect(func():
        change_map(respawn_map_id,"entry")
        hud.show_notice("The Wayshrine carries you back to %s." % Maps.definition(respawn_map_id).name,5))
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
    hud.travel_requested.connect(fast_travel)
    hud.town_requested.connect(return_nearest_town)
    menu.travel_requested.connect(fast_travel)
    menu.town_requested.connect(return_nearest_town)
    combat.feedback.connect(hud.show_notice)
    player.interact_requested.connect(func(): if map!=null: map.interact())
    player.died.connect(return_to_town,CONNECT_DEFERRED)
    state.leveled.connect(func(lv):
        sound.play_effect("level")
        hud.show_notice("LEVEL %d! +5 attribute points%s." % [lv," and 3 skill points" if state.tier()>0 else ""],6)
        var fx=preload("res://visuals/level_up_fx.gd").new()
        fx.follow=player
        fx.position=player.global_position
        add_child(fx))
    dialog=preload("res://ui/dialog_box.gd").new()
    add_child(dialog)
    dialog.setup(state)
    dialog.reward_received.connect(func(text): hud.show_notice(text,7))
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
        var existing_save=FileAccess.file_exists(save_store.path)
        loaded_character=save_store.load_into(state,bindings)
        protected_startup_save=existing_save and not loaded_character
        state.adopt_legacy_keys(bindings.legacy_skill_keys)
        if state.migration_note!="": startup_warning=state.migration_note
    state.changed.connect(func(): call_deferred("persist"))
    # Skills sit on any key; rebuild their input actions whenever the keys change.
    state.changed.connect(refresh_skill_keys)
    refresh_skill_keys()
    menu.title_requested.connect(return_to_title)
    menu.binding_changed.connect(persist)
    menu.binding_changed.connect(refresh_skill_keys)
    menu.character_requested.connect(switch_character)
    menu.save_requested.connect(func():
        if save_store.save(state,bindings): hud.show_notice("Character saved."))
    menu.export_requested.connect(func(): save_store.export_backup(state,bindings))
    menu.import_requested.connect(func(): save_store.import_backup(state,bindings))
    respawn_map_id=state.town
    change_map(state.town,"entry")
    if startup_warning=="": hud.show_notice("Welcome! Arrows move • Shift jumps twice • Space attacks • Up interacts",10)
    else: hud.show_notice(startup_warning,10)
    frontend=preload("res://ui/front_menu.gd").new()
    add_child(frontend)
    frontend.setup(self)
    if not test_mode:frontend.open_title()
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
    next.shop_requested.connect(func(): menu.open_panel("shop"))
    next.quest_requested.connect(func(npc): dialog.talk(map_id,npc))
    next.reward_notice.connect(hud.show_notice)
    next.loot_collected.connect(func(rare):sound.play_effect("epic" if rare else "loot"))
    next.experience_gained.connect(hud.show_xp)
    next.boss_spawned.connect(func(enemy): hud.boss_target=enemy)
    if map!=null:
        remove_child(map)
        map.queue_free()
    map=next
    map_id=id
    if definition.safe:
        respawn_map_id=id
        state.remember_town(id)
    sound.set_region(definition.biome,definition.has("boss"))
    player.climbs=map.climbs
    hud.minimap.map=map
    hud.minimap.player=player
    refresh_pet()
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
    elif id!="town": hud.show_notice(definition.name+" - "+("Safe town. Health recovers here. Open M for routes." if definition.safe else definition.get("notice","Explore this hunting area.")),6)
    camera.position=Vector2(clampf(player.position.x,557,map.width-557),camera_y())
    return true
func camera_y() -> float:
    if map==null: return 450.0
    return clampf(player.position.y-110,map.top+313,450)
func refresh_pet():
    if pet_node!=null and is_instance_valid(pet_node) and (state.pet=="" or pet_node.pet_id!=state.pet):
        pet_node.queue_free()
        pet_node=null
    if state.pet=="" or map==null: return
    if pet_node==null:
        pet_node=preload("res://world/pet.gd").new()
        pet_node.z_index=4
        add_child(pet_node)
        pet_node.position=player.position+Vector2(-50,0)
    pet_node.pet_id=state.pet
    pet_node.player=player
    pet_node.map=map
    if pet_node.position.distance_to(player.position)>300: pet_node.position=player.position+Vector2(-50,0)
func return_to_town():
    combat.clear_partner()
    combat.clear_summons()
    combat.combo_orbs=0
    state.clear_buffs()
    state.restore()
    change_map(respawn_map_id,"entry")
    hud.show_notice("Back on your feet. All collected loot and progress are kept.",7)
func switch_character(slot: String) -> bool:
    if not save_store.slot_paths.has(slot) or slot==save_store.active_slot: return false
    if not protected_startup_save and not save_store.save(state,bindings): return false
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
    loaded_character=true
    protected_startup_save=false
    state.adopt_legacy_keys(bindings.legacy_skill_keys)
    refresh_skill_keys()
    respawn_map_id=state.town
    menu.close()
    change_map(state.town,"entry")
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
    pending_job=options[0]
    menu.open_panel("stats")
    var box=VBoxContainer.new()
    Style.clear(menu.content)
    menu.current_panel=null
    menu.windows["stats"].current=null
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
                var fx=preload("res://visuals/level_up_fx.gd").new()
                fx.kind="skill_learned"
                fx.follow=player
                add_child(fx)
                hud.show_notice("You are now a %s! Open Skills to spend your new skill point." % job.name,7)))
    box.add_child(Style.button("Not yet",menu.close))
func _process(delta):
    shake_time=maxf(0,shake_time-delta)
    camera.offset=Vector2(sin(Time.get_ticks_msec()*.063),cos(Time.get_ticks_msec()*.079))*shake_power*minf(1,shake_time/.12) if sound.shake_enabled and shake_time>0 else Vector2.ZERO
    step_time-=delta
    if step_time<=0 and player.is_on_floor() and absf(player.velocity.x)>40:
        sound.play_effect("step")
        step_time=.28
    state.potion_cooldown=maxf(0,state.potion_cooldown-delta)
    state.mana_potion_cooldown=maxf(0,state.mana_potion_cooldown-delta)
    state.regenerate(delta,Maps.definition(map_id).get("safe",false))
    if player.position.y>950: return_to_town()
    if map!=null:
        player.position.x=clampf(player.position.x,20,map.width-20)
        camera.position=Vector2(lerpf(camera.position.x,clampf(player.position.x,557,map.width-557),minf(1,delta*6)),lerpf(camera.position.y,camera_y(),minf(1,delta*5)))
        if state.pet!=(pet_node.pet_id if pet_node!=null and is_instance_valid(pet_node) else ""): refresh_pet()

var skill_key_signature=""
func refresh_skill_keys():
    var signature=str(state.keys)+str(bindings.current())
    if signature==skill_key_signature: return
    skill_key_signature=signature
    preload("res://systems/keymap.gd").apply_skills(state,bindings)
func persist():
    if not test_mode and save_store!=null:
        if protected_startup_save:return
        save_store.save(state,bindings)

func fast_travel(destination: String) -> bool:
    if Maps.definition(destination).is_empty(): return false
    var target=Travel.travel_target(destination)
    menu.close()
    if dialog.opened: dialog.close()
    combat.clear_partner()
    combat.clear_summons()
    combat.combo_orbs=0
    if not change_map(target,"entry"): return false
    hud.show_notice("Arrived: "+Maps.definition(target).name+" • M: level guide • H: all town portals • T: nearest town",7)
    return true
func return_nearest_town() -> bool:
    return fast_travel(Travel.nearest_town(map_id,player.position))
func _unhandled_input(event):
    if not event is InputEventKey or not event.pressed or event.echo or menu.opened or dialog.opened: return
    if event.is_action_pressed("travel_hub"):
        fast_travel("portal_hub")
        get_viewport().set_input_as_handled()
    elif event.is_action_pressed("travel_town"):
        return_nearest_town()
        get_viewport().set_input_as_handled()

func return_to_title() -> bool:
    if protected_startup_save:
        hud.show_notice("Restore a valid backup before saving this character.",8)
        return false
    if not save_store.save(state,bindings):
        hud.show_notice("Could not save. Stay in game and export a backup before leaving.",8)
        return false
    menu.close()
    if dialog.opened:dialog.close()
    frontend.session_started=true
    frontend.open_title()
    return true
