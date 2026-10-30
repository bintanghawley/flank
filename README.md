# FLANK

**Flank** adalah prototipe game RPG aksi taktis 2D dengan perspektif *top-down* yang dikembangkan menggunakan Godot Engine untuk tugas proyek inkubasi sekolah.

Dalam game ini, pemain mengendalikan sebuah regu (*party*) beranggotakan empat hero yang terdiri atas dua Archer dan dua Mage. Pemain mengendalikan satu **Leader** secara langsung, sementara tiga **Follower** bergerak mengekor di belakang atau bertempur secara mandiri sesuai perintah yang diberikan. Melalui kombinasi tombol, pemain dapat berganti Leader secara instan, mengatur formasi barisan, melancarkan serangan jarak jauh terarah, serta mengeksekusi skill khusus berbasis area (AoE).

---

## Fitur Utama

- **Sistem Party Empat Hero:** Regu beranggotakan dua Archer dan dua Mage (`Archer_1`, `Mage_1`, `Archer_2`, `Mage_2`) dengan penonaktifan tabrakan fisik antarkarakter (*collision exception*) agar anggota regu tidak saling mendorong atau menghalangi pergerakan.
- **Pergantian Leader dan Kamera:** Pengalihan kendali aktif secara instan ke hero mana pun dalam regu (melalui tombol `Tab` atau angka `1`–`4`), dengan kamera yang mengikuti posisi hero aktif secara halus (*position smoothing*).
- **Formasi Breadcrumb Queue & Cascade Swap 180°:** Follower berbaris rapi mengikuti riwayat jejak langkah Leader (*breadcrumbs*), dilengkapi mekanisme pembalikan antrean estafet 180° (*cascade swap*) agar formasi langsung tertata ulang saat berputar balik.
- **Perintah FOLLOW dan ATTACK:** Pengendalian perilaku regu secara cepat antara mode **Ikuti (FOLLOW)** (tombol `C`, menjaga follower tetap dalam barisan dan menahan tembakan) serta mode **Serang (ATTACK)** (tombol `V`, mengizinkan follower keluar barisan untuk menyerang musuh di sekitar secara mandiri).
- **Serangan Dasar, Fire Rate, & Kecepatan Proyektil:** Serangan jarak jauh terarah melalui klik kiri—panah lurus untuk Archer dan bola sihir (*magic bolt*) untuk Mage. Frekuensi tembakan dasar (*basic attack fire rate*) diselaraskan penuh antara karakter terkendali, follower, dan musuh archer: Archer (terkendali dan follower) serta musuh archer memiliki jeda tembakan 1.4 detik, sedangkan Mage (terkendali dan follower) memiliki jeda 1.5 detik. Kecepatan proyektil panah adalah 580 px/s (Archer dan musuh archer), sedangkan kecepatan proyektil bola sihir Mage adalah 500 px/s.
- **Skill Charged Line Snipe dan Meteor Strike:**
  - **Archer:** *Charged Line Snipe* dengan indikator garis elastis, melepaskan serangan berdaya rusak area berbentuk garis lurus (hingga 3 kali tembakan dalam jendela waktu 10 detik).
  - **Mage:** *Meteor Strike* dengan indikator lingkaran area pada posisi kursor mouse, memanggil proyektil meteor yang jatuh dari langit dan menghasilkan ledakan area berdaya rusak tinggi.
- **Sistem Combat, Damage, Kematian, dan Respawn:** Deteksi ancaman musuh (*aggro*) berbasis area pandang kamera (*viewport*), status patroli dan pengejaran musuh, pengurangan bar darah (*health*), efek dorongan fisik (*knockback*), serta siklus *respawn* otomatis saat unit gugur (3 detik untuk hero, 4 detik untuk musuh).

> *Catatan: Flank masih berada pada tahap prototipe awal. Fitur-fitur di atas adalah sistem yang telah terbukti berfungsi dalam skenario pengujian awal yang telah dilakukan; pengujian menyeluruh terhadap kasus ekstrem (edge cases) dan keseimbangan permainan masih memerlukan pengujian lanjutan.*

---

## Kontrol Permainan

| Input | Fungsi |
|---|---|
| `W`, `A`, `S`, `D` / Tombol Panah | Menggerakkan Leader aktif |
| `Shift` | Sprint (meningkatkan kecepatan dari konstanta dasar 128 px/s menjadi 220 px/s pada kode sumber, disertai efek debu) |
| `Tab` | Mengganti Leader aktif secara berurutan (1 → 2 → 3 → 4 → 1) |
| `1`–`4` | Memilih Leader aktif secara langsung (1: Archer 1, 2: Mage 1, 3: Archer 2, 4: Mage 2) |
| `C` | Perintah Ikuti (FOLLOW): merapatkan formasi regu dan menahan tembakan |
| `V` | Perintah Serang (ATTACK): mengizinkan follower bertempur secara mandiri |
| Klik Kiri | Serangan dasar ke arah kursor mouse (panah biasa untuk Archer, bola sihir untuk Mage) |
| `E` | Mengaktifkan mode skill khusus untuk karakter aktif |

---

## Teknologi yang Digunakan

- **Godot Engine:** Proyek dikonfigurasi untuk Godot Engine 4 (file `project.godot` mencantumkan feature tag `"4.7"`). Pengujian sebelumnya dilakukan menggunakan Godot Engine v4.7.2-stable Win64 dengan renderer Forward+. Kompatibilitas terhadap versi engine lain belum diverifikasi.
- **GDScript:** Bahasa pemrograman utama yang digunakan untuk seluruh logika permainan.
- **Rendering 2D & Y-Sorting:** Tampilan grafis 2D dengan pengaturan pengurutan kedalaman (*Y-sorting*) dan konfigurasi driver Direct3D 12 di Windows (`rendering_device/driver.windows="d3d12"`).
- **Godot 2D Physics:** Sistem fisika 2D bawaan Godot (Collision Layer 1 digunakan untuk rintangan dunia, dinding, dan pembatas map; tabrakan antar-hero dinonaktifkan melalui kode).
- **Format Scene Godot 4 & TileMapLayer:** Seluruh scene menggunakan format scene Godot 4 (`format=4`), dengan peta lingkungan dibangun menggunakan node modern `TileMapLayer`.

---

## Persyaratan dan Cara Menjalankan Proyek

Berikut adalah panduan untuk mengunduh, membuka, dan menjalankan proyek Flank di perangkat lokal Anda.

### Persyaratan Sistem

- **Godot Engine 4:** Proyek telah diuji menggunakan Godot Engine v4.7.2-stable Win64 (file `project.godot` mencantumkan feature tag `"4.7"`). Kompatibilitas terhadap versi engine lain belum diverifikasi.
- **Git:** Terpasang untuk melakukan *clone* repositori.

### Langkah Menjalankan Proyek

1. **Clone repositori:**
   ```bash
   git clone https://github.com/bintanghawley/flank.git
   cd flank
   ```

2. **Buka melalui Godot Project Manager:**
   - Jalankan Godot Engine hingga jendela Project Manager terbuka.
   - Klik tombol **Import** pada menu utama.
   - Klik **Browse**, arahkan ke folder repositori `flank` hasil *clone*, lalu pilih file `project.godot`.
   - Klik tombol **Import & Edit** untuk membuka proyek di dalam editor.

3. **Jalankan Main Scene:**
   - Tekan tombol `F5` pada keyboard (atau klik ikon **Play** di pojok kanan atas editor Godot).
   - Editor akan secara otomatis memuat dan menjalankan scene utama permainan (`res://scene/game.tscn`).

---

## Struktur Direktori

```text
flank/
├── .agents/skills/flank-godot-workflow/  # Prosedur kerja pengembangan dan pengujian agen Antigravity
├── assets/                               # Aset visual permainan (karakter, partikel, proyektil, tileset)
│   ├── characters/                       # Animasi 4-arah untuk Archer dan Mage
│   ├── particles/                        # Efek debu lari dan partikel benturan
│   ├── projectile/                       # Sprite anak panah dan proyektil sihir
│   ├── skills/                           # Indikator bidikan dan tekstur efek skill khusus
│   └── tileset/                          # Spritesheet lingkungan 16px SunnySide World
├── scene/                                # Scene Godot (.tscn) dan script logika (.gd)
│   ├── effect/                           # Efek visual mandiri (run_dust)
│   ├── enemy/                            # Scene musuh dan script AI tempur
│   ├── player/                           # Controller karakter Archer dan Mage
│   ├── projectile/                       # Entitas proyektil dan efek area
│   ├── world/                            # Peta TileMapLayer (map_region_1.tscn)
│   ├── game.gd                           # Controller utama regu, kamera, dan pembatas map
│   └── game.tscn                         # Scene utama (titik masuk game)
├── PROJECT_CONTEXT.md                    # Dokumentasi komprehensif arsitektur dan konteks teknis
├── README.md                             # Gambaran umum proyek dan panduan pengenalan
└── project.godot                         # File konfigurasi utama Godot Engine
```

---

## Status Pengembangan

Flank saat ini berstatus sebagai prototipe pada tahap pengembangan awal.

### Fitur yang Berhasil dalam Pengujian Awal

Sistem-sistem berikut telah berhasil dijalankan dalam skenario pengujian awal yang telah dilakukan (pengujian belum mencakup seluruh kemungkinan *edge case*):
- **Sistem Party Empat Hero:** Pergerakan empat karakter dalam satu barisan dengan pengecualian tabrakan fisik antarkarakter.
- **Pergantian Leader & Kamera:** Pergantian kendali aktif antarhero secara instan melalui tombol `Tab` atau angka `1`–`4`, disinkronkan dengan pergerakan kamera halus.
- **Formasi Breadcrumb Queue & Cascade Swap 180°:** Riwayat langkah kaki tercatat rapi dan formasi follower berputar balik secara estafet saat berbalik arah.
- **Perintah FOLLOW dan ATTACK:** Transisi perilaku antara merapatkan barisan dan menahan tembakan (tombol `C`) serta bertarung mandiri di luar barisan (tombol `V`).
- **Serangan Jarak Jauh & Skill Khusus:** Serangan panah Archer dan bola sihir Mage ke arah kursor mouse, serta eksekusi skill area *Charged Line Snipe* dan *Meteor Strike*.
- **Siklus Tempur Musuh & Respawn:** Deteksi musuh dalam viewport kamera, pengurangan darah saat terkena serangan, efek knockback, transisi kematian, dan kemunculan kembali karakter secara otomatis.

### Keterbatasan dan Pekerjaan yang Ditunda

Fitur dan perbaikan berikut sengaja ditunda dari lingkup pengembangan saat ini dan **bukan** merupakan pekerjaan yang sedang aktif dikerjakan:
- **Penyempurnaan AI Musuh dan Navigasi Flanking:** Algoritma raycasting untuk menghindari rintangan lingkungan dan penentuan titik pandu (*waypoints*) di sekitar dinding masih memerlukan perbaikan navigasi, namun sengaja ditunda.
- **Refactoring Base Character:** Penggabungan duplikasi kode antara `player_archer.gd` dan `player_mage.gd` ke dalam satu kelas dasar bersama (*base class*) telah dicatat sebagai *technical debt* dan sengaja ditunda.

### Fitur yang Belum Diimplementasikan

Fitur-fitur berikut belum tersedia di dalam repositori dan direncanakan untuk tahap pengembangan berikutnya:
- **UI / HUD Pemain:** Tampilan bar HP anggota party di layar, indikator cooldown skill secara visual, dan ikon status perintah regu.
- **Sistem Audio:** Musik latar belakang (BGM) dan efek suara (SFX tembakan panah, sihir, impak serangan, ledakan, dan langkah kaki).
- **Menu Permainan:** Menu Pause, layar Game Over, serta layar Restart.
- **Variasi Musuh:** Jenis musuh baru dengan variasi visual dan pola serangan yang berbeda.
- **Export Presets:** Konfigurasi `export_presets.cfg` untuk mengekspor build permainan menjadi aplikasi mandiri (*executable*).
