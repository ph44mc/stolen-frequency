shader_type canvas_item;

uniform float speed : hint_range(0.0, 2.0) = 0.8;
uniform float pattern_scale : hint_range(1.0, 20.0) = 6.0;
uniform float iridescence_strength : hint_range(0.0, 1.0) = 0.6;
uniform float fade_amount : hint_range(0.0, 1.0) = 1.0;
uniform int pattern_mode : hint_range(0, 5) = 0;
uniform float saturation : hint_range(0.0, 2.0) = 0.6;  // Насыщенность (0.6=пастель)

float smooth_noise(vec2 uv) {
    vec2 i = floor(uv);
    vec2 f = smoothstep(0.0, 1.0, fract(uv));
    float a = sin(dot(i + vec2(0.0, 0.0), vec2(12.9898, 78.233))) * 0.5 + 0.5;
    float b = sin(dot(i + vec2(1.0, 0.0), vec2(12.9898, 78.233))) * 0.5 + 0.5;
    float c = sin(dot(i + vec2(0.0, 1.0), vec2(12.9898, 78.233))) * 0.5 + 0.5;
    float d = sin(dot(i + vec2(1.0, 1.0), vec2(12.9898, 78.233))) * 0.5 + 0.5;
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(a, b, u.x) + (c - a)*u.y*(1.0 - u.x) + (d - b)*u.x*u.y;
}

vec3 rgb2hsv(vec3 c) {
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

float pattern(vec2 uv, float time) {
    uv *= pattern_scale;
    
    if (pattern_mode == 0) return sin(uv.x * 2.5 + time) * sin(uv.y * 3.0 + time * 0.8) * 0.5 + 0.5;
    else if (pattern_mode == 1) {
        float angle = atan(uv.y, uv.x) + time * 0.5;
        float radius = length(uv);
        return sin(angle * 5.0 + radius * 3.0 - time) * 0.5 + 0.5;
    } else if (pattern_mode == 2) {
        vec2 grid = abs(fract(uv * 0.5) - 0.5) / fwidth(uv * 0.5);
        return 1.0 - smoothstep(0.0, 1.0, max(grid.x, grid.y)) * smooth_noise(uv + time);
    } else if (pattern_mode == 3) {
        float feather = sin(uv.x * 12.0 + time * 2.0) * 0.5 + 0.5;
        float density = sin(uv.y * 6.0 - time * 1.5 + uv.x * 0.5) * 0.5 + 0.5;
        return smoothstep(0.3, 0.7, feather) * density;
    } else if (pattern_mode == 4) {
        uv *= 0.8;
        vec2 p = mod(uv, 1.0) - 0.5;
        float hex = max(abs(p.x), abs(p.y + p.x * 0.5) + p.y * 0.866) - 0.25;
        float crystal = 1.0 - smoothstep(0.0, 0.1, abs(hex) + sin(time + floor(uv.x + uv.y) * 0.3) * 0.05);
        return crystal * 0.7 + 0.3;
    } else {
        float n1 = smooth_noise(uv * 1.0 + time * 0.1);
        float n2 = smooth_noise(uv * 2.1 + time * 0.2) * 0.5;
        float n3 = smooth_noise(uv * 4.2 - time * 0.15) * 0.25;
        return (n1 + n2 + n3) * 0.666 + 0.333;
    }
}

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);
    
    vec2 screen_uv = SCREEN_UV;
    float time = TIME * speed;
    
    float pat = pattern(screen_uv, time);
    float noise = smooth_noise(screen_uv * pattern_scale * 0.5 + time * 0.1);
    float mask = (pat + noise * 0.3) * 0.7 + 0.3;
    
    // Волны для UV
    vec2 waved_uv = screen_uv * 0.6;
    waved_uv.x += sin(screen_uv.y * 2.5 + time * 0.25) * 0.08;
    waved_uv.y += sin(screen_uv.x * 2.8 + time * 0.2) * 0.08;
	    
	// ЖЁЛТЫЙ градиент
	float brightness = sin(waved_uv.x * 100.0 + time) * 0.2 + 0.1;
	float variation = sin(waved_uv.y * 3.0 - time * 0.7) * 0.1;

	// базовый жёлтый
	vec3 iridescent = vec3(1.2, 1.5, 1.2);

	// добавляем вариации (золото / янтарь)
	iridescent *= brightness + variation;
    
    // HSV: пастель (низкая насыщенность) + тени
    vec3 hsv = rgb2hsv(iridescent);
    hsv.y *= saturation;  // Пастельная насыщенность
    hsv.z *= mask * 1.5;  // Тёмные части = тени (0.0-1.5)
    hsv.z = clamp(hsv.z, 0.2, 1.0);  // Минимум яркости
    iridescent = hsv2rgb(hsv);
    
    // Микс
    vec3 final_color = mix(tex_color.rgb, iridescent * COLOR.a, iridescence_strength * tex_color.a);
    final_color *= COLOR.rgb;
    
    COLOR = vec4(final_color, tex_color.a * fade_amount);
}