extends CharacterBody3D
## DÜŞMANLAR: burçların bozulmasıyla karanlığa dönmüş yıldız ruhları. 4 tip:
##   shade  · GÖLGE    : yakın dövüşçü. Pençe (parry'lenir) + arada bir parry'lenemeyen yırtma.
##   caster · KÂHİN    : uzak durur, 3'lü ışık mermisi atar (parry'lenemez, atılarak kaçılır).
##   leaper · ATLAYAN  : uzaktan üstüne atlar; düşeceği yer yerde kızıl daireyle görünür (parry'lenemez).
##   brute  · KOLOS    : iri ve yavaş. Ezme darbesi (parry'lenir) + çevresine deprem dalgası (parry'lenemez).
## UYARI RENKLERİ: altın-turuncu uyarı = parry'lenebilir. KIZIL, yanıp sönen uyarı = parry'lenemez, kaç!
## Kan yok: vurulunca yıldız tozu ve altın kırıkları saçılır. Başlarının üstünde can barı var.

signal killed(enemy)

const SlashFx = preload("res://scripts/slash_fx.gd")
const HitFx = preload("res://scripts/hit_fx.gd")
const PARRY_COL := Color(1.0, 0.72, 0.2)
const DANGER_COL := Color(1.0, 0.1, 0.18)

var kind := "shade"       # dövüş rolü: shade / caster / leaper / brute
var zone := "aries"       # bölge: rol aynı kalır, görünüş ve mekanik bölgeye göre değişir
var hp_mult := 1.0        # oda derinliğine göre (room.gd verir)
var dmg_mult := 1.0
var elite := false       # seçkin: altın haleli, çok daha güçlü
var windup_mult := 1.0   # Plüton retrosu: daha hızlı hazırlık
var max_hp := 90.0
var hp := 90.0
var radius := 0.45
var speed := 3.6
var size_k := 1.0
var dead := false
var hero = null
var state := "spawn"
var _st := 0.0
var _face := Vector3.FORWARD
var _knock := Vector3.ZERO
var _move := Vector3.ZERO
var _flash := 0.0
var _t := 0.0
var _bounds := 10.5
var _cd := {}                  # saldırı adı -> kalan bekleme
var _global_cd := 0.6
var attacks: Array = []
var atk: Dictionary = {}       # şu anki saldırı
var _aim_dir := Vector3.FORWARD
var _aim_point := Vector3.ZERO
var _done := false
var _leap_from := Vector3.ZERO
var _stun_len := 0.3
var _parried := false
var _strafe := 1.0
var _burn_t := 0.0
var _burn_dps := 0.0
var _burn_acc := 0.0
var _flinch := 0.0          # vurulunca geriye esneme
var _charge_traveled := 0.0
var _charge_hit := false
var shield_node: Node3D
var last_dealt := 0.0       # son vuruşta gerçekten verilen hasar (can çalma bunu kullanır)
var pebble := false         # Taş Golemi parçalanınca çıkan küçük taşçık
var ward := 0.0             # Ülker Rahibesi'nin verdiği koruma kalkanı
var _ward_t := 0.0
var _ward_node: MeshInstance3D
var _ward_cd := 3.0
var _sink := 0.0            # Köstebek toprağa gömülme miktarı
var _burrow_locked := false
var _dig_fx := 0.0
var _halo: Node3D
var bolt_col := Color(1.0, 0.2, 0.3)

var body_root: Node3D
var vis: Node3D
var arm_l: Node3D
var arm_r: Node3D
var tele: MeshInstance3D
var tele_mat: StandardMaterial3D
var hp_bar: MeshInstance3D
var hp_mat: ShaderMaterial
var m_body: StandardMaterial3D
var m_cloth: StandardMaterial3D
var m_eye: StandardMaterial3D
var m_claw: StandardMaterial3D
var _base_body := Color(0.25, 0.1, 0.45)
var _base_cloth := Color(0.3, 0.12, 0.5)


func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 4
	collision_mask = 0
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	_t = randf() * 10.0
	_strafe = 1.0 if randf() < 0.5 else -1.0
	_setup_kind()
	if zone == "aries":
		_aries_variant()
	elif zone == "taurus":
		_taurus_variant()
	# zorluk: derinlik çarpanları, daha kısa hazırlık ve daha sık saldırı
	var em := 1.0
	if elite:
		em = 1.25
		max_hp *= 1.6
		size_k *= 1.15
		radius *= 1.15
		_base_cloth = Color(0.9, 0.65, 0.2)
		_base_body = Color(0.7, 0.45, 0.15)
	max_hp *= hp_mult
	speed *= 1.06
	for a in attacks:
		a["dmg"] = float(a["dmg"]) * dmg_mult * em
		a["windup"] = float(a["windup"]) * 0.92 * windup_mult
		if not bool(a["parry"]):
			a["windup"] = float(a["windup"]) * 0.4   # kırmızı (parry'lenemez) saldırılar ani: görünce hemen atıl
		a["recover"] = float(a["recover"]) * 0.9
		a["cd"] = float(a["cd"]) * 0.85
	hp = max_hp
	for a in attacks:
		_cd[a["name"]] = randf_range(0.3, 1.2)
	_build()
	vis.position.y = -1.6
	vis.scale = Vector3(0.3, 0.3, 0.3)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(vis, "position:y", 0.0, 0.7).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(vis, "scale", Vector3.ONE * size_k, 0.7).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Tiplere göre değerler ve saldırılar.
## Saldırı: shape (fan/circle/line), min/max (başlama mesafesi), windup/act/recover (sn), dmg, reach, arc,
## parry (parry'lenebilir mi), cd (bekleme), weight (seçilme ağırlığı)
func _setup_kind() -> void:
	match kind:
		"caster":
			max_hp = 60.0
			speed = 2.9
			radius = 0.4
			attacks = [
				{"name": "bolt", "shape": "line", "min": 3.5, "max": 12.0, "windup": 0.75, "act": 0.15, "recover": 0.6,
					"dmg": 12.0, "reach": 12.0, "arc": 22.0, "parry": false, "cd": 2.4, "weight": 1.0},
			]
		"leaper":
			max_hp = 75.0
			speed = 4.3
			radius = 0.5
			attacks = [
				{"name": "claw", "shape": "fan", "min": 0.0, "max": 1.9, "windup": 0.45, "act": 0.12, "recover": 0.5,
					"dmg": 12.0, "reach": 2.2, "arc": 100.0, "parry": true, "cd": 1.0, "weight": 1.0},
				{"name": "pounce", "shape": "circle", "min": 3.2, "max": 9.0, "windup": 0.7, "act": 0.55, "recover": 0.85,
					"dmg": 22.0, "reach": 1.9, "arc": 360.0, "parry": false, "cd": 3.5, "weight": 2.0},
			]
		"brute":
			max_hp = 230.0
			speed = 2.3
			radius = 0.8
			size_k = 1.5
			_base_body = Color(0.4, 0.12, 0.3)
			_base_cloth = Color(0.35, 0.1, 0.3)
			attacks = [
				{"name": "smash", "shape": "fan", "min": 0.0, "max": 2.7, "windup": 0.8, "act": 0.16, "recover": 0.9,
					"dmg": 24.0, "reach": 3.0, "arc": 120.0, "parry": true, "cd": 1.6, "weight": 2.0},
				{"name": "quake", "shape": "circle", "min": 0.0, "max": 4.2, "windup": 1.1, "act": 0.2, "recover": 1.0,
					"dmg": 26.0, "reach": 4.2, "arc": 360.0, "parry": false, "cd": 6.0, "weight": 1.0},
			]
		_:
			kind = "shade"
			max_hp = 90.0
			speed = 3.6
			radius = 0.45
			attacks = [
				{"name": "claw", "shape": "fan", "min": 0.0, "max": 2.1, "windup": 0.55, "act": 0.14, "recover": 0.55,
					"dmg": 16.0, "reach": 2.4, "arc": 110.0, "parry": true, "cd": 1.1, "weight": 3.0},
				{"name": "rend", "shape": "fan", "min": 0.0, "max": 2.4, "windup": 0.75, "act": 0.16, "recover": 0.7,
					"dmg": 22.0, "reach": 2.8, "arc": 150.0, "parry": false, "cd": 4.0, "weight": 1.0},
			]


## KOÇ GEÇİDİ yaratıkları (rol aynı, mekanik farklı):
##  shade  -> KOR CİNİ: alevli pençe; ölünce yerinde kısa süre sonra patlayan kor bırakır
##  caster -> MARS KÂHİNİ: hedef noktaya ateş topu fırlatır, yerde yanan alev bırakır
##  leaper -> HIRÇIN KOÇ: başını eğip düz bir hatta toslar; ıskalarsa sersemler
##  brute  -> MARS SAVAŞÇISI: kalkanlı balta ustası; önden gelen hafif vuruşları kalkanıyla keser
func _aries_variant() -> void:
	_base_body = Color(0.75, 0.2, 0.04)
	_base_cloth = Color(0.55, 0.12, 0.05)
	match kind:
		"caster":
			attacks = [
				{"name": "fireball", "shape": "circle", "min": 3.0, "max": 11.0, "windup": 0.8, "act": 0.15, "recover": 0.6,
					"dmg": 14.0, "reach": 1.7, "arc": 360.0, "parry": false, "cd": 2.6, "weight": 1.0},
			]
		"leaper":
			max_hp = 80.0
			attacks = [
				{"name": "claw", "shape": "fan", "min": 0.0, "max": 1.9, "windup": 0.45, "act": 0.12, "recover": 0.5,
					"dmg": 12.0, "reach": 2.1, "arc": 90.0, "parry": true, "cd": 1.0, "weight": 1.0},
				{"name": "ramcharge", "shape": "line", "min": 3.0, "max": 9.5, "windup": 0.8, "act": 0.75, "recover": 0.45,
					"dmg": 20.0, "reach": 8.5, "arc": 0.0, "parry": false, "cd": 3.5, "weight": 2.0},
			]
		"brute":
			max_hp = 200.0
			_base_body = Color(0.6, 0.3, 0.08)


## BOĞA OTLAKLARI yaratıkları:
##  shade  -> DİKEN ÇALISI: gül başlı sarmaşık; ölünce yerde seni yavaşlatan dikenli bir alan bırakır
##  caster -> ÜLKER RAHİBESİ: yavaş tohum mermileri atar ve yakındaki bir dostuna koruma kalkanı verir (önce onu öldür!)
##  leaper -> TOPRAK KÖSTEBEĞİ: toprağa gömülür (dokunulmaz), altına gelir ve yerden fırlar
##  brute  -> TAŞ GOLEM: yere vurup ileri doğru ilerleyen bir yarık açar; ölünce 2 küçük taşçığa bölünür
func _taurus_variant() -> void:
	_base_body = Color(0.35, 0.6, 0.15)
	_base_cloth = Color(0.25, 0.45, 0.12)
	if pebble:
		kind = "shade"
		max_hp = 40.0
		speed = 4.4
		radius = 0.35
		size_k = 0.65
		_base_body = Color(0.4, 0.55, 0.3)
		attacks = [
			{"name": "claw", "shape": "fan", "min": 0.0, "max": 1.6, "windup": 0.5, "act": 0.12, "recover": 0.5,
				"dmg": 10.0, "reach": 1.9, "arc": 100.0, "parry": true, "cd": 1.0, "weight": 1.0},
		]
		return
	match kind:
		"caster":
			bolt_col = Color(0.55, 1.0, 0.45)
			attacks = [
				{"name": "bolt", "shape": "line", "min": 3.5, "max": 12.0, "windup": 0.8, "act": 0.15, "recover": 0.6,
					"dmg": 11.0, "reach": 12.0, "arc": 34.0, "parry": false, "cd": 2.6, "weight": 1.0},
			]
		"leaper":
			max_hp = 85.0
			attacks = [
				{"name": "claw", "shape": "fan", "min": 0.0, "max": 1.9, "windup": 0.45, "act": 0.12, "recover": 0.5,
					"dmg": 12.0, "reach": 2.1, "arc": 100.0, "parry": true, "cd": 1.0, "weight": 1.0},
				{"name": "burrow", "shape": "circle", "min": 3.5, "max": 12.0, "windup": 0.45, "act": 2.4, "recover": 0.7,
					"dmg": 20.0, "reach": 1.9, "arc": 360.0, "parry": false, "cd": 4.5, "weight": 2.0},
			]
		"brute":
			max_hp = 210.0
			_base_body = Color(0.3, 0.7, 0.35)
			attacks = [
				{"name": "smash", "shape": "fan", "min": 0.0, "max": 2.7, "windup": 0.8, "act": 0.16, "recover": 0.9,
					"dmg": 24.0, "reach": 3.0, "arc": 120.0, "parry": true, "cd": 1.6, "weight": 2.0},
				{"name": "fissure", "shape": "line", "min": 2.5, "max": 9.0, "windup": 1.0, "act": 0.2, "recover": 1.0,
					"dmg": 24.0, "reach": 9.0, "arc": 0.0, "parry": false, "cd": 5.0, "weight": 1.2},
			]


# ---------------------------------------------------------------- görünüş

func _m(c: Color, rough := 0.7) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	return m


func _part(parent: Node3D, mesh: Mesh, pos: Vector3, mat: Material, sc := Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.scale = sc
	parent.add_child(mi)
	return mi


func _sph(r: float, h := -1.0) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0 if h < 0.0 else h
	s.radial_segments = 16
	s.rings = 8
	return s


func _cone(r_bot: float, r_top: float, h: float, seg := 8) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.bottom_radius = r_bot
	c.top_radius = r_top
	c.height = h
	c.radial_segments = seg
	return c


func _build() -> void:
	m_body = _m(Color(0.06, 0.04, 0.12), 0.6)
	m_body.emission_enabled = true
	m_body.emission = _base_body
	m_body.emission_energy_multiplier = 0.25
	m_cloth = _m(Color(0.1, 0.06, 0.2), 0.8)
	m_cloth.emission_enabled = true
	m_cloth.emission = _base_cloth
	m_cloth.emission_energy_multiplier = 0.15
	m_eye = StandardMaterial3D.new()
	m_eye.albedo_color = Color.BLACK
	m_eye.emission_enabled = true
	m_eye.emission = Color(1.0, 0.35, 0.15) if kind != "caster" else Color(0.5, 0.8, 1.0)
	m_eye.emission_energy_multiplier = 3.0
	m_claw = _m(Color(0.15, 0.08, 0.2), 0.4)
	m_claw.emission_enabled = true
	m_claw.emission = m_eye.emission
	m_claw.emission_energy_multiplier = 0.3

	body_root = Node3D.new()
	add_child(body_root)
	vis = Node3D.new()
	body_root.add_child(vis)
	if elite:
		var el := OmniLight3D.new()
		el.light_color = Color(1.0, 0.8, 0.35)
		el.light_energy = 1.6
		el.omni_range = 3.5
		el.position = Vector3(0, 1.5, 0)
		vis.add_child(el)
	if zone == "aries":
		m_eye.emission = Color(1.0, 0.5, 0.1)
		m_claw.emission = Color(1.0, 0.4, 0.08)
		match kind:
			"caster":
				_build_seer()
			"leaper":
				_build_ram()
			"brute":
				_build_champion()
			_:
				_build_imp()
	elif zone == "taurus":
		m_eye.emission = Color(0.75, 1.0, 0.35)
		m_claw.emission = Color(0.5, 0.9, 0.3)
		if pebble:
			_build_pebble()
		else:
			match kind:
				"caster":
					_build_priestess()
				"leaper":
					_build_burrower()
				"brute":
					_build_golem()
				_:
					_build_thorn()
	else:
		match kind:
			"caster":
				_build_caster()
			"leaper":
				_build_leaper()
			"brute":
				_build_brute()
			_:
				_build_shade()

	# saldırı uyarısı (dünya koordinatında durur)
	tele = MeshInstance3D.new()
	tele_mat = StandardMaterial3D.new()
	tele_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	tele_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	tele_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	tele_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	tele_mat.vertex_color_use_as_albedo = true
	tele_mat.albedo_color = Color(1, 1, 1, 0)
	tele.material_override = tele_mat
	tele.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	tele.visible = false
	add_child(tele)
	tele.top_level = true

	# can barı (kameraya dönük)
	hp_bar = MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(1.1 if kind != "brute" else 1.7, 0.13)
	hp_bar.mesh = q
	hp_mat = ShaderMaterial.new()
	hp_mat.shader = preload("res://shaders/hp_bar.gdshader")
	hp_bar.material_override = hp_mat
	hp_bar.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	hp_bar.position.y = 2.55 * size_k
	add_child(hp_bar)


func _build_shade() -> void:
	_part(vis, _cone(0.05, 0.3, 1.1, 12), Vector3(0, 0.95, 0), m_cloth)
	for i in 6:
		var a := TAU * float(i) / 6.0
		var tm := _part(vis, _cone(0.0, 0.06, 0.55, 4), Vector3(cos(a) * 0.16, 0.42, sin(a) * 0.16), m_cloth)
		tm.rotation = Vector3(sin(a) * 0.35, 0, -cos(a) * 0.35)
	_part(vis, _sph(0.34, 0.55), Vector3(0, 1.55, 0), m_body, Vector3(1.25, 1.0, 0.85))
	_head(Vector3(0, 1.88, 0))
	arm_l = _arm(-1.0, Vector3(-0.38, 1.6, 0), 0.8)
	arm_r = _arm(1.0, Vector3(0.38, 1.6, 0), 0.8)


func _build_caster() -> void:
	# uzun, ince, yerden yüksekte süzülen kâhin; ellerinin arasında ışık küresi
	_part(vis, _cone(0.02, 0.24, 1.5, 12), Vector3(0, 1.15, 0), m_cloth)
	_part(vis, _sph(0.26, 0.5), Vector3(0, 1.95, 0), m_body, Vector3(1.0, 1.0, 0.8))
	_head(Vector3(0, 2.28, 0))
	# yüzen halkalar
	for i in 2:
		var t := TorusMesh.new()
		t.inner_radius = 0.42 + 0.14 * float(i)
		t.outer_radius = t.inner_radius + 0.025
		var rm := _part(vis, t, Vector3(0, 1.3 + 0.35 * float(i), 0), m_claw)
		rm.rotation.x = 0.3 * (1.0 if i == 0 else -1.0)
	arm_l = _arm(-1.0, Vector3(-0.3, 2.0, 0), 0.65)
	arm_r = _arm(1.0, Vector3(0.3, 2.0, 0), 0.65)
	_part(vis, _sph(0.13), Vector3(0, 1.75, -0.45), m_eye)


func _build_leaper() -> void:
	# dört ayaklı, alçak, uzun kuyruklu bir yaratık
	_part(vis, _sph(0.42, 0.6), Vector3(0, 0.75, 0), m_body, Vector3(0.9, 0.8, 1.5))
	_part(vis, _sph(0.28), Vector3(0, 0.95, -0.55), m_body, Vector3(1.0, 0.9, 1.1))
	var eye := _sph(0.04)
	_part(vis, eye, Vector3(-0.1, 1.0, -0.8), m_eye, Vector3(1.4, 0.7, 1.0))
	_part(vis, eye, Vector3(0.1, 1.0, -0.8), m_eye, Vector3(1.4, 0.7, 1.0))
	for i in 4:
		var x := -0.28 if i % 2 == 0 else 0.28
		var z := -0.35 if i < 2 else 0.35
		var leg := _part(vis, _cone(0.03, 0.07, 0.8, 6), Vector3(x, 0.38, z), m_cloth)
		leg.rotation.z = -x * 0.8
	var tail := _part(vis, _cone(0.0, 0.09, 1.2, 6), Vector3(0, 0.95, 0.95), m_cloth)
	tail.rotation.x = -1.0
	# sırttaki kırık yıldız dikenleri
	for i in 4:
		var sp := _part(vis, _cone(0.04, 0.0, 0.28, 4), Vector3(0, 1.15, -0.25 + float(i) * 0.2), m_claw)
		sp.rotation.x = 0.4
	arm_l = Node3D.new()
	arm_r = Node3D.new()
	vis.add_child(arm_l)
	vis.add_child(arm_r)


func _build_brute() -> void:
	# iri gövde, boynuzlar, kocaman yumruklar
	_part(vis, _cone(0.2, 0.42, 0.9, 12), Vector3(0, 0.6, 0), m_cloth)
	_part(vis, _sph(0.55, 0.9), Vector3(0, 1.4, 0), m_body, Vector3(1.3, 1.0, 0.95))
	_head(Vector3(0, 1.95, -0.1))
	for s in [-1.0, 1.0]:
		var horn := _part(vis, _cone(0.08, 0.0, 0.45, 6), Vector3(s * 0.22, 2.25, -0.05), m_claw)
		horn.rotation.z = -s * 0.7
	arm_l = _arm(-1.0, Vector3(-0.68, 1.65, 0), 0.9)
	arm_r = _arm(1.0, Vector3(0.68, 1.65, 0), 0.9)
	for a in [arm_l, arm_r]:
		_part(a, _sph(0.2), Vector3(0, -0.95, 0), m_body)


# ---- Koç Geçidi görünüşleri

func _bone() -> StandardMaterial3D:
	return _m(Color(0.78, 0.68, 0.52), 0.75)


func _bronze() -> StandardMaterial3D:
	var m := _m(Color(0.62, 0.38, 0.16), 0.35)
	m.metallic = 0.85
	return m


## Küçük alev kümesi (baş, kuyruk ucu, el)
func _flame(parent: Node3D, pos: Vector3, amount: int, size: float) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = amount
	p.lifetime = 0.55
	p.position = pos
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = size * 0.5
	p.direction = Vector3.UP
	p.spread = 15.0
	p.gravity = Vector3(0, 2.0, 0)
	p.initial_velocity_min = 0.4
	p.initial_velocity_max = 1.0
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.0
	var sm := SphereMesh.new()
	sm.radius = size * 0.35
	sm.height = size * 0.7
	sm.radial_segments = 6
	sm.rings = 3
	p.mesh = sm
	var fm := StandardMaterial3D.new()
	fm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fm.albedo_color = Color(1.0, 0.5, 0.12)
	p.material_override = fm
	var c := Curve.new()
	c.add_point(Vector2(0, 1))
	c.add_point(Vector2(1, 0))
	p.scale_amount_curve = c
	parent.add_child(p)
	return p


## Spiral koç boynuzu (küçülen küreler)
func _ram_horn(parent: Node3D, at: Vector3, side: float, k: float, mat: Material) -> void:
	for i in 9:
		var a := float(i) * 0.66
		var r := (0.18 + float(i) * 0.02) * k
		var p := at + Vector3(side * (r * 0.6 + float(i) * 0.025 * k), sin(a) * r, cos(a) * r * 0.9 + 0.05 * k)
		_part(parent, _sph((0.1 - float(i) * 0.008) * k), p, mat)


func _build_imp() -> void:
	# KOR CİNİ: kambur, küçük, kızgın çatlaklı bir ateş cini
	_part(vis, _sph(0.36, 0.62), Vector3(0, 1.05, 0.05), m_body, Vector3(1.1, 1.0, 1.0))
	_part(vis, _sph(0.2), Vector3(0, 1.0, -0.22), m_eye, Vector3(1.1, 0.9, 0.4))
	for s in [-1.0, 1.0]:
		var leg := _part(vis, _cone(0.05, 0.1, 0.6, 6), Vector3(s * 0.18, 0.4, 0.05), m_cloth)
		leg.rotation.x = 0.25
		_part(vis, _sph(0.09), Vector3(s * 0.18, 0.08, -0.08), m_claw, Vector3(1.0, 0.5, 1.6))
	var hp := Vector3(0, 1.5, -0.15)
	_part(vis, _sph(0.24, 0.44), hp, m_body, Vector3(1.1, 1.0, 1.1))
	var eye := _sph(0.045)
	_part(vis, eye, hp + Vector3(-0.09, 0.02, -0.21), m_eye, Vector3(1.5, 0.6, 1.0))
	_part(vis, eye, hp + Vector3(0.09, 0.02, -0.21), m_eye, Vector3(1.5, 0.6, 1.0))
	var bone := _bone()
	for s in [-1.0, 1.0]:
		var h := _part(vis, _cone(0.06, 0.0, 0.35, 6), hp + Vector3(s * 0.15, 0.2, 0.05), bone)
		h.rotation = Vector3(0.6, 0, -s * 0.5)
		var ear := _part(vis, _cone(0.05, 0.0, 0.22, 4), hp + Vector3(s * 0.24, 0.02, 0.0), m_cloth)
		ear.rotation.z = -s * 1.3
	_flame(vis, hp + Vector3(0, 0.28, 0.08), 12, 0.22)
	var tail := _part(vis, _cone(0.0, 0.06, 0.9, 6), Vector3(0, 0.75, 0.6), m_cloth)
	tail.rotation.x = -1.2
	_flame(vis, Vector3(0, 0.95, 1.05), 8, 0.16)
	arm_l = _arm(-1.0, Vector3(-0.34, 1.25, -0.05), 0.65)
	arm_r = _arm(1.0, Vector3(0.34, 1.25, -0.05), 0.65)


func _build_seer() -> void:
	# MARS KÂHİNİ: kızıl cüppeli, koç kafatası maskeli, elleri arasında ateş topu
	_part(vis, _cone(0.55, 0.16, 1.6, 14), Vector3(0, 0.9, 0), m_cloth)
	var trim := TorusMesh.new()
	trim.inner_radius = 0.5
	trim.outer_radius = 0.56
	_part(vis, trim, Vector3(0, 0.15, 0), _bronze())
	_part(vis, _sph(0.26, 0.5), Vector3(0, 1.75, 0), m_cloth, Vector3(1.1, 1.0, 0.9))
	var hood := _part(vis, _cone(0.3, 0.05, 0.55, 10), Vector3(0, 2.25, 0.05), m_cloth)
	hood.rotation.x = 0.25
	var bone := _bone()
	_part(vis, _sph(0.17), Vector3(0, 2.05, -0.17), bone, Vector3(0.9, 1.0, 0.9))
	_part(vis, _sph(0.1), Vector3(0, 1.93, -0.3), bone, Vector3(0.8, 0.7, 1.2))
	var eye := _sph(0.035)
	_part(vis, eye, Vector3(-0.07, 2.08, -0.32), m_eye, Vector3(1.3, 0.8, 1.0))
	_part(vis, eye, Vector3(0.07, 2.08, -0.32), m_eye, Vector3(1.3, 0.8, 1.0))
	for s in [-1.0, 1.0]:
		_ram_horn(vis, Vector3(s * 0.17, 2.12, -0.05), s, 0.8, bone)
	arm_l = _arm(-1.0, Vector3(-0.32, 1.85, 0), 0.6)
	arm_r = _arm(1.0, Vector3(0.32, 1.85, 0), 0.6)
	_part(vis, _sph(0.17), Vector3(0, 1.55, -0.5), m_eye)
	_flame(vis, Vector3(0, 1.6, -0.5), 14, 0.25)
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.5, 0.15)
	l.light_energy = 0.8
	l.omni_range = 3.0
	l.position = Vector3(0, 1.6, -0.5)
	vis.add_child(l)


func _build_ram() -> void:
	# HIRÇIN KOÇ: küllü yünlü, kıvrık boynuzlu koç
	var wool := _m(Color(0.22, 0.18, 0.16), 0.95)
	wool.emission_enabled = true
	wool.emission = Color(0.5, 0.12, 0.03)
	wool.emission_energy_multiplier = 0.25
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for i in 11:
		var p := Vector3(rng.randf_range(-0.28, 0.28), rng.randf_range(0.65, 0.95), rng.randf_range(-0.45, 0.5))
		_part(vis, _sph(rng.randf_range(0.22, 0.3)), p, wool)
	_part(vis, _sph(0.4, 0.6), Vector3(0, 0.78, 0), m_body, Vector3(0.85, 0.75, 1.45))
	for i in 4:
		var x := -0.22 if i % 2 == 0 else 0.22
		var z := -0.35 if i < 2 else 0.4
		_part(vis, _cone(0.05, 0.07, 0.6, 6), Vector3(x, 0.3, z), m_body)
		_part(vis, _cone(0.08, 0.07, 0.1, 6), Vector3(x, 0.04, z), m_claw)
	var head := Node3D.new()
	head.position = Vector3(0, 0.95, -0.62)
	vis.add_child(head)
	_part(head, _sph(0.2), Vector3.ZERO, m_body, Vector3(0.9, 0.95, 1.2))
	_part(head, _sph(0.13), Vector3(0, -0.08, -0.2), m_body, Vector3(0.9, 0.8, 1.1))
	var eye := _sph(0.035)
	_part(head, eye, Vector3(-0.12, 0.05, -0.13), m_eye, Vector3(1.3, 0.7, 1.0))
	_part(head, eye, Vector3(0.12, 0.05, -0.13), m_eye, Vector3(1.3, 0.7, 1.0))
	var horn := _bone()
	for s in [-1.0, 1.0]:
		_ram_horn(head, Vector3(s * 0.14, 0.1, 0.02), s, 1.25, horn)
	arm_l = Node3D.new()
	arm_r = Node3D.new()
	vis.add_child(arm_l)
	vis.add_child(arm_r)


func _build_champion() -> void:
	# MARS SAVAŞÇISI: tunç zırhlı, koç başlı dev; solda kalkan, sağda balta
	var bronze := _bronze()
	_part(vis, _cone(0.22, 0.4, 0.9, 12), Vector3(0, 0.6, 0), m_cloth)
	_part(vis, _sph(0.55, 0.9), Vector3(0, 1.4, 0), m_body, Vector3(1.3, 1.0, 0.95))
	_part(vis, _sph(0.42, 0.6), Vector3(0, 1.5, -0.22), bronze, Vector3(1.35, 1.0, 0.6))
	for s in [-1.0, 1.0]:
		_part(vis, _sph(0.22), Vector3(s * 0.62, 1.78, 0), bronze, Vector3(1.2, 0.7, 1.1))
	var hp := Vector3(0, 2.0, -0.12)
	_part(vis, _sph(0.24), hp, m_body, Vector3(0.9, 1.0, 1.15))
	_part(vis, _sph(0.15), hp + Vector3(0, -0.08, -0.22), m_body, Vector3(0.85, 0.8, 1.1))
	var eye := _sph(0.04)
	_part(vis, eye, hp + Vector3(-0.1, 0.05, -0.2), m_eye, Vector3(1.3, 0.7, 1.0))
	_part(vis, eye, hp + Vector3(0.1, 0.05, -0.2), m_eye, Vector3(1.3, 0.7, 1.0))
	var horn := _bone()
	for s in [-1.0, 1.0]:
		_ram_horn(vis, hp + Vector3(s * 0.18, 0.12, 0.05), s, 1.5, horn)
	arm_l = _arm(-1.0, Vector3(-0.72, 1.65, 0), 0.9)
	arm_r = _arm(1.0, Vector3(0.72, 1.65, 0), 0.9)
	shield_node = Node3D.new()
	shield_node.position = Vector3(-0.1, -0.7, -0.3)
	arm_l.add_child(shield_node)
	var disk := CylinderMesh.new()
	disk.top_radius = 0.62
	disk.bottom_radius = 0.62
	disk.height = 0.08
	disk.radial_segments = 20
	var dm := _part(shield_node, disk, Vector3.ZERO, bronze)
	dm.rotation.x = PI * 0.5
	var rim := TorusMesh.new()
	rim.inner_radius = 0.56
	rim.outer_radius = 0.64
	var rm := _part(shield_node, rim, Vector3(0, 0, -0.02), m_claw)
	rm.rotation.x = PI * 0.5
	for s in [-1.0, 1.0]:
		var t := TorusMesh.new()
		t.inner_radius = 0.1
		t.outer_radius = 0.14
		var g := _part(shield_node, t, Vector3(s * 0.12, 0.08, -0.06), m_eye)
		g.rotation.x = PI * 0.5
	var axe := Node3D.new()
	axe.position = Vector3(0, -0.95, 0)
	arm_r.add_child(axe)
	var handle := _part(axe, _cone(0.04, 0.04, 1.5, 6), Vector3(0, 0, -0.3), _m(Color(0.2, 0.12, 0.08)))
	handle.rotation.x = PI * 0.5
	var blade := BoxMesh.new()
	blade.size = Vector3(0.06, 0.6, 0.45)
	_part(axe, blade, Vector3(0, 0.05, -0.95), bronze)
	_part(axe, _sph(0.12), Vector3(0, 0.05, -0.95), m_claw, Vector3(0.6, 2.4, 1.6))


# ---- Boğa Otlakları görünüşleri

func _stone() -> StandardMaterial3D:
	return _m(Color(0.42, 0.4, 0.36), 0.92)


func _moss() -> StandardMaterial3D:
	return _m(Color(0.2, 0.36, 0.12), 0.95)


func _build_thorn() -> void:
	# DİKEN ÇALISI: birbirine dolanmış sarmaşık gövde, başında kırmızı bir gül
	var vine := _m(Color(0.12, 0.22, 0.08), 0.8)
	for i in 5:
		var a := TAU * float(i) / 5.0
		var c := _part(vis, _cone(0.07, 0.03, 1.4, 6), Vector3(cos(a) * 0.12, 0.75, sin(a) * 0.12), vine)
		c.rotation = Vector3(sin(a) * 0.2, a, cos(a) * 0.2)
	_part(vis, _sph(0.3, 0.6), Vector3(0, 1.35, 0), m_cloth, Vector3(1.0, 1.0, 0.8))
	for i in 10:
		var a := TAU * float(i) / 10.0
		var y := 0.5 + float(i % 5) * 0.25
		var th := _part(vis, _cone(0.035, 0.0, 0.2, 4), Vector3(cos(a) * 0.2, y, sin(a) * 0.2), m_claw)
		th.rotation = Vector3(0, -a, PI * 0.5)
	# gül baş
	var hp := Vector3(0, 1.85, 0)
	var petal := _m(Color(0.6, 0.05, 0.12), 0.6)
	petal.emission_enabled = true
	petal.emission = Color(0.5, 0.02, 0.08)
	petal.emission_energy_multiplier = 0.4
	for i in 8:
		var a := TAU * float(i) / 8.0
		var r := 0.2 if i % 2 == 0 else 0.14
		_part(vis, _sph(0.15), hp + Vector3(cos(a) * r, (0.05 if i % 2 == 0 else 0.12), sin(a) * r), petal, Vector3(1.0, 0.7, 1.0))
	_part(vis, _sph(0.12), hp + Vector3(0, 0.1, 0), petal)
	var eye := _sph(0.04)
	_part(vis, eye, hp + Vector3(-0.08, 0.0, -0.2), m_eye, Vector3(1.4, 0.7, 1.0))
	_part(vis, eye, hp + Vector3(0.08, 0.0, -0.2), m_eye, Vector3(1.4, 0.7, 1.0))
	arm_l = _arm(-1.0, Vector3(-0.32, 1.5, 0), 0.85)
	arm_r = _arm(1.0, Vector3(0.32, 1.5, 0), 0.85)


func _build_priestess() -> void:
	# ÜLKER RAHİBESİ: açık turkuaz cüppe, başının üstünde dönen yedi yıldız (Ülker), elinde asa
	var robe := _m(Color(0.75, 0.88, 0.85), 0.7)
	robe.emission_enabled = true
	robe.emission = Color(0.3, 0.7, 0.6)
	robe.emission_energy_multiplier = 0.2
	_part(vis, _cone(0.5, 0.14, 1.6, 14), Vector3(0, 0.95, 0), robe)
	_part(vis, _sph(0.24, 0.48), Vector3(0, 1.8, 0), robe, Vector3(1.0, 1.0, 0.85))
	var veil := _part(vis, _cone(0.26, 0.06, 0.6, 10), Vector3(0, 2.2, 0.04), m_cloth)
	veil.rotation.x = 0.15
	_part(vis, _sph(0.15), Vector3(0, 2.08, -0.08), _m(Color(0.05, 0.08, 0.1)))
	var eye := _sph(0.03)
	_part(vis, eye, Vector3(-0.06, 2.1, -0.21), m_eye, Vector3(1.3, 0.8, 1.0))
	_part(vis, eye, Vector3(0.06, 2.1, -0.21), m_eye, Vector3(1.3, 0.8, 1.0))
	_halo = Node3D.new()
	_halo.position = Vector3(0, 2.65, 0)
	vis.add_child(_halo)
	var star: StandardMaterial3D = Fx.emissive(Color(0.8, 0.95, 1.0), 6.0)
	for i in 7:
		var a := TAU * float(i) / 7.0
		_part(_halo, _sph(0.055), Vector3(cos(a) * 0.32, sin(float(i) * 1.7) * 0.06, sin(a) * 0.32), star)
	arm_l = _arm(-1.0, Vector3(-0.3, 1.9, 0), 0.6)
	arm_r = _arm(1.0, Vector3(0.3, 1.9, 0), 0.6)
	var staff := _part(arm_r, _cone(0.03, 0.03, 2.0, 6), Vector3(0.05, -0.4, 0), _m(Color(0.55, 0.42, 0.25)))
	staff.rotation.x = 0.1
	_part(arm_r, _sph(0.13), Vector3(0.05, 0.62, 0.0), m_eye)


func _build_burrower() -> void:
	# TOPRAK KÖSTEBEĞİ: alçak, geniş, sırtı taş plakalı, kocaman kazıcı pençeli
	var fur := _m(Color(0.3, 0.2, 0.12), 0.95)
	_part(vis, _sph(0.48, 0.7), Vector3(0, 0.6, 0.05), fur, Vector3(1.0, 0.75, 1.4))
	var stone := _stone()
	for i in 4:
		var plate := BoxMesh.new()
		plate.size = Vector3(0.75, 0.1, 0.32)
		var pm := _part(vis, plate, Vector3(0, 0.95 - absf(float(i) - 1.5) * 0.05, -0.35 + float(i) * 0.28), stone)
		pm.rotation.x = -0.2 + float(i) * 0.12
	_part(vis, _sph(0.22), Vector3(0, 0.58, -0.62), fur, Vector3(0.9, 0.8, 1.2))
	_part(vis, _sph(0.07), Vector3(0, 0.55, -0.85), _m(Color(0.7, 0.4, 0.4)))
	var eye := _sph(0.03)
	_part(vis, eye, Vector3(-0.1, 0.68, -0.75), m_eye)
	_part(vis, eye, Vector3(0.1, 0.68, -0.75), m_eye)
	for s in [-1.0, 1.0]:
		for k in 3:
			var cl := _part(vis, _cone(0.04, 0.0, 0.3, 4), Vector3(s * (0.32 + float(k) * 0.05), 0.15, -0.55 - float(k) * 0.03), m_claw)
			cl.rotation.x = -1.1
		_part(vis, _cone(0.06, 0.08, 0.35, 6), Vector3(s * 0.3, 0.2, 0.35), fur)
	arm_l = Node3D.new()
	arm_r = Node3D.new()
	vis.add_child(arm_l)
	vis.add_child(arm_r)


func _build_golem() -> void:
	# TAŞ GOLEM: üst üste yığılmış yosunlu kayalar, göğsünde yeşil kristal çekirdek, boğa boynuzları
	var stone := _stone()
	var moss := _moss()
	_part(vis, _sph(0.4), Vector3(-0.25, 0.45, 0), stone, Vector3(0.8, 1.1, 0.8))
	_part(vis, _sph(0.4), Vector3(0.25, 0.45, 0), stone, Vector3(0.8, 1.1, 0.8))
	_part(vis, _sph(0.62), Vector3(0, 1.35, 0), stone, Vector3(1.35, 1.0, 1.0))
	_part(vis, _sph(0.4), Vector3(0.15, 1.75, 0.2), moss, Vector3(1.6, 0.35, 1.2))
	_part(vis, _sph(0.2), Vector3(0, 1.4, -0.55), m_eye, Vector3(1.0, 1.3, 0.5))
	var hp := Vector3(0, 2.05, -0.15)
	_part(vis, _sph(0.3), hp, stone, Vector3(1.1, 0.85, 1.0))
	var eye := _sph(0.045)
	_part(vis, eye, hp + Vector3(-0.12, 0.02, -0.25), m_eye, Vector3(1.4, 0.7, 1.0))
	_part(vis, eye, hp + Vector3(0.12, 0.02, -0.25), m_eye, Vector3(1.4, 0.7, 1.0))
	for s in [-1.0, 1.0]:
		var h := _part(vis, _cone(0.1, 0.0, 0.55, 6), hp + Vector3(s * 0.32, 0.15, 0), _bone())
		h.rotation = Vector3(-0.3, 0, -s * 1.1)
	arm_l = _arm(-1.0, Vector3(-0.8, 1.6, 0), 0.9)
	arm_r = _arm(1.0, Vector3(0.8, 1.6, 0), 0.9)
	for a in [arm_l, arm_r]:
		_part(a, _sph(0.32), Vector3(0, -1.0, 0), stone, Vector3(1.0, 0.9, 1.0))


func _build_pebble() -> void:
	# TAŞÇIK: golemin kopan parçası
	var stone := _stone()
	_part(vis, _sph(0.42), Vector3(0, 0.7, 0), stone, Vector3(1.1, 0.95, 1.0))
	_part(vis, _sph(0.25), Vector3(0.2, 1.15, 0.1), _moss(), Vector3(1.2, 0.5, 1.0))
	_part(vis, _sph(0.06), Vector3(-0.12, 0.85, -0.38), m_eye)
	_part(vis, _sph(0.06), Vector3(0.12, 0.85, -0.38), m_eye)
	arm_l = _arm(-1.0, Vector3(-0.45, 0.9, 0), 0.5)
	arm_r = _arm(1.0, Vector3(0.45, 0.9, 0), 0.5)


func _head(p: Vector3) -> void:
	_part(vis, _sph(0.24, 0.5), p + Vector3(0, 0, 0.05), m_cloth, Vector3(1.0, 1.1, 1.15))
	_part(vis, _sph(0.16), p + Vector3(0, -0.03, -0.1), _m(Color(0.01, 0.0, 0.02)))
	var eye := _sph(0.035)
	_part(vis, eye, p + Vector3(-0.07, 0.0, -0.24), m_eye, Vector3(1.4, 0.7, 1.0))
	_part(vis, eye, p + Vector3(0.07, 0.0, -0.24), m_eye, Vector3(1.4, 0.7, 1.0))
	for i in 5:
		var a := -0.9 + float(i) * 0.45
		var sp := _part(vis, _cone(0.035, 0.0, 0.22 + (0.1 if i == 2 else 0.0), 4), p + Vector3(sin(a) * 0.2, 0.22, cos(a) * 0.05 + 0.05), m_claw)
		sp.rotation.z = -a * 0.6


func _arm(side: float, at: Vector3, length: float) -> Node3D:
	var sh := Node3D.new()
	sh.position = at
	vis.add_child(sh)
	var am := _part(sh, _cone(0.035, 0.06, length, 6), Vector3(0, -length * 0.5, 0), m_body)
	am.rotation.z = side * 0.15
	for k in 3:
		var cm := _part(sh, _cone(0.025, 0.0, 0.3, 4), Vector3(side * 0.06 + (float(k) - 1.0) * 0.045, -length - 0.1, -0.04), m_claw)
		cm.rotation.x = -0.4
	sh.rotation.z = side * 0.25
	return sh


# ---------------------------------------------------------------- uyarı geometrisi

func _fan_mesh(arc: float, reach: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := 28
	for i in n:
		var a0 := -arc * 0.5 + arc * float(i) / float(n)
		var a1 := -arc * 0.5 + arc * float(i + 1) / float(n)
		st.set_color(Color(1, 1, 1, 0.12))
		st.add_vertex(Vector3.ZERO)
		st.set_color(Color(1, 1, 1, 0.95))
		st.add_vertex(Vector3(-sin(a0), 0, -cos(a0)) * reach)
		st.add_vertex(Vector3(-sin(a1), 0, -cos(a1)) * reach)
	return st.commit()


func _line_mesh(length: float, width: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var w := width * 0.5
	var pts := [Vector3(-w, 0, 0), Vector3(w, 0, 0), Vector3(w, 0, -length), Vector3(-w, 0, -length)]
	var cols := [Color(1, 1, 1, 0.9), Color(1, 1, 1, 0.9), Color(1, 1, 1, 0.1), Color(1, 1, 1, 0.1)]
	for idx in [0, 1, 2, 0, 2, 3]:
		st.set_color(cols[idx])
		st.add_vertex(pts[idx])
	return st.commit()


func _show_tele() -> void:
	var col: Color = PARRY_COL if bool(atk["parry"]) else DANGER_COL
	tele_mat.albedo_color = Color(col.r, col.g, col.b, 0.0)
	match String(atk["shape"]):
		"fan":
			tele.mesh = _fan_mesh(deg_to_rad(float(atk["arc"])), float(atk["reach"]))
		"line":
			tele.mesh = _line_mesh(float(atk["reach"]), 1.4)
		_:
			tele.mesh = _fan_mesh(TAU, float(atk["reach"]))
	tele.visible = true
	_place_tele()


func _place_tele() -> void:
	var b := Basis.looking_at(_aim_dir, Vector3.UP) if _aim_dir.length() > 0.1 else Basis.IDENTITY
	var p := global_position
	if String(atk["name"]) == "pounce" or String(atk["name"]) == "fireball" or String(atk["name"]) == "burrow":
		p = _aim_point
		b = Basis.IDENTITY
	tele.global_transform = Transform3D(b, Vector3(p.x, 0.06, p.z))


# ---------------------------------------------------------------- yapay zekâ

func _physics_process(delta: float) -> void:
	_t += delta
	_st += delta
	_global_cd -= delta
	for k in _cd:
		_cd[k] = float(_cd[k]) - delta
	_flash = maxf(_flash - delta * 6.0, 0.0)
	if dead:
		return
	_tick_burn(delta)
	if dead:
		return
	if zone == "taurus" and kind == "caster" and not pebble:
		_tick_ward_caster(delta)
	if ward > 0.0:
		_ward_t -= delta
		if _ward_t <= 0.0:
			ward = 0.0
			_ward_node.visible = false
	var to := Vector3.ZERO
	var dist := 99.0
	var hero_ok: bool = hero != null and is_instance_valid(hero) and not hero.dead
	if hero_ok:
		to = hero.global_position - global_position
		to.y = 0.0
		dist = to.length()
	var dir_to := to.normalized() if dist > 0.05 else _face

	var want := Vector3.ZERO
	match state:
		"spawn":
			if _st > 0.7:
				_set_state("chase")
		"chase":
			if hero_ok:
				_face = _face.slerp(dir_to, minf(8.0 * delta, 1.0)).normalized()
				want = _chase_move(dir_to, dist)
				if _global_cd <= 0.0:
					_pick_attack(dist, dir_to)
		"windup":
			var track := 0.6 if bool(atk["parry"]) else 0.9
			if String(atk["shape"]) == "line":
				track = 0.85
			if hero_ok and _st < float(atk["windup"]) * track:
				_aim_dir = _aim_dir.slerp(dir_to, minf(7.0 * delta, 1.0)).normalized()
				_aim_point = hero.global_position
			_face = _aim_dir
			_place_tele()
			var k := _st / float(atk["windup"])
			var pulse := 0.0 if bool(atk["parry"]) else 0.25 * (0.5 + 0.5 * sin(_t * 28.0))
			tele_mat.albedo_color.a = 0.15 + 0.55 * k + pulse
			if _st >= float(atk["windup"]):
				_set_state("act")
		"act":
			want = _do_act(delta)
			if _st >= float(atk["act"]):
				if not _done:
					_resolve()
				_set_state("recover")
		"recover":
			if _st >= float(atk["recover"]):
				_set_state("chase")
		"stun":
			if _st >= _stun_len:
				_set_state("chase")

	# diğerlerinden uzak dur
	for o in get_tree().get_nodes_in_group("enemies"):
		if o == self or o.dead:
			continue
		var d: Vector3 = global_position - o.global_position
		d.y = 0.0
		var l := d.length()
		var min_d := radius + float(o.radius) + 0.3
		if l < min_d and l > 0.01:
			want += d / l * (min_d - l) * 6.0

	_knock = _knock.move_toward(Vector3.ZERO, 30.0 * delta)
	if state == "act" and String(atk.get("name", "")) == "ramcharge":
		_move = want
		velocity = _move + _knock
		move_and_slide()
	elif state != "act" or String(atk.get("name", "")) != "pounce":
		_move = _move.move_toward(want, 25.0 * delta)
		velocity = _move + _knock
		move_and_slide()
	var flat := Vector2(global_position.x, global_position.z)
	if flat.length() > _bounds:
		flat = flat.normalized() * _bounds
		global_position = Vector3(flat.x, global_position.y, flat.y)
	if state != "act" or String(atk.get("name", "")) != "pounce":
		global_position.y = 0.0
	_animate(delta)


func _chase_move(dir_to: Vector3, dist: float) -> Vector3:
	match kind:
		"caster":
			# 6-9 m arada kal, yana kay
			var side := Vector3(-dir_to.z, 0, dir_to.x) * _strafe
			if dist < 5.5:
				return (-dir_to * 0.9 + side * 0.4).normalized() * speed
			if dist > 9.5:
				return dir_to * speed
			if randf() < 0.005:
				_strafe = -_strafe
			return side * speed * 0.6
		"leaper":
			if dist > 2.0 and dist < 3.0:
				return Vector3(-dir_to.z, 0, dir_to.x) * _strafe * speed * 0.7
	if dist > 1.6:
		return dir_to * speed
	return Vector3.ZERO


func _pick_attack(dist: float, dir_to: Vector3) -> void:
	var total := 0.0
	var cands: Array = []
	for a in attacks:
		if float(_cd[a["name"]]) <= 0.0 and dist >= float(a["min"]) and dist <= float(a["max"]):
			cands.append(a)
			total += float(a["weight"])
	if cands.is_empty():
		return
	var r := randf() * total
	for a in cands:
		r -= float(a["weight"])
		if r <= 0.0:
			atk = a
			break
	if atk.is_empty():
		atk = cands[0]
	_aim_dir = dir_to
	_aim_point = hero.global_position
	_set_state("windup")


func _set_state(s: String) -> void:
	state = s
	_st = 0.0
	if s == "windup":
		_show_tele()
		if String(atk["name"]) == "burrow":
			tele.visible = false
		if kind == "brute":
			Sfx.play("bruteroar", -6.0, 0.08, 0)
		else:
			Sfx.play("enemyattack", -10.0 if bool(atk["parry"]) else -6.0, 0.1, 60, _voice_pitch())
	elif s == "act":
		_done = false
		_leap_from = global_position
		tele.visible = String(atk["name"]) == "pounce"
		Sfx.play("dash", -10.0, 0.1, 0, 0.8)
		_charge_traveled = 0.0
		_charge_hit = false
		if String(atk["name"]) == "bolt":
			_fire_bolts()
			_done = true
		elif String(atk["name"]) == "fireball":
			_throw_fireball()
			_done = true
		elif String(atk["name"]) == "fissure":
			_spawn_fissure()
			_done = true
		elif String(atk["name"]) == "burrow":
			_burrow_locked = false
			tele.visible = false
		elif String(atk["name"]) == "ramcharge":
			Sfx.play("bruteroar", -10.0, 0.1, 0, 1.3)
	elif s == "recover":
		tele.visible = false
		_cd[atk["name"]] = float(atk["cd"])
		_global_cd = randf_range(0.2, 0.6)
	elif s == "chase" or s == "stun":
		tele.visible = false


## Saldırı anı: hareketi döndürür
func _do_act(_delta: float) -> Vector3:
	match String(atk["name"]):
		"pounce":
			var k := clampf(_st / float(atk["act"]), 0.0, 1.0)
			var p := _leap_from.lerp(Vector3(_aim_point.x, 0, _aim_point.z), k)
			p.y = sin(k * PI) * 2.6
			global_position = p
			if k >= 1.0 and not _done:
				_resolve()
			return Vector3.ZERO
		"claw", "rend", "smash":
			if not _done and _st >= float(atk["act"]) * 0.4:
				_resolve()
			return _aim_dir * 8.0 * (1.0 - _st / float(atk["act"]))
		"quake":
			if not _done and _st >= float(atk["act"]) * 0.5:
				_resolve()
		"ramcharge":
			return _ram_charge(_delta)
		"burrow":
			return _burrow(_delta)
	return Vector3.ZERO


func _burrowed() -> bool:
	return state == "act" and String(atk.get("name", "")) == "burrow" and _sink > 0.8


## TOPRAK KÖSTEBEĞİ: gömül -> altından ilerle -> yerde halka -> fırla
func _burrow(delta: float) -> Vector3:
	var st := _st
	if st < 0.4:
		_sink = lerpf(0.0, 1.7, st / 0.4)
		_dirt(global_position, 3)
		return Vector3.ZERO
	if st < 1.6:
		_sink = 1.7
		_dig_fx -= delta
		if _dig_fx <= 0.0:
			_dig_fx = 0.1
			_dirt(global_position, 2)
		if hero != null and is_instance_valid(hero) and not hero.dead:
			var d: Vector3 = hero.global_position - global_position
			d.y = 0.0
			if d.length() > 0.4:
				return d.normalized() * 7.5
		return Vector3.ZERO
	if st < 2.2:
		if not _burrow_locked:
			_burrow_locked = true
			_aim_point = global_position
			tele.mesh = _fan_mesh(TAU, float(atk["reach"]))
			tele.visible = true
			_place_tele()
		var k := (st - 1.6) / 0.6
		tele_mat.albedo_color = Color(DANGER_COL.r, DANGER_COL.g, DANGER_COL.b, 0.2 + 0.6 * k + 0.2 * sin(_t * 30.0))
		if fmod(st, 0.15) < delta:
			_dirt(global_position, 2)
		return Vector3.ZERO
	if not _done:
		_done = true
		_sink = 0.0
		tele.visible = false
		_dirt(global_position, 14)
		var ring := SlashFx.make(0.0, TAU, 0.3, float(atk["reach"]), Color(0.75, 0.55, 0.3), 0.3)
		get_parent().add_child(ring)
		ring.global_transform = Transform3D(Basis.IDENTITY, global_position + Vector3(0, 0.3, 0))
		Fx.shake(0.3)
		Sfx.play("crush", -6.0, 0.1, 0, 0.9)
		if hero != null and is_instance_valid(hero) and not hero.dead:
			var v: Vector3 = hero.global_position - global_position
			v.y = 0.0
			if v.length() <= float(atk["reach"]) + 0.3:
				hero.take_damage(float(atk["dmg"]), v.normalized() if v.length() > 0.05 else _aim_dir, false)
	return Vector3.ZERO


func _dirt(p: Vector3, n: int) -> void:
	var m: StandardMaterial3D = Fx.mat(Color(0.35, 0.25, 0.15), 0.0, 0.95)
	var b := BoxMesh.new()
	b.size = Vector3(0.1, 0.08, 0.1)
	Fx._burst(Vector3(p.x, 0.1, p.z), Vector3.UP, n, m, b, 2.0, 4.5, 50.0, -14.0, 0.6, 0.6, 1.2, true)


## TAŞ GOLEM: ileri doğru sırayla fışkıran kaya sivrileri
func _spawn_fissure() -> void:
	var fs := Fissure.new()
	fs.start = Vector3(global_position.x, 0.0, global_position.z) + _aim_dir * 0.8
	fs.dir = _aim_dir
	fs.length = float(atk["reach"])
	fs.dmg = float(atk["dmg"])
	fs.hero = hero
	fs.bounds = _bounds + 0.5
	get_parent().add_child(fs)
	Fx.shake(0.35)
	Sfx.play("crush", -4.0, 0.1, 0, 0.7)


## ÜLKER RAHİBESİ: yakındaki bir dostuna koruma kalkanı verir
func _tick_ward_caster(delta: float) -> void:
	_ward_cd -= delta
	if _ward_cd > 0.0 or state == "stun" or state == "spawn":
		return
	var best = null
	var bd := 11.0
	for o in get_tree().get_nodes_in_group("enemies"):
		if o == self or o.dead or o.get("ward") == null or float(o.ward) > 0.0:
			continue
		var d: float = o.global_position.distance_to(global_position)
		if o.kind == "brute":
			d -= 3.0
		if d < bd:
			bd = d
			best = o
	if best == null:
		_ward_cd = 1.0
		return
	_ward_cd = 6.5
	best.give_ward(minf(60.0, float(best.max_hp) * 0.5))
	Fx.flash_light(global_position + Vector3(0, 2.2, 0), Color(0.6, 1.0, 0.8), 4.0, 4.0, 0.3)
	Sfx.play("parry", -12.0, 0.05, 0, 1.9)


func give_ward(amount: float) -> void:
	ward = amount
	_ward_t = 9.0
	if _ward_node == null:
		_ward_node = MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.95
		sm.height = 1.9
		_ward_node.mesh = sm
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		m.albedo_color = Color(0.45, 1.0, 0.75, 0.22)
		_ward_node.material_override = m
		_ward_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(_ward_node)
	_ward_node.position.y = 1.1 * size_k
	_ward_node.scale = Vector3.ONE * size_k * 1.2
	_ward_node.visible = true


## HIRÇIN KOÇ tosu: düz hatta hızla koşar; ıskalarsa boynuzları yere saplanır, sersemler (vurma fırsatı)
func _ram_charge(delta: float) -> Vector3:
	if _done:
		return Vector3.ZERO
	var spd := 15.0
	_charge_traveled += spd * delta
	if not _charge_hit and hero != null and is_instance_valid(hero) and not hero.dead:
		var d: Vector3 = hero.global_position - global_position
		d.y = 0.0
		if d.length() < radius + 0.75:
			var res: String = hero.take_damage(float(atk["dmg"]), _aim_dir, false)
			if res == "hit":
				_charge_hit = true
				Fx.shake(0.3)
	if _charge_traveled >= float(atk["reach"]) or _st >= float(atk["act"]) - 0.02:
		_done = true
		_move = Vector3.ZERO
		if not _charge_hit:
			Sfx.play("crush", -8.0, 0.1, 0, 0.8)
			Fx.shake(0.2)
			stun(1.1)
		return Vector3.ZERO
	return _aim_dir * spd


## MARS KÂHİNİ: hedef noktaya kavisli ateş topu (seçkinse 3 tane)
func _throw_fireball() -> void:
	var targets: Array = [_aim_point]
	if elite:
		for i in 2:
			targets.append(_aim_point + Vector3(randf_range(-2.5, 2.5), 0, randf_range(-2.5, 2.5)))
	for tp in targets:
		var fb := Fireball.new()
		fb.from = global_position + Vector3(0, 1.6, 0) + _aim_dir * 0.5
		var t: Vector3 = tp
		var fl := Vector2(t.x, t.z)
		if fl.length() > _bounds:
			fl = fl.normalized() * _bounds
		fb.to = Vector3(fl.x, 0.0, fl.y)
		fb.dmg = float(atk["dmg"])
		fb.radius = float(atk["reach"])
		fb.pool_dmg = 5.0 * dmg_mult
		fb.hero = hero
		get_parent().add_child(fb)


## Vuruşun kahramana değip değmediğini hesaplar
func _resolve() -> void:
	_done = true
	var nm := String(atk["name"])
	if nm == "ramcharge" or nm == "fireball" or nm == "burrow" or nm == "fissure":
		return
	var reach := float(atk["reach"])
	var col: Color = PARRY_COL if bool(atk["parry"]) else DANGER_COL
	var center := global_position
	if nm == "pounce":
		center = Vector3(_aim_point.x, 0, _aim_point.z)
		global_position = center
		tele.visible = false
	# görsel
	if String(atk["shape"]) == "fan":
		var fx := SlashFx.make(-deg_to_rad(float(atk["arc"])) * 0.5, deg_to_rad(float(atk["arc"])) * 0.5, 0.4, reach, col, 0.2)
		get_parent().add_child(fx)
		fx.global_transform = Transform3D(Basis.looking_at(_aim_dir, Vector3.UP), global_position + Vector3(0, 1.0, 0))
	else:
		var ring := SlashFx.make(0.0, TAU, reach * 0.3, reach, col, 0.3)
		get_parent().add_child(ring)
		ring.global_transform = Transform3D(Basis.IDENTITY, center + Vector3(0, 0.3, 0))
		Fx.shake(0.35 if nm == "quake" else 0.25)
		Fx.flash_light(center + Vector3(0, 1, 0), col, 4.0, reach * 2.0, 0.25)
		Sfx.play("boom", -14.0, 0.1, 0, 1.4 if nm == "quake" else 2.0)
	if hero == null or not is_instance_valid(hero) or hero.dead:
		return
	var to: Vector3 = hero.global_position - center
	to.y = 0.0
	var dist := to.length()
	if dist > reach + 0.3:
		return
	if String(atk["shape"]) == "fan" and dist > 0.3 and _aim_dir.angle_to(to / dist) > deg_to_rad(float(atk["arc"])) * 0.5:
		return
	var dir := to.normalized() if dist > 0.05 else _aim_dir
	var res: String = hero.take_damage(float(atk["dmg"]), dir, bool(atk["parry"]))
	if res == "parried":
		stun(2.0 if kind == "brute" else 1.5, true)
		_knock = -_aim_dir * 7.0


func _fire_bolts() -> void:
	var base := _aim_dir
	for i in 3:
		var ang := deg_to_rad(float(atk["arc"])) * (float(i) - 1.0) * 0.5
		var d := base.rotated(Vector3.UP, ang)
		var b := Bolt.new()
		b.col = bolt_col
		if zone == "taurus":
			b.speed = 8.5
		b.dir = d
		b.dmg = float(atk["dmg"])
		b.hero = hero
		b.position = global_position + Vector3(0, 1.6, 0) + d * 0.6
		get_parent().add_child(b)


func stun(sec: float, parried := false) -> void:
	_stun_len = sec
	_parried = parried
	if state == "act" and String(atk.get("name", "")) == "pounce":
		global_position.y = 0.0
	_set_state("stun")


## Her tipin kendi ses rengi
func _voice_pitch() -> float:
	match kind:
		"brute":
			return 0.7
		"caster":
			return 1.25
		"leaper":
			return 1.1
	return 0.95 if not elite else 0.82


## Mars lütfu: yanma (saniyede hasar, süre yenilenir)
func apply_burn(dps: float, dur: float) -> void:
	_burn_dps = maxf(_burn_dps, dps)
	_burn_t = maxf(_burn_t, dur)


func _tick_burn(delta: float) -> void:
	if _burn_t <= 0.0:
		return
	_burn_t -= delta
	_burn_acc += _burn_dps * delta
	if _burn_acc >= 2.0:
		var d := _burn_acc
		_burn_acc = 0.0
		hp -= d
		_flash = maxf(_flash, 0.35)
		var m: StandardMaterial3D = Fx.emissive(Color(1.0, 0.45, 0.15), 6.0)
		var s := SphereMesh.new()
		s.radius = 0.04
		s.height = 0.08
		Fx._burst(global_position + Vector3(0, 1.2 * size_k, 0), Vector3.UP, 4, m, s, 1.0, 2.5, 30.0, 2.0, 0.5, 0.6, 1.2)
		if hp <= 0.0:
			_die(Vector3.UP)


## Düşmanı bir noktaya doğru çeker (Ay Gelgiti)
func pull_to(point: Vector3, strength: float) -> void:
	var d := point - global_position
	d.y = 0.0
	if d.length() > 0.3:
		_knock = d.normalized() * minf(strength, d.length() * 6.0)


# ---------------------------------------------------------------- hasar

func take_hit(dmg: float, dir: Vector3, kb: float, heavy: bool, crit := false) -> void:
	last_dealt = 0.0
	if dead or state == "spawn":
		return
	if _burrowed():
		return
	var stunned_by_parry: bool = state == "stun" and _parried
	var final := dmg * (2.0 if stunned_by_parry else 1.0)
	# Ülker kalkanı önce hasarı emer
	if ward > 0.0:
		var ab := minf(ward, final)
		ward -= ab
		final -= ab
		if _ward_node != null:
			_ward_node.scale = Vector3.ONE * size_k * 1.35
			var wt := _ward_node.create_tween()
			wt.tween_property(_ward_node, "scale", Vector3.ONE * size_k * 1.2, 0.12)
		if ward <= 0.0:
			_ward_node.visible = false
			Sfx.play("parry", -8.0, 0.05, 0, 0.8)
			Fx.flash_light(global_position + Vector3(0, 1.2, 0), Color(0.5, 1.0, 0.7), 4.0, 4.0, 0.25)
		else:
			Sfx.play("parry", -14.0, 0.1, 50, 1.6)
		if final <= 0.0:
			HitFx.impact(get_parent(), global_position + Vector3(0, 1.2 * size_k, 0) - dir * 0.8, dir, Color(0.6, 1.0, 0.8), false)
			return
	# MARS SAVAŞÇISI kalkanı: önden gelen hafif vuruşları büyük ölçüde keser (yandan/arkadan, ağır vuruş ya da parry ile aşılır)
	if zone == "aries" and kind == "brute" and not heavy and state != "stun" and _face.dot(-dir) > 0.35:
		final *= 0.35
		hp -= final
		last_dealt = final
		_flash = 0.35
		HitFx.impact(get_parent(), global_position + Vector3(0, 1.5 * size_k, 0) - dir * 0.9, dir, Color(1.0, 0.8, 0.45), false)
		HitFx.number(get_parent(), global_position + Vector3(0, 2.2 * size_k, 0), final, false)
		Sfx.play("parry", -9.0, 0.1, 60, 1.5)
		if shield_node != null:
			shield_node.position.z = -0.15
			var sht := shield_node.create_tween()
			sht.tween_property(shield_node, "position:z", -0.3, 0.15)
		if hp <= 0.0:
			_die(dir)
		return
	hp -= final
	last_dealt = final
	_flash = 1.0
	# vuruş hissi: geriye esneme, ezilip toparlanma, vuruş noktasında patlama, hasar sayısı
	_flinch = 1.0 if heavy or crit else 0.6
	if vis != null:
		var base := Vector3.ONE * size_k
		vis.scale = Vector3(base.x * 1.18, base.y * 0.84, base.z * 1.18)
		var pt := vis.create_tween()
		pt.tween_property(vis, "scale", base, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var hp_pos := global_position + Vector3(0, 1.3 * size_k, 0) - dir * 0.3
	HitFx.impact(get_parent(), hp_pos, dir, Color(1.0, 0.85, 0.5) if not stunned_by_parry else Color(1.0, 0.95, 0.6), heavy or crit or stunned_by_parry)
	HitFx.number(get_parent(), global_position + Vector3(0, 2.2 * size_k, 0), final, crit or stunned_by_parry)
	if hp > 0.0:
		Sfx.play("enemyhurt", -7.0, 0.1, 110, _voice_pitch())
	if kind != "brute" or heavy:
		_knock = dir * kb * (0.4 if kind == "brute" else 1.0)
	var p := global_position + Vector3(0, 1.3 * size_k, 0)
	_stardust(p, dir, 10 if heavy else 6)
	_shards(p, dir, 5 if heavy else 3)
	if hp <= 0.0:
		_die(dir)
		return
	# ağır vuruşlar hafif düşmanların hazırlığını keser; kolos ve atlayan havadayken sendelemez
	var airborne := state == "act" and String(atk.get("name", "")) == "pounce"
	_knock *= 1.25
	# itmesiz vuruşlar (yay okları) düşmanı sendeletmez
	if kb <= 0.0:
		return
	if heavy and kind != "brute" and not airborne and state != "stun":
		stun(0.45)
	elif (state == "chase" or state == "recover") and kind != "brute":
		stun(0.15)


func _stardust(p: Vector3, dir: Vector3, n: int) -> void:
	var m: StandardMaterial3D = Fx.emissive(Color(1.0, 0.92, 0.65), 5.0)
	var s := SphereMesh.new()
	s.radius = 0.035
	s.height = 0.07
	s.radial_segments = 6
	s.rings = 3
	Fx._burst(p, (dir + Vector3(0, 0.5, 0)).normalized(), n, m, s, 2.0, 6.0, 45.0, -3.0, 0.6, 0.5, 1.4)


func _shards(p: Vector3, dir: Vector3, n: int) -> void:
	var m: StandardMaterial3D = Fx.mat(Color(0.95, 0.78, 0.35), 1.0, 0.25)
	var b := BoxMesh.new()
	b.size = Vector3(0.06, 0.02, 0.1)
	Fx._burst(p, (dir + Vector3(0, 0.8, 0)).normalized(), n, m, b, 3.0, 6.5, 40.0, -18.0, 0.8, 0.6, 1.3, true)


func _die(dir: Vector3) -> void:
	dead = true
	state = "dead"
	tele.visible = false
	hp_bar.visible = false
	remove_from_group("enemies")
	global_position.y = 0.0
	var p := global_position + Vector3(0, 1.2 * size_k, 0)
	_stardust(p, Vector3.UP, 26)
	_shards(p, dir, 10)
	Fx.flash_light(p, Color(1.0, 0.85, 0.55), 5.0, 6.0, 0.35)
	Fx.shake(0.25 if kind != "brute" else 0.6)
	Sfx.play("enemydie", -5.0, 0.08, 0, _voice_pitch())
	if zone == "taurus" and kind == "shade" and not pebble:
		var tp := ThornPatch.new()
		tp.hero = hero
		get_parent().add_child(tp)
		tp.global_position = Vector3(global_position.x, 0.0, global_position.z)
	if zone == "aries" and kind == "shade":
		var eb := EmberBurst.new()
		eb.hero = hero
		eb.dmg = 10.0 * dmg_mult
		eb.radius = 1.5 * (1.2 if elite else 1.0)
		get_parent().add_child(eb)
		eb.global_position = Vector3(global_position.x, 0.0, global_position.z)
	Sfx.play("coin", -10.0, 0.1, 0, 0.9)
	killed.emit(self)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(vis, "scale", Vector3(1.3, 0.05, 1.3) * size_k, 0.25).set_ease(Tween.EASE_IN)
	tw.tween_property(vis, "position:y", 0.6, 0.25)
	tw.chain().tween_callback(queue_free)


# ---------------------------------------------------------------- animasyon

func _animate(delta: float) -> void:
	body_root.rotation.y = lerp_angle(body_root.rotation.y, atan2(-_face.x, -_face.z), minf(14.0 * delta, 1.0))
	var hover := sin(_t * 2.2) * 0.08 + (0.35 if kind == "caster" else 0.0)
	var lean := 0.0
	var arms := 0.25
	var glow := 3.0
	var claw_glow := 0.3
	match state:
		"windup":
			var k := _st / float(atk["windup"])
			lean = 0.3 * k
			arms = 0.25 + 1.6 * k
			glow = 3.0 + 9.0 * k
			claw_glow = 0.3 + 4.0 * k
			if kind == "leaper":
				lean = -0.25 * k    # çömelir
			if String(atk["name"]) == "quake":
				arms = 2.6 * k      # kollarını havaya kaldırır
		"act":
			lean = -0.45 if kind != "leaper" else 0.3
			arms = -1.2
			glow = 10.0
			claw_glow = 5.0
		"recover":
			var r := 1.0 - _st / float(atk["recover"])
			lean = -0.2 * r
			arms = -0.6 * r
		"stun":
			lean = 0.25
			arms = 0.0
			glow = 1.0
			hover += sin(_t * 18.0) * 0.03
	_flinch = maxf(_flinch - delta * 5.0, 0.0)
	vis.rotation.x = lerpf(vis.rotation.x, lean - _flinch * 0.45, minf(20.0 * delta, 1.0))
	if state != "spawn":
		vis.position.y = hover - _sink
	if state != "act" and _sink > 0.0:
		_sink = 0.0
	hp_bar.visible = _sink < 0.5
	if _halo != null:
		_halo.rotation.y += delta * 1.4
	arm_l.rotation.x = lerpf(arm_l.rotation.x, arms, minf(16.0 * delta, 1.0))
	arm_r.rotation.x = lerpf(arm_r.rotation.x, arms, minf(16.0 * delta, 1.0))
	m_eye.emission_energy_multiplier = glow
	m_claw.emission_energy_multiplier = claw_glow
	var base_b := _base_body.lerp(Color(1.0, 0.4, 0.1), 0.6) if _burn_t > 0.0 else _base_body
	m_body.emission = base_b.lerp(Color(1.0, 0.95, 0.85), _flash)
	m_body.emission_energy_multiplier = 0.25 + _flash * 4.0
	m_cloth.emission = _base_cloth.lerp(Color(1.0, 0.95, 0.85), _flash)
	m_cloth.emission_energy_multiplier = (0.9 if elite else 0.15) + _flash * 3.0
	hp_mat.set_shader_parameter("fill", clampf(hp / max_hp, 0.0, 1.0))
	hp_mat.set_shader_parameter("stunned", 1.0 if state == "stun" else 0.0)


# ---------------------------------------------------------------- kâhin mermisi

class Bolt extends Node3D:
	var col := Color(1.0, 0.2, 0.3)
	var dir := Vector3.FORWARD
	var dmg := 12.0
	var speed := 11.5
	var hero = null
	var _dist := 0.0
	var _orb: MeshInstance3D

	func _ready() -> void:
		_orb = MeshInstance3D.new()
		var s := SphereMesh.new()
		s.radius = 0.18
		s.height = 0.36
		_orb.mesh = s
		var m := StandardMaterial3D.new()
		m.albedo_color = col
		m.emission_enabled = true
		m.emission = col
		m.emission_energy_multiplier = 5.0
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_orb.material_override = m
		add_child(_orb)
		var l := OmniLight3D.new()
		l.light_color = col
		l.light_energy = 1.2
		l.omni_range = 2.5
		add_child(l)

	func _physics_process(delta: float) -> void:
		var step := speed * delta
		global_position += dir * step
		_dist += step
		_orb.scale = Vector3.ONE * (1.0 + sin(_dist * 6.0) * 0.12)
		if hero != null and is_instance_valid(hero) and not hero.dead:
			var d: Vector3 = hero.global_position + Vector3(0, 1.0, 0) - global_position
			if Vector2(d.x, d.z).length() < 0.55 and absf(d.y) < 1.3:
				var res: String = hero.take_damage(dmg, dir, false)
				if res != "miss":
					queue_free()
					return
		if _dist > 16.0:
			queue_free()


# ---------------------------------------------------------------- Mars Kâhini ateş topu

class Fireball extends Node3D:
	var from := Vector3.ZERO
	var to := Vector3.ZERO
	var dmg := 14.0
	var radius := 1.7
	var pool_dmg := 5.0
	var hero = null
	var flight := 0.75
	var pool_time := 2.2
	var _t := 0.0
	var _landed := false
	var _tick := 0.0
	var _orb: MeshInstance3D
	var _ring: MeshInstance3D
	var _pool_mat: StandardMaterial3D

	func _ready() -> void:
		top_level = true
		_ring = load("res://scripts/star_skills.gd").ring(radius, Color(1.0, 0.15, 0.1, 0.9))
		add_child(_ring)
		_ring.global_position = to + Vector3(0, 0.06, 0)
		_orb = MeshInstance3D.new()
		var s := SphereMesh.new()
		s.radius = 0.25
		s.height = 0.5
		_orb.mesh = s
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.albedo_color = Color(1.0, 0.55, 0.15)
		_orb.material_override = m
		add_child(_orb)
		_orb.global_position = from
		var l := OmniLight3D.new()
		l.light_color = Color(1.0, 0.5, 0.15)
		l.light_energy = 1.5
		l.omni_range = 3.0
		_orb.add_child(l)

	func _physics_process(delta: float) -> void:
		_t += delta
		if not _landed:
			var k := clampf(_t / flight, 0.0, 1.0)
			var p := from.lerp(to, k)
			p.y = lerpf(from.y, 0.3, k) + sin(k * PI) * 3.2
			_orb.global_position = p
			_ring.scale = Vector3(0.4 + 0.6 * k, 0.1, 0.4 + 0.6 * k)
			if k >= 1.0:
				_land()
			return
		_tick -= delta
		var life := _t - flight
		_pool_mat.albedo_color.a = 0.55 * (1.0 - clampf((life - pool_time + 0.4) / 0.4, 0.0, 1.0))
		if _tick <= 0.0:
			_tick = 0.5
			_hurt(radius * 0.8, pool_dmg)
		if life >= pool_time:
			queue_free()

	func _land() -> void:
		_landed = true
		_orb.visible = false
		_ring.visible = false
		_tick = 0.5
		var ex = load("res://scripts/slash_fx.gd").make(0.0, TAU, 0.2, radius, Color(1.0, 0.45, 0.12), 0.35)
		get_parent().add_child(ex)
		ex.global_transform = Transform3D(Basis.IDENTITY, to + Vector3(0, 0.4, 0))
		Fx.flash_light(to + Vector3(0, 1, 0), Color(1.0, 0.45, 0.15), 5.0, 5.0, 0.25)
		Sfx.play("boom", -13.0, 0.15, 30, 1.5)
		_hurt(radius, dmg)
		# yerde yanan alev birikintisi
		var pool := MeshInstance3D.new()
		var c := CylinderMesh.new()
		c.top_radius = radius * 0.8
		c.bottom_radius = radius * 0.8
		c.height = 0.02
		pool.mesh = c
		_pool_mat = StandardMaterial3D.new()
		_pool_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_pool_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_pool_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		_pool_mat.albedo_color = Color(1.0, 0.35, 0.08, 0.55)
		pool.material_override = _pool_mat
		add_child(pool)
		pool.global_position = to + Vector3(0, 0.05, 0)
		var fire := CPUParticles3D.new()
		fire.amount = 18
		fire.lifetime = 0.6
		fire.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
		fire.emission_sphere_radius = radius * 0.7
		fire.direction = Vector3.UP
		fire.gravity = Vector3(0, 2.5, 0)
		fire.initial_velocity_min = 0.5
		fire.initial_velocity_max = 1.2
		var sm := SphereMesh.new()
		sm.radius = 0.08
		sm.height = 0.16
		fire.mesh = sm
		var fm := StandardMaterial3D.new()
		fm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		fm.albedo_color = Color(1.0, 0.5, 0.12)
		fire.material_override = fm
		add_child(fire)
		fire.global_position = to + Vector3(0, 0.1, 0)

	func _hurt(r: float, d: float) -> void:
		if hero == null or not is_instance_valid(hero) or hero.dead:
			return
		var v: Vector3 = hero.global_position - to
		v.y = 0.0
		if v.length() <= r + 0.25:
			hero.take_damage(d, v.normalized() if v.length() > 0.05 else Vector3.FORWARD, false)


# ---------------------------------------------------------------- Kor Cini ölüm koru

class EmberBurst extends Node3D:
	var hero = null
	var dmg := 10.0
	var radius := 1.5
	var fuse := 0.9
	var _t := 0.0
	var _ring: MeshInstance3D
	var _core: MeshInstance3D

	func _ready() -> void:
		_ring = load("res://scripts/star_skills.gd").ring(radius, Color(1.0, 0.25, 0.08, 0.9))
		add_child(_ring)
		_ring.position.y = 0.06
		_core = MeshInstance3D.new()
		var s := SphereMesh.new()
		s.radius = 0.18
		s.height = 0.36
		_core.mesh = s
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.albedo_color = Color(1.0, 0.6, 0.2)
		_core.material_override = m
		_core.position.y = 0.3
		add_child(_core)

	func _physics_process(delta: float) -> void:
		_t += delta
		var k := clampf(_t / fuse, 0.0, 1.0)
		_core.scale = Vector3.ONE * (1.0 + k * 1.5 + sin(_t * 30.0) * 0.2 * k)
		_ring.scale = Vector3(0.3 + 0.7 * k, 0.1, 0.3 + 0.7 * k)
		if _t >= fuse:
			var ex = load("res://scripts/slash_fx.gd").make(0.0, TAU, 0.2, radius, Color(1.0, 0.45, 0.12), 0.3)
			get_parent().add_child(ex)
			ex.global_transform = Transform3D(Basis.IDENTITY, global_position + Vector3(0, 0.4, 0))
			Fx.flash_light(global_position + Vector3(0, 1, 0), Color(1.0, 0.45, 0.15), 4.0, 4.0, 0.2)
			Sfx.play("boom", -15.0, 0.2, 30, 1.8)
			if hero != null and is_instance_valid(hero) and not hero.dead:
				var v: Vector3 = hero.global_position - global_position
				v.y = 0.0
				if v.length() <= radius + 0.25:
					hero.take_damage(dmg, v.normalized() if v.length() > 0.05 else Vector3.FORWARD, false)
			queue_free()



# ---------------------------------------------------------------- Diken Çalısı ölüm alanı (yavaşlatır)

class ThornPatch extends Node3D:
	var hero = null
	var radius := 1.7
	var life := 3.5
	var _t := 0.0
	var _mat: StandardMaterial3D

	func _ready() -> void:
		var disk := MeshInstance3D.new()
		var c := CylinderMesh.new()
		c.top_radius = radius
		c.bottom_radius = radius
		c.height = 0.02
		disk.mesh = c
		_mat = StandardMaterial3D.new()
		_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_mat.albedo_color = Color(0.15, 0.35, 0.08, 0.6)
		disk.material_override = _mat
		disk.position.y = 0.04
		add_child(disk)
		var thorn := StandardMaterial3D.new()
		thorn.albedo_color = Color(0.2, 0.3, 0.1)
		for i in 14:
			var a := randf() * TAU
			var r := sqrt(randf()) * radius * 0.9
			var cm := CylinderMesh.new()
			cm.top_radius = 0.0
			cm.bottom_radius = 0.06
			cm.height = randf_range(0.25, 0.5)
			cm.radial_segments = 4
			var mi := MeshInstance3D.new()
			mi.mesh = cm
			mi.material_override = thorn
			mi.position = Vector3(cos(a) * r, cm.height * 0.5, sin(a) * r)
			mi.rotation = Vector3(randf_range(-0.4, 0.4), 0, randf_range(-0.4, 0.4))
			add_child(mi)
		var ring = load("res://scripts/star_skills.gd").ring(radius, Color(0.5, 0.9, 0.3, 0.8))
		ring.position.y = 0.06
		add_child(ring)
		scale = Vector3(0.2, 0.2, 0.2)
		var tw := create_tween()
		tw.tween_property(self, "scale", Vector3.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	func _physics_process(delta: float) -> void:
		_t += delta
		if hero != null and is_instance_valid(hero) and not hero.dead and hero.has_method("apply_slow"):
			var v: Vector3 = hero.global_position - global_position
			v.y = 0.0
			if v.length() <= radius:
				hero.apply_slow(0.5, 0.25)
		if _t > life - 0.4:
			scale = Vector3.ONE * maxf((life - _t) / 0.4, 0.01)
		if _t >= life:
			queue_free()


# ---------------------------------------------------------------- Taş Golem yarığı

class Fissure extends Node3D:
	var start := Vector3.ZERO
	var dir := Vector3.FORWARD
	var length := 9.0
	var dmg := 24.0
	var hero = null
	var bounds := 11.0
	var _t := 0.0
	var _next := 0
	var _hit := false
	var _spikes: Array = []
	var _mat: StandardMaterial3D

	func _ready() -> void:
		top_level = true
		_mat = StandardMaterial3D.new()
		_mat.albedo_color = Color(0.45, 0.42, 0.36)
		_mat.roughness = 0.95

	func _physics_process(delta: float) -> void:
		_t += delta
		var n := int(length / 0.9)
		while _next < n and _t >= float(_next) * 0.05:
			var p := start + dir * (float(_next) * 0.9)
			if Vector2(p.x, p.z).length() <= bounds:
				_spike(p)
				if not _hit and hero != null and is_instance_valid(hero) and not hero.dead:
					var v: Vector3 = hero.global_position - p
					v.y = 0.0
					if v.length() < 1.05:
						var res: String = hero.take_damage(dmg, (dir + Vector3.UP * 0.2).normalized(), false)
						if res == "hit":
							_hit = true
			_next += 1
		for sp in _spikes:
			var mi: MeshInstance3D = sp[0]
			var age := _t - float(sp[1])
			if age < 0.12:
				mi.scale = Vector3(1, age / 0.12, 1)
			elif age > 0.7:
				mi.scale = Vector3(1, maxf(1.0 - (age - 0.7) / 0.3, 0.01), 1)
		if _t > float(n) * 0.05 + 1.1:
			queue_free()

	func _spike(p: Vector3) -> void:
		for k in 2:
			var cm := CylinderMesh.new()
			cm.top_radius = 0.0
			cm.bottom_radius = randf_range(0.25, 0.4)
			cm.height = randf_range(0.9, 1.5)
			cm.radial_segments = 5
			var mi := MeshInstance3D.new()
			mi.mesh = cm
			mi.material_override = _mat
			add_child(mi)
			var off := Vector3(randf_range(-0.35, 0.35), 0, randf_range(-0.35, 0.35))
			mi.global_position = p + off + Vector3(0, cm.height * 0.5 - 0.1, 0)
			mi.rotation = Vector3(randf_range(-0.3, 0.3), randf() * TAU, randf_range(-0.3, 0.3))
			mi.scale = Vector3(1, 0.01, 1)
			_spikes.append([mi, _t])
		Sfx.play("crush", -16.0, 0.15, 25, 1.2)
