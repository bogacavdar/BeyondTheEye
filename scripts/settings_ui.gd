extends CenterContainer
## AYARLAR paneli (ana menüde ve oyun içi duraklatma menüsünde aynı panel kullanılır)
## Ana ses, müzik, efektler ayrı ayrı; ekran sarsıntısı, tam ekran ve dil seçimi.
## Her değişiklik anında uygulanır, panel kapanınca kaydedilir.

signal closed

const GameData = preload("res://scripts/game_data.gd")
const UI = preload("res://scripts/ui_style.gd")
const Loc = preload("res://scripts/loc.gd")
const FlagButton = preload("res://scripts/flag_button.gd")

var _flags: Array = []
var _mute: CheckButton
var _reset_btn: Button
var _reset_armed := false
var _controls: Control
var _main: Control


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = UI.theme()
	var p := UI.panel()
	add_child(p)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	vb.custom_minimum_size = Vector2(620, 0)
	p.add_child(vb)
	_main = vb
	var t1 := UI.label("SETTINGS", 40)
	t1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t1)
	vb.add_child(UI.divider(260))

	_slider(vb, "Master volume", GameData.volume, 1.0, _on_master)
	_slider(vb, "Music", GameData.music_volume, 1.0, _on_music)
	_slider(vb, "Effects", GameData.sfx_volume, 1.0, _on_sfx)
	_slider(vb, "Screen shake", GameData.shake_mult, 1.5, _on_shake)

	_mute = _check(vb, "Mute music (M)", GameData.music_muted, _on_mute)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 30)
	vb.add_child(grid)
	_check(grid, "Fullscreen", GameData.fullscreen, _on_fullscreen)
	_check(grid, "VSync", GameData.vsync, _on_vsync)
	_check(grid, "Damage numbers", GameData.dmg_numbers, _on_numbers)
	var fps_row := HBoxContainer.new()
	fps_row.add_theme_constant_override("separation", 12)
	grid.add_child(fps_row)
	fps_row.add_child(UI.label("FPS limit", 18, UI.CREAM))
	var fps := OptionButton.new()
	fps.focus_mode = Control.FOCUS_NONE
	var opts := [0, 30, 60, 120, 144, 240]
	for o in opts:
		fps.add_item(tr("Unlimited") if int(o) == 0 else str(o), int(o))
	fps.select(maxi(opts.find(GameData.max_fps), 0))
	fps.item_selected.connect(_on_fps.bind(fps))
	fps_row.add_child(fps)
	# grafik kalitesi: düşük (zayıf cihazlar), orta, yüksek (sis, ışık hüzmeleri, yansımalar, tehlike ışıkları)
	var gq_row := HBoxContainer.new()
	gq_row.add_theme_constant_override("separation", 12)
	grid.add_child(gq_row)
	gq_row.add_child(UI.label("Graphics", 18, UI.CREAM))
	var gq := OptionButton.new()
	gq.focus_mode = Control.FOCUS_NONE
	for o in ["Low", "Medium", "High"]:
		gq.add_item(tr(o))
	gq.select(clampi(GameData.gfx_quality, 0, 2))
	gq.item_selected.connect(func(i: int):
		GameData.gfx_quality = i
		GameData.go_save())
	gq_row.add_child(gq)
	gq_row.add_child(UI.label(tr("(next room)"), 14, Color(0.7, 0.7, 0.78)))

	vb.add_child(UI.label("Language", 20, UI.CREAM))
	var fl := HBoxContainer.new()
	fl.add_theme_constant_override("separation", 26)
	fl.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_child(fl)
	for code in ["tr", "en"]:
		var f = FlagButton.new(code)
		f.selected = GameData.lang == code
		f.picked.connect(_set_lang)
		fl.add_child(f)
		_flags.append(f)

	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 6)
	vb.add_child(gap)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	vb.add_child(row)
	var ctl := UI.button("CONTROLS", 18)
	ctl.pressed.connect(_show_controls)
	row.add_child(ctl)
	_reset_btn = UI.button("RESET PROGRESS", 18, Color(1.0, 0.5, 0.4))
	_reset_btn.pressed.connect(_on_reset)
	row.add_child(_reset_btn)
	var back := UI.button("BACK")
	back.pressed.connect(_close)
	vb.add_child(back)

	# kontroller listesi (ayrı panel)
	_controls = _build_controls()
	_controls.visible = false
	p.add_child(_controls)


func _on_master(v: float) -> void:
	GameData.volume = v
	GameData.apply_settings()


func _on_music(v: float) -> void:
	GameData.music_volume = v
	GameData.apply_settings()


func _on_sfx(v: float) -> void:
	GameData.sfx_volume = v
	GameData.apply_settings()
	Sfx.play("coin", -10.0, 0.0, 120)


func _on_shake(v: float) -> void:
	GameData.shake_mult = v


func _on_fullscreen(on: bool) -> void:
	GameData.fullscreen = on
	GameData.apply_settings()


func _on_vsync(on: bool) -> void:
	GameData.vsync = on
	GameData.apply_settings()


func _on_numbers(on: bool) -> void:
	GameData.dmg_numbers = on


func _on_mute(on: bool) -> void:
	GameData.music_muted = on
	GameData.apply_settings()


func _on_fps(idx: int, ob: OptionButton) -> void:
	GameData.max_fps = ob.get_item_id(idx)
	GameData.apply_settings()


## İlerlemeyi sıfırla: ilk basış uyarır, ikinci basış sıfırlar
func _on_reset() -> void:
	if not _reset_armed:
		_reset_armed = true
		_reset_btn.text = tr("ARE YOU SURE? PRESS AGAIN")
		return
	GameData.reset_progress()
	_reset_armed = false
	_reset_btn.text = tr("PROGRESS RESET")
	Sfx.play("heavyhit", -8.0, 0.0, 0, 0.8)


func _check(parent: Control, title: String, on: bool, cb: Callable) -> CheckButton:
	var c := CheckButton.new()
	c.text = title
	c.add_theme_color_override("font_color", UI.CREAM)
	c.add_theme_font_size_override("font_size", 18)
	c.button_pressed = on
	c.focus_mode = Control.FOCUS_NONE
	c.toggled.connect(cb)
	parent.add_child(c)
	return c


func _build_controls() -> Control:
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	vb.custom_minimum_size = Vector2(620, 0)
	var t := UI.label("CONTROLS", 34)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t)
	vb.add_child(UI.divider(260))
	var rows := [
		["WASD", "Move"], ["Space", "Dash (dodges red warnings)"], ["Hold Space", "Sprint"],
		["Left click", "Attack combo"], ["Right click / F", "Heavy attack"], ["Shift / mouse side", "Parry (gold warnings)"],
		["Q / E / R", "Skills (1-2-3 also work)"], ["E", "Interact / doors"], ["M", "Music on / off"], ["Esc", "Pause"],
	]
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 40)
	grid.add_theme_constant_override("v_separation", 6)
	vb.add_child(grid)
	for r in rows:
		grid.add_child(UI.label(String(r[0]), 20, UI.GOLD))
		grid.add_child(UI.label(String(r[1]), 18, UI.CREAM))
	var back := UI.button("BACK")
	back.pressed.connect(_hide_controls)
	vb.add_child(back)
	return vb


func _show_controls() -> void:
	_main.visible = false
	_controls.visible = true


func _hide_controls() -> void:
	_controls.visible = false
	_main.visible = true


func _slider(parent: Control, title: String, value: float, max_v: float, cb: Callable) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	parent.add_child(row)
	var l := UI.label(title, 20, UI.CREAM)
	l.custom_minimum_size = Vector2(220, 0)
	row.add_child(l)
	var s := HSlider.new()
	s.min_value = 0.0
	s.max_value = max_v
	s.step = 0.05
	s.value = value
	s.custom_minimum_size = Vector2(320, 30)
	s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	s.focus_mode = Control.FOCUS_NONE
	s.value_changed.connect(cb)
	row.add_child(s)


func _set_lang(code: String) -> void:
	GameData.lang = code
	Loc.set_lang(code)
	for f in _flags:
		f.selected = f.code == code
	Sfx.play("switch", -12.0, 0.0, 0, 1.2)


func refresh() -> void:
	for f in _flags:
		f.selected = f.code == GameData.lang
	if _mute != null:
		_mute.set_pressed_no_signal(GameData.music_muted)
	_reset_armed = false
	if _reset_btn != null:
		_reset_btn.text = tr("RESET PROGRESS")
	if _controls != null:
		_hide_controls()


func _close() -> void:
	GameData.go_save()
	closed.emit()


func _process(_d: float) -> void:
	if visible and Input.is_action_just_pressed("ui_cancel"):
		if _controls != null and _controls.visible:
			_hide_controls()
		else:
			_close()
