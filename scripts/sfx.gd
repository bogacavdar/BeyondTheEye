extends Node
## PROSEDÜREL SESLER
## Hiçbir ses dosyası kullanmadan sesleri kodla üretir (0 TL).
## İleride gerçek kayıtlarla değiştirilecek, ama vuruş hissini şimdiden test etmemizi sağlar.

const RATE := 22050
const GameData = preload("res://scripts/game_data.gd")

var streams := {}
var _players: Array[AudioStreamPlayer] = []
var _last := {}

# --- müzik: iki çalar arasında yumuşak geçiş (crossfade)
var music_volume := 0.7          # 0..1, ayarlardan değişir
var _music: Array[AudioStreamPlayer] = []
var _music_cur := 0
var _music_path := ""
var _music_base_db := -6.0
var _music_tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# ayrı ses kanalları: ayarlardan müzik ve efektler ayrı ayrı kısılabilsin
	_ensure_bus("Music")
	_ensure_bus("SFX")
	for i in 28:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_players.append(p)
	for i in 2:
		var mp := AudioStreamPlayer.new()
		mp.volume_db = -80.0
		mp.bus = "Music"
		add_child(mp)
		_music.append(mp)

	#                       süre  gürültü sönüm  filtre  ton baş/son     ton  sönüm  çıtırtı  metal
	streams["rifle"]   = _synth(0.18, 1.0, 28.0, 0.55, 190.0, 55.0, 0.9, 22.0)
	streams["shotgun"] = _synth(0.50, 1.0, 10.0, 0.30, 130.0, 38.0, 1.0, 8.0)
	streams["flesh"]   = _synth(0.15, 1.0, 30.0, 0.07, 170.0, 50.0, 1.0, 26.0, 0.03)
	streams["splat"]   = _synth(0.38, 1.0, 9.0, 0.10, 95.0, 35.0, 0.7, 12.0, 0.06)
	streams["armor"]   = _synth(0.35, 0.5, 70.0, 0.90, 0.0, 0.0, 0.0, 1.0, 0.0,
			[[1650.0, 0.5, 13.0], [2430.0, 0.4, 17.0], [3710.0, 0.25, 22.0], [910.0, 0.3, 9.0]])
	streams["armor_break"] = _synth(0.55, 0.8, 14.0, 0.60, 300.0, 110.0, 0.5, 9.0, 0.02,
			[[760.0, 0.5, 7.0], [1180.0, 0.4, 8.0], [1930.0, 0.3, 11.0]])
	streams["hurt"]    = _synth(0.28, 0.6, 12.0, 0.15, 230.0, 80.0, 1.0, 7.0)
	streams["wall"]    = _synth(0.08, 1.0, 60.0, 0.85, 0.0, 0.0, 0.0, 1.0, 0.0, [[2900.0, 0.25, 45.0]])
	streams["switch"]  = _synth(0.12, 0.6, 50.0, 0.80, 0.0, 0.0, 0.0, 1.0, 0.0, [[1200.0, 0.4, 40.0], [2400.0, 0.3, 50.0]])
	streams["dash"]    = _whoosh(0.22)
	streams["pistol"]  = _synth(0.16, 1.0, 32.0, 0.6, 240.0, 70.0, 0.8, 26.0)
	streams["revolver"] = _synth(0.45, 1.0, 11.0, 0.45, 160.0, 45.0, 1.0, 9.0)
	streams["uzi"]     = _synth(0.09, 1.0, 45.0, 0.7, 260.0, 90.0, 0.6, 40.0)
	streams["assault"] = _synth(0.2, 1.0, 22.0, 0.5, 170.0, 50.0, 0.95, 18.0)
	streams["sawed"]   = _synth(0.6, 1.0, 8.0, 0.25, 110.0, 30.0, 1.0, 6.0)
	streams["flame"]   = _synth(0.3, 1.0, 4.0, 0.18, 0.0, 0.0, 0.0, 1.0, 0.05)
	streams["rocket"]  = _whoosh(0.5)
	streams["boom"]    = _synth(1.4, 1.0, 3.2, 0.12, 70.0, 22.0, 1.0, 3.0, 0.08)
	streams["roar"]    = _synth(1.6, 1.0, 2.2, 0.06, 95.0, 38.0, 0.9, 1.6, 0.12, [[61.0, 0.5, 1.5], [83.0, 0.4, 2.0]])
	streams["coin"]    = _synth(0.22, 0.05, 80.0, 0.9, 1500.0, 1500.0, 0.7, 14.0, 0.0, [[2250.0, 0.45, 16.0], [3000.0, 0.2, 22.0]])

	# Gerçek ses dosyaları varsa geçici seslerin yerine onları kullan.
	# res://audio/ içine "flesh_1.ogg", "flesh_2.wav", "shotgun.ogg" gibi koyman yeterli.
	# Aynı sesin birden çok çeşidi varsa her seferinde rastgele biri çalar (yapaylığı kırar).
	for key in streams.keys():
		var real := _load_real(key)
		streams[key] = real if not real.is_empty() else [streams[key]]
	# sadece gerçek kayıt olarak gelen sesler (Kenney CC0): vuruş, ağır vuruş, kesme, parry çanı
	for key in ["hit", "heavyhit", "slash", "parry", "swing", "cut", "stab", "crush", "bowshot",
			"enemyhurt", "enemydie", "enemyattack", "bruteroar", "bossroar"]:
		var real := _load_real(key)
		if not real.is_empty():
			streams[key] = real
	# yedek: dosya bulunamazsa sentez sesle çal
	if not streams.has("hit"):
		streams["hit"] = streams["flesh"]
	if not streams.has("heavyhit"):
		streams["heavyhit"] = streams["splat"]
	if not streams.has("slash"):
		streams["slash"] = streams["dash"]
	if not streams.has("parry"):
		streams["parry"] = streams["armor"]
	for k in ["swing", "bowshot"]:
		if not streams.has(k):
			streams[k] = streams["dash"]
	for k in ["cut", "stab", "crush"]:
		if not streams.has(k):
			streams[k] = streams["hit"]
	for k in ["enemyhurt", "enemydie", "enemyattack", "bruteroar", "bossroar"]:
		if not streams.has(k):
			streams[k] = streams["roar"]


func _load_real(key: String) -> Array:
	var found: Array = []
	var names: Array = [key]
	for i in range(1, 9):
		names.append("%s_%d" % [key, i])
	for n in names:
		for ext in ["ogg", "wav", "mp3"]:
			var path := "res://audio/%s.%s" % [n, ext]
			if ResourceLoader.exists(path):
				var s = load(path)
				if s is AudioStream:
					found.append(s)
	return found


func play(sound: String, vol_db: float = 0.0, pitch_var: float = 0.08, min_gap_ms: int = 25, pitch: float = 1.0) -> void:
	if not streams.has(sound):
		return
	var now := Time.get_ticks_msec()
	if now - int(_last.get(sound, -100000)) < min_gap_ms:
		return
	_last[sound] = now
	var options: Array = streams[sound]
	for p in _players:
		if not p.playing:
			p.stream = options.pick_random()
			p.volume_db = vol_db
			p.pitch_scale = pitch * randf_range(1.0 - pitch_var, 1.0 + pitch_var)
			p.play()
			return


## Gürültü (filtreli) + perdesi düşen alçak ton + isteğe bağlı metal tınılar.
func _synth(dur: float, noise_amt: float, noise_decay: float, lp: float,
		tone_start: float, tone_end: float, tone_amt: float, tone_decay: float,
		crackle := 0.0, metal: Array = []) -> AudioStreamWAV:
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var lpv := 0.0
	var phase := 0.0
	for i in n:
		var t := float(i) / RATE
		var nz := randf_range(-1.0, 1.0)
		lpv += (nz - lpv) * lp
		var env := exp(-t * noise_decay)
		var s := lpv * noise_amt * env
		if crackle > 0.0 and randf() < crackle:
			s += randf_range(-1.0, 1.0) * 0.8 * env
		var f := lerpf(tone_start, tone_end, minf(t / (dur * 0.35), 1.0))
		phase += TAU * f / RATE
		s += sin(phase) * tone_amt * exp(-t * tone_decay)
		for m in metal:
			s += sin(TAU * float(m[0]) * t) * float(m[1]) * exp(-t * float(m[2]))
		s *= minf(t / 0.002, 1.0)
		out[i] = s
	return _finish(out)


func _whoosh(dur: float) -> AudioStreamWAV:
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var a := 0.0
	var b := 0.0
	for i in n:
		var t := float(i) / RATE
		var nz := randf_range(-1.0, 1.0)
		a += (nz - a) * 0.35
		b += (a - b) * 0.05
		out[i] = (a - b) * sin(PI * t / dur)
	return _finish(out)


func _finish(out: PackedFloat32Array) -> AudioStreamWAV:
	var peak := 0.0
	for v in out:
		peak = maxf(peak, absf(v))
	var data := PackedByteArray()
	data.resize(out.size() * 2)
	for i in out.size():
		var v := out[i] / peak * 0.9 if peak > 0.0 else 0.0
		data.encode_s16(i * 2, int(clampf(v, -1.0, 1.0) * 32767.0))
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = RATE
	s.stereo = false
	s.data = data
	return s


# ---------------------------------------------------------------- M tuşu: müziği aç/kapat (her yerde)

func _unhandled_key_input(event: InputEvent) -> void:
	# Alt + Enter: tam ekran aç/kapat (her yerde)
	var k := event as InputEventKey
	if k != null and k.pressed and not k.echo and k.alt_pressed and (k.keycode == KEY_ENTER or k.keycode == KEY_KP_ENTER):
		GameData.fullscreen = not GameData.fullscreen
		GameData.apply_settings()
		GameData.go_save()
		get_viewport().set_input_as_handled()


# ---------------------------------------------------------------- giriş türü ve kontrolcüyle menü gezinme

var _focus_t := 0.0


func _input(event: InputEvent) -> void:
	var mode := GameData.input_mode
	if event is InputEventJoypadButton and event.pressed:
		mode = "pad"
	elif event is InputEventJoypadMotion and absf(event.axis_value) > 0.4:
		mode = "pad"
	elif event is InputEventScreenTouch:
		mode = "touch"
	elif event is InputEventMouseMotion and event.device != InputEvent.DEVICE_ID_EMULATION and event.relative.length() > 3.0:
		mode = "mouse" if not GameData.is_mobile() else mode
	elif event is InputEventKey and event.pressed:
		mode = "mouse" if not GameData.is_mobile() else mode
	if mode != GameData.input_mode:
		GameData.input_mode = mode


## Menü açıkken kontrolcü kullanılıyorsa ve hiçbir düğme seçili değilse ilk görünür düğmeyi seçer
func _pad_focus(delta: float) -> void:
	if GameData.input_mode != "pad":
		return
	_focus_t -= delta
	if _focus_t > 0.0:
		return
	_focus_t = 0.2
	if not _ui_mode():
		return
	var vp := get_viewport()
	var cur := vp.gui_get_focus_owner()
	if cur != null and cur.is_visible_in_tree():
		return
	var sc := get_tree().current_scene
	if sc == null:
		return
	var b := _first_button(sc)
	if b != null:
		b.grab_focus()


func _ui_mode() -> bool:
	if get_tree().paused:
		return true
	var sc := get_tree().current_scene
	if sc == null:
		return false
	if sc.get("hero") != null:
		var h = sc.get("hud")
		if h != null:
			var ob = h.get("over_box")
			var vb = h.get("victory_box")
			return (ob != null and ob.visible) or (vb != null and vb.visible)
		return false
	if sc.get("player") != null:
		return bool(sc.player.get("frozen"))
	return true


func _first_button(n: Node) -> BaseButton:
	if n is BaseButton:
		var bb := n as BaseButton
		if bb.is_visible_in_tree() and not bb.disabled and bb.focus_mode != Control.FOCUS_NONE:
			return bb
	for c in n.get_children():
		var r := _first_button(c)
		if r != null:
			return r
	return null


func _process(_d: float) -> void:
	_pad_focus(_d)
	if InputMap.has_action("mute_music") and Input.is_action_just_pressed("mute_music"):
		GameData.music_muted = not GameData.music_muted
		set_bus_volume("Music", 0.0 if GameData.music_muted else GameData.music_volume)
		GameData.go_save()
		play("switch", -10.0, 0.0, 0, 0.7 if GameData.music_muted else 1.3)


# ---------------------------------------------------------------- müzik

func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) != -1:
		return
	AudioServer.add_bus()
	var i := AudioServer.bus_count - 1
	AudioServer.set_bus_name(i, bus_name)
	AudioServer.set_bus_send(i, "Master")


func _music_db() -> float:
	return _music_base_db


## Müziği değiştirir: eski parça kısılırken yenisi yükselir. Aynı parça zaten çalıyorsa dokunmaz.
## Parçalar döngüde çalar. vol_db parçanın kendi seviyesi (ayardaki müzik sesiyle çarpılır).
func play_music(path: String, vol_db := -6.0, fade := 2.0) -> void:
	if path == _music_path:
		return
	if not ResourceLoader.exists(path):
		push_warning("Müzik bulunamadı: " + path)
		return
	var stream = load(path)
	if stream is AudioStreamMP3 or stream is AudioStreamOggVorbis:
		stream.loop = true
	elif stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	_music_path = path
	_music_base_db = vol_db
	var old := _music[_music_cur]
	_music_cur = 1 - _music_cur
	var nxt := _music[_music_cur]
	nxt.stream = stream
	nxt.volume_db = -60.0
	nxt.play()
	if _music_tween != null and _music_tween.is_valid():
		_music_tween.kill()
	_music_tween = create_tween().set_parallel(true)
	_music_tween.tween_property(nxt, "volume_db", _music_db(), fade).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if old.playing:
		_music_tween.tween_property(old, "volume_db", -60.0, fade).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		_music_tween.chain().tween_callback(old.stop)


func stop_music(fade := 1.5) -> void:
	_music_path = ""
	var cur := _music[_music_cur]
	if _music_tween != null and _music_tween.is_valid():
		_music_tween.kill()
	_music_tween = create_tween()
	_music_tween.tween_property(cur, "volume_db", -60.0, fade)
	_music_tween.tween_callback(cur.stop)


## Ayarlardan ses seviyeleri (0..1) değişince anında uygula
func set_bus_volume(bus_name: String, v: float) -> void:
	var i := AudioServer.get_bus_index(bus_name)
	if i == -1:
		return
	AudioServer.set_bus_volume_db(i, linear_to_db(maxf(v, 0.0001)))
	AudioServer.set_bus_mute(i, v <= 0.001)


func set_music_volume(v: float) -> void:
	music_volume = v
	set_bus_volume("Music", v)
