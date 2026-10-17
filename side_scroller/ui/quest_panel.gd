extends VBoxContainer
# Quest log: active quests with progress, and where to find new ones.
const Style=preload("res://ui/style.gd")
const Quests=preload("res://systems/quests.gd")
const Maps=preload("res://data/maps.gd")
const Adventure=preload("res://data/adventure.gd")
var state
func bind(s,_bindings=null):
    state=s
    refresh()
func town_name(id: String) -> String: return "Willowbridge" if id=="town" else Maps.definition(id).get("name",id)
func refresh():
    Style.clear(self)
    var active=[]
    var available=[]
    var done=0
    for id in Quests.all():
        match Quests.status(state,id):
            "active","ready": active.append(id)
            "available": available.append(id)
            "done": done+=1
    add_child(Style.section("IN PROGRESS  (%d)  •  Completed %d of %d" % [active.size(),done,Quests.all().size()]))
    if active.is_empty(): add_child(Style.label("No active quests. Look for NPCs with a yellow ! over their head in towns.",14))
    for id in active:
        var q=Quests.all()[id]
        var ready=Quests.status(state,id)=="ready"
        var text="%s  —  %s" % [q.title,"READY: return to %s in %s" % [q.npc,town_name(q.town)] if ready else "%d / %d" % [Quests.progress(state,id),q.count] if q.type!="deliver" else "talk to "+q.target]
        add_child(Style.label(text,15,Color("536623") if ready else Color("354454")))
        add_child(Style.label("From %s (%s)  •  Reward: %s" % [q.npc,town_name(q.town),Quests.reward_text(q.reward)],12,Color("617180")))
    add_child(Style.section("AVAILABLE NOW",true))
    if available.is_empty(): add_child(Style.label("Nothing new at your level. Keep growing!",14))
    available.sort_custom(func(a,b): return Quests.all()[a].min_level>Quests.all()[b].min_level)
    for id in available.slice(0,12):
        var q=Quests.all()[id]
        add_child(Style.label("Lv %d  •  %s  —  %s in %s" % [q.min_level,q.title,q.npc,town_name(q.town)],14))
    if not state.quest_items.is_empty():
        add_child(Style.section("QUEST ITEMS"))
        var parts=[]
        for item in state.quest_items: parts.append("%s ×%d" % [Adventure.QUEST_ITEMS[item],state.quest_items[item]])
        add_child(Style.label(",  ".join(parts),14))
