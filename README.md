# Memories Engine 📸

**A High-Performance Media Gallery & Document Ledger Workspace**

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Release](https://img.shields.io/github/v/release/ajy-ocean/memories?style=for-the-badge&color=orange)](https://github.com/ajy-ocean/memories/releases)

<p align="center">
  <img src="assets/icon/app_icon.png" width="200" alt="Memories Logo">
</p>

## 🚀 Overview

**Memories** is a streamlined, optimized local asset manager built with Flutter. It replaces cluttered native applications with a clean, responsive layout designed around a professional white-and-red brand aesthetic. The application scans, compiles, and serves device photo directories, video playback streams, and local documents through an integrated, high-speed dashboard.

---

## 📥 Download & Install

Experience the production-ready gallery architecture on your device immediately.

**[➔ Download Memories APK (Latest Build)](https://github.com/ajy-ocean/memories/releases/latest/download/memories.apk)**

> **Note:** Because this app is distributed as a standalone release package, you may need to grant your mobile web browser or file manager permission to *“Install unknown applications”* in your device's security preferences.

---

## ✨ Key Features

### 📷 Folder-Grouped Photo Library
* Scans local device directories instantly using high-speed background worker queries.
* Organizes pictures dynamically into horizontal scrolling album rows (e.g., Camera, Screenshots).
* Wraps asset instances in responsive hitboxes to launch an immersive, dark-canvas full-screen interactive preview deck.

---

## 🛠️ Tech Stack & Architecture

* **Framework:** [Flutter](https://flutter.dev) (Enforced Java 17 toolchain requirements for the Android compilation layer)
* **Language:** [Dart](https://dart.dev)
* **State Management:** Riverpod (Watching folder streams and mapping local storage arrays asynchronously)
* **Core Packages:** 
  * `photo_manager` & `photo_manager_image_provider` for hardware gallery indexing.
  * `video_player` for native media streaming capabilities.
  * `open_filex` for external OS document view execution.
* **UI/UX:** Monochromatic typography framework contrasted with a sharp, bold primary brand red (`#D32F2F`) color scheme.

---
