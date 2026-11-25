extends RefCounted
## YILDIZ KILICI YETENEKLERİ (1, 2, 3 tuşları)
##  1 · STARFALL / YILDIZ YAĞMURU: farenin gösterdiği yere işaret konur, kısa süre sonra yıldızlar düşer.
##  2 · LIGHT WAVE / IŞIK DALGASI: kılıçtan ileriye uçan, düşmanların içinden geçen altın hilal.
##  3 · CONSTELLATION STEP / TAKIMYILDIZI ADIMI: nişan yönüne ışınlan; geçtiğin yolda yıldızlar
##      belirir, aralarına çizgi çekilir ve takımyıldızı patlar.

const SlashFx = preload("res://scripts/slash_fx.gd")
const GOLD := Color(1.0, 0.85, 0.45)


static func glow_mat(c: Color, e: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = e
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m


static func add_mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.albedo_color = c
	return m


## Bir alandaki düşmanlara hasar verir; kaç düşmana değdiğini döndürür
static func hurt_area(tree: SceneTree, center: Vector3, r: float, dmg: float, kb: float, heavy := false) -> int:
	var n := 0
	for e in tree.get_nodes_in_group("enemies"):
		if not is_instance_valid(e) or e.dead:
			continue
		var d: Vector3 = e.global_position - center
		d.y = 0.0
		if d.length() <= r + float(e.radius):
			var dir := d.normalized() if d.length() > 0.05 else Vector3.FORWARD
			e.take_hit(dmg, dir, kb, heavy)
			n += 1
	return n


## Yerde parlayan halka (işaret)
static func ring(r: float, c: Color) -> MeshInstance3D:
	var t := TorusMesh.new()
	t.inner_radius = r - 0.06
	t.outer_radius = r
	t.rings = 64
	t.ring_segments = 4
	var mi := MeshInstance3D.new()
	mi.mesh = t
	mi.material_override = add_mat(c)
	mi.scale = Vector3(1, 0.1, 1)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


# ---------------------------------------------------------------- 1 · yıldız yağmuru

class Starfall extends Node3D:
	var radius := 2.4
	var delay := 0.5
	var dmg := 18.0
	var count := 6
	var star_r := 0.16
	var col := Color(1.0, 0.9, 0.6)
	var _t := 0.0
	var _stars: Array = []
	var _mark: MeshInstance3D
	var _done := false

	func _ready() -> void:
		_mark = load("res://scripts/star_skills.gd").ring(radius, Color(1.0, 0.8, 0.4, 0.8))
		_mark.position.y = 0.05
		add_child(_mark)
		var gm = load("res://scripts/star_skills.gd").glow_mat(col, 8.0)
		for i in count:
			var s := MeshInstance3D.new()
			var sm := SphereMesh.new()
			sm.radius = star_r
			sm.height = star_r * 2.0
			s.mesh = sm
			s.material_override = gm
			var a := randf() * TAU
			var rr := 0.0 if count == 1 else sqrt(randf()) * radius * 0.8
			var land := Vector3(cos(a) * rr, 0.0, sin(a) * rr)
			s.position = land + Vector3(-3.0, 12.0 + randf() * 3.0, -3.0)
			s.set_meta("land", land)
			s.set_meta("t0", randf() * 0.18)
			add_child(s)
			_stars.append(s)
		Sfx.play("dash", -10.0, 0.05, 0, 0.6)

	func _process(delta: float) -> void:
		_t += delta
		_mark.scale = Vector3(1.0 + sin(_t * 18.0) * 0.03, 0.1, 1.0 + sin(_t * 18.0) * 0.03)
		for s in _stars:
			if not is_instance_valid(s):
				continue
			var k := clampf((_t - float(s.get_meta("t0"))) / delay, 0.0, 1.0)
			var land: Vector3 = s.get_meta("land")
			s.position = (land + Vector3(-3.0, 13.0, -3.0)).lerp(land, k * k)
		if not _done and _t >= delay + 0.18:
			_done = true
			var p := global_position
			var n: int = load("res://scripts/star_skills.gd").hurt_area(get_tree(), p, radius, dmg, 6.0, true)
			Fx.flash_light(p + Vector3(0, 1, 0), Color(1.0, 0.85, 0.5), 8.0, 8.0, 0.4)
			Fx.shake(0.4)
			if n > 0:
				Fx.hitstop(0.06)
			Sfx.play("boom", -12.0, 0.1, 0, 1.8)
			var ex = load("res://scripts/slash_fx.gd").make(0.0, TAU, 0.2, radius, col, 0.35)
			add_child(ex)
			ex.position.y = 0.3
			for s in _stars:
				s.queue_free()
			_stars.clear()
			_mark.visible = false
		if _t > delay + 0.8:
			queue_free()


# ---------------------------------------------------------------- 2 · ışık dalgası

class LightWave extends Node3D:
	var dir := Vector3.FORWARD
	var speed := 17.0
	var max_dist := 11.0
	var dmg := 20.0
	var width := 1.0
	var col := Color(1.0, 0.88, 0.5)
	var _dist := 0.0
	var _hit: Array = []
	var _mesh: MeshInstance3D

	func _ready() -> void:
		_mesh = load("res://scripts/slash_fx.gd").make(-width, width, 0.5, 1.4, col, 10.0)
		add_child(_mesh)
		look_at(global_position + dir, Vector3.UP)
		Sfx.play("dash", -8.0, 0.05, 0, 1.9)

	func _process(delta: float) -> void:
		var step := speed * delta
		global_position += dir * step
		_dist += step
		for e in get_tree().get_nodes_in_group("enemies"):
			if not is_instance_valid(e) or e.dead or _hit.has(e):
				continue
			var d: Vector3 = e.global_position - global_position
			d.y = 0.0
			if d.length() < 0.5 + width * 0.8 + float(e.radius):
				_hit.append(e)
				e.take_hit(dmg, dir, 6.0, false)
				Fx.hitstop(0.03)
				Sfx.play("hit", -6.0, 0.1, 30)
		var fade := 1.0 - clampf((_dist - max_dist * 0.7) / (max_dist * 0.3), 0.0, 1.0)
		var wm := _mesh.material_override as StandardMaterial3D
		if wm != null:
			wm.albedo_color.a = fade
		if _dist >= max_dist:
			queue_free()


# ---------------------------------------------------------------- 3 · takımyıldızı adımı

class ConstellationPath extends Node3D:
	var points: Array = []          # dünya koordinatında yıldız konumları
	var delay := 0.4
	var dmg := 26.0
	var _t := 0.0
	var _done := false
	var _lines: Array = []

	func _ready() -> void:
		var lib = load("res://scripts/star_skills.gd")
		var gm = lib.glow_mat(Color(1.0, 0.9, 0.6), 7.0)
		var lm = lib.add_mat(Color(1.0, 0.85, 0.45, 0.9))
		for i in points.size():
			var s := MeshInstance3D.new()
			var sm := SphereMesh.new()
			sm.radius = 0.12
			sm.height = 0.24
			s.mesh = sm
			s.material_override = gm
			add_child(s)
			s.global_position = points[i] + Vector3(0, 1.0, 0)
			if i > 0:
				var a: Vector3 = points[i - 1] + Vector3(0, 1.0, 0)
				var b: Vector3 = points[i] + Vector3(0, 1.0, 0)
				var ln := MeshInstance3D.new()
				var bm := BoxMesh.new()
				bm.size = Vector3(0.05, 0.05, a.distance_to(b))
				ln.mesh = bm
				ln.material_override = lm
				add_child(ln)
				ln.global_position = (a + b) * 0.5
				if a.distance_to(b) > 0.01:
					ln.look_at(b, Vector3.UP)
				ln.scale = Vector3(1, 1, 0.01)
				_lines.append(ln)

	func _process(delta: float) -> void:
		_t += delta
		# çizgiler yıldızdan yıldıza uzar
		for i in _lines.size():
			var k := clampf((_t - float(i) * 0.04) / 0.18, 0.0, 1.0)
			(_lines[i] as Node3D).scale = Vector3(1, 1, maxf(k, 0.01))
		if not _done and _t >= delay:
			_done = true
			var lib = load("res://scripts/star_skills.gd")
			var hit: Array = []
			for p in points:
				for e in get_tree().get_nodes_in_group("enemies"):
					if not is_instance_valid(e) or e.dead or hit.has(e):
						continue
					var d: Vector3 = e.global_position - p
					d.y = 0.0
					if d.length() < 1.5 + float(e.radius):
						hit.append(e)
						e.take_hit(dmg, d.normalized() if d.length() > 0.05 else Vector3.FORWARD, 7.0, true)
			Fx.flash_light(points[points.size() / 2] + Vector3(0, 1, 0), Color(1.0, 0.85, 0.5), 7.0, 9.0, 0.35)
			Fx.shake(0.45)
			if hit.size() > 0:
				Fx.hitstop(0.08)
			Sfx.play("coin", -6.0, 0.0, 0, 0.7)
			Sfx.play("boom", -14.0, 0.0, 0, 2.0)
			for c in get_children():
				if c is MeshInstance3D:
					c.visible = false
			for p in points:
				var ex = load("res://scripts/slash_fx.gd").make(0.0, TAU, 0.1, 1.2, Color(1.0, 0.9, 0.6), 0.3)
				add_child(ex)
				ex.global_position = p + Vector3(0, 0.6, 0)
		if _t > delay + 0.6:
			queue_free()


# ---------------------------------------------------------------- anlık patlama (kahramanın etrafında ya da farenin yerinde)

class Burst extends Node3D:
	var radius := 3.0
	var dmg := 15.0
	var kb := 8.0
	var stun := 0.0
	var pull := false
	var delay := 0.0
	var col := Color(1.0, 0.85, 0.5)
	var _t := 0.0
	var _done := false
	var _mark: MeshInstance3D

	func _ready() -> void:
		if delay > 0.0:
			_mark = load("res://scripts/star_skills.gd").ring(radius, Color(col.r, col.g, col.b, 0.8))
			_mark.position.y = 0.05
			add_child(_mark)

	func _process(delta: float) -> void:
		_t += delta
		if _mark != null:
			var k := clampf(_t / maxf(delay, 0.01), 0.0, 1.0)
			_mark.scale = Vector3(0.3 + 0.7 * k, 0.1, 0.3 + 0.7 * k)
		if not _done and _t >= delay:
			_done = true
			if _mark != null:
				_mark.visible = false
			var p := global_position
			var hit := 0
			for e in get_tree().get_nodes_in_group("enemies"):
				if not is_instance_valid(e) or e.dead:
					continue
				var d: Vector3 = e.global_position - p
				d.y = 0.0
				if d.length() <= radius + float(e.radius):
					hit += 1
					if pull:
						e.pull_to(p, 16.0)
						e.take_hit(dmg, -d.normalized() if d.length() > 0.05 else Vector3.FORWARD, 0.0, false)
					else:
						e.take_hit(dmg, d.normalized() if d.length() > 0.05 else Vector3.FORWARD, kb, kb >= 9.0)
					if stun > 0.0 and not e.dead:
						e.stun(stun)
			var ex = load("res://scripts/slash_fx.gd").make(0.0, TAU, 0.2 if not pull else radius * 0.6, radius, col, 0.35)
			add_child(ex)
			ex.position.y = 0.4
			Fx.flash_light(p + Vector3(0, 1, 0), col, 5.0, radius * 2.5, 0.3)
			Fx.shake(0.3)
			if hit > 0:
				Fx.hitstop(0.05)
			Sfx.play("boom", -14.0, 0.1, 0, 1.8)
		if _t > delay + 0.6:
			queue_free()


# ---------------------------------------------------------------- yakıcı hale (Taç)

class Aura extends Node3D:
	var target = null
	var radius := 2.8
	var dmg := 5.0
	var tick := 0.45
	var duration := 5.0
	var col := Color(1.0, 0.7, 0.25)
	var _t := 0.0
	var _next := 0.0
	var _ring: MeshInstance3D
	var _light: OmniLight3D

	func _ready() -> void:
		_ring = load("res://scripts/star_skills.gd").ring(radius, Color(col.r, col.g, col.b, 0.7))
		_ring.position.y = 0.06
		add_child(_ring)
		_light = OmniLight3D.new()
		_light.light_color = col
		_light.light_energy = 2.0
		_light.omni_range = radius * 2.0
		_light.position.y = 1.2
		add_child(_light)

	func _process(delta: float) -> void:
		_t += delta
		if target != null and is_instance_valid(target):
			global_position = target.global_position
		_ring.rotation.y += delta * 2.0
		_ring.scale = Vector3(1.0 + sin(_t * 10.0) * 0.04, 0.1, 1.0 + sin(_t * 10.0) * 0.04)
		_next -= delta
		if _next <= 0.0 and dmg > 0.0:
			_next = tick
			for e in get_tree().get_nodes_in_group("enemies"):
				if not is_instance_valid(e) or e.dead:
					continue
				var d: Vector3 = e.global_position - global_position
				d.y = 0.0
				if d.length() <= radius + float(e.radius):
					e.take_hit(dmg, d.normalized() if d.length() > 0.05 else Vector3.FORWARD, 1.0, false)
		if _t > duration:
			queue_free()


# ---------------------------------------------------------------- dönen meteorlar (Yörünge)

class Orbit extends Node3D:
	var target = null
	var radius := 2.2
	var dmg := 6.0
	var duration := 5.0
	var count := 2
	var col := Color(1.0, 0.55, 0.35)
	var _t := 0.0
	var _rocks: Array = []
	var _last_hit := {}

	func _ready() -> void:
		var gm = load("res://scripts/star_skills.gd").glow_mat(col, 6.0)
		for i in count:
			var r := MeshInstance3D.new()
			var sm := SphereMesh.new()
			sm.radius = 0.28
			sm.height = 0.56
			r.mesh = sm
			r.material_override = gm
			add_child(r)
			_rocks.append(r)

	func _process(delta: float) -> void:
		_t += delta
		if target != null and is_instance_valid(target):
			global_position = target.global_position
		for i in _rocks.size():
			var a := _t * 4.5 + TAU * float(i) / float(_rocks.size())
			var r: Node3D = _rocks[i]
			r.position = Vector3(cos(a) * radius, 1.0, sin(a) * radius)
			for e in get_tree().get_nodes_in_group("enemies"):
				if not is_instance_valid(e) or e.dead:
					continue
				var d: Vector3 = e.global_position - r.global_position
				d.y = 0.0
				if d.length() < 0.5 + float(e.radius):
					var key: int = e.get_instance_id()
					if _t - float(_last_hit.get(key, -9.0)) > 0.4:
						_last_hit[key] = _t
						e.take_hit(dmg, d.normalized() if d.length() > 0.05 else Vector3.FORWARD, 4.0, false)
						Sfx.play("hit", -9.0, 0.1, 40)
		if _t > duration:
			queue_free()


# ---------------------------------------------------------------- bumerang hilal (Ay Orağı: Hilal Biçişi)

class Boomerang extends Node3D:
	var dir := Vector3.FORWARD
	var owner_node = null
	var dmg := 14.0
	var range_m := 9.0
	var speed := 17.0
	var col := Color(0.75, 0.82, 1.0)
	var _back := false
	var _dist := 0.0
	var _hit_out: Array = []
	var _hit_back: Array = []
	var _mesh: MeshInstance3D
	var _t := 0.0

	func _ready() -> void:
		_mesh = load("res://scripts/slash_fx.gd").make(-1.3, 1.3, 0.35, 1.2, col, 99.0)
		add_child(_mesh)
		Sfx.play("dash", -6.0, 0.05, 0, 1.3)

	func _process(delta: float) -> void:
		_t += delta
		_mesh.rotation.y += delta * 22.0
		var target := global_position + dir * 10.0
		if _back:
			if owner_node == null or not is_instance_valid(owner_node):
				queue_free()
				return
			target = owner_node.global_position + Vector3(0, 1.0, 0)
		var to := target - global_position
		if _back and to.length() < 0.9:
			queue_free()
			return
		global_position += to.normalized() * speed * delta
		if not _back:
			_dist += speed * delta
			if _dist >= range_m:
				_back = true
		var list: Array = _hit_back if _back else _hit_out
		for e in get_tree().get_nodes_in_group("enemies"):
			if not is_instance_valid(e) or e.dead or list.has(e):
				continue
			var d: Vector3 = e.global_position - global_position
			d.y = 0.0
			if d.length() < 1.2 + float(e.radius):
				list.append(e)
				e.take_hit(dmg, d.normalized() if d.length() > 0.05 else dir, 4.0, false)
				Sfx.play("hit", -7.0, 0.1, 30)
		if _t > 4.0:
			queue_free()


# ---------------------------------------------------------------- girdap (Ay Orağı: Ay Gelgiti)

class Vortex extends Node3D:
	var radius := 4.0
	var dmg := 4.0
	var tick := 0.3
	var duration := 2.5
	var col := Color(0.6, 0.65, 1.0)
	var _t := 0.0
	var _next := 0.0
	var _arms: Node3D

	func _ready() -> void:
		var lib = load("res://scripts/star_skills.gd")
		var ring: MeshInstance3D = lib.ring(radius, Color(col.r, col.g, col.b, 0.8))
		ring.position.y = 0.06
		add_child(ring)
		_arms = Node3D.new()
		_arms.position.y = 0.3
		add_child(_arms)
		for i in 3:
			var arc = load("res://scripts/slash_fx.gd").make(0.0, 2.2, 0.3, radius, col, 99.0)
			arc.rotation.y = TAU * float(i) / 3.0
			_arms.add_child(arc)
		Sfx.play("dash", -6.0, 0.0, 0, 0.5)

	func _process(delta: float) -> void:
		_t += delta
		_arms.rotation.y -= delta * 6.0
		_next -= delta
		var do_tick := _next <= 0.0
		if do_tick:
			_next = tick
		for e in get_tree().get_nodes_in_group("enemies"):
			if not is_instance_valid(e) or e.dead:
				continue
			var d: Vector3 = e.global_position - global_position
			d.y = 0.0
			if d.length() <= radius + float(e.radius):
				e.pull_to(global_position, 9.0)
				if do_tick:
					e.take_hit(dmg, -d.normalized() if d.length() > 0.05 else Vector3.FORWARD, 0.0, false)
		if _t > duration:
			queue_free()


# ---------------------------------------------------------------- alev konisi (Güneş Gürzü: Güneş Patlaması)

class FlameCone extends Node3D:
	var dir := Vector3.FORWARD
	var dmg := 18.0
	var reach := 5.5
	var half_angle := 0.62
	var col := Color(1.0, 0.6, 0.2)

	func _ready() -> void:
		var fx = load("res://scripts/slash_fx.gd").make(-half_angle, half_angle, 0.3, reach, col, 0.4)
		add_child(fx)
		look_at(global_position + dir, Vector3.UP)
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.albedo_color = Color(1.0, 0.55, 0.15)
		m.emission_enabled = true
		m.emission = Color(1.0, 0.5, 0.1)
		m.emission_energy_multiplier = 5.0
		var s := SphereMesh.new()
		s.radius = 0.12
		s.height = 0.24
		Fx._burst(global_position, dir, 40, m, s, 6.0, 12.0, 30.0, 1.0, 0.45, 0.6, 1.6)
		Fx.flash_light(global_position + dir * 2.0, Color(1.0, 0.55, 0.2), 6.0, 7.0, 0.3)
		Sfx.play("boom", -10.0, 0.1, 0, 2.2)
		var hit := 0
		for e in get_tree().get_nodes_in_group("enemies"):
			if not is_instance_valid(e) or e.dead:
				continue
			var d: Vector3 = e.global_position - global_position
			d.y = 0.0
			var l := d.length()
			if l <= reach + float(e.radius) and (l < 0.5 or dir.angle_to(d / l) <= half_angle):
				e.take_hit(dmg, d.normalized() if l > 0.05 else dir, 6.0, false)
				if not e.dead and e.has_method("apply_burn"):
					e.apply_burn(6.0, 3.0)
				hit += 1
		if hit > 0:
			Fx.hitstop(0.05)
		var end := create_tween()
		end.tween_interval(0.6)
		end.tween_callback(queue_free)


# ---------------------------------------------------------------- yürüyen meteor hattı (Kuyruklu Yıldız Mızrağı: Kuyruk Süpürmesi)

class LineStrike extends Node3D:
	var dir := Vector3.FORWARD
	var dmg := 14.0
	var count := 6
	var spacing := 1.5
	var step_time := 0.08
	var radius := 1.4
	var bounds := 10.5
	var col := Color(0.6, 0.85, 1.0)
	var _t := 0.0
	var _i := 0
	var _hit: Array = []

	func _process(delta: float) -> void:
		_t += delta
		while _i < count and _t >= float(_i) * step_time:
			var p := global_position + dir * spacing * float(_i + 1)
			var fl := Vector2(p.x, p.z)
			if fl.length() <= bounds:
				_blast(p)
			_i += 1
		if _i >= count and _t > float(count) * step_time + 0.5:
			queue_free()

	func _blast(p: Vector3) -> void:
		var ex = load("res://scripts/slash_fx.gd").make(0.0, TAU, 0.1, radius, col, 0.3)
		get_parent().add_child(ex)
		ex.global_transform = Transform3D(Basis.IDENTITY, p + Vector3(0, 0.3, 0))
		Fx.flash_light(p + Vector3(0, 1, 0), col, 3.0, 3.5, 0.15)
		Sfx.play("boom", -18.0, 0.15, 20, 2.4)
		for e in get_tree().get_nodes_in_group("enemies"):
			if not is_instance_valid(e) or e.dead or _hit.has(e):
				continue
			var d: Vector3 = e.global_position - p
			d.y = 0.0
			if d.length() <= radius + float(e.radius):
				_hit.append(e)
				e.take_hit(dmg, dir, 6.0, false)


# ---------------------------------------------------------------- zincir kancası (Meteor Zinciri)

class Hook extends Node3D:
	var dir := Vector3.FORWARD
	var owner_node = null
	var dmg := 16.0
	var range_m := 9.0
	var speed := 30.0
	var col := Color(1.0, 0.55, 0.35)
	var _dist := 0.0
	var _back := false
	var _caught = null
	var _head: MeshInstance3D
	var _chain: MeshInstance3D

	func _ready() -> void:
		var lib = load("res://scripts/star_skills.gd")
		_head = MeshInstance3D.new()
		var s := SphereMesh.new()
		s.radius = 0.22
		s.height = 0.44
		_head.mesh = s
		_head.material_override = lib.glow_mat(col, 5.0)
		add_child(_head)
		_chain = MeshInstance3D.new()
		var b := BoxMesh.new()
		b.size = Vector3(0.06, 0.06, 1.0)
		_chain.mesh = b
		_chain.material_override = lib.glow_mat(Color(0.95, 0.8, 0.45), 2.0)
		add_child(_chain)
		_chain.top_level = true
		Sfx.play("dash", -6.0, 0.0, 0, 1.8)

	func _process(delta: float) -> void:
		if owner_node == null or not is_instance_valid(owner_node):
			queue_free()
			return
		var origin: Vector3 = owner_node.global_position + Vector3(0, 1.0, 0)
		if not _back:
			global_position += dir * speed * delta
			_dist += speed * delta
			for e in get_tree().get_nodes_in_group("enemies"):
				if not is_instance_valid(e) or e.dead:
					continue
				var d: Vector3 = e.global_position - global_position
				d.y = 0.0
				if d.length() < 0.6 + float(e.radius):
					_caught = e
					e.take_hit(dmg, -dir, 0.0, true)
					if not e.dead:
						e.stun(1.2)
						e.pull_to(origin, 40.0)
					Sfx.play("heavyhit", -6.0, 0.05, 0)
					Fx.shake(0.3)
					_back = true
					break
			if _dist >= range_m:
				_back = true
		else:
			var to := origin - global_position
			if to.length() < 0.8:
				queue_free()
				return
			global_position += to.normalized() * speed * 1.2 * delta
			if _caught != null and is_instance_valid(_caught) and not _caught.dead:
				_caught.pull_to(origin, 30.0)
		# zincir: sahipten başa
		var a := origin
		var bpos := global_position
		var l := a.distance_to(bpos)
		if l > 0.05:
			_chain.global_position = (a + bpos) * 0.5
			_chain.look_at(bpos, Vector3.UP)
			_chain.scale = Vector3(1, 1, l)


# ---------------------------------------------------------------- ok (Kentaur Yayı)

class Arrow extends Node3D:
	var dir := Vector3.FORWARD
	var dmg := 8.0
	var speed := 34.0
	var range_m := 15.0
	var pierce := 0
	var kb := 2.0
	var heavy := false
	var crit := false
	var col := Color(0.78, 0.65, 1.0)
	var owner_node = null
	var explode_r := 0.0      # Avcı Yıldızı: uçuşun sonunda patlar
	var big := false
	var bounces := 0          # Seken Yıldız: isabetten sonra başka düşmana seker
	var _dist := 0.0
	var _hit: Array = []

	func _ready() -> void:
		var lib = load("res://scripts/star_skills.gd")
		var shaft := MeshInstance3D.new()
		var b := BoxMesh.new()
		b.size = Vector3(0.05, 0.05, 0.8 if not heavy else 1.2) * (2.2 if big else 1.0)
		shaft.mesh = b
		shaft.material_override = lib.glow_mat(col.lerp(Color.WHITE, 0.3), 4.0 if not heavy else 7.0)
		add_child(shaft)
		var tip := MeshInstance3D.new()
		var s := SphereMesh.new()
		s.radius = (0.08 if not heavy else 0.14) * (2.6 if big else 1.0)
		s.height = s.radius * 2.0
		tip.mesh = s
		tip.material_override = lib.glow_mat(Color(1.0, 0.95, 0.8), 6.0)
		tip.position = Vector3(0, 0, -0.42 if not heavy else -0.62)
		add_child(tip)
		var l := OmniLight3D.new()
		l.light_color = col
		l.light_energy = 0.8 if not heavy else 2.0
		l.omni_range = 2.0
		add_child(l)
		look_at(global_position + dir, Vector3.UP)

	func _physics_process(delta: float) -> void:
		var step := speed * delta
		global_position += dir * step
		_dist += step
		for e in get_tree().get_nodes_in_group("enemies"):
			if not is_instance_valid(e) or e.dead or _hit.has(e):
				continue
			var d: Vector3 = e.global_position - global_position
			d.y = 0.0
			if d.length() < 0.55 + float(e.radius):
				_hit.append(e)
				e.take_hit(dmg, dir, kb, heavy, crit)
				if owner_node != null and is_instance_valid(owner_node) and owner_node.has_method("on_ranged_hit"):
					owner_node.on_ranged_hit(dmg, e)
				Sfx.play("stab", -4.0, 0.12, 25, 1.1)
				Sfx.play("hit", -10.0, 0.12, 25, 1.15)
				if bounces > 0:
					# en yakın başka düşmana yönel
					var best = null
					var bd := 7.0
					for o in get_tree().get_nodes_in_group("enemies"):
						if not is_instance_valid(o) or o.dead or _hit.has(o):
							continue
						var dd: float = o.global_position.distance_to(global_position)
						if dd < bd:
							bd = dd
							best = o
					if best != null:
						bounces -= 1
						var nd: Vector3 = best.global_position - global_position
						nd.y = 0.0
						dir = nd.normalized()
						look_at(global_position + dir, Vector3.UP)
						_dist = maxf(range_m - 8.0, 0.0)
						return
				if pierce <= 0:
					_explode()
					queue_free()
					return
				pierce -= 1
		if _dist > range_m:
			_explode()
			queue_free()

	func _explode() -> void:
		if explode_r <= 0.0:
			return
		explode_r = -explode_r
		var r := -explode_r
		var lib = load("res://scripts/slash_fx.gd")
		var ex = lib.make(0.0, TAU, 0.3, r, col.lerp(Color.WHITE, 0.4), 0.35)
		get_parent().add_child(ex)
		ex.global_transform = Transform3D(Basis.IDENTITY, Vector3(global_position.x, 0.4, global_position.z))
		Fx.flash_light(global_position, col, 7.0, 7.0, 0.3)
		Fx.shake(0.3)
		Sfx.play("boom", -8.0, 0.1, 0, 1.6)
		for e in get_tree().get_nodes_in_group("enemies"):
			if not is_instance_valid(e) or e.dead:
				continue
			var d: Vector3 = e.global_position - global_position
			d.y = 0.0
			if d.length() <= r + float(e.radius):
				e.take_hit(dmg * 0.6, d.normalized() if d.length() > 0.05 else dir, 4.0, true, crit)
				if owner_node != null and is_instance_valid(owner_node) and owner_node.has_method("on_ranged_hit"):
					owner_node.on_ranged_hit(dmg * 0.6, e)
