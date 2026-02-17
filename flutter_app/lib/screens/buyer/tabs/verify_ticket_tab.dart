import 'package:flutter/material.dart';
import '../../../services/buyer_api_service.dart';
import '../../../models/buyer/verify_ticket.dart';
import '../../../widgets/buyer/custom_button.dart';
import '../../../widgets/buyer/loading_spinner.dart';

class VerifyTicketTab extends StatefulWidget {
  const VerifyTicketTab({super.key});

  @override
  State<VerifyTicketTab> createState() => _VerifyTicketTabState();
}

class _VerifyTicketTabState extends State<VerifyTicketTab> {
  final BuyerApiService _apiService = BuyerApiService();
  final _formKey = GlobalKey<FormState>();
  final _ticketController = TextEditingController();

  bool _isLoading = false;
  VerifyTicketResponse? _result;

  @override
  void dispose() {
    _ticketController.dispose();
    super.dispose();
  }

  Future<void> _verifyTicket() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _result = null;
    });

    try {
      final response = await _apiService.verifyTicket(_ticketController.text);
      setState(() {
        _result = response;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _result = VerifyTicketResponse(
          valid: false,
          message: e.toString(),
        );
        _isLoading = false;
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
          _buildVerifyForm(),
          const SizedBox(height: 24),
          if (_isLoading) const LoadingSpinner(message: 'Verifying ticket...'),
          if (_result != null && !_isLoading) _buildResult(),
        ],
      ),
    );
  }

  Widget _buildVerifyForm() {
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
                '✅ Verify Ticket Status',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1e293b),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter a ticket number or barcode to verify its status',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748b),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _ticketController,
                decoration: const InputDecoration(
                  labelText: 'Ticket Number or Barcode',
                  hintText: 'Enter ticket number',
                  prefixIcon: Icon(Icons.qr_code_scanner),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a ticket number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: 'Verify Ticket',
                onPressed: _verifyTicket,
                isLoading: _isLoading,
                icon: Icons.verified,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResult() {
    if (_result!.valid) {
      return Card(
        elevation: 2,
        color: const Color(0xFFf0fdf4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF10b981).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Color(0xFF059669),
                  size: 48,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '✅ Valid Ticket',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF059669),
                ),
              ),
              const SizedBox(height: 16),
              _buildDetailRow('Ticket Number', _result!.ticketNumber ?? 'N/A'),
              const SizedBox(height: 8),
              _buildDetailRow('Category', _result!.category ?? 'N/A'),
              const SizedBox(height: 8),
              _buildDetailRow(
                'Price',
                _result!.price != null ? '${_result!.price} HTG' : 'N/A',
              ),
              const SizedBox(height: 8),
              _buildDetailRow('Status', _result!.status ?? 'N/A'),
            ],
          ),
        ),
      );
    } else {
      return Card(
        elevation: 2,
        color: const Color(0xFFfef2f2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFef4444).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.cancel,
                  color: Color(0xFFdc2626),
                  size: 48,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '❌ Invalid Ticket',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFdc2626),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _result!.message ?? 'Ticket not found or invalid',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF991b1b),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF64748b),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1e293b),
          ),
        ),
      ],
    );
  }
}
