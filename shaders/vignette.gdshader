// Bölge renk filtresi: kenarları bölgenin renginde hafifçe karartan köşe gölgesi
shader_type canvas_item;

uniform vec4 tint : source_color = vec4(0.02, 0.02, 0.08, 1.0);
uniform float strength = 0.45;
uniform float inner = 0.55;

void fragment() {
	vec2 uv = UV - 0.5;
	uv.x *= 1.35;
	float d = length(uv);
	float v = smoothstep(inner, 0.95, d);
	COLOR = vec4(tint.rgb, v * strength);
}
