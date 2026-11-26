# Beyond The Eye — portre promptları (ComfyUI)

Her görseli bu klasöre **dosya adıyla** kaydet (ör. `aries.png`). Bana "portreler hazır" de; oyuna ben eklerim.
Oyun dosyayı bulursa otomatik gösterir: boss isim kartında, Almanak'ta, Ay Ana ve Satürn ekranlarında.

## Ayarlar
- **Boyut:** 832 × 1216 (dikey). SDXL ya da Flux.
- **Tutarlılık için:** Hepsinde aynı model, aynı sampler, aynı CFG. Beğendiğin ilk portrenin seed'ini not al, diğerlerinde de aynı ayarları kullan.
- Her promptun başına **ORTAK STİL**'i, sonuna **KARAKTER** metnini koy.

**ORTAK STİL (her promptun başına):**
```
hand-painted stylized fantasy character portrait, waist-up, three-quarter view, bold dark ink outlines, rich jewel-tone colors, dramatic rim light, deep navy cosmic background with faint golden constellation lines and stars, painterly brush texture, game splash art, centered, high detail,
```

**NEGATİF (hepsinde aynı):**
```
photo, photorealistic, 3d render, text, watermark, signature, logo, extra fingers, deformed hands, blurry, low quality, cropped head, multiple characters, frame, border
```

## Karakterler

| Dosya | Karakter |
|---|---|
| `ayana.png` | `serene elderly moon mother, silver hair flowing like moonlight, pale blue glowing skin, crescent moon crown, flowing robes of night sky with tiny stars, gentle smile, holding a glowing pearl, soft silver and lavender palette` |
| `saturn.png` | `towering old cosmic blacksmith god, braided grey beard, ringed planet halo behind his head, leather apron over dark armor, glowing anvil sparks, heavy hammer on shoulder, stern but kind eyes, bronze gold and deep indigo palette` |
| `aries.png` | `furious ram warrior of fire, curled golden horns, burning red-orange mane, ember cracks glowing across dark armored body, snorting flames, aggressive charging stance, red orange and black palette` |
| `taurus.png` | `massive calm bull titan of earth, mossy stone skin, wreath of pink roses on his horns, one glowing red eye (Aldebaran), seven tiny stars on his shoulder, immovable posture, emerald green, rose and stone grey palette` |
| `gemini.png` | `two twin warrior brothers back to back, one with a sword one with gauntlets, one bright silver one dark blue, mirrored poses, wind swirling around them, pale blue and silver palette` |
| `cancer.png` | `giant motherly crab queen of the tides, glossy turquoise shell, a glowing moon pearl on her back, raised claws, sea foam and moonlit waves, teal, silver and deep blue palette` |
| `leo.png` | `proud lion king of the sun, enormous blazing golden mane like a solar corona, regal crown, golden armor, piercing amber eyes, sunbeams behind him, gold, amber and warm white palette` |
| `virgo.png` | `winged harvest maiden with a porcelain mask-like face, holding a giant silver scythe and a glowing ear of wheat, white and pale green robes, calm and precise, mint green, ivory and gold palette` |
| `libra.png` | `elegant blindfolded judge, holding a sword in one hand, giant golden scales floating over her shoulder, flowing teal robes, perfectly symmetrical pose, teal, gold and ivory palette` |
| `scorpio.png` | `obsidian scorpion queen, glossy black carapace, raised tail with a glowing red-orange star at the tip (Antares), venom-green highlights, phoenix flames rising behind her, black, toxic green and ember orange palette` |
| `sagittarius.png` | `noble centaur archer king, drawing a glowing bow aimed upward, purple and gold armor, galaxy swirling in the background, determined eyes, violet, gold and deep blue palette` |
| `capricorn.png` | `ancient mountain sea-goat elder, front half a giant goat with spiraling ice-blue horns, back half a scaled fish tail, long white beard, snowy mountain peak behind, slate grey, ice cyan and white palette` |
| `aquarius.png` | `floating storm sorcerer pouring starry water from a giant urn on his shoulder, hair made of crackling lightning, violet robes, electric cyan sparks, stormy clouds, violet, cyan and silver palette` |
| `pisces.png` | `two huge dreamlike fish circling each other connected by a glowing silver cord, one pearl-lilac one aqua, translucent fins, bubbles and floating light orbs, dreamy ocean of stars, lilac, aqua and pearl palette` |

## İpuçları
- Yüz ya da eller bozuk çıkarsa aynı seed'le sadece "detail" ayarını değiştirip tekrar dene, ya da inpaint kullan.
- Arka planlar koyu kalırsa oyunda daha iyi durur; açık arka plan çıkarsa promptun sonuna `dark background` ekle.
