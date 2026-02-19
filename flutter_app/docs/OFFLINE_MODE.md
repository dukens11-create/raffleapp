# Offline Mode Guide

## Overview

Grate Genyen supports offline functionality to ensure users can access their tickets even without an internet connection.

## Features Available Offline

### ✅ Available Offline
- View purchased tickets
- View ticket details
- Access QR codes
- Browse cached ticket catalog
- View user profile

### ❌ Requires Internet
- Purchase new tickets
- Process payments
- Sync latest ticket data
- Upload photos
- Real-time updates

## Implementation

### Local Storage

We use multiple storage solutions:

#### 1. Shared Preferences
For simple key-value data:
```dart
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  Future<void> saveOfflineData(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  Future<String?> getOfflineData(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }
}
```

#### 2. Flutter Secure Storage
For sensitive data:
```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final storage = FlutterSecureStorage();

  Future<void> saveToken(String token) async {
    await storage.write(key: 'auth_token', value: token);
  }

  Future<String?> getToken() async {
    return await storage.read(key: 'auth_token');
  }
}
```

### Caching Strategy

#### API Response Caching
```dart
class CacheService {
  static const Duration cacheExpiry = Duration(hours: 24);
  
  Future<void> cacheApiResponse(String endpoint, dynamic data) async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    
    await prefs.setString('cache_$endpoint', jsonEncode(data));
    await prefs.setInt('cache_time_$endpoint', timestamp);
  }

  Future<dynamic> getCachedData(String endpoint) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString('cache_$endpoint');
    final cacheTime = prefs.getInt('cache_time_$endpoint');
    
    if (cachedData != null && cacheTime != null) {
      final age = DateTime.now().millisecondsSinceEpoch - cacheTime;
      if (age < cacheExpiry.inMilliseconds) {
        return jsonDecode(cachedData);
      }
    }
    return null;
  }
}
```

### Network Detection

```dart
import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkService {
  final Connectivity _connectivity = Connectivity();
  
  Stream<ConnectivityResult> get onConnectivityChanged =>
      _connectivity.onConnectivityChanged;
  
  Future<bool> isConnected() async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }
}
```

## Offline-First Architecture

### Data Sync Flow

```
User Action
    ↓
Check Network Status
    ↓
┌─────────────────┬─────────────────┐
│   Online        │   Offline       │
├─────────────────┼─────────────────┤
│ Save to Server  │ Save to Queue   │
│ Update Cache    │ Update Local    │
│ Return Success  │ Return Pending  │
└─────────────────┴─────────────────┘
    ↓
Network Restored
    ↓
Sync Queued Actions
    ↓
Update UI
```

### Sync Queue Implementation

```dart
class SyncQueue {
  static const String _queueKey = 'pending_actions';
  
  Future<void> addToQueue(Map<String, dynamic> action) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> queue = prefs.getStringList(_queueKey) ?? [];
    queue.add(jsonEncode(action));
    await prefs.setStringList(_queueKey, queue);
  }

  Future<void> processSyncQueue() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> queue = prefs.getStringList(_queueKey) ?? [];
    
    for (String actionJson in queue) {
      try {
        final action = jsonDecode(actionJson);
        await _executeAction(action);
      } catch (e) {
        print('Failed to sync action: $e');
      }
    }
    
    await prefs.remove(_queueKey);
  }
}
```

## User Experience

### Offline Indicator
```dart
class OfflineIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ConnectivityResult>(
      stream: NetworkService().onConnectivityChanged,
      builder: (context, snapshot) {
        if (snapshot.data == ConnectivityResult.none) {
          return Container(
            color: Colors.orange,
            padding: EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cloud_off, color: Colors.white),
                SizedBox(width: 8),
                Text('Offline Mode', style: TextStyle(color: Colors.white)),
              ],
            ),
          );
        }
        return SizedBox.shrink();
      },
    );
  }
}
```

### Offline Message
Show user-friendly messages:
```dart
if (!await NetworkService().isConnected()) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('This action requires an internet connection'),
      action: SnackBarAction(
        label: 'Retry',
        onPressed: () => _retryAction(),
      ),
    ),
  );
}
```

## Best Practices

1. **Cache Critical Data**: Always cache user's tickets and profile
2. **Queue Actions**: Store failed actions for later sync
3. **Clear Feedback**: Show users when offline
4. **Graceful Degradation**: Provide limited functionality offline
5. **Auto-Sync**: Automatically sync when connection restored
6. **Cache Invalidation**: Clear old cache data regularly

## Testing Offline Mode

### Manual Testing
1. Enable airplane mode
2. Open app
3. Verify cached data loads
4. Attempt online actions
5. Verify error messages
6. Disable airplane mode
7. Verify auto-sync

### Automated Testing
```dart
testWidgets('Loads cached data when offline', (tester) async {
  // Mock network service
  when(mockNetwork.isConnected()).thenAnswer((_) async => false);
  
  // Load app
  await tester.pumpWidget(MyApp());
  
  // Verify cached data displayed
  expect(find.text('Cached Ticket'), findsOneWidget);
});
```

## Troubleshooting

### Issue: Old data displayed
**Solution**: Implement cache expiry and force refresh option

### Issue: Sync conflicts
**Solution**: Implement conflict resolution strategy

### Issue: Large cache size
**Solution**: Implement cache size limits and cleanup
