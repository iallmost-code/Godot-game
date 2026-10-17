extends VBoxContainer
const Catalog=preload("res://data/catalog.gd")
const Maps=preload("res://data/maps.gd")
const Style=preload("res://ui/style.gd")
const ItemText=preload("res://ui/item_text.gd")
var state
var selected_uid=0
var map_id="town"
var note=""
func bind(s):
    state=s
    selected_uid=state.equipped.get("weapon",0)
    refresh()
func set_context(id: String):
    map_id=id
    refresh()
func in_town() -> bool: return Maps.definition(map_id).get("safe",false)
func select(uid: int):
    selected_uid=uid
    note=""
    refresh()
func act(kind: String):
    var inst=state.instance(selected_uid)
    if inst.is_empty(): return
    var name=ItemText.title(inst)
    match kind:
        "equip": note=("Equipped %s." % name) if state.equip(selected_uid) else state.equip_problem(inst.id)
        "unequip": note=("Took off %s." % name) if state.unequip(Catalog.items()[inst.id].slot) else "Your weapon cannot be removed."
        "sell":
            var coins=state.sell(selected_uid) if in_town() else 0
            note=("Sold %s for %d coins." % [name,coins]) if coins>0 else "Sell at a town Merchant. Worn gear cannot be sold."
            if coins>0: selected_uid=state.equipped.get("weapon",0)
        "dismantle":
            var shards=state.dismantle(selected_uid)
            note=("Dismantled %s into %d Shards." % [name,shards]) if shards>0 else "Take it off before dismantling."
            if shards>0: selected_uid=state.equipped.get("weapon",0)
    refresh()
func bulk(kind: String):
    var total=0
    var count=0
    for uid in state.worse_gear():
        var gained=state.sell(uid) if kind=="sell" else state.dismantle(uid)
        if gained>0:
            total+=gained
            count+=1
    note=("%s %d items for %d %s." % ["Sold" if kind=="sell" else "Dismantled",count,total,"coins" if kind=="sell" else "Shards"]) if count>0 else "Nothing weaker than your worn gear."
    selected_uid=state.equipped.get("weapon",0)
    refresh()
func icon_for(id: String) -> Control:
    var icon=preload("res://ui/item_icon.gd").new()
    icon.item_id=id
    icon.mouse_filter=Control.MOUSE_FILTER_IGNORE
    icon.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
    icon.offset_top=4
    icon.offset_bottom=45
    return icon
func refresh():
    Style.clear(self)
    add_child(Style.section("EQUIPMENT INVENTORY  /  %d of %d slots  •  Coins %d  •  Shards %d" % [state.inventory.size(),state.INVENTORY_LIMIT,state.coins,state.shards]))
    var columns=HBoxContainer.new()
    columns.add_theme_constant_override("separation",12)
    add_child(columns)
    var worn=VBoxContainer.new()
    worn.custom_minimum_size.x=230
    worn.add_theme_constant_override("separation",3)
    columns.add_child(worn)
    worn.add_child(Style.section("WORN",true))
    for slot in Catalog.GEAR_SLOTS:
        var inst=state.instance(state.equipped.get(slot,0))
        var text="%s: %s" % [ItemText.SLOT_NAMES[slot],ItemText.title(inst) if not inst.is_empty() else "—"]
        var button=Style.button(text,func(): if not inst.is_empty(): select(inst.uid))
        button.alignment=HORIZONTAL_ALIGNMENT_LEFT
        button.clip_text=true
        button.custom_minimum_size=Vector2(226,30)
        if not inst.is_empty() and inst.uid==selected_uid: button.add_theme_stylebox_override("normal",Style.box(Color("e6f3bd"),Color("87ad36"),3,5))
        worn.add_child(button)
    worn.add_child(Style.label("HP tonics %d  •  MP tonics %d" % [state.count_potions("hp"),state.count_potions("mp")],13))
    var bag=VBoxContainer.new()
    columns.add_child(bag)
    var grid=GridContainer.new()
    grid.columns=7
    grid.add_theme_constant_override("h_separation",4)
    grid.add_theme_constant_override("v_separation",4)
    bag.add_child(grid)
    for index in range(maxi(21,state.inventory.size())):
        if index>=state.inventory.size():
            var empty=PanelContainer.new()
            empty.custom_minimum_size=Vector2(84,64)
            empty.add_theme_stylebox_override("panel",Style.box(Color("dbe4e6"),Color("bac8c7"),2,2))
            grid.add_child(empty)
            continue
        var inst=state.inventory[index]
        var item=Catalog.items()[inst.id]
        var problem=state.equip_problem(inst.id)
        var tag="WORN" if state.is_equipped(inst.uid) else ("" if problem=="" else "Lv %d" % item.req if problem.begins_with("Requires") else "Other class")
        var button=Style.button("\n\n"+("+%d " % inst.plus if inst.plus>0 else "")+tag,func(): select(inst.uid))
        button.custom_minimum_size=Vector2(84,64)
        button.add_theme_font_size_override("font_size",12)
        button.add_child(icon_for(inst.id))
        button.tooltip_text=ItemText.title(inst)+"\n"+ItemText.stats_line(state,inst)
        if state.equip_problem(inst.id)!="": button.modulate=Color(1,0.85,0.85)
        if inst.uid==selected_uid: button.add_theme_stylebox_override("normal",Style.box(Color("e6f3bd"),Color("87ad36"),3,5))
        grid.add_child(button)
    add_child(Style.section("SELECTED ITEM",true))
    var inst=state.instance(selected_uid)
    if not inst.is_empty():
        add_child(Style.label(ItemText.title(inst)+"   •   "+ItemText.stats_line(state,inst),16))
        add_child(Style.label(ItemText.requirement(state,inst)+"   •   "+ItemText.compare(state,inst),13))
        add_child(Style.label("Sells for %d coins  •  Dismantles into %d Shards" % [state.sell_value(inst),state.shard_yield(inst)],13))
        var row=HBoxContainer.new()
        add_child(row)
        var worn_now=state.is_equipped(inst.uid)
        var slot=Catalog.items()[inst.id].slot
        var equip=Style.button("Unequip" if worn_now else "Equip",func(): act("unequip" if worn_now else "equip"))
        equip.disabled=worn_now and slot=="weapon" or not worn_now and state.equip_problem(inst.id)!=""
        row.add_child(equip)
        var sell=Style.button("Sell",func(): act("sell"))
        sell.disabled=worn_now or not in_town()
        sell.tooltip_text="Sell at a town Merchant." if not in_town() else "Sell for coins."
        row.add_child(sell)
        var dismantle=Style.button("Dismantle",func(): act("dismantle"))
        dismantle.disabled=worn_now
        row.add_child(dismantle)
        var worse=state.worse_gear().size()
        var bulk_sell=Style.button("Sell worse gear (%d)" % worse,func(): bulk("sell"))
        bulk_sell.disabled=worse==0 or not in_town()
        row.add_child(bulk_sell)
        var bulk_dismantle=Style.button("Dismantle worse gear (%d)" % worse,func(): bulk("dismantle"))
        bulk_dismantle.disabled=worse==0
        row.add_child(bulk_dismantle)
    add_child(Style.label(note if note!="" else "Click an item, then Equip. Sell at a town Merchant; dismantle anywhere for Shards used by the Forge.",13,Color("25758a")))
