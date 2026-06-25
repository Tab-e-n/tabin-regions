shader_type canvas_item;
render_mode unshaded;

uniform vec2 scale = vec2(1.0, 1.0);
uniform bool changing_color = false;
uniform float n = 0;
uniform vec4 current_color: source_color = vec4(1, 1, 1, 1);
uniform vec4 previous_color: source_color = vec4(1, 1, 1, 1);

void fragment() {
	vec2 uv = UV * scale;
	float c = float(changing_color && (uv.y * 0.75 - uv.x * 0.25 + 0.25) > n);
	COLOR = texture(TEXTURE, UV) * (current_color * (1.0 - c) + previous_color * c);
}
