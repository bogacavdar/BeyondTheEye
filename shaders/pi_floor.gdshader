// RÜYALAR DENİZİ ZEMİNİ
// Su altındaki koyu çivit cam; yüzeyden süzülen ışık ağları (kostik) lila ve turkuaz arasında akar. Kenarda inci şerit.
// Rüya varlıkları inci-lila parlak olduğu için zemin koyu tutuldu.
shader_type spatial;

uniform vec3 deep : source_color = vec3(0.07, 0.08, 0.2);
uniform vec3 mid : source_color = vec3(0.12, 0.13, 0.3);
uniform vec3 lilac : source_color = vec3(0.75, 0.55, 1.0);
uniform vec3 aqua : source_color = vec3(0.4, 0.9, 1.0);
uniform vec3 pearl : source_color = vec3(0.92, 0.88, 1.0);
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
	vec3 c = mix(deep, mid, noise(p * 0.25));
	// kostik ağ: iki kayan gürültünün sıfır çizgileri
	float n1 = noise(p * 0.8 + vec2(TIME * 0.15, TIME * 0.1));
	float n2 = noise(p * 0.8 - vec2(TIME * 0.12, -TIME * 0.08) + 5.0);
	float ca = 1.0 - smoothstep(0.0, 0.035, abs(n1 - n2));
	vec3 lc = mix(lilac, aqua, noise(p * 0.15 + TIME * 0.05));
	c += lc * ca * 0.12;
	// iki balık sembolünün gölgesi gibi geniş halkalar
	float rr = abs(fract(r / 3.0 - TIME * 0.05) - 0.5);
	c += pearl * (1.0 - smoothstep(0.0, 0.03, rr)) * 0.06;
	float edge = smoothstep(arena_r - 0.4, arena_r - 0.25, r) * (1.0 - smoothstep(arena_r + 0.1, arena_r + 0.25, r));
	c = mix(c, pearl, edge * 0.85);
	ALBEDO = c;
	EMISSION = lc * ca * 0.1 + pearl * edge * 0.3;
	ROUGHNESS = 0.25;
	SPECULAR = 0.7;
}
