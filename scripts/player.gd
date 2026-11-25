extends CharacterBody3D
## OYUNCU
## WASD: hareket | Mouse: nişan | Sol tık: ateş | Boşluk: atılma | 1-8 veya tekerlek: silah

signal died
signal hp_changed(hp: float, max_hp: float)
signal weapon_changed(weapon_name: String)

const MODEL = preload("res://assets/models/Characters_Shaun.gltf")
const RocketScript = preload("res://scripts/rocket.gd")
const GameData = preload("res://scripts/game_data.gd")
const WeaponModels = preload("res://scripts/weapon_models.gd")
const MODEL_SCALE := 1.22
const ALL_GUN_MESHES := ["Axe", "Guitar", "Knife", "Pistol", "Rifle", "Shotgun", "SMG", "Spear", "WoodenBat_Barbed", "WoodenBat_Saw"]

const BASE_SPEED := 7.0
const ACCEL := 70.0
const DASH_SPEED := 24.0
const DASH_TIME := 0.16
const BASE_DASH_COOLDOWN := 0.7
const GUN_HEIGHT := 1.2

var camera = null
var max_hp := 100.0
var hp := 100.0
var dead := false
var aim_point := Vector3(0, GUN_HEIGHT, -5)
var dash_timer := 0.0
var dash_cd := 0.0
var dash_dir := Vector3.FORWARD
var invuln := 0.0
var fire_cd := 0.0
var weapon_index := 0
var move_speed := BASE_SPEED
var dash_cooldown := BASE_DASH_COOLDOWN
var dmg_mult := 1.0
var rate_mult := 1.0
var hurt_flash := 0.0
var kick := 0.0

## CEPHANELİK. Vuruş hissini ince ayarlamak için en çok burayla oynayacağız.
## type: hitscan (anlık mermi), flame (alev konisi), rocket (patlayan mermi)
## pierce: merminin kaç yaratığın içinden geçebileceği
var weapons: Array = [
	{"name": "TABANCA", "mesh": "Pistol", "sound": "pistol", "sound_db": -8.0,
		"rate": 5.0, "damage": 24.0, "pellets": 1, "spread": 1.5, "range": 40.0, "pierce": 0,
		"knockback": 2.5, "shake": 0.08, "hitstop": 0.0, "kick": 0.08, "self_push": 0.0,
		"gib_range": 0.0, "flash": 5.0, "color": Color(1.0, 0.9, 0.4)},
	{"name": "REVOLVER", "mesh": "Pistol", "mesh_scale": 1.3, "sound": "revolver", "sound_db": -3.0,
		"rate": 1.8, "damage": 75.0, "pellets": 1, "spread": 0.5, "range": 55.0, "pierce": 3,
		"knockback": 9.0, "shake": 0.3, "hitstop": 0.04, "kick": 0.22, "self_push": 1.5,
		"gib_range": 3.5, "flash": 9.0, "color": Color(1.0, 0.6, 0.2)},
	{"name": "UZİ", "mesh": "SMG", "sound": "uzi", "sound_db": -12.0,
		"rate": 18.0, "damage": 9.0, "pellets": 1, "spread": 8.0, "range": 28.0, "pierce": 0,
		"knockback": 1.2, "shake": 0.035, "hitstop": 0.0, "kick": 0.04, "self_push": 0.0,
		"gib_range": 0.0, "flash": 4.0, "color": Color(0.4, 1.0, 0.6)},
	{"name": "PİYADE TÜFEĞİ", "mesh": "Rifle", "sound": "assault", "sound_db": -9.0,
		"rate": 11.0, "damage": 17.0, "pellets": 1, "spread": 2.5, "range": 45.0, "pierce": 1,
		"knockback": 2.5, "shake": 0.06, "hitstop": 0.0, "kick": 0.06, "self_push": 0.0,
		"gib_range": 0.0, "flash": 5.0, "color": Color(0.2, 0.9, 1.0)},
	{"name": "POMPALI", "mesh": "Shotgun", "sound": "shotgun", "sound_db": -3.0,
		"rate": 1.3, "damage": 12.0, "pellets": 9, "spread": 15.0, "range": 14.0, "pierce": 0,
		"knockback": 8.0, "shake": 0.42, "hitstop": 0.05, "kick": 0.2, "self_push": 4.0,
		"gib_range": 4.5, "flash": 10.0, "color": Color(1.0, 0.35, 0.55)},
	{"name": "KESİK POMPALI", "mesh": "Shotgun", "mesh_scale_x": 0.6, "sound": "sawed", "sound_db": 0.0,
		"rate": 1.5, "damage": 12.0, "pellets": 16, "spread": 26.0, "range": 9.0, "pierce": 0,
		"knockback": 13.0, "shake": 0.65, "hitstop": 0.06, "kick": 0.3, "self_push": 8.0,
		"gib_range": 6.0, "flash": 14.0, "color": Color(1.0, 0.3, 0.2)},
	{"name": "ALEV SİLAHI", "mesh": "flamer", "type": "flame", "sound": "flame", "sound_db": -7.0,
		"rate": 20.0, "damage": 4.0, "burn": 3.0, "range": 8.5, "cone": 24.0,
		"shake": 0.012, "kick": 0.0, "self_push": 0.0, "flash": 5.0, "color": Color(1.0, 0.5, 0.1)},
	{"name": "BAZUKA", "mesh": "bazooka", "type": "rocket", "sound": "rocket", "sound_db": -2.0,
		"rate": 0.9, "damage": 180.0, "radius": 6.0, "knockback": 20.0,
		"shake": 0.35, "kick": 0.35, "self_push": 6.0, "flash": 12.0, "color": Color(1.0, 0.5, 0.2)},
]

var pivot: Node3D
var model: Node3D
var anim: AnimationPlayer
var model_meshes: Array = []
var gun_meshes := {}
var _gun_base_scale := {}
var muzzle: Node3D
var muzzle_light: OmniLight3D
var muzzle_flash: MeshInstance3D
var hurt_mat: StandardMaterial3D
var laser: MeshInstance3D
var laser_dot: MeshInstance3D
var laser_mat: StandardMaterial3D
var flame: CPUParticles3D
var _flaming := false
var _cur_anim := ""


func _ready() -> void:
	# Laboratuvarda açılan silahlar ve alınan kalıcı yükseltmeler
	var mine: Array = []
	for w in weapons:
		if GameData.owned.has(w["name"]):
			mine.append(w)
	if mine.is_empty():
		mine.append(weapons[0])
	weapons = mine
	max_hp = GameData.max_hp()
	hp = max_hp
	move_speed = BASE_SPEED * GameData.speed_mult()
	dash_cooldown = BASE_DASH_COOLDOWN * GameData.dash_mult()
	dmg_mult = GameData.damage_mult()
	rate_mult = GameData.rate_mult()

	collision_layer = 2
	collision_mask = 1 | 4
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING

	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.38
	cap.height = 1.8
	cs.shape = cap
	cs.position.y = 1.0
	add_child(cs)

	pivot = Node3D.new()
	add_child(pivot)

	model = MODEL.instantiate()
	model.rotation.y = PI
	model.scale = Vector3.ONE * MODEL_SCALE
	pivot.add_child(model)
	anim = model.find_children("*", "AnimationPlayer", true, false)[0]
	for a in ["Idle_Gun", "Run_Gun", "Walk_Gun", "Idle", "Run"]:
		if anim.has_animation(a):
			anim.get_animation(a).loop_mode = Animation.LOOP_LINEAR
	model_meshes = model.find_children("*", "MeshInstance3D", true, false)
	for gname in ALL_GUN_MESHES:
		var n = model.find_child(gname, true, false)
		if n != null and n is MeshInstance3D:
			gun_meshes[gname] = n
			_gun_base_scale[gname] = n.scale
			n.visible = false
	_make_custom_guns()

	hurt_mat = StandardMaterial3D.new()
	hurt_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	hurt_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	hurt_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	hurt_mat.albedo_color = Color(1, 0.1, 0.15, 0)

	muzzle = Node3D.new()
	muzzle_light = OmniLight3D.new()
	muzzle_light.light_color = Color(1.0, 0.75, 0.4)
	muzzle_light.omni_range = 7.0
	muzzle_light.light_energy = 0.0
	muzzle.add_child(muzzle_light)
	var flash_mesh := SphereMesh.new()
	flash_mesh.radius = 0.12
	flash_mesh.height = 0.24
	muzzle_flash = MeshInstance3D.new()
	muzzle_flash.mesh = flash_mesh
	muzzle_flash.material_override = Fx.emissive(Color(1.0, 0.8, 0.45), 10.0)
	muzzle_flash.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	muzzle_flash.visible = false
	muzzle_flash.top_level = true
	muzzle.add_child(muzzle_flash)
	pivot.add_child(muzzle)

	flame = Fx.make_fire_emitter(110, 0.5, 13.0, 18.0, 9.0, 0.35, 1.5)
	flame.top_level = true
	add_child(flame)

	_equip(weapon_index)

	laser_mat = Fx.emissive(Color(1.0, 0.15, 0.2), 3.0)
	laser = MeshInstance3D.new()
	var lm := BoxMesh.new()
	lm.size = Vector3(0.014, 0.014, 1.0)
	laser.mesh = lm
	laser.material_override = laser_mat
	laser.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	laser.top_level = true
	add_child(laser)
	laser_dot = MeshInstance3D.new()
	var dm := SphereMesh.new()
	dm.radius = 0.05
	dm.height = 0.1
	laser_dot.mesh = dm
	laser_dot.material_override = Fx.emissive(Color(1.0, 0.2, 0.25), 10.0)
	laser_dot.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	laser_dot.top_level = true
	add_child(laser_dot)

	var own_light := OmniLight3D.new()
	own_light.light_color = Color(0.3, 0.9, 1.0)
	own_light.light_energy = 1.4
	own_light.omni_range = 8.0
	own_light.position = Vector3(0, 2.4, 0)
	add_child(own_light)

	_play("Idle_Gun")


## Her silah için kendine özgü modeli kurar ve karakterin elindeki silah yuvasına takar.
## (Quaternius modelinin kendi silahları gizlenir.)
func _make_custom_guns() -> void:
	if not gun_meshes.has("Rifle"):
		return
	var rifle: MeshInstance3D = gun_meshes["Rifle"]
	var parent := rifle.get_parent()
	var slot_xf := rifle.transform
	for k in gun_meshes.keys():
		gun_meshes[k].visible = false
	gun_meshes.clear()
	_gun_base_scale.clear()
	for w in weapons:
		var model := WeaponModels.build(String(w["name"]), w["color"])
		model.transform = slot_xf
		model.visible = false
		parent.add_child(model)
		gun_meshes[String(w["name"])] = model


func _cyl(r: float, length: float) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = r
	c.bottom_radius = r
	c.height = length
	return c


func _box(s: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = s
	return b


func _gun_part(parent: Node3D, mesh: Mesh, pos: Vector3, rot: Vector3, m: Material) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = m
	mi.position = pos
	mi.rotation = rot
	parent.add_child(mi)


func _play(anim_name: String, blend := 0.15) -> void:
	if anim_name == _cur_anim or not anim.has_animation(anim_name):
		return
	_cur_anim = anim_name
	anim.play(anim_name, blend)


## Seçili silahı elde gösterir, namlu noktasını silahın ucuna taşır.
func _equip(i: int) -> void:
	for g in gun_meshes.values():
		g.visible = false
	var w: Dictionary = weapons[i]
	var mesh_name := String(w["name"])
	if gun_meshes.has(mesh_name):
		var g: Node3D = gun_meshes[mesh_name]
		g.visible = true
		if _gun_base_scale.has(mesh_name):
			var s: Vector3 = _gun_base_scale[mesh_name] * float(w.get("mesh_scale", 1.0))
			s.x *= float(w.get("mesh_scale_x", 1.0))
			g.scale = s
		var tip: Vector3
		if g.has_meta("tip"):
			tip = g.get_meta("tip")
		else:
			var box := (g as MeshInstance3D).get_aabb()
			tip = Vector3(box.end.x, box.get_center().y, box.get_center().z)  # silahlar modelde +X yönünde uzanıyor
		muzzle.reparent(g, false)
		muzzle.position = tip
	else:
		muzzle.reparent(pivot, false)
		muzzle.position = Vector3(0.2, GUN_HEIGHT, -0.9)


func current_weapon_name() -> String:
	return String(weapons[weapon_index]["name"])


# ---------------------------------------------------------------- nişan

func _update_aim() -> void:
	var mp := get_viewport().get_mouse_position()
	var from: Vector3 = camera.project_ray_origin(mp)
	var dir: Vector3 = camera.project_ray_normal(mp)
	var q := PhysicsRayQueryParameters3D.create(from, from + dir * 200.0, 4)
	var res := get_world_3d().direct_space_state.intersect_ray(q)
	if not res.is_empty():
		aim_point = res["position"]
		return
	var plane := Plane(Vector3.UP, GUN_HEIGHT)
	var hit = plane.intersects_ray(from, dir)
	if hit != null:
		aim_point = hit


func _aim_dir() -> Vector3:
	var d := aim_point - muzzle.global_position
	if d.length() < 0.05:
		d = -pivot.global_transform.basis.z
	return d.normalized()


func _update_laser() -> void:
	var origin := muzzle.global_position
	var d := _aim_dir()
	var to := origin + d * 40.0
	var q := PhysicsRayQueryParameters3D.create(origin, to, 1 | 4, [get_rid()])
	q.hit_from_inside = true
	var res := get_world_3d().direct_space_state.intersect_ray(q)
	var end := to
	if not res.is_empty():
		end = res["position"]
	var length := origin.distance_to(end)
	if length < 0.05:
		laser.visible = false
		laser_dot.visible = false
		return
	laser.visible = true
	laser_dot.visible = not res.is_empty()
	laser.global_transform = Transform3D(Basis.looking_at(d, Vector3.UP), (origin + end) * 0.5)
	laser.scale = Vector3(1.0, 1.0, length)
	laser_dot.global_position = end
	laser_mat.emission = Color(weapons[weapon_index]["color"])


func _process(delta: float) -> void:
	if camera == null:
		return
	if not dead:
		var flat := aim_point - global_position
		flat.y = 0.0
		if flat.length() > 0.2:
			pivot.rotation.y = atan2(-flat.x, -flat.z)
		camera.look_ahead = (flat * 0.18).limit_length(3.0)

	kick = lerpf(kick, 0.0, 1.0 - exp(-20.0 * delta))
	model.position.z = kick
	if _flaming:
		muzzle_light.light_energy = 5.0 + randf() * 2.0
	else:
		muzzle_light.light_energy = move_toward(muzzle_light.light_energy, 0.0, delta * 80.0)
	if muzzle_flash.visible:
		muzzle_flash.global_position = muzzle.global_position
		muzzle_flash.scale *= maxf(1.0 - delta * 25.0, 0.0)
		if muzzle_flash.scale.x < 0.1:
			muzzle_flash.visible = false
	hurt_flash = maxf(hurt_flash - delta * 5.0, 0.0)
	var on := hurt_flash > 0.01
	hurt_mat.albedo_color.a = hurt_flash * 0.7
	for m in model_meshes:
		if is_instance_valid(m):
			m.material_overlay = hurt_mat if on else null


# ---------------------------------------------------------------- hareket

func _physics_process(delta: float) -> void:
	if dead:
		flame.emitting = false
		velocity = velocity.move_toward(Vector3.ZERO, 30.0 * delta)
		move_and_slide()
		return

	dash_cd -= delta
	invuln -= delta
	fire_cd -= delta
	if camera != null:
		_update_aim()
		_update_laser()

	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var move := Vector3.ZERO
	if camera != null:
		var b: Basis = camera.global_transform.basis
		var fwd := -b.z
		fwd.y = 0.0
		fwd = fwd.normalized()
		var right := b.x
		right.y = 0.0
		right = right.normalized()
		move = right * input.x - fwd * input.y
	if move.length() > 1.0:
		move = move.normalized()

	if Input.is_action_just_pressed("dash") and dash_cd <= 0.0:
		dash_dir = move.normalized() if move.length() > 0.1 else -pivot.global_transform.basis.z
		dash_dir.y = 0.0
		dash_dir = dash_dir.normalized()
		dash_timer = DASH_TIME
		dash_cd = dash_cooldown
		invuln = maxf(invuln, DASH_TIME + 0.08)
		collision_mask = 1
		Sfx.play("dash", -8.0)

	if dash_timer > 0.0:
		dash_timer -= delta
		velocity = dash_dir * DASH_SPEED
		if dash_timer <= 0.0:
			collision_mask = 1 | 4
	else:
		var hv := Vector3(velocity.x, 0.0, velocity.z)
		velocity = hv.move_toward(move * move_speed, ACCEL * delta)
	velocity.y = 0.0
	move_and_slide()
	global_position.y = 0.0

	_play("Run_Gun" if move.length() > 0.1 else "Idle_Gun")

	for i in weapons.size():
		if Input.is_action_just_pressed("weapon_%d" % (i + 1)):
			_set_weapon(i)
	if Input.is_action_just_pressed("weapon_next"):
		_set_weapon((weapon_index + 1) % weapons.size())
	if Input.is_action_just_pressed("weapon_prev"):
		_set_weapon((weapon_index - 1 + weapons.size()) % weapons.size())

	var w: Dictionary = weapons[weapon_index]
	var firing := Input.is_action_pressed("fire")
	_flaming = firing and String(w.get("type", "")) == "flame"
	flame.emitting = _flaming
	if _flaming:
		flame.global_transform = Transform3D(Basis.looking_at(_aim_dir(), Vector3.UP), muzzle.global_position)
	if firing and fire_cd <= 0.0:
		_shoot()


func _set_weapon(i: int) -> void:
	if i == weapon_index:
		return
	weapon_index = i
	fire_cd = maxf(fire_cd, 0.15)
	_equip(i)
	Sfx.play("switch", -6.0)
	weapon_changed.emit(current_weapon_name())


# ---------------------------------------------------------------- ateş

func _shoot() -> void:
	var w: Dictionary = weapons[weapon_index]
	fire_cd = 1.0 / (float(w["rate"]) * rate_mult)
	match String(w.get("type", "hitscan")):
		"flame":
			_shoot_flame(w)
		"rocket":
			_shoot_rocket(w)
		_:
			_shoot_bullets(w)


func _shoot_bullets(w: Dictionary) -> void:
	var origin := muzzle.global_position
	var base_dir := _aim_dir()
	var space := get_world_3d().direct_space_state
	var hit_flesh := false
	var spread := float(w["spread"])
	for i in int(w["pellets"]):
		var ang := deg_to_rad(randf_range(-spread, spread))
		var d := base_dir.rotated(Vector3.UP, ang)
		var to := origin + d * float(w["range"])
		var excl: Array[RID] = [get_rid()]
		var from := origin
		var end := to
		var dmg := float(w["damage"]) * dmg_mult
		var left := int(w.get("pierce", 0)) + 1
		while left > 0:
			var q := PhysicsRayQueryParameters3D.create(from, to, 1 | 4, excl)
			q.hit_from_inside = true
			var res := space.intersect_ray(q)
			if res.is_empty():
				end = to
				break
			end = res["position"]
			var col = res["collider"]
			if col != null and col.has_method("take_hit"):
				col.take_hit(dmg, d, float(w["knockback"]), end, w)
				if col.is_in_group("explosive"):
					break
				hit_flesh = true
				if col is CollisionObject3D:
					excl.append(col.get_rid())
				from = end
				dmg *= 0.8
				left -= 1
			else:
				var n: Vector3 = res["normal"]
				Fx.wall_hit(end, n)
				Sfx.play("wall", -16.0, 0.2, 60)
				break
		Fx.tracer(origin, end, w["color"])

	_fire_feedback(w, base_dir)
	if hit_flesh:
		Fx.hitstop(float(w["hitstop"]))
		get_tree().call_group("hud", "hit_marker")


## Alev: namlunun önündeki konide kalan yaratıkları tutuşturur, varilleri ısıtıp patlatır.
func _shoot_flame(w: Dictionary) -> void:
	var origin := muzzle.global_position
	var fwd := _aim_dir()
	var flat_fwd := Vector2(fwd.x, fwd.z).normalized()
	var reach := float(w["range"])
	var cone := deg_to_rad(float(w["cone"]))
	var space := get_world_3d().direct_space_state
	var targets: Array = get_tree().get_nodes_in_group("zombies") + get_tree().get_nodes_in_group("explosive")
	for z in targets:
		var zp: Vector3 = z.global_position + Vector3(0, 0.8, 0)
		var to := zp - origin
		var flat := Vector2(to.x, to.z)
		if flat.length() > reach or flat.length() < 0.01:
			continue
		if absf(flat_fwd.angle_to(flat.normalized())) > cone:
			continue
		var q := PhysicsRayQueryParameters3D.create(origin, zp, 1)
		var blocked := space.intersect_ray(q)
		if not blocked.is_empty() and blocked["collider"] != z:
			continue  # duvarın arkası
		var dir := Vector3(flat.x, 0, flat.y).normalized()
		if z.has_method("take_burn"):
			z.take_burn(float(w["damage"]) * dmg_mult, dir, float(w["burn"]))
		elif z.has_method("take_hit"):
			z.take_hit(float(w["damage"]) * 0.6, dir, 0.0, zp, w)
	Sfx.play(String(w["sound"]), float(w["sound_db"]), 0.1, 110)
	Fx.shake(float(w["shake"]))


func _shoot_rocket(w: Dictionary) -> void:
	var d := _aim_dir()
	var r = RocketScript.new()
	r.dir = d
	r.radius = float(w["radius"])
	r.damage = float(w["damage"]) * dmg_mult
	r.knockback = float(w["knockback"])
	var ex: Array[RID] = [get_rid()]
	r.exclude = ex
	get_parent().add_child(r)
	r.global_position = muzzle.global_position + d * 0.3
	r.look_at(r.global_position + d, Vector3.UP)
	_fire_feedback(w, d)


func _fire_feedback(w: Dictionary, d: Vector3) -> void:
	muzzle_light.light_energy = float(w.get("flash", 5.0))
	muzzle_flash.visible = true
	muzzle_flash.global_position = muzzle.global_position
	muzzle_flash.scale = Vector3.ONE * randf_range(0.8, 1.3)
	kick = float(w.get("kick", 0.0))
	velocity -= Vector3(d.x, 0.0, d.z) * float(w.get("self_push", 0.0))
	Sfx.play(String(w["sound"]), float(w["sound_db"]), 0.06, 0)
	Fx.shake(float(w["shake"]))


# ---------------------------------------------------------------- hasar

func take_damage(amount: float, dir: Vector3) -> void:
	if dead or invuln > 0.0:
		return
	hp = maxf(hp - amount, 0.0)
	invuln = 0.4
	hurt_flash = 1.0
	velocity += dir * 6.0
	Sfx.play("hurt", -2.0, 0.05, 80)
	Fx.shake(0.4)
	Fx.blood_spray(global_position + Vector3(0, 1.2, 0), dir, 0.6)
	hp_changed.emit(hp, max_hp)
	if hp <= 0.0:
		_die()


func _die() -> void:
	dead = true
	laser.visible = false
	laser_dot.visible = false
	muzzle_flash.visible = false
	flame.emitting = false
	died.emit()
	_play("Death", 0.1)
