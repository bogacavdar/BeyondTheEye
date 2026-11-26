extends RefCounted
## ORTAK TEHLİKELER: son yedi bölgenin yaratıkları ve boss'ları bu yapı taşlarını kullanır.
##  Blast  -> bir noktada büyüyen halka uyarısı, sonra patlama
##  Line   -> bir hat boyunca uyarı şeridi, sonra çarpma
##  Pool   -> yerde kalan alan (zehir / yavaşlatma / yanık)
##  Shot   -> düz giden (isteğe göre seni kovalayan) mermi
##  Spokes -> bir merkezin etrafında dönen kollar
## Etkiler (eff): "" düz hasar, "slow" yavaşlatır, "poison" zehirler, "freeze" kısa süre dondurur, "knock" savurur

const PARRY_COL := Color(1.0, 0.72, 0.2)
const DANGER_COL := Color(1.0, 0.1, 0.18)


static func add_mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.albedo_color = c
	return m


static func hero_ok(hero) -> bool:
	return hero != null and is_instance_valid(hero) and not hero.dead


## Kahramana hasar + etki uygular; sonucu döndürür
## Tehlikenin vurabileceği kahramanlar: tek oyunculu oyunda yalnızca hedef, co-op'ta ayakta olan herkes
static func targets(hero) -> Array:
	var out: Array = []
	if hero != null and is_instance_valid(hero) and hero.is_inside_tree():
		for h in hero.get_tree().get_nodes_in_group("heroes"):
			if hero_ok(h):
				out.append(h)
	if out.is_empty() and hero_ok(hero):
		out.append(hero)
	return out


static func hurt(hero, dmg: float, dir: Vector3, eff := "", parry := false) -> String:
	if not hero_ok(hero):
		return "miss"
	var d := dir
	d.y = 0.0
	if d.length() < 0.05:
		d = Vector3.FORWARD
	var res: String = hero.take_damage(dmg, d.normalized(), parry)
	if res == "hit":
		match eff:
			"slow":
				hero.apply_slow(0.5, 1.6)
			"poison":
				hero.apply_poison(dmg * 0.3, 3.0)
			"freeze":
				hero.apply_slow(0.05, 0.9)
			"knock":
				hero.velocity = d.normalized() * 16.0
	return res


static func flat_dist(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


static func clamp_arena(p: Vector3, r: float) -> Vector3:
	var fl := Vector2(p.x, p.z)
	if fl.length() > r:
		fl = fl.normalized() * r
	return Vector3(fl.x, 0.0, fl.y)


# ---------------------------------------------------------------- noktasal patlama

class Blast extends Node3D:
	var hero = null
	var radius := 2.0
	var delay := 1.0
	var dmg := 18.0
	var col := Color(1.0, 0.2, 0.2)
	var eff := ""
	var pool_life := 0.0      # >0 ise patladıktan sonra yerde alan bırakır
	var _t := 0.0
	var _ring: MeshInstance3D
	var _disc: MeshInstance3D
	var _dm: StandardMaterial3D

	func _ready() -> void:
		top_level = true
		_ring = load("res://scripts/star_skills.gd").ring(radius, Color(col.r, col.g, col.b, 0.9))
		add_child(_ring)
		_ring.position.y = 0.07
		_disc = MeshInstance3D.new()
		var c := CylinderMesh.new()
		c.top_radius = radius
		c.bottom_radius = radius
		c.height = 0.02
		c.radial_segments = 32
		_disc.mesh = c
		_dm = load("res://scripts/hazards.gd").add_mat(Color(col.r, col.g, col.b, 0.0))
		_disc.material_override = _dm
		_disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_disc.position.y = 0.06
		_disc.scale = Vector3(0.05, 1, 0.05)
		add_child(_disc)

	func _physics_process(delta: float) -> void:
		_t += delta
		var k := clampf(_t / delay, 0.0, 1.0)
		_disc.scale = Vector3(k, 1, k)
		_dm.albedo_color.a = 0.12 + 0.3 * k
		if _t >= delay:
			var H = load("res://scripts/hazards.gd")
			var ex = load("res://scripts/slash_fx.gd").make(0.0, TAU, radius * 0.2, radius, col, 0.3)
			get_parent().add_child(ex)
			ex.global_transform = Transform3D(Basis.IDENTITY, global_position + Vector3(0, 0.3, 0))
			Fx.flash_light(global_position + Vector3(0, 1, 0), col, 4.0, radius * 2.5, 0.25)
			Sfx.play("boom", -14.0, 0.2, 40, 1.5)
			for hh in H.targets(hero):
				if H.flat_dist(hh.global_position, global_position) <= radius + 0.25:
					H.hurt(hh, dmg, hh.global_position - global_position, eff)
			if pool_life > 0.0:
				var p = H.Pool.new()
				p.hero = hero
				p.radius = radius * 0.9
				p.life = pool_life
				p.dps = dmg * 0.25
				p.col = col
				p.eff = eff
				get_parent().add_child(p)
				p.global_position = global_position
			queue_free()


# ---------------------------------------------------------------- hat boyunca çarpma

class Line extends Node3D:
	var hero = null
	var dir := Vector3.FORWARD
	var length := 12.0
	var width := 1.2
	var delay := 0.8
	var dmg := 18.0
	var col := Color(1.0, 0.2, 0.2)
	var eff := ""
	var _t := 0.0
	var _fired := false
	var _m: StandardMaterial3D
	var _bar: MeshInstance3D

	func _ready() -> void:
		top_level = true
		look_at(global_position + dir, Vector3.UP)
		_bar = MeshInstance3D.new()
		var b := BoxMesh.new()
		b.size = Vector3(width, 0.04, length)
		_bar.mesh = b
		_m = load("res://scripts/hazards.gd").add_mat(Color(col.r, col.g, col.b, 0.15))
		_bar.material_override = _m
		_bar.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_bar.position = Vector3(0, 0.07, -length * 0.5)
		add_child(_bar)

	func _physics_process(delta: float) -> void:
		_t += delta
		if not _fired:
			_m.albedo_color.a = 0.12 + 0.35 * clampf(_t / delay, 0.0, 1.0) + 0.1 * sin(_t * 30.0)
			if _t >= delay:
				_fired = true
				var H = load("res://scripts/hazards.gd")
				(_bar.mesh as BoxMesh).size = Vector3(width, 1.8, length)
				_bar.position.y = 0.9
				_m.albedo_color.a = 0.9
				Sfx.play("boom", -12.0, 0.1, 30, 1.9)
				for hh in H.targets(hero):
					var v: Vector3 = hh.global_position - global_position
					v.y = 0.0
					var along := v.dot(dir)
					var side := Vector3(-dir.z, 0, dir.x)
					var sd := v.dot(side)
					if along > -0.4 and along < length + 0.3 and absf(sd) < width * 0.5 + 0.35:
						H.hurt(hh, dmg, side * signf(sd + 0.01), eff)
		else:
			_m.albedo_color.a = maxf(_m.albedo_color.a - delta * 3.0, 0.0)
			scale.x = maxf(1.0 - (_t - delay) * 3.0, 0.05)
			if _t > delay + 0.3:
				queue_free()


# ---------------------------------------------------------------- yerde kalan alan

class Pool extends Node3D:
	var hero = null
	var radius := 1.8
	var life := 5.0
	var dps := 6.0
	var col := Color(0.4, 1.0, 0.3)
	var eff := ""
	var _t := 0.0
	var _tick := 0.0
	var _m: StandardMaterial3D

	func _ready() -> void:
		top_level = true
		var d := MeshInstance3D.new()
		var c := CylinderMesh.new()
		c.top_radius = radius
		c.bottom_radius = radius
		c.height = 0.02
		c.radial_segments = 28
		d.mesh = c
		_m = load("res://scripts/hazards.gd").add_mat(Color(col.r, col.g, col.b, 0.35))
		d.material_override = _m
		d.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		d.position.y = 0.05
		add_child(d)

	func _physics_process(delta: float) -> void:
		_t += delta
		_m.albedo_color.a = (0.3 + 0.08 * sin(_t * 5.0)) * (1.0 - clampf((_t - life + 0.5) / 0.5, 0.0, 1.0))
		_tick -= delta
		var H = load("res://scripts/hazards.gd")
		if _tick <= 0.0:
			_tick = 0.5
			for hh in H.targets(hero):
				if H.flat_dist(hh.global_position, global_position) > radius:
					continue
				match eff:
					"poison":
						hh.apply_poison(dps, 1.0)
					"slow", "freeze":
						hh.apply_slow(0.5 if eff == "slow" else 0.25, 0.6)
						if dps > 0.0:
							hh.apply_poison(dps * 0.5, 0.5)
					_:
						hh.apply_poison(dps, 0.6)
		if _t >= life:
			queue_free()


# ---------------------------------------------------------------- mermi

class Shot extends Node3D:
	var hero = null
	var vel := Vector3.FORWARD * 8.0
	var homing := 0.0
	var dmg := 12.0
	var radius := 0.6
	var life := 4.0
	var col := Color(0.6, 0.9, 1.0)
	var eff := ""
	var size := 0.3
	var _t := 0.0

	func _ready() -> void:
		add_to_group("enemy_shot")
		top_level = true
		var m := MeshInstance3D.new()
		var s := SphereMesh.new()
		s.radius = size
		s.height = size * 2.0
		m.mesh = s
		m.material_override = Fx.emissive(col, 4.0)
		add_child(m)

	func _physics_process(delta: float) -> void:
		_t += delta
		var H = load("res://scripts/hazards.gd")
		if homing > 0.0 and H.hero_ok(hero):
			var to: Vector3 = hero.global_position + Vector3(0, 1.0, 0) - global_position
			vel = vel.lerp(to.normalized() * vel.length(), minf(homing * delta, 1.0))
		global_position += vel * delta
		for hh in H.targets(hero):
			var d: Vector3 = hh.global_position + Vector3(0, 1.0, 0) - global_position
			if d.length() < radius + 0.3:
				H.hurt(hh, dmg, vel, eff)
				queue_free()
				return
		if _t > life or global_position.length() > 40.0:
			queue_free()


# ---------------------------------------------------------------- dönen kollar

class Spokes extends Node3D:
	var hero = null
	var follow: Node3D = null
	var arms := 4
	var length := 10.0
	var width := 0.9
	var spin := 1.4
	var warn := 0.9
	var life := 4.5
	var dmg := 16.0
	var col := Color(1.0, 0.4, 0.15)
	var eff := ""
	var _t := 0.0
	var _hit_cd := 0.0
	var _m: StandardMaterial3D

	func _ready() -> void:
		top_level = true
		_m = load("res://scripts/hazards.gd").add_mat(Color(col.r, col.g, col.b, 0.2))
		for i in arms:
			var pv := Node3D.new()
			pv.rotation.y = TAU * float(i) / float(arms)
			add_child(pv)
			var m := MeshInstance3D.new()
			var b := BoxMesh.new()
			b.size = Vector3(width, 1.0, length)
			m.mesh = b
			m.material_override = _m
			m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			m.position = Vector3(0, 0.5, -length * 0.5 - 1.0)
			pv.add_child(m)

	func _physics_process(delta: float) -> void:
		_t += delta
		if follow != null:
			if not is_instance_valid(follow) or bool(follow.get("dead")):
				queue_free()
				return
			global_position = Vector3(follow.global_position.x, 0.0, follow.global_position.z)
		var live := _t >= warn
		rotation.y += spin * delta * (1.0 if live else 0.15)
		_m.albedo_color.a = (0.85 if live else 0.15 + 0.12 * sin(_t * 25.0)) * (1.0 - clampf((_t - life + 0.3) / 0.3, 0.0, 1.0))
		_hit_cd -= delta
		var H = load("res://scripts/hazards.gd")
		if live and _hit_cd <= 0.0:
			for hh in H.targets(hero):
				var v: Vector3 = hh.global_position - global_position
				v.y = 0.0
				var r := v.length()
				if r > 0.9 and r < length + 1.3:
					for i in arms:
						var a := rotation.y + TAU * float(i) / float(arms)
						var ad := Vector3(-sin(a), 0, -cos(a))
						var side := Vector3(-ad.z, 0, ad.x)
						if v.dot(ad) > 0.0 and absf(v.dot(side)) < width * 0.5 + 0.3:
							_hit_cd = 0.6
							H.hurt(hh, dmg, side * signf(spin), eff)
							break
		if _t >= life:
			queue_free()


# ---------------------------------------------------------------- rüzgâr hamlesi (İkiz Gökler)

class Gust extends Node3D:
	var hero = null
	var dir := Vector3.RIGHT
	var warn := 1.2
	var dur := 2.6
	var strength := 3.4
	var bounds := 12.0
	var _t := 0.0
	var _em: CPUParticles3D

	func _ready() -> void:
		top_level = true
		global_position = Vector3.ZERO
		_em = CPUParticles3D.new()
		_em.amount = 60
		_em.lifetime = 1.2
		_em.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
		var side := Vector3(-dir.z, 0, dir.x)
		_em.emission_box_extents = Vector3(bounds, 1.2, bounds)
		_em.position = Vector3(0, 1.2, 0) - dir * 2.0
		_em.direction = dir
		_em.spread = 3.0
		_em.gravity = Vector3.ZERO
		_em.initial_velocity_min = 4.0
		_em.initial_velocity_max = 6.0
		var q := QuadMesh.new()
		q.size = Vector2(1.2, 0.05)
		var m = load("res://scripts/hazards.gd").add_mat(Color(0.9, 0.95, 1.0, 0.35))
		m.billboard_mode = BaseMaterial3D.BILLBOARD_DISABLED
		q.material = m
		_em.mesh = q
		_em.local_coords = false
		add_child(_em)
		look_at(global_position + side, Vector3.UP)
		Sfx.play("dash", -8.0, 0.0, 0, 0.4)

	func _physics_process(delta: float) -> void:
		_t += delta
		var H = load("res://scripts/hazards.gd")
		if _t < warn:
			_em.initial_velocity_min = 2.0
			_em.initial_velocity_max = 3.0
		elif _t < warn + dur:
			_em.initial_velocity_min = 12.0
			_em.initial_velocity_max = 16.0
			for hh in H.targets(hero):
				if hh.has_method("apply_pull"):
					hh.apply_pull(hh.global_position + dir * 5.0, strength, 0.05)
		else:
			_em.emitting = false
			if _t > warn + dur + 1.3:
				queue_free()
