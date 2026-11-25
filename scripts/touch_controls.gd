extends CanvasLayer
## DOKUNMATİK KONTROLLER (telefon/tablet)
## Sol yarıda yüzen sanal çubuk (dokunduğun yer merkez olur), sağda saldırı kümesi.
## Nişan otomatik: en yakın düşmana döner (hero._pad_aim).
##  - Ekranın sağ yarısına TEK DOKUNUŞ: o noktaya saldırır (yakındaki düşmana yapışır)
##  - ÇİFT DOKUNUŞ: o yöne atılır
##  - Yetenek düğmesini SÜRÜKLE: hedef göstergesi çıkar, bırakınca oraya atar; sürüklemeden bırakırsan otomatik nişan
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
var _skill_drag := {}          # parmak no -> {"i": düğme, "cur": konum}
var _last_tap_t := -10.0
var _last_tap_p := Vector2.ZERO
var _clock := 0.0
const DRAG_MIN := 35.0         # bundan kısa sürükleme = otomatik nişan
const DRAG_MAX := 210.0        # tam menzil için sürükleme uzunluğu (piksel)
const SKILL_RANGE := 10.0      # yetenek hedefinin en uzak mesafesi (m)


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


func _process(d: float) -> void:
	_clock += d
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
				if _buttons[bi].has("skill"):
					# yetenek: basınca değil bırakınca atılır (sürükleyerek nişan alınabilsin)
					_skill_drag[st.index] = {"i": bi, "cur": st.position}
					_pressed[bi] = true
				else:
					_press(bi)
			elif st.position.x < _view.get_viewport_rect().size.x * 0.45:
				if _stick_idx == -999:
					_touch[st.index] = -1
					_stick_idx = st.index
					_stick_c = st.position
					_stick_v = Vector2.ZERO
			else:
				_tap(st.position)
		else:
			if _skill_drag.has(st.index):
				_release_skill(st.index)
				_touch.erase(st.index)
			elif _touch.has(st.index):
				var bi2: int = _touch[st.index]
				if bi2 >= 0:
					_release(bi2)
				else:
					_set_stick(Vector2.ZERO)
					_stick_idx = -999
				_touch.erase(st.index)
	elif event is InputEventScreenDrag:
		var dr := event as InputEventScreenDrag
		if _skill_drag.has(dr.index):
			_skill_drag[dr.index]["cur"] = dr.position
		elif dr.index == _stick_idx:
			var v := (dr.position - _stick_c) / 120.0
			if v.length() > 1.0:
				# parmak çok uzaklaşırsa merkez peşinden gelir
				_stick_c = dr.position - v.normalized() * 120.0
				v = v.normalized()
			_set_stick(v)


## Boş alana dokunuş: tek -> saldırı, çift -> atılma
func _tap(p: Vector2) -> void:
	if hero == null or not is_instance_valid(hero) or hub_mode:
		return
	var gp: Vector3 = hero.ground_point(p)
	if _clock - _last_tap_t < 0.3 and p.distance_to(_last_tap_p) < 160.0:
		_last_tap_t = -10.0
		hero.touch_dash(gp)
		return
	_last_tap_t = _clock
	_last_tap_p = p
	hero.touch_aim(gp, 0.35)
	_pulse("fire")


func _pulse(action: String) -> void:
	Input.action_press(action)
	get_tree().create_timer(0.08, true, false, true).timeout.connect(Input.action_release.bind(action))


## Sürüklenen yeteneğin dünyadaki hedefi (sürükleme kısaysa null)
func _skill_target(idx: int):
	if not _skill_drag.has(idx) or hero == null or not is_instance_valid(hero) or hero.camera == null:
		return null
	var sd: Dictionary = _skill_drag[idx]
	var b: Dictionary = _buttons[int(sd["i"])]
	var v: Vector2 = sd["cur"] - b["pos"]
	if v.length() < DRAG_MIN:
		return null
	var basis: Basis = hero.camera.global_transform.basis
	var fwd := -basis.z
	fwd.y = 0.0
	fwd = fwd.normalized()
	var right := basis.x
	right.y = 0.0
	right = right.normalized()
	var dir := (right * v.x - fwd * v.y).normalized()
	var dist := clampf((v.length() - DRAG_MIN) / (DRAG_MAX - DRAG_MIN), 0.05, 1.0) * SKILL_RANGE
	var hp: Vector3 = hero.global_position
	return Vector3(hp.x, 0.0, hp.z) + dir * dist


func _release_skill(idx: int) -> void:
	var sd: Dictionary = _skill_drag[idx]
	var bi: int = sd["i"]
	var tgt = _skill_target(idx)
	if tgt != null:
		hero.touch_aim(tgt, 0.45)
	_skill_drag.erase(idx)
	_pressed.erase(bi)
	_pulse(String(_buttons[bi]["action"]))


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
	for a in ["fire", "skill_1", "skill_2", "skill_3", "dash"]:
		Input.action_release(a)


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
	# yetenek hedef göstergesi
	for k in _skill_drag.keys():
		var sd: Dictionary = _skill_drag[k]
		var bp: Vector2 = _buttons[int(sd["i"])]["pos"]
		var cur: Vector2 = sd["cur"]
		_view.draw_line(bp, cur, Color(gold.r, gold.g, gold.b, 0.5), 3.0)
		_view.draw_circle(cur, 26.0, Color(gold.r, gold.g, gold.b, 0.5))
		var tgt = _skill_target(k)
		if tgt != null and hero.camera != null:
			var cam: Camera3D = hero.camera
			var hs := cam.unproject_position(hero.global_position + Vector3(0, 0.1, 0))
			var ts := cam.unproject_position(tgt + Vector3(0, 0.1, 0))
			_view.draw_line(hs, ts, Color(1.0, 0.95, 0.7, 0.8), 4.0)
			_view.draw_arc(ts, 46.0, 0.0, TAU, 40, Color(1.0, 0.95, 0.7, 0.95), 4.0)
			_view.draw_circle(ts, 10.0, Color(1.0, 0.95, 0.7, 0.9))
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
