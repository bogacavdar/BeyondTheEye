extends CanvasLayer
## DOKUNMATİK KONTROLLER (telefon/tablet)
## Sol yarıda yüzen sanal çubuk (dokunduğun yer merkez olur), sağda saldırı kümesi.
## Nişan otomatik: en yakın düşmana döner (hero._pad_aim).
## Her düğme bir giriş eylemine basar/bırakır; böylece oyunun geri kalanı klavyeyle aynı şekilde çalışır.

const UI = preload("res://scripts/ui_style.gd")

var hub_mode := false          # gözlemevi: saldırı yerine etkileşim düğmesi
var hero = null                # bekleme sürelerini göstermek için

var _view: Control
var _buttons: Array = []       # [{action, label, pos, r, sub}]
var _touch := {}               # parmak no -> düğme indeksi ya da -1 (çubuk)
var _stick_idx := -999
var _stick_c := Vector2.ZERO
var _stick_v := Vector2.ZERO
var _pressed := {}             # düğme indeksi -> true


func _ready() -> void:
	layer = 40
	_view = Control.new()
	_view.set_anchors_preset(Control.PRESET_FULL_RECT)
	_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_view.draw.connect(_draw_view)
	add_child(_view)
	get_viewport().size_changed.connect(_layout)
	_layout()


func _layout() -> void:
	var s := _view.get_viewport_rect().size
	var W := s.x
	var H := s.y
	_buttons.clear()
	if hub_mode:
		_buttons.append({"action": "interact", "label": "E", "pos": Vector2(W - 210, H - 220), "r": 105.0, "sub": "USE"})
		_buttons.append({"action": "dash", "label": "»", "pos": Vector2(W - 420, H - 130), "r": 78.0, "sub": "DASH"})
		_buttons.append({"action": "sprint", "label": "»»", "pos": Vector2(W - 150, H - 450), "r": 66.0, "sub": "RUN"})
	else:
		_buttons.append({"action": "fire", "label": "⚔", "pos": Vector2(W - 210, H - 210), "r": 110.0, "sub": "ATTACK"})
		_buttons.append({"action": "heavy", "label": "Q", "pos": Vector2(W - 430, H - 120), "r": 72.0, "sub": "HEAVY"})
		_buttons.append({"action": "dash", "label": "»", "pos": Vector2(W - 150, H - 440), "r": 76.0, "sub": "DASH"})
		_buttons.append({"action": "parry", "label": "◈", "pos": Vector2(W - 400, H - 330), "r": 72.0, "sub": "PARRY"})
		_buttons.append({"action": "skill_1", "label": "1", "pos": Vector2(W - 610, H - 170), "r": 58.0, "sub": "", "skill": 0})
		_buttons.append({"action": "skill_2", "label": "2", "pos": Vector2(W - 590, H - 360), "r": 58.0, "sub": "", "skill": 1})
		_buttons.append({"action": "skill_3", "label": "3", "pos": Vector2(W - 420, H - 520), "r": 58.0, "sub": "", "skill": 2})
	_buttons.append({"action": "pause", "label": "II", "pos": Vector2(W - 70, 170), "r": 48.0, "sub": ""})
	_view.queue_redraw()


func _process(_d: float) -> void:
	_view.queue_redraw()


func _input(event: InputEvent) -> void:
	if get_tree().paused and not (event is InputEventScreenTouch and not event.pressed):
		# menüler açıkken dokunuşlar düğmelere gitsin (bırakmalar yine işlenir)
		return
	if event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed:
			var bi := _button_at(st.position)
			if bi >= 0:
				_touch[st.index] = bi
				_press(bi)
			elif st.position.x < _view.get_viewport_rect().size.x * 0.45 and _stick_idx == -999:
				_touch[st.index] = -1
				_stick_idx = st.index
				_stick_c = st.position
				_stick_v = Vector2.ZERO
		else:
			if _touch.has(st.index):
				var bi2: int = _touch[st.index]
				if bi2 >= 0:
					_release(bi2)
				else:
					_set_stick(Vector2.ZERO)
					_stick_idx = -999
				_touch.erase(st.index)
	elif event is InputEventScreenDrag:
		var dr := event as InputEventScreenDrag
		if dr.index == _stick_idx:
			var v := (dr.position - _stick_c) / 120.0
			if v.length() > 1.0:
				# parmak çok uzaklaşırsa merkez peşinden gelir
				_stick_c = dr.position - v.normalized() * 120.0
				v = v.normalized()
			_set_stick(v)


func _button_at(p: Vector2) -> int:
	for i in _buttons.size():
		var b: Dictionary = _buttons[i]
		if p.distance_to(b["pos"]) <= float(b["r"]) * 1.15:
			return i
	return -1


func _press(i: int) -> void:
	_pressed[i] = true
	Input.action_press(String(_buttons[i]["action"]))


func _release(i: int) -> void:
	_pressed.erase(i)
	Input.action_release(String(_buttons[i]["action"]))


func _set_stick(v: Vector2) -> void:
	_stick_v = v
	var dz := 0.15
	_axis_action("move_right", v.x if v.x > dz else 0.0)
	_axis_action("move_left", -v.x if v.x < -dz else 0.0)
	_axis_action("move_down", v.y if v.y > dz else 0.0)
	_axis_action("move_up", -v.y if v.y < -dz else 0.0)


func _axis_action(a: String, strength: float) -> void:
	if strength > 0.0:
		Input.action_press(a, clampf(strength, 0.0, 1.0))
	else:
		Input.action_release(a)


func _exit_tree() -> void:
	for a in ["move_right", "move_left", "move_up", "move_down"]:
		Input.action_release(a)
	for i in _pressed.keys():
		Input.action_release(String(_buttons[i]["action"]))


# ---------------------------------------------------------------- çizim

func _draw_view() -> void:
	if get_tree().paused:
		return
	var gold := UI.GOLD
	var font := UI.font()
	var sym := UI.symbol_font()
	# çubuk
	if _stick_idx != -999:
		_view.draw_circle(_stick_c, 120.0, Color(0.02, 0.03, 0.1, 0.35))
		_view.draw_arc(_stick_c, 120.0, 0.0, TAU, 48, Color(gold.r, gold.g, gold.b, 0.5), 3.0)
		_view.draw_circle(_stick_c + _stick_v * 120.0, 52.0, Color(gold.r, gold.g, gold.b, 0.55))
	else:
		var s := _view.get_viewport_rect().size
		var c := Vector2(250, s.y - 250)
		_view.draw_arc(c, 120.0, 0.0, TAU, 48, Color(gold.r, gold.g, gold.b, 0.18), 2.0)
		_view.draw_circle(c, 46.0, Color(gold.r, gold.g, gold.b, 0.15))
	for i in _buttons.size():
		var b: Dictionary = _buttons[i]
		var p: Vector2 = b["pos"]
		var r: float = b["r"]
		var on := _pressed.has(i)
		var rd := 1.0
		if b.has("skill") and hero != null and is_instance_valid(hero):
			var idx: int = b["skill"]
			rd = 1.0 - clampf(float(hero.skill_cd[idx]) / float(hero.SKILL_CD[idx]), 0.0, 1.0)
		elif String(b["action"]) == "dash" and hero != null and is_instance_valid(hero) and hero.get("dash_cd") != null:
			rd = 1.0 if float(hero.dash_cd) <= 0.0 else 0.4
		elif String(b["action"]) == "heavy" and hero != null and is_instance_valid(hero) and float(hero.heavy_cd_max) > 0.0:
			rd = 1.0 - clampf(float(hero.heavy_cd) / float(hero.heavy_cd_max), 0.0, 1.0)
		_view.draw_circle(p, r, Color(0.02, 0.03, 0.1, 0.55 if on else 0.38))
		if rd < 1.0:
			_view.draw_arc(p, r - 6.0, -PI * 0.5, -PI * 0.5 + TAU * rd, 48, Color(gold.r, gold.g, gold.b, 0.8), 6.0)
		_view.draw_arc(p, r, 0.0, TAU, 48, Color(gold.r, gold.g, gold.b, (0.95 if on else 0.6) * (1.0 if rd >= 1.0 else 0.5)), 3.0)
		var lbl := String(b["label"])
		var fs := int(r * 0.6)
		var f: Font = sym if lbl in ["⚔", "◈", "»", "»»"] else font
		var w := f.get_string_size(lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		_view.draw_string(f, p + Vector2(-w * 0.5, fs * 0.35), lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1.0, 0.95, 0.85, 0.95 * (1.0 if rd >= 1.0 else 0.55)))
		var sub := tr(String(b["sub"]))
		if sub != "":
			var sw := font.get_string_size(sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x
			_view.draw_string(font, p + Vector2(-sw * 0.5, r + 24.0), sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(gold.r, gold.g, gold.b, 0.75))
