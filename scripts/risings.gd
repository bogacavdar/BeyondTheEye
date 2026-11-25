extends RefCounted
## YÜKSELEN BURÇ: her run'ın başında seçilir, run'ın kurallarını değiştirir (bir avantaj + bir bedel).
## Koç yükseleni baştan açık; diğerleri o burcun boss'unu ilk kez yenince açılır.

const LIST := [
	{"id": "aries", "glyph": "♈", "name": "ARIES ASCENDANT", "col": Color(1.0, 0.45, 0.3),
		"desc": "+20% Damage and -25% Dash Cooldown, but -20 Max Health",
		"mods": {"damage": 20.0, "dash_cdr": 25.0, "max_hp": -20.0}},
	{"id": "taurus", "glyph": "♉", "name": "TAURUS ASCENDANT", "col": Color(0.55, 1.0, 0.45),
		"desc": "+30 Max Health and +10 Armor, but -15% Move Speed",
		"mods": {"max_hp": 30.0, "armor": 10.0, "move_speed": -15.0}},
	{"id": "gemini", "glyph": "♊", "name": "GEMINI ASCENDANT", "col": Color(0.6, 0.8, 1.0),
		"desc": "Blessing choices show 4 cards, but skill cooldowns are 20% longer",
		"mods": {"haste": -20.0}},
	{"id": "cancer", "glyph": "♋", "name": "CANCER ASCENDANT", "col": Color(0.5, 0.9, 1.0),
		"desc": "Regenerate 1.5 health per second in battle, but -15% Damage",
		"mods": {"regen": 1.5, "damage": -15.0}},
	{"id": "leo", "glyph": "♌", "name": "LEO ASCENDANT", "col": Color(1.0, 0.8, 0.4),
		"desc": "+50% Stardust and +15% Critical Chance, but enemies have 15% more health",
		"mods": {"dust_gain": 50.0, "crit_chance": 15.0}},
	{"id": "virgo", "glyph": "♍", "name": "VIRGO ASCENDANT", "col": Color(0.5, 1.0, 0.85),
		"desc": "+50% Parry Window and +10% Dodge Chance, but -10% Damage",
		"mods": {"parry_window": 50.0, "dodge": 10.0, "damage": -10.0}},
	{"id": "libra", "glyph": "♎", "name": "LIBRA ASCENDANT", "col": Color(0.4, 1.0, 0.8),
		"desc": "+15% Damage and take 10% less damage, but -30% Stardust",
		"mods": {"damage": 15.0, "dmg_reduction": 10.0, "dust_gain": -30.0}},
	{"id": "scorpio", "glyph": "♏", "name": "SCORPIO ASCENDANT", "col": Color(0.5, 1.0, 0.3),
		"desc": "+12% Critical Chance and +50% Critical Damage, but -25 Max Health",
		"mods": {"crit_chance": 12.0, "crit_dmg": 50.0, "max_hp": -25.0}},
	{"id": "sagittarius", "glyph": "♐", "name": "SAGITTARIUS ASCENDANT", "col": Color(0.7, 0.55, 1.0),
		"desc": "+20% Move Speed and +20% Attack Reach, but take 10% more damage",
		"mods": {"move_speed": 20.0, "reach": 20.0, "dmg_reduction": -10.0}},
	{"id": "capricorn", "glyph": "♑", "name": "CAPRICORN ASCENDANT", "col": Color(0.4, 1.0, 0.9),
		"desc": "+40 Max Health and take 12% less damage, but -12% Move Speed",
		"mods": {"max_hp": 40.0, "dmg_reduction": 12.0, "move_speed": -12.0}},
]


static func get_rising(id: String) -> Dictionary:
	for r in LIST:
		if r["id"] == id:
			return r
	return {}


static func unlocked(id: String) -> bool:
	var GD = load("res://scripts/game_data.gd")
	match id:
		"aries":
			return true
		"taurus":
			return GD.taurus_defeated
		"gemini":
			return GD.gemini_defeated
		"cancer":
			return GD.cancer_defeated
		"leo":
			return GD.leo_defeated
		"virgo":
			return GD.virgo_defeated
		"libra":
			return GD.libra_defeated
		"scorpio":
			return GD.scorpio_defeated
		"sagittarius":
			return GD.sagittarius_defeated
		"capricorn":
			return GD.capricorn_defeated
	return false


static func available() -> Array:
	var out: Array = []
	for r in LIST:
		if unlocked(String(r["id"])):
			out.append(r)
	return out


static func apply(s: Dictionary, id: String) -> void:
	var r := get_rising(id)
	var mods: Dictionary = r.get("mods", {})
	for k in mods:
		s[k] = float(s.get(k, 0.0)) + float(mods[k])
