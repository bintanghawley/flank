---
name: flank-godot-workflow
description: >-
  Standard operating procedure for developing, debugging, modifying, testing,
  and maintaining documentation in the Flank game repository in Godot Engine.
  Use this skill whenever writing GDScript, editing scenes, testing gameplay,
  updating Markdown documentation, or preparing changes for commit.
---

# Flank Godot Workflow & Safety Protocol

Prosedur standar operasional (SOP) pengembangan, debugging, pengujian gameplay, pemeliharaan dokumentasi, dan pengelolaan repositori game **Flank** di Godot Engine.

---

## 1. Peran Tim, Alur Branch, & Koordinasi

1. **Struktur Peran:**
   - **Raffi (Lead Developer):** Memegang kendali arsitektur proyek, prioritas backlog, evaluasi kode, persetujuan integrasi (*merge*) ke branch `main`, serta satu-satunya pihak yang berwenang mengarahkan pembaruan dokumentasi inti (`PROJECT_CONTEXT.md` dan `README.md`).
   - **Dhafin & Firman (Developer):** Bertanggung jawab atas implementasi teknis fitur, penyempurnaan mekanik, dan perbaikan bug pada branch masing-masing. Dilarang memodifikasi dokumentasi inti proyek di branch developer.
   - **Asisten AI:** Membantu implementasi teknis, verifikasi kode, dan dokumentasi atas arahan yang sah; dilarang mengambil keputusan organisasi atau persetujuan integrasi.
2. **Alur Branch Permanen:**
   - `main`: Branch integrasi acuan tim (bukan jaminan siap produksi).
   - `dev/raffi`, `dev/dhafin`, `dev/firman`: Branch pengembangan permanen masing-masing anggota.
   - Perubahan diajukan ke `main` melalui Pull Request (PR) yang ditinjau dan disetujui oleh Lead Developer.
   - Seluruh anggota tim wajib berkoordinasi saat memodifikasi file kritis bersama, terutama scene (`.tscn`) dan script inti (`game.gd`), guna mencegah konflik merge.

---

## 2. Prinsip Kerja Utama & Batas Keselamatan

1. **Read-Before-Write:** Selalu baca kode sumber, scene, dan konfigurasi engine (`project.godot`) aktual sebelum mengubah atau mengusulkan solusi. Rujuk [`PROJECT_CONTEXT.md`](../../../PROJECT_CONTEXT.md) sebagai sumber kebenaran arsitektur, kontrol, dan status game.
2. **Kepatuhan Cakupan (No Scope Creep):** Kerjakan HANYA tugas yang secara eksplisit diminta oleh pengguna. Prioritaskan solusi paling sederhana yang memenuhi kebutuhan.
3. **Preservasi Desain Stabil:** Pertahankan mekanik yang sudah berfungsi (seperti formasi *breadcrumb queue*, *cascade swap*, kontrol kamera, dan collision) kecuali ada instruksi modifikasi langsung.
4. **Disiplin Backlog:** Dilarang mengerjakan item backlog atau pekerjaan tertunda tanpa instruksi spesifik.
5. **Kontrol Penambahan File (Strict File Creation Control):**
   - Dilarang membuat file baru apa pun (script `.gd`, scene `.tscn`, aset, dokumentasi, rule, atau skill) tanpa persetujuan eksplisit pengguna.
   - Jika suatu tugas dinilai memerlukan file baru: hentikan langkah, jelaskan kebutuhan teknis dan path file yang diusulkan, lalu tunggu izin pengguna sebelum membuatnya.
6. **Disiplin Status Git:**
   - Selalu periksa status repositori (`git status`) sebelum memulai dan sesudah menyelesaikan pekerjaan untuk memastikan perubahan terisolasi dan tidak ada pekerjaan lokal yang tertimpa.

---

## 3. Standar Implementasi & Modifikasi GDScript

1. **Isolasi Perubahan:** Batasi modifikasi seminimal mungkin, hanya pada fungsi, blok kode, atau node yang relevan dengan tugas.
2. **Konvensi Engine & Arsitektur:**
   - Gunakan integrasi grup engine (`player`, `enemy`).
   - Gunakan duck-typing yang aman (`has_method`, properti boolean).
   - Patuhi collision layer proyek (Layer 1 = rintangan dunia/dinding).
3. **Penanganan Input:** Sesuaikan logika dengan pemetaan input karakter yang ada (`WASD`, klik kanan tahan, shift sprint, `C`, `V`, `Tab`, `1–4`, `E`). Jangan membuat konflik input baru.
4. **Keterbacaan Kode:** Tulis GDScript dengan penamaan variabel dan fungsi yang jelas (`snake_case`) serta hindari logika rumit jika solusi sederhana tersedia.

---

## 4. Protokol Pengujian & Runtime

1. **Pemisahan Sumber Kebenaran (Truth Separation):**
   - Bedakan secara tegas antara:
     - Hasil inspeksi statis kode sumber.
     - Output log/print dari runtime engine.
     - Hasil pengamatan manual pengguna di monitor.
   - Dilarang menyatakan suatu fitur atau visual berfungsi hanya karena tidak ada error di log terminal.
2. **Pengujian Non-Invasif:** Jalankan game secara langsung dari repositori; dilarang menjalankan simulasi input OS mouse/keyboard otomatis ke komputer pengguna.
3. **Pemisahan Cache Engine:** Bedakan cache internal `.godot/` dari perubahan source code. Jangan menghapus atau mengubah cache tanpa alasan teknis yang jelas.

---

## 5. Tata Kelola & Sinkronisasi Dokumentasi Proyek

1. **Kewenangan Eksklusif Pembaruan:**
   - Pembaruan [`PROJECT_CONTEXT.md`](../../../PROJECT_CONTEXT.md) dan [`README.md`](../../../README.md) berada di bawah kendali eksklusif Lead Developer (**Raffi**). Hanya Raffi yang berwenang menginstruksikan AI untuk memperbarui kedua dokumen tersebut.
2. **Larangan untuk Branch Developer:**
   - Dhafin dan Firman berfokus pada implementasi fitur dan perbaikan bug pada branch masing-masing.
   - AI yang mendampingi developer dilarang keras memodifikasi `PROJECT_CONTEXT.md` atau `README.md` di branch developer.
   - Jika implementasi fitur developer berimplikasi pada dokumentasi, AI hanya boleh mencatat rekomendasi tertulis kepada Raffi di laporan kerja. Setiap perubahan dokumentasi inti di branch developer dinilai sebagai pelanggaran saat code review (`NEEDS REVISION`).
3. **Alur Sinkronisasi Pasca-Integrasi ke `main`:**
   - **Langkah 1 (Persetujuan Integrasi):** Raffi menyetujui dan menggabungkan (*merge*) perubahan branch developer ke `main`.
   - **Langkah 2 (Instruksi Sinkronisasi):** Raffi menginstruksikan AI untuk melakukan sinkronisasi dokumentasi proyek di `main`.
   - **Langkah 3 (Pemeriksaan Implementasi Nyata):** AI memeriksa kode fisik dan scene aktual yang telah terintegrasi di `main` (bukan sekadar klaim commit atau catatan developer).
   - **Langkah 4 (Evaluasi Dampak):** Evaluasi dampak nyata terhadap arsitektur, mekanik gameplay, skema kontrol, dan cara menjalankan proyek.
   - **Langkah 5 (Pembaruan Selektif):** Perbarui `PROJECT_CONTEXT.md` dan `README.md` HANYA jika terjadi perubahan substansi faktual. Dilarang mengubah dokumen jika informasi yang ada masih akurat.
   - **Langkah 6 (Pelaporan Perubahan):** Laporkan ringkasan perubahan dokumentasi beserta alasan teknisnya secara transparan kepada Raffi.
4. **Prinsip Akurasi & Batas Dokumentasi:**
   - Implementasi fisik di branch `main` adalah satu-satunya sumber kebenaran (*single source of truth*).
   - Dilarang mendokumentasikan fitur yang masih direncanakan, belum selesai, atau belum terintegrasi ke `main`.
   - Pertahankan seluruh informasi lama yang masih akurat dan valid.
   - Dilarang membuat file dokumentasi baru tanpa persetujuan eksplisit pengguna.
5. **Tata Kelola Skill & Rule:**
   - AI dapat mengusulkan penyesuaian aturan atau skill jika alur kerja berubah secara permanen atas arahan Lead Developer. Dilarang menambah atau mengubah file rule/skill tanpa izin eksplisit.

---

## 6. Protokol Saran Pesan Commit & Disiplin VCS

1. **Kondisi Pemicu:** Prosedur ini dijalankan HANYA ketika pengguna secara eksplisit meminta saran nama commit atau menyatakan sedang menyiapkan commit. Dilarang memberikan saran commit secara proaktif jika belum diminta.
2. **Langkah Verifikasi Read-Only:**
   - Periksa perubahan secara terpisah: staged (`git diff --cached`), unstaged (`git diff`), dan untracked (`git status -u`).
   - Periksa isi file untracked yang relevan secara read-only agar seluruh konteks pekerjaan terpetakan.
   - Bedakan perubahan baru dari commit sebelumnya; jangan menggabungkan riwayat lama ke dalam deskripsi commit aktif.
   - Saat mendampingi Raffi dalam tugas sinkronisasi di `main`, pastikan dokumentasi terkait sudah mutakhir sebelum commit disiapkan. Saat mendampingi developer di branch pengembangan, pastikan branch developer tidak menyertakan modifikasi pada `PROJECT_CONTEXT.md` atau `README.md`.
3. **Format Rekomendasi:**
   - Berikan rekomendasi pesan commit dalam bahasa Indonesia menggunakan format *Conventional Commits* (misal: `feat:`, `fix:`, `docs:`, `refactor:`, `chore:`).
   - Format umum: `<tipe>: <deskripsi singkat>` (contoh: `feat: implementasi formasi party hero`, `fix: penanganan collision rintangan dunia`).
4. **Batas Mutlak Permintaan Commit:**
   - Permintaan saran nama commit **BUKAN izin untuk menjalankan** `git add`, `git commit`, `git push`, `git pull`, atau operasi mutatif lainnya.
   - Seluruh eksekusi Git yang mengubah status repositori mutlak memerlukan instruksi eksplisit pengguna.
