import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Shimmer loading effect for lists and cards
/// 
/// Provides a smooth loading animation that mimics the content structure
class ShimmerLoading extends StatelessWidget {
  final Widget child;
  final bool isLoading;

  const ShimmerLoading({
    super.key,
    required this.child,
    this.isLoading = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!isLoading) {
      return child;
    }

    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: child,
    );
  }

  /// Shimmer loading for list items
  static Widget listItem({
    int itemCount = 5,
    double itemHeight = 80,
    EdgeInsets? padding,
  }) {
    return ListView.builder(
      padding: padding ?? const EdgeInsets.all(16),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: ShimmerLoading(
            child: Container(
              height: itemHeight,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Shimmer loading for ticket cards
  static Widget ticketCard() {
    return ShimmerLoading(
      child: Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title shimmer
              Container(
                height: 20,
                width: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 12),
              
              // Subtitle shimmer
              Container(
                height: 16,
                width: 150,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 16),
              
              // Details shimmer
              Row(
                children: [
                  Container(
                    height: 14,
                    width: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    height: 14,
                    width: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Shimmer loading for grid items
  static Widget gridItem({
    required int crossAxisCount,
    int itemCount = 6,
    double childAspectRatio = 1,
    EdgeInsets? padding,
  }) {
    return GridView.builder(
      padding: padding ?? const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return ShimmerLoading(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      },
    );
  }

  /// Shimmer loading for text lines
  static Widget text({
    double width = double.infinity,
    double height = 16,
    EdgeInsets? margin,
  }) {
    return ShimmerLoading(
      child: Container(
        width: width,
        height: height,
        margin: margin,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  /// Shimmer loading for circular avatar
  static Widget avatar({
    double size = 48,
  }) {
    return ShimmerLoading(
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
