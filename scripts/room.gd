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
	[["shade", "shade", "caster"], ["shade", "leaper", "shade", "caster"]],
	[["shade", "leaper", "caster", "shade"], ["brute", "caster", "shade", "shade"], ["leaper", "caster", "shade", "shade"]],
	[["shade", "leaper", "caster", "shade", "shade"], ["brute", "caster", "shade", "leaper"], ["leaper", "leaper", "caster", "caster", "shade"]],
	[["brute", "shade", "caster", "leaper", "shade"], ["caster", "caster", "leaper", "shade", "shade", "leaper"], ["brute", "brute", "leaper", "caster", "shade"]],
]
## Derinliğe göre düşman güçlenmesi ve seçkin olma şansı (dengeli: her oyuncu için)
const HP_MULT := [1.0, 1.1, 1.25, 1.4]
const DMG_MULT := [1.0, 1.1, 1.2, 1.3]
const ELITE_CHANCE := [0.0, 0.1, 0.15, 0.2]
const DUST_REWARD := [30, 45, 60, 80]
const ROOM_BONUS := [10, 15, 20, 25]
const DUST_BY_KIND := {"shade": 5, "caster": 5, "leaper": 6, "brute": 16}
const BOSS_DUST := 150
const BOSS_FIRST_BONUS := 200
## BÖLGELER: run derinliği 0-4 Koç Geçidi (4 = Koç), 5-9 Boğa Otlakları (9 = Boğa)
const ZONE_START := {"aries": 0, "taurus": 5, "gemini": 10}
const LAST_DEPTH := 14
const COMBAT_G := [
	[["shade", "shade", "caster", "leaper"], ["brute", "shade", "shade", "caster"]],
	[["shade", "shade", "leaper", "caster"], ["brute", "caster", "shade", "shade"], ["leaper", "leaper", "caster", "shade", "shade"]],
	[["brute", "leaper", "caster", "shade", "shade"], ["caster", "caster", "leaper", "shade", "shade"], ["brute", "brute", "shade", "shade", "leaper"]],
	[["brute", "leaper", "leaper", "caster", "shade", "shade"], ["caster", "caster", "brute", "shade", "shade", "leaper"], ["brute", "brute", "leaper", "caster", "shade", "shade"]],
]
const HP_MULT_G := [1.9, 2.0, 2.15, 2.3]
const DMG_MULT_G := [1.6, 1.68, 1.76, 1.85]
const ELITE_CHANCE_G := [0.25, 0.3, 0.35, 0.35]
const GEMINI_DUST := 300
const GEMINI_FIRST_BONUS := 400
const COMBAT_T := [
	[["shade", "shade", "caster", "leaper"], ["brute", "shade", "caster"]],
	[["leaper", "leaper", "shade", "caster"], ["brute", "caster", "shade", "shade"], ["leaper", "caster", "shade", "shade", "shade"]],
	[["brute", "leaper", "caster", "shade", "shade"], ["caster", "caster", "leaper", "shade", "shade"], ["brute", "brute", "caster", "leaper"]],
	[["brute", "leaper", "leaper", "caster", "shade", "shade"], ["caster", "caster", "brute", "shade", "shade", "leaper"], ["brute", "brute", "leaper", "caster", "caster", "shade"]],
]
const HP_MULT_T := [1.45, 1.55, 1.7, 1.85]
const DMG_MULT_T := [1.3, 1.38, 1.46, 1.55]
const ELITE_CHANCE_T := [0.15, 0.2, 0.25, 0.3]
const TAURUS_DUST := 220
const TAURUS_FIRST_BONUS := 300

var hero
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
	if room_i >= int(ZONE_START["gemini"]):
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
		var table: Array = _zt(COMBAT, COMBAT_T, COMBAT_G)
		waves = table[mini(local_i, table.size() - 1)]
	Sfx.play_music("res://assets/music/akash_chamber.mp3" if is_rest else "res://assets/music/awakening.mp3", -9.0)

	if zone == "gemini":
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
	camera.target = hero
	if GameData.run_hp > 0.0:
		hero.set_run_hp(GameData.run_hp)
	hero.died.connect(_on_hero_died)
	hero.hurt.connect(_on_hero_hurt)

	var layer := CanvasLayer.new()
	add_child(layer)
	hud = CombatHud.new()
	hud.hero = hero
	hud.wave_total = waves.size()
	hud.room = local_i + 1
	hud.room_total = BOSS_DEPTH + 1
	hud.reward = reward
	layer.add_child(hud)
	boon_ui = BoonUI.new()
	boon_ui.picked.connect(_on_boon_picked)
	layer.add_child(boon_ui)
	pause_ui = PauseUI.new()
	pause_ui.leave_text = "RETURN TO OBSERVATORY"
	pause_ui.leave.connect(_abandon)
	layer.add_child(pause_ui)
	_aim_moon()

	if is_rest:
		hero.heal(hero.max_hp * 0.4)
		hud.banner("SANCTUARY", tr("The stars mend your wounds"))
		_spawn_fountain()
	elif is_boss:
		if zone == "gemini":
			hud.banner("GEMINI", tr("Castor & Pollux"))
		elif zone == "taurus":
			hud.banner("TAURUS", tr("The Immovable"))
		else:
			hud.banner("ARIES", tr("The Ram's Fury"))
		get_tree().create_timer(1.6).timeout.connect(_spawn_boss)
	elif local_i == 0:
		if zone == "gemini":
			hud.banner("THE TWIN SKIES", tr("Two voices, one sky"))
		elif zone == "taurus":
			hud.banner("THE BULL'S MEADOWS", tr("Venus guards the road to Taurus"))
		else:
			hud.banner("THE RAM'S PASS", tr("The road to Aries burns"))


func _on_hero_hurt() -> void:
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
	for l in _flames:
		var ph: float = l.get_meta("flicker")
		l.light_energy = 1.1 + 0.25 * sin(_t * 9.0 + ph) + 0.15 * sin(_t * 23.0 + ph * 2.0)
	hud.dust = GameData.stardust
	hud.wave = wave + 1
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

	# kapılar
	var near = null
	var best := 2.6
	for d in doors:
		var dp: Vector3 = d["pos"]
		var dist := Vector2(hero.global_position.x - dp.x, hero.global_position.z - dp.z).length()
		if dist < best:
			best = dist
			near = d
	hud.prompt = String(near["title"]) if near != null else ""
	if near != null:
		hud.prompt_glyph = String(near["glyph"])
		hud.prompt_color = near["color"]
	if near != null and Input.is_action_just_pressed("interact"):
		_enter_door(String(near["type"]))

	if Input.is_action_just_pressed("pause") and not pause_ui.visible and not boon_ui.visible:
		pause_ui.open()


func _spawn_wave(kinds: Array) -> void:
	for i in kinds.size():
		var pos := Vector3.ZERO
		for tries in 20:
			var a := randf() * TAU
			var r := randf_range(3.5, ARENA_R - 1.5)
			pos = Vector3(cos(a) * r, 0, sin(a) * r)
			if pos.distance_to(hero.global_position) > 4.5:
				break
		pending += 1
		_spawn_marker(pos, 0.3 + float(i) * 0.25, String(kinds[i]))


## Doğuştan önce yerde mor-kızıl bir halka belirir (nereden geleceğini gösterir)
func _spawn_marker(pos: Vector3, delay: float, kind: String) -> void:
	var ring := Skills.ring(0.9, Color(0.75, 0.55, 1.0, 0.9))   # mor-beyaz: kızıl canavar ve uyarılardan ayrı
	ring.position = pos + Vector3(0, 0.05, 0)
	ring.scale = Vector3(0.2, 0.1, 0.2)
	add_child(ring)
	var tw := ring.create_tween()
	tw.tween_interval(delay)
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
	e.zone = zone
	e.hero = hero
	_tune_enemy(e)
	var di := mini(local_i, 3)
	var rt: Dictionary = GameData.retro
	var elite_ch := float(_zt(ELITE_CHANCE, ELITE_CHANCE_T, ELITE_CHANCE_G)[di]) + 0.15 * float(Retro.rank(rt, "moon"))
	if room_i >= 1 or Retro.rank(rt, "moon") > 0:
		e.elite = randf() < elite_ch
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
	if zone == "gemini" and kind == "shade":
		if _lonely != null and is_instance_valid(_lonely) and not _lonely.dead:
			e.partner = _lonely
			_lonely.partner = e
			_lonely = null
		else:
			_lonely = e


## Derinliğe ve retro lanetlerine göre güç çarpanları
func _tune_enemy(e) -> void:
	var di := mini(local_i, 3)
	var rt: Dictionary = GameData.retro
	var hpm: float = float(_zt(HP_MULT, HP_MULT_T, HP_MULT_G)[di])
	var dmm: float = float(_zt(DMG_MULT, DMG_MULT_T, DMG_MULT_G)[di])
	e.hp_mult = hpm * (1.0 + 0.25 * float(Retro.rank(rt, "jupiter")))
	e.dmg_mult = dmm * (1.0 + 0.2 * float(Retro.rank(rt, "mars")))
	e.windup_mult = 1.0 - 0.12 * float(Retro.rank(rt, "pluto"))


## Bölgeye göre tablo seçer
func _zt(a: Array, t: Array, g: Array) -> Array:
	if zone == "gemini":
		return g
	if zone == "taurus":
		return t
	return a


func _on_killed(e) -> void:
	alive -= 1
	# Taş Golem ölünce 2 taşçığa bölünür
	if zone == "taurus" and String(e.kind) == "brute" and not bool(e.get("pebble")) and not ended and not victory:
		for i in 2:
			var a := randf() * TAU
			_spawn_pebble(e.global_position + Vector3(cos(a), 0, sin(a)) * 0.9)
	var p: Vector3 = e.global_position + Vector3(0, 1.0, 0)
	var total: int = DUST_BY_KIND.get(String(e.kind), 5)
	if e.get("elite") == true:
		total *= 3
	_drop_dust(p, total)


func _spawn_pebble(pos: Vector3) -> void:
	var fl := Vector2(pos.x, pos.z)
	if fl.length() > ARENA_R - 1.0:
		fl = fl.normalized() * (ARENA_R - 1.0)
	var e = EnemyScript.new()
	e.kind = "shade"
	e.zone = "taurus"
	e.pebble = true
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


# ---------------------------------------------------------------- oda sonu ve ödüller

func _on_cleared() -> void:
	if cleared:
		return
	cleared = true
	var bonus: int = ROOM_BONUS[mini(local_i, ROOM_BONUS.size() - 1)]
	if reward == "dust":
		bonus += DUST_REWARD[mini(local_i, DUST_REWARD.size() - 1)]
	if zone == "taurus":
		bonus = int(round(float(bonus) * 1.4))
	elif zone == "gemini":
		bonus = int(round(float(bonus) * 1.8))
	bonus = int(round(float(bonus) * _retro_mult()))
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
			if zone == "gemini":
				return {"glyph": "\u264A", "color": Color(0.6, 0.8, 1.0), "label": "GEMINI", "title": tr("FACE THE TWINS")}
			if zone == "taurus":
				return {"glyph": "\u2649", "color": Color(0.55, 1.0, 0.45), "label": "TAURUS", "title": tr("FACE TAURUS")}
			return {"glyph": "\u2648", "color": Color(1.0, 0.35, 0.2), "label": "ARIES", "title": tr("FACE ARIES")}
		"gemini_gate":
			return {"glyph": "\u264A", "color": Color(0.6, 0.8, 1.0), "label": "GEMINI", "title": tr("ONWARD TO GEMINI")}
		"taurus_gate":
			return {"glyph": "\u2649", "color": Color(0.55, 1.0, 0.45), "label": "TAURUS", "title": tr("ONWARD TO TAURUS")}
		"home":
			return {"glyph": "\u2609", "color": Color(1.0, 0.85, 0.5), "label": "OBSERVATORY", "title": tr("RETURN TO OBSERVATORY")}
	return {"glyph": "?", "color": Color.WHITE, "label": "", "title": ""}


func _add_door(pos: Vector3, type: String) -> void:
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


func _enter_door(type: String) -> void:
	if type == "home":
		_leave()
		return
	if type == "taurus_gate" or type == "gemini_gate":
		# sonraki bölgeye geçiş: kısa bir nefes (canın %30'u yenilenir) ve ilk odada bir lütuf
		GameData.run_room = int(ZONE_START["taurus" if type == "taurus_gate" else "gemini"])
		GameData.run_reward = "boon:" + Boons.random_planet()
		GameData.run_hp = minf(hero.hp + hero.max_hp * 0.3, hero.max_hp)
		GameData.go_save()
		Sfx.play("dash", -4.0, 0.0, 0, 0.5)
		get_tree().change_scene_to_file(ROOM_SCENE)
		return
	GameData.run_room = room_i + 1
	GameData.run_reward = type
	GameData.run_hp = hero.hp
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

func _spawn_boss() -> void:
	if ended:
		return
	if zone == "gemini":
		boss = GeminiScript.new()
	elif zone == "taurus":
		boss = TaurusScript.new()
	else:
		boss = AriesScript.new()
	boss.hero = hero
	var rt: Dictionary = GameData.retro
	boss.dmg_mult = 1.0 + 0.2 * float(Retro.rank(rt, "mars"))
	boss.max_hp *= 1.0 + 0.25 * float(Retro.rank(rt, "jupiter"))
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
	hud.boss = boss
	Fx.shake(0.6)
	Sfx.play("bossroar", 0.0, 0.0, 0, 0.6)


func _on_summon(kinds: Array) -> void:
	for i in kinds.size():
		var a := randf() * TAU
		var pos := Vector3(cos(a), 0, sin(a)) * randf_range(5.0, ARENA_R - 2.0)
		pending += 1
		_spawn_marker(pos, 0.2 + float(i) * 0.3, String(kinds[i]))


func _on_boss_killed(_b) -> void:
	victory = true
	cleared = true
	# kalan yardımcılar da dağılır
	for e in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(e) and not e.dead:
			e.take_hit(9999.0, Vector3.UP, 0.0, true)
	await get_tree().create_timer(1.6).timeout
	if ended:
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
		_add_door(Vector3(0, 0, -7.5), "home")
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
	return 1.0 + 0.1 * float(Retro.heat(GameData.retro))


func _on_hero_died() -> void:
	ended = true
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
	GameData.clear_saved_run()
	GameData.run_room = 0
	GameData.run_hp = -1.0
	GameData.run_reward = ""
	GameData.run_boons = []
	GameData.go_save()
	get_tree().paused = false
	Engine.time_scale = 1.0
	get_tree().change_scene_to_file(HUB_SCENE)
