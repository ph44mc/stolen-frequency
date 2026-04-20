shader_type canvas_item;

uniform sampler2D mask_tex;

uniform vec4 base_color : source_color = vec4(0.2, 1.0, 0.4, 1.0);

uniform float speed : hint_range(0.0, 5.0) = 1.5;
uniform float swirl_strength : hint_range(0.0, 5.0) = 2.5;
uniform float noise_strength : hint_range(0.0, 2.0) = 0.25;

uniform int color_steps = 4;
uniform float core_size : hint_range(0.0, 0.5) = 0.18;


float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);

    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));

    vec2 u = f * f * (3.0 - 2.0 * f);

    return mix(a, b, u.x) +
           (c - a)* u.y * (1.0 - u.x) +
           (d - b) * u.x * u.y;
}

float posterize(float value, int steps) {
    return floor(value * float(steps)) / float(steps);
}

void fragment() {

    float mask = texture(mask_tex, UV).r;
    float edge = smoothstep(0.05, 0.15, mask);

    if (edge < 0.01) {
        discard;
    }

    vec2 uv = UV;
    vec2 center = vec2(0.5);
    vec2 pos = uv - center;

    float dist = length(pos);

    float angle = atan(pos.y, pos.x);
    float swirl = swirl_strength * (1.0 - dist);
    angle += swirl + TIME * speed;

    vec2 rotated = vec2(cos(angle), sin(angle)) * dist;

    float n = noise(rotated * 5.0 + TIME);
    rotated += (n - 0.5) * noise_strength;

    vec2 final_uv = clamp(center + rotated, vec2(0.0), vec2(1.0));
    float final_dist = length(final_uv - center);

    float bands = posterize(final_dist, color_steps);

    // 👉 вариации одного цвета
    float intensity;

    if (bands < 0.25)
        intensity = 0.2;
    else if (bands < 0.5)
        intensity = 1.2;
    else if (bands < 0.75)
        intensity = 0.7;
    else
        intensity = 1.5;

    vec3 col = base_color.rgb * intensity;

    float lines = step(0.85, sin(final_dist * 25.0 - TIME * 5.0));
    col += lines * 0.15;

    float core = step(final_dist, core_size);
    col = mix(col, vec3(0.0), core);

    float glow = smoothstep(0.7, 1.0, final_dist);
    col += base_color.rgb * glow * 1.5;

    COLOR = vec4(col, edge);
}