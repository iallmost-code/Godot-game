extends RefCounted
# Casts every active skill of every fourth-job path at full rank against a crowd
# and checks attack skills deal damage, buffs apply and nothing errors.
const H=preload("res://tests/helpers.gd")
const Catalog=preload("res://data/catalog.gd")
func run(t):
    var finals=[]
    for id in Catalog.jobs():
        if Catalog.jobs()[id].tier==4: finals.append(id)
    t.check(finals.size()==10,"ten fourth-job paths exist")
    var silent=["armor_crash","threaten","magic_crash","power_crash","slow_fp","slow_il","seal_fp","seal_il","dispel","doom","disorder","shadow_web","taunt_nl","taunt_sh"]
    for final in finals:
        var chain=[]
        var job=final
        while job!="beginner":
            chain.push_front(job)
            job=Catalog.jobs()[job].parent
        var kind=Catalog.jobs()[final].path
        var s=H.make(kind,chain,200)
        for id in Catalog.skills():
            var skill=Catalog.skill(id)
            if skill.job!="" and s.in_lineage(id):
                s.skill_ranks[id]=skill.max
        s.coins=100000
        var rig=H.rig(t,s)
        var c=rig.combat
        var failures=[]
        for id in Catalog.skills():
            var skill=Catalog.skill(id)
            if skill.job=="" or not s.in_lineage(id) or not skill.active: continue
            var crowd=[]
            for i in range(4): crowd.append(H.mob(rig.world,Vector2(60+i*45,0),999999))
            rig.player.position=Vector2.ZERO
            rig.player.facing=1
            rig.player.stun_time=0
            s.mp=s.derived_stats().max_mp
            s.hp=s.derived_stats().max_hp
            c.active=""
            c.cooldowns.clear()
            if skill.get("needs_combo",false):
                s.apply_buff("combo_attack",60)
                c.combo_orbs=3
            if skill.get("needs_charge",false): s.apply_buff("fire_charge",60)
            if not c.begin_attack(id):
                failures.append(id+" (would not cast)")
            elif skill.kind=="attack":
                var launched=0
                for step in range(24):
                    c.tick(0.05)
                    launched=maxi(launched,t.get_nodes_in_group("player_stars").size())
                for frame in range(20): await t.physics_frame
                var damaged=false
                for m in crowd:
                    # Killing Shot can slay a target outright, which also counts.
                    if not is_instance_valid(m) or m.hp<999999: damaged=true
                var expects_damage=not silent.has(id) and not (skill.get("power",1.0) is float and skill.power==0.0)
                if expects_damage and not damaged: failures.append(id+" (no damage, %d projectiles)" % launched)
                if silent.has(id):
                    var affected=false
                    for m in crowd:
                        if is_instance_valid(m) and not m.statuses.is_empty(): affected=true
                    if not affected: failures.append(id+" (no status)")
            elif skill.kind=="buff" and not skill.get("partner",false) and not s.has_buff(id):
                failures.append(id+" (buff missing)")
            for m in crowd:
                if is_instance_valid(m): m.queue_free()
            for star in t.get_nodes_in_group("player_stars"): star.queue_free()
            await t.process_frame
        t.check(failures.is_empty(),"every %s skill works: %s" % [Catalog.jobs()[final].name,", ".join(failures)])
        c.clear_summons()
        c.clear_partner()
        rig.world.queue_free()
        await t.process_frame
