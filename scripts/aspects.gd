extends RefCounted
## SATÜRN DEMİRCİ'NİN BURÇ MÜHÜRLERİ (silah görünüşleri)
## Her boss yenilince o burcun cevheri düşer (ilk zaferde 2, sonra 1). Demirci cevherle silahına
## o burcun mührünü işler; mühür silahın oynanışını değiştirir. Seviye n için n cevher gerekir (en çok 3).
## Aynı anda bir mühür takılır; tüm silahlarda geçerlidir.

const LIST := [
	{"id": "aries", "glyph": "♈", "ore": "MARS IRON", "name": "SEAL OF THE RAM", "col": Color(1.0, 0.45, 0.3),
		"desc": "After a dash, your next attack within 1.5 s deals +%d%% damage", "vals": [40, 60, 80]},
	{"id": "taurus", "glyph": "♉", "ore": "VENUS COPPER", "name": "SEAL OF THE BULL", "col": Color(0.55, 1.0, 0.45),
		"desc": "+20%% heavy damage; heavy hits give you a %d point shield", "vals": [8, 12, 16]},
	{"id": "gemini", "glyph": "♊", "ore": "MERCURY QUICKSILVER", "name": "SEAL OF THE TWINS", "col": Color(0.6, 0.8, 1.0),
		"desc": "Every 4th hit echoes for %d%% damage", "vals": [40, 55, 70]},
	{"id": "cancer", "glyph": "♋", "ore": "MOON SILVER", "name": "SEAL OF THE CRAB", "col": Color(0.5, 0.9, 1.0),
		"desc": "A perfect parry gives you a %d point shield", "vals": [15, 22, 30]},
	{"id": "leo", "glyph": "♌", "ore": "SUN GOLD", "name": "SEAL OF THE LION", "col": Color(1.0, 0.8, 0.4),
		"desc": "Each kill gives +%d%% damage for 4 s (stacks 3 times)", "vals": [8, 12, 16]},
	{"id": "virgo", "glyph": "♍", "ore": "EARTH CRYSTAL", "name": "SEAL OF THE MAIDEN", "col": Color(0.5, 1.0, 0.85),
		"desc": "+%d%% critical chance", "vals": [8, 12, 16]},
]


static func get_aspect(id: String) -> Dictionary:
	for a in LIST:
		if a["id"] == id:
			return a
	return {}


static func value(id: String, lv: int) -> float:
	var a := get_aspect(id)
	if a.is_empty() or lv <= 0:
		return 0.0
	return float(a["vals"][clampi(lv, 1, 3) - 1])


static func describe(id: String, lv: int) -> String:
	var a := get_aspect(id)
	return TranslationServer.translate(String(a["desc"])) % int(value(id, maxi(lv, 1)))
