// DONMUŞ ZİRVE ZEMİNİ
// Rüzgârın sürüklediği kar; aralarda camgöbeği buz levhaları ve çatlaklar. Kenarda buz şerit.
// Deniz keçileri koyu arduvaz olduğu için zemin açık ama gözü yakmayan kar grisi tutuldu.
shader_type spatial;

uniform vec3 snow_a : source_color = vec3(0.5, 0.56, 0.63);
uniform vec3 snow_b : source_color = vec3(0.64, 0.69, 0.75);
uniform vec3 ice : source_color = vec3(0.22, 0.4, 0.5);
uniform vec3 rim : source_color = vec3(0.5, 0.9, 1.0);
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
	// sürüklenen kar
	vec2 q = vec2(p.x * 0.5 + p.y * 0.5, p.y * 1.2 - p.x * 0.3);
	float n = noise(q * 0.6) * 0.6 + noise(q * 2.2 + vec2(TIME * 0.08, 0.0)) * 0.4;
	vec3 c = mix(snow_a, snow_b, smoothstep(0.3, 0.8, n));
	// buz levhaları
	float ic = smoothstep(0.62, 0.66, noise(p * 0.3 + 7.0));
	// buzdaki çatlaklar
	float cr = 1.0 - smoothstep(0.0, 0.025, abs(noise(p * 1.4) - 0.5));
	vec3 icec = mix(ice, ice * 1.4, noise(p * 2.0)) ;
	icec = mix(icec, vec3(0.85, 0.95, 1.0), cr * 0.3);
	c = mix(c, icec, ic);
	float edge = smoothstep(arena_r - 0.4, arena_r - 0.25, r) * (1.0 - smoothstep(arena_r + 0.1, arena_r + 0.25, r));
	c = mix(c, rim, edge * 0.85);
	ALBEDO = c;
	EMISSION = rim * edge * 0.3;
	ROUGHNESS = mix(0.85, 0.2, ic);
	SPECULAR = mix(0.3, 0.7, ic);
}
