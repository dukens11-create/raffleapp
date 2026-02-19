# Quick Start Guide - Phase 3 Features

## For End Users

### Offline Mode
**What happens when you go offline?**
1. A yellow banner appears at the top: "No Internet Connection"
2. You can still view your previously loaded tickets
3. Any purchases or actions will be queued
4. When online, your actions sync automatically

**How to check sync status:**
- Look for the sync icon in the app bar
- 🔵 Syncing... - Currently syncing data
- 🟠 Pending sync - Actions waiting to sync
- 🟢 Synced - Everything is up to date
- ⚫ Offline - No internet connection

### Notifications
**Accessing notifications:**
1. Tap the notification bell icon (if added to app bar)
2. Or navigate to: Menu → Notifications
3. See all your notifications with unread count badge

**Managing notifications:**
- Tap a notification to mark it as read
- Use "Mark all as read" button to clear all
- Go to Settings to customize which notifications you receive

**Notification Types You'll Receive:**
- **Buyers:**
  - 🎫 Ticket purchase confirmation
  - 💰 Payment received
  - 📅 Raffle scheduled
  - 🎉 Winner announcement
  - 🏆 Prize claim reminder

- **Sellers:**
  - 🎫 Ticket assignment
  - 💵 Sale recorded
  - 💰 Commission earned
  - ⭐ Performance milestone

- **Admins:**
  - 👤 New seller registration
  - 💳 Large transaction alert
  - ⚠️ System alerts
  - 📊 Daily summary

## For Developers

### Adding Offline Banner to Screens
```dart
import 'package:raffle_app/widgets/offline_banner.dart';

@override
Widget build(BuildContext context) {
  return Scaffold(
    body: Column(
      children: [
        const OfflineBanner(), // Add this at the top
        // Your screen content
        Expanded(
          child: YourContent(),
        ),
      ],
    ),
  );
}
```

### Showing Sync Status
```dart
import 'package:raffle_app/widgets/offline_banner.dart';

// In AppBar or anywhere else:
AppBar(
  title: Text('My Screen'),
  actions: [
    SyncStatusIndicator(showLabel: true), // Shows sync status with label
    // or
    SyncStatusIndicator(), // Just icon
  ],
)
```

### Accessing Cached Data
```dart
import 'package:raffle_app/services/cache_service.dart';

final cacheService = CacheService();

// Get cached tickets
final tickets = await cacheService.getCachedTickets(
  buyerId: currentUserId,
  status: 'purchased',
);

// Get cached user
final user = await cacheService.getCachedUser(userId);

// Check last sync time
final lastSync = await cacheService.getLastSyncTime('tickets');
```

### Triggering Manual Sync
```dart
import 'package:provider/provider.dart';
import 'package:raffle_app/providers/offline_provider.dart';

// In your widget:
final offlineProvider = context.read<OfflineProvider>();
await offlineProvider.triggerSync();
```

### Queuing Offline Actions
```dart
import 'package:provider/provider.dart';
import 'package:raffle_app/providers/offline_provider.dart';

// When performing an action offline:
await offlineProvider.queueOfflineAction(
  action: 'create',
  entityType: 'ticket',
  entityId: ticketId,
  data: ticketData,
);
```

### Sending Notifications (Backend)
```javascript
// In your backend code:
const admin = require('firebase-admin');

async function notifyTicketPurchase(userId, ticketData) {
  // Get user's FCM token
  const token = await getUserFCMToken(userId);
  
  // Send notification
  const message = {
    token: token,
    notification: {
      title: 'Ticket Purchase Confirmed',
      body: `Your ticket ${ticketData.barcode} has been purchased`,
    },
    data: {
      type: 'ticket_purchase',
      ticket_id: ticketData.id.toString(),
      barcode: ticketData.barcode,
    },
  };
  
  await admin.messaging().send(message);
  
  // Also save to database for notification history
  await saveNotificationToDatabase({
    user_id: userId,
    type: 'ticket_purchase',
    title: 'Ticket Purchase Confirmed',
    body: `Your ticket ${ticketData.barcode} has been purchased`,
    data: { ticket_id: ticketData.id, barcode: ticketData.barcode },
  });
}
```

### Accessing Debug Screen
```dart
// In development builds only:
Navigator.pushNamed(context, '/debug/sync');

// Or add to your debug menu:
ListTile(
  title: Text('Sync Debug'),
  leading: Icon(Icons.bug_report),
  onTap: () => Navigator.pushNamed(context, '/debug/sync'),
)
```

## For Backend Developers

### Implementing Sync Endpoint
```javascript
// POST /api/sync/tickets
app.post('/api/sync/tickets', authenticateToken, async (req, res) => {
  try {
    const { tickets } = req.body;
    const synced = [];
    const conflicts = [];

    for (const ticket of tickets) {
      // Check for conflicts
      const existing = await db.query(
        'SELECT * FROM tickets WHERE barcode = $1',
        [ticket.barcode]
      );

      if (existing.rows.length > 0) {
        conflicts.push({
          barcode: ticket.barcode,
          reason: 'Already exists',
          existing: existing.rows[0],
        });
        continue;
      }

      // Insert ticket
      const result = await db.query(
        `INSERT INTO tickets (barcode, category, price, status, seller_id, created_at)
         VALUES ($1, $2, $3, $4, $5, $6) RETURNING *`,
        [ticket.barcode, ticket.category, ticket.price, ticket.status,
         ticket.seller_id, ticket.created_at]
      );

      synced.push(result.rows[0]);
    }

    res.json({
      success: true,
      synced: synced.length,
      conflicts: conflicts,
      tickets: synced,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: { message: 'Sync failed', details: error.message },
    });
  }
});
```

### Registering FCM Token
```javascript
// POST /api/fcm/register
app.post('/api/fcm/register', authenticateToken, async (req, res) => {
  const { token, platform } = req.body;
  const userId = req.user.id;

  // Save to database
  await db.query(
    `INSERT INTO fcm_tokens (user_id, token, platform, active)
     VALUES ($1, $2, $3, true)
     ON CONFLICT (token) DO UPDATE SET 
       user_id = $1, platform = $2, active = true, updated_at = NOW()`,
    [userId, token, platform]
  );

  // Subscribe to role-based topics
  await admin.messaging().subscribeToTopic(token, req.user.role);
  await admin.messaging().subscribeToTopic(token, 'all_users');

  res.json({ success: true, message: 'Token registered' });
});
```

## Testing Guide

### Test Offline Mode
1. **Enable Airplane Mode** on your device
2. **Open the app** - should show cached data
3. **Try to view tickets** - should load from cache
4. **Attempt a purchase** - should queue for later
5. **Disable Airplane Mode** - sync should happen automatically
6. **Check Debug screen** to verify sync

### Test Notifications
1. **In Firebase Console:**
   - Go to Cloud Messaging
   - Click "Send test message"
   - Enter your FCM token (from app logs)
   - Send message

2. **Test Different States:**
   - App in foreground - should show local notification
   - App in background - should receive push
   - App terminated - should receive push
   - Tap notification - should open app

3. **Test Notification History:**
   - Send multiple notifications
   - Open notification list
   - Mark some as read
   - Test "Mark all as read"

### Test Background Sync
1. **Create offline actions** (queue some changes)
2. **Close the app completely**
3. **Wait 15+ minutes**
4. **Open Debug screen** - check if sync happened
5. **Verify data** is synced to server

## Troubleshooting

### Issue: Offline banner not showing
**Solution:**
- Ensure OfflineProvider is initialized in main.dart
- Check that OfflineBanner widget is added to screen
- Verify connectivity_plus package is working

### Issue: Sync not happening
**Solution:**
1. Open Debug screen (`/debug/sync`)
2. Check connection status
3. View sync logs for errors
4. Try manual sync
5. Check backend endpoints are working

### Issue: Notifications not received
**Solution:**
1. Check FCM token is generated (app logs)
2. Verify google-services.json / GoogleService-Info.plist exist
3. Ensure notification permissions granted
4. Test with Firebase Console "Send test message"
5. Check backend is calling FCM API correctly

### Issue: Database errors
**Solution:**
1. Clear app data
2. Reinstall app
3. Check logs for migration errors
4. Verify database version in database_service.dart

## Best Practices

### For Mobile Developers
1. ✅ Always add OfflineBanner to main screens
2. ✅ Show sync status in navigation
3. ✅ Handle offline state gracefully
4. ✅ Queue actions when offline
5. ✅ Test with airplane mode frequently

### For Backend Developers
1. ✅ Implement all sync endpoints
2. ✅ Handle conflicts gracefully
3. ✅ Send notifications for important events
4. ✅ Store notifications in database
5. ✅ Monitor FCM delivery rates

### For QA/Testers
1. ✅ Test offline mode thoroughly
2. ✅ Verify sync after connection restore
3. ✅ Test notification delivery
4. ✅ Check all notification types
5. ✅ Monitor database performance

## Resources

- **Full Documentation:** `flutter_app/PHASE3_IMPLEMENTATION.md`
- **Firebase Setup:** `flutter_app/FIREBASE_SETUP.md`
- **Backend API:** `flutter_app/BACKEND_API_GUIDE.md`
- **Summary:** `PHASE3_SUMMARY.md`

## Support

Need help? Check:
1. Debug screen for sync status
2. App logs for errors
3. Documentation files
4. Firebase Console for notification delivery

---

**Quick Navigation:**
- [Firebase Setup](flutter_app/FIREBASE_SETUP.md)
- [Backend API Guide](flutter_app/BACKEND_API_GUIDE.md)
- [Implementation Details](flutter_app/PHASE3_IMPLEMENTATION.md)
