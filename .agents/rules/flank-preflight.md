---
trigger: always_on
description: "Pengarah kerja global dan batas keselamatan repositori untuk workspace proyek Flank."
---

# Flank Workspace Preflight Rule

Aturan kerja dasar untuk seluruh interaksi AI Agent pada repositori game **Flank**.

## 1. Lingkup Workspace & Penggunaan Skill
- **Lingkup Workspace:** Seluruh instruksi ini berlaku aktif untuk workspace repositori Flank.
- **Pengembangan Umum:** Gunakan skill [`flank-godot-workflow`](../skills/flank-godot-workflow/SKILL.md) untuk pekerjaan implementasi GDScript, modifikasi scene, pengujian gameplay, pemeliharaan dokumentasi, atau penyiapan pesan commit.
- **Lead Review (Khusus Lead Developer):** Gunakan skill pribadi [`lead-review`](../skills/lead-review/SKILL.md) hanya ketika mendampingi Lead Developer (Raffi) dalam audit branch developer (`dev/dhafin`, `dev/firman`), review PR, atau penilaian merge ke `main`. Kontributor lain dilarang menjalankan atau mengklaim prosedur Lead Review tanpa otorisasi eksplisit Raffi.
- **Integritas Akses:** Jangan pernah mengklaim telah membaca atau menerapkan aturan suatu skill jika file fisiknya tidak benar-benar diakses dalam sesi kerja aktif.

## 2. Batas Keselamatan Repositori (VCS Safety)
- **Kepemilikan Dokumentasi Inti:** Pembaruan [`PROJECT_CONTEXT.md`](../../PROJECT_CONTEXT.md) dan [`README.md`](../../README.md) mutlak berada di bawah kewenangan Lead Developer (Raffi). AI yang mendampingi developer (Dhafin/Firman) dilarang keras mengubah kedua dokumen tersebut di branch developer.
- **Kontrol File Baru:** Dilarang keras membuat file baru apa pun (kode, scene, aset, konfigurasi, dokumentasi, rule, atau skill baru) tanpa persetujuan eksplisit pengguna.
- **Preservasi Perubahan Lokal:** Pertahankan seluruh perubahan lokal yang belum di-commit; dilarang menimpa atau menghapus pekerjaan pengguna atau anggota tim lain.
- **Disiplin Git Mutlak:** Dilarang keras menjalankan operasi Git mutatif (`git add`, `git commit`, `git push`, `git pull`, `git merge`, `git reset`, `git clean`, `git checkout`, `git switch`, `git worktree`) tanpa instruksi eksplisit pengguna. Perintah inspeksi baca-saja (*read-only*) seperti `git status`, `git diff`, dan `git log` diizinkan sesuai kebutuhan verifikasi teknis.
