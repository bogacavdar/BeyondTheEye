// GÜNEŞ SARAYI ZEMİNİ
// Beyaz ve kraliyet moru mermer karolar, damarlı; dışa doğru güneş ışınları gibi açılan desen,
// kenarda altın şerit ve ortada altın ♌ (bir daire + kıvrılan kuyruk).
// Aslan yaratıkları altın-amber olduğu için zemin bilerek mor-beyaz tutuldu.
shader_type spatial;

uniform vec3 marble : source_color = vec3(0.78, 0.76, 0.84);
uniform vec3 royal : source_color = vec3(0.24, 0.14, 0.4);
uniform vec3 gold : source_color = vec3(1.0, 0.78, 0.35);
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

float ring(vec2 p, vec2 c, float r, float w) {
	return 1.0 - smoothstep(w * 0.5, w * 0.5 + 0.04, abs(length(p - c) - r));
}

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = wpos.xz;
	float r = length(p);
	float a = atan(p.y, p.x);
	// güneş ışını dilimleri: 16 dilim, sırayla beyaz / mor
	float sector = floor((a + PI) / (TAU / 16.0));
	float alt = mod(sector, 2.0);
	// halka bantları
	float band = step(3.0, r) * (1.0 - step(3.4, r)) + step(7.2, r) * (1.0 - step(7.5, r));
	vec3 base = mix(marble, royal, alt);
	if (r < 3.0) {
		base = royal * 1.1;
	}
	// mermer damarları
	float v = noise(p * 0.8 + vec2(noise(p * 0.3) * 3.0));
	float vein = smoothstep(0.48, 0.5, v) * (1.0 - smoothstep(0.5, 0.53, v));
	base = mix(base, base * (alt > 0.5 ? 1.6 : 0.75), vein * 0.6);
	base *= 0.94 + noise(p * 3.0) * 0.08;
	// dilim sınırları (ince altın çizgiler)
	float fa = fract((a + PI) / (TAU / 16.0));
	float seam = (1.0 - smoothstep(0.0, 0.012 * 11.0 / max(r, 1.0), min(fa, 1.0 - fa))) * step(3.4, r);
	vec3 c = mix(base, gold, max(seam * 0.6, band * 0.9));
	// kenar şeridi
	float edge = smoothstep(arena_r - 0.4, arena_r - 0.25, r) * (1.0 - smoothstep(arena_r + 0.1, arena_r + 0.25, r));
	c = mix(c, gold, edge * 0.9);
	// ortada ♌: büyük daire + kuyruk kıvrımı
	vec2 q = p * 0.8;
	float g = ring(q, vec2(-0.55, 0.3), 0.45, 0.13);
	float tail = ring(q, vec2(0.35, 0.1), 0.6, 0.13) * step(q.y, 0.35) * step(-0.25, q.x);
	float hook = ring(q, vec2(1.05, -0.55), 0.3, 0.12) * step(q.y, -0.45);
	g = clamp(g + tail + hook, 0.0, 1.0) * (1.0 - step(2.6, r));
	c = mix(c, gold, g);
	ALBEDO = c;
	EMISSION = gold * (g * 0.45 + edge * 0.2 + band * 0.15 + seam * 0.08);
	METALLIC = max(g, band) * 0.7;
	ROUGHNESS = mix(0.3, 0.25, alt);
}
