import 'package:flutter/material.dart';
import '../../../services/buyer_api_service.dart';
import '../../../models/buyer/my_ticket.dart';
import '../../../widgets/buyer/loading_spinner.dart';
import '../../../widgets/buyer/empty_state.dart';
import '../../../widgets/buyer/status_badge.dart';
import '../../../widgets/buyer/custom_button.dart';

class MyTicketsTab extends StatefulWidget {
  const MyTicketsTab({super.key});

  @override
  State<MyTicketsTab> createState() => _MyTicketsTabState();
}

class _MyTicketsTabState extends State<MyTicketsTab> {
  final BuyerApiService _apiService = BuyerApiService();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _buyerCodeController = TextEditingController();

  bool _isLoading = false;
  List<MyTicket> _tickets = [];
  String? _error;
  bool _hasSearched = false;

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _buyerCodeController.dispose();
    super.dispose();
  }

  Future<void> _lookupTickets() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // At least one field must be filled
    if (_emailController.text.isEmpty &&
        _phoneController.text.isEmpty &&
        _buyerCodeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter at least one search criteria'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _hasSearched = false;
    });

    try {
      final response = await _apiService.lookupMyTickets(
        email: _emailController.text.isEmpty ? null : _emailController.text,
        phone: _phoneController.text.isEmpty ? null : _phoneController.text,
        buyerCode: _buyerCodeController.text.isEmpty
            ? null
            : _buyerCodeController.text,
      );

      setState(() {
        _tickets = response.tickets;
        _isLoading = false;
        _hasSearched = true;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
        _hasSearched = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSearchForm(),
          const SizedBox(height: 24),
          if (_isLoading) const LoadingSpinner(message: 'Looking up tickets...'),
          if (_error != null) _buildError(),
          if (_hasSearched && !_isLoading && _error == null) _buildResults(),
        ],
      ),
    );
  }

  Widget _buildSearchForm() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '🔍 Look Up My Tickets',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1e293b),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter at least one of the following:',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748b),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  hintText: 'your@email.com',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  hintText: '+509 XXXX XXXX',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _buyerCodeController,
                decoration: const InputDecoration(
                  labelText: 'Buyer Code',
                  hintText: 'Enter your buyer code',
                  prefixIcon: Icon(Icons.code),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: 'Search Tickets',
                onPressed: _lookupTickets,
                isLoading: _isLoading,
                icon: Icons.search,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Card(
      elevation: 2,
      color: const Color(0xFFfef2f2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFdc2626)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _error!,
                style: const TextStyle(color: Color(0xFFdc2626)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    if (_tickets.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Padding(
          padding: EdgeInsets.all(40),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.inbox_outlined,
                  size: 64,
                  color: Color(0xFF94a3b8),
                ),
                SizedBox(height: 16),
                Text(
                  'No tickets found',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1e293b),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'No tickets match your search criteria',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748b),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Your Tickets',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1e293b),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF667eea).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_tickets.length} ticket${_tickets.length != 1 ? 's' : ''} found',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF667eea),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _tickets.length,
              separatorBuilder: (context, index) => const Divider(height: 24),
              itemBuilder: (context, index) {
                return _buildTicketItem(_tickets[index]);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketItem(MyTicket ticket) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.confirmation_number,
                  color: Color(0xFF667eea),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  ticket.ticketNumber,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1e293b),
                  ),
                ),
              ],
            ),
            StatusBadge(status: ticket.status, small: true),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildInfoChip(Icons.category, ticket.category),
            const SizedBox(width: 8),
            _buildInfoChip(Icons.attach_money, '${ticket.price} HTG'),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildInfoChip(Icons.qr_code, ticket.barcode),
            const SizedBox(width: 8),
            _buildInfoChip(Icons.calendar_today, ticket.purchaseDate),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFf1f5f9),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF64748b)),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }
}
