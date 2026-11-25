extends Node3D
## NEON ŞEHİR
## 4x4 sokak ızgarası, aralarında 3x3 blok. Ortadaki blok meydan (başlangıç noktası),
## bir blok otopark, geri kalanı yüksek binalar. Haritanın dışı bitişik binalarla kapalı.
## Şehir her oyunda aynı kurulur (sabit tohum), böylece sokakları öğrenebilirsin.

const HALF := 52.0
const ROADS := [-48.0, -16.0, 16.0, 48.0]
const BLOCKS := [-32.0, 0.0, 32.0]
const BLOCK := 24.0
const ROAD_HALF := 4.0
const PROPS := "res://assets/city/"
const BarrelScript = preload("res://scripts/barrel.gd")

const SIGN_WORDS := ["RAMEN", "OTEL", "KLİNİK", "BAR", "KEBAP 24", "İMPLANT", "ECZANE", "NOODLE",
		"SİBER", "GECE KULÜBÜ", "TAMİR", "LOKANTA", "ÇAY OCAĞI", "BERBER", "PİYANGO", "KARAOKE",
		"SUSHI", "MARKET", "OYUN SALONU", "DÖVME", "REHİN", "PAVYON"]
const VERT_WORDS := ["OTEL", "BAR", "ÇAY", "NEO", "24", "RAMEN", "KULÜP", "HAN"]
const NEONS := [Color(1.0, 0.15, 0.5), Color(0.1, 0.9, 1.0), Color(0.7, 0.3, 1.0),
		Color(1.0, 0.5, 0.1), Color(0.3, 1.0, 0.5), Color(1.0, 0.1, 0.2)]
const CARS := ["Vehicle_Pickup", "Vehicle_Pickup_Armored", "Vehicle_Sports",
		"Vehicle_Sports_Armored", "Vehicle_Truck", "Vehicle_Truck_Armored"]

var nav
var player: Node3D = null
var building_mat: ShaderMaterial
var rng := RandomNumberGenerator.new()
var _scenes := {}
var _buildings: Array = []
var _light_count := 0
var _blinkers: Array = []
var _hologram: Label3D
var _t := 0.0


func build(p_nav) -> void:
	nav = p_nav
	rng.seed = 7
	building_mat = ShaderMaterial.new()
	building_mat.shader = preload("res://shaders/building.gdshader")

	_ground()
	_boundary()
	for bx: float in BLOCKS:
		for bz: float in BLOCKS:
			if bx == 0.0 and bz == 0.0:
				_plaza()
			elif bx == 32.0 and bz == -32.0:
				_parking(Vector2(bx, bz))
			else:
				_block(Vector2(bx, bz))
	_signs()
	_street_lights()
	_street_props()


func _process(delta: float) -> void:
	_t += delta
	if player != null and is_instance_valid(player):
		building_mat.set_shader_parameter("player_pos", player.global_position)
	for b in _blinkers:
		b.visible = fmod(_t + b.get_meta("phase"), 1.6) < 0.8
	if _hologram != null:
		_hologram.modulate.a = 0.75 + 0.25 * sin(_t * 7.0) * sin(_t * 1.3)


# ---------------------------------------------------------------- yardımcılar

func _scene(file: String) -> PackedScene:
	if not _scenes.has(file):
		_scenes[file] = load(PROPS + file + ".gltf")
	return _scenes[file]


func _local_aabb(n: Node3D) -> AABB:
	var inv := n.global_transform.affine_inverse()
	var first := true
	var box := AABB()
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		var b: AABB = (inv * mi.global_transform) * mi.get_aabb()
		box = b if first else box.merge(b)
		first = false
	return box


## Kit modelini yerleştirir. collide=true ise mermiyi ve yaratıkları durdurur, yol haritasına engel yazılır.
func _prop(file: String, pos: Vector3, rot_y: float, collide: bool) -> Node3D:
	var n: Node3D = _scene(file).instantiate()
	add_child(n)
	n.position = pos
	n.rotation.y = rot_y
	if collide:
		var box := _local_aabb(n)
		var sb := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		sh.size = box.size
		cs.shape = sh
		cs.position = box.get_center()
		sb.add_child(cs)
		n.add_child(sb)
		_block_world_box(n, box)
	return n


func _block_world_box(n: Node3D, box: AABB, pad := 0.3) -> void:
	var mn := Vector2(INF, INF)
	var mx := Vector2(-INF, -INF)
	for cx in [box.position.x, box.end.x]:
		for cz in [box.position.z, box.end.z]:
			var p: Vector3 = n.global_transform * Vector3(cx, 0, cz)
			mn = mn.min(Vector2(p.x, p.z))
			mx = mx.max(Vector2(p.x, p.z))
	nav.block_rect(Rect2(mn, mx - mn), pad)


func _light(pos: Vector3, color: Color, energy: float, rng_: float, fog := 0.5) -> void:
	var l := OmniLight3D.new()
	l.light_color = color
	l.light_energy = energy
	l.omni_range = rng_
	l.light_volumetric_fog_energy = fog
	add_child(l)
	l.position = pos
	_light_count += 1


func _neon_box(size: Vector3, pos: Vector3, color: Color, energy: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = Fx.emissive(color, energy)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	mi.position = pos
	return mi


func _is_road(x: float, z: float) -> bool:
	for r: float in ROADS:
		if absf(x - r) < ROAD_HALF or absf(z - r) < ROAD_HALF:
			return true
	return false


# ---------------------------------------------------------------- zemin ve sınır

func _ground() -> void:
	var body := StaticBody3D.new()
	add_child(body)
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(160, 1, 160)
	cs.shape = sh
	cs.position.y = -0.5
	body.add_child(cs)
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(160, 160)
	mi.mesh = pm
	var gm := ShaderMaterial.new()
	gm.shader = preload("res://shaders/ground.gdshader")
	mi.material_override = gm
	body.add_child(mi)


## Haritanın dört yanını kapatan bitişik binalar
func _boundary() -> void:
	var inner := HALF
	var depth := 16.0
	for side in 4:
		var t := -inner - depth
		while t < inner + depth:
			var w := rng.randf_range(8.0, 16.0)
			var hgt := rng.randf_range(14.0, 42.0)
			var r: Rect2
			match side:
				0: r = Rect2(t, -inner - depth, w, depth)
				1: r = Rect2(t, inner, w, depth)
				2: r = Rect2(-inner - depth, t, depth, w)
				_: r = Rect2(inner, t, depth, w)
			_building(r, hgt)
			t += w


# ---------------------------------------------------------------- binalar

func _building(r: Rect2, height: float) -> void:
	var body := StaticBody3D.new()
	add_child(body)
	body.position = Vector3(r.get_center().x, height * 0.5, r.get_center().y)
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(r.size.x, height, r.size.y)
	cs.shape = sh
	body.add_child(cs)
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = sh.size
	mi.mesh = bm
	mi.material_override = building_mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	body.add_child(mi)
	var tones := [Color(0.13, 0.14, 0.18), Color(0.16, 0.13, 0.14), Color(0.12, 0.12, 0.13),
			Color(0.15, 0.12, 0.18), Color(0.1, 0.13, 0.15)]
	var neon: Color = NEONS[rng.randi() % NEONS.size()]
	mi.set_instance_shader_parameter("seed", rng.randf() * 100.0)
	mi.set_instance_shader_parameter("base_color", tones[rng.randi() % tones.size()])
	mi.set_instance_shader_parameter("neon_color", neon)
	nav.block_rect(r, 0.4)
	_buildings.append({"rect": r, "h": height, "neon": neon})

	# çatı süsleri
	var top := Vector3(body.position.x, height, body.position.z)
	var roll := rng.randf()
	if roll < 0.3 and r.size.x > 6.0 and r.size.y > 6.0:
		var wt := _prop("WaterTower", top + Vector3(rng.randf_range(-1.5, 1.5), 0, rng.randf_range(-1.5, 1.5)), rng.randf() * TAU, false)
		wt.scale = Vector3.ONE * 0.8
	elif roll < 0.65:
		var ah := rng.randf_range(3.0, 8.0)
		var ant := _neon_box(Vector3(0.12, ah, 0.12), top + Vector3(0, ah * 0.5, 0), Color(0.05, 0.05, 0.05), 0.0)
		ant.material_override = Fx.mat(Color(0.08, 0.08, 0.1), 0.6, 0.4)
		var blink := _neon_box(Vector3(0.3, 0.3, 0.3), top + Vector3(0, ah, 0), Color(1.0, 0.05, 0.05), 10.0)
		blink.set_meta("phase", rng.randf() * 2.0)
		_blinkers.append(blink)
	if rng.randf() < 0.5:
		# çatı kenarı neon şeridi
		var y := height + 0.05
		_neon_box(Vector3(r.size.x, 0.12, 0.12), Vector3(top.x, y, r.position.y), neon, 3.0)
		_neon_box(Vector3(r.size.x, 0.12, 0.12), Vector3(top.x, y, r.end.y), neon, 3.0)
		_neon_box(Vector3(0.12, 0.12, r.size.y), Vector3(r.position.x, y, top.z), neon, 3.0)
		_neon_box(Vector3(0.12, 0.12, r.size.y), Vector3(r.end.x, y, top.z), neon, 3.0)


## Bir bloğu 1-4 binaya böler (bloğun kenarında 2,5 m kaldırım kalır).
func _block(c: Vector2) -> void:
	var inset := 2.5
	var size := BLOCK - inset * 2.0
	var origin := c - Vector2(size, size) * 0.5
	var split_x := rng.randf() < 0.7
	var split_z := rng.randf() < 0.6
	var xs := [0.0, size]
	var zs := [0.0, size]
	if split_x:
		xs = [0.0, rng.randf_range(size * 0.35, size * 0.65), size]
	if split_z:
		zs = [0.0, rng.randf_range(size * 0.35, size * 0.65), size]
	for i in xs.size() - 1:
		for j in zs.size() - 1:
			var r := Rect2(origin + Vector2(xs[i], zs[j]), Vector2(xs[i + 1] - xs[i], zs[j + 1] - zs[j]))
			_building(r, rng.randf_range(8.0, 34.0))


## Merkez meydan: oyunun başladığı açık alan
func _plaza() -> void:
	_prop("Container_Red", Vector3(-8.5, 0, -6.0), 0.2, true)
	_prop("Container_Green", Vector3(8.0, 0, 7.5), PI * 0.5 + 0.15, true)
	_prop("Couch", Vector3(6.0, 0, -7.5), 2.5, true)
	_prop("TrafficBarrier_1", Vector3(-3.0, 0, 8.0), 0.3, true)
	_prop("TrafficBarrier_2", Vector3(-1.4, 0, 8.4), 0.1, true)
	_prop("PlasticBarrier", Vector3(9.0, 0, -2.0), PI * 0.5, false)
	_prop("Pallet_Broken", Vector3(-9.0, 0, 4.0), 1.0, false)
	_prop("Wheels_Stack", Vector3(-6.8, 0, -3.0), 0.0, false)
	_prop("Blood_1", Vector3(2.0, 0.02, 3.0), 0.7, false)
	# meydanın üstünde titreyen dev hologram
	_hologram = Label3D.new()
	_hologram.text = "KARANTİNA BÖLGESİ"
	_hologram.font_size = 160
	_hologram.pixel_size = 0.014
	_hologram.outline_size = 0
	_hologram.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_hologram.modulate = Color(3.0, 0.25, 0.4, 0.9)
	add_child(_hologram)
	_hologram.position = Vector3(0, 11.0, 0)
	_light(Vector3(0, 9.0, 0), Color(1.0, 0.2, 0.3), 3.0, 18.0, 1.0)
	# meydanın dört köşesinde neon direkler
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			var p := Vector3(sx * 10.5, 0, sz * 10.5)
			var col: Color = NEONS[int(sx + 1.0 + sz + 1.0) % NEONS.size()]
			_neon_box(Vector3(0.18, 4.5, 0.18), p + Vector3(0, 2.25, 0), col, 5.0)
			_light(p + Vector3(0, 3.5, 0), col, 2.5, 9.0)


## Otopark: sıra sıra terk edilmiş araçlar
func _parking(c: Vector2) -> void:
	for row: float in [-6.0, 6.0]:
		var x := -8.5
		while x <= 8.5:
			if rng.randf() < 0.75:
				var car: String = CARS[rng.randi() % CARS.size()]
				_prop(car, Vector3(c.x + x, 0, c.y + row), (0.0 if row < 0.0 else PI) + rng.randf_range(-0.15, 0.15), true)
			x += 4.2
	_neon_box(Vector3(BLOCK - 3.0, 0.05, 0.1), Vector3(c.x, 0.03, c.y), Color(1.0, 0.8, 0.2), 1.5)
	_light(Vector3(c.x, 7.0, c.y), Color(0.9, 0.9, 1.0), 3.0, 16.0)


# ---------------------------------------------------------------- tabelalar

func _signs() -> void:
	for b in _buildings:
		var r: Rect2 = b["rect"]
		var hgt: float = b["h"]
		var faces := [
			[Vector3(r.get_center().x, 0, r.position.y), Vector3(0, 0, -1), r.size.x],
			[Vector3(r.get_center().x, 0, r.end.y), Vector3(0, 0, 1), r.size.x],
			[Vector3(r.position.x, 0, r.get_center().y), Vector3(-1, 0, 0), r.size.y],
			[Vector3(r.end.x, 0, r.get_center().y), Vector3(1, 0, 0), r.size.y],
		]
		for f in faces:
			var fc: Vector3 = f[0]
			var n: Vector3 = f[1]
			var width: float = f[2]
			if not nav.walkable(fc + n * 3.0):
				continue  # sokağa bakmayan yüz
			var tangent := Vector3(n.z, 0, -n.x)
			var col: Color = NEONS[rng.randi() % NEONS.size()]
			if rng.randf() < 0.65:
				var lb := Label3D.new()
				lb.text = SIGN_WORDS[rng.randi() % SIGN_WORDS.size()]
				lb.font_size = 96
				lb.pixel_size = 0.012
				lb.outline_size = 0
				lb.modulate = Color(col.r * 3.0, col.g * 3.0, col.b * 3.0)
				add_child(lb)
				var off := rng.randf_range(-width * 0.25, width * 0.25)
				lb.position = fc + tangent * off + n * 0.12 + Vector3(0, rng.randf_range(4.3, 6.5), 0)
				lb.rotation.y = atan2(n.x, n.z)
				if _light_count < 80 and rng.randf() < 0.5:
					_light(lb.position + n * 1.6, col, 2.2, 8.0, 0.4)
			if hgt > 14.0 and rng.randf() < 0.35:
				var word: String = VERT_WORDS[rng.randi() % VERT_WORDS.size()]
				var letters := PackedStringArray()
				for ch in word:
					letters.append(ch)
				var vl := Label3D.new()
				vl.text = "\n".join(letters)
				vl.font_size = 90
				vl.pixel_size = 0.013
				vl.outline_size = 0
				vl.line_spacing = -10
				var vc: Color = NEONS[rng.randi() % NEONS.size()]
				vl.modulate = Color(vc.r * 3.0, vc.g * 3.0, vc.b * 3.0)
				add_child(vl)
				var side := -1.0 if rng.randf() < 0.5 else 1.0
				vl.position = fc + tangent * side * (width * 0.5 - 1.0) + n * 0.12 + Vector3(0, rng.randf_range(9.0, minf(hgt - 3.0, 16.0)), 0)
				vl.rotation.y = atan2(n.x, n.z)


# ---------------------------------------------------------------- sokak lambaları ve eşyalar

func _street_lights() -> void:
	var colors := [Color(1.0, 0.85, 0.7), Color(1.0, 0.4, 0.75), Color(0.4, 0.9, 1.0)]
	var k := 0
	for r: float in ROADS:
		var t := -44.0
		while t <= 44.0:
			var near_cross := false
			for rr: float in ROADS:
				if absf(t - rr) < 7.0:
					near_cross = true
			if not near_cross:
				var side := 1.0 if k % 2 == 0 else -1.0
				var col: Color = colors[k % colors.size()]
				# z boyunca uzanan yol (x = r)
				var p1 := Vector3(r + side * (ROAD_HALF + 0.7), 0, t)
				if absf(p1.x) > HALF - 0.5:
					p1.x = r - side * (ROAD_HALF + 0.7)  # dış duvara gömülmesin
				var d1 := Vector3(signf(r - p1.x), 0, 0)
				_prop("StreetLights", p1, atan2(d1.x, d1.z), false)
				_light(p1 + d1 * 2.4 + Vector3(0, 6.0, 0), col, 3.0, 14.0)
				# x boyunca uzanan yol (z = r)
				var p2 := Vector3(t, 0, r - side * (ROAD_HALF + 0.7))
				if absf(p2.z) > HALF - 0.5:
					p2.z = r + side * (ROAD_HALF + 0.7)
				var d2 := Vector3(0, 0, signf(r - p2.z))
				_prop("StreetLights", p2, atan2(d2.x, d2.z), false)
				_light(p2 + d2 * 2.4 + Vector3(0, 6.0, 0), colors[(k + 1) % colors.size()], 3.0, 14.0)
				k += 1
			t += 18.0
	# bazı kavşaklarda trafik ışıkları
	for x: float in ROADS:
		for z: float in ROADS:
			if rng.randf() < 0.4:
				_prop("TrafficLight_1", Vector3(x + ROAD_HALF + 0.5, 0, z + ROAD_HALF + 0.5), PI, false)


func _random_road_point(margin := 1.5) -> Vector3:
	var r: float = ROADS[rng.randi() % ROADS.size()]
	var t := rng.randf_range(-HALF + 2.0, HALF - 2.0)
	var lat := rng.randf_range(-ROAD_HALF + margin, ROAD_HALF - margin)
	if rng.randf() < 0.5:
		return Vector3(r + lat, 0, t)
	return Vector3(t, 0, r + lat)


func _random_sidewalk_point() -> Vector3:
	var bx: float = BLOCKS[rng.randi() % BLOCKS.size()]
	var bz: float = BLOCKS[rng.randi() % BLOCKS.size()]
	var e := BLOCK * 0.5 - rng.randf_range(0.6, 1.8)
	var t := rng.randf_range(-BLOCK * 0.5 + 1.0, BLOCK * 0.5 - 1.0)
	match rng.randi() % 4:
		0: return Vector3(bx + t, 0, bz - e)
		1: return Vector3(bx + t, 0, bz + e)
		2: return Vector3(bx - e, 0, bz + t)
		_: return Vector3(bx + e, 0, bz + t)


func _clear_of_start(p: Vector3) -> bool:
	return Vector2(p.x, p.z).length() > 14.0


func _street_props() -> void:
	# yolda terk edilmiş arabalar
	var placed: Array[Vector3] = []
	var tries := 0
	while placed.size() < 18 and tries < 300:
		tries += 1
		var p := _random_road_point(1.6)
		if not _clear_of_start(p):
			continue
		var ok := true
		for q in placed:
			if q.distance_to(p) < 9.0:
				ok = false
				break
		if not ok:
			continue
		placed.append(p)
		var along_z := false
		for r: float in ROADS:
			if absf(p.x - r) < ROAD_HALF:
				along_z = true
		var rot := (0.0 if along_z else PI * 0.5) + (PI if rng.randf() < 0.5 else 0.0) + rng.randf_range(-0.5, 0.5)
		_prop(CARS[rng.randi() % CARS.size()], p, rot, true)

	# kavşak barikatları
	for i in 10:
		var x: float = ROADS[rng.randi() % ROADS.size()]
		var z: float = ROADS[rng.randi() % ROADS.size()]
		var p := Vector3(x + rng.randf_range(-3, 3), 0, z + rng.randf_range(-3, 3))
		if _clear_of_start(p):
			_prop(["TrafficBarrier_1", "TrafficBarrier_2"][rng.randi() % 2], p, rng.randf() * TAU, true)

	# serbest dağılan küçük eşyalar (çarpışmasız)
	var small := ["TrafficCone_1", "TrafficCone_2", "TrafficCone_1", "Blood_2", "Blood_3", "CinderBlock", "Pallet"]
	for i in 45:
		var p := _random_road_point(0.5)
		var f: String = small[rng.randi() % small.size()]
		_prop(f, p + Vector3(0, 0.02 if f.begins_with("Blood") else 0.0, 0), rng.randf() * TAU, false)

	# kaldırımlarda çöp, hidrant, palet
	var walk := ["TrashBag_1", "TrashBag_2", "TrashBag_1", "FireHydrant", "Pallet_Broken", "Pipes", "Wheels_Stack"]
	for i in 60:
		var p := _random_sidewalk_point()
		if absf(p.x) < 13.0 and absf(p.z) < 13.0:
			continue  # meydan
		_prop(walk[rng.randi() % walk.size()], p, rng.randf() * TAU, false)

	# patlayan variller
	var n := 0
	tries = 0
	while n < 16 and tries < 200:
		tries += 1
		var p := _random_sidewalk_point() if rng.randf() < 0.5 else _random_road_point(1.0)
		if not _clear_of_start(p) or not nav.walkable(p):
			continue
		var b = BarrelScript.new()
		add_child(b)
		b.position = p
		nav.block_rect(Rect2(p.x - 0.4, p.z - 0.4, 0.8, 0.8), 0.2)
		n += 1
