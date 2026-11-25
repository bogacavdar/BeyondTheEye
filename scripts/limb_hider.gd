extends SkeletonModifier3D
## Kopan uzuvların kemiklerini sıfıra yakın küçültür.
## Animasyon her karede kemikleri yeniden ayarlasa da bu düzenleyici en son çalışır,
## böylece kopan kol/bacak/kafa gövdeden kaybolur ve kesik noktada büzülür.

var hidden_bones: Array[int] = []


func _process_modification_with_delta(_delta: float) -> void:
	_apply()


func _process_modification() -> void:
	_apply()


func _apply() -> void:
	var sk := get_skeleton()
	if sk == null:
		return
	for b in hidden_bones:
		sk.set_bone_pose_scale(b, Vector3.ONE * 0.001)
