extends RefCounted
## PORTRELER: assets/portraits/<kimlik>.png (ya da .jpg) varsa oyunda gösterilir, yoksa sessizce atlanır.
## Kimlikler: 12 burç ("aries" ... "pisces"), "ayana" (Ay Ana), "saturn" (Satürn Demirci).
## Görseller ComfyUI ile üretilir; promptlar: assets/portraits/PROMPTLAR.md

static func tex(id: String) -> Texture2D:
	for ext in ["png", "jpg", "webp"]:
		var p := "res://assets/portraits/%s.%s" % [id, ext]
		if ResourceLoader.exists(p):
			return load(p)
	return null


## Panelin içine soldan portre koyan yardımcı (yoksa kutuyu olduğu gibi ekler)
static func wrap(panel: Control, box: Control, id: String, h := 520.0) -> void:
	var t := tex(id)
	if t == null:
		panel.add_child(box)
		return
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 18)
	panel.add_child(hb)
	var tr := TextureRect.new()
	tr.texture = t
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.custom_minimum_size = Vector2(h * float(t.get_width()) / float(maxi(t.get_height(), 1)), h)
	hb.add_child(tr)
	hb.add_child(box)
