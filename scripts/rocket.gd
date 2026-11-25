extends Node3D
## BAZUKA ROKETİ
## Düz uçar, arkasında ateş ve duman bırakır. İlk çarptığı yerde (yaratık, duvar, araba, zemin) patlar.

var dir := Vector3.FORWARD
var speed := 30.0
var max_range := 45.0
var radius := 6.0
var damage := 180.0
var knockback := 20.0
var exclude: Array[RID] = []
var _travel := 0.0
var _trail: CPUParticles3D


func _ready() -> void:
	var body := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.07
	cm.bottom_radius = 0.09
	cm.height = 0.55
	body.mesh = cm
	body.material_override = Fx.mat(Color(0.25, 0.3, 0.2), 0.6, 0.4)
	body.rotation.x = PI * 0.5
	add_child(body)
	var tip := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.12
	sm.height = 0.24
	tip.mesh = sm
	tip.material_override = Fx.emissive(Color(1.0, 0.6, 0.2), 9.0)
	tip.position = Vector3(0, 0, -0.3)
	add_child(tip)
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.55, 0.2)
	l.light_energy = 3.0
	l.omni_range = 6.0
	add_child(l)
	_trail = Fx.make_fire_emitter(40, 0.35, 0.5, 1.5, 25.0, 0.3, 0.7)
	_trail.direction = Vector3(0, 0, 1)
	add_child(_trail)
	_trail.emitting = true
	look_at(global_position + dir, Vector3.UP)


func _physics_process(delta: float) -> void:
	var step := dir * speed * delta
	var from := global_position
	var to := from + step
	var q := PhysicsRayQueryParameters3D.create(from, to, 1 | 4, exclude)
	var res := get_world_3d().direct_space_state.intersect_ray(q)
	if not res.is_empty():
		_explode(res["position"])
		return
	if to.y < 0.05:
		_explode(Vector3(to.x, 0.1, to.z))
		return
	global_position = to
	_travel += step.length()
	if _travel > max_range:
		_explode(global_position)


func _explode(p: Vector3) -> void:
	set_physics_process(false)
	_trail.emitting = false
	_trail.reparent(get_parent())
	get_tree().create_timer(1.0).timeout.connect(_trail.queue_free)
	Fx.explode(p - dir * 0.2, radius, damage, knockback)
	queue_free()
