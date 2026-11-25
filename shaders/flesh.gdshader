// MUTANT ETİ
// Islak, damarlı, yer yer zehirli parlayan kabarcıklı et.
// Vurulunca beyaz parlar (flash), yanarken turuncu kor (burn), yanıp ölünce kömürleşir (char_amt).
shader_type spatial;

instance uniform vec3 skin_color : source_color = vec3(0.55, 0.32, 0.34);
instance uniform float flash = 0.0;
instance uniform float burn = 0.0;
instance uniform float char_amt = 0.0;
instance uniform float pulse_seed = 0.0;

uniform vec3 vein_color : source_color = vec3(0.3, 0.0, 0.06);
uniform vec3 glow_color : source_color = vec3(0.75, 1.0, 0.15);

varying vec3 lpos;

float hash3(vec3 p) {
	return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453);
}

float noise3(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float n000 = hash3(i);
	float n100 = hash3(i + vec3(1, 0, 0));
	float n010 = hash3(i + vec3(0, 1, 0));
	float n110 = hash3(i + vec3(1, 1, 0));
	float n001 = hash3(i + vec3(0, 0, 1));
	float n101 = hash3(i + vec3(1, 0, 1));
	float n011 = hash3(i + vec3(0, 1, 1));
	float n111 = hash3(i + vec3(1, 1, 1));
	return mix(mix(mix(n000, n100, f.x), mix(n010, n110, f.x), f.y),
			mix(mix(n001, n101, f.x), mix(n011, n111, f.x), f.y), f.z);
}

void vertex() {
	lpos = VERTEX * 3.0 + vec3(pulse_seed);
	// hafif nabız gibi şişip inme
	VERTEX += NORMAL * sin(TIME * 4.0 + pulse_seed * 6.0 + VERTEX.y * 5.0) * 0.008;
}

void fragment() {
	float n = noise3(lpos * 1.3);
	float vein_n = noise3(lpos * 2.4 + 11.0);
	float veins = 1.0 - smoothstep(0.0, 0.05, abs(vein_n - 0.5));
	vec3 col = skin_color * (0.65 + 0.6 * n);
	col = mix(col, vein_color, veins * 0.85);
	float pust = smoothstep(0.8, 0.86, noise3(lpos * 3.5 + 7.0));
	col = mix(col, vec3(0.85, 0.8, 0.35), pust * 0.7);

	float throb = 0.6 + 0.4 * sin(TIME * 5.0 + pulse_seed * 9.0);
	vec3 emi = glow_color * pust * 1.6 * throb;
	emi += vec3(1.0) * flash * 2.2;
	emi += vec3(1.0, 0.35, 0.05) * burn * (1.5 + 1.5 * noise3(lpos * 2.0 + TIME * 3.0));

	col = mix(col, vec3(0.03, 0.02, 0.02), char_amt);
	emi *= 1.0 - char_amt * 0.8;

	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	emi += skin_color * rim * 0.35 * (1.0 - char_amt);

	ALBEDO = col;
	ROUGHNESS = mix(0.18, 0.55, n);
	SPECULAR = 0.65;
	EMISSION = emi;
}
