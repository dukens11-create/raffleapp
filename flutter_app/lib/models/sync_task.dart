import 'dart:convert';

enum SyncAction {
  create,
  update,
  delete,
}

enum SyncEntityType {
  ticket,
  payment,
  user,
  notification,
}

class SyncTask {
  final int? id;
  final SyncAction action;
  final SyncEntityType entityType;
  final int entityId;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final int retryCount;

  SyncTask({
    this.id,
    required this.action,
    required this.entityType,
    required this.entityId,
    required this.data,
    DateTime? createdAt,
    this.retryCount = 0,
  }) : createdAt = createdAt ?? DateTime.now();

  factory SyncTask.fromMap(Map<String, dynamic> map) {
    return SyncTask(
      id: map['id'] as int?,
      action: _parseAction(map['action'] as String),
      entityType: _parseEntityType(map['entity_type'] as String),
      entityId: map['entity_id'] as int,
      data: jsonDecode(map['data'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      retryCount: map['retry_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'action': action.name,
      'entity_type': entityType.name,
      'entity_id': entityId,
      'data': jsonEncode(data),
      'created_at': createdAt.toIso8601String(),
      'retry_count': retryCount,
    };
  }

  static SyncAction _parseAction(String action) {
    switch (action.toLowerCase()) {
      case 'create':
        return SyncAction.create;
      case 'update':
        return SyncAction.update;
      case 'delete':
        return SyncAction.delete;
      default:
        throw ArgumentError('Unknown action: $action');
    }
  }

  static SyncEntityType _parseEntityType(String entityType) {
    switch (entityType.toLowerCase()) {
      case 'ticket':
        return SyncEntityType.ticket;
      case 'payment':
        return SyncEntityType.payment;
      case 'user':
        return SyncEntityType.user;
      case 'notification':
        return SyncEntityType.notification;
      default:
        throw ArgumentError('Unknown entity type: $entityType');
    }
  }

  SyncTask copyWith({
    int? id,
    SyncAction? action,
    SyncEntityType? entityType,
    int? entityId,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    int? retryCount,
  }) {
    return SyncTask(
      id: id ?? this.id,
      action: action ?? this.action,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      retryCount: retryCount ?? this.retryCount,
    );
  }

  @override
  String toString() {
    return 'SyncTask(id: $id, action: ${action.name}, '
        'entityType: ${entityType.name}, entityId: $entityId, '
        'retryCount: $retryCount)';
  }
}
