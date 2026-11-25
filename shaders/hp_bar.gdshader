shader_type spatial;
render_mode unshaded, depth_draw_never, depth_test_disabled, cull_disabled, shadows_disabled;
// Düşman can barı: kameraya dönük, altın çerçeveli; dolu kısım kızıl, sersemleyince altın yanar.

uniform float fill = 1.0;
uniform float stunned = 0.0;

void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
}

void fragment() {
	vec2 uv = UV;
	float bx = 0.012;
	float by = 0.14;
	bool border = uv.x < bx || uv.x > 1.0 - bx || uv.y < by || uv.y > 1.0 - by;
	vec3 gold = vec3(0.95, 0.82, 0.45);
	vec3 c;
	if (border) {
		c = gold;
	} else if (uv.x < fill) {
		c = mix(vec3(0.85, 0.15, 0.2), vec3(1.0, 0.9, 0.5), stunned);
	} else {
		c = vec3(0.04, 0.04, 0.1);
	}
	ALBEDO = c;
	ALPHA = 0.92;
}
