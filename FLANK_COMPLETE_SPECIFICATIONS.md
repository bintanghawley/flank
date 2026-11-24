# SPESIFIKASI LENGKAP GAME FLANK

Dokumen spesifikasi teknis, arsitektur, gameplay, kontrol, perangkat pengembangan, performa, dan distribusi resmi untuk game **FLANK**. Disusun sebagai dokumen rujukan teknis, dokumentasi pengembangan, dan laporan hasil akhir proyek.

---

## 1. Identitas Game

| Parameter | Spesifikasi / Informasi |
| :--- | :--- |
| **Judul Game** | FLANK |
| **Versi Rilis** | Chapter 1 — Versi 1.0 (v1.0) |
| **Tim Pengembang** | Penjelajah Antariksa |
| **Genre Utama** | Action Role-Playing Game (Action RPG) / Tactical RPG |
| **Subgenre** | 2D Top-Down Real-Time Party Dungeon Crawler |
| **Tema Permainan** | Fantasi Abad Pertengahan (*Medieval Fantasy*) & Investigasi Anomali Mana Kerajaan |
| **Platform Target** | PC Desktop (Microsoft Windows 64-bit) |
| **Mode Permainan** | Single-Player (Dua Opsi Mode: *Mode Cerita* & *Mode Jelajah*) |
| **Perspektif Kamera** | 2D Top-Down Orthographic (Y-Sorted Depth) |
| **Gaya Visual** | Pixel Art Retro 16×16 (Sprite Karakter Diskalakan 5× di Dunia Game) |
| **Bahasa Antarmuka** | Bahasa Indonesia (Teks Dialog, Antarmuka HUD, Menu Buku, dan Prompt Interaksi) |
| **Target Pengguna** | Pemain umum, penggemar game retro, RPG taktis, dan petualangan berorientasi aksi (Usia 12+) |
| **Status Pengembangan** | Selesai / Siap Rilis (*Release Ready* — Chapter 1 Selesai Secara Fungsional) |

---

## 2. Deskripsi dan Konsep Permainan

### Paragraf Konsep Resmi
> **FLANK** adalah game *action RPG* taktis 2D dengan perspektif *top-down* dan visualisasi *pixel art* klasik yang dikembangkan menggunakan Godot Engine 4. Berlatar di sebuah kerajaan abad pertengahan yang dibayangi ramalan kuno kehancuran *Seven Deadly Day*, pemain memimpin Pangeran **Forzato Arthur** bersama tiga rekannya dalam regu taktis empat pahlawan untuk menginvestigasi anomali mana, menumpas ancaman monster, memecahkan teka-teki makam pusaka, dan menghadapi pertarungan bos berpola serangan dinamis. Melalui perpaduan kendali langsung pada satu pemimpin aktif (*Leader*) dan kecerdasan buatan otonom pada anggota pendamping (*Follower*), pemain disajikan pengalaman pertempuran taktis *real-time* yang fleksibel, di mana perpindahan peran antar-hero, koordinasi keahlian khusus, dan manajemen formasi menjadi kunci kemenangan di setiap arena.

### Tujuan dan Pengalaman Utama Pemain
1. **Koordinasi Taktis Empat Karakter:** Menghadirkan dinamika regu hero dengan empat peran berbeda (*Tank/Support*, *Melee Burst*, *Ranged Sniper*, dan *AoE Caster*) yang bergerak dalam barisan teratur (*breadcrumb trail*) dan bertarung secara harmonis.
2. **Kemandirian Bertarung & Kontrol Responsif:** Pemain dapat menggerakkan karakter menggunakan kendali *click-to-move* yang presisi serta melancarkan tebasan pedang, tembakan panah, kombo belati, atau sihir meteor secara terarah kursor mouse dengan pergantian kontrol instan.
3. **Pertarungan Bos Menantang:** Menguji ketangkasan pemain dalam membaca telegraf visual serangan bos (Pelatih Alaric dan Skeleton Boss) dengan fase *enrage* serta pencatatan rekor waktu penyelesaian terbaik (*best record time*).
4. **Petualangan Naratif Terstruktur:** Menyuguhkan 10 rangkaian adegan cerita pada Chapter 1 yang terhubung mulus antar-area: Hutan Observasi, Aula Pertemuan Istana, Perpustakaan Rahasia 2 lantai, Gerbang Kota, Kamp Latihan, hingga Area Pemakaman Kuno.

---

## 3. Spesifikasi Perangkat Keras Pengembangan

Informasi perangkat keras fisik yang digunakan oleh tim pengembang untuk merancang, mengompilasi, dan memvalidasi game FLANK:

### A. Komputer Pengembangan (Host Workstation)
- **Merek & Model Perangkat:** ASUSTeK COMPUTER INC. — ASUS TUF Gaming F15 (Model FX507ZC4_FX507ZC4).
- **Processor (CPU):** 12th Gen Intel(R) Core(TM) i5-12500H.
- **Arsitektur CPU:** Arsitektur Hibrida x86_64 dengan 12 Core Fisik (4 *Performance-cores* + 8 *Efficient-cores*) dan 16 *Logical Processors* (Threads).
- **Kecepatan Processor:** Base Clock 2,50 GHz, Max Turbo Frequency hingga 4,50 GHz.
- **Kartu Grafis Utama (Dedicated GPU):** NVIDIA GeForce RTX 3050 Laptop GPU.
- **Kapasitas VRAM:** 4.095 MB (4 GB GDDR6 Dedicated).
- **Versi Driver GPU Dedicated:** 32.0.15.8129 (NVIDIA Driver Branch 581.29).
- **Kartu Grafis Terintegrasi (Integrated GPU):** Intel(R) Iris(R) Xe Graphics (2.048 MB VRAM Shared, Driver 32.0.101.6790).
- **Memori Utama (RAM):** 16 GB DDR4 (15,63 GB Visible / Terdeteksi Sistem Operasi).
- **Penyimpanan Primer:** Solid State Drive (NVMe SSD) Micron 2400 MTFDKBA512QFM berkapasitas total 512 GB (476,94 GB terpartisi aktif).
- **Layar / Display Pengembangan:** Layar Internal 15,6 inci dengan resolusi 1920 × 1080 piksel (Full HD) pada *refresh rate* 144 Hz.

### B. Sistem Operasi Pengembangan
- **Nama OS:** Microsoft Windows 11 Home Single Language.
- **Versi & Build:** Versi 23H2 / 24H2 (OS Version 10.0.26300, Build Number 26300).
- **Arsitektur Sistem:** 64-bit Operating System (x64-based PC).

### C. Lingkungan Grafis Pengembangan
- **Renderer Godot:** *Forward Plus* (Rendering berbasis kluster modern Godot 4).
- **Graphics API Driver:** Direct3D 12 (D3D12) via konfigurasi resmi engine `rendering_device/driver.windows="d3d12"`.

---

## 4. Spesifikasi Perangkat Lunak Pengembangan

| Komponen | Spesifikasi / Nama Perangkat Lunak | Fungsi dalam Proyek |
| :--- | :--- | :--- |
| **Game Engine** | Godot Engine v4.7.2-stable (Official 64-bit, Build ed1daf0bf) | Engine utama logika permainan, rendering 2D, pemetaan scene tree, fisika, dan build pipeline |
| **Bahasa Pemrograman** | GDScript 2.0 (Bahasa skrip bawaan Godot Engine 4) | Pemrograman seluruh mekanik gameplay, sistem AI musuh, formasi party, HUD, dialog, dan save/load |
| **IDE / Script Editor** | Godot Integrated Script Editor & Visual Studio Code | Penulisan kode sumber GDScript, refaktorisasi fungsi, dan penataan scene tree |
| **Sistem Kendali Versi (VCS)** | Git Version 2.53.0 (Windows x64) | Manajemen riwayat perubahan, kolaborasi antar-cabang kerja (`main`, `dev/*`), dan preservasi source code |
| **Grafis & Desain Aset** | Aseprite / Pixel Art Tools | Pembuatan *spritesheet* karakter 4 arah, tekstur lingkungan, partikel, ikon antarmuka, dan tileset |
| **Pengolah Audio** | Audacity / DAW Eksternal | Masterisasi audio BGM ke OGG Vorbis 44.1 kHz stereo dan efek suara SFX ke WAV |
| **Tipografi (Font)** | Beholden oleh Tiny Speck (Beholden-Bold.ttf) | Font bergaya pixel art monospaced/bitmap terintegrasi untuk seluruh teks UI, dialog, dan menu |
| **Format Proyek** | Godot 5 Project Configuration (`project.godot`) | Definisi pengaturan display, input mapping, autoload singleton, dan fitur engine |
| **Addon / Plugin Tambahan** | Tidak ada dependensi plugin eksternal (*Vanilla Godot 4 Engine*) | Menjamin portabilitas murni tanpa risiko ketidakcocokan pustaka pihak ketiga |

---

## 5. Spesifikasi Teknis Proyek

Konfigurasi teknis aktual yang tercantum pada berkas `project.godot` dan `export_presets.cfg`:

- **Versi Konfigurasi Proyek:** `config_version=5` (Godot 4).
- **Nama Aplikasi Engine:** `"Flank"`.
- **Feature Tags:** `PackedStringArray("4.7", "Forward Plus")`.
- **Main Entry Scene (`run/main_scene`):** `res://scene/ui/menus/start_menu.tscn`.
- **Scene Arena Gameplay Utama:** `res://scene/game.tscn` (UID: `uid://80uy3wgwk1dw`).
- **Resolusi Viewport Dasar:** 1152 × 648 piksel (Rasio Aspek 16:9).
- **Mode Peregangan Jendela (*Window Stretch Mode*):** `canvas_items` (Menjaga elemen canvas dan sprite tetap tajam pada resolusi yang berbeda).
- **Aspek Peregangan Jendela (*Window Stretch Aspect*):** `expand` (Memperluas area pandang kamera secara proporsional tanpa distorsi rasio).
- **Filter Tekstur Default Canvas:** `0` (*Nearest / Point Filtering* — Wajib untuk mempertahankan ketajaman pixel art tanpa efek blur/halusinasi piksel).
- **Penyelarasan Piksel 2D (*Pixel Snapping*):**
  - `rendering/2d/snap/snap_2d_transforms_to_pixel=true`
  - `rendering/2d/snap/snap_2d_vertices_to_pixel=true`
- **Driver Rendering Windows:** Direct3D 12 (`rendering_device/driver.windows="d3d12"`).
- **Renderer Engine:** *Forward Plus* Renderer.
- **Autoload Singleton Global:**
  - `CursorManager` (`*res://scene/ui/cursor/cursor_manager.gd`): Mengatur kursor mouse kustom, umpan balik klik, dan indikator gerak tanah di seluruh scene dan status jeda.
- **Sistem Fisika 2D:**
  - `CharacterBody2D.MOTION_MODE_FLOATING` pada seluruh unit hero dan musuh.
  - Pengecualian tabrakan fisik timbal balik (*collision exceptions*) antaranggota party dan antara hero dan musuh melalui `add_collision_exception_with()`.
  - Collision Layer 1 dialokasikan untuk rintangan padat dunia fisik, dinding kota, dan collider bangunan (`StaticBody2D`).
- **Skema Pengemasan Distribusi:** Mode `binary_format/embed_pck=true` (Menyematkan data game langsung ke dalam file executable tunggal `FLANK_v1.0.exe`).
- **Mode Kompilasi Skrip Ekspor:** `script_export_mode=2` (Skrip GDScript dikompilasi menjadi bytecode biner terkompresi Zstd `.gdc`).
- **Arsitektur Ekspor Windows:** `x86_64` (Windows Desktop 64-bit).

---

## 6. Spesifikasi Gameplay dan Fitur

### A. Sistem Karakter dan Party

Game menyediakan 4 pahlawan yang dapat dimainkan dengan statistik dan peran spesifik:

| Hero | Nama Lengkap | Kelas / Peran | HP Maks | Serangan Dasar | Kecepatan Gerak | Keahlian Khusus (`E`) | Status Implementasi |
| :--- | :--- | :--- | :---: | :--- | :---: | :--- | :---: |
| **Arthur** | Forzato Arthur | Knight (Tank / Support) | 1200 | Tebasan pedang melee busur luas + *attack lunge* 140 px/s | 170 px/s (Sprint 240) | **Shield Guard:** Perisai pelindung seluruh party (100% mitigasi damage) selama 3,5 dtk (CD 12 dtk). | Terverifikasi Penuh |
| **Hellene** | Carina Hellene | Bandit (Melee Burst) | 680 | *Double Slash Dagger* (2 ayunan ritmis beruntun, 4 damage) | 185 px/s (Sprint 260) | **Dash & Flurry Slash:** Luncuran serbu ber-Super Armor, penahan musuh, dan kombo 3 tebasan beruntun (CD 5 dtk). | Terverifikasi Penuh |
| **Anastasya** | Astuta Anastasya | Archer (Ranged Sniper) | 450 | Tembakan panah lurus (580 px/s, fire rate 1,4 dtk) | 175 px/s (Sprint 245) | **Charged Line Snipe:** Mode bidik garis elastis tembakan penembus linear beruntun (CD 9 dtk). | Terverifikasi Penuh |
| **Magnus** | Pensatore Magnus | Mage (AoE Caster) | 600 | Tembakan bola sihir (500 px/s, fire rate 1,5 dtk) | 165 px/s (Sprint 230) | **Meteor Strike:** Pemanggilan meteor jatuh radius 480 px dengan ledakan area dan knockback (CD 10 dtk). | Terverifikasi Penuh |

#### Mekanisme Barisan dan Pergerakan Party:
1. **Breadcrumb Trail Queue:** Leader aktif mencatat koordinat langkah setiap 8 piksel hingga batas kapasitas 300 titik koordinat. Follower menempati slot antrean berjarak `slot_index * 85 px`.
2. **Cascade Swap 180°:** Saat Leader berbalik arah 180° melewati barisannya, antrean follower dibalik secara estafet agar formasi tidak kusut.
3. **Dynamic Corner Waypoint:** Follower melakukan raycast garis pandang (*LoS*) ke Collision Layer 1. Jika terhalang sudut bangunan, sistem mencari titik breadcrumb terdekat yang bebas rintangan agar follower melipir sudut dengan mulus.
4. **Soft Collision & Separasi:** Diterapkan dorongan separasi dinamis radius 35 px antar-hero dan 55 px terhadap musuh.
5. **Anti-Stuck Catch-Up:** Jika follower terpisah lebih dari 650 px dari Leader akibat rintangan ekstrem, follower otomatis diteleportasikan kembali ke slot barisannya dengan transisi *fade-in*.
6. **Pergantian Leader Mulus:** Menukar Leader (via angka 1–4, klik kartu HUD, atau menu Buku) mentransfer koordinat posisi dunia, arah hadap, dan momentum karakter lama ke karakter baru seketika di posisi yang sama (*zero delta offset*).

---

### B. Sistem Pertarungan

1. **Sistem Combat Real-Time:** Pertarungan aktif seketika saat unit musuh terdeteksi di viewport kamera, memicu transisi state dari `EXPLORING` ke `COMBAT`.
2. **AI Follower Mandiri:** Saat dalam mode tempur, hero follower yang tidak dikendalikan langsung akan bertempur secara otonom menyerang musuh terdekat dalam jangkauan senjatanya.
3. **Targeting & LoS:** Penentuan target proyektil dan tebasan mengarah ke kursor mouse untuk Leader, dan mengarah ke pusat hurtbox musuh untuk follower dan AI musuh.
4. **Sistem Hurtbox Menyeluruh:** Seluruh karakter hero dan musuh dilengkapi node `Hurtbox` (`Area2D` grup `"hurtbox"`) berukuran penuh dari kepala hingga kaki, menjamin penerimaan proyektil fisik yang akurat.
5. **Proteksi Double Damage & i-Frame:** Karakter hero memiliki durasi kebal pasca-damage (*invulnerability frame*) selama 0,25 detik untuk mencegah akumulasi damage ganda saat berdekatan dengan musuh.
6. **Siklus Kematian & Respawn Dinamis:** Karakter yang mencapai HP 0 memasuki status KO (potret HUD meredup dan bertuliskan `"KO"`). Jika masih ada anggota party yang hidup, hero yang gugur akan bangkit kembali secara dinamis setelah 3 detik di dekat posisi Leader aktif dengan HP penuh dan i-frame 1,5 detik.
7. **Sistem Bos Tantangan:**
   - **Pelatih Alaric:** Duel 1v1 di Arena Kamp Latihan dengan 3 pola serangan (*Basic Cleave*, *Triple Advance*, *Ground Rupture*) dan fase *enrage* saat HP di bawah 50%.
   - **Skeleton Boss:** Pertarungan klimaks 4 hero di Pemakaman Kuno dengan 4 variasi serangan area api (*Ring of Fire*, *Flame Pillar*, *Infernal Burst*, *Fireball Rain*) dan fase *enrage*.
   - **Pencatatan Rekor Bos:** Kedua bos mencatat waktu penyelesaian pertarungan dan menyimpan rekor tercepat lokal pada `user://alaric_best_record.cfg`.

---

### C. Sistem Dunia dan Level

Proyek FLANK memuat scene dan area dunia yang saling terhubung:

| Nama Scene | Berkas Scene Fisik | Peran & Fungsi dalam Game |
| :--- | :--- | :--- |
| **Start Menu** | `scene/ui/menus/start_menu.tscn` | Layar pembuka, pemilihan mode cerita/jelajah, menu opsi, kredit, dan transisi circular mask |
| **Arena Game Utama** | `scene/game.tscn` | Node orchestrator utama yang memuat dunia, sistem kamera, party, musuh, dan HUD |
| **Peta Luar / Hutan** | `scene/world/outdoor_world.tscn` | Area eksplorasi luar, Hutan Observasi, pos pengawas, jalan setapak, dan zona awal Chapter 1 |
| **Peta Kota Kerajaan** | `scene/world/kingdom_map.tscn` | Peta kota luas berbasis Sprite2D resolusi tinggi dengan 130+ batas fisik collider `StaticBody2D` |
| **Aula Pertemuan Istana**| `scene/world/castle_meeting_hall.tscn`| Ruang interior istana tempat adegan rapat darurat kerajaan bersama Raja dan Ratu |
| **Perpustakaan Rahasia**| `scene/world/secret_library.tscn` | Interior perpustakaan 2 lantai tempat investigasi anomali mana dan pembukaan skill Meteor Magnus |
| **Area Pemakaman Kuno**| Terintegrasi di `outdoor_world.tscn` | Lokasi makam Ksatria Lancelot dan arena pertarungan klimaks melawan Skeleton Boss |

---

### D. Sistem Antarmuka dan Manajemen

1. **Gameplay HUD (`gameplay_hud.tscn`):**
   - Kartu status 4 hero di kiri bawah dengan bar HP real-time, portrait, penanda Leader, dan penanda KO.
   - Bar skill 4 slot di kanan bawah dengan cooldown numerik desimal.
   - Banner penunjuk nama lokasi dinamis dan kompas navigasi misi.
2. **Menu Buku Jeda 5 Tab (`ESC` / Ikon Pause):**
   - **Tab Inventori (`B`):** 4 kategori item (*Consumable*, *Key*, *Collectible*, *Notes*).
   - **Tab Jurnal Misi (`J`):** Daftar Misi Utama dan Misi Dunia dengan deskripsi detail dan tombol kompas.
   - **Tab Informasi Karakter (`C`):** Biodata hero, animasi karakter, statistik, dan drag-and-drop susunan party.
   - **Tab Pengaturan:** Slider 4 kanal audio, kustomisasi kontrol (*key rebinding*), dan sistem Simpan/Muat Game multi-halaman ber-thumbnail.
   - **Tab Kredit:** Susunan tim pengembang Penjelajah Antariksa dan atribusi perangkat lunak.
3. **Sistem Dialog Typewriter:** Kotak teks interaktif dengan foto profil pembicara, nama karakter, dan efek ketik halus berkecepatan dinamis.
4. **Sistem Transisi Layar:** Transisi pembuka dan penutup *Iris Wipe* (Circular Mask Shader) berbasis koordinat karakter di layar.

---

## 7. Spesifikasi Kontrol Permainan

Pemetaan input kontrol resmi yang terkonfigurasi pada `gameplay_hud.gd` dan `project.godot`:

### A. Kontrol Navigasi & Eksplorasi
| Input Fisik | Fungsi Kontrol | Kondisi / Keterangan |
| :--- | :--- | :--- |
| `Klik Kanan` (Tahan) | *Click-to-Move / Hold-to-Move* | Menggerakkan Leader aktif menuju koordinat kursor mouse di dunia |
| `W`, `A`, `S`, `D` / `Tombol Panah` | Pergerakan Arah Manual | Menggerakkan Leader aktif ke 8 arah mata angin |
| `Shift` (Tahan) | Lari Cepat (*Sprint*) | Meningkatkan kecepatan gerak 1,35×–1,4× dan memicu partikel debu lari |
| `E` *(Dapat Diubah)* | Interaksi Kontekstual | Berinteraksi dengan pintu, tangga, makam, NPC, dan pemicu tantangan saat prompt `[E]` aktif |
| `Klik Kiri` / `Spasi` / `Enter` / `E` / `F` | Lanjut Dialog | Mempercepat efek ketik dialog atau beralih ke kalimat berikutnya |

### B. Kontrol Pertempuran & Penggunaan Skill
| Input Fisik | Fungsi Kontrol | Kondisi / Keterangan |
| :--- | :--- | :--- |
| `Klik Kiri` | Serangan Dasar (*Basic Attack*) | Melancarkan tebasan/tembakan ke arah posisi kursor (Aktif saat mode tempur) |
| `E` *(Dapat Diubah)* | Skill Khusus Karakter Aktif | Melancarkan skill khusus Leader aktif (Shield Guard, Dash Slash, Line Snipe, Meteor) |
| `Klik Kiri` (Tahan) | Bidik & Lepas Tembakan Panah | Khusus Anastasya saat mode Charged Line Snipe (Lepas klik kiri untuk menembak) |
| `Klik Kiri` | Tentukan Lokasi Meteor | Khusus Magnus saat mode Meteor Strike (Maksimal radius 480 px dari karakter) |
| `Klik Rpm` / `E` | Batalkan Bidikan Skill | Membatalkan persiapan skill Anastasya / Magnus dan kembali ke kendali normal |
| `1`, `2`, `3`, `4` *(Dapat Diubah)*| Ganti Hero Instan | Berganti kendali Leader langsung ke Hero Slot 1–4 (Arthur, Hellene, Anastasya, Magnus) |
| `Klik Kiri` pada Kartu Party | Ganti Hero via HUD | Mengalihkan kendali Leader ke hero yang diklik pada antarmuka HUD |
| `Klik Kiri` pada Slot Skill | Aktivasi Skill via HUD | Melancarkan skill hero terpilih secara langsung melalui klik tombol skill HUD |

### C. Kontrol Menu Buku Antarmuka (In-Game Menu)
| Input Fisik | Fungsi Kontrol | Kondisi / Keterangan |
| :--- | :--- | :--- |
| `ESC` / Klik Ikon Jeda | Buka / Tutup Menu Jeda | Membuka Menu Buku 5 tab dan menghentikan sementara waktu game (`paused = true`) |
| `B` *(Dapat Diubah)* | Buka Tab Inventori | Langsung membuka Menu Buku pada tab Inventori item party |
| `J` *(Dapat Diubah)* | Buka Tab Jurnal | Langsung membuka Menu Buku pada tab Jurnal Misi aktif |
| `C` *(Dapat Diubah)* | Buka Tab Informasi | Langsung membuka Menu Buku pada tab Info Karakter dan susunan slot party |
| `Q` / `E` | Pindah Tab Buku | Berpindah ke tab buku sebelah kiri / kanan |
| `W`, `A`, `S`, `D` / `Panah` | Navigasi Elemen Buku | Menjelajahi daftar item inventori, misi jurnal, opsi setting, atau slot simpan |
| `F` / `Enter` / `Spasi` | Konfirmasi Pilihan | Mengonfirmasi aksi (gunakan item, lacak misi, simpan/muat permainan) |

---

## 8. Spesifikasi Grafis dan Aset Visual

- **Gaya Visual:** 2D Pixel Art Retro dengan palet warna terkurasi khas fantasi abad pertengahan.
- **Resolusi Dasar Sprite:** 16 × 16 piksel per unit ubin/sprite standar.
- **Skala Karakter di Dunia:** Root `CharacterBody2D` diskalakan seragam `scale = Vector2(5, 5)` (Ukuran visual efektif ~80 × 80 piksel di layar).
- **Format File Gambar Sumber:** Portable Network Graphics (`.png`) murni ber-alpha channel (RGBA).
- **Jumlah Berkas Gambar Mentah (`assets/`):** 184 file `.png`.
- **Jumlah Tekstur Terkompilasi PCK:** 184 berkas `.ctex` (Compressed Texture 2D).
- **Pengaturan Kompresi Tekstur Godot:**
  - Seluruh sprite 2D menggunakan `compress/mode=0` (*Lossless WebP/PNG Data Storage* di dalam `.ctex`).
  - Metadata `vram_texture: false` (Menghindari kompresi lossy VRAM S3TC/BPTC yang merusak tepi piksel).
- **Pengaturan Tekstur Filtering:** `Nearest` / Point Filtering (`default_texture_filter=0`).
- **Penanganan Transparansi:** Alpha Border Fixing (`process/fix_alpha_border=true`).
- **Sistem Efek Partikel & Visual:**
  - Partikel debu lari (`run_dust.tscn` / `run_dust.gd`) dengan orientasi adaptif pada 8 arah pergerakan.
  - Partikel arwah kematian (`death_ghost.tscn`).
  - Efek kilau bintang pedang (*sword glint*) pada Start Menu.
  - Efek riak lingkaran warna kursor (*circular color ripple*) pada CanvasLayer 125 saat klik mouse.

---

## 9. Spesifikasi Audio

### A. Rangkuman Kategori dan Berkas Audio
Audit fisik terhadap folder `assets/audio/`:

| Kategori Audio | Format Berkas | Jumlah File | Sample Rate | Saluran | Bitrate Rata-Rata | Fungsi Utama |
| :--- | :---: | :---: | :---: | :---: | :---: | :--- |
| **Background Music (BGM)** | `.ogg` (Ogg Vorbis) | 10 | 44.100 Hz | Stereo (2 ch) | 192 kbps *(game_over: 128 kbps)* | Musik latar suasana eksplorasi, kota, cutscene, pertempuran, dan bos |
| **Sound Effect (SFX)** | `.wav` (PCM/ADPCM) | 49 | 44.100 Hz | Stereo / Mono | Diimpor ke IMA-ADPCM `.sample` | Efek tebasan, busur, sihir, langkah kaki, dampak benturan, dan klik UI |
| **Total Aset Suara** | — | **59 File** | **44.100 Hz** | — | — | **Tata suara lengkap game FLANK** |

### B. Daftar Trek Musik Latar (BGM)
1. `start_menu.ogg` (1,95 MB) — Musik pembuka layar Start Menu.
2. `layar_hitam_awal.ogg` (1,93 MB) — Musik prolog adegan narasi awal.
3. `game.ogg` (1,66 MB) — Musik tema eksplorasi dunia luar dan kota kerajaan.
4. `cutscene_rapat.ogg` (1,65 MB) — Musik suasana khidmat Aula Rapat Istana & Perpustakaan Rahasia.
5. `cutscene_gagak.ogg` (1,78 MB) — Musik ketegangan adegan burung gagak misterius.
6. `battle_cacing.ogg` (1,59 MB) — Musik pertempuran arena monster hutan.
7. `alaric.ogg` (1,99 MB) — Musik intensitas tinggi duel satu lawan satu Pelatih Alaric.
8. `graveyard.ogg` (2,28 MB) — Musik atmosferik Area Pemakaman Kuno dan Skeleton Boss.
9. `game_over.ogg` (0,28 MB) — Musik layar kekalahan / time rewind.
10. `perpus.ogg` (1,65 MB) — Berkas cadangan yang dideduplikasi merujuk ke trek `cutscene_rapat.ogg`.

### C. Sistem Pemutaran dan Pengaturan Suara
- **Crossfade BGM Tanpa Jeda:** Menggunakan sistem dua pemutar audio (`_bgm_player_a` dan `_bgm_player_b`) dengan interpolasi tween linear 2,5 detik untuk transisi pergantian musik yang mulus.
- **Kanal Volume Audio:** Dikelola melalui 4 bus audio independen dengan nilai rentang 0 s.d. 100% (*Master Volume*, *Music Volume*, *SFX Volume*, dan *Dialog Volume*).

---

## 10. Spesifikasi Sistem Penyimpanan Data

- **Metode Penyimpanan:** Penyimpanan lokal (*Local File Storage*) pada partisi pengguna tanpa ketergantungan server/cloud eksternal.
- **Lokasi Direktori Penyimpanan (`user://`):**
  - **Sistem Windows:** `%APPDATA%\Godot\app_userdata\Flank\` (Secara fisik berlokasi di `C:\Users\<Username>\AppData\Roaming\Godot\app_userdata\Flank\`).
- **Berkas-Berkas Penyimpanan:**
  1. **Simpan Game Utama (`user://save_slot_%d.json`):**
     - Tersedia 3 slot penyimpanan independen (Slot 1, 2, dan 3).
     - Format data: JavaScript Object Notation (JSON) terstruktur.
     - Struktur data memuat: `save_time_str`, `chapter`, `game_mode`, posisi koordinat dunia Leader, komposisi party, status HP anggota, level, isi inventori, status misi, dan tangkapan layar thumbnail berbasis base64.
     - Mekanisme Tulis Aman: *Atomic temporary write* (`save_slot_%d.json.tmp` disimpan terlebih dahulu, lalu di-rename ke `.json` setelah penulisan tuntas untuk mencegah korupsi file saat game tertutup mendadak).
  2. **Pengaturan Permainan (`user://settings.cfg`):**
     - Format: File konfigurasi INI/Godot `ConfigFile`.
     - Menyimpan konfigurasi 4 kanal volume audio (`[audio]`) dan seluruh pemetaan tombol keyboard kustom (`[controls]`).
  3. **Rekor Waktu Tercepat Bos (`user://alaric_best_record.cfg`):**
     - Format: `ConfigFile`.
     - Bagian `[alaric_duel]`: Menyimpan `best_time_sec` (detik) duel Alaric.
     - Bagian `[skeleton_boss]`: Menyimpan `best_time_sec` (detik) pertempuran Skeleton Boss.
     - Penanganan Awal: Jika berkas belum tersedia, sistem mengembalikan nilai `-1.0` yang ditampilkan pada UI sebagai status belum terpecahkan (`"--:--.--"`).

---

## 11. Spesifikasi Kinerja dan Performa

Pengukuran empiris aktual yang diperoleh melalui pengujian langsung pada build rilis Windows:

| Indikator Performa | Nilai Terukur / Parameter | Keterangan & Metode Verifikasi |
| :--- | :---: | :--- |
| **Target Frame Rate (FPS)** | 60 FPS / Mengikuti Refresh Layar (hingga 144 Hz) | Dibatasi oleh V-Sync display adapter monitor pengembangan (144 Hz stabil) |
| **Waktu Startup & Init Game** | **~2,18 detik** (`2.179 ms`) | Diukur via PowerShell `Measure-Command` saat inisialisasi cold-start hingga scene siap |
| **Konsumsi Memori RAM** | **~140 MB – 220 MB** | Pemakaian rata-rata saat memuat seluruh aset tekstur dunia, audio, dan sistem party |
| **Penggunaan Beban CPU** | **< 4%** pada Intel Core i5-12500H | Sangat ringan, beban komputasi fisika 2D dihitung pada tick rate reguler 60 Hz |
| **Penggunaan Beban GPU** | **< 8%** pada NVIDIA RTX 3050 Laptop | Pemrosesan grafis 2D dan shader iris wipe ditangani dengan lancar oleh GPU D3D12 |
| **Ukuran Data Game (PCK)** | **21,02 MB** (`21.023.888` bytes) | Hasil audit optimasi pasca-deduplikasi aset dan pembersihan filter ekspor |
| **Ukuran Binary Executable** | **124,26 MiB** (`130.292.368` bytes) | Terintegrasi utuh bersama runner engine Godot 4 release template (109,27 MB) |
| **Ukuran Arsip Distribusi** | **54,25 MiB** (`56.888.312` bytes) | Format paket ZIP rilis siap unduh |
| **Peringatan Engine Non-Fatal** | Peringatan atlas boundary ubin di luar batas | Pesan internal parser TileSet pada area ubin yang tidak memengaruhi runtime game |

---

## 12. Spesifikasi Build dan Distribusi

Audit fisik terhadap paket distribusi rilis akhir FLANK:

### A. Rincian Berkas Distribusi
- **Platform Sasaran:** Microsoft Windows Desktop (x86_64).
- **Nama Berkas Executable Resmi:** `FLANK_v1.0.exe`.
- **Nama Paket Arsip Resmi:** `FLANK_Chapter1_v1.0_Win64.zip`.
- **Lokasi Folder Distribusi:** `FLANK_Optimized_Build/`.
- **Format Packaging:** Executable mandiri dengan PCK terintegrasi (*Embedded PCK*).
- **Ketergantungan Eksternal:** Nol (*Zero external DLL dependency* — Tidak memerlukan instalasi installer pihak ketiga, .NET runtime, atau dependensi visual C++ tambahan).

### B. Tabel Ukuran Presisi

| Satuan Ukuran | Executable (`FLANK_v1.0.exe`) | Paket ZIP (`FLANK_Chapter1_v1.0_Win64.zip`) |
| :--- | :---: | :---: |
| **Ukuran Eksak (Bytes)** | **130.292.368 Bytes** | **56.888.312 Bytes** |
| **Ukuran Desimal (MB = 10^6 B)** | **130,29 MB** | **56,89 MB** |
| **Ukuran Biner (MiB = 2^20 B)** | **124,26 MiB** | **54,25 MiB** |

---

## 13. Spesifikasi Minimum dan Rekomendasi Pemain

> [!NOTE]
> Spesifikasi di bawah ini merupakan estimasi rasional berdasarkan profil konsumsi memori dan kebutuhan API grafis Godot 4 Forward Plus / D3D12. Spesifikasi ini **belum ditetapkan melalui pengujian benchmark multi-perangkat keras secara luas**. Pengujian pada ragam konfigurasi GPU terintegrasi lama (Intel HD Graphics era Gen 8 ke bawah) disarankan sebelum penetapan syarat mutlak publik.

### A. Minimum Requirements (Perkiraan Kebutuhan Minimum)
- **Sistem Operasi:** Windows 10 (64-bit) Versi 1809 atau Windows 11 (64-bit).
- **Processor (CPU):** Intel Core i3 generasi ke-6 (atau setara AMD Ryzen 3 1200) dengan dukungan arsitektur x86_64.
- **Memori RAM:** 4 GB RAM.
- **Kartu Grafis (GPU):** Kartu grafis dengan dukungan hardware **DirectX 12 (Feature Level 12_0)** atau Vulkan 1.2 (Intel UHD Graphics 620, NVIDIA GeForce GT 1030, AMD Radeon RX 550).
- **Ruang Penyimpanan Kosong:** Minimal 250 MB ruang penyimpanan kosong (untuk paket ZIP dan hasil ekstraksi executable).
- **Perangkat Masukan:** Mouse 2-tombol (Wajib untuk navigasi *click-to-move*) dan Keyboard fisik.

### B. Recommended Requirements (Kebutuhan yang Disarankan)
- **Sistem Operasi:** Windows 11 (64-bit) versi terbaru.
- **Processor (CPU):** Intel Core i5 generasi ke-10 / AMD Ryzen 5 3600 atau lebih tinggi.
- **Memori RAM:** 8 GB RAM atau lebih besar.
- **Kartu Grafis (GPU):** Kartu grafis diskrit NVIDIA GeForce GTX 1050 Ti / GTX 1650 atau AMD Radeon RX 570 dengan VRAM 4 GB.
- **Ruang Penyimpanan:** 500 MB pada media Solid State Drive (SSD).
- **Layar / Display:** Resolusi Full HD (1920 × 1080) dengan rasio layar 16:9.

---

## 14. Struktur Teknologi dan Arsitektur Proyek

### A. Hierarki Folder Sumber Repositori

```text
flank/
├── .agents/                    # Aturan kolaborasi tim dan panduan standar AI (flank-preflight)
├── assets/                     # Seluruh aset visual mentah, audio, dan tipografi
│   ├── audio/                  # Tata suara game
│   │   ├── bgm/                # Musik latar (10 file .ogg)
│   │   └── sfx/                # Efek suara terorganisir (characters, enemy, party, ui)
│   ├── characters/             # Sprite animasi 4 arah hero party, NPC istana, dan hewan
│   ├── enemies/                # Sprite monster boss (Skeleton)
│   ├── environment/            # Tekstur lingkungan luar, map kerajaan, dan interior istana
│   ├── particles/              # Tekstur partikel debu lari dan visual efek
│   ├── projectile/             # Tekstur proyektil panah, bola sihir, dan reticle bidik
│   ├── skills/                 # Tekstur efek kombo skill dan animasi meteor
│   └── ui/                     # Font Beholden, grafis dialog, ikon skill, kursor, dan menu
├── scene/                      # Logika implementasi Godot (Scene .tscn & Skrip .gd berdampingan)
│   ├── effect/                 # Entitas visual mandiri (run_dust, death_ghost)
│   ├── enemy/                  # Prefab musuh & AI musuh terintegrasi (enemy.tscn/.gd)
│   ├── npc/                    # Karakter non-pemain (npc_guard.tscn/.gd)
│   ├── player/                 # Skrip & prefab 4 hero (Knight, Bandit, Archer, Mage)
│   ├── projectile/             # Entitas fisik proyektil, hitbox AoE, dan indikator dunia
│   ├── ui/                     # Antarmuka Control dan CanvasLayer (CursorManager, HUD, StartMenu)
│   ├── world/                  # Peta dunia luar, peta kerajaan, ruang rapat, dan perpustakaan
│   ├── game.gd                 # Controller orkestrasi utama gameplay, party, kamera, dan alur cerita
│   └── game.tscn               # Node root arena yang menggabungkan seluruh modul permainan
├── export_presets.cfg          # Konfigurasi preset ekspor resmi Windows Desktop
├── project.godot               # Berkas konfigurasi utama Godot Engine 4
├── PROJECT_CONTEXT.md          # Dokumentasi teknis operasional dan riwayat perbaikan proyek
├── README.md                   # Petunjuk resmi publik proyek dan panduan menjalankan game
└── FLANK_COMPLETE_SPECIFICATIONS.md # Dokumen spesifikasi teknis lengkap game FLANK
```

### B. Hubungan Antar-Modul Kunci
1. **Scene Orchestrator (`scene/game.gd`):** Bertindak sebagai simpul pusat (*central hub*). Node ini mengontrol instansiasi peta dunia aktif, memvalidasi formasi antrean 4 karakter hero, mengatur batas pergerakan kamera, memicu transisi layar, serta memproses evaluasi skenario cerita Chapter 1 dan pertarungan bos.
2. **Autoload Singleton (`CursorManager`):** Berdiri independen di atas seluruh hierarki scene tree pada CanvasLayer 125, menyediakan kendali kursor perangkat keras global dan umpan balik klik instan yang tidak terpengaruh status *pause*.
3. **Gameplay HUD (`gameplay_hud.gd`):** Berada pada CanvasLayer 15, bertindak sebagai antarmuka pemantau dua arah yang membaca status data dari `game.gd` (HP hero, slot skill, status misi) dan mengirimkan perintah balik (ganti hero, pause, pemicu skill, simpan data).

---

## 15. Kesimpulan

Proyek game **FLANK** merupakan karya game *action RPG* taktis 2D top-down yang telah mencapai tingkat penyelesaian teknis yang matang, stabil, dan teroptimasi secara optimal pada Godot Engine 4.

Seluruh aspek teknis—mulai dari sistem formasi party cerdas (*breadcrumb trail* dengan navigasi sudut dinamis), pertarungan tertelegraf bos dengan pencatatan rekor waktu terbaik, manajemen data simpan/muat multi-slot ber-thumbnail, hingga tata suara 10 trek BGM *crossfade*—telah terintegrasi secara fungsional. Melalui audit optimasi ekspor terbaru, data game berhasil dipadatkan hingga **21,02 MB** dan terdistribusi dalam bentuk executable Windows 64-bit mandiri (`FLANK_v1.0.exe`) berukuran **124,26 MiB** serta paket arsip ZIP sebesar **54,25 MiB** tanpa sedikit pun mengorbankan kualitas grafis pixel art maupun kualitas tata suara stereo 44,1 kHz.

Dokumen spesifikasi ini menyajikan catatan faktual, terukur, dan terverifikasi dari seluruh sistem yang ada di dalam repositori, serta siap dijadikan acuan resmi dalam pelaporan proyek, evaluasi teknis, dan arsip rilis game FLANK.
