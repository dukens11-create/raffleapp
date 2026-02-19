import 'package:flutter/material.dart';
import '../../models/payment.dart';
import 'moncash_payment_screen.dart';
import 'manual_payment_screen.dart';

/// Payment method selection screen
/// 
/// Allows users to choose between:
/// - MonCash automated payment
/// - MonCash manual (USSD) payment
/// - NatCash automated payment
/// - NatCash manual payment
class PaymentMethodScreen extends StatefulWidget {
  final double amount;
  final String ticketCategory;
  final int ticketQuantity;
  final String buyerName;
  final String buyerPhone;
  final String? buyerEmail;
  final String? department;

  const PaymentMethodScreen({
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
  State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  PaymentMethodOption? _selectedMethod;

  void _handleMethodSelection(PaymentMethodOption method) {
    setState(() => _selectedMethod = method);
  }

  void _handleContinue() {
    if (_selectedMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a payment method'),
        ),
      );
      return;
    }

    if (_selectedMethod!.isAutomated) {
      // Navigate to automated payment flow
      if (_selectedMethod!.id == 'moncash') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MonCashPaymentScreen(
              amount: widget.amount,
              ticketCategory: widget.ticketCategory,
              ticketQuantity: widget.ticketQuantity,
              buyerName: widget.buyerName,
              buyerPhone: widget.buyerPhone,
              buyerEmail: widget.buyerEmail,
              department: widget.department,
            ),
          ),
        );
      } else {
        // NatCash automated - similar screen can be created
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('NatCash payment coming soon'),
          ),
        );
      }
    } else {
      // Navigate to manual payment flow
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ManualPaymentScreen(
            amount: widget.amount,
            ticketCategory: widget.ticketCategory,
            ticketQuantity: widget.ticketQuantity,
            buyerName: widget.buyerName,
            buyerPhone: widget.buyerPhone,
            buyerEmail: widget.buyerEmail,
            department: widget.department,
            paymentMethod: _selectedMethod!.id,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Payment Method'),
      ),
      body: Column(
        children: [
          // Payment summary
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.primaryContainer,
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
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
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

          // Payment methods list
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Text(
                    'Choose a payment method:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // Automated payments section
                const Text(
                  'Automated Payments',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                _buildPaymentMethodCard(PaymentMethods.moncashAutomated),
                const SizedBox(height: 8),
                _buildPaymentMethodCard(PaymentMethods.natcashAutomated),

                const SizedBox(height: 24),

                // Manual payments section
                const Text(
                  'Manual Payments',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                _buildPaymentMethodCard(PaymentMethods.moncashManual),
                const SizedBox(height: 8),
                _buildPaymentMethodCard(PaymentMethods.natcashManual),
              ],
            ),
          ),

          // Continue button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedMethod != null ? _handleContinue : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodCard(PaymentMethodOption method) {
    final isSelected = _selectedMethod?.id == method.id;

    return Card(
      elevation: isSelected ? 4 : 1,
      color: isSelected
          ? Theme.of(context).colorScheme.primaryContainer
          : null,
      child: InkWell(
        onTap: method.enabled
            ? () => _handleMethodSelection(method)
            : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  method.icon ?? '💳',
                  style: const TextStyle(fontSize: 24),
                ),
              ),
              const SizedBox(width: 16),

              // Method details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      method.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: method.enabled ? null : Colors.grey,
                      ),
                    ),
                    if (method.description != null)
                      Text(
                        method.description!,
                        style: TextStyle(
                          fontSize: 14,
                          color: method.enabled ? Colors.grey[600] : Colors.grey,
                        ),
                      ),
                    if (!method.enabled)
                      const Text(
                        'Not available',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),

              // Selection indicator
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
