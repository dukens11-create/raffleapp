import 'package:flutter/foundation.dart';
import 'package:raffle_app/services/api_service.dart';
import 'package:raffle_app/services/cache_service.dart';
import 'package:raffle_app/models/sync_task.dart';

class UserSync {
  static final UserSync _instance = UserSync._internal();
  factory UserSync() => _instance;
  UserSync._internal();

  final ApiService _apiService = ApiService();
  final CacheService _cacheService = CacheService();

  // Sync current user profile
  Future<void> syncCurrentUser() async {
    try {
      debugPrint('Syncing current user profile...');
      
      final response = await _apiService.get('/api/user/profile');

      if (response.statusCode == 200 && response.data != null) {
        await _cacheService.cacheCurrentUser(response.data);
        debugPrint('User profile synced successfully');
      }
    } catch (e) {
      debugPrint('Error syncing user profile: $e');
      rethrow;
    }
  }

  // Update user profile on server
  Future<void> updateProfile(Map<String, dynamic> userData) async {
    try {
      debugPrint('Updating user profile on server...');
      
      final response = await _apiService.put('/api/user/profile', userData);

      if (response.statusCode == 200 && response.data != null) {
        await _cacheService.cacheCurrentUser(response.data);
        debugPrint('User profile updated successfully');
      }
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      rethrow;
    }
  }

  // Sync pending user actions to server
  Future<void> syncToServer(List<SyncTask> tasks) async {
    for (var task in tasks) {
      try {
        await _syncTask(task);
      } catch (e) {
        debugPrint('Error syncing user task ${task.id}: $e');
        rethrow;
      }
    }
  }

  Future<void> _syncTask(SyncTask task) async {
    switch (task.action) {
      case SyncAction.update:
        await updateProfile(task.data);
        break;
      case SyncAction.create:
      case SyncAction.delete:
        debugPrint('User create/delete not supported in sync');
        break;
    }
  }

  // Get user by ID (from cache or server)
  Future<Map<String, dynamic>?> getUserById(int userId) async {
    try {
      // Try cache first
      final cachedUser = await _cacheService.getCachedUser(userId);
      if (cachedUser != null) {
        return cachedUser;
      }

      // Fetch from server
      final response = await _apiService.get('/api/users/$userId');
      if (response.statusCode == 200 && response.data != null) {
        await _cacheService.cacheUser(response.data);
        return response.data;
      }
    } catch (e) {
      debugPrint('Error getting user $userId: $e');
    }
    return null;
  }
}
