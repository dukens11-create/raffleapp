import 'package:flutter/material.dart';
import 'package:scratcher/scratcher.dart';
import '../../services/buyer_scratch_service.dart';

/// Full-screen scratch card for a single [BuyerScratchTicket].
///
/// The grey overlay is scratched away using the `scratcher` package.
/// When the auto-reveal threshold (70 %) is reached the prize is
/// fetched from the backend and revealed.
class BuyerScratchCardScreen extends StatefulWidget {
  final BuyerScratchTicket ticket;
  final String phone;

  const BuyerScratchCardScreen({
    super.key,
    required this.ticket,
    required this.phone,
  });

  @override
  State<BuyerScratchCardScreen> createState() => _BuyerScratchCardScreenState();
}

class _BuyerScratchCardScreenState extends State<BuyerScratchCardScreen> {
  final _scratchKey = GlobalKey<ScratcherState>();
  final _service = BuyerScratchService();

  late BuyerScratchTicket _ticket;
  double _progress = 0;
  bool _revealed = false;
  bool _loading = false;
  String? _error;

  static const _revealThreshold = 70.0; // percent

  static const _typeColors = {
    'basic':   Color(0xFF10b981),
    'premium': Color(0xFF7c3aed),
    'bronze':  Color(0xFFea580c),
    'silver':  Color(0xFF94a3b8),
    'gold':    Color(0xFFf59e0b),
    'diamond': Color(0xFF06b6d4),
  };

  static const _typeGradients = {
    'basic':   [Color(0xFF10b981), Color(0xFF059669)],
    'premium': [Color(0xFF7c3aed), Color(0xFF6366f1)],
    'bronze':  [Color(0xFFea580c), Color(0xFFc2410c)],
    'silver':  [Color(0xFFcbd5e1), Color(0xFF64748b)],
    'gold':    [Color(0xFFfbbf24), Color(0xFFd97706)],
    'diamond': [Color(0xFF22d3ee), Color(0xFF0891b2)],
  };

  @override
  void initState() {
    super.initState();
    _ticket = widget.ticket;
    if (_ticket.isScratched) {
      _revealed = true;
    }
  }

  Future<void> _reveal() async {
    if (_revealed || _loading) return;
    setState(() { _loading = true; _error = null; });

    try {
      final result = await _service.scratchTicket(_ticket.id, widget.phone);
      setState(() {
        _ticket = _ticket.withPrize(
          prizeEmoji: result.prizeEmoji,
          prizeText:  result.prizeText,
          prizeValue: result.prizeValue,
          hasPrize:   result.hasPrize,
        );
        _revealed = true;
        _loading  = false;
        _progress = 100;
      });
      // Fully clear the scratcher overlay
      _scratchKey.currentState?.reveal(duration: const Duration(milliseconds: 400));
    } catch (e) {
      setState(() {
        _loading = false;
        _error   = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _typeColors[_ticket.ticketType] ?? const Color(0xFF6366f1);
    final gradColors = _typeGradients[_ticket.ticketType] ??
        const [Color(0xFF6366f1), Color(0xFF8b5cf6)];

    return Scaffold(
      appBar: AppBar(
        title: Text('GRATE GENYEN — ${_ticket.ticketType.toUpperCase()}'),
        backgroundColor: gradColors.first,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFF0f172a),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ── Error banner ─────────────────────────────────────────
            if (_error != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFef4444).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFef4444).withOpacity(0.4)),
                ),
                child: Text(_error!, style: const TextStyle(color: Color(0xFFfca5a5))),
              ),

            // ── Card ─────────────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Column(
                  children: [
                    // Header gradient
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: gradColors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'GRATE GENYEN',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _ticket.ticketType.toUpperCase(),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (_ticket.paymentReference != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Ref: ${_ticket.paymentReference}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Scratch area
                    Container(
                      color: const Color(0xFF1e293b),
                      child: Scratcher(
                        key: _scratchKey,
                        brushSize: 50,
                        threshold: _revealThreshold,
                        color: const Color(0xFF808080),
                        onChange: (value) {
                          setState(() => _progress = value);
                        },
                        onThreshold: _reveal,
                        child: SizedBox(
                          height: 220,
                          width: double.infinity,
                          child: _buildPrizeContent(),
                        ),
                      ),
                    ),

                    // Progress bar
                    Container(
                      color: const Color(0xFF1e293b),
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                      child: Column(
                        children: [
                          LinearProgressIndicator(
                            value: _progress / 100,
                            backgroundColor: Colors.white.withOpacity(0.1),
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                            minHeight: 6,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          const SizedBox(height: 6),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              '${_progress.toStringAsFixed(0)}% grate',
                              style: const TextStyle(
                                color: Color(0xFF64748b),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Bottom
                    Container(
                      color: const Color(0xFF1e293b),
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      child: Column(
                        children: [
                          if (!_revealed) ...[
                            Text(
                              '👆 Grate kare a ak dwèt ou pou wè pri ou a!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _loading ? null : _reveal,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF6366f1),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: _loading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text('⚡ Revele Touswit',
                                        style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                          if (_revealed) _buildPrizeBanner(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrizeContent() {
    final emoji = _ticket.prizeEmoji ?? '❓';
    final text  = _ticket.prizeText  ?? 'Grate pou wè pri ou a';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 72)),
          const SizedBox(height: 16),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrizeBanner() {
    final hasPrize = _ticket.hasPrize ?? false;
    final value    = _ticket.prizeValue ?? 0;

    if (hasPrize && value > 0) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF22c55e).withOpacity(0.25),
              const Color(0xFF10b981).withOpacity(0.25),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF22c55e).withOpacity(0.5)),
        ),
        child: Column(
          children: [
            const Text(
              '🎉 Ou Genyen!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Kontakte nou pou reklame ${value.toLocaleString()} GOUD ou a.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF94a3b8), fontSize: 14),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          const Text(
            '😅 Eseye Ankò!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Pa gen chans fwa sa a. Achte yon lòt tikè!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF94a3b8), fontSize: 14),
          ),
        ],
      ),
    );
  }
}

extension on int {
  String toLocaleString() {
    final s = toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}
