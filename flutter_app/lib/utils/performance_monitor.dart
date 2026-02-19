import 'package:flutter/foundation.dart';
import 'dart:async';

/// Performance monitoring service to track app performance metrics
class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  factory PerformanceMonitor() => _instance;
  PerformanceMonitor._internal();

  final Map<String, Stopwatch> _operations = {};
  final Map<String, List<int>> _metrics = {};

  /// Start monitoring an operation
  void startOperation(String operationName) {
    final stopwatch = Stopwatch()..start();
    _operations[operationName] = stopwatch;
  }

  /// End monitoring an operation and record the duration
  void endOperation(String operationName) {
    final stopwatch = _operations[operationName];
    if (stopwatch != null) {
      stopwatch.stop();
      final duration = stopwatch.elapsedMilliseconds;
      
      // Store metric
      if (!_metrics.containsKey(operationName)) {
        _metrics[operationName] = [];
      }
      _metrics[operationName]!.add(duration);
      
      // Log slow operations in debug mode
      if (kDebugMode && duration > 1000) {
        debugPrint('⚠️ Slow operation: $operationName took ${duration}ms');
      }
      
      _operations.remove(operationName);
    }
  }

  /// Measure the execution time of a function
  Future<T> measureAsync<T>(String operationName, Future<T> Function() operation) async {
    startOperation(operationName);
    try {
      final result = await operation();
      endOperation(operationName);
      return result;
    } catch (e) {
      endOperation(operationName);
      rethrow;
    }
  }

  /// Measure synchronous operation
  T measure<T>(String operationName, T Function() operation) {
    startOperation(operationName);
    try {
      final result = operation();
      endOperation(operationName);
      return result;
    } catch (e) {
      endOperation(operationName);
      rethrow;
    }
  }

  /// Get average duration for an operation
  double? getAverageDuration(String operationName) {
    final metrics = _metrics[operationName];
    if (metrics == null || metrics.isEmpty) return null;
    
    final sum = metrics.reduce((a, b) => a + b);
    return sum / metrics.length;
  }

  /// Get metrics report
  Map<String, dynamic> getMetricsReport() {
    final report = <String, dynamic>{};
    
    _metrics.forEach((operation, durations) {
      if (durations.isNotEmpty) {
        final avg = durations.reduce((a, b) => a + b) / durations.length;
        final max = durations.reduce((a, b) => a > b ? a : b);
        final min = durations.reduce((a, b) => a < b ? a : b);
        
        report[operation] = {
          'count': durations.length,
          'average': avg.toStringAsFixed(2),
          'max': max,
          'min': min,
        };
      }
    });
    
    return report;
  }

  /// Clear all metrics
  void clearMetrics() {
    _metrics.clear();
    _operations.clear();
  }

  /// Log metrics report
  void logMetricsReport() {
    if (kDebugMode) {
      final report = getMetricsReport();
      debugPrint('📊 Performance Metrics Report:');
      report.forEach((operation, metrics) {
        debugPrint('  $operation: $metrics');
      });
    }
  }

  /// Check if frame budget is exceeded (16ms for 60fps)
  bool isFrameBudgetExceeded(String operationName) {
    final metrics = _metrics[operationName];
    if (metrics == null || metrics.isEmpty) return false;
    
    final latestDuration = metrics.last;
    return latestDuration > 16; // 60fps threshold
  }

  /// Monitor widget build performance
  void monitorWidgetBuild(String widgetName, VoidCallback buildFunction) {
    startOperation('build_$widgetName');
    buildFunction();
    endOperation('build_$widgetName');
  }

  /// Track memory usage (simplified)
  void trackMemoryWarning() {
    if (kDebugMode) {
      debugPrint('⚠️ Memory warning received');
    }
  }
}

/// Extension for easy performance monitoring
extension PerformanceMonitorExtension on Future<dynamic> {
  Future<T> withPerformanceMonitoring<T>(String operationName) async {
    return await PerformanceMonitor().measureAsync(operationName, () => this as Future<T>);
  }
}
