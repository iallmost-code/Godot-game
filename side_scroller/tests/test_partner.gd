extends RefCounted
func run(t):
    var s=load("res://systems/character_state.gd").new()
    s.initialize_class("thief")
    t.check(not s.skill_belongs("twin_stars"),"redundant Twin Stars is removed")
    t.check(s.has_method("basic_star_count"),"thief basic stars scale with job")
    if not s.has_method("basic_star_count"): return
    for job in ["thief","assassin","hermit","night_lord"]:
        var required={"thief":10,"assassin":30,"hermit":60,"night_lord":100}[job]
        while s.level<required: s.add_xp(s.xp_required(s.level))
        if job=="hermit": s.assign_skill("c","star_fan")
        t.check(s.advance_job(job),"thief advancement works: "+job)
        if job=="hermit": t.check(s.slots.c=="shadow_partner" and [s.slots.z,s.slots.x].has("star_fan"),"new summon keeps an existing C-slot attack assigned elsewhere")
        t.check(s.basic_star_count()==s.tier(),"basic stars match job count: "+job)
    var points=s.ap
    s.add_xp(999999)
    t.check(s.level==100 and s.ap==points and s.xp==0,"level cap cannot award extra levels or points")
    t.check(s.can_use("shadow_partner"),"third-job summon remains available at fourth job")
    var saved=load("res://systems/character_state.gd").new()
    t.check(saved.load_record(s.to_record()) and saved.basic_star_count()==4,"fourth-job save round trip")
    s.job="hermit"
    t.check(saved.allocate_attributes({"LUK":495}) and saved.load_record(saved.to_record()),"level-100 attribute allocation survives save validation")
    var legacy=load("res://systems/character_state.gd").new()
    legacy.initialize_class("thief")
    while legacy.level<10: legacy.add_xp(legacy.xp_required(legacy.level))
    legacy.advance_job("thief")
    legacy.add_xp(legacy.xp_required(legacy.level))
    legacy.rank_up("star_fan")
    var old=legacy.to_record()
    old.skill_ranks.twin_stars=3
    old.sp["1"]-=2
    old.slots.z="twin_stars"
    old.sp.erase("3")
    old.sp.erase("4")
    old.sp_earned.erase("3")
    old.sp_earned.erase("4")
    t.check(saved.load_record(old) and saved.sp["1"]==3 and saved.slots.z=="" and saved.skill_ranks.star_fan==2,"old Twin Stars ranks refund points while preserving other skills")
    var earned=saved.sp["1"]
    t.check(saved.load_record(saved.to_record()) and saved.sp["1"]==earned,"migrated saves do not refund points a second time")
    old.skill_ranks.twin_stars=99
    t.check(not saved.load_record(old),"invalid retired skill rank still rejects")
    var world=Node2D.new()
    t.root.add_child(world)
    var p=load("res://actors/player.gd").new()
    p.state=s
    world.add_child(p)
    p.set_physics_process(false)
    var c=load("res://actors/combat_controller.gd").new()
    world.add_child(c)
    c.setup(p,s)
    c.set_process(false)
    t.check(c.begin_attack("shadow_partner"),"summon activates from assigned ability")
    t.check(c.partner_time==60 and is_instance_valid(c.partner),"partner exists for sixty seconds")
    c.tick(0.4)
    c.begin_attack("star")
    c.tick(0.4)
    t.check(t.get_nodes_in_group("player_stars").size()==6,"third-job basic plus partner launches six stars")
    for star in t.get_nodes_in_group("player_stars"): star.queue_free()
    await t.process_frame
    var duration=c.partner_time
    var mana=s.mp
    t.check(not c.begin_attack("shadow_partner") and c.partner_time==duration and s.mp==mana,"summon cannot stack or refresh during cooldown")
    c.set_process(true)
    t.paused=true
    await t.create_timer(0.05,true).timeout
    t.check(c.partner_time==duration,"paused menu time does not consume summon duration")
    t.paused=false
    c.set_process(false)
    c.tick(59.3)
    t.check(c.partner_time==0 and not is_instance_valid(c.partner),"summon expires after sixty seconds")
    c.tick(1)
    c.begin_attack("star")
    c.tick(0.4)
    t.check(t.get_nodes_in_group("player_stars").size()==3,"basic attack returns to three stars after expiration")
    for star in t.get_nodes_in_group("player_stars"): star.queue_free()
    await t.process_frame
    c.tick(1)
    s.job="night_lord"
    c.begin_attack("shadow_partner")
    c.begin_attack("star")
    c.tick(0.4)
    t.check(t.get_nodes_in_group("player_stars").size()==8,"fourth-job basic plus partner throws eight stars")
    for star in t.get_nodes_in_group("player_stars"): star.queue_free()
    await t.process_frame
    c.tick(2)
    c.begin_attack("star_fan")
    c.tick(0.2)
    t.check(t.get_nodes_in_group("player_stars").size()==6,"partner mirrors the three-star fan skill too")
    s.job="thief"
    c.tick(0.01)
    t.check(c.partner_time==0,"loading a lower job cannot retain an unavailable summon")
    c.clear_partner()
    t.check(c.partner_time==0 and c.partner==null,"clearing summon removes its effect")
    world.queue_free()
    await t.process_frame
