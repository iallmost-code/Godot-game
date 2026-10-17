extends VBoxContainer
const Catalog=preload("res://data/catalog.gd")
const Style=preload("res://ui/style.gd")
var state
var bindings
var selected_tier=1
var note=""
func bind(s,b=null):
    state=s
    bindings=b
    selected_tier=state.tier()
    refresh()
func assign_skill(slot: String,id: String) -> bool:
    var result=state.assign_skill(slot,id)
    note="Assigned to "+slot_label(slot)+". Existing skills move or swap automatically." if result else "Learn this skill and unlock its job first."
    refresh()
    return result
func rank_up(id: String,times: int=1):
    var gained=0
    for i in range(times):
        if state.rank_up(id): gained+=1
    note="%s rank +%d." % [state.skill_name(id),gained] if gained>0 else "Need a skill point for this job, an unlocked job and any prerequisite."
    refresh()
# The job shown on a tier tab: the one on your path, or "" when not chosen yet.
func job_for_tier(t: int) -> String:
    for id in state.lineage():
        if Catalog.jobs()[id].tier==t: return id
    return ""
func path_options(t: int) -> Array:
    # Jobs this character could still reach at tier t.
    var result=[]
    for id in Catalog.jobs():
        var job=Catalog.jobs()[id]
        if job.tier!=t or job.path!=state.archetype: continue
        var ancestor=id
        while Catalog.jobs()[ancestor].tier>state.tier():
            ancestor=Catalog.jobs()[ancestor].parent
        if ancestor==state.job: result.append(id)
    return result
func refresh():
    Style.clear(self)
    add_child(Style.label("SKILL BOOK  —  %s %s" % [state.archetype_name(state.archetype).to_upper(),"" if state.job=="beginner" else "/ "+state.job_name().to_upper()],22,Color("f4d48a")))
    var tabs=HBoxContainer.new()
    add_child(tabs)
    for t in range(0,5):
        var id="beginner" if t==0 else job_for_tier(t)
        var text=Catalog.jobs()["beginner"].name if t==0 else (Catalog.jobs()[id].name if id!="" else "%s job" % ["","1st","2nd","3rd","4th"][t])
        var button=Style.button(text+" [%d]" % state.sp[str(t)],func(): selected_tier=t; refresh())
        button.modulate=Color("b7d88a") if t==selected_tier else Color.WHITE
        tabs.add_child(button)
    var hotbar=HBoxContainer.new()
    add_child(hotbar)
    for slot in Catalog.SLOTS:
        var assigned=state.slots[slot]
        hotbar.add_child(Style.label(slot_label(slot)+": "+(state.skill_name(assigned) if assigned!="" else "—")+"   ",13,Color("f4d48a")))
    if note!="": add_child(Style.label(note,15,Color("8ed9d0")))
    var job_id="beginner" if selected_tier==0 else job_for_tier(selected_tier)
    if job_id=="":
        var options=path_options(selected_tier)
        var level=Catalog.jobs()[options[0]].level if not options.is_empty() else 0
        add_child(Style.label("Not unlocked yet. Advance with Captain Elowen at level %d.%s" % [level,"  Choose one path:" if options.size()>1 else ""],16,Color("bfaee5")))
        for option in options:
            var names=[]
            for id in Catalog.skills():
                if Catalog.skill(id).job==option: names.append(Catalog.skill(id).name)
            add_child(Style.label(Catalog.jobs()[option].name.to_upper(),17,Color("8ed9d0")))
            add_child(Style.label(", ".join(names),14,Color("acc6c6")))
        return
    add_child(Style.label("%s skill points: %d" % [Catalog.jobs()[job_id].name,state.sp[str(selected_tier)]],16))
    for id in Catalog.skills():
        var skill=Catalog.skill(id)
        if skill.job!=job_id: continue
        var row=VBoxContainer.new()
        row.add_theme_constant_override("separation",2)
        add_child(row)
        var rank=state.skill_ranks.get(id,0)
        var line=HBoxContainer.new()
        row.add_child(line)
        var icon=preload("res://ui/skill_icon.gd").new()
        icon.custom_minimum_size=Vector2(40,40)
        icon.set_state(id)
        if rank==0: icon.modulate=Color(1,1,1,0.45)
        line.add_child(icon)
        var text=Style.label("%s   %d/%d%s" % [skill.name,rank,skill.max,"" if skill.active else "  (passive)"],16)
        text.custom_minimum_size.x=270
        line.add_child(text)
        var blocked=rank>=skill.max or state.sp[str(selected_tier)]<=0 or (skill.has("requires") and state.skill_ranks.get(skill.requires,0)<1)
        var plus=Style.button("+1",func(): rank_up(id))
        plus.disabled=blocked
        line.add_child(plus)
        var five=Style.button("+5",func(): rank_up(id,5))
        five.disabled=blocked
        line.add_child(five)
        if skill.active:
            for slot in Catalog.SLOTS:
                var button=Style.button(slot_label(slot)+("•" if state.slots[slot]==id else ""),func(): assign_skill(slot,id))
                button.custom_minimum_size.x=40
                button.disabled=not state.can_use(id)
                button.tooltip_text="Move or swap this skill into "+slot_label(slot)+"." if state.can_use(id) else "Learn rank 1 first."
                line.add_child(button)
        row.add_child(Style.label(skill.description+("  Requires "+Catalog.skill(skill.requires).name+"." if skill.has("requires") else ""),13,Color("acc6c6")))
        row.add_child(Style.label(details(id,maxi(1,rank)),12,Color("e1bf83")))
func details(id: String,rank: int) -> String:
    var skill=Catalog.skill(id)
    var parts=[]
    var v=func(key): return Catalog.value(skill[key],rank,skill.max)
    if skill.active and skill.has("mana") and v.call("mana")>0: parts.append("%d MP" % v.call("mana"))
    if skill.kind=="attack":
        if skill.get("power",1.0) is Array or skill.power>0: parts.append("%d%% damage%s" % [int(v.call("power")*100),(" ×%d hits" % int(v.call("hits"))) if v.call("hits")>1 else ""])
        if v.call("count")>1: parts.append("%d projectiles" % v.call("count"))
        if v.call("targets")>1: parts.append("%d targets" % v.call("targets"))
        if skill.get("pierce",0) is Array or skill.get("pierce",0)>0: parts.append("pierces %d" % v.call("pierce"))
    if skill.has("status"):
        parts.append("%d%% %s %.0fs" % [int(Catalog.value(skill.status.chance,rank,skill.max)*100),skill.status.id.replace("_"," "),Catalog.value(skill.status.time,rank,skill.max)])
    if skill.has("heal"): parts.append("heals %d%% HP" % int(v.call("heal")*100))
    if skill.has("stats"):
        for key in skill.stats:
            var amount=Catalog.value(skill.stats[key],rank,skill.max)
            if key in ["invisible","invincible","revive","status_immune","partner","charge","hamstring","blinding","venom"]: continue
            parts.append(("%s +%d%%" % [key.replace("_"," "),int(amount*100)]) if absf(amount)<2.0 and not key in ["hp_regen","mp_regen","reach","knockback","attack","defense","combo_max","hp_drain"] else "%s +%d" % [key.replace("_"," "),int(amount)])
    if skill.has("duration"): parts.append("%ds" % v.call("duration"))
    if v.call("cooldown")>=1.0 and skill.active: parts.append("%.0fs cooldown" % v.call("cooldown"))
    return "Rank %d: " % rank+"  •  ".join(parts)
func slot_label(slot: String) -> String:
    if bindings!=null and bindings.current().has("skill_"+slot): return OS.get_keycode_string(bindings.current()["skill_"+slot])
    return slot.to_upper()
