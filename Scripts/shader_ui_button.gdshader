shader_type canvas_item;
render_mode unshaded;

uniform float value = 0.0;
uniform sampler2D mask : hint_default_black;

void fragment() {
	vec4 m_color = texture(mask, UV);
	if(m_color.b >= 0.5 && value <= 0.85)
	{
		COLOR = vec4(1, 1, 1, 1);
	}
}
