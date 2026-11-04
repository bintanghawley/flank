# Flank

**Flank** adalah prototipe game action RPG taktis 2D dengan perspektif *top-down* yang dikembangkan menggunakan Godot Engine 4 untuk proyek inkubasi game.

Dalam game ini, pemain mengendalikan sebuah regu (*party*) beranggotakan empat hero: **Knight**, **Bandit**, **Archer**, dan **Mage**. Pemain mengendalikan satu **Leader** secara langsung, sementara tiga **Follower** bergerak mengekor di belakang barisan atau bertempur mandiri sesuai perintah yang diberikan. Pemain dapat berganti Leader secara instan, mengatur formasi pergerakan, mengeksekusi serangan dasar terarah, serta melancarkan skill khusus dengan fungsi taktis yang berbeda secara *real-time*.

> **Status Proyek:** Flank saat ini berada pada tahap pengembangan prototipe awal (*early prototype*). Mekanisme inti permainan telah diimplementasikan dan beberapa skenario gameplay telah berhasil diuji. Pengembangan serta pengujian lanjutan masih berlangsung.

---

## Gambaran Permainan

Flank menggabungkan mekanika aksi *real-time* dengan manajemen regu taktis:

- **Sistem Party Empat Hero:** Regu beranggotakan Knight (`Knight_1`), Bandit (`Bandit_1`), Archer (`Archer_1`), dan Mage (`Mage_1`). Pengecualian tabrakan (*collision exception*) diterapkan antaranggota party sehingga mereka tidak saling berkolisi melalui sistem fisika bawaan Godot. Pengaturan jarak antarunit tetap dilakukan secara terpisah menggunakan sistem separasi dinamis.
- **Pergantian Leader & Kamera:** Kendali aktif dapat dipindahkan secara instan ke hero mana pun menggunakan tombol `Tab` atau angka `1`–`4`. Kamera permainan secara otomatis mengikuti posisi Leader aktif dengan pergerakan yang halus (*position smoothing*).
- **Formasi Breadcrumb Queue & Cascade Swap 180°:** Saat bergerak, Follower mengikuti jejak langkah kaki Leader (*breadcrumbs*) secara teratur. Ketika Leader berputar balik 180°, formasi antrean follower langsung berbalik secara estafet (*cascade swap*) agar regu tidak bertumpuk.
- **Sistem Komando Party (Follow & Attack):**
  - **Mode FOLLOW (`C`):** Follower merapatkan barisan di belakang Leader dan tidak melakukan serangan, dengan fokus pada mobilitas serta menjaga formasi regu.
  - **Mode ATTACK (`V`):** Follower diberi kebebasan untuk keluar dari barisan dan menyerang musuh terdekat dalam jangkauan tempur secara mandiri.
- **Pertarungan Real-Time & Serangan Dasar:** Serangan diarahkan langsung ke posisi kursor mouse melalui klik kiri:
  - **Knight:** Tebasan pedang jarak dekat (*melee slash*) dengan area sapuan busur di depan karakter.
  - **Bandit:** Tebasan ganda belati (*Double Slash Dagger*) secara ritmis untuk setiap siklus serangan. Dilengkapi kemampuan pasif *Out-of-Combat Ambush Lunge* setelah beberapa detik tanpa pertempuran: serangan pembuka memperoleh jangkauan serbu luas, Bandit meluncur cepat ke target, menghasilkan bonus damage pembuka, dan diperkuat perlindungan *Super Armor*.
  - **Archer:** Tembakan anak panah lurus terarah dengan kecepatan proyektil stabil.
  - **Mage:** Tembakan bola sihir (*magic bolt*) jarak jauh yang dilepaskan tepat dari ujung tongkat sihir.
- **Skill Khusus Hero (`E`):**
  - **Knight — *Shield Guard*:** Hanya dapat diaktifkan saat Knight menjadi Leader aktif (cooldown 6.0 detik). Knight merapalkan perisai pelindung serentak yang melindungi seluruh anggota party dari 100% damage serangan musuh selama 3.5 detik, dan efek perisai tetap bertahan pada masing-masing hero saat pemain berganti karakter hingga durasinya berakhir.
  - **Bandit — *Dash, Knockup & Triple Slash*:** Hanya dapat diaktifkan saat Bandit menjadi Leader aktif. Melesat cepat ke arah kursor mouse dan berhenti seketika saat menabrak musuh pertama. Musuh yang tertabrak terangkat ke udara (*knockup*) serta terkena stun singkat, lalu seketika dieksekusi dengan kombo 3 tebasan beruntun disertai efek visual khusus *triple slash* dan perlindungan *Super Armor* (cooldown 5.0 detik).
  - **Archer — *Charged Line Snipe*:** Mengaktifkan mode bidik garis elastis. Pemain menahan klik kiri untuk mengisi daya tembakan dan melepasnya untuk melancarkan tembakan garis lurus berdaya rusak area (linear AoE) yang dapat mengenai beberapa musuh di sepanjang jalur bidikan, tetapi tidak menembus dinding atau geometri lingkungan (dapat ditembakkan hingga 3 kali dalam jendela waktu 10 detik). Tekan kembali tombol `E` saat Archer berada dalam state `READY` untuk keluar dari mode bidik. Klik kanan saat pengisian daya berlangsung (`STARTING` atau `CHARGING`) akan membatalkan pengisian dan mengembalikan skill ke state `READY`. Klik kanan saat berada dalam state `READY` juga dapat digunakan untuk keluar dari mode bidik.
  - **Mage — *Meteor Strike*:** Mengaktifkan reticle lingkaran pada posisi kursor mouse. Klik kiri memanggil proyektil meteor yang jatuh dari langit dan meledak menghasilkan kerusakan area (*AoE*). Klik kanan untuk membatalkan reticle bidikan.
- **Sistem Musuh & Siklus Tempur:**
  - AI musuh dilengkapi status patroli acak (*idle patrol*) dan pengejaran (*chase*) saat mendeteksi pemain.
  - Musuh memiliki serangan kontak fisik (damage 1) serta serangan jarak jauh berupa tembakan panah (damage 1, kecepatan 580 px/s, jeda tembak 1.4 detik).
  - Dilengkapi tampilan bar darah (*health bar*) di atas kepala, sistem prioritas ancaman (*threat target priority*), dan kemunculan kembali (*respawn*) otomatis setelah gugur (4 detik untuk musuh, 3 detik untuk hero).
  - Efek dorongan fisik (*knockback*) dinonaktifkan pada hero pemain (Knight, Archer, Mage) saat terkena damage agar kontrol pergerakan tetap responsif (sedangkan Bandit mempertahankan dorongan knockback terukur di luar status Super Armor). Efek knockback yang diterima musuh mengikuti karakteristik masing-masing serangan pemain; beberapa serangan tidak memberikan dorongan knockback.

---

## Fitur Permainan

### Fitur yang Sudah Diimplementasikan (Teruji pada Skenario Dasar)
- [x] Kontrol regu 4 hero (Knight, Bandit, Archer, Mage) dengan pengecualian tabrakan fisik antaranggota party.
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
- [ ] Implementasi prefab dan AI Bandit sebagai musuh, terpisah dari karakter Bandit yang sudah dapat dimainkan (aset sprite telah tersedia di `assets/characters/bandit/`).
- [ ] Implementasi antarmuka pengguna visual (UI/HUD: bilah darah anggota party, indikator cooldown skill visual, inventaris, dialog).
- [ ] Tata suara permainan (musik latar/BGM dan efek suara/SFX).
- [ ] Menu permainan (Start Menu, Options, Pause Menu, Save/Load, Credits).
- [ ] Variasi jenis musuh baru (monster non-humanoid pada folder cadangan `assets/enemies/`).
- [ ] Penyempurnaan navigasi flanking berbasis raycast dan waypoint pada follower ranged (Archer, Mage) dan AI musuh, terutama untuk penanganan rintangan kompleks dan optimasi jalur pergerakan.
- [ ] Konfigurasi preset ekspor aplikasi mandiri (*executable*).

---

## Kontrol Permainan

| Tombol / Input | Fungsi | Cara Penggunaan |
| :--- | :--- | :--- |
| `W`, `A`, `S`, `D` / Panah | Gerak Karakter | Menggerakkan Leader aktif ke 8 arah |
| `Shift` (Tahan) | Sprint | Meningkatkan kecepatan jalan (128 px/s → 220 px/s) disertai efek debu |
| `Tab` | Ganti Karakter Siklis | Berganti Leader secara berurutan (Knight → Bandit → Archer → Mage → Knight) |
| `1`, `2`, `3`, `4` | Ganti Karakter Langsung | Memilih Leader spesifik (1: Knight, 2: Bandit, 3: Archer, 4: Mage) |
| `C` | Perintah FOLLOW | Menginstruksikan regu untuk merapatkan barisan dan tidak melakukan serangan |
| `V` | Perintah ATTACK | Mengizinkan follower bertarung mandiri menyerang musuh terdekat |
| `Klik Kiri` (Tap / Tahan) | Serangan Dasar | Menyerang ke arah kursor mouse (tebasan Knight, ayunan ganda Bandit, panah Archer, sihir Mage) |
| `E` | Skill Khusus | **Knight:** Hanya saat menjadi Leader aktif: merapalkan perisai *Shield Guard* serentak ke seluruh regu (durasi 3.5s, cooldown 6s)<br>**Bandit:** Hanya saat menjadi Leader aktif: melesat dash menabrak musuh, knockup & stun musuh, lalu melancarkan combo 3 tebasan *Triple Slash* (cooldown 5s)<br>**Archer:** Saat skill belum aktif, masuk ke mode bidik *Charged Line Snipe*. Saat berada dalam state `READY`, tekan kembali `E` untuk keluar dari mode bidik<br>**Mage:** Masuk mode bidik *Meteor Strike* |
| `Klik Kiri` (Saat Mode Skill) | Eksekusi Skill | **Archer:** Tahan klik kiri untuk mengisi daya dan lepaskan untuk meluncurkan panah<br>**Mage:** Klik pada area sasaran untuk menjatuhkan meteor |
| `Klik Kanan` (Saat Mode Skill) | Batal / Keluar Skill | **Archer:** Saat state `STARTING` atau `CHARGING`, membatalkan pengisian daya dan mengembalikan skill ke state `READY`. Saat state `READY`, keluar dari mode bidik<br>**Mage:** Membatalkan reticle sasaran meteor |

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
   - Saat pertama kali dibuka, editor Godot akan secara otomatis memindai dan mengimpor aset serta memperbarui atau membuat file metadata (`.import`) yang diperlukan.

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
│   │   ├── bandit/                        # Sprite animasi karakter Bandit (hero party & calon musuh)
│   │   ├── knight/                        # Sprite animasi hero Knight
│   │   └── mage/                          # Sprite animasi hero Mage
│   ├── enemies/                           # Folder cadangan musuh non-humanoid di masa depan (.gitkeep)
│   ├── particles/                         # Tekstur partikel debu lari (dust.png, dust_puff.png)
│   ├── projectile/                        # Tekstur proyektil panah dan bola sihir
│   ├── skills/                            # Tekstur visual efek skill (Archer, Bandit, Knight, Mage)
│   ├── tileset/                           # Tileset lingkungan yang saat ini digunakan
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
> - Aset sprite Bandit berada di `assets/characters/bandit/`, sedangkan implementasi prefab dan AI Bandit sebagai musuh direncanakan terpisah dari karakter Bandit yang sudah dapat dimainkan.
> - Folder `assets/enemies/` disiapkan sebagai folder cadangan untuk musuh jenis non-humanoid / monster di masa depan.

---

## Status Pengembangan

Flank saat ini berstatus sebagai **prototipe aktif** dalam tahap implementasi awal:
- **Fokus Utama Saat Ini:** Penyempurnaan mekanisme inti regu (*party core loop*), respon tempur real-time, dan pemantapan arsitektur repositori untuk kolaborasi tim.
- **Lingkungan & Peta Permainan:** Peta lingkungan yang digunakan saat ini masih bersifat sementara untuk kebutuhan pengujian prototipe, dan direncanakan akan diganti menggunakan aset map yang sedang disiapkan oleh anggota tim.
- **Pekerjaan yang Ditunda Sementara:** Penyempurnaan navigasi flanking berbasis raycast dan waypoint pada follower ranged (Archer, Mage) dan AI musuh masih ditunda (terutama untuk penanganan rintangan kompleks dan optimasi jalur unit), serta evaluasi penggabungan duplikasi kode controller karakter ke dalam satu *base class* bersama (*technical debt*) sengaja ditunda agar fokus pada pengujian stabilitas gameplay.
