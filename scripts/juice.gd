extends RefCounted
## JUICE: oyun hissi efektleri (tek yerde, statik yardımcılar).
##  - constellation_spawn: düşman doğarken yerde bir takımyıldız çizilir (yıldızlar, sonra çizgiler)
##  - ascend: ölen yaratık yıldız tozuna dönüşüp göğe yükselir
##  - ring_wave: genişleyen ince ışık halkası (parry, son vuruş)
##  - boss_constellation: boss ölünce yıldızlar göğe çıkar ve burcun takımyıldızını çizer
##  - zoom_punch: kamerada kısa yakınlaşma
## Telefonda parçacık sayıları yarıya iner.

const PATTERNS := {
	# burcun basitleştirilmiş takımyıldızı: noktalar (x, y; -1..1) ve çizgiler (nokta indisleri)
	"aries": [[Vector2(-1.0, 0.35), Vector2(-0.1, 0.55), Vector2(0.55, 0.3), Vector2(0.95, -0.25)], [[0, 1], [1, 2], [2, 3]]],
	"taurus": [[Vector2(-1.0, 0.9), Vector2(-0.35, 0.15), Vector2(0.0, -0.05), Vector2(0.35, 0.15), Vector2(1.0, 0.95), Vector2(0.15, -0.6), Vector2(-0.5, -0.9)], [[0, 1], [1, 2], [2, 3], [3, 4], [2, 5], [5, 6]]],
	"gemini": [[Vector2(-0.55, 0.95), Vector2(-0.6, 0.2), Vector2(-0.55, -0.9), Vector2(0.45, 0.95), Vector2(0.5, 0.2), Vector2(0.55, -0.9)], [[0, 1], [1, 2], [3, 4], [4, 5], [0, 3], [1, 4]]],
	"cancer": [[Vector2(0.0, 0.1), Vector2(-0.7, 0.8), Vector2(0.75, 0.7), Vector2(0.1, -0.9), Vector2(-0.2, -0.3)], [[0, 1], [0, 2], [0, 4], [4, 3]]],
	"leo": [[Vector2(-1.0, -0.4), Vector2(-0.3, -0.25), Vector2(0.3, -0.1), Vector2(0.55, 0.4), Vector2(0.95, 0.75), Vector2(0.75, 0.05), Vector2(-0.45, 0.35)], [[0, 1], [1, 2], [2, 3], [3, 4], [2, 5], [1, 6], [6, 3]]],
	"virgo": [[Vector2(-1.0, 0.5), Vector2(-0.45, 0.25), Vector2(0.0, 0.3), Vector2(0.4, 0.0), Vector2(0.95, -0.2), Vector2(0.1, -0.5), Vector2(-0.3, -0.85)], [[0, 1], [1, 2], [2, 3], [3, 4], [2, 5], [5, 6]]],
	"libra": [[Vector2(0.0, 0.85), Vector2(-0.7, 0.15), Vector2(0.7, 0.2), Vector2(-0.55, -0.75), Vector2(0.6, -0.7)], [[0, 1], [0, 2], [1, 2], [1, 3], [2, 4]]],
	"scorpio": [[Vector2(-1.0, 0.7), Vector2(-0.6, 0.45), Vector2(-0.25, 0.15), Vector2(0.05, -0.25), Vector2(0.45, -0.55), Vector2(0.85, -0.4), Vector2(0.95, 0.05), Vector2(-0.85, 0.15)], [[0, 1], [1, 2], [2, 3], [3, 4], [4, 5], [5, 6], [1, 7]]],
	"sagittarius": [[Vector2(-0.6, -0.3), Vector2(-0.1, -0.1), Vector2(0.4, -0.35), Vector2(0.1, 0.45), Vector2(-0.4, 0.55), Vector2(0.75, 0.6), Vector2(0.95, 0.1)], [[0, 1], [1, 2], [1, 3], [3, 4], [3, 5], [5, 6], [2, 6]]],
	"capricorn": [[Vector2(-1.0, 0.6), Vector2(-0.45, 0.0), Vector2(0.15, -0.7), Vector2(0.95, -0.35), Vector2(0.7, 0.45), Vector2(-0.1, 0.55)], [[0, 1], [1, 2], [2, 3], [3, 4], [4, 5], [5, 0]]],
	"aquarius": [[Vector2(-1.0, 0.7), Vector2(-0.55, 0.35), Vector2(-0.1, 0.55), Vector2(0.25, 0.1), Vector2(0.6, -0.3), Vector2(0.2, -0.75), Vector2(0.95, -0.85)], [[0, 1], [1, 2], [2, 3], [3, 4], [4, 5], [4, 6]]],
	"pisces": [[Vector2(-1.0, 0.75), Vector2(-0.65, 0.4), Vector2(-0.3, 0.05), Vector2(0.05, -0.4), Vector2(0.45, -0.15), Vector2(0.85, 0.1), Vector2(0.95, 0.5), Vector2(0.6, 0.45), Vector2(-0.8, 0.95)], [[0, 1], [1, 2], [2, 3], [3, 4], [4, 5], [5, 6], [6, 7], [7, 5], [0, 8]]],
}


static func _mobile() -> bool:
	return bool(load("res://scripts/game_data.gd").is_mobile())


static func _add_mat(c: Color, energy := 3.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.albedo_color = Color(c.r * energy, c.g * energy, c.b * energy, c.a)
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


static func _star(parent: Node, pos: Vector3, c: Color, r := 0.09) -> MeshInstance3D:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	s.radial_segments = 8
	s.rings = 4
	var mi := MeshInstance3D.new()
	mi.mesh = s
	mi.material_override = _add_mat(c, 4.0)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	mi.global_position = pos
	return mi


## a'dan b'ye ince parlak çizgi (Z ekseni boyunca uzayan kutu)
static func _beam(parent: Node, a: Vector3, b: Vector3, c: Color, w := 0.03) -> MeshInstance3D:
	var bx := BoxMesh.new()
	bx.size = Vector3(w, w, 1.0)
	var mi := MeshInstance3D.new()
	mi.mesh = bx
	mi.material_override = _add_mat(c, 2.5)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	var mid := (a + b) * 0.5
	var d := b - a
	mi.global_position = mid
	if d.length() > 0.001:
		var up := Vector3.UP if absf(d.normalized().dot(Vector3.UP)) < 0.95 else Vector3.RIGHT
		mi.look_at(b, up)
	mi.scale = Vector3(1, 1, d.length())
	return mi


## Düşman doğuşu: yerde beş yıldız belirir, aralarına çizgiler çekilir, sonra söner
static func constellation_spawn(parent: Node3D, pos: Vector3, c: Color, dur := 0.9) -> void:
	if parent == null or not is_instance_valid(parent):
		return
	var root := Node3D.new()
	parent.add_child(root)
	root.global_position = Vector3(pos.x, 0.06, pos.z)
	var pts: Array = []
	var n := 5
	var rot := randf() * TAU
	for i in n:
		var a := rot + TAU * float(i) / float(n) + randf_range(-0.3, 0.3)
		var r := randf_range(0.55, 1.05)
		pts.append(root.global_position + Vector3(cos(a) * r, 0, sin(a) * r))
	var stars: Array = []
	for i in n:
		var s := _star(root, pts[i], c, 0.07)
		s.scale = Vector3.ONE * 0.01
		stars.append(s)
	var tw := root.create_tween()
	for i in n:
		tw.tween_property(stars[i], "scale", Vector3.ONE, dur * 0.12).set_trans(Tween.TRANS_BACK)
	for i in n:
		var ln := _beam(root, pts[i], pts[(i + 2) % n], c, 0.025)
		var full: Vector3 = ln.scale
		ln.scale = Vector3(1, 1, 0.001)
		tw.parallel().tween_property(ln, "scale", full, dur * 0.35).set_delay(dur * 0.06 * float(i))
	tw.tween_interval(0.25)
	tw.tween_property(root, "scale", Vector3(1.4, 1, 1.4), 0.35)
	tw.parallel().tween_callback(func():
		for ch in root.get_children():
			var mi := ch as MeshInstance3D
			if mi != null:
				var m := mi.material_override as StandardMaterial3D
				if m != null:
					root.create_tween().tween_property(m, "albedo_color:a", 0.0, 0.35))
	tw.tween_interval(0.4)
	tw.tween_callback(root.queue_free)


## Ölüm: yıldız tozu sütunu göğe yükselir
static func ascend(parent: Node3D, pos: Vector3, c: Color, size := 1.0) -> void:
	if parent == null or not is_instance_valid(parent):
		return
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.explosiveness = 0.75
	p.amount = int((28.0 if not _mobile() else 14.0) * size)
	p.lifetime = 1.4
	var s := SphereMesh.new()
	s.radius = 0.04
	s.height = 0.08
	s.radial_segments = 6
	s.rings = 3
	p.mesh = s
	p.material_override = _add_mat(c, 3.5)
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 0.5 * size
	p.direction = Vector3.UP
	p.spread = 20.0
	p.gravity = Vector3(0, 2.5, 0)
	p.initial_velocity_min = 1.5
	p.initial_velocity_max = 3.5
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.4
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	p.color_ramp = g
	parent.add_child(p)
	p.global_position = pos
	p.emitting = true
	parent.get_tree().create_timer(2.0).timeout.connect(p.queue_free)


## Genişleyen ışık halkası
static func ring_wave(parent: Node3D, pos: Vector3, c: Color, radius := 3.0, dur := 0.35) -> void:
	if parent == null or not is_instance_valid(parent):
		return
	var t := TorusMesh.new()
	t.inner_radius = 0.92
	t.outer_radius = 1.0
	t.rings = 64
	t.ring_segments = 4
	var mi := MeshInstance3D.new()
	mi.mesh = t
	var m := _add_mat(c, 3.0)
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	mi.global_position = Vector3(pos.x, maxf(pos.y, 0.1), pos.z)
	mi.scale = Vector3(0.3, 0.15, 0.3)
	var tw := mi.create_tween().set_parallel(true)
	tw.tween_property(mi, "scale", Vector3(radius, 0.15, radius), dur).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(m, "albedo_color:a", 0.0, dur)
	tw.chain().tween_callback(mi.queue_free)


## Kamerada kısa yakınlaşma (FOV)
static func zoom_punch(amount := 4.0, dur := 0.25) -> void:
	var fx = Engine.get_main_loop().root.get_node_or_null("Fx")
	if fx == null:
		return
	var cam = fx.get("camera")
	if cam == null or not is_instance_valid(cam) or not (cam is Camera3D):
		return
	var base := float(cam.get_meta("base_fov", cam.fov))
	cam.set_meta("base_fov", base)
	var tw: Tween = cam.create_tween().set_ignore_time_scale(true)
	tw.tween_property(cam, "fov", base - amount, dur * 0.3).set_ease(Tween.EASE_OUT)
	tw.tween_property(cam, "fov", base, dur * 0.7).set_ease(Tween.EASE_IN_OUT)


## Boss'un takımyıldızı: yıldızlar boss'tan göğe uçar, sırayla çizgiler çekilir, bir süre parlar, söner
static func boss_constellation(parent: Node3D, from: Vector3, sg: String, c: Color) -> void:
	if parent == null or not is_instance_valid(parent) or not PATTERNS.has(sg):
		return
	var pat: Array = PATTERNS[sg]
	var pts2: Array = pat[0]
	var edges: Array = pat[1]
	var root := Node3D.new()
	parent.add_child(root)
	# ekranın üst ortasına, kameraya dönük çizilir (kamera açısı ne olursa olsun görünür)
	var fxn = Engine.get_main_loop().root.get_node_or_null("Fx")
	var cam = fxn.get("camera") if fxn != null else null
	var targets: Array = []
	var center := Vector3(0, 4.0, 0)
	if cam != null and is_instance_valid(cam) and cam is Camera3D:
		var vp: Vector2 = cam.get_viewport().get_visible_rect().size
		var depth: float = cam.global_position.distance_to(from) * 0.85
		var sc: float = vp.y * 0.2
		for v in pts2:
			var q: Vector2 = v
			targets.append(cam.project_position(Vector2(vp.x * 0.5 + q.x * sc * 1.3, vp.y * 0.3 - q.y * sc), depth))
		center = cam.project_position(Vector2(vp.x * 0.5, vp.y * 0.3), depth)
	else:
		for v in pts2:
			var q: Vector2 = v
			targets.append(center + Vector3(q.x * 4.0, q.y * 3.0, 0))
	var stars: Array = []
	var tw := root.create_tween()
	for i in targets.size():
		var s := _star(root, from + Vector3(0, 1.5, 0), c, 0.16)
		stars.append(s)
		var tp: Vector3 = targets[i]
		tw.parallel().tween_property(s, "global_position", tp, 0.9 + 0.08 * float(i)).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func():
		Fx.flash_light(center, c, 6.0, 14.0, 0.6)
		Sfx.play("coin", -6.0, 0.0, 0, 0.6))
	for e in edges:
		var a: Vector3 = targets[int(e[0])]
		var b: Vector3 = targets[int(e[1])]
		tw.tween_callback(func():
			var ln := _beam(root, a, b, c, 0.05)
			var full: Vector3 = ln.scale
			ln.position = a + (b - a) * 0.0
			ln.global_position = a
			ln.scale = Vector3(1, 1, 0.001)
			var lt := ln.create_tween().set_parallel(true)
			lt.tween_property(ln, "scale", full, 0.18)
			lt.tween_property(ln, "global_position", (a + b) * 0.5, 0.18)
			Sfx.play("parry", -16.0, 0.05, 0, 1.6))
		tw.tween_interval(0.16)
	tw.tween_interval(2.6)
	tw.tween_callback(func():
		for ch in root.get_children():
			var mi := ch as MeshInstance3D
			if mi != null:
				var m := mi.material_override as StandardMaterial3D
				if m != null:
					root.create_tween().tween_property(m, "albedo_color:a", 0.0, 1.2))
	tw.tween_interval(1.3)
	tw.tween_callback(root.queue_free)


## Element parçacıkları: ateşte yükselen kor, suda düşen damla, havada savrulan tüy gibi esinti, toprakta dökülen yeşil toz
static func element_burst(parent: Node3D, pos: Vector3, dir: Vector3, el: String, amount := 10) -> void:
	if parent == null or not is_instance_valid(parent) or el == "":
		return
	var info: Dictionary = load("res://scripts/elements.gd").INFO.get(el, {})
	if info.is_empty():
		return
	var c: Color = info["col"]
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.explosiveness = 0.85
	p.amount = maxi(int(float(amount) * (0.5 if _mobile() else 1.0)), 3)
	p.lifetime = 0.7
	var s := SphereMesh.new()
	s.radius = 0.035
	s.height = 0.07
	s.radial_segments = 6
	s.rings = 3
	p.mesh = s
	p.material_override = _add_mat(c, 3.0)
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 0.35
	p.direction = (dir + Vector3(0, 0.3, 0)).normalized()
	p.spread = 35.0
	p.initial_velocity_min = 1.5
	p.initial_velocity_max = 4.0
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.5
	match el:
		"fire":
			p.gravity = Vector3(0, 4.0, 0)
		"water":
			p.gravity = Vector3(0, -14.0, 0)
			p.initial_velocity_max = 5.0
		"air":
			p.gravity = Vector3.ZERO
			p.spread = 70.0
			p.initial_velocity_min = 4.0
			p.initial_velocity_max = 7.0
			p.lifetime = 0.45
		"earth":
			p.gravity = Vector3(0, -9.0, 0)
			var b := BoxMesh.new()
			b.size = Vector3(0.07, 0.07, 0.07)
			p.mesh = b
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	p.color_ramp = g
	parent.add_child(p)
	p.global_position = pos
	p.emitting = true
	parent.get_tree().create_timer(1.2).timeout.connect(p.queue_free)


## Dolan uyarı: uyarı alanının içinde, saldırganın olduğu yerden dışa doğru (hatlarda boydan) dolan parlak alan.
## Dolduğu an saldırı gelir. tele: uyarı MeshInstance3D'si; col: uyarı rengi.
static func tele_fill(tele: MeshInstance3D, col: Color) -> void:
	if tele == null:
		return
	var f := tele.get_node_or_null("Fill") as MeshInstance3D
	if f == null:
		f = MeshInstance3D.new()
		f.name = "Fill"
		f.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		m.no_depth_test = false
		f.material_override = m
		f.position = Vector3(0, 0.01, 0)
		tele.add_child(f)
	f.mesh = tele.mesh
	(f.material_override as StandardMaterial3D).albedo_color = Color(col.r, col.g, col.b, 0.28)
	f.scale = Vector3(0.001, 1, 0.001)


static func tele_progress(tele: MeshInstance3D, k: float) -> void:
	if tele == null:
		return
	var f := tele.get_node_or_null("Fill") as MeshInstance3D
	if f == null or tele.mesh == null:
		return
	if f.mesh != tele.mesh:
		f.mesh = tele.mesh
	k = clampf(k, 0.001, 1.0)
	var bb := tele.mesh.get_aabb()
	if bb.size.x < bb.size.z * 0.45:
		f.scale = Vector3(1, 1, k)          # hat: boydan dolar
	else:
		f.scale = Vector3(k, 1, k)          # yelpaze / daire: merkezden dışa
