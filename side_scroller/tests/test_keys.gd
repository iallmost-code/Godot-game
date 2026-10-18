extends RefCounted
# Maple-style key config: skills on any key, actions movable and clearable.
const H=preload("res://tests/helpers.gd")
const Keymap=preload("res://systems/keymap.gd")
const Catalog=preload("res://data/catalog.gd")
func run(t):
    var game=load("res://main.tscn").instantiate()
    game.test_mode=true
    t.root.add_child(game)
    await t.process_frame
    var s=game.state
    var b=game.bindings
    s.load_record(H.make("thief",["thief","assassin","hermit"],80).to_record())
    var learned=[]
    for id in Catalog.skills():
        var skill=Catalog.skill(id)
        if skill.job!="" and skill.active and s.in_lineage(id) and learned.size()<12:
            H.learn(s,id)
            learned.append(id)
    var free=[KEY_W,KEY_E,KEY_R,KEY_Y,KEY_U,KEY_O,KEY_P,KEY_G,KEY_J,KEY_L,KEY_N,KEY_B]
    var placed=0
    for i in learned.size():
        if Keymap.assign(s,b,free[i],"skill",learned[i])=="": placed+=1
    t.check(placed==12 and s.keys.size()==12,"twelve skills sit on twelve different keys")
    t.check(InputMap.has_action("key_%d" % KEY_W) and InputMap.has_action("key_%d" % KEY_B),"every skill key gets its own input action")
    t.check(Keymap.assign(s,b,KEY_Q,"skill",learned[0])=="" and s.keys.get(KEY_Q,"")==learned[0] and not s.keys.has(KEY_W) and b.current().menu_quests==0,"a skill can take over an optional action's key")
    t.check(Keymap.assign(s,b,KEY_SHIFT,"skill",learned[1])!="" and b.current().jump==KEY_SHIFT,"required actions such as Jump keep their key")
    t.check(Keymap.assign(s,b,KEY_E,"action","potion_hp")=="" and b.current().potion_hp==KEY_E and not s.keys.has(KEY_E),"an action placed on a skill's key replaces the skill")
    t.check(Keymap.assign(s,b,KEY_SPACE,"action","jump")=="" and b.current().jump==KEY_SPACE and b.current().attack==KEY_SHIFT,"moving an action onto another action's key swaps them")
    t.check(Keymap.clear(s,b,KEY_SPACE)!="" and Keymap.clear(s,b,KEY_E)=="" and b.current().potion_hp==0,"required actions cannot be cleared; optional ones can")
    t.check(Keymap.clear(s,b,KEY_R)=="" and not s.keys.has(KEY_R),"clearing a skill key empties it")
    # The hotbar follows the keyboard.
    game.hud.refresh()
    var shown=game.hud.skills.slice(1).map(func(e): return e.icon.skill_id).filter(func(id): return id!="")
    t.check(shown.size()==9 and shown[0]==s.keys[KEY_Q],"the hotbar shows skills in keyboard order")
    # Pressing a skill key uses the skill.
    b.apply(b.defaults())
    Keymap.apply_skills(s,b)
    var attack_skill=""
    for id in learned:
        if Catalog.skill(id).kind=="attack" and s.key_of(id)!=0 and s.key_of(id)!=KEY_Q: attack_skill=id
    var code=s.key_of(attack_skill)
    s.mp=9999
    game.change_map("dewdrop","entry")
    game.combat.cancel()
    game.combat.cooldowns.clear()
    Input.action_press("key_%d" % code)
    game.player._physics_process(0.016)
    Input.action_release("key_%d" % code)
    t.check(game.combat.active==attack_skill,"pressing a skill's key casts it")
    # Saves keep the keys; old seven-slot saves move onto their letters.
    var copy=load("res://systems/character_state.gd").new()
    t.check(copy.load_record(s.to_record()) and copy.keys==s.keys,"skill keys are saved")
    var old=s.to_record()
    old.erase("keys")
    old.slots={"z":learned[0],"x":"","c":learned[2],"v":"","a":"","d":"","f":""}
    t.check(copy.load_record(old) and copy.keys=={KEY_Z:learned[0],KEY_C:learned[2]},"old hotbar saves move onto Z X C V A D F")
    var legacy=load("res://systems/input_bindings.gd").new()
    var old_bindings=legacy.defaults()
    old_bindings.skill_z=KEY_8
    old_bindings.skill_x=KEY_X
    t.check(legacy.apply(old_bindings) and legacy.legacy_skill_keys.z==KEY_8,"old bindings with skill slots still load")
    copy.adopt_legacy_keys(legacy.legacy_skill_keys)
    t.check(copy.keys.get(KEY_8,"")==learned[0] and not copy.keys.has(KEY_Z),"a skill on a custom old key stays on that key")
    var bad=s.to_record()
    bad.keys={"90":"not_a_skill"}
    t.check(not copy.load_record(bad),"unknown skills on keys are rejected")
    # The keyboard window.
    game.change_map("town","entry")
    game.menu.open_panel("controls")
    var panel=game.menu.current_panel
    panel.pick({"kind":"skill","id":learned[3]})
    panel.key_clicked(KEY_9)
    t.check(s.keys.get(KEY_9,"")==learned[3],"pick a skill, click a key")
    panel.key_clicked(KEY_9)
    panel.key_clicked(KEY_0)
    t.check(s.keys.get(KEY_0,"")==learned[3] and not s.keys.has(KEY_9),"click a key to pick up its skill and click another to move it")
    panel.key_cleared(KEY_0)
    t.check(not s.keys.has(KEY_0),"right-click clears a key")
    t.check(game.menu.tabs_by_id.controls.text.begins_with("Keys"),"the Keys tab opens the key config")
    game.menu.close()
    b.apply(b.defaults())
    game.queue_free()
    await t.process_frame
