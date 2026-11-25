// ZEHİR MAĞARALARI ZEMİNİ
// Mavi-gri bazalt, çatlaklardan sızan soluk mor ışık, yer yer mor kristal kümeleri.
// Yaratıklar obsidyen-asit yeşili olduğu için zemin bilerek mavi-mor tutuldu.
shader_type spatial;

uniform vec3 rock : source_color = vec3(0.16, 0.18, 0.24);
uniform vec3 rock_hi : source_color = vec3(0.28, 0.3, 0.38);
uniform vec3 glow : source_color = vec3(0.6, 0.4, 1.0);
uniform float arena_r = 11.0;

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

vec2 vor(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	float d1 = 9.0;
	float d2 = 9.0;
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 g = vec2(float(x), float(y));
			vec2 o = vec2(hash(i + g), hash(i + g + 17.0));
			float d = length(g + o - f);
			if (d < d1) { d2 = d1; d1 = d; } else if (d < d2) { d2 = d; }
		}
	}
	return vec2(d1, d2);
}

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = wpos.xz;
	float r = length(p);
	vec2 v = vor(p * 0.45);
	float crack = 1.0 - smoothstep(0.02, 0.07, v.y - v.x);
	vec3 c = mix(rock, rock_hi, noise(p * 0.7) * 0.7 + noise(p * 2.5) * 0.3);
	c = mix(c, rock * 0.4, crack * 0.8);
	float pulse = 0.6 + 0.4 * sin(TIME * 1.2 + p.x * 0.3);
	float edge = smoothstep(arena_r - 0.4, arena_r - 0.25, r) * (1.0 - smoothstep(arena_r + 0.1, arena_r + 0.25, r));
	c = mix(c, glow * 0.6, edge * 0.7);
	ALBEDO = c;
	EMISSION = glow * (crack * 0.35 * pulse + edge * 0.25);
	ROUGHNESS = 0.8;
}
