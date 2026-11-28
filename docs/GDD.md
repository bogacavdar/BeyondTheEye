# GÖZÜN ÖTESİ: Oyun Tasarım Belgesi (GDD)

> Sürüm: 0.5.4 · Son güncelleme: 27 Kasım 2026 (düşman gücü ve agresiflik artışı §13.9; Ayna Muhafızı yansıtması)
> Ekip: Boğaç (CEO: yön, test, astroloji) + Claude ajan ekibi (Analist, Yazılımcı, Testçi, Yönetici)
> Adını Instagram kanalı @gozunotesi_'den alır ve görsel dili oradan gelir. İngilizce adı: **Beyond The Eye**.
> Motor: Godot 4.7.2. Bu sürümdeki sayılar koddan doğrulandı (commit 1038b6e). Kod ile belge çelişirse önce bu belge güncellenir, sonra kod.
> İşaretler: **[KOD]** = oyunda olan durum · **[CEO KARARI]** = Boğaç'ın verdiği kesin karar · **[ÖNERİ – CEO onayı gerekir]** = henüz onaylanmamış.

---

## 1. Tek cümlede oyun

Bozulmuş burçların hüküm sürdüğü kozmik bir âlemde, oda oda ilerleyip **yakın dövüş, parry ve atılmayla** burçların gölge yönleriyle savaştığın, izometrik bir **aksiyon roguelite**'ı (Hades tarzı).

## 2. Temel direkler (pazarlıksız)

1. **Vuruş hissi her şeyden önce gelir.** Hit-stop, sarsıntı, altın kırıkları, yıldız tozu, uzuv koparma.
2. **Kaçarak, okuyarak dövüş.** Her saldırı önceden belli olur. **Altın uyarı = parry'lenir, kızıl uyarı = atıl.**
3. **Lacivert ve altın.** Gece göğü, dolunay, altından heykelleşmiş burçlar.
4. **Astrolojik doğruluk.** Bozulmuş burçlar **gölge yönleriyle** savaşır.

## 3. Hikâye

Burçlar bozuldu, gökyüzünün düzeni çöktü. Yolcu, gözle görülenin ötesindeki âleme geçip on iki burcu sırayla arındırır (Koç'tan Balık'a). Arınan her burç Gözlemevi'nin göğünde yeniden yanar; on ikisi yanınca "gökyüzü bütün" olur.
- Bozulma = burcun **gölge yönüne** teslim olması.
- **Açık soru:** Ana karakter kim?

## 4. Oyun akışı [KOD]

1. **Ana menü** → 3 kayıt yuvasından biri. Yeni yuva: **Gözlemevi**'ne gider. Yarım kalmış run varsa **Devam** o run'ın odasından sürer (her odaya girerken anlık kayıt alınır).
2. **Gözlemevi (hub):** duraklar arasında yürünür, E ile kullanılır (bkz. §10). Eğitim kuklası burada durur.
3. **Kapı (THE GATE)** → **Yükselen burç** seçimi (run kuralı: bir avantaj + bir bedel). Aynı ekranda: İkizler (yerel co-op) aç/kapat, çevrim içi Host/Katıl, Sonsuz Gökyüzü döngü seçimi.
4. *(Yeni, §14)* İlk kez oynayan için **Öğretici Oda**.
5. **Run:** 12 bölge × **5 oda** = 60 oda (derinlik 0–59). Her bölgede oda 1–4 dövüş, **oda 5 boss** (`BOSS_DEPTH = 4`, `ZONE_START`).
   - İlk odanın ödülü rastgele bir gezegen lütfu.
   - Dövüş odası: kapılar kilitli, 2–3 dalga düşman (doğacağı yer mor halkayla önceden görünür). Son düşman ölünce kısa ağır çekim + "THE STARS ALIGN" + oda tozu.
   - Odanın ödülü (lütuf kartları / silah ustalığı / toz) verilir, sonra **2 kapı** çıkar. Kapının üstündeki madalyonda ödülün simgesi görünür.
   - Kapı seçenekleri: biri hep gezegen lütfu; öbürü ~%40 silah ustalığı (verilebiliyorsa), ~%15 yıldız tozu, ~%15 **Sığınak** (yalnızca can %75'in altındaysa ve Venüs retrosu kapalıysa), yoksa başka bir gezegen lütfu. Neptün Sisi retrosunda tek kapı.
   - 4. dövüş odasından sonra tek kapı: **boss**.
   - **Sığınak:** dövüş yok, canın %40'ı dolar, çeşme, sonra kapılar.
   - **Boss** yenilince: toz + ilk zafer bonusu, 2 Ay Taşı, burç cevheri (ilk zaferde 2, sonra 1), başarım. Sonra 2 kapı: **sonraki bölge** (canın %30'u dolar, ilk odada lütuf) ya da **Gözlemevine dön** (run biter, kazanılan her şey kalır).
   - **Balık** (son boss) sonrası: final töreni, sonra **Sonsuz Gökyüzü** kapısı (bir üst döngü, canın %50'si dolar, Koç'tan devam) ya da eve dönüş.
6. **Ölüm:** "THE STARS DIM" ekranı, run biter, toplanan yıldız tozu kalır, Gözlemevine dönülür. Duraklat → "Gözlemevine dön" run'ı bırakır.
7. Ödüller: düşman başına toz (Gölge 5, Kâhin 5, Atlayan 6, Kolos 16; seçkin ×3), oda bonusu (bölge çarpanı Koç ×1 → Balık ×5,5), dövüş odalarından %22 ihtimalle Ay Taşı, retro ve döngü toz çarpanları.

## 5. Bölgeler ve boss'lar [KOD]

| # | Bölge (TR / EN) | Element | Boss (unvan) | Taban can (eski → **yeni**, §13.4) | Boss'un ana fikri | Normal oda tehlikesi |
|---|---|---|---|---|---|---|
| 1 | Koç Geçidi / The Ram's Pass | Ateş | **Koç** – Koç'un Öfkesi | 1400 → **1400** | durmadan hücum; 3 evre (+Tam Tutulma retrosunda 4.) | lav fışkırması |
| 2 | Boğa Otlakları / The Bull's Meadows | Toprak | **Boğa** – Sarsılmaz | 2000 → **1800** | yerinden oynamaz; deprem halkaları, Venüs gülleri (iyileşir), Aldebaran ışını | diken tarlası (yavaşlatır) |
| 3 | İkiz Gökler / The Twin Skies | Hava | **İkizler** – Kastor ve Polluks | 2600 → **2200** (toplam) | iki boss; biri düşerse 7 sn'de kalkar, ikisini yakın zamanda indir | rüzgâr iter |
| 4 | Ay Işıklı Kıyı / The Moonlit Shore | Su | **Yengeç** – Gelgitin Anası | 2400 → **2500** | önden %60 / arkadan %140 hasar; gelgitte yalnızca iç daire güvenli | gelgit (iç daire güvenli) |
| 5 | Güneş Sarayı / The Sun Palace | Ateş | **Aslan** – Güneş Kral | 2700 → **2900** | pençe serisi; yavrular yaşadıkça güçlenir; Zenit'te gölgeye saklan | Zenit |
| 6 | Sessiz Hasat / The Silent Harvest | Toprak | **Başak** – Hasat Bakiresi | 2900 → **3300** | desen okuma; geçtiğin yolu patlatır, dama ızgarası | dama ızgarası |
| 7 | Şafak Terazisi / The Scales of Dawn | Hava | **Terazi** – Dengenin Hakemi | 3100 → **3600** | iki yanından sırayla vur (denge göstergesi) | hüküm (arenanın yarısı) |
| 8 | Zehir Mağaraları / The Venom Depths | Su | **Akrep** – Zehrin Kraliçesi | 3000 → **3700** | ölünce bir kez Anka olarak %35 canla doğar | asit gölcükleri |
| 9 | Kentaur Bozkırı / The Centaur Steppes | Ateş | **Yay** – Okçu Kral | 3000 → **4300** | mesafe tutar; ok yağmuru, delici ok, dörtnala | ok yağmuru |
| 10 | Donmuş Zirve / The Frozen Summit | Toprak | **Oğlak** – Dağın Yaşlısı | 3300 → **4900** | çığ şeritleri, buz çemberi; ayazda durursan donarsın | çığ |
| 11 | Fırtına Gözlemevi / The Storm Observatory | Hava | **Kova** – Suyun Taşıyıcısı | 3500 → **5400** | su döker, sonra elektriklendirir | yıldırım |
| 12 | Rüyalar Denizi / The Sea of Dreams | Su | **Balık** – Rüya Gören | 3800 → **6000** | gümüş bağ, girdap; son evrede 11 burcun yankısı | rüya köpüğü halkası |

- Her boss'un en az bir **altın (parry'lenir)** yakın saldırısı vardır; parry'lenen boss sersemler.
- Boss girişinde 2,2 sn kimse hareket etmez/saldırmaz (isim kartı).
- Boss canı bölge tablolarıyla değil; `room.gd BOSS_HP` tablosundan gelir (§13.4), sonra retro (Jüpiter), döngü ve co-op ile çarpılır.

## 6. Düşmanlar [KOD]

Dört rol; her bölgede görünüş ve mekanik o burca göre değişir (ör. Koç'ta Kor Cini, Mars Kâhini, Hırçın Koç, Mars Savaşçısı).

| Rol | Taban can | Saldırılar |
|---|---|---|
| Gölge (shade) | 90 | pençe 16 (**altın**), yırtma 22 (**kızıl**) |
| Kâhin (caster) | 60 | uzaktan ışık mermisi 12 (**kızıl**, atılarak kaçılır) |
| Atlayan (leaper) | 75 | pençe 12 (**altın**), üstüne atlama 22 (**kızıl daire**) |
| Kolos (brute) | 230 | ezme 24 (**altın**), deprem 26 (**kızıl daire**) |

- **Seri saldırılar:** bazı saldırılar 2–3 kez art arda gelir; parry seriyi keser.
- **Seçkin:** altın haleli, can ×1,6, hasar ×1,25; run'ın 3. odasından sonra özellik alır (kalkanlı, hızlı, bölünen, şifacı, patlayan, hayalet). Sayı ve özellik sınırları §13.3. Odada aynı anda en çok 1 şifacı; şifacı ve kalkanlı aynı düşmanda olmaz (Yönetici kararı, Testçi 7. tur, T-58).
- **Karışık gruplar:** Boğa'dan itibaren düşmanların ~%25'i önceki bölgelerin yaratıklarıdır.
- **Saldırı sırası:** aynı anda en fazla 2 / 3 düşman saldırır (§13.1), diğerleri çevrede bekler.

## 7. Silahlar [KOD] (`game_data.gd` STAR_WEAPONS)

Run öncesi Gözlemevi'ndeki **Silah Sunağı**'ndan seçilir, yıldız tozuyla açılır. Her silahın 3'lü kombosu, ağır saldırısı ve 3 yeteneği (Q/E/R) var.

| Silah | Fiyat | Tarz | Yetenekler (Q · E · R) |
|---|---|---|---|
| Yıldız Kılıcı | açık | hızlı kombo, en geniş parry | Yıldız Yağmuru · Işık Dalgası · Takımyıldızı Adımı |
| Ay Orağı | 120 | geniş süpürme, kalabalığa karşı | Hilal Biçişi · Ay Gelgiti · Tutulma |
| Güneş Gürzü | 160 | yavaş, ağır, ışık dalgası | Güneş Patlaması · Zirve Darbesi · Taç |
| Kentaur Yayı | 180 | uzaktan ok, mesafe tut | Ok Yağmuru · Delici Yıldız · Kentaur Sıçrayışı |
| Kuyruklu Yıldız Mızrağı | 200 | uzun menzil, fırlat-geri çağır | Kuyruklu Yıldız Atışı · Günberi Hücumu · Kuyruk Süpürmesi |
| Meteor Zinciri | 240 | çok hızlı, çok vuruş | Çarpma · Yörünge · Zincir Kancası |

- **Kentaur Yayı gücü [CEO KARARI]:** yayın saniye başı hasarı diğer 5 silahın ortalamasının ~%80'i (kombo, ağır ve yetenekler ayrı ayrı); uzaktan vurma avantajı için %20 eksik kalır. Atış hızı değişmedi (okunurluk). `weapon_kits.gd`: kombo okları 6/6/4×3 → **12/12/8×3**, ağır ok 22 → **50**, ağır bekleme 2,0 → **1,5 sn**, Ok Yağmuru 6 → **7,5** (×10), Delici Yıldız 18 → **22**, Kentaur Sıçrayışı 12 → **15**. Silah lütufları (çoklu atış, sekme, Avcı Yıldızı ×2,5 / bekleme ×1,6, Gök Avı) ve Doğum Haritası çarpanları bu tabanlara oranla uygulanır. Ölçüm (30 sn sabit hedef, 2,5 m, taban kahraman, saniye başı hasar):

| Silah | Kombo | Ağır | Yetenek |
|---|---|---|---|
| Yıldız Kılıcı | 58,1 | 43,0 | 11,1 |
| Ay Orağı | 50,6 | 41,2 | 14,2 |
| Güneş Gürzü | 56,4 | 48,8 | 13,9 |
| Kuyruklu Yıldız Mızrağı | 59,5 | 58,5 | 11,5 |
| Meteor Zinciri | 53,9 | 40,8 | 14,7 |
| **Kentaur Yayı** (eski 23,7 · 13,8 · 8,0) | **44,1** | **37,6** | **10,8** |
| Yay / diğerlerinin ortalaması | %79 | %81 | %83 |

Run içinde **silah ustalığı** kapıları silaha özel geliştirmeler verir (`weapon_boons.gd`).

## 8. Kontroller [CEO KARARI]

| Eylem | Klavye + fare | Kontrolcü (Xbox düzeni) | Dokunmatik (telefon) |
|---|---|---|---|
| Hareket | WASD (oklar da) | sol çubuk / yön tuşları | ekranın sol yarısında yüzen çubuk |
| Saldırı kombosu | Sol tık | X | sağ yarıya tek dokunuş / ⚔ |
| Ağır saldırı | Sağ tık (F, orta tık da) | Y | AĞIR düğmesi |
| Parry | Shift (fare yan tuşları da) | B | ◈ PARRY düğmesi |
| Atılma | Boşluk | A | » düğmesi ya da çift dokunuş |
| Koşu | Boşluğu basılı tut | LT ya da sol çubuğa bas | çubuğu sonuna kadar it |
| Yetenekler | Q / E / R | LB / RB / RT | 3 yetenek düğmesi (sürükleyerek nişan) |
| Etkileşim / kapı | E | X | KULLAN düğmesi |
| Duraklat | Esc (P da) | Start | II |
| Müzik aç/kapa | M | – | – |

- **Altın uyarı = parry'lenir (Shift). Kızıl uyarı = atıl (Boşluk).**
- Parry penceresi 0,17 sn (Doğum Haritası/lütuflarla uzar); tam zamanında parry düşmanı sersemletir.
- Atılma bekleme süresi 3 sn (geliştirmelerle kısalır); atılma sırasında hasar alınmaz.
- Ekran tuş yazıları son kullanılan girişe göre değişir (`GameData.input_mode`: `mouse` / `pad` / `touch`; `sfx.gd` her girişte günceller). HUD yetenek çubuğu fare/klavyede Q·E·R·RMB·SPACE·SHIFT, kontrolcüde LB·RB·RT·Y·A·B gösterir; dokunmatikte çubuk yerine ekran düğmeleri vardır.
- **E tuşu çakışması [CEO KARARI]:** E hem 2. yetenek hem etkileşim. Kural: bir **durak (Gözlemevi) ya da kapı (dövüş odası) etkileşim menzilindeyken** klavyedeki E **yalnızca etkileşim** yapar, 2. yeteneği atmaz. Menzil dışında (dövüşte) E 2. yetenektir. Kontrolcüde 2. yetenek RB olduğu için etkilenmez.
  - Menzil: Gözlemevi durakları 3,8 m (`hub.gd`, en yakın durak), dövüş kapıları 2,6 m (`room.gd`, `hud.prompt` dolu iken).
  - Uygulama: `hero.gd`'ye `var interact_near := false`. `hub.gd` ve `room.gd` her karede en yakın durak/kapı varsa true yapar (co-op'ta her kahraman için ayrı). `_read_actions` içinde `skill_2`, `interact_near and Input.is_physical_key_pressed(KEY_E)` ise atlanır.
- **F tuşu [CEO KARARI]:** E kuralı F için de geçerli. Durak/kapı menzilindeyken (`interact_near`) F **yalnızca etkileşim** yapar, ağır saldırı başlatmaz; menzil dışında (dövüşte) F ağır saldırıdır. Uygulama: `_read_actions` içinde `heavy`, `interact_near and Input.is_physical_key_pressed(KEY_F)` ise atlanır. Sağ tık ve orta tık ağır saldırıyı her zaman yapar.
- Diğer tuş/etiket hataları için kurallar: §21.

## 9. Gezegen lütufları ve run içi güçler [KOD]

- 7 gezegen (Güneş, Ay, Merkür, Venüs, Mars, Jüpiter, Satürn); oda sonunda 3 karttan biri seçilir. Kavuşum/karşıtlık (ikili) lütufları da var (`boons.gd`).
- Lütuflar kahramana **element** verir; bölgenin elementine göre GÜÇLÜ/ZAYIF çarpanı HUD'da görünür (`elements.gd`).
- Yükselen burç (12 adet, boss'u yenince açılır), gök yoldaşı (Tilki, Baykuş, Balık, Böcek), Ay Ana tılsımları (5), Satürn mühürleri run'a taşınır.

## 10. Gözlemevi ve kalıcı gelişim [KOD]

| Durak | Ne yapar |
|---|---|
| Kapı | run başlatır (yükselen seçimi, İkizler, Sonsuz Gökyüzü) |
| Doğum Haritası | yıldız tozuyla kalıcı güçler (12 ev) |
| Silah Sunağı | silah açma/seçme |
| Gök Kadranı | retrolar ve tutulmalar (isteğe bağlı zorluk) |
| Ay Ana | Ay Taşı hediye edilir, bağ seviyesiyle tılsımlar açılır (5 tılsım, 3/8 run'da seviye atlar) |
| Satürn (Demirci) | burç cevheriyle burç mühürleri dövülür |
| Almanak | karşılaşılan bölgeler ve yaratıklar |
| Eğitim kuklası | silah ve yetenek denemek için kırılmayan hedef (`training_dummy.gd`) |

- Arınan burçlar Gözlemevi çarkında yanar; **25 başarım** (Steam kimlikleriyle aynı, `achievements.gd`).
- **Retrolar (Gök Kadranı):** Mars (+%20 düşman hasarı/kademe), Jüpiter (+%25 can), Plüton (%12 daha hızlı hazırlık), Ay Tutulması (+%15 seçkin), Merkür (+%40 atılma bekleme), Satürn (−%30 iyileşme), Güneş Tutulması (−%20 en yüksek can), Venüs (Sığınak yok), Neptün Sisi (tek kapı), Tam Tutulma (Koç'a 4. evre). Her retro seviyesi +%10 toz.

## 11. Sonsuz Gökyüzü (NG+) [KOD]

- Balık yenilince açılır. Her döngüde düşman canı +%40, hasarı +%20, seçkin ihtimali +%10; toz +%50.
- Döngüde her boss (Balık hariç) düzenli aralıklarla başka bir burcun **yankısını** taşır (aralık 11 sn − 1,5 sn × döngü, en az 5 sn).
- Döngü, Gözlemevi kapısında seçilebilir ya da Balık'tan sonra doğrudan geçilir.

## 12. İkizler (co-op) [KOD]

- **Yerel:** bilgisayarda en az bir kontrolcüyle. 1 kontrolcü: 1. oyuncu klavye+fare, 2. oyuncu kontrolcü; 2 kontrolcü: herkes kendi kontrolcüsü. Telefonda yok.
- **Çevrim içi:** Host/Katıl (ENet). Oyunun gerçeği host'tadır.
- Düşman canı ×1,5, boss canı ×1,6. Düşen oyuncuyu ortağı 2,5 sn yanında durarak %40 canla kaldırır; ikisi de düşerse run biter. Yerde kalan bir sonraki odaya %25 canla geçer.

## 13. Zorluk ve denge kuralları [CEO KARARI]

> 1038b6e'de öğrenme alanı kuralları İkizler'den Yengeç'e bir anda kalkıyordu ve düşmanın kendi bölgesine bakıyordu (T-04, T-05). Aşağıdaki kurallar CEO kararıyla **yeni hedef durumdur**; Yazılımcı birebir uygular, Testçi yeniden ölçer.
> Hedef: **"baskı/sn" (Testçi ölçütü) bölgeden bölgeye en fazla ~%30 artar**; hiçbir bölge bir öncekinden kolay olmaz (Balık en zor).

### 13.1 Öğrenme kademeleri (yumuşak geçiş, odanın bölgesine göre)
- Bütün kademe kuralları **odanın bölgesine** göre seçilir (`room.gd zone`), düşmanın görünüş bölgesine (`enemy.zone`, karışık gruplar) göre **değil**. Uygulama: `room.gd _spawn_enemy`/`_spawn_mini`/`_spawn_pebble`/`_on_summon` düşmana `e.room_zone = zone` verir; `enemy.gd _early()` ve aşağıdaki tablo `room_zone`'a bakar (`room_zone` boşsa `zone`'a; öğretici `"tutorial"` = Koç–İkizler kademesi).

| Odanın bölgesi | Hasar çarpanı | Aynı anda saldıran | Seri tavanı | Altın hazırlık | Kızıl hazırlık | Toparlanma | Bekleme |
|---|---|---|---|---|---|---|---|
| Koç, Boğa, İkizler (öğrenme) | ×0,80 | 2 | 2 | ×1,00 | ×0,85 | ×1,10 | ×1,15 |
| Yengeç (geçiş 1) | ×0,90 | 2 | 2 | ×0,97 | ×0,80 | ×1,05 | ×1,10 |
| Aslan (geçiş 2) | ×1,00 | oda 1–2: 2 · oda 3–4: 3 | 3 | ×0,95 | ×0,72 | ×1,00 | ×1,02 |
| Başak → Balık (tam) | ×1,00 | 3 | 3 | ×0,92 | ×0,65 | ×0,95 | ×0,95 |

- Kızıl hazırlık sütunu, altın sütunla **çarpılarak** uygulanır (bugünkü kod gibi: kızıl saldırı önce altın çarpanını, sonra kızıl çarpanını alır).
- Uygulama önerisi: `enemy.gd`'de `const TIER := {...}` ve `func _tier() -> Dictionary`; `_ready` içindeki `0.8 if _early()`, `1.0 if _early() else 0.92` vb. üçlü ifadeler bu tablodan okunur. `_attack_slots_full()` sınırı da buradan (Aslan için `room.local_i` gerekir: düşmana `e.room_local = local_i` verilir).
- Bölüm başlıkları ve Koç–İkizler davranışı bugünküyle aynı kalır.

### 13.2 Oda hasar tabloları (`room.gd DMG_MULT_*`, oda 1–4) [Yönetici kararı, CEO kapsamı: yumuşak geçiş]
Ölçüt **ham baskı/sn** (savunmadan arındırılmış, §15.7 standardı; bölgenin 1. odası). Hedef: ardışık iki bölgenin oranı **1,00–1,30**. **Koç ölçütten muaftır** (Koç ısınma bölgesi; Koç→Boğa oranı değerlendirilmez). Koç'u ayrıca ölçmek gerekirse 4 odasının ortalaması alınır.

| Bölge | 5c4f883 DMG_MULT | Ölçülen ham baskı (1. oda) | **Yeni DMG_MULT** | Hedef ham baskı | Oran |
|---|---|---|---|---|---|
| Koç | 1,0 · 1,1 · 1,2 · 1,3 | 3,1 | aynı | (muaf) | – |
| Boğa | 1,3 · 1,38 · 1,46 · 1,55 | 8,9 | aynı | 8,9 | muaf |
| İkizler | 1,6 · 1,68 · 1,76 · 1,85 | 9,3 | aynı | 9,3 | 1,04 |
| Yengeç | 1,9 · 1,98 · 2,06 · 2,15 | 10,1 | aynı | 10,1 | 1,09 |
| Aslan | 2,2 · 2,3 · 2,4 · 2,5 | **24,3** | **1,54 · 1,61 · 1,68 · 1,75** (+ varyant düzeltmesi, aşağıda) | ~12,5 | 1,24 |
| Başak | 2,10 · 2,18 · 2,28 · 2,40 | 17,3 | **1,89 · 1,96 · 2,05 · 2,16** (×0,9) | ~15,6 | 1,25 |
| Terazi | 1,93 · 2,00 · 2,07 · 2,17 | 15,2 | **2,41 · 2,50 · 2,59 · 2,71** (×1,25) | ~19,0 | 1,22 |
| Akrep | 2,36 · 2,43 · 2,50 · 2,62 | **28,5** | **1,86 · 1,92 · 1,98 · 2,07** (×0,79) | ~22,5 | 1,18 |
| Yay | 2,82 · 2,90 · 2,99 · 3,11 | 22,9 | aynı | 22,9 | 1,02 |
| Oğlak | 3,24 · 3,33 · 3,46 · 3,59 | 24,1 | aynı | 24,1 | 1,05 |
| Kova | 3,64 · 3,73 · 3,87 · 4,00 | 25,1 | aynı | 25,1 | 1,04 |
| Balık | 4,3 · 4,4 · 4,55 · 4,7 | 25,6 | aynı | 25,6 | 1,02 |

**Aslan varyant düzeltmesi (asıl sorun, `enemy.gd`):** Aslan bölgesinde iki güçlendirme üst üste biniyor ve sürekli açık kalıyor.
- Sürü (`_buff`): Aslan Gölgesi'ne 6 m içindeki her Aslan Gölgesi için +%20 (en çok 3 → +%60).
- Taç (`_tick_crown_caster`): Kâhin, 8 sn'de bir en yakın düşmana (Kolos'u yeğler) 8 sn'lik **+%50** taç veriyor. Bekleme süresi süreyle aynı olduğu için taç fiilen hiç düşmüyor.
- Bir Aslan 1. odasında (2–3 Gölge + Kâhin) bir Gölge kolayca ×1,9 vuruyor.

Yeni değerler:

| Ayar | Eski | **Yeni** |
|---|---|---|
| sürü bonusu (yakın Aslan Gölgesi başına) | +0,20, en çok 3 | **+0,10, en çok 2** |
| taç bonusu | +0,50 | **+0,30** |
| taç bekleme (`_crown_cd = 8.0`) / süre (8 sn) | 8 / 8 | **11 / 8** (3 sn tacsız boşluk) |
| `_buff()` toplam tavanı | yok | **≤ 1,40** |

Tablo düşüşü (×0,7) bu düzeltmeyle birlikte hesaplandı; tahmini toplam etki ×0,51 (24,3 → ~12,5). Testçi düzeltmeden sonra Aslan'ı yeniden ölçer. Aslan hedefin altında kalırsa (<11) önce tablo ×0,8'e (1,76 · 1,84 · 1,92 · 2,0) çekilir, varyant düzeltmesi kalır.

- HP tabloları (`HP_MULT_*`) bu turda değişmez.
- Kabul (Testçi): oranlar 1,00–1,30 içinde; bir bölge hedefinden ±%10 saparsa Yönetici o satırı günceller.

### 13.3 Seçkin sınırları
- **Bir bölgenin 1. odasında en fazla 1 seçkin; diğer her odada en fazla 2 seçkin** (bütün dalgalar toplamı; boss odasındaki çağrılan yardımcılar da sayılır). Bölünen seçkinin küçük kopyaları ve Boğa taşçıkları seçkin değildir.
- Uygulama: `room.gd`'de `var _elites := 0`; `_spawn_enemy` içinde `elite` zarı atılmadan önce `cap := 1 if local_i == 0 else 2`; `_elites >= cap` ise `e.elite = false`, değilse seçkin olunca `_elites += 1`.
- **Koç, Boğa, İkizler'de seçkinler tek özellikli**; Yengeç'ten itibaren 2 özellik. (Eski kuraldaki "Boğa/İkizler 4. odada 2 özellik" kalkar.) Özellik sayısı da odanın bölgesine bakar.
- Seçkin ihtimal tabloları (`ELITE_CHANCE_*`) aynı kalır; sınırlar oda süresindeki dalgalanmayı (T-03: 30–84 sn) azaltır.

### 13.4 Boss eğrisi
- Boss canı her bölgede artar (ters dönme yok), final Balık en zordur. Yeni tek kaynak: `room.gd` `const BOSS_HP := {...}`; `_spawn_boss` içinde `add_child`'dan önce `boss.max_hp = BOSS_HP[zone]`, sonra mevcut retro/döngü/co-op çarpanları. İkizler'de bu toplam candır (her ikiz yarısı, mevcut kod gibi). Boğa'nın gül canı zaten `max_hp / 2000` ile ölçekleniyor.

| Koç | Boğa | İkizler | Yengeç | Aslan | Başak | Terazi | Akrep | Yay | Oğlak | Kova | Balık |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1400 | 1800 | 2200 | 2500 | 2900 | 3300 | 3600 | 3700 | 4300 | 4900 | 5400 | 6000 |

- Akrep ölünce Anka olarak %35 canla bir kez daha doğar (etkin ~4995); bu bölgenin bilinçli zirvesidir, taban can sırası yine artandır.
- İkizler 2600 → 2200 (−%15): en uzun boss (T-06: 57 sn) kısalır.
- **Boss hasarı (`BOSS_DMG`) [Yönetici kararı, CEO kapsamı: boss eğrisi]:** final Balık en yüksek baskı; ardışık boss'larda baskı düşmez (oran 1,00–1,30). Ölçüm: yeni profil (§15.7), 5c4f883 (Balık 1,6 dahil).

| Boss | Koç | Boğa | İkizler | Yengeç | Aslan | Başak | Terazi | Akrep | Yay | Oğlak | Kova | Balık |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Ölçülen ham baskı | 6,7 | 7,4 | 13,5 | 8,1 | 16,5 | 10,3 | 10,0 | 25,7 | 11,1 | 16,0 | 20,0 | 16,8 |
| ~~Yeni BOSS_DMG~~ | 1,0 | 1,0 | 0,65 | 1,25 | 0,70 | 1,25 | 1,45 | 0,62 | 1,60 | 1,25 | 1,10 | 2,50 |
| ~~BOSS_DMG (Testçi 5. tur)~~ | 1,0 | 1,0 | 0,65 | 0,97 | 0,81 | 1,15 | 1,15 | 0,71 | 1,40 | 1,50 | 1,10 | 2,50 |
| **BOSS_DMG (Yönetici kararı, Testçi 7. tur)** | 1,0 | 1,0 | **0,65** | **0,97** | **0,81** | **1,05** | **1,15** | **0,95** | **1,15** | **1,50** | **1,10** | **2,50** |
| Hedef ham baskı | 6,7 | 7,4 | ~8,8 | ~10,1 | ~11,6 | ~12,9 | ~14,5 | ~15,9 | ~17,8 | ~20,0 | ~22,0 | ~26,3 |

  `const BOSS_DMG := {"aries": 1.0, "taurus": 1.0, "gemini": 0.65, "cancer": 1.25, "leo": 0.70, "virgo": 1.25, "libra": 1.45, "scorpio": 0.62, "sagittarius": 1.6, "capricorn": 1.25, "aquarius": 1.1, "pisces": 2.5}`. Testçi'nin önerisinden farkı: Balık 2,0 değil 2,5, çünkü Kova 1,1'de ~22 ve Balık en yüksek olmalı. Aslan boss'unun yavruları da sürü kuralına bağlıysa yukarıdaki varyant düzeltmesi boss'u da etkiler; Testçi yeniden ölçer.
  - **Balık notu [Yönetici kararı]:** `BOSS_DMG` 2,5 kalır, ama Balık'ın büyük tek vuruşları (`pisces_boss.gd` `BIG_HIT = 0,64` → etkin ~×1,6): kuyruk (26 ham → 41,6), girdap patlaması (28 → 44,8), çift ok çizgisi (20 → 32) ve burç yankıları (16–24 → 25,6–38,4). 100 canlı taban kahramana tek vuruş ≤ 45. Diğer saldırılar (kordon 18 → 45, kabarcık 14 → 35) tam ×2,5. Retro ve döngü çarpanları bunların üstüne biner.
- **Mekanik hasar tavanı yok [CEO KARARI]:** kahramanın aldığı hasara genel bir sınır konmaz (0.5.2'deki `hit_cap_frac` önerisi iptal; kodda uygulanmamıştı). Boss'ların büyük vuruşları kendi değerleriyle ayarlanır (Balık `BIG_HIT`, yukarıda). Normal düşmanlar için §13.8.
- **Boss odasındaki yardımcılar (çağrılanlar dahil) [CEO KARARI]:** `BOSS_DMG` almaz. Hasar ve can çarpanı olarak o bölgenin normal oda tablosunun **1. değerini** alır (`room.gd _tune_enemy`: boss odasında `di = 0`; bugün `mini(local_i, 3)` = 3, yani 4. oda değeri). Seçkin sınırı (§13.3, odada en fazla 2) geçerli.
- Hedef boss süreleri §15.2; Aslan sonrası boss süreleri düz kalmamalı (her boss bir öncekinden uzun ya da eşit).

### 13.5 Oda ve tehlike kuralları
- **Koç 1. oda:** 1. dalgaya bir Gölge eklenir: `COMBAT[0] = [["shade","shade","shade"], ["shade","caster","shade"]]` (toplam 6 düşman). Öğrenme alanı kuralları geçerli; tehlike yok.
- **Koç odaları 2 dalga** (oda 1: 3+3, sonra 3–5 düşman). Boğa'dan itibaren 2. odadan sonra 3 dalga (4–6 düşman).
- **Run'ın ilk iki odasında bölge tehlikesi yok** (`room_i < 2`).
- **Tehlike aralığı (`HAZARD_EVERY`, sn) yumuşak iner, Akrep'te ani sıklaşma yok:**

| Koç | Boğa | İkizler | Yengeç | Aslan | Başak | Terazi | Akrep | Yay | Oğlak | Kova | Balık |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 11 | 10 | 10 | 13 | 15 | 12 | 11 | 10 | 9 | 8,5 | 8 | 7,5 |

  (Eski: Terazi 12 → Akrep 6,5 → Yay 6 → Oğlak 7 → Kova 6 → Balık 7. Yengeç ve Aslan'ın uzun aralıkları tehlikelerinin büyüklüğünden, korunur.) `HAZARD_DMG` değişmez.
- **Zemin tehlikeleri de §13.8 kuralına tabi [CEO KARARI, Testçi 5. tur]:** tek tehlike vuruşu, o bölgenin yeni profil referans canının en çok **%30**'u. Genel tavan mekaniği yoktur; uyum `HAZARD_DMG` ve tehlike taban değerleriyle sağlanır. Ölçüm: her bölgenin 4. odası (`local_i = 3`, çarpan ×1,36), zırhsız kahraman, tehlike üstüne yürütülerek; 0,6 sn dokunulmazlık nedeniyle aynı olaydaki üst üste patlamalar tek vuruş sayılır.

| Bölge | Ref. can | Sınır (%30) | En büyük tehlike (taban × HAZARD_DMG) | Ölçülen en büyük vuruş | %ref |
|---|---|---|---|---|---|
| Koç | 100 | 30,0 | lav fışkırması 10 × 1,0 | 13,6 | %14 |
| Boğa | 100 | 30,0 | diken 8 × 1,15 | 12,5 | %12 |
| İkizler | 115 | 34,5 | rüzgâr (hasarsız) | 0 | 0 |
| Yengeç | 115 | 34,5 | gelgit 5/sn × 1,45 | 9,9/sn hesap (sürekli; 3 sn'de ~30) | %9/sn (%26/olay) |
| Aslan | 125 | 37,5 | Zenit 12 × 1,6 | 26,1 | %21 |
| Başak | 125 | 37,5 | ızgara 10 × 1,75 | 23,8 | %19 |
| Terazi | 125 | 37,5 | hüküm 10 × 1,9 | 25,8 | %21 |
| Akrep | 150 | 45,0 | asit 8 (+zehir %30) × 2,0 | 21,8 | %15 |
| Yay | 150 | 45,0 | ok yağmuru 9 × 2,1 | 25,7 | %17 |
| Oğlak | 170 | 51,0 | çığ 11 × 2,25 | 33,7 | %20 |
| Kova | 170 | 51,0 | yıldırım 11 × 2,4 | 35,9 | %21 |
| Balık | 187 | 56,1 | rüya köpüğü 10 × 2,55 | 34,7 | %19 |

  Bütün bölgeler sınırın altında; `HAZARD_DMG` değişmedi. Testçi 5. turda Balık 58,1 · Kova 49 · Oğlak 44 · Yay 42 ölçtü; bu değerler bu kodda (tek tehlike vuruşu olarak) üretilemedi. Testçi'nin ölçtüğü değerin kaynağı (tehlike + düşman vuruşu aynı anda, boss odası saldırıları ya da başka bir çarpan) yeniden ölçümde ayrılmalı.

- Koç'un ilk iki odasında seçkin yok (değişmez).
- Can odalar arası taşınır; iyileşme kaynakları: Sığınak (%40), bölge geçişi (%30), döngü geçişi (%50), lütuflar/harita/tılsımlar.

### 13.6 Boss evre alt süresi [CEO KARARI]
- Kural: **her boss evresi en az 6 sn sürer.** Evrenin başlangıcından 6 sn geçmeden boss'un canı o evrenin bitiş eşiğinin altına inemez (son evrede 1 canın altına inemez, yani ölemez). Fazla hasar kaybolur, sonraki evreye taşınmaz. Yeni oyuncu bir evreyi zaten 6 sn'den uzun sürede bitirdiği için onu etkilemez; yalnızca deneyimli profillerde (boss 7–11 sn) boss'u en az 3 evre × 6 sn'ye çıkarır.
- Evreler bugün her boss'ta aynı biçimde: `phase` değişkeni, `_damage()` (Gemini'de `_process`) içinde `hp < max_hp × eşik` kontrolü, `_enter_phase(p)`. Bütün boss'lar (Gemini hariç) `aries_boss.gd`'den türüyor.
- **Uygulama (tek kural):**
  1. `aries_boss.gd`: `const PHASE_MIN_T := 6.0`, `var phase_th: Array = [0.6, 0.25]` ve `var _phase_t0 := 0.0`. `phase` değişkenine setter: her atamada `_phase_t0 = Time.get_ticks_msec() / 1000.0`. Bu, alt sınıflardaki `_enter_phase` ve Akrep'in `phase = 3` ataması dahil her evre değişimini yakalar. Giriş (intro) bitişinde de `_phase_t0` sıfırlanır (1. evre girişten sonra başlar).
  2. Yeni yardımcı `func _phase_floor() -> float`: `now - _phase_t0 < PHASE_MIN_T` ise taban = `phase_th[phase-1] × max_hp` (dizi bittiyse 1,0), değilse 0.
  3. `_damage(d)` (base ve onu ezen her boss'ta) `hp -= d` satırından hemen sonra `hp = maxf(hp, _phase_floor())`. Akrep'te Anka doğuşundan sonraki evre de 6 sn kuralına uyar.
  4. Eşikler: her boss `_init` içinde kendi `phase_th`'ını yazar. Koç `[0.6, 0.25]` (Tam Tutulma açıkken `[0.6, 0.25, 0.12]`); Akrep `[0.5]` (Anka evresi son evre); Boğa, Yengeç, Aslan, Başak, Terazi, Yay, Oğlak, Kova, Balık `[0.65, 0.3]`.
  5. İkizler (`gemini_boss.gd`, `extends Node3D`): aynı setter ve `phase_th = [0.6, 0.3]`. Tabanı ikizler uygular: `gemini_twin.take_hit` içinde `final`, `boss.hp - final` tabandan aşağı inmeyecek kadar kırpılır (`boss` = ebeveyn İkizler düğümü).
- Süre **ağır çekim/hitstop'tan etkilenmeyen, duraklatmada duran saat** ile ölçülür (`Fx.unscaled_t`; normal oyunda gerçek zamana eşit, `--fixed-fps` testlerinde kare sayısına bağlı); çevrim içi co-op'ta yalnızca host uygular.

### 13.7 Doğum Haritası azalan getiri [CEO KARARI]
- Hedef: ilk run'lardaki his (ilk ~10 bin toz) **aynen** kalır; ileri kademelerde **hasar**, **kritik hasarı** ve **boss hasarı** yıldızları giderek daha az verir. Hedef: yarım harita (~506 bin toz) hasar ≲ ×2,5, boss hasarı ≲ ×3.
- "Hasar" kapsamı: `damage` ve türe özel hasar yıldızları (`combo_dmg`, `finisher_dmg`, `heavy_dmg`, `skill_dmg`; `calc_damage` içinde `damage`'a ekleniyorlar). Kritik şansı, can, zırh vb. etkilenmez.
- Formül (yumuşak tavan, eşik T'ye kadar doğrusal): `etkin(b) = b` (b ≤ T); `etkin(b) = T + (b − T) / (1 + (b − T) / k)` (b > T).
- Uygulanan değer: `hero_stats.gd compute` içinde haritadan gelen toplam (`stat_total` + büyük yıldızlar: Ascent, Spotlight, Kingslayer). Uygulama **gezegen lütuflarından (`Boons.apply`), tılsım, mühür ve yükselenden önce**; o kaynaklar tavanın dışında kalır.

| Değer | T (eşik ≈ 10 bin toz) | k |
|---|---|---|
| damage | 12 | 30 |
| combo_dmg | 10 | 25 |
| finisher_dmg | 17 | 30 |
| heavy_dmg | 10 | 25 |
| skill_dmg | 10 | 25 |
| crit_dmg | 18 | 40 |
| boss_dmg | 13 | 20 |

- Doğum Haritası ekranı yıldız/ev özetinde iki değeri de gösterir: `+58,9% (etkin +30,3%)`. Metin: EN "effective" → TR "etkin".
- **Hesap** (Analist, headless Godot ile `birth_chart.gd` ve `hero_stats.gd` üzerinden). Harita: her adımda en ucuz açık yıldızın alındığı açgözlü dolum. Hasar göstergesi = `(1 + (damage + combo_dmg)/100) × (1 + kritik şansı × (0,5 + crit_dmg/100))`, haritasız değere (1,025) bölünür. Boss göstergesi buna `× (1 + boss_dmg/100)` eklenmiş halidir. Yalnızca harita; tılsım, mühür ve lütuflar hariç.

| Toz | damage (ham → etkin) | combo | crit_dmg | boss_dmg | Hasar göstergesi (eski → **yeni**) | Boss göstergesi (eski → **yeni**) |
|---|---|---|---|---|---|---|
| 5 bin | 6,2 → 6,2 | 6,7 → 6,7 | 13,2 → 13,2 | 8,3 → 8,3 | ×1,15 → **×1,15** | ×1,24 → **×1,24** |
| 10 bin | 11,7 → 11,7 | 9,0 → 9,0 | 17,8 → 17,8 | 13,3 → 13,3 | ×1,24 → **×1,24** | ×1,40 → **×1,40** |
| 30 bin (deneyimli) | 17,5 → 16,6 | 18,7 → 16,5 | 32,7 → 28,7 | 23,2 → 19,8 | ×1,44 → **×1,40** | ×1,77 → **×1,68** |
| 506 bin (yarım) | 58,9 → 30,3 | 65,2 → 27,2 | 130,3 → 47,5 | 70,9 → 27,9 | ×3,34 → **×1,98** | ×5,71 → **×2,53** |

  (Kritik şansı tavansız: 5 bin %6,9 · 10 bin %7,6 · 30 bin %9,8 · 506 bin %29,3.)
- Testçi'nin ölçtüğü yarım harita ×5,1 / ×8,7 tılsım, mühür ve lütufları da içeriyor; bu tavan yalnızca harita payını düşürür. Testçi uygulamadan sonra kendi yöntemiyle yeniden ölçer. Hedef ×2,5 / ×3 tutmazsa Yönetici önce `damage` ve `boss_dmg`'nin k değerini düşürür (k 30 → 20, 20 → 15), T değerleri değişmez.

### 13.8 Normal düşman tek vuruş kuralı [CEO KARARI]
> CEO: "Normal canlılar normal güçte olmalı; boss ayrı, normal düşman ayrı. Her koşulda %60 vuran canlı OP'dir, nerflenmeli; genel sınır/tavan koymayalım."
> Testçi 3. tur (T-33/T-34, yeni profil): ilk odalarda tek vuruş canın %56–66'sı (Yengeç, Aslan, Terazi, Yay, Kova, Balık); boss odalarında Terazi Gölge yırtması 74 / pençe 54, Balık'ta ramcharge/pençe 88–117.

- **Ölçü:** bir normal düşmanın tek saldırısı, o bölgeye gelen **yeni oyuncu profilinin** (§15.7) en yüksek canının **en fazla %30'u** olur.
  - Seçkin (×1,25), seçkin özellikleri ve bölge varyant güçlendirmeleri dahildir. Aslan'da sürü + taç en çok ×1,40, Aslan dışı taç ×1,30.
  - Retro ve Sonsuz Gökyüzü hariçtir.
  - En kötü durum ölçülür: bölgenin 4. oda çarpanı, öğrenme kademesi hasar çarpanı dahil (§13.1).
- **Uygulama:** mekanik tavan yok. Saldırının kendi `dmg` değeri (`enemy.gd _setup_kind` ve bölge varyantları) düşürülür. Varyantta tanımlı olmayan, taban saldırıyı kullanan rol için o varyanta kendi saldırı listesi yazılır (değerler aşağıda).
- **İzin verilen en yüksek taban hasar:** `B(z) = 0,30 × can(z) / (DMG_MULT_z[oda 4] × kademe hasarı × 1,25 × güçlendirme)`, aşağı yuvarlanır.

| Bölge | Yeni profil can (referans) | %30 | Oda 4 DMG_MULT × kademe | **B (taban tavanı)** |
|---|---|---|---|---|
| Koç | 100 | 30 | 1,30 × 0,8 | **23** |
| Boğa | 100 | 30 | 1,55 × 0,8 | **19** |
| İkizler | 115 | 34,5 | 1,85 × 0,8 | **18** |
| Yengeç | 115 | 34,5 | 2,15 × 0,9 | **14** |
| Aslan | 125 | 37,5 | 1,75 × 1,0 (× sürü/taç) | **12** Gölge · **13** diğer |
| Başak | 125 | 37,5 | 2,16 | **13** |
| Terazi | 125 | 37,5 | 2,71 | **11** |
| Akrep | 150 | 45 | 2,07 | **17** |
| Yay | 150 | 45 | 3,11 | **11** |
| Oğlak | 170 | 51 | 3,59 | **11** |
| Kova | 170 | 51 | 4,00 | **10** |
| Balık | 170 | 51 | 4,70 | **8** |

  Referans canlar Testçi 3. tur `tres3` yeni profil oda ortalamalarından, artan sıraya getirilip 5'e aşağı yuvarlandı (Analist). Testçi'nin bölge tablosu bundan yüksekse (ör. Balık 187), Yönetici B'yi o tabloyla yeniden hesaplar: B Balık'ta 9 olur.

- **Yeni saldırı değerleri** (yalnızca B'yi aşanlar; diğerleri aynı kalır). "Taban" = `_setup_kind` değeri (Gölge pençe 16 / yırtma 22, Kâhin ışık mermisi 12, Atlayan pençe 12 / atılış 22, Kolos ezme 24 / deprem 26).

| Bölge | Rol | Saldırı | Eski | **Yeni** |
|---|---|---|---|---|
| Koç | Kolos (taban) | smash / quake | 24 / 26 | **23 / 23** |
| Boğa | Gölge (taban) | rend | 22 | **19** |
| Boğa | Atlayan | burrow | 20 | **19** |
| Boğa | Kolos | smash / fissure | 24 / 24 | **19 / 19** |
| İkizler | Gölge (taban) | rend | 22 | **18** |
| İkizler | Atlayan | burrow | 22 | **18** |
| İkizler | Kolos | smash / quake | 24 / 26 | **18 / 18** |
| Yengeç | Gölge (taban) | claw / rend | 16 / 22 | **14 / 14** |
| Yengeç | Gölge | kabuk kıskacı (`_shell_snap`, 18 × dmg_mult) | 18 | **16** (Yengeç+ odalarda `ZONE_HIT`, §13.9.2c, T-45) |
| Yengeç | Atlayan | pulse | 16 | **14** |
| Yengeç | Kolos | smash | 24 | **14** |
| Aslan | Gölge (taban) | claw / rend | 16 / 22 | **12 / 12** |
| Aslan | Kâhin | sunbeam | 16 | **13** |
| Aslan | Atlayan (taban) | pounce | 22 | **13** |
| Aslan | Kolos | smash | 26 | **13** |
| Başak | Gölge | claw / reap | 16 / 20 | **13 / 13** |
| Başak | Kâhin | seals | 16 | **13** |
| Başak | Atlayan (taban) | pounce | 22 | **13** |
| Başak | Kolos (taban) | smash / quake | 24 / 26 | **13 / 13** |
| Terazi | Gölge (taban) | claw / rend | 16 / 22 | **11 / 11** |
| Terazi | Kâhin | verdict | 16 | **11** |
| Terazi | Atlayan (taban) | claw / pounce | 12 / 22 | **11 / 11** |
| Terazi | Kolos (taban) | smash / quake | 24 / 26 | **11 / 11** |
| Terazi | Kolos (Karşı Ağırlık) | birikmiş patlama (22 × dmg_mult) | 22 | **13** |
| Akrep | Gölge (taban) | rend | 22 | **17** |
| Akrep | Atlayan (taban) | pounce | 22 | **17** |
| Akrep | Kolos | smash | 24 | **17** |
| Yay | Gölge (taban) | claw / rend | 16 / 22 | **11 / 11** |
| Yay | Atlayan | claw / burrow | 12 / 22 | **11 / 11** |
| Yay | Kolos | smash / ballista | 24 / 22 | **11 / 11** |
| Oğlak | Gölge | claw / butt | 16 / 20 | **11 / 11** |
| Oğlak | Kâhin | icespikes | 14 | **11** |
| Oğlak | Atlayan | ramcharge | 20 | **11** |
| Oğlak | Kolos (taban) | smash / quake | 24 / 26 | **11 / 11** |
| Kova | Gölge | claw | 15 | **10** |
| Kova | Kâhin | stormorb | 14 | **10** |
| Kova | Atlayan | claw / urn | 13 / 16 | **10 / 10** |
| Kova | Kolos | smash / pulse | 24 / 16 | **10 / 10** |
| Balık | Gölge | claw / ramcharge | 15 / 16 | **8 / 8** |
| Balık | Kâhin | lure | 18 | **8** |
| Balık | Atlayan | claw / bubbles | 13 / 13 | **8 / 8** |
| Balık | Kolos | smash / tidewave | 25 / 18 | **8 / 8** |
| Terazi, Kova, Balık | seçkin özelliği "patlayan" (`room.gd`, 14 × dmg_mult) | blast | 14 | **13 / 12 / 10** (diğer bölgeler 14) |

  Değişmeyenler: Koç kor cini ölüm patlaması (10), Boğa taşçık (10), tüm Kâhin mermileri B altındakiler (Boğa 11, İkizler 12, Yengeç 14, Akrep 12, Yay 11), Akrep grab 16, Aslan roar 12, Yengeç bubbles 10, Akrep/İkizler/Oğlak pençeleri B altında kalanlar.
- **Karışık (yabancı) yaratıklar:** önceki bölgeden gelen bir yaratık o odada, **odanın bölgesindeki aynı rolün** saldırı değerlerini kullanır; mekaniği kendi kalır. Altın saldırısı yerli altın saldırısının, kızıl saldırısı yerli kızıl saldırısının hasarını alır. Kendi değeri daha düşükse kendi değeri kalır.
  - Örnek: Balık'ta Koç Atlayanı'nın ramcharge'ı 20 değil 8.
  - Uygulama: `enemy.gd`'de bölge × rol × renk (altın/kızıl) için yerli değer tablosu `NATIVE_HIT`; `_ready` içinde `room_zone != zone` ise saldırı başına `dmg = min(dmg, NATIVE_HIT[room_zone][kind][renk])`.
- **Baskı uyarısı:** bu değerler ileri bölgelerde vuruşları yaklaşık yarıya indirir; §13.2'deki baskı/sn hedefleri düşer. Analist önerisi [Yönetici onayı gerekir]: baskı yeniden ölçülünce açık, büyük tek vuruşla değil saldırı sıklığı (`cd`), aynı anda saldıran sayısı ya da dalga düşman sayısıyla kapatılır; `DMG_MULT` yükseltilirse bu tablo yeniden hesaplanır.

- **Saldırı sıklığı telafisi [Yönetici kararı] — 0.5.4'te KALDIRILDI (§13.9.5):** vuruşlar küçülünce ileri bölgelerin baskısı düşmemeli; oyun zor kalır, yalnızca tek vuruşla öldürmez. Telafi büyük tek vuruşla değil, daha sık saldırıyla yapılır.
  - `enemy.gd` `ATK_RATE`: odanın bölgesine göre (`room_zone`, §13.1 gibi) saldırı bekleme süresini (`cd`) ve toparlanma süresini (`recover`) bölen çarpan. **Hazırlık (`windup`) süresine dokunulmaz** (okunabilirlik kalır).
  - Başlangıç değeri: o bölgede eski ortalama taban vuruş / yeni ortalama taban vuruş (bölge varyantlarının 4 rolündeki hasarlı saldırılar, düz ortalama). `cd` ×0,6'nın altına inmez, yani çarpan en çok 1/0,6 = 1,67.
  - Öğrenme kademesi bölgeleri (Koç, Boğa, İkizler) ve öğretici etkilenmez (çarpan 1,0). Kalan açık aynı anda saldıran sayısıyla kapatılmaz; Testçi baskıyı ölçer, Yönetici tabloyu ayarlar.

| Bölge | Eski ort. vuruş | Yeni ort. vuruş | Oran | **ATK_RATE** |
|---|---|---|---|---|
| Yengeç | 17,0 | 13,3 | 1,28 | **1,28** |
| Aslan | 18,0 | 12,4 | 1,45 | **1,45** |
| Başak | 19,4 | 12,9 | 1,51 | **1,51** |
| Terazi | 19,7 | 11,0 | 1,79 | **1,67** (tavan) |
| Akrep | 17,7 | 15,3 | 1,16 | **1,16** |
| Yay | 18,4 | 11,0 | 1,68 | **1,67** (tavan) |
| Oğlak | 20,0 | 11,0 | 1,82 | **1,67** (tavan) |
| Kova | 16,3 | 10,0 | 1,63 | **1,63** |
| Balık | 16,9 | 8,0 | 2,11 | **1,67** (tavan) |

### 13.9 Düşman gücü ve agresiflik [CEO KARARI]
> CEO: "Düşmanların genel özellikleri artmalı: can, saldırı gücü vs., daha agresif olmalılar." Normal düşman tek vuruş kuralı (§13.8, yeni profil canının ≤ %30'u, mekanik tavan yok) aynen geçerli.
> Testçi 4. tur (d7ddc32): ilk oda ham baskı Yengeç 10,5 · Aslan 11,2 · Başak 12,8 · Terazi 15,0 · Akrep 14,1 · Yay 14,0 · Oğlak 15,9 · Kova 16,9 · Balık 14,4 (50b98f2'de 13,9 · 17,0 · 16,9 · 22,7 · 21,7 · 22,6 · 26,0 · 27,8 · 30,8). `ATK_RATE` etkisiz: darboğaz aynı anda saldıran sınırı. Deneyimli profil Akrep'ten sonra ilk odalarda %1–4, boss'larda %0–1 can kaybediyor.
> **Koç, Boğa, İkizler (öğrenme bölgeleri) bu bölümden hiç etkilenmez.** Bütün kurallar odanın bölgesine (`room_zone`) bakar.

#### 13.9.1 Can (`room.gd HP_MULT_*`)
Yengeç'ten itibaren bölge başına artan çarpan: Yengeç ×1,10 · Aslan ×1,15 · Başak ×1,20 · Terazi ×1,25 · Akrep ×1,30 · Yay ×1,35 · Oğlak ×1,40 · Kova ×1,45 · Balık ×1,50. Seçkin ×1,6 ve co-op ×1,5 üstüne gelir.

| Bölge | Eski | **Yeni (oda 1–4)** |
|---|---|---|
| Yengeç | 1,85 · 1,95 · 2,05 · 2,15 | **2,04 · 2,15 · 2,26 · 2,37** |
| Aslan | 2,1 · 2,2 · 2,3 · 2,45 | ~~2,42 · 2,53 · 2,65 · 2,82~~ ~~2,22 · 2,32 · 2,43 · 2,59~~ (×0,92, Testçi 5. tur) **2,11 · 2,20 · 2,31 · 2,46** (×0,95, Yönetici kararı, Testçi 6. tur) |
| Başak | 2,35 · 2,5 · 2,6 · 2,75 | ~~2,82 · 3,00 · 3,12 · 3,30~~ **2,59 · 2,76 · 2,87 · 3,04** (×0,92, Yönetici kararı, Testçi 5. tur) |
| Terazi | 2,6 · 2,75 · 2,9 · 3,05 | **3,25 · 3,44 · 3,63 · 3,81** |
| Akrep | 2,85 · 3,0 · 3,15 · 3,3 | **3,71 · 3,90 · 4,10 · 4,29** |
| Yay | 3,1 · 3,25 · 3,4 · 3,6 | ~~4,19 · 4,39 · 4,59 · 4,86~~ **5,03 · 5,27 · 5,51 · 5,83** (×1,20, Yönetici kararı, Testçi 5. tur) |
| Oğlak | 3,35 · 3,5 · 3,7 · 3,9 | **4,69 · 4,90 · 5,18 · 5,46** |
| Kova | 3,6 · 3,75 · 3,95 · 4,15 | **5,22 · 5,44 · 5,73 · 6,02** |
| Balık | 3,85 · 4,0 · 4,2 · 4,4 | **5,78 · 6,00 · 6,30 · 6,60** |

- Kabul (Testçi): deneyimli profil Akrep–Balık ilk odalarında belirgin can kaybı (hedef ≥ %8). Yeni profilde oda süresi §15.2 üst sınırını (%10 pay ile) aşan bölgenin çarpanı Yönetici tarafından 0,05 adımlarla düşürülür.

#### 13.9.2 Saldırı gücü
Üç adım; üçü de §13.8 kuralını korur (en kötü durum: bölgenin 4. oda çarpanı).

**(a) Seçkinler daha sert vurmaz (Yengeç'ten itibaren).** Seçkin hasar çarpanı (`em`) Yengeç–Balık odalarında 1,25 → **1,00**; can ×1,6, özellikler ve hale aynı kalır. Koç–İkizler'de 1,25 kalır.
- Gerekçe: §13.8'deki B, "her vuruş seçkin olabilir" varsayımıyla ×1,25 düşük hesaplanmıştı; bu yüzden sıradan düşmanlar canın ancak ~%22–24'ünü vuruyordu. Seçkinin farkı dayanıklılık ve özellikleri olur, bütün düşmanlar kurala yakın vurur.

**(b) Oda içi hasar eğrisi düzleşir.** Oda 4 değeri (B hesabının dayanağı) aynı kalır, oda 1–3 ona yaklaşır: `DMG_MULT_z = M4 × [0,95 · 0,97 · 0,99 · 1,00]`.

| Bölge | Yeni DMG_MULT (oda 1–4) |
|---|---|
| Yengeç | 2,04 · 2,09 · 2,13 · 2,15 |
| Aslan | 1,66 · 1,70 · 1,73 · 1,75 |
| Başak | 2,05 · 2,10 · 2,14 · 2,16 |
| Terazi | 2,57 · 2,63 · 2,68 · 2,71 |
| Akrep | 1,97 · 2,01 · 2,05 · 2,07 |
| Yay | 2,95 · 3,02 · 3,08 · 3,11 |
| Oğlak | 3,41 · 3,48 · 3,55 · 3,59 |
| Kova | 3,80 · 3,88 · 3,96 · 4,00 |
| Balık | 4,47 · 4,56 · 4,65 · 4,70 |

**(c) Bölge vuruş değeri.** Yengeç'ten itibaren rol ve saldırı adına göre tablo (`HIT_TABLE`/`NATIVE_HIT`) yerine **tek bölge değeri**: o odadaki her normal düşmanın hasarlı her saldırısı (dmg > 0; `mirror`, `blink` gibi 0 hasarlılar hariç), düşmanın kökeni (yerli ya da karışık) ne olursa olsun, `ZONE_HIT[room_zone]` taban değerini alır. Yeni izin verilen tavan: `B' = 0,30 × can / (M4 × kademe hasarı × güçlendirme)` (seçkin çarpanı artık yok).

| Bölge | Referans can | B' | **ZONE_HIT** | Tahmini ham baskı (1. oda) | Oran |
|---|---|---|---|---|---|
| İkizler (değişmez) | 115 | – | – | 9,3 (ölçülen) | – |
| Yengeç | 115 | 17,8 | ~~15~~ ~~12~~ **11** (Yönetici kararı, Testçi 7. tur) | ~11,5 | 1,24 |
| Aslan | 125 | 15,3 Gölge (sürü+taç ×1,40) · 16,5 diğer (taç ×1,30) | ~~15 Gölge · 16 diğer~~ **14 Gölge · 15 diğer** | ~13,8 | 1,20 |
| Başak | 125 | 17,4 | ~~17~~ **15** | ~16,5 | 1,20 |
| Terazi | 125 | 13,8 | **13** | ~17,1 | 1,04 |
| Akrep | 150 | 21,7 | **18** | ~18,2 | 1,06 |
| Yay | 150 | 14,5 | **14** | ~19,3 | 1,06 |
| Oğlak | 170 | 14,2 | **13** | ~20,5 | 1,06 |
| Kova | 170 | 12,75 | **12** | ~22,0 | 1,07 |
| Balık | 187 (Testçi) | 11,9 | **11** | ~21,2 | 0,96 (aşağıda) |

- ZONE_HIT bazı bölgelerde B''nin altında seçildi (Yengeç, Akrep, Oğlak). Böylece ardışık oran 1,00–1,30 içinde kalır.
- **Yönetici kararı, Testçi 5. tur:** ZONE_HIT Yengeç 15→12, Aslan Gölge 15→14 / diğer 16→15, Başak 17→15 (tablodaki "Tahmini ham baskı" ve "Oran" sütunları eski değerlere göredir; Testçi yeniden ölçer). Kabuk Askeri'nin kıskacı (`_shell_snap`, T-45) Yengeç ve sonrasında `ZONE_HIT[room_zone] × dmg_mult` vurur; Koç–İkizler'de 16 × dmg_mult kalır.
- **Yönetici kararı, Testçi 6. tur (T-54):** sabit yazılmış ek vuruşlar da aynı kurala bağlı (`enemy.gd _zone_hit_or`): Karşı Ağırlık patlaması (Koç–İkizler 13), Koç Gölgesi'nin ölüm kor patlaması (10). Süreli hasarlar (Akrep zehri 4/5 × dmg_mult, ateş topu gölcüğü 5/sn × dmg_mult) vuruş sayılmaz, değişmedi.
- Tahmin; şu çarpanlarla yapıldı:
  - (a) seçkin farkının kalkması: ×0,95
  - (b) 1. oda düzleşmesi: ×1,04–1,08
  - (c) vuruş artışı: yeni değer / eski ortalama
  - §13.9.5 ATK_RATE'in kalkması: ×0,95
  - §13.9.3 dördüncü saldıran (Akrep'ten itibaren): ×1,15 varsayım
- Testçi ölçer. Ardışık oran 1,00'ın altına düşerse önce düşen bölgenin ZONE_HIT'i B' içinde 1 artırılır; B' doluysa §13.9.4 seçkin oranı, sonra Yönetici'ye bildirilir.
- **Balık açığı:** B' Balık'ı Kova'nın altında (~0,96) tutuyor, çünkü M4 = 4,7 çok büyük. Açık ölçümde kalırsa: [ÖNERİ – CEO onayı gerekir] Balık'ta aynı anda saldıran 5 (kızıl yine en çok 2).
- Ek hasar kaynakları aynı kalır (kabuk kıskacı 16, Karşı Ağırlık 13, patlayan özelliği §13.8); seçkin çarpanı almadıkları için kural içinde.
- **T-41 (Terazi Atlayan pençesi 38,6 = %31):** tek bölge değeri her saldırıya uygulandığı için eksik satır sorunu ortadan kalkar; tablo satırı eklemeye gerek yok. Tek bölge değeri uygulanmadan önce düzeltilecekse: `HIT_TABLE` her bölgede, o bölgede görünebilen her rolün (taban rol dahil) her hasarlı saldırısını içermeli; Terazi Atlayan için `claw 11`.
- **T-40 (Aslan tacı Aslan dışına taşınıyor):** tacı **yalnızca Aslan odalarında** ver (`_tick_crown_caster` yalnızca `room_zone == "leo"` iken çalışır; karışık Aslan Kâhini başka bölgede sadece güneş ışınını atar).
  - Gerekçe: taç Aslan bölgesinin kimliği (Güneş Kral'ın sarayı) ve orada B hesabında var.
  - Alternatif olan Aslan sonrası bütün bölgelerin B'sini ×1,30 ile hesaplamak, tacın nadiren göründüğü 7 bölgede bütün vuruşları ~%23 düşürür. Bu, CEO'nun "daha güçlü" isteğine ters.

#### 13.9.3 Agresiflik: aynı anda saldıran
| Odanın bölgesi | Aynı anda saldıran (`slots`) | Aynı anda kızıl saldırı |
|---|---|---|
| Koç–İkizler | 2 (değişmez) | en çok 2 |
| **Yengeç → Balık** | **4** (bütün odalar; Aslan'ın 2/3 oda kuralı kalktı) | **en çok 2** |

- **[CEO KARARI, Testçi 5. tur]** Aynı anda 4 saldıran Akrep yerine **Yengeç'ten** itibaren geçerli (`TIER` cancer/leo/full/late `slots = 4`; Aslan'ın oda 1–2'de 2 kuralı kaldırıldı). Kızıl saldırı aynı anda en çok 2 kuralı aynen. Önceki tablo: Yengeç 2 · Aslan 2/3 · Başak–Terazi 3 · Akrep–Balık 4.

- (Eski not, yukarıdaki CEO kararıyla geçersiz:) CEO metni "Yengeç–Terazi 3 kalır" diyor; kodda Yengeç 2, Aslan 2/3. "Kalır" ifadesine göre değiştirilmedi. Yengeç'in de 3 olması isteniyorsa ayrıca söylenmeli; Yengeç 3 olursa İkizler→Yengeç oranı 1,30'u aşabilir.
- Kızıl sınırı (okunabilirlik): bir düşman saldırı seçerken, odada `windup`/`act` durumunda parry'lenemeyen saldırısı olan düşman sayısı ≥ 2 ise kızıl saldırılar aday listesinden çıkar. Altın saldırısı yoksa düşman kısa bekler (`_global_cd` 0,25–0,5 sn, bugünkü sınır davranışı gibi). Bütün bölgelerde geçerli.
- **Hazırlık (`windup`) değişmez.**
- Uygulama: `TIER`'e `"late"` kademesi (Akrep–Balık): `full` ile aynı, yalnızca `slots: 4`.

#### 13.9.4 Seçkin oranı (`ELITE_CHANCE_*`)
Oda başı sınırlar (§13.3: 1. odada 1, diğer odalarda 2; ilk 3 bölgede tek özellik) aynen kalır. Yeni oranlar seçkinlerin dalgalarda daha erken ve daha sık çıkmasını sağlar.

| Bölge | Eski | **Yeni (oda 1–4)** |
|---|---|---|
| Yengeç | 0,30 · 0,35 · 0,40 · 0,40 | **0,35 · 0,40 · 0,45 · 0,45** |
| Aslan | 0,35 · 0,40 · 0,45 · 0,45 | **0,40 · 0,45 · 0,50 · 0,50** |
| Başak | 0,40 · 0,45 · 0,50 · 0,50 | **0,45 · 0,50 · 0,55 · 0,55** |
| Terazi | 0,45 · 0,50 · 0,50 · 0,55 | **0,50 · 0,55 · 0,55 · 0,60** |
| Akrep | 0,50 · 0,50 · 0,55 · 0,55 | **0,60 · 0,60 · 0,65 · 0,65** |
| Yay | 0,50 · 0,55 · 0,55 · 0,60 | ~~0,60 · 0,65 · 0,65 · 0,70~~ ~~0,70 · 0,75 · 0,75 · 0,80~~ (Testçi 5. tur) **0,80 · 0,85 · 0,85 · 0,90** (+0,10, Yönetici kararı, Testçi 6. tur) |
| Oğlak | 0,55 · 0,55 · 0,60 · 0,60 | ~~0,65 · 0,65 · 0,70 · 0,70~~ **0,70 · 0,70 · 0,75 · 0,75** (+0,05, Yönetici kararı, Testçi 7. tur) |
| Kova | 0,55 · 0,60 · 0,60 · 0,65 | **0,65 · 0,70 · 0,70 · 0,75** |
| Balık | 0,60 · 0,60 · 0,65 · 0,70 | **0,70 · 0,70 · 0,75 · 0,80** |

- **Boss hasarı (`BOSS_DMG`, §13.4) — Yönetici kararı, Testçi 5. tur:** Yengeç 0,97 · Aslan 0,81 · Başak 1,15 · Terazi 1,15 · Akrep 0,71 · Yay 1,40 · Oğlak 1,50; Koç/Boğa 1,0, İkizler 0,65, Kova 1,1, Balık 2,5 aynı.
- **Yönetici kararı, Testçi 7. tur:** BOSS_DMG Başak 1,15→1,05, Akrep 0,71→0,95, Yay 1,40→1,15; ZONE_HIT Yengeç 12→11; Oğlak seçkin oranı +0,05. Akrep boss'unun en büyük tek vuruşu (dalış patlaması 26 × 0,95) 100 canlı taban kahramana **24,7** (%24,7). **Yay ve Kova (T-60):** her odada 1. ve 2. dalgaya +1 Gölge (`room.gd`, dalga tablosu kopyalanarak). **Bitmeyen oda (T-58):** odada aynı anda en çok 1 şifacı seçkin; şifacı ile kalkanlı aynı düşmanda birleşmez.

#### 13.9.5 ATK_RATE kaldırılır
- `enemy.gd` `ATK_RATE` ve `_ready` içindeki `/ atk_rate` bölmesi silinir; `cd` ve `recover` yalnızca `TIER`'den gelir.
- Gerekçe: Testçi ölçümü `cd`'yi ek yarıya indirmenin baskıyı yalnızca +%5 artırdığını gösterdi. Düşmanlar saldırı sırasına (`slots`) takılıyor, sık saldırı hak beklemeye dönüşüyor. `cd` ×0,6 düşmanları aralıksız saldıran makinelere çevirip okunabilirliği bozuyor. Etki §13.9.3'teki dördüncü saldırana devredildi.

#### 13.9.6 Ayna Muhafızı yansıtması (T-42) [CEO KARARI]
İkizler Kolos'u (`gemini` + `brute`, saldırı `mirror`; karışık gruplarla ileri bölgelerde de görünür). Bugün ayna duruşunda hafif vuruşun hasarının %50'si kahramana dönüyor, ağır vuruş aynayı kırıp düşmanı 1,4 sn sersemletiyor (`enemy.gd take_hit`).
- **Yansıtma (CEO son hali, öncekileri geçersiz kılar):** kalkan açıkken (`mirror` hazırlığı ve `act`) gelen **hafif** vuruş düşmana hasar vermez. Kahramanın o vuruşta vereceği hasarın (yansıtma noktasındaki `dmg`) **%10'u** kahramana döner. **Tavan yok**; §13.8'in %30 sınırı bu mekaniğe uygulanmaz. Retro/NG+ çarpanı eklenmez.
  - **Ağır vuruş** (Kentaur Yayı'nın ağır oku dahil, `heavy = true`) aynayı kırar, düşmanı 1,4 sn sersemletir (değişmez), yansıtma olmaz.
  - **Yakın dövüş ve alan vuruşları anında yansır:** kombo, atılma vuruşu ve yer/alan yetenekleri (Yıldız Yağmuru, Ok Yağmuru, Çarpma, Takımyıldızı Adımı, patlama/hale/yörünge/girdap/koni/hat yetenekleri). Kod: `hero.take_damage(dmg * 0.10, -dir, false)`. Yörünge ve hale gibi tik vuran yeteneklerde her tik ayrı yansır.
  - **Mermiler geri seker (anında hasar yok):** mermi kalkana çarpınca durur. Aynı hız ve doğrultuda, **o anki kahraman konumuna** doğru düz giden (güdümsüz) bir "seken mermi" doğar.
    - Seken mermi kahramana çarparsa, orijinal merminin o düşmana vereceği hasarın %10'unu verir. Kahraman atılır ya da kenara kaçarsa hiç hasar almaz.
    - Seken mermi menzili kadar (ya da arena kenarına kadar) gider, düşmanlara çarpmaz, kaybolur.
  - **Mermi sayılanlar** (`star_skills.gd` sınıfları):

| Mermi | Kaynak | Seken davranış |
|---|---|---|
| `Arrow` | Kentaur Yayı hafif okları ve kombo okları | ok geri döner |
| `LightWave` | Işık Dalgası, Kuyruklu Yıldız Atışı, Delici Yıldız | delip geçen dalga: kalkana çarpan dalga o düşmanda durmaz, yoluna devam eder; aynadan ayrıca küçük bir yansıma parçası (dalga genişliğinin yarısı) kahramana döner |
| `Boomerang` | Hilal Biçişi | o düşmanda geri döner, kalkanı kesmez; kahramana dönen yolu seken mermi sayılır |
| `Hook` | Zincir Kancası | kanca çekmez, geri seker; kahramana değerse %10 hasar |

  - **Mermi sayılmayanlar** (gökten düşen, yerde ya da kahramanın çevresinde oluşanlar): `Starfall`, `Burst`, `Aura`, `Orbit`, `Vortex`, `FlameCone`, `LineStrike`, `ConstellationPath` ve atılma vuruşu. Bunlar anında yansır.
  - **Seken merminin okunurluğu:** ayna rengi (altın-gümüş, `Color(0.95, 0.9, 1.0)`) parlak iz. Mermi boyu orijinalin en az 1,2 katı. Yansıma anında kalkanda parlama ve kristal ses (`parry`, perde 2,2). Seken mermi kahramanın göremeyeceği kadar hızlı olmamalı: hızı en çok 22 m/sn, gerekirse yavaşlatılır.
  - Yansıtmalar "en büyük 5 vuruş" listesinde ayrı kaynak olarak görünür (§15.7).
- **Belirginlik (zorunlu):**
  1. **Açılış:** `mirror` hazırlığı başlarken kristal ses (`parry`, perde 2,0, −2 dB) + kısa "çın" (`switch`, perde 1,6). Düşmanın önünde parlak altın-gümüş ayna kalkanı 0,2 sn'de büyüyerek açılır (mevcut `_mirror_node` disk: altın kenarlı, emisyon ≥ 3, kenarı yavaşça dönen parıltılı halka; arkasında yarı saydam altın kubbe, yarıçap 1,3 × `size_k`).
  2. **Süre boyunca:** düşmanın başının üstünde büyük altın **◈ ayna simgesi** (Label3D, billboard, derinlik testi yok, yazı boyu ≥ 96, 0,6 sn'de bir nabız). Ayrıca kahramana bakan yüzde yansıyan ışık titreşimi. Kalkan bitince simge 0,15 sn'de söner.
  3. **Yansıma anı:** kalkandan kahramana uzanan 0,15 sn'lik altın ışın çizgisi. Kahramanın üstünde altın geri tepme halkası (`Juice.ring_wave`, 1,6 m). Hasar sayısı "↩" önekiyle altın renkte. Kısa kamera sarsıntısı (0,25). Kahramana küçük geri itme (`-dir`, 6).
  4. **Kırılma (ağır vuruş):** ayna cam kırıkları gibi altın parçalara dağılır, kırılma sesi (`crush`), simge söner.
  5. İlk görüldüğünde rehberlik kartı (§19.2 biçimi), anahtar `hints["mirror"]`:

| EN | TR |
|---|---|
| MIRROR GUARD · While its mirror is up, light hits bounce back. A heavy attack shatters it. | AYNA MUHAFIZI · Aynası açıkken hafif vuruşlar sana döner. Ağır saldırı aynayı kırar. |

- **Yönetici kararı, Testçi 5. tur:**
  - **Yoldaş vuruşları (T-50):** Tilki vb. yoldaşın aynaya çarpan vuruşu kahramana yansımaz ve düşmana hasar vermez; küçük bir ayna kıvılcımıyla söner.
  - **Okunurluk (T-51):** ayna diski ve kenar halkasının emisyonu bloom eşiğinin (1,2) altında (disk ≈0,9, halka 1,1, yansıma parlaması 1,8; ışık enerjisi 1,5). Muhafız ve zemin uyarıları kalkanın arkasında görünür kalır. Seken mermi: koyu kenarlı, kızıl-altın, kalın (≥0,16 m) gövde ve arkasında 0,5 sn'de sönen koyu kenarlı iz (ışıksız, beyaz zeminde okunur). "↩" sayısı büyük (84), kalın koyu kenarlı ve kahramanın sağ üstünde, ışık halkasının dışında.
  - **Ağır ok (T-52):** Kentaur Yayı'nın ağır oku aynayı okun kendi `heavy` bayrağıyla kırar (`hero.last_atk_kind`'a bakılmaz).

## 14. ÖĞRETİCİ ODA [CEO KARARI: onaylı özellik]

> Boğaç: "tüm odalardan önce bir öğretici odası kur, ilk oynayan için geçerli, her şeyi öğret: parry olsun, skiller olsun, vuruşlar olsun, her şeyi"; "skilleri falan öğretsin başında".

### 14.1 Ne zaman çıkar
- Kayıt yuvasında `tutorial_done` bayrağı **yoksa/false ise**, ilk run'ın **Kapı → Yükselen seçimi**nden sonra, Koç Geçidi'nin 1. odasından **önce** çıkar.
- Bitince (ya da atlanınca) `tutorial_done = true` yuvaya kaydedilir; bir daha kendiliğinden çıkmaz. Ardından run normal şekilde Koç Geçidi 1. odadan başlar (run zaten başlatılmış olur; öğretici run'ın canına, tozuna, lütuflarına dokunmaz).
- Bayrak **yuva başınadır** (her yeni yuva = yeni oyuncu).
- **Eski kayıtlar:** yuvada anahtar yoksa ve yuvada ilerleme varsa (toz > 0, harita boş değil, herhangi bir boss yenilmiş ya da almanak boş değil) `tutorial_done = true` sayılır; yeni/boş yuvada false.
- **Öğretici yalnızca tek kişilik ilk run'da çıkar.** İkizler (yerel/çevrim içi) run'ında çıkmaz, bayrak değişmez; ilk tek kişilik run'da çıkar. [CEO KARARI]
- Öğretici yarıda kapatılırsa (oyundan çıkış) bayrak yazılmaz; bir sonraki run'da yeniden çıkar.

### 14.2 Tekrar oynama [CEO KARARI]
- Gözlemevi'nde eğitim kuklasının yanına **ANTRENMAN / TRAINING** durağı: öğreticiyi "tekrar kipi"nde açar. Bu kipte run başlamaz, bayrak değişmez; bitince ya da atlanınca Gözlemevi'ne dönülür.
- Ayarlar'a düğme eklenmez.

### 14.3 Oda ve kurallar
- Tek, sade, yuvarlak gece arenası (lacivert-altın, Koç Geçidi'nin görünüşü olabilir ama **tehlike yok, müzik sakin**). Kahraman seçtiği silahla girer (ilk run'da Yıldız Kılıcı).
- **Ölüm yok, can azalmaz:** öğretici düşmanlarının hasarı 0 (`dmg_mult = 0`). İsabet yine hissedilir (kızıl kenar, sarsıntı) ve ekranda "tekrar dene" ipucu çıkar. Kahramanın `died` sinyali bağlanmaz; can her adım başında tam.
- Öğreticide toz düşmez, almanak/sayaçlar (öldürme) yazılmaz, run anlık kaydı alınmaz. (Parry başarımı "Savuşturma" açılabilir; sorun değil.)
- HUD: can çubuğu ve yetenek çubuğu görünür; "ODA x/y", dalga, element, ödül yazıları ve ilk 15 sn'lik kontrol satırı **gizli**.
- **Öğretici düşmanı:** Gölge rolünde, bölgesi `"tutorial"` (bölge varyantı yok), seçkin değil, özelliksiz; hareket hızı ×0,6, hazırlık süresi ×1,8 (parry adımında ×2), seri 1, can düşük (2–3 vuruşta ölür). O adımda yalnızca öğretilen türden saldırı yapar (yalnız altın ya da yalnız kızıl).
- Her adım: üst-ortada kısa başlık + tek satır talimat + **tuş rozeti** (§14.5). Başarınca altın parıltı + "Güzel!" (0,8 sn) ve sıradaki adım. Bir adımda 20 sn ilerleme olmazsa talimat yanıp söner ve ek ipucu satırı çıkar.
- Sağ üst köşede küçük "Esc: atla" yazısı (kipe göre: Start / II).

### 14.4 Adımlar (sırayla; her biri tek şey öğretir)

| # | Öğretilen | Ne olur | Başarı koşulu |
|---|---|---|---|
| 0 | Giriş | "HOŞ GELDİN, YOLCU" kartı (2,5 sn) | süre dolar |
| 1 | Hareket | yerde altın halka belirir | halkanın içine girmek |
| 2 | Saldırı kombosu | ortada eğitim kuklası | **kombonun 3. vuruşu (bitirici, kombo sırası 2) kuklaya isabet eder** (aşağıdaki kural) |
| 3 | Ağır saldırı | aynı kukla | kuklaya **ağır** vuruş isabeti |
| 4 | Atılma | öğretici Gölge yalnızca **kızıl** yırtma yapar, bu adımda ölmez | 2 kez kızıl saldırıyı **atılarak** boşa çıkarmak (aşağıdaki kural). Yürüyerek kaçmak sayılmaz. Sonra Gölge yıldız tozuna dağılır. |
| 5 | Koşu | arenanın öbür ucunda halka | toplam 1,5 sn koşarak (Boşluk basılı) halkaya varmak |
| 6 | Parry | öğretici Gölge yalnızca **altın** pençe yapar | 3 başarılı parry. Her parry'den sonra "Karşıladın! Sersemledi — şimdi vur" ; 3. parry'den sonra Gölge'yi öldürmek |
| 7 | Yetenekler Q / E / R | kukla(lar); üç yeteneğin adı ekranda | üç yeteneğin her birini en az bir kez kullanmak (sırası serbest; kullanılan yetenek listede altınla işaretlenir) |
| 8 | Kısa prova [CEO KARARI] | 2 öğretici Gölge, iki saldırı türü de açık, hasar yok | ikisini de yenmek |
| 9 | Etkileşim / kapı | tek altın kapı açılır (Koç simgesi), HUD kapı ipucu | kapıya yaklaşıp etkileşim tuşu → "ÖĞRETİCİ TAMAM", bayrak yazılır, Koç Geçidi 1. oda |

- **Adım 2 sağlam tanımı:** zaman penceresi yok. `hero.gd` `_start_attack` içinde `last_combo_idx = _combo_i` saklanır (ağırda −1). Kukla `hit_taken` aldığında `last_atk_kind == "combo"` ve `last_combo_idx == 2` ise adım biter. 2. sıraya varmak 0 ve 1 vuruşlarının aynı zincirde yapılmasını gerektirir; zincir yalnızca 0,45 sn boşta kalınca sıfırlanır. Bu yüzden hitstop (`time_scale` 0,03) ve bitiricinin uzun hazırlığı koşulu etkilemez.
  - Yedek koşul: bitirici kuklayı ıskalarsa, kuklaya **oyun zamanıyla 2,0 sn** içinde 3 kombo isabeti de adımı bitirir.
  - İlerleme göstergesi: "1/3, 2/3, 3/3" = zincirdeki son isabetin sırası + 1.
- **Adım 4 sağlam tanımı:** `dodged` sinyali tek başına yetmez; oyuncu atılarak menzilden çıkarsa saldırı kahramana hiç ulaşmaz ve sayılmaz. Yeni kural: öğretici Gölge'nin her kızıl saldırısı bitince (`act` sonu) tutorial şuna bakar:
  - (a) Saldırı kahramanı vurmadı (`hurt` gelmedi).
  - (b) Kahraman, o saldırının hazırlık başlangıcından `act` sonuna kadarki aralıkta en az bir kez atıldı (`hero.dash_started` zamanı aralık içinde) ya da `dodged` geldi.
  - (a) ve (b) birlikte sağlanıyorsa 1 başarı.
  - Uygulama: `enemy.gd`'ye yalnızca `zone == "tutorial"` iken yayınlanan `signal attack_done(parryable: bool, hit: bool)` ve `windup_t0`; `hero.gd`'ye `var last_dash_t` (oyun saati).
  - Gölge bu adımda ölmez (`tut_min_hp = 1`); saldırı menzili dışındaysa kahramana yürür, böylece her 4–5 sn'de bir kızıl saldırı gelir. Kızıl saldırı bekleme süresi bu adımda 2,5 sn'ye indirilir (rend `cd`), hazırlık ×1,8 kalır.
- Başarısızlık geri bildirimi: kızıl saldırıda vurulursa "Kızıl uyarı dolarken atıl"; altın saldırıda vurulursa "Altın uyarı dolarken bas". Hata sayılmaz, adım sürer.
- Atılma bekleme süresi (3 sn) 4. adımda HUD'daki dolan halkayla gösterilir; talimat altında "Atılma dolunca tekrar kullanılır" ipucu.
- **Parry penceresi yalnızca öğreticide 2 katıdır** (0,17 sn → 0,34 sn); run'da normal değer geçerlidir. [CEO KARARI]

### 14.5 Tuş metinleri: fare/klavye, kontrolcü, dokunmatik
- Kural: talimattaki tuş rozeti **her karede** `GameData.input_mode`'a göre seçilir (`mouse` / `pad` / `touch`); oyuncu giriş değiştirince anında güncellenir. Mevcut HUD (`combat_hud.gd _draw_slots`, ilk 15 sn ipucu) aynı yöntemi kullanıyor.
- Dokunmatikte rozet yerine **ilgili ekran düğmesinin etrafında parlayan altın halka** gösterilir (düğme konumu `touch_controls.gd` içindeki `_buttons` listesinden eylem adıyla bulunur); metin yine üst-ortada.
- Kontrolcü/fare kipinde HUD yetenek çubuğunda o adımın slotu (Q/E/R, RMB, SPACE, SHIFT) parlar.

| Eylem | mouse | pad | touch |
|---|---|---|---|
| hareket | WASD | Left stick → Sol çubuk | Drag on the left side → Sol tarafta sürükle |
| saldırı | Left click → Sol tık | X | Tap the right side → Sağ tarafa dokun |
| ağır | Right click → Sağ tık | Y | HEAVY button → AĞIR düğmesi |
| atılma | Space → Boşluk | A | Double tap or » → Çift dokun ya da » |
| koşu | Hold Space → Boşluğu basılı tut | LT | Push the stick all the way → Çubuğu sonuna kadar it |
| parry | Shift | B | PARRY button → PARRY düğmesi |
| yetenekler | Q · E · R | LB · RB · RT | Skill buttons, drag to aim → Yetenek düğmeleri, sürükleyip nişan al |
| etkileşim | E | X | USE button → KULLAN düğmesi |
| atla (duraklat) | Esc | Start | II |

### 14.6 Atlama
- Duraklat menüsü (mevcut `pause_ui.gd`) öğreticide "Gözlemevine dön" yerine **"SKIP TUTORIAL / ÖĞRETİCİYİ ATLA"** düğmesini gösterir. Basınca: bayrak yazılır, doğrudan Koç Geçidi 1. odaya geçilir (tekrar kipinde Gözlemevi'ne). Onay sorusu yok.
- Devam / Ayarlar / Oyundan çık düğmeleri aynen kalır.

### 14.7 Metinler (loc.gd: İngilizce anahtar → Türkçe)

| İngilizce (kod) | Türkçe |
|---|---|
| WELCOME, TRAVELER | HOŞ GELDİN, YOLCU |
| First, learn the ways of the stars | Önce yıldızların yolunu öğren |
| MOVE | YÜRÜ |
| Walk into the golden circle | Altın halkanın içine yürü |
| ATTACK | SALDIR |
| Strike the star stone three times in a row | Yıldız taşına art arda üç kez vur |
| HEAVY ATTACK | AĞIR SALDIRI |
| A heavy blow hits everything around you | Ağır darbe çevrendeki her şeye vurur |
| DASH | ATIL |
| Red warning: you can't block it. Dash through! | Kızıl uyarı: karşılayamazsın. Atıl! |
| Dash as the red warning fills | Kızıl uyarı dolarken atıl |
| Dash recharges when the ring fills | Atılma, halka dolunca yeniden hazır |
| SPRINT | KOŞ |
| Hold to sprint to the far circle | Basılı tutup uzaktaki halkaya koş |
| PARRY | PARRY |
| Gold warning: meet the blow with a parry | Altın uyarı: darbeyi parry ile karşıla |
| Press as the gold warning fills | Altın uyarı dolarken bas |
| Parried! It's stunned — strike now | Karşıladın! Sersemledi — şimdi vur |
| STAR SKILLS | YILDIZ YETENEKLERİ |
| Use all three skills | Üç yeteneği de kullan |
| PRACTICE | PROVA |
| Defeat both shades | İki gölgeyi de yen |
| THE GATE | KAPI |
| Step through the gate. Your journey begins | Kapıdan geç. Yolculuğun başlıyor |
| Nice! | Güzel! |
| They can't hurt you here. Try again. | Burada sana zarar veremezler. Tekrar dene. |
| TUTORIAL COMPLETE | ÖĞRETİCİ TAMAM |
| SKIP TUTORIAL | ÖĞRETİCİYİ ATLA |
| %s: skip | %s: atla |
| TRAINING | ANTRENMAN |
| Left click / Right click / Space / Hold Space / Left stick … (§14.5 tablosu) | §14.5'teki Türkçe karşılıklar |

## 15. Denge hedefleri

**İlke (CEO):** "Roguelike gibi olmalı, çok kolay bir şey varsa zorlaştırılmalı ama insanı sıkmaması lazım."

### 15.1 Zorluk eğrisi
- **Koç–İkizler (öğrenme alanı):** ilk run'da yeni oyuncu en az Koç Geçidi'nin 3–4. odasına ulaşmalı; Koç ilk 1–3 run içinde yenilebilmeli.
- **Yengeç'ten itibaren kademeli artış:** her bölge bir öncekinden hissedilir biçimde ama **küçük adımlarla** zorlaşır. Bölge içinde oda 1 → oda 4 hafif artar.
- **Boss bölgenin zirvesidir:** bölgenin en zor anı boss olmalı; boss'tan sonraki bölgenin 1. odası boss'tan kolay olmalı (nefes payı).
- Kalıcı gelişim (Doğum Haritası, silahlar, mühürler) ve retrolar oyuncuya zorluğu kendi ayarlama imkânı verir.

### 15.2 Ölçülebilir hedefler (Testçi ölçer; sayılar hedeftir, karar değil)

| Bölge grubu | Dövüş odası süresi | Oda başına can kaybı | Boss süresi | Boss'ta can kaybı |
|---|---|---|---|---|
| Koç – İkizler | 25–50 sn | %0–15 | 60–120 sn | %20–50 |
| Yengeç – Başak | 35–65 sn | %5–20 | 90–150 sn | %25–55 |
| Terazi – Yay | 45–75 sn | %10–25 | 120–180 sn | %30–60 |
| Oğlak – Balık | 50–90 sn | %10–30 | 150–240 sn | %35–65 |

- Ölçüm koşulu: Yıldız Kılıcı, retro kapalı, döngü 0, tek oyuncu, o bölgeye kadar run içinde ortalama lütuf seçimi.
- Bir dalga ile sonraki arasındaki boşluk 1,2 sn (mevcut) yeterli kabul; oda süresinin çoğu dövüşte geçmeli.

### 15.3 "Sıkmaması" için kurallar
1. **Ani sıçrama yok:** ardışık iki odada düşman etkin hasarı ya da canı %20'den fazla artmaz; bölge geçişinde de aynı kural.
2. **Ölüm adil olmalı:** her saldırı okunur (altın ya da kızıl uyarı, ses); hiçbir ölümcül saldırı uyarısız gelmez. Ekran dışından uyarısız mermi gelmez.
3. **Tek vuruşta ölüm yok:** normal düşmanın tek saldırısı yeni profil canının ≤ %30'u (§13.8, kendi değerleriyle; mekanik tavan yok). Boss'ların büyük vuruşları kendi değerleriyle ayarlanır (§13.4).
4. **Kalabalık sınırı:** aynı anda saldıran düşman sınırı (2/3) korunur; ekranda aynı anda okunması gereken kızıl uyarı sayısı sınırlı kalır.
5. **İlerleme hissi:** her ölüm sonrası harcanacak toz olmalı; ilk saatte en az bir silah ve birkaç harita yıldızı açılabilmeli.
6. **Tekrar sıkıcılığı:** aynı bölgedeki 4 dövüş odası farklı dalga dizilimleri sunar; ileri bölgelerde karışık gruplar çeşitlilik verir.

### 15.4 Ayar noktaları (zorluğu belirleyen yerler) [KOD]

| Dosya / yer | Ne ayarlar |
|---|---|
| `room.gd` `BOSS_DEPTH = 4`, `ZONE_START`, `LAST_DEPTH = 59` | bölge başına oda sayısı, bölge sırası |
| `room.gd` `COMBAT`, `COMBAT_T/_G/_C/_L/_V/_B/_S/_Y/_K/_Q/_P` | her bölgede oda başına dalga sayısı ve düşman dizilimi |
| `room.gd` `HP_MULT*`, `DMG_MULT*`, `ELITE_CHANCE*` (bölge başına 4 değer, oda 1–4) | düşman canı, hasarı, seçkin ihtimali. Koç 1,0–1,4 / 1,0–1,3 → Balık 3,85–4,4 / 4,3–4,7 |
| `room.gd _spawn_enemy` | seçkin hesabı (+%15/Ay Tutulması kademesi, +%10/döngü), 1. odada seçkin yok, seçkin özellik sayısı; yeni: oda başı seçkin sınırı ve özellik kuralı (§13.3) |
| `room.gd _tune_enemy` | retro çarpanları, Aslan yükseleni ×1,15 can, co-op ×1,5 can, Plüton hazırlık |
| `room.gd HAZARD_EVERY`, `HAZARD_DMG`, `_tick_hazards` | tehlike sıklığı (yeni değerler §13.5), hasarı (×1,0 → ×2,55, oda başına +%12), ilk iki odada kapalı |
| `room.gd _spawn_doors` | Sığınak/ustalık/toz kapısı olasılıkları |
| `room.gd` iyileşmeler | Sığınak %40, bölge geçişi %30, döngü geçişi %50 |
| `room.gd _spawn_boss`, `_cyc_hp/_cyc_dmg` | boss retro/döngü/co-op çarpanları; döngü +%40 can / +%20 hasar |
| `room.gd BOSS_HP`, `BOSS_DMG` (yeni, §13.4); `*_boss.gd` `max_hp` (eski) | boss canları (Koç 1400 … Balık 6000) ve boss hasar çarpanı |
| `enemy.gd TIER` (yeni, §13.1) | öğrenme/geçiş kademeleri |
| `enemy.gd _setup_kind` | rol başına taban can, hasar, hazırlık, bekleme |
| `enemy.gd _ready` (zorluk bloğu) | seçkin ×1,6 can ×1,25 hasar, hız ×1,06, seri uzunlukları, öğrenme alanı çarpanları |
| `enemy.gd _early()` | öğrenme alanı bölgeleri (Koç, Boğa, İkizler) |
| `enemy.gd _attack_slots_full()` | aynı anda saldıran sınırı (2 / 3) |
| `hero.gd` `BASE_HP = 100`, `PARRY_WINDOW = 0.17`, `PARRY_COOLDOWN = 0.5`, `DASH_COOLDOWN = 3.0`, `SPRINT_MULT = 1.6` | kahraman temel değerleri |
| `hero.gd take_damage` | vurulduktan sonra 0,6 sn dokunulmazlık, zırh formülü 50/(50+zırh) |
| `retro.gd CURSES` | isteğe bağlı zorluk lanetleri |

### 15.5 Testçi ölçümleri (1038b6e) ve durum
- İkizler ~12 → Yengeç ~20 baskı/sn (+%65); Başak ~31 → Terazi ~48 (+%55); Akrep–Kova ~54–69 düz; Balık ~72 → **§13.1–13.2 ile çözülür.**
- `_early()` düşmanın kendi bölgesine bakıyor (T-04) → **§13.1 (odanın bölgesi).**
- Boss canı İkizler > Yengeç, Terazi > Akrep = Yay; boss canı Koç→Balık ×2,7 iken oda düşmanı canı ×3,85, hasarı ×4,3; Aslan sonrası boss süreleri 31–47 sn düz; Balık baskısı Kova'dan düşük (T-06) → **§13.4.**
- İleri bölgelerde ilk odadan %50–60 seçkin, iki özellik; Akrep 1. odada 3 seçkin (T-03) → **§13.3.**
- Tehlike sıklığı Terazi 12 sn → Akrep 6,5 sn → **§13.5.**
- **Tek vuruş riski** (T-33/T-34: ilk odalarda canın %56–66'sı) → **§13.8 (CEO kararı).**
- Aslan–Balık dalga tabloları neredeyse aynı (T-07) → bu turda kapsam dışı; §17'de öneri.

### 15.6 Değişiklik önerileri
| # | Öneri | Durum |
|---|---|---|
| D1 | Yengeç geçiş bölgesi, tam kurallar sonra | **[CEO KARARI]** → §13.1 (Yengeç + Aslan iki kademe) |
| D2 | `_early()` odanın bölgesine baksın | **[CEO KARARI]** → §13.1 |
| D3 | Tehlike aralıkları yumuşasın | **[CEO KARARI]** → §13.5 (D3'ten daha yumuşak değerler) |
| D4 | İlk 3 bölgede seçkinler tek özellik | **[CEO KARARI]** → §13.3 |
| D5 | Tek vuruş tavanı (mekanik) | **İptal [CEO KARARI]:** genel tavan yok; yerine §13.8 (saldırı değerleri) |
| D6 | `BASE_HP` (100) ve `DASH_COOLDOWN` (3 sn) ölçüme kadar değişmesin; Koç–İkizler oda can kaybı %15'i aşarsa önce `DASH_COOLDOWN` 2,5 sn denensin | [ÖNERİ – Analist; CEO'ya sorulmadı, uygulanmayacak] |
| D7 | Öğreticide parry penceresi ×2 | **[CEO KARARI]** → §14.4 |

### 15.7 Denge ölçüm standardı [Yönetici kararı, test standardı]
Bütün denge ölçümleri bu profillerle, profil başına **3 tekrar**la yapılır; sonuç ortalama ve en düşük/en yüksek değerle verilir. Ölçüt **ham baskı/sn**: kahramana gelen saldırıların savunmadan (zırh, kaçınma, kalkan, parry) arındırılmış toplam hasarı / dövüş süresi. Ayrıca oda süresi, can kaybı ve boss süresi ölçülür.

| Profil | Doğum Haritası | Tılsım / mühür | Run içi lütuf sayısı | Kaçınma varsayımı (bot) |
|---|---|---|---|---|
| **Yeni** | 0 toz (boş) | yok | ≈ 2,55 × bölge sırası (Koç 1 → Balık 12) | %30 |
| **Orta** | 5 bin toz | Yeni Ay (newmoon) tılsımı seviye 2 | ≈ 2,55 × bölge sırası | %50 |
| **Deneyimli** | 30 bin toz | Tutulma (eclipse) tılsımı seviye 3 + Başak mührü seviye 3 | ≈ 2,55 × bölge sırası | %70 |

- Silah Yıldız Kılıcı, retro kapalı, döngü 0, tek oyuncu (§15.2'deki koşul).
- Bölge karşılaştırması bölgenin 1. odasıyla yapılır; Koç muaf (§13.2).
- Boss eğrisi (`BOSS_DMG`) yeni profille ölçülür.
- Ayna Muhafızı yansımaları en büyük 5 vuruş listesinde ayrı kaynak olarak görünür ("mirror yansıması"); §13.8 kuralına tabi değildir (CEO, T-42).
- **Her ölçüm turunda tek vuruş kontrolü:** her profil için turun **en büyük 5 vuruşu** listelenir: kaynak düşman (bölge, rol, seçkin/özellik, karışık mı, boss odası mı), saldırı adı, hasar, kahramanın en yüksek canına oranı. Yeni profilde normal düşman vuruşu %30'u aşarsa bulgu açılır (§13.8).
- Yarım harita (~506 bin toz) yalnızca azalan getiri (§13.7) kontrolü için kullanılır.

## 16. Görsel dil

- **Renkler:** koyu lacivert gece göğü + altın sarısı; ikinci ışık dolunayın soğuk beyazı. Uyarılar: altın-turuncu = parry, kızıl = kaç; düşman doğuşu mor halka.
- **Yaratıklar:** altından heykeller; bozulanlar çatlamış altın, çatlaklardan kara boşluk ve yıldız tozu sızar.
- **Kan yok:** altın kırıkları ve parlayan yıldız tozu; kopan uzuvlar ışık saçarak dağılır.
- **Dolunay** her bölümün göğünde; boss ölümünde burcun takımyıldızı göğe çizilir.
- **Yazılar:** Cinzel benzeri oymalı serif altın yazı. **Arayüz:** ince altın çerçeveler, burç sembolleri.

## 17. Yol haritası

| # | Adım | Durum |
|---|---|---|
| 1 | Tasarım belgesi | ✅ 0.5 |
| 2 | Görsel dönüşüm, menü, Gözlemevi | ✅ |
| 3 | Yakın dövüş çekirdeği (kombo, ağır, atılma, koşu, parry, Q/E/R) | ✅ |
| 4 | 4 düşman rolü × 12 bölge varyantı, seçkinler | ✅ |
| 5 | Oda/kapı sistemi, Sığınak, 12 bölge × 5 oda | ✅ |
| 6 | Gezegen lütufları, ikili lütuflar, silah ustalıkları | ✅ |
| 7 | 12 boss (Koç → Balık) ve final | ✅ |
| 8 | Doğum Haritası, Silah Sunağı (6 silah), Gök Kadranı (retrolar) | ✅ |
| 9 | Ay Ana, Satürn, Almanak, yoldaşlar, yükselenler, başarımlar | ✅ |
| 10 | Sonsuz Gökyüzü (NG+) | ✅ |
| 11 | İkizler: yerel ve çevrim içi co-op | ✅ |
| 12 | Ayarlar, duraklatma, TR/EN, 3 kayıt yuvası, dokunmatik ve kontrolcü | ✅ |
| 13 | **Öğretici Oda** (§14) | ⏳ |
| 14 | **Denge ölçümü ve ayarı** (§13, §15) | ⏳ |
| 15 | **Rehberlik** (§19) | ⏳ |
| 16 | **Proje adı ve kayıt taşıma** (§20) | ⏳ |
| 17 | Arayüz ve kod hataları (§21) | ⏳ |
| 17a | Boss evre alt süresi (§13.6), Doğum Haritası azalan getiri (§13.7), F tuşu (§8) | ⏳ |
| 18 | [ÖNERİ – CEO onayı gerekir] **Aslan–Balık dalga tablolarını ayrıştır** (T-07): bugün `COMBAT_L` … `COMBAT_P` neredeyse aynı. Her bölgeye kendi imzasını veren dizilim (ör. Akrep'te taklitçi/iğneci ağırlıklı, Yay'da okçu ağırlıklı, Kova'da hava yaratıkları) ve son odada bölgenin "elit dalgası". Bu turda kapsam dışı. | öneri |

## 18. Açık sorular

1. Ana karakter kim?
2. İkincil uzak atış olsun mu? (Kentaur Yayı kısmen karşılıyor.)
3. Tam run (60 oda) tahminen 80–100 dk sürer; Hades'te bir run ~30–45 dk. Bölge başına oda sayısı ya da ara dönüş noktaları düşünülmeli mi?
4. D6 (§15.6), Testçi'nin yeni ölçümlerinden sonra.

## 19. Rehberlik [CEO KARARI]

> OYN-01/02: Gözlemevi'nde ilk girişte yönlendirme yok; element, seçkin özellikleri, ödül simgeleri ve duraklar hiç öğretilmiyor. Dört rehberlik parçasının hepsi yapılır.
> Ortak kural: her ipucu **yuva başına bir kez** gösterilir. Yeni kayıt alanı: `GameData.hints: Dictionary` (`[rehber] seen`), anahtar → true. Eski kayıtlarda ilerleme varsa (`tutorial_done` ile aynı kural, §14.1) a ve c işaretleri görülmüş sayılır; b ve d her yuvada bir kez çıkabilir. Metinler kipe göre tuş içerir (§14.5 kuralı). Hiçbir ipucu oyunu durdurmaz; dövüşte kart ekranın sağ ortasında, can çubuğu ve yetenek çubuğunun üstüne binmeden durur.

### 19.1 (a) Gözlemevi ilk giriş
- `hints["hub_intro"]` yoksa: kahramanın ayağından **Kapı**'ya (portal) uzanan, yerde akan altın ışık izi (noktalı yıldız tozu, 1 sn'de bir ileri akar) ve ekranın üst ortasında tek satır hedef.
- İz ve satır, oyuncu Kapı'yı kullanınca (yükselen ekranı açılınca) kaybolur; `hub_intro` o anda yazılır.
- **Durak işaretleri:** her durağın (Doğum Haritası, Silah Sunağı, Gök Kadranı, Ay Ana, Satürn, Almanak, Antrenman, Kapı) üstünde, o durak **ilk kez kullanılana kadar** yavaşça nabız atan küçük altın ✦ işareti. Anahtar: `hints["station:<TITLE>"]` (ör. `station:BIRTH CHART`). İşaret yalnızca 1. ilk girişte değil, durak açılana kadar her girişte görünür.

| EN | TR |
|---|---|
| Step through THE GATE to begin your journey | Yolculuğa başlamak için KAPI'dan geç |

### 19.2 (b) Element ve seçkin özellikleri: bir kerelik açıklama kartı
- **Element:** HUD'da GÜÇLÜ ya da ZAYIF satırı ilk kez göründüğünde (`Elements.mult != 1`), 7 sn'lik kart (`hints["elements"]`).
- **Seçkin özelliği:** bir özellik (shielded, swift, splitting, healer, volatile, phantom) ilk kez doğan bir düşmanda göründüğünde o özelliğin kartı, 6 sn (`hints["affix:<id>"]`). Aynı anda iki yeni özellik varsa kartlar sırayla gelir.
- Kart: başlık + tek satır + özellik renginde ince çerçeve (`enemy.gd AFFIX_COLS`).

| Anahtar | EN başlık · metin | TR başlık · metin |
|---|---|---|
| elements | ELEMENTS · Water beats Fire, Fire beats Air, Air beats Earth, Earth beats Water. Your blessings set your element. | ELEMENTLER · Su Ateşi, Ateş Havayı, Hava Toprağı, Toprak Suyu yener. Elementini lütufların belirler. |
| shielded | SHIELDED · A ward absorbs damage first. Break it, then strike. | KALKANLI · Önce kalkan hasarı emer. Kır, sonra vur. |
| swift | SWIFT · Faster and quicker to attack. Watch its warnings closely. | HIZLI · Daha hızlı yürür ve saldırır. Uyarılarını yakından izle. |
| splitting | SPLITTING · Splits into two small copies when it dies. | BÖLÜNEN · Ölünce iki küçük kopyaya bölünür. |
| healer | HEALER · Heals nearby foes. Take it down first. | ŞİFACI · Yakındakileri iyileştirir. Önce onu indir. |
| volatile | VOLATILE · Explodes after death. Step out of the ring. | PATLAYAN · Öldükten sonra patlar. Halkadan çık. |
| phantom | PHANTOM · Turns invisible while it hunts you. | HAYALET · Seni kovalarken görünmez olur. |

### 19.3 (c) İlk kapı seçimi ve ödül adı
- Run'da kapılar **ilk kez** çıktığında (`hints["doors"]` yoksa) kapıların üstünde tek satır ipucu, kapı seçilince yazılır.
- **HUD ödül göstergesi (her zaman):** sağ üstteki "ÖDÜL" yazısı ve simgenin altına ödülün adı yazılır: gezegen lütfunda `%s LÜTFU` (ör. MARS LÜTFU), ustalıkta SİLAH USTALIĞI, tozda YILDIZ TOZU, Sığınak'ta SIĞINAK. Mevcut metin anahtarları kullanılır (`BLESSING OF %s`, `WEAPON MASTERY`, `STARDUST`, `SANCTUARY`).
- Kapı madalyonu: kapıya yaklaşınca (ipucu kutusu) zaten adı yazıyor; değişmez.

| EN | TR |
|---|---|
| Each gate's symbol shows its reward. Choose your path. | Her kapının simgesi ödülünü gösterir. Yolunu seç. |

### 19.4 (d) İlk ölümden sonra Doğum Haritası
- İlk ölümde (`hints["first_death"]` yoksa) ölüm ekranı ("THE STARS DIM") mevcut haliyle gösterilir; Gözlemevi'ne dönünce, **yıldız tozu ≥ en ucuz harita yıldızının fiyatı** ise ekranın üst ortasında kart + **"DOĞUM HARİTASINI AÇ"** düğmesi (kontrolcüde odaklı, dokunmatikte dokunulur). Düğme Doğum Haritası'nı açar (`hub.gd _open_skill_tree`); kart 12 sn sonra ya da harita açılınca kapanır. Ayrıca Doğum Haritası durağına (a)'daki gibi ışık izi çizilir.
- Toz yetmiyorsa kart yine çıkar ama düğme yerine ışık izi yeterli. `first_death` kart gösterilince yazılır.

| EN | TR |
|---|---|
| You fell, but the stars remember. Light a star in your Birth Chart. | Düştün ama yıldızlar unutmaz. Doğum Haritanda bir yıldız yak. |
| OPEN BIRTH CHART | DOĞUM HARİTASINI AÇ |

## 20. Proje adı ve kayıt taşıma [CEO KARARI]

- `project.godot`: `config/name="BeyondTheEye"` (T-17). Pencere/ürün adı dışa aktarmada zaten "Beyond The Eye"; Android paket adı `com.bogacavdar.beyondtheeye` **değişmez**.
- Masaüstünde (Windows/Linux/macOS) `user://` proje adına bağlıdır: eski klasör `…/Godot/app_userdata/NeonZombie`, yeni klasör `…/Godot/app_userdata/BeyondTheEye`. **Hiç kimse ilerleme kaybetmez:**
  1. Taşıma, `user://`'dan ilk okumadan **önce** çalışır: `GameData.go_load()` başında `_migrate_user_dir()` (ve eski zombi kaydını okuyan `load_game()` başında).
  2. Eski klasör = `OS.get_user_data_dir().get_base_dir().path_join("NeonZombie")`. Yoksa ya da yeni klasör eskiyle aynıysa hiçbir şey yapılmaz.
  3. Yeni klasörde `migrated_from_neonzombie` işaret dosyası varsa hiçbir şey yapılmaz (bir kez çalışır).
  4. Eski klasörün **kökündeki bütün dosyalar** yeni klasöre **kopyalanır** (taşınmaz): en az `beyond_the_eye_settings.cfg`, `beyond_the_eye_slot1..3.cfg`, `beyond_the_eye_v2.cfg`, `beyond_the_eye.cfg`, `kayit.cfg`. Yeni klasörde aynı adlı dosya **varsa üzerine yazılmaz**. Godot'nun kendi alt klasörleri (`shader_cache`, `vulkan` vb.) kopyalanmaz.
  5. Kopya başarılıysa işaret dosyası yazılır (içinde tarih ve kopyalanan dosya listesi). Bir dosya kopyalanamazsa işaret yazılmaz; bir sonraki açılışta yeniden denenir. Eski klasör yedek olarak kalır, silinmez.
- Web'de `user://` tarayıcı deposundadır, Android'de paket adına bağlıdır; taşıma kodu orada da zararsız çalışır (eski klasör bulunamaz). Testçi masaüstünde eski klasörle, web ve Android'de mevcut kayıtla doğrular.
- Belgedeki "proje klasörü NeonZombie" notu ve Steam/dışa aktarma adları bu değişiklikten etkilenmez.

## 21. Arayüz ve kod hataları: kurallar (CEO kararı gerekmez)

| Bulgu | Kural (Yazılımcı uygular) |
|---|---|
| **T-09** bilinmeyen silah kimliği | Silah kimliği her girişte doğrulanır: `GameData._load_slot` ve `resume_run` içinde `chosen_weapon` STAR_WEAPONS'ta yoksa **ya da** `weapons_open`'da yoksa → `"STAR SWORD"`; `weapons_open` listesinden bilinmeyen kimlikler atılır, liste boşsa `["STAR SWORD"]`. `hero.equip(id)` geçersiz kimlik alırsa `"STAR SWORD"` kullanır ve `weapon_id`'yi de ona eşitler (kit ile kimlik hep aynı). Kural: silah lütufları geçerli kimlikle çıkmaya devam eder. |
| **T-14** Gözlemevi "[ E ]" sabit | `hub.gd act_label` giriş kipine göre: `mouse` → `[ E ]`, `pad` → `[ X ]`, `touch` → yazı yok, yalnız durak adı (KULLAN düğmesi var). Aynı kural `combat_hud.gd _draw_prompt` için: kutudaki tuş `E` / `X` / (dokunmatikte tuş kutusu çizilmez). |
| **T-15** telefonda kapı (yüksek) | `touch_controls.gd`: KULLAN (`interact`) düğmesi dövüş odasında da var, ama yalnızca etkileşim menzilinde (kapı yakınında; `hud.prompt != ""`) görünür ve dokunulabilir. Konumu Gözlemevi'ndekiyle aynı (sağ üst, atılmanın üstü). Gözlemevi'nde her zaman görünür. |
| **T-16** dokunmatik etiketleri | Ağır saldırı düğmesinde "Q" yerine HUD'daki ağır saldırı simgesi + altında AĞIR; yetenek düğmelerinde "1/2/3" yerine o yeteneğin HUD simgesi (`combat_hud._icon` ile aynı çizim, kit `type`'ına göre), altında yetenek adı (zaten var). |
| **T-18** boss isim kartı portresi | Kart süresince (≈3 sn) sol üst HUD yazıları (toz, element) ve boss çubuğu gizlenir (can çubuğu kalır). Portre şeridin içinde durur: şerit yüksekliği portreye göre büyür (1080p'de 320 px), portrenin üst ve alt kenarı şeridin kenarlarına hizalı, üst kenar ≥ 150 px (can çubuğunun altı), sol kenar ≥ 440 px. Değerler 1080p içindir, ekran yüksekliğiyle ölçeklenir. |
| **T-20** üst üste binen seçkin etiketleri | Seçkin etiketi kısa: yalnızca özellik adları, en fazla 2, `·` ile. Ekranda iki etiket birbirine 70 px'ten yakınsa kahramana uzak olanın etiketi gizlenir (halesi kalır). Etiket yazısına koyu dış çizgi (outline ≥ 12) ve hafif koyu zemin. |
| **T-29** kapı ipucu ve dokunmatik çakışmaları | (1) Oda temizlenince "DALGA x/y" yazısı gizlenir. İlk kapı ipucu satırı (§19.3) ODA şeridinin altında, 1080p'de üstten ≥ 120 px'te durur; başka HUD yazısıyla kesişmez. (2) Dokunmatikte, kapılar çıkmışken ve odada canlı düşman yokken saldırı yayı (ağır, 3 yetenek, parry) %25 saydamlığa iner ve dokunuşu almaz; çubuk, atılma, KULLAN ve duraklat kalır. Yeni düşman doğarsa (boss yardımcıları vb.) yay geri gelir. (3) Dokunmatik düğme alt etiketi en fazla `2r + 16` px genişlikte: sığmazsa yazı boyutu en az 14'e küçülür, yine sığmazsa iki satıra bölünür (TR "TAKIMYILDIZI ADIMI" dahil). Etiketler komşu düğmenin dairesine binmez. |
| **OYN-14** Gözlemevi tuş satırı | Gözlemevi sol üstündeki tuş ipucu satırının arkasına, DALGA/ODA yazılarındaki gibi koyu yarı saydam şerit (kontrast ≥ 4,5:1). |
| **T-21** simge ve okunabilirlik | (1) **AĞIR SALDIRI** simgesi güneş ışını olmaz: aşağı inen kalın ok + yer çizgisi ("çakma"). **TAÇ** (Güneş Gürzü, `aura`) için halka içinde nokta (hale) kullanılır; `cone/burst_self/aura` ortak simgesi ayrılır. Kural: yetenek çubuğunda iki slot aynı simgeyi taşımaz. (2) "DALGA x/y" ve "ODA x/y" yazılarının arkasına koyu yarı saydam şerit (Kova gibi parlak arenalarda okunur; kontrast ≥ 4,5:1). (3) Ödül göstergesinde simgenin altında ödülün adı (§19.3); "ÖDÜL" yazısı kalır. ♂ gibi gezegen simgeleri anlamsız değil (ödül gezegenini gösterir) ama adsız okunmuyordu; adla birlikte doğru kullanım. |

---

## Geçmiş: ilk prototip (NeonZombie)

Proje izometrik, neon cyberpunk bir zombi/mutant shooter olarak başladı (Vampire Survivors tarzı dalga hayatta kalma, 8 ateşli silah, şehir haritası, Kovan Anası boss'u). Oradan yeni oyuna taşınanlar: vuruş hissi sistemi, uzuv koparma, prosedürel yaratık yapımı, izometrik kamera, atılma, akış haritası, menü ve kayıt sistemi, boss altyapısı.
