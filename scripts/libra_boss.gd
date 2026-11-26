extends "res://scripts/aries_boss.gd"
## TERAZİ: Şafak Terazisi'nin yargıcı, Dengenin Hakemi. Elinde kılıç, omzunda iki kefeli dev terazi.
## DENGE: Terazi'ye hep aynı taraftan (sol / sağ) vurursan kefe o yana ağar ve terazi o yarıyı ezer.
##        İki yanından sırayla vur; HUD altında denge göstergesi var.
##  1. evre (100-65%):
##    - ADALET KILICI: altın uyarı, iki savuruş; parry'lenir
##    - KEFELER: iki kefe yere iner; biri senin üstüne, biri aynadaki noktaya
##  2. evre (65-30%): + HÜKÜM: arenanın bir yarısı mahkûm edilir, sonra öbür yarısı
##  3. evre (<30%):   + DENGE: iki karşıt ışın kolu döner; kefeler daha sık iner

signal hint(a: String, b: String)

const H = preload("res://scripts/hazards.gd")
const BLADE := {"windup": 0.6, "act": 0.16, "recover": 0.6, "dmg": 24.0, "reach": 4.0, "arc": 140.0}
const JADE := Color(0.35, 1.0, 0.8)
const ROSE := Color(1.0, 0.6, 0.75)

var balance := 0.0          # sağdan vuruş +, soldan vuruş -
var _blades_left := 0
var _tip_side := 0.0
var _warned := false
var m_jade: StandardMaterial3D
var _beam: Node3D
var _pans: Array = []


func _init() -> void:
	kind = "libra"
	title = "LIBRA  ·  ARBITER OF BALANCE"
	max_hp = 3100.0
	hp = 3100.0
	radius = 1.1
	_cd = {"blade": 0.4, "pans": 1.5, "judgement": 1.0, "equilibrium": 1.0, "tip": 0.0}
	_global_cd = 1.1


func _build() -> void:
	m_body = _m(Color(0.78, 0.6, 0.42), 0.35, 0.6)
	m_body.emission_enabled = true
	m_body.emission = Color(0.4, 0.25, 0.1)
	m_body.emission_energy_multiplier = 0.2
	m_jade = _m(Color(0.3, 0.75, 0.6), 0.3)
	m_jade.emission_enabled = true
	m_jade.emission = JADE
	m_jade.emission_energy_multiplier = 0.35
	m_horn = _m(Color(0.95, 0.92, 0.88), 0.3)
	m_eye = StandardMaterial3D.new()
	m_eye.albedo_color = Color.BLACK
	m_eye.emission_enabled = true
	m_eye.emission = Color(1.0, 0.9, 0.7)
	m_eye.emission_energy_multiplier = 5.0
	body_root = Node3D.new()
	add_child(body_root)
	vis = Node3D.new()
	body_root.add_child(vis)
	vis.scale = Vector3.ONE * 0.85
	_part(vis, _cone(1.1, 0.4, 2.8), Vector3(0, 1.4, 0), m_jade)
	_part(vis, _sph(0.6), Vector3(0, 3.1, 0), m_body, Vector3(1.1, 1.1, 0.8))
	head = Node3D.new()
	head.position = Vector3(0, 4.0, 0)
	vis.add_child(head)
	_part(head, _sph(0.36), Vector3.ZERO, m_horn)
	_part(head, BoxMesh.new(), Vector3(0, 0.0, -0.3), m_body, Vector3(0.5, 0.12, 0.05))
	for s in [-1.0, 1.0]:
		_part(head, _sph(0.06), Vector3(s * 0.12, 0.08, -0.32), m_eye)
	for i in 5:
		var a := -0.8 + float(i) * 0.4
		var sp := _part(head, _cone(0.06, 0.0, 0.4), Vector3(sin(a) * 0.3, 0.4, cos(a) * 0.08), m_body)
		sp.rotation.z = -a * 0.5
	# dev terazi: yatay kol ve iki kefe
	_beam = Node3D.new()
	_beam.position = Vector3(0, 5.0, 0.2)
	vis.add_child(_beam)
	_part(_beam, _cone(0.08, 0.08, 1.4), Vector3(0, -0.7, 0), m_body)
	var bar := _part(_beam, _cone(0.07, 0.07, 4.4), Vector3.ZERO, m_body)
	bar.rotation.z = PI * 0.5
	for s in [-1.0, 1.0]:
		var pan := Node3D.new()
		pan.position = Vector3(s * 2.2, 0, 0)
		_beam.add_child(pan)
		_part(pan, _cone(0.02, 0.02, 1.2), Vector3(0, -0.6, 0), m_body)
		_part(pan, _sph(0.55), Vector3(0, -1.25, 0), m_jade if s < 0 else _m(ROSE, 0.3), Vector3(1.0, 0.35, 1.0))
		_pans.append(pan)
	arm_l = _sleeve(-1.0)
	arm_r = _sleeve(1.0)
	_part(arm_r, _cone(0.05, 0.03, 2.4), Vector3(0, -2.0, -0.2), m_horn)
	mane = CPUParticles3D.new()
	mane.amount = 20
	mane.lifetime = 2.0
	var em := SphereMesh.new()
	em.radius = 0.05
	em.height = 0.1
	mane.mesh = em
	mane.material_override = Fx.emissive(JADE, 3.0)
	mane.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	mane.emission_sphere_radius = 1.2
	mane.gravity = Vector3(0, 0.5, 0)
	mane.position = Vector3(0, 3.0, 0)
	vis.add_child(mane)
	var l := OmniLight3D.new()
	l.light_color = Color(0.7, 1.0, 0.9)
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


func _sleeve(side: float) -> Node3D:
	var sh := Node3D.new()
	sh.position = Vector3(side * 0.75, 3.3, 0)
	vis.add_child(sh)
	_part(sh, _cone(0.28, 0.15, 1.3), Vector3(0, -0.65, 0), m_jade)
	_part(sh, _sph(0.14), Vector3(0, -1.35, 0), m_horn)
	return sh


func _place_tele() -> void:
	var b := Basis.looking_at(_aim_dir, Vector3.UP) if _aim_dir.length() > 0.1 else Basis.IDENTITY
	tele.global_transform = Transform3D(b, Vector3(global_position.x, 0.07, global_position.z))


func _speed_mult() -> float:
	return [1.0, 1.0, 1.12, 1.3][clampi(phase, 1, 3)]


func _windup_len() -> float:
	var k := windup_mult / _speed_mult()
	match atk:
		"blade":
			return (float(BLADE["windup"]) if _blades_left > 0 else 0.4) * k
		"pans":
			return 0.7 * k
		"tip":
			return 0.9 * k
	return 0.6 * k


func _recover_len() -> float:
	return float(BLADE["recover"]) / _speed_mult() if atk == "blade" else 0.6


func _pick(dist: float, dir_to: Vector3) -> void:
	# denge bozulduysa önce terazi ağar
	if absf(balance) > max_hp * 0.07:
		atk = "tip"
		_tip_side = signf(balance)
		balance = 0.0
		_set_state("windup")
		if not _warned:
			_warned = true
			hint.emit("THE SCALES TIP", tr("Strike Libra from both sides in turn"))
		return
	var opts: Array = []
	if float(_cd["blade"]) <= 0.0 and dist < 4.2:
		opts.append_array(["blade", "blade", "blade"])
	if float(_cd["pans"]) <= 0.0:
		opts.append_array(["pans", "pans"])
	if phase >= 2 and float(_cd["judgement"]) <= 0.0:
		opts.append("judgement")
	if phase >= 3 and float(_cd["equilibrium"]) <= 0.0:
		opts.append("equilibrium")
	if opts.is_empty():
		return
	atk = String(opts[randi() % opts.size()])
	_aim_dir = dir_to
	if atk == "blade":
		_blades_left = 1
	_set_state("windup")


func _set_state(s: String) -> void:
	state = s
	_st = 0.0
	match s:
		"windup":
			tele.visible = false
			if atk == "blade":
				_show_tele(_fan_mesh(deg_to_rad(float(BLADE["arc"])), float(BLADE["reach"])), PARRY_COL)
			Sfx.play("bossroar", -10.0, 0.08, 0, 1.2)
		"act":
			_done = false
			tele.visible = false
		"recover":
			tele.visible = false
			_global_cd = randf_range(0.25, 0.55) / _speed_mult()
			match atk:
				"blade":
					_cd["blade"] = 1.2
				"pans":
					_cd["pans"] = 4.5 if phase < 3 else 3.0
				"judgement":
					_cd["judgement"] = 12.0
				"equilibrium":
					_cd["equilibrium"] = 11.0
		_:
			tele.visible = false


func _act(_delta: float, _sm: float) -> Vector3:
	match atk:
		"blade":
			if not _done and _st >= 0.06:
				_done = true
				_blade_hit()
			if _st >= float(BLADE["act"]) and state == "act":
				if _blades_left > 0:
					_blades_left -= 1
					if H.hero_ok(hero):
						var nd: Vector3 = hero.global_position - global_position
						nd.y = 0.0
						if nd.length() > 0.3:
							_aim_dir = nd.normalized()
					_set_state("windup")
				else:
					_set_state("recover")
			return _aim_dir * 5.0
		"pans":
			if not _done:
				_done = true
				if H.hero_ok(hero):
					var p: Vector3 = hero.global_position
					var mirror := Vector3(-p.x, 0, -p.z)
					for i in 2:
						var b := H.Blast.new()
						b.hero = hero
						b.radius = 2.6
						b.delay = 0.9 + float(i) * 0.2
						b.dmg = 22.0 * dmg_mult
						b.col = JADE if i == 0 else ROSE
						get_parent().add_child(b)
						b.global_position = H.clamp_arena(p if i == 0 else mirror, _bounds)
			if _st >= 0.3:
				_set_state("recover")
		"tip":
			if not _done:
				_done = true
				_half_plane(Vector3(-_face.z, 0, _face.x) * _tip_side, 0.6, 30.0, ROSE)
				Fx.shake(0.5)
			if _st >= 0.4:
				_set_state("recover")
		"judgement":
			if not _done:
				_done = true
				var a := randf() * TAU
				var d := Vector3(cos(a), 0, sin(a))
				_half_plane(d, 1.2, 24.0, JADE)
				_half_plane(-d, 2.6, 24.0, ROSE)
			if _st >= 0.3:
				_set_state("recover")
		"equilibrium":
			if not _done:
				_done = true
				var sp := H.Spokes.new()
				sp.hero = hero
				sp.follow = self
				sp.arms = 2
				sp.length = 11.0
				sp.spin = 1.3 * (1.0 if randf() < 0.5 else -1.0)
				sp.life = 5.0
				sp.dmg = 18.0 * dmg_mult
				sp.col = JADE
				get_parent().add_child(sp)
			if _st >= 0.4:
				_set_state("recover")
	return Vector3.ZERO


## Arenanın bir yarısını (d yönündeki taraf) patlatır
func _half_plane(d: Vector3, delay: float, dmg: float, col: Color) -> void:
	var step := 3.6
	var n := int(ceil(_bounds / step)) + 1
	for ix in range(-n, n + 1):
		for iz in range(-n, n + 1):
			var p := Vector3(float(ix) * step, 0, float(iz) * step)
			if Vector2(p.x, p.z).length() > _bounds + 0.5 or p.dot(d) < 0.8:
				continue
			var b := H.Blast.new()
			b.hero = hero
			b.radius = 2.5
			b.delay = delay
			b.dmg = dmg * dmg_mult
			b.col = col
			get_parent().add_child(b)
			b.global_position = p


func _blade_hit() -> void:
	var reach := float(BLADE["reach"])
	var arc := deg_to_rad(float(BLADE["arc"]))
	var fx := SlashFx.make(-arc * 0.5, arc * 0.5, 0.8, reach, PARRY_COL, 0.22)
	get_parent().add_child(fx)
	fx.global_transform = Transform3D(Basis.looking_at(_aim_dir, Vector3.UP), global_position + Vector3(0, 1.4, 0))
	Sfx.play("slash", -5.0, 0.1, 0, 0.8)
	if not H.hero_ok(hero):
		return
	var to: Vector3 = hero.global_position - global_position
	to.y = 0.0
	var dist := to.length()
	if dist > reach + 0.4 or (dist > 0.3 and _aim_dir.angle_to(to / dist) > arc * 0.5):
		return
	var res: String = hero.take_damage(float(BLADE["dmg"]) * dmg_mult, to.normalized() if dist > 0.05 else _aim_dir, true)
	if res == "parried":
		_blades_left = 0
		stun(2.2, true)
		_knock = -_aim_dir * 3.0


func stun(sec: float, parried := false) -> void:
	_blades_left = 0
	super.stun(sec, parried)


## Hangi yandan vurulduğunu denge hesabına ekler
func take_hit(dmg: float, dir: Vector3, kb: float, heavy: bool, crit := false) -> void:
	if puppet:
		Net.send_hit(self, dmg, dir, kb, heavy, crit)
		_flash = 1.0
		return
	var right := Vector3(-_face.z, 0, _face.x)
	var side := right.dot(-dir)
	super.take_hit(dmg, dir, kb, heavy, crit)
	if absf(side) > 0.25:
		balance += last_dealt * signf(side)


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
	_blades_left = 0
	tele.visible = false
	_set_state("roar")
	Fx.shake(0.7)
	Fx.flash_light(global_position + Vector3(0, 3, 0), JADE, 10.0, 16.0, 0.8)
	Sfx.play("bossroar", -2.0, 0.0, 0, 1.0)
	mane.amount = 20 if p == 1 else (40 if p == 2 else 70)
	if p == 2:
		_cd["judgement"] = 0.5
		hint.emit("THE JUDGEMENT", tr("Half of the arena is condemned, then the other"))
		summon.emit(["shade", "shade", "caster"])
	elif p == 3:
		_cd["equilibrium"] = 0.5
		hint.emit("EQUILIBRIUM", tr("Two arms of light turn as one"))
		summon.emit(["leaper", "brute"])
	phase_changed.emit(p)


func _animate(delta: float) -> void:
	body_root.rotation.y = lerp_angle(body_root.rotation.y, atan2(-_face.x, -_face.z), minf(8.0 * delta, 1.0))
	var arm_up := 0.2
	var swing := 0.0
	var glow := 5.0
	match state:
		"windup":
			var k := clampf(_st / _windup_len(), 0.0, 1.0)
			if atk == "blade":
				swing = -1.2 * k
			else:
				arm_up = 2.4 * k
			glow = 5.0 + 12.0 * k
		"act":
			swing = 1.3 if atk == "blade" else 0.0
			arm_up = 0.2 if atk == "blade" else 2.4
			glow = 15.0
		"roar":
			arm_up = 2.8
			glow = 18.0
		"stun":
			arm_up = 0.0
			glow = 1.5
	arm_l.rotation.x = lerpf(arm_l.rotation.x, arm_up, minf(12.0 * delta, 1.0))
	arm_r.rotation.y = lerpf(arm_r.rotation.y, swing, minf(14.0 * delta, 1.0))
	# terazi kolu dengeye göre eğilir
	var tilt := clampf(balance / (max_hp * 0.07), -1.0, 1.0) * 0.45
	_beam.rotation.z = lerpf(_beam.rotation.z, -tilt, minf(5.0 * delta, 1.0))
	for pn in _pans:
		(pn as Node3D).rotation.z = -_beam.rotation.z
	m_eye.emission_energy_multiplier = glow
	m_body.emission = Color(0.4, 0.25, 0.1).lerp(Color(1.0, 1.0, 1.0), _flash)
	m_body.emission_energy_multiplier = 0.2 + _flash * 3.0
