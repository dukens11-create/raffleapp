import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/payment_provider.dart';
import '../../providers/raffle_provider.dart';
import '../../widgets/payment_form.dart';
import '../../widgets/loading_indicator.dart';

class PaymentScreen extends StatefulWidget {
  final String? initialCategory;

  const PaymentScreen({
    super.key,
    this.initialCategory,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  @override
  void initState() {
    super.initState();
    // Load raffle info for categories
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RaffleProvider>().loadRaffleInfo();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Achte Tikè'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Consumer2<RaffleProvider, PaymentProvider>(
        builder: (context, raffleProvider, paymentProvider, child) {
          if (raffleProvider.isLoading && !raffleProvider.hasData) {
            return const LoadingIndicator(message: 'Chajman...');
          }

          if (raffleProvider.error != null) {
            return ErrorDisplay(
              error: raffleProvider.error!,
              onRetry: () => raffleProvider.refresh(),
            );
          }

          final raffleInfo = raffleProvider.raffleInfo;
          if (raffleInfo == null) {
            return const EmptyState(
              icon: Icons.inbox,
              title: 'Pa gen tiraj disponib',
              subtitle: 'Tanpri retounen pi ta',
            );
          }

          // Show payment confirmation if payment was initiated
          if (paymentProvider.paymentUrl != null) {
            return _buildPaymentConfirmation(paymentProvider);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Information card
                Card(
                  color: Colors.blue[50],
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Ranpli fòmilè a pou achte tikè ou. Ou pral redirije nan MonCash pou peye.',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Payment form
                PaymentForm(
                  categories: raffleInfo.availableCategories,
                  initialCategory: widget.initialCategory,
                  useKreyol: true,
                  onSubmit: (formData) => _handlePayment(context, formData, paymentProvider),
                ),

                // Show error if any
                if (paymentProvider.error != null) ...[
                  const SizedBox(height: 16),
                  Card(
                    color: Colors.red[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.error, color: Colors.red),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              paymentProvider.error!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: () {
                              paymentProvider.clearError();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                // Show loading overlay
                if (paymentProvider.isProcessing) ...[
                  const SizedBox(height: 16),
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text('Trete peman...'),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _handlePayment(
    BuildContext context,
    PaymentFormData formData,
    PaymentProvider paymentProvider,
  ) async {
    bool success = false;

    if (formData.paymentMethod == 'moncash') {
      success = await paymentProvider.initiateMonCashPurchase(
        buyerName: formData.buyerName,
        buyerPhone: formData.buyerPhone,
        buyerEmail: formData.buyerEmail,
        department: formData.department,
        category: formData.category,
        quantity: formData.quantity,
      );
    } else if (formData.paymentMethod == 'natcash') {
      success = await paymentProvider.initiateNatCashPurchase(
        buyerName: formData.buyerName,
        buyerPhone: formData.buyerPhone,
        buyerEmail: formData.buyerEmail,
        department: formData.department,
        category: formData.category,
        quantity: formData.quantity,
      );
    }

    if (success && context.mounted) {
      if (paymentProvider.paymentUrl != null) {
        // For MonCash, show confirmation with payment URL
        // In a real app, we would open the browser or WebView
        _showPaymentUrlDialog(context, paymentProvider.paymentUrl!);
      } else {
        // For other methods, show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Peman ou te inisye avèk siksè!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Widget _buildPaymentConfirmation(PaymentProvider paymentProvider) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_circle,
            size: 100,
            color: Colors.green,
          ),
          const SizedBox(height: 24),
          const Text(
            'Peman Inisye!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (paymentProvider.paymentReference != null) ...[
            Text(
              'Referans: ${paymentProvider.paymentReference}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (paymentProvider.ticketNumbers != null &&
              paymentProvider.ticketNumbers!.isNotEmpty) ...[
            const Text(
              'Tikè ou yo:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...paymentProvider.ticketNumbers!.map((number) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  number,
                  style: const TextStyle(fontSize: 16),
                ),
              );
            }),
          ],
          const SizedBox(height: 24),
          const Text(
            'Klike sou bouton anba a pou kontinye ak peman.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // In a real app, open payment URL in browser/WebView
                if (paymentProvider.paymentUrl != null) {
                  _showPaymentUrlDialog(context, paymentProvider.paymentUrl!);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.all(16),
              ),
              child: const Text(
                'Kontinye ak Peman',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              paymentProvider.clear();
              Navigator.pop(context);
            },
            child: const Text('Retounen'),
          ),
        ],
      ),
    );
  }

  void _showPaymentUrlDialog(BuildContext context, String paymentUrl) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('MonCash Payment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Nan yon aplikasyon reyèl, ou ta louvri lyen peman sa a nan yon navigatè oswa WebView:',
              ),
              const SizedBox(height: 16),
              SelectableText(
                paymentUrl,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                context.read<PaymentProvider>().clear();
              },
              child: const Text('Fèmen'),
            ),
          ],
        );
      },
    );
  }
}
