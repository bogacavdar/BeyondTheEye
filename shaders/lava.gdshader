// LAV DENİZİ: adanın altında yavaşça akan, parlayan erimiş kaya
shader_type spatial;
render_mode unshaded;

uniform vec3 hot : source_color = vec3(1.0, 0.55, 0.12);
uniform vec3 cool : source_color = vec3(0.35, 0.05, 0.02);

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
		p = p * 2.03 + vec2(1.7, 9.2);
		a *= 0.5;
	}
	return s;
}

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = wpos.xz * 0.12;
	float t = TIME * 0.05;
	float q = fbm(p + vec2(t, -t * 0.7));
	float f = fbm(p * 1.7 + q * 2.0 + vec2(-t * 0.6, t));
	float crust = smoothstep(0.42, 0.62, f);
	vec3 c = mix(hot * 1.8, cool, crust);
	// adadan uzaklaştıkça karar
	float far = smoothstep(25.0, 70.0, length(wpos.xz));
	ALBEDO = mix(c, cool * 0.4, far * 0.7);
}
