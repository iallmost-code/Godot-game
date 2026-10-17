extends RefCounted
const H=preload("res://tests/helpers.gd")
func run(t):
    var s=H.make("warrior",["warrior"],10)
    var rig=H.rig(t,s)
    var world=rig.world
    var player=rig.player
    var c=rig.combat
    var enemy=H.mob(world,Vector2(70,0),200)
    if not c.begin_attack("basic"):
        t.check(false,"basic attack starts")
        world.queue_free()
        await t.process_frame
        return
    t.check(enemy.hp == 200,"windup has no immediate damage")
    c.tick(0.12)
    var first_hp = enemy.hp
    t.check(first_hp < 200,"active swing damages enemy in front")
    c.tick(0.03)
    t.check(enemy.hp == first_hp,"same swing never hits enemy twice")
    t.check(not c.begin_attack("basic"),"recovery prevents attack spam")
    c.tick(1)
    t.check(not c.begin_attack("power_strike"),"unlearned skill cannot attack")
    t.check(s.rank_up("power_strike"),"first job skill point learns Heavy Blow")
    var mana = s.mp
    first_hp=enemy.hp
    t.check(c.begin_attack("power_strike"),"learned Heavy Blow starts")
    c.tick(0.12)
    t.check(enemy.hp<first_hp,"Heavy Blow damages the enemy in front")
    t.check(s.mp == mana-4,"cast consumes configured mana")
    t.check(not c.begin_attack("power_strike"),"cooldown prevents an immediate recast")
    c.tick(3)
    enemy.position.x = -60
    first_hp = enemy.hp
    c.begin_attack("basic")
    c.tick(0.12)
    t.check(enemy.hp == first_hp,"attack does not hit behind player")
    player.hurt_timer=0
    var hp = s.hp
    t.check(player.receive_damage(10,Vector2.ZERO),"first incoming hit accepted")
    t.check(not player.receive_damage(10,Vector2.ZERO) and s.hp >= hp-10,"invulnerability blocks overlapping hit")
    c.tick(3)
    s.mp=0
    t.check(not c.begin_attack("power_strike"),"no-mana cast rejected")
    s.mp=500
    # Cleave strikes up to six monsters at rank 1.
    H.learn(s,"slash_blast")
    var cluster=[]
    for i in range(7):
        cluster.append(H.mob(world,Vector2(20+i*20,0),5000))
    c.tick(3)
    c.begin_attack("slash_blast")
    c.tick(0.12)
    var hit=0
    for m in cluster:
        if m.hp<5000: hit+=1
    t.check(hit==6,"Cleave hits exactly six monsters")
    for m in cluster: m.queue_free()
    await t.process_frame
    # Buffs raise derived stats and expire.
    var defense=s.derived_stats().defense
    H.learn(s,"iron_body",5)
    c.tick(3)
    t.check(c.begin_attack("iron_body") and s.derived_stats().defense>defense,"Steel Skin buff raises defense")
    c.tick(500)
    t.check(s.derived_stats().defense==defense and not s.has_buff("iron_body"),"buff expires and its bonus ends")
    c.tick(3)
    enemy.position=Vector2(60,0)
    enemy.hp=200
    c.begin_attack("basic")
    c.tick(0.4)
    t.check(enemy.hp<200,"large frame delta does not skip attack hit window")
    c.tick(3)
    enemy.position=Vector2(70,0)
    enemy.hp=200
    var behind=H.mob(world,Vector2(-70,0),200)
    player.position=Vector2.ZERO
    player.facing=1
    c.begin_attack("basic")
    player.facing=-1
    player.position=Vector2(-20,0)
    c.tick(0.12)
    t.check(enemy.hp<200 and behind.hp==200,"turning during windup keeps damage on the displayed attack side")
    world.queue_free()
    await t.process_frame
    # Status effects: stun stops movement and attacks; poison cannot kill; armor break raises damage.
    var mage=H.make("magician",["magician","il_wizard","il_mage"],70)
    rig=H.rig(t,mage)
    var target=H.mob(rig.world,Vector2(120,0),9999)
    target.apply_status("stun",2.0)
    t.check(target.immobile() and not target.can_attack(),"stunned monsters cannot move or attack")
    target.apply_status("poison",3.0,50000)
    target.tick_statuses(1.1)
    t.check(target.hp==1,"poison damages but never kills")
    target.hp=9999
    target.apply_status("armor_break",5.0)
    t.check(target.damage_taken_multiplier()>1.0,"armor break makes monsters take more damage")
    H.learn(mage,"ice_strike")
    mage.mp=999
    target.statuses.clear()
    rig.combat.begin_attack("ice_strike")
    rig.combat.tick(0.12)
    t.check(target.hp<9999,"Glacial Spike hits monsters around the caster")
    var boss=load("res://actors/boss.gd").new()
    boss.definition_id="mother_cap"
    boss.position=Vector2(-200,0)
    rig.world.add_child(boss)
    boss.set_physics_process(false)
    boss.apply_status("stun",3.0)
    boss.apply_status("poison",3.0)
    t.check(not boss.has_status("stun") and boss.has_status("poison"),"bosses resist stun but not poison")
    rig.world.queue_free()
    await t.process_frame
