extends Node
const Catalog = preload("res://data/catalog.gd")
var player
var state
var cooldowns = {}
var active = ""
var elapsed = 0.0
var struck: Array = []
var sequence = 0
var combo = 0
var attack_origin=Vector2.ZERO
var attack_facing=1
var attack_reach=0.0
var attack_targets=0
var volleys_fired=0
var attack_star_count=1
var partner_time=0.0
var partner: Node2D
func clear_partner():
    partner_time=0
    if is_instance_valid(partner): partner.queue_free()
    partner=null
func summon_partner():
    clear_partner()
    partner_time=60.0
    partner=preload("res://visuals/character_visual.gd").new()
    partner.appearance="thief"
    partner.modulate=Color(0.46,0.26,0.75,0.58)
    partner.z_index=4
    player.get_parent().add_child(partner)
    partner.global_position=player.global_position-Vector2(player.facing*45,0)
func update_partner(delta):
    if partner_time<=0: return
    partner_time=maxf(0,partner_time-delta)
    if partner_time<=0 or state.hp<=0 or not state.can_use("shadow_partner"):
        clear_partner()
        return
    if not is_instance_valid(partner):
        partner_time=0
        return
    var direction=attack_facing if active!="" else player.facing
    var target=player.global_position-Vector2(direction*45,0)
    if partner.global_position.distance_to(target)>180: partner.global_position=target
    else: partner.global_position=partner.global_position.lerp(target,minf(1,delta*14))
    partner.walk_phase=player.visual.walk_phase
    partner.attack_style=active if active!="" else "star"
    partner.set_pose("attack" if active!="" else player.visual.pose,direction,Time.get_ticks_msec()/1000.0)
signal attack_started(skill_id: String,origin: Vector2,direction: int,reach: float)
signal impact(position: Vector2, damage: int, critical: bool)
signal feedback(message: String)
func setup(p,s):
    player=p
    state=s
    p.combat=self
func _process(delta): tick(delta)
func begin_attack(id: String) -> bool:
    if id == "":
        feedback.emit("No skill assigned. Open Skills to equip one.")
        return false
    if active != "" or state.hp <= 0: return false
    if not state.can_use(id): return false
    var skill = Catalog.skills()[id]
    if cooldowns.get(id,0.0) > 0:
        if id != "basic": feedback.emit("%s is recharging." % skill.name)
        return false
    if state.mp < skill.mana:
        feedback.emit("Not enough mana. It recovers over time.")
        return false
    state.mp -= skill.mana
    state.changed.emit()
    if id=="shadow_partner":
        cooldowns[id]=skill.cooldown
        summon_partner()
        feedback.emit("Shadow Partner summoned for 60 seconds!")
        return true
    active=id
    elapsed=0
    struck.clear()
    volleys_fired=0
    attack_star_count=state.basic_star_count() if id=="star" else 1
    sequence+=1
    combo = (combo+1)%2
    cooldowns[id]=skill.cooldown
    player.attack_timer=0.30
    var rank=state.skill_ranks.get(id,1)
    attack_origin=player.global_position
    attack_facing=player.facing
    attack_reach=skill.reach+(40*int((rank-1)/2.0) if id=="wave" else 0)
    attack_targets=skill.targets+(int((rank-1)/2.0) if id=="wave" else 0)
    if id=="thrust": player.start_lunge(attack_facing)
    attack_started.emit(id,attack_origin,attack_facing,attack_reach)
    return true
func cancel():
    active=""
    struck.clear()
    player.lunge_time=0
func launch_stars(id: String):
    var skill=Catalog.skills()[id]
    var angles=[-0.17,0.0,0.17] if id=="star_fan" else [0.0]
    var origins=[attack_origin]
    if partner_time>0 and is_instance_valid(partner): origins.append(partner.global_position)
    for origin in origins:
        for angle in angles:
            var star=preload("res://world/player_star.gd").new()
            star.direction=Vector2(attack_facing,0).rotated(angle)
            star.max_distance=attack_reach
            var rank=state.skill_ranks.get(id,1)
            star.critical=randf()<state.derived_stats().crit
            star.damage=int(state.derived_stats().attack*(skill.power+maxi(0,rank-1)*0.15)*(1.5 if star.critical else 1.0))
            star.hit.connect(func(pos,amount,critical): impact.emit(pos,amount,critical))
            player.get_parent().add_child(star)
            star.global_position=origin+Vector2(0,-25)
            if origin!=attack_origin: star.modulate=Color("b4a4eb")
func tick(delta):
    update_partner(delta)
    for id in cooldowns: cooldowns[id]=maxf(0,cooldowns[id]-delta)
    if active == "": return
    var previous_elapsed=elapsed
    elapsed+=delta
    var active_skill=Catalog.skills()[active]
    if active_skill.get("projectile",false):
        var desired=attack_star_count if active=="star" else 1
        while volleys_fired<desired and elapsed>=0.08+volleys_fired*0.06:
            launch_stars(active)
            volleys_fired+=1
        if elapsed>=0.32: active=""
        return
    if elapsed >= 0.08 and previous_elapsed <= 0.27:
        var skill=Catalog.skills()[active]
        var rank=state.skill_ranks.get(active,1)
        var reach=attack_reach
        var cap=attack_targets
        var targets: Array = []
        for e in get_tree().get_nodes_in_group("enemies"):
            var offset=e.global_position-attack_origin
            if e.hp>0 and absf(offset.y)<70 and offset.x*attack_facing>=-12 and absf(offset.x)<reach:
                targets.append(e)
        targets.sort_custom(func(a,b): return absf(a.global_position.x-attack_origin.x)<absf(b.global_position.x-attack_origin.x))
        for e in targets:
            if struck.size() >= cap: break
            if struck.has(e.get_instance_id()): continue
            struck.append(e.get_instance_id())
            var critical=randf()<state.derived_stats().crit
            var damage=int(state.derived_stats().attack*(skill.power+maxi(0,rank-1)*0.15)*(1.5 if critical else 1.0))
            var push=Vector2(attack_facing*260,-70) if active=="thrust" else Vector2.ZERO
            if e.receive_hit(damage,push,int(get_instance_id())+sequence):
                impact.emit(e.global_position+Vector2(0,-45),damage,critical)
    if elapsed>=0.32: active=""
