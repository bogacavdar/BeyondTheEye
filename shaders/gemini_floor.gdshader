// İKİZ GÖKLER ZEMİNİ
// Yarısı beyaz, yarısı gece mavisi mermer; aralarında dalgalı bir sınır (ikizliğin iki yüzü),
// damarlar, kenarda altın şerit ve ortada altın kakma ♊ (iki dikey çizgi, üstte ve altta yay).
shader_type spatial;

uniform vec3 light_m : source_color = vec3(0.92, 0.93, 0.97);
uniform vec3 dark_m : source_color = vec3(0.12, 0.15, 0.3);
uniform vec3 gold : source_color = vec3(0.95, 0.8, 0.45);
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

float fbm(vec2 p) {
	float s = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		s += noise(p) * a;
		p *= 2.1;
		a *= 0.5;
	}
	return s;
}

float bar(vec2 p, vec2 c, vec2 hs) {
	vec2 d = abs(p - c) - hs;
	return 1.0 - smoothstep(0.0, 0.06, max(d.x, d.y));
}

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = wpos.xz;
	float r = length(p);
	// dalgalı ikiz sınırı
	float wave = p.x - sin(p.y * 0.45) * 1.6;
	float side = smoothstep(-0.15, 0.15, wave);
	float veins = smoothstep(0.62, 0.7, fbm(p * 0.6 + vec2(3.0, 1.0))) * 0.5 + smoothstep(0.7, 0.74, fbm(p * 1.3)) * 0.4;
	vec3 lm = light_m * (0.92 + fbm(p * 2.0) * 0.1) - vec3(0.25, 0.22, 0.15) * veins;
	vec3 dm = dark_m * (0.85 + fbm(p * 2.0) * 0.3) + vec3(0.35, 0.4, 0.6) * veins;
	vec3 c = mix(lm, dm, side);
	float seam = 1.0 - smoothstep(0.0, 0.12, abs(wave));
	// kenar şeridi
	float rim = 1.0 - smoothstep(0.0, 0.1, abs(r - (arena_r - 0.4)));
	rim += 1.0 - smoothstep(0.0, 0.05, abs(r - (arena_r - 0.75)));
	// ♊
	vec2 g = p / 1.6;
	float glyph = bar(g, vec2(-0.55, 0.0), vec2(0.09, 0.95)) + bar(g, vec2(0.55, 0.0), vec2(0.09, 0.95));
	float top = (1.0 - smoothstep(0.0, 0.08, abs(length((g - vec2(0.0, -2.3)) * vec2(0.8, 1.0)) - 1.45))) * step(-1.25, g.y) * step(g.y, -0.85) * step(abs(g.x), 1.15);
	float bot = (1.0 - smoothstep(0.0, 0.08, abs(length((g - vec2(0.0, 2.3)) * vec2(0.8, 1.0)) - 1.45))) * step(0.85, g.y) * step(g.y, 1.25) * step(abs(g.x), 1.15);
	glyph = clamp(glyph + top + bot, 0.0, 1.0);
	float inlay = clamp(seam * 0.8 + rim + glyph, 0.0, 1.0);
	ALBEDO = mix(c, gold, inlay);
	METALLIC = inlay * 0.9;
	ROUGHNESS = mix(0.35, 0.25, inlay);
	EMISSION = gold * inlay * 0.35;
}
