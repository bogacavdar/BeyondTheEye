shader_type spatial;
render_mode unshaded;
// Güneş yüzeyi: kaynayan granülasyon, güneş lekeleri ve kenar kararması

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
		x = x * 2.1 + vec3(1.7, 9.2, 3.1);
		a *= 0.5;
	}
	return v;
}

void vertex() {
	p = normalize(VERTEX);
}

void fragment() {
	float t = TIME * 0.25;
	float g = fbm(p * 7.0 + vec3(t, -t * 0.7, t * 0.4));
	float g2 = fbm(p * 18.0 - vec3(t * 1.3));
	float heat = g * 0.7 + g2 * 0.3;
	vec3 deep = vec3(0.95, 0.38, 0.05);
	vec3 mid = vec3(1.0, 0.68, 0.18);
	vec3 hot = vec3(1.0, 0.95, 0.7);
	vec3 c = mix(deep, mid, smoothstep(0.3, 0.55, heat));
	c = mix(c, hot, smoothstep(0.55, 0.75, heat));
	// birkaç güneş lekesi
	float spots = smoothstep(0.78, 0.84, noise(p * 5.0 + 3.0));
	c = mix(c, vec3(0.35, 0.1, 0.02), spots * 0.8);
	// kenar kararması
	float mu = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	c *= 0.55 + 0.45 * pow(mu, 0.6);
	ALBEDO = c * 1.8;
}
