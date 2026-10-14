extends VBoxContainer
const Catalog=preload("res://data/catalog.gd")
var state
func bind(s):
    state=s
    refresh()
func refresh():
    for child in get_children():
        remove_child(child)
        child.queue_free()
    var title=Label.new()
    title.text="YOUR EQUIPMENT   •   %d coins" % state.coins
    title.add_theme_font_size_override("font_size",21)
    add_child(title)
    for id in state.inventory:
        var item=Catalog.items()[id]
        var row=HBoxContainer.new()
        add_child(row)
        var text=Label.new()
        text.custom_minimum_size.x=390
        text.text="%s   %s  |  %s +%d" % [item.icon,item.name,"ATK" if item.slot=="weapon" else "DEF",item.attack if item.slot=="weapon" else item.defense]
        row.add_child(text)
        var button=Button.new()
        var equipped=state.equipment[item.slot]==id
        button.text="Equipped" if equipped else "Equip"
        button.disabled=equipped or item.get("path",state.archetype)!=state.archetype
        if item.get("path",state.archetype)!=state.archetype: button.text="Other class"
        button.pressed.connect(func(): state.equip(id); refresh())
        row.add_child(button)
    var info=Label.new()
    info.text="Weapon and armor bonuses are applied once.\nWalk over forest drops to collect coins, potions, and equipment."
    add_child(info)
