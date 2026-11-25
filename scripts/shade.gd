extends CharacterBody3D
## GÖLGE (ilk düşman): burçların bozulmasıyla karanlığa dönmüş bir yıldız ruhu.
## Süzülerek yaklaşır. Saldırmadan önce DURUR ve saldırısını belli eder:
##   - yerde saldıracağı alanı gösteren kızıl bir yelpaze büyür,
##   - gözleri ve pençeleri kor gibi parlar, geriye doğru gerilir.
## Sonra öne atılıp pençe savurur. Tam o anda parry yaparsan sersemler (2 kat hasar alır).
## Kan yok: vurulunca yıldız tozu ve altın kırıkları saçılır, ölünce ışığa dağılır.

signal killed(enemy)

const SlashFx = preload("res://scripts/slash_fx.gd")

const SPEED := 3.3
const ATTACK_RANGE := 2.1      # bu mesafeye girince saldırıya hazırlanır
const STRIKE_REACH := 2.4
const STRIKE_ARC := 110.0
const DAMAGE := 14.0
const WINDUP := 0.62
const STRIKE := 0.14
const RECOVER := 0.6
const PARRY_STUN := 1.5

var max_hp := 55.0
var hp := 55.0
var radius := 0.45
var dead := false
var hero = null
var state := "spawn"           # spawn, chase, windup, strike, recover, stun, dead
var _st := 0.0                 # durumdaki süre
var _face := Vector3.FORWARD
var _strike_dir := Vector3.FORWARD
var _struck := false
var _knock := Vector3.ZERO
var _move := Vector3.ZERO      # kendi hareketi (geri itme ayrı tutulur)
var _flash := 0.0
var _t := 0.0
var _cd := 0.0                 # saldırılar arası bekleme

var body_root: Node3D
var vis: Node3D
var claw_l: Node3D
var claw_r: Node3D
var tele: MeshInstance3D
var tele_mat: StandardMaterial3D
var m_body: StandardMaterial3D
var m_cloth: StandardMaterial3D
var m_eye: StandardMaterial3D
var m_claw: StandardMaterial3D
var _bounds := 10.5


func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 4
	collision_mask = 0
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	_t = randf() * 10.0
	_cd = randf_range(0.2, 0.9)
	_build()
	# doğuş: yerden yükselir
	vis.position.y = -1.6
	vis.scale = Vector3(0.3, 0.3, 0.3)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(vis, "position:y", 0.0, 0.7).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(vis, "scale", Vector3.ONE, 0.7).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# ---------------------------------------------------------------- görünüş

func _m(c: Color, rough := 0.7) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	return m


func _part(parent: Node3D, mesh: Mesh, pos: Vector3, mat: Material, sc := Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.scale = sc
	parent.add_child(mi)
	return mi


func _build() -> void:
	m_body = _m(Color(0.06, 0.04, 0.12), 0.6)
	m_body.emission_enabled = true
	m_body.emission = Color(0.25, 0.1, 0.45)
	m_body.emission_energy_multiplier = 0.25
	m_cloth = _m(Color(0.1, 0.06, 0.2), 0.8)
	m_cloth.emission_enabled = true
	m_cloth.emission = Color(0.3, 0.12, 0.5)
	m_cloth.emission_energy_multiplier = 0.15
	m_eye = StandardMaterial3D.new()
	m_eye.albedo_color = Color.BLACK
	m_eye.emission_enabled = true
	m_eye.emission = Color(1.0, 0.35, 0.15)
	m_eye.emission_energy_multiplier = 3.0
	m_claw = _m(Color(0.15, 0.08, 0.2), 0.4)
	m_claw.emission_enabled = true
	m_claw.emission = Color(1.0, 0.3, 0.12)
	m_claw.emission_energy_multiplier = 0.3

	body_root = Node3D.new()
	add_child(body_root)
	vis = Node3D.new()
	body_root.add_child(vis)

	# yırtık pelerin gövde (aşağı doğru incelen, yerden yüksekte süzülen)
	var robe := CylinderMesh.new()
	robe.top_radius = 0.3
	robe.bottom_radius = 0.05
	robe.height = 1.1
	robe.radial_segments = 12
	_part(vis, robe, Vector3(0, 0.95, 0), m_cloth)
	# yırtık uçlar
	for i in 6:
		var a := TAU * float(i) / 6.0
		var tat := CylinderMesh.new()
		tat.top_radius = 0.06
		tat.bottom_radius = 0.0
		tat.height = 0.55
		tat.radial_segments = 4
		var tm := _part(vis, tat, Vector3(cos(a) * 0.16, 0.42, sin(a) * 0.16), m_cloth)
		tm.rotation = Vector3(sin(a) * 0.35, 0, -cos(a) * 0.35)
	# omuzlar ve göğüs
	var torso := SphereMesh.new()
	torso.radius = 0.34
	torso.height = 0.55
	_part(vis, torso, Vector3(0, 1.55, 0), m_body, Vector3(1.25, 1.0, 0.85))
	# kambur kukulete ve baş
	var hood := SphereMesh.new()
	hood.radius = 0.24
	hood.height = 0.5
	_part(vis, hood, Vector3(0, 1.88, 0.05), m_cloth, Vector3(1.0, 1.1, 1.15))
	var face := SphereMesh.new()
	face.radius = 0.16
	face.height = 0.32
	_part(vis, face, Vector3(0, 1.85, -0.1), _m(Color(0.01, 0.0, 0.02)))
	var eye := SphereMesh.new()
	eye.radius = 0.035
	eye.height = 0.07
	_part(vis, eye, Vector3(-0.07, 1.88, -0.24), m_eye, Vector3(1.4, 0.7, 1.0))
	_part(vis, eye, Vector3(0.07, 1.88, -0.24), m_eye, Vector3(1.4, 0.7, 1.0))
	# başın üstünde kırık bir yıldız tacı (bozulmuş yıldız ruhu)
	for i in 5:
		var a := -0.9 + float(i) * 0.45
		var spike := CylinderMesh.new()
		spike.top_radius = 0.0
		spike.bottom_radius = 0.035
		spike.height = 0.22 + (0.1 if i == 2 else 0.0)
		spike.radial_segments = 4
		var sp := _part(vis, spike, Vector3(sin(a) * 0.2, 2.1, cos(a) * 0.05 + 0.05), m_claw)
		sp.rotation.z = -a * 0.6
	# uzun kollar ve pençeler
	claw_l = _arm(-1.0)
	claw_r = _arm(1.0)

	# saldırı uyarısı: yerde kızıl yelpaze
	tele = MeshInstance3D.new()
	tele.mesh = _fan_mesh(deg_to_rad(STRIKE_ARC), STRIKE_REACH)
	tele_mat = StandardMaterial3D.new()
	tele_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	tele_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	tele_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	tele_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	tele_mat.vertex_color_use_as_albedo = true
	tele_mat.albedo_color = Color(1.0, 0.25, 0.12, 0.0)
	tele.material_override = tele_mat
	tele.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	tele.position.y = 0.05
	tele.visible = false
	body_root.add_child(tele)


func _arm(side: float) -> Node3D:
	var sh := Node3D.new()
	sh.position = Vector3(side * 0.38, 1.6, 0)
	vis.add_child(sh)
	var arm := CylinderMesh.new()
	arm.top_radius = 0.06
	arm.bottom_radius = 0.035
	arm.height = 0.8
	arm.radial_segments = 6
	var am := _part(sh, arm, Vector3(0, -0.4, 0), m_body)
	am.rotation.z = side * 0.15
	var claw := Node3D.new()
	claw.position = Vector3(side * 0.06, -0.82, 0)
	sh.add_child(claw)
	for k in 3:
		var c := CylinderMesh.new()
		c.top_radius = 0.0
		c.bottom_radius = 0.025
		c.height = 0.3
		c.radial_segments = 4
		var cm := _part(claw, c, Vector3((float(k) - 1.0) * 0.045, -0.13, -0.04), m_claw)
		cm.rotation.x = -0.4
	sh.rotation.z = side * 0.25
	return sh


## Yerdeki uyarı yelpazesi: kenarı parlak, içi soluk
func _fan_mesh(arc: float, reach: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := 24
	for i in n:
		var a0 := -arc * 0.5 + arc * float(i) / float(n)
		var a1 := -arc * 0.5 + arc * float(i + 1) / float(n)
		var p0 := Vector3(-sin(a0), 0, -cos(a0)) * reach
		var p1 := Vector3(-sin(a1), 0, -cos(a1)) * reach
		st.set_color(Color(1, 1, 1, 0.15))
		st.add_vertex(Vector3.ZERO)
		st.set_color(Color(1, 1, 1, 0.9))
		st.add_vertex(p0)
		st.add_vertex(p1)
	return st.commit()


# ---------------------------------------------------------------- yapay zekâ

func _physics_process(delta: float) -> void:
	_t += delta
	_st += delta
	_cd -= delta
	_flash = maxf(_flash - delta * 6.0, 0.0)
	if dead:
		return
	var to := Vector3.ZERO
	var dist := 99.0
	var hero_ok: bool = hero != null and is_instance_valid(hero) and not hero.dead
	if hero_ok:
		to = hero.global_position - global_position
		to.y = 0.0
		dist = to.length()
 
	var want := Vector3.ZERO
	match state:
		"spawn":
			if _st > 0.7:
				_set_state("chase")
		"chase":
			if hero_ok:
				_face = _face.slerp(to.normalized(), minf(8.0 * delta, 1.0)) if dist > 0.1 else _face
				if dist > ATTACK_RANGE * 0.85:
					want = to.normalized() * SPEED
				if dist < ATTACK_RANGE and _cd <= 0.0:
					_set_state("windup")
					_strike_dir = to.normalized()
		"windup":
			# hedefi hazırlığın ilk yarısında takip eder, sonra kilitlenir (kaçmak mümkün olsun)
			if hero_ok and _st < WINDUP * 0.5 and dist > 0.1:
				_strike_dir = _strike_dir.slerp(to.normalized(), minf(6.0 * delta, 1.0)).normalized()
			_face = _strike_dir
			if _st >= WINDUP:
				_set_state("strike")
		"strike":
			want = _strike_dir * 9.0 * (1.0 - _st / STRIKE)
			_move = want
			if not _struck and _st >= STRIKE * 0.4:
				_struck = true
				_do_strike()
			if _st >= STRIKE:
				_set_state("recover")
		"recover":
			if _st >= RECOVER:
				_cd = randf_range(0.5, 1.3)
				_set_state("chase")
		"stun":
			if _st >= float(get_meta("stun_len", 0.3)):
				_set_state("chase")

	# diğer gölgelerden uzak dur
	for o in get_tree().get_nodes_in_group("enemies"):
		if o == self or o.dead:
			continue
		var d: Vector3 = global_position - o.global_position
		d.y = 0.0
		var l := d.length()
		if l < 1.1 and l > 0.01:
			want += d / l * (1.1 - l) * 6.0

	_knock = _knock.move_toward(Vector3.ZERO, 30.0 * delta)
	_move = _move.move_toward(want, 25.0 * delta)
	velocity = _move + _knock
	move_and_slide()
	var flat := Vector2(global_position.x, global_position.z)
	if flat.length() > _bounds:
		flat = flat.normalized() * _bounds
		global_position = Vector3(flat.x, 0.0, flat.y)
	global_position.y = 0.0
	_animate(delta)


func _set_state(s: String) -> void:
	state = s
	_st = 0.0
	tele.visible = s == "windup"
	if s == "windup":
		Sfx.play("roar", -20.0, 0.1, 0, 2.6)
	if s == "strike":
		_struck = false
		Sfx.play("dash", -10.0, 0.1, 0, 0.8)


func _do_strike() -> void:
	var fx := SlashFx.make(-deg_to_rad(STRIKE_ARC) * 0.5, deg_to_rad(STRIKE_ARC) * 0.5, 0.4, STRIKE_REACH, Color(1.0, 0.35, 0.15), 0.18)
	get_parent().add_child(fx)
	fx.global_transform = Transform3D(body_root.global_transform.basis, global_position + Vector3(0, 1.0, 0))
	if hero == null or not is_instance_valid(hero) or hero.dead:
		return
	var to: Vector3 = hero.global_position - global_position
	to.y = 0.0
	var dist := to.length()
	if dist > STRIKE_REACH + 0.35:
		return
	if dist > 0.3 and _strike_dir.angle_to(to / dist) > deg_to_rad(STRIKE_ARC) * 0.5:
		return
	var res: String = hero.take_damage(DAMAGE, _strike_dir)
	if res == "parried":
		stun(PARRY_STUN, true)
		_knock = -_strike_dir * 7.0


func stun(sec: float, parried := false) -> void:
	set_meta("stun_len", sec)
	set_meta("parried", parried)
	_set_state("stun")


# ---------------------------------------------------------------- hasar

func take_hit(dmg: float, dir: Vector3, kb: float, heavy: bool) -> void:
	if dead or state == "spawn":
		return
	var stunned_by_parry: bool = state == "stun" and bool(get_meta("parried", false))
	var d := dmg * (2.0 if stunned_by_parry else 1.0)
	hp -= d
	_flash = 1.0
	_knock = dir * kb
	var p := global_position + Vector3(0, 1.3, 0)
	_stardust(p, dir, 10 if heavy else 6)
	_shards(p, dir, 5 if heavy else 3)
	if hp <= 0.0:
		_die(dir)
		return
	# ağır ve bitirici vuruşlar hazırlığı keser; hafif vuruşlar sadece sendeletir
	if heavy and state != "stun":
		stun(0.45)
	elif state == "chase" or state == "recover":
		stun(0.18)


func _stardust(p: Vector3, dir: Vector3, n: int) -> void:
	var m: StandardMaterial3D = Fx.emissive(Color(1.0, 0.92, 0.65), 5.0)
	var s := SphereMesh.new()
	s.radius = 0.035
	s.height = 0.07
	s.radial_segments = 6
	s.rings = 3
	Fx._burst(p, (dir + Vector3(0, 0.5, 0)).normalized(), n, m, s, 2.0, 6.0, 45.0, -3.0, 0.6, 0.5, 1.4)


func _shards(p: Vector3, dir: Vector3, n: int) -> void:
	var m: StandardMaterial3D = Fx.mat(Color(0.95, 0.78, 0.35), 1.0, 0.25)
	var b := BoxMesh.new()
	b.size = Vector3(0.06, 0.02, 0.1)
	Fx._burst(p, (dir + Vector3(0, 0.8, 0)).normalized(), n, m, b, 3.0, 6.5, 40.0, -18.0, 0.8, 0.6, 1.3, true)


func _die(dir: Vector3) -> void:
	dead = true
	state = "dead"
	tele.visible = false
	remove_from_group("enemies")
	var p := global_position + Vector3(0, 1.2, 0)
	_stardust(p, Vector3.UP, 26)
	_shards(p, dir, 10)
	Fx.flash_light(p, Color(1.0, 0.85, 0.55), 5.0, 6.0, 0.35)
	Fx.shake(0.25)
	Sfx.play("coin", -6.0, 0.1, 0, 0.9)
	killed.emit(self)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(vis, "scale", Vector3(1.3, 0.05, 1.3), 0.25).set_ease(Tween.EASE_IN)
	tw.tween_property(vis, "position:y", 0.6, 0.25)
	tw.chain().tween_callback(queue_free)


# ---------------------------------------------------------------- animasyon

func _animate(delta: float) -> void:
	body_root.rotation.y = lerp_angle(body_root.rotation.y, atan2(-_face.x, -_face.z), minf(14.0 * delta, 1.0))
	var hover := sin(_t * 2.2) * 0.08
	var lean := 0.0
	var arms := 0.25
	var glow := 3.0
	var claw_glow := 0.3
	match state:
		"windup":
			var k := _st / WINDUP
			lean = 0.3 * k                       # geriye gerilir
			arms = 0.25 + 1.6 * k                # pençeleri kaldırır
			glow = 3.0 + 9.0 * k
			claw_glow = 0.3 + 4.0 * k
			tele_mat.albedo_color.a = 0.15 + 0.6 * k
			tele.scale = Vector3.ONE * (0.6 + 0.4 * k)
		"strike":
			lean = -0.45
			arms = -1.2
			glow = 10.0
			claw_glow = 5.0
		"recover":
			lean = -0.2 * (1.0 - _st / RECOVER)
			arms = -0.6 * (1.0 - _st / RECOVER)
		"stun":
			lean = 0.25
			arms = 0.0
			glow = 1.0
			hover += sin(_t * 18.0) * 0.03
	vis.rotation.x = lerpf(vis.rotation.x, lean, minf(14.0 * delta, 1.0))
	if state != "spawn":
		vis.position.y = hover
	claw_l.rotation.x = lerpf(claw_l.rotation.x, arms, minf(16.0 * delta, 1.0))
	claw_r.rotation.x = lerpf(claw_r.rotation.x, arms, minf(16.0 * delta, 1.0))
	m_eye.emission_energy_multiplier = glow
	m_claw.emission_energy_multiplier = claw_glow
	# vurulunca beyaz parlama
	m_body.emission = Color(0.25, 0.1, 0.45).lerp(Color(1.0, 0.95, 0.85), _flash)
	m_body.emission_energy_multiplier = 0.25 + _flash * 4.0
	m_cloth.emission = Color(0.3, 0.12, 0.5).lerp(Color(1.0, 0.95, 0.85), _flash)
	m_cloth.emission_energy_multiplier = 0.15 + _flash * 3.0
