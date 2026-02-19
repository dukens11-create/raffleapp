import 'package:flutter/foundation.dart';

enum LogLevel {
  debug,
  info,
  warning,
  error,
}

class SyncLogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String message;
  final String? operation;
  final Map<String, dynamic>? metadata;

  SyncLogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
    this.operation,
    this.metadata,
  });

  @override
  String toString() {
    final levelStr = level.name.toUpperCase();
    final timeStr = timestamp.toIso8601String();
    final operationStr = operation != null ? '[$operation]' : '';
    final metadataStr = metadata != null ? ' - ${metadata.toString()}' : '';
    return '$timeStr [$levelStr] $operationStr $message$metadataStr';
  }
}

class SyncLogger {
  static final SyncLogger _instance = SyncLogger._internal();
  factory SyncLogger() => _instance;
  SyncLogger._internal();

  final List<SyncLogEntry> _logs = [];
  static const int _maxLogs = 1000;

  // Log methods
  void debug(String message, {String? operation, Map<String, dynamic>? metadata}) {
    _log(LogLevel.debug, message, operation: operation, metadata: metadata);
  }

  void info(String message, {String? operation, Map<String, dynamic>? metadata}) {
    _log(LogLevel.info, message, operation: operation, metadata: metadata);
  }

  void warning(String message, {String? operation, Map<String, dynamic>? metadata}) {
    _log(LogLevel.warning, message, operation: operation, metadata: metadata);
  }

  void error(String message, {String? operation, Map<String, dynamic>? metadata}) {
    _log(LogLevel.error, message, operation: operation, metadata: metadata);
  }

  void _log(
    LogLevel level,
    String message, {
    String? operation,
    Map<String, dynamic>? metadata,
  }) {
    final entry = SyncLogEntry(
      timestamp: DateTime.now(),
      level: level,
      message: message,
      operation: operation,
      metadata: metadata,
    );

    _logs.add(entry);

    // Keep only the most recent logs
    if (_logs.length > _maxLogs) {
      _logs.removeAt(0);
    }

    // Print to console in debug mode
    if (kDebugMode) {
      debugPrint(entry.toString());
    }
  }

  // Get logs
  List<SyncLogEntry> getLogs({
    LogLevel? minLevel,
    String? operation,
    DateTime? since,
  }) {
    var filtered = _logs;

    if (minLevel != null) {
      filtered = filtered.where((log) => log.level.index >= minLevel.index).toList();
    }

    if (operation != null) {
      filtered = filtered.where((log) => log.operation == operation).toList();
    }

    if (since != null) {
      filtered = filtered.where((log) => log.timestamp.isAfter(since)).toList();
    }

    return filtered;
  }

  // Get error logs
  List<SyncLogEntry> getErrors() {
    return _logs.where((log) => log.level == LogLevel.error).toList();
  }

  // Get recent logs
  List<SyncLogEntry> getRecentLogs(int count) {
    final startIndex = _logs.length - count;
    return _logs.sublist(startIndex.clamp(0, _logs.length));
  }

  // Clear logs
  void clearLogs() {
    _logs.clear();
    info('Logs cleared');
  }

  // Get statistics
  Map<String, int> getStatistics() {
    final stats = <String, int>{
      'total': _logs.length,
      'debug': 0,
      'info': 0,
      'warning': 0,
      'error': 0,
    };

    for (var log in _logs) {
      stats[log.level.name] = (stats[log.level.name] ?? 0) + 1;
    }

    return stats;
  }

  // Export logs as string
  String exportLogs() {
    final buffer = StringBuffer();
    buffer.writeln('=== Sync Logs Export ===');
    buffer.writeln('Generated: ${DateTime.now().toIso8601String()}');
    buffer.writeln('Total entries: ${_logs.length}');
    buffer.writeln('');

    for (var log in _logs) {
      buffer.writeln(log.toString());
    }

    return buffer.toString();
  }

  // Log sync operation lifecycle
  void logSyncStart(String operation, {Map<String, dynamic>? metadata}) {
    info('Sync started', operation: operation, metadata: metadata);
  }

  void logSyncSuccess(String operation, {Map<String, dynamic>? metadata}) {
    info('Sync completed successfully', operation: operation, metadata: metadata);
  }

  void logSyncError(String operation, dynamic error, {Map<String, dynamic>? metadata}) {
    error(
      'Sync failed: $error',
      operation: operation,
      metadata: metadata,
    );
  }

  void logSyncProgress(String operation, String progress, {Map<String, dynamic>? metadata}) {
    debug(progress, operation: operation, metadata: metadata);
  }
}
