extends RefCounted
## YETENEK EFEKTLERİ: tüm yeteneklerin ortak görsel parçaları
##  sparks     merkezden saçılan parlak kıvılcımlar
##  shockwave  yerde hızla genişleyip sönen ışık halkası
##  pillar     gökten inen ışık sütunu
##  scorch     yerde bir süre parlayıp sönen yanık/ışık izi
##  trail      hareket eden bir şeyin arkasında kalan ışıltı (dünyada kalır)


static func _add(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.albedo_color = c
	return m


static func sparks(at: Vector3, col: Color, n := 18, up := 0.7, power := 1.0) -> void:
	var m: StandardMaterial3D = Fx.emissive(col.lerp(Color.WHITE, 0.4), 7.0)
	var s := SphereMesh.new()
	s.radius = 0.05
	s.height = 0.1
	s.radial_segments = 6
	s.rings = 3
	Fx._burst(at, Vector3(0, up, 0).normalized() if up > 0.0 else Vector3.UP, n, m, s, 3.0 * power, 8.0 * power, 85.0, -9.0, 0.45, 0.5, 1.3)


static func shockwave(parent: Node, at: Vector3, col: Color, r: float, dur := 0.35) -> void:
	if parent == null:
		return
	var mi := MeshInstance3D.new()
	var t := TorusMesh.new()
	t.inner_radius = 0.86
	t.outer_radius = 1.0
	t.rings = 64
	t.ring_segments = 6
	mi.mesh = t
	var m := _add(Color(col.r, col.g, col.b, 0.9))
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	mi.global_position = Vector3(at.x, 0.12, at.z)
	mi.scale = Vector3(0.2, 0.3, 0.2)
	var tw := mi.create_tween().set_parallel(true)
	tw.tween_property(mi, "scale", Vector3(r, 0.3, r), dur).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(m, "albedo_color:a", 0.0, dur).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(mi.queue_free)


static func pillar(parent: Node, at: Vector3, col: Color, width := 0.5, h := 9.0, dur := 0.45) -> void:
	if parent == null:
		return
	var mi := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = width * 0.35
	c.bottom_radius = width
	c.height = h
	c.radial_segments = 12
	mi.mesh = c
	var m := _add(Color(col.r, col.g, col.b, 0.75))
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	mi.global_position = Vector3(at.x, h * 0.5, at.z)
	mi.scale = Vector3(1.6, 1.0, 1.6)
	var tw := mi.create_tween().set_parallel(true)
	tw.tween_property(mi, "scale", Vector3(0.05, 1.0, 0.05), dur).set_ease(Tween.EASE_IN)
	tw.tween_property(m, "albedo_color:a", 0.0, dur)
	tw.chain().tween_callback(mi.queue_free)


static func scorch(parent: Node, at: Vector3, col: Color, r: float, dur := 1.4) -> void:
	if parent == null:
		return
	var mi := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = r
	c.bottom_radius = r
	c.height = 0.01
	c.radial_segments = 32
	mi.mesh = c
	var m := _add(Color(col.r, col.g, col.b, 0.28))
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	mi.global_position = Vector3(at.x, 0.03, at.z)
	var tw := mi.create_tween()
	tw.tween_property(m, "albedo_color:a", 0.0, dur).set_ease(Tween.EASE_IN)
	tw.tween_callback(mi.queue_free)


## Hareket eden düğümün arkasında dünyada kalan ışıltı
static func trail(node: Node3D, col: Color, amount := 26, size := 0.09, life := 0.35) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = amount
	p.lifetime = life
	p.local_coords = false
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = size
	p.direction = Vector3.UP
	p.spread = 180.0
	p.gravity = Vector3.ZERO
	p.initial_velocity_min = 0.1
	p.initial_velocity_max = 0.5
	var sm := SphereMesh.new()
	sm.radius = size
	sm.height = size * 2.0
	sm.radial_segments = 6
	sm.rings = 3
	p.mesh = sm
	var m := _add(Color(col.r, col.g, col.b, 0.9))
	m.vertex_color_use_as_albedo = true
	p.material_override = m
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	p.color_ramp = g
	var cv := Curve.new()
	cv.add_point(Vector2(0, 1))
	cv.add_point(Vector2(1, 0.1))
	p.scale_amount_curve = cv
	node.add_child(p)
	return p


## Büyük isabet: halka + sütun + kıvılcım + iz + ışık (yeteneklerin "doruk" anı)
static func impact(parent: Node, at: Vector3, col: Color, r: float, big := false) -> void:
	shockwave(parent, at, col, r * (1.15 if big else 1.0))
	if big:
		shockwave(parent, at, col.lerp(Color.WHITE, 0.5), r * 0.6, 0.25)
		pillar(parent, at, col, r * 0.35, 10.0)
	sparks(at + Vector3(0, 0.4, 0), col, 26 if big else 14, 0.8, 1.2 if big else 1.0)
	scorch(parent, at, col, r * 0.8)
