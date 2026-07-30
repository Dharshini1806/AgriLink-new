# AgriLink Flutter App

## Quick Setup

### 1. Install dependencies
```bash
flutter pub get
```

### 2. Configure Backend URL
Edit `lib/core/constants/api_endpoints.dart`:
```dart
// Android emulator:
defaultValue: 'http://10.0.2.2:10000'
// iOS simulator:
defaultValue: 'http://localhost:10000'
// Physical device / Production:
defaultValue: 'https://agri-link-omib.onrender.com'
```

### 3. Add Firebase config files
- **Android**: Download `google-services.json` from Firebase Console → place in `android/app/`
  - Rename `android/app/google-services.json.template` → fill in values → save as `google-services.json`
- **iOS**: Download `GoogleService-Info.plist` from Firebase Console → place in `ios/Runner/`
  - Rename `ios/Runner/GoogleService-Info.plist.template` → fill in values → save as `GoogleService-Info.plist`

### 4. Run the app
```bash
# Android
flutter run

# iOS (requires Mac + Xcode)
cd ios && pod install && cd ..
flutter run
```

## Project Structure
```
lib/
├── core/
│   ├── constants/      # Colors, Theme, Router, API endpoints
│   ├── errors/         # Failures, Exceptions
│   ├── network/        # Dio client + interceptors
│   └── utils/          # Formatters, Validators
├── features/
│   ├── auth/           # Role select, Login, Register
│   ├── products/       # Feed, Detail, Search, Compare
│   ├── orders/         # Cart, Checkout, Tracking
│   ├── chat/           # Real-time Socket.io chat
│   ├── seller/         # Dashboard, Add Product, Analytics
│   ├── profile/        # Profile view/edit
│   ├── smart/          # Recipe to cart
│   └── admin/          # Admin panel
└── shared/
    └── widgets/        # Reusable UI components
```

## Test Accounts (after running schema.sql)
- **Admin**: admin@agrilink.in / Admin@1234

## Build APK
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```
