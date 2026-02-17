import 'package:flutter/material.dart';

class PaginationControls extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final bool isLoading;
  final VoidCallback? onPreviousPage;
  final VoidCallback? onNextPage;
  final Function(int)? onPageSelect;

  const PaginationControls({
    super.key,
    required this.currentPage,
    required this.totalPages,
    this.isLoading = false,
    this.onPreviousPage,
    this.onNextPage,
    this.onPageSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Previous button
          IconButton(
            onPressed: currentPage > 1 && !isLoading ? onPreviousPage : null,
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Previous Page',
          ),
          
          const SizedBox(width: 16),
          
          // Page indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Page $currentPage of $totalPages',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Next button
          IconButton(
            onPressed: currentPage < totalPages && !isLoading ? onNextPage : null,
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Next Page',
          ),
        ],
      ),
    );
  }
}

class LoadMoreButton extends StatelessWidget {
  final bool hasMore;
  final bool isLoading;
  final VoidCallback? onLoadMore;
  final String? loadingText;
  final String? loadMoreText;

  const LoadMoreButton({
    super.key,
    required this.hasMore,
    required this.isLoading,
    this.onLoadMore,
    this.loadingText,
    this.loadMoreText,
  });

  @override
  Widget build(BuildContext context) {
    if (!hasMore) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: isLoading
            ? Column(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 8),
                  Text(
                    loadingText ?? 'Loading more...',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              )
            : ElevatedButton.icon(
                onPressed: onLoadMore,
                icon: const Icon(Icons.refresh),
                label: Text(loadMoreText ?? 'Load More'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
      ),
    );
  }
}
