---
name: flank-godot-workflow
description: >-
  Standard operating procedure for developing, debugging, modifying, and testing
  the Flank game in Godot Engine. Use this skill whenever writing GDScript, editing scenes,
  testing gameplay, or troubleshooting issues in the Flank repository.
---

# Flank Godot Workflow & Safety Protocol

Prosedur standar operasional (SOP) untuk memodifikasi, menguji, dan mengembangkan game **Flank** di Godot Engine secara aman, terarah, dan selaras dengan alur kerja tim.

> **Catatan Penggunaan Skill:**  
> Antigravity mengaktifkan skill ini berdasarkan relevansi tugas (pengembangan, debugging, pengeditan scene, atau pengujian game Flank), dan skill ini juga dapat dipanggil secara manual jika diperlukan. Penerapan skill ini tidak menggantikan pembacaan kode sumber, melainkan memandu disiplin kerja agar perubahan terisolasi dan tidak merusak sistem yang sudah stabil.

---

## 1. Pemisahan Tanggung Jawab & Referensi Proyek

- **Pengetahuan Domain & Status Game:** Rujuk selalu dokumen [PROJECT_CONTEXT.md](../../../PROJECT_CONTEXT.md) sebagai sumber kebenaran deklaratif mengenai konsep game, peta kontrol, modul utama, dan daftar backlog.
- **Bukan Pengganti Kode Nyata:** Jangan mengasumsikan isi dokumentasi selalu mutakhir jika repositori baru saja diperbarui oleh anggota tim lain. **Selalu verifikasi fisik file kode terbaru di repositori sebelum mulai bekerja.**
- **Cakupan Skill Ini:** Berfokus murni pada prosedur kerja teknis (*how-to procedure*), disiplin Git, dan protokol pengujian yang dapat digunakan berulang kali.

---

## 2. Prinsip Kerja Utama

1. **Aturan Read-Before-Write:** Dilarang mengasumsikan implementasi. Selalu baca dan pahami script serta scene terkait sebelum menulis atau mengusulkan perubahan.
2. **Kepatuhan Cakupan (No Scope Creep):** Kerjakan HANYA tugas yang secara eksplisit diminta oleh pengguna.
3. **Preservasi Desain yang Sudah Berfungsi:** Jangan mengubah mekanisme yang sudah stabil (seperti formasi *breadcrumb queue*, *cascade swap 180°*, penanganan kamera, atau pengecualian tabrakan antar-hero) kecuali ada instruksi spesifik untuk mengubahnya.
4. **Disiplin Backlog & Masalah Tertunda:** Dilarang mengerjakan item backlog atau masalah yang sengaja ditunda (seperti penyempurnaan AI musuh & navigasi flanking) tanpa permintaan eksplisit dari pengguna. Namun, aturan ini tidak boleh menghalangi perubahan jika pengguna memang secara nyata memintanya.
5. **Adaptabilitas Arsitektur (Tidak Mengunci Desain):** Jangan mengunci arsitektur Flank saat ini secara permanen. Jika pengguna secara eksplisit meminta refactoring atau perubahan desain, evaluasi dan sesuaikan implementasi berdasarkan kebutuhan tugas serta kode terbaru.

---

## 3. Fase 1: Verifikasi Pra-Kerja (Pre-Work Checks)

Sebelum mengedit atau membuat file apa pun:

1. **Periksa Status Git:**
   - Jalankan `git status` untuk mencatat kondisi awal repositori.
   - Jika terdapat modifikasi lokal pengguna yang belum di-commit, pertahankan perubahan tersebut dan jangan menimpa atau menghapusnya.
2. **Sinkronisasi Kode Nyata:**
   - Periksa file fisik di repositori untuk mengantisipasi adanya perubahan terbaru dari anggota tim lain (*git pull*).
3. **Konfirmasi Konfigurasi Engine:**
   - Pastikan solusi teknis selaras dengan konfigurasi di `project.godot` dan versi engine yang digunakan.

---

## 4. Fase 2: Standar Implementasi & Modifikasi Kode

Saat melakukan penulisan atau perubahan kode:

1. **Isolasi Perubahan:**
   - Batasi pengeditan hanya pada fungsi atau node yang relevan dengan tugas.
2. **Kesesuaian Tipe & Konvensi Proyek:**
   - Proyek Flank menggunakan GDScript dengan integrasi grup engine (`player`, `enemy`), duck-typing (`has_method`, properti boolean), serta collision layer (Layer 1 = dunia/rintangan). Pastikan penambahan logika baru mematuhi pola yang sudah ada.
3. **Pengelolaan Input:**
   - Perhatikan pemetaan input pada script karakter (`WASD`, klik kanan tahan, shift sprint, C, V, Tab, 1–4, E). Jika memodifikasi kontrol, pastikan tidak menimbulkan konflik dengan input handling yang sudah berjalan.

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
   - Jangan menyatakan suatu fitur/animasi berfungsi visual hanya karena tidak ada error di terminal.
3. **Pengujian Non-Invasif:**
   - Dilarang menjalankan simulasi input mouse/keyboard otomatis ke desktop OS pengguna. Kendali interaktif dilakukan secara manual oleh pengguna.

---

## 6. Fase 4: Verifikasi Pasca-Kerja (Post-Work Inspection) & Disiplin VCS

Setelah pekerjaan modifikasi atau pengujian selesai:

1. **Pemeriksaan Git Wajib:**
   - Jalankan `git status` dan `git diff` untuk memastikan **hanya file yang ditugaskan** yang mengalami perubahan.
2. **Pemisahan Cache Engine:**
   - Bedakan perubahan cache internal di direktori `.godot/` dari perubahan source code. Jangan menghapus atau mengembalikan perubahan apa pun secara otomatis tanpa memeriksa dampaknya.
3. **Disiplin Version Control:**
   - **Dilarang keras** menjalankan `git add`, `git commit`, `git push`, `git pull`, `git checkout`, `git reset`, atau operasi Git lainnya tanpa instruksi eksplisit dari pengguna.
4. **Pelaporan Terbuka & Transparan:**
   - Laporkan file yang diubah, ringkasan pengujian, dan catat secara jujur hal-hal yang belum dapat dipastikan atau memerlukan verifikasi lanjutan.

