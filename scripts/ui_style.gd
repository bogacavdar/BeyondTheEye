extends RefCounted
## GÖZÜN ÖTESİ arayüz stili: lacivert zemin, altın çerçeve, Cinzel yazı tipi.
## Renkler kanal logosundan alındı.

const NAVY := Color(0.071, 0.114, 0.31)        # #121D4F
const DEEP := Color(0.02, 0.03, 0.09)
const GOLD := Color(0.953, 0.863, 0.478)       # #F3DC7A
const GOLD_DIM := Color(0.6, 0.53, 0.3)
const CREAM := Color(1.0, 0.97, 0.88)
const FONT_PATH := "res://assets/fonts/Cinzel.ttf"

static var _font: Font = null
static var _theme: Theme = null


static func font() -> Font:
	if _font == null and ResourceLoader.exists(FONT_PATH):
		_font = load(FONT_PATH)
	if _font == null:
		_font = ThemeDB.fallback_font
	return _font


## Tüm arayüze uygulanacak tema (kök Control'e verilir, alt öğelere yayılır)
static func theme() -> Theme:
	if _theme == null:
		_theme = Theme.new()
		_theme.default_font = font()
		_theme.default_font_size = 22
	return _theme


static func box(bg: Color, border: Color, width := 2, margin := 22) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(width)
	s.set_corner_radius_all(3)
	s.content_margin_left = margin
	s.content_margin_right = margin
	s.content_margin_top = 10
	s.content_margin_bottom = 10
	s.shadow_color = Color(border.r, border.g, border.b, 0.25)
	s.shadow_size = 8
	return s


static func button(text: String, size := 24, accent := GOLD) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(380, 58)
	b.add_theme_font_override("font", font())
	b.add_theme_font_size_override("font_size", size)
	b.add_theme_color_override("font_color", accent)
	b.add_theme_color_override("font_hover_color", CREAM)
	b.add_theme_color_override("font_pressed_color", Color(1, 1, 1))
	b.add_theme_color_override("font_disabled_color", Color(0.4, 0.4, 0.5))
	b.add_theme_stylebox_override("normal", box(Color(NAVY.r, NAVY.g, NAVY.b, 0.82), Color(accent.r, accent.g, accent.b, 0.75), 1))
	b.add_theme_stylebox_override("hover", box(Color(0.12, 0.17, 0.42, 0.95), accent, 2))
	b.add_theme_stylebox_override("pressed", box(Color(0.2, 0.22, 0.45, 0.95), CREAM, 2))
	b.add_theme_stylebox_override("disabled", box(Color(0.04, 0.05, 0.12, 0.7), Color(0.3, 0.3, 0.4), 1))
	b.mouse_entered.connect(func(): Sfx.play("switch", -16.0, 0.1, 40))
	b.pressed.connect(func(): Sfx.play("coin", -12.0, 0.0, 0, 0.7))
	return b


static func label(text: String, size: int, color := GOLD, outline := 0) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font())
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if outline > 0:
		l.add_theme_color_override("font_outline_color", DEEP)
		l.add_theme_constant_override("outline_size", outline)
	return l


static func panel(accent := GOLD) -> PanelContainer:
	var p := PanelContainer.new()
	var s := box(Color(DEEP.r, DEEP.g, DEEP.b, 0.92), accent, 2, 34)
	s.content_margin_top = 26
	s.content_margin_bottom = 26
	p.add_theme_stylebox_override("panel", s)
	return p


## İnce altın ayraç çizgisi (logodaki başlık altı çizgi gibi)
static func divider(width := 300.0) -> Control:
	var c := ColorRect.new()
	c.color = GOLD
	c.custom_minimum_size = Vector2(width, 2)
	c.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return c


## Sahnede yüzen altın yazı (Label3D) için ortak ayar
## Burç sembolleri için sistem yazı tipi (Cinzel'de bu semboller yok).
## Windows'ta Segoe UI Symbol, diğer sistemlerde benzeri kullanılır.
static var _sym: SystemFont
static func symbol_font() -> Font:
	if _sym == null:
		_sym = SystemFont.new()
		_sym.font_names = PackedStringArray(["Segoe UI Symbol", "Noto Sans Symbols", "Noto Sans Symbols 2", "DejaVu Sans", "Symbola"])
		_sym.fallbacks = [font()]
	return _sym


static func label3d(text: String, size := 64, color := GOLD, energy := 1.6) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font = font()
	l.font_size = size
	l.pixel_size = 0.01
	l.outline_size = 0
	l.modulate = Color(color.r * energy, color.g * energy, color.b * energy)
	return l
