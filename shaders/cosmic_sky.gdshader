// KOZMİK GÖKYÜZÜ
// Lacivert gece, mor-lacivert bulutsular, ara ara altın parıltılar, göz kırpan yıldızlar ve dev dolunay.
shader_type sky;

uniform vec3 moon_dir = vec3(-0.55, -0.15, -0.6);
uniform float moon_size = 0.12;
uniform vec3 navy : source_color = vec3(0.071, 0.114, 0.31);
uniform vec3 deep : source_color = vec3(0.012, 0.018, 0.06);
uniform vec3 gold : source_color = vec3(0.953, 0.863, 0.478);

float hash(vec3 p) {
	return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453);
}

float noise3(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(hash(i), hash(i + vec3(1, 0, 0)), f.x), mix(hash(i + vec3(0, 1, 0)), hash(i + vec3(1, 1, 0)), f.x), f.y),
			mix(mix(hash(i + vec3(0, 0, 1)), hash(i + vec3(1, 0, 1)), f.x), mix(hash(i + vec3(0, 1, 1)), hash(i + vec3(1, 1, 1)), f.x), f.y), f.z);
}

float fbm(vec3 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		v += a * noise3(p);
		p *= 2.1;
		a *= 0.5;
	}
	return v;
}

void sky() {
	vec3 d = normalize(EYEDIR);
	float n = fbm(d * 2.2);
	vec3 col = mix(deep, navy, smoothstep(0.25, 0.75, n));

	// bulutsu
	float neb = fbm(d * 3.5 + vec3(4.0, 1.0, 7.0));
	col += vec3(0.22, 0.12, 0.42) * smoothstep(0.5, 0.75, neb) * 0.9;
	col += gold * 0.07 * smoothstep(0.62, 0.8, fbm(d * 5.0 + 2.0));

	// yıldızlar (iki katman)
	for (int k = 0; k < 2; k++) {
		float scale = k == 0 ? 160.0 : 320.0;
		vec3 g = d * scale;
		vec3 c = floor(g);
		float h = hash(c + float(k) * 13.0);
		if (h > 0.982) {
			vec3 f = fract(g) - 0.5;
			float s = 1.0 - smoothstep(0.0, 0.18, length(f));
			float tw = 0.55 + 0.45 * sin(TIME * (1.5 + h * 3.0) + h * 100.0);
			vec3 sc = h > 0.995 ? gold : vec3(0.9, 0.92, 1.0);
			col += sc * s * tw * (k == 0 ? 3.0 : 1.5);
		}
	}

	// dolunay
	vec3 md = normalize(moon_dir);
	float cosang = dot(d, md);
	float ang = acos(clamp(cosang, -1.0, 1.0));
	if (ang < moon_size) {
		float edge = smoothstep(moon_size, moon_size * 0.96, ang);
		float crater = fbm(d * 70.0);
		vec3 moon = vec3(1.0, 0.97, 0.9) * (0.75 + 0.35 * crater);
		col = mix(col, moon * 2.2, edge);
	}
	col += vec3(1.0, 0.93, 0.75) * exp(-max(ang - moon_size, 0.0) * 18.0) * 0.6;
	col += vec3(0.35, 0.4, 0.75) * exp(-max(ang - moon_size, 0.0) * 4.0) * 0.25;

	COLOR = col;
}
