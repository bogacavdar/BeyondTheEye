extends CharacterBody3D
## YOLCU (ana karakter için yer tutucu)
## İnsan oranlarında (~1.8 m, 7.5 baş boyu) eklemli bir figür: kalça, diz, omuz ve dirsek eklemleri var,
## yürürken bacaklar ve kollar karşılıklı sallanır, pelerin arkada dalgalanır.
## Görünüş: lacivert tunik, koyu pantolon ve çizme, altın işlemeli kemer ve omuzluklar,
## kukuleteli lacivert pelerin; kukuletenin gölgesinde yüz, iki altın göz.
## WASD yürür, Boşluk atılır. frozen=true iken (menü açıkken) hareket etmez.

const SPEED := 6.0
const ACCEL := 120.0      # hızlanma (eskiden 50: yön değiştirince ağır kalıyordu)
const BRAKE := 260.0      # ters yöne basınca / bırakınca anında fren
const DASH_SPEED := 14.0   # ~2.2 m
const DASH_TIME := 0.16

var camera = null
var frozen := false
var bound_radius := 12.6
var dash_t := 0.0
var dash_cd := 0.0
var dash_dir := Vector3.FORWARD
var walk_t := 0.0
var walk_amt := 0.0
var _t := 0.0

var pivot: Node3D
var body: Node3D        # kalçadan yukarısı (eğilme için)
var chest: Node3D
var head: Node3D
var hip_l: Node3D
var hip_r: Node3D
var knee_l: Node3D
var knee_r: Node3D
var sh_l: Node3D
var sh_r: Node3D
var el_l: Node3D
var el_r: Node3D
var cape: Node3D
var trail: CPUParticles3D

var m_navy: StandardMaterial3D
var m_navy2: StandardMaterial3D
var m_dark: StandardMaterial3D
var m_leather: StandardMaterial3D
var m_gold: StandardMaterial3D
var m_skin: StandardMaterial3D
var m_eye: StandardMaterial3D


func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.35
	cap.height = 1.8
	cs.shape = cap
	cs.position.y = 0.9
	add_child(cs)

	_materials()
	pivot = Node3D.new()
	add_child(pivot)
	_build_body()

	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.85, 0.55)
	l.light_energy = 0.8
	l.omni_range = 5.0
	l.position = Vector3(0, 2.3, -0.4)
	add_child(l)

	# atılırken bırakılan altın toz izi
	trail = CPUParticles3D.new()
	trail.amount = 40
	trail.lifetime = 0.5
	var tm := SphereMesh.new()
	tm.radius = 0.04
	tm.height = 0.08
	trail.mesh = tm
	trail.material_override = m_eye
	trail.gravity = Vector3(0, 0.5, 0)
	trail.spread = 180.0
	trail.initial_velocity_min = 0.2
	trail.initial_velocity_max = 0.8
	trail.local_coords = false
	trail.emitting = false
	trail.position = Vector3(0, 0.9, 0)
	add_child(trail)


func _mat(c: Color, rough: float, metal := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	return m


func _materials() -> void:
	m_navy = _mat(Color(0.08, 0.12, 0.32), 0.7)
	m_navy2 = _mat(Color(0.05, 0.08, 0.22), 0.8)
	m_dark = _mat(Color(0.06, 0.06, 0.09), 0.8)
	m_leather = _mat(Color(0.16, 0.1, 0.07), 0.6)
	m_gold = _mat(Color(0.95, 0.8, 0.42), 0.25, 1.0)
	m_skin = _mat(Color(0.78, 0.6, 0.48), 0.65)
	m_eye = StandardMaterial3D.new()
	m_eye.albedo_color = Color(0, 0, 0)
	m_eye.emission_enabled = true
	m_eye.emission = Color(1.0, 0.85, 0.4)
	m_eye.emission_energy_multiplier = 6.0


# ---------------------------------------------------------------- yardımcılar

func _joint(parent: Node3D, pos: Vector3) -> Node3D:
	var n := Node3D.new()
	n.position = pos
	parent.add_child(n)
	return n


func _part(parent: Node3D, mesh: Mesh, pos: Vector3, m: Material, scale_v := Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = m
	mi.position = pos
	mi.scale = scale_v
	parent.add_child(mi)
	return mi


func _capsule(r: float, h: float) -> CapsuleMesh:
	var c := CapsuleMesh.new()
	c.radius = r
	c.height = maxf(h, r * 2.0)
	c.radial_segments = 16
	c.rings = 6
	return c


func _cyl(r_bot: float, r_top: float, h: float) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.bottom_radius = r_bot
	c.top_radius = r_top
	c.height = h
	c.radial_segments = 18
	return c


func _ball(r: float) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	s.radial_segments = 20
	s.rings = 10
	return s


func _box(sx: float, sy: float, sz: float) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = Vector3(sx, sy, sz)
	return b


# ---------------------------------------------------------------- beden
# Karakter -Z yönüne bakar. Yükseklikler metre cinsinden: kalça 0.92, omuz 1.46, baş tepesi ~1.8.

func _build_body() -> void:
	# --- bacaklar (kalça eklemi -> uyluk -> diz eklemi -> baldır -> çizme)
	hip_l = _joint(pivot, Vector3(-0.1, 0.92, 0))
	hip_r = _joint(pivot, Vector3(0.1, 0.92, 0))
	knee_l = _leg(hip_l)
	knee_r = _leg(hip_r)

	# --- gövde (kalçanın üstü)
	body = _joint(pivot, Vector3(0, 0.92, 0))
	# pelvis
	_part(body, _ball(0.17), Vector3(0, 0.02, 0), m_dark, Vector3(1.05, 0.7, 0.8))
	# tunik eteği (kemerden uyluk ortasına)
	_part(body, _cyl(0.24, 0.17, 0.36), Vector3(0, -0.1, 0), m_navy, Vector3(1.0, 1.0, 0.82))
	_part(body, _cyl(0.245, 0.245, 0.03), Vector3(0, -0.27, 0), m_gold, Vector3(1.0, 1.0, 0.82))
	# bel ve göğüs
	chest = _joint(body, Vector3(0, 0.12, 0))
	_part(chest, _cyl(0.15, 0.17, 0.22), Vector3(0, 0.08, 0), m_navy, Vector3(1.0, 1.0, 0.75))
	_part(chest, _ball(0.2), Vector3(0, 0.3, 0), m_navy, Vector3(1.05, 0.95, 0.68))
	# göğüste altın yıldız işlemesi
	var star := _part(chest, _cyl(0.045, 0.045, 0.02), Vector3(0, 0.3, -0.135), m_gold)
	star.rotation.x = PI * 0.5
	# kemer ve tokası
	_part(chest, _cyl(0.165, 0.165, 0.05), Vector3(0, -0.02, 0), m_leather, Vector3(1.0, 1.0, 0.78))
	_part(chest, _box(0.07, 0.06, 0.02), Vector3(0, -0.02, -0.13), m_gold)
	# çapraz kayış
	var strap := _part(chest, _box(0.05, 0.5, 0.02), Vector3(0, 0.25, -0.14), m_leather)
	strap.rotation.z = 0.6

	# --- omuzlar ve kollar
	sh_l = _joint(chest, Vector3(-0.215, 0.43, 0))
	sh_r = _joint(chest, Vector3(0.215, 0.43, 0))
	el_l = _arm(sh_l, -1.0)
	el_r = _arm(sh_r, 1.0)

	# --- boyun ve baş
	_part(chest, _cyl(0.05, 0.045, 0.12), Vector3(0, 0.52, 0), m_skin)
	head = _joint(chest, Vector3(0, 0.66, 0))
	_part(head, _ball(0.105), Vector3(0, 0, 0), m_skin, Vector3(0.92, 1.12, 1.0))
	# çene ve burun
	_part(head, _ball(0.05), Vector3(0, -0.07, -0.05), m_skin, Vector3(1.2, 0.8, 1.0))
	_part(head, _ball(0.018), Vector3(0, 0.0, -0.105), m_skin, Vector3(0.9, 1.4, 1.0))
	# gözler (altın ışıltılı)
	_part(head, _ball(0.014), Vector3(-0.036, 0.025, -0.092), m_eye)
	_part(head, _ball(0.014), Vector3(0.036, 0.025, -0.092), m_eye)
	# kukulete: başın arkasını ve üstünü saran, öne açık
	_part(head, _ball(0.135), Vector3(0, 0.025, 0.035), m_navy, Vector3(1.0, 1.08, 1.0))
	var hood_rim := TorusMesh.new()
	hood_rim.inner_radius = 0.105
	hood_rim.outer_radius = 0.125
	var hr := _part(head, hood_rim, Vector3(0, 0.02, -0.075), m_gold, Vector3(0.95, 1.0, 1.15))
	hr.rotation.x = PI * 0.5
	# kukuleteden omuzlara inen yaka
	_part(chest, _ball(0.2), Vector3(0, 0.47, 0.03), m_navy2, Vector3(1.25, 0.4, 0.95))

	# --- pelerin: omuzlardan sarkan, arkada dalgalanan
	cape = _joint(chest, Vector3(0, 0.46, 0.14))
	var cm := _part(cape, _box(0.5, 1.15, 0.025), Vector3(0, -0.56, 0.0), m_navy2)
	cm.scale = Vector3(1.0, 1.0, 1.0)
	var cape_low := _part(cape, _box(0.58, 0.5, 0.024), Vector3(0, -0.92, 0.01), m_navy2)
	cape_low.scale = Vector3(1.0, 1.0, 1.0)
	_part(cape, _box(0.585, 0.035, 0.03), Vector3(0, -1.165, 0.01), m_gold)
	# pelerin tokaları
	_part(chest, _ball(0.035), Vector3(-0.17, 0.45, -0.06), m_gold)
	_part(chest, _ball(0.035), Vector3(0.17, 0.45, -0.06), m_gold)


func _leg(hip: Node3D) -> Node3D:
	# uyluk
	_part(hip, _capsule(0.075, 0.46), Vector3(0, -0.22, 0), m_dark)
	var knee := _joint(hip, Vector3(0, -0.44, 0))
	_part(knee, _ball(0.07), Vector3.ZERO, m_dark)
	# baldır ve çizme
	_part(knee, _capsule(0.06, 0.42), Vector3(0, -0.2, 0), m_dark)
	_part(knee, _cyl(0.072, 0.078, 0.24), Vector3(0, -0.3, 0), m_leather)
	_part(knee, _cyl(0.082, 0.082, 0.03), Vector3(0, -0.18, 0), m_gold)
	# ayak (öne doğru uzanan)
	_part(knee, _box(0.11, 0.07, 0.24), Vector3(0, -0.445, -0.05), m_leather)
	return knee


func _arm(shoulder: Node3D, side: float) -> Node3D:
	# omuzluk (altın)
	_part(shoulder, _ball(0.09), Vector3(side * 0.01, 0.01, 0), m_gold, Vector3(1.15, 0.75, 1.0))
	# üst kol
	_part(shoulder, _capsule(0.055, 0.3), Vector3(0, -0.15, 0), m_navy)
	var elbow := _joint(shoulder, Vector3(0, -0.29, 0))
	# ön kol, bileklik, el
	_part(elbow, _capsule(0.048, 0.27), Vector3(0, -0.13, 0), m_navy)
	_part(elbow, _cyl(0.055, 0.052, 0.1), Vector3(0, -0.21, 0), m_leather)
	_part(elbow, _cyl(0.057, 0.057, 0.02), Vector3(0, -0.165, 0), m_gold)
	_part(elbow, _ball(0.05), Vector3(0, -0.3, 0), m_skin, Vector3(0.8, 1.15, 0.9))
	shoulder.rotation.z = side * 0.08   # kollar gövdeye yapışık durmasın
	return elbow


# ---------------------------------------------------------------- hareket

func _physics_process(delta: float) -> void:
	_t += delta
	dash_cd -= delta
	var move := Vector3.ZERO
	if not frozen and camera != null:
		var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
		var b: Basis = camera.global_transform.basis
		var fwd := -b.z
		fwd.y = 0.0
		fwd = fwd.normalized()
		var right := b.x
		right.y = 0.0
		right = right.normalized()
		move = right * input.x - fwd * input.y
		if move.length() > 1.0:
			move = move.normalized()
		if Input.is_action_just_pressed("dash") and dash_cd <= 0.0:
			dash_dir = move.normalized() if move.length() > 0.1 else -pivot.global_transform.basis.z
			dash_t = DASH_TIME
			dash_cd = 0.5
			Sfx.play("dash", -10.0)

	if dash_t > 0.0:
		dash_t -= delta
		velocity = dash_dir * DASH_SPEED
	else:
		var sp := SPEED * (1.6 if Input.is_action_pressed("sprint") else 1.0)
		velocity = _steer(velocity, move * sp, delta)
	velocity.y = 0.0
	trail.emitting = dash_t > 0.0
	move_and_slide()

	# platformun dışına çıkma
	var flat := Vector2(global_position.x, global_position.z)
	if flat.length() > bound_radius:
		flat = flat.normalized() * bound_radius
		global_position = Vector3(flat.x, 0.0, flat.y)
	global_position.y = 0.0

	var hv := Vector3(velocity.x, 0, velocity.z)
	var spd := hv.length()
	if spd > 0.3:
		pivot.rotation.y = lerp_angle(pivot.rotation.y, atan2(-hv.x, -hv.z), minf(22.0 * delta, 1.0))
	_animate(delta, spd)
	if camera != null:
		camera.look_ahead = Vector3.ZERO


func _animate(delta: float, spd: float) -> void:
	var dashing := dash_t > 0.0
	var target := clampf(spd / SPEED, 0.0, 1.0)
	walk_amt = lerpf(walk_amt, target, 10.0 * delta)
	walk_t += delta * (2.0 + spd * 1.25)

	var s := sin(walk_t)
	var swing := s * 0.65 * walk_amt
	# bacaklar: uyluk öne-arkaya, diz geride kalan bacakta bükülür
	hip_l.rotation.x = swing
	hip_r.rotation.x = -swing
	knee_l.rotation.x = -maxf(0.0, -s) * 1.0 * walk_amt - 0.05
	knee_r.rotation.x = -maxf(0.0, s) * 1.0 * walk_amt - 0.05
	# kollar bacakların tersine, dirsekler hafif bükük
	sh_l.rotation.x = -swing * 0.8
	sh_r.rotation.x = swing * 0.8
	el_l.rotation.x = 0.2 + maxf(0.0, -swing) * 0.6
	el_r.rotation.x = 0.2 + maxf(0.0, swing) * 0.6

	# adım zıplaması, gövde salınımı ve nefes
	var bob := absf(cos(walk_t)) * 0.045 * walk_amt
	var breathe := sin(_t * 2.2) * 0.008 * (1.0 - walk_amt)
	pivot.position.y = bob
	body.rotation.x = lerpf(body.rotation.x, -0.12 * walk_amt - (0.35 if dashing else 0.0), 12.0 * delta)
	chest.rotation.y = -swing * 0.15
	chest.position.y = 0.12 + breathe
	head.rotation.y = swing * 0.1

	# atılmada bacaklar açılır
	if dashing:
		hip_l.rotation.x = 0.7
		hip_r.rotation.x = -0.6
		knee_r.rotation.x = -0.9
		sh_l.rotation.x = 0.5
		sh_r.rotation.x = 0.5

	# pelerin: hızla geriye kalkar, hafifçe dalgalanır
	var lift := 0.12 + walk_amt * 0.45 + (0.5 if dashing else 0.0)
	var flutter := sin(_t * 6.0) * 0.05 * (0.3 + walk_amt)
	cape.rotation.x = lerpf(cape.rotation.x, -(lift + flutter), 8.0 * delta)


## Tepkili hareket: yeni yön mevcut hızla ters düşüyorsa hız o eksende anında kesilir,
## böylece sağdan sola geçişte "kayma" olmaz; karakter tuşa basıldığı an döner.
func _steer(v: Vector3, target: Vector3, delta: float) -> Vector3:
	var flat := Vector3(v.x, 0.0, v.z)
	if target.length() < 0.01:
		return flat.move_toward(Vector3.ZERO, BRAKE * delta)
	var dir := target.normalized()
	var along := flat.dot(dir)
	if along < 0.0:
		flat -= dir * along   # ters yöndeki bileşeni sıfırla
	var side := flat - dir * flat.dot(dir)
	flat -= side * minf(18.0 * delta, 1.0)   # yan kaymayı hızla sönümle
	return flat.move_toward(target, ACCEL * delta)
