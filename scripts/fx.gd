extends Node
## VURUŞ HİSSİ MERKEZİ
## Hit-stop, ekran sarsıntısı, kan, yerdeki kan izleri, et parçaları,
## kıvılcımlar, iz mermileri ve anlık ışık patlamaları burada.

var camera = null
var world: Node3D = null

var _hitstop_until := 0
var _last_hitstop := -100000
var _splats: Array = []
const MAX_SPLATS := 260

var blood_mat: StandardMaterial3D
var blood_floor_mat: StandardMaterial3D
var flesh_mat: StandardMaterial3D
var spark_mat: StandardMaterial3D
var dust_mat: StandardMaterial3D
var highlight_mat: StandardMaterial3D
var drop_mesh: SphereMesh
var spark_mesh: BoxMesh
var splat_mesh: CylinderMesh
var _tracer_mats := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	blood_mat = mat(Color(0.7, 0.0, 0.03), 0.1, 0.2)
	blood_mat.emission_enabled = true
	blood_mat.emission = Color(0.9, 0.0, 0.05)
	blood_mat.emission_energy_multiplier = 1.6

	blood_floor_mat = mat(Color(0.45, 0.0, 0.02), 0.3, 0.08)
	blood_floor_mat.emission_enabled = true
	blood_floor_mat.emission = Color(0.5, 0.0, 0.03)
	blood_floor_mat.emission_energy_multiplier = 0.35
	flesh_mat = mat(Color(0.75, 0.2, 0.15), 0.0, 0.45)
	flesh_mat.emission_enabled = true
	flesh_mat.emission = Color(0.6, 0.05, 0.05)
	flesh_mat.emission_energy_multiplier = 0.4
	spark_mat = emissive(Color(1.0, 0.65, 0.25), 9.0)
	dust_mat = emissive(Color(0.6, 0.9, 1.0), 3.0)

	# nişan alınan uzvun üstüne binen yarı saydam sarı parlama
	highlight_mat = StandardMaterial3D.new()
	highlight_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	highlight_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	highlight_mat.albedo_color = Color(1.0, 0.85, 0.15, 0.5)
	highlight_mat.grow = true
	highlight_mat.grow_amount = 0.015

	drop_mesh = SphereMesh.new()
	drop_mesh.radius = 0.05
	drop_mesh.height = 0.1
	drop_mesh.radial_segments = 6
	drop_mesh.rings = 3

	spark_mesh = BoxMesh.new()
	spark_mesh.size = Vector3(0.025, 0.2, 0.025)

	splat_mesh = CylinderMesh.new()
	splat_mesh.top_radius = 0.5
	splat_mesh.bottom_radius = 0.5
	splat_mesh.height = 0.01
	splat_mesh.radial_segments = 14
	splat_mesh.rings = 1


func reset() -> void:
	_splats.clear()
	Engine.time_scale = 1.0
	_hitstop_until = 0


func _process(_delta: float) -> void:
	if _hitstop_until > 0 and Time.get_ticks_msec() >= _hitstop_until:
		Engine.time_scale = 1.0
		_hitstop_until = 0


# ---------------------------------------------------------------- yardımcılar

func mat(c: Color, metallic := 0.0, roughness := 0.7) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.metallic = metallic
	m.roughness = roughness
	return m


func emissive(c: Color, energy := 4.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0, 0, 0)
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = energy
	return m


func _ok() -> bool:
	return world != null and is_instance_valid(world)


# ---------------------------------------------------------------- zaman ve kamera

## Oyunu çok kısa süre neredeyse dondurur. Vuruşa "ağırlık" veren şey bu.
func hitstop(sec: float) -> void:
	if sec <= 0.0:
		return
	var now := Time.get_ticks_msec()
	if now - _last_hitstop < 90:
		return
	_last_hitstop = now
	Engine.time_scale = 0.03
	_hitstop_until = maxi(_hitstop_until, now + int(sec * 1000.0))


func shake(amount: float) -> void:
	if camera != null and is_instance_valid(camera):
		camera.add_trauma(amount)


# ---------------------------------------------------------------- parçacıklar

func _burst(pos: Vector3, dir: Vector3, amount: int, m: Material, mesh: Mesh,
		vmin: float, vmax: float, spread: float, gravity: float, life: float,
		smin: float, smax: float, align := false) -> void:
	if not _ok() or amount <= 0:
		return
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.emitting = false
	p.amount = amount
	p.lifetime = life
	p.explosiveness = 1.0
	p.mesh = mesh
	p.material_override = m
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.direction = dir
	p.spread = spread
	p.initial_velocity_min = vmin
	p.initial_velocity_max = vmax
	p.gravity = Vector3(0, gravity, 0)
	p.scale_amount_min = smin
	p.scale_amount_max = smax
	if align:
		p.set_particle_flag(CPUParticles3D.PARTICLE_FLAG_ALIGN_Y_TO_VELOCITY, true)
	world.add_child(p)
	p.global_position = pos
	p.emitting = true
	get_tree().create_timer(life + 0.4).timeout.connect(p.queue_free)


## Mermi ete girdiğinde: mermi yönünde kan fışkırması + yere damla.
func blood_spray(pos: Vector3, dir: Vector3, power := 1.0) -> void:
	var d := (dir + Vector3(0, 0.35, 0)).normalized()
	_burst(pos, d, int(14.0 * power), blood_mat, drop_mesh, 3.0, 8.5 * power, 28.0, -20.0, 0.55, 0.6, 1.6)
	if randf() < 0.6:
		blood_splat(pos + dir * randf_range(0.6, 1.8), randf_range(0.22, 0.5))


## Zombi öldüğünde: büyük kan patlaması + yere birkaç gölcük.
func blood_burst(pos: Vector3, dir: Vector3) -> void:
	var d := (dir + Vector3(0, 0.8, 0)).normalized()
	_burst(pos, d, 42, blood_mat, drop_mesh, 2.0, 10.0, 75.0, -20.0, 0.8, 0.8, 2.3)
	for i in 4:
		var off := Vector3(randf_range(-0.8, 0.8), 0, randf_range(-0.8, 0.8))
		blood_splat(pos + off + dir * randf_range(0.5, 2.5), randf_range(0.4, 0.9))


func blood_splat(pos: Vector3, size: float) -> void:
	if not _ok():
		return
	var m := MeshInstance3D.new()
	m.mesh = splat_mesh
	m.material_override = blood_floor_mat
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(m)
	m.global_position = Vector3(pos.x, 0.004 + randf() * 0.012, pos.z)
	m.rotation.y = randf() * TAU
	m.scale = Vector3(size * 2.0 * randf_range(0.8, 1.5), 1.0, size * 2.0)
	_splats.append(m)
	if _splats.size() > MAX_SPLATS:
		var old = _splats.pop_front()
		if is_instance_valid(old):
			old.queue_free()


## Metal zırha vuruş: kıvılcım + anlık sıcak ışık.
func sparks(pos: Vector3, normal: Vector3, big := false) -> void:
	var n := normal if normal.length() > 0.1 else Vector3.UP
	_burst(pos, (n + Vector3(0, 0.3, 0)).normalized(), 26 if big else 10, spark_mat, spark_mesh,
			5.0, 13.0, 55.0, -14.0, 0.3, 0.6, 1.3, true)
	flash_light(pos, Color(1.0, 0.7, 0.35), 6.0 if big else 2.5, 4.0, 0.07)


## Duvara/engele vuruş: küçük soğuk toz.
func wall_hit(pos: Vector3, normal: Vector3) -> void:
	var n := normal if normal.length() > 0.1 else Vector3.UP
	_burst(pos, n, 6, dust_mat, spark_mesh, 2.0, 5.0, 40.0, -6.0, 0.22, 0.4, 0.8, true)


func flash_light(pos: Vector3, color: Color, energy: float, rng: float, dur: float) -> void:
	if not _ok():
		return
	var l := OmniLight3D.new()
	l.light_color = color
	l.light_energy = energy
	l.omni_range = rng
	world.add_child(l)
	l.global_position = pos
	var t := l.create_tween()
	t.tween_property(l, "light_energy", 0.0, dur)
	t.tween_callback(l.queue_free)


func _tracer_mat(c: Color) -> StandardMaterial3D:
	var key := c.to_html()
	if not _tracer_mats.has(key):
		_tracer_mats[key] = emissive(c, 7.0)
	return _tracer_mats[key]


func tracer(from: Vector3, to: Vector3, color: Color) -> void:
	if not _ok():
		return
	var length := from.distance_to(to)
	if length < 0.05:
		return
	var m := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.035, 0.035, length)
	m.mesh = bm
	m.material_override = _tracer_mat(color)
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(m)
	m.global_position = (from + to) * 0.5
	m.look_at(to, Vector3.UP)
	var t := m.create_tween()
	t.tween_property(m, "scale", Vector3(0.05, 0.05, 1.0), 0.07)
	t.tween_callback(m.queue_free)


# ---------------------------------------------------------------- fiziksel parçalar

func _chunk(size: Vector3, m: Material) -> RigidBody3D:
	var b := RigidBody3D.new()
	b.collision_layer = 8
	b.collision_mask = 1
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = size
	cs.shape = sh
	b.add_child(cs)
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = m
	b.add_child(mi)
	return b


## Pompalı yakından vurunca: zombi et parçalarına ayrılır.
func gibs(pos: Vector3, dir: Vector3, count: int) -> void:
	if not _ok():
		return
	for i in count:
		var s := randf_range(0.1, 0.28)
		var size := Vector3(s, s * randf_range(0.6, 1.4), s * randf_range(0.6, 1.4))
		var b := _chunk(size, flesh_mat if randf() < 0.6 else blood_mat)
		world.add_child(b)
		b.global_position = pos + Vector3(randf_range(-0.3, 0.3), randf_range(-0.4, 0.4), randf_range(-0.3, 0.3))
		b.linear_velocity = dir * randf_range(3.0, 9.0) + Vector3(randf_range(-3, 3), randf_range(3, 8), randf_range(-3, 3))
		b.angular_velocity = Vector3(randf_range(-15, 15), randf_range(-15, 15), randf_range(-15, 15))
		get_tree().create_timer(randf_range(3.5, 5.0)).timeout.connect(b.queue_free)


# ---------------------------------------------------------------- ateş ve patlama

var _fire_mat: StandardMaterial3D
var _smoke_mat: StandardMaterial3D
var _acid_mat: StandardMaterial3D
var _quad: QuadMesh
var _fire_ramp: Gradient
var _smoke_ramp: Gradient
var _grow_curve: Curve
var scorch_mat: StandardMaterial3D


func _soft_circle() -> GradientTexture2D:
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = 64
	t.height = 64
	return t


func _particle_mat(additive: bool, tint: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD if additive else BaseMaterial3D.BLEND_MODE_MIX
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.vertex_color_use_as_albedo = true
	m.albedo_texture = _soft_circle()
	m.albedo_color = tint
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


func _init_fire() -> void:
	if _fire_mat != null:
		return
	_fire_mat = _particle_mat(true, Color(4.0, 4.0, 4.0, 1.0))
	_smoke_mat = _particle_mat(false, Color(1, 1, 1, 1))
	_acid_mat = _particle_mat(true, Color(2.5, 3.0, 1.0, 1.0))
	_quad = QuadMesh.new()
	_quad.size = Vector2(1, 1)
	_fire_ramp = Gradient.new()
	_fire_ramp.set_color(0, Color(1.0, 0.95, 0.7, 1.0))
	_fire_ramp.set_color(1, Color(0.15, 0.02, 0.0, 0.0))
	_fire_ramp.add_point(0.25, Color(1.0, 0.55, 0.12, 1.0))
	_fire_ramp.add_point(0.6, Color(0.7, 0.12, 0.02, 0.7))
	_smoke_ramp = Gradient.new()
	_smoke_ramp.set_color(0, Color(0.1, 0.09, 0.09, 0.0))
	_smoke_ramp.set_color(1, Color(0.05, 0.05, 0.05, 0.0))
	_smoke_ramp.add_point(0.15, Color(0.12, 0.1, 0.1, 0.7))
	_grow_curve = Curve.new()
	_grow_curve.add_point(Vector2(0, 0.35))
	_grow_curve.add_point(Vector2(1, 1.0))
	scorch_mat = mat(Color(0.02, 0.02, 0.02), 0.0, 0.9)


## Alev silahı ve yanan yaratıklar için sürekli alev yayıcı
func make_fire_emitter(amount: int, life: float, vmin: float, vmax: float, spread: float, smin: float, smax: float) -> CPUParticles3D:
	_init_fire()
	var p := CPUParticles3D.new()
	p.amount = amount
	p.lifetime = life
	p.mesh = _quad
	p.material_override = _fire_mat
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.local_coords = false
	p.direction = Vector3(0, 0, -1)
	p.spread = spread
	p.initial_velocity_min = vmin
	p.initial_velocity_max = vmax
	p.gravity = Vector3(0, 2.5, 0)
	p.damping_min = 2.0
	p.damping_max = 4.0
	p.scale_amount_min = smin
	p.scale_amount_max = smax
	p.scale_amount_curve = _grow_curve
	p.color_ramp = _fire_ramp
	p.angle_min = 0.0
	p.angle_max = 360.0
	p.emitting = false
	return p


func _cloud(pos: Vector3, amount: int, m: Material, ramp: Gradient, life: float, vmin: float, vmax: float,
		smin: float, smax: float, gravity: float) -> void:
	if not _ok():
		return
	_init_fire()
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.explosiveness = 0.9
	p.amount = amount
	p.lifetime = life
	p.mesh = _quad
	p.material_override = m
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.direction = Vector3.UP
	p.spread = 180.0
	p.initial_velocity_min = vmin
	p.initial_velocity_max = vmax
	p.gravity = Vector3(0, gravity, 0)
	p.damping_min = 3.0
	p.damping_max = 6.0
	p.scale_amount_min = smin
	p.scale_amount_max = smax
	p.scale_amount_curve = _grow_curve
	p.color_ramp = ramp
	p.angle_max = 360.0
	world.add_child(p)
	p.global_position = pos
	p.emitting = true
	get_tree().create_timer(life + 0.5).timeout.connect(p.queue_free)


func scorch(pos: Vector3, size: float) -> void:
	if not _ok():
		return
	_init_fire()
	var m := MeshInstance3D.new()
	m.mesh = splat_mesh
	m.material_override = scorch_mat
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(m)
	m.global_position = Vector3(pos.x, 0.003, pos.z)
	m.scale = Vector3(size * 2.0, 1.0, size * 2.0)
	m.rotation.y = randf() * TAU
	_splats.append(m)


## PATLAMA: ateş topu, duman, kıvılcım, yanık izi, güçlü sarsıntı ve alan hasarı.
## Yaratıkları parçalar, uzuvlarını koparır, yakındaki varilleri zincirleme patlatır.
func explode(pos: Vector3, radius: float, dmg: float, kb: float) -> void:
	if not _ok():
		return
	_init_fire()
	flash_light(pos + Vector3(0, 1.0, 0), Color(1.0, 0.55, 0.2), 16.0, radius * 3.0, 0.4)
	_cloud(pos, 34, _fire_mat, _fire_ramp, 0.7, 2.0, radius * 1.3, 1.5, 3.5, 3.0)
	_cloud(pos + Vector3(0, 0.5, 0), 24, _smoke_mat, _smoke_ramp, 2.2, 1.0, 3.5, 2.0, 4.5, 2.0)
	_burst(pos, Vector3.UP, 30, spark_mat, spark_mesh, 8.0, 20.0, 90.0, -12.0, 0.6, 0.8, 1.6, true)
	scorch(pos, radius * 0.45)
	shake(0.9)
	hitstop(0.07)
	Sfx.play("boom", 0.0, 0.08, 40)

	for z in get_tree().get_nodes_in_group("zombies"):
		var zp: Vector3 = z.global_position
		var d := Vector2(zp.x - pos.x, zp.z - pos.z).length()
		if d < radius and z.has_method("take_explosion"):
			var f := 1.0 - (d / radius) * 0.65
			var dir := Vector3(zp.x - pos.x, 0, zp.z - pos.z)
			dir = dir.normalized() if dir.length() > 0.05 else Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()
			z.take_explosion(dmg * f, dir, kb * f, pos)
	for b in get_tree().get_nodes_in_group("explosive"):
		var bp: Vector3 = b.global_position
		if bp.distance_to(pos) < radius and b.has_method("take_explosion"):
			b.take_explosion(dmg, Vector3.ZERO, 0.0, pos)


## Şişko mutant patlayınca: yeşil-sarı asit bulutu ve sıçrayan asit
func acid_burst(pos: Vector3) -> void:
	if not _ok():
		return
	_init_fire()
	var ramp := Gradient.new()
	ramp.set_color(0, Color(0.8, 1.0, 0.3, 1.0))
	ramp.set_color(1, Color(0.2, 0.4, 0.0, 0.0))
	_cloud(pos, 30, _acid_mat, ramp, 0.9, 2.0, 7.0, 0.8, 2.2, -4.0)
	flash_light(pos, Color(0.6, 1.0, 0.2), 8.0, 8.0, 0.3)
	shake(0.5)
	Sfx.play("splat", 2.0, 0.05, 0, 0.7)


## Animasyonlu (iskeletli) modelden bir uzvun ağını o anki pozuyla kesip çıkarır.
## bone_set: kopan kemiklerin numaraları. Dönen: { mesh, center } (iskelet uzayında) ya da boş.
func cut_skinned_part(meshes: Array, skel: Skeleton3D, bone_set: Dictionary) -> Dictionary:
	var out := ArrayMesh.new()
	var sum := Vector3.ZERO
	var count := 0
	for mi in meshes:
		if not is_instance_valid(mi) or mi.mesh == null or mi.skin == null:
			continue
		var skin: Skin = mi.skin
		var bind_bone: Array[int] = []
		var bind_xf: Array[Transform3D] = []
		for i in skin.get_bind_count():
			var bi := skin.get_bind_bone(i)
			if bi < 0:
				bi = skel.find_bone(skin.get_bind_name(i))
			bind_bone.append(bi)
			bind_xf.append(skel.get_bone_global_pose(bi) * skin.get_bind_pose(i) if bi >= 0 else Transform3D())
		var src: Mesh = mi.mesh
		for s in src.get_surface_count():
			var arr := src.surface_get_arrays(s)
			var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var norms = arr[Mesh.ARRAY_NORMAL]
			var uvs = arr[Mesh.ARRAY_TEX_UV]
			var bones = arr[Mesh.ARRAY_BONES]
			var weights = arr[Mesh.ARRAY_WEIGHTS]
			var idx = arr[Mesh.ARRAY_INDEX]
			var n := verts.size()
			if bones == null or weights == null or n == 0:
				continue
			var k: int = bones.size() / n
			var inside := PackedByteArray()
			inside.resize(n)
			var pos := PackedVector3Array()
			pos.resize(n)
			var nor := PackedVector3Array()
			nor.resize(n)
			var has_n: bool = norms != null and norms.size() == n
			for v in n:
				var w_in := 0.0
				var p := Vector3.ZERO
				var nn := Vector3.ZERO
				for j in k:
					var w: float = weights[v * k + j]
					if w <= 0.0:
						continue
					var bind: int = bones[v * k + j]
					if bind < 0 or bind >= bind_bone.size():
						continue
					if bone_set.has(bind_bone[bind]):
						w_in += w
					var t: Transform3D = bind_xf[bind]
					p += (t * verts[v]) * w
					if has_n:
						nn += (t.basis * norms[v]) * w
				inside[v] = 1 if w_in > 0.5 else 0
				pos[v] = p
				nor[v] = nn.normalized()
			if idx == null or idx.size() == 0:
				idx = PackedInt32Array(range(n))
			var remap := {}
			var nv := PackedVector3Array()
			var nn_arr := PackedVector3Array()
			var nuv := PackedVector2Array()
			var ni := PackedInt32Array()
			for t in range(0, idx.size(), 3):
				var a: int = idx[t]
				var b: int = idx[t + 1]
				var c: int = idx[t + 2]
				if inside[a] == 0 or inside[b] == 0 or inside[c] == 0:
					continue
				for vi in [a, b, c]:
					if not remap.has(vi):
						remap[vi] = nv.size()
						nv.append(pos[vi])
						nn_arr.append(nor[vi])
						if uvs != null and uvs.size() == n:
							nuv.append(uvs[vi])
						sum += pos[vi]
						count += 1
					ni.append(remap[vi])
			if ni.is_empty():
				continue
			var new_arr := []
			new_arr.resize(Mesh.ARRAY_MAX)
			new_arr[Mesh.ARRAY_VERTEX] = nv
			new_arr[Mesh.ARRAY_NORMAL] = nn_arr
			if nuv.size() == nv.size():
				new_arr[Mesh.ARRAY_TEX_UV] = nuv
			new_arr[Mesh.ARRAY_INDEX] = ni
			out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, new_arr)
			out.surface_set_material(out.get_surface_count() - 1, mi.get_active_material(s))
	if out.get_surface_count() == 0 or count == 0:
		return {}
	return {"mesh": out, "center": sum / float(count)}


## Kesilen gerçek uzuv ağını fizikle fırlatır; uçarken kan damlatır.
func skinned_limb(cut: Dictionary, skel: Skeleton3D, dir: Vector3) -> void:
	if not _ok() or cut.is_empty():
		return
	var mesh: ArrayMesh = cut["mesh"]
	var c: Vector3 = cut["center"]
	var sx := skel.global_transform
	var B := sx.basis
	var b := RigidBody3D.new()
	b.collision_layer = 8
	b.collision_mask = 1
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	var size := mesh.get_aabb().size * B.get_scale()
	sh.size = Vector3(maxf(size.x, 0.1), maxf(size.y, 0.1), maxf(size.z, 0.1))
	cs.shape = sh
	b.add_child(cs)
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.transform = Transform3D(B, -(B * c))
	b.add_child(mi)
	world.add_child(b)
	b.global_position = sx * c
	cs.position = mi.transform * mesh.get_aabb().get_center()
	b.linear_velocity = dir * randf_range(4.0, 8.0) + Vector3(randf_range(-1.5, 1.5), randf_range(3.0, 6.0), randf_range(-1.5, 1.5))
	b.angular_velocity = Vector3(randf_range(-12, 12), randf_range(-12, 12), randf_range(-12, 12))
	blood_fountain(b, Vector3.ZERO, Vector3.UP, 0.8)
	get_tree().create_timer(9.0).timeout.connect(b.queue_free)


## Kopan uzuv: zombinin gerçek parçası (kafa gözleriyle, kol, bacak) fizik gövdesine taşınıp fırlar.
func limb(node: Node3D, center: Vector3, size: Vector3, dir: Vector3) -> void:
	if not _ok():
		return
	var b := RigidBody3D.new()
	b.collision_layer = 8
	b.collision_mask = 1
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(maxf(size.x, 0.08), maxf(size.y, 0.08), maxf(size.z, 0.08))
	cs.shape = sh
	b.add_child(cs)
	world.add_child(b)
	b.global_position = center
	node.reparent(b, true)
	b.linear_velocity = dir * randf_range(4.0, 8.0) + Vector3(randf_range(-1.5, 1.5), randf_range(3.0, 6.0), randf_range(-1.5, 1.5))
	b.angular_velocity = Vector3(randf_range(-12, 12), randf_range(-12, 12), randf_range(-12, 12))
	blood_fountain(b, Vector3.ZERO, Vector3.UP, 0.8)
	get_tree().create_timer(9.0).timeout.connect(b.queue_free)


## Kesik yerden birkaç saniye boyunca fışkıran kan.
func blood_fountain(parent: Node3D, local_pos: Vector3, local_dir: Vector3, duration: float) -> void:
	if parent == null or not is_instance_valid(parent):
		return
	var p := CPUParticles3D.new()
	p.amount = 40
	p.lifetime = 0.6
	p.mesh = drop_mesh
	p.material_override = blood_mat
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.direction = local_dir.normalized() if local_dir.length() > 0.01 else Vector3.UP
	p.spread = 18.0
	p.initial_velocity_min = 2.5
	p.initial_velocity_max = 5.0
	p.gravity = Vector3(0, -14, 0)
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.3
	p.local_coords = false
	parent.add_child(p)
	p.position = local_pos
	p.emitting = true
	get_tree().create_timer(duration).timeout.connect(func():
		if is_instance_valid(p):
			p.emitting = false
	)
	get_tree().create_timer(duration + 0.8).timeout.connect(p.queue_free)


## Zırh kırılınca: metal plaka gövdeden kopup uçar.
func debris(xf: Transform3D, size: Vector3, m: Material, dir: Vector3) -> void:
	if not _ok():
		return
	var b := _chunk(size, m)
	world.add_child(b)
	b.global_transform = xf
	b.linear_velocity = dir * randf_range(4.0, 8.0) + Vector3(randf_range(-2, 2), randf_range(4, 7), randf_range(-2, 2))
	b.angular_velocity = Vector3(randf_range(-10, 10), randf_range(-10, 10), randf_range(-10, 10))
	get_tree().create_timer(6.0).timeout.connect(b.queue_free)
