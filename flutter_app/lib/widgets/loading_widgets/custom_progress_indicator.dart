import 'package:flutter/material.dart';

/// Custom branded progress indicator
/// 
/// Provides consistent loading indicators across the app with branding
class CustomProgressIndicator extends StatelessWidget {
  final double size;
  final Color? color;
  final double strokeWidth;

  const CustomProgressIndicator({
    super.key,
    this.size = 40,
    this.color,
    this.strokeWidth = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          strokeWidth: strokeWidth,
          valueColor: AlwaysStoppedAnimation<Color>(
            color ?? Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }

  /// Small progress indicator
  static Widget small({Color? color}) {
    return CustomProgressIndicator(
      size: 24,
      strokeWidth: 3,
      color: color,
    );
  }

  /// Medium progress indicator (default)
  static Widget medium({Color? color}) {
    return CustomProgressIndicator(
      size: 40,
      strokeWidth: 4,
      color: color,
    );
  }

  /// Large progress indicator
  static Widget large({Color? color}) {
    return CustomProgressIndicator(
      size: 60,
      strokeWidth: 5,
      color: color,
    );
  }

  /// Full screen loading overlay
  static Widget overlay({
    String? message,
    Color? backgroundColor,
  }) {
    return Builder(
      builder: (context) {
        return Container(
          color: backgroundColor ?? Colors.black.withOpacity(0.5),
          child: Center(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomProgressIndicator.large(),
                    if (message != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        message,
                        style: Theme.of(context).textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Linear progress indicator
  static Widget linear({
    double? value,
    Color? color,
    Color? backgroundColor,
  }) {
    return Builder(
      builder: (context) {
        return LinearProgressIndicator(
          value: value,
          valueColor: AlwaysStoppedAnimation<Color>(
            color ?? Theme.of(context).colorScheme.primary,
          ),
          backgroundColor: backgroundColor ?? Colors.grey[200],
        );
      },
    );
  }
}

/// Loading button with progress indicator
class LoadingButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final bool isLoading;
  final IconData? icon;
  final bool isPrimary;

  const LoadingButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.isLoading = false,
    this.icon,
    this.isPrimary = true,
  });

  @override
  Widget build(BuildContext context) {
    final button = isPrimary
        ? ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            child: _buildContent(),
          )
        : OutlinedButton(
            onPressed: isLoading ? null : onPressed,
            child: _buildContent(),
          );

    return SizedBox(
      width: double.infinity,
      child: button,
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Text(label),
        ],
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon),
          const SizedBox(width: 8),
          Text(label),
        ],
      );
    }

    return Text(label);
  }
}
