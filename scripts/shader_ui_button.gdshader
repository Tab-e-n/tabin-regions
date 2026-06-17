shader_type canvas_item;
render_mode unshaded;

uniform float value = 0.0;
uniform sampler2D mask : hint_default_black;

void fragment() {
	float c = float(texture(mask, UV).b >= 0.5 && value <= 0.85);
	COLOR = COLOR * (1.0 - c) + vec4(c, c, c, c);
}
