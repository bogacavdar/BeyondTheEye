extends CharacterBody3D
## DÜŞMANLAR: burçların bozulmasıyla karanlığa dönmüş yıldız ruhları. 4 tip:
##   shade  · GÖLGE    : yakın dövüşçü. Pençe (parry'lenir) + arada bir parry'lenemeyen yırtma.
##   caster · KÂHİN    : uzak durur, 3'lü ışık mermisi atar (parry'lenemez, atılarak kaçılır).
##   leaper · ATLAYAN  : uzaktan üstüne atlar; düşeceği yer yerde kızıl daireyle görünür (parry'lenemez).
##   brute  · KOLOS    : iri ve yavaş. Ezme darbesi (parry'lenir) + çevresine deprem dalgası (parry'lenemez).
## UYARI RENKLERİ: altın-turuncu uyarı = parry'lenebilir. KIZIL, yanıp sönen uyarı = parry'lenemez, kaç!
## Kan yok: vurulunca yıldız tozu ve altın kırıkları saçılır. Başlarının üstünde can barı var.

signal killed(enemy)

const Elements = preload("res://scripts/elements.gd")
const GameData = preload("res://scripts/game_data.gd")
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
var affixes: Array = []      # SEÇKİN ÖZELLİKLERİ (room.gd verir): shielded, swift, splitting, healer, volatile, phantom
var mini := false            # Bölünen seçkinin ölünce bıraktığı küçük kopya
var _heal_t := 1.0
var ward := 0.0             # Ülker Rahibesi'nin verdiği koruma kalkanı
var _ward_t := 0.0
var _ward_node: MeshInstance3D
var _ward_cd := 3.0
var _sink := 0.0            # Köstebek toprağa gömülme miktarı
var _burrow_locked := false
var _dig_fx := 0.0
var _halo: Node3D
var bolt_col := Color(1.0, 0.2, 0.3)
var _chain_left := 0        # seri saldırıda kalan tur
var _wscale := 1.0          # serinin sonraki turları daha kısa hazırlanır
var _claw_base := Color(1, 0.4, 0.1)
var _eye_base := Color(1, 0.4, 0.1)
var _twist := 0.0
var _sky := false           # Fırtına Kuşu: gömülmek yerine havaya yükselir
var partner = null          # İkiz Gölge: eşi
var _enraged := false
var _blink_cd := 2.0        # Merkür Habercisi ışınlanma
var _mirror_node: MeshInstance3D
var _shell_hits := 0         # Kabuk Askeri: kısa sürede alınan vuruş sayısı
var _shell_win := 0.0
var crowned := 0.0           # Güneş Rahibi'nin tacı: süre (hasar +%50)
var _crown_node: Node3D
var _crown_cd := 2.5
var _hide_crack := 0.0       # Nemea Aslanı: postu çatladı (tam hasar alır)
var _reveal := 0.0           # Serap Avcısı: görünür kalma süresi
var _calm := 0.0             # Hasır Dev: son vuruştan bu yana geçen süre (yenilenme)
var _dodge_cd := 0.0         # Tüy Dansçısı: bir sonraki kaçışa kalan süre
var _stored := 0.0           # Karşı Ağırlık Golemi: biriktirilen hasar
var _even_cd := 3.0          # Terazi Bekçisi: eşitleme bekleme süresi
var _sharing := false
var _feigned := false         # Ölü Taklitçi: taklidi bir kez yapar

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
	elif zone == "gemini":
		_gemini_variant()
	elif zone == "cancer":
		_cancer_variant()
	elif zone == "leo":
		_leo_variant()
	elif zone == "virgo":
		_virgo_variant()
	elif zone == "libra":
		_libra_variant()
	elif zone == "scorpio":
		_scorpio_variant()
	elif zone == "sagittarius":
		_sag_variant()
	if mini:
		max_hp *= 0.35
		size_k *= 0.7
		radius *= 0.7
	if affixes.has("swift"):
		speed *= 1.3
		windup_mult *= 0.85
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
	# SERİ SALDIRILAR: bazı saldırılar 2-3 tur ard arda gelir (parry seriyi keser)
	for a in attacks:
		var nm := String(a["name"])
		var ch := 1
		if nm == "claw":
			ch = 3 if (kind == "shade" and not pebble) else 2
		elif nm == "smash" or nm == "bolt" or nm == "ramcharge":
			ch = 2
		elif nm == "fireball":
			ch = 3
		a["chain"] = ch
	for a in attacks:
		a["dmg"] = float(a["dmg"]) * dmg_mult * em
		a["windup"] = float(a["windup"]) * 0.92 * windup_mult
		if not bool(a["parry"]) and String(a["name"]) != "mirror":
			a["windup"] = float(a["windup"]) * 0.4   # kırmızı (parry'lenemez) saldırılar ani: görünce hemen atıl
		a["recover"] = float(a["recover"]) * 0.9
		a["cd"] = float(a["cd"]) * 0.85
	hp = max_hp
	for a in attacks:
		_cd[a["name"]] = randf_range(0.3, 1.2)
	_build()
	if affixes.has("shielded"):
		give_ward(max_hp * 0.4)
	if not affixes.is_empty():
		_affix_label()
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


## İKİZ GÖKLER yaratıkları:
##  shade  -> İKİZ GÖLGE: çift doğar; biri ölünce eşi öfkelenir (daha hızlı ve sık saldırır). İkisini birlikte indir
##  caster -> MERKÜR HABERCİSİ: yaklaşınca ışınlanıp kaçar; gidip geri dönen rüzgâr bıçağı fırlatır
##  leaper -> FIRTINA KUŞU: havaya yükselir (dokunulmaz), tepende süzülür ve dalar
##  brute  -> AYNA MUHAFIZI: aynasını kaldırınca hafif vuruşlarını sana yansıtır; ağır vuruş aynayı kırar
func _gemini_variant() -> void:
	_base_body = Color(0.55, 0.7, 1.0)
	_base_cloth = Color(0.45, 0.5, 0.9)
	match kind:
		"caster":
			attacks = [
				{"name": "windblade", "shape": "line", "min": 2.5, "max": 10.0, "windup": 0.75, "act": 0.15, "recover": 0.6,
					"dmg": 12.0, "reach": 9.0, "arc": 0.0, "parry": false, "cd": 2.8, "weight": 1.0},
			]
		"leaper":
			_sky = true
			max_hp = 80.0
			attacks = [
				{"name": "claw", "shape": "fan", "min": 0.0, "max": 1.9, "windup": 0.45, "act": 0.12, "recover": 0.5,
					"dmg": 12.0, "reach": 2.1, "arc": 100.0, "parry": true, "cd": 1.0, "weight": 1.0},
				{"name": "burrow", "shape": "circle", "min": 3.0, "max": 12.0, "windup": 0.45, "act": 2.4, "recover": 0.7,
					"dmg": 22.0, "reach": 2.0, "arc": 360.0, "parry": false, "cd": 4.5, "weight": 2.0},
			]
		"brute":
			max_hp = 220.0
			attacks = [
				{"name": "smash", "shape": "fan", "min": 0.0, "max": 2.7, "windup": 0.8, "act": 0.16, "recover": 0.9,
					"dmg": 24.0, "reach": 3.0, "arc": 120.0, "parry": true, "cd": 1.6, "weight": 2.0},
				{"name": "mirror", "shape": "circle", "min": 0.0, "max": 7.0, "windup": 0.6, "act": 1.8, "recover": 0.5,
					"dmg": 0.0, "reach": 1.4, "arc": 360.0, "parry": false, "cd": 6.5, "weight": 1.5},
				{"name": "quake", "shape": "circle", "min": 0.0, "max": 4.2, "windup": 1.1, "act": 0.2, "recover": 1.0,
					"dmg": 26.0, "reach": 4.2, "arc": 360.0, "parry": false, "cd": 6.0, "weight": 1.0},
			]


## AY IŞIKLI KIYI yaratıkları:
##  shade  -> KABUK ASKERİ: kısa sürede 3 kez vurulursa kabuğuna çekilir (dokunulmaz), sonra etrafına kıskaç vurur
##  caster -> GELGİT KÂHİNİ: arenayı süpüren bir dalga duvarı gönderir; değerse seni geri iter
##  leaper -> AY DENİZANASI: yakınındayken seni kendine çeker; etrafına elektrik halkası yayar
##  brute  -> DEV KEŞİŞ YENGECİ: kabarcık yağdırır (yavaşlatır); sırtı yumuşak, arkadan vuruşlar iki kat
## KENTAUR BOZKIRI yaratıkları:
##  shade  -> KENTAUR MIZRAKÇISI: vurur ve hemen geri sıçrar (vur-kaç)
##  caster -> OKÇU: senin çevrene ok yağmuru indirir
##  leaper -> AVCI ŞAHİN: havada süzülür, gökten dalar
##  brute  -> KUŞATMA KENTAURU: sırtındaki balistayla arenayı boydan boya delen ok (seni savurur)
func _sag_variant() -> void:
	_base_body = Color(0.55, 0.4, 1.0)
	_base_cloth = Color(0.45, 0.3, 0.85)
	match kind:
		"shade":
			speed = 4.6
		"caster":
			attacks = [
				{"name": "volley", "shape": "circle", "min": 3.0, "max": 13.0, "windup": 0.8, "act": 0.15, "recover": 0.7,
					"dmg": 11.0, "reach": 1.2, "arc": 360.0, "parry": false, "cd": 3.4, "weight": 1.0},
			]
		"leaper":
			_sky = true
			max_hp = 80.0
			attacks = [
				{"name": "claw", "shape": "fan", "min": 0.0, "max": 1.9, "windup": 0.45, "act": 0.12, "recover": 0.5,
					"dmg": 12.0, "reach": 2.1, "arc": 100.0, "parry": true, "cd": 1.0, "weight": 1.0},
				{"name": "burrow", "shape": "circle", "min": 3.0, "max": 12.0, "windup": 0.45, "act": 2.4, "recover": 0.7,
					"dmg": 22.0, "reach": 2.0, "arc": 360.0, "parry": false, "cd": 4.5, "weight": 2.0},
			]
		"brute":
			max_hp = 230.0
			attacks = [
				{"name": "smash", "shape": "fan", "min": 0.0, "max": 2.7, "windup": 0.8, "act": 0.16, "recover": 0.9,
					"dmg": 24.0, "reach": 3.0, "arc": 120.0, "parry": true, "cd": 1.6, "weight": 1.5},
				{"name": "ballista", "shape": "line", "min": 3.5, "max": 14.0, "windup": 1.0, "act": 0.15, "recover": 0.9,
					"dmg": 22.0, "reach": 14.0, "arc": 0.0, "parry": false, "cd": 4.0, "weight": 1.5},
			]


## ZEHİR MAĞARALARI yaratıkları:
##  shade  -> ZEHİRLİ İĞNE: vuruşları zehirler (zehir canı eritir ama öldürmez)
##  caster -> ASİT TÜKÜRÜCÜ: yere zehirli asit gölcükleri fırlatır
##  leaper -> ÖLÜ TAKLİTÇİ: canı azalınca ölü taklidi yapar; 2 sn içinde bitirmezsen canlanıp atılır
##  brute  -> KISKAÇLI TİTAN: yakalama (kızıl): değerse kısa süre kıpırdayamaz ve zehirlenirsin
func _scorpio_variant() -> void:
	_base_body = Color(0.45, 1.0, 0.3)
	_base_cloth = Color(0.3, 0.7, 0.25)
	match kind:
		"caster":
			attacks = [
				{"name": "acid", "shape": "circle", "min": 3.0, "max": 11.0, "windup": 0.8, "act": 0.15, "recover": 0.7,
					"dmg": 12.0, "reach": 1.8, "arc": 360.0, "parry": false, "cd": 3.2, "weight": 1.0},
			]
		"brute":
			max_hp = 240.0
			attacks = [
				{"name": "smash", "shape": "fan", "min": 0.0, "max": 2.7, "windup": 0.8, "act": 0.16, "recover": 0.9,
					"dmg": 24.0, "reach": 3.0, "arc": 120.0, "parry": true, "cd": 1.6, "weight": 2.0},
				{"name": "grab", "shape": "fan", "min": 0.0, "max": 2.6, "windup": 0.75, "act": 0.16, "recover": 0.9,
					"dmg": 16.0, "reach": 2.8, "arc": 70.0, "parry": false, "cd": 5.0, "weight": 1.2},
			]


## ŞAFAK TERAZİSİ yaratıkları:
##  shade  -> HAKEM: eşiyle bağlı; birine vurduğun hasar ikisine bölünür (ikisini birlikte erit)
##  caster -> TERAZİ BEKÇİSİ: hükmü (sırayla iki patlama) ve yakındaki dostlarının canını eşitler
##  leaper -> TÜY DANSÇISI: 4 saniyede bir ilk vuruştan zarifçe kaçar
##  brute  -> KARŞI AĞIRLIK GOLEMİ: aldığı hasarı biriktirir; dolunca etrafını şok dalgasıyla döver
func _libra_variant() -> void:
	_base_body = Color(0.3, 0.9, 0.7)
	_base_cloth = Color(0.25, 0.6, 0.5)
	match kind:
		"caster":
			attacks = [
				{"name": "verdict", "shape": "circle", "min": 2.5, "max": 12.0, "windup": 0.7, "act": 0.15, "recover": 0.8,
					"dmg": 16.0, "reach": 1.6, "arc": 360.0, "parry": false, "cd": 3.4, "weight": 1.0},
			]
		"leaper":
			max_hp = 80.0
		"brute":
			max_hp = 240.0


func _tick_keeper(delta: float) -> void:
	_even_cd -= delta
	if _even_cd > 0.0 or state == "stun" or state == "spawn":
		return
	_even_cd = 6.0
	var group: Array = [self]
	for o in get_tree().get_nodes_in_group("enemies"):
		if o != self and not o.dead and o.get("max_hp") != null and o.get("phase") == null and o.global_position.distance_to(global_position) < 7.0:
			group.append(o)
	if group.size() < 2:
		return
	var tot := 0.0
	for o in group:
		tot += float(o.hp) / float(o.max_hp)
	var avg := tot / float(group.size())
	for o in group:
		o.hp = clampf(float(o.max_hp) * avg, 1.0, float(o.max_hp))
	var r := SlashFx.make(0.0, TAU, 0.3, 7.0, Color(0.4, 1.0, 0.8), 0.4)
	get_parent().add_child(r)
	r.global_transform = Transform3D(Basis.IDENTITY, global_position + Vector3(0, 0.2, 0))
	Sfx.play("parry", -10.0, 0.05, 0, 1.2)


## SESSİZ HASAT yaratıkları:
##  shade  -> ORAKÇI: altın pençe + etrafında 360° orak savuruşu (kızıl)
##  caster -> ARŞİVCİ: sana doğru sırayla patlayan üç mühür dizer (düzen!)
##  leaper -> TOHUM EKİCİ: üstüne atlar, indiği yere yavaşlatan tohumlar saçar
##  brute  -> HASIR DEV: 2.5 sn vurulmazsa hızla yenilenir; baskıyı bırakma
func _virgo_variant() -> void:
	_base_body = Color(0.6, 0.5, 1.0)
	_base_cloth = Color(0.45, 0.4, 0.8)
	match kind:
		"shade":
			attacks = [
				{"name": "claw", "shape": "fan", "min": 0.0, "max": 2.1, "windup": 0.55, "act": 0.14, "recover": 0.55,
					"dmg": 16.0, "reach": 2.5, "arc": 110.0, "parry": true, "cd": 1.1, "weight": 3.0},
				{"name": "reap", "shape": "circle", "min": 0.0, "max": 2.4, "windup": 0.8, "act": 0.18, "recover": 0.7,
					"dmg": 20.0, "reach": 2.7, "arc": 360.0, "parry": false, "cd": 4.0, "weight": 1.2},
			]
		"caster":
			attacks = [
				{"name": "seals", "shape": "circle", "min": 2.5, "max": 12.0, "windup": 0.7, "act": 0.15, "recover": 0.8,
					"dmg": 16.0, "reach": 1.4, "arc": 360.0, "parry": false, "cd": 3.6, "weight": 1.0},
			]
		"leaper":
			max_hp = 70.0
		"brute":
			max_hp = 230.0


func _tick_wicker(delta: float) -> void:
	_calm += delta
	if _calm > 2.5 and hp < max_hp and state != "spawn":
		hp = minf(hp + max_hp * 0.04 * delta, max_hp)
		m_body.emission_energy_multiplier = 0.6 + 0.4 * sin(_t * 8.0)


## GÜNEŞ SARAYI yaratıkları:
##  shade  -> SÜRÜ YAVRUSU: yakınındaki her kardeşi için +%20 hasar (en çok +%60); sürüyü dağıt
##  caster -> GÜNEŞ RAHİBİ: hatta güneş ışını indirir ve bir dostuna taç giydirir (taçlı: +%50 hasar)
##  leaper -> SERAP AVCISI: kovalarken görünmez olur, sadece titreşir; vurulunca ya da saldırırken görünür
##  brute  -> NEMEA ASLANI: postu hasarın %70'ini emer; saldırısını parry'lersen post çatlar (6 sn tam hasar)
##            + KÜKREME: etrafındakileri yavaşlatır
func _leo_variant() -> void:
	_base_body = Color(1.0, 0.74, 0.36)
	_base_cloth = Color(0.95, 0.6, 0.25)
	match kind:
		"caster":
			attacks = [
				{"name": "sunbeam", "shape": "line", "min": 3.0, "max": 13.0, "windup": 0.9, "act": 0.15, "recover": 0.7,
					"dmg": 16.0, "reach": 13.0, "arc": 0.0, "parry": false, "cd": 3.0, "weight": 1.0},
			]
		"shade":
			speed = 4.0
			max_hp = 80.0
		"leaper":
			max_hp = 85.0
			speed = 4.6
		"brute":
			max_hp = 240.0
			attacks = [
				{"name": "smash", "shape": "fan", "min": 0.0, "max": 2.7, "windup": 0.8, "act": 0.16, "recover": 0.9,
					"dmg": 26.0, "reach": 3.1, "arc": 120.0, "parry": true, "cd": 1.5, "weight": 2.0},
				{"name": "roar", "shape": "circle", "min": 0.0, "max": 4.5, "windup": 0.9, "act": 0.2, "recover": 0.9,
					"dmg": 12.0, "reach": 4.6, "arc": 360.0, "parry": false, "cd": 7.0, "weight": 1.0},
			]


## Sürü ve taç güçlendirmeleri
func _buff() -> float:
	var b := 1.0
	if crowned > 0.0:
		b += 0.5
	if zone == "leo" and kind == "shade":
		var n := 0
		for o in get_tree().get_nodes_in_group("enemies"):
			if o != self and not o.dead and o.get("zone") == "leo" and o.get("kind") == "shade" and o.global_position.distance_to(global_position) < 6.0:
				n += 1
		b += 0.2 * float(mini(n, 3))
	return b


func _tick_crown_caster(delta: float) -> void:
	_crown_cd -= delta
	if _crown_cd > 0.0 or state == "stun" or state == "spawn":
		return
	var best = null
	var bd := 12.0
	for o in get_tree().get_nodes_in_group("enemies"):
		if o == self or o.dead or o.get("crowned") == null or float(o.crowned) > 0.0:
			continue
		var d: float = o.global_position.distance_to(global_position)
		if o.kind == "brute":
			d -= 3.0
		if d < bd:
			bd = d
			best = o
	if best == null:
		_crown_cd = 1.0
		return
	_crown_cd = 8.0
	best.give_crown(8.0)
	var ln := SlashFx.make(0.0, TAU, 0.2, 1.2, Color(1.0, 0.8, 0.3), 0.3)
	get_parent().add_child(ln)
	ln.global_transform = Transform3D(Basis.IDENTITY, best.global_position + Vector3(0, 2.2 * float(best.size_k), 0))
	Fx.flash_light(global_position + Vector3(0, 2.2, 0), Color(1.0, 0.8, 0.35), 4.0, 4.0, 0.3)
	Sfx.play("parry", -10.0, 0.05, 0, 1.4)


func give_crown(dur: float) -> void:
	crowned = dur
	if _crown_node == null:
		_crown_node = Node3D.new()
		var gm := StandardMaterial3D.new()
		gm.albedo_color = Color(1.0, 0.8, 0.3)
		gm.metallic = 0.9
		gm.roughness = 0.25
		gm.emission_enabled = true
		gm.emission = Color(1.0, 0.7, 0.2)
		gm.emission_energy_multiplier = 1.5
		for i in 6:
			var a := TAU * float(i) / 6.0
			var sp := MeshInstance3D.new()
			var c := CylinderMesh.new()
			c.top_radius = 0.0
			c.bottom_radius = 0.06
			c.height = 0.22
			sp.mesh = c
			sp.material_override = gm
			sp.position = Vector3(cos(a) * 0.2, 0.1, sin(a) * 0.2)
			_crown_node.add_child(sp)
		var band := MeshInstance3D.new()
		var t := TorusMesh.new()
		t.inner_radius = 0.17
		t.outer_radius = 0.24
		band.mesh = t
		band.material_override = gm
		_crown_node.add_child(band)
		add_child(_crown_node)
	_crown_node.position.y = 2.0 * size_k
	_crown_node.visible = true


func _cancer_variant() -> void:
	_base_body = Color(1.0, 0.45, 0.32)
	_base_cloth = Color(0.85, 0.35, 0.3)
	match kind:
		"caster":
			attacks = [
				{"name": "tidewave", "shape": "line", "min": 3.0, "max": 12.0, "windup": 0.9, "act": 0.15, "recover": 0.7,
					"dmg": 14.0, "reach": 12.0, "arc": 0.0, "parry": false, "cd": 3.4, "weight": 1.0},
			]
		"leaper":
			max_hp = 90.0
			speed = 2.6
			attacks = [
				{"name": "pulse", "shape": "circle", "min": 0.0, "max": 2.6, "windup": 0.75, "act": 0.15, "recover": 0.8,
					"dmg": 16.0, "reach": 2.7, "arc": 360.0, "parry": false, "cd": 2.2, "weight": 1.0},
			]
		"brute":
			max_hp = 220.0
			attacks = [
				{"name": "smash", "shape": "fan", "min": 0.0, "max": 2.7, "windup": 0.8, "act": 0.16, "recover": 0.9,
					"dmg": 24.0, "reach": 3.0, "arc": 120.0, "parry": true, "cd": 1.6, "weight": 2.0},
				{"name": "bubbles", "shape": "circle", "min": 2.0, "max": 10.0, "windup": 0.8, "act": 0.15, "recover": 0.8,
					"dmg": 10.0, "reach": 1.2, "arc": 360.0, "parry": false, "cd": 6.0, "weight": 1.5},
			]


## İkiz Gölge: eşi öldü
func lost_twin() -> void:
	if dead or _enraged:
		return
	_enraged = true
	speed *= 1.4
	for a in attacks:
		a["windup"] = float(a["windup"]) * 0.7
		a["cd"] = float(a["cd"]) * 0.6
	_base_body = Color(1.0, 0.2, 0.15)
	_base_cloth = Color(0.8, 0.1, 0.1)
	Sfx.play("enemyattack", -4.0, 0.05, 0, 0.7)
	Fx.flash_light(global_position + Vector3(0, 1.5, 0), Color(1.0, 0.2, 0.15), 5.0, 5.0, 0.4)


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
	elif zone == "gemini":
		m_eye.emission = Color(0.6, 0.85, 1.0)
		m_claw.emission = Color(0.7, 0.85, 1.0)
		match kind:
			"caster":
				_build_herald()
			"leaper":
				_build_stormbird()
			"brute":
				_build_mguard()
			_:
				_build_wraith()
	elif zone == "sagittarius":
		m_eye.emission = Color(1.0, 0.85, 0.45)
		m_body.albedo_color = Color(0.42, 0.3, 0.72)
		m_cloth.albedo_color = Color(0.35, 0.25, 0.6)
		match kind:
			"caster":
				_build_archer()
			"leaper":
				_build_hawk()
			"brute":
				_build_siege()
			_:
				_build_lancer()
	elif zone == "scorpio":
		m_eye.emission = Color(0.5, 1.0, 0.3)
		m_body.albedo_color = Color(0.12, 0.1, 0.16)
		match kind:
			"caster":
				_build_spitter()
			"leaper":
				_build_mimic()
			"brute":
				_build_grabber()
			_:
				_build_stinger()
	elif zone == "libra":
		m_eye.emission = Color(1.0, 0.85, 0.6)
		m_body.albedo_color = Color(0.3, 0.7, 0.58)
		m_cloth.albedo_color = Color(0.55, 0.42, 0.3)
		match kind:
			"caster":
				_build_keeper()
			"leaper":
				_build_dancer()
			"brute":
				_build_counterweight()
			_:
				_build_arbiter()
	elif zone == "virgo":
		m_eye.emission = Color(0.4, 1.0, 0.85)
		m_body.albedo_color = Color(0.9, 0.9, 0.95)
		m_cloth.albedo_color = Color(0.55, 0.5, 0.78)
		match kind:
			"caster":
				_build_archivist()
			"leaper":
				_build_sower()
			"brute":
				_build_wicker()
			_:
				_build_reaper()
	elif zone == "leo":
		m_eye.emission = Color(1.0, 0.85, 0.3)
		# altın post: koyu silüet yerine açık altın (mor zeminde kahverengi görünmesin)
		m_body.albedo_color = Color(0.95, 0.72, 0.38)
		m_cloth.albedo_color = Color(0.9, 0.62, 0.3)
		match kind:
			"caster":
				_build_sunpriest()
			"leaper":
				_build_stalker()
			"brute":
				_build_nemean()
			_:
				_build_cub()
	elif zone == "cancer":
		m_eye.emission = Color(0.4, 0.95, 1.0)
		m_claw.emission = Color(1.0, 0.5, 0.35)
		match kind:
			"caster":
				_build_tideoracle()
			"leaper":
				_build_jelly()
			"brute":
				_build_hermit()
			_:
				_build_shellguard()
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

	_claw_base = m_claw.emission
	_eye_base = m_eye.emission
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


# ---- İkiz Gökler görünüşleri

func _silver() -> StandardMaterial3D:
	var m := _m(Color(0.85, 0.88, 0.95), 0.25)
	m.metallic = 0.9
	return m


func _build_wraith() -> void:
	# İKİZ GÖLGE: yarısı gümüş yarısı gece; iki yüzlü maske
	var light := _m(Color(0.85, 0.88, 0.95), 0.6)
	light.emission_enabled = true
	light.emission = Color(0.5, 0.6, 0.9)
	light.emission_energy_multiplier = 0.3
	for s in [-1.0, 1.0]:
		var half := _part(vis, _cone(0.03, 0.17, 1.1, 8), Vector3(s * 0.08, 0.95, 0), light if s < 0.0 else m_cloth)
		half.scale = Vector3(1.0, 1.0, 1.6)
	_part(vis, _sph(0.3, 0.5), Vector3(0, 1.55, 0), m_body, Vector3(1.2, 1.0, 0.85))
	var hp := Vector3(0, 1.9, 0)
	_part(vis, _sph(0.22), hp, light, Vector3(1.0, 1.1, 1.0))
	_part(vis, _sph(0.17), hp + Vector3(0, 0, 0.08), m_cloth, Vector3(1.05, 1.15, 0.9))
	var eye := _sph(0.035)
	_part(vis, eye, hp + Vector3(-0.07, 0.02, -0.2), m_eye, Vector3(1.4, 0.7, 1.0))
	_part(vis, eye, hp + Vector3(0.07, 0.02, -0.2), m_eye, Vector3(1.4, 0.7, 1.0))
	_part(vis, eye, hp + Vector3(-0.07, 0.02, 0.2), m_eye, Vector3(1.4, 0.7, 1.0))
	_part(vis, eye, hp + Vector3(0.07, 0.02, 0.2), m_eye, Vector3(1.4, 0.7, 1.0))
	arm_l = _arm(-1.0, Vector3(-0.36, 1.6, 0), 0.8)
	arm_r = _arm(1.0, Vector3(0.36, 1.6, 0), 0.8)


func _build_herald() -> void:
	# MERKÜR HABERCİSİ: kanatlı miğfer, yılanlı asa (kaduse), beyaz-mavi cüppe
	var robe := _m(Color(0.88, 0.92, 1.0), 0.7)
	robe.emission_enabled = true
	robe.emission = Color(0.4, 0.55, 0.9)
	robe.emission_energy_multiplier = 0.2
	_part(vis, _cone(0.42, 0.13, 1.5, 12), Vector3(0, 1.0, 0), robe)
	_part(vis, _sph(0.22, 0.45), Vector3(0, 1.8, 0), robe)
	var hp := Vector3(0, 2.12, 0)
	var silver := _silver()
	_part(vis, _sph(0.17), hp, silver, Vector3(1.0, 1.0, 1.1))
	_part(vis, _sph(0.035), hp + Vector3(-0.06, -0.02, -0.16), m_eye, Vector3(1.4, 0.7, 1.0))
	_part(vis, _sph(0.035), hp + Vector3(0.06, -0.02, -0.16), m_eye, Vector3(1.4, 0.7, 1.0))
	for s in [-1.0, 1.0]:
		for k in 3:
			var w := _part(vis, _cone(0.05, 0.0, 0.32 - float(k) * 0.06, 4), hp + Vector3(s * 0.18, 0.08 + float(k) * 0.05, 0.05 + float(k) * 0.06), m_claw)
			w.rotation = Vector3(0.9, 0, -s * 1.2)
	arm_l = _arm(-1.0, Vector3(-0.28, 1.9, 0), 0.6)
	arm_r = _arm(1.0, Vector3(0.28, 1.9, 0), 0.6)
	var staff := _part(arm_r, _cone(0.025, 0.025, 1.8, 6), Vector3(0.05, -0.35, 0), _m(Color(0.95, 0.8, 0.4)))
	staff.rotation.x = 0.1
	for k in 6:
		var a := float(k) * 1.2
		_part(arm_r, _sph(0.045), Vector3(0.05 + cos(a) * 0.08, 0.1 + float(k) * 0.09, sin(a) * 0.08), m_eye)
	_part(arm_r, _sph(0.09), Vector3(0.05, 0.65, 0), m_claw)


func _build_stormbird() -> void:
	# FIRTINA KUŞU: geniş kanatlı, gümüş tüylü yırtıcı
	var feather := _m(Color(0.75, 0.8, 0.92), 0.8)
	feather.emission_enabled = true
	feather.emission = Color(0.4, 0.55, 0.9)
	feather.emission_energy_multiplier = 0.25
	_part(vis, _sph(0.32, 0.5), Vector3(0, 1.1, 0), feather, Vector3(0.9, 0.8, 1.5))
	var hp := Vector3(0, 1.3, -0.5)
	_part(vis, _sph(0.17), hp, feather)
	var beak := _part(vis, _cone(0.06, 0.0, 0.25, 4), hp + Vector3(0, -0.04, -0.2), _m(Color(0.95, 0.8, 0.35)))
	beak.rotation.x = -PI * 0.5
	_part(vis, _sph(0.035), hp + Vector3(-0.08, 0.04, -0.12), m_eye)
	_part(vis, _sph(0.035), hp + Vector3(0.08, 0.04, -0.12), m_eye)
	for k in 3:
		var tf := _part(vis, _cone(0.08, 0.0, 0.55, 4), Vector3((float(k) - 1.0) * 0.08, 1.12, 0.65), feather)
		tf.rotation = Vector3(1.4, 0, (float(k) - 1.0) * 0.3)
	for s in [-1.0, 1.0]:
		_part(vis, _cone(0.025, 0.035, 0.45, 5), Vector3(s * 0.1, 0.65, 0.05), m_claw)
	# kanatlar: kol düğümleri kanat gibi çırpar
	arm_l = Node3D.new()
	arm_l.position = Vector3(-0.25, 1.2, 0)
	vis.add_child(arm_l)
	arm_r = Node3D.new()
	arm_r.position = Vector3(0.25, 1.2, 0)
	vis.add_child(arm_r)
	for pair in [[arm_l, -1.0], [arm_r, 1.0]]:
		var wn: Node3D = pair[0]
		var s: float = pair[1]
		var wing := BoxMesh.new()
		wing.size = Vector3(1.1, 0.05, 0.5)
		_part(wn, wing, Vector3(s * 0.55, 0, 0), feather)
		var tip := BoxMesh.new()
		tip.size = Vector3(0.5, 0.04, 0.35)
		_part(wn, tip, Vector3(s * 1.25, 0, 0.1), m_claw)


func _build_mguard() -> void:
	# AYNA MUHAFIZI: gümüş zırhlı dev; kaldırınca parlayan büyük yuvarlak ayna
	var silver := _silver()
	_part(vis, _cone(0.22, 0.4, 0.9, 12), Vector3(0, 0.6, 0), m_cloth)
	_part(vis, _sph(0.55, 0.9), Vector3(0, 1.4, 0), m_body, Vector3(1.3, 1.0, 0.95))
	_part(vis, _sph(0.42, 0.6), Vector3(0, 1.5, -0.22), silver, Vector3(1.35, 1.0, 0.6))
	var hp := Vector3(0, 2.0, -0.1)
	_part(vis, _sph(0.26), hp, silver, Vector3(1.0, 1.1, 1.05))
	var visor := BoxMesh.new()
	visor.size = Vector3(0.3, 0.05, 0.05)
	_part(vis, visor, hp + Vector3(0, 0.02, -0.25), m_eye)
	arm_l = _arm(-1.0, Vector3(-0.72, 1.65, 0), 0.9)
	arm_r = _arm(1.0, Vector3(0.72, 1.65, 0), 0.9)
	_part(arm_r, _sph(0.22), Vector3(0, -1.0, 0), silver, Vector3(1.0, 1.3, 1.0))
	# ayna (ayna duruşunda parlar)
	_mirror_node = MeshInstance3D.new()
	var disk := CylinderMesh.new()
	disk.top_radius = 0.9
	disk.bottom_radius = 0.9
	disk.height = 0.06
	disk.radial_segments = 24
	_mirror_node.mesh = disk
	var mm := StandardMaterial3D.new()
	mm.albedo_color = Color(0.85, 0.95, 1.0)
	mm.metallic = 1.0
	mm.roughness = 0.05
	mm.emission_enabled = true
	mm.emission = Color(0.7, 0.9, 1.0)
	mm.emission_energy_multiplier = 1.5
	_mirror_node.material_override = mm
	_mirror_node.position = Vector3(0, 1.4, -0.85)
	_mirror_node.rotation.x = PI * 0.5
	_mirror_node.visible = false
	vis.add_child(_mirror_node)


# ---- Ay Işıklı Kıyı görünüşleri

func _shell_mat() -> StandardMaterial3D:
	var m := _m(Color(0.95, 0.5, 0.38), 0.45)
	m.emission_enabled = true
	m.emission = Color(1.0, 0.35, 0.25)
	m.emission_energy_multiplier = 0.25
	return m


func _crab_legs(parent: Node3D, n: int, spread: float, y: float, ln: float) -> void:
	for s in [-1.0, 1.0]:
		for k in n:
			var leg := _part(parent, _cone(0.05, 0.03, ln, 5), Vector3(s * spread, y, -0.25 + float(k) * 0.25), m_cloth)
			leg.rotation.z = s * 1.0
			leg.rotation.y = (float(k) - 1.0) * 0.3 * s


# ---- Güneş Sarayı görünüşleri (altın-amber yaratıklar; zemin mor-beyaz mermer)

func _mane_mat() -> StandardMaterial3D:
	var m := _m(Color(0.95, 0.55, 0.15), 0.8)
	m.emission_enabled = true
	m.emission = Color(1.0, 0.5, 0.1)
	m.emission_energy_multiplier = 0.45
	return m


func _lion(sc: float, mane_n: int) -> Node3D:
	# dört ayaklı aslan gövdesi; yele halkası; kuyruk
	var mane := _mane_mat()
	_part(vis, _sph(0.42 * sc, 0.62 * sc), Vector3(0, 0.75 * sc, 0.1 * sc), m_body, Vector3(0.85, 0.8, 1.6))
	for i in 4:
		var x := (-0.22 if i % 2 == 0 else 0.22) * sc
		var z := (-0.4 if i < 2 else 0.5) * sc
		_part(vis, _cone(0.07 * sc, 0.09 * sc, 0.6 * sc, 6), Vector3(x, 0.3 * sc, z), m_body)
		_part(vis, _sph(0.09 * sc), Vector3(x, 0.04 * sc, z - 0.04 * sc), m_claw, Vector3(1.0, 0.6, 1.3))
	var hd := Node3D.new()
	hd.position = Vector3(0, 1.0 * sc, -0.62 * sc)
	vis.add_child(hd)
	for i in mane_n:
		var a := TAU * float(i) / float(mane_n)
		var sp := _part(hd, _cone(0.12 * sc, 0.0, 0.42 * sc, 5), Vector3(cos(a) * 0.24 * sc, sin(a) * 0.24 * sc, 0.08 * sc), mane)
		sp.rotation = Vector3(0, 0, a - PI * 0.5)
		sp.rotate_object_local(Vector3.RIGHT, -0.3)
	_part(hd, _sph(0.26 * sc), Vector3.ZERO, mane, Vector3(1.1, 1.1, 0.9))
	_part(hd, _sph(0.19 * sc), Vector3(0, -0.02 * sc, -0.14 * sc), m_body, Vector3(1.0, 0.95, 1.1))
	_part(hd, _sph(0.1 * sc), Vector3(0, -0.08 * sc, -0.3 * sc), m_body, Vector3(1.0, 0.8, 1.0))
	var eye := _sph(0.035 * sc)
	_part(hd, eye, Vector3(-0.08 * sc, 0.04 * sc, -0.29 * sc), m_eye, Vector3(1.4, 0.7, 1.0))
	_part(hd, eye, Vector3(0.08 * sc, 0.04 * sc, -0.29 * sc), m_eye, Vector3(1.4, 0.7, 1.0))
	var tail := _part(vis, _cone(0.03 * sc, 0.02 * sc, 0.7 * sc, 5), Vector3(0, 0.95 * sc, 0.95 * sc), m_body)
	tail.rotation.x = 0.9
	_part(vis, _sph(0.08 * sc), Vector3(0, 1.2 * sc, 1.2 * sc), mane)
	arm_l = Node3D.new()
	arm_r = Node3D.new()
	hd.add_child(arm_l)
	hd.add_child(arm_r)
	return hd


func _build_cub() -> void:
	# SÜRÜ YAVRUSU: küçük, çevik aslan; yanında kardeşleri varsa güçlenir
	_lion(0.8, 9)


func _build_sunpriest() -> void:
	# GÜNEŞ RAHİBİ: beyaz-altın cüppe, arkasında güneş halesi; dostlarına taç giydirir
	var robe := _m(Color(0.95, 0.92, 0.85), 0.6)
	var gold := _m(Color(1.0, 0.8, 0.35), 0.3)
	_part(vis, _cone(0.5, 0.15, 1.6, 12), Vector3(0, 0.95, 0), robe)
	_part(vis, _cone(0.52, 0.5, 0.12, 12), Vector3(0, 0.5, 0), gold)
	_part(vis, _sph(0.24, 0.46), Vector3(0, 1.8, 0), robe)
	var hp := Vector3(0, 2.12, 0)
	_part(vis, _sph(0.17), hp, m_body)
	_part(vis, _sph(0.035), hp + Vector3(-0.06, 0.0, -0.16), m_eye, Vector3(1.4, 0.7, 1.0))
	_part(vis, _sph(0.035), hp + Vector3(0.06, 0.0, -0.16), m_eye, Vector3(1.4, 0.7, 1.0))
	# güneş halesi: arkada ışın saçan disk
	var halo := _m(Color(1.0, 0.8, 0.35), 0.3)
	halo.emission_enabled = true
	halo.emission = Color(1.0, 0.7, 0.25)
	halo.emission_energy_multiplier = 1.6
	var disc := _part(vis, _cone(0.34, 0.34, 0.04, 16), hp + Vector3(0, 0.05, 0.2), halo)
	disc.rotation.x = PI * 0.5
	for i in 12:
		var a := TAU * float(i) / 12.0
		var r := _part(vis, _cone(0.05, 0.0, 0.32, 4), hp + Vector3(cos(a) * 0.48, sin(a) * 0.48 + 0.05, 0.22), halo)
		r.rotation.z = a - PI * 0.5
	arm_l = _arm(-1.0, Vector3(-0.3, 1.85, 0), 0.6)
	arm_r = _arm(1.0, Vector3(0.3, 1.85, 0), 0.6)
	_part(arm_r, _cone(0.03, 0.03, 1.4, 6), Vector3(0, -0.5, -0.1), gold)
	_part(arm_r, _sph(0.12), Vector3(0, -1.2, -0.1), halo)


func _build_stalker() -> void:
	# SERAP AVCISI: ince, uzun bacaklı dişi aslan; kovalarken serap gibi görünmez olur
	_lion(0.9, 0)


func _build_nemean() -> void:
	# NEMEA ASLANI: dev, altın yeleli; postu neredeyse delinmez (parry ile çatlat)
	_lion(1.55, 16)
	var plate := _m(Color(1.0, 0.88, 0.55), 0.35)
	plate.emission_enabled = true
	plate.emission = Color(1.0, 0.75, 0.35)
	plate.emission_energy_multiplier = 0.35
	_part(vis, _sph(0.5), Vector3(0, 1.35, 0.15), plate, Vector3(1.3, 0.35, 1.9))


# ---- Sessiz Hasat görünüşleri (porselen beyazı yaratıklar; zemin koyu yeşil-camgöbeği)

func _porcelain() -> StandardMaterial3D:
	var m := _m(Color(0.93, 0.92, 0.97), 0.25)
	m.emission_enabled = true
	m.emission = Color(0.55, 0.45, 0.85)
	m.emission_energy_multiplier = 0.15
	return m


func _build_reaper() -> void:
	# ORAKÇI: porselen yüzlü, uzun etekli hasatçı; elinde orak
	var por := _porcelain()
	_part(vis, _cone(0.42, 0.16, 1.3, 10), Vector3(0, 0.7, 0), m_cloth)
	_part(vis, _sph(0.28, 0.5), Vector3(0, 1.45, 0), por, Vector3(1.0, 1.0, 0.8))
	var hp := Vector3(0, 1.85, 0)
	_part(vis, _sph(0.16), hp, por)
	_part(vis, _sph(0.03), hp + Vector3(-0.06, 0.0, -0.15), m_eye, Vector3(1.5, 0.6, 1.0))
	_part(vis, _sph(0.03), hp + Vector3(0.06, 0.0, -0.15), m_eye, Vector3(1.5, 0.6, 1.0))
	_part(vis, _cone(0.2, 0.0, 0.3, 8), hp + Vector3(0, 0.2, 0.03), m_cloth)
	arm_l = _arm(-1.0, Vector3(-0.3, 1.55, 0), 0.55)
	arm_r = _arm(1.0, Vector3(0.3, 1.55, 0), 0.55)
	var silver := _m(Color(0.85, 0.9, 0.95), 0.2)
	silver.metallic = 0.6
	_part(arm_r, _cone(0.025, 0.025, 1.3, 5), Vector3(0, -0.5, 0), m_cloth)
	var blade := _part(arm_r, _cone(0.06, 0.0, 0.8, 4), Vector3(-0.35, -1.1, -0.1), silver, Vector3(1.0, 1.0, 0.25))
	blade.rotation.z = 1.3


func _build_archivist() -> void:
	# ARŞİVCİ: kitap taşıyan, gözlüklü porselen bilge; çevresinde dönen sayfalar
	var por := _porcelain()
	_part(vis, _cone(0.48, 0.2, 1.5, 12), Vector3(0, 0.9, 0), m_cloth)
	_part(vis, _sph(0.24, 0.44), Vector3(0, 1.75, 0), por)
	var hp := Vector3(0, 2.08, 0)
	_part(vis, _sph(0.17), hp, por)
	for s in [-1.0, 1.0]:
		_part(vis, _sph(0.055), hp + Vector3(s * 0.07, 0.0, -0.15), m_eye)
	arm_l = _arm(-1.0, Vector3(-0.3, 1.8, 0), 0.6)
	arm_r = _arm(1.0, Vector3(0.3, 1.8, 0), 0.6)
	var book := _m(Color(0.25, 0.55, 0.5), 0.5)
	_part(vis, BoxMesh.new(), Vector3(0, 1.5, -0.5), book, Vector3(0.5, 0.08, 0.38))
	var page := _m(Color(0.95, 0.95, 0.85), 0.6)
	page.emission_enabled = true
	page.emission = Color(0.6, 1.0, 0.9)
	page.emission_energy_multiplier = 0.6
	for i in 4:
		var a := TAU * float(i) / 4.0
		var pg := _part(vis, BoxMesh.new(), Vector3(cos(a) * 0.75, 1.9 + float(i % 2) * 0.25, sin(a) * 0.75), page, Vector3(0.25, 0.02, 0.32))
		pg.rotation.y = a


func _build_sower() -> void:
	# TOHUM EKİCİ: kanatlı, tohum keseli küçük porselen peri
	var por := _porcelain()
	_part(vis, _sph(0.3, 0.5), Vector3(0, 0.9, 0), por, Vector3(1.0, 1.1, 0.9))
	_part(vis, _sph(0.17), Vector3(0, 1.35, -0.05), por)
	for s in [-1.0, 1.0]:
		_part(vis, _sph(0.035), Vector3(s * 0.06, 1.37, -0.2), m_eye, Vector3(1.4, 0.7, 1.0))
		var w := _part(vis, _sph(0.4), Vector3(s * 0.45, 1.1, 0.15), m_cloth, Vector3(1.0, 0.6, 0.08))
		w.rotation.y = s * 0.5
		_part(vis, _cone(0.04, 0.05, 0.5, 5), Vector3(s * 0.12, 0.4, 0), por)
	_part(vis, _sph(0.18), Vector3(0.25, 0.75, 0.1), _m(Color(0.3, 0.6, 0.45)))
	arm_l = Node3D.new()
	arm_r = Node3D.new()
	vis.add_child(arm_l)
	vis.add_child(arm_r)


func _build_wicker() -> void:
	# HASIR DEV: başak demetlerinden örülmüş dev; içi camgöbeği ışıkla yanar
	var straw := _m(Color(0.85, 0.85, 0.78), 0.9)
	var core := _m(Color(0.3, 1.0, 0.85), 0.4)
	core.emission_enabled = true
	core.emission = Color(0.3, 1.0, 0.85)
	core.emission_energy_multiplier = 1.5
	_part(vis, _sph(0.3), Vector3(0, 1.3, 0), core)
	for i in 10:
		var a := TAU * float(i) / 10.0
		var st := _part(vis, _cone(0.08, 0.05, 1.6, 5), Vector3(cos(a) * 0.4, 1.3, sin(a) * 0.4), straw)
		st.rotation = Vector3(sin(a) * 0.25, 0, -cos(a) * 0.25)
	_part(vis, _sph(0.3), Vector3(0, 2.2, 0), straw, Vector3(1.0, 1.2, 1.0))
	for s in [-1.0, 1.0]:
		_part(vis, _sph(0.06), Vector3(s * 0.1, 2.25, -0.27), m_eye)
		_part(vis, _cone(0.1, 0.12, 1.0, 5), Vector3(s * 0.22, 0.35, 0), straw)
	arm_l = _arm(-1.0, Vector3(-0.6, 1.9, 0), 0.9)
	arm_r = _arm(1.0, Vector3(0.6, 1.9, 0), 0.9)
	for a in [arm_l, arm_r]:
		_part(a, _sph(0.25), Vector3(0, -1.0, 0), straw, Vector3(1.0, 1.3, 1.0))


# ---- Şafak Terazisi görünüşleri (yeşim-bronz yaratıklar; zemin gül pembesi / arduvaz)

func _jade() -> StandardMaterial3D:
	var m := _m(Color(0.35, 0.8, 0.65), 0.3)
	m.emission_enabled = true
	m.emission = Color(0.2, 0.9, 0.7)
	m.emission_energy_multiplier = 0.35
	return m


func _bronze2() -> StandardMaterial3D:
	var m := _m(Color(0.75, 0.55, 0.35), 0.35)
	m.metallic = 0.6
	return m


func _build_arbiter() -> void:
	# HAKEM: maskeli, iki kılıçlı yeşim yargıç; eşiyle bağlı (hasar ikisine bölünür)
	var jade := _jade()
	var br := _bronze2()
	_part(vis, _cone(0.36, 0.2, 1.1, 10), Vector3(0, 0.75, 0), m_cloth)
	_part(vis, _sph(0.28, 0.5), Vector3(0, 1.45, 0), jade, Vector3(1.1, 1.0, 0.8))
	var hp := Vector3(0, 1.88, 0)
	_part(vis, _sph(0.16), hp, br)
	_part(vis, _sph(0.04), hp + Vector3(-0.06, 0.0, -0.15), m_eye, Vector3(1.5, 0.6, 1.0))
	_part(vis, _sph(0.04), hp + Vector3(0.06, 0.0, -0.15), m_eye, Vector3(1.5, 0.6, 1.0))
	_part(vis, BoxMesh.new(), hp + Vector3(0, 0.2, 0), br, Vector3(0.36, 0.05, 0.05))
	arm_l = _arm(-1.0, Vector3(-0.33, 1.55, 0), 0.55)
	arm_r = _arm(1.0, Vector3(0.33, 1.55, 0), 0.55)
	for a in [arm_l, arm_r]:
		_part(a, BoxMesh.new(), Vector3(0, -0.85, -0.15), br, Vector3(0.05, 0.7, 0.08))


func _build_keeper() -> void:
	# TERAZİ BEKÇİSİ: elinde küçük terazi taşıyan cüppeli bilge; dostlarının canını eşitler
	var jade := _jade()
	var br := _bronze2()
	_part(vis, _cone(0.48, 0.18, 1.55, 12), Vector3(0, 0.92, 0), m_cloth)
	_part(vis, _sph(0.24, 0.44), Vector3(0, 1.78, 0), jade)
	var hp := Vector3(0, 2.1, 0)
	_part(vis, _sph(0.17), hp, br)
	_part(vis, _sph(0.04), hp + Vector3(-0.06, 0.0, -0.16), m_eye)
	_part(vis, _sph(0.04), hp + Vector3(0.06, 0.0, -0.16), m_eye)
	arm_l = _arm(-1.0, Vector3(-0.3, 1.85, 0), 0.6)
	arm_r = _arm(1.0, Vector3(0.3, 1.85, 0), 0.6)
	# başının üstünde süzülen terazi
	_part(vis, BoxMesh.new(), Vector3(0, 2.6, 0), br, Vector3(0.9, 0.04, 0.04))
	for s in [-1.0, 1.0]:
		_part(vis, _sph(0.12), Vector3(s * 0.45, 2.42, 0), jade, Vector3(1.0, 0.4, 1.0))


func _build_dancer() -> void:
	# TÜY DANSÇISI: uzun bacaklı, tüylü yeşim kuş-insan; ilk vuruştan zarifçe kaçar
	var jade := _jade()
	_part(vis, _sph(0.26, 0.5), Vector3(0, 1.1, 0), jade, Vector3(0.9, 1.2, 0.8))
	_part(vis, _sph(0.15), Vector3(0, 1.62, -0.05), jade)
	_part(vis, _cone(0.05, 0.0, 0.25, 4), Vector3(0, 1.6, -0.24), _bronze2()).rotation.x = -PI * 0.5
	for s in [-1.0, 1.0]:
		_part(vis, _sph(0.035), Vector3(s * 0.06, 1.66, -0.16), m_eye)
		_part(vis, _cone(0.04, 0.03, 0.85, 5), Vector3(s * 0.12, 0.42, 0), m_cloth)
		for k in 3:
			var f := _part(vis, _sph(0.28), Vector3(s * (0.3 + float(k) * 0.12), 1.15 - float(k) * 0.08, 0.1), m_cloth, Vector3(0.5, 0.12, 0.25))
			f.rotation.z = s * (0.4 + float(k) * 0.25)
	arm_l = Node3D.new()
	arm_r = Node3D.new()
	vis.add_child(arm_l)
	vis.add_child(arm_r)


func _build_counterweight() -> void:
	# KARŞI AĞIRLIK GOLEMİ: göğsünde terazi kefesi olan bronz dev; aldığı hasarı biriktirip patlatır
	var br := _bronze2()
	var jade := _jade()
	_part(vis, _sph(0.6, 0.9), Vector3(0, 1.35, 0), br, Vector3(1.2, 1.0, 0.9))
	_part(vis, _sph(0.3), Vector3(0, 1.4, -0.45), jade, Vector3(1.2, 0.5, 0.5))
	_part(vis, _sph(0.26), Vector3(0, 2.15, -0.05), br)
	for s in [-1.0, 1.0]:
		_part(vis, _sph(0.055), Vector3(s * 0.09, 2.18, -0.28), m_eye)
		_part(vis, _cone(0.16, 0.2, 0.9, 6), Vector3(s * 0.3, 0.45, 0), br)
	arm_l = _arm(-1.0, Vector3(-0.75, 1.75, 0), 0.9)
	arm_r = _arm(1.0, Vector3(0.75, 1.75, 0), 0.9)
	for a in [arm_l, arm_r]:
		_part(a, _sph(0.3), Vector3(0, -1.0, 0), br, Vector3(1.0, 0.6, 1.0))


# ---- Zehir Mağaraları görünüşleri (obsidyen kara kabuk, asit yeşili parıltı; zemin mavi-gri bazalt)

func _chitin() -> StandardMaterial3D:
	var m := _m(Color(0.12, 0.1, 0.16), 0.25)
	m.metallic = 0.3
	m.emission_enabled = true
	m.emission = Color(0.4, 1.0, 0.3)
	m.emission_energy_multiplier = 0.12
	return m


func _venom() -> StandardMaterial3D:
	var m := _m(Color(0.5, 1.0, 0.3), 0.3)
	m.emission_enabled = true
	m.emission = Color(0.5, 1.0, 0.3)
	m.emission_energy_multiplier = 1.6
	return m


func _scorp_tail(parent: Node3D, base: Vector3, sc: float) -> void:
	var ch := _chitin()
	for k in 5:
		var a := float(k) * 0.42
		_part(parent, _sph(0.12 * sc * (1.0 - float(k) * 0.1)), base + Vector3(0, sin(a) * 0.55 * sc + float(k) * 0.12 * sc, cos(a) * 0.3 * sc + float(k) * 0.1 * sc), ch)
	_part(parent, _cone(0.08 * sc, 0.0, 0.3 * sc, 5), base + Vector3(0, 1.0 * sc, -0.05 * sc), _venom()).rotation.x = PI * 0.75


func _build_stinger() -> void:
	# ZEHİRLİ İĞNE: küçük, hızlı akrep; iğnesi zehirler
	var ch := _chitin()
	_part(vis, _sph(0.35, 0.5), Vector3(0, 0.45, 0), ch, Vector3(0.9, 0.5, 1.3))
	_scorp_tail(vis, Vector3(0, 0.55, 0.4), 0.9)
	_crab_legs(vis, 3, 0.35, 0.3, 0.5)
	for s in [-1.0, 1.0]:
		_part(vis, _sph(0.04), Vector3(s * 0.1, 0.6, -0.42), m_eye)
	arm_l = _arm(-1.0, Vector3(-0.3, 0.55, -0.35), 0.45)
	arm_r = _arm(1.0, Vector3(0.3, 0.55, -0.35), 0.45)
	for a in [arm_l, arm_r]:
		_part(a, _sph(0.12), Vector3(0, -0.5, -0.05), ch, Vector3(0.8, 0.6, 1.4))


func _build_spitter() -> void:
	# ASİT TÜKÜRÜCÜ: kabuklu, şişkin asit keseli rahip-böcek
	var ch := _chitin()
	_part(vis, _cone(0.45, 0.18, 1.4, 10), Vector3(0, 0.85, 0), ch)
	_part(vis, _sph(0.32), Vector3(0, 1.6, 0.15), _venom(), Vector3(1.0, 0.9, 1.0))
	_part(vis, _sph(0.18), Vector3(0, 1.85, -0.15), ch)
	for s in [-1.0, 1.0]:
		_part(vis, _sph(0.04), Vector3(s * 0.07, 1.88, -0.32), m_eye)
	arm_l = _arm(-1.0, Vector3(-0.3, 1.6, 0), 0.55)
	arm_r = _arm(1.0, Vector3(0.3, 1.6, 0), 0.55)


func _build_mimic() -> void:
	# ÖLÜ TAKLİTÇİ: uzun bacaklı kara akrep; canı azalınca ölü taklidi yapar
	var ch := _chitin()
	_part(vis, _sph(0.4, 0.6), Vector3(0, 0.7, 0), ch, Vector3(0.9, 0.55, 1.5))
	_scorp_tail(vis, Vector3(0, 0.8, 0.5), 1.1)
	_crab_legs(vis, 4, 0.4, 0.5, 0.75)
	for s in [-1.0, 1.0]:
		_part(vis, _sph(0.05), Vector3(s * 0.12, 0.85, -0.55), m_eye)
	arm_l = Node3D.new()
	arm_r = Node3D.new()
	vis.add_child(arm_l)
	vis.add_child(arm_r)


func _build_grabber() -> void:
	# KISKAÇLI TİTAN: dev kıskaçlarıyla yakalar, zehirli iğnesiyle sokar
	var ch := _chitin()
	_part(vis, _sph(0.7, 1.0), Vector3(0, 1.1, 0), ch, Vector3(1.2, 0.8, 1.4))
	_scorp_tail(vis, Vector3(0, 1.3, 0.8), 1.6)
	_crab_legs(vis, 3, 0.7, 0.6, 1.0)
	for s in [-1.0, 1.0]:
		_part(vis, _sph(0.07), Vector3(s * 0.2, 1.45, -0.8), m_eye)
	arm_l = _arm(-1.0, Vector3(-0.85, 1.3, -0.5), 0.8)
	arm_r = _arm(1.0, Vector3(0.85, 1.3, -0.5), 0.8)
	for a in [arm_l, arm_r]:
		_part(a, _sph(0.3), Vector3(0, -0.9, -0.1), ch, Vector3(1.0, 0.7, 1.6))


# ---- Kentaur Bozkırı görünüşleri (mor-lacivert kentaurlar, altın oklar; zemin adaçayı yeşili taş)

func _centaur_mat() -> StandardMaterial3D:
	var m := _m(Color(0.42, 0.3, 0.72), 0.5)
	m.emission_enabled = true
	m.emission = Color(0.45, 0.3, 1.0)
	m.emission_energy_multiplier = 0.25
	return m


func _centaur(sc: float) -> void:
	# at gövdesi + insan üst gövde
	var cm := _centaur_mat()
	var gold := _m(Color(1.0, 0.82, 0.45), 0.3)
	_part(vis, _sph(0.42 * sc, 0.6 * sc), Vector3(0, 0.85 * sc, 0.15 * sc), cm, Vector3(0.8, 0.7, 1.5))
	for i in 4:
		var x := (-0.2 if i % 2 == 0 else 0.2) * sc
		var z := (-0.3 if i < 2 else 0.55) * sc
		_part(vis, _cone(0.06 * sc, 0.08 * sc, 0.75 * sc, 6), Vector3(x, 0.38 * sc, z), cm)
	_part(vis, _cone(0.22 * sc, 0.28 * sc, 0.7 * sc, 8), Vector3(0, 1.35 * sc, -0.35 * sc), cm)
	var hp := Vector3(0, 1.85 * sc, -0.38 * sc)
	_part(vis, _sph(0.15 * sc), hp, _m(Color(0.85, 0.8, 0.95)))
	_part(vis, _sph(0.035 * sc), hp + Vector3(-0.05, 0.0, -0.13) * sc, m_eye, Vector3(1.4, 0.7, 1.0))
	_part(vis, _sph(0.035 * sc), hp + Vector3(0.05, 0.0, -0.13) * sc, m_eye, Vector3(1.4, 0.7, 1.0))
	var tail := _part(vis, _cone(0.08 * sc, 0.02 * sc, 0.6 * sc, 5), Vector3(0, 0.95 * sc, 0.85 * sc), gold)
	tail.rotation.x = 0.8
	arm_l = _arm(-1.0, Vector3(-0.27, 1.6, -0.38) * sc, 0.5 * sc)
	arm_r = _arm(1.0, Vector3(0.27, 1.6, -0.38) * sc, 0.5 * sc)


func _build_lancer() -> void:
	# KENTAUR MIZRAKÇISI: vurur ve geri çekilir
	_centaur(1.0)
	_part(arm_r, _cone(0.03, 0.0, 1.6, 5), Vector3(0, -0.5, -0.6), _m(Color(1.0, 0.82, 0.45), 0.3)).rotation.x = -1.2


func _build_archer() -> void:
	# OKÇU: yay taşıyan kentaur; ok yağmuru
	_centaur(1.0)
	var bow := TorusMesh.new()
	bow.inner_radius = 0.42
	bow.outer_radius = 0.47
	var b := _part(arm_l, bow, Vector3(0, -0.5, -0.1), _m(Color(1.0, 0.82, 0.45), 0.3), Vector3(1.0, 1.0, 0.25))
	b.rotation.y = PI * 0.5


func _build_hawk() -> void:
	# AVCI ŞAHİN: gökten dalan mor-altın yırtıcı
	var cm := _centaur_mat()
	var gold := _m(Color(1.0, 0.82, 0.45), 0.3)
	_part(vis, _sph(0.25, 0.5), Vector3(0, 0, 0), cm, Vector3(0.9, 0.8, 1.4))
	_part(vis, _sph(0.15), Vector3(0, 0.12, -0.35), cm)
	_part(vis, _cone(0.05, 0.0, 0.18, 4), Vector3(0, 0.08, -0.52), gold).rotation.x = -PI * 0.5
	for s in [-1.0, 1.0]:
		_part(vis, _sph(0.035), Vector3(s * 0.07, 0.16, -0.45), m_eye)
		var w := _part(vis, _sph(0.6), Vector3(s * 0.6, 0.05, 0.05), cm, Vector3(1.0, 0.08, 0.42))
		w.rotation.z = s * 0.15
	arm_l = Node3D.new()
	arm_r = Node3D.new()
	vis.add_child(arm_l)
	vis.add_child(arm_r)


func _build_siege() -> void:
	# KUŞATMA KENTAURU: sırtında balista taşıyan dev
	_centaur(1.45)
	var wood := _m(Color(0.35, 0.28, 0.45), 0.7)
	var gold := _m(Color(1.0, 0.82, 0.45), 0.3)
	_part(vis, BoxMesh.new(), Vector3(0, 1.85, 0.2), wood, Vector3(0.3, 0.25, 1.4))
	var bar := _part(vis, BoxMesh.new(), Vector3(0, 1.95, -0.3), gold, Vector3(1.4, 0.08, 0.08))
	bar.rotation.y = 0.0


func _build_shellguard() -> void:
	# KABUK ASKERİ: dik duran mercan zırhlı yengeç-asker; vurulunca kabuğuna çekilir
	var shell := _shell_mat()
	_part(vis, _sph(0.5, 0.7), Vector3(0, 0.75, 0.05), shell, Vector3(1.2, 0.85, 1.0))
	for k in 4:
		_part(vis, _sph(0.18), Vector3(0, 1.05 - float(k) * 0.12, 0.35 + float(k) * 0.06), shell, Vector3(1.6, 0.5, 0.8))
	_crab_legs(vis, 3, 0.45, 0.35, 0.6)
	for s in [-1.0, 1.0]:
		var stalk := _part(vis, _cone(0.03, 0.03, 0.35, 5), Vector3(s * 0.15, 1.2, -0.2), m_cloth)
		stalk.rotation.x = -0.2
		_part(vis, _sph(0.07), Vector3(s * 0.15, 1.4, -0.25), m_eye)
	arm_l = _arm(-1.0, Vector3(-0.5, 0.95, -0.15), 0.55)
	arm_r = _arm(1.0, Vector3(0.5, 0.95, -0.15), 0.55)
	for a in [arm_l, arm_r]:
		_part(a, _sph(0.17), Vector3(0, -0.6, -0.05), shell, Vector3(1.0, 0.7, 1.5))
		_part(a, _sph(0.12), Vector3(0.08, -0.68, -0.2), shell, Vector3(0.6, 0.5, 1.2))


func _build_tideoracle() -> void:
	# GELGİT KÂHİNİ: deniz kabuğu taçlı, inci süslü, mercan cüppeli kâhin
	var robe := _m(Color(0.9, 0.42, 0.38), 0.7)
	robe.emission_enabled = true
	robe.emission = Color(0.8, 0.25, 0.2)
	robe.emission_energy_multiplier = 0.2
	_part(vis, _cone(0.48, 0.14, 1.55, 12), Vector3(0, 0.95, 0), robe)
	_part(vis, _sph(0.22, 0.44), Vector3(0, 1.78, 0), robe)
	var hp := Vector3(0, 2.1, 0)
	_part(vis, _sph(0.17), hp, _m(Color(0.95, 0.85, 0.8)))
	_part(vis, _sph(0.035), hp + Vector3(-0.06, 0.0, -0.16), m_eye, Vector3(1.4, 0.7, 1.0))
	_part(vis, _sph(0.035), hp + Vector3(0.06, 0.0, -0.16), m_eye, Vector3(1.4, 0.7, 1.0))
	var pearl := _m(Color(0.95, 0.95, 1.0), 0.15)
	pearl.metallic = 0.4
	for k in 7:
		var a := -0.9 + float(k) * 0.3
		var sp := _part(vis, _cone(0.06, 0.0, 0.3 + (0.12 if k == 3 else 0.0), 5), hp + Vector3(sin(a) * 0.16, 0.2, cos(a) * 0.05), _shell_mat())
		sp.rotation.z = -a * 0.7
	arm_l = _arm(-1.0, Vector3(-0.3, 1.85, 0), 0.6)
	arm_r = _arm(1.0, Vector3(0.3, 1.85, 0), 0.6)
	_part(vis, _sph(0.16), Vector3(0, 1.6, -0.48), pearl)
	_part(vis, _sph(0.1), Vector3(0, 1.6, -0.48), m_eye)


func _build_jelly() -> void:
	# AY DENİZANASI: yarı saydam, içi parlayan çan; sarkan dokunaçlar
	var bell := StandardMaterial3D.new()
	bell.albedo_color = Color(1.0, 0.6, 0.75, 0.55)
	bell.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bell.emission_enabled = true
	bell.emission = Color(1.0, 0.45, 0.6)
	bell.emission_energy_multiplier = 0.8
	bell.roughness = 0.2
	_part(vis, _sph(0.55, 0.7), Vector3(0, 1.65, 0), bell, Vector3(1.0, 0.75, 1.0))
	_part(vis, _sph(0.2), Vector3(0, 1.6, 0), m_eye)
	for k in 8:
		var a := TAU * float(k) / 8.0
		var t := _part(vis, _cone(0.03, 0.01, 1.1, 4), Vector3(cos(a) * 0.32, 0.95, sin(a) * 0.32), bell)
		t.rotation = Vector3(sin(a) * 0.15, 0, -cos(a) * 0.15)
	arm_l = Node3D.new()
	arm_r = Node3D.new()
	vis.add_child(arm_l)
	vis.add_child(arm_r)


func _build_hermit() -> void:
	# DEV KEŞİŞ YENGECİ: sırtında sarmal deniz kabuğu, iki dev kıskaç; sırtı yumuşak
	var shell := _shell_mat()
	var conch := _m(Color(0.95, 0.88, 0.8), 0.6)
	_part(vis, _sph(0.6, 0.8), Vector3(0, 0.8, 0), m_body, Vector3(1.3, 0.8, 1.1))
	for k in 6:
		var r := 0.7 - float(k) * 0.1
		_part(vis, _sph(r), Vector3(0, 1.4 + float(k) * 0.22, 0.35 - float(k) * 0.05), conch if k % 2 == 0 else shell, Vector3(1.0, 0.75, 1.0))
	_crab_legs(vis, 3, 0.7, 0.45, 0.8)
	for s in [-1.0, 1.0]:
		_part(vis, _sph(0.08), Vector3(s * 0.2, 1.25, -0.6), m_eye)
	arm_l = _arm(-1.0, Vector3(-0.85, 1.1, -0.3), 0.7)
	arm_r = _arm(1.0, Vector3(0.85, 1.1, -0.3), 0.7)
	for a in [arm_l, arm_r]:
		_part(a, _sph(0.32), Vector3(0, -0.8, -0.1), shell, Vector3(1.0, 0.75, 1.5))
		_part(a, _sph(0.2), Vector3(0.12, -0.9, -0.45), shell, Vector3(0.6, 0.5, 1.3))


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
	if zone == "virgo" and kind == "brute":
		_tick_wicker(delta)
	if zone == "libra" and kind == "caster":
		_tick_keeper(delta)
	if _dodge_cd > 0.0:
		_dodge_cd -= delta
	if zone == "leo" and kind == "caster":
		_tick_crown_caster(delta)
	if crowned > 0.0:
		crowned -= delta
		if _crown_node != null:
			_crown_node.rotation.y += delta * 2.0
			if crowned <= 0.0:
				_crown_node.visible = false
	if _hide_crack > 0.0:
		_hide_crack -= delta
	if _reveal > 0.0:
		_reveal -= delta
	if (zone == "leo" and kind == "leaper") or affixes.has("phantom"):
		# serap: kovalarken görünmez, arada titreşir
		var hidden := state == "chase" and _reveal <= 0.0
		vis.visible = not hidden or fmod(_t, 0.9) < 0.1
		if hp_bar != null:
			hp_bar.visible = not hidden
	if _shell_win > 0.0:
		_shell_win -= delta
		if _shell_win <= 0.0:
			_shell_hits = 0
	if affixes.has("healer") and state != "spawn":
		_heal_t -= delta
		if _heal_t <= 0.0:
			_heal_t = 1.0
			var healed := false
			for o in get_tree().get_nodes_in_group("enemies"):
				if o == self or o.dead or o.get("max_hp") == null or o.get("phase") != null:
					continue
				if o.global_position.distance_to(global_position) < 5.5 and float(o.hp) < float(o.max_hp):
					o.hp = minf(float(o.hp) + float(o.max_hp) * 0.04, float(o.max_hp))
					healed = true
			if healed:
				var hr := SlashFx.make(0.0, TAU, 0.3, 5.5, Color(0.4, 1.0, 0.55), 0.35)
				get_parent().add_child(hr)
				hr.global_transform = Transform3D(Basis.IDENTITY, global_position + Vector3(0, 0.2, 0))
	if ward > 0.0 and not affixes.has("shielded"):
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
				if zone == "cancer" and kind == "leaper" and dist < 6.0 and hero.has_method("apply_pull"):
					hero.apply_pull(global_position, 1.8, 0.05)
				if zone == "gemini" and kind == "caster":
					_blink_cd -= delta
					if dist < 3.5 and _blink_cd <= 0.0:
						_herald_blink()
				if _global_cd <= 0.0:
					_pick_attack(dist, dir_to)
		"windup":
			var track := 0.6 if bool(atk["parry"]) else 0.9
			if String(atk["shape"]) == "line":
				track = 0.85
			if hero_ok and _st < _wl() * track:
				_aim_dir = _aim_dir.slerp(dir_to, minf(7.0 * delta, 1.0)).normalized()
				_aim_point = hero.global_position
			_face = _aim_dir
			_place_tele()
			var k := _st / _wl()
			var pulse := 0.0 if bool(atk["parry"]) else 0.25 * (0.5 + 0.5 * sin(_t * 28.0))
			tele_mat.albedo_color.a = 0.15 + 0.55 * k + pulse
			if _st >= _wl():
				_set_state("act")
		"act":
			want = _do_act(delta)
			if _st >= float(atk["act"]):
				if not _done:
					_resolve()
				_end_act()
		"recover":
			if _st >= float(atk["recover"]):
				_set_state("chase")
		"stun":
			if _st >= _stun_len:
				_set_state("chase")
		"feign":
			# ÖLÜ TAKLİTÇİ: 2 sn yerde yatar; ölmezse canlanıp hemen saldırır
			if _st >= 2.0:
				hp = minf(hp + max_hp * 0.35, max_hp)
				Sfx.play("enemyattack", -4.0, 0.0, 0, 0.8)
				_set_state("chase")
				_global_cd = 0.0
		"shell":
			# Kabuk Askeri kabukta: büyüyen kızıl halka, sonra etrafına kıskaç
			var k := clampf(_st / 1.2, 0.0, 1.0)
			tele.visible = true
			tele.mesh = _fan_mesh(TAU, 2.4)
			tele_mat.albedo_color = Color(DANGER_COL.r, DANGER_COL.g, DANGER_COL.b, 0.2 + 0.6 * k)
			tele.global_transform = Transform3D(Basis.IDENTITY, Vector3(global_position.x, 0.06, global_position.z))
			if _st >= 1.2:
				tele.visible = false
				_shell_snap()
				_set_state("chase")
				_global_cd = 0.8

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


## Şu anki saldırının hazırlık süresi (serinin devam turlarında kısalır)
func _wl() -> float:
	return float(atk["windup"]) * _wscale


## Saldırı anı bitti: seri devam ediyorsa yeniden nişan alıp hemen tekrar saldırır
func _end_act() -> void:
	if state != "act":
		return
	var hero_ok: bool = hero != null and is_instance_valid(hero) and not hero.dead
	if _chain_left > 0 and hero_ok:
		_chain_left -= 1
		_wscale = 0.55
		var to: Vector3 = hero.global_position - global_position
		to.y = 0.0
		if to.length() > 0.1:
			_aim_dir = to.normalized()
		_aim_point = hero.global_position
		_set_state("windup")
		return
	_wscale = 1.0
	_set_state("recover")


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
	_wscale = 1.0
	_chain_left = int(atk.get("chain", 1)) - 1
	if elite and _chain_left > 0 and String(atk["shape"]) == "fan":
		_chain_left += 1
	_set_state("windup")


func _set_state(s: String) -> void:
	state = s
	_st = 0.0
	if s == "recover" and zone == "sagittarius" and kind == "shade":
		# vur-kaç: saldırıdan sonra geri sıçrar
		_knock = -_face * 11.0
	if s == "windup":
		_show_tele()
		if String(atk["name"]) == "burrow" or String(atk["name"]) == "mirror":
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
		elif String(atk["name"]) == "volley":
			var H = load("res://scripts/hazards.gd")
			if hero != null and is_instance_valid(hero):
				for i in 5:
					var b = H.Blast.new()
					b.hero = hero
					b.radius = 1.2
					b.delay = 0.9 + float(i) * 0.1
					b.dmg = float(atk["dmg"])
					b.col = Color(1.0, 0.82, 0.45)
					get_parent().add_child(b)
					var off := Vector3.ZERO if i == 0 else Vector3(randf_range(-2.2, 2.2), 0, randf_range(-2.2, 2.2))
					b.global_position = H.clamp_arena(hero.global_position + off, 12.0)
			Sfx.play("bowshot", -6.0, 0.1, 0, 0.9)
			_done = true
		elif String(atk["name"]) == "ballista":
			var H2 = load("res://scripts/hazards.gd")
			var ln = H2.Line.new()
			ln.hero = hero
			ln.dir = _aim_dir
			ln.length = 15.0
			ln.width = 1.5
			ln.delay = 0.35
			ln.dmg = float(atk["dmg"])
			ln.col = Color(1.0, 0.82, 0.45)
			ln.eff = "knock"
			get_parent().add_child(ln)
			ln.global_position = Vector3(global_position.x, 0, global_position.z) + _aim_dir * 0.8
			Sfx.play("bowshot", -2.0, 0.0, 0, 0.6)
			_done = true
		elif String(atk["name"]) == "acid":
			var H = load("res://scripts/hazards.gd")
			if hero != null and is_instance_valid(hero):
				var b = H.Blast.new()
				b.hero = hero
				b.radius = 1.8
				b.delay = 0.9
				b.dmg = float(atk["dmg"])
				b.col = Color(0.5, 1.0, 0.3)
				b.eff = "poison"
				b.pool_life = 4.0
				get_parent().add_child(b)
				b.global_position = H.clamp_arena(hero.global_position, 12.0)
			Sfx.play("parry", -12.0, 0.05, 0, 0.9)
			_done = true
		elif String(atk["name"]) == "verdict":
			# hüküm: önce bulunduğun yere, sonra gideceğin yere
			var H = load("res://scripts/hazards.gd")
			if hero != null and is_instance_valid(hero):
				for i in 2:
					var b = H.Blast.new()
					b.hero = hero
					b.radius = 1.6
					b.delay = 0.8 + float(i) * 0.45
					b.dmg = float(atk["dmg"])
					b.col = Color(0.4, 1.0, 0.8)
					get_parent().add_child(b)
					var p: Vector3 = hero.global_position + (hero.velocity * 0.6 if i == 1 else Vector3.ZERO)
					b.global_position = H.clamp_arena(p, 12.0)
			Sfx.play("parry", -10.0, 0.05, 0, 1.4)
			_done = true
		elif String(atk["name"]) == "seals":
			# üç mühür: kahramana doğru sırayla
			var H = load("res://scripts/hazards.gd")
			var tgt: Vector3 = hero.global_position if hero != null and is_instance_valid(hero) else global_position + _aim_dir * 5.0
			for i in 3:
				var b = H.Blast.new()
				b.hero = hero
				b.radius = 1.5
				b.delay = 0.7 + float(i) * 0.35
				b.dmg = float(atk["dmg"])
				b.col = Color(0.4, 1.0, 0.85)
				get_parent().add_child(b)
				var p := global_position.lerp(tgt, (float(i) + 1.0) / 3.0) + _aim_dir * float(i) * 0.6
				b.global_position = H.clamp_arena(p, 12.0)
			Sfx.play("parry", -10.0, 0.05, 0, 1.6)
			_done = true
		elif String(atk["name"]) == "sunbeam":
			var sb := SunBeam.new()
			sb.hero = hero
			sb.dir = _aim_dir
			sb.dmg = float(atk["dmg"]) * _buff()
			get_parent().add_child(sb)
			sb.global_position = Vector3(global_position.x, 0.0, global_position.z) + _aim_dir * 0.6
			_done = true
		elif String(atk["name"]) == "tidewave":
			var tw := TideWave.new()
			tw.hero = hero
			tw.dir = _aim_dir
			tw.dmg = float(atk["dmg"])
			get_parent().add_child(tw)
			tw.global_position = Vector3(global_position.x, 0.0, global_position.z) + _aim_dir * 1.0
			_done = true
		elif String(atk["name"]) == "bubbles":
			for i in 5:
				var bb := Bubble.new()
				bb.hero = hero
				bb.dmg = float(atk["dmg"])
				bb.vel = _aim_dir.rotated(Vector3.UP, (float(i) - 2.0) * 0.45) * 4.0
				get_parent().add_child(bb)
				bb.global_position = global_position + Vector3(0, 1.3, 0) + _aim_dir * 0.8
			Sfx.play("parry", -10.0, 0.05, 0, 2.2)
			_done = true
		elif String(atk["name"]) == "windblade":
			var wb := WindBlade.new()
			wb.owner_node = self
			wb.dir = _aim_dir
			wb.dmg = float(atk["dmg"])
			wb.hero = hero
			wb.out_dist = float(atk["reach"])
			get_parent().add_child(wb)
			wb.global_position = global_position + Vector3(0, 1.3, 0) + _aim_dir * 0.6
			Sfx.play("swing", -6.0, 0.08, 0, 1.4)
			_done = true
		elif String(atk["name"]) == "mirror":
			Sfx.play("parry", -8.0, 0.05, 0, 2.0)
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
	return state == "act" and String(atk.get("name", "")) == "burrow" and absf(_sink) > 0.8


## gömülme derinliği (Fırtına Kuşu için negatif: havaya yükselir)
func _bd() -> float:
	return -4.0 if _sky else 1.7


## TOPRAK KÖSTEBEĞİ: gömül -> altından ilerle -> yerde halka -> fırla
func _burrow(delta: float) -> Vector3:
	var st := _st
	if st < 0.4:
		_sink = lerpf(0.0, _bd(), st / 0.4)
		_dirt(global_position, 3)
		return Vector3.ZERO
	if st < 1.6:
		_sink = _bd()
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
	var m: StandardMaterial3D = Fx.mat(Color(0.85, 0.9, 1.0) if _sky else Color(0.35, 0.25, 0.15), 0.0, 0.95)
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
		if not _charge_hit and _chain_left <= 0:
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
	if nm == "ramcharge" or nm == "fireball" or nm == "burrow" or nm == "fissure" or nm == "windblade" or nm == "mirror" or nm == "tidewave" or nm == "bubbles" or nm == "sunbeam" or nm == "seals" or nm == "verdict" or nm == "acid" or nm == "volley" or nm == "ballista":
		return
	var reach := float(atk["reach"])
	var col: Color = PARRY_COL if bool(atk["parry"]) else DANGER_COL
	var center := global_position
	if nm == "pounce":
		center = Vector3(_aim_point.x, 0, _aim_point.z)
		global_position = center
		tele.visible = false
		if zone == "virgo":
			# TOHUM EKİCİ: indiği yere yavaşlatan tohumlar saçar
			var H = load("res://scripts/hazards.gd")
			var a0 := randf() * TAU
			for i in 3:
				var sd = H.Blast.new()
				sd.hero = hero
				sd.radius = 1.3
				sd.delay = 1.3
				sd.dmg = float(atk["dmg"]) * 0.5
				sd.col = Color(0.5, 1.0, 0.6)
				sd.eff = "slow"
				get_parent().add_child(sd)
				var ang := a0 + TAU * float(i) / 3.0
				sd.global_position = H.clamp_arena(center + Vector3(cos(ang), 0, sin(ang)) * 2.2, 12.0)
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
	var res: String = hero.take_damage(float(atk["dmg"]) * _buff(), dir, bool(atk["parry"]))
	if res == "parried":
		stun(2.0 if kind == "brute" else 1.5, true)
		_knock = -_aim_dir * 7.0
		if zone == "leo" and kind == "brute":
			_hide_crack = 6.0
			HitFx.impact(get_parent(), global_position + Vector3(0, 1.8, 0), -dir, Color(1.0, 0.85, 0.5), true)
			Sfx.play("crush", -2.0, 0.0, 0, 1.3)
	elif res == "hit" and String(atk["name"]) == "roar" and hero.has_method("apply_slow"):
		hero.apply_slow(0.45, 1.8)
	if res == "hit" and zone == "scorpio":
		if kind == "shade" and hero.has_method("apply_poison"):
			hero.apply_poison(4.0 * dmg_mult, 3.0)
		elif nm == "grab":
			hero.apply_slow(0.05, 1.1)
			hero.apply_poison(5.0 * dmg_mult, 3.0)


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
	_chain_left = 0
	_wscale = 1.0
	_stun_len = sec
	_parried = parried
	if state == "act" and String(atk.get("name", "")) == "pounce":
		global_position.y = 0.0
	_set_state("stun")


const AFFIX_NAMES := {"shielded": "SHIELDED", "swift": "SWIFT", "splitting": "SPLITTING", "healer": "HEALER", "volatile": "VOLATILE", "phantom": "PHANTOM"}
const AFFIX_COLS := {"shielded": Color(0.5, 1.0, 0.8), "swift": Color(0.6, 0.85, 1.0), "splitting": Color(0.9, 0.7, 1.0), "healer": Color(0.45, 1.0, 0.5), "volatile": Color(1.0, 0.5, 0.3), "phantom": Color(0.8, 0.8, 0.95)}


## Seçkin özellikleri başının üstünde yazar
func _affix_label() -> void:
	var lb := Label3D.new()
	var parts: Array = []
	for a in affixes:
		parts.append(tr(String(AFFIX_NAMES.get(a, a))))
	lb.text = " · ".join(parts)
	lb.font_size = 44
	lb.pixel_size = 0.005
	lb.outline_size = 10
	lb.modulate = AFFIX_COLS.get(affixes[0], Color.WHITE)
	lb.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lb.no_depth_test = true
	lb.position = Vector3(0, 2.75 * size_k + (0.5 if kind == "caster" else 0.0), 0)
	add_child(lb)


## Kabuk Askeri: kabuktan çıkarken etrafına kıskaç vurur
func _shell_snap() -> void:
	var ring := SlashFx.make(0.0, TAU, 0.3, 2.4, DANGER_COL, 0.3)
	get_parent().add_child(ring)
	ring.global_transform = Transform3D(Basis.IDENTITY, global_position + Vector3(0, 0.5, 0))
	Sfx.play("crush", -5.0, 0.05, 0, 1.2)
	Fx.shake(0.25)
	if hero != null and is_instance_valid(hero) and not hero.dead:
		var v: Vector3 = hero.global_position - global_position
		v.y = 0.0
		if v.length() <= 2.4 + 0.3:
			hero.take_damage(18.0 * dmg_mult, v.normalized() if v.length() > 0.05 else _face, false)


## Merkür Habercisi: kahramandan uzağa ışınlanır
func _herald_blink() -> void:
	_blink_cd = 5.0
	var hp_pos: Vector3 = hero.global_position
	var best := global_position
	for i in 8:
		var a := randf() * TAU
		var p := hp_pos + Vector3(cos(a), 0, sin(a)) * randf_range(6.5, 8.5)
		if Vector2(p.x, p.z).length() < _bounds - 0.5:
			best = p
			break
	var ring := SlashFx.make(0.0, TAU, 0.2, 1.4, Color(0.7, 0.9, 1.0), 0.3)
	get_parent().add_child(ring)
	ring.global_transform = Transform3D(Basis.IDENTITY, global_position + Vector3(0, 0.5, 0))
	global_position = Vector3(best.x, 0.0, best.z)
	Fx.flash_light(global_position + Vector3(0, 1.5, 0), Color(0.7, 0.9, 1.0), 4.0, 4.0, 0.25)
	Sfx.play("dash", -8.0, 0.05, 0, 1.8)


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
	# ELEMENT üstünlüğü
	var elm: float = Elements.mult(GameData.hero_el, GameData.hero_el_n, String(Elements.ZONE_EL.get(zone, "")))
	dmg *= elm
	if elm > 1.0:
		crit = true
	if _burrowed():
		return
	if state == "feign":
		dmg *= 1.5    # yerde yatarken bitirmek kolay
	# TÜY DANSÇISI: arada bir ilk vuruştan kaçar
	if zone == "libra" and kind == "leaper" and _dodge_cd <= 0.0 and state != "stun":
		_dodge_cd = 4.0
		var side := Vector3(-dir.z, 0, dir.x) * (1.0 if randf() < 0.5 else -1.0)
		_knock = side * 9.0
		HitFx.number(get_parent(), global_position + Vector3(0, 2.0, 0), 0.0, false)
		Sfx.play("dash", -10.0, 0.05, 0, 1.8)
		return
	# HAKEM: hasar eşiyle bölünür
	if zone == "libra" and kind == "shade" and not _sharing and partner != null and is_instance_valid(partner) and not partner.dead:
		dmg *= 0.5
		partner._sharing = true
		partner.take_hit(dmg, dir, 0.0, false, false)
		partner._sharing = false
	# KARŞI AĞIRLIK: hasarı biriktirir
	if zone == "libra" and kind == "brute" and not dead:
		_stored += dmg
		if _stored >= max_hp * 0.25:
			_stored = 0.0
			var H2 = load("res://scripts/hazards.gd")
			var bw = H2.Blast.new()
			bw.hero = hero
			bw.radius = 4.0
			bw.delay = 0.7
			bw.dmg = 22.0 * dmg_mult
			bw.col = Color(1.0, 0.7, 0.4)
			bw.eff = "knock"
			get_parent().add_child(bw)
			bw.global_position = Vector3(global_position.x, 0.0, global_position.z)
	if zone == "virgo" and kind == "brute":
		_calm = 0.0
		m_body.emission_energy_multiplier = 0.3
	# NEMEA ASLANI: postu hasarın çoğunu emer (parry ile çatlat)
	if zone == "leo" and kind == "brute" and _hide_crack <= 0.0 and state != "stun":
		dmg *= 0.3
		HitFx.impact(get_parent(), global_position + Vector3(0, 1.5, 0) - dir * 0.8, -dir, Color(1.0, 0.85, 0.5), false)
	elif zone == "leo" and kind == "brute":
		crit = true
	if (zone == "leo" and kind == "leaper") or affixes.has("phantom"):
		_reveal = 1.6
	# KABUK ASKERİ: kabuktayken dokunulmaz; kısa sürede 3 vuruş alırsa kabuğuna çekilir
	if zone == "cancer" and kind == "shade":
		if state == "shell":
			HitFx.impact(get_parent(), global_position + Vector3(0, 0.9, 0) - dir * 0.6, -dir, Color(1.0, 0.7, 0.6), false)
			Sfx.play("parry", -10.0, 0.05, 40, 1.7)
			return
		_shell_win = 1.3
		_shell_hits += 1
		if _shell_hits >= 3 and state != "stun":
			_shell_hits = 0
			_chain_left = 0
			state = "shell"
			_st = 0.0
			Sfx.play("crush", -8.0, 0.05, 0, 1.6)
	# KEŞİŞ YENGECİ: sırtı yumuşak, arkadan gelen vuruş iki kat
	if zone == "cancer" and kind == "brute" and _face.dot(dir) > 0.35:
		dmg *= 2.0
		crit = true
	# AYNA MUHAFIZI: ayna duruşunda hafif vuruşlar sana yansır; ağır vuruş aynayı kırar
	if zone == "gemini" and kind == "brute" and (state == "act" or state == "windup") and String(atk.get("name", "")) == "mirror":
		if heavy:
			Sfx.play("crush", -4.0, 0.05, 0, 1.4)
			Fx.flash_light(global_position + Vector3(0, 1.5, 0), Color(0.7, 0.9, 1.0), 6.0, 5.0, 0.3)
			stun(1.4)
		else:
			HitFx.impact(get_parent(), global_position + Vector3(0, 1.4, 0) - dir * 0.9, -dir, Color(0.75, 0.9, 1.0), true)
			Sfx.play("parry", -6.0, 0.05, 40, 1.8)
			if hero != null and is_instance_valid(hero) and not hero.dead:
				hero.take_damage(dmg * 0.5, -dir, false)
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
	# ÖLÜ TAKLİTÇİ: ölümcül vuruş yerine ölü taklidi (bir kez)
	if zone == "scorpio" and kind == "leaper" and not _feigned and hp > 0.0 and hp < max_hp * 0.3:
		_feigned = true
		_chain_left = 0
		tele.visible = false
		state = "feign"
		_st = 0.0
		Sfx.play("enemydie", -10.0, 0.0, 0, 1.3)
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
	if zone == "gemini" and kind == "shade" and partner != null and is_instance_valid(partner) and not partner.dead:
		partner.lost_twin()
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
	var hover := sin(_t * 2.2) * 0.08 + (0.35 if kind == "caster" else 0.0) + (0.5 if _sky else 0.0) + (0.4 if zone == "cancer" and kind == "leaper" else 0.0)
	var lean := 0.0          # öne (+) / arkaya (-) eğilme
	var arm_lx := 0.25       # kol öne kalkma (+) / geriye (-)
	var arm_rx := 0.25
	var arm_lz := 0.0        # kol yana açılma
	var arm_rz := 0.0
	var twist := 0.0         # gövde burulması
	var py := 0.0            # zıplama / çömelme
	var shake := 0.0         # titreme (hazırlanırken)
	var glow := 3.0
	var claw_glow := 0.3
	var tint := Color(0, 0, 0, 0)   # hazırlık rengi (altın: parry, kızıl: kaç)
	var nm := String(atk.get("name", ""))
	match state:
		"windup":
			var k := clampf(_st / maxf(_wl(), 0.01), 0.0, 1.0)
			var e := k * k * (3.0 - 2.0 * k)
			tint = PARRY_COL if bool(atk["parry"]) else DANGER_COL
			glow = 3.0 + 12.0 * k
			claw_glow = 0.5 + 6.0 * k
			match nm:
				"claw":
					# PENÇE: sağ kolu arkaya-yukarı çeker, gövdesini yana burar
					arm_rx = 2.7 * e
					arm_lx = 0.6 * e
					twist = 0.55 * e
					lean = -0.12 * e
					if kind == "leaper":
						lean = -0.3 * e
						py = -0.12 * e
				"rend":
					# GENİŞ SAVURMA: iki kolunu iki yana açar, geriye yaslanır
					arm_lz = -1.5 * e
					arm_rz = 1.5 * e
					arm_lx = 0.8 * e
					arm_rx = 0.8 * e
					lean = -0.3 * e
					py = -0.08 * e
				"smash":
					# EZME: iki yumruğu başının üstüne kaldırır, parmak ucuna yükselir
					arm_lx = 2.9 * e
					arm_rx = 2.9 * e
					lean = -0.35 * e
					py = 0.15 * e
				"quake", "fissure":
					# YERE VURMA: kollar havada, sıçrar; titreyerek güç toplar
					arm_lx = 3.1 * e
					arm_rx = 3.1 * e
					arm_lz = -0.4 * e
					arm_rz = 0.4 * e
					lean = -0.25 * e
					py = 0.55 * e
					shake = 0.03 * k
				"pounce":
					# ATILMA: yere yapışacak kadar çömelir, titrer
					lean = -0.4 * e
					py = -0.3 * e
					shake = 0.05 * k
				"ramcharge":
					# KOÇ TOSU: başını eğer, toynağıyla yeri eşeler (öne-arkaya sallanır)
					lean = 0.5 * e
					py = -0.1 * e
					shake = 0.0
					vis.position.z = sin(_t * 20.0) * 0.12 * k
				"burrow":
					# GÖMÜLME: kendi etrafında döner
					twist = _t * 18.0 * k
				"reap":
					# ORAK: kolunu geriye çeker, döner
					arm_rx = -1.2 * e
					lean = -0.2 * e
					glow = 3.0 + 20.0 * k
					shake = 0.03 * k
				"volley", "ballista":
					arm_lx = 2.2 * e
					arm_rx = 1.6 * e
					lean = -0.2 * e
					glow = 3.0 + 18.0 * k
				"acid":
					arm_lx = 2.4 * e
					arm_rx = 2.4 * e
					glow = 3.0 + 18.0 * k
				"grab":
					arm_lz = 1.0 * e
					arm_rz = -1.0 * e
					lean = 0.2 * e
					glow = 3.0 + 18.0 * k
				"verdict":
					arm_lx = 2.4 * e
					arm_rx = 2.4 * e
					glow = 3.0 + 18.0 * k
				"seals":
					arm_lx = 2.4 * e
					arm_rx = 2.4 * e
					glow = 3.0 + 18.0 * k
				"roar":
					# KÜKREME: başını kaldırır, yelesi parlar
					lean = -0.35 * e
					py = 0.1 * e
					glow = 3.0 + 25.0 * k
					shake = 0.04 * k
				"sunbeam":
					arm_rx = 2.8 * e
					glow = 3.0 + 18.0 * k
				"pulse":
					# DENİZANASI: çanı kasılır, içi parlar
					py = 0.25 * e
					glow = 3.0 + 25.0 * k
					shake = 0.03 * k
				"tidewave", "bubbles":
					arm_lx = 2.6 * e
					arm_rx = 2.6 * e
					lean = -0.25 * e
					glow = 3.0 + 15.0 * k
				"mirror":
					# AYNA: aynayı önüne kaldırır, gümüş parlar
					arm_lx = 1.5 * e
					arm_rx = 1.2 * e
					lean = -0.1 * e
				"fireball", "bolt", "windblade":
					# BÜYÜ: kollarını göğe kaldırır, ışığı büyür, havaya yükselir
					arm_lx = 2.8 * e
					arm_rx = 2.8 * e
					arm_lz = -0.5 * e
					arm_rz = 0.5 * e
					lean = -0.2 * e
					py = 0.25 * e
					glow = 3.0 + 22.0 * k
				_:
					arm_lx = 0.25 + 1.6 * e
					arm_rx = arm_lx
					lean = 0.3 * e
		"act":
			glow = 10.0
			claw_glow = 5.0
			tint = PARRY_COL if bool(atk["parry"]) else DANGER_COL
			match nm:
				"claw":
					arm_rx = -0.9
					arm_lx = 0.2
					twist = -0.6
					lean = 0.35
				"rend":
					arm_lz = 0.4
					arm_rz = -0.4
					arm_lx = 1.3
					arm_rx = 1.3
					twist = -1.2
					lean = 0.3
				"smash", "quake", "fissure":
					arm_lx = -0.3
					arm_rx = -0.3
					lean = 0.55
					py = -0.12
				"ramcharge":
					lean = 0.55
				"mirror":
					arm_lx = 1.5
					arm_rx = 1.2
					glow = 18.0 + sin(_t * 20.0) * 4.0
				"fireball", "bolt", "windblade":
					arm_lx = 1.5
					arm_rx = 1.5
					lean = 0.25
				_:
					lean = -0.45 if kind != "leaper" else 0.3
					arm_lx = -1.2
					arm_rx = -1.2
		"recover":
			var r := 1.0 - _st / float(atk["recover"])
			lean = -0.2 * r
			arm_lx = -0.6 * r
			arm_rx = -0.6 * r
		"stun":
			lean = 0.25
			arm_lx = 0.0
			arm_rx = 0.0
			glow = 1.0
			hover += sin(_t * 18.0) * 0.03
		"feign":
			# ölü taklidi: ters döner, kıpırdamaz
			py = -0.25
			lean = 0.9
			glow = 0.2 + 6.0 * clampf((_st - 1.4) / 0.6, 0.0, 1.0)
		"shell":
			# kabuğuna çekilir: çömelir, kıskaçlar içeri
			py = -0.35
			arm_lx = -0.4
			arm_rx = -0.4
			arm_lz = 0.6
			arm_rz = -0.6
			glow = 2.0 + 10.0 * clampf(_st / 1.2, 0.0, 1.0)
			tint = DANGER_COL
			shake = 0.04 * clampf(_st / 1.2, 0.0, 1.0)
	_flinch = maxf(_flinch - delta * 5.0, 0.0)
	var sp := minf(18.0 * delta, 1.0)
	vis.rotation.x = lerpf(vis.rotation.x, lean - _flinch * 0.45, sp)
	_twist = lerpf(_twist, twist, sp) if nm != "burrow" or state != "windup" else twist
	vis.rotation.y = _twist
	if state != "spawn":
		vis.position.y = lerpf(vis.position.y, hover - _sink + py, minf(20.0 * delta, 1.0)) if absf(_sink) < 0.001 else hover - _sink
		vis.position.x = sin(_t * 55.0) * shake
		if not (state == "windup" and nm == "ramcharge"):
			vis.position.z = lerpf(vis.position.z, 0.0, sp)
	if state != "act" and _sink != 0.0:
		_sink = 0.0
	hp_bar.visible = absf(_sink) < 0.5
	if _mirror_node != null:
		_mirror_node.visible = (state == "act" or state == "windup") and nm == "mirror"
	if _sky:
		arm_lz += sin(_t * (14.0 if state == "act" else 7.0)) * 0.5
		arm_rz -= sin(_t * (14.0 if state == "act" else 7.0)) * 0.5
	if _halo != null:
		_halo.rotation.y += delta * 1.4
	arm_l.rotation.x = lerpf(arm_l.rotation.x, arm_lx, sp)
	arm_r.rotation.x = lerpf(arm_r.rotation.x, arm_rx, sp)
	arm_l.rotation.z = lerpf(arm_l.rotation.z, -0.25 + arm_lz, sp)
	arm_r.rotation.z = lerpf(arm_r.rotation.z, 0.25 + arm_rz, sp)
	# hazırlık rengi: pençeler ve gözler saldırının rengine bürünür
	if tint.a > 0.0:
		m_claw.emission = _claw_base.lerp(tint, 0.85)
		m_eye.emission = _eye_base.lerp(tint, 0.7)
	else:
		m_claw.emission = _claw_base
		m_eye.emission = _eye_base
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
		add_to_group("enemy_shot")
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
		add_to_group("enemy_shot")
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


# ---------------------------------------------------------------- Merkür Habercisi rüzgâr bıçağı (gider ve döner)

class WindBlade extends Node3D:
	var owner_node = null
	var hero = null
	var dir := Vector3.FORWARD
	var dmg := 12.0
	var out_dist := 9.0
	var speed := 13.0
	var _trav := 0.0
	var _back := false
	var _hit_out := false
	var _hit_back := false
	var _t := 0.0
	var _blade: MeshInstance3D

	func _ready() -> void:
		add_to_group("enemy_shot")
		top_level = true
		_blade = MeshInstance3D.new()
		var t := TorusMesh.new()
		t.inner_radius = 0.38
		t.outer_radius = 0.5
		t.rings = 24
		_blade.mesh = t
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		m.albedo_color = Color(0.7, 0.9, 1.0, 0.9)
		_blade.material_override = m
		_blade.scale = Vector3(1.0, 0.25, 1.0)
		add_child(_blade)

	func _physics_process(delta: float) -> void:
		_t += delta
		_blade.rotation.y += delta * 18.0
		if not _back:
			global_position += dir * speed * delta
			_trav += speed * delta
			if _trav >= out_dist:
				_back = true
		else:
			if owner_node == null or not is_instance_valid(owner_node) or owner_node.dead:
				queue_free()
				return
			var target: Vector3 = owner_node.global_position + Vector3(0, 1.3, 0)
			var d := target - global_position
			if d.length() < 0.6:
				queue_free()
				return
			global_position += d.normalized() * speed * 1.1 * delta
		if hero != null and is_instance_valid(hero) and not hero.dead:
			var v: Vector3 = hero.global_position + Vector3(0, 1.0, 0) - global_position
			if Vector2(v.x, v.z).length() < 0.7 and ((not _back and not _hit_out) or (_back and not _hit_back)):
				var res: String = hero.take_damage(dmg, dir if not _back else -dir, false)
				if res == "hit":
					if _back:
						_hit_back = true
					else:
						_hit_out = true
		if _t > 4.0:
			queue_free()


# ---------------------------------------------------------------- Gelgit Kâhini dalga duvarı

class TideWave extends Node3D:
	var hero = null
	var dir := Vector3.FORWARD
	var width := 3.6
	var speed := 7.5
	var travel := 15.0
	var dmg := 14.0
	var _d := 0.0
	var _hit := false
	var _mat: StandardMaterial3D
	var _wall: MeshInstance3D

	func _ready() -> void:
		top_level = true
		_wall = MeshInstance3D.new()
		var b := BoxMesh.new()
		b.size = Vector3(width, 1.2, 0.6)
		_wall.mesh = b
		_mat = StandardMaterial3D.new()
		_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_mat.albedo_color = Color(0.45, 0.85, 1.0, 0.55)
		_wall.material_override = _mat
		_wall.position.y = 0.6
		add_child(_wall)
		var foam := MeshInstance3D.new()
		var fb := BoxMesh.new()
		fb.size = Vector3(width, 0.15, 0.7)
		foam.mesh = fb
		var fm := StandardMaterial3D.new()
		fm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		fm.albedo_color = Color(0.95, 1.0, 1.0)
		foam.material_override = fm
		foam.position.y = 1.25
		add_child(foam)
		look_at(global_position + dir, Vector3.UP)
		Sfx.play("dash", -6.0, 0.05, 0, 0.5)

	func _physics_process(delta: float) -> void:
		var step := speed * delta
		global_position += dir * step
		_d += step
		_wall.scale.y = 0.7 + 0.3 * sin(_d * 2.0)
		if not _hit and hero != null and is_instance_valid(hero) and not hero.dead:
			var v: Vector3 = hero.global_position - global_position
			v.y = 0.0
			var side := Vector3(-dir.z, 0, dir.x)
			if absf(v.dot(dir)) < 0.7 and absf(v.dot(side)) < width * 0.5 + 0.3:
				var res: String = hero.take_damage(dmg, dir, false)
				if res == "hit":
					_hit = true
					if hero.has_method("apply_pull"):
						hero.apply_pull(hero.global_position + dir * 3.0, 11.0, 0.25)
		_mat.albedo_color.a = 0.55 * (1.0 - clampf((_d - travel + 2.0) / 2.0, 0.0, 1.0))
		if _d >= travel:
			queue_free()


# ---------------------------------------------------------------- Keşiş Yengeci kabarcığı

class Bubble extends Node3D:
	var hero = null
	var dmg := 10.0
	var speed := 2.6
	var life := 5.0
	var vel := Vector3.ZERO
	var _t := 0.0
	var _orb: MeshInstance3D

	func _ready() -> void:
		add_to_group("enemy_shot")
		top_level = true
		_orb = MeshInstance3D.new()
		var s := SphereMesh.new()
		s.radius = 0.42
		s.height = 0.84
		_orb.mesh = s
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(0.7, 0.95, 1.0, 0.4)
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.emission_enabled = true
		m.emission = Color(0.5, 0.9, 1.0)
		m.emission_energy_multiplier = 0.8
		m.roughness = 0.05
		m.rim_enabled = true
		_orb.material_override = m
		add_child(_orb)

	func _physics_process(delta: float) -> void:
		_t += delta
		if hero != null and is_instance_valid(hero) and not hero.dead:
			var to: Vector3 = hero.global_position + Vector3(0, 1.0, 0) - global_position
			vel = vel.lerp(to.normalized() * speed, minf(1.2 * delta, 1.0))
			if to.length() < 0.75:
				var res: String = hero.take_damage(dmg, to.normalized(), false)
				if res == "hit" and hero.has_method("apply_slow"):
					hero.apply_slow(0.5, 1.5)
				_pop()
				return
		global_position += vel * delta
		_orb.scale = Vector3.ONE * (1.0 + sin(_t * 6.0) * 0.06)
		if _t > life:
			_pop()

	func _pop() -> void:
		var ex = load("res://scripts/slash_fx.gd").make(0.0, TAU, 0.1, 0.9, Color(0.7, 0.95, 1.0), 0.25)
		get_parent().add_child(ex)
		ex.global_transform = Transform3D(Basis.IDENTITY, global_position)
		Sfx.play("parry", -14.0, 0.1, 30, 2.4)
		queue_free()


# ---------------------------------------------------------------- Güneş Rahibi ışını

class SunBeam extends Node3D:
	var hero = null
	var dir := Vector3.FORWARD
	var length := 13.0
	var width := 1.1
	var dmg := 14.0
	var _t := 0.0
	var _mat: StandardMaterial3D

	func _ready() -> void:
		top_level = true
		var bm := MeshInstance3D.new()
		var b := BoxMesh.new()
		b.size = Vector3(width, 2.4, length)
		bm.mesh = b
		_mat = StandardMaterial3D.new()
		_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		_mat.albedo_color = Color(1.0, 0.85, 0.45, 0.9)
		bm.material_override = _mat
		bm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		bm.position = Vector3(0, 1.2, -length * 0.5)
		add_child(bm)
		look_at(global_position + dir, Vector3.UP)
		Sfx.play("boom", -12.0, 0.1, 0, 2.4)
		Fx.flash_light(global_position + dir * length * 0.5 + Vector3(0, 1, 0), Color(1.0, 0.8, 0.4), 6.0, 8.0, 0.25)
		if hero != null and is_instance_valid(hero) and not hero.dead:
			var v: Vector3 = hero.global_position - global_position
			v.y = 0.0
			var along := v.dot(dir)
			var side := absf(v.dot(Vector3(-dir.z, 0, dir.x)))
			if along > -0.3 and along < length and side < width * 0.5 + 0.35:
				hero.take_damage(dmg, Vector3(-dir.z, 0, dir.x) * signf(v.dot(Vector3(-dir.z, 0, dir.x)) + 0.01), false)

	func _process(delta: float) -> void:
		_t += delta
		_mat.albedo_color.a = 0.9 * (1.0 - _t / 0.35)
		scale.x = 1.0 - _t * 1.5
		if _t >= 0.35:
			queue_free()

