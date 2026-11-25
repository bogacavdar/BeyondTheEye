extends RefCounted
## OYUN VERİLERİ
## Sahneler arasında taşınan bilgiler: seçili harita, ayarlar ve harita listesi.
## (static değişkenler sahne değişince kaybolmaz)

static var selected_map := "neon_city"
static var shake_mult := 1.0
static var volume := 0.6        # ana ses
static var sfx_volume := 0.6    # efektler
static var fullscreen := false

## Harita listesi. Yeni harita eklendikçe buraya yazılır.
const MAPS := [
	{
		"id": "neon_city", "name": "NEON ŞEHİR", "sub": "Karantina Bölgesi", "locked": false,
		"desc": "Virüsün ilk yayıldığı mahalle. Dar sokaklar, terk edilmiş arabalar, patlayan variller.\n5 dakika hayatta kal, sonra gelen KOVAN ANASI'nı öldür.",
		"color": Color(1.0, 0.2, 0.5), "boss_time": 300.0, "boss": "brood", "boss_reward": 60,
	},
	{
		"id": "port", "name": "LİMAN", "sub": "Yakında", "locked": true,
		"desc": "Konteyner labirentleri ve vinçler.", "color": Color(0.2, 0.8, 1.0),
	},
	{
		"id": "metro", "name": "METRO", "sub": "Yakında", "locked": true,
		"desc": "Karanlık tüneller, dar peronlar.", "color": Color(0.6, 1.0, 0.3),
	},
]


# ---------------------------------------------------------------- kalıcı ilerleme (roguelite)

const SAVE_PATH := "user://kayit.cfg"

## Kredi bankası: her run'da toplanan krediler ölsen de buraya eklenir.
static var bank := 0
## Açılmış silahlar (player.gd'deki silah adları)
static var owned: Array = ["TABANCA"]
## Yükseltme seviyeleri
static var upgrades := {}
## Boss'u yenilip temizlenen haritalar
static var cleared: Array = []
static var _loaded := false

## Laboratuvarda satılan silahlar (fiyat kredi)
const WEAPON_PRICES := {
	"TABANCA": 0, "UZİ": 60, "POMPALI": 90, "PİYADE TÜFEĞİ": 120,
	"REVOLVER": 150, "KESİK POMPALI": 200, "ALEV SİLAHI": 260, "BAZUKA": 350,
}

## Kalıcı yükseltmeler: id, ad, açıklama, seviye başı etki, en yüksek seviye, taban fiyat
const UPGRADES := [
	{"id": "damage", "name": "HASAR", "desc": "Tüm silahlar +%10 hasar", "max": 5, "price": 40},
	{"id": "hp", "name": "CAN", "desc": "+20 en yüksek can", "max": 5, "price": 35},
	{"id": "rate", "name": "ATIŞ HIZI", "desc": "+%8 atış hızı", "max": 5, "price": 45},
	{"id": "speed", "name": "HAREKET", "desc": "+%6 hareket hızı", "max": 4, "price": 30},
	{"id": "dash", "name": "ATILMA", "desc": "-%12 atılma bekleme süresi", "max": 4, "price": 30},
	{"id": "magnet", "name": "MIKNATIS", "desc": "Krediler +1 m uzaktan gelir", "max": 4, "price": 25},
	{"id": "greed", "name": "AÇGÖZLÜLÜK", "desc": "+%15 kredi kazancı", "max": 5, "price": 50},
]


static func lvl(id: String) -> int:
	return int(upgrades.get(id, 0))


static func upgrade_price(u: Dictionary) -> int:
	return int(u["price"]) * (lvl(u["id"]) + 1)


static func damage_mult() -> float:
	return 1.0 + 0.10 * lvl("damage")


static func rate_mult() -> float:
	return 1.0 + 0.08 * lvl("rate")


static func max_hp() -> float:
	return 100.0 + 20.0 * lvl("hp")


static func speed_mult() -> float:
	return 1.0 + 0.06 * lvl("speed")


static func dash_mult() -> float:
	return 1.0 - 0.12 * lvl("dash")


static func magnet_radius() -> float:
	return 3.5 + 1.0 * lvl("magnet")


static func credit_mult() -> float:
	return 1.0 + 0.15 * lvl("greed")


static func load_game() -> void:
	if _loaded:
		return
	_loaded = true
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	bank = int(cfg.get_value("ilerleme", "bank", 0))
	owned = cfg.get_value("ilerleme", "owned", ["TABANCA"])
	upgrades = cfg.get_value("ilerleme", "upgrades", {})
	cleared = cfg.get_value("ilerleme", "cleared", [])
	volume = float(cfg.get_value("ayarlar", "volume", 0.8))
	shake_mult = float(cfg.get_value("ayarlar", "shake", 1.0))
	fullscreen = bool(cfg.get_value("ayarlar", "fullscreen", false))
	if not owned.has("TABANCA"):
		owned.append("TABANCA")


static func save_game() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("ilerleme", "bank", bank)
	cfg.set_value("ilerleme", "owned", owned)
	cfg.set_value("ilerleme", "upgrades", upgrades)
	cfg.set_value("ilerleme", "cleared", cleared)
	cfg.set_value("ayarlar", "vol_master", volume)
	cfg.set_value("ayarlar", "vol_sfx", sfx_volume)
	cfg.set_value("ayarlar", "shake", shake_mult)
	cfg.set_value("ayarlar", "fullscreen", fullscreen)
	cfg.save(SAVE_PATH)


static func try_buy_weapon(wname: String) -> bool:
	var price := int(WEAPON_PRICES.get(wname, 999999))
	if owned.has(wname) or bank < price:
		return false
	bank -= price
	owned.append(wname)
	save_game()
	return true


static func try_buy_upgrade(u: Dictionary) -> bool:
	var id: String = u["id"]
	if lvl(id) >= int(u["max"]):
		return false
	var price := upgrade_price(u)
	if bank < price:
		return false
	bank -= price
	upgrades[id] = lvl(id) + 1
	save_game()
	return true


## Run bitince (ölüm ya da zafer) kazanılan krediler bankaya geçer.
static func end_run(credits: int, victory: bool, map_id: String) -> void:
	bank += credits
	if victory and not cleared.has(map_id):
		cleared.append(map_id)
	save_game()


static func map_info(id: String) -> Dictionary:
	for m in MAPS:
		if m["id"] == id:
			return m
	return MAPS[0]


static func apply_settings() -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(volume, 0.0001)))
	AudioServer.set_bus_mute(0, volume <= 0.001)
	Sfx.set_bus_volume("Music", 0.0 if music_muted else music_volume)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = max_fps
	Sfx.set_bus_volume("SFX", sfx_volume)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
	if is_web():
		# tarayıcı sürümü: 3D daha düşük çözünürlükte çizilir, kenar yumuşatma kapalı (akıcılık için)
		var tree := Engine.get_main_loop() as SceneTree
		if tree != null:
			tree.root.scaling_3d_scale = 0.7
			tree.root.msaa_3d = Viewport.MSAA_DISABLED


## Oyun tarayıcıda mı çalışıyor? (Web sürümünde ağır efektler kapatılır)
## Düşük ayar gereken platformlar: tarayıcı ve telefon (gölge yok, MSAA yok, çözünürlük ölçeği düşük)
static func is_web() -> bool:
	return OS.has_feature("web") or OS.has_feature("mobile")


static func is_mobile() -> bool:
	return OS.has_feature("mobile")


## Ekrandaki dokunmatik kontroller gösterilsin mi (telefon; masaüstünde test için BTE_TOUCH=1)
static func show_touch() -> bool:
	return OS.has_feature("mobile") or OS.get_environment("BTE_TOUCH") == "1"


## Son kullanılan giriş: "mouse" (klavye+fare), "pad" (kontrolcü), "touch" (dokunmatik)
static var input_mode := "touch" if OS.has_feature("mobile") else "mouse"


## Menü ve oyun aynı gece atmosferini kullanır.
static func build_environment(parent: Node) -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.03, 0.02, 0.05)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.45, 0.7)
	env.ambient_light_energy = 1.0
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.3
	env.glow_enabled = true
	env.glow_intensity = 1.0
	env.glow_strength = 1.1
	env.glow_bloom = 0.12
	env.glow_hdr_threshold = 0.9
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	env.ssr_enabled = true
	env.ssao_enabled = true
	env.fog_enabled = true
	env.fog_light_color = Color(0.25, 0.08, 0.2)
	env.fog_density = 0.003
	env.volumetric_fog_enabled = true
	env.volumetric_fog_density = 0.006
	env.volumetric_fog_albedo = Color(0.7, 0.6, 0.8)
	env.adjustment_enabled = true
	env.adjustment_contrast = 1.1
	env.adjustment_saturation = 1.2
	var we := WorldEnvironment.new()
	we.environment = env
	parent.add_child(we)

	var moon := DirectionalLight3D.new()
	moon.light_color = Color(0.7, 0.65, 1.0)
	moon.light_energy = 0.7
	moon.shadow_enabled = true
	moon.directional_shadow_max_distance = 60.0
	moon.rotation_degrees = Vector3(-60, 35, 0)
	parent.add_child(moon)


# ================================================================ GÖZÜN ÖTESİ
# Yeni oyunun kalıcı ilerlemesi. (Yukarıdaki kredi/laboratuvar bölümü eski NeonZombie prototipine ait.)

const SAVE_PATH_GO := "user://beyond_the_eye_v2.cfg"
const OLD_SAVE_GO := "user://beyond_the_eye.cfg"   # eski kayıttan sadece ayarlar alınır
const BirthChart = preload("res://scripts/birth_chart.gd")
const Loc = preload("res://scripts/loc.gd")
## Yıldız tozu henüz run'larda kazanılamadığı için Doğum Haritası'nı denemek amacıyla başlangıçta verilen miktar.
## Dövüş eklenince 0 yapılacak.
const TEST_START_DUST := 0

static var stardust := 0
static var chart := {}   # Doğum Haritası: "ev_yıldız" -> kademe
static var weapons_open: Array = ["STAR SWORD"]
static var chosen_weapon := "STAR SWORD"
static var _go_loaded := false
static var lang := "en"
static var music_volume := 0.4  # müzik
static var music_muted := false  # M tuşu
static var vsync := true
static var max_fps := 0          # 0 = sınırsız
static var dmg_numbers := true   # uçan hasar sayıları
static var saved_run := {}       # yarım kalan run (ana menüden devam etmek için)
## Run durumu (odalar arası): kaçıncı odadayız, kahramanın kalan canı, run'da toplanan toz
static var run_room := 0
static var run_hp := -1.0
static var run_dust := 0
static var last_run_msg := ""
static var run_boons: Array = []        # bu run'da alınan gezegen lütufları
static var moonstones := 0               # Ay Taşı (Ay Ana'ya hediye)
static var ayana_bond := 0               # Ay Ana ile bağ seviyesi (0-5)
static var charm_eq := ""                # takılı tılsım
static var charm_runs := {}              # tılsım -> takılı girilen run sayısı
static var ores := {}                    # burç cevherleri: burç -> adet (Satürn Demirci)
static var aspect_lv := {}               # burç mührü -> seviye (0-3)
static var aspect_eq := ""               # takılı burç mührü
static var companion := "fox"            # gök yoldaşı (companion.gd)
static var comp_runs := {}               # yoldaş -> birlikte girilen run sayısı
## SONSUZ GÖKYÜZÜ (NG+): Balık yenilince açılır. Döngü arttıkça düşmanlar güçlenir, bosslar başka burçların yankısını taşır,
## ödüller artar. sky_best = açılmış en yüksek döngü, sky_cycle = seçili başlangıç döngüsü, run_cycle = bu run'ın döngüsü.
static var sky_best := 0
static var hub_seen: Array = []          # gözlemevinde yanışı gösterilmiş takımyıldızlar
static var sky_cycle := 0
static var run_cycle := 0
static var run_rising := ""             # bu run'ın yükselen burcu (risings.gd)
static var hero_el := ""                 # kahramanın elementi (lütuflardan; hero.gd hesaplar)
static var hero_el_n := 0
static var run_reward := ""             # şu anki odanın ödülü: "boon:Mars", "dust", "rest", "boss"
static var run_revives_used := 0
static var run_unbroken_used := false
static var aries_defeated := false      # Koç boss'u en az bir kez yenildi mi
static var retro := {}                  # Gök Kadranı: açık lanetler (id -> kademe)
static var aries_best_heat := -1        # Koç'un yenildiği en yüksek retro seviyesi
static var taurus_defeated := false     # Boğa boss'u en az bir kez yenildi mi
static var gemini_defeated := false     # İkizler en az bir kez yenildi mi
static var cancer_defeated := false     # Yengeç en az bir kez yenildi mi
static var leo_defeated := false     # Aslan en az bir kez yenildi mi
static var virgo_defeated := false     # Başak en az bir kez yenildi mi
static var libra_defeated := false     # Terazi en az bir kez yenildi mi
static var scorpio_defeated := false     # Akrep en az bir kez yenildi mi
static var sagittarius_defeated := false     # Yay en az bir kez yenildi mi
static var capricorn_defeated := false     # Oğlak en az bir kez yenildi mi
static var aquarius_defeated := false     # Kova en az bir kez yenildi mi
static var pisces_defeated := false     # Balık en az bir kez yenildi mi


## Yeni bir run başlatır (Gözlemevi kapısından girerken)
static func start_run() -> void:
	run_rising = ""
	run_cycle = clampi(sky_cycle, 0, sky_best)
	run_room = 0
	run_hp = -1.0
	run_dust = 0
	run_boons = []
	if companion != "":
		comp_runs[companion] = int(comp_runs.get(companion, 0)) + 1
	if charm_eq != "":
		charm_runs[charm_eq] = int(charm_runs.get(charm_eq, 0)) + 1
		if charm_eq == "newmoon":
			# Yeni Ay: run'a rastgele bir lütufla başla
			var B = load("res://scripts/boons.gd")
			run_boons.append(String(B.BOONS[randi() % B.BOONS.size()]["id"]))
	run_reward = "boon:" + ["Sun", "Moon", "Mercury", "Venus", "Mars", "Jupiter", "Saturn"][randi() % 7]
	run_revives_used = 0
	run_unbroken_used = false

## Kozmik silahlar: başta biri seçilir, oyun tarzını o belirler. Her silahın 3 yeteneği var (1, 2, 3 tuşları).
## Yıldız Kılıcı: Yıldız Yağmuru (alana yıldız düşürür), Işık Dalgası (delip geçen hilal), Takımyıldızı Adımı (ışınlanıp yolu patlatır)
## Ay Orağı: Hilal Biçişi (geniş dönen biçme), Ay Gelgiti (düşmanları kendine çeker), Tutulma (alanı karartır, düşmanlar körleşir)
## Güneş Gürzü: Güneş Patlaması (çevreye alev dalgası), Zirve Darbesi (zıplayıp yere çakılma), Taç (yakıcı ışık halesi)
## Kuyruklu Yıldız Mızrağı: Kuyruklu Yıldız Atışı (fırlat-geri çağır), Günberi Hücumu (uzun saplayan hücum), Kuyruk Süpürmesi (geniş süpürme)
## Meteor Zinciri: Çarpma (meteoru yere vurur), Yörünge (zinciri etrafında döndürür), Meteor Sağanağı (gökten meteor yağar)
const STAR_WEAPONS := [
	{"id": "STAR SWORD", "price": 0, "style": "Fast combos. The widest parry window.",
		"color": Color(0.95, 0.9, 0.7), "skills": ["STARFALL", "LIGHT WAVE", "CONSTELLATION STEP"]},
	{"id": "MOON SCYTHE", "price": 120, "style": "Wide sweeping arcs. Made for crowds.",
		"color": Color(0.75, 0.82, 1.0), "skills": ["CRESCENT REAP", "LUNAR TIDE", "ECLIPSE"]},
	{"id": "SUN MACE", "price": 160, "style": "Slow and heavy. Slams send out a wave of light.",
		"color": Color(1.0, 0.75, 0.3), "skills": ["SOLAR FLARE", "ZENITH SLAM", "CORONA"]},
	{"id": "COMET SPEAR", "price": 200, "style": "Long reach. Thrust, throw and recall.",
		"color": Color(0.6, 0.85, 1.0), "skills": ["COMET THROW", "PERIHELION CHARGE", "TAIL SWEEP"]},
	{"id": "METEOR CHAIN", "price": 240, "style": "Very fast, many hits. Swing it on a chain.",
		"color": Color(1.0, 0.55, 0.35), "skills": ["IMPACT", "ORBIT", "CHAIN HOOK"]},
	{"id": "CENTAUR BOW", "price": 180, "style": "Fires arrows from afar. Keep your distance.",
		"color": Color(0.78, 0.65, 1.0), "skills": ["ARROW RAIN", "PIERCING STAR", "CENTAUR LEAP"]},
]

## Kayıt düzeni: ayarlar ortak dosyada, ilerleme 3 ayrı yuvada.
const SETTINGS_PATH := "user://beyond_the_eye_settings.cfg"
const SLOT_COUNT := 3
static var slot := 1
static var slot_active := false   # yuva seçilmeden (menüde) sadece ayarlar yazılır


static func slot_path(n: int) -> String:
	return "user://beyond_the_eye_slot%d.cfg" % n


static func go_load() -> void:
	if _go_loaded:
		return
	_go_loaded = true
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		# ilk açılış ya da eski tek dosyalı kayıt: ayarları ve ilerlemeyi 1. yuvaya taşı
		var old := ConfigFile.new()
		if old.load(SAVE_PATH_GO) == OK or old.load(OLD_SAVE_GO) == OK:
			_read_settings(old)
			if old.has_section("yolculuk") and not FileAccess.file_exists(slot_path(1)):
				var sc := ConfigFile.new()
				for k in old.get_section_keys("yolculuk"):
					sc.set_value("yolculuk", k, old.get_value("yolculuk", k))
				sc.save(slot_path(1))
		_save_settings()
	else:
		_read_settings(cfg)
		slot = clampi(int(cfg.get_value("ayarlar", "last_slot", 1)), 1, SLOT_COUNT)
	Loc.set_lang(lang)
	_load_slot(slot)


static func _read_settings(cfg: ConfigFile) -> void:
	volume = float(cfg.get_value("ayarlar", "vol_master", volume))
	sfx_volume = float(cfg.get_value("ayarlar", "vol_sfx", sfx_volume))
	music_volume = float(cfg.get_value("ayarlar", "vol_music", music_volume))
	music_muted = bool(cfg.get_value("ayarlar", "music_muted", music_muted))
	shake_mult = float(cfg.get_value("ayarlar", "shake", shake_mult))
	fullscreen = bool(cfg.get_value("ayarlar", "fullscreen", fullscreen))
	vsync = bool(cfg.get_value("ayarlar", "vsync", vsync))
	max_fps = int(cfg.get_value("ayarlar", "max_fps", max_fps))
	dmg_numbers = bool(cfg.get_value("ayarlar", "dmg_numbers", dmg_numbers))
	lang = String(cfg.get_value("ayarlar", "lang", lang))


static func _save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("ayarlar", "vol_master", volume)
	cfg.set_value("ayarlar", "vol_sfx", sfx_volume)
	cfg.set_value("ayarlar", "vol_music", music_volume)
	cfg.set_value("ayarlar", "music_muted", music_muted)
	cfg.set_value("ayarlar", "shake", shake_mult)
	cfg.set_value("ayarlar", "fullscreen", fullscreen)
	cfg.set_value("ayarlar", "vsync", vsync)
	cfg.set_value("ayarlar", "max_fps", max_fps)
	cfg.set_value("ayarlar", "dmg_numbers", dmg_numbers)
	cfg.set_value("ayarlar", "lang", lang)
	cfg.set_value("ayarlar", "last_slot", slot)
	cfg.save(SETTINGS_PATH)


## Bir yuvanın ilerlemesini belleğe alır (dosya yoksa sıfırdan başlar)
static func _load_slot(n: int) -> void:
	slot = n
	var cfg := ConfigFile.new()
	var ok := cfg.load(slot_path(n)) == OK
	slot_active = ok
	stardust = int(cfg.get_value("yolculuk", "stardust", TEST_START_DUST)) if ok else TEST_START_DUST
	chart = cfg.get_value("yolculuk", "chart", {}) if ok else {}
	aries_defeated = bool(cfg.get_value("yolculuk", "aries_defeated", false)) if ok else false
	retro = cfg.get_value("yolculuk", "retro", {}) if ok else {}
	aries_best_heat = int(cfg.get_value("yolculuk", "aries_best_heat", -1)) if ok else -1
	taurus_defeated = bool(cfg.get_value("yolculuk", "taurus_defeated", false)) if ok else false
	gemini_defeated = bool(cfg.get_value("yolculuk", "gemini_defeated", false)) if ok else false
	cancer_defeated = bool(cfg.get_value("yolculuk", "cancer_defeated", false)) if ok else false
	leo_defeated = bool(cfg.get_value("yolculuk", "leo_defeated", false)) if ok else false
	virgo_defeated = bool(cfg.get_value("yolculuk", "virgo_defeated", false)) if ok else false
	libra_defeated = bool(cfg.get_value("yolculuk", "libra_defeated", false)) if ok else false
	scorpio_defeated = bool(cfg.get_value("yolculuk", "scorpio_defeated", false)) if ok else false
	sagittarius_defeated = bool(cfg.get_value("yolculuk", "sagittarius_defeated", false)) if ok else false
	capricorn_defeated = bool(cfg.get_value("yolculuk", "capricorn_defeated", false)) if ok else false
	aquarius_defeated = bool(cfg.get_value("yolculuk", "aquarius_defeated", false)) if ok else false
	pisces_defeated = bool(cfg.get_value("yolculuk", "pisces_defeated", false)) if ok else false
	moonstones = int(cfg.get_value("ay_ana", "moonstones", 0)) if ok else 0
	ayana_bond = int(cfg.get_value("ay_ana", "bond", 0)) if ok else 0
	charm_eq = String(cfg.get_value("ay_ana", "charm", "")) if ok else ""
	charm_runs = Dictionary(cfg.get_value("ay_ana", "charm_runs", {})) if ok else {}
	companion = String(cfg.get_value("yoldas", "kind", "fox")) if ok else "fox"
	ores = Dictionary(cfg.get_value("demirci", "ores", {})) if ok else {}
	aspect_lv = Dictionary(cfg.get_value("demirci", "levels", {})) if ok else {}
	aspect_eq = String(cfg.get_value("demirci", "seal", "")) if ok else ""
	comp_runs = Dictionary(cfg.get_value("yoldas", "runs", {})) if ok else {}
	sky_best = int(cfg.get_value("sonsuz", "best", 0)) if ok else 0
	hub_seen = Array(cfg.get_value("yolculuk", "hub_seen", [])) if ok else []
	sky_cycle = int(cfg.get_value("sonsuz", "cycle", 0)) if ok else 0
	if pisces_defeated:
		sky_best = maxi(sky_best, 1)
	weapons_open = cfg.get_value("yolculuk", "weapons_open", ["STAR SWORD"]) if ok else ["STAR SWORD"]
	chosen_weapon = String(cfg.get_value("yolculuk", "chosen_weapon", "STAR SWORD")) if ok else "STAR SWORD"
	saved_run = cfg.get_value("yolculuk", "saved_run", {}) if ok else {}


## Ana menüden bir yuva seçilince
static func select_slot(n: int) -> void:
	go_load()
	_load_slot(clampi(n, 1, SLOT_COUNT))
	slot_active = true
	go_save()


static func slot_exists(n: int) -> bool:
	return FileAccess.file_exists(slot_path(n))


## Yuva kartında gösterilecek özet
static func slot_summary(n: int) -> Dictionary:
	var cfg := ConfigFile.new()
	if cfg.load(slot_path(n)) != OK:
		return {}
	var stars := 0
	var ch: Dictionary = cfg.get_value("yolculuk", "chart", {})
	for k in ch:
		stars += int(ch[k])
	var sr: Dictionary = cfg.get_value("yolculuk", "saved_run", {})
	return {"dust": int(cfg.get_value("yolculuk", "stardust", 0)), "stars": stars,
		"weapons": Array(cfg.get_value("yolculuk", "weapons_open", ["STAR SWORD"])).size(),
		"aries": bool(cfg.get_value("yolculuk", "aries_defeated", false)),
		"taurus": bool(cfg.get_value("yolculuk", "taurus_defeated", false)),
		"gemini": bool(cfg.get_value("yolculuk", "gemini_defeated", false)),
		"cancer": bool(cfg.get_value("yolculuk", "cancer_defeated", false)),
		"leo": bool(cfg.get_value("yolculuk", "leo_defeated", false)),
		"virgo": bool(cfg.get_value("yolculuk", "virgo_defeated", false)),
		"libra": bool(cfg.get_value("yolculuk", "libra_defeated", false)),
		"scorpio": bool(cfg.get_value("yolculuk", "scorpio_defeated", false)),
		"sagittarius": bool(cfg.get_value("yolculuk", "sagittarius_defeated", false)),
		"capricorn": bool(cfg.get_value("yolculuk", "capricorn_defeated", false)),
		"aquarius": bool(cfg.get_value("yolculuk", "aquarius_defeated", false)),
		"pisces": bool(cfg.get_value("yolculuk", "pisces_defeated", false)),
		"run_room": int(sr.get("room", -1)) if not sr.is_empty() else -1,
		"time": FileAccess.get_modified_time(slot_path(n))}


static func delete_slot(n: int) -> void:
	if FileAccess.file_exists(slot_path(n)):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(slot_path(n)))
	if n == slot:
		_load_slot(n)


static func go_save() -> void:
	_save_settings()
	if not slot_active:
		return
	var cfg := ConfigFile.new()
	cfg.set_value("yolculuk", "stardust", stardust)
	cfg.set_value("yolculuk", "chart", chart)
	cfg.set_value("yolculuk", "aries_defeated", aries_defeated)
	cfg.set_value("yolculuk", "retro", retro)
	cfg.set_value("yolculuk", "aries_best_heat", aries_best_heat)
	cfg.set_value("yolculuk", "taurus_defeated", taurus_defeated)
	cfg.set_value("yolculuk", "gemini_defeated", gemini_defeated)
	cfg.set_value("yolculuk", "cancer_defeated", cancer_defeated)
	cfg.set_value("yolculuk", "leo_defeated", leo_defeated)
	cfg.set_value("yolculuk", "virgo_defeated", virgo_defeated)
	cfg.set_value("yolculuk", "libra_defeated", libra_defeated)
	cfg.set_value("yolculuk", "scorpio_defeated", scorpio_defeated)
	cfg.set_value("yolculuk", "sagittarius_defeated", sagittarius_defeated)
	cfg.set_value("yolculuk", "capricorn_defeated", capricorn_defeated)
	cfg.set_value("yolculuk", "aquarius_defeated", aquarius_defeated)
	cfg.set_value("yolculuk", "pisces_defeated", pisces_defeated)
	cfg.set_value("ay_ana", "moonstones", moonstones)
	cfg.set_value("ay_ana", "bond", ayana_bond)
	cfg.set_value("ay_ana", "charm", charm_eq)
	cfg.set_value("ay_ana", "charm_runs", charm_runs)
	cfg.set_value("yoldas", "kind", companion)
	cfg.set_value("demirci", "ores", ores)
	cfg.set_value("demirci", "levels", aspect_lv)
	cfg.set_value("demirci", "seal", aspect_eq)
	cfg.set_value("yoldas", "runs", comp_runs)
	cfg.set_value("sonsuz", "best", sky_best)
	cfg.set_value("yolculuk", "hub_seen", hub_seen)
	cfg.set_value("sonsuz", "cycle", sky_cycle)
	cfg.set_value("yolculuk", "weapons_open", weapons_open)
	cfg.set_value("yolculuk", "chosen_weapon", chosen_weapon)
	cfg.set_value("yolculuk", "saved_run", saved_run)
	cfg.save(slot_path(slot))


## Yarım kalan run'ın anlık görüntüsü (her odaya girerken alınır)
static func snapshot_run() -> void:
	saved_run = {"room": run_room, "hp": run_hp, "dust": run_dust, "boons": run_boons.duplicate(),
		"reward": run_reward, "revives_used": run_revives_used, "unbroken_used": run_unbroken_used,
		"weapon": chosen_weapon, "rising": run_rising, "cycle": run_cycle}


static func has_saved_run() -> bool:
	return not saved_run.is_empty()


## Kayıtlı run'ı geri yükler (ana menüdeki DEVAM ET)
static func resume_run() -> void:
	run_room = int(saved_run.get("room", 0))
	run_hp = float(saved_run.get("hp", -1.0))
	run_dust = int(saved_run.get("dust", 0))
	run_boons = Array(saved_run.get("boons", [])).duplicate()
	run_rising = String(saved_run.get("rising", ""))
	run_cycle = int(saved_run.get("cycle", 0))
	run_reward = String(saved_run.get("reward", ""))
	run_revives_used = int(saved_run.get("revives_used", 0))
	run_unbroken_used = bool(saved_run.get("unbroken_used", false))
	chosen_weapon = String(saved_run.get("weapon", chosen_weapon))


static func clear_saved_run() -> void:
	saved_run = {}


## Tüm ilerlemeyi sıfırlar (ayarlar korunur)
static func reset_progress() -> void:
	stardust = 0
	chart = {}
	aries_defeated = false
	aries_best_heat = -1
	taurus_defeated = false
	gemini_defeated = false
	cancer_defeated = false
	leo_defeated = false
	virgo_defeated = false
	libra_defeated = false
	scorpio_defeated = false
	sagittarius_defeated = false
	capricorn_defeated = false
	aquarius_defeated = false
	pisces_defeated = false
	moonstones = 0
	ayana_bond = 0
	charm_eq = ""
	charm_runs = {}
	companion = "fox"
	comp_runs = {}
	sky_best = 0
	hub_seen = []
	sky_cycle = 0
	run_cycle = 0
	ores = {}
	aspect_lv = {}
	aspect_eq = ""
	retro = {}
	weapons_open = ["STAR SWORD"]
	chosen_weapon = "STAR SWORD"
	saved_run = {}
	go_save()


## Doğum Haritası'nda bir yıldıza kademe almayı dener (kurallar birth_chart.gd'de)
static func try_buy_star(h: int, i: int) -> bool:
	var st := BirthChart.state(chart, h, i)
	if st == "maxed" or st == "locked":
		return false
	var c := BirthChart.cost(chart, h, i)
	if stardust < c:
		return false
	stardust -= c
	chart[BirthChart.key(h, i)] = BirthChart.rank(chart, h, i) + 1
	go_save()
	return true


static func weapon_info(id: String) -> Dictionary:
	for w in STAR_WEAPONS:
		if w["id"] == id:
			return w
	return STAR_WEAPONS[0]


static func try_unlock_weapon(id: String) -> bool:
	var w := weapon_info(id)
	var price := int(w["price"])
	if weapons_open.has(id) or stardust < price:
		return false
	stardust -= price
	weapons_open.append(id)
	go_save()
	return true


## Ortak tuş atamaları (menü, gözlemevi ve oyun aynı tuşları kullanır)
static func setup_input() -> void:
	_keys("move_up", [KEY_W, KEY_UP])
	_keys("move_down", [KEY_S, KEY_DOWN])
	_keys("move_left", [KEY_A, KEY_LEFT])
	_keys("move_right", [KEY_D, KEY_RIGHT])
	_keys("dash", [KEY_SPACE])
	_keys("interact", [KEY_E, KEY_F])
	_keys("heavy", [KEY_Q])
	_keys("sprint", [KEY_SHIFT])
	_keys("pause", [KEY_ESCAPE, KEY_P])
	_keys("skill_1", [KEY_1])
	_keys("skill_2", [KEY_2])
	_keys("skill_3", [KEY_3])
	_keys("mute_music", [KEY_M])
	if not is_mobile():
		# telefonda dokunuş fare tıklaması gibi de gelir; saldırı/parry'yi tetiklemesin
		_mouse("fire", MOUSE_BUTTON_LEFT)
		_mouse("parry", MOUSE_BUTTON_RIGHT)
	# KONTROLCÜ (Xbox düzeni; PlayStation'da aynı yerdeki tuşlar):
	#  sol çubuk/yön tuşları: yürü · sağ çubuk: nişan · X: saldırı · Y: ağır saldırı · A: atılma
	#  B: parry · LB/RB/RT: 1-2-3 yetenekleri · LT ya da sol çubuğa basmak: koş · Start: duraklat
	_axis("move_left", JOY_AXIS_LEFT_X, -1.0)
	_axis("move_right", JOY_AXIS_LEFT_X, 1.0)
	_axis("move_up", JOY_AXIS_LEFT_Y, -1.0)
	_axis("move_down", JOY_AXIS_LEFT_Y, 1.0)
	_pad("move_up", [JOY_BUTTON_DPAD_UP])
	_pad("move_down", [JOY_BUTTON_DPAD_DOWN])
	_pad("move_left", [JOY_BUTTON_DPAD_LEFT])
	_pad("move_right", [JOY_BUTTON_DPAD_RIGHT])
	_pad("fire", [JOY_BUTTON_X])
	_pad("heavy", [JOY_BUTTON_Y])
	_pad("dash", [JOY_BUTTON_A])
	_pad("parry", [JOY_BUTTON_B])
	_pad("interact", [JOY_BUTTON_X])
	_pad("skill_1", [JOY_BUTTON_LEFT_SHOULDER])
	_pad("skill_2", [JOY_BUTTON_RIGHT_SHOULDER])
	_axis("skill_3", JOY_AXIS_TRIGGER_RIGHT, 1.0)
	_axis("sprint", JOY_AXIS_TRIGGER_LEFT, 1.0)
	_pad("sprint", [JOY_BUTTON_LEFT_STICK])
	_pad("pause", [JOY_BUTTON_START, JOY_BUTTON_BACK])


static func _pad(action: String, buttons: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for b in buttons:
		var ev := InputEventJoypadButton.new()
		ev.button_index = b
		if not InputMap.action_has_event(action, ev):
			InputMap.action_add_event(action, ev)


static func _axis(action: String, axis: JoyAxis, sign_v: float) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var ev := InputEventJoypadMotion.new()
	ev.axis = axis
	ev.axis_value = sign_v
	if not InputMap.action_has_event(action, ev):
		InputMap.action_add_event(action, ev)
	InputMap.action_set_deadzone(action, 0.3)


static func _keys(action: String, keys: Array) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action)
	for k in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		InputMap.action_add_event(action, ev)


static func _mouse(action: String, button: MouseButton) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action)
	var mb := InputEventMouseButton.new()
	mb.button_index = button
	InputMap.action_add_event(action, mb)
