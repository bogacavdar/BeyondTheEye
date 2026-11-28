extends CharacterBody3D
## İLK BOSS · KOÇ (gölge yanı: öfke, sabırsızlık, durmaksızın hücum)
## Koç burcunun bozulmuş hâli: ateş elementi, yönetici gezegen Mars. Boynuzları kıvrık, yelesi alev.
## EVRE 1 (%100-60): boynuz savuruşu (ALTIN, parry'lenir) · hücum (KIZIL çizgi, kaç) · yere vurma (KIZIL daire)
## EVRE 2 (%60-25): +2'li hücum · genişleyen ateş halkası (içinden atılarak geç) · yardımcı Gölgeler çağırır
## EVRE 3 (%25-0): öfke: daha hızlı, 3'lü hücum · gökten alev yağmuru (yerdeki dairelerden kaç)
## Son hücumdan sonra sendeler: vurma fırsatı. Parry'lenen savuruş onu 2 sn sersemletir (2 kat hasar).
## EVRE 4 (sadece TAM TUTULMA laneti açıksa, %12-0): ateş halkası ve alev yağmuru birlikte, en yüksek hız.

signal killed(enemy)
signal summon(kinds: Array)
signal phase_changed(p: int)

const JuiceS = preload("res://scripts/juice.gd")
const GameData = preload("res://scripts/game_data.gd")
const SlashFx = preload("res://scripts/slash_fx.gd")
const Skills = preload("res://scripts/star_skills.gd")
const HitFx = preload("res://scripts/hit_fx.gd")
const PARRY_COL := Color(1.0, 0.72, 0.2)
const DANGER_COL := Color(1.0, 0.1, 0.18)

var kind := "aries"
var title := "ARIES  ·  THE RAM'S FURY"
var last_dealt := 0.0
var dmg_mult := 1.0          # Mars retrosu
var windup_mult := 1.0       # Plüton retrosu
var total_eclipse := false   # Tam Tutulma: 4. evre
var max_hp := 1400.0
var hp := 1400.0
var radius := 1.1
var size_k := 1.0
var dead := false
var hero = null
var _bounds := 10.0
var state := "intro"
## BOSS EVRE ALT SÜRESİ (GDD §13.6): her evre en az 6 sn (gerçek zaman); süre dolmadan can evre eşiğinin altına inmez
const PHASE_MIN_T := 6.0
var phase_th: Array = [0.6, 0.25]   # evre bitiş eşikleri (alt sınıflar _init içinde yazar)
var _phase_t0 := 0.0
var phase := 1:
	set(v):
		phase = v
		_phase_t0 = Fx.unscaled_t


## Evre tabanı: evre başlayalı 6 sn olmadıysa can bu değerin altına inemez (son evrede 1, yani ölemez)
func _phase_floor() -> float:
	var i := phase - 1
	var has_th := i >= 0 and i < phase_th.size()
	if Fx.unscaled_t - _phase_t0 >= PHASE_MIN_T:
		# süre doldu: can eşiğin hemen altına iner (sonraki evre başlar) ama fazla hasar sonraki evreye taşınmaz
		return float(phase_th[i]) * max_hp - 1.0 if has_th else 0.0
	if has_th:
		return float(phase_th[i]) * max_hp
	return 1.0
var _st := 0.0
var _t := 0.0
var _face := Vector3.FORWARD
var _knock := Vector3.ZERO
var _move := Vector3.ZERO
var _flash := 0.0
var _cd := {"swipe": 0.5, "charge": 2.0, "stomp": 3.0, "ring": 1.0, "rain": 1.0}
var _global_cd := 1.0
var atk := ""
var _aim_dir := Vector3.FORWARD
var _done := false
var _charges_left := 0
var _charge_len := 0.0
var _charge_traveled := 0.0
var _charge_hit := false
var _stun_len := 0.0
var _parried := false
var _burn_t := 0.0
var _burn_dps := 0.0
var _burn_acc := 0.0

var body_root: Node3D
var vis: Node3D
var head: Node3D
var arm_l: Node3D
var arm_r: Node3D
var tele: MeshInstance3D
var tele_mat: StandardMaterial3D
var m_body: StandardMaterial3D
var m_eye: StandardMaterial3D
var m_horn: StandardMaterial3D
var mane: CPUParticles3D

const SWIPE := {"windup": 0.65, "act": 0.18, "recover": 0.62, "dmg": 24.0, "reach": 3.9, "arc": 155.0}
const STOMP := {"windup": 0.95, "act": 0.2, "recover": 0.75, "dmg": 26.0, "reach": 4.5}


func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 4
	collision_mask = 0
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	hp = max_hp
	if total_eclipse and phase_th == [0.6, 0.25]:
		phase_th = [0.6, 0.25, 0.12]   # Koç, Tam Tutulma: 4. evre
	_build()
	vis.position.y = -4.0
	var tw := create_tween()
	tw.tween_property(vis, "position:y", 0.0, 1.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# ---------------------------------------------------------------- görünüş

func _m(c: Color, rough := 0.6, metal := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	return load("res://scripts/toon.gd").style(m)


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
	c.radial_segments = 12
	return c


func _build() -> void:
	m_body = _m(Color(0.12, 0.03, 0.04))
	m_body.emission_enabled = true
	m_body.emission = Color(0.6, 0.08, 0.05)
	m_body.emission_energy_multiplier = 0.35
	var gold := _m(Color(0.95, 0.78, 0.38), 0.3, 0.9)
	m_horn = _m(Color(0.85, 0.7, 0.45), 0.4, 0.4)
	m_horn.emission_enabled = true
	m_horn.emission = Color(1.0, 0.5, 0.2)
	m_horn.emission_energy_multiplier = 0.2
	m_eye = StandardMaterial3D.new()
	m_eye.albedo_color = Color.BLACK
	m_eye.emission_enabled = true
	m_eye.emission = Color(1.0, 0.55, 0.15)
	m_eye.emission_energy_multiplier = 5.0

	body_root = Node3D.new()
	add_child(body_root)
	vis = Node3D.new()
	body_root.add_child(vis)
	# toynaklı bacaklar
	for s in [-1.0, 1.0]:
		_part(vis, _cone(0.28, 0.22, 1.3), Vector3(s * 0.45, 0.85, 0), m_body)
		_part(vis, _cone(0.3, 0.3, 0.25), Vector3(s * 0.45, 0.12, -0.05), gold)
	# gövde ve altın göğüs zırhı
	_part(vis, _sph(0.85), Vector3(0, 2.2, 0), m_body, Vector3(1.25, 1.1, 0.9))
	_part(vis, _sph(0.6), Vector3(0, 2.35, -0.42), gold, Vector3(1.3, 1.0, 0.35))
	_part(vis, _cone(0.75, 0.55, 0.5), Vector3(0, 1.45, 0), m_body)
	# koç burcu sembolü göğüste (♈ biçimi: iki kıvrık çizgi)
	for s in [-1.0, 1.0]:
		var t := TorusMesh.new()
		t.inner_radius = 0.13
		t.outer_radius = 0.17
		var tm := _part(vis, t, Vector3(s * 0.15, 2.5, -0.65), m_eye)
		tm.rotation.x = PI * 0.5
	# baş: uzun koç burnu
	head = Node3D.new()
	head.position = Vector3(0, 3.2, -0.35)
	vis.add_child(head)
	_part(head, _sph(0.42), Vector3.ZERO, m_body, Vector3(0.85, 0.9, 1.0))
	_part(head, _sph(0.28), Vector3(0, -0.15, -0.4), m_body, Vector3(0.85, 0.8, 1.2))
	for s in [-1.0, 1.0]:
		_part(head, _sph(0.07), Vector3(s * 0.2, 0.08, -0.32), m_eye, Vector3(1.3, 0.7, 1.0))
		# kıvrık boynuz: spiral boyunca küçülen küreler
		for k in 9:
			var a := float(k) * 0.62
			var r := 0.32 + float(k) * 0.035
			var p := Vector3(s * (0.3 + r * 0.55 + float(k) * 0.03), 0.15 + sin(a) * r, cos(a) * r * 0.9 + 0.1)
			_part(head, _sph(0.17 - float(k) * 0.012), p, m_horn)
	# kollar ve yumruklar
	arm_l = _arm(-1.0, gold)
	arm_r = _arm(1.0, gold)
	# alev yelesi
	mane = CPUParticles3D.new()
	mane.amount = 40
	mane.lifetime = 0.8
	var pm := SphereMesh.new()
	pm.radius = 0.12
	pm.height = 0.24
	mane.mesh = pm
	var fm := StandardMaterial3D.new()
	fm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fm.albedo_color = Color(1.0, 0.45, 0.12)
	fm.emission_enabled = true
	fm.emission = Color(1.0, 0.4, 0.1)
	fm.emission_energy_multiplier = 4.0
	mane.material_override = fm
	mane.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	mane.emission_sphere_radius = 0.5
	mane.direction = Vector3.UP
	mane.spread = 25.0
	mane.gravity = Vector3(0, 2.0, 0)
	mane.initial_velocity_min = 0.5
	mane.initial_velocity_max = 1.5
	mane.scale_amount_min = 0.4
	mane.scale_amount_max = 1.0
	mane.position = Vector3(0, 3.0, 0.35)
	vis.add_child(mane)
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.45, 0.2)
	l.light_energy = 2.0
	l.omni_range = 7.0
	l.position = Vector3(0, 3.0, 0)
	vis.add_child(l)
	_try_ai_model()


## PİLOT: portreden üretilmiş 3D model (TRELLIS.2). Varsa basit parçaları gizler, modeli koyar.
const AI_MODEL := "res://assets/models3d/aries_boss.glb"

func _try_ai_model() -> void:
	if get_script() != load("res://scripts/aries_boss.gd") or not ResourceLoader.exists(AI_MODEL):
		return
	var ps := load(AI_MODEL) as PackedScene
	if ps == null:
		return
	for c in vis.get_children():
		if c is MeshInstance3D or c == head:
			c.visible = false
	arm_l.visible = false
	arm_r.visible = false
	var m := ps.instantiate() as Node3D
	m.scale = Vector3.ONE * 4.4
	m.position = Vector3(0, 2.19, 0)
	mane.visible = false
	m.rotation.y = PI
	vis.add_child(m)

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


func _arm(side: float, gold: Material) -> Node3D:
	var sh := Node3D.new()
	sh.position = Vector3(side * 1.1, 2.6, 0)
	vis.add_child(sh)
	_part(sh, _sph(0.32), Vector3.ZERO, gold, Vector3(1.2, 0.8, 1.0))
	_part(sh, _cone(0.16, 0.22, 1.2), Vector3(0, -0.6, 0), m_body)
	_part(sh, _sph(0.3), Vector3(0, -1.3, 0), m_body)
	sh.rotation.z = side * 0.2
	return sh


# ---------------------------------------------------------------- uyarı geometrisi

func _fan_mesh(arc: float, reach: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := 32
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
	var cols := [Color(1, 1, 1, 0.9), Color(1, 1, 1, 0.9), Color(1, 1, 1, 0.35), Color(1, 1, 1, 0.35)]
	for idx in [0, 1, 2, 0, 2, 3]:
		st.set_color(cols[idx])
		st.add_vertex(pts[idx])
	return st.commit()


func _show_tele(mesh: Mesh, col: Color) -> void:
	tele.mesh = mesh
	tele_mat.albedo_color = Color(col.r, col.g, col.b, 0.2)
	tele.visible = true
	JuiceS.tele_fill(tele, col)
	_place_tele()


func _place_tele() -> void:
	var b := Basis.looking_at(_aim_dir, Vector3.UP) if _aim_dir.length() > 0.1 else Basis.IDENTITY
	if atk == "stomp":
		b = Basis.IDENTITY
	tele.global_transform = Transform3D(b, Vector3(global_position.x, 0.07, global_position.z))


## Bulunduğu yerden bir yöne arenanın kenarına kadar olan mesafe
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

func _speed_mult() -> float:
	match phase:
		1:
			return 1.0
		2:
			return 1.15
		3:
			return 1.35
	return 1.55


func _physics_process(delta: float) -> void:
	if puppet:
		_puppet_tick(delta)
		return
	_t += delta
	_st += delta
	_global_cd -= delta
	for k in _cd:
		_cd[k] = float(_cd[k]) - delta
	_flash = maxf(_flash - delta * 6.0, 0.0)
	if dead:
		return
	_tick_burn(delta)
	if dead:
		return
	# dolan uyarı
	if state == "windup" and tele != null and tele.visible:
		JuiceS.tele_progress(tele, _st / maxf(_windup_len(), 0.01))
	var hero_ok: bool = hero != null and is_instance_valid(hero) and not hero.dead
	var to := Vector3.ZERO
	var dist := 99.0
	if hero_ok:
		to = hero.global_position - global_position
		to.y = 0.0
		dist = to.length()
	var dir_to := to.normalized() if dist > 0.05 else _face
	var sm := _speed_mult()
	var want := Vector3.ZERO

	match state:
		"intro":
			if _st > 1.6:
				_phase_t0 = Fx.unscaled_t   # 1. evre girişten sonra başlar
				_set_state("chase")
		"roar":
			# evre geçişi: kükrer, kısa süre dokunulmaz
			if _st > 1.3:
				_set_state("chase")
		"chase":
			if hero_ok:
				_face = _face.slerp(dir_to, minf(6.0 * delta, 1.0)).normalized()
				want = _chase_vel(dist, dir_to, sm)
				if _global_cd <= 0.0:
					_pick(dist, dir_to)
		"windup":
			var w := _windup_len()
			if hero_ok and _st < w * 0.65:
				_aim_dir = _aim_dir.slerp(dir_to, minf(6.0 * delta, 1.0)).normalized()
			_face = _aim_dir
			if atk == "charge":
				_charge_len = minf(_dist_to_edge(_aim_dir), 20.0)
				tele.mesh = _line_mesh(_charge_len, 2.6)
			_place_tele()
			var pulse := 0.0 if atk == "swipe" else 0.25 * (0.5 + 0.5 * sin(_t * 26.0))
			tele_mat.albedo_color.a = 0.15 + 0.55 * (_st / w) + pulse
			if _st >= w:
				_set_state("act")
		"act":
			want = _act(delta, sm)
		"recover":
			if _st >= _recover_len():
				_set_state("chase")
		"stun":
			if _st >= _stun_len:
				_set_state("chase")

	_knock = _knock.move_toward(Vector3.ZERO, 30.0 * delta)
	if not (state == "act" and atk == "charge"):
		_move = _move.move_toward(want, 20.0 * delta)
	velocity = _move + _knock
	move_and_slide()
	var flat := Vector2(global_position.x, global_position.z)
	if flat.length() > _bounds:
		flat = flat.normalized() * _bounds
		global_position = Vector3(flat.x, 0.0, flat.y)
	global_position.y = 0.0
	_animate(delta)


## Kovalama hızı (alt sınıflar değiştirebilir: ör. mesafe koruyan okçu)
func _chase_vel(dist: float, dir_to: Vector3, sm: float) -> Vector3:
	if dist > 2.8:
		return dir_to * 3.0 * sm
	return Vector3.ZERO


func _windup_len() -> float:
	var k := windup_mult / _speed_mult()
	match atk:
		"swipe":
			return float(SWIPE["windup"]) * k
		"charge":
			return (0.85 if _charges_left <= 0 else 0.48) * k
		"stomp":
			return float(STOMP["windup"]) * k
		"ring":
			return 0.8 * k
		"rain":
			return 0.7 * k
	return 0.6


func _recover_len() -> float:
	match atk:
		"swipe":
			return float(SWIPE["recover"]) / _speed_mult()
		"charge":
			return 1.0     # son hücumdan sonra sendeler: vurma fırsatı
		"stomp":
			return float(STOMP["recover"])
	return 0.6


func _pick(dist: float, dir_to: Vector3) -> void:
	var opts: Array = []
	if float(_cd["swipe"]) <= 0.0 and dist < 3.8:
		opts.append_array(["swipe", "swipe", "swipe"])
	if float(_cd["stomp"]) <= 0.0 and dist < 4.2:
		opts.append("stomp")
	if float(_cd["charge"]) <= 0.0 and dist > 3.0:
		opts.append_array(["charge", "charge"])
	if phase >= 2 and float(_cd["ring"]) <= 0.0:
		opts.append("ring")
	if phase >= 3 and float(_cd["rain"]) <= 0.0:
		opts.append("rain")
	if opts.is_empty():
		return
	atk = String(opts[randi() % opts.size()])
	_aim_dir = dir_to
	if atk == "charge":
		_charges_left = phase - 1      # evre 2: +1, evre 3: +2 hücum
	_set_state("windup")


func _set_state(s: String) -> void:
	state = s
	_st = 0.0
	match s:
		"windup":
			match atk:
				"swipe":
					_show_tele(_fan_mesh(deg_to_rad(float(SWIPE["arc"])), float(SWIPE["reach"])), PARRY_COL)
				"charge":
					_charge_len = minf(_dist_to_edge(_aim_dir), 20.0)
					_show_tele(_line_mesh(_charge_len, 2.6), DANGER_COL)
				"stomp":
					_show_tele(_fan_mesh(TAU, float(STOMP["reach"])), DANGER_COL)
				_:
					tele.visible = false
			Sfx.play("bossroar", -4.0 if atk != "swipe" else -9.0, 0.08, 0, 0.7)
		"act":
			_done = false
			_charge_traveled = 0.0
			_charge_hit = false
			if atk != "charge":
				tele.visible = false
			Sfx.play("dash", -6.0, 0.1, 0, 0.6)
		"recover":
			tele.visible = false
			_global_cd = randf_range(0.2, 0.55) / _speed_mult()
			match atk:
				"swipe":
					_cd["swipe"] = 1.3
				"charge":
					_cd["charge"] = 4.5
				"stomp":
					_cd["stomp"] = 5.0
				"ring":
					_cd["ring"] = 7.0 if phase < 4 else 3.5
				"rain":
					_cd["rain"] = 8.0 if phase < 4 else 4.0
		_:
			tele.visible = false


func _act(delta: float, sm: float) -> Vector3:
	match atk:
		"swipe":
			if not _done and _st >= 0.07:
				_done = true
				_swipe_hit()
			if _st >= float(SWIPE["act"]):
				_set_state("recover")
			return _aim_dir * 6.0
		"charge":
			var spd := 22.0 * sm
			var step := spd * delta
			_charge_traveled += step
			_move = _aim_dir * spd
			if not _charge_hit and hero != null and is_instance_valid(hero) and not hero.dead:
				var d: Vector3 = hero.global_position - global_position
				d.y = 0.0
				if d.length() < 1.6:
					var res: String = hero.take_damage(30.0 * dmg_mult, _aim_dir, false)
					if res == "hit":
						_charge_hit = true
			if _charge_traveled >= _charge_len - 0.3 or _st > 1.6:
				_move = Vector3.ZERO
				Fx.shake(0.35)
				Sfx.play("boom", -12.0, 0.1, 0, 1.6)
				var ring := SlashFx.make(0.0, TAU, 0.3, 2.2, DANGER_COL, 0.3)
				get_parent().add_child(ring)
				ring.global_transform = Transform3D(Basis.IDENTITY, global_position + Vector3(0, 0.3, 0))
				if _charges_left > 0:
					_charges_left -= 1
					if hero != null and is_instance_valid(hero):
						var nd: Vector3 = hero.global_position - global_position
						nd.y = 0.0
						if nd.length() > 0.5:
							_aim_dir = nd.normalized()
					_set_state("windup")
				else:
					_set_state("recover")
			return _move
		"stomp":
			if not _done and _st >= 0.1:
				_done = true
				_area_hit(global_position, float(STOMP["reach"]), float(STOMP["dmg"]) * dmg_mult)
			if _st >= float(STOMP["act"]):
				_set_state("recover")
		"ring":
			if not _done:
				_done = true
				var fr := FireRing.new()
				fr.hero = hero
				fr.dmg *= dmg_mult
				if phase >= 4:
					# tam tutulma: halka ve yağmur birlikte
					var rn2 := FireRain.new()
					rn2.hero = hero
					rn2.bounds = _bounds
					rn2.dmg *= dmg_mult
					get_parent().add_child(rn2)
				fr.position = Vector3(global_position.x, 0.0, global_position.z)
				get_parent().add_child(fr)
				Fx.shake(0.3)
				Sfx.play("boom", -10.0, 0.0, 0, 0.9)
			if _st >= 0.3:
				_set_state("recover")
		"rain":
			if not _done:
				_done = true
				var rn := FireRain.new()
				rn.hero = hero
				rn.dmg *= dmg_mult
				rn.bounds = _bounds
				get_parent().add_child(rn)
			if _st >= 0.3:
				_set_state("recover")
	return Vector3.ZERO


func _swipe_hit() -> void:
	var reach := float(SWIPE["reach"])
	var arc := deg_to_rad(float(SWIPE["arc"]))
	var fx := SlashFx.make(-arc * 0.5, arc * 0.5, 0.6, reach, PARRY_COL, 0.22)
	get_parent().add_child(fx)
	fx.global_transform = Transform3D(Basis.looking_at(_aim_dir, Vector3.UP), global_position + Vector3(0, 1.4, 0))
	if hero == null or not is_instance_valid(hero) or hero.dead:
		return
	var to: Vector3 = hero.global_position - global_position
	to.y = 0.0
	var dist := to.length()
	if dist > reach + 0.3:
		return
	if dist > 0.3 and _aim_dir.angle_to(to / dist) > arc * 0.5:
		return
	var res: String = hero.take_damage(float(SWIPE["dmg"]) * dmg_mult, to.normalized() if dist > 0.05 else _aim_dir, true)
	if res == "parried":
		stun(2.2, true)
		_knock = -_aim_dir * 4.0


func _area_hit(center: Vector3, r: float, dmg: float) -> void:
	var ring := SlashFx.make(0.0, TAU, r * 0.25, r, DANGER_COL, 0.35)
	get_parent().add_child(ring)
	ring.global_transform = Transform3D(Basis.IDENTITY, center + Vector3(0, 0.3, 0))
	Fx.shake(0.5)
	Fx.flash_light(center + Vector3(0, 1, 0), Color(1.0, 0.4, 0.15), 6.0, r * 2.5, 0.3)
	Sfx.play("boom", -8.0, 0.1, 0, 1.2)
	if hero == null or not is_instance_valid(hero) or hero.dead:
		return
	var to: Vector3 = hero.global_position - center
	to.y = 0.0
	if to.length() <= r + 0.3:
		hero.take_damage(dmg, to.normalized() if to.length() > 0.05 else Vector3.FORWARD, false)


func stun(sec: float, parried := false) -> void:
	# boss hafif sersemletmelerden etkilenmez; sadece parry ve güçlü sersemletmeler işler
	if not parried and sec < 1.0:
		return
	_stun_len = sec if parried else sec * 0.5
	_parried = parried
	_charges_left = 0
	_set_state("stun")


func pull_to(_point: Vector3, _strength: float) -> void:
	pass   # Koç çekilemez


func apply_burn(dps: float, dur: float) -> void:
	_burn_dps = maxf(_burn_dps, dps)
	_burn_t = maxf(_burn_t, dur)


func _tick_burn(delta: float) -> void:
	if _burn_t <= 0.0:
		return
	_burn_t -= delta
	_burn_acc += _burn_dps * delta
	if _burn_acc >= 2.0:
		var d := _burn_acc
		_burn_acc = 0.0
		_damage(d)


# ---------------------------------------------------------------- hasar

func take_hit(dmg: float, dir: Vector3, kb: float, heavy: bool, crit := false) -> void:
	if puppet:
		Net.send_hit(self, dmg, dir, kb, heavy, crit)
		_flash = 1.0
		return
	last_dealt = 0.0
	if dead or state == "intro" or state == "roar":
		return
	var Elm = load("res://scripts/elements.gd")
	var elm: float = Elm.mult(GameData.hero_el, GameData.hero_el_n, String(Elm.ZONE_EL.get(kind, "")))
	dmg *= elm
	# boss hasarı (Doğum Haritası "Boss Damage", Tutulma tılsımı)
	if hero != null and is_instance_valid(hero) and hero.get("st") != null:
		dmg *= 1.0 + float(hero.st.get("boss_dmg", 0.0)) / 100.0
	if elm > 1.0:
		crit = true
	var mult := 2.0 if (state == "stun" and _parried) else 1.0
	last_dealt = dmg * mult
	_flash = 1.0
	HitFx.impact(get_parent(), global_position + Vector3(0, 2.0, 0) - dir * 0.8, dir, Color(1.0, 0.7, 0.4), heavy or crit)
	HitFx.number(get_parent(), global_position + Vector3(0, 4.0, 0), dmg * mult, crit or mult > 1.0)
	Sfx.play("enemyhurt", -8.0, 0.08, 450, 0.55)
	_knock = dir * kb * 0.12
	var p := global_position + Vector3(0, 2.2, 0)
	_stardust(p, dir, 10 if heavy else 6)
	_damage(dmg * mult)


func _damage(d: float) -> void:
	hp -= d
	hp = maxf(hp, _phase_floor())
	if hp <= 0.0:
		_die()
		return
	if phase == 1 and hp < max_hp * 0.6:
		_enter_phase(2)
	elif phase == 2 and hp < max_hp * 0.25:
		_enter_phase(3)
	elif phase == 3 and total_eclipse and hp < max_hp * 0.12:
		_enter_phase(4)


func _enter_phase(p: int) -> void:
	phase = p
	_charges_left = 0
	tele.visible = false
	_set_state("roar")
	Fx.shake(0.7)
	Fx.flash_light(global_position + Vector3(0, 3, 0), Color(1.0, 0.4, 0.15), 10.0, 16.0, 0.8)
	Sfx.play("bossroar", 0.0, 0.0, 0, 0.55)
	Sfx.play("bruteroar", -4.0, 0.0, 0, 0.6)
	var ring := SlashFx.make(0.0, TAU, 0.5, 6.0, Color(1.0, 0.45, 0.15), 0.5)
	get_parent().add_child(ring)
	ring.global_transform = Transform3D(Basis.IDENTITY, global_position + Vector3(0, 0.3, 0))
	# evre geçişinde yakındaki kahramanı it
	if hero != null and is_instance_valid(hero) and not hero.dead:
		var d: Vector3 = hero.global_position - global_position
		d.y = 0.0
		if d.length() < 4.0:
			hero.velocity = d.normalized() * 14.0
	mane.amount = 40 if p == 1 else (70 if p == 2 else (110 if p == 3 else 160))
	m_eye.emission = Color(1.0, 0.55, 0.15) if p < 3 else (Color(1.0, 0.15, 0.1) if p == 3 else Color(1.0, 0.9, 0.85))
	if p == 4:
		summon.emit(["leaper", "caster"])
	elif p == 2:
		summon.emit(["shade", "caster"])
	elif p == 3:
		summon.emit(["leaper", "shade"])
	phase_changed.emit(p)


func _stardust(p: Vector3, dir: Vector3, n: int) -> void:
	var m: StandardMaterial3D = Fx.emissive(Color(1.0, 0.85, 0.55), 5.0)
	var s := SphereMesh.new()
	s.radius = 0.045
	s.height = 0.09
	Fx._burst(p, (dir + Vector3(0, 0.6, 0)).normalized(), n, m, s, 2.5, 7.0, 50.0, -4.0, 0.6, 0.6, 1.5)


func _die() -> void:
	dead = true
	state = "dead"
	tele.visible = false
	remove_from_group("enemies")
	mane.emitting = false
	killed.emit(self)
	# büyük ölüm: art arda patlamalar, sonra yıldız tozuna dağılır
	var tw := create_tween()
	for i in 6:
		tw.tween_callback(_death_pop)
		tw.tween_interval(0.22)
	tw.tween_property(vis, "scale", Vector3(1.6, 0.05, 1.6), 0.4).set_ease(Tween.EASE_IN)
	tw.tween_callback(queue_free)


func _death_pop() -> void:
	var p := global_position + Vector3(randf_range(-1, 1), randf_range(1.0, 3.5), randf_range(-1, 1))
	_stardust(p, Vector3.UP, 30)
	Fx.flash_light(p, Color(1.0, 0.8, 0.45), 8.0, 10.0, 0.3)
	Fx.shake(0.5)
	Sfx.play("boom", -8.0, 0.2, 0, 1.4)


# ---------------------------------------------------------------- animasyon

func _animate(delta: float) -> void:
	body_root.rotation.y = lerp_angle(body_root.rotation.y, atan2(-_face.x, -_face.z), minf(10.0 * delta, 1.0))
	var lean := 0.0
	var arms := 0.2
	var glow := 5.0
	match state:
		"windup":
			var k := clampf(_st / _windup_len(), 0.0, 1.0)
			match atk:
				"charge":
					lean = 0.5 * k        # başını eğer, boynuzlarını öne verir
					arms = -0.3
				"stomp", "ring":
					lean = -0.2 * k
					arms = 2.6 * k
				_:
					lean = -0.15 * k
					arms = 1.8 * k
			glow = 5.0 + 10.0 * k
		"act":
			lean = 0.55 if atk == "charge" else 0.3
			arms = -1.3
			glow = 14.0
		"roar":
			lean = -0.4
			arms = 2.4
			glow = 18.0
		"stun":
			lean = 0.3
			arms = 0.0
			glow = 1.5
	vis.rotation.x = lerpf(vis.rotation.x, lean, minf(10.0 * delta, 1.0))
	arm_l.rotation.x = lerpf(arm_l.rotation.x, arms, minf(12.0 * delta, 1.0))
	arm_r.rotation.x = lerpf(arm_r.rotation.x, arms, minf(12.0 * delta, 1.0))
	head.rotation.x = lerpf(head.rotation.x, lean * 0.8, minf(10.0 * delta, 1.0))
	m_eye.emission_energy_multiplier = glow
	m_body.emission = Color(0.6, 0.08, 0.05).lerp(Color(1.0, 0.95, 0.85), _flash)
	m_body.emission_energy_multiplier = 0.35 + _flash * 3.0 + (0.4 if _burn_t > 0.0 else 0.0)


# ---------------------------------------------------------------- ateş halkası (evre 2+)

class FireRing extends Node3D:
	var hero = null
	var max_r := 13.0
	var dur := 1.9
	var dmg := 20.0
	var _t := 0.0
	var _hit := false
	var _ring: MeshInstance3D
	var _mat: StandardMaterial3D

	func _ready() -> void:
		_ring = MeshInstance3D.new()
		var t := TorusMesh.new()
		t.inner_radius = 0.95
		t.outer_radius = 1.0
		t.rings = 96
		t.ring_segments = 8
		_ring.mesh = t
		_mat = StandardMaterial3D.new()
		_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		_mat.albedo_color = Color(1.0, 0.35, 0.1, 1.0)
		_ring.material_override = _mat
		_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(_ring)

	func _physics_process(delta: float) -> void:
		_t += delta
		var r := maxf(_t / dur * max_r, 0.1)
		_ring.scale = Vector3(r, 12.0, r)
		_ring.position.y = 0.3
		_mat.albedo_color.a = 1.0 - clampf((_t - dur * 0.8) / (dur * 0.2), 0.0, 1.0)
		if not _hit and hero != null and is_instance_valid(hero) and not hero.dead:
			var d: Vector3 = hero.global_position - global_position
			d.y = 0.0
			if absf(d.length() - r) < 0.55:
				var res: String = hero.take_damage(dmg, d.normalized() if d.length() > 0.05 else Vector3.FORWARD, false)
				if res == "hit":
					_hit = true
		if _t >= dur:
			queue_free()


# ---------------------------------------------------------------- alev yağmuru (evre 3)

class FireRain extends Node3D:
	var hero = null
	var bounds := 10.0
	var count := 7
	var dmg := 20.0
	var radius := 1.8
	var _t := 0.0
	var _drops: Array = []     # [konum, patlama zamanı, halka, patladı mı]

	func _ready() -> void:
		var lib = load("res://scripts/star_skills.gd")
		for i in count:
			var p := Vector3.ZERO
			if i == 0 and hero != null and is_instance_valid(hero):
				p = hero.global_position
			elif hero != null and is_instance_valid(hero):
				p = hero.global_position + Vector3(randf_range(-4.5, 4.5), 0, randf_range(-4.5, 4.5))
			var fl := Vector2(p.x, p.z)
			if fl.length() > bounds:
				fl = fl.normalized() * bounds
			p = Vector3(fl.x, 0.0, fl.y)
			var ring: MeshInstance3D = lib.ring(radius, Color(1.0, 0.12, 0.15, 0.9))
			add_child(ring)
			ring.global_position = p + Vector3(0, 0.06, 0)
			ring.scale = Vector3(0.2, 0.1, 0.2)
			_drops.append([p, 1.0 + float(i) * 0.22, ring, false])

	func _physics_process(delta: float) -> void:
		_t += delta
		var all_done := true
		for dr in _drops:
			if bool(dr[3]):
				continue
			all_done = false
			var at: float = dr[1]
			var ring: MeshInstance3D = dr[2]
			var k := clampf(_t / at, 0.0, 1.0)
			ring.scale = Vector3(0.2 + 0.8 * k, 0.1, 0.2 + 0.8 * k)
			if _t >= at:
				dr[3] = true
				ring.visible = false
				var p: Vector3 = dr[0]
				var ex = load("res://scripts/slash_fx.gd").make(0.0, TAU, 0.2, radius, Color(1.0, 0.4, 0.12), 0.35)
				get_parent().add_child(ex)
				ex.global_transform = Transform3D(Basis.IDENTITY, p + Vector3(0, 0.4, 0))
				Fx.flash_light(p + Vector3(0, 1, 0), Color(1.0, 0.4, 0.15), 5.0, 5.0, 0.25)
				Sfx.play("boom", -14.0, 0.2, 30, 1.6)
				if hero != null and is_instance_valid(hero) and not hero.dead:
					var d: Vector3 = hero.global_position - p
					d.y = 0.0
					if d.length() <= radius + 0.25:
						hero.take_damage(dmg, d.normalized() if d.length() > 0.05 else Vector3.FORWARD, false)
		if all_done:
			queue_free()

# ---------------------------------------------------------------- ÇEVRİM İÇİ: kukla (client'taki kopya)
## Client'ta yapay zekâ çalışmaz; host'un anlık görüntüsüne göre hareket eder, vuruşları host'a iletir.
var puppet := false
var _net_pos := Vector3.ZERO


func _puppet_tick(delta: float) -> void:
	_t += delta
	_st += delta
	_flash = maxf(_flash - delta * 6.0, 0.0)
	global_position = global_position.lerp(_net_pos, minf(12.0 * delta, 1.0))
	if tele != null and tele.visible:
		_place_tele()
	_animate(delta)


func net_apply(e: Array) -> void:
	if dead:
		return
	_net_pos = e[2]
	_face = Vector3(float(e[3]), 0, float(e[4]))
	_aim_dir = Vector3(float(e[7]), 0, float(e[8]))
	var nh := float(e[9])
	if nh < hp - 0.5:
		_flash = 1.0
	hp = nh
	max_hp = float(e[10])
	if e.size() > 12 and int(e[12]) > 0:
		set("phase", int(e[12]))
	if bool(e[11]):
		_die()
		return
	var st := String(e[5])
	if st != state:
		_net_state(st, String(e[6]))


func _net_state(st: String, an: String) -> void:
	atk = an
	_set_state(st)
