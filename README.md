<div align="center">

# 💸 Wise Expense

### Smart Cross-Platform Expense Tracker

*Built with Flutter · Runs on Android, iOS & Web · Dockerized for easy deployment*

[![Flutter](https://img.shields.io/badge/Flutter-3.19.6-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.3.4-0175C2?logo=dart)](https://dart.dev)
[![Docker](https://img.shields.io/badge/Docker-ready-2496ED?logo=docker)](https://docker.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

</div>

---

## 📖 Table of Contents

1. [Overview](#-overview)
2. [Features](#-features)
3. [Tech Stack](#-tech-stack)
4. [Project Structure](#-project-structure)
5. [Database / Storage Details](#-database--storage-details)
6. [Getting Started – Local Dev](#-getting-started--local-development)
7. [Docker Deployment](#-docker-deployment)
8. [Environment & Configuration](#-environment--configuration)
9. [AI Features](#-ai-features)
10. [Screenshots](#-screenshots)
11. [Contributing](#-contributing)

---

## 🌟 Overview

**SpendWise AI** helps users understand where their money goes, detect overspending habits, and receive actionable AI-driven suggestions — all offline-first with no account required.

| Platform | Status |
|----------|--------|
| 🌐 Web (Docker / Browser) | ✅ Ready |
| 🤖 Android | ✅ Ready |
| 🍎 iOS | ✅ Ready |

---

## ✨ Features

| Feature | Details |
|---------|---------|
| **Add Expense** | Amount, category, date, optional note |
| **Dashboard** | Monthly total, budget progress bar, recent transactions |
| **History** | Full list with category filter chips, swipe-to-delete |
| **Insights** | Pie chart, weekly trend bars, AI tips, habit detection |
| **Budget Alerts** | Local notifications at 80% and 100% of limit |
| **Settings** | Monthly/daily limits, theme toggle, clear all data |
| **Security** | Face ID, Admin Password, Master Recovery Key |
| **Offline-first** | SQLite (sqflite) + Hive – no internet required |

---

## 🛠 Tech Stack

| Layer | Technology |
|-------|-----------|
| **UI Framework** | Flutter 3.x (Dart) |
| **State Management** | Provider (`ChangeNotifier`) |
| **Local Database** | SQLite (sqflite) + Hive 2 |
| **Charts** | fl_chart |
| **Animations** | flutter_animate |
| **Notifications** | flutter_local_notifications |
| **Fonts** | Google Fonts (Poppins) |
| **Web Server** | nginx 1.25 (via Docker) |
| **Container** | Docker + Docker Compose |

---

## 📁 Project Structure

```
exp_tracker/
 ├── Dockerfile                  ← Multi-stage build (Flutter → nginx)
 ├── docker-compose.yml          ← One-command deployment
 ├── .dockerignore
 ├── pubspec.yaml                ← Dependencies
 └── lib/
     ├── main.dart               ← Entry point (Hive init, providers, app)
     ├── theme/
     │   └── app_theme.dart      ← Light + Dark themes
     ├── models/
     │   ├── expense.dart        ← Expense data model (HiveObject)
     │   ├── expense.g.dart      ← Generated Hive adapter
     │   ├── budget.dart         ← Budget model (HiveObject)
     │   ├── budget.g.dart       ← Generated Hive adapter
     │   └── category.dart       ← ExpenseCategory enum
     ├── services/
     │   ├── hive_service.dart       ← CRUD operations
     │   ├── analytics_service.dart  ← Spending analysis logic
     │   ├── ai_service.dart         ← AI suggestion engine
     │   └── notification_service.dart
     ├── providers/
     │   ├── expense_provider.dart
     │   └── budget_provider.dart
     ├── widgets/
     │   ├── expense_card.dart
     │   ├── category_chip.dart
     │   ├── spending_chart.dart
     │   ├── insight_card.dart
     │   └── budget_progress_bar.dart
     └── screens/
         ├── dashboard_screen.dart
         ├── add_expense_screen.dart
         ├── history_screen.dart
         ├── insights_screen.dart
         └── settings_screen.dart
```

---

## 🔐 Security & Authentication

SpendWise AI is protected by a secure login layer to keep your financial data private.

### Default Credentials
On the first run, the app seeds a default admin account:
- **Username**: `admin`
- **Password**: `admin123`

### Recovery (Master Password)
If you forget your admin password, you can use the **Master Password** to reset it:
- **Master Password**: `spendwise_master_2024`
- **Action**: Use the "Forgot Password?" link on the login screen, enter the master password, and the admin password will be reset to `admin123`.

### Biometrics
- **Face ID / Touch ID**: Enabled for quick and secure access on supported devices.

---

## 🗄 Database / Storage Details

SpendWise AI uses **[Hive](https://docs.hivedb.dev/)** – a lightweight, blazing-fast, purely Dart key-value database. It requires **no external server** and stores data locally on the device.

### Boxes (Collections)

| Box Name | Type | Purpose |
|----------|------|---------|
| `expenses` | `Box<Expense>` | All expense records |
| `budgets` | `Box<Budget>` | Monthly and daily limit settings |

### Expense Schema

| Field | Dart Type | Hive Field | Description |
|-------|-----------|------------|-------------|
| `id` | `String` | 0 | UUID v4, primary key |
| `amount` | `double` | 1 | Expense amount in Rs. |
| `category` | `String` | 2 | Category name (enum-backed) |
| `date` | `DateTime` | 3 | Date of expense |
| `note` | `String?` | 4 | Optional description |

### Budget Schema

| Field | Dart Type | Hive Field | Description |
|-------|-----------|------------|-------------|
| `monthlyLimit` | `double` | 0 | Monthly spending cap |
| `dailyLimit` | `double` | 1 | Daily spending cap |

### Storage Location

| Platform | Path |
|----------|------|
| Android | `/data/data/<package>/app_flutter/` |
| iOS | `<Documents>/` |
| Web | `IndexedDB` (browser storage) |
| Linux/macOS (dev) | `~/.local/share/<app>/` |

> **Note:** Hive data is stored exclusively on-device. There is no remote database or cloud sync in the current version.

---

## 🚀 Getting Started – Local Development

### Prerequisites

- [Flutter SDK ≥ 3.2.0](https://docs.flutter.dev/get-started/install)
- [Dart SDK ≥ 3.2.0](https://dart.dev/get-dart) (bundled with Flutter)

```bash
# Verify installation
flutter doctor
```

### 1. Clone

```bash
git clone https://github.com/Sanish777/Expense-Tracker.git
cd Expense-Tracker
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Run

```bash
# Web (Chrome)
flutter run -d chrome

# Android (emulator / physical device)
flutter run -d android

# iOS (Xcode Simulator)
flutter run -d ios
```

### 4. Build Release

```bash
# Web
flutter build web --release --web-renderer canvaskit

# Android APK
flutter build apk --release

# iOS
flutter build ios --release
```

### 5. Run Release Build on Device After Changes

To test changes in a fully optimized production environment (especially useful for UI/Animation adjustments):

```bash
# View attached devices and get your device ID
flutter devices

# Run on specific device in release mode (iOS or Android)
flutter run -d <DEVICE_ID> --release
```

### 6. Regenerate Hive Adapters *(only if you modify models)*

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## 🐳 Docker Deployment

The Docker setup builds the Flutter web app and serves it via **nginx**.

### Requirements

- [Docker ≥ 24.x](https://docs.docker.com/get-docker/)
- [Docker Compose ≥ 2.x](https://docs.docker.com/compose/install/)

### Quick Start

```bash
# Clone the repository
git clone https://github.com/Sanish777/Expense-Tracker.git
cd Expense-Tracker

# Build & start (first build takes ~5-10 min for Flutter SDK download)
docker compose up -d --build

# Open in browser
open http://localhost:8080
```

### Docker Commands Reference

```bash
# Build image only
docker compose build

# Start (detached)
docker compose up -d

# View logs
docker compose logs -f spendwise_web

# Stop
docker compose down

# Stop and remove volumes
docker compose down -v

# Rebuild after code changes
docker compose up -d --build --force-recreate
```

### Container Details

| Property | Value |
|----------|-------|
| Base Image | `ubuntu:22.04` (build) + `nginx:1.25-alpine` (serve) |
| Exposed Port | `80` (container) → `8080` (host) |
| Container Name | `spendwise_ai` |
| Restart Policy | `unless-stopped` |
| Health Check | HTTP GET to `localhost:80` every 30s |

### Docker File Structure

```
Dockerfile          ← Multi-stage: flutter-build → nginx-serve
docker-compose.yml  ← Service definition with health check
docker/
 └── nginx.conf     ← SPA routing, caching, gzip, security headers
.dockerignore       ← Excludes build artifacts, IDE files, git history
```

---

## ⚙️ Environment & Configuration

SpendWise AI is **configuration-free** for local use (all settings are stored in Hive at runtime). However, for Docker you can pass:

```yaml
# docker-compose.yml → environment section
environment:
  - TZ=Asia/Kathmandu   # Timezone for the nginx container
```

### Future Firebase Integration *(optional)*

The `pubspec.yaml` is ready for Firebase Auth + Firestore. To enable:

1. Add `firebase_core`, `firebase_auth`, `cloud_firestore` to `pubspec.yaml`
2. Place `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
3. Run `flutterfire configure`

---

## 🤖 AI Features

All AI features are **local and rule-based** — no API key, no internet required:

| Feature | Logic |
|---------|-------|
| **Overspending Detection** | Category > 40% of monthly total → warning banner |
| **Smart Tips** | Compares category percentages to thresholds → tip strings |
| **Habit Detection** | Category appearing on ≥ 5 days in a month → habit card |
| **Motivational Message** | Based on `spent / limit` ratio on Dashboard |

---

## 🤝 Contributing

1. Fork the repo
2. Create a branch: `git checkout -b feat/your-feature`
3. Commit: `git commit -m "feat: add your feature"`
4. Push: `git push origin feat/your-feature`
5. Open a Pull Request

---

## 📄 License

MIT © 2024 Sanish Shakya

---

<div align="center">
Made with ❤️ using Flutter
</div>
