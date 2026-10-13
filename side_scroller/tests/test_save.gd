extends RefCounted
func run(t):
    var s=load("res://systems/character_state.gd").new()
    var b=load("res://systems/input_bindings.gd").new()
    b.apply(b.defaults())
    s.add_xp(s.xp_required(1))
    s.allocate_attributes({"STR":2})
    s.coins=25
    var store=load("res://systems/save_store.gd").new()
    store.path="user://test-save.json"
    t.root.add_child(store)
    if not store.save(s,b):
        t.check(false,"character writes a save")
        store.queue_free()
        await t.process_frame
        return
    var copy=load("res://systems/character_state.gd").new()
    t.check(store.load_into(copy,b) and copy.attributes.STR==6 and copy.coins==25,"character save round trip")
    var text=store.export_json(s,b)
    var data=JSON.parse_string(text)
    data.character.ap=-1
    t.check(not store.import_json(JSON.stringify(data),copy,b) and copy.coins==25,"negative points reject atomically")
    data=JSON.parse_string(text)
    data.character.attributes.STR=999
    t.check(not store.import_json(JSON.stringify(data),copy,b),"overspent stats rejected")
    data=JSON.parse_string(text)
    data.character.job="dark_knight"
    t.check(not store.import_json(JSON.stringify(data),copy,b),"impossible job rejected")
    data=JSON.parse_string(text)
    data.bindings.attack=data.bindings.jump
    t.check(not store.import_json(JSON.stringify(data),copy,b) and b.current().attack==KEY_SPACE,"duplicate save bindings reject atomically")
    data=JSON.parse_string(text)
    data.character.inventory.append("unknown")
    t.check(not store.import_json(JSON.stringify(data),copy,b),"unknown item rejected")
    t.check(not store.import_json("{broken",copy,b),"corrupt JSON rejected")
    while s.level<10: s.add_xp(s.xp_required(s.level))
    s.advance_job("warrior")
    s.rank_up("strength")
    text=store.export_json(s,b)
    t.check(store.import_json(text,copy,b),"advanced class save round trip")
    var attack=copy.derived_stats().attack
    t.check(store.import_json(text,copy,b) and copy.derived_stats().attack==attack and copy.sp["1"]==0,"reloading grants no extra starter points/modifiers")
    data=JSON.parse_string(text)
    data.character.skill_ranks.wave=5
    t.check(not store.import_json(JSON.stringify(data),copy,b),"unavailable skill rank rejected")
    data=JSON.parse_string(text)
    data.character.erase("coins")
    t.check(store.import_json(JSON.stringify(data),copy,b) and copy.coins==0,"optional missing field has default")
    store.queue_free()
    await t.process_frame
