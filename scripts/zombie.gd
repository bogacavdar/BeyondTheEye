extends CharacterBody3D
## MUTANT
## Neon şehirde yayılan virüs insanları et yığınlarına çevirdi. Beş tür:
##   normal  = YÜRÜYEN : kambur, uzun kollu, şişmiş kafalı
##   fast    = KOŞUCU  : dört ayak üstünde koşan, koca çeneli
##   armored = ZIRHLI  : iri, sibernetik zırh plakalı (gövde ve kafa korumalı)
##   bloater = ŞİŞKO   : dev şiş göbek; ölünce asit saçarak patlar
##   spider  = ÖRÜMCEK : altı bacaklı, sürü hâlinde gelir
## Vurulduğu YERE göre tepki verir; kafa, kol, bacak ayrı ayrı kopar. Yanabilir, patlamayla parçalanır.

signal killed(zombie)

const FLESH = preload("res://shaders/flesh.gdshader")

static var _flesh_mat: ShaderMaterial = null
static var _mesh_cache := {}

var kind := "normal"
var target: Node3D = null
var nav = null
var max_hp := 45.0
var hp := 45.0
var armor := 0.0
var speed := 2.6
var damage := 12.0
var body_scale := 1.0
var skin := Color(0.6, 0.45, 0.5)

var knock := Vector3.ZERO
var stagger := 0.0
var attack_cd := 0.0
var attack_anim := 0.0
var flash := 0.0
var burn_t := 0.0
var dead := false
var walk_t := 0.0
var legs_lost := 0
var arms_lost := 0
var crawl := false

var visual: Node3D
var col_shape: CollisionShape3D
var capsule: CapsuleShape3D
var parts: Array = []          # tüm et parçaları (parlama/yanma için)
var limbs := {}                # kopabilen uzuvlar
var legs: Array = []           # yürüme animasyonu
var arms: Array = []
var head_node: Node3D = null
var torso_mi: MeshInstance3D = null
var plates: Array = []
var burn_fx: CPUParticles3D = null
var _applied_flash := -1.0
var _applied_burn := -1.0


func setup(p_kind: String, p_target: Node3D, p_nav = null) -> void:
	kind = p_kind
	target = p_target
	nav = p_nav
	match kind:
		"fast":
			max_hp = 26.0
			speed = 5.2
			damage = 8.0
			skin = Color(0.78, 0.3, 0.28)
		"armored":
			max_hp = 70.0
			armor = 60.0
			speed = 2.0
			damage = 20.0
			body_scale = 1.25
			skin = Color(0.5, 0.42, 0.48)
		"bloater":
			max_hp = 60.0
			speed = 1.7
			damage = 10.0
			skin = Color(0.62, 0.6, 0.4)
		"spider":
			max_hp = 16.0
			speed = 4.6
			damage = 6.0
			body_scale = 0.85
			skin = Color(0.4, 0.3, 0.42)
		_:
			max_hp = 45.0
			speed = randf_range(2.3, 3.0)
			skin = Color(0.62, 0.48, 0.52)
	hp = max_hp
	walk_t = randf() * TAU


# ---------------------------------------------------------------- yapım

func _ready() -> void:
	add_to_group("zombies")
	collision_layer = 4
	collision_mask = 1 | 2 | 4
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	if _flesh_mat == null:
		_flesh_mat = ShaderMaterial.new()
		_flesh_mat.shader = FLESH

	var shape_r := 0.4
	var shape_h := 1.9
	match kind:
		"fast":
			shape_r = 0.45
			shape_h = 1.3
		"armored":
			shape_r = 0.45
			shape_h = 2.0
		"bloater":
			shape_r = 0.75
			shape_h = 2.0
		"spider":
			shape_r = 0.6
			shape_h = 1.2
		"boss":
			shape_r = 1.3
			shape_h = 3.2
	col_shape = CollisionShape3D.new()
	capsule = CapsuleShape3D.new()
	capsule.radius = shape_r * body_scale
	capsule.height = shape_h * body_scale
	col_shape.shape = capsule
	col_shape.position.y = shape_h * 0.5 * body_scale + 0.05
	add_child(col_shape)

	visual = Node3D.new()
	visual.scale = Vector3.ONE * body_scale
	add_child(visual)

	_build_body()

	var pseed := randf() * 10.0
	for p in parts:
		p.set_instance_shader_parameter("skin_color", skin.darkened(randf_range(0.0, 0.12)))
		p.set_instance_shader_parameter("pulse_seed", pseed)
	_apply_params(true)


## Gövdeyi kurar. Boss gibi alt türler bunu kendi gövdesiyle değiştirir.
func _build_body() -> void:
	match kind:
		"fast":
			_build_runner()
		"armored":
			_build_brute()
		"bloater":
			_build_bloater()
		"spider":
			_build_spider()
		_:
			_build_shambler()


func _sphere(r: float) -> Mesh:
	var key := "s%.3f" % r
	if not _mesh_cache.has(key):
		var m := SphereMesh.new()
		m.radius = r
		m.height = r * 2.0
		m.radial_segments = 14
		m.rings = 8
		_mesh_cache[key] = m
	return _mesh_cache[key]


func _capsule(r: float, h: float) -> Mesh:
	var key := "c%.3f_%.3f" % [r, h]
	if not _mesh_cache.has(key):
		var m := CapsuleMesh.new()
		m.radius = r
		m.height = maxf(h, r * 2.0)
		m.radial_segments = 12
		m.rings = 4
		_mesh_cache[key] = m
	return _mesh_cache[key]


func _boxm(s: Vector3) -> Mesh:
	var key := "b%s" % str(s)
	if not _mesh_cache.has(key):
		var m := BoxMesh.new()
		m.size = s
		_mesh_cache[key] = m
	return _mesh_cache[key]


func _part(parent: Node3D, mesh: Mesh, pos: Vector3, rot := Vector3.ZERO, scl := Vector3.ONE, m: Material = null) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = pos
	mi.rotation = rot
	mi.scale = scl
	if m == null:
		mi.material_override = _flesh_mat
		parts.append(mi)
	else:
		mi.material_override = m
	parent.add_child(mi)
	return mi


func _pivot(parent: Node3D, pos: Vector3, rot := Vector3.ZERO) -> Node3D:
	var n := Node3D.new()
	n.position = pos
	n.rotation = rot
	parent.add_child(n)
	return n


func _limb(limb_name: String, node: Node3D, mesh: MeshInstance3D, limb_hp: float, spray: Vector3) -> void:
	limbs[limb_name] = {"node": node, "mesh": mesh, "hp": limb_hp, "spray": spray}


func _leg(node: Node3D, axis: String, base: float, phase: float, amp: float) -> void:
	legs.append({"node": node, "axis": axis, "base": base, "phase": phase, "amp": amp})


func _arm(node: Node3D, base: float, phase: float, amp: float) -> void:
	arms.append({"node": node, "base": base, "phase": phase, "amp": amp})


func _eyes(parent: Node3D, pos: Vector3, spread: float, count: int, r := 0.045) -> void:
	var em := Fx.emissive(Color(0.75, 1.0, 0.2), 9.0)
	for i in count:
		var o := Vector3(randf_range(-spread, spread), randf_range(-spread * 0.6, spread * 0.6), 0)
		_part(parent, _sphere(r * randf_range(0.7, 1.3)), pos + o, Vector3.ZERO, Vector3.ONE, em)


func _teeth(parent: Node3D, pos: Vector3, width: float, n: int) -> void:
	var tm := Fx.mat(Color(0.85, 0.8, 0.65), 0.0, 0.4)
	for i in n:
		var x := lerpf(-width, width, float(i) / maxf(n - 1, 1))
		_part(parent, _boxm(Vector3(0.025, 0.07, 0.025)), pos + Vector3(x, 0, 0), Vector3(0, 0, randf_range(-0.3, 0.3)), Vector3.ONE, tm)


## YÜRÜYEN: kambur gövde, şişmiş kafa, yere sarkan uzun kollar
func _build_shambler() -> void:
	for side: float in [-1.0, 1.0]:
		var hip := _pivot(visual, Vector3(0.15 * side, 0.95, 0))
		var leg := _part(hip, _capsule(0.11, 0.95), Vector3(0, -0.47, 0))
		_leg(hip, "x", 0.0, 0.0 if side < 0.0 else PI, 0.55)
		_limb("leg_l" if side < 0.0 else "leg_r", hip, leg, 20.0, Vector3(0, -1, 0))
	var spine := _pivot(visual, Vector3(0, 0.95, 0), Vector3(-0.38, 0, 0))
	torso_mi = _part(spine, _capsule(0.3, 1.05), Vector3(0, 0.45, 0))
	_part(spine, _sphere(0.2), Vector3(0.22, 0.85, 0.12))
	_part(spine, _sphere(0.14), Vector3(-0.12, 0.7, 0.24))
	head_node = _pivot(spine, Vector3(0, 1.08, -0.08))
	var head := _part(head_node, _sphere(0.26), Vector3.ZERO, Vector3.ZERO, Vector3(1.0, 0.9, 1.15))
	_part(head_node, _sphere(0.15), Vector3(0.14, 0.12, 0.05))
	_part(head_node, _boxm(Vector3(0.24, 0.08, 0.2)), Vector3(0, -0.2, -0.14), Vector3(0.35, 0, 0))
	_teeth(head_node, Vector3(0, -0.15, -0.25), 0.09, 5)
	_eyes(head_node, Vector3(0, 0.05, -0.26), 0.1, 3)
	_limb("head", head_node, head, 20.0, Vector3(0, 1, 0))
	for side: float in [-1.0, 1.0]:
		var sh := _pivot(spine, Vector3(0.34 * side, 0.85, 0), Vector3(-0.5, 0, 0))
		var arm := _part(sh, _capsule(0.08, 1.15), Vector3(0, -0.55, 0))
		_part(sh, _boxm(Vector3(0.16, 0.08, 0.2)), Vector3(0, -1.12, -0.05), Vector3.ZERO, Vector3.ONE, Fx.mat(Color(0.2, 0.15, 0.12), 0.0, 0.5))
		_arm(sh, -0.5, 0.0 if side < 0.0 else PI, 0.25)
		_limb("arm_l" if side < 0.0 else "arm_r", sh, arm, 18.0, Vector3(side, 0.2, 0))


## KOŞUCU: dört ayak üstünde, alçak gövde, koca çene
func _build_runner() -> void:
	var spine := _pivot(visual, Vector3(0, 0.75, 0))
	torso_mi = _part(spine, _capsule(0.26, 1.3), Vector3.ZERO, Vector3(PI * 0.5, 0, 0))
	var bone := Fx.mat(Color(0.8, 0.75, 0.6), 0.0, 0.4)
	for i in 4:
		_part(spine, _boxm(Vector3(0.05, 0.18, 0.05)), Vector3(0, 0.27, -0.4 + i * 0.25), Vector3(0.4, 0, 0), Vector3.ONE, bone)
	head_node = _pivot(spine, Vector3(0, 0.12, -0.82))
	var head := _part(head_node, _sphere(0.21), Vector3.ZERO, Vector3.ZERO, Vector3(0.9, 0.8, 1.35))
	_part(head_node, _boxm(Vector3(0.26, 0.07, 0.3)), Vector3(0, -0.14, -0.12), Vector3(0.3, 0, 0))
	_teeth(head_node, Vector3(0, -0.08, -0.32), 0.1, 6)
	_eyes(head_node, Vector3(0, 0.07, -0.26), 0.08, 2, 0.04)
	_limb("head", head_node, head, 14.0, Vector3(0, 0.3, -1))
	for side: float in [-1.0, 1.0]:
		var sh := _pivot(spine, Vector3(0.24 * side, 0.0, -0.45))
		var arm := _part(sh, _capsule(0.075, 0.85), Vector3(0, -0.4, 0))
		_leg(sh, "x", 0.0, 0.0 if side < 0.0 else 0.6, 0.85)
		_limb("arm_l" if side < 0.0 else "arm_r", sh, arm, 12.0, Vector3(side, 0, 0))
		var hip := _pivot(spine, Vector3(0.24 * side, 0.0, 0.45))
		var leg := _part(hip, _capsule(0.085, 0.85), Vector3(0, -0.4, 0))
		_leg(hip, "x", 0.0, PI + (0.0 if side < 0.0 else 0.6), 0.85)
		_limb("leg_l" if side < 0.0 else "leg_r", hip, leg, 14.0, Vector3(side, 0, 0))


## ZIRHLI: iri, bir kolu dev yumruk; gövde ve kafada sibernetik plakalar
func _build_brute() -> void:
	for side: float in [-1.0, 1.0]:
		var hip := _pivot(visual, Vector3(0.2 * side, 0.9, 0))
		var leg := _part(hip, _capsule(0.15, 0.95), Vector3(0, -0.45, 0))
		_leg(hip, "x", 0.0, 0.0 if side < 0.0 else PI, 0.45)
		_limb("leg_l" if side < 0.0 else "leg_r", hip, leg, 30.0, Vector3(0, -1, 0))
	var spine := _pivot(visual, Vector3(0, 0.9, 0), Vector3(-0.2, 0, 0))
	torso_mi = _part(spine, _capsule(0.42, 1.1), Vector3(0, 0.5, 0), Vector3.ZERO, Vector3(1.15, 1.0, 0.9))
	head_node = _pivot(spine, Vector3(0, 1.15, -0.1))
	var head := _part(head_node, _sphere(0.22), Vector3.ZERO)
	_eyes(head_node, Vector3(0, 0.02, -0.2), 0.06, 2)
	_limb("head", head_node, head, 26.0, Vector3(0, 1, 0))
	var metal := Fx.mat(Color(0.32, 0.33, 0.37), 0.9, 0.3)
	plates.append(_part(spine, _boxm(Vector3(0.8, 0.65, 0.45)), Vector3(0, 0.55, -0.12), Vector3.ZERO, Vector3.ONE, metal))
	plates.append(_part(head_node, _boxm(Vector3(0.5, 0.26, 0.5)), Vector3(0, 0.1, 0.0), Vector3.ZERO, Vector3.ONE, metal))
	plates.append(_part(spine, _boxm(Vector3(0.6, 0.05, 0.03)), Vector3(0, 0.62, -0.36), Vector3.ZERO, Vector3.ONE, Fx.emissive(Color(1.0, 0.5, 0.1), 4.0)))
	for side: float in [-1.0, 1.0]:
		var sh := _pivot(spine, Vector3(0.52 * side, 0.85, 0), Vector3(-0.3, 0, 0))
		var big := side > 0.0
		var arm := _part(sh, _capsule(0.16 if big else 0.11, 0.95), Vector3(0, -0.45, 0))
		_part(sh, _sphere(0.3 if big else 0.14), Vector3(0, -0.95, -0.05))
		_arm(sh, -0.3, 0.0 if side < 0.0 else PI, 0.2)
		_limb("arm_l" if side < 0.0 else "arm_r", sh, arm, 30.0, Vector3(side, 0.2, 0))


## ŞİŞKO: dev şiş göbek, minik kafa ve uzuvlar
func _build_bloater() -> void:
	torso_mi = _part(visual, _sphere(0.78), Vector3(0, 1.05, 0), Vector3.ZERO, Vector3(1.0, 0.95, 1.0))
	_part(visual, _sphere(0.3), Vector3(0.45, 1.35, -0.4))
	_part(visual, _sphere(0.22), Vector3(-0.5, 0.8, -0.35))
	_part(visual, _sphere(0.25), Vector3(-0.2, 1.55, 0.4))
	head_node = _pivot(visual, Vector3(0, 1.88, -0.15))
	var head := _part(head_node, _sphere(0.18), Vector3.ZERO)
	_eyes(head_node, Vector3(0, 0.02, -0.16), 0.05, 2, 0.035)
	_limb("head", head_node, head, 12.0, Vector3(0, 1, 0))
	for side: float in [-1.0, 1.0]:
		var sh := _pivot(visual, Vector3(0.72 * side, 1.25, -0.1), Vector3(-0.4, 0, side * 0.5))
		var arm := _part(sh, _capsule(0.08, 0.6), Vector3(0, -0.28, 0))
		_arm(sh, -0.4, 0.0 if side < 0.0 else PI, 0.3)
		_limb("arm_l" if side < 0.0 else "arm_r", sh, arm, 12.0, Vector3(side, 0, 0))
		var hip := _pivot(visual, Vector3(0.32 * side, 0.45, 0))
		var leg := _part(hip, _capsule(0.13, 0.5), Vector3(0, -0.22, 0))
		_leg(hip, "x", 0.0, 0.0 if side < 0.0 else PI, 0.35)
		_limb("leg_l" if side < 0.0 else "leg_r", hip, leg, 16.0, Vector3(0, -1, 0))


## ÖRÜMCEK: altı uzun bacak, şiş karın, çeneli kafa
func _build_spider() -> void:
	var body := _pivot(visual, Vector3(0, 0.6, 0))
	torso_mi = _part(body, _sphere(0.32), Vector3.ZERO, Vector3.ZERO, Vector3(1.0, 0.8, 1.1))
	_part(body, _sphere(0.42), Vector3(0, 0.1, 0.5), Vector3.ZERO, Vector3(1.0, 0.85, 1.2))
	head_node = _pivot(body, Vector3(0, 0.02, -0.38))
	var head := _part(head_node, _sphere(0.17), Vector3.ZERO)
	_eyes(head_node, Vector3(0, 0.06, -0.14), 0.08, 4, 0.03)
	var bone := Fx.mat(Color(0.85, 0.8, 0.65), 0.0, 0.4)
	for side: float in [-1.0, 1.0]:
		_part(head_node, _boxm(Vector3(0.04, 0.04, 0.2)), Vector3(0.07 * side, -0.08, -0.14), Vector3(0, side * 0.4, 0), Vector3.ONE, bone)
	_limb("head", head_node, head, 8.0, Vector3(0, 0.3, -1))
	var zs := [-0.22, 0.05, 0.3]
	for side: float in [-1.0, 1.0]:
		for i in 3:
			var hip := _pivot(body, Vector3(0.25 * side, 0.0, zs[i]), Vector3(0, 0, side * 1.05))
			var leg := _part(hip, _capsule(0.045, 1.0), Vector3(0, -0.5, 0))
			_leg(hip, "y", (i - 1) * 0.35 * side, float(i) * 2.1 + (0.0 if side < 0.0 else PI), 0.45)
			_limb("leg_%s%d" % ["l" if side < 0.0 else "r", i], hip, leg, 6.0, Vector3(side, 0, 0))


# ---------------------------------------------------------------- hareket

func _physics_process(delta: float) -> void:
	if dead:
		knock = knock.move_toward(Vector3.ZERO, 18.0 * delta)
		velocity = knock
		move_and_slide()
		if burn_t > 0.0:
			burn_t -= delta
			if burn_t <= 0.0 and burn_fx != null:
				burn_fx.emitting = false
		return

	attack_cd -= delta
	stagger -= delta
	attack_anim -= delta
	flash = maxf(flash - delta * 14.0, 0.0)
	if burn_t > 0.0:
		burn_t -= delta
		hp -= 12.0 * delta
		if burn_t <= 0.0 and burn_fx != null:
			burn_fx.emitting = false
		if hp <= 0.0:
			_die(Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized(), 2.0, false, true)
			return
	_apply_params()
	visual.scale = visual.scale.lerp(Vector3.ONE * body_scale, 1.0 - exp(-18.0 * delta))

	var direct := Vector3.ZERO
	var dist := 999.0
	if target != null and is_instance_valid(target):
		var to := target.global_position - global_position
		to.y = 0.0
		dist = to.length()
		if dist > 0.01:
			direct = to / dist
	var dir := direct
	if nav != null:
		var nd: Vector3 = nav.dir_at(global_position)
		if nd != Vector3.ZERO:
			dir = nd

	var spd := speed
	if kind == "spider":
		spd *= maxf(1.0 - legs_lost * 0.14, 0.25)
	elif legs_lost == 1:
		spd *= 0.45
	elif legs_lost >= 2:
		spd = minf(speed, 1.6) * 0.6
	if burn_t > 0.0:
		spd *= 1.25  # yanarken panikle koşar
	if stagger > 0.0:
		spd *= 0.2
	knock = knock.move_toward(Vector3.ZERO, 25.0 * delta)
	velocity = dir * spd + knock
	velocity.y = 0.0
	move_and_slide()
	global_position.y = 0.0

	if dir != Vector3.ZERO:
		visual.rotation.y = lerp_angle(visual.rotation.y, atan2(-dir.x, -dir.z), 10.0 * delta)

	_animate(delta, spd)

	if dist < (1.3 + capsule.radius * 0.6) and attack_cd <= 0.0 and stagger <= 0.0:
		attack_cd = 0.9
		attack_anim = 0.35
		target.call("take_damage", damage, direct)
		knock -= direct * 2.0


func _animate(delta: float, spd: float) -> void:
	walk_t += delta * maxf(spd, 0.8) * (3.2 if kind == "spider" else 2.2)
	for L in legs:
		var n: Node3D = L["node"]
		if not is_instance_valid(n):
			continue
		var v: float = float(L["base"]) + sin(walk_t + float(L["phase"])) * float(L["amp"])
		if L["axis"] == "y":
			n.rotation.y = v
		else:
			n.rotation.x = v
	for A in arms:
		var n: Node3D = A["node"]
		if not is_instance_valid(n):
			continue
		var v: float = float(A["base"]) + sin(walk_t * 0.5 + float(A["phase"])) * float(A["amp"])
		if attack_anim > 0.0:
			v = -1.5
		n.rotation.x = lerpf(n.rotation.x, v, 1.0 - exp(-15.0 * delta))
	if head_node != null and is_instance_valid(head_node) and head_node.get_parent() != null and visual.is_ancestor_of(head_node):
		head_node.rotation.x = sin(walk_t * 0.5) * 0.12
	var bob := absf(sin(walk_t)) * (0.02 if crawl else 0.05)
	if kind == "bloater":
		bob = absf(sin(walk_t)) * 0.08
		visual.rotation.z = sin(walk_t * 0.5) * 0.12
	visual.position.y = (0.25 if crawl else 0.0) + bob
	if crawl:
		visual.rotation.x = lerpf(visual.rotation.x, -1.2, 1.0 - exp(-6.0 * delta))


func _apply_params(force := false) -> void:
	var b := clampf(burn_t, 0.0, 1.0)
	if not force and absf(flash - _applied_flash) < 0.02 and absf(b - _applied_burn) < 0.02:
		return
	_applied_flash = flash
	_applied_burn = b
	for p in parts:
		if is_instance_valid(p):
			p.set_instance_shader_parameter("flash", flash)
			p.set_instance_shader_parameter("burn", b)


# ---------------------------------------------------------------- vuruş bölgesi

func _part_dist(mi: MeshInstance3D, p: Vector3) -> float:
	var box := mi.mesh.get_aabb()
	var xf := mi.global_transform
	var c := xf * box.get_center()
	var s := xf.basis.get_scale()
	var r := minf(minf(box.size.x * s.x, box.size.y * s.y), box.size.z * s.z) * 0.5
	return maxf(p.distance_to(c) - r, 0.0)


## Merminin girdiği noktaya en yakın vücut parçasını bulur.
func _hit_part(point: Vector3) -> String:
	var best := "torso"
	var best_d := INF
	if torso_mi != null:
		best_d = _part_dist(torso_mi, point) + 0.08  # sınırdaki isabetler uzva sayılsın
	for k in limbs:
		var mi: MeshInstance3D = limbs[k]["mesh"]
		if not is_instance_valid(mi):
			continue
		var d := _part_dist(mi, point)
		if d < best_d:
			best_d = d
			best = k
	return best


func part_at(point: Vector3) -> String:
	return _hit_part(point)


# ---------------------------------------------------------------- hasar

func take_hit(dmg: float, dir: Vector3, knockback: float, point: Vector3, w: Dictionary) -> void:
	if dead:
		return
	var part := _hit_part(point)

	if armor > 0.0 and (part == "torso" or part == "head"):
		armor -= dmg
		Fx.sparks(point, -dir)
		Sfx.play("armor", -8.0, 0.1, 45)
		knock += dir * knockback * 0.25
		flash = 0.4
		if armor <= 0.0:
			_break_armor(dir)
		return

	var mult := 1.0
	if part == "head":
		mult = 1.6
	elif part != "torso":
		mult = 0.7
	hp -= dmg * mult
	knock += dir * knockback
	stagger = 0.12
	flash = 1.0
	visual.scale = Vector3(1.12, 0.9, 1.12) * body_scale
	Fx.blood_spray(point, dir)
	Sfx.play("flesh", -5.0, 0.12, 30)

	if limbs.has(part):
		var info: Dictionary = limbs[part]
		info["hp"] = float(info["hp"]) - dmg
		if float(info["hp"]) <= 0.0:
			_sever(part, dir)
			if part == "head":
				hp = minf(hp, 0.0)

	if hp <= 0.0:
		var gib := hp < -25.0
		if target != null and is_instance_valid(target):
			gib = gib or global_position.distance_to(target.global_position) < float(w.get("gib_range", 0.0))
		_die(dir, knockback, gib)


## Alev silahı: tutuşturur, yanarken sürekli can kaybeder.
func take_burn(dmg: float, dir: Vector3, duration: float) -> void:
	if dead:
		return
	hp -= dmg
	burn_t = maxf(burn_t, duration)
	flash = maxf(flash, 0.3)
	knock += dir * 0.6
	_ensure_burn_fx()
	if hp <= 0.0:
		_die(dir, 1.0, false, true)


func _ensure_burn_fx() -> void:
	if burn_fx == null:
		burn_fx = Fx.make_fire_emitter(28, 0.55, 0.8, 2.0, 35.0, 0.3, 0.8)
		burn_fx.direction = Vector3.UP
		burn_fx.position = Vector3(0, 1.0, 0)
		visual.add_child(burn_fx)
	burn_fx.emitting = true


## Patlama: ağır hasar, uzuvları koparır, yakındakileri parçalara ayırır.
func take_explosion(dmg: float, dir: Vector3, kb: float, origin: Vector3) -> void:
	if dead:
		return
	hp -= dmg
	knock += dir * kb
	flash = 1.0
	burn_t = maxf(burn_t, 1.5)
	_ensure_burn_fx()
	for k in limbs.keys():
		if randf() < clampf(dmg / 180.0, 0.15, 0.7):
			_sever(k, (dir + Vector3(0, 0.6, 0)).normalized())
	if hp <= 0.0:
		var close := global_position.distance_to(origin) < 2.5
		_die(dir, kb, close or dmg > 90.0)


func _sever(part: String, dir: Vector3) -> void:
	if not limbs.has(part):
		return
	var info: Dictionary = limbs[part]
	limbs.erase(part)
	var node: Node3D = info["node"]
	var mi: MeshInstance3D = info["mesh"]
	if not is_instance_valid(node) or not is_instance_valid(mi):
		return
	var parent := node.get_parent() as Node3D
	var stump_local := node.position
	var center := mi.global_transform * mi.mesh.get_aabb().get_center()
	var size := mi.mesh.get_aabb().size * mi.global_transform.basis.get_scale()

	# kopan parçayı bu yaratığın listelerinden çıkar
	var kept: Array = []
	for p in parts:
		if not is_instance_valid(p):
			continue
		if node.is_ancestor_of(p):
			p.set_instance_shader_parameter("flash", 0.0)
		else:
			kept.append(p)
	parts = kept
	var kept_plates: Array = []
	for p in plates:
		if is_instance_valid(p) and not node.is_ancestor_of(p):
			kept_plates.append(p)
	plates = kept_plates
	for L in legs.duplicate():
		if L["node"] == node:
			legs.erase(L)
	for A in arms.duplicate():
		if A["node"] == node:
			arms.erase(A)

	Fx.limb(node, center, size, dir)

	# kesik nokta ve kan fışkırması
	if parent != null:
		var stump := MeshInstance3D.new()
		stump.mesh = _sphere(0.09)
		stump.material_override = Fx.blood_mat
		stump.position = stump_local
		parent.add_child(stump)
		Fx.blood_fountain(parent, stump_local, info["spray"], 2.2 if part == "head" else 1.5)
	Fx.blood_spray(center, dir, 1.5)
	Sfx.play("splat", -4.0, 0.1, 30)
	Fx.shake(0.15)
	Fx.hitstop(0.04)

	if part.begins_with("leg"):
		legs_lost += 1
		if kind in ["normal", "fast", "armored"] and legs_lost >= 2:
			_start_crawl()
		elif kind in ["normal", "fast", "armored"] and legs_lost == 1:
			visual.rotation.z = 0.2 if part == "leg_r" else -0.2
	elif part.begins_with("arm"):
		arms_lost += 1
		damage *= 0.6


func _start_crawl() -> void:
	crawl = true
	capsule.height = maxf(capsule.radius * 2.0, 0.9 * body_scale)
	col_shape.position.y = capsule.height * 0.5


func _break_armor(dir: Vector3) -> void:
	armor = 0.0
	Sfx.play("armor_break", -2.0, 0.05, 50)
	Fx.shake(0.2)
	for p in plates:
		if is_instance_valid(p) and p.is_visible_in_tree():
			var xf: Transform3D = p.global_transform
			var size: Vector3 = (p.mesh as BoxMesh).size * xf.basis.get_scale()
			Fx.debris(Transform3D(xf.basis.orthonormalized(), xf.origin), size, p.material_override, dir)
			Fx.sparks(xf.origin, -dir, true)
			p.queue_free()
	plates.clear()
	stagger = 0.4
	knock += dir * 3.0


func _die(dir: Vector3, knockback: float, gib: bool, burned := false) -> void:
	if dead:
		return
	dead = true
	flash = 0.0
	remove_from_group("zombies")
	collision_layer = 0
	collision_mask = 1
	killed.emit(self)

	var chest := global_position + Vector3(0, 1.0 * body_scale, 0)
	Fx.shake(0.12)
	Fx.hitstop(0.035)

	if kind == "bloater":
		_bloater_pop(chest)
		return

	if burned:
		# kömürleşip yere yığılır, duman tüter
		for p in parts:
			if is_instance_valid(p):
				p.set_instance_shader_parameter("char_amt", 1.0)
				p.set_instance_shader_parameter("flash", 0.0)
		burn_t = 2.5
		_ensure_burn_fx()
		Sfx.play("flame", -8.0, 0.2, 60)
	else:
		Fx.blood_burst(chest, dir)
		Sfx.play("splat", -5.0, 0.12, 40)
		_apply_params(true)

	if gib and not burned:
		Fx.gibs(chest, dir, 12)
		Fx.flash_light(chest, Color(1.0, 0.1, 0.1), 2.5, 4.0, 0.12)
		queue_free()
		return

	knock = dir * (knockback * 1.4 + 3.0)
	visual.rotation = Vector3(0, atan2(dir.x, dir.z), 0)
	visual.scale = Vector3.ONE * body_scale
	var fall_rot := PI if kind == "spider" else PI * 0.5
	var fall_y := 0.5 if kind == "spider" else 0.3
	var t := create_tween()
	t.tween_property(visual, "rotation:x", fall_rot, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(visual, "position:y", fall_y, 0.35)
	if not burned:
		t.tween_callback(func(): Fx.blood_splat(global_position + dir * 0.9, 0.7))
	t.tween_interval(5.0)
	t.tween_property(visual, "position:y", -1.2, 1.5)
	t.tween_callback(queue_free)


## Şişko ölünce: asit saçarak patlar, yakındaki oyuncuyu yakar, diğer mutantları savurur.
func _bloater_pop(pos: Vector3) -> void:
	Fx.acid_burst(pos)
	Fx.blood_burst(pos, Vector3.UP)
	Fx.gibs(pos, Vector3.UP, 16)
	for i in 5:
		Fx.blood_splat(pos + Vector3(randf_range(-2, 2), 0, randf_range(-2, 2)), randf_range(0.5, 1.1))
	if target != null and is_instance_valid(target) and target.global_position.distance_to(global_position) < 3.2:
		var d := target.global_position - global_position
		d.y = 0.0
		target.call("take_damage", 18.0, d.normalized())
	for z in get_tree().get_nodes_in_group("zombies"):
		var zp: Vector3 = z.global_position
		if zp.distance_to(global_position) < 3.5 and z.has_method("take_explosion"):
			var v := zp - global_position
			v.y = 0.0
			z.take_explosion(25.0, v.normalized() if v.length() > 0.05 else Vector3.FORWARD, 8.0, global_position)
	queue_free()
