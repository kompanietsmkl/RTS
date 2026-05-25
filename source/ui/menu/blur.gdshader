shader_type canvas_item;

// Параметр размытия. В Godot 4 для этого используется уровень mipmap (lod).
uniform float blur_amount: hint_range(0.0, 5.0) = 2.5;

// Затемнение или цветовой фильтр поверх размытия
uniform float mix_amount: hint_range(0.0, 1.0) = 0.3;
uniform vec4 color_over: source_color = vec4(0.0, 0.0, 0.0, 1.0);

// В Godot 4 нужно явно объявлять SCREEN_TEXTURE
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

void fragment() {
	// Берем пиксель с экрана и применяем размытие через mipmap уровень (lod)
	vec4 blurred_color = texture(SCREEN_TEXTURE, SCREEN_UV, blur_amount);
	
	// Смешиваем размытый фон с полупрозрачным цветом (например, черным для затемнения)
	COLOR = mix(blurred_color, color_over, mix_amount);
}
