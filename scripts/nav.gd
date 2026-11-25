extends RefCounted
## AKIŞ HARİTASI (flow field)
## Şehri 2 metrelik karelere böler. Oyuncunun bulunduğu kareden başlayarak her kareye
## "oyuncuya kaç adım var" yazar. Yaratıklar her an komşu karelerden en küçük sayılıya yürür;
## böylece binaların, arabaların etrafından dolaşıp oyuncuyu bulurlar. Yüzlerce yaratık için çok ucuz.

const INF_D := 1 << 30
const NEIGHBORS := [
	Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
	Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1),
]

var cell := 2.0
var ox := 0.0
var oz := 0.0
var w := 0
var h := 0
var blocked := PackedByteArray()
var dist := PackedInt32Array()
var _target := Vector2i(-9999, -9999)


func setup(min_x: float, min_z: float, size_x: float, size_z: float, cell_size := 2.0) -> void:
	cell = cell_size
	ox = min_x
	oz = min_z
	w = int(ceil(size_x / cell))
	h = int(ceil(size_z / cell))
	blocked.resize(w * h)
	blocked.fill(0)
	dist.resize(w * h)
	dist.fill(INF_D)


## Dünya üzerindeki bir dikdörtgeni (x,z) yürünemez işaretler.
func block_rect(r: Rect2, pad := 0.4) -> void:
	var x0 := clampi(int(floor((r.position.x - pad - ox) / cell)), 0, w - 1)
	var x1 := clampi(int(floor((r.end.x + pad - ox) / cell)), 0, w - 1)
	var z0 := clampi(int(floor((r.position.y - pad - oz) / cell)), 0, h - 1)
	var z1 := clampi(int(floor((r.end.y + pad - oz) / cell)), 0, h - 1)
	for z in range(z0, z1 + 1):
		for x in range(x0, x1 + 1):
			blocked[z * w + x] = 1
	_target = Vector2i(-9999, -9999)


func cell_of(p: Vector3) -> Vector2i:
	return Vector2i(int(floor((p.x - ox) / cell)), int(floor((p.z - oz) / cell)))


func inside(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < w and c.y < h


func center(c: Vector2i) -> Vector3:
	return Vector3(ox + (c.x + 0.5) * cell, 0.0, oz + (c.y + 0.5) * cell)


func walkable(p: Vector3) -> bool:
	var c := cell_of(p)
	return inside(c) and blocked[c.y * w + c.x] == 0


func distance_at(p: Vector3) -> int:
	var c := cell_of(p)
	if not inside(c):
		return INF_D
	return dist[c.y * w + c.x]


## Oyuncu yeni bir kareye geçtiyse tüm haritayı yeniden hesaplar (genişlik öncelikli arama).
func update(target: Vector3) -> void:
	var c := cell_of(target)
	if c == _target or not inside(c):
		return
	_target = c
	dist.fill(INF_D)
	var start := c.y * w + c.x
	dist[start] = 0
	var q := PackedInt32Array([start])
	var head := 0
	while head < q.size():
		var i := q[head]
		head += 1
		var cx := i % w
		var cy := i / w
		var nd := dist[i] + 1
		for o in NEIGHBORS:
			var nx: int = cx + o.x
			var ny: int = cy + o.y
			if nx < 0 or ny < 0 or nx >= w or ny >= h:
				continue
			var j := ny * w + nx
			if blocked[j] == 1 or dist[j] <= nd:
				continue
			if o.x != 0 and o.y != 0 and (blocked[cy * w + nx] == 1 or blocked[ny * w + cx] == 1):
				continue  # köşeden kesme
			dist[j] = nd
			q.append(j)


## Bu noktadaki yaratığın yürümesi gereken yön. Oyuncuya çok yakınsa ya da harita dışındaysa sıfır döner
## (o durumda yaratık doğrudan oyuncuya yürür).
func dir_at(p: Vector3) -> Vector3:
	var c := cell_of(p)
	if not inside(c):
		return Vector3.ZERO
	var d0 := dist[c.y * w + c.x]
	if d0 <= 2 or d0 >= INF_D:
		return Vector3.ZERO
	var best := c
	var best_d := d0
	for o in NEIGHBORS:
		var n: Vector2i = c + o
		if not inside(n):
			continue
		var dn := dist[n.y * w + n.x]
		if dn < best_d:
			if o.x != 0 and o.y != 0 and (blocked[c.y * w + n.x] == 1 or blocked[n.y * w + c.x] == 1):
				continue
			best_d = dn
			best = n
	if best == c:
		return Vector3.ZERO
	var v := center(best) - p
	v.y = 0.0
	return v.normalized()


## Oyuncudan belli adım uzaklıktaki yürünebilir kareler (yaratık doğurma noktaları).
func cells_in_range(min_steps: int, max_steps: int) -> Array:
	var out: Array = []
	for i in w * h:
		var d := dist[i]
		if d >= min_steps and d <= max_steps and blocked[i] == 0:
			out.append(center(Vector2i(i % w, i / w)))
	return out
