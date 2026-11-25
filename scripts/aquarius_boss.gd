extends "res://scripts/aries_boss.gd"
## KOVA: Fırtına Gözlemevi'nin efendisi, Suyun Taşıyıcısı. Havada süzülen, omzunda yıldızlı su testisi taşıyan dev bir figür.
## Kova bir hava burcudur ama su taşır: Su döker, sonra o suyu şimşekle elektriklendirir.
##  1. evre (100-65%):
##    - TESTİ DARBESİ: yakındaysan altın uyarı; parry'lenir
##    - SU DÖKÜŞÜ: testiden sana doğru dalga
##    - FIRTINA: arenaya ve üstüne şimşekler iner
##    - FIRTINA KÜRELERİ: seni yavaşça kovalayan küreler
##  2. evre (65-30%): + SEL: arenanın dört yanına su gölleri döker; şimşekler gölleri elektriklendirir (göllerin içi tehlikeli)
##  3. evre (<30%):   + YENİ ÇAĞ: etrafında dönen beş şimşek kolu; şimşek sıklaşır

signal hint(a: String, b: String)

const H = preload("res://scripts/hazards.gd")
const EnemyScript = preload("res://scripts/enemy.gd")
const SLAM := {"windup": 0.6, "act": 0.16, "recover": 0.6, "dmg": 26.0, "reach": 3.6, "arc": 130.0}
const SPARK := Color(0.65, 0.9, 1.0)
const WATER := Color(0.4, 0.65, 1.0)

var m_robe: StandardMaterial3D
var m_spark: StandardMaterial3D
var urn: Node3D
var _pools: Array = []        # [pozisyon, bitiş zamanı]
var _clock := 0.0


func _init() -> void:
	kind = "aquarius"
	title = "AQUARIUS  ·  THE WATER BEARER"
	max_hp = 3500.0
	hp = 3500.0
	radius = 1.3
	_cd = {"slam": 0.0, "pour": 1.0, "storm": 2.0, "orbs": 3.0, "flood": 0.5, "newage": 0.5}
	_global_cd = 1.0


func _build() -> void:
	m_robe = _m(Color(0.38, 0.36, 0.72), 0.5)
	m_robe.emission_enabled = true
	m_robe.emission = Color(0.4, 0.3, 1.0)
	m_robe.emission_energy_multiplier = 0.25
	m_body = _m(Color(0.82, 0.8, 1.0), 0.4)
	m_body.emission_enabled = true
	m_body.emission = Color(0.5, 0.45, 1.0)
	m_body.emission_energy_multiplier = 0.2
	m_spark = _m(SPARK, 0.2)
	m_spark.emission_enabled = true
	m_spark.emission = SPARK
	m_spark.emission_energy_multiplier = 2.0
	m_horn = m_spark
	m_eye = StandardMaterial3D.new()
	m_eye.albedo_color = Color.BLACK
	m_eye.emission_enabled = true
	m_eye.emission = Color(0.7, 1.0, 1.0)
	m_eye.emission_energy_multiplier = 5.0
	var m_urn := _m(Color(0.4, 0.55, 0.85), 0.2)
	m_urn.metallic = 0.7
	body_root = Node3D.new()
	add_child(body_root)
	vis = Node3D.new()
	body_root.add_child(vis)
	vis.scale = Vector3.ONE * 0.95
	# havada süzülen cübbe (ayak yok, uçta kıvılcım)
	_part(vis, _cone(0.25, 0.95, 2.4), Vector3(0, 2.0, 0), m_robe)
	_part(vis, _sph(0.65), Vector3(0, 3.2, 0), m_body, Vector3(1.1, 0.9, 0.8))
	_part(vis, _cone(0.04, 0.25, 0.5), Vector3(0, 0.6, 0), m_spark)
	# baş, saç yerine yükselen fırtına telleri
	head = Node3D.new()
	head.position = Vector3(0, 4.05, 0)
	vis.add_child(head)
	_part(head, _sph(0.38), Vector3.ZERO, m_body)
	for s in [-1.0, 1.0]:
		_part(head, _sph(0.06), Vector3(s * 0.14, 0.05, -0.34), m_eye, Vector3(1.4, 0.7, 1.0))
	for i in 7:
		var a := TAU * float(i) / 7.0
		var t := _part(head, _cone(0.06, 0.0, 0.7), Vector3(cos(a) * 0.25, 0.45, sin(a) * 0.25 + 0.05), m_spark)
		t.rotation = Vector3(sin(a) * 0.5, 0, -cos(a) * 0.5)
	# kollar: sol el boşta, sağ omuzda dev testi
	arm_l = Node3D.new()
	arm_l.position = Vector3(-0.75, 3.45, 0)
	vis.add_child(arm_l)
	_part(arm_l, _cone(0.14, 0.11, 1.4), Vector3(0, -0.6, 0), m_body)
	_part(arm_l, _sph(0.16), Vector3(0, -1.35, 0), m_spark)
	arm_r = Node3D.new()
	arm_r.position = Vector3(0.75, 3.45, 0)
	vis.add_child(arm_r)
	_part(arm_r, _cone(0.14, 0.11, 1.0), Vector3(0, 0.3, 0), m_body).rotation.z = -0.4
	urn = Node3D.new()
	urn.position = Vector3(0.9, 4.1, 0.2)
	vis.add_child(urn)
	_part(urn, _sph(0.6), Vector3.ZERO, m_urn, Vector3(1.0, 1.25, 1.0))
	_part(urn, _cone(0.26, 0.34, 0.4), Vector3(0, 0.8, 0), m_urn)
	_part(urn, _sph(0.28), Vector3(0, 1.0, 0), _m(Color(0.2, 0.3, 0.7), 0.1))
	for k in 6:
		var a2 := TAU * float(k) / 6.0
		_part(urn, _sph(0.05), Vector3(cos(a2) * 0.6, sin(a2) * 0.3, sin(a2) * 0.6), m_spark)
	urn.rotation.z = -0.5
	# testiden akan yıldızlı su
	mane = CPUParticles3D.new()
	mane.amount = 40
	mane.lifetime = 1.4
	var em := SphereMesh.new()
	em.radius = 0.07
	em.height = 0.14
	mane.mesh = em
	mane.material_override = Fx.emissive(WATER, 2.5)
	mane.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	mane.emission_sphere_radius = 0.2
	mane.direction = Vector3(1, 0.3, 0)
	mane.initial_velocity_min = 1.0
	mane.initial_velocity_max = 2.0
	mane.gravity = Vector3(0, -6.0, 0)
	mane.position = Vector3(1.4, 5.0, 0.2)
	vis.add_child(mane)
	var l := OmniLight3D.new()
	l.light_color = SPARK
	l.light_energy = 1.8
	l.omni_range = 7.0
	l.position = Vector3(0, 4.0, -0.5)
	vis.add_child(l)
	tele = MeshInstance3D.new()
	tele_mat = StandardMaterial3D.new()
	tele_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	tele_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	tele_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	tele_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	tele_mat.vertex_color_use_as_albedo = true
	tele.material_override = tele_mat
	tele.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	tele.visible = false
	add_child(tele)
	tele.top_level = true


func _place_tele() -> void:
	var b := Basis.looking_at(_aim_dir, Vector3.UP) if _aim_dir.length() > 0.1 else Basis.IDENTITY
	tele.global_transform = Transform3D(b, Vector3(global_position.x, 0.07, global_position.z))


func _speed_mult() -> float:
	return [1.0, 1.0, 1.1, 1.22][clampi(phase, 1, 3)]


func _windup_len() -> float:
	var k := windup_mult / _speed_mult()
	if atk == "slam":
		return float(SLAM["windup"]) * k
	return 0.75 * k


func _recover_len() -> float:
	return float(SLAM["recover"]) if atk == "slam" else 0.55


## Orta mesafede süzülür: çok yaklaşınca biraz geri çekilir
func _chase_vel(dist: float, dir_to: Vector3, sm: float) -> Vector3:
	if dist < 2.2:
		return -dir_to * 2.0 * sm
	if dist > 6.0:
		return dir_to * 3.6 * sm
	return dir_to.rotated(Vector3.UP, PI * 0.5) * 1.6 * sm


func _pick(dist: float, dir_to: Vector3) -> void:
	var opts: Array = []
	if float(_cd["slam"]) <= 0.0 and dist < 4.0:
		opts.append_array(["slam", "slam", "slam"])
	if float(_cd["pour"]) <= 0.0:
		opts.append_array(["pour", "pour"])
	if float(_cd["storm"]) <= 0.0:
		opts.append_array(["storm", "storm"])
	if float(_cd["orbs"]) <= 0.0:
		opts.append("orbs")
	if phase >= 2 and float(_cd["flood"]) <= 0.0:
		opts.append_array(["flood", "flood"])
	if phase >= 3 and float(_cd["newage"]) <= 0.0:
		opts.append_array(["newage", "newage"])
	if opts.is_empty():
		return
	atk = String(opts[randi() % opts.size()])
	_aim_dir = dir_to
	_set_state("windup")


func _set_state(s: String) -> void:
	state = s
	_st = 0.0
	match s:
		"windup":
			tele.visible = false
			if atk == "slam":
				_show_tele(_fan_mesh(deg_to_rad(float(SLAM["arc"])), float(SLAM["reach"])), PARRY_COL)
			Sfx.play("bossroar", -10.0, 0.08, 0, 1.1)
		"act":
			_done = false
			tele.visible = false
		"recover":
			tele.visible = false
			_global_cd = randf_range(0.3, 0.6) / _speed_mult()
			match atk:
				"slam":
					_cd["slam"] = 1.3
				"pour":
					_cd["pour"] = 4.5
				"storm":
					_cd["storm"] = 5.0 if phase < 3 else 3.2
				"orbs":
					_cd["orbs"] = 7.0
				"flood":
					_cd["flood"] = 12.0
				"newage":
					_cd["newage"] = 11.0
		_:
			tele.visible = false


func _bolt(p: Vector3, delay: float, r: float) -> void:
	var b := H.Blast.new()
	b.hero = hero
	b.radius = r
	b.delay = delay
	b.dmg = 18.0 * dmg_mult
	b.col = SPARK
	b.eff = "slow"
	get_parent().add_child(b)
	b.global_position = H.clamp_arena(p, _bounds)


func _act(_delta: float, _sm: float) -> Vector3:
	match atk:
		"slam":
			if not _done and _st >= 0.06:
				_done = true
				_slam_hit()
			if _st >= float(SLAM["act"]):
				_set_state("recover")
			return _aim_dir * 5.0
		"pour":
			if not _done:
				_done = true
				var n := 1 if phase < 2 else 3
				for i in n:
					var tw := EnemyScript.TideWave.new()
					tw.hero = hero
					tw.dir = _aim_dir.rotated(Vector3.UP, (float(i) - float(n - 1) * 0.5) * 0.55)
					tw.dmg = 18.0 * dmg_mult
					tw.width = 4.0
					tw.speed = 8.0
					tw.travel = _bounds * 2.0
					get_parent().add_child(tw)
					tw.global_position = Vector3(global_position.x, 0, global_position.z) + _aim_dir * 0.8
				Sfx.play("dash", -6.0, 0.05, 0, 0.6)
			if _st >= 0.4:
				_set_state("recover")
		"storm":
			if not _done:
				_done = true
				# önce senin üstüne, sonra arenaya; 2. evreden itibaren gölleri de çarpar
				if H.hero_ok(hero):
					_bolt(hero.global_position, 1.0, 1.4)
				var cnt := 4 if phase < 3 else 6
				for i in cnt:
					var a := randf() * TAU
					_bolt(Vector3(cos(a), 0, sin(a)) * randf_range(2.0, _bounds - 0.5), 1.0 + float(i) * 0.15, 1.3)
				_clean_pools()
				for pl in _pools:
					_bolt(pl[0], 1.3, 2.6)
				Sfx.play("boom", -8.0, 0.0, 0, 1.4)
			if _st >= 0.4:
				_set_state("recover")
		"orbs":
			if not _done:
				_done = true
				for i in 3:
					var sh := H.Shot.new()
					sh.hero = hero
					sh.vel = _aim_dir.rotated(Vector3.UP, (float(i) - 1.0) * 0.8) * 4.0
					sh.homing = 1.3
					sh.dmg = 15.0 * dmg_mult
					sh.radius = 0.7
					sh.life = 6.0
					sh.size = 0.45
					sh.col = SPARK
					sh.eff = "slow"
					get_parent().add_child(sh)
					sh.global_position = global_position + Vector3(0, 2.0, 0) + _aim_dir * 1.0
				Sfx.play("parry", -8.0, 0.05, 0, 2.4)
			if _st >= 0.4:
				_set_state("recover")
		"flood":
			if not _done:
				_done = true
				hint.emit("THE FLOOD", tr("Lightning seeks the water — stay dry"))
				var base := randf() * TAU
				for i in 4:
					var a := base + TAU * float(i) / 4.0
					var p := Vector3(cos(a), 0, sin(a)) * randf_range(4.0, _bounds - 2.5)
					var pool := H.Pool.new()
					pool.hero = hero
					pool.radius = 2.4
					pool.life = 10.0
					pool.dps = 3.0 * dmg_mult
					pool.col = WATER
					pool.eff = "slow"
					get_parent().add_child(pool)
					pool.global_position = p
					_pools.append([p, _clock + 10.0])
				Sfx.play("dash", -4.0, 0.05, 0, 0.5)
			if _st >= 0.5:
				_set_state("recover")
		"newage":
			if not _done:
				_done = true
				var sp := H.Spokes.new()
				sp.hero = hero
				sp.follow = self
				sp.arms = 5
				sp.length = 11.0
				sp.width = 0.9
				sp.spin = 0.85 * (1.0 if randf() < 0.5 else -1.0)
				sp.warn = 1.1
				sp.life = 6.0
				sp.dmg = 18.0 * dmg_mult
				sp.col = SPARK
				sp.eff = "slow"
				get_parent().add_child(sp)
				sp.global_position = Vector3(global_position.x, 0, global_position.z)
				Sfx.play("bossroar", -4.0, 0.0, 0, 1.3)
			if _st >= 0.5:
				_set_state("recover")
	return Vector3.ZERO


func _clean_pools() -> void:
	var keep: Array = []
	for pl in _pools:
		if float(pl[1]) > _clock + 1.3:
			keep.append(pl)
	_pools = keep


func _physics_process(delta: float) -> void:
	_clock += delta
	super._physics_process(delta)


func _slam_hit() -> void:
	var reach := float(SLAM["reach"])
	var arc := deg_to_rad(float(SLAM["arc"]))
	var fx := SlashFx.make(-arc * 0.5, arc * 0.5, 0.8, reach, PARRY_COL, 0.22)
	get_parent().add_child(fx)
	fx.global_transform = Transform3D(Basis.looking_at(_aim_dir, Vector3.UP), global_position + Vector3(0, 1.5, 0))
	Sfx.play("crush", -5.0, 0.1, 0, 0.9)
	if not H.hero_ok(hero):
		return
	var to: Vector3 = hero.global_position - global_position
	to.y = 0.0
	var dist := to.length()
	if dist > reach + 0.4 or (dist > 0.3 and _aim_dir.angle_to(to / dist) > arc * 0.5):
		return
	var res: String = hero.take_damage(float(SLAM["dmg"]) * dmg_mult, to.normalized() if dist > 0.05 else _aim_dir, true)
	if res == "parried":
		stun(2.4, true)
		_knock = -_aim_dir * 3.0


func _damage(d: float) -> void:
	hp -= d
	if hp <= 0.0:
		_die()
		return
	if phase == 1 and hp < max_hp * 0.65:
		_enter_phase(2)
	elif phase == 2 and hp < max_hp * 0.3:
		_enter_phase(3)


func _enter_phase(p: int) -> void:
	phase = p
	tele.visible = false
	_set_state("roar")
	Fx.shake(0.8)
	Fx.flash_light(global_position + Vector3(0, 4, 0), SPARK, 12.0, 18.0, 0.8)
	Sfx.play("bossroar", 0.0, 0.0, 0, 1.0)
	mane.amount = 40 if p == 1 else (70 if p == 2 else 110)
	if p == 2:
		_cd["flood"] = 0.3
		summon.emit(["shade", "shade", "caster"])
	elif p == 3:
		_cd["newage"] = 0.3
		hint.emit("THE NEW AGE", tr("The storm turns around the Water Bearer"))
		summon.emit(["leaper", "brute"])
	phase_changed.emit(p)


func _animate(delta: float) -> void:
	body_root.rotation.y = lerp_angle(body_root.rotation.y, atan2(-_face.x, -_face.z), minf(6.0 * delta, 1.0))
	vis.position.y = 0.25 + sin(_clock * 1.6) * 0.2
	var tilt := -0.5
	var arm_x := 0.0
	var glow := 5.0
	match state:
		"windup":
			var k := clampf(_st / _windup_len(), 0.0, 1.0)
			if atk == "slam" or atk == "pour":
				tilt = -0.5 - 1.2 * k
			else:
				arm_x = -2.4 * k
			glow = 5.0 + 14.0 * k
		"act":
			tilt = -1.9 if atk == "pour" or atk == "slam" else -0.5
			arm_x = -2.6 if atk != "slam" and atk != "pour" else 0.0
			glow = 16.0
		"roar":
			arm_x = -2.8
			glow = 20.0
		"stun":
			tilt = 0.0
			glow = 1.5
	urn.rotation.z = lerpf(urn.rotation.z, tilt, minf(8.0 * delta, 1.0))
	arm_l.rotation.x = lerpf(arm_l.rotation.x, arm_x, minf(10.0 * delta, 1.0))
	m_eye.emission_energy_multiplier = glow
	m_body.emission_energy_multiplier = 0.2 + _flash * 3.0
	m_spark.emission_energy_multiplier = 2.0 + glow * 0.1
