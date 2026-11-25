extends RefCounted
## SİLAH MODELLERİ
## Her silahın kendine özgü modeli basit parçalardan kurulur. Namlu +X yönünde, üst +Y.
## Hepsinde silahın rengiyle parlayan küçük bir neon detay var (cyberpunk dokunuşu).
## "tip" etiketi namlu ucunu gösterir (mermi, alev ve roket buradan çıkar).

static var _mats := {}


static func _m(key: String, color: Color, metal: float, rough: float) -> StandardMaterial3D:
	if not _mats.has(key):
		var m := StandardMaterial3D.new()
		m.albedo_color = color
		m.metallic = metal
		m.roughness = rough
		_mats[key] = m
	return _mats[key]


static func _gunmetal() -> StandardMaterial3D:
	return _m("gunmetal", Color(0.13, 0.13, 0.15), 0.85, 0.35)


static func _polymer() -> StandardMaterial3D:
	return _m("polymer", Color(0.06, 0.06, 0.07), 0.1, 0.65)


static func _wood() -> StandardMaterial3D:
	return _m("wood", Color(0.36, 0.18, 0.08), 0.0, 0.5)


static func _chrome() -> StandardMaterial3D:
	return _m("chrome", Color(0.75, 0.75, 0.78), 1.0, 0.12)


static func _olive() -> StandardMaterial3D:
	return _m("olive", Color(0.22, 0.27, 0.15), 0.3, 0.55)


static func _red() -> StandardMaterial3D:
	return _m("red", Color(0.6, 0.08, 0.05), 0.5, 0.35)


static func _neon(c: Color, e := 5.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0, 0, 0)
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = e
	return m


static func _box(root: Node3D, size: Vector3, pos: Vector3, m: Material, rot_z := 0.0) -> void:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	mi.mesh = b
	mi.material_override = m
	mi.position = pos
	mi.rotation.z = rot_z
	root.add_child(mi)


## X ekseni boyunca uzanan silindir (namlu, tüp)
static func _tube(root: Node3D, r: float, length: float, pos: Vector3, m: Material, r_end := -1.0, z := 0.0) -> void:
	var mi := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = r if r_end < 0.0 else r_end
	c.bottom_radius = r
	c.height = length
	c.radial_segments = 14
	mi.mesh = c
	mi.material_override = m
	mi.position = pos + Vector3(0, 0, z)
	mi.rotation.z = -PI * 0.5
	root.add_child(mi)


static func build(weapon_name: String, accent: Color) -> Node3D:
	var g := Node3D.new()
	g.name = "Gun_" + weapon_name
	match weapon_name:
		"TABANCA":
			_box(g, Vector3(0.5, 0.11, 0.07), Vector3(0.17, 0.09, 0), _gunmetal())        # sürgü
			_box(g, Vector3(0.42, 0.07, 0.065), Vector3(0.14, 0.0, 0), _polymer())        # gövde
			_box(g, Vector3(0.11, 0.3, 0.07), Vector3(-0.02, -0.15, 0), _polymer(), 0.28) # kabza
			_box(g, Vector3(0.14, 0.02, 0.04), Vector3(0.08, -0.07, 0), _gunmetal())      # tetik korkuluğu
			_box(g, Vector3(0.3, 0.012, 0.012), Vector3(0.2, 0.15, 0), _neon(accent))     # neon nişangâh
			g.set_meta("tip", Vector3(0.44, 0.09, 0))
		"REVOLVER":
			_tube(g, 0.035, 0.6, Vector3(0.45, 0.09, 0), _chrome())                        # uzun namlu
			_box(g, Vector3(0.6, 0.03, 0.03), Vector3(0.45, 0.135, 0), _chrome())          # namlu sırtı
			_tube(g, 0.095, 0.17, Vector3(0.08, 0.06, 0), _chrome())                       # top (silindir)
			_box(g, Vector3(0.28, 0.1, 0.06), Vector3(0.06, 0.04, 0), _gunmetal())         # gövde
			_box(g, Vector3(0.13, 0.3, 0.075), Vector3(-0.08, -0.14, 0), _wood(), 0.35)    # ahşap kabza
			_box(g, Vector3(0.05, 0.06, 0.03), Vector3(-0.07, 0.12, 0), _gunmetal(), -0.5) # horoz
			_tube(g, 0.098, 0.02, Vector3(0.08, 0.06, 0), _neon(accent, 4.0))              # neon halka
			g.set_meta("tip", Vector3(0.76, 0.09, 0))
		"UZİ":
			_box(g, Vector3(0.42, 0.14, 0.09), Vector3(0.12, 0.05, 0), _gunmetal())        # kutu gövde
			_tube(g, 0.025, 0.12, Vector3(0.38, 0.06, 0), _gunmetal())                     # kısa namlu
			_box(g, Vector3(0.07, 0.46, 0.06), Vector3(0.04, -0.24, 0), _polymer())        # uzun şarjör
			_box(g, Vector3(0.3, 0.02, 0.02), Vector3(-0.22, 0.05, 0.035), _gunmetal())    # tel dipçik
			_box(g, Vector3(0.3, 0.02, 0.02), Vector3(-0.22, 0.05, -0.035), _gunmetal())
			_box(g, Vector3(0.02, 0.1, 0.09), Vector3(-0.36, 0.03, 0), _gunmetal())
			_box(g, Vector3(0.36, 0.015, 0.092), Vector3(0.12, 0.125, 0), _neon(accent))   # neon şerit
			g.set_meta("tip", Vector3(0.45, 0.06, 0))
		"PİYADE TÜFEĞİ":
			_box(g, Vector3(0.6, 0.14, 0.09), Vector3(0.1, 0.06, 0), _gunmetal())          # gövde
			_box(g, Vector3(0.38, 0.11, 0.1), Vector3(0.55, 0.07, 0), _polymer())          # el kundağı
			_tube(g, 0.025, 0.4, Vector3(0.88, 0.09, 0), _gunmetal())                      # namlu
			_tube(g, 0.035, 0.08, Vector3(1.1, 0.09, 0), _gunmetal())                      # alev gizleyici
			_box(g, Vector3(0.1, 0.32, 0.07), Vector3(0.06, -0.16, 0), _polymer(), -0.25)  # kavisli şarjör
			_box(g, Vector3(0.42, 0.15, 0.07), Vector3(-0.42, 0.03, 0), _polymer())        # dipçik
			_box(g, Vector3(0.09, 0.2, 0.07), Vector3(-0.12, -0.1, 0), _polymer(), 0.3)    # kabza
			_tube(g, 0.042, 0.3, Vector3(0.12, 0.2, 0), _gunmetal())                       # dürbün
			_tube(g, 0.036, 0.01, Vector3(0.275, 0.2, 0), _neon(accent, 8.0))              # dürbün camı
			g.set_meta("tip", Vector3(1.15, 0.09, 0))
		"POMPALI":
			_tube(g, 0.038, 0.95, Vector3(0.55, 0.1, 0), _gunmetal())                      # uzun namlu
			_tube(g, 0.03, 0.7, Vector3(0.45, 0.03, 0), _gunmetal())                       # şarjör tüpü
			_tube(g, 0.055, 0.26, Vector3(0.45, 0.03, 0), _wood())                         # ahşap pompa
			_box(g, Vector3(0.3, 0.14, 0.08), Vector3(0.0, 0.07, 0), _gunmetal())          # gövde
			_box(g, Vector3(0.5, 0.15, 0.07), Vector3(-0.38, 0.02, 0), _wood(), 0.08)      # ahşap dipçik
			_box(g, Vector3(0.6, 0.012, 0.012), Vector3(0.55, 0.142, 0), _neon(accent))    # neon şerit
			g.set_meta("tip", Vector3(1.02, 0.1, 0))
		"KESİK POMPALI":
			_tube(g, 0.036, 0.42, Vector3(0.3, 0.1, 0), _gunmetal(), -1.0, 0.037)          # çift namlu
			_tube(g, 0.036, 0.42, Vector3(0.3, 0.1, 0), _gunmetal(), -1.0, -0.037)
			_box(g, Vector3(0.2, 0.06, 0.1), Vector3(0.22, 0.04, 0), _wood())              # ön kundak
			_box(g, Vector3(0.18, 0.13, 0.1), Vector3(0.0, 0.08, 0), _gunmetal())          # gövde
			_box(g, Vector3(0.16, 0.28, 0.08), Vector3(-0.13, -0.08, 0), _wood(), 0.5)     # kesik kabza
			_box(g, Vector3(0.02, 0.02, 0.1), Vector3(0.52, 0.1, 0), _neon(accent, 6.0))   # namlu ağzı neonu
			g.set_meta("tip", Vector3(0.52, 0.1, 0))
		"ALEV SİLAHI":
			_tube(g, 0.05, 0.8, Vector3(0.35, 0.05, 0), _gunmetal())                       # gövde borusu
			_tube(g, 0.05, 0.22, Vector3(0.85, 0.05, 0), _gunmetal(), 0.08)                # genişleyen ağız
			_tube(g, 0.09, 0.5, Vector3(0.1, 0.2, 0.06), _red())                           # yakıt tüpü 1
			_tube(g, 0.09, 0.5, Vector3(0.1, 0.2, -0.06), _red())                          # yakıt tüpü 2
			_box(g, Vector3(0.1, 0.22, 0.07), Vector3(0.0, -0.1, 0), _polymer(), 0.2)      # kabza
			_box(g, Vector3(0.09, 0.18, 0.07), Vector3(0.45, -0.07, 0), _polymer())        # ön tutamak
			var pilot := MeshInstance3D.new()
			var sm := SphereMesh.new()
			sm.radius = 0.03
			sm.height = 0.06
			pilot.mesh = sm
			pilot.material_override = _neon(Color(0.3, 0.6, 1.0), 10.0)               # mavi pilot alevi
			pilot.position = Vector3(0.98, -0.02, 0)
			g.add_child(pilot)
			g.set_meta("tip", Vector3(0.98, 0.05, 0))
		"BAZUKA":
			_tube(g, 0.11, 1.5, Vector3(0.3, 0.12, 0), _olive())                           # ana tüp
			_tube(g, 0.16, 0.22, Vector3(-0.55, 0.12, 0), _olive(), 0.11)                  # arka huni
			_tube(g, 0.125, 0.06, Vector3(1.03, 0.12, 0), _gunmetal())                     # ön halka
			_tube(g, 0.08, 0.12, Vector3(1.1, 0.12, 0), _red(), 0.0)                       # roket ucu
			_box(g, Vector3(0.18, 0.1, 0.07), Vector3(0.2, 0.25, 0.08), _gunmetal())       # nişangâh
			_box(g, Vector3(0.01, 0.06, 0.05), Vector3(0.29, 0.25, 0.08), _neon(accent, 8.0))
			_box(g, Vector3(0.1, 0.24, 0.07), Vector3(0.0, -0.1, 0), _polymer(), 0.2)      # kabza
			_box(g, Vector3(0.09, 0.2, 0.07), Vector3(0.45, -0.07, 0), _polymer())         # ön tutamak
			g.set_meta("tip", Vector3(1.12, 0.12, 0))
		_:
			_box(g, Vector3(0.5, 0.12, 0.08), Vector3(0.15, 0.05, 0), _gunmetal())
			g.set_meta("tip", Vector3(0.42, 0.05, 0))
	return g
