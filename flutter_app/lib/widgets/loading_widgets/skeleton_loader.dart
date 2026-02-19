import 'package:flutter/material.dart';
import 'shimmer_loading.dart';

/// Skeleton loader for detail pages
/// 
/// Shows placeholder content while data is loading
class SkeletonLoader extends StatelessWidget {
  final SkeletonType type;

  const SkeletonLoader({
    super.key,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case SkeletonType.ticketDetail:
        return _buildTicketDetailSkeleton();
      case SkeletonType.profile:
        return _buildProfileSkeleton();
      case SkeletonType.list:
        return _buildListSkeleton();
    }
  }

  Widget _buildTicketDetailSkeleton() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header image skeleton
          ShimmerLoading(
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Title skeleton
          ShimmerLoading.text(width: 250, height: 24),
          const SizedBox(height: 12),

          // Subtitle skeleton
          ShimmerLoading.text(width: 180, height: 16),
          const SizedBox(height: 24),

          // Info rows
          ...List.generate(4, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ShimmerLoading.text(width: 120, height: 16),
                  ShimmerLoading.text(width: 100, height: 16),
                ],
              ),
            );
          }),

          const SizedBox(height: 24),

          // Description skeleton
          ShimmerLoading.text(width: double.infinity, height: 16),
          const SizedBox(height: 8),
          ShimmerLoading.text(width: double.infinity, height: 16),
          const SizedBox(height: 8),
          ShimmerLoading.text(width: 200, height: 16),
          const SizedBox(height: 32),

          // Button skeleton
          ShimmerLoading(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSkeleton() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Avatar skeleton
          ShimmerLoading.avatar(size: 100),
          const SizedBox(height: 16),

          // Name skeleton
          ShimmerLoading.text(width: 200, height: 20),
          const SizedBox(height: 8),

          // Email skeleton
          ShimmerLoading.text(width: 180, height: 16),
          const SizedBox(height: 32),

          // Stats cards
          Row(
            children: [
              Expanded(
                child: ShimmerLoading(
                  child: Container(
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ShimmerLoading(
                  child: Container(
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // List items
          ...List.generate(5, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ShimmerLoading(
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildListSkeleton() {
    return ShimmerLoading.listItem(
      itemCount: 8,
      itemHeight: 80,
    );
  }
}

/// Types of skeleton loaders
enum SkeletonType {
  ticketDetail,
  profile,
  list,
}
