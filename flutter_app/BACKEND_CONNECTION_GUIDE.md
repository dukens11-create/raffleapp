# Backend Connection Guide for Flutter App

## Overview
This guide explains how to connect the Flutter mobile app to the backend API server.

## Default Configuration

The Flutter app is configured to connect to:
- **Default URL**: `http://10.0.2.2:10000`
- **Port**: 10000 (backend default port)
- **Network**: Android emulator uses `10.0.2.2` to access host machine's localhost

## Backend Server Setup

### 1. Finding Your Backend URL

#### For Android Emulator:
- Use `http://10.0.2.2:10000` (already configured as default)
- The emulator maps `10.0.2.2` to the host machine's `127.0.0.1`

#### For iOS Simulator:
- Use `http://localhost:10000` or `http://127.0.0.1:10000`
- iOS simulator can directly access localhost

#### For Physical Devices:
- Find your computer's local IP address:
  ```bash
  # On Linux/Mac
  ifconfig | grep "inet "
  
  # On Windows
  ipconfig
  ```
- Use `http://<your-local-ip>:10000`
- Example: `http://192.168.1.100:10000`
- **Important**: Ensure your phone and computer are on the same WiFi network

### 2. Starting the Backend Server

Make sure the backend is running on port 10000:

```bash
cd raffle-app
node server.js
```

You should see:
```
🚀 Server running on port 10000
```

### 3. Verify Backend is Accessible

Test the backend health endpoint:

```bash
# From your computer
curl http://localhost:10000/health

# From Android emulator (use adb shell)
adb shell
curl http://10.0.2.2:10000/health
```

Expected response:
```json
{
  "status": "ok",
  "timestamp": "2026-02-17T..."
}
```

## Custom API Base URL

To override the default URL, set the `API_BASE_URL` environment variable when building:

### For Android:
```bash
flutter build apk --dart-define=API_BASE_URL=http://192.168.1.100:10000
```

### For iOS:
```bash
flutter build ios --dart-define=API_BASE_URL=http://localhost:10000
```

### For Development (flutter run):
```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:10000
```

## Network Configuration Files

### Android Network Security Config

Location: `android/app/src/main/res/xml/network_security_config.xml`

This file allows HTTP connections for development:
```xml
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <base-config cleartextTrafficPermitted="true">
        <trust-anchors>
            <certificates src="system" />
        </trust-anchors>
    </base-config>
</network-security-config>
```

### iOS App Transport Security

Location: `ios/Runner/Info.plist`

Add this to allow HTTP connections:
```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

## Troubleshooting

### Error: "Error Loading Tickets"

**Symptoms**: The Available Tickets tab shows an error message

**Common Causes**:

1. **Backend not running**
   - Solution: Start the backend server with `node server.js`
   - Verify: Check console for "Server running on port 10000"

2. **Wrong port**
   - Solution: Ensure backend is on port 10000, not 3000
   - Verify: Check `raffle-app/server.js` for `const PORT = process.env.PORT || 10000`

3. **Network connectivity**
   - For Android emulator: Try `adb shell ping 10.0.2.2`
   - For physical devices: Ensure same WiFi network
   - Check firewall settings on host machine

4. **CORS issues** (usually not a problem for mobile apps)
   - Mobile apps don't have CORS restrictions like web browsers
   - If you see CORS errors, it's likely a web browser test

### Viewing Debug Logs

#### Flutter Console Logs:
```bash
flutter logs
```

Look for:
- `❌ Available Tickets Error:` - Connection or parsing errors
- `Response body:` - Actual API response (for debugging format issues)

#### Backend Console Logs:
Check the terminal running `node server.js` for:
- `📥 Buyer available-tickets endpoint called` - Request received
- `❌ Error in /api/buyer/available-tickets:` - Server-side errors

### Testing API Endpoints Manually

You can test the API with curl or a tool like Postman:

```bash
# Get available tickets
curl http://localhost:10000/api/buyer/available-tickets

# Get raffle info
curl http://localhost:10000/api/public/raffle-info

# Get ticket availability
curl http://localhost:10000/api/public/ticket-availability
```

Expected response format for available tickets:
```json
{
  "categories": {
    "ABC": [
      {
        "ticket_number": "ABC-000001",
        "barcode": "BC001",
        "category": "ABC",
        "price": 100,
        "status": "AVAILABLE",
        "created_at": "..."
      }
    ],
    "EFG": [...],
    "JKL": [...],
    "XYZ": [...]
  },
  "timestamp": "2026-02-17T..."
}
```

## Production Deployment

For production:

1. **Use HTTPS**: Always use secure connections
   ```dart
   defaultValue: 'https://api.yourdomain.com'
   ```

2. **Environment Variables**: Set `API_BASE_URL` during build
   ```bash
   flutter build apk --dart-define=API_BASE_URL=https://api.yourdomain.com
   ```

3. **Remove Debug Logs**: Consider removing `print()` statements in production

4. **Update Network Security**: 
   - Android: Remove `cleartextTrafficPermitted="true"`
   - iOS: Remove `NSAllowsArbitraryLoads`

## Additional Resources

- Flutter HTTP Package: https://pub.dev/packages/http
- Android Network Security: https://developer.android.com/training/articles/security-config
- iOS App Transport Security: https://developer.apple.com/documentation/security/preventing_insecure_network_connections

## Support

If you continue to experience issues:

1. Check backend logs for errors
2. Verify network connectivity
3. Test API endpoints manually with curl
4. Review Flutter debug logs with `flutter logs`
5. Ensure correct port (10000) and IP address configuration
