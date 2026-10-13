extends VBoxContainer
const Style=preload("res://ui/style.gd")
var state
var draft={}
var note=""
func bind(s,_b=null):
    state=s
    refresh()
func stage(key: String):
    var total=0
    for value in draft.values(): total+=value
    if total<state.ap: draft[key]=draft.get(key,0)+1
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
    add_child(Style.label("Level %d   •   %s   •   %d points available" % [state.level,state.job.capitalize(),state.ap]))
    var explanations={"STR":"Melee damage and maximum health","DEX":"Additional melee damage","INT":"Maximum mana","LUK":"Critical hit chance (25% cap)"}
    for key in ["STR","DEX","INT","LUK"]:
        var row=HBoxContainer.new()
        add_child(row)
        var text=Style.label("%s    %d %s" % [key,state.attributes[key],"+ %d pending" % draft[key] if draft.get(key,0)>0 else ""])
        text.custom_minimum_size.x=240
        row.add_child(text)
        var explain=Style.label(explanations[key],14,Color("acc6c6"))
        explain.custom_minimum_size.x=270
        row.add_child(explain)
        row.add_child(Style.button("+",func(): stage(key)))
    var proposed=state.attributes.duplicate()
    for key in draft: proposed[key]+=draft[key]
    var hp_gain=2*draft.get("STR",0)
    var mp_gain=2*draft.get("INT",0)
    var atk_gain=draft.get("STR",0)+int(proposed.DEX/4.0)-int(state.attributes.DEX/4.0)
    add_child(Style.label("Attack %d -> %d     Defense %d\nMax HP %d -> %d     Max MP %d -> %d\nCritical chance %.1f%%" % [stats.attack,stats.attack+atk_gain,stats.defense,stats.max_hp,stats.max_hp+hp_gain,stats.max_mp,stats.max_mp+mp_gain,stats.crit*100],18))
    var actions=HBoxContainer.new()
    add_child(actions)
    actions.add_child(Style.button("Confirm points",func(): confirm()))
    actions.add_child(Style.button("Cancel draft",cancel))
    add_child(Style.label(note,15,Color("e8cf8e")))
