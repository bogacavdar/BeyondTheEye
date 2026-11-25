extends RefCounted
## AY ANA'NIN TILSIMLARI
## Ay Ana'ya Ay Taşı verdikçe bağınız derinleşir; her bağ seviyesinde yeni bir tılsım verir.
## Her run'a bir tılsım takılır. Tılsım kullanıldıkça (takılı girilen run sayısı) seviye atlar: 3 / 8 run.

const MAX_BOND := 5
const LIST := [
	{"id": "crescent", "bond": 1, "glyph": "☽", "name": "CRESCENT", "desc": "Dashing through enemies deals damage; +%d%% Dash Distance"},
	{"id": "newmoon", "bond": 2, "glyph": "●", "name": "NEW MOON", "desc": "Begin every run with a random blessing; +%d Max Health"},
	{"id": "tide", "bond": 3, "glyph": "≈", "name": "TIDE", "desc": "Take %d%% less damage while below 30%% health"},
	{"id": "eclipse", "bond": 4, "glyph": "◐", "name": "ECLIPSE", "desc": "+%d%% damage to bosses"},
	{"id": "fullmoon", "bond": 5, "glyph": "○", "name": "FULL MOON", "desc": "Once per run, rise again with half health; +%d Max Health"},
]


static func get_charm(id: String) -> Dictionary:
	for c in LIST:
		if c["id"] == id:
			return c
	return {}


static func level(runs: int) -> int:
	return 1 + (1 if runs >= 3 else 0) + (1 if runs >= 8 else 0)


## Seviyeye göre ana değer
static func value(id: String, lv: int) -> int:
	match id:
		"crescent":
			return [15, 25, 35][lv - 1]
		"newmoon":
			return [10, 20, 30][lv - 1]
		"tide":
			return [20, 30, 40][lv - 1]
		"eclipse":
			return [20, 30, 40][lv - 1]
		"fullmoon":
			return [10, 20, 30][lv - 1]
	return 0


static func describe(id: String, lv: int) -> String:
	var c := get_charm(id)
	return TranslationServer.translate(String(c["desc"])) % value(id, lv)


static func apply(s: Dictionary, id: String, lv: int) -> void:
	var v := float(value(id, lv))
	match id:
		"crescent":
			s["dash_strike"] = true
			s["dash_dist"] = float(s.get("dash_dist", 0.0)) + v
		"newmoon":
			s["max_hp"] = float(s.get("max_hp", 0.0)) + v
		"eclipse":
			s["boss_dmg"] = float(s.get("boss_dmg", 0.0)) + v
		"fullmoon":
			s["revives"] = float(s.get("revives", 0.0)) + 1.0
			s["max_hp"] = float(s.get("max_hp", 0.0)) + v


## Ay Ana'nın bağ seviyesine göre sözleri
const LINES := [
	"You walk in the dark, star-child. Bring me the stones the Moon has dropped, and I will light your way.",
	"Ah... a moonstone. It remembers every night it has seen. Take this crescent; it cuts through the dark.",
	"The new moon is not empty, it is a promise. Begin each journey with something in your hands.",
	"The tide always returns. When you are low, let it carry you instead of drowning you.",
	"Even the Sun bows when I pass before it. Carry the eclipse to the great signs.",
	"You have given me light, child. Now take the full moon. If you fall, I will lift you once.",
]
