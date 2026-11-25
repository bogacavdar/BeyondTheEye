extends "res://scripts/aries_boss.gd"
## BAŞAK: Sessiz Hasat'ın hanımı, Hasat Bakiresi. Kanatlı, porselen yüzlü, dev oraklı;
## dövüşü DÜZEN üzerine kurulu: saldırıları bir sıra ve desen izler, deseni okuyan kazanır.
##  1. evre (100-65%):
##    - ORAK SAVURUŞU: altın uyarı, iki savuruş art arda; parry'lenir
##    - DEMET ATIŞI: üç başak demeti fırlatır, düştükleri yer yavaşlatır
##    - ÇÖZÜMLEME: geçtiğin yolu not eder; izlediğin yolu sırayla patlatır (durmadan yön değiştir)
##  2. evre (65-30%): + SAFLIK IZGARASI: arena dama tahtası gibi; önce bir renk, sonra öbürü patlar
##  3. evre (<30%):   + HASAT AYI: dev orak arenayı bir uçtan öbür uca biçer; dalganın arkasına atıl

signal hint(a: String, b: String)

const H = preload("res://scripts/hazards.gd")
const REAP := {"windup": 0.6, "act": 0.16, "recover": 0.6, "dmg": 22.0, "reach": 4.2, "arc": 160.0}
const TEAL := Color(0.35, 1.0, 0.85)

var _reaps_left := 0
var _marks: Array = []
var _mark_t := 0.0
var m_robe: StandardMaterial3D
var _wings: Array = []


func _init() -> void:
	kind = "virgo"
	title = "VIRGO  ·  THE HARVEST MAIDEN"
	max_hp = 2900.0
	hp = 2900.0
	radius = 1.1
	_cd = {"reap": 0.4, "sheaf": 1.5, "analysis": 3.0, "grid": 1.0, "moon": 1.0}
	_global_cd = 1.1


# ---------------------------------------------------------------- görünüş: kanatlı, oraklı porselen bakire

func _build() -> void:
	m_body = _m(Color(0.94, 0.93, 0.98), 0.25)
	m_body.emission_enabled = true
	m_body.emission = Color(0.5, 0.45, 0.9)
	m_body.emission_energy_multiplier = 0.15
	m_robe = _m(Color(0.42, 0.36, 0.72), 0.7)
	m_robe.emission_enabled = true
	m_robe.emission = Color(0.35, 0.25, 0.8)
	m_robe.emission_energy_multiplier = 0.2
	m_horn = _m(Color(0.88, 0.92, 0.96), 0.2, 0.7)
	m_eye = StandardMaterial3D.new()
	m_eye.albedo_color = Color.BLACK
	m_eye.emission_enabled = true
	m_eye.emission = TEAL
	m_eye.emission_energy_multiplier = 5.0
	var wheat := _m(Color(0.9, 0.92, 0.85), 0.6)
	wheat.emission_enabled = true
	wheat.emission = Color(0.6, 1.0, 0.9)
	wheat.emission_energy_multiplier = 0.4

	body_root = Node3D.new()
	add_child(body_root)
	vis = Node3D.new()
	body_root.add_child(vis)
	vis.scale = Vector3.ONE * 0.8
	# uzun, yere değen cüppe
	_part(vis, _cone(1.3, 0.45, 3.0), Vector3(0, 1.5, 0), m_robe)
	_part(vis, _sph(0.6), Vector3(0, 3.3, 0), m_body, Vector3(1.0, 1.2, 0.75))
	_part(vis, _cone(0.7, 0.62, 0.15), Vector3(0, 2.95, 0), m_horn)
	# baş ve başak tacı
	head = Node3D.new()
	head.position = Vector3(0, 4.25, 0)
	vis.add_child(head)
	_part(head, _sph(0.38), Vector3.ZERO, m_body, Vector3(0.9, 1.05, 0.95))
	for s in [-1.0, 1.0]:
		_part(head, _sph(0.06), Vector3(s * 0.14, 0.02, -0.33), m_eye, Vector3(1.6, 0.6, 1.0))
	_part(head, _sph(0.42), Vector3(0, 0.08, 0.1), m_robe, Vector3(1.0, 1.05, 1.0))
	for i in 9:
		var a := -1.2 + float(i) * 0.3
		var w := _part(head, _cone(0.05, 0.0, 0.6), Vector3(sin(a) * 0.38, 0.4, cos(a) * 0.12), wheat)
		w.rotation.z = -a * 0.5
	# kanatlar: katmanlı tüy panelleri
	for s in [-1.0, 1.0]:
		var wing := Node3D.new()
		wing.position = Vector3(s * 0.4, 3.6, 0.45)
		vis.add_child(wing)
		_wings.append(wing)
		for k in 5:
			var f := _part(wing, _sph(0.5), Vector3(s * (0.5 + float(k) * 0.4), 0.3 - float(k) * 0.25, float(k) * 0.05), m_body, Vector3(0.9, 0.35 + float(k) * 0.12, 0.06))
			f.rotation.z = s * (0.3 + float(k) * 0.15)
	# kollar ve dev orak
	arm_l = _sleeve(-1.0)
	arm_r = _sleeve(1.0)
	_part(arm_r, _cone(0.06, 0.06, 4.2), Vector3(0, -1.2, -0.2), m_horn)
	var blade := _part(arm_r, _sph(1.0), Vector3(-0.9, 0.85, -0.2), m_horn, Vector3(1.4, 0.25, 0.08))
	blade.rotation.z = 0.35
	_part(arm_r, _sph(0.16), Vector3(0, 0.9, -0.2), _glow_mat(TEAL, 3.0))

	mane = CPUParticles3D.new()
	mane.amount = 24
	mane.lifetime = 2.0
	var em := QuadMesh.new()
	em.size = Vector2(0.08, 0.16)
	mane.mesh = em
	mane.material_override = Fx.emissive(Color(0.75, 1.0, 0.9), 3.0)
	mane.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	mane.emission_sphere_radius = 1.2
	mane.direction = Vector3(0, 1, 0)
	mane.spread = 60.0
	mane.gravity = Vector3(0, -0.4, 0)
	mane.initial_velocity_min = 0.2
	mane.initial_velocity_max = 0.8
	mane.position = Vector3(0, 3.2, 0)
	vis.add_child(mane)
	var l := OmniLight3D.new()
	l.light_color = Color(0.6, 1.0, 0.9)
	l.light_energy = 1.5
	l.omni_range = 7.0
	l.position = Vector3(0, 4.0, -0.8)
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


func _glow_mat(c: Color, e: float) -> StandardMaterial3D:
	var m := _m(c, 0.3)
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = e
	return m


func _sleeve(side: float) -> Node3D:
	var sh := Node3D.new()
	sh.position = Vector3(side * 0.7, 3.5, 0)
	vis.add_child(sh)
	_part(sh, _cone(0.3, 0.16, 1.4), Vector3(0, -0.7, 0), m_robe)
	_part(sh, _sph(0.14), Vector3(0, -1.45, 0), m_body)
	sh.rotation.z = side * 0.15
	return sh


func _place_tele() -> void:
	var b := Basis.looking_at(_aim_dir, Vector3.UP) if _aim_dir.length() > 0.1 else Basis.IDENTITY
	tele.global_transform = Transform3D(b, Vector3(global_position.x, 0.07, global_position.z))


# ---------------------------------------------------------------- yapay zekâ

func _speed_mult() -> float:
	match phase:
		1:
			return 1.0
		2:
			return 1.12
	return 1.3


func _windup_len() -> float:
	var k := windup_mult / _speed_mult()
	match atk:
		"reap":
			return (float(REAP["windup"]) if _reaps_left > 0 else 0.4) * k
		"sheaf":
			return 0.7 * k
		"analysis":
			return 0.5 * k
		"grid":
			return 0.6 * k
		"moon":
			return 0.9 * k
	return 0.6


func _recover_len() -> float:
	match atk:
		"reap":
			return float(REAP["recover"]) / _speed_mult()
		"analysis":
			return 0.4
		"moon":
			return 1.0
	return 0.6


func _pick(dist: float, dir_to: Vector3) -> void:
	var opts: Array = []
	if float(_cd["reap"]) <= 0.0 and dist < 4.3:
		opts.append_array(["reap", "reap", "reap"])
	if float(_cd["sheaf"]) <= 0.0 and dist > 3.0:
		opts.append_array(["sheaf", "sheaf"])
	if float(_cd["analysis"]) <= 0.0:
		opts.append("analysis")
	if phase >= 2 and float(_cd["grid"]) <= 0.0:
		opts.append("grid")
	if phase >= 3 and float(_cd["moon"]) <= 0.0:
		opts.append("moon")
	if opts.is_empty():
		return
	atk = String(opts[randi() % opts.size()])
	_aim_dir = dir_to
	if atk == "reap":
		_reaps_left = 1
	_set_state("windup")


func _set_state(s: String) -> void:
	state = s
	_st = 0.0
	match s:
		"windup":
			tele.visible = false
			if atk == "reap":
				_show_tele(_fan_mesh(deg_to_rad(float(REAP["arc"])), float(REAP["reach"])), PARRY_COL)
			Sfx.play("bossroar", -8.0 if atk != "reap" else -12.0, 0.08, 0, 1.3)
		"act":
			_done = false
			_mark_t = 0.0
			_marks.clear()
			tele.visible = false
			Sfx.play("dash", -6.0, 0.1, 0, 0.8)
		"recover":
			tele.visible = false
			_global_cd = randf_range(0.25, 0.55) / _speed_mult()
			match atk:
				"reap":
					_cd["reap"] = 1.2
				"sheaf":
					_cd["sheaf"] = 4.5
				"analysis":
					_cd["analysis"] = 7.0
				"grid":
					_cd["grid"] = 12.0
				"moon":
					_cd["moon"] = 12.0
		_:
			tele.visible = false


func _act(_delta: float, _sm: float) -> Vector3:
	match atk:
		"reap":
			if not _done and _st >= 0.06:
				_done = true
				_reap_hit()
			if _st >= float(REAP["act"]) and state == "act":
				if _reaps_left > 0:
					_reaps_left -= 1
					if H.hero_ok(hero):
						var nd: Vector3 = hero.global_position - global_position
						nd.y = 0.0
						if nd.length() > 0.3:
							_aim_dir = nd.normalized()
					_set_state("windup")
				else:
					_set_state("recover")
			return _aim_dir * 5.0
		"sheaf":
			if not _done:
				_done = true
				if H.hero_ok(hero):
					var n := 3 if phase < 3 else 5
					for i in n:
						var p: Vector3 = hero.global_position
						if i > 0:
							p += Vector3(randf_range(-3.0, 3.0), 0, randf_range(-3.0, 3.0))
						var b := H.Blast.new()
						b.hero = hero
						b.radius = 1.7
						b.delay = 0.9 + float(i) * 0.12
						b.dmg = 18.0 * dmg_mult
						b.col = Color(0.7, 1.0, 0.75)
						b.eff = "slow"
						get_parent().add_child(b)
						b.global_position = H.clamp_arena(p, _bounds)
			if _st >= 0.3:
				_set_state("recover")
		"analysis":
			# 1.6 sn boyunca yolunu not eder; her not 1 sn sonra patlar
			_mark_t -= _delta
			if _mark_t <= 0.0 and _st < 1.6 and H.hero_ok(hero):
				_mark_t = 0.32
				var b := H.Blast.new()
				b.hero = hero
				b.radius = 1.5
				b.delay = 1.0
				b.dmg = 16.0 * dmg_mult
				b.col = TEAL
				get_parent().add_child(b)
				b.global_position = H.clamp_arena(hero.global_position, _bounds)
				Sfx.play("parry", -14.0, 0.05, 30, 2.2)
			if _st >= 1.7:
				_set_state("recover")
		"grid":
			if not _done:
				_done = true
				_purity_grid()
			if _st >= 0.3:
				_set_state("recover")
		"moon":
			if not _done:
				_done = true
				_harvest_moon()
			if _st >= 0.5:
				_set_state("recover")
	return Vector3.ZERO


func _reap_hit() -> void:
	var reach := float(REAP["reach"])
	var arc := deg_to_rad(float(REAP["arc"]))
	var fx := SlashFx.make(-arc * 0.5, arc * 0.5, 0.8, reach, PARRY_COL, 0.22)
	get_parent().add_child(fx)
	fx.global_transform = Transform3D(Basis.looking_at(_aim_dir, Vector3.UP), global_position + Vector3(0, 1.4, 0))
	Sfx.play("slash", -5.0, 0.1, 0, 0.7)
	if not H.hero_ok(hero):
		return
	var to: Vector3 = hero.global_position - global_position
	to.y = 0.0
	var dist := to.length()
	if dist > reach + 0.4:
		return
	if dist > 0.3 and _aim_dir.angle_to(to / dist) > arc * 0.5:
		return
	var res: String = hero.take_damage(float(REAP["dmg"]) * dmg_mult, to.normalized() if dist > 0.05 else _aim_dir, true)
	if res == "parried":
		_reaps_left = 0
		stun(2.2, true)
		_knock = -_aim_dir * 3.0


## Saflık Izgarası: 3 m'lik dama tahtası; önce açık kareler, 1.3 sn sonra koyu kareler patlar
func _purity_grid() -> void:
	var step := 3.0
	var n := int(ceil(_bounds / step)) + 1
	for wave in 2:
		for ix in range(-n, n + 1):
			for iz in range(-n, n + 1):
				if (ix + iz + wave) % 2 != 0:
					continue
				var p := Vector3(float(ix) * step, 0, float(iz) * step)
				if Vector2(p.x, p.z).length() > _bounds + 0.5:
					continue
				var b := H.Blast.new()
				b.hero = hero
				b.radius = 1.55
				b.delay = 1.3 + float(wave) * 1.3
				b.dmg = 20.0 * dmg_mult
				b.col = TEAL if wave == 0 else Color(0.7, 0.55, 1.0)
				get_parent().add_child(b)
				b.global_position = p


## Hasat Ayı: arenayı bir uçtan öbürüne biçen orak dalgası (2.6 m'lik şeritler sırayla)
func _harvest_moon() -> void:
	var a := randf() * TAU
	var sweep := Vector3(cos(a), 0, sin(a))       # dalganın ilerleme yönü
	var along := Vector3(-sweep.z, 0, sweep.x)     # şeritlerin uzandığı yön
	var w := 2.6
	var count := int(ceil(_bounds * 2.0 / w)) + 1
	for i in count:
		var off := -_bounds + float(i) * w
		var ln := H.Line.new()
		ln.hero = hero
		ln.dir = along
		ln.length = _bounds * 2.0 + 2.0
		ln.width = w
		ln.delay = 0.9 + float(i) * 0.28
		ln.dmg = 24.0 * dmg_mult
		ln.col = Color(0.85, 0.95, 1.0)
		get_parent().add_child(ln)
		ln.global_position = sweep * off - along * (_bounds + 1.0)
	Fx.flash_light(Vector3(0, 6, 0), Color(0.85, 0.95, 1.0), 6.0, 30.0, 0.5)


# ---------------------------------------------------------------- hasar ve evreler

func stun(sec: float, parried := false) -> void:
	_reaps_left = 0
	super.stun(sec, parried)


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
	_reaps_left = 0
	tele.visible = false
	_set_state("roar")
	Fx.shake(0.7)
	Fx.flash_light(global_position + Vector3(0, 3, 0), TEAL, 10.0, 16.0, 0.8)
	Sfx.play("bossroar", -2.0, 0.0, 0, 1.1)
	var ring := SlashFx.make(0.0, TAU, 0.5, 7.0, TEAL, 0.5)
	get_parent().add_child(ring)
	ring.global_transform = Transform3D(Basis.IDENTITY, global_position + Vector3(0, 0.3, 0))
	if H.hero_ok(hero):
		var d: Vector3 = hero.global_position - global_position
		d.y = 0.0
		if d.length() < 4.5:
			hero.velocity = d.normalized() * 15.0
	mane.amount = 24 if p == 1 else (48 if p == 2 else 80)
	m_eye.emission_energy_multiplier = 8.0
	if p == 2:
		_cd["grid"] = 0.5
		hint.emit("THE PURITY GRID", tr("Read the pattern: one colour, then the other"))
		summon.emit(["shade", "caster"])
	elif p == 3:
		_cd["moon"] = 0.5
		hint.emit("THE HARVEST MOON", tr("Dash through the wave behind the blade"))
		summon.emit(["brute", "leaper"])
	phase_changed.emit(p)


# ---------------------------------------------------------------- animasyon

func _animate(delta: float) -> void:
	body_root.rotation.y = lerp_angle(body_root.rotation.y, atan2(-_face.x, -_face.z), minf(8.0 * delta, 1.0))
	var lean := 0.0
	var arm_up := 0.2
	var swing := 0.0
	var glow := 5.0
	var hover := sin(_t * 1.6) * 0.12 + 0.2
	match state:
		"windup":
			var k := clampf(_st / _windup_len(), 0.0, 1.0)
			match atk:
				"reap":
					swing = -1.2 * k        # orağı geriye çeker
					lean = -0.1 * k
				"grid", "moon", "analysis":
					arm_up = 2.6 * k
					hover += 0.6 * k
				_:
					arm_up = 1.6 * k
			glow = 5.0 + 12.0 * k
		"act":
			if atk == "reap":
				swing = 1.3
				lean = 0.15
			else:
				arm_up = 2.4
				hover += 0.6
			glow = 15.0
		"roar":
			arm_up = 2.8
			hover += 0.8
			glow = 18.0
		"stun":
			lean = 0.25
			arm_up = 0.0
			hover = 0.0
			glow = 1.5
	if state != "intro":
		vis.position.y = lerpf(vis.position.y, hover, minf(6.0 * delta, 1.0))
	vis.rotation.x = lerpf(vis.rotation.x, lean, minf(10.0 * delta, 1.0))
	arm_l.rotation.x = lerpf(arm_l.rotation.x, arm_up, minf(12.0 * delta, 1.0))
	arm_r.rotation.x = lerpf(arm_r.rotation.x, arm_up * 0.5, minf(12.0 * delta, 1.0))
	arm_r.rotation.y = lerpf(arm_r.rotation.y, swing, minf(14.0 * delta, 1.0))
	for i in _wings.size():
		var wg: Node3D = _wings[i]
		var s := -1.0 if i == 0 else 1.0
		wg.rotation.y = s * (0.25 + sin(_t * 3.0) * 0.12 + (0.3 if state == "roar" else 0.0))
	m_eye.emission_energy_multiplier = glow
	m_body.emission = Color(0.5, 0.45, 0.9).lerp(Color(1.0, 1.0, 1.0), _flash)
	m_body.emission_energy_multiplier = 0.15 + _flash * 3.0 + (0.4 if _burn_t > 0.0 else 0.0)
