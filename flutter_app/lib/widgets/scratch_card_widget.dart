import 'package:flutter/material.dart';
import 'package:scratcher/scratcher.dart';
import '../models/scratch/scratch_ticket.dart';
import '../models/scratch/prize.dart';

class ScratchCardWidget extends StatefulWidget {
  final ScratchTicket ticket;
  final Prize selectedPrize;
  final VoidCallback onComplete;

  const ScratchCardWidget({
    Key? key,
    required this.ticket,
    required this.selectedPrize,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<ScratchCardWidget> createState() => _ScratchCardWidgetState();
}

class _ScratchCardWidgetState extends State<ScratchCardWidget>
    with SingleTickerProviderStateMixin {
  static const double _brushSizeRatio = 0.12;
  static const double _minBrushSize = 30.0;
  static const double _maxBrushSize = 70.0;

  double scratchProgress = 0;
  final scratchKey = GlobalKey<ScratcherState>();
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _shimmerAnimation = Tween<double>(begin: -1.5, end: 1.5).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Adaptive brush size: larger on bigger screens
    final adaptiveBrush =
        (screenWidth * _brushSizeRatio).clamp(_minBrushSize, _maxBrushSize);

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            // Ticket Header
            _buildTicketHeader(),
            
            // Scratch Area with shimmer overlay
            Expanded(
              child: Stack(
                children: [
                  Scratcher(
                    key: scratchKey,
                    brushSize: adaptiveBrush,
                    threshold: 55,
                    color: _getScratchOverlayColor(),
                    onChange: (value) {
                      setState(() {
                        scratchProgress = value;
                      });
                    },
                    onThreshold: () {
                      widget.onComplete();
                    },
                    child: _buildPrizeContent(),
                  ),
                  // Animated shimmer label on top of unscratched area
                  if (scratchProgress < 5)
                    _buildScratchHintOverlay(),
                ],
              ),
            ),
            
            // Progress Indicator
            _buildProgressIndicator(),
          ],
        ),
      ),
    );
  }

  /// Hint overlay shown before scratching starts
  Widget _buildScratchHintOverlay() {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _shimmerAnimation,
          builder: (context, child) {
            return Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(_shimmerAnimation.value - 1, 0),
                  end: Alignment(_shimmerAnimation.value + 1, 0),
                  colors: [
                    Colors.transparent,
                    Colors.white.withOpacity(0.12),
                    Colors.white.withOpacity(0.25),
                    Colors.white.withOpacity(0.12),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.ticket.typeName.toUpperCase(),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withOpacity(0.95),
                      letterSpacing: 2,
                      shadows: const [
                        Shadow(
                          color: Colors.black26,
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '✦ GRATE ISIT LA ✦',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.85),
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTicketHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: widget.ticket.theme.gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          // Price Badge
          Align(
            alignment: Alignment.topRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${widget.ticket.price} HTG',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.ticket.name,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: widget.ticket.theme.textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Win up to ${widget.ticket.prizeRange}',
            style: TextStyle(
              fontSize: 16,
              color: widget.ticket.theme.textColor.withOpacity(0.9),
            ),
          ),
          if (widget.ticket.subText != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.ticket.subText!,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: widget.ticket.theme.textColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPrizeContent() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: widget.ticket.theme.gradientColors,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.selectedPrize.emoji,
              style: const TextStyle(fontSize: 80),
            ),
            const SizedBox(height: 20),
            Text(
              widget.selectedPrize.text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: widget.ticket.theme.textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final pct = scratchProgress / 100;
    final color = widget.ticket.theme.gradientColors.first;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Scratched: ${scratchProgress.toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54,
                ),
              ),
              // Scratch All accessibility button
              GestureDetector(
                onTap: () {
                  scratchKey.currentState?.reveal();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: color, width: 1.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '✨ Scratch All',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getScratchOverlayColor() {
    final colors = widget.ticket.theme.gradientColors;
    return colors.isNotEmpty ? colors.first : Colors.grey;
  }
}
