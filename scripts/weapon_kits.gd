extends RefCounted
## SİLAH SETLERİ: her kozmik silahın kombosu, ağır saldırısı (Q) ve 3 yeteneği (1, 2, 3).
## Saldırı alanları: wind = hazırlık, act = vuruş anı, rec = toparlanma (sn); arc = vuruş yayı (derece);
## range = menzil (m); kb = geri itme; step = vuruşta öne adım hızı.
## Yetenek türleri:
##   starfall   : farenin yerine yıldız/meteor düşer (radius, count, dmg, delay, star_r, max_range)
##   wave       : ileri giden, delip geçen ışık (dmg, speed, range, width)
##   path       : nişan yönüne ışınlan/hücum et, yol boyunca hasar (dist, dmg, delay)
##   burst_self : kahramanın etrafında anlık patlama (radius, dmg, kb, stun)
##   burst_aim  : farenin olduğu yerde patlama; düşmanları çekebilir / sersemletebilir (radius, dmg, stun, pull, delay, max_range)
##   leap       : farenin olduğu yere zıplayıp yere çakıl (max_range, radius, dmg)
##   aura       : kahramanın etrafında süreli yakıcı hale (radius, dmg, tick, duration)
##   orbit      : kahramanın etrafında dönen meteorlar (radius, dmg, duration, count)
##   boomerang  : fırlatılıp geri dönen hilal (dmg, range)
##   vortex     : düşmanları içine çeken girdap (radius, dmg, duration, max_range)
##   eclipse    : çevreyi sersemlet + birkaç saniye her vuruş kritik (radius, dmg, stun, buff)
##   cone       : ileriye alev püskürtme + yakma (dmg, reach)
##   charge     : mızrakla ileri atılış, yoldakileri savurur (dist, dmg)
##   line       : ileriye doğru yürüyen patlamalar (dmg, count)
##   hook       : düşmanı yakalayıp yanına çeken zincir (dmg, range)


static func _combo(arc: float, rng: float, dmg: Array, t: Array, step: Array, kb: Array) -> Array:
	var h := deg_to_rad(arc) * 0.5
	return [
		{"wind": t[0], "act": t[1], "rec": t[2], "dmg": dmg[0], "arc": arc, "range": rng, "kb": kb[0], "a0": -h, "a1": h, "step": step[0]},
		{"wind": t[0], "act": t[1], "rec": t[2], "dmg": dmg[1], "arc": arc, "range": rng, "kb": kb[1], "a0": h, "a1": -h, "step": step[1]},
		{"wind": t[0] * 1.8, "act": t[1] * 1.2, "rec": t[2] * 1.6, "dmg": dmg[2], "arc": minf(arc * 1.4, 300.0), "range": rng * 1.15, "kb": kb[2],
			"a0": -minf(h * 1.4, 2.6), "a1": minf(h * 1.4, 2.6), "step": step[2], "finisher": true},
	]


## Yakın dövüş silahları için küçük güçlendirme (atılma 3 sn, can çalma tavanı ve ani düşman saldırılarından sonra denge):
## vuruş hasarı +%15, yetenek hasarı +%10, saldırılar %8 daha seri. Yay (menzilli) hariç.
const MELEE_DMG := 1.15
const MELEE_SKILL_DMG := 1.1
const MELEE_SPEED := 0.92


static func get_kit(id: String) -> Dictionary:
	var k := _raw_kit(id)
	if bool(k.get("ranged", false)):
		return k
	for a in k["combo"]:
		_buff(a)
	_buff(k["heavy"])
	for sk in k["skills"]:
		if sk.has("dmg"):
			sk["dmg"] = float(sk["dmg"]) * MELEE_SKILL_DMG
	return k


static func _buff(a: Dictionary) -> void:
	a["dmg"] = float(a["dmg"]) * MELEE_DMG
	for key in ["wind", "rec"]:
		if a.has(key):
			a[key] = float(a[key]) * MELEE_SPEED


static func _raw_kit(id: String) -> Dictionary:
	match id:
		"MOON SCYTHE":
			return {
				"color": Color(0.75, 0.82, 1.0),
				"combo": _combo(210.0, 3.1, [11.0, 11.0, 22.0], [0.1, 0.09, 0.28], [2.0, 2.0, 3.5], [5.0, 5.0, 10.0]),
				"heavy": {"wind": 0.35, "act": 0.16, "rec": 0.45, "dmg": 22.0, "arc": 360.0, "range": 3.7, "kb": 11.0, "a0": 0.0, "a1": TAU, "step": 0.0, "finisher": true},
				"skills": [
					{"name": "CRESCENT REAP", "cd": 6.0, "type": "boomerang", "dmg": 14.0, "range": 9.0},
					{"name": "LUNAR TIDE", "cd": 10.0, "type": "vortex", "radius": 4.0, "dmg": 4.0, "duration": 2.5, "max_range": 8.0},
					{"name": "ECLIPSE", "cd": 16.0, "type": "eclipse", "radius": 4.0, "dmg": 6.0, "stun": 2.0, "buff": 4.0},
				],
			}
		"SUN MACE":
			return {
				"color": Color(1.0, 0.75, 0.3),
				"combo": _combo(130.0, 2.5, [17.0, 17.0, 32.0], [0.16, 0.1, 0.38], [2.0, 2.0, 3.0], [7.0, 7.0, 14.0]),
				"heavy": {"wind": 0.45, "act": 0.14, "rec": 0.5, "dmg": 30.0, "arc": 360.0, "range": 3.2, "kb": 14.0, "a0": 0.0, "a1": TAU, "step": 0.0, "finisher": true},
				"skills": [
					{"name": "SOLAR FLARE", "cd": 8.0, "type": "cone", "dmg": 18.0, "reach": 5.5},
					{"name": "ZENITH SLAM", "cd": 10.0, "type": "leap", "max_range": 7.0, "radius": 2.8, "dmg": 26.0},
					{"name": "CORONA", "cd": 15.0, "type": "aura", "radius": 2.8, "dmg": 5.0, "tick": 0.45, "duration": 5.0},
				],
			}
		"COMET SPEAR":
			return {
				"color": Color(0.6, 0.85, 1.0),
				"combo": _combo(50.0, 3.8, [10.0, 10.0, 20.0], [0.07, 0.08, 0.2], [4.0, 4.0, 7.0], [4.0, 4.0, 9.0]),
				"heavy": {"wind": 0.3, "act": 0.12, "rec": 0.4, "dmg": 26.0, "arc": 40.0, "range": 5.0, "kb": 10.0, "a0": -0.35, "a1": 0.35, "step": 11.0, "finisher": true},
				"skills": [
					{"name": "COMET THROW", "cd": 6.0, "type": "wave", "dmg": 22.0, "speed": 26.0, "range": 15.0, "width": 0.35},
					{"name": "PERIHELION CHARGE", "cd": 8.0, "type": "charge", "dist": 8.0, "dmg": 18.0},
					{"name": "TAIL SWEEP", "cd": 9.0, "type": "line", "dmg": 14.0, "count": 6},
				],
			}
		"METEOR CHAIN":
			return {
				"color": Color(1.0, 0.55, 0.35),
				"combo": _combo(170.0, 3.3, [7.0, 7.0, 14.0], [0.05, 0.07, 0.15], [2.0, 2.0, 3.0], [3.0, 3.0, 8.0]),
				"heavy": {"wind": 0.2, "act": 0.18, "rec": 0.35, "dmg": 16.0, "arc": 360.0, "range": 3.4, "kb": 9.0, "a0": 0.0, "a1": TAU, "step": 0.0, "finisher": true},
				"skills": [
					{"name": "IMPACT", "cd": 8.0, "type": "starfall", "radius": 2.4, "count": 1, "dmg": 30.0, "delay": 0.6, "star_r": 0.55, "max_range": 8.0},
					{"name": "ORBIT", "cd": 14.0, "type": "orbit", "radius": 2.2, "dmg": 6.0, "duration": 5.0, "count": 2},
					{"name": "CHAIN HOOK", "cd": 7.0, "type": "hook", "dmg": 16.0, "range": 9.0},
				],
			}
		"CENTAUR BOW":
			# menzilli: saldırılar ok fırlatır (arrows: ok sayısı, spread: yelpaze açısı, pierce: kaç düşmanı deler)
			return {
				"color": Color(0.78, 0.65, 1.0),
				"ranged": true,
				"combo": [
					{"wind": 0.16, "act": 0.04, "rec": 0.3, "dmg": 12.0, "arrows": 1, "spread": 0.0, "pierce": 0, "speed": 34.0, "range": 12.0, "kb": 0.0, "a0": 0.0, "a1": 0.0, "arc": 0.0, "step": 0.0},
					{"wind": 0.16, "act": 0.04, "rec": 0.3, "dmg": 12.0, "arrows": 1, "spread": 0.0, "pierce": 0, "speed": 34.0, "range": 12.0, "kb": 0.0, "a0": 0.0, "a1": 0.0, "arc": 0.0, "step": 0.0},
					{"wind": 0.22, "act": 0.05, "rec": 0.48, "dmg": 8.0, "arrows": 3, "spread": 26.0, "pierce": 0, "speed": 34.0, "range": 12.0, "kb": 0.0, "a0": 0.0, "a1": 0.0, "arc": 0.0, "step": -2.0, "finisher": true},
				],
				"heavy_cd": 1.5,
				"heavy": {"wind": 0.55, "act": 0.05, "rec": 0.4, "dmg": 50.0, "arrows": 1, "spread": 0.0, "pierce": 2, "speed": 44.0, "range": 15.0, "kb": 0.0, "a0": 0.0, "a1": 0.0, "arc": 0.0, "step": 0.0, "finisher": true},
				"skills": [
					{"name": "ARROW RAIN", "cd": 10.0, "type": "starfall", "radius": 2.6, "count": 10, "dmg": 7.5, "delay": 0.55, "star_r": 0.07, "max_range": 10.0},
					{"name": "PIERCING STAR", "cd": 7.0, "type": "wave", "dmg": 22.0, "speed": 30.0, "range": 16.0, "width": 0.25},
					{"name": "CENTAUR LEAP", "cd": 11.0, "type": "disengage", "dist": 4.5, "radius": 2.4, "dmg": 15.0, "stun": 0.8},
				],
			}
	# STAR SWORD (varsayılan)
	return {
		"color": Color(0.95, 0.9, 0.7),
		"combo": _combo(150.0, 2.5, [9.0, 9.0, 18.0], [0.06, 0.08, 0.2], [3.0, 3.0, 5.0], [4.0, 4.0, 10.0]),
		"heavy": {"wind": 0.28, "act": 0.14, "rec": 0.42, "dmg": 20.0, "arc": 360.0, "range": 3.1, "kb": 12.0, "a0": 0.0, "a1": TAU, "step": 0.0, "finisher": true},
		"skills": [
			{"name": "STARFALL", "cd": 9.0, "type": "starfall", "radius": 1.8, "count": 5, "dmg": 13.0, "delay": 0.5, "star_r": 0.16, "max_range": 8.0},
			{"name": "LIGHT WAVE", "cd": 6.0, "type": "wave", "dmg": 13.0, "speed": 17.0, "range": 11.0, "width": 1.0},
			{"name": "CONSTELLATION STEP", "cd": 11.0, "type": "path", "dist": 6.0, "dmg": 16.0, "delay": 0.4},
		],
	}
