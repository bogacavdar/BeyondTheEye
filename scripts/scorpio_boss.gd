extends "res://scripts/aries_boss.gd"
## AKREP: Zehir Mağaraları'nın kraliçesi. Obsidyen kabuklu dev akrep; kuyruğunda Antares parlar.
## Akrep astrolojide ölüm ve yeniden doğuştur: Kraliçe ilk kez ölünce ANKA olarak yeniden doğar.
##  1. evre (100-50%):
##    - KISKAÇ: altın uyarı, iki kıskaç; parry'lenir
##    - İĞNE: kuyruğunu hatta saplar (kızıl şerit), üç kez arka arkaya, her seferinde yeniden nişan alır
##    - ZEHİR BULUTU: etrafına zehirli gölcükler saçar
##  2. evre (50-0%): + KUM ALTI: toprağa gömülür, altından fırlar
##  YENİDEN DOĞUŞ: canı bitince bir kez ANKA olarak %35 canla doğar:
##    - ANTARES HALKASI: dışa yayılan alev halkaları · ALEV DALIŞI: hatlar boyunca ateş

signal hint(a: String, b: String)

const H = preload("res://scripts/hazards.gd")
const AriesS = preload("res://scripts/aries_boss.gd")
const PINCER := {"windup": 0.6, "act": 0.16, "recover": 0.6, "dmg": 22.0, "reach": 3.8, "arc": 120.0}
const VENOM := Color(0.5, 1.0, 0.3)
const FLAME := Color(1.0, 0.55, 0.2)

var _left := 0
var _reborn := false
var _hidden := false
var m_chitin: StandardMaterial3D
var m_venom: StandardMaterial3D
var _tail: Node3D


func _init() -> void:
	kind = "scorpio"
	title = "SCORPIO  ·  THE VENOM QUEEN"
	max_hp = 3000.0
	hp = 3000.0
	radius = 1.6
	_cd = {"pincer": 0.4, "sting": 1.2, "cloud": 3.0, "burrow": 1.0, "ring": 1.0, "dive": 1.0}
	_global_cd = 1.1


func _build() -> void:
	m_chitin = _m(Color(0.1, 0.09, 0.14), 0.25, 0.3)
	m_chitin.emission_enabled = true
	m_chitin.emission = VENOM
	m_chitin.emission_energy_multiplier = 0.1
	m_body = m_chitin
	m_venom = _m(VENOM, 0.3)
	m_venom.emission_enabled = true
	m_venom.emission = VENOM
	m_venom.emission_energy_multiplier = 2.0
	m_horn = m_venom
	m_eye = StandardMaterial3D.new()
	m_eye.albedo_color = Color.BLACK
	m_eye.emission_enabled = true
	m_eye.emission = VENOM
	m_eye.emission_energy_multiplier = 5.0
	body_root = Node3D.new()
	add_child(body_root)
	vis = Node3D.new()
	body_root.add_child(vis)
	vis.scale = Vector3.ONE * 0.9
	# gövde parçaları
	for k in 4:
		_part(vis, _sph(0.9 - float(k) * 0.08), Vector3(0, 1.2, -0.8 + float(k) * 0.65), m_chitin, Vector3(1.3, 0.6, 0.9))
	head = Node3D.new()
	head.position = Vector3(0, 1.3, -1.5)
	vis.add_child(head)
	_part(head, _sph(0.55), Vector3.ZERO, m_chitin, Vector3(1.1, 0.6, 0.8))
	for i in 6:
		_part(head, _sph(0.07), Vector3(-0.25 + float(i % 3) * 0.25, 0.25 + float(i / 3) * 0.08, -0.35), m_eye)
	# bacaklar
	for s in [-1.0, 1.0]:
		for k in 4:
			var leg := _part(vis, _cone(0.1, 0.03, 1.6), Vector3(s * 1.3, 0.7, -0.6 + float(k) * 0.5), m_chitin)
			leg.rotation.z = s * 0.9
	# kıskaçlar
	arm_l = _claw(-1.0)
	arm_r = _claw(1.0)
	# kuyruk: yukarı kıvrılan halkalar, ucunda Antares
	_tail = Node3D.new()
	_tail.position = Vector3(0, 1.4, 1.6)
	vis.add_child(_tail)
	for k in 6:
		var a := float(k) * 0.5
		_part(_tail, _sph(0.38 - float(k) * 0.035), Vector3(0, sin(a) * 1.3 + float(k) * 0.35, cos(a) * 0.6 - float(k) * 0.25), m_chitin)
	_part(_tail, _sph(0.3), Vector3(0, 3.0, -1.2), m_venom)
	var sting := _part(_tail, _cone(0.15, 0.0, 0.7), Vector3(0, 2.8, -1.6), m_venom)
	sting.rotation.x = -2.2
	mane = CPUParticles3D.new()
	mane.amount = 20
	mane.lifetime = 1.6
	var em := SphereMesh.new()
	em.radius = 0.06
	em.height = 0.12
	mane.mesh = em
	mane.material_override = Fx.emissive(VENOM, 3.0)
	mane.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	mane.emission_sphere_radius = 0.5
	mane.gravity = Vector3(0, -1.0, 0)
	mane.position = Vector3(0, 3.0, -1.2)
	_tail.add_child(mane)
	var l := OmniLight3D.new()
	l.light_color = VENOM
	l.light_energy = 1.6
	l.omni_range = 7.0
	l.position = Vector3(0, 3.0, 0)
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
	sh.position = Vector3(side * 0.9, 1.3, -1.7)
	vis.add_child(sh)
	var a1 := _part(sh, _cone(0.18, 0.14, 1.0), Vector3(side * 0.2, 0, -0.4), m_chitin)
	a1.rotation.x = PI * 0.5
	_part(sh, _sph(0.5), Vector3(side * 0.25, 0.05, -1.2), m_chitin, Vector3(0.8, 0.6, 1.3))
	var up := _part(sh, _cone(0.22, 0.03, 0.9), Vector3(side * 0.25, 0.2, -1.9), m_venom)
	up.rotation.x = PI * 0.5 + 0.25
	return sh


func _place_tele() -> void:
	var b := Basis.looking_at(_aim_dir, Vector3.UP) if _aim_dir.length() > 0.1 else Basis.IDENTITY
	tele.global_transform = Transform3D(b, Vector3(global_position.x, 0.07, global_position.z))


func _speed_mult() -> float:
	return 1.35 if _reborn else (1.15 if phase >= 2 else 1.0)


func _windup_len() -> float:
	var k := windup_mult / _speed_mult()
	match atk:
		"pincer":
			return (float(PINCER["windup"]) if _left > 0 else 0.4) * k
		"sting":
			return (0.6 if _left >= 2 else 0.4) * k
		"burrow":
			return 0.5 * k
	return 0.7 * k


func _recover_len() -> float:
	return 0.9 if atk == "sting" else 0.6


func _pick(dist: float, dir_to: Vector3) -> void:
	var opts: Array = []
	if float(_cd["pincer"]) <= 0.0 and dist < 4.0:
		opts.append_array(["pincer", "pincer"])
	if float(_cd["sting"]) <= 0.0 and dist > 2.5:
		opts.append_array(["sting", "sting"])
	if float(_cd["cloud"]) <= 0.0:
		opts.append("cloud")
	if phase >= 2 and float(_cd["burrow"]) <= 0.0:
		opts.append("burrow")
	if _reborn and float(_cd["ring"]) <= 0.0:
		opts.append_array(["ring", "ring"])
	if _reborn and float(_cd["dive"]) <= 0.0:
		opts.append("dive")
	if opts.is_empty():
		return
	atk = String(opts[randi() % opts.size()])
	_aim_dir = dir_to
	_left = 1 if atk == "pincer" else (2 if atk == "sting" else 0)
	_set_state("windup")


func _set_state(s: String) -> void:
	state = s
	_st = 0.0
	match s:
		"windup":
			tele.visible = false
			if atk == "pincer":
				_show_tele(_fan_mesh(deg_to_rad(float(PINCER["arc"])), float(PINCER["reach"])), PARRY_COL)
			Sfx.play("bossroar", -10.0, 0.08, 0, 1.0)
		"act":
			_done = false
			tele.visible = false
		"recover":
			tele.visible = false
			_global_cd = randf_range(0.25, 0.5) / _speed_mult()
			match atk:
				"pincer":
					_cd["pincer"] = 1.2
				"sting":
					_cd["sting"] = 4.0
				"cloud":
					_cd["cloud"] = 7.0
				"burrow":
					_cd["burrow"] = 8.0
				"ring":
					_cd["ring"] = 5.0
				"dive":
					_cd["dive"] = 6.0
		_:
			tele.visible = false


func _aim_again() -> void:
	if H.hero_ok(hero):
		var nd: Vector3 = hero.global_position - global_position
		nd.y = 0.0
		if nd.length() > 0.3:
			_aim_dir = nd.normalized()


func _act(_delta: float, _sm: float) -> Vector3:
	match atk:
		"pincer":
			if not _done and _st >= 0.06:
				_done = true
				_pincer_hit()
			if _st >= float(PINCER["act"]) and state == "act":
				if _left > 0:
					_left -= 1
					_aim_again()
					_set_state("windup")
				else:
					_set_state("recover")
			return _aim_dir * 5.0
		"sting":
			if not _done:
				_done = true
				var ln := H.Line.new()
				ln.hero = hero
				ln.dir = _aim_dir
				ln.length = 9.0
				ln.width = 1.3
				ln.delay = 0.45
				ln.dmg = 20.0 * dmg_mult
				ln.col = FLAME if _reborn else VENOM
				ln.eff = "poison"
				get_parent().add_child(ln)
				ln.global_position = Vector3(global_position.x, 0, global_position.z) + _aim_dir * 0.8
			if _st >= 0.5 and state == "act":
				if _left > 0:
					_left -= 1
					_aim_again()
					_set_state("windup")
				else:
					_set_state("recover")
		"cloud":
			if not _done:
				_done = true
				if H.hero_ok(hero):
					for i in 4:
						var b := H.Blast.new()
						b.hero = hero
						b.radius = 1.9
						b.delay = 1.0 + float(i) * 0.12
						b.dmg = 12.0 * dmg_mult
						b.col = VENOM
						b.eff = "poison"
						b.pool_life = 5.0
						get_parent().add_child(b)
						var p: Vector3 = hero.global_position if i == 0 else hero.global_position + Vector3(randf_range(-4, 4), 0, randf_range(-4, 4))
						b.global_position = H.clamp_arena(p, _bounds)
			if _st >= 0.3:
				_set_state("recover")
		"burrow":
			# gömül → kahramanın altından çık
			if not _done:
				_done = true
				_hidden = true
				var tw := create_tween()
				tw.tween_property(vis, "position:y", -4.0, 0.35)
			if _st >= 0.5 and _st < 0.55 and H.hero_ok(hero):
				var b2 := H.Blast.new()
				b2.hero = hero
				b2.radius = 2.8
				b2.delay = 1.0
				b2.dmg = 26.0 * dmg_mult
				b2.col = VENOM
				b2.eff = "knock"
				get_parent().add_child(b2)
				b2.global_position = H.clamp_arena(hero.global_position, _bounds)
				global_position = b2.global_position
			if _st >= 1.5:
				_hidden = false
				var tw2 := create_tween()
				tw2.tween_property(vis, "position:y", 0.0, 0.25).set_trans(Tween.TRANS_BACK)
				_set_state("recover")
		"ring":
			if not _done:
				_done = true
				var fr := AriesS.FireRing.new()
				fr.hero = hero
				fr.dmg = 20.0 * dmg_mult
				fr.position = Vector3(global_position.x, 0.0, global_position.z)
				get_parent().add_child(fr)
			if _st >= 0.6 and _st < 0.65:
				var fr2 := AriesS.FireRing.new()
				fr2.hero = hero
				fr2.dmg = 20.0 * dmg_mult
				fr2.position = Vector3(global_position.x, 0.0, global_position.z)
				get_parent().add_child(fr2)
			if _st >= 0.9:
				_set_state("recover")
		"dive":
			if not _done:
				_done = true
				for i in 3:
					var ln2 := H.Line.new()
					ln2.hero = hero
					ln2.dir = _aim_dir.rotated(Vector3.UP, (float(i) - 1.0) * 0.5)
					ln2.length = 13.0
					ln2.width = 1.4
					ln2.delay = 0.6 + float(i) * 0.15
					ln2.dmg = 22.0 * dmg_mult
					ln2.col = FLAME
					get_parent().add_child(ln2)
					ln2.global_position = Vector3(global_position.x, 0, global_position.z)
			if _st >= 0.4:
				_set_state("recover")
	return Vector3.ZERO


func _pincer_hit() -> void:
	var reach := float(PINCER["reach"])
	var arc := deg_to_rad(float(PINCER["arc"]))
	var fx := SlashFx.make(-arc * 0.5, arc * 0.5, 0.8, reach, PARRY_COL, 0.22)
	get_parent().add_child(fx)
	fx.global_transform = Transform3D(Basis.looking_at(_aim_dir, Vector3.UP), global_position + Vector3(0, 1.3, 0))
	Sfx.play("crush", -6.0, 0.1, 0, 0.9)
	if not H.hero_ok(hero):
		return
	var to: Vector3 = hero.global_position - global_position
	to.y = 0.0
	var dist := to.length()
	if dist > reach + 0.4 or (dist > 0.3 and _aim_dir.angle_to(to / dist) > arc * 0.5):
		return
	var res: String = hero.take_damage(float(PINCER["dmg"]) * dmg_mult, to.normalized() if dist > 0.05 else _aim_dir, true)
	if res == "parried":
		_left = 0
		stun(2.2, true)
		_knock = -_aim_dir * 3.0


func stun(sec: float, parried := false) -> void:
	if _hidden:
		return
	_left = 0
	super.stun(sec, parried)


func take_hit(dmg: float, dir: Vector3, kb: float, heavy: bool, crit := false) -> void:
	if puppet:
		Net.send_hit(self, dmg, dir, kb, heavy, crit)
		_flash = 1.0
		return
	if _hidden:
		last_dealt = 0.0
		return
	super.take_hit(dmg, dir, kb, heavy, crit)


func _damage(d: float) -> void:
	hp -= d
	if hp <= 0.0:
		if not _reborn:
			_rebirth()
			return
		_die()
		return
	if phase == 1 and hp < max_hp * 0.5 and not _reborn:
		_enter_phase(2)


## Ölüm ve yeniden doğuş: Anka
func _rebirth() -> void:
	_reborn = true
	hp = max_hp * 0.35
	phase = 3
	_left = 0
	tele.visible = false
	_set_state("roar")
	Fx.shake(1.0)
	Fx.flash_light(global_position + Vector3(0, 3, 0), FLAME, 14.0, 20.0, 1.2)
	Sfx.play("bossroar", 0.0, 0.0, 0, 0.6)
	Sfx.play("boom", -4.0, 0.0, 0, 0.6)
	m_chitin.albedo_color = Color(0.35, 0.12, 0.08)
	m_chitin.emission = FLAME
	m_chitin.emission_energy_multiplier = 0.6
	m_venom.albedo_color = FLAME
	m_venom.emission = FLAME
	m_eye.emission = Color(1.0, 0.8, 0.3)
	mane.material_override = Fx.emissive(FLAME, 4.0)
	mane.amount = 70
	_cd["ring"] = 0.5
	hint.emit("THE PHOENIX RISES", tr("Scorpio is reborn from its own venom"))
	summon.emit(["shade", "leaper"])
	phase_changed.emit(3)


func _enter_phase(p: int) -> void:
	phase = p
	_left = 0
	tele.visible = false
	_set_state("roar")
	Fx.shake(0.7)
	Fx.flash_light(global_position + Vector3(0, 3, 0), VENOM, 10.0, 16.0, 0.8)
	Sfx.play("bossroar", -2.0, 0.0, 0, 0.8)
	mane.amount = 40
	_cd["burrow"] = 0.5
	hint.emit("BENEATH THE SAND", tr("Watch for the ground swelling under you"))
	summon.emit(["shade", "shade", "caster"])
	phase_changed.emit(p)


func _animate(delta: float) -> void:
	body_root.rotation.y = lerp_angle(body_root.rotation.y, atan2(-_face.x, -_face.z), minf(8.0 * delta, 1.0))
	var open := 0.0
	var tail := 0.0
	var glow := 5.0
	match state:
		"windup":
			var k := clampf(_st / _windup_len(), 0.0, 1.0)
			match atk:
				"pincer":
					open = 0.9 * k
				"sting", "dive":
					tail = 0.6 * k
				_:
					open = 0.5 * k
			glow = 5.0 + 12.0 * k
		"act":
			open = -0.4 if atk == "pincer" else 0.0
			tail = -0.5 if atk == "sting" or atk == "dive" else 0.0
			glow = 15.0
		"roar":
			open = 1.2
			tail = 0.4
			glow = 18.0
		"stun":
			glow = 1.5
	arm_l.rotation.x = lerpf(arm_l.rotation.x, open, minf(12.0 * delta, 1.0))
	arm_r.rotation.x = lerpf(arm_r.rotation.x, open, minf(12.0 * delta, 1.0))
	_tail.rotation.x = lerpf(_tail.rotation.x, tail + sin(_t * 2.0) * 0.05, minf(10.0 * delta, 1.0))
	m_eye.emission_energy_multiplier = glow
