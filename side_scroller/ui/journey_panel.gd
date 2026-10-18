extends VBoxContainer
const C=preload("res://data/catalog.gd")
const Style=preload("res://ui/style.gd")
const Travel=preload("res://systems/world_travel.gd")
const Maps=preload("res://data/maps.gd")
var state
signal travel_requested(destination: String)
signal panel_requested(panel: String)
func bind(s,_b=null):
    state=s
    refresh()
func summary() -> String:
    return "Lv %d %s • %s" % [state.level,state.job_name(),"4th job complete" if state.tier()==4 else "%d of 4 jobs complete" % state.tier()]
func refresh():
    Style.clear(self)
    add_child(Style.section("YOUR CHARACTER JOURNEY"))
    add_child(Style.label(summary(),22))
    var next=Travel.next_job_level(state)
    var status="All four job advancements are complete. Build your skills and challenge the world's bosses." if next==0 else "READY TO ADVANCE: visit Captain Elowen in Willowbridge." if state.level>=next else "Next job at level %d — %d levels to go." % [next,next-state.level]
    var note=Style.label(status,15)
    note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
    add_child(note)
    var actions=HFlowContainer.new()
    add_child(actions)
    if next>0:actions.add_child(Style.button("Visit Captain Elowen",func(): travel_requested.emit("town")))
    actions.add_child(Style.button("Spend skill points",func(): panel_requested.emit("skills")))
    actions.add_child(Style.button("Find a boss",func(): panel_requested.emit("bosses")))
    var stage=Travel.recommended(state.level)
    actions.add_child(Style.button("Hunt: "+Maps.definition(stage.field).name,func(): travel_requested.emit(stage.field)))
    for tier in range(1,5):
        var chosen=""
        for id in state.lineage():
            if C.jobs()[id].tier==tier:chosen=id
        var choices=[]
        if chosen!="":choices=[chosen]
        else:
            for id in C.jobs():
                var job=C.jobs()[id]
                if job.tier!=tier or job.path!=state.archetype:continue
                var ancestor=id
                while C.jobs()[ancestor].tier>state.tier():ancestor=C.jobs()[ancestor].parent
                if ancestor==state.job:choices.append(id)
        var level=8 if tier==1 and state.archetype=="magician" else [0,10,30,70,120][tier]
        add_child(Style.section("%s JOB  /  LEVEL %d  /  %s" % [["","1ST","2ND","3RD","4TH"][tier],level,"COMPLETE" if chosen!="" else "READY" if state.level>=level and tier==state.tier()+1 else "UPCOMING"],chosen!=""))
        for id in choices:
            add_child(Style.label(C.jobs()[id].name+(" — Current job" if id==state.job else ""),17))
            var skills=[]
            for skill_id in C.skills():
                var skill=C.skill(skill_id)
                if skill.job==id and skill.active:skills.append(skill.name)
            var text=Style.label("Skills: "+", ".join(skills),13)
            text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
            add_child(text)
    add_child(Style.section("NEXT MILESTONE",true))
    var exp=ProgressBar.new()
    exp.max_value=state.xp_required(state.level)
    exp.value=state.xp
    exp.custom_minimum_size.y=22
    add_child(exp)
    add_child(Style.label("%d / %d EXP • %d AP • %d unspent skill points" % [state.xp,state.xp_required(state.level),state.ap,total_points()],14))
func total_points() -> int:
    var total=0
    for value in state.sp.values():total+=value
    return total
