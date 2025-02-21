shader_type canvas_item;
render_mode unshaded;

uniform float radi = 0.33;
uniform float size = 10.0; // 1 / radi
uniform float threshold = 0.5;
uniform vec4 color = vec4(1, 1, 1, 1);

void fragment() {
	COLOR.rgb = vec3(1.0, 1.0, 1.0);
	vec2 pos = UV;
	pos -= vec2(0.5, 0.5);
	float dist = sqrt(pos.x * pos.x + pos.y * pos.y);
	if(texture(TEXTURE, UV).r - abs(radi - dist) * size < threshold)
	{
		COLOR.a = 0.0;
	}
	COLOR *= color;
}
