extends RefCounted
## GEZEGEN LÜTUFLARI (run içi güçlendirmeler, Hades'teki tanrı lütufları gibi)
## Bir lütuf kapısından geçip odayı temizleyince o gezegenin 3 lütfundan birini seçersin.
## Lütuflar sadece o run boyunca geçerlidir; ölünce ya da run bitince sıfırlanır.
## Her gezegenin astrolojik anlamı lütuflarına yansır:
##   Güneş: yaşam gücü, ihtişam · Ay: döngüler, sezgi, gizlenme · Merkür: hız, zekâ
##   Venüs: uyum, şifa · Mars: saldırganlık, ateş · Jüpiter: genişleme, şans · Satürn: disiplin, koruma

const PLANETS := {
	"Sun": {"glyph": "☉", "color": Color(1.0, 0.8, 0.3), "name": "SUN"},
	"Moon": {"glyph": "☽", "color": Color(0.75, 0.82, 1.0), "name": "MOON"},
	"Mercury": {"glyph": "☿", "color": Color(0.6, 0.95, 0.85), "name": "MERCURY"},
	"Venus": {"glyph": "♀", "color": Color(1.0, 0.65, 0.75), "name": "VENUS"},
	"Mars": {"glyph": "♂", "color": Color(1.0, 0.35, 0.25), "name": "MARS"},
	"Jupiter": {"glyph": "♃", "color": Color(0.95, 0.7, 0.45), "name": "JUPITER"},
	"Saturn": {"glyph": "♄", "color": Color(0.85, 0.8, 0.6), "name": "SATURN"},
	"Neptune": {"glyph": "♆", "color": Color(0.35, 0.65, 1.0), "name": "NEPTUNE"},
}

## id, gezegen, ad, açıklama, değer eklemeleri (hero_stats anahtarları), özel bayraklar
const BOONS := [
	{"id": "sun_heart", "planet": "Sun", "name": "Solar Heart", "desc": "+40 Max Health", "mods": {"max_hp": 40.0}},
	{"id": "sun_radiance", "planet": "Sun", "name": "Radiance", "desc": "+50% Critical Damage", "mods": {"crit_dmg": 50.0}},
	{"id": "sun_sunrise", "planet": "Sun", "name": "Sunrise", "desc": "Once this run, rise again with half health", "mods": {"revives": 1.0}},
	{"id": "sun_zenith", "planet": "Sun", "name": "Zenith", "desc": "+60% Finisher Damage", "mods": {"finisher_dmg": 60.0}},

	{"id": "moon_dodge", "planet": "Moon", "name": "Moonlit Step", "desc": "+12% Dodge Chance", "mods": {"dodge": 12.0}},
	{"id": "moon_tides", "planet": "Moon", "name": "Tides", "desc": "Regenerate 1 health per second", "mods": {"regen": 1.0}},
	{"id": "moon_edge", "planet": "Moon", "name": "Lunar Edge", "desc": "After a perfect parry, your next hit deals double damage", "flags": ["parry_empower"]},
	{"id": "moon_veil", "planet": "Moon", "name": "Night Veil", "desc": "Stay untouchable longer after being hit", "flags": ["extra_iframes"]},

	{"id": "merc_feet", "planet": "Mercury", "name": "Swift Feet", "desc": "+20% Move Speed", "mods": {"move_speed": 20.0}},
	{"id": "merc_dash", "planet": "Mercury", "name": "Quicksilver", "desc": "-40% Dash Cooldown", "mods": {"dash_cdr": 40.0}},
	{"id": "merc_wings", "planet": "Mercury", "name": "Winged Step", "desc": "Dashing through enemies deals 15 damage", "flags": ["dash_strike"]},
	{"id": "merc_haste", "planet": "Mercury", "name": "Quick Mind", "desc": "-25% Skill Cooldowns", "mods": {"haste": 25.0}},

	{"id": "venus_embrace", "planet": "Venus", "name": "Venus Embrace", "desc": "+2% Life Steal", "mods": {"lifesteal": 2.0}},
	{"id": "venus_grace", "planet": "Venus", "name": "Beauty's Grace", "desc": "+30 Max Health", "mods": {"max_hp": 30.0}},
	{"id": "venus_allure", "planet": "Venus", "name": "Allure", "desc": "Take 15% less damage", "mods": {"dmg_reduction": 15.0}},
	{"id": "venus_garden", "planet": "Venus", "name": "Rose Garden", "desc": "Heal 10 health after every chamber", "mods": {"room_heal": 10.0}},

	{"id": "mars_strike", "planet": "Mars", "name": "Mars Strike", "desc": "+20% Damage", "mods": {"damage": 20.0}},
	{"id": "mars_fever", "planet": "Mars", "name": "War Fever", "desc": "+15% Attack Speed", "mods": {"atk_speed": 15.0}},
	{"id": "mars_blaze", "planet": "Mars", "name": "Blazing Edge", "desc": "Your attacks set enemies on fire", "flags": ["burn"]},
	{"id": "mars_rage", "planet": "Mars", "name": "Rage", "desc": "+40% damage while below half health", "flags": ["rage"]},

	{"id": "jup_might", "planet": "Jupiter", "name": "Jovian Might", "desc": "+30% Skill Damage", "mods": {"skill_dmg": 30.0}},
	{"id": "jup_fortune", "planet": "Jupiter", "name": "Fortune's Favor", "desc": "+15% Critical Chance", "mods": {"crit_chance": 15.0}},
	{"id": "jup_expand", "planet": "Jupiter", "name": "Expansion", "desc": "+25% Attack Reach", "mods": {"reach": 25.0}},
	{"id": "jup_abundance", "planet": "Jupiter", "name": "Abundance", "desc": "+50% Stardust Gain", "mods": {"dust_gain": 50.0}},

	{"id": "sat_ring", "planet": "Saturn", "name": "Saturn's Ring", "desc": "Begin every chamber with a 30 point shield", "mods": {"room_shield": 30.0}},
	{"id": "sat_iron", "planet": "Saturn", "name": "Iron Discipline", "desc": "+15 Armor", "mods": {"armor": 15.0}},
	{"id": "sat_keeper", "planet": "Saturn", "name": "Timekeeper", "desc": "+50% Parry Window", "mods": {"parry_window": 50.0}},
	{"id": "sat_fate", "planet": "Saturn", "name": "Heavy Fate", "desc": "+50% Heavy Attack Damage", "mods": {"heavy_dmg": 50.0}},

	{"id": "nep_mist", "planet": "Neptune", "name": "Sea Mist", "desc": "+30% Dash Distance and +6% Dodge Chance", "mods": {"dash_dist": 30.0, "dodge": 6.0}},
	{"id": "nep_dream", "planet": "Neptune", "name": "Dreamtide", "desc": "+20% Skill Damage and -15% Skill Cooldowns", "mods": {"skill_dmg": 20.0, "haste": 15.0}},
	{"id": "nep_depths", "planet": "Neptune", "name": "Drowning Depths", "desc": "+10% Critical Chance and +25% Critical Damage", "mods": {"crit_chance": 10.0, "crit_dmg": 25.0}},
	{"id": "nep_veil", "planet": "Neptune", "name": "Sea Veil", "desc": "Take 10% less damage and +20 Max Health", "mods": {"dmg_reduction": 10.0, "max_hp": 20.0}},
]


## KAVUŞUM (☌) ve KARŞITLIK (☍) LÜTUFLARI
## Kavuşum: iki gezegen gökte buluşur, güçleri birleşir. İkisinden de en az bir lütfun varsa
## o gezegenlerden birinin lütuf seçiminde ara sıra karşına çıkar.
## Karşıtlık: karşıt gezegenlerin gerilimi; çok güçlü ama bir bedeli var.
const DUOS := [
	{"id": "cj_passion", "type": "conj", "planet": "Mars", "planet2": "Venus", "name": "Passion", "desc": "+25% Damage and +3% Life Steal", "mods": {"damage": 25.0, "lifesteal": 3.0}},
	{"id": "cj_eclipse", "type": "conj", "planet": "Sun", "planet2": "Moon", "name": "Eclipse", "desc": "+15% Critical Chance and +60% Critical Damage", "mods": {"crit_chance": 15.0, "crit_dmg": 60.0}},
	{"id": "cj_thunder", "type": "conj", "planet": "Jupiter", "planet2": "Mercury", "name": "Thunderbolt", "desc": "Dashing through enemies deals damage, -30% Dash Cooldown, +25% Skill Damage", "mods": {"dash_cdr": 30.0, "skill_dmg": 25.0}, "flags": ["dash_strike"]},
	{"id": "cj_fortress", "type": "conj", "planet": "Saturn", "planet2": "Venus", "name": "Golden Fortress", "desc": "Begin every chamber with a 40 point shield, +15 Armor", "mods": {"room_shield": 40.0, "armor": 15.0}},
	{"id": "cj_nova", "type": "conj", "planet": "Sun", "planet2": "Mars", "name": "Supernova", "desc": "+30% Damage and +60% Finisher Damage", "mods": {"damage": 30.0, "finisher_dmg": 60.0}},
	{"id": "cj_deepdream", "type": "conj", "planet": "Moon", "planet2": "Neptune", "name": "Deep Dream", "desc": "+15% Dodge Chance and regenerate 1.5 health per second", "mods": {"dodge": 15.0, "regen": 1.5}},
	{"id": "cj_crown", "type": "conj", "planet": "Jupiter", "planet2": "Sun", "name": "Royal Fortune", "desc": "+15% Critical Chance, +50% Stardust, +30 Max Health", "mods": {"crit_chance": 15.0, "dust_gain": 50.0, "max_hp": 30.0}},
	{"id": "cj_riptide", "type": "conj", "planet": "Mercury", "planet2": "Neptune", "name": "Riptide", "desc": "+25% Move Speed, +40% Dash Distance, -20% Skill Cooldowns", "mods": {"move_speed": 25.0, "dash_dist": 40.0, "haste": 20.0}},
	{"id": "op_lightshadow", "type": "opp", "planet": "Sun", "planet2": "Saturn", "name": "Light and Shadow", "desc": "+50% Damage, but -30 Max Health", "mods": {"damage": 50.0, "max_hp": -30.0}},
	{"id": "op_warcalm", "type": "opp", "planet": "Mars", "planet2": "Moon", "name": "War and Calm", "desc": "+40% Attack Speed, but take 15% more damage", "mods": {"atk_speed": 40.0, "dmg_reduction": -15.0}},
	{"id": "op_mindmight", "type": "opp", "planet": "Jupiter", "planet2": "Saturn", "name": "Hope and Limit", "desc": "+60% Skill Damage, but +40% Dash Cooldown", "mods": {"skill_dmg": 60.0, "dash_cdr": -40.0}},
	{"id": "op_dreamwake", "type": "opp", "planet": "Neptune", "planet2": "Sun", "name": "Dream and Waking", "desc": "+25% Critical Chance, but -20% Move Speed", "mods": {"crit_chance": 25.0, "move_speed": -20.0}},
]


static func get_boon(id: String) -> Dictionary:
	for b in BOONS:
		if b["id"] == id:
			return b
	for d in DUOS:
		if d["id"] == id:
			return d
	return {}


static func has_planet(owned: Array, planet: String) -> bool:
	for id in owned:
		var b: Dictionary = get_boon(String(id))
		if not b.is_empty() and not b.has("type") and String(b["planet"]) == planet:
			return true
	return false


## Bu gezegenin seçiminde çıkabilecek kavuşum/karşıtlık lütufları (iki gezegenden de lütfun olmalı)
static func duos_for(planet: String, owned: Array) -> Array:
	var out: Array = []
	for d in DUOS:
		if owned.has(d["id"]):
			continue
		if String(d["planet"]) != planet and String(d["planet2"]) != planet:
			continue
		if has_planet(owned, String(d["planet"])) and has_planet(owned, String(d["planet2"])):
			out.append(d)
	return out


## Bir gezegenden sahip olunmayan 3 lütuf seçer (yetmezse başka gezegenlerden tamamlar)
static func offer(planet: String, owned: Array) -> Array:
	var pool: Array = []
	for b in BOONS:
		if b["planet"] == planet and not owned.has(b["id"]):
			pool.append(b)
	pool.shuffle()
	var out: Array = pool.slice(0, 3)
	# kavuşum/karşıtlık: koşullar sağlanıyorsa %45 ihtimalle kartlardan biri onunla değişir
	var duos := duos_for(planet, owned)
	if not duos.is_empty() and randf() < 0.45:
		duos.shuffle()
		if out.size() >= 3:
			out[2] = duos[0]
		else:
			out.append(duos[0])
	if out.size() < 3:
		var rest: Array = []
		for b in BOONS:
			if not owned.has(b["id"]) and not out.has(b):
				rest.append(b)
		rest.shuffle()
		for b in rest:
			if out.size() >= 3:
				break
			out.append(b)
	return out


static func random_planet(exclude := "") -> String:
	var keys: Array = PLANETS.keys()
	keys.erase(exclude)
	return String(keys[randi() % keys.size()])


## Lütufları kahraman değerlerine uygular
static func apply(s: Dictionary, owned: Array) -> void:
	for id in owned:
		var b := get_boon(String(id))
		if b.is_empty():
			continue
		var mods: Dictionary = b.get("mods", {})
		for k in mods:
			s[k] = float(s.get(k, 0.0)) + float(mods[k])
		var flags: Array = b.get("flags", [])
		for f in flags:
			s[f] = true
