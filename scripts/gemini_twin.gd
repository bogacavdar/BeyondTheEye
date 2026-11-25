extends CharacterBody3D
## İKİZLER boss'unun bir yarısı. Kastor (mavi, kılıç ustası) ya da Polluks (altın, boksör/yıldız büyücüsü).
## Kontrolcü (gemini_boss.gd) ikisini yönetir. Biri yere düşünce dokunulmaz olur ve bir süre sonra
## kardeşi onu ayağa kaldırır; ikisini birbirine yakın zamanda indirmek gerekir.

const SlashFx = preload("res://scripts/slash_fx.gd")
const HitFx = preload("res://scripts/hit_fx.gd")
const EnemyScript = preload("res://scripts/enemy.gd")
const AriesScript = preload("res://scripts/aries_boss.gd")
const PARRY_COL := Color(1.0, 0.72, 0.2)
const DANGER_COL := Color(1.0, 0.1, 0.18)
const DOWN_TIME := 7.0

var who := "castor"
var kind := "castor"
var ctrl = null
var partner = null
var hero = null
var max_hp := 1300.0
var hp := 1300.0
var radius := 0.9
var dead := false          # dokunulamaz mı (yere düşmüş ya da ölmüş)
var down := false
var gone := false
var dmg_mult := 1.0
var windup_mult := 1.0
var last_dealt := 0.0
var _bounds := 10.0
var state := "intro"
var atk := ""
var _st := 0.0
var _t := 0.0
var _face := Vector3.FORWARD
var _aim_dir := Vector3.FORWARD
var _aim_point := Vector3.ZERO
var _knock := Vector3.ZERO
var _move := Vector3.ZERO
var _flash := 0.0
var _done := false
var _chain := 0
var _cd := {}
var _global_cd := 1.0
var _stun_len := 0.0
var _parried := false
var _enraged := false
var _down_t := 0.0
var _line_len := 8.0
var _lunge_hit := false
var _burn_t := 0.0
var _burn_dps := 0.0

var col_main := Color(0.45, 0.7, 1.0)
var vis: Node3D
var body_root: Node3D
var arm_l: Node3D
var arm_r: Node3D
var head: Node3D
var m_body: StandardMaterial3D
var m_armor: StandardMaterial3D
var m_eye: StandardMaterial3D
var m_glow: StandardMaterial3D
var tele: MeshInstance3D
var tele_mat: StandardMaterial3D
var hp_bar: MeshInstance3D
var hp_mat: ShaderMaterial
var down_ring: MeshInstance3D


func _ready() -> void:
	kind = who
	add_to_group("enemies")
	collision_layer = 4
	collision_mask = 0
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	hp = max_hp
	if who == "castor":
		col_main = Color(0.45, 0.72, 1.0)
		_cd = {"slash": 0.6, "lunge": 2.0, "blades": 3.0}
	else:
		col_main = Color(1.0, 0.8, 0.35)
		_cd = {"jab": 0.6, "starfall": 2.5, "nova": 4.0}
	_build()
	vis.position.y = 6.0
	var tw := create_tween()
	tw.tween_property(vis, "position:y", 0.0, 1.0).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)


# ---------------------------------------------------------------- görünüş

func _m(c: Color, rough := 0.5, metal := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	return m


func _part(parent: Node3D, mesh: Mesh, pos: Vector3, mat: Material, sc := Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.scale = sc
	parent.add_child(mi)
	return mi


func _sph(r: float) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	return s


func _cone(rb: float, rt: float, h: float) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.bottom_radius = rb
	c.top_radius = rt
	c.height = h
	c.radial_segments = 10
	return c


func _build() -> void:
	var castor := who == "castor"
	m_body = _m(Color(0.1, 0.1, 0.14), 0.6)
	m_body.emission_enabled = true
	m_body.emission = col_main * 0.5
	m_body.emission_energy_multiplier = 0.3
	m_armor = _m(Color(0.75, 0.8, 0.9) if castor else Color(0.95, 0.78, 0.38), 0.3, 0.85)
	m_eye = StandardMaterial3D.new()
	m_eye.albedo_color = Color.BLACK
	m_eye.emission_enabled = true
	m_eye.emission = col_main
	m_eye.emission_energy_multiplier = 5.0
	m_glow = _m(col_main, 0.3)
	m_glow.emission_enabled = true
	m_glow.emission = col_main
	m_glow.emission_energy_multiplier = 2.0
	var cape := _m(Color(0.15, 0.25, 0.6) if castor else Color(0.55, 0.2, 0.12), 0.8)

	body_root = Node3D.new()
	add_child(body_root)
	vis = Node3D.new()
	vis.scale = Vector3.ONE * (1.35 if castor else 1.55)
	body_root.add_child(vis)
	# bacaklar
	for s in [-1.0, 1.0]:
		_part(vis, _cone(0.13, 0.17, 0.9), Vector3(s * 0.2, 0.45, 0), m_body)
		_part(vis, _cone(0.15, 0.13, 0.25), Vector3(s * 0.2, 0.12, -0.04), m_armor)
	# gövde ve zırh
	_part(vis, _cone(0.28, 0.42, 0.85), Vector3(0, 1.3, 0), m_body)
	_part(vis, _sph(0.38), Vector3(0, 1.45, -0.08), m_armor, Vector3(1.15, 1.0, 0.65) if castor else Vector3(1.35, 1.05, 0.75))
	_part(vis, _sph(0.12), Vector3(0, 1.5, -0.32), m_eye)   # göğüsteki yıldız (Kastor ya da Polluks)
	for s in [-1.0, 1.0]:
		_part(vis, _sph(0.2), Vector3(s * 0.46, 1.68, 0), m_armor, Vector3(1.2, 0.8, 1.1))
	var cp := _part(vis, _cone(0.42, 0.2, 1.1), Vector3(0, 1.15, 0.22), cape)
	cp.rotation.x = 0.12
	# baş ve miğfer
	head = Node3D.new()
	head.position = Vector3(0, 1.98, 0)
	vis.add_child(head)
	_part(head, _sph(0.2), Vector3.ZERO, m_armor, Vector3(1.0, 1.1, 1.05))
	_part(head, _sph(0.04), Vector3(-0.07, 0.0, -0.18), m_eye, Vector3(1.6, 0.6, 1.0))
	_part(head, _sph(0.04), Vector3(0.07, 0.0, -0.18), m_eye, Vector3(1.6, 0.6, 1.0))
	if castor:
		# tüylü miğfer sorgucu
		for k in 6:
			_part(head, _sph(0.07), Vector3(0, 0.2 + float(k) * 0.02, 0.12 - float(k) * 0.08), m_glow)
	else:
		# defne tacı
		for k in 8:
			var a := TAU * float(k) / 8.0
			_part(head, _sph(0.05), Vector3(cos(a) * 0.2, 0.12, sin(a) * 0.2), m_glow)
	arm_l = _arm(-1.0, castor)
	arm_r = _arm(1.0, castor)
	if castor:
		# uzun yıldız kılıcı
		var sword := Node3D.new()
		sword.position = Vector3(0, -0.75, 0)
		arm_r.add_child(sword)
		var blade := BoxMesh.new()
		blade.size = Vector3(0.06, 0.03, 1.3)
		_part(sword, blade, Vector3(0, 0, -0.7), m_glow)
		_part(sword, _sph(0.07), Vector3.ZERO, m_armor, Vector3(2.2, 0.6, 0.6))
	else:
		# boksör eldivenleri
		for a in [arm_l, arm_r]:
			_part(a, _sph(0.2), Vector3(0, -0.78, 0), m_glow)
	var l := OmniLight3D.new()
	l.light_color = col_main
	l.light_energy = 1.6
	l.omni_range = 5.0
	l.position = Vector3(0, 2.0, 0)
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

	hp_bar = MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(1.8, 0.16)
	hp_bar.mesh = q
	hp_mat = ShaderMaterial.new()
	hp_mat.shader = preload("res://shaders/hp_bar.gdshader")
	hp_bar.material_override = hp_mat
	hp_bar.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	hp_bar.position.y = 3.6
	add_child(hp_bar)

	down_ring = MeshInstance3D.new()
	var t := TorusMesh.new()
	t.inner_radius = 1.25
	t.outer_radius = 1.4
	t.rings = 64
	down_ring.mesh = t
	var dm := StandardMaterial3D.new()
	dm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dm.albedo_color = col_main
	down_ring.material_override = dm
	down_ring.position.y = 0.08
	down_ring.scale = Vector3(1, 0.1, 1)
	down_ring.visible = false
	add_child(down_ring)


func _arm(side: float, castor: bool) -> Node3D:
	var sh := Node3D.new()
	sh.position = Vector3(side * (0.5 if castor else 0.55), 1.68, 0)
	vis.add_child(sh)
	_part(sh, _cone(0.08, 0.11, 0.75), Vector3(0, -0.38, 0), m_body)
	_part(sh, _sph(0.11), Vector3(0, -0.72, 0), m_armor)
	sh.rotation.z = side * 0.15
	return sh


# ---------------------------------------------------------------- uyarı geometrisi

func _fan_mesh(arc: float, reach: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := 28
	for i in n:
		var a0 := -arc * 0.5 + arc * float(i) / float(n)
		var a1 := -arc * 0.5 + arc * float(i + 1) / float(n)
		st.set_color(Color(1, 1, 1, 0.12))
		st.add_vertex(Vector3.ZERO)
		st.set_color(Color(1, 1, 1, 0.95))
		st.add_vertex(Vector3(-sin(a0), 0, -cos(a0)) * reach)
		st.add_vertex(Vector3(-sin(a1), 0, -cos(a1)) * reach)
	return st.commit()


func _line_mesh(length: float, width: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var w := width * 0.5
	var pts := [Vector3(-w, 0, 0), Vector3(w, 0, 0), Vector3(w, 0, -length), Vector3(-w, 0, -length)]
	var cols := [Color(1, 1, 1, 0.9), Color(1, 1, 1, 0.9), Color(1, 1, 1, 0.3), Color(1, 1, 1, 0.3)]
	for idx in [0, 1, 2, 0, 2, 3]:
		st.set_color(cols[idx])
		st.add_vertex(pts[idx])
	return st.commit()


func _show_tele(mesh: Mesh, col: Color) -> void:
	tele.mesh = mesh
	tele_mat.albedo_color = Color(col.r, col.g, col.b, 0.2)
	tele.visible = true
	_place_tele()


func _place_tele() -> void:
	var b := Basis.looking_at(_aim_dir, Vector3.UP) if _aim_dir.length() > 0.1 else Basis.IDENTITY
	tele.global_transform = Transform3D(b, Vector3(global_position.x, 0.07, global_position.z))


func _dist_to_edge(dir: Vector3) -> float:
	var p := Vector2(global_position.x, global_position.z)
	var d := Vector2(dir.x, dir.z).normalized()
	var b := p.dot(d)
	var c := p.length_squared() - _bounds * _bounds
	var disc := b * b - c
	if disc < 0.0:
		return 0.0
	return maxf(-b + sqrt(disc), 0.0)


# ---------------------------------------------------------------- yapay zekâ

func _phase() -> int:
	return int(ctrl.phase) if ctrl != null and is_instance_valid(ctrl) else 1


func _spd() -> float:
	var k := 1.0 + 0.12 * float(_phase() - 1)
	return k * (1.35 if _enraged else 1.0)


func _windup_len() -> float:
	var k := windup_mult / _spd() * (0.75 if _enraged else 1.0) * (0.6 if _chain_follow else 1.0)
	match atk:
		"slash":
			return 0.55 * k
		"lunge":
			return 0.6 * k
		"blades":
			return 0.6 * k
		"jab":
			return 0.45 * k
		"starfall":
			return 0.7 * k
		"nova":
			return 0.8 * k
		"pincer":
			return 0.95 * windup_mult
	return 0.6


var _chain_follow := false


func _physics_process(delta: float) -> void:
	_t += delta
	_st += delta
	_global_cd -= delta
	for k in _cd:
		_cd[k] = float(_cd[k]) - delta
	_flash = maxf(_flash - delta * 6.0, 0.0)
	if gone:
		return
	if _burn_t > 0.0 and not down:
		_burn_t -= delta
		hp -= _burn_dps * delta
		if hp <= 0.0:
			_fall()
	var hero_ok: bool = hero != null and is_instance_valid(hero) and not hero.dead
	var to := Vector3.ZERO
	var dist := 99.0
	if hero_ok:
		to = hero.global_position - global_position
		to.y = 0.0
		dist = to.length()
	var dir_to := to.normalized() if dist > 0.05 else _face
	var want := Vector3.ZERO
	match state:
		"intro":
			if _st > 1.2:
				_set_state("chase")
		"down":
			_down_t -= delta
			var k := clampf(_down_t / DOWN_TIME, 0.0, 1.0)
			down_ring.scale = Vector3(0.3 + 0.7 * k, 0.1, 0.3 + 0.7 * k)
			if _down_t <= 0.0:
				_revive()
		"chase":
			if hero_ok:
				_face = _face.slerp(dir_to, minf(8.0 * delta, 1.0)).normalized()
				var pref := 1.8 if who == "castor" else 4.5
				if dist > pref + 0.6:
					want = dir_to * (4.2 if who == "castor" else 3.0) * _spd()
				elif dist < pref - 1.2 and who == "pollux":
					want = -dir_to * 2.5
				if _global_cd <= 0.0:
					_pick(dist, dir_to)
		"windup":
			var w := _windup_len()
			if hero_ok and _st < w * 0.8 and atk != "pincer":
				_aim_dir = _aim_dir.slerp(dir_to, minf(7.0 * delta, 1.0)).normalized()
				_aim_point = hero.global_position
			_face = _aim_dir
			if atk == "lunge" or atk == "pincer":
				_line_len = minf(_dist_to_edge(_aim_dir), 9.0) if atk == "lunge" else 16.0
				tele.mesh = _line_mesh(_line_len, 1.6 if atk == "lunge" else 1.3)
			_place_tele()
			tele_mat.albedo_color.a = 0.15 + 0.6 * (_st / w)
			if _st >= w:
				_set_state("act")
		"act":
			want = _act(delta)
		"recover":
			if _st >= _recover_len():
				_set_state("chase")
		"stun":
			if _st >= _stun_len:
				_set_state("chase")
	_knock = _knock.move_toward(Vector3.ZERO, 30.0 * delta)
	if state == "act" and atk == "lunge":
		_move = want
	else:
		_move = _move.move_toward(want, 20.0 * delta)
	velocity = _move + _knock
	move_and_slide()
	var flat := Vector2(global_position.x, global_position.z)
	if flat.length() > _bounds:
		flat = flat.normalized() * _bounds
		global_position = Vector3(flat.x, 0.0, flat.y)
	global_position.y = 0.0
	_animate(delta)


func _recover_len() -> float:
	match atk:
		"lunge":
			return 0.7
		"blades", "starfall", "nova":
			return 0.6
		"pincer":
			return 1.0
	return 0.5 / _spd()


func _pick(dist: float, dir_to: Vector3) -> void:
	var opts: Array = []
	var ph := _phase()
	if who == "castor":
		if float(_cd["slash"]) <= 0.0 and dist < 3.3:
			opts.append_array(["slash", "slash", "slash"])
		if float(_cd["lunge"]) <= 0.0 and dist > 2.5:
			opts.append_array(["lunge", "lunge"])
		if ph >= 2 and float(_cd["blades"]) <= 0.0:
			opts.append("blades")
	else:
		if float(_cd["jab"]) <= 0.0 and dist < 3.0:
			opts.append_array(["jab", "jab", "jab"])
		if float(_cd["starfall"]) <= 0.0:
			opts.append_array(["starfall", "starfall"])
		if ph >= 2 and float(_cd["nova"]) <= 0.0 and dist < 6.0:
			opts.append("nova")
	if opts.is_empty():
		return
	atk = String(opts[randi() % opts.size()])
	_aim_dir = dir_to
	_aim_point = hero.global_position
	_chain = 0
	_chain_follow = false
	if atk == "slash":
		_chain = 2 if ph >= 2 else 1
	elif atk == "jab":
		_chain = 2
	_set_state("windup")


## Kontrolcü 3. evrede çağırır: kahramanın iki yanına ışınlanıp çapraz ışın
func start_pincer(pos: Vector3, target: Vector3) -> void:
	if down or gone or state == "intro":
		return
	_blink_to(pos)
	atk = "pincer"
	var d := target - pos
	d.y = 0.0
	_aim_dir = d.normalized() if d.length() > 0.1 else _face
	_face = _aim_dir
	_chain = 0
	_set_state("windup")


func _blink_to(pos: Vector3) -> void:
	_flash_fx(global_position)
	global_position = Vector3(pos.x, 0.0, pos.z)
	_flash_fx(global_position)
	Sfx.play("dash", -6.0, 0.05, 0, 1.6)


func _flash_fx(p: Vector3) -> void:
	var ring := SlashFx.make(0.0, TAU, 0.2, 1.6, col_main, 0.3)
	get_parent().add_child(ring)
	ring.global_transform = Transform3D(Basis.IDENTITY, p + Vector3(0, 0.5, 0))
	Fx.flash_light(p + Vector3(0, 1.5, 0), col_main, 5.0, 5.0, 0.25)


func _set_state(s: String) -> void:
	state = s
	_st = 0.0
	match s:
		"windup":
			tele.visible = false
			match atk:
				"slash":
					_show_tele(_fan_mesh(deg_to_rad(130.0), 2.9), PARRY_COL)
				"jab":
					_show_tele(_fan_mesh(deg_to_rad(80.0), 2.5), PARRY_COL)
				"lunge":
					_line_len = minf(_dist_to_edge(_aim_dir), 9.0)
					_show_tele(_line_mesh(_line_len, 1.6), DANGER_COL)
				"pincer":
					_show_tele(_line_mesh(16.0, 1.3), DANGER_COL)
				"nova":
					_show_tele(_fan_mesh(TAU, 2.0), DANGER_COL)
				"blades":
					_show_tele(_fan_mesh(deg_to_rad(70.0), 7.0), DANGER_COL)
			Sfx.play("enemyattack", -8.0, 0.08, 0, 0.75 if who == "pollux" else 1.0)
		"act":
			_done = false
			_lunge_hit = false
			if atk != "lunge":
				tele.visible = false
		"recover":
			tele.visible = false
			_global_cd = randf_range(0.3, 0.7) / _spd()
			match atk:
				"slash":
					_cd["slash"] = 1.3
				"lunge":
					_cd["lunge"] = 4.5
				"blades":
					_cd["blades"] = 6.5
				"jab":
					_cd["jab"] = 1.2
				"starfall":
					_cd["starfall"] = 5.0
				"nova":
					_cd["nova"] = 7.0
		_:
			tele.visible = false


func _act(delta: float) -> Vector3:
	match atk:
		"slash", "jab":
			if not _done and _st >= 0.06:
				_done = true
				var slash := atk == "slash"
				_melee(2.9 if slash else 2.5, deg_to_rad(130.0 if slash else 80.0), (18.0 if slash else 14.0) * dmg_mult, true)
			if _st >= 0.15:
				_end_act()
			return _aim_dir * 6.0
		"lunge":
			var spd := 20.0
			if not _lunge_hit and hero != null and is_instance_valid(hero) and not hero.dead:
				var d: Vector3 = hero.global_position - global_position
				d.y = 0.0
				if d.length() < 1.3:
					var res: String = hero.take_damage(20.0 * dmg_mult, _aim_dir, false)
					if res == "hit":
						_lunge_hit = true
			if _st * spd >= _line_len - 0.2 or _st > 0.6:
				_set_state("recover")
				return Vector3.ZERO
			return _aim_dir * spd
		"blades":
			if not _done:
				_done = true
				for i in 5:
					var ang := deg_to_rad(70.0) * (float(i) / 4.0 - 0.5)
					var b = EnemyScript.Bolt.new()
					b.col = col_main
					b.speed = 13.0
					b.dmg = 12.0 * dmg_mult
					b.hero = hero
					b.dir = _aim_dir.rotated(Vector3.UP, ang)
					b.position = global_position + Vector3(0, 1.5, 0) + b.dir * 0.8
					get_parent().add_child(b)
				Sfx.play("swing", -4.0, 0.05, 0, 1.3)
			if _st >= 0.15:
				_set_state("recover")
		"starfall":
			if not _done:
				_done = true
				var fr = AriesScript.FireRain.new()
				fr.hero = hero
				fr.count = 3 if _phase() < 3 else 5
				fr.dmg = 20.0 * dmg_mult
				fr.bounds = _bounds
				get_parent().add_child(fr)
			if _st >= 0.2:
				_set_state("recover")
		"nova":
			if not _done:
				_done = true
				var ring = AriesScript.FireRing.new()
				ring.hero = hero
				ring.dmg = 18.0 * dmg_mult
				ring.max_r = 9.0
				ring.position = Vector3(global_position.x, 0.0, global_position.z)
				get_parent().add_child(ring)
				Fx.shake(0.3)
				Sfx.play("boom", -8.0, 0.0, 0, 1.1)
			if _st >= 0.25:
				_set_state("recover")
		"pincer":
			if not _done:
				_done = true
				_line_hit(16.0, 1.3, 22.0 * dmg_mult)
			if _st >= 0.25:
				_set_state("recover")
	return Vector3.ZERO


func _end_act() -> void:
	if _chain > 0 and hero != null and is_instance_valid(hero) and not hero.dead:
		_chain -= 1
		_chain_follow = true
		var to: Vector3 = hero.global_position - global_position
		to.y = 0.0
		if to.length() > 0.1:
			_aim_dir = to.normalized()
		_set_state("windup")
		return
	_chain_follow = false
	_set_state("recover")


func _melee(reach: float, arc: float, dmg: float, parryable: bool) -> void:
	var fx := SlashFx.make(-arc * 0.5, arc * 0.5, 0.5, reach, PARRY_COL if parryable else DANGER_COL, 0.2)
	get_parent().add_child(fx)
	fx.global_transform = Transform3D(Basis.looking_at(_aim_dir, Vector3.UP), global_position + Vector3(0, 1.3, 0))
	Sfx.play("swing", -6.0, 0.08, 0, 1.2 if who == "castor" else 0.8)
	if hero == null or not is_instance_valid(hero) or hero.dead:
		return
	var to: Vector3 = hero.global_position - global_position
	to.y = 0.0
	var dist := to.length()
	if dist > reach + 0.3:
		return
	if dist > 0.3 and _aim_dir.angle_to(to / dist) > arc * 0.5:
		return
	var res: String = hero.take_damage(dmg, to.normalized() if dist > 0.05 else _aim_dir, parryable)
	if res == "parried":
		stun(2.2, true)
		_knock = -_aim_dir * 5.0


func _line_hit(length: float, width: float, dmg: float) -> void:
	var beam := MeshInstance3D.new()
	var bx := BoxMesh.new()
	bx.size = Vector3(width, 0.5, length)
	beam.mesh = bx
	var bm := StandardMaterial3D.new()
	bm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	bm.albedo_color = Color(col_main.r, col_main.g, col_main.b, 0.8)
	beam.material_override = bm
	get_parent().add_child(beam)
	beam.global_transform = Transform3D(Basis.looking_at(_aim_dir, Vector3.UP), global_position + Vector3(0, 1.0, 0) + _aim_dir * length * 0.5)
	var tw := beam.create_tween()
	tw.tween_property(bm, "albedo_color:a", 0.0, 0.35)
	tw.tween_callback(beam.queue_free)
	Fx.shake(0.3)
	Sfx.play("boom", -8.0, 0.05, 0, 1.8)
	if hero == null or not is_instance_valid(hero) or hero.dead:
		return
	var v: Vector3 = hero.global_position - global_position
	v.y = 0.0
	var along := v.dot(_aim_dir)
	if along > 0.0 and along < length:
		var perp := (v - _aim_dir * along).length()
		if perp < width * 0.5 + 0.35:
			hero.take_damage(dmg, (v - _aim_dir * along).normalized() if perp > 0.05 else Vector3.RIGHT, false)


func stun(sec: float, parried := false) -> void:
	if down or gone:
		return
	if not parried and sec < 1.0:
		return
	_stun_len = sec if parried else sec * 0.5
	_parried = parried
	_chain = 0
	_set_state("stun")


func pull_to(_point: Vector3, _strength: float) -> void:
	pass


func apply_burn(dps: float, dur: float) -> void:
	_burn_dps = maxf(_burn_dps, dps)
	_burn_t = maxf(_burn_t, dur)


func enrage(on: bool) -> void:
	_enraged = on


# ---------------------------------------------------------------- hasar, düşme, ayağa kalkma

func take_hit(dmg: float, dir: Vector3, kb: float, heavy: bool, crit := false) -> void:
	last_dealt = 0.0
	if dead or gone or state == "intro":
		return
	var mult := 2.0 if (state == "stun" and _parried) else 1.0
	var final := dmg * mult
	last_dealt = final
	hp -= final
	_flash = 1.0
	HitFx.impact(get_parent(), global_position + Vector3(0, 1.6, 0) - dir * 0.6, dir, col_main.lerp(Color.WHITE, 0.5), heavy or crit)
	HitFx.number(get_parent(), global_position + Vector3(0, 3.2, 0), final, crit or mult > 1.0)
	Sfx.play("enemyhurt", -9.0, 0.08, 300, 0.8 if who == "castor" else 0.6)
	_knock = dir * kb * 0.15
	if hp <= 0.0:
		_fall()


## Yere düşer: dokunulmaz olur; kardeşi de düşmüşse ikisi birden yenilir
func _fall() -> void:
	if down or gone:
		return
	hp = 0.0
	down = true
	dead = true
	tele.visible = false
	_chain = 0
	state = "down"
	_st = 0.0
	_down_t = DOWN_TIME
	down_ring.visible = true
	Sfx.play("enemydie", -4.0, 0.05, 0, 0.6)
	Fx.flash_light(global_position + Vector3(0, 1.5, 0), col_main, 6.0, 8.0, 0.4)
	if ctrl != null and is_instance_valid(ctrl):
		ctrl.on_twin_down(self)


## Kardeşi onu ayağa kaldırır (canının %35'iyle)
func _revive() -> void:
	if gone:
		return
	down = false
	dead = false
	hp = max_hp * 0.35
	down_ring.visible = false
	_set_state("chase")
	_flash_fx(global_position)
	Sfx.play("bossroar", -6.0, 0.05, 0, 0.9)
	if ctrl != null and is_instance_valid(ctrl):
		ctrl.on_twin_revived(self)


## Son yenilgi: yıldız tozuna dağılır
func vanish() -> void:
	gone = true
	dead = true
	down = false
	tele.visible = false
	down_ring.visible = false
	hp_bar.visible = false
	remove_from_group("enemies")
	var tw := create_tween()
	for i in 4:
		tw.tween_callback(func():
			Fx.flash_light(global_position + Vector3(randf_range(-1, 1), randf_range(1, 3), randf_range(-1, 1)), col_main, 7.0, 8.0, 0.3)
			Sfx.play("boom", -10.0, 0.2, 0, 1.4))
		tw.tween_interval(0.2)
	tw.tween_property(vis, "scale", Vector3(1.6, 0.05, 1.6), 0.4)
	tw.tween_callback(queue_free)


# ---------------------------------------------------------------- animasyon

func _animate(delta: float) -> void:
	body_root.rotation.y = lerp_angle(body_root.rotation.y, atan2(-_face.x, -_face.z), minf(12.0 * delta, 1.0))
	var lean := 0.0
	var ax_l := 0.2
	var ax_r := 0.2
	var py := 0.0
	var glow := 5.0
	var spd := Vector2(velocity.x, velocity.z).length()
	var walk := sin(_t * 9.0) * minf(spd / 4.0, 1.0)
	ax_l += walk * 0.5
	ax_r -= walk * 0.5
	match state:
		"windup":
			var k := clampf(_st / maxf(_windup_len(), 0.01), 0.0, 1.0)
			glow = 5.0 + 15.0 * k
			match atk:
				"slash":
					ax_r = 2.6 * k
					lean = -0.15 * k
				"jab":
					ax_r = -0.6 * k
					ax_l = 1.2 * k
					lean = -0.1 * k
				"lunge", "pincer":
					ax_r = -0.4 * k
					lean = 0.45 * k
					py = -0.15 * k
				"blades":
					ax_r = 2.9 * k
					ax_l = 2.9 * k
				"starfall", "nova":
					ax_l = 3.0 * k
					ax_r = 3.0 * k
					py = 0.3 * k
		"act":
			glow = 18.0
			match atk:
				"slash":
					ax_r = -0.9
					lean = 0.35
				"jab":
					ax_r = 1.6
					lean = 0.3
				"lunge":
					ax_r = 1.4
					lean = 0.6
				_:
					ax_l = 1.4
					ax_r = 1.4
		"down":
			lean = 0.8
			py = -0.5
			ax_l = -0.2
			ax_r = -0.2
			glow = 1.0 + sin(_t * 6.0) * 0.8
		"stun":
			lean = 0.3
			glow = 1.5
	var sp := minf(16.0 * delta, 1.0)
	vis.rotation.x = lerpf(vis.rotation.x, lean, sp)
	if state != "intro":
		vis.position.y = lerpf(vis.position.y, py + sin(_t * 2.0) * 0.04, sp)
	arm_l.rotation.x = lerpf(arm_l.rotation.x, ax_l, sp)
	arm_r.rotation.x = lerpf(arm_r.rotation.x, ax_r, sp)
	m_eye.emission_energy_multiplier = glow
	var base_e := col_main * 0.5
	if _enraged:
		base_e = Color(1.0, 0.2, 0.15)
	m_body.emission = base_e.lerp(Color(1, 1, 1), _flash)
	m_body.emission_energy_multiplier = 0.3 + _flash * 3.0 + (0.8 if _enraged else 0.0)
	hp_mat.set_shader_parameter("fill", clampf(hp / max_hp, 0.0, 1.0))
	hp_mat.set_shader_parameter("stunned", 1.0 if state == "stun" or down else 0.0)
