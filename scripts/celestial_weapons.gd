extends RefCounted
## KOZMİK SİLAH MODELLERİ
## Altın ve yıldız ışığından silahlar. Kabza başlangıç noktasında, silah +Y yönünde uzanır.

static var _gold: StandardMaterial3D = null
static var _dark: StandardMaterial3D = null


static func _mats() -> void:
	if _gold != null:
		return
	_gold = StandardMaterial3D.new()
	_gold.albedo_color = Color(0.95, 0.78, 0.38)
	_gold.metallic = 1.0
	_gold.roughness = 0.22
	_dark = StandardMaterial3D.new()
	_dark.albedo_color = Color(0.06, 0.08, 0.2)
	_dark.metallic = 0.6
	_dark.roughness = 0.35


static func _glow(c: Color, e := 4.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = e
	m.metallic = 0.3
	m.roughness = 0.1
	return m


static func _add(root: Node3D, mesh: Mesh, pos: Vector3, m: Material, rot := Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = m
	mi.position = pos
	mi.rotation = rot
	root.add_child(mi)
	return mi


static func _box(s: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = s
	return b


static func _cyl(r: float, h: float, r_top := -1.0) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.bottom_radius = r
	c.top_radius = r if r_top < 0.0 else r_top
	c.height = h
	c.radial_segments = 12
	return c


static func _sphere(r: float) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	return s


static func build(id: String, color: Color) -> Node3D:
	_mats()
	var g := Node3D.new()
	var light := _glow(color, 5.0)
	match id:
		"STAR SWORD":
			_add(g, _cyl(0.035, 0.32), Vector3(0, 0.0, 0), _dark)                          # kabza
			_add(g, _box(Vector3(0.42, 0.05, 0.08)), Vector3(0, 0.18, 0), _gold)            # balçak
			_add(g, _sphere(0.05), Vector3(0, -0.18, 0), _gold)                              # kabza topuzu
			_add(g, _box(Vector3(0.09, 1.25, 0.02)), Vector3(0, 0.84, 0), light)             # ışık bıçağı
			_add(g, _box(Vector3(0.03, 1.2, 0.03)), Vector3(0, 0.82, 0), _gold)              # bıçak omurgası
			_add(g, _cyl(0.045, 0.12, 0.0), Vector3(0, 1.52, 0), light)                      # uç
		"MOON SCYTHE":
			_add(g, _cyl(0.03, 1.5), Vector3(0, 0.55, 0), _dark)                             # sap
			_add(g, _sphere(0.05), Vector3(0, -0.22, 0), _gold)
			_add(g, _box(Vector3(0.12, 0.08, 0.08)), Vector3(0, 1.3, 0), _gold)
			for i in 9:                                                                        # hilal bıçak
				var t := float(i) / 8.0
				var ang := lerpf(0.15, PI * 0.85, t)
				var rr := 0.55
				var p := Vector3(cos(ang) * rr - 0.05, 1.3 + sin(ang) * rr * 0.55, 0)
				var w := lerpf(0.11, 0.03, t)
				_add(g, _box(Vector3(0.16, w, 0.02)), p, light, Vector3(0, 0, ang + PI * 0.5))
		"SUN MACE":
			_add(g, _cyl(0.04, 1.0), Vector3(0, 0.3, 0), _dark)                              # sap
			_add(g, _sphere(0.06), Vector3(0, -0.22, 0), _gold)
			_add(g, _sphere(0.24), Vector3(0, 0.95, 0), _gold)                               # baş
			_add(g, _sphere(0.16), Vector3(0, 0.95, 0), _glow(color, 6.0))
			for i in 8:                                                                        # güneş ışınları
				var a := TAU * float(i) / 8.0
				_add(g, _cyl(0.04, 0.22, 0.0), Vector3(cos(a) * 0.28, 0.95 + sin(a) * 0.28, 0), _gold, Vector3(0, 0, a - PI * 0.5))
		"COMET SPEAR":
			_add(g, _cyl(0.028, 2.0), Vector3(0, 0.6, 0), _dark)                             # uzun sap
			_add(g, _box(Vector3(0.16, 0.05, 0.05)), Vector3(0, 1.6, 0), _gold)
			_add(g, _cyl(0.07, 0.4, 0.0), Vector3(0, 1.85, 0), light)                        # uç
			_add(g, _cyl(0.06, 0.25, 0.0), Vector3(0, 1.32, 0), _glow(color, 2.0), Vector3(PI, 0, 0))  # kuyruk
			_add(g, _sphere(0.05), Vector3(0, -0.42, 0), _gold)
		"METEOR CHAIN":
			_add(g, _cyl(0.04, 0.38), Vector3(0, 0.0, 0), _dark)                             # birinci sap
			_add(g, _cyl(0.045, 0.05), Vector3(0, 0.2, 0), _gold)
			for i in 6:                                                                        # zincir halkaları
				_add(g, _sphere(0.03), Vector3(0.05 * sin(i * 0.9), 0.26 + i * 0.07, 0), _gold)
			_add(g, _cyl(0.04, 0.38), Vector3(0.12, 0.85, 0), _dark, Vector3(0, 0, -0.5))   # ikinci sap
			_add(g, _sphere(0.11), Vector3(0.22, 1.05, 0), light)                            # meteor taşı
		"CENTAUR BOW":
			# kavis: tutamak merkezde, kollar yukarı-aşağı uzanır ve okçuya (+Z) doğru kıvrılır
			_add(g, _cyl(0.035, 0.24), Vector3.ZERO, _dark)                                 # tutamak
			_add(g, _cyl(0.042, 0.04), Vector3(0, 0.12, 0), _gold)
			_add(g, _cyl(0.042, 0.04), Vector3(0, -0.12, 0), _gold)
			for side: float in [1.0, -1.0]:
				var prev := Vector3(0, 0.1 * side, 0)
				for k in range(1, 5):
					var p := Vector3(0, (0.1 + 0.16 * float(k)) * side, 0.028 * float(k * k))
					var mid := (prev + p) * 0.5
					var seg := _add(g, _box(Vector3(0.05, prev.distance_to(p) + 0.02, 0.035)), mid, _gold)
					seg.rotation.x = atan2(p.z - prev.z, p.y - prev.y)
					prev = p
				_add(g, _sphere(0.05), prev, light)                                           # parlayan uçlar
			_add(g, _cyl(0.008, 1.48), Vector3(0, 0, 0.45), light)                            # ışık kirişi
			_add(g, _sphere(0.06), Vector3(0, 0, -0.02), light)                               # merkez taşı
		_:
			_add(g, _box(Vector3(0.1, 1.0, 0.05)), Vector3(0, 0.5, 0), light)
	return g
