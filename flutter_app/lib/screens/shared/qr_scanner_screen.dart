import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../services/qr_scanner_service.dart';
import '../../widgets/qr_scanner_overlay.dart';

/// Reusable QR/Barcode scanner screen
/// 
/// Supports:
/// - QR codes and barcodes (Code 128, Code 39)
/// - Ticket validation via API
/// - Visual feedback with animations
/// - Flashlight toggle
class QRScannerScreen extends StatefulWidget {
  final String? title;
  final bool validateTicket;
  final Function(String)? onScanComplete;
  final Function(TicketValidationResult)? onValidationComplete;

  const QRScannerScreen({
    super.key,
    this.title = 'Scan QR Code',
    this.validateTicket = true,
    this.onScanComplete,
    this.onValidationComplete,
  });

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final QRScannerService _scannerService = QRScannerService();
  MobileScannerController? _controller;
  
  bool _isProcessing = false;
  String? _statusText;
  bool _showSuccess = false;
  bool _showError = false;
  bool _flashOn = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      formats: [
        BarcodeFormat.qrCode,
        BarcodeFormat.code128,
        BarcodeFormat.code39,
      ],
      detectionSpeed: DetectionSpeed.normal,
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _handleBarcode(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final barcode = barcodes.first;
    final code = QRScannerService.parseBarcode(barcode);

    if (code == null) {
      _showMessage('Unable to read code', isError: true);
      return;
    }

    setState(() {
      _isProcessing = true;
      _statusText = 'Validating...';
    });

    // Pause scanning during validation
    _controller?.stop();

    if (widget.validateTicket) {
      // Validate ticket via API
      final result = await _scannerService.validateTicket(code);

      setState(() {
        _statusText = result.displayMessage;
        _showSuccess = result.isValid;
        _showError = !result.isValid;
      });

      // Wait a moment to show result
      await Future.delayed(const Duration(seconds: 2));

      if (widget.onValidationComplete != null) {
        widget.onValidationComplete!(result);
      }

      // Return result and close screen
      if (mounted) {
        Navigator.of(context).pop(result);
      }
    } else {
      // Just return the scanned code without validation
      setState(() {
        _statusText = 'Code scanned successfully';
        _showSuccess = true;
      });

      await Future.delayed(const Duration(seconds: 1));

      if (widget.onScanComplete != null) {
        widget.onScanComplete!(code);
      }

      if (mounted) {
        Navigator.of(context).pop(code);
      }
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    setState(() {
      _statusText = message;
      _showError = isError;
      _showSuccess = !isError;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _statusText = null;
          _showError = false;
          _showSuccess = false;
          _isProcessing = false;
        });
        _controller?.start();
      }
    });
  }

  void _toggleFlash() {
    setState(() {
      _flashOn = !_flashOn;
    });
    _controller?.toggleTorch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? 'Scan QR Code'),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: Icon(_flashOn ? Icons.flash_on : Icons.flash_off),
            onPressed: _toggleFlash,
            tooltip: 'Toggle flashlight',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera view
          MobileScanner(
            controller: _controller,
            onDetect: _handleBarcode,
          ),

          // Scanner overlay
          QRScannerOverlay(
            statusText: _statusText,
            showSuccess: _showSuccess,
            showError: _showError,
          ),

          // Cancel button
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
                label: const Text('Cancel'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
