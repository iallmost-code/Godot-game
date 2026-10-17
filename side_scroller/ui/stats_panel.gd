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
    var stats=state.derived_stats()
    var columns=HBoxContainer.new()
    columns.add_theme_constant_override("separation",12)
    add_child(columns)
    var left=VBoxContainer.new()
    left.custom_minimum_size.x=460
    columns.add_child(left)
    left.add_child(Style.section("CHARACTER STATS"))
    Style.data_row(left,"JOB",preload("res://data/catalog.gd").jobs()[state.job].name,true)
    Style.data_row(left,"LEVEL",str(state.level),true)
    Style.data_row(left,"HP","%d / %d" % [state.hp,stats.max_hp],true)
    Style.data_row(left,"MP","%d / %d" % [state.mp,stats.max_mp],true)
    left.add_child(Style.section("ABILITY POINTS     %d available" % remaining_points()))
    for key in ["STR","DEX","INT","LUK"]:
        var row=HBoxContainer.new()
        left.add_child(row)
        var text=Style.label("%s   %d%s" % [key,state.attributes[key]," (+%d)" % draft[key] if draft.get(key,0)>0 else ""],15)
        text.custom_minimum_size.x=195
        row.add_child(text)
        for amount in [1,5,-1]:
            var button=Style.button("All" if amount==-1 else "+%d" % amount,func(): stage(key,amount))
            button.custom_minimum_size.x=76
            button.disabled=remaining_points()==0
            button.tooltip_text="Stage all remaining points in "+key if amount==-1 else "Stage up to %d points in %s" % [amount,key]
            row.add_child(button)
    var actions=HBoxContainer.new()
    left.add_child(actions)
    actions.add_child(Style.button("Confirm points",func(): confirm()))
    actions.add_child(Style.button("Cancel draft",cancel))
    left.add_child(Style.label(note if note!="" else "Points apply only after confirmation.",13))
    left.add_child(Style.label("STR: melee / HP   DEX: secondary damage
INT: mana   LUK: throwing / critical chance",13))
    var right=VBoxContainer.new()
    right.custom_minimum_size.x=355
    columns.add_child(right)
    right.add_child(Style.section("DETAILED STATS"))
    var proposed=state.attributes.duplicate()
    for key in draft: proposed[key]+=draft[key]
    var hp_gain=2*draft.get("STR",0)
    var mp_gain=2*draft.get("INT",0)
    var atk_gain=draft.get("LUK" if state.archetype=="thief" else "STR",0)+int(proposed.DEX/4.0)-int(state.attributes.DEX/4.0)
    var next_attack=stats.attack+atk_gain
    Style.data_row(right,"ATTACK","%d -> %d" % [stats.attack,next_attack])
    Style.data_row(right,"DEFENSE","%d -> %d" % [stats.defense,stats.defense+int(proposed.STR/10.0)-int(state.attributes.STR/10.0)])
    Style.data_row(right,"MAX HP","%d -> %d" % [stats.max_hp,stats.max_hp+hp_gain])
    Style.data_row(right,"MAX MP","%d -> %d" % [stats.max_mp,stats.max_mp+mp_gain])
    Style.data_row(right,"CRITICAL RATE","%.1f%% -> %.1f%%" % [stats.crit*100,minf(0.25,0.05+0.002*(proposed.LUK-4))*100])
    Style.data_row(right,"CRIT DAMAGE","150% of a normal hit")
    right.add_child(Style.section("DAMAGE PREVIEW",true))
    Style.data_row(right,"BASIC HIT",str(next_attack))
    Style.data_row(right,"BASIC CRIT",str(int(next_attack*1.5)))
    right.add_child(Style.label("Skill damage = attack × skill power.
Ranks add 15% base attack per rank.
Critical hits multiply the result by 1.5.
Preview includes pending points.",13))
