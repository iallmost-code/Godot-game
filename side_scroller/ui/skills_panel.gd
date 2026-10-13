extends VBoxContainer
const Catalog=preload("res://data/catalog.gd")
const Style=preload("res://ui/style.gd")
var state
var selected_tier=1
var note=""
func bind(s,_b=null):
    state=s
    selected_tier=maxi(1,state.tier())
    refresh()
func assign_skill(slot: String,id: String) -> bool:
    var result=state.assign_skill(slot,id)
    note="Assigned to "+slot.to_upper() if result else "Already assigned elsewhere, or not learned."
    refresh()
    return result
func refresh():
    Style.clear(self)
    add_child(Style.label("SKILLS & JOB TREE",24,Color("f4d48a")))
    var tabs=HBoxContainer.new()
    add_child(tabs)
    for i in range(1,6):
        var text=["Warrior 10","Spearman 30","Dragon Knight 60","Dark Knight 100","Hyper 140+"][i-1]
        tabs.add_child(Style.button(text,func(): selected_tier=i; refresh()))
    if selected_tier>2:
        add_child(Style.label("FUTURE JOB — NOT PLAYABLE IN THIS BUILD",20,Color("bba8dc")))
        var explanation="Dragon Knight: erupting spears and larger area attacks." if selected_tier==3 else "Dark Knight: powerful mob clearing, boss damage and a map attack." if selected_tier==4 else "Hyper: passive skill modifiers, powerful buffs and burst attacks."
        add_child(Style.label(explanation,17))
        return
    add_child(Style.label("Tier %d skill points: %d  |  %s" % [selected_tier,state.sp[str(selected_tier)],"Advance with the town instructor to unlock this tier." if selected_tier>state.tier() else "Spend points to increase ranks; assign learned attacks below."],16))
    if selected_tier==2:
        add_child(Style.label("Spear Mastery  →  Ground Wave\nBattle Vigor (independent passive)",16,Color("8ed9d0")))
    else:
        add_child(Style.label("Crescent Sweep  •  Driving Thrust  •  Strength Training  •  Iron Skin",15,Color("8ed9d0")))
    for id in Catalog.skills():
        var skill=Catalog.skills()[id]
        if skill.tier!=selected_tier: continue
        var row=VBoxContainer.new()
        row.add_theme_constant_override("separation",3)
        add_child(row)
        var rank=state.skill_ranks.get(id,0)
        var line=HBoxContainer.new()
        row.add_child(line)
        var text=Style.label("%s   %d / %d" % [skill.name,rank,skill.max],18)
        text.custom_minimum_size.x=300
        line.add_child(text)
        var rank_button=Style.button("Rank +1",func():
            note="Rank increased." if state.rank_up(id) else "Need a skill point, unlocked tier, and any prerequisite."
            refresh())
        rank_button.disabled=rank>=skill.max or selected_tier>state.tier() or state.sp[str(selected_tier)]<=0 or (skill.has("requires") and state.skill_ranks.get(skill.requires,0)<1)
        line.add_child(rank_button)
        if skill.active:
            for slot in ["z","x","c"]:
                var button=Style.button(slot.to_upper()+(" ✓" if state.slots[slot]==id else ""),func(): assign_skill(slot,id))
                button.custom_minimum_size.x=56
                button.disabled=not state.can_use(id)
                line.add_child(button)
        row.add_child(Style.label(skill.description,14,Color("acc6c6")))
        if skill.active:
            row.add_child(Style.label("%d MP  •  %.1fs cooldown  •  %d targets  •  Next rank: +15%% base attack" % [skill.mana,skill.cooldown,skill.targets],13,Color("e1bf83")))
    add_child(Style.label(note,15,Color("e8cf8e")))
