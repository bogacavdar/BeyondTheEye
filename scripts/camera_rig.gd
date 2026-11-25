extends Camera3D

const GameData = preload("res://scripts/game_data.gd")
## İzometrik takip kamerası: yumuşak takip, nişan yönüne hafif kayma, sarsıntı.

var target: Node3D = null
var offset := Vector3(11.0, 17.0, 11.0)
var follow_speed := 7.0
var look_ahead := Vector3.ZERO
var trauma := 0.0
var shake_power := 0.5
var _snapped := false


func _ready() -> void:
	fov = 38.0
	far = 200.0
	current = true
	basis = Basis.looking_at(-offset.normalized(), Vector3.UP)


func add_trauma(amount: float) -> void:
	trauma = minf(trauma + amount, 1.0)


func _process(delta: float) -> void:
	if target == null or not is_instance_valid(target):
		return
	var desired := target.global_position + offset + look_ahead
	if not _snapped:
		global_position = desired
		_snapped = true
	else:
		global_position = global_position.lerp(desired, 1.0 - exp(-follow_speed * delta))

	trauma = maxf(trauma - delta * 2.5, 0.0)
	var s := trauma * trauma * shake_power * GameData.shake_mult
	h_offset = randf_range(-1.0, 1.0) * s
	v_offset = randf_range(-1.0, 1.0) * s
