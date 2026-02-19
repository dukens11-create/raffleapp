import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scratcher/scratcher.dart';
import '../../models/scratch_ticket.dart';
import '../../providers/scratch_provider.dart';

class ScratchCardScreen extends StatefulWidget {
  final ScratchTicket ticket;
  final String phone;

  const ScratchCardScreen({
    Key? key,
    required this.ticket,
    required this.phone,
  }) : super(key: key);

  @override
  State<ScratchCardScreen> createState() => _ScratchCardScreenState();
}

class _ScratchCardScreenState extends State<ScratchCardScreen> {
  final _scratchKey = GlobalKey<ScratcherState>();
  double _progress = 0;
  bool _revealed = false;
  bool _claiming = false;
  late ScratchTicket _ticket;

  @override
  void initState() {
    super.initState();
    _ticket = widget.ticket;
    // If already scratched, reveal immediately
    if (_ticket.isScratched) {
      _revealed = true;
    }
  }

  Future<void> _onRevealed() async {
    if (_revealed) return;
    setState(() => _revealed = true);

    // Mark as scratched on server
    final provider = context.read<ScratchProvider>();
    final updated =
        await provider.markScratched(_ticket.paymentReference, widget.phone);
    if (updated != null && mounted) {
      setState(() => _ticket = updated);
    }
  }

  Future<void> _claimPrize() async {
    setState(() => _claiming = true);
    final provider = context.read<ScratchProvider>();
    final success =
        await provider.claimPrize(_ticket.paymentReference, widget.phone);

    if (!mounted) return;
    setState(() => _claiming = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '🎉 Prize claimed! ${_ticket.prizeAmount.toStringAsFixed(0)} HTG'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );
      // Refresh ticket to show claimed state
      final updated =
          await provider.getTicket(_ticket.paymentReference);
      if (updated != null && mounted) {
        setState(() => _ticket = updated);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Failed to claim prize'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Color _getCategoryColor() {
    switch (_ticket.displayCategory.toUpperCase()) {
      case 'BASIC':
        return const Color(0xFF10b981);
      case 'PREMIUM':
        return const Color(0xFF7c3aed);
      case 'BRONZE':
        return const Color(0xFFea580c);
      case 'SILVER':
        return const Color(0xFF94a3b8);
      case 'GOLD':
        return const Color(0xFFfbbf24);
      case 'DIAMOND':
        return const Color(0xFF22d3ee);
      default:
        return const Color(0xFF667eea);
    }
  }

  @override
  Widget build(BuildContext context) {
    final catColor = _getCategoryColor();

    return Scaffold(
      appBar: AppBar(
        title: Text('${_ticket.displayCategory} Scratch Card'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [catColor, const Color(0xFF764ba2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Ticket info card
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_ticket.displayCategory} Ticket',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _ticket.shortRef,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                  Chip(
                    label: Text(
                      _ticket.displayCategory,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: catColor,
                  ),
                ],
              ),
            ),

            // Already scratched warning
            if (_ticket.isScratched && _revealed)
              Container(
                color: Colors.amber.shade50,
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: Colors.amber.shade800, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tikè sa deja grate. This ticket was already scratched.',
                        style: TextStyle(
                          color: Colors.amber.shade800,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // Scratch area
            Container(
              height: 280,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: _ticket.isScratched
                  ? _buildRevealedPrize(catColor)
                  : Scratcher(
                      key: _scratchKey,
                      brushSize: 50,
                      threshold: 70,
                      color: Colors.grey,
                      onChange: (value) {
                        setState(() => _progress = value);
                      },
                      onThreshold: _onRevealed,
                      child: _buildRevealedPrize(catColor),
                    ),
            ),

            const SizedBox(height: 16),

            // Progress indicator (only when scratching)
            if (!_ticket.isScratched)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    LinearProgressIndicator(
                      value: _progress / 100,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: AlwaysStoppedAnimation<Color>(catColor),
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_progress.toStringAsFixed(0)}% Scratched / Grate',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // Claim / Back buttons
            if (_revealed) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    if (_ticket.hasPrize && !_ticket.claimed)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _claiming ? null : _claimPrize,
                          icon: _claiming
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white),
                                )
                              : const Icon(Icons.emoji_events),
                          label: Text(_claiming
                              ? 'Claiming...'
                              : '🏆 Claim Prize / Reklame Pri'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            textStyle: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    if (_ticket.claimed)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: const Center(
                          child: Text(
                            '✅ Prize Already Claimed',
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('← Back to My Scratch Cards'),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildRevealedPrize(Color catColor) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [catColor, const Color(0xFF764ba2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: catColor.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _ticket.hasPrize ? '🎉' : '😢',
                style: const TextStyle(fontSize: 64),
              ),
              const SizedBox(height: 12),
              Text(
                _ticket.hasPrize
                    ? 'FÉLICITASYON!\nCONGRATULATIONS!'
                    : 'ESEYE ANKÒ!\nTRY AGAIN!',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.3,
                ),
              ),
              if (_ticket.hasPrize && _ticket.prizeAmount > 0) ...[
                const SizedBox(height: 12),
                Text(
                  '${_ticket.prizeAmount.toStringAsFixed(0)} HTG',
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFfde047),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                _ticket.prizeMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
