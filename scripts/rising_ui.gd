extends Control
## Yükselen seçimi: portala girerken açılır. "Yükselensiz" de seçilebilir.

const UI = preload("res://scripts/ui_style.gd")
const Risings = preload("res://scripts/risings.gd")

signal chosen(id: String)
signal closed

var _box: VBoxContainer


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
	var p := UI.panel()
	center.add_child(p)
	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 10)
	p.add_child(_box)
	visible = false


func open() -> void:
	for c in _box.get_children():
		c.queue_free()
	var t := UI.label(tr("CHOOSE YOUR RISING SIGN"), 34, UI.GOLD, 5)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_box.add_child(t)
	var sub := UI.label(tr("It changes the rules of this run. Defeat a sign's boss to unlock its rising."), 17, UI.CREAM, 3)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_box.add_child(sub)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 10)
	_box.add_child(grid)
	for r in Risings.LIST:
		grid.add_child(_option(r, Risings.unlocked(String(r["id"]))))
	var none := UI.button(tr("NO RISING SIGN"), 20)
	none.pressed.connect(func(): chosen.emit(""))
	_box.add_child(none)
	var back := UI.button(tr("BACK"), 18)
	back.pressed.connect(func(): visible = false; closed.emit())
	_box.add_child(back)
	visible = true


func _option(r: Dictionary, open_: bool) -> Control:
	var b := UI.button("", 18, r["col"])
	b.custom_minimum_size = Vector2(460, 96)
	b.disabled = not open_
	var vb := VBoxContainer.new()
	vb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vb.offset_left = 14
	vb.offset_right = -14
	vb.offset_top = 8
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(vb)
	var head := UI.label(String(r["glyph"]) + "︎  " + tr(String(r["name"])), 22, r["col"] if open_ else Color(0.5, 0.5, 0.55), 4)
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(head)
	var d := UI.label(tr(String(r["desc"])) if open_ else tr("Locked: defeat this sign's boss"), 15, UI.CREAM if open_ else Color(0.55, 0.55, 0.6), 3)
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(d)
	b.pressed.connect(func(): chosen.emit(String(r["id"])))
	return b


func _process(_d: float) -> void:
	if visible and Input.is_action_just_pressed("ui_cancel"):
		visible = false
		closed.emit()
