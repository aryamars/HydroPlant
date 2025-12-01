# 💧 HydroPlant: IoT Smart Watering System

> Sistem penyiram tanaman pintar berbasis IoT yang dibangun dengan **ESP32**, **MQTT**, dan **Flutter**. Memungkinkan pemantauan kelembaban tanah secara *real-time* dan kontrol pompa air nirkabel melalui aplikasi mobile.

![hydroplant](https://github.com/user-attachments/assets/02c9a047-954b-4735-886d-7389dd6671fb)

[![Flutter](https://img.shields.io/badge/Flutter-v1.0-blue)](https://flutter.dev/)
[![MQTT](https://img.shields.io/badge/MQTT-HiveMQ-orange)](https://www.hivemq.com/)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

---

## ✨ Fitur Utama

| Ikon | Fitur | Deskripsi |
| :---: | :--- | :--- |
| 💧 | **Real-time Moisture Monitoring** | Visualisasi kelembaban tanah (Moisture %) secara *live* melalui aplikasi Flutter. |
| 펌프 | **Remote Pump Control** | Kontrol ON/OFF pompa air jarak jauh melalui protokol MQTT. |
| 🌐 | **Seamless Connectivity** | Konfigurasi WiFi *out-of-the-box* menggunakan `WiFiManager`. |
| 🛡️ | **Hardware Stability** | Menggunakan Power MOSFET/Relay dengan proteksi untuk manajemen beban pompa yang stabil. |
| 📱 | **User Interface** | Antarmuka pengguna yang bersih dan *cross-platform*. |

---

## 🛠️ Stack Teknologi

| Komponen | Bahasa/Teknologi | Catatan |
| :--- | :--- | :--- |
| **Microcontroller** | ESP32 | Otak sistem, menangani sensor dan koneksi WiFi. |
| **Firmware** | Arduino C++ | Logika sensor, pompa, dan MQTT. |
| **Mobile App** | Flutter (Dart) | Aplikasi *user interface* yang berjalan di Android/iOS. |
| **Protocol** | MQTT | Komunikasi data antara ESP32 dan App (Broker: `broker.hivemq.com`). |

---

## 🚀 Panduan Instalasi

### A. Persiapan Firmware (ESP32)

1.  **Buka Project:** Buka *source code* Arduino C++ kamu.
2.  **Verifikasi Topik:** Pastikan detail topik MQTT sudah sesuai dengan kode aplikasi:
    * **Topic Publish (Moisture):** `plant/moisture`
    * **Topic Subscribe (Pump Control):** `plant/pump/control`
3.  **Unggah Kode:** Hubungkan ESP32, atur Board dan Port yang benar, lalu unggah kode.

### B. Persiapan Aplikasi Mobile (Flutter)

1.  **Clone Repositori:**
    ```bash
    git clone [https://github.com/](https://github.com/)[Nama_Akun_GitHub_Kamu]/HydroPlant.git
    cd HydroPlant
    ```
2.  **Dependencies:** Unduh *package* yang dibutuhkan (termasuk `mqtt_client`):
    ```bash
    flutter pub get
    ```
3.  **Jalankan Aplikasi:** Hubungkan perangkat atau *emulator*, lalu jalankan:
    ```bash
    flutter run
    ```

---

## 📸 Tampilan Aplikasi

![WhatsApp Image 2025-12-01 at 18 06 37](https://github.com/user-attachments/assets/de80a7c5-a347-4736-b223-9087dc4137e7)

---

## 🤝 Kontribusi

Project ini dibuat karena keinginan pembuat membantu project rekannya.

---

## 📄 Lisensi

Didistribusikan di bawah Lisensi MIT. Lihat file `LICENSE` untuk informasi lebih lanjut.

<br>
Dibuat oleh Aryawangi Rahmawanto
