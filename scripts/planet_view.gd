extends SubViewportContainer
## Arayüzde dönen 3D gezegen (lütuf ekranı için). Kendi küçük 3D dünyası var; oyun dururken de döner.
## Görünüşler Gözlemevi'ndeki gezegen düzeneğiyle aynı gölgelendiricileri kullanır.

var planet := "Sun"
var _vp: SubViewport
var _tilt: Node3D
var _body: MeshInstance3D

## Gezegen yüzey ayarları (planet.gdshader)
const LOOKS := {
	"Mercury": {"kind": 0, "col_a": Color(0.62, 0.58, 0.55), "col_b": Color(0.36, 0.34, 0.33), "col_c": Color(0.5, 0.45, 0.4), "crater_amt": 1.0, "seed": 1.3},
	"Venus": {"kind": 1, "col_a": Color(0.95, 0.87, 0.65), "col_b": Color(0.86, 0.72, 0.48), "col_c": Color(1.0, 0.95, 0.8), "band_freq": 4.0, "band_warp": 3.0, "seed": 2.1, "atmo_col": Color(1.0, 0.9, 0.6), "atmo_amt": 0.6},
	"Moon": {"kind": 0, "col_a": Color(0.82, 0.82, 0.8), "col_b": Color(0.48, 0.48, 0.5), "col_c": Color(0.66, 0.66, 0.66), "crater_amt": 1.0, "seed": 11.0, "atmo_col": Color(0.7, 0.8, 1.0), "atmo_amt": 0.4},
	"Mars": {"kind": 0, "col_a": Color(0.85, 0.42, 0.2), "col_b": Color(0.5, 0.21, 0.11), "col_c": Color(0.62, 0.3, 0.16), "crater_amt": 0.35, "polar_cap": 0.88, "seed": 4.4, "atmo_col": Color(1.0, 0.6, 0.4), "atmo_amt": 0.4},
	"Jupiter": {"kind": 1, "col_a": Color(0.93, 0.87, 0.75), "col_b": Color(0.72, 0.52, 0.34), "col_c": Color(0.55, 0.38, 0.27), "band_freq": 13.0, "band_warp": 1.4, "seed": 5.2, "spot_size": 0.24, "spot_dir": Vector3(0.7, -0.38, 0.6), "spot_col": Color(0.78, 0.36, 0.2)},
	"Saturn": {"kind": 1, "col_a": Color(0.93, 0.85, 0.63), "col_b": Color(0.8, 0.68, 0.46), "col_c": Color(0.98, 0.93, 0.78), "band_freq": 11.0, "band_warp": 0.8, "seed": 6.6},
}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vp = SubViewport.new()
	_vp.own_world_3d = true
	_vp.transparent_bg = true
	_vp.msaa_3d = Viewport.MSAA_4X
	_vp.size = Vector2i(512, 512)
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_vp)

	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.25, 0.28, 0.45)
	env.ambient_light_energy = 0.6
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.glow_enabled = true
	env.glow_intensity = 0.8
	env.glow_hdr_threshold = 1.0
	var we := WorldEnvironment.new()
	we.environment = env
	_vp.add_child(we)

	var cam := Camera3D.new()
	cam.position = Vector3(0, 0.25, 3.4)
	cam.fov = 40.0
	_vp.add_child(cam)
	cam.look_at(Vector3.ZERO, Vector3.UP)

	var sun_light := DirectionalLight3D.new()
	sun_light.light_energy = 1.6
	sun_light.rotation_degrees = Vector3(-15, -50, 0)
	_vp.add_child(sun_light)

	_tilt = Node3D.new()
	_tilt.rotation.z = deg_to_rad(18.0)
	_vp.add_child(_tilt)
	var sph := SphereMesh.new()
	sph.radius = 1.0
	sph.height = 2.0
	sph.radial_segments = 64
	sph.rings = 32
	_body = MeshInstance3D.new()
	_body.mesh = sph
	_tilt.add_child(_body)

	if planet == "Sun":
		var sm := ShaderMaterial.new()
		sm.shader = preload("res://shaders/sun.gdshader")
		_body.material_override = sm
		var cq := QuadMesh.new()
		cq.size = Vector2(4.6, 4.6)
		var cm := ShaderMaterial.new()
		cm.shader = preload("res://shaders/corona.gdshader")
		cm.set_shader_parameter("strength", 0.9)
		var corona := MeshInstance3D.new()
		corona.mesh = cq
		corona.material_override = cm
		_vp.add_child(corona)
	else:
		var pm := ShaderMaterial.new()
		pm.shader = preload("res://shaders/planet.gdshader")
		var look: Dictionary = LOOKS.get(planet, LOOKS["Mercury"])
		for k in look:
			var v = look[k]
			if v is Color:
				v = Vector3(v.r, v.g, v.b)
			pm.set_shader_parameter(k, v)
		pm.set_shader_parameter("self_glow", 0.18)
		_body.material_override = pm
		if planet == "Saturn":
			var ring := PlaneMesh.new()
			ring.size = Vector2(4.2, 4.2)
			var rm := ShaderMaterial.new()
			rm.shader = preload("res://shaders/planet_ring.gdshader")
			rm.set_shader_parameter("inner", 0.55)
			rm.set_shader_parameter("col_a", Vector3(0.9, 0.82, 0.62))
			rm.set_shader_parameter("col_b", Vector3(0.62, 0.52, 0.36))
			rm.set_shader_parameter("gap_at", 0.62)
			var ri := MeshInstance3D.new()
			ri.mesh = ring
			ri.material_override = rm
			ri.rotation.x = deg_to_rad(16.0)
			_tilt.add_child(ri)
			_body.scale = Vector3.ONE * 0.75


func _process(delta: float) -> void:
	if _body != null:
		_body.rotate_y(delta * 0.35)
