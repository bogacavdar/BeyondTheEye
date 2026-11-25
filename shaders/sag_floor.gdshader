// KENTAUR BOZKIRI ZEMİNİ
// Rüzgârın yatırdığı adaçayı yeşili bozkır otu, aralarda gri-mavi düz taşlar; kenarda gümüş şerit.
// Kentaurlar mor-lacivert olduğu için zemin serin yeşil-gri tutuldu.
shader_type spatial;

uniform vec3 grass_a : source_color = vec3(0.3, 0.42, 0.36);
uniform vec3 grass_b : source_color = vec3(0.45, 0.56, 0.48);
uniform vec3 stone : source_color = vec3(0.5, 0.55, 0.6);
uniform vec3 silver : source_color = vec3(0.85, 0.88, 0.95);
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
	// rüzgâr yönünde uzamış ot dokusu
	vec2 q = vec2(p.x * 0.6 + p.y * 0.3, p.y * 1.6);
	float n = noise(q * 0.7) * 0.65 + noise(q * 1.8 + TIME * 0.05) * 0.35;
	vec3 c = mix(grass_a, grass_b, smoothstep(0.3, 0.75, n));
	// düz taşlar
	float st = smoothstep(0.68, 0.72, noise(p * 0.35 + 3.0));
	c = mix(c, stone * (0.85 + noise(p * 3.0) * 0.2), st);
	float edge = smoothstep(arena_r - 0.4, arena_r - 0.25, r) * (1.0 - smoothstep(arena_r + 0.1, arena_r + 0.25, r));
	c = mix(c, silver, edge * 0.85);
	ALBEDO = c;
	EMISSION = silver * edge * 0.2;
	ROUGHNESS = mix(0.9, 0.6, st);
}
