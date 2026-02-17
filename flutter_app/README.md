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

## CI/CD with Codemagic

This project uses Codemagic for continuous integration and deployment.

- **Build Status:** [![Codemagic build status](https://api.codemagic.io/apps/<app-id>/status_badge.svg)](https://codemagic.io/apps/<app-id>/latest_build)
- **Configuration:** See `/codemagic.yaml` in repository root
- **Setup Guide:** See [CODEMAGIC_SETUP.md](CODEMAGIC_SETUP.md)

### Workflows

Three automated workflows are configured:

1. **Android Build** - Builds APK and AAB for Google Play Store
2. **iOS Build** - Builds IPA for Apple App Store  
3. **Development Build** - Quick debug builds with automated tests

### Quick Start

1. Builds trigger automatically on push to `main` branch
2. Download APK/AAB/IPA from build artifacts in Codemagic dashboard
3. Google Play (internal track) and App Store publishing configured
4. Email notifications sent to configured recipients

For detailed setup instructions, see [CODEMAGIC_SETUP.md](CODEMAGIC_SETUP.md).

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

This Flutter app connects to the backend API for the Grate Genyen raffle system.

### API Configuration

**Default Production URL:** `https://grategenyen.com`

The app is configured to connect to the production backend by default. If no data appears or you see connection errors, please verify:

1. Your device has internet connectivity
2. The backend server at `https://grategenyen.com` is accessible
3. Your network/firewall allows HTTPS connections

### Custom API URL (Development)

You can override the API URL for development or testing using the `--dart-define` flag:

```bash
# For Android Emulator (localhost development)
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:10000

# For iOS Simulator
flutter run --dart-define=API_BASE_URL=http://localhost:10000

# For Physical Device (replace with your computer's IP)
flutter run --dart-define=API_BASE_URL=http://192.168.1.100:10000

# For Production Build
flutter build apk --release --dart-define=API_BASE_URL=https://grategenyen.com
```

### Troubleshooting Connection Issues

If the app shows "Cannot connect to server" or no data appears:

1. **Check Internet Connection:** Ensure your device has active internet
2. **Verify Backend Status:** Confirm the backend at `https://grategenyen.com` is running
3. **Check Firewall:** Some corporate networks may block the connection
4. **View Logs:** Use `flutter run` in a terminal to see detailed connection logs
5. **Test Backend:** Open `https://grategenyen.com/health` in a browser to verify it's accessible

For detailed API configuration and connection setup for different environments, see [`BACKEND_CONNECTION_GUIDE.md`](BACKEND_CONNECTION_GUIDE.md).

## Contributing

See the main repository README for contribution guidelines.

## License

This project is open source and available under the MIT License.
