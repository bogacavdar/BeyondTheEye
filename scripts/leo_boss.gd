extends "res://scripts/aries_boss.gd"
## ASLAN: Güneş Sarayı'nın hükümdarı, Güneş Kral. Hızlı, saldırgan ve gururlu;
## yanındaki sürü yavruları yaşadıkça daha sert vurur (yavru başına +%15).
##  1. evre (100-65%):
##    - PENÇE SERİSİ: üç pençe art arda (altın uyarı); herhangi birini parry'le, seri kırılır
##    - SIÇRAYIŞ: üstüne atlar; indiği yer kızıl daireyle gösterilir
##    - KÜKREME: etrafındakileri savurur ve yavaşlatır
##  2. evre (65-30%): + ZENİT: güneş tepeye çıkar; arenanın her yeri yanar, yalnızca gölge daireleri güvenli
##                    + sürü yavruları çağırır
##  3. evre (<30%):   + TAÇ ALEVİ: etrafında dönen dört alev kolu; aralarında kal

signal hint(a: String, b: String)

const MAUL := {"windup": 0.55, "act": 0.14, "recover": 0.6, "dmg": 20.0, "reach": 3.6, "arc": 120.0}
const SUN_COL := Color(1.0, 0.8, 0.35)

var _mauls_left := 0
var _leap_from := Vector3.ZERO
var _leap_to := Vector3.ZERO
var m_mane: StandardMaterial3D


func _init() -> void:
	kind = "leo"
	title = "LEO  ·  THE SUN KING"
	max_hp = 2700.0
	hp = 2700.0
	radius = 1.5
	_cd = {"maul": 0.4, "pounce": 1.5, "roar": 4.0, "zenith": 1.0, "corona": 1.0}
	_global_cd = 1.1


# ---------------------------------------------------------------- görünüş: dev altın aslan

func _build() -> void:
	m_body = _m(Color(1.0, 0.74, 0.4), 0.6)
	m_body.emission_enabled = true
	m_body.emission = Color(0.5, 0.25, 0.05)
	m_body.emission_energy_multiplier = 0.25
	m_mane = _m(Color(0.95, 0.5, 0.12), 0.8)
	m_mane.emission_enabled = true
	m_mane.emission = Color(1.0, 0.5, 0.1)
	m_mane.emission_energy_multiplier = 0.6
	m_horn = _m(Color(1.0, 0.85, 0.45), 0.25, 0.9)
	m_eye = StandardMaterial3D.new()
	m_eye.albedo_color = Color.BLACK
	m_eye.emission_enabled = true
	m_eye.emission = Color(1.0, 0.9, 0.5)
	m_eye.emission_energy_multiplier = 5.0
	var claw := _m(Color(0.95, 0.92, 0.85), 0.3)

	body_root = Node3D.new()
	add_child(body_root)
	vis = Node3D.new()
	body_root.add_child(vis)
	vis.scale = Vector3.ONE * 0.85
	# gövde
	_part(vis, _sph(1.0), Vector3(0, 2.0, 0.4), m_body, Vector3(1.15, 1.0, 1.9))
	_part(vis, _sph(0.8), Vector3(0, 2.2, -0.6), m_body, Vector3(1.25, 1.1, 1.1))
	# arka bacaklar
	for s in [-1.0, 1.0]:
		_part(vis, _cone(0.3, 0.4, 1.6), Vector3(s * 0.6, 0.85, 1.4), m_body)
		_part(vis, _sph(0.3), Vector3(s * 0.6, 0.12, 1.3), claw, Vector3(1.0, 0.5, 1.3))
	# ön bacaklar = kollar (pençe animasyonu)
	arm_l = _leg(-1.0, claw)
	arm_r = _leg(1.0, claw)
	# kuyruk
	var tail := _part(vis, _cone(0.08, 0.05, 2.0), Vector3(0, 2.4, 2.4), m_body)
	tail.rotation.x = 1.0
	_part(vis, _sph(0.22), Vector3(0, 3.2, 3.1), m_mane)
	# baş ve dev yele
	head = Node3D.new()
	head.position = Vector3(0, 3.0, -1.5)
	vis.add_child(head)
	for ring in 2:
		var n := 14 if ring == 0 else 10
		var rr := 0.95 if ring == 0 else 0.6
		for i in n:
			var a := TAU * (float(i) + 0.5 * float(ring)) / float(n)
			var sp := _part(head, _cone(0.32, 0.0, 1.1 - 0.3 * float(ring)), Vector3(cos(a) * rr, sin(a) * rr, 0.35 - 0.15 * float(ring)), m_mane)
			sp.rotation = Vector3(0, 0, a - PI * 0.5)
			sp.rotate_object_local(Vector3.RIGHT, -0.35)
	_part(head, _sph(0.85), Vector3(0, 0, 0.2), m_mane, Vector3(1.1, 1.1, 0.9))
	_part(head, _sph(0.62), Vector3(0, -0.05, -0.35), m_body, Vector3(1.0, 1.0, 1.1))
	_part(head, _sph(0.3), Vector3(0, -0.25, -0.9), m_body, Vector3(1.1, 0.8, 1.0))
	_part(head, _sph(0.1), Vector3(0, -0.1, -1.18), _m(Color(0.25, 0.12, 0.1)))
	for s in [-1.0, 1.0]:
		_part(head, _sph(0.1), Vector3(s * 0.24, 0.12, -0.85), m_eye, Vector3(1.4, 0.7, 1.0))
	# altın taç
	for i in 7:
		var a := -0.9 + float(i) * 0.3
		var sp2 := _part(head, _cone(0.1, 0.0, 0.45 + (0.15 if i == 3 else 0.0)), Vector3(sin(a) * 0.5, 0.75, -0.2 + cos(a) * 0.1), m_horn)
		sp2.rotation.z = -a * 0.4

	mane = CPUParticles3D.new()
	mane.amount = 30
	mane.lifetime = 1.2
	var em := SphereMesh.new()
	em.radius = 0.07
	em.height = 0.14
	mane.mesh = em
	mane.material_override = Fx.emissive(Color(1.0, 0.65, 0.2), 4.0)
	mane.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	mane.emission_sphere_radius = 1.0
	mane.direction = Vector3.UP
	mane.spread = 30.0
	mane.gravity = Vector3(0, 2.0, 0)
	mane.initial_velocity_min = 0.3
	mane.initial_velocity_max = 1.0
	mane.position = Vector3(0, 0.2, 0.2)
	head.add_child(mane)
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.75, 0.4)
	l.light_energy = 1.8
	l.omni_range = 7.0
	l.position = Vector3(0, 3.5, -1.0)
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


func _leg(side: float, claw: Material) -> Node3D:
	var sh := Node3D.new()
	sh.position = Vector3(side * 0.75, 2.0, -1.1)
	vis.add_child(sh)
	_part(sh, _cone(0.32, 0.38, 1.9), Vector3(0, -1.0, 0), m_body)
	_part(sh, _sph(0.36), Vector3(0, -1.9, -0.15), claw, Vector3(1.0, 0.5, 1.4))
	for k in 3:
		var c := _part(sh, _cone(0.06, 0.0, 0.3), Vector3((float(k) - 1.0) * 0.16, -1.95, -0.6), claw)
		c.rotation.x = -PI * 0.5
	return sh


func _place_tele() -> void:
	if atk == "pounce":
		tele.global_transform = Transform3D(Basis.IDENTITY, Vector3(_leap_to.x, 0.07, _leap_to.z))
		return
	var b := Basis.looking_at(_aim_dir, Vector3.UP) if _aim_dir.length() > 0.1 else Basis.IDENTITY
	if atk == "roar":
		b = Basis.IDENTITY
	tele.global_transform = Transform3D(b, Vector3(global_position.x, 0.07, global_position.z))


# ---------------------------------------------------------------- yapay zekâ

func _speed_mult() -> float:
	match phase:
		1:
			return 1.05
		2:
			return 1.18
	return 1.35


## Sürü: yaşayan her yavru +%15 hasar (en çok +%45)
func _pride() -> float:
	var n := 0
	for e in get_tree().get_nodes_in_group("enemies"):
		if e != self and not e.dead and e.get("kind") == "shade":
			n += 1
	return dmg_mult * (1.0 + 0.15 * float(mini(n, 3)))


func _windup_len() -> float:
	var k := windup_mult / _speed_mult()
	match atk:
		"maul":
			return (float(MAUL["windup"]) if _mauls_left >= 2 else 0.32) * k
		"pounce":
			return 0.75 * k
		"roar":
			return 0.85 * k
		"zenith":
			return 0.6 * k
		"corona":
			return 1.0 * k
	return 0.6


func _recover_len() -> float:
	match atk:
		"maul":
			return float(MAUL["recover"]) / _speed_mult()
		"pounce":
			return 0.9      # indikten sonra toparlanır: vurma fırsatı
		"roar":
			return 0.7
		"corona":
			return 0.9
	return 0.6


func _pick(dist: float, dir_to: Vector3) -> void:
	var opts: Array = []
	if float(_cd["maul"]) <= 0.0 and dist < 3.8:
		opts.append_array(["maul", "maul", "maul"])
	if float(_cd["pounce"]) <= 0.0 and dist > 3.5:
		opts.append_array(["pounce", "pounce"])
	if float(_cd["roar"]) <= 0.0 and dist < 5.0:
		opts.append("roar")
	if phase >= 2 and float(_cd["zenith"]) <= 0.0:
		opts.append("zenith")
	if phase >= 3 and float(_cd["corona"]) <= 0.0:
		opts.append("corona")
	if opts.is_empty():
		# uzaktaysa yaklaşır; yine de sıçrayış hazırsa onu kullanır
		return
	atk = String(opts[randi() % opts.size()])
	_aim_dir = dir_to
	if atk == "maul":
		_mauls_left = 2
	if atk == "pounce" and hero != null and is_instance_valid(hero):
		_leap_from = global_position
		var t: Vector3 = hero.global_position
		var fl := Vector2(t.x, t.z)
		if fl.length() > _bounds:
			fl = fl.normalized() * _bounds
		_leap_to = Vector3(fl.x, 0.0, fl.y)
	_set_state("windup")


func _set_state(s: String) -> void:
	state = s
	_st = 0.0
	match s:
		"windup":
			tele.visible = false
			match atk:
				"maul":
					var arc := deg_to_rad(float(MAUL["arc"]) + (40.0 if _mauls_left == 0 else 0.0))
					_show_tele(_fan_mesh(arc, float(MAUL["reach"])), PARRY_COL)
				"pounce":
					_show_tele(_fan_mesh(TAU, 3.0), DANGER_COL)
				"roar":
					_show_tele(_fan_mesh(TAU, 5.5), DANGER_COL)
			Sfx.play("bossroar", -4.0 if atk == "roar" else -11.0, 0.08, 0, 0.75)
		"act":
			_done = false
			if atk != "pounce":
				tele.visible = false
			Sfx.play("dash", -6.0, 0.1, 0, 0.6)
		"recover":
			tele.visible = false
			_global_cd = randf_range(0.2, 0.5) / _speed_mult()
			match atk:
				"maul":
					_cd["maul"] = 1.2
				"pounce":
					_cd["pounce"] = 4.0
				"roar":
					_cd["roar"] = 8.0
				"zenith":
					_cd["zenith"] = 14.0
				"corona":
					_cd["corona"] = 11.0
		_:
			tele.visible = false


func _act(delta: float, sm: float) -> Vector3:
	match atk:
		"maul":
			if not _done and _st >= 0.05:
				_done = true
				_maul_hit()
			if _st >= float(MAUL["act"]) and state == "act":
				if _mauls_left > 0:
					_mauls_left -= 1
					if hero != null and is_instance_valid(hero):
						var nd: Vector3 = hero.global_position - global_position
						nd.y = 0.0
						if nd.length() > 0.3:
							_aim_dir = nd.normalized()
					_set_state("windup")
				else:
					_set_state("recover")
			return _aim_dir * 7.0
		"pounce":
			var dur := 0.55 / sm
			var k := clampf(_st / dur, 0.0, 1.0)
			var p := _leap_from.lerp(_leap_to, k)
			global_position = Vector3(p.x, 0.0, p.z)
			vis.position.y = sin(k * PI) * 3.5
			_face = (_leap_to - _leap_from).normalized() if _leap_to.distance_to(_leap_from) > 0.3 else _face
			if k >= 1.0 and not _done:
				_done = true
				vis.position.y = 0.0
				tele.visible = false
				_area_hit(_leap_to, 3.0, 28.0 * _pride())
				_set_state("recover")
			return Vector3.ZERO
		"roar":
			if not _done:
				_done = true
				var ring := SlashFx.make(0.0, TAU, 0.6, 5.5, SUN_COL, 0.4)
				get_parent().add_child(ring)
				ring.global_transform = Transform3D(Basis.IDENTITY, global_position + Vector3(0, 0.4, 0))
				Fx.shake(0.5)
				Sfx.play("bossroar", 0.0, 0.0, 0, 0.6)
				if hero != null and is_instance_valid(hero) and not hero.dead:
					var d: Vector3 = hero.global_position - global_position
					d.y = 0.0
					if d.length() <= 5.8:
						var res: String = hero.take_damage(14.0 * _pride(), d.normalized() if d.length() > 0.05 else _face, false)
						if res == "hit":
							hero.velocity = d.normalized() * 16.0
							hero.apply_slow(0.5, 1.8)
			if _st >= 0.25:
				_set_state("recover")
		"zenith":
			if not _done:
				_done = true
				var z := Zenith.new()
				z.hero = hero
				z.bounds = _bounds
				z.dmg = 30.0 * dmg_mult
				get_parent().add_child(z)
				Fx.flash_light(Vector3(0, 6, 0), SUN_COL, 6.0, 30.0, 0.6)
			if _st >= 0.3:
				_set_state("recover")
		"corona":
			if not _done:
				_done = true
				var c := Corona.new()
				c.boss = self
				c.hero = hero
				c.dmg = 16.0 * dmg_mult
				c.spin = (1.0 if randf() < 0.5 else -1.0) * 1.6
				get_parent().add_child(c)
			if _st >= 4.6:
				_set_state("recover")
	return Vector3.ZERO


func _maul_hit() -> void:
	var reach := float(MAUL["reach"])
	var arc := deg_to_rad(float(MAUL["arc"]) + (40.0 if _mauls_left == 0 else 0.0))
	var fx := SlashFx.make(-arc * 0.5, arc * 0.5, 0.7, reach, PARRY_COL, 0.2)
	get_parent().add_child(fx)
	fx.global_transform = Transform3D(Basis.looking_at(_aim_dir, Vector3.UP), global_position + Vector3(0, 1.6, 0))
	Sfx.play("slash", -6.0, 0.1, 0, 0.8)
	if hero == null or not is_instance_valid(hero) or hero.dead:
		return
	var to: Vector3 = hero.global_position - global_position
	to.y = 0.0
	var dist := to.length()
	if dist > reach + 0.4:
		return
	if dist > 0.3 and _aim_dir.angle_to(to / dist) > arc * 0.5:
		return
	var dm := float(MAUL["dmg"]) * (1.4 if _mauls_left == 0 else 1.0)
	var res: String = hero.take_damage(dm * _pride(), to.normalized() if dist > 0.05 else _aim_dir, true)
	if res == "parried":
		_mauls_left = 0
		stun(2.2, true)
		_knock = -_aim_dir * 3.0


# ---------------------------------------------------------------- hasar ve evreler

func stun(sec: float, parried := false) -> void:
	_mauls_left = 0
	if state == "act" and atk == "pounce":
		return     # havadayken sersemlemez
	vis.position.y = 0.0
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
	if state == "act" and atk == "pounce":
		vis.position.y = 0.0
	phase = p
	_mauls_left = 0
	tele.visible = false
	_set_state("roar")
	Fx.shake(0.8)
	Fx.flash_light(global_position + Vector3(0, 3, 0), SUN_COL, 10.0, 16.0, 0.8)
	Sfx.play("bossroar", 0.0, 0.0, 0, 0.5)
	Sfx.play("bruteroar", -4.0, 0.0, 0, 0.55)
	var ring := SlashFx.make(0.0, TAU, 0.5, 7.0, SUN_COL, 0.5)
	get_parent().add_child(ring)
	ring.global_transform = Transform3D(Basis.IDENTITY, global_position + Vector3(0, 0.3, 0))
	if hero != null and is_instance_valid(hero) and not hero.dead:
		var d: Vector3 = hero.global_position - global_position
		d.y = 0.0
		if d.length() < 4.5:
			hero.velocity = d.normalized() * 15.0
	mane.amount = 30 if p == 1 else (60 if p == 2 else 100)
	m_mane.emission_energy_multiplier = 0.6 + 0.6 * float(p - 1)
	m_eye.emission_energy_multiplier = 8.0
	if p == 2:
		_cd["zenith"] = 0.5
		hint.emit("THE ZENITH", tr("Hide in the shadows when the sun burns"))
		summon.emit(["shade", "shade", "caster"])
	elif p == 3:
		hint.emit("THE PRIDE", tr("Every cub makes the King stronger"))
		summon.emit(["shade", "shade", "leaper"])
	phase_changed.emit(p)


# ---------------------------------------------------------------- animasyon

func _animate(delta: float) -> void:
	body_root.rotation.y = lerp_angle(body_root.rotation.y, atan2(-_face.x, -_face.z), minf(9.0 * delta, 1.0))
	var lean := 0.0
	var paw_l := 0.0
	var paw_r := 0.0
	var head_up := 0.0
	var glow := 5.0
	match state:
		"windup":
			var k := clampf(_st / _windup_len(), 0.0, 1.0)
			match atk:
				"maul":
					# sırayla sol / sağ pençeyi kaldırır
					if _mauls_left % 2 == 0:
						paw_l = 1.4 * k
					else:
						paw_r = 1.4 * k
					lean = -0.1 * k
				"pounce":
					lean = 0.25 * k
					vis.position.y = -0.4 * k
				"roar", "zenith", "corona":
					head_up = -0.5 * k
					lean = -0.15 * k
			glow = 5.0 + 12.0 * k
		"act":
			match atk:
				"maul":
					if _mauls_left % 2 == 0:
						paw_l = -0.5
					else:
						paw_r = -0.5
					lean = 0.15
				"pounce":
					paw_l = 1.0
					paw_r = 1.0
					lean = -0.2
				_:
					head_up = -0.6
			glow = 15.0
		"roar":
			head_up = -0.7
			lean = -0.2
			glow = 18.0
		"stun":
			lean = 0.3
			head_up = 0.3
			glow = 1.5
	if state != "intro" and not (state == "act" and atk == "pounce") and not (state == "windup" and atk == "pounce"):
		vis.position.y = lerpf(vis.position.y, 0.0, minf(10.0 * delta, 1.0))
	vis.rotation.x = lerpf(vis.rotation.x, lean, minf(10.0 * delta, 1.0))
	arm_l.rotation.x = lerpf(arm_l.rotation.x, paw_l, minf(14.0 * delta, 1.0))
	arm_r.rotation.x = lerpf(arm_r.rotation.x, paw_r, minf(14.0 * delta, 1.0))
	head.rotation.x = lerpf(head.rotation.x, head_up, minf(10.0 * delta, 1.0))
	m_eye.emission_energy_multiplier = glow
	m_body.emission = Color(0.5, 0.25, 0.05).lerp(Color(1.0, 0.95, 0.85), _flash)
	m_body.emission_energy_multiplier = 0.25 + _flash * 3.0 + (0.4 if _burn_t > 0.0 else 0.0)


# ---------------------------------------------------------------- ZENİT: gölgeye saklan (evre 2+)

class Zenith extends Node3D:
	var hero = null
	var bounds := 10.0
	var dmg := 30.0
	var warn := 2.0
	var safe_r := 2.1
	var _t := 0.0
	var _safe: Array = []
	var _glare: MeshInstance3D
	var _gm: StandardMaterial3D
	var _fired := false

	func _ready() -> void:
		top_level = true
		global_position = Vector3.ZERO
		# arenayı kaplayan altın parıltı
		_glare = MeshInstance3D.new()
		var c := CylinderMesh.new()
		c.top_radius = bounds + 1.0
		c.bottom_radius = bounds + 1.0
		c.height = 0.02
		c.radial_segments = 64
		_glare.mesh = c
		_gm = StandardMaterial3D.new()
		_gm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_gm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_gm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		_gm.albedo_color = Color(1.0, 0.6, 0.15, 0.0)
		_glare.material_override = _gm
		_glare.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_glare.position.y = 0.05
		add_child(_glare)
		# gölge daireleri: biri kahramanın 4-6 m uzağında, ikisi rastgele
		var hp := Vector3.ZERO
		if hero != null and is_instance_valid(hero):
			hp = hero.global_position
		var a0 := randf() * TAU
		var pts: Array = [hp + Vector3(cos(a0), 0, sin(a0)) * randf_range(4.0, 6.0)]
		for i in 2:
			pts.append(Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized() * randf_range(2.0, bounds - 2.5))
		var sm := StandardMaterial3D.new()
		sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		sm.albedo_color = Color(0.08, 0.04, 0.2, 0.85)
		for p0 in pts:
			var p: Vector3 = p0
			var fl := Vector2(p.x, p.z)
			if fl.length() > bounds - safe_r * 0.5:
				fl = fl.normalized() * (bounds - safe_r * 0.5)
			p = Vector3(fl.x, 0.0, fl.y)
			_safe.append(p)
			var d := MeshInstance3D.new()
			var dc := CylinderMesh.new()
			dc.top_radius = safe_r
			dc.bottom_radius = safe_r
			dc.height = 0.03
			dc.radial_segments = 40
			d.mesh = dc
			d.material_override = sm
			d.position = p + Vector3(0, 0.08, 0)
			add_child(d)
			var rim = load("res://scripts/star_skills.gd").ring(safe_r, Color(0.7, 0.5, 1.0, 0.9))
			add_child(rim)
			rim.position = p + Vector3(0, 0.1, 0)
		Sfx.play("bossroar", -8.0, 0.0, 0, 1.4)

	func _physics_process(delta: float) -> void:
		_t += delta
		if _t < warn:
			_gm.albedo_color.a = 0.08 + 0.25 * (_t / warn) + 0.08 * sin(_t * 20.0)
		elif not _fired:
			_fired = true
			_gm.albedo_color.a = 0.8
			Fx.shake(0.6)
			Fx.flash_light(Vector3(0, 5, 0), Color(1.0, 0.75, 0.35), 12.0, 30.0, 0.4)
			Sfx.play("boom", -2.0, 0.0, 0, 0.7)
			if hero != null and is_instance_valid(hero) and not hero.dead:
				var inside := false
				for p in _safe:
					var d: Vector3 = hero.global_position - p
					d.y = 0.0
					if d.length() <= safe_r + 0.15:
						inside = true
				if not inside:
					hero.take_damage(dmg, Vector3.UP, false)
		else:
			_gm.albedo_color.a = maxf(0.8 - (_t - warn) * 2.5, 0.0)
			if _t > warn + 0.5:
				queue_free()


# ---------------------------------------------------------------- TAÇ ALEVİ: dönen alev kolları (evre 3)

class Corona extends Node3D:
	var boss = null
	var hero = null
	var dmg := 16.0
	var spin := 1.6
	var arms := 4
	var length := 11.0
	var warn := 0.9
	var life := 4.5
	var _t := 0.0
	var _hit_cd := 0.0
	var _mat: StandardMaterial3D

	func _ready() -> void:
		top_level = true
		_mat = StandardMaterial3D.new()
		_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		_mat.albedo_color = Color(1.0, 0.45, 0.12, 0.2)
		for i in arms:
			var m := MeshInstance3D.new()
			var b := BoxMesh.new()
			b.size = Vector3(0.9, 1.0, length)
			m.mesh = b
			m.material_override = _mat
			m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			var pv := Node3D.new()
			pv.rotation.y = TAU * float(i) / float(arms)
			add_child(pv)
			pv.add_child(m)
			m.position = Vector3(0, 0.5, -length * 0.5 - 1.2)

	func _physics_process(delta: float) -> void:
		_t += delta
		if boss == null or not is_instance_valid(boss) or boss.dead:
			queue_free()
			return
		global_position = Vector3(boss.global_position.x, 0.0, boss.global_position.z)
		var live := _t >= warn
		rotation.y += spin * delta * (1.0 if live else 0.15)
		_mat.albedo_color.a = (0.85 if live else 0.15 + 0.15 * sin(_t * 25.0)) * (1.0 - clampf((_t - life + 0.3) / 0.3, 0.0, 1.0))
		_hit_cd -= delta
		if live and _hit_cd <= 0.0 and hero != null and is_instance_valid(hero) and not hero.dead:
			var v: Vector3 = hero.global_position - global_position
			v.y = 0.0
			var r := v.length()
			if r > 1.0 and r < length + 1.5:
				for i in arms:
					var a := rotation.y + TAU * float(i) / float(arms)
					var ad := Vector3(-sin(a), 0, -cos(a))
					var side := absf(v.dot(Vector3(-ad.z, 0, ad.x)))
					if v.dot(ad) > 0.0 and side < 0.75:
						_hit_cd = 0.6
						hero.take_damage(dmg, Vector3(-ad.z, 0, ad.x) * signf(spin), false)
						break
		if _t >= life:
			queue_free()
