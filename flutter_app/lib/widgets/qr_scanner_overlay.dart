import 'package:flutter/material.dart';

/// QR scanner overlay with guide frame and instructions
/// 
/// Provides visual feedback for scanner positioning
class QRScannerOverlay extends StatelessWidget {
  final String? statusText;
  final bool showSuccess;
  final bool showError;

  const QRScannerOverlay({
    super.key,
    this.statusText,
    this.showSuccess = false,
    this.showError = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Dark overlay with cutout
        ColorFiltered(
          colorFilter: const ColorFilter.mode(
            Colors.black54,
            BlendMode.srcOut,
          ),
          child: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Colors.black,
                  backgroundBlendMode: BlendMode.dstOut,
                ),
              ),
              Align(
                alignment: Alignment.center,
                child: Container(
                  height: 250,
                  width: 250,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Scan frame with corners
        Center(
          child: Container(
            height: 250,
            width: 250,
            decoration: BoxDecoration(
              border: Border.all(
                color: showSuccess
                    ? Colors.green
                    : showError
                        ? Colors.red
                        : Colors.white,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Stack(
              children: [
                // Corner indicators
                _buildCorner(Alignment.topLeft, true, true),
                _buildCorner(Alignment.topRight, true, false),
                _buildCorner(Alignment.bottomLeft, false, true),
                _buildCorner(Alignment.bottomRight, false, false),
              ],
            ),
          ),
        ),

        // Instructions at top
        Positioned(
          top: 100,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            child: Text(
              'Position the QR code or barcode\nwithin the frame',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.8),
                    offset: const Offset(0, 1),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
        ),

        // Status message at bottom
        if (statusText != null)
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: showSuccess
                      ? Colors.green.withOpacity(0.9)
                      : showError
                          ? Colors.red.withOpacity(0.9)
                          : Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (showSuccess)
                      const Icon(Icons.check_circle, color: Colors.white, size: 24)
                    else if (showError)
                      const Icon(Icons.error, color: Colors.white, size: 24)
                    else
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        statusText!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCorner(Alignment alignment, bool top, bool left) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          border: Border(
            top: top
                ? const BorderSide(color: Colors.white, width: 4)
                : BorderSide.none,
            left: left
                ? const BorderSide(color: Colors.white, width: 4)
                : BorderSide.none,
            bottom: !top
                ? const BorderSide(color: Colors.white, width: 4)
                : BorderSide.none,
            right: !left
                ? const BorderSide(color: Colors.white, width: 4)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }
}
