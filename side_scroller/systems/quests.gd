extends RefCounted
# Town quests. Uses data/quests.json when it exists (written by the art/writing
# pass), otherwise a built-in three-step chain for every town.
const Maps=preload("res://data/maps.gd")
const EnemyStats=preload("res://data/enemy_stats.gd")
const Adventure=preload("res://data/adventure.gd")
const Catalog=preload("res://data/catalog.gd")
const JSON_PATH="res://data/quests.json"
const GIVERS={"town":"Old Tobin","firstlight":"Fisher Bess","gullhaven":"Deckhand Pim","starbough":"Gardener Wil","ironridge":"Smith Hagen",
    "shadecross":"Lookout Nix","hollowroot":"Gravedigger Moll","sunpetal":"Diver Coral","skylume":"Courier Feather","frostmere":"Trapper Ulf",
    "tickletop":"Toymaker Bix","brasswatch":"Mechanic Rivet","lanternvale":"Lamplighter Hana","tideglass":"Tidewatcher Mira","wyrmrest":"Scale-Sage Orin",
    "peachspire":"Monk Tadao","reedhaven":"Reedcutter Bo","saffron":"Spicetrader Zafir","verdigris":"Apprentice Quill","hourglass":"Chronicler Sev",
    "moonshrine":"Priestess Yuki","emberlane":"Fence Marlow","mistkeep":"Captain Oda","copperwick":"Butler Graves","thornscar":"Huntress Kael",
    "rainport":"Salvager Brine","bloomkamp":"Ringmaster Dot","farmeadow":"Farmhand Lottie","crownreach":"Herald Tamsin","rimehaven":"Sledder Finn",
    "jadehaven":"Picker Mei-Lin","lotusquay":"Ferryman Osei"}
static var _all: Dictionary={}
static var _givers: Dictionary={}
# Tests can force the built-in chains even when quests.json exists.
static var force_builtin=false
static func all() -> Dictionary:
    if _all.is_empty(): build()
    return _all
static func reset_cache():
    _all={}
    _givers={}
static func build():
    var loaded=load_json() if not force_builtin else {"quests":[],"npc_x":{},"npc_town":{}}
    var list: Array=loaded.quests if not loaded.quests.is_empty() else builtin()
    for q in list: _all[q.id]=q
    for q in list:
        if q.get("next","")!="" and _all.has(q.next): _all[q.next].prev=q.id
    for q in list:
        add_giver(q.town,q.npc,loaded.npc_x)
        if q.type=="deliver" and loaded.npc_town.has(q.target): add_giver(loaded.npc_town[q.target],q.target,loaded.npc_x)
    # Givers stand clear of the instructor, the merchant, the gates and each other.
    for town in _givers:
        var taken=[]
        for i in _givers[town].size():
            var giver=_givers[town][i]
            if giver.x<=0 or blocked(town,giver.x,taken):
                for x in [300.0 if town=="town" else 420.0,1130.0,1390.0,1650.0,1910.0,2170.0,2430.0,2690.0]:
                    if not blocked(town,x,taken):
                        giver.x=x
                        break
            taken.append(giver.x)
static func blocked(town: String,x: float,taken: Array) -> bool:
    var data=Maps.definition(town)
    if x<60 or x>data.width-60: return true
    if absf(x-(500.0 if town=="town" else 600.0))<170 or absf(x-800.0)<150: return true
    for portal in data.portals:
        if absf(portal.position.x-x)<150: return true
    for other in taken:
        if absf(other-x)<150: return true
    return false
static func add_giver(town: String,name: String,positions: Dictionary):
    if not _givers.has(town): _givers[town]=[]
    if not has_giver(town,name): _givers[town].append({"name":name,"x":float(positions.get(name,0.0))})
static func has_giver(town: String,name: String) -> bool:
    for g in _givers.get(town,[]):
        if g.name==name: return true
    return false
static func givers(town: String) -> Array:
    all()
    return _givers.get(town,[])
static func load_json() -> Dictionary:
    var result={"quests":[],"npc_x":{},"npc_town":{}}
    if not FileAccess.file_exists(JSON_PATH): return result
    var parsed=JSON.parse_string(FileAccess.get_file_as_string(JSON_PATH))
    if not parsed is Dictionary: return result
    for npc in parsed.get("npcs",[]):
        if npc is Dictionary and npc.get("name","") is String and (npc.get("x",0) is float or npc.get("x",0) is int):
            result.npc_x[npc.name]=float(npc.x)
        if npc is Dictionary and npc.get("name","") is String and npc.get("town","") is String and Maps.definition(npc.town).get("safe",false):
            result.npc_town[npc.name]=npc.town
    for raw in parsed.get("quests",[]):
        var q=clean(raw)
        if not q.is_empty(): result.quests.append(q)
    return result
# Normalise one JSON quest; returns {} when it cannot work in this world.
static func clean(raw) -> Dictionary:
    if not raw is Dictionary: return {}
    for key in ["id","town","npc","type"]:
        if not raw.get(key,"") is String or raw.get(key,"")=="": return {}
    if not Maps.definition(raw.town).get("safe",false) or not raw.type in ["hunt","collect","deliver"]: return {}
    var q={"id":raw.id,"town":raw.town,"npc":raw.npc,"type":raw.type,"min_level":clampi(int(raw.get("min_level",1)),1,Catalog.MAX_LEVEL),
        "target":str(raw.get("target","")),"item":str(raw.get("item","")),"count":clampi(int(raw.get("count",1)),1,999),
        "intro":lines(raw.get("intro",[])),"progress":str(raw.get("progress","Come back when it's done.")),"complete":lines(raw.get("complete",["Thank you!"])),
        "next":str(raw.get("next","")),"title":str(raw.get("title",""))}
    if q.type=="deliver":
        q.count=1
    elif not known_monster(q.target): return {}
    if q.type=="collect" and not Adventure.QUEST_ITEMS.has(q.item): q.item=Adventure.quest_item_for(q.target)
    var r=raw.get("reward",{})
    if not r is Dictionary: r={}
    q.reward={"xp":maxi(0,int(r.get("xp",0))),"coins":maxi(0,int(r.get("coins",0)))}
    if r.get("item","") is String and Catalog.items().has(r.get("item","")): q.reward.item=r.item
    if r.get("consumable","") is String and Catalog.consumables().has(r.get("consumable","")):
        q.reward.consumable=r.consumable
        q.reward.count=clampi(int(r.get("consumable_count",1)),1,999)
    if r.get("scroll","") is String and Adventure.scrolls().has(r.get("scroll","")): q.reward.scroll=r.scroll
    if q.title=="": q.title=default_title(q)
    return q
static func known_monster(id: String) -> bool:
    return EnemyStats.LEGACY.has(id) or EnemyStats.ROSTER.has(id) or EnemyStats.BOSSES.has(id)
static func lines(value) -> Array:
    if value is String: return [value]
    var result=[]
    if value is Array:
        for line in value: result.append(str(line))
    return result if not result.is_empty() else ["..."]
static func default_title(q: Dictionary) -> String:
    match q.type:
        "hunt": return "Hunt %d %s" % [q.count,plural(EnemyStats.profile(q.target).name)]
        "collect": return "Collect %d %s" % [q.count,plural(Adventure.QUEST_ITEMS[q.item])]
    return "Deliver to %s" % q.target
static func plural(word: String) -> String:
    if word.ends_with("s") or word.ends_with("sh") or word.ends_with("ch"): return word+"es" if not word.ends_with("s") or word.ends_with("ss") else word
    if word.ends_with("y") and not word.ends_with("ey"): return word.left(-1)+"ies"
    if word.ends_with("f"): return word.left(-1)+"ves"
    return word+"s"
# Three linked quests per town: hunt, collect a drop, then a tougher hunt.
static func builtin() -> Array:
    var result=[]
    var towns=[["town","Whisperwood",3,["mossling","mossling"],["lantern"]]]
    for row in Maps.region_rows():
        var lists=Maps.ROUTE_MONSTERS.get(row[0],[])
        if lists.is_empty(): continue
        towns.append([row[0],row[4],int(row[3]),lists[0],lists[1]])
    for entry in towns:
        var town: String=entry[0]
        var route: String=entry[1]
        var level: int=maxi(1,entry[2])
        var npc=GIVERS.get(town,"Townsfolk")
        var first: String=entry[3][0]
        var second: String=entry[3][1]
        var third: String=entry[4][0]
        var item=Adventure.quest_item_for(second)
        var band=Maps.band_for(level+5)
        var potion="hp_1" if level<20 else "hp_2" if level<50 else "hp_3" if level<100 else "hp_4"
        var a=EnemyStats.profile(first).name
        var b=EnemyStats.profile(second).name
        var c=EnemyStats.profile(third).name
        var per=EnemyStats.xp_for(level)
        var ids=[town+"_q1",town+"_q2",town+"_q3"]
        result.append({"id":ids[0],"town":town,"npc":npc,"type":"hunt","min_level":level,"target":first,"item":"","count":20,"next":ids[1],
            "intro":["You there! You look like you can swing a weapon.","%s keep wandering out of %s and trampling everything. Thin them out for me: 20 should do it." % [plural(a),route]],
            "progress":"Still %s everywhere out there. Keep at it!" % plural(a).to_lower(),
            "complete":["Ha! Look at that. The road's already quieter.","Here, take this for your trouble."],
            "reward":{"xp":per*20,"coins":60+level*25,"consumable":potion,"count":10}})
        result.append({"id":ids[1],"town":town,"npc":npc,"type":"collect","min_level":level,"target":second,"item":item,"count":15,"next":ids[2],
            "intro":["Now, a favour of a stranger sort.","Bring me 15 %s. %s out on %s carry them." % [plural(Adventure.QUEST_ITEMS[item]),plural(b),route],"Don't ask what they're for. Okay, it's soup."],
            "progress":"Any luck finding those %s?" % plural(Adventure.QUEST_ITEMS[item]).to_lower(),
            "complete":["Perfect. Smells awful. Wonderful.","This scroll's been gathering dust in my drawer. Go on, it's yours."],
            "reward":{"xp":per*25,"coins":100+level*35,"scroll":"scroll_weapon_60"}})
        result.append({"id":ids[2],"town":town,"npc":npc,"type":"hunt","min_level":level+2,"target":third,"item":"","count":25,"next":"",
            "intro":["One last job, and it's a real one.","%s up high on %s have been picking off travellers. Climb up there and deal with 25 of them." % [plural(c),route]],
            "progress":"The high ledges are still crawling with %s." % plural(c).to_lower(),
            "complete":["You actually did it. %s owes you one." % ("Willowbridge" if town=="town" else Maps.definition(town).name),"I had this made for whoever finished the job. Wear it well."],
            "reward":{"xp":per*40,"coins":200+level*50,"item":"hat_"+band if Catalog.items().has("hat_"+band) else "","scroll":"scroll_armor_60"}})
    for q in result:
        q.title=default_title(q)
        if q.reward.get("item","")=="": q.reward.erase("item")
    return result

# --- Per-character progress ---
static func status(state,id: String) -> String:
    var q=all().get(id,{})
    if q.is_empty(): return "none"
    var entry=state.quests.get(id,{})
    if entry.get("status","")=="done": return "done"
    if entry.get("status","")=="active": return "ready" if ready(state,id) else "active"
    if q.has("prev") and state.quests.get(q.prev,{}).get("status","")!="done": return "hidden"
    if state.level<q.min_level: return "locked"
    return "available"
static func progress(state,id: String) -> int:
    var q=all()[id]
    match q.type:
        "collect": return mini(q.count,int(state.quest_items.get(q.item,0)))
        "deliver": return 0
    return mini(q.count,int(state.quests.get(id,{}).get("count",0)))
static func ready(state,id: String) -> bool:
    var q=all()[id]
    if q.type=="deliver": return false
    return progress(state,id)>=q.count
static func accept(state,id: String) -> bool:
    if status(state,id)!="available": return false
    state.quests[id]={"status":"active","count":0}
    state.changed.emit()
    return true
static func abandon(state,id: String) -> bool:
    if state.quests.get(id,{}).get("status","")!="active": return false
    state.quests.erase(id)
    state.changed.emit()
    return true
# Counts a kill toward active hunt quests; returns notices to show.
static func on_kill(state,monster: String) -> Array:
    var notes=[]
    for id in state.quests:
        var entry=state.quests[id]
        var q=all().get(id,{})
        if q.is_empty() or entry.status!="active" or q.type!="hunt" or q.target!=monster: continue
        if entry.count<q.count:
            entry.count+=1
            if entry.count==q.count: notes.append("Quest ready: %s. Return to %s." % [q.title,q.npc])
            elif entry.count%5==0: notes.append("%s %d / %d" % [q.title,entry.count,q.count])
    return notes
# Quest item a defeated monster should drop, or "".
static func wanted_drop(state,monster: String) -> String:
    for id in state.quests:
        var q=all().get(id,{})
        if q.is_empty() or state.quests[id].status!="active" or q.type!="collect" or q.target!=monster: continue
        if int(state.quest_items.get(q.item,0))<q.count: return q.item
    return ""
# Hands in a finished quest. Returns the reward, or {} when it is not ready
# (or the reward item does not fit in the bag).
static func complete(state,id: String) -> Dictionary:
    var q=all().get(id,{})
    if q.is_empty() or status(state,id)!="ready" and not (q.type=="deliver" and status(state,id)=="active"): return {}
    var reward=q.reward
    if reward.has("item") and state.inventory.size()>=state.INVENTORY_LIMIT: return {}
    if q.type=="collect":
        state.quest_items[q.item]=int(state.quest_items.get(q.item,0))-q.count
        if state.quest_items[q.item]<=0: state.quest_items.erase(q.item)
    state.quests[id]={"status":"done","count":q.count}
    if reward.has("item"): state.add_item_uid(reward.item)
    if reward.has("scroll"): state.add_scroll(reward.scroll)
    if reward.has("consumable"): state.consumables[reward.consumable]=mini(9999,int(state.consumables.get(reward.consumable,0))+int(reward.get("count",1)))
    state.coins=mini(1000000,state.coins+int(reward.get("coins",0)))
    state.add_xp(int(reward.get("xp",0)))
    state.changed.emit()
    return reward
static func reward_text(reward: Dictionary) -> String:
    var parts=[]
    if reward.get("xp",0)>0: parts.append("%d XP" % reward.xp)
    if reward.get("coins",0)>0: parts.append("%d coins" % reward.coins)
    if reward.has("item"): parts.append(Catalog.items()[reward.item].name)
    if reward.has("consumable"): parts.append("%d× %s" % [reward.get("count",1),Catalog.consumables()[reward.consumable].name])
    if reward.has("scroll"): parts.append(Adventure.scrolls()[reward.scroll].name)
    return ", ".join(parts)
# Quests an NPC has to say something about, most urgent first.
static func for_npc(state,town: String,npc: String) -> Array:
    var order={"ready":0,"available":1,"active":2,"locked":3}
    var result=[]
    for id in all():
        var q=all()[id]
        var talker=q.npc if not (q.type=="deliver" and status(state,id)=="active") else q.target
        if talker!=npc: continue
        if q.town!=town and talker==q.npc: continue
        var s=status(state,id)
        if order.has(s): result.append(id)
    result.sort_custom(func(a,b): return order[status(state,a)]<order[status(state,b)])
    return result
# Marker shown over an NPC: "?" ready, "!" available, "…" active, "" nothing.
static func marker(state,town: String,npc: String) -> String:
    var list=for_npc(state,town,npc)
    if list.is_empty(): return ""
    match status(state,list[0]):
        "ready": return "?"
        "available": return "!"
        "active": return "…"
        "locked": return "!locked"
    return ""
