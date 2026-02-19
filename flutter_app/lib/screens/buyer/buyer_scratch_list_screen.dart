import 'package:flutter/material.dart';
import '../../services/buyer_scratch_service.dart';
import 'buyer_scratch_card_screen.dart';

/// Displays the list of buyer scratch tickets for a given phone number.
class BuyerScratchListScreen extends StatefulWidget {
  const BuyerScratchListScreen({super.key});

  @override
  State<BuyerScratchListScreen> createState() => _BuyerScratchListScreenState();
}

class _BuyerScratchListScreenState extends State<BuyerScratchListScreen> {
  final _phoneController = TextEditingController();
  final _service = BuyerScratchService();

  List<BuyerScratchTicket>? _tickets;
  bool _loading = false;
  String? _error;
  String? _currentPhone;

  static const _typeColors = {
    'basic':   Color(0xFF10b981),
    'premium': Color(0xFF7c3aed),
    'bronze':  Color(0xFFea580c),
    'silver':  Color(0xFF94a3b8),
    'gold':    Color(0xFFf59e0b),
    'diamond': Color(0xFF06b6d4),
  };

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _lookup() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      setState(() => _error = 'Tanpri antre nimewo telefòn ou a.');
      return;
    }
    setState(() { _loading = true; _error = null; _tickets = null; });

    try {
      final tickets = await _service.getMyTickets(phone);
      setState(() {
        _tickets = tickets;
        _currentPhone = phone;
        _loading = false;
        if (tickets.isEmpty) _error = 'Pa gen tikè grate jwenn pou nimewo sa a.';
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tikè Grate Mwen'),
        backgroundColor: const Color(0xFF1e293b),
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFF0f172a),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildLookupCard(),
          if (_error != null) _buildErrorBanner(_error!),
          if (_loading) const Center(child: Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(color: Color(0xFF6366f1)),
          )),
          if (_tickets != null && _tickets!.isNotEmpty)
            ..._tickets!.map(_buildTicketCard),
        ],
      ),
    );
  }

  Widget _buildLookupCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📱 Chèche tikè ou yo pa nimewo telefòn',
            style: TextStyle(color: Color(0xFFcbd5e1), fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'ex: 50912345678',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.07),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF6366f1)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  onSubmitted: (_) => _lookup(),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _loading ? null : _lookup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366f1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('🔍', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(String msg) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFef4444).withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFef4444).withOpacity(0.4)),
      ),
      child: Text(msg, style: const TextStyle(color: Color(0xFFfca5a5), fontSize: 14)),
    );
  }

  Widget _buildTicketCard(BuyerScratchTicket ticket) {
    final color = _typeColors[ticket.ticketType] ?? const Color(0xFF6366f1);
    final isScratched = ticket.isScratched;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  ticket.ticketType.toUpperCase(),
                  style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isScratched
                        ? const Color(0xFF22c55e).withOpacity(0.2)
                        : const Color(0xFFf59e0b).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isScratched ? '✅ Grate' : '🔔 Pa Grate',
                    style: TextStyle(
                      color: isScratched ? const Color(0xFF86efac) : const Color(0xFFfde68a),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Ref
          if (ticket.paymentReference != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Ref: ${ticket.paymentReference}',
                  style: const TextStyle(color: Color(0xFF94a3b8), fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),

          // Date
          if (ticket.createdAt != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _formatDate(ticket.createdAt!),
                  style: const TextStyle(color: Color(0xFF64748b), fontSize: 12),
                ),
              ),
            ),

          // Button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _openScratchCard(ticket),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isScratched
                      ? Colors.white.withOpacity(0.1)
                      : const Color(0xFFf59e0b),
                  foregroundColor: isScratched ? const Color(0xFF94a3b8) : const Color(0xFF1c1917),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: Text(
                  isScratched ? '👁 Wè Rezilta' : '✨ Grate Kounye a!',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openScratchCard(BuyerScratchTicket ticket) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BuyerScratchCardScreen(
          ticket: ticket,
          phone: _currentPhone ?? '',
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
  }
}
