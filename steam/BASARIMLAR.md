# Steam başarımları

Oyun bu 25 başarımı kendi içinde tutuyor (Almanak → Başarımlar). Steam'de görünmeleri için:

1. **Steamworks → Uygulama Yönetimi → Stats & Achievements → Achievements** sayfasında aşağıdaki her satır için yeni başarım ekle.
   - **API Name** sütununa tablodaki kimliği birebir yaz (örn. `BOSS_ARIES`).
   - Ad ve açıklamayı Türkçe ve İngilizce gir (dil ekleyerek).
   - **Achieved icon**: `achievement_icons/<KİMLİK>.jpg`, **Unachieved icon**: `achievement_icons/<KİMLİK>_locked.jpg` (256×256).
2. Sayfanın altındaki **Publish** ile yayınla.
3. Oyuna GodotSteam eklentisi kurulunca (Steam uygulama kimliği gerektirir) oyun başarımları otomatik olarak Steam'e de gönderir;
   kodda `Engine.has_singleton("Steam")` kontrolü hazır, başka değişiklik gerekmez.

| API Name | Türkçe ad | Türkçe açıklama | English name | English description |
|---|---|---|---|---|
| `BOSS_ARIES` | Koç Düştü | Koç'u arındır. | The Ram Falls | Restore Aries. |
| `BOSS_TAURUS` | Yerinden Oynamayan Oynadı | Boğa'yı arındır. | The Immovable Moved | Restore Taurus. |
| `BOSS_GEMINI` | İki Ses Sustu | İkizler'i arındır. | Two Voices Silenced | Restore Gemini. |
| `BOSS_CANCER` | Cezir | Yengeç'i arındır. | Low Tide | Restore Cancer. |
| `BOSS_LEO` | Bir Kralın Gün Batımı | Aslan'ı arındır. | Sunset of a King | Restore Leo. |
| `BOSS_VIRGO` | Hasat Kaldırıldı | Başak'ı arındır. | The Harvest Is In | Restore Virgo. |
| `BOSS_LIBRA` | Denge Yerine Geldi | Terazi'yi arındır. | Balance Restored | Restore Libra. |
| `BOSS_SCORPIO` | İki Kez Yenilen | Akrep'i ankasıyla birlikte arındır. | Twice Defeated | Restore Scorpio, phoenix and all. |
| `BOSS_SAGITTARIUS` | Okçuya Yetiştin | Yay'ı arındır. | Caught the Archer | Restore Sagittarius. |
| `BOSS_CAPRICORN` | Zirveye Ulaşıldı | Oğlak'ı arındır. | The Summit Reached | Restore Capricorn. |
| `BOSS_AQUARIUS` | Fırtınadan Sonra | Kova'yı arındır. | After the Storm | Restore Aquarius. |
| `BOSS_PISCES` | Rüyadan Uyanış | Balık'ı arındır. | Waking from the Dream | Restore Pisces. |
| `ALL_TWELVE` | Gökyüzü Bütün | On iki takımyıldızın hepsini arındır. | The Sky Is Whole | Restore all twelve constellations. |
| `CYCLE_1` | Bir Tur Daha | Sonsuz Gökyüzü'nde bir döngü tamamla. | Once More, Around | Complete a cycle of the Endless Sky. |
| `CYCLE_3` | Gözün Ötesi | Sonsuz Gökyüzü'nde 3. döngüyü tamamla. | Beyond the Eye | Complete cycle 3 of the Endless Sky. |
| `FLAWLESS` | Yıldızlar Dokunamadı | Hiç hasar almadan bir boss'u yen. | Untouched by the Stars | Defeat a boss without taking damage. |
| `FIRST_PARRY` | Savuşturma | Bir saldırıyı parry'le. | Turned Aside | Parry an attack. |
| `PARRY_100` | Altın Muhafız | 100 saldırıyı parry'le. | Golden Guard | Parry 100 attacks. |
| `KILLS_1000` | Bin Kayan Yıldız | 1000 yaratık yen. | A Thousand Falling Stars | Defeat 1000 creatures. |
| `DUO` | Kavuşum | Bir kavuşum ya da karşıtlık lütfu al. | Conjunction | Take a conjunction or opposition blessing. |
| `RISING_WIN` | Yükselende Yazılı | Bir yükselen seçiliyken boss yen. | Written in the Ascendant | Defeat a boss with a rising sign chosen. |
| `RETRO_5` | Retroya Karşı | Retro zorluğu 5 ya da üstündeyken boss yen. | Against the Retrograde | Defeat a boss with Retrograde heat 5 or more. |
| `MOON_BOND` | Ay'ın Çocuğu | Ay Ana ile en yüksek bağa ulaş. | Child of the Moon | Reach the highest bond with Mother Moon. |
| `SEAL_MASTER` | Örsün Ustası | Satürn'ün örsünde bir mührü ustalaştır. | Master of the Forge | Master a seal at Saturn's forge. |
| `ALMANAC_FULL` | Almanak Bekçisi | Almanak'ın bütün sayfalarını doldur. | Keeper of the Almanac | Fill in every page of the Almanac. |
