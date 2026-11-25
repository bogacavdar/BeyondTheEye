extends "res://scripts/hub_player.gd"
## KAHRAMAN (dövüş): Yolcu'nun bedeni + seçilen kozmik silah.
## Sol tık: 3 vuruşluk kombo · Q: ağır saldırı · Sağ tık: parry · Boşluk: atılma · Shift (basılı): koşma
## 1 / 2 / 3: silahın yetenekleri (weapon_kits.gd). Fare: nişan yönü.
## Parry: sadece ALTIN uyarılı saldırılar karşılanabilir. KIZIL uyarılı saldırılardan atılarak kaçılır.
## Değerler Doğum Haritası'ndan gelir (hero_stats.gd).

signal hp_changed(hp: float, max_hp: float)
signal hurt
signal died
signal parried

const Weapons = preload("res://scripts/celestial_weapons.gd")
const SlashFx = preload("res://scripts/slash_fx.gd")
const Skills = preload("res://scripts/star_skills.gd")
const Kits = preload("res://scripts/weapon_kits.gd")
const Stats = preload("res://scripts/hero_stats.gd")
const GameData = preload("res://scripts/game_data.gd")
const Retro = preload("res://scripts/retro.gd")

const BASE_HP := 100.0
const SPRINT_MULT := 1.6
const PARRY_WINDOW := 0.17
const PARRY_RECOVER := 0.3
const PARRY_COOLDOWN := 0.5
const DASH_COOLDOWN := 0.6

var weapon_id := "STAR SWORD"
var kit: Dictionary = {}
var st: Dictionary = {}              # Doğum Haritası'ndan gelen değerler
var SKILL_CD := [9.0, 6.0, 11.0]     # HUD için (kit'ten doldurulur)
var max_hp := 100.0
var hp := 100.0
var shield := 0.0
var dead := false
var revives := 0
var _unbroken_used := false
var aim := Vector3.FORWARD
var aim_point := Vector3.ZERO
var skill_cd := [0.0, 0.0, 0.0]
var state := "free"                  # free, attack, parry, cast, dead
var sprinting := false
var _cast_t := 0.0
var _atk: Dictionary = {}
var _atk_t := 0.0
var _atk_hit := false
var _combo_i := 0
var _combo_reset := 0.0
var _queued := ""
var _parry_t := 0.0
var _parry_cd := 0.0
var _invuln := 0.0
var _slow_t := 0.0      # Diken Çalısı: yavaşlatma süresi
var _slow_mult := 1.0
var _regen_acc := 0.0
var _first_strike := true
var _kills := 0
var _col := Color(0.95, 0.85, 0.5)
var _leap_from := Vector3.ZERO
var _leap_to := Vector3.ZERO
var _leap_h := 0.0
var _empowered := false
var _dash_hits: Array = []
var _crit_buff_t := 0.0     # Tutulma: her vuruş kritik
var _charge_t := 0.0        # Günberi Hücumu: mızrakla ileri atılış
var _charge_dmg := 0.0
var _charge_hits: Array = []

var blade_pivot: Node3D
var sword: Node3D
var _hit_this_swing: Array = []


func _ready() -> void:
	super._ready()
	add_to_group("hero")
	blade_pivot = Node3D.new()
	blade_pivot.position = Vector3(0.16, 1.12, 0)
	pivot.add_child(blade_pivot)
	equip(GameData.chosen_weapon)
	hp = max_hp
	shield = float(st["shield"]) + float(st["room_shield"])


## Silahı eline al (Gözlemevinde sunaktan değiştirince de çağrılır)
func equip(id: String) -> void:
	weapon_id = id
	kit = Kits.get_kit(weapon_id)
	_col = kit["color"]
	_compute_stats()
	hp = minf(hp, max_hp) if hp > 0.0 else max_hp
	for i in 3:
		skill_cd[i] = 0.0
	if sword != null and is_instance_valid(sword):
		sword.queue_free()
	sword = Weapons.build(weapon_id, _col)
	sword.position = Vector3(0, 0, -0.18)
	blade_pivot.add_child(sword)
	state = "free"
	_combo_i = 0
	_idle_pose(1.0)


func _compute_stats() -> void:
	st = Stats.compute(GameData.chart, GameData.run_boons)
	for i in 3:
		SKILL_CD[i] = float(kit["skills"][i]["cd"]) * maxf(1.0 - float(st["haste"]) / 100.0, 0.35)
	var rt: Dictionary = GameData.retro
	st["dust_gain"] = float(st["dust_gain"]) + 10.0 * float(Retro.heat(rt))
	st["heal_mult"] = maxf(1.0 - 0.3 * float(Retro.rank(rt, "saturn")), 0.1)
	st["dash_mult"] = 1.0 + 0.4 * float(Retro.rank(rt, "mercury"))
	max_hp = (BASE_HP + float(st["max_hp"])) * (1.0 - 0.2 * float(Retro.rank(rt, "sun")))
	revives = maxi(int(st["revives"]) - GameData.run_revives_used, 0)


## Yeni lütuf alınınca değerleri yeniden hesapla (artan en yüksek can kadar iyileş)
func refresh_stats() -> void:
	var old_max := max_hp
	_compute_stats()
	if max_hp > old_max:
		hp += max_hp - old_max
	hp = minf(hp, max_hp)
	hp_changed.emit(hp, max_hp)


## Odalar arası taşınan can (run boyunca)
func set_run_hp(v: float) -> void:
	hp = clampf(v, 1.0, max_hp)
	hp_changed.emit(hp, max_hp)


func room_cleared() -> void:
	_first_strike = true
	heal(float(st["room_heal"]))


func heal(v: float) -> void:
	if v <= 0.0 or dead:
		return
	hp = minf(hp + v * (1.0 + float(st["heal_power"]) / 100.0) * float(st.get("heal_mult", 1.0)), max_hp)
	hp_changed.emit(hp, max_hp)


# ---------------------------------------------------------------- nişan

func _update_aim() -> void:
	if camera == null:
		return
	var mp := get_viewport().get_mouse_position()
	var from: Vector3 = camera.project_ray_origin(mp)
	var dir: Vector3 = camera.project_ray_normal(mp)
	if absf(dir.y) < 0.001:
		return
	var t := (1.0 - from.y) / dir.y
	var hit := from + dir * t
	aim_point = Vector3(hit.x, 0.0, hit.z)
	var d := hit - global_position
	d.y = 0.0
	if d.length() > 0.2:
		aim = d.normalized()


func _face(dir: Vector3, delta: float, spd := 30.0) -> void:
	pivot.rotation.y = lerp_angle(pivot.rotation.y, atan2(-dir.x, -dir.z), minf(spd * delta, 1.0))


# ---------------------------------------------------------------- ana döngü

func _physics_process(delta: float) -> void:
	_t += delta
	dash_cd -= delta
	_parry_cd -= delta
	_invuln -= delta
	_combo_reset -= delta
	_crit_buff_t -= delta
	for i in 3:
		skill_cd[i] = maxf(float(skill_cd[i]) - delta, 0.0)
	if _combo_reset <= 0.0 and state == "free":
		_combo_i = 0
	if dead:
		velocity = velocity.move_toward(Vector3.ZERO, 30.0 * delta)
		move_and_slide()
		return
	# can yenileme: sadece savaş sırasında (odada düşman varken)
	if float(st["regen"]) > 0.0 and hp < max_hp and get_tree().get_node_count_in_group("enemies") > 0:
		_regen_acc += float(st["regen"]) * delta
		if _regen_acc >= 1.0:
			heal(floorf(_regen_acc))
			_regen_acc -= floorf(_regen_acc)

	_update_aim()
	var move := Vector3.ZERO
	if not frozen and camera != null:
		var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
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
		sprinting = Input.is_action_pressed("sprint") and move.length() > 0.1 and state == "free"
		_read_actions(move)

	var spd_now := SPEED * (1.0 + float(st["move_speed"]) / 100.0) * (SPRINT_MULT if sprinting else 1.0)
	if _slow_t > 0.0:
		_slow_t -= delta
		spd_now *= _slow_mult
	else:
		_slow_mult = 1.0
	match state:
		"attack":
			_tick_attack(delta, move)
		"parry":
			_parry_t -= delta
			velocity = velocity.move_toward(Vector3.ZERO, 40.0 * delta)
			if _parry_t <= -PARRY_RECOVER:
				state = "free"
		"cast":
			_cast_t -= delta
			if _charge_t > 0.0:
				_charge_t -= delta
				velocity = aim * 26.0
				_charge_strike()
			else:
				velocity = velocity.move_toward(Vector3.ZERO, 40.0 * delta)
			if _cast_t <= 0.0:
				state = "free"
		_:
			if dash_t > 0.0:
				dash_t -= delta
				velocity = dash_dir * DASH_SPEED * (1.0 + float(st["dash_dist"]) / 100.0)
				if bool(st["dash_strike"]):
					_dash_strike()
			else:
				velocity = _steer(velocity, move * spd_now, delta)

	velocity.y = 0.0
	trail.emitting = dash_t > 0.0 or sprinting
	move_and_slide()
	var flat := Vector2(global_position.x, global_position.z)
	if flat.length() > bound_radius:
		flat = flat.normalized() * bound_radius
		global_position = Vector3(flat.x, 0.0, flat.y)
	global_position.y = 0.0

	var hv := Vector3(velocity.x, 0, velocity.z)
	var spd := hv.length()
	if state == "free" and dash_t <= 0.0 and spd > 0.3:
		_face(move if move.length() > 0.1 else hv, delta, 24.0)
	elif state != "free":
		_face(aim, delta)
	_animate(delta, minf(spd, SPEED) if state == "free" else spd * 0.4)
	pivot.position.y += _leap_h
	if sprinting:
		body.rotation.x = lerpf(body.rotation.x, -0.3, 10.0 * delta)
	_pose_weapon(delta)
	if camera != null:
		camera.look_ahead = camera.look_ahead.lerp(aim * 1.2, 4.0 * delta)


## Merkür lütfu: atılırken içinden geçtiğin düşmanlara hasar
func _dash_strike() -> void:
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e) or e.dead or _dash_hits.has(e):
			continue
		var d: Vector3 = e.global_position - global_position
		d.y = 0.0
		if d.length() < 1.2 + float(e.radius):
			_dash_hits.append(e)
			var res: Array = calc_damage(15.0)
			e.take_hit(float(res[0]), dash_dir, 3.0, false)
			Sfx.play("hit", -8.0, 0.1, 30)


## Günberi Hücumu: atılış yolundaki düşmanlara bir kez vurur ve onları savurur
func _charge_strike() -> void:
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e) or e.dead or _charge_hits.has(e):
			continue
		var d: Vector3 = e.global_position - global_position
		d.y = 0.0
		if d.length() < 1.4 + float(e.radius):
			_charge_hits.append(e)
			var side := Vector3(-aim.z, 0, aim.x)
			var push := (aim + side * (1.0 if side.dot(d) > 0.0 else -1.0)).normalized()
			e.take_hit(_charge_dmg, push, 10.0, true)
			Sfx.play("heavyhit", -6.0, 0.08, 30)
			Fx.hitstop(0.05)


func _recovering() -> bool:
	return state == "attack" and _atk_t > (float(_atk["wind"]) + float(_atk["act"])) * _speed_k()


func _read_actions(move: Vector3) -> void:
	if Input.is_action_just_pressed("dash") and dash_cd <= 0.0:
		if state == "free" or _recovering() or (state == "parry" and _parry_t <= 0.0):
			state = "free"
			_queued = ""
			dash_dir = move.normalized() if move.length() > 0.1 else aim
			dash_t = DASH_TIME
			dash_cd = DASH_COOLDOWN * maxf(1.0 - float(st["dash_cdr"]) / 100.0, 0.3) * float(st.get("dash_mult", 1.0))
			_invuln = maxf(_invuln, DASH_TIME + 0.08)
			_dash_hits.clear()
			Sfx.play("dash", -10.0)
			return
	if Input.is_action_just_pressed("parry") and _parry_cd <= 0.0 and (state == "free" or _recovering()) and dash_t <= 0.0:
		state = "parry"
		_parry_t = PARRY_WINDOW * (1.0 + float(st["parry_window"]) / 100.0)
		_parry_cd = PARRY_COOLDOWN
		Sfx.play("switch", -14.0, 0.05, 0, 0.7)
		return
	for i in 3:
		if Input.is_action_just_pressed("skill_%d" % (i + 1)) and float(skill_cd[i]) <= 0.0 and dash_t <= 0.0:
			if state == "free" or _recovering():
				_use_skill(i)
				return
	if Input.is_action_just_pressed("fire"):
		if state == "free" and dash_t <= 0.0:
			_start_attack(kit["combo"][_combo_i])
		elif state == "attack":
			_queued = "fire"
	if Input.is_action_just_pressed("heavy"):
		if state == "free" and dash_t <= 0.0:
			_start_attack(kit["heavy"])
		elif state == "attack":
			_queued = "heavy"


# ---------------------------------------------------------------- saldırı

func _speed_k() -> float:
	return 1.0 / (1.0 + float(st["atk_speed"]) / 100.0)


func _is_heavy(a: Dictionary) -> bool:
	return a == kit["heavy"]


func _start_attack(a: Dictionary) -> void:
	state = "attack"
	_atk = a
	_atk_t = 0.0
	_atk_hit = false
	_queued = ""
	_hit_this_swing.clear()
	pivot.rotation.y = atan2(-aim.x, -aim.z)
	# savurma sesi (boşa savurmada duyulan tek ses budur)
	if not bool(kit.get("ranged", false)):
		Sfx.play("swing", -9.0 if not _is_heavy(a) else -6.0, 0.08, 0, _swing_pitch() * (0.85 if _is_heavy(a) else 1.0))


func _tick_attack(delta: float, move: Vector3) -> void:
	_atk_t += delta
	var k := _speed_k()
	var wind := float(_atk["wind"]) * k
	var act := float(_atk["act"]) * k
	var rec := float(_atk["rec"]) * k
	if _atk_t < wind + act:
		velocity = aim * float(_atk["step"])
	else:
		velocity = velocity.move_toward(move * SPEED * 0.25, 40.0 * delta)
	if not _atk_hit and _atk_t >= wind:
		_atk_hit = true
		_do_hit()
	if _atk_t >= wind + act + rec * 0.45 and _queued != "":
		var q := _queued
		_queued = ""
		_advance_combo()
		_start_attack(kit["heavy"] if q == "heavy" else kit["combo"][_combo_i])
		return
	if _atk_t >= wind + act + rec:
		state = "free"
		_advance_combo()
		_combo_reset = 0.45


func _advance_combo() -> void:
	if _is_heavy(_atk):
		_combo_i = 0
	else:
		_combo_i = (_combo_i + 1) % 3


## Hasar hesabı: temel × hasar bonusları × kritik. Dönüş: [hasar, kritik mi]
func calc_damage(base: float, kind_bonus := 0.0) -> Array:
	var m := 1.0 + (float(st["damage"]) + kind_bonus) / 100.0
	if bool(st["death_door"]) and hp < max_hp * 0.3:
		m += 0.3
	if bool(st["warrior"]) and hp > max_hp * 0.8:
		m += 0.1
	if bool(st["rage"]) and hp < max_hp * 0.5:
		m += 0.4
	if _empowered:
		m *= 2.0
		_empowered = false
	var crit: bool = _crit_buff_t > 0.0 or randf() * 100.0 < 5.0 + float(st["crit_chance"])
	if crit:
		m *= 1.5 + float(st["crit_dmg"]) / 100.0
	if _first_strike and bool(st["first_strike"]):
		m *= 3.0
		_first_strike = false
	return [base * m, crit]


func _do_hit() -> void:
	var rng := float(_atk["range"]) * (1.0 + float(st["reach"]) / 100.0)
	var half_arc := deg_to_rad(float(_atk["arc"])) * 0.5
	var finisher: bool = bool(_atk.get("finisher", false))
	var heavy: bool = _is_heavy(_atk)
	var bonus := 0.0
	if heavy:
		bonus = float(st["heavy_dmg"])
	elif finisher:
		bonus = float(st["finisher_dmg"])
	else:
		bonus = float(st["combo_dmg"])
	if bool(kit.get("ranged", false)):
		_fire_arrows(bonus, finisher, heavy)
		return
	var fx_node := SlashFx.make(float(_atk["a0"]), float(_atk["a1"]), 0.45, rng, _col)
	get_parent().add_child(fx_node)
	fx_node.global_transform = Transform3D(pivot.global_transform.basis, global_position + Vector3(0, 1.05, 0))
	var hits := 0
	var any_crit := false
	for e in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e) or e.dead or _hit_this_swing.has(e):
			continue
		var to: Vector3 = e.global_position - global_position
		to.y = 0.0
		var dist := to.length()
		if dist > rng + float(e.radius):
			continue
		if dist > 0.3 and aim.angle_to(to / dist) > half_arc:
			continue
		_hit_this_swing.append(e)
		var dir := to.normalized() if dist > 0.1 else aim
		var res: Array = calc_damage(float(_atk["dmg"]), bonus)
		var dmg: float = res[0]
		if bool(res[1]):
			any_crit = true
		e.take_hit(dmg, dir, float(_atk["kb"]) * 1.2, finisher, bool(res[1]))
		if bool(st["burn"]) and not e.dead and e.has_method("apply_burn"):
			e.apply_burn(5.0 * (1.0 + float(st["damage"]) / 100.0), 3.0)
		_on_dealt(dmg, e)
		hits += 1
	if hits > 0:
		Fx.hitstop(0.11 if finisher or any_crit else 0.065)
		Fx.shake(0.38 if finisher or any_crit else 0.24)
		_impact_sound(finisher or any_crit)


## Silaha göre savurma sesi perdesi
func _swing_pitch() -> float:
	match weapon_id:
		"MOON SCYTHE":
			return 0.8
		"SUN MACE":
			return 0.62
		"COMET SPEAR":
			return 1.2
		"METEOR CHAIN":
			return 1.3
	return 1.0


## Silaha göre isabet sesi: gerçek darbe + gövdeye oturan tok ses
func _impact_sound(big: bool) -> void:
	match weapon_id:
		"MOON SCYTHE":
			Sfx.play("cut", -3.0, 0.08, 0, 0.78)
			Sfx.play("hit", -6.0, 0.1, 0, 0.9)
		"SUN MACE":
			Sfx.play("crush", -2.0, 0.08, 0, 0.9)
			Sfx.play("heavyhit", -3.0, 0.08, 0, 0.85)
		"COMET SPEAR":
			Sfx.play("stab", -1.0, 0.1, 0, 1.0)
			Sfx.play("cut", -9.0, 0.1, 0, 1.35)
			Sfx.play("hit", -7.0, 0.1, 0, 1.15)
		"METEOR CHAIN":
			Sfx.play("crush", -5.0, 0.1, 0, 1.3)
			Sfx.play("hit", -4.0, 0.1, 0, 1.1)
		_:
			Sfx.play("cut", -3.0, 0.08, 0)
			Sfx.play("hit", -6.0, 0.1, 0)
	if big:
		Sfx.play("heavyhit", -4.0, 0.06, 0, 0.8)


## Yay: okları fırlat (yelpaze halinde birden fazla olabilir)
func _fire_arrows(bonus: float, finisher: bool, heavy: bool) -> void:
	var n := int(_atk.get("arrows", 1))
	var spread := float(_atk.get("spread", 0.0))
	for i in n:
		var ang := deg_to_rad(spread * (float(i) - float(n - 1) * 0.5))
		var d := aim.rotated(Vector3.UP, ang)
		var res: Array = calc_damage(float(_atk["dmg"]), bonus)
		var ar = Skills.Arrow.new()
		ar.dir = d
		ar.dmg = float(res[0])
		ar.crit = bool(res[1])
		ar.speed = float(_atk.get("speed", 34.0))
		ar.range_m = float(_atk.get("range", 15.0)) * (1.0 + float(st["reach"]) / 100.0)
		ar.pierce = int(_atk.get("pierce", 0))
		ar.kb = float(_atk["kb"])
		ar.heavy = heavy
		ar.col = _col
		ar.owner_node = self
		ar.position = global_position + Vector3(0, 1.15, 0) + d * 0.7
		get_parent().add_child(ar)
	Sfx.play("bowshot", -6.0 if not heavy else -2.0, 0.1, 0, 1.0 if not heavy else 0.75)
	Fx.shake(0.12 if not (finisher or heavy) else 0.25)


## Okların düşmana değmesi (can çalma, yanma vb. lütuf/yıldız etkileri)
func on_ranged_hit(dmg: float, e) -> void:
	if bool(st["burn"]) and not e.dead and e.has_method("apply_burn"):
		e.apply_burn(5.0 * (1.0 + float(st["damage"]) / 100.0), 3.0)
	_on_dealt(dmg, e)


## Verilen hasarın yan etkileri: can çalma, şifacı eller, hasat
func _on_dealt(dmg: float, e) -> void:
	if float(st["lifesteal"]) > 0.0:
		heal(dmg * float(st["lifesteal"]) / 100.0)
	if e.dead:
		_kills += 1
		if bool(st["healer"]):
			heal(3.0)
		if bool(st["harvest"]) and _kills % 10 == 0:
			heal(max_hp * 0.1)


# ---------------------------------------------------------------- yetenekler

func _use_skill(i: int) -> void:
	var sk: Dictionary = kit["skills"][i]
	skill_cd[i] = SKILL_CD[i]
	_queued = ""
	pivot.rotation.y = atan2(-aim.x, -aim.z)
	var thrown := float(st["thrown_dmg"]) if String(sk["type"]) == "wave" else 0.0
	var dres: Array = calc_damage(float(sk.get("dmg", 0.0)), thrown + float(st["skill_dmg"]))
	var dmg: float = dres[0]
	var off := aim_point - global_position
	off.y = 0.0
	var max_r := float(sk.get("max_range", 8.0))
	if off.length() > max_r:
		off = off.normalized() * max_r
	var target := global_position + off
	state = "cast"
	_cast_t = 0.25
	match String(sk["type"]):
		"starfall":
			var sf = Skills.Starfall.new()
			sf.radius = float(sk["radius"])
			sf.count = int(sk["count"])
			sf.dmg = dmg
			sf.delay = float(sk["delay"])
			sf.star_r = float(sk["star_r"])
			sf.col = _col
			sf.position = target
			get_parent().add_child(sf)
		"wave":
			var w = Skills.LightWave.new()
			w.dir = aim
			w.dmg = dmg
			w.speed = float(sk["speed"])
			w.max_dist = float(sk["range"])
			w.width = float(sk["width"])
			w.col = _col
			w.position = global_position + Vector3(0, 1.0, 0) + aim * 0.8
			get_parent().add_child(w)
			_cast_t = 0.2
		"path":
			var start := global_position
			var dest := start + aim * float(sk["dist"])
			var fl := Vector2(dest.x, dest.z)
			if fl.length() > bound_radius:
				fl = fl.normalized() * bound_radius
				dest = Vector3(fl.x, 0.0, fl.y)
			var pts: Array = []
			for k in 5:
				pts.append(start.lerp(dest, float(k) / 4.0))
			var cp = Skills.ConstellationPath.new()
			cp.points = pts
			cp.dmg = dmg
			cp.delay = float(sk["delay"])
			get_parent().add_child(cp)
			Fx.flash_light(start + Vector3(0, 1, 0), _col, 4.0, 5.0, 0.2)
			global_position = dest
			velocity = Vector3.ZERO
			_invuln = maxf(_invuln, 0.35)
			_cast_t = 0.15
			Sfx.play("dash", -6.0, 0.0, 0, 2.2)
		"burst_self":
			var b = Skills.Burst.new()
			b.radius = float(sk["radius"])
			b.dmg = dmg
			b.kb = float(sk["kb"])
			b.stun = float(sk["stun"])
			b.col = _col
			b.position = global_position
			get_parent().add_child(b)
		"burst_aim":
			var b2 = Skills.Burst.new()
			b2.radius = float(sk["radius"])
			b2.dmg = dmg
			b2.kb = 0.0
			b2.stun = float(sk["stun"])
			b2.pull = bool(sk["pull"])
			b2.delay = float(sk["delay"])
			b2.col = _col
			b2.position = target
			get_parent().add_child(b2)
		"leap":
			# hedefe zıpla, yere çakıl
			_invuln = maxf(_invuln, 0.5)
			_cast_t = 0.45
			_leap_from = global_position
			_leap_to = target
			var tw := create_tween()
			tw.tween_method(_leap_step, 0.0, 1.0, 0.4)
			var bl = Skills.Burst.new()
			bl.radius = float(sk["radius"])
			bl.dmg = dmg
			bl.kb = 12.0
			bl.stun = 0.4
			bl.delay = 0.4
			bl.col = _col
			bl.position = target
			get_parent().add_child(bl)
		"aura":
			var au = Skills.Aura.new()
			au.target = self
			au.radius = float(sk["radius"])
			au.dmg = dmg
			au.tick = float(sk["tick"])
			au.duration = float(sk["duration"])
			au.col = _col
			get_parent().add_child(au)
			_cast_t = 0.15
		"boomerang":
			var bm = Skills.Boomerang.new()
			bm.dir = aim
			bm.owner_node = self
			bm.dmg = dmg
			bm.range_m = float(sk["range"])
			bm.col = _col
			bm.position = global_position + Vector3(0, 1.0, 0) + aim * 0.8
			get_parent().add_child(bm)
			_cast_t = 0.2
		"vortex":
			var vx = Skills.Vortex.new()
			vx.radius = float(sk["radius"])
			vx.dmg = dmg
			vx.duration = float(sk["duration"])
			vx.col = _col
			vx.position = target
			get_parent().add_child(vx)
		"eclipse":
			# çevredekiler sersemler, birkaç saniye boyunca her vuruş kritik
			var be = Skills.Burst.new()
			be.radius = float(sk["radius"])
			be.dmg = dmg
			be.kb = 0.0
			be.stun = float(sk["stun"])
			be.col = Color(0.55, 0.4, 0.95)
			be.position = global_position
			get_parent().add_child(be)
			_crit_buff_t = float(sk["buff"])
			var halo = Skills.Aura.new()
			halo.target = self
			halo.radius = 1.3
			halo.dmg = 0.0
			halo.duration = float(sk["buff"])
			halo.col = Color(0.55, 0.4, 0.95)
			get_parent().add_child(halo)
		"cone":
			var fc = Skills.FlameCone.new()
			fc.dir = aim
			fc.dmg = dmg
			fc.reach = float(sk["reach"])
			fc.position = global_position + Vector3(0, 0.9, 0) + aim * 0.5
			get_parent().add_child(fc)
			_cast_t = 0.3
		"charge":
			_charge_t = float(sk["dist"]) / 26.0
			_charge_dmg = dmg
			_charge_hits.clear()
			_cast_t = _charge_t + 0.1
			_invuln = maxf(_invuln, _cast_t + 0.1)
			trail.emitting = true
			Sfx.play("dash", -4.0, 0.0, 0, 0.8)
		"line":
			var ls = Skills.LineStrike.new()
			ls.dir = aim
			ls.dmg = dmg
			ls.count = int(sk["count"])
			ls.bounds = bound_radius
			ls.col = _col
			ls.position = global_position
			get_parent().add_child(ls)
		"hook":
			var hk = Skills.Hook.new()
			hk.dir = aim
			hk.owner_node = self
			hk.dmg = dmg
			hk.range_m = float(sk["range"])
			hk.col = _col
			hk.position = global_position + Vector3(0, 1.0, 0) + aim * 0.6
			get_parent().add_child(hk)
			_cast_t = 0.2
		"disengage":
			# Kentaur Sıçrayışı: nişanın tersine sıçra, bıraktığın yerde patlama
			var start2 := global_position
			var back := start2 - aim * float(sk["dist"])
			var fl2 := Vector2(back.x, back.z)
			if fl2.length() > bound_radius:
				fl2 = fl2.normalized() * bound_radius
				back = Vector3(fl2.x, 0.0, fl2.y)
			var bd = Skills.Burst.new()
			bd.radius = float(sk["radius"])
			bd.dmg = dmg
			bd.kb = 8.0
			bd.stun = float(sk["stun"])
			bd.delay = 0.05
			bd.col = _col
			bd.position = start2
			get_parent().add_child(bd)
			_invuln = maxf(_invuln, 0.45)
			_cast_t = 0.35
			_leap_from = start2
			_leap_to = back
			var tw2 := create_tween()
			tw2.tween_method(_leap_step, 0.0, 1.0, 0.32)
			Sfx.play("dash", -4.0, 0.0, 0, 1.3)
		"orbit":
			var ob = Skills.Orbit.new()
			ob.target = self
			ob.radius = float(sk["radius"])
			ob.dmg = dmg
			ob.duration = float(sk["duration"])
			ob.count = int(sk["count"])
			ob.col = _col
			get_parent().add_child(ob)
			_cast_t = 0.15


func _leap_step(k: float) -> void:
	global_position = _leap_from.lerp(_leap_to, k)
	_leap_h = sin(k * PI) * 2.2
	if k >= 1.0:
		_leap_h = 0.0


# ---------------------------------------------------------------- silah duruşu

func _idle_pose(w: float) -> void:
	blade_pivot.rotation.y = lerp_angle(blade_pivot.rotation.y, -0.5, w)
	sword.rotation.x = lerpf(sword.rotation.x, -PI * 0.5 + 1.15, w)


func _pose_weapon(delta: float) -> void:
	match state:
		"attack" when bool(kit.get("ranged", false)):
			# yay: dik tutulur, kol öne uzanır, öbür el kirişi çeker
			blade_pivot.rotation.y = lerp_angle(blade_pivot.rotation.y, 0.0, 30.0 * delta)
			sword.rotation.x = lerpf(sword.rotation.x, 0.0, 30.0 * delta)
			sh_r.rotation.x = 1.5
			el_r.rotation.x = 0.05
			sh_l.rotation.x = 1.3
			el_l.rotation.x = 1.2
		"attack":
			var k := _speed_k()
			var wind := float(_atk["wind"]) * k
			var act := float(_atk["act"]) * k
			var a0 := float(_atk["a0"])
			var a1 := float(_atk["a1"])
			if _atk_t < wind:
				blade_pivot.rotation.y = lerpf(blade_pivot.rotation.y, a0, 25.0 * delta)
			else:
				var f := clampf((_atk_t - wind) / act, 0.0, 1.0)
				f = 1.0 - pow(1.0 - f, 3.0)
				blade_pivot.rotation.y = lerpf(a0, a1, f)
			sword.rotation.x = lerpf(sword.rotation.x, -PI * 0.5, 30.0 * delta)
			sh_r.rotation.x = 1.35
			sh_r.rotation.y = blade_pivot.rotation.y * 0.5
			el_r.rotation.x = 0.15
			chest.rotation.y = clampf(blade_pivot.rotation.y * 0.35, -0.6, 0.6)
		"cast":
			blade_pivot.rotation.y = lerp_angle(blade_pivot.rotation.y, 0.0, 25.0 * delta)
			sword.rotation.x = lerpf(sword.rotation.x, 0.2, 25.0 * delta)
			sh_r.rotation.x = 2.5
			el_r.rotation.x = 0.2
		"parry":
			blade_pivot.rotation.y = lerp_angle(blade_pivot.rotation.y, 0.35, 30.0 * delta)
			sword.rotation.x = lerpf(sword.rotation.x, -0.25, 30.0 * delta)
			sh_r.rotation.x = 1.1
			el_r.rotation.x = 0.9
		_:
			_idle_pose(minf(10.0 * delta, 1.0))
			sh_r.rotation.y = 0.0


# ---------------------------------------------------------------- hasar alma

## Düşman vuruşu. parryable=false ise parry işe yaramaz (sadece atılma kurtarır).
## Dönüş: "parried", "hit" ya da "miss"
func take_damage(amount: float, from_dir: Vector3, parryable := true) -> String:
	if dead:
		return "miss"
	if parryable and state == "parry" and _parry_t > 0.0:
		_on_parry(from_dir)
		return "parried"
	if _invuln > 0.0 or dash_t > 0.0:
		return "miss"
	if randf() * 100.0 < float(st["dodge"]):
		Sfx.play("dash", -12.0, 0.0, 0, 1.8)
		_invuln = 0.2
		return "miss"
	var dmg := amount
	var armor := float(st["armor"])
	dmg *= 50.0 / (50.0 + armor)
	dmg *= 1.0 - float(st["dmg_reduction"]) / 100.0
	if shield > 0.0:
		var absorbed := minf(shield, dmg)
		shield -= absorbed
		dmg -= absorbed
	hp = maxf(hp - dmg, 0.0)
	_invuln = 1.2 if bool(st["extra_iframes"]) else 0.6
	velocity = from_dir.normalized() * 9.0
	state = "free"
	_queued = ""
	Fx.shake(0.55)
	Fx.hitstop(0.07)
	Sfx.play("hurt", -6.0)
	if hp <= 0.0 and bool(st["unbroken"]) and not GameData.run_unbroken_used:
		GameData.run_unbroken_used = true
		hp = 1.0
		_invuln = 1.2
	elif hp <= 0.0 and revives > 0:
		revives -= 1
		GameData.run_revives_used += 1
		hp = max_hp * 0.5
		_invuln = 2.0
		Fx.flash_light(global_position + Vector3(0, 1.5, 0), Color(1.0, 0.85, 0.5), 10.0, 10.0, 0.8)
		Sfx.play("coin", -4.0, 0.0, 0, 0.5)
	hp_changed.emit(hp, max_hp)
	hurt.emit()
	if hp <= 0.0:
		_die()
	return "hit"


func _on_parry(from_dir: Vector3) -> void:
	_parry_t = 0.0
	_parry_cd = 0.0
	_invuln = 0.35
	state = "free"
	Fx.hitstop(0.6 if bool(st["libra"]) else 0.14)
	Fx.shake(0.4)
	Sfx.play("parry", -8.0, 0.04, 0)
	Sfx.play("heavyhit", -8.0, 0.05, 0, 1.2)
	if bool(st["accord"]):
		heal(2.0)
	if bool(st["parry_empower"]):
		_empowered = true
	var p := global_position + Vector3(0, 1.1, 0) - from_dir.normalized() * 0.6
	Fx.flash_light(p, Color(1.0, 0.9, 0.6), 6.0, 6.0, 0.25)
	var ring := SlashFx.make(0.0, TAU, 0.2, 1.6, Color(1.0, 0.95, 0.75))
	get_parent().add_child(ring)
	ring.global_transform = Transform3D(Basis.IDENTITY, p)
	parried.emit()


func _die() -> void:
	dead = true
	state = "dead"
	trail.emitting = false
	Fx.shake(0.8)
	Sfx.play("boom", -10.0, 0.0, 0, 1.6)
	var t := create_tween()
	t.tween_property(pivot, "rotation:x", PI * 0.5, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.parallel().tween_property(pivot, "position:y", 0.25, 0.6)
	died.emit()


## Dikenli alan gibi etkiler kahramanı kısa süre yavaşlatır
func apply_slow(mult: float, dur: float) -> void:
	_slow_mult = minf(_slow_mult, mult) if _slow_t > 0.0 else mult
	_slow_t = maxf(_slow_t, dur)
