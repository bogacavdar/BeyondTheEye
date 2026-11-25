// AY IŞIKLI DENİZ: kıyıyı çevreleyen gece denizi; ay yolunda parıldayan dalgalar
shader_type spatial;
render_mode unshaded;

uniform vec3 deep : source_color = vec3(0.02, 0.05, 0.12);
uniform vec3 shallow : source_color = vec3(0.06, 0.2, 0.32);
uniform vec3 moon_dir = vec3(-0.7, 0.0, -0.7);

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
	float t = TIME * 0.4;
	float w = noise(p * 0.25 + vec2(t, t * 0.6)) * 0.6 + noise(p * 0.9 - vec2(t * 1.3, 0.0)) * 0.4;
	vec3 c = mix(deep, shallow, smoothstep(60.0, 14.0, r) * 0.8 + w * 0.2);
	// ay yolu: aya doğru uzanan parıltılı şerit
	vec2 md = normalize(moon_dir.xz);
	float along = dot(p, md);
	float across = abs(dot(p, vec2(-md.y, md.x)));
	float path = smoothstep(9.0, 0.0, across) * step(0.0, along);
	float spark = smoothstep(0.78, 0.95, noise(p * 2.5 + vec2(t * 3.0, -t * 2.0)));
	c += vec3(0.7, 0.85, 1.0) * spark * (0.06 + path * 0.7);
	// kıyıda köpük
	float foam = smoothstep(0.7, 0.0, abs(r - 13.5 - sin(atan(p.y, p.x) * 7.0 + TIME) * 0.4)) * (0.5 + 0.5 * w);
	c = mix(c, vec3(0.85, 0.95, 1.0), foam * 0.3);
	ALBEDO = c;
}
