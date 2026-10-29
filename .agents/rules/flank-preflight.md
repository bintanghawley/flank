---
trigger: always_on
description: "Wajib membaca ulang SKILL.md sebelum memproses setiap prompt di workspace proyek Flank."
---

# Flank Workspace Preflight Rule

Aturan kerja wajib dan permanen untuk agen AI pada workspace repositori game **Flank**.

## 1. Kewajiban Membaca Ulang SKILL.md

Pada awal pemrosesan **setiap prompt baru dari pengguna di workspace Flank**, sebelum menjawab, menganalisis, atau mengambil tindakan apa pun:

1. **Wajib membaca ulang fisik file terbaru:**
   Baca file `.agents/skills/flank-godot-workflow/SKILL.md` langsung dari workspace menggunakan tool pembaca file (`read_file`).
2. **Dilarang hanya mengandalkan ingatan:**
   Jangan mengandalkan memori konteks, ringkasan percakapan, cache, pembacaan di giliran sebelumnya, atau asumsi bahwa skill sudah aktif secara otomatis.
3. **Patuhi seluruh prosedur yang relevan:**
   Setelah membaca, jadikan `SKILL.md` sebagai acuan operasional utama untuk tugas saat ini (prosedur verifikasi pra-kerja, disiplin modifikasi kode, protokol pengujian, pemeliharaan dokumentasi adaptif, dan protokol saran pesan commit).
4. **Verifikasi Teknis Tambahan:**
   Untuk tugas teknis, rujuk `PROJECT_CONTEXT.md` dan periksa kode sumber, scene, serta konfigurasi engine (`project.godot`) aktual yang relevan sebelum melakukan tindakan.

## 2. Format Konfirmasi Respons

- Berikan konfirmasi singkat di baris paling awal respons Anda:
  `Preflight: SKILL.md berhasil dibaca ulang.`
- Cantumkan konfirmasi tersebut **hanya jika** pembacaan file fisik pada giliran prompt saat ini benar-benar berhasil dilakukan.

## 3. Penanganan Jika File Tidak Dapat Diakses

Jika file `SKILL.md` tidak ditemukan, tidak dapat dibaca, atau akses workspace terganggu:
- **Dilarang** berpura-pura telah membaca file atau mengklaim telah menerapkan aturan yang belum diverifikasi.
- Sampaikan kendala akses file secara transparan kepada pengguna di awal respons.
- Hentikan seluruh tindakan berisiko yang berpotensi melanggar aturan proyek sampai kendala diselesaikan.

## 4. Kepatuhan Batasan Proyek

- **Kontrol File Baru:** Dilarang keras membuat file baru apa pun (kode, scene, aset, konfigurasi, dokumentasi, atau file workflow AI) tanpa permintaan atau persetujuan eksplisit dari pengguna.
- **Preservasi Perubahan Lokal:** Pertahankan seluruh perubahan lokal yang ada dan jangan menimpa pekerjaan pengguna atau anggota tim lain.
- **Disiplin Git:** Dilarang keras menjalankan operasi Git yang mengubah keadaan atau riwayat repositori tanpa instruksi eksplisit dari pengguna, seperti `git add`, `git commit`, `git push`, `git pull`, `git reset`, dan `git clean`. Sebaliknya, perintah inspeksi baca-saja (*read-only*), seperti `git status`, `git diff`, `git diff --cached`, dan `git log`, tetap diizinkan untuk dijalankan sesuai kebutuhan verifikasi dan ketentuan `SKILL.md`.
- **Batasan Rule Ini:** Rule ini berfungsi sebagai pengingat wajib (*standing directive*) untuk memicu pembacaan file sumber terbaru. Prosedur detail tetap bersumber langsung dari `SKILL.md`.

