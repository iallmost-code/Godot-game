extends Node
const Catalog = preload("res://data/catalog.gd")
const BASE_WINDUP=0.08
const BASE_SWING=0.24
var player
var state
var cooldowns = {}
var active = ""
var active_rank = 1
var elapsed = 0.0
var swing_end = 0.32
var windup = BASE_WINDUP
var struck: Array = []
var sequence = 0
var combo = 0
var attack_origin=Vector2.ZERO
var attack_facing=1
var attack_reach=0.0
var attack_targets=0
var volleys_fired=0
var attack_star_count=1
var hidden_strike=false
var partner_time=0.0
var partner_skill=""
var partner: Node2D
var combo_orbs=0
var summons={}
var source_counter=0
signal attack_started(skill_id: String,origin: Vector2,direction: int,reach: float)
signal impact(position: Vector2, damage: int, critical: bool)
signal feedback(message: String)
signal effect_requested(kind: String, data: Dictionary)
signal loot_requested(position: Vector2, reward: Dictionary)
signal door_requested
func setup(p,s):
    player=p
    state=s
    p.combat=self
func _process(delta): tick(delta)
func new_source() -> int:
    source_counter+=1
    return int(get_instance_id())*64+source_counter
func skill_value(id: String,key: String,fallback=0.0) -> float:
    var skill=Catalog.skill(id)
    if not skill.has(key): return fallback
    return Catalog.value(skill[key],state.skill_rank(id),skill.max)
# ---------------- Shadow partner ----------------
func clear_partner():
    partner_time=0
    partner_skill=""
    if is_instance_valid(partner): partner.queue_free()
    partner=null
func summon_partner(id: String="",duration: float=60.0):
    clear_partner()
    partner_time=duration
    partner_skill=id
    partner=preload("res://visuals/character_visual.gd").new()
    partner.appearance="thief"
    partner.modulate=Color(0.46,0.26,0.75,0.58)
    partner.z_index=4
    player.get_parent().add_child(partner)
    partner.global_position=player.global_position-Vector2(player.facing*45,0)
func partner_active() -> bool: return partner_time>0 and is_instance_valid(partner)
func update_partner(delta):
    if partner_time<=0: return
    partner_time=maxf(0,partner_time-delta)
    if partner_time<=0 or state.hp<=0 or partner_skill!="" and not state.can_use(partner_skill):
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
    partner.appearance=player.visual.appearance
    partner.attack_style=active if active!="" else "star"
    partner.set_pose("attack" if active!="" else player.visual.pose,direction,Time.get_ticks_msec()/1000.0)
# ---------------- Summons ----------------
func clear_summons():
    for id in summons.keys():
        if is_instance_valid(summons[id]): summons[id].queue_free()
    summons.clear()
func spawn_summon(id: String):
    var skill=Catalog.skill(id)
    if summons.has(id) and is_instance_valid(summons[id]): summons[id].queue_free()
    var creature=preload("res://world/summon.gd").new()
    creature.skill_id=id
    creature.combat=self
    creature.player=player
    creature.config=skill.summon
    creature.rank=state.skill_rank(id)
    creature.max_rank=skill.max
    creature.lifetime=skill_value(id,"duration",60.0)
    player.get_parent().add_child(creature)
    creature.global_position=player.global_position+Vector2(-player.facing*50,-70 if skill.summon.get("follow",true) else 0)
    if not skill.summon.get("follow",true): creature.global_position=player.global_position+Vector2(player.facing*70,0)
    summons[id]=creature
# ---------------- Casting ----------------
func mana_cost(id: String) -> int:
    var cost=skill_value(id,"mana")
    var modifier=state.bonus("mp_cost_pct")
    return maxi(0,int(round(cost*maxf(0.0,1.0+modifier))))
func begin_attack(id: String) -> bool:
    if id == "":
        feedback.emit("No skill assigned. Open Skills to equip one.")
        return false
    if state.hp <= 0: return false
    var skill=Catalog.skill(id)
    if skill.is_empty(): return false
    if player!=null and player.stun_time>0 and skill.get("effect","")!="cure": return false
    if active != "" and skill.kind=="attack": return false
    if not state.can_use(id): return false
    if cooldowns.get(id,0.0) > 0:
        if skill.job!="": feedback.emit("%s is recharging." % state.skill_name(id))
        return false
    var cost=mana_cost(id)
    if state.mp < cost:
        feedback.emit("Not enough MP. It recovers over time.")
        return false
    var hp_cost=skill_value(id,"hp_cost")*state.derived_stats().max_hp
    if hp_cost>0 and state.hp<=hp_cost+1:
        feedback.emit("Not enough HP for %s." % state.skill_name(id))
        return false
    var coin_cost=int(skill_value(id,"coin_cost"))
    if coin_cost>state.coins:
        feedback.emit("%s needs %d coins." % [state.skill_name(id),coin_cost])
        return false
    if skill.get("needs_combo",false) and (state.buff_group("combo")=="" or combo_orbs<=0):
        feedback.emit("Build combo orbs first with Momentum active.")
        return false
    if skill.get("needs_charge",false) and state.buff_group("charge")=="":
        feedback.emit("Brand your weapon with an elemental charge first.")
        return false
    state.mp -= cost
    state.hp -= hp_cost
    state.coins -= coin_cost
    var cooldown=skill_value(id,"cooldown")
    var speed=state.derived_stats().attack_speed
    if skill.kind=="attack" and cooldown<2.0: cooldown*=1.0-speed
    cooldowns[id]=cooldown
    var rank=state.skill_rank(id)
    match skill.kind:
        "buff":
            var duration=skill_value(id,"duration",60.0)
            if skill.get("partner",false):
                summon_partner(id,duration)
                feedback.emit("%s summoned for %d seconds!" % [state.skill_name(id),int(duration)])
            else:
                if skill.get("needs_combo",false): combo_orbs=0
                if skill.get("group","")=="combo" and state.buff_group("combo")=="": combo_orbs=0
                state.apply_buff(id,duration)
                feedback.emit("%s active for %d seconds." % [state.skill_name(id),int(duration)])
            effect_requested.emit("aura",{"position":player.global_position,"element":skill.get("element",""),"skill":id})
            state.changed.emit()
            return true
        "summon":
            spawn_summon(id)
            feedback.emit("%s summoned!" % state.skill_name(id))
            state.changed.emit()
            return true
        "move":
            if skill.get("effect","")=="door":
                door_requested.emit()
            else:
                player.teleport(attack_facing_now()*skill_value(id,"distance",150))
                effect_requested.emit("aura",{"position":player.global_position,"element":"arcane","skill":id})
            state.changed.emit()
            return true
        "special":
            cure()
            effect_requested.emit("aura",{"position":player.global_position,"element":"holy","skill":id})
            feedback.emit("%s: you shake off every hindrance." % state.skill_name(id))
            state.changed.emit()
            return true
        "heal":
            var amount=skill_value(id,"heal")*state.derived_stats().max_hp
            state.hp=minf(state.derived_stats().max_hp,state.hp+amount)
            effect_requested.emit("heal",{"position":player.global_position,"amount":int(amount)})
            if skill_value(id,"power")>0:
                for e in targets_for(id,player.global_position,player.facing,skill.reach,skill.get("height",90),true,int(skill_value(id,"targets",6))):
                    apply_hit(e,id,rank)
            state.changed.emit()
            return true
    # Attack skills.
    hidden_strike=state.has_buff("dark_sight")
    if hidden_strike: state.remove_buff("dark_sight")
    active=id
    active_rank=rank
    elapsed=0
    struck.clear()
    volleys_fired=0
    attack_star_count=int(skill_value(id,"count",1))
    sequence+=1
    combo = (combo+1)%2
    windup=(BASE_WINDUP+skill.get("windup",0.0))*(1.0-speed*0.5)
    swing_end=windup+BASE_SWING*(1.0-speed*0.5)
    if skill.shape=="projectile":
        swing_end=maxf(swing_end,windup+attack_star_count*skill.get("volley_delay",0.06)+0.05)
    player.attack_timer=0.30
    attack_origin=player.global_position
    attack_facing=player.facing
    attack_reach=skill.reach+(state.derived_stats().reach if skill.shape=="projectile" else 0.0)
    attack_targets=int(skill_value(id,"targets",1))
    if skill.shape=="lunge":
        var duration=skill_value(id,"lunge",0.3)
        player.start_lunge(attack_facing,duration,700.0)
        swing_end=duration+0.08
    if skill.shape=="pull": pull_monsters(id)
    attack_started.emit(id,attack_origin,attack_facing,attack_reach)
    if skill.get("element","")!="" and skill.shape in ["area","drop","chain"]:
        effect_requested.emit("element",{"position":attack_origin,"facing":attack_facing,"reach":attack_reach,"element":skill.element,"shape":skill.shape,"both":skill.get("both",false)})
    return true
func attack_facing_now() -> int: return player.facing
func cancel():
    active=""
    struck.clear()
    player.lunge_time=0
func cure():
    if player!=null:
        player.stun_time=0
        player.status_immunity=3.0
# ---------------- Targeting ----------------
func targets_for(id: String,origin: Vector2,facing: int,reach: float,height: float,both: bool,cap: int) -> Array:
    var found: Array=[]
    for e in get_tree().get_nodes_in_group("enemies"):
        if e.hp<=0: continue
        var offset=e.global_position-origin
        if absf(offset.y)>=height: continue
        if not both and offset.x*facing<-12: continue
        if absf(offset.x)<reach: found.append(e)
    found.sort_custom(func(a,b): return absf(a.global_position.x-origin.x)<absf(b.global_position.x-origin.x))
    return found.slice(0,cap)
func pull_monsters(id: String):
    var skill=Catalog.skill(id)
    for e in targets_for(id,attack_origin,attack_facing,skill.reach,90,false,attack_targets):
        if not e.is_heavy: e.global_position.x=attack_origin.x+attack_facing*(50+randf()*30)
# ---------------- Damage ----------------
func roll_damage(id: String,rank: int,enemy=null,scale: float=1.0) -> Array:
    var stats=state.derived_stats()
    var skill=Catalog.skill(id)
    var power=Catalog.value(skill.get("power",1.0),rank,skill.max)*scale
    if id=="basic" and state.weapon_type()=="staff": power*=0.6
    var multiplier=1.0+stats.damage_pct
    if state.buff_group("combo")!="": multiplier+=combo_orbs*state.bonus("orb_bonus")
    if state.buff_group("charge")!="" and skill.shape in ["melee","lunge"]: multiplier+=state.bonus("charge_bonus")
    if state.hp<stats.max_hp*0.4: multiplier+=state.bonus("berserk")
    if hidden_strike and id=="assassinate": multiplier*=1.5
    if skill.get("needs_combo",false): multiplier*=1.0+0.08*combo_orbs
    var critical=randf()<stats.crit
    var amount=stats.attack*power*multiplier*randf_range(stats.mastery_min,1.0)*((1.0+stats.crit_damage) if critical else 1.0)
    if enemy!=null and enemy.has_method("damage_taken_multiplier"): amount*=enemy.damage_taken_multiplier()
    return [maxi(1,int(amount)),critical]
func status_for(id: String) -> Dictionary:
    var skill=Catalog.skill(id)
    if not skill.has("status"): return {}
    var rank=state.skill_rank(id)
    return {"id":skill.status.id,"chance":Catalog.value(skill.status.chance,rank,skill.max),"time":Catalog.value(skill.status.time,rank,skill.max)}
# Resolve every damage line one skill deals to one enemy, plus all on-hit effects.
func apply_hit(e,id: String,rank: int,scale: float=1.0,origin=null) -> int:
    if not is_instance_valid(e) or e.hp<=0: return 0
    var skill=Catalog.skill(id)
    var stats=state.derived_stats()
    var total=0
    var lines=int(skill_value(id,"hits",1))
    var push=Vector2(attack_facing*skill.get("push",0),-70 if skill.get("push",0)>0 else 0)
    if id in ["star","arrow"] and state.bonus("knockback")>0: push=Vector2(attack_facing*state.bonus("knockback"),-40)
    var power=skill_value(id,"power",1.0)
    for line in range(lines):
        if not is_instance_valid(e) or e.hp<=0 or power<=0.0: break
        var roll=roll_damage(id,rank,e,scale)
        if e.receive_hit(roll[0],push if line==0 else Vector2.ZERO,new_source()):
            total+=roll[0]
            impact.emit(e.global_position+Vector2(0,-45),roll[0],roll[1])
    if not is_instance_valid(e): return total
    # Point-blank instant kill.
    if id=="arrow" and not e.is_heavy and e.hp>0 and absf(e.global_position.x-player.global_position.x)<150 and randf()<state.bonus("mortal"):
        var rest=e.hp
        if e.receive_hit(rest,Vector2.ZERO,new_source()):
            total+=rest
            impact.emit(e.global_position+Vector2(0,-45),rest,true)
    var effects=[]
    var own=status_for(id)
    if not own.is_empty(): effects.append(own)
    if power>0.0: effects.append_array(state.on_hit_effects())
    for status in effects:
        if is_instance_valid(e) and e.hp>0 and randf()<status.chance:
            e.apply_status(status.id,status.time,maxi(1,int(stats.attack*0.25)))
    if total>0:
        var drain=skill_value(id,"drain")
        if drain>0: state.hp=minf(stats.max_hp,state.hp+total*drain)
        if randf()<state.bonus("mp_eater"): state.mp=minf(stats.max_mp,state.mp+stats.max_mp*0.03)
        if state.buff_group("combo")!="" and not skill.get("needs_combo",false):
            var cap=int(maxf(5,state.bonus("combo_max")))
            var gain=2 if randf()<state.bonus("combo_double") else 1
            combo_orbs=mini(cap,combo_orbs+gain)
        var steal=skill_value(id,"steal")
        if steal>0 and not e.stolen and randf()<steal:
            e.stolen=true
            loot_requested.emit(e.global_position,{"potions":1} if randf()<0.4 else {"coins":randi_range(5,15)+e.level*2})
        if randf()<state.bonus("pickpocket"):
            loot_requested.emit(e.global_position,{"coins":randi_range(1,4)+int(e.level/2.0)})
    return total
func finish_hits(id: String,hit_any: bool):
    var skill=Catalog.skill(id)
    if not hit_any: return
    if skill.get("needs_combo",false): combo_orbs=0
    if skill.get("needs_charge",false):
        if randf()>=state.bonus("charge_keep"):
            var charge=state.buff_group("charge")
            if charge!="": state.remove_buff(charge)
    var chance=state.bonus("final_attack")
    if chance>0 and skill.shape in ["melee","lunge","projectile"] and randf()<chance:
        var near=targets_for(id,player.global_position,attack_facing,attack_reach,80,false,1)
        if not near.is_empty(): apply_hit(near[0],"basic" if state.basic_skill()=="basic" else state.basic_skill(),1,0.9)
func partner_mirror(e,id: String):
    if partner_active() and is_instance_valid(e) and e.hp>0: apply_hit(e,id,active_rank,0.5)
# ---------------- Projectiles ----------------
func launch_stars(id: String):
    var skill=Catalog.skill(id)
    var angles=[0.0]
    if skill.get("spread",0.0)>0: angles=[-skill.spread,0.0,skill.spread]
    var origins=[attack_origin]
    if partner_active(): origins.append(partner.global_position)
    for origin in origins:
        for angle in angles:
            var star=preload("res://world/player_star.gd").new()
            star.direction=Vector2(attack_facing,0).rotated(angle)
            star.max_distance=attack_reach
            star.style=skill.get("style","star") if skill.get("style","")!="" else "star"
            star.element=skill.get("element","")
            star.pierce=int(skill_value(id,"pierce",0))
            star.skill_id=id
            star.rank=active_rank
            star.scale_factor=1.0 if origin==attack_origin else 0.5
            star.combat=self
            var roll=roll_damage(id,active_rank,null,star.scale_factor)
            star.damage=roll[0]
            star.critical=roll[1]
            player.get_parent().add_child(star)
            star.global_position=origin+Vector2(0,-25)
            if origin!=attack_origin: star.modulate=Color("b4a4eb")
func projectile_hit(star,e):
    var id=star.skill_id
    var skill=Catalog.skill(id)
    var total=apply_hit(e,id,star.rank,star.scale_factor)
    var splash=skill.get("splash",0)
    if splash>0:
        var count=0
        for other in get_tree().get_nodes_in_group("enemies"):
            if other==e or other.hp<=0 or count>=int(skill_value(id,"targets",6))-1: continue
            if other.global_position.distance_to(star.global_position)<splash:
                apply_hit(other,id,star.rank,star.scale_factor*0.8)
                count+=1
        effect_requested.emit("burst",{"position":star.global_position,"radius":splash,"element":skill.get("element","fire")})
    if star.scale_factor==1.0: finish_hits(id,total>0)
    return total
# ---------------- Frame update ----------------
func tick(delta):
    update_partner(delta)
    for id in cooldowns: cooldowns[id]=maxf(0,cooldowns[id]-delta)
    for id in state.tick_buffs(delta):
        if Catalog.skill(id).get("group","")=="combo": combo_orbs=0
    for id in summons.keys():
        if not is_instance_valid(summons[id]): summons.erase(id)
    if active == "": return
    var previous_elapsed=elapsed
    elapsed+=delta
    var skill=Catalog.skill(active)
    if skill.shape=="projectile":
        var delay=skill.get("volley_delay",0.06)
        while volleys_fired<attack_star_count and elapsed>=windup+volleys_fired*delay:
            launch_stars(active)
            volleys_fired+=1
        if elapsed>=swing_end: active=""
        return
    if skill.shape=="lunge":
        var hit_any=false
        for e in targets_for(active,player.global_position,attack_facing,skill.reach,80,false,99):
            if struck.size()>=attack_targets: break
            if struck.has(e.get_instance_id()): continue
            struck.append(e.get_instance_id())
            hit_any=apply_hit(e,active,active_rank)>0 or hit_any
            partner_mirror(e,active)
        if hit_any: finish_hits(active,true)
        if elapsed>=swing_end: active=""
        return
    if elapsed >= windup and previous_elapsed <= swing_end-0.05 and struck.is_empty():
        var targets: Array
        var both=skill.get("both",false)
        match skill.shape:
            "chain": targets=chain_targets()
            "drop": targets=targets_for(active,attack_origin,attack_facing,attack_reach,skill.get("height",200),false,attack_targets)
            "area","pull": targets=targets_for(active,attack_origin,attack_facing,attack_reach,skill.get("height",90),both,attack_targets)
            _: targets=targets_for(active,attack_origin,attack_facing,attack_reach,skill.get("height",70),false,attack_targets)
        var hit_any=false
        for e in targets:
            struck.append(e.get_instance_id())
            hit_any=apply_hit(e,active,active_rank)>0 or hit_any
            if skill.shape in ["melee","area","pull"]: partner_mirror(e,active)
        if skill.has("effect") and skill.effect=="cure": cure()
        struck.append(-1)
        finish_hits(active,hit_any)
    if elapsed>=swing_end: active=""
func chain_targets() -> Array:
    var chain: Array=[]
    var from=attack_origin
    var points=[attack_origin+Vector2(0,-30)]
    var pool=targets_for(active,attack_origin,attack_facing,attack_reach,120,false,1)
    if pool.is_empty(): return chain
    chain.append(pool[0])
    points.append(pool[0].global_position+Vector2(0,-30))
    while chain.size()<attack_targets:
        var best=null
        var best_distance=240.0
        for e in get_tree().get_nodes_in_group("enemies"):
            if e.hp<=0 or chain.has(e): continue
            var d=e.global_position.distance_to(chain.back().global_position)
            if d<best_distance:
                best=e
                best_distance=d
        if best==null: break
        chain.append(best)
        points.append(best.global_position+Vector2(0,-30))
    effect_requested.emit("chain",{"points":points,"element":"lightning"})
    return chain
