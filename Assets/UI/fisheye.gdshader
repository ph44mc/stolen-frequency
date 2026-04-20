shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

uniform float strength : hint_range(0.0, 2.0) = 0.8;

void fragment() {
    vec2 uv = SCREEN_UV;

    vec2 center = vec2(0.5);
    vec2 offset = uv - center;

    float dist = length(offset);

    // 🔻 ВОГНУТЫЙ эффект (ключевая часть)
    float factor = 1.0 / (1.0 + strength * dist * dist);

    offset *= factor;

    uv = center + offset;

    COLOR = texture(SCREEN_TEXTURE, uv);
}