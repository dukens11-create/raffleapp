/// Performance and optimization configuration
class OptimizationConfig {
  // Image optimization
  static const int maxImageWidth = 1920;
  static const int maxImageHeight = 1080;
  static const int imageQuality = 85;
  static const int thumbnailSize = 200;
  
  // Cache settings
  static const Duration cacheExpiry = Duration(hours: 24);
  static const int maxCacheSize = 100 * 1024 * 1024; // 100MB
  static const int maxCachedImages = 100;
  
  // List pagination
  static const int pageSize = 20;
  static const int prefetchThreshold = 5; // Load more when 5 items from end
  
  // Network settings
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);
  
  // Animation settings
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  static const Duration fastAnimationDuration = Duration(milliseconds: 150);
  static const Duration slowAnimationDuration = Duration(milliseconds: 500);
  
  // Performance thresholds
  static const int maxFrameRenderTime = 16; // milliseconds (60fps)
  static const int slowOperationThreshold = 1000; // milliseconds
  static const int maxStartupTime = 2000; // milliseconds
  
  // Memory management
  static const int maxMemoryUsage = 512 * 1024 * 1024; // 512MB
  static const int memoryWarningThreshold = 400 * 1024 * 1024; // 400MB
  
  // Battery optimization
  static const Duration backgroundSyncInterval = Duration(minutes: 15);
  static const Duration locationUpdateInterval = Duration(seconds: 30);
  
  // UI optimization
  static const bool enableAnimations = true;
  static const bool useShimmerLoading = true;
  static const bool enableHapticFeedback = true;
  
  // Debug settings
  static const bool enablePerformanceLogging = true;
  static const bool enableMemoryProfiling = true;
  static const bool showPerformanceOverlay = false;
  
  // Lazy loading
  static const bool enableLazyLoading = true;
  static const int visibleItemsBuffer = 3;
  
  // Image loading
  static const bool enableImageCaching = true;
  static const bool enableProgressiveLoading = true;
  static const bool enablePlaceholders = true;
  
  // Network optimization
  static const bool enableRequestBatching = true;
  static const int maxConcurrentRequests = 3;
  static const bool enableResponseCompression = true;
  
  // Build optimization
  static const bool useConstConstructors = true;
  static const bool enableTreeShaking = true;
  static const bool splitDebugInfo = true;
  static const bool obfuscate = true; // For release builds
}

/// Performance targets for monitoring
class PerformanceTargets {
  // Startup performance
  static const int coldStartTarget = 2000; // ms
  static const int warmStartTarget = 1000; // ms
  
  // UI responsiveness
  static const int targetFrameRate = 60; // fps
  static const int maxFrameDrops = 5; // per second
  
  // API response time
  static const int apiResponseTarget = 200; // ms
  static const int maxApiResponseTime = 3000; // ms
  
  // App size
  static const int targetAppSize = 50 * 1024 * 1024; // 50MB
  static const int maxAppSize = 100 * 1024 * 1024; // 100MB
  
  // Battery usage
  static const double maxBatteryDrainPerHour = 5.0; // percentage
}
