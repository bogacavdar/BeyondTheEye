extends Node
## GÖKSEL YANKI: bir burcun imza hamlesini, kaynağın (boss) bulunduğu yerden tekrar eder.
## - Balık'ın 3. evresi "Burçların Yankısı" bunu kullanır.
## - Sonsuz Gökyüzü döngülerinde her boss, düzenli aralıklarla başka bir burcun yankısını taşır.

const H = preload("res://scripts/hazards.gd")
const EnemyScript = preload("res://scripts/enemy.gd")
const SIGNS := ["aries", "taurus", "gemini", "cancer", "leo", "virgo", "libra", "scorpio", "sagittarius", "capricorn", "aquarius"]
const NAMES := {"aries": "ECHO OF ARIES", "taurus": "ECHO OF TAURUS", "gemini": "ECHO OF GEMINI", "cancer": "ECHO OF CANCER",
	"leo": "ECHO OF LEO", "virgo": "ECHO OF VIRGO", "libra": "ECHO OF LIBRA", "scorpio": "ECHO OF SCORPIO",
	"sagittarius": "ECHO OF SAGITTARIUS", "capricorn": "ECHO OF CAPRICORN", "aquarius": "ECHO OF AQUARIUS"}

var hero = null
var par: Node = null          # tehlikelerin ekleneceği sahne (oda)
var center := Vector3.ZERO    # yankının çıktığı yer
var bounds := 10.0
var dm := 1.0
var aim := Vector3(0, 0, 1)

# --- Sonsuz Gökyüzü kipi: bir boss'a bağlı, aralıklarla kendiliğinden yankılar
var source: Node3D = null
var own := ""                 # boss'un kendi burcu (yankılanmaz)
var every := 10.0
var on_hint: Callable
var _t := 4.0
var _bag: Array = []


func _process(delta: float) -> void:
	if source == null:
		return
	if not is_instance_valid(source) or bool(source.get("dead")):
		queue_free()
		return
	_t -= delta
	if _t > 0.0:
		return
	_t = every
	if _bag.is_empty():
		_bag = SIGNS.duplicate()
		_bag.erase(own)
		_bag.shuffle()
	var sg: String = String(_bag.pop_back())
	center = Vector3(source.global_position.x, 0, source.global_position.z)
	var m = source.get("dmg_mult")
	dm = float(m) if m != null else 1.0
	if on_hint.is_valid():
		on_hint.call(String(NAMES[sg]), "")
	cast(sg)


func _blast(p: Vector3, r: float, delay: float, dmg: float, col: Color, eff := "") -> void:
	var b := H.Blast.new()
	b.hero = hero
	b.radius = r
	b.delay = delay
	b.dmg = dmg * dm
	b.col = col
	b.eff = eff
	par.add_child(b)
	b.global_position = H.clamp_arena(p, bounds)


func _line(from: Vector3, dir: Vector3, length: float, width: float, delay: float, dmg: float, col: Color, eff := "") -> void:
	var ln := H.Line.new()
	ln.hero = hero
	ln.dir = dir
	ln.length = length
	ln.width = width
	ln.delay = delay
	ln.dmg = dmg * dm
	ln.col = col
	ln.eff = eff
	par.add_child(ln)
	ln.global_position = Vector3(from.x, 0, from.z)


## Verilen burcun hamlesini yankılar (Balık'ın 3. evresi ve Sonsuz Gökyüzü bosslarının Göksel Yankısı)
func cast(sg: String) -> void:
	if not H.hero_ok(hero):
		return
	var hp: Vector3 = hero.global_position
	hp.y = 0.0
	aim = hp - center
	aim.y = 0.0
	aim = aim.normalized() if aim.length() > 0.1 else Vector3(0, 0, 1)
	match sg:
		"aries":
			# üç koç saldırısı: kenarlardan sana doğru
			for i in 3:
				var a := randf() * TAU
				var from := Vector3(cos(a), 0, sin(a)) * (bounds + 0.5)
				var d := (hp - from).normalized()
				_line(from, d, bounds * 2.2, 2.0, 1.0 + float(i) * 0.3, 20.0, Color(1.0, 0.45, 0.3))
		"taurus":
			# deprem: önce yakını, sonra dış halka
			_blast(center, 3.5, 0.9, 22.0, Color(0.55, 1.0, 0.45))
			for i in 8:
				var a2 := TAU * float(i) / 8.0
				_blast(center + Vector3(cos(a2), 0, sin(a2)) * 6.0, 2.0, 1.6, 18.0, Color(0.55, 1.0, 0.45))
		"gemini":
			var g := H.Gust.new()
			g.hero = hero
			var ga := randf() * TAU
			g.dir = Vector3(cos(ga), 0, sin(ga))
			g.bounds = bounds
			g.strength = 3.8
			par.add_child(g)
			for i in 6:
				var bb := EnemyScript.Bubble.new()
				bb.hero = hero
				bb.dmg = 12.0 * dm
				bb.vel = Vector3(cos(TAU * float(i) / 6.0), 0, sin(TAU * float(i) / 6.0)) * 3.0
				par.add_child(bb)
				bb.global_position = center + Vector3(0, 1.3, 0)
		"cancer":
			for i in 3:
				var tw := EnemyScript.TideWave.new()
				tw.hero = hero
				tw.dir = aim.rotated(Vector3.UP, (float(i) - 1.0) * 0.6)
				tw.dmg = 18.0 * dm
				tw.width = 4.0
				tw.speed = 7.5
				tw.travel = bounds * 2.0
				par.add_child(tw)
				tw.global_position = Vector3(center.x, 0, center.z)
		"leo":
			_blast(hp, 2.2, 1.0, 22.0, Color(1.0, 0.8, 0.4))
			for i in 5:
				var a3 := randf() * TAU
				_blast(Vector3(cos(a3), 0, sin(a3)) * randf_range(2.0, bounds - 1.0), 2.2, 1.0 + float(i) * 0.15, 20.0, Color(1.0, 0.8, 0.4))
		"virgo":
			# hasat: üstünde kesişen iki tırpan hattı
			var va := randf() * TAU
			var vd := Vector3(cos(va), 0, sin(va))
			for d2 in [vd, Vector3(-vd.z, 0, vd.x)]:
				var dd: Vector3 = d2
				_line(hp - dd * (bounds + 1.0), dd, bounds * 2.2, 1.6, 1.1, 20.0, Color(0.5, 1.0, 0.85))
		"libra":
			# terazi: arenanın yarısı (tarafı seçilir) hüküm giyer
			var la := randf() * TAU
			var ld := Vector3(cos(la), 0, sin(la))
			var side := Vector3(-ld.z, 0, ld.x)
			_line(side * (bounds * 0.5) - ld * (bounds + 1.0), ld, bounds * 2.2, bounds, 1.4, 24.0, Color(0.4, 1.0, 0.8))
		"scorpio":
			for i in 3:
				var p3 := hp if i == 0 else Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized() * randf_range(2.0, bounds - 1.5)
				var b := H.Blast.new()
				b.hero = hero
				b.radius = 1.8
				b.delay = 0.9
				b.dmg = 14.0 * dm
				b.col = Color(0.5, 1.0, 0.3)
				b.eff = "poison"
				b.pool_life = 4.0
				par.add_child(b)
				b.global_position = H.clamp_arena(p3, bounds)
		"sagittarius":
			for i in 8:
				var off := Vector3.ZERO if i == 0 else Vector3(randf_range(-4.0, 4.0), 0, randf_range(-4.0, 4.0))
				_blast(hp + off, 1.3, 1.0 + float(i) * 0.08, 16.0, Color(0.75, 0.6, 1.0))
		"capricorn":
			var n := 10
			var gap := randi() % n
			for i in n:
				if i == gap:
					continue
				var a4 := TAU * float(i) / float(n)
				_blast(hp + Vector3(cos(a4), 0, sin(a4)) * 3.0, 1.3, 1.0, 18.0, Color(0.5, 0.9, 1.0), "freeze")
			_blast(hp, 1.6, 1.5, 18.0, Color(0.5, 0.9, 1.0), "freeze")
		"aquarius":
			_blast(hp, 1.4, 1.0, 18.0, Color(0.65, 0.9, 1.0), "slow")
			for i in 6:
				var a5 := randf() * TAU
				_blast(Vector3(cos(a5), 0, sin(a5)) * randf_range(2.0, bounds - 0.5), 1.3, 1.0 + float(i) * 0.12, 18.0, Color(0.65, 0.9, 1.0), "slow")
	Fx.flash_light(center + Vector3(0, 3, 0), Color(0.88, 0.65, 1.0), 8.0, 10.0, 0.4)
