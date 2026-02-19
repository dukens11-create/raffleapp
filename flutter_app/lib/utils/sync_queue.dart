import 'package:raffle_app/models/sync_task.dart';
import 'package:raffle_app/services/cache_service.dart';

class SyncQueue {
  static final SyncQueue _instance = SyncQueue._internal();
  factory SyncQueue() => _instance;
  SyncQueue._internal();

  final CacheService _cacheService = CacheService();
  
  static const int maxRetries = 3;

  // Add task to sync queue
  Future<void> addTask(SyncTask task) async {
    await _cacheService.queueOfflineAction(
      action: task.action.name,
      entityType: task.entityType.name,
      entityId: task.entityId,
      data: task.data,
    );
  }

  // Get all pending tasks
  Future<List<SyncTask>> getPendingTasks() async {
    final queueItems = await _cacheService.getPendingSyncActions();
    return queueItems.map((item) => SyncTask.fromMap(item)).toList();
  }

  // Get tasks by entity type
  Future<List<SyncTask>> getTasksByType(SyncEntityType entityType) async {
    final allTasks = await getPendingTasks();
    return allTasks.where((task) => task.entityType == entityType).toList();
  }

  // Remove completed task
  Future<void> removeTask(int taskId) async {
    await _cacheService.removeSyncedAction(taskId);
  }

  // Increment retry count
  Future<void> incrementRetryCount(SyncTask task) async {
    if (task.id != null) {
      await _cacheService.incrementRetryCount(task.id!, task.retryCount);
    }
  }

  // Check if task should be retried
  bool shouldRetry(SyncTask task) {
    return task.retryCount < maxRetries;
  }

  // Remove tasks that exceeded max retries
  Future<void> removeExpiredTasks() async {
    final tasks = await getPendingTasks();
    for (var task in tasks) {
      if (task.retryCount >= maxRetries && task.id != null) {
        await removeTask(task.id!);
      }
    }
  }

  // Get queue size
  Future<int> getQueueSize() async {
    final tasks = await getPendingTasks();
    return tasks.length;
  }

  // Clear entire queue (use with caution)
  Future<void> clearQueue() async {
    final tasks = await getPendingTasks();
    for (var task in tasks) {
      if (task.id != null) {
        await removeTask(task.id!);
      }
    }
  }

  // Get tasks sorted by priority (oldest first)
  Future<List<SyncTask>> getTasksByPriority() async {
    final tasks = await getPendingTasks();
    tasks.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return tasks;
  }

  // Check if specific entity has pending sync
  Future<bool> hasEntityPendingSync(
    SyncEntityType entityType,
    int entityId,
  ) async {
    final tasks = await getTasksByType(entityType);
    return tasks.any((task) => task.entityId == entityId);
  }
}
