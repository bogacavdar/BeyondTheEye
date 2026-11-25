extends CanvasLayer
## ARAYÜZ: can, öldürme, süre, silah, nişangâh, hasar efekti, ölüm ekranı.


class Crosshair extends Control:
	var base_color := Color(0.3, 1.0, 1.0)
	var hit_color := Color(1.0, 0.2, 0.3)
	var pulse := 0.0

	func _ready() -> void:
		set_anchors_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(delta: float) -> void:
		pulse = maxf(pulse - delta * 7.0, 0.0)
		queue_redraw()

	func _draw() -> void:
		var p := get_local_mouse_position()
		var c := base_color.lerp(hit_color, pulse)
		var r := 10.0 + pulse * 7.0
		draw_arc(p, r, 0.0, TAU, 32, c, 2.0, true)
		draw_circle(p, 2.0, c)
		for a in [0.0, PI * 0.5, PI, PI * 1.5]:
			var d := Vector2(cos(a), sin(a))
			draw_line(p + d * (r + 3.0), p + d * (r + 10.0), c, 2.0, true)


signal pause_toggled
signal menu_requested

const HP_W := 320.0
const UI = preload("res://scripts/ui_style.gd")

var pause_box: CenterContainer
var boss_timer_label: Label
var warn_label: Label
var warn_t := 0.0
var boss_root: Control
var boss_fill: ColorRect
var boss_name: Label
var boss_trail := 1.0
var boss_ratio := 1.0
var victory_box: CenterContainer
var victory_stats: Label
var over_bank: Label
const BOSS_W := 760.0

var hp_fill: ColorRect
var hp_label: Label
var kills_label: Label
var credits_label: Label
var credit_pulse := 0.0
var time_label: Label
var weapon_label: Label
var damage_rect: ColorRect
var over_box: CenterContainer
var over_stats: Label
var crosshair: Crosshair
var dmg_alpha := 0.0


func _ready() -> void:
	add_to_group("hud")
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS  # oyun duraklatılınca da çalışsın

	damage_rect = ColorRect.new()
	damage_rect.color = Color(0.8, 0.0, 0.08, 0.0)
	damage_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	damage_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(damage_rect)

	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.6)
	bg.position = Vector2(24, 24)
	bg.size = Vector2(HP_W + 6.0, 22)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	hp_fill = ColorRect.new()
	hp_fill.color = Color(0.2, 1.0, 0.9)
	hp_fill.position = Vector2(27, 27)
	hp_fill.size = Vector2(HP_W, 16)
	hp_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hp_fill)

	hp_label = _label(Vector2(28, 50), 20)
	credits_label = _label(Vector2(28, 80), 30, Color(1.0, 0.78, 0.2))
	kills_label = _label(Vector2(28, 120), 24, Color(1.0, 0.35, 0.5))
	time_label = _label(Vector2(28, 154), 22)
	weapon_label = _label(Vector2(28, 186), 22, Color(0.3, 1.0, 1.0))
	var help := _label(Vector2(28, 220), 16, Color(0.7, 0.7, 0.8))
	help.text = "WASD hareket  •  Mouse nişan  •  Sol tık ateş  •  Boşluk atılma  •  1-8 / tekerlek silah  •  Esc duraklat"

	over_box = CenterContainer.new()
	over_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	over_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	over_box.visible = false
	add_child(over_box)
	var vb := VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	over_box.add_child(vb)
	var title := _make_label(84, Color(1.0, 0.15, 0.3))
	title.text = "ÖLDÜN"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(title)
	over_stats = _make_label(30, Color(0.9, 0.95, 1.0))
	over_stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(over_stats)
	var hint := _make_label(22, Color(0.3, 1.0, 1.0))
	over_bank = _make_label(26, Color(1.0, 0.78, 0.2))
	over_bank.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(over_bank)
	hint.text = "R  yeniden başla     •     M  ana menü (Laboratuvar)"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(hint)

	# boss geri sayımı (sağ üst)
	boss_timer_label = _make_label(26, Color(1.0, 0.3, 0.4))
	boss_timer_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	boss_timer_label.offset_left = -360.0
	boss_timer_label.offset_top = 26.0
	add_child(boss_timer_label)

	# ortada büyük uyarı yazısı
	warn_label = _make_label(54, Color(1.0, 0.15, 0.25))
	warn_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	warn_label.offset_left = -600.0
	warn_label.offset_right = 600.0
	warn_label.offset_top = 180.0
	warn_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	warn_label.visible = false
	add_child(warn_label)

	# boss can barı (üst orta)
	boss_root = Control.new()
	boss_root.set_anchors_preset(Control.PRESET_CENTER_TOP)
	boss_root.offset_left = -BOSS_W * 0.5
	boss_root.offset_top = 70.0
	boss_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_root.visible = false
	add_child(boss_root)
	boss_name = _make_label(30, Color(1.0, 0.35, 0.5))
	boss_name.position = Vector2(0, -42)
	boss_root.add_child(boss_name)
	var bb := ColorRect.new()
	bb.color = Color(0, 0, 0, 0.7)
	bb.size = Vector2(BOSS_W + 8.0, 26)
	bb.position = Vector2(-4, -4)
	bb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_root.add_child(bb)
	var trail := ColorRect.new()
	trail.name = "Trail"
	trail.color = Color(1.0, 0.9, 0.9)
	trail.size = Vector2(BOSS_W, 18)
	trail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_root.add_child(trail)
	boss_fill = ColorRect.new()
	boss_fill.color = Color(0.85, 0.05, 0.2)
	boss_fill.size = Vector2(BOSS_W, 18)
	boss_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_root.add_child(boss_fill)

	crosshair = Crosshair.new()
	add_child(crosshair)

	# zafer ekranı
	victory_box = CenterContainer.new()
	victory_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	victory_box.visible = false
	add_child(victory_box)
	var vp := UI.panel(Color(0.3, 1.0, 0.5))
	victory_box.add_child(vp)
	var vv := VBoxContainer.new()
	vv.add_theme_constant_override("separation", 16)
	vp.add_child(vv)
	var vt := UI.label("BÖLGE TEMİZLENDİ", 60, Color(0.3, 1.0, 0.5), 10)
	vt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vv.add_child(vt)
	victory_stats = UI.label("", 26, Color(0.9, 0.95, 1.0), 6)
	victory_stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vv.add_child(victory_stats)
	var vr := HBoxContainer.new()
	vr.add_theme_constant_override("separation", 16)
	vr.alignment = BoxContainer.ALIGNMENT_CENTER
	vv.add_child(vr)
	var b_again := UI.button("TEKRAR OYNA", 24, Color(0.3, 1.0, 0.5))
	b_again.pressed.connect(func(): get_tree().reload_current_scene())
	vr.add_child(b_again)
	var b_lab := UI.button("ANA MENÜ / LABORATUVAR", 24, Color(1.0, 0.2, 0.55))
	b_lab.custom_minimum_size = Vector2(420, 56)
	b_lab.pressed.connect(func(): menu_requested.emit())
	vr.add_child(b_lab)

	# duraklatma menüsü
	pause_box = CenterContainer.new()
	pause_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_box.visible = false
	add_child(pause_box)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pause_box.add_child(dim)
	var panel := UI.panel(Color(0.3, 1.0, 1.0))
	pause_box.add_child(panel)
	var pv := VBoxContainer.new()
	pv.add_theme_constant_override("separation", 16)
	panel.add_child(pv)
	var pt := UI.label("DURAKLATILDI", 48, Color(0.3, 1.0, 1.0), 8)
	pt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pv.add_child(pt)
	var b_resume := UI.button("DEVAM", 28, Color(0.3, 1.0, 0.5))
	b_resume.pressed.connect(func(): pause_toggled.emit())
	pv.add_child(b_resume)
	var b_menu := UI.button("ANA MENÜ", 24, Color(1.0, 0.2, 0.55))
	b_menu.pressed.connect(func(): menu_requested.emit())
	pv.add_child(b_menu)
	var b_quit := UI.button("OYUNDAN ÇIK", 24, Color(1.0, 0.2, 0.55))
	b_quit.pressed.connect(func(): get_tree().quit())
	pv.add_child(b_quit)


func _make_label(size: int, color: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	l.add_theme_constant_override("outline_size", 6)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _label(pos: Vector2, size: int, color := Color(0.85, 0.95, 1.0)) -> Label:
	var l := _make_label(size, color)
	l.position = pos
	add_child(l)
	return l


func show_pause(on: bool) -> void:
	pause_box.visible = on
	crosshair.visible = not on


func _process(delta: float) -> void:
	if warn_t > 0.0:
		warn_t -= delta
		warn_label.visible = warn_t > 0.0 and fmod(warn_t, 0.5) > 0.15
	boss_trail = move_toward(boss_trail, boss_ratio, delta * 0.4)
	var tr := boss_root.get_node_or_null("Trail") as ColorRect
	if tr != null:
		tr.size.x = BOSS_W * boss_trail
	if Input.is_action_just_pressed("pause") and not over_box.visible and not victory_box.visible:
		pause_toggled.emit()
	dmg_alpha = maxf(dmg_alpha - delta * 2.0, 0.0)
	damage_rect.color.a = dmg_alpha
	credit_pulse = maxf(credit_pulse - delta * 6.0, 0.0)
	credits_label.scale = Vector2.ONE * (1.0 + credit_pulse * 0.25)
	credits_label.modulate = Color(1, 1, 1).lerp(Color(1.6, 1.4, 0.8), credit_pulse)


func set_hp(hp: float, max_hp: float) -> void:
	var r := clampf(hp / max_hp, 0.0, 1.0)
	hp_fill.size.x = HP_W * r
	hp_fill.color = Color(1.0, 0.2, 0.3).lerp(Color(0.2, 1.0, 0.9), r)
	hp_label.text = "CAN  %d / %d" % [int(ceil(hp)), int(max_hp)]


func set_credits(c: int) -> void:
	credits_label.text = "KREDİ  %d" % c
	if c > 0:
		credit_pulse = 1.0


func set_kills(k: int) -> void:
	kills_label.text = "ÖLDÜRME  %d" % k


func set_time(t: float) -> void:
	time_label.text = "SÜRE  " + _fmt(t)


func set_weapon(n: String) -> void:
	weapon_label.text = "SİLAH  " + n


func hit_marker() -> void:
	crosshair.pulse = 1.0


func flash_damage() -> void:
	dmg_alpha = 0.35


func set_boss_timer(t: float) -> void:
	boss_timer_label.text = "KOVAN ANASI  " + _fmt(t)


func warn(text: String, duration := 4.0) -> void:
	warn_label.text = text
	warn_t = duration


func show_boss(boss_title: String) -> void:
	boss_timer_label.visible = false
	boss_name.text = boss_title
	boss_root.visible = true
	boss_ratio = 1.0
	boss_trail = 1.0
	warn(boss_title, 2.5)


func set_boss_hp(hp: float, max_hp: float) -> void:
	boss_ratio = clampf(hp / max_hp, 0.0, 1.0)
	boss_fill.size.x = BOSS_W * boss_ratio
	if boss_ratio <= 0.0:
		boss_root.visible = false


func show_victory(kills: int, t: float, credits: int, reward: int, bank: int) -> void:
	crosshair.visible = false
	victory_stats.text = "Öldürme: %d   |   Süre: %s\nKredi: %d  (boss ödülü +%d dahil)\nBankadaki toplam kredi: %d" % [kills, _fmt(t), credits, reward, bank]
	victory_box.visible = true


func show_game_over(kills: int, t: float, credits := 0, bank := 0) -> void:
	crosshair.visible = false
	over_stats.text = "Öldürme: %d   |   Süre: %s   |   Kredi: %d" % [kills, _fmt(t), credits]
	over_bank.text = "Krediler bankaya eklendi. Toplam: %d  —  Laboratuvarda harca!" % bank
	over_box.visible = true


func _fmt(t: float) -> String:
	var s := int(t)
	return "%02d:%02d" % [s / 60, s % 60]
