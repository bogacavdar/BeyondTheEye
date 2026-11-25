extends RefCounted
## SİLAH USTALIKLARI (silaha özel dönüşümler, Hades'teki çekiç yükseltmeleri gibi)
## "Silah Ustalığı" kapısından geçip odayı temizleyince silahına ait 3 dönüşümden birini seçersin.
## Her dönüşüm bir YUVAYA aittir: SALDIRI (sol tık), AĞIR (Q), YETENEKLER (1 2 3), ATILMA (boşluk).
## Bir yuvaya run başına tek dönüşüm alınır; böylece her run aynı silah farklı oynanır:
## bir run'da saldırı odaklı (zincirleme, yanma, hız), öbüründe yetenek odaklı (yankı, büyüme, güçlenme).
##
## Etkiler (hero.gd bunları okur):
##  atk_wave      bitiriş vuruşu ışık dalgası fırlatır          atk_burn      saldırılar yakar
##  atk_chain     her vuruş yakındaki bir düşmana sıçrar        atk_frenzy    peş peşe vuruşlar hasarı artırır
##  atk_rapid     saldırılar çok hızlı, vuruş başı biraz zayıf  atk_multishot (yay) her atış üçlü
##  atk_ricochet  (yay) oklar başka düşmana seker
##  hv_shock      ağır saldırı etrafa şok dalgası yayar         hv_execute    ağır saldırı zayıf düşmanları biçer
##  hv_pull       ağır saldırı önce düşmanları çeker            hv_star       (yay) dev delici yıldız oku, patlar
##  hv_rain       (yay) ağır atış gökten ok yağmuru olur
##  sk_echo       yetenekler yarım güçle bir kez daha çıkar     sk_haste      yetenekler çok daha sık
##  sk_empower    yetenekten sonra 3 saldırı çok güçlü          sk_big        yetenekler daha büyük ve güçlü
##  ds_strike     atılma geçtiği düşmanları keser               ds_trail      atılma patlayan yıldız izi bırakır
##  ds_double     arka arkaya iki kez atılabilirsin

const SLOTS := {
	"attack": {"name": "ATTACK", "col": Color(1.0, 0.85, 0.5)},
	"heavy": {"name": "HEAVY", "col": Color(1.0, 0.55, 0.35)},
	"skill": {"name": "SKILLS", "col": Color(0.6, 0.8, 1.0)},
	"dash": {"name": "DASH", "col": Color(0.7, 1.0, 0.75)},
}

const BOONS := [
	# ---------------- YILDIZ KILICI
	{"id": "w_sword_wave", "weapon": "STAR SWORD", "slot": "attack", "fx": "atk_wave", "name": "Light Cleave", "desc": "Your combo finisher releases a cutting wave of light"},
	{"id": "w_sword_frenzy", "weapon": "STAR SWORD", "slot": "attack", "fx": "atk_frenzy", "name": "Star Dance", "desc": "Each hit in quick succession deals +6% more damage (up to +60%). Getting hit resets it"},
	{"id": "w_sword_shock", "weapon": "STAR SWORD", "slot": "heavy", "fx": "hv_shock", "name": "Supernova Spin", "desc": "Your heavy spin bursts into a starlight shockwave around you"},
	{"id": "w_sword_exec", "weapon": "STAR SWORD", "slot": "heavy", "fx": "hv_execute", "name": "Final Verdict", "desc": "Your heavy attack deals triple damage to foes below 40% health"},
	{"id": "w_sword_echo", "weapon": "STAR SWORD", "slot": "skill", "fx": "sk_echo", "name": "Twin Starfall", "desc": "Your skills strike again a moment later at half power"},
	{"id": "w_sword_emp", "weapon": "STAR SWORD", "slot": "skill", "fx": "sk_empower", "name": "Charged Blade", "desc": "After a skill, your next 3 attacks deal +60% damage"},
	{"id": "w_sword_dstrike", "weapon": "STAR SWORD", "slot": "dash", "fx": "ds_strike", "name": "Comet Step", "desc": "Dashing through foes cuts them"},
	{"id": "w_sword_trail", "weapon": "STAR SWORD", "slot": "dash", "fx": "ds_trail", "name": "Star Trail", "desc": "Your dash leaves a trail of stars that explode"},
	# ---------------- AY ORAĞI
	{"id": "w_scythe_chain", "weapon": "MOON SCYTHE", "slot": "attack", "fx": "atk_chain", "name": "Crescent Chain", "desc": "Every hit leaps to another nearby foe for half damage"},
	{"id": "w_scythe_rapid", "weapon": "MOON SCYTHE", "slot": "attack", "fx": "atk_rapid", "name": "New Moon Fury", "desc": "Attacks are 40% faster but deal 15% less damage each"},
	{"id": "w_scythe_pull", "weapon": "MOON SCYTHE", "slot": "heavy", "fx": "hv_pull", "name": "Tidal Reap", "desc": "Your heavy attack first drags nearby foes to you"},
	{"id": "w_scythe_shock", "weapon": "MOON SCYTHE", "slot": "heavy", "fx": "hv_shock", "name": "Full Moon", "desc": "Your heavy attack bursts into a ring of moonlight"},
	{"id": "w_scythe_big", "weapon": "MOON SCYTHE", "slot": "skill", "fx": "sk_big", "name": "Wide Eclipse", "desc": "Skills are 40% larger and deal 25% more damage"},
	{"id": "w_scythe_haste", "weapon": "MOON SCYTHE", "slot": "skill", "fx": "sk_haste", "name": "Lunar Cycle", "desc": "Skills recharge 40% faster"},
	{"id": "w_scythe_double", "weapon": "MOON SCYTHE", "slot": "dash", "fx": "ds_double", "name": "Phase Shift", "desc": "You can dash twice in a row"},
	{"id": "w_scythe_dstrike", "weapon": "MOON SCYTHE", "slot": "dash", "fx": "ds_strike", "name": "Shadow Reap", "desc": "Dashing through foes cuts them"},
	# ---------------- GÜNEŞ GÜRZÜ
	{"id": "w_mace_burn", "weapon": "SUN MACE", "slot": "attack", "fx": "atk_burn", "name": "Solar Brand", "desc": "Your attacks set foes ablaze"},
	{"id": "w_mace_frenzy", "weapon": "SUN MACE", "slot": "attack", "fx": "atk_frenzy", "name": "Rising Heat", "desc": "Each hit in quick succession deals +6% more damage (up to +60%). Getting hit resets it"},
	{"id": "w_mace_shock", "weapon": "SUN MACE", "slot": "heavy", "fx": "hv_shock", "name": "Solar Quake", "desc": "Your heavy slam sends a burning shockwave around you"},
	{"id": "w_mace_exec", "weapon": "SUN MACE", "slot": "heavy", "fx": "hv_execute", "name": "Judgement", "desc": "Your heavy attack deals triple damage to foes below 40% health"},
	{"id": "w_mace_big", "weapon": "SUN MACE", "slot": "skill", "fx": "sk_big", "name": "Corona Blaze", "desc": "Skills are 40% larger and deal 25% more damage"},
	{"id": "w_mace_echo", "weapon": "SUN MACE", "slot": "skill", "fx": "sk_echo", "name": "Double Dawn", "desc": "Your skills strike again a moment later at half power"},
	{"id": "w_mace_trail", "weapon": "SUN MACE", "slot": "dash", "fx": "ds_trail", "name": "Burning Path", "desc": "Your dash leaves a trail of stars that explode"},
	{"id": "w_mace_dstrike", "weapon": "SUN MACE", "slot": "dash", "fx": "ds_strike", "name": "Meteor Rush", "desc": "Dashing through foes cuts them"},
	# ---------------- KUYRUKLU YILDIZ MIZRAĞI
	{"id": "w_spear_wave", "weapon": "COMET SPEAR", "slot": "attack", "fx": "atk_wave", "name": "Comet Thrust", "desc": "Your combo finisher releases a cutting wave of light"},
	{"id": "w_spear_chain", "weapon": "COMET SPEAR", "slot": "attack", "fx": "atk_chain", "name": "Arc Lance", "desc": "Every hit leaps to another nearby foe for half damage"},
	{"id": "w_spear_pull", "weapon": "COMET SPEAR", "slot": "heavy", "fx": "hv_pull", "name": "Gravity Lance", "desc": "Your heavy attack first drags nearby foes to you"},
	{"id": "w_spear_exec", "weapon": "COMET SPEAR", "slot": "heavy", "fx": "hv_execute", "name": "Perihelion Pierce", "desc": "Your heavy attack deals triple damage to foes below 40% health"},
	{"id": "w_spear_haste", "weapon": "COMET SPEAR", "slot": "skill", "fx": "sk_haste", "name": "Orbital Return", "desc": "Skills recharge 40% faster"},
	{"id": "w_spear_emp", "weapon": "COMET SPEAR", "slot": "skill", "fx": "sk_empower", "name": "Tail Fire", "desc": "After a skill, your next 3 attacks deal +60% damage"},
	{"id": "w_spear_double", "weapon": "COMET SPEAR", "slot": "dash", "fx": "ds_double", "name": "Slingshot", "desc": "You can dash twice in a row"},
	{"id": "w_spear_trail", "weapon": "COMET SPEAR", "slot": "dash", "fx": "ds_trail", "name": "Comet Tail", "desc": "Your dash leaves a trail of stars that explode"},
	# ---------------- METEOR ZİNCİRİ
	{"id": "w_chain_chain", "weapon": "METEOR CHAIN", "slot": "attack", "fx": "atk_chain", "name": "Linked Impact", "desc": "Every hit leaps to another nearby foe for half damage"},
	{"id": "w_chain_burn", "weapon": "METEOR CHAIN", "slot": "attack", "fx": "atk_burn", "name": "Molten Links", "desc": "Your attacks set foes ablaze"},
	{"id": "w_chain_pull", "weapon": "METEOR CHAIN", "slot": "heavy", "fx": "hv_pull", "name": "Gravity Well", "desc": "Your heavy attack first drags nearby foes to you"},
	{"id": "w_chain_shock", "weapon": "METEOR CHAIN", "slot": "heavy", "fx": "hv_shock", "name": "Crater", "desc": "Your heavy attack bursts into a shockwave around you"},
	{"id": "w_chain_echo", "weapon": "METEOR CHAIN", "slot": "skill", "fx": "sk_echo", "name": "Meteor Shower", "desc": "Your skills strike again a moment later at half power"},
	{"id": "w_chain_big", "weapon": "METEOR CHAIN", "slot": "skill", "fx": "sk_big", "name": "Bigger Rocks", "desc": "Skills are 40% larger and deal 25% more damage"},
	{"id": "w_chain_dstrike", "weapon": "METEOR CHAIN", "slot": "dash", "fx": "ds_strike", "name": "Wrecking Dash", "desc": "Dashing through foes cuts them"},
	{"id": "w_chain_double", "weapon": "METEOR CHAIN", "slot": "dash", "fx": "ds_double", "name": "Whiplash", "desc": "You can dash twice in a row"},
	# ---------------- KENTAUR YAYI
	{"id": "w_bow_multi", "weapon": "CENTAUR BOW", "slot": "attack", "fx": "atk_multishot", "name": "Volley", "desc": "Every shot becomes three arrows at reduced damage"},
	{"id": "w_bow_rico", "weapon": "CENTAUR BOW", "slot": "attack", "fx": "atk_ricochet", "name": "Ricochet Star", "desc": "Your arrows bounce to another foe after a hit"},
	{"id": "w_bow_star", "weapon": "CENTAUR BOW", "slot": "heavy", "fx": "hv_star", "name": "Hunter's Star", "desc": "Your heavy shot becomes a huge star that pierces everything and explodes. Longer recharge"},
	{"id": "w_bow_rain", "weapon": "CENTAUR BOW", "slot": "heavy", "fx": "hv_rain", "name": "Sky Hunt", "desc": "Your heavy shot rains arrows from the sky where you aim"},
	{"id": "w_bow_echo", "weapon": "CENTAUR BOW", "slot": "skill", "fx": "sk_echo", "name": "Twin Quiver", "desc": "Your skills strike again a moment later at half power"},
	{"id": "w_bow_emp", "weapon": "CENTAUR BOW", "slot": "skill", "fx": "sk_empower", "name": "Focused Aim", "desc": "After a skill, your next 3 shots deal +60% damage"},
	{"id": "w_bow_trail", "weapon": "CENTAUR BOW", "slot": "dash", "fx": "ds_trail", "name": "Hoof Sparks", "desc": "Your dash leaves a trail of stars that explode"},
	{"id": "w_bow_double", "weapon": "CENTAUR BOW", "slot": "dash", "fx": "ds_double", "name": "Centaur Gallop", "desc": "You can dash twice in a row"},
]


static func get_boon(id: String) -> Dictionary:
	for b in BOONS:
		if b["id"] == id:
			return b
	return {}


static func is_weapon_boon(id: String) -> bool:
	return id.begins_with("w_")


## Bu silah için, dolu yuvalar dışından 3 dönüşüm seçer
static func offer(weapon: String, owned: Array) -> Array:
	var taken := {}
	for id in owned:
		var b := get_boon(String(id))
		if not b.is_empty():
			taken[b["slot"]] = true
	var pool: Array = []
	for b in BOONS:
		if b["weapon"] == weapon and not taken.has(b["slot"]):
			pool.append(b)
	pool.shuffle()
	# mümkünse farklı yuvalardan seç
	var out: Array = []
	var slots := {}
	for b in pool:
		if out.size() >= 3:
			break
		if not slots.has(b["slot"]):
			out.append(b)
			slots[b["slot"]] = true
	for b in pool:
		if out.size() >= 3:
			break
		if not out.has(b):
			out.append(b)
	return out


static func can_offer(weapon: String, owned: Array) -> bool:
	return not offer(weapon, owned).is_empty()


## Alınan dönüşümlerin etki bayrakları (sadece şu anki silaha ait olanlar)
static func effects(owned: Array, weapon: String) -> Dictionary:
	var fx := {}
	for id in owned:
		var b := get_boon(String(id))
		if not b.is_empty() and b["weapon"] == weapon:
			fx[String(b["fx"])] = true
	return fx
