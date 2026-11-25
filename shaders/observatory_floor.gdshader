// GÖZLEMEVİ ZEMİNİ
// Parlak lacivert mermer; üstüne altın kakma burç çarkı:
// dış halka, 12 ev çizgisi, iç halka, ortada güneş motifi ve serpiştirilmiş yıldız noktaları.
shader_type spatial;

uniform vec3 navy : source_color = vec3(0.06, 0.09, 0.24);
uniform vec3 gold : source_color = vec3(0.953, 0.863, 0.478);
uniform float platform_r = 14.0;

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

float ring(float r, float center, float w) {
	return 1.0 - smoothstep(0.0, w, abs(r - center));
}

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = wpos.xz;
	float r = length(p);
	float a = atan(p.y, p.x);

	// mermer damarları
	float m = noise(p * 0.6) * 0.6 + noise(p * 2.3) * 0.3;
	float vein = 1.0 - smoothstep(0.0, 0.03, abs(noise(p * 0.9 + 3.0) - 0.5));
	vec3 col = navy * (0.75 + 0.5 * m) + vec3(0.25, 0.25, 0.35) * vein * 0.25;
	float g = 0.0;

	// halkalar
	g += ring(r, platform_r - 0.6, 0.06);
	g += ring(r, platform_r - 0.9, 0.03);
	g += ring(r, 8.2, 0.05);
	g += ring(r, 6.4, 0.05);
	g += ring(r, 2.0, 0.05);
	g += ring(r, 1.7, 0.025);

	// 12 ev çizgisi (6.4 ile 8.2 arasında)
	float sector = TAU / 12.0;
	float ad = abs(mod(a + sector * 0.5, sector) - sector * 0.5) * r;
	if (r > 6.4 && r < 8.2) {
		g += 1.0 - smoothstep(0.0, 0.05, ad);
	}
	// iç ışınlar (güneş motifi)
	float rays = abs(mod(a, TAU / 24.0) - TAU / 48.0) * r;
	if (r > 2.0 && r < 6.4) {
		g += (1.0 - smoothstep(0.0, 0.025, rays)) * 0.35 * smoothstep(6.4, 2.0, r);
	}
	if (r < 1.7) {
		g += 0.25 + 0.2 * sin(r * 12.0);
	}

	// yıldız noktaları
	vec2 cell = floor(p * 1.5);
	float h = hash(cell);
	if (h > 0.93 && r < platform_r - 1.2) {
		vec2 f = fract(p * 1.5) - 0.5;
		g += (1.0 - smoothstep(0.0, 0.08, length(f))) * 0.8;
	}

	g = clamp(g, 0.0, 1.0);
	col = mix(col, gold, g);
	ALBEDO = col;
	METALLIC = mix(0.05, 0.85, g);
	ROUGHNESS = mix(0.55, 0.4, g) + m * 0.1;
	EMISSION = gold * g * 0.25;
}
