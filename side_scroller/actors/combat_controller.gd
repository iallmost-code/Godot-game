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
signal attack_started(skill_id: String)
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
    sequence+=1
    combo = (combo+1)%2
    cooldowns[id]=skill.cooldown
    player.attack_timer=0.30
    attack_started.emit(id)
    return true
func cancel():
    active=""
    struck.clear()
func tick(delta):
    for id in cooldowns: cooldowns[id]=maxf(0,cooldowns[id]-delta)
    if active == "": return
    elapsed+=delta
    if elapsed >= 0.08 and elapsed <= 0.27:
        var skill=Catalog.skills()[active]
        var rank=state.skill_ranks.get(active,1)
        var reach=skill.reach + (40*int(rank/2.0) if active=="wave" else 0)
        var cap=skill.targets+(int(rank/2.0) if active=="wave" else 0)
        var targets: Array = []
        for e in get_tree().get_nodes_in_group("enemies"):
            var offset=e.global_position-player.global_position
            if e.hp>0 and absf(offset.y)<70 and offset.x*player.facing>=-12 and absf(offset.x)<reach:
                targets.append(e)
        targets.sort_custom(func(a,b): return absf(a.global_position.x-player.global_position.x)<absf(b.global_position.x-player.global_position.x))
        for e in targets:
            if struck.size() >= cap: break
            if struck.has(e.get_instance_id()): continue
            struck.append(e.get_instance_id())
            var critical=randf()<state.derived_stats().crit
            var damage=int(state.derived_stats().attack*(skill.power+maxi(0,rank-1)*0.15)*(1.5 if critical else 1.0))
            var push=Vector2(player.facing*260,-70) if active=="thrust" else Vector2.ZERO
            if e.receive_hit(damage,push,int(get_instance_id())+sequence):
                impact.emit(e.global_position+Vector2(0,-45),damage,critical)
    if elapsed>=0.32: active=""
