shader_type spatial;
// Gezegen yüzeyi: koddan üretilen gerçekçi doku.
// kind 0 = kayalık (Merkür, Ay, Mars, Plüton), 1 = gaz/bulut kuşaklı (Venüs, Jüpiter, Satürn, Uranüs, Neptün), 2 = Dünya

uniform int kind = 0;
uniform vec3 col_a : source_color = vec3(0.5);
uniform vec3 col_b : source_color = vec3(0.3);
uniform vec3 col_c : source_color = vec3(0.7);
uniform float seed = 0.0;
uniform float band_freq = 10.0;
uniform float band_warp = 1.5;
uniform float crater_amt = 0.0;
uniform float polar_cap = 2.0;          // |y| bu değerin üstü buz (2 = yok)
uniform vec3 spot_dir = vec3(1.0, -0.35, 0.0);
uniform float spot_size = 0.0;          // 0 = leke yok
uniform vec3 spot_col : source_color = vec3(0.8, 0.4, 0.25);
uniform vec3 atmo_col : source_color = vec3(0.4, 0.6, 1.0);
uniform float atmo_amt = 0.0;
uniform float self_glow = 0.12;

varying vec3 p;

float hash(vec3 q) {
	q = fract(q * 0.3183099 + vec3(0.71, 0.113, 0.419));
	q *= 17.0;
	return fract(q.x * q.y * q.z * (q.x + q.y + q.z));
}

float noise(vec3 x) {
	vec3 i = floor(x);
	vec3 f = fract(x);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(hash(i), hash(i + vec3(1, 0, 0)), f.x),
				   mix(hash(i + vec3(0, 1, 0)), hash(i + vec3(1, 1, 0)), f.x), f.y),
			   mix(mix(hash(i + vec3(0, 0, 1)), hash(i + vec3(1, 0, 1)), f.x),
				   mix(hash(i + vec3(0, 1, 1)), hash(i + vec3(1, 1, 1)), f.x), f.y), f.z);
}

float fbm(vec3 x) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 5; i++) {
		v += a * noise(x);
		x = x * 2.03 + vec3(1.7, 9.2, 3.1);
		a *= 0.5;
	}
	return v;
}

void vertex() {
	p = normalize(VERTEX);
}

void fragment() {
	vec3 q = p + vec3(seed);
	vec3 c;
	if (kind == 2) {
		// Dünya: okyanus, kıtalar, çöller, buzullar ve bulutlar
		float land = fbm(q * 2.2);
		float ocean_shade = fbm(q * 6.0);
		vec3 ocean = mix(col_a * 0.75, col_a * 1.15, ocean_shade);
		vec3 ground = mix(col_b, col_c, smoothstep(0.45, 0.7, fbm(q * 5.0 + 4.0)));
		c = mix(ocean, ground, smoothstep(0.5, 0.53, land));
		float ice = smoothstep(polar_cap - 0.04, polar_cap + 0.02, abs(p.y) + (fbm(q * 8.0) - 0.5) * 0.12);
		c = mix(c, vec3(0.93, 0.95, 0.98), ice);
		float cloud = smoothstep(0.52, 0.7, fbm(q * 4.0 + vec3(TIME * 0.015, 0.0, 0.0)));
		c = mix(c, vec3(1.0), cloud * 0.85);
	} else if (kind == 1) {
		// kuşaklı gaz devi / bulut örtüsü
		float w = fbm(q * 3.0) * band_warp;
		float b = sin(p.y * band_freq + w) * 0.5 + 0.5;
		float b2 = sin(p.y * band_freq * 2.3 + w * 1.7 + 1.3) * 0.5 + 0.5;
		c = mix(col_a, col_b, smoothstep(0.25, 0.75, b));
		c = mix(c, col_c, smoothstep(0.6, 0.95, b2) * 0.45);
		c *= 0.92 + fbm(q * 9.0) * 0.16;
		if (spot_size > 0.0) {
			float d = distance(p, normalize(spot_dir));
			float s = 1.0 - smoothstep(0.55, 1.0, d / spot_size);
			c = mix(c, spot_col, s);
		}
	} else {
		// kayalık yüzey + kraterler
		float n = fbm(q * 3.0);
		c = mix(col_b, col_a, smoothstep(0.3, 0.7, n));
		c = mix(c, col_c, smoothstep(0.55, 0.75, fbm(q * 1.4 + 7.0)) * 0.6);
		if (crater_amt > 0.0) {
			float cr = noise(q * 14.0);
			float rim = smoothstep(0.72, 0.78, cr) - smoothstep(0.8, 0.9, cr);
			float pit = smoothstep(0.8, 0.9, cr);
			c *= 1.0 - pit * 0.35 * crater_amt;
			c += rim * 0.12 * crater_amt;
		}
		float ice = smoothstep(polar_cap - 0.03, polar_cap + 0.02, abs(p.y) + (fbm(q * 8.0) - 0.5) * 0.1);
		c = mix(c, vec3(0.95, 0.95, 0.97), ice);
	}
	ALBEDO = c;
	ROUGHNESS = (kind == 2) ? 0.55 : 0.9;
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	EMISSION = c * self_glow + atmo_col * fres * atmo_amt;
}
