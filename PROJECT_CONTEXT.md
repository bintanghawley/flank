# FLANK — PROJECT CONTEXT & OPERATIONAL GUIDE

Dokumen ini merupakan ringkasan teknis operasional proyek game **"Flank"**. Dokumen ini berfungsi sebagai referensi kontekstual utama bagi pengembang dan agen asisten agar pengembangan fitur, perbaikan bug, dan pengujian dapat berjalan konsisten dengan arsitektur yang sudah ada tanpa mengulang inventarisasi dari awal.

**Tanggal Audit Terakhir:** 2026-11-07

> **PENTING — ATURAN VERIFIKASI SEBELUM BEKERJA:**  
> Seluruh informasi dalam dokumen ini (struktur kode, ketersediaan fitur, dan konfigurasi proyek) mencerminkan kondisi pada saat audit dan pengujian awal dilakukan. Pengembang atau asisten **wajib memeriksa kembali kondisi file fisik repositori terbaru** sebelum memulai tugas baru, terutama setelah adanya pembaruan (*git pull*) dari anggota tim lain.

---

## 1. IDENTITAS & KONSEP GAME

- **Judul Proyek:** Flank
- **Tujuan Proyek:** Tugas proyek inkubasi sekolah.
- **Genre:** Top-Down Real-Time Tactical Party Action RPG / Crawler 2D.
- **Perspektif & Gaya Visual:** 2D Top-Down Orthographic (Y-Sorted), Pixel Art 16x16 (Sprite karakter diskalakan 5x).
- **Konsep Inti Permainan:** 
  Pemain mengendalikan 1 *Leader* aktif dan 3 *Follower* otonom (total 4 hero: Knight, Bandit, Archer, dan Mage). Anggota party mengekor di belakang Leader dalam barisan dinamis (*snake breadcrumb queue*). Pemain dapat menukar kendali Leader secara instan, mengubah mode komando taktis (*Follow / Attack*), melepaskan tebasan melee, serangan proyektil, dan skill khusus (Shield Guard, Triple Slash, Charged Line Snipe, Meteor Strike). Sebagian unit memiliki navigasi flanking dasar untuk melipir rintangan, yaitu follower ranged (Archer dan Mage) saat berada dalam mode ATTACK dan terhalang rintangan, serta AI musuh saat berada dalam state CHASE dan terhalang rintangan.

---

## 2. SPESIFIKASI TEKNOLOGI & KONFIGURASI ENGINE

- **Lingkungan Pengujian yang Digunakan:** Godot Engine **v4.7.2-stable (Win64)** dengan driver render Direct3D 12 (D3D12) Forward+.
- **Persyaratan Versi Proyek:** 
  File konfigurasi `project.godot` mencantumkan feature tag `"4.7"` dan `"Forward Plus"`. Persyaratan engine resmi wajib selalu dikonfirmasi ulang melalui konfigurasi repositori terbaru.
- **Titik Masuk Utama (`run/main_scene`):** `res://scene/ui/menus/start_menu.tscn`. Scene arena permainan utama (`res://scene/game.tscn`, UID: `uid://80uy3wgwk1dw`) dimuat setelah pemain menekan "Mulai Permainan" pada start menu melalui transisi circular mask.
- **Format Scene:** Format file scene format=3 (standar teks scene Godot 4 dengan node modern `TileMapLayer`).
- **Pengaturan Display:** Stretch mode `canvas_items`, aspect `expand` (viewport default 1152x648).
- **Sistem Fisika:** 
  - 2D Physics Engine bawaan Godot.
  - **Collision Layer 1:** Lingkungan dunia fisik, dinding, rintangan, dan pembatas map (*WorldBorders*).
  - Pengecualian tabrakan (*collision exception*) diterapkan secara timbal balik antaranggota party maupun antara hero dan musuh melalui `add_collision_exception_with()`, sehingga pasangan `PhysicsBody2D` tersebut tidak saling berkolisi melalui sistem fisika Godot. Pengaturan jarak antarunit dilakukan secara terpisah oleh sistem separasi dinamis.

---

## 3. STRUKTUR DIREKTORI & MODUL UTAMA

### A. Master Plan Struktur Direktori Final (Resmi Disetujui)

> [!IMPORTANT]
> **Status Target Migrasi Fase 2 vs Struktur Fisik Repositori Saat Ini:**<br>
> Pohon direktori di bawah ini merupakan **Master Plan target migrasi arsitektur jangka panjang (Fase 2)** yang telah resmi disetujui, bukan struktur fisik repositori secara menyeluruh saat ini.<br>
> Pemindahan folder fisik untuk Fase 2 **sengaja belum dieksekusi** guna mencegah kerusakan referensi UID scene Godot, path tekstur, dan dependensi impor aset sebelum ada jadwal refactoring aset khusus.
>
> | Komponen Aset | Lokasi Fisik Saat Ini | Target Master Plan (Fase 2) | Status Pemindahan |
> | :--- | :--- | :--- | :--- |
> | Tekstur Proyektil | `assets/projectile/` | `assets/projectiles/` | Ditunda ke Fase 2 |
> | Tileset Lingkungan | `assets/tileset/` | `assets/environment/tileset/` | Ditunda ke Fase 2 |
> | Tekstur Efek Meteor Mage | `assets/skills/mage/fireball/` | `assets/skills/mage/meteor/` | Ditunda ke Fase 2 |
>
> Seluruh folder baru dengan penanda `.gitkeep` (seperti `assets/audio/`, `assets/ui/`, `assets/enemies/`, dan `scene/ui/`) telah dibuat secara fisik pada Fase 1 untuk menyiapkan hierarki kerja tim.<br>
> **Catatan Penggunaan Map Sementara:** Map yang digunakan saat ini (`map_region_1.tscn`) masih bersifat sementara untuk kebutuhan pengujian prototipe. Anggota tim sedang menyiapkan map pengganti, dan proses integrasinya akan dilakukan pada pekerjaan terpisah setelah aset peta tersedia. Penggantian tileset yang saat ini digunakan tidak dapat diasumsikan, karena yang sedang disiapkan dan direncanakan untuk diganti adalah susunan map permainan. Migrasi folder fisik Fase 2 tetap terpisah dan belum boleh dilaksanakan hanya berdasarkan rencana penggantian map ini.

Struktur direktori resmi proyek game **Flank** yang disepakati sebagai acuan arsitektur jangka panjang dan panduan kolaborasi tim:

```text
flank/
├── .agents/                               # Konfigurasi dan Standing Rules AI (flank-preflight, SKILL.md)
│   ├── rules/
│   └── skills/
│
├── assets/                                # ROOT SELURUH ASET GRAFIS, TEKSTUR, DAN AUDIO
│   ├── audio/                             # Aset Suara (BGM & SFX)
│   │   ├── bgm/                           # Musik latar (.ogg) + .gitkeep (Cadangan)
│   │   └── sfx/                           # Efek suara (.wav) terorganisir per domain:
│   │       ├── characters/                # SFX 4 hero (archer, bandit, knight, mage) & universal
│   │       ├── enemy/                     # SFX aksi musuh (alert, shoot, hit, death, respawn)
│   │       ├── party/                     # SFX taktis (ganti leader, follow, attack)
│   │       └── ui/                        # SFX menu (hover, click, sword raise, transisi iris)
│   │
│   ├── characters/                        # Seluruh Sprite Karakter (Hero Party & Karakter Musuh)
│   │   ├── archer/                        # Sprite 4-arah Archer (Hero)
│   │   ├── bandit/                        # Sprite 4-arah Bandit (Hero Party & Karakter Musuh — Tetap di sini)
│   │   ├── knight/                        # Sprite 4-arah Knight (Hero)
│   │   └── mage/                          # Sprite 4-arah Mage (Hero)
│   │
│   ├── enemies/                           # Folder Cadangan Musuh Non-Humanoid / Monster (.gitkeep)
│   │
│   ├── environment/                       # Aset Lingkungan & Map Dunia
│   │   └── tileset/                       # Target lokasi tileset setelah migrasi Fase 2
│   │
│   ├── particles/                         # Tekstur Partikel (dust.png & dust_puff.png)
│   │
│   ├── projectiles/                       # Tekstur Proyektil Fisik (Panah & Magic Bolt)
│   │   ├── arrow/
│   │   └── magic_bolt/
│   │
│   ├── skills/                            # Tekstur Efek Animasi Skill
│   │   ├── archer/
│   │   ├── bandit/
│   │   │   └── triple_slash/              # Tekstur efek skill Bandit (nama tanpa spasi)
│   │   ├── knight/
│   │   └── mage/
│   │       └── meteor/                    # Tekstur efek Meteor Strike
│   │
│   └── ui/                                # SELURUH ASET GRAFIS MENTAH UI & FONT
│       ├── fonts/                         # Tipografi pixel (Beholden-Bold.ttf)
│       ├── gameplay/                      # Grafis Antarmuka In-Game
│       │   ├── dialogue/                  # Balon dialog (bubble_talk_left-sheet.png)
│       │   ├── location/                  # Banner lokasi (location_banner.png)
│       │   └── party_hud/                 # Frame kartu hero, portrait 4 hero, life bar empty/filled
│       ├── icons/                         # Ikon-Ikon UI
│       │   ├── actions/                   # Tombol aksi prompt kontrol (action_buttons.png)
│       │   ├── cursor/                    # Tekstur kursor kustom (cursor.png)
│       │   └── skills/                    # Spritesheet ikon skill hero (skill.png)
│       └── menus/                         # Grafis Layar Menu
│           ├── character_stats/           # Menu status karakter (.gitkeep)
│           ├── credits/                   # Frame credits, logo tim + .gitkeep
│           ├── inventory/                 # Menu inventaris (.gitkeep)
│           ├── options_menu/              # Slider bar, grabber, checkbox + .gitkeep
│           ├── pause_menu/                # Tombol pause in-game (btn_pause_menu.png)
│           ├── quests/                    # Menu quest (.gitkeep)
│           ├── save_load/                 # Slot card, delete/save buttons + .gitkeep
│           └── start_menu/                # Logo flank, bg_start_sky, bg_start_grass, start-menu.png
│
├── scene/                                 # IMPLEMENTASI GAME (SCENE & SCRIPT CO-LOCATION)
│   ├── effect/                            # Prefab visual efek mandiri (run_dust.tscn/.gd)
│   ├── enemy/                             # Prefab & Script Musuh (enemy.tscn/.gd)
│   ├── player/                            # Prefab Hero Party (player_knight, player_bandit, player_archer, player_mage)
│   ├── projectile/                        # Proyektil Fisik & Reticle Bidikan Dunia
│   │   ├── arrow.tscn / .gd
│   │   ├── magic_bolt.tscn / .gd
│   │   ├── meteor_strike.tscn / .gd
│   │   ├── meteor_indicator.tscn / .gd    # World-space reticle Node2D
│   │   ├── skill_indicator.tscn / .gd     # World-space reticle Node2D
│   │   ├── skill_aoe_effect.tscn / .gd    # Area2D damage hitbox
│   │   └── impacts/                       # Prefab benturan (arrow, fireball, meteor)
│   ├── ui/                                # IMPLEMENTASI SCENE GODOT UI (CONTROL / CANVASLAYER)
│   │   ├── gameplay/                      # Scene UI Gameplay (gameplay_hud.tscn / .gd)
│   │   └── menus/                         # Scene UI Menu (start_menu.tscn / .gd)
│   ├── world/                             # TileMapLayer (map_region_1.tscn)
│   ├── game.gd                            # Controller utama party & kamera (transisi iris open)
│   └── game.tscn                          # Scene arena gameplay utama (dengan TransitionLayer IrisMask)
│
├── PROJECT_CONTEXT.md                     # Dokumentasi Konteks Operasional Proyek
├── README.md                              # Dokumentasi Publik dan Petunjuk Proyek
└── project.godot                          # Konfigurasi Utama Godot Engine
```

### B. Prinsip Arsitektur & Aturan Kolaborasi:
1. **Aturan `.gitkeep` untuk Folder Kosong:**  
   Git secara bawaan tidak melacak direktori kosong. Seluruh folder yang belum memiliki file aset aktif (seperti `assets/enemies/`, subfolder cadangan `assets/ui/menus/`, dan `assets/audio/bgm/`) diberi file penanda kosong bernama `.gitkeep` agar hierarki folder tetap terlacak saat di-clone. File `.gitkeep` pada folder yang telah terisi aset aktif (seperti `assets/audio/sfx/`, subfolder `assets/ui/gameplay/`, `assets/ui/icons/`, `assets/ui/menus/pause_menu/`, `assets/ui/menus/start_menu/`, serta `scene/ui/`) dihapus untuk menjaga kebersihan repositori.
2. **Pemisahan `assets/ui/` vs. `scene/ui/`:**  
   - `assets/ui/` khusus menampung aset visual mentah (PNG, SVG), tekstur 9-slice, ikon, dan file font tipografi (.ttf/.otf). Dilarang meletakkan script `.gd` atau scene `.tscn` di folder ini.
   - `scene/ui/` khusus menampung implementasi node Godot UI berbasis `Control` atau `CanvasLayer` beserta logika interaksinya (`.gd`).
3. **Status Entitas Reticle / Indicator Tempur:**  
   `meteor_indicator.tscn` (Node2D) dan `skill_indicator.tscn` (Node2D) adalah *world-space reticle*, sedangkan `skill_aoe_effect.tscn` adalah *Area2D combat hitbox*. Ketiganya tetap berada di domain combat/proyektil (`scene/projectile/`) dan **dilarang dipindahkan ke `scene/ui/`**.
4. **Alokasi Sprite Karakter:**  
   `assets/characters/` digunakan untuk seluruh sprite animasi karakter (baik Hero Party maupun karakter musuh seperti Bandit). Aset Bandit tetap berada di `assets/characters/bandit/`. Folder `assets/enemies/` disiapkan kosong untuk musuh monster/non-humanoid di masa depan.

### C. Tanggung Jawab Komponen Kunci:
1. **`scene/game.gd` (Game & Party Manager):**
   - Berfungsi sebagai orchestrator utama permainan dan pengelola sistem party di scene arena `game.tscn`.
   - Menangani inisialisasi dan registrasi 4 anggota party (`Knight_1`, `Bandit_1`, `Archer_1`, `Mage_1`), layer peta `map_region_1`, serta menghubungkan interface antarmuka in-game `gameplay_hud`.
   - Mengeksekusi transisi pembukaan circular mask (`play_iris_opening_transition()`) saat masuk dari Start Menu, mengunci kamera awal ke Leader, lalu menghapus layer transisi setelah selesai.
   - Mengelola pergantian Leader aktif (siklis via Tab / Q dan pemilihan langsung via angka 1–4 atau klik kartu party HUD) serta penugasan slot antrean Follower (Slot 1–3).
   - Menangani eksekusi skill instan berbasis slot (`trigger_hero_skill_by_slot`) ketika pemain menekan angka 1–4 atau mengklik slot skill pada HUD (melakukan auto-switch ke hero yang bersangkutan sekaligus melancarkan skill-nya).
   - Menghitung riwayat jejak langkah (*breadcrumbs queue*), formasi barisan, dan pembalikan antrean 180° (*cascade swap*).
   - Mengendalikan pergerakan kamera halus (*position smoothing*), offset target pandangan, evaluasi aggro tempur berbasis area kamera, efek screen shake, dan memicu balon dialog perintah taktis ("Ikuti" / "Serang") di atas kepala Leader.
   - Menghubungkan pembukaan menu jeda (*Pause Menu*) in-game melalui penekanan tombol `ESC` ke `gameplay_hud.toggle_pause_menu()`.
   - Menghasilkan batas fisik map (*WorldBorders*) secara dinamis dari layer `Ground`.
   *(Rujukan silang: Detail mekanik formasi barisan dan mode tempur kamera dijelaskan pada Bab 5.1 & 5.2; transisi iris mask dijelaskan pada Bab 5.13; Gameplay HUD dan Pause Menu dijelaskan pada Bab 5.15).*
2. **`scene/player/player_knight.gd` & `scene/player/player_knight.tscn`:**
   - Mengontrol logika karakter Knight sebagai petarung melee garda depan (Slot 1 / default Leader).
   - Menangani kendali manual saat menjadi Leader (WASD, sprint) dan kendali tempur otonom saat menjadi Follower (mendekati musuh dan menyerang berulang pada mode ATTACK).
   - Mengeksekusi serangan dasar tebasan pedang terarah kursor dengan area sapuan busur melee dan pengecekan kontak dekat di sekitar karakter.
   - Mengelola skill khusus *Shield Guard* (tombol `E` saat menjadi Leader) yang merapalkan perisai pelindung untuk seluruh anggota party, didukung animasi skill 9-frame (`skill_n`, `skill_s`, `skill_e`, `skill_w`).
   - Menangani integrasi partikel debu lari, logika separasi dinamis pada controller Knight sebagai bagian dari mekanisme yang juga diterapkan pada controller hero lainnya dan AI musuh, imunitas terhadap dorongan knockback saat menerima damage, siklus kematian, dan respawn.
   - *(Rujukan silang: Detail geometri sapuan pedang dan penyelarasan visual dijelaskan pada Bab 5.8, sedangkan penyesuaian serangan dan peniadaan knockback dijelaskan pada Bab 5.9. Detail mekanik Shield Guard dijelaskan pada Bab 5.12).*
3. **`scene/player/player_bandit.gd` & `scene/player/player_bandit.tscn`:**
   - Mengontrol logika karakter Bandit sebagai rogue/petarung melee lincah (Slot 2).
   - Menangani kendali manual Leader dan AI tempur otonom Follower (disiplin serangan dasar tanpa auto-cast skill).
   - Mengeksekusi serangan dasar *Double Slash Dagger* via klik kiri dengan dua ayunan tebasan ritmis berturut-turut.
   - Mengelola kemampuan pasif *Out-of-Combat Ambush Lunge* yang memberikan akselerasi serbu berkecepatan tinggi, bonus damage pembuka, penentuan target presisi berbasis kursor mouse dengan fallback jarak terdekat (`find_ambush_target_in_range`), dan proteksi *Super Armor* setelah jeda tanpa pertempuran.
   - Mengelola skill aktif khusus Leader *Dash, Knockup & Triple Slash* (tombol `E`): fase luncuran dash, transisi presisi saat menabrak musuh pertama ke fase knockup & stun vertikal, serta eksekusi kombo 3 tebasan beruntun dengan proteksi *Super Armor*.
   - Menangani offset visual kanvas sprite kaki agar sejajar dengan anggota party lain, respons knockback terukur saat bukan dalam aksi super armor, proteksi interupsi bersih, siklus kematian, dan respawn.
   - *(Rujukan silang: Detail parameter serangan ganda, pasif ambush, dan rangkaian kombo skill dijelaskan pada Bab 5.11).*
4. **`scene/player/player_mage.gd`:**
   - Mengontrol logika karakter Mage sebagai perapal sihir jarak jauh (Slot 4).
   - Menangani kendali pergerakan manual Leader dan perilaku tempur otonom Follower jarak jauh dengan adaptasi formasi barisan.
   - Mengeksekusi serangan dasar proyektil sihir (`magic_bolt.tscn`) dengan penentuan titik spawn dinamis di ujung tongkat sihir pada 8 arah hadap serta pembatalan instan jika terinterupsi.
   - Mengelola skill khusus *Meteor Strike AoE* (tombol `E` saat menjadi Leader) melalui reticle bidikan area kursor mouse yang memanggil proyektil meteor jatuh dari langit.
   - Mengimplementasikan navigasi flanking berbasis waypoint saat berada dalam mode tempur follower dan terhalang rintangan fisik.
   - Menangani stabilitas posisi tanpa knockback saat menerima damage, siklus kematian, dan respawn.
   - *(Rujukan silang: Detail parameter proyektil sihir dan fire rate dijelaskan pada Bab 5.5; navigasi flanking dijelaskan pada Bab 5.3).*
5. **`scene/player/player_archer.gd`:**
   - Mengontrol logika karakter Archer sebagai penembak panah jarak jauh (Slot 3).
   - Menangani kendali pergerakan manual Leader dan perilaku tempur otonom Follower jarak jauh dalam mode jelajah maupun tempur mandiri.
   - Mengeksekusi serangan dasar proyektil panah lurus (`arrow.tscn`) via klik kiri terarah ke posisi kursor mouse.
   - Mengelola skill khusus *Charged Line Snipe* (tombol `E` saat menjadi Leader) berupa mode bidik garis elastis untuk serangan linear AoE yang dapat mengenai beberapa musuh di sepanjang jalur bidikan, tetapi tidak menembus dinding atau geometri lingkungan (kuota 3 tembakan dalam durasi 10 detik).
   - Mengimplementasikan navigasi flanking berbasis waypoint saat berada dalam mode tempur follower dan terhalang rintangan fisik.
   - Menangani stabilitas posisi tanpa knockback saat terkena hit, penanganan interupsi aman pada siklus charging skill untuk mencegah deadlock/freeze, siklus kematian, dan respawn.
   - *(Rujukan silang: Detail kecepatan dan fire rate panah dijelaskan pada Bab 5.5; navigasi flanking dijelaskan pada Bab 5.3).*
6. **`scene/enemy/enemy.gd`:**
   - Mengontrol perilaku AI musuh penguji berbasis state machine (`IDLE_PATROL` dan `CHASE`).
   - Mengeksekusi serangan panah jarak jauh dan serangan kontak fisik dengan pelacakan target multi-hero serta sinkronisasi cooldown untuk mencegah akumulasi damage ganda.
   - Mengelola sistem navigasi flanking berbasis waypoint saat mengejar target melewati rintangan fisik.
   - Menangani bar HP ganda (indikator riil dan pengurangan tertunda), sistem memori ancaman (*threat-aggro*) terhadap penyerang, separasi fisik dinamis, dan siklus respawn otomatis.
   - *(Rujukan silang: Detail algoritma navigasi flanking, separasi fisik, dan proteksi double damage dijelaskan pada Bab 5.3, 5.6, dan 5.10).*
7. **`scene/ui/menus/start_menu.gd` & `scene/ui/menus/start_menu.tscn` (Start Menu Controller):**
   - Berfungsi sebagai titik masuk utama (`run/main_scene`) permainan.
   - Menampilkan latar belakang parallax bergerak kontinu (lapisan awan/langit `bg_sky` kecepatan 20 px/s dan tanah rumput `bg_grass` kecepatan 75 px/s) serta animasi berjalan di tempat 4 karakter hero party (`Knight`, `Bandit`, `Archer`, `Mage`).
   - Menyediakan interaksi tombol menu: Mulai Permainan, Lanjutkan, Pengaturan, Credits, dan Exit menggunakan font pixel `Beholden-Bold.ttf`.
   - Mengelola umpan balik visual tombol (hover/focus scaling 1.18x, penambahan penanda panah `▶ ... ◀`, dan kursor tangan).
   - Mengeksekusi transisi sinematik *Circular Mask* (Iris Wipe) saat tombol "Mulai Permainan" ditekan: hero berhenti melangkah, Knight memainkan animasi mengangkat pedang ke atas (`skill_w`), shader iris menutup memusat ke ujung pedang Knight, lalu berpindah scene ke `res://scene/game.tscn`.
   *(Rujukan silang: Detail teknis transisi iris mask dijelaskan pada Bab 5.13).*
8. **`scene/ui/gameplay/gameplay_hud.gd` & `scene/ui/gameplay/gameplay_hud.tscn` (Gameplay HUD & In-Game UI Controller):**
   - Mengontrol seluruh antarmuka in-game berbasis CanvasLayer (layer 15) di atas dunia permainan dan di bawah TransitionLayer.
   - Mengelola kontainer status party (kiri bawah): menampilkan 4 kartu hero (Arthur/Knight, Hellene/Bandit, Anastasya/Archer, Magnus/Mage) dengan portrait, bar HP real-time (`TextureProgressBar`), penanda Leader aktif (`LeaderIndicator`), serta mendukung klik mouse langsung pada kartu hero untuk berpindah kendali Leader seketika.
   - Mengelola bar skill (kanan bawah): 4 slot skill dengan ikon, hotkey angka (1–4), overlay cooldown gelap, serta penghitung waktu mundur angka digital. Klik slot memicu switch karakter sekaligus eksekusi skill.
   - Menampilkan Speech Bubble dinamis di atas kepala Leader aktif di ruang layar (*screen-space*) saat pemain memberi instruksi komando (`C` = "Ikuti", `V` = "Serang") dengan animasi pop-in dan fade-out halus.
   - Menampilkan prompt kontrol pergerakan/aksi di kiri bawah, banner nama lokasi di tengah atas, dan pelacak quest di kiri atas.
   - Mengelola overlay jeda (*Pause Menu*): dapat dibuka melalui tombol ESC atau klik ikon pause kiri atas (`btn_pause_menu.png`), menghentikan sementara proses scene tree (`get_tree().paused = true`), serta menyediakan tombol Lanjutkan (Resume) dan Menu Utama (kembali ke `start_menu.tscn`).
   *(Rujukan silang: Detail mekanik Gameplay HUD dan Pause Menu dijelaskan pada Bab 5.15).*

---

## 4. DAFTAR KARAKTER & SKEMA KONTROL GAMEPLAY

### Komposisi Party (Indeks 0–3):
- **Slot 1 (Indeks 0):** `Knight_1` (Arthur — Leader default saat game dimulai, petarung melee & shield)
- **Slot 2 (Indeks 1):** `Bandit_1` (Hellene — Rogue lincah, tebasan melee double swing / double damage & skill Triple Slash)
- **Slot 3 (Indeks 2):** `Archer_1` (Anastasya — Ranged sniper, tembakan panah lurus & skill Charged Line Snipe)
- **Slot 4 (Indeks 3):** `Mage_1` (Magnus — Ranged caster, tembakan bola sihir & skill Meteor Strike)

### Skema Input (Terverifikasi dalam Pengujian Manual):
- `W`, `A`, `S`, `D` / Panah: Gerak manual Leader.
- Tahan `Shift`: Sprint Leader dan Follower + memunculkan partikel debu lari.
- `Tab` / `Q`: Pergantian Leader berurutan secara siklis (1 ➔ 2 ➔ 3 ➔ 4 ➔ 1).
- Angka `1`, `2`, `3`, `4`: Auto-switch ke karakter yang bersangkutan sekaligus langsung melancarkan skill khususnya (1: Arthur/Knight Shield Guard, 2: Hellene/Bandit Triple Slash, 3: Anastasya/Archer Line Snipe, 4: Magnus/Mage Meteor Strike).
- Tombol `ESC` (atau klik ikon pause kiri atas): Membuka/menutup overlay Pause Menu di tengah permainan (`get_tree().paused = true/false`) dengan tombol Lanjutkan dan Menu Utama.
- Tombol `C`: Komando **FOLLOW** (follower merapatkan barisan dan dilarang menyerang) + memunculkan balon ucapan "Ikuti" di atas kepala Leader.
- Tombol `V`: Komando **ATTACK** (follower diizinkan keluar barisan dan bertarung mandiri) + memunculkan balon ucapan "Serang" di atas kepala Leader.
- `Klik Kiri`: Serangan dasar (Tebasan Melee Knight / Ayunan Ganda Double Damage Bandit / Panah Archer / Bola Sihir Mage).
- Tombol `E`: Mengaktifkan skill khusus karakter yang sedang menjadi Leader aktif (Knight: Shield Guard, Bandit: Triple Slash, Archer: masuk/keluar mode bidik Charged Line Snipe, Mage: masuk mode bidik Meteor Strike).
- `Klik Kiri pada Kartu Party HUD`: Beralih kendali Leader seketika ke hero yang diklik.
- `Klik Kiri pada Slot Skill HUD`: Auto-switch ke hero pemilik skill dan langsung melancarkan skill tersebut.

---

## 5. MEKANIK DAN SISTEM UTAMA

1. **Breadcrumb Trail & Cascade Swap 180°:**
   Leader merekam koordinat setiap melangkah sejauh 8 px (maksimal 65 titik). Follower menempati slot dengan jarak `slot_index * 85.0 px`. Jika Leader berputar balik 180° melewati barisannya, antrean dibalik secara estafet agar follower langsung berada di belakang arah baru tanpa kusut.
2. **Peralihan Mode Tempur Viewport:**
   Jika musuh masuk ke layar kamera, `game.gd` mengubah state ke `COMBAT` dan follower mulai menyerang mandiri (jika dalam komando `ATTACK`). Ketika musuh musnah atau keluar layar, ada jeda *wind-down* 0.4 detik sebelum kembali ke mode `EXPLORING`.
3. **Flanking Navigasi (Algoritma Dasar & Status Deferred):**
   - **Algoritma Waypoint Dasar:** Algoritma navigasi ini (`calculate_flank_waypoints`) hanya aktif pada **follower penyerang jarak jauh (`player_archer.gd` dan `player_mage.gd`)** saat berada dalam mode tempur follower (`in_party_combat` dengan komando `ATTACK`) dan terhalang rintangan, serta pada **AI musuh (`enemy.gd`)** saat mengejar target dalam state `CHASE` dan terhalang rintangan. Unit melakukan raycast langsung ke target pada Collision Layer 1 (`TileMapLayer` dan `StaticBody2D`). Jika terhalang, sistem melakukan probe melintang (rentang 24–720 px) ke sisi kiri dan kanan menggunakan vektor ortogonal untuk mencari celah tepi rintangan terdekat, lalu menyusun dua titik pandu (*waypoints*) untuk melipir rintangan. Algoritma ini **tidak digunakan oleh Leader** (karena dikendalikan manual oleh pemain) maupun oleh **karakter melee (Knight dan Bandit)**.
   - **Status Penyempurnaan Lanjutan:** Penyempurnaan navigasi flanking berbasis raycast dan waypoint pada follower ranged (Archer, Mage) dan AI musuh, terutama untuk penanganan rintangan kompleks dan optimasi jalur pergerakan unit, saat ini berstatus **masalah yang sengaja ditunda (*deferred issue*)** pada Bab 6B, dan dilarang dikerjakan tanpa instruksi eksplisit.
4. **Siklus Kematian & Respawn:**
   Unit hero yang mencapai HP 0 mematikan collision-nya, melepaskan keanggotaan grup `player` agar tidak ditarget musuh/proyektil saat gugur, memicu auto-switch kendali ke anggota party lain yang masih hidup jika berstatus Leader aktif, memudar (fade-out merah), disembunyikan (`visible = false`), menunggu timer respawn (3s untuk hero, 4s untuk musuh), lalu bangkit kembali di posisi awal dengan HP penuh, didaftarkan kembali ke grup `player`, ditampilkan kembali dengan fade-in halus, serta menyinkronkan status komando party (`party_command`, `in_party_combat`, `target_position`).
5. **Sistem Kecepatan Proyektil Dasar & Penyeimbangan Fire Rate:**
   Kecepatan terbang proyektil panah dibuat seragam sebesar 580 px/s untuk Archer (baik terkendali maupun follower) serta musuh archer. Kecepatan proyektil bola sihir Mage disesuaikan dikurangi sedikit menjadi 500 px/s dan dibuat sama baik saat dikendalikan (Leader) maupun tidak dikendalikan (follower). Sedangkan *basic attack fire rate* diselaraskan secara konsisten antara karakter yang dikendalikan, follower, dan musuh model archer: frekuensi tembakan Archer (Leader dan follower) serta musuh archer sama-sama berjarak 1.4s, sementara Mage (Leader dan follower) sama-sama berjarak 1.5s.
6. **Sistem Soft Collision & Separasi Dinamis:**
   Seluruh 4 karakter hero (`player_knight.gd`, `player_bandit.gd`, `player_archer.gd`, `player_mage.gd`) dan unit musuh (`enemy.gd`) mengadopsi `motion_mode = CharacterBody2D.MOTION_MODE_FLOATING`, pengecualian tabrakan fisik timbal balik (*collision exceptions*) baik antaranggota party maupun antara hero dan musuh, serta fungsi `move_and_slide_with_separation()`. Collision exception mengecualikan pasangan body yang didaftarkan dari collision satu sama lain melalui sistem fisika Godot. Sementara itu, pengaturan jarak antarunit dilakukan secara terpisah melalui kalkulasi `get_separation_vector()` di dalam `move_and_slide_with_separation()`, menggunakan parameter separasi yang telah ditentukan: dorongan separasi menggunakan `min_sep_dist = 55.0 px`; vektor hasil kalkulasi terlebih dahulu dibatasi menggunakan `limit_length(55.0)`, kemudian dikalikan dengan faktor `8.0`. Dengan demikian, collision exception mengatur pasangan yang tidak saling berkolisi, sedangkan sistem separasi mengatur jarak antarunit. Pada musuh penembak, diterapkan batas henti jarak serang (berhenti pada `dist <= 140.0 px` atau `dist <= shoot_range`) serta manuver mundur (*kiting* jika `dist < 80.0 px`) sehingga tidak pernah menerobos menempel ke 0 px. Raycast garis pandang (*LoS*) dan navigasi celah menggunakan `Array[RID]` terfilter yang hanya diblokir oleh rintangan dunia nyata (`TileMapLayer` dan `StaticBody2D`).
7. **Sistem Partikel Debu Berlari (Run Dust):**
   Partikel debu lari (`run_dust.tscn`) disinkronkan secara konsisten di seluruh 8 arah mata angin (East, West, South, North, NE, NW, SE, SW) untuk seluruh 4 hero (`Knight`, `Bandit`, `Archer`, `Mage`). Pemosisian kepulan debu menggunakan offset adaptif (`feet_y = 36–38 px` dan `lag_y = 10 px` untuk arah North/NE/NW) dengan `z_index = 3` tepat di bawah karakter (`z_index = 4`) dan di atas lantai/bayangan (`z_index = 0–2`), memastikan kepulan debu tidak tertutup jubah/baju zirah saat bergerak ke atas. Pemanggilan debu dieksekusi secara terpusat pada siklus fisika baik untuk Leader maupun Follower saat berlari sprint (`velocity.length() >= NORMAL_SPEED * 1.35`).
8. **Penyelarasan Baseline Visual & Y-Sorting Karakter:**
   Seluruh 4 hero (`Knight`, `Bandit`, `Archer`, `Mage`) memiliki hierarki scene root `CharacterBody2D` dengan origin `(0, 0)` dan skala root seragam `scale = Vector2(5, 5)`.
   - **Geometri Collision & Offset Sprite:** Seluruh hero menggunakan `CollisionShape2D` dengan posisi seragam `Vector2(0, 5.6)`. Pada konfigurasi `AnimatedSprite2D`, Archer menggunakan `offset = Vector2(0, 4)`, sedangkan Knight, Bandit, dan Mage menggunakan `offset = Vector2(0, 5)`. Perbedaan satu unit lokal ini dipertahankan sebagai kompensasi proporsi kanvas sprite Archer untuk membantu menjaga keselarasan visual baseline kaki seluruh anggota party agar berpijak sejajar di lantai dunia tanpa ada karakter yang tampak mengambang.
   - **Titik Jangkar Debu Lari (Run Dust Anchor):** Pemunculan partikel debu lari dihitung konsisten dari `global_position + Vector2(0, feet_y)` dengan `feet_y = 36.0 px` (dan `38.0 px` saat bergerak ke South) pada seluruh 4 hero.
   - **Pusat Serangan & Skill:** Titik pusat tebasan pedang Knight berpusat pada `VISUAL_CENTER_OFFSET = Vector2(0.0, 7.5)` di ruang global (setara perisai lokal `SHIELD_CENTER_OFFSET = Vector2(0.0, 1.5)`). Titik torso Archer berada di `VISUAL_CENTER_OFFSET = Vector2(2.5, 26.0)` dengan titik tembak panah `BASIC_ATTACK_ARROW_OFFSET = Vector2(2.5, 35.0)` sejajar busur. Titik tembak bola sihir Mage berada di `BASIC_ATTACK_STAFF_OFFSET = Vector2(0.0, 47.0)` (offset maju 92 px) tepat di ujung tongkat sihir. Seluruh titik kalkulasi visual ini disinkronkan presisi agar Y-sorting dan proyeksi serangan proyektil/hitbox tetap konsisten di seluruh 8 arah mata angin.
9. **Penyesuaian Geometri Tebasan Bawah Knight & Peniadaan Knockback Hero Saat Terkena Hit:**
   Jangkauan tebasan Knight ke arah bawah (South / `attack_dir.y > 0.3`) diperluas menjadi `slash_range = 160.0 px`, `close_contact_radius = 85.0 px`, `slash_arc_deg = 180.0°`, serta titik pusat digeser ke bawah (`center_offset = Vector2(0.0, 32.0)`) sehingga proporsional dan selaras sempurna dengan animasi ayunan pedang ke bawah. Efek knockback dorongan mundur pada hero `Knight`, `Archer`, dan `Mage` saat menerima damage dari musuh (`take_damage()`) maupun saat memblokir dengan Shield Guard telah dihilangkan sepenuhnya (`knockback_strength = 0.0`), sehingga posisi hero tetap stabil dan tidak tersentak mundur saat diserang (sedangkan pada `Bandit`, dorongan terukur `knockback_strength = 380.0` tetap diterapkan di luar status Super Armor/Poise). Pembatalan status serang/skill (`cancel_attack()` / `cancel_skill()`), feedback visual kedip warna, dan proteksi i-frame tetap dipertahankan agar responsivitas kontrol tetap terjaga.
10. **Proteksi Double Damage & Invulnerability Frame (i-frame):**
    Seluruh 4 hero (`Knight`, `Bandit`, `Archer`, `Mage`) dilengkapi dengan jeda kebal singkat (`invulnerability_duration = 0.25s`) pasca menerima hit untuk mencegah akumulasi damage ganda saat berdekatan/menempel dengan musuh. Pada `enemy.gd`, tembakan panah jarak dekat secara otomatis menyinkronkan cooldown kontak (`damage_timer = max(damage_timer, 0.6)`), memastikan tidak terjadi tumpang tindih antara damage panah instan dan damage kontak fisik dalam satu kali siklus serangan. Proyektil panah musuh (`arrow.gd`) juga memproyeksikan arah knockback selaras dengan vektor lintasannya (`direction`).
11. **Mekanik Khusus Hero Bandit (Double Slash, Ambush Passive, Dash Knockup Triple Slash):**
    - **Double Slash Dagger:** Serangan melee ritmis dua ayunan berurutan (jeda 0.15s dan 0.40s) selaras frame visual belati `atk-[e|w|n|s].png`. Menghasilkan 2 damage per tebasan (total 4 damage) dengan sapuan busur 160° hingga 130 px (dan adaptasi jangkauan bawah 140 px, 180°). Tidak memberikan dorongan knockback horizontal pada musuh.
    - **Out-of-Combat Ambush Lunge:** Timer 5 detik tanpa menerima maupun memberikan damage. Ditandai modulasi visual aura berpendar halus (`modulate` cyan lembut). Saat aktif, serangan dasar pertama memperoleh jangkauan *engage* luas (260 px), penentuan sasaran memprioritaskan musuh terdekat dari posisi kursor mouse (radius seleksi 120 px) dengan fallback ke musuh terdekat dalam jangkauan *engage* (`find_ambush_target_in_range`), Bandit meluncur kencang (680 px/s) ke musuh target, memberikan bonus damage +3 pada tebasan pertama (total 5 damage pembuka), mengonsumsi status pasif, serta memicu screen shake. Dilengkapi *Super Armor* dan pengecualian perisai party sehingga damage 100% masuk tanpa terblokir collider/buff sendiri.
    - **Dash, Knockup & Triple Slash (Tombol E):** Skill aktif khusus Leader (follower Bandit dilarang auto-cast). Meluncur kencang (750 px/s) ke target kursor hingga 0.35s dengan animasi `skill_[n|s|e|w]` aktif sepanjang luncuran (dan menuntaskan frame visual jika miss sebelum kembali ke idle/run). Dash berhenti seketika saat menabrak musuh pertama di jalurnya (`check_dash_collision_enemy()`); seluruh visual dan sisa animasi dash dihentikan seketika (`animated_sprite.stop()`), lalu beralih 100% secara bersih ke animasi kombo `triple_slash` pada node `AnimatedSprite2D` utama tanpa adanya sprite ganda yang tertinggal. Musuh yang tertabrak terangkat melayang ke udara secara vertikal (*knockup* ~40 px via tween parabolik) dan terkena stun selama 0.70s tanpa pergeseran horizontal. Seketika memicu kombo 3x tebasan beruntun (Step 1 pada 0.10s, Step 2 pada 0.26s, Step 3 pada 0.42s; masing-masing berdaya rusak 2, total 6 damage combo). Dilengkapi *Super Armor* penuh (tidak dapat dibatalkan atau didorong knockback oleh serangan musuh). Cooldown 5.0 detik baru mulai berjalan setelah rangkaian aksi tuntas.
12. **Sistem Shield Guard Knight:**
    - **Kondisi Aktivasi:** Shield Guard (tombol `E`) hanya dapat diaktifkan ketika Knight menjadi Leader aktif yang dikendalikan langsung oleh pemain (`player_knight.gd`). Skill tidak dapat diaktifkan jika Knight sedang gugur (`is_dead`), sedang dalam animasi skill, atau jika perisai masih aktif. Follower Knight dilarang melakukan auto-cast skill ini. Animasi skill Knight (`skill_n`, `skill_s`, `skill_e`, `skill_w`) telah diselaraskan menggunakan rangkaian aset 9-frame (frame 0–8 pada kecepatan 10 FPS).
    - **Efek Perlindungan:** Saat rapalan animasi Knight selesai (`_deploy_shield()`), perisai pelindung diberikan secara serentak kepada seluruh anggota party yang hidup dalam grup `player` (Knight, Bandit, Archer, Mage) melalui fungsi `grant_shield(shield_duration)`.
    - **Mitigasi Damage:** Menahan 100% damage dari seluruh serangan musuh (0 damage diterima, HP tidak berkurang). Karakter yang memblokir serangan musuh memicu kilatan visual putih-kebiruan halus (`modulate` flash) serta efek getaran kamera singkat (*camera shake* 3.0).
    - **Durasi dan Cooldown:** Durasi perlindungan perisai aktif selama 3.5 detik (`shield_duration = 3.5s`). Cooldown skill berlangsung selama 6.0 detik (`skill_cooldown_max = 6.0s`) dan mulai dihitung sejak pemain menekan tombol E untuk mengaktifkan skill, bersamaan dengan dimulainya proses aktivasi dan animasi rapalan Knight.
    - **Persistensi Efek:** Timer perisai (`shield_timer`) dan pembaruan visual diproses secara independen pada masing-masing hero, sehingga perlindungan tetap bertahan aktif pada seluruh anggota party ketika pemain menukar Leader di tengah durasi berlangsung hingga timer masing-masing hero habis. Efek perlindungan berakhir seketika jika karakter gugur (`is_dead`).
    - **Transisi Visual:** Node perisai (`ShieldSprite`) muncul tegak tanpa rotasi di tengah tubuh karakter dengan posisi terpusat (`SHIELD_CENTER_OFFSET`). Pemunculan perisai menggunakan tween fade-in (`modulate.a` dari 0.0 ke 1.0 dalam 0.25 detik), melayang naik-turun halus secara dinamis (*floating oscillation*), serta denyut skala berkala (*pulsing scale*). Saat durasi perisai berakhir (`deactivate_shield()`), perisai memudar keluar secara mulus melalui tween fade-out (`modulate.a` menuju 0.0 dalam 0.35 detik) sebelum visibilitas dinonaktifkan (`visible = false`).
13. **Sistem Transisi Layar Circular Mask (Iris Wipe & Iris Open):**
    - **Transisi Start Menu (Iris Wipe):** Pada Start Menu (`start_menu.gd`), ketika tombol Mulai Permainan ditekan, posisi UV ujung pedang Knight yang terangkat ke atas dihitung secara dinamis (`sword_tip_pos = knight.position + Vector2(-17.0, -36.0)`). Shader circular mask (`IrisMask`) memusatkan titik fokus ke ujung pedang dan radius lingkaran mengecil secara kubik (`TRANS_CUBIC`, `EASE_IN` dari 1.45 ke 0.0 selama 0.85 detik) hingga layar hitam total sebelum scene beralih ke `game.tscn`.
    - **Transisi Masuk Arena (Iris Open):** Pada `scene/game.gd`, fungsi `play_iris_opening_transition()` dieksekusi melalui node `TransitionLayer` (CanvasLayer 100). Kamera mengunci posisi ke Leader seketika tanpa lag smoothing (`reset_smoothing()`), kemudian shader circular mask membuka dari radius 0.0 ke 1.5 secara sinusoidal (`TRANS_SINE`, `EASE_IN_OUT` selama 1.15 detik). Setelah transisi mekar penuh, node transisi langsung dibersihkan (`queue_free()`) dari scene tree demi optimalisasi performa render.
14. **Sistem Efek Suara (Audio SFX) Gameplay & UI:**
    Implementasi audio SFX menggunakan pemanggilan instan satu arah (*one-shot AudioStreamPlayer*) melalui fungsi pembantu `play_sfx()` yang secara otomatis membebaskan memori (`queue_free()`) setelah audio selesai diputar. Seluruh 46 file audio (.wav) dimuat via `preload()` / `load()` dan dipetakan ke 5 domain utama:
    - **Hero Combat & Skills:** Ayunan pedang, hit, dan perisai (*cast, block, fade*) pada Knight; tebasan ganda, ambush (*lunge & hit*), dash, knockup, dan kombo triple slash pada Bandit; tembakan busur, aktivasi mode bidik, charging, pelepasan, dan benturan panah pada Archer; rapalan sihir, benturan bola sihir pada musuh/dinding, bidik meteor, serta luncuran dan ledakan meteor pada Mage.
    - **Universal Hero:** Langkah kaki sprint berkala (*footstep run*), suara terkena hit (*hurt*), gugur (*death*), dan bangkit kembali (*respawn*).
    - **AI Musuh:** Peringatan deteksi (*alert*), tembakan panah musuh, benturan kontak fisik, respon terluka, suara gugur, dan respawn.
    - **Taktis Party:** Suara peralihan leader aktif (`party_switch_leader`), komando FOLLOW (`party_command_follow`), dan komando ATTACK (`party_command_attack`).
    - **UI & Transisi Layar:** Interaksi tombol Start Menu (*hover, click*), animasi hunus pedang Knight (`start_sword_raise`), serta suara transisi circular mask iris wipe dan iris open.
15. **Sistem Gameplay HUD & Pause Menu Overlay:**
    Implementasi antarmuka in-game dikendalikan secara modular melalui `gameplay_hud.gd` (CanvasLayer 15):
    - **Pemantauan HP & Kartu Party:** Bar HP pada 4 kartu hero (`TextureProgressBar`) diperbarui secara real-time pada loop `_process` membaca `current_health` masing-masing hero. Indikator `LeaderIndicator` otomatis menyala pada kartu hero yang sedang dikendalikan. Klik langsung pada kartu memancarkan sinyal `leader_switch_requested` ke `game.gd` untuk menukar Leader secara mulus.
    - **Slot Skill & Cooldown Numeric Display:** Slot skill membaca `skill_cooldown_timer` hero aktif dan menampilkan countdown angka bulat (`ceil(cd)`) beserta overlay gelap transparan saat cooldown berlangsung. Klik pada slot memicu `trigger_hero_skill_by_slot()`.
    - **Balon Ucapan Taktis (Screen-Space Speech Bubble):** Menggunakan node `bubble_talk_left-sheet.png` yang posisinya dihitung setiap frame berdasarkan transformasi kanvas viewport terhadap koordinat global Leader aktif (`canvas_transform * leader.global_position + Vector2(-28, -96)`). Muncul dengan animasi skala pop-in (`TRANS_BACK`, `EASE_OUT`), bertahan 1.2 detik, lalu memudar keluar secara otomatis saat komando `C` ("Ikuti") atau `V` ("Serang") diaktifkan.
    - **Pause Menu Overlay In-Game:** Menekan `ESC` atau tombol pause kiri atas memunculkan panel jeda semi-transparan (`pause_overlay`) dan menghentikan engine tree (`get_tree().paused = true`). Tombol "Lanjutkan" mengembalikan jalannya permainan, sedangkan "Menu Utama" mematikan pause dan memuat ulang `start_menu.tscn`.

---

## 6. STATUS PENGUJIAN & CATATAN PENGEMBANGAN

### A. Fitur yang Berhasil dalam Skenario Pengujian yang Telah Dilakukan:
Klaim berikut dibatasi secara ketat pada skenario pengujian dasar yang telah dijalankan, dan **tidak mengasumsikan seluruh *edge case* telah teruji**:

- **Pergerakan Leader & Formasi Follower:** Berhasil via WASD; follower mengekor dan merespons U-turn 180° (*Diverifikasi via pengamatan manual user*).
- **Pergantian Leader & Sinkronisasi Kamera:** Berhasil via tombol Tab dan angka 1–4 (*Diverifikasi via pengamatan manual user & log runtime*).
- **Komando Party FOLLOW (C) dan ATTACK (V):** Berhasil mengubah perilaku kawal barisan vs serang mandiri (*Diverifikasi via pengamatan manual user & log runtime*).
- **Implementasi Hero Bandit (Double Slash, Ambush Lunge, Dash Knockup Triple Slash & Super Armor):** Bandit berfungsi penuh sebagai anggota party ke-2 (Slot 2); double slash ritmis 2x hit (2 damage per ayunan), pasif ambush lunge out-of-combat 5s dengan aura visual dan bonus damage (+3) yang tetap memberikan damage 100% saat memiliki perisai Knight, dash cepat dengan animasi skill penuh bahkan saat meleset (miss), knockup vertikal di tempat & stun musuh tanpa pergeseran horizontal kombo triple slash 3x hit selaras visual sprite terpisah, perlindungan Super Armor/Poise selama aksi pasif dan skill 'E', follower Bandit disiplin basic attack, serta baseline visual kaki selaras dengan Knight dan Mage (*Diverifikasi via inspeksi kode sumber & validasi pemuatan scene headless; pengujian perilaku gameplay dinamis dan visual kombo telah diamati manual*).
- **Serangan Dasar (Klik Kiri):** Tebasan pedang Knight (direct arc sweep & proximity check), ayunan ganda belati Bandit (double slash & out-of-combat ambush), panah Archer, dan bola sihir Mage berhasil diarahkan ke kursor dan mengenai musuh (*Diverifikasi via pengamatan manual user & inspeksi kode sumber*).
- **Sistem Soft Collision & Separasi Karakter:** Collision exception dan sistem separasi dinamis telah ditemukan pada implementasi seluruh controller hero dan AI musuh. Inspeksi kode sumber dan validasi pemuatan scene secara headless memastikan keberadaan implementasi serta integritas pemuatan scene. Perilaku separasi dinamis saat runtime, khususnya pada skenario kompleks, masih memerlukan observasi dan pengujian lanjutan.
- **Skill Khusus (Tombol E):** *Shield Guard* Knight (hanya aktif saat menjadi Leader), *Dash, Knockup & Triple Slash* Bandit, *Charged Line Snipe* Archer, dan *Meteor Strike* Mage berhasil diaktifkan dan memberikan dampak taktis (*Diverifikasi via pengamatan manual user*).
- **Partikel Debu Berlari (Run Dust):** Partikel debu muncul konsisten di 8 arah mata angin saat sprint bagi Leader dan Follower pada seluruh 4 hero: Knight, Bandit, Archer, dan Mage tanpa terhalang jubah karakter (*Diverifikasi via inspeksi parameter kode/scene & pengamatan manual user; pemuatan headless hanya memvalidasi keberadaan node/tekstur*).
- **Kesejajaran Baseline & Y-Sorting Party:** Seluruh 4 karakter hero (Knight, Bandit, Archer, Mage) berdiri sejajar secara horizontal dengan pijakan kaki menyentuh tanah pada baseline yang seragam tanpa ada karakter yang tampak mengambang (*Diverifikasi via inspeksi konfigurasi scene fisik & perhitungan offset sprite; validasi headless memastikan scene termuat tanpa error*).
- **Peniadaan Knockback Hero Saat Terkena Damage:** Karakter hero Knight, Archer, dan Mage tidak lagi terdorong/tersentak mundur saat menerima damage dari musuh maupun saat memblokir serangan dengan Shield Guard, menjaga stabilitas posisi tempur (sedangkan Bandit mempertahankan dorongan terukur knockback_strength = 380.0 di luar kondisi Super Armor) (*Diverifikasi via inspeksi kode sumber & pengujian manual user; pemuatan headless mengonfirmasi integritas script*).
- **Jangkauan Tebasan Bawah Knight:** Tebasan pedang ke arah South konsisten mengenai musuh di area visual sapuan bilah pedang berkat penyesuaian offset pusat tebasan (+32 px) dan radius jangkauan 160 px (*Diverifikasi via inspeksi kode sumber & pengamatan manual user*).
- **Peniadaan Double Damage Kontak Musuh:** Hero tidak lagi menerima damage ganda saat berdekatan/menempel dengan musuh berkat implementasi i-frame (0.25s) dan desinkronisasi tembakan jarak dekat di AI musuh (*Diverifikasi via inspeksi kode sumber & validasi logika i-frame*).
- **Interupsi Bersih Skill & Pencegahan Freeze Archer:** Archer tidak lagi mengalami deadlock/freeze ketika menerima damage/knockback saat sedang menahan charging skill 'E' berkat pemulihan state aman ke READY, token pembatalan serangan (`attack_token`), pencegahan penahanan klik mouse (`require_mouse_release`), serta timeout cadangan pada siklus animasi (*Diverifikasi via inspeksi kode sumber & validasi logika state*).
- **Sinkronisasi Posisi & Pembatalan Peluncuran Sihir Mage:** Proyektil bola sihir Mage kini dihitung posisinya secara dinamis tepat di ujung tongkat sihir dan secara otomatis digugurkan jika Mage terinterupsi oleh serangan musuh/knockback di tengah jeda windup cast, menghilangkan kemunculan proyektil gaib pada koordinat usang (*Diverifikasi via inspeksi kode sumber & validasi pemuatan scene*).
- **Start Menu Interaktif & Transisi Circular Mask (`start_menu.tscn`):** Layar pembuka berfungsi penuh sebagai titik masuk utama permainan (`run/main_scene`); latar belakang parallax awan dan rumput berjalan mulus, 4 karakter hero berjalan di tempat, interaksi tombol (Mulai Permainan, Lanjutkan, Pengaturan, Credits, Exit) responsif dengan umpan balik visual dan cursor hand, animasi Knight mengangkat pedang saat mulai, transisi iris wipe menutup presisi ke ujung pedang, serta transisi iris opening sinusoidal saat masuk ke arena `game.tscn` (*Diverifikasi via inspeksi kode sumber & pengujian manual user*).
- **Penyelarasan Animasi 9-Frame Skill Knight:** Rangkaian animasi skill Knight (`skill_n`, `skill_s`, `skill_e`, `skill_w`) telah diselaraskan penuh dengan pembaruan aset 9-frame (frame 0–8) tanpa error atlas region (*Diverifikasi via inspeksi scene player_knight.tscn*).
- **Presisi Targeting Ambush Lunge Bandit:** Logika targeting pasif ambush bandit memprioritaskan musuh terdekat dari posisi kursor mouse (radius 120 px) dengan fallback terukur ke musuh terdekat dalam jangkauan engage, serta membersihkan peringatan unused variable linter engine (*Diverifikasi via inspeksi kode sumber player_bandit.gd*).
- **Siklus Kematian & Respawn:** Pengurangan HP saat terkena serangan musuh, transisi mati (fade-out), timer tunggu, dan kemunculan kembali karakter berhasil berjalan normal (*Diverifikasi via pengamatan manual user & log runtime*).
- **Sistem Efek Suara (Audio SFX) Terintegrasi Penuh:** Seluruh 46 aset audio SFX (.wav) terdistribusi ke subfolder terstruktur (`characters/`, `enemy/`, `party/`, `ui/`) dan terverifikasi memutar suara dengan tepat pada seluruh aksi gameplay: serangan dasar dan skill 4 hero, langkah kaki lari, respons damage/death/respawn hero dan musuh, perintah taktis party, interaksi tombol start menu, serta transisi circular mask iris tanpa error pemuatan atau kebocoran memori (*Diverifikasi via inspeksi kode sumber, log runtime engine, dan validasi eksekusi headless*).
- **Gameplay HUD Terintegrasi Penuh (`gameplay_hud.tscn`):** Kartu status party 4 hero (Arthur, Hellene, Anastasya, Magnus) dengan bar HP real-time, penanda leader aktif, fungsionalitas klik kartu untuk switch leader, bar 4 skill dengan countdown cooldown angka bulat, balon ucapan komando taktis ("Ikuti"/"Serang") di atas kepala leader, banner lokasi, pelacak quest, serta overlay pause menu in-game via tombol pause atau ESC yang menghentikan sementara jalannya game (`get_tree().paused`) dan menyediakan navigasi kembali ke start menu (*Diverifikasi via inspeksi scene & kode gameplay_hud.gd/game.gd*).
- **Pembaruan Animasi Knight Start Menu:** Spritesheet dan frame animasi Knight pada start menu telah diperbarui (*Diverifikasi via git log commit d76fd4d & inspeksi aset start-menu.png*).

> **Catatan Sumber Verifikasi Parameter:**  
> Parameter numerik internal seperti kecepatan gerak (128 px/s normal, 220 px/s sprint), kecepatan dasar proyektil (panah 580 px/s untuk Archer dan musuh, magic bolt 500 px/s untuk Mage baik terkendali maupun tidak), rasio kesetaraan proyektil (1.0), durasi cooldown serangan dasar (1.4s untuk Archer Leader/follower/musuh archer, 1.5s untuk Mage Leader/follower) / skill, kekuatan dorongan knockback (`knockback_strength`), laju redaman (`knockback_decay = 1400.0`), jarak antrean (85 px), serta interval pemindaian aggro (0.15s) bersumber dari **inspeksi kode sumber dan log runtime**, bukan hasil pengukuran stopwatch manual pemain.

### B. Masalah yang Sengaja Ditunda (*Deferred Issues*):
- **Penyempurnaan AI Musuh & Flanking Navigasi:**
  Penyempurnaan perilaku navigasi flanking berbasis raycast dan waypoint pada follower ranged (Archer, Mage) dan AI musuh, terutama saat menghadapi rintangan kompleks dan optimasi jalur pergerakan unit, masih berstatus *deferred issue*.
  > **PERINGATAN:** Catatan penundaan ini **BUKAN** merupakan izin untuk langsung mengerjakannya tanpa permintaan atau instruksi eksplisit dari pengguna.

### C. Technical Debt & Rencana Masa Depan (*Backlog*):
*(Hanya dikerjakan jika secara spesifik diminta oleh pengguna)*
1. **Refactoring Base Character:** Evaluasi dan penggabungan logika bersama yang berulang antara `player_knight.gd`, `player_bandit.gd`, `player_archer.gd`, dan `player_mage.gd` ke dalam kelas dasar bersama.
2. **Sistem Antarmuka Pengguna (UI / Menus / HUD):**
   - **Gameplay UI (`scene/ui/gameplay/`):**
     - *Party HUD (`gameplay_hud.tscn`):* **SUDAH SELESAI & TERINTEGRASI** (bar HP real-time 4 hero, indikator leader aktif, bar skill dengan countdown cooldown, bubble ucapan komando, banner lokasi, prompt kontrol, dan pause menu overlay).
     - *Inventory UI:* Tampilan slot grid inventaris barang, frame tooltip deskripsi item, dan status perlengkapan (aset grafis telah disiapkan di `assets/ui/`).
     - *Dialogue UI:* Sistem dialog percakapan NPC penuh dan penampil teks cerita (aset balon dialog telah disiapkan di `assets/ui/gameplay/dialogue/`).
   - **Menu UI (`scene/ui/menus/`):**
     - *Start / Main Menu (`start_menu.tscn`):* **SUDAH SELESAI & TERINTEGRASI** sebagai `run/main_scene` dengan latar parallax, animasi party, font Beholden, dan transisi circular mask.
     - *Pause Menu:* **SUDAH SELESAI & TERINTEGRASI** sebagai overlay in-game di `gameplay_hud.tscn` (dapat diakses via tombol ESC atau ikon pause).
     - *Options Menu:* Panel pengaturan audio (slider volume Master, BGM, SFX), resolusi layar, dan mode tampilan (Windowed/Fullscreen).
     - *Save & Load Menu:* Tampilan slot kartu penyimpanan progres permainan, tombol simpan, dan muat data.
     - *Credits Screen:* Panel apresiasi tim pengembang dan kontributor proyek inkubasi.
   *(Status Implementasi: Start Menu, Gameplay HUD, dan Pause Menu telah selesai diimplementasikan dan aktif; sub-menu lainnya dan dialog/inventaris penuh saat ini berstatus backlog).*
3. **Sistem Audio (Musik Latar / BGM):** Integrasi musik latar BGM permainan pada layar menu dan arena gameplay (efek suara / SFX telah selesai diimplementasikan secara komprehensif).
4. **Sentralisasi InputMap:** Memindahkan konstanta fisik `KEY_*` di script ke action resmi di `project.godot`.
5. **Variasi Musuh:** Penggantian spritesheet musuh agar tidak menduplikasi sprite Archer merah.
6. **Preset Ekspor:** Pembuatan konfigurasi `export_presets.cfg` untuk build rilis.

---

## 7. KONVENSI & ATURAN KERJA PENGEMBANGAN

Bagi pengembang atau asisten AI yang bekerja pada repositori ini:

1. **Pahami Kode Terlebih Dahulu (*Read Before Write*):** Selalu pelajari implementasi yang ada pada script terkait sebelum mengusulkan atau menulis kode baru.
2. **Pertahankan Sistem yang Sudah Berfungsi:** Jangan mengubah mekanisme formasi, pergantian leader, atau kalkulasi proyektil yang sudah terbukti stabil pada pengujian sebelumnya.
3. **Dilarang Refactoring Liar & Feature Creep:** Fokus secara ketat hanya pada instruksi spesifik yang diminta. Jangan melakukan refactoring arsitektur atau menambahkan fitur di luar permintaan.
4. **Pemeriksaan Git Wajib Sebelum & Sesudah Bekerja:** Selalu jalankan `git status` sebelum memulai pekerjaan untuk mencatat kondisi awal, dan periksa kembali setelah selesai guna memastikan hanya file yang ditugaskan yang mengalami perubahan.
5. **Pemisahan Cache Engine:** Bedakan perubahan cache internal (`.godot/`) dari perubahan source code riil proyek.
