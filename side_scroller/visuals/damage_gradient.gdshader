shader_type canvas_item;
uniform vec4 top_color : source_color = vec4(1.0,0.16,0.02,1.0);
uniform vec4 mid_color : source_color = vec4(1.0,0.55,0.02,1.0);
uniform vec4 bottom_color : source_color = vec4(1.0,0.93,0.17,1.0);
uniform float text_height = 44.0;
varying float local_y;
void vertex() {
    local_y = VERTEX.y;
}
void fragment() {
    float t = clamp((local_y - text_height * 0.2) / (text_height * 0.65), 0.0, 1.0);
    vec3 fill = t < 0.5 ? mix(top_color.rgb, mid_color.rgb, t * 2.0) : mix(mid_color.rgb, bottom_color.rgb, (t - 0.5) * 2.0);
    COLOR = vec4(fill, COLOR.a);
}
