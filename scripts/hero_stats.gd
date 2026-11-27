extends RefCounted
## DOĞUM HARİTASI → KAHRAMAN GÜÇLERİ
## Doğum Haritası'nda yakılan yıldızlardan kahramanın dövüş değerlerini hesaplar.
## Küçük yıldızlar değerleri toplar; bazı büyük yıldızlar ve takımyıldızı güçleri burada açılır.

const BC = preload("res://scripts/birth_chart.gd")
const Boons = preload("res://scripts/boons.gd")


## AZALAN GETİRİ (GDD §13.7): haritadan gelen hasar türü değerleri eşik T'den sonra yumuşak tavanla büyür.
## etkin(b) = b (b <= T);  T + (b - T) / (1 + (b - T) / k) (b > T). Lütuf, tılsım, mühür ve yükselen tavanın dışında.
const SOFT := {"damage": [12.0, 30.0], "combo_dmg": [10.0, 25.0], "finisher_dmg": [17.0, 30.0], "heavy_dmg": [10.0, 25.0],
	"skill_dmg": [10.0, 25.0], "crit_dmg": [18.0, 40.0], "boss_dmg": [13.0, 20.0]}


static func _soft(b: float, t: float, k: float) -> float:
	if b <= t:
		return b
	return t + (b - t) / (1.0 + (b - t) / k)


## Haritadan gelen ham toplam (küçük yıldızlar + ilgili büyük yıldızlar), azalan getiriden önce
static func raw_total(chart: Dictionary, key: String) -> float:
	var v := BC.stat_total(chart, key)
	if key == "damage" and BC.has_power(chart, "Ascent"): v += 8.0
	if key == "crit_dmg" and BC.has_power(chart, "Spotlight"): v += 25.0
	if key == "boss_dmg" and BC.has_power(chart, "Kingslayer"): v += 15.0
	return v


## Haritadaki ham değerin etkin karşılığı (Doğum Haritası ekranı da kullanır)
static func effective(key: String, raw: float) -> float:
	if not SOFT.has(key):
		return raw
	return _soft(raw, float(SOFT[key][0]), float(SOFT[key][1]))


## boons: bu run'da alınan gezegen lütufları
static func compute(chart: Dictionary, boons: Array = []) -> Dictionary:
	var s := {}
	var keys := ["max_hp", "move_speed", "dash_cdr", "dust_gain", "armor", "gold_find", "atk_speed", "combo_dmg",
		"dash_dist", "room_heal", "shield", "heal_power", "damage", "crit_dmg", "finisher_dmg", "regen", "crit_chance",
		"poison_res", "parry_window", "reflect", "boon_rarity", "lifesteal", "poison_dmg", "execute", "luck", "reach",
		"thrown_dmg", "boss_dmg", "heavy_dmg", "dmg_reduction", "shop_discount", "haste", "planet_power", "dodge",
		"shadow_time", "counter_dmg", "skill_dmg", "room_shield"]
	for k in keys:
		s[k] = BC.stat_total(chart, k)
	# büyük yıldızlar (şimdilik oyunda karşılığı olanlar)
	var p := func(n: String) -> bool: return BC.has_power(chart, n)
	if p.call("Iron Will"): s["max_hp"] += 40.0
	if p.call("Bedrock"): s["armor"] += 5.0
	if p.call("Quick Wit"): s["atk_speed"] += 8.0
	if p.call("Spark"): s["crit_chance"] += 5.0
	if p.call("Precision"): s["crit_chance"] += 5.0
	if p.call("Spotlight"): s["crit_dmg"] += 25.0
	if p.call("Grace"): s["parry_window"] += 20.0
	if p.call("Sixth Sense"): s["parry_window"] += 20.0
	if p.call("Far Reach"): s["reach"] += 15.0
	if p.call("Ascent"): s["damage"] += 8.0
	if p.call("Stone Skin"): s["dmg_reduction"] += 5.0
	if p.call("Lightning Mind"): s["haste"] += 10.0
	if p.call("Dream Walk"): s["dodge"] += 8.0
	if p.call("Hoarder"): s["dust_gain"] += 20.0
	if p.call("Hearth"): s["room_heal"] += 5.0
	if p.call("Shell"): s["shield"] += 25.0
	if p.call("Twin Dash"): s["dash_cdr"] += 25.0
	if p.call("Kingslayer"): s["boss_dmg"] += 15.0
	if p.call("TAURUS STEADFAST"): s["armor"] *= 1.25
	s["death_door"] = p.call("Death's Door")
	s["warrior"] = p.call("Warrior's Spirit")
	s["unbroken"] = p.call("Unbroken")
	s["revives"] = (1 if p.call("Phoenix Ash") else 0) + (1 if p.call("Mother's Watch") else 0) + (1 if p.call("Second Birth") else 0)
	s["accord"] = p.call("Accord")
	s["healer"] = p.call("Healer's Hands")
	s["first_strike"] = p.call("ARIES RISING")
	s["harvest"] = p.call("VIRGO HARVEST")
	s["libra"] = p.call("LIBRA BALANCE")
	for f in ["burn", "rage", "dash_strike", "parry_empower", "extra_iframes"]:
		s[f] = false
	s["revives"] = float(s["revives"])
	for sk in SOFT:
		s[sk] = effective(String(sk), float(s[sk]))   # §13.7: lütuflardan önce
	Boons.apply(s, boons)
	s["dodge"] = minf(float(s["dodge"]), 40.0)
	s["dmg_reduction"] = minf(float(s["dmg_reduction"]), 60.0)
	return s
