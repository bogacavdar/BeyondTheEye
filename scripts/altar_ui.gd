extends Control
## SİLAH SUNAĞI
## Run'a hangi kozmik silahla gireceğini seçersin. Kilitli silahlar yıldız tozuyla açılır.

signal closed
signal weapon_chosen(id: String)

const GameData = preload("res://scripts/game_data.gd")
const UI = preload("res://scripts/ui_style.gd")

var _list: VBoxContainer
var _dust: Label


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = UI.theme()
	var bg := ColorRect.new()
	bg.color = Color(0.01, 0.015, 0.05, 0.8)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(cc)
	var p := UI.panel()
	cc.add_child(p)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	p.add_child(vb)
	var t := UI.label("WEAPON ALTAR", 40)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t)
	vb.add_child(UI.divider(320))
	_dust = UI.label("", 18, UI.CREAM)
	_dust.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(_dust)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 10)
	vb.add_child(_list)
	var close := UI.button("CLOSE", 20)
	close.pressed.connect(func(): closed.emit())
	vb.add_child(close)
	refresh()


func _process(_d: float) -> void:
	if visible and Input.is_action_just_pressed("ui_cancel"):
		closed.emit()


func refresh() -> void:
	_dust.text = tr("%d stardust") % GameData.stardust
	for c in _list.get_children():
		c.queue_free()
	for w in GameData.STAR_WEAPONS:
		var id: String = w["id"]
		var open: bool = GameData.weapons_open.has(id)
		var chosen := GameData.chosen_weapon == id
		var status := tr("EQUIPPED") if chosen else (tr("EQUIP") if open else tr("UNLOCK · %d stardust") % int(w["price"]))
		var sk: Array = []
		for s in w["skills"]:
			sk.append(tr(String(s)))
		var b := UI.button("%s\n%s   —   %s\n%s" % [tr(id), tr(String(w["style"])), status, "  ·  ".join(sk)], 18, w["color"] if open else UI.GOLD_DIM)
		b.custom_minimum_size = Vector2(820, 100)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		if chosen:
			b.add_theme_stylebox_override("normal", UI.box(Color(0.14, 0.16, 0.38, 0.95), UI.CREAM, 2))
		b.disabled = (not open) and GameData.stardust < int(w["price"])
		b.pressed.connect(func():
			if not GameData.weapons_open.has(id):
				if not GameData.try_unlock_weapon(id):
					return
			GameData.chosen_weapon = id
			GameData.go_save()
			weapon_chosen.emit(id)
			refresh()
		)
		_list.add_child(b)
