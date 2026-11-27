extends "res://scripts/aries_boss.gd"
## YAY: Kentaur Bozkırı'nın efendisi, Okçu Kral. Dev, mor-altın bir kentaur; mesafeyi korur, uzaktan avlar.
## Ona yakın durmak zordur: yaklaşınca çifte tekmeyle (parry'lenir) savurup geri sıçrar.
##  1. evre (100-65%):
##    - OK YAĞMURU: senin çevrene oklar düşer
##    - DELİCİ OK: arenayı boydan boya delen ok (önce ince bir hat belirir)
##    - ÇİFTE TEKME: yakındaysan altın uyarı; parry'lersen uzun sersemler
##  2. evre (65-30%): + DÖRTNALA: arenayı boydan boya koşar, arkasında ok izi bırakır; delici ok üçlü
##  3. evre (<30%):   + GALAKSİ MERKEZİ: arenanın kenarlarından merkeze oklar yağar

signal hint(a: String, b: String)

const H = preload("res://scripts/hazards.gd")
const KICK := {"windup": 0.55, "act": 0.16, "recover": 0.5, "dmg": 24.0, "reach": 3.6, "arc": 150.0}
const GOLD := Color(1.0, 0.82, 0.45)
const VIOLET := Color(0.6, 0.45, 1.0)

var _shots := 0
var _gallop_from := Vector3.ZERO
var _gallop_to := Vector3.ZERO
var m_coat: StandardMaterial3D


func _init() -> void:
	phase_th = [0.65, 0.3]   # §13.6 evre eşikleri
	kind = "sagittarius"
	title = "SAGITTARIUS  ·  THE ARCHER KING"
	max_hp = 3000.0
	hp = 3000.0
	radius = 1.3
	_cd = {"volley": 0.8, "pierce": 1.5, "kick": 0.0, "gallop": 1.0, "galaxy": 1.0}
	_global_cd = 1.0


func _build() -> void:
	m_coat = _m(Color(0.4, 0.28, 0.7), 0.5)
	m_coat.emission_enabled = true
	m_coat.emission = Color(0.4, 0.25, 1.0)
	m_coat.emission_energy_multiplier = 0.25
	m_body = _m(Color(0.88, 0.82, 0.95), 0.5)
	m_body.emission_enabled = true
	m_body.emission = Color(0.3, 0.2, 0.6)
	m_body.emission_energy_multiplier = 0.1
	m_horn = _m(GOLD, 0.3, 0.6)
	m_eye = StandardMaterial3D.new()
	m_eye.albedo_color = Color.BLACK
	m_eye.emission_enabled = true
	m_eye.emission = GOLD
	m_eye.emission_energy_multiplier = 5.0
	body_root = Node3D.new()
	add_child(body_root)
	vis = Node3D.new()
	body_root.add_child(vis)
	vis.scale = Vector3.ONE * 0.9
	# at gövdesi
	_part(vis, _sph(0.9), Vector3(0, 1.9, 0.4), m_coat, Vector3(0.85, 0.75, 1.6))
	for i in 4:
		var x := -0.45 if i % 2 == 0 else 0.45
		var z := -0.5 if i < 2 else 1.3
		_part(vis, _cone(0.14, 0.2, 1.6), Vector3(x, 0.8, z), m_coat)
		_part(vis, _sph(0.2), Vector3(x, 0.05, z), m_horn, Vector3(1.0, 0.5, 1.2))
	var tail := _part(vis, _cone(0.18, 0.04, 1.5), Vector3(0, 2.0, 1.9), m_horn)
	tail.rotation.x = 0.9
	# insan üst gövde ve baş
	_part(vis, _cone(0.45, 0.55, 1.4), Vector3(0, 3.1, -0.7), m_coat)
	head = Node3D.new()
	head.position = Vector3(0, 4.1, -0.75)
	vis.add_child(head)
	_part(head, _sph(0.32), Vector3.ZERO, m_body)
	for s in [-1.0, 1.0]:
		_part(head, _sph(0.06), Vector3(s * 0.12, 0.05, -0.28), m_eye, Vector3(1.4, 0.7, 1.0))
	for i in 7:
		var a := -0.9 + float(i) * 0.3
		var sp := _part(head, _cone(0.06, 0.0, 0.4), Vector3(sin(a) * 0.28, 0.35, cos(a) * 0.08), m_horn)
		sp.rotation.z = -a * 0.5
	arm_l = _arm_s(-1.0)
	arm_r = _arm_s(1.0)
	# dev yay
	var bow := TorusMesh.new()
	bow.inner_radius = 1.3
	bow.outer_radius = 1.42
	var bw := _part(arm_l, bow, Vector3(0, -1.0, -0.2), m_horn, Vector3(1.0, 1.0, 0.3))
	bw.rotation.y = PI * 0.5
	mane = CPUParticles3D.new()
	mane.amount = 24
	mane.lifetime = 1.5
	var em := SphereMesh.new()
	em.radius = 0.05
	em.height = 0.1
	mane.mesh = em
	mane.material_override = Fx.emissive(GOLD, 3.0)
	mane.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	mane.emission_sphere_radius = 1.0
	mane.gravity = Vector3(0, 0.6, 0)
	mane.position = Vector3(0, 3.0, 0)
	vis.add_child(mane)
	var l := OmniLight3D.new()
	l.light_color = VIOLET
	l.light_energy = 1.6
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


func _arm_s(side: float) -> Node3D:
	var sh := Node3D.new()
	sh.position = Vector3(side * 0.6, 3.6, -0.7)
	vis.add_child(sh)
	_part(sh, _cone(0.16, 0.12, 1.2), Vector3(0, -0.6, 0), m_coat)
	_part(sh, _sph(0.13), Vector3(0, -1.25, 0), m_body)
	return sh


func _place_tele() -> void:
	var b := Basis.looking_at(_aim_dir, Vector3.UP) if _aim_dir.length() > 0.1 else Basis.IDENTITY
	tele.global_transform = Transform3D(b, Vector3(global_position.x, 0.07, global_position.z))


## Okçu mesafe korur: yakınsan uzaklaşır, uzaksan yaklaşır, arada yan yan dolaşır
func _chase_vel(dist: float, dir_to: Vector3, sm: float) -> Vector3:
	var side := Vector3(-dir_to.z, 0, dir_to.x) * (1.0 if fmod(_t, 8.0) < 4.0 else -1.0)
	if dist < 6.0:
		return (-dir_to * 0.8 + side * 0.5).normalized() * 4.2 * sm
	if dist > 11.0:
		return dir_to * 3.2 * sm
	return side * 2.6 * sm


func _speed_mult() -> float:
	return [1.0, 1.0, 1.12, 1.3][clampi(phase, 1, 3)]


func _windup_len() -> float:
	var k := windup_mult / _speed_mult()
	match atk:
		"kick":
			return float(KICK["windup"]) * k
		"pierce":
			return (1.0 if _shots <= 0 else 0.55) * k
		"gallop":
			return 0.9 * k
		"galaxy":
			return 0.8 * k
	return 0.7 * k


func _recover_len() -> float:
	return 0.9 if atk == "gallop" else 0.55


func _pick(dist: float, dir_to: Vector3) -> void:
	var opts: Array = []
	if float(_cd["kick"]) <= 0.0 and dist < 3.6:
		opts.append_array(["kick", "kick", "kick"])
	if float(_cd["volley"]) <= 0.0:
		opts.append_array(["volley", "volley"])
	if float(_cd["pierce"]) <= 0.0 and dist > 3.0:
		opts.append_array(["pierce", "pierce"])
	if phase >= 2 and float(_cd["gallop"]) <= 0.0:
		opts.append("gallop")
	if phase >= 3 and float(_cd["galaxy"]) <= 0.0:
		opts.append("galaxy")
	if opts.is_empty():
		return
	atk = String(opts[randi() % opts.size()])
	_aim_dir = dir_to
	_shots = (2 if phase >= 2 else 0) if atk == "pierce" else 0
	if atk == "gallop":
		# arenanın kenarından kenarına, kahramanın yakınından geçen bir hat
		var a := atan2(dir_to.z, dir_to.x) + randf_range(-0.4, 0.4)
		var d := Vector3(cos(a), 0, sin(a))
		_gallop_from = global_position
		_gallop_to = H.clamp_arena(global_position + d * 30.0, _bounds)
		_aim_dir = (_gallop_to - _gallop_from).normalized()
	_set_state("windup")


func _set_state(s: String) -> void:
	state = s
	_st = 0.0
	match s:
		"windup":
			tele.visible = false
			match atk:
				"kick":
					_show_tele(_fan_mesh(deg_to_rad(float(KICK["arc"])), float(KICK["reach"])), PARRY_COL)
				"pierce":
					_show_tele(_line_mesh(26.0, 1.2), DANGER_COL)
				"gallop":
					_show_tele(_line_mesh(_gallop_from.distance_to(_gallop_to), 2.6), DANGER_COL)
			Sfx.play("bossroar", -10.0, 0.08, 0, 1.1)
		"act":
			_done = false
			if atk != "gallop":
				tele.visible = false
		"recover":
			tele.visible = false
			_global_cd = randf_range(0.2, 0.45) / _speed_mult()
			match atk:
				"kick":
					_cd["kick"] = 2.5
				"volley":
					_cd["volley"] = 3.2 if phase < 3 else 2.4
				"pierce":
					_cd["pierce"] = 4.0
				"gallop":
					_cd["gallop"] = 8.0
				"galaxy":
					_cd["galaxy"] = 11.0
		_:
			tele.visible = false


func _act(delta: float, sm: float) -> Vector3:
	match atk:
		"kick":
			if not _done and _st >= 0.06:
				_done = true
				_kick_hit()
			if _st >= float(KICK["act"]) and state == "act":
				_set_state("recover")
				_knock = -_aim_dir * 12.0      # tekmeden sonra geri sıçrar
			return Vector3.ZERO
		"volley":
			if not _done:
				_done = true
				Sfx.play("bowshot", -2.0, 0.0, 0, 0.7)
				if H.hero_ok(hero):
					var n := 6 if phase < 3 else 9
					for i in n:
						var b := H.Blast.new()
						b.hero = hero
						b.radius = 1.4
						b.delay = 0.9 + float(i) * 0.08
						b.dmg = 16.0 * dmg_mult
						b.col = GOLD
						get_parent().add_child(b)
						var off := Vector3.ZERO if i == 0 else Vector3(randf_range(-3.0, 3.0), 0, randf_range(-3.0, 3.0))
						b.global_position = H.clamp_arena(hero.global_position + off, _bounds)
			if _st >= 0.3:
				_set_state("recover")
		"pierce":
			if not _done:
				_done = true
				var ln := H.Line.new()
				ln.hero = hero
				ln.dir = _aim_dir
				ln.length = 26.0
				ln.width = 1.2
				ln.delay = 0.05
				ln.dmg = 24.0 * dmg_mult
				ln.col = GOLD
				ln.eff = "knock"
				get_parent().add_child(ln)
				ln.global_position = Vector3(global_position.x, 0, global_position.z)
				Sfx.play("bowshot", 0.0, 0.0, 0, 0.5)
			if _st >= 0.25 and state == "act":
				if _shots > 0:
					_shots -= 1
					if H.hero_ok(hero):
						var nd: Vector3 = hero.global_position - global_position
						nd.y = 0.0
						if nd.length() > 0.3:
							_aim_dir = nd.normalized()
					_set_state("windup")
				else:
					_set_state("recover")
		"gallop":
			var spd := 20.0 * sm
			var to := _gallop_to - global_position
			to.y = 0.0
			_face = _aim_dir
			if not _done:
				_done = true
				_gallop_to = H.clamp_arena(global_position + _aim_dir * 30.0, _bounds)
				Sfx.play("dash", -2.0, 0.0, 0, 0.5)
			if H.hero_ok(hero) and H.flat_dist(hero.global_position, global_position) < 1.9:
				H.hurt(hero, 26.0 * dmg_mult, _aim_dir, "knock")
			# arkasında ok izi
			if int(_st * 10.0) % 2 == 0 and fmod(_st, 0.1) < delta:
				var b2 := H.Blast.new()
				b2.hero = hero
				b2.radius = 1.3
				b2.delay = 0.8
				b2.dmg = 14.0 * dmg_mult
				b2.col = VIOLET
				get_parent().add_child(b2)
				b2.global_position = Vector3(global_position.x, 0, global_position.z)
			if to.length() < 0.6 or _st > 2.0:
				tele.visible = false
				_set_state("recover")
				return Vector3.ZERO
			_move = to.normalized() * spd
			return _move
		"galaxy":
			if not _done:
				_done = true
				var base_a := randf() * TAU
				for i in 8:
					var a := base_a + TAU * float(i) / 8.0
					var ln2 := H.Line.new()
					ln2.hero = hero
					ln2.dir = -Vector3(cos(a), 0, sin(a))
					ln2.length = _bounds * 2.0
					ln2.width = 1.2
					ln2.delay = 1.0 + float(i % 4) * 0.35
					ln2.dmg = 20.0 * dmg_mult
					ln2.col = VIOLET
					get_parent().add_child(ln2)
					ln2.global_position = Vector3(cos(a), 0, sin(a)) * _bounds
			if _st >= 0.4:
				_set_state("recover")
	return Vector3.ZERO


func _kick_hit() -> void:
	var reach := float(KICK["reach"])
	var arc := deg_to_rad(float(KICK["arc"]))
	var fx := SlashFx.make(-arc * 0.5, arc * 0.5, 0.6, reach, PARRY_COL, 0.2)
	get_parent().add_child(fx)
	fx.global_transform = Transform3D(Basis.looking_at(_aim_dir, Vector3.UP), global_position + Vector3(0, 1.0, 0))
	Sfx.play("crush", -6.0, 0.1, 0, 0.9)
	if not H.hero_ok(hero):
		return
	var to: Vector3 = hero.global_position - global_position
	to.y = 0.0
	var dist := to.length()
	if dist > reach + 0.4 or (dist > 0.3 and _aim_dir.angle_to(to / dist) > arc * 0.5):
		return
	var res: String = hero.take_damage(float(KICK["dmg"]) * dmg_mult, to.normalized() if dist > 0.05 else _aim_dir, true)
	if res == "parried":
		stun(2.6, true)
	elif res == "hit":
		hero.velocity = to.normalized() * 15.0


func _damage(d: float) -> void:
	hp -= d
	hp = maxf(hp, _phase_floor())   # §13.6
	if hp <= 0.0:
		_die()
		return
	if phase == 1 and hp < max_hp * 0.65:
		_enter_phase(2)
	elif phase == 2 and hp < max_hp * 0.3:
		_enter_phase(3)


func _enter_phase(p: int) -> void:
	phase = p
	_shots = 0
	tele.visible = false
	_set_state("roar")
	Fx.shake(0.7)
	Fx.flash_light(global_position + Vector3(0, 3, 0), GOLD, 10.0, 16.0, 0.8)
	Sfx.play("bossroar", -2.0, 0.0, 0, 0.9)
	mane.amount = 24 if p == 1 else (44 if p == 2 else 70)
	if p == 2:
		_cd["gallop"] = 0.5
		hint.emit("THE GALLOP", tr("He runs the arena end to end; step aside"))
		summon.emit(["shade", "shade", "caster"])
	elif p == 3:
		_cd["galaxy"] = 0.5
		hint.emit("THE GALACTIC CENTER", tr("Arrows rain in from every edge"))
		summon.emit(["leaper", "leaper"])
	phase_changed.emit(p)


func _animate(delta: float) -> void:
	body_root.rotation.y = lerp_angle(body_root.rotation.y, atan2(-_face.x, -_face.z), minf(8.0 * delta, 1.0))
	var draw := 0.0
	var rear := 0.0
	var glow := 5.0
	match state:
		"windup":
			var k := clampf(_st / _windup_len(), 0.0, 1.0)
			if atk == "kick":
				rear = 0.3 * k
			else:
				draw = 1.6 * k
			glow = 5.0 + 12.0 * k
		"act":
			draw = 1.6 if atk != "kick" else 0.0
			rear = -0.25 if atk == "kick" else 0.0
			glow = 15.0
		"roar":
			rear = -0.35
			draw = 2.4
			glow = 18.0
		"stun":
			rear = 0.2
			glow = 1.5
	vis.rotation.x = lerpf(vis.rotation.x, rear, minf(10.0 * delta, 1.0))
	arm_l.rotation.x = lerpf(arm_l.rotation.x, draw, minf(12.0 * delta, 1.0))
	arm_r.rotation.x = lerpf(arm_r.rotation.x, draw * 0.9, minf(12.0 * delta, 1.0))
	m_eye.emission_energy_multiplier = glow
	m_coat.emission_energy_multiplier = 0.25 + _flash * 3.0
