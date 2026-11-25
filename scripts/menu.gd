extends Node3D
## ANA MENÜ: GÖZÜN ÖTESİ
## Lacivert kozmik gökyüzü ve dolunay; sağda yavaşça dönen altın burç çarkı,
## solda kanal amblemi, başlık ve butonlar.

const GameData = preload("res://scripts/game_data.gd")
const UI = preload("res://scripts/ui_style.gd")
const Loc = preload("res://scripts/loc.gd")
const FlagButton = preload("res://scripts/flag_button.gd")
const SettingsUI = preload("res://scripts/settings_ui.gd")
const HUB_SCENE := "res://scenes/hub.tscn"
const ROMAN := ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X", "XI", "XII"]
## Burç sembolleri (♈ Koç ... ♓ Balık). \uFE0E renkli emoji yerine düz sembol olarak çizilmesini sağlar.
const SIGNS := ["\u2648", "\u2649", "\u264A", "\u264B", "\u264C", "\u264D", "\u264E", "\u264F", "\u2650", "\u2651", "\u2652", "\u2653"]

var cam: Camera3D
var wheel: Node3D
var inner: Node3D
var sky_mat: ShaderMaterial
var t := 0.0
var main_box: VBoxContainer
var settings_panel
var emblem: TextureRect
var flags: Array = []
var slots_box: VBoxContainer
var _del_armed := 0


func _ready() -> void:
	get_window().title = "Beyond The Eye"
	get_tree().paused = false
	Engine.time_scale = 1.0
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	GameData.go_load()
	GameData.apply_settings()
	GameData.setup_input()
	Sfx.play_music("res://assets/music/awakening.mp3", -8.0)
	Fx.reset()
	Fx.world = self

	sky_mat = ShaderMaterial.new()
	sky_mat.shader = preload("res://shaders/cosmic_sky.gdshader")
	sky_mat.set_shader_parameter("moon_dir", Vector3(0.55, 0.32, -1.0))
	sky_mat.set_shader_parameter("moon_size", 0.16)
	var sky := Sky.new()
	sky.sky_material = sky_mat
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.4, 0.45, 0.75)
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.glow_enabled = true
	env.glow_intensity = 0.55
	env.glow_bloom = 0.0
	env.glow_hdr_threshold = 1.3
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var key := DirectionalLight3D.new()
	key.light_color = Color(1.0, 0.92, 0.8)
	key.light_energy = 1.2
	key.rotation_degrees = Vector3(-30, 30, 0)
	add_child(key)

	cam = Camera3D.new()
	cam.fov = 45.0
	cam.position = Vector3(0, 0, 10)
	add_child(cam)
	cam.current = true

	_build_wheel()
	_build_ui()


# ---------------------------------------------------------------- burç çarkı

func _gold() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.95, 0.8, 0.42)
	m.metallic = 1.0
	m.roughness = 0.2
	m.emission_enabled = true
	m.emission = Color(0.95, 0.8, 0.42)
	m.emission_energy_multiplier = 0.25
	return m


func _torus(r: float, w: float, parent: Node3D, m: Material) -> void:
	var tm := TorusMesh.new()
	tm.inner_radius = r - w
	tm.outer_radius = r + w
	tm.rings = 96
	var mi := MeshInstance3D.new()
	mi.mesh = tm
	mi.material_override = m
	mi.rotation.x = PI * 0.5
	parent.add_child(mi)


func _build_wheel() -> void:
	var gold := _gold()
	wheel = Node3D.new()
	wheel.position = Vector3(3.6, 0.1, 0)
	wheel.rotation = Vector3(-0.25, -0.35, 0)
	add_child(wheel)
	inner = Node3D.new()
	wheel.add_child(inner)
	_torus(3.3, 0.04, inner, gold)
	_torus(3.15, 0.015, inner, gold)
	_torus(2.45, 0.03, inner, gold)
	_torus(1.0, 0.03, inner, gold)
	_torus(0.85, 0.012, inner, gold)
	for i in 12:
		var a := TAU * float(i) / 12.0
		var spoke := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.025, 1.45, 0.025)
		spoke.mesh = bm
		spoke.material_override = gold
		spoke.position = Vector3(cos(a) * 1.72, sin(a) * 1.72, 0)
		spoke.rotation.z = a - PI * 0.5
		inner.add_child(spoke)
		var mid := a + TAU / 24.0
		var num := UI.label3d(ROMAN[i], 48, UI.GOLD, 1.6)
		num.position = Vector3(cos(mid) * 2.8, sin(mid) * 2.8, 0.02)
		num.rotation.z = mid - PI * 0.5
		inner.add_child(num)
		var sg := UI.label3d(SIGNS[i] + "\uFE0E", 64, UI.GOLD, 1.3)
		sg.font = UI.symbol_font()
		sg.position = Vector3(cos(mid) * 1.75, sin(mid) * 1.75, 0.02)
		sg.rotation.z = mid - PI * 0.5
		inner.add_child(sg)
		var star := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.04
		sm.height = 0.08
		star.mesh = sm
		star.material_override = Fx.emissive(Color(1.0, 0.9, 0.6), 6.0)
		star.position = Vector3(cos(a) * 3.3, sin(a) * 3.3, 0)
		inner.add_child(star)
	# merkezde parlayan güneş
	var sun := MeshInstance3D.new()
	var s2 := SphereMesh.new()
	s2.radius = 0.35
	s2.height = 0.7
	sun.mesh = s2
	sun.material_override = Fx.emissive(Color(1.0, 0.82, 0.4), 2.0)
	wheel.add_child(sun)
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.85, 0.5)
	l.light_energy = 1.0
	l.omni_range = 8.0
	l.position = Vector3(0, 0, 1.5)
	wheel.add_child(l)


func _process(delta: float) -> void:
	t += delta
	inner.rotation.z += delta * 0.06
	wheel.rotation.y = -0.35 + sin(t * 0.25) * 0.08
	if emblem != null:
		emblem.modulate.a = 0.9 + 0.1 * sin(t * 1.5)
	if Input.is_action_just_pressed("ui_cancel") and (settings_panel.visible or slots_box.visible):
		_show_main()


# ---------------------------------------------------------------- arayüz

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.theme = UI.theme()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)

	var col := VBoxContainer.new()
	col.position = Vector2(150, 70)
	col.custom_minimum_size = Vector2(560, 0)
	col.add_theme_constant_override("separation", 14)
	root.add_child(col)

	emblem = TextureRect.new()
	emblem.texture = load("res://assets/ui/amblem.png")
	emblem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	emblem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	emblem.custom_minimum_size = Vector2(300, 300)
	emblem.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(emblem)

	var title := UI.label("BEYOND THE EYE", 70, UI.GOLD, 0)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(title)
	col.add_child(UI.divider(320))
	var sub := UI.label("LOOK BEYOND THE VISIBLE", 22, UI.GOLD, 0)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(sub)

	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 26)
	col.add_child(gap)

	main_box = VBoxContainer.new()
	main_box.add_theme_constant_override("separation", 14)
	main_box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(main_box)
	if GameData.has_saved_run():
		var b_cont := UI.button("CONTINUE THE JOURNEY", 26)
		b_cont.pressed.connect(_continue_run)
		main_box.add_child(b_cont)
	var b_go := UI.button("BEGIN THE JOURNEY", 26)
	b_go.pressed.connect(_show_slots)
	main_box.add_child(b_go)
	var b_set := UI.button("SETTINGS")
	b_set.pressed.connect(_show_settings)
	main_box.add_child(b_set)
	var b_quit := UI.button("QUIT")
	b_quit.pressed.connect(func(): get_tree().quit())
	main_box.add_child(b_quit)

	var ver := UI.label("v0.5 · early prototype", 15, UI.GOLD_DIM)
	ver.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	ver.offset_left = -230.0
	ver.offset_top = -44.0
	root.add_child(ver)

	# dil seçimi: sağ üstte iki bayrak
	var fl := HBoxContainer.new()
	fl.add_theme_constant_override("separation", 22)
	fl.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	fl.offset_left = -220.0
	fl.offset_top = 36.0
	root.add_child(fl)
	for code in ["tr", "en"]:
		var f = FlagButton.new(code)
		f.selected = GameData.lang == code
		f.picked.connect(_set_lang)
		fl.add_child(f)
		flags.append(f)

	slots_box = VBoxContainer.new()
	slots_box.add_theme_constant_override("separation", 12)
	slots_box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(slots_box)

	settings_panel = _build_settings()
	root.add_child(settings_panel)
	_show_main()


func _build_settings() -> Control:
	var st := SettingsUI.new()
	st.closed.connect(_show_main)
	return st


## Yarım kalan run'a kaldığı odadan devam et
func _continue_run() -> void:
	GameData.resume_run()
	get_tree().change_scene_to_file("res://scenes/room.tscn")


func _set_lang(code: String) -> void:
	GameData.lang = code
	Loc.set_lang(code)
	GameData.go_save()
	for f in flags:
		f.selected = f.code == code
	Sfx.play("switch", -12.0, 0.0, 0, 1.2)


func _show_main() -> void:
	main_box.visible = true
	settings_panel.visible = false
	slots_box.visible = false
	for f in flags:
		f.selected = f.code == GameData.lang
	GameData.go_save()


func _show_settings() -> void:
	main_box.visible = false
	slots_box.visible = false
	settings_panel.refresh()
	settings_panel.visible = true


# ---------------------------------------------------------------- kayıt yuvaları

func _show_slots() -> void:
	main_box.visible = false
	settings_panel.visible = false
	slots_box.visible = true
	_del_armed = 0
	_build_slots()


func _build_slots() -> void:
	for c in slots_box.get_children():
		c.queue_free()
	var head := UI.label("CHOOSE A JOURNEY", 26, UI.GOLD, 2)
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	slots_box.add_child(head)
	for n in range(1, GameData.SLOT_COUNT + 1):
		slots_box.add_child(_slot_row(n))
	var back := UI.button("BACK", 20)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(_show_main)
	slots_box.add_child(back)


func _slot_row(n: int) -> Control:
	var info: Dictionary = GameData.slot_summary(n)
	var p := UI.panel()
	p.custom_minimum_size = Vector2(560, 0)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	p.add_child(row)
	var txt := VBoxContainer.new()
	txt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(txt)
	txt.add_child(UI.label(tr("JOURNEY") + " " + ROMAN[n - 1], 22, UI.GOLD, 2))
	if info.is_empty():
		txt.add_child(UI.label("EMPTY", 15, UI.GOLD_DIM))
	else:
		var line := "%s %d  ·  %s %d  ·  %s %d" % [tr("DUST"), int(info["dust"]), tr("STARS"), int(info["stars"]),
			tr("WEAPONS"), int(info["weapons"])]
		txt.add_child(UI.label(line, 15, UI.CREAM))
		var extra := tr("ARIES DEFEATED") if bool(info["aries"]) else ""
		if bool(info.get("taurus", false)):
			extra = tr("ARIES & TAURUS DEFEATED")
		if bool(info.get("gemini", false)):
			extra = tr("ARIES, TAURUS & GEMINI DEFEATED")
		if bool(info.get("cancer", false)):
			extra = tr("FOUR CONSTELLATIONS RESTORED")
		if bool(info.get("leo", false)):
			extra = tr("FIVE CONSTELLATIONS RESTORED")
		if bool(info.get("virgo", false)):
			extra = tr("SIX CONSTELLATIONS RESTORED")
		if bool(info.get("libra", false)):
			extra = tr("SEVEN CONSTELLATIONS RESTORED")
		if int(info["run_room"]) >= 0:
			extra += ("  ·  " if extra != "" else "") + tr("RUN IN PROGRESS") + " (%d)" % (int(info["run_room"]) + 1)
		if extra != "":
			txt.add_child(UI.label(extra, 14, UI.GOLD_DIM))
	var btns := VBoxContainer.new()
	btns.add_theme_constant_override("separation", 6)
	row.add_child(btns)
	if not info.is_empty() and int(info["run_room"]) >= 0:
		var bc := UI.button("CONTINUE", 18)
		bc.pressed.connect(func():
			GameData.select_slot(n)
			_continue_run())
		btns.add_child(bc)
	var bp := UI.button("NEW JOURNEY" if info.is_empty() else "OBSERVATORY", 18)
	bp.pressed.connect(func():
		GameData.select_slot(n)
		get_tree().change_scene_to_file(HUB_SCENE))
	btns.add_child(bp)
	if not info.is_empty():
		var bd := UI.button("DELETE" if _del_armed != n else "SURE? DELETE", 15, Color(1.0, 0.45, 0.4))
		bd.pressed.connect(func():
			if _del_armed == n:
				GameData.delete_slot(n)
				_del_armed = 0
			else:
				_del_armed = n
			Sfx.play("switch", -12.0, 0.0, 0, 0.9)
			_build_slots())
		btns.add_child(bd)
	return p
