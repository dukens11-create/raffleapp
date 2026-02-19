import 'package:flutter/material.dart';
import 'package:scratcher/scratcher.dart';
import '../../services/buyer_scratch_service.dart';

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
  final BuyerScratchService _service = BuyerScratchService();
  final GlobalKey<ScratcherState> _scratchKey = GlobalKey<ScratcherState>();

  double _scratchProgress = 0;
  bool _isRevealed = false;
  bool _isLoading = false;
  ScratchResult? _result;
  String? _error;

  static const double _autoRevealThreshold = 70;

  @override
  void initState() {
    super.initState();
    // If already scratched, show the prize directly
    if (widget.ticket.isScratched) {
      _fetchExistingPrize();
    }
  }

  Future<void> _fetchExistingPrize() async {
    setState(() => _isLoading = true);
    try {
      final result = await _service.markScratched(widget.ticket.id, widget.phone);
      if (mounted) {
        setState(() {
          _result = result;
          _isRevealed = true;
          _isLoading = false;
        });
        _scratchKey.currentState?.reveal(duration: Duration.zero);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _onThreshold() async {
    if (_isRevealed) return;
    setState(() => _isLoading = true);
    try {
      final result = await _service.markScratched(widget.ticket.id, widget.phone);
      if (mounted) {
        setState(() {
          _result = result;
          _isRevealed = true;
          _isLoading = false;
        });
        // Fully reveal the scratch overlay
        _scratchKey.currentState?.reveal(duration: const Duration(milliseconds: 300));
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Grate Tikè Ou',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildTicketHeader(),
                const SizedBox(height: 20),
                if (widget.ticket.isScratched && !_isRevealed)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: _AlreadyScratchedBanner(),
                  ),
                if (_error != null) _buildErrorBanner(),
                _buildScratchArea(),
                if (_isRevealed && _result != null)
                  _buildPrizePanel(_result!),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTicketHeader() {
    final gradient = _typeGradient(widget.ticket.ticketType);
    final emoji = _typeEmoji(widget.ticket.ticketType);
    final label = _typeLabel(widget.ticket.ticketType);

    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 12)],
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 44)),
          const SizedBox(height: 8),
          const Text(
            'GRATE GENYEN',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
          ),
          const SizedBox(height: 4),
          Text(
            'Tikè $label',
            style:
                const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildScratchArea() {
    if (_isLoading) {
      return Container(
        height: 220,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    // Prize content shown underneath scratch overlay
    final prizeContent = _buildPrizeUnderlay();

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Scratcher(
            key: _scratchKey,
            brushSize: 40,
            threshold: _autoRevealThreshold,
            color: const Color(0xFF808080),
            onChange: (value) {
              setState(() => _scratchProgress = value);
            },
            onThreshold: _onThreshold,
            child: prizeContent,
          ),
        ),
        if (!_isRevealed) ...[
          const SizedBox(height: 10),
          _buildProgressBar(),
          const SizedBox(height: 6),
          const Text(
            '✋ Deplase dwèt ou sou kare gri pou grate',
            style: TextStyle(color: Colors.white70, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildPrizeUnderlay() {
    // Show loading or placeholder prize display underneath the grey overlay
    return Container(
      height: 220,
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🎁', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 12),
            Text(
              _isRevealed && _result != null
                  ? _result!.prizeText
                  : 'GRATE POU WÈ',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _isRevealed && _result != null && _result!.hasPrize
                    ? const Color(0xFFd97706)
                    : const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: _scratchProgress / 100,
            backgroundColor: Colors.white30,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${_scratchProgress.toStringAsFixed(0)}% grate',
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildPrizePanel(ScratchResult result) {
    return AnimatedOpacity(
      opacity: 1.0,
      duration: const Duration(milliseconds: 500),
      child: Container(
        margin: const EdgeInsets.only(top: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 12)],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(result.prizeEmoji, style: const TextStyle(fontSize: 52)),
            const SizedBox(height: 12),
            Text(
              result.prizeText,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: result.hasPrize
                    ? const Color(0xFFd97706)
                    : const Color(0xFF94a3b8),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              result.hasPrize
                  ? '🎉 Ou genyen! Kontakte nou pou reklame prim ou a.'
                  : 'Eseye ankò nan pwochen tikè ou a!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: result.hasPrize
                    ? Colors.green.shade700
                    : const Color(0xFF94a3b8),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('← Retounen nan lis tikè'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Text(
        _error!,
        style: TextStyle(color: Colors.red.shade700, fontSize: 13),
      ),
    );
  }

  LinearGradient _typeGradient(String type) {
    switch (type) {
      case 'basic':
        return const LinearGradient(
            colors: [Color(0xFF10b981), Color(0xFF059669)]);
      case 'premium':
        return const LinearGradient(
            colors: [Color(0xFF7c3aed), Color(0xFF6366f1)]);
      case 'bronze':
        return const LinearGradient(
            colors: [Color(0xFFea580c), Color(0xFFdc2626)]);
      case 'silver':
        return const LinearGradient(
            colors: [Color(0xFF94a3b8), Color(0xFF64748b)]);
      case 'gold':
        return const LinearGradient(
            colors: [Color(0xFFf59e0b), Color(0xFFd97706)]);
      case 'diamond':
        return const LinearGradient(
            colors: [Color(0xFF06b6d4), Color(0xFF0284c7)]);
      default:
        return const LinearGradient(
            colors: [Color(0xFF667eea), Color(0xFF764ba2)]);
    }
  }

  String _typeLabel(String type) {
    const labels = {
      'basic': 'Basic',
      'premium': 'Premium',
      'bronze': 'Bronze',
      'silver': 'Silver',
      'gold': 'Gold',
      'diamond': 'Diamond',
    };
    return labels[type] ?? type;
  }

  String _typeEmoji(String type) {
    const emojis = {
      'basic': '🎉',
      'premium': '🎰',
      'bronze': '🏆',
      'silver': '💫',
      'gold': '👑',
      'diamond': '💎',
    };
    return emojis[type] ?? '🎰';
  }
}

class _AlreadyScratchedBanner extends StatelessWidget {
  const _AlreadyScratchedBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white38),
      ),
      child: const Row(
        children: [
          Icon(Icons.check_circle_outline, color: Colors.white70, size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              '✅ Ou deja grate tikè sa a. Chajman rezilta...',
              style: TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
