// KONTUR: ters kabuk yöntemi. Modelin arka yüzleri ekran uzayında normal yönünde biraz dışarı itilip koyu renkle çizilir.
// Kalınlık ekran pikseli cinsinden sabit kalır (yakın/uzak fark etmez).
shader_type spatial;
render_mode unshaded, cull_front, depth_draw_opaque, shadows_disabled;

uniform vec4 line_col : source_color = vec4(0.03, 0.02, 0.07, 1.0);
uniform float width = 2.6;

void vertex() {
	vec4 clip = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	vec3 n = normalize((MODELVIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	vec2 off = (PROJECTION_MATRIX * vec4(n, 0.0)).xy;
	float l = length(off);
	if (l > 0.0001) {
		off /= l;
	}
	clip.xy += off * width / VIEWPORT_SIZE * clip.w * 2.0;
	POSITION = clip;
}

void fragment() {
	ALBEDO = line_col.rgb;
}
