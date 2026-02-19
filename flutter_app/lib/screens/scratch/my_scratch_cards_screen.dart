import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/api_scratch_ticket.dart';
import '../../providers/scratch_provider.dart';
import 'scratch_card_screen.dart';

/// Screen that shows the buyer's purchased scratch tickets.
/// Buyers look up their cards by payment reference, email, or phone.
class MyScratchCardsScreen extends StatelessWidget {
  const MyScratchCardsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ScratchProvider(),
      child: const _MyScratchCardsBody(),
    );
  }
}

class _MyScratchCardsBody extends StatefulWidget {
  const _MyScratchCardsBody();

  @override
  State<_MyScratchCardsBody> createState() => _MyScratchCardsBodyState();
}

class _MyScratchCardsBodyState extends State<_MyScratchCardsBody> {
  final _refCtrl   = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _formKey   = GlobalKey<FormState>();

  @override
  void dispose() {
    _refCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _lookup() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    await context.read<ScratchProvider>().loadTickets(
      ref:   _refCtrl.value.text.trim().isNotEmpty ? _refCtrl.value.text.trim() : null,
      email: _emailCtrl.value.text.trim().isNotEmpty ? _emailCtrl.value.text.trim() : null,
      phone: _phoneCtrl.value.text.trim().isNotEmpty ? _phoneCtrl.value.text.trim() : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🎰 My Scratch Cards'),
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
          builder: (context, provider, _) => SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildLookupCard(context, provider),
                if (provider.error != null) _buildError(provider.error!),
                if (!provider.isLoading && provider.tickets.isNotEmpty)
                  _buildTicketList(context, provider.tickets),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLookupCard(BuildContext context, ScratchProvider provider) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Find My Scratch Cards',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'Enter your buyer code, email, or phone number.',
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _refCtrl,
                decoration: _inputDeco('Buyer Code (Payment Reference)', Icons.confirmation_number_outlined),
                autocorrect: false,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: _inputDeco('Email Address', Icons.email_outlined),
                autocorrect: false,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: _inputDeco('Phone Number', Icons.phone_outlined),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: provider.isLoading ? null : _lookup,
                  icon: provider.isLoading
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.search),
                  label: Text(provider.isLoading ? 'Searching…' : 'Find My Cards'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: const Color(0xFF667eea),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTicketList(BuildContext context, List<ApiScratchTicket> tickets) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            '${tickets.length} Scratch Card${tickets.length == 1 ? '' : 's'} Found',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...tickets.map((ticket) => _buildTicketRow(context, ticket)),
      ],
    );
  }

  Widget _buildTicketRow(BuildContext context, ApiScratchTicket ticket) {
    final shortRef = ticket.paymentReference.length > 12
        ? '…${ticket.paymentReference.substring(ticket.paymentReference.length - 12)}'
        : ticket.paymentReference;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: const Icon(Icons.casino_outlined, color: Color(0xFF667eea), size: 32),
        title: Text(shortRef, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                _chip(ticket.ticketCategory, const Color(0xFF667eea), Colors.white),
                _chip(
                  ticket.isApproved ? '✓ Approved' : '⏳ Pending',
                  ticket.isApproved ? Colors.green.shade100 : Colors.amber.shade100,
                  ticket.isApproved ? Colors.green.shade800 : Colors.amber.shade800,
                ),
                if (ticket.isApproved)
                  _chip(
                    ticket.isScratched ? '✦ Scratched' : '⬜ Unscratched',
                    ticket.isScratched ? Colors.purple.shade50 : Colors.blue.shade50,
                    ticket.isScratched ? Colors.purple.shade800 : Colors.blue.shade800,
                  ),
              ],
            ),
          ],
        ),
        trailing: ticket.isApproved
            ? ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ScratchCardScreen(
                        paymentReference: ticket.paymentReference,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF667eea),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  ticket.isScratched ? 'View' : 'Scratch',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              )
            : const Text('Pending', style: TextStyle(color: Colors.grey, fontSize: 13)),
      ),
    );
  }

  Widget _buildError(String error) {
    return Card(
      color: Colors.red.shade50,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 12),
            Expanded(
              child: Text(error, style: const TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, color: fg, fontWeight: FontWeight.w600)),
    );
  }

  InputDecoration _inputDeco(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
  }
}
