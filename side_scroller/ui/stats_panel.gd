extends VBoxContainer
const Style=preload("res://ui/style.gd")
var state
var draft={}
var note=""
func bind(s,_b=null):
    state=s
    refresh()
func remaining_points() -> int:
    var total=0
    for value in draft.values(): total+=value
    return maxi(0,state.ap-total)
func stage(key: String,amount=1):
    if not state.attributes.has(key) or not [1,5,-1].has(amount): return
    var count=remaining_points() if amount==-1 else mini(amount,remaining_points())
    if count>0:
        draft[key]=draft.get(key,0)+count
        note=""
    refresh()
func confirm() -> bool:
    var result=state.allocate_attributes(draft)
    if result: draft.clear(); note="Attributes applied."
    else: note="Choose points to allocate before confirming."
    refresh()
    return result
func cancel():
    draft.clear()
    refresh()
func refresh():
    Style.clear(self)
    add_child(Style.label("CHARACTER STATS",24,Color("f4d48a")))
    var stats=state.derived_stats()
    add_child(Style.label("Level %d   •   %s   •   %d points available" % [state.level,state.job.capitalize(),remaining_points()]))
    var explanations={"STR":"Melee damage and maximum health","DEX":"Additional melee damage","INT":"Maximum mana","LUK":"Critical hit chance (25% cap)"}
    if state.archetype=="thief":
        explanations.LUK="Throwing damage and critical chance"
        explanations.STR="Maximum health and defense"
    for key in ["STR","DEX","INT","LUK"]:
        var row=HBoxContainer.new()
        add_child(row)
        var text=Style.label("%s    %d %s" % [key,state.attributes[key],"+ %d pending" % draft[key] if draft.get(key,0)>0 else ""])
        text.custom_minimum_size.x=240
        row.add_child(text)
        var explain=Style.label(explanations[key],14,Color("acc6c6"))
        explain.custom_minimum_size.x=270
        row.add_child(explain)
        for amount in [1,5,-1]:
            var button=Style.button("All" if amount==-1 else "+%d" % amount,func(): stage(key,amount))
            button.disabled=remaining_points()==0
            button.tooltip_text="Add all remaining points to "+key+" in this draft." if amount==-1 else "Add up to %d remaining points to %s." % [amount,key]
            row.add_child(button)
    var proposed=state.attributes.duplicate()
    for key in draft: proposed[key]+=draft[key]
    var hp_gain=2*draft.get("STR",0)
    var mp_gain=2*draft.get("INT",0)
    var atk_gain=draft.get("LUK" if state.archetype=="thief" else "STR",0)+int(proposed.DEX/4.0)-int(state.attributes.DEX/4.0)
    add_child(Style.label("Attack %d -> %d     Defense %d -> %d\nMax HP %d -> %d     Max MP %d -> %d\nCritical chance %.1f%% -> %.1f%%" % [stats.attack,stats.attack+atk_gain,stats.defense,stats.defense+int(proposed.STR/10.0)-int(state.attributes.STR/10.0),stats.max_hp,stats.max_hp+hp_gain,stats.max_mp,stats.max_mp+mp_gain,stats.crit*100,minf(0.25,0.05+0.002*(proposed.LUK-4))*100],18))
    var actions=HBoxContainer.new()
    add_child(actions)
    actions.add_child(Style.button("Confirm points",func(): confirm()))
    actions.add_child(Style.button("Cancel draft",cancel))
    add_child(Style.label(note,15,Color("e8cf8e")))
