extends Node3D
## ASİT TÜKÜRÜĞÜ (boss saldırısı)
## Yay çizerek hedefe uçar; düşeceği yerde önceden yeşil uyarı halkası belirir.
## Düşünce birkaç saniye kalan asit gölü bırakır; içinde duran oyuncu yanar.

var start := Vector3.ZERO
var target_pos := Vector3.ZERO
var player: Node3D = null
var flight := 1.1
var arc := 5.0
var pool_time := 5.0
var pool_radius := 1.8
var _t := 0.0
var _landed := false
var _tick := 0.0
var _ball: MeshInstance3D
var _ring: MeshInstance3D
var _pool: MeshInstance3D


func _ready() -> void:
	_ball = MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.35
	sm.height = 0.7
	_ball.mesh = sm
	_ball.material_override = Fx.emissive(Color(0.6, 1.0, 0.15), 6.0)
	add_child(_ball)
	var l := OmniLight3D.new()
	l.light_color = Color(0.6, 1.0, 0.2)
	l.light_energy = 2.0
	l.omni_range = 5.0
	_ball.add_child(l)

	_ring = MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = pool_radius - 0.12
	tm.outer_radius = pool_radius
	_ring.mesh = tm
	_ring.material_override = Fx.emissive(Color(0.6, 1.0, 0.1), 3.0)
	_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_ring)
	_ring.top_level = true
	_ring.global_position = target_pos + Vector3(0, 0.05, 0)
	global_position = start


func _physics_process(delta: float) -> void:
	if not _landed:
		_t += delta
		var k := clampf(_t / flight, 0.0, 1.0)
		var p := start.lerp(target_pos, k)
		p.y += sin(k * PI) * arc
		_ball.global_position = p
		_ring.scale = Vector3.ONE * (1.0 + 0.1 * sin(_t * 20.0))
		if k >= 1.0:
			_land()
		return

	_t += delta
	_tick -= delta
	if _tick <= 0.0:
		_tick = 0.5
		if player != null and is_instance_valid(player):
			var d := Vector2(player.global_position.x - target_pos.x, player.global_position.z - target_pos.z).length()
			if d < pool_radius:
				player.call("take_damage", 9.0, Vector3.ZERO)
	var fade := clampf((pool_time - _t) / 1.0, 0.0, 1.0)
	_pool.scale = Vector3(pool_radius * 2.0 * fade, 1.0, pool_radius * 2.0 * fade)
	if _t > pool_time:
		queue_free()


func _land() -> void:
	_landed = true
	_t = 0.0
	_ball.queue_free()
	_ring.queue_free()
	global_position = target_pos
	Fx.acid_burst(target_pos + Vector3(0, 0.4, 0))
	_pool = MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.5
	cm.bottom_radius = 0.5
	cm.height = 0.02
	_pool.mesh = cm
	var m := Fx.emissive(Color(0.45, 0.9, 0.1), 2.0)
	m.albedo_color = Color(0.2, 0.4, 0.0)
	m.roughness = 0.05
	_pool.material_override = m
	_pool.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_pool)
	_pool.position = Vector3(0, 0.03, 0)
	_pool.scale = Vector3(pool_radius * 2.0, 1.0, pool_radius * 2.0)
