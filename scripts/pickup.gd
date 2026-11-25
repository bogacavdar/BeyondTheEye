extends Node3D
## KREDİ ÇİPİ
## Ölen zombiden fırlayıp yere sekerek düşer, kendi etrafında döner.
## Oyuncu yaklaşınca mıknatıs gibi ona doğru uçar ve toplanır.
## Uzun süre toplanmazsa yanıp sönüp kaybolur.

const GameData = preload("res://scripts/game_data.gd")
const LIFETIME := 30.0
const REST_Y := 0.3

static var _mesh: CylinderMesh = null
static var _mat: StandardMaterial3D = null

var value := 1
var target: Node3D = null
var vel := Vector3.ZERO
var age := 0.0
var magnet := false
var resting := false
var mi: MeshInstance3D


func _ready() -> void:
	if _mesh == null:
		_mesh = CylinderMesh.new()
		_mesh.top_radius = 0.17
		_mesh.bottom_radius = 0.17
		_mesh.height = 0.05
		_mesh.radial_segments = 6
		_mesh.rings = 1
		_mat = StandardMaterial3D.new()
		_mat.albedo_color = Color(1.0, 0.75, 0.15)
		_mat.metallic = 0.8
		_mat.roughness = 0.25
		_mat.emission_enabled = true
		_mat.emission = Color(1.0, 0.7, 0.1)
		_mat.emission_energy_multiplier = 2.5
	mi = MeshInstance3D.new()
	mi.mesh = _mesh
	mi.material_override = _mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.rotation.x = PI * 0.5  # çip dik dursun, dönerken parlasın
	add_child(mi)
	vel = Vector3(randf_range(-2.5, 2.5), randf_range(4.0, 6.5), randf_range(-2.5, 2.5))
	rotation.y = randf() * TAU


func _physics_process(delta: float) -> void:
	age += delta
	rotation.y += delta * 5.0

	var can_collect := target != null and is_instance_valid(target) and not bool(target.get("dead"))
	if can_collect:
		var tp := target.global_position + Vector3(0, 1.0, 0)
		var d := global_position.distance_to(tp)
		if age > 0.35 and d < GameData.magnet_radius():
			magnet = true
		if magnet:
			var want := (tp - global_position).normalized() * (14.0 + age * 2.0)
			vel = vel.lerp(want, 1.0 - exp(-10.0 * delta))
			global_position += vel * delta
			if global_position.distance_to(tp) < 0.6:
				get_tree().call_group("game", "on_credit", value)
				queue_free()
			return

	if not resting:
		vel.y -= 20.0 * delta
		global_position += vel * delta
		if global_position.y < REST_Y:
			global_position.y = REST_Y
			vel.y = -vel.y * 0.35
			vel.x *= 0.55
			vel.z *= 0.55
			if absf(vel.y) < 0.8:
				resting = true
				vel = Vector3.ZERO
	else:
		mi.position.y = sin(age * 3.0) * 0.06

	if age > LIFETIME - 4.0:
		visible = fmod(age * 8.0, 2.0) < 1.2
	if age > LIFETIME:
		queue_free()
