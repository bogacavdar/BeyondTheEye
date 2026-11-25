extends RefCounted
## Kılıç izi: kılıcın süpürdüğü yayı altın ışıktan bir şerit olarak çizer, sonra hızla söner.
## Açılar kahramanın gövdesine göre (0 = tam ileri, + = sola). Yayın dış kenarı ve en son süpürülen ucu daha parlak.

static func make(a0: float, a1: float, r_in: float, r_out: float, color: Color, life := 0.2) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var segs := maxi(10, int(absf(a1 - a0) * 14.0))
	var prev_in := Vector3.ZERO
	var prev_out := Vector3.ZERO
	var prev_a := 0.0
	for i in segs + 1:
		var t := float(i) / float(segs)
		var ang := lerpf(a0, a1, t)
		var d := Vector3(-sin(ang), 0.0, -cos(ang))
		var p_in := d * r_in
		var p_out := d * r_out
		var a := 0.25 + 0.75 * t
		if i > 0:
			_quad(st, prev_in, prev_out, p_out, p_in, prev_a, a, color)
		prev_in = p_in
		prev_out = p_out
		prev_a = a
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.vertex_color_use_as_albedo = true
	m.albedo_color = Color(1.6, 1.5, 1.2, 1.0)
	mi.material_override = m
	mi.ready.connect(func():
		var tw := mi.create_tween().set_parallel(true)
		tw.tween_property(m, "albedo_color:a", 0.0, life).set_ease(Tween.EASE_IN)
		tw.tween_property(mi, "scale", Vector3(1.08, 1.0, 1.08), life)
		tw.chain().tween_callback(mi.queue_free)
	)
	return mi


static func _quad(st: SurfaceTool, a_in: Vector3, a_out: Vector3, b_out: Vector3, b_in: Vector3, alpha_a: float, alpha_b: float, c: Color) -> void:
	var ci_a := Color(c.r, c.g, c.b, 0.0)
	var co_a := Color(c.r, c.g, c.b, alpha_a)
	var co_b := Color(c.r, c.g, c.b, alpha_b)
	var ci_b := Color(c.r, c.g, c.b, 0.0)
	st.set_color(ci_a)
	st.add_vertex(a_in)
	st.set_color(co_a)
	st.add_vertex(a_out)
	st.set_color(co_b)
	st.add_vertex(b_out)
	st.set_color(ci_a)
	st.add_vertex(a_in)
	st.set_color(co_b)
	st.add_vertex(b_out)
	st.set_color(ci_b)
	st.add_vertex(b_in)
