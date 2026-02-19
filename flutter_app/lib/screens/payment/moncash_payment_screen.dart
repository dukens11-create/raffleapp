import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../services/payment_service.dart';
import '../../models/transaction.dart';

/// MonCash automated payment screen
/// 
/// Flow:
/// 1. Initiate payment via API
/// 2. Get redirect URL
/// 3. Open MonCash payment gateway in WebView
/// 4. Handle payment completion/cancellation
class MonCashPaymentScreen extends StatefulWidget {
  final double amount;
  final String ticketCategory;
  final int ticketQuantity;
  final String buyerName;
  final String buyerPhone;
  final String? buyerEmail;
  final String? department;

  const MonCashPaymentScreen({
    super.key,
    required this.amount,
    required this.ticketCategory,
    required this.ticketQuantity,
    required this.buyerName,
    required this.buyerPhone,
    this.buyerEmail,
    this.department,
  });

  @override
  State<MonCashPaymentScreen> createState() => _MonCashPaymentScreenState();
}

class _MonCashPaymentScreenState extends State<MonCashPaymentScreen> {
  final PaymentService _paymentService = PaymentService();
  
  bool _isInitiating = true;
  bool _isError = false;
  String? _errorMessage;
  PurchaseResponse? _purchaseResponse;

  @override
  void initState() {
    super.initState();
    _initiatePayment();
  }

  Future<void> _initiatePayment() async {
    setState(() {
      _isInitiating = true;
      _isError = false;
    });

    try {
      final response = await _paymentService.initiateMonCashPurchase(
        buyerName: widget.buyerName,
        buyerPhone: widget.buyerPhone,
        buyerEmail: widget.buyerEmail,
        department: widget.department,
        category: widget.ticketCategory,
        quantity: widget.ticketQuantity,
      );

      setState(() {
        _purchaseResponse = response;
        _isInitiating = false;
      });

      // If we have a redirect URL, show web view
      // In a real implementation, you would use webview_flutter
      // For now, we'll just show success message
      if (response.paymentUrl != null) {
        _showPaymentUrlDialog(response.paymentUrl!);
      }
    } catch (e) {
      setState(() {
        _isError = true;
        _errorMessage = e.toString();
        _isInitiating = false;
      });
    }
  }

  void _showPaymentUrlDialog(String url) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Complete Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Payment initiated successfully!'),
            const SizedBox(height: 16),
            Text(
              'Payment Reference:\n${_purchaseResponse?.paymentReference ?? "N/A"}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'In a production app, you would be redirected to MonCash payment gateway.',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(_purchaseResponse); // Return to previous screen
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
        title: const Text('MonCash Payment'),
      ),
      body: Center(
        child: _isInitiating
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  const Text('Initiating payment...'),
                  const Text(
                    'Please wait',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              )
            : _isError
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Payment Initiation Failed',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage ?? 'Unknown error occurred',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Go Back'),
                        ),
                      ],
                    ),
                  )
                : Container(),
      ),
    );
  }
}
