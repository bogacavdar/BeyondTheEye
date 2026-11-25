// BULUT DENİZİ: adanın altında yavaşça akan bembeyaz bulutlar
shader_type spatial;
render_mode unshaded;

uniform vec3 bright : source_color = vec3(1.0, 1.0, 1.0);
uniform vec3 shade_c : source_color = vec3(0.62, 0.72, 0.9);

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
	for (int i = 0; i < 5; i++) {
		s += noise(p) * a;
		p = p * 2.02 + vec2(4.1, 1.7);
		a *= 0.5;
	}
	return s;
}

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = wpos.xz * 0.05 + vec2(TIME * 0.01, TIME * 0.004);
	float n = fbm(p);
	float puff = smoothstep(0.35, 0.75, n);
	vec3 c = mix(shade_c, bright, puff);
	float far = smoothstep(40.0, 120.0, length(wpos.xz));
	ALBEDO = mix(c, vec3(0.8, 0.87, 1.0), far * 0.6);
}
