extends Control
## BIRTH CHART ekranı (tam ekran, iki katman)
## 1) ÇARK: gerçek bir doğum haritası gibi 12 ev. 1. ev solda (ASC) başlar, saat yönünün tersine ilerler.
##    Her dilimde evin numarası, adı, burcu ve ilerlemesi yazar. Eve tıkla: o evin ağacı açılır.
## 2) EV AĞACI: o evin 43 yıldızlık ağacı, arkada burcun takımyıldızı. Kaydır (sürükle), yakınlaştır (tekerlek).
##    Yıldıza tıkla: yıldız tozu harcayıp kademe al. Esc / BACK çarka döner. A / D önceki-sonraki ev.

signal closed

const GameData = preload("res://scripts/game_data.gd")
const BC = preload("res://scripts/birth_chart.gd")
const UI = preload("res://scripts/ui_style.gd")

const PANEL_W := 400.0
const R_MINOR := 13.0
const R_NOTABLE := 22.0
const R_KEY := 34.0
const BAND := 52.0   # çarkın dışındaki burç halkasının kalınlığı

var mode := "wheel"
var house := 0
var _t := 0.0
var _hover_house := -1
var _hover_star := -1
var _flash := {}          # yıldız -> kalan parlama süresi
var _bg_stars: Array = [] # [konum oranı, boyut, faz]
var _pan := Vector2.ZERO
var _zoom := 1.0
var _dragging := false
var _drag_moved := 0.0
var _mouse := Vector2.ZERO
var _font: Font

var _btn_close: Button
var _btn_back: Button
var _btn_prev: Button
var _btn_next: Button


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = UI.theme()
	_font = UI.font()
	var rng := RandomNumberGenerator.new()
	rng.seed = 12
	for i in 260:
		_bg_stars.append([Vector2(rng.randf(), rng.randf()), rng.randf_range(0.6, 2.2), rng.randf() * TAU])

	_btn_close = _make_btn("CLOSE", func(): closed.emit())
	_btn_back = _make_btn("BACK", func(): _to_wheel())
	_btn_prev = _make_btn("<", func(): _open_house((house + 11) % 12))
	_btn_next = _make_btn(">", func(): _open_house((house + 1) % 12))
	_btn_prev.custom_minimum_size = Vector2(64, 48)
	_btn_next.custom_minimum_size = Vector2(64, 48)
	visibility_changed.connect(_on_visibility)
	_layout()


func _on_visibility() -> void:
	if visible:
		_to_wheel()


func _make_btn(text: String, cb: Callable) -> Button:
	var b := UI.button(text, 20)
	b.custom_minimum_size = Vector2(180, 48)
	b.pressed.connect(cb)
	b.focus_mode = Control.FOCUS_NONE
	add_child(b)
	return b


func _layout() -> void:
	# CanvasLayer içinde olduğumuz için boyutu ekrandan alıyoruz (anchor burada çalışmaz)
	var vs := get_viewport_rect().size
	position = Vector2.ZERO
	size = vs
	_btn_close.position = Vector2(vs.x - 220, vs.y - 78)
	_btn_back.position = Vector2(40, vs.y - 78)
	_btn_prev.position = Vector2(236, vs.y - 78)
	_btn_next.position = Vector2(310, vs.y - 78)
	var in_house := mode == "house"
	_btn_back.visible = in_house
	_btn_prev.visible = in_house
	_btn_next.visible = in_house


func _to_wheel() -> void:
	mode = "wheel"
	_hover_star = -1
	_layout()


func _open_house(h: int) -> void:
	house = h
	mode = "house"
	_hover_star = -1
	_layout()
	_fit_house()
	Sfx.play("switch", -12.0, 0.0, 0, 1.3)


func _fit_house() -> void:
	var list := BC.nodes(house)
	var mn := Vector2(INF, INF)
	var mx := Vector2(-INF, -INF)
	for n in list:
		var p: Vector2 = n["pos"]
		mn = mn.min(p)
		mx = mx.max(p)
	var area := _tree_area()
	var span := (mx - mn) + Vector2(160, 160)
	_zoom = clampf(minf(area.size.x / span.x, area.size.y / span.y), 0.35, 1.6)
	_pan = -(mn + mx) * 0.5


func _tree_area() -> Rect2:
	return Rect2(PANEL_W + 20.0, 20.0, size.x - PANEL_W - 40.0, size.y - 120.0)


func _to_screen(p: Vector2) -> Vector2:
	return _tree_area().get_center() + (p + _pan) * _zoom


func _process(delta: float) -> void:
	if not visible:
		return
	_t += delta
	if size != get_viewport_rect().size:
		_layout()
	for k in _flash.keys():
		_flash[k] = float(_flash[k]) - delta
		if _flash[k] <= 0.0:
			_flash.erase(k)
	if Input.is_action_just_pressed("ui_cancel"):
		if mode == "house":
			_to_wheel()
		else:
			closed.emit()
	if mode == "house":
		if Input.is_action_just_pressed("move_left"):
			_open_house((house + 11) % 12)
		elif Input.is_action_just_pressed("move_right"):
			_open_house((house + 1) % 12)
	queue_redraw()


# ---------------------------------------------------------------- giriş

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		_mouse = mm.position
		if _dragging and mode == "house":
			_pan += mm.relative / _zoom
			_drag_moved += mm.relative.length()
		if mode == "wheel":
			_hover_house = _pick_house(_mouse)
		else:
			_hover_star = _pick_star(_mouse)
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mode == "house" and mb.pressed and (mb.button_index == MOUSE_BUTTON_WHEEL_UP or mb.button_index == MOUSE_BUTTON_WHEEL_DOWN):
			var before := (mb.position - _tree_area().get_center()) / _zoom - _pan
			_zoom = clampf(_zoom * (1.12 if mb.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / 1.12), 0.3, 2.2)
			var after := (mb.position - _tree_area().get_center()) / _zoom - _pan
			_pan += after - before
			return
		if mb.button_index == MOUSE_BUTTON_LEFT or mb.button_index == MOUSE_BUTTON_RIGHT or mb.button_index == MOUSE_BUTTON_MIDDLE:
			if mb.pressed:
				_dragging = true
				_drag_moved = 0.0
			else:
				_dragging = false
				if mb.button_index == MOUSE_BUTTON_LEFT and _drag_moved < 6.0:
					_click(mb.position)


func _click(pos: Vector2) -> void:
	if mode == "wheel":
		var h := _pick_house(pos)
		if h >= 0:
			_open_house(h)
		return
	var i := _pick_star(pos)
	if i < 0:
		return
	if GameData.try_buy_star(house, i):
		_flash[i] = 0.9
		Sfx.play("coin", -6.0, 0.0, 0, 1.2)
		Sfx.play("parry", -18.0, 0.05, 0, 1.4)
	else:
		Sfx.play("switch", -10.0, 0.0, 0, 0.6)


# ---------------------------------------------------------------- çark geometrisi

func _wheel_c() -> Vector2:
	return size * 0.5 + Vector2(0, -20)


func _wheel_r() -> float:
	return minf(size.x, size.y) * 0.37


## Ev açısı: 1. ev sol yatay çizginin (ASC) hemen altından başlar, saat yönünün tersine.
func _house_angle(i: int, frac := 0.5) -> float:
	return PI + (float(i) + frac) * (TAU / 12.0)


func _polar(r: float, ang: float) -> Vector2:
	return _wheel_c() + Vector2(cos(ang), -sin(ang)) * r


func _pick_house(p: Vector2) -> int:
	var d := p - _wheel_c()
	var r := d.length()
	var big_r := _wheel_r()
	if r < big_r * 0.3 or r > big_r + BAND:
		return -1
	var ang := fposmod(atan2(-d.y, d.x) - PI, TAU)
	return int(ang / (TAU / 12.0)) % 12


func _pick_star(p: Vector2) -> int:
	var list := BC.nodes(house)
	var best := -1
	var best_d := INF
	for i in list.size():
		var n: Dictionary = list[i]
		var r := _star_r(n) * _zoom + 6.0
		var d := p.distance_to(_to_screen(n["pos"]))
		if d < r and d < best_d:
			best = i
			best_d = d
	return best


func _star_r(n: Dictionary) -> float:
	match String(n["kind"]):
		"keystone":
			return R_KEY
		"notable":
			return R_NOTABLE
	return R_MINOR


# ---------------------------------------------------------------- çizim yardımcıları

func _text(s: String, pos: Vector2, fsize: int, col: Color, align: int = HORIZONTAL_ALIGNMENT_CENTER) -> void:
	var w := _font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize).x + 4.0
	var x := pos.x
	if align == HORIZONTAL_ALIGNMENT_CENTER:
		x -= w * 0.5
	elif align == HORIZONTAL_ALIGNMENT_RIGHT:
		x -= w
	draw_string(_font, Vector2(x, pos.y), s, HORIZONTAL_ALIGNMENT_LEFT, w, fsize, col)


## Evin ilerlemesi: çerçeveli kutuda büyük sayı + altında doluluk çubuğu
func _progress_pill(top_center: Vector2, prog: Vector2i, hover: bool) -> void:
	var t := "%d / %d" % [prog.x, prog.y]
	var fs := 18
	var w := _font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + 22.0
	var r := Rect2(top_center.x - w * 0.5, top_center.y, w, 28.0)
	var lit := prog.x > 0
	draw_rect(r, Color(0.03, 0.045, 0.13, 0.95))
	draw_rect(r, UI.GOLD if (lit or hover) else _alpha(UI.GOLD, 0.55), false, 1.5)
	_text(t, Vector2(top_center.x, top_center.y + 21.0), fs, UI.CREAM if not lit else UI.GOLD)
	var frac := float(prog.x) / float(maxi(prog.y, 1))
	var bar := Rect2(r.position.x + 4.0, r.position.y + r.size.y + 3.0, r.size.x - 8.0, 4.0)
	draw_rect(bar, Color(0.12, 0.15, 0.3))
	if frac > 0.0:
		draw_rect(Rect2(bar.position, Vector2(maxf(bar.size.x * frac, 2.0), bar.size.y)), UI.GOLD)


## Burç sembolü (♈ ... ♓), sistemdeki sembol yazı tipiyle
func _symbol(h: int, pos: Vector2, fsize: int, col: Color) -> void:
	var sf := UI.symbol_font()
	var g := String.chr(0x2648 + h) + String.chr(0xFE0E)
	var w := sf.get_string_size(g, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize).x
	draw_string(sf, Vector2(pos.x - w * 0.5, pos.y), g, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, col)


## Basit satır kaydırma; yazılan yüksekliği döndürür
func _wrap(s: String, pos: Vector2, width: float, fsize: int, col: Color) -> float:
	var words := s.split(" ")
	var line := ""
	var y := pos.y
	for wd in words:
		var test: String = wd if line == "" else line + " " + wd
		if _font.get_string_size(test, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize).x > width and line != "":
			draw_string(_font, Vector2(pos.x, y), line, HORIZONTAL_ALIGNMENT_LEFT, width, fsize, col)
			y += fsize * 1.3
			line = wd
		else:
			line = test
	if line != "":
		draw_string(_font, Vector2(pos.x, y), line, HORIZONTAL_ALIGNMENT_LEFT, width, fsize, col)
		y += fsize * 1.3
	return y - pos.y


func _star_poly(c: Vector2, r_out: float, r_in: float, points: int, rot := 0.0) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for k in points * 2:
		var a := rot - PI * 0.5 + float(k) * PI / float(points)
		var r := r_out if k % 2 == 0 else r_in
		pts.append(c + Vector2(cos(a), sin(a)) * r)
	return pts


func _alpha(c: Color, a: float) -> Color:
	return Color(c.r, c.g, c.b, a)


# ---------------------------------------------------------------- çizim

func _draw() -> void:
	# opak lacivert gökyüzü + göz kırpan yıldızlar
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.035, 0.05, 0.14))
	draw_circle(size * 0.5, maxf(size.x, size.y) * 0.6, Color(0.071, 0.114, 0.31, 0.35))
	for s in _bg_stars:
		var sp: Vector2 = s[0]
		var tw := 0.45 + 0.55 * sin(_t * 1.3 + float(s[2]))
		draw_circle(Vector2(sp.x * size.x, sp.y * size.y), float(s[1]), Color(1.0, 0.95, 0.8, 0.25 + 0.4 * tw))
	if mode == "wheel":
		_draw_wheel()
	else:
		_draw_house()


func _draw_wheel() -> void:
	var c := _wheel_c()
	var big_r := _wheel_r()
	var r_in := big_r * 0.3
	var gold := UI.GOLD
	# dilimler
	for h in 12:
		var a0 := _house_angle(h, 0.0)
		var a1 := _house_angle(h, 1.0)
		var poly := PackedVector2Array()
		for k in 25:
			poly.append(_polar(big_r, lerpf(a0, a1, float(k) / 24.0)))
		for k in 25:
			poly.append(_polar(r_in, lerpf(a1, a0, float(k) / 24.0)))
		var hover := h == _hover_house
		draw_colored_polygon(poly, _alpha(gold, 0.16 if hover else 0.035))
		# ilerleme yayı
		var prog := BC.house_progress(GameData.chart, h)
		var frac := float(prog.x) / float(prog.y)
		if frac > 0.0:
			var arc := PackedVector2Array()
			for k in 33:
				arc.append(_polar(big_r - 9.0, lerpf(a0, lerpf(a0, a1, frac), float(k) / 32.0)))
			draw_polyline(arc, gold, 6.0, true)
		# yazılar
		var mid := _house_angle(h)
		var info: Dictionary = BC.HOUSES[h]
		# Roma rakamı dış halkada; sembol, ev adı ve ilerleme dilimin ortasında alt alta
		_text(String(BC.ROMAN[h]), _polar(big_r * 0.87, mid) + Vector2(0, 11), 32 if hover else 28, gold)
		var cpt := _polar(big_r * 0.6, mid)
		_text(tr(String(info["name"])), cpt + Vector2(0, 4), 18, _alpha(gold, 1.0 if hover else 0.85))
		_progress_pill(cpt + Vector2(0, 20), prog, hover)
		# burç halkası: dış çemberin dışındaki bantta sembol
		var band_poly := PackedVector2Array()
		for k in 13:
			band_poly.append(_polar(big_r + BAND, lerpf(a0, a1, float(k) / 12.0)))
		for k in 13:
			band_poly.append(_polar(big_r, lerpf(a1, a0, float(k) / 12.0)))
		draw_colored_polygon(band_poly, _alpha(gold, 0.18 if hover else 0.06))
		_symbol(h, _polar(big_r + BAND * 0.5, mid) + Vector2(0, 11), 32 if hover else 28, gold if hover else _alpha(UI.CREAM, 0.9))
	# halkalar ve ev çizgileri
	draw_arc(c, big_r + BAND, 0.0, TAU, 180, gold, 3.0, true)
	draw_arc(c, big_r, 0.0, TAU, 160, gold, 2.0, true)
	for h in 12:
		var ab := _house_angle(h, 0.0)
		draw_line(_polar(big_r, ab), _polar(big_r + BAND, ab), _alpha(gold, 0.6), 1.2, true)
	draw_arc(c, big_r - 18.0, 0.0, TAU, 160, _alpha(gold, 0.45), 1.5, true)
	draw_arc(c, r_in, 0.0, TAU, 120, gold, 2.5, true)
	draw_arc(c, r_in - 10.0, 0.0, TAU, 120, _alpha(gold, 0.4), 1.0, true)
	for h in 12:
		var a := _house_angle(h, 0.0)
		var angular := h % 3 == 0   # açı evleri (1, 4, 7, 10) kalın çizgi
		draw_line(_polar(r_in, a), _polar(big_r + (BAND + 16.0 if angular else 0.0), a), _alpha(gold, 0.95 if angular else 0.5), 3.0 if angular else 1.2, true)
	_text("ASC", _polar(big_r + BAND + 42.0, PI) + Vector2(0, 8), 22, gold)
	_text("DSC", _polar(big_r + BAND + 42.0, 0.0) + Vector2(0, 8), 22, gold)
	_text("MC", _polar(big_r + BAND + 30.0, PI * 0.5), 22, gold)
	_text("IC", _polar(big_r + BAND + 30.0, PI * 1.5) + Vector2(0, 16), 22, gold)
	# merkez
	draw_circle(c, r_in - 14.0, Color(0.04, 0.06, 0.17, 0.95))
	var all := BC.all_progress(GameData.chart)
	_text(tr("BIRTH CHART"), c + Vector2(0, -34), 30, gold)
	draw_line(c + Vector2(-90, -20), c + Vector2(90, -20), _alpha(gold, 0.6), 1.0)
	_text(tr("%d stardust") % GameData.stardust, c + Vector2(0, 12), 22, UI.CREAM)
	_text(tr("%d / %d stars lit") % [all.x, all.y], c + Vector2(0, 46), 19, UI.CREAM)
	var hint := tr("Choose a house to open its sky")
	if _hover_house >= 0:
		hint = tr(String(BC.HOUSES[_hover_house]["theme"]))
	_text(hint, Vector2(size.x * 0.5, size.y - 40.0), 18, _alpha(UI.CREAM, 0.8))


func _draw_house() -> void:
	var info: Dictionary = BC.HOUSES[house]
	var list := BC.nodes(house)
	var chart: Dictionary = GameData.chart
	var gold := UI.GOLD
	var area := _tree_area()

	# arkada burcun takımyıldızı (soluk, dev)
	var con: Dictionary = BC.CONSTELLATIONS[house]
	var cc := area.get_center()
	var cs := minf(area.size.x, area.size.y) * 0.42
	var cpts: Array = con["pts"]
	var segs: Array = con["segs"]
	for k in range(0, segs.size(), 2):
		var pa: Vector2 = cpts[segs[k]]
		var pb: Vector2 = cpts[segs[k + 1]]
		draw_line(cc + pa * cs, cc + pb * cs, Color(0.6, 0.7, 1.0, 0.1), 2.0, true)
	for p in cpts:
		var pp: Vector2 = p
		draw_circle(cc + pp * cs, 5.0, Color(0.75, 0.82, 1.0, 0.18))

	# bağlantılar
	for i in list.size():
		var ni: Dictionary = list[i]
		var a := _to_screen(ni["pos"])
		var lit_a := BC.rank(chart, house, i) > 0
		for p in ni["parents"]:
			var pi_: int = p
			var b := _to_screen(list[pi_]["pos"])
			var lit_b := BC.rank(chart, house, pi_) > 0
			var col := Color(0.5, 0.55, 0.75, 0.22)
			var w := 2.0 * _zoom
			if lit_a and lit_b:
				col = gold
				w = 4.0 * _zoom
			elif lit_b:
				col = _alpha(gold, 0.45)
			draw_line(a, b, col, maxf(w, 1.0), true)

	# yıldızlar
	for i in list.size():
		var n: Dictionary = list[i]
		var p := _to_screen(n["pos"])
		var st := BC.state(chart, house, i)
		var r := _star_r(n) * _zoom
		var rk := BC.rank(chart, house, i)
		var kind := String(n["kind"])
		var fl := float(_flash.get(i, 0.0))
		# hale
		if st == "maxed" or st == "owned":
			draw_circle(p, r * (1.9 + fl * 1.5), _alpha(gold, 0.08 + fl * 0.3))
		elif st == "open":
			draw_circle(p, r * 1.6, _alpha(gold, 0.05 + 0.05 * sin(_t * 4.0)))
		var fill := Color(0.05, 0.06, 0.13)
		var edge := Color(0.4, 0.45, 0.6, 0.5)
		match st:
			"maxed":
				fill = gold
				edge = Color(1.0, 0.97, 0.85)
			"owned":
				fill = Color(0.55, 0.45, 0.2)
				edge = gold
			"open":
				fill = Color(0.08, 0.11, 0.3)
				edge = _alpha(gold, 0.65 + 0.35 * sin(_t * 4.0))
		var lw := maxf(2.0 * _zoom, 1.0)
		if kind == "minor":
			draw_circle(p, r, fill)
			draw_arc(p, r, 0.0, TAU, 32, edge, lw, true)
		else:
			var pts := 4 if kind == "notable" else 8
			var shape := _star_poly(p, r * 1.25, r * 0.55, pts, _t * 0.2 if kind == "keystone" else 0.0)
			draw_colored_polygon(shape, fill)
			shape.append(shape[0])
			draw_polyline(shape, edge, lw, true)
			draw_arc(p, r * 1.45, 0.0, TAU, 48, _alpha(edge, 0.5), lw, true)
		if i == _hover_star:
			draw_arc(p, r * 1.7, 0.0, TAU, 48, Color(1, 1, 1, 0.8), 2.0, true)
		# kademe noktaları
		var mxr := int(n["max"])
		if mxr > 1 and _zoom > 0.45:
			for k in mxr:
				var ang := PI * 0.5 + (float(k) - float(mxr - 1) * 0.5) * 0.42
				var dp := p + Vector2(cos(ang), sin(ang)) * (r + 9.0 * _zoom)
				draw_circle(dp, maxf(3.0 * _zoom, 1.5), gold if k < rk else Color(0.35, 0.38, 0.5, 0.8))

	_draw_house_panel(info)
	_text(tr("Drag to move  ·  Wheel to zoom  ·  A / D change house  ·  Esc back"), Vector2(area.get_center().x, size.y - 40.0), 16, _alpha(UI.CREAM, 0.7))
	# açıklama kutusu en son çizilir ki hiçbir yazı üstüne binmesin
	if _hover_star >= 0:
		_draw_tooltip(list[_hover_star], _hover_star)


func _draw_house_panel(info: Dictionary) -> void:
	var gold := UI.GOLD
	draw_rect(Rect2(0, 0, PANEL_W, size.y), Color(0.03, 0.045, 0.13, 0.94))
	draw_line(Vector2(PANEL_W, 0), Vector2(PANEL_W, size.y), gold, 2.0)
	var x := 40.0
	var y := 70.0
	var tw := PANEL_W - 80.0
	_text(tr("HOUSE %s") % String(BC.ROMAN[house]), Vector2(x, y), 22, _alpha(gold, 0.75), HORIZONTAL_ALIGNMENT_LEFT)
	_symbol(house, Vector2(PANEL_W - 66.0, y + 6.0), 40, gold)
	y += 52.0
	_text(tr(String(info["name"])), Vector2(x, y), 44, gold, HORIZONTAL_ALIGNMENT_LEFT)
	y += 36.0
	_text(tr("%s  ·  ruled by %s") % [tr(String(info["sign"])), tr(String(info["ruler"]))], Vector2(x, y), 16, UI.CREAM, HORIZONTAL_ALIGNMENT_LEFT)
	y += 18.0
	draw_line(Vector2(x, y), Vector2(x + tw, y), _alpha(gold, 0.5), 1.0)
	y += 30.0
	y += _wrap(tr(String(info["theme"])), Vector2(x, y), tw, 17, _alpha(UI.CREAM, 0.85))
	y += 20.0
	var prog := BC.house_progress(GameData.chart, house)
	_text(tr("STARS LIT"), Vector2(x, y), 14, _alpha(gold, 0.7), HORIZONTAL_ALIGNMENT_LEFT)
	y += 26.0
	_text("%d / %d" % [prog.x, prog.y], Vector2(x, y), 26, gold, HORIZONTAL_ALIGNMENT_LEFT)
	y += 14.0
	draw_rect(Rect2(x, y, tw, 8), Color(0.12, 0.15, 0.3))
	draw_rect(Rect2(x, y, tw * float(prog.x) / float(prog.y), 8), gold)
	y += 46.0
	_text(tr("CONSTELLATION POWER"), Vector2(x, y), 14, _alpha(gold, 0.7), HORIZONTAL_ALIGNMENT_LEFT)
	y += 28.0
	var ks: Array = info["keystone"]
	_text(tr(String(ks[0])), Vector2(x, y), 20, gold, HORIZONTAL_ALIGNMENT_LEFT)
	y += 26.0
	y += _wrap(tr(String(ks[1])), Vector2(x, y), tw, 16, _alpha(UI.CREAM, 0.85))
	y += 30.0
	_text(tr("STARDUST"), Vector2(x, y), 14, _alpha(gold, 0.7), HORIZONTAL_ALIGNMENT_LEFT)
	y += 30.0
	_text("%d" % GameData.stardust, Vector2(x, y), 30, UI.CREAM, HORIZONTAL_ALIGNMENT_LEFT)


func _draw_tooltip(n: Dictionary, i: int) -> void:
	var chart: Dictionary = GameData.chart
	var gold := UI.GOLD
	var st := BC.state(chart, house, i)
	var rk := BC.rank(chart, house, i)
	var mxr := int(n["max"])
	var kind := String(n["kind"])
	var kind_txt := tr("MINOR STAR")
	if kind == "notable":
		kind_txt = tr("MAJOR STAR")
	elif kind == "keystone":
		kind_txt = tr("CONSTELLATION POWER")
	var desc := ""
	var now := ""
	if kind == "minor":
		var per := float(n["per"])
		var unit := String(n["unit"])
		desc = tr("%s %s per rank") % [BC.fmt_value(per, unit), tr(String(n["name"]))]
		if rk > 0:
			now = tr("Current: %s") % BC.fmt_value(per * rk, unit)
	else:
		desc = tr(String(n["desc"]))
	# alt bilgi: fiyat ayrı, büyük ve renkli bir kutuda
	var foot := ""
	var foot_col := UI.CREAM
	var price := -1
	var afford := true
	if st == "maxed":
		foot = tr("Fully lit")
		foot_col = gold
	elif st == "locked":
		foot = tr("Locked: light a star connected below it")
		foot_col = Color(0.75, 0.78, 0.92)
	else:
		price = BC.cost(chart, house, i)
		afford = GameData.stardust >= price
		foot = tr("Click to light") if afford else tr("Not enough stardust (you have %d)") % GameData.stardust
		foot_col = UI.CREAM if afford else Color(1.0, 0.6, 0.5)
	var w := 460.0
	var fs_desc := 20
	var desc_lines := ceilf(_font.get_string_size(desc, HORIZONTAL_ALIGNMENT_LEFT, -1, fs_desc).x / (w - 44.0)) + 0.4
	var foot_lines := ceilf(_font.get_string_size(foot, HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x / (w - 44.0))
	var h := 112.0 + desc_lines * fs_desc * 1.3 + (30.0 if now != "" else 0.0) + 20.0 + (52.0 if price >= 0 else 0.0) + foot_lines * 23.0
	var pos := _mouse + Vector2(26, 20)
	if pos.x + w > size.x - 10.0:
		pos.x = _mouse.x - w - 26.0
	if pos.y + h > size.y - 20.0:
		pos.y = size.y - h - 20.0
	pos.y = maxf(pos.y, 10.0)
	draw_rect(Rect2(pos + Vector2(6, 8), Vector2(w, h)), Color(0, 0, 0, 0.45))
	draw_rect(Rect2(pos, Vector2(w, h)), Color(0.025, 0.035, 0.11, 0.98))
	draw_rect(Rect2(pos, Vector2(w, h)), gold, false, 2.5)
	var x := pos.x + 22.0
	var y := pos.y + 32.0
	_text(kind_txt, Vector2(x, y), 16, _alpha(gold, 0.85), HORIZONTAL_ALIGNMENT_LEFT)
	if mxr > 1:
		_text(tr("RANK %d / %d") % [rk, mxr], Vector2(pos.x + w - 22.0, y), 18, UI.CREAM, HORIZONTAL_ALIGNMENT_RIGHT)
	y += 36.0
	_text(tr(String(n["name"])), Vector2(x, y), 28, gold, HORIZONTAL_ALIGNMENT_LEFT)
	y += 34.0
	y += _wrap(desc, Vector2(x, y), w - 44.0, fs_desc, UI.CREAM)
	if now != "":
		_text(now, Vector2(x, y), 20, Color(0.6, 1.0, 0.7), HORIZONTAL_ALIGNMENT_LEFT)
		y += 30.0
	draw_line(Vector2(x, y - 12.0), Vector2(pos.x + w - 22.0, y - 12.0), _alpha(gold, 0.4), 1.0)
	y += 14.0
	if price >= 0:
		# fiyat kutusu: ✦ 49 YILDIZ TOZU
		var ptxt := "\u2726  %d  %s" % [price, tr("STARDUST")]
		var pw := _font.get_string_size(ptxt, HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x + 30.0
		var pr := Rect2(x, y - 6.0, pw, 40.0)
		var pc := gold if afford else Color(1.0, 0.45, 0.38)
		draw_rect(pr, Color(pc.r, pc.g, pc.b, 0.14))
		draw_rect(pr, pc, false, 2.0)
		_text(ptxt, Vector2(x + 15.0, y + 23.0), 24, pc, HORIZONTAL_ALIGNMENT_LEFT)
		y += 54.0
	_wrap(foot, Vector2(x, y + 6.0), w - 44.0, 17, foot_col)
