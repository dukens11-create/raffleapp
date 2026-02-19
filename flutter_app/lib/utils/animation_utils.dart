import 'package:flutter/material.dart';

/// Reusable animation utilities
/// 
/// Provides common animations for consistent UX across the app
class AnimationUtils {
  /// Fade in animation
  static Widget fadeIn({
    required Widget child,
    Duration duration = const Duration(milliseconds: 300),
    Duration delay = Duration.zero,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: child,
        );
      },
      child: child,
    );
  }

  /// Slide in from bottom animation
  static Widget slideInFromBottom({
    required Widget child,
    Duration duration = const Duration(milliseconds: 400),
    Curve curve = Curves.easeOut,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 50.0, end: 0.0),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, value),
          child: Opacity(
            opacity: (50 - value) / 50,
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  /// Scale animation
  static Widget scaleIn({
    required Widget child,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeOut,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: child,
    );
  }

  /// Success checkmark animation
  static Widget successCheckmark({
    double size = 80,
    Color? color,
    VoidCallback? onComplete,
  }) {
    return Builder(
      builder: (context) {
        final checkColor = color ?? Colors.green;
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 600),
          curve: Curves.elasticOut,
          onEnd: onComplete,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: checkColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  size: size * 0.8,
                  color: checkColor,
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Page transition
  static Route createRoute({
    required Widget page,
    RouteTransitionType type = RouteTransitionType.slideFromRight,
  }) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        switch (type) {
          case RouteTransitionType.slideFromRight:
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              )),
              child: child,
            );
          case RouteTransitionType.slideFromBottom:
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              )),
              child: child,
            );
          case RouteTransitionType.fade:
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          case RouteTransitionType.scale:
            return ScaleTransition(
              scale: Tween<double>(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeInOut,
                ),
              ),
              child: child,
            );
        }
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  /// Animated list item
  static Widget animatedListItem({
    required Widget child,
    required int index,
    Duration delay = const Duration(milliseconds: 50),
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  /// Shimmer effect for loading
  static Widget shimmer({
    required Widget child,
    Duration duration = const Duration(milliseconds: 1500),
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: -1.0, end: 2.0),
      duration: duration,
      builder: (context, value, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: [
                value - 1,
                value,
                value + 1,
              ],
              colors: const [
                Colors.grey,
                Colors.white,
                Colors.grey,
              ],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: child,
    );
  }

  /// Bounce animation
  static Widget bounce({
    required Widget child,
    Duration duration = const Duration(milliseconds: 400),
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1.0, end: 0.0),
      duration: duration,
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, -20 * value),
          child: child,
        );
      },
      child: child,
    );
  }
}

/// Route transition types
enum RouteTransitionType {
  slideFromRight,
  slideFromBottom,
  fade,
  scale,
}
