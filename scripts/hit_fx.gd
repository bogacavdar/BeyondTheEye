extends RefCounted
## VURUŞ EFEKTLERİ: vuruşun "oturduğunu" hissettiren küçük ama yoğun görseller.
##  - impact(): vuruş noktasında parlayan yıldız patlaması + vuruş yönünde ışık çizgileri + kısa ışık
##  - number(): yukarı fırlayıp sönen hasar sayısı (kritik: büyük, turuncu, ünlemli)

const UI = preload("res://scripts/ui_style.gd")
const GameData = preload("res://scripts/game_data.gd")

static var _star_mat: StandardMaterial3D
static var _streak_mat: StandardMaterial3D
static var _streak_mesh: BoxMesh


static func _mats() -> void:
	if _star_mat != null:
		return
	_star_mat = StandardMaterial3D.new()
	_star_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_star_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_star_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_star_mat.no_depth_test = true
	_star_mat.albedo_color = Color(1.0, 0.95, 0.8, 1.0)
	_streak_mat = StandardMaterial3D.new()
	_streak_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_streak_mat.albedo_color = Color(1.0, 0.92, 0.7)
	_streak_mat.emission_enabled = true
	_streak_mat.emission = Color(1.0, 0.85, 0.5)
	_streak_mat.emission_energy_multiplier = 6.0
	_streak_mesh = BoxMesh.new()
	_streak_mesh.size = Vector3(0.035, 0.035, 0.5)


## Vuruş noktasında patlama. dir: vuruşun yönü (düşmana doğru)
static func impact(world: Node3D, pos: Vector3, dir: Vector3, color: Color, big := false) -> void:
	if world == null or not is_instance_valid(world):
		return
	_mats()
	var root := Node3D.new()
	world.add_child(root)
	root.global_position = pos
	# kameraya dönük dört kollu yıldız parlaması
	var star := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(1.0, 1.0)
	star.mesh = q
	var sm := _star_mat.duplicate() as StandardMaterial3D
	sm.albedo_color = Color(lerp(1.0, color.r, 0.4), lerp(1.0, color.g, 0.4), lerp(1.0, color.b, 0.4), 1.0)
	sm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	sm.albedo_texture = _star_texture()
	star.material_override = sm
	star.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(star)
	var s0 := 0.6 if not big else 1.1
	star.scale = Vector3.ONE * s0 * 0.4
	var tw := star.create_tween().set_parallel(true)
	tw.tween_property(star, "scale", Vector3.ONE * s0 * 1.6, 0.14).set_ease(Tween.EASE_OUT)
	tw.tween_property(sm, "albedo_color:a", 0.0, 0.16).set_delay(0.04)
	# vuruş yönünde fırlayan ışık çizgileri
	var n := 5 if not big else 9
	var d := dir.normalized() if dir.length() > 0.01 else Vector3.FORWARD
	for i in n:
		var sk := MeshInstance3D.new()
		sk.mesh = _streak_mesh
		sk.material_override = _streak_mat
		sk.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(sk)
		var spread := Vector3(randf_range(-0.7, 0.7), randf_range(-0.3, 0.6), randf_range(-0.7, 0.7))
		var v := (d + spread).normalized()
		sk.look_at(sk.global_position + v, Vector3.UP if absf(v.y) < 0.95 else Vector3.RIGHT)
		var dist := randf_range(0.6, 1.3) * (1.4 if big else 1.0)
		var st := sk.create_tween().set_parallel(true)
		st.tween_property(sk, "position", v * dist, 0.16).set_ease(Tween.EASE_OUT)
		st.tween_property(sk, "scale", Vector3(0.2, 0.2, 0.1), 0.16).set_ease(Tween.EASE_IN)
	var l := OmniLight3D.new()
	l.light_color = color
	l.light_energy = 3.0 if not big else 6.0
	l.omni_range = 3.0 if not big else 5.0
	root.add_child(l)
	var lt := l.create_tween()
	lt.tween_property(l, "light_energy", 0.0, 0.15)
	var end := root.create_tween()
	end.tween_interval(0.3)
	end.tween_callback(root.queue_free)


## Uçan hasar sayısı
static func number(world: Node3D, pos: Vector3, value: float, crit := false) -> void:
	if world == null or not is_instance_valid(world) or not GameData.dmg_numbers:
		return
	var l := Label3D.new()
	l.text = str(int(round(value))) + ("!" if crit else "")
	l.font = UI.font()
	l.font_size = 64 if crit else 44
	l.pixel_size = 0.01
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.render_priority = 5
	l.outline_size = 14
	l.outline_modulate = Color(0.04, 0.03, 0.1, 1.0)
	l.modulate = Color(1.0, 0.55, 0.2) if crit else Color(1.0, 0.92, 0.7)
	world.add_child(l)
	l.global_position = pos + Vector3(randf_range(-0.3, 0.3), 0.2, randf_range(-0.3, 0.3))
	l.scale = Vector3.ONE * (0.5 if crit else 0.7)
	var tw := l.create_tween().set_parallel(true)
	tw.tween_property(l, "scale", Vector3.ONE * (1.35 if crit else 1.0), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "position:y", l.position.y + 1.3, 0.7).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "modulate:a", 0.0, 0.3).set_delay(0.45)
	tw.tween_property(l, "outline_modulate:a", 0.0, 0.3).set_delay(0.45)
	tw.chain().tween_callback(l.queue_free)


## Yumuşak dört kollu yıldız dokusu (bir kez üretilir)
static var _tex: ImageTexture
static func _star_texture() -> ImageTexture:
	if _tex != null:
		return _tex
	var sz := 64
	var img := Image.create(sz, sz, false, Image.FORMAT_RGBA8)
	for y in sz:
		for x in sz:
			var u := (float(x) + 0.5) / float(sz) * 2.0 - 1.0
			var v := (float(y) + 0.5) / float(sz) * 2.0 - 1.0
			var r := sqrt(u * u + v * v)
			var core := clampf(1.0 - r * 2.2, 0.0, 1.0)
			var arm_h := clampf(1.0 - absf(v) * 14.0, 0.0, 1.0) * clampf(1.0 - absf(u), 0.0, 1.0)
			var arm_v := clampf(1.0 - absf(u) * 14.0, 0.0, 1.0) * clampf(1.0 - absf(v), 0.0, 1.0)
			var a := clampf(core * core + arm_h + arm_v, 0.0, 1.0)
			img.set_pixel(x, y, Color(1, 1, 1, a))
	_tex = ImageTexture.create_from_image(img)
	return _tex
