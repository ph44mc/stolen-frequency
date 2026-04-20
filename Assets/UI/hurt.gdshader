shader_type canvas_item;

uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;
uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
    vec4 texture_color = texture(TEXTURE, UV);
    
    // Смешиваем оригинальный цвет с цветом вспышки
    vec3 final_color = mix(texture_color.rgb, flash_color.rgb, flash_amount);
    
    COLOR = vec4(final_color, texture_color.a);
}