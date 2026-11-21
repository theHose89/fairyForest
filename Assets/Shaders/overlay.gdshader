shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform float pixel_size : hint_range(1.0, 20.0, 1.0) = 4.0;

void fragment() {
	vec2 texture_size = 1.0 / SCREEN_PIXEL_SIZE;
	vec2 pixel_count = texture_size / (pixel_size * 1.0);
	vec2 pixel_UV = (floor(SCREEN_UV * pixel_count) + 0.5) / pixel_count;
	COLOR = texture(screen_texture, pixel_UV);
}