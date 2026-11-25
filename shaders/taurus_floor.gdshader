// BOĞA OTLAKLARI ZEMİNİ
// Altın saat ışığında çimenli yayla: koyu ve açık çimen lekeleri, serpiştirilmiş pembe/beyaz çiçekler,
// kenarda aşınmış toprak yol, ortada çimene işlenmiş ♉ (daire + hilal) motifi.
shader_type spatial;

uniform vec3 grass_dark : source_color = vec3(0.13, 0.28, 0.07);
uniform vec3 grass_light : source_color = vec3(0.36, 0.55, 0.16);
uniform vec3 dirt : source_color = vec3(0.4, 0.3, 0.18);
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

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = wpos.xz;
	float r = length(p);
	// yumuşak, katmanlı çimen dokusu (köşeli bloklar olmasın diye döndürülmüş katmanlar)
	vec2 q = mat2(vec2(0.8, 0.6), vec2(-0.6, 0.8)) * p;
	float n = noise(p * 0.3) * 0.5 + noise(q * 1.1) * 0.3 + noise(q * 3.7 + 11.0) * 0.2;
	vec3 c = mix(grass_dark, grass_light, smoothstep(0.3, 0.75, n));
	// ince çimen ışıltısı: küçük, yuvarlak lekeler
	float tuft = noise(q * 9.0) * 0.6 + noise(p * 17.0 + 3.0) * 0.4;
	c *= 0.9 + (tuft - 0.5) * 0.25;
	// çiçekler: hücre başına küçük bir nokta
	vec2 cell = floor(p * 1.6);
	vec2 f = fract(p * 1.6) - 0.5;
	float h = hash(cell);
	vec2 o = vec2(hash(cell + 3.1), hash(cell + 7.7)) - 0.5;
	float dot_ = 1.0 - smoothstep(0.05, 0.09, length(f - o * 0.6));
	vec3 flower = h < 0.5 ? vec3(1.0, 0.55, 0.72) : vec3(1.0, 0.97, 0.85);
	float show = step(0.62, h) * dot_;
	// kenarda aşınmış toprak halka yol
	float path = 1.0 - smoothstep(0.5, 1.2, abs(r - (arena_r - 1.4)) + (noise(p * 2.0) - 0.5) * 0.6);
	c = mix(c, dirt * (0.85 + n * 0.3), path * 0.85);
	show *= 1.0 - path;
	// ortada ♉: daire + üstünde hilal (açık çimen)
	float circ = 1.0 - smoothstep(0.12, 0.2, abs(length(p - vec2(0.0, 0.8)) - 2.2));
	float hornr = length(p - vec2(0.0, -2.6));
	float horn = (1.0 - smoothstep(0.12, 0.2, abs(hornr - 2.6))) * step(p.y, -1.4) * step(-4.6, p.y);
	float glyph = max(circ, horn) * (1.0 - path);
	c = mix(c, vec3(0.75, 0.85, 0.35), glyph * 0.45);
	ALBEDO = mix(c, flower, show);
	ROUGHNESS = 0.9;
	EMISSION = flower * show * 0.25 + vec3(0.6, 0.8, 0.25) * glyph * 0.12;
}
