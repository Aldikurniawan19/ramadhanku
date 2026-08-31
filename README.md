# 🌙 Ramadhan & Islamic Companion App (Flutter)

<p align="center">
  <img src="assets/images/home.png" alt="Ramadhan App Banner" width="220" />
</p>

<p align="center">
  <b>Aplikasi Pendamping Ibadah Ramadhan & Harian Islami Terlengkap Berbasis Flutter</b>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter Badge" />
  <img src="https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart Badge" />
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20iOS-brightgreen?style=for-the-badge&logo=android" alt="Platform Badge" />
  <img src="https://img.shields.io/badge/License-MIT-gold?style=for-the-badge" alt="License Badge" />
</p>

---

## 📌 Deskripsi Proyek

**Ramadhan Flutter** adalah aplikasi mobile Islami modern dan elegan yang dirancang khusus untuk mempermudah ibadah umat Muslim, baik di bulan suci Ramadhan maupun dalam kehidupan harian. Dilengkapi dengan antarmuka bernuansa **Islamic Modern Gold & Deep Emerald Green**, animasi khusus **Rub El Hizb 8 Sudut**, serta fitur spiritual yang lengkap.

---

## ✨ Fitur Utama (Feature Highlights)

### 📖 1. Al-Qur'an 30 Juz & Audio Player
* **Teks Arab & Terjemahan**: Teks Arab sesuai standar Kemenag RI dilengkapi terjemahan Bahasa Indonesia.
* **Audio Murottal Per Surah & Ayat**: Mendengarkan audio tilawah dari Qari ternama (*Mishary Rashid Al-Afasy*, dll.).
* **Floating Audio Player**: Bar pemutar audio melayang (*floating player*) yang tetap aktif saat berpindah halaman.
* **Filter & Pencarian**: Pencarian cepat nama/nomor surah serta filter kategori *Makkiyah*, *Madaniyah*, dan *Juz*.

### 🕌 2. Jadwal Sholat & Waktu Imsakiyah Otomatis
* **Presisi Waktu Sholat**: Menampilkan waktu Subuh, Terbit, Dzuhur, Ashar, Maghrib, dan Isya.
* **Hitung Mundur (*Countdown*)**: Timer hitung mundur real-time menuju waktu sholat/buka puasa berikutnya.
* **Deteksi Lokasi GPS & Pemilih Kota Manual**: Deteksi otomatis lokasi via GPS atau pilihan kota secara manual seluruh Indonesia.

### 📜 3. Hadits Shahih Lengkap (Kitab 6 Imam)
* **Koleksi Kitab Utama**: Hadits dari Imam Bukhari, Muslim, Tirmidzi, Abu Daud, Nasai, dan Ibnu Majah.
* **Pasangan Teks Arab & Terjemahan**: Setiap hadits disajikan lengkap dengan teks Arab harakat dan terjemahan Indonesia.
* **Offline Fallback**: Tetap dapat diakses meski tanpa koneksi internet (25 Hadits Pilihan offline).

### 🤲 4. Kumpulan Doa Harian (227+ Doa)
* **Ribuan Doa Pilihan**: Kategori doa Puasa, Sholat, Makan, Rumah, Perlindungan, dan Doa Harian.
* **Transliterasi Latin**: Dilengkapi teks Arab, transliterasi Latin, serta arti terjemahan.

### 📅 5. Kalender Hijriah & Countdown Hari Besar Islami
* **Grid Kalender Masehi & Hijriah**: Tampilan kalender bulanan dengan penanggalan pudar (*faded dates*) untuk overflow bulan sebelum & sesudah.
* **Kartu Hitung Mundur Hari Besar**: Countdown otomatis menuju *Hari Raya Idul Fitri*, *Idul Adha*, *Isra Mi'raj*, *Nuzulul Qur'an*, dan *Tahun Baru Hijriah*.

### 🧭 6. Kompas Arah Kiblat Interaktif
* **Akurasi Kiblat**: Penunjuk arah Kakbah menggunakan sensor kompas perangkat yang presisi dengan kalkulasi derajat lokasi.

### 🎨 7. Desain & Animasi Islami Premium
* **Islamic Aesthetics**: Palet warna Deep Emerald Green (`#063D2E`) dan Islamic Gold Accent (`#D4AF37`).
* **Karakter Unta Berjalan**: Animasi unik karakter unta berjalan di atas bukit pasir gurun (*Desert Dunes*) pada tampilan pencarian kosong.
* **Keyboard Inset Fixed Background**: Latar belakang tidak akan bergeser atau terdorong saat keyboard software muncul.

---

## 🛠️ Teknologi & Library yang Digunakan

* **Framework**: [Flutter](https://flutter.dev/) (Dart 3.x)
* **State Management**: `provider`
* **Typography**: `google_fonts` (Lora & Amiri Typography)
* **Audio Player**: `just_audio` / `audioplayers`
* **Network & API**: `http` (Integrasi jsDelivr CDN, Equran.id API, MyQuran API)
* **Location & Compass**: `geolocator`, `flutter_compass`
* **Preferences**: `shared_preferences`
* **Animations**: `animations`, Custom Painters (`CustomPaint`)

---

## 📂 Struktur Folder Proyek (`lib/`)

```text
lib/
├── core/
│   ├── router/          # Transisi rute halaman (SmoothPageRoute)
│   ├── theme/           # Token warna (AppColors) & tema global
│   └── widgets/         # Komponen UI terpakai ulang (IslamicEmptyState, GlassBackButton, Shimmer)
├── data/
│   ├── models/          # Model data (SurahModel, HaditsModel, DoaModel, EventModel)
│   └── services/        # Service API (HaditsService, DoaService, PrayerService, FirebaseService)
├── features/
│   ├── auth/            # Halaman Login & Register
│   ├── doa/             # Layar List & Detail Doa Harian
│   ├── hadits/          # Layar List & Detail Hadits Shahih
│   ├── home/            # Layar Beranda utama & Kartu Waktu Sholat
│   ├── jadwal_sholat/   # Layar Jadwal Sholat Lengkap
│   ├── kalender/        # Layar Kalender Hijriah & Event Countdown
│   ├── kiblat/          # Layar Kompas Arah Kiblat
│   ├── murottal/        # Layar Pemutar Audio Murottal
│   ├── quran/           # Layar List & Detail Al-Qur'an 30 Juz
│   └── splash/          # Layar Splash Screen & Rub El Hizb Animated Loader
├── providers/           # Provider State Management (QuranProvider, PrayerProvider, HaditsProvider, DoaProvider)
└── main.dart            # Entry point aplikasi Flutter
```

---

## 🚀 Cara Menjalankan Proyek (Getting Started)

### Prasyarat
* [Flutter SDK](https://docs.flutter.dev/get-started/install) (versi 3.19.0 atau lebih baru)
* [Android Studio](https://developer.android.com/studio) / [VS Code](https://code.visualstudio.com/)
* Perangkat Android / Emulator atau iOS Simulator

### Langkah-Langkah Instalasi

1. **Clone repository ini**:
   ```bash
   git clone https://github.com/USERNAME/ramadhan_flutter.git
   cd ramadhan_flutter
   ```

2. **Install dependency paket**:
   ```bash
   flutter pub get
   ```

3. **Jalankan aplikasi di emulator/perangkat**:
   ```bash
   flutter run
   ```

4. **Build Rilis APK (Android Release)**:
   ```bash
   flutter build apk --release
   ```
   *File APK rilis akan berlokasi di: `build/app/outputs/flutter-apk/app-release.apk`*

---

## 📡 Sumber API & Lisensi Data

Aplikasi ini menggunakan API terbuka (*Open Source APIs*) gratis dan legal:
* **Al-Qur'an & Terjemahan**: `https://equran.id/api` & `https://api.myquran.com`
* **Hadits Shahih**: `fawazahmed0/hadith-api` di jsDelivr CDN & MyQuran API
* **Doa Harian**: `https://equran.id/api/doa`
* **Jadwal Sholat**: Calculation method Aladhan & Kemenag RI

---

## 📄 Lisensi

Proyek ini dilesensikan di bawah [Lisensi MIT](LICENSE). Bebas untuk digunakan, dimodifikasi, dan dikembangkan untuk kebaikan bersama.

<p align="center">
  <i>Dibuat dengan ❤️ & keikhlasan untuk menyambut bulan suci Ramadhan. Semoga bermanfaat!</i>
</p>
