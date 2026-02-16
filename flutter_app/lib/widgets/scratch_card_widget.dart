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

class _ScratchCardWidgetState extends State<ScratchCardWidget> {
  double scratchProgress = 0;
  final scratchKey = GlobalKey<ScratcherState>();

  @override
  Widget build(BuildContext context) {
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
            
            // Scratch Area
            Expanded(
              child: Scratcher(
                key: scratchKey,
                brushSize: 50,
                threshold: 70,
                color: _getScratchColor(),
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
            ),
            
            // Progress Indicator
            _buildProgressIndicator(),
          ],
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
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          LinearProgressIndicator(
            value: scratchProgress / 100,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              widget.ticket.theme.gradientColors.first,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Scratched: ${scratchProgress.toStringAsFixed(0)}%',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getScratchColor() {
    // Return cover color based on ticket theme
    final colors = widget.ticket.theme.gradientColors;
    return colors.isNotEmpty ? colors.first : Colors.grey;
  }
}
