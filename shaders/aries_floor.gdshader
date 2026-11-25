// KOÇ BÖLGESİ ZEMİNİ
// Kızgın bazalt: koyu taş plakalar, aralarındaki çatlaklardan nabız gibi atan lav ışığı.
// Ortada sönük, yere kazınmış bir koç boynuzu sarmalı (♈).
shader_type spatial;

uniform vec3 rock : source_color = vec3(0.12, 0.13, 0.17);
uniform vec3 rock_hi : source_color = vec3(0.26, 0.28, 0.34);
uniform vec3 lava : source_color = vec3(0.55, 0.1, 0.06);
uniform float heat = 1.0;

varying vec3 wpos;

vec2 hash2(vec2 p) {
	p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
	return fract(sin(p) * 43758.5453);
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}

// voronoi: x = hücre içi mesafe farkı (çatlak), y = hücre kimliği
vec2 voronoi(vec2 p) {
	vec2 n = floor(p);
	vec2 f = fract(p);
	float d1 = 8.0;
	float d2 = 8.0;
	float id = 0.0;
	for (int j = -1; j <= 1; j++) {
		for (int i = -1; i <= 1; i++) {
			vec2 g = vec2(float(i), float(j));
			vec2 o = hash2(n + g);
			float d = length(g + o - f);
			if (d < d1) {
				d2 = d1;
				d1 = d;
				id = hash(n + g);
			} else if (d < d2) {
				d2 = d;
			}
		}
	}
	return vec2(d2 - d1, id);
}

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = wpos.xz;
	vec2 v = voronoi(p * 0.42);
	float crack = 1.0 - smoothstep(0.0, 0.08, v.x);
	float fine = 1.0 - smoothstep(0.0, 0.035, voronoi(p * 1.3 + 7.0).x);
	float n = noise(p * 2.5) * 0.6 + noise(p * 9.0) * 0.4;
	vec3 base = mix(rock, rock_hi, v.y * 0.6 + n * 0.4);
	// koç boynuzu sarmalı (merkezde, iki yana kıvrılan)
	float r = length(p);
	float ang = atan(p.y, abs(p.x));
	float spiral = abs(fract((log(max(r, 0.01)) * 2.2 - ang / 6.2831) ) - 0.5);
	float horn = (1.0 - smoothstep(0.05, 0.11, spiral)) * smoothstep(0.8, 1.6, r) * (1.0 - smoothstep(4.2, 5.0, r));
	float pulse = 0.75 + 0.25 * sin(TIME * 1.6 + v.y * 6.2831);
	float glow = (crack * 0.95 + fine * 0.25) * pulse * heat;
	ALBEDO = base * (1.0 - crack * 0.75) + vec3(0.2, 0.2, 0.24) * horn * 0.5;
	ROUGHNESS = 0.85 - n * 0.15;
	METALLIC = 0.0;
	// çatlaklar sönük tutulur: kırmızı saldırı uyarıları ve kızıl yaratıklar zeminden ayrılsın
	EMISSION = lava * (glow * 0.22 + horn * 0.1 * pulse);
}
