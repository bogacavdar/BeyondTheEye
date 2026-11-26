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


func open() -> void:
	for c in _box.get_children():
		c.queue_free()
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
	# İKİZLER: yerel co-op (bilgisayarda, en az bir kontrolcüyle)
	if not GD.is_mobile():
		var pads := Input.get_connected_joypads().size()
		var crow := HBoxContainer.new()
		crow.alignment = BoxContainer.ALIGNMENT_CENTER
		crow.add_theme_constant_override("separation", 14)
		_box.add_child(crow)
		var cb := UI.button(("♊︎  " + tr("TWINS: 2 PLAYERS")) if GD.coop else ("♊︎  " + tr("TWINS: OFF")), 18, Color(0.75, 0.55, 1.0) if GD.coop else UI.CREAM)
		cb.custom_minimum_size = Vector2(330, 50)
		cb.disabled = pads == 0 and not GD.coop
		cb.pressed.connect(func():
			GD.coop = not GD.coop
			open())
		crow.add_child(cb)
		var hint := tr("Player 2 plays with a controller. One controller: Player 1 uses keyboard and mouse.") if pads > 0 else tr("Connect a controller for Player 2.")
		if pads >= 2:
			hint = tr("Two controllers: each player uses their own.")
		var hl := UI.label(hint, 14, Color(0.75, 0.75, 0.85), 3)
		hl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hl.custom_minimum_size = Vector2(520, 0)
		crow.add_child(hl)
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
