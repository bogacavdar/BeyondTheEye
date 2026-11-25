extends Control
## LÜTUF SEÇİMİ: gezegen ortada 3D olarak döner, ekran gezegenin rengiyle parlar,
## 3 lütuf kartı aşağıdan kayarak gelir. Birini seçersin. Seçim sırasında oyun durur.

signal picked(id: String)

const UI = preload("res://scripts/ui_style.gd")
const Boons = preload("res://scripts/boons.gd")
const GameData = preload("res://scripts/game_data.gd")
const PlanetView = preload("res://scripts/planet_view.gd")

var _row: HBoxContainer
var _title: Label
var _sub: Label
var _glow: TextureRect
var _sky
var _planet_slot: CenterContainer
var _planet_view
var _col := Color(1, 0.85, 0.5)
var _t := 0.0
var _choosing := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = UI.theme()
	visible = false
	var bg := ColorRect.new()
	bg.color = Color(0.01, 0.015, 0.05, 0.86)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	# gezegen renginde büyük, yumuşak bir ışık
	_glow = TextureRect.new()
	var gt := GradientTexture2D.new()
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.33)
	gt.fill_to = Vector2(0.5, 1.0)
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 0.5))
	g.set_color(1, Color(1, 1, 1, 0.0))
	gt.gradient = g
	gt.width = 512
	gt.height = 512
	_glow.texture = gt
	_glow.stretch_mode = TextureRect.STRETCH_SCALE
	_glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_glow)
	_sky = Starfield.new()
	_sky.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_sky)

	var cc := CenterContainer.new()
	cc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(cc)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	cc.add_child(vb)
	_planet_slot = CenterContainer.new()
	_planet_slot.custom_minimum_size = Vector2(0, 300)
	vb.add_child(_planet_slot)
	_title = UI.label("", 54, UI.GOLD, 8)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(_title)
	_sub = UI.label("Choose a blessing", 22, UI.CREAM, 5)
	_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(_sub)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 10)
	vb.add_child(gap)
	_row = HBoxContainer.new()
	_row.add_theme_constant_override("separation", 30)
	_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_child(_row)


func open(planet: String) -> void:
	var info: Dictionary = Boons.PLANETS.get(planet, Boons.PLANETS["Sun"])
	_col = info["color"]
	_glow.modulate = _col
	_sky.tint = _col
	_title.text = tr("BLESSING OF %s") % tr(String(info["name"]))
	_title.add_theme_color_override("font_color", _col.lerp(Color.WHITE, 0.25))
	# dönen 3D gezegen
	if _planet_view != null and is_instance_valid(_planet_view):
		_planet_view.queue_free()
	_planet_view = PlanetView.new()
	_planet_view.planet = planet
	_planet_view.custom_minimum_size = Vector2(300, 300)
	_planet_slot.add_child(_planet_view)
	_planet_view.pivot_offset = Vector2(150, 150)
	_planet_view.scale = Vector2(0.4, 0.4)
	_planet_view.modulate.a = 0.0
	# kartlar
	for c in _row.get_children():
		c.queue_free()
	var cards := Boons.offer(planet, GameData.run_boons)
	var i := 0
	for b in cards:
		var card := _card(b)
		_row.add_child(card)
		card.modulate.a = 0.0
		card.scale = Vector2(0.85, 0.85)
		var ct := card.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel(true)
		ct.tween_property(card, "modulate:a", 1.0, 0.35).set_delay(0.35 + 0.12 * float(i))
		ct.tween_property(card, "scale", Vector2.ONE, 0.45).set_delay(0.35 + 0.12 * float(i)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		i += 1
	visible = true
	_choosing = true
	modulate.a = 0.0
	var tw := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel(true)
	tw.tween_property(self, "modulate:a", 1.0, 0.3)
	tw.tween_property(_planet_view, "scale", Vector2.ONE, 0.7).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_planet_view, "modulate:a", 1.0, 0.5)
	get_tree().paused = true
	Sfx.play("parry", -10.0, 0.0, 0, 0.8)
	Sfx.play("coin", -10.0, 0.0, 0, 0.6)


func _process(delta: float) -> void:
	if not visible:
		return
	_t += delta
	_glow.modulate.a = 0.75 + 0.25 * sin(_t * 1.6)


func _card(b: Dictionary) -> Button:
	var pinfo: Dictionary = Boons.PLANETS[b["planet"]]
	var col: Color = pinfo["color"]
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(340, 280)
	btn.focus_mode = Control.FOCUS_NONE
	btn.pivot_offset = Vector2(170, 140)
	btn.add_theme_stylebox_override("normal", _card_box(Color(0.04, 0.06, 0.17, 0.97), Color(col.r, col.g, col.b, 0.85), 3))
	btn.add_theme_stylebox_override("hover", _card_box(Color(col.r * 0.25, col.g * 0.25, col.b * 0.3 + 0.08, 0.98), col.lerp(Color.WHITE, 0.3), 4))
	btn.add_theme_stylebox_override("pressed", _card_box(Color(col.r * 0.35, col.g * 0.35, col.b * 0.4, 1.0), Color.WHITE, 4))
	var vb := VBoxContainer.new()
	vb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vb.offset_left = 24
	vb.offset_right = -24
	vb.offset_top = 20
	vb.offset_bottom = -20
	vb.add_theme_constant_override("separation", 10)
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(vb)
	var g := UI.label(String(pinfo["glyph"]) + "︎", 56, col, 6)
	g.add_theme_font_override("font", UI.symbol_font())
	g.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	g.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(g)
	var n := UI.label(String(b["name"]), 28, col.lerp(Color.WHITE, 0.35), 5)
	n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	n.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	n.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(n)
	var line := ColorRect.new()
	line.color = Color(col.r, col.g, col.b, 0.6)
	line.custom_minimum_size = Vector2(200, 2)
	line.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(line)
	var d := UI.label(String(b["desc"]), 20, UI.CREAM, 4)
	d.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d.custom_minimum_size = Vector2(290, 0)
	d.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(d)
	btn.mouse_entered.connect(_hover.bind(btn, true))
	btn.mouse_exited.connect(_hover.bind(btn, false))
	btn.pressed.connect(_choose.bind(String(b["id"]), btn))
	return btn


func _card_box(bg: Color, border: Color, w: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(w)
	s.set_corner_radius_all(14)
	s.shadow_color = Color(border.r, border.g, border.b, 0.35)
	s.shadow_size = 14
	s.content_margin_left = 20
	s.content_margin_right = 20
	s.content_margin_top = 20
	s.content_margin_bottom = 20
	return s


func _hover(btn: Control, on: bool) -> void:
	if not _choosing:
		return
	var tw := btn.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(btn, "scale", Vector2.ONE * (1.06 if on else 1.0), 0.12).set_ease(Tween.EASE_OUT)
	if on:
		Sfx.play("switch", -16.0, 0.05, 40, 1.6)


func _choose(id: String, btn: Control) -> void:
	if not _choosing:
		return
	_choosing = false
	GameData.run_boons.append(id)
	Sfx.play("parry", -6.0, 0.0, 0, 1.2)
	Sfx.play("heavyhit", -12.0, 0.0, 0, 1.4)
	var tw := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel(true)
	tw.tween_property(btn, "scale", Vector2.ONE * 1.15, 0.2).set_ease(Tween.EASE_OUT)
	for c in _row.get_children():
		if c != btn:
			tw.tween_property(c, "modulate:a", 0.0, 0.2)
	tw.chain().tween_property(self, "modulate:a", 0.0, 0.25)
	tw.chain().tween_callback(_finish.bind(id))


func _finish(id: String) -> void:
	visible = false
	modulate.a = 1.0
	get_tree().paused = false
	picked.emit(id)


## Arka planda gezegen renginde göz kırpan yıldızlar
class Starfield extends Control:
	var tint := Color(1, 0.85, 0.5)
	var _pts: Array = []
	var _t := 0.0

	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		for i in 140:
			_pts.append([Vector2(randf(), randf()), randf_range(0.8, 2.6), randf() * TAU, randf_range(0.6, 2.0)])

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		for p in _pts:
			var pos: Vector2 = p[0]
			var tw := 0.4 + 0.6 * sin(_t * float(p[3]) + float(p[2]))
			var c := tint.lerp(Color.WHITE, 0.5)
			draw_circle(Vector2(pos.x * size.x, pos.y * size.y), float(p[1]), Color(c.r, c.g, c.b, 0.25 + 0.5 * tw))
