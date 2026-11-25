extends Control
## GÖK KADRANI: retroları ve tutulmaları aç/kapat. Her satırda gezegen sembolü, ad, açıklama,
## kademe noktaları ve - / + düğmeleri. Üstte toplam retro seviyesi, toz ödülü ve Koç rekoru.

signal closed

const GameData = preload("res://scripts/game_data.gd")
const UI = preload("res://scripts/ui_style.gd")
const Retro = preload("res://scripts/retro.gd")

var _list: VBoxContainer
var _head: Label
var _sub: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = UI.theme()
	var bg := ColorRect.new()
	bg.color = Color(0.01, 0.015, 0.05, 0.82)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var cc := CenterContainer.new()
	cc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(cc)
	var p := UI.panel(Color(1.0, 0.45, 0.35))
	cc.add_child(p)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	vb.custom_minimum_size = Vector2(900, 0)
	p.add_child(vb)
	var t := UI.label("SKY DIAL", 40)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t)
	var d := UI.label("Retrogrades and eclipses: optional curses for those who seek a harder sky", 17, UI.CREAM)
	d.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(d)
	vb.add_child(UI.divider(320))
	_head = UI.label("", 26, Color(1.0, 0.55, 0.45))
	_head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(_head)
	_sub = UI.label("", 17, UI.CREAM)
	_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(_sub)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 6)
	vb.add_child(_list)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 20)
	vb.add_child(row)
	var clear := UI.button("CLEAR ALL", 20)
	clear.pressed.connect(_clear_all)
	row.add_child(clear)
	var close := UI.button("CLOSE", 20)
	close.pressed.connect(_close)
	row.add_child(close)
	refresh()


func _process(_d: float) -> void:
	if visible and Input.is_action_just_pressed("ui_cancel"):
		_close()


func _close() -> void:
	GameData.go_save()
	closed.emit()


func _clear_all() -> void:
	GameData.retro = {}
	Sfx.play("switch", -10.0, 0.0, 0, 0.8)
	refresh()


func _change(id: String, delta: int) -> void:
	var c := Retro.info(id)
	var r := clampi(Retro.rank(GameData.retro, id) + delta, 0, int(c["max"]))
	GameData.retro[id] = r
	Sfx.play("switch", -10.0, 0.0, 0, 1.2 if delta > 0 else 0.8)
	refresh()


func refresh() -> void:
	var h := Retro.heat(GameData.retro)
	_head.text = tr("RETRO LEVEL %d / %d") % [h, Retro.max_heat()]
	var best := tr("Aries not yet defeated") if GameData.aries_best_heat < 0 else tr("Aries defeated at retro level %d") % GameData.aries_best_heat
	_sub.text = tr("Stardust reward +%d%%") % (h * 10) + "   ·   " + best
	for ch in _list.get_children():
		ch.queue_free()
	for c in Retro.CURSES:
		_list.add_child(_row(c))


func _row(c: Dictionary) -> Control:
	var id := String(c["id"])
	var rk := Retro.rank(GameData.retro, id)
	var mx := int(c["max"])
	var lit := rk > 0
	var box := PanelContainer.new()
	var red := Color(1.0, 0.45, 0.35)
	box.add_theme_stylebox_override("panel", UI.box(Color(0.12, 0.04, 0.08, 0.9) if lit else Color(0.04, 0.06, 0.15, 0.9), red if lit else Color(UI.GOLD.r, UI.GOLD.g, UI.GOLD.b, 0.35), 2 if lit else 1, 12))
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 14)
	box.add_child(hb)
	var g := UI.label(String(c["glyph"]) + "︎", 34, red if lit else UI.GOLD_DIM, 0)
	g.add_theme_font_override("font", UI.symbol_font())
	g.custom_minimum_size = Vector2(46, 0)
	g.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hb.add_child(g)
	var tv := VBoxContainer.new()
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv.add_theme_constant_override("separation", 0)
	hb.add_child(tv)
	tv.add_child(UI.label(String(c["name"]), 20, red if lit else UI.GOLD))
	var dl := UI.label(String(c["desc"]), 15, UI.CREAM)
	tv.add_child(dl)
	# kademe noktaları
	var pips := ""
	for k in mx:
		pips += "◆ " if k < rk else "◇ "
	var pl := UI.label(pips.strip_edges(), 20, red if lit else UI.GOLD_DIM)
	pl.add_theme_font_override("font", UI.symbol_font())
	pl.custom_minimum_size = Vector2(80, 0)
	pl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hb.add_child(pl)
	var heat_l := UI.label("+%d" % int(c["heat"]), 16, UI.CREAM)
	heat_l.custom_minimum_size = Vector2(34, 0)
	hb.add_child(heat_l)
	var minus := UI.button("-", 20)
	minus.custom_minimum_size = Vector2(44, 40)
	minus.disabled = rk <= 0
	minus.pressed.connect(_change.bind(id, -1))
	hb.add_child(minus)
	var plus := UI.button("+", 20)
	plus.custom_minimum_size = Vector2(44, 40)
	plus.disabled = rk >= mx
	plus.pressed.connect(_change.bind(id, 1))
	hb.add_child(plus)
	return box
