extends RefCounted
## RETROLAR VE TUTULMALAR: isteğe bağlı zorluk lanetleri (Hades'teki Heat / Pact of Punishment gibi).
## Gözlemevindeki Gök Kadranı'ndan açılır. Her kademe "retro seviyesi" (ısı) ekler.
## Her retro seviyesi run'da kazanılan yıldız tozunu %10 artırır.
## Koç'u yendiğin en yüksek retro seviyesi rekor olarak saklanır.
## Astrolojik mantık: retro gezegen, kendi alanında işleri tersine çevirir.

const CURSES := [
	{"id": "mars", "glyph": "♂", "name": "MARS RETROGRADE", "desc": "Enemies deal +20% damage per rank", "max": 3, "heat": 1},
	{"id": "jupiter", "glyph": "♃", "name": "JUPITER RETROGRADE", "desc": "Enemies have +25% health per rank", "max": 3, "heat": 1},
	{"id": "pluto", "glyph": "♇", "name": "PLUTO RETROGRADE", "desc": "Enemies prepare their attacks 12% faster per rank", "max": 2, "heat": 1},
	{"id": "moon", "glyph": "☽", "name": "LUNAR ECLIPSE", "desc": "+15% chance for elite enemies per rank", "max": 2, "heat": 1},
	{"id": "mercury", "glyph": "☿", "name": "MERCURY RETROGRADE", "desc": "Dash cooldown +40% per rank", "max": 2, "heat": 1},
	{"id": "saturn", "glyph": "♄", "name": "SATURN RETROGRADE", "desc": "All healing -30% per rank", "max": 2, "heat": 1},
	{"id": "sun", "glyph": "☉", "name": "SOLAR ECLIPSE", "desc": "-20% Max Health per rank", "max": 2, "heat": 1},
	{"id": "venus", "glyph": "♀", "name": "VENUS RETROGRADE", "desc": "Sanctuary doors never appear", "max": 1, "heat": 2},
	{"id": "neptune", "glyph": "♆", "name": "NEPTUNE FOG", "desc": "Only one door appears after each chamber", "max": 1, "heat": 2},
	{"id": "eclipse", "glyph": "♈", "name": "TOTAL ECLIPSE", "desc": "Aries awakens a fourth, final phase", "max": 1, "heat": 3},
]


static func rank(retro: Dictionary, id: String) -> int:
	return int(retro.get(id, 0))


static func heat(retro: Dictionary) -> int:
	var h := 0
	for c in CURSES:
		h += rank(retro, String(c["id"])) * int(c["heat"])
	return h


static func max_heat() -> int:
	var h := 0
	for c in CURSES:
		h += int(c["max"]) * int(c["heat"])
	return h


static func info(id: String) -> Dictionary:
	for c in CURSES:
		if c["id"] == id:
			return c
	return {}
