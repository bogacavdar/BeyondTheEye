// UZAK ÇAYIR: yaylanın çevresindeki alçak vadi; uzaklaştıkça sise karışır
shader_type spatial;

uniform vec3 near_col : source_color = vec3(0.2, 0.36, 0.1);
uniform vec3 far_col : source_color = vec3(0.55, 0.5, 0.42);

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

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float n = noise(wpos.xz * 0.08) * 0.6 + noise(wpos.xz * 0.4) * 0.4;
	vec3 c = near_col * (0.75 + n * 0.5);
	float far = smoothstep(20.0, 90.0, length(wpos.xz));
	ALBEDO = mix(c, far_col, far * 0.8);
	ROUGHNESS = 1.0;
}
