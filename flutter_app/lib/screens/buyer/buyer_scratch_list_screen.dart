import 'package:flutter/material.dart';
import '../../services/buyer_scratch_service.dart';
import 'buyer_scratch_card_screen.dart';

class BuyerScratchListScreen extends StatefulWidget {
  const BuyerScratchListScreen({super.key});

  @override
  State<BuyerScratchListScreen> createState() => _BuyerScratchListScreenState();
}

class _BuyerScratchListScreenState extends State<BuyerScratchListScreen> {
  final BuyerScratchService _service = BuyerScratchService();
  final TextEditingController _phoneController = TextEditingController();

  bool _isLoading = false;
  List<BuyerScratchTicket> _tickets = [];
  String? _error;
  String? _currentPhone;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadTickets() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tanpri antre nimewo telefòn ou'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final tickets = await _service.getMyScratchTickets(phone);
      if (mounted) {
        setState(() {
          _tickets = tickets;
          _currentPhone = phone;
          _isLoading = false;
        });
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

  void _reset() {
    setState(() {
      _tickets = [];
      _currentPhone = null;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tikè Grate Mwen',
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
        actions: _currentPhone != null
            ? [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Rechaje',
                  onPressed: _loadTickets,
                ),
              ]
            : null,
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
          child: _currentPhone == null ? _buildPhoneEntry() : _buildTicketList(),
        ),
      ),
    );
  }

  Widget _buildPhoneEntry() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          const Text(
            '🎰',
            style: TextStyle(fontSize: 56),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'Wè Tikè Grate Ou Yo',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Antre nimewo telefòn ou pou wè tikè grate ou yo',
            style: TextStyle(color: Colors.white70, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 12)],
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  '📱 Nimewo Telefòn',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: 'ex: 50912345678',
                    prefixIcon: const Icon(Icons.phone),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 16),
                  ),
                  onSubmitted: (_) => _loadTickets(),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      _error!,
                      style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                ElevatedButton(
                  onPressed: _isLoading ? null : _loadTickets,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF667eea),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          '🔍 Chèche Tikè Mwen',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketList() {
    return Column(
      children: [
        // Phone info bar
        Container(
          color: Colors.black12,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              const Icon(Icons.phone, color: Colors.white70, size: 16),
              const SizedBox(width: 6),
              Text(
                _currentPhone!,
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _reset,
                child: const Text(
                  'Chanje',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      decoration: TextDecoration.underline),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white))
              : _tickets.isEmpty
                  ? _buildEmptyState()
                  : _buildGrid(),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🎰', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            const Text(
              'Pa gen tikè grate',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ou poko achte okenn tikè grate.\nAchte youn nan seksyon "Scratch & Win"!',
              style: TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 280,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 1.1,
      ),
      itemCount: _tickets.length,
      itemBuilder: (context, index) =>
          _buildTicketCard(_tickets[index]),
    );
  }

  Widget _buildTicketCard(BuyerScratchTicket ticket) {
    final typeColors = _typeColors(ticket.ticketType);
    final typeLabel = _typeLabel(ticket.ticketType);
    final typeEmoji = _typeEmoji(ticket.ticketType);

    return GestureDetector(
      onTap: () => _openScratchCard(ticket),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Coloured header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(gradient: typeColors),
              child: Row(
                children: [
                  Text(typeEmoji,
                      style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      typeLabel,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: ticket.isScratched
                          ? Colors.white
                          : Colors.white30,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      ticket.isScratched ? 'Grate' : 'Nou',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: ticket.isScratched
                            ? Colors.green.shade700
                            : Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Body
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (ticket.createdAt != null)
                      Text(
                        '📅 ${_formatDate(ticket.createdAt!)}',
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF94a3b8)),
                      ),
                    ElevatedButton(
                      onPressed: () => _openScratchCard(ticket),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ticket.isScratched
                            ? const Color(0xFFf1f5f9)
                            : const Color(0xFF667eea),
                        foregroundColor: ticket.isScratched
                            ? const Color(0xFF475569)
                            : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                      child: Text(
                        ticket.isScratched ? '👁 Wè Rezilta' : '✨ Grate!',
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.bold),
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

  void _openScratchCard(BuyerScratchTicket ticket) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BuyerScratchCardScreen(
          ticket: ticket,
          phone: _currentPhone!,
        ),
      ),
    ).then((_) => _loadTickets()); // Refresh list on return
  }

  LinearGradient _typeColors(String type) {
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

  String _formatDate(DateTime d) {
    return '${d.day}/${d.month}/${d.year}';
  }
}
