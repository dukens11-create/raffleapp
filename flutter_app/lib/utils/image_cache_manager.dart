import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';

/// Image cache manager for optimized image loading
/// 
/// Handles image caching, compression, and optimization
class ImageCacheManager {
  static final ImageCacheManager _instance = ImageCacheManager._internal();
  factory ImageCacheManager() => _instance;
  ImageCacheManager._internal();

  /// Maximum cache size in MB
  static const int maxCacheSizeMB = 100;
  
  /// Maximum cache age in days
  static const int maxCacheAgeDays = 30;

  /// Get optimized image URL with resize parameters
  /// This assumes backend supports image resizing via query parameters
  String getOptimizedImageUrl(
    String originalUrl, {
    int? width,
    int? height,
    int quality = 85,
  }) {
    // If it's a local asset, return as-is
    if (originalUrl.startsWith('assets/')) {
      return originalUrl;
    }

    // For network images, add optimization parameters if backend supports it
    final uri = Uri.parse(originalUrl);
    final queryParams = Map<String, String>.from(uri.queryParameters);

    if (width != null) {
      queryParams['w'] = width.toString();
    }
    if (height != null) {
      queryParams['h'] = height.toString();
    }
    queryParams['q'] = quality.toString();

    return uri.replace(queryParameters: queryParams).toString();
  }

  /// Clear image cache
  Future<void> clearCache() async {
    try {
      await CachedNetworkImage.evictFromCache('');
      if (kDebugMode) {
        debugPrint('Image cache cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error clearing image cache: $e');
      }
    }
  }

  /// Pre-cache important images
  Future<void> precacheImages(List<String> urls) async {
    // TODO: Implement image precaching
    // This would download and cache images in the background
    if (kDebugMode) {
      debugPrint('Precaching ${urls.length} images');
    }
  }

  /// Get cache size
  Future<int> getCacheSizeInBytes() async {
    // TODO: Implement cache size calculation
    return 0;
  }

  /// Check if cache needs cleanup
  Future<bool> needsCacheCleanup() async {
    final cacheSizeBytes = await getCacheSizeInBytes();
    final cacheSizeMB = cacheSizeBytes / (1024 * 1024);
    return cacheSizeMB > maxCacheSizeMB;
  }

  /// Perform cache cleanup
  Future<void> performCacheCleanup() async {
    final needsCleanup = await needsCacheCleanup();
    if (needsCleanup) {
      await clearCache();
      if (kDebugMode) {
        debugPrint('Cache cleanup performed');
      }
    }
  }
}

/// Image loading strategies
enum ImageLoadingStrategy {
  /// Load immediately
  immediate,
  
  /// Load when widget becomes visible
  lazy,
  
  /// Preload in background
  preload,
}

/// Image quality presets
enum ImageQuality {
  low(quality: 60, maxWidth: 400),
  medium(quality: 75, maxWidth: 800),
  high(quality: 85, maxWidth: 1200),
  original(quality: 100, maxWidth: null);

  const ImageQuality({
    required this.quality,
    required this.maxWidth,
  });

  final int quality;
  final int? maxWidth;
}
