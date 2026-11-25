extends RefCounted
## ELEMENTLER: Ateş · Toprak · Hava · Su (astrolojinin dört elementi)
## Üstünlük döngüsü: Su > Ateş > Hava > Toprak > Su
##   su ateşi söndürür · ateş havayı yakar · rüzgâr toprağı aşındırır · toprak suyu emer
## Kahramanın elementi, aldığı gezegen lütuflarında en çok hangi element varsa odur.
## Ne kadar çok lütuf o elementteyse üstünlük de zayıflık da o kadar belirgin olur (1-3 lütuf).

const INFO := {
	"fire": {"name": "FIRE", "col": Color(1.0, 0.45, 0.2)},
	"earth": {"name": "EARTH", "col": Color(0.55, 0.85, 0.35)},
	"air": {"name": "AIR", "col": Color(0.75, 0.9, 1.0)},
	"water": {"name": "WATER", "col": Color(0.3, 0.65, 1.0)},
}
const PLANET_EL := {"Sun": "fire", "Mars": "fire", "Venus": "earth", "Saturn": "earth",
	"Mercury": "air", "Jupiter": "air", "Moon": "water", "Neptune": "water"}
const ZONE_EL := {"aries": "fire", "taurus": "earth", "gemini": "air", "cancer": "water", "leo": "fire", "virgo": "earth",
	"libra": "air", "scorpio": "water", "sagittarius": "fire", "capricorn": "earth", "aquarius": "air", "pisces": "water"}
const BEATS := {"water": "fire", "fire": "air", "air": "earth", "earth": "water"}


## Lütuf listesinden kahramanın elementi ve o elementteki lütuf sayısı: [element, adet]
static func of_boons(boons: Array) -> Array:
	var cnt := {}
	var last := ""
	var Boons = load("res://scripts/boons.gd")
	for id in boons:
		var b: Dictionary = Boons.get_boon(String(id))
		if b.is_empty():
			continue
		var el := String(PLANET_EL.get(String(b.get("planet", "")), ""))
		if el == "":
			continue
		cnt[el] = int(cnt.get(el, 0)) + 1
		last = el
	var best := ""
	var bn := 0
	for el in cnt:
		var n: int = cnt[el]
		if n > bn or (n == bn and el == last):
			bn = n
			best = el
	return [best, bn]


## Hasar çarpanı: üstünse +%12 / lütuf, zayıfsa -%8 / lütuf (en çok 3 lütuf sayılır)
static func mult(hero_el: String, n: int, target_el: String) -> float:
	if hero_el == "" or target_el == "" or n <= 0:
		return 1.0
	var k := mini(n, 3)
	if BEATS.get(hero_el, "") == target_el:
		return 1.0 + 0.12 * float(k)
	if BEATS.get(target_el, "") == hero_el:
		return 1.0 - 0.08 * float(k)
	return 1.0


static func beats(el: String) -> String:
	return String(BEATS.get(el, ""))


static func beaten_by(el: String) -> String:
	for k in BEATS:
		if BEATS[k] == el:
			return k
	return ""
