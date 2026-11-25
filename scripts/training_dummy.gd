extends CharacterBody3D
## ANTRENMAN HEDEFİ (Gözlemevi): silahları ve yetenekleri denemek için kırılmayan bir yıldız taşı.
## Vurdukça sarsılır, hasar sayıları çıkar; canı hep kendini yeniler. Saldırmaz.

const HitFx = preload("res://scripts/hit_fx.gd")

var kind := "dummy"
var dead := false
var radius := 0.6
var elite := false
var hp := 1000.0
var max_hp := 1000.0
var _flash := 0.0
var _flinch := 0.0
var _knock := Vector3.ZERO
var _home := Vector3.ZERO
var _burn_t := 0.0
var _burn_acc := 0.0
var _burn_dps := 0.0
var vis: Node3D
var m_core: StandardMaterial3D
var m_stone: StandardMaterial3D


func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 4
	collision_mask = 0
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	_home = global_position
	vis = Node3D.new()
	add_child(vis)
	m_stone = StandardMaterial3D.new()
	m_stone.albedo_color = Color(0.08, 0.1, 0.25)
	m_stone.roughness = 0.5
	m_stone.emission_enabled = true
	m_stone.emission = Color(0.3, 0.35, 0.8)
	m_stone.emission_energy_multiplier = 0.2
	var gold := StandardMaterial3D.new()
	gold.albedo_color = Color(0.95, 0.8, 0.42)
	gold.metallic = 0.9
	gold.roughness = 0.38
	m_core = StandardMaterial3D.new()
	m_core.albedo_color = Color.BLACK
	m_core.emission_enabled = true
	m_core.emission = Color(1.0, 0.85, 0.5)
	m_core.emission_energy_multiplier = 3.0
	# kaide, gövde (dikilitaş) ve göğüste parlayan yıldız
	var base := CylinderMesh.new()
	base.top_radius = 0.55
	base.bottom_radius = 0.65
	base.height = 0.3
	_part(base, Vector3(0, 0.15, 0), gold)
	var body := CylinderMesh.new()
	body.top_radius = 0.28
	body.bottom_radius = 0.45
	body.height = 1.7
	body.radial_segments = 6
	_part(body, Vector3(0, 1.15, 0), m_stone)
	var top := SphereMesh.new()
	top.radius = 0.3
	top.height = 0.6
	_part(top, Vector3(0, 2.15, 0), m_stone)
	var core := SphereMesh.new()
	core.radius = 0.14
	core.height = 0.28
	_part(core, Vector3(0, 1.45, -0.32), m_core)
	var ring := TorusMesh.new()
	ring.inner_radius = 0.42
	ring.outer_radius = 0.47
	var rm := _part(ring, Vector3(0, 1.45, 0), gold)
	rm.rotation.x = 0.3


func _part(mesh: Mesh, pos: Vector3, m: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = m
	mi.position = pos
	vis.add_child(mi)
	return mi


func _physics_process(delta: float) -> void:
	_flash = maxf(_flash - delta * 6.0, 0.0)
	_flinch = maxf(_flinch - delta * 5.0, 0.0)
	_knock = _knock.move_toward(Vector3.ZERO, 20.0 * delta)
	# yerine geri döner
	var back := (_home - global_position) * 3.0
	back.y = 0.0
	velocity = _knock + back
	move_and_slide()
	global_position.y = 0.0
	vis.rotation.x = lerpf(vis.rotation.x, -_flinch * 0.35, minf(20.0 * delta, 1.0))
	m_stone.emission = Color(0.3, 0.35, 0.8).lerp(Color(1.0, 0.95, 0.85), _flash)
	m_stone.emission_energy_multiplier = 0.2 + _flash * 3.0
	hp = minf(hp + 200.0 * delta, max_hp)
	if _burn_t > 0.0:
		_burn_t -= delta
		_burn_acc += _burn_dps * delta
		if _burn_acc >= 2.0:
			HitFx.number(get_parent(), global_position + Vector3(0, 2.4, 0), _burn_acc, false)
			_burn_acc = 0.0


func take_hit(dmg: float, dir: Vector3, kb: float, heavy: bool, crit := false) -> void:
	_flash = 1.0
	_flinch = 1.0 if heavy or crit else 0.6
	_knock = dir * kb * 0.5
	hp -= dmg
	var base := Vector3.ONE
	vis.scale = Vector3(1.15, 0.86, 1.15)
	var pt := vis.create_tween()
	pt.tween_property(vis, "scale", base, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	HitFx.impact(get_parent(), global_position + Vector3(0, 1.3, 0) - dir * 0.3, dir, Color(1.0, 0.85, 0.5), heavy or crit)
	HitFx.number(get_parent(), global_position + Vector3(0, 2.4, 0), dmg, crit)


func stun(_sec: float, _parried := false) -> void:
	pass


func pull_to(point: Vector3, strength: float) -> void:
	var d := point - global_position
	d.y = 0.0
	if d.length() > 0.3:
		_knock = d.normalized() * minf(strength, d.length() * 4.0)


func apply_burn(dps: float, dur: float) -> void:
	_burn_dps = dps
	_burn_t = dur
