extends VBoxContainer
const Catalog=preload("res://data/catalog.gd")
const Style=preload("res://ui/style.gd")
var state
var selected=""
func bind(s):
    state=s
    selected=state.equipment.weapon
    refresh()
func refresh():
    Style.clear(self)
    add_child(Style.section("EQUIPMENT INVENTORY"))
    var columns=HBoxContainer.new()
    columns.add_theme_constant_override("separation",14)
    add_child(columns)
    var worn=VBoxContainer.new()
    worn.custom_minimum_size.x=242
    columns.add_child(worn)
    worn.add_child(Style.section("EQUIPPED",true))
    for slot in ["weapon","armor"]:
        var item=Catalog.items()[state.equipment[slot]]
        var card=PanelContainer.new()
        worn.add_child(card)
        var layout=VBoxContainer.new()
        card.add_child(layout)
        layout.add_child(Style.label(slot.to_upper(),12))
        layout.add_child(Style.label(item.name,16))
        layout.add_child(Style.label("ATK +%d" % item.attack if slot=="weapon" else "DEF +%d" % item.defense,14))
    Style.data_row(worn,"COINS",str(state.coins),true)
    Style.data_row(worn,"POTIONS",str(state.potions),true)
    var bag=VBoxContainer.new()
    columns.add_child(bag)
    bag.add_child(Style.section("EQUIP  /  %d items" % state.inventory.size()))
    var grid=GridContainer.new()
    grid.columns=6
    grid.add_theme_constant_override("h_separation",5)
    grid.add_theme_constant_override("v_separation",5)
    bag.add_child(grid)
    for index in range(maxi(24,state.inventory.size())):
        if index>=state.inventory.size():
            var empty=PanelContainer.new()
            empty.custom_minimum_size=Vector2(87,68)
            empty.add_theme_stylebox_override("panel",Style.box(Color("dbe4e6"),Color("bac8c7"),2,2))
            grid.add_child(empty)
            continue
        var id=state.inventory[index]
        var item=Catalog.items()[id]
        var equipped=state.equipment[item.slot]==id
        var button=Style.button("\n\n"+("WORN" if equipped else "ATK %d" % item.attack if item.slot=="weapon" else "DEF %d" % item.defense),func(): selected=id; refresh())
        button.custom_minimum_size=Vector2(87,68)
        var icon=preload("res://ui/item_icon.gd").new()
        icon.item_id=id
        icon.mouse_filter=Control.MOUSE_FILTER_IGNORE
        icon.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
        icon.offset_top=4
        icon.offset_bottom=45
        button.add_child(icon)
        button.tooltip_text=item.name+"\nClick to inspect and equip"
        if id==selected: button.add_theme_stylebox_override("normal",Style.box(Color("e6f3bd"),Color("87ad36"),3,5))
        grid.add_child(button)
    add_child(Style.section("SELECTED ITEM",true))
    if Catalog.items().has(selected):
        var item=Catalog.items()[selected]
        var row=HBoxContainer.new()
        add_child(row)
        var text=Style.label(item.name+"   •   "+("ATK +%d" % item.attack if item.slot=="weapon" else "DEF +%d" % item.defense),16)
        text.custom_minimum_size.x=510
        row.add_child(text)
        var equipped=state.equipment[item.slot]==selected
        var other_class=item.get("path",state.archetype)!=state.archetype
        var equip=Style.button("Other class" if other_class else "Equipped" if equipped else "Equip",func(): state.equip(selected); refresh())
        equip.disabled=equipped or other_class
        row.add_child(equip)
    add_child(Style.label("Select an item in the grid, then Equip. Bonuses apply once. Collect loot by walking over it.",13))
