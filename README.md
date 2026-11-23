# FLANK

*Game action RPG taktis 2D top-down berbasis Godot Engine 4 dengan sistem party empat hero real-time, kampanye cerita Chapter 1, dan mode jelajah.*

---

## Ringkasan

**FLANK** adalah game action RPG taktis 2D dengan perspektif *top-down* dan gaya visual *pixel art*, dikembangkan oleh tim **Penjelajah Antariksa** menggunakan **Godot Engine 4**.

Berlatar sebuah kerajaan abad pertengahan yang dibayangi ramalan **Seven Deadly Day**, pemain mengikuti perjalanan Pangeran **Forzato Arthur** bersama tiga rekannya untuk menyelidiki anomali mana, menumpas kawanan monster, membuka kekuatan pusaka, dan membentuk regu empat pahlawan yang solid.

Dalam permainan, pemain mengendalikan satu **Leader** secara langsung menggunakan sistem kendali mouse *click-to-move* dan serangan terarah kursor, sementara anggota regu lainnya membantu secara otonom di dalam arena pertempuran. Pemain dapat berpindah kendali antar-hero, memadukan peran *tank*, *melee burst*, *sniper*, dan *caster*, serta memanfaatkan skill khusus masing-masing untuk menaklukkan arena dan pertarungan boss.

---

## Mode Permainan

FLANK menyediakan dua mode permainan yang dapat dipilih dari Start Menu:

- **Mode Cerita (Chapter 1):** Kampanye naratif yang terdiri dari 10 rangkaian adegan cerita terhubung—mulai dari prolog di Hutan Observasi, rapat darurat di Aula Istana, penyelidikan Perpustakaan Istana, pertahanan Gerbang Kota, uji kekompakan tim, duel satu lawan satu melawan Pelatih Alaric, penggalian makam Ksatria Lancelot, hingga klimaks menghadapi Skeleton Boss. Anggota party bergabung secara bertahap mengikuti alur cerita.
- **Mode Jelajah:** Mode eksplorasi bebas di seluruh area peta dengan keempat hero langsung tersedia sejak awal. Pemain dapat menjelajahi kota kerajaan, aula istana, perpustakaan, serta menantang ulang arena monster dan pertarungan boss lengkap dengan pencatatan rekor waktu tercepat.

---

## Hero Party

Pemain dapat memimpin regu berisi empat karakter dengan peran dan kemampuan tempur berbeda:

| Hero | Kelas / Peran | HP | Serangan Dasar | Skill Khusus (`E`) |
| :--- | :--- | :---: | :--- | :--- |
| **Forzato Arthur** | Knight (Tank / Support) | 1200 | Tebasan pedang jarak dekat dengan hentakan maju (*attack lunge*) | **Shield Guard** — Mengaktifkan perisai pelindung seluruh anggota party yang menahan 100% damage selama 3,5 detik (CD 12 dtk). |
| **Carina Hellene** | Bandit (Melee Burst) | 680 | *Double Slash Dagger* — Dua tebasan belati cepat berturut-turut | **Auto-Dash & Flurry Slash** — Meluncur cepat ke target dengan *Super Armor*, menahan musuh di tempat, lalu mengeksekusi kombo 5 tebasan beruntun (CD 8 dtk). |
| **Astuta Anastasya** | Archer (Ranged Sniper) | 450 | Tembakan anak panah lurus terarah kursor | **Charged Line Snipe** — Mode bidik garis lurus (hingga 3 tembakan dalam 10 detik) yang menghasilkan damage area linear menembus banyak musuh, tertahan dinding solid (CD 9 dtk). |
| **Pensatore Magnus** | Mage (Ranged AoE Caster) | 600 | Tembakan bola sihir (*magic bolt*) dari ujung tongkat | **Meteor Strike** — Memanggil meteor jatuh ke area bidikan dalam radius 480 px yang meledak dengan damage area dan *knockback* (CD 10 dtk; terbuka melalui Perpustakaan Istana di Mode Cerita). |

---

## Fitur Utama

- **Pertarungan Party Real-Time & Arena Terkunci:** Saat memasuki zona arena, seluruh anggota party diterjunkan dalam formasi tempur, kamera melebar untuk sudut pandang taktis, dan rekan AI bertempur mandiri sesuai jarak serang masing-masing.
- **Pertarungan Boss Berpola Serangan Tertelegraf:**
  - **Pelatih Alaric** — Duel 1v1 di Arena Kamp dengan fase *enrage* dan tiga pola serangan (*Basic Cleave*, *Triple Advance*, *Ground Rupture*).
  - **Skeleton Boss** — Pertarungan klimaks 4 hero di Arena Pemakaman dengan fase *enrage* dan empat pola AoE api (*Ring of Fire*, *Flame Pillar*, *Infernal Burst*, *Fireball Rain*).
  - Kedua tantangan boss mencatat waktu penyelesaian dan menyimpan rekor tercepat lokal.
- **Sistem Kekalahan & Time Rewind:** Jika seluruh anggota party gugur dalam pertempuran arena, pemain dapat memutar mundur waktu ke *snapshot* sesaat sebelum arena dimulai untuk mencoba strategi baru.
- **Sistem Dialog, Misi & Navigasi:** Kotak dialog bergaya *typewriter* dengan potret karakter, banner lokasi, pelacak misi aktif, prompt interaksi kontekstual (`[E]`), serta kompas penunjuk arah tujuan misi.
- **Menu Buku In-Game 5 Tab (`ESC`):**
  - **Inventori (`B`):** Manajemen item dalam 4 kategori (*Consumable*, *Key*, *Collectible*, *Notes*), termasuk item pemulih HP (*Apel Merah Hutan*), item pembangkit hero KO (*Roti Gandum*), dan catatan cerita yang dapat dibaca.
  - **Jurnal (`J`):** Daftar Misi Utama dan Misi Dunia beserta detail tujuan dan tombol navigasi kompas.
  - **Informasi (`C`):** Tampilan animasi karakter, biodata, statistik HP/ATK, ringkasan skill, dan pengaturan ulang urutan slot party secara *drag-and-drop*.
  - **Pengaturan:** Pengaturan volume 4 kanal (*Master*, *Music*, *SFX*, *Dialog*), kustomisasi tombol (*keybind remapping*), serta sistem **Simpan & Muat** multi-halaman lengkap dengan *thumbnail* tangkapan layar.
  - **Kredit:** Daftar lengkap tim pengembang dan teknologi yang digunakan.
- **Tata Suara BGM & SFX Terintegrasi:** Dilengkapi 10 musik latar (`.ogg`) dengan transisi *seamless equal-power crossfade* antar-suasana (menu, eksplorasi, cutscene, perpustakaan, pertarungan, boss, dan layar kekalahan) serta efek suara untuk aksi tempur, langkah kaki, dan interaksi antarmuka.
- **Start Menu Interaktif & Kursor Kustom:** Layar pembuka dengan latar *parallax* langit dan rumput, animasi berjalan keempat hero, transisi *circular mask* (iris wipe/open), serta kursor *pixel art* kustom dengan umpan balik klik dan indikator titik gerak di tanah.

---

## Gameplay

1. **Eksplorasi Dunia:** Pemain bergerak menjelajahi wilayah Hutan Observasi, Kota Kerajaan, Gerbang Kota, Aula Rapat Istana, Perpustakaan Istana (2 lantai), dan Area Pemakaman menggunakan klik kanan mouse. Saat tidak bertempur, hanya Leader aktif yang tampil di peta untuk menjaga kejelasan navigasi, dan pergantian karakter tetap berlangsung mulus di posisi yang sama.
2. **Interaksi & Alur Cerita:** Dekati pintu, tangga, NPC, makam, atau titik pemicu tantangan hingga muncul indikator `[E]`, lalu tekan `E` untuk berinteraksi. Pada Mode Cerita, kompas navigasi dan Jurnal Misi memandu pemain menelusuri seluruh adegan Chapter 1.
3. **Pertarungan Arena:** Memasuki arena monster atau memulai duel boss memunculkan HUD tempur (kartu HP party di kiri bawah dan bar skill di kanan bawah). Pemain menyerang ke arah kursor dengan klik kiri, melancarkan skill dengan `E`, berpindah Leader dengan `1`–`4` (atau klik kartu HUD), serta menggunakan item dari Inventori jika membutuhkan pemulihan atau membangkitkan rekan yang KO.

---

## Kontrol Permainan

Sebagian besar pintasan keyboard dapat disesuaikan kembali melalui **Menu Buku → Pengaturan → Kontrol** (tersimpan otomatis pada `user://settings.cfg`).

### Eksplorasi & Pertarungan

| Input | Aksi |
| :--- | :--- |
| `Klik Kanan` / `Tahan Klik Kanan` | Menggerakkan Leader aktif menuju posisi kursor mouse (*click-to-move* / *hold-to-move*) |
| `Klik Kiri` / `Tahan Klik Kiri` | Serangan dasar ke arah kursor mouse (aktif saat berada dalam pertempuran) |
| `E` *(dapat diubah)* | Mengaktifkan skill khusus Leader aktif saat bertempur |
| `Klik Kiri` *(saat mode bidik skill)* | **Anastasya:** Tahan untuk memanjangkan jarak bidikan lalu lepas untuk menembak<br>**Magnus:** Klik lokasi target untuk menjatuhkan meteor |
| `Klik Kanan` / `E` *(saat mode bidik skill)* | Membatalkan bidikan atau keluar dari mode skill (**Anastasya** / **Magnus**) |
| `1`, `2`, `3`, `4` *(dapat diubah)* | Berganti kendali Leader langsung ke anggota party pada slot terkait |
| `Klik Kiri` *(Kartu Party HUD)* | Berganti kendali Leader langsung ke hero yang diklik |
| `Klik Kiri` *(Slot Skill HUD)* | Mengaktifkan skill khusus milik Leader aktif |
| `E` *(dapat diubah)* | Berinteraksi dengan pintu, tangga, objek, NPC, atau tantangan boss saat prompt muncul |
| `Klik Kiri` / `Spasi` / `Enter` / `E` / `F` | Melanjutkan atau menyelesaikan efek ketik dialog |

### Menu Buku & Antarmuka

| Input | Aksi |
| :--- | :--- |
| `ESC` / Klik Ikon Jeda | Membuka atau menutup Menu Buku Jeda (*Pause Menu*) serta menutup modal konfirmasi |
| `B` *(dapat diubah)* | Membuka atau menutup tab **Inventori** |
| `J` *(dapat diubah)* | Membuka atau menutup tab **Jurnal Misi** |
| `C` *(dapat diubah)* | Membuka atau menutup tab **Informasi Karakter & Party** |
| `Q` / `E` *(di dalam Menu Buku)* | Berpindah ke tab Menu Buku sebelumnya / berikutnya |
| `W`, `A`, `S`, `D` / `Panah` *(di dalam Menu Buku)* | Navigasi daftar misi, kategori inventori, submenu pengaturan, atau halaman slot simpan |
| `F` / `Enter` / `Spasi` *(di dalam Menu Buku)* | Konfirmasi pilihan (gunakan item, navigasi misi, simpan/muat) |

---

## Persyaratan

- **Engine:** Godot Engine 4 (konfigurasi [project.godot](project.godot) menggunakan feature tag `"4.7"` dan renderer `Forward Plus`, dengan format scene Godot 4 `format=3` dan `format=4`).
- **Sistem Operasi:** Dikonfigurasi dengan driver rendering Windows Direct3D 12 (`rendering_device/driver.windows="d3d12"`).
- **Addon / Dependency Eksternal:** Tidak memerlukan plugin, addon, atau pustaka eksternal tambahan.

---

## Download & Play

Build Windows FLANK tersedia untuk diunduh dan dimainkan langsung tanpa perlu membuka project di Godot Editor.

**[Download FLANK for Windows](https://drive.google.com/drive/folders/1zJ1DxqqwpGK0N28joNuseXCjSGJxb2h3)**

| Info | Detail |
| :--- | :--- |
| **Rilis** | `FLANK_Chapter1_v1.0_Win64.zip` |
| **Platform** | Windows 64-bit |

### Cara Memulai

1. Buka folder Google Drive melalui tautan di atas.
2. Unduh `FLANK_Chapter1_v1.0_Win64.zip`.
3. Ekstrak file ZIP ke folder pilihan.
4. Buka folder hasil ekstraksi — pastikan seluruh file tetap berada dalam satu folder yang sama.
5. Jalankan `FLANK_v1.0.exe` untuk memulai permainan.

> [!NOTE]
> Seluruh file dalam folder hasil ekstraksi (termasuk file `.pck` jika ada) harus tetap berada di lokasi yang sama dengan `FLANK_v1.0.exe` agar game dapat berjalan dengan benar.

---

## Cara Menjalankan Proyek

1. **Clone repositori:**
   ```bash
   git clone https://github.com/bintanghawley/flank.git
   cd flank
   ```
2. **Buka Godot Project Manager** (Godot Engine 4 yang kompatibel dengan konfigurasi proyek `4.7` / `Forward Plus`).
3. Klik **Import**, pilih berkas `project.godot` di dalam folder hasil clone, lalu klik **Import & Edit**.
4. Tunggu editor Godot menyelesaikan proses pemindaian dan impor aset awal.
5. Tekan **F5** atau klik tombol **Run Project** di kanan atas editor untuk menjalankan game dari scene utama (`res://scene/ui/menus/start_menu.tscn`).

---

## Struktur Proyek

```text
flank/
├── assets/                     # Seluruh aset grafis, audio, dan tipografi
│   ├── audio/
│   │   ├── bgm/                # 10 trek musik latar (.ogg)
│   │   └── sfx/                # Efek suara (.wav) untuk karakter, musuh, party, dan UI
│   ├── characters/             # Sprite 4-arah hero party, NPC istana, cacing, dan gagak
│   ├── enemies/                # Sprite boss monster (Skeleton)
│   ├── environment/            # Tekstur peta dunia luar, kota kerajaan, interior, dan arena
│   ├── particles/              # Tekstur partikel debu lari dan death ghost
│   ├── projectile/             # Tekstur proyektil panah dan bola sihir
│   ├── skills/                 # Tekstur efek visual & reticle skill 4 hero
│   └── ui/                     # Font Beholden, grafis HUD, dialog, ikon, kursor, dan menu buku
├── scene/                      # Scene Godot (.tscn), resource (.tres), dan script (.gd)
│   ├── effect/                 # Efek visual mandiri (run_dust, death_ghost)
│   ├── enemy/                  # Prefab musuh & AI musuh/boss terpadu (enemy.gd)
│   ├── npc/                    # NPC pengawal patroli kerajaan (npc_guard)
│   ├── player/                 # Scene dan controller 4 hero party
│   ├── projectile/             # Proyektil fisik, efek benturan, hitbox AoE, dan reticle dunia
│   ├── ui/
│   │   ├── cursor/             # Autoload CursorManager (kursor kustom & indikator gerak)
│   │   ├── gameplay/           # Gameplay HUD, dialog, dan Menu Buku 5 tab (gameplay_hud)
│   │   └── menus/              # Start Menu, pemilih mode, dan transisi iris (start_menu)
│   ├── world/                  # Peta dunia luar, kerajaan, aula rapat, dan perpustakaan 2 lantai
│   ├── game.gd                 # Controller utama gameplay, cerita Chapter 1, arena, boss, dan save/load
│   └── game.tscn               # Scene utama gameplay yang memuat dunia, party, musuh, dan HUD
├── PROJECT_CONTEXT.md          # Catatan konteks teknis dan riwayat pengembangan
├── README.md                   # Dokumentasi utama repositori
└── project.godot               # Konfigurasi utama Godot Engine
```

---

## Tim Pengembang & Kredit

Dikembangkan oleh **Penjelajah Antariksa** *(terverifikasi dari halaman Kredit in-game)*:

| Bidang | Anggota Tim |
| :--- | :--- |
| **Lead & Game Direction** | **Ghofar Jalesa** |
| **Programming & Combat** | **Raffi Setiawan** *(Lead)*, Firman Nugraha, Evan Mahardika |
| **Visual Art, UI & Animation** | **Evan Mahardika** *(Lead)*, Daffa Ronalvinato, Ghofar Jalesa, Raffi Setiawan, Firman Nugraha |
| **Level & Technical Design** | **Ghofar Jalesa** *(Lead)*, Daffa Ronalvinato, Dhafin Kautsar, Raffi Setiawan, Evan Mahardika |
| **Writing & Worldbuilding** | **Daffa Ronalvinato** *(Lead)*, Ghofar Jalesa, Evan Mahardika |
| **Audio & Sound Design** | **Raffi Setiawan** *(Lead)*, Firman Nugraha |
| **Quality Assurance** | **Raffi Setiawan** *(Lead)*, Hikmawal Dzachwan |

**Teknologi & Tipografi:**
- Game Engine: Godot Engine 4
- Font: Beholden oleh Tiny Speck

---

## Lisensi

Repositori ini belum menyertakan berkas lisensi resmi.
