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
  Pemain mengendalikan 1 *Leader* aktif dan 3 *Follower* otonom (total 4 hero: 2 Archer dan 2 Mage). Anggota party mengekor di belakang Leader dalam barisan dinamis (*snake breadcrumb queue*). Pemain dapat menukar kendali Leader secara instan, mengubah mode komando taktis (*Follow / Attack*), melepaskan serangan proyektil dan skill area (AoE), serta memanfaatkan manuver melipir rintangan (*flanking*).

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
  - Pengecualian tabrakan (*collision exception*) diterapkan antar-seluruh anggota party via `add_collision_exception_with()` agar tidak saling mendorong.

---

## 3. STRUKTUR DIREKTORI & MODUL UTAMA

```text
flank/
├── assets/                  # Seluruh aset visual (spritesheet karakter, tileset, proyektil)
│   ├── characters/          # Animasi 4-arah Archer, Mage, dan Knight (idle, walk, attack, skill)
│   ├── particles/           # Partikel debu lari (dust.png, dust_puff.png)
│   ├── projectile/          # Tekstur panah, trace trail, dan magic bolt
│   ├── skills/              # Indikator dan efek visual skill Archer, Mage, & Knight
│   └── tileset/             # Spritesheet SunnySide World 16px
├── scene/                   # Logika kode sumber dan hierarki node
│   ├── effect/              # Efek visual mandiri (run_dust.tscn / .gd)
│   ├── enemy/               # AI dan prefab musuh (enemy.tscn / .gd)
│   ├── player/              # Entitas hero (player_archer dan player_mage)
│   ├── projectile/          # Proyektil dan efek area (arrow, magic_bolt, meteor)
│   ├── world/               # Peta TileMapLayer (map_region_1.tscn)
│   ├── game.gd              # Controller utama party, kamera, dan boundary
│   └── game.tscn            # Main Scene game
├── PROJECT_CONTEXT.md       # Dokumentasi konteks operasional proyek
└── project.godot            # Konfigurasi engine Godot
```

### Tanggung Jawab Komponen Kunci:
1. **`scene/game.gd` (Game & Party Manager):**
   - Mendaftarkan 4 anggota party (`Archer_1`, `Mage_1`, `Archer_2`, `Mage_2`).
   - Mengelola pergantian Leader aktif dan penugasan slot antrean Follower (slot 1, 2, 3).
   - Menghitung riwayat jejak langkah (*breadcrumbs queue*) dan pembalikan antrean 180° (*cascade swap*).
   - Mengendalikan pergerakan kamera halus (*position smoothing*), offset target (+45 px vertikal), dan screen shake.
   - Memindai Rect2 kamera (+50 px margin) setiap 0.15 detik untuk memicu aggro tempur saat musuh terlihat di layar.
   - Menghasilkan dinding pembatas map (*WorldBorders*) secara dinamis saat runtime dari Rect layer `Ground`.
2. **`scene/player/player_archer.gd`:**
   - Logika kontrol manual Leader (WASD, sprint).
   - Logika otonom Follower (mode menjelajah berbaris vs mode bertempur mandiri).
   - Serangan dasar panah (`arrow.tscn`) via klik kiri.
   - Skill khusus tombol `E`: *Charged Line Snipe* (kuota 3 tembakan, durasi 10s, indikator memanjang elastis).
   - Algoritma raycasting manuver melipir rintangan (*flanking waypoints*).
   - Penanganan knockback decay, penerimaan damage, kematian (fade-out), dan respawn (3s).
3. **`scene/player/player_mage.gd`:**
   - Logika pergerakan dan formasi party (arsitektur serupa dengan Archer).
   - Serangan dasar bola sihir (`magic_bolt.tscn`) via klik kiri.
   - Skill khusus tombol `E`: *Meteor Strike AoE* (indikator radius di kursor mouse, memanggil meteor jatuh).
4. **`scene/enemy/enemy.gd`:**
   - State AI musuh: `IDLE_PATROL` dan `CHASE`.
   - Serangan panah jarak jauh (320 px) dan kontak fisik (1 damage).
   - Bar HP ganda (merah untuk HP riil, kuning untuk animasi lag pengurangan damage).
   - Sistem memori ancaman (*threat-aggro*) terhadap karakter yang melukainya.
   - Respawn musuh otomatis setelah 4 detik.

---

## 4. DAFTAR KARAKTER & SKEMA KONTROL GAMEPLAY

### Komposisi Party (Indeks 0–3):
- **Slot 1 (Indeks 0):** `Archer_1` (Leader default saat game dimulai)
- **Slot 2 (Indeks 1):** `Mage_1`
- **Slot 3 (Indeks 2):** `Archer_2`
- **Slot 4 (Indeks 3):** `Mage_2`

### Skema Input (Terverifikasi dalam Pengujian Manual):
- `W`, `A`, `S`, `D` / Panah: Gerak manual Leader.
- Tahan `Shift`: Sprint Leader dan Follower + memunculkan partikel debu lari.
- `Tab`: Pergantian Leader berurutan secara siklis (1 ➔ 2 ➔ 3 ➔ 4 ➔ 1).
- Angka `1`, `2`, `3`, `4`: Memilih Leader secara langsung sesuai nomor slot.
- Tombol `C`: Komando **FOLLOW** (follower dilarang menyerang, wajib berada di barisan).
- Tombol `V`: Komando **ATTACK** (follower diizinkan keluar barisan dan bertarung mandiri).
- `Klik Kiri`: Serangan dasar (Panah / Magic Bolt).
- Tombol `E`: Masuk ke mode skill khusus karakter aktif.

---

## 5. MEKANIK DAN SISTEM UTAMA

1. **Breadcrumb Trail & Cascade Swap 180°:**
   Leader merekam koordinat setiap melangkah sejauh 8 px (maksimal 65 titik). Follower menempati slot dengan jarak `slot_index * 85.0 px`. Jika Leader berputar balik 180° melewati barisannya, antrean dibalik secara estafet agar follower langsung berada di belakang arah baru tanpa kusut.
2. **Peralihan Mode Tempur Viewport:**
   Jika musuh masuk ke layar kamera, `game.gd` mengubah state ke `COMBAT` dan follower mulai menyerang mandiri (jika dalam komando `ATTACK`). Ketika musuh musnah atau keluar layar, ada jeda *wind-down* 0.4 detik sebelum kembali ke mode `EXPLORING`.
3. **Flanking Navigasi:**
   Unit melakukan raycast langsung ke target pada Collision Layer 1. Jika terhalang, sistem melakukan probe melintang (24–720 px) ke sisi kiri dan kanan untuk mencari celah tepi rintangan, lalu membuat dua titik pandu (*waypoints*) untuk melipir.
4. **Siklus Kematian & Respawn:**
   Unit yang mencapai HP 0 mematikan collision-nya, memudar (fade-out), menunggu timer respawn (3s untuk player, 4s untuk musuh), lalu bangkit kembali di posisi awal dengan HP penuh.
5. **Sistem Kecepatan Proyektil Dasar & Penyeimbangan Fire Rate:**
   Kecepatan terbang proyektil panah dibuat seragam sebesar 580 px/s untuk Archer (baik terkendali maupun follower) serta musuh archer. Kecepatan proyektil bola sihir Mage disesuaikan dikurangi sedikit menjadi 500 px/s dan dibuat sama baik saat dikendalikan (Leader) maupun tidak dikendalikan (follower). Sedangkan *basic attack fire rate* diselaraskan secara konsisten antara karakter yang dikendalikan, follower, dan musuh model archer: frekuensi tembakan Archer (Leader dan follower) serta musuh archer sama-sama berjarak 1.4s, sementara Mage (Leader dan follower) sama-sama berjarak 1.5s.

---

## 6. STATUS PENGUJIAN & CATATAN PENGEMBANGAN

### A. Fitur yang Berhasil dalam Skenario Pengujian yang Telah Dilakukan:
Klaim berikut dibatasi secara ketat pada skenario pengujian dasar yang telah dijalankan, dan **tidak mengasumsikan seluruh *edge case* telah teruji**:

- **Pergerakan Leader & Formasi Follower:** Berhasil via WASD; follower mengekor dan merespons U-turn 180° (*Diverifikasi via pengamatan manual user*).
- **Pergantian Leader & Sinkronisasi Kamera:** Berhasil via tombol Tab dan angka 1–4 (*Diverifikasi via pengamatan manual user & log runtime*).
- **Komando Party FOLLOW (C) dan ATTACK (V):** Berhasil mengubah perilaku kawal barisan vs serang mandiri (*Diverifikasi via pengamatan manual user & log runtime*).
- **Serangan Dasar (Klik Kiri):** Panah Archer dan bola sihir Mage berhasil ditembakkan dan mengenai musuh (*Diverifikasi via pengamatan manual user*).
- **Skill Khusus (Tombol E):** *Charged Line Snipe* Archer dan *Meteor Strike* Mage berhasil diaktifkan dan memberikan dampak area (*Diverifikasi via pengamatan manual user*).
- **Siklus Kematian & Respawn:** Pengurangan HP saat terkena serangan musuh, transisi mati (fade-out), timer tunggu, dan kemunculan kembali karakter berhasil berjalan normal (*Diverifikasi via pengamatan manual user & log runtime*).

> **Catatan Sumber Verifikasi Parameter:**  
> Parameter numerik internal seperti kecepatan gerak (128 px/s normal, 220 px/s sprint), kecepatan dasar proyektil (panah 580 px/s untuk Archer dan musuh, magic bolt 500 px/s untuk Mage baik terkendali maupun tidak), rasio kesetaraan proyektil (1.0), durasi cooldown serangan dasar (1.4s untuk Archer Leader/follower/musuh archer, 1.5s untuk Mage Leader/follower) / skill, kekuatan dorongan knockback (`knockback_strength`), laju redaman (`knockback_decay = 1400.0`), jarak antrean (85 px), serta interval pemindaian aggro (0.15s) bersumber dari **inspeksi kode sumber dan log runtime**, bukan hasil pengukuran stopwatch manual pemain.

### B. Masalah yang Sengaja Ditunda (*Deferred Issues*):
- **Penyempurnaan AI Musuh & Flanking Navigasi:**
  Algoritma perhitungan waypoint raycast musuh dan follower saat membentur objek lingkungan masih memerlukan perbaikan perilaku navigasi.
  > **PERINGATAN:** Catatan penundaan ini **BUKAN** merupakan izin untuk langsung mengerjakannya tanpa permintaan atau instruksi eksplisit dari pengguna.

### C. Technical Debt & Rencana Masa Depan (*Backlog*):
*(Hanya dikerjakan jika secara spesifik diminta oleh pengguna)*
1. **Refactoring Base Character:** Penggabungan duplikasi logika (~80%) antara `player_archer.gd` dan `player_mage.gd` ke dalam kelas dasar bersama.
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
