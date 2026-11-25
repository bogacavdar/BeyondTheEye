# GÖZÜN ÖTESİ: Oyun Tasarım Belgesi (GDD)

> Sürüm: 0.4 (yeni yön) · Son güncelleme: 25 Kasım 2026
> Ekip: Boğaç (yön, test, astroloji) + Claude (tasarım, kod, sistemler)
> Adını Instagram kanalı @gozunotesi_'den alır ve görsel dili oradan gelir.
> (Proje klasörü hâlâ "NeonZombie" adını taşıyor. İlk prototip neon zombi shooter'dı, aşağıdaki "Geçmiş" bölümüne bakın.)

---

## 1. Tek cümlede oyun

Bozulmuş burçların hüküm sürdüğü kozmik bir âlemde, oda oda ilerleyip **yakın dövüş, parry ve atılmayla** burçların gölge yönleriyle savaştığın, izometrik bir **aksiyon roguelite**'ı (Hades tarzı).

## 2. Temel direkler (pazarlıksız)

1. **Vuruş hissi her şeyden önce gelir.** Her darbe ağır ve tatmin edici: hit-stop, sarsıntı, altın kırıkları, yıldız tozu, uzuv koparma.
2. **Kaçarak, okuyarak dövüş.** Düşman saldırıları önceden belli olur. Atılma ve parry ile kaç, aç, cezalandır.
3. **Lacivert ve altın.** Kanalın görsel dili: gece göğü, dolunay, altından heykelleşmiş burçlar.
4. **Astrolojik doğruluk.** Burçlar ve gezegenler gerçek astrolojik özelliklerine sadık. Bozulmuş burçlar **gölge yönleriyle** savaşır.

## 3. Hikâye

Burçlar bozuldu, gökyüzünün düzeni çöktü. Kahraman, gözle görülenin ötesindeki âleme geçip bozulmuş burçları arındırarak düzeni geri getirmeye çalışır.
- Bozulma = burcun **gölge yönüne** teslim olması. Bu hem astrolojik olarak doğru, hem de tasarımda esneklik sağlar.
- **Açık soru:** Ana karakter kim? (kâhin, gökte hapsolmuş ruh, savaşçı… sonra karar verilecek)

## 4. Oyun akışı (Hades yapısı)

1. Run başında **silah seçilir**. Oyun tarzını silah belirler.
2. Bölge birbirine bağlı **odalardan** oluşur. Odaya girince kapılar kilitlenir, düşman dalgaları gelir.
3. Oda temizlenince **ödül** çıkar.
4. Çıkışta 2-3 kapı vardır. Kapının üstünde arkasındaki ödülün simgesi görünür, oyuncu seçer.
5. Yaklaşık 10-12 oda sonra **burç boss'u** gelir.
6. Ölünce başa dönülür, kalıcı kaynaklar **Doğum Haritası**'nda harcanır.

**Oda türleri:** savaş, elit (zor ama iyi ödüllü), dükkân, dinlenme (can), boss.
**Ödül türleri:** gezegen etkisi, silah güçlendirme, kalıcı kaynak (yıldız tozu), can.

## 5. Bölgeler: 4 element

| Bölge | Burçlar (boss adayları) | Atmosfer |
|---|---|---|
| Ateş | Koç, Aslan, Yay | kızıl-altın, alevli takımyıldızlar |
| Toprak | Boğa, Başak, Oğlak | altın sütunlar, taş, kristal |
| Hava | İkizler, Terazi, Kova | bulutlar, rüzgâr, süzülen platformlar |
| Su | Yengeç, Akrep, Balık | dolunay yansımaları, gelgit |

Her run'da bölgenin boss'u o elementin üç burcundan biri olur. Toplam 12 boss.

## 6. Boss'lar: burçların gölge yönleri (taslak)

| Burç | Gölge yönü | Dövüş fikri |
|---|---|---|
| Koç | öfke, düşünmeden saldırı | durmadan hücum eder, duvarlara çarpar, çarpınca sersemler |
| Boğa | inat, sahiplenme | neredeyse kıpırdamaz, çok dayanıklı, alanına giren cezalandırılır |
| İkizler | ikiyüzlülük | ikiye bölünür, gerçek olanı bulman gerekir |
| Akrep | saklı intikam | görünmez olur, zehir, verdiğin hasarı yansıtır |
| (diğerleri) | Boğaç ile birlikte, kanal yorumlarına dayanarak yazılacak | |

## 7. Silahlar (yakın dövüş)

| Silah | Tarz |
|---|---|
| Yıldız Kılıcı | hızlı kombolar, en geniş parry penceresi |
| Ay Orağı | geniş süpürme vuruşları, kalabalığa karşı |
| Güneş Gürzü | yavaş ve ağır, yere vurunca ışık dalgası |
| Kuyruklu Yıldız Mızrağı | uzun menzil, saplama, fırlatıp geri çağırma |
| Meteor Zinciri | nunçaku gibi, çok hızlı ve çok vuruşlu |

**Kontroller:** sol tık saldırı kombosu, sağ tık güçlü saldırı, Boşluk atılma, Shift (ya da Q) parry. Parry tam zamanında yapılırsa düşman sersemler ve ağır bir **bitirici** vuruş açılır.
**Açık soru:** Hades'teki gibi bir ikincil uzak atış (örneğin yıldız parçası fırlatma) olsun mu?

## 8. Gezegen etkileri (Hades'teki lütufların karşılığı)

| Gezegen | Tarz |
|---|---|
| Güneş | patlama, ışık, kör etme |
| Ay | yansıma, kaçış, gölge kopyalar |
| Merkür | hız, çift vuruş, atılma güçlendirme |
| Venüs | can çalma, büyüleme |
| Mars | saldırı gücü, yakıcılık |
| Jüpiter | büyüme, şans, alan etkisi |
| Satürn | savunma, zaman yavaşlatma, kalkan |

## 9. Rastgele zorluklar: retrolar ve tutulmalar

- **Merkür Retrosu:** kapılar yanlış ödül gösterebilir
- **Ay Tutulması:** bu odada düşmanlar görünmez, sadece gölgeleri görünür
- (sonra genişletilecek)

## 10. Kalıcı gelişim: Doğum Haritası (skill ağacı)

Daire şeklinde, 12 evli dev bir harita. Kalıcı kaynak (**yıldız tozu**) ile düğümler açılır.

| Ev | Dal |
|---|---|
| 1. ev | beden, en yüksek can |
| 2. ev | kazanç, yıldız tozu bonusu |
| 3. ev | hareket, atılma |
| 6. ev | sağlık, yenilenme |
| 8. ev | ölüm, kritik vuruş, uzuv koparma |
| 10. ev | güç, hasar |
| diğer evler | silah ustalıkları, parry, şans (Boğaç ile birlikte dağıtılacak) |

## 11. Görsel dil

- **Renkler:** koyu lacivert gece göğü + altın sarısı. İkinci ışık kaynağı dolunayın soğuk beyazı.
- **Yaratıklar:** altından heykeller. Bozulanlar çatlamış altın, çatlaklardan kara boşluk ve yıldız tozu sızar.
- **Kan yok:** vuruşta altın kırıkları ve parlayan yıldız tozu. Kopan uzuvlar ışık saçarak dağılır, yerde bir süre toz izi kalır.
- **Dolunay:** her bölümün göğünde, boss odalarında boss'un arkasında.
- **Yazılar:** Cinzel benzeri oymalı serif altın yazı (bedava, ticari kullanıma açık).
- **Arayüz:** ince altın çerçeveler, köşe süslemeleri, burç sembolleri, oval altın etiketler.
- **Boss ölümü:** parçaları göğe yükselip takımyıldızına döner, burç arınır.

## 12. Yol haritası (sırayla, her adım test edilerek)

| # | Adım | Durum |
|---|---|---|
| 1 | Tasarım belgesi (bu belge) | ✅ |
| 2 | **Görsel dönüşüm:** lacivert-altın gökyüzü, dolunay, altın yazı tipi, menü, Gözlemevi, gerçekçi gezegen düzeneği | ✅ |
| 3 | **Yakın dövüş çekirdeği:** Yıldız Kılıcı 3'lü kombosu, ağır saldırı, atılma, parry; 3 silah yeteneği (1/2/3); yıldız tozu ve altın kırığı efektleri | ✅ ilk sürüm |
| 4 | **Saldırısını belli eden ilk düşman:** Gölge (bozulmuş yıldız ruhu): yerde kızıl uyarı yelpazesi, parry ile sersemler | ✅ ilk sürüm |
| 5 | **Oda sistemi:** 4 oda + boss; 2 kapıdan seçim (lütuf / yıldız tozu / Sığınak); can ve lütuflar odalar arası taşınır | ✅ ilk sürüm |
| 6 | **Gezegen lütufları:** 7 gezegen × 4 lütuf = 28 lütuf; oda sonunda 3 karttan seçim | ✅ ilk sürüm |
| 7 | **İlk boss: Koç** — 3 evre: boynuz savuruşu (parry), hücum zinciri, yere vurma, ateş halkası, alev yağmuru, yardımcı çağırma | ✅ ilk sürüm |
| 8 | **Doğum Haritası** skill ağacı: 12 ev, 516 yıldız, 1764 kademe; küçük yıldızlar ve bazı büyük güçler dövüşe bağlı | ✅ kısmen |
| 9 | Diğer silahların yetenekleri, bölgeler, boss'lar, dövüş müziği | ⏳ |
| — | Ayarlar (ana ses / müzik / efekt ayrı), duraklatma menüsü, Türkçe-İngilizce dil desteği, menü ve Gözlemevi müziği | ✅ |

**Silah yetenekleri (1, 2, 3):**
- Yıldız Kılıcı: Yıldız Yağmuru · Işık Dalgası · Takımyıldızı Adımı (oynanabilir)
- Ay Orağı: Hilal Biçişi · Ay Gelgiti · Tutulma
- Güneş Gürzü: Güneş Patlaması · Zirve Darbesi · Taç
- Kuyruklu Yıldız Mızrağı: Kuyruklu Yıldız Atışı · Günberi Hücumu · Kuyruk Süpürmesi
- Meteor Zinciri: Çarpma · Yörünge · Meteor Sağanağı

## 13. Açık sorular

1. Ana karakter kim?
2. İkincil uzak atış olsun mu?
3. Zorluk: Hades gibi affedici mi, Souls gibi cezalandırıcı mı?
4. Diğer burçların gölge yönleri ve 12 evin dalları (Boğaç ile).

---

## Geçmiş: ilk prototip (NeonZombie)

Proje izometrik, neon cyberpunk bir zombi/mutant shooter olarak başladı (Vampire Survivors tarzı dalga hayatta kalma, 8 ateşli silah, şehir haritası, Kovan Anası boss'u). Oradan şunlar yeni oyuna taşınıyor: vuruş hissi sistemi (hit-stop, sarsıntı, parçacıklar), uzuv koparma, prosedürel yaratık yapımı, izometrik kamera, atılma, akış haritası (yol bulma), menü ve kayıt sistemi, boss altyapısı.
