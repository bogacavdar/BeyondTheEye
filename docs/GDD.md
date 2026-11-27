# GÖZÜN ÖTESİ: Oyun Tasarım Belgesi (GDD)

> Sürüm: 0.5.1 · Son güncelleme: 27 Kasım 2026 (Testçi bulguları ve CEO denge/rehberlik kararları işlendi)
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
- **Seçkin:** altın haleli, can ×1,6, hasar ×1,25; run'ın 3. odasından sonra özellik alır (kalkanlı, hızlı, bölünen, şifacı, patlayan, hayalet). Sayı ve özellik sınırları §13.3.
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
  - F (ağır saldırı + etkileşim) için ayrı karar verilmedi; bu turda değişmez.
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

### 13.2 Oda hasar tabloları (`room.gd DMG_MULT_*`, oda 1–4)
Başak→Terazi sıçraması (T-05: +%55) ve ileri bölgelerdeki düzlük, tabloların yeniden yazılmasıyla düzelir. Ham çarpanlar bölgeden bölgeye düz artmaz, çünkü ileri bölge yaratıklarının kendi mekanikleri daha güçlü (Testçi ölçümü: Terazi'den sonra aynı çarpan ~%50 daha fazla baskı üretiyor). Hedef baskı eğrisi sütunda.

| Bölge | Eski DMG_MULT | **Yeni DMG_MULT** | Hedef baskı/sn (yaklaşık) |
|---|---|---|---|
| Koç | 1,0 · 1,1 · 1,2 · 1,3 | aynı | ölçülsün |
| Boğa | 1,3 · 1,38 · 1,46 · 1,55 | aynı | ölçülsün |
| İkizler | 1,6 · 1,68 · 1,76 · 1,85 | aynı | ~12 (ölçülen) |
| Yengeç | 1,9 · 1,98 · 2,06 · 2,15 | aynı (geçiş kademesi düşürür) | ~15–16 |
| Aslan | 2,2 · 2,3 · 2,4 · 2,5 | aynı (geçiş kademesi düşürür) | ~20 |
| Başak | 2,5 · 2,6 · 2,72 · 2,85 | **2,10 · 2,18 · 2,28 · 2,40** | ~26 |
| Terazi | 2,8 · 2,9 · 3,0 · 3,15 | **1,93 · 2,00 · 2,07 · 2,17** | ~33 |
| Akrep | 3,1 · 3,2 · 3,3 · 3,45 | **2,36 · 2,43 · 2,50 · 2,62** | ~41 |
| Yay | 3,4 · 3,5 · 3,6 · 3,75 | **2,82 · 2,90 · 2,99 · 3,11** | ~49 |
| Oğlak | 3,7 · 3,8 · 3,95 · 4,1 | **3,24 · 3,33 · 3,46 · 3,59** | ~56 |
| Kova | 4,0 · 4,1 · 4,25 · 4,4 | **3,64 · 3,73 · 3,87 · 4,00** | ~63 |
| Balık | 4,3 · 4,4 · 4,55 · 4,7 | aynı | ~72 (ölçülen) |

- HP tabloları (`HP_MULT_*`) bu turda değişmez.
- Kabul ölçütü (Testçi): ardışık iki bölgenin baskı/sn oranı ≤ 1,30 ve ≥ 1,00. Sapma ±%10'u aşarsa Yönetici bu tablodaki sayıları günceller.

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
- **Boss hasarı:** yeni `const BOSS_DMG := {"pisces": 1.6}` (diğerleri 1,0), `boss.dmg_mult` ile çarpılır. Gerekçe: Kova baskısı 54/sn iken final Balık 36/sn (T-06). Hedef: Balık ≥ Kova. Diğer boss'ların baskısı ölçülünce Yönetici tabloyu tamamlar.
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
- Koç'un ilk iki odasında seçkin yok (değişmez).
- Can odalar arası taşınır; iyileşme kaynakları: Sığınak (%40), bölge geçişi (%30), döngü geçişi (%50), lütuflar/harita/tılsımlar.

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
| 2 | Saldırı kombosu | ortada eğitim kuklası | kuklaya 1,5 sn içinde 3 isabet (3'lü kombo) |
| 3 | Ağır saldırı | aynı kukla | kuklaya **ağır** vuruş isabeti |
| 4 | Atılma | öğretici Gölge yalnızca **kızıl** yırtma yapar | 2 kez kızıl saldırıyı **atılarak** boşa çıkarmak (atılma i-frame'i sırasında gelen saldırı). Yürüyerek kaçmak sayılmaz. Sonra Gölge yıldız tozuna dağılır. |
| 5 | Koşu | arenanın öbür ucunda halka | toplam 1,5 sn koşarak (Boşluk basılı) halkaya varmak |
| 6 | Parry | öğretici Gölge yalnızca **altın** pençe yapar | 3 başarılı parry. Her parry'den sonra "Karşıladın! Sersemledi — şimdi vur" ; 3. parry'den sonra Gölge'yi öldürmek |
| 7 | Yetenekler Q / E / R | kukla(lar); üç yeteneğin adı ekranda | üç yeteneğin her birini en az bir kez kullanmak (sırası serbest; kullanılan yetenek listede altınla işaretlenir) |
| 8 | Kısa prova [CEO KARARI] | 2 öğretici Gölge, iki saldırı türü de açık, hasar yok | ikisini de yenmek |
| 9 | Etkileşim / kapı | tek altın kapı açılır (Koç simgesi), HUD kapı ipucu | kapıya yaklaşıp etkileşim tuşu → "ÖĞRETİCİ TAMAM", bayrak yazılır, Koç Geçidi 1. oda |

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
3. **Tek vuruşta ölüm yok:** tam candaki kahramanı tek bir normal düşman saldırısı öldürmemeli (hedef: tek vuruş ≤ beklenen en yüksek canın %30'u; boss'larda ≤ %40).
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
- **Tek vuruş riski** (taban 100 cana Balık'ta Kolos depremi ≈ 122; §13.2'deki yeni tablolarla Başak–Kova'da azalır, Balık'ta aynı) → açık; D5.
- Aslan–Balık dalga tabloları neredeyse aynı (T-07) → bu turda kapsam dışı; §17'de öneri.

### 15.6 Değişiklik önerileri
| # | Öneri | Durum |
|---|---|---|
| D1 | Yengeç geçiş bölgesi, tam kurallar sonra | **[CEO KARARI]** → §13.1 (Yengeç + Aslan iki kademe) |
| D2 | `_early()` odanın bölgesine baksın | **[CEO KARARI]** → §13.1 |
| D3 | Tehlike aralıkları yumuşasın | **[CEO KARARI]** → §13.5 (D3'ten daha yumuşak değerler) |
| D4 | İlk 3 bölgede seçkinler tek özellik | **[CEO KARARI]** → §13.3 |
| D5 | Tek vuruş tavanı: normal düşman saldırısı en yüksek canın %35'ini geçmesin | [ÖNERİ – Analist; CEO'ya sorulmadı, uygulanmayacak] |
| D6 | `BASE_HP` (100) ve `DASH_COOLDOWN` (3 sn) ölçüme kadar değişmesin; Koç–İkizler oda can kaybı %15'i aşarsa önce `DASH_COOLDOWN` 2,5 sn denensin | [ÖNERİ – Analist; CEO'ya sorulmadı, uygulanmayacak] |
| D7 | Öğreticide parry penceresi ×2 | **[CEO KARARI]** → §14.4 |

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
| 18 | [ÖNERİ – CEO onayı gerekir] **Aslan–Balık dalga tablolarını ayrıştır** (T-07): bugün `COMBAT_L` … `COMBAT_P` neredeyse aynı. Her bölgeye kendi imzasını veren dizilim (ör. Akrep'te taklitçi/iğneci ağırlıklı, Yay'da okçu ağırlıklı, Kova'da hava yaratıkları) ve son odada bölgenin "elit dalgası". Bu turda kapsam dışı. | öneri |

## 18. Açık sorular

1. Ana karakter kim?
2. İkincil uzak atış olsun mu? (Kentaur Yayı kısmen karşılıyor.)
3. Tam run (60 oda) tahminen 80–100 dk sürer; Hades'te bir run ~30–45 dk. Bölge başına oda sayısı ya da ara dönüş noktaları düşünülmeli mi?
4. D5 ve D6 (§15.6), Testçi'nin yeni ölçümlerinden sonra.
5. F tuşu da (ağır saldırı + etkileşim) E kuralına uysun mu? (§8)

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
| **T-21** simge ve okunabilirlik | (1) **AĞIR SALDIRI** simgesi güneş ışını olmaz: aşağı inen kalın ok + yer çizgisi ("çakma"). **TAÇ** (Güneş Gürzü, `aura`) için halka içinde nokta (hale) kullanılır; `cone/burst_self/aura` ortak simgesi ayrılır. Kural: yetenek çubuğunda iki slot aynı simgeyi taşımaz. (2) "DALGA x/y" ve "ODA x/y" yazılarının arkasına koyu yarı saydam şerit (Kova gibi parlak arenalarda okunur; kontrast ≥ 4,5:1). (3) Ödül göstergesinde simgenin altında ödülün adı (§19.3); "ÖDÜL" yazısı kalır. ♂ gibi gezegen simgeleri anlamsız değil (ödül gezegenini gösterir) ama adsız okunmuyordu; adla birlikte doğru kullanım. |

---

## Geçmiş: ilk prototip (NeonZombie)

Proje izometrik, neon cyberpunk bir zombi/mutant shooter olarak başladı (Vampire Survivors tarzı dalga hayatta kalma, 8 ateşli silah, şehir haritası, Kovan Anası boss'u). Oradan yeni oyuna taşınanlar: vuruş hissi sistemi, uzuv koparma, prosedürel yaratık yapımı, izometrik kamera, atılma, akış haritası, menü ve kayıt sistemi, boss altyapısı.
