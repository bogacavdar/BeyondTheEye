extends Control
## DURAKLATMA MENÜSÜ (Esc): oyunu durdurur.
## DEVAM ET · AYARLAR · (çıkış: Gözlemevine dön / Ana menü) · OYUNDAN ÇIK

signal leave

const UI = preload("res://scripts/ui_style.gd")
const SettingsUI = preload("res://scripts/settings_ui.gd")

var leave_text := "MAIN MENU"
var _box: Control
var _settings
var _opened_frame := -1


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = UI.theme()
	visible = false
	var bg := ColorRect.new()
	bg.color = Color(0.01, 0.015, 0.05, 0.75)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var cc := CenterContainer.new()
	cc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(cc)
	_box = UI.panel()
	cc.add_child(_box)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	vb.custom_minimum_size = Vector2(460, 0)
	_box.add_child(vb)
	var t := UI.label("PAUSED", 44)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t)
	vb.add_child(UI.divider(240))
	var b_res := UI.button("RESUME", 24)
	b_res.pressed.connect(close)
	vb.add_child(b_res)
	var b_set := UI.button("SETTINGS", 24)
	b_set.pressed.connect(_open_settings)
	vb.add_child(b_set)
	var b_leave := UI.button(leave_text, 24)
	b_leave.pressed.connect(_on_leave)
	vb.add_child(b_leave)
	var b_quit := UI.button("QUIT GAME", 24)
	b_quit.pressed.connect(_on_quit)
	vb.add_child(b_quit)

	_settings = SettingsUI.new()
	_settings.visible = false
	_settings.closed.connect(_on_settings_closed)
	add_child(_settings)


func _on_leave() -> void:
	get_tree().paused = false
	leave.emit()


func _on_quit() -> void:
	get_tree().quit()


func _on_settings_closed() -> void:
	_settings.visible = false
	_box.visible = true
	_opened_frame = Engine.get_process_frames()


func open() -> void:
	visible = true
	_box.visible = true
	_settings.visible = false
	_opened_frame = Engine.get_process_frames()
	get_tree().paused = true
	Sfx.play("switch", -12.0, 0.0, 0, 0.8)


func close() -> void:
	visible = false
	get_tree().paused = false


func _open_settings() -> void:
	_box.visible = false
	_settings.refresh()
	_settings.visible = true


func _process(_d: float) -> void:
	if not visible or Engine.get_process_frames() == _opened_frame:
		return
	if _settings.visible:
		return   # ayarlar paneli kendi Esc'sini yönetir
	if Input.is_action_just_pressed("pause") or Input.is_action_just_pressed("ui_cancel"):
		close()
