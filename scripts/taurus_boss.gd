extends "res://scripts/aries_boss.gd"
## BOĞA: Boğa Otlakları'nın bekçisi. Koç'tan farklı olarak yavaş, ağır ve yerinden oynamaz;
## dövüşü alanı kontrol etmek üzerine kuruludur.
##  1. evre (100-65%):
##    - BOYNUZ DARBESİ: altın uyarı, parry'lenir (2.4 sn sersemler)
##    - TOYNAK DEPREMİ: şaha kalkar; içten dışa 3 halka sırayla yerden fışkırır. Halkaların ARASI güvenli
##    - KAYA FIRLATMA: kocaman bir kaya söküp üstüne atar
##  2. evre (65-30%): + VENÜS GÜLLERİ: arenada 3 gül açar, yaşadıkça Boğa'yı iyileştirir (önce onları kes!)
##                    + ALDEBARAN'IN GÖZÜ: kızıl gözünden arenayı yay çizerek süpüren bir ışın (atılarak üstünden geç)
##  3. evre (<30%):   + HAYALET SÜRÜ: arenayı şeritler halinde ezip geçen boğa sürüsü; iki dalga, boş şeritlere kaç
##                    + kaya fırlatmada 3 kaya

const GORE := {"windup": 0.7, "act": 0.18, "recover": 0.65, "dmg": 26.0, "reach": 3.7, "arc": 115.0}
const BEAM_HALF := 0.98      # ışının süpürdüğü yayın yarısı (~56°)
const BEAM_TIME := 1.7

var _beam_sign := 1.0
var _held: MeshInstance3D
var _pleiades: Node3D
var m_hoof: StandardMaterial3D
var _roses_spawned := false


func _init() -> void:
	kind = "taurus"
	title = "TAURUS  ·  THE IMMOVABLE"
	max_hp = 2000.0
	hp = 2000.0
	radius = 1.6
	_cd = {"gore": 0.5, "quake": 2.5, "boulder": 1.5, "beam": 1.0, "stampede": 1.0}
	_global_cd = 1.2


# ---------------------------------------------------------------- görünüş: dört ayaklı dev boğa

func _build() -> void:
	m_body = _m(Color(0.16, 0.11, 0.07), 0.8)
	m_body.emission_enabled = true
	m_body.emission = Color(0.25, 0.55, 0.15)
	m_body.emission_energy_multiplier = 0.3
	var moss := _m(Color(0.22, 0.38, 0.12), 0.95)
	var gold := _m(Color(0.95, 0.78, 0.38), 0.3, 0.9)
	m_hoof = gold
	m_horn = _m(Color(0.9, 0.84, 0.7), 0.45, 0.2)
	m_horn.emission_enabled = true
	m_horn.emission = Color(0.9, 0.8, 0.5)
	m_horn.emission_energy_multiplier = 0.15
	m_eye = StandardMaterial3D.new()
	m_eye.albedo_color = Color.BLACK
	m_eye.emission_enabled = true
	m_eye.emission = Color(1.0, 0.18, 0.1)
	m_eye.emission_energy_multiplier = 5.0
	var petal := _m(Color(1.0, 0.55, 0.7), 0.6)
	petal.emission_enabled = true
	petal.emission = Color(1.0, 0.45, 0.6)
	petal.emission_energy_multiplier = 0.5

	body_root = Node3D.new()
	add_child(body_root)
	vis = Node3D.new()
	vis.scale = Vector3.ONE * 1.25
	body_root.add_child(vis)
	# gövde: geniş göğüs, kambur, yosunlu sırt
	_part(vis, _sph(1.0), Vector3(0, 1.75, 0.2), m_body, Vector3(1.05, 0.95, 1.6))
	_part(vis, _sph(0.85), Vector3(0, 2.15, -0.55), m_body, Vector3(1.15, 1.1, 1.0))   # kambur
	_part(vis, _sph(0.6), Vector3(0, 2.75, -0.25), moss, Vector3(1.4, 0.35, 2.0))
	_part(vis, _sph(0.45), Vector3(0.3, 2.55, 0.8), moss, Vector3(1.2, 0.3, 1.3))
	# altın burç sembolü böğürde (♉: daire + hilal)
	for s in [-1.0, 1.0]:
		var t := TorusMesh.new()
		t.inner_radius = 0.2
		t.outer_radius = 0.26
		var tm := _part(vis, t, Vector3(s * 1.02, 1.7, 0.25), gold)
		tm.rotation.z = PI * 0.5
	# bacaklar ve altın toynaklar
	for i in 4:
		var x := -0.62 if i % 2 == 0 else 0.62
		var z := -0.75 if i < 2 else 1.05
		_part(vis, _cone(0.26, 0.34, 1.2), Vector3(x, 0.75, z), m_body)
		_part(vis, _cone(0.3, 0.28, 0.22), Vector3(x, 0.11, z), gold)
	# kuyruk
	var tail := _part(vis, _cone(0.03, 0.07, 1.1), Vector3(0, 1.75, 1.95), m_body)
	tail.rotation.x = 0.4
	_part(vis, _sph(0.12), Vector3(0, 1.25, 2.15), moss)
	# baş: alçak, geniş alın, uzun ileri kıvrık boynuzlar
	head = Node3D.new()
	head.position = Vector3(0, 1.95, -1.55)
	vis.add_child(head)
	_part(head, _sph(0.55), Vector3.ZERO, m_body, Vector3(1.0, 0.9, 1.1))
	_part(head, _sph(0.4), Vector3(0, -0.3, -0.45), m_body, Vector3(0.95, 0.75, 0.9))
	var ring := TorusMesh.new()
	ring.inner_radius = 0.12
	ring.outer_radius = 0.16
	var rm := _part(head, ring, Vector3(0, -0.5, -0.72), gold)
	rm.rotation.x = 0.2
	# Aldebaran: sağ göz kocaman ve kızıl, sol göz sönük
	_part(head, _sph(0.12), Vector3(0.36, 0.12, -0.38), m_eye, Vector3(1.3, 0.9, 1.0))
	var dim := m_eye.duplicate() as StandardMaterial3D
	dim.emission_energy_multiplier = 1.5
	_part(head, _sph(0.08), Vector3(-0.36, 0.12, -0.38), dim, Vector3(1.3, 0.8, 1.0))
	for s in [-1.0, 1.0]:
		for k in 12:
			var u := float(k) / 11.0
			var p := Vector3(s * (0.45 + u * 1.15 - u * u * 0.35), 0.25 + u * 0.55 + u * u * 0.45, -u * 0.55 + u * u * 0.1)
			_part(head, _sph(lerpf(0.2, 0.05, u)), p, m_horn)
	# boyunda Venüs çiçek çelengi
	for i in 14:
		var a := TAU * float(i) / 14.0
		_part(vis, _sph(0.13), Vector3(cos(a) * 0.85, 1.85 + sin(a) * 0.75, -1.05), petal)
	# omzunun üstünde dönen Ülker (yedi yıldız)
	_pleiades = Node3D.new()
	_pleiades.position = Vector3(0, 3.6, -0.4)
	vis.add_child(_pleiades)
	var star: StandardMaterial3D = Fx.emissive(Color(0.75, 0.9, 1.0), 7.0)
	for i in 7:
		var a := TAU * float(i) / 7.0
		_part(_pleiades, _sph(0.09), Vector3(cos(a) * 0.7, sin(float(i) * 2.1) * 0.18, sin(a) * 0.7), star)
	# base sınıfın beklediği düğümler
	arm_l = Node3D.new()
	arm_r = Node3D.new()
	vis.add_child(arm_l)
	vis.add_child(arm_r)
	# toz ve polen bulutu (evre ilerledikçe yoğunlaşır)
	mane = CPUParticles3D.new()
	mane.amount = 24
	mane.lifetime = 1.6
	var pm := SphereMesh.new()
	pm.radius = 0.06
	pm.height = 0.12
	mane.mesh = pm
	var fm := StandardMaterial3D.new()
	fm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fm.albedo_color = Color(0.85, 1.0, 0.55)
	mane.material_override = fm
	mane.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	mane.emission_box_extents = Vector3(1.0, 0.2, 1.6)
	mane.direction = Vector3.UP
	mane.spread = 40.0
	mane.gravity = Vector3(0, 0.6, 0)
	mane.initial_velocity_min = 0.3
	mane.initial_velocity_max = 0.9
	mane.position = Vector3(0, 0.3, 0)
	vis.add_child(mane)
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.35, 0.25)
	l.light_energy = 1.5
	l.omni_range = 6.0
	l.position = Vector3(0.6, 2.4, -2.4)
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
	var d := _aim_dir
	if atk == "beam":
		d = _aim_dir.rotated(Vector3.UP, -_beam_sign * BEAM_HALF)
	var b := Basis.looking_at(d, Vector3.UP) if d.length() > 0.1 else Basis.IDENTITY
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
		"gore":
			return float(GORE["windup"]) * k
		"quake":
			return 1.0 * k
		"boulder":
			return 0.85 * k
		"beam":
			return 1.1 * k
		"stampede":
			return 0.9 * k
	return 0.6


func _recover_len() -> float:
	match atk:
		"gore":
			return float(GORE["recover"]) / _speed_mult()
		"quake":
			return 0.8
		"beam":
			return 0.9     # ışından sonra yorulur: vurma fırsatı
		"stampede":
			return 0.6
	return 0.6


func _pick(dist: float, dir_to: Vector3) -> void:
	var opts: Array = []
	if float(_cd["gore"]) <= 0.0 and dist < 3.8:
		opts.append_array(["gore", "gore", "gore"])
	if float(_cd["quake"]) <= 0.0 and dist < 8.0:
		opts.append("quake")
	if float(_cd["boulder"]) <= 0.0 and dist > 3.5:
		opts.append_array(["boulder", "boulder"])
	if phase >= 2 and float(_cd["beam"]) <= 0.0:
		opts.append("beam")
	if phase >= 3 and float(_cd["stampede"]) <= 0.0:
		opts.append("stampede")
	if opts.is_empty():
		return
	atk = String(opts[randi() % opts.size()])
	_aim_dir = dir_to
	_beam_sign = 1.0 if randf() < 0.5 else -1.0
	_set_state("windup")


func _set_state(s: String) -> void:
	state = s
	_st = 0.0
	match s:
		"windup":
			tele.visible = false
			match atk:
				"gore":
					_show_tele(_fan_mesh(deg_to_rad(float(GORE["arc"])), float(GORE["reach"])), PARRY_COL)
				"beam":
					_show_tele(_line_mesh(15.0, 1.0), DANGER_COL)
				"quake":
					var q := QuakeRings.new()
					q.center = Vector3(global_position.x, 0.0, global_position.z)
					q.first_delay = _windup_len() + 0.1
					q.dmg = 22.0 * dmg_mult
					q.hero = hero
					get_parent().add_child(q)
				"boulder":
					_hold_rock()
			Sfx.play("bossroar", -5.0 if atk != "gore" else -10.0, 0.08, 0, 0.5)
		"act":
			_done = false
			if atk != "beam":
				tele.visible = false
			Sfx.play("dash", -6.0, 0.1, 0, 0.5)
		"recover":
			tele.visible = false
			_global_cd = randf_range(0.25, 0.6) / _speed_mult()
			match atk:
				"gore":
					_cd["gore"] = 1.3
				"quake":
					_cd["quake"] = 6.5 if phase < 3 else 5.0
				"boulder":
					_cd["boulder"] = 4.0 if phase < 3 else 3.2
				"beam":
					_cd["beam"] = 9.0
				"stampede":
					_cd["stampede"] = 11.0
		_:
			tele.visible = false
			if _held != null:
				_held.queue_free()
				_held = null


func _act(delta: float, _sm: float) -> Vector3:
	match atk:
		"gore":
			if not _done and _st >= 0.07:
				_done = true
				_gore_hit()
			if _st >= float(GORE["act"]):
				_set_state("recover")
			return _aim_dir * 5.0
		"quake":
			if not _done:
				_done = true
				Fx.shake(0.55)
				Sfx.play("boom", -6.0, 0.0, 0, 0.7)
				var r := SlashFx.make(0.0, TAU, 0.4, 2.5, Color(0.8, 0.65, 0.35), 0.35)
				get_parent().add_child(r)
				r.global_transform = Transform3D(Basis.IDENTITY, global_position + Vector3(0, 0.3, 0))
			if _st >= 0.3:
				_set_state("recover")
		"boulder":
			if not _done:
				_done = true
				_throw_rocks()
			if _st >= 0.3:
				_set_state("recover")
		"beam":
			if not _done:
				_done = true
				tele.visible = false
				var bm := Beam.new()
				bm.boss = self
				bm.start_dir = _aim_dir.rotated(Vector3.UP, -_beam_sign * BEAM_HALF)
				bm.sweep = _beam_sign * BEAM_HALF * 2.0
				bm.dur = BEAM_TIME
				bm.dmg = 18.0 * dmg_mult
				bm.hero = hero
				get_parent().add_child(bm)
				Sfx.play("boom", -8.0, 0.0, 0, 2.2)
			var k := clampf(_st / BEAM_TIME, 0.0, 1.0)
			_face = _aim_dir.rotated(Vector3.UP, -_beam_sign * BEAM_HALF + _beam_sign * BEAM_HALF * 2.0 * k)
			if _st >= BEAM_TIME:
				_set_state("recover")
		"stampede":
			if not _done:
				_done = true
				var sp := Stampede.new()
				sp.hero = hero
				sp.dmg = 24.0 * dmg_mult
				sp.bounds = _bounds + 1.0
				get_parent().add_child(sp)
				Fx.shake(0.4)
			if _st >= 0.4:
				_set_state("recover")
	return Vector3.ZERO


func _gore_hit() -> void:
	var reach := float(GORE["reach"])
	var arc := deg_to_rad(float(GORE["arc"]))
	var fx := SlashFx.make(-arc * 0.5, arc * 0.5, 0.8, reach, PARRY_COL, 0.22)
	get_parent().add_child(fx)
	fx.global_transform = Transform3D(Basis.looking_at(_aim_dir, Vector3.UP), global_position + Vector3(0, 1.6, 0))
	Sfx.play("crush", -6.0, 0.1, 0, 0.7)
	if hero == null or not is_instance_valid(hero) or hero.dead:
		return
	var to: Vector3 = hero.global_position - global_position
	to.y = 0.0
	var dist := to.length()
	if dist > reach + 0.4:
		return
	if dist > 0.3 and _aim_dir.angle_to(to / dist) > arc * 0.5:
		return
	var res: String = hero.take_damage(float(GORE["dmg"]) * dmg_mult, to.normalized() if dist > 0.05 else _aim_dir, true)
	if res == "parried":
		stun(2.4, true)
		_knock = -_aim_dir * 3.0
	elif res == "hit":
		hero.velocity = (to.normalized() if dist > 0.05 else _aim_dir) * 12.0


func _hold_rock() -> void:
	if _held != null:
		_held.queue_free()
	_held = MeshInstance3D.new()
	_held.mesh = _sph(0.75)
	_held.material_override = _m(Color(0.42, 0.4, 0.36), 0.95)
	_held.scale = Vector3(1.1, 0.85, 1.0)
	_held.position = Vector3(0, 3.6, -1.9)
	vis.add_child(_held)


func _throw_rocks() -> void:
	if _held != null:
		_held.queue_free()
		_held = null
	if hero == null or not is_instance_valid(hero):
		return
	var targets: Array = [hero.global_position]
	if phase >= 3:
		for i in 2:
			targets.append(hero.global_position + Vector3(randf_range(-3.5, 3.5), 0, randf_range(-3.5, 3.5)))
	for tp in targets:
		var t: Vector3 = tp
		var fl := Vector2(t.x, t.z)
		if fl.length() > _bounds:
			fl = fl.normalized() * _bounds
		var bd := Boulder.new()
		bd.from = global_position + Vector3(0, 4.2, 0) + _face * 2.0
		bd.to = Vector3(fl.x, 0.0, fl.y)
		bd.dmg = 24.0 * dmg_mult
		bd.hero = hero
		get_parent().add_child(bd)


# ---------------------------------------------------------------- hasar ve evreler

func _damage(d: float) -> void:
	hp -= d
	if hp <= 0.0:
		_die()
		return
	if phase == 1 and hp < max_hp * 0.65:
		_enter_phase(2)
	elif phase == 2 and hp < max_hp * 0.3:
		_enter_phase(3)


func heal_boss(amount: float) -> void:
	if dead:
		return
	hp = minf(hp + amount, max_hp)


func _enter_phase(p: int) -> void:
	phase = p
	tele.visible = false
	if _held != null:
		_held.queue_free()
		_held = null
	_set_state("roar")
	Fx.shake(0.8)
	Fx.flash_light(global_position + Vector3(0, 3, 0), Color(0.6, 1.0, 0.4), 10.0, 16.0, 0.8)
	Sfx.play("bossroar", 0.0, 0.0, 0, 0.45)
	Sfx.play("bruteroar", -4.0, 0.0, 0, 0.5)
	var ring := SlashFx.make(0.0, TAU, 0.5, 7.0, Color(0.7, 1.0, 0.45), 0.5)
	get_parent().add_child(ring)
	ring.global_transform = Transform3D(Basis.IDENTITY, global_position + Vector3(0, 0.3, 0))
	if hero != null and is_instance_valid(hero) and not hero.dead:
		var d: Vector3 = hero.global_position - global_position
		d.y = 0.0
		if d.length() < 4.5:
			hero.velocity = d.normalized() * 15.0
	mane.amount = 24 if p == 1 else (50 if p == 2 else 90)
	m_eye.emission_energy_multiplier = 8.0
	if p == 2:
		_spawn_roses(3)
		summon.emit(["shade", "caster"])
	elif p == 3:
		_spawn_roses(2)
		summon.emit(["leaper", "shade"])
	phase_changed.emit(p)


## Venüs Gülleri: yaşadıkları sürece Boğa'yı iyileştirir
func _spawn_roses(n: int) -> void:
	var base_a := randf() * TAU
	for i in n:
		var a := base_a + TAU * float(i) / float(n)
		var r := Rose.new()
		r.boss = self
		r.max_hp = 140.0 * (max_hp / 2000.0)
		r.heal_rate = max_hp * 0.006   # gül başına saniyede %0.6
		get_parent().add_child(r)
		r.global_position = Vector3(cos(a), 0, sin(a)) * minf(_bounds - 1.5, 7.5)


# ---------------------------------------------------------------- animasyon

func _animate(delta: float) -> void:
	body_root.rotation.y = lerp_angle(body_root.rotation.y, atan2(-_face.x, -_face.z), minf(6.0 * delta, 1.0))
	var pitch := 0.0
	var lift := 0.0
	var head_x := 0.0
	var glow := 5.0
	match state:
		"windup":
			var k := clampf(_st / _windup_len(), 0.0, 1.0)
			match atk:
				"quake", "stampede":
					pitch = -0.45 * k      # şaha kalkar
					lift = 0.6 * k
				"gore":
					head_x = 0.45 * k      # başını eğer, boynuzları öne
				"beam":
					head_x = -0.15
					glow = 5.0 + 20.0 * k
				"boulder":
					pitch = -0.15 * k
					head_x = -0.4 * k
		"act":
			match atk:
				"gore":
					head_x = -0.6
				"beam":
					glow = 26.0
				"quake", "stampede":
					pitch = 0.12
		"roar":
			pitch = -0.35
			lift = 0.4
			head_x = -0.5
			glow = 14.0
		"stun":
			head_x = 0.5
			pitch = 0.1
			glow = 1.5
	vis.rotation.x = lerpf(vis.rotation.x, pitch, minf(10.0 * delta, 1.0))
	vis.position.y = lerpf(vis.position.y, lift, minf(10.0 * delta, 1.0))
	head.rotation.x = lerpf(head.rotation.x, head_x, minf(10.0 * delta, 1.0))
	m_eye.emission_energy_multiplier = lerpf(m_eye.emission_energy_multiplier, glow, minf(8.0 * delta, 1.0))
	m_body.emission = Color(0.25, 0.55, 0.15).lerp(Color(1.0, 0.95, 0.85), _flash)
	m_body.emission_energy_multiplier = 0.3 + _flash * 3.0 + (0.4 if _burn_t > 0.0 else 0.0)
	_pleiades.rotation.y += delta * (0.8 + float(phase) * 0.4)


# ================================================================ saldırı düğümleri

static func _add_mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.albedo_color = c
	return m


static func _annulus(r_in: float, r_out: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := 64
	for i in n:
		var a0 := TAU * float(i) / float(n)
		var a1 := TAU * float(i + 1) / float(n)
		var p0 := Vector3(cos(a0), 0, sin(a0))
		var p1 := Vector3(cos(a1), 0, sin(a1))
		for v in [p0 * r_in, p0 * r_out, p1 * r_out, p0 * r_in, p1 * r_out, p1 * r_in]:
			st.add_vertex(v)
	return st.commit()


## TOYNAK DEPREMİ: içten dışa üç halka sırayla patlar; aralar güvenli
class QuakeRings extends Node3D:
	var center := Vector3.ZERO
	var first_delay := 1.0
	var step := 0.55
	var dmg := 22.0
	var hero = null
	var bands := [[1.0, 3.3], [4.8, 7.0], [8.5, 10.8]]
	var _t := 0.0
	var _rings: Array = []     # [mesh, mat, erupt_t, done]
	var _rock: StandardMaterial3D
	var _hit := false

	func _ready() -> void:
		top_level = true
		global_position = center
		_rock = StandardMaterial3D.new()
		_rock.albedo_color = Color(0.45, 0.4, 0.33)
		_rock.roughness = 0.95
		var lib = load("res://scripts/taurus_boss.gd")
		for i in bands.size():
			var b: Array = bands[i]
			var mi := MeshInstance3D.new()
			mi.mesh = lib._annulus(float(b[0]), float(b[1]))
			var m: StandardMaterial3D = lib._add_mat(Color(1.0, 0.25, 0.1, 0.1))
			mi.material_override = m
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			mi.position.y = 0.06
			add_child(mi)
			_rings.append([mi, m, first_delay + step * float(i), false])

	func _physics_process(delta: float) -> void:
		_t += delta
		var all_done := true
		for r in _rings:
			var m: StandardMaterial3D = r[1]
			var et: float = r[2]
			if bool(r[3]):
				m.albedo_color.a = maxf(m.albedo_color.a - delta * 1.5, 0.0)
				continue
			all_done = false
			var k := clampf(_t / et, 0.0, 1.0)
			m.albedo_color.a = 0.12 + 0.5 * k + (0.15 * sin(_t * 30.0) if k > 0.7 else 0.0)
			if _t >= et:
				r[3] = true
				_erupt(_rings.find(r))
		if all_done and _t > first_delay + step * 3.0 + 1.0:
			queue_free()

	func _erupt(i: int) -> void:
		var b: Array = bands[i]
		var r_in := float(b[0])
		var r_out := float(b[1])
		var rm := (r_in + r_out) * 0.5
		var n := int(TAU * rm / 1.1)
		for k in n:
			var a := TAU * float(k) / float(n) + randf() * 0.2
			var cm := CylinderMesh.new()
			cm.top_radius = 0.0
			cm.bottom_radius = randf_range(0.3, 0.5)
			cm.height = randf_range(1.0, 1.7)
			cm.radial_segments = 5
			var mi := MeshInstance3D.new()
			mi.mesh = cm
			mi.material_override = _rock
			var rr := randf_range(r_in + 0.3, r_out - 0.3)
			mi.position = Vector3(cos(a) * rr, cm.height * 0.5 - 0.1, sin(a) * rr)
			mi.rotation = Vector3(randf_range(-0.3, 0.3), randf() * TAU, randf_range(-0.3, 0.3))
			mi.scale = Vector3(1, 0.01, 1)
			add_child(mi)
			var tw := mi.create_tween()
			tw.tween_property(mi, "scale", Vector3.ONE, 0.1)
			tw.tween_interval(0.5)
			tw.tween_property(mi, "scale", Vector3(1, 0.01, 1), 0.3)
		Fx.shake(0.35)
		Sfx.play("crush", -4.0, 0.1, 0, 0.6 + 0.15 * float(i))
		if _hit or hero == null or not is_instance_valid(hero) or hero.dead:
			return
		var v: Vector3 = hero.global_position - center
		v.y = 0.0
		var d := v.length()
		if d >= r_in - 0.3 and d <= r_out + 0.3:
			var res: String = hero.take_damage(dmg, v.normalized() if d > 0.05 else Vector3.FORWARD, false)
			if res == "hit":
				_hit = true


## Kaya: kavisle uçar, düştüğü yerde parçalanır
class Boulder extends Node3D:
	var from := Vector3.ZERO
	var to := Vector3.ZERO
	var dmg := 24.0
	var radius := 2.0
	var flight := 0.95
	var hero = null
	var _t := 0.0
	var _rock: MeshInstance3D
	var _ring: MeshInstance3D
	var _landed := false

	func _ready() -> void:
		add_to_group("enemy_shot")
		top_level = true
		_ring = load("res://scripts/star_skills.gd").ring(radius, Color(1.0, 0.2, 0.1, 0.9))
		add_child(_ring)
		_ring.global_position = to + Vector3(0, 0.06, 0)
		_rock = MeshInstance3D.new()
		var s := SphereMesh.new()
		s.radius = 0.75
		s.height = 1.5
		s.radial_segments = 10
		s.rings = 6
		_rock.mesh = s
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(0.42, 0.4, 0.36)
		m.roughness = 0.95
		_rock.material_override = m
		_rock.scale = Vector3(1.1, 0.85, 1.0)
		add_child(_rock)
		_rock.global_position = from

	func _physics_process(delta: float) -> void:
		_t += delta
		if _landed:
			if _t > flight + 0.6:
				_rock.scale = _rock.scale.move_toward(Vector3(0.01, 0.01, 0.01), delta * 3.0)
			if _t > flight + 1.0:
				queue_free()
			return
		var k := clampf(_t / flight, 0.0, 1.0)
		var p := from.lerp(to + Vector3(0, 0.6, 0), k)
		p.y += sin(k * PI) * 4.5
		_rock.global_position = p
		_rock.rotation += Vector3(6.0, 3.0, 0) * delta
		_ring.scale = Vector3(0.3 + 0.7 * k, 0.1, 0.3 + 0.7 * k)
		if k >= 1.0:
			_landed = true
			_ring.visible = false
			var ex = load("res://scripts/slash_fx.gd").make(0.0, TAU, 0.3, radius, Color(0.75, 0.6, 0.4), 0.35)
			get_parent().add_child(ex)
			ex.global_transform = Transform3D(Basis.IDENTITY, to + Vector3(0, 0.4, 0))
			Fx.shake(0.45)
			Sfx.play("crush", -3.0, 0.1, 0, 0.6)
			var dm: StandardMaterial3D = Fx.mat(Color(0.45, 0.4, 0.33), 0.0, 0.95)
			var bx := BoxMesh.new()
			bx.size = Vector3(0.18, 0.14, 0.18)
			Fx._burst(to + Vector3(0, 0.5, 0), Vector3.UP, 14, dm, bx, 3.0, 7.0, 60.0, -16.0, 0.8, 0.6, 1.3, true)
			if hero != null and is_instance_valid(hero) and not hero.dead:
				var v: Vector3 = hero.global_position - to
				v.y = 0.0
				if v.length() <= radius + 0.25:
					hero.take_damage(dmg, v.normalized() if v.length() > 0.05 else Vector3.FORWARD, false)


## ALDEBARAN'IN GÖZÜ: boğanın kızıl gözünden çıkan, yay çizerek süpüren ışın
class Beam extends Node3D:
	var boss = null
	var hero = null
	var start_dir := Vector3.FORWARD
	var sweep := 1.9
	var dur := 1.7
	var dmg := 18.0
	var length := 15.0
	var _t := 0.0
	var _tick := 0.0
	var _outer: MeshInstance3D
	var _core: MeshInstance3D
	var _light: OmniLight3D

	func _ready() -> void:
		top_level = true
		var lib = load("res://scripts/taurus_boss.gd")
		_outer = MeshInstance3D.new()
		var b1 := BoxMesh.new()
		b1.size = Vector3(1.1, 0.7, length)
		_outer.mesh = b1
		_outer.material_override = lib._add_mat(Color(1.0, 0.15, 0.08, 0.45))
		_outer.position = Vector3(0, 1.0, -length * 0.5)
		add_child(_outer)
		_core = MeshInstance3D.new()
		var b2 := BoxMesh.new()
		b2.size = Vector3(0.35, 0.3, length)
		_core.mesh = b2
		_core.material_override = lib._add_mat(Color(1.0, 0.85, 0.7, 0.9))
		_core.position = Vector3(0, 1.0, -length * 0.5)
		add_child(_core)
		_light = OmniLight3D.new()
		_light.light_color = Color(1.0, 0.2, 0.1)
		_light.light_energy = 3.0
		_light.omni_range = 8.0
		_light.position = Vector3(0, 1.5, -4.0)
		add_child(_light)
		_place(0.0)

	func _place(k: float) -> void:
		var d := start_dir.rotated(Vector3.UP, sweep * k)
		var origin := Vector3.ZERO
		if boss != null and is_instance_valid(boss):
			origin = boss.global_position
		global_transform = Transform3D(Basis.looking_at(d, Vector3.UP), Vector3(origin.x, 0.0, origin.z))

	func _physics_process(delta: float) -> void:
		_t += delta
		var k := clampf(_t / dur, 0.0, 1.0)
		_place(k)
		var w := 1.0 + 0.15 * sin(_t * 40.0)
		_outer.scale = Vector3(w, w, 1.0)
		_tick -= delta
		if _tick <= 0.0 and hero != null and is_instance_valid(hero) and not hero.dead:
			var o := global_position
			var d := -global_transform.basis.z
			var v: Vector3 = hero.global_position - o
			v.y = 0.0
			var along := v.dot(d)
			if along > 0.5 and along < length:
				var perp := (v - d * along).length()
				if perp < 0.85:
					var res: String = hero.take_damage(dmg, (v - d * along).normalized() if perp > 0.05 else Vector3.RIGHT, false)
					if res == "hit":
						_tick = 0.5
		if boss == null or not is_instance_valid(boss) or boss.dead or _t >= dur:
			queue_free()


## HAYALET SÜRÜ: arenayı şeritler halinde geçen hayalet boğalar; iki dalga, farklı şeritler
class Stampede extends Node3D:
	var hero = null
	var dmg := 24.0
	var bounds := 11.0
	var lane_w := 2.2
	var _dir := Vector3.FORWARD
	var _side := Vector3.RIGHT
	var _t := 0.0
	var _waves: Array = []      # [aktif şeritler, uyarı başlangıcı, koşu başlangıcı, uyarı düğümleri, boğalar, vurdu mu]
	var _lane_off := [-4.8, -2.4, 0.0, 2.4, 4.8]

	func _ready() -> void:
		top_level = true
		global_position = Vector3.ZERO
		var a := randf() * TAU
		_dir = Vector3(cos(a), 0, sin(a))
		_side = Vector3(-_dir.z, 0, _dir.x)
		var first := [0, 2, 4] if randf() < 0.5 else [1, 3]
		var second := [1, 3] if first.size() == 3 else [0, 2, 4]
		_waves.append([first, 0.0, 1.2, [], [], false])
		_waves.append([second, 1.5, 2.7, [], [], false])

	func _physics_process(delta: float) -> void:
		_t += delta
		var lib = load("res://scripts/taurus_boss.gd")
		for w in _waves:
			var lanes: Array = w[0]
			var t_warn: float = w[1]
			var t_run: float = w[2]
			var teles: Array = w[3]
			var bulls: Array = w[4]
			if _t >= t_warn and teles.is_empty():
				for li in lanes:
					var mi := MeshInstance3D.new()
					var bx := BoxMesh.new()
					bx.size = Vector3(lane_w, 0.02, bounds * 2.4)
					mi.mesh = bx
					mi.material_override = lib._add_mat(Color(1.0, 0.15, 0.1, 0.15))
					mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
					add_child(mi)
					mi.global_transform = Transform3D(Basis.looking_at(_dir, Vector3.UP), _side * float(_lane_off[li]) + Vector3(0, 0.06, 0))
					teles.append(mi)
				Sfx.play("bossroar", -12.0, 0.1, 0, 0.9)
			if _t < t_run:
				var k := clampf((_t - t_warn) / (t_run - t_warn), 0.0, 1.0)
				for mi in teles:
					var tm: StandardMaterial3D = mi.material_override
					tm.albedo_color.a = 0.15 + 0.45 * k + (0.15 * sin(_t * 30.0) if k > 0.7 else 0.0)
				continue
			if bulls.is_empty() and not bool(w[5]):
				for li in lanes:
					var b := _ghost_bull(lib)
					add_child(b)
					bulls.append([b, li])
				Fx.shake(0.4)
				Sfx.play("crush", -4.0, 0.1, 0, 0.5)
				w[5] = true
			var rk := (_t - t_run) / 0.75
			for pair in bulls:
				var b: Node3D = pair[0]
				var along := lerpf(-bounds * 1.3, bounds * 1.3, rk)
				var pos: Vector3 = _side * float(_lane_off[int(pair[1])]) + _dir * along
				b.global_transform = Transform3D(Basis.looking_at(_dir, Vector3.UP), pos)
				if hero != null and is_instance_valid(hero) and not hero.dead:
					var v: Vector3 = hero.global_position - pos
					v.y = 0.0
					if absf(v.dot(_side)) < lane_w * 0.5 + 0.25 and absf(v.dot(_dir)) < 1.4:
						var res: String = hero.take_damage(dmg, (_dir + _side * signf(v.dot(_side))).normalized(), false)
						if res == "hit":
							hero.velocity = _side * signf(v.dot(_side) + 0.01) * 12.0
			for mi in teles:
				var tm: StandardMaterial3D = mi.material_override
				tm.albedo_color.a = maxf(0.6 - rk, 0.0)
		if _t > 3.6:
			queue_free()

	func _ghost_bull(lib) -> Node3D:
		var root := Node3D.new()
		var m: StandardMaterial3D = lib._add_mat(Color(0.75, 1.0, 0.6, 0.55))
		var body := MeshInstance3D.new()
		var s := SphereMesh.new()
		s.radius = 0.8
		s.height = 1.6
		body.mesh = s
		body.material_override = m
		body.position = Vector3(0, 1.2, 0)
		body.scale = Vector3(0.9, 0.85, 1.6)
		root.add_child(body)
		var head := MeshInstance3D.new()
		var hs := SphereMesh.new()
		hs.radius = 0.45
		hs.height = 0.9
		head.mesh = hs
		head.material_override = m
		head.position = Vector3(0, 1.3, -1.35)
		root.add_child(head)
		for sgn: float in [-1.0, 1.0]:
			var h := MeshInstance3D.new()
			var c := CylinderMesh.new()
			c.top_radius = 0.0
			c.bottom_radius = 0.1
			c.height = 0.8
			h.mesh = c
			h.material_override = m
			h.position = Vector3(sgn * 0.45, 1.65, -1.5)
			h.rotation = Vector3(-0.6, 0, -sgn * 1.0)
			root.add_child(h)
		var l := OmniLight3D.new()
		l.light_color = Color(0.6, 1.0, 0.5)
		l.light_energy = 1.5
		l.omni_range = 4.0
		l.position = Vector3(0, 1.5, 0)
		root.add_child(l)
		return root


## VENÜS GÜLÜ: Boğa'yı iyileten bitki. Düşman grubundadır, silahla kesilir.
class Rose extends Node3D:
	var boss = null
	var max_hp := 140.0
	var hp := 140.0
	var heal_rate := 24.0
	var radius := 0.6
	var dead := false
	var kind := "rose"
	var _t := 0.0
	var _link: MeshInstance3D
	var _bloom: Node3D
	var _bar_mat: ShaderMaterial
	var _flash := 0.0
	var _petal: StandardMaterial3D

	func _ready() -> void:
		add_to_group("enemies")
		hp = max_hp
		var stem := MeshInstance3D.new()
		var c := CylinderMesh.new()
		c.top_radius = 0.07
		c.bottom_radius = 0.12
		c.height = 1.5
		stem.mesh = c
		var g := StandardMaterial3D.new()
		g.albedo_color = Color(0.15, 0.35, 0.1)
		stem.material_override = g
		stem.position.y = 0.75
		add_child(stem)
		for i in 3:
			var leaf := MeshInstance3D.new()
			var ls := SphereMesh.new()
			ls.radius = 0.2
			ls.height = 0.4
			leaf.mesh = ls
			leaf.material_override = g
			var a := TAU * float(i) / 3.0
			leaf.position = Vector3(cos(a) * 0.22, 0.4 + float(i) * 0.3, sin(a) * 0.22)
			leaf.scale = Vector3(1.4, 0.3, 0.7)
			add_child(leaf)
		_bloom = Node3D.new()
		_bloom.position.y = 1.7
		add_child(_bloom)
		_petal = StandardMaterial3D.new()
		_petal.albedo_color = Color(1.0, 0.45, 0.65)
		_petal.emission_enabled = true
		_petal.emission = Color(1.0, 0.4, 0.6)
		_petal.emission_energy_multiplier = 1.2
		for i in 10:
			var p := MeshInstance3D.new()
			var ps := SphereMesh.new()
			ps.radius = 0.22
			ps.height = 0.44
			p.mesh = ps
			p.material_override = _petal
			var a := TAU * float(i) / 10.0
			var r := 0.28 if i % 2 == 0 else 0.16
			p.position = Vector3(cos(a) * r, 0.08 if i % 2 == 0 else 0.2, sin(a) * r)
			p.scale = Vector3(1.0, 0.6, 1.0)
			_bloom.add_child(p)
		var l := OmniLight3D.new()
		l.light_color = Color(1.0, 0.5, 0.7)
		l.light_energy = 1.4
		l.omni_range = 4.0
		l.position.y = 1.8
		add_child(l)
		# Boğa'ya akan şifa bağı
		_link = MeshInstance3D.new()
		var lb := BoxMesh.new()
		lb.size = Vector3(0.08, 0.08, 1.0)
		_link.mesh = lb
		var lib = load("res://scripts/taurus_boss.gd")
		_link.material_override = lib._add_mat(Color(1.0, 0.55, 0.75, 0.7))
		_link.top_level = true
		add_child(_link)
		# can barı
		var bar := MeshInstance3D.new()
		var q := QuadMesh.new()
		q.size = Vector2(1.1, 0.13)
		bar.mesh = q
		_bar_mat = ShaderMaterial.new()
		_bar_mat.shader = preload("res://shaders/hp_bar.gdshader")
		bar.material_override = _bar_mat
		bar.position.y = 2.4
		bar.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(bar)
		scale = Vector3(0.05, 0.05, 0.05)
		var tw := create_tween()
		tw.tween_property(self, "scale", Vector3.ONE, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	func _physics_process(delta: float) -> void:
		if dead:
			return
		_t += delta
		_flash = maxf(_flash - delta * 6.0, 0.0)
		_bloom.rotation.y += delta * 0.8
		_bloom.scale = Vector3.ONE * (1.0 + 0.06 * sin(_t * 3.0))
		_petal.emission_energy_multiplier = 1.2 + _flash * 4.0
		_bar_mat.set_shader_parameter("fill", clampf(hp / max_hp, 0.0, 1.0))
		_bar_mat.set_shader_parameter("stunned", 0.0)
		if boss == null or not is_instance_valid(boss) or boss.dead:
			_link.visible = false
			return
		boss.heal_boss(heal_rate * delta)
		var a := global_position + Vector3(0, 1.7, 0)
		var b: Vector3 = boss.global_position + Vector3(0, 2.4, 0)
		var mid := (a + b) * 0.5
		var ln := a.distance_to(b)
		if ln > 0.1:
			_link.global_transform = Transform3D(Basis.looking_at(b - a, Vector3.UP), mid)
			_link.scale = Vector3(1.0 + 0.4 * sin(_t * 8.0), 1.0, ln)

	func take_hit(dmg: float, dir: Vector3, _kb: float, heavy: bool, crit := false) -> void:
		if dead:
			return
		hp -= dmg
		_flash = 1.0
		var hfx = load("res://scripts/hit_fx.gd")
		hfx.impact(get_parent(), global_position + Vector3(0, 1.4, 0) - dir * 0.4, dir, Color(1.0, 0.6, 0.75), heavy or crit)
		hfx.number(get_parent(), global_position + Vector3(0, 2.6, 0), dmg, crit)
		Sfx.play("cut", -8.0, 0.1, 40, 1.3)
		if hp <= 0.0:
			dead = true
			remove_from_group("enemies")
			_link.visible = false
			Fx.flash_light(global_position + Vector3(0, 1.5, 0), Color(1.0, 0.5, 0.7), 5.0, 6.0, 0.3)
			var pm: StandardMaterial3D = Fx.emissive(Color(1.0, 0.5, 0.7), 3.0)
			var s := SphereMesh.new()
			s.radius = 0.08
			s.height = 0.16
			Fx._burst(global_position + Vector3(0, 1.6, 0), Vector3.UP, 24, pm, s, 2.0, 5.0, 70.0, -3.0, 0.9, 0.6, 1.2)
			Sfx.play("enemydie", -8.0, 0.05, 0, 1.6)
			var tw := create_tween()
			tw.tween_property(self, "scale", Vector3(0.05, 0.05, 0.05), 0.3).set_ease(Tween.EASE_IN)
			tw.tween_callback(queue_free)

	func stun(_sec: float, _parried := false) -> void:
		pass

	func pull_to(_point: Vector3, _strength: float) -> void:
		pass

	func apply_burn(dps: float, dur: float) -> void:
		take_hit(dps * dur * 0.5, Vector3.UP, 0.0, false)
