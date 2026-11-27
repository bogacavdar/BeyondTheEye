extends Node3D
## GÖK YOLDAŞI: run'a yanında götürdüğün küçük göksel hayvan. Kullandıkça (run sayısı) seviye atlar: 3 / 8 run.
##  fox    YILDIZ TİLKİSİ: arada bir en yakın düşmana atılıp ısırır
##  owl    AY BAYKUŞU: kaçman gereken (kızıl) bir saldırı hazırlanırken öter; seviyeyle kaçınma verir
##  fish   KUYRUKLU YILDIZ BALIĞI: etrafında döner, değdiği düşman mermilerini yok eder
##  beetle GÜNEŞ BÖCEĞİ: canın %35'in altına inince her odada bir kez seni iyileştirir

const LIST := [
	{"id": "fox", "name": "STAR FOX", "col": Color(0.75, 0.85, 1.0), "unlock": "",
		"desc": "Now and then leaps at the nearest foe and bites"},
	{"id": "owl", "name": "MOON OWL", "col": Color(0.85, 0.85, 1.0), "unlock": "aries",
		"desc": "Hoots when a red attack is being prepared nearby; grants dodge as it grows"},
	{"id": "fish", "name": "COMET FISH", "col": Color(0.4, 0.95, 1.0), "unlock": "cancer",
		"desc": "Circles you and destroys enemy projectiles it touches"},
	{"id": "beetle", "name": "SUN BEETLE", "col": Color(1.0, 0.85, 0.4), "unlock": "leo",
		"desc": "Once per chamber, heals you when your health drops below 35%"},
]

var kind := "fox"
var level := 1
var hero = null
var _t := 0.0
var _cd := 2.0
var _dash := 0.0
var _target = null
var _vis: Node3D
var _mat: StandardMaterial3D
var _hooted := {}
var _healed := false
var _orbit := 0.0


static func get_info(id: String) -> Dictionary:
	for c in LIST:
		if c["id"] == id:
			return c
	return {}


static func unlocked(id: String) -> bool:
	var GD = load("res://scripts/game_data.gd")
	match String(get_info(id).get("unlock", "x")):
		"":
			return true
		"aries":
			return GD.aries_defeated
		"cancer":
			return GD.cancer_defeated
		"leo":
			return GD.leo_defeated
	return false


static func lvl(runs: int) -> int:
	return 1 + (1 if runs >= 3 else 0) + (1 if runs >= 8 else 0)


func _ready() -> void:
	top_level = true
	var info := get_info(kind)
	var col: Color = info.get("col", Color.WHITE)
	_mat = StandardMaterial3D.new()
	_mat.albedo_color = col
	_mat.emission_enabled = true
	_mat.emission = col
	_mat.emission_energy_multiplier = 1.8
	_vis = Node3D.new()
	add_child(_vis)
	match kind:
		"fox":
			_part(SphereMesh.new(), Vector3(0, 0, 0), Vector3(0.22, 0.2, 0.4))
			_part(SphereMesh.new(), Vector3(0, 0.12, -0.25), Vector3(0.18, 0.17, 0.2))
			for s in [-1.0, 1.0]:
				var e := _part(CylinderMesh.new(), Vector3(s * 0.07, 0.27, -0.25), Vector3(0.05, 0.12, 0.05))
				(e.mesh as CylinderMesh).top_radius = 0.0
			var tail := _part(SphereMesh.new(), Vector3(0, 0.08, 0.32), Vector3(0.14, 0.14, 0.35))
			tail.rotation.x = -0.5
		"owl":
			_part(SphereMesh.new(), Vector3(0, 0, 0), Vector3(0.24, 0.3, 0.22))
			_part(SphereMesh.new(), Vector3(0, 0.25, 0), Vector3(0.2, 0.18, 0.18))
			for s in [-1.0, 1.0]:
				var w := _part(SphereMesh.new(), Vector3(s * 0.2, 0.02, 0.02), Vector3(0.18, 0.24, 0.05))
				w.rotation.z = s * 0.4
		"fish":
			_part(SphereMesh.new(), Vector3(0, 0, 0), Vector3(0.16, 0.16, 0.3))
			var fin := _part(CylinderMesh.new(), Vector3(0, 0, 0.26), Vector3(0.14, 0.14, 0.02))
			(fin.mesh as CylinderMesh).top_radius = 0.0
			fin.rotation.x = PI * 0.5
			var tr_ := CPUParticles3D.new()
			tr_.amount = 20
			tr_.lifetime = 0.5
			tr_.local_coords = false
			var sm := SphereMesh.new()
			sm.radius = 0.04
			sm.height = 0.08
			tr_.mesh = sm
			tr_.material_override = Fx.emissive(col, 3.0)
			tr_.gravity = Vector3.ZERO
			tr_.initial_velocity_min = 0.0
			tr_.initial_velocity_max = 0.2
			_vis.add_child(tr_)
		"beetle":
			_part(SphereMesh.new(), Vector3(0, 0, 0), Vector3(0.2, 0.14, 0.26))
			for s in [-1.0, 1.0]:
				var w2 := _part(SphereMesh.new(), Vector3(s * 0.14, 0.08, 0.0), Vector3(0.16, 0.03, 0.24))
				w2.rotation.z = s * 0.5
	var l := OmniLight3D.new()
	l.light_color = col
	l.light_energy = 0.8
	l.omni_range = 2.5
	add_child(l)
	if hero != null:
		global_position = hero.global_position + Vector3(0.8, 1.6, 0.6)


func _part(m: Mesh, p: Vector3, sc: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	if m is SphereMesh:
		(m as SphereMesh).radius = 1.0
		(m as SphereMesh).height = 2.0
	elif m is CylinderMesh:
		(m as CylinderMesh).height = 2.0
		(m as CylinderMesh).bottom_radius = 1.0
	mi.mesh = m
	mi.material_override = _mat
	mi.position = p
	mi.scale = sc
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_vis.add_child(mi)
	return mi


func _hero_ok() -> bool:
	return hero != null and is_instance_valid(hero) and not hero.dead


func _physics_process(delta: float) -> void:
	_t += delta
	if not _hero_ok():
		return
	var home: Vector3 = hero.global_position + Vector3(0.0, 1.7 + sin(_t * 2.5) * 0.12, 0.0) + hero.aim.rotated(Vector3.UP, 2.2) * 0.9
	match kind:
		"fox":
			_tick_fox(delta, home)
			return
		"fish":
			_orbit += delta * (2.4 + 0.4 * float(level))
			home = hero.global_position + Vector3(cos(_orbit) * 1.6, 1.0, sin(_orbit) * 1.6)
			_tick_fish(delta)
		"owl":
			_tick_owl(delta)
		"beetle":
			_tick_beetle()
	global_position = global_position.lerp(home, minf(8.0 * delta, 1.0)) if kind != "fish" else home
	var mv := home - global_position
	if kind != "fish":
		_vis.rotation.y = lerp_angle(_vis.rotation.y, atan2(-hero.aim.x, -hero.aim.z), minf(6.0 * delta, 1.0))
	else:
		_vis.rotation.y = -_orbit


# ---------------------------------------------------------------- Yıldız Tilkisi

func _tick_fox(delta: float, home: Vector3) -> void:
	_cd -= delta
	if _dash > 0.0 and _target != null and is_instance_valid(_target) and not _target.dead:
		_dash -= delta
		var tp: Vector3 = _target.global_position + Vector3(0, 0.8, 0)
		global_position = global_position.lerp(tp, minf(14.0 * delta, 1.0))
		_vis.look_at(tp + (tp - global_position), Vector3.UP)
		if global_position.distance_to(tp) < 0.7:
			var dmg: float = [12.0, 18.0, 26.0][level - 1]
			var d: Vector3 = _target.global_position - hero.global_position
			d.y = 0.0
			if _target.has_method("mirror_up") and _target.mirror_up():
				_target.mirror_fizzle(global_position)   # T-50: yoldaş vuruşu aynada söner, yansımaz
			else:
				_target.take_hit(dmg, d.normalized() if d.length() > 0.1 else Vector3.FORWARD, 1.0, false)
			Sfx.play("cut", -10.0, 0.1, 0, 1.6)
			_dash = 0.0
			_target = null
		return
	_dash = 0.0
	global_position = global_position.lerp(home, minf(6.0 * delta, 1.0))
	if _cd <= 0.0:
		_cd = [4.0, 3.3, 2.6][level - 1]
		var best = null
		var bd := 8.0
		for e in get_tree().get_nodes_in_group("enemies"):
			if e.dead:
				continue
			var dist: float = e.global_position.distance_to(hero.global_position)
			if dist < bd:
				bd = dist
				best = e
		if best != null:
			_target = best
			_dash = 0.6


# ---------------------------------------------------------------- Ay Baykuşu

func _tick_owl(_delta: float) -> void:
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.dead or String(e.get("state")) != "windup":
			continue
		var danger := false
		var a = e.get("atk")
		if a is Dictionary:
			danger = not bool(a.get("parry", true))
		else:
			var tm = e.get("tele_mat")
			var tv = e.get("tele")
			if tm != null and tv != null and tv.visible:
				var c: Color = tm.albedo_color
				danger = c.r > 0.9 and c.g < 0.3
		if not danger:
			continue
		if e.global_position.distance_to(hero.global_position) > 9.0:
			continue
		var id := e.get_instance_id()
		if _t - float(_hooted.get(id, -9.0)) < 1.2:
			continue
		_hooted[id] = _t
		Sfx.play("parry", -6.0, 0.0, 0, 2.6)
		var ring = load("res://scripts/slash_fx.gd").make(0.0, TAU, 0.1, 0.9, Color(1.0, 0.3, 0.35), 0.35)
		get_parent().add_child(ring)
		ring.global_transform = Transform3D(Basis.IDENTITY, global_position)
		_vis.scale = Vector3.ONE * 1.4
		create_tween().tween_property(_vis, "scale", Vector3.ONE, 0.3)


# ---------------------------------------------------------------- Kuyruklu Yıldız Balığı

func _tick_fish(delta: float) -> void:
	_cd -= delta
	if _cd > 0.0:
		return
	for s in get_tree().get_nodes_in_group("enemy_shot"):
		if not is_instance_valid(s):
			continue
		if (s as Node3D).global_position.distance_to(global_position) < 0.9:
			var fx = load("res://scripts/slash_fx.gd").make(0.0, TAU, 0.1, 0.8, Color(0.5, 1.0, 1.0), 0.25)
			get_parent().add_child(fx)
			fx.global_transform = Transform3D(Basis.IDENTITY, global_position)
			Sfx.play("parry", -10.0, 0.1, 0, 2.0)
			s.queue_free()
			_cd = [1.6, 1.1, 0.6][level - 1]
			return


# ---------------------------------------------------------------- Güneş Böceği

func _tick_beetle() -> void:
	if _healed or hero.hp >= hero.max_hp * 0.35:
		return
	_healed = true
	var pct: float = [0.15, 0.22, 0.3][level - 1]
	hero.heal(hero.max_hp * pct)
	Fx.flash_light(hero.global_position + Vector3(0, 1.5, 0), Color(1.0, 0.85, 0.4), 6.0, 6.0, 0.6)
	Sfx.play("coin", -6.0, 0.0, 0, 1.2)
	var fx = load("res://scripts/slash_fx.gd").make(0.0, TAU, 0.2, 2.2, Color(1.0, 0.85, 0.45), 0.5)
	get_parent().add_child(fx)
	fx.global_transform = Transform3D(Basis.IDENTITY, hero.global_position + Vector3(0, 0.3, 0))
