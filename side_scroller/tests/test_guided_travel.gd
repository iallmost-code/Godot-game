extends RefCounted
const Maps=preload("res://data/maps.gd")
const Stats=preload("res://data/enemy_stats.gd")
const H=preload("res://tests/helpers.gd")
func run(t):
    t.check(Stats.xp_for(10)>=100 and Stats.xp_for(100)>=3000,"XP rewards keep pace with the level curve")
    t.check(not Maps.definition("portal_hub").is_empty(),"central all-town portal hub exists")
    var game=load("res://main.tscn").instantiate()
    game.test_mode=true
    t.root.add_child(game)
    t.check(game.has_method("fast_travel") and game.has_method("return_nearest_town"),"game exposes safe fast travel and nearest-town return")
    if not game.has_method("fast_travel"):
        game.queue_free()
        await t.process_frame
        return
    H.reach(game.state,100)
    game.state.coins=1234
    game.state.add_item("hat_lv30")
    var before=game.state.to_record()
    game.state.hp=27
    game.menu.open_panel("map")
    t.check(game.fast_travel("portal_hub") and game.map_id=="portal_hub","travel works from a paused map menu")
    t.check(game.state.hp==27,"teleporting preserves current health instead of granting a free heal")
    t.check(not t.paused and not game.menu.opened,"travel closes windows and resumes the game")
    t.check(game.state.coins==before.coins and game.state.inventory.any(func(entry): return entry.id=="hat_lv30"),"travel preserves coins and equipment")
    t.check(not game.fast_travel("missing") and game.map_id=="portal_hub","invalid travel request leaves character in place")
    var hub=Maps.definition("portal_hub")
    var towns=[]
    for portal in hub.portals:towns.append(portal.target)
    for town in Maps.regions():
        t.check(town.id=="portal_hub" or towns.has(town.id),"hub links town "+town.id)
    t.check(game.fast_travel("mossvale"),"guide can travel to its recommended hunting area")
    t.check(game.return_nearest_town() and game.map_id=="starbough","return button uses nearest regional town")
    game.fast_travel("arena_mother_cap")
    t.check(game.map_id==Maps.definition("arena_mother_cap").region,"guide travel to bosses stops at their gate town")
    game.fast_travel("forest")
    var previous=0
    for level in [3,10,30,70]:
        var start=game.state.xp
        game.map.grant_xp("mossling",null,level)
        var reward=game.state.xp-start
        t.check(reward>previous and reward==Stats.xp_for(level),"live placed-level XP reward is consistent at "+str(level))
        previous=reward
    game.state.xp=0
    game.map.grant_xp("grand_shellmaw",null,20)
    t.check(game.state.xp==Stats.xp_for(20)*30,"boss XP keeps its reward multiplier")
    var count=0
    var valid=true
    var appropriate=true
    var catalog=load("res://data/catalog.gd")
    seed(42)
    for i in range(400):
        var reward=game.map.reward_for("stumpkin",70)
        if not reward.has("item"):continue
        count+=1
        if not catalog.items().has(reward.item):valid=false
        elif catalog.items()[reward.item].req<60:appropriate=false
    t.check(count>40 and valid and appropriate,"higher-level mobs drop valid level-appropriate gear even in starter regions")
    game.menu.open_panel("map")
    t.check(game.menu.current_panel.has_method("show_guide"),"map opens an actionable level guide")
    game.menu.close()
    var key=InputEventKey.new()
    key.physical_keycode=KEY_H
    key.pressed=true
    t.root.push_input(key)
    t.check(game.map_id=="portal_hub","H keyboard shortcut enters the portal hub")
    key=InputEventKey.new()
    key.physical_keycode=KEY_T
    key.pressed=true
    t.root.push_input(key)
    t.check(game.map_id=="town","T keyboard shortcut returns from the hub to the starter town")
    game.bindings.rebind("travel_hub",KEY_G)
    game.hud._process(0)
    t.check(game.hud.travel_buttons.travel_hub.text.ends_with("[G]"),"travel HUD displays rebound key")
    game.bindings.apply(game.bindings.defaults())
    game.queue_free()
    await t.process_frame

    var stats=load("res://data/enemy_stats.gd")
    var painted=load("res://visuals/monster_layout.gd")
    var mob_art=load("res://visuals/mob_art.gd")
    for id in stats.ROSTER:
        var body_key=mob_art.painted_key(stats.profile(id))
        t.check(painted.DATA.has(body_key),"painted sprite covers monster variant "+id)
    var boss_art=load("res://visuals/boss_layout.gd")
    for id in stats.BOSSES:
        t.check(boss_art.DATA.has(id),"painted idle and attack artwork covers boss "+id)
    t.check(boss_art.DATA.has("rootwarden"),"Rootwarden matches the painted boss art")
