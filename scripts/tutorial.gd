extends Node3D
## ÖĞRETİCİ ODA (GDD §14)
## Kaydında tutorial_done olmayan oyuncunun ilk tek kişilik run'ında, Koç Geçidi 1. odasından önce açılır;
## Gözlemevi'ndeki ANTRENMAN durağından "tekrar kipi"nde de açılır (GameData.tutorial_replay).
## Sade, yuvarlak bir gece arenası; tehlike yok, ölüm yok, can azalmaz (düşman hasarı 0).
## Toz düşmez, almanak/öldürme sayacı yazılmaz, run anlık kaydı alınmaz.
## Adımlar (§14.4): 0 giriş · 1 yürü · 2 saldır · 3 ağır · 4 atıl · 5 koş · 6 parry · 7 yetenekler · 8 prova · 9 kapı

const GameData = preload("res://scripts/game_data.gd")
const UI = preload("res://scripts/ui_style.gd")
const CameraScript = preload("res://scripts/camera_rig.gd")
const HeroScript = preload("res://scripts/hero.gd")
const EnemyScript = preload("res://scripts/enemy.gd")
const DummyScript = preload("res://scripts/training_dummy.gd")
const PauseUI = preload("res://scripts/pause_ui.gd")
const CombatHud = preload("res://scripts/combat_hud.gd")
const Juice = preload("res://scripts/juice.gd")
const ROOM_SCENE := "res://scenes/room.tscn"
const HUB_SCENE := "res://scenes/hub.tscn"

const ARENA_R := 11.0
const CTX := &"tutorial"
const NICE_TIME := 0.8
const IDLE_HINT := 20.0
const RING_R := 1.4
const GATE_POS := Vector3(0, 0, -8.5)

## Adımlar: başlık, talimat, öğretilen eylem (tuş rozeti / vurgulanan düğme için)
const STEPS := [
	{"title": "WELCOME, TRAVELER", "text": "First, learn the ways of the stars", "act": ""},
	{"title": "MOVE", "text": "Walk into the golden circle", "act": "move"},
	{"title": "ATTACK", "text": "Strike the star stone three times in a row", "act": "attack"},
	{"title": "HEAVY ATTACK", "text": "A heavy blow hits everything around you", "act": "heavy"},
	{"title": "DASH", "text": "Red warning: you can't block it. Dash through!", "act": "dash"},
	{"title": "SPRINT", "text": "Hold to sprint to the far circle", "act": "sprint"},
	{"title": "PARRY", "text": "Gold warning: meet the blow with a parry", "act": "parry"},
	{"title": "STAR SKILLS", "text": "Use all three skills", "act": "skills"},
	{"title": "PRACTICE", "text": "Defeat both shades", "act": ""},
	{"title": "THE GATE", "text": "Step through the gate. Your journey begins", "act": "interact"},
]

## Tuş metinleri giriş kipine göre (§14.5)
const KEYS := {
	"mouse": {"move": "WASD", "attack": "Left click", "heavy": "Right click", "dash": "Space", "sprint": "Hold Space",
		"parry": "Shift", "skills": "Q · E · R", "interact": "E", "skip": "Esc"},
	"pad": {"move": "Left stick", "attack": "X", "heavy": "Y", "dash": "A", "sprint": "LT",
		"parry": "B", "skills": "LB · RB · RT", "interact": "X", "skip": "Start"},
	"touch": {"move": "Drag on the left side", "attack": "Tap the right side", "heavy": "HEAVY button", "dash": "Double tap or »",
		"sprint": "Push the stick all the way", "parry": "PARRY button", "skills": "Skill buttons, drag to aim", "interact": "USE button", "skip": "II"},
}
## HUD yetenek çubuğunda parlayan slot (0-2 Q/E/R, 3 RMB, 4 SPACE, 5 SHIFT) ve dokunmatikte vurgulanan düğme
const HUD_SLOT := {"heavy": [3], "dash": [4], "sprint": [4], "parry": [5]}
const TOUCH_BTN := {"move": ["move"], "attack": ["fire"], "heavy": ["heavy"], "dash": ["dash"], "sprint": ["move"],
	"parry": ["parry"], "interact": ["interact"]}

var replay := false
var hero
var camera
var hud
var pause_ui
var tc = null
var overlay: Control
var sky_mat: ShaderMaterial

var step := -1
var step_t := 0.0
var idle_t := 0.0
var nice_t := -1.0
var fb_t := 0.0
var fb_line := ""
var sub_t := 0.0
var sub_line := ""
var done := false
var _finish_t := -1.0
var _clock := 0.0

var ring: Node3D
var ring_mat: StandardMaterial3D
var ring_pos := Vector3.ZERO
var dummy = null
var foes: Array = []
var gate: Node3D = null
var combo_hits: Array = []
var dodges := 0
var parries := 0
var sprint_acc := 0.0
var skills_used := [false, false, false]
var _prev_cd := [0.0, 0.0, 0.0]
var kills := 0
var combo_prog := 0          # adım 2 göstergesi: zincirdeki son isabetin sırası + 1
var _hurt_rt := -100.0       # son isabet alınan an (gerçek saat)
var _dodged_rt := -100.0     # son dodged sinyali (gerçek saat)


func _ready() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	GameData.go_load()
	GameData.apply_settings()
	GameData.setup_input()
	Fx.reset()
	Fx.world = self
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	replay = GameData.tutorial_replay
	Sfx.play_music("res://assets/music/akash_chamber.mp3", -9.0)

	_environment()
	_arena()

	camera = CameraScript.new()
	camera.offset = Vector3(9.0, 11.5, 9.0)
	add_child(camera)
	camera.fov = 44.0
	Fx.camera = camera

	hero = HeroScript.new()
	hero.camera = camera
	hero.bound_radius = ARENA_R - 0.4
	hero.parry_mult = 2.0   # parry penceresi yalnızca öğreticide 2 kat (§14.4)
	add_child(hero)
	hero.global_position = Vector3(0, 0, 5.0)
	hero.add_to_group("heroes")
	camera.target = hero
	# ölüm yok: died bağlanmaz; isabet yine hissedilir
	hero.hurt.connect(_on_hero_hurt)
	hero.dodged.connect(_on_dodged)
	hero.parried.connect(_on_parried)

	var layer := CanvasLayer.new()
	add_child(layer)
	hud = CombatHud.new()
	hud.hero = hero
	hud.tutorial_mode = true
	hud.wave_total = 0
	layer.add_child(hud)
	overlay = Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.draw.connect(_draw_overlay)
	layer.add_child(overlay)
	pause_ui = PauseUI.new()
	pause_ui.leave_text = "SKIP TUTORIAL"
	pause_ui.leave.connect(skip)
	layer.add_child(pause_ui)
	if GameData.show_touch():
		tc = load("res://scripts/touch_controls.gd").new()
		tc.hero = hero
		tc.hud = hud
		add_child(tc)
	_aim_moon()
	_begin(0)


# ---------------------------------------------------------------- ortam

func _environment() -> void:
	sky_mat = ShaderMaterial.new()
	sky_mat.shader = preload("res://shaders/cosmic_sky.gdshader")
	var sky := Sky.new()
	sky.sky_material = sky_mat
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.35, 0.4, 0.7)
	env.ambient_light_energy = 0.9
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.glow_enabled = true
	env.glow_intensity = 0.55
	env.glow_strength = 0.9
	env.glow_hdr_threshold = 1.3
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var moon := DirectionalLight3D.new()
	moon.light_color = Color(0.75, 0.8, 1.0)
	moon.light_energy = 0.9
	moon.shadow_enabled = not GameData.is_web()
	moon.rotation_degrees = Vector3(-50, -135, 0)
	add_child(moon)


func _aim_moon() -> void:
	var b: Basis = camera.global_transform.basis
	var d := (-b.z + b.y * 0.34 - b.x * 0.42).normalized()
	sky_mat.set_shader_parameter("moon_dir", d)


func _glow(c: Color, e: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = e
	return m


func _gold() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.95, 0.8, 0.42)
	m.metallic = 0.9
	m.roughness = 0.38
	return m


func _mesh(mesh: Mesh, pos: Vector3, m: Material, parent: Node3D = null) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = m
	(parent if parent != null else self).add_child(mi)
	mi.position = pos
	return mi


## Lacivert-altın yuvarlak gece arenası (Gözlemevi zemini), kenarda altın halka ve sakin ışıklar
func _arena() -> void:
	var top := CylinderMesh.new()
	top.top_radius = ARENA_R + 0.6
	top.bottom_radius = ARENA_R + 0.6
	top.height = 1.0
	top.radial_segments = 96
	var fm := ShaderMaterial.new()
	fm.shader = preload("res://shaders/observatory_floor.gdshader")
	_mesh(top, Vector3(0, -0.5, 0), fm)
	var under := CylinderMesh.new()
	under.top_radius = ARENA_R + 0.6
	under.bottom_radius = 2.0
	under.height = 5.0
	under.radial_segments = 48
	var um := StandardMaterial3D.new()
	um.albedo_color = Color(0.05, 0.06, 0.16)
	um.roughness = 0.8
	_mesh(under, Vector3(0, -3.5, 0), um)
	var edge := TorusMesh.new()
	edge.inner_radius = ARENA_R + 0.45
	edge.outer_radius = ARENA_R + 0.7
	edge.rings = 96
	var em := _gold()
	em.emission_enabled = true
	em.emission = Color(1.0, 0.8, 0.4)
	em.emission_energy_multiplier = 0.6
	var e := _mesh(edge, Vector3(0, 0.02, 0), em)
	e.scale = Vector3(1, 0.3, 1)
	for i in 8:
		var a := TAU * float(i) / 8.0
		var p := Vector3(cos(a), 0, sin(a)) * (ARENA_R + 0.2)
		var post := CylinderMesh.new()
		post.top_radius = 0.12
		post.bottom_radius = 0.2
		post.height = 1.2
		_mesh(post, p + Vector3(0, 0.6, 0), _gold())
		var orb := SphereMesh.new()
		orb.radius = 0.16
		orb.height = 0.32
		_mesh(orb, p + Vector3(0, 1.35, 0), _glow(Color(1.0, 0.85, 0.5), 4.0))
		var l := OmniLight3D.new()
		l.light_color = Color(1.0, 0.85, 0.55)
		l.light_energy = 0.8
		l.omni_range = 5.0
		add_child(l)
		l.position = p + Vector3(0, 1.6, 0)
	# görev halkası (yürü / koş adımları)
	ring = Node3D.new()
	add_child(ring)
	var t := TorusMesh.new()
	t.inner_radius = RING_R - 0.08
	t.outer_radius = RING_R + 0.04
	t.rings = 64
	ring_mat = _glow(Color(1.0, 0.82, 0.4), 3.0)
	var rm := _mesh(t, Vector3(0, 0.05, 0), ring_mat, ring)
	rm.scale = Vector3(1, 0.2, 1)
	var disc := CylinderMesh.new()
	disc.top_radius = RING_R
	disc.bottom_radius = RING_R
	disc.height = 0.02
	var dm := _glow(Color(1.0, 0.8, 0.35), 0.6)
	dm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dm.albedo_color.a = 0.25
	_mesh(disc, Vector3(0, 0.03, 0), dm, ring)
	var rl := OmniLight3D.new()
	rl.light_color = Color(1.0, 0.85, 0.5)
	rl.light_energy = 1.5
	rl.omni_range = 3.5
	ring.add_child(rl)
	rl.position = Vector3(0, 1.0, 0)
	ring.visible = false


func _show_ring(p: Vector3) -> void:
	ring_pos = Vector3(p.x, 0, p.z)
	ring.position = ring_pos
	ring.visible = true
	Juice.ring_wave(self, ring_pos + Vector3(0, 0.2, 0), Color(1.0, 0.85, 0.45), RING_R * 1.6, 0.4)


## Tek altın kapı, üstünde Koç simgesi
func _build_gate() -> void:
	gate = Node3D.new()
	add_child(gate)
	gate.position = GATE_POS
	var gm := _gold()
	for sx: float in [-1.3, 1.3]:
		var pil := CylinderMesh.new()
		pil.top_radius = 0.18
		pil.bottom_radius = 0.24
		pil.height = 3.2
		_mesh(pil, Vector3(sx, 1.6, 0), gm, gate)
	var arch := TorusMesh.new()
	arch.inner_radius = 1.2
	arch.outer_radius = 1.42
	arch.rings = 48
	var am := _mesh(arch, Vector3(0, 3.2, 0), gm, gate)
	am.rotation.x = PI * 0.5
	var veil := QuadMesh.new()
	veil.size = Vector2(2.4, 3.2)
	var vm := _glow(Color(1.0, 0.8, 0.45), 1.6)
	vm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	vm.albedo_color.a = 0.35
	vm.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mesh(veil, Vector3(0, 1.6, 0), vm, gate)
	var glyph := UI.label3d("♈︎", 96, Color(1.0, 0.55, 0.3), 2.5)
	glyph.font = UI.symbol_font()
	glyph.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	glyph.position = Vector3(0, 4.3, 0)
	gate.add_child(glyph)
	var gl := OmniLight3D.new()
	gl.light_color = Color(1.0, 0.8, 0.45)
	gl.light_energy = 2.5
	gl.omni_range = 6.0
	gate.add_child(gl)
	gl.position = Vector3(0, 2.0, 1.0)
	gate.scale = Vector3(0.05, 0.05, 0.05)
	create_tween().tween_property(gate, "scale", Vector3.ONE, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	Fx.flash_light(GATE_POS + Vector3(0, 2, 0), Color(1.0, 0.85, 0.5), 8.0, 8.0, 0.6)
	Sfx.play("coin", -6.0, 0.0, 0, 0.6)


# ---------------------------------------------------------------- adımlar

func _spawn_dummy(p: Vector3) -> void:
	dummy = DummyScript.new()
	dummy.position = p   # _home ağaca girerken alınır
	add_child(dummy)
	dummy.hit_taken.connect(_on_dummy_hit)


func _clear_dummy() -> void:
	if dummy != null and is_instance_valid(dummy):
		dummy.remove_from_group("enemies")
		var d = dummy
		var tw: Tween = d.create_tween()
		tw.tween_property(d, "scale", Vector3(0.05, 0.05, 0.05), 0.3)
		tw.tween_callback(d.queue_free)
		Fx.flash_light(d.global_position + Vector3(0, 1.4, 0), Color(1.0, 0.85, 0.5), 4.0, 5.0, 0.3)
	dummy = null


## Öğretici Gölge (§14.3): bölgesi "tutorial", seçkin değil, özelliksiz, hasarı 0, yavaş, seri 1, düşük can
func _spawn_foe(p: Vector3, only: String, windup: float, min_hp := 0.0) -> void:
	var e = EnemyScript.new()
	e.kind = "shade"
	e.zone = "tutorial"
	e.hero = hero
	e.dmg_mult = 0.0
	e.windup_mult = windup
	e.tut_only = only
	var base := 10.0
	if hero.kit.has("combo"):
		base = float(hero.kit["combo"][0]["dmg"])
	e.tut_hp = maxf(base * (1.0 + float(hero.st["damage"]) / 100.0) * 2.5, 15.0)
	e.tut_min_hp = min_hp
	e._bounds = ARENA_R - 0.5
	add_child(e)
	e.global_position = p
	var to: Vector3 = hero.global_position - p
	to.y = 0.0
	if to.length() > 0.1:
		e._face = to.normalized()
	e.killed.connect(_on_foe_killed)
	e.attack_done.connect(_on_attack_done.bind(e))
	if step == 4 and only == "red":
		for a in e.attacks:
			if not bool(a["parry"]):
				a["cd"] = 2.5   # §14.4: bu adımda kızıl saldırı bekleme süresi 2,5 sn
	foes.append(e)
	Sfx.play("enemyattack", -14.0, 0.1, 120, 1.0)


func _clear_foes() -> void:
	for e in foes:
		if e != null and is_instance_valid(e) and not e.dead:
			e.tut_min_hp = 0.0
			e._die(Vector3.UP)   # yıldız tozuna dağılır (toz düşmez: kimse saymıyor)
	foes.clear()


func _begin(n: int) -> void:
	step = n
	step_t = 0.0
	idle_t = 0.0
	nice_t = -1.0
	sub_t = 0.0
	if hero.max_hp > 0.0:
		hero.heal(hero.max_hp)   # can her adım başında tam
	var act := String(STEPS[n]["act"]) if n < STEPS.size() else ""
	var slots: Array = []
	if HUD_SLOT.has(act):
		slots = HUD_SLOT[act].duplicate()
	hud.tut_slots = slots
	if tc != null:
		tc.highlight = TOUCH_BTN.get(act, []).duplicate()
	match n:
		1:
			_show_ring(Vector3(-3.5, 0, 0.5))
		2:
			combo_hits.clear()
			combo_prog = 0
			_spawn_dummy(Vector3(0, 0, 0))
		3:
			pass
		4:
			_clear_dummy()
			dodges = 0
			_spawn_foe(Vector3(0, 0, -2.5), "red", 1.8, 1.0)
		5:
			sprint_acc = 0.0
			_place_far_ring()
		6:
			parries = 0
			_spawn_foe(Vector3(0, 0, -2.5), "gold", 2.0, 1.0)
		7:
			skills_used = [false, false, false]
			for i in 3:
				_prev_cd[i] = float(hero.skill_cd[i])
			_spawn_dummy(Vector3(0, 0, -2.0))
			_update_skill_slots()
		8:
			_clear_dummy()
			kills = 0
			_spawn_foe(Vector3(-3.0, 0, -3.0), "", 1.8)
			_spawn_foe(Vector3(3.0, 0, -3.0), "", 1.8)
		9:
			_build_gate()


func _place_far_ring() -> void:
	var p: Vector3 = hero.global_position
	p.y = 0.0
	var away := -p.normalized() if p.length() > 1.0 else Vector3(0, 0, -1)
	_show_ring(away * 8.0)


func _update_skill_slots() -> void:
	var s: Array = []
	for i in 3:
		if not bool(skills_used[i]):
			s.append(i)
	hud.tut_slots = s
	if tc != null:
		var b: Array = []
		for i in s:
			b.append("skill_%d" % (int(i) + 1))
		tc.highlight = b


func _progress() -> void:
	idle_t = 0.0


func _success() -> void:
	if nice_t >= 0.0 or done:
		return
	nice_t = 0.0
	ring.visible = false
	hud.tut_slots = []
	if tc != null:
		tc.highlight = []
	var p: Vector3 = hero.global_position + Vector3(0, 1.2, 0)
	Juice.ring_wave(self, p, Color(1.0, 0.85, 0.45), 3.0, 0.4)
	Fx.flash_light(p, Color(1.0, 0.88, 0.55), 6.0, 7.0, 0.4)
	Sfx.play("coin", -4.0, 0.0, 0, 1.2)


func _on_dummy_hit(_dmg: float, _heavy: bool, _crit: bool) -> void:
	if nice_t >= 0.0:
		return
	var kind := String(hero.last_atk_kind)
	if step == 2 and kind == "combo":
		# §14.4 adım 2: kombonun 3. vuruşu (sıra 2) kuklaya değerse biter; zaman penceresi yok
		var idx := int(hero.last_combo_idx)
		combo_prog = idx + 1
		_progress()
		if idx == 2:
			_success()
			return
		# yedek: oyun zamanıyla 2,0 sn içinde 3 kombo isabeti
		var now := _clock
		combo_hits.append(now)
		while not combo_hits.is_empty() and now - float(combo_hits[0]) > 2.0:
			combo_hits.pop_front()
		if combo_hits.size() >= 3:
			_success()
	elif step == 3 and kind == "heavy":
		_success()


func _on_dodged(_parryable: bool) -> void:
	_dodged_rt = Time.get_ticks_msec() / 1000.0


## §14.4 adım 4: kızıl saldırı bitti. (a) kahramanı vurmadı ve (b) hazırlık başından act sonuna kadar atıldı ya da dodged geldiyse 1 başarı
func _on_attack_done(parryable: bool, e) -> void:
	if step != 4 or nice_t >= 0.0 or parryable or e == null or not is_instance_valid(e):
		return
	var t0: float = float(e.windup_t0)
	var now := Time.get_ticks_msec() / 1000.0
	var hit := _hurt_rt >= t0 and _hurt_rt <= now + 0.01
	var dashed: bool = float(hero.last_dash_t) >= t0 or (_dodged_rt >= t0 and _dodged_rt <= now + 0.01)
	if hit or not dashed:
		return
	dodges += 1
	_progress()
	Juice.ring_wave(self, hero.global_position + Vector3(0, 1.0, 0), Color(1.0, 0.5, 0.45), 2.2, 0.3)
	if dodges >= 2:
		_clear_foes()
		_success()


func _on_parried() -> void:
	if step != 6 or nice_t >= 0.0:
		return
	parries += 1
	_progress()
	sub_line = "Parried! It's stunned — strike now"
	sub_t = 2.0
	if parries >= 3:
		for e in foes:
			if e != null and is_instance_valid(e):
				e.tut_min_hp = 0.0


func _on_foe_killed(_e) -> void:
	if step == 6 and parries >= 3:
		_success()
	elif step == 8:
		kills += 1
		_progress()
		if kills >= 2:
			_success()


func _on_hero_hurt() -> void:
	_hurt_rt = Time.get_ticks_msec() / 1000.0
	hud.hurt_flash()
	fb_line = "Press as the gold warning fills" if bool(hero.last_hit_parryable) else "Dash as the red warning fills"
	fb_t = 2.6


# ---------------------------------------------------------------- bitiş / atlama

## Kapıdan geçildi ya da atlandı: bayrak yazılır (tekrar kipinde değil), sonra Koç Geçidi 1. oda / Gözlemevi
func _finish(show_card: bool) -> void:
	if done:
		return
	done = true
	if not replay:
		GameData.tutorial_done = true
		GameData.go_save()
	GameData.tutorial_replay = false
	hud.prompt = ""
	if show_card:
		_finish_t = 0.0
		Sfx.play("dash", -4.0, 0.0, 0, 0.6)
		Fx.shake(0.3)
	else:
		_leave()


func _leave() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(HUB_SCENE if replay else ROOM_SCENE)


## Duraklat menüsündeki ÖĞRETİCİYİ ATLA (onay yok)
func skip() -> void:
	_finish(false)


# ---------------------------------------------------------------- döngü

func _process(delta: float) -> void:
	_clock += delta
	overlay.queue_redraw()
	if _finish_t >= 0.0:
		_finish_t += delta
		if _finish_t > 1.6:
			_finish_t = -10.0
			_leave()
		return
	if done:
		return
	if Input.is_action_just_pressed("pause") and not pause_ui.visible:
		pause_ui.open()
		return
	step_t += delta
	idle_t += delta
	fb_t = maxf(fb_t - delta, 0.0)
	sub_t = maxf(sub_t - delta, 0.0)
	if ring.visible:
		ring_mat.emission_energy_multiplier = 2.5 + 1.2 * sin(_clock * 4.0)
	if nice_t >= 0.0:
		nice_t += delta
		if nice_t >= NICE_TIME:
			_begin(step + 1)
		return
	var hp: Vector3 = hero.global_position
	var flat := Vector2(hp.x - ring_pos.x, hp.z - ring_pos.z).length()
	match step:
		0:
			if step_t >= 2.5:
				_begin(1)
		1:
			if flat < RING_R:
				_success()
		2:
			if int(hero._combo_i) == 0 and String(hero.state) != "attack":
				combo_prog = 0   # zincir boşta sıfırlandı
		5:
			if hero.sprinting:
				sprint_acc += delta
				_progress()
			if flat < RING_R:
				if sprint_acc >= 1.5:
					_success()
				else:
					_place_far_ring()   # koşarak varılmadı: halka öbür uca geçer
		6:
			# Gölge parry'den önce bir şekilde yok olursa yenisi gelir
			_respawn_if_gone("gold", 2.0)
		4:
			_respawn_if_gone("red", 1.8)
		7:
			for i in 3:
				var cd := float(hero.skill_cd[i])
				if cd > float(_prev_cd[i]) + 0.01 and not bool(skills_used[i]):
					skills_used[i] = true
					_progress()
					Sfx.play("coin", -10.0, 0.0, 0, 1.5)
					_update_skill_slots()
				_prev_cd[i] = cd
			if bool(skills_used[0]) and bool(skills_used[1]) and bool(skills_used[2]):
				_success()
		9:
			var gd := Vector2(hp.x - GATE_POS.x, hp.z - GATE_POS.z).length()
			hero.interact_near = gd < 2.8   # E kuralı (GDD §8)
			if gd < 2.8:
				hud.prompt = "THE GATE"
				hud.prompt_glyph = "♈"
				hud.prompt_color = Color(1.0, 0.55, 0.3)
				if Input.is_action_just_pressed("interact"):
					_finish(true)
			else:
				hud.prompt = ""


func _respawn_if_gone(only: String, windup: float) -> void:
	var any := false
	for e in foes:
		if e != null and is_instance_valid(e) and not e.dead:
			any = true
	if not any and not (step == 6 and parries >= 3):
		foes.clear()
		_spawn_foe(Vector3(0, 0, -2.5), only, windup, 1.0)


# ---------------------------------------------------------------- arayüz

func _key(act: String) -> String:
	var mode := GameData.input_mode if KEYS.has(GameData.input_mode) else "mouse"
	return tr(String(KEYS[mode].get(act, "")), CTX)


## Çevrilmemiş tuş adı mı (Shift, Esc, LB…)? Öyleyse büyük harf dönüşümünden muaf çizilir
func _is_key_name(act: String) -> bool:
	var mode := GameData.input_mode if KEYS.has(GameData.input_mode) else "mouse"
	var raw := String(KEYS[mode].get(act, ""))
	return tr(raw, CTX) == raw


func _t(s: String) -> String:
	return tr(s, CTX)


func _text(s: String, pos: Vector2, fsize: int, col: Color, center := true, f: Font = null, key_name := false) -> void:
	var ff := f if f != null else UI.font()
	if key_name:
		# tuş adı (çevrilmemiş: Shift, Esc, WASD…): dilin büyük harf kuralından muaf, İngilizce şekillendirilir
		var tl := TextLine.new()
		tl.add_string(s, ff, fsize, "en")
		var x0 := pos.x - (tl.get_size().x * 0.5 if center else 0.0)
		var top := Vector2(x0, pos.y - tl.get_line_ascent())
		tl.draw_outline(overlay.get_canvas_item(), top, 7, Color(0.02, 0.03, 0.1, 0.9))
		tl.draw(overlay.get_canvas_item(), top, col)
		return
	var w := ff.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize).x
	var x := pos.x - (w * 0.5 if center else 0.0)
	overlay.draw_string_outline(ff, Vector2(x, pos.y), s, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, 7, Color(0.02, 0.03, 0.1, 0.9))
	overlay.draw_string(ff, Vector2(x, pos.y), s, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, col)


func _badge(t: String, center: Vector2, key_name := false) -> void:
	var f := UI.font()
	var fs := 22
	var w := f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + 36.0
	var r := Rect2(center.x - w * 0.5, center.y - 20.0, w, 40.0)
	var pulse := 0.5 + 0.5 * sin(_clock * 5.0)
	overlay.draw_rect(r.grow(4.0 + 2.0 * pulse), Color(1.0, 0.8, 0.4, 0.12 + 0.12 * pulse))
	overlay.draw_rect(r, Color(0.08, 0.1, 0.26, 0.97))
	overlay.draw_rect(r, UI.GOLD, false, 2.0)
	_text(t, Vector2(center.x, center.y + 8.0), fs, UI.CREAM, true, null, key_name)


func _draw_overlay() -> void:
	if step < 0:
		return
	var vs := overlay.get_viewport_rect().size
	var cx := vs.x * 0.5
	var gold := UI.GOLD
	# sağ üst: atla
	var sk := _t("%s: skip") % _key("skip")
	var skw := UI.font().get_string_size(sk, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x
	_text(sk, Vector2(vs.x - 40.0 - skw, 48.0), 18, Color(UI.CREAM.r, UI.CREAM.g, UI.CREAM.b, 0.75), false)

	if _finish_t >= 0.0:
		var a := clampf(_finish_t * 3.0, 0.0, 1.0)
		overlay.draw_rect(Rect2(0, vs.y * 0.3 - 70.0, vs.x, 120.0), Color(0.01, 0.015, 0.05, 0.6 * a))
		_text(_t("TUTORIAL COMPLETE"), Vector2(cx, vs.y * 0.3 + 12.0), 60, Color(gold.r, gold.g, gold.b, a))
		return
	var st: Dictionary = STEPS[step]
	if step == 0:
		# giriş kartı
		var a0 := clampf(step_t * 3.0, 0.0, 1.0) * clampf((2.5 - step_t) * 3.0, 0.0, 1.0)
		overlay.draw_rect(Rect2(0, vs.y * 0.34 - 90.0, vs.x, 170.0), Color(0.01, 0.015, 0.05, 0.65 * a0))
		_text(_t(String(st["title"])), Vector2(cx, vs.y * 0.34 + 4.0), 64, Color(gold.r, gold.g, gold.b, a0))
		_text(_t(String(st["text"])), Vector2(cx, vs.y * 0.34 + 52.0), 26, Color(UI.CREAM.r, UI.CREAM.g, UI.CREAM.b, a0))
		var lw := minf(step_t * 1.6, 1.0) * vs.x * 0.3
		overlay.draw_line(Vector2(cx - lw, vs.y * 0.34 + 72.0), Vector2(cx + lw, vs.y * 0.34 + 72.0), Color(gold.r, gold.g, gold.b, a0), 2.0)
		return

	# üst-orta: başlık, tek satır talimat, tuş rozeti
	var y := 64.0
	var blink := 1.0
	if idle_t > IDLE_HINT:
		blink = 0.35 + 0.65 * (0.5 + 0.5 * sin(_clock * 7.0))
	overlay.draw_rect(Rect2(cx - 520.0, y - 34.0, 1040.0, 92.0), Color(0.01, 0.015, 0.05, 0.55))
	overlay.draw_rect(Rect2(cx - 520.0, y - 34.0, 1040.0, 92.0), Color(gold.r, gold.g, gold.b, 0.35), false, 1.0)
	_text(_t(String(st["title"])), Vector2(cx, y + 4.0), 34, gold)
	_text(_t(String(st["text"])), Vector2(cx, y + 42.0), 22, Color(UI.CREAM.r, UI.CREAM.g, UI.CREAM.b, blink))
	y += 92.0
	var act := String(st["act"])
	if act != "" and GameData.input_mode != "touch":
		_badge(_key(act), Vector2(cx, y), _is_key_name(act))
		y += 50.0
	elif act != "":
		# dokunmatik: rozet yok, ilgili ekran düğmesi parlar; metin yine üst-ortada
		_text(_key(act), Vector2(cx, y + 6.0), 20, gold)
		y += 36.0
	# ilerleme çubuğu: kombo 3, atılma 2, parry 3 (dolu altın bölmeler + sayı)
	if step == 2 or step == 4 or step == 6:
		var need := 2 if step == 4 else 3
		var have := combo_prog if step == 2 else (dodges if step == 4 else parries)
		_pips(mini(have, need), need, cx, y + 6.0, gold)
		y += 40.0
	if step == 4:
		_text(_t("Dash recharges when the ring fills"), Vector2(cx, y + 6.0), 18, Color(UI.CREAM.r, UI.CREAM.g, UI.CREAM.b, 0.85))
		y += 30.0
	elif step == 7:
		# üç yeteneğin adı; kullanılan altınla işaretlenir
		var names: Array = []
		for i in 3:
			names.append(tr(String(hero.kit["skills"][i]["name"])))
		var parts: Array = []
		for i in 3:
			parts.append(("✓ " if bool(skills_used[i]) else "") + String(names[i]))
		var total := 0.0
		var f := UI.font()
		var gap := 48.0
		for p in parts:
			total += f.get_string_size(String(p), HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x
		total += gap * 2.0
		var x := cx - total * 0.5
		overlay.draw_rect(Rect2(x - 18.0, y - 14.0, total + 36.0, 32.0), Color(0.01, 0.015, 0.05, 0.6))
		for i in 3:
			var col: Color = gold if bool(skills_used[i]) else Color(UI.CREAM.r, UI.CREAM.g, UI.CREAM.b, 0.7)
			_text(String(parts[i]), Vector2(x, y + 8.0), 22, col, false)
			x += f.get_string_size(String(parts[i]), HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x + gap
		y += 36.0
	# 20 sn ilerleme yoksa ek ipucu
	if idle_t > IDLE_HINT and nice_t < 0.0:
		var hint := _key(act) if act != "" else ""
		if step == 4:
			hint = _t("Dash as the red warning fills")
		elif step == 6:
			hint = _t("Press as the gold warning fills")
		elif step == 5:
			hint = _t("Hold to sprint to the far circle") + "  ·  " + _key("sprint")
		if hint != "":
			_text(hint, Vector2(cx, y + 8.0), 20, Color(1.0, 0.85, 0.5, blink))
			y += 32.0
	if sub_t > 0.0:
		_text(_t(sub_line), Vector2(cx, y + 10.0), 24, Color(1.0, 0.85, 0.45, clampf(sub_t * 2.0, 0.0, 1.0)))
		y += 34.0
	# vurulunca: tekrar dene
	if fb_t > 0.0:
		var fa := clampf(fb_t * 2.0, 0.0, 1.0)
		_text(_t("They can't hurt you here. Try again."), Vector2(cx, vs.y * 0.62), 22, Color(1.0, 0.6, 0.55, fa))
		_text(_t(fb_line), Vector2(cx, vs.y * 0.62 + 30.0), 20, Color(UI.CREAM.r, UI.CREAM.g, UI.CREAM.b, fa))
	# Güzel!
	if nice_t >= 0.0:
		var na := clampf((NICE_TIME - nice_t) * 4.0, 0.0, 1.0)
		var sc := 1.0 + 0.15 * clampf(1.0 - nice_t * 5.0, 0.0, 1.0)
		_text(_t("Nice!"), Vector2(cx, vs.y * 0.36), int(56.0 * sc), Color(gold.r, gold.g, gold.b, na))


## Öğretici ilerleme çubuğu: `total` bölme, `have` kadarı dolu; ortasında "have / total"
func _pips(have: int, total: int, cx: float, y: float, gold: Color) -> void:
	var w := 64.0
	var h := 14.0
	var gap := 10.0
	var full := w * float(total) + gap * float(total - 1)
	var x := cx - full * 0.5 - 40.0
	overlay.draw_rect(Rect2(x - 10.0, y - h - 6.0, full + 100.0, h + 22.0), Color(0.01, 0.015, 0.05, 0.6))
	for i in total:
		var r := Rect2(x + float(i) * (w + gap), y - h, w, h)
		if i < have:
			overlay.draw_rect(r, gold)
		else:
			overlay.draw_rect(r, Color(gold.r, gold.g, gold.b, 0.15))
		overlay.draw_rect(r, Color(gold.r, gold.g, gold.b, 0.9), false, 1.5)
	_text("%d / %d" % [have, total], Vector2(x + full + 44.0, y - 1.0), 22, gold)
