extends Node3D
## DÖVÜŞ ODASI: yıldızların arasında asılı, yuvarlak bir gözlem platformu.
## RUN AKIŞI: 4 oda (derinlik 0-3) + KOÇ boss'u (derinlik 4).
##  - Her odanın bir ödülü var (girdiğin kapı belirler): gezegen lütfu, yıldız tozu ya da dinlenme (Sığınak).
##  - Oda temizlenince ödül verilir, sonra 2 kapı açılır; üstlerindeki sembol ödülü gösterir. Hangisine gireceğini sen seçersin.
##  - Son odadan sonra tek kapı: Koç'un arenası.
## Can ve lütuflar odalar arasında taşınır. Ölürsen toplanan yıldız tozu sende kalır.
## Esc: duraklatma menüsü.

const GameData = preload("res://scripts/game_data.gd")
const UI = preload("res://scripts/ui_style.gd")
const CameraScript = preload("res://scripts/camera_rig.gd")
const HeroScript = preload("res://scripts/hero.gd")
const EnemyScript = preload("res://scripts/enemy.gd")
const AriesScript = preload("res://scripts/aries_boss.gd")
const TaurusScript = preload("res://scripts/taurus_boss.gd")
const GeminiScript = preload("res://scripts/gemini_boss.gd")
const CancerScript = preload("res://scripts/cancer_boss.gd")
const LeoScript = preload("res://scripts/leo_boss.gd")
const VirgoScript = preload("res://scripts/virgo_boss.gd")
const LibraScript = preload("res://scripts/libra_boss.gd")
const ScorpioScript = preload("res://scripts/scorpio_boss.gd")
const SagScript = preload("res://scripts/sagittarius_boss.gd")
const CapScript = preload("res://scripts/capricorn_boss.gd")
const AqScript = preload("res://scripts/aquarius_boss.gd")
const PiScript = preload("res://scripts/pisces_boss.gd")
const SkyEcho = preload("res://scripts/sky_echo.gd")
const Ach = preload("res://scripts/achievements.gd")
const Juice = preload("res://scripts/juice.gd")
const Elements = preload("res://scripts/elements.gd")
var _boss_hurt := false   # boss odasında hasar alındı mı (Yıldızlar Dokunamadı başarımı)
const PauseUI = preload("res://scripts/pause_ui.gd")
const BoonUI = preload("res://scripts/boon_ui.gd")
const CombatHud = preload("res://scripts/combat_hud.gd")
const Skills = preload("res://scripts/star_skills.gd")
const Boons = preload("res://scripts/boons.gd")
const Retro = preload("res://scripts/retro.gd")
const WBoons = preload("res://scripts/weapon_boons.gd")
const HUB_SCENE := "res://scenes/hub.tscn"
const ROOM_SCENE := "res://scenes/room.tscn"

const ARENA_R := 11.0
const BOSS_DEPTH := 4
## Her derinlik: dalgalar listesi; her dalga: düşman tipleri
const COMBAT := [
	[["shade", "shade", "shade"], ["shade", "caster", "shade"]],   # GDD §13.5: 3+3
	[["shade", "leaper", "caster"], ["brute", "shade", "shade"]],
	[["shade", "leaper", "caster", "shade"], ["brute", "caster", "shade", "leaper"]],
	[["brute", "shade", "caster", "leaper", "shade"], ["caster", "leaper", "shade", "shade", "brute"]],
]
## Derinliğe göre düşman güçlenmesi ve seçkin olma şansı (dengeli: her oyuncu için)
const HP_MULT := [1.0, 1.1, 1.25, 1.4]
const DMG_MULT := [1.0, 1.1, 1.2, 1.3]
const ELITE_CHANCE := [0.0, 0.0, 0.08, 0.15]
const DUST_REWARD := [30, 45, 60, 80]
const ROOM_BONUS := [10, 15, 20, 25]
const DUST_BY_KIND := {"shade": 5, "caster": 5, "leaper": 6, "brute": 16}
const BOSS_DUST := 150
const BOSS_FIRST_BONUS := 200
## BÖLGELER: run derinliği 0-4 Koç Geçidi (4 = Koç), 5-9 Boğa Otlakları (9 = Boğa)
const ZONE_START := {"aries": 0, "taurus": 5, "gemini": 10, "cancer": 15, "leo": 20, "virgo": 25, "libra": 30, "scorpio": 35, "sagittarius": 40, "capricorn": 45, "aquarius": 50, "pisces": 55}
const LAST_DEPTH := 59
const COMBAT_G := [
	[["shade", "shade", "caster", "leaper"], ["brute", "shade", "shade", "caster"]],
	[["shade", "shade", "leaper", "caster"], ["brute", "caster", "shade", "shade"], ["leaper", "leaper", "caster", "shade", "shade"]],
	[["brute", "leaper", "caster", "shade", "shade"], ["caster", "caster", "leaper", "shade", "shade"], ["brute", "brute", "shade", "shade", "leaper"]],
	[["brute", "leaper", "leaper", "caster", "shade", "shade"], ["caster", "caster", "brute", "shade", "shade", "leaper"], ["brute", "brute", "leaper", "caster", "shade", "shade"]],
]
const HP_MULT_G := [1.6, 1.7, 1.8, 1.9]
const DMG_MULT_G := [1.6, 1.68, 1.76, 1.85]
const ELITE_CHANCE_G := [0.25, 0.3, 0.35, 0.35]
const COMBAT_C := [
	[["shade", "shade", "caster", "leaper"], ["brute", "shade", "shade", "caster"]],
	[["shade", "leaper", "leaper", "caster"], ["brute", "caster", "shade", "shade"], ["leaper", "caster", "shade", "shade", "shade"]],
	[["brute", "leaper", "caster", "shade", "shade"], ["caster", "caster", "leaper", "shade", "shade"], ["brute", "brute", "shade", "leaper", "caster"]],
	[["brute", "leaper", "leaper", "caster", "shade", "shade"], ["caster", "caster", "brute", "shade", "shade", "leaper"], ["brute", "brute", "leaper", "caster", "shade", "shade"]],
]
const HP_MULT_C := [2.04, 2.15, 2.26, 2.37]   # GDD §13.9 (0.5.4)
const DMG_MULT_C := [2.04, 2.09, 2.13, 2.15]   # GDD §13.9 (0.5.4)
const ELITE_CHANCE_C := [0.35, 0.40, 0.45, 0.45]   # GDD §13.9 (0.5.4)
const COMBAT_L := [
	[["shade", "shade", "caster", "leaper"], ["brute", "shade", "shade", "caster"]],
	[["shade", "shade", "shade", "caster"], ["brute", "caster", "leaper", "shade"], ["leaper", "leaper", "caster", "shade", "shade"]],
	[["brute", "leaper", "caster", "shade", "shade"], ["shade", "shade", "shade", "caster", "caster"], ["brute", "brute", "shade", "leaper", "caster"]],
	[["brute", "leaper", "leaper", "caster", "shade", "shade"], ["caster", "caster", "brute", "shade", "shade", "shade"], ["brute", "brute", "leaper", "caster", "shade", "shade"]],
]
const HP_MULT_L := [2.22, 2.32, 2.43, 2.59]   # GDD §13.9 (Testçi 5. tur: ×0,92)
const DMG_MULT_L := [1.66, 1.70, 1.73, 1.75]   # GDD §13.9 (0.5.4)
const ELITE_CHANCE_L := [0.40, 0.45, 0.50, 0.50]   # GDD §13.9 (0.5.4)
const COMBAT_V := [
	[["shade", "shade", "caster", "leaper"], ["brute", "shade", "caster", "leaper"]],
	[["shade", "leaper", "leaper", "caster"], ["brute", "caster", "shade", "shade"], ["leaper", "caster", "caster", "shade", "shade"]],
	[["brute", "leaper", "caster", "shade", "shade"], ["caster", "caster", "leaper", "shade", "shade"], ["brute", "brute", "shade", "leaper", "caster"]],
	[["brute", "leaper", "leaper", "caster", "shade", "shade"], ["caster", "caster", "brute", "shade", "shade", "leaper"], ["brute", "brute", "leaper", "caster", "caster", "shade"]],
]
const HP_MULT_V := [2.59, 2.76, 2.87, 3.04]   # GDD §13.9 (Testçi 5. tur: ×0,92)
const DMG_MULT_V := [2.05, 2.10, 2.14, 2.16]   # GDD §13.9 (0.5.4)
const ELITE_CHANCE_V := [0.45, 0.50, 0.55, 0.55]   # GDD §13.9 (0.5.4)
const COMBAT_B := [
	[["shade", "shade", "caster", "leaper"], ["brute", "shade", "shade", "caster"]],
	[["shade", "shade", "leaper", "caster"], ["brute", "caster", "shade", "shade"], ["leaper", "leaper", "caster", "shade", "shade"]],
	[["brute", "leaper", "caster", "shade", "shade"], ["caster", "caster", "leaper", "shade", "shade"], ["brute", "brute", "shade", "shade", "caster"]],
	[["brute", "leaper", "leaper", "caster", "shade", "shade"], ["caster", "caster", "brute", "shade", "shade", "leaper"], ["brute", "brute", "leaper", "caster", "shade", "shade"]],
]
const HP_MULT_B := [3.25, 3.44, 3.63, 3.81]   # GDD §13.9 (0.5.4)
const DMG_MULT_B := [2.57, 2.63, 2.68, 2.71]   # GDD §13.9 (0.5.4)
const ELITE_CHANCE_B := [0.50, 0.55, 0.55, 0.60]   # GDD §13.9 (0.5.4)
const COMBAT_S := [
	[["shade", "shade", "caster", "leaper"], ["brute", "shade", "shade", "caster"]],
	[["shade", "shade", "leaper", "caster"], ["brute", "caster", "shade", "leaper"], ["leaper", "leaper", "caster", "shade", "shade"]],
	[["brute", "leaper", "caster", "shade", "shade"], ["caster", "caster", "leaper", "shade", "shade"], ["brute", "brute", "shade", "leaper", "caster"]],
	[["brute", "leaper", "leaper", "caster", "shade", "shade"], ["caster", "caster", "brute", "shade", "shade", "leaper"], ["brute", "brute", "leaper", "caster", "shade", "shade"]],
]
const HP_MULT_S := [3.71, 3.90, 4.10, 4.29]   # GDD §13.9 (0.5.4)
const DMG_MULT_S := [1.97, 2.01, 2.05, 2.07]   # GDD §13.9 (0.5.4)
const ELITE_CHANCE_S := [0.60, 0.60, 0.65, 0.65]   # GDD §13.9 (0.5.4)
const COMBAT_Y := [
	[["shade", "shade", "caster", "leaper"], ["brute", "shade", "shade", "caster"]],
	[["shade", "shade", "leaper", "caster"], ["brute", "caster", "shade", "leaper"], ["leaper", "leaper", "caster", "shade", "shade"]],
	[["brute", "leaper", "caster", "shade", "shade"], ["caster", "caster", "leaper", "shade", "shade"], ["brute", "brute", "shade", "leaper", "caster"]],
	[["brute", "leaper", "leaper", "caster", "shade", "shade"], ["caster", "caster", "brute", "shade", "shade", "leaper"], ["brute", "brute", "leaper", "caster", "shade", "shade"]],
]
const HP_MULT_Y := [5.03, 5.27, 5.51, 5.83]   # GDD §13.9 (Testçi 5. tur: ×1,20)
const DMG_MULT_Y := [2.95, 3.02, 3.08, 3.11]   # GDD §13.9 (0.5.4)
const ELITE_CHANCE_Y := [0.70, 0.75, 0.75, 0.80]   # GDD §13.9 (Testçi 5. tur: +0,10)
const COMBAT_K := [
	[["shade", "shade", "caster", "leaper"], ["brute", "shade", "shade", "caster"]],
	[["shade", "shade", "leaper", "caster"], ["brute", "caster", "shade", "leaper"], ["leaper", "leaper", "caster", "shade", "shade"]],
	[["brute", "leaper", "caster", "shade", "shade"], ["caster", "caster", "leaper", "shade", "shade"], ["brute", "brute", "shade", "leaper", "caster"]],
	[["brute", "leaper", "leaper", "caster", "shade", "shade"], ["caster", "caster", "brute", "shade", "shade", "leaper"], ["brute", "brute", "leaper", "caster", "shade", "shade"]],
]
const HP_MULT_K := [4.69, 4.90, 5.18, 5.46]   # GDD §13.9 (0.5.4)
const DMG_MULT_K := [3.41, 3.48, 3.55, 3.59]   # GDD §13.9 (0.5.4)
const ELITE_CHANCE_K := [0.65, 0.65, 0.70, 0.70]   # GDD §13.9 (0.5.4)
const COMBAT_Q := [
	[["shade", "shade", "caster", "leaper"], ["brute", "shade", "shade", "caster"]],
	[["shade", "shade", "leaper", "caster"], ["brute", "caster", "shade", "leaper"], ["leaper", "leaper", "caster", "shade", "shade"]],
	[["brute", "leaper", "caster", "shade", "shade"], ["caster", "caster", "leaper", "shade", "shade"], ["brute", "brute", "shade", "leaper", "caster"]],
	[["brute", "leaper", "leaper", "caster", "shade", "shade"], ["caster", "caster", "brute", "shade", "shade", "leaper"], ["brute", "brute", "leaper", "caster", "shade", "shade"]],
]
const HP_MULT_Q := [5.22, 5.44, 5.73, 6.02]   # GDD §13.9 (0.5.4)
const DMG_MULT_Q := [3.80, 3.88, 3.96, 4.00]   # GDD §13.9 (0.5.4)
const ELITE_CHANCE_Q := [0.65, 0.70, 0.70, 0.75]   # GDD §13.9 (0.5.4)
const COMBAT_P := [
	[["shade", "shade", "caster", "leaper"], ["brute", "shade", "shade", "caster"]],
	[["shade", "shade", "leaper", "caster"], ["brute", "caster", "shade", "leaper"], ["leaper", "leaper", "caster", "shade", "shade"]],
	[["brute", "leaper", "caster", "shade", "shade"], ["caster", "caster", "leaper", "shade", "shade"], ["brute", "brute", "shade", "leaper", "caster"]],
	[["brute", "leaper", "leaper", "caster", "shade", "shade"], ["caster", "caster", "brute", "shade", "shade", "leaper"], ["brute", "brute", "leaper", "caster", "shade", "shade"]],
]
const HP_MULT_P := [5.78, 6.00, 6.30, 6.60]   # GDD §13.9 (0.5.4)
const DMG_MULT_P := [4.47, 4.56, 4.65, 4.70]   # GDD §13.9 (0.5.4)
const ELITE_CHANCE_P := [0.70, 0.70, 0.75, 0.80]   # GDD §13.9 (0.5.4)
const PI_DUST := 1100
const PI_FIRST_BONUS := 2000
const AQ_DUST := 940
const AQ_FIRST_BONUS := 1200
const CAP_DUST := 860
const CAP_FIRST_BONUS := 1100
const SAG_DUST := 780
const SAG_FIRST_BONUS := 1000
const SCORPIO_DUST := 700
const SCORPIO_FIRST_BONUS := 900
const LIBRA_DUST := 620
const LIBRA_FIRST_BONUS := 800
const VIRGO_DUST := 540
const VIRGO_FIRST_BONUS := 700
const LEO_DUST := 460
const LEO_FIRST_BONUS := 600
const CANCER_DUST := 380
const CANCER_FIRST_BONUS := 500
const GEMINI_DUST := 300
const GEMINI_FIRST_BONUS := 400
const COMBAT_T := [
	[["shade", "shade", "caster", "leaper"], ["brute", "shade", "caster"]],
	[["leaper", "leaper", "shade", "caster"], ["brute", "caster", "shade", "shade"], ["leaper", "caster", "shade", "shade", "shade"]],
	[["brute", "leaper", "caster", "shade", "shade"], ["caster", "caster", "leaper", "shade", "shade"], ["brute", "brute", "caster", "leaper"]],
	[["brute", "leaper", "leaper", "caster", "shade", "shade"], ["caster", "caster", "brute", "shade", "shade", "leaper"], ["brute", "brute", "leaper", "caster", "caster", "shade"]],
]
const HP_MULT_T := [1.35, 1.45, 1.55, 1.65]
const DMG_MULT_T := [1.3, 1.38, 1.46, 1.55]
const ELITE_CHANCE_T := [0.15, 0.2, 0.25, 0.3]
const TAURUS_DUST := 220
const TAURUS_FIRST_BONUS := 300

var hero
var hero2 = null          # İKİZLER: 2. oyuncu (co-op değilse null)
var _cam_focus: Node3D    # co-op'ta kamera iki kahramanın ortasına bakar
var _revive := {}         # yerde yatan kahraman -> kaldırma ilerlemesi (sn)
var _retarget_t := 0.0
var camera
var sky_mat: ShaderMaterial
var _flames: Array = []
var hud
var pause_ui
var boon_ui
var boss = null
var wave := -1
var room_i := 0
var zone := "aries"
var local_i := 0             # bölge içindeki oda sırası (0-3 dövüş, 4 boss)
var _lonely = null           # İkiz Gölge eşleştirmesi: eşini bekleyen gölge
var reward := ""
var is_boss := false
var is_rest := false
var waves: Array = []
var alive := 0
var pending := 0
var earned := 0
var cleared := false
var ended := false
var victory := false
var doors: Array = []          # [{node, type, pos, title}]
var _t := 0.0
var _next_wave_t := 1.4
var _elites := 0
const VOLATILE_DMG := {"libra": 13.0, "aquarius": 12.0, "pisces": 10.0}   # "patlayan" seçkin özelliği (GDD §13.8), diğerleri 14
var tc = null   # dokunmatik kontroller (telefon)   # bu odada doğan seçkin sayısı (GDD §13.3)
## BOSS EĞRİSİ (GDD §13.4): taban can ve hasar çarpanı (retro/döngü/co-op çarpanları bunların üstüne)
const BOSS_HP := {"aries": 1400.0, "taurus": 1800.0, "gemini": 2200.0, "cancer": 2500.0, "leo": 2900.0, "virgo": 3300.0,
	"libra": 3600.0, "scorpio": 3700.0, "sagittarius": 4300.0, "capricorn": 4900.0, "aquarius": 5400.0, "pisces": 6000.0}
const BOSS_DMG := {"aries": 1.0, "taurus": 1.0, "gemini": 0.65, "cancer": 0.97, "leo": 0.81, "virgo": 1.15,
	"libra": 1.15, "scorpio": 0.71, "sagittarius": 1.40, "capricorn": 1.50, "aquarius": 1.1, "pisces": 2.5}   # GDD §13.4 (Testçi 5. tur)


func _ready() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	GameData.go_load()
	GameData.apply_settings()
	GameData.setup_input()
	Fx.reset()
	Fx.world = self
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if GameData.run_room == 0 and GameData.run_hp < 0.0 and GameData.run_reward == "":
		GameData.start_run()
	room_i = clampi(GameData.run_room, 0, LAST_DEPTH)
	zone = "aries"
	if room_i >= int(ZONE_START["pisces"]):
		zone = "pisces"
	elif room_i >= int(ZONE_START["aquarius"]):
		zone = "aquarius"
	elif room_i >= int(ZONE_START["capricorn"]):
		zone = "capricorn"
	elif room_i >= int(ZONE_START["sagittarius"]):
		zone = "sagittarius"
	elif room_i >= int(ZONE_START["scorpio"]):
		zone = "scorpio"
	elif room_i >= int(ZONE_START["libra"]):
		zone = "libra"
	elif room_i >= int(ZONE_START["virgo"]):
		zone = "virgo"
	elif room_i >= int(ZONE_START["leo"]):
		zone = "leo"
	elif room_i >= int(ZONE_START["cancer"]):
		zone = "cancer"
	elif room_i >= int(ZONE_START["gemini"]):
		zone = "gemini"
	elif room_i >= int(ZONE_START["taurus"]):
		zone = "taurus"
	local_i = room_i - int(ZONE_START[zone])
	reward = GameData.run_reward
	is_boss = local_i >= BOSS_DEPTH
	is_rest = reward == "rest" and not is_boss
	GameData.snapshot_run()
	GameData.go_save()
	if is_boss or is_rest:
		waves = []
	else:
		var table: Array = _zt(COMBAT, COMBAT_T, COMBAT_G, COMBAT_C, COMBAT_L, COMBAT_V, COMBAT_B, COMBAT_S, COMBAT_Y, COMBAT_K, COMBAT_Q, COMBAT_P)
		waves = table[mini(local_i, table.size() - 1)]
	Sfx.play_music(_music_path(), -9.0)
	if not GameData.almanac.has("zone:" + zone):
		GameData.almanac["zone:" + zone] = 1   # almanakta burcun sayfası açılır

	if zone == "pisces":
		_environment_pisces()
		_arena_pisces()
	elif zone == "aquarius":
		_environment_aquarius()
		_arena_aquarius()
	elif zone == "capricorn":
		_environment_capricorn()
		_arena_capricorn()
	elif zone == "sagittarius":
		_environment_sagittarius()
		_arena_sagittarius()
	elif zone == "scorpio":
		_environment_scorpio()
		_arena_scorpio()
	elif zone == "libra":
		_environment_libra()
		_arena_libra()
	elif zone == "virgo":
		_environment_virgo()
		_arena_virgo()
	elif zone == "leo":
		_environment_leo()
		_arena_leo()
	elif zone == "cancer":
		_environment_cancer()
		_arena_cancer()
	elif zone == "gemini":
		_environment_gemini()
		_arena_gemini()
	elif zone == "taurus":
		_environment_taurus()
		_arena_taurus()
	else:
		_environment()
		_arena()

	camera = CameraScript.new()
	camera.offset = Vector3(9.0, 11.5, 9.0) * ((1.22 if zone == "taurus" else 1.15) if is_boss else 1.0)
	add_child(camera)
	camera.fov = 44.0
	Fx.camera = camera

	hero = HeroScript.new()
	hero.camera = camera
	hero.bound_radius = ARENA_R - 0.4
	add_child(hero)
	hero.global_position = Vector3(0, 0, 5.0)
	hero.add_to_group("heroes")
	camera.target = hero
	_cam_focus = hero
	if GameData.run_hp > 0.0:
		hero.set_run_hp(GameData.run_hp)
	hero.hurt.connect(_on_hero_hurt)
	# ÇEVRİM İÇİ İKİZLER: ikinci kahraman karşı bilgisayardaki oyuncudur (her iki tarafta "hero" kendi oyuncumuz)
	if Net.online():
		hero2 = HeroScript.new()
		hero2.remote = true
		hero2.pid = 1
		hero2.camera = camera
		hero2.bound_radius = ARENA_R - 0.4
		add_child(hero2)
		hero2.global_position = Vector3(1.6, 0, 5.4)
		hero2.add_to_group("heroes")
		hero2.tint_p2()
		var mid0 := Node3D.new()
		add_child(mid0)
		mid0.global_position = Vector3(0.8, 0, 5.2)
		_cam_focus = mid0
		camera.target = mid0
		if Net.is_host():
			hero.died.connect(_on_coop_died.bind(hero))
			hero2.died.connect(_on_coop_died.bind(hero2))
	# İKİZLER: ikinci kahraman (kontrolcüsü bağlıysa)
	elif GameData.coop and not GameData.is_mobile() and GameData.coop_bind():
		hero2 = HeroScript.new()
		hero2.pid = 1
		hero2.pad_dev = GameData.p2_pad
		hero2.camera = camera
		hero2.bound_radius = ARENA_R - 0.4
		add_child(hero2)
		hero2.global_position = Vector3(1.6, 0, 5.4)
		hero2.add_to_group("heroes")
		hero2.tint_p2()
		if GameData.run_hp2 > 0.0:
			hero2.set_run_hp(GameData.run_hp2)
		hero2.hurt.connect(_on_hero_hurt)
		hero2.died.connect(_on_coop_died.bind(hero2))
		hero.died.connect(_on_coop_died.bind(hero))
		var mid := Node3D.new()
		add_child(mid)
		mid.global_position = Vector3(0.8, 0, 5.2)
		_cam_focus = mid
		camera.target = mid
	else:
		hero.died.connect(_on_hero_died)

	var layer := CanvasLayer.new()
	add_child(layer)
	hud = CombatHud.new()
	hud.hero = hero
	hud.hero2 = hero2
	hud.wave_total = waves.size()
	hud.room = local_i + 1
	hud.room_total = BOSS_DEPTH + 1
	hud.reward = reward
	hud.zone_el = String(load("res://scripts/elements.gd").ZONE_EL.get(zone, ""))
	layer.add_child(hud)
	boon_ui = BoonUI.new()
	boon_ui.picked.connect(_on_boon_picked)
	layer.add_child(boon_ui)
	pause_ui = PauseUI.new()
	pause_ui.leave_text = "RETURN TO OBSERVATORY"
	pause_ui.leave.connect(_abandon)
	layer.add_child(pause_ui)
	if GameData.show_touch():
		tc = load("res://scripts/touch_controls.gd").new()
		tc.hero = hero
		tc.hud = hud   # T-15: kapı menzilinde KULLAN düğmesi
		add_child(tc)
	# gök yoldaşı
	var CompS = load("res://scripts/companion.gd")
	if GameData.companion != "" and CompS.unlocked(GameData.companion):
		var comp = CompS.new()
		comp.kind = GameData.companion
		comp.level = CompS.lvl(int(GameData.comp_runs.get(GameData.companion, 0)))
		comp.hero = hero
		add_child(comp)
	_aim_moon()
	_grade()
	Net.room_ready(self)

	if is_rest:
		hero.heal(hero.max_hp * 0.4)
		hud.banner("SANCTUARY", tr("The stars mend your wounds"))
		_spawn_fountain()
	elif is_boss:
		if zone == "pisces":
			hud.banner("PISCES", tr("The Dreamer"))
		elif zone == "aquarius":
			hud.banner("AQUARIUS", tr("The Water Bearer"))
		elif zone == "capricorn":
			hud.banner("CAPRICORN", tr("The Mountain Elder"))
		elif zone == "sagittarius":
			hud.banner("SAGITTARIUS", tr("The Archer King"))
		elif zone == "scorpio":
			hud.banner("SCORPIO", tr("The Venom Queen"))
		elif zone == "libra":
			hud.banner("LIBRA", tr("Arbiter of Balance"))
		elif zone == "virgo":
			hud.banner("VIRGO", tr("The Harvest Maiden"))
		elif zone == "leo":
			hud.banner("LEO", tr("The Sun King"))
		elif zone == "cancer":
			hud.banner("CANCER", tr("Mother of Tides"))
		elif zone == "gemini":
			hud.banner("GEMINI", tr("Castor & Pollux"))
		elif zone == "taurus":
			hud.banner("TAURUS", tr("The Immovable"))
		else:
			hud.banner("ARIES", tr("The Ram's Fury"))
		if not Net.is_client():
			get_tree().create_timer(1.6).timeout.connect(_spawn_boss)
	elif local_i == 0:
		if zone == "pisces":
			hud.banner("THE SEA OF DREAMS", tr("The last sign, where every sign returns"))
		elif zone == "aquarius":
			hud.banner("THE STORM OBSERVATORY", tr("Where the future is struck by lightning"))
		elif zone == "capricorn":
			hud.banner("THE FROZEN SUMMIT", tr("Patience is the steepest climb"))
		elif zone == "sagittarius":
			hud.banner("THE CENTAUR STEPPES", tr("The hunt never stands still"))
		elif zone == "scorpio":
			hud.banner("THE VENOM DEPTHS", tr("What dies here does not stay dead"))
		elif zone == "libra":
			hud.banner("THE SCALES OF DAWN", tr("Every blow is weighed"))
		elif zone == "virgo":
			hud.banner("THE SILENT HARVEST", tr("Order is the only path to Virgo"))
		elif zone == "leo":
			hud.banner("THE SUN PALACE", tr("The pride guards its King"))
		elif zone == "cancer":
			hud.banner("THE MOONLIT SHORE", tr("The Moon pulls the tide toward Cancer"))
		elif zone == "gemini":
			hud.banner("THE TWIN SKIES", tr("Two voices, one sky"))
		elif zone == "taurus":
			hud.banner("THE BULL'S MEADOWS", tr("Venus guards the road to Taurus"))
		else:
			hud.banner("THE RAM'S PASS", tr("The road to Aries burns"))


## Bölgeye ve boss'a özel müzik: dosya varsa onu, yoksa varsayılanı çalar.
## assets/music/zone_<bölge>.(ogg|mp3) · boss_<bölge>.(ogg|mp3) · boss.(ogg|mp3)
func _music_path() -> String:
	if is_rest:
		return "res://assets/music/akash_chamber.mp3"
	var names: Array = []
	if is_boss:
		names = ["boss_" + zone, "boss"]
	else:
		# önce bölgeye özel parça, yoksa bölgenin elementinin parçası (ateş/toprak/hava/su)
		names = ["zone_" + zone, "zone_" + String(load("res://scripts/elements.gd").ZONE_EL.get(zone, ""))]
	for n in names:
		for ext in [".ogg", ".mp3"]:
			var p: String = "res://assets/music/" + String(n) + String(ext)
			if ResourceLoader.exists(p):
				return p
	return "res://assets/music/awakening.mp3"


func _on_hero_hurt() -> void:
	if is_boss:
		_boss_hurt = true
	hud.hurt_flash()


# ---------------------------------------------------------------- ortam

func _environment() -> void:
	# KOÇ BÖLGESİ: kızıl alacakaranlık, duman ve kül; uzay değil, volkanik bir dağ geçidi
	var psky := ProceduralSkyMaterial.new()
	psky.sky_top_color = Color(0.05, 0.05, 0.1)
	psky.sky_horizon_color = Color(0.42, 0.2, 0.14)
	psky.sky_curve = 0.12
	psky.ground_horizon_color = Color(0.5, 0.15, 0.05)
	psky.ground_bottom_color = Color(0.12, 0.03, 0.02)
	psky.sun_angle_max = 8.0
	psky.sun_curve = 0.08
	var sky := Sky.new()
	sky.sky_material = psky
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.42, 0.44, 0.55)   # soğuk ortam ışığı: kızıl canavarlar zeminden ayrılsın
	env.ambient_light_energy = 0.75
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.0
	env.glow_enabled = true
	env.glow_intensity = 0.6
	env.glow_strength = 0.9
	env.glow_bloom = 0.0
	env.glow_hdr_threshold = 1.2
	env.ssao_enabled = true
	env.fog_enabled = true
	env.fog_light_color = Color(0.22, 0.2, 0.25)
	env.fog_light_energy = 0.8
	env.fog_density = 0.008
	env.fog_sky_affect = 0.35
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	# alçak, kızıl bir akşam güneşi (gölgeler uzun ve sıcak)
	var sun := DirectionalLight3D.new()
	sun.light_color = Color(1.0, 0.88, 0.8)
	sun.light_energy = 1.05
	sun.shadow_enabled = not GameData.is_web()
	sun.rotation_degrees = Vector3(-32, 150, 0)
	add_child(sun)
	# aşağıdaki lavdan yükselen turuncu dolgu ışığı
	var under := DirectionalLight3D.new()
	under.light_color = Color(1.0, 0.4, 0.12)
	under.light_energy = 0.06
	under.rotation_degrees = Vector3(60, -40, 0)
	add_child(under)


## BÖLGE RENK FİLTRESİ: her bölgeye kendi tonu (doygunluk/kontrast) ve renkli bir köşe gölgesi
const GRADE := {
	# bölge: [doygunluk, kontrast, köşe rengi, köşe gücü]
	"aries": [1.12, 1.08, Color(0.25, 0.04, 0.02), 0.5],
	"taurus": [1.08, 1.05, Color(0.04, 0.12, 0.04), 0.4],
	"gemini": [1.0, 1.06, Color(0.08, 0.1, 0.2), 0.35],
	"cancer": [1.08, 1.06, Color(0.01, 0.05, 0.14), 0.5],
	"leo": [1.12, 1.08, Color(0.2, 0.1, 0.02), 0.45],
	"virgo": [1.0, 1.05, Color(0.03, 0.1, 0.08), 0.4],
	"libra": [1.05, 1.06, Color(0.02, 0.1, 0.1), 0.4],
	"scorpio": [1.1, 1.1, Color(0.02, 0.08, 0.01), 0.6],
	"sagittarius": [1.05, 1.06, Color(0.08, 0.04, 0.16), 0.4],
	"capricorn": [0.95, 1.08, Color(0.06, 0.1, 0.16), 0.4],
	"aquarius": [1.05, 1.1, Color(0.04, 0.02, 0.12), 0.55],
	"pisces": [1.1, 1.06, Color(0.08, 0.03, 0.14), 0.55],
}


## IŞIK VE ATMOSFER (grafik kalitesine göre)
##  yüksek: hacimli sis (güneşten ışık hüzmeleri), su bölgelerinde zemin yansımaları, yumuşak gölgeler
##  orta: yalnızca yansımalar kapalı, sis hafif;  düşük: ikisi de kapalı, ortam gölgesi (SSAO) kapalı
const ATMO := {
	# bölge: [sis rengi, yoğunluk, yansıma]
	"aries": [Color(0.55, 0.35, 0.25), 0.02, false], "taurus": [Color(0.4, 0.55, 0.3), 0.015, false],
	"gemini": [Color(0.5, 0.6, 0.85), 0.015, false], "cancer": [Color(0.3, 0.45, 0.7), 0.02, true],
	"leo": [Color(0.8, 0.6, 0.3), 0.018, false], "virgo": [Color(0.4, 0.6, 0.5), 0.015, false],
	"libra": [Color(0.4, 0.7, 0.65), 0.015, true], "scorpio": [Color(0.3, 0.5, 0.2), 0.03, false],
	"sagittarius": [Color(0.55, 0.45, 0.75), 0.012, false], "capricorn": [Color(0.7, 0.8, 0.9), 0.02, true],
	"aquarius": [Color(0.4, 0.4, 0.8), 0.02, true], "pisces": [Color(0.6, 0.45, 0.85), 0.025, false],
}


func _atmosphere(env: Environment) -> void:
	var q := int(GameData.gfx_quality)
	var pc := not GameData.is_web()
	if q <= 0:
		env.ssao_enabled = false
		env.glow_enabled = true
		return
	var a: Array = ATMO.get(zone, [Color(0.5, 0.5, 0.7), 0.015, false])
	if pc and q >= 2:
		env.volumetric_fog_enabled = true
		env.volumetric_fog_albedo = a[0]
		env.volumetric_fog_density = float(a[1]) * 0.55
		env.volumetric_fog_emission = Color(a[0]) * 0.01
		env.volumetric_fog_anisotropy = 0.6
		env.volumetric_fog_length = 40.0
		env.volumetric_fog_sky_affect = 0.2
		if bool(a[2]):
			env.ssr_enabled = true
			env.ssr_max_steps = 48
			env.ssr_fade_in = 0.2
			env.ssr_fade_out = 2.0
		for c in get_children():
			if c is DirectionalLight3D:
				c.light_volumetric_fog_energy = 1.6
				c.shadow_blur = 1.5


func _grade() -> void:
	var g: Array = GRADE.get(zone, [1.0, 1.05, Color(0.02, 0.02, 0.08), 0.4])
	for c in get_children():
		if c is WorldEnvironment and c.environment != null:
			var env: Environment = c.environment
			env.adjustment_enabled = true
			env.adjustment_saturation = float(g[0])
			env.adjustment_contrast = float(g[1])
			_atmosphere(env)
			break
	var layer := CanvasLayer.new()
	layer.layer = -1
	add_child(layer)
	var r := ColorRect.new()
	r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var m := ShaderMaterial.new()
	m.shader = preload("res://shaders/vignette.gdshader")
	m.set_shader_parameter("tint", g[2])
	m.set_shader_parameter("strength", float(g[3]))
	r.material = m
	layer.add_child(r)


func _aim_moon() -> void:
	if sky_mat == null:
		return
	var b: Basis = camera.global_transform.basis
	var d := (-b.z + b.y * 0.34 - b.x * 0.42).normalized()
	sky_mat.set_shader_parameter("moon_dir", d)


func _mat(c: Color, metal := 0.0, rough := 0.6) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.metallic = metal
	m.roughness = rough
	return m


func _glow(c: Color, e: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = e
	return m


func _mesh(mesh: Mesh, pos: Vector3, m: Material, parent: Node3D = null) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = m
	mi.position = pos
	(parent if parent != null else self).add_child(mi)
	return mi


func _arena() -> void:
	var heat := 1.35 if is_boss else (0.55 if is_rest else 1.0)
	# bazalt ada
	var top := CylinderMesh.new()
	top.top_radius = ARENA_R + 0.6
	top.bottom_radius = ARENA_R + 0.9
	top.height = 1.0
	top.radial_segments = 96
	var fm := ShaderMaterial.new()
	fm.shader = preload("res://shaders/aries_floor.gdshader")
	fm.set_shader_parameter("heat", heat)
	_mesh(top, Vector3(0, -0.5, 0), fm)
	# adanın altı: lavın içine inen, pürüzlü kaya kütlesi
	var rockm := _mat(Color(0.1, 0.06, 0.05), 0.0, 0.95)
	var under := CylinderMesh.new()
	under.top_radius = ARENA_R + 0.9
	under.bottom_radius = ARENA_R - 3.0
	under.height = 6.0
	under.radial_segments = 14
	_mesh(under, Vector3(0, -4.0, 0), rockm)
	# lav denizi
	var lava := PlaneMesh.new()
	lava.size = Vector2(240, 240)
	var lm := ShaderMaterial.new()
	lm.shader = preload("res://shaders/lava.gdshader")
	_mesh(lava, Vector3(0, -5.5, 0), lm)
	# kenar: düzensiz kaya sivrileri ve ateş mangalları
	var rng := RandomNumberGenerator.new()
	rng.seed = 7 + room_i * 31
	for i in 16:
		var a := TAU * (float(i) + rng.randf_range(0.2, 0.8)) / 16.0
		var p := Vector3(cos(a), 0, sin(a)) * (ARENA_R + rng.randf_range(0.3, 1.0))
		var h := rng.randf_range(0.8, 3.4)
		if i % 4 == 0:
			_brazier(p)
			continue
		var c := CylinderMesh.new()
		c.top_radius = rng.randf_range(0.02, 0.15)
		c.bottom_radius = rng.randf_range(0.45, 0.8)
		c.height = h
		c.radial_segments = 5
		c.rings = 1
		var sp := _mesh(c, p + Vector3(0, h * 0.5 - 0.1, 0), rockm)
		sp.rotation = Vector3(rng.randf_range(-0.2, 0.2), rng.randf() * TAU, rng.randf_range(-0.2, 0.2))
	# arka planda dev koç boynuzları (bölgenin bekçisi)
	var back := Vector3(-1, 0, -1).normalized()
	var side := Vector3(1, 0, -1).normalized()
	for sgn: float in [-1.0, 1.0]:
		_horn(back * (ARENA_R + 7.0) + side * sgn * 5.5 + Vector3(0, -2.0, 0), sgn, 3.2)
	# uzaktaki volkanik dağlar
	for i in 11:
		var a := TAU * float(i) / 11.0 + rng.randf_range(-0.15, 0.15)
		var d := rng.randf_range(48.0, 75.0)
		var hh := rng.randf_range(14.0, 30.0)
		var cone := CylinderMesh.new()
		cone.top_radius = hh * 0.08
		cone.bottom_radius = hh * 0.9
		cone.height = hh
		cone.radial_segments = 9
		cone.rings = 1
		var pos := Vector3(cos(a) * d, hh * 0.5 - 6.0, sin(a) * d)
		_mesh(cone, pos, _mat(Color(0.07, 0.035, 0.03), 0.0, 1.0))
		if i % 3 == 0:
			_mesh(_sphere(hh * 0.09), pos + Vector3(0, hh * 0.5, 0), _glow(Color(1.0, 0.4, 0.1), 3.0))
	_embers(heat)


# ---------------------------------------------------------------- RÜYALAR DENİZİ ortamı

func _environment_pisces() -> void:
	# rüya ile deniz arası: alacakaranlık lila gök, sonsuz durgun su, yukarı süzülen ışık kabarcıkları
	var psky := ProceduralSkyMaterial.new()
	psky.sky_top_color = Color(0.05, 0.04, 0.12)
	psky.sky_horizon_color = Color(0.36, 0.26, 0.5)
	psky.sky_curve = 0.18
	psky.ground_horizon_color = Color(0.25, 0.2, 0.4)
	psky.ground_bottom_color = Color(0.04, 0.04, 0.1)
	psky.sun_angle_max = 1.0
	var sky := Sky.new()
	sky.sky_material = psky
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.6, 0.55, 0.78)
	env.ambient_light_energy = 0.9
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.glow_enabled = true
	env.glow_intensity = 0.6
	env.glow_bloom = 0.0
	env.glow_hdr_threshold = 1.1
	env.ssao_enabled = true
	env.fog_enabled = true
	env.fog_light_color = Color(0.14, 0.1, 0.24)
	env.fog_light_energy = 1.0
	env.fog_density = 0.01
	env.fog_sky_affect = 0.3
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.light_color = Color(0.85, 0.8, 1.0)
	sun.light_energy = 0.75
	sun.shadow_enabled = not GameData.is_web()
	sun.rotation_degrees = Vector3(-58, 135, 0)
	add_child(sun)


func _arena_pisces() -> void:
	var top := CylinderMesh.new()
	top.top_radius = ARENA_R + 0.6
	top.bottom_radius = ARENA_R + 0.6
	top.height = 1.0
	top.radial_segments = 96
	var fm := ShaderMaterial.new()
	fm.shader = preload("res://shaders/pi_floor.gdshader")
	_mesh(top, Vector3(0, -0.5, 0), fm)
	_floor_glyph("♓", Color(0.85, 0.65, 1.0))
	# arenanın çevresi: aynalı, durgun bir deniz
	var sea := PlaneMesh.new()
	sea.size = Vector2(400, 400)
	var sm := _mat(Color(0.06, 0.05, 0.14), 0.6, 0.05)
	_mesh(sea, Vector3(0, -0.35, 0), sm)
	var pearl := _glow(Color(0.9, 0.8, 1.0), 2.0)
	var stone := _mat(Color(0.3, 0.27, 0.45), 0.0, 0.6)
	var rng := RandomNumberGenerator.new()
	rng.seed = 91 + room_i * 5
	var back := Vector3(-1, 0, -1).normalized()
	# sudan yükselen inci kabukları ve kemerler (arka taraf)
	for i in 9:
		var a2 := TAU * (float(i) + 0.5) / 9.0
		var dir := Vector3(cos(a2), 0, sin(a2))
		if dir.dot(back) < -0.2:
			continue
		var hh := rng.randf_range(1.4, 2.4)
		var c := CylinderMesh.new()
		c.top_radius = 0.2
		c.bottom_radius = 0.35
		c.height = hh
		c.radial_segments = 8
		_mesh(c, dir * (ARENA_R + 1.3) + Vector3(0, hh * 0.5 - 0.35, 0), stone)
		_mesh(_sphere(0.28), dir * (ARENA_R + 1.3) + Vector3(0, hh - 0.2, 0), pearl)
	# uzakta sudan yükselen iki dev balık kuyruğu silueti
	for s: float in [-1.0, 1.0]:
		var a := atan2(back.z, back.x) + s * 0.5
		var tail := _mesh(_sphere(6.0), Vector3(cos(a) * 60.0, 6.0, sin(a) * 60.0), _mat(Color(0.18, 0.15, 0.32), 0.0, 0.5))
		tail.scale = Vector3(0.25, 1.4, 1.0)
		tail.rotation.y = -a
	# yukarı süzülen ışık kabarcıkları
	var em := CPUParticles3D.new()
	em.amount = 80 if not GameData.is_web() else 40
	em.lifetime = 8.0
	em.preprocess = 8.0
	em.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	em.emission_box_extents = Vector3(ARENA_R + 6.0, 0.5, ARENA_R + 6.0)
	em.direction = Vector3.UP
	em.spread = 15.0
	em.gravity = Vector3(0, 0.2, 0)
	em.initial_velocity_min = 0.3
	em.initial_velocity_max = 0.7
	var s2 := SphereMesh.new()
	s2.radius = 0.06
	s2.height = 0.12
	em.mesh = s2
	em.material_override = _glow(Color(0.8, 0.75, 1.0), 3.0)
	add_child(em)


# ---------------------------------------------------------------- FIRTINA GÖZLEMEVİ ortamı

func _environment_aquarius() -> void:
	# bulutların arasında süzülen bir gözlemevi: koyu mor-lacivert fırtına göğü, uzakta çakan şimşekler
	var psky := ProceduralSkyMaterial.new()
	psky.sky_top_color = Color(0.03, 0.03, 0.07)
	psky.sky_horizon_color = Color(0.2, 0.17, 0.3)
	psky.sky_curve = 0.2
	psky.ground_horizon_color = Color(0.2, 0.18, 0.36)
	psky.ground_bottom_color = Color(0.06, 0.06, 0.14)
	psky.sun_angle_max = 1.0
	var sky := Sky.new()
	sky.sky_material = psky
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.58, 0.55, 0.72)
	env.ambient_light_energy = 0.9
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.glow_enabled = true
	env.glow_intensity = 0.6
	env.glow_bloom = 0.0
	env.glow_hdr_threshold = 1.15
	env.ssao_enabled = true
	env.fog_enabled = true
	env.fog_light_color = Color(0.1, 0.09, 0.17)
	env.fog_light_energy = 1.0
	env.fog_density = 0.008
	env.fog_sky_affect = 0.3
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.light_color = Color(0.75, 0.78, 1.0)
	sun.light_energy = 0.8
	sun.shadow_enabled = not GameData.is_web()
	sun.rotation_degrees = Vector3(-60, 120, 0)
	add_child(sun)


func _arena_aquarius() -> void:
	var top := CylinderMesh.new()
	top.top_radius = ARENA_R + 0.6
	top.bottom_radius = ARENA_R + 0.6
	top.height = 1.0
	top.radial_segments = 96
	var fm := ShaderMaterial.new()
	fm.shader = preload("res://shaders/aq_floor.gdshader")
	_mesh(top, Vector3(0, -0.5, 0), fm)
	_floor_glyph("♒", Color(0.6, 0.9, 1.0))
	# platform havada: altı daralan kaya, aşağıda koyu bulut denizi
	var rock := _mat(Color(0.12, 0.12, 0.17), 0.0, 0.85)
	var under := CylinderMesh.new()
	under.top_radius = ARENA_R + 0.6
	under.bottom_radius = 1.5
	under.height = 12.0
	under.radial_segments = 24
	_mesh(under, Vector3(0, -7.0, 0), rock)
	var cloud := PlaneMesh.new()
	cloud.size = Vector2(400, 400)
	_mesh(cloud, Vector3(0, -18.0, 0), _mat(Color(0.07, 0.065, 0.12), 0.0, 1.0))
	var met := _mat(Color(0.4, 0.44, 0.6), 0.7, 0.35)
	var orb := _glow(Color(0.6, 0.9, 1.0), 2.5)
	var rng := RandomNumberGenerator.new()
	rng.seed = 81 + room_i * 5
	var back := Vector3(-1, 0, -1).normalized()
	# kenarda bobin kuleleri (kameraya yakın taraf alçak)
	for i in 8:
		var a2 := TAU * (float(i) + 0.5) / 8.0
		var dir := Vector3(cos(a2), 0, sin(a2))
		var near := dir.dot(back) < -0.2
		var hh := 0.7 if near else rng.randf_range(2.6, 3.6)
		var c := CylinderMesh.new()
		c.top_radius = 0.12
		c.bottom_radius = 0.3
		c.height = hh
		c.radial_segments = 8
		_mesh(c, dir * (ARENA_R + 1.0) + Vector3(0, hh * 0.5 - 0.2, 0), met)
		if not near:
			for k in 3:
				var tr2 := TorusMesh.new()
				tr2.inner_radius = 0.2
				tr2.outer_radius = 0.3
				_mesh(tr2, dir * (ARENA_R + 1.0) + Vector3(0, hh * (0.4 + float(k) * 0.18), 0), met)
			_mesh(_sphere(0.3), dir * (ARENA_R + 1.0) + Vector3(0, hh + 0.1, 0), orb)
	# uzakta süzülen kaya parçaları
	for i in 10:
		var a := atan2(back.z, back.x) + (float(i) - 4.5) * 0.3
		var d := rng.randf_range(28.0, 60.0)
		var b := BoxMesh.new()
		b.size = Vector3(rng.randf_range(2.0, 5.0), rng.randf_range(1.0, 2.5), rng.randf_range(2.0, 5.0))
		var m := _mesh(b, Vector3(cos(a) * d, rng.randf_range(-6.0, 6.0), sin(a) * d), rock)
		m.rotation = Vector3(rng.randf_range(-0.4, 0.4), rng.randf_range(0, TAU), rng.randf_range(-0.4, 0.4))
	# gökte ara ara çakan şimşekler
	var tm := Timer.new()
	tm.wait_time = 3.5
	tm.autostart = true
	add_child(tm)
	tm.timeout.connect(func():
		tm.wait_time = randf_range(2.5, 6.0)
		var aa := atan2(back.z, back.x) + randf_range(-1.0, 1.0)
		Fx.flash_light(Vector3(cos(aa) * 30.0, 15.0, sin(aa) * 30.0), Color(0.7, 0.8, 1.0), 6.0, 60.0, 0.25))
	_wind()


# ---------------------------------------------------------------- DONMUŞ ZİRVE ortamı

func _environment_capricorn() -> void:
	# dağ zirvesi: soluk gri-mavi gök, yoğun sis, kar taneleri, soğuk ışık
	var psky := ProceduralSkyMaterial.new()
	psky.sky_top_color = Color(0.25, 0.32, 0.45)
	psky.sky_horizon_color = Color(0.62, 0.7, 0.8)
	psky.sky_curve = 0.15
	psky.ground_horizon_color = Color(0.55, 0.62, 0.7)
	psky.ground_bottom_color = Color(0.3, 0.35, 0.42)
	psky.sun_angle_max = 4.0
	var sky := Sky.new()
	sky.sky_material = psky
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.62, 0.72)
	env.ambient_light_energy = 0.6
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.glow_enabled = true
	env.glow_intensity = 0.45
	env.glow_bloom = 0.0
	env.glow_hdr_threshold = 1.3
	env.ssao_enabled = true
	env.fog_enabled = true
	env.fog_light_color = Color(0.62, 0.7, 0.8)
	env.fog_light_energy = 0.8
	env.fog_density = 0.005
	env.fog_sky_affect = 0.25
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.light_color = Color(0.85, 0.92, 1.0)
	sun.light_energy = 0.85
	sun.shadow_enabled = not GameData.is_web()
	sun.rotation_degrees = Vector3(-55, 140, 0)
	add_child(sun)


func _arena_capricorn() -> void:
	var top := CylinderMesh.new()
	top.top_radius = ARENA_R + 0.6
	top.bottom_radius = ARENA_R + 0.6
	top.height = 1.0
	top.radial_segments = 96
	var fm := ShaderMaterial.new()
	fm.shader = preload("res://shaders/cap_floor.gdshader")
	_mesh(top, Vector3(0, -0.5, 0), fm)
	_floor_glyph("♑", Color(0.4, 1.0, 0.9))
	# zirve: arena bir kayalık tepenin üstünde, aşağısı uçurum ve bulut
	var cliff := CylinderMesh.new()
	cliff.top_radius = ARENA_R + 0.6
	cliff.bottom_radius = ARENA_R + 6.0
	cliff.height = 30.0
	cliff.radial_segments = 24
	var rock := _mat(Color(0.2, 0.23, 0.28), 0.0, 0.9)
	_mesh(cliff, Vector3(0, -16.0, 0), rock)
	var cloud := PlaneMesh.new()
	cloud.size = Vector2(400, 400)
	_mesh(cloud, Vector3(0, -14.0, 0), _mat(Color(0.5, 0.55, 0.63), 0.0, 1.0))
	var snow := _mat(Color(0.75, 0.8, 0.86), 0.0, 0.7)
	var icem := _glow(Color(0.4, 0.9, 1.0), 1.2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 71 + room_i * 5
	var back := Vector3(-1, 0, -1).normalized()
	# uzaktaki zirveler (bulutların üstünden)
	for i in 8:
		var a := atan2(back.z, back.x) + (float(i) - 3.5) * 0.28
		var d := rng.randf_range(70.0, 100.0)
		var h := rng.randf_range(30.0, 50.0)
		var c := CylinderMesh.new()
		c.top_radius = 0.0
		c.bottom_radius = h * 0.6
		c.height = h
		c.radial_segments = 5
		_mesh(c, Vector3(cos(a) * d, h * 0.5 - 14.0, sin(a) * d), rock)
		var cap := CylinderMesh.new()
		cap.top_radius = 0.0
		cap.bottom_radius = h * 0.24
		cap.height = h * 0.4
		cap.radial_segments = 5
		_mesh(cap, Vector3(cos(a) * d, h - 14.0 - h * 0.2, sin(a) * d), snow)
	# arena kenarında kayalar ve buz kristalleri (kameraya yakın taraf alçak)
	for i in 10:
		var a2 := TAU * (float(i) + 0.4) / 10.0
		var dir := Vector3(cos(a2), 0, sin(a2))
		var near := dir.dot(back) < -0.2
		var b := BoxMesh.new()
		var hh := rng.randf_range(0.5, 0.9) if near else rng.randf_range(1.4, 2.6)
		b.size = Vector3(rng.randf_range(1.0, 1.8), hh, rng.randf_range(0.9, 1.4))
		var m := _mesh(b, dir * (ARENA_R + 1.2) + Vector3(0, hh * 0.5 - 0.3, 0), rock)
		m.rotation = Vector3(rng.randf_range(-0.2, 0.2), a2, rng.randf_range(-0.2, 0.2))
		var sc := BoxMesh.new()
		sc.size = Vector3(b.size.x * 1.02, 0.15, b.size.z * 1.02)
		_mesh(sc, dir * (ARENA_R + 1.2) + Vector3(0, hh - 0.25, 0), snow).rotation = m.rotation
		if not near and i % 2 == 0:
			var cr := CylinderMesh.new()
			cr.top_radius = 0.0
			cr.bottom_radius = 0.25
			cr.height = rng.randf_range(1.2, 2.0)
			cr.radial_segments = 5
			var k := _mesh(cr, dir * (ARENA_R + 0.7) + Vector3(0, cr.height * 0.5 - 0.1, 0), icem)
			k.rotation.z = rng.randf_range(-0.3, 0.3)
	_snowfall()


func _snowfall() -> void:
	var p := CPUParticles3D.new()
	p.amount = 160 if not GameData.is_web() else 70
	p.lifetime = 6.0
	p.preprocess = 6.0
	var em := SphereMesh.new()
	em.radius = 0.04
	em.height = 0.08
	p.mesh = em
	p.material_override = Fx.emissive(Color(0.95, 0.97, 1.0), 1.2)
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(ARENA_R + 4.0, 0.5, ARENA_R + 4.0)
	p.direction = Vector3(0.4, -1, 0.2)
	p.spread = 15.0
	p.gravity = Vector3(0.3, -0.6, 0)
	p.initial_velocity_min = 0.8
	p.initial_velocity_max = 1.6
	p.position = Vector3(0, 9.0, 0)
	add_child(p)


# ---------------------------------------------------------------- KENTAUR BOZKIRI ortamı

func _environment_sagittarius() -> void:
	# yüksek bozkır: açık mavi gök, uzakta karlı dağlar, serin ışık
	var psky := ProceduralSkyMaterial.new()
	psky.sky_top_color = Color(0.2, 0.38, 0.72)
	psky.sky_horizon_color = Color(0.72, 0.82, 0.95)
	psky.sky_curve = 0.12
	psky.ground_horizon_color = Color(0.5, 0.6, 0.62)
	psky.ground_bottom_color = Color(0.2, 0.26, 0.24)
	psky.sun_angle_max = 6.0
	var sky := Sky.new()
	sky.sky_material = psky
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.6, 0.66, 0.72)
	env.ambient_light_energy = 0.85
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.glow_enabled = true
	env.glow_intensity = 0.4
	env.glow_bloom = 0.0
	env.glow_hdr_threshold = 1.35
	env.ssao_enabled = true
	env.fog_enabled = true
	env.fog_light_color = Color(0.7, 0.78, 0.9)
	env.fog_light_energy = 0.8
	env.fog_density = 0.004
	env.fog_sky_affect = 0.2
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.light_color = Color(1.0, 0.97, 0.92)
	sun.light_energy = 1.1
	sun.shadow_enabled = not GameData.is_web()
	sun.rotation_degrees = Vector3(-48, 130, 0)
	add_child(sun)


func _arena_sagittarius() -> void:
	var top := CylinderMesh.new()
	top.top_radius = ARENA_R + 0.6
	top.bottom_radius = ARENA_R + 0.6
	top.height = 1.0
	top.radial_segments = 96
	var fm := ShaderMaterial.new()
	fm.shader = preload("res://shaders/sag_floor.gdshader")
	_mesh(top, Vector3(0, -0.5, 0), fm)
	_floor_glyph("♐", Color(0.75, 0.6, 1.0))
	var ground := PlaneMesh.new()
	ground.size = Vector2(400, 400)
	_mesh(ground, Vector3(0, -0.6, 0), _mat(Color(0.3, 0.4, 0.34), 0.0, 1.0))
	var rock := _mat(Color(0.45, 0.48, 0.55), 0.0, 0.85)
	var snow := _mat(Color(0.92, 0.95, 1.0), 0.0, 0.6)
	var rng := RandomNumberGenerator.new()
	rng.seed = 61 + room_i * 5
	# uzakta karlı dağ silsilesi (sadece kameranın karşısında)
	var back := Vector3(-1, 0, -1).normalized()
	for i in 9:
		var a := atan2(back.z, back.x) + (float(i) - 4.0) * 0.22
		var d := rng.randf_range(80.0, 110.0)
		var h := rng.randf_range(25.0, 45.0)
		var c := CylinderMesh.new()
		c.top_radius = 0.0
		c.bottom_radius = h * 0.8
		c.height = h
		c.radial_segments = 6
		_mesh(c, Vector3(cos(a) * d, h * 0.5 - 2.0, sin(a) * d), rock)
		var cap := CylinderMesh.new()
		cap.top_radius = 0.0
		cap.bottom_radius = h * 0.25
		cap.height = h * 0.3
		cap.radial_segments = 6
		_mesh(cap, Vector3(cos(a) * d, h - 2.0 - h * 0.15, sin(a) * d), snow)
	# arenanın çevresinde ok saplanmış taş dikilitaşlar
	var gold := _glow(Color(0.75, 0.6, 1.0), 1.5)
	for i in 7:
		var a2 := TAU * (float(i) + 0.3) / 7.0
		var dir := Vector3(cos(a2), 0, sin(a2))
		if dir.dot(back) < -0.2:
			continue
		var b := BoxMesh.new()
		b.size = Vector3(0.7, rng.randf_range(2.2, 3.4), 0.5)
		var m := _mesh(b, dir * (ARENA_R + 1.0) + Vector3(0, b.size.y * 0.5 - 0.3, 0), rock)
		m.rotation.y = a2
		_mesh(_sphere(0.16), dir * (ARENA_R + 1.0) + Vector3(0, b.size.y - 0.1, 0), gold)
	_wind()


# ---------------------------------------------------------------- ZEHİR MAĞARALARI ortamı

func _environment_scorpio() -> void:
	# yer altı: neredeyse karanlık, mor-mavi sis; ışık kristallerden ve tavandaki bir yarıktan gelir
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.02, 0.02, 0.05)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.42, 0.4, 0.6)
	env.ambient_light_energy = 0.85
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.glow_enabled = true
	env.glow_intensity = 0.6
	env.glow_bloom = 0.0
	env.glow_hdr_threshold = 1.1
	env.ssao_enabled = true
	env.fog_enabled = true
	env.fog_light_color = Color(0.12, 0.1, 0.22)
	env.fog_light_energy = 1.0
	env.fog_density = 0.02
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var shaft := DirectionalLight3D.new()
	shaft.light_color = Color(0.7, 0.75, 1.0)
	shaft.light_energy = 0.9
	shaft.shadow_enabled = not GameData.is_web()
	shaft.rotation_degrees = Vector3(-70, 120, 0)
	add_child(shaft)


func _arena_scorpio() -> void:
	var top := CylinderMesh.new()
	top.top_radius = ARENA_R + 0.6
	top.bottom_radius = ARENA_R + 0.6
	top.height = 1.0
	top.radial_segments = 96
	var fm := ShaderMaterial.new()
	fm.shader = preload("res://shaders/scorpio_floor.gdshader")
	_mesh(top, Vector3(0, -0.5, 0), fm)
	_floor_glyph("♏", Color(0.7, 0.5, 1.0))
	var rock := _mat(Color(0.1, 0.1, 0.14), 0.0, 0.9)
	var under := PlaneMesh.new()
	under.size = Vector2(200, 200)
	_mesh(under, Vector3(0, -1.0, 0), rock)
	var crystal := _glow(Color(0.6, 0.4, 1.0), 2.5)
	var rng := RandomNumberGenerator.new()
	rng.seed = 51 + room_i * 11
	# mağara duvarı: çevrede yükselen kaya sütunları, tavandan sarkıtlar, mor kristaller
	for i in 22:
		var a := TAU * float(i) / 22.0 + rng.randf() * 0.1
		var d := ARENA_R + rng.randf_range(2.5, 6.0)
		var h := rng.randf_range(5.0, 14.0)
		# kameraya yakın taraftaki kayalar alçak kalsın (görüşü kapatmasın)
		if Vector3(cos(a), 0, sin(a)).dot(Vector3(-1, 0, -1).normalized()) < 0.1:
			h = rng.randf_range(0.6, 1.6)
		var c := CylinderMesh.new()
		c.top_radius = rng.randf_range(0.6, 1.4)
		c.bottom_radius = c.top_radius + rng.randf_range(0.6, 1.6)
		c.height = h
		c.radial_segments = 7
		_mesh(c, Vector3(cos(a) * d, h * 0.5 - 0.6, sin(a) * d), rock)
		if i % 3 == 0:
			var cr := CylinderMesh.new()
			cr.top_radius = 0.0
			cr.bottom_radius = rng.randf_range(0.25, 0.45)
			cr.height = rng.randf_range(1.0, 2.2)
			cr.radial_segments = 5
			var m := _mesh(cr, Vector3(cos(a) * (ARENA_R + 1.2), 0.5, sin(a) * (ARENA_R + 1.2)), crystal)
			m.rotation = Vector3(rng.randf_range(-0.4, 0.4), 0, rng.randf_range(-0.4, 0.4))
	_fireflies(Color(0.55, 1.0, 0.35))


# ---------------------------------------------------------------- ŞAFAK TERAZİSİ ortamı

func _environment_libra() -> void:
	# şafak: yukarıda derin camgöbeği, ufukta gül pembesi
	var psky := ProceduralSkyMaterial.new()
	psky.sky_top_color = Color(0.1, 0.22, 0.32)
	psky.sky_horizon_color = Color(0.95, 0.62, 0.7)
	psky.sky_curve = 0.14
	psky.ground_horizon_color = Color(0.8, 0.55, 0.65)
	psky.ground_bottom_color = Color(0.15, 0.18, 0.25)
	psky.sun_angle_max = 0.0
	var sky := Sky.new()
	sky.sky_material = psky
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.62, 0.6, 0.68)
	env.ambient_light_energy = 0.9
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.glow_enabled = true
	env.glow_intensity = 0.45
	env.glow_bloom = 0.0
	env.glow_hdr_threshold = 1.3
	env.ssao_enabled = true
	env.fog_enabled = true
	env.fog_light_color = Color(0.7, 0.55, 0.65)
	env.fog_light_energy = 0.8
	env.fog_density = 0.005
	env.fog_sky_affect = 0.15
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.light_color = Color(1.0, 0.85, 0.85)
	sun.light_energy = 1.05
	sun.shadow_enabled = not GameData.is_web()
	sun.rotation_degrees = Vector3(-35, 140, 0)
	add_child(sun)
	var back := Vector3(-1, 0, -1).normalized()
	_mesh(_sphere(6.0), back * 150.0 + Vector3(0, 12, 0), _glow(Color(1.0, 0.8, 0.8), 4.0))


func _arena_libra() -> void:
	var top := CylinderMesh.new()
	top.top_radius = ARENA_R + 0.6
	top.bottom_radius = ARENA_R + 0.6
	top.height = 1.0
	top.radial_segments = 96
	var fm := ShaderMaterial.new()
	fm.shader = preload("res://shaders/libra_floor.gdshader")
	_mesh(top, Vector3(0, -0.5, 0), fm)
	_floor_glyph("♎", Color(0.95, 0.85, 0.7))
	var stone := _mat(Color(0.55, 0.5, 0.58), 0.0, 0.7)
	var under := CylinderMesh.new()
	under.top_radius = ARENA_R + 0.6
	under.bottom_radius = 2.0
	under.height = 8.0
	under.radial_segments = 24
	_mesh(under, Vector3(0, -5.0, 0), stone)
	var clouds := PlaneMesh.new()
	clouds.size = Vector2(300, 300)
	var cm := ShaderMaterial.new()
	cm.shader = preload("res://shaders/cloud_sea.gdshader")
	cm.set_shader_parameter("bright", Color(1.0, 0.82, 0.88))
	cm.set_shader_parameter("shade_c", Color(0.45, 0.4, 0.6))
	_mesh(clouds, Vector3(0, -9.0, 0), cm)
	# iki yanda karşılıklı duran iki dev kefe-sütun: denge
	var bronze := _mat(Color(0.75, 0.55, 0.35), 0.6, 0.35)
	var jade := _glow(Color(0.35, 1.0, 0.8), 1.5)
	for s: float in [-1.0, 1.0]:
		var p := Vector3(s * (ARENA_R + 3.5), 0, -2.0)
		var c := CylinderMesh.new()
		c.top_radius = 0.35
		c.bottom_radius = 0.5
		c.height = 8.0
		_mesh(c, p + Vector3(0, 3.0, 0), bronze)
		var bowl := _mesh(_sphere(1.6), p + Vector3(0, 7.2, 0), bronze)
		bowl.scale = Vector3(1.0, 0.3, 1.0)
		_mesh(_sphere(0.5), p + Vector3(0, 7.6, 0), jade)
	for i in 8:
		var a := TAU * (float(i) + 0.5) / 8.0
		var dir := Vector3(cos(a), 0, sin(a))
		var pc := CylinderMesh.new()
		pc.top_radius = 0.2
		pc.bottom_radius = 0.25
		pc.height = 2.6
		_mesh(pc, dir * (ARENA_R + 0.4) + Vector3(0, 1.3, 0), stone)
		_mesh(_sphere(0.22), dir * (ARENA_R + 0.4) + Vector3(0, 2.8, 0), jade)
	_fireflies(Color(1.0, 0.75, 0.85))


# ---------------------------------------------------------------- SESSİZ HASAT ortamı

func _environment_virgo() -> void:
	# sessiz bir hasat gecesi: lacivertten camgöbeğine inen gök, gümüş hilal
	var psky := ProceduralSkyMaterial.new()
	psky.sky_top_color = Color(0.05, 0.08, 0.18)
	psky.sky_horizon_color = Color(0.25, 0.5, 0.55)
	psky.sky_curve = 0.12
	psky.ground_horizon_color = Color(0.2, 0.38, 0.42)
	psky.ground_bottom_color = Color(0.04, 0.08, 0.1)
	psky.sun_angle_max = 0.0
	var sky := Sky.new()
	sky.sky_material = psky
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.5, 0.6, 0.66)
	env.ambient_light_energy = 0.9
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.glow_enabled = true
	env.glow_intensity = 0.5
	env.glow_bloom = 0.0
	env.glow_hdr_threshold = 1.25
	env.ssao_enabled = true
	env.fog_enabled = true
	env.fog_light_color = Color(0.2, 0.35, 0.4)
	env.fog_light_energy = 0.8
	env.fog_density = 0.006
	env.fog_sky_affect = 0.15
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var moon := DirectionalLight3D.new()
	moon.light_color = Color(0.85, 0.95, 1.0)
	moon.light_energy = 1.1
	moon.shadow_enabled = not GameData.is_web()
	moon.rotation_degrees = Vector3(-50, 125, 0)
	add_child(moon)
	# hilal: parlak küre, önünde onu yarı örten koyu küre
	var back := Vector3(-1, 0, -1).normalized()
	var mp := back * 150.0 + Vector3(0, 55, 0)
	_mesh(_sphere(8.0), mp, _glow(Color(0.85, 0.95, 1.0), 3.0))
	_mesh(_sphere(7.6), mp + Vector3(3.5, 2.0, 4.0), _mat(Color(0.05, 0.08, 0.18), 0.0, 1.0))
	# Spika: Başak'ın en parlak yıldızı
	_mesh(_sphere(1.1), back * 140.0 + Vector3(-28, 70, 10), _glow(Color(0.7, 0.85, 1.0), 6.0))


func _arena_virgo() -> void:
	var top := CylinderMesh.new()
	top.top_radius = ARENA_R + 0.6
	top.bottom_radius = ARENA_R + 0.6
	top.height = 1.0
	top.radial_segments = 96
	var fm := ShaderMaterial.new()
	fm.shader = preload("res://shaders/virgo_floor.gdshader")
	_mesh(top, Vector3(0, -0.5, 0), fm)
	_floor_glyph("♍", Color(0.6, 1.0, 0.9))
	var earth := _mat(Color(0.08, 0.12, 0.1), 0.0, 1.0)
	var under := CylinderMesh.new()
	under.top_radius = ARENA_R + 0.6
	under.bottom_radius = ARENA_R + 8.0
	under.height = 2.0
	under.radial_segments = 32
	_mesh(under, Vector3(0, -2.0, 0), earth)
	# arenanın çevresinde gece rüzgârında gümüş başak tarlası
	var ground := PlaneMesh.new()
	ground.size = Vector2(300, 300)
	_mesh(ground, Vector3(0, -1.0, 0), _mat(Color(0.06, 0.1, 0.09), 0.0, 1.0))
	var rng := RandomNumberGenerator.new()
	rng.seed = 41 + room_i * 7
	var wheat := _mat(Color(0.32, 0.42, 0.38), 0.0, 0.9)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var stalk := CylinderMesh.new()
	stalk.top_radius = 0.0
	stalk.bottom_radius = 0.05
	stalk.height = 0.9
	stalk.radial_segments = 4
	stalk.material = wheat
	mm.mesh = stalk
	mm.instance_count = 900
	for i in 900:
		var a := rng.randf() * TAU
		var d := ARENA_R + 1.5 + rng.randf() * 18.0
		var tf := Transform3D(Basis(Vector3(rng.randf_range(-0.3, 0.3), 0, 1).normalized(), rng.randf_range(-0.08, 0.08)), Vector3(cos(a) * d, -0.4 + rng.randf() * 0.3, sin(a) * d))
		mm.set_instance_transform(i, tf)
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	add_child(mmi)
	# kenarda kemerli çardaklar ve camgöbeği fenerler
	var silver := _mat(Color(0.8, 0.86, 0.88), 0.5, 0.35)
	for i in 6:
		var a := TAU * (float(i) + 0.5) / 6.0
		var dir := Vector3(cos(a), 0, sin(a))
		var tang := Vector3(-dir.z, 0, dir.x)
		var base := dir * (ARENA_R + 0.4)
		for sgn: float in [-1.0, 1.0]:
			var c := CylinderMesh.new()
			c.top_radius = 0.1
			c.bottom_radius = 0.12
			c.height = 3.0
			_mesh(c, base + tang * sgn * 0.9 + Vector3(0, 1.5, 0), silver)
		var arch := TorusMesh.new()
		arch.inner_radius = 0.8
		arch.outer_radius = 0.95
		var am := _mesh(arch, base + Vector3(0, 3.0, 0), silver)
		am.look_at(am.global_position + dir, Vector3.UP)
		am.rotate_object_local(Vector3.RIGHT, PI * 0.5)
		_mesh(_sphere(0.2), base + Vector3(0, 2.4, 0), _glow(Color(0.4, 1.0, 0.85), 3.0))
	_fireflies(Color(0.5, 1.0, 0.85))


## Zemine yatık, parlayan burç simgesi
func _floor_glyph(g: String, col: Color) -> void:
	var lb := Label3D.new()
	lb.text = g + "︎"
	lb.font = UI.symbol_font()
	lb.font_size = 256
	lb.pixel_size = 0.012
	lb.modulate = col
	lb.outline_size = 0
	lb.shaded = false
	lb.double_sided = true
	lb.rotation_degrees = Vector3(-90, 45, 0)
	lb.position = Vector3(0, 0.03, 0)
	add_child(lb)


## Ateşböcekleri
func _fireflies(col: Color) -> void:
	var em := CPUParticles3D.new()
	em.amount = 45
	em.lifetime = 6.0
	em.preprocess = 6.0
	em.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	em.emission_box_extents = Vector3(ARENA_R + 6.0, 1.5, ARENA_R + 6.0)
	em.position = Vector3(0, 1.5, 0)
	em.direction = Vector3(0.2, 1, 0.1)
	em.spread = 90.0
	em.gravity = Vector3.ZERO
	em.initial_velocity_min = 0.1
	em.initial_velocity_max = 0.4
	var s := SphereMesh.new()
	s.radius = 0.04
	s.height = 0.08
	em.mesh = s
	em.material_override = _glow(col, 4.0)
	add_child(em)


# ---------------------------------------------------------------- GÜNEŞ SARAYI ortamı

func _environment_leo() -> void:
	# alacakaranlık: mor-lacivert gök, ufukta gül pembesi; batan beyaz-altın güneş
	var psky := ProceduralSkyMaterial.new()
	psky.sky_top_color = Color(0.1, 0.06, 0.24)
	psky.sky_horizon_color = Color(0.72, 0.4, 0.6)
	psky.sky_curve = 0.14
	psky.ground_horizon_color = Color(0.55, 0.35, 0.6)
	psky.ground_bottom_color = Color(0.12, 0.08, 0.22)
	psky.sun_angle_max = 0.0
	var sky := Sky.new()
	sky.sky_material = psky
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.6, 0.52, 0.72)
	env.ambient_light_energy = 0.85
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.glow_enabled = true
	env.glow_intensity = 0.5
	env.glow_bloom = 0.0
	env.glow_hdr_threshold = 1.25
	env.ssao_enabled = true
	env.fog_enabled = true
	env.fog_light_color = Color(0.5, 0.35, 0.6)
	env.fog_light_energy = 0.8
	env.fog_density = 0.005
	env.fog_sky_affect = 0.15
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.light_color = Color(1.0, 0.9, 0.85)
	sun.light_energy = 1.1
	sun.shadow_enabled = not GameData.is_web()
	sun.rotation_degrees = Vector3(-42, 140, 0)
	add_child(sun)
	var back := Vector3(-1, 0, -1).normalized()
	_mesh(_sphere(7.0), back * 150.0 + Vector3(0, 22, 0), _glow(Color(1.0, 0.92, 0.75), 5.0))
	# Regulus: aslanın kalbi, parlak mavi-beyaz yıldız
	_mesh(_sphere(1.2), back * 140.0 + Vector3(25, 60, 0), _glow(Color(0.7, 0.8, 1.0), 6.0))


func _arena_leo() -> void:
	var top := CylinderMesh.new()
	top.top_radius = ARENA_R + 0.6
	top.bottom_radius = ARENA_R + 0.6
	top.height = 1.0
	top.radial_segments = 96
	var fm := ShaderMaterial.new()
	fm.shader = preload("res://shaders/leo_floor.gdshader")
	_mesh(top, Vector3(0, -0.5, 0), fm)
	var marble := _mat(Color(0.88, 0.86, 0.92), 0.0, 0.4)
	var royal := _mat(Color(0.3, 0.16, 0.48), 0.0, 0.6)
	var gold := _glow(Color(1.0, 0.78, 0.38), 0.5)
	var under := CylinderMesh.new()
	under.top_radius = ARENA_R + 0.6
	under.bottom_radius = 2.0
	under.height = 8.0
	under.radial_segments = 24
	_mesh(under, Vector3(0, -5.0, 0), marble)
	var clouds := PlaneMesh.new()
	clouds.size = Vector2(300, 300)
	var cm := ShaderMaterial.new()
	cm.shader = preload("res://shaders/cloud_sea.gdshader")
	cm.set_shader_parameter("bright", Color(0.95, 0.75, 0.85))
	cm.set_shader_parameter("shade_c", Color(0.35, 0.22, 0.5))
	_mesh(clouds, Vector3(0, -9.0, 0), cm)
	# kenarda sütunlu revak: beyaz sütun, altın başlık, aralarda mor sancaklar
	for i in 12:
		var a := TAU * (float(i) + 0.5) / 12.0
		var dir := Vector3(cos(a), 0, sin(a))
		var p := dir * (ARENA_R + 0.5)
		if i % 4 == 1:
			continue     # boşluklar: kapılar ve görüş
		var c := CylinderMesh.new()
		c.top_radius = 0.28
		c.bottom_radius = 0.32
		c.height = 4.2
		_mesh(c, p + Vector3(0, 2.1, 0), marble)
		var cap := BoxMesh.new()
		cap.size = Vector3(0.8, 0.18, 0.8)
		_mesh(cap, p + Vector3(0, 4.28, 0), gold)
		if i % 2 == 0:
			var ban := BoxMesh.new()
			ban.size = Vector3(0.7, 2.0, 0.04)
			var bn := _mesh(ban, p + dir * 0.35 + Vector3(0, 3.0, 0), royal)
			bn.look_at(bn.global_position + dir, Vector3.UP)
			_mesh(_sphere(0.15), p + dir * 0.38 + Vector3(0, 3.2, 0), _glow(Color(1.0, 0.85, 0.5), 3.0))
	# arkada taht kapısı ve güneş kemeri
	var back := Vector3(-1, 0, -1).normalized()
	var bp := back * (ARENA_R + 9.0)
	for s: float in [-1.0, 1.0]:
		var side := Vector3(-back.z, 0, back.x) * s * 4.0
		var tw := CylinderMesh.new()
		tw.top_radius = 0.9
		tw.bottom_radius = 1.2
		tw.height = 18.0
		tw.radial_segments = 10
		_mesh(tw, bp + side + Vector3(0, 4.0, 0), marble)
		_mesh(_sphere(0.7), bp + side + Vector3(0, 13.5, 0), gold)
	var arch := TorusMesh.new()
	arch.inner_radius = 3.6
	arch.outer_radius = 4.3
	var am := _mesh(arch, bp + Vector3(0, 13.0, 0), gold)
	am.look_at(am.global_position + back, Vector3.UP)
	am.rotate_object_local(Vector3.RIGHT, PI * 0.5)
	_sun_motes()


## Havada süzülen altın toz zerreleri
func _sun_motes() -> void:
	var em := CPUParticles3D.new()
	em.amount = 40
	em.lifetime = 5.0
	em.preprocess = 5.0
	em.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	em.emission_box_extents = Vector3(ARENA_R + 3.0, 2.0, ARENA_R + 3.0)
	em.position = Vector3(0, 2.0, 0)
	em.direction = Vector3(0.3, 1, 0.1)
	em.spread = 40.0
	em.gravity = Vector3.ZERO
	em.initial_velocity_min = 0.1
	em.initial_velocity_max = 0.35
	var s := SphereMesh.new()
	s.radius = 0.035
	s.height = 0.07
	em.mesh = s
	em.material_override = _glow(Color(1.0, 0.85, 0.55), 3.0)
	add_child(em)


# ---------------------------------------------------------------- AY IŞIKLI KIYI ortamı

func _environment_cancer() -> void:
	# gece: lacivert gökyüzü, kocaman dolunay; serin, gümüşi ışık
	var psky := ProceduralSkyMaterial.new()
	psky.sky_top_color = Color(0.02, 0.03, 0.09)
	psky.sky_horizon_color = Color(0.12, 0.2, 0.35)
	psky.sky_curve = 0.12
	psky.ground_horizon_color = Color(0.1, 0.18, 0.3)
	psky.ground_bottom_color = Color(0.02, 0.04, 0.08)
	psky.sun_angle_max = 0.0
	var sky := Sky.new()
	sky.sky_material = psky
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.42, 0.5, 0.68)
	env.ambient_light_energy = 0.9
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.glow_enabled = true
	env.glow_intensity = 0.55
	env.glow_bloom = 0.0
	env.glow_hdr_threshold = 1.2
	env.ssao_enabled = true
	env.fog_enabled = true
	env.fog_light_color = Color(0.15, 0.22, 0.35)
	env.fog_light_energy = 0.8
	env.fog_density = 0.006
	env.fog_sky_affect = 0.15
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var moon := DirectionalLight3D.new()
	moon.light_color = Color(0.78, 0.86, 1.0)
	moon.light_energy = 1.05
	moon.shadow_enabled = not GameData.is_web()
	moon.rotation_degrees = Vector3(-48, 135, 0)
	add_child(moon)
	# dolunay ve hâlesi
	var back := Vector3(-1, 0, -1).normalized()
	_mesh(_sphere(9.0), back * 140.0 + Vector3(0, 52, 0), _glow(Color(0.85, 0.92, 1.0), 2.5))
	var halo := _mesh(_sphere(15.0), back * 141.0 + Vector3(0, 52, 0), _glow(Color(0.3, 0.45, 0.8), 0.6))
	(halo.material_override as StandardMaterial3D).transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	(halo.material_override as StandardMaterial3D).albedo_color.a = 0.25
	# yıldızlar
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	var st := _glow(Color(0.85, 0.9, 1.0), 3.0)
	for i in 70:
		var a := rng.randf() * TAU
		var el := rng.randf_range(0.25, 1.2)
		var d := 160.0
		_mesh(_sphere(rng.randf_range(0.2, 0.5)), Vector3(cos(a) * cos(el), sin(el), sin(a) * cos(el)) * d, st)


func _arena_cancer() -> void:
	var top := CylinderMesh.new()
	top.top_radius = ARENA_R + 0.6
	top.bottom_radius = ARENA_R + 0.6
	top.height = 1.0
	top.radial_segments = 96
	var fm := ShaderMaterial.new()
	fm.shader = preload("res://shaders/cancer_floor.gdshader")
	_mesh(top, Vector3(0, -0.5, 0), fm)
	var rockm := _mat(Color(0.2, 0.24, 0.3), 0.0, 0.9)
	var under := CylinderMesh.new()
	under.top_radius = ARENA_R + 0.6
	under.bottom_radius = ARENA_R - 2.0
	under.height = 3.0
	under.radial_segments = 32
	_mesh(under, Vector3(0, -2.0, 0), rockm)
	var sea := PlaneMesh.new()
	sea.size = Vector2(320, 320)
	var sm := ShaderMaterial.new()
	sm.shader = preload("res://shaders/moon_sea.gdshader")
	_mesh(sea, Vector3(0, -1.6, 0), sm)
	var rng := RandomNumberGenerator.new()
	rng.seed = 31 + room_i * 17
	var shellm := _mat(Color(0.95, 0.88, 0.85), 0.0, 0.5)
	var pearl := _glow(Color(0.75, 0.9, 1.0), 3.0)
	# kenarda deniz kayaları ve üstlerinde inci fenerleri
	for i in 9:
		var a := TAU * (float(i) + rng.randf() * 0.4) / 9.0
		var dir := Vector3(cos(a), 0, sin(a))
		var h := rng.randf_range(1.2, 3.0)
		var rk := _mesh(_sphere(1.0), dir * (ARENA_R + 1.3) + Vector3(0, h * 0.3, 0), rockm)
		rk.scale = Vector3(rng.randf_range(0.8, 1.3), h * 0.6, rng.randf_range(0.8, 1.3))
		if i % 3 == 0:
			_mesh(_sphere(0.28), dir * (ARENA_R + 1.3) + Vector3(0, h * 0.6 + 0.6, 0), pearl)
		# kıyıya saçılmış deniz kabukları
		var sh := _mesh(_sphere(0.18), dir.rotated(Vector3.UP, 0.2) * (ARENA_R - 0.8) + Vector3(0, 0.05, 0), shellm)
		sh.scale = Vector3(1.4, 0.4, 1.0)
	# uzakta deniz sütunları (kaya adacıklar)
	for i in 10:
		var a := rng.randf() * TAU
		var d := rng.randf_range(24.0, 60.0)
		var h := rng.randf_range(4.0, 14.0)
		var c := CylinderMesh.new()
		c.top_radius = rng.randf_range(0.6, 1.4)
		c.bottom_radius = c.top_radius + rng.randf_range(0.8, 2.0)
		c.height = h
		c.radial_segments = 7
		_mesh(c, Vector3(cos(a) * d, h * 0.5 - 2.0, sin(a) * d), rockm)
	_plankton()


## Havada süzülen, ay ışığında parlayan plankton ışıltıları
func _plankton() -> void:
	var em := CPUParticles3D.new()
	em.amount = 50
	em.lifetime = 6.0
	em.preprocess = 6.0
	em.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	em.emission_box_extents = Vector3(ARENA_R + 4.0, 0.5, ARENA_R + 4.0)
	em.position = Vector3(0, 0.3, 0)
	em.direction = Vector3.UP
	em.spread = 30.0
	em.gravity = Vector3(0, 0.15, 0)
	em.initial_velocity_min = 0.1
	em.initial_velocity_max = 0.4
	var s := SphereMesh.new()
	s.radius = 0.04
	s.height = 0.08
	em.mesh = s
	em.material_override = _glow(Color(0.4, 0.9, 1.0), 4.0)
	add_child(em)


# ---------------------------------------------------------------- İKİZ GÖKLER ortamı

func _environment_gemini() -> void:
	# parlak, rüzgârlı gökyüzü; aşağıda bulut denizi
	var psky := ProceduralSkyMaterial.new()
	psky.sky_top_color = Color(0.22, 0.42, 0.85)
	psky.sky_horizon_color = Color(0.78, 0.86, 1.0)
	psky.sky_curve = 0.1
	psky.ground_horizon_color = Color(0.85, 0.9, 1.0)
	psky.ground_bottom_color = Color(0.7, 0.78, 0.95)
	psky.sun_angle_max = 6.0
	var sky := Sky.new()
	sky.sky_material = psky
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.62, 0.68, 0.85)
	env.ambient_light_energy = 0.85
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.glow_enabled = true
	env.glow_intensity = 0.45
	env.glow_bloom = 0.0
	env.glow_hdr_threshold = 1.35
	env.ssao_enabled = true
	env.fog_enabled = true
	env.fog_light_color = Color(0.8, 0.86, 1.0)
	env.fog_light_energy = 0.8
	env.fog_density = 0.004
	env.fog_sky_affect = 0.2
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.light_color = Color(1.0, 0.97, 0.92)
	sun.light_energy = 1.1
	sun.shadow_enabled = not GameData.is_web()
	sun.rotation_degrees = Vector3(-50, 130, 0)
	add_child(sun)
	# gökte Kastor (mavi-beyaz) ve Polluks (turuncu-altın)
	var back := Vector3(-1, 0, -1).normalized()
	var side := Vector3(1, 0, -1).normalized()
	_mesh(_sphere(1.6), back * 120.0 + side * 6.0 + Vector3(0, 60, 0), _glow(Color(0.7, 0.85, 1.0), 6.0))
	_mesh(_sphere(1.8), back * 120.0 - side * 6.0 + Vector3(0, 57, 0), _glow(Color(1.0, 0.75, 0.4), 6.0))


func _arena_gemini() -> void:
	var top := CylinderMesh.new()
	top.top_radius = ARENA_R + 0.6
	top.bottom_radius = ARENA_R + 0.6
	top.height = 1.0
	top.radial_segments = 96
	var fm := ShaderMaterial.new()
	fm.shader = preload("res://shaders/gemini_floor.gdshader")
	_mesh(top, Vector3(0, -0.5, 0), fm)
	var rockm := _mat(Color(0.82, 0.84, 0.9), 0.0, 0.8)
	var under := CylinderMesh.new()
	under.top_radius = ARENA_R + 0.6
	under.bottom_radius = 1.5
	under.height = 9.0
	under.radial_segments = 16
	_mesh(under, Vector3(0, -5.5, 0), rockm)
	var clouds := PlaneMesh.new()
	clouds.size = Vector2(300, 300)
	var cm := ShaderMaterial.new()
	cm.shader = preload("res://shaders/cloud_sea.gdshader")
	_mesh(clouds, Vector3(0, -9.0, 0), cm)
	var rng := RandomNumberGenerator.new()
	rng.seed = 21 + room_i * 13
	var marble := _mat(Color(0.93, 0.94, 0.97), 0.0, 0.35)
	var gold := _mat(Color(0.95, 0.8, 0.42), 0.9, 0.35)
	# kenarda ikiz sütunlar (çift çift), aralarında süzülen cıva küreleri
	for i in 6:
		var a := TAU * (float(i) + 0.5) / 6.0
		var dir := Vector3(cos(a), 0, sin(a))
		var tang := Vector3(-dir.z, 0, dir.x)
		var base := dir * (ARENA_R + 0.3)
		var h := 3.2 + float(i % 2) * 0.8
		for sgn: float in [-1.0, 1.0]:
			var p := base + tang * sgn * 0.75
			var c := CylinderMesh.new()
			c.top_radius = 0.22
			c.bottom_radius = 0.26
			c.height = h
			_mesh(c, p + Vector3(0, h * 0.5, 0), marble)
			var cap := BoxMesh.new()
			cap.size = Vector3(0.62, 0.14, 0.62)
			_mesh(cap, p + Vector3(0, h + 0.07, 0), gold)
		_mesh(_sphere(0.2), base + Vector3(0, h * 0.7, 0), _glow(Color(0.75, 0.85, 1.0) if i % 2 == 0 else Color(1.0, 0.85, 0.55), 3.0))
	# arkada ikiz kuleler: Kastor (mavi) ve Polluks (altın)
	var back := Vector3(-1, 0, -1).normalized()
	var side := Vector3(1, 0, -1).normalized()
	for sgn: float in [-1.0, 1.0]:
		var p := back * (ARENA_R + 16.0) + side * sgn * 7.0
		var col := Color(0.6, 0.8, 1.0) if sgn < 0.0 else Color(1.0, 0.8, 0.45)
		var tw := CylinderMesh.new()
		tw.top_radius = 1.2
		tw.bottom_radius = 2.0
		tw.height = 34.0
		tw.radial_segments = 12
		_mesh(tw, p + Vector3(0, 6.0, 0), marble)
		for k in 4:
			var band := TorusMesh.new()
			band.inner_radius = 1.6 - float(k) * 0.08
			band.outer_radius = 1.8 - float(k) * 0.08
			_mesh(band, p + Vector3(0, float(k) * 7.0 - 2.0, 0), gold)
		var spire := CylinderMesh.new()
		spire.top_radius = 0.0
		spire.bottom_radius = 1.3
		spire.height = 5.0
		_mesh(spire, p + Vector3(0, 25.5, 0), gold)
		_mesh(_sphere(0.9), p + Vector3(0, 28.8, 0), _glow(col, 5.0))
	# uçan kaya adacıkları
	for i in 10:
		var a := rng.randf() * TAU
		var d := rng.randf_range(22.0, 55.0)
		var r := rng.randf_range(1.2, 3.5)
		var rk := _mesh(_sphere(r), Vector3(cos(a) * d, rng.randf_range(-6.0, 8.0), sin(a) * d), rockm)
		rk.scale = Vector3(1.3, 0.7, 1.1)
	_wind()


## Arenayı yatay geçen rüzgâr çizgileri ve tüyler
func _wind() -> void:
	var em := CPUParticles3D.new()
	em.amount = 40
	em.lifetime = 2.4
	em.preprocess = 2.4
	em.position = Vector3(-ARENA_R - 8.0, 2.0, 0)
	em.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	em.emission_box_extents = Vector3(1.0, 2.0, ARENA_R + 6.0)
	em.direction = Vector3(1, 0.05, 0.2)
	em.spread = 6.0
	em.gravity = Vector3.ZERO
	em.initial_velocity_min = 10.0
	em.initial_velocity_max = 15.0
	var q := QuadMesh.new()
	q.size = Vector2(1.6, 0.03)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.albedo_color = Color(1, 1, 1, 0.35)
	m.billboard_mode = BaseMaterial3D.BILLBOARD_DISABLED
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	q.material = m
	em.mesh = q
	add_child(em)


# ---------------------------------------------------------------- BOĞA OTLAKLARI ortamı

func _environment_taurus() -> void:
	# altın saat: sıcak şeftali ufuk, yukarıda alacakaranlık mavisi; hafif pus
	var psky := ProceduralSkyMaterial.new()
	psky.sky_top_color = Color(0.2, 0.26, 0.5)
	psky.sky_horizon_color = Color(1.0, 0.72, 0.5)
	psky.sky_curve = 0.15
	psky.ground_horizon_color = Color(0.75, 0.62, 0.45)
	psky.ground_bottom_color = Color(0.15, 0.22, 0.08)
	psky.sun_angle_max = 10.0
	psky.sun_curve = 0.1
	var sky := Sky.new()
	sky.sky_material = psky
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.62, 0.58, 0.5)
	env.ambient_light_energy = 0.8
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.glow_enabled = true
	env.glow_intensity = 0.5
	env.glow_bloom = 0.0
	env.glow_hdr_threshold = 1.3
	env.ssao_enabled = true
	env.fog_enabled = true
	env.fog_light_color = Color(0.85, 0.7, 0.55)
	env.fog_light_energy = 0.7
	env.fog_density = 0.006
	env.fog_sky_affect = 0.3
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.light_color = Color(1.0, 0.82, 0.6)
	sun.light_energy = 1.15
	sun.shadow_enabled = not GameData.is_web()
	sun.rotation_degrees = Vector3(-28, 160, 0)
	add_child(sun)
	var fill := DirectionalLight3D.new()
	fill.light_color = Color(0.55, 0.7, 1.0)
	fill.light_energy = 0.2
	fill.rotation_degrees = Vector3(-50, -30, 0)
	add_child(fill)
	# gökte Ülker (Yedi Kızkardeşler) ve kızıl Aldebaran
	var back := Vector3(-1, 0, -1).normalized()
	var center := back * 120.0 + Vector3(0, 55, 0)
	var pl := [Vector2(0, 0), Vector2(3, 1.2), Vector2(5.5, -0.5), Vector2(2.5, -2.6), Vector2(-2.5, -1.2), Vector2(7.5, 1.8), Vector2(1, 3.2)]
	var side := Vector3(1, 0, -1).normalized()
	for v in pl:
		var vv: Vector2 = v
		_mesh(_sphere(0.6), center + side * vv.x * 1.6 + Vector3(0, vv.y * 1.6, 0), _glow(Color(0.75, 0.88, 1.0), 6.0))
	_mesh(_sphere(1.0), center - side * 22.0 - Vector3(0, 14, 0), _glow(Color(1.0, 0.35, 0.2), 6.0))


func _arena_taurus() -> void:
	# çimenli yayla
	var top := CylinderMesh.new()
	top.top_radius = ARENA_R + 0.6
	top.bottom_radius = ARENA_R + 1.0
	top.height = 1.0
	top.radial_segments = 96
	var fm := ShaderMaterial.new()
	fm.shader = preload("res://shaders/taurus_floor.gdshader")
	_mesh(top, Vector3(0, -0.5, 0), fm)
	var earth := CylinderMesh.new()
	earth.top_radius = ARENA_R + 1.0
	earth.bottom_radius = ARENA_R + 6.0
	earth.height = 4.0
	earth.radial_segments = 24
	_mesh(earth, Vector3(0, -3.0, 0), _mat(Color(0.3, 0.22, 0.13), 0.0, 1.0))
	# aşağıdaki geniş vadi
	var plain := PlaneMesh.new()
	plain.size = Vector2(260, 260)
	var mm := ShaderMaterial.new()
	mm.shader = preload("res://shaders/meadow.gdshader")
	_mesh(plain, Vector3(0, -5.0, 0), mm)
	var rng := RandomNumberGenerator.new()
	rng.seed = 13 + room_i * 17
	var stone := _mat(Color(0.5, 0.48, 0.44), 0.0, 0.95)
	var moss := _mat(Color(0.25, 0.4, 0.14), 0.0, 1.0)
	var leaf := _mat(Color(0.14, 0.3, 0.09), 0.0, 0.9)
	var rose := _glow(Color(1.0, 0.45, 0.65), 0.6)
	# kenarda menhir çemberi ve aralarında gül çalıları
	for i in 14:
		var a := TAU * (float(i) + rng.randf_range(0.3, 0.7)) / 14.0
		var p := Vector3(cos(a), 0, sin(a)) * (ARENA_R + rng.randf_range(0.4, 0.9))
		if i % 2 == 0:
			var h := rng.randf_range(2.0, 3.6)
			var bx := BoxMesh.new()
			bx.size = Vector3(rng.randf_range(0.7, 1.0), h, rng.randf_range(0.45, 0.6))
			var mi := _mesh(bx, p + Vector3(0, h * 0.5 - 0.2, 0), stone)
			mi.rotation = Vector3(rng.randf_range(-0.08, 0.08), a + PI * 0.5, rng.randf_range(-0.1, 0.1))
			var cap := _mesh(_sphere(0.4), p + Vector3(0, h - 0.1, 0), moss)
			cap.scale = Vector3(1.4, 0.35, 1.0)
		else:
			for k in 4:
				var bp := p + Vector3(rng.randf_range(-0.5, 0.5), 0.35 + rng.randf() * 0.3, rng.randf_range(-0.5, 0.5))
				_mesh(_sphere(rng.randf_range(0.35, 0.5)), bp, leaf)
			for k in 6:
				var fp := p + Vector3(rng.randf_range(-0.6, 0.6), 0.6 + rng.randf() * 0.4, rng.randf_range(-0.6, 0.6))
				_mesh(_sphere(0.1), fp, rose)
	# arkada taştan dev boğa boynuzları (♉ hilali)
	var back := Vector3(-1, 0, -1).normalized()
	var side := Vector3(1, 0, -1).normalized()
	var base := back * (ARENA_R + 8.0) + Vector3(0, -3.0, 0)
	for k in 30:
		var u := float(k) / 29.0
		var ang := lerpf(-PI * 0.95, -PI * 0.05, u)
		var p := base + side * cos(ang) * 8.5 + Vector3(0, 6.5 + sin(ang) * -6.5, 0)
		var th := lerpf(0.35, 1.1, 1.0 - absf(u - 0.5) * 2.0)
		_mesh(_sphere(th), p, stone)
	# uzakta tepeler ve çiçek açmış ağaçlar
	var hill := _mat(Color(0.22, 0.38, 0.12), 0.0, 1.0)
	for i in 9:
		var a := TAU * float(i) / 9.0 + rng.randf_range(-0.2, 0.2)
		var d := rng.randf_range(55.0, 85.0)
		var hm := _mesh(_sphere(rng.randf_range(14.0, 24.0)), Vector3(cos(a) * d, -9.0, sin(a) * d), hill)
		hm.scale = Vector3(1.6, 0.55, 1.3)
	var trunk := _mat(Color(0.3, 0.2, 0.12), 0.0, 0.9)
	var bloom := _mat(Color(1.0, 0.72, 0.82), 0.0, 0.8)
	for i in 8:
		var a := TAU * (float(i) + 0.3) / 8.0 + rng.randf_range(-0.15, 0.15)
		var d := rng.randf_range(17.0, 26.0)
		var p := Vector3(cos(a) * d, -4.6, sin(a) * d)
		var tc := CylinderMesh.new()
		tc.top_radius = 0.2
		tc.bottom_radius = 0.35
		tc.height = 4.0
		_mesh(tc, p + Vector3(0, 2.0, 0), trunk)
		for k in 5:
			_mesh(_sphere(rng.randf_range(1.0, 1.6)), p + Vector3(rng.randf_range(-1.2, 1.2), 4.4 + rng.randf() * 1.2, rng.randf_range(-1.2, 1.2)), bloom)
	# Venüs fenerleri (yumuşak yeşil-altın ışık)
	for i in 4:
		var a := TAU * (float(i) + 0.5) / 4.0
		var p := Vector3(cos(a), 0, sin(a)) * (ARENA_R + 0.2)
		var pole := CylinderMesh.new()
		pole.top_radius = 0.06
		pole.bottom_radius = 0.1
		pole.height = 2.2
		_mesh(pole, p + Vector3(0, 1.1, 0), _mat(Color(0.55, 0.42, 0.22), 0.8, 0.4))
		_mesh(_sphere(0.22), p + Vector3(0, 2.35, 0), _glow(Color(0.8, 1.0, 0.55), 3.0))
		var l := OmniLight3D.new()
		l.light_color = Color(0.85, 1.0, 0.6)
		l.light_energy = 0.9
		l.omni_range = 6.0
		l.position = p + Vector3(0, 2.4, 0)
		add_child(l)
	_petals()


## Rüzgârla süzülen pembe taç yaprakları ve polen
func _petals() -> void:
	var em := CPUParticles3D.new()
	em.amount = 60
	em.lifetime = 7.0
	em.preprocess = 7.0
	em.position = Vector3(0, 7.0, 0)
	em.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	em.emission_box_extents = Vector3(ARENA_R + 8.0, 1.0, ARENA_R + 8.0)
	em.direction = Vector3(1, -0.4, 0.3)
	em.spread = 30.0
	em.gravity = Vector3(0.3, -0.5, 0.15)
	em.initial_velocity_min = 0.5
	em.initial_velocity_max = 1.4
	em.angular_velocity_min = -180.0
	em.angular_velocity_max = 180.0
	em.scale_amount_min = 0.6
	em.scale_amount_max = 1.2
	var q := QuadMesh.new()
	q.size = Vector2(0.14, 0.1)
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(1.0, 0.7, 0.8)
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	q.material = m
	em.mesh = q
	add_child(em)


## Taş kaide üstünde yanan mangal (titrek turuncu ışık)
func _brazier(p: Vector3) -> void:
	var bowl := CylinderMesh.new()
	bowl.top_radius = 0.55
	bowl.bottom_radius = 0.25
	bowl.height = 0.4
	var stand := CylinderMesh.new()
	stand.top_radius = 0.2
	stand.bottom_radius = 0.35
	stand.height = 1.0
	var iron := _mat(Color(0.16, 0.12, 0.1), 0.6, 0.5)
	_mesh(stand, p + Vector3(0, 0.5, 0), iron)
	_mesh(bowl, p + Vector3(0, 1.2, 0), iron)
	var fire := CPUParticles3D.new()
	fire.amount = 26
	fire.lifetime = 0.7
	fire.position = p + Vector3(0, 1.4, 0)
	fire.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	fire.emission_sphere_radius = 0.3
	fire.direction = Vector3.UP
	fire.spread = 12.0
	fire.gravity = Vector3(0, 2.5, 0)
	fire.initial_velocity_min = 0.6
	fire.initial_velocity_max = 1.4
	fire.scale_amount_min = 0.5
	fire.scale_amount_max = 1.0
	var q := QuadMesh.new()
	q.size = Vector2(0.4, 0.4)
	var fmat := _glow(Color(1.0, 0.5, 0.12), 4.0)
	fmat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	fmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fmat.vertex_color_use_as_albedo = true
	q.material = fmat
	fire.mesh = q
	var grad := Gradient.new()
	grad.set_color(0, Color(1.0, 0.85, 0.4, 1.0))
	grad.set_color(1, Color(0.9, 0.15, 0.02, 0.0))
	fire.color_ramp = grad
	var curve := Curve.new()
	curve.add_point(Vector2(0, 1))
	curve.add_point(Vector2(1, 0.2))
	fire.scale_amount_curve = curve
	add_child(fire)
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.55, 0.2)
	l.light_energy = 1.2
	l.omni_range = 6.0
	l.position = p + Vector3(0, 1.8, 0)
	l.set_meta("flicker", randf() * 10.0)
	add_child(l)
	_flames.append(l)


## Sarmal koç boynuzu: incelen, kendi etrafında kıvrılan boğumlu kemik
func _horn(base: Vector3, sgn: float, k: float) -> void:
	var root := Node3D.new()
	root.position = base
	add_child(root)
	root.look_at_from_position(base, Vector3(0, base.y, 0), Vector3.UP)
	var bone := _mat(Color(0.72, 0.62, 0.48), 0.0, 0.75)
	var ridge := _mat(Color(0.5, 0.42, 0.32), 0.0, 0.85)
	var n := 34
	for i in n:
		var t := float(i) / float(n - 1)
		var ang := t * TAU * 1.25
		var r := (1.0 - t * 0.72) * 1.6 * k
		var p := Vector3(sgn * (sin(ang) * r), 1.6 * k + cos(ang) * r - (1.0 - t) * 0.4 * k, -t * 1.2 * k)
		var th := lerpf(0.62, 0.1, t) * k
		_mesh(_sphere(th), p, bone if i % 3 != 0 else ridge, root)


## Havada süzülen kül ve yukarı uçan kıvılcımlar
func _embers(heat: float) -> void:
	var em := CPUParticles3D.new()
	em.amount = int(25 * heat)
	em.lifetime = 5.0
	em.preprocess = 5.0
	em.position = Vector3(0, -1.0, 0)
	em.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	em.emission_box_extents = Vector3(ARENA_R + 6.0, 0.5, ARENA_R + 6.0)
	em.direction = Vector3(0.3, 1, 0.1)
	em.spread = 25.0
	em.gravity = Vector3(0.2, 0.6, 0)
	em.initial_velocity_min = 0.6
	em.initial_velocity_max = 1.6
	em.scale_amount_min = 0.4
	em.scale_amount_max = 1.0
	var q := QuadMesh.new()
	q.size = Vector2(0.07, 0.07)
	var m := _glow(Color(1.0, 0.55, 0.15), 5.0)
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.vertex_color_use_as_albedo = true
	q.material = m
	em.mesh = q
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.15, 1.0])
	grad.colors = PackedColorArray([Color(1, 0.8, 0.4, 0.0), Color(1, 0.7, 0.3, 1.0), Color(0.8, 0.2, 0.05, 0.0)])
	em.color_ramp = grad
	add_child(em)


func _sphere(r: float) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	return s


# ---------------------------------------------------------------- akış

func _process(delta: float) -> void:
	_t += delta
	if hero2 != null:
		_coop_tick(delta)
	for l in _flames:
		var ph: float = l.get_meta("flicker")
		l.light_energy = 1.1 + 0.25 * sin(_t * 9.0 + ph) + 0.15 * sin(_t * 23.0 + ph * 2.0)
	hud.dust = GameData.stardust
	hud.wave = wave + 1
	hud.cleared = cleared   # T-29: oda temizlenince DALGA yazısı gizlenir
	if tc != null:
		# T-29: kapılar çıkmış ve canlı düşman yokken saldırı yayı sönük ve dokunulmaz
		tc.combat_idle = not doors.is_empty() and get_tree().get_node_count_in_group("enemies") == 0
	if Net.is_client():
		return   # client: dalgalar, kapılar ve ödüller host'ta işler
	if ended:
		return
	if not cleared and not is_boss and alive <= 0 and pending <= 0:
		_next_wave_t -= delta
		if _next_wave_t <= 0.0:
			if wave + 1 < waves.size():
				wave += 1
				_spawn_wave(waves[wave])
				_next_wave_t = 1.2
			else:
				_on_cleared()

	_tick_hints()
	# kapılar
	var near = null
	var best := 2.6
	var p2_near := false
	for d in doors:
		var dp: Vector3 = d["pos"]
		for h in ([hero, hero2] if hero2 != null else [hero]):
			if h.dead:
				continue
			var dist := Vector2(h.global_position.x - dp.x, h.global_position.z - dp.z).length()
			if dist < best:
				best = dist
				near = d
				p2_near = h == hero2
	# E kuralı (GDD §8): kapı menzilindeki kahramanda klavye E'si yalnızca etkileşimdir
	for h in ([hero, hero2] if hero2 != null else [hero]):
		var hn := false
		for d in doors:
			var dp2: Vector3 = d["pos"]
			if Vector2(h.global_position.x - dp2.x, h.global_position.z - dp2.z).length() < 2.6:
				hn = true
		h.interact_near = hn
	hud.prompt = String(near["title"]) if near != null else ""
	if near != null:
		hud.prompt_glyph = String(near["glyph"])
		hud.prompt_color = near["color"]
	if near != null and (Input.is_action_just_pressed("interact") or (p2_near and hero2._jp("interact"))):
		_enter_door(String(near["type"]))

	if Input.is_action_just_pressed("pause") and not pause_ui.visible and not boon_ui.visible:
		pause_ui.open()


func _spawn_wave(kinds_in: Array) -> void:
	# önce yakın dövüşçüler, sonra arkadan büyücüler
	var kinds: Array = []
	for k in kinds_in:
		if String(k) != "caster":
			kinds.append(k)
	for k in kinds_in:
		if String(k) == "caster":
			kinds.append(k)
	for i in kinds.size():
		var pos := Vector3.ZERO
		for tries in 20:
			var a := randf() * TAU
			var r := randf_range(3.5, ARENA_R - 1.5)
			pos = Vector3(cos(a) * r, 0, sin(a) * r)
			if pos.distance_to(hero.global_position) > 4.5:
				break
		pending += 1
		_spawn_marker(pos, 0.3 + float(i) * 0.25 + (0.9 if String(kinds[i]) == "caster" else 0.0), String(kinds[i]))


## Doğuştan önce yerde mor-kızıl bir halka belirir (nereden geleceğini gösterir)
func _spawn_marker(pos: Vector3, delay: float, kind: String) -> void:
	var ring := Skills.ring(0.9, Color(0.75, 0.55, 1.0, 0.9))   # mor-beyaz: kızıl canavar ve uyarılardan ayrı
	ring.position = pos + Vector3(0, 0.05, 0)
	ring.scale = Vector3(0.2, 0.1, 0.2)
	add_child(ring)
	var tw := ring.create_tween()
	tw.tween_interval(delay)
	tw.tween_callback(func(): Juice.constellation_spawn(self, pos, Color(0.75, 0.6, 1.0), 0.8))
	tw.tween_property(ring, "scale", Vector3(1.0, 0.1, 1.0), 0.7).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_callback(_spawn_enemy.bind(pos, kind))
	tw.tween_property(ring, "scale", Vector3(1.4, 0.1, 1.4), 0.4)
	tw.tween_callback(ring.queue_free)


func _spawn_enemy(pos: Vector3, kind: String) -> void:
	if ended:
		return
	pending -= 1
	var e = EnemyScript.new()
	e.kind = kind
	e.zone = _mixed_zone()
	e.room_zone = zone
	e.room_local = local_i
	e.hero = hero
	_tune_enemy(e)
	var di := mini(local_i, 3)
	var rt: Dictionary = GameData.retro
	var elite_ch := float(_zt(ELITE_CHANCE, ELITE_CHANCE_T, ELITE_CHANCE_G, ELITE_CHANCE_C, ELITE_CHANCE_L, ELITE_CHANCE_V, ELITE_CHANCE_B, ELITE_CHANCE_S, ELITE_CHANCE_Y, ELITE_CHANCE_K, ELITE_CHANCE_Q, ELITE_CHANCE_P)[di]) + 0.15 * float(Retro.rank(rt, "moon")) + 0.1 * float(GameData.run_cycle)
	if room_i >= 1 or Retro.rank(rt, "moon") > 0:
		# seçkin sınırı: bölgenin 1. odasında en fazla 1, diğer odalarda en fazla 2 (GDD §13.3)
		var cap := 1 if local_i == 0 else 2
		if _elites < cap:
			e.elite = randf() < elite_ch
			if e.elite:
				_elites += 1
	if e.elite and room_i >= 2:
		# ortak seçkin özellikleri: Koç-İkizler'de tek, Yengeç'ten itibaren iki (odanın bölgesine göre)
		var pool: Array = ["shielded", "swift", "splitting", "healer", "volatile", "phantom"]
		pool.shuffle()
		var n := 2 if ZONE_ORDER.find(zone) >= 3 else 1
		e.affixes = pool.slice(0, n)
		for af in e.affixes:
			_affix_hint(String(af))
	e._bounds = ARENA_R - 0.5
	add_child(e)
	e.global_position = pos
	var to: Vector3 = hero.global_position - pos
	if to.length() > 0.1:
		e._face = to.normalized()
	e.killed.connect(_on_killed)
	alive += 1
	Sfx.play("enemyattack", -14.0, 0.1, 120, 1.0)
	# İkiz Gölgeler çift olarak eşleşir
	if (e.zone == "gemini" or e.zone == "libra") and kind == "shade":
		if _lonely != null and is_instance_valid(_lonely) and not _lonely.dead:
			e.partner = _lonely
			_lonely.partner = e
			_lonely = null
		else:
			_lonely = e


## REHBERLİK (GDD §19.2): seçkin özelliği ilk kez görülünce bir kerelik kart
const AFFIX_HINT := {"shielded": "A ward absorbs damage first. Break it, then strike.",
	"swift": "Faster and quicker to attack. Watch its warnings closely.",
	"splitting": "Splits into two small copies when it dies.",
	"healer": "Heals nearby foes. Take it down first.",
	"volatile": "Explodes after death. Step out of the ring.",
	"phantom": "Turns invisible while it hunts you."}


func _affix_hint(af: String) -> void:
	var key := "affix:" + af
	if bool(GameData.hints.get(key, false)) or not AFFIX_HINT.has(af):
		return
	GameData.mark_hint(key)
	hud.show_hint(String(EnemyScript.AFFIX_NAMES.get(af, af)), String(AFFIX_HINT[af]), EnemyScript.AFFIX_COLS.get(af, UI.GOLD), 6.0)


## REHBERLİK (§19.2 element, §19.3 kapılar): her karede kontrol
var _door_hint := false


func _tick_hints() -> void:
	if not bool(GameData.hints.get("mirror", false)):
		for e in get_tree().get_nodes_in_group("enemies"):
			if e.has_method("mirror_up") and e.mirror_up():
				GameData.mark_hint("mirror")
				hud.show_hint("MIRROR GUARD", "While its mirror is up, light hits bounce back. A heavy attack shatters it.", EnemyScript.MIRROR_COL, 7.0)
				break
	if not bool(GameData.hints.get("elements", false)) and hud.zone_el != "" and GameData.hero_el != "":
		if Elements.mult(GameData.hero_el, GameData.hero_el_n, hud.zone_el) != 1.0:
			GameData.mark_hint("elements")
			hud.show_hint("ELEMENTS", "Water beats Fire, Fire beats Air, Air beats Earth, Earth beats Water. Your blessings set your element.", UI.GOLD, 7.0)
	if not _door_hint and not doors.is_empty() and not bool(GameData.hints.get("doors", false)):
		# T-29: ipucu HUD'da, ODA şeridinin altında (dünyada değil)
		_door_hint = true
		hud.door_hint = "Each gate's symbol shows its reward. Choose your path."


const ZONE_ORDER := ["aries", "taurus", "gemini", "cancer", "leo", "virgo", "libra", "scorpio", "sagittarius", "capricorn", "aquarius", "pisces"]


## KARIŞIK GRUPLAR: ileri bölgelerde yaratıkların ~%25'i önceki bölgelerden tanıdık yüzler olur
func _mixed_zone() -> String:
	var zi := ZONE_ORDER.find(zone)
	if zi <= 0 or randf() > 0.25:
		return zone
	return String(ZONE_ORDER[randi() % zi])


## Derinliğe ve retro lanetlerine göre güç çarpanları
func _tune_enemy(e) -> void:
	var di := mini(local_i, 3)
	if is_boss:
		di = 0   # §13.4: boss odasındaki yardımcılar bölgenin 1. oda çarpanlarını alır (BOSS_DMG almaz)
	var rt: Dictionary = GameData.retro
	var hpm: float = float(_zt(HP_MULT, HP_MULT_T, HP_MULT_G, HP_MULT_C, HP_MULT_L, HP_MULT_V, HP_MULT_B, HP_MULT_S, HP_MULT_Y, HP_MULT_K, HP_MULT_Q, HP_MULT_P)[di])
	var dmm: float = float(_zt(DMG_MULT, DMG_MULT_T, DMG_MULT_G, DMG_MULT_C, DMG_MULT_L, DMG_MULT_V, DMG_MULT_B, DMG_MULT_S, DMG_MULT_Y, DMG_MULT_K, DMG_MULT_Q, DMG_MULT_P)[di])
	e.hp_mult = hpm * (1.0 + 0.25 * float(Retro.rank(rt, "jupiter"))) * (1.15 if GameData.run_rising == "leo" else 1.0) * _cyc_hp()
	e.dmg_mult = dmm * (1.0 + 0.2 * float(Retro.rank(rt, "mars"))) * _cyc_dmg()
	if hero2 != null:
		e.hp_mult *= 1.5   # İKİZLER: iki kahramana karşı düşmanlar daha dayanıklı
	e.windup_mult = 1.0 - 0.12 * float(Retro.rank(rt, "pluto"))


## Bölgeye göre tablo seçer
func _zt(a: Array, t: Array, g: Array, c: Array, l: Array, v: Array, b: Array, sc: Array, y: Array, k: Array, q: Array, pp: Array) -> Array:
	if zone == "pisces":
		return pp
	if zone == "aquarius":
		return q
	if zone == "capricorn":
		return k
	if zone == "sagittarius":
		return y
	if zone == "scorpio":
		return sc
	if zone == "libra":
		return b
	if zone == "virgo":
		return v
	if zone == "leo":
		return l
	if zone == "cancer":
		return c
	if zone == "gemini":
		return g
	if zone == "taurus":
		return t
	return a


func _on_killed(e) -> void:
	alive -= 1
	var ak := String(e.zone) + ":" + String(e.kind)
	GameData.almanac[ak] = int(GameData.almanac.get(ak, 0)) + 1
	Ach.bump("kills")
	if GameData.almanac[ak] == 1:
		Ach.check_almanac()
	# Taş Golem ölünce 2 taşçığa bölünür
	if String(e.zone) == "taurus" and String(e.kind) == "brute" and not bool(e.get("pebble")) and not ended and not victory:
		for i in 2:
			var a := randf() * TAU
			_spawn_pebble(e.global_position + Vector3(cos(a), 0, sin(a)) * 0.9)
	if not ended and not victory:
		if e.affixes.has("splitting"):
			for i in 2:
				var a2 := randf() * TAU
				_spawn_mini(e, e.global_position + Vector3(cos(a2), 0, sin(a2)) * 0.9)
		if e.affixes.has("volatile"):
			var b := HZ.Blast.new()
			b.hero = hero
			b.radius = 2.3
			b.delay = 0.9
			b.dmg = float(VOLATILE_DMG.get(zone, 14.0)) * float(e.dmg_mult)   # §13.8
			b.col = Color(1.0, 0.45, 0.2)
			add_child(b)
			b.global_position = Vector3(e.global_position.x, 0.0, e.global_position.z)
	var p: Vector3 = e.global_position + Vector3(0, 1.0, 0)
	var total: int = DUST_BY_KIND.get(String(e.kind), 5)
	if e.get("elite") == true:
		total *= 3
	_drop_dust(p, total)


## Bölünen seçkinin küçük kopyası
func _spawn_mini(src, pos: Vector3) -> void:
	var e = EnemyScript.new()
	e.kind = String(src.kind)
	e.zone = String(src.zone)
	e.mini = true
	e.room_zone = zone
	e.room_local = local_i
	e.hero = hero
	_tune_enemy(e)
	e._bounds = ARENA_R - 0.5
	add_child(e)
	e.global_position = HZ.clamp_arena(pos, ARENA_R - 1.0)
	e.killed.connect(_on_killed)
	alive += 1


func _spawn_pebble(pos: Vector3) -> void:
	var fl := Vector2(pos.x, pos.z)
	if fl.length() > ARENA_R - 1.0:
		fl = fl.normalized() * (ARENA_R - 1.0)
	var e = EnemyScript.new()
	e.kind = "shade"
	e.zone = "taurus"
	e.pebble = true
	e.room_zone = zone
	e.room_local = local_i
	e.hero = hero
	_tune_enemy(e)
	e._bounds = ARENA_R - 0.5
	add_child(e)
	e.global_position = Vector3(fl.x, 0.0, fl.y)
	e.killed.connect(_on_killed)
	alive += 1


func _drop_dust(p: Vector3, amount: int) -> void:
	var total := int(round(float(amount) * (1.0 + float(hero.st["dust_gain"]) / 100.0)))
	var n := clampi(total, 1, 8)
	for i in n:
		_mote(p, total / n + (1 if i < total % n else 0))


## Yıldız tozu zerresi: önce saçılır, sonra kahramana uçar ve toplanır
func _mote(p: Vector3, value: int) -> void:
	var m := MeshInstance3D.new()
	m.mesh = _sphere(0.09)
	m.material_override = _glow(Color(1.0, 0.92, 0.65), 6.0)
	add_child(m)
	m.global_position = p
	var v := Vector3(randf_range(-1, 1), randf_range(1.5, 3.0), randf_range(-1, 1)) * 2.0
	m.set_meta("v", v)
	m.set_meta("t", 0.0)
	m.set_meta("value", value)
	m.add_to_group("motes")


func _physics_process(delta: float) -> void:
	if Net.is_client():
		return
	_tick_hazards(delta)
	for m in get_tree().get_nodes_in_group("motes"):
		var t := float(m.get_meta("t")) + delta
		m.set_meta("t", t)
		var v: Vector3 = m.get_meta("v")
		if t < 0.45:
			v = v.move_toward(Vector3.ZERO, 9.0 * delta)
		else:
			var to: Vector3 = hero.global_position + Vector3(0, 1.0, 0) - m.global_position
			v = v.lerp(to.normalized() * (8.0 + t * 10.0), minf(6.0 * delta, 1.0))
			if to.length() < 0.6:
				var val := int(m.get_meta("value"))
				GameData.stardust += val
				GameData.run_dust += val
				earned += val
				Sfx.play("coin", -16.0, 0.1, 40, 1.4)
				m.queue_free()
				continue
		m.set_meta("v", v)
		m.global_position += v * delta


# ---------------------------------------------------------------- BÖLGE TEHLİKELERİ (normal odalar)
## Her bölgenin kendi doğal tehlikesi dövüş sürerken arada bir devreye girer; boss'takinden hafiftir.
##  Koç: zeminden lav fışkırır · Boğa: diken tarlası (yavaşlatır) · İkizler: rüzgâr seni iter
##  Yengeç: gelgit kıyıyı basar (iç daire güvenli) · Aslan: Zenit (gölgelere saklan) · Başak: dama ızgarası

const HZ = preload("res://scripts/hazards.gd")
const HAZARD_EVERY := {"aries": 11.0, "taurus": 10.0, "gemini": 10.0, "cancer": 13.0, "leo": 15.0, "virgo": 12.0, "libra": 11.0, "scorpio": 10.0, "sagittarius": 9.0, "capricorn": 8.5, "aquarius": 8.0, "pisces": 7.5}   # GDD §13.5
const HAZARD_DMG := {"aries": 1.0, "taurus": 1.15, "gemini": 1.3, "cancer": 1.45, "leo": 1.6, "virgo": 1.75, "libra": 1.9, "scorpio": 2.0, "sagittarius": 2.1, "capricorn": 2.25, "aquarius": 2.4, "pisces": 2.55}
var _hazard_t := 6.0


func _tick_hazards(delta: float) -> void:
	if room_i < 2:
		return   # ilk iki oda tehlikesiz: oyuncu kontrollere alışsın
	if is_boss or is_rest or cleared or ended or hero == null or hero.dead:
		return
	if wave < 0 or alive <= 0:
		return
	_hazard_t -= delta
	if _hazard_t > 0.0:
		return
	_hazard_t = float(HAZARD_EVERY.get(zone, 8.0)) * randf_range(0.85, 1.15)
	var k := float(HAZARD_DMG.get(zone, 1.0)) * (1.0 + 0.12 * float(local_i))
	var hp: Vector3 = hero.global_position
	match zone:
		"aries":
			# lav fışkırması: biri ayağının dibinde, ikisi rastgele; yerde kısa süre yanan iz
			for i in 3:
				var p := hp + Vector3(randf_range(-1.5, 1.5), 0, randf_range(-1.5, 1.5)) if i == 0 else Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized() * randf_range(2.0, ARENA_R - 1.5)
				var b := HZ.Blast.new()
				b.hero = hero
				b.radius = 1.6
				b.delay = 1.3 + float(i) * 0.25
				b.dmg = 10.0 * k
				b.col = Color(1.0, 0.4, 0.1)
				b.pool_life = 2.0
				add_child(b)
				b.global_position = HZ.clamp_arena(p, ARENA_R - 0.5)
		"taurus":
			# diken tarlası: yavaşlatan dikenler, arkasında yavaşlatan çalılık
			for i in 3:
				var p2 := hp + Vector3(randf_range(-3.0, 3.0), 0, randf_range(-3.0, 3.0))
				var b2 := HZ.Blast.new()
				b2.hero = hero
				b2.radius = 1.7
				b2.delay = 1.4
				b2.dmg = 8.0 * k
				b2.col = Color(0.5, 1.0, 0.35)
				b2.eff = "slow"
				b2.pool_life = 3.0
				add_child(b2)
				b2.global_position = HZ.clamp_arena(p2, ARENA_R - 0.5)
		"gemini":
			var a := randf() * TAU
			var g := HZ.Gust.new()
			g.hero = hero
			g.dir = Vector3(cos(a), 0, sin(a))
			g.bounds = ARENA_R
			g.strength = 3.0 + 0.3 * float(local_i)
			add_child(g)
		"cancer":
			var fl := CancerScript.Flood.new()
			fl.hero = hero
			var c := Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized() * randf_range(0.0, 4.0)
			fl.center = c
			fl.safe_r = 5.8
			fl.bounds = ARENA_R + 2.0
			fl.dps = 5.0 * k
			fl.hold = 3.0
			add_child(fl)
			hud.banner("", tr("The tide rises — find dry sand"))
		"leo":
			var z := LeoScript.Zenith.new()
			z.hero = hero
			z.bounds = ARENA_R - 0.5
			z.dmg = 12.0 * k
			z.safe_r = 2.3
			add_child(z)
		"pisces":
			# rüya köpüğü: çevrende bir halka köpük belirir, tek boşluktan çık
			var n9 := 8
			var gap9 := randi() % n9
			for i in n9:
				if i == gap9:
					continue
				var a9 := TAU * float(i) / float(n9)
				var b9 := HZ.Blast.new()
				b9.hero = hero
				b9.radius = 1.2
				b9.delay = 1.3
				b9.dmg = 10.0 * k
				b9.col = Color(0.85, 0.65, 1.0)
				add_child(b9)
				b9.global_position = HZ.clamp_arena(hp + Vector3(cos(a9), 0, sin(a9)) * 2.6, ARENA_R - 0.5)
		"aquarius":
			# yıldırım: biri üstüne, biri yakınına (yavaşlatır)
			for i in 2:
				var b8 := HZ.Blast.new()
				b8.hero = hero
				b8.radius = 1.4
				b8.delay = 1.0 + float(i) * 0.35
				b8.dmg = 11.0 * k
				b8.col = Color(0.65, 0.9, 1.0)
				b8.eff = "slow"
				add_child(b8)
				b8.global_position = HZ.clamp_arena(hp + (Vector3.ZERO if i == 0 else Vector3(randf_range(-3.0, 3.0), 0, randf_range(-3.0, 3.0))), ARENA_R - 0.5)
			get_tree().create_timer(1.0).timeout.connect(func(): Fx.flash_light(Vector3(0, 12, 0), Color(0.7, 0.85, 1.0), 4.0, 40.0, 0.15))
		"capricorn":
			# çığ: arenayı boydan boya geçen bir kaya şeridi (uyarılı)
			var a7 := randf() * TAU
			var roll := Vector3(cos(a7), 0, sin(a7))
			var side := Vector3(-roll.z, 0, roll.x)
			var off := side.dot(hp) + randf_range(-1.5, 1.5)
			var ln := HZ.Line.new()
			ln.hero = hero
			ln.dir = roll
			ln.length = ARENA_R * 2.0 + 2.0
			ln.width = 3.4
			ln.delay = 1.3
			ln.dmg = 11.0 * k
			ln.col = Color(0.75, 0.8, 0.85)
			ln.eff = "knock"
			add_child(ln)
			ln.global_position = side * off - roll * (ARENA_R + 1.0)
		"sagittarius":
			# gökten ok yağmuru: biri üstüne, diğerleri çevrene
			for i in 4:
				var p6 := hp + (Vector3.ZERO if i == 0 else Vector3(randf_range(-3.5, 3.5), 0, randf_range(-3.5, 3.5)))
				var b6 := HZ.Blast.new()
				b6.hero = hero
				b6.radius = 1.3
				b6.delay = 1.2 + float(i) * 0.1
				b6.dmg = 9.0 * k
				b6.col = Color(0.75, 0.6, 1.0)
				add_child(b6)
				b6.global_position = HZ.clamp_arena(p6, ARENA_R - 0.5)
		"scorpio":
			# asit fışkırması: zehirli gölcük bırakır
			for i in 2:
				var p5 := hp + Vector3(randf_range(-2.0, 2.0), 0, randf_range(-2.0, 2.0)) if i == 0 else Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized() * randf_range(2.0, ARENA_R - 1.5)
				var b5 := HZ.Blast.new()
				b5.hero = hero
				b5.radius = 1.6
				b5.delay = 1.3
				b5.dmg = 8.0 * k
				b5.col = Color(0.5, 1.0, 0.3)
				b5.eff = "poison"
				b5.pool_life = 3.5
				add_child(b5)
				b5.global_position = HZ.clamp_arena(p5, ARENA_R - 0.5)
		"libra":
			# hüküm: arenanın bir yarısı mahkûm edilir
			var a3 := randf() * TAU
			var dd := Vector3(cos(a3), 0, sin(a3))
			var st3 := 3.6
			var n3 := int(ceil(ARENA_R / st3)) + 1
			for ix in range(-n3, n3 + 1):
				for iz in range(-n3, n3 + 1):
					var hp3 := Vector3(float(ix) * st3, 0, float(iz) * st3)
					if Vector2(hp3.x, hp3.z).length() > ARENA_R or hp3.dot(dd) < 0.8:
						continue
					var b4 := HZ.Blast.new()
					b4.hero = hero
					b4.radius = 2.5
					b4.delay = 1.8
					b4.dmg = 10.0 * k
					b4.col = Color(1.0, 0.6, 0.75)
					add_child(b4)
					b4.global_position = hp3
		"virgo":
			# yarım ızgara: tek renk kareler patlar
			var step := 3.0
			var n := int(ceil(ARENA_R / step)) + 1
			var par := randi() % 2
			for ix in range(-n, n + 1):
				for iz in range(-n, n + 1):
					if (ix + iz + par) % 2 != 0:
						continue
					var gp := Vector3(float(ix) * step, 0, float(iz) * step)
					if Vector2(gp.x, gp.z).length() > ARENA_R:
						continue
					var b3 := HZ.Blast.new()
					b3.hero = hero
					b3.radius = 1.5
					b3.delay = 1.6
					b3.dmg = 10.0 * k
					b3.col = Color(0.35, 1.0, 0.85)
					add_child(b3)
					b3.global_position = gp


# ---------------------------------------------------------------- oda sonu ve ödüller

func _on_cleared() -> void:
	if cleared:
		return
	cleared = true
	# son vuruş: kısa ağır çekim, kamera yakınlaşır, kahramanın çevresinde ışık halkası
	if not is_boss:
		Fx.slowmo(0.3, 0.45)
		Juice.zoom_punch(3.0, 0.5)
		if hero != null and is_instance_valid(hero):
			Juice.ring_wave(self, hero.global_position, Color(1.0, 0.88, 0.6), 6.0, 0.6)
	var bonus: int = ROOM_BONUS[mini(local_i, ROOM_BONUS.size() - 1)]
	if reward == "dust":
		bonus += DUST_REWARD[mini(local_i, DUST_REWARD.size() - 1)]
	if zone == "taurus":
		bonus = int(round(float(bonus) * 1.4))
	elif zone == "gemini":
		bonus = int(round(float(bonus) * 1.8))
	elif zone == "cancer":
		bonus = int(round(float(bonus) * 2.2))
	elif zone == "leo":
		bonus = int(round(float(bonus) * 2.6))
	elif zone == "virgo":
		bonus = int(round(float(bonus) * 3.0))
	elif zone == "libra":
		bonus = int(round(float(bonus) * 3.4))
	elif zone == "scorpio":
		bonus = int(round(float(bonus) * 3.8))
	elif zone == "sagittarius":
		bonus = int(round(float(bonus) * 4.2))
	elif zone == "capricorn":
		bonus = int(round(float(bonus) * 4.6))
	elif zone == "aquarius":
		bonus = int(round(float(bonus) * 5.0))
	elif zone == "pisces":
		bonus = int(round(float(bonus) * 5.5))
	bonus = int(round(float(bonus) * _retro_mult()))
	# AY TAŞI: dövüş odalarından ara sıra düşer
	if not is_rest and not is_boss and randf() < 0.22:
		GameData.moonstones += 1
		Fx.flash_light(hero.global_position + Vector3(0, 2, 0), Color(0.75, 0.85, 1.0), 4.0, 6.0, 0.6)
		get_tree().create_timer(2.2).timeout.connect(func(): if not ended: hud.banner("", tr("+1 Moonstone — Mother Moon will want it")))
	if not is_rest:
		GameData.stardust += bonus
		GameData.run_dust += bonus
		earned += bonus
		hero.room_cleared()
		hud.banner("THE STARS ALIGN", tr("+%d stardust") % earned)
		Sfx.play("coin", -4.0, 0.0, 0, 0.6)
		Fx.flash_light(Vector3(0, 3, 0), Color(1.0, 0.85, 0.5), 6.0, 20.0, 1.0)
	GameData.go_save()
	if reward.begins_with("boon:") and not is_boss:
		await get_tree().create_timer(1.2).timeout
		if not ended:
			boon_ui.open(reward.substr(5))
		return
	if reward == "weapon" and not is_boss and WBoons.can_offer(GameData.chosen_weapon, GameData.run_boons):
		await get_tree().create_timer(1.2).timeout
		if not ended:
			boon_ui.open_weapon(GameData.chosen_weapon)
		return
	_spawn_doors()


func _on_boon_picked(_id: String) -> void:
	Net.sync_boons()
	hero.refresh_stats()
	_spawn_doors()


## Sonraki odaya giden kapılar
func _spawn_doors() -> void:
	var next := local_i + 1
	if next >= BOSS_DEPTH:
		_add_door(Vector3(0, 0, -7.5), "boss")
		return
	var p1 := Boons.random_planet()
	var t2 := "boon:" + Boons.random_planet(p1)
	var r := randf()
	if r < 0.4 and WBoons.can_offer(GameData.chosen_weapon, GameData.run_boons):
		t2 = "weapon"
	elif r < 0.55:
		t2 = "dust"
	elif r < 0.7 and hero.hp < hero.max_hp * 0.75 and Retro.rank(GameData.retro, "venus") == 0:
		t2 = "rest"
	var types := ["boon:" + p1, t2]
	types.shuffle()
	if Retro.rank(GameData.retro, "neptune") > 0:
		# Neptün sisi: tek kapı
		_add_door(Vector3(0, 0, -7.5), String(types[0]))
		return
	_add_door(Vector3(-3.4, 0, -7.5), String(types[0]))
	_add_door(Vector3(3.4, 0, -7.5), String(types[1]))


func _door_info(type: String) -> Dictionary:
	if type.begins_with("boon:"):
		var pl: Dictionary = Boons.PLANETS.get(type.substr(5), Boons.PLANETS["Sun"])
		return {"glyph": pl["glyph"], "color": pl["color"], "label": pl["name"], "title": tr("BLESSING OF %s") % tr(String(pl["name"]))}
	match type:
		"weapon":
			var wi: Dictionary = GameData.weapon_info(GameData.chosen_weapon)
			return {"glyph": "\u2605", "color": wi["color"], "label": "MASTERY", "title": tr("WEAPON MASTERY")}
		"dust":
			return {"glyph": "\u2726", "color": Color(1.0, 0.9, 0.6), "label": "STARDUST", "title": tr("STARDUST")}
		"rest":
			return {"glyph": "\u2665", "color": Color(0.6, 0.95, 0.8), "label": "SANCTUARY", "title": tr("SANCTUARY")}
		"boss":
			if zone == "pisces":
				return {"glyph": "\u2653", "color": Color(0.85, 0.65, 1.0), "label": "PISCES", "title": tr("FACE PISCES")}
			if zone == "aquarius":
				return {"glyph": "\u2652", "color": Color(0.6, 0.9, 1.0), "label": "AQUARIUS", "title": tr("FACE AQUARIUS")}
			if zone == "capricorn":
				return {"glyph": "\u2651", "color": Color(0.4, 1.0, 0.9), "label": "CAPRICORN", "title": tr("FACE CAPRICORN")}
			if zone == "sagittarius":
				return {"glyph": "\u2650", "color": Color(0.7, 0.55, 1.0), "label": "SAGITTARIUS", "title": tr("FACE SAGITTARIUS")}
			if zone == "scorpio":
				return {"glyph": "\u264F", "color": Color(0.5, 1.0, 0.3), "label": "SCORPIO", "title": tr("FACE SCORPIO")}
			if zone == "libra":
				return {"glyph": "\u264E", "color": Color(0.4, 1.0, 0.8), "label": "LIBRA", "title": tr("FACE LIBRA")}
			if zone == "virgo":
				return {"glyph": "\u264D", "color": Color(0.5, 1.0, 0.85), "label": "VIRGO", "title": tr("FACE VIRGO")}
			if zone == "leo":
				return {"glyph": "\u264C", "color": Color(1.0, 0.8, 0.4), "label": "LEO", "title": tr("FACE LEO")}
			if zone == "cancer":
				return {"glyph": "\u264B", "color": Color(0.5, 0.9, 1.0), "label": "CANCER", "title": tr("FACE CANCER")}
			if zone == "gemini":
				return {"glyph": "\u264A", "color": Color(0.6, 0.8, 1.0), "label": "GEMINI", "title": tr("FACE THE TWINS")}
			if zone == "taurus":
				return {"glyph": "\u2649", "color": Color(0.55, 1.0, 0.45), "label": "TAURUS", "title": tr("FACE TAURUS")}
			return {"glyph": "\u2648", "color": Color(1.0, 0.35, 0.2), "label": "ARIES", "title": tr("FACE ARIES")}
		"cycle_gate":
			return {"glyph": "\u221e", "color": Color(0.85, 0.65, 1.0), "label": tr("CYCLE") + " %d" % (GameData.run_cycle + 1), "title": tr("INTO THE ENDLESS SKY")}
		"pisces_gate":
			return {"glyph": "\u2653", "color": Color(0.85, 0.65, 1.0), "label": "PISCES", "title": tr("ONWARD TO PISCES")}
		"aquarius_gate":
			return {"glyph": "\u2652", "color": Color(0.6, 0.9, 1.0), "label": "AQUARIUS", "title": tr("ONWARD TO AQUARIUS")}
		"capricorn_gate":
			return {"glyph": "\u2651", "color": Color(0.4, 1.0, 0.9), "label": "CAPRICORN", "title": tr("ONWARD TO CAPRICORN")}
		"sagittarius_gate":
			return {"glyph": "\u2650", "color": Color(0.7, 0.55, 1.0), "label": "SAGITTARIUS", "title": tr("ONWARD TO SAGITTARIUS")}
		"scorpio_gate":
			return {"glyph": "\u264F", "color": Color(0.5, 1.0, 0.3), "label": "SCORPIO", "title": tr("ONWARD TO SCORPIO")}
		"libra_gate":
			return {"glyph": "\u264E", "color": Color(0.4, 1.0, 0.8), "label": "LIBRA", "title": tr("ONWARD TO LIBRA")}
		"virgo_gate":
			return {"glyph": "\u264D", "color": Color(0.5, 1.0, 0.85), "label": "VIRGO", "title": tr("ONWARD TO VIRGO")}
		"leo_gate":
			return {"glyph": "\u264C", "color": Color(1.0, 0.8, 0.4), "label": "LEO", "title": tr("ONWARD TO LEO")}
		"cancer_gate":
			return {"glyph": "\u264B", "color": Color(0.5, 0.9, 1.0), "label": "CANCER", "title": tr("ONWARD TO CANCER")}
		"gemini_gate":
			return {"glyph": "\u264A", "color": Color(0.6, 0.8, 1.0), "label": "GEMINI", "title": tr("ONWARD TO GEMINI")}
		"taurus_gate":
			return {"glyph": "\u2649", "color": Color(0.55, 1.0, 0.45), "label": "TAURUS", "title": tr("ONWARD TO TAURUS")}
		"home":
			return {"glyph": "\u2609", "color": Color(1.0, 0.85, 0.5), "label": "OBSERVATORY", "title": tr("RETURN TO OBSERVATORY")}
	return {"glyph": "?", "color": Color.WHITE, "label": "", "title": ""}


func _add_door(pos: Vector3, type: String) -> void:
	Net.send_door(pos, type)
	var info := _door_info(type)
	var col: Color = info["color"]
	var root := Node3D.new()
	root.position = pos
	add_child(root)
	var ring := TorusMesh.new()
	ring.inner_radius = 1.3
	ring.outer_radius = 1.46
	ring.rings = 64
	var rm := _mesh(ring, Vector3(0, 1.8, 0), _mat(Color(0.95, 0.8, 0.42), 0.9, 0.38), root)
	rm.rotation.x = PI * 0.5
	var glow_ring := TorusMesh.new()
	glow_ring.inner_radius = 1.5
	glow_ring.outer_radius = 1.55
	glow_ring.rings = 64
	var gm := _mesh(glow_ring, Vector3(0, 1.8, 0), _glow(col, 2.0), root)
	gm.rotation.x = PI * 0.5
	var q := QuadMesh.new()
	q.size = Vector2(2.7, 2.7)
	var pm := ShaderMaterial.new()
	pm.shader = preload("res://shaders/portal.gdshader")
	_mesh(q, Vector3(0, 1.8, 0), pm, root)
	var floor_ring := Skills.ring(1.9, Color(col.r, col.g, col.b, 0.7))
	floor_ring.position.y = 0.05
	root.add_child(floor_ring)
	# kapının üstünde yuvarlak madalyon içinde ödül sembolü (yazı yok)
	var med := QuadMesh.new()
	med.size = Vector2(1.7, 1.7)
	var mm := ShaderMaterial.new()
	mm.shader = preload("res://shaders/medallion.gdshader")
	mm.set_shader_parameter("tint", Vector3(col.r, col.g, col.b))
	mm.render_priority = 1
	var medal := _mesh(med, Vector3(0, 4.05, 0), mm, root)
	medal.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var g := UI.label3d(String(info["glyph"]) + "\uFE0E", 96, col, 1.6)
	g.font = UI.symbol_font()
	g.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	g.no_depth_test = true
	g.render_priority = 2
	g.position = Vector3(0, 4.05, 0)
	root.add_child(g)
	_light_at(pos + Vector3(0, 2.0, 1.0), col, root)
	root.scale = Vector3(0.01, 0.01, 0.01)
	var tw := root.create_tween()
	tw.tween_property(root, "scale", Vector3.ONE, 0.8).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	doors.append({"node": root, "type": type, "pos": pos, "title": String(info["title"]), "glyph": String(info["glyph"]), "color": col})


func _light_at(pos: Vector3, col: Color, parent: Node3D) -> void:
	var l := OmniLight3D.new()
	l.light_color = col
	l.light_energy = 1.5
	l.omni_range = 6.0
	parent.add_child(l)
	l.global_position = pos


## co-op: yerde yatan kahraman bir sonraki odaya canının %25'iyle geçer
func _save_hp2(heal: float) -> void:
	if hero != null and hero.dead:
		GameData.run_hp = hero.max_hp * 0.25
	if hero2 == null:
		return
	var h2: float = hero2.max_hp * 0.25 if hero2.dead else hero2.hp
	GameData.run_hp2 = minf(h2 + hero2.max_hp * heal, hero2.max_hp)


func _enter_door(type: String) -> void:
	if _door_hint:
		hud.door_hint = ""
		GameData.mark_hint("doors")   # §19.3: kapı seçilince yazılır
	if type == "home":
		_leave()
		return
	if type == "cycle_gate":
		# Sonsuz Gökyüzü: aynı run, bir üst döngüde Koç'tan devam (canın yarısı yenilenir)
		GameData.run_cycle += 1
		GameData.run_room = 0
		GameData.run_reward = "boon:" + Boons.random_planet()
		GameData.run_hp = minf(hero.hp + hero.max_hp * 0.5, hero.max_hp)
		_save_hp2(0.5)
		GameData.go_save()
		Sfx.play("dash", -4.0, 0.0, 0, 0.4)
		get_tree().change_scene_to_file(ROOM_SCENE)
		return
	if type == "taurus_gate" or type == "gemini_gate" or type == "cancer_gate" or type == "leo_gate" or type == "virgo_gate" or type == "libra_gate" or type == "scorpio_gate" or type == "sagittarius_gate" or type == "capricorn_gate" or type == "aquarius_gate" or type == "pisces_gate":
		# sonraki bölgeye geçiş: kısa bir nefes (canın %30'u yenilenir) ve ilk odada bir lütuf
		GameData.run_room = int(ZONE_START[type.trim_suffix("_gate")])
		GameData.run_reward = "boon:" + Boons.random_planet()
		GameData.run_hp = minf(hero.hp + hero.max_hp * 0.3, hero.max_hp)
		_save_hp2(0.3)
		GameData.go_save()
		Sfx.play("dash", -4.0, 0.0, 0, 0.5)
		get_tree().change_scene_to_file(ROOM_SCENE)
		return
	GameData.run_room = room_i + 1
	GameData.run_reward = type
	GameData.run_hp = hero.hp
	_save_hp2(0.0)
	GameData.go_save()
	Sfx.play("dash", -4.0, 0.0, 0, 0.6)
	get_tree().change_scene_to_file(ROOM_SCENE)


## Sığınak: ortada şifa veren bir ışık çeşmesi, kısa süre sonra kapılar açılır
func _spawn_fountain() -> void:
	var root := Node3D.new()
	add_child(root)
	var basin := CylinderMesh.new()
	basin.top_radius = 1.4
	basin.bottom_radius = 1.6
	basin.height = 0.5
	_mesh(basin, Vector3(0, 0.25, 0), _mat(Color(0.95, 0.8, 0.42), 0.9, 0.38), root)
	var water := CylinderMesh.new()
	water.top_radius = 1.25
	water.bottom_radius = 1.25
	water.height = 0.05
	_mesh(water, Vector3(0, 0.5, 0), _glow(Color(0.6, 0.95, 0.85), 2.5), root)
	var p := CPUParticles3D.new()
	p.amount = 50
	p.lifetime = 2.0
	var sm := SphereMesh.new()
	sm.radius = 0.04
	sm.height = 0.08
	p.mesh = sm
	p.material_override = _glow(Color(0.7, 1.0, 0.9), 5.0)
	p.direction = Vector3.UP
	p.spread = 15.0
	p.gravity = Vector3(0, -1.0, 0)
	p.initial_velocity_min = 2.0
	p.initial_velocity_max = 3.5
	p.position = Vector3(0, 0.6, 0)
	root.add_child(p)
	_light_at(Vector3(0, 1.5, 0), Color(0.6, 1.0, 0.85), root)
	_next_wave_t = 2.0


# ---------------------------------------------------------------- boss

## Boss girişi: kamera boss'a döner, boss yıldızlardan belirir, isim kartı gelir; bu sürede kimse saldırmaz
func _boss_intro() -> void:
	var glyphs := {"aries": "♈", "taurus": "♉", "gemini": "♊", "cancer": "♋", "leo": "♌", "virgo": "♍",
		"libra": "♎", "scorpio": "♏", "sagittarius": "♐", "capricorn": "♑", "aquarius": "♒", "pisces": "♓"}
	var zc: Color = Color(Elements.INFO[String(Elements.ZONE_EL.get(zone, "fire"))]["col"]) if Elements.ZONE_EL.has(zone) else Color(1.0, 0.85, 0.5)
	var bpos: Vector3 = boss.global_position
	Juice.constellation_spawn(self, bpos, zc.lerp(Color.WHITE, 0.3), 1.2)
	Juice.ring_wave(self, bpos, zc, 7.0, 0.8)
	Fx.flash_light(bpos + Vector3(0, 3, 0), zc, 10.0, 16.0, 0.8)
	var bt = boss.get("title")
	hud.boss_card(String(glyphs.get(zone, "✦")), String(bt) if bt != null else zone.to_upper(), zc)
	if boss.get("_global_cd") != null:
		boss._global_cd = maxf(float(boss._global_cd), 2.4)
	hero.frozen = true
	if hero2 != null:
		hero2.frozen = true
	var cam = Fx.camera
	if cam != null and is_instance_valid(cam) and boss is Node3D:
		cam.target = boss
		Juice.zoom_punch(6.0, 2.2)
	get_tree().create_timer(2.2).timeout.connect(func():
		if hero2 != null and is_instance_valid(hero2):
			hero2.frozen = false
		if hero != null and is_instance_valid(hero):
			hero.frozen = false
			if cam != null and is_instance_valid(cam):
				cam.target = _cam_focus if _cam_focus != null else hero)


func _spawn_boss() -> void:
	if ended:
		return
	if zone == "pisces":
		boss = PiScript.new()
	elif zone == "aquarius":
		boss = AqScript.new()
	elif zone == "capricorn":
		boss = CapScript.new()
	elif zone == "sagittarius":
		boss = SagScript.new()
	elif zone == "scorpio":
		boss = ScorpioScript.new()
	elif zone == "libra":
		boss = LibraScript.new()
	elif zone == "virgo":
		boss = VirgoScript.new()
	elif zone == "leo":
		boss = LeoScript.new()
	elif zone == "cancer":
		boss = CancerScript.new()
	elif zone == "gemini":
		boss = GeminiScript.new()
	elif zone == "taurus":
		boss = TaurusScript.new()
	else:
		boss = AriesScript.new()
	boss.hero = hero
	var rt: Dictionary = GameData.retro
	boss.max_hp = float(BOSS_HP.get(zone, boss.max_hp))
	boss.dmg_mult = (1.0 + 0.2 * float(Retro.rank(rt, "mars"))) * _cyc_dmg() * float(BOSS_DMG.get(zone, 1.0))
	boss.max_hp *= (1.0 + 0.25 * float(Retro.rank(rt, "jupiter"))) * _cyc_hp() * (1.6 if hero2 != null else 1.0)
	boss.windup_mult = 1.0 - 0.12 * float(Retro.rank(rt, "pluto"))
	boss.total_eclipse = Retro.rank(rt, "eclipse") > 0
	boss._bounds = ARENA_R - 1.0
	add_child(boss)
	boss.global_position = Vector3(0, 0, -4.5 if zone == "taurus" else -4.0)
	boss._face = Vector3(0, 0, 1)
	boss.killed.connect(_on_boss_killed)
	boss.summon.connect(_on_summon)
	if boss.has_signal("hint"):
		boss.hint.connect(func(a: String, b: String): hud.banner(a, b))
	# SONSUZ GÖKYÜZÜ: her boss düzenli aralıklarla başka bir burcun yankısını taşır (Balık zaten taşıyor)
	if GameData.run_cycle > 0 and zone != "pisces":
		var ec := SkyEcho.new()
		ec.hero = hero
		ec.par = self
		ec.bounds = ARENA_R - 1.0
		ec.source = boss
		ec.own = zone
		ec.every = maxf(11.0 - 1.5 * float(GameData.run_cycle), 5.0)
		ec.on_hint = func(a: String, b: String): hud.banner(a, b)
		add_child(ec)
	hud.boss = boss
	Fx.shake(0.6)
	Sfx.play("bossroar", 0.0, 0.0, 0, 0.6)
	_boss_intro()


## Final: arenanın çevresinde on iki burç sembolü sırayla yanar ve göğe yükselir
func _finale() -> void:
	var glyphs := ["\u2648", "\u2649", "\u264A", "\u264B", "\u264C", "\u264D", "\u264E", "\u264F", "\u2650", "\u2651", "\u2652", "\u2653"]
	var cols := [Color(1.0, 0.4, 0.25), Color(0.55, 1.0, 0.45), Color(0.6, 0.8, 1.0), Color(0.5, 0.9, 1.0), Color(1.0, 0.8, 0.4), Color(0.5, 1.0, 0.85),
		Color(0.4, 1.0, 0.8), Color(0.5, 1.0, 0.3), Color(0.7, 0.55, 1.0), Color(0.4, 1.0, 0.9), Color(0.6, 0.9, 1.0), Color(0.85, 0.65, 1.0)]
	for i in 12:
		var a := -PI * 0.5 + TAU * float(i) / 12.0
		var lb := Label3D.new()
		lb.text = glyphs[i]
		lb.font_size = 220
		lb.pixel_size = 0.01
		lb.modulate = cols[i]
		lb.outline_size = 0
		lb.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lb.no_depth_test = true
		lb.position = Vector3(cos(a) * 7.0, 0.5, sin(a) * 7.0)
		lb.modulate.a = 0.0
		add_child(lb)
		var tw := create_tween()
		tw.tween_interval(0.25 * float(i))
		tw.tween_property(lb, "modulate:a", 1.0, 0.3)
		tw.parallel().tween_callback(func():
			Sfx.play("coin", -10.0, 0.0, 0, 0.6 + 0.08 * float(i))
			Fx.flash_light(lb.global_position + Vector3(0, 1, 0), cols[i], 5.0, 6.0, 0.4))
		tw.tween_interval(3.2 - 0.25 * float(i))
		tw.tween_property(lb, "position", lb.position * 1.6 + Vector3(0, 9.0, 0), 2.5).set_trans(Tween.TRANS_SINE)
	get_tree().create_timer(3.4).timeout.connect(func():
		Fx.shake(0.5)
		Fx.flash_light(Vector3(0, 6, 0), Color(1.0, 0.95, 1.0), 14.0, 40.0, 2.0))


func _on_summon(kinds: Array) -> void:
	for i in kinds.size():
		var a := randf() * TAU
		var pos := Vector3(cos(a), 0, sin(a)) * randf_range(5.0, ARENA_R - 2.0)
		pending += 1
		_spawn_marker(pos, 0.2 + float(i) * 0.3, String(kinds[i]))


func _on_boss_killed(_b) -> void:
	victory = true
	cleared = true
	# boss ölümü: ağır çekim, sonra boss'un takımyıldızı göğe çizilir
	Fx.slowmo(0.25, 1.1)
	Juice.zoom_punch(5.0, 1.2)
	var bpos: Vector3 = _b.global_position if _b != null and is_instance_valid(_b) else Vector3.ZERO
	var zc: Color = Color(Elements.INFO[String(Elements.ZONE_EL.get(zone, "fire"))]["col"]) if Elements.ZONE_EL.has(zone) else Color(1.0, 0.85, 0.5)
	get_tree().create_timer(1.4).timeout.connect(func(): Juice.boss_constellation(self, bpos, zone, zc.lerp(Color.WHITE, 0.35)))
	# başarımlar
	Ach.unlock("BOSS_" + zone.to_upper())
	if not _boss_hurt:
		Ach.unlock("FLAWLESS")
	if GameData.run_rising != "":
		Ach.unlock("RISING_WIN")
	if Retro.heat(GameData.retro) >= 5:
		Ach.unlock("RETRO_5")
	if zone == "pisces" and GameData.run_cycle >= 1:
		Ach.unlock("CYCLE_1")
	if zone == "pisces" and GameData.run_cycle >= 3:
		Ach.unlock("CYCLE_3")
	GameData.moonstones += 2
	# burç cevheri (Satürn Demirci için): ilk zaferde 2, sonra 1
	var beaten := {"aries": GameData.aries_defeated, "taurus": GameData.taurus_defeated, "gemini": GameData.gemini_defeated,
		"cancer": GameData.cancer_defeated, "leo": GameData.leo_defeated, "virgo": GameData.virgo_defeated,
		"libra": GameData.libra_defeated, "scorpio": GameData.scorpio_defeated,
		"sagittarius": GameData.sagittarius_defeated, "capricorn": GameData.capricorn_defeated,
		"aquarius": GameData.aquarius_defeated,
		"pisces": GameData.pisces_defeated}
	var first_win := not bool(beaten.get(zone, false))
	GameData.ores[zone] = int(GameData.ores.get(zone, 0)) + (2 if first_win else 1)
	# kalan yardımcılar da dağılır
	for e in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(e) and not e.dead:
			e.take_hit(9999.0, Vector3.UP, 0.0, true)
	await get_tree().create_timer(1.6).timeout
	if ended:
		return
	if zone == "pisces":
		# FİNAL: on iki takımyıldızın hepsi arındı
		var first_all := not GameData.pisces_defeated
		var amount_p := PI_DUST + (PI_FIRST_BONUS if first_all else 0)
		amount_p = int(round(float(amount_p) * _retro_mult()))
		GameData.pisces_defeated = true
		var unlocked_new := GameData.run_cycle + 1 > GameData.sky_best
		GameData.sky_best = maxi(GameData.sky_best, GameData.run_cycle + 1)
		_drop_dust(Vector3(0, 2.0, -3.5), amount_p)
		GameData.last_run_msg = tr("Pisces is restored! All twelve constellations shine again — the sky is whole. This run: %d stardust") % (GameData.run_dust + amount_p)
		hud.banner("PISCES IS RESTORED", tr("+%d stardust") % amount_p)
		Sfx.play("coin", -2.0, 0.0, 0, 0.5)
		GameData.go_save()
		_finale()
		await get_tree().create_timer(4.5).timeout
		if ended:
			return
		if GameData.run_cycle == 0:
			hud.banner("THE SKY IS WHOLE AGAIN", tr("All twelve constellations shine. Beyond the eye, the dream goes on."))
		else:
			hud.banner(tr("CYCLE %d COMPLETE") % GameData.run_cycle, tr("The sky turns once more."))
		if unlocked_new:
			await get_tree().create_timer(3.0).timeout
			if ended:
				return
			hud.banner("THE ENDLESS SKY OPENS", tr("Cycle %d unlocked. Choose it at the portal, or keep going now.") % GameData.sky_best)
		await get_tree().create_timer(3.0).timeout
		# devam: aynı run'la bir sonraki döngüye (Koç'tan yeniden), ya da eve dönüş
		_add_door(Vector3(-3.4, 0, -7.5), "cycle_gate")
		_add_door(Vector3(3.4, 0, -7.5), "home")
		return
	if zone == "aquarius":
		var amount_q := AQ_DUST + (AQ_FIRST_BONUS if not GameData.aquarius_defeated else 0)
		amount_q = int(round(float(amount_q) * _retro_mult()))
		GameData.aquarius_defeated = true
		_drop_dust(Vector3(0, 2.0, -3.5), amount_q)
		GameData.last_run_msg = tr("Aquarius is restored! Eleven constellations shine again. This run: %d stardust") % (GameData.run_dust + amount_q)
		hud.banner("AQUARIUS IS RESTORED", tr("+%d stardust") % amount_q)
		Sfx.play("coin", -2.0, 0.0, 0, 0.5)
		Fx.flash_light(Vector3(0, 4, 0), Color(0.6, 0.9, 1.0), 10.0, 25.0, 1.5)
		GameData.go_save()
		await get_tree().create_timer(1.5).timeout
		_add_door(Vector3(-3.4, 0, -7.5), "pisces_gate")
		_add_door(Vector3(3.4, 0, -7.5), "home")
		return
	if zone == "capricorn":
		var amount_k := CAP_DUST + (CAP_FIRST_BONUS if not GameData.capricorn_defeated else 0)
		amount_k = int(round(float(amount_k) * _retro_mult()))
		GameData.capricorn_defeated = true
		_drop_dust(Vector3(0, 2.0, -3.5), amount_k)
		GameData.last_run_msg = tr("Capricorn is restored! Ten constellations shine again. This run: %d stardust") % (GameData.run_dust + amount_k)
		hud.banner("CAPRICORN IS RESTORED", tr("+%d stardust") % amount_k)
		Sfx.play("coin", -2.0, 0.0, 0, 0.5)
		Fx.flash_light(Vector3(0, 4, 0), Color(0.4, 1.0, 0.9), 10.0, 25.0, 1.5)
		GameData.go_save()
		await get_tree().create_timer(1.5).timeout
		_add_door(Vector3(-3.4, 0, -7.5), "aquarius_gate")
		_add_door(Vector3(3.4, 0, -7.5), "home")
		return
	if zone == "sagittarius":
		var amount_y := SAG_DUST + (SAG_FIRST_BONUS if not GameData.sagittarius_defeated else 0)
		amount_y = int(round(float(amount_y) * _retro_mult()))
		GameData.sagittarius_defeated = true
		_drop_dust(Vector3(0, 2.0, -3.5), amount_y)
		GameData.last_run_msg = tr("Sagittarius is restored! Nine constellations shine again. This run: %d stardust") % (GameData.run_dust + amount_y)
		hud.banner("SAGITTARIUS IS RESTORED", tr("+%d stardust") % amount_y)
		Sfx.play("coin", -2.0, 0.0, 0, 0.5)
		Fx.flash_light(Vector3(0, 4, 0), Color(0.7, 0.55, 1.0), 10.0, 25.0, 1.5)
		GameData.go_save()
		await get_tree().create_timer(1.5).timeout
		_add_door(Vector3(-3.4, 0, -7.5), "capricorn_gate")
		_add_door(Vector3(3.4, 0, -7.5), "home")
		return
	if zone == "scorpio":
		var amount_s := SCORPIO_DUST + (SCORPIO_FIRST_BONUS if not GameData.scorpio_defeated else 0)
		amount_s = int(round(float(amount_s) * _retro_mult()))
		GameData.scorpio_defeated = true
		_drop_dust(Vector3(0, 2.0, -3.5), amount_s)
		GameData.last_run_msg = tr("Scorpio is restored! Eight constellations shine again. This run: %d stardust") % (GameData.run_dust + amount_s)
		hud.banner("SCORPIO IS RESTORED", tr("+%d stardust") % amount_s)
		Sfx.play("coin", -2.0, 0.0, 0, 0.5)
		Fx.flash_light(Vector3(0, 4, 0), Color(0.5, 1.0, 0.3), 10.0, 25.0, 1.5)
		GameData.go_save()
		await get_tree().create_timer(1.5).timeout
		_add_door(Vector3(-3.4, 0, -7.5), "sagittarius_gate")
		_add_door(Vector3(3.4, 0, -7.5), "home")
		return
	if zone == "libra":
		var amount_b := LIBRA_DUST + (LIBRA_FIRST_BONUS if not GameData.libra_defeated else 0)
		amount_b = int(round(float(amount_b) * _retro_mult()))
		GameData.libra_defeated = true
		_drop_dust(Vector3(0, 2.0, -3.5), amount_b)
		GameData.last_run_msg = tr("Libra is restored! Seven constellations shine again. This run: %d stardust") % (GameData.run_dust + amount_b)
		hud.banner("LIBRA IS RESTORED", tr("+%d stardust") % amount_b)
		Sfx.play("coin", -2.0, 0.0, 0, 0.5)
		Fx.flash_light(Vector3(0, 4, 0), Color(0.4, 1.0, 0.8), 10.0, 25.0, 1.5)
		GameData.go_save()
		await get_tree().create_timer(1.5).timeout
		_add_door(Vector3(-3.4, 0, -7.5), "scorpio_gate")
		_add_door(Vector3(3.4, 0, -7.5), "home")
		return
	if zone == "virgo":
		var amount_v := VIRGO_DUST + (VIRGO_FIRST_BONUS if not GameData.virgo_defeated else 0)
		amount_v = int(round(float(amount_v) * _retro_mult()))
		GameData.virgo_defeated = true
		_drop_dust(Vector3(0, 2.0, -3.5), amount_v)
		GameData.last_run_msg = tr("Virgo is restored! Six constellations shine again. This run: %d stardust") % (GameData.run_dust + amount_v)
		hud.banner("VIRGO IS RESTORED", tr("+%d stardust") % amount_v)
		Sfx.play("coin", -2.0, 0.0, 0, 0.5)
		Fx.flash_light(Vector3(0, 4, 0), Color(0.5, 1.0, 0.85), 10.0, 25.0, 1.5)
		GameData.go_save()
		await get_tree().create_timer(1.5).timeout
		_add_door(Vector3(-3.4, 0, -7.5), "libra_gate")
		_add_door(Vector3(3.4, 0, -7.5), "home")
		return
	if zone == "leo":
		var amount_l := LEO_DUST + (LEO_FIRST_BONUS if not GameData.leo_defeated else 0)
		amount_l = int(round(float(amount_l) * _retro_mult()))
		GameData.leo_defeated = true
		_drop_dust(Vector3(0, 2.0, -3.5), amount_l)
		GameData.last_run_msg = tr("Leo is restored! Five constellations shine again. This run: %d stardust") % (GameData.run_dust + amount_l)
		hud.banner("LEO IS RESTORED", tr("+%d stardust") % amount_l)
		Sfx.play("coin", -2.0, 0.0, 0, 0.5)
		Fx.flash_light(Vector3(0, 4, 0), Color(1.0, 0.85, 0.5), 10.0, 25.0, 1.5)
		GameData.go_save()
		await get_tree().create_timer(1.5).timeout
		_add_door(Vector3(-3.4, 0, -7.5), "virgo_gate")
		_add_door(Vector3(3.4, 0, -7.5), "home")
		return
	if zone == "cancer":
		var amount_c := CANCER_DUST + (CANCER_FIRST_BONUS if not GameData.cancer_defeated else 0)
		amount_c = int(round(float(amount_c) * _retro_mult()))
		GameData.cancer_defeated = true
		_drop_dust(Vector3(0, 2.0, -3.5), amount_c)
		GameData.last_run_msg = tr("Cancer is restored! Four constellations shine again. This run: %d stardust") % (GameData.run_dust + amount_c)
		hud.banner("CANCER IS RESTORED", tr("+%d stardust") % amount_c)
		Sfx.play("coin", -2.0, 0.0, 0, 0.5)
		Fx.flash_light(Vector3(0, 4, 0), Color(0.6, 0.9, 1.0), 10.0, 25.0, 1.5)
		GameData.go_save()
		await get_tree().create_timer(1.5).timeout
		_add_door(Vector3(-3.4, 0, -7.5), "leo_gate")
		_add_door(Vector3(3.4, 0, -7.5), "home")
		return
	if zone == "gemini":
		var amount_g := GEMINI_DUST + (GEMINI_FIRST_BONUS if not GameData.gemini_defeated else 0)
		amount_g = int(round(float(amount_g) * _retro_mult()))
		GameData.gemini_defeated = true
		_drop_dust(Vector3(0, 2.0, -3.0), amount_g)
		GameData.last_run_msg = tr("The Twins are restored! Three constellations shine again. This run: %d stardust") % (GameData.run_dust + amount_g)
		hud.banner("THE TWINS ARE RESTORED", tr("+%d stardust") % amount_g)
		Sfx.play("coin", -2.0, 0.0, 0, 0.5)
		Fx.flash_light(Vector3(0, 4, 0), Color(0.7, 0.85, 1.0), 10.0, 25.0, 1.5)
		GameData.go_save()
		await get_tree().create_timer(1.5).timeout
		_add_door(Vector3(-3.4, 0, -7.5), "cancer_gate")
		_add_door(Vector3(3.4, 0, -7.5), "home")
		return
	if zone == "taurus":
		var amount_t := TAURUS_DUST + (TAURUS_FIRST_BONUS if not GameData.taurus_defeated else 0)
		amount_t = int(round(float(amount_t) * _retro_mult()))
		GameData.taurus_defeated = true
		_drop_dust(Vector3(0, 2.0, -4.5), amount_t)
		GameData.last_run_msg = tr("Taurus is restored! Two constellations shine again. This run: %d stardust") % (GameData.run_dust + amount_t)
		hud.banner("TAURUS IS RESTORED", tr("+%d stardust") % amount_t)
		Sfx.play("coin", -2.0, 0.0, 0, 0.5)
		Fx.flash_light(Vector3(0, 4, 0), Color(0.7, 1.0, 0.6), 10.0, 25.0, 1.5)
		GameData.go_save()
		await get_tree().create_timer(1.5).timeout
		_add_door(Vector3(-3.4, 0, -7.5), "gemini_gate")
		_add_door(Vector3(3.4, 0, -7.5), "home")
		return
	var amount := BOSS_DUST
	var first: bool = not GameData.aries_defeated
	if first:
		amount += BOSS_FIRST_BONUS
	amount = int(round(float(amount) * _retro_mult()))
	GameData.aries_defeated = true
	var heat := Retro.heat(GameData.retro)
	if heat > GameData.aries_best_heat:
		GameData.aries_best_heat = heat
	_drop_dust(Vector3(0, 2.0, -4.0), amount)
	GameData.last_run_msg = tr("Aries is restored! The first constellation shines again. This run: %d stardust") % (GameData.run_dust + amount)
	hud.banner("ARIES IS RESTORED", tr("+%d stardust") % amount)
	Sfx.play("coin", -2.0, 0.0, 0, 0.5)
	Fx.flash_light(Vector3(0, 4, 0), Color(1.0, 0.85, 0.5), 10.0, 25.0, 1.5)
	GameData.go_save()
	await get_tree().create_timer(1.5).timeout
	# yolculuk sürer: Boğa Otlakları'na ilerle ya da Gözlemevine dön
	_add_door(Vector3(-3.4, 0, -7.5), "taurus_gate")
	_add_door(Vector3(3.4, 0, -7.5), "home")


## Retro seviyesi başına +%10 yıldız tozu
func _retro_mult() -> float:
	return (1.0 + 0.1 * float(Retro.heat(GameData.retro))) * (1.0 + 0.5 * float(GameData.run_cycle))


## Sonsuz Gökyüzü döngü çarpanları
func _cyc_hp() -> float:
	return 1.0 + 0.4 * float(GameData.run_cycle)


func _cyc_dmg() -> float:
	return 1.0 + 0.2 * float(GameData.run_cycle)


## İKİZLER: kamera ortası, düşmanların en yakın kahramanı hedeflemesi, yerde yatanı kaldırma
func _coop_tick(delta: float) -> void:
	var a: Vector3 = hero.global_position
	var b: Vector3 = hero2.global_position
	if _cam_focus != hero and _cam_focus != null and is_instance_valid(_cam_focus):
		var tgt := (a + b) * 0.5
		if hero.dead:
			tgt = tgt.lerp(b, 0.5)
		elif hero2.dead:
			tgt = tgt.lerp(a, 0.5)
		_cam_focus.global_position = _cam_focus.global_position.lerp(tgt, minf(6.0 * delta, 1.0))
		# uzaklaştıkça kamera geri çekilir
		var spread := a.distance_to(b)
		camera.fov = lerpf(camera.fov, clampf(44.0 + (spread - 6.0) * 1.6, 44.0, 62.0), minf(3.0 * delta, 1.0))
	if Net.is_client():
		return   # hedef seçimi ve kaldırma host'ta
	_retarget_t -= delta
	if _retarget_t <= 0.0:
		_retarget_t = 0.35
		for e in get_tree().get_nodes_in_group("enemies"):
			if e == null or not is_instance_valid(e) or bool(e.get("dead")):
				continue
			var best = null
			var bd := 1.0e9
			for h in [hero, hero2]:
				if h.dead:
					continue
				var d: float = h.global_position.distance_squared_to(e.global_position)
				if d < bd:
					bd = d
					best = h
			if best != null and e.get("hero") != best:
				e.hero = best
	# yerde yatan: ortağı yanında 2,5 sn durursa %40 canla kalkar
	for pair in [[hero, hero2], [hero2, hero]]:
		var down = pair[0]
		var mate = pair[1]
		if not down.dead or ended:
			_revive.erase(down)
			continue
		var near: bool = not mate.dead and mate.global_position.distance_to(down.global_position) < 2.0
		var p := float(_revive.get(down, 0.0))
		p = p + delta if near else maxf(p - delta * 0.5, 0.0)
		_revive[down] = p
		if near and int(p * 4.0) != int((p - delta) * 4.0):
			Sfx.play("coin", -16.0, 0.05, 0, 0.8 + p * 0.3)
		if p >= 2.5:
			_revive.erase(down)
			down.revive(0.4)
			hud.banner(tr("BACK ON YOUR FEET"), "")
	hud.revive = _revive


func _on_coop_died(who) -> void:
	if ended:
		return
	var other = hero2 if who == hero else hero
	if other != null and not other.dead:
		hud.banner(tr("YOUR TWIN HAS FALLEN"), tr("Stand beside them to lift them up"))
		return
	_on_hero_died()


func _exit_tree() -> void:
	Net.room_left(self)


## ÇEVRİM İÇİ: arkadaş ayrıldı (host)
func net_partner_left() -> void:
	if hero2 != null and is_instance_valid(hero2):
		hero2.queue_free()
	hero2 = null
	_cam_focus = hero
	camera.target = hero
	hud.hero2 = null
	hud.banner(tr("YOUR FRIEND LEFT"), "")


## ÇEVRİM İÇİ: host run'ı bitirdi (client)
func net_run_over(death: bool) -> void:
	if ended:
		return
	ended = true
	if death:
		GameData.death_hint_pending = true
		hud.death_screen(GameData.run_dust)
		await get_tree().create_timer(3.5).timeout
	_leave()


func _on_hero_died() -> void:
	Net.send_run_over(true)
	ended = true
	GameData.death_hint_pending = true   # §19.4: Gözlemevi'nde Doğum Haritası kartı
	GameData.last_run_msg = tr("The stars remember you. Gathered this run: %d stardust") % GameData.run_dust
	GameData.go_save()
	await get_tree().create_timer(1.0).timeout
	hud.death_screen(GameData.run_dust)
	await get_tree().create_timer(3.5).timeout
	_leave()


func _abandon() -> void:
	GameData.last_run_msg = tr("The stars remember you. Gathered this run: %d stardust") % GameData.run_dust
	_leave()


func _leave() -> void:
	if not ended:
		Net.send_run_over(false)
	GameData.coop_unbind()
	GameData.run_hp2 = -1.0
	GameData.clear_saved_run()
	GameData.run_room = 0
	GameData.run_hp = -1.0
	GameData.run_reward = ""
	GameData.run_boons = []
	GameData.go_save()
	get_tree().paused = false
	Engine.time_scale = 1.0
	get_tree().change_scene_to_file(HUB_SCENE)
