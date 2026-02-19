import 'dart:convert';

enum NotificationType {
  ticketPurchase,
  paymentReceived,
  raffleScheduled,
  winnerAnnouncement,
  prizeClaimReminder,
  ticketAssignment,
  saleRecorded,
  commissionEarned,
  performanceMilestone,
  sellerRegistration,
  largeTransaction,
  systemAlert,
  dailySummary,
}

class NotificationModel {
  final int? id;
  final String title;
  final String body;
  final NotificationType type;
  final Map<String, dynamic>? data;
  final bool read;
  final DateTime createdAt;

  NotificationModel({
    this.id,
    required this.title,
    required this.body,
    required this.type,
    this.data,
    this.read = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'] as int?,
      title: map['title'] as String,
      body: map['body'] as String,
      type: _parseType(map['type'] as String),
      data: map['data'] != null 
          ? (map['data'] is String 
              ? jsonDecode(map['data'] as String) 
              : map['data'] as Map<String, dynamic>)
          : null,
      read: (map['read'] as int? ?? 0) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'body': body,
      'type': type.name,
      'data': data != null ? jsonEncode(data) : null,
      'read': read ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as int?,
      title: json['title'] as String,
      body: json['body'] as String,
      type: _parseType(json['type'] as String),
      data: json['data'] as Map<String, dynamic>?,
      read: json['read'] == true || json['read'] == 1,
      createdAt: json['created_at'] is String
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'body': body,
      'type': type.name,
      'data': data,
      'read': read,
      'created_at': createdAt.toIso8601String(),
    };
  }

  static NotificationType _parseType(String type) {
    switch (type.toLowerCase()) {
      case 'ticketpurchase':
      case 'ticket_purchase':
        return NotificationType.ticketPurchase;
      case 'paymentreceived':
      case 'payment_received':
        return NotificationType.paymentReceived;
      case 'rafflescheduled':
      case 'raffle_scheduled':
        return NotificationType.raffleScheduled;
      case 'winnerannouncement':
      case 'winner_announcement':
        return NotificationType.winnerAnnouncement;
      case 'prizeclaimreminder':
      case 'prize_claim_reminder':
        return NotificationType.prizeClaimReminder;
      case 'ticketassignment':
      case 'ticket_assignment':
        return NotificationType.ticketAssignment;
      case 'salerecorded':
      case 'sale_recorded':
        return NotificationType.saleRecorded;
      case 'commissionearned':
      case 'commission_earned':
        return NotificationType.commissionEarned;
      case 'performancemilestone':
      case 'performance_milestone':
        return NotificationType.performanceMilestone;
      case 'sellerregistration':
      case 'seller_registration':
        return NotificationType.sellerRegistration;
      case 'largetransaction':
      case 'large_transaction':
        return NotificationType.largeTransaction;
      case 'systemalert':
      case 'system_alert':
        return NotificationType.systemAlert;
      case 'dailysummary':
      case 'daily_summary':
        return NotificationType.dailySummary;
      default:
        return NotificationType.systemAlert;
    }
  }

  NotificationModel copyWith({
    int? id,
    String? title,
    String? body,
    NotificationType? type,
    Map<String, dynamic>? data,
    bool? read,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      data: data ?? this.data,
      read: read ?? this.read,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'NotificationModel(id: $id, title: $title, type: ${type.name}, read: $read)';
  }

  String getIcon() {
    switch (type) {
      case NotificationType.ticketPurchase:
      case NotificationType.ticketAssignment:
        return '🎫';
      case NotificationType.paymentReceived:
      case NotificationType.commissionEarned:
        return '💰';
      case NotificationType.raffleScheduled:
        return '📅';
      case NotificationType.winnerAnnouncement:
        return '🎉';
      case NotificationType.prizeClaimReminder:
        return '🏆';
      case NotificationType.saleRecorded:
        return '💵';
      case NotificationType.performanceMilestone:
        return '⭐';
      case NotificationType.sellerRegistration:
        return '👤';
      case NotificationType.largeTransaction:
        return '💳';
      case NotificationType.systemAlert:
        return '⚠️';
      case NotificationType.dailySummary:
        return '📊';
    }
  }
}
