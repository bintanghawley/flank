# FLANK — PROJECT CONTEXT & OPERATIONAL GUIDE

Dokumen ini merupakan ringkasan teknis operasional proyek game **"Flank"**. Dokumen ini berfungsi sebagai referensi kontekstual utama bagi pengembang dan agen asisten agar pengembangan fitur, perbaikan bug, dan pengujian dapat berjalan konsisten dengan arsitektur yang sudah ada tanpa mengulang inventarisasi dari awal.

> **PENTING — ATURAN VERIFIKASI SEBELUM BEKERJA:**  
> Seluruh informasi dalam dokumen ini (struktur kode, ketersediaan fitur, dan konfigurasi proyek) mencerminkan kondisi pada saat audit dan pengujian awal dilakukan. Pengembang atau asisten **wajib memeriksa kembali kondisi file fisik repositori terbaru** sebelum memulai tugas baru, terutama setelah adanya pembaruan (*git pull*) dari anggota tim lain.

---

## 1. IDENTITAS & KONSEP GAME

- **Judul Proyek:** Flank
- **Tujuan Proyek:** Tugas proyek inkubasi sekolah.
- **Genre:** Top-Down Real-Time Tactical Party Action RPG / Crawler 2D.
- **Perspektif & Gaya Visual:** 2D Top-Down Orthographic (Y-Sorted), Pixel Art 16x16 (Sprite karakter diskalakan 5x).
- **Konsep Inti Permainan:** 
  Pemain mengendalikan 1 *Leader* aktif dan 3 *Follower* otonom (total 4 hero: Knight, Bandit, Archer, dan Mage). Anggota party mengekor di belakang Leader dalam barisan dinamis (*snake breadcrumb queue*). Pemain dapat menukar kendali Leader secara instan, mengubah mode komando taktis (*Follow / Attack*), melepaskan tebasan melee, serangan proyektil, dan skill khusus (Shield Guard, Triple Slash, Line Snipe, Meteor Strike), serta memanfaatkan manuver melipir rintangan (*flanking*).

---

## 2. SPESIFIKASI TEKNOLOGI & KONFIGURASI ENGINE

- **Lingkungan Pengujian yang Digunakan:** Godot Engine **v4.7.2-stable (Win64)** dengan driver render Direct3D 12 (D3D12) Forward+.
- **Persyaratan Versi Proyek:** 
  File konfigurasi `project.godot` mencantumkan feature tag `"4.7"` dan `"Forward Plus"`. Persyaratan engine resmi wajib selalu dikonfirmasi ulang melalui konfigurasi repositori terbaru.
- **Titik Masuk Utama (`run/main_scene`):** `res://scene/game.tscn` (UID: `uid://80uy3wgwk1dw`).
- **Format Scene:** Format 4 (menggunakan node modern `TileMapLayer`).
- **Pengaturan Display:** Stretch mode `canvas_items`, aspect `expand` (viewport default 1152x648).
- **Sistem Fisika:** 
  - 2D Physics Engine bawaan Godot.
  - **Collision Layer 1:** Lingkungan dunia fisik, dinding, rintangan, dan pembatas map (*WorldBorders*).
  - Pengecualian tabrakan (*collision exception*) diterapkan antar-seluruh anggota party (3 karakter) via `add_collision_exception_with()` agar tidak saling mendorong.

---

## 3. STRUKTUR DIREKTORI & MODUL UTAMA

### A. Master Plan Struktur Direktori Final (Resmi Disetujui)

Struktur direktori resmi proyek game **Flank** yang disepakati sebagai acuan arsitektur jangka panjang dan panduan kolaborasi tim:

```text
flank/
├── .agents/                               # Konfigurasi dan Standing Rules AI (flank-preflight, SKILL.md)
│   ├── rules/
│   └── skills/
│
├── assets/                                # ROOT SELURUH ASET GRAFIS, TEKSTUR, DAN AUDIO
│   ├── audio/                             # Aset Suara (Disiapkan dengan .gitkeep)
│   │   ├── bgm/                           # Musik latar (.ogg) + .gitkeep
│   │   └── sfx/                           # Efek suara (.wav) + .gitkeep
│   │
│   ├── characters/                        # Seluruh Sprite Karakter (Hero Party & Karakter Musuh)
│   │   ├── archer/                        # Sprite 4-arah Archer (Hero)
│   │   ├── bandit/                        # Sprite 4-arah Bandit (Karakter Musuh — Tetap di sini)
│   │   ├── knight/                        # Sprite 4-arah Knight (Hero)
│   │   └── mage/                          # Sprite 4-arah Mage (Hero)
│   │
│   ├── enemies/                           # Folder Cadangan Musuh Non-Humanoid / Monster (.gitkeep)
│   │
│   ├── environment/                       # Aset Lingkungan & Map Dunia
│   │   └── tileset/                       # Spritesheet SunnySide World 16px
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
│       ├── fonts/                         # Tipografi pixel (.ttf, .otf) + .gitkeep
│       ├── gameplay/                      # Grafis Antarmuka In-Game
│       │   ├── dialogue/                  # 9-slice box dialog, frame avatar + .gitkeep
│       │   ├── inventory/                 # Grid cell slot, frame tooltip + .gitkeep
│       │   └── party_hud/                 # HP bar frame/fill, command icons + .gitkeep
│       ├── icons/                         # Ikon-Ikon UI
│       │   ├── actions/                   # Skip icon, prompt tombol interaksi + .gitkeep
│       │   └── skills/                    # Subfolder Ikon Skill per Karakter:
│       │       ├── archer/                # Ikon skill Archer + .gitkeep
│       │       ├── bandit/                # Ikon skill Bandit + .gitkeep
│       │       ├── knight/                # Ikon skill Knight + .gitkeep
│       │       └── mage/                  # Ikon skill Mage + .gitkeep
│       └── menus/                         # Grafis Layar Menu
│           ├── credits/                   # Frame credits, logo tim + .gitkeep
│           ├── options_menu/              # Slider bar, grabber, checkbox + .gitkeep
│           ├── pause_menu/                # Dim overlay, popup frame + .gitkeep
│           ├── save_load/                 # Slot card, delete/save buttons + .gitkeep
│           └── start_menu/                # Title logo, main button frames + .gitkeep
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
│   │   ├── gameplay/                      # Scene UI Gameplay (.gitkeep)
│   │   └── menus/                         # Scene UI Menu (.gitkeep)
│   ├── world/                             # TileMapLayer (map_region_1.tscn)
│   ├── game.gd                            # Controller utama party & kamera
│   └── game.tscn                          # Main Entry Scene (uid://80uy3wgwk1dw)
│
├── PROJECT_CONTEXT.md                     # Dokumentasi Konteks Operasional Proyek
├── README.md                              # Dokumentasi Publik dan Petunjuk Proyek
└── project.godot                          # Konfigurasi Utama Godot Engine
```

### B. Prinsip Arsitektur & Aturan Kolaborasi:
1. **Aturan `.gitkeep` untuk Folder Kosong:**  
   Git secara bawaan tidak melacak direktori kosong. Seluruh folder baru yang belum memiliki file aset aktif (misal: `assets/enemies/`, subfolder `assets/ui/`, `assets/audio/`, dan `scene/ui/`) wajib diberi file penanda kosong bernama `.gitkeep` agar hierarki folder tetap terlacak dan konsisten saat di-clone oleh anggota tim lain.
2. **Pemisahan `assets/ui/` vs. `scene/ui/`:**  
   - `assets/ui/` khusus menampung aset visual mentah (PNG, SVG), tekstur 9-slice, ikon, dan file font tipografi (.ttf/.otf). Dilarang meletakkan script `.gd` atau scene `.tscn` di folder ini.
   - `scene/ui/` khusus menampung implementasi node Godot UI berbasis `Control` atau `CanvasLayer` beserta logika interaksinya (`.gd`).
3. **Status Entitas Reticle / Indicator Tempur:**  
   `meteor_indicator.tscn` (Node2D) dan `skill_indicator.tscn` (Node2D) adalah *world-space reticle*, sedangkan `skill_aoe_effect.tscn` adalah *Area2D combat hitbox*. Ketiganya tetap berada di domain combat/proyektil (`scene/projectile/`) dan **dilarang dipindahkan ke `scene/ui/`**.
4. **Alokasi Sprite Karakter:**  
   `assets/characters/` digunakan untuk seluruh sprite animasi karakter (baik Hero Party maupun karakter musuh seperti Bandit). Aset Bandit tetap berada di `assets/characters/bandit/`. Folder `assets/enemies/` disiapkan kosong untuk musuh monster/non-humanoid di masa depan.

### C. Tanggung Jawab Komponen Kunci:
1. **`scene/game.gd` (Game & Party Manager):**
   - Root scene `game.tscn` terpusat pada origin `Vector2(0, 0)` sehingga menyelaraskan koordinat global entitas hero, musuh, pembatas map (`WorldBorders`), dan layer peta `map_region_1`.
   - Mendaftarkan 4 anggota party (`Knight_1`, `Bandit_1`, `Archer_1`, `Mage_1`).
   - Mengelola pergantian Leader aktif (validasi hidup/mati siklis via Tab dan pemilihan langsung angka 1–4 dengan pengabaian hero yang gugur) dan penugasan slot antrean Follower (slot 1, 2, dan 3).
   - Menghitung riwayat jejak langkah (*breadcrumbs queue*) dan pembalikan antrean 180° (*cascade swap*).
   - Mengendalikan pergerakan kamera halus (*position smoothing*), offset target (+45 px vertikal), dan screen shake.
   - Memindai Rect2 kamera (+50 px margin) setiap 0.15 detik untuk memicu aggro tempur saat musuh terlihat di layar.
   - Menghasilkan dinding pembatas map (*WorldBorders*) secara dinamis saat runtime dari Rect layer `Ground`.
2. **`scene/player/player_knight.gd`:**
   - Logika kontrol manual Leader (WASD, sprint) dan otonom Follower petarung melee.
   - Serangan dasar tebasan pedang mouse-directed berbasis geometri sapuan busur (*direct arc sweep* 170° hingga 125 px sesuai skala sprite 5x) dan kontak dekat (*close-contact proximity* 65 px sekeliling badan Knight, damage 2, knockback 300 px/s, camera shake 7.0) yang berpusat presisi pada titik tengah torso karakter di ruang global (`SLASH_CENTER_OFFSET` / `VISUAL_CENTER_OFFSET = Vector2(0.0, 7.5)`, setara `y=1.5` lokal) sehingga jangkauan simetris ke 4 arah mata angin (North, South, East, West). Serangan disinkronkan presisi dengan jeda ancang-ancang visual (`SLASH_WINDUP_DELAY = 0.18s`, frame 0-2) sebelum mengaktifkan window deteksi dampak tebasan 200ms (`SLASH_ACTIVE_DURATION = 0.20s`), serta dapat diayunkan secara bebas tanpa penguncian target artifisial.
   - Skill khusus tombol `E`: *Shield Guard* (durasi 3.5s, cooldown 6.0s; hanya dapat diaktifkan oleh pemain saat Knight menjadi Leader aktif. Merapalkan pelindung perisai ke seluruh anggota party sekaligus: Knight, Mage, dan Archer. Perisai muncul tegak presisi di tengah visual tubuh masing-masing karakter setelah animasi rapalan Knight selesai dengan transisi fade-in/fade-out, tetap aktif saat pergantian karakter hingga durasi habis, serta menahan 100% damage serangan musuh untuk seluruh party).
   - Perilaku AI tempur Follower: mendekati musuh hingga jarak melee (85 px), menebas berulang setiap 1.2s saat mode komando ATTACK (V), dan dilarang mengaktifkan skill secara otomatis.
   - Penanganan penerimaan damage (tanpa dorongan knockback saat karakter terkena hit), siklus kematian (fade-out merah, pelepasan grup `player`, auto-switch jika leader aktif, `visible = false`), dan respawn (3s) dengan pemulihan ke grup `player`, fade-in, serta sinkronisasi status party terkini (`party_command`, `in_party_combat`, dan `target_position`).
3. **`scene/player/player_bandit.gd` & `scene/player/player_bandit.tscn`:**
   - Logika kontrol manual Leader (WASD, sprint) dan otonom Follower petarung melee lincah (Slot 2).
   - Serangan dasar *Double Slash Dagger* via klik kiri: dua tebasan berurutan (Swing 1 pada ~0.15s, Swing 2 pada ~0.40s) dengan area sapuan busur melee 160° hingga 130 px (dan adaptasi jangkauan tebasan South 140 px, 180°), masing-masing berdaya rusak 2 (total 4 damage per siklus), jeda cooldown 0.85s, dan terdistribusi ritmis selaras animasi `atk-[e|w|n|s].png`. Serangan tidak memberikan dorongan knockback horizontal pada musuh.
   - Kemampuan pasif *Out-of-Combat Ambush Lunge*: aktif setelah 5 detik tanpa menerima maupun memberikan damage, ditandai visual aura berpendar halus (`modulate` cyan lembut). Saat aktif, serangan dasar pertama memperoleh jangkauan engage luas (260 px), Bandit meluncur lunge dengan kecepatan tinggi (680 px/s) ke arah musuh terdekat dari kursor, memberikan bonus damage +3 pada tebasan pembuka (total 5 damage pembuka), mengonsumsi status pasif, serta memicu screen shake. Dilengkapi perlindungan *Super Armor* (tidak dapat diinterupsi oleh serangan musuh, dan tidak terhalang buff perisai Knight).
   - Skill khusus tombol `E`: *Dash, Knockup & Triple Slash* (hanya dapat diaktifkan saat Bandit menjadi Leader aktif; dilarang auto-cast saat menjadi follower):
     1. Fase Dash: meluncur kencang (750 px/s) ke arah target kursor mouse hingga maksimal 0.35s dengan animasi skill `skill_[n|s|e|w]` aktif sepanjang luncuran. Jika dash tidak menabrak musuh (miss), animasi skill tetap dituntaskan secara mulus hingga frame terakhir sebelum bertransisi ke idle/run.
     2. Fase Knockup & Triple Slash: dash berhenti seketika saat menabrak musuh pertama di jalurnya (`check_dash_collision_enemy()`). Seluruh visual dan sisa animasi dash dihentikan dan dibersihkan seketika (`animated_sprite.stop()`), lalu beralih 100% secara bersih ke animasi kombo `triple_slash` pada node `AnimatedSprite2D` utama tanpa adanya sprite ganda yang tertinggal. Musuh yang tertabrak terangkat vertikal di tempat (*knockup* ~40 px via tween parabolik) dan terkena stun selama 0.70s tanpa pergeseran horizontal. Seketika memicu kombo 3x tebasan beruntun (Step 1 pada 0.10s, Step 2 pada 0.26s, Step 3 pada 0.42s; masing-masing berdaya rusak 2, total 6 damage combo). Cooldown 5.0 detik baru mulai berjalan setelah rangkaian aksi tuntas.
   - Status *Super Armor / Poise*: Selama eksekusi Ambush Lunge dan sepanjang rangkaian Skill 'E' (dash hingga tebasan ke-3 tuntas), Bandit kebal terhadap interupsi/pembatalan aksi dan knockback dari serangan musuh (HP tetap berkurang normal jika tidak memiliki perisai).
   - Penyelarasan visual sprite: `offset = Vector2(0, 5)` pada sprite 96x96 untuk menyelaraskan baseline kaki (+60 px) presisi dengan Knight dan Mage, collision shape `Vector2(0, 5.6)`, dan integrasi debu lari 8-arah.
   - Penanganan proteksi hit: knockback standar (`knockback_strength = 380.0`, `knockback_decay = 1400.0`), interupsi bersih saat bukan dalam aksi super armor tanpa freeze/deadlock via reset flag, dan safeguard `require_mouse_release`. Proteksi perisai Knight (Shield Guard) 100% menahan damage tanpa membatalkan serangan keluar atau mereset pasif Bandit.
4. **`scene/player/player_mage.gd`:**
   - Logika pergerakan dan formasi party (arsitektur serupa dengan Archer).
   - Serangan dasar bola sihir (`magic_bolt.tscn`) via klik kiri yang diselaraskan presisi di tengah dan tepat di ujung kepala senjata tongkat sihir saat mengarah ke depan (`BASIC_ATTACK_STAFF_OFFSET = Vector2(0.0, 47.0)` di ruang global, offset maju 92 px), fungsi pemosisian spawn adaptif 8-arah (`get_magic_bolt_spawn_position()`) berbasis `match last_direction` dengan safeguard sinkronisasi arah hadap horizontal sprite (`flip_h`) agar proyektil tidak pernah spawn di belakang tubuh karakter saat menembak diagonal, serta timing pelepasan sihir instan (~0.34s, Frame 4) tepat saat tongkat mengarah ke depan bersamaan dengan letupan animasi efek sihir dan watchdog `attack_stuck_timer` (0.8s) agar seluruh animasi serangan selesai secara alami.
   - Skill khusus tombol `E`: *Meteor Strike AoE* (indikator radius di kursor mouse, memanggil meteor jatuh).
5. **`scene/player/player_archer.gd`:**
   - Logika kontrol manual Leader (WASD, sprint).
   - Logika otonom Follower (mode menjelajah berbaris vs mode bertempur mandiri).
   - Serangan dasar panah (`arrow.tscn`) via klik kiri.
   - Skill khusus tombol `E`: *Charged Line Snipe* (kuota 3 tembakan, durasi 10s, indikator memanjang elastis).
   - Penyelarasan visual sprite (`offset = Vector2(0, 4)`), titik torso/skill (`VISUAL_CENTER_OFFSET = Vector2(2.5, 26.0)`), serta titik spawn basic attack proyektil panah (`BASIC_ATTACK_ARROW_OFFSET = Vector2(2.5, 35.0)`) agar presisi sejajar dengan senjata busur di tangan dan baseline kaki sejajar dengan Knight dan Mage.
   - Algoritma raycasting manuver melipir rintangan (*flanking waypoints*).
   - Penanganan penerimaan damage (tanpa dorongan knockback saat karakter terkena hit), kematian (fade-out), dan respawn (3s).
6. **`scene/enemy/enemy.gd`:**
   - State AI musuh: `IDLE_PATROL` dan `CHASE`.
   - Serangan panah jarak jauh (320 px) dan kontak fisik (1 damage) dengan pelacakan hitbox multi-hero yang aman (mempertahankan status kontak dan siklus cooldown selama setidaknya satu hero hidup berada di dalam hitbox).
   - Bar HP ganda (merah untuk HP riil, kuning untuk animasi lag pengurangan damage).
   - Sistem memori ancaman (*threat-aggro*) terhadap karakter yang melukainya.
   - Respawn musuh otomatis setelah 4 detik.

---

## 4. DAFTAR KARAKTER & SKEMA KONTROL GAMEPLAY

### Komposisi Party (Indeks 0–3):
- **Slot 1 (Indeks 0):** `Knight_1` (Leader default saat game dimulai, petarung melee & shield)
- **Slot 2 (Indeks 1):** `Bandit_1` (Rogue lincah, tebasan melee double swing / double damage & skill Triple Slash)
- **Slot 3 (Indeks 2):** `Archer_1` (Ranged sniper, tembakan panah lurus & skill Charged Line Snipe)
- **Slot 4 (Indeks 3):** `Mage_1` (Ranged caster, tembakan bola sihir & skill Meteor Strike)

### Skema Input (Terverifikasi dalam Pengujian Manual):
- `W`, `A`, `S`, `D` / Panah: Gerak manual Leader.
- Tahan `Shift`: Sprint Leader dan Follower + memunculkan partikel debu lari.
- `Tab`: Pergantian Leader berurutan secara siklis (1 ➔ 2 ➔ 3 ➔ 4 ➔ 1).
- Angka `1`, `2`, `3`, `4`: Memilih Leader secara langsung sesuai nomor slot (1: Knight, 2: Bandit, 3: Archer, 4: Mage).
- Tombol `C`: Komando **FOLLOW** (follower dilarang menyerang, wajib berada di barisan).
- Tombol `V`: Komando **ATTACK** (follower diizinkan keluar barisan dan bertarung mandiri).
- `Klik Kiri`: Serangan dasar (Tebasan Melee Knight / Ayunan Ganda Double Damage Bandit / Panah Archer / Bola Sihir Mage).
- Tombol `E`: Masuk ke mode skill khusus karakter aktif (Knight: Shield Guard, Bandit: Triple Slash, Archer: Charged Line Snipe, Mage: Meteor Strike).

---

## 5. MEKANIK DAN SISTEM UTAMA

1. **Breadcrumb Trail & Cascade Swap 180°:**
   Leader merekam koordinat setiap melangkah sejauh 8 px (maksimal 65 titik). Follower menempati slot dengan jarak `slot_index * 85.0 px`. Jika Leader berputar balik 180° melewati barisannya, antrean dibalik secara estafet agar follower langsung berada di belakang arah baru tanpa kusut.
2. **Peralihan Mode Tempur Viewport:**
   Jika musuh masuk ke layar kamera, `game.gd` mengubah state ke `COMBAT` dan follower mulai menyerang mandiri (jika dalam komando `ATTACK`). Ketika musuh musnah atau keluar layar, ada jeda *wind-down* 0.4 detik sebelum kembali ke mode `EXPLORING`.
3. **Flanking Navigasi:**
   Unit melakukan raycast langsung ke target pada Collision Layer 1. Jika terhalang, sistem melakukan probe melintang (24–720 px) ke sisi kiri dan kanan untuk mencari celah tepi rintangan, lalu membuat dua titik pandu (*waypoints*) untuk melipir.
4. **Siklus Kematian & Respawn:**
   Unit hero yang mencapai HP 0 mematikan collision-nya, melepaskan keanggotaan grup `player` agar tidak ditarget musuh/proyektil saat gugur, memicu auto-switch kendali ke anggota party lain yang masih hidup jika berstatus Leader aktif, memudar (fade-out merah), disembunyikan (`visible = false`), menunggu timer respawn (3s untuk hero, 4s untuk musuh), lalu bangkit kembali di posisi awal dengan HP penuh, didaftarkan kembali ke grup `player`, ditampilkan kembali dengan fade-in halus, serta menyinkronkan status komando party (`party_command`, `in_party_combat`, `target_position`).
5. **Sistem Kecepatan Proyektil Dasar & Penyeimbangan Fire Rate:**
   Kecepatan terbang proyektil panah dibuat seragam sebesar 580 px/s untuk Archer (baik terkendali maupun follower) serta musuh archer. Kecepatan proyektil bola sihir Mage disesuaikan dikurangi sedikit menjadi 500 px/s dan dibuat sama baik saat dikendalikan (Leader) maupun tidak dikendalikan (follower). Sedangkan *basic attack fire rate* diselaraskan secara konsisten antara karakter yang dikendalikan, follower, dan musuh model archer: frekuensi tembakan Archer (Leader dan follower) serta musuh archer sama-sama berjarak 1.4s, sementara Mage (Leader dan follower) sama-sama berjarak 1.5s.
6. **Sistem Soft Collision & Separasi Dinamis:**
   Seluruh karakter hero (`player_knight.gd`, `player_archer.gd`, `player_mage.gd`) dan unit musuh (`enemy.gd`) mengadopsi `motion_mode = CharacterBody2D.MOTION_MODE_FLOATING`, pengecualian tabrakan fisik timbal balik (*collision exceptions*) antar-hero dan musuh, serta fungsi `move_and_slide_with_separation()`. Pengecualian tabrakan fisik melenyapkan bug saling mengunci atau menyeret saat bertumpuk (*sticky collision lock*), sementara kalkulasi dorongan separasi (`min_sep_dist = 55.0 px`, dibatasi `limit_length(55.0) * 8.0`) memisahkan karakter secara halus dan natural. Pada musuh penembak, diterapkan batas henti jarak serang (berhenti pada `dist <= 140.0 px` atau `dist <= shoot_range`) serta manuver mundur (*kiting* jika `dist < 80.0 px`) sehingga tidak pernah menerobos menempel ke 0 px. Raycast garis pandang (*LoS*) dan navigasi celah menggunakan `Array[RID]` terfilter yang hanya diblokir oleh rintangan dunia nyata (`TileMapLayer` dan `StaticBody2D`).
7. **Sistem Partikel Debu Berlari (Run Dust):**
   Partikel debu lari (`run_dust.tscn`) disinkronkan secara konsisten di seluruh 8 arah mata angin (East, West, South, North, NE, NW, SE, SW) untuk seluruh hero (`Knight`, `Mage`, `Archer`). Pemosisian kepulan debu menggunakan offset adaptif (`feet_y = 36–38 px` dan `lag_y = 10 px` untuk arah North/NE/NW) dengan `z_index = 3` tepat di bawah karakter (`z_index = 4`) dan di atas lantai/bayangan (`z_index = 0–2`), memastikan kepulan debu tidak tertutup jubah/baju zirah saat bergerak ke atas. Pemanggilan debu dieksekusi secara terpusat pada siklus fisika baik untuk Leader maupun Follower saat berlari sprint (`velocity.length() >= NORMAL_SPEED * 1.35`).
8. **Penyelarasan Baseline Visual & Y-Sorting Karakter:**
   Seluruh hero (`Knight`, `Mage`, `Archer`) diselaraskan memiliki batas bawah pijakan kaki (*visual feet baseline*) pada posisi origin dunia yang seragam (`+55.0 px` di bawah origin node). Pada Archer (`player_archer.tscn`), `AnimatedSprite2D` dikonfigurasi dengan `offset = Vector2(0, 4)` sehingga meniadakan masalah visual karakter mengambang/naik 20 px dibanding Knight dan Mage. Seluruh titik kalkulasi visual Archer (`CollisionShape2D` di `Vector2(0, 5.6)`, `SHIELD_CENTER_OFFSET = Vector2(0.0, 4.0)`, `VISUAL_CENTER_OFFSET = Vector2(2.5, 26.0)`, titik tembak panah `BASIC_ATTACK_ARROW_OFFSET = Vector2(2.5, 35.0)` sejajar senjata busur, serta titik pijakan partikel debu lari `feet_y = 36–38 px`) disinkronkan presisi agar Y-sorting dan proyeksi serangan panah tetap konsisten. Titik pusat tebasan dan LOS Knight juga disinkronkan secara simetris menggunakan `VISUAL_CENTER_OFFSET` / `SLASH_CENTER_OFFSET = Vector2(0.0, 7.5)` di ruang global (setara posisi perisai lokal `SHIELD_CENTER_OFFSET = Vector2(0.0, 1.5)`). Titik tembak dan bidikan dasar bola sihir Mage juga diselaraskan presisi dengan posisi tengah dan ujung senjata tongkat saat mengarah ke depan (`BASIC_ATTACK_STAFF_OFFSET = Vector2(0.0, 47.0)`, offset 92 px, timing rilis 0.34s bersamaan dengan letupan efek sabit sihir di Frame 4, dan watchdog 0.8s) agar proyektil keluar tepat di tengah dan ujung tongkat di seluruh arah.
9. **Penyesuaian Geometri Tebasan Bawah Knight & Peniadaan Knockback Hero Saat Terkena Hit:**
   Jangkauan tebasan Knight ke arah bawah (South / `attack_dir.y > 0.3`) diperluas menjadi `slash_range = 160.0 px`, `close_contact_radius = 85.0 px`, `slash_arc_deg = 180.0°`, serta titik pusat digeser ke bawah (`center_offset = Vector2(0.0, 32.0)`) sehingga proporsional dan selaras sempurna dengan animasi ayunan pedang ke bawah. Efek knockback dorongan mundur pada seluruh hero (`Knight`, `Archer`, `Mage`) saat menerima damage dari musuh (`take_damage()`) maupun saat memblokir dengan Shield Guard telah dihilangkan sepenuhnya (`knockback_strength = 0.0`), sehingga posisi hero tetap stabil dan tidak tersentak mundur saat diserang. Pembatalan status serang/skill (`cancel_attack()` / `cancel_skill()`), feedback visual kedip warna, dan proteksi i-frame tetap dipertahankan agar responsivitas kontrol tetap terjaga.
10. **Proteksi Double Damage & Invulnerability Frame (i-frame):**
    Seluruh hero (`Knight`, `Mage`, `Archer`) dilengkapi dengan jeda kebal singkat (`invulnerability_duration = 0.25s`) pasca menerima hit untuk mencegah akumulasi damage ganda saat berdekatan/menempel dengan musuh. Pada `enemy.gd`, tembakan panah jarak dekat secara otomatis menyinkronkan cooldown kontak (`damage_timer = max(damage_timer, 0.6)`), memastikan tidak terjadi tumpang tindih antara damage panah instan dan damage kontak fisik dalam satu kali siklus serangan. Proyektil panah musuh (`arrow.gd`) juga memproyeksikan arah knockback selaras dengan vektor lintasannya (`direction`).
11. **Mekanik Khusus Hero Bandit (Double Slash, Ambush Passive, Dash Knockup Triple Slash):**
    - **Double Slash Dagger:** Serangan melee ritmis dua ayunan berurutan (jeda 0.15s dan 0.40s) selaras frame visual belati `atk-[e|w|n|s].png`. Menghasilkan 2 damage per tebasan (total 4 damage) dengan sapuan busur 160° hingga 130 px (dan adaptasi jangkauan bawah 140 px, 180°). Tidak memberikan dorongan knockback horizontal pada musuh.
    - **Out-of-Combat Ambush Lunge:** Timer 5 detik tanpa menerima maupun memberikan damage. Ditandai modulasi visual aura berpendar halus (`modulate` cyan lembut). Saat aktif, serangan dasar pertama memperoleh jangkauan *engage* luas (260 px), Bandit meluncur kencang (680 px/s) ke musuh terdekat dari kursor, memberikan bonus damage +3 pada tebasan pertama (total 5 damage pembuka), mengonsumsi status pasif, serta memicu screen shake. Dilengkapi *Super Armor* dan pengecualian perisai party sehingga damage 100% masuk tanpa terblokir collider/buff sendiri.
    - **Dash, Knockup & Triple Slash (Tombol E):** Skill aktif khusus Leader (follower Bandit dilarang auto-cast). Meluncur kencang (750 px/s) ke target kursor hingga 0.35s dengan animasi `skill_[n|s|e|w]` aktif sepanjang luncuran (dan menuntaskan frame visual jika miss sebelum kembali ke idle/run). Dash berhenti seketika saat menabrak musuh pertama di jalurnya (`check_dash_collision_enemy()`); seluruh visual dan sisa animasi dash dihentikan seketika (`animated_sprite.stop()`), lalu beralih 100% secara bersih ke animasi kombo `triple_slash` pada node `AnimatedSprite2D` utama tanpa adanya sprite ganda yang tertinggal. Musuh yang tertabrak terangkat melayang ke udara secara vertikal (*knockup* ~40 px via tween parabolik) dan terkena stun selama 0.70s tanpa pergeseran horizontal. Seketika memicu kombo 3x tebasan beruntun (Step 1 pada 0.10s, Step 2 pada 0.26s, Step 3 pada 0.42s; masing-masing berdaya rusak 2, total 6 damage combo). Dilengkapi *Super Armor* penuh (tidak dapat dibatalkan atau didorong knockback oleh serangan musuh). Cooldown 5.0 detik baru mulai berjalan setelah rangkaian aksi tuntas.

---

## 6. STATUS PENGUJIAN & CATATAN PENGEMBANGAN

### A. Fitur yang Berhasil dalam Skenario Pengujian yang Telah Dilakukan:
Klaim berikut dibatasi secara ketat pada skenario pengujian dasar yang telah dijalankan, dan **tidak mengasumsikan seluruh *edge case* telah teruji**:

- **Pergerakan Leader & Formasi Follower:** Berhasil via WASD; follower mengekor dan merespons U-turn 180° (*Diverifikasi via pengamatan manual user*).
- **Pergantian Leader & Sinkronisasi Kamera:** Berhasil via tombol Tab dan angka 1–4 (*Diverifikasi via pengamatan manual user & log runtime*).
- **Komando Party FOLLOW (C) dan ATTACK (V):** Berhasil mengubah perilaku kawal barisan vs serang mandiri (*Diverifikasi via pengamatan manual user & log runtime*).
- **Implementasi Hero Bandit (Double Slash, Ambush Lunge, Dash Knockup Triple Slash & Super Armor):** Bandit berfungsi penuh sebagai anggota party ke-2 (Slot 2); double slash ritmis 2x hit (2 damage per ayunan), pasif ambush lunge out-of-combat 5s dengan aura visual dan bonus damage (+3) yang tetap memberikan damage 100% saat memiliki perisai Knight, dash cepat dengan animasi skill penuh bahkan saat meleset (miss), knockup vertikal di tempat & stun musuh tanpa pergeseran horizontal kombo triple slash 3x hit selaras visual sprite terpisah, perlindungan Super Armor/Poise selama aksi pasif dan skill 'E', follower Bandit disiplin basic attack, serta baseline visual kaki selaras dengan Knight dan Mage (*Diverifikasi via validasi headless engine & inspeksi kode sumber*).
- **Serangan Dasar (Klik Kiri):** Tebasan pedang Knight (direct arc sweep & proximity check), panah Archer, dan bola sihir Mage berhasil diarahkan ke kursor dan mengenai musuh (*Diverifikasi via pengamatan manual user & validasi headless engine*).
- **Sistem Soft Collision & Separasi Karakter:** Seluruh anggota party dan musuh saling mendorong secara elastis saat bertabrakan/menempel tanpa terjadi getaran macet atau penguncian posisi (*Diverifikasi via validasi headless engine*).
- **Skill Khusus (Tombol E):** *Shield Guard* Knight (hanya aktif saat menjadi Leader), *Charged Line Snipe* Archer, dan *Meteor Strike* Mage berhasil diaktifkan dan memberikan dampak taktis (*Diverifikasi via pengamatan manual user*).
- **Partikel Debu Berlari (Run Dust):** Partikel debu muncul konsisten di 8 arah mata angin saat sprint bagi Leader dan Follower pada Knight, Mage, dan Archer tanpa terhalang jubah karakter (*Diverifikasi via validasi headless engine*).
- **Kesejajaran Baseline & Y-Sorting Party:** Seluruh karakter hero (Knight, Mage, Archer) berdiri sejajar secara horizontal dengan pijakan kaki menyentuh tanah pada baseline yang sama (+55 px) tanpa ada karakter yang tampak mengambang (*Diverifikasi via validasi headless engine*).
- **Peniadaan Knockback Hero Saat Terkena Damage:** Seluruh karakter hero (Knight, Archer, Mage) tidak lagi terdorong/tersentak mundur saat menerima damage dari musuh maupun saat memblokir serangan dengan Shield Guard, menjaga stabilitas posisi tempur (*Diverifikasi via validasi headless engine & inspeksi kode sumber*).
- **Jangkauan Tebasan Bawah Knight:** Tebasan pedang ke arah South konsisten mengenai musuh di area visual sapuan bilah pedang berkat penyesuaian offset pusat tebasan (+32 px) dan radius jangkauan 160 px (*Diverifikasi via validasi headless engine*).
- **Peniadaan Double Damage Kontak Musuh:** Hero tidak lagi menerima damage ganda saat berdekatan/menempel dengan musuh berkat implementasi i-frame (0.25s) dan desinkronisasi tembakan jarak dekat di AI musuh (*Diverifikasi via validasi headless engine*).
- **Interupsi Bersih Skill & Pencegahan Freeze Archer:** Archer tidak lagi mengalami deadlock/freeze ketika menerima damage/knockback saat sedang menahan charging skill 'E' berkat pemulihan state aman ke READY, token pembatalan serangan (`attack_token`), pencegahan penahanan klik mouse (`require_mouse_release`), serta timeout cadangan pada siklus animasi (*Diverifikasi via validasi headless engine*).
- **Sinkronisasi Posisi & Pembatalan Peluncuran Sihir Mage:** Proyektil bola sihir Mage kini dihitung posisinya secara dinamis tepat di ujung tongkat sihir dan secara otomatis digugurkan jika Mage terinterupsi oleh serangan musuh/knockback di tengah jeda windup cast, menghilangkan kemunculan proyektil gaib pada koordinat usang (*Diverifikasi via validasi headless engine*).
- **Siklus Kematian & Respawn:** Pengurangan HP saat terkena serangan musuh, transisi mati (fade-out), timer tunggu, dan kemunculan kembali karakter berhasil berjalan normal (*Diverifikasi via pengamatan manual user & log runtime*).

> **Catatan Sumber Verifikasi Parameter:**  
> Parameter numerik internal seperti kecepatan gerak (128 px/s normal, 220 px/s sprint), kecepatan dasar proyektil (panah 580 px/s untuk Archer dan musuh, magic bolt 500 px/s untuk Mage baik terkendali maupun tidak), rasio kesetaraan proyektil (1.0), durasi cooldown serangan dasar (1.4s untuk Archer Leader/follower/musuh archer, 1.5s untuk Mage Leader/follower) / skill, kekuatan dorongan knockback (`knockback_strength`), laju redaman (`knockback_decay = 1400.0`), jarak antrean (85 px), serta interval pemindaian aggro (0.15s) bersumber dari **inspeksi kode sumber dan log runtime**, bukan hasil pengukuran stopwatch manual pemain.

### B. Masalah yang Sengaja Ditunda (*Deferred Issues*):
- **Penyempurnaan AI Musuh & Flanking Navigasi:**
  Algoritma perhitungan waypoint raycast musuh dan follower saat membentur objek lingkungan masih memerlukan perbaikan perilaku navigasi.
  > **PERINGATAN:** Catatan penundaan ini **BUKAN** merupakan izin untuk langsung mengerjakannya tanpa permintaan atau instruksi eksplisit dari pengguna.

### C. Technical Debt & Rencana Masa Depan (*Backlog*):
*(Hanya dikerjakan jika secara spesifik diminta oleh pengguna)*
1. **Refactoring Base Character:** Penggabungan duplikasi logika (~80%) antara `player_knight.gd`, `player_archer.gd`, dan `player_mage.gd` ke dalam kelas dasar bersama.
2. **UI / HUD Pemain:** Tampilan bar HP party di layar, indikator cooldown skill visual, dan ikon status komando.
3. **Sistem Audio:** Integrasi BGM dan SFX (langkah, tembakan busur, sihir, ledakan, hit).
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
