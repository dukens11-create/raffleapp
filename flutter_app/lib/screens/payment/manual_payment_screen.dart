import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/payment_service.dart';
import '../../models/transaction.dart';

/// Manual payment screen for USSD/app-based payments
/// 
/// Flow:
/// 1. Show payment instructions and wallet number
/// 2. User makes payment via USSD (*202#) or app
/// 3. User enters transaction reference
/// 4. Submit for admin verification
class ManualPaymentScreen extends StatefulWidget {
  final double amount;
  final String ticketCategory;
  final int ticketQuantity;
  final String buyerName;
  final String buyerPhone;
  final String? buyerEmail;
  final String? department;
  final String paymentMethod;

  const ManualPaymentScreen({
    super.key,
    required this.amount,
    required this.ticketCategory,
    required this.ticketQuantity,
    required this.buyerName,
    required this.buyerPhone,
    this.buyerEmail,
    this.department,
    required this.paymentMethod,
  });

  @override
  State<ManualPaymentScreen> createState() => _ManualPaymentScreenState();
}

class _ManualPaymentScreenState extends State<ManualPaymentScreen> {
  final PaymentService _paymentService = PaymentService();
  final TextEditingController _transactionIdController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  bool _isSubmitting = false;
  bool _showInstructions = true;

  @override
  void dispose() {
    _transactionIdController.dispose();
    super.dispose();
  }

  String get _walletNumber {
    // TODO: Fetch from backend configuration API
    // In production, this should come from /api/config/payment-wallets
    // For now, using hardcoded values for development
    if (widget.paymentMethod.contains('moncash')) {
      return '509-1234-5678'; // MonCash wallet - should be from backend
    } else {
      return '509-8765-4321'; // NatCash wallet - should be from backend
    }
  }

  String get _paymentMethodName {
    if (widget.paymentMethod.contains('moncash')) {
      return 'MonCash';
    } else {
      return 'NatCash';
    }
  }

  String get _instructions {
    if (widget.paymentMethod.contains('moncash')) {
      return '''
1. Dial *202# on your phone
2. Select "Send Money"
3. Enter amount: ${widget.amount.toStringAsFixed(2)} HTG
4. Enter receiver number: $_walletNumber
5. Confirm the transaction
6. Enter the transaction reference below
''';
    } else {
      return '''
1. Open your NatCash app
2. Select "Send Money"
3. Enter amount: ${widget.amount.toStringAsFixed(2)} HTG
4. Enter receiver number: $_walletNumber
5. Confirm the transaction
6. Enter the transaction reference below
''';
    }
  }

  Future<void> _submitPayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final response = await _paymentService.submitManualPayment(
        buyerName: widget.buyerName,
        buyerPhone: widget.buyerPhone,
        buyerEmail: widget.buyerEmail,
        department: widget.department,
        category: widget.ticketCategory,
        quantity: widget.ticketQuantity,
        paymentMethod: widget.paymentMethod,
        transactionId: _transactionIdController.text.trim(),
      );

      if (mounted) {
        _showSuccessDialog(response);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit payment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _showSuccessDialog(PurchaseResponse response) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Payment Submitted'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'Your payment has been submitted for verification.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Payment Reference:\n${response.paymentReference}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'You will receive an SMS confirmation once your payment is approved.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(response); // Return result
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$_paymentMethodName Manual Payment'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Payment summary
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Amount to Pay:',
                          style: TextStyle(fontSize: 16),
                        ),
                        Text(
                          '${widget.amount.toStringAsFixed(2)} HTG',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Tickets:'),
                        Text(
                          '${widget.ticketQuantity}x ${widget.ticketCategory}',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Wallet number
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Send payment to:',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _walletNumber,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: _walletNumber));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Wallet number copied'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Instructions
            ExpansionTile(
              title: const Text(
                'Payment Instructions',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              initiallyExpanded: _showInstructions,
              onExpansionChanged: (expanded) {
                setState(() => _showInstructions = expanded);
              },
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _instructions,
                    style: const TextStyle(height: 1.5),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Transaction reference form
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Transaction Reference',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _transactionIdController,
                    decoration: const InputDecoration(
                      hintText: 'Enter transaction reference',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.receipt),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Transaction reference is required';
                      }
                      if (value.trim().length < 5) {
                        return 'Please enter a valid transaction reference';
                      }
                      return null;
                    },
                    enabled: !_isSubmitting,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Enter the transaction reference you received after completing the payment',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitPayment,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Submit Payment',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
