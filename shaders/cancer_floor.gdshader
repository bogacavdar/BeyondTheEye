// AY IŞIKLI KIYI ZEMİNİ
// Ay ışığında ıslak, soğuk tonlu kum; rüzgârın çizdiği dalgacıklar, yer yer gelgit gölcükleri,
// kenarda inci-gümüş şerit ve ortada gümüş kakma ♋ (iki daire ve iki yay).
// Yengeç yaratıkları mercan kırmızısı olduğu için zemin bilerek serin mavi-gri tutuldu.
shader_type spatial;

uniform vec3 sand : source_color = vec3(0.2, 0.24, 0.32);
uniform vec3 sand_hi : source_color = vec3(0.34, 0.39, 0.48);
uniform vec3 pool : source_color = vec3(0.06, 0.2, 0.3);
uniform vec3 silver : source_color = vec3(0.85, 0.9, 1.0);
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

float ring(vec2 p, vec2 c, float r, float w) {
	return 1.0 - smoothstep(w * 0.5, w * 0.5 + 0.04, abs(length(p - c) - r));
}

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = wpos.xz;
	float r = length(p);
	float n = noise(p * 0.35) * 0.6 + noise(p * 1.3) * 0.4;
	// rüzgâr dalgacıkları
	float rip = sin(p.x * 2.2 + p.y * 0.8 + noise(p * 0.5) * 4.0) * 0.5 + 0.5;
	vec3 c = mix(sand, sand_hi, smoothstep(0.25, 0.8, n));
	c *= 0.92 + rip * 0.1;
	// gelgit gölcükleri
	float pl = smoothstep(0.74, 0.78, noise(p * 0.3 + 7.0));
	float glint = step(0.985, hash(floor(p * 9.0))) * pl;
	c = mix(c, pool, pl * 0.85);
	vec3 em = vec3(0.3, 0.7, 1.0) * glint * 1.2 + pool * pl * 0.25;
	// kenar şeridi
	float edge = smoothstep(arena_r - 0.4, arena_r - 0.25, r) * (1.0 - smoothstep(arena_r + 0.1, arena_r + 0.25, r));
	c = mix(c, silver, edge * 0.8);
	// ortada ♋
	vec2 q = p * 0.75;
	float g = ring(q, vec2(-0.75, 0.4), 0.32, 0.12) + ring(q, vec2(0.75, -0.4), 0.32, 0.12);
	float arc1 = ring(q, vec2(0.0, 0.4), 1.05, 0.1) * step(0.55, q.y) ;
	float arc2 = ring(q, vec2(0.0, -0.4), 1.05, 0.1) * step(q.y, -0.55);
	g = clamp(g + arc1 * step(q.x, 0.7) + arc2 * step(-0.7, q.x), 0.0, 1.0) * (1.0 - step(2.2, r));
	c = mix(c, silver, g * 0.85);
	em += silver * g * 0.35 + silver * edge * 0.15;
	ALBEDO = c;
	EMISSION = em;
	ROUGHNESS = mix(0.85, 0.2, pl);
	METALLIC = g * 0.5;
}
