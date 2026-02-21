import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/payment_provider.dart';
import '../../providers/raffle_provider.dart';
import '../../widgets/language_switcher.dart';
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
    final locale = context.watch<LocaleProvider>();
    return Scaffold(
      appBar: AppBar(
        title: Text(locale.translate('buy_tickets_title')),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: const [
          LanguageSwitcher(),
          SizedBox(width: 4),
        ],
      ),
      body: Consumer2<RaffleProvider, PaymentProvider>(
        builder: (context, raffleProvider, paymentProvider, child) {
          if (raffleProvider.isLoading && !raffleProvider.hasData) {
            return LoadingIndicator(message: locale.translate('loading'));
          }

          if (raffleProvider.error != null) {
            return ErrorDisplay(
              error: raffleProvider.error!,
              onRetry: () => raffleProvider.refresh(),
            );
          }

          final raffleInfo = raffleProvider.raffleInfo;
          if (raffleInfo == null) {
            return EmptyState(
              icon: Icons.inbox,
              title: locale.translate('no_raffle_available'),
              subtitle: locale.translate('come_back_later_raffle'),
            );
          }

          // Show payment confirmation if payment was initiated
          if (paymentProvider.paymentUrl != null) {
            return _buildPaymentConfirmation(paymentProvider, locale);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Information card
                Card(
                  color: Colors.blue[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.info, color: Colors.blue),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            locale.translate('payment_info'),
                            style: const TextStyle(fontSize: 14),
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
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 12),
                          Text(locale.translate('processing')),
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
      final locale = context.read<LocaleProvider>();
      if (paymentProvider.paymentUrl != null) {
        _showPaymentUrlDialog(context, paymentProvider.paymentUrl!, locale);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(locale.translate('payment_success')),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Widget _buildPaymentConfirmation(PaymentProvider paymentProvider, LocaleProvider locale) {
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
          Text(
            locale.translate('payment_initiated'),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (paymentProvider.paymentReference != null) ...[
            Text(
              '${locale.translate('reference')}: ${paymentProvider.paymentReference}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (paymentProvider.ticketNumbers != null &&
              paymentProvider.ticketNumbers!.isNotEmpty) ...[
            Text(
              locale.translate('your_tickets'),
              style: const TextStyle(
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
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (paymentProvider.paymentUrl != null) {
                  _showPaymentUrlDialog(context, paymentProvider.paymentUrl!, locale);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.all(16),
              ),
              child: Text(
                locale.translate('continue_payment'),
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              paymentProvider.clear();
              Navigator.pop(context);
            },
            child: Text(locale.translate('return_back')),
          ),
        ],
      ),
    );
  }

  void _showPaymentUrlDialog(BuildContext context, String paymentUrl, LocaleProvider locale) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('MonCash Payment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                locale.translate('moncash_dialog_info'),
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
              child: Text(locale.translate('close')),
            ),
          ],
        );
      },
    );
  }
}
