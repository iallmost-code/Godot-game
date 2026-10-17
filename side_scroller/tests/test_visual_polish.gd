extends RefCounted
func run(t):
    var visual=load("res://visuals/character_visual.gd").new()
    t.root.add_child(visual)
    t.check(visual.has_method("set_attack_clock"),"character animation accepts the real combat clock")
    if not visual.has_method("set_attack_clock"):
        visual.queue_free()
        await t.process_frame
        return
    for entry in [["mage","mage_body.png"],["archer","archer_body.png"]]:
        visual.appearance=entry[0]
        visual.set_pose("idle",1,0)
        t.check(visual.sprite.texture.resource_path.ends_with(entry[1]),"class uses dedicated art: "+entry[0])
    visual.appearance="spear"
    visual.set_equipment("job_spear")
    visual.attack_style="spear_crusher"
    var frames={}
    for elapsed in [0.02,0.12,0.27,0.38]:
        visual.set_attack_clock(elapsed,0.4,0.08)
        visual.set_pose("attack",1,elapsed)
        frames[visual.current_frame]=true
    t.check(frames.size()==4,"one attack has distinct windup, strike, follow-through and recovery")
    visual.set_attack_clock(0.02,0.4,0.08)
    visual.set_pose("attack",1,10)
    t.check(visual.current_frame==10,"consecutive held attacks restart their visual windup")
    visual.appearance="thief"
    t.check(visual.set_equipment("forest_dagger") and visual.weapon_kind=="dagger","dagger equipment changes the visible weapon instead of showing a claw")
    visual.appearance="archer"
    t.check(visual.set_equipment("forest_crossbow") and visual.weapon_kind=="crossbow","crossbow equipment changes the visible weapon instead of showing a bow")
    t.check(not visual.set_equipment("not_an_item") and visual.weapon_kind=="crossbow","invalid visual equipment preserves the current weapon")
    visual.set_attack_clock(0.12,0.4,0.08)
    visual.set_pose("attack",1,0.12)
    var right=visual.weapon_mount.position
    visual.set_pose("attack",-1,0.12)
    t.check(is_equal_approx(visual.weapon_mount.position.x,-right.x) and is_equal_approx(visual.weapon_mount.position.y,right.y),"weapon grip mirrors around the same stable body anchor")
    visual.queue_free()
    await t.process_frame
    var fx=load("res://visuals/combat_effects.gd").new()
    t.root.add_child(fx)
    fx.show_attack("basic",Vector2.ZERO,1,110,0.1)
    t.check(fx.effects.size()==1 and fx.effects[0].age<0,"melee slash waits for attack windup rather than appearing before impact")
    fx._process(0.11)
    t.check(fx.effects[0].age>=0,"melee slash appears when the active hit phase starts")
    fx.show_effect("element",{"position":Vector2.ZERO,"facing":1,"reach":200,"element":"fire","shape":"area","both":false,"delay":0.12})
    t.check(fx.shapes.size()==1 and fx.shapes[0].age<0,"spell bursts wait for their own combat windup")
    fx._process(0.13)
    t.check(fx.shapes[0].age>=0,"spell burst becomes visible at the active phase")
    fx.queue_free()
    await t.process_frame
    var state=preload("res://tests/helpers.gd").make("thief")
    var rig=preload("res://tests/helpers.gd").rig(t,state)
    rig.player.movement_enabled=false
    rig.player.attack_timer=0
    rig.combat.active="star"
    rig.combat.elapsed=0.35
    rig.combat.swing_end=0.6
    rig.combat.windup=0.08
    rig.player._physics_process(0.016)
    t.check(rig.player.visual.pose=="attack" and is_equal_approx(rig.player.visual.attack_elapsed,0.35),"long projectile volleys stay animated after the legacy attack timer expires")
    rig.combat.active=""
    rig.player._physics_process(0.016)
    t.check(rig.player.visual.pose!="attack" and rig.player.visual.attack_elapsed<0,"finishing a volley releases the attack pose and clock")
    rig.world.queue_free()
    await t.process_frame
