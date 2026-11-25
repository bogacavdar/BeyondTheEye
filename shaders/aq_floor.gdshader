// FIRTINA GÖZLEMEVİ ZEMİNİ
// Koyu lacivert taş levhalar, gümüş halka ve takımyıldızı çizgileri; aralarda ara ara çakan şimşek damarları.
// Yaratıklar parlak menekşe-beyaz olduğu için zemin koyu tutuldu.
shader_type spatial;

uniform vec3 tile_a : source_color = vec3(0.1, 0.12, 0.22);
uniform vec3 tile_b : source_color = vec3(0.15, 0.17, 0.3);
uniform vec3 silver : source_color = vec3(0.7, 0.75, 0.9);
uniform vec3 spark : source_color = vec3(0.55, 0.85, 1.0);
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
	float ang = atan(p.y, p.x);
	// halka biçimli levhalar
	float ring = floor(r / 2.2);
	float seg = floor((ang + 3.14159) / (6.28318 / (8.0 + ring * 4.0)));
	float h = hash(vec2(ring, seg));
	vec3 c = mix(tile_a, tile_b, h) * (0.9 + noise(p * 2.0) * 0.2);
	// derzler
	float fr = fract(r / 2.2);
	float gr = 1.0 - smoothstep(0.0, 0.03, min(fr, 1.0 - fr));
	float sa = fract((ang + 3.14159) / (6.28318 / (8.0 + ring * 4.0)));
	float gs = 1.0 - smoothstep(0.0, 0.025 / max(r * 0.15, 0.2), min(sa, 1.0 - sa));
	float grout = max(gr, gs * step(0.5, r));
	c = mix(c, silver * 0.35, grout * 0.7);
	// şimşek damarları: zamanla yanıp sönen ince çizgiler
	float v = abs(noise(p * 0.9 + vec2(floor(TIME * 1.3) * 3.7)) - 0.5);
	float vein = (1.0 - smoothstep(0.0, 0.02, v)) * step(0.82, hash(vec2(floor(TIME * 1.3), 1.0)));
	c = mix(c, spark, vein * 0.6);
	float edge = smoothstep(arena_r - 0.4, arena_r - 0.25, r) * (1.0 - smoothstep(arena_r + 0.1, arena_r + 0.25, r));
	c = mix(c, silver, edge * 0.85);
	ALBEDO = c;
	EMISSION = spark * (vein * 0.8 + edge * 0.3) + silver * grout * 0.05;
	ROUGHNESS = 0.5;
	METALLIC = 0.2;
}
