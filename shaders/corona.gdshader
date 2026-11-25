shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;
// Güneş tacı: kameraya dönük, yumuşak ve hafifçe titreşen ışık halesi

uniform vec3 tint : source_color = vec3(1.0, 0.6, 0.2);
uniform float strength = 1.0;

void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
}

void fragment() {
	vec2 d = UV - vec2(0.5);
	float r = length(d) * 2.0;
	float ang = atan(d.y, d.x);
	float rays = 0.85 + 0.15 * sin(ang * 14.0 + TIME * 0.6) * sin(ang * 5.0 - TIME * 0.4);
	float g = pow(clamp(1.0 - r, 0.0, 1.0), 2.6) * rays;
	ALBEDO = tint * g * strength;
}
