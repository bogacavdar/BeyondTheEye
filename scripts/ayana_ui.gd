extends Control
## AY ANA: Ay Taşı hediye et, tılsım seç

const UI = preload("res://scripts/ui_style.gd")
const Charms = preload("res://scripts/charms.gd")
const GameData = preload("res://scripts/game_data.gd")

signal closed

var _box: VBoxContainer
const MOON := Color(0.78, 0.86, 1.0)


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var bg := ColorRect.new()
	bg.color = Color(0.01, 0.015, 0.05, 0.82)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var p := UI.panel(MOON)
	center.add_child(p)
	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 10)
	_box.custom_minimum_size = Vector2(900, 0)
	p.add_child(_box)
	visible = false


func open() -> void:
	_refresh()
	visible = true


func _refresh() -> void:
	for c in _box.get_children():
		c.queue_free()
	var t := UI.label(tr("MOTHER MOON"), 36, MOON, 5)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_box.add_child(t)
	var bond := GameData.ayana_bond
	var line := UI.label("“" + tr(String(Charms.LINES[mini(bond, Charms.LINES.size() - 1)])) + "”", 19, UI.CREAM, 3)
	line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_box.add_child(line)
	var info := UI.label(tr("Bond: %d / %d   ·   Moonstones: %d") % [bond, Charms.MAX_BOND, GameData.moonstones], 20, MOON, 3)
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_box.add_child(info)
	if bond < Charms.MAX_BOND:
		var give := UI.button(tr("GIVE A MOONSTONE"), 22, MOON)
		give.disabled = GameData.moonstones <= 0
		give.pressed.connect(_give)
		_box.add_child(give)
	var sep := UI.label(tr("CHARMS  —  wear one into each journey"), 18, UI.GOLD, 3)
	sep.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_box.add_child(sep)
	for c in Charms.LIST:
		_box.add_child(_row(c))
	var close := UI.button(tr("CLOSE"), 18)
	close.pressed.connect(_close)
	_box.add_child(close)


func _row(c: Dictionary) -> Control:
	var id := String(c["id"])
	var open_ := GameData.ayana_bond >= int(c["bond"])
	var runs := int(GameData.charm_runs.get(id, 0))
	var lv := Charms.level(runs)
	var eq := GameData.charm_eq == id
	var b := UI.button("", 17, MOON if open_ else Color(0.4, 0.4, 0.45))
	b.custom_minimum_size = Vector2(880, 64)
	b.disabled = not open_
	var lb := UI.label("", 17, UI.CREAM, 3)
	lb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lb.offset_left = 16
	lb.offset_right = -16
	lb.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if open_:
		lb.text = "%s  %s  ·  %s %d   —   %s%s" % [String(c["glyph"]), tr(String(c["name"])), tr("LV"), lv, Charms.describe(id, lv), ("   ✓ " + tr("WORN")) if eq else ""]
		lb.add_theme_color_override("font_color", MOON if eq else UI.CREAM)
	else:
		lb.text = "%s  %s   —   %s" % [String(c["glyph"]), tr(String(c["name"])), tr("Bond %d needed") % int(c["bond"])]
		lb.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
	b.add_child(lb)
	b.pressed.connect(func():
		GameData.charm_eq = "" if eq else id
		GameData.go_save()
		_refresh())
	return b


func _give() -> void:
	if GameData.moonstones <= 0 or GameData.ayana_bond >= Charms.MAX_BOND:
		return
	GameData.moonstones -= 1
	GameData.ayana_bond += 1
	# yeni açılan tılsımı hemen tak (hiç takılı yoksa)
	for c in Charms.LIST:
		if int(c["bond"]) == GameData.ayana_bond and GameData.charm_eq == "":
			GameData.charm_eq = String(c["id"])
	GameData.go_save()
	Sfx.play("coin", -4.0, 0.0, 0, 0.8)
	_refresh()


func _close() -> void:
	visible = false
	closed.emit()


func _process(_d: float) -> void:
	if visible and Input.is_action_just_pressed("ui_cancel"):
		_close()
