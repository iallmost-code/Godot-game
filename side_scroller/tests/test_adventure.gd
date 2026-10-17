extends RefCounted
# Ropes and tall maps, quests, scrolls, pets, looks, skill icons and the minimap.
const H=preload("res://tests/helpers.gd")
const Maps=preload("res://data/maps.gd")
const Quests=preload("res://systems/quests.gd")
const Adventure=preload("res://data/adventure.gd")
const Catalog=preload("res://data/catalog.gd")
const EnemyStats=preload("res://data/enemy_stats.gd")
func run(t):
    world_checks(t)
    quest_checks(t)
    scroll_checks(t)
    save_checks(t)
    await game_checks(t)
func world_checks(t):
    var tall=0
    var bad=[]
    for id in Maps.all_ids():
        var data=Maps.definition(id)
        if data.climbs.is_empty(): continue
        tall+=1
        for c in data.climbs:
            var top_ok=false
            var bottom_ok=c[2]==610
            for p in data.platforms:
                if absf(p[1]-c[1])<1 and absf(p[0]-c[0])<=p[2]/2.0: top_ok=true
                if absf(p[1]-c[2])<1 and absf(p[0]-c[0])<=p[2]/2.0: bottom_ok=true
            if not top_ok or not bottom_ok: bad.append(id)
    t.check(tall>=40,"hunting maps have upper ledges reached by ropes and ladders (%d maps)" % tall)
    t.check(bad.is_empty(),"every rope and ladder joins two standing surfaces %s" % str(bad.slice(0,3)))
    t.check(Maps.definition("town").climbs.is_empty() and Maps.definition(Maps.boss_arena_id("mother_cap")).climbs.is_empty(),"towns and boss lairs stay flat")
    var forest=Maps.definition("forest")
    var high=forest.enemies.filter(func(e): return e[1]<=Maps.TIER_A)
    t.check(forest.top<0 and high.size()>=3,"upper ledges have their own monsters")
    var missing=[]
    for id in Catalog.skills():
        if preload("res://visuals/skill_icon_layout.gd").region(id).size.x<=0: missing.append(id)
    t.check(missing.is_empty(),"every skill has a painted icon")
func quest_checks(t):
    Quests.reset_cache()
    var all=Quests.all()
    t.check(all.size()>=90,"every town has a quest chain (%d quests)" % all.size())
    var broken=[]
    for id in all:
        var q=all[id]
        if q.type!="deliver" and not Quests.known_monster(q.target): broken.append(id)
        if not Maps.definition(q.town).get("safe",false): broken.append(id)
        if q.reward.has("item") and not Catalog.items().has(q.reward.item): broken.append(id)
    t.check(broken.is_empty(),"quests use real monsters, towns and rewards %s" % str(broken.slice(0,3)))
    t.check(Quests.givers("frostmere").size()==1 and Quests.givers("town")[0].x==300.0,"each town has a quest giver clear of the other NPCs")
    var s=H.make("warrior",[],3)
    t.check(Quests.status(s,"town_q1")=="available" and Quests.status(s,"town_q2")=="hidden","the first quest is offered; the next waits for it")
    t.check(Quests.marker(s,"town","Old Tobin")=="!","a yellow ! marks an NPC with a new quest")
    t.check(Quests.accept(s,"town_q1") and not Quests.accept(s,"town_q1"),"accepting a quest works once")
    t.check(Quests.complete(s,"town_q1").is_empty(),"an unfinished quest cannot be handed in")
    for i in 25: Quests.on_kill(s,"mossling")
    t.check(Quests.status(s,"town_q1")=="ready" and Quests.progress(s,"town_q1")==20 and Quests.marker(s,"town","Old Tobin")=="?","kills count up to the goal and mark the quest ready")
    var xp=s.xp
    var level=s.level
    var coins=s.coins
    var reward=Quests.complete(s,"town_q1")
    t.check(not reward.is_empty() and s.coins>coins and (s.xp>xp or s.level>level) and s.consumables.get("hp_1",0)>=10,"completing a quest pays XP, coins and potions")
    t.check(Quests.status(s,"town_q1")=="done" and Quests.status(s,"town_q2")=="available","the chain's next step opens")
    Quests.accept(s,"town_q2")
    var q2=all["town_q2"]
    t.check(Quests.wanted_drop(s,q2.target)==q2.item and Quests.wanted_drop(s,"lantern")=="","collect quests make the right monster drop quest items")
    for i in q2.count: s.collect_reward({"quest_item":q2.item})
    t.check(Quests.wanted_drop(s,q2.target)=="","a full set of quest items stops further drops")
    Quests.complete(s,"town_q2")
    t.check(not s.quest_items.has(q2.item) and s.scrolls.get("scroll_weapon_60",0)==1,"handing in removes the items and gives a scroll")
    var low=H.make("warrior",[],1)
    t.check(Quests.status(low,"frostmere_q1")=="locked","higher-level quests wait for your level")
    t.check(Quests.abandon(s,"town_q3")==false,"only active quests can be abandoned")
    # JSON quests written for the world are cleaned up and checked.
    var cleaned=Quests.clean({"id":"x","town":"frostmere","npc":"Edda","type":"collect","target":"frost_cub","count":5,"intro":"Hello","reward":{"xp":10,"item":"no_such_item","consumable":"hp_2","consumable_count":3}})
    t.check(cleaned.item=="ice_shard" and not cleaned.reward.has("item") and cleaned.reward.count==3 and cleaned.intro==["Hello"],"quests.json entries are cleaned")
    t.check(Quests.clean({"id":"y","town":"frostmere_trail","npc":"Edda","type":"hunt","target":"frost_cub"}).is_empty() and Quests.clean({"id":"z","town":"frostmere","npc":"E","type":"hunt","target":"dragon_god"}).is_empty(),"quests in unsafe maps or with unknown monsters are dropped")
func scroll_checks(t):
    var s=H.make("warrior",["warrior"],30)
    var weapon=s.equipped.weapon
    var attack=s.derived_stats().attack
    var base=s.item_attack(s.instance(weapon))
    s.add_scroll("scroll_weapon_60",10)
    s.add_scroll("scroll_hat_100")
    t.check(s.scroll_problem(weapon,"scroll_hat_100").contains("helm"),"scrolls only fit their gear slot")
    t.check(s.apply_scroll(weapon,"scroll_weapon_60",0.0)=="success" and s.item_attack(s.instance(weapon))==base+3 and s.derived_stats().attack>attack,"a successful scroll adds attack")
    t.check(s.apply_scroll(weapon,"scroll_weapon_60",0.99)=="fail" and s.instance(weapon).failed==1 and s.upgrade_slots(s.instance(weapon))==5,"a failed scroll uses up a slot")
    for i in 5: s.apply_scroll(weapon,"scroll_weapon_60",0.5)
    t.check(s.upgrade_slots(s.instance(weapon))==0 and s.scroll_problem(weapon,"scroll_weapon_60").contains("No upgrade slots"),"items run out of upgrade slots")
    s.add_scroll("scroll_clean")
    t.check(s.apply_scroll(weapon,"scroll_clean",0.0)=="success" and s.upgrade_slots(s.instance(weapon))==1 and s.instance(weapon).failed==0,"Clean Slate restores a failed slot")
    s.add_scroll("scroll_chaos")
    var before=s.instance(weapon).get("bonus",{}).duplicate()
    t.check(s.apply_scroll(weapon,"scroll_chaos",0.0)=="success" and s.instance(weapon).bonus.has("attack") and s.upgrade_slots(s.instance(weapon))==0,"Chaos scrolls reshuffle stats and use a slot")
    var hat=s.add_item_uid("hat_lv30")
    var hp=s.derived_stats().max_hp
    s.equip(hat)
    var worn_hp=s.derived_stats().max_hp
    t.check(s.apply_scroll(hat,"scroll_hat_100")=="success" and s.derived_stats().max_hp==worn_hp+5 and worn_hp>hp,"100% helm scrolls always add defense and HP")
    t.check(Adventure.scrolls().size()==23 and Adventure.scrolls().has(Adventure.random_scroll()),"23 scroll types, all droppable")
    var copy=load("res://systems/character_state.gd").new()
    t.check(copy.load_record(s.to_record()) and copy.item_attack(copy.instance(weapon))==s.item_attack(s.instance(weapon)) and copy.instance(weapon).failed==s.instance(weapon).failed,"scrolled items survive saving")
    var tampered=s.to_record()
    for entry in tampered.inventory:
        if entry.uid==weapon: entry.slots=7
    t.check(not copy.load_record(tampered),"saves with impossible upgrade slots are rejected")
func save_checks(t):
    var s=H.make("thief",["thief"],20)
    s.coins=50000
    t.check(not s.buy_pet("dragon") and s.buy_pet("puppy") and s.pet=="puppy" and s.coins==35000 and not s.buy_pet("puppy"),"pets cost coins and are bought once")
    t.check(s.set_pet("") and s.pet=="" and not s.set_pet("dragon") and s.set_pet("puppy"),"you can switch to pets you own")
    t.check(s.set_looks({"hair":"braid","hair_color":3,"face":"cool","skin":2}) and not s.set_looks({"hair":"afro","hair_color":0,"face":"default","skin":0}) and not s.set_looks({"hair":"braid","hair_color":99,"face":"default","skin":0}),"looks accept only real options")
    s.remember_town("frostmere")
    Quests.accept(s,"town_q1")
    s.quest_items["ice_shard"]=4
    s.add_scroll("scroll_cape_10",2)
    var copy=load("res://systems/character_state.gd").new()
    t.check(copy.load_record(s.to_record()) and copy.town=="frostmere" and copy.pet=="puppy" and copy.looks.hair=="braid" and copy.quests.has("town_q1") and copy.quest_items.ice_shard==4 and copy.scrolls.scroll_cape_10==2,"town, pets, looks, quests and scrolls are saved")
    var old=s.to_record()
    for key in ["town","quests","quest_items","scrolls","looks","pets","pet"]: old.erase(key)
    var fresh=load("res://systems/character_state.gd").new()
    t.check(fresh.load_record(old) and fresh.town=="town" and fresh.pets.is_empty(),"older saves without the new fields still load")
    for bad in [{"pet":"dragon"},{"looks":{"hair":"x"}},{"scrolls":{"scroll_fake":1}},{"quest_items":{"ice_shard":-1}},{"town":"frostmere_trail"}]:
        var record=s.to_record()
        for key in bad: record[key]=bad[key]
        var ok=fresh.load_record(record)
        if bad.has("town"): t.check(ok and fresh.town=="town","an unsafe saved town falls back to Willowbridge")
        else: t.check(not ok,"tampered %s is rejected" % bad.keys()[0])
func game_checks(t):
    var game=load("res://main.tscn").instantiate()
    game.test_mode=true
    t.root.add_child(game)
    await t.process_frame
    t.check(game.hud.minimap.map==game.map and game.hud.skills[0].icon.skill_id==game.state.basic_skill(),"the HUD shows a minimap and skill icons")
    # Climbing.
    game.change_map("forest","entry")
    var p=game.player
    t.check(p.climbs==game.map.climbs and not p.climbs.is_empty(),"the player knows the map's ropes")
    var c=p.climbs[0]
    p.position=Vector2(c[0]+8,c[2])
    t.check(p.climb_at(-1)==c and p.climb_at(1).is_empty(),"you can grab a rope from its foot")
    p.start_climbing(c)
    Input.action_press("interact")
    for i in 200:
        p._physics_process(0.05)
        if not p.climbing: break
    Input.action_release("interact")
    t.check(not p.climbing and absf(p.position.y-c[1])<3 and p.position.x==c[0],"holding Up climbs to the ledge on top")
    t.check(p.climb_at(1)==c,"standing on the ledge you can climb back down")
    p.start_climbing(c)
    Input.action_press("move_down")
    for i in 200:
        p._physics_process(0.05)
        if not p.climbing: break
    Input.action_release("move_down")
    t.check(not p.climbing and absf(p.position.y-c[2])<3,"holding Down climbs back to the ground")
    p.position.y=c[1]
    game.camera.position.y=game.camera_y()
    t.check(game.camera_y()<300,"the camera follows you up tall maps")
    p.start_climbing(c)
    p.apply_knockback(Vector2(100,-50))
    t.check(not p.climbing and p.collision_mask==1,"getting hit knocks you off a rope")
    # Quest kills on a map and the quest giver in town.
    H.reach(game.state,5)
    t.check(Quests.accept(game.state,"town_q1"),"quests can be accepted in game")
    var record=null
    for r in game.map.spawns:
        if r.id=="mossling": record=r
    game.map.on_defeated(record.position,"mossling",record)
    t.check(game.state.quests.town_q1.count==1,"defeating a monster on the map counts for quests")
    game.change_map("frostmere","entry")
    t.check(game.state.town=="frostmere" and game.respawn_map_id=="frostmere","the save remembers the last town")
    game.player.position=Vector2(Quests.givers("frostmere")[0].x,610)
    game.map.interact()
    t.check(game.dialog.opened and t.paused,"pressing Up at a quest giver opens their dialogue")
    game.dialog.close()
    t.check(not game.dialog.opened and not t.paused,"closing the dialogue resumes the game")
    # Pets fetch loot.
    game.state.coins=20000
    game.state.buy_pet("kitten")
    game.refresh_pet()
    t.check(game.pet_node!=null and game.pet_node.pet_id=="kitten","your pet follows you between maps")
    game.change_map("frostmere_trail","entry")
    game.player.position=Vector2(600,610)
    game.pet_node.position=Vector2(560,610)
    game.map.spawn_loot(Vector2(700,610),{"coins":77})
    var coins=game.state.coins
    for i in 60: game.pet_node._process(0.05)
    t.check(game.state.coins==coins+77 and game.map.pickups.is_empty(),"the pet fetches nearby loot")
    # Level-up flash.
    game.state.add_xp(game.state.xp_required(game.state.level))
    t.check(game.get_children().any(func(n): return n.get_script()==preload("res://visuals/level_up_fx.gd")),"levelling up shows a pillar of light")
    # Menus render.
    game.state.add_scroll("scroll_weapon_100",2)
    for panel in ["quests","inventory","characters"]:
        game.menu.open_panel(panel)
        await t.process_frame
    game.change_map("frostmere","entry")
    game.menu.open_panel("shop")
    game.menu.current_panel.open_tab("pets")
    await t.process_frame
    t.check(game.menu.current_panel.get_child_count()>8,"the Merchant sells pets")
    game.menu.close()
    game.queue_free()
    await t.process_frame
