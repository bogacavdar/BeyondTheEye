extends Control
## DÖVÜŞ ARAYÜZÜ
## Sol üst: can (altın çerçeveli bar) ve yıldız tozu. Üst orta: dalga.
## Alt orta: 3 yetenek (1, 2, 3) + atılma ve parry; bekleme süresi dolan dilim olarak görünür.
## Vurulunca ekran kenarları kısa süre kızıl yanar. Oda bitince/ölünce ortada büyük yazı.

const UI = preload("res://scripts/ui_style.gd")
const Boons = preload("res://scripts/boons.gd")
const GameData = preload("res://scripts/game_data.gd")
const Elements = preload("res://scripts/elements.gd")
var zone_el := ""          # bu bölgenin elementi (room.gd verir)

var hero = null
var dust := 0
var wave := 0
var wave_total := 1
var room := 1
var room_total := 3
var reward := ""
var hub_mode := false    # Gözlemevi: sadece yetenek çubuğu
var boss = null
var _boss_shown := 1.0
var prompt := ""
var prompt_glyph := ""
var prompt_color := Color(0.95, 0.82, 0.45)
var _font: Font
var _sym: Font
var _hurt := 0.0
var _banner_t := 0.0
var _banner_a := ""
var _banner_b := ""
var _dead_t := -1.0
var _dead_earned := 0
var _t := 0.0
var _hp_shown := 1.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_font = UI.font()
	_sym = UI.symbol_font()


func hurt_flash() -> void:
	_hurt = 1.0


func banner(a: String, b := "") -> void:
	_banner_a = a
	_banner_b = b
	_banner_t = 4.0


func death_screen(earned: int) -> void:
	_dead_t = 0.0
	_dead_earned = earned


func _process(delta: float) -> void:
	_t += delta
	var vs := get_viewport_rect().size
	position = Vector2.ZERO
	size = vs
	_hurt = maxf(_hurt - delta * 2.2, 0.0)
	_banner_t = maxf(_banner_t - delta, 0.0)
	if _dead_t >= 0.0:
		_dead_t += delta
	if hero != null and is_instance_valid(hero):
		_hp_shown = lerpf(_hp_shown, hero.hp / hero.max_hp, minf(6.0 * delta, 1.0))
	queue_redraw()


func _text(s: String, pos: Vector2, fsize: int, col: Color, center := true, f: Font = null) -> void:
	var ff := f if f != null else _font
	var w := ff.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize).x
	var x := pos.x - (w * 0.5 if center else 0.0)
	draw_string_outline(ff, Vector2(x, pos.y), s, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, 6, Color(0.02, 0.03, 0.1, 0.85))
	draw_string(ff, Vector2(x, pos.y), s, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, col)


func _a(c: Color, a: float) -> Color:
	return Color(c.r, c.g, c.b, a)


func _draw() -> void:
	if hero == null or not is_instance_valid(hero):
		return
	if hub_mode:
		if GameData.input_mode != "touch":
			_draw_slots()
		return
	var gold := UI.GOLD
	# --- vurulma kenarı
	if _hurt > 0.0:
		var e := 90.0
		var c := Color(0.75, 0.1, 0.15, 0.45 * _hurt)
		draw_rect(Rect2(0, 0, size.x, e), c)
		draw_rect(Rect2(0, size.y - e, size.x, e), c)
		draw_rect(Rect2(0, 0, e, size.y), c)
		draw_rect(Rect2(size.x - e, 0, e, size.y), c)

	# --- can
	var bx := Vector2(40, 40)
	var bw := 360.0
	var bh := 22.0
	draw_rect(Rect2(bx - Vector2(4, 4), Vector2(bw + 8, bh + 8)), Color(0.02, 0.03, 0.1, 0.85))
	var frac := clampf(hero.hp / hero.max_hp, 0.0, 1.0)
	draw_rect(Rect2(bx, Vector2(bw * _hp_shown, bh)), Color(1.0, 0.95, 0.8, 0.6))
	var col := gold if frac > 0.3 else Color(1.0, 0.45 + 0.2 * sin(_t * 8.0), 0.35)
	draw_rect(Rect2(bx, Vector2(bw * frac, bh)), col)
	if hero.shield > 0.0:
		var sf := clampf(hero.shield / hero.max_hp, 0.0, 1.0)
		draw_rect(Rect2(bx + Vector2(0, bh - 6.0), Vector2(bw * sf, 6.0)), Color(0.6, 0.85, 1.0))
	draw_rect(Rect2(bx - Vector2(4, 4), Vector2(bw + 8, bh + 8)), gold, false, 2.0)
	_text("%d / %d" % [int(ceil(hero.hp)), int(hero.max_hp)], bx + Vector2(bw * 0.5, bh - 3.0), 18, UI.CREAM)
	_text(tr("%d stardust") % dust, bx + Vector2(0, bh + 38.0), 20, UI.CREAM, false)
	_draw_elements(bx + Vector2(0, bh + 68.0))

	# --- dalga
	if boss != null and is_instance_valid(boss) and not boss.dead:
		_draw_boss_bar()
	else:
		_text(tr("CHAMBER %d / %d") % [room, room_total], Vector2(size.x * 0.5, 44), 26, gold)
	_draw_reward_and_boons()
	if wave > 0 and boss == null:
		_text(tr("WAVE %d / %d") % [mini(wave, wave_total), wave_total], Vector2(size.x * 0.5, 74), 18, _a(UI.CREAM, 0.85))

	if GameData.input_mode != "touch":
		_draw_slots()

	# --- etkileşim ipucu
	if prompt != "":
		_draw_prompt()

	# --- büyük duyuru
	if _banner_t > 0.0:
		var a := clampf(_banner_t, 0.0, 1.0) * clampf((4.0 - _banner_t) * 3.0, 0.0, 1.0)
		_text(tr(_banner_a), Vector2(size.x * 0.5, size.y * 0.32), 56, _a(gold, a))
		if _banner_b != "":
			_text(_banner_b, Vector2(size.x * 0.5, size.y * 0.32 + 48.0), 24, _a(UI.CREAM, a))

	# --- ölüm ekranı
	if _dead_t >= 0.0:
		var a := clampf(_dead_t * 1.2, 0.0, 1.0)
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.01, 0.015, 0.05, 0.7 * a))
		_text(tr("THE STARS DIM"), Vector2(size.x * 0.5, size.y * 0.45), 64, _a(gold, a))
		_text(tr("Stardust gathered: %d") % _dead_earned, Vector2(size.x * 0.5, size.y * 0.45 + 56.0), 24, _a(UI.CREAM, a))
		_text(tr("Light new stars in your Birth Chart and return stronger"), Vector2(size.x * 0.5, size.y * 0.45 + 100.0), 20, _a(gold, a * 0.85))

	# --- kontroller (ilk saniyelerde)
	if _t < 15.0:
		var a := clampf(15.0 - _t, 0.0, 1.0)
		var hint_txt := tr("LMB attack  ·  Q heavy  ·  RMB parry (gold warnings)  ·  Space dash (red warnings)  ·  Shift sprint  ·  1 2 3 skills")
		if GameData.input_mode == "pad":
			hint_txt = tr("X attack  ·  Y heavy  ·  B parry (gold warnings)  ·  A dash (red warnings)  ·  LT sprint  ·  LB RB RT skills")
		if GameData.input_mode != "touch":
			_text(hint_txt, Vector2(size.x * 0.5, size.y - 18.0), 16, _a(UI.CREAM, 0.75 * a))


## Element bilgisi: senin elementin (lütuflardan) ve bölgenin elementi; üstünlük durumu
func _draw_elements(p: Vector2) -> void:
	var he := GameData.hero_el
	if zone_el != "":
		var zi: Dictionary = Elements.INFO[zone_el]
		_text(tr("Foes: %s") % tr(String(zi["name"])), p, 19, zi["col"], false)
		p.y += 24.0
	if he == "":
		_text(tr("Your element: none (take planet blessings)"), p, 16, _a(UI.CREAM, 0.6), false)
		return
	var hi: Dictionary = Elements.INFO[he]
	var line := tr("Your element: %s ×%d") % [tr(String(hi["name"])), mini(GameData.hero_el_n, 3)]
	_text(line, p, 19, hi["col"], false)
	if zone_el != "":
		var m: float = Elements.mult(he, GameData.hero_el_n, zone_el)
		if m > 1.0:
			_text(tr("STRONG  +%d%%") % int(round((m - 1.0) * 100.0)), p + Vector2(0, 24), 17, Color(0.6, 1.0, 0.5), false)
		elif m < 1.0:
			_text(tr("WEAK  -%d%%") % int(round((1.0 - m) * 100.0)), p + Vector2(0, 24), 17, Color(1.0, 0.5, 0.4), false)


func _draw_slots() -> void:
	var gold := UI.GOLD
	# --- yetenekler ve hareketler: simge, üstünde tuş rozeti, altında çerçeveli ad kutusu
	var slots := [
		["1", 0, "starfall", ""], ["2", 1, "wave", ""], ["3", 2, "path", ""], ["Q", -3, "heavy", "HEAVY ATTACK"],
		["SPACE", -1, "dash", "DASH"], ["RMB", -2, "parry", "PARRY"],
	]
	if GameData.input_mode == "pad":
		var pk := ["LB", "RB", "RT", "Y", "A", "B"]
		for i in slots.size():
			slots[i][0] = pk[i]
	var sw := 72.0
	var gap := 80.0
	var total := sw * slots.size() + gap * (slots.size() - 1) + 30.0
	var x0 := size.x * 0.5 - total * 0.5
	var y0 := size.y - 158.0
	var back := Rect2(x0 - 22.0, y0 - 26.0, total + 44.0, sw + 26.0 + 10.0 + 50.0 + 14.0)
	draw_rect(back, Color(0.02, 0.03, 0.1, 0.55))
	draw_rect(back, _a(gold, 0.35), false, 1.0)
	for i in slots.size():
		var sl: Array = slots[i]
		var x := x0 + float(i) * (sw + gap) + (30.0 if i >= 4 else 0.0)
		var c := Vector2(x + sw * 0.5, y0 + sw * 0.5)
		var frac_cd := 0.0
		var idx: int = sl[1]
		var name_txt := tr(String(sl[3]))
		if idx >= 0:
			frac_cd = float(hero.skill_cd[idx]) / float(hero.SKILL_CD[idx])
			name_txt = tr(String(hero.kit["skills"][idx]["name"]))
		elif idx == -3:
			frac_cd = clampf(hero.heavy_cd / hero.heavy_cd_max, 0.0, 1.0) if hero.heavy_cd_max > 0.0 else 0.0
		elif idx == -1:
			frac_cd = clampf(hero.dash_cd / hero.DASH_COOLDOWN, 0.0, 1.0)
		else:
			frac_cd = clampf(hero._parry_cd / hero.PARRY_COOLDOWN, 0.0, 1.0)
		var is_ready := frac_cd <= 0.0
		draw_circle(c, sw * 0.5 + 3.0, Color(0.02, 0.03, 0.1, 0.9))
		draw_circle(c, sw * 0.5, Color(0.05, 0.08, 0.2, 0.95))
		var icon_kind := String(sl[2])
		if idx >= 0:
			icon_kind = String(hero.kit["skills"][idx]["type"])
		_icon(icon_kind, c, sw * 0.28, gold if is_ready else _a(gold, 0.35))
		if not is_ready:
			# kalan süre: saat yönünde azalan karanlık dilim
			var pts := PackedVector2Array([c])
			var n := 32
			for k in n + 1:
				var a := -PI * 0.5 + TAU * frac_cd * float(k) / float(n)
				pts.append(c + Vector2(cos(a), sin(a)) * (sw * 0.5 - 2.0))
			if pts.size() >= 3:
				draw_colored_polygon(pts, Color(0.0, 0.0, 0.05, 0.55))
		draw_arc(c, sw * 0.5, 0.0, TAU, 48, gold if is_ready else _a(gold, 0.45), 3.0 if is_ready else 1.5, true)
		_key_badge(tr(String(sl[0])), c + Vector2(0, -sw * 0.5 - 2.0), is_ready)
		_name_box(name_txt, Vector2(c.x, y0 + sw + 10.0), sw + gap - 10.0, is_ready)


## Simgenin üstündeki tuş rozeti
func _key_badge(t: String, center: Vector2, lit: bool) -> void:
	var fs := 14
	var w := maxf(_font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + 16.0, 76.0)
	var r := Rect2(center.x - w * 0.5, center.y - 12.0, w, 24.0)
	draw_rect(r, Color(0.08, 0.1, 0.26, 0.98))
	draw_rect(r, UI.GOLD if lit else _a(UI.GOLD, 0.5), false, 1.5)
	_text(t, Vector2(center.x, center.y + 6.0), fs, UI.CREAM)


## Simgenin altındaki çerçeveli ad kutusu (uzun adlar iki satıra bölünür)
func _name_box(t: String, top_center: Vector2, max_w: float, lit: bool) -> void:
	var fs := 14
	var lines: Array = []
	var words := t.split(" ")
	var line := ""
	for wd in words:
		var test: String = wd if line == "" else line + " " + wd
		if _font.get_string_size(test, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > max_w - 16.0 and line != "":
			lines.append(line)
			line = wd
		else:
			line = test
	if line != "":
		lines.append(line)
	# hepsi aynı boy: sabit genişlik, iki satırlık sabit yükseklik, yazı dikeyde ortalı
	var w := max_w - 6.0
	var h := 50.0
	var r := Rect2(top_center.x - w * 0.5, top_center.y, w, h)
	draw_rect(r, Color(0.03, 0.045, 0.13, 0.95))
	draw_rect(r, UI.GOLD if lit else _a(UI.GOLD, 0.45), false, 1.5)
	var lh := 19.0
	var y0 := top_center.y + h * 0.5 - lh * float(lines.size()) * 0.5 + 14.0
	for k in lines.size():
		_text(String(lines[k]), Vector2(top_center.x, y0 + lh * float(k)), fs, UI.GOLD if lit else _a(UI.CREAM, 0.6))


## Kapı ipucu: çerçeveli kutu, E tuşu, ödül sembolü ve adı
func _draw_prompt() -> void:
	var gold := UI.GOLD
	var txt := tr(prompt)
	var fs := 32
	var tw := _font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var glyph_w := 56.0 if prompt_glyph != "" else 0.0
	var key_w := 52.0
	var pad := 26.0
	var w := pad + key_w + 18.0 + glyph_w + tw + pad
	var h := 70.0
	var pulse := 0.75 + 0.25 * sin(_t * 4.0)
	var r := Rect2(size.x * 0.5 - w * 0.5, size.y - 270.0, w, h)
	draw_rect(r.grow(6.0), Color(prompt_color.r, prompt_color.g, prompt_color.b, 0.18 * pulse))
	draw_rect(r, Color(0.03, 0.045, 0.13, 0.95))
	draw_rect(r, gold, false, 2.5)
	# E tuşu
	var kx := r.position.x + pad
	var kr := Rect2(kx, r.position.y + (h - 44.0) * 0.5, key_w - 8.0, 44.0)
	draw_rect(kr, Color(0.1, 0.12, 0.3))
	draw_rect(kr, gold, false, 2.0)
	_text("E", kr.get_center() + Vector2(0, 10), 26, gold)
	var x := kx + key_w + 18.0
	if prompt_glyph != "":
		_text(prompt_glyph + "\uFE0E", Vector2(x + 22.0, r.position.y + h * 0.5 + 14.0), 38, prompt_color, true, _sym)
		x += glyph_w
	_text(txt, Vector2(x, r.position.y + h * 0.5 + 11.0), fs, gold, false)


func _draw_boss_bar() -> void:
	var gold := UI.GOLD
	var w := minf(size.x * 0.5, 820.0)
	var x := size.x * 0.5 - w * 0.5
	var y := 52.0
	var h := 20.0
	_boss_shown = lerpf(_boss_shown, boss.hp / boss.max_hp, 0.08)
	var f := clampf(boss.hp / boss.max_hp, 0.0, 1.0)
	draw_rect(Rect2(x - 4, y - 4, w + 8, h + 8), Color(0.02, 0.03, 0.1, 0.9))
	draw_rect(Rect2(x, y, w * clampf(_boss_shown, 0.0, 1.0), h), Color(1.0, 0.9, 0.7, 0.5))
	draw_rect(Rect2(x, y, w * f, h), Color(0.85, 0.2, 0.12) if boss.phase < 3 else Color(1.0, 0.1 + 0.15 * sin(_t * 10.0), 0.08))
	# evre işaretleri (%60, %25)
	var bkind := String(boss.get("kind")) if boss.get("kind") != null else "aries"
	var marks: Array = [0.65, 0.3] if bkind in ["taurus", "cancer", "leo", "virgo"] else ([0.6, 0.3] if bkind == "gemini" else [0.6, 0.25])
	for m in marks:
		draw_line(Vector2(x + w * m, y - 4), Vector2(x + w * m, y + h + 4), gold, 2.0)
	draw_rect(Rect2(x - 4, y - 4, w + 8, h + 8), gold, false, 2.0)
	var bg := {"aries": "\u2648", "taurus": "\u2649", "gemini": "\u264A", "cancer": "\u264B", "leo": "\u264C", "virgo": "\u264D"}
	var bk = boss.get("kind")
	_text(String(bg.get(String(bk) if bk != null else "aries", "\u2648")) + "\uFE0E", Vector2(x - 34, y + 18), 30, gold, true, _sym)
	var btitle: String = String(boss.get("title")) if boss.get("title") != null else "ARIES  ·  THE RAM'S FURY"
	_text(tr(btitle), Vector2(size.x * 0.5, y - 12), 22, gold)


## Sağ üst: bu odanın ödülü ve alınan lütuflar
func _draw_reward_and_boons() -> void:
	var gold := UI.GOLD
	var x := size.x - 40.0
	var y := 46.0
	if reward.begins_with("boon:"):
		var pl: Dictionary = Boons.PLANETS.get(reward.substr(5), {})
		if not pl.is_empty():
			var col: Color = pl["color"]
			_text(tr("REWARD"), Vector2(x - 120, y), 14, _a(UI.CREAM, 0.7))
			_text(String(pl["glyph"]) + "\uFE0E", Vector2(x - 20, y + 6), 32, col, true, _sym)
	elif reward == "weapon":
		_text(tr("REWARD"), Vector2(x - 120, y), 14, _a(UI.CREAM, 0.7))
		_text("\u2605\uFE0E", Vector2(x - 20, y + 6), 30, hero.kit["color"] if hero != null else gold, true, _sym)
	elif reward == "dust":
		_text(tr("REWARD"), Vector2(x - 120, y), 14, _a(UI.CREAM, 0.7))
		_text("\u2726\uFE0E", Vector2(x - 20, y + 6), 30, gold, true, _sym)
	# alınan lütuflar: gezegen sembolleri sıra halinde
	var bx := x - 20.0
	var by := y + 50.0
	var i := 0
	for id in GameData.run_boons:
		var b := Boons.get_boon(String(id))
		if b.is_empty():
			continue
		var pl2: Dictionary = Boons.PLANETS[b["planet"]]
		_text(String(pl2["glyph"]) + "\uFE0E", Vector2(bx - float(i % 6) * 30.0, by + float(i / 6) * 32.0), 24, pl2["color"], true, _sym)
		i += 1


## Basit çizilmiş simgeler
func _icon(kind: String, c: Vector2, r: float, col: Color) -> void:
	match kind:
		"starfall":
			# düşen yıldız: yıldız + kuyruk
			draw_line(c + Vector2(-r * 1.0, -r * 1.0), c + Vector2(-r * 0.2, -r * 0.2), col, 2.0, true)
			draw_line(c + Vector2(-r * 0.6, -r * 1.1), c + Vector2(0, -r * 0.4), _a(col, col.a * 0.6), 1.5, true)
			draw_colored_polygon(_star(c + Vector2(r * 0.25, r * 0.25), r * 0.75, r * 0.32, 5), col)
		"wave":
			# hilal
			draw_arc(c, r, -PI * 0.75, PI * 0.75, 24, col, 4.0, true)
			draw_arc(c + Vector2(-r * 0.25, 0), r * 0.85, -PI * 0.6, PI * 0.6, 24, _a(col, col.a * 0.5), 2.0, true)
		"path":
			# birbirine bağlı üç yıldız
			var p1 := c + Vector2(-r, r * 0.5)
			var p2 := c + Vector2(0, -r * 0.6)
			var p3 := c + Vector2(r, r * 0.3)
			draw_line(p1, p2, col, 2.0, true)
			draw_line(p2, p3, col, 2.0, true)
			for p in [p1, p2, p3]:
				draw_colored_polygon(_star(p, r * 0.35, r * 0.15, 4), col)
		"boomerang":
			draw_arc(c, r, -0.4, PI + 0.4, 24, col, 4.0, true)
			draw_arc(c + Vector2(0, r * 0.35), r * 0.75, -0.2, PI + 0.2, 24, _a(col, col.a * 0.5), 2.0, true)
		"vortex":
			for k in 3:
				draw_arc(c, r * (0.35 + 0.3 * float(k)), float(k) * 2.1, float(k) * 2.1 + 3.6, 20, col, 2.5, true)
		"eclipse":
			draw_circle(c, r * 0.85, col)
			draw_circle(c + Vector2(r * 0.35, -r * 0.15), r * 0.75, Color(0.05, 0.08, 0.2))
			draw_arc(c, r * 1.05, 0.0, TAU, 32, _a(col, col.a * 0.6), 1.5, true)
		"cone", "burst_self", "aura":
			if kind == "cone":
				var pts := PackedVector2Array([c + Vector2(-r, r * 0.1), c + Vector2(r, -r * 0.7), c + Vector2(r, r * 0.9)])
				draw_colored_polygon(pts, _a(col, col.a * 0.8))
			else:
				draw_circle(c, r * 0.45, col)
				for k in 8:
					var a := TAU * float(k) / 8.0
					draw_line(c + Vector2(cos(a), sin(a)) * r * 0.6, c + Vector2(cos(a), sin(a)) * r * 1.0, col, 2.0, true)
		"charge", "leap", "disengage":
			draw_line(c + Vector2(-r, r * 0.6), c + Vector2(r * 0.8, -r * 0.6), col, 3.5, true)
			draw_colored_polygon(PackedVector2Array([c + Vector2(r, -r * 0.75), c + Vector2(r * 0.3, -r * 0.65), c + Vector2(r * 0.75, -r * 0.05)]), col)
		"line":
			for k in 4:
				draw_circle(c + Vector2(-r + float(k) * r * 0.66, r * 0.4 - float(k) * r * 0.28), r * (0.14 + 0.05 * float(k)), col)
		"hook":
			draw_line(c + Vector2(-r, r), c + Vector2(r * 0.2, -r * 0.2), col, 2.5, true)
			draw_arc(c + Vector2(r * 0.45, -r * 0.2), r * 0.35, PI, TAU + 0.8, 16, col, 3.0, true)
		"orbit":
			draw_arc(c, r * 0.85, 0.0, TAU, 32, _a(col, col.a * 0.6), 1.5, true)
			draw_circle(c, r * 0.3, col)
			draw_circle(c + Vector2(r * 0.85, 0), r * 0.22, col)
			draw_circle(c - Vector2(r * 0.85, 0), r * 0.22, col)
		"dash":
			for k in 3:
				var o := float(k) * r * 0.45
				draw_line(c + Vector2(-r + o, -r * 0.6), c + Vector2(-r * 0.2 + o, 0), col, 2.5, true)
				draw_line(c + Vector2(-r * 0.2 + o, 0), c + Vector2(-r + o, r * 0.6), col, 2.5, true)
		"heavy":
			# ağır saldırı: merkezden saçılan darbe
			draw_circle(c, r * 0.32, col)
			for k in 8:
				var a := TAU * float(k) / 8.0
				draw_line(c + Vector2(cos(a), sin(a)) * r * 0.5, c + Vector2(cos(a), sin(a)) * r * (0.95 if k % 2 == 0 else 0.75), col, 2.5, true)
		"parry":
			# kalkan
			var pts := PackedVector2Array([c + Vector2(-r * 0.8, -r * 0.8), c + Vector2(r * 0.8, -r * 0.8), c + Vector2(r * 0.8, 0), c + Vector2(0, r), c + Vector2(-r * 0.8, 0)])
			pts.append(pts[0])
			draw_polyline(pts, col, 2.5, true)
			draw_line(c + Vector2(0, -r * 0.6), c + Vector2(0, r * 0.6), col, 2.0, true)


func _star(c: Vector2, ro: float, ri: float, n: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for k in n * 2:
		var a := -PI * 0.5 + float(k) * PI / float(n)
		pts.append(c + Vector2(cos(a), sin(a)) * (ro if k % 2 == 0 else ri))
	return pts
