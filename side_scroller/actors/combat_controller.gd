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
    active=id
    elapsed=0
    struck.clear()
    volleys_fired=0
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
    for angle in angles:
        var star=preload("res://world/player_star.gd").new()
        star.direction=Vector2(attack_facing,0).rotated(angle)
        star.max_distance=attack_reach
        var rank=state.skill_ranks.get(id,1)
        star.critical=randf()<state.derived_stats().crit
        star.damage=int(state.derived_stats().attack*(skill.power+maxi(0,rank-1)*0.15)*(1.5 if star.critical else 1.0))
        star.hit.connect(func(pos,amount,critical): impact.emit(pos,amount,critical))
        player.get_parent().add_child(star)
        # Trace from the body, so even a thin wall before the hand blocks the throw.
        star.global_position=attack_origin+Vector2(0,-25)
func tick(delta):
    for id in cooldowns: cooldowns[id]=maxf(0,cooldowns[id]-delta)
    if active == "": return
    var previous_elapsed=elapsed
    elapsed+=delta
    var active_skill=Catalog.skills()[active]
    if active_skill.get("projectile",false):
        var desired=2 if active=="twin_stars" else 1
        while volleys_fired<desired and elapsed>=0.08+volleys_fired*0.09:
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
