extends RefCounted
## BAŞARIMLAR: oyun içinde tutulur, kazanılınca ekranda kısa bir bildirim çıkar.
## Steam: oyun GodotSteam ile Steam'e bağlıysa (Engine'de "Steam" tekili varsa) aynı kimlikle Steam başarımı da açılır.
## Kimlikler Steamworks'te girilen API adlarıyla birebir aynı olmalı (steam/BASARIMLAR.md).

const LIST := [
	{"id": "BOSS_ARIES", "glyph": "♈", "col": Color(1.0, 0.45, 0.3), "name": ["The Ram Falls", "Koç Düştü"], "desc": ["Restore Aries.", "Koç'u arındır."]},
	{"id": "BOSS_TAURUS", "glyph": "♉", "col": Color(0.55, 1.0, 0.45), "name": ["The Immovable Moved", "Yerinden Oynamayan Oynadı"], "desc": ["Restore Taurus.", "Boğa'yı arındır."]},
	{"id": "BOSS_GEMINI", "glyph": "♊", "col": Color(0.6, 0.8, 1.0), "name": ["Two Voices Silenced", "İki Ses Sustu"], "desc": ["Restore Gemini.", "İkizler'i arındır."]},
	{"id": "BOSS_CANCER", "glyph": "♋", "col": Color(0.5, 0.9, 1.0), "name": ["Low Tide", "Cezir"], "desc": ["Restore Cancer.", "Yengeç'i arındır."]},
	{"id": "BOSS_LEO", "glyph": "♌", "col": Color(1.0, 0.8, 0.4), "name": ["Sunset of a King", "Bir Kralın Gün Batımı"], "desc": ["Restore Leo.", "Aslan'ı arındır."]},
	{"id": "BOSS_VIRGO", "glyph": "♍", "col": Color(0.5, 1.0, 0.85), "name": ["The Harvest Is In", "Hasat Kaldırıldı"], "desc": ["Restore Virgo.", "Başak'ı arındır."]},
	{"id": "BOSS_LIBRA", "glyph": "♎", "col": Color(0.4, 1.0, 0.8), "name": ["Balance Restored", "Denge Yerine Geldi"], "desc": ["Restore Libra.", "Terazi'yi arındır."]},
	{"id": "BOSS_SCORPIO", "glyph": "♏", "col": Color(0.5, 1.0, 0.3), "name": ["Twice Defeated", "İki Kez Yenilen"], "desc": ["Restore Scorpio, phoenix and all.", "Akrep'i ankasıyla birlikte arındır."]},
	{"id": "BOSS_SAGITTARIUS", "glyph": "♐", "col": Color(0.7, 0.55, 1.0), "name": ["Caught the Archer", "Okçuya Yetiştin"], "desc": ["Restore Sagittarius.", "Yay'ı arındır."]},
	{"id": "BOSS_CAPRICORN", "glyph": "♑", "col": Color(0.4, 1.0, 0.9), "name": ["The Summit Reached", "Zirveye Ulaşıldı"], "desc": ["Restore Capricorn.", "Oğlak'ı arındır."]},
	{"id": "BOSS_AQUARIUS", "glyph": "♒", "col": Color(0.6, 0.9, 1.0), "name": ["After the Storm", "Fırtınadan Sonra"], "desc": ["Restore Aquarius.", "Kova'yı arındır."]},
	{"id": "BOSS_PISCES", "glyph": "♓", "col": Color(0.85, 0.65, 1.0), "name": ["Waking from the Dream", "Rüyadan Uyanış"], "desc": ["Restore Pisces.", "Balık'ı arındır."]},
	{"id": "ALL_TWELVE", "glyph": "✦", "col": Color(1.0, 0.9, 0.6), "name": ["The Sky Is Whole", "Gökyüzü Bütün"], "desc": ["Restore all twelve constellations.", "On iki takımyıldızın hepsini arındır."]},
	{"id": "CYCLE_1", "glyph": "∞", "col": Color(0.85, 0.65, 1.0), "name": ["Once More, Around", "Bir Tur Daha"], "desc": ["Complete a cycle of the Endless Sky.", "Sonsuz Gökyüzü'nde bir döngü tamamla."]},
	{"id": "CYCLE_3", "glyph": "∞", "col": Color(1.0, 0.6, 0.9), "name": ["Beyond the Eye", "Gözün Ötesi"], "desc": ["Complete cycle 3 of the Endless Sky.", "Sonsuz Gökyüzü'nde 3. döngüyü tamamla."]},
	{"id": "FLAWLESS", "glyph": "☾", "col": Color(0.8, 0.9, 1.0), "name": ["Untouched by the Stars", "Yıldızlar Dokunamadı"], "desc": ["Defeat a boss without taking damage.", "Hiç hasar almadan bir boss'u yen."]},
	{"id": "FIRST_PARRY", "glyph": "⚔", "col": Color(1.0, 0.85, 0.45), "name": ["Turned Aside", "Savuşturma"], "desc": ["Parry an attack.", "Bir saldırıyı parry'le."]},
	{"id": "PARRY_100", "glyph": "⚜", "col": Color(1.0, 0.7, 0.3), "name": ["Golden Guard", "Altın Muhafız"], "desc": ["Parry 100 attacks.", "100 saldırıyı parry'le."]},
	{"id": "KILLS_1000", "glyph": "☄", "col": Color(1.0, 0.55, 0.45), "name": ["A Thousand Falling Stars", "Bin Kayan Yıldız"], "desc": ["Defeat 1000 creatures.", "1000 yaratık yen."]},
	{"id": "DUO", "glyph": "☌", "col": Color(1.0, 0.8, 0.9), "name": ["Conjunction", "Kavuşum"], "desc": ["Take a conjunction or opposition blessing.", "Bir kavuşum ya da karşıtlık lütfu al."]},
	{"id": "RISING_WIN", "glyph": "↑", "col": Color(0.7, 1.0, 0.8), "name": ["Written in the Ascendant", "Yükselende Yazılı"], "desc": ["Defeat a boss with a rising sign chosen.", "Bir yükselen seçiliyken boss yen."]},
	{"id": "RETRO_5", "glyph": "℞", "col": Color(1.0, 0.5, 0.5), "name": ["Against the Retrograde", "Retroya Karşı"], "desc": ["Defeat a boss with Retrograde heat 5 or more.", "Retro zorluğu 5 ya da üstündeyken boss yen."]},
	{"id": "MOON_BOND", "glyph": "☽", "col": Color(0.78, 0.86, 1.0), "name": ["Child of the Moon", "Ay'ın Çocuğu"], "desc": ["Reach the highest bond with Mother Moon.", "Ay Ana ile en yüksek bağa ulaş."]},
	{"id": "SEAL_MASTER", "glyph": "♄", "col": Color(0.95, 0.8, 0.5), "name": ["Master of the Forge", "Örsün Ustası"], "desc": ["Master a seal at Saturn's forge.", "Satürn'ün örsünde bir mührü ustalaştır."]},
	{"id": "ALMANAC_FULL", "glyph": "✎", "col": Color(1.0, 0.92, 0.75), "name": ["Keeper of the Almanac", "Almanak Bekçisi"], "desc": ["Fill in every page of the Almanac.", "Almanak'ın bütün sayfalarını doldur."]},
]


static var _shown := 0


static func _gd():
	return load("res://scripts/game_data.gd")


static func has(id: String) -> bool:
	return _gd().achievements.has(id)


static func get_info(id: String) -> Dictionary:
	for a in LIST:
		if String(a["id"]) == id:
			return a
	return {}


static func t(pair: Array) -> String:
	return String(pair[1]) if String(_gd().lang) == "tr" else String(pair[0])


## Başarımı aç (zaten açıksa bir şey yapmaz)
static func unlock(id: String, quiet := false) -> void:
	var GD = _gd()
	if GD.achievements.has(id):
		return
	var info := get_info(id)
	if info.is_empty():
		return
	GD.achievements[id] = int(Time.get_unix_time_from_system())
	GD.go_save()
	if Engine.has_singleton("Steam"):
		var steam = Engine.get_singleton("Steam")
		steam.call("setAchievement", id)
		steam.call("storeStats")
	if not quiet:
		_toast(info)


## Sayaçlı başarımlar için: GameData.stats[key] artar, eşiğe gelince açılır
static func bump(key: String, amount := 1) -> int:
	var GD = _gd()
	var n := int(GD.stats.get(key, 0)) + amount
	GD.stats[key] = n
	match key:
		"parries":
			if n >= 1:
				unlock("FIRST_PARRY")
			if n >= 100:
				unlock("PARRY_100")
		"kills":
			if n >= 1000:
				unlock("KILLS_1000")
	return n


static func check_almanac() -> void:
	var pr: Vector2i = load("res://scripts/almanac.gd").progress()
	if pr.x >= pr.y:
		unlock("ALMANAC_FULL")


## Ekranın üstünde kayan küçük bildirim
static func _toast(info: Dictionary) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return
	var UI = load("res://scripts/ui_style.gd")
	var layer := CanvasLayer.new()
	layer.layer = 90
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	tree.root.add_child(layer)
	var p: PanelContainer = UI.panel(info["col"])
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(p)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	p.add_child(row)
	var g: Label = UI.label(String(info["glyph"]) + "︎", 44, info["col"], 3)
	g.add_theme_font_override("font", UI.symbol_font())
	row.add_child(g)
	var vb := VBoxContainer.new()
	row.add_child(vb)
	vb.add_child(UI.label(tr_static("ACHIEVEMENT UNLOCKED", "BAŞARIM KAZANILDI"), 15, UI.GOLD, 3))
	vb.add_child(UI.label(t(info["name"]), 24, info["col"], 4))
	vb.add_child(UI.label(t(info["desc"]), 15, UI.CREAM, 3))
	var vp := tree.root.get_visible_rect().size
	p.position = Vector2(vp.x * 0.5 - 260.0, -160.0)
	p.custom_minimum_size = Vector2(520, 0)
	var Sfx = tree.root.get_node_or_null("Sfx")
	if Sfx != null:
		Sfx.call("play", "coin", -4.0, 0.0, 0, 1.3)
	var tw := layer.create_tween()
	var slot := _shown
	_shown += 1
	tw.tween_interval(0.25 * float(slot))
	tw.tween_property(p, "position:y", 24.0 + 150.0 * float(slot % 4), 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(3.6)
	tw.tween_property(p, "position:y", -180.0, 0.4).set_ease(Tween.EASE_IN)
	tw.tween_callback(func():
		_shown = maxi(_shown - 1, 0)
		layer.queue_free())


static func tr_static(en: String, trk: String) -> String:
	return trk if String(_gd().lang) == "tr" else en
