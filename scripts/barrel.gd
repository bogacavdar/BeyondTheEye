extends StaticBody3D
## PATLAYAN VARİL
## Kırmızı, üstünde uyarı şeridi parlayan varil. Birkaç mermi yiyince patlar,
## çevresindeki yaratıkları parçalar ve yakındaki diğer varilleri de zincirleme patlatır.

var hp := 30.0
var exploded := false


func _ready() -> void:
	add_to_group("explosive")
	collision_layer = 1
	var cs := CollisionShape3D.new()
	var sh := CylinderShape3D.new()
	sh.radius = 0.42
	sh.height = 1.15
	cs.shape = sh
	cs.position.y = 0.575
	add_child(cs)

	var body := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.4
	cm.bottom_radius = 0.4
	cm.height = 1.15
	body.mesh = cm
	body.material_override = Fx.mat(Color(0.6, 0.05, 0.04), 0.5, 0.35)
	body.position.y = 0.575
	add_child(body)

	var band := MeshInstance3D.new()
	var bm := CylinderMesh.new()
	bm.top_radius = 0.41
	bm.bottom_radius = 0.41
	bm.height = 0.12
	band.mesh = bm
	band.material_override = Fx.emissive(Color(1.0, 0.8, 0.1), 4.0)
	band.position.y = 0.8
	band.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(band)


func take_hit(dmg: float, dir: Vector3, _knockback: float, point: Vector3, _w: Dictionary) -> void:
	if exploded:
		return
	hp -= dmg
	Fx.sparks(point, -dir)
	Sfx.play("armor", -12.0, 0.15, 60)
	if hp <= 0.0:
		detonate()


func take_explosion(_dmg: float, _dir: Vector3, _kb: float, _origin: Vector3) -> void:
	if exploded:
		return
	# zincirleme patlama: kısa gecikmeyle, art arda patlasınlar
	exploded = true
	get_tree().create_timer(randf_range(0.08, 0.2)).timeout.connect(_boom)


func detonate() -> void:
	if exploded:
		return
	exploded = true
	_boom()


func _boom() -> void:
	if not is_inside_tree():
		return
	var p := global_position + Vector3(0, 0.6, 0)
	queue_free()
	Fx.explode(p, 5.5, 160.0, 16.0)
