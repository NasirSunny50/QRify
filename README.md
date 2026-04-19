# QRify — QR & Barcode App

A premium Flutter app for scanning and generating QR codes and barcodes.

## Features

- **QR Scanner** — Scan any QR code (URL, WiFi, Contact, Text, Email, Phone, SMS)
- **QR Generator** — Create QR codes for URL, Text, Contact (vCard), WiFi, Email, Phone
- **Barcode Scanner** — Scan EAN-13, EAN-8, Code 128, Code 39, UPC-A, PDF417
- **Barcode Generator** — Generate barcodes in 6 formats
- **Smart Result Screen** — Auto-detects content type and shows smart actions
- **History** — Full scan/generate history with search, filter, and favorites
- **Gallery Import** — Scan QR codes from photos
- **Share & Save** — Export generated codes as PNG

---

## Setup

### 1. Prerequisites

- Flutter 3.x (`flutter --version` to check)
- Android Studio / Xcode

### 2. Install dependencies

```bash
cd qrify_app
flutter pub get
```

### 3. Run the app

```bash
# Android
flutter run

# iOS
flutter run -d iPhone
```

---

## Project Structure

```
lib/
├── main.dart                   # App entry + Splash screen
├── theme/
│   └── app_theme.dart          # Colors, typography, component styles
├── models/
│   └── history_item.dart       # Data model + local storage service
├── widgets/
│   └── common_widgets.dart     # Reusable UI components
└── screens/
    ├── home_screen.dart         # Dashboard + bottom navigation
    ├── scanner_screen.dart      # Camera scanner (QR + Barcode)
    ├── qr_generator_screen.dart # QR code generator
    ├── barcode_generator_screen.dart  # Barcode generator
    ├── result_screen.dart       # Scan/generate result view
    └── history_screen.dart      # History with search & filters
```

---

## Key Packages

| Package              | Purpose                                 |
| -------------------- | --------------------------------------- |
| `mobile_scanner`     | Camera-based QR & barcode scanning      |
| `qr_flutter`         | QR code rendering with custom styles    |
| `barcode_widget`     | Barcode rendering (EAN, Code 128, etc.) |
| `shared_preferences` | Local history persistence               |
| `flutter_animate`    | Smooth animations throughout the app    |
| `google_fonts`       | Inter font family                       |
| `share_plus`         | Native share sheet                      |
| `url_launcher`       | Open URLs, phone calls, emails          |
| `image_picker`       | Scan QR from gallery images             |
| `path_provider`      | Temp file storage for sharing           |
| `permission_handler` | Camera & storage permissions            |

---

## Permissions

### Android (`AndroidManifest.xml`)

- `CAMERA` — Required for scanning
- `READ_MEDIA_IMAGES` — For gallery import (Android 13+)
- `WRITE_EXTERNAL_STORAGE` — Save to gallery (Android ≤ 9)

### iOS (`Info.plist`)

- `NSCameraUsageDescription`
- `NSPhotoLibraryUsageDescription`
- `NSPhotoLibraryAddUsageDescription`

---

## Customization

### Change accent colors

Edit `lib/theme/app_theme.dart`:

```dart
static const primary = Color(0xFF6C63FF);   // Purple → change this
static const accent  = Color(0xFFFF6584);   // Pink → change this
static const success = Color(0xFF00D9A3);   // Teal → change this
```

### Add a new QR type

In `qr_generator_screen.dart`, add to `_types` list and handle in `_buildQRData()` and `_buildInputFields()`.

### Add a new barcode format

In `barcode_generator_screen.dart`, add a `_BarcodeFormat` to the `_formats` list.

& "D:\flutter\bin\flutter.bat" run -d chrome
& "D:\flutter\bin\flutter.bat" build apk
D:\flutter\bin\flutter.bat build apk --release --split-per-abi
