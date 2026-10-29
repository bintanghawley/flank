---
name: flank-godot-workflow
description: >-
  Standard operating procedure for developing, debugging, modifying, testing,
  and maintaining documentation in the Flank game repository in Godot Engine.
  Use this skill whenever writing GDScript, editing scenes, testing gameplay,
  updating Markdown documentation, or preparing changes for commit.
---

# Flank Godot Workflow & Safety Protocol

Prosedur standar operasional (SOP) untuk pengembangan, debugging, pengujian gameplay, pemeliharaan dokumentasi, dan pengelolaan repositori game **Flank** di Godot Engine secara aman, terarah, dan selaras dengan alur kerja tim.

> **Catatan Penggunaan Skill:**  
> Antigravity mengaktifkan skill ini berdasarkan relevansi tugas (pengembangan, debugging, pengeditan scene, pengujian gameplay, pemeliharaan dokumentasi, atau persiapan commit game Flank), dan skill ini juga dapat dipanggil secara manual jika diperlukan. Penerapan skill ini tidak menggantikan pembacaan kode sumber, melainkan memandu disiplin kerja agar perubahan terisolasi, dokumentasi tetap mutakhir, dan kontrol repositori tetap berada di tangan pengguna.

---

## 1. Pemisahan Tanggung Jawab & Hirarki Keputusan

1. **Peran Pengguna sebagai Pengambil Keputusan Utama:**
   - Pengguna memegang kendali penuh atas arah pengembangan game, prioritas backlog, arsitektur proyek, dan seluruh mutasi pada repositori Git.
   - Asisten AI bertugas membantu implementasi teknis, memverifikasi kode, menjaga konsistensi sistem, dan memelihara dokumentasi, namun **dilarang mengambil keputusan yang memerlukan persetujuan pengguna**.
2. **Pengetahuan Domain & Status Game:**
   - Rujuk dokumen [PROJECT_CONTEXT.md](../../../PROJECT_CONTEXT.md) sebagai sumber kebenaran deklaratif mengenai konsep game, kontrol, arsitektur teknis, dan daftar backlog.
3. **Bukan Pengganti Kode Nyata:**
   - Jangan mengasumsikan dokumentasi atau percakapan sebelumnya selalu mencerminkan kondisi terkini. **Selalu verifikasi file fisik repositori terbaru sebelum mulai bekerja**, terutama setelah adanya pembaruan (*git pull*) dari anggota tim lain.
4. **Cakupan Skill Ini:**
   - Berfokus murni pada prosedur kerja teknis (*how-to procedure*), disiplin Git, pengendalian pembuatan file, pemeliharaan dokumentasi adaptif, dan protokol pengujian yang dapat digunakan berulang kali.

---

## 2. Prinsip Kerja Utama & Kontrol Penambahan File

1. **Aturan Read-Before-Write:** Selalu baca dan pahami script serta scene terkait sebelum menulis atau mengusulkan perubahan. Dilarang berasumsi.
2. **Kepatuhan Cakupan (No Scope Creep):** Kerjakan HANYA tugas yang secara eksplisit diminta oleh pengguna. Prioritaskan solusi paling sederhana yang memenuhi kebutuhan.
3. **Preservasi Desain yang Sudah Berfungsi:** Jangan mengubah mekanisme yang sudah stabil (seperti formasi *breadcrumb queue*, *cascade swap 180°*, penanganan kamera, atau pengecualian tabrakan antar-hero) kecuali ada instruksi spesifik.
4. **Disiplin Backlog & Masalah Tertunda:** Dilarang mengerjakan item backlog atau masalah yang sengaja ditunda (seperti penyempurnaan AI musuh & navigasi flanking) tanpa instruksi eksplisit. Keberadaan backlog bukan izin untuk langsung mengerjakannya.
5. **Adaptabilitas Arsitektur (Tidak Mengunci Desain):** Jika pengguna secara eksplisit meminta refactoring atau perubahan desain, evaluasi dan sesuaikan implementasi berdasarkan kebutuhan tugas serta kode terbaru.
6. **Persetujuan Wajib untuk File Baru (Strict File Creation Control):**
   - Pengguna mengontrol penuh penambahan file dalam repositori. **Dilarang membuat file baru apa pun yang belum secara eksplisit diminta atau disetujui oleh pengguna.**
   - Aturan ini mencakup:
     - Dokumentasi baru (misalnya `CHANGELOG.md`, `CONTRIBUTING.md`, atau dokumen baru lainnya).
     - Script GDScript (`.gd`) baru.
     - Scene Godot (`.tscn`) baru.
     - File konfigurasi, aset visual/audio, atau file pendukung lainnya.
     - File pembantu untuk workflow AI atau pengujian.
   - **Protokol jika suatu tugas dinilai memerlukan file baru:**
     1. Hentikan langkah yang memerlukan pembuatan file tersebut.
     2. Jelaskan kebutuhan teknis dan masalah konkret yang akan diselesaikannya.
     3. Usulkan nama serta path lokasi file secara spesifik.
     4. Jelaskan mengapa file yang sudah ada tidak memadai untuk menampung fungsi tersebut.
     5. Tunggu persetujuan eksplisit pengguna sebelum membuat file.
   - Jika pengguna secara eksplisit telah menyetujui/meminta file tertentu, asisten dapat melanjutkan pembuatan file tersebut sesuai cakupan permintaan tanpa meminta izin berulang kali.
   - Sambil menunggu keputusan pengguna, lanjutkan bagian pekerjaan lain yang memungkinkan tanpa membuat file baru.
   - Dilarang membuat file hanya untuk memperlihatkan bahwa suatu alur kerja telah diterapkan.

---

## 3. Fase 1: Verifikasi Pra-Kerja (Pre-Work Checks)

Sebelum mengedit file apa pun:

1. **Periksa Status Git:**
   - Jalankan `git status` untuk mencatat branch aktif, commit HEAD, dan kondisi kerja awal repositori.
   - Jika terdapat modifikasi lokal pengguna atau anggota tim lain yang belum di-commit, **pertahankan seluruh perubahan tersebut** dan jangan menimpa atau menghapusnya.
2. **Sinkronisasi Kode Fisik:**
   - Periksa file fisik dan konfigurasi aktual di repositori terkait tugas untuk mengantisipasi pembaruan terkini.
3. **Konfirmasi Konfigurasi Engine:**
   - Pastikan solusi teknis selaras dengan konfigurasi di `project.godot` dan versi engine yang digunakan saat pengujian.

---

## 4. Fase 2: Standar Implementasi & Modifikasi Kode

Saat melakukan penulisan atau perubahan kode:

1. **Isolasi Perubahan:**
   - Batasi pengeditan hanya pada fungsi, blok kode, atau node yang relevan dengan tugas.
2. **Kesesuaian Tipe & Konvensi Proyek:**
   - Gunakan pola GDScript yang konsisten dengan proyek: integrasi grup engine (`player`, `enemy`), duck-typing yang aman (`has_method`, properti boolean), serta collision layer (Layer 1 = rintangan dunia/dinding).
3. **Pengelolaan Input:**
   - Perhatikan pemetaan input pada script karakter (`WASD`, klik kanan tahan, shift sprint, C, V, Tab, 1–4, E). Jangan membuat konflik dengan penanganan input yang sudah berjalan.

---

## 5. Fase 3: Protokol Pengujian & Runtime

Ketika menjalankan pengujian atau memverifikasi fitur:

1. **Penggunaan Repositori Utama Secara Aman:**
   - Jalankan game langsung dari repositori utama tanpa memodifikasi aset atau scene secara destruktif.
2. **Pembedaan Sumber Kebenaran (Truth Separation):**
   - Bedakan secara tegas antara:
     - Hasil inspeksi statis kode sumber.
     - Bukti log / output print dari runtime engine.
     - Hasil pengamatan manual pengguna di monitor.
   - Jangan menyatakan suatu fitur/animasi visual berfungsi hanya karena tidak muncul error di log terminal.
3. **Pengujian Non-Invasif:**
   - Dilarang menjalankan simulasi input mouse/keyboard otomatis ke sistem operasi pengguna. Kendali interaktif dilakukan secara manual oleh pengguna.

---

## 6. Fase 4: Pemeliharaan Dokumentasi Secara Adaptif

Setelah menyelesaikan suatu pekerjaan (modifikasi kode, scene, konfigurasi, fitur, atau workflow), evaluasi apakah perubahan tersebut menyebabkan dokumentasi Markdown yang sudah ada menjadi tidak akurat atau tidak lengkap.

1. **Ruang Lingkup dan Kriteria Pembaruan Dokumen:**
   - **`README.md`:** Perbarui jika perubahan memengaruhi informasi bagi pengunjung atau kontributor publik (fitur yang tersedia, kontrol permainan, persyaratan sistem, petunjuk menjalankan game, struktur direktori, atau status pengembangan).
   - **`PROJECT_CONTEXT.md`:** Perbarui jika perubahan memengaruhi pengetahuan teknis internal proyek (arsitektur sistem, mekanik gameplay, relasi antarmodul, kontrol, status fitur terverifikasi, hasil pengujian, atau daftar pekerjaan yang ditunda).
   - **`SKILL.md` (Dokumen ini):** Perbarui **HANYA** jika prosedur kerja, aturan keselamatan, alur pengujian, atau konvensi kerja AI memang perlu diubah. **Dilarang mengubah SKILL.md hanya karena ada fitur gameplay baru atau perubahan kode biasa.**
   - **Dokumentasi Markdown Lain yang Sudah Ada:** Periksa relevansinya dan perbarui hanya jika benar-benar terdampak oleh pekerjaan.
2. **Otorisasi Pembaruan Dokumentasi yang Ada:**
   - Asisten AI **diizinkan mengedit file Markdown yang sudah ada tanpa meminta persetujuan tambahan** apabila pembaruan tersebut murni diperlukan untuk menjaga akurasi dokumentasi terhadap kode aktual.
   - Dokumentasi harus selalu mengikuti kondisi aktual proyek (kode sumber), bukan memaksakan kode mengikuti dokumentasi yang sudah usang.
   - Dilarang memperbarui seluruh dokumentasi secara otomatis tanpa alasan. Jika tidak ada informasi yang terpengaruh, nyatakan secara transparan bahwa dokumentasi yang ada masih sesuai.
3. **Prosedur Sebelum dan Sesudah Mengedit Dokumentasi:**
   - **Sebelum mengedit:** Catat status Git awal, periksa isi fisik file yang akan diedit, pertahankan perubahan lokal pengguna, dan batasi perubahan hanya pada bagian yang relevan.
   - **Setelah mengedit:**
     - Pastikan fakta dalam dokumentasi sesuai dengan implementasi terbaru.
     - Pastikan format Markdown valid (heading, daftar, tabel, code block seimbang).
     - Jalankan `git diff` dan `git status` untuk memverifikasi bahwa tidak ada perubahan pengguna yang tertimpa dan tidak ada file di luar tugas yang berubah.
     - Laporkan file dokumentasi yang diubah beserta alasannya secara terbuka.
     - Jika menemukan perubahan lokal yang tidak berasal dari tugas saat ini atau tidak jelas asal-usulnya, jangan mengklaimnya; identifikasi dan laporkan secara terpisah.

---

## 7. Fase 5: Protokol Permintaan Pesan Commit & Disiplin VCS

Pengguna memiliki alur kerja rutin: setelah menyelesaikan suatu pekerjaan, pengguna akan meminta saran pesan commit dalam bahasa Indonesia berdasarkan perubahan sejak commit atau push sebelumnya yang relevan.

1. **Langkah-Langkah Saat Pengguna Meminta Nama Commit:**
   Ketika pengguna secara eksplisit meminta nama commit atau menyatakan sedang menyiapkan perubahan untuk dikirim ke repositori:
   - **Langkah 1 (Audit Status Perubahan Secara Terpisah):** Periksa status Git secara rinci dengan memisahkan tiga kategori perubahan: perubahan staged (`git diff --cached`), perubahan unstaged (`git diff`), dan file tak terlacak / untracked (`git status -u`).
   - **Langkah 2 (Pemeriksaan Isi File Untracked):** Dilarang hanya mengandalkan `git diff` karena perintah tersebut tidak menampilkan isi file untracked. Baca dan periksa isi file baru yang relevan secara *read-only* agar seluruh cakupan pekerjaan dapat dipahami secara utuh.
   - **Langkah 3 (Pemisahan Batas Commit):** Bedakan secara tegas antara perubahan yang sudah di-commit pada riwayat Git sebelumnya dengan perubahan yang masih menunggu commit. Jangan memasukkan pekerjaan dari commit terdahulu ke dalam pesan commit baru seolah-olah perubahan tersebut belum pernah di-commit.
   - **Langkah 4 (Identifikasi Cakupan & Pengelompokan Perubahan):** Jika terdapat beberapa kelompok perubahan yang berbeda (misalnya modifikasi kode gameplay, pembaruan dokumentasi, atau perubahan konfigurasi), identifikasi cakupan masing-masing sebelum menyarankan pesan commit. Jangan menggabungkan perubahan yang tidak berkaitan tanpa menjelaskan alasannya secara transparan.
   - **Langkah 5 (Sinkronisasi Dokumentasi Adaptif):** Evaluasi apakah dokumentasi yang ada (`README.md`, `PROJECT_CONTEXT.md`, dsb.) terpengaruh oleh perubahan tersebut. Jika ada dokumen yang menjadi tidak akurat, perbarui file Markdown terkait tanpa meminta persetujuan tambahan.
   - **Langkah 6 (Verifikasi Bebas File Baru Tak Berizin):** Pastikan tidak ada file baru yang dibuat di luar persetujuan pengguna. Pertahankan seluruh perubahan lokal yang sudah ada.
   - **Langkah 7 (Verifikasi Akhir Sebelum Saran):** Periksa kembali seluruh perubahan menggunakan `git diff` dan `git status` untuk memastikan keakuratan data.
   - **Langkah 8 (Pemberian Saran Pesan Commit):** Berikan rekomendasi pesan commit dalam bahasa Indonesia menggunakan format *Conventional Commits* (misalnya `feat:`, `fix:`, `docs:`, `chore:`, `refactor:`) yang selaras dengan riwayat repositori.
   - **Langkah 9 (Pelaporan Transparan):** Jelaskan file yang berubah, kelompok perubahannya, dan status pembaruan dokumentasi. Jika riwayat perubahan sejak commit/push terakhir tidak dapat dipastikan dengan yakin, jangan mengarang; laporkan keterbatasannya dan gunakan data yang dapat diverifikasi secara fisik.
2. **Batasan Ketat Permintaan Nama Commit:**
   - Permintaan nama commit **HANYA** mengizinkan pemeriksaan perubahan, pemeliharaan dokumentasi yang relevan agar mutakhir, dan pemberian rekomendasi pesan commit.
   - Permintaan nama commit **BUKAN izin untuk:**
     - Menjalankan `git add`.
     - Menjalankan `git commit`.
     - Menjalankan `git push`.
     - Menjalankan `git pull`.
     - Melakukan operasi Git destruktif (`checkout`, `reset`, `clean`, dsb.).
     - Membuat file baru yang belum disetujui.
   - Seluruh operasi Git yang mengubah status repositori tetap memerlukan instruksi eksplisit pengguna.
   - **Dilarang menawarkan atau memberikan saran pesan commit secara proaktif** apabila pengguna belum memintanya.
3. **Pemisahan Cache Engine:**
   - Bedakan perubahan cache internal di direktori `.godot/` dari perubahan source code riil. Jangan menghapus atau mengembalikan perubahan apa pun secara otomatis tanpa memeriksa dampaknya.
