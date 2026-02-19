import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scratcher/scratcher.dart';
import '../../models/api_scratch_ticket.dart';
import '../../providers/scratch_provider.dart';

/// Screen for scratching a purchased API-connected scratch ticket.
/// The grey overlay is rendered using the [Scratcher] package.
/// Prize data is fetched from the backend and revealed on threshold.
class ScratchCardScreen extends StatelessWidget {
  final String paymentReference;

  const ScratchCardScreen({Key? key, required this.paymentReference}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ScratchProvider(),
      child: _ScratchCardBody(paymentReference: paymentReference),
    );
  }
}

class _ScratchCardBody extends StatefulWidget {
  final String paymentReference;
  const _ScratchCardBody({required this.paymentReference});

  @override
  State<_ScratchCardBody> createState() => _ScratchCardBodyState();
}

class _ScratchCardBodyState extends State<_ScratchCardBody> {
  double _progress = 0;
  bool _revealed = false;
  final _scratchKey = GlobalKey<ScratcherState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ScratchProvider>().loadTicket(widget.paymentReference);
    });
  }

  void _onScratchThreshold(ScratchProvider provider) async {
    if (_revealed) return;
    setState(() => _revealed = true);

    // Mark scratched on the server and get the actual prize result
    await provider.markScratched(widget.paymentReference);
    if (mounted) _showResultDialog(provider);
  }

  void _showResultDialog(ScratchProvider provider) {
    final ticket = provider.currentTicket;
    if (ticket == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              ticket.hasPrize ? '🎉' : '😢',
              style: const TextStyle(fontSize: 80),
            ),
            const SizedBox(height: 16),
            Text(
              ticket.hasPrize ? 'Félicitasyon!' : 'Eseye Ankò!',
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (ticket.hasPrize) ...[
              Text(
                '${ticket.prizeAmount.toStringAsFixed(0)} HTG',
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF667eea)),
              ),
              const SizedBox(height: 8),
            ],
            Text(
              ticket.prizeMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            if (ticket.hasPrize && !ticket.claimed)
              ElevatedButton.icon(
                icon: const Icon(Icons.card_giftcard),
                label: const Text('Claim Prize'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF667eea),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  await _claimPrize(provider);
                },
              ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop();
              },
              child: const Text('Back to My Cards'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _claimPrize(ScratchProvider provider) async {
    final success = await provider.claimPrize(widget.paymentReference);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? '🎉 Prize claimed! Please visit our office to collect.'
              : provider.error ?? 'Failed to claim prize.',
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🎰 Scratch & Win'),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Consumer<ScratchProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading && provider.currentTicket == null) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            }

            if (provider.error != null && provider.currentTicket == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.white, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        provider.error!,
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Back'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final ticket = provider.currentTicket;
            if (ticket == null) return const SizedBox.shrink();

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildHeader(ticket),
                  const SizedBox(height: 16),
                  if (!ticket.isApproved) _buildPendingBanner(),
                  _buildScratchArea(ticket, provider),
                  const SizedBox(height: 16),
                  _buildProgress(),
                  const SizedBox(height: 16),
                  if (_revealed) _buildActions(ticket, provider),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(ApiScratchTicket ticket) {
    final shortRef = ticket.paymentReference.length > 12
        ? '…${ticket.paymentReference.substring(ticket.paymentReference.length - 12)}'
        : ticket.paymentReference;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ticket $shortRef',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(ticket.buyerName,
                    style: const TextStyle(color: Colors.black54, fontSize: 13)),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                ticket.ticketCategory,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingBanner() {
    return Card(
      color: Colors.amber.shade50,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: const Padding(
        padding: EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(Icons.hourglass_top, color: Colors.amber),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                "Your payment is pending verification. You can scratch once it's approved.",
                style: TextStyle(color: Colors.amber, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScratchArea(ApiScratchTicket ticket, ScratchProvider provider) {
    if (ticket.isScratched && !_revealed) {
      // Ticket was already scratched in a previous session - reveal immediately
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _revealed = true);
      });
    }

    return Container(
      height: 280,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ticket.isApproved && !ticket.isScratched
            ? Scratcher(
                key: _scratchKey,
                brushSize: 50,
                threshold: 70,
                color: Colors.grey,
                onChange: (value) => setState(() => _progress = value),
                onThreshold: () => _onScratchThreshold(provider),
                child: _buildPrizeContent(ticket),
              )
            : _buildPrizeContent(ticket, showPrize: ticket.isScratched),
      ),
    );
  }

  Widget _buildPrizeContent(ApiScratchTicket ticket, {bool showPrize = true}) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              showPrize
                  ? (ticket.hasPrize ? '🎉' : '😢')
                  : '🎰',
              style: const TextStyle(fontSize: 72),
            ),
            const SizedBox(height: 16),
            Text(
              showPrize
                  ? (ticket.hasPrize ? 'CONGRATULATIONS!' : 'TRY AGAIN!')
                  : 'SCRATCH TO REVEAL',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            if (showPrize && ticket.hasPrize) ...[
              const SizedBox(height: 8),
              Text(
                '${ticket.prizeAmount.toStringAsFixed(0)} HTG',
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ],
            if (showPrize) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  ticket.prizeMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 15),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProgress() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            LinearProgressIndicator(
              value: _progress / 100,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF667eea)),
            ),
            const SizedBox(height: 8),
            Text(
              '${_progress.toStringAsFixed(0)}% Scratched',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(ApiScratchTicket ticket, ScratchProvider provider) {
    return Column(
      children: [
        if (ticket.hasPrize && !ticket.claimed)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.card_giftcard),
              label: const Text('Claim Prize',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667eea),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => _claimPrize(provider),
            ),
          ),
        if (ticket.claimed)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('✅ Prize already claimed',
                style: TextStyle(color: Colors.white, fontSize: 15)),
          ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Back to My Cards', style: TextStyle(color: Colors.white70)),
        ),
      ],
    );
  }
}
