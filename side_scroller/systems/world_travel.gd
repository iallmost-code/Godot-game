extends RefCounted
const Maps=preload("res://data/maps.gd")
const STAGES=[
    {"low":1,"high":11,"field":"dewdrop","town":"farmeadow"},
    {"low":12,"high":24,"field":"mossvale","town":"starbough"},
    {"low":25,"high":44,"field":"rotfen","town":"hollowroot"},
    {"low":45,"high":59,"field":"emberpeak","town":"ironridge"},
    {"low":60,"high":79,"field":"frostspire","town":"frostmere"},
    {"low":80,"high":99,"field":"clockwork","town":"tickletop"},
    {"low":100,"high":109,"field":"bonepit","town":"frostmere"},
    {"low":110,"high":124,"field":"tidegrave","town":"tideglass"},
    {"low":125,"high":154,"field":"skyreach","town":"wyrmrest"},
    {"low":155,"high":200,"field":"timeless","town":"hourglass"},
]
static func recommended(level: int) -> Dictionary:
    for stage in STAGES:
        if level<=stage.high: return stage
    return STAGES.back()
static func nearest_town(map_id: String,position=Vector2.ZERO) -> String:
    if map_id=="portal_hub": return "town"
    var data=Maps.definition(map_id)
    if data.is_empty(): return "town"
    if data.safe: return map_id
    var queue=[{"id":map_id,"distance":0.0}]
    var distances={map_id:0.0}
    while not queue.is_empty():
        queue.sort_custom(func(a,b): return a.distance<b.distance)
        var step=queue.pop_front()
        if step.distance>distances[step.id]: continue
        var area=Maps.definition(step.id)
        if area.safe and step.id!="portal_hub": return step.id
        for portal in area.portals:
            if portal.target=="portal_hub": continue
            var distance=step.distance+(position.distance_to(portal.position) if step.id==map_id else 4000.0)
            if distance>=distances.get(portal.target,INF): continue
            distances[portal.target]=distance
            queue.append({"id":portal.target,"distance":distance})
    return "town"
static func next_job_level(state) -> int:
    if state.tier()==0: return 8 if state.archetype=="magician" else 10
    return {1:30,2:70,3:120}.get(state.tier(),0)
static func travel_target(area_id: String) -> String:
    var area=Maps.definition(area_id)
    if area.has("boss"): return area.region
    return area_id
