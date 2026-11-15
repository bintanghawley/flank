# Flank

**Flank** adalah prototipe game action RPG taktis 2D dengan perspektif *top-down* yang dikembangkan menggunakan Godot Engine 4 untuk proyek inkubasi game.

Dalam game ini, pemain mengendalikan sebuah regu (*party*) beranggotakan empat hero: **Knight**, **Bandit**, **Archer**, dan **Mage**. Pemain mengendalikan satu **Leader** secara langsung, sementara tiga **Follower** bergerak mengekor di belakang barisan atau bertempur mandiri sesuai perintah yang diberikan. Pemain dapat berganti Leader secara instan, mengatur formasi pergerakan, mengeksekusi serangan dasar terarah, serta melancarkan skill khusus dengan fungsi taktis yang berbeda secara *real-time*.

> **Status Proyek:** Flank saat ini berada pada tahap pengembangan prototipe awal (*early prototype*). Mekanisme inti permainan telah diimplementasikan dan beberapa skenario gameplay telah berhasil diuji. Pengembangan serta pengujian lanjutan masih berlangsung.

---

## Gambaran Permainan

Flank menggabungkan mekanika aksi *real-time* dengan manajemen regu taktis:

- **Sistem Party Empat Hero:** Regu beranggotakan Knight (`Knight_1` / Arthur), Bandit (`Bandit_1` / Hellene), Archer (`Archer_1` / Anastasya), dan Mage (`Mage_1` / Magnus). Pengecualian tabrakan (*collision exception*) diterapkan antaranggota party sehingga mereka tidak saling berkolisi melalui sistem fisika bawaan Godot. Pengaturan jarak antarunit tetap dilakukan secara terpisah menggunakan sistem separasi dinamis. Jika hero gugur, sistem secara otomatis mengalihkan kendali dari Leader yang mati ke anggota yang masih hidup, dan hero akan respawn secara dinamis di dekat Leader aktif dengan perlindungan invulnerability awal 1.5 detik.
- **Pergantian Leader & Kamera:** Kendali aktif dapat dipindahkan saat memasuki pertempuran arena menggunakan tombol `Tab`, `Q`, angka `1`–`4` (auto-switch & cast skill), maupun klik langsung pada kartu potret hero di HUD (dinonaktifkan saat mode eksplorasi tanpa musuh). Penggantian leader di luar pertempuran maupun saat bertempur juga dapat dilakukan melalui menu Buku/Jeda (tab Informasi -> Party Slots), di mana pergantian leader di mode eksplorasi secara otomatis memindahkan posisi dan arah karakter baru tepat ke koordinat karakter yang sedang dimainkan secara mulus tanpa teleportasi. Kamera permainan diatur dengan zoom `0.65x` dan secara otomatis mengikuti posisi Leader aktif dengan pergerakan yang halus (*position smoothing*).
- **Formasi Breadcrumb Queue, Navigasi Sudut & Cascade Swap 180°:** Saat bergerak, Follower mengikuti jejak langkah kaki Leader (*breadcrumbs* hingga 300 titik) secara teratur. Ketika Leader berputar balik 180°, formasi antrean follower langsung berbalik secara estafet (*cascade swap*) agar regu tidak bertumpuk. Follower juga dilengkapi algoritma navigasi sudut dinamis (*Dynamic Corner Waypoint*) yang mengevaluasi garis pandang (*LoS*) dan melipir sudut bangunan map baru secara cerdas, didukung *corner-slide assist* serta proteksi *anti-stuck* (teleportasi catch-up otomatis jika terpisah > 650 px).
- **Sistem Pertarungan Party Otonom:**
  - Saat berada di luar pertempuran (mode eksplorasi), Follower merapatkan barisan mengekor di belakang Leader (*breadcrumbs*).
  - Saat memasuki pertempuran arena, Follower secara otonom bergerak aktif dan menyerang musuh terdekat dalam jangkauan tempur masing-masing tanpa memerlukan komando manual.
- **Gameplay HUD & Menu Jeda (Pause Menu):** Antarmuka in-game lengkap berbasis CanvasLayer yang menyajikan 4 kartu status party dengan bilah HP real-time, indikator status KO (potret meredup gelap dan label nama berubah menjadi teks merah "KO"), bar 4 skill dengan countdown cooldown berpresisi satu desimal (`"%.1f"`), balon ucapan dinamis di ruang layar (*screen-space*), banner lokasi, prompt kontrol, serta overlay Menu Jeda (*Pause Menu*) via tombol `ESC` atau ikon pause untuk melanjutkan atau kembali ke Start Menu.
- **Start Menu Interaktif & Transisi Sinematik:** Permainan dimulai dari layar Start Menu interaktif dengan visual parallax dinamis (awan langit dan rumput berjalan), penempatan teks tombol yang seimbang di area rumput hijau, animasi berjalan di tempat empat hero party, pemilihan tombol interaktif, efek kilau bintang (*sword glint sparkle*) di ujung pedang Knight, dan transisi *Circular Mask* (Iris Wipe) yang menutup ke ujung pedang Knight sementara kawan-kawan party beralih ke animasi `idle_w` sebelum masuk ke arena pertempuran.
- **Pertarungan Real-Time & Serangan Dasar:** Serangan dasar diarahkan langsung ke posisi kursor mouse melalui klik kiri, yang dinonaktifkan saat mode eksplorasi (di luar arena / tidak ada musuh) dan diaktifkan secara penuh tanpa batasan jarak saat memasuki arena tempur:
  - **Knight:** Tebasan pedang jarak dekat (*melee slash*) dengan area sapuan busur di depan karakter serta dorongan hentakan halus ke depan (*attack lunge* 140 px/s terurai halus).
  - **Bandit:** Tebasan ganda belati (*Double Slash Dagger*) secara ritmis untuk setiap siklus serangan. Dilengkapi kemampuan pasif *Out-of-Combat Ambush Lunge* setelah beberapa detik tanpa pertempuran: serangan pembuka memperoleh jangkauan serbu luas, Bandit meluncur cepat ke target, menghasilkan bonus damage pembuka, dan diperkuat perlindungan *Super Armor*.
  - **Archer:** Tembakan anak panah lurus terarah dengan kecepatan proyektil stabil tanpa batasan jarak.
  - **Mage:** Tembakan bola sihir (*magic bolt*) jarak jauh yang dilepaskan tepat dari ujung tongkat sihir ke arah kursor tanpa batasan jarak.
- **Skill Khusus Hero (`E`):** Seluruh skill khusus hero hanya dapat diaktifkan saat berada dalam pertempuran arena (dinonaktifkan saat mode eksplorasi tanpa musuh):
  - **Knight — *Shield Guard*:** Hanya dapat diaktifkan saat Knight menjadi Leader aktif (cooldown 6.0 detik). Knight merapalkan perisai pelindung serentak yang melindungi seluruh anggota party dari 100% damage serangan musuh selama 3.5 detik, dan efek perisai tetap bertahan pada masing-masing hero saat pemain berganti karakter hingga durasinya berakhir.
  - **Bandit — *Dash, Knockup & Triple Slash*:** Hanya dapat diaktifkan saat Bandit menjadi Leader aktif. Melesat cepat ke arah kursor mouse dengan proteksi benturan dinding rintangan solid (berhenti bersih disertai getaran kamera), berhenti seketika saat menabrak musuh pertama. Musuh yang tertabrak terangkat ke udara (*knockup*) serta terkena stun singkat, lalu seketika dieksekusi dengan kombo 3 tebasan beruntun disertai efek visual khusus *triple slash* dan perlindungan *Super Armor* (cooldown 5.0 detik).
  - **Archer — *Charged Line Snipe*:** Mengaktifkan mode bidik garis elastis. Pemain menahan klik kiri untuk mengisi daya tembakan dan melepasnya untuk melancarkan tembakan garis lurus berdaya rusak area (linear AoE) yang dapat mengenai beberapa musuh di sepanjang jalur bidikan, tetapi tidak menembus dinding atau geometri lingkungan (dapat ditembakkan hingga 3 kali dalam jendela waktu 10 detik). Tekan kembali tombol `E` saat Archer berada dalam state `READY` untuk keluar dari mode bidik. Klik kanan saat pengisian daya berlangsung (`STARTING` atau `CHARGING`) akan membatalkan pengisian dan mengembalikan skill ke state `READY`. Klik kanan saat berada dalam state `READY` juga dapat digunakan untuk keluar dari mode bidik.
  - **Mage — *Meteor Strike*:** Mengaktifkan reticle lingkaran pada posisi kursor mouse dengan batasan radius casting maksimum (480 px dari Magnus). Klik kiri memanggil proyektil meteor yang jatuh dari langit dan meledak menghasilkan kerusakan area (*AoE*). Klik kanan untuk membatalkan reticle bidikan.
- **Sistem Musuh, Hurtbox Menyeluruh & Siklus Tempur:**
  - Seluruh karakter hero dan musuh dilengkapi node `Hurtbox` berukuran penuh (mencakup kepala hingga kaki) untuk registrasi tabrakan proyektil yang presisi pada seluruh permukaan visual sprite.
  - AI musuh dilengkapi status patroli acak (*idle patrol*) dan pengejaran (*chase*) saat mendeteksi pemain.
  - Musuh memiliki serangan kontak fisik (damage 1) serta serangan jarak jauh berupa tembakan panah yang membidik ke bagian tengah tubuh hero (damage 1, kecepatan 580 px/s, jeda tembak 1.4 detik).
  - Dilengkapi tampilan bar darah (*health bar*) di atas kepala, sistem prioritas ancaman (*threat target priority*), dan kemunculan kembali (*respawn*) dinamis setelah gugur (4 detik untuk musuh, 3 detik untuk hero).
  - Efek dorongan fisik (*knockback*) dinonaktifkan pada hero pemain (Knight, Archer, Mage) saat terkena damage agar kontrol pergerakan tetap responsif (sedangkan Bandit mempertahankan dorongan knockback terukur di luar status Super Armor). Efek knockback yang diterima musuh mengikuti karakteristik masing-masing serangan pemain; beberapa serangan tidak memberikan dorongan knockback.
- **Tata Suara & SFX Responsif:** Dilengkapi sistem efek suara (*one-shot AudioStreamPlayer*) terorganisir yang mencakup seluruh aksi: suara serangan dan skill 4 hero, langkah lari sprint, suara terkena damage, gugur, dan respawn hero maupun musuh, komando taktis party, hingga respon tombol dan transisi visual menu.
- **Kursor Kustom & Animasi Umpan Balik Klik (*Tactile Click Feedback*):** Menggunakan kursor mouse kustom pixel art panah keemasan proporsional (15x20 px) berbasis API kursor perangkat keras (*zero input lag*) dengan Autoload Singleton `CursorManager`. Saat diklik, kursor memberikan respon visual taktis berupa pergeseran maju halus 1 px ke arah target tanpa menyusut, perubahan warna menggelap terukur yang hangat (terracotta/chestnut), jeda penahanan visual minimum (0.08 detik) untuk ketukan kilat, dan efek riak lingkaran warna dinamis pada lapisan kanvas teratas yang berpusat presisi di ujung panah.

---

## Fitur Permainan

### Fitur yang Sudah Diimplementasikan (Teruji pada Skenario Dasar)
- [x] Titik masuk permainan: Start Menu interaktif (latar belakang parallax bergerak kontinu, animasi berjalan empat hero party, interaksi tombol dengan font Beholden, efek kilau bintang kuning emas di ujung pedang Knight, dan transisi circular mask / iris wipe).
- [x] Efek pembukaan circular mask (iris open) saat memasuki arena gameplay.
- [x] Kontrol regu 4 hero (Knight, Bandit, Archer, Mage) dengan pengecualian tabrakan fisik antaranggota party.
- [x] Pergantian Leader instan secara siklis (`Tab`) maupun langsung (`1`, `2`, `3`, `4`).
- [x] Pelacakan kamera halus (*position smoothing*) yang terikat pada Leader aktif.
- [x] Sistem pergerakan formasi barisan (*breadcrumb queue*) dan pembalikan barisan 180° (*cascade swap*).
- [x] Sistem pertarungan regu otonom: Follower berbaris rapi saat eksplorasi dan bertarung mandiri saat pertempuran arena.
- [x] Serangan dasar terarah mouse (tebasan pedang Knight, belati cepat Bandit, panah Archer, bola sihir Mage) dengan sistem gating mode tempur dan tanpa batasan jarak serang.
- [x] Skill khusus per kelas hero (*Shield Guard*, *Triple Slash*, *Charged Line Snipe*, *Meteor Strike*).
- [x] AI musuh dengan status patroli, pengejaran (*aggro/chase*), serangan kontak, dan tembakan panah.
- [x] Sistem kesehatan, bilah darah musuh, durasi kebal singkat pasca-hit (*invulnerability frame*), dan siklus respawn otomatis.
- [x] Efek partikel lari (*run dust*) dinamis saat sprint.
- [x] Peta lingkungan kerajaan baru (`kingdom_map.tscn`) berbasis `Sprite2D` resolusi tinggi dengan 130+ batas collision fisik `StaticBody2D` pada Collision Layer 1 (dukungan fallback `TileMapLayer` tetap dipertahankan pada controller batas kamera).
- [x] Navigasi sudut dinamis (*Dynamic Corner Waypoint*), *corner-slide assist*, dan proteksi *anti-stuck* follower pada geometri bangunan peta baru.
- [x] Hurtbox proyektil menyeluruh (*head-to-toe*) pada seluruh hero dan musuh, serta bidikan panah musuh terpusat ke badan hero.
- [x] Sistem kematian hero, auto-switch leader saat KO, respawn dinamis di dekat leader aktif dengan i-frame 1.5 detik, dan indikator visual KO pada HUD.
- [x] Sistem efek suara (SFX) gameplay lengkap: suara serangan dan skill 4 hero, langkah kaki sprint, hit/death/respawn hero & musuh, komando taktis party, dan interaksi UI.
- [x] Gameplay HUD in-game: kartu status 4 hero dengan bilah darah real-time, penanda leader aktif, indikator status KO, bar 4 skill dengan countdown cooldown berpresisi satu desimal (`"%.1f"`), balon ucapan komando di atas kepala leader, dan banner lokasi.
- [x] Menu Jeda (Pause Menu) overlay in-game: toggle via tombol ESC atau ikon pause, dengan penghentian game (`get_tree().paused`) dan opsi Lanjutkan atau Kembali ke Start Menu.
- [x] Sistem kursor kustom pixel art dengan animasi *tactile click feedback* (iluminasi hangat menggelap terukur saat ditekan, gerak maju halus 1 px ke target, dan riak bayangan berpusat presisi pada ujung panah saat diklik) serta respon *zero lag* menyeluruh di seluruh layar game.

### Fitur yang Sedang Dikembangkan & Direncanakan
- [ ] Implementasi prefab dan AI Bandit sebagai musuh, terpisah dari karakter Bandit yang sudah dapat dimainkan (aset sprite telah tersedia di `assets/characters/bandit/`).
- [ ] Implementasi sistem dialog interaktif penuh dan kisi inventaris barang (aset grafis telah disiapkan di `assets/ui/gameplay/`).
- [ ] Musik latar permainan (BGM) untuk layar menu dan arena gameplay.
- [ ] Menu permainan lanjutan (Options Menu, Save/Load, Credits Screen).
- [ ] Variasi jenis musuh baru (monster non-humanoid pada folder cadangan `assets/enemies/`).
- [ ] Penyempurnaan navigasi flanking berbasis raycast dan waypoint pada follower ranged (Archer, Mage) dan AI musuh, terutama untuk penanganan rintangan kompleks dan optimasi jalur pergerakan.
- [ ] Konfigurasi preset ekspor aplikasi mandiri (*executable*).

---

## Kontrol Permainan

| Tombol / Input | Fungsi | Cara Penggunaan |
| :--- | :--- | :--- |
| `W`, `A`, `S`, `D` / Panah | Gerak Karakter | Menggerakkan Leader aktif ke 8 arah |
| `Shift` (Tahan) | Sprint | Meningkatkan kecepatan jalan (128 px/s → 220 px/s) disertai efek debu |
| `Tab` / `Q` | Ganti Karakter Siklis | Berganti Leader secara berurutan (Knight → Bandit → Archer → Mage → Knight) |
| `1`, `2`, `3`, `4` | Auto-Switch & Skill Hero | Berganti kendali langsung ke hero terkait sekaligus melancarkan skill-nya (1: Arthur, 2: Hellene, 3: Anastasya, 4: Magnus; diabaikan jika hero berstatus KO) |
| `ESC` / Klik Ikon Pause | Buka / Tutup Pause Menu | Menghentikan sementara permainan dan menampilkan panel jeda (Lanjutkan / Menu Utama) |
| `B` | Buka / Tutup Inventori | Membuka layar tas inventori item party |
| `C` | Buka / Tutup Info Karakter | Membuka layar statistik dan biografi karakter hero party |
| `J` | Buka / Tutup Jurnal Misi | Membuka layar pelacak jurnal misi aktif |
| `Klik Kiri` (Kartu Party HUD) | Ganti Leader Langsung | Klik pada kartu potret hero di HUD kiri bawah untuk berpindah kendali (diabaikan jika hero berstatus KO) |
| `Klik Kiri` (Slot Skill HUD) | Eksekusi Skill | Klik pada slot skill di HUD kanan bawah untuk melancarkan skill hero terkait (diabaikan jika hero berstatus KO) |
| `Klik Kiri` (Di Arena Dunia) | Serangan Dasar | Menyerang ke arah kursor mouse (tebasan Knight, ayunan ganda Bandit, panah Archer, sihir Mage) |
| `E` | Skill Khusus Leader | Melancarkan skill khusus dari karakter yang sedang aktif menjadi Leader |
| `Klik Kiri` (Saat Mode Skill) | Eksekusi Skill Bidik | **Archer:** Tahan klik kiri untuk mengisi daya dan lepaskan untuk meluncurkan panah<br>**Mage:** Klik pada area sasaran untuk menjatuhkan meteor |
| `Klik Kanan` (Saat Mode Skill) | Batal / Keluar Skill | **Archer:** Membatalkan pengisian daya / keluar dari mode bidik<br>**Mage:** Membatalkan reticle sasaran meteor |

---

## Teknologi yang Digunakan

- **Game Engine:** Godot Engine 4 (konfigurasi proyek menggunakan feature tag `"4.7"`, diuji pada Godot Engine v4.7.2-stable Win64).
- **Titik Masuk Utama (Main Scene):** `res://scene/ui/menus/start_menu.tscn` (beralih ke scene arena `res://scene/game.tscn` melalui transisi circular mask).
- **Bahasa Pemrograman:** GDScript.
- **Rendering:** Forward+ 2D dengan konfigurasi driver Direct3D 12 di Windows (`rendering_device/driver.windows="d3d12"`).
- **Fisika 2D:** Godot 2D Physics bawaan (`CharacterBody2D`, `Area2D`, dengan `motion_mode = MOTION_MODE_FLOATING`).
- **Format Scene & Map:** Format scene Godot 4 (`format=3`), dengan peta dunia arena kerajaan berbasis prefab `kingdom_map.tscn` (layer visual `Sprite2D` resolusi tinggi dan collider fisik `StaticBody2D` pada Collision Layer 1) serta dukungan fallback `TileMapLayer` pada controller batas kamera.

---

## Cara Menjalankan Proyek

Berikut adalah langkah-langkah untuk mengunduh, membuka, dan menjalankan proyek Flank:

1. **Clone Repositori:**
   ```bash
   git clone https://github.com/bintanghawley/flank.git
   cd flank
   ```

2. **Buka Melalui Godot Engine:**
   - Jalankan **Godot Engine 4** di komputer Anda.
   - Pada jendela **Project Manager**, klik tombol **Import**.
   - Klik **Browse**, arahkan ke folder repositori `flank` yang baru di-clone, lalu pilih file `project.godot`.
   - Klik **Import & Edit** untuk membuka proyek ke dalam editor.

3. **Tunggu Proses Impor Selesai:**
   - Saat pertama kali dibuka, editor Godot akan secara otomatis memindai dan mengimpor aset serta memperbarui atau membuat file metadata (`.import`) yang diperlukan.

4. **Jalankan Permainan:**
   - Tekan tombol **F5** pada keyboard, atau klik tombol **Play** di pojok kanan atas editor.
   - Editor akan memuat scene utama: `res://scene/ui/menus/start_menu.tscn`.
   - Klik tombol **Mulai Permainan** pada menu untuk masuk ke scene arena pertempuran (`res://scene/game.tscn`) melalui transisi circular mask.

---

## Struktur Direktori

Berikut adalah struktur direktori utama repositori Flank:

```text
flank/
├── .agents/                               # Konfigurasi agen AI dan workflow proyek
├── assets/                                # Seluruh aset visual, audio, dan font mentah
│   ├── audio/                             # Aset suara (BGM & SFX)
│   │   ├── bgm/                           # Musik latar (.gitkeep)
│   │   └── sfx/                           # Efek suara (.wav) terorganisir (characters, enemy, party, ui)
│   ├── characters/                        # Sprite karakter 4-arah (idle, walk, attack, skill)
│   │   ├── archer/                        # Sprite animasi hero Archer
│   │   ├── bandit/                        # Sprite animasi karakter Bandit (hero party & calon musuh)
│   │   ├── knight/                        # Sprite animasi hero Knight
│   │   └── mage/                          # Sprite animasi hero Mage
│   ├── enemies/                           # Folder cadangan musuh non-humanoid di masa depan (.gitkeep)
│   ├── environment/                       # Aset lingkungan & peta kerajaan (kingdom_ground.png, kingdom_structures.png)
│   ├── particles/                         # Tekstur partikel debu lari (dust_puff.png)
│   ├── projectile/                        # Tekstur proyektil panah dan bola sihir
│   ├── skills/                            # Tekstur visual efek skill (Archer, Bandit, Knight, Mage)
│   ├── tileset/                           # Folder cadangan tileset lama (.gitkeep)
│   └── ui/                                # Aset grafis antarmuka mentah dan tipografi
│       ├── fonts/                         # Tipografi pixel (Beholden-Bold.ttf)
│       ├── gameplay/                      # Grafis UI in-game (dialogue, location, party_hud)
│       ├── icons/                         # Ikon-Ikon UI (actions, cursor, skills)
│       └── menus/                         # Grafis menu (character_stats, credits, inventory, options, pause, quests, save_load, start)
├── scene/                                 # Logika kode sumber (GDScript) dan scene Godot (.tscn)
│   ├── effect/                            # Prefab efek visual mandiri (run_dust.tscn/.gd)
│   ├── enemy/                             # Prefab dan AI musuh (enemy.tscn/.gd)
│   ├── player/                            # Controller hero regu (player_archer, player_bandit, player_knight, player_mage)
│   ├── projectile/                        # Proyektil fisik, benturan (impact), dan indikator reticle dunia
│   ├── ui/                                # Implementasi scene Godot UI (menus & gameplay)
│   │   ├── cursor/                        # Autoload controller kursor global & animasi klik (cursor_manager.gd)
│   │   ├── gameplay/                      # Scene UI gameplay (gameplay_hud.tscn / .gd)
│   │   └── menus/                         # Scene UI menu (start_menu.tscn / .gd)
│   ├── world/                             # Peta lingkungan kerajaan (kingdom_map.tscn)
│   ├── game.gd                            # Controller utama party manager, navigasi sudut, kamera, dan transisi iris open
│   └── game.tscn                          # Scene arena gameplay utama (dimuat setelah start menu)
├── PROJECT_CONTEXT.md                     # Dokumentasi arsitektur dan konteks teknis proyek
├── README.md                              # Dokumentasi umum dan panduan pengenalan proyek
└── project.godot                          # Konfigurasi utama Godot Engine
```

> **Catatan Struktur:**  
> - Subfolder dengan penanda `.gitkeep` merupakan struktur hierarki kolaborasi yang telah disiapkan agar siap digunakan saat aset visual atau menu lanjutan ditambahkan oleh tim. File `.gitkeep` pada folder yang telah terisi aset aktif (seperti `assets/audio/sfx/`, subfolder `assets/ui/gameplay/`, `assets/ui/icons/`, `assets/ui/menus/credits/`, `assets/ui/menus/pause_menu/`, `assets/ui/menus/start_menu/`, dan `scene/ui/`) telah dibersihkan.
> - Keberadaan subfolder `scene/ui/gameplay/` kini telah memuat implementasi `gameplay_hud.tscn`, sedangkan subfolder menu lanjutan lainnya disiapkan untuk pengembangan bertahap.
> - Peta arena pertempuran aktif menggunakan prefab `scene/world/kingdom_map.tscn` dengan layer tekstur `assets/environment/map/`, sedangkan `assets/tileset/` bertindak sebagai folder cadangan bertanda `.gitkeep`.
> - Aset sprite Bandit berada di `assets/characters/bandit/`, sedangkan implementasi prefab dan AI Bandit sebagai musuh direncanakan terpisah dari karakter Bandit yang sudah dapat dimainkan.
> - Folder `assets/enemies/` disiapkan sebagai folder cadangan untuk musuh jenis non-humanoid / monster di masa depan.

---

## Status Pengembangan

Flank saat ini berstatus sebagai **prototipe aktif** dalam tahap implementasi awal:
- **Fokus Utama Saat Ini:** Penyempurnaan mekanisme inti regu (*party core loop*), respon tempur real-time, dan pemantapan arsitektur repositori untuk kolaborasi tim.
- **Lingkungan & Peta Permainan:** Map kerajaan baru (`kingdom_map.tscn`) telah selesai diintegrasikan secara penuh dengan aset visual resolusi tinggi (`kingdom_ground.png`, `kingdom_structures.png`) dan 130+ pembatas tabrakan fisik `StaticBody2D` untuk seluruh struktur bangunan.
- **Pekerjaan yang Ditunda Sementara:** Penyempurnaan navigasi flanking berbasis raycast dan waypoint pada follower ranged (Archer, Mage) dan AI musuh masih ditunda (terutama untuk penanganan rintangan kompleks dan optimasi jalur unit), serta evaluasi penggabungan duplikasi kode controller karakter ke dalam satu *base class* bersama (*technical debt*) sengaja ditunda agar fokus pada pengujian stabilitas gameplay.
