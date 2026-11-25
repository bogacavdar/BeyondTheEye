shader_type spatial;
render_mode cull_disabled, depth_draw_opaque;
// Gezegen halkası (PlaneMesh üzerine): iç/dış yarıçap arasında ince halkacıklar ve boşluklar

uniform float inner = 0.55;   // UV yarıçapı (0..0.5 dış kenar = 0.5)
uniform vec3 col_a : source_color = vec3(0.85, 0.75, 0.55);
uniform vec3 col_b : source_color = vec3(0.6, 0.5, 0.35);
uniform float opacity = 0.9;
uniform float gap_at = 0.78;  // Cassini boşluğu (inner..1 arası oran)
uniform float gap_w = 0.04;
uniform float bands = 40.0;

void fragment() {
	float r = length(UV - vec2(0.5)) * 2.0;   // 0 merkez, 1 dış kenar
	if (r > 1.0 || r < inner) {
		discard;
	}
	float f = (r - inner) / (1.0 - inner);
	float ringlets = sin(f * bands) * 0.5 + 0.5;
	ringlets = mix(ringlets, sin(f * bands * 3.7 + 1.0) * 0.5 + 0.5, 0.4);
	vec3 c = mix(col_b, col_a, ringlets);
	float a = opacity * (0.55 + 0.45 * ringlets);
	a *= smoothstep(0.0, 0.06, f) * (1.0 - smoothstep(0.9, 1.0, f));
	a *= 1.0 - (1.0 - smoothstep(0.0, gap_w, abs(f - gap_at))) * 0.92;
	ALBEDO = c;
	ALPHA = a;
	ROUGHNESS = 1.0;
	EMISSION = c * 0.1;
}
