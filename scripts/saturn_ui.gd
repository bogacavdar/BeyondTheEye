extends Control
## SATÜRN DEMİRCİ: burç cevherleriyle silaha mühür işle, mühür tak

const UI = preload("res://scripts/ui_style.gd")
const Aspects = preload("res://scripts/aspects.gd")
const GameData = preload("res://scripts/game_data.gd")

signal closed

var _box: VBoxContainer
const ANVIL := Color(0.95, 0.8, 0.55)

const LINES := [
	"Hm. Another one who thinks a blade is enough. Bring me the ore of the signs you have broken.",
	"Mars iron. Good. Time tests every metal; I only hurry it along.",
	"Your weapon remembers the signs you defeated. I simply teach it to speak.",
]


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
	var p := UI.panel(ANVIL)
	center.add_child(p)
	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 8)
	_box.custom_minimum_size = Vector2(960, 0)
	p.add_child(_box)
	visible = false


func open() -> void:
	_refresh()
	visible = true


func _refresh() -> void:
	for c in _box.get_children():
		c.queue_free()
	var t := UI.label(tr("SATURN THE SMITH"), 36, ANVIL, 5)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_box.add_child(t)
	var forged := 0
	for k in GameData.aspect_lv:
		forged += int(GameData.aspect_lv[k])
	var line := UI.label("“" + tr(LINES[mini(forged, LINES.size() - 1)]) + "”", 18, UI.CREAM, 3)
	line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_box.add_child(line)
	var sub := UI.label(tr("Defeat a sign's boss to earn its ore. Wear one seal; it works with every weapon."), 15, ANVIL, 3)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_box.add_child(sub)
	for a in Aspects.LIST:
		_box.add_child(_row(a))
	var close := UI.button(tr("CLOSE"), 18)
	close.pressed.connect(_close)
	_box.add_child(close)


func _row(a: Dictionary) -> Control:
	var id := String(a["id"])
	var lv := int(GameData.aspect_lv.get(id, 0))
	var ore := int(GameData.ores.get(id, 0))
	var eq := GameData.aspect_eq == id
	var col: Color = a["col"]
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var b := UI.button("", 16, col if lv > 0 else Color(0.45, 0.45, 0.5))
	b.custom_minimum_size = Vector2(720, 62)
	b.disabled = lv <= 0
	var lb := UI.label("", 16, UI.CREAM, 3)
	lb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lb.offset_left = 14
	lb.offset_right = -14
	lb.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if lv > 0:
		lb.text = "%s  %s  ·  %s %d   —   %s%s" % [String(a["glyph"]) + "\uFE0E", tr(String(a["name"])), tr("LV"), lv, Aspects.describe(id, lv), ("   ✓ " + tr("WORN")) if eq else ""]
		lb.add_theme_color_override("font_color", col if eq else UI.CREAM)
	else:
		lb.text = "%s  %s   —   %s" % [String(a["glyph"]) + "\uFE0E", tr(String(a["name"])), Aspects.describe(id, 1)]
		lb.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
	b.add_child(lb)
	b.pressed.connect(func():
		GameData.aspect_eq = "" if eq else id
		GameData.go_save()
		_refresh())
	row.add_child(b)
	var cost := lv + 1
	var fb := UI.button((tr("FORGE") + "  %d/%d " % [ore, cost] + tr(String(a["ore"]))) if lv < 3 else tr("MASTERED"), 14, col)
	fb.custom_minimum_size = Vector2(230, 62)
	fb.disabled = lv >= 3 or ore < cost
	fb.pressed.connect(func():
		GameData.ores[id] = ore - cost
		GameData.aspect_lv[id] = lv + 1
		if lv + 1 >= 3:
			load("res://scripts/achievements.gd").unlock("SEAL_MASTER")
		if GameData.aspect_eq == "":
			GameData.aspect_eq = id
		GameData.go_save()
		Sfx.play("crush", -4.0, 0.0, 0, 0.8)
		_refresh())
	row.add_child(fb)
	return row


func _close() -> void:
	visible = false
	closed.emit()


func _process(_d: float) -> void:
	if visible and Input.is_action_just_pressed("ui_cancel"):
		_close()
