extends Node3D
## İKİZLER: Kastor & Polluks. Aynı anda iki boss; can çubuğu ikisinin toplamıdır.
##  - İKİZ BAĞI: biri yere düşerse dokunulmaz olur ve 7 sn sonra kardeşi onu ayağa kaldırır.
##    Kardeşi bu sürede öfkelenir (daha hızlı). İkisini birbirine yakın zamanda indirmek gerekir.
##  - KASTOR (mavi): kılıç savurma (parry, 2-3'lü seri), düz hatta atılma; 2. evrede 5'li kılıç yelpazesi
##  - POLLUKS (altın): yumruk serisi (parry, 3'lü), yıldız yağmuru; 2. evrede yayılan halka (nova)
##  - YER DEĞİŞTİRME: arada bir ikisi ışınlanıp yer değiştirir
##  - 3. evre ÇAPRAZ IŞIN: ikisi kahramanın iki yanına ışınlanır ve aynı anda birbirine doğru ışın atar

signal killed(b)
signal summon(kinds: Array)
signal phase_changed(p: int)
signal hint(title: String, sub: String)

const TwinScript = preload("res://scripts/gemini_twin.gd")

var kind := "gemini"
var title := "GEMINI  ·  CASTOR & POLLUX"
var max_hp := 2600.0
var hp := 2600.0
## §13.6: evre alt süresi (taban ikizlerin take_hit'inde uygulanır)
const PHASE_MIN_T := 6.0
var phase_th: Array = [0.6, 0.3]
var _phase_t0 := 0.0
var phase := 1:
	set(v):
		phase = v
		_phase_t0 = Time.get_ticks_msec() / 1000.0


func _phase_floor() -> float:
	var i := phase - 1
	var has_th := i >= 0 and i < phase_th.size()
	if Time.get_ticks_msec() / 1000.0 - _phase_t0 >= PHASE_MIN_T:
		# süre doldu: can eşiğin hemen altına iner (sonraki evre başlar) ama fazla hasar sonraki evreye taşınmaz
		return float(phase_th[i]) * max_hp - 1.0 if has_th else 0.0
	if has_th:
		return float(phase_th[i]) * max_hp
	return 1.0
var dead := false
var hero = null
var dmg_mult := 1.0
var windup_mult := 1.0
var total_eclipse := false
var last_dealt := 0.0
var _bounds := 10.0
var _face := Vector3.FORWARD
var castor = null
var pollux = null
var _swap_t := 12.0
var _pincer_t := 4.0
var _hinted := false
var _spawned := false


func _ready() -> void:
	_phase_t0 = Time.get_ticks_msec() / 1000.0
	call_deferred("_spawn_twins")


func _spawn_twins() -> void:
	var side := Vector3(1, 0, 0)
	castor = _make("castor", global_position - side * 3.0)
	pollux = _make("pollux", global_position + side * 3.0)
	castor.partner = pollux
	pollux.partner = castor
	_spawned = true
	Fx.shake(0.6)


func _make(who: String, pos: Vector3):
	var t = TwinScript.new()
	t.who = who
	t.ctrl = self
	t.hero = hero
	t.max_hp = max_hp * 0.5
	t.dmg_mult = dmg_mult
	t.windup_mult = windup_mult
	t._bounds = _bounds
	get_parent().add_child(t)
	t.global_position = Vector3(pos.x, 0.0, pos.z)
	t._face = _face
	return t


func _process(delta: float) -> void:
	if dead or not _spawned:
		return
	hp = maxf(float(castor.hp), 0.0) + maxf(float(pollux.hp), 0.0)
	var f := hp / max_hp
	if phase == 1 and f < 0.6:
		_enter_phase(2)
	elif phase == 2 and f < 0.3:
		_enter_phase(3)
	# arada bir yer değiştirirler
	_swap_t -= delta
	if _swap_t <= 0.0:
		_swap_t = randf_range(10.0, 14.0)
		if _free(castor) and _free(pollux):
			var a: Vector3 = castor.global_position
			castor._blink_to(pollux.global_position)
			pollux._blink_to(a)
	# 3. evre: çapraz ışın
	if phase >= 3:
		_pincer_t -= delta
		if _pincer_t <= 0.0 and _free(castor) and _free(pollux) and hero != null and is_instance_valid(hero) and not hero.dead:
			_pincer_t = randf_range(9.0, 12.0)
			var hp_pos: Vector3 = hero.global_position
			var a := randf() * TAU
			var d := Vector3(cos(a), 0, sin(a))
			var p1 := _clamp(hp_pos + d * 6.0)
			var p2 := _clamp(hp_pos - d * 6.0)
			castor.start_pincer(p1, hp_pos)
			pollux.start_pincer(p2, hp_pos)


func _free(t) -> bool:
	return t != null and is_instance_valid(t) and not t.down and not t.gone and (t.state == "chase" or t.state == "recover")


func _clamp(p: Vector3) -> Vector3:
	var fl := Vector2(p.x, p.z)
	if fl.length() > _bounds - 0.5:
		fl = fl.normalized() * (_bounds - 0.5)
	return Vector3(fl.x, 0.0, fl.y)


func _enter_phase(p: int) -> void:
	phase = p
	Fx.shake(0.7)
	Sfx.play("bossroar", 0.0, 0.0, 0, 0.8)
	for t in [castor, pollux]:
		if t != null and is_instance_valid(t) and not t.gone:
			Fx.flash_light(t.global_position + Vector3(0, 2, 0), t.col_main, 8.0, 12.0, 0.6)
	if p == 2:
		summon.emit(["shade", "shade"])
	elif p == 3:
		summon.emit(["caster", "leaper"])
		hint.emit("THE TWINS UNITE", tr("Watch both sides!"))
	phase_changed.emit(p)


func on_twin_down(t) -> void:
	var other = t.partner
	if other == null or not is_instance_valid(other) or other.down or other.gone:
		_finish()
		return
	other.enrage(true)
	if not _hinted:
		_hinted = true
		hint.emit("TWIN BOND", tr("Defeat the other twin before it rises!"))


func on_twin_revived(t) -> void:
	var other = t.partner
	if other != null and is_instance_valid(other):
		other.enrage(false)


func _finish() -> void:
	if dead:
		return
	dead = true
	hp = 0.0
	for t in [castor, pollux]:
		if t != null and is_instance_valid(t):
			t.vanish()
	killed.emit(self)
	var tw := create_tween()
	tw.tween_interval(2.0)
	tw.tween_callback(queue_free)


## Kontrolcünün kendisi vurulamaz (vuruşlar ikizlere gider)
func take_hit(_dmg: float, _dir: Vector3, _kb: float, _heavy: bool, _crit := false) -> void:
	pass
