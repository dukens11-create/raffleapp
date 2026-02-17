# Grate Genyen - Flutter Mobile App

A Flutter-based mobile application for the Grate Genyen raffle ticket management system.

## Features

- 🎫 **Ticket Management** - Scan, verify, and manage raffle tickets
- 👥 **Multi-Role Support** - Admin, Seller, and Buyer interfaces
- 💳 **Payment Integration** - MonCash, NatCash, Stripe, and manual payments
- 📊 **Analytics Dashboard** - Sales reports and performance metrics
- 📷 **Camera Features** - QR/Barcode scanning and photo verification
- 🔐 **Secure Authentication** - JWT-based authentication with the backend API
- 📱 **Offline Support** - Local caching for offline access

## Getting Started

### Prerequisites

- Flutter SDK (3.0.0 or higher)
- Android Studio / Xcode
- Backend API running (from raffle-app directory)

### Installation

1. Clone the repository and navigate to the flutter_app directory:
```bash
cd flutter_app
```

2. Install dependencies:
```bash
flutter pub get
```

3. Configure the API endpoint in `lib/config/api_config.dart`

4. Run the app:
```bash
flutter run
```

### Building for Production

#### Android
```bash
flutter build apk --release
# or for app bundle:
flutter build appbundle --release
```

#### iOS
```bash
flutter build ios --release
```

## Architecture

The app follows a clean architecture pattern:

```
lib/
├── config/          # App configuration
├── models/          # Data models
├── services/        # API and business logic
├── providers/       # State management
├── screens/         # UI screens
│   ├── auth/       # Login, registration
│   ├── admin/      # Admin dashboard
│   ├── seller/     # Seller dashboard
│   └── buyer/      # Buyer portal
├── widgets/         # Reusable widgets
└── utils/          # Helper functions
```

## Backend API

This Flutter app connects to the existing Express.js backend API located in the `raffle-app` directory. Make sure the backend server is running before using the mobile app.

**Default backend URL:** `http://10.0.2.2:10000` (Android emulator)

The backend server runs on port **10000**. For detailed API configuration and connection setup for different environments (iOS, physical devices, etc.), see [`BACKEND_CONNECTION_GUIDE.md`](BACKEND_CONNECTION_GUIDE.md).

## Contributing

See the main repository README for contribution guidelines.

## License

This project is open source and available under the MIT License.
