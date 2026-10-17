shader_type canvas_item;
// Multiplies the skin areas of a neutral body sheet by the chosen skin tone.
// The mask is softened with a small blur so speckles in it do not show.
uniform sampler2D mask : filter_linear;
uniform vec4 skin : source_color = vec4(1.0);
void fragment() {
    vec4 base = texture(TEXTURE, UV);
    vec2 step_size = TEXTURE_PIXEL_SIZE * 2.0;
    float m = 0.0;
    for (int x = -1; x <= 1; x++) {
        for (int y = -1; y <= 1; y++) {
            m += texture(mask, UV + vec2(float(x), float(y)) * step_size).r;
        }
    }
    m /= 9.0;
    base.rgb *= mix(vec3(1.0), skin.rgb, clamp(m * 1.3, 0.0, 1.0));
    COLOR = base * COLOR;
}
