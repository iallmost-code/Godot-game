extends VBoxContainer
const Quality=preload("res://data/loot_quality.gd")
const Catalog=preload("res://data/catalog.gd")
const Maps=preload("res://data/maps.gd")
const Style=preload("res://ui/style.gd")
const ItemText=preload("res://ui/item_text.gd")
const Adventure=preload("res://data/adventure.gd")
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
func sort_bag(mode: String):
    state.sort_inventory(mode)
    note="Sorted by "+mode+". Locked and rare gear are kept out of bulk cleanup."
    refresh()
func toggle_lock():
    var inst=state.instance(selected_uid)
    if inst.is_empty():return
    state.set_item_locked(selected_uid,not inst.get("locked",false))
    note="Item locked. It cannot be sold or dismantled." if inst.locked else "Item unlocked."
    refresh()
func use_scroll(id: String):
    var inst=state.instance(selected_uid)
    if inst.is_empty(): return
    var before=ItemText.stats_line(state,inst)
    var result=state.apply_scroll(selected_uid,id)
    match result:
        "success": note="The scroll shone brightly! %s  →  %s" % [before,ItemText.stats_line(state,state.instance(selected_uid))]
        "fail": note="The scroll failed. An upgrade slot was used up." if id!="scroll_clean" else "The Clean Slate fizzled."
        _: note=result
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
    var sort_row=HFlowContainer.new()
    add_child(sort_row)
    sort_row.add_child(Style.label("SORT:",13))
    for mode in ["level","rarity","slot"]:
        sort_row.add_child(Style.button(mode.capitalize(),func(): sort_bag(mode)))
    sort_row.add_child(Style.label("Double-click to equip • Rare / epic gear stays out of bulk cleanup",12))
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
        button.tooltip_text=ItemText.title(inst)+"\n"+ItemText.stats_line(state,inst)+"\n"+ItemText.requirement(state,inst)+"\n"+ItemText.compare(state,inst)
        button.add_theme_stylebox_override("normal",Style.box(Quality.color(inst).lightened(0.55),Quality.color(inst,true),3,3))
        if inst.get("locked",false):button.text="\n\nLOCKED"
        button.gui_input.connect(func(event):
            if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.double_click:
                selected_uid=inst.uid
                act("equip"))
        if state.equip_problem(inst.id)!="": button.modulate=Color(1,0.85,0.85)
        if inst.uid==selected_uid: button.add_theme_stylebox_override("normal",Style.box(Color("e6f3bd"),Color("87ad36"),3,5))
        grid.add_child(button)
    add_child(Style.section("SELECTED ITEM",true))
    var inst=state.instance(selected_uid)
    if not inst.is_empty():
        var title=Style.label(ItemText.title(inst),16,Quality.color(inst,true))
        title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
        add_child(title)
        var stats_label=Style.label(ItemText.stats_line(state,inst),14)
        stats_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
        add_child(stats_label)
        var comparison=Style.label(ItemText.requirement(state,inst)+"\n"+ItemText.compare(state,inst),13)
        comparison.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
        add_child(comparison)
        add_child(Style.label("%s  •  Sells for %d coins  •  Dismantles into %d Shards" % [ItemText.upgrades(state,inst),state.sell_value(inst),state.shard_yield(inst)],13))
        var usable=HBoxContainer.new()
        for id in Adventure.scrolls():
            if int(state.scrolls.get(id,0))<=0: continue
            var info=Adventure.scrolls()[id]
            if info.slot!="" and info.slot!=Catalog.items()[inst.id].slot: continue
            var scroll_id=id
            var button=Style.button("%s (%d)" % [info.name,state.scrolls[id]],func(): use_scroll(scroll_id))
            var problem=state.scroll_problem(selected_uid,id)
            button.disabled=problem!=""
            button.tooltip_text=info.text if problem=="" else problem
            button.add_theme_font_size_override("font_size",13)
            usable.add_child(button)
        if usable.get_child_count()>0:
            add_child(Style.label("Use a scroll on this item:",13,Color("7e6539")))
            add_child(usable)
        else: usable.free()
        var row=HBoxContainer.new()
        add_child(row)
        var worn_now=state.is_equipped(inst.uid)
        var slot=Catalog.items()[inst.id].slot
        var equip=Style.button("Unequip" if worn_now else "Equip",func(): act("unequip" if worn_now else "equip"))
        equip.disabled=worn_now and slot=="weapon" or not worn_now and state.equip_problem(inst.id)!=""
        row.add_child(equip)
        row.add_child(Style.button("Unlock" if inst.get("locked",false) else "Lock item",toggle_lock))
        var sell=Style.button("Sell",func(): act("sell"))
        sell.disabled=worn_now or not in_town() or inst.get("locked",false)
        sell.tooltip_text="Sell at a town Merchant." if not in_town() else "Sell for coins."
        row.add_child(sell)
        var dismantle=Style.button("Dismantle",func(): act("dismantle"))
        dismantle.disabled=worn_now or inst.get("locked",false)
        row.add_child(dismantle)
        var worse=state.worse_gear().size()
        var bulk_sell=Style.button("Sell worse gear (%d)" % worse,func(): bulk("sell"))
        bulk_sell.disabled=worse==0 or not in_town()
        row.add_child(bulk_sell)
        var bulk_dismantle=Style.button("Dismantle worse gear (%d)" % worse,func(): bulk("dismantle"))
        bulk_dismantle.disabled=worse==0
        row.add_child(bulk_dismantle)
    if not state.scrolls.is_empty():
        add_child(Style.section("SCROLLS",true))
        var scroll_row=HFlowContainer.new()
        add_child(scroll_row)
        for id in state.scrolls:
            var cell=HBoxContainer.new()
            var art=preload("res://ui/scroll_icon.gd").new()
            art.scroll_id=id
            art.custom_minimum_size=Vector2(26,26)
            cell.add_child(art)
            var text=Style.label("%s ×%d" % [Adventure.scrolls()[id].name,state.scrolls[id]],13)
            text.tooltip_text=Adventure.scrolls()[id].text
            text.mouse_filter=Control.MOUSE_FILTER_PASS
            cell.add_child(text)
            scroll_row.add_child(cell)
    add_child(Style.label(note if note!="" else "Click an item, then Equip. Sell at a town Merchant; dismantle anywhere for Shards used by the Forge.",13,Color("25758a")))
