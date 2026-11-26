extends "res://scripts/aries_boss.gd"
## YENGEÇ: Ay Işıklı Kıyı'nın bekçisi, Gelgitin Anası. Dev, yan yan koşan bir yengeç;
## sırtında Ay'ın incisi taşır. Kabuğu önden sert, arkadan yumuşaktır (önden %60, arkadan %140 hasar).
##  1. evre (100-65%):
##    - ÇİFT KISKAÇ: altın uyarı, art arda iki kıskaç; parry'lenir
##    - YAN KOŞU: kızıl şerit; yan yan arenayı boydan boya geçer (evre arttıkça art arda)
##    - KABUĞA ÇEKİLME: 2 sn neredeyse hasar almaz, sonra dışa doğru bir su halkası salar (atılarak geç)
##  2. evre (65-30%): + GELGİT: Ay yükselir, kıyı sular altında kalır; dış halka yavaşlatır ve yakar,
##                      yalnızca Yengeç'in yanındaki iç daire güvenli
##                    + KÖPÜK YAĞMURU: seni kovalayan, değince yavaşlatan kabarcıklar
##  3. evre (<30%):   + GİRDAP: seni içine çeken bir girdap açar, kenarlardan dalgalar gelir

signal hint(a: String, b: String)

const EnemyScript = preload("res://scripts/enemy.gd")
const SNAP := {"windup": 0.62, "act": 0.16, "recover": 0.55, "dmg": 22.0, "reach": 3.8, "arc": 130.0}
const WATER_COL := Color(0.35, 0.85, 1.0)

var _snaps_left := 0
var _pearl: MeshInstance3D
var m_shell: StandardMaterial3D


func _init() -> void:
	kind = "cancer"
	title = "CANCER  ·  MOTHER OF TIDES"
	max_hp = 2400.0
	hp = 2400.0
	radius = 1.7
	_cd = {"snap": 0.5, "scuttle": 2.0, "shell": 5.0, "tide": 1.0, "bubbles": 2.0, "maelstrom": 1.0}
	_global_cd = 1.2


# ---------------------------------------------------------------- görünüş: dev ay yengeci

func _build() -> void:
	m_body = _m(Color(0.75, 0.22, 0.18), 0.5)
	m_body.emission_enabled = true
	m_body.emission = Color(0.5, 0.08, 0.06)
	m_body.emission_energy_multiplier = 0.3
	m_shell = _m(Color(0.95, 0.45, 0.32), 0.35)
	m_shell.emission_enabled = true
	m_shell.emission = Color(1.0, 0.35, 0.25)
	m_shell.emission_energy_multiplier = 0.2
	m_horn = _m(Color(0.98, 0.9, 0.85), 0.3)
	m_eye = StandardMaterial3D.new()
	m_eye.albedo_color = Color.BLACK
	m_eye.emission_enabled = true
	m_eye.emission = Color(0.4, 0.95, 1.0)
	m_eye.emission_energy_multiplier = 5.0
	var pearl := _m(Color(0.92, 0.95, 1.0), 0.1, 0.3)
	pearl.emission_enabled = true
	pearl.emission = Color(0.75, 0.88, 1.0)
	pearl.emission_energy_multiplier = 1.6

	body_root = Node3D.new()
	add_child(body_root)
	vis = Node3D.new()
	body_root.add_child(vis)
	# geniş, yassı kabuk
	_part(vis, _sph(1.0), Vector3(0, 1.5, 0.2), m_shell, Vector3(2.3, 0.8, 1.8))
	_part(vis, _sph(0.9), Vector3(0, 1.25, 0.1), m_body, Vector3(2.1, 0.6, 1.6))
	# kabuk sırtındaki sivri kabartılar
	for i in 7:
		var a := -1.2 + float(i) * 0.4
		var sp := _part(vis, _cone(0.16, 0.0, 0.5), Vector3(sin(a) * 1.8, 1.75, cos(a) * 0.9 + 0.2), m_shell)
		sp.rotation = Vector3(cos(a) * 0.6, 0, -sin(a) * 0.6)
	# sırtta Ay incisi
	_pearl = _part(vis, _sph(0.55), Vector3(0, 2.3, 0.5), pearl)
	# bacaklar: 4 çift, eklemli
	for s in [-1.0, 1.0]:
		for k in 4:
			var root := Node3D.new()
			root.position = Vector3(s * 1.7, 1.2, -0.6 + float(k) * 0.55)
			vis.add_child(root)
			var up := _part(root, _cone(0.14, 0.1, 1.2), Vector3(s * 0.45, 0.25, 0), m_body)
			up.rotation.z = s * 1.0
			var dn := _part(root, _cone(0.1, 0.03, 1.4), Vector3(s * 1.0, -0.55, 0), m_shell)
			dn.rotation.z = -s * 0.35
	# göz sapları (kafa)
	head = Node3D.new()
	head.position = Vector3(0, 1.7, -1.4)
	vis.add_child(head)
	for s in [-1.0, 1.0]:
		var st := _part(head, _cone(0.07, 0.06, 0.7), Vector3(s * 0.35, 0.3, 0), m_body)
		st.rotation.z = -s * 0.2
		_part(head, _sph(0.17), Vector3(s * 0.42, 0.68, 0), m_eye)
	# dev kıskaçlar
	arm_l = _claw(-1.0)
	arm_r = _claw(1.0)

	mane = CPUParticles3D.new()
	mane.amount = 24
	mane.lifetime = 1.6
	var bm := SphereMesh.new()
	bm.radius = 0.06
	bm.height = 0.12
	mane.mesh = bm
	var bmat := StandardMaterial3D.new()
	bmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bmat.albedo_color = Color(0.7, 0.95, 1.0, 0.6)
	mane.material_override = bmat
	mane.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	mane.emission_sphere_radius = 1.4
	mane.direction = Vector3.UP
	mane.spread = 20.0
	mane.gravity = Vector3(0, 1.2, 0)
	mane.initial_velocity_min = 0.3
	mane.initial_velocity_max = 0.9
	mane.position = Vector3(0, 1.6, 0)
	vis.add_child(mane)
	var l := OmniLight3D.new()
	l.light_color = Color(0.6, 0.85, 1.0)
	l.light_energy = 1.6
	l.omni_range = 7.0
	l.position = Vector3(0, 3.2, 0.5)
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


func _claw(side: float) -> Node3D:
	var sh := Node3D.new()
	sh.position = Vector3(side * 1.5, 1.6, -1.0)
	vis.add_child(sh)
	var a1 := _part(sh, _cone(0.22, 0.18, 1.2), Vector3(side * 0.2, 0, -0.5), m_body)
	a1.rotation.x = PI * 0.5
	_part(sh, _sph(0.6), Vector3(side * 0.25, 0.1, -1.4), m_shell, Vector3(0.9, 0.75, 1.4))
	var up := _part(sh, _cone(0.3, 0.05, 1.1), Vector3(side * 0.25, 0.3, -2.3), m_shell)
	up.rotation.x = PI * 0.5 + 0.2
	var lo := _part(sh, _cone(0.22, 0.04, 0.9), Vector3(side * 0.25, -0.2, -2.2), m_horn)
	lo.rotation.x = PI * 0.5 - 0.25
	return sh


func _place_tele() -> void:
	var b := Basis.looking_at(_aim_dir, Vector3.UP) if _aim_dir.length() > 0.1 else Basis.IDENTITY
	if atk == "shell":
		b = Basis.IDENTITY
	tele.global_transform = Transform3D(b, Vector3(global_position.x, 0.07, global_position.z))


# ---------------------------------------------------------------- yapay zekâ

func _speed_mult() -> float:
	match phase:
		1:
			return 1.0
		2:
			return 1.12
	return 1.28


func _windup_len() -> float:
	var k := windup_mult / _speed_mult()
	match atk:
		"snap":
			return (float(SNAP["windup"]) if _snaps_left > 0 else 0.42) * k
		"scuttle":
			return (0.8 if _charges_left <= 0 else 0.45) * k
		"shell":
			return 0.4 * k
		"tide":
			return 1.0 * k
		"bubbles":
			return 0.75 * k
		"maelstrom":
			return 0.9 * k
	return 0.6


func _recover_len() -> float:
	match atk:
		"snap":
			return float(SNAP["recover"]) / _speed_mult()
		"scuttle":
			return 1.0     # koşu sonunda bocalar: vurma fırsatı
		"shell":
			return 0.8
	return 0.6


func _pick(dist: float, dir_to: Vector3) -> void:
	var opts: Array = []
	if float(_cd["snap"]) <= 0.0 and dist < 3.9:
		opts.append_array(["snap", "snap", "snap"])
	if float(_cd["scuttle"]) <= 0.0 and dist > 3.0:
		opts.append_array(["scuttle", "scuttle"])
	if float(_cd["shell"]) <= 0.0 and dist < 6.0:
		opts.append("shell")
	if phase >= 2 and float(_cd["tide"]) <= 0.0:
		opts.append("tide")
	if phase >= 2 and float(_cd["bubbles"]) <= 0.0 and dist > 3.0:
		opts.append("bubbles")
	if phase >= 3 and float(_cd["maelstrom"]) <= 0.0:
		opts.append("maelstrom")
	if opts.is_empty():
		return
	atk = String(opts[randi() % opts.size()])
	_aim_dir = dir_to
	if atk == "snap":
		_snaps_left = 1                 # iki kıskaç: ilki + 1 tekrar
	if atk == "scuttle":
		_charges_left = phase - 1
	_set_state("windup")


func _set_state(s: String) -> void:
	state = s
	_st = 0.0
	match s:
		"windup":
			tele.visible = false
			match atk:
				"snap":
					_show_tele(_fan_mesh(deg_to_rad(float(SNAP["arc"])), float(SNAP["reach"])), PARRY_COL)
				"scuttle":
					_charge_len = minf(_dist_to_edge(_aim_dir), 20.0)
					_show_tele(_line_mesh(_charge_len, 3.0), DANGER_COL)
				"tide":
					_show_tele(_fan_mesh(TAU, 5.2), WATER_COL)
			Sfx.play("bossroar", -6.0 if atk != "snap" else -11.0, 0.08, 0, 0.8)
		"act":
			_done = false
			_charge_traveled = 0.0
			_charge_hit = false
			if atk != "scuttle":
				tele.visible = false
			Sfx.play("dash", -6.0, 0.1, 0, 0.55)
		"recover":
			tele.visible = false
			_global_cd = randf_range(0.25, 0.55) / _speed_mult()
			match atk:
				"snap":
					_cd["snap"] = 1.3
				"scuttle":
					_cd["scuttle"] = 4.5
				"shell":
					_cd["shell"] = 9.0
				"tide":
					_cd["tide"] = 13.0
				"bubbles":
					_cd["bubbles"] = 7.0
				"maelstrom":
					_cd["maelstrom"] = 11.0
		_:
			tele.visible = false


func _act(delta: float, sm: float) -> Vector3:
	match atk:
		"snap":
			if not _done and _st >= 0.06:
				_done = true
				_snap_hit()
			if _st >= float(SNAP["act"]):
				if _snaps_left > 0 and state == "act":
					_snaps_left -= 1
					if hero != null and is_instance_valid(hero):
						var nd: Vector3 = hero.global_position - global_position
						nd.y = 0.0
						if nd.length() > 0.3:
							_aim_dir = nd.normalized()
					_set_state("windup")
				elif state == "act":
					_set_state("recover")
			return _aim_dir * 5.0
		"scuttle":
			# yan yan koşar: gövde yana bakar, kıskaçlar açık
			var spd := 20.0 * sm
			_charge_traveled += spd * delta
			_move = _aim_dir * spd
			_face = _aim_dir.rotated(Vector3.UP, PI * 0.5)
			if not _charge_hit and hero != null and is_instance_valid(hero) and not hero.dead:
				var d: Vector3 = hero.global_position - global_position
				d.y = 0.0
				if d.length() < 1.9:
					var res: String = hero.take_damage(28.0 * dmg_mult, _aim_dir, false)
					if res == "hit":
						_charge_hit = true
			if _charge_traveled >= _charge_len - 0.3 or _st > 1.6:
				_move = Vector3.ZERO
				Fx.shake(0.35)
				Sfx.play("crush", -6.0, 0.1, 0, 0.8)
				var ring := SlashFx.make(0.0, TAU, 0.3, 2.4, DANGER_COL, 0.3)
				get_parent().add_child(ring)
				ring.global_transform = Transform3D(Basis.IDENTITY, global_position + Vector3(0, 0.3, 0))
				if _charges_left > 0:
					_charges_left -= 1
					if hero != null and is_instance_valid(hero):
						var nd2: Vector3 = hero.global_position - global_position
						nd2.y = 0.0
						if nd2.length() > 0.5:
							_aim_dir = nd2.normalized()
					_set_state("windup")
				else:
					_set_state("recover")
			return _move
		"shell":
			# kabuğa çekilir; içi parlayarak dolar, sonra su halkası salar
			var k := clampf(_st / 2.0, 0.0, 1.0)
			_pearl.scale = Vector3.ONE * (1.0 + 0.5 * k)
			if _st >= 2.0 and not _done:
				_done = true
				_pearl.scale = Vector3.ONE
				var fr := FireRing.new()
				fr.hero = hero
				fr.dmg = 22.0 * dmg_mult
				fr.dur = 1.6
				fr.position = Vector3(global_position.x, 0.0, global_position.z)
				get_parent().add_child(fr)
				fr._mat.albedo_color = Color(WATER_COL.r, WATER_COL.g, WATER_COL.b, 1.0)
				if phase >= 3:
					var fr2 := FireRing.new()
					fr2.hero = hero
					fr2.dmg = 18.0 * dmg_mult
					fr2.dur = 2.6
					fr2.position = fr.position
					get_parent().add_child(fr2)
					fr2._mat.albedo_color = Color(WATER_COL.r, WATER_COL.g, WATER_COL.b, 1.0)
				Fx.shake(0.35)
				Sfx.play("boom", -8.0, 0.0, 0, 1.3)
				_set_state("recover")
		"tide":
			if not _done:
				_done = true
				var fl := Flood.new()
				fl.hero = hero
				fl.center = Vector3(global_position.x, 0.0, global_position.z)
				fl.safe_r = 5.2
				fl.bounds = _bounds + 2.0
				fl.dps = 9.0 * dmg_mult
				get_parent().add_child(fl)
				Fx.shake(0.4)
				Sfx.play("boom", -10.0, 0.0, 0, 0.5)
			if _st >= 0.3:
				_set_state("recover")
		"bubbles":
			if not _done:
				_done = true
				var n := 6 if phase < 3 else 9
				for i in n:
					var bb := EnemyScript.Bubble.new()
					bb.hero = hero
					bb.dmg = 12.0 * dmg_mult
					bb.life = 6.0
					bb.speed = 3.0
					bb.vel = _aim_dir.rotated(Vector3.UP, TAU * float(i) / float(n)) * 5.0
					get_parent().add_child(bb)
					bb.global_position = global_position + Vector3(0, 2.4, 0)
				Sfx.play("parry", -8.0, 0.05, 0, 2.0)
			if _st >= 0.3:
				_set_state("recover")
		"maelstrom":
			if not _done:
				_done = true
				var mp := Vector3.ZERO
				if hero != null and is_instance_valid(hero):
					mp = hero.global_position + Vector3(randf_range(-2.0, 2.0), 0, randf_range(-2.0, 2.0))
				var fl2 := Vector2(mp.x, mp.z)
				if fl2.length() > _bounds - 2.0:
					fl2 = fl2.normalized() * (_bounds - 2.0)
				var wp := Whirlpool.new()
				wp.hero = hero
				wp.dmg = 10.0 * dmg_mult
				get_parent().add_child(wp)
				wp.global_position = Vector3(fl2.x, 0.0, fl2.y)
				# kenarlardan merkeze üç dalga
				var base_a := randf() * TAU
				for i in 3:
					var a := base_a + TAU * float(i) / 3.0
					var tw := EnemyScript.TideWave.new()
					tw.hero = hero
					tw.dir = -Vector3(cos(a), 0, sin(a))
					tw.dmg = 16.0 * dmg_mult
					tw.width = 5.0
					tw.speed = 6.5
					tw.travel = _bounds * 2.0
					get_parent().add_child(tw)
					tw.global_position = Vector3(cos(a), 0, sin(a)) * (_bounds + 0.5)
			if _st >= 0.4:
				_set_state("recover")
	return Vector3.ZERO


func _snap_hit() -> void:
	var reach := float(SNAP["reach"])
	var arc := deg_to_rad(float(SNAP["arc"]))
	var fx := SlashFx.make(-arc * 0.5, arc * 0.5, 0.7, reach, PARRY_COL, 0.22)
	get_parent().add_child(fx)
	fx.global_transform = Transform3D(Basis.looking_at(_aim_dir, Vector3.UP), global_position + Vector3(0, 1.5, 0))
	Sfx.play("crush", -6.0, 0.1, 0, 1.0)
	if hero == null or not is_instance_valid(hero) or hero.dead:
		return
	var to: Vector3 = hero.global_position - global_position
	to.y = 0.0
	var dist := to.length()
	if dist > reach + 0.4:
		return
	if dist > 0.3 and _aim_dir.angle_to(to / dist) > arc * 0.5:
		return
	var res: String = hero.take_damage(float(SNAP["dmg"]) * dmg_mult, to.normalized() if dist > 0.05 else _aim_dir, true)
	if res == "parried":
		_snaps_left = 0
		stun(2.2, true)
		_knock = -_aim_dir * 3.0
	elif res == "hit":
		hero.velocity = (to.normalized() if dist > 0.05 else _aim_dir) * 10.0


# ---------------------------------------------------------------- hasar ve evreler

func stun(sec: float, parried := false) -> void:
	_snaps_left = 0
	super.stun(sec, parried)


func take_hit(dmg: float, dir: Vector3, kb: float, heavy: bool, crit := false) -> void:
	if puppet:
		Net.send_hit(self, dmg, dir, kb, heavy, crit)
		_flash = 1.0
		return
	# kabuğa çekilmişken neredeyse hasar almaz; aksi halde önden sert, arkadan yumuşak
	var m := 1.0
	if state == "act" and atk == "shell":
		m = 0.1
		Sfx.play("parry", -12.0, 0.05, 40, 1.6)
	elif state != "stun":
		var front := _face.dot(-dir)
		if front > 0.35:
			m = 0.6
		elif front < -0.35:
			m = 1.4
			crit = true
	super.take_hit(dmg * m, dir, kb, heavy, crit)


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
	_charges_left = 0
	_snaps_left = 0
	tele.visible = false
	_pearl.scale = Vector3.ONE
	_set_state("roar")
	Fx.shake(0.8)
	Fx.flash_light(global_position + Vector3(0, 3, 0), WATER_COL, 10.0, 16.0, 0.8)
	Sfx.play("bossroar", 0.0, 0.0, 0, 0.5)
	Sfx.play("bruteroar", -4.0, 0.0, 0, 0.55)
	var ring := SlashFx.make(0.0, TAU, 0.5, 7.0, WATER_COL, 0.5)
	get_parent().add_child(ring)
	ring.global_transform = Transform3D(Basis.IDENTITY, global_position + Vector3(0, 0.3, 0))
	if hero != null and is_instance_valid(hero) and not hero.dead:
		var d: Vector3 = hero.global_position - global_position
		d.y = 0.0
		if d.length() < 4.5:
			hero.velocity = d.normalized() * 15.0
	mane.amount = 24 if p == 1 else (48 if p == 2 else 80)
	m_eye.emission_energy_multiplier = 8.0
	if p == 2:
		_cd["tide"] = 0.5
		hint.emit("THE TIDE RISES", tr("Stay close to the Crab when the shore floods"))
		summon.emit(["shade", "caster"])
	elif p == 3:
		hint.emit("THE MAELSTROM", tr("Strike its soft back"))
		summon.emit(["leaper", "shade"])
	phase_changed.emit(p)


# ---------------------------------------------------------------- animasyon

func _animate(delta: float) -> void:
	body_root.rotation.y = lerp_angle(body_root.rotation.y, atan2(-_face.x, -_face.z), minf(8.0 * delta, 1.0))
	var open := 0.0       # kıskaçları kaldırma
	var spread := 0.0     # kıskaçları yana açma
	var low := 0.0        # çömelme
	var glow := 5.0
	match state:
		"windup":
			var k := clampf(_st / _windup_len(), 0.0, 1.0)
			match atk:
				"snap":
					open = 0.9 * k
					spread = 0.3 * k
				"scuttle":
					low = 0.25 * k
					spread = 0.6 * k
				"tide", "maelstrom":
					open = 1.4 * k
					spread = -0.2
				"bubbles":
					low = -0.2 * k
				"shell":
					low = 0.5 * k
			glow = 5.0 + 10.0 * k
		"act":
			match atk:
				"snap":
					open = -0.4
				"scuttle":
					spread = 0.6
					low = 0.25
				"shell":
					low = 0.6
					spread = -0.5
					glow = 3.0 + 12.0 * clampf(_st / 2.0, 0.0, 1.0)
				_:
					open = 1.0
			if atk != "shell":
				glow = 14.0
		"roar":
			open = 1.5
			spread = 0.4
			glow = 18.0
		"stun":
			low = 0.35
			glow = 1.5
	vis.position.y = lerpf(vis.position.y, -low, minf(10.0 * delta, 1.0)) if state != "intro" else vis.position.y
	arm_l.rotation.x = lerpf(arm_l.rotation.x, open, minf(12.0 * delta, 1.0))
	arm_r.rotation.x = lerpf(arm_r.rotation.x, open, minf(12.0 * delta, 1.0))
	arm_l.rotation.y = lerpf(arm_l.rotation.y, spread, minf(12.0 * delta, 1.0))
	arm_r.rotation.y = lerpf(arm_r.rotation.y, -spread, minf(12.0 * delta, 1.0))
	head.position.y = 1.7 + sin(_t * 3.0) * 0.05
	if state == "act" and atk == "scuttle":
		vis.rotation.z = sin(_t * 30.0) * 0.06
	else:
		vis.rotation.z = lerpf(vis.rotation.z, 0.0, minf(10.0 * delta, 1.0))
	m_eye.emission_energy_multiplier = glow
	m_body.emission = Color(0.5, 0.08, 0.06).lerp(Color(1.0, 0.95, 0.9), _flash)
	m_body.emission_energy_multiplier = 0.3 + _flash * 3.0 + (0.4 if _burn_t > 0.0 else 0.0)
	m_shell.emission_energy_multiplier = 0.2 + _flash * 2.0


# ---------------------------------------------------------------- GELGİT: kıyıyı su basar (evre 2+)

class Flood extends Node3D:
	var hero = null
	var center := Vector3.ZERO
	var safe_r := 5.2
	var bounds := 12.0
	var dps := 9.0
	var rise := 1.4      # suyun yükselme süresi (uyarı)
	var hold := 4.5
	var _t := 0.0
	var _tick := 0.0
	var _water: MeshInstance3D
	var _mat: StandardMaterial3D

	func _ready() -> void:
		top_level = true
		global_position = Vector3(center.x, 0.0, center.z)
		_water = MeshInstance3D.new()
		var t := TorusMesh.new()
		t.inner_radius = safe_r
		t.outer_radius = bounds + 6.0
		t.rings = 64
		t.ring_segments = 6
		_water.mesh = t
		_water.scale = Vector3(1.0, 0.02, 1.0)
		_mat = StandardMaterial3D.new()
		_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_mat.albedo_color = Color(0.25, 0.7, 1.0, 0.0)
		_water.material_override = _mat
		_water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_water.position.y = 0.08
		add_child(_water)
		Sfx.play("dash", -4.0, 0.0, 0, 0.35)

	func _physics_process(delta: float) -> void:
		_t += delta
		var a := 0.0
		if _t < rise:
			# uyarı: titreşen, yavaş dolan su
			a = 0.12 + 0.18 * (_t / rise) + 0.08 * sin(_t * 18.0)
		elif _t < rise + hold:
			a = 0.55
			_hurt(delta)
		else:
			a = 0.55 * (1.0 - clampf((_t - rise - hold) / 0.8, 0.0, 1.0))
		_mat.albedo_color.a = a
		if _t >= rise + hold + 0.8:
			queue_free()

	func _hurt(delta: float) -> void:
		if hero == null or not is_instance_valid(hero) or hero.dead:
			return
		var d: Vector3 = hero.global_position - global_position
		d.y = 0.0
		if d.length() <= safe_r:
			return
		if hero.has_method("apply_slow"):
			hero.apply_slow(0.55, 0.2)
		_tick -= delta
		if _tick <= 0.0:
			_tick = 0.5
			hero.take_damage(dps * 0.5, -d.normalized(), false)


# ---------------------------------------------------------------- GİRDAP (evre 3)

class Whirlpool extends Node3D:
	var hero = null
	var dmg := 10.0
	var life := 5.0
	var pull := 2.6
	var core := 1.3
	var _t := 0.0
	var _tick := 0.0
	var _disc: MeshInstance3D
	var _mat: StandardMaterial3D

	func _ready() -> void:
		top_level = true
		_disc = MeshInstance3D.new()
		var t := TorusMesh.new()
		t.inner_radius = 0.6
		t.outer_radius = 4.5
		t.rings = 48
		t.ring_segments = 6
		_disc.mesh = t
		_disc.scale = Vector3(1.0, 0.03, 1.0)
		_mat = StandardMaterial3D.new()
		_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		_mat.albedo_color = Color(0.3, 0.75, 1.0, 0.0)
		_disc.material_override = _mat
		_disc.position.y = 0.1
		add_child(_disc)
		var eye := MeshInstance3D.new()
		var s := SphereMesh.new()
		s.radius = core
		s.height = core * 0.4
		eye.mesh = s
		var em := StandardMaterial3D.new()
		em.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		em.albedo_color = Color(0.02, 0.1, 0.2)
		eye.material_override = em
		eye.position.y = 0.05
		add_child(eye)

	func _physics_process(delta: float) -> void:
		_t += delta
		rotation.y += delta * 4.0
		var a := clampf(_t / 0.6, 0.0, 1.0) * (1.0 - clampf((_t - life + 0.6) / 0.6, 0.0, 1.0))
		_mat.albedo_color.a = 0.6 * a
		if _t > 0.6 and _t < life and hero != null and is_instance_valid(hero) and not hero.dead:
			var d: Vector3 = global_position - hero.global_position
			d.y = 0.0
			if d.length() < 7.0 and hero.has_method("apply_pull"):
				hero.apply_pull(global_position, pull, 0.05)
			_tick -= delta
			if d.length() < core and _tick <= 0.0:
				_tick = 0.5
				hero.take_damage(dmg, -d.normalized() if d.length() > 0.05 else Vector3.FORWARD, false)
		if _t >= life:
			queue_free()
