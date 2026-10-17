extends RefCounted
const INK=Color("354454")
static func label(text: String,size=15,color=INK) -> Label:
    var node=Label.new()
    node.text=text
    node.add_theme_font_size_override("font_size",size)
    var remap={Color("f4d48a"):Color("536623"),Color("acc6c6"):Color("617180"),Color("e8cf8e"):Color("656c35"),Color("bfaee5"):Color("71598b"),Color("bba8dc"):Color("71598b"),Color("8ed9d0"):Color("25758a"),Color("e1bf83"):Color("7e6539")}
    node.add_theme_color_override("font_color",remap.get(color,color))
    return node
static func button(text: String,callback: Callable) -> Button:
    var node=Button.new()
    node.text=text
    node.focus_mode=Control.FOCUS_NONE
    node.custom_minimum_size=Vector2(76,28)
    node.pressed.connect(callback)
    return node
static func clear(node: Node):
    for child in node.get_children():
        node.remove_child(child)
        child.queue_free()
static func box(background: Color,border=Color("9ba9b6"),radius=4,margin=7) -> StyleBoxFlat:
    var style=StyleBoxFlat.new()
    style.bg_color=background
    style.border_color=border
    style.set_border_width_all(2)
    style.set_corner_radius_all(radius)
    style.content_margin_left=margin
    style.content_margin_right=margin
    style.content_margin_top=margin
    style.content_margin_bottom=margin
    return style
static func section(text: String,green=false) -> PanelContainer:
    var panel=PanelContainer.new()
    panel.add_theme_stylebox_override("panel",box(Color("97bf31") if green else Color("65a7cd"),Color("c8df94") if green else Color("9bcce5"),3,5))
    var title=label(text,14,Color.WHITE)
    title.add_theme_constant_override("outline_size",2)
    title.add_theme_color_override("font_outline_color",Color("52743a") if green else Color("43728f"))
    panel.add_child(title)
    return panel
static func data_row(parent: Node,title: String,value: String,green=false):
    var row=HBoxContainer.new()
    row.add_theme_constant_override("separation",2)
    parent.add_child(row)
    var name_panel=PanelContainer.new()
    name_panel.custom_minimum_size.x=116
    name_panel.add_theme_stylebox_override("panel",box(Color("acd34d") if green else Color("d2d9de"),Color("c0c9ce"),2,4))
    name_panel.add_child(label(title,13,Color("3e5424") if green else Color("52606a")))
    row.add_child(name_panel)
    var data_panel=PanelContainer.new()
    data_panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL
    data_panel.add_theme_stylebox_override("panel",box(Color("fafcfd"),Color("d7dde1"),2,4))
    data_panel.add_child(label(value,14))
    row.add_child(data_panel)
static func theme() -> Theme:
    var value=Theme.new()
    value.default_font_size=15
    value.set_color("font_color","Label",INK)
    value.set_constant("separation","VBoxContainer",5)
    value.set_constant("separation","HBoxContainer",5)
    value.set_stylebox("panel","PanelContainer",box(Color("edf1f3"),Color("84919d"),6,9))
    for state in ["normal","hover","pressed","disabled","focus"]:
        var color=Color("e8f0f5")
        if state=="hover": color=Color("cbe6f4")
        if state=="pressed": color=Color("a8cbdf")
        if state=="disabled": color=Color("dfe3e6")
        value.set_stylebox(state,"Button",box(color,Color("9cabb7"),4,5))
    value.set_color("font_color","Button",INK)
    value.set_color("font_hover_color","Button",Color("1f5775"))
    value.set_color("font_pressed_color","Button",INK)
    value.set_color("font_disabled_color","Button",Color("9ba5ad"))
    value.set_stylebox("normal","TooltipPanel",box(Color("fffde7"),Color("7f8995"),4,8))
    value.set_color("font_color","TooltipLabel",INK)
    return value
