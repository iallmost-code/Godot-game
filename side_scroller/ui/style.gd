extends RefCounted
static func label(text: String,size=17,color=Color("e9f1e9")) -> Label:
    var node=Label.new()
    node.text=text
    node.add_theme_font_size_override("font_size",size)
    node.add_theme_color_override("font_color",color)
    return node
static func button(text: String,callback: Callable) -> Button:
    var node=Button.new()
    node.text=text
    node.focus_mode=Control.FOCUS_NONE
    node.custom_minimum_size=Vector2(90,34)
    node.pressed.connect(callback)
    return node
static func clear(node: Node):
    for child in node.get_children():
        node.remove_child(child)
        child.queue_free()
static func theme() -> Theme:
    var value=Theme.new()
    value.default_font_size=17
    for type in ["Button","PanelContainer","TabContainer"]:
        for state in ["normal","hover","pressed","disabled","panel"]:
            var style=StyleBoxFlat.new()
            style.bg_color=Color("243e48") if state=="normal" else Color("345b60")
            if state=="disabled": style.bg_color=Color("293c43")
            if type=="PanelContainer": style.bg_color=Color("182c38")
            style.border_color=Color("649a96")
            style.set_border_width_all(1)
            style.set_corner_radius_all(9)
            style.content_margin_left=13
            style.content_margin_right=13
            style.content_margin_top=9
            style.content_margin_bottom=9
            value.set_stylebox(state,type,style)
    value.set_color("font_color","Button",Color("f6efd6"))
    value.set_color("font_disabled_color","Button",Color("84979a"))
    value.set_color("font_color","Label",Color("e9f1e9"))
    return value
