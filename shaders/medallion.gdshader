shader_type spatial;
render_mode unshaded, depth_test_disabled, depth_draw_never, cull_disabled, shadows_disabled;
// Kapı madalyonu: kameraya dönük yuvarlak lacivert disk, altın çerçeve ve ödül renginde hafif hale.

uniform vec3 tint : source_color = vec3(1.0, 0.85, 0.45);

void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
}

void fragment() {
	float r = length(UV - vec2(0.5)) * 2.0;
	if (r > 1.0) {
		discard;
	}
	vec3 navy = vec3(0.035, 0.055, 0.16);
	vec3 gold = vec3(0.95, 0.82, 0.45);
	vec3 c = navy;
	float a = 0.94;
	// iç ince altın çizgi
	float inner = smoothstep(0.70, 0.72, r) - smoothstep(0.735, 0.755, r);
	c = mix(c, gold, inner * 0.8);
	// kalın altın çerçeve
	float ring = smoothstep(0.80, 0.82, r);
	c = mix(c, gold * 1.15, ring);
	// çerçevenin dışında ödül renginde hale
	float halo = smoothstep(0.93, 0.95, r);
	c = mix(c, tint * 1.6, halo);
	a = mix(a, 0.55 * (1.0 - smoothstep(0.95, 1.0, r)), halo);
	// diskin içinde ödül renginde yumuşak parıltı
	c += tint * (1.0 - smoothstep(0.0, 0.7, r)) * 0.12;
	ALBEDO = c;
	ALPHA = a;
}
