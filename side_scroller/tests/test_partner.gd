extends RefCounted
const H=preload("res://tests/helpers.gd")
func run(t):
    var s=H.make("thief",["thief","assassin","hermit"],70)
    t.check(not s.skill_belongs("twin_stars") and not s.skill_belongs("star_fan"),"retired custom skills are gone")
    H.learn(s,"shadow_partner_hermit")
    s.mp=999
    var rig=H.rig(t,s)
    var c=rig.combat
    t.check(c.begin_attack("shadow_partner_hermit"),"Shadow Twin activates")
    t.check(c.partner_time==60 and is_instance_valid(c.partner),"rank-one Shadow Twin lasts sixty seconds")
    c.tick(0.4)
    c.begin_attack("star")
    c.tick(0.4)
    var stars=t.get_nodes_in_group("player_stars")
    t.check(stars.size()==2,"shadow mirrors the basic star")
    var mirrored=0
    for star in stars:
        if star.scale_factor==0.5: mirrored+=1
    t.check(mirrored==1,"mirrored star deals half damage")
    for star in stars: star.queue_free()
    await t.process_frame
    var duration=c.partner_time
    var mana=s.mp
    t.check(not c.begin_attack("shadow_partner_hermit") and c.partner_time==duration and s.mp==mana,"summon cannot stack or refresh during cooldown")
    c.set_process(true)
    t.paused=true
    await t.create_timer(0.05,true).timeout
    t.check(c.partner_time==duration,"paused menu time does not consume summon duration")
    t.paused=false
    c.set_process(false)
    c.tick(59.3)
    t.check(c.partner_time==0 and not is_instance_valid(c.partner),"Shadow Twin expires on time")
    c.tick(1)
    c.begin_attack("star")
    c.tick(0.4)
    t.check(t.get_nodes_in_group("player_stars").size()==1,"basic attack returns to one star after expiration")
    for star in t.get_nodes_in_group("player_stars"): star.queue_free()
    await t.process_frame
    c.tick(2)
    H.reach(s,120)
    s.advance_job("night_lord")
    H.learn(s,"triple_throw")
    c.begin_attack("shadow_partner_hermit")
    c.tick(0.2)
    c.begin_attack("triple_throw")
    c.tick(0.4)
    t.check(t.get_nodes_in_group("player_stars").size()==6,"Triple Toss plus Shadow Twin throws six stars")
    for star in t.get_nodes_in_group("player_stars"): star.queue_free()
    await t.process_frame
    s.job="assassin"
    c.tick(0.01)
    t.check(c.partner_time==0,"losing the job ends the shadow")
    c.clear_partner()
    t.check(c.partner_time==0 and c.partner==null,"clearing summon removes its effect")
    # Summoned creatures attack on their own.
    var priest=H.make("magician",["magician","cleric","priest"],80)
    H.learn(priest,"summon_dragon")
    priest.mp=999
    var rig2=H.rig(t,priest)
    var target=H.mob(rig2.world,Vector2(120,0),99999)
    t.check(rig2.combat.begin_attack("summon_dragon") and rig2.combat.summons.has("summon_dragon"),"Light Drake is summoned")
    var drake=rig2.combat.summons.summon_dragon
    drake._process(1.0)
    drake._process(2.1)
    t.check(target.hp<99999,"summoned drake attacks nearby monsters")
    rig2.combat.clear_summons()
    rig.world.queue_free()
    rig2.world.queue_free()
    await t.process_frame
