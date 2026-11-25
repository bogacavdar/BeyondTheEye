extends "res://scripts/zombie.gd"
## BOSS: KOVAN ANASI
## Neon Şehir'in sonu. Dev örümcek-et yığını: şiş karnında yavrular taşır.
## Saldırılar:
##   Pençe     : yakındaysan iki dev pençeyle vurur (kollar havaya kalkınca kaç!)
##   Asit      : yay çizen asit topları tükürür, yere düşünce asit gölü bırakır
##   Doğurma   : karnından örümcek yavruları (3. evrede şişkolar da) bırakır
##   Hücum     : (2. evreden sonra) kırmızı uyarı çizgisi, ardından üstüne koşar; duvara çarparsa sersemler
## Evreler: can %60'ın altına inince hızlanır ve hücuma başlar, %25'in altında öfkelenir.
## 8 bacağı ve 2 pençe kolu ayrı ayrı koparılabilir.

const AcidScript = preload("res://scripts/acid_glob.gd")

var phase := 1
var state := "intro"
var state_t := 2.0
var spit_cd := 5.0
var spawn_cd := 8.0
var charge_cd := 10.0
var charge_dir := Vector3.ZERO
var swipe_done := false
var abdomen: MeshInstance3D
var telegraph: MeshInstance3D
var _last_reported := -1.0


func setup(p_kind: String, p_target: Node3D, p_nav = null) -> void:
	kind = "boss"
	target = p_target
	nav = p_nav
	max_hp = 3200.0
	hp = max_hp
	speed = 2.4
	damage = 25.0
	body_scale = 1.0
	skin = Color(0.55, 0.3, 0.42)


func _build_body() -> void:
	var body := _pivot(visual, Vector3(0, 1.8, 0))
	torso_mi = _part(body, _sphere(1.0), Vector3(0, 0, -0.2), Vector3.ZERO, Vector3(1.15, 0.85, 1.2))
	abdomen = _part(body, _sphere(1.5), Vector3(0, 0.55, 1.9), Vector3.ZERO, Vector3(1.0, 0.85, 1.15))
	_part(body, _sphere(0.5), Vector3(0.8, 1.1, 1.6))
	_part(body, _sphere(0.4), Vector3(-0.9, 0.9, 2.3))
	_part(body, _sphere(0.35), Vector3(0.2, 1.5, 2.5))
	var bone := Fx.mat(Color(0.85, 0.8, 0.65), 0.0, 0.4)
	for i in 5:
		_part(body, _boxm(Vector3(0.12, 0.6, 0.12)), Vector3(0, 1.0 - i * 0.05, 0.9 + i * 0.5), Vector3(-0.5, 0, 0), Vector3.ONE, bone)

	head_node = _pivot(body, Vector3(0, 0.2, -1.35))
	var head := _part(head_node, _sphere(0.62), Vector3.ZERO, Vector3.ZERO, Vector3(1.0, 0.85, 1.1))
	_eyes(head_node, Vector3(0, 0.18, -0.58), 0.32, 9, 0.08)
	for side: float in [-1.0, 1.0]:
		_part(head_node, _boxm(Vector3(0.12, 0.12, 0.7)), Vector3(0.22 * side, -0.35, -0.55), Vector3(0.3, side * 0.35, 0), Vector3.ONE, bone)
	_limb("head", head_node, head, 700.0, Vector3(0, 1, 0))

	# sekiz bacak
	for side: float in [-1.0, 1.0]:
		for i in 4:
			var hip := _pivot(body, Vector3(0.95 * side, 0.1, -0.8 + i * 0.62), Vector3(0, 0, side * 0.9))
			var leg := _part(hip, _capsule(0.14, 2.4), Vector3(0, -1.2, 0))
			_part(hip, _boxm(Vector3(0.1, 0.4, 0.1)), Vector3(0, -2.45, 0), Vector3.ZERO, Vector3.ONE, bone)
			_leg(hip, "y", (i - 1.5) * 0.3 * side, float(i) * 1.6 + (0.0 if side < 0.0 else PI), 0.32)
			_limb("leg_%s%d" % ["l" if side < 0.0 else "r", i], hip, leg, 240.0, Vector3(side, 0, 0))

	# iki dev pençe
	for side: float in [-1.0, 1.0]:
		var sh := _pivot(body, Vector3(0.8 * side, 0.35, -1.1), Vector3(-0.9, 0, side * 0.15))
		var arm := _part(sh, _capsule(0.2, 2.2), Vector3(0, -1.1, 0))
		_part(sh, _boxm(Vector3(0.14, 1.0, 0.4)), Vector3(0, -2.4, -0.2), Vector3(0.4, 0, 0), Vector3.ONE, bone)
		_arm(sh, -0.9, 0.0 if side < 0.0 else PI, 0.12)
		_limb("arm_l" if side < 0.0 else "arm_r", sh, arm, 380.0, Vector3(side, 0.3, 0))

	# hücum uyarı çizgisi
	telegraph = MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(2.6, 0.02, 1.0)
	telegraph.mesh = bm
	var tm := Fx.emissive(Color(1.0, 0.05, 0.1), 4.0)
	tm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	tm.albedo_color = Color(0, 0, 0, 0.6)
	telegraph.material_override = tm
	telegraph.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	telegraph.top_level = true
	telegraph.visible = false
	add_child(telegraph)


func _ready() -> void:
	super._ready()
	Sfx.play("roar", 2.0, 0.0, 0)
	Fx.shake(0.8)
	_report_hp()


func _report_hp() -> void:
	if absf(hp - _last_reported) > 1.0:
		_last_reported = hp
		get_tree().call_group("hud", "set_boss_hp", maxf(hp, 0.0), max_hp)


# ---------------------------------------------------------------- yapay zekâ

func _physics_process(delta: float) -> void:
	if dead:
		return
	flash = maxf(flash - delta * 14.0, 0.0)
	if burn_t > 0.0:
		burn_t -= delta
		hp -= 15.0 * delta
		if burn_t <= 0.0 and burn_fx != null:
			burn_fx.emitting = false
	_apply_params()
	_report_hp()
	if hp <= 0.0:
		_die(Vector3.FORWARD, 0.0, false)
		return

	state_t -= delta
	spit_cd -= delta
	spawn_cd -= delta
	charge_cd -= delta
	attack_cd -= delta
	var new_phase := 1 if hp > max_hp * 0.6 else (2 if hp > max_hp * 0.25 else 3)
	if new_phase != phase:
		phase = new_phase
		Sfx.play("roar", 2.0, 0.05, 0, 0.9)
		Fx.shake(0.6)
		state = "spawn"
		state_t = 1.0

	var to := Vector3.ZERO
	var dist := 999.0
	if target != null and is_instance_valid(target):
		to = target.global_position - global_position
		to.y = 0.0
		dist = to.length()
	var dirp := to.normalized() if dist > 0.01 else Vector3.FORWARD
	var leg_factor := maxf(1.0 - legs_lost * 0.07, 0.4)
	var move := Vector3.ZERO
	var face := dirp

	match state:
		"intro":
			if state_t <= 0.0:
				state = "walk"
		"walk":
			var dir := dirp
			if nav != null:
				var nd: Vector3 = nav.dir_at(global_position)
				if nd != Vector3.ZERO:
					dir = nd
			face = dir
			move = dir * speed * (1.0 + 0.25 * (phase - 1)) * leg_factor
			if dist < 4.6 and attack_cd <= 0.0 and arms_lost < 2:
				state = "swipe"
				state_t = 0.6
				swipe_done = false
				attack_anim = 0.45
			elif spit_cd <= 0.0 and dist < 24.0:
				state = "spit"
				state_t = 0.7
				spit_cd = 5.0 if phase < 3 else 3.2
				_spit()
			elif spawn_cd <= 0.0:
				state = "spawn"
				state_t = 1.0
			elif phase >= 2 and charge_cd <= 0.0 and dist > 6.0 and dist < 26.0:
				state = "charge_wind"
				state_t = 0.9
				charge_dir = dirp
				Sfx.play("roar", -2.0, 0.1, 0, 1.3)
		"swipe":
			if state_t < 0.25 and not swipe_done:
				swipe_done = true
				Fx.shake(0.4)
				Sfx.play("splat", 0.0, 0.1, 0, 0.6)
				if dist < 5.2:
					target.call("take_damage", damage * (1.0 - 0.35 * arms_lost), dirp)
			if state_t <= 0.0:
				state = "walk"
				attack_cd = 1.3
		"spit":
			if state_t <= 0.0:
				state = "walk"
		"spawn":
			abdomen.scale = Vector3(1.0, 0.85, 1.15) * (1.0 + 0.12 * sin(state_t * 30.0))
			if state_t <= 0.0:
				abdomen.scale = Vector3(1.0, 0.85, 1.15)
				var back := global_position - face * 3.0
				get_tree().call_group("game", "spawn_minion", "spider", back, 3 + phase)
				if phase >= 3:
					get_tree().call_group("game", "spawn_minion", "bloater", back, 1)
				Fx.blood_burst(back + Vector3(0, 1.5, 0), -face)
				Sfx.play("splat", 2.0, 0.1, 0, 0.7)
				spawn_cd = 10.0 if phase < 3 else 6.5
				state = "walk"
		"charge_wind":
			face = charge_dir
			telegraph.visible = true
			var tlen := 20.0
			telegraph.global_transform = Transform3D(Basis.looking_at(charge_dir, Vector3.UP), global_position + charge_dir * tlen * 0.5 + Vector3(0, 0.05, 0))
			telegraph.scale = Vector3(1.0, 1.0, tlen)
			visual.position.x = randf_range(-0.05, 0.05)
			if state_t <= 0.0:
				telegraph.visible = false
				state = "charge"
				state_t = 1.2
				swipe_done = false
		"charge":
			face = charge_dir
			move = charge_dir * 17.0
			if not swipe_done and dist < 3.2:
				swipe_done = true
				target.call("take_damage", 30.0, dirp)
				Fx.shake(0.6)
			if is_on_wall() and state_t < 1.1:
				state = "stunned"
				state_t = 1.6
				Fx.shake(0.9)
				Fx.hitstop(0.06)
				Sfx.play("boom", -4.0, 0.1, 0, 0.7)
			elif state_t <= 0.0:
				state = "walk"
				charge_cd = 9.0 if phase < 3 else 5.5
		"stunned":
			if state_t <= 0.0:
				state = "walk"
				charge_cd = 9.0 if phase < 3 else 5.5

	knock = knock.move_toward(Vector3.ZERO, 30.0 * delta)
	velocity = move + knock * 0.1
	velocity.y = 0.0
	move_and_slide()
	global_position.y = 0.0
	visual.rotation.y = lerp_angle(visual.rotation.y, atan2(-face.x, -face.z), (6.0 if state != "charge" else 12.0) * delta)
	_animate(delta, move.length() + (1.5 if state == "spawn" else 0.0))


func _spit() -> void:
	var n := 3 if phase == 1 else (4 if phase == 2 else 6)
	for i in n:
		var a = AcidScript.new()
		a.player = target
		a.start = global_position + Vector3(0, 3.0, 0)
		var off := Vector3(randf_range(-3.5, 3.5), 0, randf_range(-3.5, 3.5)) if i > 0 else Vector3.ZERO
		a.target_pos = Vector3(target.global_position.x, 0, target.global_position.z) + off
		a.flight = randf_range(0.9, 1.3)
		get_parent().add_child(a)
	Sfx.play("splat", 0.0, 0.1, 0, 1.3)


# ---------------------------------------------------------------- hasar (boss'a özel)

func take_hit(dmg: float, dir: Vector3, knockback: float, point: Vector3, w: Dictionary) -> void:
	super.take_hit(dmg, dir, knockback * 0.2, point, {})
	stagger = 0.0


func take_explosion(dmg: float, dir: Vector3, kb: float, origin: Vector3) -> void:
	if dead:
		return
	hp -= dmg * 0.8
	flash = 1.0
	Fx.blood_spray(global_position + Vector3(0, 2.0, 0), dir, 2.0)
	for k in limbs.keys():
		if randf() < 0.08:
			_sever(k, (dir + Vector3(0, 0.6, 0)).normalized())


## Ölüm: art arda et patlamaları, devrilip yere çöker.
func _die(dir: Vector3, knockback: float, gib: bool, burned := false) -> void:
	if dead:
		return
	dead = true
	telegraph.visible = false
	remove_from_group("zombies")
	collision_layer = 0
	collision_mask = 1
	get_tree().call_group("hud", "set_boss_hp", 0.0, max_hp)
	killed.emit(self)
	Sfx.play("roar", 4.0, 0.0, 0, 0.7)
	Fx.hitstop(0.12)
	Fx.shake(1.0)
	for i in 8:
		var t := get_tree().create_timer(0.25 * i)
		t.timeout.connect(func():
			if not is_inside_tree():
				return
			var p := global_position + Vector3(randf_range(-2.5, 2.5), randf_range(1.0, 3.0), randf_range(-2.5, 2.5))
			Fx.blood_burst(p, Vector3(randf_range(-1, 1), 1, randf_range(-1, 1)).normalized())
			Fx.gibs(p, Vector3.UP, 8)
			Fx.shake(0.5)
			Sfx.play("splat", 2.0, 0.15, 0, 0.6)
		)
	for k in limbs.keys():
		if randf() < 0.5:
			_sever(k, Vector3(randf_range(-1, 1), 0.5, randf_range(-1, 1)).normalized())
	var tw := create_tween()
	tw.tween_interval(1.0)
	tw.tween_property(visual, "position:y", -0.9, 1.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(visual, "rotation:z", 0.35, 1.2)
