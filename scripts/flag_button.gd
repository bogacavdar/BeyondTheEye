extends Control
## Dil seçimi için bayrak düğmesi. Bayraklar koddan çizilir (resim dosyası yok).
## "tr": Türk bayrağı (resmî oranlara göre ay-yıldız), "en": Birleşik Krallık bayrağı (Union Jack).
## Seçili olan altın çerçeveli ve tam parlak; diğeri biraz soluk. Üstüne gelince hafifçe büyür.

signal picked(code: String)

const UI = preload("res://scripts/ui_style.gd")

var code := "en"
var selected := false
var _hover := false
var _k := 0.0


func _init(lang_code: String = "en") -> void:
	code = lang_code
	custom_minimum_size = Vector2(72, 48)
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	tooltip_text = "Türkçe" if code == "tr" else "English"


var _art: FlagArt


func _ready() -> void:
	mouse_entered.connect(func(): _hover = true)
	mouse_exited.connect(func(): _hover = false)
	_art = FlagArt.new()
	_art.code = code
	_art.clip_contents = true   # çapraz çizgiler bayrak dışına taşmasın
	_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_art)


func _process(delta: float) -> void:
	_k = lerpf(_k, 1.0 if (_hover or selected) else 0.0, 10.0 * delta)
	var grow := 2.0 * _k
	_art.position = Vector2(-grow, -grow)
	_art.size = size + Vector2(grow, grow) * 2.0
	_art.dim = 0.0 if selected else 0.45 * (1.0 - _k * 0.6)
	_art.queue_redraw()
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		picked.emit(code)


func _draw() -> void:
	# altın çerçeve (bayrağın dışında)
	var grow := 2.0 * _k
	var r := Rect2(Vector2(-grow, -grow), size + Vector2(grow, grow) * 2.0)
	var edge := UI.GOLD if selected else Color(UI.GOLD.r, UI.GOLD.g, UI.GOLD.b, 0.35 + 0.4 * _k)
	draw_rect(r.grow(4.0), edge, false, 3.0 if selected else 1.5)


class FlagArt extends Control:
	var code := "en"
	var dim := 0.0

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		if code == "tr":
			_draw_turkey(r)
		else:
			_draw_uk(r)
		if dim > 0.0:
			draw_rect(r, Color(0.02, 0.03, 0.1, dim))

	## Türk bayrağı: 1200x800 ölçeğinde dış ay (425,400,r200), iç ay (475,400,r160),
	## yıldız merkezi (583.3,400), yıldızı çevreleyen çember r=100, bir köşesi gönderden yana bakar.
	func _draw_turkey(r: Rect2) -> void:
		var red := Color(0.89, 0.04, 0.09)
		draw_rect(r, red)
		var s := r.size.y / 800.0
		var o := r.position
		draw_circle(o + Vector2(425, 400) * s, 200.0 * s, Color.WHITE)
		draw_circle(o + Vector2(475, 400) * s, 160.0 * s, red)
		var c := o + Vector2(583.3, 400) * s
		var pts := PackedVector2Array()
		for k in 10:
			var a := PI + float(k) * PI / 5.0
			var rad := (100.0 if k % 2 == 0 else 38.2) * s
			pts.append(c + Vector2(cos(a), sin(a)) * rad)
		draw_colored_polygon(pts, Color.WHITE)


	## Union Jack (60x30 ölçeğinden 3:2 alana sığdırılmış): lacivert zemin, beyaz ve kırmızı çaprazlar,
	## ortada beyaz kenarlı kırmızı haç.
	func _draw_uk(r: Rect2) -> void:
		var blue := Color(0.0, 0.13, 0.41)
		var red := Color(0.78, 0.06, 0.18)
		draw_rect(r, blue)
		var w := r.size.x
		var h := r.size.y
		var o := r.position
		var u := h / 30.0
		var tl := o
		var tr_ := o + Vector2(w, 0)
		var bl := o + Vector2(0, h)
		var br := o + Vector2(w, h)
		# beyaz çaprazlar
		draw_line(tl, br, Color.WHITE, 6.0 * u)
		draw_line(tr_, bl, Color.WHITE, 6.0 * u)
		# kırmızı çaprazlar (resmî bayraktaki gibi merkezden hafif kaydırılmış)
		var d1 := (br - tl).normalized()
		var n1 := Vector2(-d1.y, d1.x) * u
		draw_line(tl + n1, o + Vector2(w, h) * 0.5 + n1, red, 2.0 * u)
		draw_line(o + Vector2(w, h) * 0.5 - n1, br - n1, red, 2.0 * u)
		var d2 := (bl - tr_).normalized()
		var n2 := Vector2(-d2.y, d2.x) * u
		draw_line(tr_ - n2, o + Vector2(w, h) * 0.5 - n2, red, 2.0 * u)
		draw_line(o + Vector2(w, h) * 0.5 + n2, bl + n2, red, 2.0 * u)
		# beyaz ve kırmızı haç
		draw_rect(Rect2(o.x + w * 0.5 - 5.0 * u, o.y, 10.0 * u, h), Color.WHITE)
		draw_rect(Rect2(o.x, o.y + h * 0.5 - 5.0 * u, w, 10.0 * u), Color.WHITE)
		draw_rect(Rect2(o.x + w * 0.5 - 3.0 * u, o.y, 6.0 * u, h), red)
		draw_rect(Rect2(o.x, o.y + h * 0.5 - 3.0 * u, w, 6.0 * u), red)
