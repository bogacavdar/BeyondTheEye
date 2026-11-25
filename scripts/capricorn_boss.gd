extends "res://scripts/aries_boss.gd"
## OĞLAK: Donmuş Zirve'nin bilgesi, Dağın Yaşlısı. Ön yarısı dev dağ keçisi, arka yarısı balık kuyruklu deniz keçisi.
## Oğlak sabırdır: Saldırıları yavaş ama ağır; arena giderek buz ve çığla daralır.
##  1. evre (100-65%):
##    - BOYNUZ: altın uyarı, iki tos; parry'lenir
##    - ÇIĞ: arenanın bir ucundan öbürüne sırayla yuvarlanan kaya şeritleri
##    - BUZ ÇEMBERİ: etrafında tek bir boşluk bırakan buz dikenleri halkası (boşluğu bul)
##  2. evre (65-30%): + DONDURUCU AYAZ: yerinde durursan donarsın; 6 sn boyunca hep hareket et
##  3. evre (<30%):   + DENİZ KEÇİSİ GELGİTİ: balık kuyruğuyla arenayı süpüren dalgalar; çığlar sıklaşır

signal hint(a: String, b: String)

const H = preload("res://scripts/hazards.gd")
const EnemyScript = preload("res://scripts/enemy.gd")
const HORNS := {"windup": 0.7, "act": 0.18, "recover": 0.7, "dmg": 28.0, "reach": 3.8, "arc": 120.0}
const ICE := Color(0.5, 0.9, 1.0)
const STONE := Color(0.75, 0.8, 0.85)

var _left := 0
var m_slate: StandardMaterial3D
var m_ice: StandardMaterial3D
var _frost_t := 0.0
var _still := 0.0
var _frost_tick := 0.0


func _init() -> void:
	kind = "capricorn"
	title = "CAPRICORN  ·  THE MOUNTAIN ELDER"
	max_hp = 3300.0
	hp = 3300.0
	radius = 1.5
	_cd = {"horns": 0.4, "avalanche": 1.5, "icering": 3.0, "frost": 1.0, "tide": 1.0}
	_global_cd = 1.2


func _build() -> void:
	m_slate = _m(Color(0.22, 0.28, 0.33), 0.6)
	m_slate.emission_enabled = true
	m_slate.emission = Color(0.2, 0.8, 0.8)
	m_slate.emission_energy_multiplier = 0.15
	m_body = m_slate
	m_ice = _m(ICE, 0.15)
	m_ice.emission_enabled = true
	m_ice.emission = ICE
	m_ice.emission_energy_multiplier = 1.0
	m_horn = m_ice
	m_eye = StandardMaterial3D.new()
	m_eye.albedo_color = Color.BLACK
	m_eye.emission_enabled = true
	m_eye.emission = Color(0.4, 1.0, 0.9)
	m_eye.emission_energy_multiplier = 5.0
	var scale_m := _m(Color(0.2, 0.45, 0.5), 0.3)
	scale_m.metallic = 0.5
	body_root = Node3D.new()
	add_child(body_root)
	vis = Node3D.new()
	body_root.add_child(vis)
	vis.scale = Vector3.ONE * 0.9
	# keçi ön gövde
	_part(vis, _sph(0.9), Vector3(0, 2.0, -0.4), m_slate, Vector3(1.0, 0.9, 1.2))
	for s in [-1.0, 1.0]:
		_part(vis, _cone(0.22, 0.3, 1.8), Vector3(s * 0.5, 0.9, -0.8), m_slate)
		_part(vis, _sph(0.25), Vector3(s * 0.5, 0.05, -0.85), m_ice, Vector3(1.0, 0.5, 1.2))
	# balık kuyruğu: kıvrılan pullu halkalar ve yüzgeç
	for k in 6:
		_part(vis, _sph(0.75 - float(k) * 0.1), Vector3(0, 1.6 - float(k) * 0.2, 0.6 + float(k) * 0.55), scale_m, Vector3(1.0, 0.8, 1.0))
	var fin := _part(vis, _sph(0.8), Vector3(0, 0.6, 3.9), m_ice, Vector3(1.3, 0.12, 0.6))
	fin.rotation.x = -0.3
	# baş, sakal ve dev kıvrık boynuzlar
	head = Node3D.new()
	head.position = Vector3(0, 3.0, -1.3)
	vis.add_child(head)
	_part(head, _sph(0.5), Vector3.ZERO, m_slate, Vector3(0.9, 1.0, 1.3))
	_part(head, _cone(0.25, 0.0, 0.8), Vector3(0, -0.6, -0.3), _m(Color(0.9, 0.92, 0.95)))
	for s in [-1.0, 1.0]:
		_part(head, _sph(0.08), Vector3(s * 0.25, 0.1, -0.45), m_eye, Vector3(1.4, 0.7, 1.0))
		for k in 5:
			var a := float(k) * 0.55
			_part(head, _sph(0.2 - float(k) * 0.025), Vector3(s * (0.35 + sin(a) * 0.5), 0.45 + cos(a) * 0.5, 0.2 + float(k) * 0.08), m_ice)
	arm_l = Node3D.new()
	arm_r = Node3D.new()
	head.add_child(arm_l)
	head.add_child(arm_r)
	mane = CPUParticles3D.new()
	mane.amount = 30
	mane.lifetime = 2.0
	var em := SphereMesh.new()
	em.radius = 0.05
	em.height = 0.1
	mane.mesh = em
	mane.material_override = Fx.emissive(Color(0.9, 0.95, 1.0), 2.0)
	mane.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	mane.emission_sphere_radius = 1.5
	mane.gravity = Vector3(0, -0.8, 0)
	mane.position = Vector3(0, 3.0, 0)
	vis.add_child(mane)
	var l := OmniLight3D.new()
	l.light_color = ICE
	l.light_energy = 1.6
	l.omni_range = 7.0
	l.position = Vector3(0, 4.0, -1.0)
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
	return [1.0, 0.95, 1.08, 1.22][clampi(phase, 1, 3)]


func _windup_len() -> float:
	var k := windup_mult / _speed_mult()
	if atk == "horns":
		return (float(HORNS["windup"]) if _left > 0 else 0.45) * k
	return 0.8 * k


func _recover_len() -> float:
	return float(HORNS["recover"]) if atk == "horns" else 0.6


func _pick(dist: float, dir_to: Vector3) -> void:
	var opts: Array = []
	if float(_cd["horns"]) <= 0.0 and dist < 4.0:
		opts.append_array(["horns", "horns", "horns"])
	if float(_cd["avalanche"]) <= 0.0:
		opts.append_array(["avalanche", "avalanche"])
	if float(_cd["icering"]) <= 0.0:
		opts.append("icering")
	if phase >= 2 and float(_cd["frost"]) <= 0.0:
		opts.append("frost")
	if phase >= 3 and float(_cd["tide"]) <= 0.0:
		opts.append("tide")
	if opts.is_empty():
		return
	atk = String(opts[randi() % opts.size()])
	_aim_dir = dir_to
	_left = 1 if atk == "horns" else 0
	_set_state("windup")


func _set_state(s: String) -> void:
	state = s
	_st = 0.0
	match s:
		"windup":
			tele.visible = false
			if atk == "horns":
				_show_tele(_fan_mesh(deg_to_rad(float(HORNS["arc"])), float(HORNS["reach"])), PARRY_COL)
			Sfx.play("bossroar", -8.0, 0.08, 0, 0.6)
		"act":
			_done = false
			tele.visible = false
		"recover":
			tele.visible = false
			_global_cd = randf_range(0.3, 0.6) / _speed_mult()
			match atk:
				"horns":
					_cd["horns"] = 1.3
				"avalanche":
					_cd["avalanche"] = 6.0 if phase < 3 else 4.0
				"icering":
					_cd["icering"] = 7.0
				"frost":
					_cd["frost"] = 14.0
				"tide":
					_cd["tide"] = 10.0
		_:
			tele.visible = false


func _act(_delta: float, _sm: float) -> Vector3:
	match atk:
		"horns":
			if not _done and _st >= 0.06:
				_done = true
				_horn_hit()
			if _st >= float(HORNS["act"]) and state == "act":
				if _left > 0:
					_left -= 1
					if H.hero_ok(hero):
						var nd: Vector3 = hero.global_position - global_position
						nd.y = 0.0
						if nd.length() > 0.3:
							_aim_dir = nd.normalized()
					_set_state("windup")
				else:
					_set_state("recover")
			return _aim_dir * 6.0
		"avalanche":
			if not _done:
				_done = true
				# arenanın bir ucundan öbürüne sırayla yuvarlanan kaya şeritleri (aralarında boşluk)
				var a := randf() * TAU
				var roll := Vector3(cos(a), 0, sin(a))
				var side := Vector3(-roll.z, 0, roll.x)
				var lanes := 4
				var gap := randi() % lanes
				for i in lanes:
					if i == gap:
						continue
					var ln := H.Line.new()
					ln.hero = hero
					ln.dir = roll
					ln.length = _bounds * 2.0 + 2.0
					ln.width = 4.2
					ln.delay = 1.1 + float(i) * 0.12
					ln.dmg = 24.0 * dmg_mult
					ln.col = STONE
					ln.eff = "knock"
					get_parent().add_child(ln)
					ln.global_position = side * (-_bounds + (float(i) + 0.5) * (_bounds * 2.0 / float(lanes))) - roll * (_bounds + 1.0)
				Fx.shake(0.4)
				Sfx.play("boom", -8.0, 0.0, 0, 0.5)
			if _st >= 0.4:
				_set_state("recover")
		"icering":
			if not _done:
				_done = true
				if H.hero_ok(hero):
					var c: Vector3 = hero.global_position
					var n := 10
					var gap2 := randi() % n
					for i in n:
						if i == gap2:
							continue
						var ang := TAU * float(i) / float(n)
						var b := H.Blast.new()
						b.hero = hero
						b.radius = 1.3
						b.delay = 1.0
						b.dmg = 18.0 * dmg_mult
						b.col = ICE
						b.eff = "freeze"
						get_parent().add_child(b)
						b.global_position = H.clamp_arena(c + Vector3(cos(ang), 0, sin(ang)) * 3.0, _bounds)
					# ve tam ortada
					var bc := H.Blast.new()
					bc.hero = hero
					bc.radius = 1.6
					bc.delay = 1.5
					bc.dmg = 18.0 * dmg_mult
					bc.col = ICE
					bc.eff = "freeze"
					get_parent().add_child(bc)
					bc.global_position = H.clamp_arena(c, _bounds)
			if _st >= 0.3:
				_set_state("recover")
		"frost":
			if not _done:
				_done = true
				_frost_t = 6.0
				hint.emit("BITING FROST", tr("Keep moving or freeze"))
			if _st >= 0.3:
				_set_state("recover")
		"tide":
			if not _done:
				_done = true
				for i in 2:
					var tw := EnemyScript.TideWave.new()
					tw.hero = hero
					var d := _aim_dir.rotated(Vector3.UP, (float(i) - 0.5) * 0.8)
					tw.dir = d
					tw.dmg = 20.0 * dmg_mult
					tw.width = 6.0
					tw.speed = 7.0
					tw.travel = _bounds * 2.2
					get_parent().add_child(tw)
					tw.global_position = Vector3(global_position.x, 0, global_position.z)
			if _st >= 0.4:
				_set_state("recover")
	return Vector3.ZERO


## Dondurucu ayaz: hareketsiz kalırsan hasar alır, yavaşlarsın
func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if _frost_t <= 0.0 or dead or not H.hero_ok(hero):
		return
	_frost_t -= delta
	var v: Vector3 = hero.velocity
	v.y = 0.0
	_still = _still + delta if v.length() < 1.0 else 0.0
	_frost_tick -= delta
	if _still > 0.6 and _frost_tick <= 0.0:
		_frost_tick = 0.5
		hero.apply_slow(0.4, 0.6)
		hero.apply_poison(6.0 * dmg_mult, 0.6)
		Fx.flash_light(hero.global_position + Vector3(0, 1, 0), ICE, 3.0, 3.0, 0.2)


func _horn_hit() -> void:
	var reach := float(HORNS["reach"])
	var arc := deg_to_rad(float(HORNS["arc"]))
	var fx := SlashFx.make(-arc * 0.5, arc * 0.5, 0.8, reach, PARRY_COL, 0.22)
	get_parent().add_child(fx)
	fx.global_transform = Transform3D(Basis.looking_at(_aim_dir, Vector3.UP), global_position + Vector3(0, 1.5, 0))
	Sfx.play("crush", -5.0, 0.1, 0, 0.7)
	if not H.hero_ok(hero):
		return
	var to: Vector3 = hero.global_position - global_position
	to.y = 0.0
	var dist := to.length()
	if dist > reach + 0.4 or (dist > 0.3 and _aim_dir.angle_to(to / dist) > arc * 0.5):
		return
	var res: String = hero.take_damage(float(HORNS["dmg"]) * dmg_mult, to.normalized() if dist > 0.05 else _aim_dir, true)
	if res == "parried":
		_left = 0
		stun(2.4, true)
		_knock = -_aim_dir * 3.0
	elif res == "hit":
		hero.velocity = (to.normalized() if dist > 0.05 else _aim_dir) * 14.0


func stun(sec: float, parried := false) -> void:
	_left = 0
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
	_left = 0
	tele.visible = false
	_set_state("roar")
	Fx.shake(0.8)
	Fx.flash_light(global_position + Vector3(0, 3, 0), ICE, 10.0, 16.0, 0.8)
	Sfx.play("bossroar", 0.0, 0.0, 0, 0.5)
	mane.amount = 30 if p == 1 else (60 if p == 2 else 100)
	if p == 2:
		_cd["frost"] = 0.5
		summon.emit(["shade", "shade", "caster"])
	elif p == 3:
		_cd["tide"] = 0.5
		hint.emit("TIDE OF THE SEA-GOAT", tr("The fish tail stirs the frozen sea"))
		summon.emit(["leaper", "brute"])
	phase_changed.emit(p)


func _animate(delta: float) -> void:
	body_root.rotation.y = lerp_angle(body_root.rotation.y, atan2(-_face.x, -_face.z), minf(6.0 * delta, 1.0))
	var lean := 0.0
	var head_x := 0.0
	var glow := 5.0
	match state:
		"windup":
			var k := clampf(_st / _windup_len(), 0.0, 1.0)
			if atk == "horns":
				head_x = 0.5 * k
				lean = 0.1 * k
			else:
				head_x = -0.4 * k
				lean = -0.15 * k
			glow = 5.0 + 12.0 * k
		"act":
			head_x = -0.3 if atk == "horns" else -0.5
			lean = 0.2 if atk == "horns" else 0.0
			glow = 15.0
		"roar":
			head_x = -0.6
			lean = -0.2
			glow = 18.0
		"stun":
			head_x = 0.3
			glow = 1.5
	vis.rotation.x = lerpf(vis.rotation.x, lean, minf(8.0 * delta, 1.0))
	head.rotation.x = lerpf(head.rotation.x, head_x, minf(10.0 * delta, 1.0))
	m_eye.emission_energy_multiplier = glow
	m_slate.emission_energy_multiplier = 0.15 + _flash * 3.0
