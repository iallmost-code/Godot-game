extends RefCounted
const H=preload("res://tests/helpers.gd")
const C=preload("res://data/catalog.gd")
func run(t):
    var s=H.make("thief",["thief","assassin","hermit","night_lord"],150)
    t.check(s.has_method("set_item_locked"),"equipment can be protected from selling and dismantling")
    t.check(FileAccess.file_exists("res://data/loot_quality.gd"),"loot has rarity and original boss trophies")
    t.check(FileAccess.file_exists("res://ui/journey_panel.gd"),"character journey explains advancements and unlocks")
    t.check(FileAccess.file_exists("res://systems/soundscape.gd"),"regional music and combat sounds are available")
    if not s.has_method("set_item_locked"):return
    var uid=s.add_item_uid("claw_lv110")
    t.check(s.set_item_locked(uid,true) and s.sell(uid)==0 and s.dismantle(uid)==0,"locked equipment cannot be destroyed")
    t.check(not s.worse_gear().has(uid),"bulk cleanup excludes locked gear")
    var comparison=s.add_item_uid("claw_lv110")
    s.equip(comparison)
    var potential=s.add_item_uid("claw_lv110")
    s.instance(potential).affixes={"LUK":20}
    t.check(not s.worse_gear().has(potential),"bulk cleanup preserves gear with better primary stats")
    var saved=s.to_record()
    var copy=load("res://systems/character_state.gd").new()
    t.check(copy.load_record(saved) and copy.instance(uid).locked,"item protection survives save round trip")
    var quality=load("res://data/loot_quality.gd")
    var plain=s.item_attack({"id":"claw_lv110","uid":1000,"plus":0})
    var reward={"item":"claw_lv110","rarity":"epic","affixes":{"attack":12,"LUK":8},"origin":"chronovore"}
    t.check(s.collect_reward(reward),"rarity gear is collectible")
    var item=s.inventory.back()
    t.check(s.item_attack(item)==plain+12 and item.origin=="chronovore","random bonuses affect combat and retain boss provenance")
    t.check(copy.load_record(s.to_record()) and copy.inventory.back().affixes.LUK==8,"rarity and affixes survive validated save loading")
    var bad=s.to_record()
    bad.inventory.back().affixes.attack=100000
    t.check(not copy.load_record(bad),"corrupt rarity bonuses are rejected")
    var coins=s.coins
    t.check(not s.collect_reward({"item":"claw_lv110","rarity":"made_up","coins":100}) and s.coins==coins,"invalid loot is rejected atomically")
    var boss_reward=quality.decorate({"item":"claw_lv110"},125,"chronovore")
    t.check(boss_reward.rarity=="epic" and boss_reward.origin=="chronovore","bosses guarantee named epic gear")
    var low=0
    var high=0
    seed(22)
    for i in range(600):
        if quality.decorate({"item":"claw_lv110"},10).rarity!="common":low+=1
        if quality.decorate({"item":"claw_lv110"},150).rarity!="common":high+=1
    t.check(high>low and low>0,"rare loot remains special and improves in higher-level areas")
    var game=load("res://main.tscn").instantiate()
    game.test_mode=true
    t.root.add_child(game)
    t.check(game.state.load_record(s.to_record()),"polished character loads into live game")
    game.combat.summon_partner("",180)
    game.hud.refresh()
    t.check(game.hud.partner_bar.max_value==180,"summon timer bar uses the actual cast duration")
    game.combat.clear_partner()
    game.menu.open_panel("journey")
    t.check(game.menu.current_panel.summary().contains("Nightblade") and game.menu.current_panel.summary().contains("4th"),"journey recognizes completed fourth job")
    game.menu.open_panel("bosses")
    t.check(game.menu.current_panel.entries().size()==13,"boss journal lists twelve lairs and Rootwarden")
    game.menu.close()
    game.change_map("arena_grand_shellmaw","entry")
    var boss=game.map.boss
    t.check(boss.has_method("update_stage"),"bosses expose health-based encounter stages")
    if boss.has_method("update_stage"):
        boss.hp=boss.max_hp*0.3
        boss.update_stage()
        t.check(boss.stage==3 and boss.enraged,"boss enters its final attack stage at low health")
        boss.start_pattern()
        t.check(boss.windup>=0.65,"late-stage boss telegraphs remain readable")
    t.check(game.hud.get("boss_warning")!=null,"boss telegraphs have an unobstructed HUD warning")
    if game.hud.get("boss_warning")!=null:
        boss.phase="windup"
        boss.pattern="beam"
        game.player.position=boss.position+Vector2(-100,0)
        game.hud.refresh()
        t.check(game.hud.boss_warning.visible and game.hud.boss_warning.text.contains("LOW SWEEP"),"HUD explains the active attack while its ground warning is visible")
    var inventory=load("res://ui/inventory_panel.gd").new()
    t.root.add_child(inventory)
    inventory.bind(s)
    inventory.sort_bag("level")
    t.check(s.instance(uid).locked and s.inventory.size()==saved.inventory.size()+1,"sorting preserves instances and item locks")
    inventory.queue_free()
    var tracks_ready=game.sound.streams.size()==24
    for stream in game.sound.streams.values():
        if stream==null or stream.get_length()<.02:tracks_ready=false
    t.check(tracks_ready,"all 24 original music, ambience and sound assets load")
    t.check(game.sound.track_for("coast")!=game.sound.track_for("snow") and game.sound.track_for("toy")!=game.sound.track_for("temple"),"different regions select distinct music")
    game.sound.set_levels(-1,2,false)
    t.check(game.sound.music_volume==0 and game.sound.effects_volume==1 and not game.sound.shake_enabled,"volume controls clamp safely and can disable shake")
    game.menu.open_panel("controls")
    t.check(game.menu.current_panel.has_method("set_audio"),"audio levels can be changed from settings")
    t.check(game.sound.can_process(),"music continues while paused menus are open")
    game.menu.close()
    var original_path=OS.get_environment("WINDSWEPT_COMPAT_SAVE")
    if FileAccess.file_exists(original_path):
        var original=JSON.parse_string(FileAccess.get_file_as_string(original_path))
        t.check(copy.load_record(original.character) and copy.job=="night_lord" and copy.level==150,"uploaded level-150 thief save stays compatible")
    game.queue_free()
    await t.process_frame
