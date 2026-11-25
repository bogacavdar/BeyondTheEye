extends RefCounted
## ALMANAK: Gözlemevi'ndeki kitap. Her burç için bir sayfa: mit, bölge, boss ve dört yaratık.
## Açılma: bölgeye ilk girişte burcun miti ve bölgesi, yaratığı ilk öldürüşte o yaratığın kaydı,
## boss'u yenince boss'un kaydı açılır. Yaratık kayıtlarında kaç tane öldürüldüğü de yazar.
## Metinler doğrudan iki dilde tutulur (GameData.lang: "tr" ise Türkçe, değilse İngilizce).

const SIGNS := ["aries", "taurus", "gemini", "cancer", "leo", "virgo", "libra", "scorpio", "sagittarius", "capricorn", "aquarius", "pisces"]
const KINDS := ["shade", "caster", "leaper", "brute"]

## e: [İngilizce, Türkçe]
const PAGES := {
	"aries": {
		"glyph": "♈", "col": Color(1.0, 0.45, 0.3),
		"name": ["ARIES", "KOÇ"], "zone": ["The Ram's Pass", "Koç Geçidi"],
		"myth": ["The golden-fleeced ram flew Phrixus and Helle away from a cruel stepmother. Its fleece was hung in Colchis, the prize Jason and the Argonauts later sailed for. Ruled by Mars: courage, fire, the first spark of the zodiac.",
			"Altın postlu koç, Phrixos ile Helle'yi zalim üvey annelerinden kaçırıp gökte uçurdu. Postu Kolkhis'te asıldı; Iason ve Argonotlar yıllar sonra onun için yola çıktı. Yöneticisi Mars: cesaret, ateş, zodyağın ilk kıvılcımı."],
		"boss": ["THE RAM'S FURY", "KOÇ'UN ÖFKESİ"],
		"boss_d": ["Aries' shadow side: rage and endless charging. A horn sweep you can parry, charges in lines, a widening ring of fire and, at the end, a rain of flame. After his last charge he staggers: strike then.",
			"Koç'un gölge yanı: öfke ve durmaksızın hücum. Parry'lenebilen boynuz savuruşu, düz hatta hücumlar, genişleyen ateş halkası ve sonunda alev yağmuru. Son hücumundan sonra sendeler: o an vur."],
		"creatures": {
			"shade": [["Ember Imp", "Kor Cini"], ["A flaming claw. When it dies it leaves an ember that bursts a moment later.", "Alevli pençe. Ölünce yerinde kısa süre sonra patlayan bir kor bırakır."]],
			"caster": [["Mars Seer", "Mars Kâhini"], ["Hurls fireballs at a point; the ground keeps burning.", "Hedef noktaya ateş topu fırlatır; yer bir süre yanar."]],
			"leaper": [["Wild Ram", "Hırçın Koç"], ["Lowers its head and charges in a straight line. If it misses, it is dazed.", "Başını eğip düz bir hatta toslar. Iskalarsa sersemler."]],
			"brute": [["Mars Warrior", "Mars Savaşçısı"], ["A shielded axe master: his shield blocks light hits from the front.", "Kalkanlı balta ustası: önden gelen hafif vuruşları kalkanıyla keser."]],
		},
	},
	"taurus": {
		"glyph": "♉", "col": Color(0.55, 1.0, 0.45),
		"name": ["TAURUS", "BOĞA"], "zone": ["The Bull's Meadows", "Boğa Otlakları"],
		"myth": ["Zeus became a gleaming white bull and carried Europa across the sea to Crete. In the sky the bull's red eye is Aldebaran, and the Pleiades ride on its shoulder. Ruled by Venus: patience, earth, beauty that does not move.",
			"Zeus bembeyaz bir boğaya dönüşüp Europa'yı sırtında denizden Girit'e taşıdı. Gökte boğanın kızıl gözü Aldebaran'dır, omzunda da Ülker yıldızları durur. Yöneticisi Venüs: sabır, toprak, yerinden oynamayan güzellik."],
		"boss": ["THE IMMOVABLE", "YERİNDEN OYNAMAYAN"],
		"boss_d": ["Slow, heavy and never moved: he controls the field. Hoof quakes in rings (the gaps are safe), hurled boulders, Venus roses that heal him (cut them first), Aldebaran's sweeping eye and a stampede of ghost bulls.",
			"Yavaş, ağır ve yerinden oynamaz: alanı kontrol eder. Halka halka toynak depremi (aralar güvenli), fırlatılan kayalar, onu iyileştiren Venüs gülleri (önce onları kes), arenayı süpüren Aldebaran'ın Gözü ve hayalet boğa sürüsü."],
		"creatures": {
			"shade": [["Thorn Bramble", "Diken Çalısı"], ["A rose-headed vine. When it dies it leaves a thorny patch that slows you.", "Gül başlı sarmaşık. Ölünce seni yavaşlatan dikenli bir alan bırakır."]],
			"caster": [["Pleiades Priestess", "Ülker Rahibesi"], ["Fires slow seeds and shields a nearby ally. Kill her first.", "Yavaş tohum mermileri atar, yakındaki bir dostuna kalkan verir. Önce onu öldür."]],
			"leaper": [["Earth Mole", "Toprak Köstebeği"], ["Burrows (untouchable), surfaces beneath you and bursts out.", "Toprağa gömülür (dokunulmaz), altına gelir ve yerden fırlar."]],
			"brute": [["Stone Golem", "Taş Golem"], ["Opens a crack that runs forward; splits into two pebbles on death.", "İleri doğru ilerleyen bir yarık açar; ölünce iki küçük taşçığa bölünür."]],
		},
	},
	"gemini": {
		"glyph": "♊", "col": Color(0.6, 0.8, 1.0),
		"name": ["GEMINI", "İKİZLER"], "zone": ["The Twin Skies", "İkiz Gökler"],
		"myth": ["Castor was mortal, Pollux the son of Zeus. When Castor died, Pollux begged to share his immortality, so the twins spend one day on Olympus and the next beneath the earth, never apart. Ruled by Mercury: air, words, two voices in one sky.",
			"Kastor ölümlüydü, Polluks ise Zeus'un oğlu. Kastor ölünce Polluks ölümsüzlüğünü onunla paylaşmak için yalvardı; ikizler o günden beri bir gün Olimpos'ta, bir gün yerin altında, hiç ayrılmadan yaşar. Yöneticisi Merkür: hava, söz, tek gökte iki ses."],
		"boss": ["CASTOR & POLLUX", "KASTOR & POLLUKS"],
		"boss_d": ["Two bosses at once with a shared health bar. If one falls, the other raises him seven seconds later and rages meanwhile: bring them down close together. Swords and fists you can parry, swapped places and a crossing beam.",
			"Aynı anda iki boss, can çubuğu ortak. Biri düşerse kardeşi onu yedi saniye sonra kaldırır ve bu arada öfkelenir: ikisini yakın zamanda indir. Parry'lenen kılıç ve yumruk serileri, yer değiştirme ve çapraz ışın."],
		"creatures": {
			"shade": [["Twin Shade", "İkiz Gölge"], ["Born in pairs; when one dies its twin grows furious. Take them down together.", "Çift doğar; biri ölünce eşi öfkelenir. İkisini birlikte indir."]],
			"caster": [["Mercury Herald", "Merkür Habercisi"], ["Teleports away when you close in and throws a returning wind blade.", "Yaklaşınca ışınlanıp kaçar; gidip geri dönen rüzgâr bıçağı fırlatır."]],
			"leaper": [["Storm Bird", "Fırtına Kuşu"], ["Rises out of reach, glides above you and dives.", "Havaya yükselir (dokunulmaz), tepende süzülür ve dalar."]],
			"brute": [["Mirror Warden", "Ayna Muhafızı"], ["Raises its mirror to reflect light hits; a heavy hit shatters it.", "Aynasını kaldırınca hafif vuruşları sana yansıtır; ağır vuruş aynayı kırar."]],
		},
	},
	"cancer": {
		"glyph": "♋", "col": Color(0.5, 0.9, 1.0),
		"name": ["CANCER", "YENGEÇ"], "zone": ["The Moonlit Shore", "Ay Işıklı Kıyı"],
		"myth": ["Hera sent a giant crab to bite Heracles' heel while he fought the Hydra. It was crushed underfoot, but Hera set it among the stars for its loyalty. Ruled by the Moon: water, home, the tide that always returns.",
			"Herakles Hydra ile dövüşürken Hera, topuğunu ısırması için dev bir yengeç gönderdi. Yengeç ezildi ama Hera sadakati için onu yıldızların arasına koydu. Yöneticisi Ay: su, yuva, hep geri dönen gelgit."],
		"boss": ["MOTHER OF TIDES", "GELGİTİN ANASI"],
		"boss_d": ["A giant crab with the Moon's pearl on her back. Her shell is hard in front and soft behind. Double pincers you can parry, sideways rushes, the rising tide where only her inner circle is dry, and a pulling whirlpool.",
			"Sırtında Ay'ın incisini taşıyan dev yengeç. Kabuğu önden sert, arkadan yumuşak. Parry'lenen çift kıskaç, yan yan koşu, yalnızca yanındaki iç dairenin kuru kaldığı gelgit ve içine çeken girdap."],
		"creatures": {
			"shade": [["Shell Soldier", "Kabuk Askeri"], ["Hit three times quickly and it withdraws into its shell, then snaps around itself.", "Kısa sürede üç kez vurulursa kabuğuna çekilir, sonra etrafına kıskaç vurur."]],
			"caster": [["Tide Oracle", "Gelgit Kâhini"], ["Sends a wall of water across the arena that pushes you back.", "Arenayı süpüren, değince seni geri iten bir dalga duvarı gönderir."]],
			"leaper": [["Moon Jelly", "Ay Denizanası"], ["Pulls you in when close and spreads a ring of lightning.", "Yakınındayken seni kendine çeker, etrafına elektrik halkası yayar."]],
			"brute": [["Giant Hermit Crab", "Dev Keşiş Yengeci"], ["Rains slowing bubbles. Its back is soft: hits from behind deal double.", "Yavaşlatan kabarcık yağdırır. Sırtı yumuşak: arkadan vuruşlar iki kat."]],
		},
	},
	"leo": {
		"glyph": "♌", "col": Color(1.0, 0.8, 0.4),
		"name": ["LEO", "ASLAN"], "zone": ["The Sun Palace", "Güneş Sarayı"],
		"myth": ["The Nemean lion's hide could not be pierced by any weapon. Heracles strangled it with his bare hands and wore its skin as armour ever after. Ruled by the Sun: pride, fire, the heart of the summer sky.",
			"Nemea aslanının postunu hiçbir silah delemezdi. Herakles onu çıplak elleriyle boğdu ve postunu ömrü boyunca zırh gibi giydi. Yöneticisi Güneş: gurur, ateş, yaz göğünün kalbi."],
		"boss": ["THE SUN KING", "GÜNEŞ KRAL"],
		"boss_d": ["Fast, proud and brutal; every pride cub alive makes him hit harder. A three-claw combo (parry any one to break it), pounces, a roar that throws you back, the Zenith where only shadows are safe, and four spinning arms of flame.",
			"Hızlı, gururlu ve sert; yaşayan her sürü yavrusu onu daha güçlü vurdurur. Üçlü pençe serisi (birini parry'le, seri kırılır), sıçrayış, savuran kükreme, yalnızca gölgelerin güvenli olduğu Zenit ve etrafında dönen dört alev kolu."],
		"creatures": {
			"shade": [["Pride Cub", "Sürü Yavrusu"], ["+20% damage for each sibling nearby (up to +60%). Break up the pride.", "Yakınındaki her kardeşi için +%20 hasar (en çok +%60). Sürüyü dağıt."]],
			"caster": [["Sun Priest", "Güneş Rahibi"], ["Calls down sunbeams and crowns an ally (+50% damage).", "Hatta güneş ışını indirir ve bir dostuna taç giydirir (+%50 hasar)."]],
			"leaper": [["Mirage Hunter", "Serap Avcısı"], ["Turns invisible while stalking you, only shimmering; it appears when it strikes or is hit.", "Kovalarken görünmez olur, sadece titreşir; vurulunca ya da saldırırken görünür."]],
			"brute": [["Nemean Lion", "Nemea Aslanı"], ["Its hide absorbs 70% of damage. Parry its attack to crack the hide for six seconds.", "Postu hasarın %70'ini emer. Saldırısını parry'lersen post altı saniye çatlar."]],
		},
	},
	"virgo": {
		"glyph": "♍", "col": Color(0.5, 1.0, 0.85),
		"name": ["VIRGO", "BAŞAK"], "zone": ["The Silent Harvest", "Sessiz Hasat"],
		"myth": ["Astraea, goddess of justice, was the last immortal to leave the earth when people turned cruel. She holds an ear of wheat, the bright star Spica. Ruled by Mercury: earth, order, the patient work of the harvest.",
			"Adalet tanrıçası Astraea, insanlar acımasızlaşınca dünyayı terk eden son ölümsüzdü. Elinde bir başak tutar: parlak Spika yıldızı. Yöneticisi Merkür: toprak, düzen, hasadın sabırlı emeği."],
		"boss": ["THE HARVEST MAIDEN", "HASAT BAKİRESİ"],
		"boss_d": ["Winged, porcelain-faced, with a giant scythe. Her fight is built on order: read the pattern and you win. Scythe sweeps you can parry, wheat sheaves, the Analysis that detonates the path you walked, a checkerboard grid and the Harvest Moon.",
			"Kanatlı, porselen yüzlü, dev oraklı. Dövüşü düzen üzerine kurulu: deseni okuyan kazanır. Parry'lenen orak savuruşu, başak demetleri, yürüdüğün yolu patlatan Çözümleme, dama tahtası ızgarası ve Hasat Ayı."],
		"creatures": {
			"shade": [["Reaper", "Orakçı"], ["A golden claw and a full 360° scythe spin.", "Altın pençe ve etrafında 360° orak savuruşu."]],
			"caster": [["Archivist", "Arşivci"], ["Lays down three seals that burst in order toward you.", "Sana doğru sırayla patlayan üç mühür dizer."]],
			"leaper": [["Seed Sower", "Tohum Ekici"], ["Leaps onto you and scatters slowing seeds where it lands.", "Üstüne atlar, indiği yere yavaşlatan tohumlar saçar."]],
			"brute": [["Straw Giant", "Hasır Dev"], ["Regenerates quickly if left alone for 2.5 seconds. Keep up the pressure.", "2,5 saniye vurulmazsa hızla yenilenir. Baskıyı bırakma."]],
		},
	},
	"libra": {
		"glyph": "♎", "col": Color(0.4, 1.0, 0.8),
		"name": ["LIBRA", "TERAZİ"], "zone": ["The Scales of Dawn", "Şafak Terazisi"],
		"myth": ["The only sign that is not a living being: the scales of Astraea, weighing every soul. The ancients once saw these stars as the Scorpion's claws. Ruled by Venus: air, balance, the moment day equals night.",
			"Canlı olmayan tek burç: her ruhu tartan Astraea'nın terazisi. Eskiler bu yıldızları bir zamanlar Akrep'in kıskaçları olarak görürdü. Yöneticisi Venüs: hava, denge, gecenin gündüze eşit olduğu an."],
		"boss": ["ARBITER OF BALANCE", "DENGENİN HAKEMİ"],
		"boss_d": ["A judge with a sword and giant scales on her shoulder. Hit her from one side too often and the scale tips and crushes that half: alternate sides. Sword strikes you can parry, falling pans, the Verdict on half the arena, and two turning beams.",
			"Elinde kılıç, omzunda dev terazi taşıyan yargıç. Hep aynı taraftan vurursan kefe o yana ağar ve o yarıyı ezer: iki yandan sırayla vur. Parry'lenen kılıç darbeleri, inen kefeler, arenanın yarısına Hüküm ve dönen iki ışın."],
		"creatures": {
			"shade": [["Arbiter", "Hakem"], ["Bound to its partner: damage to one is split between both. Melt them together.", "Eşiyle bağlı: birine vurduğun hasar ikisine bölünür. İkisini birlikte erit."]],
			"caster": [["Scale Keeper", "Terazi Bekçisi"], ["Casts a two-step verdict and evens out its allies' health.", "Sırayla iki patlamalı hüküm verir, yakındaki dostlarının canını eşitler."]],
			"leaper": [["Feather Dancer", "Tüy Dansçısı"], ["Gracefully dodges the first hit every four seconds.", "Dört saniyede bir ilk vuruştan zarifçe kaçar."]],
			"brute": [["Counterweight Golem", "Karşı Ağırlık Golemi"], ["Stores the damage it takes, then releases it as a shockwave.", "Aldığı hasarı biriktirir; dolunca etrafını şok dalgasıyla döver."]],
		},
	},
	"scorpio": {
		"glyph": "♏", "col": Color(0.5, 1.0, 0.3),
		"name": ["SCORPIO", "AKREP"], "zone": ["The Venom Depths", "Zehir Mağaraları"],
		"myth": ["A scorpion was sent to stop the boastful hunter Orion, and its sting brought him down. Placed on opposite sides of the sky, the two never shine together: when Scorpio rises, Orion sets. Ruled by Mars and Pluto: water, death and rebirth.",
			"Övüngen avcı Orion'u durdurmak için bir akrep gönderildi ve iğnesiyle onu yere serdi. Göğün iki zıt ucuna konan ikisi asla birlikte parlamaz: Akrep doğarken Orion batar. Yöneticileri Mars ve Plüton: su, ölüm ve yeniden doğuş."],
		"boss": ["THE VENOM QUEEN", "ZEHİR KRALİÇESİ"],
		"boss_d": ["An obsidian scorpion with Antares glowing in her tail. Pincers you can parry, a triple stinger strike, poison clouds and burrowing. When she dies for the first time she is reborn as a phoenix: rings of Antares fire and flaming dives.",
			"Kuyruğunda Antares parlayan obsidyen akrep. Parry'lenen kıskaçlar, üçlü iğne, zehir bulutları ve toprağa gömülme. İlk kez ölünce Anka olarak yeniden doğar: Antares halkaları ve alev dalışları."],
		"creatures": {
			"shade": [["Venom Needle", "Zehirli İğne"], ["Its hits poison you. Poison melts health but cannot kill.", "Vuruşları zehirler. Zehir canı eritir ama öldürmez."]],
			"caster": [["Acid Spitter", "Asit Tükürücü"], ["Spits pools of acid onto the ground.", "Yere zehirli asit gölcükleri fırlatır."]],
			"leaper": [["Deathfeigner", "Ölü Taklitçi"], ["Plays dead when hurt. Finish it within two seconds or it rises and lunges.", "Canı azalınca ölü taklidi yapar. İki saniyede bitirmezsen canlanıp atılır."]],
			"brute": [["Pincer Titan", "Kıskaçlı Titan"], ["Its grab roots you in place and poisons you.", "Yakalaması seni kısa süre kıpırdatmaz ve zehirler."]],
		},
	},
	"sagittarius": {
		"glyph": "♐", "col": Color(0.7, 0.55, 1.0),
		"name": ["SAGITTARIUS", "YAY"], "zone": ["The Centaur Steppes", "Kentaur Bozkırı"],
		"myth": ["A centaur archer, often said to be wise Chiron, teacher of heroes. His arrow is drawn toward Antares, the heart of the Scorpion, guarding the sky. Ruled by Jupiter: fire, freedom, the hunt that never stands still.",
			"Kahramanların öğretmeni bilge Kiron olduğu söylenen kentaur okçu. Oku, gökyüzünü korumak için Akrep'in kalbi Antares'e gerili durur. Yöneticisi Jüpiter: ateş, özgürlük, hiç durmayan av."],
		"boss": ["THE ARCHER KING", "OKÇU KRAL"],
		"boss_d": ["Unlike the others he keeps his distance: you have to catch him. Arrow rain, a piercing arrow, a double kick you can parry when you get close, a gallop across the arena and, at the end, the Galactic Center.",
			"Ötekilerin aksine mesafe korur: ona sen yetişmelisin. Ok yağmuru, delici ok, yakına gelince parry'lenen çifte tekme, arenayı boydan boya dörtnala ve sonunda Galaksi Merkezi."],
		"creatures": {
			"shade": [["Centaur Lancer", "Kentaur Mızrakçısı"], ["Strikes and leaps straight back: hit and run.", "Vurur ve hemen geri sıçrar: vur-kaç."]],
			"caster": [["Archer", "Okçu"], ["Brings down a rain of arrows around you.", "Senin çevrene ok yağmuru indirir."]],
			"leaper": [["Hunting Hawk", "Avcı Şahin"], ["Soars out of reach and dives from the sky.", "Havada süzülür, gökten dalar."]],
			"brute": [["Siege Centaur", "Kuşatma Kentauru"], ["Its back-mounted ballista pierces the whole arena and throws you.", "Sırtındaki balistayla arenayı boydan boya delen ok atar ve seni savurur."]],
		},
	},
	"capricorn": {
		"glyph": "♑", "col": Color(0.4, 1.0, 0.9),
		"name": ["CAPRICORN", "OĞLAK"], "zone": ["The Frozen Summit", "Donmuş Zirve"],
		"myth": ["Fleeing the monster Typhon, the god Pan leapt into a river: the half above water stayed a goat, the half below became a fish. The sea-goat is one of the oldest constellations ever drawn. Ruled by Saturn: earth, patience, the steepest climb.",
			"Canavar Tifon'dan kaçan tanrı Pan bir nehre atladı: sudan çıkan yarısı keçi kaldı, suyun altındaki yarısı balığa dönüştü. Deniz keçisi çizilmiş en eski takımyıldızlardan biridir. Yöneticisi Satürn: toprak, sabır, en dik yokuş."],
		"boss": ["THE MOUNTAIN ELDER", "DAĞIN YAŞLISI"],
		"boss_d": ["A giant mountain goat in front, a fish-tailed sea-goat behind. Slow, heavy blows: a double horn charge you can parry, avalanches with one gap, a ring of ice with one opening, the Biting Frost that punishes standing still, and the tide of the sea-goat.",
			"Önü dev dağ keçisi, arkası balık kuyruklu deniz keçisi. Yavaş ama ağır: parry'lenen ikili boynuz tosu, tek boşluklu çığ, tek açıklıklı buz çemberi, yerinde durmayı cezalandıran Dondurucu Ayaz ve deniz keçisinin gelgiti."],
		"creatures": {
			"shade": [["Mountain Goat", "Dağ Keçisi"], ["Besides its claw it rams; the ram cannot be parried and throws you.", "Pençesinin yanında tos atar; tos parry'lenmez, seni savurur."]],
			"caster": [["Ice Hermit", "Buz Ermişi"], ["Ice spikes burst toward you one by one and freeze you briefly.", "Sana doğru sırayla buz dikenleri fışkırtır; değerse kısa süre donarsın."]],
			"leaper": [["Avalanche Ball", "Çığ Yuvarlağı"], ["Rolls in a straight line and crushes you.", "Düz hatta yuvarlanıp ezer."]],
			"brute": [["Patient Giant", "Sabırlı Dev"], ["Gains a layer of ice armour every three seconds it isn't hit (up to five); each hit breaks one.", "Üç saniye vurulmazsa bir buz zırh katmanı kuşanır (en çok beş); her vuruş birini kırar."]],
		},
	},
	"aquarius": {
		"glyph": "♒", "col": Color(0.6, 0.9, 1.0),
		"name": ["AQUARIUS", "KOVA"], "zone": ["The Storm Observatory", "Fırtına Gözlemevi"],
		"myth": ["Ganymede, the most beautiful of mortals, was carried to Olympus by Zeus's eagle to become the cupbearer of the gods. He pours the water of the heavens from his urn. Ruled by Saturn and Uranus: air, the future, sudden lightning.",
			"Ölümlülerin en güzeli Ganymedes, Zeus'un kartalı tarafından Olimpos'a kaçırıldı ve tanrıların sakisi oldu. Testisinden göğün suyunu döker. Yöneticileri Satürn ve Uranüs: hava, gelecek, ansızın çakan şimşek."],
		"boss": ["THE WATER BEARER", "SUYUN TAŞIYICISI"],
		"boss_d": ["He floats at a distance with a starry urn on his shoulder. An air sign that carries water: he pours it out, then electrifies it. An urn slam you can parry, pouring waves, lightning and storm orbs, the Flood that turns pools into traps, and the New Age of spinning lightning.",
			"Omzunda yıldızlı testiyle mesafede süzülür. Su taşıyan bir hava burcu: suyu döker, sonra elektriklendirir. Parry'lenen testi darbesi, dalgalar, yıldırım ve fırtına küreleri, gölleri tuzağa çeviren Sel ve dönen şimşeklerle Yeni Çağ."],
		"creatures": {
			"shade": [["Storm Sprite", "Fırtına Perisi"], ["If you keep your distance it teleports behind you in a flash and strikes at once.", "Uzaktaysan bir şimşekle arkana ışınlanır ve hemen pençe atar."]],
			"caster": [["Lightning Sage", "Şimşek Bilgesi"], ["Launches a slow storm orb that hunts you.", "Seni yavaşça kovalayan bir fırtına küresi fırlatır."]],
			"leaper": [["Urn Bearer", "Testi Taşıyıcı"], ["Throws its urn; the ground floods and slows you.", "Testisini fırlatır; düştüğü yeri su basar ve yavaşlatır."]],
			"brute": [["Conductor Golem", "İletken Golem"], ["Opens arms of lightning that spin around it.", "Çevresinde dönen şimşek kolları açar."]],
		},
	},
	"pisces": {
		"glyph": "♓", "col": Color(0.85, 0.65, 1.0),
		"name": ["PISCES", "BALIK"], "zone": ["The Sea of Dreams", "Rüyalar Denizi"],
		"myth": ["Fleeing Typhon, Aphrodite and her son Eros became two fish and tied themselves together with a cord so they would not lose each other in the river. The last sign of the zodiac, where every cycle ends and begins. Ruled by Jupiter and Neptune: water, dreams, the whole sky.",
			"Tifon'dan kaçan Afrodit ve oğlu Eros iki balığa dönüştü; nehirde birbirlerini kaybetmemek için kendilerini bir iple bağladılar. Zodyağın son burcu: her döngünün bittiği ve başladığı yer. Yöneticileri Jüpiter ve Neptün: su, rüya, bütün gökyüzü."],
		"boss": ["THE DREAMER", "RÜYA GÖREN"],
		"boss_d": ["Two giant dream fish bound by a silver cord, forever circling each other. A tail you can parry, the sweeping cord, twin darts and rings of foam, a whirlpool that pulls you in and, at the end, the Echo of the Zodiac: the moves of all eleven other signs.",
			"Gümüş bir bağla bağlı, sürekli birbirinin çevresinde dönen iki dev rüya balığı. Parry'lenen kuyruk, süpüren bağ, çifte atılış ve köpük halkaları, içine çeken girdap ve sonunda Burçların Yankısı: diğer on bir burcun hamleleri."],
		"creatures": {
			"shade": [["Dream Koi", "Rüya Balığı"], ["A claw and an arrow-straight dart.", "Pençe ve ok gibi düz bir atılış."]],
			"caster": [["Siren", "Deniz Kızı"], ["Her song pulls you in while foam bursts at her feet. Swim away.", "Şarkısıyla seni kendine çeker, ayağının dibinde köpük patlar. Uzaklaş."]],
			"leaper": [["Sea Horse", "Deniz Atı"], ["Blows rings of foam bubbles.", "Köpük baloncukları üfler."]],
			"brute": [["Leviathan Spawn", "Leviatan Yavrusu"], ["A heavy claw and a wave from its tail.", "Ağır pençe ve kuyruğuyla dalga."]],
		},
	},
}


static func t(pair: Array) -> String:
	var GD = load("res://scripts/game_data.gd")
	return String(pair[1]) if String(GD.lang) == "tr" else String(pair[0])


static func defeated(sg: String) -> bool:
	var GD = load("res://scripts/game_data.gd")
	match sg:
		"aries": return GD.aries_defeated
		"taurus": return GD.taurus_defeated
		"gemini": return GD.gemini_defeated
		"cancer": return GD.cancer_defeated
		"leo": return GD.leo_defeated
		"virgo": return GD.virgo_defeated
		"libra": return GD.libra_defeated
		"scorpio": return GD.scorpio_defeated
		"sagittarius": return GD.sagittarius_defeated
		"capricorn": return GD.capricorn_defeated
		"aquarius": return GD.aquarius_defeated
		"pisces": return GD.pisces_defeated
	return false


## Bölgeye girildi mi (eski kayıtlarda: boss'u yenilmişse de girilmiş sayılır)
static func visited(sg: String) -> bool:
	var GD = load("res://scripts/game_data.gd")
	return bool(GD.almanac.get("zone:" + sg, 0)) or defeated(sg)


static func kills(sg: String, kind: String) -> int:
	var GD = load("res://scripts/game_data.gd")
	return int(GD.almanac.get(sg + ":" + kind, 0))


static func note(key: String) -> void:
	var GD = load("res://scripts/game_data.gd")
	GD.almanac[key] = int(GD.almanac.get(key, 0)) + 1


## Açılmış kayıt sayısı / toplam (her burç: mit + boss + 4 yaratık = 6)
static func progress() -> Vector2i:
	var n := 0
	for s in SIGNS:
		if visited(s):
			n += 1
		if defeated(s):
			n += 1
		for k in KINDS:
			if kills(s, k) > 0:
				n += 1
	return Vector2i(n, SIGNS.size() * 6)
