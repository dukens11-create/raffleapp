import 'package:flutter/material.dart';
import 'package:raffle_app/models/notification.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  // Notification preferences
  final Map<NotificationType, bool> _notificationEnabled = {
    NotificationType.ticketPurchase: true,
    NotificationType.paymentReceived: true,
    NotificationType.raffleScheduled: true,
    NotificationType.winnerAnnouncement: true,
    NotificationType.prizeClaimReminder: true,
    NotificationType.ticketAssignment: true,
    NotificationType.saleRecorded: true,
    NotificationType.commissionEarned: true,
    NotificationType.performanceMilestone: true,
    NotificationType.sellerRegistration: true,
    NotificationType.largeTransaction: true,
    NotificationType.systemAlert: true,
    NotificationType.dailySummary: true,
  };

  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _badgeEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
      ),
      body: ListView(
        children: [
          // General Settings
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'General',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SwitchListTile(
            title: const Text('Sound'),
            subtitle: const Text('Play sound for notifications'),
            value: _soundEnabled,
            onChanged: (value) {
              setState(() {
                _soundEnabled = value;
              });
            },
          ),
          SwitchListTile(
            title: const Text('Vibration'),
            subtitle: const Text('Vibrate on notification'),
            value: _vibrationEnabled,
            onChanged: (value) {
              setState(() {
                _vibrationEnabled = value;
              });
            },
          ),
          SwitchListTile(
            title: const Text('Badge'),
            subtitle: const Text('Show badge count on app icon'),
            value: _badgeEnabled,
            onChanged: (value) {
              setState(() {
                _badgeEnabled = value;
              });
            },
          ),

          const Divider(),

          // Notification Types
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Notification Types',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          _buildNotificationTypeTile(
            'Ticket Purchase',
            'Get notified when you purchase a ticket',
            NotificationType.ticketPurchase,
          ),
          _buildNotificationTypeTile(
            'Payment Received',
            'Get notified when payment is confirmed',
            NotificationType.paymentReceived,
          ),
          _buildNotificationTypeTile(
            'Raffle Scheduled',
            'Get notified about upcoming raffles',
            NotificationType.raffleScheduled,
          ),
          _buildNotificationTypeTile(
            'Winner Announcement',
            'Get notified about raffle winners',
            NotificationType.winnerAnnouncement,
          ),
          _buildNotificationTypeTile(
            'Prize Claim Reminder',
            'Reminders to claim your prize',
            NotificationType.prizeClaimReminder,
          ),
          _buildNotificationTypeTile(
            'Ticket Assignment',
            'Get notified when tickets are assigned (Sellers)',
            NotificationType.ticketAssignment,
          ),
          _buildNotificationTypeTile(
            'Sale Recorded',
            'Get notified when a sale is recorded (Sellers)',
            NotificationType.saleRecorded,
          ),
          _buildNotificationTypeTile(
            'Commission Earned',
            'Get notified about commissions (Sellers)',
            NotificationType.commissionEarned,
          ),
          _buildNotificationTypeTile(
            'Performance Milestone',
            'Get notified about milestones (Sellers)',
            NotificationType.performanceMilestone,
          ),
          _buildNotificationTypeTile(
            'Seller Registration',
            'Get notified about new sellers (Admins)',
            NotificationType.sellerRegistration,
          ),
          _buildNotificationTypeTile(
            'Large Transaction',
            'Get notified about large transactions (Admins)',
            NotificationType.largeTransaction,
          ),
          _buildNotificationTypeTile(
            'System Alerts',
            'Important system notifications',
            NotificationType.systemAlert,
          ),
          _buildNotificationTypeTile(
            'Daily Summary',
            'Daily summary of activities',
            NotificationType.dailySummary,
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildNotificationTypeTile(
    String title,
    String subtitle,
    NotificationType type,
  ) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      value: _notificationEnabled[type] ?? true,
      onChanged: (value) {
        setState(() {
          _notificationEnabled[type] = value;
        });
      },
    );
  }
}
