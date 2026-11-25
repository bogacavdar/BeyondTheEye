extends RefCounted
## BIRTH CHART — kalıcı dev skill ağacı (veri ve kurallar).
## 12 ev, her evde 43 yıldızlık bir ağaç: kökten yukarı dallanarak büyür, en tepede burcun "takımyıldızı gücü" (keystone).
## - Küçük yıldızlar (minor): evin temasına göre küçük artışlar, 3-5 kademe.
## - Büyük yıldızlar (notable): oyun tarzını değiştiren güçler, 1 kademe.
## - Takımyıldızı gücü (keystone): evin son yıldızı, evin burcuna özel büyük güç.
## Bir yıldızı açmak için ona bağlı alttaki yıldızlardan en az biri yanmış olmalı (kök her zaman açılabilir).
## Fiyatlar: satır yükseldikçe artar, kademe arttıkça artar ve haritada toplam yaktığın her kademe tüm fiyatları %1.2 artırır.
## Toplam ~1300 kademe: tamamlamak yüzlerce run sürer.

const ROWS := [1, 2, 3, 4, 4, 5, 5, 5, 4, 4, 3, 2, 1]
const ROW_GAP := 92.0
const COL_GAP := 112.0
const INFLATION := 0.012

static var _cache: Array = []

## Evler: gerçek astrolojik anlamları, doğal burcu ve yönetici gezegeni.
## stats: küçük yıldızların verdiği değerler [anahtar, etiket, kademe başı değer, birim]
## notables: 5 büyük yıldız; keystone: takımyıldızı gücü
const HOUSES := [
	{"name": "SELF", "sign": "ARIES", "ruler": "Mars", "theme": "Body, vitality, the will to begin",
		"stats": [["max_hp", "Max Health", 5.0, ""], ["move_speed", "Move Speed", 1.0, "%"], ["dash_cdr", "Dash Cooldown Reduction", 2.0, "%"]],
		"notables": [["Iron Will", "+40 Max Health"], ["Ram's Charge", "Dashing through enemies damages them"],
			["First Light", "Enter every room with a 20 point shield"], ["Warrior's Spirit", "+10% damage while above 80% health"],
			["Unbroken", "Once per run, survive a lethal hit with 1 health"]],
		"keystone": ["ARIES RISING", "Your first strike in every room deals triple damage"]},
	{"name": "VALUES", "sign": "TAURUS", "ruler": "Venus", "theme": "Wealth, possessions, what you hold dear",
		"stats": [["dust_gain", "Stardust Gain", 2.0, "%"], ["armor", "Armor", 1.0, ""], ["gold_find", "Gold Shard Find", 2.0, "%"]],
		"notables": [["Hoarder", "+20% stardust from every source"], ["Golden Touch", "Gold shards can drop twice"],
			["Bedrock", "+5 Armor"], ["Fertile Ground", "Reward rooms offer one extra choice"],
			["Patience", "Standing still for a second grants 15% damage reduction"]],
		"keystone": ["TAURUS STEADFAST", "You cannot be knocked back. +25% Armor"]},
	{"name": "MIND", "sign": "GEMINI", "ruler": "Mercury", "theme": "Thought, speech, short journeys",
		"stats": [["atk_speed", "Attack Speed", 1.5, "%"], ["combo_dmg", "Combo Damage", 2.0, "%"], ["dash_dist", "Dash Distance", 2.0, "%"]],
		"notables": [["Twin Dash", "+1 dash charge"], ["Quick Wit", "+8% attack speed"],
			["Messenger", "Dashing leaves a trail of stardust that burns enemies"], ["Double Talk", "Every 5th hit strikes twice"],
			["Wind Step", "After a dash, +20% move speed for 1.5 seconds"]],
		"keystone": ["GEMINI MIRROR", "A shadow twin repeats your attacks at 30% damage"]},
	{"name": "ROOTS", "sign": "CANCER", "ruler": "Moon", "theme": "Home, family, the safe harbor",
		"stats": [["room_heal", "Healing per Room", 1.0, ""], ["shield", "Starting Shield", 3.0, ""], ["heal_power", "Healing Power", 3.0, "%"]],
		"notables": [["Hearth", "Heal 5 health after every room"], ["Homeward", "Rest rooms heal 50% more"],
			["Shell", "+25 starting shield"], ["Tide", "Healing above full health becomes shield"],
			["Mother's Watch", "Once per run, rise again with 30% health"]],
		"keystone": ["CANCER SHELL", "Your shield slowly regenerates outside of combat"]},
	{"name": "CREATION", "sign": "LEO", "ruler": "Sun", "theme": "Joy, play, courage and risk",
		"stats": [["damage", "Damage", 1.5, "%"], ["crit_dmg", "Critical Damage", 4.0, "%"], ["finisher_dmg", "Finisher Damage", 3.0, "%"]],
		"notables": [["Spark", "+5% critical chance"], ["Spotlight", "+25% critical damage"],
			["Gambler's Heart", "The lower your health, the more damage you deal"], ["Showstopper", "Finishers burst into gold shards that hurt nearby enemies"],
			["Royal Pride", "+15% damage against elites"]],
		"keystone": ["LEO CROWN", "Critical hits make you blaze: +5% damage per stack, up to 10"]},
	{"name": "HEALTH", "sign": "VIRGO", "ruler": "Mercury", "theme": "Daily order, service, healing",
		"stats": [["regen", "Health Regen per Second", 0.1, ""], ["crit_chance", "Critical Chance", 0.6, "%"], ["poison_res", "Poison Resistance", 3.0, "%"]],
		"notables": [["Routine", "Health regeneration also works in combat at half strength"], ["Remedy", "Healing items are 30% stronger"],
			["Precision", "+5% critical chance"], ["Healer's Hands", "Finishers heal 3 health"],
			["Purity", "You are immune to poison"]],
		"keystone": ["VIRGO HARVEST", "Every 10th enemy you defeat heals 10% of your health"]},
	{"name": "UNION", "sign": "LIBRA", "ruler": "Venus", "theme": "Partnership, harmony, balance",
		"stats": [["parry_window", "Parry Window", 2.0, "%"], ["reflect", "Damage Reflected", 2.0, "%"], ["boon_rarity", "Boon Rarity", 1.0, "%"]],
		"notables": [["Planet Friend", "+1 choice when picking planetary boons"], ["Harmony", "Two boons from the same planet grant a bonus"],
			["The Scales", "Reflect 15% of damage taken"], ["Grace", "+20% parry window"],
			["Accord", "Perfect parries heal 2 health"]],
		"keystone": ["LIBRA BALANCE", "A perfect parry stops time for one second"]},
	{"name": "REBIRTH", "sign": "SCORPIO", "ruler": "Pluto & Mars", "theme": "Death, transformation, hidden power",
		"stats": [["lifesteal", "Life Steal", 0.5, "%"], ["poison_dmg", "Poison Damage", 3.0, "%"], ["execute", "Shatter Threshold", 0.5, "%"]],
		"notables": [["Venom", "Your attacks poison enemies"], ["Phoenix Ash", "Once per run, rise again with 50% health"],
			["Second Birth", "+1 rebirth per run"], ["Death's Door", "+30% damage while below 30% health"],
			["Shatterer", "Enemies below 10% health shatter into stardust"]],
		"keystone": ["SCORPIO STING", "Poison stacks without limit"]},
	{"name": "WISDOM", "sign": "SAGITTARIUS", "ruler": "Jupiter", "theme": "Philosophy, faith, far journeys",
		"stats": [["luck", "Luck", 1.0, "%"], ["reach", "Attack Reach", 2.0, "%"], ["thrown_dmg", "Thrown Damage", 3.0, "%"]],
		"notables": [["Oracle", "Rarer rewards appear behind doors"], ["Pilgrim", "Begin every run with a random boon"],
			["Seeing Eye", "See which room waits behind each door"], ["Far Reach", "+15% attack reach"],
			["Fortune", "+10% luck"]],
		"keystone": ["SAGITTARIUS ARROW", "Heavy attacks also loose an arrow of starlight"]},
	{"name": "SUMMIT", "sign": "CAPRICORN", "ruler": "Saturn", "theme": "Career, mastery, authority",
		"stats": [["boss_dmg", "Boss Damage", 2.0, "%"], ["heavy_dmg", "Heavy Attack Damage", 3.0, "%"], ["dmg_reduction", "Damage Reduction", 0.6, "%"]],
		"notables": [["Ascent", "+8% damage"], ["Kingslayer", "+15% damage against bosses"],
			["Stone Skin", "+5% damage reduction"], ["Heavy Hand", "Heavy attacks stagger enemies"],
			["Discipline", "+1 heavy attack charge"]],
		"keystone": ["CAPRICORN SUMMIT", "The longer a fight lasts, the stronger you become"]},
	{"name": "HOPE", "sign": "AQUARIUS", "ruler": "Uranus & Saturn", "theme": "Community, ideals, the future",
		"stats": [["shop_discount", "Shop Discount", 1.0, "%"], ["haste", "Ability Haste", 1.0, "%"], ["planet_power", "Planetary Boon Power", 2.0, "%"]],
		"notables": [["Wishing Stone", "Shop prices are 15% lower"], ["The Crowd", "+1 door to choose from"],
			["Prophecy", "Reroll a reward once per room"], ["Lightning Mind", "+10% ability haste"],
			["Uranian Surprise", "Boons sometimes upgrade on their own"]],
		"keystone": ["AQUARIUS FLOW", "Every third boon you take is legendary"]},
	{"name": "HIDDEN", "sign": "PISCES", "ruler": "Neptune & Jupiter", "theme": "The unconscious, karma, the unseen",
		"stats": [["dodge", "Dodge Chance", 0.6, "%"], ["shadow_time", "Shadow Step Duration", 3.0, "%"], ["counter_dmg", "Parry Counter Damage", 2.0, "%"]],
		"notables": [["Sixth Sense", "+20% parry window"], ["Shadow Step", "Enemies lose track of you while you dash"],
			["Karma", "Perfect parries reflect the blow"], ["Dream Walk", "+8% dodge chance"],
			["Mist", "Become invisible for a second after taking damage"]],
		"keystone": ["PISCES DREAM", "15% chance to dodge any hit, leaving an illusion behind"]},
]

## Takımyıldızı çizimleri (ağacın arkasında soluk olarak görünür). Noktalar -1..1, y aşağı.
const CONSTELLATIONS := [
	{"pts": [Vector2(-0.9, 0.25), Vector2(-0.2, -0.1), Vector2(0.4, -0.25), Vector2(0.8, -0.12)], "segs": [0, 1, 1, 2, 2, 3]},
	{"pts": [Vector2(0, 0), Vector2(-0.25, -0.15), Vector2(-0.45, -0.25), Vector2(0.2, -0.2), Vector2(0.35, -0.32), Vector2(-0.9, -0.8), Vector2(0.6, -0.9), Vector2(0.75, 0.5), Vector2(0.82, 0.55), Vector2(0.78, 0.6)],
		"segs": [0, 1, 1, 2, 0, 3, 3, 4, 2, 5, 4, 6]},
	{"pts": [Vector2(-0.4, -0.9), Vector2(-0.45, -0.2), Vector2(-0.55, 0.4), Vector2(-0.6, 0.85), Vector2(0.2, -0.85), Vector2(0.15, -0.2), Vector2(0.1, 0.35), Vector2(0.15, 0.9)],
		"segs": [0, 1, 1, 2, 2, 3, 4, 5, 5, 6, 6, 7, 0, 4, 1, 5]},
	{"pts": [Vector2(0, 0), Vector2(0.05, -0.75), Vector2(-0.55, 0.6), Vector2(0.55, 0.55), Vector2(0.1, 0.15)], "segs": [0, 1, 0, 2, 0, 3, 0, 4]},
	{"pts": [Vector2(-0.5, 0.4), Vector2(-0.55, 0.0), Vector2(-0.4, -0.4), Vector2(-0.15, -0.55), Vector2(0.0, -0.35), Vector2(0.4, -0.1), Vector2(0.9, 0.05), Vector2(0.45, 0.35)],
		"segs": [0, 1, 1, 2, 2, 3, 3, 4, 1, 5, 5, 6, 6, 7, 7, 0]},
	{"pts": [Vector2(-0.9, -0.3), Vector2(-0.4, -0.1), Vector2(0.0, 0.0), Vector2(0.3, -0.5), Vector2(0.2, 0.55), Vector2(0.65, 0.1), Vector2(0.9, -0.3)],
		"segs": [0, 1, 1, 2, 2, 3, 2, 4, 2, 5, 5, 6]},
	{"pts": [Vector2(0, -0.6), Vector2(-0.5, 0.0), Vector2(0.5, 0.05), Vector2(-0.4, 0.6), Vector2(0.45, 0.7)], "segs": [0, 1, 0, 2, 1, 2, 1, 3, 2, 4]},
	{"pts": [Vector2(-0.9, -0.8), Vector2(-0.8, -0.4), Vector2(-0.95, -0.1), Vector2(-0.55, -0.3), Vector2(-0.3, -0.1), Vector2(-0.1, 0.2), Vector2(0.1, 0.55), Vector2(0.4, 0.8), Vector2(0.7, 0.75), Vector2(0.85, 0.45)],
		"segs": [0, 3, 1, 3, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9]},
	{"pts": [Vector2(-0.5, 0.3), Vector2(-0.5, -0.1), Vector2(-0.1, -0.45), Vector2(0.2, -0.15), Vector2(0.3, 0.3), Vector2(0.0, 0.45), Vector2(0.7, -0.25), Vector2(0.8, 0.4)],
		"segs": [0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 0, 1, 3, 3, 6, 4, 7, 6, 7]},
	{"pts": [Vector2(-0.8, -0.5), Vector2(-0.6, 0.1), Vector2(0.0, 0.5), Vector2(0.6, 0.3), Vector2(0.9, -0.3), Vector2(0.3, -0.2)], "segs": [0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 0]},
	{"pts": [Vector2(-0.2, -0.8), Vector2(0.0, -0.4), Vector2(0.3, -0.55), Vector2(-0.3, 0.0), Vector2(-0.6, 0.3), Vector2(-0.1, 0.4), Vector2(0.3, 0.7), Vector2(0.6, 0.5)],
		"segs": [0, 1, 1, 2, 1, 3, 3, 4, 3, 5, 5, 6, 6, 7]},
	{"pts": [Vector2(-0.8, -0.7), Vector2(-0.6, -0.5), Vector2(-0.3, 0.0), Vector2(0.0, 0.6), Vector2(0.4, 0.2), Vector2(0.6, -0.3), Vector2(0.75, -0.7), Vector2(0.5, -0.8)],
		"segs": [0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 5]},
]

const ROMAN := ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X", "XI", "XII"]


# ---------------------------------------------------------------- ağaç üretimi

static func nodes(h: int) -> Array:
	if _cache.is_empty():
		for i in 12:
			_cache.append(_build(i))
	return _cache[h]


static func _build(h: int) -> Array:
	var info: Dictionary = HOUSES[h]
	var pool: Array = info["stats"]
	var notables: Array = info["notables"]
	var rng := RandomNumberGenerator.new()
	rng.seed = 7919 * (h + 1)
	var out: Array = []
	var prev: Array = []
	var notable_i := 0
	var last_row := ROWS.size() - 1
	for r in ROWS.size():
		var n: int = ROWS[r]
		var cur: Array = []
		for i in n:
			var x := 0.0
			if n > 1:
				x = (float(i) - float(n - 1) * 0.5) * COL_GAP + rng.randf_range(-16.0, 16.0)
			var y := -float(r) * ROW_GAP + rng.randf_range(-12.0, 12.0)
			var node := {"idx": out.size(), "row": r, "pos": Vector2(x, y), "parents": [], "children": []}
			var base := 12.0 * pow(1.36, float(r))
			if r == last_row:
				node["kind"] = "keystone"
				node["name"] = info["keystone"][0]
				node["desc"] = info["keystone"][1]
				node["max"] = 1
				node["cost"] = base * 12.0
			elif (r == 3 and i == 1) or (r == 6 and i == 2) or (r == 9 and i == 3) or r == 11:
				var nb: Array = notables[notable_i % notables.size()]
				notable_i += 1
				node["kind"] = "notable"
				node["name"] = nb[0]
				node["desc"] = nb[1]
				node["max"] = 1
				node["cost"] = base * 5.0
			else:
				var st: Array = pool[(r + i) % pool.size()]
				var per := snappedf(float(st[2]) * (1.0 + float(r) * 0.08), 0.1)
				node["kind"] = "minor"
				node["stat"] = st[0]
				node["name"] = st[1]
				node["per"] = per
				node["unit"] = st[3]
				node["max"] = 3 if r < 7 else 5
				node["cost"] = base
			# bağlantılar: alttaki satırdan en yakın yıldız (+ bazen komşusu)
			if r > 0:
				var pn := prev.size()
				if n == 1:
					for p in prev:
						node["parents"].append(p)
				else:
					var t := float(i) / float(n - 1)
					var j := roundi(t * float(pn - 1))
					node["parents"].append(prev[j])
					if rng.randf() < 0.35:
						var k := j + (1 if rng.randf() < 0.5 else -1)
						if k >= 0 and k < pn:
							node["parents"].append(prev[k])
			out.append(node)
			cur.append(node["idx"])
		# yukarı bağı olmayan yıldızı en yakın üst yıldıza bağla
		if r > 0:
			for c in cur:
				for p in out[c]["parents"]:
					if not out[p]["children"].has(c):
						out[p]["children"].append(c)
			for p in prev:
				if out[p]["children"].is_empty():
					var best: int = cur[0]
					for c in cur:
						if absf(out[c]["pos"].x - out[p]["pos"].x) < absf(out[best]["pos"].x - out[p]["pos"].x):
							best = c
					out[best]["parents"].append(p)
					out[p]["children"].append(best)
		prev = cur
	return out


# ---------------------------------------------------------------- kurallar

static func key(h: int, i: int) -> String:
	return "%d_%d" % [h, i]


static func rank(chart: Dictionary, h: int, i: int) -> int:
	return int(chart.get(key(h, i), 0))


static func total_ranks(chart: Dictionary) -> int:
	var t := 0
	for k in chart:
		t += int(chart[k])
	return t


## "maxed" tam dolu, "owned" yanık ama kademe alınabilir, "open" açılabilir, "locked" kilitli
static func state(chart: Dictionary, h: int, i: int) -> String:
	var node: Dictionary = nodes(h)[i]
	var rk := rank(chart, h, i)
	if rk >= int(node["max"]):
		return "maxed"
	if rk > 0:
		return "owned"
	if (node["parents"] as Array).is_empty():
		return "open"
	for p in node["parents"]:
		if rank(chart, h, p) > 0:
			return "open"
	return "locked"


static func cost(chart: Dictionary, h: int, i: int) -> int:
	var node: Dictionary = nodes(h)[i]
	var rk := rank(chart, h, i)
	var c := float(node["cost"]) * (1.0 + 0.6 * float(rk)) * (1.0 + INFLATION * float(total_ranks(chart)))
	return maxi(1, roundi(c))


static func house_progress(chart: Dictionary, h: int) -> Vector2i:
	var have := 0
	var total := 0
	var list := nodes(h)
	for i in list.size():
		have += rank(chart, h, i)
		total += int(list[i]["max"])
	return Vector2i(have, total)


static func all_progress(chart: Dictionary) -> Vector2i:
	var have := 0
	var total := 0
	for h in 12:
		var p := house_progress(chart, h)
		have += p.x
		total += p.y
	return Vector2i(have, total)


static func fmt_value(v: float, unit: String) -> String:
	var s := str(snappedf(v, 0.1))
	if s.ends_with(".0"):
		s = s.substr(0, s.length() - 2)
	return "+" + s + unit


## Küçük yıldızlardan gelen toplam değer (oyun içinde kullanılacak)
static func stat_total(chart: Dictionary, stat: String) -> float:
	var t := 0.0
	for h in 12:
		var list := nodes(h)
		for i in list.size():
			if list[i].get("stat", "") == stat:
				t += float(list[i]["per"]) * float(rank(chart, h, i))
	return t


## Büyük güç alınmış mı (ada göre)
static func has_power(chart: Dictionary, power_name: String) -> bool:
	for h in 12:
		var list := nodes(h)
		for i in list.size():
			if list[i]["kind"] != "minor" and list[i]["name"] == power_name and rank(chart, h, i) > 0:
				return true
	return false
