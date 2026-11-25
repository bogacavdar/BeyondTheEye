extends Node3D
## OYUN SAHNESİ (scenes/game.tscn)
## Menüde seçilen haritayı, ışıkları, oyuncuyu, kamerayı, arayüzü kurar ve mutant dalgalarını doğurur.
## Esc: duraklat | Ölünce R: yeniden, M: ana menü

const GameData = preload("res://scripts/game_data.gd")
const MENU_SCENE := "res://scenes/main.tscn"
const PlayerScript = preload("res://scripts/player.gd")
const ZombieScript = preload("res://scripts/zombie.gd")
const CameraScript = preload("res://scripts/camera_rig.gd")
const HudScript = preload("res://scripts/hud.gd")
const PickupScript = preload("res://scripts/pickup.gd")
const CityScript = preload("res://scripts/city.gd")
const NavScript = preload("res://scripts/nav.gd")
const BossScript = preload("res://scripts/boss.gd")

const MAX_ZOMBIES := 150

## Mutant türüne göre düşen kredi çipi sayısı
const CREDIT_DROPS := {"normal": 1, "fast": 2, "armored": 4, "bloater": 2, "spider": 1, "boss": 30}

var player: CharacterBody3D
var camera: Camera3D
var hud
var city
var nav
var rng := RandomNumberGenerator.new()
var elapsed := 0.0
var spawn_timer := 1.0
var kills := 0
var game_over := false
var credits := 0
var _credit_streak := 0
var _last_credit_ms := 0
var _nav_timer := 0.0
var _spawn_cells: Array = []
var _credit_acc := 0.0
var map_info: Dictionary = {}
var boss_time := 300.0
var boss = null
var boss_spawned := false
var victory := false
var _warned := false


func _ready() -> void:
	rng.randomize()
	add_to_group("game")
	Fx.reset()
	Fx.world = self
	Engine.time_scale = 1.0
	get_tree().paused = false
	GameData.load_game()
	GameData.apply_settings()
	map_info = GameData.map_info(GameData.selected_map)
	boss_time = float(map_info.get("boss_time", 300.0))
	_setup_input()
	GameData.build_environment(self)

	nav = NavScript.new()
	nav.setup(-62.0, -62.0, 124.0, 124.0, 2.0)
	# Harita seçimi: şimdilik tek harita var (Neon Şehir). Yeni haritalar buraya eklenecek.
	match GameData.selected_map:
		_:
			city = CityScript.new()
	add_child(city)
	city.build(nav)

	camera = CameraScript.new()
	add_child(camera)
	Fx.camera = camera

	player = PlayerScript.new()
	player.name = "Player"
	player.set("camera", camera)
	add_child(player)
	player.global_position = Vector3.ZERO
	camera.set("target", player)
	city.player = player
	player.connect("died", _on_player_died)
	player.connect("hp_changed", _on_player_hp_changed)
	player.connect("weapon_changed", _on_weapon_changed)
	nav.update(player.global_position)
	_spawn_cells = nav.cells_in_range(9, 22)

	hud = HudScript.new()
	add_child(hud)
	hud.pause_toggled.connect(_toggle_pause)
	hud.menu_requested.connect(_go_menu)
	hud.set_hp(player.get("hp"), player.get("max_hp"))
	hud.set_kills(0)
	hud.set_credits(0)
	hud.set_time(0.0)
	hud.set_weapon(player.call("current_weapon_name"))

	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN


# ---------------------------------------------------------------- kontroller

func _setup_input() -> void:
	_action_keys("move_up", [KEY_W, KEY_UP])
	_action_keys("move_down", [KEY_S, KEY_DOWN])
	_action_keys("move_left", [KEY_A, KEY_LEFT])
	_action_keys("move_right", [KEY_D, KEY_RIGHT])
	_action_keys("dash", [KEY_SPACE, KEY_SHIFT])
	var nums := [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8]
	for i in nums.size():
		_action_keys("weapon_%d" % (i + 1), [nums[i]])
	_action_keys("restart", [KEY_R])
	_action_keys("menu", [KEY_M])
	_action_keys("pause", [KEY_ESCAPE, KEY_P])
	_action_mouse("fire", MOUSE_BUTTON_LEFT)
	_action_mouse("weapon_next", MOUSE_BUTTON_WHEEL_DOWN)
	_action_mouse("weapon_prev", MOUSE_BUTTON_WHEEL_UP)


func _action_keys(action: String, keys: Array) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action)
	for k in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		InputMap.action_add_event(action, ev)


func _action_mouse(action: String, button: MouseButton) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action)
	var mb := InputEventMouseButton.new()
	mb.button_index = button
	InputMap.action_add_event(action, mb)


# ---------------------------------------------------------------- oyun döngüsü

func _process(delta: float) -> void:
	if game_over:
		if Input.is_action_just_pressed("restart"):
			Engine.time_scale = 1.0
			get_tree().reload_current_scene()
		elif Input.is_action_just_pressed("menu"):
			_go_menu()
		return

	elapsed += delta
	hud.set_time(elapsed)

	_nav_timer -= delta
	if _nav_timer <= 0.0:
		_nav_timer = 0.2
		nav.update(player.global_position)
		_spawn_cells = nav.cells_in_range(9, 22)

	# boss geri sayımı
	if not boss_spawned:
		hud.set_boss_timer(maxf(boss_time - elapsed, 0.0))
		if not _warned and elapsed > boss_time - 10.0:
			_warned = true
			hud.warn("UYARI: KOVAN ANASI YAKLAŞIYOR")
			Sfx.play("roar", -6.0, 0.0, 0, 0.8)
		if elapsed >= boss_time:
			_spawn_boss()

	spawn_timer -= delta
	if spawn_timer <= 0.0:
		spawn_timer = maxf(0.8 - elapsed * 0.008, 0.15)
		if boss_spawned:
			spawn_timer *= 2.5  # boss savaşında kalabalık azalır
		elif elapsed > boss_time - 12.0:
			return  # boss gelmeden önce kısa bir sessizlik
		var count := 1 + int(minf(elapsed, boss_time) / 35.0)
		for i in count:
			_spawn_group()


## Bir doğurma noktasında mutant (örümcekse sürü) doğurur.
func _spawn_group() -> void:
	var alive := get_tree().get_nodes_in_group("zombies").size()
	if alive >= MAX_ZOMBIES or _spawn_cells.is_empty():
		return
	var pos := Vector3.ZERO
	var ok := false
	for attempt in 6:
		pos = _spawn_cells[rng.randi() % _spawn_cells.size()]
		if pos.distance_to(player.global_position) > 15.0:
			ok = true
			break
	if not ok:
		return

	var kind := "normal"
	var r := rng.randf()
	if elapsed > 45.0 and r < 0.08:
		kind = "bloater"
	elif elapsed > 25.0 and r < 0.18:
		kind = "armored"
	elif elapsed > 15.0 and r < 0.3:
		kind = "spider"
	elif elapsed > 5.0 and r < 0.52:
		kind = "fast"

	var n := 1
	if kind == "spider":
		n = rng.randi_range(3, 5)
	for i in n:
		if alive + i >= MAX_ZOMBIES:
			break
		var z = ZombieScript.new()
		z.setup(kind, player, nav)
		add_child(z)
		z.global_position = pos + Vector3(rng.randf_range(-1.2, 1.2), 0, rng.randf_range(-1.2, 1.2))
		z.killed.connect(_on_zombie_killed)


## Boss saldırısı: belirtilen yerde mutant doğurur.
func spawn_minion(kind: String, pos: Vector3, n: int) -> void:
	for i in n:
		if get_tree().get_nodes_in_group("zombies").size() >= MAX_ZOMBIES + 20:
			return
		var z = ZombieScript.new()
		z.setup(kind, player, nav)
		add_child(z)
		z.global_position = Vector3(pos.x + rng.randf_range(-1.5, 1.5), 0.0, pos.z + rng.randf_range(-1.5, 1.5))
		z.killed.connect(_on_zombie_killed)


func _spawn_boss() -> void:
	boss_spawned = true
	var pos := player.global_position + Vector3(20, 0, 0)
	var best := -1.0
	for c in _spawn_cells:
		var d: float = (c as Vector3).distance_to(player.global_position)
		if d > 16.0 and d < 30.0 and (best < 0.0 or absf(d - 22.0) < best):
			best = absf(d - 22.0)
			pos = c
	boss = BossScript.new()
	boss.setup("boss", player, nav)
	add_child(boss)
	boss.global_position = pos
	boss.killed.connect(_on_zombie_killed)
	hud.show_boss("KOVAN ANASI")


func _on_zombie_killed(z) -> void:
	kills += 1
	hud.set_kills(kills)
	var n: int = CREDIT_DROPS.get(z.kind, 1)
	var pos: Vector3 = z.global_position + Vector3(0, 1.0, 0)
	for i in n:
		var c = PickupScript.new()
		c.target = player
		if z.kind == "boss":
			c.value = 2
			c.magnet = true
		add_child(c)
		c.global_position = pos + Vector3(0, 1.0, 0) if z.kind == "boss" else pos
	if z.kind == "boss":
		_on_boss_killed()


func _on_boss_killed() -> void:
	victory = true
	var reward := int(map_info.get("boss_reward", 60))
	get_tree().create_timer(4.0).timeout.connect(func():
		if not is_inside_tree():
			return
		game_over = true
		_credit_acc += reward
		credits = int(_credit_acc)
		hud.set_credits(credits)
		GameData.end_run(credits, true, GameData.selected_map)
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		hud.show_victory(kills, elapsed, credits, reward, GameData.bank)
	)


## Kredi çipi toplandığında çağrılır. Art arda toplarken ses her seferinde biraz incelir.
func on_credit(value: int) -> void:
	if game_over:
		return
	_credit_acc += value * GameData.credit_mult()
	credits = int(_credit_acc)
	hud.set_credits(credits)
	var now := Time.get_ticks_msec()
	_credit_streak = _credit_streak + 1 if now - _last_credit_ms < 450 else 0
	_last_credit_ms = now
	Sfx.play("coin", -10.0, 0.0, 0, 1.0 + minf(_credit_streak, 14) * 0.05)


func _on_player_hp_changed(hp: float, max_hp: float) -> void:
	hud.set_hp(hp, max_hp)
	hud.flash_damage()


func _on_weapon_changed(n: String) -> void:
	hud.set_weapon(n)


func _on_player_died() -> void:
	if victory and game_over:
		return
	game_over = true
	GameData.end_run(credits, false, GameData.selected_map)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	hud.show_game_over(kills, elapsed, credits, GameData.bank)


# ---------------------------------------------------------------- duraklatma ve menü

func _toggle_pause() -> void:
	if game_over:
		return
	var p := not get_tree().paused
	get_tree().paused = p
	Engine.time_scale = 1.0
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if p else Input.MOUSE_MODE_HIDDEN
	hud.show_pause(p)


func _go_menu() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	get_tree().change_scene_to_file(MENU_SCENE)
