extends Node2D
const FONT=preload("res://fonts/damage-bold.ttf")
const GRADIENT=preload("res://visuals/damage_gradient.gdshader")
func setup(text: String,critical: bool,celebration=false):
    var font_size=40 if critical else 34
    if celebration: font_size=30
    var width=FONT.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x
    # Two separate outline layers keep the dark silhouette and white rim intact
    # while only the foreground glyphs receive the vertical color gradient.
    for outline in [10,5,0]:
        var label=Label.new()
        label.text=text
        label.position=Vector2(-width/2,-font_size)
        label.mouse_filter=Control.MOUSE_FILTER_IGNORE
        label.add_theme_font_override("font",FONT)
        label.add_theme_font_size_override("font_size",font_size)
        label.add_theme_constant_override("outline_size",outline)
        label.add_theme_color_override("font_outline_color",Color("291e30") if outline==10 else Color("fffbe8"))
        label.add_theme_color_override("font_color",Color.WHITE)
        if outline==0:
            var gradient=ShaderMaterial.new()
            gradient.shader=GRADIENT
            gradient.set_shader_parameter("text_height",font_size*1.2)
            if critical:
                gradient.set_shader_parameter("top_color",Color("860626"))
                gradient.set_shader_parameter("mid_color",Color("d70b39"))
                gradient.set_shader_parameter("bottom_color",Color("f84770"))
            if celebration:
                gradient.set_shader_parameter("top_color",Color("ffb626"))
                gradient.set_shader_parameter("mid_color",Color("fff082"))
                gradient.set_shader_parameter("bottom_color",Color("fffed7"))
            label.material=gradient
        add_child(label)
