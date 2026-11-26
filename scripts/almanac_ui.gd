extends Control
## ALMANAK ekranı: solda on iki burç, sağda seçili burcun sayfası (mit, boss, yaratıklar).

const UI = preload("res://scripts/ui_style.gd")
const Almanac = preload("res://scripts/almanac.gd")

signal closed

const INK := Color(0.95, 0.88, 0.7)
var _list: VBoxContainer
var _page: VBoxContainer
var _scroll: ScrollContainer
var _head: Label
var _sel := "aries"


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var bg := ColorRect.new()
	bg.color = Color(0.01, 0.015, 0.05, 0.85)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var p := UI.panel()
	center.add_child(p)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 10)
	p.add_child(outer)
	_head = UI.label("", 34, UI.GOLD, 5)
	_head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	outer.add_child(_head)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	outer.add_child(row)
	# burç listesi
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 4)
	row.add_child(_list)
	# sayfa
	_scroll = ScrollContainer.new()
	_scroll.custom_minimum_size = Vector2(1000, 760)
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	row.add_child(_scroll)
	_page = VBoxContainer.new()
	_page.add_theme_constant_override("separation", 8)
	_page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_page)
	var back := UI.button(tr("BACK"), 18)
	back.pressed.connect(func(): visible = false; closed.emit())
	outer.add_child(back)
	visible = false


func open() -> void:
	var pr: Vector2i = Almanac.progress()
	_head.text = tr("ALMANAC") + "   %d / %d" % [pr.x, pr.y]
	_refresh_list()
	_show(_sel)
	visible = true


func _refresh_list() -> void:
	for c in _list.get_children():
		c.queue_free()
	for s in Almanac.SIGNS:
		var pg: Dictionary = Almanac.PAGES[s]
		var open_ := Almanac.visited(s)
		var col: Color = pg["col"] if open_ else Color(0.42, 0.42, 0.5)
		var txt := String(pg["glyph"]) + "︎  " + (Almanac.t(pg["name"]) if open_ else "? ? ?")
		if Almanac.defeated(s):
			txt += "  ✦"
		var b := UI.button(("▸ " if s == _sel else "") + txt, 17, col)
		b.custom_minimum_size = Vector2(250, 54)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var sid: String = s
		b.pressed.connect(func():
			_sel = sid
			_refresh_list()
			_show(sid))
		_list.add_child(b)
	var Ach = load("res://scripts/achievements.gd")
	var ab := UI.button(("▸ " if _sel == "ach" else "") + "✦  " + tr("ACHIEVEMENTS") + "  %d/%d" % [GameData_ach_count(), Ach.LIST.size()], 17, UI.GOLD)
	ab.custom_minimum_size = Vector2(250, 54)
	ab.alignment = HORIZONTAL_ALIGNMENT_LEFT
	ab.pressed.connect(func():
		_sel = "ach"
		_refresh_list()
		_show("ach"))
	_list.add_child(ab)


func GameData_ach_count() -> int:
	return int(load("res://scripts/game_data.gd").achievements.size())


func _para(text: String, size: int, col: Color) -> Label:
	var l := UI.label(text, size, col, 3)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(960, 0)
	_page.add_child(l)
	return l


func _sep() -> void:
	var r := ColorRect.new()
	r.color = Color(UI.GOLD.r, UI.GOLD.g, UI.GOLD.b, 0.35)
	r.custom_minimum_size = Vector2(960, 2)
	_page.add_child(r)


func _show(s: String) -> void:
	for c in _page.get_children():
		c.queue_free()
	_scroll.scroll_vertical = 0
	if s == "ach":
		_show_achievements()
		return
	var pg: Dictionary = Almanac.PAGES[s]
	var col: Color = pg["col"]
	if not Almanac.visited(s):
		_para(String(pg["glyph"]) + "︎", 64, Color(0.42, 0.42, 0.5))
		_para(tr("This page is still dark. Reach this sign's lands to read it."), 20, Color(0.6, 0.6, 0.68))
		return
	_para(String(pg["glyph"]) + "︎  " + Almanac.t(pg["name"]), 40, col)
	_para(Almanac.t(pg["zone"]), 20, INK)
	_sep()
	_para(tr("THE MYTH"), 20, UI.GOLD)
	_para(Almanac.t(pg["myth"]), 18, UI.CREAM)
	_sep()
	_para(tr("THE GUARDIAN"), 20, UI.GOLD)
	if Almanac.defeated(s):
		var pt = load("res://scripts/portraits.gd").tex(s)
		if pt != null:
			var trc := TextureRect.new()
			trc.texture = pt
			trc.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			trc.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
			trc.custom_minimum_size = Vector2(300.0 * float(pt.get_width()) / float(maxi(pt.get_height(), 1)), 300)
			_page.add_child(trc)
		_para(Almanac.t(pg["boss"]), 24, col)
		_para(Almanac.t(pg["boss_d"]), 17, UI.CREAM)
	else:
		_para("? ? ?", 24, Color(0.45, 0.45, 0.52))
		_para(tr("Defeat this sign's boss to fill in this entry."), 17, Color(0.6, 0.6, 0.68))
	_sep()
	_para(tr("CREATURES"), 20, UI.GOLD)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 20)
	grid.add_theme_constant_override("v_separation", 12)
	_page.add_child(grid)
	for k in Almanac.KINDS:
		var cr: Array = pg["creatures"][k]
		var n := Almanac.kills(s, k)
		var box := VBoxContainer.new()
		box.custom_minimum_size = Vector2(470, 0)
		grid.add_child(box)
		var nm := UI.label(Almanac.t(cr[0]) if n > 0 else "? ? ?", 20, col if n > 0 else Color(0.45, 0.45, 0.52), 3)
		box.add_child(nm)
		var d := UI.label(Almanac.t(cr[1]) if n > 0 else tr("Defeat one to learn its secrets."), 16, UI.CREAM if n > 0 else Color(0.6, 0.6, 0.68), 3)
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		d.custom_minimum_size = Vector2(470, 0)
		box.add_child(d)
		if n > 0:
			box.add_child(UI.label(tr("Defeated: %d") % n, 15, INK, 3))


func _show_achievements() -> void:
	var Ach = load("res://scripts/achievements.gd")
	_para(tr("ACHIEVEMENTS"), 34, UI.GOLD)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 20)
	grid.add_theme_constant_override("v_separation", 10)
	_page.add_child(grid)
	for a in Ach.LIST:
		var got: bool = Ach.has(String(a["id"]))
		var col: Color = a["col"] if got else Color(0.45, 0.45, 0.52)
		var row := HBoxContainer.new()
		row.custom_minimum_size = Vector2(470, 0)
		row.add_theme_constant_override("separation", 12)
		grid.add_child(row)
		var g := UI.label(String(a["glyph"]) + "︎", 32, col, 3)
		g.add_theme_font_override("font", UI.symbol_font())
		g.custom_minimum_size = Vector2(44, 0)
		row.add_child(g)
		var vb := VBoxContainer.new()
		row.add_child(vb)
		vb.add_child(UI.label(Ach.t(a["name"]), 19, col, 3))
		var d := UI.label(Ach.t(a["desc"]), 15, UI.CREAM if got else Color(0.6, 0.6, 0.68), 3)
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		d.custom_minimum_size = Vector2(410, 0)
		vb.add_child(d)


func _process(_d: float) -> void:
	if visible and Input.is_action_just_pressed("ui_cancel"):
		visible = false
		closed.emit()
