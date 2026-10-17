extends RefCounted
const Character=preload("res://systems/character_state.gd")
const Catalog=preload("res://data/catalog.gd")
static func reach(s,level: int):
    while s.level<level: s.add_xp(s.xp_required(s.level))
# A character of the given class that advanced through each job in path on time.
static func make(kind: String,path: Array=[],level: int=1):
    var s=Character.new()
    s.initialize_class(kind)
    for job in path:
        reach(s,Catalog.jobs()[job].level)
        s.advance_job(job)
    reach(s,level)
    return s
static func learn(s,id: String,ranks: int=1):
    var pool=s.skill_pool(id)
    for i in range(ranks):
        if s.sp[pool]<=0:
            s.sp[pool]+=1
            s.sp_earned[pool]+=1
        s.rank_up(id)
static func rig(t,s):
    var world=Node2D.new()
    t.root.add_child(world)
    var p=load("res://actors/player.gd").new()
    p.state=s
    world.add_child(p)
    p.set_physics_process(false)
    p.hurt_timer=0
    var c=load("res://actors/combat_controller.gd").new()
    world.add_child(c)
    c.setup(p,s)
    c.set_process(false)
    return {"world":world,"player":p,"combat":c}
static func mob(world,pos: Vector2,hp: int=500,id: String="mossling"):
    var e=load("res://actors/enemy.gd").new()
    e.definition_id=id
    e.position=pos
    world.add_child(e)
    e.set_physics_process(false)
    e.hp=hp
    e.max_hp=maxi(hp,e.max_hp)
    return e
