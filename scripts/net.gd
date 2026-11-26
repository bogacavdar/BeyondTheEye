extends Node
## ÇEVRİM İÇİ İKİZLER (host / katıl). Otomatik yüklenen tekil: /root/Net
##
## Yapı (host yetkili):
##  - Oyunun gerçeği host'tadır: dalgalar, düşman yapay zekâsı, bosslar, tehlikeler, ödüller, kapılar.
##  - Katılan oyuncu (client) kendi kahramanını kendi bilgisayarında oynatır ve konumunu host'a yollar.
##    Host'ta bu kahramanın bir kopyası (hero2, remote) durur; düşmanlar ona saldırır, hasar client'a iletilir.
##  - Client'taki düşmanlar ve bosslar "kukla"dır (puppet): yapay zekâları kapalı, host'un anlık görüntüsüyle
##    (konum, yön, durum, saldırı, can) hareket ederler. Client'ın vuruşları host'a iletilir.
##  - Tehlikeler (patlama, hat, göl, mermi, dönen kollar, rüzgâr, dalga, köpük...) host'ta doğunca client'ta
##    görsel kopyaları oluşur; hasarı host'taki asılları verir.
##  - Oda geçişleri, kapılar, başlıklar, lütuflar ve run sonu host'tan bildirilir.
## Bağlantı: ENet (UDP) PORT. Aynı ağda doğrudan; internetten host'un modeminde bu portun açılması gerekir.

signal status_changed(text: String)

const PORT := 24680
const SNAP_HZ := 20.0
const H = preload("res://scripts/hazards.gd")
const EnemyScript = preload("res://scripts/enemy.gd")

var role := ""             # "" / "host" / "client"
var connected := false
var status := ""
var room = null             # şu anki oda (her iki tarafta)
var _snap_t := 0.0
var _send_t := 0.0
var _nid := 0
var _nodes := {}            # nid -> düğüm (her iki tarafta)
var _shots := {}            # client: nid -> genel mermi küresi
var _hz_classes := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_hz_classes = {"Blast": H.Blast, "Line": H.Line, "Pool": H.Pool, "Shot": H.Shot, "Spokes": H.Spokes, "Gust": H.Gust,
		"TideWave": EnemyScript.TideWave, "Bubble": EnemyScript.Bubble, "SunBeam": EnemyScript.SunBeam,
		"Bolt": EnemyScript.Bolt, "Fireball": EnemyScript.Fireball, "EmberBurst": EnemyScript.EmberBurst,
		"ThornPatch": EnemyScript.ThornPatch, "Fissure": EnemyScript.Fissure, "WindBlade": EnemyScript.WindBlade}
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected)
	multiplayer.connection_failed.connect(_on_failed)
	multiplayer.server_disconnected.connect(_on_server_gone)


func online() -> bool:
	return role != "" and connected


func is_host() -> bool:
	return role == "host" and connected


func is_client() -> bool:
	return role == "client" and connected


func _set_status(t: String) -> void:
	status = t
	status_changed.emit(t)


# ---------------------------------------------------------------- bağlantı

func host() -> bool:
	leave()
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(PORT, 1)
	if err != OK:
		_set_status(tr("Could not open the game (port %d busy?)") % PORT)
		return false
	multiplayer.multiplayer_peer = peer
	role = "host"
	connected = false
	_set_status(tr("Waiting for a friend... Your address: %s") % ", ".join(local_ips()))
	return true


func join(ip: String) -> bool:
	leave()
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(ip.strip_edges(), PORT)
	if err != OK:
		_set_status(tr("Could not connect."))
		return false
	multiplayer.multiplayer_peer = peer
	role = "client"
	connected = false
	_set_status(tr("Connecting to %s ...") % ip)
	return true


func leave() -> void:
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = null
	role = ""
	connected = false
	_nodes.clear()
	_shots.clear()
	_set_status("")


func local_ips() -> Array:
	var out: Array = []
	for a in IP.get_local_addresses():
		var s := String(a)
		if s.count(".") == 3 and not s.begins_with("127.") and not s.begins_with("169.254"):
			out.append(s)
	return out


func _on_peer_connected(_id: int) -> void:
	connected = true
	if role == "host":
		_set_status(tr("Friend connected! Enter the portal to start."))


func _on_peer_disconnected(_id: int) -> void:
	connected = false
	if role == "host":
		_set_status(tr("Your friend left."))
		if room != null and is_instance_valid(room):
			room.net_partner_left()


func _on_connected() -> void:
	connected = true
	_set_status(tr("Connected! Waiting for the host to start the run."))


func _on_failed() -> void:
	_set_status(tr("Could not connect. Check the address and the host's port %d.") % PORT)
	leave()


func _on_server_gone() -> void:
	var was_room: bool = room != null and is_instance_valid(room)
	leave()
	_set_status(tr("The host left."))
	if was_room:
		load("res://scripts/game_data.gd").coop_unbind()
		get_tree().paused = false
		Engine.time_scale = 1.0
		get_tree().change_scene_to_file("res://scenes/hub.tscn")


# ---------------------------------------------------------------- oda başlangıcı

## Host'ta oda kurulunca client'a "bu odaya geç" denir; client'ta oda kurulunca kendini kaydeder
func room_ready(r) -> void:
	room = r
	_nodes.clear()
	_shots.clear()
	_nid = 0
	if not get_tree().node_added.is_connected(_on_node_added):
		get_tree().node_added.connect(_on_node_added)
	if is_host():
		var GD = load("res://scripts/game_data.gd")
		var data := {"room": GD.run_room, "reward": GD.run_reward, "boons": GD.run_boons, "cycle": GD.run_cycle,
			"rising": GD.run_rising, "retro": GD.retro}
		rpc_id(_peer(), "_c_goto", data)


func room_left(r) -> void:
	if room == r:
		room = null
	if get_tree().node_added.is_connected(_on_node_added):
		get_tree().node_added.disconnect(_on_node_added)


func _peer() -> int:
	var ps := multiplayer.get_peers()
	return int(ps[0]) if ps.size() > 0 else 0


@rpc("authority", "call_remote", "reliable")
func _c_goto(data: Dictionary) -> void:
	var GD = load("res://scripts/game_data.gd")
	# client kendi kahramanının canını korur
	if room != null and is_instance_valid(room) and room.hero != null and is_instance_valid(room.hero):
		GD.run_hp = room.hero.hp if not room.hero.dead else room.hero.max_hp * 0.25
	GD.run_room = int(data["room"])
	GD.run_reward = String(data["reward"])
	GD.run_boons = Array(data["boons"])
	GD.run_cycle = int(data["cycle"])
	GD.run_rising = String(data["rising"])
	GD.retro = data["retro"]
	get_tree().paused = false
	Engine.time_scale = 1.0
	get_tree().change_scene_to_file("res://scenes/room.tscn")


## Host lütuf seçince client'ın kahramanı da aynı lütuflarla güçlenir
func sync_boons() -> void:
	if is_host():
		var GD = load("res://scripts/game_data.gd")
		rpc_id(_peer(), "_c_boons", GD.run_boons)


@rpc("authority", "call_remote", "reliable")
func _c_boons(boons: Array) -> void:
	var GD = load("res://scripts/game_data.gd")
	GD.run_boons = boons
	if room != null and is_instance_valid(room) and room.hero != null:
		room.hero._compute_stats()


# ---------------------------------------------------------------- host: yeni düğümleri çoğalt

func _on_node_added(n: Node) -> void:
	if is_host():
		call_deferred("_rep_node", n)
	elif is_client() and n.get_script() != null and String(n.get_script().resource_path) == "":
		# client: kopyaların kendi ürettiği alt tehlikeler (göl, patlama...) host'tan zaten gelir; çift olmasın
		call_deferred("_drop_local_hz", n)


func _drop_local_hz(n: Node) -> void:
	if n != null and is_instance_valid(n) and not n.has_meta("net_copy") and _hz_name(n) != "":
		n.queue_free()


func _hz_name(n: Node) -> String:
	var sc = n.get_script()
	for k in _hz_classes:
		if sc == _hz_classes[k]:
			return String(k)
	return ""


func _props(n: Object) -> Dictionary:
	var d := {}
	for p in n.get_property_list():
		if not (int(p["usage"]) & PROPERTY_USAGE_SCRIPT_VARIABLE):
			continue
		var nm := String(p["name"])
		if nm.begins_with("_") or nm == "hero":
			continue
		var t := int(p["type"])
		if t in [TYPE_FLOAT, TYPE_INT, TYPE_BOOL, TYPE_STRING, TYPE_VECTOR3, TYPE_VECTOR2, TYPE_COLOR]:
			d[nm] = n.get(nm)
	return d


func _rep_node(n: Node) -> void:
	if n == null or not is_instance_valid(n) or not n.is_inside_tree() or n.has_meta("nid"):
		return
	var hz := _hz_name(n)
	if hz != "":
		var p := _props(n)
		var f = n.get("follow")
		if f != null and is_instance_valid(f) and f.has_meta("nid"):
			p["follow_nid"] = int(f.get_meta("nid"))
		var n3 := n as Node3D
		rpc_id(_peer(), "_c_hazard", hz, p, n3.global_position, n3.global_rotation)
		return
	if n.is_in_group("enemies") and n.get_script() != null and String(n.get_script().resource_path) != "":
		_nid += 1
		n.set_meta("nid", _nid)
		_nodes[_nid] = n
		var info := {}
		for k in ["zone", "kind", "elite", "affixes", "mini", "who", "title", "size_k"]:
			var v = n.get(k)
			if v != null:
				info[k] = v
		rpc_id(_peer(), "_c_spawn", _nid, String(n.get_script().resource_path), info, (n as Node3D).global_position)
		return
	if n.is_in_group("enemy_shot") and n is Node3D:
		_nid += 1
		n.set_meta("nid", _nid)
		_nodes[_nid] = n


@rpc("authority", "call_remote", "reliable")
func _c_hazard(cls: String, p: Dictionary, pos: Vector3, rot: Vector3) -> void:
	if room == null or not is_instance_valid(room) or not _hz_classes.has(cls):
		return
	var h = _hz_classes[cls].new()
	h.set_meta("net_copy", true)
	for k in p:
		if k == "follow_nid":
			continue
		h.set(k, p[k])
	h.hero = null
	if p.has("follow_nid") and _nodes.has(int(p["follow_nid"])):
		h.set("follow", _nodes[int(p["follow_nid"])])
	room.add_child(h)
	h.global_position = pos
	if cls == "Spokes":
		h.global_rotation = rot


@rpc("authority", "call_remote", "reliable")
func _c_spawn(nid: int, path: String, info: Dictionary, pos: Vector3) -> void:
	if room == null or not is_instance_valid(room) or not ResourceLoader.exists(path):
		return
	var e = load(path).new()
	for k in info:
		e.set(k, info[k])
	e.set("puppet", true)
	e.set("hero", null)
	e.set_meta("nid", nid)
	room.add_child(e)
	e.global_position = pos
	e.set("_net_pos", pos)
	_nodes[nid] = e
	if e.get("phase") != null and room.hud != null:
		room.hud.boss = e


# ---------------------------------------------------------------- anlık görüntüler

func _physics_process(delta: float) -> void:
	if not online() or room == null or not is_instance_valid(room):
		return
	if is_host():
		_snap_t -= delta
		if _snap_t <= 0.0:
			_snap_t = 1.0 / SNAP_HZ
			_send_snapshot()
	elif is_client():
		_send_t -= delta
		if _send_t <= 0.0:
			_send_t = 1.0 / 30.0
			_send_me()


func _hero_pack(h) -> Array:
	if h == null or not is_instance_valid(h):
		return []
	return [h.global_position.x, h.global_position.z, h.pivot.rotation.y if h.pivot != null else 0.0, h.dead, h.hp, h.max_hp, String(h.state), h.velocity.length()]


func _send_snapshot() -> void:
	var es: Array = []
	var gone: Array = []
	for nid in _nodes:
		var n = _nodes[nid]
		if n == null or not is_instance_valid(n):
			gone.append(nid)
			continue
		if n.is_in_group("enemy_shot"):
			var c: Color = n.get("col") if n.get("col") != null else Color(1.0, 0.6, 0.3)
			es.append([nid, 1, n.global_position, c])
			continue
		var f: Vector3 = n.get("_face") if n.get("_face") != null else Vector3.FORWARD
		var a: Vector3 = n.get("_aim_dir") if n.get("_aim_dir") != null else f
		var atk_name := ""
		var at = n.get("atk")
		if at is Dictionary:
			atk_name = String(at.get("name", ""))
		elif at is String:
			atk_name = String(at)
		es.append([nid, 0, n.global_position, f.x, f.z, String(n.get("state")), atk_name, a.x, a.z,
			float(n.get("hp")), float(n.get("max_hp")), bool(n.get("dead")), int(n.get("phase")) if n.get("phase") != null else 0])
	for g in gone:
		_nodes.erase(g)
	var GD = load("res://scripts/game_data.gd")
	rpc_id(_peer(), "_c_snap", _hero_pack(room.hero), es, gone, GD.run_dust)


@rpc("authority", "call_remote", "unreliable_ordered")
func _c_snap(hp: Array, es: Array, gone: Array, dust: int) -> void:
	if room == null or not is_instance_valid(room):
		return
	if room.hero2 != null and hp.size() > 0:
		room.hero2.net_apply(hp)
	var GD = load("res://scripts/game_data.gd")
	GD.run_dust = dust
	var seen := {}
	for e in es:
		var nid := int(e[0])
		seen[nid] = true
		if int(e[1]) == 1:
			_c_shot(nid, e[2], e[3])
			continue
		var n = _nodes.get(nid)
		if n == null or not is_instance_valid(n):
			continue
		n.net_apply(e)
	for g in gone:
		var n = _nodes.get(int(g))
		if n != null and is_instance_valid(n) and not bool(n.get("dead")):
			n.queue_free()
		_nodes.erase(int(g))
		if _shots.has(int(g)):
			_shots[int(g)].queue_free()
			_shots.erase(int(g))
	# görüntüden kaybolan mermiler
	for nid in _shots.keys():
		if not seen.has(nid):
			if is_instance_valid(_shots[nid]):
				_shots[nid].queue_free()
			_shots.erase(nid)


func _c_shot(nid: int, pos: Vector3, col: Color) -> void:
	var s = _shots.get(nid)
	if s == null or not is_instance_valid(s):
		s = MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.25
		sm.height = 0.5
		s.mesh = sm
		s.material_override = Fx.emissive(col, 4.0)
		room.add_child(s)
		_shots[nid] = s
		s.global_position = pos
	s.global_position = s.global_position.lerp(pos, 0.6)


func _send_me() -> void:
	rpc_id(1, "_h_me", _hero_pack(room.hero))


@rpc("any_peer", "call_remote", "unreliable_ordered")
func _h_me(p: Array) -> void:
	if room != null and is_instance_valid(room) and room.hero2 != null and p.size() > 0:
		room.hero2.net_apply(p)


# ---------------------------------------------------------------- olaylar

## client'ın kahramanı bir kuklaya vurdu: host'taki asıl düşmana uygula
func send_hit(n: Node, dmg: float, dir: Vector3, kb: float, heavy: bool, crit: bool) -> void:
	if not is_client() or not n.has_meta("nid"):
		return
	rpc_id(1, "_h_hit", int(n.get_meta("nid")), dmg, dir, kb, heavy, crit)


@rpc("any_peer", "call_remote", "reliable")
func _h_hit(nid: int, dmg: float, dir: Vector3, kb: float, heavy: bool, crit: bool) -> void:
	var n = _nodes.get(nid)
	if n != null and is_instance_valid(n) and not bool(n.get("dead")):
		n.take_hit(dmg, dir, kb, heavy, crit)


## host'taki kopya kahraman hasar aldı: client'taki asıl kahramana uygula
func send_hurt(kind: String, a: Array) -> void:
	if is_host():
		rpc_id(_peer(), "_c_hurt", kind, a)


@rpc("authority", "call_remote", "reliable")
func _c_hurt(kind: String, a: Array) -> void:
	if room == null or not is_instance_valid(room) or room.hero == null:
		return
	var h = room.hero
	match kind:
		"dmg":
			h.take_damage(float(a[0]), a[1], bool(a[2]))
		"slow":
			h.apply_slow(float(a[0]), float(a[1]))
		"poison":
			h.apply_poison(float(a[0]), float(a[1]))
		"pull":
			h.apply_pull(a[0], float(a[1]), float(a[2]))
		"revive":
			h.revive(float(a[0]))
		"heal":
			h.heal(float(a[0]))


## Kılıç savuruşu görüntüsü karşı tarafta da çıksın
func send_slash(a0: float, a1: float, rng: float, col: Color, xf: Transform3D) -> void:
	if online():
		rpc_id(_peer() if is_host() else 1, "_x_slash", a0, a1, rng, col, xf)


@rpc("any_peer", "call_remote", "unreliable")
func _x_slash(a0: float, a1: float, rng: float, col: Color, xf: Transform3D) -> void:
	if room == null or not is_instance_valid(room):
		return
	var fx = load("res://scripts/slash_fx.gd").make(a0, a1, 0.45, rng, col)
	room.add_child(fx)
	fx.global_transform = xf


func send_banner(a: String, b: String) -> void:
	if is_host():
		rpc_id(_peer(), "_c_banner", a, b)


@rpc("authority", "call_remote", "reliable")
func _c_banner(a: String, b: String) -> void:
	if room != null and is_instance_valid(room) and room.hud != null:
		room.hud.banner(a, b)


func send_door(pos: Vector3, type: String) -> void:
	if is_host():
		rpc_id(_peer(), "_c_door", pos, type)


@rpc("authority", "call_remote", "reliable")
func _c_door(pos: Vector3, type: String) -> void:
	if room != null and is_instance_valid(room):
		room._add_door(pos, type)


func send_run_over(death: bool) -> void:
	if is_host():
		rpc_id(_peer(), "_c_run_over", death)


@rpc("authority", "call_remote", "reliable")
func _c_run_over(death: bool) -> void:
	if room != null and is_instance_valid(room):
		room.net_run_over(death)
