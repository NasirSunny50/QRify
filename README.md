# QRify — Premium QR & Barcode Scanner & Generator

<div align="center">

A powerful, feature-rich Flutter application for scanning and generating QR codes and barcodes with smart features and intuitive UI.

[Download APK](#installation) • [Features](#features) • [Getting Started](#getting-started) • [Documentation](#project-structure)

</div>

---

## 📱 Overview

**QRify** is a professional-grade mobile application that empowers users to scan QR codes, barcodes, and generate custom codes in multiple formats. With an intuitive interface, comprehensive history management, and smart content detection, it's your all-in-one solution for code management.

---

## ✨ Features

### 🔍 **Scanning Capabilities**

- **QR Code Scanner** — Decode QR codes containing:
  - URLs & web links
  - WiFi credentials
  - Contact information (vCard format)
  - Plain text messages
  - Email addresses
  - Phone numbers
  - SMS content

- **Barcode Scanner** — Read 1D barcodes:
  - EAN-13, EAN-8 (retail products)
  - Code 128, Code 39 (logistics & inventory)
  - UPC-A (product codes)
  - PDF417 (tickets & documents)

- **Gallery Import** — Scan codes from saved photos

### 🎨 **Generation Features**

- **QR Code Generator** — Create custom QR codes for:
  - URLs & web links
  - Plain text
  - Contact cards (vCard)
  - WiFi networks
  - Email addresses
  - Phone numbers

- **Barcode Generator** — Generate barcodes in 6 formats:
  - EAN-13, EAN-8, Code 128, Code 39, UPC-A, PDF417

### 🧠 **Smart Features**

- **Intelligent Result Detection** — Automatically recognizes content type and suggests relevant actions
  - Click URLs to open in browser
  - Call phone numbers directly
  - Join WiFi networks instantly
  - Save contacts automatically
- **Complete History** — Never lose your scan/generate data:
  - Persistent local storage
  - Advanced search functionality
  - Filter by type, date, and frequency
  - Mark favorite items
  - One-tap deletion

- **Quick Export** — Save and share with ease:
  - Export codes as high-quality PNG images
  - Native share sheet integration
  - Copy to clipboard
  - Save to device gallery

---

## 🚀 Getting Started

### Prerequisites

Before you begin, ensure you have the following installed:

- **Flutter SDK** — Version 3.x or higher
  - Check installation: `flutter --version`
  - [Install Flutter](https://flutter.dev/docs/get-started/install)
- **Development IDE** — Choose one:
  - Android Studio (Android development)
  - Xcode (iOS development)
  - VS Code with Flutter extension

- **Device/Emulator**:
  - Android device/emulator with Android 8.0+
  - iOS device/simulator with iOS 11.0+

### Installation

#### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/qrify.git
cd qrify
```

#### 2. Install Flutter Dependencies

```bash
# Get all required packages
flutter pub get

# (Optional) Update packages to latest versions
flutter pub upgrade
```

#### 3. Configure Platform-Specific Settings

**Android:**

```bash
# Ensure Android SDK is configured
flutter doctor --android-licenses

# Navigate to android directory
cd android
./gradlew clean
cd ..
```

**iOS:**

```bash
# Pod dependencies
cd ios
pod install --repo-update
cd ..
```

#### 4. Run the Application

**On Android:**

```bash
flutter run
# or specific device
flutter run -d <device-id>
```

**On iOS:**

```bash
flutter run -d iPhone
# or specific simulator
flutter run -d "iPhone 15 Pro"
```

**Build Release:**

```bash
# Android APK
flutter build apk --release

# iOS App Bundle
flutter build ios --release
```

---

## 📁 Project Structure

```
lib/
├── main.dart                        # Application entry point & splash screen
│
├── theme/
│   └── app_theme.dart              # Global theme, colors, typography, component styles
│
├── models/
│   └── history_item.dart           # Data models, storage services, business logic
│
├── widgets/
│   └── common_widgets.dart         # Reusable UI components (buttons, cards, dialogs)
│
└── screens/
    ├── home_screen.dart            # Dashboard with bottom navigation menu
    ├── scanner_screen.dart         # Camera scanner interface (QR + Barcode)
    ├── qr_generator_screen.dart    # Interactive QR code generator
    ├── barcode_generator_screen.dart        # Barcode generation interface
    ├── result_screen.dart          # Smart result display & action handler
    └── history_screen.dart         # History management with search & filters

android/
├── app/
│   └── src/main/
│       ├── AndroidManifest.xml     # Android permissions & configuration
│       ├── kotlin/ or java/        # Native Android code (if any)
│       └── res/                    # Android resources (drawables, layouts)
└── gradle files                    # Build configuration

ios/
├── Runner.xcodeproj                # Xcode project
├── Runner.xcworkspace              # Xcode workspace
└── Podfile                         # iOS dependencies configuration

test/
└── widget_test.dart                # Flutter widget tests

assets/
└── icon/                           # App icons & launch images
```

---

## 📦 Key Dependencies

| Package              | Version | Purpose                                     |
| -------------------- | ------- | ------------------------------------------- |
| `mobile_scanner`     | Latest  | Camera-based QR & barcode scanning engine   |
| `qr_flutter`         | Latest  | QR code rendering with customization        |
| `barcode_widget`     | Latest  | 1D barcode generation (EAN, Code 128, etc.) |
| `shared_preferences` | Latest  | Local persistent data storage for history   |
| `flutter_animate`    | Latest  | Smooth animations & transitions             |
| `google_fonts`       | Latest  | Inter font family integration               |
| `share_plus`         | Latest  | Native share & export functionality         |
| `url_launcher`       | Latest  | Open URLs, make calls, send emails          |
| `image_picker`       | Latest  | Gallery access for scanning photos          |
| `path_provider`      | Latest  | Temporary file management                   |
| `permission_handler` | Latest  | Runtime permission management               |
| `gal`                | Latest  | Gallery saving functionality                |

See [pubspec.yaml](pubspec.yaml) for complete dependency list.

---

## 🔐 Permissions

### Android Permissions (`AndroidManifest.xml`)

| Permission               | Purpose                 | Android Version |
| ------------------------ | ----------------------- | --------------- |
| `CAMERA`                 | QR/barcode scanning     | All             |
| `READ_EXTERNAL_STORAGE`  | Gallery import (photos) | ≤ API 32        |
| `WRITE_EXTERNAL_STORAGE` | Save codes to gallery   | ≤ API 29        |
| `READ_MEDIA_IMAGES`      | Gallery access (new)    | API 33+         |
| `WRITE_CONTACTS`         | Save contact cards      | All             |
| `READ_CONTACTS`          | Read contact info       | All             |
| `INTERNET`               | Open URLs               | All             |

### iOS Permissions (`Info.plist`)

| Key                                 | Description                |
| ----------------------------------- | -------------------------- |
| `NSCameraUsageDescription`          | Camera access for scanning |
| `NSPhotoLibraryUsageDescription`    | Read photos from gallery   |
| `NSPhotoLibraryAddUsageDescription` | Save to photo library      |
| `NSContactsUsageDescription`        | Contact save functionality |

---

## 🎯 Usage Guide

### Scanning QR Codes

1. Open the app and tap **Scan** from home
2. Point camera at QR code
3. Code automatically detects and shows results
4. Tap action button (Open URL, Call, etc.) or save to history

### Generating QR Codes

1. Tap **Generate** and select **QR Code**
2. Choose content type (URL, Text, Contact, WiFi, etc.)
3. Fill in the details
4. Preview generated code
5. Save or share directly

### Scanning Barcodes

1. From home, tap **Scan**
2. Point camera at barcode (1D format)
3. Code auto-detects format (EAN, Code 128, etc.)
4. View results and save to history

### Managing History

1. Tap **History** tab
2. Search by content or filter by type
3. Star items as favorites
4. Swipe to delete entries

---

## 🛠️ Configuration & Customization

### Theme Customization

Edit colors and styling in [lib/theme/app_theme.dart](lib/theme/app_theme.dart):

```dart
// Primary color
const primaryColor = Color(0xFF2196F3);

// Edit typography, button styles, spacing
```

### Adding New QR Types

Extend the QR generator in [lib/screens/qr_generator_screen.dart](lib/screens/qr_generator_screen.dart) to support additional content types.

### API Integration

To integrate with a backend service:

1. Add HTTP package to `pubspec.yaml`
2. Create API service in `lib/models/`
3. Implement cloud history sync

---

## 🐛 Troubleshooting

### Camera Not Working

- Check camera permission in app settings
- Verify `CAMERA` permission in AndroidManifest.xml
- Restart device and clear app cache

### Scanning Not Detecting Codes

- Ensure good lighting
- Hold camera steady
- Increase QR code size or distance
- Try importing image from gallery

### App Crashes on Launch

```bash
# Clean build
flutter clean
flutter pub get
flutter run
```

### iOS Build Issues

```bash
cd ios
rm -rf Pods Podfile.lock
pod install --repo-update
cd ..
flutter run
```

### Permission Denied Errors

- Update app permissions in:
  - Android: `AndroidManifest.xml`
  - iOS: `ios/Runner/Info.plist`
- Uninstall and reinstall app
- Grant permissions when prompted

---

## 📊 Performance Tips

- Keep history limited (delete old entries regularly)
- Use PNG export for better quality than JPG
- Close unnecessary background apps for faster scanning
- Keep Flutter dependencies updated: `flutter pub upgrade`

---

## 🤝 Contributing

Contributions are welcome! To contribute:

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/YourFeature`
3. Commit changes: `git commit -am 'Add YourFeature'`
4. Push to branch: `git push origin feature/YourFeature`
5. Open a Pull Request

Please follow Dart style guidelines and test thoroughly before submitting.

---

## 📄 License

This project is licensed under the MIT License - see [LICENSE](LICENSE) file for details.

---

## 📞 Support & Contact

- **Report Issues**: [GitHub Issues](https://github.com/yourusername/qrify/issues)
- **Feature Requests**: [GitHub Discussions](https://github.com/yourusername/qrify/discussions)
- **Email**: your.email@example.com

---

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Package maintainers: `mobile_scanner`, `qr_flutter`, and other dependencies
- Community feedback and contributions

---

## 📈 Roadmap

- [ ] Cloud backup & sync
- [ ] Batch scanning
- [ ] Custom QR code designs
- [ ] OCR text recognition
- [ ] Cloud storage integration
- [ ] Dark mode optimization

---

**Made with ❤️ using Flutter**

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
