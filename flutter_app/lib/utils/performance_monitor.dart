import 'package:flutter/foundation.dart';

/// Performance monitoring utility
/// 
/// Tracks app performance metrics and identifies bottlenecks
class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  factory PerformanceMonitor() => _instance;
  PerformanceMonitor._internal();

  final Map<String, DateTime> _startTimes = {};
  final Map<String, List<int>> _metrics = {};

  /// Start tracking an operation
  void startTracking(String operationName) {
    _startTimes[operationName] = DateTime.now();
    
    if (kDebugMode) {
      debugPrint('⏱️ Started tracking: $operationName');
    }
  }

  /// Stop tracking and record the duration
  void stopTracking(String operationName) {
    final startTime = _startTimes[operationName];
    if (startTime == null) {
      if (kDebugMode) {
        debugPrint('⚠️ No start time found for: $operationName');
      }
      return;
    }

    final duration = DateTime.now().difference(startTime).inMilliseconds;
    _startTimes.remove(operationName);

    // Store metric
    _metrics.putIfAbsent(operationName, () => []);
    _metrics[operationName]!.add(duration);

    if (kDebugMode) {
      debugPrint('⏱️ $operationName completed in ${duration}ms');
      
      // Warn if operation is slow
      if (duration > 1000) {
        debugPrint('⚠️ SLOW OPERATION: $operationName took ${duration}ms');
      }
    }
  }

  /// Track an async operation
  Future<T> trackAsync<T>(
    String operationName,
    Future<T> Function() operation,
  ) async {
    startTracking(operationName);
    try {
      final result = await operation();
      stopTracking(operationName);
      return result;
    } catch (e) {
      stopTracking(operationName);
      rethrow;
    }
  }

  /// Get average duration for an operation
  double getAverageDuration(String operationName) {
    final metrics = _metrics[operationName];
    if (metrics == null || metrics.isEmpty) {
      return 0;
    }

    final sum = metrics.reduce((a, b) => a + b);
    return sum / metrics.length;
  }

  /// Get performance summary
  Map<String, dynamic> getSummary() {
    final summary = <String, dynamic>{};

    for (final entry in _metrics.entries) {
      final operationName = entry.key;
      final durations = entry.value;

      if (durations.isEmpty) continue;

      final avg = durations.reduce((a, b) => a + b) / durations.length;
      final min = durations.reduce((a, b) => a < b ? a : b);
      final max = durations.reduce((a, b) => a > b ? a : b);

      summary[operationName] = {
        'count': durations.length,
        'average': '${avg.toStringAsFixed(2)}ms',
        'min': '${min}ms',
        'max': '${max}ms',
      };
    }

    return summary;
  }

  /// Print performance summary
  void printSummary() {
    if (!kDebugMode) return;

    debugPrint('=== PERFORMANCE SUMMARY ===');
    final summary = getSummary();
    
    for (final entry in summary.entries) {
      final name = entry.key;
      final stats = entry.value as Map<String, dynamic>;
      
      debugPrint('$name:');
      debugPrint('  Count: ${stats['count']}');
      debugPrint('  Average: ${stats['average']}');
      debugPrint('  Min: ${stats['min']}');
      debugPrint('  Max: ${stats['max']}');
    }
    debugPrint('===========================');
  }

  /// Clear all metrics
  void clearMetrics() {
    _startTimes.clear();
    _metrics.clear();
    
    if (kDebugMode) {
      debugPrint('Performance metrics cleared');
    }
  }

  /// Check if an operation exceeds target time
  bool isOperationSlow(String operationName, int targetMs) {
    final avg = getAverageDuration(operationName);
    return avg > targetMs;
  }

  /// Get slow operations (over 1 second average)
  List<String> getSlowOperations() {
    final slowOps = <String>[];
    
    for (final entry in _metrics.entries) {
      if (getAverageDuration(entry.key) > 1000) {
        slowOps.add(entry.key);
      }
    }
    
    return slowOps;
  }
}

/// Performance metrics targets
class PerformanceTargets {
  /// Frame render time target (16.67ms = 60 FPS)
  static const int frameRenderTimeMs = 16;

  /// API call target
  static const int apiCallMs = 2000;

  /// Screen load target
  static const int screenLoadMs = 1000;

  /// Image load target
  static const int imageLoadMs = 500;

  /// Database query target
  static const int databaseQueryMs = 100;
}
