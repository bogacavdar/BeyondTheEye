// ŞAFAK TERAZİSİ ZEMİNİ
// Gül pembesi ve arduvaz grisi baklava karolar; ortadan geçen ince altın denge çizgisi;
// kenarda gümüş şerit. Yaratıklar yeşim-bronz olduğu için zemin pembe-gri tutuldu.
shader_type spatial;

uniform vec3 rose : source_color = vec3(0.62, 0.45, 0.52);
uniform vec3 slate : source_color = vec3(0.2, 0.21, 0.27);
uniform vec3 line_c : source_color = vec3(0.95, 0.85, 0.7);
uniform float arena_r = 11.0;

varying vec3 wpos;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = wpos.xz;
	float r = length(p);
	// baklava ızgara: 45 derece döndürülmüş kareler
	vec2 q = mat2(vec2(0.7071, 0.7071), vec2(-0.7071, 0.7071)) * p / 1.8;
	vec2 cell = floor(q);
	vec2 f = fract(q);
	float chk = mod(cell.x + cell.y, 2.0);
	vec3 c = mix(slate, rose, chk);
	c *= 0.88 + hash(cell) * 0.14 + noise(p * 2.0) * 0.08;
	float gd = min(min(f.x, 1.0 - f.x), min(f.y, 1.0 - f.y));
	float g = 1.0 - smoothstep(0.015, 0.04, gd);
	c = mix(c, line_c * 0.7, g * 0.45);
	// denge çizgisi
	float bl = 1.0 - smoothstep(0.03, 0.08, abs(p.x));
	c = mix(c, line_c, bl * 0.8);
	float edge = smoothstep(arena_r - 0.4, arena_r - 0.25, r) * (1.0 - smoothstep(arena_r + 0.1, arena_r + 0.25, r));
	c = mix(c, line_c, edge * 0.85);
	ALBEDO = c;
	EMISSION = line_c * (bl * 0.3 + edge * 0.2);
	ROUGHNESS = mix(0.5, 0.3, chk);
}
