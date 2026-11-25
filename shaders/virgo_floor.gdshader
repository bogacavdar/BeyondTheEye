// SESSİZ HASAT ZEMİNİ
// Koyu çam yeşili ve camgöbeği taş karolar; aralarında gümüş derz, karoların içinde ince
// düzen çizgileri (Başak'ın titizliği); kenarda gümüş şerit. Yaratıklar porselen beyazı olduğu için
// zemin bilerek koyu ve serin tutuldu.
shader_type spatial;

uniform vec3 tile_a : source_color = vec3(0.07, 0.16, 0.15);
uniform vec3 tile_b : source_color = vec3(0.1, 0.22, 0.2);
uniform vec3 grout : source_color = vec3(0.42, 0.52, 0.52);
uniform vec3 teal : source_color = vec3(0.3, 1.0, 0.85);
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
	vec2 cell = floor(p / 2.0);
	vec2 f = fract(p / 2.0);
	float chk = mod(cell.x + cell.y, 2.0);
	vec3 c = mix(tile_a, tile_b, chk);
	c *= 0.85 + hash(cell) * 0.2 + noise(p * 2.5) * 0.1;
	// derz
	float gd = min(min(f.x, 1.0 - f.x), min(f.y, 1.0 - f.y));
	float g = 1.0 - smoothstep(0.015, 0.035, gd);
	c = mix(c, grout, g * 0.5);
	// karonun içinde ince çerçeve (düzen)
	float inner = (1.0 - smoothstep(0.0, 0.012, abs(gd - 0.16))) * step(0.5, chk);
	c = mix(c, grout * 0.6, inner * 0.5);
	// kenar şeridi
	float edge = smoothstep(arena_r - 0.4, arena_r - 0.25, r) * (1.0 - smoothstep(arena_r + 0.1, arena_r + 0.25, r));
	c = mix(c, grout, edge * 0.9);
	// merkez dairesi
	float ring = 1.0 - smoothstep(0.03, 0.07, abs(r - 3.0));
	c = mix(c, grout, ring * 0.8);
	ALBEDO = c;
	EMISSION = teal * (inner * 0.06 + ring * 0.25 + edge * 0.15) + grout * g * 0.03;
	ROUGHNESS = 0.55;
}
