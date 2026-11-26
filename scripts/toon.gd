extends RefCounted
## ÇİZGİ FİLM TARZI: karakter malzemelerine düz renk bölgeli (toon) ışık, arkadan vuran kenar ışığı (rim)
## ve ince koyu kontur ekler. Bütün karakterler (kahraman, silahlar, yaratıklar, bosslar) aynı tarzda görünür.
## Telefonda kontur kapalıdır (her parça iki kez çizildiği için).

static var _outline: ShaderMaterial = null


static func outline_mat() -> ShaderMaterial:
	if _outline == null:
		_outline = ShaderMaterial.new()
		_outline.shader = load("res://shaders/outline.gdshader")
		_outline.render_priority = -1
	return _outline


static func style(m: StandardMaterial3D, outline := true) -> StandardMaterial3D:
	m.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	m.specular_mode = BaseMaterial3D.SPECULAR_TOON
	m.rim_enabled = true
	m.rim = 0.45
	m.rim_tint = 0.55
	if outline and m.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED and not bool(load("res://scripts/game_data.gd").is_mobile()) and bool(load("res://scripts/game_data.gd").gfx_outline()):
		m.next_pass = outline_mat()
	return m
