extends "res://scripts/aries_boss.gd"
## BALIK: Rüyalar Denizi'nin efendisi ve son burç, İki Balık / Rüya Gören. Gümüş bir bağla birbirine bağlı, sürekli
## birbirinin çevresinde dönen iki dev rüya balığı. Balık bütün burçların sonudur: Son evrede on bir burcun yankısını taşır.
##  1. evre (100-65%):
##    - KUYRUK: yakındaysan altın uyarı; parry'lenir
##    - GÜMÜŞ BAĞ: iki balığı bağlayan bağ arenayı süpürür
##    - ÇİFTE ATILIŞ: iki balık sana doğru ok gibi atılır (iki hat)
##    - RÜYA KÖPÜKLERİ: çevresine yayılan köpük halkası
##  2. evre (65-30%): + GİRDAP: seni merkezine çeker, ortası patlar; akıntıya karşı kaç
##  3. evre (<30%):   + BURÇLARIN YANKISI: her seferinde on bir burçtan birinin hamlesini tekrarlar

signal hint(a: String, b: String)

const H = preload("res://scripts/hazards.gd")
const EnemyScript = preload("res://scripts/enemy.gd")
const SkyEcho = preload("res://scripts/sky_echo.gd")
## Büyük tek vuruşlar (GDD §13.4 Balık notu): BOSS_DMG 2,5 iken bu saldırılar etkin ~×1,6 vurur
## (100 canlı taban kahramana tek vuruş <= 45). Diğer saldırılar tam çarpanla. Retro/döngü çarpanları üstüne biner.
const BIG_HIT := 0.64
const TAIL := {"windup": 0.55, "act": 0.16, "recover": 0.55, "dmg": 26.0, "reach": 4.0, "arc": 140.0}
const PEARL := Color(0.88, 0.65, 1.0)
const AQUA := Color(0.45, 0.95, 1.0)
const ECHOES := ["aries", "taurus", "gemini", "cancer", "leo", "virgo", "libra", "scorpio", "sagittarius", "capricorn", "aquarius"]
const ECHO_NAME := {"aries": "ECHO OF ARIES", "taurus": "ECHO OF TAURUS", "gemini": "ECHO OF GEMINI", "cancer": "ECHO OF CANCER",
	"leo": "ECHO OF LEO", "virgo": "ECHO OF VIRGO", "libra": "ECHO OF LIBRA", "scorpio": "ECHO OF SCORPIO",
	"sagittarius": "ECHO OF SAGITTARIUS", "capricorn": "ECHO OF CAPRICORN", "aquarius": "ECHO OF AQUARIUS"}

var m_fish_a: StandardMaterial3D
var m_fish_b: StandardMaterial3D
var m_cord: StandardMaterial3D
var pivot: Node3D
var _spin := 0.8
var _whirl_t := 0.0
var _whirl_tick := 0.0
var _echo_bag: Array = []


func _init() -> void:
	phase_th = [0.65, 0.3]   # §13.6 evre eşikleri
	kind = "pisces"
	title = "PISCES  ·  THE DREAMER"
	max_hp = 3800.0
	hp = 3800.0
	radius = 1.8
	_cd = {"tail": 0.0, "cord": 1.5, "dart": 1.0, "bubbles": 3.0, "whirl": 0.5, "echo": 0.5}
	_global_cd = 1.0


func _fish(par: Node3D, mat: StandardMaterial3D, fin: StandardMaterial3D, x: float, face: float) -> void:
	var f := Node3D.new()
	f.position = Vector3(x, 0, 0)
	f.rotation.y = face
	par.add_child(f)
	_part(f, _sph(0.75), Vector3(0, 0, 0), mat, Vector3(0.75, 0.85, 1.7))
	_part(f, _sph(0.6), Vector3(0, 0, 1.55), fin, Vector3(0.15, 1.1, 0.8))
	_part(f, _sph(0.45), Vector3(0, 0.75, 0.1), fin, Vector3(0.12, 0.7, 1.3))
	for s in [-1.0, 1.0]:
		_part(f, _sph(0.1), Vector3(s * 0.38, 0.2, -0.85), m_eye)
		var pf := _part(f, _sph(0.4), Vector3(s * 0.6, -0.25, -0.1), fin, Vector3(0.9, 0.1, 0.7))
		pf.rotation.z = s * 0.5


func _build() -> void:
	m_fish_a = _m(Color(0.9, 0.78, 1.0), 0.25)
	m_fish_a.emission_enabled = true
	m_fish_a.emission = PEARL
	m_fish_a.emission_energy_multiplier = 0.4
	m_fish_b = _m(Color(0.7, 0.92, 1.0), 0.25)
	m_fish_b.emission_enabled = true
	m_fish_b.emission = AQUA
	m_fish_b.emission_energy_multiplier = 0.4
	m_body = m_fish_a
	var fin := StandardMaterial3D.new()
	fin.albedo_color = Color(0.75, 0.9, 1.0, 0.55)
	fin.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fin.emission_enabled = true
	fin.emission = Color(0.6, 0.8, 1.0)
	fin.emission_energy_multiplier = 1.0
	m_cord = _m(Color(0.9, 0.9, 1.0), 0.1)
	m_cord.emission_enabled = true
	m_cord.emission = Color(0.85, 0.85, 1.0)
	m_cord.emission_energy_multiplier = 2.0
	m_horn = m_cord
	m_eye = StandardMaterial3D.new()
	m_eye.albedo_color = Color.BLACK
	m_eye.emission_enabled = true
	m_eye.emission = Color(1.0, 1.0, 1.0)
	m_eye.emission_energy_multiplier = 5.0
	body_root = Node3D.new()
	add_child(body_root)
	vis = Node3D.new()
	body_root.add_child(vis)
	pivot = Node3D.new()
	pivot.position = Vector3(0, 1.6, 0)
	vis.add_child(pivot)
	head = pivot
	# iki balık zıt yönlere yüzer, aralarında gümüş bağ
	_fish(pivot, m_fish_a, fin, -2.0, PI * 0.5)
	_fish(pivot, m_fish_b, fin, 2.0, -PI * 0.5)
	var cord := _part(pivot, _cone(0.05, 0.05, 4.0), Vector3.ZERO, m_cord)
	cord.rotation.z = PI * 0.5
	_part(pivot, _sph(0.3), Vector3.ZERO, m_cord)
	arm_l = Node3D.new()
	arm_r = Node3D.new()
	pivot.add_child(arm_l)
	pivot.add_child(arm_r)
	mane = CPUParticles3D.new()
	mane.amount = 40
	mane.lifetime = 2.5
	var em := SphereMesh.new()
	em.radius = 0.06
	em.height = 0.12
	mane.mesh = em
	mane.material_override = Fx.emissive(Color(0.8, 0.9, 1.0), 2.0)
	mane.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	mane.emission_sphere_radius = 2.2
	mane.direction = Vector3.UP
	mane.gravity = Vector3(0, 0.6, 0)
	mane.initial_velocity_min = 0.2
	mane.initial_velocity_max = 0.6
	mane.position = Vector3(0, 1.4, 0)
	vis.add_child(mane)
	var l := OmniLight3D.new()
	l.light_color = PEARL
	l.light_energy = 1.8
	l.omni_range = 8.0
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


func _place_tele() -> void:
	var b := Basis.looking_at(_aim_dir, Vector3.UP) if _aim_dir.length() > 0.1 else Basis.IDENTITY
	tele.global_transform = Transform3D(b, Vector3(global_position.x, 0.07, global_position.z))


func _speed_mult() -> float:
	return [1.0, 1.0, 1.1, 1.22][clampi(phase, 1, 3)]


func _windup_len() -> float:
	var k := windup_mult / _speed_mult()
	if atk == "tail":
		return float(TAIL["windup"]) * k
	if atk == "echo":
		return 0.9 * k
	return 0.75 * k


func _recover_len() -> float:
	return float(TAIL["recover"]) if atk == "tail" else 0.55


func _chase_vel(dist: float, dir_to: Vector3, sm: float) -> Vector3:
	if dist > 4.5:
		return dir_to * 3.2 * sm
	return dir_to.rotated(Vector3.UP, PI * 0.5) * 1.8 * sm


func _pick(dist: float, dir_to: Vector3) -> void:
	var opts: Array = []
	if float(_cd["tail"]) <= 0.0 and dist < 4.2:
		opts.append_array(["tail", "tail", "tail"])
	if float(_cd["cord"]) <= 0.0:
		opts.append_array(["cord", "cord"])
	if float(_cd["dart"]) <= 0.0:
		opts.append_array(["dart", "dart"])
	if float(_cd["bubbles"]) <= 0.0:
		opts.append("bubbles")
	if phase >= 2 and float(_cd["whirl"]) <= 0.0:
		opts.append_array(["whirl", "whirl"])
	if phase >= 3 and float(_cd["echo"]) <= 0.0:
		opts.append_array(["echo", "echo", "echo"])
	if opts.is_empty():
		return
	atk = String(opts[randi() % opts.size()])
	_aim_dir = dir_to
	_set_state("windup")


func _set_state(s: String) -> void:
	state = s
	_st = 0.0
	match s:
		"windup":
			tele.visible = false
			if atk == "tail":
				_show_tele(_fan_mesh(deg_to_rad(float(TAIL["arc"])), float(TAIL["reach"])), PARRY_COL)
			Sfx.play("bossroar", -10.0, 0.08, 0, 1.3)
		"act":
			_done = false
			tele.visible = false
		"recover":
			tele.visible = false
			_global_cd = randf_range(0.3, 0.6) / _speed_mult()
			match atk:
				"tail":
					_cd["tail"] = 1.3
				"cord":
					_cd["cord"] = 6.0
				"dart":
					_cd["dart"] = 4.0
				"bubbles":
					_cd["bubbles"] = 6.0
				"whirl":
					_cd["whirl"] = 11.0
				"echo":
					_cd["echo"] = 3.2
		_:
			tele.visible = false


func _act(_delta: float, _sm: float) -> Vector3:
	match atk:
		"tail":
			if not _done and _st >= 0.06:
				_done = true
				_tail_hit()
			if _st >= float(TAIL["act"]):
				_set_state("recover")
			return _aim_dir * 5.0
		"cord":
			if not _done:
				_done = true
				var sp := H.Spokes.new()
				sp.hero = hero
				sp.follow = self
				sp.arms = 2 if phase < 3 else 3
				sp.length = 8.0
				sp.width = 0.8
				sp.spin = 1.1 * (1.0 if randf() < 0.5 else -1.0)
				sp.warn = 0.9
				sp.life = 4.0
				sp.dmg = 18.0 * dmg_mult
				sp.col = Color(0.9, 0.9, 1.0)
				get_parent().add_child(sp)
				sp.global_position = Vector3(global_position.x, 0, global_position.z)
				_spin = 2.2 * signf(sp.spin)
			if _st >= 0.4:
				_set_state("recover")
		"dart":
			if not _done:
				_done = true
				for i in 2:
					var ln := H.Line.new()
					ln.hero = hero
					ln.dir = _aim_dir.rotated(Vector3.UP, (float(i) - 0.5) * 0.5)
					ln.length = 14.0
					ln.width = 1.5
					ln.delay = 0.8 + float(i) * 0.2
					ln.dmg = 20.0 * dmg_mult * BIG_HIT
					ln.col = PEARL if i == 0 else AQUA
					get_parent().add_child(ln)
					ln.global_position = Vector3(global_position.x, 0, global_position.z)
			if _st >= 0.4:
				_set_state("recover")
		"bubbles":
			if not _done:
				_done = true
				var n := 10 if phase < 3 else 14
				for i in n:
					var bb := EnemyScript.Bubble.new()
					bb.hero = hero
					bb.dmg = 14.0 * dmg_mult
					bb.vel = Vector3(cos(TAU * float(i) / float(n)), 0, sin(TAU * float(i) / float(n))) * 3.2
					get_parent().add_child(bb)
					bb.global_position = global_position + Vector3(0, 1.3, 0)
				Sfx.play("parry", -8.0, 0.05, 0, 2.0)
			if _st >= 0.4:
				_set_state("recover")
		"whirl":
			if not _done:
				_done = true
				_whirl_t = 2.4
				hint.emit("THE WHIRLPOOL", tr("Swim against the current"))
				var b := H.Blast.new()
				b.hero = hero
				b.radius = 3.2
				b.delay = 2.4
				b.dmg = 28.0 * dmg_mult * BIG_HIT
				b.col = AQUA
				get_parent().add_child(b)
				b.global_position = Vector3(global_position.x, 0, global_position.z)
			if _st >= 0.5:
				_set_state("recover")
		"echo":
			if not _done:
				_done = true
				_echo()
			if _st >= 0.5:
				_set_state("recover")
	return Vector3.ZERO


# ---------------------------------------------------------------- burçların yankısı

func _echo() -> void:
	if _echo_bag.is_empty():
		_echo_bag = ECHOES.duplicate()
		_echo_bag.shuffle()
	var sg: String = String(_echo_bag.pop_back())
	hint.emit(String(ECHO_NAME[sg]), "")
	var ec := SkyEcho.new()
	ec.hero = hero
	ec.par = get_parent()
	ec.center = Vector3(global_position.x, 0, global_position.z)
	ec.bounds = _bounds
	ec.dm = dmg_mult * BIG_HIT   # burç yankıları 16-24 ham
	ec.cast(sg)
	ec.free()


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if _whirl_t > 0.0 and not dead:
		_whirl_t -= delta
		_whirl_tick -= delta
		if _whirl_tick <= 0.0 and H.hero_ok(hero):
			_whirl_tick = 0.15
			hero.apply_pull(global_position, 3.4, 0.2)


func _tail_hit() -> void:
	var reach := float(TAIL["reach"])
	var arc := deg_to_rad(float(TAIL["arc"]))
	var fx := SlashFx.make(-arc * 0.5, arc * 0.5, 0.8, reach, PARRY_COL, 0.22)
	get_parent().add_child(fx)
	fx.global_transform = Transform3D(Basis.looking_at(_aim_dir, Vector3.UP), global_position + Vector3(0, 1.5, 0))
	Sfx.play("crush", -5.0, 0.1, 0, 1.0)
	if not H.hero_ok(hero):
		return
	var to: Vector3 = hero.global_position - global_position
	to.y = 0.0
	var dist := to.length()
	if dist > reach + 0.4 or (dist > 0.3 and _aim_dir.angle_to(to / dist) > arc * 0.5):
		return
	var res: String = hero.take_damage(float(TAIL["dmg"]) * dmg_mult * BIG_HIT, to.normalized() if dist > 0.05 else _aim_dir, true)
	if res == "parried":
		stun(2.4, true)
		_knock = -_aim_dir * 3.0


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
	tele.visible = false
	_whirl_t = 0.0
	_set_state("roar")
	Fx.shake(0.9)
	Fx.flash_light(global_position + Vector3(0, 3, 0), PEARL, 12.0, 20.0, 0.9)
	Sfx.play("bossroar", 0.0, 0.0, 0, 1.2)
	mane.amount = 40 if p == 1 else (70 if p == 2 else 120)
	if p == 2:
		_cd["whirl"] = 0.3
		summon.emit(["shade", "shade", "caster"])
	elif p == 3:
		_cd["echo"] = 0.3
		hint.emit("ECHO OF THE ZODIAC", tr("The last sign dreams of all the others"))
		summon.emit(["leaper", "brute"])
	phase_changed.emit(p)


func _animate(delta: float) -> void:
	body_root.rotation.y = lerp_angle(body_root.rotation.y, atan2(-_face.x, -_face.z), minf(4.0 * delta, 1.0))
	_spin = lerpf(_spin, 0.8 if state != "stun" else 0.15, minf(0.6 * delta, 1.0))
	pivot.rotation.y += _spin * delta
	pivot.position.y = 1.6 + sin(Time.get_ticks_msec() * 0.0015) * 0.25
	var glow := 5.0
	match state:
		"windup":
			glow = 5.0 + 14.0 * clampf(_st / _windup_len(), 0.0, 1.0)
			_spin = lerpf(_spin, 2.5, minf(2.0 * delta, 1.0))
		"act":
			glow = 16.0
		"roar":
			glow = 20.0
		"stun":
			glow = 1.5
	m_eye.emission_energy_multiplier = glow
	m_fish_a.emission_energy_multiplier = 0.4 + _flash * 3.0
	m_fish_b.emission_energy_multiplier = 0.4 + _flash * 3.0
	m_cord.emission_energy_multiplier = 2.0 + glow * 0.15
