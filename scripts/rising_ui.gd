extends Control
## Yükselen seçimi: portala girerken açılır. "Yükselensiz" de seçilebilir.

const UI = preload("res://scripts/ui_style.gd")
const Risings = preload("res://scripts/risings.gd")

signal chosen(id: String)
signal closed

var _box: VBoxContainer


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var bg := ColorRect.new()
	bg.color = Color(0.01, 0.015, 0.05, 0.82)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var p := UI.panel()
	center.add_child(p)
	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 10)
	p.add_child(_box)
	visible = false


var _online_view := false
var _ip_text := ""


func open() -> void:
	for c in _box.get_children():
		c.queue_free()
	if _online_view or Net.is_client():
		_open_online()
		return
	var t := UI.label(tr("CHOOSE YOUR RISING SIGN"), 34, UI.GOLD, 5)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_box.add_child(t)
	var sub := UI.label(tr("It changes the rules of this run. Defeat a sign's boss to unlock its rising."), 17, UI.CREAM, 3)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_box.add_child(sub)
	# gök yoldaşı seçimi
	var ct := UI.label(tr("SKY COMPANION"), 22, UI.GOLD, 4)
	ct.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_box.add_child(ct)
	var crow := HBoxContainer.new()
	crow.add_theme_constant_override("separation", 10)
	crow.alignment = BoxContainer.ALIGNMENT_CENTER
	_box.add_child(crow)
	var CompS = load("res://scripts/companion.gd")
	var GD = load("res://scripts/game_data.gd")
	for cinfo in CompS.LIST:
		var cid := String(cinfo["id"])
		var open_ := bool(CompS.unlocked(cid))
		var lv := int(CompS.lvl(int(GD.comp_runs.get(cid, 0))))
		var sel := String(GD.companion) == cid
		var cb := UI.button(("✓ " if sel else "") + tr(String(cinfo["name"])) + ("  " + tr("LV") + " %d" % lv if open_ else ""), 16, cinfo["col"] if open_ else Color(0.4, 0.4, 0.45))
		cb.custom_minimum_size = Vector2(222, 50)
		cb.disabled = not open_
		cb.tooltip_text = tr(String(cinfo["desc"]))
		cb.pressed.connect(func():
			GD.companion = "" if sel else cid
			GD.go_save()
			open())
		crow.add_child(cb)
	var cd_txt := tr("No companion")
	if String(GD.companion) != "":
		cd_txt = tr(String(CompS.get_info(String(GD.companion)).get("desc", "")))
	var cdl := UI.label(cd_txt, 15, UI.CREAM, 3)
	cdl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cdl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_box.add_child(cdl)
	# ÇEVRİM İÇİ İKİZLER: host / katıl ekranı
	if not GD.is_mobile():
		var ob := UI.button("🌐︎  " + (tr("ONLINE: CONNECTED") if Net.online() else tr("ONLINE CO-OP")), 18, Color(0.55, 0.85, 1.0))
		ob.custom_minimum_size = Vector2(330, 50)
		ob.pressed.connect(func():
			_online_view = true
			open())
		var orow := HBoxContainer.new()
		orow.alignment = BoxContainer.ALIGNMENT_CENTER
		orow.add_child(ob)
		_box.add_child(orow)
	# İKİZLER: yerel co-op (bilgisayarda, en az bir kontrolcüyle)
	if not GD.is_mobile() and not Net.online():
		var pads := Input.get_connected_joypads().size()
		var coop_row := HBoxContainer.new()
		coop_row.alignment = BoxContainer.ALIGNMENT_CENTER
		coop_row.add_theme_constant_override("separation", 14)
		_box.add_child(coop_row)
		var cb := UI.button(("♊︎  " + tr("TWINS: 2 PLAYERS")) if GD.coop else ("♊︎  " + tr("TWINS: OFF")), 18, Color(0.75, 0.55, 1.0) if GD.coop else UI.CREAM)
		cb.custom_minimum_size = Vector2(330, 50)
		cb.disabled = pads == 0 and not GD.coop
		cb.pressed.connect(func():
			GD.coop = not GD.coop
			open())
		coop_row.add_child(cb)
		var hint := tr("Player 2 plays with a controller. One controller: Player 1 uses keyboard and mouse.") if pads > 0 else tr("Connect a controller for Player 2.")
		if pads >= 2:
			hint = tr("Two controllers: each player uses their own.")
		var hl := UI.label(hint, 14, Color(0.75, 0.75, 0.85), 3)
		hl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hl.custom_minimum_size = Vector2(520, 0)
		coop_row.add_child(hl)
	# SONSUZ GÖKYÜZÜ döngü seçimi (Balık yenildikten sonra)
	if int(GD.sky_best) >= 1:
		var st := UI.label(tr("ENDLESS SKY"), 22, Color(0.85, 0.65, 1.0), 4)
		st.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_box.add_child(st)
		var srow := HBoxContainer.new()
		srow.add_theme_constant_override("separation", 10)
		srow.alignment = BoxContainer.ALIGNMENT_CENTER
		_box.add_child(srow)
		var cyc := clampi(int(GD.sky_cycle), 0, int(GD.sky_best))
		var minus := UI.button("◀", 20)
		minus.custom_minimum_size = Vector2(60, 50)
		minus.disabled = cyc <= 0
		minus.pressed.connect(func():
			GD.sky_cycle = cyc - 1
			GD.go_save()
			open())
		srow.add_child(minus)
		var cl := UI.label((tr("CYCLE") + " %d" % cyc) if cyc > 0 else tr("NORMAL SKY"), 22, Color(0.85, 0.65, 1.0) if cyc > 0 else UI.CREAM, 4)
		cl.custom_minimum_size = Vector2(260, 0)
		cl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		srow.add_child(cl)
		var plus := UI.button("▶", 20)
		plus.custom_minimum_size = Vector2(60, 50)
		plus.disabled = cyc >= int(GD.sky_best)
		plus.pressed.connect(func():
			GD.sky_cycle = cyc + 1
			GD.go_save()
			open())
		srow.add_child(plus)
		var sd := tr("Enemies +%d%% health, +%d%% damage. Every boss carries the echo of another sign. Stardust +%d%%.") % [40 * cyc, 20 * cyc, 50 * cyc] if cyc > 0 else tr("Defeat Pisces in a cycle to unlock the next one.")
		var sdl := UI.label(sd, 15, UI.CREAM, 3)
		sdl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sdl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		sdl.custom_minimum_size = Vector2(900, 0)
		_box.add_child(sdl)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 10)
	_box.add_child(grid)
	for r in Risings.LIST:
		grid.add_child(_option(r, Risings.unlocked(String(r["id"]))))
	var none := UI.button(tr("NO RISING SIGN"), 20)
	none.pressed.connect(func(): chosen.emit(""))
	_box.add_child(none)
	var back := UI.button(tr("BACK"), 18)
	back.pressed.connect(func(): visible = false; closed.emit())
	_box.add_child(back)
	visible = true


func _option(r: Dictionary, open_: bool) -> Control:
	var b := UI.button("", 18, r["col"])
	b.custom_minimum_size = Vector2(460, 96)
	b.disabled = not open_
	var vb := VBoxContainer.new()
	vb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vb.offset_left = 14
	vb.offset_right = -14
	vb.offset_top = 8
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(vb)
	var head := UI.label(String(r["glyph"]) + "︎  " + tr(String(r["name"])), 22, r["col"] if open_ else Color(0.5, 0.5, 0.55), 4)
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(head)
	var d := UI.label(tr(String(r["desc"])) if open_ else tr("Locked: defeat this sign's boss"), 15, UI.CREAM if open_ else Color(0.55, 0.55, 0.6), 3)
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(d)
	b.pressed.connect(func(): chosen.emit(String(r["id"])))
	return b


func _process(_d: float) -> void:
	if visible and Input.is_action_just_pressed("ui_cancel"):
		visible = false
		closed.emit()


## Çevrim içi ekranı: oyun aç (host) ya da IP ile katıl
func _open_online() -> void:
	var t := UI.label(tr("ONLINE CO-OP"), 34, UI.GOLD, 5)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_box.add_child(t)
	var info := UI.label(tr("One player opens the game, the other joins with their address. On the same network it works directly; over the internet the host must open UDP port %d on their modem.") % Net.PORT, 16, UI.CREAM, 3)
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.custom_minimum_size = Vector2(900, 0)
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_box.add_child(info)
	var st := UI.label(Net.status if Net.status != "" else tr("Not connected."), 20, Color(0.55, 0.85, 1.0), 4)
	st.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	st.custom_minimum_size = Vector2(900, 0)
	st.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_box.add_child(st)
	if not Net.status_changed.is_connected(_on_net_status):
		Net.status_changed.connect(_on_net_status)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 14)
	_box.add_child(row)
	if Net.role == "":
		var hb := UI.button(tr("HOST A GAME"), 20, UI.GOLD)
		hb.custom_minimum_size = Vector2(280, 56)
		hb.pressed.connect(func():
			Net.host()
			open())
		row.add_child(hb)
		var ip := LineEdit.new()
		ip.placeholder_text = tr("Host's address (e.g. 192.168.1.20)")
		ip.text = _ip_text
		ip.custom_minimum_size = Vector2(330, 56)
		ip.add_theme_font_size_override("font_size", 20)
		ip.text_changed.connect(func(v: String): _ip_text = v)
		row.add_child(ip)
		var jb := UI.button(tr("JOIN"), 20, Color(0.55, 0.85, 1.0))
		jb.custom_minimum_size = Vector2(180, 56)
		jb.pressed.connect(func():
			if _ip_text.strip_edges() != "":
				Net.join(_ip_text)
				open())
		row.add_child(jb)
	else:
		var lb := UI.button(tr("DISCONNECT"), 18, Color(1.0, 0.6, 0.55))
		lb.custom_minimum_size = Vector2(260, 52)
		lb.pressed.connect(func():
			Net.leave()
			open())
		row.add_child(lb)
	if Net.role == "host" and Net.connected:
		var go := UI.label(tr("Your friend is here. Go back and choose your rising sign to start the run together."), 16, UI.CREAM, 3)
		go.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_box.add_child(go)
	if not Net.is_client():
		var back := UI.button(tr("BACK"), 18)
		back.custom_minimum_size = Vector2(220, 50)
		back.pressed.connect(func():
			_online_view = false
			open())
		var brow := HBoxContainer.new()
		brow.alignment = BoxContainer.ALIGNMENT_CENTER
		brow.add_child(back)
		_box.add_child(brow)
	else:
		var wait := UI.label(tr("The host chooses the rising sign and starts the run; you will be pulled in automatically."), 16, UI.CREAM, 3)
		wait.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_box.add_child(wait)


func _on_net_status(_t: String) -> void:
	if visible and (_online_view or Net.is_client()):
		open()
