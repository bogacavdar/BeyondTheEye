// BİNA CEPHESİ
// - Dünya konumuna göre otomatik pencere ızgarası: bazıları sıcak sarı, bazıları neon mavi/pembe yanıyor
// - Zemin katta neon şerit ve ışıklı vitrinler
// - Kamera ile oyuncu arasında kalan kısım noktalı (dither) şekilde delinir: oyuncu hep görünür
shader_type spatial;

uniform vec3 player_pos = vec3(0.0);
uniform float cut_radius = 5.0;

instance uniform float seed = 0.0;
instance uniform vec3 base_color : source_color = vec3(0.12, 0.12, 0.15);
instance uniform vec3 neon_color : source_color = vec3(1.0, 0.2, 0.5);

varying vec3 wpos;
varying vec3 wnorm;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnorm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	// --- görüş kesme ---
	vec3 cam = CAMERA_POSITION_WORLD;
	vec3 p = player_pos + vec3(0.0, 1.0, 0.0);
	vec3 ab = p - cam;
	float t = dot(wpos - cam, ab) / dot(ab, ab);
	if (t > 0.0 && t < 0.97) {
		float d = length(wpos - (cam + ab * t));
		if (d < cut_radius) {
			float edge = smoothstep(cut_radius * 0.6, cut_radius, d);
			float dither = fract(sin(dot(floor(FRAGCOORD.xy), vec2(12.9898, 78.233))) * 43758.5453);
			if (edge < dither) {
				discard;
			}
		}
	}

	vec3 col = base_color;
	vec3 emi = vec3(0.0);
	float rough = 0.7;
	float metal = 0.2;

	if (abs(wnorm.y) < 0.5) {
		float u = abs(wnorm.x) > abs(wnorm.z) ? wpos.z : wpos.x;
		float v = wpos.y;
		vec2 g = vec2(u / 2.4, v / 3.2);
		vec2 cellc = floor(g);
		vec2 f = fract(g);
		// üst katlar: pencereler
		if (v > 4.0 && f.x > 0.18 && f.x < 0.82 && f.y > 0.3 && f.y < 0.78) {
			float h = hash(cellc + seed);
			col = vec3(0.02, 0.02, 0.035);
			rough = 0.08;
			metal = 0.7;
			if (h > 0.6) {
				float h2 = hash(cellc * 1.7 + seed + 3.1);
				vec3 wc = h2 < 0.55 ? vec3(1.0, 0.72, 0.42) : (h2 < 0.82 ? vec3(0.3, 0.8, 1.0) : vec3(1.0, 0.3, 0.75));
				emi = wc * (0.8 + 1.8 * hash(cellc + seed + 7.0));
			}
		}
		// zemin kat: neon şerit + vitrin
		if (v > 3.35 && v < 3.55) {
			emi = neon_color * 4.0;
			col = vec3(0.0);
		} else if (v > 0.5 && v < 3.0) {
			float shop = hash(vec2(floor(u / 4.0), seed));
			float fx = fract(u / 4.0);
			if (shop > 0.35 && fx > 0.08 && fx < 0.92) {
				col = vec3(0.02);
				rough = 0.05;
				metal = 0.8;
				emi = mix(neon_color, vec3(1.0, 0.9, 0.8), 0.35) * (0.5 + 0.6 * shop);
			}
		}
		// kat ayrımı çizgileri
		if (v > 4.0 && f.y < 0.04) {
			col *= 0.6;
		}
	} else {
		col = base_color * 0.6;  // çatı
	}

	ALBEDO = col;
	EMISSION = emi;
	ROUGHNESS = rough;
	METALLIC = metal;
}
