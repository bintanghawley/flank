# Flank

**Flank** adalah prototipe game action RPG taktis 2D dengan perspektif *top-down* yang dikembangkan menggunakan Godot Engine 4 untuk proyek inkubasi game.

Dalam game ini, pemain mengendalikan sebuah regu (*party*) beranggotakan empat hero: **Knight**, **Bandit**, **Archer**, dan **Mage**. Pemain mengendalikan satu **Leader** secara langsung, sementara tiga **Follower** bergerak mengekor di belakang barisan atau bertempur mandiri sesuai perintah yang diberikan. Pemain dapat berganti Leader secara instan, mengatur formasi pergerakan, mengeksekusi serangan dasar terarah, serta melancarkan skill khusus pertahanan dan area secara *real-time*.

> **Status Proyek:** Flank saat ini berada pada tahap pengembangan prototipe awal (*early prototype*). Seluruh fitur inti gameplay telah dapat dimainkan dan diuji, sementara antarmuka visual (UI/HUD), tata suara (audio), dan variasi musuh lanjutan sedang dalam tahap persiapan.

---

## Gambaran Permainan

Flank menggabungkan mekanika aksi *real-time* dengan manajemen regu taktis:

- **Sistem Party Empat Hero:** Regu beranggotakan Knight (`Knight_1`), Bandit (`Bandit_1`), Archer (`Archer_1`), dan Mage (`Mage_1`). Tabrakan fisik antar-anggota regu dinonaktifkan (*collision exception*) sehingga pergerakan tetap leluasa tanpa saling dorong atau menghalangi.
- **Pergantian Leader & Kamera:** Kendali aktif dapat dipindahkan secara instan ke hero mana pun menggunakan tombol `Tab` atau angka `1`–`4`. Kamera permainan secara otomatis mengikuti posisi Leader aktif dengan pergerakan yang halus (*position smoothing*).
- **Formasi Breadcrumb Queue & Cascade Swap 180°:** Saat bergerak, Follower mengikuti jejak langkah kaki Leader (*breadcrumbs*) secara teratur. Ketika Leader berputar balik 180°, formasi antrean follower langsung berbalik secara estafet (*cascade swap*) agar regu tidak bertumpuk.
- **Sistem Komando Party (Follow & Attack):**
  - **Mode FOLLOW (`C`):** Follower merapatkan barisan di belakang Leader dan menahan serangan, berfokus penuh pada mobilitas dan reposisi regu.
  - **Mode ATTACK (`V`):** Follower diberi kebebasan untuk keluar dari barisan dan menyerang musuh terdekat dalam jangkauan tempur secara mandiri.
- **Pertarungan Real-Time & Serangan Dasar:** Serangan diarahkan langsung ke posisi kursor mouse melalui klik kiri:
  - **Knight:** Tebasan pedang jarak dekat (*melee slash*) berdaya rusak 2 dengan area sapuan busur di depan karakter.
  - **Bandit:** Tebasan ganda belati (*Double Slash Dagger*) berdaya rusak 2 untuk setiap ayunan (total 4 damage per siklus) dengan jeda serang 0.85 detik. Dilengkapi kemampuan pasif *Out-of-Combat Ambush Lunge* setelah 5 detik tanpa pertempuran: serangan dasar pembuka memperoleh jangkauan *engage* luas (260 px), Bandit meluncur lunge cepat ke target, dan memberikan bonus damage +3 (total 5 damage pembuka) disertai aura visual berpendar.
  - **Archer:** Tembakan anak panah lurus berdaya rusak 1 dengan kecepatan proyektil 580 px/s dan jeda tembak 1.4 detik.
  - **Mage:** Tembakan bola sihir (*magic bolt*) berdaya rusak 1 dengan kecepatan proyektil 500 px/s dan jeda tembak 1.5 detik.
- **Skill Khusus Hero (`E`):**
  - **Knight — *Shield Guard*:** Mengaktifkan perisai pelindung serentak untuk seluruh anggota party selama 3.5 detik (cooldown 6.0 detik). Memberikan kekebalan 100% dari seluruh serangan musuh dan tetap aktif saat pemain berganti karakter.
  - **Bandit — *Dash, Knockup & Triple Slash*:** Meluncur cepat (750 px/s) ke arah kursor mouse dan berhenti seketika saat menabrak musuh pertama. Musuh yang tertabrak terlempar melayang ke udara (*knockup*) serta terkena stun singkat (0.7s), lalu seketika dieksekusi dengan kombo 3 tebasan beruntun berdaya rusak total 6 (2 per hit) dengan efek visual khusus *triple slash* (cooldown 5.0 detik). Hanya dapat diaktifkan saat Bandit menjadi Leader aktif.
  - **Archer — *Charged Line Snipe*:** Mengaktifkan mode bidik garis elastis. Pemain menahan klik kiri untuk mengisi jarak tembak dan melepasnya untuk meluncurkan panah penembus rintangan berdaya rusak area garis lurus (dapat ditembakkan hingga 3 kali dalam jendela waktu 10 detik). Klik kanan untuk membatalkan pengisian daya atau keluar dari mode bidik.
  - **Mage — *Meteor Strike*:** Mengaktifkan reticle lingkaran pada posisi kursor mouse. Klik kiri memanggil proyektil meteor yang jatuh dari langit dan meledak menghasilkan kerusakan area (*AoE*). Klik kanan untuk membatalkan bidikan.
- **Sistem Musuh & Siklus Tempur:**
  - AI musuh dilengkapi status patroli acak (*idle patrol*) dan pengejaran (*chase*) saat mendeteksi pemain.
  - Musuh memiliki serangan kontak fisik (damage 1) serta serangan jarak jauh berupa tembakan panah (damage 1, kecepatan 580 px/s, jeda tembak 1.4 detik).
  - Dilengkapi tampilan bar darah (*health bar*) di atas kepala, sistem prioritas ancaman (*threat target priority*), dan kemunculan kembali (*respawn*) otomatis setelah gugur (4 detik untuk musuh, 3 detik untuk hero).
  - Efek dorongan fisik (*knockback*) dinonaktifkan pada hero pemain saat terkena damage agar kontrol pergerakan tetap responsif, sedangkan musuh tetap menerima dorongan knockback saat terkena serangan pemain.

---

## Fitur Permainan

### Fitur yang Sudah Tersedia (Aktif & Terverifikasi)
- [x] Kontrol regu 4 hero (Knight, Bandit, Archer, Mage) dengan pengecualian tabrakan fisik antarkarakter.
- [x] Pergantian Leader instan secara siklis (`Tab`) maupun langsung (`1`, `2`, `3`, `4`).
- [x] Pelacakan kamera halus (*position smoothing*) yang terikat pada Leader aktif.
- [x] Sistem pergerakan formasi barisan (*breadcrumb queue*) dan pembalikan barisan 180° (*cascade swap*).
- [x] Perintah regu taktis: Mode **FOLLOW** (`C`) dan Mode **ATTACK** (`V`).
- [x] Serangan dasar terarah mouse (tebasan pedang Knight, belati cepat Bandit, panah Archer, bola sihir Mage).
- [x] Skill khusus per kelas hero (*Shield Guard*, *Triple Slash*, *Charged Line Snipe*, *Meteor Strike*).
- [x] AI musuh dengan status patroli, pengejaran (*aggro/chase*), serangan kontak, dan tembakan panah.
- [x] Sistem kesehatan, bilah darah musuh, durasi kebal singkat pasca-hit (*invulnerability frame*), dan siklus respawn otomatis.
- [x] Efek partikel lari (*run dust*) dinamis saat sprint.
- [x] Peta lingkungan menggunakan sistem `TileMapLayer` Godot 4.

### Fitur yang Sedang Dikembangkan & Direncanakan
- [ ] Implementasi prefab dan AI musuh Bandit (aset sprite telah tersedia di `assets/characters/bandit/`).
- [ ] Implementasi antarmuka pengguna visual (UI/HUD: bilah darah anggota party, indikator cooldown skill visual, inventaris, dialog).
- [ ] Tata suara permainan (musik latar/BGM dan efek suara/SFX).
- [ ] Menu permainan (Start Menu, Options, Pause Menu, Save/Load, Credits).
- [ ] Variasi jenis musuh baru (monster non-humanoid pada folder cadangan `assets/enemies/`).
- [ ] Penyempurnaan navigasi musuh (*raycasting flanking* dan penghindaran rintangan dinamis).
- [ ] Konfigurasi preset ekspor aplikasi mandiri (*executable*).

---

## Kontrol Permainan

| Tombol / Input | Fungsi | Cara Penggunaan |
| :--- | :--- | :--- |
| `W`, `A`, `S`, `D` / Panah | Gerak Karakter | Menggerakkan Leader aktif ke 8 arah |
| `Shift` (Tahan) | Sprint | Meningkatkan kecepatan jalan (128 px/s → 220 px/s) disertai efek debu |
| `Tab` | Ganti Karakter Siklis | Berganti Leader secara berurutan (Knight → Bandit → Archer → Mage → Knight) |
| `1`, `2`, `3`, `4` | Ganti Karakter Langsung | Memilih Leader spesifik (1: Knight, 2: Bandit, 3: Archer, 4: Mage) |
| `C` | Perintah FOLLOW | Menginstruksikan regu untuk merapatkan barisan dan menahan tembakan |
| `V` | Perintah ATTACK | Mengizinkan follower bertarung mandiri menyerang musuh terdekat |
| `Klik Kiri` (Tap / Tahan) | Serangan Dasar | Menyerang ke arah kursor mouse (tebasan Knight, ayunan ganda Bandit, panah Archer, sihir Mage) |
| `E` | Skill Khusus | **Knight:** Langsung merapalkan perisai *Shield Guard* (durasi 3.5s, cooldown 6s)<br>**Bandit:** Melesat dash menabrak musuh, knockup & stun musuh, lalu melancarkan combo 3 tebasan *Triple Slash* (cooldown 5s)<br>**Archer:** Masuk/keluar mode bidik *Charged Line Snipe*<br>**Mage:** Masuk mode bidik *Meteor Strike* |
| `Klik Kiri` (Saat Mode Skill) | Eksekusi Skill | **Archer:** Tahan untuk mengisi jarak tembak, lepas untuk menembak<br>**Mage:** Klik pada area sasaran untuk menjatuhkan meteor |
| `Klik Kanan` (Saat Mode Skill) | Batal / Keluar Skill | **Archer:** Membatalkan pengisian daya atau keluar dari mode bidik<br>**Mage:** Membatalkan reticle sasaran meteor |

---

## Teknologi yang Digunakan

- **Game Engine:** Godot Engine 4 (konfigurasi proyek menggunakan feature tag `"4.7"`, diuji pada Godot Engine v4.7.2-stable Win64).
- **Bahasa Pemrograman:** GDScript.
- **Rendering:** Forward+ 2D dengan konfigurasi driver Direct3D 12 di Windows (`rendering_device/driver.windows="d3d12"`).
- **Fisika 2D:** Godot 2D Physics bawaan (`CharacterBody2D`, `Area2D`, dengan `motion_mode = MOTION_MODE_FLOATING`).
- **Format Scene & Map:** Format scene Godot 4 (`format=3`), dengan peta dunia berbasis node modern `TileMapLayer`.

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
   - Saat pertama kali dibuka, editor Godot akan secara otomatis memindai dan mengompilasi metadata impor seluruh aset (file `.import`).

4. **Jalankan Permainan:**
   - Tekan tombol **F5** pada keyboard, atau klik tombol **Play** di pojok kanan atas editor.
   - Editor akan memuat scene utama permainan: `res://scene/game.tscn`.

---

## Struktur Direktori

Berikut adalah struktur direktori utama repositori Flank:

```text
flank/
├── .agents/                               # Konfigurasi agen AI dan workflow proyek
├── assets/                                # Seluruh aset visual, audio, dan font mentah
│   ├── audio/                             # Aset suara (disiapkan dengan .gitkeep)
│   │   ├── bgm/                           # Musik latar (.gitkeep)
│   │   └── sfx/                           # Efek suara (.gitkeep)
│   ├── characters/                        # Sprite karakter 4-arah (idle, walk, attack, skill)
│   │   ├── archer/                        # Sprite animasi hero Archer
│   │   ├── bandit/                        # Sprite animasi musuh Bandit (telah tersedia)
│   │   ├── knight/                        # Sprite animasi hero Knight
│   │   └── mage/                          # Sprite animasi hero Mage
│   ├── enemies/                           # Folder cadangan musuh non-humanoid di masa depan (.gitkeep)
│   ├── particles/                         # Tekstur partikel debu lari (dust.png, dust_puff.png)
│   ├── projectile/                        # Tekstur proyektil panah dan bola sihir
│   ├── skills/                            # Tekstur visual efek skill (Archer, Bandit, Knight, Mage)
│   ├── tileset/                           # Spritesheet lingkungan SunnySide World 16px
│   └── ui/                                # Aset grafis antarmuka mentah dan tipografi (.gitkeep)
│       ├── fonts/                         # Tipografi pixel (.gitkeep)
│       ├── gameplay/                      # Grafis UI in-game (dialog, inventaris, HUD) (.gitkeep)
│       ├── icons/                         # Ikon aksi dan ikon skill per karakter (.gitkeep)
│       └── menus/                         # Grafis menu (start, options, pause, save/load, credits) (.gitkeep)
├── scene/                                 # Logika kode sumber (GDScript) dan scene Godot (.tscn)
│   ├── effect/                            # Prefab efek visual mandiri (run_dust.tscn/.gd)
│   ├── enemy/                             # Prefab dan AI musuh (enemy.tscn/.gd)
│   ├── player/                            # Controller hero regu (player_archer, player_bandit, player_knight, player_mage)
│   ├── projectile/                        # Proyektil fisik, benturan (impact), dan indikator reticle dunia
│   ├── ui/                                # Folder persiapan scene Godot UI (menus & gameplay) (.gitkeep)
│   ├── world/                             # Peta lingkungan TileMapLayer (map_region_1.tscn)
│   ├── game.gd                            # Controller utama party manager dan kamera
│   └── game.tscn                          # Main Scene permainan (titik masuk game)
├── PROJECT_CONTEXT.md                     # Dokumentasi arsitektur dan konteks teknis proyek
├── README.md                              # Dokumentasi umum dan panduan pengenalan proyek
└── project.godot                          # Konfigurasi utama Godot Engine
```

> **Catatan Struktur:**  
> - Subfolder dengan penanda `.gitkeep` merupakan struktur hierarki kolaborasi yang telah disiapkan agar siap digunakan saat aset visual, audio, atau scene UI ditambahkan oleh tim.
> - Keberadaan subfolder `scene/ui/` adalah persiapan struktur implementasi UI, bukan berarti sistem UI sudah selesai dibuat.
> - Aset sprite Bandit berada di `assets/characters/bandit/`, sedangkan implementasi gameplay prefab musuh Bandit direncanakan terpisah.
> - Folder `assets/enemies/` disiapkan sebagai folder cadangan untuk musuh jenis non-humanoid / monster di masa depan.

---

## Status Pengembangan

Flank saat ini berstatus sebagai **prototipe aktif** dalam tahap implementasi awal:
- **Fokus Utama Saat Ini:** Penyempurnaan mekanisme inti regu (*party core loop*), respon tempur real-time, dan pemantapan arsitektur repositori untuk kolaborasi tim.
- **Pekerjaan yang Ditunda Sementara:** Navigasi musuh lanjutan berbasis *raycasting flanking* dan penggabungan duplikasi kode controller karakter ke dalam satu *base class* bersama (*technical debt*) sengaja ditunda agar fokus pada pengujian stabilitas gameplay.

---

## Kredit dan Atribusi Aset

- **Tileset Lingkungan:** Menggunakan spritesheet *SunnySide World 16px* (`spr_tileset_sunnysideworld_16px.png`).
- **Aset Karakter, Efek Visual, dan Proyektil:** Dibuat dan dikembangkan secara internal untuk kebutuhan proyek inkubasi game ini.
- Dokumentasi lisensi resmi pihak ketiga dan atribusi tambahan akan diperbarui secara berkala seiring integrasi aset baru oleh anggota tim.
