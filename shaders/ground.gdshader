// ŞEHİR ZEMİNİ
// Tek bir düzlem; dünya konumuna göre asfalt yolları, şerit çizgilerini, yaya geçitlerini,
// kaldırım taşlarını ve neonları yansıtan su birikintilerini çizer.
shader_type spatial;

uniform float road_spacing = 32.0;
uniform float road_first = -48.0;
uniform float road_half = 4.0;

varying vec3 wpos;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float road_dist(float c) {
	float d = 1e9;
	for (int i = 0; i < 4; i++) {
		float rc = road_first + road_spacing * float(i);
		d = min(d, abs(c - rc));
	}
	return d;
}

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float dx = road_dist(wpos.x);  // z boyunca uzanan yola uzaklık
	float dz = road_dist(wpos.z);  // x boyunca uzanan yola uzaklık
	bool road = dx < road_half || dz < road_half;
	float n = noise(wpos.xz * 0.35);
	float puddle = smoothstep(0.58, 0.72, noise(wpos.xz * 0.11 + 3.0));
	vec3 col;
	vec3 emi = vec3(0.0);
	float rough;

	if (road) {
		col = vec3(0.05, 0.05, 0.06) * (0.8 + 0.4 * n);
		// orta şerit (kesikli)
		if (dz < road_half && dx >= road_half && dz < 0.09 && fract(wpos.x / 4.0) < 0.5) {
			col = vec3(0.85, 0.75, 0.3);
			emi = vec3(0.3, 0.25, 0.08);
		}
		if (dx < road_half && dz >= road_half && dx < 0.09 && fract(wpos.z / 4.0) < 0.5) {
			col = vec3(0.85, 0.75, 0.3);
			emi = vec3(0.3, 0.25, 0.08);
		}
		// yaya geçitleri
		if (dx < road_half - 0.4 && dz > road_half + 0.5 && dz < road_half + 2.6 && fract(wpos.x * 0.8) < 0.5) {
			col = vec3(0.6);
		}
		if (dz < road_half - 0.4 && dx > road_half + 0.5 && dx < road_half + 2.6 && fract(wpos.z * 0.8) < 0.5) {
			col = vec3(0.6);
		}
		rough = mix(0.5, 0.03, puddle);
	} else {
		vec2 g = fract(wpos.xz / 1.5);
		float line = step(g.x, 0.035) + step(g.y, 0.035);
		col = vec3(0.13, 0.13, 0.15) * (0.85 + 0.3 * n) - line * 0.045;
		rough = mix(0.65, 0.1, puddle);
		// kaldırım kenarı
		if (min(dx, dz) < road_half + 0.25) {
			col = vec3(0.3, 0.3, 0.32);
			rough = 0.6;
		}
	}
	col *= mix(1.0, 0.55, puddle);  // ıslak yerler koyu

	ALBEDO = col;
	EMISSION = emi;
	ROUGHNESS = rough;
	METALLIC = mix(0.1, 0.5, puddle);
}
