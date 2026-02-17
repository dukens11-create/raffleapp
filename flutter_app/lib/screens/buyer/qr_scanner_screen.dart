import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../providers/my_tickets_provider.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Skane Kòd QR'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: _controller.torchState,
              builder: (context, state, child) {
                switch (state as TorchState) {
                  case TorchState.off:
                    return const Icon(Icons.flash_off);
                  case TorchState.on:
                    return const Icon(Icons.flash_on);
                }
              },
            ),
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: _controller.cameraFacingState,
              builder: (context, state, child) {
                return const Icon(Icons.cameraswitch);
              },
            ),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera view
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              if (_isProcessing) return;
              
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  _handleScannedCode(barcode.rawValue!);
                  break;
                }
              }
            },
          ),

          // Scanning frame overlay
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          // Instructions
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 32),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Mete kòd QR tikè a nan kad la',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          // Manual entry button
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: TextButton.icon(
                onPressed: _showManualEntryDialog,
                icon: const Icon(Icons.keyboard, color: Colors.white),
                label: const Text(
                  'Antre manyèlman',
                  style: TextStyle(color: Colors.white),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.purple.withOpacity(0.8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleScannedCode(String code) async {
    setState(() => _isProcessing = true);

    try {
      // Verify the ticket
      final ticketProvider = context.read<MyTicketsProvider>();
      final result = await ticketProvider.verifyTicket(code);

      if (!mounted) return;

      if (result != null && result.valid) {
        // Show success dialog
        _showTicketVerificationDialog(
          isValid: true,
          ticket: result.ticket,
        );
      } else {
        // Show error dialog
        _showTicketVerificationDialog(
          isValid: false,
          error: result?.error ?? 'Tikè pa valid',
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erè: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showTicketVerificationDialog({
    required bool isValid,
    dynamic ticket,
    String? error,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                isValid ? Icons.check_circle : Icons.error,
                color: isValid ? Colors.green : Colors.red,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isValid ? 'Tikè Valid!' : 'Tikè Pa Valid',
                  style: TextStyle(
                    color: isValid ? Colors.green : Colors.red,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isValid && ticket != null) ...[
                _buildVerificationRow('Nimewo', ticket.ticket_number ?? ''),
                const SizedBox(height: 8),
                _buildVerificationRow('Kategori', ticket.category ?? ''),
                const SizedBox(height: 8),
                _buildVerificationRow('Pri', '${ticket.price ?? ''} HTG'),
                const SizedBox(height: 8),
                _buildVerificationRow('Estati', ticket.status ?? ''),
              ] else ...[
                Text(
                  error ?? 'Tikè sa a pa valid oswa pa egziste',
                  style: const TextStyle(color: Colors.red),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Skane Ankò'),
            ),
            if (isValid)
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('Fèmen'),
              ),
          ],
        );
      },
    );
  }

  Widget _buildVerificationRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  void _showManualEntryDialog() {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Antre Nimewo Tikè'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Nimewo Tikè',
              hintText: 'Antre nimewo tikè a',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Anile'),
            ),
            ElevatedButton(
              onPressed: () {
                final ticketNumber = controller.text.trim();
                if (ticketNumber.isNotEmpty) {
                  Navigator.pop(context);
                  _handleScannedCode(ticketNumber);
                }
              },
              child: const Text('Verifye'),
            ),
          ],
        );
      },
    );
  }
}
