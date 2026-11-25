// GÖZÜN ÖTESİ KAPISI
// Altın halkanın içinde dönen bulutsu ve yıldızlar; ortası daha parlak.
shader_type spatial;
render_mode unshaded, cull_disabled;

uniform vec3 navy : source_color = vec3(0.071, 0.114, 0.31);
uniform vec3 gold : source_color = vec3(0.953, 0.863, 0.478);
uniform vec3 violet : source_color = vec3(0.45, 0.25, 0.85);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}

void fragment() {
	vec2 uv = UV * 2.0 - 1.0;
	float r = length(uv);
	if (r > 1.0) {
		discard;
	}
	float a = atan(uv.y, uv.x);
	float swirl = a + r * 4.0 - TIME * 0.8;
	vec2 q = vec2(cos(swirl), sin(swirl)) * r * 3.0;
	float n = noise(q + TIME * 0.2) * 0.6 + noise(q * 2.5 - TIME * 0.3) * 0.4;
	vec3 col = mix(navy * 0.6, violet, smoothstep(0.35, 0.8, n));
	col = mix(col, gold, smoothstep(0.7, 0.95, n) * 0.6);
	col += gold * pow(1.0 - r, 3.0) * 1.8;
	vec2 sc = floor(q * 8.0);
	if (hash(sc) > 0.96) {
		col += vec3(1.0) * (1.0 - smoothstep(0.0, 0.3, length(fract(q * 8.0) - 0.5))) * 2.0;
	}
	ALBEDO = col * 1.6;
	ALPHA = smoothstep(1.0, 0.85, r);
}
