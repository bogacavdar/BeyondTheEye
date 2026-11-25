extends Node3D
## GÖZLEMEVİ (ana oda)
## Uzay boşluğunda süzülen yuvarlak bir platform. Zeminde altın kakma burç çarkı,
## tepede dönen 7 klasik gezegen (Güneş merkezde), arkada dev dolunay.
## Üç durak:
##   Doğum Haritası (batı) : kalıcı skill ağacı
##   Silah Sunağı (doğu)   : run'a girilecek silahı seç
##   Gözün Ötesi Kapısı (kuzey): run'ı başlat

const GameData = preload("res://scripts/game_data.gd")
const UI = preload("res://scripts/ui_style.gd")
const CameraScript = preload("res://scripts/camera_rig.gd")
const PlayerScript = preload("res://scripts/hero.gd")   # Gözlemevinde de silah elde: denemek için
const SkillTreeUI = preload("res://scripts/skill_tree_ui.gd")
const PauseUI = preload("res://scripts/pause_ui.gd")
const RetroUI = preload("res://scripts/retro_ui.gd")
const Retro = preload("res://scripts/retro.gd")
const ROOM_SCENE := "res://scenes/room.tscn"
const AltarUI = preload("res://scripts/altar_ui.gd")
const DummyScript = preload("res://scripts/training_dummy.gd")
const CombatHud = preload("res://scripts/combat_hud.gd")
const Weapons = preload("res://scripts/celestial_weapons.gd")
const MENU_SCENE := "res://scenes/main.tscn"

const PLATFORM_R := 14.0
const ROMAN := ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X", "XI", "XII"]

var player
var camera
var sky_mat: ShaderMaterial
var orrery: Node3D
var planets: Array = []
var spinners: Array = []   # [mesh, kendi ekseni etrafında dönüş hızı]
var orbiters: Array = []   # uydu yörüngeleri (Ay)
var chart_ring: Node3D
var altar_slot: Node3D
var altar_weapon: Node3D
var stations := []      # {title, pos, action}
var act_box: PanelContainer
var act_label: Label
var ui_layer: CanvasLayer
var skill_ui
var altar_ui
var dust_label: Label
var msg_label: Label
var msg_t := 0.0
var _t := 0.0
var _ui_open := false
var pause_ui
var retro_ui
var dial_rings: Array = []


func _ready() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	GameData.go_load()
	GameData.apply_settings()
	GameData.setup_input()
	Sfx.set_music_volume(GameData.music_volume)
	Sfx.play_music("res://assets/music/akash_chamber.mp3", -6.0)
	Fx.reset()
	Fx.world = self
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	_environment()
	_platform()
	_pillars()
	_orrery()
	_portal(Vector3(0, 0, -11.2))
	_birth_chart(Vector3(-10.6, 0, 1.0))
	_altar(Vector3(10.6, 0, 1.0))
	_sky_dial(Vector3(0, 0, 10.6))
	_ay_ana(Vector3(-7.6, 0, -7.6))
	_saturn(Vector3(7.6, 0, -7.6))

	camera = CameraScript.new()
	camera.offset = Vector3(10.0, 10.5, 10.0)
	add_child(camera)
	camera.fov = 44.0
	Fx.camera = camera

	player = PlayerScript.new()
	player.camera = camera
	add_child(player)
	if GameData.show_touch():
		var tc = load("res://scripts/touch_controls.gd").new()
		tc.hub_mode = true
		tc.hero = player
		add_child(tc)
	player.global_position = Vector3(0, 0, 6.0)
	camera.target = player

	# antrenman hedefi: silahı ve yetenekleri denemek için
	var dummy = DummyScript.new()
	add_child(dummy)
	dummy.global_position = Vector3(4.5, 0, -5.0)

	_aim_moon()
	_build_ui()
	GameData.run_room = 0
	GameData.run_hp = -1.0
	GameData.run_reward = ""
	GameData.run_boons = []
	if GameData.last_run_msg != "":
		_message(GameData.last_run_msg, 7.0)
		GameData.last_run_msg = ""


# ---------------------------------------------------------------- atmosfer

func _environment() -> void:
	sky_mat = ShaderMaterial.new()
	sky_mat.shader = preload("res://shaders/cosmic_sky.gdshader")
	var sky := Sky.new()
	sky.sky_material = sky_mat
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.35, 0.4, 0.7)
	env.ambient_light_energy = 0.9
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.0
	env.glow_enabled = true
	env.glow_intensity = 0.55
	env.glow_strength = 0.9
	env.glow_bloom = 0.0
	env.glow_hdr_threshold = 1.3
	env.ssr_enabled = false   # ayna gibi yansımalar göz alıyordu
	env.ssao_enabled = true
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.1
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	var moon := DirectionalLight3D.new()
	moon.light_color = Color(0.75, 0.8, 1.0)
	moon.light_energy = 0.9
	moon.shadow_enabled = not GameData.is_web()
	moon.rotation_degrees = Vector3(-50, -135, 0)
	add_child(moon)


## Dolunayı kameranın görüş alanının üst-sol köşesine yerleştir (platformun arkasındaki boşlukta görünsün)
func _aim_moon() -> void:
	var b: Basis = camera.global_transform.basis
	var f := -b.z
	var d := (f + b.y * 0.34 - b.x * 0.42).normalized()
	sky_mat.set_shader_parameter("moon_dir", d)


func _mat(c: Color, metal := 0.0, rough := 0.6) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.metallic = metal
	m.roughness = rough
	return m


func _gold() -> StandardMaterial3D:
	return _mat(Color(0.95, 0.8, 0.42), 0.9, 0.38)


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


func _light(pos: Vector3, c: Color, e: float, r: float, parent: Node3D = null) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.light_color = c
	l.light_energy = e
	l.omni_range = r
	l.position = pos
	(parent if parent != null else self).add_child(l)
	return l


# ---------------------------------------------------------------- platform

func _platform() -> void:
	var body := StaticBody3D.new()
	add_child(body)
	var cs := CollisionShape3D.new()
	var sh := CylinderShape3D.new()
	sh.radius = PLATFORM_R
	sh.height = 1.0
	cs.shape = sh
	cs.position.y = -0.5
	body.add_child(cs)

	var top := CylinderMesh.new()
	top.top_radius = PLATFORM_R
	top.bottom_radius = PLATFORM_R
	top.height = 1.0
	top.radial_segments = 96
	var fm := ShaderMaterial.new()
	fm.shader = preload("res://shaders/observatory_floor.gdshader")
	_mesh(top, Vector3(0, -0.5, 0), fm)

	# platformun altı: boşlukta asılı duran ters koni
	var under := CylinderMesh.new()
	under.top_radius = PLATFORM_R - 0.3
	under.bottom_radius = 2.5
	under.height = 9.0
	under.radial_segments = 64
	_mesh(under, Vector3(0, -5.5, 0), _mat(Color(0.05, 0.07, 0.2), 0.4, 0.5))
	for k in 3:
		var band := TorusMesh.new()
		band.inner_radius = lerpf(PLATFORM_R - 0.6, 4.0, float(k + 1) / 4.0)
		band.outer_radius = band.inner_radius + 0.12
		_mesh(band, Vector3(0, -1.2 - k * 2.1, 0), _gold())
	_mesh(_sphere(0.9), Vector3(0, -10.4, 0), _glow(Color(1.0, 0.85, 0.45), 2.0))

	# kenarda altın halka
	var rim := TorusMesh.new()
	rim.inner_radius = PLATFORM_R - 0.12
	rim.outer_radius = PLATFORM_R + 0.12
	rim.rings = 96
	_mesh(rim, Vector3(0, 0.02, 0), _gold())

	# burç çarkındaki ev numaraları (yerde, altın)
	for h in 12:
		var a := PI + (h + 0.5) * TAU / 12.0
		var l := UI.label3d(ROMAN[h], 110, UI.GOLD, 1.4)
		add_child(l)
		l.position = Vector3(cos(a) * 7.3, 0.03, -sin(a) * 7.3)
		l.rotation = Vector3(-PI * 0.5, PI * 0.25, 0)


func _sphere(r: float) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	return s


func _cyl(r: float, h: float, r_top := -1.0) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.bottom_radius = r
	c.top_radius = r if r_top < 0.0 else r_top
	c.height = h
	return c


func _pillars() -> void:
	var navy := _mat(Color(0.07, 0.1, 0.27), 0.3, 0.4)
	for i in 8:
		var a := TAU * (float(i) + 0.5) / 8.0
		var p := Vector3(cos(a) * 12.9, 0, sin(a) * 12.9)
		if p.z < -9.0 and absf(p.x) < 6.0:
			continue  # kapının önünü açık bırak
		_mesh(_cyl(0.35, 4.2), p + Vector3(0, 2.1, 0), navy)
		_mesh(_cyl(0.5, 0.3), p + Vector3(0, 0.15, 0), _gold())
		_mesh(_cyl(0.42, 0.25, 0.55), p + Vector3(0, 4.3, 0), _gold())
		var orb := _mesh(_sphere(0.22), p + Vector3(0, 4.9, 0), _glow(Color(1.0, 0.85, 0.5), 2.2))
		orb.set_meta("base_y", 4.9)
		orb.set_meta("phase", float(i))
		planets.append(orb)
		_light(p + Vector3(0, 4.9, 0), Color(1.0, 0.82, 0.5), 0.6, 6.0)


## Gezegen düzeneği: merkezde Güneş, Güneş'e uzaklık sırasıyla gerçek renkli gezegenler.
## Boyutlar ve uzaklıklar sıkıştırıldı (gerçek ölçekte Jüpiter Güneş'in yanında kaybolurdu),
## yörünge hızları Kepler'e göre: uzaktaki gezegen daha yavaş döner. Eksen eğiklikleri gerçek.
func _orrery() -> void:
	orrery = Node3D.new()
	orrery.position = Vector3(0, 6.6, 0)
	add_child(orrery)
	var sun_m := ShaderMaterial.new()
	sun_m.shader = preload("res://shaders/sun.gdshader")
	var sun := _mesh(_sphere(0.62), Vector3.ZERO, sun_m, orrery)
	spinners.append([sun, 0.12])
	# güneş halesi
	var cq := QuadMesh.new()
	cq.size = Vector2(3.4, 3.4)
	var cm := ShaderMaterial.new()
	cm.shader = preload("res://shaders/corona.gdshader")
	var corona := _mesh(cq, Vector3.ZERO, cm, orrery)
	corona.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_light(Vector3.ZERO, Color(1.0, 0.85, 0.6), 2.0, 14.0, orrery)

	# ad, uzaklık, yarıçap, eksen eğikliği (derece), kendi dönüşü, doku ayarları
	var defs := [
		["Merkur", 1.15, 0.085, 0.0, 0.2, {"kind": 0, "col_a": Color(0.62, 0.58, 0.55), "col_b": Color(0.36, 0.34, 0.33), "col_c": Color(0.5, 0.45, 0.4), "crater_amt": 1.0, "seed": 1.3}],
		["Venus", 1.55, 0.145, 177.0, -0.1, {"kind": 1, "col_a": Color(0.95, 0.87, 0.65), "col_b": Color(0.86, 0.72, 0.48), "col_c": Color(1.0, 0.95, 0.8), "band_freq": 4.0, "band_warp": 3.0, "seed": 2.1, "atmo_col": Color(1.0, 0.9, 0.6), "atmo_amt": 0.5}],
		["Dunya", 2.0, 0.155, 23.4, 0.8, {"kind": 2, "col_a": Color(0.07, 0.2, 0.52), "col_b": Color(0.18, 0.4, 0.16), "col_c": Color(0.68, 0.57, 0.38), "polar_cap": 0.84, "seed": 3.7, "atmo_col": Color(0.35, 0.6, 1.0), "atmo_amt": 1.2}],
		["Mars", 2.45, 0.115, 25.2, 0.78, {"kind": 0, "col_a": Color(0.8, 0.4, 0.2), "col_b": Color(0.5, 0.21, 0.11), "col_c": Color(0.62, 0.3, 0.16), "crater_amt": 0.35, "polar_cap": 0.88, "seed": 4.4, "atmo_col": Color(1.0, 0.6, 0.4), "atmo_amt": 0.25}],
		["Jupiter", 3.3, 0.4, 3.1, 1.6, {"kind": 1, "col_a": Color(0.93, 0.87, 0.75), "col_b": Color(0.72, 0.52, 0.34), "col_c": Color(0.55, 0.38, 0.27), "band_freq": 13.0, "band_warp": 1.4, "seed": 5.2, "spot_size": 0.24, "spot_dir": Vector3(1.0, -0.38, 0.2), "spot_col": Color(0.78, 0.36, 0.2)}],
		["Saturn", 4.35, 0.33, 26.7, 1.45, {"kind": 1, "col_a": Color(0.93, 0.85, 0.63), "col_b": Color(0.8, 0.68, 0.46), "col_c": Color(0.98, 0.93, 0.78), "band_freq": 11.0, "band_warp": 0.8, "seed": 6.6}],
		["Uranus", 5.25, 0.22, 97.8, -1.0, {"kind": 1, "col_a": Color(0.66, 0.88, 0.91), "col_b": Color(0.56, 0.8, 0.86), "col_c": Color(0.75, 0.93, 0.95), "band_freq": 6.0, "band_warp": 0.4, "seed": 7.9, "atmo_col": Color(0.6, 0.95, 1.0), "atmo_amt": 0.6}],
		["Neptun", 5.95, 0.21, 28.3, 1.1, {"kind": 1, "col_a": Color(0.24, 0.4, 0.9), "col_b": Color(0.14, 0.24, 0.68), "col_c": Color(0.5, 0.65, 1.0), "band_freq": 8.0, "band_warp": 1.0, "seed": 8.3, "spot_size": 0.18, "spot_dir": Vector3(-0.6, -0.4, 0.7), "spot_col": Color(0.08, 0.12, 0.4), "atmo_col": Color(0.35, 0.5, 1.0), "atmo_amt": 0.7}],
		["Pluton", 6.5, 0.06, 120.0, 0.3, {"kind": 0, "col_a": Color(0.85, 0.76, 0.64), "col_b": Color(0.55, 0.41, 0.31), "col_c": Color(0.93, 0.88, 0.8), "crater_amt": 0.3, "seed": 9.1}],
	]
	for d in defs:
		var dist: float = d[1]
		# yörünge çizgisi (ince altın)
		var ring := TorusMesh.new()
		ring.inner_radius = dist - 0.012
		ring.outer_radius = dist + 0.012
		ring.rings = 128
		ring.ring_segments = 6
		_mesh(ring, Vector3.ZERO, _glow(Color(0.95, 0.8, 0.45), 0.6), orrery)
		var arm := Node3D.new()
		arm.rotation.y = randf() * TAU
		arm.set_meta("speed", 0.55 * pow(1.15 / dist, 1.5))
		orrery.add_child(arm)
		var holder := Node3D.new()
		holder.position = Vector3(dist, 0, 0)
		arm.add_child(holder)
		var tilt := Node3D.new()
		tilt.rotation.z = deg_to_rad(float(d[3]))
		holder.add_child(tilt)
		var body := _mesh(_sphere(float(d[2])), Vector3.ZERO, _planet_mat(d[5]), tilt)
		spinners.append([body, float(d[4])])
		match d[0]:
			"Dunya":
				var moon_arm := Node3D.new()
				moon_arm.set_meta("speed", 1.6)
				moon_arm.rotation.x = deg_to_rad(5.1)
				holder.add_child(moon_arm)
				var moon_ring := TorusMesh.new()
				moon_ring.inner_radius = 0.285
				moon_ring.outer_radius = 0.295
				moon_ring.ring_segments = 4
				_mesh(moon_ring, Vector3.ZERO, _glow(Color(0.8, 0.82, 0.9), 0.4), moon_arm)
				_mesh(_sphere(0.045), Vector3(0.29, 0, 0), _planet_mat({"kind": 0, "col_a": Color(0.75, 0.75, 0.73), "col_b": Color(0.45, 0.45, 0.46), "col_c": Color(0.6, 0.6, 0.6), "crater_amt": 1.0, "seed": 11.0}), moon_arm)
				orbiters.append(moon_arm)
			"Saturn":
				_rings(tilt, 0.42, 0.82, Color(0.9, 0.82, 0.62), Color(0.62, 0.52, 0.36), 0.95, 0.62)
			"Uranus":
				_rings(tilt, 0.3, 0.38, Color(0.75, 0.85, 0.9), Color(0.5, 0.6, 0.66), 0.35, -1.0)
	orrery.rotation.x = 0.12


func _planet_mat(params: Dictionary) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = preload("res://shaders/planet.gdshader")
	for k in params:
		var v = params[k]
		if v is Color:
			v = Vector3(v.r, v.g, v.b)
		m.set_shader_parameter(k, v)
	return m


func _rings(parent: Node3D, r_in: float, r_out: float, ca: Color, cb: Color, opacity: float, gap: float) -> void:
	var pm := PlaneMesh.new()
	pm.size = Vector2(r_out * 2.0, r_out * 2.0)
	var m := ShaderMaterial.new()
	m.shader = preload("res://shaders/planet_ring.gdshader")
	m.set_shader_parameter("inner", r_in / r_out)
	m.set_shader_parameter("col_a", Vector3(ca.r, ca.g, ca.b))
	m.set_shader_parameter("col_b", Vector3(cb.r, cb.g, cb.b))
	m.set_shader_parameter("opacity", opacity)
	m.set_shader_parameter("gap_at", gap if gap > 0.0 else 2.0)
	_mesh(pm, Vector3.ZERO, m, parent)


# ---------------------------------------------------------------- duraklar

func _station(title: String, pos: Vector3, action: Callable, floor_y := 0.04) -> void:
	# Tepede yazı yok: etkileşim alanını yerde hafifçe parıldayan altın bir halka belli eder.
	# Halka yavaşça nefes alır; oyuncu yaklaşınca parlaklaşır ve büyür.
	var t := TorusMesh.new()
	t.inner_radius = 2.05
	t.outer_radius = 2.15
	t.rings = 96
	t.ring_segments = 6
	var m := _glow(Color(1.0, 0.85, 0.45), 1.0)
	var ring := _mesh(t, pos + Vector3(0, floor_y, 0), m)
	ring.scale = Vector3(1.0, 0.15, 1.0)
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# halkanın üstünde yükselen ince altın toz
	var p := CPUParticles3D.new()
	p.amount = 18
	p.lifetime = 2.2
	var pm := SphereMesh.new()
	pm.radius = 0.025
	pm.height = 0.05
	p.mesh = pm
	p.material_override = _glow(Color(1.0, 0.88, 0.55), 2.5)
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING
	p.emission_ring_axis = Vector3.UP
	p.emission_ring_radius = 2.1
	p.emission_ring_inner_radius = 1.9
	p.emission_ring_height = 0.0
	p.direction = Vector3.UP
	p.spread = 10.0
	p.gravity = Vector3.ZERO
	p.initial_velocity_min = 0.25
	p.initial_velocity_max = 0.55
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.2
	p.position = pos + Vector3(0, floor_y + 0.01, 0)
	add_child(p)
	stations.append({"pos": pos, "title": title, "action": action, "ring": ring, "mat": m, "glow": 0.0})


func _portal(pos: Vector3) -> void:
	var root := Node3D.new()
	root.position = pos
	add_child(root)
	# basamaklar
	_mesh(_cyl(2.8, 0.2), Vector3(0, 0.1, 0), _mat(Color(0.07, 0.1, 0.27), 0.3, 0.3), root)
	_mesh(_cyl(2.85, 0.06), Vector3(0, 0.22, 0), _gold(), root)
	# altın halka ve içindeki bulutsu
	var ring := TorusMesh.new()
	ring.inner_radius = 2.05
	ring.outer_radius = 2.35
	ring.rings = 64
	var rm := _mesh(ring, Vector3(0, 2.6, 0), _gold(), root)
	rm.rotation.x = PI * 0.5
	var ring2 := TorusMesh.new()
	ring2.inner_radius = 2.45
	ring2.outer_radius = 2.5
	ring2.rings = 64
	var rm2 := _mesh(ring2, Vector3(0, 2.6, 0), _glow(Color(1.0, 0.85, 0.5), 1.6), root)
	rm2.rotation.x = PI * 0.5
	var q := QuadMesh.new()
	q.size = Vector2(4.2, 4.2)
	var pm := ShaderMaterial.new()
	pm.shader = preload("res://shaders/portal.gdshader")
	_mesh(q, Vector3(0, 2.6, 0), pm, root)
	# halkanın etrafında 12 küçük yıldız
	for i in 12:
		var a := TAU * float(i) / 12.0
		_mesh(_sphere(0.07), Vector3(cos(a) * 2.7, 2.6 + sin(a) * 2.7, 0), _glow(Color(1.0, 0.9, 0.6), 2.5), root)
	_light(Vector3(0, 2.6, 1.2), Color(0.6, 0.45, 1.0), 2.5, 9.0, root)
	_station("THE GATE", pos, _enter_portal, 0.26)


func _birth_chart(pos: Vector3) -> void:
	var root := Node3D.new()
	root.position = pos
	root.rotation.y = PI * 0.5  # merkeze baksın
	add_child(root)
	_mesh(_cyl(0.9, 0.3), Vector3(0, 0.15, 0), _mat(Color(0.07, 0.1, 0.27), 0.3, 0.3), root)
	_mesh(_cyl(0.12, 1.2), Vector3(0, 0.9, 0), _gold(), root)
	# dikey duran usturlap diski
	chart_ring = Node3D.new()
	chart_ring.position = Vector3(0, 2.6, 0)
	root.add_child(chart_ring)
	var disc := _mesh(_cyl(1.35, 0.08), Vector3.ZERO, _mat(Color(0.05, 0.08, 0.22), 0.5, 0.3), chart_ring)
	disc.rotation.x = PI * 0.5
	for r in [1.35, 1.0, 0.45]:
		var t := TorusMesh.new()
		t.inner_radius = r - 0.035
		t.outer_radius = r + 0.035
		t.rings = 64
		var tm := _mesh(t, Vector3.ZERO, _gold(), chart_ring)
		tm.rotation.x = PI * 0.5
	for i in 12:
		var a := TAU * float(i) / 12.0
		var spoke := _mesh(BoxMesh.new(), Vector3(cos(a) * 0.72, sin(a) * 0.72, 0.05), _gold(), chart_ring)
		(spoke.mesh as BoxMesh).size = Vector3(0.55, 0.025, 0.02)
		spoke.rotation.z = a
		_mesh(_sphere(0.05), Vector3(cos(a + 0.26) * 1.17, sin(a + 0.26) * 1.17, 0.06), _glow(Color(1.0, 0.9, 0.6), 2.2), chart_ring)
	_mesh(_sphere(0.14), Vector3(0, 0, 0.06), _glow(Color(1.0, 0.85, 0.45), 2.5), chart_ring)
	_light(Vector3(0, 2.6, 1.0), Color(1.0, 0.85, 0.55), 0.9, 6.0, root)
	_station("BIRTH CHART", pos, _open_skill_tree)


func _altar(pos: Vector3) -> void:
	var root := Node3D.new()
	root.position = pos
	add_child(root)
	var navy := _mat(Color(0.07, 0.1, 0.27), 0.3, 0.3)
	_mesh(_cyl(1.2, 0.3), Vector3(0, 0.15, 0), navy, root)
	_mesh(_cyl(0.85, 0.3), Vector3(0, 0.45, 0), navy, root)
	_mesh(_cyl(0.6, 0.9), Vector3(0, 1.05, 0), navy, root)
	_mesh(_cyl(0.75, 0.08), Vector3(0, 1.54, 0), _gold(), root)
	_mesh(_cyl(1.25, 0.05), Vector3(0, 0.31, 0), _gold(), root)
	altar_slot = Node3D.new()
	altar_slot.position = Vector3(0, 2.0, 0)
	root.add_child(altar_slot)
	_light(Vector3(0, 2.8, 0), Color(1.0, 0.85, 0.55), 0.9, 6.0, root)
	_show_altar_weapon()
	_station("WEAPON ALTAR", pos, _open_altar)


## GÖK KADRANI: kızıl-altın dönen halkalarla bir gök küresi (retrolar ve tutulmalar)
func _sky_dial(pos: Vector3) -> void:
	var root := Node3D.new()
	root.position = pos
	add_child(root)
	var navy := _mat(Color(0.07, 0.1, 0.27), 0.3, 0.3)
	_mesh(_cyl(1.0, 0.3), Vector3(0, 0.15, 0), navy, root)
	_mesh(_cyl(1.05, 0.05), Vector3(0, 0.31, 0), _gold(), root)
	_mesh(_cyl(0.1, 1.3), Vector3(0, 0.95, 0), _gold(), root)
	var center := Node3D.new()
	center.position = Vector3(0, 2.4, 0)
	root.add_child(center)
	_mesh(_sphere(0.28), Vector3.ZERO, _glow(Color(1.0, 0.35, 0.25), 3.0), center)
	var red_gold := _mat(Color(0.95, 0.55, 0.35), 0.9, 0.35)
	for i in 3:
		var t := TorusMesh.new()
		t.inner_radius = 0.75 + 0.18 * float(i)
		t.outer_radius = t.inner_radius + 0.05
		t.rings = 64
		var holder := Node3D.new()
		holder.rotation = Vector3(0.6 * float(i), 0.4 * float(i), 0.9 * float(i))
		center.add_child(holder)
		_mesh(t, Vector3.ZERO, red_gold if i != 1 else _gold(), holder)
		holder.set_meta("spin", 0.4 + 0.25 * float(i))
		dial_rings.append(holder)
	_light(Vector3(0, 2.4, 0), Color(1.0, 0.45, 0.35), 1.0, 5.0, root)
	_station("SKY DIAL", pos, _open_retro)


func _open_retro() -> void:
	_ui_open = true
	player.frozen = true
	retro_ui.refresh()
	retro_ui.visible = true


func _show_altar_weapon() -> void:
	if altar_weapon != null and is_instance_valid(altar_weapon):
		altar_weapon.queue_free()
	var info := GameData.weapon_info(GameData.chosen_weapon)
	altar_weapon = Weapons.build(GameData.chosen_weapon, info["color"])
	altar_slot.add_child(altar_weapon)
	altar_weapon.rotation.z = 0.35


# ---------------------------------------------------------------- arayüz

func _build_ui() -> void:
	ui_layer = CanvasLayer.new()
	add_child(ui_layer)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = UI.theme()
	ui_layer.add_child(root)

	var title := UI.label("OBSERVATORY", 42, UI.GOLD, 6)
	title.position = Vector2(40, 28)
	root.add_child(title)
	var line := ColorRect.new()
	line.color = UI.GOLD
	line.position = Vector2(42, 86)
	line.size = Vector2(240, 2)
	root.add_child(line)
	dust_label = UI.label("", 22, UI.CREAM, 5)
	dust_label.position = Vector2(42, 96)
	root.add_child(dust_label)
	var hint_txt := "WASD move   ·   LMB / Q / 1 2 3 try your weapon   ·   E interact   ·   Esc pause"
	if GameData.is_mobile():
		hint_txt = "Left stick move   ·   USE interact   ·   II pause"
	elif Input.get_connected_joypads().size() > 0:
		hint_txt = "Left stick move   ·   X interact   ·   A dash   ·   Start pause"
	var hint := UI.label(hint_txt, 16, Color(0.85, 0.8, 0.6), 4)
	hint.set_anchors_preset(Control.PRESET_TOP_LEFT)
	hint.offset_left = 40.0
	hint.offset_top = 132.0
	root.add_child(hint)

	# yakındaki durak için ekranın altında açık bir etkileşim kutusu
	act_box = PanelContainer.new()
	var abs_style := UI.box(Color(UI.DEEP.r, UI.DEEP.g, UI.DEEP.b, 0.9), UI.GOLD, 2, 30)
	abs_style.content_margin_top = 12
	abs_style.content_margin_bottom = 12
	act_box.add_theme_stylebox_override("panel", abs_style)
	act_box.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	act_box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	act_box.grow_vertical = Control.GROW_DIRECTION_BEGIN
	act_box.offset_bottom = -235.0
	act_box.visible = false
	root.add_child(act_box)
	act_label = UI.label("", 26, UI.GOLD, 4)
	act_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	act_box.add_child(act_label)
	msg_label = UI.label("", 26, UI.GOLD, 6)
	msg_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	msg_label.offset_left = -600.0
	msg_label.offset_right = 600.0
	msg_label.offset_top = 150.0
	msg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(msg_label)

	skill_ui = SkillTreeUI.new()
	skill_ui.visible = false
	skill_ui.closed.connect(_close_ui)
	ui_layer.add_child(skill_ui)
	saturn_ui = load("res://scripts/saturn_ui.gd").new()
	saturn_ui.closed.connect(_close_ui)
	ui_layer.add_child(saturn_ui)
	ayana_ui = load("res://scripts/ayana_ui.gd").new()
	ayana_ui.closed.connect(_close_ui)
	ui_layer.add_child(ayana_ui)
	altar_ui = AltarUI.new()
	altar_ui.visible = false
	altar_ui.closed.connect(_close_ui)
	altar_ui.weapon_chosen.connect(_on_weapon_chosen)
	ui_layer.add_child(altar_ui)
	var hud = CombatHud.new()
	hud.hero = player
	hud.hub_mode = true
	ui_layer.add_child(hud)
	retro_ui = RetroUI.new()
	retro_ui.visible = false
	retro_ui.closed.connect(_close_ui)
	ui_layer.add_child(retro_ui)
	pause_ui = PauseUI.new()
	pause_ui.leave_text = "MAIN MENU"
	pause_ui.leave.connect(func(): get_tree().change_scene_to_file(MENU_SCENE))
	ui_layer.add_child(pause_ui)


func _on_weapon_chosen(id: String) -> void:
	_show_altar_weapon()
	if player.has_method("equip"):
		player.equip(id)


func _open_skill_tree() -> void:
	_ui_open = true
	player.frozen = true
	skill_ui.visible = true
	Sfx.play("roar", -22.0, 0.0, 0, 2.2)


func _open_altar() -> void:
	_ui_open = true
	player.frozen = true
	altar_ui.refresh()
	altar_ui.visible = true


var ayana_ui = null


## AY ANA: ay ışığında oturan, hilal taçlı gümüş kadın; Ay Taşı karşılığı tılsım verir
func _ay_ana(pos: Vector3) -> void:
	var root := Node3D.new()
	root.position = pos
	add_child(root)
	root.look_at(Vector3(0, 0, 0) + Vector3(0, 0, 0.01), Vector3.UP)
	root.rotate_y(PI)
	var robe := _mat(Color(0.78, 0.82, 0.95), 0.2, 0.45)
	robe.emission_enabled = true
	robe.emission = Color(0.5, 0.6, 1.0)
	robe.emission_energy_multiplier = 0.25
	var skin := _mat(Color(0.92, 0.94, 1.0), 0.0, 0.4)
	var moon := _glow(Color(0.85, 0.92, 1.0), 3.0)
	# taş kaide
	var base := CylinderMesh.new()
	base.top_radius = 1.0
	base.bottom_radius = 1.2
	base.height = 0.5
	_mesh(base, Vector3(0, 0.25, 0), _mat(Color(0.25, 0.27, 0.4), 0.1, 0.7), root)
	# yere yayılan cüppe ve gövde
	var c := CylinderMesh.new()
	c.top_radius = 0.28
	c.bottom_radius = 0.95
	c.height = 1.7
	_mesh(c, Vector3(0, 1.35, 0), robe, root)
	var h := _mesh(_sphere(0.26), Vector3(0, 2.4, 0), skin, root)
	h.scale = Vector3(0.9, 1.05, 0.9)
	# uzun gümüş saç
	var hair := CylinderMesh.new()
	hair.top_radius = 0.24
	hair.bottom_radius = 0.42
	hair.height = 1.3
	_mesh(hair, Vector3(0, 1.85, 0.12), _mat(Color(0.85, 0.88, 0.98), 0.0, 0.5), root)
	# hilal taç
	var t := TorusMesh.new()
	t.inner_radius = 0.28
	t.outer_radius = 0.36
	var cr := _mesh(t, Vector3(0, 2.78, 0), moon, root)
	cr.rotation.x = PI * 0.5
	cr.scale = Vector3(1.0, 1.0, 0.4)
	# elinde ay taşı
	_mesh(_sphere(0.14), Vector3(0.0, 1.55, -0.55), moon, root)
	# etrafında süzülen küçük aylar
	for i in 5:
		var a := TAU * float(i) / 5.0
		var o := _mesh(_sphere(0.09), Vector3(cos(a) * 1.4, 2.2 + sin(a * 2.0) * 0.3, sin(a) * 1.4), moon, root)
		o.set_meta("speed", 0.4)
	_light(Vector3(0, 3.2, 0), Color(0.7, 0.8, 1.0), 2.2, 7.0, root)
	_station("MOTHER MOON", pos, _open_ayana)


var saturn_ui = null


## SATÜRN DEMİRCİ: halkalı örsün başında, kül grisi yaşlı demirci
func _saturn(pos: Vector3) -> void:
	var root := Node3D.new()
	root.position = pos
	add_child(root)
	root.look_at(Vector3(0, 0, 0.01), Vector3.UP)
	root.rotate_y(PI)
	var cloak := _mat(Color(0.32, 0.3, 0.36), 0.1, 0.8)
	var skin := _mat(Color(0.75, 0.7, 0.65), 0.0, 0.6)
	var iron := _mat(Color(0.25, 0.26, 0.3), 0.8, 0.35)
	var gold := _glow(Color(1.0, 0.78, 0.45), 1.2)
	var base := CylinderMesh.new()
	base.top_radius = 1.0
	base.bottom_radius = 1.2
	base.height = 0.4
	_mesh(base, Vector3(0, 0.2, 0), _mat(Color(0.22, 0.22, 0.28), 0.1, 0.8), root)
	# geniş omuzlu, kambur demirci
	var body := CylinderMesh.new()
	body.top_radius = 0.5
	body.bottom_radius = 0.7
	body.height = 1.4
	_mesh(body, Vector3(0.6, 1.1, 0.3), cloak, root)
	var h := _mesh(_sphere(0.28), Vector3(0.6, 2.0, 0.15), skin, root)
	h.scale = Vector3(1.0, 1.0, 1.1)
	var beard := CylinderMesh.new()
	beard.top_radius = 0.26
	beard.bottom_radius = 0.06
	beard.height = 0.6
	_mesh(beard, Vector3(0.6, 1.65, -0.05), _mat(Color(0.85, 0.85, 0.85), 0.0, 0.9), root)
	# halkalı örs
	var anvil := BoxMesh.new()
	anvil.size = Vector3(0.9, 0.45, 0.5)
	_mesh(anvil, Vector3(-0.4, 0.95, -0.3), iron, root)
	var leg := BoxMesh.new()
	leg.size = Vector3(0.4, 0.5, 0.35)
	_mesh(leg, Vector3(-0.4, 0.55, -0.3), iron, root)
	var ring := TorusMesh.new()
	ring.inner_radius = 0.75
	ring.outer_radius = 0.85
	var rm := _mesh(ring, Vector3(-0.4, 1.0, -0.3), gold, root)
	rm.rotation.x = 0.35
	spinners.append([rm, 0.6])
	# çekiç
	var hh := CylinderMesh.new()
	hh.top_radius = 0.04
	hh.bottom_radius = 0.04
	hh.height = 0.8
	var hm := _mesh(hh, Vector3(0.05, 1.45, -0.1), _mat(Color(0.4, 0.28, 0.2), 0.0, 0.8), root)
	hm.rotation.z = 0.9
	var head := BoxMesh.new()
	head.size = Vector3(0.18, 0.18, 0.32)
	_mesh(head, Vector3(-0.22, 1.7, -0.1), iron, root)
	# örsten sıçrayan kıvılcımlar
	var sp := CPUParticles3D.new()
	sp.amount = 14
	sp.lifetime = 0.8
	var sm := SphereMesh.new()
	sm.radius = 0.025
	sm.height = 0.05
	sp.mesh = sm
	sp.material_override = _glow(Color(1.0, 0.7, 0.3), 4.0)
	sp.direction = Vector3.UP
	sp.spread = 60.0
	sp.initial_velocity_min = 1.0
	sp.initial_velocity_max = 2.5
	sp.gravity = Vector3(0, -6, 0)
	sp.position = Vector3(-0.4, 1.2, -0.3)
	root.add_child(sp)
	_light(Vector3(-0.4, 1.8, -0.3), Color(1.0, 0.7, 0.4), 1.8, 6.0, root)
	_station("SATURN THE SMITH", pos, _open_saturn)


func _open_saturn() -> void:
	_ui_open = true
	player.frozen = true
	saturn_ui.open()


func _open_ayana() -> void:
	_ui_open = true
	player.frozen = true
	ayana_ui.open()


func _close_ui() -> void:
	skill_ui.visible = false
	altar_ui.visible = false
	retro_ui.visible = false
	if ayana_ui != null:
		ayana_ui.visible = false
	if saturn_ui != null:
		saturn_ui.visible = false
	if rising_ui != null:
		rising_ui.visible = false
	player.frozen = false
	# aynı Esc basışı menüye dönmesin diye bir kare bekle
	await get_tree().process_frame
	_ui_open = false


var rising_ui = null


func _enter_portal() -> void:
	# yükselen seçimi
	if rising_ui == null:
		rising_ui = load("res://scripts/rising_ui.gd").new()
		ui_layer.add_child(rising_ui)
		rising_ui.chosen.connect(_start_with_rising)
		rising_ui.closed.connect(_close_ui)
	_ui_open = true
	player.frozen = true
	rising_ui.open()


func _start_with_rising(id: String) -> void:
	GameData.start_run()
	GameData.run_rising = id
	Sfx.play("dash", -4.0, 0.0, 0, 0.6)
	Fx.shake(0.3)
	get_tree().change_scene_to_file(ROOM_SCENE)


func _message(text: String, dur := 4.0) -> void:
	msg_label.text = text
	msg_t = dur


# ---------------------------------------------------------------- döngü

func _process(delta: float) -> void:
	_t += delta
	dust_label.text = tr("%d stardust") % GameData.stardust
	var heat := Retro.heat(GameData.retro)
	if heat > 0:
		dust_label.text += "   ·   " + tr("RETRO %d") % heat
	if msg_t > 0.0:
		msg_t -= delta
		msg_label.modulate.a = clampf(msg_t, 0.0, 1.0)

	# gezegen düzeneği ve süslemeler
	for arm in orrery.get_children():
		if arm.has_meta("speed"):
			arm.rotation.y += delta * float(arm.get_meta("speed"))
	orrery.rotation.y += delta * 0.05
	for sp in spinners:
		(sp[0] as Node3D).rotation.y += delta * float(sp[1])
	for o in orbiters:
		(o as Node3D).rotation.y += delta * float(o.get_meta("speed"))
	for orb in planets:
		orb.position.y = float(orb.get_meta("base_y")) + sin(_t * 1.5 + float(orb.get_meta("phase"))) * 0.12
	for dr in dial_rings:
		(dr as Node3D).rotate_object_local(Vector3.UP, delta * float(dr.get_meta("spin")))
	if chart_ring != null:
		chart_ring.rotation.z += delta * 0.15
	if altar_weapon != null and is_instance_valid(altar_weapon):
		altar_slot.rotation.y += delta * 0.8
		altar_slot.position.y = 2.0 + sin(_t * 2.0) * 0.1

	# durak halkaları: yavaş nefes, yakınken daha parlak
	for st in stations:
		var spos: Vector3 = st["pos"]
		var dist := Vector2(player.global_position.x - spos.x, player.global_position.z - spos.z).length()
		var target := 1.0 if (dist < 3.8 and not _ui_open) else 0.0
		st["glow"] = lerpf(float(st["glow"]), target, 6.0 * delta)
		var g := float(st["glow"])
		var breath := 0.5 + 0.5 * sin(_t * 2.0 + spos.x)
		(st["mat"] as StandardMaterial3D).emission_energy_multiplier = 0.5 + breath * 0.6 + g * 2.0
		var sc := 1.0 + g * 0.06 + breath * 0.015
		(st["ring"] as Node3D).scale = Vector3(sc, 0.15, sc)

	if _ui_open:
		act_box.visible = false
		return

	# yakındaki durak
	var near = null
	var best := 3.8
	for s in stations:
		var sp: Vector3 = s["pos"]
		var d := Vector2(player.global_position.x - sp.x, player.global_position.z - sp.z).length()
		if d < best:
			best = d
			near = s
	if near != null:
		act_box.visible = true
		act_label.text = "[ E ]   %s" % tr(String(near["title"]))
		act_box.modulate.a = 0.8 + 0.2 * sin(_t * 5.0)
		if Input.is_action_just_pressed("interact"):
			act_box.visible = false
			near["action"].call()
	else:
		act_box.visible = false

	if Input.is_action_just_pressed("pause") and not pause_ui.visible:
		pause_ui.open()
